%%%--------------------------------------
%%% @Module  : lib_fame_merge
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.10.22
%%% @Description: 合服时名人堂投票
%%%--------------------------------------

-module(lib_fame_merge).
-include("fame.hrl").
-include("rank.hrl").
-include("unite.hrl").
-include("designation.hrl").
-compile(export_all).

%% [公共线] 获取名人堂数据
%% 打开名人堂tab页入口函数，可能返回两种协议的数据
get_fame_data(UniteStatus) ->
	case UniteStatus#unite_status.mergetime of
		%% 没合过区
		0 ->
			Data =  lib_rank:pp_get_rank(?RK_FAME),
			{ok, BinData} = pt_220:write(22074, Data),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		_ ->
			case get_fame_version() of
				%% 旧名人堂数据被删除，因此跟新服流程一样，需要重新触发合人堂
				1 ->
					Data =  lib_rank:pp_get_rank(?RK_FAME),
					{ok, BinData} = pt_220:write(22074, Data),
					lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				_ ->
					MergeDay = util:unixdate(UniteStatus#unite_status.mergetime),
					DayTime = util:unixdate(),
					case DayTime >= MergeDay andalso DayTime < MergeDay + 4  * 86400 of
						%% 合服后4天内，显示投票页面
						true ->
		                    get_vote_data(UniteStatus);

						%% 合服后第5天开始，显示正常的名人堂界面
						_ ->
							Data =  lib_rank:pp_get_rank(?RK_FAME),
							{ok, BinData} = pt_220:write(22074, Data),
							lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
					end
			end
	end.

%% [公共线] 打开合服名人堂
get_merge_fame_data(UniteStatus) ->
	case UniteStatus#unite_status.mergetime of
		%% 没合过区，跳过
		0 ->
			skip;
		_ ->
			Data =  lib_rank:pp_get_rank(?RK_FAME),
			{ok, BinData} = pt_220:write(22076, Data),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end.

%% 显示投票数据
get_vote_data(US) ->
	LeftTime = case US#unite_status.mergetime of
		0 -> 0;
		_ ->
			DayTime = util:unixdate(US#unite_status.mergetime),
			LeftSecond = DayTime + 4 * 86400 - util:unixtime() - 600,
			case LeftSecond < 0 of
				true -> 0;
				_ -> LeftSecond
			end
	end,
	{ok, BinData} = pt_220:write(22075, [private_get_vote_data(), LeftTime]),
	lib_unite_send:send_to_sid(US#unite_status.sid, BinData).

%% 玩家送花给支持的人
support(MergeTime, ToId, FromId, FlowerNum) ->
    case private_check_send_flower(MergeTime) of
        1 ->
            private_update_vote(ToId, FlowerNum),
            case ToId /= FromId of
                true ->
                    private_update_vote(FromId, FlowerNum);
                _ ->
                    skip
            end;
        _ ->
            skip
    end.

%% 秘籍，处理投票结果
handle_vote_in_manage() ->
	do_vote().

%% 管理后台调用
vote_in_manage() ->
	mod_disperse:cast_to_unite(lib_fame_merge, handle_vote_in_manage, []).

%% 处理投票结果
%% 由timer_daily调用，下面在第4天至第5天第1个小时会被触发逻辑
do_vote() ->
	NowTime = util:unixtime(),
	MergeDay = lib_activity_merge:get_activity_day(),
	LimitTime = MergeDay + 4 * 86400,
	case NowTime > LimitTime andalso NowTime < LimitTime + 3600 of
		true ->
			case db:get_one(io_lib:format(?SQL_FAME_VERSION, [])) of
				1 ->
					skip;
				_ ->
					private_do_vote()
			end;
		_ ->
			skip
	end.

%% 取得名人堂版本
%% 返回值：1合服时被删除了数据，0没有被删除数据
get_fame_version() ->
	case mod_daily_dict:get_special_info(lib_fame_merge_version) of
		undefined ->
			case db:get_one(io_lib:format(?SQL_FAME_VERSION, [])) of
				null ->
					mod_daily_dict:set_special_info(lib_fame_merge_version, 0),
					0;
				Vsn ->
					mod_daily_dict:set_special_info(lib_fame_merge_version, Vsn),
					Vsn
			end;
		Version ->
			Version
	end.

%% 处理投票结果
private_do_vote() ->
	NowTime = util:unixtime(),
	%% 取出所有玩家ID，名人堂ID，投票记录
    List = db:get_all(io_lib:format(?SQL_FAME_VOTE_SELECT2, [])),
	%% 取出所有玩家对应的昵称
	NickList = private_get_rolename(List),
    ReturnList = private_format_vote(List, []),
    lists:foreach(fun({FameId, TmpRoleList}) ->
		RoleList = private_sort_vote(TmpRoleList),
		BaseFame = data_fame:get_fame(FameId),

		MailTitle = io_lib:format(data_merge_text:get_fame_vote_title(), [BaseFame#base_fame.name]),
		MailContent = private_format_mail_content(BaseFame#base_fame.name, NickList, RoleList),

		%% 删除旧名人堂记录
		db:execute(io_lib:format(?SQL_FAME_DELETE2, [FameId])),

		[_, ToMailRole] = 
			lists:foldl(fun([_FId, RoleId, _Vote], [Position, MailRole]) ->
			case Position < 4 of
				%% 前三名获得称号
				true ->
					%% 插入名人堂记录
					db:execute(io_lib:format(?SQL_FAME_INSERT, [FameId, RoleId, NowTime])),
					case BaseFame#base_fame.design_id of
						0 -> skip;
						_ ->
							lib_designation:bind_design_in_server(RoleId, BaseFame#base_fame.design_id, "", 1)
					end,
					[Position + 1, MailRole];

				%% 其他名次获得补偿礼包，通过邮件发送
				_ ->
					[Position + 1, [RoleId | MailRole]]
			end
		end, [1, []], RoleList),

		%% 其他名次获得补偿礼包，通过邮件发送
		case ToMailRole of
			[] -> skip;
			_ ->
				lib_mail:send_sys_mail_bg(
					ToMailRole,
					MailTitle,
					MailContent,
					lib_gift_new:get_goodsid_by_giftid(0), 
					2, 0, 0, 1, 0, 0, 0, 0
				)
		end
    end, ReturnList),

	%% 刷新名人堂
	lib_rank:refresh_single(?RK_FAME).

%% 对玩家的投票数进行排序
private_sort_vote(List) ->
	lists:sort(fun([_, _, Vote1], [_, _, Vote2]) -> 
		Vote1 >= Vote2
	end, List).

%% 检查送花是否会影响支持度
%% 返回：0否，1是
private_check_send_flower(MergeTime) ->
    case MergeTime of
		%% 没合过区
		0 -> 
			0;
		_ ->
			MergeDay = util:unixdate(MergeTime),
			case MergeDay + 4  * 86400 - 600 > util:unixdate() of
				%% 合服后第不超过4天缺10分钟
				true -> 
					1;
				_ -> 
					0
			end
	end.

%% 从数据库中批量取出玩家昵称
private_get_rolename(List) ->
	PlayerList = [PlayerId || [_FameId, PlayerId, _Vote] <- List],
	%% 玩家id去重
	PlayerList2 = sets:to_list(sets:from_list(PlayerList)),
	StringIds = lists:concat(
		util:implode(",", PlayerList2)
	),
	db:get_all(io_lib:format(?SQL_FAME_GET_PLAYER, [StringIds])).

%% 通过玩家id取到玩家昵称
private_get_name_by_id([], _Id) -> undefined;
private_get_name_by_id([[RoleId, RoleName] | Tail], Id) ->
	case RoleId =:= Id of
		true -> RoleName ;
		_ ->
			private_get_name_by_id(Tail, Id)
	end.

private_format_mail_content(FameName, NickList, StatList) ->
	ContentList = lists:map(fun([_FameId, PlayerId, Vote]) -> 
		Nick = private_get_name_by_id(NickList, PlayerId),
		io_lib:format("~s：~p", [Nick, Vote])
	end, StatList),
	Content = lists:concat(
		util:implode("\n", ContentList)
	),
	Content2 = lists:flatten(Content),
	io_lib:format(
		data_merge_text:get_fame_vote_content(),
		[FameName, Content2]
	).

%% 格式化投票数据
private_format_vote([], List) ->
   List;
private_format_vote([Row | Tail], List) ->
    NewList = private_format_vote2(Row, List),
    private_format_vote(Tail, NewList).

private_format_vote2(Row, List) ->
	[FameId | _] = Row,
    [LastList, LastExist] = 
    lists:foldl(fun({TargetFameId, TargetPlayer}, [ParamList, ParamExist]) -> 
        case FameId =:= TargetFameId of
            true ->
                [[{TargetFameId, [Row | TargetPlayer]} | ParamList], 1];
            _ ->
                [[{TargetFameId, TargetPlayer} | ParamList], ParamExist]
        end
    end, [[], 0], List),
    case LastExist of
        0 -> [{FameId, [Row]} | LastList];
        1 -> LastList
    end.

%% 获取投票数据，返回列表
private_get_vote_data() ->
	case db:get_all(io_lib:format(?SQL_FAME_VOTE_SELECT3, [])) of
		[] ->
			[];
		List ->
			List2 = private_format_vote(List, []),
			lists:map(fun({FameId, RoleList}) -> 
				PlayerList = lists:map(fun([_, PlayerId, Vote, NickName, Realm, Career, Sex]) ->
					Name = pt:write_string(NickName),
					<<PlayerId:32, Name/binary, Realm:8, Career:8, Sex:8, Vote:32>>
				end, RoleList),
				PlayerLen = length(PlayerList),
				PlayerBin = list_to_binary(PlayerList),
				BaseFame = data_fame:get_fame(FameId),
				DesignId = BaseFame#base_fame.design_id,
				BaseDesign = data_designation:get_by_id(DesignId),
				DesignName = pt:write_string(BaseDesign#designation.name),
				<<DesignId:32, DesignName/binary, FameId:32, PlayerLen:16, PlayerBin/binary>>
			end, List2)
	end.

%% 更新支持度
private_update_vote(RoleId, VoteNum) ->
	db:execute(io_lib:format(?SQL_FAME_VOTE_UPDATE, [VoteNum, RoleId])).
