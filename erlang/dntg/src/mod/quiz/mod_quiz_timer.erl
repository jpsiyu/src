%%------------------------------------------------------------------------------
%% @Module  : mod_quiz_timer
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.31
%% @Description: 答题定时器服务器
%%------------------------------------------------------------------------------

-module(mod_quiz_timer).
-behaviour(gen_fsm).
-include("common.hrl").
-include("record.hrl").
-include("quiz.hrl").
-export([start_link/0, init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4, stop/0]).

-export([sign_tick/2,    %% 广播注册.
		 send_subject/2, %% 发题.
		 answer_tick/2,  %% 答题.
		 count_score/2,  %% 统计.
		 quiz_end/2,     %% 结束.
		 init_date/2     %% 初始化数据.
]).

-export([cmd_start/0]).


cmd_start() ->
    timer_quiz:handle(ok),
    ok.

start_link() ->
%   catch util:errlog("~p start_link!! ~n", [?MODULE]),
    gen_fsm:start(?MODULE, [], []).

stop() ->
    gen_fsm:send_event(?MODULE, 'stop').

init(_) ->
    process_flag(trap_exit, true),
    %强制性发题跳转
%    erlang:send_after((?QUIZ_NOTICE_TIME - 10)*1000, self(), send_subject),
    {ok, init_date, #quiz_timer_state{}, 10}.

handle_event(_Event, _StateName, StateData) ->
    {next_state, _StateName, StateData, 10}.

handle_sync_event(_Event, _From, _StateName, StateData) ->
    {next_state, _StateName, StateData, 10}.

code_change(_OldVsn, _StateName, State, _Extra) ->
    {ok, _StateName, State}.

%handle_info(send_subject, _StateName, State) ->
%%    {next_state, send_subject, State, 10};
%    case _StateName of
%        sign_tick ->
%            catch util:errlog("~p get send subject sign!!!~n", [?MODULE]),
%            {next_state, send_subject, State, 10};
%        _ ->
%            {next_state, _StateName, State, 10}
%    end;

handle_info(quiz_stop, _StateName, State) ->
%    catch util:errlog("~p get stop sign!!!~n", [?MODULE]),
    {stop, normal, State};
    
handle_info(_Any, _StateName, State) ->
%    catch util:errlog("~p get unknow handle info:~p~n", [?MODULE, _Any]),
    {next_state, _StateName, State, 10}.

terminate(_Any, _StateName, _Opts) ->
%    catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

% ----------------------------
%         状态处理
% ----------------------------
%% 检查开启
%check_open(_R, State) ->
%    case check_state() of
%        1 ->
%            clear_data(),
%            NewStatus = State#quiz_timer_state{sign_time = ?QUIZ_NOTICE_TIME},
%            sign_tick(ok, NewStatus);
%        _ ->
%            {next_state, check_open, State, 60*1000}
%    end.

%% 初始化数据.
init_date(_R, State) ->
%    catch util:errlog("~p init date!! ~n", [?MODULE]),
    %插入进程记录表
    ets:insert(quiz_process, #quiz_process{
									        id = 1,
									        type = 1,
									        pid = self()
									        }),
     clear_data(),
     %启动答题器
    {ok, QuizPid} = mod_quiz:start_link(),
%    强制性进程关闭
    erlang:send_after(3600*1000, self(), quiz_stop),
	%1.随机一个主题类型.
	SubjectType1 = util:rand(1, 8),
	%1.圣诞答题主题活动.
	SubjectType =
		case data_activity_time:get_activity_time(11) of
			true ->
				9;
			false ->
				SubjectType1
		end,
	%2.清空之前的主题题库.
	ets:delete_all_objects(?ETS_QUIZ_OTHER),
	%2.加载答题主题题库.
	lib_quiz:load_quiz_other(SubjectType),
    spawn_link(fun()-> lib_quiz:send_sign_tick(?QUIZ_TOTAL_TIME, 0, SubjectType) end),
    {next_state, sign_tick, State#quiz_timer_state{quiz_pid = QuizPid, 
												   sign_time = ?QUIZ_NOTICE_TIME + 5,
												   subject_type = SubjectType}, 10}.

