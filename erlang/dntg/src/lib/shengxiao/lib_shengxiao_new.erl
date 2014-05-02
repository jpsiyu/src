%%%------------------------------------------------
%%% @Module  : lib_shengxiao_new
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.5.30
%%% @Description: 生肖大奖工具函数
%%%------------------------------------

-module(lib_shengxiao_new).
-include("common.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("shengxiao.hrl").
-compile(export_all).

%% 获取个人已投注信息(63001) (公共线)
member(PlayerId) ->
	%% 查看用户是否已有投注信息
	case mod_shengxiao_new:member(PlayerId) of
		undefined -> [{0, 0}, {0, 0}, {0, 0}, {0, 0}];
		Any -> %% Any = #shengxiao_member{}
			Option1 = Any#shengxiao_member.option1,
			Option2 = Any#shengxiao_member.option2,
			Option3 = Any#shengxiao_member.option3,
			Option4 = Any#shengxiao_member.option4,
			Local1  = Any#shengxiao_member.local1,
			Local2  = Any#shengxiao_member.local2,
			Local3  = Any#shengxiao_member.local3,
			Local4  = Any#shengxiao_member.local4,
			[{Local1, Option1}, {Local2, Option2}, {Local3, Option3}, {Local4, Option4}]
	end.

%% 刷新其他用户投注信息(63002) (公共线)
other_betting() ->
	case mod_shengxiao_new:dict_get(get_other) of
		undefined -> [];
		L  ->
				Len = length(L),
				case Len < 9 of
						true  -> 
								list_out(L);
						false ->
								%% 随机选取其他已投注的用户
								Rand = util:rand(1, Len),
								L1  = lists:nth(Rand rem Len + 1, L),
								L2  = lists:nth((Rand + 1 ) rem Len + 1, L),
								L3  = lists:nth((Rand + 2 ) rem Len + 1, L),
								L4  = lists:nth((Rand + 3 ) rem Len + 1, L),
								L5  = lists:nth((Rand + 4 ) rem Len + 1, L),
								L6  = lists:nth((Rand + 5 ) rem Len + 1, L),
								L7  = lists:nth((Rand + 6 ) rem Len + 1, L),
								L8  = lists:nth((Rand + 7 ) rem Len + 1, L),
								L9  = lists:nth((Rand + 8 ) rem Len + 1, L),
								[L11] = list_out([L1]),
								[L22] = list_out([L2]),
								[L33] = list_out([L3]),
								[L44] = list_out([L4]),
								[L55] = list_out([L5]),
								[L66] = list_out([L6]),
								[L77] = list_out([L7]),
								[L88] = list_out([L8]),
								[L99] = list_out([L9]),
								[L11, L22, L33, L44, L55, L66, L77, L88, L99]
				end
	end.

%% 处理输出格式
list_out([])      -> [];
list_out([H | T]) ->
	%% 格式 : {id, name, "猪 狗 牛 兔"}
	RoleId = H#shengxiao_member.role_id,
	Name   = H#shengxiao_member.name,
	Op1    = H#shengxiao_member.option1,
	Op2    = H#shengxiao_member.option2,
	Op3    = H#shengxiao_member.option3,
	Op4    = H#shengxiao_member.option4,
	Other = lists:concat([lists:nth(Op1, ?SHENGXIAO_LIST), lists:nth(Op2, ?SHENGXIAO_LIST), lists:nth(Op3, ?SHENGXIAO_LIST), lists:nth(Op4, ?SHENGXIAO_LIST)]),
	L = {RoleId, Name, Other},
	[L | list_out(T)].

%% 开奖倒计时通知(63003) (公共线)
%% 返回时间(秒)
lottery_countdown() ->
	%% 兼容秘籍测试
	case mod_shengxiao_new:gm_test() of
		undefined ->
			Now = util:unixtime(),
			[Hour, Min]  = ?SHENGXIAO_OPTION_TIME,
			LotteryTime = util:unixdate() + Hour * 60 * 60 + Min * 60 + ?SHENGXIAO_LONG + ?END_OPEN,
			case LotteryTime > Now of
				true  -> 
						CountDown = LotteryTime - Now,
						CountDown;
				false -> 0
			end;
		Time -> 
			Now = util:unixtime(),
			LotteryTime = Time,
			case LotteryTime > Now of
				true  -> 
						CountDown = LotteryTime - Now,
						CountDown;
				false -> 0
			end
	end.

%% 活动结束倒计时(63004) (游戏线)
%% 返回时间(秒)
end_countdown() ->
	%% 兼容秘籍测试
	case mod_shengxiao_new:gm_test() of
		undefined ->
			Now = util:unixtime(),
			[Hour, Min]  = ?SHENGXIAO_OPTION_TIME,
			%EndTime = util:unixdate() + Hour * 60 * 60 + Min * 60 + ?SHENGXIAO_LONG + ?SHENGXIAO_END,
			EndTime = util:unixdate() + Hour * 60 * 60 + Min * 60 + ?SHENGXIAO_LONG,
			EndTime - Now;
		Time -> 
			Now = util:unixtime(),
			EndTime = Time - ?END_OPEN,
			EndTime - Now
	end.

%% 倒计时完，获取开奖信息(63005) (公共线)
lottery_info(PlayerId) ->
	%% 抽中的4个生肖及每个生肖选中的人数
	%% 格式：{位置, 抽中的生肖, 选择的人数}
	case mod_shengxiao_new:select(1) of
		undefined -> L1 = {1, 1, 0};
		L1 -> L1
	end,
	case mod_shengxiao_new:select(2) of
		undefined -> L2 = {2, 2, 0};
		L2 -> L2
	end,
	case mod_shengxiao_new:select(3) of
		undefined -> L3 = {3, 3, 0};
		L3 -> L3
	end,
	case mod_shengxiao_new:select(4) of
		undefined -> L4 = {4, 4, 0};
		L4 -> L4
	end,
	
	%% 中奖情况统计
	%% 格式{中奖级别，中奖人数，奖励的元宝，奖励的绑定元宝，奖励的绑定铜钱，奖励的经验}
	case mod_shengxiao_new:tongji(0) of
		undefined -> L5 = {0, 0, 0, 0, 0, 0};
		L5 -> L5
	end,
	case mod_shengxiao_new:tongji(1) of
		undefined -> L6 = {1, 0, 0, 0, 0, 0};
		L6 -> L6
	end,
	case mod_shengxiao_new:tongji(2) of
		undefined -> L7 = {2, 0, 0, 0, 0, 0};
		L7 -> L7
	end,
	case mod_shengxiao_new:tongji(3) of
		undefined -> L8 = {3, 0, 0, 0, 0, 0};
		L8 -> L8
	end,
	case mod_shengxiao_new:tongji(4) of
		undefined -> L9 = {4, 0, 0, 0, 0, 0};
		L9 -> L9
	end,

	%% 用户中奖情况
	%% 格式：Award:中奖级别，IsDrow:是否已领奖
	case mod_shengxiao_new:member(PlayerId) of
		undefined -> 
			Award = 5,
			L10 = [{0, 0}, {0, 0}, {0, 0}, {0, 0}],
			IsDrow = 0;
		Any -> %% Any = #shengxiao_member{}
			Option1 = Any#shengxiao_member.option1,
			Option2 = Any#shengxiao_member.option2,
			Option3 = Any#shengxiao_member.option3,
			Option4 = Any#shengxiao_member.option4,
			Local1  = Any#shengxiao_member.local1,
			Local2  = Any#shengxiao_member.local2,
			Local3  = Any#shengxiao_member.local3,
			Local4  = Any#shengxiao_member.local4,
			Award   = Any#shengxiao_member.award,
			L10     = [{Local1, Option1}, {Local2, Option2}, {Local3, Option3}, {Local4, Option4}],
			IsDrow  = Any#shengxiao_member.is_drow
	end,

	[L1, L2, L3, L4, L5, L6, L7, L8, L9, Award, L10, IsDrow].

%% 获取中奖名单(63006) (公共线)
%% 格式：{用户ID，用户姓名，是否已领奖，中奖级别}
winner() ->
	L = mod_shengxiao_new:dict_get(member),
	get_winner(L, []).

get_winner([], Winner)       -> Winner;
get_winner([H | T], Winner)  ->
	Id      = H#shengxiao_member.role_id,
	Name    = H#shengxiao_member.name,
	Award   = H#shengxiao_member.award,
	IsDrow = H#shengxiao_member.is_drow,
	get_winner(T, [{Id, Name, IsDrow, Award} | Winner]).

%% 返回用户的活动状态(63007) (公共线)
%% 返回值: 1 未投注， 2 已投注未开奖， 3 已开奖， 4 今天不是活动日
user_status(PlayerId) ->
	%% 兼容秘籍测试
	%io:format("mod_shengxiao_new:gm_test():~p~n", [mod_shengxiao_new:gm_test()]),
	case mod_shengxiao_new:gm_test() of
		undefined ->
			case lists:member(calendar:day_of_the_week(date()), ?SHENGXIAO_ACTIVITY_DAY) of
				true ->
					%% 已开奖(判断有一个特等奖，肯定已开奖)
					case mod_shengxiao_new:tongji(0) =:= undefined of
						false  -> 3;
						true ->
							%% 用户未参与活动
							case mod_shengxiao_new:member(PlayerId) of
								undefined -> 1;
								_  -> 2
						end
					end;
				false ->
					4
			end;
		_Time -> 
			case mod_shengxiao_new:tongji(4) =:= undefined of
				%% 已开奖
				false  -> 3;
				true ->
					%% 用户未参与活动
					case mod_shengxiao_new:member(PlayerId) of
						undefined -> 1;
						_  -> 2
					end
			end
	end.

%% 用户点击投注(63010) (公共线)
%% 返回值： (1=成功; 2=失败,不在投注时间内; 3=失败,玩家等级不足; 4=失败,玩家已经投注; 5=失败,玩家铜币不足)
bet(Status, Pos1, Option1, Pos2, Option2, Pos3, Option3, Pos4, Option4) ->
	%% 兼容秘籍测试
	PlayerId = Status#unite_status.id,
    case lib_player:get_player_info(PlayerId, sxbet) of
        false -> {4, Status};
        Any -> {Pid, NickName, Realm, Coin, Sid, Lv} = Any,
            case mod_shengxiao_new:gm_test() of
                undefined ->
                    %% 是否在投注时间内
                    %% 已开奖(判断有一个特等奖，肯定已开奖)
                    case mod_shengxiao_new:tongji(0) =:= undefined of
                        true ->
                            %% 报名等级限制
                            case Lv < ?LV_LIMITED of
                                true -> {3, Status};
                                false ->
                                    %% 用户是否已投注
                                    case mod_shengxiao_new:member(PlayerId) of
                                        undefined -> 
                                            case Coin >= 10000 of
                                                true  ->
                                                    %% 写入进程字典中
                                                    mod_shengxiao_new:put_member(PlayerId, #shengxiao_member{role_id = PlayerId, role_pid = Pid, name = NickName, realm = Realm, bet_time = util:unixtime(), option1 = Option1, option2 = Option2, option3 = Option3, option4 = Option4, local1 = Pos1, local2 = Pos2, local3 = Pos3, local4 = Pos4, award = 4, is_drow = 0, gold = 0, bgold = 0, bcopper = 0, experience = 0}),
                                                    lib_player:update_player_info(PlayerId, [{cost_shengxiao_coin, 10000}]),
                                                    lib_unite:refresh_client(2, Sid),
                                                    {1, Status};
                                                false -> {5, Status}	%% 铜币不足10000
                                            end;
                                        _  -> {4, Status}		%% 玩家已投注
                                    end
                            end;
                        false -> {2, Status}	%% 失败，不在投注时间内
                    end;
                _Time -> 
                    %% 报名等级限制
                    case Lv < ?LV_LIMITED of
                        true -> {3, Status};
                        false ->
                            %% 用户是否已投注
                            case mod_shengxiao_new:member(PlayerId) of
                                undefined -> 
                                    case Coin >= 10000 of
                                        true  ->
                                            %% 写入进程字典中
                                            mod_shengxiao_new:put_member(PlayerId, #shengxiao_member{role_id = PlayerId, role_pid = Pid, name = NickName, realm = Realm, bet_time = util:unixtime(), option1 = Option1, option2 = Option2, option3 = Option3, option4 = Option4, local1 = Pos1, local2 = Pos2, local3 = Pos3, local4 = Pos4, award = 4, is_drow = 0, gold = 0, bgold = 0, bcopper = 0, experience = 0}),
                                            lib_player:update_player_info(PlayerId, [{cost_shengxiao_coin, 10000}]),
                                            lib_unite:refresh_client(2, Sid),
                                            {1, Status};
                                        false -> {5, Status}	%% 铜币不足10000
                                    end;
                                _  -> {4, Status}		%% 玩家已投注
                            end
                    end
            end
    end.

%% 用户点击投注(测试用)
bet_gm(PlayerId, Name, Realm, Pos1, Option1, Pos2, Option2, Pos3, Option3, Pos4, Option4) ->
	case mod_shengxiao_new:member(PlayerId) of
		undefined -> 
			mod_shengxiao_new:put_member(PlayerId, #shengxiao_member{role_id = PlayerId, name = Name, realm = Realm, bet_time = util:unixtime(), option1 = Option1, option2 = Option2, option3 = Option3, option4 = Option4, local1 = Pos1, local2 = Pos2, local3 = Pos3, local4 = Pos4, award = -1, is_drow = 0, gold = 0, bgold = 0, bcopper = 0, experience = 0}),
			1;
		_  -> 0		%% 玩家已投注
	end.

%% 用户领奖(63011) (公共线)
%% 返回值: 1 领奖成功，0 领奖失败， 2 已领取
award(Status) ->
    PlayerId = Status#unite_status.id,
    case lib_player:get_player_info(PlayerId, sxaward) of
        false -> {0, "error1", Status};
        Any -> Sid = Any,
            case mod_shengxiao_new:member(PlayerId) of
                undefined -> {0, "error1", Status};
                L  -> 
                    case L#shengxiao_member.is_drow of
                        1 -> {2, "error2", Status};	%% 已领取过
                        0 -> 
                            %% 改变领取状态
                            L1 = L#shengxiao_member{is_drow = 1},
                            mod_shengxiao_new:put_member(PlayerId, L1),
                            %% 修改内存
                            Gold = L#shengxiao_member.gold,
                            Bgold = L#shengxiao_member.bgold,
                            Bcopper = L#shengxiao_member.bcopper,
                            %case Gold > 0 of
                            %	true -> S1 = lists:concat([" 元宝:+", integer_to_list(Gold)]);
                            %	false -> S1 = ""
                            %end,
                            %case Bgold > 0 of
                            %	true -> S2 = lists:concat([S1, " 绑定元宝:+", integer_to_list(Bgold)]);
                            %	false -> S2 = S1
                            %end,
                            %case Bcopper > 0 of
                            %	true -> S3 = lists:concat([S2, " 绑定铜币:+", integer_to_list(Bcopper)]);
                            %	false -> S3 = S2
                            %end,
                            case L#shengxiao_member.award of
                                0 -> S3 = data_shengxiao_text:get_award_text(0);
                                1 -> S3 = data_shengxiao_text:get_award_text(1);
                                2 -> S3 = data_shengxiao_text:get_award_text(2);
                                3 -> S3 = data_shengxiao_text:get_award_text(3);
                                _ -> S3 = data_shengxiao_text:get_award_text(4)
                            end,
                            lib_player:update_player_info(PlayerId, [{add_shengxiao_gold, Gold}, {add_shengxiao_bgold, Bgold}, {add_shengxiao_bcoin, Bcopper}]),
                            lib_unite:refresh_client(2, Sid),
                            {1, S3, Status}
                    end
            end
    end.

%% 统计每个生肖有多少用户选择,返回[{Num1, Option1}...{Num12, Option12}]
count([], List) -> List;
count([H | T], List) ->
	Option1 = H#shengxiao_member.option1,
	Option2 = H#shengxiao_member.option2,
	Option3 = H#shengxiao_member.option3,
	Option4 = H#shengxiao_member.option4,
	L1 = count_add(Option1, List),
	L2 = count_add(Option2, L1),
	L3 = count_add(Option3, L2),
	L4 = count_add(Option4, L3),
	count(T, L4).

count_add(Option, [{S1, N1}, {S2, N2}, {S3, N3}, {S4, N4}, {S5, N5}, {S6, N6}, {S7, N7}, {S8, N8}, {S9, N9}, {S10, N10}, {S11, N11}, {S12, N12}]) ->
	case Option of
			1  -> [{S1 + 1, N1}, {S2, N2}, {S3, N3}, {S4, N4}, {S5, N5}, {S6, N6}, {S7, N7}, {S8, N8}, {S9, N9}, {S10, N10}, {S11, N11}, {S12, N12}];
			2  -> [{S1, N1}, {S2 + 1, N2}, {S3, N3}, {S4, N4}, {S5, N5}, {S6, N6}, {S7, N7}, {S8, N8}, {S9, N9}, {S10, N10}, {S11, N11}, {S12, N12}];
			3  -> [{S1, N1}, {S2, N2}, {S3 + 1, N3}, {S4, N4}, {S5, N5}, {S6, N6}, {S7, N7}, {S8, N8}, {S9, N9}, {S10, N10}, {S11, N11}, {S12, N12}];
			4  -> [{S1, N1}, {S2, N2}, {S3, N3}, {S4 + 1, N4}, {S5, N5}, {S6, N6}, {S7, N7}, {S8, N8}, {S9, N9}, {S10, N10}, {S11, N11}, {S12, N12}];
			5  -> [{S1, N1}, {S2, N2}, {S3, N3}, {S4, N4}, {S5 + 1, N5}, {S6, N6}, {S7, N7}, {S8, N8}, {S9, N9}, {S10, N10}, {S11, N11}, {S12, N12}];
			6  -> [{S1, N1}, {S2, N2}, {S3, N3}, {S4, N4}, {S5, N5}, {S6 + 1, N6}, {S7, N7}, {S8, N8}, {S9, N9}, {S10, N10}, {S11, N11}, {S12, N12}];
			7  -> [{S1, N1}, {S2, N2}, {S3, N3}, {S4, N4}, {S5, N5}, {S6, N6}, {S7 + 1, N7}, {S8, N8}, {S9, N9}, {S10, N10}, {S11, N11}, {S12, N12}];
			8  -> [{S1, N1}, {S2, N2}, {S3, N3}, {S4, N4}, {S5, N5}, {S6, N6}, {S7, N7}, {S8 + 1, N8}, {S9, N9}, {S10, N10}, {S11, N11}, {S12, N12}];
			9  -> [{S1, N1}, {S2, N2}, {S3, N3}, {S4, N4}, {S5, N5}, {S6, N6}, {S7, N7}, {S8, N8}, {S9 + 1, N9}, {S10, N10}, {S11, N11}, {S12, N12}];
			10 -> [{S1, N1}, {S2, N2}, {S3, N3}, {S4, N4}, {S5, N5}, {S6, N6}, {S7, N7}, {S8, N8}, {S9, N9}, {S10 + 1, N10}, {S11, N11}, {S12, N12}];
			11 -> [{S1, N1}, {S2, N2}, {S3, N3}, {S4, N4}, {S5, N5}, {S6, N6}, {S7, N7}, {S8, N8}, {S9, N9}, {S10, N10}, {S11 + 1, N11}, {S12, N12}];
			12 -> [{S1, N1}, {S2, N2}, {S3, N3}, {S4, N4}, {S5, N5}, {S6, N6}, {S7, N7}, {S8, N8}, {S9, N9}, {S10, N10}, {S11, N11}, {S12 + 1, N12}];
			_  -> [{S1, N1}, {S2, N2}, {S3, N3}, {S4, N4}, {S5, N5}, {S6, N6}, {S7, N7}, {S8, N8}, {S9, N9}, {S10, N10}, {S11, N11}, {S12, N12}]
	end.

%% 得到获奖的4个生肖
%% 做法：
%% 1.先统计每个生肖选择的人数，然后去除0人选择的生肖，再对剩余的进行递增排序，选择最少人选的4个。
%% 2.然后判断是否有用户选择了这4个生肖，如果有，则该4个生肖为抽中生肖。如果没有，进入下一步。
%% 3.选择最少人选的3个生肖，判断是否有用户选择了这3个生肖，如果有并有多人，随机选择一名用户，该用户所选的4个生肖则是抽中生肖，否则重复3，选择最少人选的2个生肖。
%% 4.如果无人参与活动，则系统返回最后4个生肖作为中奖结果。
get_award_num(L, Num) ->
	case L of
			[L1, L2, L3, L4] ->
					{A, _} = lists:keyfind(L1, 2, Num),
					{B, _} = lists:keyfind(L2, 2, Num),
					{C, _} = lists:keyfind(L3, 2, Num),
					{D, _} = lists:keyfind(L4, 2, Num),
					case A > 0 andalso B > 0 andalso C > 0 andalso D > 0 of
							true  -> 
									FL = find_award_user([L1, L2, L3, L4]),
									case FL of
											false -> [];
											true -> [{L1, A}, {L2, B}, {L3, C}, {L4, D}]
									end;
							false -> []
					end;
			[L1, L2, L3] ->
					{A, _} = lists:keyfind(L1, 2, Num),
					{B, _} = lists:keyfind(L2, 2, Num),
					{C, _} = lists:keyfind(L3, 2, Num),
					case A > 0 andalso B > 0 andalso C > 0 of
							true  -> 
									FL = find_award_user([L1, L2, L3]),
									case FL of
											false -> [];
											L4 ->
													{D, _} = lists:keyfind(L4, 2, Num),
													[{L1, A}, {L2, B}, {L3, C}, {L4, D}]
									end;
							false -> []
					end;
			[L1, L2] ->
					{A, _} = lists:keyfind(L1, 2, Num),
					{B, _} = lists:keyfind(L2, 2, Num),
					case A > 0 andalso B > 0 of
							true  -> 
									FL = find_award_user([L1, L2]),
									case FL of
											[L3, L4] ->
													{C, _} = lists:keyfind(L3, 2, Num),
													{D, _} = lists:keyfind(L4, 2, Num),
													[{L1, A}, {L2, B}, {L3, C}, {L4, D}];
											false -> []
									end;
							false -> []
					end;
			L1 ->
					{A, _} = lists:keyfind(L1, 2, Num),
					case A > 0 of
							true  -> 
									FL = find_award_user(L1),
									case FL of
											[L2, L3, L4] ->
													{B, _} = lists:keyfind(L2, 2, Num),
													{C, _} = lists:keyfind(L3, 2, Num),
													{D, _} = lists:keyfind(L4, 2, Num),
													[{L1, A}, {L2, B}, {L3, C}, {L4, D}];
											false -> 
													{Nu1, _} = lists:keyfind(1, 2, Num),
													{Nu2, _} = lists:keyfind(2, 2, Num),
													{Nu3, _} = lists:keyfind(3, 2, Num),
													{Nu4, _} = lists:keyfind(4, 2, Num),
													[{1, Nu1}, {2, Nu2}, {3, Nu3}, {4, Nu4}]
									end;
							false -> 
									{Nu1, _} = lists:keyfind(1, 2, Num),
									{Nu2, _} = lists:keyfind(2, 2, Num),
									{Nu3, _} = lists:keyfind(3, 2, Num),
									{Nu4, _} = lists:keyfind(4, 2, Num),
									[{1, Nu1}, {2, Nu2}, {3, Nu3}, {4, Nu4}]
					end
	end.

find_award_user(L) ->
	Users = mod_shengxiao_new:dict_get(member),
	case L of
			[L1, L2, L3, L4] -> 
					do_match([L1, L2, L3, L4], Users);
			[L1, L2, L3] -> 
					do_match([L1, L2, L3], Users);
			[L1, L2] ->
					do_match([L1, L2], Users);
			L1 ->
					do_match(L1, Users)
	end.

do_match(_L, [])     -> false;
do_match(L, [H | T]) ->
	Option1 = H#shengxiao_member.option1,
	Option2 = H#shengxiao_member.option2,
	Option3 = H#shengxiao_member.option3,
	Option4 = H#shengxiao_member.option4,
	Op = [Option1, Option2, Option3, Option4],
	case L of
			[L1, L2, L3, L4] ->
					case lists:member(L1, Op) =:= true andalso lists:member(L2, Op) =:= true andalso lists:member(L3, Op) =:= true andalso lists:member(L4, Op) =:= true of
							true  ->
									true;
							false -> do_match(L, T)
					end;
			[L1, L2, L3] -> 
					case lists:member(L1, Op) =:= true andalso lists:member(L2, Op) =:= true andalso lists:member(L3, Op) =:= true of
							true  ->
									[L4] = lists:delete(L3, lists:delete(L2, lists:delete(L1, Op))),
									L4;
							false -> do_match(L, T)
					end;
			[L1, L2] ->
					case lists:member(L1, Op) =:= true andalso lists:member(L2, Op) =:= true of
							true  ->
									[L3, L4] = lists:delete(L2, lists:delete(L1, Op)),
									[L3, L4];
							false -> do_match(L, T)
					end;
			L1 ->
					case lists:member(L1, Op) of
							true  ->
									[L2, L3, L4] = lists:delete(L1, Op),
									[L2, L3, L4];
							false -> do_match(L, T)
					end
	end.

%% 中奖情况统计 : 特等奖人数、奖金等
%% 把每个等级的中奖情况写入ETS_SHENGXIAO_TONGJI
award_tongji([A, B, C, D, L]) ->
	mod_shengxiao_new:put_tongji(0, {0, 0, 0, 0, 0, 0}),
	mod_shengxiao_new:put_tongji(1, {1, 0, 0, 0, 0, 0}),
	mod_shengxiao_new:put_tongji(2, {2, 0, 0, ?ER_BGOLD, ?ER_BCOPPER, ?ER_EXP}),
	mod_shengxiao_new:put_tongji(3, {3, 0, 0, ?SAN_BGOLD, ?SAN_BCOPPER, ?SAN_EXP}),
	mod_shengxiao_new:put_tongji(4, {4, 0, 0, 0, 0, ?CANYU_EXP}),
	tongji([A, B, C, D], L),
	dict_update(),
	ok.

tongji(_, []) -> ok;
tongji([A, B, C, D], [H | T]) ->
	Op1 = H#shengxiao_member.option1,
	Op2 = H#shengxiao_member.option2,
	Op3 = H#shengxiao_member.option3,
	Op4 = H#shengxiao_member.option4,
	Op = [Op1, Op2, Op3, Op4],
    N = right_num([A, B, C, D], Op, 0),
    spawn(fun() ->
                db:execute(io_lib:format(<<"insert into log_shengxiao_player set player_id =~p, select1 = ~p, select2 = ~p, select3 = ~p, select4 = ~p, award = ~p, time = ~p, log_id = (select max(id) from log_shengxiao_info)">>, [H#shengxiao_member.role_id, H#shengxiao_member.option1, H#shengxiao_member.option2, H#shengxiao_member.option3, H#shengxiao_member.option4, N, H#shengxiao_member.bet_time]))
        end),
	case N of
			0 ->
					%% 用户获得参与奖
					H1 = H#shengxiao_member{award = 4},
					mod_shengxiao_new:put_member(H#shengxiao_member.role_id, H1),
					%% 统计参与奖人数
					{Aw, Nu, G, Bg, Bc, Ex} = mod_shengxiao_new:tongji(4),
					mod_shengxiao_new:put_tongji(Aw, {Aw, Nu + 1, G, Bg, Bc, Ex});
			1 ->
					%% 用户获得三等奖
					H1 = H#shengxiao_member{award = 3},
					mod_shengxiao_new:put_member(H#shengxiao_member.role_id, H1),
					%% 统计参与奖人数
					{Aw, Nu, G, Bg, Bc, Ex} = mod_shengxiao_new:tongji(3),
					mod_shengxiao_new:put_tongji(Aw, {Aw, Nu + 1, G, Bg, Bc, Ex});
			2 ->
					%% 用户获得二等奖
					H1 = H#shengxiao_member{award = 2},
					mod_shengxiao_new:put_member(H#shengxiao_member.role_id, H1),
					%% 统计参与奖人数
					{Aw, Nu, G, Bg, Bc, Ex} = mod_shengxiao_new:tongji(2),
					mod_shengxiao_new:put_tongji(Aw, {Aw, Nu + 1, G, Bg, Bc, Ex});
			3 ->
					%% 用户获得一等奖
					H1 = H#shengxiao_member{award = 1},
					mod_shengxiao_new:put_member(H#shengxiao_member.role_id, H1),
					%% 统计参与奖人数
					{Aw, Nu, G, Bg, Bc, Ex} = mod_shengxiao_new:tongji(1),
					mod_shengxiao_new:put_tongji(Aw, {Aw, Nu + 1, G, Bg, Bc, Ex});
			4 ->
					%% 用户获得特等奖
					H1 = H#shengxiao_member{award = 0},
					mod_shengxiao_new:put_member(H#shengxiao_member.role_id, H1),
					%% 统计参与奖人数
					{Aw, Nu, G, Bg, Bc, Ex} = mod_shengxiao_new:tongji(0),
					mod_shengxiao_new:put_tongji(Aw, {Aw, Nu + 1, G, Bg, Bc, Ex}),
                    spawn(fun() ->
                                db:execute(io_lib:format(<<"insert into log_shengxiao set player_id = ~p, time = ~p">>, [H#shengxiao_member.role_id, util:unixtime()]))
                        end);
			_ ->	skip
	end,
	tongji([A, B, C, D], T).

right_num([], _Op, N) -> N;
right_num([H | T], Op, N) ->
	case lists:member(H, Op) of
			true  -> right_num(T, Op, N + 1);
			false -> right_num(T, Op, N)
	end.

dict_update() ->
	{_A4, N4, _G4, _Bg4, _Bc4, _Ex4} = mod_shengxiao_new:tongji(4),
	{_A3, N3, _G3, _Bg3, _Bc3, _Ex3} = mod_shengxiao_new:tongji(3),
	{_A2, N2, _G2, _Bg2, _Bc2, _Ex2} = mod_shengxiao_new:tongji(2),
	{_A1, N1, _G1, _Bg1, _Bc1, _Ex1} = mod_shengxiao_new:tongji(1),
	{_A0, N0, _G0, _Bg0, _Bc0, _Ex0} = mod_shengxiao_new:tongji(0),
	%% 更新ETS_SHENGXIAO_TONGJI表
	mod_shengxiao_new:put_tongji(4, {4, N4, 0, 0, ?CANYU_BCOPPER, ?CANYU_EXP}),
	mod_shengxiao_new:put_tongji(3, {3, N3, 0, ?SAN_BGOLD, ?SAN_BCOPPER, ?SAN_EXP}),
	mod_shengxiao_new:put_tongji(2, {2, N2, 0, ?ER_BGOLD, ?ER_BCOPPER, ?ER_EXP}),
	case N1 > 0 of
		true ->
			mod_shengxiao_new:put_tongji(1, {1, N1, 0, round(?SHENGXIAO_BGOLD * ?YI_PERCENT / N1), round(?SHENGXIAO_BCOPPER * ?YI_PERCENT / N1), round(?SHENGXIAO_EXP * ?YI_PERCENT / N1)});
		false -> skip
	end,
	case N0 > 0 of
		true ->
			mod_shengxiao_new:put_tongji(0, {0, N0, round(?SHENGXIAO_GOLD / N0), round(?SHENGXIAO_BGOLD * ?TENG_PERCENT / N0), round(?SHENGXIAO_BCOPPER * ?TENG_PERCENT / N0), round(?SHENGXIAO_EXP * ?TENG_PERCENT / N0)});
		false -> skip
	end,
	%% 更新ETS_SHENGXIAO_MEMBER表
	L = mod_shengxiao_new:dict_get(member),
	ets_update_member(L, N4, N3, N2, N1, N0),
	ok.

ets_update_member([], _N4, _N3, _N2, _N1, _N0) -> ok;
ets_update_member([H | T], N4, N3, N2, N1, N0) ->
	Award = H#shengxiao_member.award,
	case Award of
			4 ->
					%% 参与奖奖励
					H4 = H#shengxiao_member{gold = 0, bgold = 0, bcopper = ?CANYU_BCOPPER, experience = ?CANYU_EXP},
					mod_shengxiao_new:put_member(H#shengxiao_member.role_id, H4);
			3 ->
					%% 三等奖奖励
					H3 = H#shengxiao_member{gold = 0, bgold = ?SAN_BGOLD, bcopper = ?SAN_BCOPPER, experience = ?SAN_EXP},
					mod_shengxiao_new:put_member(H#shengxiao_member.role_id, H3);
			2 ->
					%% 二等奖奖励
					H2 = H#shengxiao_member{gold = 0, bgold = ?ER_BGOLD, bcopper = ?ER_BCOPPER, experience = ?ER_EXP},
					mod_shengxiao_new:put_member(H#shengxiao_member.role_id, H2);
			1 ->
					%% 一等奖奖励
					H1 = H#shengxiao_member{gold = 0, bgold = round(?SHENGXIAO_BGOLD * ?YI_PERCENT / N1), bcopper = round(?SHENGXIAO_BCOPPER * ?YI_PERCENT / N1), experience = round(?SHENGXIAO_EXP * ?YI_PERCENT / N1)},
					mod_shengxiao_new:put_member(H#shengxiao_member.role_id, H1);
			0 ->
					%% 特等奖奖励
					H0 = H#shengxiao_member{gold = round(?SHENGXIAO_GOLD / N0), bgold = round(?SHENGXIAO_BGOLD * ?TENG_PERCENT / N0), bcopper = round(?SHENGXIAO_BCOPPER * ?TENG_PERCENT / N0), experience = round(?SHENGXIAO_EXP * ?TENG_PERCENT / N0)},
					mod_shengxiao_new:put_member(H#shengxiao_member.role_id, H0);
			_ -> skip
	end,
	ets_update_member(T, N4, N3, N2, N1, N0).

%% 给未领奖的用户发送提示
send_award_tips(BinData) ->
	AwardTipsPSId = award_tips_ps_id(),
	send_tips(AwardTipsPSId, BinData).

send_tips([], _BinData) -> skip;
send_tips([H | T], BinData) -> 
	lib_unite_send:send_to_one(H, BinData),
	send_tips(T, BinData).

%% 获取未领奖用户ID
award_tips_ps_id() ->
	L = mod_shengxiao_new:dict_get(member),
	award_tips_ps_id2(L, []).

award_tips_ps_id2([], L2) -> L2;
award_tips_ps_id2([H | T], L2) -> 
	IsDrow = H#shengxiao_member.is_drow,
	case IsDrow =:= 0 of
		false -> award_tips_ps_id2(T, L2);
		true  -> award_tips_ps_id2(T, [H#shengxiao_member.role_id | L2])
	end.

%% 给未领奖的用户发送邮件
send_all_award() ->
	L = mod_shengxiao_new:dict_get(member),
	send_award(L, 0).

%% 邮件限制发送时间，不让一直发
send_award([], _N) -> ok;
send_award([H | T], N) ->
	IsDrow = H#shengxiao_member.is_drow,
	case IsDrow =:= 0 of
		false -> skip;
		true  -> 
			H1 = H#shengxiao_member{is_drow = 1},
			mod_shengxiao_new:put_member(H#shengxiao_member.role_id, H1),
			RoleId = H#shengxiao_member.role_id,
			Gold = H#shengxiao_member.gold,
			Bgold = H#shengxiao_member.bgold,
			Bcopper = H#shengxiao_member.bcopper,
			%% 进入休眠
			case N rem 10 of
				0 -> util:sleep(100);
				_ -> skip
			end,
			case H#shengxiao_member.award of
				0 -> 
                    S1 = data_shengxiao_text:get_email_text(1),
                    S2 = data_shengxiao_text:get_email_text(2),
                    S3 = data_shengxiao_text:get_email_text(3),
                    S0 = data_shengxiao_text:get_email_text(0),
                    S = lists:concat([S1, Gold, S2, Bgold, S3, Bcopper]),
                    lib_mail:send_sys_mail_bg([RoleId], S0, S, 0, 0, 0, 0, 0, Bcopper, 0, Bgold, Gold);
				1 -> 
                    S1 = data_shengxiao_text:get_email_text(4),
                    S2 = data_shengxiao_text:get_email_text(3),
                    S0 = data_shengxiao_text:get_email_text(0),
                    S = lists:concat([S1, Bgold, S2, Bcopper]),
                    lib_mail:send_sys_mail_bg([RoleId], S0, S, 0, 0, 0, 0, 0, Bcopper, 0, Bgold, Gold);
				2 -> 
                    S1 = data_shengxiao_text:get_email_text(5),
                    S2 = data_shengxiao_text:get_email_text(3),
                    S0 = data_shengxiao_text:get_email_text(0),
                    S = lists:concat([S1, Bgold, S2, Bcopper]),
                    lib_mail:send_sys_mail_bg([RoleId], S0, S, 0, 0, 0, 0, 0, Bcopper, 0, Bgold, Gold);
				3 -> 
                    S1 = data_shengxiao_text:get_email_text(6),
                    S0 = data_shengxiao_text:get_email_text(0),
                    S = lists:concat([S1, Bcopper]),
                    lib_mail:send_sys_mail_bg([RoleId], S0, S, 0, 0, 0, 0, 0, Bcopper, 0, Bgold, Gold);
				_ -> 
                    S1 = data_shengxiao_text:get_email_text(7),
                    S0 = data_shengxiao_text:get_email_text(0),
                    S = lists:concat([S1, Bcopper]),
                    lib_mail:send_sys_mail_bg([RoleId], S0, S, 0, 0, 0, 0, 0, Bcopper, 0, Bgold, Gold)
			end
	end,
	send_award(T, N + 1).

%% 清除旧数据(上次抽奖信息)
clear_ets() ->
	mod_shengxiao_new:clear_data().

%% GM秘籍
ets_gm_endtime(Endtime) ->
	mod_shengxiao_new:put_gm(Endtime).

start_lottery() ->
	%% 先统计每个生肖选的人数，然后选择四个生肖作为抽中结果
	L = mod_shengxiao_new:dict_get(member),
	Num = count(L, [{0, 1}, {0, 2}, {0, 3}, {0, 4}, {0, 5}, {0, 6}, {0, 7}, {0, 8}, {0, 9}, {0, 10}, {0, 11}, {0, 12}]),	%% {A, B}   A:选择人数,B:生肖
	%% 选最少用户选择的四个生肖
	%% 先去除选择数为0的
	%% 例如: 只有一个用户投注，则4个生肖选择人数为1，其他生肖选择人数为0，去除选择人数为0的生肖
	Num11 = lists:keydelete(0, 1, Num),
	Num22 = lists:keydelete(0, 1, Num11),
	Num33 = lists:keydelete(0, 1, Num22),
	Num44 = lists:keydelete(0, 1, Num33),
	Num55 = lists:keydelete(0, 1, Num44),
	Num66 = lists:keydelete(0, 1, Num55),
	Num77 = lists:keydelete(0, 1, Num66),
	Num88 = lists:keydelete(0, 1, Num77),
	SNum = lists:sort(Num88),
	{_, S1} = lists:nth(1, SNum),
	{_, S2} = lists:nth(2, SNum),
	{_, S3} = lists:nth(3, SNum),
	{_, S4} = lists:nth(4, SNum),
	%% 有人选中最少的四个生肖
	case get_award_num([S1, S2, S3, S4], Num) of
		[] -> 
			case get_award_num([S1, S2, S3], Num) of
				[] ->
					case get_award_num([S1, S2], Num) of
						[] -> 
							[{A, Num1}, {B, Num2}, {C, Num3}, {D, Num4}] = get_award_num(S1, Num);
						[{A, Num1}, {B, Num2}, {C, Num3}, {D, Num4}] -> ok
					end;
				[{A, Num1}, {B, Num2}, {C, Num3}, {D, Num4}] -> ok
			end;
		[{A, Num1}, {B, Num2}, {C, Num3}, {D, Num4}] -> ok
	end,
    spawn(fun() ->
                case db:get_row(<<"select max(id) from log_shengxiao_info">>) of
                    [MaxId] ->
                        db:execute(io_lib:format(<<"update log_shengxiao_info set award1 = ~p, num1 = ~p, award2 = ~p, num2 = ~p, award3 = ~p, num3 = ~p, award4 = ~p, num4 = ~p where id = ~p">>, [A, Num1, B, Num2, C, Num3, D, Num4, MaxId]));
                    _ ->
                        skip
                end
        end),
    Result = case db:get_all(<<"select player_id from log_shengxiao where time = (select max(time) from log_shengxiao limit 1)">>) of
        [] ->
            PlayerIds = [],
            skip;
        _PlayerIds when is_list(_PlayerIds) ->
            PlayerIds = db_ids_deal(_PlayerIds, []),
            ok;
        _ ->
            PlayerIds = [],
            skip
    end,
    case Result of
        skip ->
            mod_shengxiao_new:put_select(1, {1, A, Num1}),
            mod_shengxiao_new:put_select(2, {2, B, Num2}),
            mod_shengxiao_new:put_select(3, {3, C, Num3}),
            mod_shengxiao_new:put_select(4, {4, D, Num4}),
            %% 中奖情况统计 : 特等奖人数、奖金等
            award_tongji([A, B, C, D, L]);
        _ ->
            TeIds = get_te_award_ids([A, B, C, D], L, []),
            case last_te(PlayerIds, TeIds) of
                %% 有玩家前一次中过特等奖，则随机一个中奖
                true ->
                    RandNum = util:rand(1, length(L)),
                    Win = lists:nth(RandNum, L),
                    BInfo1 = select_info(1, Win#shengxiao_member.option1, L, 0),
                    BInfo2 = select_info(2, Win#shengxiao_member.option2, L, 0),
                    BInfo3 = select_info(3, Win#shengxiao_member.option3, L, 0),
                    BInfo4 = select_info(4, Win#shengxiao_member.option4, L, 0),
                    mod_shengxiao_new:put_select(1, BInfo1),
                    mod_shengxiao_new:put_select(2, BInfo2),
                    mod_shengxiao_new:put_select(3, BInfo3),
                    mod_shengxiao_new:put_select(4, BInfo4),
                    %% 中奖情况统计 : 特等奖人数、奖金等
                    award_tongji([Win#shengxiao_member.option1, Win#shengxiao_member.option2, Win#shengxiao_member.option3, Win#shengxiao_member.option4, L]);
                false ->
                    mod_shengxiao_new:put_select(1, {1, A, Num1}),
                    mod_shengxiao_new:put_select(2, {2, B, Num2}),
                    mod_shengxiao_new:put_select(3, {3, C, Num3}),
                    mod_shengxiao_new:put_select(4, {4, D, Num4}),
                    %% 中奖情况统计 : 特等奖人数、奖金等
                    award_tongji([A, B, C, D, L])
            end
    end.

%% 发送特等奖和一等奖中奖传闻
send_all_te_cw() ->
	L = mod_shengxiao_new:dict_get(member),
	send_te_cw(L),
	send_one_cw(L).

%% 发送特等奖中奖传闻
send_te_cw([])       -> ok;
send_te_cw([H | T])  ->
	case H#shengxiao_member.award of
		0 ->
			Id      = H#shengxiao_member.role_id,
			%% 获得特等奖传闻
			%% 先判断用户是否在线
			case lib_player:is_online_unite(Id) of
				true ->
                    case lib_player:get_player_info(Id, sendTv_Message) of
                        [PSId, PSRealm, PSNickname, PSSex, PSCareer, PSImage] ->
                            lib_chat:send_TV({all},1,2, ["shengxiao", 0, PSId, PSRealm, PSNickname, PSSex, PSCareer, PSImage]);
                        _ -> skip
                    end;
				false -> 
                    case lib_player:get_player_low_data(Id) of
                        [NickName, Sex, _Lv, Career, Realm, _GuildId, _Mount_limit, _HusongNpc, _Image|_] -> 
                            lib_chat:send_TV({all},1,2, ["shengxiao", 0, Id, Realm, binary_to_list(NickName), Sex, Career, 0]);
                        _ -> skip
                    end
			end;
		_ -> 
			skip
	end,
	send_te_cw(T).

%% 发送一等奖中奖传闻
send_one_cw([])       -> ok;
send_one_cw([H | T])  ->
	case H#shengxiao_member.award of
		1 ->
			Id      = H#shengxiao_member.role_id,
			%% 获得一等奖传闻
			%% 先判断用户是否在线
            case lib_player:is_online_unite(Id) of
                true ->
                    case lib_player:get_player_info(Id, sendTv_Message) of
                        [PSId, PSRealm, PSNickname, PSSex, PSCareer, PSImage] ->
                            lib_chat:send_TV({all},1,2, ["shengxiao", 1, PSId, PSRealm, PSNickname, PSSex, PSCareer, PSImage]);
                        _ -> skip
                    end;
                false -> 
                    case lib_player:get_player_low_data(Id) of
                        [NickName, Sex, _Lv, Career, Realm, _GuildId, _Mount_limit, _HusongNpc, _Image| _] -> 
                            lib_chat:send_TV({all},1,2, ["shengxiao", 1, Id, Realm, binary_to_list(NickName), Sex, Career, 0]);
                        _ -> skip
                    end
            end;
		_ -> 
			skip
	end,
	send_one_cw(T).

%% 把[{A, B}]转化为[B], 其中A = {Kind, Any}, Kind = member | tongji | select
list_deal([], _Kind)        -> [];
list_deal([H | T], Kind) ->
	case H of
		{{_Kind, _Any}, B} ->
			case _Kind =:= Kind of
				true -> [B | list_deal(T, Kind)];
				false -> list_deal(T, Kind)
			end;
		_ -> list_deal(T, Kind)
	end.

%% [[Id1], [Id2], [Id3]] -> [Id1, Id2, Id3]
db_ids_deal([], List) -> List;
db_ids_deal([[H] | T], List) ->
    db_ids_deal(T, [H | List]).

%% 找出特等奖玩家ID
get_te_award_ids(_, [], List) -> List;
get_te_award_ids([A, B, C, D], [H | T], List) ->
    Op1 = H#shengxiao_member.option1,
    Op2 = H#shengxiao_member.option2,
    Op3 = H#shengxiao_member.option3,
    Op4 = H#shengxiao_member.option4,
    Op = [Op1, Op2, Op3, Op4],
    N = right_num([A, B, C, D], Op, 0),
    case N of
        4 ->
            get_te_award_ids([A, B, C, D], T, [H#shengxiao_member.role_id | List]);
        _ ->
            get_te_award_ids([A, B, C, D], T, List)
    end.

last_te([], _TeIds) -> false;
last_te([H1 | T1], TeIds) ->
    case lists:member(H1, TeIds) of
        true -> true;
        false -> last_te(T1, TeIds)
    end.

select_info(Pos, Op, [], Num) -> {Pos, Op, Num};
select_info(Pos, Op, [H | T], Num) ->
    case lists:member(Op, [H#shengxiao_member.option1, H#shengxiao_member.option2, H#shengxiao_member.option3, H#shengxiao_member.option4]) of
        true -> select_info(Pos, Op, T, Num + 1);
        false -> select_info(Pos, Op, T, Num)
    end.
