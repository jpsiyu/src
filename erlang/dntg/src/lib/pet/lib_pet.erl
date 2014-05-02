%%%--------------------------------------
%% @Module  : lib_pet
%% @Author  : zhenghehe
%% @Created : 2010.07.03
%% @Description : 宠物信息
%%%--------------------------------------
-module(lib_pet).
-include("common.hrl").
-include("goods.hrl").
-include("server.hrl").
-include("pet.hrl").
-include("buff.hrl").
-include("sql_pet.hrl").
-compile(export_all).

%%=========================================================================
%% 初始化回调函数
%%=========================================================================

%% -----------------------------------------------------------------
%% 登录后的初始化
%% -----------------------------------------------------------------
role_login(Pid, PlayerId, Career) ->
    gen_server:call(Pid, {'apply_call', lib_pet, role_login_pid, [PlayerId, Career]}).

role_login_pid(PlayerId, Career) ->
    %% 清除缓存
    clear_cache(PlayerId),
    %% 加载所有宠物
    load_pet(PlayerId, Career),
    %% 返回出战宠物的加成
    Pet = get_fighting_pet(PlayerId),
    %% EggBrokenAgain = mod_daily_dict:get_count(PlayerId, 5000005), %是否已经再砸一次
    %% EggBrokenDaily = mod_daily_dict:get_count(PlayerId, 5000004), %每日砸蛋次数
    %% DefaultEggBrokenTime = data_pet:get_pet_config(default_egg_broken_time, []),
    %% mod_daily_dict:set_count(PlayerId, 5000008, DefaultEggBrokenTime-EggBrokenDaily+EggBrokenAgain),
    case Pet =:= [] of
        true  ->
            [0, 0, 0, <<>>, 0, 0, get_zero_pet_attribute(), get_zero_pet_skill_attribute(), get_zero_pet_potential_attribute(), get_zero_pet_aptitude_attribute(),[]];
        false ->
            [Pet#player_pet.id, Pet#player_pet.figure, Pet#player_pet.nimbus, Pet#player_pet.name, Pet#player_pet.level, Pet#player_pet.base_aptitude + Pet#player_pet.extra_aptitude, Pet#player_pet.pet_attr, Pet#player_pet.pet_skill_attr, calc_potential_attr(Pet), Pet#player_pet.base_aptitude_attr, Pet#player_pet.skills]            
    end.

load_pet(PlayerId, Career) ->
    Data = [PlayerId],
    SQL  = io_lib:format(?SQL_PET_SELECT_ALL, Data),
    PetList = db:get_all(SQL),
    util:foreach_ex(fun load_pet_into_dict/2, PetList, Career),
    length(PetList).
make_record([PetId,Location,PotentialTypeId,Lv,Exp,CreateTime, Name], pet_potential) ->
    #pet_potential{
	     pet_id = PetId,               
	     potential_type_id = PotentialTypeId,    
	     location = Location,             
	     lv = Lv,                   
	     exp = Exp,                  
	     name = Name,
	     create_time = CreateTime
	    };
make_record([Id,PetId, TypeId, Type, Level], pet_skill) ->
    #pet_skill{
	     id = Id,
	     pet_id = PetId,
	     type_id = TypeId,
	     type = Type,
	     level = Level};
make_record([Id,PlayerId, TypeId, FigureId, ChangeFlag, ActivateFlag, ActivateTime, LastTime], pet_figure) ->
    BaseGoodsFigure = data_pet_figure:get(TypeId),
    FigureAttr = case BaseGoodsFigure#base_goods_figure.figure_attr of
		     List when is_list(List) -> List;
		     _ -> []
		 end,
    #pet_activate_figure{
		   id = Id,
		   player_id = PlayerId,
		   type_id = TypeId,
		   figure_id = FigureId,
		   change_flag = ChangeFlag,
		   activate_flag = ActivateFlag,
		   activate_time = ActivateTime,
		   last_time = LastTime,
		   figure_attr = FigureAttr
		  }.
load_pet_into_dict([Id,Name,PlayerId,TypeId,OriginFigure,Figure,ChangeFlag,FigureType,FigureExpireTime,Level,BaseAptitude,ExtraAptitude,ExtraAptitudeMax,Quality,Forza,Wit,Agile,Thew,Growth,GrowthExp,MaxinumGrowth,Strength,FightFlag,UpgradeExp,CreateTime,ForzaScale, WitScale , AgileScale, ThewScale,LastForzaScale, LastWitScale , LastAgileScale, LastThewScale,CombatPower,Nimbus], _Career) ->
    %% 1- 加载宠物技能
    SQL0  = io_lib:format(?SQL_PET_SKILL_SELECT_ONE_PET, [Id]),
    _SkillList = db:get_all(SQL0),
    PetSkills = util:map_ex(fun make_record/2, _SkillList, pet_skill),
    %% 2- 计算出战宠物的下次体力值同步时间
    NowTime            = util:unixtime(),
    {StrengthNextTime, FightStartTime} 
	= case FightFlag of
	      0 -> {0, 0};
	      1 -> {util:floor(NowTime/60), NowTime}
	  end,
    %% 3- 获取快乐值上限
    StrengthThreshold = data_pet:get_strength_threshold(Quality),
    %% 4- 计算属性值
    PetAttr = calc_pet_attribute(Forza, Wit, Agile, Thew, BaseAptitude + ExtraAptitude),
    %% 5- 构造技能列表
    PetSkillAttr = calc_pet_skill_attribute(Level, PetSkills),
    SQL = io_lib:format(?SQL_PET_POTENTIAL_SELECT_ALL, [Id]),
    _PetPotentials = db:get_all(SQL),
    PetPotentials = util:map_ex(fun make_record/2, _PetPotentials, pet_potential),
    %% 7- 构造潜能列表
    PetPotentialAttr = calc_potential_attr_base(PetPotentials),
    PPA = data_pet_potential:calc_potential_phase_addition(calc_potential_average_lev(PetPotentials)),
    BaseAddition = calc_base_addition([Forza, Wit, Agile, Thew], [ForzaScale, WitScale , AgileScale, ThewScale], Level),
    %% 基础资质的固有属性
    BaseAptitudeAttr = data_pet:calc_pet_aptitude_attr(BaseAptitude),
    %% 宠物幻化形象检查
    Now = util:unixtime(),
    _RealFigure = case ChangeFlag of
		      1 ->
			  case FigureType of
			      0 -> Figure;	%永久幻化
			      1 ->
				  case Now > FigureExpireTime of
				      true -> OriginFigure;
				      false -> Figure
				  end
			  end;
		      0 -> OriginFigure;
		      _ -> OriginFigure
		  end,
    {SubFigure0, _Nimbus} = data_pet:get_growth_phase_info(Growth, figure),
    RealFigure = make_pet_figure(_RealFigure div 100, SubFigure0),
    %% 8- 插入缓存
    Pet = #player_pet{
      id = Id,                     
      name = Name,                   
      player_id = PlayerId,                  
      type_id = TypeId,
      origin_figure = OriginFigure,
      figure = RealFigure,
      figure_type = FigureType,
      change_flag = ChangeFlag,
      figure_expire_time = FigureExpireTime,
      level = Level,                      
      base_aptitude = BaseAptitude,
      extra_aptitude = ExtraAptitude,
      extra_aptitude_max = ExtraAptitudeMax,
      quality = Quality,                    
      forza = Forza,                    
      wit = Wit,                         
      agile = Agile,                   
      thew = Thew,
      forza_scale = ForzaScale,                                       
      wit_scale = WitScale,                                          
      agile_scale = AgileScale,                                       
      thew_scale = ThewScale,
      last_forza_scale = LastForzaScale,                                       
      last_wit_scale = LastWitScale,                                          
      last_agile_scale = LastAgileScale,                                       
      last_thew_scale = LastThewScale, 
      base_addition = BaseAddition,
      growth = Growth,
      growth_exp = GrowthExp,
      maxinum_growth = MaxinumGrowth,
      strength = Strength,
      strength_threshold = StrengthThreshold,
      fight_flag = FightFlag,
      fight_starttime = FightStartTime,
      upgrade_exp = UpgradeExp,
      create_time = CreateTime,                 
      pet_attr = PetAttr,
      name_upper = string:to_upper(util:make_sure_list(Name)),   
      strength_nexttime = StrengthNextTime,
      potentials = PetPotentials,
      pet_potential_attr = PetPotentialAttr,
      pet_potential_phase_addition = PPA,
      base_aptitude_attr = BaseAptitudeAttr,
      skills = PetSkills,   
      pet_skill_attr = PetSkillAttr,
      combat_power = CombatPower,
      nimbus = Nimbus},
    update_pet(Pet).

check_pet_figure_expire(Pid) ->
    gen_server:cast(Pid, {'check_pet_figure_expire'}),
    timer:sleep(1000*60),
    check_pet_figure_expire(Pid).

get_zero_pet_attribute() ->
    [0, 0, 0, 0, 0, 0, 0, 0].

get_zero_pet_skill_attribute() ->
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0].

get_zero_pet_potential_attribute() ->
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0].
get_zero_pet_figure_attribute() ->
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0].

get_zero_pet_aptitude_attribute() ->    
    [0, 0, 0].

%% -----------------------------------------------------------------
%% 退出后的存盘
%% -----------------------------------------------------------------
role_logout(Pid, PlayerId, LastLoginTime) ->
    gen_server:cast(Pid, {'apply_cast', lib_pet, role_logout, [PlayerId, LastLoginTime]}).

role_logout(PlayerId, LastLoginTime) ->
    %% 保存宠物数据
    PetList = get_all_pet(PlayerId),
    case PetList of 
        undefined ->
            skip;
        _ ->
            util:foreach_ex(fun save_pet/2, PetList, LastLoginTime),
            %% 清除缓存
            clear_cache(PlayerId)
    end.

clear_cache(PlayerId) ->
    %% 删除缓存中的宠物
    delete_all_pet(PlayerId).

