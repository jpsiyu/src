%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-10-19
%% Description: TODO:
%% --------------------------------------------------------
-module(lib_mount2).
-compile(export_all).
-include("mount.hrl").
-include("server.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-include("scene.hrl").
-include("errcode_goods.hrl").


%% 坐骑进阶升星条件检查
check_mount_upgrade(PS, MountId, RuneList, GoodsStatus) ->
    case lib_goods_check:list_handle(fun check_upgrade_stone/2, [PS, 0, [], GoodsStatus], RuneList) of
        {fail, Res} -> {fail, Res};
        {ok, [_, Num, NewStoneList, _]} ->
            Mou = PS#player_status.mount,
            case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
                [] -> {fail, 7}; %% 坐骑不存在
                [Mount] ->
                    if
                        Mount#ets_mount.role_id =/= PS#player_status.id ->
                            {fail, 8}; %% 坐骑不属于你所有
                        true ->
                            StarRule = data_mount:get_mount_upgrade_star(Mount#ets_mount.star, Mount#ets_mount.level),
                            Limit = data_mount:get_upgrade_limit(Mount#ets_mount.level + 1),
                            [{GoodsInfo, _}|_] = NewStoneList,
                            if
                                is_record(StarRule, mount_upgrade_star) =:= false orelse is_record(Limit, mount_upgrade_limit) =:= false ->
                                    {fail, 9};
                                true ->
                                    [{StarGoodId, StarGoodNum}] = StarRule#mount_upgrade_star.goods,
                                    if
                                        GoodsInfo#goods.goods_id =/= StarGoodId ->
                                            {fail, 10};
                                        Num < StarGoodNum ->
                                            %% io:format("~p ~p Num:~p, StarGoodNum:~p~n", [?MODULE, ?LINE, Num, StarGoodNum]),
                                            {fail, 11};
                                        (PS#player_status.coin+PS#player_status.bcoin) < StarRule#mount_upgrade_star.coin ->
                                            {fail, 13};
                                        Mount#ets_mount.level >= 12 ->
                                            {fail, 14};
                                        Limit#mount_upgrade_limit.lv > PS#player_status.lv ->
                                            {fail, 15};
                                        true ->
                                            {ok, Mount, NewStoneList, StarRule, Limit#mount_upgrade_limit.max_value}
                                    end
                            end
                    end
            end
    end.
          

%% 坐骑升星操作
mount_upgrade(PS, Mount, StoneList, StarRule, GoodsStatus, _MaxValue) ->
    F = fun() ->
                ok = lib_goods_dict:start_dict(),
                NewPS = lib_goods_util:cost_money(PS, StarRule#mount_upgrade_star.coin, coin),
                {ok, NewStatus} =  lib_goods:delete_goods_list(GoodsStatus, StoneList),
                Bind1 = lib_goods_compose:get_bind(StoneList),
                case Mount#ets_mount.bind > 0 orelse Bind1 > 0 of
                    true ->
                        Trade = 1,
                        Bind = 2;
                    false ->
                        Bind = 0,
                        Trade = 0
                end,
                Ram = util:rand(1, 10000),
                {IsUpStar, IsUpMount} = is_up_star_or_upgrade(Mount#ets_mount.star, Mount#ets_mount.star_value, Ram, StarRule),
                %% io:format("~p ~p {IsUpStar, IsUpMount}:~p~n", [?MODULE, ?LINE, [IsUpStar, IsUpMount]]),
                case length(StoneList) of
                    2 ->
                        [{GoodsInfo, N1}, {_, N2}] = StoneList,
                        Num = N1 + N2;
                    _ ->
                        [{GoodsInfo, Num}|_] = StoneList
                end,
                About1 = lib_goods_compose:get_about([{GoodsInfo,1}]),
                if
                    IsUpMount =:= 1 -> %%　坐骑升阶
                        Res = 1,
                        NewMount = mount_upgrade_ok(Mount, Bind, Trade, StarRule, NewPS),
                        log:log_mount_upgrade(Mount, NewMount, PS#player_status.lv, GoodsInfo#goods.goods_id, Num, 
                                              StarRule#mount_upgrade_star.coin, StarRule#mount_upgrade_star.radio, Ram, 1, About1);
                    IsUpStar =:= 1 ->
                        Res = 2,
                        NewMount = mount_upgrade_star_ok(Mount, Bind, Trade),
                        log:log_mount_upgrade(Mount, NewMount, PS#player_status.lv, GoodsInfo#goods.goods_id, Num, 
                                              StarRule#mount_upgrade_star.coin, StarRule#mount_upgrade_star.radio, Ram, 2, About1);
                    true ->
                        Res = 3,
                        NewMount = mount_upgrade_star_fail(Mount, Bind, Trade),
                        log:log_mount_upgrade(Mount, NewMount, PS#player_status.lv, GoodsInfo#goods.goods_id, Num, 
                                              StarRule#mount_upgrade_star.coin, StarRule#mount_upgrade_star.radio, Ram, 3, About1)
                end,
                
                Mou = NewPS#player_status.mount,
                OldDict = Mou#status_mount.mount_dict,
                MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, OldDict),
                %% io:format("~p ~p MountDict:~p~n", [?MODULE, ?LINE,MountDict]),
                NewPS1 = lib_mount:change_player_status(NewPS, MountDict), 
                %% 日志
                About = lists:concat(["mount_upgrade ",Mount#ets_mount.id," +",Mount#ets_mount.type_id," => +",NewMount#ets_mount.type_id]),
                log:log_consume(mount_star_upgrade, coin, PS, NewPS1, Mount#ets_mount.id, 1, About),
                Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                NewStatus1 = NewStatus#goods_status{dict = Dict},
                {ok, Res, NewPS1, NewStatus1, NewMount}
        end,
    lib_goods_util:transaction(F).

%% new:进阶成功
mount_upgrade_ok(Mount, Bind, Trade, StarRule, PS) ->
    NewTypeId = StarRule#mount_upgrade_star.next_figure,
    NewName = data_goods_type:get_name(NewTypeId),
    %% io:format("~p ~p mount_upgrade_ok:NewTypeId:~p~n", [?MODULE, ?LINE,NewTypeId]),
    %% io:format("~p ~p mount_upgrade_ok:StarNum:~p, StarValue:~p~n", [?MODULE, ?LINE, Mount#ets_mount.star, Mount#ets_mount.star_value]),
    NewMount1 = Mount#ets_mount{level = StarRule#mount_upgrade_star.level, star_value=0, star=0, type_id = NewTypeId, name = NewName},
    NewFigure = lib_mount:get_stren_figure(NewMount1),
    NewMount2 = count_mount_attribute(NewMount1),
    NewMount = NewMount2#ets_mount{figure = NewFigure, bind = Bind, trade = Trade},
    Sql = io_lib:format(?SQL_UPGRADE_OK, [util:term_to_string(NewMount#ets_mount.attribute), NewMount#ets_mount.bind, 
                                          NewMount#ets_mount.trade, NewMount#ets_mount.figure, NewMount#ets_mount.combat_power, 
                                          NewMount#ets_mount.type_id, NewMount#ets_mount.level, NewMount#ets_mount.star,
                                          NewMount#ets_mount.star_value, NewMount#ets_mount.id]),
    %% io:format("~p ~p mount_upgrade_ok:~nSQL:~ts~n", [?MODULE, ?LINE, Sql]),
    db:execute(Sql),
    lib_chat:send_TV({all},0,2, ["horseJinjie",  
                                            PS#player_status.id, 
                                            PS#player_status.realm, 
                                            PS#player_status.nickname, 
                                            PS#player_status.sex, 
                                            PS#player_status.career, 
                                            PS#player_status.image, 
                                            NewMount#ets_mount.type_id, 
                                            NewMount#ets_mount.level]),
    NewMount.

%%　new:坐骑进阶升星操作成功
mount_upgrade_star_ok(Mount, Bind, Trade) ->
    %% io:format("~p ~p mount_upgrade_star_ok:StarNum:~p, StarValue:~p~n", [?MODULE, ?LINE, Mount#ets_mount.star, Mount#ets_mount.star_value]),
    NewStar = Mount#ets_mount.star + 1,
    NewMount1 = Mount#ets_mount{star = NewStar, star_value = 0},
    NewMount2 = count_mount_attribute(NewMount1),
    NewMount = NewMount2#ets_mount{bind = Bind, trade = Trade},
    Sql = io_lib:format(?SQL_UPGRADE_STAR_OK, [util:term_to_string(NewMount#ets_mount.attribute),
                                               NewMount#ets_mount.star, 
                                               NewMount#ets_mount.star_value,  
                                               NewMount#ets_mount.bind, 
                                               NewMount#ets_mount.trade, 
                                               NewMount#ets_mount.combat_power, 
                                               NewMount#ets_mount.id]),
    db:execute(Sql),
    NewMount.

%%　new:坐骑进阶升星操作失败：增加升星祝福值
mount_upgrade_star_fail(Mount, Bind, Trade) ->
    Value = Mount#ets_mount.star_value + 1,
    NewMount = Mount#ets_mount{star_value = Value, trade = Trade},
    Sql = io_lib:format(?SQL_UPGRADE_STAR_FAIL, [NewMount#ets_mount.star_value, Bind, Trade, NewMount#ets_mount.id]),
    db:execute(Sql),
    NewMount.


get_mount_ratio(_, []) -> 
    0;
get_mount_ratio(Ram, List) ->
    case List of
        [{Min, Max, Value}|T] ->
            if
                Max >= Ram andalso Min =< Ram ->
                    Value;
                true ->
                    get_mount_ratio(Ram, T)
            end;
        _ ->
            0
    end.

%% check_mount_upgrade(PlayerStatus, MountId, RuneList, GoodsStatus) ->
%%     case lib_goods_check:list_handle(fun check_upgrade_stone/2, [PlayerStatus, 0, [], GoodsStatus], RuneList) of
%%         {fail, Res} ->
%%             {fail, Res};
%%         {ok, [_, Num, NewStoneList, _]} ->
%%             Mou = PlayerStatus#player_status.mount,
%%             case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
%%                 [] ->
%%                     %% 坐骑不存在
%%                     {fail, 5};
%%                 [Mount] ->
%%                     if
%%                         %% 坐骑不属于你所有
%%                         Mount#ets_mount.role_id =/= PlayerStatus#player_status.id ->
%%                             {fail, 6};
%%                         true ->
%%                             Rule = data_mount:get_mount_upgrade(Mount#ets_mount.type_id),
%%                             Limit = data_mount:get_upgrade_limit(Mount#ets_mount.level + 1),
%%                             [{GoodsInfo, _}|_] = NewStoneList,
%%                             if
%%                                 is_record(Rule, mount_upgrade_star) =:= false
%%                                 orelse is_record(Limit, mount_upgrade_limit) =:=
%%                                 false ->
%%                                     {fail, 7};
%%                                 GoodsInfo#goods.goods_id =/= Rule#mount_upgrade.rune_id ->
%%                                     {fail, 8};
%%                                 Num =/= Rule#mount_upgrade.num ->
%%                                     {fail, 9};
%%                                 (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Rule#mount_upgrade.coin ->
%%                                     {fail, 11};
%%                                 Mount#ets_mount.level >= 12 ->
%%                                     {fail, 12};
%%                                 Limit#mount_upgrade_limit.lv > PlayerStatus#player_status.lv ->
%%                                     {fail, 13};
%%                                 true ->
%%                                     {ok, Mount, NewStoneList, Rule, Limit#mount_upgrade_limit.max_value}
%%                             end
%%                     end
%%             end
%%     end.

%% mount_upgrade(PlayerStatus, Mount, StoneList, Rule, GoodsStatus, MaxValue) ->
%%     F = fun() ->
%%         ok = lib_goods_dict:start_dict(),
%%         NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Rule#mount_upgrade.coin, coin),
%%         {ok, NewStatus} =  lib_goods:delete_goods_list(GoodsStatus, StoneList),
%%         Bind1 = lib_goods_compose:get_bind(StoneList),
%%         case Mount#ets_mount.bind > 0 orelse Bind1 > 0 of
%%             true ->
%%                 Trade = 1,
%%                 Bind = 2;
%%             false ->
%%                 Bind = 0,
%%                 Trade = 0
%%         end,
%%         Ram = util:rand(1, 10000),
%%         MountRam = get_mount_ratio(Mount#ets_mount.up_value, Rule#mount_upgrade.radio),
%%         %io:format("MountRam = ~p, ~p, ~p~n", [Mount#ets_mount.up_value, MountRam, Ram]),
%%         case length(StoneList) of
%%             2 ->
%%                 [{GoodsInfo, N1}, {_, N2}] = StoneList,
%%                 Num = N1 + N2;
%%             _ ->
%%                 [{GoodsInfo, Num}|_] = StoneList
%%         end,
%%         About1 = lib_goods_compose:get_about([{GoodsInfo,1}]),
%%         if
%%             MountRam >= Ram ->
%%                 %% 成功
%%                 Res = 1,
%%                 NewMount = mount_upgrade_ok(Mount, Bind, Trade, Rule, NewPlayerStatus),                
%%                 log:log_mount_upgrade(Mount, NewMount, GoodsInfo#goods.goods_id, Num, Rule#mount_upgrade.coin, Ram, 1, PlayerStatus#player_status.lv, NewMount#ets_mount.up_value, About1);
%%             true ->
%%                 case Mount#ets_mount.up_value >= MaxValue of
%%                     true ->
%%                         Res = 1,
%%                         NewMount = mount_upgrade_ok(Mount, Bind, Trade, Rule, NewPlayerStatus),                
%%                         log:log_mount_upgrade(Mount, NewMount, GoodsInfo#goods.goods_id, Num, Rule#mount_upgrade.coin, Ram, 1, PlayerStatus#player_status.lv, NewMount#ets_mount.up_value, About1);
%%                     false ->
%%                         Res = 0,
%%                         NewMount = mount_upgrade_fail(Mount, Bind, Trade),
%%                         log:log_mount_upgrade(Mount, NewMount, GoodsInfo#goods.goods_id, Num, Rule#mount_upgrade.coin, Ram, 0, PlayerStatus#player_status.lv, NewMount#ets_mount.up_value, About1)
%%                 end
%%         end,
%%         Mou = NewPlayerStatus#player_status.mount,
%%         OldDict = Mou#status_mount.mount_dict,
%%         MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, OldDict),
%%         NewPlayerStatus1 = lib_mount:change_player_status(NewPlayerStatus, MountDict), 
%%         %% 日志 
%%         About = lists:concat(["mount_upgrade ", Mount#ets_mount.id, " +",Mount#ets_mount.type_id," => +",NewMount#ets_mount.type_id]),
%%         log:log_consume(mount_upgrade, coin, PlayerStatus, NewPlayerStatus1, Mount#ets_mount.id, 1, About),
%%         Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
%%         NewStatus1 = NewStatus#goods_status{dict = Dict},
%%         {ok, Res, NewPlayerStatus1, NewStatus1, NewMount}
%%     end,
%%     lib_goods_util:transaction(F).

%% mount_upgrade_ok(Mount, Bind, Trade, Rule, PlayerStatus) ->
%%     Type = Rule#mount_upgrade.next_figure,
%%     NewMount1 = Mount#ets_mount{level = Rule#mount_upgrade.level, up_value=0, type_id=Type},
%%     NewFigure = lib_mount:get_stren_figure(NewMount1),
%%     NewMount2 = count_mount_attribute(NewMount1),
%%     if
%%         NewMount2#ets_mount.level >= 3 andalso NewMount2#ets_mount.star =:= 0 ->
%%             FlyId = 311401, 
%%             lib_flyer:unlock_flyer_by_mount(PlayerStatus#player_status.pid, PlayerStatus#player_status.id); 
%%         true ->
%%             FlyId = NewMount2#ets_mount.fly_id
%%     end,
%%     NewMount3 = NewMount2#ets_mount{fly_id = FlyId},
%%     NewMount = NewMount3#ets_mount{figure = NewFigure, bind = Bind, trade = Trade},
%%     Sql = io_lib:format(?sql_upgrade_ok, [util:term_to_string(NewMount#ets_mount.attribute), util:term_to_string(NewMount#ets_mount.attribute2), NewMount#ets_mount.bind, NewMount#ets_mount.trade, NewMount#ets_mount.figure, NewMount#ets_mount.combat_power, NewMount#ets_mount.up_value, NewMount#ets_mount.type_id, NewMount#ets_mount.level, NewMount#ets_mount.fly_id, NewMount#ets_mount.id]),
%%     db:execute(Sql),
%%     lib_chat:send_TV({all},0,2, ["horseJinjie",  
%%                                             PlayerStatus#player_status.id, 
%%                                             PlayerStatus#player_status.realm, 
%%                                             PlayerStatus#player_status.nickname, 
%%                                             PlayerStatus#player_status.sex, 
%%                                             PlayerStatus#player_status.career, 
%%                                             PlayerStatus#player_status.image, 
%%                                             NewMount#ets_mount.type_id, 
%%                                             NewMount#ets_mount.level]),
%%     NewMount.
     
%% mount_upgrade_fail(Mount, Bind, Trade) ->
%%     R = util:rand(1,3),
%%     Value = Mount#ets_mount.up_value + R,
%%     NewMount = Mount#ets_mount{up_value = Value, trade = Trade},
%%     Sql = io_lib:format(?sql_upgrade_fail, [NewMount#ets_mount.up_value, Bind, Trade, NewMount#ets_mount.id]),
%%     db:execute(Sql),
%%     NewMount.

%----------------------------------------------------------------------------------
get_max_star(Level) ->
    case Level of
        3 -> 1;
        4 -> 2;
        5 -> 3;
        6 -> 4;
        7 -> 5;
        8 -> 6;
        9 -> 7;
        10 -> 8;
        11 -> 9;
        12 -> 10;
        _ -> 0
    end.
        
check_up_fly_star(PlayerStatus, MountId, StoneList, GoodsStatus) ->
    case lib_goods_check:list_handle(fun check_upgrade_stone/2, [PlayerStatus, 0, [], GoodsStatus], StoneList) of
        {fail, Res} ->
            {fail, Res};
        {ok, [_, Num, NewStoneList, _]} ->
            Mou = PlayerStatus#player_status.mount,
            case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
                [] ->
                    %% 坐骑不存在
                    {fail, 5};
                [Mount] ->
                    if
                        %% 坐骑不属于你所有
                        Mount#ets_mount.role_id =/= PlayerStatus#player_status.id ->
                            {fail, 6};
                        true ->
                            MaxStar = get_max_star(Mount#ets_mount.level),
                            if
                                Mount#ets_mount.star >= MaxStar ->
                                    {fail, 13};
                                true ->
                                    Rule = data_mount:get_mount_fly(Mount#ets_mount.star),
                                    [{GoodsInfo, _}|_] = NewStoneList,
                                    if
                                        is_record(Rule, up_fly_star) =:= false ->
                                            {fail, 7};
                                        GoodsInfo#goods.goods_id =/= Rule#up_fly_star.goods_id ->
                                            {fail, 8};
                                        Num =/= Rule#up_fly_star.num ->
                                            {fail, 9};
                                        (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Rule#up_fly_star.coin ->
                                            {fail, 11};
                                        Mount#ets_mount.star >= 10 ->
                                            {fail, 12};
                                        true ->
                                            {ok, Mount, NewStoneList, Rule}
                                    end
                            end
                    end
            end
    end.
        
mount_up_fly_star(PlayerStatus, Mount, StoneList, Rule, GoodsStatus) ->
     F = fun() ->
        ok = lib_goods_dict:start_dict(),
        NewPlayerStatus = lib_goods_util:cost_money(PlayerStatus, Rule#up_fly_star.coin, coin),
        {ok, NewStatus} =  lib_goods:delete_goods_list(GoodsStatus, StoneList),
        Bind1 = lib_goods_compose:get_bind(StoneList),
        case Mount#ets_mount.bind > 0 orelse Bind1 > 0 of
            true ->
                Trade = 1,
                Bind = 2;
            false ->
                Bind = 0,
                Trade = 0
        end,
        Ram = util:rand(1, 10000),
        FlyRam = get_mount_ratio(Mount#ets_mount.star_value, Rule#up_fly_star.star_radio),
        %io:format("FlyRam = ~p, ~p~n", [Mount#ets_mount.star_value, FlyRam]),
        case length(StoneList) of
            2 ->
                [{GoodsInfo, N1}, {_, N2}] = StoneList,
                Num = N1 + N2;
            _ ->
                [{GoodsInfo, Num}|_] = StoneList
        end,
        About1 = lib_goods_compose:get_about([{GoodsInfo,1}]),
        if
            FlyRam >= Ram ->
                Res = 1,
                NewMount = mount_upfly_ok(Mount, Bind, Trade, Rule),                
                log:log_mount_upfly(Mount, NewMount, GoodsInfo#goods.goods_id, Num, Rule#up_fly_star.coin, Ram, 1, PlayerStatus#player_status.lv, NewMount#ets_mount.star_value, About1);
            true ->
                case Mount#ets_mount.star_value >= Rule#up_fly_star.max_value of
                    true ->
                        Res = 1,
                        NewMount = mount_upfly_ok(Mount, Bind, Trade, Rule),                
                        log:log_mount_upfly(Mount, NewMount, GoodsInfo#goods.goods_id, Num, Rule#up_fly_star.coin, Ram, 1, PlayerStatus#player_status.lv, NewMount#ets_mount.star_value, About1);
                    false ->
                        Res = 0,
                        NewMount = mount_upfly_fail(Mount, Bind, Trade),
                        log:log_mount_upfly(Mount, NewMount, GoodsInfo#goods.goods_id, Num, Rule#up_fly_star.coin, Ram, 0, PlayerStatus#player_status.lv, NewMount#ets_mount.star_value, About1)
                end
        end,
        Mou = NewPlayerStatus#player_status.mount,
        OldDict = Mou#status_mount.mount_dict,
        MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, OldDict),
        NewPlayerStatus1 = lib_mount:change_player_status(NewPlayerStatus, MountDict), 
        %% 日志 
        About = lists:concat(["mount_upfly ", Mount#ets_mount.id, " +",Mount#ets_mount.fly_id," => +",NewMount#ets_mount.fly_id]),
        log:log_consume(mount_upfly, coin, PlayerStatus, NewPlayerStatus1, Mount#ets_mount.id, 1, About),
        Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
        NewStatus1 = NewStatus#goods_status{dict = Dict},
        {ok, Res, NewPlayerStatus1, NewStatus1, NewMount}
    end,
    lib_goods_util:transaction(F).

mount_upfly_ok(Mount, Bind, Trade, Rule) ->
    Type = Rule#up_fly_star.fly_figure,  
    Star = Mount#ets_mount.star + 1,
    NewMount1 = Mount#ets_mount{fly_id = Type, star_value=0, star = Star},
    NewMount2 = count_mount_attribute(NewMount1),
    NewMount = NewMount2#ets_mount{bind = Bind, trade = Trade},
    Sql = io_lib:format(?sql_upfly_ok, [util:term_to_string(NewMount#ets_mount.attribute), util:term_to_string(NewMount#ets_mount.attribute2),NewMount#ets_mount.bind, NewMount#ets_mount.trade, NewMount#ets_mount.combat_power, NewMount#ets_mount.star_value, NewMount#ets_mount.star, NewMount#ets_mount.fly_id, NewMount#ets_mount.id]),
    db:execute(Sql),
    NewMount.

mount_upfly_fail(Mount, Bind, Trade) ->
    R = util:rand(1,3),
    Value = Mount#ets_mount.star_value + R,
    NewMount = Mount#ets_mount{star_value = Value, bind = Bind, trade = Trade},
    Sql = io_lib:format(?sql_upfly_fail, [NewMount#ets_mount.star_value, Bind, Trade, NewMount#ets_mount.id]),
    db:execute(Sql),
    NewMount.

%------------------------------------------------------------------------------------------------
%%　坐骑资质培养检查
check_up_quality(PlayerStatus, MountId, Type, Coin, StoneList, GoodsStatus) ->
    UsedTime = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 8010),
    if
        UsedTime >= 10 ->
            {fail, 9};
        true -> 
            case Type of
                1 ->
                    Mou = PlayerStatus#player_status.mount,
                    case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
                        [] ->
                            {fail, 2};
                        [Mount] ->
                            if
                                Mount#ets_mount.role_id =/= PlayerStatus#player_status.id ->
                                    {fail, 3};
                                (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Coin ->
                                    {fail, 12};
                                true ->
                                    Rule = data_mount:get_mount_quality_attr_cfg(Type),
                                    if
                                        is_record(Rule, mount_quality_attr_cfg) =:= false ->
                                            {fail, 7};
                                        true ->
                                            {ok, Mount, Type, Coin, [], Rule}
                                    end
                            end
                    end;
                2 ->                                    
                    case lib_goods_check:list_handle(fun check_upgrade_stone/2, [PlayerStatus, 0, [], GoodsStatus], StoneList) of
                        {fail, Res} ->
                            {fail, Res};
                        {ok, [_, Num, NewStoneList, _]} ->
                            Mou = PlayerStatus#player_status.mount,
                            case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
                                [] ->
                                    {fail, 2};
                                [Mount] ->
                                    if
                                        Mount#ets_mount.role_id =/= PlayerStatus#player_status.id ->
                                            {fail, 3};
                                        true ->
                                            Rule = data_mount:get_mount_quality_attr_cfg(Type),
                                            [{GoodsInfo, _}|_] = NewStoneList,
                                            if
                                                is_record(Rule, mount_quality_attr_cfg) =:= false ->
                                                    {fail, 7};
                                                true ->
                                                    [{GoodId, NeedNum}] = Rule#mount_quality_attr_cfg.goods,
                                                    if
                                                        
                                                        GoodsInfo#goods.goods_id =/= GoodId ->
                                                            {fail, 8};
                                                        Num =/= NeedNum ->
                                                            {fail, 11};
                                                        true ->
                                                            {ok, Mount, Type, 0, NewStoneList, Rule}
                                                    end
                                            end
                                    end
                            end
                    end;
                _ ->
                    {fail, 0}
            end
    end.

%% 新版资质培养
mount_up_quality(PS, Mount, Type, Coin, StoneList, Rule, GoodsStatus) ->
    case Type of
        1 ->
            About = lists:concat(["mount_up_quality_", Mount#ets_mount.id, "_", Mount#ets_mount.type_id, "_coin_type_used:", Coin]),
            NewPS = lib_goods_util:cost_money(PS, Coin, coin),
            log:log_consume(mount_up_quality, coin, PS, NewPS, Mount#ets_mount.id, 1, About),
            NewMount = mount_quality_cul(Mount, Rule),
            log:log_mount_quality(Mount, NewMount,NewPS#player_status.lv, Type, 0, 0, Coin, About),
            Mou = PS#player_status.mount,
            OldDict = Mou#status_mount.mount_dict,
            MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, OldDict),
            NewPS1 = lib_mount:change_player_status(NewPS, MountDict), 
            {ok, 1, NewPS1, GoodsStatus, NewMount};
        2 ->
            F = fun() ->
                        ok = lib_goods_dict:start_dict(),
                        {ok, NewStatus} =  lib_goods:delete_goods_list(GoodsStatus, StoneList),
                        Bind1 = lib_goods_compose:get_bind(StoneList),
                        case Mount#ets_mount.bind > 0 orelse Bind1 > 0 of
                            true ->
                                _Trade = 1,
                                _Bind = 2;
                            false ->
                                _Bind = 0,
                                _Trade = 0
                        end,
                        case length(StoneList) of
                            2 ->
                                [{GoodsInfo, N1}, {_, N2}] = StoneList,
                                Num = N1 + N2;
                            _ ->
                                [{GoodsInfo, Num}|_] = StoneList
                        end,
                        %% 日志
                        About1 = lib_goods_compose:get_about([{GoodsInfo,1}]),
                        NewMount = mount_quality_cul(Mount, Rule),
                        log:log_mount_quality(Mount, NewMount,PS#player_status.lv, Type, GoodsInfo#goods.goods_id, Num, 0, About1),
                        %% 内存
                        Mou = PS#player_status.mount,
                        OldDict = Mou#status_mount.mount_dict,
                        MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, OldDict),
                        NewPS = lib_mount:change_player_status(PS, MountDict), 
                        %% 更新背包
                        Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                        NewStatus1 = NewStatus#goods_status{dict = Dict},
                        {ok, 1, NewPS, NewStatus1, NewMount}
                end,
            lib_goods_util:transaction(F)
    end.

%%　资质属性替换/取消
replace_quality_attr(PS, Mount, Type) ->
    case Type of
        1 -> 
            
            NewMount = Mount#ets_mount{temp_quality_attr = []},
            log:log_mount_quality_replace(Mount, NewMount,PS#player_status.lv, Type),
            Mou = PS#player_status.mount,
            OldDict = Mou#status_mount.mount_dict,
            MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, OldDict),
            NewPS = lib_mount:change_player_status(PS, MountDict), 
            {ok, 1, NewPS, NewMount};
        2 ->
            TempQualityAttr = Mount#ets_mount.temp_quality_attr,
            NewQualityAttr = remove_cut_num_quality_attr(TempQualityAttr),
			TotalQualityStar = data_mount_config:get_quality_attr_total_star(NewQualityAttr),
			NewQualityLv = data_mount_config:get_quality_lv(TotalQualityStar),
            NewMount1 = Mount#ets_mount{quality_attr = NewQualityAttr, quality_lv = NewQualityLv, temp_quality_attr = []},
            NewMount = count_mount_attribute(NewMount1),
            UpSQL = io_lib:format(?SQL_UP_MOUNT_QUALITY,[util:term_to_string(NewQualityAttr), NewQualityLv, 
                                                         NewMount#ets_mount.id, PS#player_status.id]),
            db:execute(UpSQL),
            log:log_mount_quality_replace(Mount, NewMount,PS#player_status.lv, Type),
            %% 更新玩家内存数据            
            Mou = PS#player_status.mount,
			OldDict = Mou#status_mount.mount_dict,
            MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, OldDict),
            NewPS = lib_mount:change_player_status(PS, MountDict), 
            %% NewPS = PS#player_status{mount = Mou#status_mount{mount_dict = MountDict}},
            {ok, 1, NewPS, NewMount}
    end.

%%　资质的计算
mount_quality_cul(Mount, Rule) ->
    OldQualityAttr = Mount#ets_mount.quality_attr,
    TempQualityAttr = mount_quality_cul1(OldQualityAttr, Rule),
    %% io:format("~p ~p OldQualityAttr:~p, ~nTempQualityAttr:~p~n", [?MODULE, ?LINE, OldQualityAttr, TempQualityAttr]),
    NewMount = Mount#ets_mount{temp_quality_attr = TempQualityAttr},
    NewMount.

mount_quality_cul1(OldQualityAttr, Rule)->
    Fun =fun({Type, Value, StarNum}, TempQualityAttr) ->
                 AttrCfg = get_quality_attr_grow_cfg(Rule, Type),
                 case AttrCfg of
                     [] ->
                         [{Type, Value, StarNum, 0}|TempQualityAttr];
                     [{_AttrType, GrowNum}, {max_star, MaxStar}, {max_attr, MaxValue}, {radio, Radio}] ->
                         TotalRatio = lib_goods_util:get_ratio_total(Radio, 2),
                         Rand = util:rand(1, TotalRatio),
                         case lib_goods_util:find_ratio(Radio, 0, Rand, 2) of
                             null -> 
                                 [{Type, Value, StarNum, 0}|TempQualityAttr];
                             {MultipStarNum, _Rate} ->
                                 if
                                     MultipStarNum >= 0 ->
                                         if
                                             StarNum >= MaxStar ->
                                                 [{Type, Value, MaxStar, 0}|TempQualityAttr];
                                             true ->
                                                 Add = GrowNum * MultipStarNum,
                                                 NewValue = Value + GrowNum * MultipStarNum,
                                                 NewStarNum = StarNum + MultipStarNum,
                                                 if
                                                     NewStarNum > MaxStar ->
                                                         [{Type, MaxValue, MaxStar, MaxValue - Value}|TempQualityAttr];
                                                     true ->
                                                         [{Type, NewValue, NewStarNum, Add}|TempQualityAttr]  
                                                 end
                                         end;
                                     true ->
                                         Cut = GrowNum * MultipStarNum,
                                         NewValue = Value + GrowNum * MultipStarNum,
                                         NewStarNum = StarNum + MultipStarNum,
                                         if
                                             NewValue < 0 ->
                                                 CutStarNum = -(Value div GrowNum),
                                                 CutValue = -(Value),
                                                 [{Type, 0, CutStarNum , CutValue}|TempQualityAttr];
                                             true ->
                                                 [{Type, NewValue, NewStarNum, Cut}|TempQualityAttr]  
                                         end
                                 end
                         end
                 end
         end,         
    lists:foldl(Fun, [], OldQualityAttr).


%% check_up_quality(PlayerStatus, MountId, Type, Coin, StoneList, GoodsStatus) ->
%%     case lib_goods_check:list_handle(fun check_upgrade_stone/2, [PlayerStatus, 0, [], GoodsStatus], StoneList) of
%%         {fail, Res} ->
%%             {fail, Res};
%%         {ok, [_, Num, NewStoneList, _]} ->
%%             Mou = PlayerStatus#player_status.mount,
%%             case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
%%                 [] ->
%%                     {fail, 5};
%%                 [Mount] ->
%%                     if
%%                         Mount#ets_mount.role_id =/= PlayerStatus#player_status.id ->
%%                             {fail, 6};
%%                         true ->
%%                             if
%%                                 Mount#ets_mount.point+1 =:= 10 ->
%%                                     Rule = data_mount:get_mount_quality(Mount#ets_mount.quality+1, 0);
%%                                 true ->
%%                                     Rule = data_mount:get_mount_quality(Mount#ets_mount.quality, Mount#ets_mount.point+1)
%%                             end,
%%                             [{GoodsInfo, _}|_] = NewStoneList,
%%                             if
%%                                 is_record(Rule, mount_up_quality) =:= false ->
%%                                     {fail, 7};
%%                                 GoodsInfo#goods.goods_id =/= Rule#mount_up_quality.goods_id ->
%%                                     {fail, 8};
%%                                 Num =/= Rule#mount_up_quality.num ->
%%                                     {fail, 9};
%%                                 %(PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < Rule#mount_up_quality.coin ->
%%                                 %    {fail, 11};
%%                                 Mount#ets_mount.point >= 10 orelse Mount#ets_mount.quality >= 5 ->
%%                                     {fail, 12};
%%                                 Mount#ets_mount.quality >= 4 andalso Mount#ets_mount.level < 5 ->
%%                                     {fail, 13};
%%                                 true ->
%%                                     {ok, Mount, NewStoneList, Rule}
%%                             end
%%                     end
%%             end
%%     end.
 
%% mount_up_quality(PlayerStatus, Mount, Type, Coin, StoneList, Rule, GoodsStatus) ->
%%      F = fun() ->
%%         ok = lib_goods_dict:start_dict(),
%%         {ok, NewStatus} =  lib_goods:delete_goods_list(GoodsStatus, StoneList),
%%         Bind1 = lib_goods_compose:get_bind(StoneList),
%%         case Mount#ets_mount.bind > 0 orelse Bind1 > 0 of
%%             true ->
%%                 Trade = 1,
%%                 Bind = 2;
%%             false ->
%%                 Bind = 0,
%%                 Trade = 0
%%         end,
%%         Ram = util:rand(1, 100),
%%         case length(StoneList) of
%%             2 ->
%%                 [{GoodsInfo, N1}, {_, N2}] = StoneList,
%%                 Num = N1 + N2;
%%             _ ->
%%                 [{GoodsInfo, Num}|_] = StoneList
%%         end,
%%         About1 = lib_goods_compose:get_about([{GoodsInfo,1}]),
%%         if
%%             Rule#mount_up_quality.radio >= Ram ->
%%                 Res = 1,
%%                 NewMount = mount_quality_ok(Mount, Bind, Trade, PlayerStatus),                
%%                 log:log_mount_quality(Mount, NewMount, GoodsInfo#goods.goods_id, Num, 0, Ram, 1, PlayerStatus#player_status.lv, NewMount#ets_mount.quality_value, About1);
%%             true ->
%%                 case Mount#ets_mount.quality_value >= Rule#mount_up_quality.max_value of
%%                     true ->
%%                         Res = 1,
%%                         NewMount = mount_quality_ok(Mount, Bind, Trade, PlayerStatus),                
%%                         log:log_mount_quality(Mount, NewMount, GoodsInfo#goods.goods_id, Num, 0, Ram, 1, PlayerStatus#player_status.lv, NewMount#ets_mount.quality_value, About1);
%%                     false ->
%%                         Res = 0,
%%                         NewMount = mount_quality_fail(Mount, Bind, Trade),
%%                         log:log_mount_quality(Mount, NewMount, GoodsInfo#goods.goods_id, Num, 0, Ram, 0, PlayerStatus#player_status.lv, NewMount#ets_mount.quality_value, About1)
%%                 end
%%         end,
%%         Mou = PlayerStatus#player_status.mount,
%%         OldDict = Mou#status_mount.mount_dict,
%%         MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, OldDict),
%%         NewPlayerStatus1 = lib_mount:change_player_status(PlayerStatus, MountDict), 
%%         Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
%%         NewStatus1 = NewStatus#goods_status{dict = Dict},
%%         {ok, Res, NewPlayerStatus1, NewStatus1, NewMount}
%%     end,
%%     lib_goods_util:transaction(F).

%% mount_quality_ok(Mount, Bind, Trade, PlayerStatus) ->
%%     Point1 = Mount#ets_mount.point + 1,
%%     if
%%         Point1 >= 10 ->
%%             Point = 0,
%%             Quality = Mount#ets_mount.quality + 1,
%%             %% 传闻
%%             lib_chat:send_TV({all},0,2, ["horseZizhi",  
%%                                          PlayerStatus#player_status.id, 
%%                                          PlayerStatus#player_status.realm, 
%%                                          PlayerStatus#player_status.nickname, 
%%                                          PlayerStatus#player_status.sex, 
%%                                          PlayerStatus#player_status.career, 
%%                                          PlayerStatus#player_status.image, 
%%                                          Mount#ets_mount.type_id, 
%%                                          Quality]);
%%         true ->
%%             Point = Mount#ets_mount.point + 1,
%%             Quality = Mount#ets_mount.quality
%%     end,
%%     NewMount1 = Mount#ets_mount{quality = Quality, point = Point, quality_value = 0},
%%     NewMount2 = count_mount_attribute(NewMount1),
%%     NewMount = NewMount2#ets_mount{bind = Bind, trade = Trade},
%%     Sql = io_lib:format(?sql_quality_ok, [util:term_to_string(NewMount#ets_mount.attribute), util:term_to_string(NewMount#ets_mount.attribute2),NewMount#ets_mount.bind, NewMount#ets_mount.trade, NewMount#ets_mount.combat_power, NewMount#ets_mount.quality_value, NewMount#ets_mount.point, NewMount#ets_mount.quality, NewMount#ets_mount.id]),
%%     db:execute(Sql),
%%     NewMount.
%% 
%% mount_quality_fail(Mount, Bind, Trade) ->
%%     Value = Mount#ets_mount.quality_value + 1,
%%     NewMount = Mount#ets_mount{quality_value = Value, bind = Bind, trade = Trade},
%%     Sql = io_lib:format(?sql_quality_fail, [NewMount#ets_mount.quality_value, Bind, Trade, NewMount#ets_mount.id]),
%%     db:execute(Sql),
%%     NewMount.

%----------------------------------------------------------------------------------------------------------

%%  获取幻化的形象列表
get_figure_list(Level) ->
    AllList = data_mount:get_upgrade_all(),
    get_figure(AllList, Level, []).

get_figure([], _Level, L) ->
    L;
get_figure([MountId|H], Level, L) ->
    case data_mount:get_mount_upgrade(MountId) of
        [] ->
            get_figure(H, Level, L);
        Upgrade ->
            if
%%                 is_record(Upgrade, mount_upgrade) =:= true andalso Upgrade#mount_upgrade.level =< Level 
%%                   andalso (Upgrade#mount_upgrade.level =/= 2 
%%                           orelse (Upgrade#mount_upgrade.level =:= 2 andalso Upgrade#mount_upgrade.mount_id =:= 311006)) ->
                is_record(Upgrade, mount_upgrade) =:= true andalso Upgrade#mount_upgrade.level =< Level ->
                    %io:format("Upgrade = ~p~n", [{Level, Upgrade#mount_upgrade.level, Upgrade#mount_upgrade.mount_id}]),
                    get_figure(H, Level,[Upgrade#mount_upgrade.mount_id|L]);
                true ->
                    get_figure(H, Level, L)
            end
    end.

%%  获取幻化的形象
get_mount_change_list(Dict, Mid) ->
    Dict1 = dict:filter(fun(_Key, [Value]) -> Value#upgrade_change.mid =:= Mid end, Dict),
    DictList = dict:to_list(Dict1),
    lib_goods_dict:get_list(DictList, []).


%% 
is_change_list(_TypeId, []) ->
    no;
is_change_list(TypeId, [Change|T]) ->
    if
        is_record(Change, upgrade_change) =:= true ->
            if
                Change#upgrade_change.type_id =:= TypeId ->
                    yes;
                true ->
                    is_change_list(TypeId, T)
            end;
        true ->
            is_change_list(TypeId, T)
    end.


%%　幻化操作
change_mount_figure(PS, Mount, Figure) ->
    case data_mount:get_mount_upgrade(Figure) of
        [] ->
            case data_mount:get_mount_figure(Figure) of
                [] ->
                    {fail, 3};
                _Att ->                             
                            F = fun() ->
%%                                         if 
%%                                             Mount#ets_mount.stren >= 7 andalso Mount#ets_mount.stren < 10 ->
%%                                                 NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(2));
%%                                             Mount#ets_mount.stren >= 10 andalso Mount#ets_mount.stren < 12 ->
%%                                                 NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(3));
%%                                             Mount#ets_mount.stren >= 12 ->
%%                                                 NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(4));
%%                                             true ->
%%                                                 NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(1))
%%                                         end,
                                        NewFigure2 = Figure,
                                        NewMount2 = Mount#ets_mount{figure = NewFigure2},
                                        Sql = io_lib:format(?SQL_CHANGE_FIGURE, [NewFigure2, NewMount2#ets_mount.id]),
                                        db:execute(Sql),
                                        Mon = PS#player_status.mount,
                                        Dict = lib_mount:add_dict(NewMount2#ets_mount.id, NewMount2, Mon#status_mount.mount_dict),
                                        %% 如果坐骑不是骑乘状态下，不改变场景和玩家#player_status{}中的形象
                                        NewFigure3 = case NewMount2#ets_mount.status == 0 orelse NewMount2#ets_mount.status == 1 of
                                                         true -> Mon#status_mount.mount_figure;
                                                         false -> NewFigure2
                                                     end,
                                        NewPS = PS#player_status{mount = Mon#status_mount{mount_dict = Dict, mount_figure=NewFigure3}},
                                        {ok, NewPS, NewMount2}
                                end,
                            lib_goods_util:transaction(F)

            end;
        _Upgrade ->
            Mou = PS#player_status.mount,
            List = lib_mount2:get_mount_change_list(Mou#status_mount.change_dict, Mount#ets_mount.id),
            T = is_change_list(Figure, List),
            if
                Mount#ets_mount.role_id =/= PS#player_status.id ->
                    {fail, 4};
                %Upgrade#mount_upgrade.level > Mount#ets_mount.level ->
                %    {fail, 5};
                T =:= no ->
                    {fail, 6};
                true ->
                    F = fun() ->
%%                                 if 
%%                                     Mount#ets_mount.stren >= 7 andalso Mount#ets_mount.stren < 10 ->
%%                                         NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(2));
%%                                     Mount#ets_mount.stren >= 10 andalso Mount#ets_mount.stren < 12 ->
%%                                         NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(3));
%%                                     Mount#ets_mount.stren >= 12 ->
%%                                         NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(4));
%%                                     true ->
%%                                         NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(1))
%%                                 end,
                                NewFigure2 = Figure,
                                %% io:format("~p ~p 16019_NewFigure2:~p~n", [?MODULE, ?LINE, NewFigure2]),
                                NewMount2 = Mount#ets_mount{figure = NewFigure2},
                                Sql = io_lib:format(?SQL_CHANGE_FIGURE, [NewFigure2, NewMount2#ets_mount.id]),
                                db:execute(Sql),
                                Mon = PS#player_status.mount,
                                Dict = lib_mount:add_dict(NewMount2#ets_mount.id, NewMount2, Mon#status_mount.mount_dict),
                                %% 如果坐骑不是骑乘状态下，不改变场景和玩家#player_status{}中的形象
                                NewFigure3 = case NewMount2#ets_mount.status == 0 orelse NewMount2#ets_mount.status == 1 of
                                                 true -> Mon#status_mount.mount_figure;
                                                 false -> NewFigure2
                                             end,
                                NewPS = PS#player_status{mount = Mon#status_mount{mount_dict = Dict, mount_figure=NewFigure3}},
                                {ok, NewPS, NewMount2}
                        end,
                    lib_goods_util:transaction(F)
            end
    end.


%%  光效id切换
replace_lingxi_gx(PS, Mount, LingXiGXId) ->
    NewMount = Mount#ets_mount{lingxi_gx_id = LingXiGXId},
    UpSQL = io_lib:format(?SQL_UP_MOUNT_LINGXI_GX_ID, [LingXiGXId, NewMount#ets_mount.id, PS#player_status.id]),
    db:execute(UpSQL),
    OldDict = Mount#status_mount.mount_dict,
    MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, OldDict),
    NewPS = lib_mount:change_player_status(PS, MountDict), 
    {ok, 1, NewPS}.                


%% %%　幻化操作
%% change_mount_figure(PS, Mount, Figure) ->
%%     case data_mount:get_mount_upgrade(Figure) of
%%         [] ->
%%             case data_mount:get_attr_add(Figure) of
%%                 [] ->
%%                     {fail, 3};
%%                 _Att ->
%%                     Mou = PS#player_status.mount,
%%                     List = lib_mount2:get_mount_change_list(Mou#status_mount.change_dict, Mount#ets_mount.id),
%%                     io:format("List = ~p~n", [{List, Figure}]),
%%                     T = is_change_list(Figure, List),
%%                     if
%%                         Mount#ets_mount.role_id =/= PS#player_status.id ->
%%                             {fail, 4};
%%                         T =:= no ->
%%                             {fail, 6};
%%                         true ->
%%                             F = fun() ->
%%                                 if 
%%                                  Mount#ets_mount.stren >= 7 andalso Mount#ets_mount.stren < 10 ->
%%                                      NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(2));
%%                                  Mount#ets_mount.stren >= 10 andalso Mount#ets_mount.stren < 12 ->
%%                                      NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(3));
%%                                  Mount#ets_mount.stren >= 12 ->
%%                                      NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(4));
%%                                  true ->
%%                                      NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(1))
%%                              end,
%%                                 NewMount2 = Mount#ets_mount{figure = NewFigure2},
%%                                 Sql = io_lib:format(?SQL_CHANGE_FIGURE, [NewFigure2, NewMount2#ets_mount.id]),
%%                                 db:execute(Sql),
%%                                 Mon = PS#player_status.mount,
%%                                 Dict = lib_mount:add_dict(NewMount2#ets_mount.id, NewMount2, Mon#status_mount.mount_dict),
%%                                 %% 如果坐骑不是骑乘状态下，不改变场景和玩家#player_status{}中的形象
%%                                 NewFigure3 = case NewMount2#ets_mount.status == 0 orelse NewMount2#ets_mount.status == 1 of
%%                                     true -> Mon#status_mount.mount_figure;
%%                                     false -> NewFigure2
%%                                 end,
%%                                 NewPS = PS#player_status{mount = Mon#status_mount{mount_dict = Dict, mount_figure=NewFigure3}},
%%                                 {ok, NewPS, NewMount2}
%%                             end,
%%                             lib_goods_util:transaction(F)
%%                     end
%%             end;
%%         _Upgrade ->
%%             Mou = PS#player_status.mount,
%%             List = lib_mount2:get_mount_change_list(Mou#status_mount.change_dict, Mount#ets_mount.id),
%%             T = is_change_list(Figure, List),
%%             if
%%                 Mount#ets_mount.role_id =/= PS#player_status.id ->
%%                     {fail, 4};
%%                 %Upgrade#mount_upgrade.level > Mount#ets_mount.level ->
%%                 %    {fail, 5};
%%                 T =:= no ->
%%                     {fail, 6};
%%                 true ->
%%                     F = fun() ->
%%                         %NewMount1 = Mount#ets_mount{type_id = Figure},
%%                         if 
%%                             Mount#ets_mount.stren >= 7 andalso Mount#ets_mount.stren < 10 ->
%%                                 NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(2));
%%                             Mount#ets_mount.stren >= 10 andalso Mount#ets_mount.stren < 12 ->
%%                                 NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(3));
%%                             Mount#ets_mount.stren >= 12 ->
%%                                 NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(4));
%%                             true ->
%%                                 NewFigure2 = list_to_integer(integer_to_list(Figure) ++ integer_to_list(1))
%%                         end,
%%                         NewMount2 = Mount#ets_mount{figure = NewFigure2},
%%                         Sql = io_lib:format(?SQL_CHANGE_FIGURE, [NewFigure2, NewMount2#ets_mount.id]),
%%                         db:execute(Sql),
%%                         Mon = PS#player_status.mount,
%%                         Dict = lib_mount:add_dict(NewMount2#ets_mount.id, NewMount2, Mon#status_mount.mount_dict),
%%                         %% 如果坐骑不是骑乘状态下，不改变场景和玩家#player_status{}中的形象
%%                         NewFigure3 = case NewMount2#ets_mount.status == 0 orelse NewMount2#ets_mount.status == 1 of
%%                             true -> Mon#status_mount.mount_figure;
%%                             false -> NewFigure2
%%                         end,
%%                         NewPS = PS#player_status{mount = Mon#status_mount{mount_dict = Dict, mount_figure=NewFigure3}},
%%                         {ok, NewPS, NewMount2}
%%                     end,
%%                     lib_goods_util:transaction(F)
%%             end
%%     end.


%%============================================坐骑飞行器===================================================
get_fly_list(Star) ->
    AllList = data_mount:get_fly_all(),
    get_fly_figure(AllList, Star, []).

get_fly_figure([], _Star, L) ->
    L;
get_fly_figure([StarId|H], Star, L) ->
    case data_mount:get_mount_fly(StarId) of
        [] ->
            get_fly_figure(H, Star, L);
        Fly ->
            if
                is_record(Fly, up_fly_star) =:= true andalso Fly#up_fly_star.star =< Star ->
                    get_fly_figure(H, Star,[Fly#up_fly_star.fly_figure|L]);
                true ->
                    get_fly_figure(H, Star, L)
            end
    end.

get_figure_star(Figure) ->
    AllList = data_mount:get_fly_all(),
    get_star(AllList, Figure).
get_star([], _) ->
    0;
get_star([Star|H], F) ->
    case data_mount:get_mount_fly(Star) of
        [] ->
            get_star(H,F);
        Fly ->
            if
                is_record(Fly, up_fly_star) =:= true andalso Fly#up_fly_star.fly_figure =< F ->
                    Fly#up_fly_star.star;
                true ->
                    get_star(H, F)
            end
    end.

change_mount_fly(PS, Mount, Figure) ->
    Star = get_figure_star(Figure),
    if
        Star > Mount#ets_mount.star orelse Star =:= 0 ->
            {fail, 3};
        Mount#ets_mount.role_id =/= PS#player_status.id ->
            {fail, 4};
        true ->
            F = fun() ->
                        NewMount = Mount#ets_mount{fly_id = Figure},
                        Sql = io_lib:format(?sql_change_fly, [Figure, NewMount#ets_mount.id]),
                        db:execute(Sql),
                        Mon = PS#player_status.mount,
                        Dict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, Mon#status_mount.mount_dict),
                        NewPS = PS#player_status{mount = Mon#status_mount{mount_dict = Dict}},
                        {ok, NewPS}
            end,
            lib_goods_util:transaction(F)
    end.

%% get_new_figure(PS) ->
%%     Mou = PS#player_status.mount,
%%     Mount = lib_mount:get_equip_mount(PS#player_status.id, Mou#status_mount.mount_dict),
%%     case Mount#ets_mount.id > 0 of
%%         true ->
%%             [A,B,C,D,E,F,_] = integer_to_list(Mount#ets_mount.figure),
%%             if
%%                 Mount#ets_mount.stren >= 7 andalso Mount#ets_mount.stren < 10 ->
%%                     list_to_integer([A,B,C,D,E,F] ++ integer_to_list(2));
%%                 Mount#ets_mount.stren >= 10 andalso Mount#ets_mount.stren < 12 ->
%%                     list_to_integer([A,B,C,D,E,F] ++ integer_to_list(3));
%%                 Mount#ets_mount.stren >= 12 ->
%%                     list_to_integer([A,B,C,D,E,F] ++ integer_to_list(4));
%%                 true ->
%%                     Mount#ets_mount.figure
%%             end;
%%         false ->
%%             Mount#ets_mount.figure
%%     end.

get_new_figure(PS) ->
    Mou = PS#player_status.mount,
    Mount = lib_mount:get_equip_mount(PS#player_status.id, Mou#status_mount.mount_dict),
    case Mount#ets_mount.id > 0 of
        true ->
            Mount#ets_mount.figure;
        false ->
            Mount#ets_mount.figure
    end.


%% 形象id
%% get_typeid_from_figure(Figure) ->
%%     L = integer_to_list(Figure),
%%     case length(L) of
%%         7 ->
%%             [A,B,C,D,E,F,_] = L,
%%             list_to_integer([A,B,C,D,E,F]);
%%         _ ->
%%             0
%%     end.
get_typeid_from_figure(Figure) ->
    Figure.
    

plus_attr([L1|T1], [L2|T2]) ->
    [L1+L2|plus_attr(T1,T2)];
plus_attr([], L) -> L.

get_attribute5([], L) ->
    L;
get_attribute5([[TypeId]|H], L) ->
    T = lists:member(TypeId, ?figure_list),
    if
        T =:= true ->
            Attr = data_mount:get_attr_add(TypeId),
            L2 = plus_attr([Attr#attr_add.hp,Attr#attr_add.att,
                    Attr#attr_add.fire, Attr#attr_add.ice,
                    Attr#attr_add.drug], L),
            get_attribute5(H, L2);
        true ->
            get_attribute5(H, L)
    end.

is_typeid_change([], _TypeId) ->
    no;
is_typeid_change([Change|T], TypeId) ->
    NowTime = util:unixtime(),
    if
        is_record(Change, upgrade_change) =:= true ->
            if
                Change#upgrade_change.type_id =:= TypeId orelse (Change#upgrade_change.time =< NowTime andalso Change#upgrade_change.time =/= 0) ->
                    yes;
                true ->
                    is_typeid_change(T, TypeId)
            end;
        true ->
            is_typeid_change(T, TypeId)
    end.

%%============================================坐骑物品使用===================================================
%% 使用灵犀丹
use_lingxi_dan(PS, GoodsInfo) ->
    case data_mount:get_mount_lingxi_good(GoodsInfo#goods.goods_id) of
        [] ->
            %% 灵犀丹类型不存在
            {fail, ?ERRCODE15_NO_GOODS_TYPE};
        LingXiGoodRecord ->
            Mount = PS#player_status.mount,
            M = lib_mount:get_equip_mount(PS#player_status.id, Mount#status_mount.mount_dict),
            if  
                M#ets_mount.id =< 0 -> %% 坐骑未出战
                    {fail, ?ERRCODE15_FASHION_NONE};
                true ->
                    %%　计算新的坐骑属性值
                    LingXiGoodNum = LingXiGoodRecord#mount_lingxi_good.lingxi_num,
                    LingXiGoodAttr = LingXiGoodRecord#mount_lingxi_good.attr,
                    LingXiLv = data_mount_config:get_lingxi_lv(M#ets_mount.lingxi_num),
                    LingXiAttrLim = case data_mount:get_mount_lingxi_lv(LingXiLv) of
                                        [] -> [];
                                        LingXiLvRecord -> LingXiLvRecord#mount_lingxi_lv.lim_attr
                                    end,
                    NewLingXiNum = M#ets_mount.lingxi_num + LingXiGoodNum,
                    NewLingXiAttr = plus_list_by_type_lingxi(M#ets_mount.lingxi_attr, LingXiGoodAttr, LingXiAttrLim),
                    NewM = M#ets_mount{lingxi_num = NewLingXiNum, lingxi_attr = NewLingXiAttr},
                    
                    NewMount = count_mount_attribute(NewM),
                    log:log_mount_lingxi(M, NewMount, PS#player_status.lv, GoodsInfo#goods.goods_id, 1),
                    %% 更新数据库
                    Sql3 = io_lib:format(?SQL_UP_MOUNT_LINGXI_ATTR, 
                                         [util:term_to_string(NewMount#ets_mount.attribute), 
                                          NewMount#ets_mount.combat_power, NewMount#ets_mount.lingxi_num, 
                                          util:term_to_string(NewMount#ets_mount.lingxi_attr), NewMount#ets_mount.id]),
                    db:execute(Sql3),
                    
                    %% 更新玩家内存数据
                    Dict = lib_mount:add_dict(NewM#ets_mount.id, NewMount, Mount#status_mount.mount_dict),
                    NewPS=PS#player_status{mount = Mount#status_mount{mount_dict=Dict}},
                    NewPS2 = lib_player:count_player_attribute(NewPS),
                    {ok, NewPS2}
            end
    end.


%% 使用幻化卡
use_change_card(PS, GoodsInfo) ->
    case data_mount:get_mount_figure(GoodsInfo#goods.goods_id) of
        [] ->
            %% 形象类型不存在
            {fail, ?ERRCODE15_NO_GOODS_TYPE};
        Attr ->
            Mount = PS#player_status.mount,
            M = lib_mount:get_equip_mount(PS#player_status.id, Mount#status_mount.mount_dict),
            if  
                M#ets_mount.id =< 0 -> %% 坐骑未出战
                    {fail, ?ERRCODE15_FASHION_NONE}; 
                true ->
                    List = lib_mount2:get_mount_change_list(Mount#status_mount.change_dict, M#ets_mount.id),
                    T1 = is_typeid_change(List, GoodsInfo#goods.goods_id),
%%                     T3 = is_typeid_change(List, 311002),
%%                     T2 = is_typeid_change(List, 311004),
                    %% io:format("add.... = ~p~n", [{List, T1, T2, T3, GoodsInfo#goods.goods_id}]),
                    if
                        T1 =:= yes ->
                            {fail, ?ERRCODE15_HAVE_CHANGE};
%%                         T3 =:= yes andalso GoodsInfo#goods.goods_id =:= 311501 ->
%%                             {fail, ?ERRCODE15_HAVE_CHANGE};
%%                         T2 =:= yes andalso GoodsInfo#goods.goods_id =:= 311502 ->
%%                             {fail, ?ERRCODE15_HAVE_CHANGE};
                        true ->
%%                             if
%%                                 GoodsInfo#goods.goods_id =:= 311501 ->
%%                                     Fig = 311002;
%%                                 GoodsInfo#goods.goods_id =:= 311502 ->
%%                                     Fig = 311004;
%%                                 true ->
%%                                     Fig = Attr#figure_attr_add.figure_id
%%                             end,
%%                             %% Flist = integer_to_list(Fig) ++ integer_to_list(1),
%%                             Flist = integer_to_list(Fig),
%%                             Figure = list_to_integer(Flist),
                            Figure = Attr#figure_attr_add.figure_id,

                            if
                                Attr#figure_attr_add.time > 0 ->
                                    Time = util:unixtime() + Attr#figure_attr_add.time * 86400,
                                    State = 1;
                                true ->
                                    Time = 0,
                                    State = 3
                            end,
                            Change = #upgrade_change{
                                                     mid = M#ets_mount.id,
                                                     pid = PS#player_status.id,
                                                     time = Time,
                                                     %% type_id = Fig,
                                                     type_id = Figure,
                                                     state = State
                                                    },
                            % 新增数据到幻化表+更新内存
                            Sql2 = io_lib:format(<<"insert into upgrade_change set mid=~p, pid=~p, type_id=~p, time=~p, state=~p">>, 
                                                 [Change#upgrade_change.mid, Change#upgrade_change.pid, Change#upgrade_change.type_id, 
                                                  Change#upgrade_change.time, Change#upgrade_change.state]),
                            db:execute(Sql2),
                            
                            Key = integer_to_list(Change#upgrade_change.mid) ++ integer_to_list(Change#upgrade_change.type_id),
                            ChangeDict = lib_mount:add_dict(Key, Change, Mount#status_mount.change_dict),
                            
                            NewMount = M#ets_mount{figure = Figure},
                            %% io:format("add22.... = ~p~n", [{Figure, GoodsInfo#goods.goods_id}]),
%%                             Sql = io_lib:format(?SQL_CHANGE_FIGURE, [Figure, NewMount#ets_mount.id]),
%%                             db:execute(Sql),
                            %% 计算新的属性
                            NewMount2 = count_mount_attribute(NewMount),
                            %% io:format("~p ~p PowerCompare:~p~n", [?MODULE, ?LINE,[NewMount#ets_mount.combat_power, NewMount2#ets_mount.combat_power]]),
                            Sql3 = io_lib:format(<<"UPDATE mount SET figure = ~p, combat_power=~p WHERE id=~p">>, 
                                                 [NewMount2#ets_mount.figure, NewMount2#ets_mount.combat_power, NewMount2#ets_mount.id]),
                            %% io:format("~p ~p Sql3:~ts~n", [?MODULE, ?LINE, Sql3]),
                            db:execute(Sql3),
                            
                            Dict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount2, Mount#status_mount.mount_dict),
                            if
                                M#ets_mount.status =:= 2 ->
                                    NewPS = PS#player_status{mount = Mount#status_mount{mount_dict = Dict, change_dict = ChangeDict, mount_figure=Figure}};
                                true ->
                                    NewPS = PS#player_status{mount = Mount#status_mount{mount_dict = Dict, change_dict = ChangeDict}}
                            end,
                            %% 计算任务属性
                            NewPS2 = lib_player:count_player_attribute(NewPS),
                            
                            %% [NewPS, List2] = lib_mount3:check_time(MList, NewPS2, []),
                            %% 组装数据发送到客户端
                            MList = get_mount_change_list(ChangeDict, NewMount#ets_mount.id),
                            NewFigureList = data_mount_config:get_diff_change_figure_list(MList),
                            FigureAttr = data_mount_config:get_figure_attr(NewFigureList),
                            %% io:format("~p ~p NewFigureList:~p, FigureAttr:~p~n", [?MODULE, ?LINE, NewFigureList, FigureAttr]),
                            {ok, BinData} = pt_160:write(16018, [1, NewMount#ets_mount.figure, NewFigureList, FigureAttr]),
                            lib_server_send:send_one(NewPS2#player_status.socket, BinData),
                            {ok, NewPS2}
                    end
            end
    end.


%% 检查幻化卡过期
check_mount_time(PS) ->
    Mou = PS#player_status.mount,
    Mount = lib_mount:get_equip_mount(PS#player_status.id, Mou#status_mount.mount_dict),
    case Mount#ets_mount.id > 0 of
        true ->
            List = lib_mount2:get_mount_change_list(Mou#status_mount.change_dict, Mount#ets_mount.id),
            [NewPS, _List2] = lib_mount3:check_time(List, PS, []),
            lib_player:send_attribute_change_notify(NewPS, 3);
        false ->
            NewPS = PS
    end,
    NewPS.


%% 最终属性=（坐骑进阶属性+坐骑资质属性）*（1+灵犀值对应阶段百分比）+坐骑灵犀值固定属性+坐骑幻化属性+资质星级奖励属性。
count_mount_attribute(Mount) ->
    %% TypeId = Mount#ets_mount.type_id,
    %% io:format("~p ~p TypeId:~p~n", [?MODULE, ?LINE, TypeId]),
    Upgrade = data_mount:get_mount_upgrade(Mount#ets_mount.type_id),
    %% 坐骑当前进阶属性
    [UpgradeAttr, Speed, Level] = case is_record(Upgrade, mount_upgrade) of
                      true ->
                          [Upgrade#mount_upgrade.attr, Upgrade#mount_upgrade.speed, Upgrade#mount_upgrade.level];
                      false ->
                          [[], 0, 0]
                  end,
    %% io:format("~p ~p [UpgradeAttr, Level]:~p~n", [?MODULE, ?LINE, [UpgradeAttr, Level]]),
    %%　当前星星属性
    MountUpgradeStar = data_mount:get_mount_upgrade_star(Mount#ets_mount.star, Level),
    StarAttr = case is_record(MountUpgradeStar, mount_upgrade_star) of
                   true ->
                       MountUpgradeStar#mount_upgrade_star.attr;
                   false ->
                       []
               end,
    %% io:format("~p ~p [StarAttr]:~p~n", [?MODULE, ?LINE, StarAttr]),
    %% 资质总星额外属性和资质培养属性
    QualityStar = data_mount:get_mount_quality(Mount#ets_mount.quality_lv),
    QualityStarAttr = case is_record(QualityStar, mount_quality) of
                      true ->
                          QualityStar#mount_quality.attr;
                      false ->
                          []
                  end,
    %% io:format("~p ~p [QualityStarAttr]:~p~n", [?MODULE, ?LINE, QualityStarAttr]),
    QualityAttr = Mount#ets_mount.quality_attr,
    %% io:format("~p ~p [QualityAttr]:~p~n", [?MODULE, ?LINE, QualityAttr]),
    
    %% 灵犀属性百分比和使用灵犀丹属性
    LingXiLv = data_mount_config:get_lingxi_lv(Mount#ets_mount.lingxi_num),
    LingXiRecord = data_mount:get_mount_lingxi_lv(LingXiLv),
    LingXiPer = case is_record(LingXiRecord, mount_lingxi_lv) of
                      true ->
                          LingXiRecord#mount_lingxi_lv.lingxi_p;
                      false ->
                          0
                  end,
    LingXiAttr = Mount#ets_mount.lingxi_attr,
    %% io:format("~p ~p [LingXiLv, LingXiAttr, LingXiPer]:~p~n", [?MODULE, ?LINE, [LingXiLv, LingXiAttr, LingXiPer]]),
    
    %% 幻化属性
    NowTime = util:unixtime(),
    SeSQL = io_lib:format(?SQL_MOUNT_FIFURE_BY_TIME, [Mount#ets_mount.id, NowTime]),
    AllFigureList = db:get_all(SeSQL),
    AllFigureList1 = lists:flatten(AllFigureList),
    [ChangeFigureList, _LevelFigureList] = get_change_figure_list(AllFigureList1),
    FigureAttr = case ChangeFigureList of
                    [] -> [];
                    ChangeFigureList ->
                        get_attr_from_figure(ChangeFigureList)
                 end,
    %% io:format("~p ~p [FigureAttr]:~p~n", [?MODULE, ?LINE, FigureAttr]),
    %% 基础属性 = 坐骑当阶基础属性 + 坐骑升星属性 + 资质培养属性 
    NewUpgradeAttr1 = plus_list_by_type(UpgradeAttr, StarAttr),
    %% io:format("~p ~p NewUpgradeAttr1:~p~n", [?MODULE, ?LINE, NewUpgradeAttr1]),
    BaseAttr = plus_list_by_type(NewUpgradeAttr1, QualityAttr),
    %% io:format("~p ~p BaseAttr:~p~n", [?MODULE, ?LINE, BaseAttr]),
    %% 基础属性*(1+P):灵犀百分比
    NewAttr1 = count_attr_per(BaseAttr, LingXiPer),
    %% io:format("~p ~p NewAttr1:~p~n", [?MODULE, ?LINE, NewAttr1]),
    %%　+坐骑灵犀值固定属性+坐骑幻化属性+资质星级奖励属性　
    NewAttr2 = plus_list_by_type(NewAttr1, LingXiAttr),
    %% io:format("~p ~p NewAttr2:~p~n", [?MODULE, ?LINE, NewAttr2]),
    NewAttr3 = plus_list_by_type(NewAttr2, FigureAttr),
    %% io:format("~p ~p NewAttr3:~p~n", [?MODULE, ?LINE, NewAttr3]),
    AllAttr = plus_list_by_type(NewAttr3, QualityStarAttr),
    %% io:format("~p ~p AllAttr:~p~n", [?MODULE, ?LINE, AllAttr]),
    AllAttrList = remove_type_less_attr_value(AllAttr),
    %% io:format("~p ~p AllAttrList:~p~n", [?MODULE, ?LINE, AllAttrList]),
    [Hp, _Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug] = AllAttrList,
    Power = round(Hp*0.26 + Def*1.32 + Hit*1.37 + Dodge*1.65 + Crit*3.53 + Ten*1.76 + Att*3.97 + Fire*0.44 + Ice*0.44 +  Drug*0.44),
    %% io:format("~p ~p Power:~p~n", [?MODULE, ?LINE, Power]),
    Mount#ets_mount{attribute = AllAttr, speed = Speed, combat_power = Power, level = Level}.
    

%% 下一阶的坐骑战斗力：
%%　最终属性=（坐骑进阶属性+坐骑资质属性）*（1+灵犀值对应阶段百分比）+坐骑灵犀值固定属性+坐骑幻化属性+资质星级奖励属性。
get_next_level_power(Mount, NextLevel) ->
    %% NextLevelTypeId = data_mount_config:get_mount_type_id_by_level(NextLevel),
    NextLevelTypeId = lib_mount3:get_figure_by_level(NextLevel),
    %% io:format("~p ~p NextLevelTypeId:~p~n", [?MODULE, ?LINE, NextLevelTypeId]),
    NextUpgrade = data_mount:get_mount_upgrade(NextLevelTypeId),
    %% 坐骑进阶属性
    NextUpgradeAttr = case is_record(NextUpgrade, mount_upgrade) of
                          true ->
                              NextUpgrade#mount_upgrade.attr;
                          false ->
                              []
                      end,
    %% io:format("~p ~p NextUpgradeAttr:~p~n", [?MODULE, ?LINE, NextUpgradeAttr]),
    
    %%　下一阶零星星属性
    MountUpgradeStar = data_mount:get_mount_upgrade_star(0, NextLevel),
    StarAttr = case is_record(MountUpgradeStar, mount_upgrade_star) of
                   true ->
                       MountUpgradeStar#mount_upgrade_star.attr;
                   false ->
                       []
               end,
    %% io:format("~p ~p [StarAttr]:~p~n", [?MODULE, ?LINE, StarAttr]),
    %% 资质总星额外属性和资质培养属性
    QualityStar = data_mount:get_mount_quality(Mount#ets_mount.quality_lv),
    QualityStarAttr = case is_record(QualityStar, mount_quality) of
                      true ->
                          QualityStar#mount_quality.attr;
                      false ->
                          []
                  end,
    %% io:format("~p ~p [QualityStarAttr]:~p~n", [?MODULE, ?LINE, QualityStarAttr]),
    QualityAttr = Mount#ets_mount.quality_attr,
    %% io:format("~p ~p [QualityAttr]:~p~n", [?MODULE, ?LINE, QualityAttr]),
    
    %% 灵犀属性百分比和使用灵犀丹属性
    LingXiLv = data_mount_config:get_lingxi_lv(Mount#ets_mount.lingxi_num),
    LingXiRecord = data_mount:get_mount_lingxi_lv(LingXiLv),
    LingXiPer = case is_record(LingXiRecord, mount_lingxi_lv) of
                      true ->
                          LingXiRecord#mount_lingxi_lv.lingxi_p;
                      false ->
                          0
                  end,
    LingXiAttr = Mount#ets_mount.lingxi_attr,
    %% io:format("~p ~p [LingXiLv, LingXiAttr, LingXiPer]:~p~n", [?MODULE, ?LINE, [LingXiLv, LingXiAttr, LingXiPer]]),
    
    %% 幻化属性
    NowTime = util:unixtime(),
    SeSQL = io_lib:format(?SQL_MOUNT_FIFURE_BY_TIME, [Mount#ets_mount.id, NowTime]),
    AllFigureList = db:get_all(SeSQL),
    AllFigureList1 = lists:flatten(AllFigureList),
    [ChangeFigureList, _LevelFigureList] = get_change_figure_list(AllFigureList1),
    FigureAttr = case ChangeFigureList of
                    [] -> [];
                    ChangeFigureList ->
                        get_attr_from_figure(ChangeFigureList)
                 end,
    %% io:format("~p ~p [FigureAttr]:~p~n", [?MODULE, ?LINE, FigureAttr]),
    %% 基础属性 = 坐骑当阶基础属性 + 坐骑升星属性 + 资质培养属性 
    NextUpgradeAttr1 = plus_list_by_type(NextUpgradeAttr, StarAttr),
    
    BaseAttr = plus_list_by_type(NextUpgradeAttr1, QualityAttr),
    %% 基础属性*(1+P):灵犀百分比
    NewAttr1 = count_attr_per(BaseAttr, LingXiPer),
    %%　+坐骑灵犀值固定属性+坐骑幻化属性+资质星级奖励属性　
    NewAttr2 = plus_list_by_type(NewAttr1, LingXiAttr),
    NewAttr3 = plus_list_by_type(NewAttr2, FigureAttr),
    AllAttr = plus_list_by_type(NewAttr3, QualityStarAttr),
    %% io:format("~p ~p AllAttr:~p~n", [?MODULE, ?LINE, AllAttr]),
    AllAttrList = remove_type_less_attr_value(AllAttr),
    %% io:format("~p ~p AllAttrList:~p~n", [?MODULE, ?LINE, AllAttrList]),
    [Hp, _Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug] = AllAttrList,
    NextPower = round(Hp*0.26 + Def*1.32 + Hit*1.37 + Dodge*1.65 + Crit*3.53 + Ten*1.76 + Att*3.97 + Fire*0.44 + Ice*0.44 +  Drug*0.44),
    %% io:format("~p ~p NextPower:~p~n", [?MODULE, ?LINE, NextPower]),
    NextPower.

%%　玩家下线操作
mount_offline(PS) ->
    Mou = PS#player_status.mount,
    Mount = lib_mount:get_equip_mount(PS#player_status.id, Mou#status_mount.mount_dict),
    if
        Mount#ets_mount.status =:= 3 ->
            NewMount = Mount#ets_mount{status = 2},
            Sql = io_lib:format(?sql_fly, [2, NewMount#ets_mount.id]),
            db:execute(Sql),
            MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, Mou#status_mount.mount_dict),
            M = Mou#status_mount{fly = 0, mount_dict = MountDict},
            PS#player_status{mount = M};
        true -> PS
    end.


%%===========================内部属性处理函数================================================================================
check_upgrade_stone({GoodsId, Num}, [PS, N, L, GoodsStatus]) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    %% util:errlog("~p ~p GoodsStatus#goods_status.dict:~p~n", [?MODULE, ?LINE, GoodsStatus#goods_status.dict]),
    %% util:errlog("~p ~p GoodsInfo:~p~n", [?MODULE, ?LINE, GoodsInfo]),
    if
        is_record(GoodsInfo, goods) =:= false ->                       %% 背包里面没有该物品
            {fail, 4};
        GoodsInfo#goods.player_id =/= PS#player_status.id ->           %% 物品不属于你所有
            {fail, 5};
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->                 %% 物品位置不正确 
            {fail, 6};
        GoodsInfo#goods.num < 1 orelse GoodsInfo#goods.num < Num->     %% 物品数量不足
            %% io:format("~p ~p Num:~p, GoodsInfo#goods.num:~p~n", [?MODULE, ?LINE, Num, GoodsInfo#goods.num]),
            {fail, 11};
        true ->
            {ok, [PS, Num+N, [{GoodsInfo, Num}|L], GoodsStatus]}
    end.

%% 获取幻化的形象列表
get_change_figure_list(FigureList)->
    LevelFigure = data_mount:get_upgrade_all(),
    lists:foldl(fun(FigureId, [TempFigureList, TempLevelList])->
                        case lists:member(FigureId, LevelFigure) of
                            true ->
                                [TempFigureList, [FigureId|TempLevelList]];
                            false ->
                                [[FigureId|TempFigureList], TempLevelList]
                        end
                end, [[],[]], FigureList).

%% 幻化形象属性
get_attr_from_figure(ChangeFigureList)->
    FigureList = lists:map(fun(FigureId)->
                                   case data_mount:get_mount_figure(FigureId) of
                                       FigureRecord when is_record(FigureRecord, figure_attr_add) ->
                                           FigureRecord#figure_attr_add.attr;
                                       _ -> []
                                   end
                           end, ChangeFigureList),
    figure_attr_add(FigureList).

%% 将幻化形象属性相加
figure_attr_add([H|[]])-> 
    H;
figure_attr_add([H1, H2|TFigureList])->
    NewH = plus_list_by_type1(H1, H2),
    figure_attr_add([NewH|TFigureList]).

%% 属性相加
plus_list_by_type1(List, []) -> 
    List;
plus_list_by_type1(List, [H|N]) ->
    {Type, Value} =  H,
    case lists:keyfind(Type, 1, List) of
        false -> 
            Value3 = Value;
        {_, Value2} -> 
            Value3 = Value+Value2
    end,
    NewList = lists:keystore(Type, 1, List, {Type, Value3}),
    plus_list_by_type1(NewList, N).

%% 针对灵犀属性写的属性相加方法(达到上限不加)
plus_list_by_type_lingxi(LingXiAttrList, [], _LimAttrList) ->
    LingXiAttrList;
plus_list_by_type_lingxi(LingXiAttrList, [H|N], LimAttrList) ->
    {Type, Value} =  H,
    case lists:keyfind(Type, 1, LingXiAttrList) of
        false -> 
            Value3 = Value;
        {_, Value2} -> 
            Value3 = Value+Value2
    end,
    case lists:keyfind(Type, 1, LimAttrList) of
        false -> 
            Value4 = Value3;
        {_, MaxAttr} -> 
            if
                Value3 >= MaxAttr ->
                    Value4 = MaxAttr;
                true ->
                    Value4 = Value3
            end
    end,
    NewList = lists:keystore(Type, 1, LingXiAttrList, {Type, Value4}),
    plus_list_by_type_lingxi(NewList, N, LimAttrList).
        
%% 属性列表相加(针对全抗，会分别对雷抗,水抗,冥抗加相应属性)
plus_list_by_type(List, []) -> 
    List;
plus_list_by_type(List, [H|N]) ->
    case H of
        {Type, Value} -> {Type, Value};
        {Type, Value, _StarNum} -> {Type, Value}
    end,        
    case lists:keyfind(Type, 1, List) of
        false -> 
            if
                Type =:= 16 ->  %% 如果资质中的全抗属性16
                    [NewList, _ResistList] = lists:foldl(
                                               fun({Type1, Value1}, [TempTypeList, ResistList])->
                                                       case lists:member(Type1, ResistList) of
                                                           true ->
                                                               [[{Type1, Value + Value1}|TempTypeList], ResistList];
                                                           false ->
                                                               [[{Type1, Value1}|TempTypeList], ResistList]
                                                       end
                                               end, [[], [13,14,15]], List),
                    plus_list_by_type(NewList, N);
                true ->
                    Value3 = Value,
                    NewList = lists:keystore(Type, 1, List, {Type, Value3}),
                    plus_list_by_type(NewList, N)
            end;
        {_, Value2} -> 
            Value3 = Value+Value2,
            NewList = lists:keystore(Type, 1, List, {Type, Value3}),
            plus_list_by_type(NewList, N)
    end.

%%　属性减法
sub_list_by_type(List, [])->
    List;
sub_list_by_type(List, [H|N])->
    {Type, Value} =  H,
    case lists:keyfind(Type, 1, List) of
        false -> 
            Value3 = 0;
        {_, Value2} -> 
            if
                Value2 > Value ->
                    Value3 = Value2 - Value;
                true ->
                    Value3 = 0
            end
    end,
    NewList = lists:keystore(Type, 1, List, {Type, Value3}),
    sub_list_by_type(NewList, N).

%%　根据属性类型列表,move属性类型, 剩下属性数值
remove_type_less_attr_value(AttrList)  when is_list(AttrList)->
    AttrTypeList = data_mount_config:get_config(attr_type_list),
    F = fun(Type) ->
                case lists:keyfind(Type, 1, AttrList) of
                    false -> 0;
                    {_, Value} -> Value
                end
        end,
    lists:map(F, AttrTypeList).

%% 将临时的资质属性替换成永久的
remove_cut_num_quality_attr(TempQualityAttr)->
    F = fun({Type, Value, StarNum, _AddOrCut}) ->
                if
                    StarNum < 0 ->
                        {Type, Value, 0};
                    true -> 
                        {Type, Value, StarNum}
                end
        end,
    lists:map(F, TempQualityAttr).

%% 计算添加百分比属性
count_attr_per(AttrList, Per) when is_integer(Per)->
    case Per > 0 of
        true ->
            [{Type, round(Value*(1+Per/1000))} || {Type, Value} <- AttrList];
        _ -> 
            AttrList
    end.
        
%% 判断是否升星和升阶
%% 当前星星数
%% 祝福值
%% 随机数
%% 规则
is_up_star_or_upgrade(StarNum, StarValue, Ram, Rule)->
    Radio = Rule#mount_upgrade_star.radio,
    LimStarNum = Rule#mount_upgrade_star.lim_star,
    LimStarLucky = Rule#mount_upgrade_star.lim_lucky,
    %% io:format("~p ~p StarNum:~p, Ram:~p, Radio:~p, LimStarNum:~p~n", [?MODULE, ?LINE, StarNum, Ram, Radio, LimStarNum]),
    {IsUpStar, NewStar} = case  Radio > Ram of
                            true -> {1, StarNum + 1};
                            false -> 
                                NewStarValue = StarValue + 1,
                                if
                                    NewStarValue > LimStarLucky -> %% 新的祝福大于等级祝福值上限,升星
                                        {1, StarNum + 1};
                                    true ->
                                        {0, StarNum} 
                                end
                          end,
    IsUpMount = case NewStar >= LimStarNum of
                    true -> 1;
                    false -> 0
                end,
    {IsUpStar, IsUpMount}.

%% 获取单属性成长规则
get_quality_attr_grow_cfg(MountQualityAttrCfg, Type)->
    case Type of
        
        3 -> MountQualityAttrCfg#mount_quality_attr_cfg.att_cfg;
        1 -> MountQualityAttrCfg#mount_quality_attr_cfg.hp_cfg;
        4 -> MountQualityAttrCfg#mount_quality_attr_cfg.def_cfg;
        16 -> MountQualityAttrCfg#mount_quality_attr_cfg.resist_cfg;
        5 -> MountQualityAttrCfg#mount_quality_attr_cfg.hit_cfg;
        6 -> MountQualityAttrCfg#mount_quality_attr_cfg.dodge_cfg;
        7 -> MountQualityAttrCfg#mount_quality_attr_cfg.crit_cfg;
        8 -> MountQualityAttrCfg#mount_quality_attr_cfg.ten_cfg;
        _ -> []
    end.
 










