%%%------------------------------------
%%% @Module  : mod_daily_dict
%%% @Author  : 
%%% @Created : 2010.09.26
%%% @Description: 每天记录器(只保存缓存,不会写入数据库)
%%%------------------------------------

%% 沙滩：恶搞次数------------1021
%% 沙滩：示好次数------------1022
%% 沙滩：第一次恶搞------------1023
%% 沙滩：第一次示好------------1024
%% 限时名人堂（活动）：铜币获得次数------------1040
%% 限时名人堂（活动）：经验获得次数------------1041
%% 限时名人堂（活动）：历练获得次数------------1042
%% 名人堂：名人堂版本------------1050

%% 更新跨服排行榜数据--------------------------8900


%% 开服七天登录礼包兼容标识：------------1111
%% 玩家已送出花灯祝福--------------------2001

-module(mod_daily_dict).
-export([
	start_link/0,
	set_special_info/2,
	get_special_info/1,
	get_special_multi/1,
	get/2,
	get_all/1,
	get_count/2,
	get_count_multi/2,
	set_count/3,
	plus_count/3,
	cut_count/3,
	new/1,
	save/1,
	increment/2,
	decrement/2,
	daily_clear/0,
	get_task_count/1,
	get_refresh_time/2,		
	set_refresh_time/2,
	get_room/2
]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% 设置特殊值(无判断)
set_special_info(Key, Value) ->
	gen_server:call(misc:get_global_pid(?MODULE), {set_special_info, [Key, Value]}).

%% 获取特殊值(无判断)
get_special_info(Key) ->
	gen_server:call(misc:get_global_pid(?MODULE), {get_special_info, [Key]}).

%% 获取房间人数
get_room(Type, Scene) ->
	gen_server:call(misc:get_global_pid(?MODULE), {get_room, [Type, Scene]}).

%% 批量获取特殊值(无判断)
%% 返回 : [{Key, Value}, ...]
get_special_multi(KeyList) ->
	gen_server:call(misc:get_global_pid(?MODULE), {get_special_multi, [KeyList]}).

%% 获取整个记录器
get(RoleId, Type) ->
    gen_server:call(misc:get_global_pid(?MODULE), {get, [RoleId, Type]}).

%% 取玩家的整个记录
get_all(RoleId) ->
    gen_server:call(misc:get_global_pid(?MODULE), {get_all, [RoleId]}).

%% 获取数量
get_count(RoleId, Type) ->
    gen_server:call(misc:get_global_pid(?MODULE), {get_count, [RoleId, Type]}).

%% 获取数量(多个日常ID)(返回对应的计数器数量列表)
get_count_multi(RoleId, TypeIdList) ->
    gen_server:call(misc:get_global_pid(?MODULE), {get_count_multi, [RoleId, TypeIdList]}).

%% 加一操作
increment(RoleId, Type) ->
    plus_count(RoleId, Type, 1).

%% 减一操作
decrement(RoleId, Type) ->
    cut_count(RoleId, Type, 1).

%% 设置数量
set_count(RoleId, Type, Count) ->
    gen_server:call(misc:get_global_pid(?MODULE), {set_count, [RoleId, Type, Count]}).

%% 获取刷新时间
get_refresh_time(RoleId, Type) ->
	gen_server:call(misc:get_global_pid(?MODULE), {get_refresh_time, [RoleId, Type]}).
   
%% 更新刷新时间
set_refresh_time(RoleId, Type) ->
	gen_server:call(misc:get_global_pid(?MODULE), {set_refresh_time, [RoleId, Type]}).

%% 追加数量
plus_count(RoleId, Type, Count) ->
    gen_server:call(misc:get_global_pid(?MODULE), {plus_count, [RoleId, Type, Count]}).

%% 扣除数量
cut_count(RoleId, Type, Count) ->
    gen_server:call(misc:get_global_pid(?MODULE), {cut_count, [RoleId, Type, Count]}).

new([RoleId, Type, Count]) ->  
    gen_server:call(misc:get_global_pid(?MODULE), {new, [[RoleId, Type, Count]]});

new([RoleId, Type]) ->  
    gen_server:call(misc:get_global_pid(?MODULE), {new, [[RoleId, Type]]}).

save(RoleDaily) ->
    gen_server:call(misc:get_global_pid(?MODULE), {save, [RoleDaily]}).

%% 获取皇榜任务和平乱任务次数
get_task_count(RoleId) ->
    gen_server:call(misc:get_global_pid(?MODULE), {get_task_count, [RoleId]}).
   
%% 每天数据清除
daily_clear() ->
    gen_server:cast(misc:get_global_pid(?MODULE), {daily_clear, []}).

start_link() ->
    gen_server:start_link({global,?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    {ok, ?MODULE}.

%% cast数据调用
handle_cast({Fun, Arg}, Status) ->
    apply(lib_daily_dict, Fun, Arg),
    {noreply, Status};

handle_cast(_R , Status) ->
    {noreply, Status}.

%% call数据调用
handle_call({Fun, Arg} , _FROM, Status) ->
    {reply, apply(lib_daily_dict, Fun, Arg), Status};

handle_call(_R , _FROM, Status) ->
    {reply, ok, Status}.

handle_info(_Reason, Status) ->
    {noreply, Status}.

terminate(_Reason, Status) ->
    {ok, Status}.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.
