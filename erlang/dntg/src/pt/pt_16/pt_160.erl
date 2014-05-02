%% %% ---------------------------------------------------------
%% %% Author:  xyj
%% %% Email:   156702030@qq.com
%% %% Created: 2012-5-3
%% %% Description: 坐骑模块
%% %% --------------------------------------------------------
-module(pt_160).
-export([read/2, write/2]).
-include("mount.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%

%% 获取坐骑列表
read(16000, _R) ->
    {ok, mount_list};

%% 获取坐骑详细信息
read(16001, <<MountId:32>>) ->
    {ok, MountId};

%% 乘上坐骑
read(16002, <<MountId:32>>) ->
    {ok, MountId};

%% 离开坐骑
read(16003, <<MountId:32>>) ->
    {ok, MountId};

%% 强化
read(16006, <<MountId:32, StoneId:32, LuckyId:32>>) ->
    {ok, [MountId, StoneId, LuckyId]};

%% 回收坐骑
read(16007, <<MountId:32>>) ->
    {ok, MountId};

%% 坐骑卡使用
read(16008, <<GoodsId:32>>) ->
    {ok, GoodsId};

%% 坐骑出战
read(16009, <<Mount_id:32>>) ->
    {ok, Mount_id};

%% 坐骑休息
read(16010, <<Mount_id:32>>) ->
    {ok, Mount_id};

%% 获取别人坐骑详细信息
read(16011, <<Role_id:32, Mount_id:32>>) ->
    {ok, [Role_id, Mount_id]};


%% 获取别人出战坐骑
read(16012, <<Role_id:32>>) ->
    {ok, Role_id};

%% 进阶
read(16015, <<MountId:32, Num:16, Bin/binary>>) ->
    {_, RuneList} = pt:read_id_num_list(Bin, [], Num),
    {ok, [MountId, RuneList]};

%% 升星
read(16016, <<MountId:32, Num:16, Bin/binary>>) ->
    {_, RuneList} = pt:read_id_num_list(Bin, [], Num),
    {ok, [MountId, RuneList]};

%% %% 资质
%% read(16017, <<MountId:32, Num:16, Bin/binary>>) ->
%%     {_, StoneList} = pt:read_id_num_list(Bin, [], Num),
%%     {ok, [MountId, StoneList]};

%% 资质
read(16017, <<MountId:32, Type:8, Coin:32, Num:16, Bin/binary>>) ->
    {_, StoneList} = pt:read_id_num_list(Bin, [], Num),
    {ok, [MountId, Type, Coin, StoneList]};

%% 进阶幻化列表
read(16018, <<MountId:32>>) ->
    {ok, MountId};

%% 进阶幻化
read(16019, <<MountId:32, Figure:32>>) ->
    {ok, [MountId, Figure]};

% 飞行幻化列表
read(16020, <<MountId:32>>) ->
    {ok, MountId};

% 飞行幻化
read(16021, <<MountId:32, FlyId:32>>) ->
    {ok, [MountId, FlyId]};

% 飞行
read(16022, <<MountId:32, Fly:8>>) ->
    {ok, [MountId, Fly]};

% 准备提升资质
read(16023, _R) ->
    {ok, ready};

read(16025, <<PlayerId:32, MountId:32>>) ->
    {ok, [PlayerId, MountId]};

% 查看别人坐骑
read(16030, <<PlayerId:32>>) ->
    {ok, PlayerId};

%% 取消幻化
read(16031, <<MountId:32>>) ->
    {ok, MountId};

%% 查看资质和信息信息
read(16032, <<MountId:32>>) ->
    {ok, MountId};

%% 资质替换还是保留
read(16033, <<MountId:32, Type:8>>) ->
    {ok, [MountId, Type]};

%% 切换灵犀光效id
read(16034, <<MountId:32, LingXiGxId:8>>) ->
    {ok, [MountId, LingXiGxId]};

read(16035, <<MountId:32>>) ->
    {ok, MountId};

read(_Cmd, _R) ->
    {error, nomatck}.

%% 服务器 -> 客户端
%% 坐骑列表
write(16000, [Mount_lim, MountList]) ->
    ListNum = length(MountList),
    F = fun(Info) ->
                Mount_id = Info#ets_mount.id,
                Type = Info#ets_mount.type_id,
                Figure = Info#ets_mount.figure,
                Status = Info#ets_mount.status,
                Name = pt:write_string(Info#ets_mount.name),
                %% Stren = Info#ets_mount.stren,
                %% <<Mount_id:32, Figure:32, Status:8, Name/binary, Stren:8, Type:32>>
                <<Mount_id:32, Figure:32, Status:8, Name/binary, Type:32>>
        end,
    ListBin = list_to_binary(lists:map(F, MountList)),
    {ok, pt:pack(16000, <<Mount_lim:16, ListNum:16, ListBin/binary>>)};

%% 获取坐骑详细信息
write(16001, [Code, Mount, BaseSpeed, LimStar, LimStarValue,  NextLevel, NextName1, NextFigure, NextCombatPower, GoodId, Num]) ->
    %% io:format("~p ~p Code:~p~n", [?MODULE, ?LINE, Code]),
    MountId = Mount#ets_mount.id,
    TypeId = Mount#ets_mount.type_id,
    Name = case Mount#ets_mount.name of
               <<>> ->
                   pt:write_string(data_goods_type:get_name(TypeId));
               _ ->
                   %%　pt:write_string(Mount#ets_mount.name)
                   pt:write_string(data_goods_type:get_name(TypeId))
           end,
    Speed = round((Mount#ets_mount.speed / BaseSpeed) * 100),
    %% io:format("~p ~p Speed:~p~n", [?MODULE, ?LINE, Speed]),
    Level = round(Mount#ets_mount.level),
    FigureId = Mount#ets_mount.figure,
    Status = Mount#ets_mount.status,
    CombatPower = Mount#ets_mount.combat_power,
    Star = Mount#ets_mount.star,
    StarValue = Mount#ets_mount.star_value,
    AllAttr = Mount#ets_mount.attribute,
    %% io:format("~p ~p LimStar:~p, LimStarValue:~p, Star:~p, StarValue:~p~nAllAttr:~p~n", [?MODULE, ?LINE, LimStar, LimStarValue, Star, StarValue, AllAttr]),
    {Len, Bin} = pack_attr_to_bin(AllAttr),
    NextName = pt:write_string(NextName1),
    %% io:format("~p ~p Name:~p~n", [?MODULE, ?LINE, Name]),
    %% io:format("~p ~p NextName:~p~n", [?MODULE, ?LINE, NextName]),
    BinData = <<Code:8, MountId:32, Name/binary, Speed:16, Level:8, TypeId:32, FigureId:32, Status:8, CombatPower:32, LimStar:8, Star:8, LimStarValue:32, StarValue:32, NextLevel:8, NextName/binary, NextFigure:32, NextCombatPower:32, GoodId:32, Num:8, Len:16, Bin/binary>>,
    {ok, pt:pack(16001, BinData, 1)};

%% 乘上坐骑
write(16002, [Res, Mount]) ->
    Mount_id = Mount#ets_mount.id,
    Figure = Mount#ets_mount.figure,
    {ok, pt:pack(16002, <<Res:16, Mount_id:32, Figure:32>>)};

%% 离开坐骑
write(16003, [Res, Mount_id]) ->
    {ok, pt:pack(16003, <<Res:16, Mount_id:32>>)};

%% 强化坐骑
write(16006, [Res, Mount_id, Mount]) ->
    NewFigure = Mount#ets_mount.figure,
    NewStren = Mount#ets_mount.stren,
    NewStrenRatio = Mount#ets_mount.stren_ratio,
    NewSpeed = Mount#ets_mount.speed,
    Name = pt:write_string(Mount#ets_mount.name),
    [Hp, Att, Hit, Crit, Fire, _Ice, _Drug] = Mount#ets_mount.attribute,
    Combat_power = Mount#ets_mount.combat_power,
    {ok, pt:pack(16006, <<Res:16, Mount_id:32, NewFigure:32, NewStren:8, NewStrenRatio:16, NewSpeed:16, Name/binary, Hp:16, Att:16, Hit:16, Crit:16, Fire:16, Combat_power:16>>)};

%% 回收坐骑
write(16007, [Res, MountId]) ->
    {ok, pt:pack(16007, <<Res:16, MountId:32>>)};

%% 坐骑卡使用
write(16008, [Res, Mount_id]) ->
    {ok, pt:pack(16008, <<Res:16, Mount_id:32>>)};

%% 坐骑出战
write(16009, [Res, Mount, OldMount_id]) ->
    Mount_id = Mount#ets_mount.id,
    Figure = Mount#ets_mount.figure,
    {ok, pt:pack(16009, <<Res:16, OldMount_id:32, Mount_id:32, Figure:32>>)};

%% 坐骑休息
write(16010, [Res, Mount_id]) ->
    {ok, pt:pack(16010, <<Res:16, Mount_id:32>>)};

%% 获取别人坐骑详细信息
write(16011, [Res, Mount]) ->
    Mount_id = Mount#ets_mount.id,
    Name = pt:write_string(Mount#ets_mount.name),
    Figure = Mount#ets_mount.figure,
    Stren = Mount#ets_mount.stren,
    Speed = Mount#ets_mount.speed,
    Combat_power = Mount#ets_mount.combat_power,
    {ok, pt:pack(16011, <<Res:16, Mount_id:32, Name/binary, Figure:32, Stren:8, Speed:16, Combat_power:16>>)};

%% 获取别人出战坐骑
write(16012, [Res, Mount]) ->
    Mount_id = Mount#ets_mount.id,
    Name = pt:write_string(Mount#ets_mount.name),
    Figure = Mount#ets_mount.figure,
    Stren = Mount#ets_mount.stren,
    Speed = Mount#ets_mount.speed,
    {ok, pt:pack(16012, <<Res:16, Mount_id:32, Name/binary, Figure:32, Stren:8, Speed:16>>)};

%% 坐骑进阶升星操作
write(16015, [Code, MountId, Star, StarValue]) ->
    %% io:format("~p ~p Code,MountId,Star,StarValue:~p~n",[?MODULE, ?LINE, [Code, MountId, Star, StarValue]]),
    {ok, pt:pack(16015, <<Code:8, MountId:32, Star:8, StarValue:32>>)};

%% write(16015, [Res, MountId, UpValue]) ->
%%     {ok, pt:pack(16015, <<Res:16, MountId:32, UpValue:32>>)};

write(16016, [Res, FlyId, StarValue]) ->
    {ok, pt:pack(16016, <<Res:16, FlyId:32, StarValue:32>>)};

%% write(16017, [Res, Quality, QualityValue]) ->
%%     {ok, pt:pack(16017, <<Res:16, Quality:32, QualityValue:32>>)};

%% 新版资质培养操作
write(16017, [Code, MountId, TotalStarNum, LessTime, QualityAttr]) ->
    {Len, Bin} = pack_quality_attr_to_bin1(QualityAttr),
    {ok, pt:pack(16017, <<Code:8, MountId:32, TotalStarNum:16, LessTime:8, Len:16, Bin/binary>>)};

%% write(16018, [Res, List, MountType]) ->
%%     Len = length(List),
%%     F = fun(Upgrade) ->
%%             if
%%                 is_record(Upgrade, upgrade_change) =:= true ->
%%                     TypeId = Upgrade#upgrade_change.type_id,
%%                     State = Upgrade#upgrade_change.state,
%%                     Time = Upgrade#upgrade_change.time,
%%                     <<TypeId:32, State:8, Time:32>>;
%%                 true ->
%%                     <<0:32, 0:8, 0:32>>
%%             end
%%     end,
%%     ListBin = list_to_binary(lists:map(F, List)),
%%     {ok, pt:pack(16018, <<Res:16, MountType:32, Len:16, ListBin/binary>>)};

%%　幻化形象信息和属性
write(16018, [Code, FigureId, FigureList, AttrList]) ->
    {FLen, FBin} = pact_figure_list_to_bin(FigureList),
    {ALen, ABin} = pack_attr_to_bin(AttrList),
    {ok, pt:pack(16018, <<Code:8, FigureId:32, FLen:16, FBin/binary,  ALen:16, ABin/binary>>)};

%% 坐骑幻化
write(16019, [Code, NewFigure]) ->
    {ok, pt:pack(16019, <<Code:8, NewFigure:32>>)};


write(16020, [Res, List, FlyType]) ->
    Len = length(List),
    F = fun(TypeId) ->
                <<TypeId:32>>
        end,
    ListBin = list_to_binary(lists:map(F, List)),
    {ok, pt:pack(16018, <<Res:16, FlyType:32, Len:16, ListBin/binary>>)};

write(16021, Res) ->
    {ok, pt:pack(16021, <<Res:16>>)};

write(16022, [Res, FlyId]) ->
    {ok, pt:pack(16022, <<Res:16, FlyId:32>>)};

write(16025, [Res, Mount]) ->
    Stren = Mount#ets_mount.stren,
    Quality = Mount#ets_mount.quality,
    Speed = Mount#ets_mount.speed,
    Power = Mount#ets_mount.combat_power,
    Type = Mount#ets_mount.type_id,
    Level = Mount#ets_mount.level,
    {ok, pt:pack(16025, <<Res:16, Stren:16, Quality:16, Speed:16, Power:32,
                          Type:32, Level:16>>)};

%% 获取坐骑详细信息
write(16030, [Res, Mount, BaseSpeed]) ->
    case Res of
        1 ->
            Mount_id = Mount#ets_mount.id,
            Type_id = Mount#ets_mount.type_id,
            Figure = Mount#ets_mount.figure,
            Stren = Mount#ets_mount.stren,
            StrenRadio = Mount#ets_mount.stren_ratio,
            case BaseSpeed of
                0 ->
                    Speed = Mount#ets_mount.speed;
                _ ->
                    Speed = round((Mount#ets_mount.speed / BaseSpeed) * 100)
            end,
            
            [Hp, Att, Hit, Crit, Fire1, Ice1, Drug1] = Mount#ets_mount.attribute,
            Fire = round(Fire1), 
            Ice = round(Ice1), 
            Drug = round(Drug1),
            Combat_power = Mount#ets_mount.combat_power,
            Status = Mount#ets_mount.status,
            Name = pt:write_string(Mount#ets_mount.name),
            AttPer = Mount#ets_mount.att_per,
            case Mount#ets_mount.attribute2 =/= [] of
                true ->
                    [Mp1, Def1, Dodge1, Ten1, HpPer1] = Mount#ets_mount.attribute2,
                    Mp = round(Mp1),
                    Def = round(Def1),
                    Dodge = round(Dodge1),
                    Ten = round(Ten1),
                    HpPer = round(HpPer1);
                false ->
                    Mp = 0, 
                    Def = 0, 
                    Dodge = 0, 
                    Ten = 0, 
                    HpPer = 0
            end,
            Level = round(Mount#ets_mount.level),
            Quality = Mount#ets_mount.quality,
            Point = Mount#ets_mount.point,
            QualityValue = Mount#ets_mount.quality_value,
            {ok, pt:pack(16030, <<Res:8, Mount_id:32, Figure:32, Stren:8,Speed:16,
                                  Hp:16, Att:16, Hit:16, Crit:16, 0:16, Combat_power:16, Status:8,
                                  Name/binary, Type_id:32, StrenRadio:16, AttPer:8, Mp:16, Def:16, 
                                  Dodge:16, Ten:16, HpPer:8, Fire:16, Ice:16, Drug:16, Level:16, 0:16,
                                  Quality:16, Point:16, QualityValue:32>>)};
        _ ->
            Default = <<0:8, 0:32, 0:32, 0:8,0:16,
                        0:16, 0:16, 0:16, 0:16, 0:16, 0:16, 0:8,
                        <<>>/binary, 0:32, 0:16, 0:8, 0:16, 0:16, 
                        0:16, 0:16, 0:8, 0:16, 0:16, 0:16, 0:16, 0:16,
                        0:16, 0:16, 0:32>>,
            {ok, pt:pack(16030, Default)}
    end;

%% 取消幻化
write(16031, [Res, Figure]) ->
    {ok, pt:pack(16031, <<Res:16, Figure:32>>)};

%% 资质和灵犀信息显示
write(16032, [Code,Coin,GoodId,Num,QualityLv,LessTime,TotalStarNum,QualityAttr,LingXiNum,LingXiLV,LingXiGXId,LingXiAttr,LightEffLsit])->
    {QLen, QBin} = pack_quality_attr_to_bin(QualityAttr),
    {LLen, LBin} = pack_lingxi_attr_to_bin(LingXiAttr),
    {GLen, GBin} = pack_lingxi_gx_id_bin(LightEffLsit),
    BinData = <<Code:8, Coin:32, GoodId:32, Num:8, QualityLv:8, LessTime:8, TotalStarNum:16, QLen:16, QBin/binary, LingXiNum:32, LingXiLV:8, LingXiGXId:32, LLen:16, LBin/binary, GLen:16, GBin/binary>>,
    {ok, pt:pack(16032,BinData,1)};

%% 资质替换或保留操作
write(16033, [Code, Type, QualityLv]) ->
    {ok, pt:pack(16033, <<Code:8, Type:8, QualityLv:8>>)};

%% 切换光效操作 
write(16034, [Code, LingXiGxId]) ->
    {ok, pt:pack(16034, <<Code:8, LingXiGxId:32>>)};

%% 坐骑45级前的进阶数据协议(玩家45级之后走16001)
write(16035, [Code, Mount, FigureList, BaseSpeed]) ->
    MountId = Mount#ets_mount.id,
    TypeId = Mount#ets_mount.type_id,
    Name = case Mount#ets_mount.name of
               <<>> ->
                   pt:write_string(data_goods_type:get_name(TypeId));
               _ ->
                   pt:write_string(data_goods_type:get_name(TypeId))
                   %% pt:write_string(Mount#ets_mount.name)
           end,
    %% io:format("~p ~p Name:~p~n", [?MODULE, ?LINE, Name]),
    Speed = round((Mount#ets_mount.speed / BaseSpeed) * 100),
    %% io:format("~p ~p Speed:~p~n", [?MODULE, ?LINE, Speed]),
    Level = round(Mount#ets_mount.level),
    FigureId = Mount#ets_mount.figure,
    Status = Mount#ets_mount.status,
    CombatPower = Mount#ets_mount.combat_power,
    AllAttr = Mount#ets_mount.attribute,
    {ALen, ABin} = pack_attr_to_bin(AllAttr),
    {FLen, FBin} = pact_figure_list_to_bin1(FigureList),
    %% io:format("~p ~p Level:~p, FigureId:~p,ALen:~p, FLen:~p~n", [?MODULE, ?LINE, Level, FigureId, ALen, FLen]),
    {ok, pt:pack(16035, <<Code:8, MountId:32, Name/binary, Speed:16, Level:8, FigureId:32, Status:8, CombatPower:32, ALen:16, ABin/binary, FLen:16, FBin/binary>>)};


write(_Cmd, _Bin) ->
    {ok, pt:pack(0, <<>>)}.



%%===========================================内部数组组装方法===================================================
pack_attr_to_bin(AttrList) ->
    Len = length(AttrList),
    BinList = lists:map(fun({Type, Value})->
                                <<Type:8, Value:32>>
                        end,  AttrList),
    {Len, list_to_binary(BinList)}.


pact_figure_list_to_bin(FigureList)->
    Len = length(FigureList),
    BinList = lists:map(fun({FigureId, State, Time, Type} )->
                                <<FigureId:32, State:8, Time:32, Type:8>>
                        end,  FigureList),
    {Len, list_to_binary(BinList)}.

pact_figure_list_to_bin1(FigureList)->
    Len = length(FigureList),
    BinList = lists:map(fun({FigureId, State, Time} )->
                                <<FigureId:32, State:8, Time:32>>
                        end,  FigureList),
    {Len, list_to_binary(BinList)}.


pack_quality_attr_to_bin(QualityAttr) ->
    Len = length(QualityAttr),
    BinList = lists:map(fun({Type, Value, StarNum} )->
                                <<Type:8, Value:32, StarNum:16>>
                        end,  QualityAttr),
    {Len, list_to_binary(BinList)}.


pack_quality_attr_to_bin1(QualityAttr) ->
    Len = length(QualityAttr),
    BinList = lists:map(fun({Type, Value, StarNum, AddOrCut} )->
                                <<Type:8, Value:32, StarNum:16, AddOrCut:8>>
                        end,  QualityAttr),
    {Len, list_to_binary(BinList)}.

pack_lingxi_attr_to_bin(LingXiAttr)->
    Len = length(LingXiAttr),
    BinList = lists:map(fun({Type, Value, LimValue} )->
                                <<Type:8, Value:32, LimValue:32>>
                        end,  LingXiAttr),
    {Len, list_to_binary(BinList)}.

pack_lingxi_gx_id_bin(LightEffLsit)->
    Len = length(LightEffLsit),
    BinList = lists:map(fun(Id)->
                                <<Id:32>>
                        end, LightEffLsit),
    {Len, list_to_binary(BinList)}.
