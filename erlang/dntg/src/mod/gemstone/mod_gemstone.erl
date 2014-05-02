%%%------------------------------------
%%% module  : mod_gemstone
%%% @Author : huangwenjie
%%% @Email  : 1015099316@qq.com
%%% @Create : 2014.2.19
%%% @Description: 宝石系统
%%%-------------------------------------
-module(mod_gemstone).
-include("server.hrl").
-include("common.hrl").
-include("gemstone.hrl").
-compile(export_all).
start_link() -> 
    gen_server:start_link(?MODULE, [], []).

stop(Pid) -> 
    case is_pid(Pid) andalso is_process_alive(Pid) of 
        true -> gen_server:cast(Pid, stop);
        false -> skip 
    end.

%%更新全部宝石栏
update_all(GemPid, PlayerId, GemStones) -> 
    gen_server:cast(GemPid, {update_all, [PlayerId, GemStones]}).

%% 更新单个宝石栏
update_one(GemPid, PlayerId, GemStone) -> 
    gen_server:cast(GemPid, {update_one, [PlayerId, GemStone]}).

%% 取全部宝石栏
get_all(GemPid, PlayerId) -> 
    gen_server:call(GemPid, {get_all, PlayerId}).

%% 取单个宝石栏
get_one(GemPid, PlayerId, Id) -> 
    gen_server:call(GemPid, {get_one, [PlayerId, Id]}).

%% 取单个装备位置的宝石栏列表
get_one_equippos(GemPid, PlayerId, EquipPos) ->
    gen_server:call(GemPid, {get_one_equippos, [PlayerId, EquipPos]}).

init([]) -> 
    {ok, ?MODULE}.

handle_cast({update_all, [PlayerId, GemStones]}, State) -> 
    put(PlayerId, GemStones),
    {noreply, State};

handle_cast({update_one, [PlayerId, GemStone]}, State) -> 
    GemStones = get(PlayerId), 
    case GemStones =:= undefined of 
        true -> 
            put(PlayerId, [GemStone]);
        false -> 
            _List = lists:keydelete(GemStone#gemstone.id, 2, GemStones),
            List = [GemStone|_List],
            SortList = lists:keysort(2, List),
            put(PlayerId, SortList)
    end,
    {noreply, State};

handle_cast(_Msg, State) -> 
    {noreply, State}.

handle_call({get_all, PlayerId}, _From, State) -> 
    GemStones = get(PlayerId),
    Reply = case GemStones =:= undefined of 
        true -> [];
        false -> GemStones
    end,
    {reply, Reply, State};

handle_call({get_one, [PlayerId, Id]}, _From, State) -> 
    GemStones = get(PlayerId),
    Reply = case GemStones =:= undefined of 
        true -> [];
        false -> 
            One = lists:keyfind(Id, 2, GemStones),
            case One =:= false of  
                true -> [];
                false -> One
            end
    end,
    {reply, Reply, State};

handle_call({get_one_equippos, [PlayerId, EquipPos]}, _From, State) ->
    GemStones = get(PlayerId),
    Reply = case GemStones =:= undefined of 
        true ->
            [];
        false ->
            List = lists:filter(fun(GemStone) -> GemStone#gemstone.equip_pos =:= EquipPos end, GemStones),
            List
    end,
    {reply, Reply, State};

handle_call(_Request, _From, State) -> 
    Reply = ok,
    {reply, Reply, State}.

handle_info(_Event, State) -> 
    {noreply, State}.

terminate(_Reason, _State) -> 
    ok.

code_change(_OldVsn, State, _Extra) -> 
    {ok, State}.
    