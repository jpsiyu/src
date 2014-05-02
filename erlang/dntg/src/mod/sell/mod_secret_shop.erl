%%% -------------------------------------------------------------------
%%% Author  : xyj
%%% Description : 神秘商店(公共线)
%%%
%%% Created : 2012-5-22
%%% -------------------------------------------------------------------
-module(mod_secret_shop).
-behaviour(gen_server).
-include("shop.hrl").
-export([start_link/0, add_to_dict/1, get_shop_list/1, cast_notice_add/1, call_notice_list/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% 加入数据
add_to_dict(ShopInfo) ->
    gen_server:cast(?MODULE, {'add_dict', ShopInfo}).

get_shop_list(Id) ->
    gen_server:call(?MODULE, {'list', Id}).

cast_notice_add(Data) ->
    gen_server:cast(?MODULE, {'notice', Data}).

call_notice_list() ->
    case gen:call(?MODULE, '$gen_call', {'notice_list'}) of
        {ok, Res} -> 
            Res;
        {'EXIT',_Reason} -> 
            []
    end.

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    Dict = dict:new(),
    State = #state{notice = [], dict = Dict},
    {ok, State}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call(Request, From, State) ->
    mod_secret_shop_call:handle_call(Request, From, State).

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
    mod_secret_shop_cast:handle_cast(Msg, State).

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

