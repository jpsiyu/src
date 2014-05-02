%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-7-4
%% Description: 物品掉落
%% --------------------------------------------------------
-module(mod_drop).
-export([start_link/0, add_drop/1, delete_drop/1, get_drop/1, clean_drop/0, get_drop_id/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("drop.hrl").

%% 插入掉落物品
add_drop(DropInfo) ->
    gen_server:call(misc:get_global_pid(?MODULE), {add, DropInfo}).

%% 删除掉落物品
delete_drop(DropId) ->
    gen_server:call(misc:get_global_pid(?MODULE), {delete, DropId}).

%% 获得掉落物品
get_drop(DropId) ->
    gen_server:call(misc:get_global_pid(?MODULE), {get, DropId}).

%% 清理掉落物品
clean_drop() ->
    gen_server:cast(misc:get_global_pid(?MODULE), {clean}).

%% 取掉落物品ID
get_drop_id() ->
    gen_server:call(misc:get_global_pid(?MODULE), {drop_id}).

%% -----------------------------------------------------------------------

start_link() ->
    gen_server:start_link({global,?MODULE}, ?MODULE, [], []).

init([]) ->
    D = dict:new(),
    {ok, {D, 0}}.

handle_call({drop_id}, _FROM, Status) ->
    {Status1, N} = Status,
    N1 = N + 1,
    {reply, N1, {Status1, N1}};

handle_call({add, DropInfo}, _FROM, Status) ->
    {Status1, N} = Status,
    case is_record(DropInfo, ets_drop) of
        true ->
            Key = DropInfo#ets_drop.id,
            D = dict:store(Key, DropInfo, Status1),
            NewD = D;
        false ->
            NewD = Status1
    end,
    NewStatus = {NewD, N},
    {reply, ok, NewStatus};

handle_call({delete, DropId}, _FROM, Status) ->
    {Status1, N} = Status,
    case dict:is_key(DropId, Status1) of
        true ->
            NewD = dict:erase(DropId, Status1);
        false ->
            NewD = Status1
    end,
    NewStatus = {NewD, N},
    {reply, ok, NewStatus};

handle_call({get, DropId}, _FROM, Status) ->
    {Status1, _N} = Status,
    case dict:is_key(DropId, Status1) of
        true ->
            {ok, DropInfo} = dict:find(DropId, Status1);
        false ->
            DropInfo = {}
    end,
    {reply, DropInfo, Status};

handle_call(_R, _FROM, Status) ->
    {reply, ok, Status}.

handle_cast({clean}, Status) ->
    {Status1, N} = Status,
    NowTime = util:unixtime(),
    List = dict:to_list(Status1),
    List2 = filter_list(List, [], NowTime),
    NewD = delete_expire_drop(List2,  Status1),
    NewStatus = {NewD, N},
    {noreply, NewStatus};

handle_cast(_R , Status) ->
    {noreply, Status}.

handle_info(_Reason, Status) ->
    {noreply, Status}.

terminate(_Reason, Status) ->
    {ok, Status}.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

%% ---------------------------------------------------------------------
%% 过滤列表
filter_list([], L, _) ->
    L;
filter_list([{_Key, DropInfo} | H], L, NowTime) ->
    case is_record(DropInfo, ets_drop) of
        true ->
            if NowTime > DropInfo#ets_drop.expire_time ->
                    filter_list(H, [DropInfo|L], NowTime);
                true ->
                    filter_list(H, L, NowTime)
            end;
        false ->
            filter_list(H, L, NowTime)
    end.

%% 删除过期物品
delete_expire_drop([], Status) ->
    Status;
delete_expire_drop([DropInfo | H], Status) ->
    case dict:is_key(DropInfo#ets_drop.id, Status) of
        true ->
            Status2 = dict:erase(DropInfo#ets_drop.id, Status);
        false ->
            Status2 = Status
    end,
    delete_expire_drop(H, Status2).

