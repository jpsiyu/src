%%%--------------------------------------
%%% @Module  : lib_target
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.2
%%% @Description: 目标
%%%--------------------------------------

-module(lib_target).
-include("server.hrl").
-include("target.hrl").
-include("gift.hrl").
-include("activity.hrl").

-define(sql_target_select, <<"SELECT status FROM role_target WHERE role_id=~p AND target_id=~p LIMIT 1">>).

-export([
	online/1,
	offline/1, 
	trigger/3,
	trigger_offline/2,
	get_all/1,
	insert/3,
	fetch_gift_award/2,
	fetch_level_award/2,
	check_level_award/2,
	refresh_client/1
]).

%% 功能开关：false关，true开
get_switch() ->
	lib_switch:get_switch(target).

%% 上线操作
online(RoleId) ->
    private_reload(RoleId).

%% 下线操作
offline(RoleId) ->
	private_erase(RoleId).

%% 获取所有记录
get_all(RoleId) ->
	List = case get(?GAME_TARGET_ALLID(RoleId)) of
		undefined ->
			private_reload(RoleId);
		R ->
			R
	end,
	F = fun(Id) ->
		get(?GAME_TARGET(RoleId, Id))
	end,
	[F(TargetId) || TargetId <- List].


%% 触发目标达成
%% TargetId 目标ID，TargetData：目标的数据，下面private_trigger_target/3 里面有所有的目标说明，比如
%%  目标：将武器升级到30级 101
%%  private_trigger_target(RoleId, 101, Level)
trigger(RoleId, TargetId, TargetData) ->
	case get_switch() of
		true ->
            %%io:format("TargetData:~p ~n",[[?MODULE,?LINE,TargetId,TargetData]]),
			private_trigger_target(RoleId, TargetId, TargetData);
		_ ->
			skip
	end.

%% 离线触发目标
trigger_offline(RoleId, TargetId) ->
	case db:get_row(io_lib:format(?sql_target_select, [RoleId, TargetId])) of
		[_Status] ->
			skip;
		_ ->
			db:execute(io_lib:format(?sql_target_insert, [RoleId, TargetId, 1]))
	end.

