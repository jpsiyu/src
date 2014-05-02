%%%---------------------------------------------
%%% @Module  : pt_410_c
%%% @Author  : zhenghehe
%%% @Created : 2012.01.18
%%% @Description: 宠物系统测试客户端组包解包
%%%---------------------------------------------
-module(pt_410_c).
-compile(export_all).

write(41001, [PetId]) ->
    Data = <<PetId:32>>,
    {ok, pt:pack(41001, Data)};
write(41002, [PlayerId]) ->
    Data = <<PlayerId:32>>,
    {ok, pt:pack(41002, Data)};

write(41003, [GoodsId, GoodsUseNum]) ->
    Data = <<GoodsId:32, GoodsUseNum:16>>,
    {ok, pt:pack(41003, Data)};
write(41004, [PetId]) ->
    Data = <<PetId:32>>,
    {ok, pt:pack(41004, Data)};
write(41005, [PetId, NewPetName]) ->
    NewPetNameBin = pt:write_string(NewPetName),
    Data = <<PetId:32, NewPetNameBin/binary>>,
    {ok, pt:pack(41005, Data)};
write(41006, [PetId]) ->
    Data = <<PetId:32>>,
    {ok, pt:pack(41006, Data)};
write(41007, [PetId]) ->
    Data = <<PetId:32>>,
    {ok, pt:pack(41007, Data)};
write(41008, [PetId]) ->
    Data = <<PetId:32>>,
    {ok, pt:pack(41008, Data)};
write(41016, [PetId, GoodsId, GoodsUseNum]) ->
    Data = <<PetId:32, GoodsId:32, GoodsUseNum:16>>,
    {ok, pt:pack(41016, Data)};
write(41017, [PetId]) ->
    Data = <<PetId:32>>,
    {ok, pt:pack(41017, Data)};
write(41022, [PetId, GoodsId, GoodsUseNum]) ->
    Data = <<PetId:32, GoodsId:32, GoodsUseNum:16>>,
    {ok, pt:pack(41022, Data)};
write(41030, [PetId, NewFigure]) ->
    Data = <<PetId:32, NewFigure:16>>,
    {ok, pt:pack(41030, Data)};
write(24000, [TeamName]) ->
	Data = pt:write_string(TeamName),
	{ok, pt:pack(24000, Data)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

read(41001, Bin) ->
    <<Error:16, Bin1/binary>> = Bin,
    [Pet] = parse_pet_list(1, Bin1, []),
    {Error, Pet};
read(41002, Bin) ->
    <<Error:16, PlayerId:32, MaxPetNum:16, RecordNum:16, Bin1/binary>> = Bin,
    PetList = parse_pet_list(RecordNum, Bin1, []),
    {Error, PlayerId, MaxPetNum, RecordNum, PetList};
read(41003, Bin) ->
    <<Error:16, PetId:32, Bin1/binary>> = Bin,
    {PetName, Bin2} = pt:read_string(Bin1),
    <<GoodsTypeId:32>> = Bin2,
    {Error, PetId, PetName, GoodsTypeId};
read(41004, Bin) ->
    <<Error:16, PetId:32>> = Bin,
    {Error, PetId};
read(41005, Bin) ->
    <<Error:16, PetId:32, Bin1/binary>> = Bin,
    {NewPetName, _Res} = pt:read_string(Bin1),
    {Error, PetId, NewPetName};
read(41006, Bin) ->
    <<Error:16, PetId:32, HpLim:32, MpLim:32, Att:16, Def:16, Hit:16, Dodge:16, Crit:16, Ten:16>> = Bin,
    {Error, PetId, HpLim, MpLim, Att, Def, Hit, Dodge, Crit, Ten};
read(41007, Bin) ->
    <<Error:16, PetId:32>> = Bin,
    {Error, PetId};
read(41008, Bin) ->
    <<Result:16, PetId:32, NewLevel:16, UnallocAttr:16, ExpLeft:32, LlptLeft:32, NextLevelExp:32, NextLevelLlpt:32, MaxPotentialNum:8>> = Bin,
    {Result, PetId, NewLevel, UnallocAttr, ExpLeft, LlptLeft, NextLevelExp, NextLevelLlpt, MaxPotentialNum};
read(41016, Bin) ->
    <<Code:16, PetId:32, NewFigure:16, LeftTime:32, AttrChangeFlag:8>> = Bin,
    {Code, PetId, NewFigure, LeftTime, AttrChangeFlag};
read(41017, Bin) ->
    <<Code:16, PetId:32, OriginFigure:16, NewFigure:16, ChangeType:8, AttrChangeFlag:8>> = Bin,
    {Code, PetId, OriginFigure, NewFigure, ChangeType, AttrChangeFlag};
read(41022, Bin) ->
    <<Result:16, PetId:32, AptitudeThreshold:16>> = Bin,
    {Result, PetId, AptitudeThreshold};
read(41030, Bin) ->
    <<Code:16, PetId:32, NewFigure:16, LeftTime:32, NewIntimacy:32, AttrChangeFlag:8>> = Bin,
    {Code, PetId, NewFigure, LeftTime, NewIntimacy, AttrChangeFlag};
read(24000, Bin) ->
	<<Result:16, Bin1/binary>> = Bin,
	{TeamName, _Res} = pt:read_string(Bin1),
	{Result, TeamName};
read(_Cmd, _R) ->
    {error, no_match}.

parse_pet_list(0, _Bin, AccList) ->
    AccList;
parse_pet_list(RecordNum, Bin, AccList) ->
    <<PetId:32, Bin1/binary>> = Bin,
    {PetName, Bin2} = pt:read_string(Bin1),
    <<TypeId:32,Level:16,Quality:8,Forza:16,Wit:16,Agile:16,Thew:16,UnallocAttr:16,Aptitude:16,Strength:16,StrengthThreshold:16,FightFlag:8,FigureChangeFlag:8,NewFigureChangeLeftTime:32,HpLim:32,MpLim:32,Att:16,Def:16,Hit:16,Dodge:16,Crit:16,Ten:16, Bin3/binary>> = Bin2,
    {PetSkill, Bin4} = pt:read_string(Bin3),
    <<NextLevelExp:32,NextLevelLlpt:32,EnhanceAptitudeCoin:32,NewEnhanceAptitudeProbability:8,MaxSkillNum:8,Figure:16,AptitudeThreshold:16,NewUpgradeExp:32,Growth:32,Fire:16,Ice:16,Drug:16,SavvyLv:16,SavvyExp:32,SavvyExpUpgrade:32,MaxPotentialNum:8, Bin5/binary>> = Bin4,
    {Potentials, Bin6} = pt:read_string(Bin5),
    <<CombatPower:32, Bin7/binary>> = Bin6,
    NewAccList = [{PetId, PetName, TypeId, Level, Quality, Forza, Wit, Agile, Thew, UnallocAttr, Aptitude, Strength, StrengthThreshold, FightFlag, FigureChangeFlag, NewFigureChangeLeftTime, HpLim, MpLim, Att, Def, Hit, Dodge, Crit, Ten, PetSkill, NextLevelExp,NextLevelLlpt,EnhanceAptitudeCoin,NewEnhanceAptitudeProbability,MaxSkillNum,Figure,AptitudeThreshold,NewUpgradeExp,Growth,Fire,Ice,Drug,SavvyLv,SavvyExp,SavvyExpUpgrade,MaxPotentialNum, Potentials, CombatPower} | AccList],
    parse_pet_list(RecordNum-1, Bin7, NewAccList).
