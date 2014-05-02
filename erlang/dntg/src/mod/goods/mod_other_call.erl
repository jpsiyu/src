%%
%% @file mod_other_call.erl
%% @brief 物品给外部调用(游戏线)
%% @author xyj, 156702030@qq.com
%% @version 1.0
%% @date 2012-06-22
%%

-module(mod_other_call).
-compile(export_all).
-include("server.hrl").
-include("goods.hrl").
-include("def_goods.hrl").

%% 购买升级VIP卡
pay_vip_upgrade_card(PlayerStatus, GoodsTypeId) ->
    Go = PlayerStatus#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'vip_band', PlayerStatus, GoodsTypeId}) of
        {ok, [Res, NewPlayerStatus]} ->
            {Res, NewPlayerStatus};
        {'EXIT', _Reason} ->
            util:errlog("handle pay_vip_upgrade_card error:~p", [_Reason])
    end.
        
%% 送绑定物品(只能在游戏线用，会CALL物品进程)
%% Bind:绑定类型
send_bind_goods(PlayerStatus, GoodsTypeId, Num, Bind) ->
    GoodsList = [{goods, GoodsTypeId, Num, Bind}],
    Go = PlayerStatus#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'give_more', PlayerStatus, GoodsList}) of
         %% 2:物品类型不存在, 3背包格子不足
         {ok, {fail, Res}} ->
             {fail, Res};
         {ok, ok} ->
             ok;
         {'EXIT', _Reason} ->
             util:errlog("send_bind_goods error:~p", [_Reason]);
         {ok, Error} ->
             Error
     end.

