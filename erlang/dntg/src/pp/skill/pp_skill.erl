%%%--------------------------------------
%%% @Module  : pp_skill
%%% @Author  : zhenghehe
%%% @Created : 2010.07.27
%%% @Description:  技能管理
%%%--------------------------------------
-module(pp_skill).
-export([handle/3]).
-include("common.hrl").
%% -include("record.hrl").
-include("server.hrl").
-include("skill.hrl").

%%学习技能
handle(21001, Status, SkillId) ->
    Status1 = lib_skill:upgrade_skill(Status, SkillId, 0, 0),
    {ok, Status1};

%%获取技能列表
handle(21002, Status, _) ->
    Sk = Status#player_status.skill,
    All = data_skill:get_ids(Status#player_status.career),
    {ok, BinData} = pt_210:write(21002, [All, Sk#status_skill.skill_list, []]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%% 获取技能cd列表
handle(21003, Status, []) -> 
    Skill = Status#player_status.skill,
    {ok, BinData} = pt_210:write(21003, Skill#status_skill.skill_cd),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    ok;

%% 删除技能Buff
handle(21004, Status, TypeId) ->
    Status1 = lib_skill_buff:remove_buff(Status, TypeId),
    {ok, Status1};
    
%% 删除连砍Buff
%handle(21031, Status, _) ->
%    NewStatus = lib_ext_skill:clear_combo_buff(Status),
%    {ok, NewStatus};
    
handle(_Cmd, _Status, _Data) ->
    {error, "pp_skill no match"}.
