%%%--------------------------------------
%%% @Module  : pt_410
%%% @Author  : zhenghehe
%%% @Created : 2010.07.03
%%% @Description: 宠物消息的解包和组包
%%%--------------------------------------
-module(pt_410).
-export([read/2, write/2]).

%%%=========================================================================
%%% 解包函数
%%%=========================================================================

%% -----------------------------------------------------------------
%% 获取宠物信息
%% -----------------------------------------------------------------
read(41001, <<PetId:32>>) ->
    {ok, [PetId]};

%% -----------------------------------------------------------------
%% 获取宠物列表
%% -----------------------------------------------------------------
read(41002, <<PlayerId:32>>) ->
    {ok, [PlayerId]};

%% -----------------------------------------------------------------
%% 宠物放生
%% -----------------------------------------------------------------
read(41004, <<PetId:32>>) ->
    {ok, [PetId]};

%% -----------------------------------------------------------------
%% 宠物改名
%% -----------------------------------------------------------------
read(41005, <<PetId:32, Bin/binary>>) ->
    {PetName, _} = pt:read_string(Bin),
    {ok, [PetId, PetName]};

%% -----------------------------------------------------------------
%% 宠物出战
%% -----------------------------------------------------------------
read(41006, <<PetId:32>>) -> 
    {ok, [PetId]};

%% -----------------------------------------------------------------
%% 宠物休息
%% -----------------------------------------------------------------
read(41007, <<PetId:32>>) ->
    {ok, [PetId]};

