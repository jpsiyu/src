%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-1-30
%% Description: 宝箱模块
%% --------------------------------------------------------
-module(mod_box).
-behaviour(gen_server).
-export([start_link/0, open_box/5, get_notice/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("box.hrl").
-include("common.hrl").
-include("def_goods.hrl").
-include("sql_goods.hrl").
-include("server.hrl").

-record(state, {notice = []}).% 播报列表

%% 公共线上操作开定箱动作
open_box(PlayerStatus, BoxInfo, BoxNum, BoxBag, Bind) ->
    case gen:call(?MODULE, '$gen_call', {'open', PlayerStatus, BoxInfo, BoxNum, BoxBag, Bind}) of
        {ok, Res} -> Res;
        {'EXIT',_Reason} ->
            util:errlog("mod_box open_box error:~p", [_Reason]);
        Error -> Error
    end.

%% 公共线上操作取播报列表动作
get_notice() ->
    case gen:call(?MODULE, '$gen_call', {'notice'}) of
        {ok, Res} -> Res;
        {'EXIT',_Reason} ->
            util:errlog("mod_box get_notice error:~p", [_Reason]);
        _Error -> []
    end.

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, #state{}}.


handle_cast(_R , State) ->
    {noreply, State}.

%% 开宝箱
handle_call({'open', PlayerStatus, BoxInfo, BoxNum}, _From, State) ->
    case lib_box:open(PlayerStatus, BoxInfo, BoxNum) of
        {ok, NewPlayerStatus, GiveList, NoticeList} ->
            NewNoticeList = [{PlayerStatus#player_status.id, PlayerStatus#player_status.nickname, 
                              PlayerStatus#player_status.realm, BoxInfo#ets_box.id, GoodsTypeId, GoodsNum}
                            || {GoodsTypeId, GoodsNum, _} <- NoticeList],
            NewState = State#state{notice = lists:sublist(NewNoticeList ++ State#state.notice, 20)},
            {reply, {ok, NewPlayerStatus, GiveList, NoticeList}, NewState};
        Error ->
            ?INFO("mod_box open:~p", [Error]),
            {reply, Error, State}
    end;
handle_call({'open', PlayerStatus, BoxInfo, BoxNum, BoxBag, Bind}, _From, State) ->
    case lib_box:open(PlayerStatus, BoxInfo, BoxNum, BoxBag, Bind) of
        {ok, NewBoxBag, GiveList, NoticeList} ->
            NewNoticeList = [{PlayerStatus#player_status.id, PlayerStatus#player_status.nickname, PlayerStatus#player_status.realm, BoxInfo#ets_box.id, GoodsTypeId, GoodsNum} || {GoodsTypeId, GoodsNum, _} <- NoticeList],
            NewState = State#state{notice = lists:sublist(NewNoticeList ++ State#state.notice, 20)},
            {reply, {ok, NewBoxBag, GiveList, NoticeList}, NewState};
        Error ->
            ?INFO("mod_box open:~p", [Error]),
            {reply, Error, State}
    end;

handle_call({'notice'} , _From, State) ->
    {reply, State#state.notice, State};

handle_call(_R , _From, State) ->
    {reply, no_match, State}.

handle_info(_Reason, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra)->
    {ok, State}.



