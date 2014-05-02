%%%-----------------------------------
%%% @Module  : lib_daily_dict
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.05.08
%%% @Description: 每天记录器(只保存缓存,不会写入数据库, 玩家下线不会清除缓存, 只在每日清除)
%%%-----------------------------------
-module(lib_daily_dict).
-include("daily.hrl").
-export(
    [
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
		get_refresh_time/2,		
        set_refresh_time/2,
		get_room/2
    ]
).

%% 设置特殊值(无判断)
set_special_info(Key, Value) ->
	put(Key, Value).

%% 获取特殊值(无判断)
get_special_info(Key) ->
	get(Key).

%% 获取房间人数,返回房间列表[{Id, Num}]
%% Type:房间类型 wubianhai
get_room(Type, SceneId) ->
    Time = util:unixtime(),
    case get(Type) of
        undefined ->
            Room = mod_chat_agent:get_scene_room_num(SceneId),
            put(Type, {Room, Time}),
            Room;
        {Romm1, Time1} ->
            case Time - Time1 < 20 of
                true ->
                    Romm1;
                false ->
                    Room2= mod_chat_agent:get_scene_room_num(SceneId),
                    put(Type, {Room2, Time}),
                    Room2
            end
    end.

%% 批量获取特殊值(无判断)
get_special_multi(KeyList) ->
	lists:map(fun(Key) -> 
		{Key, get(Key)}
	end, KeyList).

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
    case lib_daily_dict:get(RoleId, Type) of
        false -> 0;
        RD -> RD#ets_daily.count
    end.

%% 获取数量(多个类型)
get_count_multi(RoleId, TypeIdList) ->
	[get_count(RoleId, Type) || Type <- TypeIdList, is_integer(Type)].

%% 加一操作
increment(RoleId, Type) ->
    plus_count(RoleId, Type, 1).

%% 减一操作
decrement(RoleId, Type) ->
	cut_count(RoleId, Type, 1).


%% 设置数量
set_count(RoleId, Type, Count) ->
    case lib_daily_dict:get(RoleId, Type) of
        false -> save(new([RoleId, Type, Count]));
        RD -> save(RD#ets_daily{count = Count})
    end.

%% 追加数量
plus_count(RoleId, Type, Count) ->
    case lib_daily_dict:get(RoleId, Type) of
        false -> save(new([RoleId, Type, Count]));
        RD -> save(RD#ets_daily{count = RD#ets_daily.count + Count})
    end.

%% 扣除数量
cut_count(RoleId, Type, Count) ->
    case lib_daily_dict:get(RoleId, Type) of
        false -> save(new([RoleId, Type, Count]));
        RD -> save(RD#ets_daily{count = RD#ets_daily.count - Count})
    end.

%% 获取刷新时间
get_refresh_time(RoleId, Type) ->
	case lib_daily_dict:get(RoleId, Type) of
        false -> 0;
        RD -> RD#ets_daily.refresh_time
    end.

%% 更新刷新时间
set_refresh_time(RoleId, Type) ->
    case lib_daily_dict:get(RoleId, Type) of
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
    {RoleId, _Type} = NewRoleDaily#ets_daily.id,
    Data = get_all(RoleId),
    Data1 = lists:keydelete(NewRoleDaily#ets_daily.id, #ets_daily.id, Data) ++ [NewRoleDaily],
    put(?DAILY_KEY(RoleId), Data1),
	lib_fortune:taks_times_refresh(RoleDaily).

%% 所有数据重载(等于清除某玩家的所有数据了```)
reload(_RoleId) ->
	[].

%% to_dict([], D) ->
%%     D;
%% to_dict([[RoleId, Type, Count, Time] | T], D) ->
%%     to_dict(T, D ++ [#ets_daily{
%%             id              = {RoleId, Type}
%%             ,count          = Count
%%             ,refresh_time   = Time
%%         }]).

%% 每天数据清除
daily_clear() ->
    erase().

