%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-4-14
%% Description: 装备系统
%% --------------------------------------------------------
-module(pp_equip).
-export([handle/3, get_change_info/3, get_fashion_mount/1, qiling_login/1]).
-include("server.hrl").
-include("common.hrl").
-include("buff.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-include("fashion.hrl").
-include("mount.hrl").

%% 装备强化
handle(15400, PlayerStatus, [EquipId, StoneList, LuckyId]) ->
%%二级密码     
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            G = PlayerStatus#player_status.goods,
            case gen:call(G#status_goods.goods_pid, '$gen_call', {'strengthen', PlayerStatus, EquipId, StoneList, LuckyId}) of
                {ok, [NewPlayerStatus, Res, NewGoodsInfo]} ->
                    {ok, BinData} = pt_154:write(15400, [Res, EquipId, NewGoodsInfo#goods.stren, NewGoodsInfo#goods.stren_ratio, NewGoodsInfo#goods.bind, NewPlayerStatus#player_status.coin, NewPlayerStatus#player_status.bcoin]),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
		            lib_task:event(qh, do, NewPlayerStatus#player_status.id),
                    case Res =:= 1 of
                        true ->
                             case NewGoodsInfo#goods.level >= 1 andalso NewGoodsInfo#goods.level =< 45 of
                                true ->
                                    %%  目标：将武器升级到30级101
                                    case NewGoodsInfo#goods.subtype =:= 10 of
                                         true ->
                                             mod_target:trigger(NewPlayerStatus#player_status.status_target, NewPlayerStatus#player_status.id, 101, NewGoodsInfo#goods.level);
                                         false ->
                                             skip
                                     end,
                                    case gen:call(G#status_goods.goods_pid, '$gen_call', {'get_goods_status'}) of
                                        {ok, GoodsStatus1} ->
                                            EquipList1 = lib_goods_util:get_equip_list(NewPlayerStatus#player_status.id,?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP,GoodsStatus1#goods_status.dict),
                                            case length(EquipList1) >= 12 of
                                                true ->
                                                    %%  目标：将所有装备升级到30级以上 302
                                                    Whether302 = lists:foldl(fun(EquipId1,Flag1) ->  (EquipId1#goods.level >= 30) andalso Flag1 end ,true,EquipList1),
                                                    mod_target:trigger(NewPlayerStatus#player_status.status_target, NewPlayerStatus#player_status.id, 302, Whether302);
                                                _ ->
                                                    skip
                                            end;
                                         {'EXIT', _R} ->
                                             skip
                                    end;
                                false ->
                                    skip
                            end, 
                            if 
                                NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                                    case (NewGoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_FASHION orelse NewGoodsInfo#goods.subtype =:= ?GOODS_FASHION_WEAPON orelse NewGoodsInfo#goods.subtype =:= ?GOODS_FASHION_ARMOR orelse NewGoodsInfo#goods.subtype =:= ?GOODS_FASHION_ACCESSORY orelse NewGoodsInfo#goods.subtype =:= ?GOODS_FASHION_HEAD orelse NewGoodsInfo#goods.subtype =:= ?GOODS_FASHION_TAIL orelse NewGoodsInfo#goods.subtype =:= ?GOODS_FASHION_RING) andalso NewGoodsInfo#goods.stren > 0 of
                                        true ->
                                            %% 装备一件强化时装
                                            mod_achieve:trigger_equip(NewPlayerStatus#player_status.achieve, NewPlayerStatus#player_status.id, 7, 0, NewGoodsInfo#goods.stren);
                                        false ->
                                            skip
                                    end,
                                    NewG = NewPlayerStatus#player_status.goods,    
                                    N = lib_goods:get_min_stren7_num2(NewG#status_goods.stren7_num),
                                    if
										N >= 7 ->
											%% 成就：会发光哦，全身装备强化+N以上（不包括时装和坐骑）
											mod_achieve:trigger_equip(NewPlayerStatus#player_status.achieve, NewPlayerStatus#player_status.id,  6, 0, N);
										true ->
									        skip
								   	end,                                  
                                    NewPlayerStatus2 = lib_player:count_player_attribute(NewPlayerStatus),
                                    lib_player:send_attribute_change_notify(NewPlayerStatus2, 1),
                                    {ok, BinDataF} = pt_120:write(12003, NewPlayerStatus2),
			lib_server_send:send_to_area_scene(NewPlayerStatus2#player_status.scene, NewPlayerStatus2#player_status.copy_id, NewPlayerStatus2#player_status.x, NewPlayerStatus2#player_status.y, BinDataF),
                                    {ok, equip, NewPlayerStatus2};
                                true ->
                                    {ok, NewPlayerStatus}
                            end;
                        false -> 
                            {ok, NewPlayerStatus}
                    end;
                {'EXIT',_Reason} -> 
                    util:errlog("handle 15400 error:~p", [_Reason])
            end
    end;

%% 装备分解
handle(15401, PlayerStatus, [GreemList, BlueList, PurpleList]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            G = PlayerStatus#player_status.goods,
            case gen:call(G#status_goods.goods_pid, '$gen_call', {'goods_resolve', PlayerStatus, GreemList, BlueList, PurpleList}) of
                {ok, [NewPlayerStatus, Res, StoneList1, StoneList2, StoneList3, LuckList1, LuckList2, 
                      LuckList3, Reserve1, Reserve2, Reserve3]} ->
                    {ok, BinData} = pt_154:write(15401, [Res, StoneList1, StoneList2, StoneList3, LuckList1, LuckList2, LuckList3, Reserve1, Reserve2, Reserve3]),        
					lib_task:event(fj, do, NewPlayerStatus#player_status.id),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                    lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
                    {ok, NewPlayerStatus};
                {'EXIT',_Reason} -> 
                    util:errlog("handle 15401 error:~p", [_Reason])
            end
    end;

%% 装备升阶
handle(15402, PlayerStatus, [GoodsId, StoneTypeId, PrefixType, StoneList]) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'quality_upgrade', PlayerStatus, GoodsId, StoneTypeId, PrefixType, StoneList}) of
        {ok, [NewPlayerStatus, Res, FirstPrefix, Prefix, Bind, NewStoneNum, NewGoodsInfo]} ->
            %%目标：将任意一件装备的品质提升到精良 504
            mod_target:trigger(NewPlayerStatus#player_status.status_target, NewPlayerStatus#player_status.id, 504, Prefix),
            {ok, BinData} = pt_154:write(15402, [Res, GoodsId, PrefixType, FirstPrefix, Prefix, NewStoneNum, Bind, NewPlayerStatus#player_status.coin, NewPlayerStatus#player_status.bcoin]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            if
                NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                    NewPlayerStatus2 = lib_player:count_player_attribute(NewPlayerStatus),
                    lib_player:send_attribute_change_notify(NewPlayerStatus2, 1),
                    {ok, equip, NewPlayerStatus2};
                true ->
                    {ok, NewPlayerStatus}
            end;
        {'EXIT', _Reason} ->
            util:errlog("handle 15402 error:~p", [_Reason])
    end;

%%装备合成
handle(15405, PlayerStatus, [BlueId, PurpleId1, PurpleId2]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> 
            skip;
        true ->
            G = PlayerStatus#player_status.goods,
            case gen:call(G#status_goods.goods_pid, '$gen_call', {'equip_compose', PlayerStatus, BlueId, PurpleId1, PurpleId2}) of
                {ok, [NewPlayerStatus, Res, GoodsId, Bind, Prefix]} ->
                    {ok, BinData} = pt_154:write(15405, [Res, GoodsId, Bind, Prefix, NewPlayerStatus#player_status.coin, NewPlayerStatus#player_status.bcoin]),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                    {ok, NewPlayerStatus};
                {'EXIT', _Reason} ->
                    util:errlog("handle 15405s error:~p", [_Reason])
            end
    end;

%% 装备精炼
%% StoneList:石头列表
%% ChipList:碎片列表
handle(15406, PlayerStatus, [GoodsId, StoneList, ChipList]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            G = PlayerStatus#player_status.goods,
            case gen:call(G#status_goods.goods_pid, '$gen_call', {'weapon_compose', PlayerStatus, GoodsId, StoneList, ChipList}) of
                {ok, [NewPlayerStatus, Res, NewGoodsInfo]} ->
                    {ok, BinData} = pt_154:write(15406, [Res, NewGoodsInfo#goods.goods_id, NewGoodsInfo#goods.bind, NewGoodsInfo#goods.prefix]),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
                    if
                        NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            NewPlayerStatus2 = lib_player:count_player_attribute(NewPlayerStatus),
                            lib_player:send_attribute_change_notify(NewPlayerStatus2, 1),
                            {ok, equip, NewPlayerStatus2};
                        true ->
                            {ok, NewPlayerStatus}
                    end;
                {'EXIT',_Reason} ->
                    util:errlog("handle 15406 error:~p", [_Reason])
            end
    end;

%% 装备继承
handle(15408, PlayerStatus, [LowId, HighId, StuffList]) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'equip_inherit', PlayerStatus, LowId, HighId, StuffList}) of
        {ok, [NewPlayerStatus, Res, GoodsTypeId, Bind, Prefix, Stren, Flag]} ->
            {ok, BinData} = pt_154:write(15408, [Res, GoodsTypeId, Bind, Prefix, Stren]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            if
                Flag =:= 1 ->
                    NewPlayerStatus2 = lib_player:count_player_attribute(NewPlayerStatus),
                    lib_player:send_attribute_change_notify(NewPlayerStatus, 1),
                    {ok, equip, NewPlayerStatus2};
                true ->
                    {ok, NewPlayerStatus}
            end;
        {'EXIT',_Reason} ->
            skip
    end;

%% 装备升级
handle(15410, PlayerStatus, [GoodsId, RuneId, TripList, StoneList, IronList]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            G = PlayerStatus#player_status.goods,
            case gen:call(G#status_goods.goods_pid, '$gen_call', {'equip_upgrade', PlayerStatus, GoodsId, RuneId, TripList, StoneList, IronList}) of
                {ok, [NewPlayerStatus, Res, NewGoods, Loc]} ->
                    {ok, BinData} = pt_154:write(15410, [Res, NewGoods#goods.goods_id, NewGoods#goods.bind, NewGoods#goods.prefix, NewGoods#goods.stren]),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                    if
                        Loc =:= ?GOODS_LOC_EQUIP ->
                            NewPlayerStatus2 = lib_player:count_player_attribute(NewPlayerStatus),
                            lib_player:send_attribute_change_notify(NewPlayerStatus2, 1),
                            N = lib_goods:get_min_stren7_num2(G#status_goods.stren7_num),
                            NewG = NewPlayerStatus2#player_status.goods,
                            if
                                NewG#status_goods.suit_id > 0 ->
							        %% 成就：碎片达人，装备一套 N级酆都、谪仙或者菩提套装
                                    mod_achieve:trigger_equip(NewPlayerStatus2#player_status.achieve, NewPlayerStatus2#player_status.id, 10, NewG#status_goods.suit_id, NewGoods#goods.level),
                                    %% 成就：红得发紫，装备一套 N级 幽冥、圣法或者释尊套装
                                    mod_achieve:trigger_equip(NewPlayerStatus2#player_status.achieve, NewPlayerStatus2#player_status.id, 12, NewG#status_goods.suit_id, NewGoods#goods.level),
                                    %% 成就：六道轮回，装备一套 N级 橙装
							        mod_achieve:trigger_equip(NewPlayerStatus2#player_status.achieve, NewPlayerStatus2#player_status.id, 13, NewG#status_goods.suit_id, NewGoods#goods.level);
                                N >= 7 ->
                                    %% 成就：会发光哦，全身装备强化+N以上（不包括时装和坐骑）
                                    mod_achieve:trigger_equip(NewPlayerStatus2#player_status.achieve, NewPlayerStatus2#player_status.id,  6, 0, N);
                                true ->
                                    skip
                            end,
                            case NewGoods#goods.subtype =:= 10 andalso NewGoods#goods.color =:= 3 of
                                true ->
                                    %% 成就：神兵，装备一把N级以上的紫色武器
                                    mod_achieve:trigger_equip(NewPlayerStatus2#player_status.achieve, NewPlayerStatus2#player_status.id, 9, 0, NewGoods#goods.level);
                                false ->
                                    skip
                            end,                                   
                            {ok, equip, NewPlayerStatus2};
                        true ->
                            {ok, NewPlayerStatus}
                    end;
                {'EXIT',_Reason} -> 
                    util:errlog("handle 15410 error:~p", [_Reason])
            end
    end;

%% 装备洗炼,洗炼附加属性
handle(15412, PlayerStatus, [GoodsId, Time, Grade, StoneList, LockAttrList]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            Go = PlayerStatus#player_status.goods,
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'attribute_wash', PlayerStatus, GoodsId, Time, Grade, StoneList, LockAttrList}) of
                %% [新玩家字段,洗炼是否成功, 洗炼出来的属性, 新的物品记录]
                {ok, [NewPlayerStatus, Res, AdditionList, NewGoodsInfo]} ->
                     {ok, BinData} = pt_154:write(15412, [Res, Time, GoodsId, NewGoodsInfo#goods.bind, Grade, AdditionList]),
                     lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),       
                    if 
                        Res =:= 1 ->
                            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'get_goods_status'}) of
                                {ok, GoodsStatus1} ->
                                    %%  目标：洗炼属性条超过50条 502
                                    EquipList1 = lib_goods_util:get_equip_list(NewPlayerStatus#player_status.id,?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP,GoodsStatus1#goods_status.dict),
                                    Sum502 = lists:foldl(fun(EquipId1,Sum) ->  length(EquipId1#goods.addition_1)+length(EquipId1#goods.addition_2)+length(EquipId1#goods.addition_3) + Sum end ,0,EquipList1),
                                    mod_target:trigger(NewPlayerStatus#player_status.status_target, NewPlayerStatus#player_status.id, 502, Sum502);
                                 {'EXIT', _R} ->
                                     skip
                            end,
                            %% 目标：洗炼出一条紫色属性 303
                            Whether303 = lists:keymember(3,4,AdditionList) orelse lists:keymember(4,4,AdditionList),
                            mod_target:trigger(NewPlayerStatus#player_status.status_target, NewPlayerStatus#player_status.id, 303, Whether303),
				% lib_task:event(lh, do, NewPlayerStatus#player_status.id),
    %                         	mod_achieve:trigger_equip(NewPlayerStatus#player_status.achieve, NewPlayerStatus#player_status.id, 8, 0, Time),
                            if
                                NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                                    NewPlayerStatus2 = lib_player:count_player_attribute(NewPlayerStatus),
                                    lib_player:send_attribute_change_notify(NewPlayerStatus2, 1),
                                    {ok, equip, NewPlayerStatus2};
                                true ->
                                    {ok, NewPlayerStatus}
                            end;
                        true ->
                            {ok, NewPlayerStatus}
                    end;
                {'EXIT',_Reason} -> 
                    util:errlog("15412 error ~p~n", [_Reason])
            end
    end;

%% 选择洗炼 属性
% handle(15413, PlayerStatus, [GoodsId, Pos]) ->
%     Go = PlayerStatus#player_status.goods,
%     case gen:call(Go#status_goods.goods_pid, '$gen_call', {'attribute_sel', PlayerStatus, GoodsId, Pos}) of
%         {ok, [NewPlayerStatus,Res, NewGoodsInfo]} ->
%             T = data_activity_time:get_activity_time(8),
%             if
%                         Res =:= 1 andalso NewGoodsInfo#goods.subtype =:= ?GOODS_TYPE_EQUIP andalso T =:= true ->
%                             %% 攻击条数
%                             N = lib_wash_gift:get_att_num(NewGoodsInfo#goods.addition, 0),
%                             OldNum = lib_wash_gift:get_old_att(PlayerStatus#player_status.id),
%                             if
%                                 N > OldNum andalso OldNum > 0 ->       %% 更新
%                                     lib_wash_gift:update_wash_gift(PlayerStatus#player_status.id, NewGoodsInfo#goods.id, N, update);
%                                 N > OldNum andalso OldNum =:= 0 ->
%                                     lib_wash_gift:update_wash_gift(PlayerStatus#player_status.id, NewGoodsInfo#goods.id, N, insert);
%                                 true ->
%                                     skip
%                             end;
%                         true ->
%                             skip
%                     end,
%             NewPlayerStatus2 = lib_player:count_player_attribute(NewPlayerStatus),
%             lib_player:send_attribute_change_notify(NewPlayerStatus2, 1),
%             {ok, BinData} = pt_154:write(15413, [Res, GoodsId]),
%             lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
%             {ok, NewPlayerStatus2};
%         {'EXIT',_Reason} -> 
%             util:errlog("15413 error ~p~n", [_Reason])
%     end;

%% 获取洗炼信息
handle(15414, PlayerStatus, GoodsId) ->
    Go = PlayerStatus#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'attribute_get', PlayerStatus, GoodsId}) of
        {ok, [Res,  Addition1, Addition2, Addition3]} ->
            {ok, BinData} = pt_154:write(15414, [Res, Addition1, Addition2, Addition3]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            {ok, PlayerStatus};
        {'EXIT', _Reason} ->
            util:errlog("15414 error ~p~n", [_Reason])
    end;

%% 隐藏时装或挂挂饰 1:隐藏, 0:显示
handle(15415, PlayerStatus, [GoodsId, Show]) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'hide_fashion', PlayerStatus, GoodsId, Show}) of
        {ok, [NewPlayerStatus, Res]} ->
            {ok, BinData} = pt_154:write(15415, [Res]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            lib_player:send_attribute_change_notify(NewPlayerStatus, 1),
            NewGo = NewPlayerStatus#player_status.goods,
            Mount = NewPlayerStatus#player_status.mount,
            %io:format("Res = ~p, ~p~n", [Res, NewGo#status_goods.hide_fashion_accessory]),
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
            {ok, BinDataF} = pt_120:write(12003, NewPlayerStatus),
			lib_server_send:send_to_area_scene(NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.copy_id, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, BinDataF),
            %io:format("pp show = ~p~n", [{NewGo#status_goods.fashion_weapon,
			%											 NewGo#status_goods.fashion_armor, 
			%											 NewGo#status_goods.fashion_accessory, 
			%											 NewGo#status_goods.hide_fashion_weapon, 
			%											 NewGo#status_goods.hide_fashion_armor, 
			%											 NewGo#status_goods.hide_fashion_accessory}]),
            {ok, equip, NewPlayerStatus};
        {'EXIT', _Reason} ->
            util:errlog("handle 15415 error:~p", [_Reason])
    end;

%% 装备进阶
%% StoneList:石头列表
%% ChipList:碎片列表
handle(15416, PlayerStatus, [GoodsId, StoneList, ChipList]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            G = PlayerStatus#player_status.goods,
            case gen:call(G#status_goods.goods_pid, '$gen_call', {'advanced', PlayerStatus, GoodsId, StoneList, ChipList}) of
                {ok, [NewPlayerStatus, Res, NewGoodsInfo]} ->
                    {ok, BinData} = pt_154:write(15416, [Res, NewGoodsInfo#goods.goods_id, NewGoodsInfo#goods.bind, NewGoodsInfo#goods.prefix]),
                    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
                    if
                        NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            NewPlayerStatus2 = lib_player:count_player_attribute(NewPlayerStatus),
                            lib_player:send_attribute_change_notify(NewPlayerStatus2, 1),
                            N = lib_goods:get_min_stren7_num2(G#status_goods.stren7_num),
                            NewG = NewPlayerStatus2#player_status.goods,
                            if
                                NewG#status_goods.suit_id > 0 ->
							        %% 成就：碎片达人，装备一套 N级酆都、谪仙或者菩提套装
                                    mod_achieve:trigger_equip(NewPlayerStatus2#player_status.achieve, NewPlayerStatus2#player_status.id, 10, NewG#status_goods.suit_id, NewGoodsInfo#goods.level),
                                    %% 成就：红得发紫，装备一套 N级 幽冥、圣法或者释尊套装
                                    mod_achieve:trigger_equip(NewPlayerStatus2#player_status.achieve, NewPlayerStatus2#player_status.id, 12, NewG#status_goods.suit_id, NewGoodsInfo#goods.level),
                                    %% 成就：六道轮回，装备一套 N级 橙装
							        mod_achieve:trigger_equip(NewPlayerStatus2#player_status.achieve, NewPlayerStatus2#player_status.id, 13, NewG#status_goods.suit_id, NewGoodsInfo#goods.level);
                                N >= 7 ->
                                    %% 成就：会发光哦，全身装备强化+N以上（不包括时装和坐骑）
                                    mod_achieve:trigger_equip(PlayerStatus#player_status.achieve, NewPlayerStatus2#player_status.id,  6, 0, N);
                                true ->
                                    skip
                            end,
                            {ok, equip, NewPlayerStatus2};
                        true ->
                            {ok, NewPlayerStatus}
                    end;
                {'EXIT',_Reason} ->
                    util:errlog("handle 15416 error:~p", [_Reason])
            end
    end;

%% 取变换信息
handle(15417, PlayerStatus, change_info) ->
    G = PlayerStatus#player_status.goods,
    case gen:call(G#status_goods.goods_pid, '$gen_call', {'get_goods_status'}) of
        {ok, GoodsStatus} ->
            GoodsList = lib_goods_util:get_equip_list(PlayerStatus#player_status.id, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, GoodsStatus#goods_status.dict),
            List1 = get_change_info(PlayerStatus#player_status.change_dict, 1, GoodsList),
            List2 = get_change_info(PlayerStatus#player_status.change_dict, 2, GoodsList),
            List3 = get_change_info(PlayerStatus#player_status.change_dict, 3, GoodsList),
            List4 = get_fashion_mount(PlayerStatus),
            List = List1 ++ List2 ++ List3 ++ List4,
            case List of
                [] ->
                    {ok, BinData} = pt_154:write(15417, [2, List]);
                _L ->
                    {ok, BinData} = pt_154:write(15417, [1, List])
            end,
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        {'EXIT', _R} ->
            skip
    end,
    {ok, PlayerStatus};

%% 衣橱列表
handle(15418, PlayerStatus, Pos) ->
    if
        %Pos =/= 1 andalso Pos =/= 2 andalso Pos =/= 3 ->
        Pos =< 0 ->
            Res = 2;
        true ->
            Res = 1
    end,
    case Res =:= 1 of
        true ->
            Dict1 = dict:filter(fun(_Key, [Value]) -> Value#ets_wardrobe.pos > 0 end, PlayerStatus#player_status.wardrobe),
            DictList = dict:to_list(Dict1),
            List = lib_goods_dict:get_list(DictList, []);
        false ->
            List = []
    end,
    %% 身上
    GDict = lib_goods_dict:get_player_dict(PlayerStatus),
	GoodsList = lib_goods_util:get_equip_list(PlayerStatus#player_status.id, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, GDict),
    List2 = get_fashion_info(GoodsList, []),
    %io:format("15418 ~p~n", [{List, List2, PlayerStatus#player_status.wardrobe}]),
    {ok, BinData} = pt_154:write(15418, [Res, List, List2]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    {ok, PlayerStatus};

handle(15419, PlayerStatus, [_Pos, GoodsId]) ->
    case dict:is_key(GoodsId, PlayerStatus#player_status.wardrobe) of
        true ->
            [M] = dict:fetch(GoodsId, PlayerStatus#player_status.wardrobe),
            if
                M#ets_wardrobe.state =:= 2 ->
                    Res = 2;
                true ->
                    Res = 1
            end;
        false ->
            M = #ets_wardrobe{},
            Res = 2
    end,
    case Res =:= 1 of
        true ->
            G = PlayerStatus#player_status.goods,
            case gen:call(G#status_goods.goods_pid, '$gen_call', {'replace_wardrobe', PlayerStatus, M}) of
                {ok, [Result, NewPS]} ->
                    {ok, BinData} = pt_154:write(15419, [Result]),
                    lib_server_send:send_one(NewPS#player_status.socket, BinData),
                    NewGo = NewPS#player_status.goods,
                    Mount = NewPS#player_status.mount,
                    {ok, BinData1} = pt_120:write(12012, [NewPS#player_status.id, NewPS#player_status.platform, NewPS#player_status.server_num, 
														 NewGo#status_goods.equip_current, 
														 NewGo#status_goods.stren7_num, 
														 NewGo#status_goods.suit_id, 
														 NewPS#player_status.hp, 
														 NewPS#player_status.hp_lim, 
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
                    lib_server_send:send_to_area_scene(NewPS#player_status.scene, 
                                                       NewPS#player_status.copy_id,
                                                       NewPS#player_status.x, 
                                                       NewPS#player_status.y, BinData1),
                    {ok, equip, NewPS};
                {'EXIT', _R} ->
                    {ok, PlayerStatus}
            end;
        false ->
            {ok, BinData} = pt_154:write(15419, [Res]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            {ok, PlayerStatus}
    end;

%% 宝石合成
handle(15420, PlayerStatus, [RuneList, StoneTypeId, StoneList, Times, IsRune, PerNum]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            G = PlayerStatus#player_status.goods,
             case gen:call(G#status_goods.goods_pid, '$gen_call', {'compose', PlayerStatus, RuneList, StoneTypeId, StoneList, Times, IsRune, PerNum}) of
                {ok, [NewPlayerStatus, Res, SucNum, FailNum, Cost, GoodsType]} ->
                    {ok, BinData} = pt_154:write(15420, [Res, SucNum, FailNum, Cost, GoodsType]),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                    {ok, NewPlayerStatus};
                {'EXIT',_Reason} -> 
                    util:errlog("handle 15420 error:~p", [_Reason])
            end
    end;

%% 宝石镶嵌
handle(15421, PlayerStatus, [EquipId, StoneId1, RuneId1, StoneId2, RuneId2, StoneId3, RuneId3]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            G = PlayerStatus#player_status.goods,    
            case gen:call(G#status_goods.goods_pid, '$gen_call', {'inlay', PlayerStatus, EquipId, StoneId1, RuneId1, StoneId2, RuneId2, StoneId3, RuneId3}) of
                {ok, [NewPlayerStatus, Res, Stone1Info, Stone2Info, Stone3Info, StoneTypeId, NewGoodsInfo]} ->
                    {ok, BinData} = pt_154:write(15421, [Res, EquipId, StoneTypeId, NewPlayerStatus#player_status.coin, NewGoodsInfo#goods.bind]),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                    %% 触发成就
                    case Res =:= 1 of
                        true ->
                            [_,_,_,_,_,L] = integer_to_list(Stone1Info#goods.goods_id),
                            Level = list_to_integer([L]),
                            mod_achieve:trigger_equip(NewPlayerStatus#player_status.achieve, NewPlayerStatus#player_status.id, 4, Stone1Info#goods.goods_id, Level),
                            if
                                is_record(Stone2Info, goods) =:= true ->
                                    [_,_,_,_,_,L2] = integer_to_list(Stone1Info#goods.goods_id),
                                    Level2 = list_to_integer([L2]),
                                    mod_achieve:trigger_equip(NewPlayerStatus#player_status.achieve, NewPlayerStatus#player_status.id, 4, Stone2Info#goods.goods_id, Level2);
                                is_record(Stone3Info, goods) =:= true ->
                                    [_,_,_,_,_,L3] = integer_to_list(Stone1Info#goods.goods_id),
                                    Level3 = list_to_integer([L3]),
                                    mod_achieve:trigger_equip(NewPlayerStatus#player_status.achieve, NewPlayerStatus#player_status.id, 4, Stone3Info#goods.goods_id, Level3);
                                true ->
                                    skip
                            end,
                            if
                                NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                                    NewPlayerStatus2 = lib_player:count_player_attribute(NewPlayerStatus),
                                    lib_player:send_attribute_change_notify(NewPlayerStatus2, 1),
                                    {ok, equip, NewPlayerStatus2};
                                true ->
                                    {ok, NewPlayerStatus}
                            end;
                        false -> 
                            {ok, NewPlayerStatus}
                    end;
                {'EXIT',_Reason} ->
                    skip
            end
    end;

%% 宝石拆除
handle(15422, PlayerStatus, [EquipId, StonePos1, RuneId1, StonePos2, RuneId2, StonePos3, RuneId3]) ->
     case lib_secondary_password:is_pass(PlayerStatus) of
        false -> skip;
        true ->
            G = PlayerStatus#player_status.goods,                        
           case gen:call(G#status_goods.goods_pid, '$gen_call', {'backout', PlayerStatus, EquipId, StonePos1, RuneId1, StonePos2, RuneId2, StonePos3, RuneId3}) of
                {ok, [NewPlayerStatus, Res, NewGoodsInfo]} ->
                    {ok, BinData} = pt_154:write(15422, [Res, EquipId, NewPlayerStatus#player_status.coin]),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                    if
                        NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            NewPlayerStatus2 = lib_player:count_player_attribute(NewPlayerStatus),
                            lib_player:send_attribute_change_notify(NewPlayerStatus2, 1),
                            {ok, equip, NewPlayerStatus2};
                        true ->
                            {ok, NewPlayerStatus}
                    end;
                {'EXIT',_Reason} ->
                    skip
            end
    end;

%% 炼炉合成
handle(15430, PlayerStatus, [Id, Num, Flag]) ->
    case lib_secondary_password:is_pass(PlayerStatus) of
        false -> 
            skip;
        true ->
            Go = PlayerStatus#player_status.goods,
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'forge', PlayerStatus, Id, Num, Flag}) of
                {ok, [NewPlayerStatus, Res, Notice]} ->
                    {ok, BinData} = pt_154:write(15430, [Res, Id, Num, Notice]),
                    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                    {ok, NewPlayerStatus};
                {'EXIT',_Reason} -> 
                    skip
            end
    end;

%% 注灵
handle(15435, PlayerStatus, GoodsId) ->
    Go = PlayerStatus#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'add_reiki', PlayerStatus, GoodsId}) of
        {ok, [Res, NewPlayerStatus, NewGoodsInfo]} ->
            Level = NewGoodsInfo#goods.reiki_level,
            if
                NewGoodsInfo#goods.reiki_value =/= [] ->
                    [Type, Value] = NewGoodsInfo#goods.reiki_value;
                true ->
                    [Type, Value] = [0,0]
            end,
            {ok, BinData} = pt_154:write(15435, [Res, Level, Type, Value]),
            %io:format("15435, ~p~n", [{Res, Level, Type, Value}]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            lib_player:send_attribute_change_notify(NewPlayerStatus, 1),
            {ok, NewPlayerStatus};
        {'EXIT', _R} ->
            skip
    end;

%% 提升器灵
handle(15436, PlayerStatus, GoodsId) ->
    Go = PlayerStatus#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'qi_reiki', PlayerStatus, GoodsId}) of
        {ok, [Res, NewPlayerStatus, NewGoodsInfo]} ->
            Level = NewGoodsInfo#goods.reiki_level,
            [Type, Value] = NewGoodsInfo#goods.reiki_value,
            {ok, BinData} = pt_154:write(15436, [Res, Level, Type, Value]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            {ok, NewPlayerStatus};
        {'EXIT', _R} ->
            skip
    end;

%% 获取注灵信息
handle(15437, PlayerStatus, GoodsId) ->
    Go = PlayerStatus#player_status.goods,
    case gen:call(Go#status_goods.goods_pid, '$gen_call', {'get_reiki', PlayerStatus, GoodsId}) of
        {ok, [Res, Level, QiLevel]} ->
            {ok, BinData} = pt_154:write(15437, [Res, Level, QiLevel]),
            %io:format("15437, ~p~n", [{GoodsId, Res, Level, QiLevel}]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            {ok, PlayerStatus};
        {'EXIT', _R} ->
            skip
    end;

handle(15440, PlayerStatus, wash_gift) ->
    AllList = lib_wash_gift:get_gift_id(5), 
    [GetList, GiveList] = lib_wash_gift:get_wash_gift_list(PlayerStatus#player_status.id),
    %io:format("GetList, GiveList = ~p~n", [{GetList, GiveList, AllList}]),
    List = lib_wash_gift:check_giftid_status(AllList, GetList, GiveList, []),
    {ok, BinData} = pt_154:write(15440, [1, List]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    {ok, PlayerStatus};

%% 领取礼包
handle(15441, PlayerStatus, GiftId) ->
    case lib_wash_gift:check_get_gift(PlayerStatus, GiftId) of
        {fail, Res} ->
            {ok, BinData} = pt_154:write(15441, [Res, GiftId]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
        {ok, Id, List} ->
            G = PlayerStatus#player_status.goods,
			case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PlayerStatus, Id}) of
				{ok, [ok, NewPS]} ->
                    {ok, BinData} = pt_154:write(15441, [1, Id]),
                    lib_server_send:send_to_sid(NewPS#player_status.sid, BinData),
                    lib_wash_gift:update_get_gift(NewPS#player_status.id, Id, List),
                    {ok, NewPS};
                {ok, [error, ErrorCode]} ->
                    {ok, BinData} = pt_154:write(15441, [ErrorCode, Id]),
					lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
                    {ok, PlayerStatus}
            end
    end;

%% 器灵激活
handle(15442, PlayerStatus, Date) ->
	[TypeId] = Date,
    Go = PlayerStatus#player_status.goods,
	case TypeId > 0 andalso TypeId < 99 of
		true ->
			case gen_server:call(Go#status_goods.goods_pid,{'delete_more', 601401, 70}) of
		        1 ->
					NewPS = syn_qiling(PlayerStatus, 601401, TypeId),
					%% 不需要计算属性
					mod_scene_agent:update(qiling_figure, NewPS), 
					{ok, BinDataF} = pt_120:write(12003, NewPS),
					lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, NewPS#player_status.x, NewPS#player_status.y, BinDataF),
					{ok, BinDataPs} = pt_130:write(13001, NewPS),
					lib_server_send:send_to_sid(NewPS#player_status.sid, BinDataPs),
					{ok, BinData} = pt_154:write(15442, [601401 * 100 + TypeId, 1]),
					lib_server_send:send_to_sid(NewPS#player_status.sid, BinData),
					{ok, NewPS};
		        _->
					{ok, BinData} = pt_154:write(15442, [0, 2]),
					lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
		    end;
		_ ->
			ok
	end;

handle(Cmd, _PlayerStatus, _) ->
    ?INFO("pp_goods no match ~p~n", [Cmd]),
    {error, "pp_goods no match"}.
        
%% 取坐骑的时装变幻信息
get_fashion_mount(PlayerStatus) ->
    Mount = PlayerStatus#player_status.mount,
    M = lib_mount:get_equip_mount(PlayerStatus#player_status.id, Mount#status_mount.mount_dict),
    Dict = PlayerStatus#player_status.change_dict,
    case is_record(M, ets_mount) of
        true ->
            Key = M#ets_mount.id,
            case dict:is_key(Key, Dict) of
                true ->
                    [Change] = dict:fetch(Key, Dict),
                    [{4, Change#ets_change.new_id, Change#ets_change.time}];
                false ->
                    []
            end;
        false ->
            []
    end.

%% 取时装变幻信息
get_change_info(Dict, Pos, GoodsList) ->                        
    GoodsId = lib_fashion_change:get_fashion_id(GoodsList, Pos),
    case dict:is_key(GoodsId, Dict) of
        true ->
            [Change] = dict:fetch(GoodsId, Dict),
            [{Pos, Change#ets_change.new_id, Change#ets_change.time}];
        false ->
            []
    end.

get_fashion_info([], L) ->
    L;
get_fashion_info([GoodsInfo|T], L) ->
    if
        GoodsInfo#goods.subtype =:= ?GOODS_FASHION_ARMOR orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_WEAPON orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_ACCESSORY orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_HEAD orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_TAIL orelse GoodsInfo#goods.subtype =:= ?GOODS_FASHION_RING ->
            get_fashion_info(T, [GoodsInfo#goods.goods_id | L]);
        true ->
            get_fashion_info(T, L)
    end.

%%get_fashion_info([], _) ->
%%    #goods{};
%%get_fashion_info([GoodsInfo|T], Pos) ->
%%    case Pos of
%%        1 ->
%%            if
%%                GoodsInfo#goods.subtype =:= ?GOODS_FASHION_ARMOR ->
%%                    GoodsInfo;
%%                true ->
%%                    get_fashion_info(T, Pos)
%%            end;
%%        2 ->
%%            if
%%                GoodsInfo#goods.subtype =:= ?GOODS_FASHION_WEAPON ->
%%                    GoodsInfo;
%%                true ->
%%                    get_fashion_info(T, Pos)
%%            end;
%%        3 ->
%%            if
%%                GoodsInfo#goods.subtype =:= ?GOODS_FASHION_ACCESSORY ->
%%                    GoodsInfo;
%%                true ->
%%                    get_fashion_info(T, Pos)
%%            end;
%%        _ ->
%%            get_fashion_info(T, Pos)
%%    end.


syn_qiling(Ps, GTypeId, CTypeId) ->
	TypeId = GTypeId * 100 + CTypeId,
	NewPlayerStatusF = Ps#player_status{qiling = TypeId},
	NowTime = util:unixtime(),
	Ftime = NowTime + 60 * 60 * 24 * 7,
    NewBuffInfo = case lib_buff:match_three(NewPlayerStatusF#player_status.player_buff, 98, 98, []) of
  	%NewBuffInfo = case lib_player:get_player_buff(NewPlayerStatusF#player_status.id, 98, 98) of
 	 	[] -> 
			lib_player:add_player_buff(NewPlayerStatusF#player_status.id
										, 98
										, TypeId
										, 98
										, TypeId	%% Value
										, Ftime
										, []);
  		[BuffInfo] -> %% 重置为新的形象
			%% 已经有BUFF的处理(规则未完成)
			lib_player:mod_buff(BuffInfo
							   , TypeId
							   , TypeId
							   , Ftime
							   , [])
 	end,
	%% 插入并提示buff改变
	buff_dict:insert_buff(NewBuffInfo),
  	lib_player:send_buff_notice(NewPlayerStatusF, [NewBuffInfo]),
	NewPlayerStatusF.


%% 器灵登录处理
qiling_login(PS)->
	NowTime = util:unixtime(),
    Sql2 = io_lib:format(<<"select end_time, goods_id from `buff` where `pid`=~p and `type`=~p">>, [PS#player_status.id, 98]),
    case db:get_row(Sql2) of
        [ETime, TypeGoodId]  -> 
			case ETime > NowTime of
				true ->
					NewPlayerStatusF = PS#player_status{qiling = TypeGoodId},
					mod_scene_agent:update(qiling_figure, NewPlayerStatusF),
					NewPlayerStatusF;
				false ->
%% 					io:format("QL_ ERROR 2~p~n", [PS#player_status.id]),
					PS
			end;
		_->
			PS
    end.
