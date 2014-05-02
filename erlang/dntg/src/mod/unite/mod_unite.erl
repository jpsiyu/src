%%%------------------------------------
%%% @Module  : mod_unite
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.06.14
%%% @Description: 公共服务处理
%%%------------------------------------
-module(mod_unite).
-behaviour(gen_server).
-export([start/0, stop/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("common.hrl").
-include("unite.hrl").

%%开始
start() ->
    gen_server:start(?MODULE, [], []).

init([]) ->
    process_flag(priority, max),
    {ok, none}.

%%停止本游戏进程
stop(Pid) 
  when is_pid(Pid) ->
    gen_server:call(Pid, stop).

%%游戏进程死掉修改状态
terminate(_Reason, _Status) ->
    ok.

%% 停止游戏进程
handle_cast(stop, Status) ->
    mod_login:logout(Status),
    {stop, normal, Status};

%% handle_cast信息处理
handle_cast(Event, Status) ->
    mod_unite_cast:handle_cast(Event, Status).

%%停止游戏进程
handle_call(stop, _From, Status) ->
    mod_login:logout(Status),
    {stop, normal, Status};

%%处理socket协议
%%cmd：命令号
%%data：协议体
handle_call({'SOCKET_EVENT', Cmd, Bin}, _From, Status) ->
    case catch routing(Cmd, Status, Bin) of
        {ok, Status1} when is_record(Status1, unite_status)->
            mod_login:save_online(Status1),
            {reply, ok, Status1};
        {ok, Status1} ->
            catch util:errlog("badrecord: cmd:~p:~p", [Cmd, Status1]),
            {reply, ok, Status};
        {'EXIT', R} ->
            catch util:errlog("cmd:~p:~p", [Cmd, R]),
            {reply, ok, Status};
        _ ->
            {reply, ok, Status}
    end;

%% handle_call信息处理
handle_call(Event, From, Status) ->
    mod_unite_call:handle_call(Event, From, Status).

%% handle_info信息处理
handle_info(Info, Status) ->
    mod_unite_info:handle_info(Info, Status).

code_change(_oldvsn, Status, _extra) ->
    {ok, Status}.

%%
%% ------------------------私有函数------------------------
%%
%% 路由
%%cmd:命令号
%%Socket:socket id
%%data:消息体
routing(Cmd, Status, Bin) ->
    %%取前面二位区分功能类型
    [H1, H2, H3, _, _] = integer_to_list(Cmd),
    case cd_cmd(Cmd) of
        true ->
            case [H1, H2, H3] of
                %%游戏基础功能处理
                "100" -> pp_login:handle(Cmd, Status, Bin);
                "110" -> pp_chat:handle(Cmd, Status, Bin);
                "119" -> pp_setting:handle(Cmd, Status, Bin);
                "112" -> pp_chat:handle(Cmd, Status, Bin);
                "131" -> pp_sit:handle(Cmd, Status, Bin);
                "140" -> pp_relationship:handle(Cmd, Status, Bin);
                %%"152" -> pp_secret_shop:handle(Cmd, Status, Bin);
                "153" -> pp_shop:handle(Cmd, Status, Bin);
                "180" -> pp_sell_unite:handle(Cmd, Status, Bin);
                "190" -> pp_mail:handle(Cmd, Status, Bin);
                "220" -> pp_rank:handle(Cmd, Status, Bin);
                "240" -> pp_team2:handle(Cmd, Status, Bin);
                "270" -> pp_appointment:handle(Cmd, Status, Bin);
                "271" -> pp_marriage:handle(Cmd, Status, Bin);
                "280" -> pp_tower_dungeon:handle(Cmd, Status, Bin);
                "290" -> pp_flower:handle(Cmd, Status, Bin); 
				"315" -> pp_festival:handle(unite, Cmd, Status, Bin);
				"319" -> pp_activity_kf_power:handle(Cmd, Status, Bin);
                "342" -> pp_butterfly:handle(Cmd, Status, Bin);
                "343" -> pp_loverun:handle(Cmd, Status, Bin);
                "370" -> pp_fortune:handle(Cmd, Status, Bin);
				"380" -> pp_almanac:handle(Cmd, Status, Bin);
                "400" -> pp_guild:handle(check, Cmd, Status, Bin); 
                "402" -> pp_factionwar:handle(Cmd, Status, Bin);
				"403" -> pp_guild:handle(check, Cmd, Status, Bin); 
                %% 		"440" -> pp_master:handle(Cmd, Status, Bin);
                "480" -> pp_arena_new:handle(Cmd, Status, Bin);
				"481" -> pp_peach:handle(Cmd, Status, Bin);
				"483" -> pp_kf_1v1:handle(Cmd, Status, Bin);
				"484" -> pp_kf_3v3:handle(Cmd, Status, Bin);
				"485" -> pp_god:handle(Cmd, Status, Bin);
                "610" -> pp_tower_dungeon:handle(Cmd, Status, Bin);
                "620" -> pp_turntable:handle(Cmd, Status, Bin);
                "630" -> pp_shengxiao:handle(Cmd, Status, Bin);
%%                 "640" -> pp_wubianhai:handle(Cmd, Status, Bin);
                "641" -> pp_city_war:handle(Cmd, Status, Bin);
                %%错误处理
                _ ->
                    ?ERR("[~w]路由失败.", [Cmd]),
                    {error, "Routing failure"}
            end;
        false ->
            skip
    end.

%% 需要加cd时间的协议
%%List = [{12001, 3},{120001,4}];  12001是需要加cd的协议号,3是cd的时间长度单位秒
cd_cmd(Cmd) ->
	List = [
		{13113, 50*60},
		{48109, 3},
		{48506,3},{48511,10},{48512,5},{48514,2},{48515,50},
		{48005, 5},{48003, 3},{48009,3},{40205,3},{40212,3},{40219,3},{48210,5},
		{48305, 20},{48306, 1},{48310, 20},{48313, 10},{48314, 10},{48410, 5},
		{19004, 3},{19005, 3},{19008, 3},{11901, 1},{48405,20},{48414,60},{48424, 60},
        {64003, 1},{64004, 1},{11031, 3},{22005, 20},{34300, 1},{34310, 1},{34311, 1},{15200, 1},
		{31901, 60}
	],
    case lists:keyfind(Cmd, 1, List) of
        false  ->
            true;
        {_, T} ->
            NowTime = util:unixtime(),
            case get({mod_unite_cd_cmd, Cmd}) of
                undefined ->
                    put({mod_unite_cd_cmd, Cmd}, NowTime),
                    true;
                LastTime ->
                    case NowTime - LastTime > T of
                        true ->
                            put({mod_unite_cd_cmd, Cmd}, NowTime),
                            true;
                        false ->
                            false
                    end
            end
    end.
