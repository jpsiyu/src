%%%------------------------------------
%%% @Module  : mod_server
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.06.14
%%% @Description: 角色处理
%%%------------------------------------
-module(mod_server).
-behaviour(gen_server).
-export([start/0, stop/1, set_dungeon_pid/2, gst/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("common.hrl").
-include("server.hrl").
-include("dungeon.hrl").


%% HHL test 
gst(Role_Id)->    
    Pid = misc:get_player_process(Role_Id),
    gen_server:call(Pid, 'base_data').

%% 设置副本进程PID
set_dungeon_pid(Pid, Val) ->
    case is_pid(Pid) of
        false ->
            false;
        true ->
            gen_server:cast(Pid, {set_dungeon_pid, Val})
    end.

%%开始
start() ->
    gen_server:start(?MODULE, [], []).

init([]) ->
    process_flag(priority, max),
    lib_dict:start(pet, 2),
    lib_dict:start(skill, 2),
    lib_dict:start(skill_buff, 2),
    {ok, none}.

%%停止本游戏进程
stop(Pid) ->
    catch gen:call(Pid, '$gen_call', stop).

%%游戏进程死掉修改状态
terminate(_Reason, Status) ->

	%1.离线副本操作.
	CopyId = Status#player_status.copy_id,
    lib_dungeon:set_logout_type(CopyId, ?DUN_EXIT_PLAYER_LOGOUT),
    lib_dungeon:clear_role(CopyId, Status#player_status.id),
	
	%2.一些特定副本下线不清除，要断线重连.
    case lists:member(Status#player_status.scene, ?BACK_DUNGEON_LIST) of
        true ->
            skip;
        _Other ->
			lib_dungeon:clear(role, CopyId)
	end,

    %3.玩家下线，如有队伍，则离开队伍
    %pp_team:handle(24005, Status, offline),
    ok.

%% 停止游戏进程
handle_cast(stop, Status) ->
    catch mod_login:logout(Status),
    {stop, normal, Status};

%% handle_cast信息处理
handle_cast(Event, Status) ->
    misc:monitor_pid(handle_cast, Event),
    mod_server_cast:handle_cast(Event, Status).

%%停止游戏进程
handle_call(stop, _From, Status) ->
    catch mod_login:logout(Status),
    {stop, normal, Status};


%%处理socket协议
%%cmd：命令号
%%data：协议体
handle_call({'SOCKET_EVENT', Cmd, Bin}, _From, Status) ->
    case catch routing(Cmd, Status, Bin) of
        {ok, Status1} when is_record(Status1, player_status) ->
            {reply, ok, Status1};
        {ok, V, Status1} when is_record(Status1, player_status) ->
            do_return_value(V, Status1),
            {reply, ok, Status1};
        {ok, Status1} ->
            catch util:errlog("badrecord: cmd:~p:~p", [Cmd, Status1]),
            {reply, ok, Status};
        {ok, V, Status1} ->
            catch util:errlog("syn badrecord: cmd:~p:state:~p:~p", [Cmd, V, Status1]),
            {reply, ok, Status};
        {'EXIT', R} ->
            %%catch util:errlog("cmd:~p:~p~n~p", [Cmd, R, Status]),
            catch util:errlog("cmd:~p:~p:~p", [Cmd, R, Bin]),
            {reply, ok, Status};
        _ ->
            {reply, ok, Status}
    end;

%% handle_call信息处理
handle_call(Event, From, Status) ->
    misc:monitor_pid(handle_call, Event),
    mod_server_call:handle_call(Event, From, Status).

%% handle_info信息处理
handle_info(Info, Status) ->
    misc:monitor_pid(handle_info, Info),
    mod_server_info:handle_info(Info, Status).

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
%%     if
%%         Cmd =:= 1000 orelse Cmd =:= 12001 orelse Cmd =:= 41009 orelse Cmd =:= 41011 orelse Cmd =:= 13102 orelse Cmd =:= 10006 orelse Cmd =:= 15053->
%%             skip;
%%         true ->
%%             io:format("~p ~p server recv Cmd = ~p~n", [?MODULE, ?LINE, Cmd]),
%%             skip
%%     end,
    case cd_cmd(Cmd) of
        true ->
            case [H1, H2, H3] of
                "100" -> pp_login:handle(Cmd, Status, Bin);
                "101" -> pp_change_name:handle(Cmd, Status, Bin);
                "110" -> 
                    case Cmd of
                        %% 特殊协议
                        11071 ->
                            pp_chat:handle(Cmd, Status, Bin);
                        _ ->
                            TICKET = config:get_ticket(),
                            case TICKET =:= "SDFSDESF123DFSDF" of
                                true ->
                                    pp_gm:handle(Cmd, Status, Bin);
                                false ->
                                    skip
                            end
                    end;
                "120" -> pp_scene:handle(Cmd, Status, Bin);
                "121" -> pp_scene:handle(Cmd, Status, Bin);
                "123" -> pp_scene:handle(Cmd, Status, Bin);
                "130" -> pp_player:handle(Cmd, Status, Bin);
                "131" -> pp_sit:handle(Cmd, Status, Bin);
                "132" -> pp_player:handle(Cmd, Status, Bin);
                "140" -> pp_relationship:handle(Cmd, Status, Bin);
                "150" -> pp_goods:handle(Cmd, Status, Bin);
                "151" -> pp_goods:handle(Cmd, Status, Bin);
%%                "152" -> pp_secret_shop:handle(Cmd, Status, Bin);
                "153" -> pp_shop:handle(Cmd, Status, Bin);
                "154" -> pp_equip:handle(Cmd, Status, Bin);
                "155" -> pp_goods_relation:handle(Cmd, Status, Bin);
                "160" -> pp_mount:handle(Cmd, Status, Bin);
				"162" -> pp_flyer:handle(Cmd, Status, Bin);
                "166" -> pp_gemstone:handle(Cmd, Status, Bin);
                "170" -> pp_box:handle(Cmd, Status, Bin);
				"172" -> pp_qiling:handle(Cmd, Status, Bin);
                "180" -> pp_sell:handle(Cmd, Status, Bin);
				"190" -> pp_mail:handle_server(Cmd, Status, Bin);
                "200" -> pp_battle:handle(Cmd, Status, Bin);
                "210" -> pp_skill:handle(Cmd, Status, Bin);
                "220" -> pp_rank:handle(Cmd, Status, Bin);
                "250" -> pp_meridian:handle(Cmd, Status, Bin);
                "260" -> pp_secondary_password:handle(Cmd, Status, Bin);
                "270" -> pp_appointment:handle(Cmd, Status, Bin);
                "271" -> pp_marriage:handle(Cmd, Status, Bin);
				"272" -> pp_xianyuan:handle(Cmd, Status, Bin);
                "277" -> pp_qixi:handle(Cmd, Status, Bin);
                "280" -> pp_tower_dungeon:handle(Cmd, Status, Bin);
                "300" -> pp_task:handle(Cmd, Status, Bin);
                "301" -> pp_task:handle(Cmd, Status, Bin);
                "302" -> pp_task:handle(Cmd, Status, Bin);
                "303" -> pp_task:handle(Cmd, Status, Bin);
%%                 "304" -> pp_task_eb:handle(Cmd, Status, Bin);
                "305" -> pp_task_sr:handle(Cmd, Status, Bin);
                "306" -> pp_task:handle(Cmd, Status, Bin);
                "307" -> pp_task_zyl:handle(Cmd, Status, Bin);
                "310" -> pp_gift:handle(Cmd, Status,Bin);
                "311" -> pp_gift:handle(Cmd, Status,Bin);
                "312" -> pp_login_gift:handle(Cmd, Status,Bin);
                "313" -> pp_gift:handle(Cmd, Status,Bin);
                "314" -> pp_activity_daily:handle(Cmd, Status,Bin);
				"315" -> pp_festival:handle(Cmd, Status,Bin);
                "316" -> pp_firstgift:handle(Cmd, Status, Bin);
				"317" -> pp_special_activity:handle(Cmd, Status, Bin);
                "318" -> pp_off_line:handle(Cmd, Status, Bin);
				"319" -> pp_activity_kf_power:handle(Cmd, Status, Bin);
                "320" -> pp_npc:handle(Cmd, Status, Bin);
                "330" -> pp_hotspring:handle(Cmd, Status, Bin);
                "331" -> pp_fish:handle(Cmd, Status, Bin);
                "340" -> pp_designation:handle(Cmd, Status, Bin);
                "341" -> pp_target:handle(Cmd, Status, Bin);
                "342" -> pp_butterfly:handle(Cmd, Status, Bin);
                "343" -> pp_loverun:handle(Cmd, Status, Bin);
                "350" -> pp_achieve:handle(Cmd, Status, Bin);
                "360" -> pp_gift:handle(Cmd, Status, Bin);
				"361" -> pp_kaixiangzi:handle(Cmd, Status, Bin);
                "370" -> pp_fortune:handle(Cmd, Status, Bin);
                "401" -> pp_guild_scene:handle(Cmd, Status, Bin);
                "402" -> pp_factionwar:handle(Cmd, Status, Bin);
                "404" -> pp_guild_server:handle(Cmd, Status, Bin);
				"405" -> pp_guild_dun:handle(Cmd, Status, Bin);
                "420" -> pp_fcm:handle(Cmd, Status, Bin);		
                "450" -> pp_vip:handle(Cmd, Status, Bin);
                "451" -> pp_vip_dun:handle(Cmd, Status, Bin);
                "460" -> pp_husong:handle(Cmd, Status, Bin);
                "490" -> pp_quiz:handle(Cmd, Status, Bin);
                "500" -> pp_guild_battle:handle(Cmd, Status, Bin);
                "410" -> pp_pet:handle(Cmd, Status, Bin);
                "240" -> pp_team:handle(Cmd, Status, Bin);
                "610" -> pp_dungeon:handle(Cmd, Status, Bin);
                "611" -> pp_dungeon:handle(Cmd, Status, Bin);
                "612" -> pp_dungeon_secret_shop:handle(Cmd, Status, Bin);
				"613" -> pp_kingdom_rush_dungeon:handle(Cmd, Status, Bin);
                "620" -> pp_turntable:handle(Cmd, Status, Bin);
                "631" -> pp_shake_money:handle(Cmd, Status, Bin);
%%                 "640" -> pp_wubianhai:handle(Cmd, Status, Bin);
                "641" -> pp_city_war:handle(Cmd, Status, Bin);
                _ ->
                    ?ERR("[~P]路由失败.", [Cmd]),
                    {error, "Routing failure"}
            end;
        false ->
            skip
    end.
	
%% 处理路由返回值
do_return_value(Value, Status) ->
    case Value of
        battle_attr ->                  %% 更新战斗属性
            mod_scene_agent:update(battle_attr, Status);
        hp_mp ->                        %% 更新气血和内力
            mod_scene_agent:update(hp_mp, Status);
        sit ->                        	%% 更新打坐/双修状态
            mod_scene_agent:update(sit, Status);
        guild ->                        %% 更新玩家所属帮派ID
            mod_scene_agent:update(guild, Status);
        use_goods ->                    %% 使用物品
            mod_scene_agent:update(use_goods, Status);
        equip ->    %% 装备
            mod_scene_agent:update(battle_attr, Status),
            mod_scene_agent:update(equip, Status);
        husong ->                       %% 护送
            mod_scene_agent:update(husong, Status);
        pet ->                          %% 宠物
            mod_scene_agent:update(pet, Status);
	flyer ->
	    mod_scene_agent:update(flyer, Status);
        pet_addition ->
            mod_scene_agent:update(battle_attr, Status),
            mod_scene_agent:update(hp_mp, Status);
        mount ->
            mod_scene_agent:update(mount, Status);
        pk ->
            mod_scene_agent:update(pk, Status);
        wubianhai ->
            mod_scene_agent:update(wubianhai, Status);
	    battle_hp_mp ->
            mod_scene_agent:update(battle_attr, Status),
            mod_scene_agent:update(hp_mp, Status);
        _ ->
            skip
    end.

%% 需要加cd时间的协议
%%List = [{12001, 3},{120001,4}];  12001是需要加cd的协议号,3是cd的时间长度单位秒
cd_cmd(Cmd) ->
	List = [
		{33002, 10}, {33003, 5}, {33005, 50}, {34205, 10}, {34206, 10}, {45010, 5}, {45011, 5}, 
		{34203, 5}, {36006, 10}, {36007, 10}, {33025, 2}, {31408,5}, {64002, 1}, {64009, 1}, {64011, 1}, {31403,5}, {27705,1},
		{31414, 1}, {61200, 1},{62002, 1}, {18032, 1}, {34301, 1}, {34302, 1}, {34303, 1}, {34304, 1}, {34305, 1}, {33107, 3}, 
        {34306, 1}, {34307, 1}, {34309, 1}, {34312, 1}, {34313, 1}, {61011, 3}, {61012, 3}, {27124, 3}, {31204, 3}, {34314, 3}
	],
	case lists:keyfind(Cmd, 1 ,List) of
        false  ->
            true;
        {_, T} ->
            NowTime = util:unixtime(),
            case get({mod_server_cd_cmd, Cmd}) of
                undefined ->
                    put({mod_server_cd_cmd, Cmd}, NowTime),
                    true;
                LastTime ->
                    case NowTime - LastTime > T of
                        true ->
                            put({mod_server_cd_cmd, Cmd}, NowTime),
                            true;
                        false ->
                            false
                    end
            end
    end.