%% 广播注册
sign_tick(_R, State) ->
    case State#quiz_timer_state.sign_time > 5 of
        true ->
%            catch lib_quiz:send_sign_tick(State#quiz_timer_state.sign_time - 5, 0),
            NewStatus = State#quiz_timer_state{sign_time = State#quiz_timer_state.sign_time - 5},
            {next_state, sign_tick, NewStatus, 5*1000};
        _ ->
%            catch util:errlog("~p start_send_subject ~n", [?MODULE]),
%            lib_chat:send_quiz_notice("答题活动报名结束！"),
            NewStatus = State#quiz_timer_state{sign_time = 0},
            send_subject(ok, NewStatus)
    end.

%% 发送题目
send_subject(_R, State) ->
    case State#quiz_timer_state.turn >= ?QUIZ_TOTAL_SUBJECT of
        true ->
			%发送传闻
%% 			[Text] = data_cw_text:get_cw_text(quiz_end),
%%             lib_cw:send_quiz_notice(Text),
            %结束
            catch lib_quiz:send_to_end(),
            % -----------------------
            % 答题器通信异常处理
            % -----------------------
            cast_to_quiz(State, {send_award, State#quiz_timer_state.type}),
            NewStatus = #quiz_timer_state{},
%            catch util:errlog("~p quiz_end ~n", [?MODULE]),
            {next_state, quiz_end, NewStatus, 15*60*1000};
        _ ->
            NewStatus = State#quiz_timer_state{turn = State#quiz_timer_state.turn + 1, answer_time = 0},
            % -----------------------
            % 答题器通信异常处理
            % -----------------------
            NewStatus1 = cast_to_quiz(NewStatus, {send_quiz, State#quiz_timer_state.subject_type}),
            %五秒阅题时间【延迟一秒计算时时间】
            {next_state, answer_tick, NewStatus1, ?QUIZ_READ_TO_ANSWER + 1*1000}
    end.

%% 答题
answer_tick(_R, State) ->
    case State#quiz_timer_state.answer_time < ?QUIZ_ANSWER_TIME of
        true ->
            % -----------------------
            % 答题器通信异常处理
            % -----------------------
            NewStatus1 = cast_to_quiz(State, {answer_tick, State#quiz_timer_state.answer_time}),
            NewStatus2 = NewStatus1#quiz_timer_state{answer_time = NewStatus1#quiz_timer_state.answer_time + 1},
            {next_state, answer_tick, NewStatus2, 1*1000};
        _ ->
            count_score(ok, State)
    end.

%% 统计
count_score(_R, State) ->
    % -----------------------
    % 答题器通信异常处理
    % -----------------------
    NewStatus = cast_to_quiz(State, judge),
    %五秒判题时间【提前一秒结束，补偿阅题时间】
    {next_state, send_subject, NewStatus, ?QUIZ_COUNT_TO_SEND - 1*1000}.

%% 结束
quiz_end(_R, State) ->
    {stop, normal, State}.

% ----------------------------
%         工具函数
% ----------------------------
clear_data() ->
    ets:delete_all_objects(?ETS_QUIZ_ANSWER),
    ets:delete_all_objects(?ETS_QUIZ_MEMBER),
    ok.

% 检测答题活动状态【25分钟检测时间】
%check_state() ->
%    [Hour, Min] = ?OPTION_TIME,
%    {NowHour, NowMin, _} = time(),
%    case NowHour =:= Hour andalso (NowMin >=Min andalso NowMin =< Min + 25) of
%        true ->
%            1;
%        _ ->
%            0
%    end.

%% -------------------------
%%  答题器通信异常处理
%% -------------------------
cast_to_quiz(State, Event) ->
    case is_process_alive(State#quiz_timer_state.quiz_pid) of
        true ->
            gen_server:cast(State#quiz_timer_state.quiz_pid, Event),
            State;
        _ ->
            catch util:errlog("~p process quiz die！ ~n", [?MODULE]),
            {ok, QuizPid} = mod_quiz:start_link(),
            gen_server:cast(QuizPid, Event),
            State#quiz_timer_state{quiz_pid = QuizPid}
     end.