%% 隐藏时装翅膀(进蝴蝶时用)
%% Show 1:隐藏, 0:显示
hide_fashion(PlayerStatus, Show) -> 
    G = PlayerStatus#player_status.goods,
    [Accessory, _] = G#status_goods.fashion_accessory,
    case Accessory > 0 of
        true ->
            lib_goods_util:change_fashion_state(G#status_goods.hide_fashion_weapon, G#status_goods.hide_fashion_armor, Show, PlayerStatus#player_status.id),
            NewPlayerStatus = PlayerStatus#player_status{goods = G#status_goods{hide_fashion_accessory = Show}};
        false ->
            NewPlayerStatus = PlayerStatus
    end,
    NewGo = NewPlayerStatus#player_status.goods,
    Mount = NewPlayerStatus#player_status.mount,
    {ok, BinData1} = pt_120:write(12012, [NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.platform, NewPlayerStatus#player_status.server_num, 
													NewGo#status_goods.equip_current, 
													NewGo#status_goods.stren7_num, 
													NewGo#status_goods.suit_id, 
													NewPlayerStatus#player_status.hp, 
													NewPlayerStatus#player_status.hp_lim, 
													NewGo#status_goods.fashion_weapon,
													NewGo#status_goods.fashion_armor, 
													NewGo#status_goods.fashion_accessory, 
													NewGo#status_goods.hide_fashion_weapon, 
													NewGo#status_goods.hide_fashion_armor, 
													NewGo#status_goods.hide_fashion_accessory, 
													Mount#status_mount.mount_figure,
                                                    NewGo#status_goods.hide_head,
                                                        NewGo#status_goods.hide_tail,
                                                        NewGo#status_goods.hide_ring,
                                                        NewGo#status_goods.fashion_head,
                                                        NewGo#status_goods.fashion_tail,
                                                        NewGo#status_goods.fashion_ring]),
    lib_server_send:send_to_area_scene(NewPlayerStatus#player_status.scene, 
                                                    NewPlayerStatus#player_status.copy_id,
                                                    NewPlayerStatus#player_status.x, 
                                                    NewPlayerStatus#player_status.y, BinData1),
    {ok, equip, NewPlayerStatus}.

%%更新装备磨损信息
updata_equip_attrition(Status) ->
    Go = Status#player_status.goods,
    NewEquipAttrit = Go#status_goods.equip_attrit + 1,
    %% 每战斗100次，更新一次状态
    case NewEquipAttrit >= 100 of
        true ->
            %% 更新装备磨损状态
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'attrit', Status, NewEquipAttrit}) of
                {ok, NewStatus} ->
                    NewStatus2 = NewStatus#player_status{goods=Go#status_goods{equip_attrit = 0}};
                {'EXIT', _Error} ->
                    NewStatus2 = Status#player_status{goods=Go#status_goods{equip_attrit = 0}}
            end;
        false ->
            NewStatus2 = Status#player_status{goods=Go#status_goods{equip_attrit = NewEquipAttrit}}
    end,
    {ok, NewStatus2}.
   
%% 刷新热卖
refresh_limit_shop() ->
    mod_disperse:call_to_unite(lib_shop, init_limit_shop, [{0,0,0}]).

%% 获取物品数量
%% 不在物品进程时GoodsStatus传0
get_goods_num(PS, GoodsTypeId, GoodsStatus) ->
    case GoodsStatus =:= 0 of
        true -> %% 不在物品进程
            Dict = lib_goods_dict:get_player_dict(PS),
            case Dict =/= [] of
                true ->
                    List = lib_goods_util:get_type_goods_list(PS#player_status.id, GoodsTypeId, 4, Dict), 
                    get_num(List, 0);
                false ->
                    0
            end;
        false ->
            List = lib_goods_util:get_type_goods_list(PS#player_status.id, GoodsTypeId, 4, GoodsStatus#goods_status.dict), 
            get_num(List, 0)
    end.

get_num([], N) ->
    N;
get_num([GoodsInfo|T], N) ->
    if
        is_record(GoodsInfo, goods) =:= true ->
            get_num(T, GoodsInfo#goods.num+N);
        true ->
            get_num(T, N)
    end.

%% 变性
equip_change_sex(PS) ->
    Go = PS#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'change_sex', PS#player_status.id}) of
        {ok, Res} ->
            Res;
        {'EXIT', _Error} ->
            skip
    end.

%%使用物品背包武器变性
change_sex_bag(GoodsStatus, GoodsInfo, EquipInfo) ->
    [G1,G2,G3,G4,G5,A] = integer_to_list(EquipInfo#goods.goods_id),
    B = list_to_integer([A]) + 5,
    C = integer_to_list(B),
    case length(C) of
        2 ->
            [_, D] = C;
        1 ->
            [D] = C
    end,
    F = fun() ->
            {ok, NewStatus1} = lib_goods:delete_more(GoodsStatus, [GoodsInfo], 1),
            ok = lib_goods_dict:start_dict(),
            NewId = list_to_integer([G1,G2,G3,G4,G5,D]),
            NewEquipInfo = EquipInfo#goods{goods_id = NewId},

            Dict = lib_goods_dict:add_dict_goods(NewEquipInfo, NewStatus1#goods_status.dict),
            NewStatus = NewStatus1#goods_status{dict = Dict},
            lib_fashion_change2:update_goods_id(NewId, NewEquipInfo#goods.id),
            {ok, NewStatus, NewEquipInfo}
    end,
    lib_goods_util:transaction(F).
    
%% 功章续期
token_renewal(GoodsStatus, GoodsInfo, Days, NeedNum) ->
    GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, 523501, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
    F = fun() ->
            {ok, NewStatus1} = lib_goods:delete_more(GoodsStatus, GoodsList, NeedNum),
            ok = lib_goods_dict:start_dict(),
            NowTime = util:unixtime(),
            ExpireTime = NowTime + 86400 * Days,
            Sql = io_lib:format(<<"update goods set expire_time = ~p where id = ~p">>,[ExpireTime, GoodsInfo#goods.id]),
            db:execute(Sql),
            NewGoodsInfo = GoodsInfo#goods{expire_time = ExpireTime},
            Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, NewStatus1#goods_status.dict),
            NewStatus2 = NewStatus1#goods_status{dict = Dict},
            D = lib_goods_dict:handle_dict(NewStatus2#goods_status.dict),
            NewStatus = NewStatus2#goods_status{dict = D},
            {ok, NewStatus, NewGoodsInfo}
    end,
    lib_goods_util:transaction(F).

%% 升级
token_upgrade(PlayerStatus, GoodsStatus, GoodsInfo, TokenInfo, NeedNum) ->
    GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, 523501, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
    F = fun() ->
            %%删除物品
        {ok, NewStatus1} = lib_goods:delete_more(GoodsStatus, GoodsList, NeedNum),
        ok = lib_goods_dict:start_dict(),
        %Kf = PlayerStatus#player_status.kf_1v1,
        %Pt = Kf#status_kf_1v1.pt - TokenInfo#kf_token.pt,
        %NewKf = Kf#status_kf_1v1{pt = Pt},
        %io:format("upbrade pt = ~p~n", [{TokenInfo#kf_token.pt, Kf#status_kf_1v1.pt, Pt, TokenInfo#kf_token.token_id}]),
        %% 改PT
        %NewPS = PlayerStatus#player_status{kf_1v1 = NewKf},
        %Sql = io_lib:format(<<"update player_kf_1v1 set pt = ~p where id = ~p">>,[Pt, PlayerStatus#player_status.id]),
        %db:execute(Sql),

        GoodsTypeInfo = data_goods_type:get(TokenInfo#kf_token.token_id),
        Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
        %% 改ID
        NewGoodsInfo = GoodsInfo#goods{goods_id=TokenInfo#kf_token.token_id, hp=Info#goods.hp, att=Info#goods.att},
        Sql2 = io_lib:format(<<"update goods_high set goods_id=~p where gid=~p">>, [NewGoodsInfo#goods.goods_id, NewGoodsInfo#goods.id]),
        Sql3 = io_lib:format(<<"update goods_low set gtype_id=~p where gid=~p">>, [NewGoodsInfo#goods.goods_id, NewGoodsInfo#goods.id]),
        Sql4 = io_lib:format(<<"update goods set hp=~p, att=~p where id=~p">>, [NewGoodsInfo#goods.hp, NewGoodsInfo#goods.att, NewGoodsInfo#goods.id]),
        db:execute(Sql2),
        db:execute(Sql3),
        db:execute(Sql4),
        Dict = lib_goods_dict:append_dict({add, goods, NewGoodsInfo}, NewStatus1#goods_status.dict),
        NewStatus2 = NewStatus1#goods_status{dict = Dict},
        D = lib_goods_dict:handle_dict(NewStatus2#goods_status.dict),
        NewStatus = NewStatus2#goods_status{dict = D},
        {ok, PlayerStatus, NewStatus, NewGoodsInfo}
    end,
    lib_goods_util:transaction(F).

%% 替换身上效果
change_body_effect(PS, Pos, Stren) ->
    G = PS#player_status.goods,
    [_Weapon, _Clothes, _Zq, WqStren, _YfStren, _Sz] = G#status_goods.equip_current,
    N = lib_goods:get_min_stren7_num2(G#status_goods.stren7_num),
    if
        Pos =:= 1 andalso N < Stren ->
            {fail, 2};
        Pos =:= 2 andalso WqStren < Stren ->
            {fail, 2};
        (Pos =/= 1 andalso Pos =/= 2) orelse Stren < 0 ->
            {fail, 3};
        true ->
            if
                Pos =:= 1 ->
                    Sql = io_lib:format(<<"update player_low set body = ~p where id = ~p">>, [Stren, PS#player_status.id]),
                    db:execute(Sql),
                    NewPS = PS#player_status{goods = G#status_goods{body_effect = Stren}};
                Pos =:= 2 ->
                    Sql = io_lib:format(<<"update player_low set feet = ~p where id = ~p">>, [Stren, PS#player_status.id]),
                    db:execute(Sql),
                    NewPS = PS#player_status{goods = G#status_goods{feet_effect = Stren}};
                true ->
                    NewPS = PS
            end,
            {ok, NewPS}
    end.


