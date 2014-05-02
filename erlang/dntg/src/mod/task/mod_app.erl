%% --------------------------------------------------------
%% @Module:           |mod_app
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-00-00
%% @Description:      |仙侣情缘服务
%% -------------------------------------------------------- 
-module(mod_app).
-behaviour(gen_fsm).
-export([
		 insert_location/2	 					%% 添加玩家区域记录
		, get_location_filter/1					%% 获取同城玩家
		, insert_one/1	 	 					%% 添加一个仙侣志愿者
		, remove_one/1	 	 					%% 删除一个仙侣志愿者
		, start_one_xlqy/3 						%% 开始一段仙侣情缘
		, get_xlqy/1	 	 					%% 获取仙侣状态
		, private_get_xlqy/3					%% 开始一段仙侣情缘
		, end_one_xlqy/2 						%% 结束一段仙侣情缘
		, remove_two/2	 	 					%% 移除仙侣双方
		, get_one/1								%% 查找一个伴侣
		]).
-export([start_link/0, init/1, handle_event/3, handle_sync_event/4,handle_info/3, terminate/3, code_change/4, waiting/2]).

-include("appointment.hrl").
-include("common.hrl").
-define(APPBASE, "AppBase"). 	 	 							%% 基础数据
-define(LOCATION, "Location"). 	 	 							%% 玩家地域
-define(CLEAR_TIME, 30 * 60 * 1000). 	 	 					%% 30分钟执行一次(没人做仙侣任务的时候)
-define(CLEAR_TIME_BUSY, 1 * 60 * 1000). 	 	 				%% 1分钟执行一次(有人做仙侣任务的时候)

%% 启动进程
start_link() ->
    gen_fsm:start_link({global,?MODULE}, ?MODULE, [], []).

%% @Status 一个Key 为怪物唯一ID Value 为制定清除的时间 的字典 
init([])->
	%% 仙侣基本字典
	AppBase = dict:new(),
	put(?APPBASE, AppBase),
	put(?LOCATION, AppBase),
    {ok, waiting, [], ?CLEAR_TIME}.

%% --------------------------------------------------------------------------
%% 状态函数
%% --------------------------------------------------------------------------

waiting(timeout, Status) ->
%% 	NowTime = util:unixtime(),
	{next_state, waiting, Status, ?CLEAR_TIME}.

%% --------------------------------------------------------------------------
%% 接口函数
%% --------------------------------------------------------------------------

%% 记录玩家登陆区域
insert_location(RoleId, Location) when erlang:is_integer(RoleId) ->
	make_cast({insert_location, [RoleId, Location]}).

%% 获取同城玩家
get_location_filter(RoleId) ->
	make_call({get_location_filter, [RoleId]}).

%% 添加一个仙侣志愿者 
insert_one([RoleId, Sex]) ->
	make_cast({insert_one, [RoleId, Sex]}).

%% 删除一个仙侣志愿者
remove_one(RoleId) ->
	make_cast({remove_one, RoleId}).

%% 开始一段仙侣
%% 类型  
%% 		0 -> 错误类型,不处理
%%		1 -> 默认类型,只有 RoleIdA 完成任务
%% 		2 -> 匹配类型,RoleIdA, RoleIdB 都完成任务
start_one_xlqy(RoleIdA, RoleIdB, Type) ->
	case Type =:= 0 of
		true ->
			skip;
		false ->
			make_cast({start_one_xlqy, [RoleIdA, RoleIdB, Type]})
	end.

%% 结束一段仙侣
end_one_xlqy(RoleIdA, RoleIdB) ->
	make_cast({end_one_xlqy, [RoleIdA, RoleIdB]}).

%% 移除仙侣双方
remove_two(RoleIdA, RoleIdB) ->
	make_cast({remove_two, [RoleIdA, RoleIdB]}).

%% 找到一个仙侣情缘伴侣(同步事件)
get_one(Sex) ->
	make_call({get_one, Sex}).

%% 获取个人仙侣情缘信息

