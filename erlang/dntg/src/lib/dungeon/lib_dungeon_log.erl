%%------------------------------------------------------------------------------
%% @Module  : lib_dungeon_log
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.8.22
%% @Description: 副本日志
%%------------------------------------------------------------------------------


-module(lib_dungeon_log).
-include("dungeon.hrl").
-include("sql_dungeon.hrl").


-export([
        online/1,                 %% 上线操作.
        offline/1,                %% 下线操作.
        get/2,                    %% 获取整个记录器.
        get_all/1,                %% 取玩家的整个记录
        get_count/2,              %% 获取数量.
        set_count/3,              %% 加一操作.
        plus_count/3,             %% 追加数量.
		cut_count/3,              %% 扣除数量.
        new/1,                    %% 新建数据.
        save/1,                   %% 保存数据.
		reload/1,                 %% 所有数据重载.
		to_dict/2,                %% 转换为进程字典数据.
        increment/2,              %% 加一操作.
		decrement/2,              %% 减一操作
		get_cooling_time/2,       %% 获取副本冷却时间.	
        set_cooling_time/2,       %% 更新副本冷却时间. 
		clear_cooling_time/2,     %% 清空副本冷却时间.
		get_record_level/2,	      %% 获取副本通关等级.
        set_record_level/4	      %% 更新副本通关等级.
    ]).


%% 上线操作.
online(RoleId) ->
    reload(RoleId).

%% 下线操作.
offline(RoleId) ->
    erase(?DUNGEON_LOG_KEY(RoleId)).

