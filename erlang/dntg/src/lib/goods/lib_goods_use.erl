%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-1-3
%% Description: 物品他用类
%% --------------------------------------------------------
-module(lib_goods_use).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("errcode_goods.hrl").
-include("goods.hrl").
-include("server.hrl").
-include("buff.hrl").
-include("scene.hrl").

%% 使用物品
use_goods(PlayerStatus, Status, GoodsInfo, GoodsNum) ->
	case GoodsInfo#goods.type of
		?GOODS_TYPE_DRUG -> %气血包  
			case lib_hp_bag:use_bag(PlayerStatus, Status, GoodsInfo, GoodsNum) of
                {ok, NewPlayerStatus, Status1} ->
                    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [Status1, GoodsNum]),
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    pp_player:handle(13060, NewPlayerStatus, []),
                    {ok, NewPlayerStatus, NewStatus, NewNum};
                _Error -> 
                    skip
            end;
		?GOODS_TYPE_GAIN -> %增益类
            case use22(PlayerStatus, Status, GoodsInfo, GoodsNum) of
                {ok, NewPlayerStatus, NewStatus1} ->
                    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [NewStatus1, GoodsNum]),
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    {ok, NewPlayerStatus, NewStatus, NewNum};
                _Error -> 
                    skip
            end;
		?GOODS_TYPE_BUFF -> %buff
			F = fun() ->
					ok = lib_goods_dict:start_dict(),
					case use21(PlayerStatus, GoodsInfo, GoodsNum) of
						{ok, NewPlayerStatus} ->
                            [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [Status, GoodsNum]),
                            NewNum = GoodsInfo#goods.num - GoodsNum,
                            Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                            NewStatus1 = NewStatus#goods_status{dict = Dict},
                            {ok, NewPlayerStatus, NewStatus1, NewNum};
                        {fail, ErrorCode} ->
                            {fail, ErrorCode};
                        _Error ->
                            %Dict = lib_goods_dict:handle_dict(Status#goods_status.dict),
                            %_NewStatus1 = Status#goods_status{dict = Dict},
                            skip
                    end
                end,
			case lib_goods_util:transaction(F) of
				{ok, NewPlayerStatus, NewStatus, NewNum} ->
                    {ok, NewPlayerStatus, NewStatus, NewNum};
                {fail, ErrorCode} ->
                    {fail, ErrorCode};
                _Error -> 
                    skip
            end;
		?GOODS_TYPE_SKILL ->
            case use13(PlayerStatus, GoodsInfo) of
                {ok, NewPlayerStatus} ->
                    {ok, NewPlayerStatus, Status, GoodsNum};
                _Error -> 
                    {fail, ?ERRCODE15_SKILL_FAIL}
            end;
		%VIP卡
        ?GOODS_TYPE_VIP ->
            case use63(PlayerStatus, GoodsInfo, GoodsNum) of
                {ok, NewPlayerStatus} ->
                    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [Status, GoodsNum]),
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    {ok, NewPlayerStatus, NewStatus, NewNum};
                _Error -> 
                    {fail, ?ERRCODE15_FAIL}
            end;
        %% 任务类
        ?GOODS_TYPE_TASK ->
            case use50(PlayerStatus, GoodsInfo) of
                {ok, NewPlayerStatus} ->
                    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [Status, GoodsNum]),
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    {ok, NewPlayerStatus, NewStatus, NewNum};
                _Error -> 
                    skip
            end;
        %% 活动类
        ?GOODS_TYPE_ACTIVICE ->
            %io:format("1~n"),
            case use52(PlayerStatus, GoodsInfo) of
                {ok, NewPlayerStatus} ->
                    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [Status, GoodsNum]),
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    {ok, NewPlayerStatus, NewStatus, NewNum};
                _Error -> 
                    skip
            end;
        %% 特殊类
        ?GOODS_TYPE_OBJECT ->
            case use61(PlayerStatus, GoodsInfo, GoodsNum, Status) of
                {ok, NewPlayerStatus} ->
                    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [Status, GoodsNum]),
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    {ok, NewPlayerStatus, NewStatus, NewNum};
                {ok, NewPlayerStatus, NewGoodsStatus} ->
                    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [NewGoodsStatus, GoodsNum]),
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    {ok, NewPlayerStatus, NewStatus, NewNum};
                nothing ->
                    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [Status, GoodsNum]),
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    {nothing, PlayerStatus, NewStatus, NewNum};
                _Error ->
                    _Error
            end;
        %% 宠物类
        ?GOODS_TYPE_PET ->
            case use62(PlayerStatus, Status, GoodsInfo, GoodsNum) of
                {ok, NewPlayerStatus, NewStatus1} ->
		    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [NewStatus1, GoodsNum]),
		    NewNum = GoodsInfo#goods.num - GoodsNum,
                    {ok, NewPlayerStatus, NewStatus, NewNum};
		{skip, "feed_pet"} ->
		    {ok, PlayerStatus, Status, GoodsNum};
		{skip, "incubate"} ->
		    {ok, PlayerStatus, Status, GoodsNum};
		{skip, "pet_skill"} ->
		    {ok, PlayerStatus, Status, GoodsNum};
		{skip, "practice_potentials"} ->
		    {ok, PlayerStatus, Status, GoodsNum};
		{skip, "grow_up"} ->
		    {ok, PlayerStatus, Status, GoodsNum};
		{skip, "aptitude_up"} ->
		    {ok, PlayerStatus, Status, GoodsNum};
		{skip, "pet_figure_activate"} ->
		    {ok, PlayerStatus, Status, GoodsNum};
		{skip, "pet_upgrade"} ->
		    {ok, PlayerStatus, Status, GoodsNum};
		_Error -> 
                 skip
            end;
        %合成类
        ?GOODS_TYPE_COMPOSE ->
            case use67(PlayerStatus, Status, GoodsInfo) of
                {ok, NewPlayerStatus, NewStatus} ->
                    {ok, NewPlayerStatus, NewStatus, GoodsNum};
                _Error -> 
                    skip
            end;
        %% 飞行类
        ?GOODS_TYPE_FLY ->
            case use69(PlayerStatus, Status, GoodsInfo) of
                {ok, NewPlayerStatus, NewStatus} ->
                    {ok, NewPlayerStatus, NewStatus, GoodsNum};
                _Error -> 
                    skip
            end;
        ?GOODS_TYPE_GUILD ->
            case use41(PlayerStatus, GoodsInfo) of
                {ok, NewPlayerStatus} ->
                    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [Status, GoodsNum]),
                    NewNum = GoodsInfo#goods.num - GoodsNum,
                    {ok, NewPlayerStatus, NewStatus, NewNum};
                {fail, Res} ->
                    {fail, Res};
                _Error ->
                    io:format("_Error = ~p~n", [_Error]),
                    skip
            end;
        31 ->       %% 坐骑
            case use31(PlayerStatus, GoodsInfo) of
                {ok, NewPlayerStatus} ->
                    [NewStatus, _] = lib_goods:delete_one(GoodsInfo, [Status, GoodsNum]),
                    NewNum = GoodsInfo#goods.num - GoodsNum,  
                    {ok, NewPlayerStatus, NewStatus, NewNum};
                {fail, Res} ->
                    {fail, Res};
                _E ->
                    _E
            end;
        _ ->
            {fail, ?ERRCODE15_TYPE_ERR}
    end.