get_xlqy(PlayerId) ->
	make_call({get_xlqy, PlayerId}).

%% %% 回写仙侣时间
%% save_xlqy_exp_time() ->
%% 	1.

%% --------------------------------------------------------------------------
%% 回调函数
%% --------------------------------------------------------------------------

%% 记录玩家登陆区域
handle_event({insert_location, [RoleId, Location]}, StateName, Status) ->
	case get(?LOCATION) of
		undefined ->
			LB = dict:new(),
			put(?LOCATION, dict:store(RoleId, Location, LB));
		Value ->
			put(?LOCATION, dict:store(RoleId, Location, Value))
	end,
    {next_state, StateName, Status, 0};
%% 添加一个仙侣志愿者
handle_event({insert_one, [RoleId, Sex]}, StateName, Status) ->
	NewStatus = case lists:keyfind(RoleId, 1, Status) of
		false ->
			[{RoleId, Sex}|Status];
		{_RoleId, _Sex} ->
			Status
	end,
    {next_state, StateName, NewStatus, 0};
%% 删除一个仙侣志愿者
handle_event({remove_one, RoleId}, StateName, Status) ->
	NewStatus = lists:keydelete(RoleId, 1, Status),
    {next_state, StateName, NewStatus, 0};
%% 移除仙侣双方(从志愿者目录移除)
handle_event({remove_two, [RoleIdA, RoleIdB]}, StateName, Status) ->
	NewStatus1 = lists:keydelete(RoleIdA, 1, Status),
	NewStatus2 = lists:keydelete(RoleIdB, 1, NewStatus1),
    {next_state, StateName, NewStatus2, 0};
%% 开始一段仙侣
handle_event({start_one_xlqy, [RoleIdA, RoleIdB, Type]}, StateName, Status) ->
	private_start_one_xlqy(RoleIdA, RoleIdB, Type),
    {next_state, StateName, Status, 0};
%% 结束一段仙侣
handle_event({end_one_xlqy, [RoleIdA, RoleIdB]}, StateName, Status) ->
	private_end_one_xlqy(RoleIdA, RoleIdB),
    {next_state, StateName, Status, 0};

%% 默认匹配(异步事件)
handle_event(_Event, StateName, Status) ->
    {next_state, StateName, Status, 0}.


%% --------------------------------------------------------------------------
%% 同步事件
%% --------------------------------------------------------------------------
%% 返回LIST,[]就是找不到
handle_sync_event({get_one, Sex}, _From, StateName, Status) ->
	{Res, NewStatus} = case lists:keyfind(Sex, 2, Status) of
		false ->
			{[], Status};
		{RoleId, Sex} ->
			case lists:keytake(RoleId, 1, Status) of
				{value, _Tuple, TupleList2} ->
					{[RoleId], TupleList2};
				false ->
					{[], Status}
			end
	end,
    {reply, Res, StateName, NewStatus, 0};
%% 获取同城匹配玩家
handle_sync_event({get_location_filter, [RoleId]}, _From, StateName, Status) ->
	Res = case get(?LOCATION) of
		undefined ->
			[];
		Value ->
			case dict:find(RoleId, Value) of
				{ok, SelfLocation} ->
					D = dict:to_list(dict:filter(fun(_, Location) -> Location =:= SelfLocation end, Value)),
					[Id||{Id, _} <- D,  Id =/= RoleId];
				error ->
					[]
			end
	end,
    {reply, Res, StateName, Status, 0};
%% 开始一段仙侣情缘
handle_sync_event({start_one_xlqy, [RoleIdA, RoleIdB, Type]}, _From, StateName, Status) ->
	Res = private_start_one_xlqy(RoleIdA, RoleIdB, Type),
    {reply, Res, StateName, Status, 0};
%% 获取一个仙侣伴侣
handle_sync_event({get_xlqy, RoleId}, _From, StateName, Status) ->
	Res = private_get_xlqy(RoleId),
    {reply, Res, StateName, Status, 0};

%% 默认匹配(同步事件)
handle_sync_event(_Event, _From, StateName, Status) ->
    {reply, ok, StateName, Status}.


