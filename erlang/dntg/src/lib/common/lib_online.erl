%%%------------------------------------
%%% @Module     : lib_online
%%% @Author     : huangyongxing
%%% @Email      : huangyongxing@yeah.net
%%% @Created    : 2010.10.28
%%% @Description: 在线人数统计
%%%------------------------------------
-module(lib_online).
-export([log_online/1, online_state/0, update_online_num/1, do_check_mem/0]).
-include("common.hrl").
-include("record.hrl").
-include("server.hrl").

%% 统计在线人数
log_online(Turn) ->
    online_state(),
    F = fun(Server) ->
            Num = case rpc:call(Server#node.node, lib_online, online_state, []) of
                {badrpc, _R} ->
                    0;
                N ->
                    N
            end,
            [Server#node.id, Server#node.node, Num, Server#node.state]
    end,
    ServerList = mod_disperse:node_all_list(),
    %% 根据Server的Id排序
    NewServerList = lists:usort(
        fun(Server1, Server2) ->
                hd(Server1) < hd(Server2)
        end,
        [F(Server) || Server <- ServerList]),
    NumList = [Num || [_, _, Num, _] <- NewServerList],
    case NumList of
        [] ->
            skip;
        _ ->
            %Total = lists:sum(NumList),
            case Turn == 0 of
                true -> 
                    Timestamp = util:unixtime(), 
                    Total = mod_chat_agent:get_online_num(),
                    OnlineInfo = binary_to_list(list_to_binary(io_lib:format("~w", [NumList]))),
                    Sql = lists:concat(["insert into log_online (total, online, timestamp) values (", Total, ", '", OnlineInfo, "', ", Timestamp, ")"]),
                    db:execute(Sql);
                false -> skip
            end,
            update_all_num(NewServerList)
    end.

%% 更新除聊天服务器外的所有服务器的ets_node表人数
update_all_num(ServerList) ->
    update_online_num(ServerList),      %% 更新gateway上的ets_node表
    AllServerNodes = [Node || [_, Node, _, _] <- ServerList],
    rpc:eval_everywhere(AllServerNodes, lib_online, update_online_num, [ServerList]).

%% 更新本节点ets_node表人数
update_online_num(ServerList) ->
    F = fun([Id, _, Num, State]) ->
        ets:update_element(?ETS_NODE, Id, [{#node.num, Num}, {#node.state, State}])
    end,
    lists:foreach(fun(Server) -> F(Server) end, ServerList).

%% 在线状况
online_state() ->
    spawn(
        fun() ->
            check_db(),
            case mod_disperse:node_id() =/= 0 of
                true ->
                    check_mem();
                false ->
                    skip
            end
    end),
    case ets:info(?ETS_ONLINE, size) of
        undefined ->
            0;
        Num ->
            Num
    end.

%% 相当数据库心跳包
check_db() ->
    F = fun(_) -> db:get_one("SELECT id FROM node LIMIT 1") end,
    lists:foreach(F, lists:duplicate(10,a)).

%% 检查内存消耗
%% 默认设置30分钟检查一次
%% 内存上限500M
check_mem() ->
     {_, {_H, I, _S}} = erlang:localtime(),
    case I rem 30 =:= 0 of
        true ->
            check_mem(1000000000);
        false ->
            skip
    end.

%% 手动执行
do_check_mem() ->
    check_mem(1000000000).


%% 检查溢出的内存，强制gc, 并写入日志分析
check_mem(MemLim) ->
    lists:foreach(
        fun(P) ->
            case is_pid(P) andalso is_process_alive(P)  of
                true ->
                    {memory, Mem} = erlang:process_info(P, memory),
                    case Mem  > MemLim of
                        true ->
                            erlang:garbage_collect(P),
                            %% 写入日志记录
                            catch util:errlog("===check_mem===:~p", [erlang:process_info(P)]);
                        false ->
                            []
                    end;
                false ->
                    []
            end
        end, erlang:processes()).
