%%------------------------------------------------------------------------------
%% @Module  : mod_monster_siege
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.9.10
%% @Description: 怪物攻城服务
%%------------------------------------------------------------------------------

-module(mod_monster_siege).
-behaviour(gen_fsm).
-include("common.hrl").
-include("boss.hrl").
-include("scene.hrl").

-export([
		start_link/0,          %%
		cmd_restart/0,         %% 重启BOSS服务器秘籍. 
		restart/0,             %% 
		watch/1,               %% 添加监控怪物
		xss/0]).               %% 
		
-export([
		 init/1,               %% 
		 waiting/2,            %% 定时器
         handle_event/3,       %%  
         handle_sync_event/4,  %% 
         handle_info/3,        %% 
         terminate/3,          %% 
         code_change/4]).      %% 

start_link() ->
    gen_fsm:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 重启BOSS服务器秘籍.
cmd_restart() ->
    mod_disperse:cast_to_unite(mod_monster_siege, restart, []).

restart()->
    ?MODULE ! {start}.

xss()->
    ?MODULE ! 'xss'.

%%添加监控怪物
watch(Date) ->
    Pid = whereis(?MODULE),
    Pid ! {'watch', Date}.

%% --------------------------------- 内部函数 ----------------------------------

init([]) ->
	%公共线启动60*2秒后才生成BOSS怪物.
	gen_fsm:send_event_after(?UPDATE_TIMES*2, repeat),
	{ok, waiting, ?MODULE}.

%% 定时器
waiting(_R, _State) ->
	case data_activity_time:get_activity_time(7) of
		true ->
			%% 创建怪物.
			create_mon1(),
			%% 清除怪物.
			clear_mon1();
		false ->
			false
	end, 	
	gen_fsm:send_event_after(?UPDATE_TIMES, repeat),
    {next_state, waiting, _State}.

handle_event({'watch', _Date}, StateName, _State) ->
	gen_fsm:send_event_after(10, repeat),
    {next_state, StateName, _State};
    
handle_event(stop, _StateName, State) ->
    {stop, normal, State}.

handle_sync_event(_Any, _From, StateName, State) ->
    {reply, {error, unhandled}, StateName, State}.

handle_info({start}, StateName, _) ->
    NewState = lib_boss:load(),
	gen_fsm:send_event_after(10, repeat),
    {next_state, StateName, NewState};

handle_info('xss', StateName, _State) ->
	gen_fsm:send_event_after(10, repeat),
    {next_state, StateName, _State};

handle_info({'watch', _Date}, StateName, _State) ->
	gen_fsm:send_event_after(10, repeat),
    {next_state, StateName, _State};
    
handle_info(_Any, StateName, State) ->
    {next_state, StateName, State}.

terminate(_Any, _StateName, _Opts) ->
    ok.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.


%% 创建怪物.
create_mon1() ->
    {Hour,Min,_} = time(),
	case get("create_mon1") of
		1 ->
			skip;
		_Other ->
		    case Hour =:= 16 andalso Min =:= 00 of
		        true ->
					%1.得到世界等级.
		            WorldLevel = 
						case mod_rank:get_average_level() of
			                AverageLevel when is_integer(AverageLevel)-> 
			                    AverageLevel;
							_Other ->
			                    40
			            end,
					
					%2.创建怪物.
                    lib_mon:sync_create_mon(23323, 102, 128, 125, 1, 0, 1, [{auto_lv, WorldLevel}]),
					put("create_mon1", 1);
		        _Skip ->
		            skip
		    end			
	end.

%% 清除怪物.
clear_mon1() ->
    {Hour,Min,_} = time(),
	case get("create_mon1") of
		1 ->
		    case Hour =:= 16 andalso Min =:= 05 of
		        true ->
                    lib_mon:clear_scene_mon_by_mids(102, 0, 1, [23323]),
					put("create_mon1", 0);
		        _Skip ->
		            skip
		    end;
		_Other ->
			skip
			
	end.