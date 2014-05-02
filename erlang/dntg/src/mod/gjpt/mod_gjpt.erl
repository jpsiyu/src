%%%------------------------------------------------
%%% @Module  : mod_gjpt
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.8.18
%%% @Description: 国家声望
%%%------------------------------------

-module(mod_gjpt).
-include("server.hrl").
-include("scene.hrl").
-include("predefine.hrl").
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% Id1:杀人者ID
%% Id2:被杀者ID
lookup_last_kill_time(Id1, Id2) ->
	gen_server:call(misc:get_global_pid(?MODULE), {lookup_last_kill_time, Id1, Id2}).

%% Id1:杀人者ID
%% Id2:被杀者ID
insert_last_kill_time(Id1, Id2, Time) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {insert_last_kill_time, Id1, Id2, Time}).

%% 罪恶值大于0的玩家进行登记
player_reg(PlayerId, PkValue) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {player_reg, PlayerId, PkValue}).

all_reg_player() ->
    gen_server:call(misc:get_global_pid(?MODULE), {all_reg_player}).

del_reg_player(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE), {del_reg_player, PlayerId}).

start_link() ->
	gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    spawn(fun() -> gjpt_timer() end),
    {ok, 0}.

%% call
handle_call({lookup_last_kill_time, Id1, Id2}, _From, Status) ->
	Reply = case get({last_kill_time, Id1, Id2}) of
		undefined -> 0;
		Time -> Time
	end,
    {reply, Reply, Status};

handle_call({all_reg_player}, _From, Status) ->
	Reply = list_deal(get(), []),
    {reply, Reply, Status};

handle_call(Event, _From, Status) ->
    catch util:errlog("mod_gjpt:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.

%% cast
handle_cast({insert_last_kill_time, Id1, Id2, Time}, Status) ->
	put({last_kill_time, Id1, Id2}, Time),
    {noreply, Status};

handle_cast({player_reg, PlayerId, PkValue}, Status) ->
    case PkValue =< 0 of
        true -> erase({player_reg, PlayerId});
        false -> put({player_reg, PlayerId}, util:unixtime())
    end,
    {noreply, Status};

handle_cast({del_reg_player, PlayerId}, Status) ->
    erase({player_reg, PlayerId}),
    {noreply, Status};

handle_cast(Msg, Status) ->
    catch util:errlog("mod_gjpt:handle_cast not match: ~p", [Msg]),
    {noreply, Status}.

%% info
handle_info(Info, Status) ->
    catch util:errlog("mod_gjpt:handle_info not match: ~p", [Info]),
    {noreply, Status}.

terminate(_Reason, _Status) ->
    %catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

gjpt_timer() ->
    util:sleep(5 * 60 * 1000),
    AllPlayer = mod_gjpt:all_reg_player(),
    all_deal(AllPlayer),
    gjpt_timer().

list_deal([], L) -> L;
list_deal([H | T], L) ->
    case H of
        {{player_reg, PlayerId}, LastTime} -> list_deal(T, [{PlayerId, LastTime} | L]);
        _ -> list_deal(T, L)
    end.

all_deal([]) -> skip;
all_deal([H | T]) ->
    case H of
        {PlayerId, LastTime} -> 
            case misc:get_player_process(PlayerId) of
                Pid when is_pid(Pid) ->
                    case util:unixtime() - LastTime >= 5 * 60 of
                        true ->
                            gen_server:cast(Pid, {'set_data', [{minus_pk_value, 8}]});
                        false -> skip
                    end;
                _ -> 
                    mod_gjpt:del_reg_player(PlayerId)
            end;
        _ -> skip
    end,
    all_deal(T).

%% 减少玩家罪恶值
minus_player_pk_value(PlayerId, Value) ->
    case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'set_data', [{minus_pk_value, Value}]});
        _ -> 
            mod_gjpt:del_reg_player(PlayerId)
    end.

%% 判断用户是否在监狱中
is_in_prison(Status) ->
    case Status#player_status.pk#status_pk.pk_value > 500 of
        true ->
            case Status#player_status.scene =:= ?PRISON_SCENE of
                true -> skip;
                false -> 
                    Scene = data_scene:get(?PRISON_SCENE),
                    lib_scene:player_change_scene(Status#player_status.id, ?PRISON_SCENE, 0, Scene#ets_scene.x, Scene#ets_scene.y, false)
            end,
            true;
        false -> 
            case Status#player_status.scene =:= ?PRISON_SCENE of
                true -> 
                    {X, Y} = lib_scene:get_main_city_x_y(),
                    lib_scene:player_change_scene(Status#player_status.id, ?MAIN_CITY_SCENE, 0, X, Y, false);
                false -> skip
            end,
            false
    end.

put_to_prison(Status) ->
    case Status#player_status.pk#status_pk.pk_value > 500 of
        true ->
            case Status#player_status.scene == ?PRISON_SCENE of %998 of
                true -> Status;
                false -> 
                    Scene = data_scene:get(?PRISON_SCENE),
                    Status#player_status{scene = ?PRISON_SCENE, copy_id = 0, x = Scene#ets_scene.x, y = Scene#ets_scene.y}
            end;
        false -> 
            case Status#player_status.scene == ?PRISON_SCENE of
                true -> 
                    {X, Y} = lib_scene:get_main_city_x_y(),
                    Status#player_status{scene = ?MAIN_CITY_SCENE, copy_id = 0, x = X, y = Y};
                false -> Status
            end
    end.