%% 技能
use13(PlayerStatus, GoodsInfo) ->
	case GoodsInfo#goods.subtype of
		?GOODS_SUBTYPE_SKILL ->
            gen_server:cast(PlayerStatus#player_status.pid, {'use_skill_book', [GoodsInfo#goods.skill_id, GoodsInfo#goods.id]}),
            {ok, PlayerStatus};
		_ ->
			{fail, ?ERRCODE15_TYPE_ERR}
	end.

%% BUFF
use21(PlayerStatus, GoodsInfo, GoodsNum) ->
    if 
        GoodsNum =< 0 ->
            mod_scene_agent:update(battle_attr, PlayerStatus),
            {ok, PlayerStatus};
        true ->
            %酒类每天使用不能超过6次
            %% 酒类物品需要特殊处理
            case GoodsInfo#goods.goods_id =:= 214001 orelse GoodsInfo#goods.goods_id =:= 214002 
                orelse GoodsInfo#goods.goods_id =:= 214003 orelse GoodsInfo#goods.goods_id =:= 214004 of
                true ->
                    UseNum = mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 1008),
                    case UseNum >= 6 of
                        true ->
                            {fail, ?ERRCODE15_WINE_TOP};
                        false ->
                            case data_goods_effect:get_val(GoodsInfo#goods.goods_id, buff) of %物品类型
                                [] ->
                                    {fail, ?ERRCODE15_TYPE_ERR};
                                {Type, AttributeId, Value, _Time, SceneLimit} ->
                                    Time = _Time * GoodsNum,
                                    %酒水数量+1
                                    mod_daily:set_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 1008, UseNum+1),
                                    NowTime = util:unixtime(),
                                    case lib_buff:match_three(PlayerStatus#player_status.player_buff, Type, AttributeId, []) of
                                    %case lib_player:get_player_buff(PlayerStatus#player_status.id, Type, AttributeId) of
                                        [] ->
                                            NewBuffInfo = lib_player:add_player_buff(PlayerStatus#player_status.id, Type, GoodsInfo#goods.goods_id, AttributeId, Value, NowTime+Time, SceneLimit),
                                            CannotReplace = 0;
                                        [BuffInfo] ->
                                            case BuffInfo#ets_buff.end_time > NowTime of
                                                true ->
                                                    if
                                                        BuffInfo#ets_buff.value =:= Value -> %同类型增加
                                                            NewTime = BuffInfo#ets_buff.end_time + Time,
                                                            case BuffInfo#ets_buff.goods_id > GoodsInfo#goods.goods_id of
                                                                true -> 
                                                                    NewBuffInfo = lib_player:mod_buff(BuffInfo, BuffInfo#ets_buff.goods_id, Value, NewTime, SceneLimit);
                                                                false ->
                                                                    NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsInfo#goods.goods_id, Value, NewTime, SceneLimit)
                                                            end,
                                                            CannotReplace = 0;
                                                        true ->                              %不同类型覆盖
                                                            case BuffInfo#ets_buff.goods_id < GoodsInfo#goods.goods_id of
                                                                true ->
                                                                    NewTime = NowTime + Time,
                                                                    NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsInfo#goods.goods_id, Value, NewTime, SceneLimit),
                                                                    CannotReplace = 0;
                                                                false ->
                                                                    NewBuffInfo = BuffInfo,
                                                                    case BuffInfo#ets_buff.goods_id - BuffInfo#ets_buff.goods_id div 10 * 10 of
                                                                        2 -> CannotReplace = 1;
                                                                        _ -> CannotReplace = 2
                                                                    end
                                                            end
                                                    end;
                                                false ->
                                                    CannotReplace = 0,
                                                    NewTime = NowTime + Time,
                                                    NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsInfo#goods.goods_id, Value, NewTime, SceneLimit)
                                            end
                                            %NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsInfo#goods.goods_id, Value, NewTime, SceneLimit)
                                    end,
                                    case CannotReplace of
                                        1 -> {fail, ?ERRCODE15_CANNOT_REPLACE_MID};
                                        2 -> {fail, ?ERRCODE15_CANNOT_REPLACE_BIG};
                                        _ ->
                                            %% 写入表, 发通知
                                            buff_dict:insert_buff(NewBuffInfo),
                                            lib_player:send_buff_notice(PlayerStatus, [NewBuffInfo]),
                                            lib_player:send_wine_buff_notice(PlayerStatus, 1, GoodsInfo#goods.goods_id),
                                            %use21(PlayerStatus, GoodsInfo, GoodsNum - 1)
                                            mod_scene_agent:update(battle_attr, PlayerStatus),
                                            {ok, PlayerStatus}
                                    end
                            end
                    end;
                false -> %% 非酒水
                    case data_goods_effect:get_val(GoodsInfo#goods.goods_id, buff) of %%获取buff类型
                        [] ->
                            {fail, ?ERRCODE15_TYPE_ERR};
                        {Type, AttributeId, _Value, _Time, _SceneLimit} when Type =:= 0 orelse Type =:= 4 
                        orelse AttributeId =:= 0 orelse Type =:= 6 ->
                            {fail, ?ERRCODE15_TYPE_ERR};
                        {Type, AttributeId, Value, _Time, SceneLimit} ->
                            Time = _Time * GoodsNum,
                            SceneId = PlayerStatus#player_status.scene,
                            case SceneLimit =:= [] orelse lists:member(SceneId, SceneLimit) of
                                false -> {fail, ?ERRCODE15_SCENE_WRONG}; %%场景限制
                                true ->
                                    NowTime = util:unixtime(),
                                    case lib_buff:match_three(PlayerStatus#player_status.player_buff, Type, AttributeId, []) of
                                    %case lib_player:get_player_buff(PlayerStatus#player_status.id, Type, AttributeId) of
                                        [] -> %%没有就加上
                                            NewBuffInfo = lib_player:add_player_buff(PlayerStatus#player_status.id, Type, 
                                                GoodsInfo#goods.goods_id, AttributeId, Value, NowTime+Time, SceneLimit),
                                            CannotReplace = 0;
                                        [BuffInfo] when Type =/= 5 andalso BuffInfo#ets_buff.type =/= 5 ->
                                            %andalso BuffInfo#ets_buff.value =:= Value ->
                                            %% 是否已过有效时间
                                            case BuffInfo#ets_buff.end_time > NowTime of
                                                true ->  
                                                    %% 物品效果与之前已使用的是否相同
                                                    case BuffInfo#ets_buff.value =:= Value of
                                                        true ->
                                                            NewTime = BuffInfo#ets_buff.end_time + Time,
                                                            %% 高级物品不能被替代，只能叠加
                                                            case BuffInfo#ets_buff.goods_id > GoodsInfo#goods.goods_id of
                                                                true ->
                                                                    NewBuffInfo = lib_player:mod_buff(BuffInfo, BuffInfo#ets_buff.goods_id, Value, NewTime, SceneLimit);
                                                                false ->
                                                                    NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsInfo#goods.goods_id, Value, NewTime, SceneLimit)
                                                            end,
                                                            CannotReplace = 0;
                                                        false ->
                                                            NewTime = NowTime + Time,
                                                            %% 效果不同，低级物品不能替代高级物品，高级物品可以替代低级物品
                                                            case BuffInfo#ets_buff.goods_id > GoodsInfo#goods.goods_id of
                                                                true ->
                                                                    NewBuffInfo = BuffInfo,
                                                                    case BuffInfo#ets_buff.goods_id - BuffInfo#ets_buff.goods_id div 10 * 10 of
                                                                        2 -> CannotReplace = 1;
                                                                        _ -> CannotReplace = 2
                                                                    end;
                                                                false ->
                                                                    NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsInfo#goods.goods_id, Value, NewTime, SceneLimit),
                                                                    CannotReplace = 0
                                                            end
                                                    end;
                                                false -> 
                                                    NewTime = NowTime + Time,
                                                    NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsInfo#goods.goods_id, Value, NewTime, SceneLimit),
                                                    CannotReplace = 0
                                            end;
                                        %NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsInfo#goods.goods_id, Value, NewTime, SceneLimit);
                                        [BuffInfo] ->
                                            NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsInfo#goods.goods_id, Value, NowTime + Time, SceneLimit),
                                            CannotReplace = 0;
                                        %% 跳到该分支说明有bug，写入日志中
                                        [H | T] ->
                                            NewBuffInfo = lib_player:mod_buff(H, GoodsInfo#goods.goods_id, Value, NowTime + Time, SceneLimit),
                                            CannotReplace = 0,
                                            catch util:errlog("~p error!! lib_player:get_player_buff : ~p~n", [?MODULE, [H | T]])
                                    end,
                                    case CannotReplace of
                                        1 -> {fail, ?ERRCODE15_CANNOT_REPLACE_MID};
                                        2 -> {fail, ?ERRCODE15_CANNOT_REPLACE_BIG};
                                        _ -> 
                                            buff_dict:insert_buff(NewBuffInfo),
                                            lib_player:send_buff_notice(PlayerStatus, [NewBuffInfo]),
                                            case Type =:= 2 orelse Type =:= 5 of
                                                %% BUFF符，喜宴
                                                true -> BuffAttribute = lib_player:get_buff_attribute(PlayerStatus#player_status.id, PlayerStatus#player_status.scene),
                                                    NewPlayerStatus = lib_player:count_player_attribute( PlayerStatus#player_status{ buff_attribute = BuffAttribute } ),
                                                    %lib_player:send_attribute_change_notify(NewPlayerStatus, 0),
                                                    %use21(NewPlayerStatus, GoodsInfo, GoodsNum - 1);
                                                    mod_scene_agent:update(battle_attr, NewPlayerStatus),
                                                    {ok, NewPlayerStatus};
                                                    false ->
                                                        %use21(PlayerStatus, GoodsInfo, GoodsNum - 1)
                                                        mod_scene_agent:update(battle_attr, PlayerStatus),
                                                        {ok, PlayerStatus}
                                                end
                                        end
                                end
                        end
                end
        end.

%% 增益类物品
use22(PlayerStatus, GoodsStatus, GoodsInfo, GoodsNum) ->
	case GoodsInfo#goods.subtype of
		%% 经验卡, 未调试
        ?GOODS_SUBTYPE_EXP ->
            Exp = data_goods_effect:get_val(GoodsInfo#goods.goods_id, exp),
            NewExp = Exp * GoodsNum,
            NewPlayerStatus = lib_player:add_exp(PlayerStatus, NewExp, 0),
            {ok, NewPlayerStatus, GoodsStatus};
		%% 铜钱卡
        ?GOODS_SUBTYPE_COIN ->
            Coin = data_goods_effect:get_val(GoodsInfo#goods.goods_id, coin),
            NewCoin = Coin * GoodsNum,
            case GoodsInfo#goods.bind > 0 of
                true ->
                    NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, NewCoin, coin),
                    log:log_produce(goods_use, coin, PlayerStatus, NewPlayerStatus, "");
                false ->
                    NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, NewCoin, coin),
                    log:log_produce(goods_use, coin, PlayerStatus, NewPlayerStatus, "")
            end,
            {ok, NewPlayerStatus, GoodsStatus};
		%% 历练声望卡
        ?GOODS_SUBTYPE_LLPT ->
            Llpt = data_goods_effect:get_val(GoodsInfo#goods.goods_id, llpt),
            NewLlpt = Llpt * GoodsNum,
            NewPlayerStatus = lib_player:add_pt(llpt, PlayerStatus, NewLlpt),
            %lib_player:send_attribute_change_notify(NewPlayerStatus, 1),
            {ok, NewPlayerStatus, GoodsStatus};
        %% 修为声望卡
        ?GOODS_SUBTYPE_XWPT ->
            Xwpt = data_goods_effect:get_val(GoodsInfo#goods.goods_id, xwpt),
            NewXwpt = Xwpt * GoodsNum,
            NewPlayerStatus = lib_player:add_pt(xwpt, PlayerStatus, NewXwpt),
            %lib_player:send_attribute_change_notify(NewPlayerStatus, 1),
            {ok, NewPlayerStatus, GoodsStatus};
        %% 背包栏
        ?GOODS_SUBTYPE_BAG_EXD ->
            CellNum = data_goods_effect:get_val(GoodsInfo#goods.goods_id, bag_num),
            NewCellNum = CellNum * GoodsNum,
            NewPlayerStatus = lib_goods_util:extend_bag(PlayerStatus, NewCellNum),
            NullCells = lists:seq((PlayerStatus#player_status.cell_num+1), NewPlayerStatus#player_status.cell_num),
            NewNullCells = GoodsStatus#goods_status.null_cells ++ NullCells,
            NewGoodsStatus = GoodsStatus#goods_status{null_cells = NewNullCells},
            {ok, NewPlayerStatus, NewGoodsStatus};
        %% 仓库栏, 暂时没有功能
        ?GOODS_SUBTYPE_STORAGE_EXD ->
            CellNum = data_goods_effect:get_val(GoodsInfo#goods.goods_id, bag_num),
            NewCellNum = CellNum * GoodsNum,
            NewPlayerStatus = lib_storage_util:extend_storage(PlayerStatus, NewCellNum),
            {ok, NewPlayerStatus, GoodsStatus};
        %% 爬塔
        ?GOODS_SUBTYPE_TOWER ->
            Honour = data_goods_effect:get_val(GoodsInfo#goods.goods_id, honour),
            NewHonour = Honour * GoodsNum,
            NewPlayerStatus = lib_player:add_honour(PlayerStatus, NewHonour),
            %lib_player:send_attribute_change_notify(NewPlayerStatus, 1),
            {ok, NewPlayerStatus, GoodsStatus};
        %% 绑定铜钱
        ?GOODS_SUBTYPE_BCOIN ->
            Bcoin = data_goods_effect:get_val(GoodsInfo#goods.goods_id, coin),
            NewBcoin = Bcoin * GoodsNum,
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, NewBcoin, coin),
            log:log_produce(goods_use, coin, PlayerStatus, NewPlayerStatus, ""),
            {ok, NewPlayerStatus, GoodsStatus};
        %% 体力值
        ?GOODS_SUBTYPE_PHYSICAL ->
            {ok, PlayerStatus, GoodsStatus};
        %% 武魂
        ?GOODS_SUBTYPE_WHPT ->
            Whpt = data_goods_effect:get_val(GoodsInfo#goods.goods_id, whpt),
            Value = Whpt * GoodsNum,
            NewPlayerStatus = lib_player:add_pt(whpt, PlayerStatus, Value),
            %lib_player:send_attribute_change_notify(NewPlayerStatus, 1),
            {ok, NewPlayerStatus, GoodsStatus};
        _ ->
            {fail, ?ERRCODE15_TYPE_ERR}
    end.

use31(PlayerStatus, GoodsInfo) ->
    case GoodsInfo#goods.subtype of
        15 ->   %% 坐骑幻化卡
            lib_mount2:use_change_card(PlayerStatus, GoodsInfo);
        13 ->   %% 坐骑灵犀丹
            lib_mount2:use_lingxi_dan(PlayerStatus, GoodsInfo);
        _ ->
            {fail, ?ERRCODE15_TYPE_ERR}
    end.

%% 帮派类
use41(PlayerStatus, GoodsInfo) ->
    if
        GoodsInfo#goods.goods_id =:= 412101 ->
            Num = 10;
        GoodsInfo#goods.goods_id =:= 412102 ->
            Num = 30;
        GoodsInfo#goods.goods_id =:= 412103 ->
            Num = 50;
        GoodsInfo#goods.goods_id =:= 412104 ->
            Num = 100;
        GoodsInfo#goods.goods_id =:= 411301 ->
            Num = 3;
        true ->
            Num = 0
    end,
    case lib_guild_base:add_guild_caifu_server(PlayerStatus#player_status.id, Num) of   
        true ->
            {ok, BinData} = pt_110:write(11004, lists:concat([data_guild_text:get_wealth(),Num])),
            lib_chat:rpc_send_msg_one(PlayerStatus#player_status.id, BinData),
            {ok, PlayerStatus};
        _ ->
            {fail, ?ERRCODE15_NO_GUILD}
    end.

%% 活动类
use52(PlayerStatus, GoodsInfo) ->
    %io:format("2~n"),
	case GoodsInfo#goods.subtype of
		%烟花类
		10 ->
            case GoodsInfo#goods.goods_id of
                %% 结婚场景烟花播放效果
                521001 ->
                    Rand = util:rand(1, 100),
                    Type = case Rand > 50 of
                        true -> 1;
                        false -> 2
                    end,
                    {ok, BinData2} = pt_271:write(27147, [PlayerStatus#player_status.id, PlayerStatus#player_status.x, PlayerStatus#player_status.y, Type]),
                    mod_disperse:cast_to_unite(lib_unite_send, send_to_scene, [PlayerStatus#player_status.scene, PlayerStatus#player_status.copy_id, BinData2]),
                    mod_marriage:add_mood([2, PlayerStatus#player_status.nickname, PlayerStatus#player_status.scene, PlayerStatus#player_status.copy_id]);
                _ ->
                    skip
            end,
			Exp = data_goods_effect:get_val(GoodsInfo#goods.goods_id, exp),
			NewPlayerStatus = lib_player:add_exp(PlayerStatus, Exp, 0),
			{ok, BinData} = pt_120:write(12022, [PlayerStatus#player_status.id, PlayerStatus#player_status.platform, PlayerStatus#player_status.server_num, PlayerStatus#player_status.platform, PlayerStatus#player_status.server_num, GoodsInfo#goods.goods_id]),
			lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
			{ok, NewPlayerStatus};
        %% 仙侣
        13 ->
			%% 临时改为全都绑定
            BCoin = data_goods_effect:get_val(GoodsInfo#goods.goods_id, coin),
            NewPlayerStatus = lib_goods_util:add_money(PlayerStatus, BCoin, coin),
            log:log_produce(goods_use, coin, PlayerStatus, NewPlayerStatus, ""),
            {ok, NewPlayerStatus};
		_ ->
			{fail, ?ERRCODE15_TYPE_ERR}
	end.

%% 任务类
use50(PlayerStatus, GoodsInfo) ->
    case GoodsInfo#goods.subtype of
        %烟花类
        11 ->
            {ok, BinData} = pt_120:write(12022, [PlayerStatus#player_status.id, GoodsInfo#goods.goods_id]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            {ok, PlayerStatus};
        _ ->
            {fail, ?ERRCODE15_TYPE_ERR}
    end.

%% 特殊类
use61(PlayerStatus, GoodsInfo, _GoodsNum, Status) ->
    case GoodsInfo#goods.subtype of
        ?GOODS_SUBTYPE_TP -> %%传送
            SceneId = data_scene_id:get(GoodsInfo#goods.goods_id),
            %% 监狱不能使用传送卷
            case SceneId =/= 0 andalso PlayerStatus#player_status.scene =/= 998 of
                true ->
					Kf3v3ChkResult = PlayerStatus#player_status.scene =:= data_kf_3v3:get_config(scene_id1) 
						orelse lists:member(PlayerStatus#player_status.scene, data_kf_3v3:get_config(scene_pk_ids)),
                    if
                        PlayerStatus#player_status.husong#status_husong.husong > 0 ->
                            {fail, ?ERRCODE15_YUNBIAO_ING};
                        is_pid(PlayerStatus#player_status.copy_id) =:= true ->
                            {fail, ?ERRCODE15_SCENE_WRONG};
						Kf3v3ChkResult =:= true ->
							{fail, ?ERRCODE15_SCENE_WRONG};
                        true ->
                            Scene = data_scene:get(SceneId),
                            case is_record(Scene, ets_scene) of
                                true ->
                                    NewPlayerStatus = lib_scene:change_scene(PlayerStatus, SceneId, 0, Scene#ets_scene.x, Scene#ets_scene.y,true),
                                    {ok, NewPlayerStatus};
                                false ->
                                    skip
                            end
                    end;
                false ->
                    {fail, ?ERRCODE15_SCENE_WRONG}
            end;
        ?GOODS_SUBTYPE_MAP -> %%藏宝图
            case data_scene_id:get_scene_event(GoodsInfo#goods.goods_id) of
                [[Scene,X,Y], Event] ->
                    if PlayerStatus#player_status.scene =/= Scene orelse PlayerStatus#player_status.x =/= X orelse PlayerStatus#player_status.y =/= Y ->
                            %% 坐标不对
                        {fail, ?ERRCODE15_SCENE_POS};
                    true ->
                        R = util:rand(1, 100),
                        {EventId, SubType, _} = select_event(Event, R),
                        %io:format(" map ~p~n", [{EventId, SubType}]),
                        case EventId of
                            1 ->    %% 招怪
                                case data_scene_id:get_event(EventId, SubType) of
                                    [] ->   %% 事件不存在
                                        nothing;
                                    E ->
                                        R1 = util:rand(1, 100),
                                        case select_mon_event(E, R1) of
                                            {0,0,0} ->
                                                nothing;
                                            {Index, MonId, _} ->
                                            % 招怪
                                                lib_boss:call_mon(PlayerStatus, Index, MonId, Scene, X, Y),
                                                T = lists:member(GoodsInfo#goods.goods_id, [613717,613718,613719,613720,613721]),
                                                if
                                                    T =:= true ->
                                                        NewPS = lib_figure:use_figure_goods(PlayerStatus, 523018);
                                                    true ->
                                                        NewPS = PlayerStatus
                                                end,
                                                {ok, NewPS}
                                        end
                                end;
                            2 ->
                                case data_scene_id:get_event(EventId, SubType) of
                                    [{0,0,0}] -> %% 啥都没有
                                        nothing;
                                    _ ->
                                        nothing
                                end;
                            _ ->
                                {ok, PlayerStatus}
                        end
                    end;
                _ ->
                    {fail, ?ERRCODE15_NOT_EVENT}
            end;
        ?GOODS_SUBTYPE_ARMOR_CHA ->
            lib_fashion_change2:add_fashion_change(PlayerStatus, GoodsInfo, 1, Status);
        ?GOODS_SUBTYPE_WEAPON_CHA ->
            lib_fashion_change2:add_fashion_change(PlayerStatus, GoodsInfo, 2, Status);
        ?GOODS_SUBTYPE_ACCE_CHA ->
            lib_fashion_change2:add_fashion_change(PlayerStatus, GoodsInfo, 3, Status);
        ?GOODS_SUBTYPE_HEAD_CHA ->
            lib_fashion_change2:add_fashion_change(PlayerStatus, GoodsInfo, 5, Status);
        ?GOODS_SUBTYPE_TAIL_CHA ->
            lib_fashion_change2:add_fashion_change(PlayerStatus, GoodsInfo, 6, Status);
        ?GOODS_SUBTYPE_RING_CHA ->
            lib_fashion_change2:add_fashion_change(PlayerStatus, GoodsInfo, 7, Status);
        %?GOODS_SUBTYPE_MOUTN_FIGURE ->
        %    lib_fashion_change2:add_fashion_change(PlayerStatus, GoodsInfo, 4, Status);
        ?GOODS_SUBTYPE_GOLD ->
            lib_player:minus_pk_value(PlayerStatus, 100),
            {ok, PlayerStatus};
        ?GOODS_SUBTYPE_RECHARGE ->
            %NowTime = util:unixtime(),
            {ok, NewPS} = lib_recharge:pay_by_goods(PlayerStatus, 1000, GoodsInfo#goods.goods_id),
            %Sql = io_lib:format(<<"insert into charge set player_id=~p, ctime=~p,gold=1000">>, [NewPS#player_status.id, NowTime]),
            %db:execute(Sql),
            {ok, NewPS};
		?GOODS_SUBTYPE_CHENGHAO ->
			Glist = data_designation_goods:get(),
			case lists:keyfind(GoodsInfo#goods.goods_id, 1, Glist) of
				false ->
					skip;
				{_, DesignId} ->
					lib_designation:bind_design_in_server(PlayerStatus#player_status.id, DesignId, "", 0)
			end,
            {ok, PlayerStatus};
        36 -> %幸运转盘
            R = util:rand(1, 10000),
            List = data_scene_id:get_turntable(GoodsInfo#goods.goods_id), 
            GoodsTypeId = get_turntable_goodstype(List, R),
            %io:format("111 ~p~n", [{R, List, GoodsTypeId}]),
            if
                GoodsTypeId =< 0 ->
                    {fail, ?ERRCODE15_NO_RULE};
                true ->
                    F = fun() ->
                        GoodsList = [{goods, GoodsTypeId, 1, 2}],
                        ok = lib_goods_dict:start_dict(),
                        {ok, NewStatus} = lib_goods_check:list_handle(fun lib_goods:give_goods/2, Status, GoodsList),
                        Dict = lib_goods_dict:handle_dict(NewStatus#goods_status.dict),
                        NewStatus2 = NewStatus#goods_status{dict = Dict},
                        {ok, NewStatus2}
                end,
                case lib_goods_util:transaction(F) of
                        {ok, NewStatus} ->
                            {ok, BinData} = pt_630:write(63015, GoodsTypeId),
                            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
                            %%传闻
                            T = lists:member(GoodsTypeId, [621101, 112104, 111030, 112231, 112105]),
                            if
                                T =:= true ->
                                    lib_chat:send_TV({all},0,3, ["findLuck", 
													0, 
													PlayerStatus#player_status.id, 
													PlayerStatus#player_status.realm, 
													PlayerStatus#player_status.nickname, 
													PlayerStatus#player_status.sex, 
													PlayerStatus#player_status.career, 
													PlayerStatus#player_status.image, 
													GoodsTypeId]);
                                true ->
                                    skip
                            end,
                            log:log_table(PlayerStatus#player_status.id, GoodsInfo#goods.goods_id, GoodsTypeId),
                            {ok, PlayerStatus, NewStatus};
                       _ ->
                            {fail, ?ERRCODE15_NO_RULE}
                end
            end;
        _ ->
            skip
    end.

get_turntable_goodstype([], _R) ->
    0;
get_turntable_goodstype([{GoodsId, Rem}|H], R) ->
    case Rem >= R of
        true ->
            GoodsId;
        false ->
            get_turntable_goodstype(H, R)
    end.

select_event([], _R) ->
    {0, 0, 0};
select_event([{EventId, SubType, Rem}|H], R) ->
    case Rem >= R of
        true ->
            {EventId, SubType, Rem};
        false ->
            select_event(H, R)
    end.

select_mon_event([], _R) ->
    {0,0,0};
select_mon_event([{Index, EventId, Rem}|H], R) ->
    case Rem >= R of
        true ->
            {Index, EventId, Rem};
        false ->
            select_mon_event(H, R)
    end.

%% VIP卡
use63(PlayerStatus, GoodsInfo, GoodsNum) ->
	case GoodsInfo#goods.subtype of
        %% 周卡
        ?GOODS_VIPTYPE_WEEK ->
            lib_vip:add_vip(PlayerStatus, 1, 3600*24*7);
        %% VIP月卡
        ?GOODS_VIPTYPE_MON ->
            lib_vip:add_vip(PlayerStatus, 2, 3600*24*30);
        %% VIP半年卡
        ?GOODS_VIPTYPE_HYEAR ->
            lib_vip:add_vip(PlayerStatus, 3, 3600*24*180);
        %% VIP一天
        ?GOODS_VIPTYPE_1DAY ->
            lib_vip:add_vip(PlayerStatus, 1, 3600*24*1);
        %% VIP三天
        ?GOODS_VIPTYPE_3DAY ->
            lib_vip:add_vip(PlayerStatus, 1, 3600*24*3);
        ?GOODS_VIPTYPE_EXPERIENCE ->
            lib_vip:add_vip(PlayerStatus, 1, 60*30);
        %% vip成长丹
        ?GOODS_VIPTYPE_GROWTH ->
            case PlayerStatus#player_status.vip#status_vip.vip_type of
                3 ->
                    GrowthExp = case GoodsInfo#goods.goods_id of
                        632000 -> 1 * GoodsNum;
                        632001 -> 10 * GoodsNum;
                        632002 -> 20 * GoodsNum;
                        632003 -> 30 * GoodsNum;
                        _ -> 0
                    end,
                    lib_vip_info:add_growth_exp(PlayerStatus#player_status.id, GrowthExp),
                    {ok, PlayerStatus};
                _ ->
                    error
            end;
        _ ->
            {fail, ?ERRCODE15_TYPE_ERR}
    end.

%% 宠物类
use62(PlayerStatus, _GoodsStatus, GoodsInfo, GoodsUseNum) ->
    %% case lib_pet:is_skill_book(GoodsInfo#goods.goods_id) of
    %%     true ->
    %% 	    gen_server:cast(PlayerStatus#player_status.pid, {'learn_pet_skill', [GoodsInfo, 1]}),
    %% 	    {skip, "pet_skill"};
    %% 	false ->
            case GoodsInfo#goods.subtype of
		%% 宠物蛋
		10 ->
                    gen_server:cast(PlayerStatus#player_status.pid, {'incubate_pet', [GoodsInfo, 1]}),
		    {skip, "incubate"};
		%% 口粮
                13 ->
		    gen_server:cast(PlayerStatus#player_status.pid, {'feed_pet', [GoodsInfo, 1]}),
		    {skip, "feed_pet"};
		%% 潜能修行
		% 48 ->
		%     gen_server:cast(PlayerStatus#player_status.pid, {'practice_potential', [GoodsInfo, GoodsUseNum]}),
		%     {skip, "practice_potentials"};
		%% 成长丹
		% 42 ->
		%     gen_server:cast(PlayerStatus#player_status.pid, {'pet_grow_up', [GoodsInfo, GoodsUseNum]}),
		%     {skip, "grow_up"};
		%% 资质符
		11 ->
		    gen_server:cast(PlayerStatus#player_status.pid, {'pet_aptitude_up', [GoodsInfo, GoodsUseNum]}),
		    {skip, "aptitude_up"};
		%% 幻化卡
		14 ->
		    gen_server:cast(PlayerStatus#player_status.pid, {'pet_figure_activate', [GoodsInfo, GoodsUseNum]}),
		    {skip, "pet_figure_activate"};
		%% 经验丹
		30 ->
		    gen_server:cast(PlayerStatus#player_status.pid, {'pet_upgrade', [GoodsInfo, GoodsUseNum]}),
		    {skip, "pet_upgrade"};
		_ ->
		    skip
	    %% end
    end.

use67(PlayerStatus, Status, GoodsInfo) ->
    case GoodsInfo#goods.subtype of
        %% 任务触发物品
        10 ->
            TaskId = data_task_goods:get_trigger_task(GoodsInfo#goods.goods_id),
            case TaskId > 0 of
                true -> 
                    gen_server:cast(PlayerStatus#player_status.pid, {'use_task_goods', [GoodsInfo, 1]}),
                    {ok, PlayerStatus, Status};
                false -> {fail, ?ERRCODE15_TYPE_ERR}
            end;
        _ ->
            {fail, ?ERRCODE15_TYPE_ERR}
    end.

use69(PlayerStatus, Status, GoodsInfo) ->
    case GoodsInfo#goods.subtype of
        %% 飞行道具
        10 ->
            case data_fly_mount:get(GoodsInfo#goods.goods_id) of
                [] ->
                    {fail, ?ERRCODE15_TYPE_ERR};
                _ ->
                    gen_server:cast(PlayerStatus#player_status.pid, {'use_fly_goods', [GoodsInfo]}),
                    {ok, PlayerStatus, Status} 
            end;
        _ ->
            {fail, ?ERRCODE15_TYPE_ERR}
    end.