save_pet(Pet, _LastLoginTime) ->
    NowTime = util:unixtime(),
    [PetId, Strength, Figure, FightFlag, FightStartTime, UpgradeExp, Level, PlayerId, StrengthNextTime, Quality, CombatPower] =
	[Pet#player_pet.id, Pet#player_pet.strength, Pet#player_pet.figure, Pet#player_pet.fight_flag, Pet#player_pet.fight_starttime, Pet#player_pet.upgrade_exp, Pet#player_pet.level, Pet#player_pet.player_id, Pet#player_pet.strength_nexttime, Pet#player_pet.quality, Pet#player_pet.combat_power],
    %% 2- 处理升级经验累加
    NewUpgradeExp = calc_upgrade_exp(FightFlag, FightStartTime, UpgradeExp, Level, PlayerId),
    %% 3- 防外挂进行体力值补扣
    {NewFightFlag, NewStrength} = calc_strength(util:floor(NowTime/60), StrengthNextTime, Quality, FightFlag, Strength),
    %% 4- 保存数据
    Data = [NewFightFlag, NewStrength, Figure, NewUpgradeExp, CombatPower, PetId],
    SQL = io_lib:format(?SQL_PET_UPDATE_LOGOUT, Data),
    db:execute(SQL).

calc_strength(NowTime, StrengthNextTime, Quality, FightFlag, Strength) ->
    case FightFlag == 0 of
        %% 宠物没有出战
        true ->
            {FightFlag, Strength};
        false ->
            DiffTime       = NowTime-StrengthNextTime-5,
            case DiffTime =< 0 of
                %% 无需扣减体力值
                true ->
                    {FightFlag, Strength};
                false->
                    SyncStrength   = data_pet:get_strength_sync_value(Quality),
                    SyncInterval   = data_pet:get_pet_config(strength_sync_interval, []),
                    StrengthDeduct = (DiffTime div SyncInterval)*SyncStrength,
                    case Strength > StrengthDeduct of
                        %% 体力值够扣
                        true  -> {FightFlag, Strength-StrengthDeduct};
                        %% 体力值不够扣
                        false -> {0, 0}
                    end
            end            
    end.

%%=========================================================================
%% 业务操作函数
%%=========================================================================

%% -----------------------------------------------------------------
%% 获取宠物信息
%% -----------------------------------------------------------------
get_pet_info(PetId, Status) ->
    Pet = get_pet(PetId),
    if  %% 宠物不存在
        Pet =:= [] ->
            [2, <<>>];
        true ->
            PetBin = parse_pet_info(Pet, Status),
            [1, PetBin]
    end.

get_fighting_pet_info(Status) ->
    Pet = get_fighting_pet(Status#player_status.id),
    if  %% 宠物不存在
        Pet =:= [] ->
            [2, <<>>];
        true ->
            PetBin = parse_fighting_pet_info(Pet, Status),
            [1, PetBin]
    end.


parse_pet_info(Pet, Status) ->
    [Id,Name,TypeId,Level,Quality,_Forza,_Wit,_Agile,_Thew,LastForzaScale,LastWitScale,LastAgileScale,LastThewScale,BaseAptitude,ExtraAptitude,Strength,
     StrengthThreshold,FightFlag,PetAttr,Figure,_Nimbus,ExtraAptitudeMax, FightStartTime, UpgradeExp, PlayerId, Growth, 
     GrowthExp,MaxinumGrowth,PetSkills, PetSkillAttr, PetPotentialAttr, PetPotentials,PetCombatPower, BaseAptitudeAttr] =
	[Pet#player_pet.id,Pet#player_pet.name,Pet#player_pet.type_id,Pet#player_pet.level,Pet#player_pet.quality,Pet#player_pet.forza,
	 Pet#player_pet.wit,Pet#player_pet.agile,Pet#player_pet.thew,Pet#player_pet.last_forza_scale,Pet#player_pet.last_wit_scale,Pet#player_pet.last_agile_scale,
	 Pet#player_pet.last_thew_scale,Pet#player_pet.base_aptitude,Pet#player_pet.extra_aptitude,Pet#player_pet.strength,Pet#player_pet.strength_threshold,Pet#player_pet.fight_flag,
	 Pet#player_pet.pet_attr,Pet#player_pet.figure,Pet#player_pet.nimbus,Pet#player_pet.extra_aptitude_max,
	 Pet#player_pet.fight_starttime,Pet#player_pet.upgrade_exp,Pet#player_pet.player_id,Pet#player_pet.growth,Pet#player_pet.growth_exp,Pet#player_pet.maxinum_growth,
	 Pet#player_pet.skills, Pet#player_pet.pet_skill_attr, Pet#player_pet.pet_potential_attr,Pet#player_pet.potentials,Pet#player_pet.combat_power, Pet#player_pet.base_aptitude_attr],
    NameLen = byte_size(Name),
    %% 计算升级经验
    _NewUpgradeExp = calc_upgrade_exp(FightFlag, FightStartTime, UpgradeExp, Level, PlayerId),
    %% 计算下级升级信息
    NextLevelExp = data_pet:get_upgrade_info(Level),
    NewUpgradeExp = 
	case _NewUpgradeExp > NextLevelExp of
	    true ->
		NextLevelExp;
	    false ->
		_NewUpgradeExp
	end,
    %% 这是所有属性的加成，用于计算战斗力，不用于返回给客户端显示
    [_HpLim,_MpLim,_Att,_Def,_Hit,_Dodge,_Crit,_Ten,_Fire,_Ice,_Drug,_Hit1,_Hit2] = calc_pet_attr_total(Status, PetAttr, PetSkillAttr, calc_potential_attr(Pet), Pet#player_pet.figure, BaseAptitudeAttr),
    CombatPower = calc_pet_comat_power(_HpLim,_Att,_Def,_Hit,_Dodge,_Crit,_Ten,_Fire,_Ice,_Drug,_Hit1,_Hit2),
    case PetCombatPower =/= CombatPower andalso CombatPower > 0 of
        true ->
            NewPet = Pet#player_pet{combat_power = CombatPower},
            update_pet(NewPet);
        false->
            void
    end,
    %% 成长总加成=成长加成+成长阶段加成
    [ForzaAddition,WitAddition,AgileAddition,ThewAddition] = Pet#player_pet.base_addition,
    %% 基础成长属性
    [Forza, Wit, Agile, Thew] = [_Forza - ForzaAddition, _Wit - WitAddition, _Agile - AgileAddition, _Thew - ThewAddition],
    %% 潜能加成
    [PAHpLim,PAMpLim,PAAtt,PADef,PAHit,PADodge,PACrit,PATen, PAFire, PAIce,PADrug] = PetPotentialAttr,
    [PANHpLim,PANMpLim,PANAtt,PANDef,PANHit,PANDodge,PANCrit,PANTen, PANFire, PANIce,PANDrug] = get_next_potential_addition(PetPotentials),
    RecordsSkill = lists:map(fun parse_pet_skill/1, PetSkills),
    RecordsSkillBin = list_to_binary(RecordsSkill),
    RecordsSkillNum = length(RecordsSkill),
    RecordsPotential = lists:map(fun parse_potential_info/1, PetPotentials),
    RecordsPotentialBin = list_to_binary(RecordsPotential),
    RecordsPotentialNum = length(RecordsPotential),
    NextGrowthExp = data_pet:get_grow_exp(Growth),
    _MaxScale = data_pet:get_growth_phase_info(Growth, max_scale),
    _UnallocAttr = get_unalloc_attr_total(Growth, Level),
    Addition = data_pet:get_growth_phase_info(Growth, addition),
    [_LastForza, _LastWit, _LastAgile, _LastThew] = calc_attr(Growth, Level, [LastForzaScale, LastWitScale, LastAgileScale, LastThewScale]),
    LevelAddition = data_pet_potential:get_potential_level_addition(calc_potential_average_lev(PetPotentials)), 
    %% 潜能阶段加成
    [PPPAHp, PPPAMp, PPPAAtt, PPPADef, PPPAHit, PPPADodge, PPPACrit, PPPATen, PPPAFire, PPPAIce, PPPADrug] = Pet#player_pet.pet_potential_phase_addition,
    %% 基础资质固有加成
    [AptitudeHp, AptitudeAtt,AptitudeDef] = BaseAptitudeAttr,
    %% 二级属性加成，用于客户端显示+号右边的属性值  算法：潜能加成+潜能阶段加成+资质固有属性
    [HpAddition,MpAddition,AttAddition,DefAddition,HitAddition,DodgeAddition,CritAddition,TenAddition,FireAddition,IceAddition,DrugAddition] = [PAHpLim+PPPAHp+AptitudeHp, PAMpLim+PPPAMp, PAAtt+PPPAAtt+AptitudeAtt, PADef+PPPADef+AptitudeDef, PAHit+PPPAHit, PADodge+PPPADodge, PACrit+PPPACrit, PATen+PPPATen, PAFire+PPPAFire, PAIce+PPPAIce, PADrug+PPPADrug],
    %% 这是用于客户端显示基础属性 总的属性 - 潜能加成-潜能阶段加成-基础资质固有属性
    [HpLim,MpLim,Att,Def,Hit,Dodge,Crit,Ten,Fire,Ice,Drug] = [_HpLim-HpAddition, _MpLim-MpAddition,_Att-AttAddition,_Def-DefAddition,_Hit-HitAddition,_Dodge-DodgeAddition,_Crit-CritAddition,_Ten-TenAddition,_Fire-FireAddition,_Ice-IceAddition,_Drug-DrugAddition], 
    %% 成长丹数量
    GrowSingleNum = data_pet:get_single_grow_goods_num(Growth),
    TotalGrowNum = 10*GrowSingleNum,
    %% 潜能丹数量
    AvgPotential = calc_potential_average_lev(PetPotentials),
    PotentialSingleNum = data_pet_potential:get_single_potential_goods_num(AvgPotential),
    TotalPotentialNum = 10*PotentialSingleNum,
    <<Id:32,NameLen:16,Name/binary,TypeId:32,Level:16,Quality:8,Forza:16,Wit:16,Agile:16,Thew:16,ForzaAddition:16,
      WitAddition:16,AgileAddition:16,ThewAddition:16,BaseAptitude:16, ExtraAptitude:16, Strength:16,StrengthThreshold:16,FightFlag:8,HpLim:32,MpLim:32,Att:16,Def:16,Hit:16,Dodge:16,Crit:16,Ten:16,Fire:16,Ice:16,Drug:16,
      HpAddition:16,MpAddition:16,AttAddition:16,DefAddition:16,HitAddition:16,DodgeAddition:16,CritAddition:16,TenAddition:16,FireAddition:16, IceAddition:16,DrugAddition:16,
      NewUpgradeExp:32,NextLevelExp:32,Figure:16,ExtraAptitudeMax:16,
      Growth:32,MaxinumGrowth:32,GrowthExp:32,CombatPower:32,RecordsSkillNum:16, RecordsSkillBin/binary, RecordsPotentialNum:16, RecordsPotentialBin/binary, NextGrowthExp:32, Addition:32,
      PPPAHp:16, PPPAMp:16, PPPAAtt:16, PPPADef:16, PPPAHit:16, PPPADodge:16, PPPACrit:16, PPPATen:16, PPPAFire:16, PPPAIce:16, PPPADrug:16,
      PANHpLim:16,PANMpLim:16,PANAtt:16,PANDef:16,PANHit:16,PANDodge:16,PANCrit:16,PANTen:16,PANFire:16, PANIce:16,PANDrug:16,
      LevelAddition:16,GrowSingleNum:16, TotalGrowNum:16, PotentialSingleNum:16, TotalPotentialNum:16>>.

parse_fighting_pet_info(Pet, Status) ->
    [Id,Name,TypeId,Level,Quality,BaseAptitude, ExtraAptitude, _Forza,_Wit,_Agile,_Thew,PetAttr,Figure,Nimbus,Growth,PetSkills, PetSkillAttr, PetPotentialAttr, PetPotentials, BaseAptitudeAttr] =
	[Pet#player_pet.id,Pet#player_pet.name,Pet#player_pet.type_id,Pet#player_pet.level,Pet#player_pet.quality,Pet#player_pet.base_aptitude,Pet#player_pet.extra_aptitude, Pet#player_pet.forza,
	 Pet#player_pet.wit,Pet#player_pet.agile,Pet#player_pet.thew,Pet#player_pet.pet_attr,Pet#player_pet.figure,Pet#player_pet.nimbus,Pet#player_pet.growth,
	 Pet#player_pet.skills, Pet#player_pet.pet_skill_attr, Pet#player_pet.pet_potential_attr,Pet#player_pet.potentials, Pet#player_pet.base_aptitude_attr],
    NameLen = byte_size(Name),
    %% 这是总的属性,用于计算战斗力，不用于返回给客户端显示
    [HpLim,MpLim,Att,Def,Hit,Dodge,Crit,Ten,Fire,Ice,Drug,Hit1,Hit2] = calc_pet_attr_total(Status, PetAttr, PetSkillAttr, calc_potential_attr(Pet), Pet#player_pet.figure, BaseAptitudeAttr),
    CombatPower = calc_pet_comat_power(HpLim,Att,Def,Hit,Dodge,Crit,Ten,Fire,Ice,Drug,Hit1,Hit2),
    %% 用于客户端显示的一级属性加成
    [ForzaAddition,WitAddition,AgileAddition,ThewAddition] = Pet#player_pet.base_addition,
    %% 用于客户端显示的一级基础属性
    [Forza, Wit, Agile, Thew] = [_Forza-ForzaAddition, _Wit-WitAddition, _Agile-AgileAddition, _Thew-ThewAddition],
    %% 潜能加成
    [PAHpLim,PAMpLim,PAAtt,PADef,PAHit,PADodge,PACrit,PATen, PAFire, PAIce,PADrug] = PetPotentialAttr,
    RecordsSkill = lists:map(fun parse_pet_skill/1, PetSkills),
    RecordsSkillBin = list_to_binary(RecordsSkill),
    RecordsSkillNum = length(RecordsSkill),
    PotentialLv = calc_potential_average_lev(PetPotentials),
    %% 潜能阶段加成
    [PPPAHp, PPPAMp, PPPAAtt, PPPADef, PPPAHit, PPPADodge, PPPACrit, PPPATen, PPPAFire, PPPAIce, PPPADrug] = Pet#player_pet.pet_potential_phase_addition,
    %% 基础资质固有加成
    [AptitudeHp, AptitudeAtt, AptitudeDef] = BaseAptitudeAttr,
    %% 用于客户端显示的潜能所有加成属性
    [HpAddition,MpAddition,AttAddition,DefAddition,HitAddition,DodgeAddition,CritAddition,TenAddition,FireAddition,IceAddition,DrugAddition] = [PAHpLim+PPPAHp+AptitudeHp, PAMpLim+PPPAMp,PAAtt+PPPAAtt+AptitudeAtt,PADef+PPPADef+AptitudeDef,PAHit+PPPAHit,PADodge+PPPADodge,PACrit+PPPACrit,PATen+PPPATen,PAFire+PPPAFire,PAIce+PPPAIce,PADrug+PPPADrug],
    % 用于客户端显示的二级基础属性
    [HpLim2,MpLim2,Att2,Def2,Hit3,Dodge2,Crit2,Ten2,Fire2,Ice2,Drug2] = [HpLim-HpAddition, MpLim-MpAddition,Att-AttAddition,Def-DefAddition,Hit-HitAddition,Dodge-DodgeAddition,Crit-CritAddition,Ten-TenAddition,Fire-FireAddition,Ice-IceAddition,Drug-DrugAddition],
    FigureVal = Status#player_status.pet_figure_value,
    Aptitude = BaseAptitude+ExtraAptitude,
    <<Id:32,NameLen:16,Name/binary,TypeId:32,Level:16,Quality:8,Aptitude:16, Forza:16,Wit:16,Agile:16,Thew:16,HpLim2:32,MpLim2:32,Att2:16,Def2:16,Hit3:16,Dodge2:16,Crit2:16,Ten2:16,Fire2:16,Ice2:16,Drug2:16,
      ForzaAddition:16,WitAddition:16,AgileAddition:16,ThewAddition:16,HpAddition:16,MpAddition:16,AttAddition:16,DefAddition:16,HitAddition:16,DodgeAddition:16,CritAddition:16,TenAddition:16,FireAddition:16, IceAddition:16,DrugAddition:16,Figure:16,Nimbus:16,Growth:32,CombatPower:32,RecordsSkillNum:16, RecordsSkillBin/binary,PotentialLv:16,FigureVal:32>>.

calc_pet_attr_total(PetAttr, PetPotentialAttr) ->
    [HpLim,MpLim,Att,Def,Hit,Dodge,Crit,Ten] = PetAttr,
    [PotentialHpLim,PotentialMpLim,PotentialAtt,PotentialDef,PotentialHit,PotentialDodge,PotentialCrit,PotentialTen, PotentialFire, PotentialIce, PotentialDrug] = PetPotentialAttr,
    NewHpLim = HpLim+PotentialHpLim,
    NewMpLim = MpLim+PotentialMpLim,
    NewAtt   = Att+PotentialAtt,
    NewDef   = Def+PotentialDef,
    NewHit   = Hit+PotentialHit,
    NewDodge = Dodge+PotentialDodge,
    NewCrit  = Crit+PotentialCrit,
    NewTen   = Ten+PotentialTen,
    NewFire  = PotentialFire,
    NewIce   = PotentialIce,
    NewDrug  = PotentialDrug,
    [NewHpLim,NewMpLim,NewAtt,NewDef,NewHit,NewDodge,NewCrit,NewTen,NewFire,NewIce,NewDrug].

calc_pet_attr_total(Status,PetAttr,PetSkillAttr,PetPotentialAttr,_PetFigure, BaseAptitudeAttr) ->
    PetFigureAttr = lib_pet:filter_figure_attr(Status#player_status.unreal_figure_activate),
    [_PetFigureHp,_PetFigureMp,_PetFigureAtt,_PetFigureDef,_PetFigureHit,_PetFigureDodge,_PetFigureCrit,_PetFigureTen,_PetFigureFire,_PetFigureIce,_PetFigureDrug] = 
	PetFigureAttr,
    [_PetHp,_PetMp,_PetAtt,_PetDef,_PetHit,_PetDodge,_PetCrit,_PetTen] = PetAttr,
    [_PetSkillHp,_PetSkillMp,_PetSkillAtt,_PetSkillDef,_PetSkillHit,_PetSkillDodge,_PetSkillCrit,_PetSkillTen,_PetSkillFire,_PetSkillIce,_PetSkillDrug] = PetSkillAttr,
    [_PetPotentialHp,_PetPotentialMp,_PetPotentialAtt,_PetPotentialDef,_PetPotentialHit, _PetPotentialDodge,_PetPotentialCrit,_PetPotentialTen,_PetPotentialFire,_PetPotentialIce, _PetPotentialDrug] = PetPotentialAttr,
    %% 基础资质的固有属性
    [AptitudeHp, AptitudeAtt, AptitudeDef] = BaseAptitudeAttr,
    PetHp    = _PetHp+_PetSkillHp+_PetPotentialHp+_PetFigureHp+AptitudeHp,
    PetMp    = _PetMp+_PetSkillMp+_PetPotentialMp+_PetFigureMp,
    PetAtt   = _PetAtt+_PetSkillAtt+_PetPotentialAtt+_PetFigureAtt+AptitudeAtt,
    PetDef   = _PetDef+_PetSkillDef+_PetPotentialDef+_PetFigureDef+AptitudeDef,
    PetHit   = _PetHit+_PetSkillHit+_PetPotentialHit+_PetFigureHit,
    PetDodge = _PetDodge+_PetSkillDodge+_PetPotentialDodge+_PetFigureDodge,
    PetCrit  = _PetCrit+_PetSkillCrit+_PetPotentialCrit+_PetFigureCrit,
    PetTen   = _PetTen+_PetSkillTen+_PetPotentialTen+_PetFigureTen,
    PetFire  = _PetSkillFire+_PetPotentialFire+_PetFigureFire, 
    PetIce   = _PetSkillIce+_PetPotentialIce+_PetFigureIce, 
    PetDrug  = _PetSkillDrug+_PetPotentialDrug+_PetFigureDrug,
    PetHit1 = if
		  _PetSkillHit =< 0 ->
		      64.8;
		  true ->
		      _PetSkillHit
	      end,
    PetHit2 = _PetHit+_PetPotentialHit+_PetFigureHit,
    [PetHp,PetMp,PetAtt,PetDef,PetHit,PetDodge,PetCrit,PetTen,PetFire, PetIce, PetDrug, PetHit1, PetHit2].

calc_pet_comat_power_incubate(HpLim,Att,Def,Hit,Dodge,Crit,Ten,Fire,Ice,Drug) ->
    round(Att*3.97+Def*1.32+Hit*1.37+Dodge*1.65+Crit*3.53+Ten*1.76+HpLim*0.26+(Fire+Ice+Drug)*0.44).
calc_pet_comat_power(HpLim,Att,Def,Hit,Dodge,Crit,Ten,Fire,Ice,Drug,_Hit1,_Hit2) ->
    round(Att*3.97+Def*1.32+Hit*1.37+Dodge*1.65+Crit*3.53+Ten*1.76+HpLim*0.26+(Fire+Ice+Drug)*0.44).
calc_pet_comat_power_by_pet(PlayerStatus, Pet) ->
    [HpLim,_MpLim,Att,Def,Hit,Dodge,Crit,Ten,Fire,Ice,Drug,Hit1,Hit2] = calc_pet_attr_total(PlayerStatus, Pet#player_pet.pet_attr, Pet#player_pet.pet_skill_attr, calc_potential_attr(Pet), Pet#player_pet.figure, Pet#player_pet.base_aptitude_attr),
    calc_pet_comat_power(HpLim,Att,Def,Hit,Dodge,Crit,Ten,Fire,Ice,Drug,Hit1,Hit2).

%% -----------------------------------------------------------------
%% 获取宠物列表
%% -----------------------------------------------------------------
get_pet_list(Status) ->
    PlayerId    = Status#player_status.id,
    Pt = Status#player_status.pet,
    PetCapacity = Pt#status_pet.pet_capacity,
    PetMaxNum   = get_pet_maxnum(PetCapacity),
    PetList     = get_all_pet(PlayerId),
    RecordNum   = length(PetList),
    if  %% 没有宠物
        RecordNum == 0 ->
            [1, PetMaxNum, RecordNum, <<>>];
        true ->
            Records = util:map_ex(fun parse_pet_info/2, PetList, Status),
            [1, PetMaxNum, RecordNum, list_to_binary(Records)]
    end.

init_default_potential(PetId) ->
    BasePetPotential1 = data_pet_potential:get(1),
    PetPotential1 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential1#ets_base_pet_potential.id,
      location = 1,
      lv = BasePetPotential1#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential1#ets_base_pet_potential.name
     },
    BasePetPotential2 = data_pet_potential:get(2),
    PetPotential2 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential2#ets_base_pet_potential.id,
      location = 2,
      lv = BasePetPotential2#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential2#ets_base_pet_potential.name
     },
    BasePetPotential3 = data_pet_potential:get(3),
    PetPotential3 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential3#ets_base_pet_potential.id,
      location = 3,
      lv = BasePetPotential3#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential3#ets_base_pet_potential.name
     },
    BasePetPotential4 = data_pet_potential:get(4),
    PetPotential4 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential4#ets_base_pet_potential.id,
      location = 4,
      lv = BasePetPotential4#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential4#ets_base_pet_potential.name
     },
    BasePetPotential5 = data_pet_potential:get(5),
    PetPotential5 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential5#ets_base_pet_potential.id,
      location = 5,
      lv = BasePetPotential5#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential5#ets_base_pet_potential.name
     },
    BasePetPotential6 = data_pet_potential:get(6),
    PetPotential6 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential6#ets_base_pet_potential.id,
      location = 6,
      lv = BasePetPotential6#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential6#ets_base_pet_potential.name
     },
    BasePetPotential7 = data_pet_potential:get(7),
    PetPotential7 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential7#ets_base_pet_potential.id,
      location = 7,
      lv = BasePetPotential7#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential7#ets_base_pet_potential.name
     },
    BasePetPotential8 = data_pet_potential:get(8),
    PetPotential8 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential8#ets_base_pet_potential.id,
      location = 8,
      lv = BasePetPotential8#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential8#ets_base_pet_potential.name
     },
    BasePetPotential9 = data_pet_potential:get(9),
    PetPotential9 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential9#ets_base_pet_potential.id,
      location = 9,
      lv = BasePetPotential9#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential9#ets_base_pet_potential.name
     },
    BasePetPotential10 = data_pet_potential:get(10),
    PetPotential10 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential10#ets_base_pet_potential.id,
      location = 10,
      lv = BasePetPotential10#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential10#ets_base_pet_potential.name
     },
    BasePetPotential11 = data_pet_potential:get(11),
    PetPotential11 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential11#ets_base_pet_potential.id,
      location = 11,
      lv = BasePetPotential11#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential11#ets_base_pet_potential.name
     },
    BasePetPotential12 = data_pet_potential:get(12),
    PetPotential12 = #pet_potential{
      pet_id = PetId,
      potential_type_id = BasePetPotential12#ets_base_pet_potential.id,
      location = 12,
      lv = BasePetPotential12#ets_base_pet_potential.lv,
      exp = 0,
      name = BasePetPotential12#ets_base_pet_potential.name
     },
    [PetPotential1, PetPotential2, PetPotential3, PetPotential4, PetPotential5, PetPotential6, PetPotential7, 
     PetPotential8, PetPotential9, PetPotential10, PetPotential11, PetPotential12].