%% -----------------------------------------------------------------
%% 升级经验同步
%% -----------------------------------------------------------------
read(41009, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 宠物喂养
%% -----------------------------------------------------------------
read(41010, <<PetId:32, GoodsId:32, GoodsNum:16>>) ->
    case GoodsNum > 0 of
	true ->
	    {ok, [PetId, GoodsId, GoodsNum]};
	false ->
	    {ok, [PetId, GoodsId, 1]}
	end;

%% -----------------------------------------------------------------
%% 快乐值同步
%% -----------------------------------------------------------------
read(41011, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 宠物继承
%% -----------------------------------------------------------------
read(41012, <<PetId1:32, PetId2:32, DeriveFigure:8>>) ->
    {ok, [PetId1, PetId2, DeriveFigure]};

%% -----------------------------------------------------------------
%% 购买宠物栏
%% -----------------------------------------------------------------
read(41013, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 属性还原
%% -----------------------------------------------------------------
read(41014, <<PetId:32, GoodsId:32, GoodsUseNum:16>>) ->
    case GoodsUseNum > 0 of
	true ->
	    {ok, [PetId, GoodsId, GoodsUseNum]};
	false ->
	    {ok, [PetId, GoodsId, 1]}
	end;

%% -----------------------------------------------------------------
%% 宠物成长
%% -----------------------------------------------------------------
read(41015, <<PetId:32>>) ->
    {ok, [PetId]};

%% -----------------------------------------------------------------
%% 宠物展示
%% -----------------------------------------------------------------
read(41016, <<PetId:32, PlayerId:32>>) ->
    {ok, [PetId, PlayerId]};

%% -----------------------------------------------------------------
%% 宠物出战替换
%% -----------------------------------------------------------------
read(41017, <<PetId:32>>) ->
    {ok, [PetId]};

%% -----------------------------------------------------------------
%% 宠物潜能修行
%% -----------------------------------------------------------------
read(41018, <<PetId:32, Type:8>>) ->
    {ok, [PetId, Type]};

%% -----------------------------------------------------------------
%% 宠物砸蛋
%% -----------------------------------------------------------------
read(41019, <<Type:8>>) ->
    {ok, [Type]};

%% -----------------------------------------------------------------
%% 学习技能
%% -----------------------------------------------------------------
read(41020, <<PetId:32, GoodsId:32, GoodsTypeId:32, Num:16, Bin/binary>>) ->
    {Rest, LockList} = pt:read_id_list(Bin, [], Num),
    <<RestNum:16, RestBin/binary>> = Rest,
    StoneList = read_id_num_list(RestBin, [], RestNum),
    {ok, [PetId, GoodsId, GoodsTypeId, LockList, StoneList]};

%% -----------------------------------------------------------------
%% 技能遗忘
%% -----------------------------------------------------------------
read(41021, <<PetId:32, SkillTypeId:32>>) ->
    {ok, [PetId, SkillTypeId]};

%% -----------------------------------------------------------------
%% 宠物还童替换
%% -----------------------------------------------------------------
read(41022, <<PetId:32>>) ->
    {ok, [PetId]};

read(41023, <<PetId:32, PetOwner:32>>) ->
    {ok, [PetId, PetOwner]};
read(41024, _) ->
    {ok, []};
read(41025, _) ->
    {ok, []};
read(41026, _) ->
    {ok, []};
read(41028, _) ->
    {ok, []};
read(41029, <<PetId:32, FigureId:16>>) ->
    {ok, [PetId, FigureId]};
read(41030, <<PetId:32, FigureId:16>>) ->
    {ok, [PetId, FigureId]};

read(41031, <<PetId:32>>) ->
    {ok, [PetId]};
read(41032, _) ->
    {ok, []};
read(41033, <<Type:8,UseBindGold>>) ->
    {ok, [Type,UseBindGold]};
read(41034, <<GoodsTypeId:32, Bind:8, WriteType:8>>) ->
    {ok, [GoodsTypeId, Bind, WriteType]};

read(41035, <<GoodsTypeId:32>>) ->
    {ok, [GoodsTypeId]};

read(41036, _) ->
    {ok, []};

read(41038, <<PetId:32, PlayerId:32>>) ->
    {ok, [PetId, PlayerId]};

read(41039, <<PlayerId:32>>) ->
    {ok, [PlayerId]};

read(41042, _) ->
    {ok, []};

%% 宠物砸蛋
read(41050, _) ->
    {ok, []};

read(41051, _) ->
    {ok, []};
%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================

%% -----------------------------------------------------------------
%% 获取宠物信息
%% -----------------------------------------------------------------
write(41001, [Code, Record]) ->
    Data = <<Code:16, Record/binary>>,
    {ok, pt:pack(41001, Data)};

%% -----------------------------------------------------------------
%% 获取宠物列表
%% -----------------------------------------------------------------
write(41002, [Code, PlayerId, PetMaxNum, RecordNum, Records]) ->
    Data = <<Code:16, PlayerId:32, PetMaxNum:16, RecordNum:16, Records/binary>>,
    {ok, pt:pack(41002, Data)};

%% -----------------------------------------------------------------
%% 宠物孵化
%% -----------------------------------------------------------------
write(41003, [Code, PetId, PetName, GoodsTypeId]) ->
    PetNameLen = byte_size(PetName),
    Data = <<Code:16, PetId:32, PetNameLen:16, PetName/binary, GoodsTypeId:32>>,
    {ok, pt:pack(41003, Data)};

%% -----------------------------------------------------------------
%% 宠物放生
%% -----------------------------------------------------------------
write(41004, [Code, PetId]) ->
    Data = <<Code:16, PetId:32>>,
    {ok, pt:pack(41004, Data)};

%% -----------------------------------------------------------------
%% 宠物改名
%% -----------------------------------------------------------------
write(41005, [Code, PetId, PetName]) ->
    PetNameLen = byte_size(PetName),
    Data = <<Code:16, PetId:32, PetNameLen:16, PetName/binary>>,
    {ok, pt:pack(41005, Data)};

%% -----------------------------------------------------------------
%% 宠物出战
%% -----------------------------------------------------------------
write(41006, [Code, PetId]) ->
    Data = <<Code:16, PetId:32>>,
    {ok, pt:pack(41006, Data)};

%% -----------------------------------------------------------------
%% 宠物休息
%% -----------------------------------------------------------------
write(41007, [Code, PlayerId]) ->
    Data = <<Code:16, PlayerId:32>>,
    {ok, pt:pack(41007, Data)};

%% -----------------------------------------------------------------
%% 宠物升级
%% -----------------------------------------------------------------
write(41008, [PetId, NewLevel, ExpLeft, NewNextLevelExp, NewPetForza,NewPetWit,NewPetAgile,NewPetThew,NewHpLim,NewMpLim,NewAtt,NewDef,NewHit,NewDodge,NewCrit,NewTen,NewForzaAddition,NewWitAddition,NewAgileAddition,NewThewAddition, NewComatPower]) ->
    Data = <<PetId:32, NewLevel:16, ExpLeft:32, NewNextLevelExp:32, NewPetForza:16,NewPetWit:16,NewPetAgile:16,NewPetThew:16,NewHpLim:32,NewMpLim:32,NewAtt:16,NewDef:16,NewHit:16,NewDodge:16,NewCrit:16,NewTen:16,NewForzaAddition:16,NewWitAddition:16,NewAgileAddition:16,NewThewAddition:16, NewComatPower:32>>,
    {ok, pt:pack(41008, Data)};

%% -----------------------------------------------------------------
%% 升级经验同步
%% -----------------------------------------------------------------
write(41009, [Code, PetId, PetLevel, UpgradeExp]) ->
    Data = <<Code:16, PetId:32, PetLevel:16, UpgradeExp:32>>,
    {ok, pt:pack(41009, Data)};

%% -----------------------------------------------------------------
%% 宠物喂养
%% -----------------------------------------------------------------
write(41010, [Code, PetId, Strength]) ->
    Data = <<Code:16, PetId:32, Strength:16>>,
    {ok, pt:pack(41010, Data)};

%% -----------------------------------------------------------------
%% 快乐值同步
%% -----------------------------------------------------------------
write(41011, [Code, PetId, Strength, ChangeFlag]) ->
    Data = <<Code:16, PetId:32, Strength:16, ChangeFlag:8>>,
    {ok, pt:pack(41011, Data)};

%% -----------------------------------------------------------------
%% 宠物继承
%% -----------------------------------------------------------------
write(41012, [Code, PetId1, PetId2]) ->
    Data = <<Code:16, PetId1:32, PetId2:32>>,
    {ok, pt:pack(41012, Data)};

%% -----------------------------------------------------------------
%% 购买宠物栏
%% -----------------------------------------------------------------
write(41013, [Code, PetMaxNum]) ->
    Data = <<Code:16, PetMaxNum:16>>,
    {ok, pt:pack(41013, Data)};

%% -----------------------------------------------------------------
%% 属性还童
%% -----------------------------------------------------------------
write(41014, [Code, PetId, NewForza, NewWit, NewAgile, NewThew]) ->
    Data = <<Code:16, PetId:32, NewForza:16, NewWit:16, NewAgile:16, NewThew:16>>,
    {ok, pt:pack(41014, Data)};

%% -----------------------------------------------------------------
%% 宠物成长
%% -----------------------------------------------------------------
write(41015, [Result, PetId, Again, Msg, TenMul, UpGradePhase, Exp, NextCost, BatchGrowCost]) ->
    MsgLen = byte_size(Msg),
    Data = <<Result:16, PetId:32, Again:8, MsgLen:16, Msg/binary, TenMul:8, UpGradePhase:8, Exp:16, NextCost:16, BatchGrowCost:16>>,
    {ok, pt:pack(41015, Data)};

%% -----------------------------------------------------------------
%% 宠物展示
%% -----------------------------------------------------------------
write(41016, [Code, Record]) ->
    Data = <<Code:16, Record/binary>>,
    {ok, pt:pack(41016, Data)};

%% -----------------------------------------------------------------
%% 宠物出战替换
%% -----------------------------------------------------------------
write(41017, [Code, PetId]) ->
    Data = <<Code:16, PetId:32>>,
    {ok, pt:pack(41017, Data)};

%% -----------------------------------------------------------------
%% 宠物潜能修行
%% -----------------------------------------------------------------
write(41018, [Result, PetId, TypeNumExpArray, TypeExpArray, PotentialCost, BatchPracticeCost, IsMed, Exp, IsBatch, LvUpList]) ->
    TNEBinList = [<<TNEATypeId:8, TNEANum:8, TNEAExp:32>>|| {TNEATypeId, TNEANum, TNEAExp} <- TypeNumExpArray],
    TEBinList = [<<TEATypeId:8, TEAExp:32>> || {TEATypeId, TEAExp} <- TypeExpArray],
    LvUpBinList = [<<UpTypeId:8>> || UpTypeId <- LvUpList],
    TypeNumExpArrayLen = length(TNEBinList),
    TypeNumExpArrayBin = list_to_binary(TNEBinList),
    TypeExpArrayLen = length(TEBinList),
    TypeExpArrayBin = list_to_binary(TEBinList),
    LvUpArrayLen = length(LvUpBinList),
    LvUpArrayBin = list_to_binary(LvUpBinList),
    Data = <<PetId:32, TypeNumExpArrayLen:16, TypeNumExpArrayBin/binary, PotentialCost:16, BatchPracticeCost:16, IsMed:8, Exp:16, Result:16, TypeExpArrayLen:16, TypeExpArrayBin/binary, IsBatch:8, LvUpArrayLen:16, LvUpArrayBin/binary>>,
    {ok, pt:pack(41018, Data)};

%% -----------------------------------------------------------------
%% 宠物砸蛋
%% -----------------------------------------------------------------
write(41019, [Code, List]) ->
    {Len, Bin} = pack_good_list(List),
    {ok, pt:pack(41019, <<Code:8, Len:16, Bin/binary>>)};

%% -----------------------------------------------------------------
%% 学习技能
%% -----------------------------------------------------------------
write(41020, [Result, PetId, OldSkillId, OldSkillTypeId, NewSkillId, NewSkillTypeId]) ->
    Data = <<Result:16, PetId:32, OldSkillId:32, OldSkillTypeId:32, NewSkillId:32, NewSkillTypeId:32>>,
    {ok, pt:pack(41020, Data)};

%% -----------------------------------------------------------------
%% 技能遗忘
%% -----------------------------------------------------------------
write(41021, [Code, PetId, SkillTypeId, NewSkills]) ->
    RecordsSkill = lists:map(fun lib_pet:parse_pet_skill/1, NewSkills), 
    RecordsSkillBin = list_to_binary(RecordsSkill),
    RecordsSkillNum = length(RecordsSkill),
    Data = <<Code:16, PetId:32, SkillTypeId:32, RecordsSkillNum:16, RecordsSkillBin/binary>>,
    {ok, pt:pack(41021, Data)};

%% -----------------------------------------------------------------
%% 还童替换
%% -----------------------------------------------------------------
write(41022, [Code, PetId]) ->
    Data = <<Code:16, PetId:32>>,
    {ok, pt:pack(41022, Data)};
write(41023, [Result, Bin]) ->
    Data = <<Result:16, Bin/binary>>,
    {ok, pt:pack(41023, Data)};
write(41024, []) ->
    Data = <<>>,
    {ok, pt:pack(41024, Data)};
write(41025, [PetId, HitBefore, HitAfter, IsGet]) ->
    Data = <<PetId:32, HitBefore:16, HitAfter:16, IsGet:8>>,
    {ok, pt:pack(41025, Data)};
write(41026, [Result]) ->
    Data = <<Result:16>>,
    {ok, pt:pack(41026, Data)};
write(41027, [Result,PetId,Value]) ->
    Data = <<Result:16,PetId:32,Value:16>>,
    {ok, pt:pack(41027, Data)};
write(41028, [Result, FigureVal, List, ChangePetId]) ->
    BinList = [<<GoodsTypeId:32, FigureId:16, ChangeFlag:8, ActivateFlag:8, LeftTime:32>> || {GoodsTypeId, FigureId, ChangeFlag, ActivateFlag, LeftTime} <- List],
    Len = length(BinList),
    Bin = list_to_binary(BinList),
    Data = <<Result:16, FigureVal:32, Len:16,Bin/binary, ChangePetId:32>>,
    {ok, pt:pack(41028, Data)};
write(41029, [Result,PetId,FigureId]) ->
    Data = <<Result:16,PetId:32,FigureId:16>>,
    {ok, pt:pack(41029, Data)};
write(41030, [Result]) ->
    Data = <<Result:16>>,
    {ok, pt:pack(41030, Data)};

write(41031, [Result, PetId, UpGradePhase, NextCost, BatchGrowCost, ExpList]) ->
    RealExpList = [<<Val:16>> || {_, Val} <- ExpList],
    Len = length(RealExpList),
    Bin = list_to_binary(RealExpList),
    Data = <<Result:16, PetId:32, UpGradePhase:8, NextCost:16, BatchGrowCost:16, Len:16, Bin/binary>>,
    {ok, pt:pack(41031, Data)};

%% BoxList: [{GoodsTypeId, Bind},...]
write(41032, [LuckyVal, BlessVal, FreeCount, BoxList]) ->
    RealBoxList = [<<GoodsTypeId:32, Bind:8>> || {GoodsTypeId, Bind} <- BoxList],
    BoxLen = length(RealBoxList),
    BoxBin = list_to_binary(RealBoxList),
    Data = <<LuckyVal:32, BlessVal:32, FreeCount:8, BoxLen:16, BoxBin/binary>>,
    {ok, pt:pack(41032, Data)};
write(41033, [Result]) ->
    Data = <<Result:16>>,
    {ok, pt:pack(41033, Data)};
write(41034, [Result, GoodsTypeId]) ->
    Data = <<Result:16, GoodsTypeId:32>>,
    {ok, pt:pack(41034, Data)};
write(41035, [Result, GoodsTypeId]) ->
    Data = <<Result:16, GoodsTypeId:32>>,
    {ok, pt:pack(41035, Data)};
write(41036, [AllNotice, OneNotice]) ->
    OneNoticeList = [<<Time:32, GoodsTypeId:32>> || {_, _, _, GoodsTypeId, Time} <- OneNotice],
    OneLen = length(OneNoticeList),
    OneBin = list_to_binary(OneNoticeList),
    AllNoticeList = lists:map(fun(X) ->
				      {PlayerId, NickName, Realm, GoodsTypeId, _} = X,
				      NickNameBin = pt:write_string(NickName),
				      <<PlayerId:32, NickNameBin/binary, Realm:8, GoodsTypeId:32>>
			      end, AllNotice),
    AllLen = length(AllNoticeList),
    AllBin = list_to_binary(AllNoticeList),
    Data = <<OneLen:16, OneBin/binary, AllLen:16, AllBin/binary>>,
    {ok, pt:pack(41036, Data)};
write(41037, [PetId, Aptitude, PetName, Figure, Growth, Quality]) ->
    PetNameBin = pt:write_string(PetName),
    Data = <<PetId:32, Aptitude:16, PetNameBin/binary, Figure:16, Growth:32, Quality:8>>,
    {ok, pt:pack(41037, Data)};
write(41038, [Result, Bin]) ->
    Data = <<Result:16, Bin/binary>>,
    {ok, pt:pack(41038, Data)};
write(41039, [Result, Bin]) ->
    Data = <<Result:16, Bin/binary>>,
    {ok, pt:pack(41039, Data)};
write(41040, [Code, PetId, PetLevel, UpgradeExp]) ->
    Data = <<Code:8, PetId:32, PetLevel:16, UpgradeExp:32>>,
    {ok, pt:pack(41040, Data)};

write(41042, [GrowFree, PotentialFree]) ->
    Data = <<GrowFree:8, PotentialFree:8>>,
    {ok, pt:pack(41042, Data)};

%% 宠物砸蛋
write(41050, [EggList]) ->
    Len = length(EggList),
    Bin = list_to_binary(EggList),
    {ok, pt:pack(41050, <<Len:16, Bin/binary>>)};

%% 砸蛋页面滚动数据
write(41051, [Num, NoticeList]) ->
    Len = length(NoticeList),
    Bin = list_to_binary(NoticeList),
    {ok, pt:pack(41051, <<Num:8, Len:16, Bin/binary>>)};

%%　全屏公告
write(41052, [Id, Realm, NickName, Type, NoticeList]) ->
    {Len, Bin} = pack_notice_good_list(NoticeList),
    BName = pt:wirte_string(NickName),
    {ok, pt:pack(41052, <<Id:32, Realm:8, BName/binary, Type:8, Len:16, Bin/binary>>)};


%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

read_id_num_list(<<Id:32, Num:16, Rest/binary>>, List, ListNum) when ListNum > 0 ->
    NewList = [{Id, Num} | List],
    read_id_num_list(Rest, NewList, ListNum - 1);
read_id_num_list(_, List, _) -> List.

%% 公告物品列表
pack_notice_good_list(NoticeList)->
    Len = length(NoticeList),
    List = lists:map(fun(GoodId)-> <<GoodId:32>> end, NoticeList),
    {Len, list_to_binary(List)}.

pack_good_list(List) ->
    Len = length(List),
    List1 = lists:map(fun({goods, GoodId, _Num, _Bind})-> <<GoodId:32>> end, List),
    {Len, list_to_binary(List1)}.

