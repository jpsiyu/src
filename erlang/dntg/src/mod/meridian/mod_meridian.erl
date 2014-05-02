%%% -------------------------------------------------------------------
%%% Author  : zengzhaoyuan
%%% Description :
%%%
%%% Created : 2012-3-15
%%% -------------------------------------------------------------------
-module(mod_meridian).
-behaviour(gen_server).
-include("meridian.hrl").
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([start/1,stop/1,getPlayer_meridian/1,upMer/3,upGen/3,getMers/3,clearCD/2,count_meridian_attribute/1, count_meridian_base_attribute/1,tupo/4]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================
%% 启动方法
%% @param Uid 玩家ID
start(Uid) -> gen_server:start_link(?MODULE, [Uid], []).
%%停止进程
stop(Pid) ->
	case is_pid(Pid) andalso is_process_alive(Pid) of
		true -> gen_server:cast(Pid, stop);
		false -> skip
	end.

%% ====================================================================
%% Server functions
%% ====================================================================
%%获取状态
getPlayer_meridian(Pid)->
	case misc:is_process_alive(Pid) of
		false->#player_meridian{};
		true->gen_server:call(Pid,{getPlayer_meridian})
	end.
%%升级经脉
upMer(Pid,PlayerStatus, [MeridianId])
  when MeridianId >=1 andalso MeridianId =<10
      ->gen_server:call(Pid,{upMer,PlayerStatus, [MeridianId]}).
%%升级根骨
upGen(Pid,PlayerStatus, [MeridianId,IsUse,IsBuy])
   when MeridianId >=1 andalso MeridianId =<10
        andalso (IsUse=:=0 orelse IsUse=:=1)
        andalso (IsBuy=:=0 orelse IsBuy=:=1)->gen_server:call(Pid,{upGen,PlayerStatus, [MeridianId,IsUse,IsBuy]}).
%%查询经脉信息
getMers(Pid,PlayerStatus, [Uid,Mid])when Mid>=0 andalso Mid=<10->gen_server:call(Pid,{getMers,PlayerStatus, [Uid,Mid]}).

%%清空CD时间
clearCD(Pid,PlayerStatus)->gen_server:call(Pid,{clearCD,PlayerStatus}).

%%突破
%%@param PlayerStatus
%%@param MeridianId 经脉类型
%%@param IsBuy 是否自动购买
tupo(Pid,PlayerStatus,MeridianId,IsBuy)
  when MeridianId >=1 andalso MeridianId =<10
        andalso (IsBuy=:=0 orelse IsBuy=:=1)->gen_server:call(Pid,{tupo,PlayerStatus,MeridianId,IsBuy}).

%%计算经脉系统附加属性
%% @param MerPid 经脉Pid
%% @return [气血，....，毒抗]  具体顺序请看客户端界面顺序，从上到下，左到右
count_meridian_attribute(MerPid)->
	Player_meridian = mod_meridian:getPlayer_meridian(MerPid),
    {_Type,[{Mer_Hp3,Gen_Hp3}, {Mer_Mp3,Gen_Mp3}, {Mer_Def3,Gen_Def3}, {Mer_Hit3,Gen_Hit3}, {Mer_Dodge3,Gen_Dodge3}, 
			  {Mer_Ten3,Gen_Ten3},{Mer_Crit3,Gen_Crit3}, {Mer_Att3,Gen_Att3}, {Mer_Fire3,Gen_Fire3}, 
			  {Mer_Ice3,Gen_Ice3}, {Mer_Drug3,Gen_Drug3}]} = lib_meridian:count_attr(Player_meridian),
	[Mer_Hp3+Gen_Hp3, Mer_Mp3+Gen_Mp3, Mer_Def3+Gen_Def3, Mer_Hit3+Gen_Hit3, 
     Mer_Dodge3+Gen_Dodge3,Mer_Ten3+Gen_Ten3,Mer_Crit3+Gen_Crit3, Mer_Att3+Gen_Att3, 
	 Mer_Fire3+Gen_Fire3,Mer_Ice3+Gen_Ice3, Mer_Drug3+Gen_Drug3].

%% 添加基础属性
%% @param MerPid 经脉Pid
%% return [力量、体制、灵力、身法]
count_meridian_base_attribute(MerPid)->
	Player_meridian = mod_meridian:getPlayer_meridian(MerPid),
    lib_meridian:count_base_attr(Player_meridian).


%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([Uid]) ->
	Player_meridian = lib_meridian:load(Uid),
    {ok, Player_meridian}.

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
handle_call(Request, From, State) ->
    mod_meridian_call:handle_call(Request, From, State).

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
%%停止游戏进程
handle_cast(stop, State) ->
    {stop, normal, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

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

