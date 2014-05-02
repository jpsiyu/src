%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-16
%% Description: 物品基础信息call
%% --------------------------------------------------------
-module(mod_goods_call).
-export([handle_call/3, wear_equip_in_gift/3]).
-include("goods.hrl").
-include("gift.hrl").
-include("common.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("errcode_goods.hrl").
-include("server.hrl").
-include("drop.hrl").

%% 取物品状态
handle_call({'get_goods_status'}, _From, GoodsStatus) ->
	{reply, GoodsStatus, GoodsStatus};

%%删除背包物品
handle_call({'delete_one', GoodsId, GoodsNum}, _From, GoodsStatus) ->
    case lib_goods_check:check_delete(GoodsStatus, GoodsId, GoodsNum) of
        {fail, Res} ->
            {reply, Res, GoodsStatus};
        {ok, GoodsInfo} ->
            case lib_goods:delete_one(GoodsInfo, [GoodsStatus, GoodsNum]) of
                [NewStatus, _] ->
                    lib_player:refresh_client(NewStatus#goods_status.player_id, 2),
                    {reply, 1, NewStatus};
                Error ->
                    util:errlog("mod_goods delete_one:~p", [Error]),
                    {reply, 0, GoodsStatus}
            end
    end;

%%删除背包物品
handle_call({'delete_one_norefresh', GoodsTypeId, GoodsNum}, _From, GoodsStatus) ->
    GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, 
                                                   ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
    TotalNum = lib_goods_util:get_goods_totalnum(GoodsList),
    if 
        %% 物品不存在
        length(GoodsList) =:= 0 ->
            {reply, 2, GoodsStatus};
        %% 物品数量不足
        TotalNum < GoodsNum orelse GoodsNum =< 0 ->
            {reply, 3, GoodsStatus};
        true ->
            case lib_goods:delete_more(GoodsStatus, GoodsList, GoodsNum) of
                {ok, NewStatus} ->
                     {reply, 1, NewStatus};
                 Error ->
                     util:errlog("mod_goods delete_more:~p", [Error]),
                     {reply, 0, GoodsStatus}
            end
    end;

%%删除多个同类型物品
handle_call({'delete_more', GoodsTypeId, GoodsNum}, _From, GoodsStatus) ->
    GoodsList = lib_goods_util:get_type_goods_list(GoodsStatus#goods_status.player_id, GoodsTypeId, 
                                                   ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
    TotalNum = lib_goods_util:get_goods_totalnum(GoodsList),
    if 
        %% 物品不存在
        length(GoodsList) =:= 0 ->
            {reply, 2, GoodsStatus};
        %% 物品数量不足
        TotalNum < GoodsNum orelse GoodsNum =< 0 ->
            {reply, 3, GoodsStatus};
        true ->
            case lib_goods:delete_more(GoodsStatus, GoodsList, GoodsNum) of
                {ok, NewStatus} ->
                     lib_player:refresh_client(GoodsStatus#goods_status.player_id, 2),
                     {reply, 1, NewStatus};
                 Error ->
                     util:errlog("mod_goods delete_more:~p", [Error]),
                     {reply, 0, GoodsStatus}
            end
    end;

%%删除背包物品列表
%% GoodsList = [{GoodsId, GoodsNum}, ...]
handle_call({'delete_list', GoodsList}, _From, GoodsStatus) ->
    case lib_goods_check:check_delete_list(GoodsStatus, GoodsList) of
        {fail, Res} ->
            {reply, Res, GoodsStatus};
        {ok, NewGoodsList} ->
            F = fun() ->
                    ok = lib_goods_dict:start_dict(),
                    {ok, NewStatus} = lib_goods:delete_goods_list(GoodsStatus, NewGoodsList),
                     Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                    NewStatus2 = NewStatus#goods_status{dict = Dict},
                    {ok, NewStatus2}
                end,
            case lib_goods_util:transaction(F) of
                {ok, NewStatus} ->
                    lib_player:refresh_client(NewStatus#goods_status.player_id, 2),
                    {reply, 1, NewStatus};
                Error ->
                    util:errlog("mod_goods delete_list:~p", [Error]),
                    {reply, 0, GoodsStatus}
            end
    end;

%%获取物品详细信息
handle_call({'info', GoodsId}, _From, GoodsStatus) ->
	GoodsInfo = lib_goods_util:get_goods_info(GoodsId, GoodsStatus#goods_status.dict),
	case is_record(GoodsInfo, goods) of
		% 坐骑
		true when GoodsInfo#goods.type =:= ?GOODS_TYPE_MOUNT andalso GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_MOUNT_CARD ->
            AttributeList = GoodsInfo#goods.addition_1+GoodsInfo#goods.addition_2+GoodsInfo#goods.addition_3,
            {reply, [GoodsInfo, 0, AttributeList], GoodsStatus};
        true when GoodsInfo#goods.player_id == GoodsStatus#goods_status.player_id ->
            AttributeList = data_goods:get_goods_attribute(GoodsInfo),
            SuitNum = lib_goods_util:get_suit_num(GoodsStatus#goods_status.equip_suit, GoodsInfo#goods.suit_id),
            case GoodsInfo#goods.location =:= ?GOODS_LOC_STORAGE of
                true -> 
                    NewDict = lib_goods_dict:add_dict_goods(GoodsInfo, GoodsStatus#goods_status.dict),
                    NewGoodsStatus = GoodsStatus#goods_status{dict = NewDict};
                false -> 
                    NewGoodsStatus = GoodsStatus
            end,
            {reply, [GoodsInfo, SuitNum, AttributeList], NewGoodsStatus};
        _Error ->
            {reply, [{}, 0, []], GoodsStatus}
    end;

%% 查询别人物品详细信息
handle_call({'info_other', GoodsId}, _From, GoodsStatus) ->
	GoodsInfo = lib_goods_util:get_goods_info(GoodsId, GoodsStatus#goods_status.dict),
	case is_record(GoodsInfo, goods) of
		% 坐骑
		%true when GoodsInfo#goods.type =:= ?GOODS_TYPE_MOUNT andalso GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_MOUNT_CARD ->
            %AttributeList = data_goods:get_mount_attribute(GoodsInfo),
        %    {reply, [GoodsInfo, 0, []], GoodsStatus};
        true ->
            AttributeList = data_goods:get_goods_attribute(GoodsInfo),
            SuitNum = 0,
            {reply, [GoodsInfo, SuitNum, AttributeList], GoodsStatus};
        false ->
            {reply, [#goods{}, 0, []], GoodsStatus}
    end;

%% 获取要修理装备列表 
handle_call({'mend_list'}, _From, GoodsStatus) ->
	MendList = lib_goods_util:get_mend_list(GoodsStatus#goods_status.player_id, GoodsStatus#goods_status.dict),
	{reply, MendList, GoodsStatus};

%%装备物品
handle_call({'equip', PlayerStatus, GoodsId, Cell}, _From, GoodsStatus) ->
	case lib_goods_check:check_equip(PlayerStatus, GoodsId, Cell, GoodsStatus) of
		{fail, Res} ->
			{reply, [PlayerStatus, Res, {}, {}], GoodsStatus};
		{ok, GoodsInfo, Location, NewCell} ->
			case lib_goods:equip_goods(PlayerStatus, GoodsStatus, GoodsInfo, Location, NewCell) of
                {ok, NewPlayerStatus, NewStatus, OldGoodsInfo} ->
					{reply, [NewPlayerStatus, ?ERRCODE_OK, GoodsInfo, OldGoodsInfo], NewStatus};
                 Error ->
                     util:errlog("mod_goods equip:~p", [Error]),
                     {reply, [PlayerStatus, ?ERRCODE15_FAIL, {}], GoodsStatus}
            end
    end;

%% 直接从礼包装备上去
handle_call({'equip2', PlayerStatus, GoodsTypeId}, _From, GoodsStatus) ->
	case lib_goods_check:add_equip_by_typeid(GoodsTypeId, GoodsStatus) of
		{fail, Res} ->
			{reply, [PlayerStatus, Res], GoodsStatus};
		{ok, GoodsInfo, Cell, NewGoodsStatus} ->
            case lib_goods_check:check_equip(PlayerStatus, GoodsInfo#goods.id, Cell, NewGoodsStatus) of
                {fail, Res} ->
			        {reply, [PlayerStatus, Res, NewGoodsStatus]};
		        {ok, GoodsInfo, Location, NewCell} ->
			        case lib_goods:equip_goods(PlayerStatus, NewGoodsStatus, GoodsInfo, Location, NewCell) of
                        {ok, NewPlayerStatus, NewStatus, _OldGoodsInfo} ->
					        {reply, [NewPlayerStatus, ?ERRCODE_OK], NewStatus};
                        Error ->
                            util:errlog("mod_goods equip2:~p", [Error]),
                            {reply, [PlayerStatus, ?ERRCODE15_FAIL], NewGoodsStatus}
                    end
            end
    end;



%% 缷下装备
handle_call({'unequip', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
	case lib_goods_check:check_unequip(PlayerStatus, GoodsStatus, GoodsId) of
		{fail, Res} ->
			{reply, [PlayerStatus, Res, {}], GoodsStatus};
		{ok, GoodsInfo} ->
			case (catch lib_goods:unequip_goods(PlayerStatus, GoodsStatus, GoodsInfo)) of
				{ok, NewPlayerStatus, NewGoodsStatus, NewGoodsInfo} ->
					{reply, [NewPlayerStatus, ?ERRCODE_OK, NewGoodsInfo], NewGoodsStatus};
				Error ->
					util:errlog("mod_goods call unequip error:~p~n", [Error]),
					{reply, [PlayerStatus, ?ERRCODE_FAIL, {}], GoodsStatus}
			end
	end;

%% 修理装备
handle_call({'mend', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
	GoodsInfo = lib_goods_util:get_goods(GoodsId, GoodsStatus#goods_status.dict),
	case lib_goods_check:check_mend_list(PlayerStatus, [GoodsInfo]) of	%检查
		{fail, Res} ->
			{reply, [PlayerStatus, Res, {}, 0], GoodsStatus};
		{ok} ->
			case lib_goods:mend_goods(PlayerStatus, GoodsStatus, GoodsInfo) of	%修理
				{ok, NewPlayerStatus, NewGoodsStatus, Cost} ->
					{reply, [NewPlayerStatus, ?ERRCODE_OK, GoodsInfo, Cost], NewGoodsStatus};
				Error ->
					util:errlog("handle_call mend_goods error:~p", [Error]),
					{reply, [PlayerStatus, ?ERRCODE_FAIL, {}, 0], GoodsStatus}
			end;
		_Error ->
			util:errlog("handle_call mend error:~p", [_Error])
	end;		

%% 修理全部装备
handle_call({'mend_all', PlayerStatus}, _From, GoodsStatus) ->
	GoodsList = lib_goods_util:get_mend_list(PlayerStatus#player_status.id, GoodsStatus#goods_status.dict),
	case lib_goods_check:check_mend_list(PlayerStatus, GoodsList) of 		%检查
		{fail, Res} ->
			{reply, [PlayerStatus, Res, 0], GoodsStatus};
		{ok} ->
			case lib_goods:mend_goods_list(PlayerStatus, GoodsStatus, GoodsList) of 	%修理
				{ok, NewPlayerStatus, NewStatus, Cost} ->
					{reply, [NewPlayerStatus, ?ERRCODE_OK, Cost], NewStatus};
				Error ->
					util:errlog("handle_call 15035 lib_goods:mend_goods_list error:~p", [Error]),
					{reply, [PlayerStatus, ?ERRCODE_FAIL, 0], GoodsStatus}
			end
	end;

%%背包拖动物品
handle_call({'drag_goods', PlayerStatus, GoodsId, OldCell, NewCell}, _From, GoodsStatus) ->
	%检查
	case lib_goods_check:check_drag_goods(GoodsStatus, GoodsId, OldCell, NewCell, PlayerStatus#player_status.cell_num) of
		{fail, Res} ->
			{reply, [Res, #goods{}, #goods{}], GoodsStatus};
		{ok, GoodsInfo} ->
			%拖动
			case lib_goods:drag_goods(GoodsStatus, GoodsInfo, OldCell, NewCell) of
				{ok, NewStatus, [NewGoodsInfo1, NewGoodsInfo2]} ->
					{reply, [?ERRCODE_OK, NewGoodsInfo1, NewGoodsInfo2], NewStatus};
				Error ->
					util:errlog("handle_call 15040 lib_goods:drag_goods error:~p", [Error]),
					{reply, [?ERRCODE_FAIL, #goods{}, #goods{}], GoodsStatus}
			end
	end;

%%物品存入仓库
handle_call({'movein_storage', PlayerStatus, NpcId, GoodsId, Num}, _From, GoodsStatus) ->
	% 物品检查
	case lib_storage_util:check_movein_storage(PlayerStatus, NpcId, GoodsId, Num, GoodsStatus) of
		{fail, Res} ->
			{reply, Res, GoodsStatus};
		{ok, GoodsInfo, GoodsTypeInfo} ->	%正确
			case lib_storage_util:movein_storage(GoodsStatus, GoodsInfo, Num, ?GOODS_LOC_STORAGE, GoodsTypeInfo) of
				{ok, NewStatus} ->
					{reply, ?ERRCODE_OK, NewStatus};
				Error ->
					util:errlog("lib_goods:movein_storage error:~p", [Error])
			end
	end;

%%从仓库取出物品
handle_call({'moveout_storage', PlayerStatus, NpcId, GoodsId, Num}, _From, GoodsStatus) ->
	% 物品检查
	case lib_storage_util:check_moveout_storage(PlayerStatus, GoodsStatus, NpcId, GoodsId, Num) of
		{fail, Res} ->
			{reply, [Res, []], GoodsStatus};
		{ok, GoodsInfo, GoodsTypeInfo, GoodsTypeList} ->
			case lib_storage_util:moveout_storage(GoodsStatus, GoodsInfo, Num, ?GOODS_LOC_BAG, GoodsTypeInfo, GoodsTypeList) of
                {ok, NewStatus} ->
                    GoodsList = lib_goods_util:get_type_goods_list(GoodsInfo#goods.player_id, GoodsInfo#goods.goods_id, 
																	GoodsInfo#goods.bind, ?GOODS_LOC_BAG, NewStatus#goods_status.dict),
                    {reply, [?ERRCODE_OK, GoodsList], NewStatus};
                Error ->
                    util:errlog("mod_goods moveout_storage erroe:~p", [Error]),
                    {reply, [?ERRCODE15_FAIL, []], GoodsStatus}
            end
    end;

%% 使用物品
handle_call({'use_goods', PlayerStatus, GoodsId, GoodsNum}, _From, GoodsStatus) ->
	%% 检查
	case lib_goods_check:check_use_goods(PlayerStatus, GoodsId, GoodsNum, GoodsStatus) of
		{fail, Res} ->
            {reply, [PlayerStatus, Res, #goods{}, 0, []], GoodsStatus};
		{ok, GoodsInfo, GiftInfo} ->
			case GoodsInfo#goods.type of
				?GOODS_TYPE_GIFT -> %53 使用礼包物品
					case lib_gift_new:use_gift(PlayerStatus, GoodsStatus, GoodsInfo, GiftInfo, GoodsNum) of
						{ok, NewPlayerStatus, NewStatus, NewNum, GiveList} ->
							lib_gift:send_gift_item_notice(NewPlayerStatus, GiftInfo#ets_gift.id, GiftInfo#ets_gift.goods_id, GiveList),
                            {reply, [NewPlayerStatus, ?ERRCODE_OK, GoodsInfo, NewNum, []], NewStatus};
						_Error ->
                            %util:errlog("mod_goods use_gift error:~p", [Error]),
                            {reply, [PlayerStatus, ?ERRCODE15_FAIL, #goods{}, 0, []], GoodsStatus}
                    end;
				_ ->  
                    GoodsList = lib_goods_util:get_equip_list(PlayerStatus#player_status.id, ?GOODS_TYPE_EQUIP, ?GOODS_LOC_EQUIP, GoodsStatus#goods_status.dict),
                    %使用物品
					case lib_goods_use:use_goods(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum) of
						{ok, NewPlayerStatus, NewStatus, NewNum} ->
                            %% 日志
                            if  %% 气血
                                GoodsInfo#goods.type =:= ?GOODS_TYPE_DRUG andalso GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_HP -> skip;
                                %% 内力
                                GoodsInfo#goods.type =:= ?GOODS_TYPE_DRUG andalso GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_MP -> skip;
                                true ->
                                    log:log_throw(goods_use,
                                        PlayerStatus#player_status.id,
                                        GoodsInfo#goods.id,
                                        GoodsInfo#goods.goods_id, GoodsNum,
                                        GoodsInfo#goods.prefix,
                                        GoodsInfo#goods.stren),
									log:log_goods_use(PlayerStatus#player_status.id, GoodsInfo#goods.goods_id, GoodsNum)
                            end,
                            if
                                GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_ARMOR_CHA orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_WEAPON_CHA orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_ACCE_CHA orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_HEAD_CHA orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_TAIL_CHA orelse GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_RING_CHA ->
                                    {ok, NewPS} = lib_goods_util:count_role_equip_attribute(NewPlayerStatus, NewStatus);
                                true ->
                                    NewPS = NewPlayerStatus
                            end,
                            {reply, [NewPS, ?ERRCODE_OK, GoodsInfo, NewNum, GoodsList], NewStatus};
                        {nothing, NewPlayerStatus, NewStatus, NewNum} ->
                            {reply, [NewPlayerStatus, ?ERRCODE15_NOTHING, GoodsInfo, NewNum, GoodsList], NewStatus};
                        {fail, Res2} ->
                            {reply, [PlayerStatus, Res2, GoodsInfo, 0, GoodsList], GoodsStatus};
                        _Error ->
                            %util:errlog("mod_goods use_goods:~p", [_Error]),
                            {reply, [PlayerStatus, ?ERRCODE15_FAIL, #goods{}, 0, GoodsList], GoodsStatus}
                    end
			end
	end;

%% 销毁物品
handle_call({'throw', GoodsId, GoodsNum}, _From, GoodsStatus) ->
	case lib_goods_check:check_throw(GoodsStatus, GoodsId, GoodsNum) of
		{fail, Res} ->
			{reply, Res, GoodsStatus};
		{ok, GoodsInfo} ->
			case lib_goods:delete_one(GoodsStatus, GoodsInfo, GoodsNum) of
				{ok, NewStatus, _NewNum} ->
					if  %% 紫色以下装备忽略
                        GoodsInfo#goods.type =:= ?GOODS_TYPE_EQUIP andalso GoodsInfo#goods.subtype =/= 70 andalso GoodsInfo#goods.color < 3 -> skip;
                        %% 血药忽略
                        GoodsInfo#goods.type =:= ?GOODS_TYPE_DRUG andalso GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_HP -> skip;
                        %% 蓝药忽略
                        GoodsInfo#goods.type =:= ?GOODS_TYPE_DRUG andalso GoodsInfo#goods.subtype =:= ?GOODS_SUBTYPE_MP -> skip;
                        true ->
                            log:log_throw(throw, NewStatus#goods_status.player_id, GoodsInfo#goods.id,
										  GoodsInfo#goods.goods_id, GoodsNum, GoodsInfo#goods.prefix, GoodsInfo#goods.stren)
                    end,
                    lib_player:refresh_client(NewStatus#goods_status.player_id, 2),
                    {reply, ?ERRCODE_OK, NewStatus};
                Error ->
                    util:errlog("mod_goods throw goods:~p", [Error]),
                    {reply, ?ERRCODE15_FAIL, GoodsStatus}
            end
    end;

%% 整理背包
handle_call({'order', PlayerStatus}, _From, GoodsStatus) ->
    %% 查询背包物品列表
    GoodsList = lib_goods_util:get_goods_list(GoodsStatus#goods_status.player_id, ?GOODS_LOC_BAG, GoodsStatus#goods_status.dict),
    %% 按物品类型ID排序
    GoodsList1 = lib_goods_util:sort(GoodsList, bind_id),
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            %% 整理
            [Num, _, NewStatus] = lists:foldl(fun lib_goods:clean_bag/2, [1, {}, GoodsStatus], GoodsList1),
            %% 重新计算
            if
                Num > PlayerStatus#player_status.cell_num ->
                    Num1 = PlayerStatus#player_status.cell_num;
                true ->
                    Num1 = Num
            end,
            NullCells = lists:seq(Num1, PlayerStatus#player_status.cell_num),
            NewGoodsStatus = NewStatus#goods_status{null_cells = NullCells},
            Dict = lib_goods_dict:handle_dict(NewGoodsStatus#goods_status.dict),
            NewGoodsStatus2 = NewGoodsStatus#goods_status{dict = Dict},
            {ok, NewGoodsStatus2}
        end,
    case lib_goods_util:transaction(F) of
        {ok, NewGoodsStatus1} ->
            NewGoodsList = lib_goods_util:get_goods_list(NewGoodsStatus1#goods_status.player_id, ?GOODS_LOC_BAG, NewGoodsStatus1#goods_status.dict),
            {reply, NewGoodsList, NewGoodsStatus1};
        Error ->
            util:errlog("mod_goods order error:~p", [Error]),
            {reply, GoodsList, GoodsStatus}
    end;

%% 拣取地上掉落包的物品
handle_call({'drop_choose', PlayerStatus, DropId}, _From, GoodsStatus) ->
    case lib_goods_check:check_drop_choose(PlayerStatus, GoodsStatus, DropId, GoodsStatus) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res], GoodsStatus};
        {ok, GoodsTypeInfo, DropInfo} ->
             case (catch lib_goods:drop_choose(PlayerStatus, GoodsStatus, GoodsTypeInfo, DropId)) of
                {ok, NewPlayerStatus, NewStatus, NewGoodsInfo} ->
                    lib_goods_drop:send_drop_notice(NewPlayerStatus, DropInfo),
                    lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
                     case DropInfo#ets_drop.notice > 0 of
                         true ->
                             [SceneId, X, Y] = case data_scene_id:get_boss_xy(DropInfo#ets_drop.mon_id) of
                                 [] -> [DropInfo#ets_drop.scene, 0, 0];
                                 [S, X1, X2] -> [S, X1, X2]
                             end,
                             %% 传闻
                             lib_chat:send_TV({all},0,2, ["killBoss",
													2, 
													NewPlayerStatus#player_status.id, 
													NewPlayerStatus#player_status.realm, 
													NewPlayerStatus#player_status.nickname, 
													NewPlayerStatus#player_status.sex, 
													NewPlayerStatus#player_status.career, 
													NewPlayerStatus#player_status.image, 
													binary_to_list(DropInfo#ets_drop.mon_name), 
													DropInfo#ets_drop.goods_id, 
													SceneId, 
													X, 
													Y, NewGoodsInfo#goods.id]);
                         false -> 
                             skip
                     end,
                    {reply, [NewPlayerStatus, ?ERRCODE_OK], NewStatus};
                {fail, Res1} ->
                    {reply, [PlayerStatus, Res1], GoodsStatus};
                Error ->
                    util:errlog("mod_goods drop_choose:~p", [Error]),
                    {reply, [PlayerStatus, ?ERRCODE15_FAIL], GoodsStatus}
            end
    end;

%% 拆分物品
handle_call({'split', GoodsId, GoodsNum}, _From, GoodsStatus) ->
    case lib_goods_check:check_split(GoodsStatus, GoodsId, GoodsNum) of
        {fail, Res} ->
            {reply, [Res, #goods{}], GoodsStatus};
        {ok, GoodsInfo} ->
            case lib_goods:split(GoodsStatus, GoodsInfo, GoodsNum) of
                {ok, NewStatus, NewGoodsInfo} ->
                    {reply, [?ERRCODE_OK, NewGoodsInfo], NewStatus};
                Error ->
                    util:errlog("mod_goods split error:~p", [Error]),
                    {reply, [?ERRCODE15_FAIL, #goods{}], GoodsStatus}
            end
    end;

%% 在线礼包领取
handle_call({'online_gift', PlayerStatus, GiftId}, _From, GoodsStatus) ->
    case lib_gift_check:check_online_gift(PlayerStatus, GoodsStatus, GiftId) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res], GoodsStatus};
        {ok, GiftInfo} ->
            case lib_gift:receive_online_gift(PlayerStatus, GoodsStatus, GiftInfo) of
                {ok, NewPlayerStatus, NewGoodsStatus, GiveList} ->
                    lib_gift:send_gift_item_notice(NewPlayerStatus, GiftInfo#ets_gift.id, GiftInfo#ets_gift.goods_id, GiveList),
                    lib_player:refresh_client(NewGoodsStatus#goods_status.player_id, 2),
                    {reply, [NewPlayerStatus, ?ERRCODE_OK], NewGoodsStatus};
                Error ->
                    util:errlog("mod_goods online_gift:~p", [Error]),
                    {reply, [PlayerStatus, ?ERRCODE15_FAIL], GoodsStatus}
            end
    end;

%% 领取礼包，可将礼包放到背包，或直接获取礼包中的物品
handle_call({'fetch_gift', PlayerStatus, GiftId}, _From, GoodsStatus) ->
	case lib_gift_new:fetch_gift_in_good(PlayerStatus, GoodsStatus, GiftId) of
	    {ok, NewPlayerStatus, NewGoodsStatus} ->
	        lib_player:refresh_client(NewGoodsStatus#goods_status.player_id, 2),
	        {reply, [ok, NewPlayerStatus], NewGoodsStatus};
	    {error, ErrorCode} ->
	        {reply, [error, ErrorCode], GoodsStatus}
	end;

%% 领取连续登录或回归礼包
handle_call({'get_continuous_login_gift', PlayerStatus, GiftList, NewEtsLoginCounter}, _From, GoodsStatus) ->
    case lib_login_gift:get_continuous_login_gift(PlayerStatus, GoodsStatus, GiftList, NewEtsLoginCounter) of
        {ok, NewPlayerStatus, NewGoodsStatus, GiveList} ->
            lib_player:refresh_client(NewGoodsStatus#goods_status.player_id, 2),
            {reply, {ok, NewPlayerStatus, GiveList}, NewGoodsStatus};
        {fail, FailCode} ->
            {reply, {error, FailCode}, GoodsStatus};
        Error ->
            util:errlog("mod_goods get_continuous_login_gift:~p", [Error]),
            {reply, {error, 0}, GoodsStatus}
    end;

%% 活动礼包领取
handle_call({'recv_gift', PlayerStatus, GiftId, Card}, _From, GoodsStatus) ->
    case lib_gift_check:check_recv_gift(PlayerStatus, GoodsStatus, GiftId, Card) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res], GoodsStatus};
        {ok, GiftInfo} ->
            case lib_activity_gift:receive_gift(PlayerStatus, GoodsStatus, GiftInfo, Card) of
                {ok, NewPlayerStatus, NewGoodsStatus, GiveList} ->
                    lib_activity_gift:send_gift_item_notice(NewPlayerStatus, GiftInfo, GiveList),
                    lib_player:refresh_client(NewGoodsStatus#goods_status.player_id, 2),
                    {reply, [NewPlayerStatus, ?ERRCODE_OK], NewGoodsStatus};
                Error ->
                    util:errlog("mod_goods recv_gift:~p", [Error]),
                    {reply, [PlayerStatus, 0], GoodsStatus}
            end
    end;

%% NPC礼包领取
handle_call({'npc_gift', PlayerStatus, GiftId, Card}, _From, GoodsStatus) ->
    case lib_gift_check:check_npc_gift(PlayerStatus, GoodsStatus, GiftId, Card) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res], GoodsStatus};
        {ok, GiftInfo} ->
            case lib_gift:receive_npc_gift(PlayerStatus, GoodsStatus, GiftInfo, Card) of
                {ok, NewPlayerStatus, NewGoodsStatus, GiveList} ->
                    lib_gift:send_gift_item_notice(NewPlayerStatus, GiftInfo#ets_gift.id, GiftInfo#ets_gift.goods_id, GiveList),
                    lib_player:refresh_client(NewGoodsStatus#goods_status.player_id, 2),
                    {reply, [NewPlayerStatus, ?ERRCODE_OK], NewGoodsStatus};
                %% 背包格子不足
                {db_error, {error, card_invalid}} ->
                    {reply, [PlayerStatus, ?ERRCODE15_REQUIRE_ERR], GoodsStatus};
                Error ->
                     util:errlog("mod_goods npc_gift:~p", [Error]),
                    {reply, [PlayerStatus, ?ERRCODE15_FAIL], GoodsStatus}
            end
    end;

%% NPC物品兑换
handle_call({'npc_exchange', PlayerStatus, NpcTypeId, ExchangeId, ExchangeNum}, _From, GoodsStatus) ->
    case lib_goods_check:check_npc_exchange(PlayerStatus, GoodsStatus, NpcTypeId, ExchangeId, ExchangeNum) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, 0], GoodsStatus};
        {ok, ExchangeInfo} ->
            case lib_gift:exchange_goods(PlayerStatus, GoodsStatus, ExchangeInfo, ExchangeNum) of
                {ok, NewPlayerStatus, NewGoodsStatus, GiveList, RemainNum} ->
                    lib_gift:send_gift_item_notice(NewPlayerStatus, 0, 0, GiveList),
                    lib_player:refresh_client(NewGoodsStatus#goods_status.player_id, 2),
                    {reply, [NewPlayerStatus, ?ERRCODE_OK, RemainNum], NewGoodsStatus};
                Error ->
                    util:errlog("mod_goods npc_exchange:~p", [Error]),
                    {reply, [PlayerStatus, ?ERRCODE15_FAIL, 0], GoodsStatus}
            end
    end;

%% 使用替身娃娃完成任务
handle_call({'finish_task', PlayerStatus, TaskId}, _From, GoodsStatus) ->
    case lib_goods_check:check_finish_task(PlayerStatus, TaskId) of
        {fail, Res} ->
            {reply, [Res], GoodsStatus};
        {ok, GoodsList, GoodsTypeId, GoodsNum} ->
            case lib_goods:finish_task(GoodsStatus, GoodsList, GoodsTypeId, GoodsNum, TaskId) of
                {ok, NewStatus} ->
                    lib_player:refresh_client(PlayerStatus#player_status.id, 2),
                    {reply, [1], NewStatus};
                {fail, Res1} ->
                    {reply, [Res1], GoodsStatus};
                Error ->
                    util:errlog("mod_goods finish_task:~p", [Error]),
                    {reply, [10], GoodsStatus}
            end
    end;

%% 送东西
handle_call({'send_gift', PlayerStatus, Type, SubType, PlayerId}, _From, GoodsStatus) ->
    case lib_goods_check:check_send_gift(PlayerStatus, Type, SubType, PlayerId) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res], GoodsStatus};
        {ok, GoodsTypeInfo, Coin, Gold} ->
            case lib_goods:send_gift(PlayerStatus, GoodsTypeInfo, Coin, Gold, PlayerId) of
                {ok, NewPlayerStatus, _MailList} ->
                    lib_player:refresh_client(NewPlayerStatus#player_status.id, 2),
%%以后加上                     
%%                     mod_mail:update_mail_info(PlayerId, MailList, <<"系统">>),
                    {reply, [NewPlayerStatus, 1], GoodsStatus};
                Error ->
                    util:errlog("mod_goods send_gift:~p", [Error]),
                    {reply, [PlayerStatus, 10], GoodsStatus}
            end
    end;

%% 开宝箱
handle_call({'box_open', PlayerStatus, BoxId, BoxNum}, _From, GoodsStatus) ->
    case lib_box_check:check_box_open(PlayerStatus, BoxId, BoxNum, GoodsStatus) of
        {fail, Res1} ->
            {reply, [PlayerStatus, Res1, [], [], 0, 0], GoodsStatus};
        {ok, BoxInfo, BoxBag, Cost, GoodsInfo, GoodsTypeId, Bind} ->
            %io:format("11 ~p~n", [{BoxInfo, BoxBag, Cost, GoodsInfo, GoodsTypeId, Bind}]),
            case mod_disperse:call_to_unite(mod_box, open_box, [PlayerStatus, BoxInfo, BoxNum, BoxBag, Bind]) of
                {badrpc, _} ->
                    {reply, [PlayerStatus, 0, [], [], 0, 0], GoodsStatus};
                {ok, NewBoxBag, GiveList, NoticeList} ->
                    case lib_box:save_open(PlayerStatus, GoodsStatus, BoxInfo, BoxNum, Cost, GoodsInfo, NewBoxBag, GiveList) of
                        {ok, NewPlayerStatus, NewStatus} ->
                            lib_qixi:update_player_task_batch(NewPlayerStatus#player_status.id, [21,22,23,24,25], BoxNum),
                            %% 成就：我淘我乐，淘宝N次
                            mod_achieve:trigger_role(NewPlayerStatus#player_status.achieve, NewPlayerStatus#player_status.id, 29, 0, BoxNum),
                            lib_player:refresh_client(NewStatus#goods_status.player_id, 2),
                            {reply, [NewPlayerStatus, 1, GiveList, NoticeList, Cost, GoodsTypeId], NewStatus};
                        Error ->
                            util:errlog("mod_goods box_open save_open:~p", [Error]),
                            {reply, [PlayerStatus, 0, [], [], 0, 0], GoodsStatus}
                    end;
                Error ->
                    util:errlog("mod_goods box_open:~p", [Error]),
                    {reply, [PlayerStatus, 0, [], [], 0, 0], GoodsStatus}
            end
    end;

%% 取宝箱物品
handle_call({'box_get', PlayerStatus, GoodsList, NewBoxBag}, _From, GoodsStatus) ->
    case length(GoodsStatus#goods_status.null_cells) < length(GoodsList) of
        %% 背包格子不足
        true -> {reply, {fail, 3}, GoodsStatus};
        false ->
            F = fun() ->
                    ok = lib_goods_dict:start_dict(),
                    {ok, NewStatus} = lib_goods_check:list_handle(fun lib_goods:give_goods/2, GoodsStatus, GoodsList),
                    NewPlayerStatus = lib_box:mod_box_bag(PlayerStatus, NewBoxBag),
                    F1 = fun({info, G}) -> 
                                 log:log_box(2, NewPlayerStatus#player_status.id, 0, 0, G#goods.goods_id, G#goods.num, G#goods.bind) 
                         end,
                    lists:foreach(F1, GoodsList),
                     Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                    NewStatus2 = NewStatus#goods_status{dict = Dict},
                    {ok, NewPlayerStatus, NewStatus2}
                end,
            case lib_goods_util:transaction(F) of
                {ok, NewPlayerStatus, NewStatus} ->
                    lib_player:refresh_client(NewStatus#goods_status.player_id, 2),
                    {reply, {ok, NewPlayerStatus}, NewStatus};
                %% 物品类型不存在
                {db_error, {error,{_, not_found}}} ->
                    {reply, {fail, 2}, GoodsStatus};
                %% 背包格子不足
                {db_error, {error,{cell_num, not_enough}}} ->
                    {reply, {fail, 3}, GoodsStatus};
                Error ->
                    util:errlog("mod_goods box_get:~p", [Error]),
                    {reply, Error, GoodsStatus}
            end
    end;

%% 宝箱兑换
handle_call({'box_exchange', PlayerStatus, StoneId, EquipId, Pos}, _From, GoodsStatus) ->
    case lib_box_check:check_box_exchange(PlayerStatus, StoneId, EquipId, Pos, GoodsStatus) of
        {fail, Res} ->
            {reply, [Res, PlayerStatus, 0], GoodsStatus};
        {ok, Stone, EquipTypeInfo} ->
            case lib_box:box_exchange(PlayerStatus, Stone, EquipTypeInfo, Pos, GoodsStatus) of
                {ok, NewPlayerStatus, NewStatus, NewGoodsInfo} ->
                    if
                        Pos =:= 0 ->
                            StoneTypeId = StoneId;
                        true ->
                            StoneTypeId = Stone#goods.goods_id
                    end,
                     %% 传闻
                    lib_chat:send_TV({all},0,2, ["taobaoDH", 
													NewPlayerStatus#player_status.id, 
													NewPlayerStatus#player_status.realm, 
													NewPlayerStatus#player_status.nickname, 
													NewPlayerStatus#player_status.sex, 
													NewPlayerStatus#player_status.career, 
													NewPlayerStatus#player_status.image, 
                                                    StoneTypeId,
												    NewGoodsInfo#goods.id]),
                    {reply, [?ERRCODE_OK, NewPlayerStatus, NewGoodsInfo#goods.bind], NewStatus};
                _Error ->
                    {reply, [?ERRCODE_FAIL, PlayerStatus, 0], GoodsStatus}
            end
    end;

%% 赠送物品
handle_call({'give_goods', _PlayerStatus, GoodsTypeId, GoodsNum}, _From, GoodsStatus) ->
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            {ok, NewStatus} = lib_goods:give_goods({GoodsTypeId, GoodsNum}, GoodsStatus),
             Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
            {ok, NewStatus2}
        end,
    case lib_goods_util:transaction(F) of
        {ok, NewStatus} ->
            lib_player:refresh_client(NewStatus#goods_status.player_id, 2),
            {reply, ok, NewStatus};
        %% 物品类型不存在
        {db_error, {error,{Type, not_found}}} ->
            {reply, {db_error, {error,{Type, not_found}}}, GoodsStatus};
        %% 背包格子不足
        {db_error, {error,{cell_num, not_enough}}} ->
            {reply, {db_error, {error,{cell_num, not_enough}}}, GoodsStatus};
        Error ->
            %util:errlog("mod_goods give_goods:~p", [Error]),
            {reply, Error, GoodsStatus}
    end;

%% 赠送物品 (列表中GoodsTypeId不能重复)
%% GoodsList = [{GoodsTypeId, GoodsNum }, ...]
%% GoodsList = [{goods, GoodsTypeId, GoodsNum }, ...]
%% GoodsList = [{equip, GoodsTypeId, Prefix, Stren }, ...]
%% GoodsList = [{info, GoodsInfo }, ...]
handle_call({'give_more', _PlayerStatus, GoodsList}, _From, GoodsStatus) ->
    %%　io:format("~p ~p give_more:~p~n", [?MODULE, ?LINE, GoodsList]),
    F = fun() ->
            ok = lib_goods_dict:start_dict(),
            {ok, NewStatus} = lib_goods_check:list_handle(fun lib_goods:give_goods/2, GoodsStatus, GoodsList),
             Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
            NewStatus2 = NewStatus#goods_status{dict = Dict},
            {ok, NewStatus2}
        end,
    case lib_goods_util:transaction(F) of
        {ok, NewStatus} ->
            lib_player:refresh_client(NewStatus#goods_status.player_id, 2),
            {reply, ok, NewStatus};
        %% 物品类型不存在
        {db_error, {error,{_, not_found}}} ->
            {reply, {fail, 2}, GoodsStatus};
        %% 背包格子不足
        {db_error, {error,{cell_num, not_enough}}} ->
            {reply, {fail, 3}, GoodsStatus};
        Error ->
            ?INFO("mod_goods give_more:~p", [Error]),
            {reply, Error, GoodsStatus}
    end;
handle_call({'give_more_bind', _PlayerStatus, GoodsList}, _From, GoodsStatus) ->
    F = fun({GoodsTypeId, GoodsNum}) ->
			   {goods, GoodsTypeId, GoodsNum, 2}
%%			   已经废弃的物品处理
%%             case GoodsTypeId of
%%                 411001 -> {goods, GoodsTypeId, GoodsNum, 0};			%% 取消写死帮派建设令
%%                 411311 -> {goods, GoodsTypeId, GoodsNum, 0};			%% 未知物品
%%                 101125 -> {goods, GoodsTypeId, GoodsNum, 3, 3, 2};		%% 未知物品
%%                 101225 -> {goods, GoodsTypeId, GoodsNum, 3, 3, 2};		%% 未知物品
%%                 101325 -> {goods, GoodsTypeId, GoodsNum, 3, 3, 2};		%% 未知物品
%%                 105010 -> {goods, GoodsTypeId, GoodsNum, 3, 0, 2};		%% 未知物品
%%                 101132 -> {goods, GoodsTypeId, GoodsNum, 0, 3, 2};		%% 未知物品
%%                 101232 -> {goods, GoodsTypeId, GoodsNum, 0, 3, 2};		%% 未知物品
%%                 101332 -> {goods, GoodsTypeId, GoodsNum, 0, 3, 2};		%% 
%%                 _ -> {goods, GoodsTypeId, GoodsNum, 2}
%%             end
        end,
    NewGoodsList = [ F(Item) || Item <- GoodsList],
    handle_call({'give_more', _PlayerStatus, NewGoodsList}, _From, GoodsStatus);

%% NPC已领取礼包列表
handle_call({'gift_list'}, _From, GoodsStatus) ->
	{reply, GoodsStatus#goods_status.gift_list, GoodsStatus};

%% 空格子数
handle_call({'cell_num'}, _From, GoodsStatus) ->
	{reply, length(GoodsStatus#goods_status.null_cells), GoodsStatus};

%%删除多类物品
%% GoodsTypeList = [GoodsTypeId1, GoodsTypeId2, ...]
handle_call({'delete_type', GoodsTypeList}, _From, GoodsStatus) ->
    case lib_goods_check:list_handle(fun lib_goods:delete_type_goods/2, GoodsStatus, GoodsTypeList) of
        {ok, NewStatus} ->
            lib_player:refresh_client(NewStatus#goods_status.player_id, 2),
            {reply, ok, NewStatus};
         {Error, Status} ->
             ?INFO("mod_goods delete_type:~p", [Error]),
             {reply, Error, Status}
    end;

%% 存帮派物品
handle_call({'movein_guild', GuildId, GuildMaxNum, GoodsId, GoodsNum} , _From, GoodsStatus) ->
    case lib_goods_check:check_movein_guild(GoodsStatus, GuildId, GuildMaxNum, GoodsId, GoodsNum) of
        {fail, Res} ->
            {reply, {fail, Res}, GoodsStatus};
        {ok, GoodsInfo, GoodsTypeInfo} ->
            case lib_storage_util:movein_storage(GoodsStatus, GoodsInfo, GoodsNum, ?GOODS_LOC_GUILD, GoodsTypeInfo) of
                {ok, NewStatus} ->
                    %lib_send:send_to_all_server(goods_init, refresh_guild_goods, [GuildId]),
                    log:log_guild_goods(1, GoodsStatus#goods_status.player_id, GuildId, GoodsInfo, GoodsNum),
                    {reply, ok, NewStatus};
                Error ->
                    ?INFO("mod_goods movein_guild:~p", [Error]),
                    {reply, {fail, 0}, GoodsStatus}
            end
    end;

%% 取帮派物品 
handle_call({'moveout_guild', GuildId, GoodsId, GoodsNum} , _From, GoodsStatus) ->
    case lib_goods_check:check_moveout_guild(GoodsStatus, GuildId, GoodsId, GoodsNum) of
        {fail, Res} ->
            {reply, {fail, Res}, GoodsStatus};
        {ok, GoodsInfo, GoodsTypeInfo, GoodsTypeList} ->
            case lib_storage_util:moveout_storage(GoodsStatus, GoodsInfo, GoodsNum, ?GOODS_LOC_BAG, GoodsTypeInfo, GoodsTypeList) of
                {ok, NewStatus} ->
                    log:log_guild_goods(2, GoodsStatus#goods_status.player_id, GuildId, GoodsInfo, GoodsNum),
                    {reply, {ok, GoodsTypeInfo}, NewStatus};
                Error ->
                    ?INFO("mod_goods moveout_guild:~p", [Error]),
                    {reply, {fail, 0}, GoodsStatus}
            end
    end;

%% 删除帮派物品
handle_call({'delete_guild', GuildId, GoodsId} , _From, GoodsStatus) ->
    case lib_goods_check:check_delete_guild(GuildId, GoodsId) of
        {fail, Res} ->
            {reply, {fail, Res}, GoodsStatus};
        {ok, GoodsInfo, GoodsNum} ->
            F = fun() ->
                    ok = lib_goods_dict:start_dict(),
                    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [GoodsStatus, GoodsNum]),
                    log:log_guild_goods(3, GoodsStatus#goods_status.player_id, GuildId, GoodsInfo, GoodsNum),
                     Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                    NewStatus2 = NewStatus#goods_status{dict = Dict},
                    {ok, NewStatus2}
                end,
            case lib_goods_util:transaction(F) of
                {ok, NewStatus} ->
                    {reply, ok, NewStatus};
                Error ->
                    ?INFO("mod_goods delete_guild:~p", [Error]),
                    {reply, {fail, 0}, GoodsStatus}
            end
    end;

%% 帮派解散
handle_call({'cancel_guild', GuildId} , _From, GoodsStatus) ->
    case (catch lib_goods_util:delete_goods_by_guild(GuildId)) of
        ok ->
            {reply, ok, GoodsStatus};
        Error ->
            ?INFO("mod_goods cancel_guild:~p", [Error]),
            {reply, {fail, 0}, GoodsStatus}
    end;

%% 扩展帮派仓库
handle_call({'extend_guild', PlayerStatus, GuildLevel} , _From, GoodsStatus) ->
    case lib_goods_check:check_extend_guild(PlayerStatus, GuildLevel) of
        {fail, Res} ->
            {reply, {fail, Res}, GoodsStatus};
        {ok, GoldNum, GoodsNum, GoodsTypeList} ->
            case lib_goods:extend_guild(PlayerStatus, GoodsStatus, GoldNum, GoodsNum, GoodsTypeList) of
                {ok, NewPlayerStatus, NewStatus} ->
                    {reply, {ok, NewPlayerStatus}, NewStatus};
                Error ->
                    ?INFO("mod_goods extend_guild:~p", [Error]),
                    {reply, {fail, 0}, GoodsStatus}
            end
    end;

%% 领取任务累积经验
handle_call({'recv_cumulate', PlayerStatus, Task_id, Type}, _From, GoodsStatus) ->
    case lib_goods_check:check_recv_cumulate(PlayerStatus, Task_id, Type) of
        {fail, Res} ->
            {reply, [PlayerStatus, Res, 0, ""], GoodsStatus};
        {ok, TC, Day, GoodsList} ->
            case lib_task_cumulate:receive_exp(PlayerStatus, GoodsStatus, Type, TC, Day, GoodsList) of
                {ok, NewPlayerStatus, NewGoodsStatus, Exp, TaskName} ->
                    {reply, [NewPlayerStatus, 1, Exp, TaskName], NewGoodsStatus};
                {fail, Res2} ->
                    {reply, [PlayerStatus, Res2, 0, ""], GoodsStatus};
                Error ->
                    ?INFO("mod_goods recv_cumulate:~p", [Error]),
                    {reply, [PlayerStatus, 10, 0, ""], GoodsStatus}
            end
    end;

%% 物品合并
handle_call({'goods_merge', PlayerStatus, [Type, GoodsId1, GoodsId2]}, _From, GoodsStatus) ->
    case Type of
        1 -> 
            case lib_goods_relation:merge_goods_default(GoodsStatus, PlayerStatus) of
                {ok, NewGoodsStatus} ->
                    {reply, 1, NewGoodsStatus};
                _E ->
                    {reply, 10, GoodsStatus}
            end;
        2 ->
            case lib_goods_relation:check_goods_merge(GoodsId1, GoodsId2, PlayerStatus, GoodsStatus) of
                {fail, Res} ->
                    {reply, Res, GoodsStatus};
                {ok, GoodsInfo1, GoodsInfo2} ->
                    case lib_goods_relation:goods_merge_move(GoodsInfo1, GoodsInfo2, GoodsStatus) of
                        {ok, _NewGoodsInfo, NewGoodsStatus} ->
                            {reply, 1, NewGoodsStatus};
                        _Error ->
                            {reply, 10, GoodsStatus}
                    end
            end;
         _ ->
             {reply, 4, GoodsStatus}
     end;

%% ------------------ 邮件  ------------------------------------------------- 
%% 存进邮件附件
handle_call({'movein_mail', GoodsId, GoodsNum, PlayerId, MailInfo, PlayerInfo} , _From, GoodsStatus) ->
    case lib_goods_check:check_movein_mail(GoodsStatus, GoodsId, GoodsNum) of
        {fail, Res} ->
            {reply, {fail, Res}, GoodsStatus};
        {ok, GoodsInfo} ->
            case lib_goods:movein_mail(GoodsStatus, GoodsInfo, GoodsNum, PlayerId, MailInfo, PlayerInfo) of
                {ok, NewStatus, NewGoodsInfo, MailAttribute} ->
                    {reply, {ok, NewGoodsInfo#goods.id, MailAttribute}, NewStatus};
                Error ->
                    ?INFO("mod_goods movein_mail:~p", [Error]),
                    {reply, {fail, 0}, GoodsStatus}
            end
    end;

%% 取邮件附件
handle_call({'moveout_mail', GoodsId, MailId}, _From, GoodsStatus) ->
    case lib_goods_check:check_moveout_mail(GoodsStatus, GoodsId) of
        {fail, Res} ->
            {reply, {fail, Res}, GoodsStatus};
        {ok, GoodsInfo} ->
            case lib_goods:moveout_mail(GoodsStatus, GoodsInfo, MailId) of
                {ok, NewStatus} ->
                    {reply, ok, NewStatus};
                Error ->
                    ?INFO("mod_goods moveout_mail:~p", [Error]),
                    {reply, {fail, 0}, GoodsStatus}
            end
    end;

%% VIP绑定卡
handle_call({'vip_band', PlayerStatus, GoodsTypeId}, _From, GoodsStatus) ->
    case lib_goods_check:check_vip_band(PlayerStatus, GoodsStatus, GoodsTypeId) of
        {fail, Res} ->
            {reply, [Res, PlayerStatus], GoodsStatus};
        {ok, GoodsTypeInfo} ->
            case lib_goods:pay_vip_upgrade(PlayerStatus, GoodsTypeInfo, GoodsStatus) of
                {ok, NewPlayerStatus, NewStatus, _NewGoodsInfo} ->
                    {reply, [1, NewPlayerStatus], NewStatus};
                _Error ->
                    {reply, [0, PlayerStatus], GoodsStatus}
            end
    end;

%% 扩展背包
handle_call({'expand_bag', PlayerStatus, Type, Num, Gold}, _From, GoodsStatus) ->
    case lib_goods_check:check_expand_bag(PlayerStatus, Type, Num, Gold) of
        {fail, Res} ->
            {reply, [Res, PlayerStatus], GoodsStatus};
        {ok} ->
            case lib_goods:expand_bag(PlayerStatus, GoodsStatus, Type, Num, Gold) of
                {ok, NewPlayerStatus, NewStatus} ->
                    {reply, [1, NewPlayerStatus], NewStatus};
                _Error ->
                    {reply, [0, PlayerStatus], GoodsStatus}
            end;
        _ ->
            {reply, [0, PlayerStatus], GoodsStatus}
    end;
    
 
%% --------------------------------- 铸造  ----------------------------------------------------
handle_call({'quality_upgrade', PlayerStatus, GoodsId, StoneTypeId, PrefixType, StoneList}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'quality_upgrade', PlayerStatus, GoodsId, StoneTypeId, PrefixType, StoneList}, _From, GoodsStatus);
            
handle_call({'strengthen', PlayerStatus, EquipId, StoneId, LuckyId}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'strengthen', PlayerStatus, EquipId, StoneId, LuckyId}, _From, GoodsStatus);

handle_call({'equip_compose', PlayerStatus, BlueId, PurpleId1, PurpleId2}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'equip_compose', PlayerStatus, BlueId, PurpleId1, PurpleId2}, _From, GoodsStatus);
    
handle_call({'weapon_compose', PlayerStatus, GoodsId, StoneList, ChipList}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'weapon_compose', PlayerStatus, GoodsId, StoneList, ChipList}, _From, GoodsStatus);

handle_call({'advanced', PlayerStatus, GoodsId, StoneList, ChipList}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'advanced', PlayerStatus, GoodsId, StoneList, ChipList}, _From, GoodsStatus);

handle_call({'equip_inherit', PlayerStatus, LowId, HighId, StuffList}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'equip_inherit', PlayerStatus, LowId,
            HighId, StuffList}, _From, GoodsStatus);

handle_call({'equip_upgrade', PlayerStatus, GoodsId, RuneId, TripList, StoneList, IronList}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'equip_upgrade', PlayerStatus, GoodsId, RuneId, TripList, StoneList, IronList}, _From, GoodsStatus);

handle_call({'attribute_wash', PlayerStatus, GoodsId, Time, StoneList1, LockList, StoneList}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'attribute_wash', PlayerStatus, GoodsId, Time, StoneList1, LockList, StoneList}, _From, GoodsStatus);

handle_call({'attribute_sel', PlayerStatus, GoodsId, Pos}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'attribute_sel', PlayerStatus, GoodsId, Pos}, _From, GoodsStatus);

handle_call({'attribute_get', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'attribute_get', PlayerStatus, GoodsId}, _From, GoodsStatus);

handle_call({'goods_resolve', PlayerStatus, GreemList, BlueList, PurpleList}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'goods_resolve', PlayerStatus, GreemList, BlueList, PurpleList}, _From, GoodsStatus);

handle_call({'hide_fashion', PlayerStatus, GoodsId, Show}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'hide_fashion', PlayerStatus, GoodsId, Show}, _From, GoodsStatus);

handle_call({'replace_wardrobe', PlayerStatus, M}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'replace_wardrobe', PlayerStatus, M}, _From, GoodsStatus);

handle_call({'get_reiki', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'get_reiki', PlayerStatus, GoodsId}, _From, GoodsStatus);

handle_call({'add_reiki', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'add_reiki', PlayerStatus, GoodsId}, _From, GoodsStatus);

handle_call({'qi_reiki', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'qi_reiki', PlayerStatus, GoodsId}, _From, GoodsStatus);

%% 坐骑
handle_call({'mount_stren', PlayerStatus, MountId, StoneId, RuneList}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'mount_stren', PlayerStatus, MountId, StoneId, RuneList}, _From, GoodsStatus);

handle_call({'mount_upgrade', PlayerStatus, MountId, RuenList}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'mount_upgrade', PlayerStatus, MountId, RuenList}, _From, GoodsStatus);

handle_call({'fly_star', PlayerStatus, MountId, RuenList}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'fly_star', PlayerStatus, MountId, RuenList}, _From, GoodsStatus);

handle_call({'up_quality', PlayerStatus, MountId, Type, Coin, StoneList}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'up_quality', PlayerStatus, MountId, Type, Coin, StoneList}, _From, GoodsStatus);

%% handle_call({'up_quality', PlayerStatus, MountId, StoneList}, _From, GoodsStatus) ->
%%     mod_goods_compose_call:handle_call({'up_quality', PlayerStatus, MountId, StoneList}, _From, GoodsStatus);

handle_call({'mount_card', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'mount_card', PlayerStatus, GoodsId}, _From, GoodsStatus);

handle_call({'mount_recover', PlayerStatus, MountId}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'mount_recover', PlayerStatus, MountId}, _From, GoodsStatus);

%% 宝石
handle_call({'inlay', PlayerStatus, EquipId, S1, R1, S2, R2, S3, R3}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'inlay', PlayerStatus, EquipId, S1, R1, S2, R2, S3, R3}, _From, GoodsStatus);

handle_call({'backout', PlayerStatus, EquipId, StonePos1, RuneId1, StonePos2, RuneId2, StonePos3, RuneId3}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'backout', PlayerStatus, EquipId, StonePos1, RuneId1, StonePos2, RuneId2, StonePos3, RuneId3}, _From, GoodsStatus);

handle_call({'compose', PlayerStatus, RuneList, StoneTypeId, StoneList, Times, IsRune, PerNum}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'compose', PlayerStatus, RuneList, StoneTypeId, StoneList, Times, IsRune, PerNum}, _From, GoodsStatus);

handle_call({'forge', PlayerStatus, Id, Num, Flag}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'forge', PlayerStatus, Id, Num, Flag}, _From, GoodsStatus);

%% 新版宝石系统
handle_call({'gemstone_upgrade', PlayerStatus, GemStone, GoodsList}, _From, GoodsStatus) -> 
    mod_goods_compose_call:handle_call({'gemstone_upgrade', PlayerStatus, GemStone, GoodsList}, _From, GoodsStatus);

%%取装备位置物品
handle_call({'gemstone_equip', PlayerStatus, EquipPos}, _From, GoodsStatus) ->  
    mod_goods_compose_call:handle_call({'gemstone_equip', PlayerStatus, EquipPos}, _From, GoodsStatus);

%% 市场
handle_call({'sell_up', PlayerStatus, GoodsId, Num, PriceType, Price, Time, Show}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'sell_up', PlayerStatus, GoodsId, Num, PriceType, Price, Time, Show}, _From, GoodsStatus);

handle_call({'resell', PlayerStatus, Id}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'resell', PlayerStatus, Id}, _From, GoodsStatus);

handle_call({'sell_down', PlayerStatus, Id}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'sell_down', PlayerStatus, Id}, _From, GoodsStatus);

handle_call({'pay_sell', PlayerStatus, Id}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'pay_sell', PlayerStatus, Id}, _From, GoodsStatus);

handle_call({'pay_buy', PlayerStatus, Id, GoodsId}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'pay_buy', PlayerStatus, Id, GoodsId}, _From, GoodsStatus);

handle_call({'finish_sell_one', PlayerStatus, SellerPlayerStatus}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'finish_sell_one', PlayerStatus, SellerPlayerStatus}, _From, GoodsStatus);

handle_call({'finish_sell_two', PlayerStatus, SellerPlayerStatus, SellerGoodsStatus}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'finish_sell_two', PlayerStatus, SellerPlayerStatus, SellerGoodsStatus}, _From, GoodsStatus);
%%购买物品
handle_call({'pay', PlayerStatus, GoodsTypeId, GoodsNum, ShopType, ShopSubtype, PayMoneyType}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'pay', PlayerStatus, GoodsTypeId, GoodsNum, ShopType, ShopSubtype, PayMoneyType}, _From, GoodsStatus);
%%购买限时物品
handle_call({'pay_limit', PlayerStatus, Pos, GoodsTypeId, GoodsNum}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'pay_limit', PlayerStatus, Pos, GoodsTypeId, GoodsNum}, _From, GoodsStatus);
%% 出售物品
handle_call({'sell', PlayerStatus, ShopType, GoodsList}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'sell', PlayerStatus, ShopType, GoodsList}, _From, GoodsStatus);
%% 刷新神秘商店
handle_call({'refresh_secret', PlayerStatus, Type, GoodsId, Num}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'refresh_secret', PlayerStatus, Type, GoodsId, Num}, _From, GoodsStatus);
%% 购买神秘商店物品
handle_call({'pay_secret', PlayerStatus, GoodsId, Num}, _From, GoodsStatus) ->
    mod_goods_sell_call:handle_call({'pay_secret', PlayerStatus, GoodsId, Num}, _From, GoodsStatus);

%% 功勋续期
handle_call({'token_renewal', PlayerStatus, [GoodsId, Days]}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'token_renewal', PlayerStatus, [GoodsId, Days]}, _From, GoodsStatus);

%% 功勋升级
handle_call({'token_upgrade', PlayerStatus, GoodsId}, _From, GoodsStatus) ->
    mod_goods_compose_call:handle_call({'token_upgrade', PlayerStatus, GoodsId}, _From, GoodsStatus);

handle_call(_R, _From, GoodsStatus) ->
	{reply, no_match, GoodsStatus}.

%% 打开礼包后穿上礼包中的装备
wear_equip_in_gift(PlayerStatus, GoodsStatus, GoodsTypeId) ->
	case lib_goods_check:add_equip_by_typeid(GoodsTypeId, GoodsStatus) of
		{fail, Res} ->
			{error, Res};
		{ok, GoodsInfo, Cell, NewGoodsStatus} ->
            case lib_goods_check:check_equip(PlayerStatus, GoodsInfo#goods.id, Cell, NewGoodsStatus) of
                {fail, Res} ->
			       {error, Res};
		        {ok, GoodsInfo, Location, NewCell} ->
			        case lib_goods:equip_goods(PlayerStatus, NewGoodsStatus, GoodsInfo, Location, NewCell) of
                        {ok, NewPlayerStatus, NewStatus, _OldGoodsInfo} ->
							{ok, NewPlayerStatus, NewStatus};
                        _Error ->
							{error, ?ERRCODE15_FAIL}
                    end
            end
    end.
