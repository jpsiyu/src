%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-5-3
%% Description: 坐骑模块
%% --------------------------------------------------------
-module(pp_mount).
-compile(export_all).
-export([handle/3]).
-include("mount.hrl").
-include("common.hrl").
-include("server.hrl").
-include("goods.hrl").

%% 获取坐骑列表
handle(16000, PlayerStatus, mount_list) ->
    Mou = PlayerStatus#player_status.mount,
    MountList = lib_mount:get_mount_list(PlayerStatus#player_status.id, Mou#status_mount.mount_dict),
    {ok, BinData} = pt_160:write(16000, [Mou#status_mount.mount_lim, MountList]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData); 

%% 查询坐骑详细信息
handle(16001, PS, MountId) ->
    %% io:format("~p ~p 16001_MountId:~p~n", [?MODULE, ?LINE, MountId]),
    case PS#player_status.lv < 50 of
        true ->
            skip;
        _ ->
            Mou = PS#player_status.mount,
            BaseSpeed = PS#player_status.base_speed,
            case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
                [] -> 
                    {ok, BinData} = pt_160:write(16001, [2, #ets_mount{}, BaseSpeed, 0, 0, 0, <<>>, 0, 0, 0, 0]);
                [Mount] ->
                    Result = case data_mount_config:mount_is_max_level(Mount#ets_mount.level) of
                                 true ->
                                     [1, Mount, BaseSpeed, 0, 0, 0, <<>>, 0, 0, 0, 0];
                                 false ->
                                     %% io:format("~p ~p Star:~p, Level:~p~n", [?MODULE, ?LINE, Mount#ets_mount.star, Mount#ets_mount.level]),
                                     [LimStar, LimStarValue, [{GoodId, Num}]] = 
                                         case data_mount:get_mount_upgrade_star(Mount#ets_mount.star, Mount#ets_mount.level) of
                                             [] -> 
                                                 %% io:format("~p ~p LimStar_PeiZhi_Error!~n", [?MODULE, ?LINE]),
                                                 util:errlog("~p ~p LimStar_PeiZhi_Error!~n", [?MODULE, ?LINE]), 
                                                 [0, 0, [{0, 0}]];
                                             StarRecord -> 
                                                 [StarRecord#mount_upgrade_star.lim_star, 
                                                  StarRecord#mount_upgrade_star.lim_lucky, 
                                                  StarRecord#mount_upgrade_star.goods]
                                         end,
                                     NextLevel = Mount#ets_mount.level + 1,
                                     NextType = lib_mount3:get_figure_by_level(NextLevel),
                                     NextName = data_goods_type:get_name(NextType),
                                     NextFigure = NextType,
                                     NextPower = lib_mount2:get_next_level_power(Mount, NextLevel),
                                     [1, Mount, BaseSpeed, LimStar, LimStarValue, NextLevel, NextName, NextFigure, NextPower, GoodId, Num]
                             end,
                    
                    {ok, BinData} = pt_160:write(16001, Result)
            end,
            lib_server_send:send_one(PS#player_status.socket, BinData)
    end;

%% 乘上坐骑
handle(16002, PS, MountId) ->
    Mou = PS#player_status.mount,
    case lib_mount:get_on(PS, MountId, Mou#status_mount.mount_dict) of
        {fail, Res} ->
            {ok, BinData} = pt_160:write(16002, [Res, #ets_mount{}]),
            lib_server_send:send_one(PS#player_status.socket, BinData);
        {ok, NewPS, NewMount} ->
            {ok, BinData} = pt_160:write(16002, [1, NewMount]),
            lib_server_send:send_one(NewPS#player_status.socket, BinData),
            lib_player:send_attribute_change_notify(NewPS, 3),
            Figure = lib_mount2:get_new_figure(NewPS),
            %% 计算技能buff带来的速度加成
            mod_scene_agent:update(speed, NewPS),
            {_, NewBuffSpeed} = mod_battle:count_speed_buff(NewPS#player_status.speed, 
                                                            NewPS#player_status.battle_status, util:longunixtime()),
            {ok, BinData1} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, 
                                                  NewPS#player_status.server_num, NewBuffSpeed, Figure]),
            lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, 
                                               NewPS#player_status.x, NewPS#player_status.y, BinData1),
            {ok, mount, NewPS}
    end;

%% 离开坐骑
handle(16003, PS, MountId) ->
    Mou = PS#player_status.mount,
    case lib_mount:get_off(PS, MountId, Mou#status_mount.mount_dict) of
        {fail, Res} ->
            {ok, BinData} = pt_160:write(16003, [Res, MountId]),
            lib_server_send:send_one(PS#player_status.socket, BinData);
        {ok, NewPS} ->
            {ok, BinData} = pt_160:write(16003, [1, MountId]),
            lib_server_send:send_one(NewPS#player_status.socket, BinData),
            lib_player:send_attribute_change_notify(NewPS, 3),
            Mou1 = NewPS#player_status.mount,
            %% 计算技能buff带来的速度加成
            mod_scene_agent:update(speed, NewPS),
            {_, NewBuffSpeed} = mod_battle:count_speed_buff(NewPS#player_status.speed, NewPS#player_status.battle_status, util:longunixtime()),
            {ok, BinData1} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, 
                                                  NewPS#player_status.server_num, NewBuffSpeed, Mou1#status_mount.mount_figure]),
            lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, NewPS#player_status.x, 
                                               NewPS#player_status.y, BinData1),
            {ok, mount, NewPS}
    end;

%% 坐骑强化
handle(16006, PS, [MountId, StoneId, LuckyId]) ->
    Go = PS#player_status.goods,
    case lib_secondary_password:is_pass(PS) of
        false -> skip;
        true ->
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'mount_stren', PS, MountId, StoneId, LuckyId}) of
                {ok, [NewPS, Res, Mount]} ->
                    {ok, BinData} = pt_160:write(16006, [Res, MountId, Mount]),
                    lib_server_send:send_one(NewPS#player_status.socket, BinData),
                    case Res =:= 1 of
                        true -> 
                            lib_task:event(NewPS#player_status.tid, qh, do, NewPS#player_status.id);
                        false -> skip
                    end,
                    lib_player:send_attribute_change_notify(NewPS, 3),
                    {ok, NewPS};
                {'EXIT',_Reason} -> 
                     ?DEBUG("pp_mount 16006 error", [])
            end
    end;

%% 放生坐骑
handle(16007, PS, MountId) -> 
    Mou = PS#player_status.mount,
    case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] ->
            {ok, BinData} = pt_160:write(16007, [2, MountId]),
            lib_server_send:send_one(PS#player_status.socket, BinData);
        [Mount] ->
            if
                Mount#ets_mount.status > 0 ->
                    {ok, BinData} = pt_160:write(16007, [5, MountId]),
                    lib_server_send:send_one(PS#player_status.socket, BinData);
                true ->
                    Dict = dict:erase(MountId, Mou#status_mount.mount_dict),
                    List = lib_mount2:get_mount_change_list(Mou#status_mount.change_dict, MountId),
                    ChangeDict = lib_mount3:delete_from_dict(Mou#status_mount.change_dict, List),
                    NewPS = PS#player_status{mount=Mou#status_mount{mount_dict=Dict, change_dict=ChangeDict}},
                    Sql = io_lib:format(<<"delete from mount where id=~p">>, [MountId]),
                    db:execute(Sql),
                    Sql2 = io_lib:format(<<"delete from upgrade_change where mid=~p">>, [MountId]),
                    db:execute(Sql2),
                    log:log_mount_discard(NewPS#player_status.id, Mount),
                    {ok, BinData} = pt_160:write(16007, [1, MountId]),
                    lib_server_send:send_one(NewPS#player_status.socket, BinData),
                    {ok, NewPS}
            end
    end;

%% 坐骑卡使用
handle(16008, PS, GoodsId) ->
    Go = PS#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'mount_card', PS, GoodsId}) of
        {ok, [Res, NewMount, NewPS]} ->
            case Res of
                1 -> 
                    {ok, BinData} = pt_160:write(16008, [Res, NewMount#ets_mount.id]),
                    lib_server_send:send_one(NewPS#player_status.socket, BinData),
                    NewPS1 = lib_player:count_player_attribute(NewPS),
                    lib_player:send_attribute_change_notify(NewPS1, 3),
                    NewPS2 = lib_mount_repair:add_change(NewPS1, NewPS1#player_status.mount, NewMount),
                    {ok, NewPS2};
                Res ->
                    {ok, BinData} = pt_160:write(16008, [Res, NewMount#ets_mount.id]),
                    lib_server_send:send_one(NewPS#player_status.socket, BinData),
                    {ok, NewPS}
            end;       
        {'EXIT',_Reason} ->
            util:errlog("~p ~p _Reason:~p~n", [?MODULE, ?LINE, _Reason]),
            {ok, PS}
    end;

%% 坐骑出战
%% handle(16009, PS, MountId) ->
%%     Mou = PS#player_status.mount,
%%     case lib_mount:go_out(PS, MountId, Mou#status_mount.mount_dict) of
%%         {fail, Res} ->
%%             {ok, BinData} = pt_160:write(16009, [Res, #ets_mount{}, 0]),
%%             lib_server_send:send_one(PS#player_status.socket, BinData);
%%         {ok, NewPS, NewMount, OldMountId} ->
%%             {ok, BinData} = pt_160:write(16009, [1, NewMount, OldMountId]),
%%             lib_server_send:send_one(NewPS#player_status.socket, BinData),
%%             lib_player:send_attribute_change_notify(NewPS, 3),
%%             Mou1 = NewPS#player_status.mount,
%%             {ok, BinData1} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, 
%%                                                   NewPS#player_status.server_num, NewPS#player_status.speed, Mou1#status_mount.mount_figure]),            
%%             lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, 
%%                                                NewPS#player_status.x, NewPS#player_status.y, BinData1),
%%             if
%%                 NewMount#ets_mount.level >= 3 ->
%%                     Flyer = 311401;
%%                 true ->
%%                     Flyer = 0
%%             end,
%%             NewPS1 = NewPS#player_status{mount = Mou1#status_mount{flyer=Flyer}},
%%             {ok, mount, NewPS1}
%%     end;

%% 坐骑休息
%% handle(16010, PS, MountId) ->
%%     Mou = PS#player_status.mount,
%%     case lib_mount:mount_rest(PS, MountId, Mou#status_mount.mount_dict) of
%%         {fail, Res} ->
%%             {ok, BinData} = pt_160:write(16010, [Res, MountId]),
%%             lib_server_send:send_one(PS#player_status.socket, BinData);
%%         {ok, NewPS} ->
%%             {ok, BinData} = pt_160:write(16010, [1, MountId]),
%%             lib_server_send:send_one(NewPS#player_status.socket, BinData),
%%             lib_player:send_attribute_change_notify(NewPS, 3),
%%             Mou1 = NewPS#player_status.mount,
%%             {ok, BinData1} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, NewPS#player_status.server_num, 
%%                                                   NewPS#player_status.speed, Mou1#status_mount.mount_figure]),            
%%             lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id,
%%                                                NewPS#player_status.x, NewPS#player_status.y, BinData1),
%%             {ok, NewPS}
%%     end;

%% 获取别人坐骑详细信息
handle(16011, PlayerStatus, [RoleId, MountId]) ->
    case RoleId =:= PlayerStatus#player_status.id of
        true ->
            Mou = PlayerStatus#player_status.mount,
            case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
                [] -> 
                    {ok, BinData} = pt_160:write(16011, [2, #ets_mount{}]);
                [Mount] ->
                    {ok, BinData} = pt_160:write(16011, [1, Mount])
            end;
        false ->
            MountDict = lib_player:get_player_info(RoleId, mount),
            [Res, Mount] =
            case lib_mount:get_mount_info(MountId, MountDict) of
                [M] when M#ets_mount.role_id =/= RoleId -> [3, #ets_mount{}];
                [M] -> [1, M];
                [] ->
                [3, #ets_mount{}]
            end,
            {ok, BinData} = pt_160:write(16011, [Res, Mount])
    end,
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%% 获取别人出战坐骑
handle(16012, PlayerStatus, RoleId) ->
    case RoleId =:= PlayerStatus#player_status.id of
        true -> 
            skip;
        false ->
            MouDict = lib_player:get_player_info(RoleId, mount),
            [Res, Mount] =
            case lib_mount:get_equip_mount(RoleId, MouDict) of
                M when M#ets_mount.id > 0 -> 
                    [1, M];
                M ->
                    [3, M]
            end,
            {ok, BinData} = pt_160:write(16012, [Res, Mount]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData)
    end;

%% 坐骑进阶
handle(16015, PS, [MountId, RuenList]) ->
    Mou = PS#player_status.mount,
    case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] -> 
            {ok, BinData} = pt_160:write(16015, [7, MountId, 0, 0]),
            lib_server_send:send_one(PS#player_status.socket, BinData);
        [Mount] ->
            case data_mount_config:mount_is_max_level(Mount#ets_mount.level) of
                true ->
                    {ok, BinData} = pt_160:write(16015, [14, MountId, 0, 0]),
                    lib_server_send:send_one(PS#player_status.socket, BinData);
                false ->
                    Go = PS#player_status.goods,
                    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'mount_upgrade', PS, MountId, RuenList}) of
                        {ok, [Code, NewPS, NewMount]} ->
                            pp_goods:handle(15010, NewPS, 4),
                            {ok, BinData} = pt_160:write(16015, [Code, MountId, NewMount#ets_mount.star, NewMount#ets_mount.star_value]),
                            lib_server_send:send_one(NewPS#player_status.socket, BinData),
                            if
                                Code =:= 1 ->    
                                    Mou = PS#player_status.mount,
                                    Figure = lib_mount2:get_new_figure(NewPS),
                                    {ok, BinData1} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, 
                                                                          NewPS#player_status.server_num, NewPS#player_status.speed, Figure]),
                                    lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, 
                                                                       NewPS#player_status.x, NewPS#player_status.y, BinData1),
                                    %%  目标：将坐骑进阶到第二阶 402
                                    mod_target:trigger(NewPS#player_status.status_target, NewPS#player_status.id, 402, NewMount#ets_mount.level),
                                    mod_achieve:trigger_role(NewPS#player_status.achieve, NewPS#player_status.id, 33, 0, NewMount#ets_mount.level),
                                    %% 加幻化形象
                                    NewPS1 = lib_mount_repair:add_change(NewPS, Mou, NewMount);
                                true ->
                                    NewPS1 = NewPS
                            end,
                            if
                                Code =:= 1 orelse Code =:= 2 ->
                                    NewPS2 = lib_player:count_player_attribute(NewPS1),
                                    lib_player:send_attribute_change_notify(NewPS2, 3),
                                    handle(16001, NewPS2, MountId);
                                true ->
                                    NewPS2 = NewPS1
                            end,
                            {ok, mount, NewPS2};
                        {'EXIT',_Reason} -> 
                            util:errlog("~p ~p mount_upgrade_error_Reason:~p~n", [?MODULE, ?LINE, _Reason]),
                            skip
                    end
            end
    end;

%% 飞行棋坐骑升星
handle(16016, PS, [MountId, RuenList]) ->
    Go = PS#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'fly_star', PS, MountId, RuenList}) of
       {ok, [Res, NewPS, NewMount]} ->
            {ok, BinData} = pt_160:write(16016, [Res, NewMount#ets_mount.fly_id, NewMount#ets_mount.star_value]),
            lib_server_send:send_one(NewPS#player_status.socket, BinData),
            lib_player:send_attribute_change_notify(NewPS, 3),
            if
                Res =:= 1 ->
                    mod_achieve:trigger_role(NewPS#player_status.achieve, NewPS#player_status.id, 34, 0, NewMount#ets_mount.star);
                true ->
                    skip
            end,                    
            {ok, mount, NewPS};
        {'EXIT',_Reason} -> 
            skip
    end; 


%% 资质培养新版
handle(16017, PS, [MountId, Type, Coin, StoneList]) ->
    Go = PS#player_status.goods,  
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'up_quality', PS, MountId, Type, Coin, StoneList}) of
        {ok, [Code, NewPS, TempQualityAttr]} ->
            pp_goods:handle(15010, NewPS, 4),
            %% io:format("~p ~p Code:~p~n", [?MODULE, ?LINE, Code]),
            case Code of
                1 ->
                    %% 增加次数
                    mod_daily:increment(NewPS#player_status.dailypid, NewPS#player_status.id, 8010),
                    UsedTime = mod_daily:get_count(NewPS#player_status.dailypid, NewPS#player_status.id, 8010),
                    TotalTime = data_mount_config:get_config(quality_times),
                    LessTime = TotalTime - UsedTime,
                    TotalStarNum = data_mount_config:get_quality_attr_total_star1(TempQualityAttr),
                    {ok, BinData} = pt_160:write(16017, [Code, MountId, TotalStarNum, LessTime, TempQualityAttr]),
                    lib_server_send:send_one(NewPS#player_status.socket, BinData);
                Code ->
                    {ok, BinData} = pt_160:write(16017, [Code, MountId, 0, 0, []]),
                    lib_server_send:send_one(NewPS#player_status.socket, BinData)
            end,
            {ok, mount, NewPS};
        {'EXIT',_Reason} -> 
            util:errlog("~p ~p mount_upgrade_error_Reason:~p~n", [?MODULE, ?LINE, _Reason]),
            skip
    end;

%% %% 资质培养
%% handle(16017, PlayerStatus, [MountId, StoneList]) ->
%%     Go = PlayerStatus#player_status.goods,
%%     case gen:call(Go#status_goods.goods_pid, '$gen_call', {'up_quality', PlayerStatus, MountId, StoneList}) of
%%        {ok, [Res, NewPlayerStatus, NewQualityId, Point]} ->
%%             {ok, BinData} = pt_160:write(16017, [Res, NewQualityId, Point]),
%%             lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
%%             lib_player:send_attribute_change_notify(NewPlayerStatus, 3),
%%             if
%%                 Res =:= 1 ->
%%                     Exp = lib_mount3:get_exp(NewQualityId),
%%                     lib_mount3:add_exp_area(PlayerStatus#player_status.scene,PlayerStatus#player_status.copy_id, PlayerStatus#player_status.x, PlayerStatus#player_status.y, Exp, PlayerStatus#player_status.pid),
%%                     mod_achieve:trigger_role(NewPlayerStatus#player_status.achieve, NewPlayerStatus#player_status.id, 32, 0, NewQualityId),
%%                     {ok, BinData2} = pt_120:write(12097, [2, PlayerStatus#player_status.id, 5, 5]),
%%                     lib_server_send:send_to_area_scene(PlayerStatus#player_status.scene, 
%%                                                        PlayerStatus#player_status.copy_id,
%%                                                        PlayerStatus#player_status.x, 
%%                                                        PlayerStatus#player_status.y, BinData2);
%%                 Res =:= 0 ->
%%                     Exp2 = round(lib_mount3:get_exp(NewQualityId)/2),
%%                     lib_mount3:add_exp_area(PlayerStatus#player_status.scene,PlayerStatus#player_status.copy_id, PlayerStatus#player_status.x, PlayerStatus#player_status.y, Exp2, PlayerStatus#player_status.pid);
%%                 true ->
%%                     skip
%%             end,   
%%             {ok, mount, NewPlayerStatus};
%%         {'EXIT',_Reason} -> 
%%             skip
%%     end;

%%　获取进阶和幻化的形象信息
handle(16018, PS, MountId) ->
     Mou = PS#player_status.mount,
     case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] ->
            %% io:format("~p ~p Code:~p~n", [?MODULE, ?LINE, 2]),
            {ok, BinData} = pt_160:write(16018, [2, 0, [], []]),
            NewPS = PS;
        [Mount] ->
            List = lib_mount2:get_mount_change_list(Mou#status_mount.change_dict, MountId),
            [NewPS, List2] = lib_mount3:check_time(List, PS, []),
            NewFigureList = lib_mount3:get_diff_change_figure_list(List2),
            FigureAttr = lib_mount3:get_figure_attr(NewFigureList),
            %%　io:format("~p ~p NewFigureList:~p~n",[?MODULE, ?LINE, NewFigureList]),
            {ok, BinData} = pt_160:write(16018, [1, Mount#ets_mount.figure, NewFigureList, FigureAttr])
    end,
    lib_server_send:send_one(NewPS#player_status.socket, BinData),
    {ok, mount, NewPS};

%% 旧版幻化获取
%% handle(16018, PlayerStatus, MountId) ->
%%      Mou = PlayerStatus#player_status.mount,
%%      case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
%%         [] ->
%%             {ok, BinData} = pt_160:write(16018, [2, [], 0]),
%%             NewPS = PlayerStatus;
%%         [Mount] ->
%%             List = lib_mount2:get_mount_change_list(Mou#status_mount.change_dict, MountId),
%%             [NewPS, List2] = check_time(List, PlayerStatus, []),
%%             %io:format("list = ~p~n",[{List2}]),
%%             lib_player:send_attribute_change_notify(NewPS, 3),
%%             {ok, BinData} = pt_160:write(16018, [1, List2, Mount#ets_mount.figure])
%%     end,
%%     lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
%%     {ok, mount, NewPS};

%% 坐骑幻化操作
handle(16019, PS, [MountId, Figure]) ->
    %% io:format("~p ~p 16019_args:~p~n", [?MODULE, ?LINE, [MountId, Figure]]),
    Mou = PS#player_status.mount,
     case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] ->
            {ok, BinData} = pt_160:write(16019, [2, 0]),
            lib_server_send:send_one(PS#player_status.socket, BinData),
            {ok, PS};
        [Mount] ->
            case lib_mount2:change_mount_figure(PS, Mount, Figure) of
                {fail, Code} ->
                    {ok, BinData} = pt_160:write(16019, [Code, 0]),
                    lib_server_send:send_one(PS#player_status.socket, BinData),
                    {ok, PS};
                {ok, NewPS, NewMount} ->
                    {ok, BinData} = pt_160:write(16019,[1, NewMount#ets_mount.figure]),
                    lib_server_send:send_one(NewPS#player_status.socket, BinData),
                    if
                        Mount#ets_mount.status =:= 2 orelse Mount#ets_mount.status =:= 3 ->
                            {ok, BinData1} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, 
                                                                  NewPS#player_status.server_num, NewPS#player_status.speed, 
                                                                  NewMount#ets_mount.figure]);
                        true ->
                            {ok, BinData1} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, 
                                                                  NewPS#player_status.server_num, NewPS#player_status.speed, 0])
                    end,
                    lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, NewPS#player_status.x, 
                                                       NewPS#player_status.y, BinData1),
                    {ok, mount, NewPS}
            end
    end;

%% %% 坐骑幻化操作
%% handle(16019, PlayerStatus, [MountId, Figure]) ->
%%     Mou = PlayerStatus#player_status.mount,
%%      case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
%%         [] ->
%%             {ok, BinData} = pt_160:write(16019, 2),
%%             lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
%%             {ok, PlayerStatus};
%%         [Mount] ->
%%             case lib_mount2:change_mount_figure(PlayerStatus, Mount, Figure) of
%%                 {fail, Res} ->
%%                     {ok, BinData} = pt_160:write(16019, Res),
%%                     lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
%%                     {ok, PlayerStatus};
%%                 {ok, NewPS, NewMount} ->
%%                     {ok, BinData} = pt_160:write(16019, 1),
%%                     lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
%%                     if
%%                         Mount#ets_mount.status =:= 2 orelse Mount#ets_mount.status =:= 3 ->
%%                             {ok, BinData1} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, NewPS#player_status.server_num, NewPS#player_status.speed, NewMount#ets_mount.figure]);
%%                         true ->
%%                             {ok, BinData1} = pt_120:write(12010, [NewPS#player_status.id, NewPS#player_status.platform, NewPS#player_status.server_num, NewPS#player_status.speed, 0])
%%                     end,
%%                     lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, NewPS#player_status.x, NewPS#player_status.y, BinData1),
%%                     {ok, mount, NewPS}
%%             end
%%     end;

% 飞行幻化列表
handle(16020, PlayerStatus, MountId) ->
     Mou = PlayerStatus#player_status.mount,
     case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] ->
            {ok, BinData} = pt_160:write(16020, [2, [], 0]);
        [Mount] ->
            List = lib_mount2:get_fly_list(Mount#ets_mount.star),
            {ok, BinData} = pt_160:write(16020, [1, List, Mount#ets_mount.fly_id])
    end,
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

% 飞行幻化
handle(16021, PlayerStatus, [MountId, Figure]) ->
    Mou = PlayerStatus#player_status.mount,
     case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] ->
            {ok, BinData} = pt_160:write(16021, 2),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            {ok, PlayerStatus};
        [Mount] ->
            case lib_mount2:change_mount_fly(PlayerStatus, Mount, Figure) of
                {fail, Res} ->
                    {ok, BinData} = pt_160:write(16021, Res),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
                    {ok, PlayerStatus};
                {ok, NewPS} ->
                    {ok, BinData} = pt_160:write(16021, 1),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
                    {ok, mount, NewPS}
            end
    end;

% 飞行
handle(16022, PlayerStatus, [MountId, Fly]) ->
    Mou = PlayerStatus#player_status.mount,
    case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] ->
            NewFigure = 0,
            NewPS = PlayerStatus,
            Res = 2;
        [Mount] ->
			Kf3v3InScene = lists:member(PlayerStatus#player_status.scene, data_kf_3v3:get_config(scene_pk_ids)),
            if 
                (PlayerStatus#player_status.scene =:= 251 orelse 
                    PlayerStatus#player_status.scene =:= 291 orelse
                    Kf3v3InScene =:= true) andalso Fly =:= 0 ->
                    NewFigure = 0,
                    NewPS = PlayerStatus,
                    Res = 7;
                Mount#ets_mount.level < 3 ->
                    NewFigure = 0,
                    NewPS = PlayerStatus,
                    Res = 5;
                Mount#ets_mount.status =:= 0 ->
                    NewFigure = 0,
                    NewPS = PlayerStatus,
                    Res = 2;
                Fly =:= 0 andalso Mount#ets_mount.status =:= 3 ->
                    NewFigure = 0,
                    NewPS = PlayerStatus,
                    Res = 3;
                Fly =:= 0 andalso Mount#ets_mount.status =/= 2 ->
                    NewFigure = 0,
                    NewPS = PlayerStatus,
                    Res = 6;
                Fly =/= 0 andalso Mount#ets_mount.status =/= 3 ->
                    NewFigure = 0,
                    NewPS = PlayerStatus,
                    Res = 4;
                true ->
                    case Fly =:= 0 of   %飞行
                        true ->
                            NewMount = Mount#ets_mount{status = 3},
                            Sql = io_lib:format(?sql_fly, [3, NewMount#ets_mount.id]),
                            db:execute(Sql),
                            MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, Mou#status_mount.mount_dict),
                            M = Mou#status_mount{fly = Mount#ets_mount.fly_id,
                            mount_figure = NewMount#ets_mount.figure,
                            mount_dict = MountDict},
                            NewPS = PlayerStatus#player_status{mount = M},
                            NewFigure = M#status_mount.fly,
                            Res = 1;
                        false ->
                            NewMount = Mount#ets_mount{status = 2},
                            Sql = io_lib:format(?sql_fly, [2, NewMount#ets_mount.id]),
                            db:execute(Sql),
                            MountDict = lib_mount:add_dict(NewMount#ets_mount.id, NewMount, Mou#status_mount.mount_dict),
                            M = Mou#status_mount{fly = 0, mount_dict = MountDict},
                            NewPS = PlayerStatus#player_status{mount = M},
                            NewFigure = 0,
                            Res = 7
                    end
            end
    end,
    %% io:format("NewFigure = ~p~n", [NewFigure]),
    {ok, BinData} = pt_160:write(16022, [Res, NewFigure]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    if 
        Res =:= 1 orelse Res =:= 7 ->
            {ok, BinData2} = pt_123:write(12301, [PlayerStatus#player_status.id, PlayerStatus#player_status.platform, PlayerStatus#player_status.server_num, NewFigure]),
            lib_server_send:send_to_area_scene(PlayerStatus#player_status.scene, 
                                                       PlayerStatus#player_status.copy_id,
                                                       PlayerStatus#player_status.x, 
                                                       PlayerStatus#player_status.y, BinData2),
            {ok, mount, NewPS};
        true ->
            {ok, NewPS}
    end;    

%准备提升资质
handle(16023, PlayerStatus, ready) ->
    {ok, BinData} = pt_120:write(12097, [2, PlayerStatus#player_status.id, 4, 5]),
    lib_server_send:send_to_area_scene(PlayerStatus#player_status.scene, 
                                                       PlayerStatus#player_status.copy_id,
                                                       PlayerStatus#player_status.x, 
                                                       PlayerStatus#player_status.y, BinData),
    {ok, BinData2} = pt_160:write(16023, 1),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData2);

handle(16025, PlayerStatus, [PlayerId, MountId]) ->
    case PlayerStatus#player_status.id =/= PlayerId of
        true ->
            case lib_player:get_player_info(PlayerId, mount) of
                false ->
                    {ok, BinData} = pt_160:write(16025, [0, #ets_mount{}]);
                MountDict ->
                    case lib_mount:get_mount_info(MountId, MountDict) of
                        [Mount] when is_record(Mount, ets_mount) ->
                            {ok, BinData} = pt_160:write(16025, [1, Mount]);
                        _ ->
                            {ok, BinData} = pt_160:write(16025, [0, #ets_mount{}])
                    end
            end;
        false ->
            Mou = PlayerStatus#player_status.mount,
            case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
                [] ->
                    {ok, BinData} = pt_160:write(16025, [0, #ets_mount{}]);
                [Mount] ->
                    {ok, BinData} = pt_160:write(16025, [1, Mount])
            end
    end,
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);                    

%% 查看别人坐骑
handle(16030, PlayerStatus, PlayerId) ->
	case PlayerStatus#player_status.id /= PlayerId of
		true ->
			case lib_player:get_player_info(PlayerId, status_mount) of
				[StatusMount, BaseSpeed] when is_record(StatusMount, status_mount) ->
					MountDict = StatusMount#status_mount.mount_dict,
					case lib_mount:get_equip_mount(PlayerId, MountDict) of
						Mount when is_record(Mount, ets_mount) ->
							{ok, BinData} = pt_160:write(16030, [1, Mount, BaseSpeed]);
						_ -> 
							{ok, BinData} = pt_160:write(16030, [0, #ets_mount{}, 100])
					end;
				_ ->
					{ok, BinData} = pt_160:write(16030, [0, #ets_mount{}, 100])
			end,
		    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
		_ ->
			{ok, BinData} = pt_160:write(16030, [0, #ets_mount{}, 100]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData)
	end;

%% 取消幻化
handle(16031, PS, MountId) ->
    Mou = PS#player_status.mount,
    case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] ->
            {ok, BinData} = pt_160:write(16031, [0, 0]),
            lib_server_send:send_one(PS#player_status.socket, BinData);
        [Mount] ->
            if
                Mount#ets_mount.level =:= 2 ->
                    %%　Figure = list_to_integer(integer_to_list(311002)++integer_to_list(1)),
                    %% io:format("~p ~p Figure:~p~n", [?MODULE, ?LINE, Figure]),
                    Figure = 311002,
                    NewPS = lib_mount3:update(PS, Mount, Figure),
                    {ok, mount, NewPS};
                true ->
                    Type = lib_mount3:get_figure_by_level(Mount#ets_mount.level),
                    %% io:format("~p ~p Type:~p~n", [?MODULE, ?LINE, Type]),
                    if
                        Type =/= [] andalso Type > 0 ->
                            %% Figure = list_to_integer(integer_to_list(Type)++integer_to_list(1)),
                            Figure = Type,
                            NewPS = lib_mount3:update(PS, Mount, Figure),
                            {ok, mount, NewPS};
                        true ->
                            {ok, BinData} = pt_160:write(16031, [0, 0]),
                            lib_server_send:send_one(PS#player_status.socket, BinData)
                    end
            end
    end;

%% 旧版取消幻化
%% handle(16031, PS, MountId) ->
%%     %% io:format("~p ~p MountId:~p~n", [?MODULE, ?LINE, MountId]),
%%     Mou = PS#player_status.mount,
%%     case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
%%         [] ->
%%             {ok, BinData} = pt_160:write(16031, [0, 0]),
%%             lib_server_send:send_one(PS#player_status.socket, BinData);
%%         [Mount] ->
%%             if
%%                 Mount#ets_mount.level =:= 2 ->
%%                     Figure = list_to_integer(integer_to_list(311006)++integer_to_list(1)),
%%                     %% io:format("~p ~p Figure:~p~n", [?MODULE, ?LINE, Figure]),
%%                     NewPS = lib_mount3:update(PS, Mount, Figure),
%%                     {ok, mount, NewPS};
%%                 true ->
%%                     Type = lib_mount3:get_figure_by_level(Mount#ets_mount.level),
%%                     %% io:format("~p ~p Type:~p~n", [?MODULE, ?LINE, Type]),
%%                     if
%%                         Type =/= [] andalso Type > 0 ->
%%                             Figure = list_to_integer(integer_to_list(Type)++integer_to_list(1)),
%%                             NewPS = lib_mount3:update(PS, Mount, Figure),
%%                             {ok, mount, NewPS};
%%                         true ->
%%                             {ok, BinData} = pt_160:write(16031, [0, 0]),
%%                             lib_server_send:send_one(PS#player_status.socket, BinData)
%%                     end
%%             end
%%     end;

%% 资质查看和灵犀信息
handle(16032, PS, MountId) ->
    Mou = PS#player_status.mount,
    case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] ->
            {ok, BinData} = pt_160:write(16032, [2, 0, 0, 0, 0, 0, 0, [], 0, 0, 0, [], []]),
            lib_server_send:send_one(PS#player_status.socket, BinData);
        [Mount] ->
            if
                PS#player_status.id =/= Mount#ets_mount.role_id ->
                    {ok, BinData} = pt_160:write(16032, [3, 0, 0, 0, 0, 0, 0, [], 0, 0, 0, [], []]),
                    lib_server_send:send_one(PS#player_status.socket, BinData);
                true ->
                    Coin = data_mount_config:get_config(quality_used_coin),
                    {GoodId, Num} = data_mount_config:get_config(quality_used_goods),
                    QualityAttr = Mount#ets_mount.quality_attr,
                    TotalStarNum = data_mount_config:get_quality_attr_total_star(QualityAttr),
                    QualityLv = Mount#ets_mount.quality_lv,
                    TotalTimes = data_mount_config:get_config(quality_times),
                    LessTime = TotalTimes - mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 8010),
                    LingXiNum = Mount#ets_mount.lingxi_num,
                    LingXiAttr = Mount#ets_mount.lingxi_attr,
                    LingXiGXId =  Mount#ets_mount.lingxi_gx_id,
                    LingXiLV = data_mount_config:get_lingxi_lv(LingXiNum),
                    LingXiLvRecord = data_mount:get_mount_lingxi_lv(LingXiLV),
                    LightEffLsit =  LingXiLvRecord#mount_lingxi_lv.light_effect_list,
                    LingXiLimAttr = LingXiLvRecord#mount_lingxi_lv.lim_attr,
                    NewLingXiAttr = lib_mount3:format_list_by_type(LingXiAttr, LingXiLimAttr, []),
                    A = [1,Coin,GoodId,Num,QualityLv,LessTime,TotalStarNum,QualityAttr,LingXiNum,LingXiLV,LingXiGXId,NewLingXiAttr,LightEffLsit],
                    %% io:format("~p ~p A:~p~n", [?MODULE, ?LINE, A]),
                    {ok, BinData} = pt_160:write(16032, A),
                    lib_server_send:send_one(PS#player_status.socket, BinData)
            end
    end;
                    
%% 资质替换/取消
handle(16033, PS, [MountId, Type]) ->
    Mou = PS#player_status.mount,
    case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] ->
            {ok, BinData} = pt_160:write(16033, [3, 0, 0]),
            lib_server_send:send_one(PS#player_status.socket, BinData);
        [Mount] ->
            if
                Mount#ets_mount.role_id =/= PS#player_status.id ->
                    {ok, BinData} = pt_160:write(16033, [4, 0, 0]),
                    lib_server_send:send_one(PS#player_status.socket, BinData);
                true ->
                    if
                        Mount#ets_mount.temp_quality_attr =:= [] ->
                            case Type of
                                1 ->    
                                    {ok, BinData} = pt_160:write(16033, [1, 1, 0]),
                                    lib_server_send:send_one(PS#player_status.socket, BinData);
                                2 ->
                                    {ok, BinData} = pt_160:write(16033, [5, 2, 0]),
                                    lib_server_send:send_one(PS#player_status.socket, BinData)
                            end;
                        true ->
                            case Type of
                                1 ->    
                                    {ok, 1, NewPS, _NewMount} = lib_mount2:replace_quality_attr(PS, Mount, Type),
                                    {ok, BinData} = pt_160:write(16033, [1, 1, 0]),
                                    lib_server_send:send_one(PS#player_status.socket, BinData),
                                    Mount#ets_mount.temp_quality_attr,
                                    {ok, mount, NewPS};
                                2 ->
                                    {ok, 1, NewPS, NewMount} = lib_mount2:replace_quality_attr(PS, Mount, Type),
                                    {ok, BinData} = pt_160:write(16033, [2, 2, NewMount#ets_mount.quality_lv]),
                                    lib_server_send:send_one(NewPS#player_status.socket, BinData),
                                    NewPS1 = lib_player:count_player_attribute(NewPS),
                                    lib_player:send_attribute_change_notify(NewPS1, 3),
                                    handle(16001, NewPS1, MountId),
                                    {ok, mount, NewPS1}
                            end  
                    end
            end
    end;

%% 灵犀光效切换
handle(16034, PS, [MountId, LingXiGXId]) ->
    Mou = PS#player_status.mount,
    case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
        [] ->
            {ok, BinData} = pt_160:write(16034, [2, 0]),
            lib_server_send:send_one(PS#player_status.socket, BinData);
        [Mount] ->
            if
                PS#player_status.id =/= Mount#ets_mount.role_id ->
                    {ok, BinData} = pt_160:write(16034, [3, 0]),
                    lib_server_send:send_one(PS#player_status.socket, BinData);
                true ->
                    case Mount#ets_mount.lingxi_gx_id =:= LingXiGXId of
                        true -> skip;
                        false ->
                            LingXiLv = data_mount_config:get_lingxi_lv(Mount#ets_mount.lingxi_num),
                            LingXiRecord = data_mount:get_mount_lingxi_lv(LingXiLv),
                            LingXiGXIdList = LingXiRecord#mount_lingxi_lv.light_effect_list,
                            case lists:member(LingXiGXId, LingXiGXIdList) of
                                true ->
                                    {ok, Code, NewPS} = lib_mount2:replace_lingxi_gx(PS, Mount, LingXiGXId),
                                    {ok, BinData} = pt_160:write(16034, [Code, LingXiGXId]),
                                    lib_server_send:send_one(NewPS#player_status.socket, BinData),
                                    {ok, mount, NewPS};
                                false ->
                                     {ok, BinData} = pt_160:write(16034, [4, 0]),
                                     lib_server_send:send_one(PS#player_status.socket, BinData)
                            end
                     end 
            end       
    end;

%% 坐骑45级之前的进阶信息
handle(16035, PS, MountId) ->
    case PS#player_status.lv >= 50 of
        true -> 
            NewPS = PS;
        _ ->
            Mou = PS#player_status.mount,
            BaseSpeed = PS#player_status.base_speed,
            case lib_mount:get_mount_info(MountId, Mou#status_mount.mount_dict) of
                [] -> 
                    {ok, BinData} = pt_160:write(16035, [2, #ets_mount{}, [], 0]),
                    NewPS = PS;
                [Mount] ->
                    if
                        PS#player_status.id =/= Mount#ets_mount.role_id ->
                            {ok, BinData} = pt_160:write(16035, [3, #ets_mount{}, [], 0]),
                            lib_server_send:send_one(PS#player_status.socket, BinData),
                            NewPS = PS;
                        true ->
                            List = lib_mount2:get_mount_change_list(Mou#status_mount.change_dict, MountId),
                            [NewPS, List2] = lib_mount3:check_time(List, PS, []),
                            FigureList = lib_mount3:get_change_figure_list(List2),
                            {ok, BinData} = pt_160:write(16035, [1, Mount, FigureList, BaseSpeed])
                    end  
            end,
            lib_server_send:send_one(PS#player_status.socket, BinData)
    end,
    {ok, mount, NewPS};

%% 容错
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_mount no match", []),
    {error, "pp_mount no match"}.



