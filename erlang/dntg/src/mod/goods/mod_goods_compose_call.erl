%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-1-9
%% Description: 物品合成,洗炼,强化等call
%% --------------------------------------------------------
-module(mod_goods_compose_call).
-export([handle_call/3]).
-include("goods.hrl").
-include("common.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("errcode_goods.hrl").
-include("server.hrl").
-include("mount.hrl").

%% 装备品质升级
handle_call({'quality_upgrade', PlayerStatus, GoodsId, StoneTypeId, PrefixType, StoneList}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_quality_upgrade(PlayerStatus, GoodsId, StoneTypeId, PrefixType, StoneList, GoodsStatus) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, 0, 0, 0, 0, #goods{}], GoodsStatus};
        {ok, GoodsInfo, NewStoneList, GoodsQualityRule} ->
            case lib_goods_compose:quality_upgrade(PlayerStatus, GoodsStatus, GoodsInfo, NewStoneList, GoodsQualityRule, PrefixType) of
                {ok, Res1, NewPlayerStatus, NewStatus, [FirstPrefix, Prefix, Bind, NewStoneNum, NewGoodsInfo]} ->
                    case Res1 =:= 1 andalso NewGoodsInfo#goods.prefix >= 4 andalso NewGoodsInfo#goods.level >= 60 of
                        true ->
                            %% 传闻
                            lib_chat:send_TV({all},0,3, ["pingzhi", 
													1, 
													NewPlayerStatus#player_status.id, 
													NewPlayerStatus#player_status.realm, 
													NewPlayerStatus#player_status.nickname, 
													NewPlayerStatus#player_status.sex, 
													NewPlayerStatus#player_status.career, 
													NewPlayerStatus#player_status.image, 
													GoodsInfo#goods.id, 
													GoodsInfo#goods.goods_id]);
                        false ->
                            skip
                    end,
                    if NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus);
                         true ->
                            NewPlayerStatus2 = NewPlayerStatus
                    end,
                    %%  目标：将任意一件装备进阶到紫色 205
                    mod_target:trigger(NewPlayerStatus2#player_status.status_target, NewPlayerStatus2#player_status.id, 205, NewGoodsInfo#goods.color),
                    {reply, [NewPlayerStatus2, Res1, FirstPrefix, Prefix, Bind, NewStoneNum, NewGoodsInfo], NewStatus};
                Error ->
                    util:errlog("mod_goods quality_upgrade error:~p", [Error]),
                    {reply, [PlayerStatus, 10, 0, 0, 0, #goods{}], GoodsStatus}
            end
    end;

%% 装备强化
handle_call({'strengthen', PlayerStatus, EquipId, StoneId, LuckyId}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_strengthen(PlayerStatus, GoodsStatus, EquipId, StoneId, LuckyId) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, #goods{}], GoodsStatus};
        {ok, GoodsInfo, StoneList, LuckyInfo, LuckyRule, GoodsStrengthenRule, NewGoodsTypeInfo} ->
             case lib_goods_compose:strengthen(PlayerStatus, GoodsStatus, GoodsInfo, StoneList, LuckyInfo, LuckyRule, GoodsStrengthenRule, NewGoodsTypeInfo) of
                {ok, Res1, NewPlayerStatus, NewStatus, NewGoodsInfo} -> 
                    %%强化到7发送传闻
                    %if  Res1 =:= 1 andalso NewGoodsInfo#goods.stren >= 7 ->
                    %       lib_chat:send_TV({all},0,3, ["qianghua", 
                    %   						   1, 
                    %   						   NewPlayerStatus#player_status.id, 
                    %   						   NewPlayerStatus#player_status.realm, 
                    %   						   NewPlayerStatus#player_status.nickname, 
                    %   						   NewPlayerStatus#player_status.sex, 
                    %   						   NewPlayerStatus#player_status.career, 
                    %   						   NewPlayerStatus#player_status.image, 
                    %   						   NewGoodsInfo#goods.id, 
                    %   						   NewGoodsInfo#goods.goods_id, 
                    %   						   NewGoodsInfo#goods.stren]);
                    %       %lib_cw:send_cw_stren(NewPlayerStatus, NewGoodsInfo);
                    %    true -> skip
                    %end,
                    case NewGoodsInfo#goods.equip_type =:= 1 andalso Res1 =:= 1 of %% 武器目标
                        true ->
                            %% 第一个将武器强化到7级
                            case NewGoodsInfo#goods.stren >= 7 of
                                true ->
                                    mod_fame:trigger(NewPlayerStatus#player_status.mergetime, NewPlayerStatus#player_status.id, 4, 0, NewGoodsInfo#goods.stren); 
                                false ->
                                    skip
                            end;
                        false ->
                            skip
                    end,
                    %% add by xieyunfei target 105                            
                    EquipList = lib_goods_util:get_equip_list(NewPlayerStatus#player_status.id, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, GoodsStatus#goods_status.dict),
                    EquipSum = lists:foldl(fun(EquipInfo, Sum) -> EquipInfo#goods.stren + Sum end, 0, EquipList),
                    %% 目标：将强化总等级提升到20级 105
                    mod_target:trigger(NewPlayerStatus#player_status.status_target, NewPlayerStatus#player_status.id, 105, EquipSum),
                    %% 目标：将强化总等级提升到40级 204
                    mod_target:trigger(NewPlayerStatus#player_status.status_target, NewPlayerStatus#player_status.id, 204, EquipSum),
                    %% 目标：强化总等级200级以上 503
                    mod_target:trigger(NewPlayerStatus#player_status.status_target, NewPlayerStatus#player_status.id, 503, EquipSum),
                    %%io:format("Module:~p Line:~p EquipList:~p EquipSum:~p ~n", [?MODULE,?LINE,EquipList,EquipSum]),
                    if Res1 =:= 1 andalso NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            if
                                NewGoodsInfo#goods.stren >= 7 ->
                                    Stren7_num = lib_goods:add_stren7_num(NewGoodsInfo, NewStatus#goods_status.stren7_num),
                                    NewStatus2 = NewStatus#goods_status{stren7_num = Stren7_num};
                                true ->
                                    NewStatus2 = NewStatus
                            end,
                            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus2);
                        true ->
                            NewPlayerStatus2 = NewPlayerStatus,
                            NewStatus2 = NewStatus
                    end,
                    %% 强化后帮派神炉返利
                    lib_guild:put_furnace_back(NewPlayerStatus2, GoodsStrengthenRule#ets_goods_strengthen.coin),
                    {reply, [NewPlayerStatus2, Res1, NewGoodsInfo], NewStatus2};
                Error ->
                    util:errlog("mod_goods strengthen error:~p", [Error]),
                    {reply, [PlayerStatus, 10, #goods{}], GoodsStatus}
            end
    end;

%% 装备分解
handle_call({'goods_resolve', PlayerStatus, GreemList, BlueList, PurpleList}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_goods_resolve(PlayerStatus, GreemList, BlueList, PurpleList, GoodsStatus) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, [], [], [], [], [], [], [], [], []], GoodsStatus};
        {ok, NewGreamList, GreamRule, NewBlueList, BlueRule, NewPurpleList, PurpleRule, Cost} ->
            case lib_goods_compose:goods_resolve(PlayerStatus, GoodsStatus, NewGreamList, GreamRule, NewBlueList, BlueRule, NewPurpleList, PurpleRule, Cost) of
                 {ok, NewPlayerStatus, NewGoodsStatus, StoneList1, StoneList2, StoneList3, 
                  LuckList1, LuckList2, LuckList3, Reserve1, Reserve2, Reserve3} ->
                     {reply, [NewPlayerStatus, 1, StoneList1, StoneList2, StoneList3, LuckList1, 
                              LuckList2, LuckList3, Reserve1, Reserve2, Reserve3], NewGoodsStatus};
                 Error ->
                     util:errlog("mod_goods goods_resolve error:~p", [Error]),
                     {reply, [PlayerStatus, 10, [], [], [], [], [], [], [], [], []], GoodsStatus}
            end;
        _Error ->
            skip
            %io:format("Error = ~p~n", [Error])
    end;

%% 装备合成
handle_call({'equip_compose', PlayerStatus, BlueId, PurpleId1, PurpleId2}, _From, GoodsStatus) ->
    case lib_goods_compose_check:equip_compose_check(PlayerStatus, BlueId, PurpleId1, PurpleId2, GoodsStatus) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, 0, 0, 0], GoodsStatus};
        {ok, GoodsTypeInfo, BlueInfo, PurpleInfo1, PurpleInfo2} ->
            case lib_goods_compose:equip_compose(PlayerStatus, GoodsStatus, GoodsTypeInfo, BlueInfo, PurpleInfo1, PurpleInfo2) of
                {ok, NewPlayerStatus, NewStatus, NewGoodsInfo} ->
                    {reply, [NewPlayerStatus, 1, NewGoodsInfo#goods.goods_id, NewGoodsInfo#goods.bind, NewGoodsInfo#goods.prefix], NewStatus};
                _Error ->
                     {reply, [PlayerStatus, 10, 0, 0, 0], GoodsStatus}
            end
    end;

%% 装备精炼 
%% StoneList:石头列表
%% ChipList:碎片列表
handle_call({'weapon_compose', PlayerStatus, GoodsId, StoneList, ChipList}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_weapon_compose(PlayerStatus, GoodsStatus, GoodsId, StoneList, ChipList) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, #goods{}], GoodsStatus};
        {ok, GoodsTypeInfo, GoodsInfo, RuleInfo, NewStoneList, NewChipList} ->
            case lib_goods_compose:weapon_compose(PlayerStatus, GoodsStatus, GoodsTypeInfo, GoodsInfo, RuleInfo, NewStoneList, NewChipList) of
                {ok, NewPlayerStatus, NewStatus, NewGoodsInfo} ->
                    %% 传闻
                    lib_chat:send_TV({all},0,3, ["jinglian", 
											1, 
											NewPlayerStatus#player_status.id, 
											NewPlayerStatus#player_status.realm, 
											NewPlayerStatus#player_status.nickname, 
											NewPlayerStatus#player_status.sex, 
											NewPlayerStatus#player_status.career, 
											NewPlayerStatus#player_status.image, 
											NewGoodsInfo#goods.id, 
											NewGoodsInfo#goods.goods_id]),
                    if
                        NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus);
                        true ->
                            NewPlayerStatus2 = NewPlayerStatus
                    end,
                     {reply, [NewPlayerStatus2, 1, NewGoodsInfo], NewStatus};
                 Error ->
                     util:errlog("mod_goods weapon_compose error:~p", [Error]),
                     {reply, [PlayerStatus, 10, #goods{}], GoodsStatus}
            end
    end;

%% 装备进阶
handle_call({'advanced', PlayerStatus, GoodsId, StoneList, ChipList}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_equip_advanced(PlayerStatus, GoodsStatus, GoodsId, StoneList, ChipList) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, #goods{}], GoodsStatus};
        {ok, GoodsTypeInfo, GoodsInfo, RuleInfo, NewStoneList, NewChipList} ->
            case lib_goods_compose:equip_advanced(PlayerStatus, GoodsStatus, GoodsTypeInfo, GoodsInfo, RuleInfo, NewStoneList, NewChipList) of
                {ok, NewPlayerStatus, NewStatus, NewGoodsInfo} ->
                    %% 传闻
                    lib_chat:send_TV({all},0,3, ["equipJJ", 
											1, 
											NewPlayerStatus#player_status.id, 
											NewPlayerStatus#player_status.realm, 
											NewPlayerStatus#player_status.nickname, 
											NewPlayerStatus#player_status.sex, 
											NewPlayerStatus#player_status.career, 
											NewPlayerStatus#player_status.image, 
											NewGoodsInfo#goods.id, 
											NewGoodsInfo#goods.goods_id]),
                    if
                        NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus);
                        true ->
                            NewPlayerStatus2 = NewPlayerStatus
                    end,
                     {reply, [NewPlayerStatus2, 1, NewGoodsInfo], NewStatus};
                 Error ->
                     util:errlog("mod_goods advanced error:~p", [Error]),
                     {reply, [PlayerStatus, 10, #goods{}], GoodsStatus}
            end
    end;

%% 装备继承
handle_call({'equip_inherit', PlayerStatus, LowId, HighId, StuffList}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_equip_inherit(PlayerStatus,
            GoodsStatus, LowId, HighId, StuffList) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, 0, 0, 0, 0, 0], GoodsStatus};
        {ok, LowInfo, HighInfo, NewStuffList, InheritRule, Flag, Cost} ->
            case lib_goods_compose:equip_inherit(PlayerStatus, GoodsStatus,
                    LowInfo, HighInfo,NewStuffList, InheritRule, Flag, Cost) of
                {ok, NewPlayerStatus, NewStatus, GoodsTypeId, Bind, Prefix, Stren} ->
                    if
                        LowInfo#goods.location =:= ?GOODS_LOC_EQUIP orelse HighInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus),
                            {reply, [NewPlayerStatus2, 1, GoodsTypeId, Bind, Prefix, Stren, 1], NewStatus};
                        true ->
                            {reply, [NewPlayerStatus, 1, GoodsTypeId, Bind, Prefix, Stren, 0], NewStatus}
                    end;
                 Error ->
                     util:errlog("mod_goods equip_inherit error:~p", [Error]),
                     {reply, [PlayerStatus, 10, 0, 0, 0, 0, 0], GoodsStatus}
            end
    end;

%% 装备升级
handle_call({'equip_upgrade', PlayerStatus, GoodsId, RuneId, TripList, StoneList, IronList}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_equip_upgrade(PlayerStatus, GoodsId, RuneId, TripList, StoneList, IronList, GoodsStatus) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, #goods{}, 0], GoodsStatus};
        {ok, GoodsTypeInfo, GoodsInfo, RuneInfo, RuleInfo, NewTripList, NewStoneList, NewIronList} ->
            case lib_goods_compose:equip_upgrade(PlayerStatus, GoodsStatus, GoodsTypeInfo, GoodsInfo, RuneInfo, RuleInfo, NewTripList, NewStoneList, NewIronList) of
                {ok, NewPlayerStatus, NewStatus, NewGoods} ->
                    if
                        GoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus);
                        true ->
                            NewPlayerStatus2 = NewPlayerStatus
                    end,
                    %% 传闻
                    lib_chat:send_TV({all},0,3, ["Equipshengji", 
											1, 
											NewPlayerStatus2#player_status.id, 
											NewPlayerStatus2#player_status.realm, 
											NewPlayerStatus2#player_status.nickname, 
											NewPlayerStatus2#player_status.sex, 
											NewPlayerStatus2#player_status.career, 
											NewPlayerStatus2#player_status.image, 
											NewGoods#goods.id, 
											NewGoods#goods.goods_id]),
                     {reply, [NewPlayerStatus2, 1, NewGoods, GoodsInfo#goods.location], NewStatus};
                 _Error ->
                     %util:errlog("mod_goods equip_upgrade:~p", [Error]),
                     {reply, [PlayerStatus, 10, #goods{}, 0], GoodsStatus}
            end
    end;

%% 装备洗炼
handle_call({'attribute_wash', PlayerStatus, GoodsId, Time, Grade, StoneList, LockAttrList}, _From, GoodsStatus) ->
    %% 检查洗炼石，锁定属性
    case lib_goods_compose_check:check_attribute_wash(PlayerStatus, GoodsId, Time, Grade, StoneList, LockAttrList, GoodsStatus) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res,[], #goods{}], GoodsStatus};
        {ok, GoodsInfo, StoneInfoList, NewLockAttrList, WashRule, TypeRule, StarRule, Cost} ->
            case lib_goods_compose:attribute_wash(PlayerStatus, GoodsStatus, GoodsInfo, Time, Grade, StoneInfoList, NewLockAttrList, WashRule, TypeRule, StarRule, Cost) of
                {ok, NewPlayerStatus, NewGoodsInfo, Attr, NewGoodsStatus} ->
                    if
                        NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP
                        andalso Time =:= 1 ->
                            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewGoodsStatus); 
                        true ->
                            NewPlayerStatus2 = NewPlayerStatus
                    end,
                    %% 帮派神炉返利
                    lib_guild:put_furnace_back(NewPlayerStatus2, Cost),
		            % case GoodsInfo#goods.color >= 3 of
			           %   true ->
			           %        lib_qixi:update_player_task_batch(PlayerStatus#player_status.id, [11,12,13,14,15], Time);
			           %   false -> []
		            % end,
                    %io:format("Attr = ~p~n", [Attr]),
                     {reply, [NewPlayerStatus2, 1, Attr, NewGoodsInfo], NewGoodsStatus};
                 Error ->
                     util:errlog("mod_goods attribute_wash:~p", [Error]),
                     {reply, [PlayerStatus, 10, [], #goods{}], GoodsStatus}
            end
    end;

%% 选择洗炼 属性
handle_call({'attribute_sel', PlayerStatus, GoodsId, Grade, Pos}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_attribute_sel(PlayerStatus, GoodsId, Grade, Pos, GoodsStatus) of
        {fail, Res} ->
            {reply, [PlayerStatus,Res,#goods{}], GoodsStatus};
        {ok, [GoodsInfo, AttrList]} ->
            case lib_goods_compose:attribute_sel(GoodsStatus, GoodsInfo, Grade, AttrList) of
                {ok, NewGoodsInfo, NewGoodsStatus} ->
                    if
                        NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            {ok, NewPlayerStatus} = lib_goods_util:count_role_equip_attribute(PlayerStatus, NewGoodsStatus);
                        true ->
                            NewPlayerStatus = PlayerStatus
                    end,
                    {reply, [NewPlayerStatus, 1, NewGoodsInfo], NewGoodsStatus};
                Error ->
                     util:errlog("mod_goods attribute_sel:~p", [Error]),
                     {reply, [PlayerStatus,10, #goods{}], GoodsStatus}
            end
    end;

%% 洗炼信息
handle_call({'attribute_get', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_attribute_get(PlayerStatus, GoodsId, GoodsStatus) of
        {fail, Res} ->
            {reply, [Res, [], [], []], GoodsStatus};
        {ok, Addition1,Addition2,Addition3} ->
            {reply, [1, Addition1, Addition2, Addition3], GoodsStatus};
        Error ->
            util:errlog("mod_goods attribute_get:~p", [Error])                    
     end;

%% 隐藏时装
handle_call({'hide_fashion', PlayerStatus, GoodsId, Show}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_hide_fashion(PlayerStatus, GoodsId, GoodsStatus) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res], GoodsStatus};
        {ok, GoodsInfo} ->
            case lib_goods_compose:hide_fashion(PlayerStatus, GoodsInfo, Show) of
                {ok, NewPlayerStatus} ->
                    {reply, [NewPlayerStatus, 1], GoodsStatus};
                Error ->
                    util:errlog("hide_fashion:~p", [Error]),
                    {reply, [PlayerStatus, 10], GoodsStatus}
            end
    end;      
    
%% ============================ 装备 end =======================================
%% 坐骑强化
handle_call({'mount_stren', PlayerStatus, EquipId, StoneId, LuckyId}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_mount_stren(PlayerStatus, GoodsStatus, EquipId, StoneId, LuckyId) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, #ets_mount{}], GoodsStatus};
        {ok, Mount, StoneInfo, LuckyInfo, LuckyRule, GoodsStrengthenRule} ->
             case lib_mount:mount_strengthen(PlayerStatus, GoodsStatus, Mount, StoneInfo, LuckyInfo, LuckyRule, GoodsStrengthenRule) of
                {ok, Res1, NewPlayerStatus, NewStatus, NewMount} ->
                    %%强化到7发送传闻
                     if  Res1 =:= 1 andalso NewMount#ets_mount.stren >= 7 ->
                             lib_chat:send_TV({all},0,3, ["qianghua", 
													1, 
													NewPlayerStatus#player_status.id, 
													NewPlayerStatus#player_status.realm, 
													NewPlayerStatus#player_status.nickname, 
													NewPlayerStatus#player_status.sex, 
													NewPlayerStatus#player_status.career, 
													NewPlayerStatus#player_status.image, 
													NewMount#ets_mount.id, 
													NewMount#ets_mount.type_id, 
													NewMount#ets_mount.stren]);
                         true -> skip
                     end,
                     {reply, [NewPlayerStatus, Res1, NewMount], NewStatus};
                 Error ->
                     util:errlog("mount_stren error:~p", [Error]),
                     {reply, [PlayerStatus, 10, #ets_mount{}], GoodsStatus}
            end
    end;

%% 坐骑卡使用
handle_call({'mount_card', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_mount_card(PlayerStatus, GoodsId, GoodsStatus) of
        {fail, Res} ->
            {reply, [Res, #ets_mount{}, PlayerStatus], GoodsStatus};
        {ok, GoodsInfo, Base} ->
            case lib_mount:use_mount_card(PlayerStatus, GoodsStatus, GoodsInfo, Base) of
                {ok, Res, NewPlayerStatus, NewStatus, NewMount} ->
                    lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
                    {reply, [Res, NewMount, NewPlayerStatus], NewStatus};
                {fail, Res} ->
                    io:format("~p ~p UsedMountCardRes:~p~n", [?MODULE, ?LINE, Res]),
                    {reply, [Res, #ets_mount{}, PlayerStatus], GoodsStatus};
                Error ->
                    ?INFO("mod_goods mount_card:~p", [Error]),
                    {reply, [10, #ets_mount{}, PlayerStatus], GoodsStatus}
            end
    end;

%% 回收坐骑
handle_call({'mount_recover', PlayerStatus, MountId}, _From, GoodsStatus) ->
    case lib_mount:check_mount_recover(PlayerStatus, MountId, GoodsStatus) of
        {fail, Res} ->
            {reply, [Res, PlayerStatus, #goods{}], GoodsStatus};
        {ok, Mount} ->
            case lib_mount:mount_recover(PlayerStatus, GoodsStatus, Mount) of
                {ok, NewPlayerStatus, NewGoodsStatus, NewGoodsInfo} ->
                    {reply, [?ERRCODE_OK, NewPlayerStatus, NewGoodsInfo], NewGoodsStatus};
                Error ->
                    util:errlog("mount_recover error:~p~n", [Error]),
                    {reply, [?ERRCODE_FAIL, PlayerStatus, #goods{}], GoodsStatus}
            end
    end;
                
%% ------------------------------- 坐骑 end -------------------------------------------------------------------

%% 宝石合成
handle_call({'compose', PlayerStatus, RuneList, StoneTypeId, StoneList, Times, IsRune, PerNum}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_compose(PlayerStatus, GoodsStatus, RuneList, StoneTypeId, StoneList, Times, IsRune, PerNum) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, 0, 0, 0, 0], GoodsStatus};
        {ok, NewStoneList, NewRuneList, GoodsComposeRule, Times, IsRune} ->
            case lib_goods_compose:compose(PlayerStatus, GoodsStatus, NewStoneList, NewRuneList, GoodsComposeRule, Times, IsRune) of
                {ok, NewPlayerStatus, NewStatus, SucNum, FailNum, Cost, GoodsType} ->
                     {reply, [NewPlayerStatus, 1, SucNum, FailNum, Cost, GoodsType], NewStatus};
                 Error ->
                     util:errlog("mod_goods compose error:~p", [Error]),
                     {reply, [PlayerStatus, 10, 0, 0, 0, 0], GoodsStatus}
            end
    end;

%% 宝石镶嵌
handle_call({'inlay', PlayerStatus, EquipId, StoneId1, RuneId1, StoneId2, RuneId2, StoneId3, RuneId3}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_inlay(PlayerStatus, EquipId, StoneId1, RuneId1, StoneId2, RuneId2, StoneId3, RuneId3, GoodsStatus) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, [], [], [], 0, #goods{}], GoodsStatus};
        {ok, GoodsInfo, Stone1Info, Stone2Info, Stone3Info, Rune1Info, Rune2Info, Rune3Info, GoodsInlayRule1, GoodsInlayRule2, GoodsInlayRule3} ->
            case lib_goods_compose:inlay(PlayerStatus, GoodsStatus, GoodsInfo, Stone1Info, Stone2Info, Stone3Info, Rune1Info, 
                                         Rune2Info, Rune3Info, GoodsInlayRule1, GoodsInlayRule2, GoodsInlayRule3) of
                {ok, NewPlayerStatus, NewStatus, NewGoodsInfo} ->
                    if
                        NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus);
                         true ->
                            NewPlayerStatus2 = NewPlayerStatus
                    end,
                     {reply, [NewPlayerStatus2, 1, Stone1Info, Stone2Info, Stone3Info, Stone1Info#goods.goods_id, NewGoodsInfo], NewStatus};
                 Error ->
                     util:errlog("mod_goods inlay error:~p", [Error]),
                     {reply, [PlayerStatus, 10, [], [], [], 0, #goods{}], GoodsStatus}
            end
    end;

%% 宝石拆除
handle_call({'backout', PlayerStatus, EquipId, Pos1, RuneId1, Pos2, RuneId2, Pos3, RuneId3}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_backout(PlayerStatus, GoodsStatus, EquipId, Pos1, RuneId1, Pos2, RuneId2, Pos3, RuneId3) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, #goods{}], GoodsStatus};
        {ok, GoodsInfo, Pos1, Pos2, Pos3, RuneInfo1, RuneInfo2, RuneInfo3} ->
            case lib_goods_compose:backout(PlayerStatus, GoodsStatus, GoodsInfo, Pos1, Pos2, Pos3, RuneInfo1, RuneInfo2, RuneInfo3) of
                {ok, NewPlayerStatus, NewStatus, NewGoodsInfo} ->
                    if
                        NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus);
                         true ->
                            NewPlayerStatus2 = NewPlayerStatus
                    end,
                     {reply, [NewPlayerStatus2, 1, NewGoodsInfo], NewStatus};
                 Error ->
                     util:errlog("mod_goods backout:~p", [Error]),
                     {reply, [PlayerStatus, 10, #goods{}], GoodsStatus}
            end
    end;

%% 炼炉合成
handle_call({'forge', PlayerStatus, Id, Num, Flag}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_forge(PlayerStatus, GoodsStatus, Id, Num, Flag) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, 0], GoodsStatus};
        {ok, ForgeInfo, GoodsTypeInfo} ->
            case lib_goods_compose:forge(PlayerStatus, GoodsStatus, ForgeInfo, GoodsTypeInfo, Num, Flag) of
                {ok, Res1, NewPlayerStatus, NewGoodsStatus} ->
                    %% 传闻
                    case Res1 =:= 1 andalso ForgeInfo#ets_forge.notice > 0 of
                        true ->
                            lib_chat:send_TV({all},0,3, ["lianlu", 
													1, 
													NewPlayerStatus#player_status.id, 
													NewPlayerStatus#player_status.realm, 
													NewPlayerStatus#player_status.nickname, 
													NewPlayerStatus#player_status.sex, 
													NewPlayerStatus#player_status.career, 
													NewPlayerStatus#player_status.image, 
													GoodsTypeInfo#ets_goods_type.goods_id]);
                        false ->
                            skip
                    end,
                    {reply, [NewPlayerStatus, Res1, ForgeInfo#ets_forge.notice], NewGoodsStatus};
                 Error ->
                     ?INFO("mod_goods forge:~p", [Error]),
                     {reply, [PlayerStatus, 10], GoodsStatus}
            end
    end;

%% 注灵
handle_call({'add_reiki', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    case lib_equip_reiki:check_add_reiki(PlayerStatus, GoodsId, GoodsStatus) of
        {fail, Res} ->
            {reply, [Res, PlayerStatus, #goods{}], GoodsStatus};
        {ok, GoodsInfo, ReikiRule} ->
            case lib_equip_reiki:add_reiki(PlayerStatus, GoodsInfo, ReikiRule, GoodsStatus) of
                {ok, Res1, NewPlayerStatus, NewGoodsInfo, NewStatus} ->
                    if
                        NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus);
                         true ->
                            NewPlayerStatus2 = NewPlayerStatus
                    end,
                    {reply, [Res1, NewPlayerStatus2, NewGoodsInfo], NewStatus};
                _Error ->
                    {reply, [10, PlayerStatus, #goods{}], GoodsStatus}
            end
    end;  

%% 器灵
handle_call({'qi_reiki', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    case lib_equip_reiki:check_qi_reiki(PlayerStatus, GoodsId, GoodsStatus) of
        {fail, Res} ->
            {reply, [Res, PlayerStatus, #goods{}], GoodsStatus};
        {ok, GoodsInfo, ReikiRule} ->
            case lib_equip_reiki:qi_reiki(PlayerStatus, GoodsInfo, ReikiRule, GoodsStatus) of
                {ok, NewPlayerStatus, NewGoodsInfo, NewStatus} ->
                    if
                        NewGoodsInfo#goods.location =:= ?GOODS_LOC_EQUIP ->
                            {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus);
                         true ->
                            NewPlayerStatus2 = NewPlayerStatus
                    end,
                    {reply, [1, NewPlayerStatus2, NewGoodsInfo], NewStatus};
                _Error ->
                    {reply, [10, PlayerStatus, #goods{}], GoodsStatus}
            end
    end;     

%% 注灵信息
handle_call({'get_reiki', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    case lib_equip_reiki:check_get_reiki(PlayerStatus, GoodsId, GoodsStatus) of
        {fail, Res} ->
            {reply, [Res, 0, 0], GoodsStatus};
        {ok, GoodsInfo} ->
            if
                GoodsInfo#goods.reiki_level =:= 0 ->
                    NewGoodsInfo = lib_equip_reiki:get_goods_reiki(GoodsInfo);
                true ->
                    NewGoodsInfo = GoodsInfo
            end,
            {reply, [1, NewGoodsInfo#goods.reiki_level, NewGoodsInfo#goods.qi_level], GoodsStatus};
        _Error ->
            skip
    end;

%% 替换时装
handle_call({'replace_wardrobe', PlayerStatus, M}, _From, GoodsStatus) ->
    case lib_fashion_change2:replace_wardrobe(PlayerStatus, M, GoodsStatus) of
        {ok, NewPS, NewStatus} ->
            {reply, [1, NewPS], NewStatus};
        {fail, Res} ->
            {reply, [Res, PlayerStatus], GoodsStatus}
    end;

handle_call({'fly_star', PlayerStatus, MountId, RuenList}, _From, GoodsStatus) ->
    case lib_mount2:check_up_fly_star(PlayerStatus, MountId, RuenList, GoodsStatus) of
        {fail, Res} ->
            {reply, [Res, PlayerStatus, #ets_mount{}], GoodsStatus};
        {ok, Mount, GoodsList, Rule} ->
            case lib_mount2:mount_up_fly_star(PlayerStatus, Mount, GoodsList, Rule, GoodsStatus) of
                {ok, Res, NewPlayerStatus, NewStatus, NewMount} ->
                    {reply, [Res, NewPlayerStatus, NewMount], NewStatus};
                _E ->
                    io:format("error ~p~n",[_E]),
                    {reply, [10, PlayerStatus, #ets_mount{}], GoodsStatus} 
            end
    end;

%% handle_call({'up_quality', PlayerStatus, MountId, StoneList}, _From, GoodsStatus) ->
%%     case lib_mount2:check_up_quality(PlayerStatus, MountId, StoneList, GoodsStatus) of
%%         {fail, Res} ->
%%             {reply, [Res, PlayerStatus, 0, 0], GoodsStatus};
%%         {ok, Mount, GoodsList, Rule} ->
%%             case lib_mount2:mount_up_quality(PlayerStatus, Mount, GoodsList, Rule, GoodsStatus) of
%%                 {ok, Res, NewPlayerStatus, NewStatus, NewMount} ->
%%                     {reply, [Res, NewPlayerStatus, NewMount#ets_mount.quality, NewMount#ets_mount.point], NewStatus};
%%                 _E ->
%%                     io:format("error ~p~n",[_E]),
%%                     {reply, [10, PlayerStatus, 0, 0], GoodsStatus} 
%%             end
%%     end;


handle_call({'up_quality', PlayerStatus, MountId, Type, Coin, StoneList}, _From, GoodsStatus) ->
    case lib_mount2:check_up_quality(PlayerStatus, MountId, Type, Coin, StoneList, GoodsStatus) of
        {fail, Res} ->
            {reply, [Res, PlayerStatus, []], GoodsStatus};
        {ok, Mount, Type, Coin, GoodsList, Rule} ->
            case lib_mount2:mount_up_quality(PlayerStatus, Mount, Type, Coin, GoodsList, Rule, GoodsStatus) of
                {ok, Res, NewPlayerStatus, NewStatus, NewMount} ->
                    {reply, [Res, NewPlayerStatus, NewMount#ets_mount.temp_quality_attr], NewStatus};
                _E ->
                     util:errlog("~p ~p Mount_Upgrade_Error:~p~n", [?MODULE, ?LINE, _E]),
                    {reply, [10, PlayerStatus, []], GoodsStatus} 
            end
    end;

handle_call({'mount_upgrade', PlayerStatus, MountId, RuenList}, _From, GoodsStatus) ->
    case lib_mount2:check_mount_upgrade(PlayerStatus, MountId, RuenList, GoodsStatus) of
        {fail, Res} ->
            {reply, [Res, PlayerStatus, #ets_mount{}], GoodsStatus};
        {ok, Mount, GoodsList, StarRule, MaxValue} ->
            case lib_mount2:mount_upgrade(PlayerStatus, Mount, GoodsList, StarRule, GoodsStatus, MaxValue) of
                {ok, Res, NewPlayerStatus, NewStatus, NewMount} ->
                    {reply, [Res, NewPlayerStatus, NewMount], NewStatus};
                _E ->
                    util:errlog("~p ~p Mount_Upgrade_Error:~p~n", [?MODULE, ?LINE, _E]),
                    {reply, [12, PlayerStatus, #ets_mount{}], GoodsStatus} 
            end
    end;
 
%% 功章续期
handle_call({'token_renewal', PlayerStatus, [GoodsId, Days]}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_token_renewal(PlayerStatus, GoodsStatus, GoodsId, Days) of
        {fail, Res} ->
            {reply, [Res, PlayerStatus, #goods{}], GoodsStatus};
        {ok, GoodsInfo, NeedNum} ->
            case mod_other_call:token_renewal(GoodsStatus, GoodsInfo, Days, NeedNum) of
                {ok, NewGoodsStatus, NewGoodsInfo} ->
                    {ok, NewPlayerStatus} = lib_goods_util:count_role_equip_attribute(PlayerStatus, NewGoodsStatus),
                    {reply, [1, NewPlayerStatus, NewGoodsInfo], NewGoodsStatus};
                _ ->
                    {reply, [10, PlayerStatus, GoodsInfo], GoodsStatus}
            end
    end;

%% 功章升级
handle_call({'token_upgrade', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    case lib_goods_compose_check:check_token_upgrade(PlayerStatus, GoodsStatus, GoodsId) of
        {fail, Res} ->
            {reply, [Res, PlayerStatus, #goods{}], GoodsStatus};
        {ok, GoodsInfo, NeedNum, TokenInfo} ->
            case mod_other_call:token_upgrade(PlayerStatus, GoodsStatus, GoodsInfo, TokenInfo, NeedNum) of
                {ok, NewPS, NewGoodsStatus, NewGoodsInfo} ->
                    {ok, NewPlayerStatus2} = lib_goods_util:count_role_equip_attribute(NewPS, NewGoodsStatus),
                    {reply, [1, NewPlayerStatus2, NewGoodsInfo], NewGoodsStatus};
                _ ->
                    {reply, [10, PlayerStatus, GoodsInfo], GoodsStatus}
            end
    end;

%%#################################### 新版宝石 #############################################  
%% 宝石栏升级
handle_call({'gemstone_upgrade', PlayerStatus, GemStone, GoodsList}, _From, GoodsStatus) -> 
    case lib_gemstone:check_gemstone_upgrade(PlayerStatus, GemStone, GoodsList, GoodsStatus) of 
        {fail, Res} ->
            {reply, [Res, PlayerStatus, 0, 0], GoodsStatus};
        {ok, NewGoodsList, Exp} -> 
            case lib_gemstone:gemstone_upgrade(PlayerStatus, GoodsStatus, GemStone, Exp, NewGoodsList) of 
                {ok, NewPS, IsUpgrade, Add_Exp, NewStatus} ->
                    {reply, [1, NewPS, IsUpgrade, Add_Exp], NewStatus};
                _Error -> 
                    {reply, [0, PlayerStatus, 0, 0], GoodsStatus}
            end
    end;

%% 取装备位置装备
handle_call({'gemstone_equip', PlayerStatus, EquipPos}, _From, GoodsStatus) -> 
    GoodsInfo = lib_goods_util:get_goods_by_cell(PlayerStatus#player_status.id, ?GOODS_LOC_EQUIP, EquipPos, GoodsStatus#goods_status.dict),   
    {reply, GoodsInfo, GoodsStatus}.



            
    
                    
            
    




