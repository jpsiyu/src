%%%-----------------------------------
%%% @Module  : pt_210
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.12.13
%%% @Description: 21技能信息
%%%-----------------------------------
-module(pt_210).
-include("skill.hrl").
-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%

%%技能升级
read(21001, <<Id:32>>) ->
    {ok, Id};

%%技能列表
read(21002, _) ->
    {ok, list};

%%技能cd列表
read(21003, _) ->
    {ok, []};

%% 删除技能Buff
read(21004, <<TypeId:32>>) ->
    {ok, TypeId};

%% 删除连砍技能Buff
read(21031, _) ->
    {ok, no};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%%技能升级
write(21001, [State, Msg, Id]) ->
    Msg_b = pt:write_string(Msg),
    {ok, pt:pack(21001, <<State:32, Msg_b/binary, Id:32>>)};

%%获取技能列表
write(21002, [All, Skill, ExtSkill]) ->
    {ok, pt:pack(21002, skill_list([All, Skill, ExtSkill]))};

%%获取技能cd列表
write(21003, SkillCd) ->
    Len = length(SkillCd),
    Now = util:longunixtime(),
    F =fun({SkillId, LastTime}) ->
            LeftTime =  Now - LastTime,
            case LeftTime > 10*60*1000 orelse LeftTime < 1 of
                true -> <<0:32, 0:32>>;
                false -> <<SkillId:32, LeftTime:32>>
            end
    end,
    SkillCd_b = list_to_binary([F(E)||E <- SkillCd]),
    {ok, pt:pack(21003, <<Len:16, SkillCd_b/binary>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
    
skill_list([]) ->
    <<0:16, <<>>/binary>>;
skill_list([All, Skill, ExtSkill]) ->
    Rlen = length(All),
    F = fun(SkillId) ->
        %额外等级
        _ExtLv1 = case lists:keyfind(SkillId, 1, ExtSkill) of
            {_, ExtLv} ->
                ExtLv;
            _ ->
                0
        end,
        case lists:keyfind(SkillId, 1, Skill) of
            false ->
                <<SkillId:32, 0:8>>;
            {_, Lv} ->
                <<SkillId:32, Lv:8>>
        end
    end,
    RB = list_to_binary([F(D) || D <- All]),
    <<Rlen:16, RB/binary>>.
