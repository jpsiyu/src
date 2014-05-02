%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-13
%% Description: 血包操作模块
%% --------------------------------------------------------
-module(lib_hp_bag).
-include("common.hrl").
-include("record.hrl").
-include("goods.hrl").
-include("server.hrl").
-export(
    [
        get_bag_count/2,
        get_bag_info/2,
        get_bag_list/1,
        get_reply_span/1,
        is_bag/1,
        reply_hm/2,
        reply/2,
        use_bag/4,
        offline/1,
        init/1
    ]
).

-define(sql_hp_insert, "insert into `role_hp_bag` (role_id, type, bag_num, reply_num, goods_id, time) values (~p,~p,~p,~p,~p,~p)").
-define(sql_hp_update, "update `role_hp_bag` set `bag_num`=~p, `reply_num`=~p, `goods_id`=~p, `time`=~p  where `role_id`=~p and `type`=~p ").
-define(sql_hp_delete, "delete from `role_hp_bag` where `role_id`=~p and `type`=~p ").
-define(sql_hp_select, "select `role_id`,`type`,`bag_num`,`reply_num`,`goods_id`,`time` from `role_hp_bag` where `role_id`=~p ").
-define(sql_hp_select2, "select * from `role_hp_bag` where `role_id`=~p and `type`=~p").

%% 获取角色包的存储量，Type：5气血包，6法力包
get_bag_count(RoleId, Type) ->
    case ets:lookup(?ETS_HP_BAG, {RoleId,Type})of
        [] ->
            0;
        [Reply] ->
            Reply#ets_hp_bag.bag_num
    end.

%% 获取血包信息
get_bag_info(Role_id, Type) ->
    ets:lookup(?ETS_HP_BAG, {Role_id,Type}).

