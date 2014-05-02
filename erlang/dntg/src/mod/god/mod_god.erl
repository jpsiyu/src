%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2013-1-7
%%% -------------------------------------------------------------------
-module(mod_god).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("god.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([]).

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
%% 开启
%% @param mod 状态：0无赛事、1海选赛、2小组赛、3复活赛/人气赛、4总决赛
%% @param status 开启状态: 0 未开启 1 进行中 2 已结束
%% @param Year 活动-年
%% @param Month 活动-月
%% @param Day 活动-日
open(Mod,Next_mod,God_no,Open_time,Config_end)->
	gen_server:cast(?MODULE, {open,Mod,Next_mod,God_no,Open_time,Config_end}).

%% 关闭
close()->
	gen_server:cast(?MODULE, {close}).

%%鄙视
bs(Flat,Server_id,Id,God_no,Type)->
	gen_server:cast(?MODULE, {bs,Flat,Server_id,Id,God_no,Type}).

%%推送
set_god_top50(Node)->
	gen_server:cast(?MODULE, {set_god_top50,Node}).

%% 结算
balance(Mod,Next_mod)->
	gen_server:cast(?MODULE, {balance,Mod,Next_mod}).

%%送入战场
goin_war(God_pk_key,G_a,G_b)->
	gen_server:cast(?MODULE, {goin_war,God_pk_key,G_a,G_b}).

%% 人气PK
vote_relive(Flat,Server_id,Id)->
	gen_server:cast(?MODULE, {vote_relive,Flat,Server_id,Id}).

%% 复活名单
vote_relive_list()->
	gen_server:cast(?MODULE, {vote_relive_list}).

get_mod_and_status()->
	gen_server:call(?MODULE, {get_mod_and_status}).

%% 给各服设置状态、赛事
set_mod_and_status(Node)->
	gen_server:cast(?MODULE, {set_mod_and_status,Node}).

%% 给服务设置状态
set_mod_and_status(God_no,Mod,Status,Config_End)->
	gen_server:cast(?MODULE, {set_mod_and_status,God_no,Mod,Status,Config_End}).

%% 其他非诸神场景进入准备区、战斗后进入准备区
%% @param From war|out|其他原子值
%% @param Node 节点值
%% @param Plat 平台
%% @param Server_id 服务器号
%% @param Id 玩家ID
%% @param Name 玩家名称
%% @param Country 玩家国家
%% @param Sex 玩家性别
%% @param Carrer 玩家职业
%% @param Image 玩家头像
%% @param Lv 玩家等级
%% @param Combat_power 玩家战力
%% @param Hightest_combat_power 玩家历史最高战力
goin(From,Node,Flat,Server_id,Id,Name,Country,Sex,Carrer,
     Image,Lv,Combat_power,Hightest_combat_power)->
	gen_server:cast(?MODULE, {goin,From,Node,Flat,Server_id,Id,Name,Country,Sex,Carrer,
				  			  Image,Lv,Combat_power,Hightest_combat_power}).

%%退出操作
%% @param Node 节点值
%% @param Plat 平台
%% @param Server_id 服务器号
%% @param Id 玩家ID
%% @param Scene_id 场景ID
goout(Node,Flat,Server_id,Id)->
	gen_server:cast(?MODULE, {goout,Node,Flat,Server_id,Id}).

%%加载god数据
load_god(God_no,Mod)->
	gen_server:cast(?MODULE, {load_god,God_no,Mod}).

%%加载历届前50名
load_god_top50()->
	gen_server:cast(?MODULE, {load_god_top50}).

%%手动选择对手
%% @param Plat 平台
%% @param Server_id 服务器号
%% @param Id 玩家ID
%% @param Plat 平台
%% @param Server_id 服务器号
%% @param Id 玩家ID
select_enemy(Node,Flat,Server_id,Id,B_Flat,B_Server_id,B_Id)->
	gen_server:cast(?MODULE, {select_enemy,Node,Flat,Server_id,Id,B_Flat,B_Server_id,B_Id}).

%%系统匹配对手
%% @param Plat 平台
%% @param Server_id 服务器号
%% @param Id 玩家ID
system_select(Node,Flat,Server_id,Id)->
	gen_server:cast(?MODULE, {system_select,Node,Flat,Server_id,Id}).

%%总决赛系统匹配
sort_match()->
	gen_server:cast(?MODULE, {sort_match}).

%%对阵列表
%% @param Plat 平台
%% @param Server_id 服务器号
%% @param Id 玩家ID
pk_list(Node,Plat,Server_id,Id)->
	gen_server:cast(?MODULE, {pk_list,Node,Plat,Server_id,Id}).

%%向各服发送god_dict
set_god_and_room_dict(Node)->
	gen_server:cast(?MODULE, {set_god_and_room_dict,Node}).
	
%%结束PK
%% @param Plat 平台
%% @param Server_id 服务器号
%% @param Id 玩家ID
%% @param Plat 平台
%% @param Server_id 服务器号
%% @param Id 玩家ID
end_pk(Plat,Server_id,Id,B_Plat,B_Server_id,B_Id,Current_loop)->
	gen_server:cast(?MODULE, {end_pk,Plat,Server_id,Id,B_Plat,B_Server_id,B_Id,Current_loop}).

%%当杀死人的时候(杀人者、被杀者)
when_kill(Plat,Server_id,Id,Plat_killed,Server_id_killed,Id_killed)->
	gen_server:cast(?MODULE, {when_kill,Plat,Server_id,Id,Plat_killed,Server_id_killed,Id_killed}).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
	%%加载历届前50名
	God_top50_dict = load_god_top50(),
    {ok, #god_state{
		god_top50_dict = God_top50_dict			
	}}.

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
handle_call({get_mod_and_status}, _From, State) ->
    Reply = {State#god_state.mod,State#god_state.status},
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
handle_cast(stop, State) ->
	{stop, normal, State};

handle_cast(Msg, State) ->
    case catch mod_god_cast:handle_cast(Msg, State) of
        {noreply, NewState} ->
            {noreply, NewState};
        {stop, Normal, NewState} ->
            {stop, Normal, NewState};
        Reason ->
            util:errlog("mod_god_cast error: ~p, Reason:=~p~n",[Msg, Reason]),
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

