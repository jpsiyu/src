%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-1-29
%% Description: 宝箱操作
%% --------------------------------------------------------
-module(pp_box).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("box.hrl").

%% 开宝箱
handle(17000, PlayerStatus, [BoxId, BoxNum]) ->
	case lib_secondary_password:is_pass(PlayerStatus) of
		false -> 
			skip;
		true ->
			G = PlayerStatus#player_status.goods,
			case gen:call(G#status_goods.goods_pid, '$gen_call', {'box_open', PlayerStatus, BoxId, BoxNum}) of
				{ok, [NewPlayerStatus, Res, GiveList, NoticeList, Cost, GoodsTypeId]} ->
					{ok, BinData} = pt_170:write(17000, [Res, BoxId, NewPlayerStatus#player_status.gold, GoodsTypeId, GiveList]),
					lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
					if length(NoticeList) > 0 ->
						{ok, BinData2} = pt_170:write(17006, [
							NewPlayerStatus#player_status.id, BoxId, 
							NewPlayerStatus#player_status.realm, 
							NewPlayerStatus#player_status.nickname, NoticeList
						]),
						L = filter_notice_list(NoticeList, []),
                        %% 不发传闻的大R
                        M = lists:member(PlayerStatus#player_status.id, []),
                        if
                            BoxId =:= 1 andalso M =/= true ->
						        %% 传闻
						        lib_chat:send_TV({all},0, 2, [
							        "taobao", 1, 
							        NewPlayerStatus#player_status.id, 
							        NewPlayerStatus#player_status.realm, 
							        NewPlayerStatus#player_status.nickname, 
							        NewPlayerStatus#player_status.sex, 
							        NewPlayerStatus#player_status.career, 
							        NewPlayerStatus#player_status.image 
						        ] ++ L);
                            BoxId =:= 2 andalso M =/= true ->
                                lib_chat:send_TV({all},0, 2, [
							        "taobao", 2, 
							        NewPlayerStatus#player_status.id, 
							        NewPlayerStatus#player_status.realm, 
							        NewPlayerStatus#player_status.nickname, 
							        NewPlayerStatus#player_status.sex, 
							        NewPlayerStatus#player_status.career, 
							        NewPlayerStatus#player_status.image 
						        ] ++ L);
                            true ->
                                skip
                        end,
						lib_server_send:send_to_all(BinData2);
					true -> 
						skip
				end,
				%% 运势任务(3700012:我淘我乐)
				lib_fortune:fortune_daily(PlayerStatus#player_status.id, 3700012, 1),
				%% 限时名人堂活动
				NewPlayerStatus2 = 
				case Res == 1 of
					true ->
                        %淘宝消费
                        lib_activity:add_consumption(taobao,NewPlayerStatus,Cost),
						lib_fame_limit:trigger_taobao(NewPlayerStatus, BoxNum);
					_ ->
						NewPlayerStatus
				end,

				{ok, NewPlayerStatus2};
			{'EXIT',_Reason} -> 
				skip
		end
	end;

%% 宝箱包裹列表
handle(17001, PlayerStatus, list) ->
    BoxBag = lib_box:get_box_bag(PlayerStatus),
    {ok, BinData} = pt_170:write(17001, BoxBag),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%% 获取宝箱包裹里的物品信息
handle(17002, PlayerStatus, GoodsTypeId) ->
    [Res, Prefix, Stren, AttributeList, Bind] = info(PlayerStatus, GoodsTypeId),
    {ok, BinData} = pt_170:write(17002, [Res, GoodsTypeId, Prefix, Stren, AttributeList, Bind]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%% 取宝箱物品
handle(17003, PlayerStatus, GoodsTypeId) ->
    [NewPlayerStatus, Res] = get_one(PlayerStatus, GoodsTypeId),
    {ok, BinData} = pt_170:write(17003, [Res, GoodsTypeId]),
    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
    {ok, NewPlayerStatus};

%% 取宝箱全部物品
handle(17004, PlayerStatus, get_all) ->
    [NewPlayerStatus, Res] = get_all(PlayerStatus),
    {ok, BinData} = pt_170:write(17004, Res),
    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
    {ok, NewPlayerStatus};

%% 取宝箱初始信息
handle(17005, PlayerStatus, init) ->
    {ok, BinData} = pt_170:write(17005, data_box:get_all()),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%% 取宝箱播报列表
handle(17007, PlayerStatus, notice) ->
    case mod_disperse:call_to_unite(mod_box, get_notice, []) of
        List when is_list(List) -> 
            NoticeList = List;
        _ -> 
            NoticeList = []
    end,
    {ok, BinData} = pt_170:write(17007, NoticeList),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%% 淘宝兑换
handle(17010, PlayerStatus, [StoneId, EquipId, Pos]) ->
    G = PlayerStatus#player_status.goods,
    if
        PlayerStatus#player_status.box_bag =:= null ->
            Bag = lib_box:get_box_bag(PlayerStatus),
            PlayerStatus1 = PlayerStatus#player_status{box_bag = Bag};
        true ->
            PlayerStatus1 = PlayerStatus
    end,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'box_exchange', PlayerStatus1, StoneId, EquipId, Pos}) of
        {ok, [Res, NewPlayerStatus, Bind]} ->
            if
                Res =:= 1 ->
                    [NewPS, GiftId] = count_exchange(NewPlayerStatus, EquipId);
                true ->
                    [NewPS, GiftId] = [NewPlayerStatus, 0]
            end,
            {ok, BinData} = pt_170:write(17010, [Res, EquipId, Bind, GiftId]),
            lib_server_send:send_one(NewPS#player_status.socket, BinData),
            {ok, NewPS};
        {'EXIT', _R} ->
            {ok, PlayerStatus1}
    end;

%% 取兑换表
handle(17011, PlayerStatus, exchange) ->
    [Num, GiftId] = get_exchange_num(PlayerStatus),
    [TypeList, _] = get_type_list(PlayerStatus),
    {ok, BinData} = pt_170:write(17011, [Num, GiftId, TypeList]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    {ok, PlayerStatus};

%% 取礼包
handle(17012, PlayerStatus, [GiftId]) ->
    case lib_box_check:check_get_gift(PlayerStatus, GiftId) of
        {fail, Res} ->
            {ok, BinData} = pt_170:write(17012, [Res, GiftId]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
        {ok, GiftId2} ->
            G = PlayerStatus#player_status.goods,
			case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PlayerStatus, GiftId2}) of
				{ok, [ok, NewPS]} ->
				    {ok, BinData} = pt_170:write(17012, [1, GiftId2]),
				    lib_server_send:send_to_sid(NewPS#player_status.sid, BinData),
                    [TypeList, GiftList] = get_type_list(NewPS),
                    NewGiftList = GiftList ++ [GiftId2],
                    Sql = io_lib:format(?sql_update_exchange2, [util:term_to_string(NewGiftList), PlayerStatus#player_status.id]),
                    db:execute(Sql),
                    NewPS1 = update_exchange_dict(NewPS, TypeList, NewGiftList),
				    {ok, NewPS1};
			    {ok, [error, ErrorCode]} ->
					{ok, BinData} = pt_170:write(17012, [ErrorCode, GiftId2]),
					lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
                    {ok, PlayerStatus}
            end
    end;       
   
handle(_Cmd, _Status, _Data) ->
    ?INFO("pp_box no match: ~p", [[_Cmd,_Data]]),
    {error, pp_box_no_match}.

%%
%% 内部处理函数
%%

%% 取兑换数量和礼包ID
get_exchange_num(PlayerStatus) ->
    Dict = PlayerStatus#player_status.exchange_dict,
    case dict:is_key(PlayerStatus#player_status.id, Dict) of
        true ->
            [Exchange] = dict:fetch(PlayerStatus#player_status.id, Dict),
            TypeList = Exchange#ets_box_exchange.type_list,
            GiftList = Exchange#ets_box_exchange.gift_list,
            N = length(TypeList),
            if
                N >= 2 andalso N < 4 ->   % 第一个礼包
                    case lists:member(532451, GiftList) of
                        true ->
                            [N, 0];
                        false ->
                            [N, 532451]
                    end;
                N >= 4 andalso N < 6 ->
                    case lists:member(532451, GiftList) of
                        true ->
                            case lists:member(532452, GiftList) of
                                true ->      % 第二个礼包
                                    [N, 0];
                                false ->
                                    [N, 532452]
                            end;
                        false ->
                            [N, 532451]
                    end;
                N =:= 6 ->
                    case lists:member(532451, GiftList) of
                        true ->
                            case lists:member(532452, GiftList) of
                                true ->      % 第二个礼包
                                    case lists:member(532453, GiftList) of
                                        true ->
                                            [N, 0];
                                        false ->     % 第三个礼包
                                            [N, 532453]
                                    end;
                                false ->
                                    [N, 532452]
                            end;
                        false ->
                            [N, 532451]
                    end;
                true ->
                    [N, 0]
            end;
        false ->
            [0,0]
    end.

%% 处理兑换
count_exchange(PS, EquipId) ->
    Dict = PS#player_status.exchange_dict,
    case dict:is_key(PS#player_status.id, Dict) of
        true ->
            [Exchange] = dict:fetch(PS#player_status.id, Dict),
            TypeList = Exchange#ets_box_exchange.type_list,
            GiftList = Exchange#ets_box_exchange.gift_list,
            case lists:member(EquipId, TypeList) of
                true ->%% 已经兑换过的不算
                    GiftId = 0,
                    NewPS = PS;
                false -> 
                    NewTypeList = TypeList ++ [EquipId],
                    %% 判断兑换件数
                    N = length(NewTypeList),
                    if
                        N =:= 1 ->
                            GiftId = 0;
                        N >= 2 andalso N < 4 ->   % 第一个礼包
                            case lists:member(532451, GiftList) of
                                false ->
                                    GiftId = 532451;
                                true ->
                                    GiftId = 0
                            end;
                        N >= 4 andalso N < 6 ->   % 第二个礼包
                            case lists:member(532452, GiftList) of
                                false ->
                                    GiftId = 532452;
                                true ->
                                    GiftId = 0
                            end;
                        N =:= 6 ->   % 第三个礼包
                            case lists:member(532453, GiftList) of
                                false ->
                                    GiftId = 532453;
                                true ->
                                    GiftId = 0
                            end;
                        true ->
                            GiftId = 0
                    end,
                    Sql2 = io_lib:format(?sql_update_exchange, [util:term_to_string(NewTypeList), PS#player_status.id]),
                    db:execute(Sql2),
                    NewPS = update_exchange_dict(PS, NewTypeList, GiftList)
            end,
            [NewPS, GiftId];
        false ->
            %% 第一次
            Sql1 = io_lib:format(?sql_insert_exchange, [PS#player_status.id, util:term_to_string([EquipId])]),
            db:execute(Sql1),
            NewPS = update_exchange_dict(PS, [EquipId], []),
            [NewPS, 0]
    end.

%% 获取兑换列表
get_type_list(PS) ->
    Dict = PS#player_status.exchange_dict,
    case dict:is_key(PS#player_status.id, Dict) of
        true ->
            [Exchange] = dict:fetch(PS#player_status.id, Dict),
            [Exchange#ets_box_exchange.type_list,Exchange#ets_box_exchange.gift_list];
        false ->
            [[], []]
    end.

%% 更新兑换字典
update_exchange_dict(PS, NewTypeList, NewGiftList) ->
    Dict = PS#player_status.exchange_dict,
    Exchange = #ets_box_exchange{
        pid = PS#player_status.id,
        type_list = NewTypeList,
        gift_list = NewGiftList
    },
    Dict2 = lib_mount:add_dict(PS#player_status.id, Exchange, Dict),
    PS#player_status{exchange_dict = Dict2}.

%% 获取宝箱包裹里的物品信息
info(PlayerStatus, GoodsTypeId) ->
    BoxBag = lib_box:get_box_bag(PlayerStatus),
    case lists:keyfind(GoodsTypeId, 1, BoxBag) of
        %% 物品不存在
        false -> 
            [2, 0, 0, [], 0];
        Info ->
            case get_goods(Info) of
                %% 物品不存在
                [] -> 
                    [2, 0, 0, [], 0];
                [{info, GoodsInfo}] ->
                    AttributeList = data_goods:get_goods_attribute(GoodsInfo),
                    [1, GoodsInfo#goods.prefix, GoodsInfo#goods.stren, AttributeList, GoodsInfo#goods.bind]
            end
    end.

%% 取宝箱物品
get_one(PlayerStatus, GoodsTypeId) ->
    BoxBag = lib_box:get_box_bag(PlayerStatus),
    case lists:keyfind(GoodsTypeId, 1, BoxBag) of
        %% 物品不存在
        false -> 
            [PlayerStatus, 2];
        Info ->
            case get_goods(Info) of
                [] -> 
                    [PlayerStatus, 2] ;
                GoodsList ->
                    NewBoxBag = lists:delete(Info, BoxBag),
                    G = PlayerStatus#player_status.goods,
                    case gen:call(G#status_goods.goods_pid, '$gen_call', {'box_get', PlayerStatus, GoodsList, NewBoxBag}) of
                        {ok, {fail, Res}} -> 
                            [PlayerStatus, Res];
                        {ok, {ok, NewPlayerStatus}} ->
                            lib_player:refresh_client(PlayerStatus#player_status.id, 2),
                            [NewPlayerStatus, 1];
                        _ -> [PlayerStatus, 0]
                    end
            end
    end.

%% 取宝箱全部物品
get_all(PlayerStatus) ->
    BoxBag = lib_box:get_box_bag(PlayerStatus),
    case length(BoxBag) =:= 0 of
        %% 物品不存在
        true -> 
            [PlayerStatus, 2];
        false ->
            GoodsList = lists:flatmap(fun get_goods/1, BoxBag),
            NewBoxBag = [],
            G = PlayerStatus#player_status.goods,
            case gen:call(G#status_goods.goods_pid, '$gen_call', {'box_get', PlayerStatus, GoodsList, NewBoxBag}) of
                {ok, {fail, Res}} -> 
                    [PlayerStatus, Res];
                {ok, {ok, NewPlayerStatus}} ->
                    lib_player:refresh_client(PlayerStatus#player_status.id, 2),
                    [NewPlayerStatus, 1];
                _ -> [PlayerStatus, 0]
            end
    end.

get_goods({GoodsTypeId, GoodsNum, Bind}) ->
    case data_goods_type:get(GoodsTypeId) of
        [] -> 
            [];
        GoodsTypeInfo ->
            Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
            if  Info#goods.type =:= 10 ->
                    GoodsInfo = Info#goods{num = GoodsNum, bind = Bind, prefix=3};
                true ->
                    GoodsInfo = Info#goods{num = GoodsNum, bind = Bind}
            end,
            [{info, GoodsInfo}]
    end.

filter_notice_list([], L) ->
    L;
filter_notice_list([{GoodsTypeId, GoodsNum, _Bind}|H], L) ->
    filter_notice_list(H, [GoodsTypeId,GoodsNum] ++ L).




