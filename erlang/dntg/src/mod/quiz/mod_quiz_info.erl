%%------------------------------------------------------------------------------
%% @Module  : mod_quiz_cast
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.31
%% @Description: 答题服务器handle_info处理
%%------------------------------------------------------------------------------

-module(mod_quiz_info).
-include("common.hrl").
-include("quiz.hrl").
-export([handle_info/2]).


%分批奖励
handle_info({'pward', NewStart}, State) ->
    TempRank = ets:tab2list(ets_quiz_member),
    Fun = fun(A, B) ->
        A#quiz_member.score > B#quiz_member.score
    end,
    NewRank = lists:sort(Fun, TempRank),
    %防死循环，只进行15分钟的奖励发送
%    [Hour, _] = ?OPTION_TIME,
%    {NowHour, _, _} = time(),
%    case Hour =:= NowHour of
%        true ->
%            p_award(NewRank, 0, NewStart);
%        _ ->
%            ok
%    end,
    mod_quiz:p_award(NewRank, 0, NewStart),
    {noreply, State};

%% 默认匹配
handle_info(Info, State) ->
	catch util:errlog("mod_quiz:handle_info not match: ~p", [Info]),
    {noreply, State}.