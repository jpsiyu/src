%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-23
%% Description: 装备检查
%% --------------------------------------------------------
-module(lib_goods_check).
-compile(export_all).
-include("def_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("server.hrl").
-include("common.hrl").
-include("shop.hrl").
-include("task.hrl").
-include("drop.hrl").

check_delete(GoodsStatus, GoodsId, GoodsNum) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
            {fail, 3};
        %% 物品不在背包
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品数量不正确
        GoodsNum < 1 orelse GoodsInfo#goods.num < GoodsNum ->
            {fail, 6};
        %% 正在交易中
        GoodsStatus#goods_status.sell_status =/= 0  ->
            {fail, 7};
        true ->
            {ok, GoodsInfo}
    end.

check_delete_list(GoodsStatus, GoodsList) ->
    F = fun({GoodsId,GoodsNum}, List) ->
            case check_delete(GoodsStatus, GoodsId, GoodsNum) of
                {ok, GoodsInfo} -> {ok, [{GoodsInfo,GoodsNum} | List]};
                {fail, Res} -> {fail, Res}
            end
        end,
    list_handle(F, [], GoodsList).

check_equip(PlayerStatus, GoodsId, Cell, GoodsStatus) ->
	Location = ?GOODS_LOC_EQUIP,
	NowTime = util:unixtime(),
	GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    Sell = PlayerStatus#player_status.sell,
	Kf3v3InScene = lists:member(PlayerStatus#player_status.scene, data_kf_3v3:get_config(scene_pk_ids)),
	if
        PlayerStatus#player_status.scene =:= 251 orelse
        PlayerStatus#player_status.scene =:= 250 orelse
        PlayerStatus#player_status.scene =:= 252 orelse
        Kf3v3InScene =:= true ->
            {fail, ?ERRCODE15_SCENE_WRONG};
		%% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, ?ERRCODE15_NO_GOODS};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, ?ERRCODE15_PALYER_ERR};
        %% 物品位置不正确
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG andalso GoodsInfo#goods.location =/= ?GOODS_LOC_FASHION ->
            {fail, ?ERRCODE15_LOCATION_ERR};
        %% 物品类型不可装备
        GoodsInfo#goods.type =/= ?GOODS_TYPE_EQUIP ->
            {fail, ?ERRCODE15_TYPE_ERR};
        %% 装备耐久为0
        GoodsInfo#goods.attrition > 0 andalso GoodsInfo#goods.use_num =:= 0 ->
            {fail, ?ERRCODE15_ATTRITION_ZERO};
        %% 装备已经过期，不可穿戴
        GoodsInfo#goods.expire_time > 0 andalso GoodsInfo#goods.expire_time =< NowTime ->
            {fail, ?ERRCODE15_FASHION_EXPIRE};
        %% 正在交易中
        Sell#status_sell.sell_status > 0 ->
            {fail, ?ERRCODE15_IN_SELL};
        true ->
            case can_equip(PlayerStatus, GoodsInfo#goods.goods_id, Cell) of
                %% 玩家条件不符
                {fail, Res} ->
                    {fail, Res};
                NewCell ->
                    {ok, GoodsInfo, Location, NewCell}
            end
    end.

%% 用于礼包直接装备上
add_equip_by_typeid(GoodsTypeId, GoodsStatus) ->
    %%增加物品
    case data_goods_type:get(GoodsTypeId) of
        %% 物品不存在
        [] -> 
            {fail, ?ERRCODE15_NO_GOODS};
        GoodsTypeInfo ->
            GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, GoodsTypeInfo#ets_goods_type.bind, 
                                                           ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
            CellNum = lib_storage_util:get_null_cell_num(GoodsList, GoodsTypeInfo#ets_goods_type.max_overlap, 1),
            case length(GoodsStatus#goods_status.null_cells) < CellNum of
                %% 背包格子不足
                true -> 
                    {fail, 5};
                false ->
                    ok = lib_goods_dict:start_dict(),
                    GoodsInfo = lib_goods_util:get_new_goods(GoodsTypeInfo),
                    {ok, NewGoodsStatus} = lib_goods:add_goods_base(GoodsStatus, GoodsTypeInfo, 1, GoodsInfo, GoodsList),
                    Cell = data_goods:get_equip_cell(GoodsTypeInfo#ets_goods_type.subtype),
                    Dict = lib_goods_dict:handle_dict(NewGoodsStatus#goods_status.dict),
                    NewGoodsStatus2 = NewGoodsStatus#goods_status{dict = Dict},
                    {ok, GoodsInfo, Cell, NewGoodsStatus2}
            end
    end.

%% 检查装备是否可穿
can_equip(PlayerStatus, GoodsTypeId, Cell) ->
	GoodsTypeInfo = data_goods_type:get(GoodsTypeId),
    DefCell = data_goods:get_equip_cell(GoodsTypeInfo#ets_goods_type.subtype),
    NewCell = case (Cell =< 0 orelse Cell > 12) of
                  true -> DefCell;
                  false -> Cell
              end,
    if  GoodsTypeInfo#ets_goods_type.subtype =:= 32 andalso NewCell =/= 11 andalso NewCell =/= 12 ->
            {fail, ?ERRCODE15_LOCATION_ERR};
        GoodsTypeInfo#ets_goods_type.subtype =:= 30 andalso NewCell =/= 8 andalso NewCell =/= 9 ->
            {fail, ?ERRCODE15_LOCATION_ERR};
        GoodsTypeInfo#ets_goods_type.subtype =/= 32 andalso GoodsTypeInfo#ets_goods_type.subtype =/= 30 andalso NewCell =/= DefCell ->
            {fail, ?ERRCODE15_LOCATION_ERR};
        GoodsTypeInfo#ets_goods_type.level > PlayerStatus#player_status.lv ->
            {fail, ?ERRCODE15_LV_ERR};
        GoodsTypeInfo#ets_goods_type.career > 0 andalso GoodsTypeInfo#ets_goods_type.career =/= PlayerStatus#player_status.career ->
            {fail, ?ERRCODE15_CAREER_ERR};
        %GoodsTypeInfo#ets_goods_type.job > PlayerStatus#player_status.jobs ->
        %    {fail, ?ERRCODE15_JOB_ERR};
        %GoodsTypeInfo#ets_goods_type.xwpt_limit > PlayerStatus#player_status.xwpt ->
        %    {fail, ?ERRCODE15_XWPT_ERR};
        GoodsTypeInfo#ets_goods_type.sex > 0 andalso GoodsTypeInfo#ets_goods_type.sex =/= PlayerStatus#player_status.sex ->
            {fail, ?ERRCODE15_SEX_ERR};
        true ->
            NewCell
    end.

%% 缷下
check_unequip(PlayerStatus, GoodsStatus, GoodsId) ->
	GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
	Kf3v3InScene = lists:member(PlayerStatus#player_status.scene, data_kf_3v3:get_config(scene_pk_ids)),
	if
        PlayerStatus#player_status.scene =:= 251 orelse PlayerStatus#player_status.scene =:= 252 orelse
        Kf3v3InScene =:= true ->
            {fail, ?ERRCODE15_SCENE_WRONG};
		%% 物品不存在
		is_record(GoodsInfo, goods) =:= false ->
			{fail, ?ERRCODE15_NO_GOODS};
		%% 物品不属于你所有
		GoodsInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
			{fail, ?ERRCODE15_PALYER_ERR};
		%% 物品不在身上
        GoodsInfo#goods.location =/= ?GOODS_LOC_EQUIP ->
            {fail, ?ERRCODE15_LOCATION_ERR};
		%% 物品类型不可装备
        GoodsInfo#goods.type =/= 10 ->
            {fail, ?ERRCODE15_TYPE_ERR};
		%% 背包格子不足
        length(GoodsStatus#goods_status.null_cells) =:= 0 ->
            {fail, ?ERRCODE15_NO_CELL};
		true ->
			{ok, GoodsInfo}
	end.
		
%% 修理装备
check_mend_list(PlayerStatus, GoodsList) ->
	F = fun(GoodsInfo, C) ->
				case check_mend(PlayerStatus, GoodsInfo) of
					{fail, Res} ->
						{fail, Res};
					{ok, Cost} ->
						{ok, Cost+C}
				end
		end,
	case list_handle(F, 0, GoodsList) of
		{fail, Res} ->
			{fail, Res};
		{ok, Cost} ->
			case lib_goods_util:is_enough_money(PlayerStatus, Cost, coin) of
				false ->
					% 余额不足
					{fail, ?ERRCODE15_NO_MONEY};
				true ->
					case length(GoodsList) =:= 0 of
						true -> % 无磨损
							{fail, ?ERRCODE15_ATTRITION_FULL};
						false ->
							{ok}
					end
			end
	end.
		
%% 修理检查
check_mend(PlayerStatus, GoodsInfo) ->
	Kf3v3InScene = lists:member(PlayerStatus#player_status.scene, data_kf_3v3:get_config(scene_pk_ids)),
	if
		%物品不存在
		is_record(GoodsInfo, goods) =:= false ->
			{fail, ?ERRCODE15_NO_GOODS};
		% 物品不属于你所有
		GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
			{fail, ?ERRCODE15_PALYER_ERR};
		% 物品类型不正确,不是装备
		GoodsInfo#goods.type =/= 10 ->
			{fail, ?ERRCODE15_TYPE_ERR};
		% 装备不可磨损，不用修复
		GoodsInfo#goods.attrition =:= 0 ->
			{fail, ?ERRCODE15_ATTRITION_ERR};
        PlayerStatus#player_status.scene =:= 251 orelse
        PlayerStatus#player_status.scene =:= 250 orelse 
        PlayerStatus#player_status.scene =:= 252 orelse
        Kf3v3InScene =:= true ->
            {fail, ?ERRCODE15_MAND};
		true ->
			UseNum = data_goods:count_goods_use_num(GoodsInfo#goods.equip_type, GoodsInfo#goods.attrition),
			if %无磨损
				UseNum =:= GoodsInfo#goods.use_num ->
					{ok, 0};
				true ->
					Cost = data_goods:count_mend_cost(GoodsInfo),
					{ok, Cost}
			end
	end.

%%检查背包拖动物品
check_drag_goods(GoodsStatus, GoodsId, OldCell, NewCell, MaxCellNum) ->
	GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
	if
		%% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, ?ERRCODE15_NO_GOODS};
		%% 物品不属于你所有
        GoodsInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
            {fail, ?ERRCODE15_PALYER_ERR};
        %% 物品不在背包
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, ?ERRCODE15_LOCATION_ERR};
		%% 物品格子位置不正确
        GoodsInfo#goods.cell =/= OldCell ->
            {fail, ?ERRCODE15_LOCATION_ERR};
		%% 物品格子位置不正确
        NewCell < 1 orelse NewCell > MaxCellNum ->
            {fail, ?ERRCODE15_LOCATION_ERR};
		true ->
			{ok, GoodsInfo}
	end.	

%% 检查使用物品
check_use_goods(PlayerStatus, GoodsId, GoodsNum, GoodsStatus) ->
	NowTime = util:unixtime(),
	GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
	if
		%% 物品不存在
        is_record(GoodsInfo, goods) =:= false orelse GoodsInfo#goods.id < 0 ->
            {fail, ?ERRCODE15_NO_GOODS};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
            {fail, ?ERRCODE15_PALYER_ERR};
        %% 物品不在背包
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, ?ERRCODE15_LOCATION_ERR};
		%% 物品数量不正确
        GoodsNum < 1 orelse GoodsInfo#goods.num < GoodsNum ->
            {fail, ?ERRCODE15_NUM_ERR};
        %% 冷却时间
		 GoodsInfo#goods.type =:= ?GOODS_TYPE_DRUG andalso GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_HP
                andalso GoodsStatus#goods_status.hp_cd > NowTime ->
            {fail, ?ERRCODE15_IN_CD};
        %% 冷却时间
        GoodsInfo#goods.type =:= ?GOODS_TYPE_DRUG andalso GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_MP 
                andalso GoodsStatus#goods_status.mp_cd > NowTime ->
            {fail, ?ERRCODE15_IN_CD};
		 %% 人物等级不足
        GoodsInfo#goods.level > PlayerStatus#player_status.lv ->
            {fail, ?ERRCODE15_LV_ERR};
		%% 人物已经死亡
        GoodsInfo#goods.type =:= ?GOODS_TYPE_DRUG andalso PlayerStatus#player_status.hp =:= 0 ->
            {fail, ?ERRCODE15_PLAYER_DIE};
		 %% 背包已达上限
        GoodsInfo#goods.type =:= ?GOODS_TYPE_GAIN andalso GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_BAG_EXD ->
            CellNum = data_goods:get_extend_num(GoodsInfo#goods.goods_id),
            if  (PlayerStatus#player_status.cell_num + CellNum * GoodsNum) > ?GOODS_BAG_MAX_NUM ->
                    {fail, ?ERRCODE15_CELL_MAX};
                true ->
                    {ok, GoodsInfo, {}}
            end;
		%% 仓库已达上限
        GoodsInfo#goods.type =:= ?GOODS_TYPE_GAIN andalso GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_STORAGE_EXD ->
            CellNum = data_goods:get_extend_num(GoodsInfo#goods.goods_id),
            if  (PlayerStatus#player_status.storage_num + CellNum * GoodsNum) > ?GOODS_STORAGE_MAX_NUM ->
                    {fail, ?ERRCODE15_STORAGE_MAX};
                true ->
                    {ok, GoodsInfo, {}}
            end;
        GoodsInfo#goods.goods_id =:= 613601 andalso length(GoodsStatus#goods_status.null_cells) =:= 0 ->
            {fail, ?ERRCODE15_NO_CELL};
        GoodsInfo#goods.expire_time > 0 andalso GoodsInfo#goods.expire_time =< NowTime ->
            {fail, ?ERRCODE15_FASHION_EXPIRE};
		true ->
			if GoodsInfo#goods.type =:= ?GOODS_TYPE_GIFT -> %礼包
				   lib_gift_check:ckeck_use_gift(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum);
			   GoodsInfo#goods.type =:= ?GOODS_TYPE_BUFF -> %使用buff
				   lib_goods_check:check_use_buff(PlayerStatus, GoodsInfo);
			   GoodsInfo#goods.type =:= ?GOODS_TYPE_DRUG
                    andalso (GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_HP_BAG 
											 orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_MP_BAG) -> %药物内力包
                                SceneType = lib_scene:get_res_type(PlayerStatus#player_status.scene),
                                case lists:member(SceneType, ?REPLY_SCENE_LIMIT) of %该场景不能使用
                                    true -> {fail, ?ERRCODE15_SCENE_WRONG};
                                    false ->
										%% 检查HP
                                        case lib_goods_check:check_use_hp(PlayerStatus, GoodsInfo, GoodsNum) of
                                            false -> {fail, ?ERRCODE15_HP_MP_FULL};
                                            true -> {ok, GoodsInfo, {}}
                                        end
                                end;
%%                         end;
			   GoodsInfo#goods.goods_id =:= 521004 -> %婚礼烟花
                    case data_goods_type:get(GoodsInfo#goods.goods_id) of
                        [] -> {fail, ?ERRCODE15_NO_GOODS};
                        GoodsTypeInfo ->
                            if  length(GoodsTypeInfo#ets_goods_type.scene_limit) > 0 ->
                                    SceneId = PlayerStatus#player_status.scene,
                                    case lists:member(SceneId, GoodsTypeInfo#ets_goods_type.scene_limit) of
                                        false -> {fail, ?ERRCODE15_SCENE_WRONG};
                                        true -> {ok, GoodsInfo, {}}
                                    end;
                                true -> {ok, GoodsInfo, {}}
                            end
                    end;
                true ->
                    {ok, GoodsInfo, {}}
            end
    end.

%% 销毁物品
check_throw(GoodsStatus, GoodsId, GoodsNum) ->
	GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, ?ERRCODE15_NO_GOODS};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
            {fail, ?ERRCODE15_PALYER_ERR};
        %% 物品不在背包
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, ?ERRCODE15_LOCATION_ERR};
        %% 物品不可销毁
        GoodsInfo#goods.isdrop =:= 1 ->
            {fail, ?ERRCODE15_NOT_TRHOW};
        %% 物品数量不正确
        GoodsNum < 1 orelse GoodsInfo#goods.num < GoodsNum ->
            {fail, ?ERRCODE15_NUM_ERR};
        %% 正在交易中
        GoodsStatus#goods_status.sell_status =/= 0  ->
            {fail, ?ERRCODE15_IN_SELL};
        true ->
            {ok, GoodsInfo}
    end.

%% 检查拣取地上掉落包的物品
check_drop_choose(PlayerStatus, GoodsStatus, DropId, GoodsStatus) ->
    case check_drop_list(PlayerStatus, DropId) of
        {fail, Res} ->
            {fail, Res};
        {ok, DropInfo} ->
            GoodsTypeId = DropInfo#ets_drop.goods_id,
            case data_goods_type:get(GoodsTypeId) of
                [] ->
                    {fail, ?ERRCODE15_NO_GOODS_TYPE};
                GoodsTypeInfo when GoodsTypeId =:= ?GOODS_ID_COIN ->
                    {ok, GoodsTypeInfo, DropInfo};
                GoodsTypeInfo ->
                    GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, 
                                                                   DropInfo#ets_drop.bind, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
                    CellNum = lib_storage_util:get_null_cell_num(GoodsList, GoodsTypeInfo#ets_goods_type.max_overlap, DropInfo#ets_drop.num),
                    Dis = get_drop_distance(PlayerStatus, DropInfo),
                    if
                        %% 背包格子不足
                        length(GoodsStatus#goods_status.null_cells) < CellNum ->
                            {fail, ?ERRCODE15_NO_CELL};
                        Dis =:= false andalso DropInfo#ets_drop.goods_id =:= 602001 ->
                            {fail, ?ERRCODE15_DISTANCE};
                        true ->
                            {ok, GoodsTypeInfo, DropInfo}
                    end
            end
    end.

get_drop_distance(PlayerStatus,  DropInfo) ->
    (PlayerStatus#player_status.scene =:= DropInfo#ets_drop.scene andalso abs(DropInfo#ets_drop.x - PlayerStatus#player_status.x) =< 5 andalso abs(DropInfo#ets_drop.y - PlayerStatus#player_status.y) =< 5).

check_drop_list(PlayerStatus, DropId) ->
    DropInfo = mod_drop:get_drop(DropId),
    NowTime = util:unixtime(),
    Sell = PlayerStatus#player_status.sell,
    if
        %% 掉落包已经消失
        is_record(DropInfo, ets_drop) =:= false ->
            {fail, ?ERRCODE15_NO_DROP};
        %% 掉落包已经消失
        DropInfo#ets_drop.expire_time =< NowTime ->
            {fail, ?ERRCODE15_NO_DROP};
        %% 无权拣取
        DropInfo#ets_drop.scene =/=  PlayerStatus#player_status.scene ->
            {fail, ?ERRCODE15_NO_DROP_PER};
        %% 无权拣取
        DropInfo#ets_drop.team_id > 0 andalso DropInfo#ets_drop.team_id =/= PlayerStatus#player_status.pid_team
            andalso (DropInfo#ets_drop.expire_time - NowTime) > 20 ->
            {fail, ?ERRCODE15_NO_DROP_PER};
        %% 无权拣取
        DropInfo#ets_drop.copy_id =/= 0 andalso DropInfo#ets_drop.copy_id =/= PlayerStatus#player_status.copy_id
            andalso (DropInfo#ets_drop.expire_time - NowTime) > 20 ->
            {fail, ?ERRCODE15_NO_DROP_PER};
        %% 无权拣取
        DropInfo#ets_drop.player_id > 0 andalso DropInfo#ets_drop.player_id =/= PlayerStatus#player_status.id
                andalso (DropInfo#ets_drop.expire_time - NowTime) > 20 ->
            {fail, ?ERRCODE15_NO_DROP_PER};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, ?ERRCODE15_IN_SELL};
        %% 死亡
        PlayerStatus#player_status.hp =< 0 ->
            {fail, ?ERRCODE15_NO_DROP_PER};
        true ->
            {ok, DropInfo}
    end.

%% 检查拆分物品
check_split(GoodsStatus, GoodsId, GoodsNum) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, ?ERRCODE15_NO_GOODS};
        %% 物品不属于该玩家所有
        GoodsInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
            {fail, ?ERRCODE15_PALYER_ERR};
        %% 物品不在背包
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, ?ERRCODE15_LOCATION_ERR};
        %% 物品数量不正确
        GoodsNum < 1 ->
            {fail, ?ERRCODE15_NUM_ERR};
        GoodsInfo#goods.num =< GoodsNum ->
            {fail, ?ERRCODE15_NUM_ERR};
        %% 背包格子不足
        length(GoodsStatus#goods_status.null_cells) =:= 0 ->
            {fail, ?ERRCODE15_NO_CELL};
        true ->
            {ok, GoodsInfo}
    end.

list_handle(F, Data, List) ->
	case List of
		[H|T] ->
			case F(H, Data) of
				{ok, Data2} ->
					list_handle(F, Data2, T);
				Error ->
					Error
			end;
		[] ->
			{ok, Data}
	end.

%%检查NPC 
check_npc(PlayerStatus, ShopType, Type) ->
    Vip = PlayerStatus#player_status.vip,
    %%商店类型 - 商城
    if 
        %% 35级以下不判断
        PlayerStatus#player_status.lv =< 35 ->
            true;
        Type =:= pay andalso (ShopType =:= ?SHOP_TYPE_GOLD orelse ShopType =:= ?SHOP_TYPE_SIEGE_SHOP2) -> 
           true;
       %%商店类型 - VIP药店
        ShopType =:= ?SHOP_TYPE_VIP_DRUG andalso Vip#status_vip.vip_type > 0 -> 
            true;
       %%商店类型 - VIP仓库
        ShopType =:= ?SHOP_TYPE_VIP_STORAGE andalso Vip#status_vip.vip_type > 0 -> 
            true;
        %%炼化NPC
        ShopType =:= ?SHOP_TYPE_FORGE -> 
            true;
        %% 竞技场兑换NPC  战功兑换NPC  荣誉兑换NPC
        Type =:= exchange andalso (ShopType =:= ?SHOP_TYPE_ARENA orelse ShopType =:= ?SHOP_TYPE_BATTLE orelse ShopType =:= ?SHOP_TYPE_HOUNOR) -> 
            true;
        true -> 
            lib_npc:is_near_npc(ShopType, PlayerStatus#player_status.scene, PlayerStatus#player_status.x, PlayerStatus#player_status.y)
    end.

%% 检查buff
check_use_buff(PlayerStatus, GoodsInfo) ->
    case data_goods_type:get(GoodsInfo#goods.goods_id) of
        [] ->
            {fail, ?ERRCODE15_NO_GOODS};
        GoodsTypeInfo ->
            if length(GoodsTypeInfo#ets_goods_type.scene_limit) > 0 ->
                   SceneId = PlayerStatus#player_status.scene,
                   case lists:member(SceneId, GoodsTypeInfo#ets_goods_type.scene_limit) of
                       false ->
                           {fail, ?ERRCODE15_SCENE_WRONG};
                       true ->
                           {ok, GoodsInfo, {}}
                   end;
                   true ->
                       {ok, GoodsInfo, {}}
            end
    end.

%% 检查气血法力使用物品后是否到达上限
check_use_hp(PlayerStatus, GoodsInfo, GoodsNum) ->
    %%Hp = PlayerStatus#player_status.hp_bag,
    [BagMax,_Reply_num] = data_hp_mp:get_bag_by_lv(PlayerStatus#player_status.lv),
    BagCount = lib_hp_bag:get_bag_count(PlayerStatus#player_status.id,GoodsInfo#goods.subtype),
    %%io:format("LINE:~p Hp#status_hp.hp_bag + GoodsInfo#goods.hp * GoodsNum:~p", [?LINE,BagCount + GoodsInfo#goods.hp * GoodsNum]),
    case GoodsInfo#goods.subtype of
        ?GOODS_SUBTYPE_HP_BAG -> %气血包
             %%io:format("LINE:~p NewBag:~p BagMax:~p ~n", [?LINE,BagCount + GoodsInfo#goods.hp * GoodsNum,BagMax]),
            ((BagCount + GoodsInfo#goods.hp * GoodsNum) =< BagMax);
        ?GOODS_SUBTYPE_MP_BAG -> %内力包
            %%io:format("LINE:~p NewBag:~p BagMax:~p ~n", [?LINE,BagCount + GoodsInfo#goods.mp * GoodsNum,BagMax]),
            ((BagCount + GoodsInfo#goods.mp * GoodsNum) =< BagMax);
        _ -> true
    end.

check_npc_exchange(PlayerStatus, GoodsStatus, NpcTypeId, ExchangeId, ExchangeNum) ->
    Sell = PlayerStatus#player_status.sell,
    ExchangeInfo = data_exchange:get(ExchangeId),
    if
        %% 数量不正确
        ExchangeNum < 1 orelse ExchangeNum > 100 ->
            {fail, ?ERRCODE15_NUM_OVER_ERR};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, ?ERRCODE15_IN_SELL};
        %% 规则不存在
        is_record(ExchangeInfo, ets_goods_exchange) =:= false ->
            {fail, ?ERRCODE15_NO_RULE};
        %% 规则未生效
        ExchangeInfo#ets_goods_exchange.status =:= 0 ->
            {fail, ?ERRCODE15_RULE_UNACTIVE};
        %% NPC类型错误
        ExchangeInfo#ets_goods_exchange.npc =/= NpcTypeId ->
            {fail, ?ERRCODE15_NPC_TYPE_ERR};
        %% 跨服声望不足
        ExchangeInfo#ets_goods_exchange.honour > 0 andalso (ExchangeInfo#ets_goods_exchange.honour * ExchangeNum) > PlayerStatus#player_status.kf_1v1#status_kf_1v1.pt ->
            {fail, ?ERRCODE15_HONOUR_ERR};
        %% 荣誉不足
%%                 ExchangeInfo#ets_goods_exchange.king_honour > 0 andalso (ExchangeInfo#ets_goods_exchange.king_honour * ExchangeNum) > PlayerStatus#player_status.king_honour ->
%%                     {fail, ?ERRCODE15_HONOUR_ERR};
        
        true ->
        %% 到时加上
        CanEx = if  %% 竞技场积分兑换
%%                  ExchangeInfo#ets_goods_exchange.type =:= 1 ->
%%                      lib_arena:can_exchange(PlayerStatus);
%%                  %% 帮派战功兑换
%%                  ExchangeInfo#ets_goods_exchange.type =:= 3 ->
%%                      lib_guild_battle:can_exchange(PlayerStatus);
%%                  %% 跨服积分兑换
%%                  ExchangeInfo#ets_goods_exchange.type =:= 7 ->
%%                      lib_kfz_3v3:can_exchange(PlayerStatus);
%%                  %% 跨服荣誉兑换
%%                  ExchangeInfo#ets_goods_exchange.type =:= 8 ->
%%                      lib_kfz_arena:can_exchange(PlayerStatus);
                    true -> true
                end,
        Count = if  ExchangeInfo#ets_goods_exchange.limit_id > 0 ->
                        mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ExchangeInfo#ets_goods_exchange.limit_id);
                    true -> 0
                end,
	    %% 当日单个物品兑换次数
	    SingleCount = if  ExchangeInfo#ets_goods_exchange.single_limit_num > 0 ->
				  SingleKey = integer_to_list(PlayerStatus#player_status.id) ++ "_" ++ integer_to_list(ExchangeInfo#ets_goods_exchange.id),
				  case mod_daily_dict:get_special_info(SingleKey) of
				      undefined -> 0;
				      _SingleCount -> _SingleCount
				  end;
			      true -> 0
			  end,
        CellNum = lib_storage_util:get_null_storage_num(0, ExchangeNum, ExchangeInfo#ets_goods_exchange.max_overlap),
        if  %% 英雄岛开战期间不可兑换
            ExchangeInfo#ets_goods_exchange.type =:= 1 andalso CanEx =:= false ->
                {fail, ?ERRCODE15_EXCHANGE_ARENA_ERR};
            %% 帮派战斗期间不可兑换
            ExchangeInfo#ets_goods_exchange.type =:= 3 andalso CanEx =:= false ->
                {fail, ?ERRCODE15_EXCHANGE_BATTLE_ERR};
            %% 跨服战斗期间不可兑换
            ExchangeInfo#ets_goods_exchange.type =:= 7 andalso CanEx =:= false ->
                {fail, ?ERRCODE15_EXCHANGE_KFZ_ERR};
            %% 次数已达上限
            ExchangeInfo#ets_goods_exchange.limit_id > 0 andalso Count >= ExchangeInfo#ets_goods_exchange.limit_num ->
                {fail, ?ERRCODE15_NUM_LIMIT};
	    %% 单个物品次数已达上限
	    ExchangeInfo#ets_goods_exchange.single_limit_num > 0 andalso SingleCount >= ExchangeInfo#ets_goods_exchange.single_limit_num ->
                {fail, ?ERRCODE15_NUM_SINGLE_LIMIT};
	    %% 单个物品次数超出每天上限
	    ExchangeInfo#ets_goods_exchange.single_limit_num > 0 andalso (SingleCount + ExchangeNum) > ExchangeInfo#ets_goods_exchange.single_limit_num ->
                {fail, ?ERRCODE15_NUM_SINGLE_OVER};
            %% 次数超出每天上限
            ExchangeInfo#ets_goods_exchange.limit_id > 0 andalso (Count + ExchangeNum) > ExchangeInfo#ets_goods_exchange.limit_num ->
                {fail, ?ERRCODE15_NUM_OVER};
            %% 格子不足
            CellNum > length(GoodsStatus#goods_status.null_cells) ->
                {fail, ?ERRCODE15_NO_CELL};
            true ->
                NowTime = util:unixtime(),
                if ExchangeInfo#ets_goods_exchange.start_time > NowTime andalso ExchangeInfo#ets_goods_exchange.start_time =/= 0 ->
                        {fail, ?ERRCODE15_TIME_NOT_START};
                    ExchangeInfo#ets_goods_exchange.end_time < NowTime andalso ExchangeInfo#ets_goods_exchange.end_time =/= 0 ->
                        {fail, ?ERRCODE15_TIME_END};
                    true ->
                        case lib_gift_check:check_exchange_raw_goods(ExchangeInfo#ets_goods_exchange.raw_goods, PlayerStatus, ExchangeNum, GoodsStatus) of
                            %% 条件不符
                            false -> {fail, ?ERRCODE15_REQUIRE_ERR};
                            true ->{ok, ExchangeInfo}
                        end
              end
        end
    end.

check_near_npc(PlayerStatus, NpcTypeId, NpcId, Type) ->
    Vip = PlayerStatus#player_status.vip,
    if  Type =:= pay andalso NpcTypeId =:= ?SHOP_TYPE_GOLD -> ok;
        Type =:= sell andalso NpcTypeId =:= ?SHOP_TYPE_VIP_DRUG andalso Vip#status_vip.vip_type > 0 -> ok;
        Type =:= pay andalso NpcTypeId =:= ?SHOP_TYPE_VIP_DRUG andalso Vip#status_vip.vip_type > 0 -> ok;
        Type =:= move andalso NpcTypeId =:= ?SHOP_TYPE_VIP_STORAGE andalso Vip#status_vip.vip_type > 0 -> ok;
        Type =:= exchange andalso (NpcTypeId =:= ?SHOP_TYPE_ARENA orelse NpcTypeId =:= ?SHOP_TYPE_BATTLE orelse NpcTypeId =:= ?SHOP_TYPE_HOUNOR orelse NpcTypeId =:= 30063 orelse NpcTypeId =:= 30066 orelse NpcTypeId =:= 20108 orelse NpcTypeId =:= 30082 orelse NpcTypeId =:= 30095 orelse NpcTypeId =:= ?SHOP_TYPE_KING_HOUNOR) -> ok;
        true -> lib_npc:check_npc(NpcId, NpcTypeId, PlayerStatus#player_status.scene, PlayerStatus#player_status.x, PlayerStatus#player_status.y)
    end.

%% 使用替身娃娃完成任务
check_finish_task(PlayerStatus, TaskId, GoodsStatus) ->
    Sell = PlayerStatus#player_status.sell,
    case data_task_goods:get_finish_goods(TaskId) of
        %% 任务不可使用替身娃娃完成
        [] -> {fail, 2};
        [GoodsTypeId, GoodsNum] when GoodsTypeId =:= 0 orelse GoodsNum =:= 0 ->
            {fail, 2};
        [GoodsTypeId, GoodsNum] ->
            GoodsList = lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id,
                                                           GoodsTypeId, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
            TotalNum = lib_goods_util:get_goods_totalnum(GoodsList),
            if  %% 物品数量不足
                TotalNum < GoodsNum ->
                    {fail, 3};
                %% 正在交易中
                Sell#status_sell.sell_status =/= 0 ->
                    {fail, 4};
                true ->
                    {ok, GoodsList, GoodsTypeId, GoodsNum}
            end
    end.

%% 送东西
check_send_gift(PlayerStatus, Type, SubType, PlayerId) ->
    Sell = PlayerStatus#player_status.sell,
    case data_goods:get_send_gift(Type, SubType) of
        %% 没有找到赠送信息
        [] -> {fail, 2};
        [GoodsTypeId,Coin,Gold] when GoodsTypeId =:= 0 orelse (Coin =:= 0 andalso Gold =:= 0) ->
            {fail, 2};
        [GoodsTypeId,Coin,Gold] ->
            GoodsTypeInfo = data_goods_type:get(GoodsTypeId),
            if  %% 物品类型错误
                is_record(GoodsTypeInfo, ets_goods_type) =:= false ->
                    {fail, 3};
                %% 金钱不足
                Coin > 0 andalso PlayerStatus#player_status.coin < Coin ->
                    {fail, 4};
                %% 金钱不足
                Gold > 0 andalso PlayerStatus#player_status.gold < Gold ->
                    {fail, 4};
                %% 正在交易中
                Sell#status_sell.sell_status =/= 0 ->
                    {fail, 5};
                %% 玩家错误
                PlayerId =< 0 orelse PlayerStatus#player_status.id =:= PlayerId ->
                    {fail, 6};
                true ->
                    {ok, GoodsTypeInfo, Coin, Gold}
            end
    end.

%% 幸运转盘
check_lucky_box(PlayerStatus, GoodsStatus, GoodsId) ->
    Sell = PlayerStatus#player_status.sell,
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        GoodsInfo#goods.num < 1 ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
            {fail, 3};
        %% 物品位置不正确
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品类型不正确
        GoodsInfo#goods.type =/= 61 orelse GoodsInfo#goods.subtype =/= 36 ->
            {fail, 5};
        %% 正在交易中
        Sell#status_sell.sell_status =/= 0 ->
            {fail, 6};
        %% 背包格子不足
        length(GoodsStatus#goods_status.null_cells) =:= 0 ->
            {fail, 8};
        true ->
            case data_lucky_box:get_goods_list() of
                %% 没有配置信息
                [] -> {fail, 7};
                GoodsList ->
                    {ok, GoodsInfo, GoodsList}
            end
    end.

%% 刷新神秘商店 1元宝刷新, 2物品刷新， 3免费刷新, 4自动刷新
check_refresh_secret(PlayerStatus, GoodsStatus, Type, GoodsId, Num) ->
    if Type =:= 1 ->
        %% 元宝刷新
            Sell = PlayerStatus#player_status.sell,
            if  %% 正在交易中
                Sell#status_sell.sell_status =/= 0 ->
                    {fail, 6};
                %% 元宝不足
                Num < 1 orelse PlayerStatus#player_status.gold < (10*Num) ->
                    {fail, 8};
                true ->
                    case mod_disperse:call_to_unite(mod_secret_shop, get_shop_list, [PlayerStatus#player_status.id]) of
                        %% 商店信息不存在
                        [] -> 
                            {fail, 7};
                        [ShopInfo] ->
                            {ok, ShopInfo, #goods{}}
                    end
            end;
        %% 物品刷新
        Type =:= 2 ->
            GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
            Sell = PlayerStatus#player_status.sell,
            if  %% 物品不存在
                is_record(GoodsInfo, goods) =:= false ->
                    {fail, 2};
                Num < 1 orelse GoodsInfo#goods.num < Num ->
                    {fail, 2}; %% 物品不属于你所有
                GoodsInfo#goods.player_id =/= PlayerStatus#player_status.id ->
                    {fail, 3};
                %% 物品位置不正确
                GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
                    {fail, 4};
                %% 物品类型不正确
                GoodsInfo#goods.type =/= 61 orelse GoodsInfo#goods.subtype =/= 35 ->
                    {fail, 5};
                %% 正在交易中
                Sell#status_sell.sell_status =/= 0 ->
                    {fail, 6};
                true ->
                    case mod_disperse:call_to_unite(mod_secret_shop, get_shop_list, [PlayerStatus#player_status.id]) of
                        %% 商店信息不存在
                        [] -> 
                            {fail, 7};
                        [ShopInfo] ->
                            {ok, ShopInfo, GoodsInfo}
                    end
            end;
       Type =:= 3 ->
           %%免费刷新
           case mod_disperse:call_to_unite(mod_secret_shop, get_shop_list, [PlayerStatus#player_status.id]) of
                %% 商店信息不存在
                [] -> 
                    {fail, 7};
                [ShopInfo] ->
                    case mod_daily_dict:get_count(PlayerStatus#player_status.id, 8001) > 3 of
%%                    case ShopInfo#ets_secret_shop.free_time =< 0 of
                        true ->
                            %% 免费次数用完
                            {fail, 9};
                        false ->
                            {ok, ShopInfo, #goods{}}
                    end
           end;
        Type =:= 4 ->   %%定时自动刷新
            case mod_disperse:call_to_unite(mod_secret_shop, get_shop_list, [PlayerStatus#player_status.id]) of
                [] ->
                    {fail, 7};
                [ShopInfo] ->
                    {RefreshTime,_} = pp_secret_shop:refresh_second(mod_daily_dict:get_count(PlayerStatus#player_status.id, 8002)),
                    case RefreshTime > 0 of
                        true ->
                            %% 未到刷新时间
                            {fail, 0};
                        false ->
                            {ok, ShopInfo, #goods{}}
                    end
            end;
        true ->
            {fail, 10}   %%类型不存在 
    end.

%% 购买神秘商店物品
check_pay_secret(PlayerStatus, GoodsStatus, GoodsId, Num) ->
    case mod_disperse:call_to_unite(mod_secret_shop, get_shop_list, [PlayerStatus#player_status.id]) of
        %% 商店信息不存在
        [] -> {fail, 2};
        [ShopInfo] ->
            Sell = PlayerStatus#player_status.sell,
            case lists:keyfind(GoodsId, 2, ShopInfo#ets_secret_shop.goods_list) of
                %% 找不到物品
                false -> {fail, 3};
                ShopGoods when is_record(ShopGoods, base_secret_shop) =:= false ->
                    {fail, 3};
                %% 价格错误
                ShopGoods when ShopGoods#base_secret_shop.price =< 0 ->
                    {fail, 4};
                %% 价格不足
                ShopGoods when ShopGoods#base_secret_shop.price_type =:=1 andalso PlayerStatus#player_status.gold < (ShopGoods#base_secret_shop.price*Num) ->
                    {fail, 5};
                ShopGoods when ShopGoods#base_secret_shop.price_type =:=2 andalso (PlayerStatus#player_status.gold+PlayerStatus#player_status.bgold) < (ShopGoods#base_secret_shop.price*Num) ->
                    {fail, 5};
                ShopGoods when ShopGoods#base_secret_shop.price_type =:=3 andalso (PlayerStatus#player_status.coin+PlayerStatus#player_status.bcoin) < (ShopGoods#base_secret_shop.price*Num) ->
                    {fail, 5};
                %% 正在交易中
                _ShopGoods when Sell#status_sell.sell_status =/= 0 ->
                    {fail, 7};
                %% 数量错误
                ShopGoods when Num < 1 orelse ShopGoods#base_secret_shop.goods_num < Num ->
                    {fail, 8};
                ShopGoods ->
                    case data_goods_type:get(GoodsId) of
                        [] -> {fail, 3};
                        GoodsTypeInfo ->
                            CellNum = lib_storage_util:get_null_cell_num([], GoodsTypeInfo#ets_goods_type.max_overlap, Num),
                            case length(GoodsStatus#goods_status.null_cells) < CellNum of
                                %% 背包格子不足
                                true -> 
                                    {fail, 6};
                                false -> 
                                    {ok, ShopInfo, ShopGoods, GoodsTypeInfo}
                            end
                    end
             end
    end.

%%　购买物品
check_pay(PlayerStatus, GoodsStatus, GoodsTypeId, GoodsNum, ShopType, ShopSubtype, PayMoneyType) ->
    ShopInfo = mod_disperse:call_to_unite(lib_shop, get_shop_info, [ShopType, ShopSubtype, GoodsTypeId]), 
    GoodsTypeInfo = data_goods_type:get(GoodsTypeId),
    case is_record(GoodsTypeInfo, ets_goods_type) andalso is_record(ShopInfo, ets_shop) of
        %% 物品不存在
        false -> {fail, ?ERRCODE15_NO_GOODS};
        true ->
            if  
                ShopInfo#ets_shop.shop_type =:= ?SHOP_TYPE_GOLD andalso ShopInfo#ets_shop.shop_subtype =:= ?SHOP_SUBTYPE_POINT ->
                    Flag = case util:check_open_day(7) of
                               true -> 0;
                               false -> 1
                           end;
                true ->
                    Flag = 0
            end,
            case check_npc(PlayerStatus, ShopType, pay) of
                %% 离NPC太远
                false -> {fail, ?ERRCODE15_NPC_FAR};
                %% 正在交易中
                true when GoodsStatus#goods_status.sell_status =/= 0  ->
                    {fail, ?ERRCODE15_IN_SELL};
                %% 非武陵城占有帮派的帮众无法购买
                true when ShopInfo#ets_shop.shop_type =:= ?SHOP_TYPE_SIEGE_SHOP andalso Flag < 0 ->
                    {fail, ?ERRCODE15_SIEGE_PAY_ERR};
                %% 物品价格错误
                true when ShopInfo#ets_shop.new_price andalso GoodsTypeInfo#ets_goods_type.price =:= 0  ->
                    {fail, ?ERRCODE15_PRICE_ERR};
                true when ShopType =:= ?SHOP_TYPE_GOLD andalso ShopSubtype >= 50 andalso ShopSubtype =< 65 andalso Flag > 0 ->
                    {fail, ?ERRCODE15_SHOP_TIME_LIMIT};
                %% 物品数量错误
                true when GoodsNum =< 0 ->
                    {fail, ?ERRCODE15_NUM_ERR};
                true ->
                    {PriceType, Price} = data_goods:get_shop_price(ShopInfo, GoodsTypeInfo, PayMoneyType),
                    Cost = Price * GoodsNum,
                    case lib_goods_util:is_enough_money(PlayerStatus, Cost, PriceType) of
                        %% 金额不足
                        false -> {fail, ?ERRCODE15_NO_MONEY};
                        true  -> 
                            NewGoodsTypeInfo = case PriceType of
                                silver_and_gold -> 
                                    case lib_goods_util:is_enough_money(PlayerStatus, Cost, silver) of
                                        true -> GoodsTypeInfo#ets_goods_type{bind = 2, trade = 1};
                                        false -> GoodsTypeInfo
                                    end;
                                silver ->
                                    GoodsTypeInfo#ets_goods_type{bind = 2, trade = 1};
                                bcoin ->
                                    GoodsTypeInfo#ets_goods_type{bind = 2, trade = 1};
                                coin when PlayerStatus#player_status.bcoin > 0 ->
                                    GoodsTypeInfo#ets_goods_type{bind = 2, trade = 1};
                                gold when ShopInfo#ets_shop.shop_subtype >= 50 andalso ShopInfo#ets_shop.shop_subtype =< 65 ->
                                    GoodsTypeInfo#ets_goods_type{bind = 2, trade = 1};
                                point ->
                                    GoodsTypeInfo#ets_goods_type{bind = 2, trade = 1};
                                _ ->
                                    GoodsTypeInfo
                            end,
                            GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, NewGoodsTypeInfo#ets_goods_type.bind, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
                            CellNum = lib_storage_util:get_null_cell_num(GoodsList, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsNum),
                            case length(GoodsStatus#goods_status.null_cells) < CellNum of
                                %%背包格子不足
                                true  -> {fail, ?ERRCODE15_NO_CELL};
                                false ->  {ok, NewGoodsTypeInfo, GoodsList, ShopInfo, Cost}
                            end
                    end
            end
    end.

%% 限时热卖
check_limit_pay(PlayerStatus, GoodsStatus, Pos, GoodsId, GoodsNum) ->
    ShopInfo = mod_disperse:call_to_unite(lib_shop, get_limit_shop_info, [Pos, GoodsId]),
    case is_record(ShopInfo, ets_limit_shop) of
        true ->
            GoodsTypeInfo = data_goods_type:get(ShopInfo#ets_limit_shop.goods_id);
        false ->
            GoodsTypeInfo = []
    end,
    OpenDay = util:get_open_day(),
    NowTime = util:unixtime(),
    MergeTime = lib_activity_merge:get_activity_time(),
    MergeDay = util:get_diff_days(NowTime, MergeTime),
    case is_record(GoodsTypeInfo, ets_goods_type) andalso is_record(ShopInfo, ets_limit_shop) of
        %% 物品不存在
        false -> 
            {fail, ?ERRCODE15_NO_GOODS};
        true ->
            Num = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, ShopInfo#ets_limit_shop.limit_id),
            {LimitNum, BuyType} = lib_shop:get_limit_pay_record_and_type(PlayerStatus#player_status.id, ShopInfo#ets_limit_shop.shop_id),
            if  %% 超过限购数量
		%% 已经买过列表中的物品，再买一件开服物品
		ShopInfo#ets_limit_shop.time_end > 0 andalso BuyType =:= 0 andalso LimitNum =/= 0 andalso ShopInfo#ets_limit_shop.list_id =/= LimitNum + 1 ->
                %% (ShopInfo#ets_limit_shop.time_end > 0 orelse ShopInfo#ets_limit_shop.merge_end > 0) andalso LimitNum =/= 0 andalso ShopInfo#ets_limit_shop.list_id =/= LimitNum + 1 ->
                    {fail, ?ERRCODE15_SHOP_TIME_LIMIT};
		%% 已经买过列表中的物品，再买一件合服物品
		ShopInfo#ets_limit_shop.merge_end > 0 andalso BuyType =:= 1 andalso LimitNum =/= 0 andalso ShopInfo#ets_limit_shop.list_id =/= LimitNum + 1 ->
		    {fail, ?ERRCODE15_SHOP_TIME_LIMIT};
		%% 非开服或者合服物品，超出购买限制
                Num >= ShopInfo#ets_limit_shop.limit_num andalso ShopInfo#ets_limit_shop.time_end =< 0 andalso ShopInfo#ets_limit_shop.merge_end =< 0 ->
                    {fail, ?ERRCODE15_SHOP_TIME_LIMIT};
                (OpenDay =< ?OPEN_DAYS orelse (MergeTime =/= 0 andalso MergeDay =< ?MERGE_DAYS)) andalso Num =:= 0 andalso Pos > 6 ->
                    {fail, ?ERRCODE15_SHOP_TIME_LIMIT};
                %% 物品已经卖完
                ShopInfo#ets_limit_shop.goods_num =< 0 ->
                    {fail, ?ERRCODE15_GOODS_NUM_ZERO};
                %% 物品价格错误
                ShopInfo#ets_limit_shop.new_price andalso GoodsTypeInfo#ets_goods_type.price =:= 0  ->
                    {fail, ?ERRCODE15_PRICE_ERR};
                %% 物品数量错误
                GoodsNum =< 0 ->
                    {fail, ?ERRCODE15_NUM_ERR};
                %% 正在交易
                GoodsStatus#goods_status.sell_status =/= 0  ->
                    {fail, ?ERRCODE15_IN_SELL};
                true ->
                    NewGoodsTypeInfo = GoodsTypeInfo#ets_goods_type{bind = 2, trade = 1},
                    GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, ShopInfo#ets_limit_shop.goods_id, NewGoodsTypeInfo#ets_goods_type.bind, 
                                                                   ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
                    CellNum = lib_storage_util:get_null_cell_num(GoodsList, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsNum),
                    case ShopInfo#ets_limit_shop.price_type of
                        1 -> %% 元宝
                            PriceType = gold;
                        2 -> %% 绑定元宝
                            PriceType = silver
                    end,
                    case length(GoodsStatus#goods_status.null_cells) < CellNum of
                        %%背包格子不足
                        true -> 
                            {fail, ?ERRCODE15_NO_CELL};
                        false ->
                            Cost = ShopInfo#ets_limit_shop.new_price * GoodsNum,
                            case lib_goods_util:is_enough_money(PlayerStatus, Cost, PriceType) of
                                %% 金额不足
                                false -> 
                                    {fail, ?ERRCODE15_NO_MONEY};
                                true -> 
                                    {ok, NewGoodsTypeInfo, GoodsList, ShopInfo}
                            end
                    end
            end
    end.

%% 出售物品
check_sell(PlayerStatus, _NpcId, GoodsList, GoodsStatus) ->
    Sell = PlayerStatus#player_status.sell,
    %case check_npc(PlayerStatus, NpcId, sell) of
        %% 离NPC太远
    %    false -> {fail, ?ERRCODE15_NPC_FAR};
        %% 正在交易中
    if Sell#status_sell.sell_status =/= 0  ->
            {fail, ?ERRCODE15_IN_SELL};
        true ->
            %% 物品列表一个个检查
            case list_handle(fun check_sells/2, [PlayerStatus#player_status.id, 0, 0, [], GoodsStatus], GoodsList) of
                {fail, Res} -> 
                    {fail, Res};
                {ok, [_, NewCoin, NewBcoin, NewGoodsList, _]} ->
                    {ok, NewCoin, NewBcoin, NewGoodsList}
            end
    end.

check_sells({GoodsId, GoodsNum}, [PlayerId, Coin, _Bcoin, GoodsList, GoodsStatus]) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, ?ERRCODE15_NO_GOODS};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= PlayerId ->
            {fail, ?ERRCODE15_PALYER_ERR};
        %% 物品不在背包
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, ?ERRCODE15_LOCATION_ERR};
        %% 物品不可出售
        GoodsInfo#goods.sell =:= 1 ->
            {fail, ?ERRCODE15_NOT_SELL};
        %% 物品数量不足
        GoodsNum < 1 orelse GoodsInfo#goods.num < GoodsNum ->
            {fail, ?ERRCODE15_NUM_ERR};
        true ->
            NewBcoin = 0,
            NewCoin  = Coin + GoodsInfo#goods.sell_price * GoodsNum,
            %case  GoodsInfo#goods.bind > 0 of
            %    true ->
            %        NewBcoin = Bcoin + GoodsInfo#goods.sell_price * GoodsNum,
            %        NewCoin = Coin;
            %    false ->
            %        NewBcoin = Bcoin,
            %        NewCoin = Coin + GoodsInfo#goods.sell_price * GoodsNum
            %end,
            {ok, [PlayerId, NewCoin, NewBcoin, [{GoodsInfo,GoodsNum}|GoodsList], GoodsStatus]}
    end.

check_movein_guild(GoodsStatus, GuildId, GuildMaxNum, GoodsId, GoodsNum) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
            {fail, 3};
        %% 物品不在背包
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品数量不正确
        GoodsNum < 1 orelse GoodsInfo#goods.num < GoodsNum ->
            {fail, 5};
        %% 绑定物品不可放入
        GoodsInfo#goods.bind =:= 2 ->
            {fail, 6};
        %% 正在交易中
        GoodsStatus#goods_status.sell_status =/= 0 ->
            {fail, 8};
        GoodsInfo#goods.bind =/= 0 ->
            {fail, ?ERRCODE15_REQUIRE_ERR};
        true ->
            GoodsTypeId = GoodsInfo#goods.goods_id,
            case data_goods_type:get(GoodsTypeId) of
                %% 物品类型不存在
                [] ->
                    {fail, 2};
                GoodsTypeInfo ->
                    TotalNum = lib_storage_util:get_storage_count(GoodsStatus#goods_status.player_id, GuildId),
                    TypeNum = lib_storage_util:get_storage_type_count(GoodsStatus#goods_status.player_id, GuildId, GoodsTypeId, GoodsInfo#goods.bind),
                    CellNum = lib_storage_util:get_null_storage_num(TypeNum, GoodsNum, GoodsTypeInfo#ets_goods_type.max_overlap),
                    if
                        %% 帮派仓库格子不足
                        GuildMaxNum < (TotalNum + CellNum) ->
                            {fail, 7};
                        true ->
                            NewGoodsInfo = GoodsInfo#goods{ player_id=0, guild_id=GuildId },
                            {ok, NewGoodsInfo, GoodsTypeInfo}
                    end
            end
    end.

check_moveout_guild(GoodsStatus, GuildId, GoodsId, GoodsNum) ->
    GoodsInfo = lib_goods_util:get_goods_by_id(GoodsId),
    if  %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于你所有
        GoodsInfo#goods.guild_id =/= GuildId ->
            {fail, 3};
        %% 物品不在背包
        GoodsInfo#goods.location =/= ?GOODS_LOC_GUILD ->
            {fail, 4};
        %% 物品数量不正确
        GoodsNum < 1 orelse GoodsInfo#goods.num < GoodsNum ->
            {fail, 5};
        %% 正在交易中
        GoodsStatus#goods_status.sell_status =/= 0 ->
            {fail, 8};
        true ->
            GoodsTypeId = GoodsInfo#goods.goods_id,
            case data_goods_type:get(GoodsTypeId) of
                %% 物品类型不存在
                [] ->
                    {fail, 2};
                GoodsTypeInfo ->
                    TypeList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsInfo#goods.goods_id, 2, 
                                                                  ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
                    GoodsTypeList = lib_goods_util:sort(TypeList, cell),
                    CellNum = lib_storage_util:get_null_cell_num(GoodsTypeList, GoodsTypeInfo#ets_goods_type.max_overlap, GoodsNum),
                    if  %% 背包格子不足
                        length(GoodsStatus#goods_status.null_cells) < CellNum ->
                            {fail, 6};
                        true ->
                            %NewGoodsInfo = GoodsInfo#goods{ player_id=GoodsStatus#goods_status.player_id, guild_id=0, bind=2, trade=1 },
                            {ok, GoodsInfo, GoodsTypeInfo, GoodsTypeList}
                    end
            end
    end.

check_delete_guild(GuildId, GoodsId) ->
    GoodsInfo = lib_goods_util:get_goods_by_id(GoodsId),
    if
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于帮派所有
        GoodsInfo#goods.guild_id =/= GuildId ->
            {fail, 3};
        %% 物品不在帮派仓库
        GoodsInfo#goods.location =/= ?GOODS_LOC_GUILD ->
            {fail, 4};
        %% 物品不可丢弃
        GoodsInfo#goods.isdrop =:= 1 ->
            {fail, 5};
        true ->
            {ok, GoodsInfo, GoodsInfo#goods.num}
    end.

check_extend_guild(PlayerStatus, GuildLevel, GoodsStatus) ->
    [GoldNum, GoodsNum] = data_goods:get_extend_guild(GuildLevel),
    if
        %% 帮派仓库已达上限
        GuildLevel >= ?GOODS_GUILD_MAX_LEVEL ->
            {fail, 2};
        %% 铜钱不足
        (PlayerStatus#player_status.coin + PlayerStatus#player_status.bcoin) < GoldNum ->
            {fail, 3};
        true ->
            GoodsTypeList = lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id, ?GOODS_GUILD_EXTEND_MATERIAL, 
                                                               ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
            TotalNum = lib_goods_util:get_goods_totalnum(GoodsTypeList),
            if
                %% 建设卡数量不足
                TotalNum < GoodsNum ->
                    {fail, 4};
                true ->
                    {ok, GoldNum, GoodsNum, GoodsTypeList}
            end
    end.
	

check_movein_mail(GoodsStatus, GoodsId, GoodsNum) ->
    GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
    if
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品不属于该玩家所有
        GoodsInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
            {fail, 3};
        %% 物品不在背包
        GoodsInfo#goods.location =/= ?GOODS_LOC_BAG ->
            {fail, 4};
        %% 物品数量不正确
        GoodsNum < 1 orelse GoodsInfo#goods.num < GoodsNum ->
            {fail, 5};
        %% 物品不可交易
        GoodsInfo#goods.bind =:= 2 orelse GoodsInfo#goods.trade =:= 1 ->
            {fail, 6};
        %% 正在交易中
        GoodsStatus#goods_status.sell_status =/= 0 ->
            {fail, 8};
        true ->
            {ok, GoodsInfo}
    end.
    
check_moveout_mail(GoodsStatus, GoodsId) ->
    GoodsInfo = lib_goods_util:get_goods_by_id(GoodsId),
    if
        %% 物品不存在
        is_record(GoodsInfo, goods) =:= false ->
            {fail, 2};
        %% 物品已有玩家
        GoodsInfo#goods.player_id =/= GoodsStatus#goods_status.player_id ->
            {fail, 3};
        %% 物品不在附件
        GoodsInfo#goods.location =/= ?GOODS_LOC_MAIL ->
            {fail, 4};
        %% 背包格子不足
        length(GoodsStatus#goods_status.null_cells) =:= 0 ->
            {fail, 5};
        %% 正在交易中
        GoodsStatus#goods_status.sell_status =/= 0 ->
            {fail, 8};
        true ->
            {ok, GoodsInfo}
    end.

%% VIP升级
check_vip_band(PlayerStatus, GoodsStatus, GoodsTypeId) ->
    case data_goods_type:get(GoodsTypeId) of
        [] ->
            %%物品不存在
            {fail, 2};
        GoodsTypeInfo ->
            if
                is_record(GoodsTypeInfo, ets_goods_type) =:= false ->
                    %% 物品类型不对
                    {fail, 3};
                PlayerStatus#player_status.gold < GoodsTypeInfo#ets_goods_type.price ->
                    %% 元宝不足
                    {fail, 4};
                %% 背包格子不足
                length(GoodsStatus#goods_status.null_cells) =:= 0 ->
                    {fail, 5};
                true ->
                    {ok, GoodsTypeInfo}
            end
    end.

%% 扩展背包
check_expand_bag(PlayerStatus, Type, Num, Gold) ->
    case Type of
        1 -> % 背包
            if
                %% 超过最大数
                PlayerStatus#player_status.cell_num + Num > ?GOODS_BAG_MAX_NUM ->
                    {fail, 2};
                %% 元宝不够
                PlayerStatus#player_status.gold < Gold ->
                    {fail, 3};
                %% 数量不对
                Num =< 0 orelse Gold =< 0 ->
                    {fail, 4};
                true ->
                    {ok}
            end;
        2 -> % 仓库
            if
                %% 超过最大数
                PlayerStatus#player_status.storage_num + Num > ?GOODS_STORAGE_MAX_NUM ->
                    {fail, 2};
                %% 元宝不够
                PlayerStatus#player_status.gold < Gold ->
                    {fail, 3};
                %% 数量不对
                Num =< 0 orelse Gold =< 0 ->
                    {fail, 4};
                true ->
                    {ok}
            end;
        _ ->
            skip
    end.



	



