%%%------------------------------------
%%% @Module  : pt_451
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.02.25
%%% @Description: VIP副本
%%%------------------------------------

-module(pt_451).
-export([read/2, write/2]).


%% 进入vip副本
read(45101, _) ->
    {ok, []};

%% 退出vip副本
read(45102, _) ->
    {ok, []};

%% 副本信息
read(45103, _) ->
    {ok, []};

%% 投掷骰子
read(45105, _) ->
    {ok, []};

%% 杀怪用时
read(45106, _) ->
    {ok, []};

%% 获取题目
read(45107, _) ->
    {ok, []};

%% 回答题目
read(45108, <<Answer:8>>) ->
    {ok, [Answer]};

%% 选择正确答案
read(45109, _) ->
    {ok, []};

%% 去掉2个错误答题
read(45110, _) ->
    {ok, []};

%% 猜拳
read(45111, <<Answer:8>>) ->
    {ok, [Answer]};

%% 购买骰子次数
read(45113, _) ->
    {ok, []};

%% 赌神(压大小)
read(45115, <<Ans:8>>) ->
    {ok, [Ans]};

%% 圈数加一(成功则传送玩家至第一格，失败则不做处理)
read(45116, _) ->
    {ok, []};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%% 进入vip副本
write(45101, [Res, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(45101, <<Res:8, Str1/binary>>)};

%% 退出vip副本
write(45102, [Res, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(45102, <<Res:8, Str1/binary>>)};

%% 副本信息
write(45103, [RestTime, XYList, X, Y, Type, SkillList, RestNum, CanFlap, DunNum, NeedGold, Round, ForceMove]) ->
    Pack = pack1(RestTime, XYList, X, Y, Type, SkillList, RestNum, CanFlap, DunNum, NeedGold, Round, ForceMove),
    {ok, pt:pack(45103, Pack)};

%% 投掷骰子
write(45105, [Num]) ->
    {ok, pt:pack(45105, <<Num:8>>)};

%% 杀怪用时
write(45106, [Time]) ->
    {ok, pt:pack(45106, <<Time:32>>)};

%% 获取题目
write(45107, [Question, Section1, Section2, Section3, Section4, QuestimeTime2]) ->
    Question1 = pt:write_string(Question),
    Section11 = pt:write_string(Section1),
    Section21 = pt:write_string(Section2),
    Section31 = pt:write_string(Section3),
    Section41 = pt:write_string(Section4),
    {ok, pt:pack(45107, <<Question1/binary, Section11/binary, Section21/binary, Section31/binary, Section41/binary, QuestimeTime2:32>>)};

%% 回答题目
write(45108, [Res]) ->
    {ok, pt:pack(45108, <<Res:8>>)};

%% 选择正确答案
write(45109, [Res]) ->
    {ok, pt:pack(45109, <<Res:8>>)};

%% 去掉2个错误答题
write(45110, [Res, Wrong1, Wrong2]) ->
    {ok, pt:pack(45110, <<Res:8, Wrong1:8, Wrong2:8>>)};

%% 猜拳
write(45111, [Res, Answer, ComputeRes]) ->
    {ok, pt:pack(45111, <<Res:8, Answer:8, ComputeRes:8>>)};

%% 获得技能
write(45112, [Skill]) ->
    {ok, pt:pack(45112, <<Skill:8>>)};

%% 购买骰子次数
write(45113, [Res, RestNum, NextGold]) ->
    {ok, pt:pack(45113, <<Res:8, RestNum:8, NextGold:8>>)};

%% 提示
write(45114, [Res, Str]) ->
    Str1 = pt:write_string(util:make_sure_list(Str)),
    {ok, pt:pack(45114, <<Res:8, Str1/binary>>)};

%% 赌神(压大小)
write(45115, [Res, Point]) ->
    {ok, pt:pack(45115, <<Res:8, Point:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

pack1(RestTime, XYList, X, Y, Type, SkillList, RestNum, CanFlap, DunNum, NeedGold, Round, ForceMove) ->
    Fun1 = fun(Elem1) ->
            {{PerX, PerY}, _State} = Elem1,
            <<PerX:16, PerY:16>>
    end,
    BinList1 = list_to_binary([Fun1(X1) || X1 <- XYList]),
    Size1  = length(XYList),
    Fun2 = fun(Elem2) ->
            Id = Elem2,
            <<Id:8>>
    end,
    BinList2 = list_to_binary([Fun2(X2) || X2 <- SkillList]),
    Size2  = length(SkillList),
    <<RestTime:32, Size1:16, BinList1/binary, X:16, Y:16, Type:8, Size2:16, BinList2/binary, RestNum:8, CanFlap:8, DunNum:32, NeedGold:8, Round:8, ForceMove:8>>.
