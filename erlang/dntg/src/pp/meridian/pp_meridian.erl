%%%--------------------------------------
%%% @Module  : pp_meridian
%%% @Author  : zengzhaoyuan
%%% @Email   : hc@jieyou.com
%%% @Created : 2010.08.09
%%% @Description:  经脉系统
%%%--------------------------------------

-module(pp_meridian).
-export([handle/3]).
-include("server.hrl").

handle(Cmd, PlayerStatus, Params)->
	%%不改变状态，无返回值，改变状态，返回{ok, NewPlayerStatus}
	case Cmd of
		25001 -> %%内功提升
            [MeridianId] = Params,
			if
				MeridianId=<0 orelse 10<MeridianId->
					ok;
				true->
					Reply = mod_meridian:upMer(PlayerStatus#player_status.player_meridian,PlayerStatus, [MeridianId]),
					handle(25003, PlayerStatus, [PlayerStatus#player_status.id,MeridianId,1]),
					case Reply of
						ok->ok;
						Others ->
							SPlayerStatus = lib_player:count_player_attribute(Others),
							lib_player:send_attribute_change_notify(SPlayerStatus, 4),
							{ok,SPlayerStatus}
					end
			end;
        25002 -> %%境界提升
			[MeridianId,IsUse,IsBuy] = Params,
			if
				MeridianId=<0 orelse 10<MeridianId->
					ok;
				true->
					Reply = mod_meridian:upGen(PlayerStatus#player_status.player_meridian,PlayerStatus, [MeridianId,IsUse,IsBuy]),
					handle(25003, PlayerStatus, [PlayerStatus#player_status.id,MeridianId,2]),
					case Reply of
						ok->ok;
						Others ->
							SPlayerStatus = lib_player:count_player_attribute(Others),
							lib_player:send_attribute_change_notify(SPlayerStatus, 4),
							{ok,SPlayerStatus}
					end
			end;
        25003 -> %%查询内功境界信息
			[Uid,Mid,Type] = Params,
			getMers(PlayerStatus,[Uid,Mid,Type]),
			ok;
		25004 -> %%加速CD时间
			{_MeridianId,Reply} = mod_meridian:clearCD(PlayerStatus#player_status.player_meridian,PlayerStatus),
			%%handle(25003, PlayerStatus, [PlayerStatus#player_status.id,MeridianId,1]),
            handle(25003, PlayerStatus, [PlayerStatus#player_status.id,0,1]),
			case Reply of
				ok->ok;
				Others ->
					SPlayerStatus = lib_player:count_player_attribute(Others),
					lib_player:send_attribute_change_notify(SPlayerStatus, 4),
					{ok,SPlayerStatus}
			end;
		25005 ->
			[MeridianId] = Params,
			if
				MeridianId=<0 orelse 10<MeridianId->
					ok;
				true->
					Reply = mod_meridian:tupo(PlayerStatus#player_status.player_meridian,PlayerStatus,MeridianId,0),
					handle(25003, PlayerStatus, [PlayerStatus#player_status.id,MeridianId,1]),
					{ok,Reply}
			end;
		25006 ->
			[Uid] = Params,
			if
				PlayerStatus#player_status.id=:=Uid->
					T_Player_meridian = mod_meridian:getPlayer_meridian(PlayerStatus#player_status.player_meridian),
					{Meridian_Gap,[{Mer_Hp3,Gen_Hp3}, {Mer_Mp3,Gen_Mp3}, {Mer_Def3,Gen_Def3}, {Mer_Hit3,Gen_Hit3}, {Mer_Dodge3,Gen_Dodge3}, 
								   {Mer_Ten3,Gen_Ten3},{Mer_Crit3,Gen_Crit3}, {Mer_Att3,Gen_Att3}, {Mer_Fire3,Gen_Fire3}, 
								   {Mer_Ice3,Gen_Ice3}, {Mer_Drug3,Gen_Drug3}]} = lib_meridian:count_attr(T_Player_meridian),
					Reply = {ok,{Meridian_Gap,[{Mer_Hp3,Gen_Hp3}, {Mer_Mp3,Gen_Mp3}, {Mer_Def3,Gen_Def3}, {Mer_Hit3,Gen_Hit3}, {Mer_Dodge3,Gen_Dodge3}, 
								   {Mer_Ten3,Gen_Ten3},{Mer_Crit3,Gen_Crit3}, {Mer_Att3,Gen_Att3}, {Mer_Fire3,Gen_Fire3}, 
								   {Mer_Ice3,Gen_Ice3}, {Mer_Drug3,Gen_Drug3}]}};
				true->
					case lib_player:get_player_info(Uid, player_meridian) of
						false->
							Reply = {error,offline};
						Player_meridian->
							T_Player_meridian = mod_meridian:getPlayer_meridian(Player_meridian),
							{Meridian_Gap,[{Mer_Hp3,Gen_Hp3}, {Mer_Mp3,Gen_Mp3}, {Mer_Def3,Gen_Def3}, {Mer_Hit3,Gen_Hit3}, {Mer_Dodge3,Gen_Dodge3}, 
								   {Mer_Ten3,Gen_Ten3},{Mer_Crit3,Gen_Crit3}, {Mer_Att3,Gen_Att3}, {Mer_Fire3,Gen_Fire3}, 
								   {Mer_Ice3,Gen_Ice3}, {Mer_Drug3,Gen_Drug3}]} = lib_meridian:count_attr(T_Player_meridian),
							Reply = {ok,{Meridian_Gap,[{Mer_Hp3,Gen_Hp3}, {Mer_Mp3,Gen_Mp3}, {Mer_Def3,Gen_Def3}, {Mer_Hit3,Gen_Hit3}, {Mer_Dodge3,Gen_Dodge3}, 
								   {Mer_Ten3,Gen_Ten3},{Mer_Crit3,Gen_Crit3}, {Mer_Att3,Gen_Att3}, {Mer_Fire3,Gen_Fire3}, 
								   {Mer_Ice3,Gen_Ice3}, {Mer_Drug3,Gen_Drug3}]}}
					end
			end,
			case Reply of
				{error,_Reson}->
					ok;
				{ok,Param}->
					{ok,DataBin} = pt_250:write(25006, [Param]),
					lib_server_send:send_to_sid(PlayerStatus#player_status.sid, DataBin)
			end;
		_ -> void
	end.

%%发送内功境界信息
%%@param PlayerStatus 玩家状态
%%@param BUid 目标玩家ID
%%@param Mid 内功类型ID
getMers(PlayerStatus,[BUid,Mid,Type])->
    if
    	BUid =:= PlayerStatus#player_status.id ->
        	B_PlayerStatus = PlayerStatus;
        true ->
            B_PlayerStatus = lib_player:get_player_info(BUid)
    end,
    if
        is_record(B_PlayerStatus,player_status) andalso is_pid(B_PlayerStatus#player_status.pid)->
			Player_meridian = gen_server:call(B_PlayerStatus#player_status.player_meridian,{getPlayer_meridian}),
			Data = lib_meridian:getMers(PlayerStatus,Player_meridian,Type,Mid);
        true ->
        	Data = [BUid,Type,0]
    end,
	{ok,BinData} = pt_250:write(25003,Data),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData).
