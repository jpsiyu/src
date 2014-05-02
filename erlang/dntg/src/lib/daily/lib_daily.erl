%%%-----------------------------------
%%% @Module  : lib_scene
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.05.08
%%% @Description: 每天记录器
%%%-----------------------------------
-module(lib_daily).
-include("daily.hrl").
-export(
    [
        online/1,
        get/2,
        get_all/1,
        get_count/2,
        set_count/3,
        plus_count/3,
		cut_count/3,
        new/1,
        save/1,
        increment/2,
		decrement/2,
        get_task_count/1,
		get_refresh_time/2,		
        set_refresh_time/2,
		set_special_info/2,
		get_special_info/1,
		update_count/4
    ]
).

%% 上线操作
online(RoleId) ->
    reload(RoleId).

%% 获取整个记录器
get(RoleId, Type) ->
    Data = get_all(RoleId),
    lists:keyfind({RoleId, Type}, #ets_daily.id, Data).

%% 取玩家的整个记录
get_all(RoleId) ->
    Data =  get(?DAILY_KEY(RoleId)),
    case Data =:= undefined of
        true ->
            reload(RoleId);
        false ->
            Data
    end.

%% 获取数量
get_count(RoleId, Type) ->
    case lib_daily:get(RoleId, Type) of
        false -> 0;
        RD -> RD#ets_daily.count
    end.

%% 加一操作
increment(RoleId, Type) ->
    plus_count(RoleId, Type, 1).

%% 减一操作
decrement(RoleId, Type) ->
	cut_count(RoleId, Type, 1).

%% 设置数量
set_count(RoleId, Type, Count) ->
    case lib_daily:get(RoleId, Type) of
        false -> save(new([RoleId, Type, Count]));
        RD -> save(RD#ets_daily{count = Count})
    end.

%% 追加数量
plus_count(RoleId, Type, Count) ->
    case lib_daily:get(RoleId, Type) of
        false -> save(new([RoleId, Type, Count]));
        RD -> save(RD#ets_daily{count = RD#ets_daily.count + Count})
    end.

%% 扣除数量
cut_count(RoleId, Type, Count) ->
    case lib_daily:get(RoleId, Type) of
        false -> save(new([RoleId, Type, Count]));
        RD -> save(RD#ets_daily{count = RD#ets_daily.count - Count})
    end.

%% 获取刷新时间
get_refresh_time(RoleId, Type) ->
	case lib_daily:get(RoleId, Type) of
        false -> 0;
        RD -> RD#ets_daily.refresh_time
    end.

%% 更新刷新时间
set_refresh_time(RoleId, Type) ->
    case lib_daily:get(RoleId, Type) of
        false -> save(new([RoleId, Type, 0]));
        RD -> save(RD)
    end.

new([RoleId, Type, Count]) ->  
    #ets_daily{
        id              = {RoleId, Type}
        ,count          = Count 
        ,refresh_time   = 0
    };

new([RoleId, Type]) ->  
    #ets_daily{id = {RoleId, Type}}.

save(RoleDaily) ->
    NowTime = util:unixtime(),
    NewRoleDaily = RoleDaily#ets_daily{ refresh_time=NowTime },
    {RoleId, Type} = NewRoleDaily#ets_daily.id,
    Data = get_all(RoleId),
    Data1 = lists:keydelete(NewRoleDaily#ets_daily.id, #ets_daily.id, Data) ++ [NewRoleDaily],
    put(?DAILY_KEY(RoleId), Data1),
    db:execute(io_lib:format(?sql_daily_role_upd, [RoleId, Type, NewRoleDaily#ets_daily.count, NowTime])).

%% 所有数据重载
reload(RoleId) ->
    erase(?DAILY_KEY(RoleId)),
    List = db:get_all(io_lib:format(?sql_daily_role_sel_all, [RoleId])),
    D = to_dict(List, []),
    put(?DAILY_KEY(RoleId), D),
    D.

%% 获取特殊数据：针对个人的数据，但不入库，只保存在进程中
get_special_info(Key) ->
	get(Key).

%% 设置特殊数据：针对个人的数据，但不入库，只保存在进程中
set_special_info(Key, Value) ->
	put(Key, Value).

to_dict([], D) ->
    D;
to_dict([[RoleId, Type, Count, Time] | T], D) ->
    to_dict(T, D ++ [#ets_daily{
            id              = {RoleId, Type}
            ,count          = Count
            ,refresh_time   = Time
        }]).

%% 获取皇榜任务和平乱任务次数
get_task_count(RoleId) ->
    {get_count(RoleId, 5000010), get_count(RoleId, 5000020)}.

%% 直接操作数据库，适合在玩家不在线的时候调用
update_count(RoleId, Type, Count, Time) ->
	db:execute(io_lib:format(?sql_daily_role_upd, [RoleId, Type, Count, Time])).
