%%------------------------------------------------------------------------------
%% @Module  : mod_boss
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.6.20
%% @Description: BOSS系统服务
%%------------------------------------------------------------------------------

-module(mod_boss).
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
    mod_disperse:cast_to_unite(mod_boss, restart, []).

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
    State = lib_boss:load(),

	%公共线启动40*2秒后才生成BOSS怪物.
	gen_fsm:send_event_after(?UPDATE_TIMES*2, repeat),
    {ok, waiting, State}.

%% 定时器
waiting(_R, _State) ->
    {Hour,Min,_} = time(),
	
	%1.重新载入BOSS数据使用（1347786752=2012年9月16日17:14）.
    State = case Hour =:= 22 andalso (Min >= 30  andalso Min =< 50) andalso 
					 util:unixtime() < 1347786752 of
        true ->
%%             F = fun(SceneId) ->
%%                 lib_boss:kill_scene_mon(SceneId)
%%             end,
%%             catch lists:foreach(F, [982, 981, 996]),
            %重载数据
            lib_boss:load();
        _ ->
            _State
    end,
	
	%2.生成怪物.
    NewMonitems = lib_boss:check_all(State#boss_state.monitems),	
    NewState = State#boss_state{monitems=NewMonitems},
	gen_fsm:send_event_after(?UPDATE_TIMES, repeat),
    {next_state, waiting, NewState}.

handle_event({'watch', Date}, StateName, Status) ->
    [Monid, LivingTime] = Date,
    Now = util:unixtime(),
    Boss = #monitem{
        id = util:rand(1, 9999999999),
        living_time = LivingTime,

        mon_id = Monid,
        mon_type = 1,
        mon_born_time= Now
    },
    NewList = Status#boss_state.monitems ++ [Boss],
    NewState = Status#boss_state{monitems=NewList},
	gen_fsm:send_event_after(10, repeat),
    {next_state, StateName, NewState};
    
handle_event(stop, _StateName, State) ->
    {stop, normal, State}.

handle_sync_event(_Any, _From, StateName, State) ->
    {reply, {error, unhandled}, StateName, State}.

handle_info({start}, StateName, _) ->
    NewState = lib_boss:load(),
	gen_fsm:send_event_after(10, repeat),
    {next_state, StateName, NewState};

handle_info('xss', StateName, _State) ->
    Now = util:unixtime(),

    %1.杀死所有Boss怪物
    FunKillAllBoss = fun(Monitem1) ->
		Th = util:rand(1, length(Monitem1#monitem.refresh_place)),
        {Scene, _X, _Y} = lists:nth(Th, Monitem1#monitem.refresh_place),
        lib_mon:clear_scene_mon_by_mids(Scene, 0, 1, [Monitem1#monitem.mon_id])
    end,
    lists:map(FunKillAllBoss, _State#boss_state.monitems),
	
    %2.重导配置
    State = lib_boss:load(),
    Monitems =  State#boss_state.monitems,
    FunCreateBoss = fun(Monitem) ->
            Th = util:rand(1, length(Monitem#monitem.refresh_place)),			
            {Scene, X, Y} = lists:nth(Th, Monitem#monitem.refresh_place),
            BOSS_ID = lib_boss:get_boss_type(Monitem#monitem.boss_id, Monitem#monitem.boss_rate),
            _Mon_id =
				case Monitem#monitem.boss_id of
					%% 刷新黄眉老佛专用.
					40005 ->								
						lib_boss:create_mon2(Monitem#monitem.boss_id, BOSS_ID, [404,405,406], Monitem#monitem.active);
					%% 刷新白骨精专用.
					40040 ->								
						lib_boss:create_mon2(Monitem#monitem.boss_id, BOSS_ID, [402,410,411], Monitem#monitem.active);
					%% 刷新赤鬼王专用.
					40050 ->
						lib_boss:create_mon2(Monitem#monitem.boss_id, BOSS_ID, [403,408,409], Monitem#monitem.active);
					_Other ->
						lib_boss:create_mon([BOSS_ID, Scene, X, Y, Monitem#monitem.active])
				end,			
			lib_boss:add_log(BOSS_ID, Scene),
            case Monitem#monitem.notice > 0 of
                true ->
                    spawn(fun()->
                            lib_boss:send_notice(Scene, X, Y, Monitem, BOSS_ID,1)
                    end);
                _ ->
                    ok
            end,
            Monitem#monitem{
                        mon_id=BOSS_ID,
                        mon_born_time=Now,
                        mon_die_time=0,
                        mon_check_time=Now}
    end,
    NewMonitems = lists:map(FunCreateBoss, Monitems),
	
    NewState = State#boss_state{monitems = NewMonitems},
    {next_state, StateName, NewState};

handle_info({'watch', Date}, StateName, Status) ->
    [Monid, LivingTime, Scene, X, Y] = Date,
    Now = util:unixtime(),
    Boss = #monitem{
        id = util:rand(1, 9999999999),
        living_time = LivingTime,

        mon_id = Monid,
        mon_type = 1,
        mon_born_time= Now,
		refresh_place= [{Scene, X, Y}]
    },
	
    NewList = Status#boss_state.monitems ++ [Boss],
    NewState = Status#boss_state{monitems=NewList},
	gen_fsm:send_event_after(10, repeat),
    {next_state, StateName, NewState};
    
handle_info(_Any, StateName, State) ->
    {next_state, StateName, State}.

terminate(_Any, _StateName, _Opts) ->
    ok.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.

