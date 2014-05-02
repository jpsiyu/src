%%%-------------------------------------------------------------------
%%% @Module	: mod_turntable_cast
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	:  5 Jul 2012
%%% @Description: 转盘cast
%%%-------------------------------------------------------------------
-module(mod_turntable_cast).
-export([handle_cast/2]).
-include("server.hrl").
-include("turntable.hrl").
-include("common.hrl").
-include("unite.hrl").
-include("goods.hrl").

handle_cast(clear_dict, State) ->
    Now = util:unixtime(),
    F = fun(K, _V) when K =:= player_goods ->
		true;
	   (_K, _V) ->
		false
	end,
    case orddict:filter(F, State) of
	[] ->
	    Filter = [];
	[{_, Filter}] ->
	    Filter
    end,
    Val = lists:filter(fun(X) ->
			       {_, _, _, _, _, TS} = X,
			       case TS of 
				   TS when TS >= Now + 60 ->
				       true;
				   _ ->
				       false
			       end
		       end, Filter),
    NewState = orddict:store(?ETS_PLAYER_GOODS, Val, State),
    {noreply, NewState};
handle_cast(stop, State) ->
    %% io:format("cast writting acccoin into db~n"),
    %% Q = io_lib:format(<<"insert into turntable_ultimate_prize(`acccoin`, `timestamp`) values(~p,~p)">>,[State, util:unixtime()]),
    %% db:execute(Q),
    {stop, normal, State};
%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_server_cast:handle_cast not match: ~p", [Event]),
    {noreply, Status}.