%% 领取礼包奖励
fetch_gift_award(PS, TargetId) ->
	case get_switch() of
		true ->
			case private_can_fetch_gift(PS#player_status.id, TargetId) of
				{ok, TargetInfo} ->
					%% 调用礼包接口领取礼包
					G = PS#player_status.goods,
					case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, TargetInfo#game_target.gift_id}) of
						{ok, [ok, NewPS]} ->
							%% 更新目标奖励为已领取奖励
							insert(PS#player_status.id, TargetId, 2),
                            
				                            %% 检查是否完成所有奖励的领取
				                            private_finish_all_target(PS, TargetId),

							{ok, NewPS, TargetInfo#game_target.gift_id};
						{ok, [error, ErrorCode]} ->
							{error, ErrorCode};
						_ ->
							{error, 999}
					end;
				{error, ErrorCode} ->
					{error, ErrorCode}
			end;
		_ ->
			{error, 999}
	end.

%% 插入新记录
insert(RoleId, TargetId, Status) ->
	RD = #role_target{id = {RoleId, TargetId}, status = Status},
	private_save(RD).

%% 检查达到指定等级后弹出来的小窗奖励是否可以领取
check_level_award(PS, GiftId) ->
	LV = PS#player_status.lv,
	RequireLV = private_gift_require_level(GiftId),
	CacheKey = lists:concat(["target_get_gift_", GiftId]),
	case LV < RequireLV of
		true ->
			{error, 3};
		_ ->
			case get(CacheKey) of
				1 ->
					{error, 4};
				_ ->
					case lib_gift:is_fetch_gift(PS#player_status.id, GiftId) of
						%% 已经领取
						true -> 
							put(CacheKey, 1),
							{error, 4};
						_ ->
							%% 如果是下面这个指定的礼包id，则不需要处理，直接设置为已经领取
							case GiftId =:= ?FRIENDID_GIFT_ID of
								true ->
									lib_gift:trigger_finish(PS#player_status.id, GiftId),
									{ok, endaction};
								_ ->
									{ok, fetchgift}
							end
					end
			end
	end.

%% 领取达到指定等级后弹出来的小窗奖励
fetch_level_award(PS, GiftId) ->
	case lib_gift:is_fetch_gift(PS#player_status.id, GiftId) of
		%% 已经领取
		true -> 
			{error, 4};
		_ ->
			LV = PS#player_status.lv,
			RequireLV = private_gift_require_level(GiftId),
			case LV < RequireLV of
				true ->
					{error, 3};
				_ ->
					case GiftId =:= ?FRIENDID_GIFT_ID of
						true ->
							lib_gift:trigger_finish(PS#player_status.id, GiftId),
							{ok, PS};
						_ ->
							case lib_gift:fetch_gift(PS, GiftId) of
								{ok, NewPS} ->
									lib_gift:trigger_finish(PS#player_status.id, GiftId),
									{ok, NewPS};
								{error, ErrorCode} ->
									{error, ErrorCode}
							end
					end
			end
	end.

%% 刷新前端数据
refresh_client(PS) ->
	%% 获取配置数据
	DataList = data_target:get_all(),

	%% 获取玩家完成的数据
	RoleList = mod_target:get_all(PS#player_status.status_target, PS#player_status.id),

	%% 循环每个阶段
	NewRoleList = [private_foreach_steps(Item, RoleList) || Item <- DataList],

	%% 处理子目标列表
	case RoleList of
		[] ->
			TargetList = [];
		List ->
			F = fun(RD) ->
				#role_target{id={_RoleId, TargetId}, status=Status} = RD,
				<<TargetId:32, Status:8>>
			end,
			TargetList = [F(Item) || Item <- List]
	end,

	{ok, BinData} = pt_341:write(34101, [NewRoleList, TargetList]),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData).

%% 目标进程内部刷新前端数据
private_refresh_client(RoleId) ->
	%% 获取配置数据
	DataList = data_target:get_all(),
	%% 获取玩家完成的数据
	RoleList = get_all(RoleId),
	%% 循环每个阶段
	NewRoleList = [private_foreach_steps(Item, RoleList) || Item <- DataList],

	%% 处理子目标列表
	case RoleList of
		[] ->
			TargetList = [];
		List ->
			F = fun(RD) ->
				#role_target{id={_RoleId, TargetId}, status=Status} = RD,
				<<TargetId:32, Status:8>>
			end,
			TargetList = [F(Item) || Item <- List]
	end,
	{ok, BinData} = pt_341:write(34101, [NewRoleList, TargetList]),
	lib_server_send:send_to_uid(RoleId, BinData).

%% 获取指定等级新手礼包id需要的等级
private_gift_require_level(GiftId) ->
	if
		%% 宠物礼包需要6级才能领
		GiftId =:= ?PET_LEVEL_GIFT_ID -> 6;
		%% 坐骑礼包需要16级才能领
		GiftId =:= ?MOUNT_LEVEL_GIFT_ID -> 16;
		%% 元神
		GiftId =:= ?MODULE_OPEN_MIND -> 19;
		%% 帮派
		GiftId =:= ?MODULE_OPEN_GUILD -> 25;
		%% 市场
		GiftId =:= ?MODULE_OPEN_MARKET -> 30;
		%% 铸造
		GiftId =:= ?MODULE_OPEN_STREN -> 35;
		%% 日常
		GiftId =:= ?MODULE_OPEN_DAILY -> 32;
		%% 淘宝
		GiftId =:= ?MODULE_OPEN_TAOBAO -> 33;
		%% 炼炉
		GiftId =:= ?MODULE_OPEN_LIANLU -> 33;
		%% 宝石
		GiftId =:= ?MODULE_OPEN_STONE -> 34;
		true -> 101
	end.

%% 判断目标奖励是否可以领取
%% 错误码：
%%			2：目标不存在
%%			3：目标未完成
%%			4：奖励已经领取
private_can_fetch_gift(RoleId, TargetId) ->
	case data_target:get_by_id(TargetId) of
		[] ->
			{error, 2};
		TargetInfo ->
			case private_fetch_row(RoleId, TargetId) of
				[] ->
					{error, 3};
				RoleTarget ->
					if
						RoleTarget#role_target.status =:= 2 ->
							{error, 4};
						true ->
							{ok, TargetInfo}
					end
			end
	end.

%% 获取一条记录
private_fetch_row(RoleId, TargetId) ->
	case get(?GAME_TARGET(RoleId, TargetId)) of
		undefined ->
			[];
		RD ->
			RD
	end.

%% db数据重载到字典中
private_reload(RoleId) ->
	private_erase(RoleId),
    List = db:get_all(io_lib:format(?sql_target_fetch_all, [RoleId])),
    D = private_list_to_record(List, []),
    put(?GAME_TARGET_ALLID(RoleId), D),
	D.

%% 清除目标数据
private_erase(RoleId) ->
	case erase(?GAME_TARGET_ALLID(RoleId)) of
		List when is_list(List), List =/= [] ->
			[erase(?GAME_TARGET(RoleId, Id)) || Id <- List];
		_ ->
			skip
	end.

%% 插入新记录
private_insert(RoleId, TargetId, Status) ->
	RD = #role_target{id = {RoleId, TargetId}, status = Status},
	private_save(RD).

%% 保存
private_save(RD) ->
	{RoleId, TargetId} = RD#role_target.id,
	db:execute(io_lib:format(?sql_target_insert, [RoleId, TargetId, RD#role_target.status])),
	put(?GAME_TARGET(RoleId, TargetId), RD),
	case get(?GAME_TARGET_ALLID(RoleId)) of
		undefined ->
			private_reload(RoleId);
		List ->
			NewList = [TargetId | lists:delete(TargetId, List)],
			put(?GAME_TARGET_ALLID(RoleId), NewList)
	end.

%% 数据表记录转成列表
private_list_to_record([], D) ->
    D;
private_list_to_record([[RoleId, TargetId, Status] | T], D) ->
	put(?GAME_TARGET(RoleId, TargetId), #role_target{id = {RoleId, TargetId}, status = Status}),
	private_list_to_record(
		T,
		[TargetId | D]
	).

%% 目标达成
private_finish_target(RoleId, TargetId) ->
	private_insert(RoleId, TargetId, 1),
	private_refresh_client(RoleId).

%%  目标：将武器升级到30级 101
private_trigger_target(RoleId, 101, Level) ->
    case Level >= 10 of
        true ->
            case private_fetch_row(RoleId, 101) of
                [] -> 
                    private_finish_target(RoleId, 101);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%%  目标：将心法升到5级 102
private_trigger_target(RoleId, 102, Level) ->
    case Level >= 0 of
        true ->
            case private_fetch_row(RoleId, 102) of
                [] -> 
                    private_finish_target(RoleId, 102);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%%  目标: 拥有五位好友 103 
private_trigger_target(RoleId, 103, Sum) ->
    case Sum >= 5 of
        true ->
            case private_fetch_row(RoleId, 103) of
                [] -> 
                    private_finish_target(RoleId, 103);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%% 目标：通关封魔录3关 104
private_trigger_target(RoleId, 104, _) ->
    case private_fetch_row(RoleId, 104) of
        [] -> 
            private_finish_target(RoleId, 104);
        _ -> 
            skip
    end,
    true;

%%目标：将强化总等级提升到20级 105
private_trigger_target(RoleId, 105, EquipSum) ->
    case EquipSum >= 19 of
        true ->
            case private_fetch_row(RoleId, 105) of
                [] -> 
                    private_finish_target(RoleId, 105);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%% 目标：将宠物升到20级 201
private_trigger_target(RoleId, 201, Level) ->
    case Level >= 20 of
        true ->
            case private_fetch_row(RoleId, 201) of
                [] -> 
                    private_finish_target(RoleId, 201);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;


%% 目标：集满一套装备 202
private_trigger_target(RoleId, 202, EquipSum) ->
    case EquipSum >= 12 of
        true ->
            case private_fetch_row(RoleId, 202) of
                [] -> 
                    private_finish_target(RoleId, 202);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%% 目标：加入一个帮派或创建一个帮派 203
private_trigger_target(RoleId, 203, _) ->
    case private_fetch_row(RoleId, 203) of
        [] -> 
            private_finish_target(RoleId, 203);
        _ -> 
            skip
    end,
    true;

%% 目标：将强化总等级提升到40级 204
private_trigger_target(RoleId, 204, EquipSum) ->
    case EquipSum >= 39 of
        true ->
            case private_fetch_row(RoleId, 204) of
                [] -> 
                    private_finish_target(RoleId, 204);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%% 目标：将任意一件装备进阶到紫色 205
private_trigger_target(RoleId, 205, EquipColor) ->
    case EquipColor >= 3 of
        true ->
            case private_fetch_row(RoleId, 205) of
                [] -> 
                    private_finish_target(RoleId, 205);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%% 目标：获得一个资质大于680的宠物 301
private_trigger_target(RoleId, 301, PetAptitude) ->
    case PetAptitude >= 680 of
        true ->
            case private_fetch_row(RoleId, 301) of
                [] -> 
                    private_finish_target(RoleId, 301);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%% 目标：将所有装备升级到30级以上 302
private_trigger_target(RoleId, 302, Whether302) ->
    case Whether302 of
        true ->
            case private_fetch_row(RoleId, 302) of
                [] -> 
                    private_finish_target(RoleId, 302);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%% 目标：洗炼出一条紫色属性 303
private_trigger_target(RoleId, 303, Whether303) ->
    case Whether303 of
        true ->
            case private_fetch_row(RoleId, 303) of
                [] -> 
                    private_finish_target(RoleId, 303);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%%  目标：将心法的总等级提升到30级 304
private_trigger_target(RoleId, 304, Level) ->
    case Level >= 3 of
        true ->
            case private_fetch_row(RoleId, 304) of
                [] -> 
                    private_finish_target(RoleId, 304);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%% 目标：开启10个以上的宝石孔 305
private_trigger_target(RoleId, 305, Sum) ->
    case Sum >= 10 of
        true ->
            case private_fetch_row(RoleId, 305) of
                [] -> 
                    private_finish_target(RoleId, 305);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%% 目标：将宠物提升到40级401
private_trigger_target(RoleId, 401, Lev) ->
    case Lev >= 40 of
        true ->
            case private_fetch_row(RoleId, 401) of
                [] -> 
                    private_finish_target(RoleId, 401);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%%  目标：将坐骑进阶到第二阶 402
private_trigger_target(RoleId, 402, Level) ->
    case Level >= 2 of
        true ->
            case private_fetch_row(RoleId, 402) of
                [] -> 
                    private_finish_target(RoleId, 402);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%%  目标：通关24关装备副本 403
private_trigger_target(RoleId, 403, _) ->
    case private_fetch_row(RoleId, 403) of
        [] -> 
            private_finish_target(RoleId, 403);
        _ -> 
            skip
    end,
    true;

%% 目标：通关封魔录8层 404
private_trigger_target(RoleId, 404, _) ->
    case private_fetch_row(RoleId, 404) of
        [] -> 
            private_finish_target(RoleId, 404);
        _ -> 
            skip
    end,
    true;

%%目标：将宠物的成长提升到20以上 405
private_trigger_target(RoleId, 405, Growth) ->
    case Growth >= 20 of
        true ->
            case private_fetch_row(RoleId, 405) of
                [] -> 
                    private_finish_target(RoleId, 405);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%%  目标：将等级提升到55级 501
private_trigger_target(RoleId, 501, Level) ->
    case Level >= 55 of
        true ->
            case private_fetch_row(RoleId, 501) of
                [] -> 
                    private_finish_target(RoleId, 501);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%%  目标：洗炼属性条超过50条 502
private_trigger_target(RoleId, 502, Sum) ->
    case Sum >= 50 of
        true ->
            case private_fetch_row(RoleId, 502) of
                [] -> 
                    private_finish_target(RoleId, 502);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%% 目标：强化总等级200级以上 503
private_trigger_target(RoleId, 503, EquipSum) ->
    case EquipSum >= 199 of
        true ->
            case private_fetch_row(RoleId, 503) of
                [] -> 
                    private_finish_target(RoleId, 503);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%% 目标：将任意一件装备的品质提升到精良 504
private_trigger_target(RoleId, 504, Prefix) ->
    case Prefix >= 2 of
        true ->
            case private_fetch_row(RoleId, 504) of
                [] -> 
                    private_finish_target(RoleId, 504);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;

%%  目标：心法境界阶段到达凝气聚神 505
private_trigger_target(RoleId, 505, Level) ->
    case Level >= 1 of
        true ->
            case private_fetch_row(RoleId, 505) of
                [] -> 
                    private_finish_target(RoleId, 505);
                _ -> 
                    skip
            end;
        _ ->
            skip
    end,
    true;



%% 容错
private_trigger_target(_, Type, TypeValue) ->
	util:errlog("error! Module=lib_target, Funcion=private_trigger_target, Param=(~p, ~p)", [Type, TypeValue]),
	true.

private_foreach_steps({Step, Ids}, RoleList) ->
	%% 循环阶段Step下面所有的子目标Ids
	%% 检查目标ids，在我完成的目标记录RoleList里面的情况
	{RoleList, NewNum} = lists:foldl(fun private_count_num/2, {RoleList, 0}, Ids),
	<<Step:8, NewNum:8>>.

private_count_num(Id, {RoleList, Num}) ->
	%% 在我完成的记录里面，查找Id
	{Id, NewNum} = lists:foldl(fun private_count_num2/2, {Id, Num}, RoleList),
	{RoleList, NewNum}.

private_count_num2(RoleTarget, {Id, Num}) ->
	#role_target{id={_RoleId, TargetId}, status=Status} = RoleTarget,
	if
		TargetId =:= Id andalso Status =:= 2 ->
			{Id, Num + 1};
		true ->
			{Id, Num}
	end.

%% 检查是否领取完所有目标，全部完成的话，目标图标将不再出现
private_finish_all_target(PS, TargetId) ->
    CheckList = [501, 502, 503, 504, 505],
    case lists:member(TargetId, CheckList) of
        true ->
            Bool = lists:all(fun(Tid) -> 
                case get(?GAME_TARGET(PS#player_status.id, Tid)) of
                    Target when is_record(Target, role_target) ->
                        case Target#role_target.status == 2 of
                            true ->
                                true;
                            _ ->
                                false
                        end;
                    _ ->
                        false
                end
            end, CheckList),
            case Bool of
                true ->
                    lib_activity:finish_activity(PS, ?ACTIVITY_FINISH_TARGET); 
                _ ->
                    skip
            end;
        _ ->
            skip
    end.

