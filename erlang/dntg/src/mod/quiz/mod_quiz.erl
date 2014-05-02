%%------------------------------------------------------------------------------
%% @Module  : mod_quiz
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.31
%% @Description: 答题服务器
%%------------------------------------------------------------------------------

-module(mod_quiz).
-behaviour(gen_server).
-include("common.hrl").
-include("quiz.hrl").
-export([start_link/0, p_award/3, get_max_sel/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


start_link() ->
    gen_server:start_link(?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    ets:insert(quiz_process, #quiz_process{
        id = 2,
        type = 2,
        pid = self()
        }),

	%得到活动的倍数.
	Multiple_all_data = mod_multiple:get_all_data(),
	Multiple = lib_multiple:get_multiple_by_type(5,Multiple_all_data),
	case Multiple > 0 of
		true ->
			put("multiple", Multiple);
		false ->
			put("multiple", 1)
	end,

    {ok, #quiz_state{state = 1, start_time = util:unixtime()}}.

handle_call(Request, From, State) ->
    mod_quiz_call:handle_call(Request, From, State).

handle_cast(Msg, State) ->
    mod_quiz_cast:handle_cast(Msg, State).

handle_info(Info, State) ->
    mod_quiz_info:handle_info(Info, State).

   
terminate(_Reason, _Status) ->
    catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

% -------------------------
%  工具函数
% -------------------------
get_max_sel([A, B, C, D]) ->
    Max = lists:max([A, B, C, D]),
    if
        A =:= Max ->
            1;
        B =:= Max ->
            2;
        C =:= Max ->
            3;
        true ->
            4
    end.

p_award(Rank, Type, Start) when length(Rank)>0->
	%得到活动的倍数.
	Multiple = get("multiple"),
    %处理排名
    List = lists:sublist(Rank, Start, 30),
    lib_quiz:send_award(List, Start, Type, Multiple),
    %后续判断
    NewStart = Start + 30,
    case NewStart > length(Rank) of
        true ->
            ok;
        _ ->
            timer:send_after(2000, self(), {'pward', NewStart})
    end;
p_award(_, _,_) ->
    ok.
