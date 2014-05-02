%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-13
%% Description: 物品操作
%% --------------------------------------------------------
-module(pp_goods).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("shop.hrl").
-include("fame.hrl").

%%查询物品详细信息
handle(15000, PlayerStatus, [GoodsId, _Location]) ->
	Go = PlayerStatus#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'info', GoodsId}) of
		{ok, [GoodsInfo, SuitNum, AttributeList]} ->
			{ok, BinData} = pt_150:write_goods_info(15000, [GoodsInfo, SuitNum, AttributeList, PlayerStatus#player_status.base_speed, PlayerStatus#player_status.career]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
		{'EXIT', _Reason} ->
			skip
	end;

%% 查看别人物品信息
handle(15001, PlayerStatus, [RoleId, GoodsId]) ->
    case RoleId =:= PlayerStatus#player_status.id of
        true -> 
            Go = PlayerStatus#player_status.goods,
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'info_other', GoodsId}) of
                {ok, [GoodsInfo, SuitNum, AttriList]} ->
                     {ok, BinData} = pt_150:write_goods_info(15001, [GoodsInfo, SuitNum, AttriList, PlayerStatus#player_status.base_speed, PlayerStatus#player_status.career]),
					lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
				{'EXIT', _Reason} ->
				    skip
			end;
        false ->
	        Ro= lib_player:get_player_info(RoleId, goods_pid),
            case Ro =/= false of
                true ->
	                case is_pid(Ro) of
	                    true ->
			                case gen:call(Ro, '$gen_call', {'info_other', GoodsId}) of
				                {ok, [GoodsInfo, SuitNum, AttriList]} ->
					                {ok, BinData} = pt_150:write_goods_info(15001, [GoodsInfo, SuitNum, AttriList, PlayerStatus#player_status.base_speed]),
					                lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
				                {'EXIT', _Reason} ->
					                util:errlog("15001 call info error ~p ", [_Reason])
			                end;
		                false ->
			                util:errlog("15001 process is not pid ~p~n", [Ro])
	                end;
                _ ->
                    Go = PlayerStatus#player_status.goods,
                    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'info_other', GoodsId}) of
                        {ok, [GoodsInfo, SuitNum, AttriList]} ->
                            {ok, BinData} = pt_150:write_goods_info(15001, [GoodsInfo, SuitNum, AttriList, PlayerStatus#player_status.base_speed]),
					        lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
				        {'EXIT', _Reason} ->
				            skip
                    end
            end
    end;

%% 预览物品信息
handle(15003, PlayerStatus, [GoodsTypeId, Bind, Prefix, Stren]) ->
	[Res, AttriList] = get_info(GoodsTypeId, Bind, Prefix, Stren),
	{ok, BinData} = pt_150:write(15003, [Res, GoodsTypeId, Bind, Prefix, Stren, AttriList]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%% 预览装备洗炼信息
handle(15004, PlayerStatus, GoodsId) ->
    Dict = lib_goods_dict:get_player_dict(PlayerStatus),
	GoodsInfo = lib_goods_util:get_goods(GoodsId, Dict),
	case GoodsInfo =/= [] of
		true ->
			[Res, GoodsTypeId, HasWash, Addition] =
				if 
					%%物品不存在
					is_record(GoodsInfo, goods) =:= false ->
						[2, 0, 0, [], []];
					%% 物品不属于你
					GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
						[3, 0, 0, [], []];
					%% 物品位置不正确
					GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
						[4, 0, 0, [], []];
					%% 物品类型不正确
					GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP andalso GoodsInfo#goods.type =/= ?GOODS_TYPE_MOUNT ->
						[5, 0, 0, [], []];
					true ->
						Addition1 = [{Type, Star, Value, Color, Min, Max} || {Type, Star, Value, Color, Min, Max} <- GoodsInfo#goods.addition_1++GoodsInfo#goods.addition_2++GoodsInfo#goods.addition_3],
               			HasWash1 = case  length(Addition1) > 0 of 
                                       true -> 1; 
                                       false -> 0 
                                   end,
                		[1, GoodsInfo#goods.goods_id, HasWash1, Addition1]
				end,
			{ok, BinData} = pt_150:write(15004, [Res, GoodsId, GoodsTypeId, HasWash, Addition]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
		false ->
			io:format("15004 GoodsInfo is []~n")
	end;

%% 查看物品列表
handle(15010, PlayerStatus, Pos) ->
	if 
		Pos =< 0 -> %装备
			NewPos = ?GOODS_LOC_EQUIP,
			CellNum = 0;
		Pos =:= ?GOODS_LOC_STORAGE -> %仓库
			NewPos = Pos,
			CellNum = PlayerStatus#player_status.storage_num;
		Pos =:= ?GOODS_LOC_BAG -> %背包
			NewPos = Pos,
			CellNum = PlayerStatus#player_status.cell_num;
		true ->
			NewPos = Pos,
			CellNum = 0
	end,
    Dict = lib_goods_dict:get_player_dict(PlayerStatus),
	GoodsList = lib_goods_util:get_goods_list(PlayerStatus#player_status.id, NewPos, Dict),
	{ok, BinData} = pt_150:write(15010, [NewPos, CellNum, 
										 PlayerStatus#player_status.bcoin,
										 PlayerStatus#player_status.coin,
										 PlayerStatus#player_status.bgold,
										 PlayerStatus#player_status.gold,
										 PlayerStatus#player_status.point,GoodsList]),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%%查询别人身上装备列表
handle(15011, PlayerStatus, RoleId) ->
	case RoleId =/= PlayerStatus#player_status.id of
		true ->
            Goods = lib_player:get_player_info(RoleId, goods),
            case Goods =/= false of
                true ->
                    Dict = lib_goods_dict:get_player_dict_by_goods_pid(Goods#status_goods.goods_pid),
                    List = lib_goods_util:get_equip_list(RoleId, Dict),
                    [Res, EquipList] = [?ERRCODE_OK, List],
                        %case List =:= [] of
                        %    true ->
                        %        [1502, []];
                        %    false ->
                        %        [?ERRCODE_OK, List]
                       % end,
            
			        case is_list(EquipList) of
				        true ->
					        {ok, BinData} = pt_150:write(15011, [Res, RoleId, EquipList]);
				        false ->
					        {ok, BinData} = pt_150:write(15011, [0, RoleId, []])
                    end,
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
                false ->
                    {ok, BinData} = pt_150:write(15011, [0, RoleId, []]),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData)
            end;
		false ->
			skip
	end;

%% 获取要修理装备列表
handle(15012, PlayerStatus, mend_list) ->
    G = PlayerStatus#player_status.goods,
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'mend_list'}) of
		{ok, MendList} ->
			{ok, BinData} = pt_150:write(15012, MendList),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
		{'EXIT', _Reason} ->
			util:errlog("15012 get mend list error: ~p~n", [_Reason])
	end;

%% 列出背包打造装备列表
handle(15014, PlayerStatus, make_list) ->
    Dict = lib_goods_dict:get_player_dict(PlayerStatus),
	EquipList = lib_goods_util:get_equip_list(PlayerStatus#player_status.id, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_BAG, Dict),
    MountList = lib_goods_util:get_equip_list(PlayerStatus#player_status.id, ?GOODS_TYPE_MOUNT, ?GOODS_LOC_BAG, Dict),
    {ok, BinData} = pt_150:write(15014, EquipList++MountList),
	lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%% 已领取礼包列表
handle(15016, PlayerStatus, gift_list) ->
    G = PlayerStatus#player_status.goods,
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'gift_list'}) of
		{ok, GiftList} ->
			{ok, BinData} = pt_150:write(15016, GiftList),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
		{'EXIT', _Reason} ->
			util:errlog("15016 get gift list error: ~p~n", [_Reason])
	end;

%% 背包扩展
handle(15022, PlayerStatus, [Type, Num, Gold]) ->
     G = PlayerStatus#player_status.goods,
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'expand_bag',
                PlayerStatus, Type, Num, Gold}) of
        {ok, [Res, NewPlayerStatus]} ->
            {ok, BinData} = pt_150:write(15022, [Res, NewPlayerStatus#player_status.cell_num, NewPlayerStatus#player_status.gold]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            {ok, NewPlayerStatus};
        {'EXIT', _Reason} ->
			util:errlog("15022 expand_bag error: ~p~n", [_Reason])
	end;

%% 装备物品
handle(15030, PlayerStatus, [EquipId, CellPos]) ->
    G = PlayerStatus#player_status.goods,
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'equip', PlayerStatus, EquipId, CellPos}) of
		{ok, [_NewPlayerStatus, Res, GoodsInfo, OldGoodsInfo]} ->
            NewPlayerStatus = lib_gemstone:count_player_attr(_NewPlayerStatus),
			NewG = NewPlayerStatus#player_status.goods,
			case is_record(OldGoodsInfo, goods) of 
				true ->
					 OldGoodsId = OldGoodsInfo#goods.id,
                     OldGoodsTypeId = OldGoodsInfo#goods.goods_id,
                     OldGoodsCell = OldGoodsInfo#goods.cell,
                     OldBind = OldGoodsInfo#goods.bind,
                     OldAttrition = data_goods:count_goods_attrition(OldGoodsInfo#goods.equip_type, 
																	 OldGoodsInfo#goods.attrition, 
																	 OldGoodsInfo#goods.use_num);
				false ->
					 OldGoodsId = 0,
                     OldGoodsTypeId = 0,
                     OldGoodsCell = 0,
                     OldBind = 0,
                     OldAttrition = 0
			end,
			{ok, BinData} = pt_150:write(15030, [Res, EquipId, OldGoodsId, OldGoodsTypeId, 
												OldGoodsCell, OldAttrition, OldBind]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
			lib_player:send_attribute_change_notify(NewPlayerStatus, 2),
            N = lib_goods:get_min_stren7_num2(G#status_goods.stren7_num),
            case Res =:= 1 of
                true ->
                     case GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_FASHION orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_WEAPON orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_ARMOR orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_ACCESSORY orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_HEAD orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_TAIL orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_RING of
                        true ->
                            %% 装备一件时装
                            mod_achieve:trigger_equip(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 0, 0, 1),
                            case GoodsInfo#goods.stren > 0 of
                                true ->
                                    %% 装备一件强化时装
                                    mod_achieve:trigger_equip(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 7, 0, GoodsInfo#goods.stren);
                                false ->
                                    skip
                            end;
                        false ->
                        skip
                    end,
                    case GoodsInfo#goods.subtype =:= 10 andalso GoodsInfo#goods.color =:= 3 of
                        true ->
                        %% 成就：神兵，装备一把N级以上的紫色武器
                            mod_achieve:trigger_equip(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 9, 0, GoodsInfo#goods.level);
                        false ->
                            skip
                    end,
                    case GoodsInfo#goods.subtype =:= 10 andalso GoodsInfo#goods.color =:= 4 of
                        true ->
                            %% 装备一把N级以上的橙色武器
                            mod_achieve:trigger_equip(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 11, 0, GoodsInfo#goods.level);
                        false ->
                            skip
                    end,
					BaseFame = data_fame:get_fame(10501),
                    case is_record(BaseFame, base_fame) andalso lists:member(NewG#status_goods.suit_id, BaseFame#base_fame.target_id) of
                        true ->
                            %% 第一个穿戴紫色套装全部部件
                            mod_fame:trigger(PlayerStatus#player_status.mergetime, PlayerStatus#player_status.id, 5, NewG#status_goods.suit_id, 1);
                        false ->
                            skip
                    end,
                    case lists:member(NewG#status_goods.suit_id, ?ORANGE_ID) of
                        true ->
							skip;
                             %% 暂时屏蔽掉：第一个穿戴橙色装全部部件
%%                             mod_fame:trigger(PlayerStatus#player_status.mergetime, PlayerStatus#player_status.id, 5, NewG#status_goods.suit_id, 1);
                        false ->
                            skip
                    end,
                    %N = lib_goods:get_min_stren7_num2(G#status_goods.stren7_num),
                    if
                        NewG#status_goods.suit_id > 0 ->
							 %% 成就：碎片达人，装备一套 N级酆都、谪仙或者菩提套装
                            mod_achieve:trigger_equip(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 10, NewG#status_goods.suit_id, GoodsInfo#goods.level),
                            %% 成就：红得发紫，装备一套 N级 幽冥、圣法或者释尊套装
                            mod_achieve:trigger_equip(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 12, NewG#status_goods.suit_id, GoodsInfo#goods.level),
                            %% 成就：六道轮回，装备一套 N级 橙装
							mod_achieve:trigger_equip(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 13, NewG#status_goods.suit_id, GoodsInfo#goods.level);
                        N >= 7 ->
                            %% 成就：会发光哦，全身装备强化+N以上（不包括时装和坐骑）
                            mod_achieve:trigger_equip(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id,  6, 0, N);
                        true ->
                            skip
                    end;
                false ->
                    skip
            end,            
            case Res =:= 1 andalso lists:member(GoodsInfo#goods.goods_id,
                    [101101,101201,101301,102101,102201,102301]) =:= true of
                true -> 
                    lib_task:event(equip, {GoodsInfo#goods.goods_id}, NewPlayerStatus#player_status.id);
                false -> 
                    skip
            end,
			%% 气血变化时广播
            NewGo = NewPlayerStatus#player_status.goods,
            Mount = NewPlayerStatus#player_status.mount,
            %io:format("2222 ~p~n", [{NewGo#status_goods.fashion_head, G#status_goods.fashion_head}]),
			case is_record(GoodsInfo, goods) of
				true when NewPlayerStatus#player_status.hp_lim =/= PlayerStatus#player_status.hp_lim
                            orelse NewPlayerStatus#player_status.hp =/= PlayerStatus#player_status.hp
                            orelse NewGo#status_goods.equip_current =/= G#status_goods.equip_current
                            orelse NewGo#status_goods.fashion_weapon =/= G#status_goods.fashion_weapon
                            orelse NewGo#status_goods.fashion_armor =/= G#status_goods.fashion_armor
                            orelse NewGo#status_goods.fashion_accessory =/= G#status_goods.fashion_accessory
                            orelse NewGo#status_goods.fashion_head =/= G#status_goods.fashion_head
                            orelse NewGo#status_goods.fashion_tail =/= G#status_goods.fashion_tail
                            orelse NewGo#status_goods.fashion_ring =/= G#status_goods.fashion_ring
                            orelse NewGo#status_goods.stren7_num =/= G#status_goods.stren7_num
                            orelse NewGo#status_goods.suit_id =/= G#status_goods.suit_id
                            orelse GoodsInfo#goods.subtype =:= 10
                            orelse GoodsInfo#goods.subtype =:= 21 ->
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
                    Sql = io_lib:format(<<"update player_low set body = ~p where id = ~p">>, [N, NewPlayerStatus#player_status.id]),
                    db:execute(Sql),
                    NewPS = NewPlayerStatus#player_status{goods = NewGo#status_goods{body_effect = N}},
                    {ok, BinDataF} = pt_120:write(12003, NewPS),
			        lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, NewPS#player_status.x, NewPS#player_status.y, BinDataF),
                    {ok, equip, NewPS};
				_ ->
					{ok, NewPlayerStatus}
			end;
        {'EXIT',_Reason} -> 
			util:errlog("15030 error:~p~n", [_Reason])
    end;

%% 缷下装备
handle(15031, PlayerStatus, GoodsId) ->
    Go = PlayerStatus#player_status.goods,
	case gen:call(Go#status_goods.goods_pid, '$gen_call', {'unequip', PlayerStatus, GoodsId}) of
		{ok, [_NewPlayerStatus, Res, GoodsInfo]} ->
            NewPlayerStatus = lib_gemstone:count_player_attr(_NewPlayerStatus),
			%% 取物品信息,回复客户端
			case is_record(GoodsInfo, goods) of
				true ->
					TypeId = GoodsInfo#goods.goods_id,
                    Cell = GoodsInfo#goods.cell,
                    Bind = GoodsInfo#goods.bind,
                    Stren = GoodsInfo#goods.stren,
                    Attrition = data_goods:count_goods_attrition(GoodsInfo#goods.equip_type, 
																 GoodsInfo#goods.attrition, 
																 GoodsInfo#goods.use_num);
				false ->
					TypeId = 0,
                    Cell = 0,
                    Bind = 0,
                    Stren = 0,
                    Attrition = 0
			end,
			{ok, BinData} = pt_150:write(15031, [Res, GoodsId, TypeId, Cell, Attrition, Bind, Stren]),
			lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
			lib_player:send_attribute_change_notify(NewPlayerStatus, 2),
			%% 气血有改变则广播
            NewGo = NewPlayerStatus#player_status.goods,
            Mount = NewPlayerStatus#player_status.mount,
			case is_record(GoodsInfo, goods) of
				true when NewPlayerStatus#player_status.hp_lim =/= PlayerStatus#player_status.hp_lim
                            orelse NewPlayerStatus#player_status.hp =/= PlayerStatus#player_status.hp
                            orelse NewGo#status_goods.equip_current =/= Go#status_goods.equip_current
                            orelse NewGo#status_goods.fashion_weapon =/= Go#status_goods.fashion_weapon
                            orelse NewGo#status_goods.fashion_armor =/= Go#status_goods.fashion_armor
                            orelse NewGo#status_goods.fashion_accessory =/= Go#status_goods.fashion_accessory
                            orelse NewGo#status_goods.fashion_head =/= Go#status_goods.fashion_head
                            orelse NewGo#status_goods.fashion_tail =/= Go#status_goods.fashion_tail
                            orelse NewGo#status_goods.fashion_ring =/= Go#status_goods.fashion_ring
                            orelse NewGo#status_goods.stren7_num =/= Go#status_goods.stren7_num
                            orelse NewGo#status_goods.suit_id =/= Go#status_goods.suit_id
                            orelse GoodsInfo#goods.subtype =:= 10
                            orelse GoodsInfo#goods.subtype =:= 21 ->
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
                    lib_server_send:send_to_area_scene(PlayerStatus#player_status.scene, 
                                                        NewPlayerStatus#player_status.copy_id,
                                                        PlayerStatus#player_status.x, 
                                                        PlayerStatus#player_status.y, BinData1),

                    N = lib_goods:get_min_stren7_num2(NewGo#status_goods.stren7_num),
                    if
                        GoodsInfo#goods.subtype =:= 10 ->
                            Feet = 0;
                        true ->
                            Feet = NewGo#status_goods.feet_effect
                    end,
                    Sql = io_lib:format(<<"update player_low set body = ~p, feet=~p where id = ~p">>, [N, Feet, NewPlayerStatus#player_status.id]),
                    db:execute(Sql),
                    NewPS = NewPlayerStatus#player_status{goods = NewGo#status_goods{body_effect = N, feet_effect = Feet}},
                    {ok, BinDataF} = pt_120:write(12003, NewPS),
			        lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, NewPS#player_status.x, NewPS#player_status.y, BinDataF),
                    {ok, equip, NewPS};
				_ ->
					{ok, NewPlayerStatus}
            end;
        {'EXIT',_Reason} -> 
			util:errlog("15031 error: ~p~n", [_Reason])
	end;

%% 修理装备
handle(15033, PlayerStatus, GoodsId) ->
    G = PlayerStatus#player_status.goods,
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'mend', PlayerStatus, GoodsId}) of
		{ok, [NewPlayerStatus, Res, GoodsInfo, Cost]} ->
			{ok, BinData} = pt_150:write(15033, [Res, GoodsId, NewPlayerStatus#player_status.coin,
												 NewPlayerStatus#player_status.bcoin, Cost]),
			lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            if GoodsInfo#goods.location =:= 1 andalso GoodsInfo#goods.use_num =< 0 ->
                    lib_player:send_attribute_change_notify(NewPlayerStatus, 1), 
                    lib_player:refresh_client(NewPlayerStatus#player_status.id, 1);
				true ->
					skip
            end,
			%% 判断气血有没改变,有则广播
			if is_record(GoodsInfo, goods) ->
				   if NewPlayerStatus#player_status.hp_lim =/= PlayerStatus#player_status.hp_lim ->
						  {ok, BinData1} = pt_120:write(12009, [NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.platform, NewPlayerStatus#player_status.server_num, 
														NewPlayerStatus#player_status.hp,NewPlayerStatus#player_status.hp_lim]),
						  lib_server_send:send_to_area_scene(NewPlayerStatus#player_status.scene,
                                                             NewPlayerStatus#player_status.copy_id,
															 NewPlayerStatus#player_status.x,
															 NewPlayerStatus#player_status.y,
                                                             BinData1),
                          {ok, equip, NewPlayerStatus};
					  true ->
                          {ok, NewPlayerStatus}
                  end;
              true ->
                  {ok, NewPlayerStatus}
          end;
		{'EXIT', _Reason} ->
			util:errlog("handle 15033 error:~p", [_Reason])
	end;

%% 修理全部装备
handle(15035, PlayerStatus, mend_all) ->
    G = PlayerStatus#player_status.goods,
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'mend_all', PlayerStatus}) of
		{ok, [NewPlayerStatus, Res, Cost]} ->
			{ok, BinData} = pt_150:write(15035, [Res, NewPlayerStatus#player_status.coin,NewPlayerStatus#player_status.bcoin, Cost]),
			lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            if Res =:= 1 -> %成功
					%刷新客户端
                    lib_player:send_attribute_change_notify(NewPlayerStatus, 1),
					lib_player:refresh_client(NewPlayerStatus#player_status.id, 1);
			   true ->
				   %util:errlog("handle 15035 Res = ~p", [Res])
                   skip
			end,
			%气血改变了就广播
			if NewPlayerStatus#player_status.hp_lim =/= PlayerStatus#player_status.hp_lim ->
				   {ok, BinData1} = pt_120:write(12009, [NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.platform, NewPlayerStatus#player_status.server_num, NewPlayerStatus#player_status.hp,
														 NewPlayerStatus#player_status.hp_lim]),
				   lib_server_send:send_to_area_scene(NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.copy_id, NewPlayerStatus#player_status.x,
													  NewPlayerStatus#player_status.y, BinData1),
                    {ok, equip, NewPlayerStatus};
			   true ->
				   {ok, NewPlayerStatus}
			end;
		{'EXIT', _Reason} ->
			util:errlog("handle 15035 error:~p", [_Reason])
	end;

%%拖动背包物品
handle(15040, PlayerStatus, [GoodsId, OldCell, NewCell]) ->
    G = PlayerStatus#player_status.goods,
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'drag_goods', PlayerStatus, GoodsId,  OldCell, NewCell}) of
		{ok, [Res, NewGoodsInfo1, NewGoodsInfo2]} ->
			{ok, BinData} = pt_150:write(15040, [Res, NewGoodsInfo1, NewGoodsInfo2]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
		{'EXIT', _Reason} ->
			util:errlog("handle 15040 error:~p", [_Reason])
	end;

%% 物品存入仓库
handle(15041, PlayerStatus, [NpcId, GoodsId, Num]) ->
    G = PlayerStatus#player_status.goods,
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'movein_storage', PlayerStatus, NpcId, GoodsId, Num}) of
		{ok, Res} ->
			{ok, BinData} = pt_150:write(15041, [Res, GoodsId, Num]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            if
                Res =:= ?ERRCODE_OK ->
                    lib_task:event(PlayerStatus#player_status.tid, movein_storage, do, PlayerStatus#player_status.id);
                true ->
                    skip
            end;
		{'EXIT', _Reason} ->
			util:errlog("handle 15041 error:~p", [_Reason])
	end;
	
%% 从仓库取出物品
handle(15042, PlayerStatus, [NpcId, GoodsId, Num]) ->
    G = PlayerStatus#player_status.goods,
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'moveout_storage', PlayerStatus, NpcId, GoodsId, Num}) of
		{ok, [Res, GoodsList]} ->
			{ok, BinData} = pt_150:write(15042, [Res, GoodsId, GoodsList]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
		{'EXIT', _Reason} ->
			util:errlog("handle 15042 error:~p", [_Reason])
	end;
		
%% 使用物品
handle(15050, PlayerStatus, [GoodsId, Num]) ->
    G = PlayerStatus#player_status.goods,
	%% 完成特殊使用物品任务
    lib_task:event(PlayerStatus#player_status.tid, use_goods, {PlayerStatus#player_status.scene, PlayerStatus#player_status.x, PlayerStatus#player_status.y, GoodsId}, PlayerStatus#player_status.id),
	case gen:call(G#status_goods.goods_pid, '$gen_call', {'use_goods', PlayerStatus, GoodsId, Num}) of
		{ok, [NewPlayerStatus, Res, GoodsInfo, NewNum, _GoodsList]} ->
			{ok, BinData} = pt_150:write(15050, [Res, GoodsId, GoodsInfo#goods.goods_id, NewNum, NewPlayerStatus#player_status.hp, NewPlayerStatus#player_status.mp]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),           
            lib_player:send_attribute_change_notify(NewPlayerStatus, 1),
            if
                GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_ARMOR_CHA orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_WEAPON_CHA orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_ACCE_CHA orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_MOUTN_FIGURE orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_HEAD_CHA orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_TAIL_CHA orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_RING_CHA ->
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
                Dict = lib_goods_dict:get_player_dict(NewPlayerStatus),
	            GoodsList1 = lib_goods_util:get_goods_list(NewPlayerStatus#player_status.id, ?GOODS_LOC_EQUIP, Dict),
	            {ok, BinData2} = pt_150:write(15010, [?GOODS_LOC_EQUIP, 0, 
										 NewPlayerStatus#player_status.bcoin,
										 NewPlayerStatus#player_status.coin,
										 NewPlayerStatus#player_status.bgold,
										 NewPlayerStatus#player_status.gold,
										 NewPlayerStatus#player_status.point,GoodsList1]),
	            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData2),
                if
                    GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_MOUTN_FIGURE ->
                        {ok, BinData3} = pt_120:write(12010, [NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.platform, NewPlayerStatus#player_status.server_num, NewPlayerStatus#player_status.speed, Mount#status_mount.mount_figure]),
                        lib_server_send:send_to_area_scene(NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.copy_id, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, BinData3),
                        MountList = lib_mount:get_mount_list(NewPlayerStatus#player_status.id, Mount#status_mount.mount_dict),
                        {ok, BinData4} = pt_160:write(16000, [Mount#status_mount.mount_lim, MountList]),
                        lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData4),
                        {ok, mount, NewPlayerStatus};
                    true ->
                        {ok, equip, NewPlayerStatus}
                end;
            true ->
                Vip = PlayerStatus#player_status.vip,
                NewVip = NewPlayerStatus#player_status.vip,
			    case Vip#status_vip.vip_type =/= NewVip#status_vip.vip_type
                    orelse Vip#status_vip.vip_end_time =/= NewVip#status_vip.vip_end_time 
                    orelse PlayerStatus#player_status.hp =/= NewPlayerStatus#player_status.hp
                    orelse PlayerStatus#player_status.hp_lim =/= NewPlayerStatus#player_status.hp_lim
                    orelse PlayerStatus#player_status.mp =/= NewPlayerStatus#player_status.mp
                    orelse PlayerStatus#player_status.mp_lim =/= NewPlayerStatus#player_status.mp_lim
                    orelse PlayerStatus#player_status.sex =/= NewPlayerStatus#player_status.sex of
                    true -> 
                        {ok, use_goods, NewPlayerStatus};
                    false -> 
                        {ok, NewPlayerStatus}
                end
        end;
        {'EXIT',_Reason} -> 
			util:errlog("handle 15050 error:~p", [_Reason])
	end;
			
%% 销毁物品
handle(15051, PlayerStatus, [GoodsId, Num]) ->
	case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            G = PlayerStatus#player_status.goods,
            case gen:call(G#status_goods.goods_pid, '$gen_call', {'throw', GoodsId, Num}) of
	           {ok, Res} ->
			     {ok, BinData} = pt_150:write(15051, [Res, GoodsId,Num]),
			     lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
	           {'EXIT', _Reason} ->
			     util:errlog("handle 15051 error:~p", [_Reason])
	       end
	end;
					
%%整理背包
handle(15052, PlayerStatus, order) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'order', PlayerStatus}) of
        {ok, GoodsList} ->
            {ok, BinData} = pt_150:write(15052, GoodsList),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {'EXIT', _Reason} ->
			util:errlog("handle 15052 error:~p", [_Reason])
    end;

%% 拣取地上掉落包的物品
handle(15053, PlayerStatus, DropId) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'drop_choose', PlayerStatus, DropId}) of
        {ok, [NewStatus, Res]} ->
            {ok, BinData} = pt_150:write(15053, [Res, DropId]),
            lib_server_send:send_one(NewStatus#player_status.socket, BinData),
            {ok, NewStatus};
        {'EXIT',_Reason} -> 
			util:errlog("handle 15053 error:~p", [_Reason])
    end;

%% 拆分物品
handle(15054, PlayerStatus, [GoodsId, Num]) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'split', GoodsId, Num}) of
        {ok, [Res, GoodsInfo]} ->
            {ok, BinData} = pt_150:write(15054, [Res, GoodsId, GoodsInfo]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {'EXIT', _Reason} ->
			util:errlog("handle 15054 error:~p", [_Reason])
    end;

%% 在线礼包领取
handle(15082, PlayerStatus, GiftId) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'online_gift', PlayerStatus, GiftId}) of
        {ok, [NewPlayerStatus, Res]} ->
            {ok, BinData} = pt_150:write(15082, [Res, GiftId]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            lib_gift:send_gift_notice(NewPlayerStatus),
            {ok, NewPlayerStatus};
        {'EXIT',_Reason} -> 
            util:errlog("handle 15082 error:~p", [_Reason])
    end;

%% NPC礼包领取
handle(15083, PlayerStatus, [GiftId, Card]) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'npc_gift', PlayerStatus, GiftId, Card}) of
        {ok, [NewPlayerStatus, Res]} ->
            {ok, BinData} = pt_150:write(15083, [Res, GiftId]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            {ok, NewPlayerStatus};
        {'EXIT',_Reason} -> 
            util:errlog("handle 15083 error:~p", [_Reason])
    end;

%% NPC兑换物品
handle(15084, PlayerStatus, [NpcTypeId, ExchangeId, ExchangeNum]) ->
    io:format("15084:~p~n",[[NpcTypeId, ExchangeId, ExchangeNum]]),
   case util:check_kfz() of
       false ->
            G = PlayerStatus#player_status.goods,
            case gen:call(G#status_goods.goods_pid, '$gen_call', {'npc_exchange', PlayerStatus, NpcTypeId, ExchangeId, ExchangeNum}) of
                {ok, [NewPlayerStatus, Res, RemainNum]} ->
                    {ok, BinData} = pt_150:write(15084, [Res, NpcTypeId, ExchangeId, RemainNum]),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                    lib_player:send_attribute_change_notify(NewPlayerStatus, 1),
                    {ok, NewPlayerStatus};
                {'EXIT',_Reason} -> 
                    util:errlog("handle 15084 error:~p", [_Reason])
            end;
        true -> 
            skip
    end;

%% 使用替身娃娃完成任务
handle(15102, PlayerStatus, TaskId) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'finish_task', PlayerStatus, TaskId}) of
        {ok, [Res]} ->
            {ok, BinData} = pt_151:write(15102, [Res, TaskId]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {'EXIT',_Reason} -> 
            util:errlog("handle 15102 error:~p", [_Reason])
    end;

%% 送东西
handle(15103, PlayerStatus, [Type, SubType, PlayerId]) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'send_gift', PlayerStatus, Type, SubType, PlayerId}) of
        {ok, [NewPlayerStatus, Res]} ->
            {ok, BinData} = pt_151:write(15103, [Res, Type, SubType, PlayerId]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            {ok, NewPlayerStatus};
        {'EXIT',_Reason} -> 
            util:errlog("handle 15103 error:~p", [_Reason])
    end;

%% 幸运转盘
handle(15104, PlayerStatus, GoodsId) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'lucky_box', PlayerStatus, GoodsId}) of
        {ok, [Res, Goods_id]} ->
            {ok, BinData} = pt_151:write(15104, [Res, Goods_id]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {'EXIT',_Reason} -> 
            util:errlog("handle 15104 error:~p", [_Reason])
    end;

handle(_Cmd, _Status, _Data) ->
    ?INFO("pp_goods no match", []),
    {error, "pp_goods no match"}.

%% ---------------------- private ---------------------------------------------------
get_info(GoodsTypeId, _Bind, _Prefix, _Stren) ->
	case data_goods_type:get(GoodsTypeId) of
		[] ->
			[2, []]; %物品不存在
		GoodsTypeInfo ->
			Info = lib_goods_util:get_new_goods(GoodsTypeInfo),
			GoodsInfo = Info#goods{bind = _Bind, prefix = _Prefix, stren = _Stren},
			AttriList = data_goods:get_goods_attribute(GoodsInfo),
			[1, AttriList]
	end.


