%%%--------------------------------------
%%% @Module  : pp_team2
%%% @Author  : zhenghehe
%%% @Created : 2010.07.06
%%% @Description:  组队功能管理(公共服务器)
%%%--------------------------------------
-module(pp_team2).
-export([handle/3]).
%% -include("record.hrl").
-include("common.hrl").
-include("unite.hrl").
-include("team.hrl").
-include("dungeon.hrl").
-include("server.hrl").

%% 发布招募消息 -- 公共服务器
handle(24035, Status, [Type, SubType, LowLevel, HighLevel, Career, Leader, Msg]) when is_record(Status, unite_status)->
    Res = case mod_chat_agent:lookup(Status#unite_status.id) of
        [] -> 0;
        [R] ->
            lib_team:delete_proclaim(Status#unite_status.id),
            ets:insert(?ETS_TEAM_ENLIST, #ets_team_enlist{
                    id = {util:unixtime(), R#ets_unite.id},
                    name = list_to_binary(R#ets_unite.name),
                    career = R#ets_unite.career,
                    lv = R#ets_unite.lv,
                    type = Type,
                    sub_type = SubType,
                    low_lv = LowLevel,
                    high_lv = HighLevel,
                    lim_career = Career,
                    sex = R#ets_unite.sex,
                    leader = Leader,
                    msg = Msg
                }),
            1
    end,
    {ok, BinData} = pt_240:write(24035, Res),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 获取招募信息 -- 公共服务器
handle(24036, Status, []) ->
    L = ets:tab2list(?ETS_TEAM_ENLIST),
    {ok, BinData} = pt_240:write(24036, L),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 登记副本招募(8.29)
handle(24049, Status, [IsNeedFire, IsNeedIce, IsNeedDrug, Lv, Att, Def, Sid, CombatPower]) when is_record(Status, unite_status)->
    Res = case mod_chat_agent:lookup(Status#unite_status.id) of
        [] -> 0;
        [ChatInfo] ->
            mod_team_agent:create_dungeon_enlist2(#ets_dungeon_enlist2{
                    id = Status#unite_status.id, 
                    sid = Sid, 
                    nickname = ChatInfo#ets_unite.name,
                    is_need_fire = IsNeedFire,
                    is_need_ice = IsNeedIce,
                    is_need_drug = IsNeedDrug,
                    lv = Lv,
                    att = Att,
                    def = Def,
                    combatpower = CombatPower
                }), 
            1
    end,
    {ok, BinData} = pt_240:write(24049, Res),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    ok;

%% 注销副本招募(8.29)
handle(24050, Status, []) ->
	mod_team_agent:del_dungeon_enlist2(Status#unite_status.id),    
    {ok, BinData} = pt_240:write(24050, 1),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    ok;

%% 获取副本招募列表(8.29)
handle(24051, Status, Sid) ->
	L = mod_team_agent:get_dungeon_enlist2_by_scene_id(Sid),
    {ok, BinData} = pt_240:write(24051, L),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    ok;

%% 聊天招募队友查询是否进入副本(公共线)
%% 0 => 否 1 => 是 2 => 队伍已满
handle(24062, Status, LeaderId) when is_record(Status, unite_status)->
    Res = case mod_team_agent:get_dungeon_enlist2_by_player_id(LeaderId) of
        [] ->
			0;
        [_R|_Other] -> 
			if 
				_R#ets_dungeon_enlist2.mb_num >= 3 ->
					2;
				true ->
					1
			end
    end,
    {ok, BinData} = pt_240:write(24062, [Res, LeaderId]),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    ok;

handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_team2 no match", []),
    {error, "pp_team2 no match"}.
