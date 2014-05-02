%%------------------------------------------------------------------------------
%% @Module  : pt_613
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.10.18
%% @Description: 塔防副本协议定义
%%------------------------------------------------------------------------------

-module(pt_613).
-export([read/2, write/2]).
-include("king_dun.hrl").
-include("scene.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%

%% 塔防副本—设置波数.
read(61300, <<Level:32>>) ->
    {ok, Level};
    
%% 塔防副本—获取波数.
read(61301, _) ->
    {ok, []};

%% 塔防副本—获取积分和经验.
read(61302, _) ->
    {ok, []};

%% 塔防副本—提前召唤怪物.
read(61303, _) ->
    {ok, []};

%% 塔防副本—升级建筑.
read(61304, <<MonAutoId:32, NextMonMid:32>>) ->
    {ok, [MonAutoId, NextMonMid]};

%% 塔防副本—升级技能.
read(61305, <<MonAutoId:32, SkillId:32, SkillLevel:32>>) ->
    {ok, [MonAutoId, SkillId, SkillLevel]};

%% 塔防副本—获取建筑信息.
read(61306, _) ->
    {ok, []};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%
        
%% 塔防副本—设置波数.
write(61300, [Result]) ->
    {ok, pt:pack(61300, <<Result:8>>)};

%% 塔防副本—获取波数.
write(61301, [Level, MonName, _Time, _TotalTime]) ->
	%1.得到怪物进攻时间.
	{Time, TotalTime} = 
		case _Time =< 0 of
			true ->
				{0, 0};
			false ->
				{_Time, _TotalTime}
		end,
		
	Name = pt:write_string(MonName),
    {ok, pt:pack(61301, <<Level:32, Name/binary, Time:32, TotalTime:32>>)};

%% 塔防副本—获取积分和经验.
write(61302, [Score, Exp]) ->
    {ok, pt:pack(61302, <<Score:32, Exp:32>>)};

%% 塔防副本—提前召唤怪物.
write(61303, [Result]) ->
    {ok, pt:pack(61303, <<Result:8>>)};

%% 塔防副本—升级建筑.
write(61304, [Result]) ->
    {ok, pt:pack(61304, <<Result:8>>)};

%% 塔防副本—升级技能.
write(61305, [Result, MonAutoId, SkillId]) ->
    {ok, pt:pack(61305, <<Result:8, MonAutoId:32, SkillId:32>>)};

%% 塔防副本—获取建筑信息.
write(61306, [BuildingList]) ->
	%1.技能.
	FunSkill = 
		fun({SkillId, SkillLevel}) ->
        	<<SkillId:32, SkillLevel:32>>
    end,

	%2.建筑.
	FunBuilding = 
		fun(BuildingAutoId, BuildingId, Position,SkillList) ->
			BuildingIconId = 
				case data_mon:get(BuildingId) of
					  [] -> 
						  BuildingId;
					  MonData ->
					      if 
						      Position < 4 ->
							      MonData#ets_mon.icon+200;
							  true ->
							      MonData#ets_mon.icon
						  end
				end, 

		    SkillBinList = list_to_binary([FunSkill(X1) || X1 <- SkillList]),
		    SkillListSize = length(SkillList),				
        	<<Position:32, BuildingAutoId:32, BuildingId:32, BuildingIconId:32, SkillListSize:16, SkillBinList/binary>>
    end,
    BuildingBinList = list_to_binary([FunBuilding(
					      X2#king_dun_building.auto_id,
					      X2#king_dun_building.mid,
					      X2#king_dun_building.position,
						  X2#king_dun_building.skill_list)
						  || X2 <- BuildingList]),
    BuildingListSize  = length(BuildingList),	
    {ok, pt:pack(61306, <<BuildingListSize:16, BuildingBinList/binary>>)};

%% 塔防副本—升级建筑广播.
write(61307, [PlayerName, BuildingId, BuildingName, Score]) ->
	Name = pt:write_string(PlayerName),
	Name2 = pt:write_string(BuildingName),
    {ok, pt:pack(61307, <<Name/binary, BuildingId:32, Name2/binary, Score:32>>)};

%% 塔防副本—升级建筑的技能广播.
write(61308, [PlayerName, BuildingAutoId, SkillId, SkillName, SkillLevel, Score]) ->
	Name = pt:write_string(PlayerName),
	Name2 = pt:write_string(SkillName),
    {ok, pt:pack(61308, <<Name/binary, BuildingAutoId:32, SkillId:32, 
						  Name2/binary, SkillLevel:16, Score:32>>)};								 

%% 塔防副本—跳关成功.
write(61309, [NowLevel, TotalLevel]) ->
    {ok, pt:pack(61309, <<NowLevel:32, TotalLevel:32>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

