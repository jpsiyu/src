%%%-----------------------------------
%%% @Module  : pt_280
%%% @Author  : zzm
%%% @Email   : ming_up@163.com
%%% @Created : 2011.01.07
%%% @Description: 28锁妖塔信息
%%%-----------------------------------
-module(pt_280).
-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%

%% 进入锁妖塔
read(28000, <<TowerType:32>>) ->
    {ok, TowerType};

%% 获取这一层的霸主
read(28001, <<Sid:32>>) ->
    {ok, Sid};

%% 获取这一层的剩余时间
read(28002, _) ->
    {ok, []};

%% 计时结束
%read(28003, <<LeaderId:32, Time:32>>) ->
%    {ok, [LeaderId, Time]};

%% 霸主每天领取奖励
read(28004, _) ->
    {ok, []};

%% 离开锁妖塔
read(28005, _) ->
    {ok, []};

%% 获取这一层的奖励
read(28006, _) ->
    {ok, []};

%% 层数超时全部离开
read(28010, _) ->
    {ok, []};

%% 增加跳层次数
read(28011, _) ->
    {ok, []};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%% 获取每层霸主
write(28001, [L, PassTime]) ->
    N = length(L),
    F = fun({Id, Lv, Realm, Career, Sex, Weapon, Cloth, WLight, CLight, ShiZhuang, SuitId, Vip, Nick}) ->
            [[FWeapon, FWS], [FArmor, FAS], [FAccessory, FAccS]] = case is_list(ShiZhuang) of
                true -> ShiZhuang;
                false -> [[0,0],[ShiZhuang,0],[0,0]]
            end,
            Nick_b = list_to_binary(Nick),
            NL = byte_size(Nick_b),
            S7 = pt:write_string(integer_to_list(CLight)),
            <<Id:32,       %% 玩家id    
            Lv:16,         %% 玩家等级
            Realm:8,       %% 国家
            Career:8,      %% 玩家职业
            Sex:8,         %% 玩家性别
            Weapon:32,     %% 武器
            Cloth:32,      %% 装备
            WLight:8,      %% 武器发光
            S7/binary,     %% 衣服发光
            FArmor:32,     %% 时装衣服id
            SuitId:32,     %% 套装id
            Vip:8,         %% vip
            NL:16,         %% 玩家名字
			Nick_b/binary, %% 玩家名字
            FAS:8,         %% 衣服时装强化数
            FWeapon:32,    %% 武器时装id
            FWS:8,         %% 武器时装强化数
            FAccessory:32, %% 饰品时装id
            FAccS:8>>      %% 饰品时装强化数
    end,
    BL = list_to_binary([F(E) || E <- L]),
    {ok, pt:pack(28001, <<N:16, BL/binary, PassTime:32>>)};

%% 获取该层剩余时间
write(28002, [LeftTime, Type, Count]) ->
    {ok, pt:pack(28002, <<LeftTime:32, Type:8, Count:8>>)};

%% 霸主领取经历
write(28004, Res) ->
    {ok, pt:pack(28004, <<Res:8>>)};

%% 获取这一层的奖励
write(28006, [Exp, Llpt, TotalExp, TotalLlpt, Level, Sid]) ->
    {ok, pt:pack(28006, <<Exp:32, Llpt:32, TotalExp:32, TotalLlpt:32, Level:8, Sid:32>>)};

%% 开始计时
write(28007, [BeginCountTime, Type]) ->
    {ok, pt:pack(28007, <<BeginCountTime:32, Type:8>>)};

%% 增加跳层次数
write(28011, [R, Count]) ->
    {ok, pt:pack(28011, <<R:8, Count:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
