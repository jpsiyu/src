%%%-----------------------------------
%%% @Module  : pt_200
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.07.25
%%% @Description: 20战斗信息
%%%-----------------------------------
-module(pt_200).
-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%

%%人打怪
read(20001, <<Id:32, Sid:32, AttMovieType:8, TargetX:16, TargetY:16>>) ->
    {ok, [Id, Sid, AttMovieType, TargetX, TargetY]};

%%人打人
read(20002, <<Id:32, Bin/binary>>) ->
    {Platform, Bin1} = pt:read_string(Bin),
    <<SerNum:16, Sid:32, AttMovieType:8, TargetX:16, TargetY:16, _Bin2/binary>>= Bin1,
    {ok, [Id, Platform, SerNum, Sid, AttMovieType, TargetX, TargetY]};

%%复活:1正常复活，2原地复活
read(20004, <<Type:8>>) ->
    {ok, [Type]};

%%使用辅助技能
read(20006, <<Id:32, Bin/binary>>) ->
    {Platform, Bin1} = pt:read_string(Bin),
    <<SerNum:16, Sid:32, Act:8, _Bin2/binary>>= Bin1,
    {ok, [Id, Platform, SerNum, Sid, Act]};

%%采集怪物
read(20008, <<MonId:32, Type:8>>) ->
    {ok, [MonId, Type]};

%%施放特殊技能
read(20009, <<SkillId:32, Id:32, Bin/binary>>) ->
    {Platform, Bin1} = pt:read_string(Bin),
    <<SerNum:16, Type:8, _Bin2/binary>>= Bin1,
    {ok, [SkillId, Id, Platform, SerNum, Type]};

%%拾取怪物
read(20010, <<Id:32>>) ->
    {ok, Id};

%%特殊攻击协议（用于模拟攻击）
read(20012, <<AttId:32, DefType:8, DefId:32, Bin/binary>>) ->
    {Platform, <<ServerNum:16, SkillId:32>>} = pt:read_string(Bin),
    {ok, [AttId, DefType, DefId, Platform, ServerNum, SkillId]};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%%广播战斗结果 - 玩家PK怪
write(20001, [Id, Platform, SerNum, Hp, Mp, SkillId, SkillLv, AerX, AerY, Act, TargetX, TargetY, ABuffList, AEffectList, DefList]) ->
    Platform1 = pt:write_string(Platform),
    Data1 = <<Id:32, Platform1/binary, SerNum:16, Hp:32, Mp:32, SkillId:32, SkillLv:8, AerX:16, AerY:16, Act:8, TargetX:16, TargetY:16>>,
    AEffectList_b = effect_list(AEffectList),
    DefList_b     = def_list(DefList),
    Data          = << Data1/binary, ABuffList/binary, AEffectList_b/binary, DefList_b/binary>>,
    {ok, pt:pack(20001, Data)};

%%广播战斗结果 - 怪PK玩家
write(20003, [Id, Platform, SerNum, Hp, Mp, SkillId, SkillLv, AerX, AerY, Act, TargetX, TargetY, ABuffList, AEffectList, DefList]) ->
    Platform1 = pt:write_string(Platform),
    Data1 = <<Id:32, Platform1/binary, SerNum:16, Hp:32, Mp:32, SkillId:32, SkillLv:8, AerX:16, AerY:16, Act:8, TargetX:16, TargetY:16>>,
    AEffectList_b = effect_list(AEffectList),
    DefList_b     = def_list(DefList),
    Data          = << Data1/binary, ABuffList/binary, AEffectList_b/binary, DefList_b/binary>>,
    {ok, pt:pack(20003, Data)};

%%复活结果
write(20004, [Res, ReturnScene]) ->
    Data = <<Res:8, ReturnScene:32>>,
    {ok, pt:pack(20004, Data)};

%%广播战斗结果 - 怪PK玩家
write(20005, [ErrCode, Sign1, User1, Platform1, SerNum1, Hp1, X1, Y1, Sign2, User2, Platform2, SerNum2, Hp2, X2, Y2]) ->
    Platform1_b = pt:write_string(Platform1),
    Platform2_b = pt:write_string(Platform2),
    {ok, pt:pack(20005, <<ErrCode:8, Sign1:8, User1:32, Platform1_b/binary, SerNum1:16, Hp1:32, X1:16, Y1:16, Sign2:8, User2:32, Platform2_b/binary, SerNum2:16, Hp2:32, X2:16, Y2:16>>)};

%%广播战斗结果 - 辅助技能
write(20006, [Sign, Id, Platform, SerNum, SkillId, SkillLv, Mp, Act, AssList]) ->
    Platform1 = pt:write_string(Platform),
    Data1 = <<Id:32, Platform1/binary, SerNum:16, Sign:8, SkillId:32, SkillLv:8, Mp:32, Act:8>>,
    Data2 = assist_list(AssList),
    Data = << Data1/binary, Data2/binary>>,
    {ok, pt:pack(20006, Data)};

%%战斗疲劳
write(20007, _) ->
    Data = <<>>,
    {ok, pt:pack(20007, Data)};

%%采集怪物
write(20008, Res) ->
    {ok, pt:pack(20008, <<Res:8>>)};

%%拾取怪物
write(20010, Res) ->
    {ok, pt:pack(20010, <<Res:8>>)};

%%复活冷却时间
write(20011, [Time1, Time2]) ->
    {ok, pt:pack(20011, <<Time1:16, Time2:16>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

def_list([]) ->
    <<0:16, <<>>/binary>>;
def_list(DefList) ->
    Rlen = length(DefList),
    F = fun([Sign, Id, Platform, SerNum, Hp, Mp, Hurt, HurtType, X, Y, DBuffList, EList]) ->
        Platform_b = pt:write_string(Platform),
        EList_b = effect_list(EList),
        <<Sign:8, Id:32, Platform_b/binary, SerNum:16, Hp:32, Mp:32, Hurt:32, HurtType:8, X:16, Y:16, DBuffList/binary, EList_b/binary>>
    end,
    RB = list_to_binary([F(D) || D <- DefList]),
    <<Rlen:16, RB/binary>>.

assist_list([]) ->
    <<0:16, <<>>/binary>>;
assist_list(List) ->
    Rlen = length(List),
    F = fun([Sign, Id, Platform, SerNum, Hp, DBuffList, EffectList]) ->
            Platform_b = pt:write_string(Platform),
            EL_b = effect_list(EffectList),
            <<Sign:8, Id:32, Platform_b/binary, SerNum:16, Hp:32, DBuffList/binary, EL_b/binary>>
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.

effect_list([]) ->
    <<0:16, <<>>/binary>>;
effect_list(List) ->
    Rlen = length(List),
    F = fun({Type, LastTime, Value}) ->
            <<Type:8, LastTime:32, Value:32>> 
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.
