%%%--------------------------------------
%%% @Module : mod_kf_3v3_pk
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3pk进程
%%%--------------------------------------

-module(mod_kf_3v3_pk).
-behaviour(gen_server).
-include("kf_3v3.hrl").
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([
	start/6,
	onhook/4,
	report/7,
	when_kill/8,
	when_logout/4,
	mon_die/5,
	count_occupy_value/4,
	use_skill/5,
	refresh_skill/4,
	end_each_war/1,
	end_each_war_forward/1,
    create_mon_3v3/3
]).

start(KF3v3State, KeyListA, KeyListB, TeamIdA, TeamIdB, SleepTime) ->
	gen_server:start(?MODULE, [KF3v3State, KeyListA, KeyListB, TeamIdA, TeamIdB, SleepTime], []).

%% 判定为挂机
onhook(Pid, Platform, ServerNum, Id) ->
	gen_server:cast(Pid, {onhook, Platform, ServerNum, Id}).

%% 举报
report(Pid, FromPlatform, FromServerNum, FromId, ToPlatform, ToServerNum, ToId) ->
	gen_server:cast(Pid, {report, FromPlatform, FromServerNum, FromId, ToPlatform, ToServerNum, ToId}).

%% 杀人
when_kill(Pid, KillerPlatform, KillerServerNum, KillerId, DiePlatform, DieServerNum, DiedId, HelpList) ->
	gen_server:cast(Pid, {when_kill, KillerPlatform, KillerServerNum, KillerId, DiePlatform, DieServerNum, DiedId, HelpList}).

%% 刷新或掉线处理
when_logout(Pid, Platform, ServerNum, Id) ->
	gen_server:cast(Pid, {when_logout, Platform, ServerNum, Id}).

%% 占领神坛
mon_die(Pid, Platform, ServerNum, Id, MonId) ->
	gen_server:cast(Pid, {mon_die, Platform, ServerNum, Id, MonId}).

%% 计算神坛占领度
%% 每个pk进程里面，会新加一进程专门计算占领度
%% 当计算时间超规定时间，或pk时间到之后，进程销毁
count_occupy_value(Pid, TotalTime, SleepTime, PkTime) ->
	gen_server:cast(Pid, {count_occupy_value, Pid, TotalTime, SleepTime, PkTime}).

%% 使用技能
use_skill(Pid, Platform, ServerNum, Id, MonId) ->
	gen_server:cast(Pid, {use_skill, Platform, ServerNum, Id, MonId}).

%% 刷新技能
%% 每个pk进程里面，会新加一进程刷新技能
%% 当计算时间超规定时间，或pk时间到之后，进程销毁
refresh_skill(Pid, TotalTime, SleepTime, PkTime) ->
	gen_server:cast(Pid, {refresh_skill, Pid, TotalTime, SleepTime, PkTime}).

%% 结束一场战斗: 正常结束
end_each_war(Pid) ->
	gen_server:cast(Pid, {end_each_war}).

%% 结束一场战斗: 提前结束
end_each_war_forward(Pid) ->
	gen_server:cast(Pid, {end_each_war_forward}).