%% --------------------------------------------------------------------------
%% 功能函数(内部处理)
%% --------------------------------------------------------------------------

%% 开始一段仙侣
private_start_one_xlqy(RoleIdA, RoleIdB, _Type)->
	case get(?APPBASE) of
		undefined ->
			[];
		AppBase ->
			case dict:find({RoleIdA, RoleIdB}, AppBase) of
				{ok, _Value} ->
					[];
				error ->
					NowTime = util:unixtime(),
% step => 0:初始状态 1:已经邀请了(未送礼) 2:送礼后 3:小游戏中 4:约会中 5:评价对方中 8:已完成未交任务
					RCAPPNew = #rc_xlqy{begin_time = NowTime
									  , last_exp_time = NowTime
									  , step = 2				
									  , gamestate = 0
								   },
					NewAppBase = dict:store({RoleIdA, RoleIdB}, RCAPPNew, AppBase),
					put(?APPBASE, NewAppBase)
			end
	end.

%% 获取仙侣情缘信息
private_get_xlqy(RoleId) ->
	%% 获取进程字典内容
	AppBase = case get(?APPBASE) of
		undefined ->
			dict:new();
		Value ->
			Value
	end,
	DictFiltered = dict:filter(fun({RoleIdA, RoleIdB}, _ValueS) -> RoleIdA =:= RoleId orelse RoleIdB =:= RoleId end, AppBase),
	case dict:to_list(DictFiltered) of
		[{{RoleIdAR, RoleIdBR}, RCXLQY}] ->
			PartnerId = case RoleId =:= RoleIdAR of
					true ->
						RoleIdBR;
					false ->
						RoleIdAR
			end,
			[PartnerId, RCXLQY];
		_ ->
			false
	end.

%% 仙侣情缘NewStep
private_get_xlqy(RoleId, OldStep, NewStep) ->
	%% 获取进程字典内容
	AppBase = case get(?APPBASE) of
		undefined ->
			dict:new();
		Value ->
			Value
	end,
	DictFiltered = dict:filter(fun({RoleIdAF, RoleIdBF}, _ValueS) -> RoleIdAF =:= RoleId orelse RoleIdBF =:= RoleId end, AppBase),
	case dict:to_list(DictFiltered) of
		[{{RoleIdA, RoleIdB}, RCXLQY}] ->
			case RCXLQY#rc_xlqy.step =:= OldStep of
				false ->%% 失败
					false;
				true -> %% 存入新状态
					RCXLQYNew = RCXLQY#rc_xlqy{step = NewStep},
					NewAppBase = dict:store({RoleIdA, RoleIdB}, RCXLQYNew, AppBase),
					put(?APPBASE, NewAppBase),
					ok
			end;
		_ ->
			false
	end.









%% 结束一段仙侣
private_end_one_xlqy(RoleIdA, RoleIdB)->
	case get(?APPBASE) of
		undefined ->
			[];
		AppBase ->
			_AppBase2 = dict:erase({RoleIdA, RoleIdB}, AppBase)
	end.


	
















































%% 异步调用
make_cast(Info)->
	case misc:whereis_name(global, ?MODULE) of
		Pid when is_pid(Pid) ->
			gen_fsm:send_all_state_event(Pid, Info);
		_ ->
			skip
	end.

%% 同步调用
make_call(Info)->
	case misc:whereis_name(global, ?MODULE) of
		Pid when is_pid(Pid) ->
			gen_fsm:sync_send_all_state_event(Pid, Info, 5000);
		_r ->
			[]
	end.


%% --------------------------------------------------------------------------
%% 回调函数(未使用的)-----OVER
%% --------------------------------------------------------------------------

handle_info(stop, _StateName, Status) ->
    {stop, normal, Status};
handle_info(_Info, StateName, Status) ->
    {next_state, StateName, Status}.

terminate(_Reason, _StateName, _Status) ->
    ok.

code_change(_OldVsn, StateName, Status, _Extra) ->
    {ok, StateName, Status}.