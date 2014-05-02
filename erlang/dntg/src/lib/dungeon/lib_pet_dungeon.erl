%%------------------------------------------------------------------------------
%% @Module  : lib_pet_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.3
%% @Description: 宠物副本逻辑
%%------------------------------------------------------------------------------

-module(lib_pet_dungeon).
-export([
		 check_enter_dungeon/2, %% 检查情缘副本是否能进入.
		 get_appointment_msg/2, %% 获取情缘副本中对应的怪物名字.
		 send_change_look/4     %% 发送怪物变身.
]).

-include("common.hrl").
-include("scene.hrl").
-include("unite.hrl").
-include("rela.hrl").
-include("server.hrl").
-include("appointment.hrl").
-include("task.hrl").
-include("dungeon.hrl").


%% 进入情缘副本.
check_enter_dungeon(Id, PS) ->
    if
        Id == 233 ->
            Mids = lib_team:get_mb_ids(PS#player_status.pid_team),
            F = fun(Mid) -> 
                    case lib_player:get_player_info(Mid) of
                        [] -> 
							0;
                        PlayerStatus -> 
							PlayerStatus#player_status.sex
                    end
            end,
            L = [F(Mid)||Mid<-Mids],
            [lists:member(X,L)||X<-[1,2]] == [true, true];
        true -> true
    end.

%% 获取对应怪物的名字.
get_appointment_msg(MonResId, MonName) -> 
    MonNameList = data_appointment_dungeon:get_name(),
    if
        MonResId rem 2 == 0 -> %% 女性
            lists:keyfind(MonName, 2, MonNameList);
        true -> 
            lists:keyfind(MonName, 1, MonNameList)
    end.

%% 发送怪物变身.
%% MonId:怪物自增ID, MonMid:怪物类型ID.
%% ChangeType:0默认变身，1狂暴变身，2狂暴变身还原，3伪装变身，4伪装变身还原.
send_change_look(MonId, MonMid, ChangeType, State) ->
	NewMon = data_mon:get(MonMid),
	case NewMon =:= [] of
	    true ->
	        skip;
	    false ->
			{ok, BinData} = pt_120:write(12085, [MonId, 
	                                     		 NewMon#ets_mon.icon,
	                                     		 111,0,0,
	                                     		 ChangeType,
	                                     		 NewMon#ets_mon.name
												 ]),
			[lib_player:rpc_cast_by_id(Role#dungeon_player.id, 
									   lib_server_send, 
									   send_to_uid, 
									   [Role#dungeon_player.id, BinData])
									  ||Role<-State#dungeon_state.role_list]
	end.