init([KF3v3State, KeyListA, KeyListB, TeamIdA, TeamIdB, SleepTime]) ->
	%% 随机一个场景
	SceneId = data_kf_3v3:get_rand_pk_sceneid(),
	CopyId = lib_kf_3v3:make_copyid_by_teamid(TeamIdA, TeamIdB),
	%% 取出pk场景中技能图标位置
	[Skill1, Skill2, Skill3] = lib_kf_3v3:before_pk_init_skill(data_kf_3v3:get_config(skill_list)),
	%% 初始化神坛，守护神，技能
    mod_scene_agent:apply_cast(SceneId, mod_kf_3v3_pk, create_mon_3v3, [SceneId, CopyId, [Skill1, Skill2, Skill3]]),

	%% 找出所有人的详细资料
	PlayerListA = [lib_kf_3v3:get_player_from_dict(DictKeyA, KF3v3State#kf_3v3_state.player_dict) || DictKeyA <- KeyListA],
	PlayerListB = [lib_kf_3v3:get_player_from_dict(DictKeyB, KF3v3State#kf_3v3_state.player_dict) || DictKeyB <- KeyListB],

	UpdateFun = fun(UPlayer, Group) -> 
		UPlayer#bd_3v3_player{
			group = Group
		}
	end,
	PlayerList2A = [UpdateFun(PlayerA, 1) || PlayerA <- PlayerListA],
	PlayerList2B = [UpdateFun(PlayerB, 2) || PlayerB <- PlayerListB],

	Dict = dict:new(),
	DictFun = fun(DPlayer, DDict) -> 
		dict:store([DPlayer#bd_3v3_player.platform, DPlayer#bd_3v3_player.server_num, DPlayer#bd_3v3_player.id], DPlayer, DDict)
	end,
	NewDict1 = lists:foldl(DictFun, Dict, PlayerList2A),
	NewDict2 = lists:foldl(DictFun, NewDict1, PlayerList2B),

	PkState = #pk_state{
		team_id_a = TeamIdA,
		team_id_b = TeamIdB,
		players_a = KeyListA,
		players_b = KeyListB,
		player_dict = NewDict2,
		skill_1 = Skill1,
		skill_2 = Skill2,
		skill_3 = Skill3,
		start_time = util:unixtime(),
		activity_end_time = KF3v3State#kf_3v3_state.end_time,
		pk_time = KF3v3State#kf_3v3_state.pk_time,
		scene_id = SceneId,
		copy_id = CopyId
	},

	%% 将玩家传送入战斗场景，弹出对战双方面板，刷新pk场景右边数据等
	spawn(fun() -> 
		timer:sleep(SleepTime),
		lib_kf_3v3:move_team_to_pk_scene(PkState, PlayerList2A, PlayerList2B)
	end),

	%% 发送对阵双方队友信息
%% 	lib_kf_3v3_pk:send_partner_info(PlayerListA, PlayerListB),

	{ok, PkState}.

handle_cast(Msg, State) ->
	case catch mod_kf_3v3_pk_cast:handle_cast(Msg, State) of
		{noreply, NewState} ->
			{noreply, NewState};
		{stop, Normal, NewState} ->
			{stop, Normal, NewState};
		Reason ->
			util:errlog("mod_kf_3v3_pk_cast error: ~p, Reason:=~p~n",[Msg, Reason]),
			{noreply, State}
	end.

handle_call(_Request, _From, State) ->
	Reply = ok,
	{reply, Reply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, State) ->
	spawn(fun() ->
		%% 休眠比战斗时间多10秒后，清理副本数据
		timer:sleep((State#pk_state.pk_time + 10) * 1000),
		mod_scene_agent:apply_cast(State#pk_state.scene_id, mod_scene, clear_scene, [State#pk_state.scene_id, State#pk_state.copy_id])
	end),
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.


%% 生成怪物，在场景中生成
create_mon_3v3(SceneId, CopyId, SkillXYList) ->
    %% 生成神坛
    lists:foldl(fun([OX, OY], Num) -> 
                mod_mon_create:create_mon_cast(data_kf_3v3:get_monid_by_occupy(Num, 0), SceneId, OX, OY, 1, CopyId, 1, [{auto_lv, 0}, {group, 0}]),
                Num + 1
        end, 1, data_kf_3v3:get_config(occupy_xy)),

    %% 生成守护神
    lists:foreach(fun([MonId, MX, MY, RealmType]) ->
                mod_mon_create:create_mon_cast(MonId, SceneId, MX, MY, 1, CopyId,1, [{auto_lv, 0}, {group, RealmType}])
        end, data_kf_3v3:get_config(guarder_list)),

    %% 生成技能状态
    [[SX1, SY1], [SX2, SY2], [SX3, SY3]] = SkillXYList,
    mod_mon_create:create_mon_cast(25306, SceneId, SX1, SY1, 1, CopyId, 1, [{auto_lv, 0}, {group, 0}]),
    mod_mon_create:create_mon_cast(25307, SceneId, SX2, SY2, 1, CopyId, 1, [{auto_lv, 0}, {group, 0}]),
    mod_mon_create:create_mon_cast(25308, SceneId, SX3, SY3, 1, CopyId, 1, [{auto_lv, 0}, {group, 0}]).
