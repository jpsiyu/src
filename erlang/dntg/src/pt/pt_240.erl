%%%------------------------------------
%%% @Module  : pt_240
%%% @Author  : zhenghehe
%%% @Created : 2010.07.06
%%% @Description: 组队协议
%%%------------------------------------

-module(pt_240).
-export([read/2, write/2]).
-include("record.hrl").
-include("common.hrl").
-include("server.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%

%%创建队伍
read(24000, <<Type:8, Sid:32, Bin/binary>>) ->
    {TeamName, <<AutoEnter:8, Distribution:8, IsAllowMemInvite:8>>} = pt:read_string(Bin),
    {ok, [Type, Sid, TeamName, AutoEnter, Distribution, IsAllowMemInvite]};

%%加入队伍
read(24002, <<Id:32, JoinType:8>>) ->
    {ok, [Id, JoinType]};

%%队长处理加入队伍请求
read(24004, <<Res:16, Id:32>>) ->
    {ok, [Res, Id]};

%%离开队伍
read(24005, _R) ->
    {ok, []};

%%邀请人加入队伍
read(24006, <<Id:32>>) ->
    {ok, Id};

%%被邀请人处理邀请进队信息
read(24008, <<Id:32, Res:16>>) ->
    {ok, [Id, Res]};

%%踢出队伍
read(24009, <<Id:32>>) ->
    {ok, Id};

%%委任队长
read(24013, <<Id:32>>) ->
    {ok, Id};

%%更改队名
read(24014, <<Bin/binary>>) ->
    {TeamName, _} = pt:read_string(Bin),
    {ok, TeamName};

%%队伍资料
read(24016, <<Id:32>>) ->
    {ok, Id};

%% 解散队伍
read(24017, _R) ->
    {ok, []};

%% 设置队伍拾取方式
read(24018, <<Type:8>>) ->
    {ok, Type};

%% 获取下线前组队信息
read(24032, _R) ->
    {ok, []};

%% 获得周围队伍状态
read(24033, <<Count:16, Bin/binary>>) ->
    L = read_arrary(Count, Bin),
    {ok, L};

%%设置队员加入方式
read(24034, <<JoinType:8>>) ->
    {ok, JoinType};

%% 发布招募消息
read(24035, <<Type:8, SubType:16, LowLevel:16, HighLevel:16, Career:8, Leader:8, _L:16, Bin/binary>>) ->
    {ok, [Type, SubType, LowLevel, HighLevel, Career, Leader, Bin]};

%% 获取招募消息
read(24036, _) ->
    {ok, []};

%% 队员投票
read(24038, <<RecordId:32, Res:8>>) ->
    {ok, [RecordId, Res]};

%% 登记副本招募
read(24041, <<Sid:32>>) ->
    {ok, Sid};

%% 注销副本招募
read(24042, _R) ->
    {ok, []};

%% 获取副本招募列表
read(24043, <<Sid:32>>) ->
    {ok, Sid};

%% 获取队伍是否进入副本
read(24045, _R) ->
    {ok, []};

%% 登记我要进入副本
read(24046, <<Sid:32>>) ->
    {ok, Sid};

%% 注销我要进入副本
read(24047, _R) ->
    {ok, []};

%% 获取我要进入副本列表
read(24048, <<Sid:32>>) ->
    {ok, Sid};

%% 登记副本招募(8.29)
read(24049, <<IsNeedFire:8,IsNeedIce:8,IsNeedDrug:8, Lv:16, Att:16, Def:16, Sid:32, CombatPower:32>>) ->
    {ok, [IsNeedFire, IsNeedIce, IsNeedDrug, Lv, Att, Def, Sid, CombatPower]};


%% 获取我要进入副本列表(8.29)
read(24050, _R) ->
    {ok, []};


%% 获取登记副本招募列表(8.29)
read(24051, <<Sid:32>>) ->
    {ok, Sid};

%% 赞成传送到副本区(8.29)
read(24053, _R) ->
    {ok, []};


% 切换线路加入队伍
read(24061, <<PlayerId:32, Line:8>>) ->
    {ok, [PlayerId, Line]};

% 聊天招募队友查询是否进入副本(公共线)
read(24062, <<LeaderId:32>>) ->
    {ok, LeaderId};

%% 更改队员邀请玩家进队设置
read(24064, <<IsAllowMemInvite:8>>) ->
    {ok, IsAllowMemInvite};

%% 获取队伍的坐标信息.
read(24065, _R) ->
    {ok, []};

%% 设置九重天双倍掉落.
read(24066, <<Code:8>>) ->
    {ok, Code};

%% 进入副本投票.
read(24067, <<DungeonID:32>>) ->
    {ok, DungeonID};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%%创建队伍
write(24000, [Res, TeamName, CreateType]) ->
    TeamName1 = list_to_binary(TeamName),
    L = byte_size(TeamName1),
    Data = <<Res:16, L:16, TeamName1/binary, CreateType:8>>,
    {ok, pt:pack(24000, Data)};

%%加入队伍
write(24002, [1, LeaderId]) ->
    Data = <<1:16, LeaderId:32>>,
    {ok, pt:pack(24002, Data)};
write(24002, Res) ->
    Data = <<Res:16, 0:32>>,
    {ok, pt:pack(24002, Data)};

%%向队长发送加入队伍请求
write(24003, [Id, Lv, Career, Realm, Nick]) ->
    Nick1 = list_to_binary(Nick),
    L = byte_size(Nick1),
    Data = <<Id:32, Lv:16, Career:16, Realm:16, L:16, Nick1/binary>>,
    {ok, pt:pack(24003, Data)};

%%队长处理加入队伍请求
write(24004, Res)->
    Data = <<Res:16>>,
    {ok, pt:pack(24004, Data)};

%%离开队伍
write(24005, Res)->
    Data = <<Res:16>>,
    {ok, pt:pack(24005, Data)};

%%邀请加入队伍
write(24006, Res)->
    Data = <<Res:16>>,
    {ok, pt:pack(24006, Data)};

%%向被邀请人发出邀请
write(24007, [Id, Nick, TeamName, Distribution, Lv]) ->
    Nick1 = list_to_binary(Nick),
    NL = byte_size(Nick1),
    TeamName1 = list_to_binary(TeamName),
    TNL = byte_size(TeamName1),
    Data = <<Id:32, NL:16, Nick1/binary, TNL:16, TeamName1/binary, Distribution:8, Lv:16>>,
    {ok, pt:pack(24007, Data)};

%%邀请人邀请进队伍
write(24008, [1, LeaderId]) ->
    Data = <<1:16, LeaderId:32>>,
    {ok, pt:pack(24008, Data)}; 
write(24008, Res) ->
    Data = <<Res:16, 0:32>>,
    {ok, pt:pack(24008, Data)};

%%踢出队员
write(24009, Res) ->
    Data = <<Res:16>>,
    {ok, pt:pack(24009, Data)};

%%向队员发送队伍信息
write(24010, [TeamId, TeamName, Member, Distribution, JoinType, State, IsAllowMemInvite, DoubleDrop]) ->
    TeamName1 = list_to_binary(TeamName),
    TL = byte_size(TeamName1),
    N = length(Member),
    F = fun([Id, Lv, Career, Realm, Nick, Sex, Vip, [Weapon, Cloth | _], Hp, Hp_lim, 
			 Place, Mp, Mp_lim, Image, SceneName, [FWeapon, _], [FArmor, _]]) ->
            Nick1 = list_to_binary(Nick),
            L = byte_size(Nick1),
            SceneName_b = pt:write_string(SceneName),
            <<Id:32, Lv:16, Career:16, Realm:8, L:16, Nick1/binary, Sex:8, Vip:8, 
			  Weapon:32, Cloth:32, Hp:32, Hp_lim:32, Place:8, Mp:32, Mp_lim:32, 
			  Image:8, SceneName_b/binary, FWeapon:32, FArmor:32>>
    end,
    LN = list_to_binary([F(X)||X <- Member]),
    Data1 = <<TeamId:32, TL:16, TeamName1/binary, N:16, LN/binary, Distribution:8, 
			  JoinType:8, State:8, IsAllowMemInvite:8, DoubleDrop:8>>,
    {ok, pt:pack(24010, Data1)};

%%向队员发送有人离队的信息
write(24011, Id) ->
    Data = <<Id:32>>,
    {ok, pt:pack(24011, Data)};

%%向队员发送更换队长的信息
write(24012, Id) ->
    Data = <<Id:32>>,
    {ok, pt:pack(24012, Data)};

%%委任队长
write(24013, Res) ->
    Data = <<Res:16>>,
    {ok, pt:pack(24013, Data)};

%%更改队名
write(24014, Res) ->
    Data = <<Res:16>>,
    {ok, pt:pack(24014, Data)};

%%通知队员队名更改了
write(24015, TeamName) ->
    TeamName1 = list_to_binary(TeamName),
    L = byte_size(TeamName1),
    Data = <<L:16, TeamName1/binary>>,
    {ok, pt:pack(24015, Data)};

%%队伍资料
write(24016, [Res, TeamId, TeamName, Member]) ->
    TeamName1 = list_to_binary(TeamName),
    TL = byte_size(TeamName1),
    N = length(Member),
    F = fun([Id, Lv, Career, Realm, Nick, Sex, Vip, [Weapon, Cloth | _], Hp, Hp_lim, 
			 Place, Mp, Mp_lim, Image, SceneName,  [FWeapon, _], [FArmor, _]]) ->
            Nick1 = list_to_binary(Nick),
            L = byte_size(Nick1),
            SceneName_b = pt:write_string(SceneName),
            <<Id:32, Lv:16, Career:16, Realm:8, L:16, Nick1/binary, Sex:8, 
			  Vip:8, Weapon:32, Cloth:32, Hp:32, Hp_lim:32, Place:8, Mp:32, 
			  Mp_lim:32, Image:8, SceneName_b/binary, FWeapon:32, FArmor:32>>
    end,
    LN = list_to_binary([F(X)||X <- Member]),
    Data1 = <<Res:8, TeamId:32, TL:16, TeamName1/binary, N:16, LN/binary>>,
    {ok, pt:pack(24016, Data1)};

%%通知队员队伍解散
write(24017, []) ->
    {ok, pt:pack(24017, <<>>)};

%% 设置队伍拾取方式
write(24018, [Res, Type]) ->
    {ok, pt:pack(24018, <<Res:8, Type:8>>)};

%%给队伍进入副本信息
write(24030, [Sid, DunName]) ->
    N = byte_size(DunName),
    {ok, pt:pack(24030, <<Sid:32, N:16, DunName/binary>>)};

%%给离线队员进入副本信息
write(24031, Sid) ->
    {ok, pt:pack(24031, <<Sid:32>>)};

%%获得附近队伍状态
write(24033, []) ->
    {ok, pt:pack(24033, <<0:16, <<>>/binary>>)};
write(24033, L) ->
    N = length(L),
    F = fun({Id, Num, JoinType}) ->
            <<Id:32, Num:8, JoinType:8>>
    end,
    R = list_to_binary([F(T) || T <- L]),
    {ok, pt:pack(24033, <<N:16, R/binary>>)};

%%设置队员加入方式
write(24034, Res) ->
    {ok, pt:pack(24034, <<Res:8>>)};

%% 发布招募信息
write(24035, Res) ->
    {ok, pt:pack(24035, <<Res:8>>)};

%% 获取招募信息
write(24036, L) -> 
    N = length(L),
    F = fun({_, {_, Id}, Name, Career, Lv, Type, SubType, LowLv, HighLv, LimCareer, Sex, Leader, Msg}) ->
            NameL = byte_size(Name),
            MsgL = byte_size(Msg),
            <<Id:32, NameL:16, Name/binary, Career:8, Lv:16, Type:8, SubType:16, LowLv:16, HighLv:16, LimCareer:8, Sex:8, Leader:8, MsgL:16, Msg/binary>>
    end,
    Bin = list_to_binary([F(X) || X <- L]),
    Data = <<N:16, Bin/binary>>,
    {ok, pt:pack(24036, Data)};

%% 开启仲裁
write(24037, [Num, Nick, Msg]) ->
    Nick_b = list_to_binary(Nick),
    Msg_b = list_to_binary(Msg),
    NL = byte_size(Nick_b),
    ML = byte_size(Msg_b),
    Data = <<Num:32, NL:16, Nick_b/binary, ML:16, Msg_b/binary>>,
    {ok, pt:pack(24037, Data)};

%% 开始投票
write(24038, Res) ->
    {ok, pt:pack(24038, <<Res:8>>)};

%% 投票结果广播
write(24039, [RecordId, Uid, Res]) ->
    {ok, pt:pack(24039, <<RecordId:32, Uid:32, Res:8>>)};

%% 登记副本招募
write(24041, Res) ->
    {ok, pt:pack(24041, <<Res:8>>)};

%% 注销副本招募
write(24042, Res) ->
    {ok, pt:pack(24042, <<Res:8>>)};

%% 获取副本招募列表
%% write(24043, []) ->
%%     {ok, pt:pack(24043, <<0:16>>)};
%% write(24043, L) ->
%%     N = length(L),
%%     F = fun({_, Id, _Sid, NickName}) ->
%%             Nick_b = list_to_binary(NickName),
%%             NL = byte_size(Nick_b),
%%             {MNum, LeaderLv} = case ets:lookup(?ETS_ONLINE, Id) of
%%                 [] -> {0, 0};
%%                 [R] -> {lib_team:get_mb_num(R#ets_online.pid_team), R#ets_online.lv}
%%             end, 
%%             <<Id:32, NL:16, Nick_b/binary, MNum:8, LeaderLv:16>>
%%     end,
%%     BL = list_to_binary([F(R)||R<-L]),
%%     {ok, pt:pack(24043, <<N:16, BL/binary>>)};

%% 清除右边的副本招募列表
write(24044, []) ->
    {ok, pt:pack(24044, <<>>)};

%% 获取队伍是否进入副本
write(24045, Sid) ->
    {ok, pt:pack(24045, <<Sid:32>>)};

%% 登记我要进入副本
write(24046, Res) ->
    {ok, pt:pack(24046, <<Res:8>>)};

%% 注销我要进入副本
write(24047, Res) ->
    {ok, pt:pack(24047, <<Res:8>>)};

%% 获取我要进入副本列表
write(24048, L) ->
    N = length(L),
    F = fun({_, PlayerId, _, Nick, Sex, Career, Lv}) ->
            NL = byte_size(Nick),
            <<PlayerId:32, NL:16, Nick/binary, Sex:8, Career:8, Lv:8>>
    end,
    BL = list_to_binary([F(X) || X <- L]),
    Data = <<N:16, BL/binary>>,
    {ok, pt:pack(24048, Data)};

%% 登记副本招募
write(24049, Res) -> 
    {ok, pt:pack(24049, <<Res:8>>)};

%% 注销副本招募
write(24050, Res) -> 
    {ok, pt:pack(24050, <<Res:8>>)};

%% 获取副本招募列表
write(24051, L) ->
    N = length(L),
    F = fun({_, Id, Sid, NickName, IsNeedFire, IsNeedIce, IsNeedDrug, Lv, Att, Def, CombatPower, MbNum}) ->
            Nick_b = pt:write_string(NickName),
            <<Id:32, Nick_b/binary, Sid:32, IsNeedFire:8, IsNeedIce:8, IsNeedDrug:8, Lv:16, Att:16, Def:16, CombatPower:32, MbNum:8>>
    end,
    BL = list_to_binary([F(X)||X<-L]),
    {ok, pt:pack(24051, <<N:16, BL/binary>>)};

%% 副本招募完队员进入副本倒计时(8.29)
write(24052, [Sid, SName, Type]) ->
    SName_b = pt:write_string(SName),
    {ok, pt:pack(24052, <<Sid:32, SName_b/binary, Type:8>>)};

%% 告诉队友我在哪里
write(24054, [Mid, SceneName]) ->
    SceneName_b = pt:write_string(SceneName),
    {ok, pt:pack(24054, <<Mid:32, SceneName_b/binary>>)};

% 聊天招募队友查询是否进入副本(公共线)
write(24062, [Res, LeaderId]) ->
    {ok, pt:pack(24062, <<Res:8, LeaderId:32>>)};

% 改变队伍状态
write(24063, State) ->
    {ok, pt:pack(24063, <<State:8>>)};

%% 更改队员邀请玩家进队设置
write(24064, IsAllowMemInvite) ->
    {ok, pt:pack(24064, <<IsAllowMemInvite:8>>)};

%% 获取队伍的坐标信息.
write(24065, TeamLocalList) ->
    Len = length(TeamLocalList),
    FunPackLocal = 
		fun({PlayerId, SceneId, X, Y}) ->
            <<PlayerId:32, SceneId:32, X:32, Y:32>>
    	end,
    BinaryList = list_to_binary([FunPackLocal(X)||X<-TeamLocalList]),
    {ok, pt:pack(24065, <<Len:16, BinaryList/binary>>)};

%% 设置九重天双倍掉落.
write(24066, Code) ->
    {ok, pt:pack(24066, <<Code:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

%% 读取数组
read_arrary(Count, Bin) ->
    read_arrary(Count, Bin, []).
read_arrary(0, _Bin, Result) ->
    Result;
read_arrary(_Count, <<>>, Result) ->
    Result;
read_arrary(Count, <<Bin:32, Rest/binary>>, Result) ->
    case Count =< 0 of
        true->
            read_arrary(0, Bin, Result);
        false ->
            read_arrary(Count-1, Rest, [Bin|Result])
    end.