init_default_potential_on_db(PetPotentials) ->
    F = fun(PetPotential) ->
                CreateTime = util:unixtime(),
                [PetId, Location, PotentialTypeId, Lv, Exp] = 
		    [PetPotential#pet_potential.pet_id, PetPotential#pet_potential.location, PetPotential#pet_potential.potential_type_id, PetPotential#pet_potential.lv, PetPotential#pet_potential.exp],
                SQL = io_lib:format(?SQL_PET_POTENTIAL_INSERT, [PetId, Location, PotentialTypeId, Lv, Exp, CreateTime, PetPotential#pet_potential.name]),
                db:execute(SQL)
        end,
    FAll = fun() ->
		   lists:foreach(F, PetPotentials)
	   end,
    db:transaction(FAll).
%% -----------------------------------------------------------------
%% 孵化宠物
%% -----------------------------------------------------------------
incubate_pet(PlayerId, PlayerCareer, GoodsType, BaseGoodsPet) ->
    %% 解析物品类型
    TypeId = GoodsType#ets_goods_type.goods_id,
    [PetName, GrowthMin, GrowthMax, Figure0] = [BaseGoodsPet#base_goods_pet.name, BaseGoodsPet#base_goods_pet.growth_min, BaseGoodsPet#base_goods_pet.growth_max,BaseGoodsPet#base_goods_pet.effect],
    AptitudeRatio = BaseGoodsPet#base_goods_pet.aptitude_ratio,
    % {AptitudeMin, AptitudeMax} = case get_incubate_aptitude(AptitudeRatio) of
				%      null -> {BaseGoodsPet#base_goods_pet.aptitude_min, BaseGoodsPet#base_goods_pet.aptitude_max};
				%      {Min, Max, _} -> {Min, Max}
				%  end,
      %% 手机版修改 基础资质和额外资质上限
      BaseAptitude = case get_incubate_aptitude(AptitudeRatio) of 
          null -> BaseGoodsPet#base_goods_pet.base_aptitude;
          {Min, Max, _} -> util:rand(Min, Max)
      end,
    %% 获取配置
    %%DefaultAptitude = util:rand(AptitudeMin, AptitudeMax),
    %% 基础资质，额外资质，额外资质上限
    DefaultBaseAptitude = BaseAptitude,
    DefaultExtraAptitude = 0,
    DefaultExtraAptitudeMax = BaseGoodsPet#base_goods_pet.extra_aptitude_max,
    DefaultQuality = data_pet:get_quality(DefaultBaseAptitude + DefaultExtraAptitude),
    DefaultGrowth = GrowthMin,
    {SubFigure0, Nimbus} = data_pet:get_growth_phase_info(DefaultGrowth, figure),
    Figure = make_pet_figure(Figure0, SubFigure0),
    DefaultGrowthExp = 0,
    MaxinumGrowth = GrowthMax,
    %DefaultAptitudeThreshold = AptitudeMax,
    DefaultStrength   = data_pet:get_strength_threshold(DefaultQuality),
    DefaultLevel      = data_pet:get_pet_config(default_level, []),    
    [ForzaScale, WitScale, AgileScale, ThewScale] = data_pet:get_default_growth_scale(),
    [Forza, Wit, Agile, Thew] = calc_attr(DefaultGrowth, DefaultLevel, [ForzaScale, WitScale, AgileScale, ThewScale]),
    %% 属性由基础资质+额外资质影响
    PetAttr = calc_pet_attribute(Forza, Wit, Agile, Thew, DefaultBaseAptitude+DefaultExtraAptitude),
    [HpLim,_MpLim,Att,Def,Hit,Dodge,Crit,Ten] = PetAttr,
    %% 基础资质属性
    AptitudeAttr = data_pet:calc_pet_aptitude_attr(DefaultBaseAptitude),
    [HpLim2, Att2, Def2] = AptitudeAttr,
    ComatPower = calc_pet_comat_power_incubate(HpLim+HpLim2,Att+Att2,Def+Def2,Hit,Dodge,Crit,Ten,0,0,0),
    %% 插入宠物
    CreateTime = util:unixtime(),
    Data = [PlayerId, TypeId, Figure, Nimbus, PetName, Forza, Wit, Agile, Thew, DefaultQuality, DefaultBaseAptitude, DefaultExtraAptitude, DefaultExtraAptitudeMax, DefaultLevel, DefaultStrength, DefaultGrowth, DefaultGrowthExp, MaxinumGrowth, ForzaScale, WitScale, AgileScale, ThewScale, CreateTime, ComatPower],
    SQL  = io_lib:format(?SQL_PET_INSERT, Data),
    db:execute(SQL),
    %% 获取新孵化的宠物
    Data1 = [PlayerId, TypeId, CreateTime],
    SQL1  = io_lib:format(?SQL_PET_SELECT_INCUBATE_PET, Data1),
    IncubateInfo = db:get_row(SQL1),
    case IncubateInfo of
        %% 孵化失败
        [] ->
            ?ERR("incubate_pet: Failed to incubated pet, PlayerId=[~p], TypeId=[~p], CreateTime=[~p]", [PlayerId, TypeId, CreateTime]),
            0;
        %% 孵化成功
        _ ->
            [PetId| _] = IncubateInfo,
            PetPotentials = init_default_potential(PetId),
            init_default_potential_on_db(PetPotentials),
            %% 更新缓存
            load_pet_into_dict(IncubateInfo, PlayerCareer),
            %% 触发成就
	    %%             lib_chengjiu:trigger_yx(PlayerId, 16, 1),
            %% 返回值
            [ok, PetId, PetName, Figure, DefaultBaseAptitude, DefaultGrowth, MaxinumGrowth]
    end.

get_incubate_aptitude(AptitudeRatio) ->
    case is_list(AptitudeRatio) of
	true ->
	    TotalRatio = lib_goods_util:get_ratio_total(AptitudeRatio, 3),
	    Rand = util:rand(1, TotalRatio),
	    lib_goods_util:find_ratio(AptitudeRatio, 0, Rand, 3);
	false ->
	    null
    end.



%% -----------------------------------------------------------------
%% 宠物放生
%% -----------------------------------------------------------------
free_pet(PetId) ->
    %% 删除宠物
    SQL = io_lib:format(?SQL_PET_DELETE, [PetId]),
    db:execute(SQL),
    %% 更新缓存
    delete_pet(PetId),
    %% 删除宠物技能
    SQL1 = io_lib:format(?SQL_PET_SKILL_DELETE, [PetId]),
    db:execute(SQL1),
    %% 删除宠物潜能
    SQL2 = io_lib:format(?SQL_PET_POTENTIAL_DELETE, [PetId]),
    db:execute(SQL2),
    SQL3 = io_lib:format(<<"delete from pet_potential_exp where pet_id=~p">>, [PetId]),
    db:execute(SQL3),
    ok.

%% -----------------------------------------------------------------
%% 宠物改名
%% -----------------------------------------------------------------
rename_pet(PetId, PetName, PlayerId, RenameNum, RenameLastTime) ->
    %% 更新宠物名
    Data = [PetName, PetId],
    SQL = io_lib:format(?SQL_PET_UPDATE_RENAME_INFO, Data),
    db:execute(SQL),
    %% 记录修改次数
    Data1 = [RenameNum, RenameLastTime, PlayerId],
    SQL1 = io_lib:format(?SQL_PLAYER_PET_UPDATE_PET_RENAME, Data1),
    db:execute(SQL1),
    ok.

%% -----------------------------------------------------------------
%% 宠物出战
%% -----------------------------------------------------------------
fighting_pet(PetId) ->
    Data = [1, PetId],
    SQL = io_lib:format(?SQL_PET_UPDATE_FIGHT, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 宠物休息
%% -----------------------------------------------------------------
rest_pet(PetId, NewUpgradeExp) ->
    Data = [0, NewUpgradeExp, PetId],
    SQL = io_lib:format(?SQL_PET_UPDATE_REST, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 宠物升级
%% -----------------------------------------------------------------
upgrade_pet(PetId, Level, ExpLeft,PetForza,PetWit,PetAgile,PetThew,ComatPower) ->
    %% 更新升级信息
    Data = [Level, ExpLeft,PetForza,PetWit,PetAgile,PetThew,ComatPower, PetId],
    SQL = io_lib:format(?SQL_PET_UPDATE_UPGRADE, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 升级经验同步
%% -----------------------------------------------------------------
upgrade_exp_sync(PetId, NewUpgradeExp) ->
    Data = [NewUpgradeExp, PetId],
    SQL = io_lib:format(?SQL_PET_UPDATE_UPGRADE_EXP, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 体力值改变
%% -----------------------------------------------------------------
change_strength(PetId, Strength) ->
    %% 更新体力值
    case Strength == 0 of
        true ->
            Data = [Strength, 0, PetId],
            SQL = io_lib:format(?SQL_PET_UPDATE_ZERO_STRENGTH, Data),
            db:execute(SQL),
            ok;
        false ->
            Data = [Strength, PetId],
            SQL = io_lib:format(?SQL_PET_UPDATE_STRENGTH, Data),
            db:execute(SQL),
            ok
    end.

add_aptitude(Pet,GoodsTypeId) ->
    BaseGoodsPet = lib_pet:get_base_goods_pet(GoodsTypeId),
    AptitudeRatio = BaseGoodsPet#base_goods_pet.aptitude_ratio,
    TotalRatio = lib_goods_util:get_ratio_total(AptitudeRatio, 2),
    Rand = util:rand(1, TotalRatio),
    Value = case lib_goods_util:find_ratio(AptitudeRatio, 0, Rand, 2) of
		null -> 1;
		{Val, _} -> 
		    Val
	    end,
    [BaseAptitude, ExtraAptitude, ExtraAptitudeMax, Forza, Wit, Agile, Thew] = [Pet#player_pet.base_aptitude, Pet#player_pet.extra_aptitude, Pet#player_pet.extra_aptitude_max, Pet#player_pet.forza, Pet#player_pet.wit, Pet#player_pet.agile, Pet#player_pet.thew],
    NewExtraAptitude = case ExtraAptitude + Value >= ExtraAptitudeMax of
		      true -> ExtraAptitudeMax;
		      false -> ExtraAptitude + Value
		  end,
 %    NewAptitudeThreshold =
	% if
	%     NewAptitude > Pet#player_pet.aptitude_threshold ->
	% 	NewAptitude;
	%     true ->
	% 	Pet#player_pet.aptitude_threshold
	% end,
    %% 宠物资质 = 基础资质+额外资质
    NewAptitude = BaseAptitude + NewExtraAptitude,
    NewPetAttr = calc_pet_attribute(Forza, Wit, Agile, Thew, NewAptitude),
    NewQuality = data_pet:get_quality(NewAptitude),
    NewPet = Pet#player_pet{ 
	       pet_attr = NewPetAttr,
	       extra_aptitude = NewExtraAptitude,
	       quality = NewQuality
	      },
    update_pet(NewPet),
    SQL = io_lib:format(<<"update pet set extra_aptitude=~p, quality=~p where id=~p">>,[NewExtraAptitude, NewQuality, NewPet#player_pet.id]),
    db:execute(SQL),
    [NewPetAttr, NewAptitude, NewExtraAptitude - ExtraAptitude].

%% -----------------------------------------------------------------
%% 资质提升
%% -----------------------------------------------------------------
enhance_aptitude(PetId, NewAptitude, NewQuality) ->
    %% 改变资质
    Data1 = [NewAptitude, NewQuality, PetId],
    SQL1 = io_lib:format(?SQL_PET_UPDATE_APTITUDE, Data1),
    db:execute(SQL1),
    ok.

%% -----------------------------------------------------------------
%% 属性点分配
%% -----------------------------------------------------------------
alloc_attr(PetId, NewForza, NewWit, NewAgile, NewThew, NewUnallocAttr) ->
    Data = [NewForza, NewWit, NewAgile, NewThew, NewUnallocAttr, PetId],
    SQL = io_lib:format(?SQL_PET_UPDATE_UNALLOC_ATTR, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 宠物继承
%% 修改记录: 1. 副宠技能不再转移至主宠身上   
%% -----------------------------------------------------------------
derive_pet(DeletePetId, PetId1, NewBaseAptitude, NewExtraAptitude, NewExtraAptitudeMax, NewGrowth, NewGrowthExp, NewMaxinumGrowth, NewLevel, NewQuality, NewPotentials, NewForza, NewWit, NewAgile, NewThew, NewPetSkills) ->
    %% 删除副宠
    Data = [DeletePetId],
    SQL  = io_lib:format(?SQL_PET_DELETE, Data),
    %% 更新主宠
    Data1 = [NewForza, NewWit, NewAgile, NewThew, NewBaseAptitude, NewExtraAptitude, NewExtraAptitudeMax, NewQuality, NewGrowth, NewGrowthExp, NewMaxinumGrowth, NewLevel, PetId1],
    SQL1  = io_lib:format(?SQL_PET_UPDATE_DERIVE, Data1),
    %% 删除副宠潜能
    Data4= [DeletePetId],
    SQL4 = io_lib:format(?SQL_PET_POTENTIAL_DELETE, Data4),
    %% 删除主宠潜能
    Data5= [PetId1],
    SQL5 = io_lib:format(?SQL_PET_POTENTIAL_DELETE, Data5),
    %% 插入主宠新潜能
    F = fun(Potential) ->
		db:execute(io_lib:format(?SQL_PET_POTENTIAL_DERIVE, [Potential#pet_potential.pet_id, Potential#pet_potential.location, Potential#pet_potential.potential_type_id, Potential#pet_potential.lv, Potential#pet_potential.exp, Potential#pet_potential.create_time, Potential#pet_potential.name]))
        end,
    %% 删除副宠技能
    SQL6 = io_lib:format(?SQL_PET_SKILL_DELETE, [DeletePetId]),
    SQL7 = io_lib:format(?SQL_PET_SKILL_DELETE, [PetId1]),
    %% 插入融合宠物技能
    F1 = fun(NewPetSkill) ->
		 %% 宠物ID是主宠，但技能ID有可能是副宠的
		 db:execute(io_lib:format(?SQL_PET_SKILL_INSERT, [PetId1,NewPetSkill#pet_skill.type_id,NewPetSkill#pet_skill.type,NewPetSkill#pet_skill.level]))
	 end,
    %% 事务操作多条数据库语句
    FAll = fun() ->
		   db:execute(SQL),
		   db:execute(SQL1),
		   db:execute(SQL4),
		   db:execute(io_lib:format(<<"delete from pet_potential_exp where pet_id=~p">>, [DeletePetId])),
		   db:execute(SQL5),
		   lists:foreach(F, NewPotentials),
		   db:execute(SQL6),
		   db:execute(SQL7),
		   lists:foreach(F1, NewPetSkills)
	   end,
    db:transaction(FAll),
    %%     %% 继承副宠技能
    %%     F1 = fun(_PetSkill) ->
    %%                  _SkillId = _PetSkill#pet_skill.id,
    %%                  SQL7 = io_lib:format(?SQL_PET_SKILL_UPDATE_DERIVE, [PetId1, DeletePetId, _SkillId]),
    %%                 ?DEBUG("derive_pet: SQL=[~s]", [SQL7]),
    %%                 db:execute(SQL7)
    %%          end,
    %%     lists:foreach(F1, DeffSkills),
    ok.

%% -----------------------------------------------------------------
%% 扣取铜币
%% -----------------------------------------------------------------
update_coin(PlayerId, CoinLeft, BindCoinLeft) ->
    %% 扣取铜币
    Data = [CoinLeft, BindCoinLeft, PlayerId],
    SQL = io_lib:format(?SQL_PLAYER_HIGH_UPDATE_COIN_BOTH, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 宠物进化
%% -----------------------------------------------------------------
enhance_aptitude_threshold(PetId, NewAptitudeThreshold) ->
    Data = [NewAptitudeThreshold, PetId],
    SQL = io_lib:format(?SQL_PET_UPDATE_APTITUDE_THRESHOLD, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 购买宠物栏
%% -----------------------------------------------------------------
buy_pet_capacity(PlayerId, GoldLeft, NewPetCapacity) ->
    Data = [GoldLeft, NewPetCapacity, PlayerId],
    SQL = io_lib:format(?SQL_PLAYER_PET_UPDATE_PET_CAPACITY, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 宠物成长
%% -----------------------------------------------------------------
grow_up(PetId, NewGrowth) ->
    Data = [NewGrowth, PetId],
    SQL = io_lib:format(?SQL_PET_UPDATE_GROWTH, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 宠物展示
%% -----------------------------------------------------------------
show_pet(PlayerId, PetId) ->
    Pet = lib_player:rpc_call_by_id(PlayerId, lib_pet, get_pet, [PetId]),
    if  %% 缓存中不存在
        Pet =:= [] ->
            %% 查找数据库中的宠物
            Data = [PetId],
            SQL = io_lib:format(?SQL_PET_SELECT_SHOW_INFO, Data),
            PetInfo = db:get_row(SQL),
            case PetInfo =:= [] of
                %% 宠物不存在
                true ->
                    [2, <<>>];
                %% 宠物存在
                false->
                    [Id,Name,Level,Quality,Forza,Wit,Agile,Thew,BaseAptitude, ExtraAptitude, Figure,Nimbus, ExtraAptitudeMax, Growth,CombatPower] = PetInfo,
                    %% 解析宠物信息
                    PetBin = parse_show_pet_info(Id,Name,Level,Quality,Forza,Wit,Agile,Thew,BaseAptitude+ExtraAptitude,Figure,Nimbus,ExtraAptitudeMax, Growth,CombatPower),
                    [1, PetBin]
            end;
        %% 缓存中存在
        true ->
            %% 解析宠物信息
            PetBin = parse_show_pet_info(Pet),
            [1, PetBin]
    end.

parse_show_pet_info(Pet) ->
    [Id,Name,Level,Quality,Forza,Wit,Agile,Thew,Aptitude,Figure,Nimbus,AptitudeThreshold, Growth, CombatPower] =
        [Pet#player_pet.id,Pet#player_pet.name,Pet#player_pet.level,Pet#player_pet.quality,Pet#player_pet.forza,Pet#player_pet.wit,Pet#player_pet.agile,Pet#player_pet.thew,Pet#player_pet.base_aptitude + Pet#player_pet.extra_aptitude,Pet#player_pet.figure,Pet#player_pet.nimbus,Pet#player_pet.extra_aptitude_max,Pet#player_pet.growth, Pet#player_pet.combat_power],
    NameLen       = byte_size(Name),
    <<Id:32,NameLen:16,Name/binary,Level:16,Quality:8,Forza:16,Wit:16,Agile:16,Thew:16,Aptitude:16,Figure:16,Nimbus:16,AptitudeThreshold:16,Growth:32,CombatPower:32>>.


parse_show_pet_info(Pet, PlayerName) ->
    [Id,PetName,Level,Quality,BaseAptitude,ExtraAptitude,Figure,Nimbus,_Skills,_Potentials,Growth, CombatPower] =
        [Pet#player_pet.id,Pet#player_pet.name,Pet#player_pet.level,Pet#player_pet.quality,Pet#player_pet.base_aptitude, Pet#player_pet.extra_aptitude, Pet#player_pet.figure,Pet#player_pet.nimbus,Pet#player_pet.skills,Pet#player_pet.potentials,Pet#player_pet.growth, Pet#player_pet.combat_power],
    Skills = lists:map(fun(Record) ->
			       Bin = parse_pet_skill(Record),
			       Bin
		       end, _Skills),
    PotentialLv = calc_potential_average_lev(_Potentials),
    PetNameBin = pt:write_string(PetName),
    PlayerNameBin = pt:write_string(PlayerName),
    SkillsLen = length(Skills),
    SkillsBin = list_to_binary(Skills),
    %% 手机版资质 = 基础资质 +额外资质
    Aptitude = BaseAptitude + ExtraAptitude,
    <<Id:32, PetNameBin/binary, PlayerNameBin/binary, Level:16, Quality:8, SkillsLen:16, SkillsBin/binary, Figure:16, Nimbus:16, Aptitude:16, Growth:32, PotentialLv:16, CombatPower:32>>.

parse_show_pet_figure_change_info(Pet, PlayerName, UnrealFigureList, FigureChangeVal) ->
    [Id,PetName,Level,Quality,Aptitude,Figure,Nimbus,_Potentials,Growth, CombatPower] =
        [Pet#player_pet.id,Pet#player_pet.name,Pet#player_pet.level,Pet#player_pet.quality,Pet#player_pet.base_aptitude + Pet#player_pet.extra_aptitude, Pet#player_pet.figure,Pet#player_pet.nimbus,Pet#player_pet.potentials,Pet#player_pet.growth, Pet#player_pet.combat_power],
    _UnrealFigureList = lists:map(fun(Record) ->
			       Bin = parse_pet_figure_change(Record),
			       Bin
		       end, UnrealFigureList),
    PotentialLv = calc_potential_average_lev(_Potentials),
    PetNameBin = pt:write_string(PetName),
    PlayerNameBin = pt:write_string(PlayerName),
    FigureListLen = length(_UnrealFigureList),
    FigureListBin = list_to_binary(_UnrealFigureList),
    <<Id:32, PetNameBin/binary, PlayerNameBin/binary, Level:16, Quality:8, FigureListLen:16, FigureListBin/binary, Figure:16, Nimbus:16, Aptitude:16, Growth:32, PotentialLv:16, CombatPower:32, FigureChangeVal:32>>.


parse_show_pet_info(Id,Name,Level,Quality,Forza,Wit,Agile,Thew,Aptitude,Figure,Nimbus,ExtraAptitudeMax, Growth,CombatPower) ->
    NameLen = byte_size(Name),
    <<Id:32,NameLen:16,Name/binary,Level:16,Quality:8,Forza:16,Wit:16,Agile:16,Thew:16,Aptitude:16,Figure:16,Nimbus:16,ExtraAptitudeMax:16,Growth:32,CombatPower:32>>.

parse_potential_info(Potential) ->
    PetId = Potential#pet_potential.pet_id,
    PotentialTypeId = Potential#pet_potential.potential_type_id,
    Location = Potential#pet_potential.location,
    Lv = Potential#pet_potential.lv,
    Exp = Potential#pet_potential.exp,
    Name = Potential#pet_potential.name,
    NameLen = byte_size(Name),
    NewLevelExp = data_pet_potential:get_level_exp(Lv),
    <<PetId:32, PotentialTypeId:32, Location:16, Lv:16, Exp:32, NameLen:16, Name/binary, NewLevelExp:32>>.

parse_pet_skill(PetSkill) ->
    SkillId     = PetSkill#pet_skill.id,
    SkillTypeId = make_pet_skill_type_id(PetSkill#pet_skill.type_id, PetSkill#pet_skill.level),
    SkillLevel  = PetSkill#pet_skill.level,
    SkillType = PetSkill#pet_skill.type,
    <<SkillId:32, SkillTypeId:32, SkillLevel:16, SkillType:8>>.

parse_pet_figure_change(UnrealFigure) ->
    TypeId = UnrealFigure#pet_activate_figure.type_id,
    Figure = UnrealFigure#pet_activate_figure.figure_id,
    ChangeFlag = UnrealFigure#pet_activate_figure.change_flag,
    ActivateFlag = UnrealFigure#pet_activate_figure.activate_flag,
    LastTime = UnrealFigure#pet_activate_figure.last_time,
    <<TypeId:32, Figure:16, ChangeFlag:8, ActivateFlag:8, LastTime:32>>.
%%=========================================================================
%% 日志服务
%%=========================================================================

%% -----------------------------------------------------------------
%% 记录操作日志
%% -----------------------------------------------------------------
log_pet(Type, PlayerId, PetId, Param) ->
    spawn(fun()->
		  case Type of
    
		      %% 升级
		      upgrade_pet ->
			  [OldLevel, NewLevel] = Param,
			  Format = data_pet_text:get_msg(1),
			  Info = io_lib:format(Format, [OldLevel, NewLevel]),
			  [TypeNew, Status, InfoNew] = [1, 1, Info],
			  NowTime = util:unixtime(),
			  Data = [PlayerId, PetId, NowTime, TypeNew, Status, InfoNew],
			  SQL = io_lib:format(?SQL_LOG_PET_INSERT, Data),
			  db:execute(SQL);
		      %% 成长
		      grow_up ->
			  [GrowthType, GrowthMul, OldExp, Exp, OldGrowth, Growth, _GrowthExp] = Param,
			  SQL = io_lib:format(?SQL_LOG_PET_INSERT_GROWTH, [PlayerId, PetId, GrowthType, GrowthMul, OldExp, Exp, OldGrowth, Growth, util:unixtime()]),
			  db:execute(SQL);
		      %% 放生
		      free_pet ->
			  [Name, Level, Aptitude, Growth, Skills, _Potentials, TypeId] = Param,
			  NowTime = util:unixtime(),
			  SkillsString = util:term_to_string([{Skill#pet_skill.type_id, Skill#pet_skill.level, Skill#pet_skill.type}||Skill<-Skills]),
			  PotentialsLv = calc_potential_average_lev(_Potentials),
			  Data = [PlayerId, PetId, Name, Level, Aptitude, Growth, SkillsString, PotentialsLv, NowTime, TypeId],
			  SQL = io_lib:format(<<"insert into log_pet_free(player_id,pet_id,name,lv,aptitude,growth,skills,potentials,ts,type_id) values(~p,~p,'~s',~p,~p,~p,'~s',~p,~p,~p)">>, Data),
			  db:execute(SQL);
		      %% 继承
		      derive_pet ->
			  [PetId1, Name1, Level1, Aptitude1, _AptitudeThreshold1, Growth1, _Potentials1, Pet1BaseAttr, PetId2, Name2, Level2, Aptitude2, _AptitudeThreshold2, Growth2, _Potentials2, Pet2BaseAttr, NewPetInfo] = Param,
			  %% InfoList:[1,2,3,[1,2,3,4]]
			  PetInfo1 = data_pet_text:translate_pet_info([Level1, Aptitude1, Growth1, Pet1BaseAttr]),
			  PetInfo2 = data_pet_text:translate_pet_info([Level2, Aptitude2, Growth2, Pet2BaseAttr]),
			  DeriveInfo = data_pet_text:translate_pet_info(NewPetInfo),
			  SQL = io_lib:format(?SQL_LOG_PET_INSERT_DERIVE, [PlayerId, PetId1, Name1, PetInfo1, PetId2, Name2, PetInfo2, DeriveInfo, util:unixtime()]),
			  db:execute(SQL);
		      %% 潜能修行
		      practice_potential ->
			  [PracticeType, ExpRatio, PotentialTypeId, _Potentialname, OldExp, OldLv, PotentialExp, PotentialLv] = Param,
			  SQL = io_lib:format(?SQL_LOG_PET_INSERT_POTENTIAL, [PlayerId, PetId, PracticeType, PotentialTypeId, ExpRatio, OldExp, PotentialExp, OldLv, PotentialLv, util:unixtime()]),
			  db:execute(SQL);
		      %% 孵化
		      incubate_pet ->
			  [EggId, _PetFigure, PetAptitude, _PetGrowth, _PetMaxinumGrowth] = Param,
			  SQL = io_lib:format(?SQL_LOG_PET_INSERT_INCUBATE, [PlayerId, EggId, PetId, PetAptitude, util:unixtime()]),
			  db:execute(SQL);
		      %% 砸蛋
		      egg_broken ->
			  [Growth, Aptitude, CoinCost, Mult, AddExp, Again] = Param,
			  Format = data_pet_text:get_msg(8),
			  Info = io_lib:format(Format, [Growth, Aptitude, CoinCost, Mult, AddExp, Again]),
			  [TypeNew, Status, InfoNew] = [3, 1, Info],
			  NowTime = util:unixtime(),
			  Data = [PlayerId, PetId, NowTime, TypeNew, Status, InfoNew],
			  SQL = io_lib:format(?SQL_LOG_PET_INSERT, Data),
			  db:execute(SQL);
		      %% 技能遗忘
		      forget_skill ->
			  [IsReplace, GoodsTypeId, OldPetSkillId, NewPetSkillId, LockList, Tips] = Param,
			  SQL = io_lib:format(?SQL_LOG_PET_INSERT_SKILL, [PlayerId, PetId, GoodsTypeId, IsReplace, OldPetSkillId, NewPetSkillId, util:unixtime(), LockList, Tips]),
			  db:execute(SQL);
		      %% 技能学习
		      learn_skill ->
			  [IsReplace, GoodsTypeId, OldPetSkillId, NewPetSkillId, LockList, Tips] = Param,
			  SQL = io_lib:format(?SQL_LOG_PET_INSERT_SKILL, [PlayerId, PetId, GoodsTypeId, IsReplace, OldPetSkillId, NewPetSkillId, util:unixtime(), LockList, Tips]),
			  db:execute(SQL)
		  end
	  end).

%% -----------------------------------------------------------------
%% 删除操作日志
%% -----------------------------------------------------------------
delete_log() ->
    NowTime    = util:unixtime(),
    LogSaveLog = data_pet:get_pet_config(log_save_time, []),
    ExpireTime = NowTime - LogSaveLog,
    Data = [ExpireTime],
    SQL = io_lib:format(?SQL_LOG_PET_DELETE, Data),
    db:execute(SQL).

%%=========================================================================
%% 定时服务
%%=========================================================================

%% -----------------------------------------------------------------
%% 删除角色
%% -----------------------------------------------------------------
delete_role(PlayerId) ->
    %% 1- 删除宠物
    Data = [PlayerId],
    SQL  = io_lib:format(?SQL_PET_DELETE_ROLE, Data),
    db:execute(SQL),
    delete_all_pet(PlayerId),
    ok.

%% -----------------------------------------------------------------
%% 邮件服务
%% -----------------------------------------------------------------
send_mail(SubjectType, Param) ->
    [NameListNew, TitleNew, ContentNew] = case SubjectType of
					      upgrade_level ->
                                                  [PlayerName, PetName, Level] = Param,
                                                  NameList = [PlayerName],
                                                  [Title, Format] = data_pet_text:get_msg(9),
                                                  Content = io_lib:format(Format, [PetName, Level]),
                                                  [NameList, Title, Content];
                                              _ ->
                                                  [[], "", <<>>]
                                          end,
    mod_disperse:rpc_cast_by_id(?UNITE, lib_mail, send_sys_mail, [NameListNew, TitleNew, ContentNew]).

%% -----------------------------------------------------------------
%% 发送宠物形象改变通知
%% -----------------------------------------------------------------
send_figure_change_notify(Scence, CopyId, X, Y, PlayerId, Platform, SerNum, Figure, Nimbus, Level, Name, Aptitude) ->
    {ok, BinData} = pt_120:write(12033, [PlayerId, Platform, SerNum, Figure, Nimbus, Level, Name, data_pet:get_quality(Aptitude)]),
    lib_server_send:send_to_area_scene(Scence, CopyId, X, Y, BinData).

%% -----------------------------------------------------------------
%% 计算宠物属性
%% -----------------------------------------------------------------
calc_pet_attribute(Forza, Wit, Agile, Thew, Aptitude) ->
    Hp = round(Thew*11.5*Aptitude/1000),
    Mp = round(Thew*1.15*Aptitude/1000),
    Att = round(Forza*1.3*Aptitude/1000)+round(Wit*1.3/4*Aptitude/1000)+round(Agile*1.3/4*Aptitude/1000),
    Def = round(Thew*1.15*Aptitude/1000),
    Hit = round(Wit*2.1*Aptitude/1000),
    Dodge = round(Agile*1.75*Aptitude/1000),
    Crit = 0,
    Ten = 0,
    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten].

%% -----------------------------------------------------------------
%% 计算升级经验
%% -----------------------------------------------------------------
% calc_upgrade_exp(FightFlag, FightStartTime, UpgradeExp, Level, PlayerId) ->
%     case FightFlag of
%         0 -> UpgradeExp;
%         1 ->
%             NowTime         = util:unixtime(),
%             UpgradeExpTemp  = case lib_player:get_player_buff(PlayerId, 3, 61) of
%                                   []    -> round(UpgradeExp+(NowTime-FightStartTime));
%                                   [R|_] -> round(UpgradeExp+(NowTime-FightStartTime)*(1+R#ets_buff.value))
%                               end,
%             NextLevelExp = data_pet:get_upgrade_info(Level),
%             UpgradeExpMax                  = data_pet:get_pet_config(maxinum_upgrade_exp, []),
%             UpgradeExpMaxTotal             = NextLevelExp+UpgradeExpMax,
%             case UpgradeExpTemp =< UpgradeExpMaxTotal of
%                 true ->  UpgradeExpTemp;
%                 false->  UpgradeExpMaxTotal
%             end
%     end.
%% 计算宠物经验
calc_upgrade_exp(FightFlag, FightStartTime, UpgradeExp, PlayerLevel, PlayerId) ->
  case FightFlag of
    0 ->
        UpgradeExp;
    1 ->
        NowTime = util:unixtime(),
        AddExp = round((NowTime - FightStartTime)/60*0.0008*(50+PlayerLevel)*(50+PlayerLevel)),
        UpgradeExpTemp = case lib_player:get_player_buff(PlayerId, 3, 61) of
            [] -> round(UpgradeExp + AddExp);
            [R|_] -> round(UpgradeExp + AddExp*(1+R#ets_buff.value))
        end,
        NextLevelExp = data_pet:get_upgrade_info(PlayerLevel),
        case UpgradeExpTemp >= NextLevelExp of 
          true -> NextLevelExp+1;
          false ->  UpgradeExpTemp
        end
  end.



%% -----------------------------------------------------------------
%% 计算宠物属性加点到角色的影响
%% -----------------------------------------------------------------
calc_player_attribute(Status, PetAttr) ->
    %% 重新计算人物属性
    Pt = Status#player_status.pet,
    Status1 = Status#player_status{pet=Pt#status_pet{pet_attribute       = PetAttr}},
    Status2 = lib_player:count_player_attribute(Status1),
    %% 内息上限有变化则通知客户端
    if  Status1#player_status.hp_lim =/= Status2#player_status.hp_lim ->
            {ok, SceneData} = pt_120:write(12009, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status2#player_status.hp, Status2#player_status.hp_lim]),
            lib_server_send:send_to_area_scene(Status2#player_status.scene, Status2#player_status.copy_id, Status2#player_status.x, Status2#player_status.y, SceneData);
        true ->
            void
    end,
    %% 通知客户端角色属性改变
    lib_player:send_attribute_change_notify(Status2, 1),
    Status2.

%% -----------------------------------------------------------------
%% 计算宠物属性加点到角色的影响
%% -----------------------------------------------------------------
calc_player_attribute(Status, PetAttr, PetSkillAttr) ->
    %% 重新计算人物属性
    Pt = Status#player_status.pet,
    Status1 = Status#player_status{pet=Pt#status_pet{pet_attribute       = PetAttr,
						     pet_skill_attribute = PetSkillAttr}},
    Status2 = lib_player:count_player_attribute(Status1),
    %% 内息上限有变化则通知客户端
    if  Status1#player_status.hp_lim =/= Status2#player_status.hp_lim ->
            {ok, SceneData} = pt_120:write(12009, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status2#player_status.hp, Status2#player_status.hp_lim]),
            lib_server_send:send_to_area_scene(Status2#player_status.scene, Status2#player_status.copy_id, Status2#player_status.x, Status2#player_status.y, SceneData);
        true ->
            void
    end,
    %% 通知客户端角色属性改变
    lib_player:send_attribute_change_notify(Status2, 1),
    Status2.

calc_player_attribute(Status) ->
    %% 重新计算人物属性
    Status1 = lib_player:count_player_attribute(Status),
    %% 内息上限有变化则通知客户端
    if  Status#player_status.hp_lim =/= Status1#player_status.hp_lim ->
            {ok, SceneData} = pt_120:write(12009, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status1#player_status.hp, Status1#player_status.hp_lim]),
            lib_server_send:send_to_area_scene(Status1#player_status.scene, Status1#player_status.copy_id, Status1#player_status.x, Status1#player_status.y, SceneData);
        true ->
            void
    end,
    %% 通知客户端角色属性改变
    lib_player:send_attribute_change_notify(Status1, 1),
    Status1.

calc_player_attribute(Status, PetAttr, PetSkillAttr, PetPotentialAttr, BaseAptitudeAttr) ->
    %% 重新计算人物属性
    Pt = Status#player_status.pet,
    Status1 = Status#player_status{pet=Pt#status_pet{pet_attribute          = PetAttr,
						     pet_skill_attribute     = PetSkillAttr,
						     pet_potential_attribute = PetPotentialAttr,
                 pet_aptitude_attribute = BaseAptitudeAttr}},
    Status2 = lib_player:count_player_attribute(Status1),
    %% 内息上限有变化则通知客户端
    if  Status1#player_status.hp_lim =/= Status2#player_status.hp_lim ->
            {ok, SceneData} = pt_120:write(12009, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status2#player_status.hp, Status2#player_status.hp_lim]),
            lib_server_send:send_to_area_scene(Status2#player_status.scene, Status2#player_status.copy_id, Status2#player_status.x, Status2#player_status.y, SceneData);
        true ->
            void
    end,
    %% 通知客户端角色属性改变
    lib_player:send_attribute_change_notify(Status2, 1),
    Status2.

calc_player_attribute_by_pet_potential_attr(Status, PetPotentialAttr) ->
    %% 重新计算人物属性
    Pt = Status#player_status.pet,
    Status1 = Status#player_status{pet=Pt#status_pet{pet_potential_attribute = PetPotentialAttr}},
    Status2 = lib_player:count_player_attribute(Status1),
    %% 内息上限有变化则通知客户端
    if  Status1#player_status.hp_lim =/= Status2#player_status.hp_lim ->
            {ok, SceneData} = pt_120:write(12009, [Status2#player_status.id, Status2#player_status.platform, Status2#player_status.server_num, Status2#player_status.hp, Status2#player_status.hp_lim]),
            lib_server_send:send_to_area_scene(Status2#player_status.scene, Status2#player_status.copy_id, Status2#player_status.x, Status2#player_status.y, SceneData);
        true ->
            void
    end,
    %% 通知客户端角色属性改变
    lib_player:send_attribute_change_notify(Status2, 1),
    Status2.

%% -----------------------------------------------------------------
%% 判断体力值扣减是否改变角色属性
%% -----------------------------------------------------------------
is_strength_deduct_change_attribute(Strength, NewStrength, StrengthThreshold) ->
    StengthPercent    = Strength/StrengthThreshold,
    NewStengthPercent = NewStrength/StrengthThreshold,
    if  ((StengthPercent >= 0)   and (NewStengthPercent == 0)) -> true;
        true -> false
    end.

%% -----------------------------------------------------------------
%% 判断体力值增加是否改变角色属性
%% -----------------------------------------------------------------
is_strength_add_change_attribute(Strength, NewStrength, StrengthThreshold) ->
    StengthPercent    = Strength/StrengthThreshold,
    NewStengthPercent = NewStrength/StrengthThreshold,
    if  ((StengthPercent == 0)   and (NewStengthPercent > 0)) -> true;
        true -> false
    end.

%% -----------------------------------------------------------------
%% 获取最大宠物数
%% -----------------------------------------------------------------
get_pet_maxnum(PetCapacity) ->
    [BaseCapacity, MaxCapacity] = data_pet:get_pet_config(capacity, []),
    Capacity = BaseCapacity+PetCapacity,
    case Capacity >= MaxCapacity of
        true -> MaxCapacity;
        false-> Capacity
    end.

%% -----------------------------------------------------------------
%% 宠物操作
%% -----------------------------------------------------------------
get_fighting_pet(_PlayerId) ->
    _PetList = lib_dict:get(pet),
    PetList = lists:filter(fun(_Pet) -> _Pet#player_pet.fight_flag =:= 1 end, _PetList),
    PetNum  = length(PetList),
    case PetNum == 1 of
        true ->
            lists:last(PetList);
        false when PetNum > 1 ->
            {PetList1, PetList2} = lists:split(1, PetList),
            Fun = fun(Pet) ->
			  %% 更新缓存
			  NewPet = Pet#player_pet{fight_flag = 0},
			  update_pet(NewPet),
			  %% 更新数据库
			  Data = [0, Pet#player_pet.id],
			  SQL  = io_lib:format(?SQL_PET_UPDATE_FIGHT, Data),
			  db:execute(SQL)
                  end,
            lists:foreach(Fun, PetList2),
            lists:last(PetList1);
        false ->
            []
    end.

get_pet(_PlayerId, PetId) ->
    lib_dict:get(pet, PetId).

get_pet(PetId) ->
    lib_dict:get(pet, PetId).

get_all_pet(_PlayerId) ->
    lib_dict:get(pet).

get_pet_count(PlayerId) ->
    length(get_all_pet(PlayerId)).

update_pet(Pet) ->
    lib_dict:update(pet, Pet).

delete_pet(PetId) ->
    lib_dict:erase(pet, PetId).

delete_all_pet(_PlayerId) ->
    lib_dict:erase(pet).

%% -----------------------------------------------------------------
%% 宠物物品配置
%% -----------------------------------------------------------------
get_base_goods_pet(Id) ->
    data_pet_goods:get(Id).

calc_potential_attr_base(PetPotentials) ->
    F = fun(PetPotential, PetPotentialAttr) ->
                [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug] = PetPotentialAttr,
		case PetPotential#pet_potential.potential_type_id of
		    2 ->
			AdjustPotential = lists:keyfind(1, 3, PetPotentials),
			Addition = data_pet_potential:get_potential_addition(AdjustPotential#pet_potential.lv, AdjustPotential#pet_potential.potential_type_id);
		    12 -> Addition = 0;
		    _ -> Addition = data_pet_potential:get_potential_addition(PetPotential#pet_potential.lv, PetPotential#pet_potential.potential_type_id)
		end,
                [NewHp, NewMp, NewAtt, NewDef, NewHit, NewDodge, NewCrit, NewTen, NewFire, NewIce, NewDrug] = 
		    case PetPotential#pet_potential.potential_type_id of
			1 ->
			    {HpAddition, MpAddition} = Addition,
			    [HpAddition, MpAddition, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
			2 ->
			    {HpAddition, MpAddition} = Addition,
			    [HpAddition, MpAddition, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
			3 ->
			    [Hp, Mp, Addition, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
			4 ->
			    [Hp, Mp, Att, Addition, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
			5 ->
			    [Hp, Mp, Att, Def, Addition, Dodge, Crit, Ten, Fire, Ice, Drug];
			6 ->
			    [Hp, Mp, Att, Def, Hit, Addition, Crit, Ten, Fire, Ice, Drug];
			7 ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Addition, Ten, Fire, Ice, Drug];
			8 ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Addition, Fire, Ice, Drug];
			9 ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Addition, Ice, Drug];
			10 ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Addition, Drug];
			11 ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Addition];
			_ ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug]
		    end,
                [NewHp, NewMp, NewAtt, NewDef, NewHit, NewDodge, NewCrit, NewTen, NewFire, NewIce, NewDrug]
        end,
    PetPotentialAttr1 = lists:foldl(F, [0,0,0,0,0,0,0,0,0,0,0], PetPotentials),
    PetPotentialAttr1.

calc_potential_attr(Pet) ->
    [HpB, MpB, AttB, DefB, HitB, DodgeB, CritB, TenB, FireB, IceB, DrugB] = Pet#player_pet.pet_potential_attr,
    [PPAHp, PPAMp, PPAAtt, PPADef, PPAHit, PPADodge, PPACrit, PPATen, PPAFire, PPAIce, PPADrug] = Pet#player_pet.pet_potential_phase_addition,
    [HpB+PPAHp, MpB+PPAMp, AttB+PPAAtt, DefB+PPADef, HitB+PPAHit, DodgeB+PPADodge, CritB+PPACrit, TenB+PPATen, FireB+PPAFire, IceB+PPAIce, DrugB+PPADrug].

get_next_potential_addition(PetPotentials) ->
    F = fun(PetPotential, PetPotentialAttr) ->
                [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug] = PetPotentialAttr,
		case PetPotential#pet_potential.potential_type_id of
		    2 ->
			AdjustPotential = lists:keyfind(1, 3, PetPotentials),
			Addition = data_pet_potential:get_potential_addition(AdjustPotential#pet_potential.lv + 1, AdjustPotential#pet_potential.potential_type_id);
		    12 -> Addition = 0;
		    _ -> Addition = data_pet_potential:get_potential_addition(PetPotential#pet_potential.lv+1, PetPotential#pet_potential.potential_type_id)
		end,
                [NewHp, NewMp, NewAtt, NewDef, NewHit, NewDodge, NewCrit, NewTen, NewFire, NewIce, NewDrug] = 
		    case PetPotential#pet_potential.potential_type_id of
			1 ->
			    {HpAddition, MpAddition} = Addition,
			    [HpAddition, MpAddition, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
			2 ->
			    {HpAddition, MpAddition} = Addition,
			    [HpAddition, MpAddition, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
			3 ->
			    [Hp, Mp, Addition, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
			4 ->
			    [Hp, Mp, Att, Addition, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
			5 ->
			    [Hp, Mp, Att, Def, Addition, Dodge, Crit, Ten, Fire, Ice, Drug];
			6 ->
			    [Hp, Mp, Att, Def, Hit, Addition, Crit, Ten, Fire, Ice, Drug];
			7 ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Addition, Ten, Fire, Ice, Drug];
			8 ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Addition, Fire, Ice, Drug];
			9 ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Addition, Ice, Drug];
			10 ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Addition, Drug];
			11 ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Addition];
			_ ->
			    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug]
		    end,
                [NewHp, NewMp, NewAtt, NewDef, NewHit, NewDodge, NewCrit, NewTen, NewFire, NewIce, NewDrug]
        end,
    PetPotentialAttr1 = lists:foldl(F, [0,0,0,0,0,0,0,0,0,0,0], PetPotentials),
    PetPotentialAttr1.

get_goods_by_type_subtype(PS, Type, SubType) ->
    Dict = lib_goods_dict:get_player_dict(PS),
    lib_goods_util:get_list_by_subtype(Type, SubType, Dict).

%% ---------------------------------------------------------------------------
%% 修改记录: 宠物成长提升后经验值置0 
%%
%% ---------------------------------------------------------------------------
add_growth_exp(Status, Pet, {one, Value}) when is_record(Pet, player_pet) ->
    add_growth_exp(Status, Pet, Value);

add_growth_exp(Status, Pet, {five, Value}) when is_record(Pet, player_pet) ->
    add_growth_exp(Status, Pet, Value);

add_growth_exp(Status, Pet, {medicine, Value}) when is_record(Pet, player_pet) ->
    add_growth_exp(Status, Pet, Value);

add_growth_exp(_Status, Pet, {direct, Value}) when is_record(Pet, player_pet) ->
    OldGrowth = Pet#player_pet.growth,
    NewGrowth = OldGrowth+Value,
    [Aptitude, Level,Figure, ForzaScale, WitScale, AgileScale, ThewScale] = [Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude, Pet#player_pet.level,Pet#player_pet.figure, Pet#player_pet.forza_scale, Pet#player_pet.wit_scale, Pet#player_pet.agile_scale, Pet#player_pet.thew_scale],
    %%     [NewForzaScale, NewWitScale, NewAgileScale, NewThewScale] = data_pet:get_growth_scale(NewGrowth),
    [NewForza, NewWit, NewAgile, NewThew] = calc_attr(NewGrowth, Level, [ForzaScale, WitScale, AgileScale, ThewScale]),
    NewPetAttr = calc_pet_attribute(NewForza, NewWit, NewAgile, NewThew, Aptitude),
    {SubFigure, Nimbus} = data_pet:get_growth_phase_info(NewGrowth, figure), 
    NewFigure = make_pet_figure(get_pet_figure_type(Figure), SubFigure),
    BaseAddition = calc_base_addition([NewForza, NewWit, NewAgile, NewThew], [ForzaScale, WitScale, AgileScale, ThewScale], Pet#player_pet.level),
    %% 提升成长对额外资质上限的影响
    NewExtraAptitudeMax = data_pet:grow_to_aptitudemax(NewGrowth),
    NewPet = Pet#player_pet{ 
	       forza = NewForza,
	       wit = NewWit, 
	       agile = NewAgile,
	       thew = NewThew,
	       base_addition = BaseAddition,
	       growth=NewGrowth, 
	       pet_attr = NewPetAttr,
	       figure = NewFigure,
	       nimbus = Nimbus,
         extra_aptitude_max = NewExtraAptitudeMax
	      },
    update_pet(NewPet),
    GrowthExp = NewPet#player_pet.growth_exp,
    SQL = io_lib:format(?SQL_PET_UPDATE_UPGRADE_GROWTH, [NewForza,NewWit,NewAgile,NewThew,ForzaScale,WitScale,AgileScale,ThewScale,NewGrowth, GrowthExp, NewFigure, Nimbus, NewExtraAptitudeMax, NewPet#player_pet.id]),
    db:execute(SQL),
    [NewPetAttr, NewGrowth, NewPet#player_pet.growth_exp];

add_growth_exp(Status, Pet, Value) when is_record(Pet, player_pet) ->
    NewGrowthExp = Pet#player_pet.growth_exp+Value,
    NextGrowthExp = data_pet:get_grow_exp(Pet#player_pet.growth),
    if
        %% 未提升成长
        NextGrowthExp > NewGrowthExp ->
            NewPet = Pet#player_pet{ growth_exp = NewGrowthExp },
            update_pet(NewPet),
            SQL = io_lib:format(?SQL_PET_UPDATE_GROWTHEXP, [NewGrowthExp, NewPet#player_pet.id]),
            db:execute(SQL),
            [NewPet#player_pet.pet_attr, NewPet#player_pet.growth, NewPet#player_pet.growth_exp];
        true ->
            %NewGrowthExp1 = NewGrowthExp-NextGrowthExp,
            OldGrowth = Pet#player_pet.growth,
            NewGrowth = OldGrowth+1,
            %% 升阶后就停下来了
            IsUpgradePhase = data_pet:is_growth_upgrade_phase(OldGrowth, NewGrowth),
            NewGrowthExp1 = case IsUpgradePhase =:= 1 of 
              true ->
                  0;
              false ->
                  NewGrowthExp - NextGrowthExp
            end,
            [Aptitude, Level, Figure, ForzaScale, WitScale, AgileScale, ThewScale] = [Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude, Pet#player_pet.level, Pet#player_pet.figure, Pet#player_pet.forza_scale, Pet#player_pet.wit_scale, Pet#player_pet.agile_scale, Pet#player_pet.thew_scale],
	    %% [Aptitude, Level, ForzaScale, WitScale, AgileScale, ThewScale] = [Pet#player_pet.aptitude, Pet#player_pet.level, Pet#player_pet.forza_scale, Pet#player_pet.wit_scale, Pet#player_pet.agile_scale, Pet#player_pet.thew_scale],
            [NewForza, NewWit, NewAgile, NewThew] = calc_attr(NewGrowth, Level, [ForzaScale, WitScale, AgileScale, ThewScale]),
            NewPetAttr = lib_pet:calc_pet_attribute(NewForza, NewWit, NewAgile, NewThew, Aptitude),
            {SubFigure, NewNimbus} = data_pet:get_growth_phase_info(NewGrowth, figure),
	    %% {NewFigure, NewNimbus} = data_pet:get_growth_phase_info(NewGrowth, figure),
            NewFigure = make_pet_figure(get_pet_figure_type(Figure), SubFigure),
            BaseAddition = calc_base_addition([NewForza, NewWit, NewAgile, NewThew], [ForzaScale, WitScale , AgileScale, ThewScale], Pet#player_pet.level),
            NewPetTmp = Pet#player_pet{ 
			  forza = NewForza,
			  wit = NewWit, 
			  agile = NewAgile,
			  thew = NewThew,
			  base_addition = BaseAddition,
			  growth=NewGrowth, 
			  growth_exp = NewGrowthExp1,
			  pet_attr = NewPetAttr,
			  figure = NewFigure,
			  nimbus = NewNimbus
			 },
	    CombatPower = lib_pet:calc_pet_comat_power_by_pet(Status, NewPetTmp),
      %% 提升成长对额外资质上限的影响
      NewExtraAptitudeMax = data_pet:grow_to_aptitudemax(NewGrowth),
	    NewPet = NewPetTmp#player_pet{combat_power = CombatPower,extra_aptitude_max = NewExtraAptitudeMax},
	    update_pet(NewPet),
	    update_combat_on_db(NewPet#player_pet.combat_power, NewPet#player_pet.id),
            SQL = io_lib:format(?SQL_PET_UPDATE_UPGRADE_GROWTH, [NewForza,NewWit,NewAgile,NewThew,ForzaScale,WitScale,AgileScale,ThewScale,NewGrowth, NewGrowthExp1, NewFigure, NewNimbus, NewExtraAptitudeMax, NewPet#player_pet.id]),
            db:execute(SQL),
            add_growth_exp(Status, NewPet, 0)
    end.

%% 基础总属性由升级带来
get_unalloc_attr_total(Growth, Level) ->
    BaseAttr = Level*16,
    [Percentage, Fixed] = data_pet:get_growth_addition(Growth),
    round(BaseAttr*(1+Percentage/100)+Fixed).
     


get_attr(UnallocAttr, Scale) ->
    round(UnallocAttr*Scale/100).

%% 计算总的一级属性值 升级属性+成长属性+成长阶段属性
calc_attr(Growth, Level, [ForzaScale, WitScale, AgileScale, ThewScale]) ->
    UnallocAttr = get_unalloc_attr_total(Growth, Level),
    Addition = data_pet:get_growth_phase_info(Growth, addition),
    Forza = get_attr(UnallocAttr, ForzaScale)+Addition,
    Wit = get_attr(UnallocAttr, WitScale)+Addition,
    Agile = get_attr(UnallocAttr, AgileScale)+Addition,
    Thew = get_attr(UnallocAttr, ThewScale)+Addition,
    [Forza, Wit, Agile, Thew].

%% 单级成长
%% @return: [TypeId,...]
filter_upgrade_potential(OldPotentials, NewPotentials) ->
    Filter =
	case OldPotentials =/= [] andalso NewPotentials =/= [] of
	    true ->
		lists:filter(fun(NewPotential) ->
				     case lists:keyfind(NewPotential#pet_potential.potential_type_id, 3, OldPotentials) of
					 false -> false;
					 OldPotential ->
					     OldPotential#pet_potential.lv < NewPotential#pet_potential.lv
				     end
			     end, NewPotentials);
	    false -> []
	end,
    lists:map(fun(P) -> P#pet_potential.potential_type_id end, Filter).

check_all_potential_exceed_limit_lv(Potentials, PetLv) ->
    ExceedList = lists:filter(fun(Potential) -> Potential#pet_potential.lv >= PetLv end, Potentials),
    length(ExceedList) >= 10.

%% 批量修行，如果升阶了就停下来
add_potential_exp2([], _PetId, _OldSingleNum, _Status, _PracticeType, List) -> List;
add_potential_exp2([H | T], PetId, OldSingleNum, Status, PracticeType, List) -> 
    PetTmp = get_pet(PetId),
    %% 新的潜能等级和修行卷
    NewAvgPotential = calc_potential_average_lev(PetTmp#player_pet.potentials),
    NewSingleNum = data_pet_potential:get_single_potential_goods_num(NewAvgPotential),
    case OldSingleNum =:= NewSingleNum of 
        true -> 
            {Type, {_Num, Exp, _Times}} = H,
            add_potential_exp(Status, PetTmp, Type, Exp, PracticeType),
            add_potential_exp2(T, PetId, OldSingleNum, Status, PracticeType, [H | List]);
        false -> 
            add_potential_exp2(T, PetId, OldSingleNum, Status, PracticeType, List)
    end.


%% [{11,{1,5,1}},{12,{2,15,3}},...]
add_potential_exp(Status, Pet, TypeExpList, PracticeType) ->
  %io:format("TypeExpList:~p~n", [TypeExpList]),
    %% 旧的平均潜能等级和修行卷
    OldAvgPotential = calc_potential_average_lev(Pet#player_pet.potentials),
    OldSingleNum = data_pet_potential:get_single_potential_goods_num(OldAvgPotential),
    PetId = Pet#player_pet.id,
    List = add_potential_exp2(TypeExpList, PetId, OldSingleNum, Status, PracticeType, []),
    List.

add_potential_exp(Status, Pet, 12, Exp, PracticeType) ->
    PetId = Pet#player_pet.id,
    F = fun(Type) ->
		PetTmp = get_pet(PetId),        
		add_potential_exp(Status, PetTmp, Type, Exp, PracticeType)
	end,
    lists:foreach(F, [1,3,4,5,6,7,8,9,10,11]);

    %% NewPet = get_pet(PetId),   
    %% {_PotentialAttrChangeFlag, NewPetPotentialAttr, UpGrade, _Type1, Exp1, Lv1} = add_potential_exp(Status, NewPet, 11, Exp),
    %% {1, NewPetPotentialAttr, UpGrade, 12, Exp1, Lv1};
add_potential_exp(Status, Pet, Type, Exp, PracticeType) ->
  %io:format("lib_pet Type:~p, Exp:~p~n", [Type, Exp]),
    Potentials = Pet#player_pet.potentials,
    if
        Potentials =:= []  -> 
            {0, [], failed, 0, 0, 0};
        true ->
            case lists:keyfind(Type, 3, Potentials) of
                false ->
                    {0, [], failed, 0, 0, 0};
                EtsPetPotential ->
                    %% if
                    %%     is_record(EtsPetPotential, pet_potential) /= true -> 
                    %%         {0, [], failed, 0, 0, 0};
                    %%     true ->
		    OldExp = EtsPetPotential#pet_potential.exp,
		    OldLv = EtsPetPotential#pet_potential.lv,
		    QSelectExpInDb = io_lib:format("select exp from pet_potential_exp where pet_id=~p and type_id=~p",[Pet#player_pet.id,Type]),
		    ExpInDb =
			if PracticeType =:= upgrade -> 0; %这种修行方式进来的经验已经是存在数据库中的暂存经验
			   true -> 
				case db:get_one(QSelectExpInDb) of
				    null -> 0;
				    Any -> Any
				end
			end,
		    NewExp = OldExp+Exp+ExpInDb,
        %io:format("lib_pet OldExp:~p, Exp:~p, ExpInDb:~p", [OldExp, Exp, ExpInDb]),
		    NewLevelExp = data_pet_potential:get_level_exp(EtsPetPotential#pet_potential.lv),
		    {ShouldUpLv, RemainExp} = calc_potential_lv_should_upgrade(OldLv, NewExp),
		    if
			%% NewLevelExp下一级潜能所需经验, NewExp当前经验+额外获得的经验
			NewLevelExp =< NewExp -> 
			    {NewEtsPetPotential, NewPetPotential} = 
				if
				    OldLv + ShouldUpLv > Pet#player_pet.level ->
					{_, ToPetLvRemainExp} = calc_potential_lv_to_pet_lv(OldLv, Pet#player_pet.level, NewExp),
					NewEtsPetPotentialTmp = EtsPetPotential#pet_potential{ lv = Pet#player_pet.level, exp = 0 },
					NewPetPotentialTmp = lists:keyreplace(Type, 3, Pet#player_pet.potentials, NewEtsPetPotentialTmp),
					Q1 = io_lib:format(<<"insert into pet_potential_exp set pet_id=~p, type_id=~p, player_id=~p, exp=~p on duplicate key update exp=~p">>,[Pet#player_pet.id, Type, Status#player_status.id, ToPetLvRemainExp, ToPetLvRemainExp]),
					db:execute(Q1),
					{NewEtsPetPotentialTmp, NewPetPotentialTmp};
				    %% {0, [], exceed_pet_lv, 0, 0, 0};
				    true ->
					NewExp1 = RemainExp,
					%% 要减了升级剩余经验
					QDPPE = io_lib:format(<<"delete from pet_potential_exp where pet_id=~p and type_id=~p">>, [Pet#player_pet.id, Type]),
					db:execute(QDPPE),
					NewEtsPetPotentialTmp = EtsPetPotential#pet_potential{ lv = OldLv + ShouldUpLv, exp = NewExp1 },
					NewPetPotentialTmp = lists:keyreplace(Type, 3, Pet#player_pet.potentials, NewEtsPetPotentialTmp),
					{NewEtsPetPotentialTmp, NewPetPotentialTmp}
				end,
			    [Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug] = Pet#player_pet.pet_potential_attr,
			    Addition = data_pet_potential:get_potential_addition(NewEtsPetPotential#pet_potential.lv, Type),
			    [NewHp, NewMp, NewAtt, NewDef, NewHit, NewDodge, NewCrit, NewTen, NewFire, NewIce, NewDrug] = 
				case Type of
				    1 ->
					{HpAddition, MpAddition} = Addition,
					[HpAddition, MpAddition, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
				    2 ->
					%% 不会有类型2，已经合并成1
					[Hp, 0, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
				    3 ->
					[Hp, Mp, Addition, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
				    4 ->
					[Hp, Mp, Att, Addition, Hit, Dodge, Crit, Ten, Fire, Ice, Drug];
				    5 ->
					[Hp, Mp, Att, Def, Addition, Dodge, Crit, Ten, Fire, Ice, Drug];
				    6 ->
					[Hp, Mp, Att, Def, Hit, Addition, Crit, Ten, Fire, Ice, Drug];
				    7 ->
					[Hp, Mp, Att, Def, Hit, Dodge, Addition, Ten, Fire, Ice, Drug];
				    8 ->
					[Hp, Mp, Att, Def, Hit, Dodge, Crit, Addition, Fire, Ice, Drug];
				    9 ->
					[Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Addition, Ice, Drug];
				    10 ->
					[Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Addition, Drug];
				    11 ->
					[Hp, Mp, Att, Def, Hit, Dodge, Crit, Ten, Fire, Ice, Addition]
				end,
			    PPA = data_pet_potential:calc_potential_phase_addition(calc_potential_average_lev(NewPetPotential)),
			    NewPetTmp = Pet#player_pet{ 
					  potentials = NewPetPotential, 
					  pet_potential_attr = [NewHp, NewMp, NewAtt, NewDef, NewHit, NewDodge, NewCrit, NewTen, NewFire, NewIce, NewDrug],
					  pet_potential_phase_addition = PPA
					 },
			    CombatPower = lib_pet:calc_pet_comat_power_by_pet(Status, NewPetTmp),
			    NewPet = NewPetTmp#player_pet{combat_power = CombatPower},
			    update_pet(NewPet),
			    lib_pet:update_combat_on_db(NewPet#player_pet.combat_power, NewPet#player_pet.id),
			    %% 更新数据库
			    SQL = io_lib:format(?SQL_PET_POTENTIAL_UPDATE_LV_EXP, [NewEtsPetPotential#pet_potential.lv, NewEtsPetPotential#pet_potential.exp, NewEtsPetPotential#pet_potential.pet_id, NewEtsPetPotential#pet_potential.potential_type_id]),
			    db:execute(SQL),
			    %% 记录日志
			    ExpPotential = data_pet_potential:get(Type),
			    log_pet(practice_potential, Status#player_status.id, NewPet#player_pet.id, [data_pet_text:translate_practice_type(PracticeType), 0, Type, ExpPotential#ets_base_pet_potential.name, OldExp, OldLv, NewEtsPetPotential#pet_potential.exp, NewEtsPetPotential#pet_potential.lv]);
			%% {1, NewPet#player_pet.pet_potential_attr, upgrade, Type, NewEtsPetPotential#pet_potential.exp, NewEtsPetPotential#pet_potential.lv}
			true ->
			    %% QDPPE = io_lib:format(<<"delete from pet_potential_exp where pet_id=~p and type_id=~p">>, [Pet#player_pet.id, Type]),
			    %% db:execute(QDPPE),
			    NewEtsPetPotential = EtsPetPotential#pet_potential{ exp = NewExp },
			    NewPetPotential = lists:keyreplace(Type, 3, Pet#player_pet.potentials, NewEtsPetPotential),
			    NewPet = Pet#player_pet{ potentials = NewPetPotential },
			    update_pet(NewPet),
			    %% 更新数据库
			    SQL = io_lib:format(?SQL_PET_POTENTIAL_UPDATE_EXP, [NewEtsPetPotential#pet_potential.exp, NewEtsPetPotential#pet_potential.pet_id, NewEtsPetPotential#pet_potential.potential_type_id]),
			    db:execute(SQL),
			    %% 记录日志
			    ExpPotential = data_pet_potential:get(Type),
			    log_pet(practice_potential, Status#player_status.id, NewPet#player_pet.id, [data_pet_text:translate_practice_type(PracticeType), 0, Type, ExpPotential#ets_base_pet_potential.name, OldExp, OldLv, NewEtsPetPotential#pet_potential.exp, NewEtsPetPotential#pet_potential.lv])
			    %% {0, [], noupgrade, Type, NewEtsPetPotential#pet_potential.exp, NewEtsPetPotential#pet_potential.lv}
		    end
	    end
    end.
%% 潜能按照所加经验需要增加的级数
calc_potential_lv_should_upgrade(OldLv, TotalExp) ->
    List = data_pet_potential:get_potentials_info(),
    LvExpList = [E || {L, E, _} <- List, L >= OldLv],
    %% lists:map(fun({L, E, _}) when L >= OldLv -> E end, List),
    lists:foldl(fun(Exp, {LvSum, RemainExp}) ->
			if
			    RemainExp >= Exp ->
				{LvSum + 1, RemainExp - Exp};
			    true ->
				{LvSum, RemainExp}
			end
		end, {0, TotalExp} , LvExpList).

%% 潜能按照所加经验升到与宠物等级相同时剩余经验
calc_potential_lv_to_pet_lv(OldLv, PetLv, TotalExp) ->
    List = data_pet_potential:get_potentials_info(),
    LvExpList = [E || {L, E, _} <- List, L >= OldLv],
    %% lists:map(fun({L, E, _}) when L >= OldLv -> E end, List),
    lists:foldl(fun(Exp, {LvSum, RemainExp}) ->
			if
			    LvSum >= PetLv ->
				{LvSum, RemainExp};
			    RemainExp >= Exp ->
				case LvSum + 1 =< PetLv of
				    true ->
					{LvSum + 1, RemainExp - Exp};
				    false ->
					{LvSum, RemainExp}
				end;
			    true ->
				{LvSum, RemainExp}
			end
		end, {OldLv, TotalExp} , LvExpList).

%% 按照所加经验升到与人物等级相同时剩余经验
calc_exp_to_player_lv(PetLv, PlayerLv, TotalExp) ->
    List = data_pet:get_upgrade_exp_info(),
    LvExpList = [E || {L, E} <- List, L >= PetLv],
    lists:foldl(fun(Exp, {LvSum, RemainExp}) ->
			if
			    LvSum >= PlayerLv ->
				{LvSum, RemainExp};
			    RemainExp >= Exp ->
				case LvSum + 1 =< PlayerLv of
				    true ->
					{LvSum + 1, RemainExp - Exp};
				    false ->
					{LvSum, RemainExp}
				end;
			    true ->
				{LvSum, RemainExp}
			end
		end, {PetLv, TotalExp} , LvExpList).

calc_base_addition([Forza, Wit, Agile, Thew], [ForzaScale, WitScale, AgileScale, ThewScale], PetLevel) ->
    ForzaAddition = util:ceil(Forza-PetLevel*16*ForzaScale/100),
    WitAddition   = util:ceil(Wit-PetLevel*16*WitScale/100),
    AgileAddition = util:ceil(Agile-PetLevel*16*AgileScale/100),
    ThewAddition  = util:ceil(Thew-PetLevel*16*ThewScale/100),
    [ForzaAddition, WitAddition, AgileAddition, ThewAddition].

get_maxinum_growth_pet(PlayerId) ->
    Pets = get_all_pet(PlayerId),
    PetNum = length(Pets),
    if
        Pets =:= [] -> [];
        PetNum =:= 1 -> hd(Pets);
        true ->
            F = fun(Pet1, Pet2) ->
			if
			    Pet1#player_pet.growth < Pet2#player_pet.growth -> true;
			    true -> false
			end
                end,
	    NewPets = lists:sort(F, Pets),
	    lists:last(NewPets)
    end.

calc_egg_broken_exp(Mult, PlayerLevel) ->
    PlayerLevel*PlayerLevel*167*Mult.
%% 经验技能没有等级,不算内力等级
calc_potential_average_lev(Potentials) ->
    Sum = lists:foldl(fun(Potential, Acc)->
			      case Potential#pet_potential.potential_type_id of
				  2 ->
				      Acc;
				  12 ->
				      Acc;
				  _ ->
				      Potential#pet_potential.lv+Acc
			      end
		      end, 0, Potentials),
    util:floor(Sum/(length(Potentials)-2)).

%% 计算经验技能总等级
calc_potential_average_total(Potentials) ->
    Sum = lists:foldl(fun(Potential, Acc)->
            case Potential#pet_potential.potential_type_id of
          2 ->
              Acc;
          12 ->
              Acc;
          _ ->
              Potential#pet_potential.lv+Acc
            end
          end, 0, Potentials),
    Sum.


get_pet_skill(PetId) ->
    Pet = get_pet(PetId),
    if
        Pet =:= [] -> [];
        true ->
            Pet#player_pet.skills
    end.
get_pet_skill_count(PetId) ->
    PetSkills = get_pet_skill(PetId),
    length(PetSkills).

get_pet_trigger_skill(PetId) ->
    PetSkills = get_pet_skill(PetId),
    lists:filter(fun(PetSkill)-> PetSkill#pet_skill.type =:= 1 end, PetSkills).

get_pet_passive_skill(PetId) ->
    PetSkills = get_pet_skill(PetId),
    lists:filter(fun(PetSkill)-> PetSkill#pet_skill.type =:= 0 end, PetSkills).

get_pet_active_skill(PetId) ->
    PetSkills = get_pet_skill(PetId),
    lists:filter(fun(PetSkill)-> PetSkill#pet_skill.type =:= 2 end, PetSkills).

get_pet_skill_id(PetId) ->
    PetSkills = get_pet_skill(PetId),
    lists:map(fun(PetSkill)-> PetSkill#pet_skill.type_id end, PetSkills).

%% #pet_skill | false
get_pet_skill_by_type_id(PetId, GoodsTypeId) ->
    PetSkills = get_pet_skill(PetId),
    lists:keyfind(GoodsTypeId, 4, PetSkills).
%% %% 获取不同级别的同种技能
%% get_same_skill_by_type_id(PetId, GoodsTypeId) ->
%%     PetSkills = get_pet_skill(PetId),
%%     SkillSeries = data_pet_skill:get_skill_series_by_goods_type_id(GoodsTypeId),
%%     SkillId = lists:filter(fun(X) ->
%% 				   case lists:keyfind(X, 4, PetSkills) of
%% 				       false -> false;
%% 				       _ -> true
%% 				   end
%% 			   end, SkillSeries),
%%     lists:keyfind(SkillId, 4, PetSkills).


%% 是否满足前置条件
is_learned_pre_skill(Skill, GoodsTypeId) ->
    case Skill of
	false ->
	    %% 未学过该类技能，先检查前置技能
	    NewSkillLv = data_pet_skill:get_skill_level_by_goods_type_id(GoodsTypeId),
	    case NewSkillLv =/= 1 of
		true ->
		    {false, 10}; %% 未学该技能的前置技能
		false ->
		    true
	    end;
	_ ->
	    NowSkillLv = Skill#pet_skill.level, 
	    NewSkillLv = data_pet_skill:get_skill_level_by_goods_type_id(GoodsTypeId),
	    if
		NowSkillLv + 1 < NewSkillLv ->
		    {false, 10}; %% 未学该技能的前置技能
		NowSkillLv >= NewSkillLv ->
		    {false, 8}; %% 已经存在同级或更高级技能
		true ->
		    true
	    end
    end.

make_pet_skill_type_id(SkillTypeId, SkillLv) ->
    BaseSkillId = data_pet_skill:get_skill_series_by_goods_type_id(SkillTypeId),
    BaseSkillId - 1 + SkillLv.

delete_pet_skill_by_pet_id_type_id(PetId, SkillTypeId) ->
    Pet = get_pet(PetId),
    if
        Pet =:= [] -> ok;
        true ->
            PetSkills = Pet#player_pet.skills,
            NewPetSkills = lists:keydelete(SkillTypeId, 4, PetSkills),
            NewPet = Pet#player_pet{ skills = NewPetSkills },
            update_pet(NewPet),
            ok
    end.

%% 学习主动技能检测
can_learn_second_active_skill(Pet, GoodsTypeId) ->
    BaseSkillId = data_pet_skill:get_skill_series_by_goods_type_id(GoodsTypeId),
    ActiveSkill = lists:filter(fun(PetSkill)-> PetSkill#pet_skill.type =:= 2 end, Pet#player_pet.skills),
    ActiveSkillCount = length(ActiveSkill),
    MaxActiveSkillCount = data_pet_skill:get_pet_config(maxinum_active_skill, []),
    %% 主动类技能最多学习2个     
    case ActiveSkillCount >= MaxActiveSkillCount of
	true ->
	    case lists:keymember(BaseSkillId, 4, ActiveSkill) of
		false ->
		    active_limit;
		true ->
		    true
	    end;
	false ->
	    LearnedActiveSkill = lists:keyfind(BaseSkillId, 4, ActiveSkill),
	    case LearnedActiveSkill of
		%% 学习新主动技能
		false ->
		    case ActiveSkillCount of
			%% 学习第一个主动技能
			0 ->
			    case Pet#player_pet.growth >= 25 of
				true -> true;
				false -> pal_limit
			    end;
			%% 学习第二个主动技能
			1 -> 
			    case Pet#player_pet.growth >= 35 of
				false -> pal_limit;
				true -> true
			    end
		    end;
		_ -> true
	    end
    end.

%% 学习被动技能检测
can_learn_passive_skill(Pet, GoodsTypeId) ->
    BaseSkillId = data_pet_skill:get_skill_series_by_goods_type_id(GoodsTypeId),
    PassiveSkill = lists:filter(fun(PetSkill)-> PetSkill#pet_skill.type =:= 0 end, Pet#player_pet.skills),
    PassiveSkillCount = length(PassiveSkill),
    MaxPassiveSkillCount = data_pet_skill:get_pet_config(maxinum_passive_skill, []),
    %% 被动类技能最多学习8个     
    case PassiveSkillCount >= MaxPassiveSkillCount of
	true ->
	    case lists:keymember(BaseSkillId, 4, PassiveSkill) of
		false ->
		    passive_limit;
		true ->
		    true
	    end;
	false ->
	    LearnedPassiveSkill = lists:keyfind(BaseSkillId, 4, PassiveSkill),
	    case LearnedPassiveSkill of
		%% 学习新被动技能
		false ->
		    case check_pal_passive_skill_count(calc_potential_average_lev(Pet#player_pet.potentials),PassiveSkillCount) of
			false ->
			    pal_limit;
			true -> true
		    end;
		_ -> true
	    end
    end.
%% PAL:潜能等级 PassiveSkillCount:当前被动技能个数
check_pal_passive_skill_count(PAL, PassiveSkillCount) ->
    L = data_pet_skill:get_pet_potential_skill(),
    case lists:keyfind(PassiveSkillCount + 1, 2, L) of
	false -> false;
	{PotentialLv, _} ->
	    PAL >= PotentialLv
    end.

%% -----------------------------------------------------------------
%% 学习新技能
%% @param:TypeId:宠物书Id
%% -----------------------------------------------------------------
learn_new_skill(Pet, TypeId, GoodsId, GoodsPid, GoodsUseNum, StoneList) ->
    %% 插入宠物
    Type = data_pet_skill:get_skill_type_by_goods_type(TypeId),
    case Type of
	%%学习的是主动技能
	2 ->
	    case can_learn_second_active_skill(Pet, TypeId) of
		true ->
		    learn_new_skill(Pet, TypeId, Type, GoodsId, GoodsPid, GoodsUseNum, StoneList, real);
		Limit ->
		    Limit
	    end;
	%% %%学习的是触发类技能
	%% 1 ->
	%%     TriggerSkillCount = length(lib_pet:get_pet_trigger_skill(Pet#player_pet.id)),
	%%     MaxTriggerSkillCount = data_pet_skill:get_pet_config(maxinum_trigger_skill, []),
	%%     %% 触发类技能最多学习2个     
	%%     case TriggerSkillCount >= MaxTriggerSkillCount of
	%% 	true ->
	%% 	    %% [9, Status, Pet#player_pet.id, 0, GoodsTypeId, 0, 0];
	%% 	    trigger_limit;
	%% 	false ->
	%% 	    learn_new_skill(Pet, TypeId, Type, GoodsId, GoodsPid, GoodsUseNum, StoneList, real)
	%%     end;
	0 ->
	    case can_learn_passive_skill(Pet, TypeId) of
		true ->
		    learn_new_skill(Pet, TypeId, Type, GoodsId, GoodsPid, GoodsUseNum, StoneList, real);
		Limit -> Limit
	    end
    end.

learn_new_skill(Pet, TypeId, Type, GoodsId, GoodsPid, GoodsUseNum, StoneList, real) ->
    PetId = Pet#player_pet.id,
    BaseSkillId = data_pet_skill:get_skill_series_by_goods_type_id(TypeId),
    NewSkillLv = data_pet_skill:get_skill_level_by_goods_type_id(TypeId),
    Skill = lists:keyfind(BaseSkillId, 4, Pet#player_pet.skills),
    case gen_server:call(GoodsPid, {'delete_list', [{GoodsId, GoodsUseNum}|StoneList]}) of
	1 ->
	    case Skill of
		false ->			%%学习新技能
		    Data = [PetId,  TypeId, Type, NewSkillLv],
		    SQL  = io_lib:format(?SQL_PET_SKILL_INSERT, Data),
		    db:execute(SQL),
		    %% 获取新学习的技能
		    Data1 = [PetId, TypeId],
		    SQL1  = io_lib:format(?SQL_PET_SKILL_SELECT_NEW, Data1),
		    SkillInfo = db:get_row(SQL1),
		    case SkillInfo of
			%% 失败
			[] -> 0;
			%% 成功
			_ ->
			    [Id,PetId, TypeId, Type, Level] = SkillInfo,
			    PetSkill = #pet_skill{
			      id = Id,
			      pet_id = PetId,
			      type_id = TypeId,
			      type = Type,
			      level = Level},
			    Pet1 = get_pet(PetId),
			    if
				Pet1 =:= [] ->
				    0;
				true ->
				    Skills = Pet1#player_pet.skills,
				    NewPet = Pet1#player_pet{ skills = [PetSkill|Skills] },
				    update_pet(NewPet),
				    %% 返回值
				    {ok, PetSkill#pet_skill.id, PetSkill#pet_skill.level, PetSkill#pet_skill.level}
			    end
		    end;
		Record when is_record(Record, pet_skill) ->				%%升级原有技能
		    PetSkills = Pet#player_pet.skills,
		    UpgradeSkill = Record#pet_skill{level = NewSkillLv},
		    NewPetSkills = lists:keyreplace(UpgradeSkill#pet_skill.type_id, 4, PetSkills, UpgradeSkill),
		    NewPet = Pet#player_pet{ skills = NewPetSkills },
		    update_pet(NewPet),
		    SQL = io_lib:format(<<"update pet_skill set level=~p where pet_id=~p and type_id=~p">>, [UpgradeSkill#pet_skill.level, PetId, UpgradeSkill#pet_skill.type_id]),
		    db:execute(SQL),
		    {ok, Record#pet_skill.id, Record#pet_skill.level, NewSkillLv}
	    end;
	_GoodsModuleCode ->
	    %% [0, Status, Pet#player_pet.id, 0, GoodsTypeId, 0, 0]
	    failed
    end.

get_skill_list(PetId, PetLevel) ->
    PetSkillList = get_pet_skill(PetId),
    if  %% 技能不存在
        PetSkillList =:= [] ->
            [[], get_zero_pet_skill_attribute()];
        true ->         
            [PetSkillList, calc_pet_skill_attribute(PetLevel,PetSkillList)]
    end.

%% 计算宠物技能加成
calc_pet_skill_attribute(PetLevel, PetSkillList) ->
    calc_pet_skill_attribute_helper(PetLevel,PetSkillList, get_zero_pet_skill_attribute()).
calc_pet_skill_attribute_helper(_PetLevel, [], SkillAttr) ->
    SkillAttr;
calc_pet_skill_attribute_helper(PetLevel, [H|T], SkillAttr) ->
    if
	%% type:0被动类 1触发类 2主动类
        H#pet_skill.type =:= 1 ->
            calc_pet_skill_attribute_helper(PetLevel, T, SkillAttr);
        H#pet_skill.type =:= 2 ->
            calc_pet_skill_attribute_helper(PetLevel, T, SkillAttr);
        true ->
            [HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio] = SkillAttr,
            NewSkillAttr = case data_pet_skill:get_skill_book_type(H#pet_skill.type_id) of
			       %% 气血
			       1 ->
				   Factor = data_pet_skill:get_skill_addition_factor(1, H#pet_skill.level),
				   RatioAdd = round(2000+PetLevel*Factor),
				   [HpLimRatio+RatioAdd, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
			       %% 内力
			       2 -> 
				   Factor = data_pet_skill:get_skill_addition_factor(2, H#pet_skill.level),
				   RatioAdd = round(220+PetLevel*Factor),
				   [HpLimRatio, MpLimRatio+RatioAdd, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
			       %% 攻击
			       3 -> 
				   Factor = data_pet_skill:get_skill_addition_factor(3, H#pet_skill.level),
				   RatioAdd = round(120+PetLevel*Factor),
				   [HpLimRatio, MpLimRatio, AttRatio+RatioAdd, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
			       %% 防御
			       4 -> 
				   Factor = data_pet_skill:get_skill_addition_factor(4, H#pet_skill.level),
				   RatioAdd = round(120+PetLevel*Factor),
				   [HpLimRatio, MpLimRatio, AttRatio, DefRatiot+RatioAdd, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
			       %% 命中
			       5 -> 
				   Factor = data_pet_skill:get_skill_addition_factor(5, H#pet_skill.level),
				   RatioAdd = round(72+PetLevel*Factor),
				   [HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio+RatioAdd, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
			       %% 躲避
			       6 -> 
				   Factor = data_pet_skill:get_skill_addition_factor(6, H#pet_skill.level),
				   RatioAdd = round(60+PetLevel*Factor),
				   [HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio+RatioAdd, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
			       %% 暴击
			       7 -> 
				   Factor = data_pet_skill:get_skill_addition_factor(7, H#pet_skill.level),
				   RatioAdd = round(12+PetLevel*Factor),
				   [HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio+RatioAdd, TenRatio, FireRatio, IceRatio, DrugRatio];
			       %% 坚韧
			       8 -> 
				   Factor = data_pet_skill:get_skill_addition_factor(8, H#pet_skill.level),
				   RatioAdd = round(24+PetLevel*Factor),
				   [HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio+RatioAdd, FireRatio, IceRatio, DrugRatio];
			       %% 火抗
			       9 -> 
				   Factor = data_pet_skill:get_skill_addition_factor(9, H#pet_skill.level),
				   RatioAdd = round(220+PetLevel*Factor),
				   [HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio+RatioAdd, IceRatio, DrugRatio];
			       %% 冰抗
			       10 -> 
				   Factor = data_pet_skill:get_skill_addition_factor(10, H#pet_skill.level),
				   RatioAdd = round(220+PetLevel*Factor),
				   [HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio+RatioAdd, DrugRatio];
			       %% 毒抗
			       11 -> 
				   Factor = data_pet_skill:get_skill_addition_factor(11, H#pet_skill.level),
				   RatioAdd = round(220+PetLevel*Factor),
				   [HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio+RatioAdd]
			   end,
            calc_pet_skill_attribute_helper(PetLevel, T, NewSkillAttr)        
    end.

calc_pet_skill_attribute2(PetLevel, Type) ->
    [HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio] = get_zero_pet_skill_attribute(),
    SkillAttr = case Type of
		    %% 气血
		    1 -> 
			RatioAdd = 100+PetLevel*2,
			[HpLimRatio+RatioAdd, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
		    %% 内力
		    2 -> 
			RatioAdd = 100+PetLevel*3,
			[HpLimRatio, MpLimRatio+RatioAdd, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
		    %% 攻击
		    3 -> 
			RatioAdd = 100+PetLevel*3,
			[HpLimRatio, MpLimRatio, AttRatio+RatioAdd, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
		    %% 防御
		    4 -> 
			RatioAdd = 100+PetLevel*4,
			[HpLimRatio, MpLimRatio, AttRatio, DefRatiot+RatioAdd, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
		    %% 命中
		    5 -> 
			RatioAdd = 100+PetLevel*5,
			[HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio+RatioAdd, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
		    %% 躲避
		    6 -> 
			RatioAdd = 100+PetLevel*6,
			[HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio+RatioAdd, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio];
		    %% 暴击
		    7 -> 
			RatioAdd = 100+PetLevel*7,
			[HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio+RatioAdd, TenRatio, FireRatio, IceRatio, DrugRatio];
		    %% 坚韧
		    8 -> 
			RatioAdd = 100+PetLevel*8,
			[HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio+RatioAdd, FireRatio, IceRatio, DrugRatio];
		    %% 火抗
		    9 -> 
			RatioAdd = 100+PetLevel*9,
			[HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio+RatioAdd, IceRatio, DrugRatio];
		    %% 冰抗
		    10 -> 
			RatioAdd = 100+PetLevel*10,
			[HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio+RatioAdd, DrugRatio];
		    %% 毒抗
		    11 -> 
			RatioAdd = 100+PetLevel*11,
			[HpLimRatio, MpLimRatio, AttRatio, DefRatiot, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio+RatioAdd]
		end,
    SkillAttr.
%% -----------------------------------------------------------------
%% 技能遗忘
%% -----------------------------------------------------------------
forget_skill(PetId, SkillTypeId) ->
    %% 更新宠物技能表
    Data = [PetId, SkillTypeId],
    SQL = io_lib:format(?SQL_PET_SKILL_DELETE_FORGET_SKILL, Data),
    db:execute(SQL),
    ok.
update_combat_on_db(CombatPower, PetId) ->
    SQL = io_lib:format(<<"update pet set combat_power=~p where id=~p">>, [CombatPower, PetId]),
    db:execute(SQL),
    ok.    

update_last_scale_on_db(ForzaScale, WitScale, AgileScale, ThewScale, PetId) ->
    SQL = io_lib:format(?SQL_PET_UPDATE_LAST_SCALE, [ForzaScale, WitScale, AgileScale, ThewScale, PetId]),
    db:execute(SQL),
    ok.

update_scale_on_db(ForzaScale, WitScale, AgileScale, ThewScale, PetId) ->
    SQL = io_lib:format(?SQL_PET_UPDATE_SCALE, [ForzaScale, WitScale, AgileScale, ThewScale, PetId]),
    db:execute(SQL),
    ok.

is_skill_book(GoodTypeId) ->
    SkillBooks = data_pet_skill:get_skill_books(),
    lists:member(GoodTypeId, SkillBooks).

is_goods_pet_card(GoodsType, GoodsSubtype) ->
    [EggGoodsType, EggGoodsSubType] = data_pet:get_pet_config(goods_pet_card,[]),
    (GoodsType =:= EggGoodsType andalso GoodsSubtype =:= EggGoodsSubType).

%% 宠物加成累计
count_pet_attribute(PlayerStatus) ->
    Pt = PlayerStatus#player_status.pet,
    [_PetHp,_PetMp,_PetAtt,_PetDef,_PetHit,_PetDodge,_PetCrit,_PetTen] = Pt#status_pet.pet_attribute,
    [_PetSkillHp,_PetSkillMp,_PetSkillAtt,_PetSkillDef,_PetSkillHit,_PetSkillDodge,_PetSkillCrit,_PetSkillTen,_PetSkillFire,_PetSkillIce,_PetSkillDrug] = Pt#status_pet.pet_skill_attribute,
    [_PetPotentialHp,_PetPotentialMp,_PetPotentialAtt,_PetPotentialDef,_PetPotentialHit, _PetPotentialDodge,_PetPotentialCrit,_PetPotentialTen,_PetPotentialFire,_PetPotentialIce, _PetPotentialDrug] = Pt#status_pet.pet_potential_attribute,
    [_PetFigureHp,_PetFigureMp,_PetFigureAtt,_PetFigureDef,_PetFigureHit,_PetFigureDodge,_PetFigureCrit,_PetFigureTen,_PetFigureFire,_PetFigureIce,_PetFigureDrug] =
	Pt#status_pet.pet_figure_attribute,
  [AptitudeHp, AptitudeAtt, AptitudeDef] = Pt#status_pet.pet_aptitude_attribute,
    PetHp    = _PetHp+_PetSkillHp+_PetPotentialHp+_PetFigureHp+AptitudeHp,
    PetMp    = _PetMp+_PetSkillMp+_PetPotentialMp+_PetFigureMp,
    PetAtt   = _PetAtt+_PetSkillAtt+_PetPotentialAtt+_PetFigureAtt+AptitudeAtt,
    PetDef   = _PetDef+_PetSkillDef+_PetPotentialDef+_PetFigureDef+AptitudeDef,
    PetHit   = _PetHit+_PetSkillHit+_PetPotentialHit+_PetFigureHit,
    PetDodge = _PetDodge+_PetSkillDodge+_PetPotentialDodge+_PetFigureDodge,
    PetCrit  = _PetCrit+_PetSkillCrit+_PetPotentialCrit+_PetFigureCrit,
    PetTen   = _PetTen+_PetSkillTen+_PetPotentialTen+_PetFigureTen,
    PetFire  = _PetSkillFire+_PetPotentialFire+_PetFigureFire, 
    PetIce   = _PetSkillIce+_PetPotentialIce+_PetFigureIce, 
    PetDrug  = _PetSkillDrug+_PetPotentialDrug+_PetFigureDrug,
    PetHit1 = if
		  _PetSkillHit =< 0 ->
		      64.8;
		  true ->
		      _PetSkillHit
	      end,
    PetHit2 = _PetHit+_PetPotentialHit+_PetFigureHit,
    [PetHp,PetMp,PetAtt,PetDef,PetHit,PetDodge,PetCrit,PetTen,PetFire, PetIce, PetDrug,PetHit1,PetHit2].

generate_born_pos(SceneId, X, Y) ->
    X1 = case X - 6 >= 0 of
	     true ->
		 X - 6;
	     false ->
		 0
	 end,
    Y1 = case Y - 6 >= 0 of
	     true ->
		 Y - 6;
	     false ->
		 0
	 end,
    RX = util:rand(X1, X + 6),
    RY = util:rand(Y1, Y + 6),
    case lib_scene:is_blocked(SceneId, RX, RY) of
        true ->
            generate_born_pos(SceneId, X, Y);
        false ->
            {RX, RY}
    end.

make_pet_figure(Type, SubType) ->
    Type*100+SubType.

get_pet_figure_type(Figure) ->
    util:floor(Figure/100).

is_pet_food(Type, Subtype) ->
    [_Type, _Subtype] = data_pet:get_pet_config(goods_pet_food, []),
    if
        Type == _Type andalso Subtype == _Subtype ->
            true;
        true ->
            false
    end.

is_pet_potential_medicine(Type, Subtype) ->
    [_Type, _Subtype] = data_pet:get_pet_config(goods_potential_spell, []),
    if
        Type == _Type andalso Subtype == _Subtype ->
            true;
        true ->
            false
    end.

is_pet_grow_up_medicine(Type, Subtype) ->
    [_Type, _Subtype] = data_pet:get_pet_config(goods_grow_up_medicine, []),
    if
        Type == _Type andalso Subtype == _Subtype ->
            true;
        true ->
            false
    end.
is_pet_aptitude_medicine(Type, Subtype) ->
    [_Type, _Subtype] = data_pet:get_pet_config(goods_aptitude_medicine, []),
    if
        Type == _Type andalso Subtype == _Subtype ->
            true;
        true ->
            false
    end.

is_pet_figure_card(Type, Subtype) ->
    [_Type, _Subtype] = data_pet:get_pet_config(goods_figure_card, []),
    if
        Type == _Type andalso Subtype == _Subtype ->
            true;
        true ->
            false
    end.

%% 激活宠物幻化形象
activate_new_figure(Status, TypeId, FigureId, ActivateFlag, ActivateValue, ActivateTime, LastTime, GoodsId, GoodsPid, GoodsUseNum) ->
    PlayerId = Status#player_status.id,
    case gen_server:call(GoodsPid, {'delete_one', GoodsId, GoodsUseNum}) of
	1 ->
	    ActivateFigureList = Status#player_status.unreal_figure_activate,
	    case get_figure_activate(ActivateFigureList, FigureId * 100) of
		%% 没有相同形象的激活，新增
		false ->
		    F = fun() ->
				SQL = io_lib:format(<<"insert into pet_figure_change(player_id,type_id,figure_id,change_flag,activate_flag,activate_time,last_time) values(~p,~p,~p,~p,~p,~p,~p)">>,[PlayerId,TypeId,FigureId,0,ActivateFlag,ActivateTime,LastTime]),
				db:execute(SQL),
				SQL2 = io_lib:format(<<"insert into pet_figure_change_value set player_id=~p, value=~p on duplicate key update value=~p">>,[PlayerId, Status#player_status.pet_figure_value + ActivateValue, Status#player_status.pet_figure_value + ActivateValue]),
				db:execute(SQL2)
			end,
		    db:transaction(F),
		    Status1 = Status#player_status{pet_figure_value = Status#player_status.pet_figure_value + ActivateValue},
		    SQL1= io_lib:format(<<"select * from pet_figure_change where player_id=~p and type_id=~p">>,[PlayerId, TypeId]),
		    case db:get_row(SQL1) of
			[] -> {failed, Status};
			R ->
			    [Id, PlayerId, TypeId, FigureId, ChangeFlag, ActivateFlag, ActivateTime, LastTime] = R,
			    %% 获取新激活的形象
			    BaseGoodsFigure = data_pet_figure:get(TypeId),
			    FigureAttr = case BaseGoodsFigure#base_goods_figure.figure_attr of
					     List when is_list(List) -> List;
					     _ -> []
					 end,
			    PetActivateFigure = #pet_activate_figure{
			      id = Id,
			      player_id = PlayerId,
			      type_id = TypeId,
			      figure_id = FigureId,
			      change_flag = ChangeFlag,
			      activate_flag = ActivateFlag,
			      activate_time = ActivateTime,
			      last_time = LastTime,
			      figure_attr = FigureAttr
			     },
			    ActivateFigures = Status1#player_status.unreal_figure_activate,
			    _Status2 = Status1#player_status{
					 unreal_figure_activate = [PetActivateFigure | ActivateFigures]
					},
			    PetFigureAttr = lib_pet:filter_figure_attr(_Status2#player_status.unreal_figure_activate),
			    Status2 = _Status2#player_status{pet = _Status2#player_status.pet#status_pet{pet_figure_attribute = PetFigureAttr}},
			    Status3 = calc_player_attribute(Status2),
			    pp_pet:handle(41002, Status3, [Status3#player_status.pet#status_pet.pet_id]),
			    {ok, Status3}
		    end;
		%% 已有相同形象的激活，替换
		ActivateFigure ->
		    SQL = io_lib:format(<<"update pet_figure_change set type_id=~p,activate_flag=~p,activate_time=~p,last_time=~p where id=~p">>,[TypeId,ActivateFlag,ActivateTime,LastTime,ActivateFigure#pet_activate_figure.id]),
		    db:execute(SQL),
		    ActivateFigures = Status#player_status.unreal_figure_activate,
		    NewActivateFigure = ActivateFigure#pet_activate_figure{
					  type_id = TypeId,
					  activate_flag = ActivateFlag,
					  activate_time = ActivateTime,
					  last_time = LastTime
					 },
		    NewActivateFigures = lists:keyreplace(ActivateFigure#pet_activate_figure.id, 2, ActivateFigures, NewActivateFigure),
		    NewStatus = Status#player_status{ unreal_figure_activate = NewActivateFigures},
		    {ok, NewStatus}
	    end;
	GoodsModuleCode ->
	    util:errlog("activate_figure: Call goods module failed, result code=[~p]", [GoodsModuleCode]),
	    %% [0, Status, Pet#player_pet.id, 0, GoodsTypeId, 0, 0]
	    {failed, Status}
    end.

get_figure_activate(ActivateFigureList, FigureId) ->
    case ActivateFigureList of
	[] -> false;
	_ ->
	    case lists:filter(fun(Record) -> lib_pet:make_pet_figure(Record#pet_activate_figure.figure_id,0) =:= FigureId end, ActivateFigureList) of
		[] -> false;
		ActivateFigure ->
		    hd(ActivateFigure)
	    end
    end.


load_pet_figure_activate(Id) ->
    %% 宠物幻化形象列表
    Q1 = io_lib:format(<<"select * from pet_figure_change where player_id=~p">>,[Id]),
    _FigureList = db:get_all(Q1),
    util:map_ex(fun make_record/2, _FigureList, pet_figure).

replace_using_figure(FigureList, ReplaceFigure) ->
    UsingFigure = lists:filter(fun(Record) ->
				       Record#pet_activate_figure.change_flag =:= 1
			       end, FigureList),
    case UsingFigure of
	[] ->
	    SQL = io_lib:format(<<"update pet_figure_change set change_flag=~p where id=~p">>,[1,ReplaceFigure#pet_activate_figure.id]),
	    db:execute(SQL),
	    NewActivateFigure = ReplaceFigure#pet_activate_figure{change_flag = 1},
	    lists:keyreplace(ReplaceFigure#pet_activate_figure.id, 2, FigureList, NewActivateFigure);
	R ->
	    Old = hd(R),
	    F = fun() ->
			SQL = io_lib:format(<<"update pet_figure_change set change_flag=~p where id=~p">>,[0,Old#pet_activate_figure.id]),
			db:execute(SQL),
			SQL1 = io_lib:format(<<"update pet_figure_change set change_flag=~p where id=~p">>,[1,ReplaceFigure#pet_activate_figure.id]),
			db:execute(SQL1)
		end,
	    db:transaction(F),
	    OldActivateFigure = Old#pet_activate_figure{change_flag = 0},
	    OldFigureList = lists:keyreplace(OldActivateFigure#pet_activate_figure.id, 2, FigureList, OldActivateFigure),
	    NewActivateFigure = ReplaceFigure#pet_activate_figure{change_flag = 1},
	    lists:keyreplace(ReplaceFigure#pet_activate_figure.id, 2, OldFigureList, NewActivateFigure)
    end.

get_using_figure(FigureList) ->
    lists:filter(fun(Record) ->
			 Record#pet_activate_figure.change_flag =:= 1
		 end, FigureList).
reset_figure_using_flag(FigureList) ->
    lists:map(fun(Record) ->
		      Record#pet_activate_figure{change_flag = 0}
	      end, FigureList).

filter_figure_attr(FigureList) ->
    lists:foldl(fun(Record, Sum) ->
			case Record#pet_activate_figure.figure_attr of
			    [] ->
				Sum;
			    Eleven ->
				[A,B,C,D,E,F,G,H,I,J,K] = Sum,
				[{1,A1},{2,B1},{3,C1},{4,D1},{5,E1},{6,F1},{7,G1},{8,H1},{9,I1},{10,J1},{11,K1}] = Eleven,
				[A+A1, B+B1, C+C1, D+D1, E+E1, F+F1, G+G1, H+H1, I+I1, J+J1, K+K1]
			end
		end, [0,0,0,0,0,0,0,0,0,0,0], FigureList).

get_figure_change_value(PlayerId) ->
    SQL = io_lib:format(<<"select `value` from pet_figure_change_value where player_id=~p">>,[PlayerId]),
    case db:get_one(SQL) of
	null ->
	    0;
	V -> V
    end.


is_exists_figure_change_pet(PlayerId) ->
    PetList = get_all_pet(PlayerId),
    case lists:filter(fun(Pet) -> Pet#player_pet.change_flag =:= 1 end,PetList) of
	[] ->
	    false;
	_ ->
	    true
    end.

get_exists_figure_change_pet(PlayerId) ->
    PetList = get_all_pet(PlayerId),
    case lists:filter(fun(Pet) -> Pet#player_pet.change_flag =:= 1 end,PetList) of
	[] ->
	    false;
	Pet ->
	    hd(Pet)
    end.

login_add_active_skill(Status, PetSkills) ->    
    %% 分离主动技能
    List = lists:filter(fun(X) -> X#pet_skill.type =:= 2 end, PetSkills),
    %% [{物品ID,等级}...]
    List1 = lists:map(fun(X) -> {make_pet_skill_type_id(X#pet_skill.type_id, X#pet_skill.level), X#pet_skill.level} end, List),
    %% [{技能ID,等级}...]
    List2 = lists:map(fun({SkillTypeId, _SkillLv}) ->
			      GoodsType = data_goods_type:get(SkillTypeId),
			      {GoodsType#ets_goods_type.skill_id, 1} end, List1),
    lib_skill:add_pet_skill(Status, List2).

add_active_skill(Status) ->
    FightingPet = lib_pet:get_pet(Status#player_status.pet#status_pet.pet_id),
    case FightingPet of
	[] -> Status;
	_ -> 
	    SkillTypeIdList = FightingPet#player_pet.skills,
	    %% 分离主动技能
	    List = lists:filter(fun(X) -> X#pet_skill.type =:= 2 end, SkillTypeIdList),
	    %% [{物品ID,等级}...]
	    List1 = lists:map(fun(X) -> {make_pet_skill_type_id(X#pet_skill.type_id, X#pet_skill.level), X#pet_skill.level} end, List),
	    %% [{技能ID,等级}...]
	    List2 = lists:map(fun({SkillTypeId, _SkillLv}) ->
				      GoodsType = data_goods_type:get(SkillTypeId),
				      {GoodsType#ets_goods_type.skill_id, 1} end, List1),
	    lib_skill:add_pet_skill(Status, List2)
    end.

del_active_skill(Status, PetId) ->
    Pet = lib_pet:get_pet(PetId),
    case Pet of
	[] -> Status;
	_ ->
	    SkillTypeIdList = Pet#player_pet.skills,
	    %% 分离主动技能
	    List = lists:filter(fun(X) -> X#pet_skill.type =:= 2 end, SkillTypeIdList),
	    %% [物品ID,...]
	    List1 = lists:map(fun(X) -> make_pet_skill_type_id(X#pet_skill.type_id, X#pet_skill.level) end, List),
	    %% [技能ID,...]
	    List2 = lists:map(fun(SkillTypeId) ->
				      GoodsType = data_goods_type:get(SkillTypeId),
				      GoodsType#ets_goods_type.skill_id end, List1),
	    lib_skill:del_pet_skill(Status, List2)
    end.
del_and_reload_pet_skill(Status) ->
    Status1 = lib_skill:del_all_pet_skill(Status),
    add_active_skill(Status1).

get_refresh_skill(Status) ->
    RefreshInfo = Status#player_status.pet_refresh_skill,
    FreeCount = case mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000007) >= data_pet_skill:get_refresh_skill_free_count() of
		    false -> 0;
		    true -> 1
		end,
    [LuckyVal, BlessVal, BoxList] = [RefreshInfo#status_pet_refresh_skill.lucky, RefreshInfo#status_pet_refresh_skill.bless, RefreshInfo#status_pet_refresh_skill.refresh_list],
    [LuckyVal, BlessVal, FreeCount, BoxList].

get_refresh_bind_or_not(BGold, Gold) ->
    Total = BGold + Gold,
    BindRate = BGold / Total,
    case BindRate >= 0.9 of
	true -> 1;
	false -> 0
    end.
	    
refresh_skill(Status, Type, UseBindGold) ->
    GoodsPid = Status#player_status.goods#status_goods.goods_pid,
    RefreshCount = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5000007), %刷新技能次数
    case Type of
	0 ->					%单次刷新
	    OldLucky = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.lucky,
	    BoxList = data_pet_refresh_skill:get_refresh_skill_goods(),
	    ProbableList = lists:filter(fun(X) ->
						{_,_,{Start, End},_,_} = X,
						OldLucky >= Start andalso OldLucky =< End
					end, BoxList),
	    case get_refresh_skill_box(ProbableList, RefreshCount) of
		null ->
		    [0, Status];
		Box ->
		    [Reason, Bind, Status1, NewLucky] =
			case RefreshCount >= data_pet_skill:get_refresh_skill_free_count() of
			    true ->
				case mod_other_call:get_goods_num(Status, 613501, 0) > 0 of
				    true ->
					%% 道具足够，优先扣道具
					case gen_server:call(GoodsPid, {'delete_more', 613501, 1}) of
					    1 ->
						log:log_goods_use(Status#player_status.id, 613501, 1),
						ConsumptionStatus = lib_player:add_consumption(petjn,Status,0,1),
%%						ConsumptionStatus = Status,
						[ok, 1, ConsumptionStatus, OldLucky + 8];
					    _ -> [{failed, 3}, 1, Status, OldLucky]
					end;
				    false ->
					case UseBindGold =:= 1 of
					    true ->
						%% 勾选了绑定元宝刷新
						case Status#player_status.bgold < 10 of
						    true ->
							%% 非绑元宝刷新
							case Status#player_status.gold < 10 of
							    true -> [{failed, 2}, 1, Status, OldLucky];
							    false ->
								StatusCost = lib_goods_util:cost_money(Status, 10, gold),
								NewGold = StatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill.gold + 10,
								lib_player:refresh_client(StatusCost#player_status.id, 2),
								log:log_consume(pet_refresh_skill, gold, Status, StatusCost, "pet refresh skill"),
								StatusCost1 = StatusCost#player_status{
									    pet_refresh_skill = StatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill{
															   gold = NewGold
															  }
									   },
								update_refresh_bgold_and_gold(StatusCost1#player_status.id, StatusCost1#player_status.pet_refresh_skill#status_pet_refresh_skill.bgold, NewGold),
								NewStatusCost = lib_player:add_consumption(petjn,StatusCost1,10,1),
%%								NewStatusCost = StatusCost,
								lib_activity:add_consumption(petjn,NewStatusCost,10),
								lib_qixi:update_player_task_batch(NewStatusCost#player_status.id, [16,17,18,19,20], 1),
								BindOrNot = get_refresh_bind_or_not(NewStatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill.bgold, NewStatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill.gold),
								[ok, BindOrNot, NewStatusCost, OldLucky + 10]
							end;
						    false ->
							%% 绑定元宝刷新
							StatusCost = lib_goods_util:cost_money(Status, 10, bgold),
							NewBGold = StatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill.bgold + 10,
							lib_player:refresh_client(StatusCost#player_status.id, 2),
							log:log_consume(pet_refresh_skill, bgold, Status, StatusCost, "pet refresh skill"),
							StatusCost1 = StatusCost#player_status{
									pet_refresh_skill = StatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill{
														       bgold = NewBGold
														      }
								       },
							update_refresh_bgold_and_gold(StatusCost1#player_status.id, NewBGold, StatusCost1#player_status.pet_refresh_skill#status_pet_refresh_skill.gold),
							lib_qixi:update_player_task_batch(StatusCost1#player_status.id, [16,17,18,19,20], 1),
							[ok, 1, StatusCost1, OldLucky + 10]
						end;
					    false ->
						%% 非绑元宝刷新
						case Status#player_status.gold < 10 of
						    true -> [{failed, 2}, 1, Status, OldLucky];
						    false ->
							StatusCost = lib_goods_util:cost_money(Status, 10, gold),
							NewGold = StatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill.gold + 10,
							lib_player:refresh_client(StatusCost#player_status.id, 2),
							log:log_consume(pet_refresh_skill, gold, Status, StatusCost, "pet refresh skill"),
							StatusCost1 = StatusCost#player_status{
									pet_refresh_skill = StatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill{
														       gold = NewGold
														      }
								       },
							update_refresh_bgold_and_gold(StatusCost1#player_status.id, StatusCost1#player_status.pet_refresh_skill#status_pet_refresh_skill.bgold, NewGold),
							NewStatusCost = lib_player:add_consumption(petjn,StatusCost1,10,1),
%%							NewStatusCost = StatusCost,
							lib_activity:add_consumption(petjn,NewStatusCost,10),
							lib_qixi:update_player_task_batch(NewStatusCost#player_status.id, [16,17,18,19,20], 1),
							BindOrNot = get_refresh_bind_or_not(NewStatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill.bgold, NewStatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill.gold),
							[ok, BindOrNot, NewStatusCost, OldLucky + 10]
						end
					end
				end;
			    false ->
				lib_qixi:update_player_task_batch(Status#player_status.id, [16,17,18,19,20], 1),
				[ok, 1, Status, OldLucky + 5]
			end,
		    case Reason of
			{failed, Error} ->
			    [Error, Status];
			ok ->
			    OldBless = Status1#player_status.pet_refresh_skill#status_pet_refresh_skill.bless,
			    NewBless = round((NewLucky - OldLucky) * 0.2) + OldBless,
			    {_, _, _, GoodsTypeId, _} = Box,
			    RefreshList = case Status1#player_status.pet_refresh_skill#status_pet_refresh_skill.refresh_list of
					      [] -> [{GoodsTypeId,Bind}];
					      RL ->
						  %% %% 选出绑定的那个技能
						  %% case lists:filter(fun(X) ->
						  %% 			    {_,Binding} = X,
						  %% 			    Binding =:= 1
						  %% 		    end, Status1#player_status.pet_refresh_skill#status_pet_refresh_skill.refresh_list) of
						  %%     [] ->
						  %% 	  %% 全部均为非绑定，替换第一个
						  [_ | T] = RL,
						  [{GoodsTypeId, Bind} | T]
						     %%  _ ->
						  %% 	  %% 替换绑定的那个
						  %% 	  lists:keyreplace(1, 2, Status1#player_status.pet_refresh_skill#status_pet_refresh_skill.refresh_list, {GoodsTypeId, Bind})
						  %% end
					  end,
			    update_pet_refresh_to_db(Status1#player_status.id, OldLucky, NewLucky, OldBless, NewBless, RefreshList),
			    Status2 = Status1#player_status{
					pet_refresh_skill = Status1#player_status.pet_refresh_skill#status_pet_refresh_skill{
										    lucky = NewLucky,
										    bless = NewBless,
										    refresh_list = RefreshList
										   }
				       },
			    mod_daily:increment(Status2#player_status.dailypid, Status2#player_status.id, 5000007),
			    [1, Status2]
		    end
	    end;
	1 ->
	    OldLucky = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.lucky,
	    BoxList = data_pet_refresh_skill:get_refresh_skill_goods(),
	    ProbableList = lists:filter(fun(X) ->
						{_,_,{Start, End},_,_} = X,
						OldLucky >= Start andalso OldLucky =< End
					end, BoxList),

	    %% 批量刷，刷12个
	    Seq = lists:seq(1,12),
	    case UseBindGold =:= 1 of
		true ->
		    case Status#player_status.bgold < 110 of
			true ->
			    %% 非绑元宝刷
			    case Status#player_status.gold < 110 of
				true -> [2, Status];
				false ->
				    NewLucky = OldLucky + 120,
				    OldBless = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.bless,
				    NewBless = round((NewLucky - OldLucky) * 0.2) + OldBless,
				    NewGold = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.gold + 110,
				    RefreshList = lists:map(fun(_) ->
								    {_, _, _, GoodsTypeId, _} = get_refresh_skill_box(ProbableList, RefreshCount + data_pet_skill:get_refresh_skill_free_count()),
								    BindOrNot = get_refresh_bind_or_not(Status#player_status.pet_refresh_skill#status_pet_refresh_skill.bgold, NewGold),
								    {GoodsTypeId, BindOrNot}
							    end, Seq),
				    StatusCost = lib_goods_util:cost_money(Status, 110, gold),
				    lib_player:refresh_client(StatusCost#player_status.id, 2),
				    log:log_consume(pet_refresh_skill, gold, Status, StatusCost, "pet refresh skill batch"),
				    update_pet_refresh_to_db(StatusCost#player_status.id, OldLucky, NewLucky, OldBless, NewBless, RefreshList),
				    Status2 = StatusCost#player_status{
						pet_refresh_skill = StatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill{
											       lucky = NewLucky,
											       bless = NewBless,
											       gold = NewGold,
											       refresh_list = RefreshList
											      }
					       },
				    update_refresh_bgold_and_gold(Status2#player_status.id, Status2#player_status.pet_refresh_skill#status_pet_refresh_skill.bgold, NewGold),
				    Status3 = lib_player:add_consumption(petjn,Status2,110,12),
%%				    Status3 = Status2,
				    lib_activity:add_consumption(petjn,Status2,110),
				    lib_qixi:update_player_task_batch(Status3#player_status.id, [16,17,18,19,20], 12),
				    [1, Status3]
			    end;
			false ->
			    NewLucky = OldLucky + 120,
			    OldBless = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.bless,
			    NewBless = round((NewLucky - OldLucky) * 0.2) + OldBless,
			    NewBGold = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.bgold + 110,
			    RefreshList = lists:map(fun(_) ->
							    {_, _, _, GoodsTypeId, _} = get_refresh_skill_box(ProbableList, RefreshCount + data_pet_skill:get_refresh_skill_free_count()),
							    {GoodsTypeId, 1}
						    end, Seq),
			    StatusCost = lib_goods_util:cost_money(Status, 110, bgold),
			    lib_player:refresh_client(StatusCost#player_status.id, 2),
			    log:log_consume(pet_refresh_skill, bgold, Status, StatusCost, "pet refresh skill batch"),
			    update_pet_refresh_to_db(StatusCost#player_status.id, OldLucky, NewLucky, OldBless, NewBless, RefreshList),
			    Status2 = StatusCost#player_status{
					pet_refresh_skill = StatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill{
										       lucky = NewLucky,
										       bless = NewBless,
										       bgold = NewBGold,
										       refresh_list = RefreshList
										      }
				       },
			    update_refresh_bgold_and_gold(Status2#player_status.id, NewBGold, Status2#player_status.pet_refresh_skill#status_pet_refresh_skill.gold),
			    lib_qixi:update_player_task_batch(Status2#player_status.id, [16,17,18,19,20], 12),
			    [1, Status2]
		    end;
		false ->
		    case Status#player_status.gold < 110 of
			true -> [2, Status];
			false ->
			    %% 非绑元宝刷
			    NewLucky = OldLucky + 120,
			    OldBless = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.bless,
			    NewBless = round((NewLucky - OldLucky) * 0.2) + OldBless,
			    NewGold = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.gold + 110,
			    RefreshList = lists:map(fun(_) ->
							    {_, _, _, GoodsTypeId, _} = get_refresh_skill_box(ProbableList, RefreshCount + data_pet_skill:get_refresh_skill_free_count()),
							    BindOrNot = get_refresh_bind_or_not(Status#player_status.pet_refresh_skill#status_pet_refresh_skill.bgold, NewGold),
							    {GoodsTypeId, BindOrNot}
						    end, Seq),
			    StatusCost = lib_goods_util:cost_money(Status, 110, gold),
			    lib_player:refresh_client(StatusCost#player_status.id, 2),
			    log:log_consume(pet_refresh_skill, gold, Status, StatusCost, "pet refresh skill batch"),
			    update_pet_refresh_to_db(StatusCost#player_status.id, OldLucky, NewLucky, OldBless, NewBless, RefreshList),
			    Status2 = StatusCost#player_status{
					pet_refresh_skill = StatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill{
										       lucky = NewLucky,
										       bless = NewBless,
										       gold = NewGold,
										       refresh_list = RefreshList
										      }
				       },
			    update_refresh_bgold_and_gold(Status2#player_status.id, Status2#player_status.pet_refresh_skill#status_pet_refresh_skill.bgold, NewGold),
			    Status3 = lib_player:add_consumption(petjn,Status2,110,12),
%%			    Status3 = Status2,
			    lib_activity:add_consumption(petjn,Status2,110),
			    lib_qixi:update_player_task_batch(Status3#player_status.id, [16,17,18,19,20], 12),
			    [1, Status3]
		    end
	    end;
	_ ->
	    [0, Status]
    end.
%% @param: List: [{GoodsTypeId,Bind},...]
%% @return: RealList: [{GoodsTypeId, Pos, Bind},...]
%% make_refresh_skill_list(List) ->
%%     {RealList, _} = lists:foldl(fun(X, Acc) ->
%% 					{GoodsTypeId, Bind} = X,
%% 					{List1, Pos} = Acc,
%% 					{[{GoodsTypeId, Pos, Bind} | List1], Pos + 1}
%% 				end, {[], 0}, List),
%%     RealList.

%% 获取技能刷新宝箱
get_refresh_skill_box(BoxList, RefreshCount) ->
    case RefreshCount >= data_pet_skill:get_refresh_skill_free_count() of
	true ->
	    case is_list(BoxList) of
		true ->
		    TotalRatio = lib_goods_util:get_ratio_total(BoxList, 5),
		    Rand = util:rand(1, TotalRatio),
		    lib_goods_util:find_ratio(BoxList, 0, Rand, 5);
		false ->
		    null
	    end;
	false ->
	    FreeBoxList = [{0,0,0,621711, 140},{0,0,0,622311, 140},{0,0,0,621911, 140},{0,0,0,622111, 140},{0,0,0,622411, 40},{0,0,0,622511, 40},{0,0,0,622611, 40},{0,0,0,623201, 1800},{0,0,0,623202, 900}],
	    TotalRatio = lib_goods_util:get_ratio_total(FreeBoxList, 5),
	    Rand = util:rand(1, TotalRatio),
	    lib_goods_util:find_ratio(FreeBoxList, 0, Rand, 5)
    end.


%% 抄写宠物技能
copy_skill(Status, GoodsTypeId, Bind, CopyType) ->
    RefreshList = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.refresh_list,
    GoodsPid = Status#player_status.goods#status_goods.goods_pid,
    OldLucky = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.lucky,
    OldBless = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.bless,
    case lists:member({GoodsTypeId, Bind}, RefreshList) of
	true ->
	    case CopyType of
		%% 道具抄写
		0 ->
		    case gen_server:call(GoodsPid, {'delete_more', 613501, 1}) of
			1 ->
			    log:log_goods_use(Status#player_status.id, 613501, 1),
			    case Bind =:= 1 of
				true ->
				    %% 清空宝箱列表和幸运值
				    clear_pet_refresh_for_copy(Status#player_status.id, OldLucky, OldBless, OldBless, GoodsTypeId),
				    Status1 = Status#player_status{
						pet_refresh_skill = Status#player_status.pet_refresh_skill#status_pet_refresh_skill{
											   lucky = 0,
											   bgold = 0,
											   gold = 0,
											   refresh_list = []
											  }
					       },
				    update_refresh_bgold_and_gold(Status1#player_status.id, 0, 0),
				    case gen_server:call(GoodsPid, {'give_more_bind', [], [{GoodsTypeId, 1}]}) of
					ok ->
					    send_skill_ref_tv(Status, GoodsTypeId),
					    mod_pet_refresh_skill:insert_buy_record({Status#player_status.id, Status#player_status.nickname, Status#player_status.realm}, GoodsTypeId),
					    [1, Status1];
					{fail, Code} ->
					    [Code, Status];
					_ ->
					    [0, Status]
				    end;
				false ->
				    clear_pet_refresh_for_copy(Status#player_status.id, OldLucky, OldBless, OldBless, GoodsTypeId),
				    %% 清空宝箱列表和幸运值
				    Status1 = Status#player_status{
						pet_refresh_skill = Status#player_status.pet_refresh_skill#status_pet_refresh_skill{
											   lucky = 0,
											   bgold = 0,
											   gold = 0,
											   refresh_list = []
											  }
					       },
				    update_refresh_bgold_and_gold(Status1#player_status.id, 0, 0),
				    case gen_server:call(GoodsPid, {'give_more', [], [{GoodsTypeId, 1}]}) of
					ok ->
					    send_skill_ref_tv(Status, GoodsTypeId),
					    mod_pet_refresh_skill:insert_buy_record({Status#player_status.id, Status#player_status.nickname, Status#player_status.realm}, GoodsTypeId),
					    [1, Status1];
					{fail, Code} ->
					    [Code, Status];
					_ ->
					    [0, Status]
				    end
			    end;
			_ ->
			    [5, Status]
		    end;
		%% 元宝抄写
		1 ->
		    case Status#player_status.gold < 10 of
			true ->
			    [4, Status];
			false ->
			    case Bind =:= 1 of
				true ->
				    StatusCost = lib_goods_util:cost_money(Status, 10, gold),
				    lib_player:refresh_client(StatusCost#player_status.id, 2),
				    log:log_consume(pet_copy_skill, gold, Status, StatusCost, "copy refresh skill"),
				    %% 清空宝箱列表和幸运值
				    clear_pet_refresh_for_copy(StatusCost#player_status.id, OldLucky, OldBless, OldBless, GoodsTypeId),
				    Status1 = StatusCost#player_status{
						pet_refresh_skill = StatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill{
											       lucky = 0,
											       bgold = 0,
											       gold = 0,
											       refresh_list = []
											      }
					       },
				    update_refresh_bgold_and_gold(Status1#player_status.id, 0, 0),
				    Status2 = lib_player:add_consumption(petjn,Status1,10,1),
%%				    Status2 = Status1,
				    lib_activity:add_consumption(petjn,Status1,10),
				    case gen_server:call(GoodsPid, {'give_more_bind', [], [{GoodsTypeId, 1}]}) of
					ok ->
					    send_skill_ref_tv(Status, GoodsTypeId),
					    mod_pet_refresh_skill:insert_buy_record({Status#player_status.id, Status#player_status.nickname, Status#player_status.realm}, GoodsTypeId),
					    [1, Status2];
					{fail, Code} ->
					    [Code, Status];
					_ ->
					    [0, Status]
				    end;
				false ->
				    StatusCost = lib_goods_util:cost_money(Status, 10, gold),
				    lib_player:refresh_client(StatusCost#player_status.id, 2),
				    log:log_consume(pet_copy_skill, gold, Status, StatusCost, "copy refresh skill"),
				    %% 清空宝箱列表和幸运值
				    clear_pet_refresh_for_copy(StatusCost#player_status.id, OldLucky, OldBless, OldBless, GoodsTypeId),
				    Status1 = StatusCost#player_status{
						pet_refresh_skill = StatusCost#player_status.pet_refresh_skill#status_pet_refresh_skill{
											       lucky = 0,
											       bgold = 0,
											       gold = 0,
											       refresh_list = []
											      }
					       },
				    update_refresh_bgold_and_gold(Status1#player_status.id, 0, 0),
				    Status2 = lib_player:add_consumption(petjn,Status1,10,1),
%%				    Status2 = Status1,
				    lib_activity:add_consumption(petjn,Status1,10),
				    case gen_server:call(GoodsPid, {'give_more', [], [{GoodsTypeId, 1}]}) of
					ok ->
					    send_skill_ref_tv(Status, GoodsTypeId),
					    mod_pet_refresh_skill:insert_buy_record({Status#player_status.id, Status#player_status.nickname, Status#player_status.realm}, GoodsTypeId),
					    [1, Status2];
					{fail, Code} ->
					    [Code, Status];
					_ ->
					    [0, Status]
				    end
			    end
		    end;
		_ ->
		    [0, Status]
	    end;
	false ->
	    [0, Status]
    end.
update_pet_refresh_to_db(PlayerId, OldLucky, NewLucky, OldBless, NewBless, RefreshList) ->
    Q1 = io_lib:format(<<"update pet_refresh_skill set lucky_val=~p, bless_val=~p, goods='~s' where player_id=~p">>,[NewLucky, NewBless, util:term_to_string(RefreshList), PlayerId]),
    db:execute(Q1),
    Q2 = io_lib:format(<<"insert into log_pet_refresh_skill(player_id,old_lucky,new_lucky,old_bless,new_bless,goods,timestamp) values(~p,~p,~p,~p,~p,'~s',~p)">>,[PlayerId, OldLucky, NewLucky, OldBless, NewBless, util:term_to_string(RefreshList),util:unixtime()]),
    db:execute(Q2).

clear_pet_refresh_for_copy(PlayerId, CopyLucky, OldBless, NewBless, GoodsTypeId) ->
    Q1 = io_lib:format(<<"update pet_refresh_skill set lucky_val=~p, goods='~s' where player_id=~p">>, [0, util:term_to_string([]), PlayerId]),
    db:execute(Q1),
    Q2 = io_lib:format(<<"insert into log_copy_refresh_goods(player_id,copy_lucky,old_bless,new_bless,goods,timestamp) values(~p,~p,~p,~p,~p,~p)">>, [PlayerId, CopyLucky, OldBless, NewBless, GoodsTypeId,util:unixtime()]),
    db:execute(Q2).

update_refresh_bgold_and_gold(PlayerId, BGold, Gold) ->
    Q1 = io_lib:format(<<"update pet_refresh_skill set bgold=~p, gold=~p where player_id=~p">>, [BGold, Gold, PlayerId]),
    db:execute(Q1).
    
get_refresh_skill_info(PlayerId) ->
    Q1 = io_lib:format(<<"select lucky_val, bless_val, goods, bgold, gold from pet_refresh_skill where player_id=~p">>,[PlayerId]),
    case db:get_row(Q1) of
	[] ->
	    SQL = io_lib:format(<<"insert into pet_refresh_skill(player_id, lucky_val, bless_val, bgold, gold, goods) values(~p,~p,~p,~p,~p,'~s')">>, [PlayerId, 0,0,0,0,util:term_to_string([])]),
	    db:execute(SQL),
	    [0,0,[],0,0];
	R ->
	    [Lucky, Bless, RefreshList, BGold, Gold] = R,
	    [Lucky, Bless, lib_goods_util:to_term(RefreshList), BGold, Gold]
    end.

withdraw_bless_goods(Status, GoodsTypeId) ->
    GoodsList = data_pet_refresh_skill:get_bless_goods(),
    GoodsPid = Status#player_status.goods#status_goods.goods_pid,
    OldBless = Status#player_status.pet_refresh_skill#status_pet_refresh_skill.bless,
    case lists:keyfind(GoodsTypeId, 1, GoodsList) of
	false ->
	    [2, Status];
	{Goods, BlessVal} ->
	    case OldBless >= BlessVal of
		true ->
		    NewBless = OldBless - BlessVal,
		    %% 扣取祝福值
		    Q = io_lib:format(<<"update pet_refresh_skill set bless_val=~p where player_id=~p">>,[NewBless, Status#player_status.id]),
		    db:execute(Q),
		    Q1 = io_lib:format(<<"insert into log_withdraw_bless_goods(player_id,old_bless,new_bless,goods,timestamp) values(~p,~p,~p,~p,~p)">>,[Status#player_status.id,OldBless,NewBless,Goods,util:unixtime()]), 
		    db:execute(Q1),
		    Status1 = Status#player_status{
				pet_refresh_skill = Status#player_status.pet_refresh_skill#status_pet_refresh_skill{
									   bless = NewBless
									  }
			       },
		    case gen_server:call(GoodsPid, {'give_more_bind', [], [{Goods, 1}]}) of
			ok ->
			    lib_chat:send_TV({all}, 0, 2, ["petSkillZhufu", Status#player_status.id, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image, Goods]),
			    [1, Status1];
			{fail, Code} ->
			    [Code, Status];
			_ ->
			    [0, Status]
		    end;
		false -> [4, Status]
	    end
    end.

send_skill_ref_tv(Status, GoodsTypeId) ->
    case data_pet_skill:get_skill_level_by_goods_type_id(GoodsTypeId) of
	error ->
	    PreciousGoods = data_pet_skill:get_precious_goods(),
	    case lists:member(GoodsTypeId, PreciousGoods) of
		true ->
		    %% 发传闻
		    lib_chat:send_TV({all}, 0, 2, ["petSkillRef", Status#player_status.id, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image, GoodsTypeId]);
		false -> []
	    end;
	GoodsTypeIdLv when GoodsTypeIdLv >= 2->
	    lib_chat:send_TV({all}, 0, 2, ["petSkillRef", Status#player_status.id, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image, GoodsTypeId]);
	_ -> []
    end.


check_span_time(PlayerID) ->
    Now = util:longunixtime(),
    Span = io_lib:format("~ppet_refresh_skill", [PlayerID]),
    case get(Span) of
	undefined ->
	    put(Span, Now),
	    ok;
	SpanTime ->
	    if
		%% 2次玩的间隔
		Now - SpanTime >= 200 -> 
		    put(Span, Now),
		    ok;
		true ->
		    error
	    end
    end.


%% 批量成长判断是否升阶
%% @param: [H|T] 旧的十次成长经验值，宠物成长所需物品，宠物当前成长经验值，当前成长值，新的N次成长经验值
is_upgrade_batch_grow([], _OldExp, _TemGrowth, _IsStop, NewList) -> NewList;
is_upgrade_batch_grow([H | T], OldExp, TmpGrowth, IsStop, NewList) -> 
    case IsStop of 
        true -> NewList;
        false ->
            {_, Value} = H,
            OldExpMax = data_pet:get_grow_exp(TmpGrowth),
            case OldExp + Value >= OldExpMax of 
            %% 成长值升级
                true ->
                
                    NewTmpGrowth = TmpGrowth + 1,
                    NewExp = OldExp + Value - OldExpMax,
                    IsUpgrade = data_pet:is_growth_upgrade_phase(TmpGrowth, NewTmpGrowth),
                    case IsUpgrade =:= 0 of 
                        true -> 
                            is_upgrade_batch_grow(T, NewExp, NewTmpGrowth, false, [H | NewList]);
                        false -> 
                            is_upgrade_batch_grow(T, NewExp, NewTmpGrowth, true, [H | NewList])
                    end;
                false -> 
                    is_upgrade_batch_grow(T, OldExp+Value, TmpGrowth, false, [H | NewList])
            end
    end.

