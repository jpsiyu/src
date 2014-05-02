%%------------------------------------------------------------------------------
%% @Module  : mod_quiz_cast
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.31
%% @Description: 答题服务器handle_cast处理
%%------------------------------------------------------------------------------

-module(mod_quiz_cast).
-include("common.hrl").
-include("quiz.hrl").
-export([handle_cast/2]).


% 加载题库
handle_cast(load_quiz_base, Status) ->
    lib_quiz:load_quiz_base(),
    {noreply, Status};

% 发题
handle_cast({send_quiz, SubjectType}, Status) ->
    {Correct, Count} = lib_quiz:send_quiz(Status#quiz_state.now_turn + 1, 
								 ?QUIZ_TOTAL_SUBJECT, 
								 Status#quiz_state.type, 
								 SubjectType),
    NewState = Status#quiz_state{
         state = 2,
         answer_time = 0,
         righ_option = Correct,
		 count = Count,
         now_turn = Status#quiz_state.now_turn  + 1,
         option1_num = 0,
         option2_num = 0,
         option3_num = 0,
         option4_num = 0
    },
    {noreply, NewState};
    
% 答题
handle_cast({answer, Data}, Status) ->
    Option = lib_quiz:answer_quiz(Data, Status#quiz_state.answer_time),
    NewState = case Option of
        1 ->
            Status#quiz_state{option1_num = Status#quiz_state.option1_num + 1};
        2 ->
            Status#quiz_state{option2_num = Status#quiz_state.option2_num + 1};
        3 ->
            Status#quiz_state{option3_num = Status#quiz_state.option3_num + 1};
        _ ->
            Status#quiz_state{option4_num = Status#quiz_state.option4_num + 1}
    end,
    {noreply, NewState};
    
% 答题倒计时
handle_cast({answer_tick, Time}, Status) ->
    NewState = Status#quiz_state{answer_time = Time},
    {noreply, NewState};

% 判题
handle_cast(judge, Status) ->
	%1.获取回答人数最多的答题选项.
    MaxSel = mod_quiz:get_max_sel([Status#quiz_state.option1_num, 
									   Status#quiz_state.option2_num, 
									   Status#quiz_state.option3_num,
									   Status#quiz_state.option4_num]),
    %2.判题.
	lib_quiz:judge_quiz(Status#quiz_state.righ_option, MaxSel),
	Total = Status#quiz_state.option1_num + Status#quiz_state.option2_num + 
			Status#quiz_state.option3_num + Status#quiz_state.option4_num,
	
	%3.发送判题结果.
	OptionNum = 
		if 
			Total == 0 ->
				[0, 0, 0, 0];
			true ->				
			    [Status#quiz_state.option1_num * 100 div Total,
				 Status#quiz_state.option2_num * 100 div Total,
				 Status#quiz_state.option3_num * 100 div Total,
				 Status#quiz_state.option4_num * 100 div Total]
		end,	
	lib_quiz:send_result(OptionNum, Status#quiz_state.righ_option),
    NewState = Status#quiz_state{
         answer_time = 0,
         righ_option = 0,
         option1_num = 0,
         option2_num = 0,
         option3_num = 0,
         option4_num = 0
    },
    %清理答案
    ets:delete_all_objects(?ETS_QUIZ_ANSWER),
    {noreply, NewState};

%% 发放奖励
handle_cast({send_award, Type}, _State) ->
    TempRank = ets:tab2list(ets_quiz_member),
    Fun = fun(A, B) ->
        A#quiz_member.score > B#quiz_member.score
    end,
    NewRank = lists:sort(Fun, TempRank),
    mod_quiz:p_award(NewRank, Type, 1),
    %本次答题完毕
    NewState = #quiz_state{},
    {noreply, NewState};

%% 下一题开始时间.
handle_cast({next_start_time, PlayerId}, Status) ->
	%1.获取下一题的时间.
	NowTime = util:unixtime(),
	NowTurn = Status#quiz_state.now_turn,
	StartTime = Status#quiz_state.start_time,	
	LastTime = StartTime + ?QUIZ_NOTICE_TIME + NowTurn *25 - NowTime,

	%2.发给客户端.
	{ok, BinData} = pt_490:write(49010, [NowTurn, LastTime]),
    lib_quiz:send_to_uid(PlayerId, BinData),
    {noreply, Status};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_quiz:handle_cast not match: ~p", [Event]),
    {noreply, Status}.