%% 获取血包列表
get_bag_list(Role_id) ->
    ets:match_object(?ETS_HP_BAG, #ets_hp_bag{role_id=Role_id, _='_'}).

%% 获取回复间隔的秒数
get_reply_span(Type) ->
    case data_hp_bag:get(Type) of
        [] -> 
            15;
        Base -> 
            Base#base_hp_bag.reply_span
    end.

%% 获取回复类型
get_reply_type(SubType) ->
    case SubType of
        1 -> 1;
        2 -> 2;
        3 -> 5;
        4 -> 6;
        5 -> 5;
        6 -> 6;
        7 -> 7;
        8 -> 8
    end.

%% 判断是否是气血类
is_hp(Type) ->
    (Type =:= 1 orelse Type =:= 3 orelse Type =:= 5 orelse Type =:= 7).

%% 判断是否是血包类
is_bag(Type) ->
    (Type =/= 1 andalso Type =/= 2).

%% 气血内力药回复
reply_hm(PlayerStatus, Type) ->
    case data_hp_bag:get(Type) of
        %% 没有找到药品配置
        [] -> {fail, 2};
        Base ->
            HpFlag = is_hp(Type),
            Hp_bag = PlayerStatus#player_status.hp_bag,
            if  %% 人物死亡，无法回复
                PlayerStatus#player_status.hp =< 0 ->
                    {fail, 4};
                %% 气血已满，无需回复
                HpFlag =:= true andalso PlayerStatus#player_status.hp >= PlayerStatus#player_status.hp_lim ->
                    {fail, 5};
                %% 内力已满，无需回复
                HpFlag =:= false andalso PlayerStatus#player_status.mp >= PlayerStatus#player_status.mp_lim ->
                    {fail, 6};
                true ->
                    case HpFlag of
                        true ->
                            Hp = PlayerStatus#player_status.hp,
                            Hp_lim = PlayerStatus#player_status.hp_lim,
                            Hp_reply = Hp_bag#status_hp.hp_reply;
                        false ->
                            Hp = PlayerStatus#player_status.mp,
                            Hp_lim = PlayerStatus#player_status.mp_lim,
                            Hp_reply = Hp_bag#status_hp.mp_reply
                    end,
                    NowTime = util:unixtime(),
                    case Hp_reply of
                        %% 回复时间未到
                        [_ReplyNum, _LastNum, LastTime] when NowTime < (LastTime + Base#base_hp_bag.reply_span) ->
                            {fail, 7};
                        [ReplyNum, LastNum, _LastTime] ->
                            Reply_num = case LastNum < ReplyNum of
                                            true -> LastNum;
                                            false -> ReplyNum
                                        end,
                            NewHp = case (Hp + Reply_num) >= Hp_lim of
                                        true -> Hp_lim;
                                        false -> Hp + Reply_num
                                    end,
                            NewReply_num = NewHp - Hp,
                            NewNum = LastNum - NewReply_num,
                            HpReply = case NewNum =< 0 of
                                          true -> [];
                                          false -> [ReplyNum, NewNum, NowTime]
                                      end,
                            case HpFlag of
                                true -> 
                                    NewPlayerStatus = PlayerStatus#player_status{hp = NewHp, hp_bag=Hp_bag#status_hp{hp_reply = HpReply}};
                                false -> 
                                    NewPlayerStatus = PlayerStatus#player_status{mp = NewHp, hp_bag=Hp_bag#status_hp{mp_reply = HpReply}}
                            end,
                            {ok, NewPlayerStatus, 0, NewNum, Base#base_hp_bag.reply_span};
                        %% 没有找到回复药品
                        _ -> {fail, 3}
                    end
            end
    end.

%% 血包回复
reply(PlayerStatus, Type) ->
    case data_hp_bag:get(Type) of
        %% 没有找到药品配置
        [] -> {fail, 2};
        Base ->
            case get_bag_info(PlayerStatus#player_status.id, Type) of
                %% 没有找到回复药品
                [] -> {fail, 3};
                [Reply] ->
                    NowTime = util:unixtime(),
                    HpFlag = is_hp(Type),
                    if  %% 人物死亡，无法回复
                        PlayerStatus#player_status.hp =< 0 ->
                            {fail, 4};
                        %% 气血已满，无需回复
                        HpFlag =:= true andalso PlayerStatus#player_status.hp >= PlayerStatus#player_status.hp_lim ->
                            {fail, 5};
                        %% 内力已满，无需回复
                        HpFlag =:= false andalso PlayerStatus#player_status.mp >= PlayerStatus#player_status.mp_lim ->
                            {fail, 6};
                        %% 回复时间未到
                        NowTime < (Reply#ets_hp_bag.time + Base#base_hp_bag.reply_span - 1) ->
                            {fail, 7};
                        true ->
                            Flag1 =
                                case Base#base_hp_bag.scene_lim =/= [] of
                                    true ->
                                        SceneType1 = lib_scene:get_res_type(PlayerStatus#player_status.scene),
                                        case lists:member(SceneType1, Base#base_hp_bag.scene_lim) of
                                            true -> false;
                                            false -> true
                                        end;
                                    false -> true
                                end,
                            Flag2 =
                                case Flag1 =:= true andalso Base#base_hp_bag.scene_allow =/= [] of
                                    true ->
                                        SceneType2 = lib_scene:get_res_type(PlayerStatus#player_status.scene),
                                        case lists:member(SceneType2, Base#base_hp_bag.scene_allow) of
                                            true -> true;
                                            false -> false
                                        end;
                                    false -> Flag1
                                end,
                            case Flag2 of
                                %% 该场景限制回复
                                false -> {fail, 8};
                                true ->
                                    case HpFlag of
                                        true ->
                                            Hp = PlayerStatus#player_status.hp,
                                            Hp_lim = PlayerStatus#player_status.hp_lim;
                                        false ->
                                            Hp = PlayerStatus#player_status.mp,
                                            Hp_lim = PlayerStatus#player_status.mp_lim
                                    end,
                                    Reply_num = case Reply#ets_hp_bag.reply_num =:= 0 of
                                                    true -> Hp_lim - Hp;
                                                    false -> Reply#ets_hp_bag.reply_num
                                                end,
                                    Reply_num2 = case Reply#ets_hp_bag.bag_num < Reply_num of
                                                    true -> Reply#ets_hp_bag.bag_num;
                                                    false -> Reply_num
                                                end,
                                    NewHp = case (Hp + Reply_num2) >= Hp_lim of
                                                true -> Hp_lim;
                                                false -> Hp + Reply_num2
                                            end,
                                    NewReply_num = NewHp - Hp,
                                    NewBag_num = Reply#ets_hp_bag.bag_num - NewReply_num,
                                    %% io:format("Line:~p Hp:~p, NewHp:~p, Reply_num:~p NewBag_num:~p OldBag_num:~p~n", [?LINE,Hp,NewHp,NewReply_num,NewBag_num,Reply#ets_hp_bag.bag_num]),
                                    % io:format("use NewBag_num=~p~n", [NewBag_num]),
                                    case NewBag_num > 0 of
                                        true -> 
                                            change_bag_num(Reply, NewBag_num, Reply#ets_hp_bag.reply_num, Reply#ets_hp_bag.goods_id, NowTime);
                                        false -> 
                                            del_bag_num(Reply)
                                    end,
                                    NewPlayerStatus = case HpFlag of
                                                          true -> 
                                                              PlayerStatus#player_status{hp=NewHp};
                                                          false -> 
                                                              PlayerStatus#player_status{mp=NewHp}
                                                      end,
                                    {ok, NewPlayerStatus, Reply#ets_hp_bag.goods_id, NewBag_num, Base#base_hp_bag.reply_span}
                            end
                    end
            end
    end.

%% 使用血包
use_bag(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum) ->
    Role_id = PlayerStatus#player_status.id,
    Type = get_reply_type(GoodsInfo#goods.subtype),
%%     io:format("use type = ~p, GoodsNum = ~p~n", [Type, GoodsNum]),
    case data_hp_bag:get(Type) of
        %% 没有找到药品配置
        [] -> {fail, 1513};
        Base ->
            Flag1 =
                case Base#base_hp_bag.scene_lim =/= [] of
                    true ->
                        SceneType1 = lib_scene:get_res_type(PlayerStatus#player_status.scene),
                        case lists:member(SceneType1, Base#base_hp_bag.scene_lim) of
                            true -> false;
                            false -> true
                        end;
                    false -> true
                end,
            Flag2 =
                case Flag1 =:= true andalso Base#base_hp_bag.scene_allow =/= [] of
                    true ->
                        SceneType2 = lib_scene:get_res_type(PlayerStatus#player_status.scene),
                        case lists:member(SceneType2, Base#base_hp_bag.scene_allow) of
                            true -> true;
                            false -> false
                        end;
                    false -> Flag1
                end,
            case Flag2 of
                %% 该场景限制回复
                false -> {fail, 1541};
                true ->
                    HpFlag = is_hp(Type),
                    Hp_bag =  case HpFlag of
                                    true -> 
                                        GoodsInfo#goods.hp;
                                    false -> 
                                        GoodsInfo#goods.mp
                                end,
                    RoleHMBag = PlayerStatus#player_status.hp_bag,
                    case is_bag(Type) of
                        true ->
                            [_,Reply_num] = data_hp_mp:get_bag_by_lv(PlayerStatus#player_status.lv),
                            case get_bag_info(Role_id, Type) of
                                [] ->
                                    Id = {Role_id,Type},
                                    Bag_num = Hp_bag * GoodsNum,
                                    %%Reply_num = data_hp_bag:get_reply_num(GoodsInfo#goods.goods_id),
                                    NewReply = #ets_hp_bag{id=Id, role_id=Role_id, type=Type, bag_num=Bag_num, reply_num=Reply_num, goods_id=GoodsInfo#goods.goods_id},
                                    add_bag_num(NewReply);
                                [Reply] when Reply#ets_hp_bag.goods_id =/= GoodsInfo#goods.goods_id ->
                                    Bag_num = Hp_bag * GoodsNum + Reply#ets_hp_bag.bag_num,
                                    %%Reply_num = data_hp_bag:get_reply_num(GoodsInfo#goods.goods_id),
                                    case Reply#ets_hp_bag.goods_id > GoodsInfo#goods.goods_id of
                                        true ->
                                            NewReply = change_bag_num(Reply, Bag_num, Reply_num, Reply#ets_hp_bag.goods_id, Reply#ets_hp_bag.time);
                                        false ->
                                            NewReply = change_bag_num(Reply, Bag_num, Reply_num, GoodsInfo#goods.goods_id, Reply#ets_hp_bag.time)
                                    end;
                                [Reply] ->
                                    Bag_num = Reply#ets_hp_bag.bag_num + Hp_bag * GoodsNum,
                                    NewReply = change_bag_num(Reply, Bag_num, Reply_num, Reply#ets_hp_bag.goods_id, Reply#ets_hp_bag.time)
                            end,
                            NewStatus = GoodsStatus,
                            GoodsId = NewReply#ets_hp_bag.goods_id,
                            BagNum = NewReply#ets_hp_bag.bag_num,
                            Result = reply(PlayerStatus, Type);
                        false ->
                             case HpFlag of
                                true ->
                                    Hp = PlayerStatus#player_status.hp,
                                    Hp_lim = PlayerStatus#player_status.hp_lim,
                                    YaoPinUseTime = RoleHMBag#status_hp.yaopin_use_time;
                                false ->
                                    Hp = PlayerStatus#player_status.mp,
                                    Hp_lim = PlayerStatus#player_status.mp_lim,
                                    YaoPinUseTime = RoleHMBag#status_hp.yaopin_use_time
                            end,
                            NowTime = util:unixtime(),
                            case NowTime < (YaoPinUseTime + Base#base_hp_bag.reply_span) of
                                true ->
                                    Result = {fail, 7};
                                false ->
                                    NewHp = case (Hp + Hp_bag) >= Hp_lim of
                                                true -> Hp_lim;
                                                false -> Hp + Hp_bag
                                            end,
                                    case HpFlag of
                                        true ->
                                            %% io:format("Line:~p Hp:~p, NewHp:~p, GoodHM:~p ~n", [?LINE,Hp,NewHp,Hp_bag]),
                                            PlayerStatus2 = PlayerStatus#player_status{hp = NewHp, hp_bag=RoleHMBag#status_hp{yaopin_use_time = NowTime}};
                                        false -> 
                                            %% io:format("Line:~p Hp:~p, NewHp:~p, GoodHM:~p ~n", [?LINE,Hp,NewHp,Hp_bag]),
                                            PlayerStatus2 = PlayerStatus#player_status{mp = NewHp, hp_bag=RoleHMBag#status_hp{yaopin_use_time = NowTime}}
                                    end,
                                    Result = {ok, PlayerStatus2, 0, 0, Base#base_hp_bag.reply_span}
                            end,
                            %% 计算冷却时间                           
                            NewStatus = case HpFlag of
                                            true ->
                                                Cd_time = util:unixtime() + data_hp_mp:get_hp_yaopin_cd_len(),
                                                GoodsStatus#goods_status{hp_cd=Cd_time};
                                            false -> 
                                                Cd_time = util:unixtime() + data_hp_mp:get_mp_yaopin_cd_len(),
                                                GoodsStatus#goods_status{mp_cd=Cd_time}
                                        end,
                            GoodsId = 0,
                            BagNum = Hp_bag
                            %%Result = reply_hm(PlayerStatus2, Type)
                    end,
                    case Result of
                        {ok, NewPlayerStatus, Goods_id, NewBag_num, Span} ->
                            {ok, BinData} = pt_130:write(13061, [1, Type, Goods_id, NewBag_num, Span, NewPlayerStatus#player_status.mp]),
                            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                            case NewPlayerStatus#player_status.hp =/= PlayerStatus#player_status.hp of
                                true ->
                                    {ok, BinData1} = pt_120:write(12009, [NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.platform, NewPlayerStatus#player_status.server_num, NewPlayerStatus#player_status.hp, NewPlayerStatus#player_status.hp_lim]),
                                    lib_server_send:send_to_area_scene(NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.copy_id, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, BinData1);
                                false -> skip
                            end,
                            {ok, NewPlayerStatus, NewStatus};
                        {fail, _Res} ->
                            {ok, BinData} = pt_130:write(13061, [1, Type, GoodsId, BagNum, Base#base_hp_bag.reply_span, PlayerStatus#player_status.mp]),
                            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
                            {ok, PlayerStatus, NewStatus};
                        _Error ->
                            util:errlog("hp error ~p~n", [_Error]),
                            {fail, 1500}
                    end
            end
    end.


%% 更改血包储量
add_bag_num(Reply) ->
    Sql1 = io_lib:format(?sql_hp_select2, [Reply#ets_hp_bag.role_id, Reply#ets_hp_bag.type]),
    case db:get_all(Sql1) of
        [] -> 
            Sql = io_lib:format(?sql_hp_insert,
                        [Reply#ets_hp_bag.role_id, Reply#ets_hp_bag.type, Reply#ets_hp_bag.bag_num, 
                         Reply#ets_hp_bag.reply_num, Reply#ets_hp_bag.goods_id, Reply#ets_hp_bag.time]),
            db:execute(Sql),
            ets:insert(?ETS_HP_BAG, Reply);
        List when is_list(List) ->
            Sql = io_lib:format(?sql_hp_update, [Reply#ets_hp_bag.bag_num, Reply#ets_hp_bag.reply_num, Reply#ets_hp_bag.goods_id, Reply#ets_hp_bag.time, Reply#ets_hp_bag.role_id, Reply#ets_hp_bag.type]),
            db:execute(Sql),
            NewReply = Reply#ets_hp_bag{bag_num=Reply#ets_hp_bag.bag_num, reply_num=Reply#ets_hp_bag.reply_num, goods_id=Reply#ets_hp_bag.goods_id, time=Reply#ets_hp_bag.time},
            ets:insert(?ETS_HP_BAG, NewReply);
        _ ->
            skip
    end.

%% 更改血包储量
change_bag_num(Reply, Bag_num, ReplyNum, GoodsId, Time) ->
    Sql = io_lib:format(?sql_hp_update, [Bag_num, ReplyNum, GoodsId, Time, Reply#ets_hp_bag.role_id, Reply#ets_hp_bag.type]),
    db:execute(Sql),
    NewReply = Reply#ets_hp_bag{bag_num=Bag_num, reply_num=ReplyNum, goods_id=GoodsId, time=Time},
    ets:insert(?ETS_HP_BAG, NewReply),
    NewReply.

%% 删除血包
del_bag_num(Reply) ->
    Sql = io_lib:format(?sql_hp_delete, [Reply#ets_hp_bag.role_id, Reply#ets_hp_bag.type]),
    db:execute(Sql),
    ets:delete(?ETS_HP_BAG, Reply#ets_hp_bag.id).

%% 下线
offline(Role_id) ->
    ets:match_delete(?ETS_HP_BAG, #ets_hp_bag{role_id=Role_id, _='_'}),
    ok.

%% 初始化 ETS
init(Role_id) ->
    ets:match_delete(?ETS_HP_BAG, #ets_hp_bag{role_id=Role_id, _='_'}),
    F = fun([Mrole_id, Mtype, Mbag_num, Mreply_num, Mgoods_id, Mtime]) ->
                Info = #ets_hp_bag{
                                id = {Mrole_id,Mtype},
                                role_id = Mrole_id,
                                type = Mtype,
                                bag_num = Mbag_num,
                                reply_num = Mreply_num,
                                goods_id = Mgoods_id,
                                time = Mtime
                         },
                ets:insert(?ETS_HP_BAG, Info)
         end,
    Sql = io_lib:format(?sql_hp_select, [Role_id]),
    case db:get_all(Sql) of
        [] -> skip;
        List when is_list(List) ->
            lists:foreach(F, List);
        _ -> skip
    end,
    ok.
