%%% -------------------------------------------------------------------
%%% Author  : zengzhaoyuan
%%% Description :
%%%
%%% Created : 2012-5-22
%%% -------------------------------------------------------------------
-module(mod_kf_1v1).
-behaviour(gen_server).
-include("kf_1v1.hrl").
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([
	 when_kill/12,
	 set_status/1,
	 get_status/0,
	 end_bd_1v1/0
]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).


%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(?MODULE, stop).

%% ====================================================================
%% Server functions
%% ====================================================================
%%观战
look_war(Node,Platform,Server_num,Id,Loop,A_Flat,A_Server_id,A_Id,B_Flat,B_Server_id,B_Id)->
	gen_server:cast(?MODULE,{look_war,Node,Platform,Server_num,Id,Loop,A_Flat,A_Server_id,A_Id,B_Flat,B_Server_id,B_Id}).

%% 玩家掉线时，属性设置
%% Type : 1下线  2退出按钮
when_logout(Platform,Server_num,Id,Hp,Hp_lim,Combat_power,Type)->
	gen_server:cast(?MODULE,{when_logout,Platform,Server_num,Id,Hp,Hp_lim,Combat_power,Type}).

%% 进入准备区
%% @param UniteStatus 公共性状态
%% @return [Result,Loop,State,RestTime,WholeRestTime]
enter_prepare(UniteStatus,Platform,Server_num,Node,Pt_lv,Combat_power,Loop_day,Max_Combat_power)->
	gen_server:cast(?MODULE,{enter_prepare,UniteStatus,Platform,Server_num,Node,Pt_lv,Combat_power,Loop_day,Max_Combat_power}).

%% 退出准备区
%% @param Id 玩家Id
%% @param IsIn 0 out|1 in
%% @param Combat_power 当IsIn的值为1的时候，需要赋值，其他时候，直接给0
in_or_exit_prepare(Platform,Server_num,Id,IsIn,Combat_power)->
	gen_server:cast(?MODULE,{in_or_exit_prepare,Platform,Server_num,Id,IsIn,Combat_power}).

%%退出跨服
exit_prepare(Node,Platform,Server_num,Id)->
	gen_server:cast(?MODULE,{exit_prepare,Node,Platform,Server_num,Id}).

%%设置状态
%%@param Bd_1v1_Status 1v1状态 0还未开启  1开启报名中 2开启准备中 3开启比赛中 4已结束
set_status(Bd_1v1_Status)->
	gen_server:cast(?MODULE,{set_status,Bd_1v1_Status}).

get_status()->
	gen_server:cast(?MODULE,{get_status}).

%%获取排序后列表
get_player_top_list(Node,Platform,Server_num,Id)->
	gen_server:cast(?MODULE,{get_player_top_list,Node,Platform,Server_num,Id}).

get_player_pk_list(Node,Platform,Server_num,Id)->
	gen_server:cast(?MODULE,{get_player_pk_list,Node,Platform,Server_num,Id}).

%% 击杀玩家
%% @param Uid 
%% @param KilledUid
when_kill(Platform,Server_num,Uid,UidPower,UidHp,UidHpLim,KilledPlatform,KilledServer_num,KilledUid,KilledUidPower,KilledUidHp,KilledUidHpLim)->
	gen_server:cast(?MODULE,{when_kill,Platform,Server_num,Uid,UidPower,UidHp,UidHpLim,KilledPlatform,KilledServer_num,KilledUid,KilledUidPower,KilledUidHp,KilledUidHpLim}).

%%开启本服1v1
%% @param Loop 总轮次
%% @param Config_End 总结束时刻
%% @param Sign_up_end_time 报名结束时刻
open_bd_1v1(Loop,Loop_time,Sign_up_time)->
	gen_server:cast(?MODULE,{open_bd_1v1,Loop,Loop_time,Sign_up_time}).

%% 报名结束：分配对阵名单
%% @param Rest_end_time 准备结束时刻
sign_up_end()->
	gen_server:cast(?MODULE,{sign_up_end}).

%%报名
%%@param Platform 平台
%%@param Server_num 平台
%%@param Id 平台
sign_up(Node,Platform,Server_num,Id)->
	gen_server:cast(?MODULE,{sign_up,Node,Platform,Server_num,Id}).

%%进入每场战斗
goin_war(Player,Element,Bd_1v1_room)->
	gen_server:cast(?MODULE,{goin_war,Player,Element,Bd_1v1_room}).

%% 结束每一个战斗
%% @param Bd_1v1_room 一个战斗
end_each_war(Player,Element,Bd_1v1_room)->
	gen_server:cast(?MODULE,{end_each_war,Player,Element,Bd_1v1_room}).

%%本服1v1结束时处理逻辑
end_bd_1v1()->
	gen_server:cast(?MODULE,{end_bd_1v1}).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {ok, #kf_1v1_state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({get_status}, _From, State) ->
    Reply = State#kf_1v1_state.bd_1v1_stauts,
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
    case catch mod_kf_1v1_cast:handle_cast(Msg, State) of
        {noreply, NewState} ->
            {noreply, NewState};
        {stop, Normal, NewState} ->
            {stop, Normal, NewState};
        Reason ->
            util:errlog("mod_kf_1v1_cast error: ~p, Reason:=~p~n",[Msg, Reason]),
            {noreply, State}
    end.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
