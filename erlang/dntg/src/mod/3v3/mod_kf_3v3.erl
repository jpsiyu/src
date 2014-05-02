%%%--------------------------------------
%%% @Module : mod_kf_3v3
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.12.17
%%% @Description : 跨服3v3主要逻辑处理进程
%%%--------------------------------------

-module(mod_kf_3v3).
-behaviour(gen_server).
-include("kf_3v3.hrl").
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([
	start_link/0,
	onhook/3,
	report/6,
	enter_prepare/1,
	exit_prepare/3,
	sign_up_single/4,
	sign_up_team/5,
	start_matching/0,
	team_matching/0,
	when_logout/3,
	when_kill/7,
	mon_die/4,
	use_skill/4,
	end_pk/3,
	get_score_rank/4,
	set_status/1,
	open_3v3/4,
	stop_3v3/0,
	end_3v3/0
]).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 挂机
onhook(Platform, ServerNum, Id) ->
	gen_server:cast(?MODULE, {onhook, Platform, ServerNum, Id}).

%% 举报
report(FromPlatform, FromServerNum, FromId, ToPlatform, ToServerNum, ToId) ->
	gen_server:cast(?MODULE, {report, FromPlatform, FromServerNum, FromId, ToPlatform, ToServerNum, ToId}).

%% 进入准备区
enter_prepare(Args) ->
	gen_server:cast(?MODULE, {enter_prepare, Args}).

%% 退出准备区
exit_prepare(Platform, ServerNum, Id)->
	gen_server:cast(?MODULE, {exit_prepare, Platform, ServerNum, Id}).

%% 单个玩家报名
sign_up_single(Node, Platform, ServerNum, Id)->
	gen_server:cast(?MODULE, {sign_up_single, Node, Platform, ServerNum, Id}).

%% 队伍报名
sign_up_team(Node, Platform, ServerNum, Id, MemberIds)->
	gen_server:cast(?MODULE, {sign_up_team, Node, Platform, ServerNum, Id, MemberIds}).

%% 开始匹配逻辑
%% 流程：先匹配队友组成队伍，完成之后，新起进程再匹配队伍
start_matching() ->
	gen_server:cast(?MODULE, {start_matching}).

%% 匹配队伍
team_matching() ->
	gen_server:cast(?MODULE, {team_matching}).

%% 刷新或掉线处理
when_logout(Platform, ServerNum, Id) ->
	gen_server:cast(?MODULE, {when_logout, Platform, ServerNum, Id}).

%% 击杀玩家
when_kill(Platform, ServerNum, Id, KilledPlatform, KilledServerNum, KilledId, HelpList) ->
	gen_server:cast(?MODULE, {when_kill, Platform, ServerNum, Id, KilledPlatform, KilledServerNum, KilledId, HelpList}).

%% 占领神坛
mon_die(Platform, ServerNum, Id, MonId) ->
	gen_server:cast(?MODULE, {mon_die, Platform, ServerNum, Id, MonId}).

%% 使用技能
use_skill(Platform, ServerNum, Id, MonId) ->
	gen_server:cast(?MODULE, {use_skill, Platform, ServerNum, Id, MonId}).

%% pk结束之后，由pk进程调用到这里，结算收益，更新玩家数据
end_pk(PkState, PlayerListA, PlayerListB) ->
	gen_server:cast(?MODULE, {end_pk, PkState, PlayerListA, PlayerListB}).

%% 获取积分列表
%% 从这里拿完State，然后cast到mod_kf_3v3_helper进行具体的处理
get_score_rank(Platform, ServerNum, Node, Id) ->
	gen_server:cast(?MODULE, {get_score_rank, Platform, ServerNum, Node, Id}).

%% 设置活动状态
%% @param Status 1v1状态(0还未开启, 1开启报名中, 4已结束)
set_status(Status)->
	gen_server:cast(?MODULE, {set_status, Status}).

%% 跨服节点开启3v3活动
%% @param Loop		当天第几场活动
%% @param StartTime	活动开始时间（当天距离0点秒数）
%% @param EndTime	活动结束时间（当天距离0点秒数）
%% @param PkTime	每场战斗耗时(秒)
open_3v3(Loop, StartTime, EndTime, PkTime) ->
	gen_server:cast(?MODULE, {open_3v3, Loop, StartTime, EndTime, PkTime}).

%% 按照活动时间停止活动，只是禁止玩家进入准备区，和报名
%% 已经报了名和在战斗中的玩家不影响
stop_3v3() ->
	gen_server:cast(?MODULE, {stop_3v3}).

%% 跨服节点结束3v3活动，开始结算
end_3v3() ->
	gen_server:cast(?MODULE, {end_3v3}).

init([]) ->
	{ok, #kf_3v3_state{}}.

handle_call({get_status}, _From, State) ->
	{reply, State#kf_3v3_state.status, State};

handle_call(_Request, _From, State) ->
	Reply = ok,
	{reply, Reply, State}.

handle_cast(Msg, State) ->
	case catch mod_kf_3v3_cast:handle_cast(Msg, State) of
		{noreply, NewState} ->
			{noreply, NewState};
		{stop, Normal, NewState} ->
			{stop, Normal, NewState};
		Reason ->
			util:errlog("mod_kf_3v3_cast error: ~p, Reason:=~p~n",[Msg, Reason]),
			{noreply, State}
	end.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.