%% 获取整个记录器.
get(RoleId, DungeonId) ->
    Data = get_all(RoleId),
    lists:keyfind({RoleId, DungeonId}, #dungeon_log.id, Data).

%% 取玩家的整个记录.
get_all(RoleId) ->
    Data =  get(?DUNGEON_LOG_KEY(RoleId)),
    case Data =:= undefined of
        true ->
            reload(RoleId);
        false ->
            Data
    end.

%% 获取数量.
get_count(RoleId, DungeonId) ->
    case lib_dungeon_log:get(RoleId, DungeonId) of
        false -> 0;
        RD -> RD#dungeon_log.total_count
    end.


%% 加一操作.
increment(RoleId, DungeonId) ->
    plus_count(RoleId, DungeonId, 1).

%% 减一操作
decrement(RoleId, DungeonId) ->
	cut_count(RoleId, DungeonId, 1).


%% 设置数量
set_count(RoleId, DungeonId, Count) ->
    case lib_dungeon_log:get(RoleId, DungeonId) of
        false -> save(new([RoleId, DungeonId, Count, 0, 0, 0, 0]));
        RD -> save(RD#dungeon_log{total_count = Count})
    end.

%% 追加数量
plus_count(RoleId, DungeonId, Count) ->
	TotalCount = 
	    case lib_dungeon_log:get(RoleId, DungeonId) of
	        false ->
				%查询查询副本你是否有礼包.
				GiftId = data_story_dun_config:get_gift_id(DungeonId),
				GiftFlag = 
					case GiftId of
						0 ->
							0;
						_Other ->
							1
					end,
				save(new([RoleId, DungeonId, Count, 0, 0, 0, GiftFlag])),
				Count;
	        RD ->
				GiftFlag = 
					case RD#dungeon_log.gift of
						0 ->
							%查询查询副本你是否有礼包.
							GiftId = data_story_dun_config:get_gift_id(DungeonId),
							case GiftId of
								0 ->
									0;
								_Other ->
									1
							end;
						_Other ->
							_Other
					end,
				TotalCount1 = RD#dungeon_log.total_count + Count,
				save(RD#dungeon_log{total_count=TotalCount1, gift=GiftFlag}),
				TotalCount1
	    end,

	%发给客户端更新次数.
	CountList = [{DungeonId, TotalCount}],
	{ok, BinData} = pt_610:write(61008, [RoleId, CountList]),
	lib_server_send:send_to_uid(RoleId, BinData).	

%% 扣除数量
cut_count(RoleId, DungeonId, Count) ->
    case lib_dungeon_log:get(RoleId, DungeonId) of
        false -> save(new([RoleId, DungeonId, Count, 0, 0, 0, 0]));
        RD -> save(RD#dungeon_log{total_count = RD#dungeon_log.total_count - Count})
    end.

%% 获取冷却时间.
get_cooling_time(RoleId, DungeonId) ->
	case lib_dungeon_log:get(RoleId, DungeonId) of
        false -> {0, 0, 0};
        RD -> 
			CoolTime1 = util:unixtime() - RD#dungeon_log.cooling_time,
			if CoolTime1 > 300 ->
				   {0,
					RD#dungeon_log.record_level,
					RD#dungeon_log.pass_time};
			   true ->
				   {300 - CoolTime1,
					RD#dungeon_log.record_level,
					RD#dungeon_log.pass_time}
			end
    end.

%% 更新冷却时间.
set_cooling_time(RoleId, DungeonId) ->
	NowTime = util:unixtime(),
    case lib_dungeon_log:get(RoleId, DungeonId) of
        false -> save(new([RoleId, DungeonId, 0, 0, 0, NowTime, 0]));
        RD -> save(RD#dungeon_log{ cooling_time=NowTime })
    end.

%% 清空冷却时间.
clear_cooling_time(RoleId, DungeonId) ->
    case lib_dungeon_log:get(RoleId, DungeonId) of
        false -> save(new([RoleId, DungeonId, 0, 0, 0, 0, 0]));
        RD -> save(RD#dungeon_log{cooling_time=0, gift=0})
    end.

%% 获取副本通关等级.
get_record_level(RoleId, DungeonId) ->
	case lib_dungeon_log:get(RoleId, DungeonId) of
        false -> 0;
        RD -> {ok, RD#dungeon_log.record_level, RD#dungeon_log.pass_time}
    end.

%% 更新副本通关等级.
set_record_level(RoleId, DungeonId, RecordLevel, TotalTime) ->
	%1.保存通关等级.
    case lib_dungeon_log:get(RoleId, DungeonId) of
        false -> save(new([RoleId, DungeonId, 1, RecordLevel, TotalTime, 0, 0]));
        RD -> save(RD#dungeon_log{ record_level=RecordLevel, pass_time=TotalTime})
    end.

%% 新建数据
new([RoleId, DungeonId, Count, Level, TotalTime, Time, Gift]) ->  
    #dungeon_log{
        id              = {RoleId, DungeonId}
        ,total_count    = Count
		,record_level   = Level
		,pass_time      = TotalTime 
        ,cooling_time   = Time
		,gift           = Gift
    };

%% 新建数据
new([RoleId, DungeonId]) ->  
    #dungeon_log{id = {RoleId, DungeonId}}.

%% 保存数据
save(DungeonLog) ->
    {RoleId, DungeonId} = DungeonLog#dungeon_log.id,
    Data = get_all(RoleId),
    Data1 = lists:keydelete(DungeonLog#dungeon_log.id, #dungeon_log.id, Data) ++ [DungeonLog],
    put(?DUNGEON_LOG_KEY(RoleId), Data1),
    catch db:execute_nohalt(io_lib:format(?sql_dungeon_log_upd, 
										  [RoleId, DungeonId, 
										   DungeonLog#dungeon_log.total_count, 
										   DungeonLog#dungeon_log.record_level,
										   DungeonLog#dungeon_log.pass_time,
										   DungeonLog#dungeon_log.cooling_time,
										   DungeonLog#dungeon_log.gift])).

%% 所有数据重载.
reload(RoleId) ->
    offline(RoleId),
    List = db:get_all(io_lib:format(?sql_dungeon_log_sel_all, [RoleId])),
    D = to_dict(List, []),
    put(?DUNGEON_LOG_KEY(RoleId), D),
    D.

%% 转换为进程字典数据.
to_dict([], D) ->
    D;
to_dict([[RoleId, Type, Count, Level, PassTime, Time, Gift] | T], D) ->
    to_dict(T, D ++ [#dungeon_log{
            id              = {RoleId, Type}
            ,total_count    = Count
			,record_level   = Level
			,pass_time      = PassTime					 
            ,cooling_time   = Time
			,gift           = Gift
        }]).