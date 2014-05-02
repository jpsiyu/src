%%------------------------------------------------------------------------------
%% @Module  : mod_dungeon_agent
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.7.23
%% @Description: 副本管理
%%------------------------------------------------------------------------------

-module(mod_dungeon_agent).
-behaviour(gen_server).
-include("dungeon.hrl").

-export([start_link/0, stop/0, init/1, 
		 handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([
         set_dungeon_record/1,             %% 设置副本记录.
		 set_dungeon_record_scene_id/2,    %% 设置副本记录的场景ID.
		 set_multi_king_master/3,          %% 设置多人塔防副本霸主.		 
         set_dungeon_end_time/2,           %% 设置副本记录结束时间.
		 set_dungeon_scene/2,              %% 设置副本记录场景.
	     set_dungeon_log/2,                %% 设置副本日志.
		 set_dungeon_time/2,               %% 设置上次副本时间.		 
		 get_dungeon_record/1,             %% 获取副本记录.
         get_dungeon_log/1,                %% 获取副本日志.
		 get_dungeon_time/1,               %% 获取上次副本时间.
         get_mutil_king_rank/0             %% 获取多人塔防副本霸主.
]).


%% --------------------------------- 公共函数 ----------------------------------


%% 启动服务器
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

%% 停止服务器
stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

%% 设置副本记录.
set_dungeon_record(DungeonRecrod)->
	gen_server:cast(misc:get_global_pid(?MODULE),{'set_dungeon_record', DungeonRecrod}).

%% 设置副本记录的场景ID.
set_dungeon_record_scene_id(PlayerId, SceneId)->
	gen_server:cast(misc:get_global_pid(?MODULE),{'set_dungeon_record_scene_id', PlayerId, SceneId}).

%% 设置多人塔防副本霸主.
set_multi_king_master(PlayerIdList, Level, Time)->
	gen_server:cast(misc:get_global_pid(?MODULE),{'set_multi_king_master', PlayerIdList, Level, Time}).

%% 设置副本记录结束时间.
set_dungeon_end_time(PlayerId, EndTime)->
	gen_server:call(misc:get_global_pid(?MODULE),{'set_dungeon_end_time', PlayerId, EndTime}).

%% 设置副本记录场景.
set_dungeon_scene(PlayerId, SceneId)->
	gen_server:call(misc:get_global_pid(?MODULE),{'set_dungeon_scene', PlayerId, SceneId}).

%% 设置副本日志.
set_dungeon_log(PlayerId, DungeonLog)->
	gen_server:call(misc:get_global_pid(?MODULE),{'set_dungeon_log', PlayerId, DungeonLog}).

%% 设置上次副本时间.
set_dungeon_time(PlayerId, DungeonTime)->
	gen_server:call(misc:get_global_pid(?MODULE),{'set_dungeon_time', PlayerId, DungeonTime}).

%% 获取副本记录.
get_dungeon_record(PlayerId)->
	gen_server:call(misc:get_global_pid(?MODULE),{'get_dungeon_record', PlayerId}).

%% 获取副本日志.
get_dungeon_log(PlayerId)->
	gen_server:call(misc:get_global_pid(?MODULE),{'get_dungeon_log', PlayerId}).

%% 获取上次副本时间.
get_dungeon_time(PlayerId)->
	gen_server:call(misc:get_global_pid(?MODULE),{'get_dungeon_time', PlayerId}).

%% 获取多人塔防副本霸主.
get_mutil_king_rank()->
	gen_server:call(misc:get_global_pid(?MODULE),'get_mutil_king_rank').

%% --------------------------------- 内部函数 ----------------------------------


%% 启动服务器.
init([]) ->
	erlang:send_after(30 * 1000, self(), 'check_dungeon_alive'),
	lib_multi_king_master:load_master(),
    {ok, ?MODULE}.

%% 获取副本记录.
handle_call({'get_dungeon_record',PlayerId}, _From, State) ->
	 case get(PlayerId) of
		 undefined ->
		     {reply, [], State};
		 DungeonRecrod ->
		     {reply, [DungeonRecrod], State}
     end;

%% 设置上次副本时间.
handle_call({'set_dungeon_time', PlayerId, Time}, _From, State) ->
	DunTimerKey = lists:concat(["dungeon_time", PlayerId]),
	put(DunTimerKey, Time),
    {reply, 0, State};

%% 获取上次副本时间.
handle_call({'get_dungeon_time',PlayerId}, _From, State) ->
	DunTimerKey = lists:concat(["dungeon_time",PlayerId]),
	 case get(DunTimerKey) of
		 undefined ->
		     {reply, [], State};
		 DungeonTime ->
		     {reply, [DungeonTime], State}
     end;

%% 设置副本日志.
handle_call({'set_dungeon_log', PlayerId, DungeonLog}, _From, State) ->
	DunLogKey = lists:concat(["dungeon_log", PlayerId]),
	put(DunLogKey, DungeonLog),
    {reply, 0, State};

%% 获取副本日志.
handle_call({'get_dungeon_log',PlayerId}, _From, State) ->
	DunLogKey = lists:concat(["dungeon_log",PlayerId]),
	 case get(DunLogKey) of
		 undefined ->
		     {reply, [], State};
		 DungeonLog ->
		     {reply, [DungeonLog], State}
     end;

%% 获取多人塔防副本霸主.
handle_call('get_mutil_king_rank', _From, State) ->
	MasterList = lib_multi_king_master:get_rank_master(),
	{reply, MasterList, State};

%% 默认匹配
handle_call(Event, _From, State) ->
    catch util:errlog("mod_dungeon_agent:handle_call not match: ~p", [Event]),
    {reply, ok, State}.

%% 设置副本记录.
handle_cast({'set_dungeon_record', DungeonRecrod}, State) ->
	put(DungeonRecrod#dungeon_record.player_id, DungeonRecrod),
    {noreply, State};

%% 设置副本记录的场景ID.
handle_cast({'set_dungeon_record_scene_id', PlayerId, SceneId}, State) ->
	 case get(PlayerId) of
		 DungeonRecrod when is_record(DungeonRecrod, dungeon_record) ->
			 put(PlayerId, DungeonRecrod#dungeon_record{scene_id = SceneId});
		 _Other ->
		     skip
     end,
    {noreply, State};

%% 设置多人塔防副本霸主.
handle_cast({'set_multi_king_master', PlayerIdList, Level, Time}, State) ->
	lib_multi_king_master:set_master(PlayerIdList, Level, Time),
    {noreply, State};

%% 删除副本记录.
handle_cast({'del_dungeon_record', PlayerId}, State) ->
    case get(PlayerId) of
         undefined ->
             [];
         _DungeonRecrod ->             
             erase(PlayerId)
	end,
	{noreply, State};

%% 默认匹配
handle_cast(Event, State) ->
    catch util:errlog("mod_dungeon_agent:handle_cast not match: ~p", [Event]),
    {noreply, State}.

%% 检测副本是否活着.
handle_info('check_dungeon_alive', State) ->

	%1.5分钟检测一次.
	erlang:send_after(5* 60 * 1000, self(), 'check_dungeon_alive'),
	
	%2.定义检测副本存活函数.
	FunCheckAlive = 
		fun(DungeonRecrod) ->
				DunPid = DungeonRecrod#dungeon_record.dungeon_pid,
				PlayerId = DungeonRecrod#dungeon_record.player_id,
			case is_pid(DunPid) andalso 
					 misc:is_process_alive(DunPid) of
			    true ->
					Time = util:unixtime(),
           			case Time - DungeonRecrod#dungeon_record.end_time >= 60 of
						true ->
							%lib_dungeon:quit(DunPid, PlayerId),
    						%lib_dungeon:clear(role, DunPid),
							gen_server:cast(DunPid, 'close_dungeon'),
                            %exit(DunPid, kill),
							erase(PlayerId);
						false ->
							skip
					end;			   
			    false ->
					erase(PlayerId)
			end
		end, 

	%3.检测所有副本.
    AllRecord = get(),
   	[FunCheckAlive(DunRecord) || {Key, DunRecord} <- AllRecord, is_integer(Key)],

	{noreply, State};

%% 默认匹配
handle_info(Info, State) ->
    catch util:errlog("mod_dungeon_agent:handle_info not match: ~p", [Info]),
    {noreply, State}.

%% 服务器停止.
terminate(_R, _State) ->
    ok.

%% 热代码替换.
code_change(_OldVsn, State, _Extra)->
    {ok, State}.
