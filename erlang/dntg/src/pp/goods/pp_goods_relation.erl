%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-9-25
%% Description: 临时背包
%% --------------------------------------------------------
-module(pp_goods_relation).
-compile(export_all).
-include("server.hrl").
-include("goods.hrl").

%% 取临时背包物品列表
handle(15500, PlayerStatus, temp_list) ->
    List = lib_temp_bag:get_temp_list(PlayerStatus),
    {ok, BinData} = pt_155:write(15500, [1, List]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    {ok, PlayerStatus};

%% 取单个
handle(15501, PlayerStatus, Id) ->
    {Res, Temp} = lib_temp_bag:get_one_temp_goods(Id, PlayerStatus),
    if
        Res =:= 1 ->
            G = PlayerStatus#player_status.goods,
            GoodsList = [{goods, Temp#temp_bag.goods_id, Temp#temp_bag.num, Temp#temp_bag.prefix, Temp#temp_bag.stren, Temp#temp_bag.bind}],
		    case gen:call(G#status_goods.goods_pid, '$gen_call', {'give_more', PlayerStatus, GoodsList}) of
                {ok, ok} ->
                    {ok, BinData} = pt_155:write(15501, [Res]),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
                    NewPS = lib_temp_bag:delete_temp_one(PlayerStatus, Id),
                    lib_temp_bag:write_log(NewPS#player_status.id, GoodsList),
                    {ok, NewPS};
                {ok, {fail, Res1}} ->
                    {ok, BinData} = pt_155:write(15501, [Res1]),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
                {'EXITE', _R} ->
                    skip
            end;
        true ->
            {ok, BinData} = pt_155:write(15501, [Res]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData)
    end;

%% 取全部
handle(15502, PlayerStatus, all) ->
    GoodsList = lib_temp_bag:get_all_list(PlayerStatus),
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'give_more', PlayerStatus, GoodsList}) of
        {ok, ok} ->
            {ok, BinData} = pt_155:write(15502, [1]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            NewPS = lib_temp_bag:delete_temp_all(PlayerStatus),
            lib_temp_bag:write_log(NewPS#player_status.id, GoodsList),
            {ok, NewPS};
        {ok, {fail, Res1}} ->
            {ok, BinData} = pt_155:write(15502, [Res1]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {'EXITE', _R} ->
            skip
    end;

%% 物品合并
handle(15503, PlayerStatus, [Type, GoodsId1, GoodsId2]) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'goods_merge', PlayerStatus, [Type, GoodsId1, GoodsId2]}) of
        {ok, Res} ->
            {ok, BinData} = pt_155:write(15503, [Res]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {'EXIT', _R} ->
            skip
    end;    

%% 功勋续期
handle(15504, PlayerStatus, [GoodsId, Days]) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'token_renewal', PlayerStatus, [GoodsId, Days]}) of
        {ok, [Res, NewPS, NewGoodsInfo]} ->
            {ok, BinData} = pt_155:write(15504, [Res, NewGoodsInfo#goods.expire_time]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            lib_player:send_attribute_change_notify(NewPS, 2),
            %% 刷新物品列表
            Dict = lib_goods_dict:get_player_dict(NewPS),
	        GoodsList = lib_goods_util:get_goods_list(PlayerStatus#player_status.id, 1, Dict),
	        {ok, BinData2} = pt_150:write(15010, [1, 0, 
										 NewPS#player_status.bcoin,
										 NewPS#player_status.coin,
										 NewPS#player_status.bgold,
										 NewPS#player_status.gold,
										 NewPS#player_status.point,GoodsList]),
	        lib_server_send:send_one(NewPS#player_status.socket, BinData2),
            {ok, NewPS};
        {'EXIT', _R} ->
            skip
    end;    

%% 功勋升级
handle(15505, PlayerStatus, GoodsId) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'token_upgrade', PlayerStatus, GoodsId}) of
        {ok, [Res, NewPS, NewGoodsInfo]} ->
            {ok, BinData} = pt_155:write(15505, [Res, NewGoodsInfo#goods.goods_id]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            lib_player:send_attribute_change_notify(NewPS, 2),
            %% 刷新物品列表
            Dict = lib_goods_dict:get_player_dict(NewPS),
	        GoodsList = lib_goods_util:get_goods_list(PlayerStatus#player_status.id, 1, Dict),
	        {ok, BinData2} = pt_150:write(15010, [1, 0, 
										 NewPS#player_status.bcoin,
										 NewPS#player_status.coin,
										 NewPS#player_status.bgold,
										 NewPS#player_status.gold,
										 NewPS#player_status.point,GoodsList]),
	        lib_server_send:send_one(NewPS#player_status.socket, BinData2),
            {ok, NewPS};
        {'EXIT', _R} ->
            skip
    end;   

%%使用物品背包武器变性 
handle(15506, PlayerStatus, [GoodsId, EquipId]) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'change_sex_bag', PlayerStatus, [GoodsId, EquipId]}) of
        {ok, [Res, GoodsTypeId]} ->
            %io:format("2222 ~p~n", [{Res, GoodsTypeId}]),
            {ok, BinData} = pt_155:write(15506, [Res, GoodsTypeId]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {'EXIT', _R} ->
            skip
    end;   

%% 更换身上和脚上的光效 Pos:1 身上, 2 脚上  Stren:对应强化数的光效
handle(15507, PlayerStatus, [Pos, Stren]) ->
    case mod_other_call:change_body_effect(PlayerStatus, Pos, Stren) of
        {fail, Res} ->
            {ok, BinData} = pt_155:write(15507, Res),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            {ok, PlayerStatus};
        {ok, NewPS} ->
            {ok, BinData} = pt_155:write(15507, 1),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            {ok, BinDataF} = pt_120:write(12003, NewPS),
			lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, NewPS#player_status.x, NewPS#player_status.y, BinDataF),
            {ok, equip, NewPS}
    end;
    
handle(_Cmd, _PlayerStatus, _) ->
    {error, "pp_goods no match"}.
