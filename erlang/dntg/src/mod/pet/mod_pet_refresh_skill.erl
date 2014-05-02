%%%-------------------------------------------------------------------
%%% @Module	: mod_pet_refresh_skill
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 28 Sep 2012
%%% @Description: 
%%%-------------------------------------------------------------------
-module(mod_pet_refresh_skill).
-compile(export_all).

-record(state, {notice = []}).% 播报列表
%% 插入玩家购买记录
%% PlayerInfo: {PlayerId, NickName, Realm}
insert_buy_record(PlayerInfo, GoodsTypeId) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {insert_buy_record, PlayerInfo, GoodsTypeId}).

%% 公共线上操作取播报列表动作
get_all_record() ->
    gen_server:call(misc:get_global_pid(?MODULE), {get_all_record}).
get_one_record(PlayerId) ->
    gen_server:call(misc:get_global_pid(?MODULE), {get_one_record, PlayerId}).
get_one_and_all_record(PlayerId) ->
    gen_server:call(misc:get_global_pid(?MODULE), {get_one_and_all_record, PlayerId}).
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, #state{}}.

%% 开宝箱
handle_cast({insert_buy_record, PlayerInfo, GoodsTypeId}, State) ->
    {PlayerId, NickName, Realm} = PlayerInfo,
    NewNoticeList = [{PlayerId, NickName, Realm, GoodsTypeId, util:unixtime()}],
    NewState = State#state{notice = lists:sublist(NewNoticeList ++ State#state.notice, 8)},
    %% 增加存数据库记录
    {noreply, NewState};

handle_cast(_R , State) ->
    {noreply, State}.

%% @return:[{PlayerId, NickName, Realm, GoodsTypeId, util:unixtime()},...]
handle_call({get_all_record}, _From, State) ->
    Notice = State#state.notice,
    {reply, Notice, State};

handle_call({get_one_record, PlayerId} , _From, State) ->
    Notice = State#state.notice,
    FilterNotice = lists:filter(fun(X) ->
					{Id,_,_,_,_} = X,
					Id =:= PlayerId
				end, Notice),
    {reply, FilterNotice, State};

handle_call({get_one_and_all_record, PlayerId} , _From, State) ->
    AllNotice = State#state.notice,
    OneNotice = lists:filter(fun(X) ->
				     {Id,_,_,_,_} = X,
				     Id =:= PlayerId
			     end, AllNotice),
    {reply, {AllNotice, OneNotice}, State};

handle_call(_R , _From, State) ->
    {reply, no_match, State}.

handle_info(_Reason, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra)->
    {ok, State}.



