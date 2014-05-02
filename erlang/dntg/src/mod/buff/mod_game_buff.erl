%%%-----------------------------------
%%% @Module  : mod_game_buff
%%% @Author  : zhenghehe
%%% @Created : 2010.12.28
%%% @Description: 加载服务器buff
%%%-----------------------------------
-module(mod_game_buff).
-behaviour(gen_server).
%---------外部接口------------
-export([check_buff/1,       %Buff检测
         get_all_buff/0,     %获取当前游戏世界Buff
         update/0             %更新当前游戏世界Buff
        ]).

%------------------------------
-export([start_link/0, stop/0, test/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-record(state, {list=[],gamebuff=[],times=0}).

-include("common.hrl").
%% -include("record.hrl").
-include("buff.hrl").

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

stop() ->
    ?INFO("关闭~w...", [?MODULE]),
    ok.

init([]) ->
    Now = util:unixtime(),
    %启动原始数据加载
    F = fun([Id, BuffType,BuffNum,StartTime,EndTime]) ->
        Record = #ets_game_buff{
                       id = Id,
                       bufftype = BuffType,
                       buffnum = BuffNum,
                       start_time = StartTime,
                       end_time = EndTime
                       },
         case EndTime > Now of
             true ->
                ets:insert(?ETS_GAME_BUFF, Record);
             false ->
                 ok
         end,
         Record
        end,
    Status = case db:get_all(<<"select id, buff_type, buff_num, start_time, end_time from base_game_buff">>) of
        Buff when is_list(Buff) ->
            List = lists:map(F, Buff),
            #state{list = List, times = util:unixtime()};
        _ ->
            #state{times = util:unixtime()}
    end,
    {ok,Status}.

handle_call(_Request, _From, State) ->
    {noreply, State}.

handle_cast('update', _State) ->
    ets:delete_all_objects(?ETS_GAME_BUFF),
    Now = util:unixtime(),
    %启动原始数据加载
    F = fun([Id, BuffType,BuffNum,StartTime,EndTime]) ->
        Record = #ets_game_buff{
                       id = Id,
                       bufftype = BuffType,
                       buffnum = BuffNum,
                       start_time = StartTime,
                       end_time = EndTime
                       },
         case EndTime > Now of
             true ->
                ets:insert(?ETS_GAME_BUFF, Record);
             false ->
                 ok
         end,
         Record
        end,
    NewStatus = case db:get_all(<<"select id, buff_type, buff_num, start_time, end_time from base_game_buff">>) of
        Buff when is_list(Buff) ->
            List = lists:map(F, Buff),
            #state{list = List, times = util:unixtime()};
        _ ->
            #state{times = util:unixtime()}
    end,
    %通知游戏世界重新加载buff
    Data = ets:tab2list(?ETS_GAME_BUFF),
    {ok, BinData} = pt_130:write(13052, Data),
    lib_server_send:send_to_all(BinData),
    {noreply, NewStatus};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%------外部接口-------%
%更新
update() ->
    gen_server:cast(?MODULE, 'update').


check_buff(BuffType) ->
    Now = util:unixtime(),
    MS = [{#ets_game_buff{bufftype = '$1', buffnum = '$2', start_time = '$3', end_time = '$4', _ = '_'},
           [{'=:=', '$1', BuffType}, {'<', '$3', Now}, {'>', '$4', Now}],
           ['$2']}],
    case ets:select(?ETS_GAME_BUFF, MS) of
        {error, _Reason} ->
            1;
        [BNum] ->
            BNum;
        _ ->
            1
    end.

%-record(ets_game_buff, {
%    id = 0, %%id
%    bufftype = 0, %% buff类型
%    buffnum = 0,  %% 加倍类型
%    start_time = 0, %%开始时间
%    end_time = 0    %%结束时间
%    })

%获取总buff
%return：[[buff类型，buff倍率，buff到期时间]，……]
get_all_buff() ->
    List = ets:match(?ETS_GAME_BUFF, #ets_game_buff{bufftype='$1', buffnum='$2', end_time='$3', _= '_'}),
    List.

%------测试-----------%
test() ->
%    STime = util:unixtime(),
%    F = fun(_) ->
%        check_buff(1)
%        end,
%    List = lists:seq(1,1000000,1),
%    lists:foreach(F, List),
%    ETime = util:unixtime(),
%    io:format("Time=~p~n", [ETime - STime]),
    ok.

%test1() ->
%    STime = util:unixtime(),
%    F = fun(_) ->
%        check_buff1(1)
%        end,
%    List = lists:seq(1,1000000,1),
%    lists:foreach(F, List),
%    ETime = util:unixtime(),
%    io:format("Time=~p~n", [ETime - STime]),
%    ok.

%%------私有函数-------%
%localtime_to_seconds([Data, Time]) ->
%    [UTCData] = calendar:local_time_to_universal_time_dst({Data,Time}),
%    calendar:datetime_to_gregorian_seconds(UTCData)-?DIFF_SECONDS_0000_1900.