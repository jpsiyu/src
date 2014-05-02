%%%------------------------------------
%%% @Module  : mod_pet
%%% @Author  : zhenghehe
%%% @Created : 2010.07.03
%%% @Description: 宠物处理
%%%------------------------------------
-module(mod_pet).
-behaviour(gen_server).
-include("common.hrl").
-include("goods.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("pet.hrl").
-include("sql_pet.hrl").
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%%=========================================================================
%% 一些定义
%%=========================================================================
-record(state, {interval = 0}).

%%=========================================================================
%% 接口函数
%%=========================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:cast(?MODULE, stop).

send_pet_mail(SubjectType, Param) ->
    gen_server:cast(?MODULE, {'send_mail', SubjectType, Param}).

send_log_pet(Type, PlayerId, PetId, Param) ->
    gen_server:cast(?MODULE, {'log_pet', Type, PlayerId, PetId, Param}).

send_delete_log() ->
    gen_server:cast(?MODULE, {'delete_log'}).

%%=========================================================================
%% 回调函数
%%=========================================================================
init([]) ->
    process_flag(trap_exit, true),
    Timeout = 60000,
    State = #state{interval = Timeout},
    {ok, State}.

handle_call(Request, From, State) ->
    mod_pet_call:handle_call(Request, From, State).

handle_cast(stop, State) ->
    {stop, normal, State};

handle_cast(Msg, State) ->
    mod_pet_cast:handle_cast(Msg, State).

handle_info(Info, State) ->
    mod_pet_info:handle_info(Info, State).

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%=========================================================================
%% 业务处理函数
%%=========================================================================

%% -----------------------------------------------------------------
%% 获取宠物信息
%% -----------------------------------------------------------------
get_pet_info(Status, [PetId]) ->
    lib_pet:get_pet_info(PetId, Status).

%% -----------------------------------------------------------------
%% 获取宠物列表
%% -----------------------------------------------------------------
get_pet_list(Status, [_PlayerId]) ->
    lib_pet:get_pet_list(Status).

%% -----------------------------------------------------------------
%% 宠物孵化
%% -----------------------------------------------------------------
incubate_pet(Status, [GoodsInfo, GoodsUseNum]) ->
    Pet = Status#player_status.pet,
    PetCount      = lib_pet:get_pet_count(Status#player_status.id),
    PetMaxNum     = lib_pet:get_pet_maxnum(Pet#status_pet.pet_capacity),
    Go = Status#player_status.goods,
    if  %% 该物品不存在
        GoodsInfo =:= []  -> [2, 0, <<>>, 0];
	%% 宠物数已满
        PetCount >= PetMaxNum -> [7, 0, <<>>, 0];
        true ->
            [EggGoodsType, EggGoodsSubType] = data_pet:get_pet_config(goods_pet_card,[]),
            [GoodsId, GoodsPlayerId, GoodsTypeId, GoodsType, GoodsSubtype, GoodsNum, _GoodsCell, GoodsLevel]  =
                [GoodsInfo#goods.id, GoodsInfo#goods.player_id, GoodsInfo#goods.goods_id, GoodsInfo#goods.type, GoodsInfo#goods.subtype, GoodsInfo#goods.num, GoodsInfo#goods.cell, GoodsInfo#goods.level],
            if   %% 物品不归你所有
		GoodsPlayerId =/= Status#player_status.id -> [3, 0, <<>>, 0];
		%% 该物品不是宠物蛋
		((GoodsType =/= EggGoodsType) and (GoodsSubtype =/= EggGoodsSubType)) -> [4, 0, <<>>, 0];
		%% 物品数量不够
		GoodsNum < GoodsUseNum -> [5, 0, <<>>, 0];
		true ->
		    GoodsTypeInfo = data_goods_type:get(GoodsTypeId),
		    if %% 该物品类型信息不存在
                        GoodsTypeInfo =:= [] ->
                            util:errlog("incubate_pet: Goods type not in cache, type_id=[~p]", [GoodsTypeId]),
                            [0, 0, <<>>, 0];
                        true ->
                            if  %% 你级别不够
                                Status#player_status.lv < GoodsLevel -> [6, 0, <<>>, 0];
                                true ->
                                    BaseGoodsPet = lib_pet:get_base_goods_pet(GoodsTypeId),
                                    if   BaseGoodsPet =:= [] ->
					    util:errlog("incubate_pet: Cannot find base goods pet in cache, id=[~p]", [GoodsTypeId]),
					    [0, 0, <<>>, 0];
                                         true ->
					    case gen_server:call(Go#status_goods.goods_pid, {'delete_one', GoodsId, GoodsUseNum}) of
						1 ->
						    case lib_pet:incubate_pet(Status#player_status.id, Status#player_status.career, GoodsTypeInfo, BaseGoodsPet) of
                                                        [ok, PetId, PetName, PetFigure, PetAptitude, PetGrowth, PetMaxinumGrowth] ->
							    case Status#player_status.lv >= 40 of
								false -> [];
								_ ->
								    pp_pet:handle(41037, Status, [PetId, PetAptitude, PetName, PetFigure, PetGrowth, data_pet:get_quality(PetAptitude)])
							    end,
                                %%  目标：获得一个资质大于680的宠物 301
                                mod_target:trigger(Status#player_status.status_target, Status#player_status.id, 301, PetAptitude),
							    if
								PetAptitude >= 801 ->
								    lib_chat:send_TV({all}, 0, 2, ["petZizhi", PetAptitude, Status#player_status.id, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image, GoodsTypeId, data_pet:get_quality(PetAptitude)]);
								true -> skip
							    end,
                                                            send_log_pet(incubate_pet, Status#player_status.id, PetId, [GoodsTypeId, PetFigure, PetAptitude, PetGrowth, PetMaxinumGrowth]),
							    [1, PetId, PetName, GoodsTypeInfo#ets_goods_type.goods_id];
                                                        _   ->
                                                            [0, 0, <<>>, 0]
                                                    end;
						GoodsModuleCode ->
                                                    util:errlog("incubate_pet: Call goods module faild, result code=[~p]", [GoodsModuleCode]),
                                                    [0, 0, <<>>, 0]
					    end
                                    end
                            end
		    end
            end
    end.

%% -----------------------------------------------------------------
%% 宠物放生
%% -----------------------------------------------------------------
free_pet(Status, [PetId]) ->
    Pet = lib_pet:get_pet(PetId),
    if  %% 宠物不存在
        Pet =:= []  -> 2;
        true ->
            [PlayerId, FightFlag] = [Pet#player_pet.player_id, Pet#player_pet.fight_flag],
            if  %% 该宠物不归你所有
                PlayerId /= Status#player_status.id -> 3;
		%% 宠物正在出战
                FightFlag == 1 -> 5;
                true ->
                    case lib_pet:free_pet(PetId) of
                        ok  ->
			    %% 记录日志
                            send_log_pet(free_pet, Status#player_status.id, PetId, [Pet#player_pet.name, Pet#player_pet.level, Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude, Pet#player_pet.growth, Pet#player_pet.skills, Pet#player_pet.potentials, Pet#player_pet.type_id]),
                            1;
                        _   ->
                            0
                    end
            end
    end.

%% -----------------------------------------------------------------
%% 宠物改名
%% -----------------------------------------------------------------
rename_pet(Status, [PetId, PetName]) ->
    Pet = lib_pet:get_pet(PetId),
    NameLenValid        = util:check_length(PetName, 16),
    NameContentInValid  = util:check_keyword(PetName),
    StatusPet = Status#player_status.pet,
    if  %% 宠物不存在
        Pet =:= []  -> [2, 0, 0, 0, 0, 0, 0];
	%% 宠物名长度非法
        NameLenValid == false -> [5, 0, 0, 0, 0, 0, 0];
	%% 宠物名内容非法
        NameContentInValid == true -> [6, 0, 0, 0, 0, 0, 0];
        true ->
            [PlayerId, Name, PetFigure, PetNimbus, PetLevel, PetAptitude] = [Pet#player_pet.player_id, Pet#player_pet.name, Pet#player_pet.figure, Pet#player_pet.nimbus, Pet#player_pet.level, Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude],
            NewName = util:make_sure_binary(PetName),
            if  %% 该宠物不归你所有
                PlayerId /= Status#player_status.id -> [3, 0, 0, 0, 0, 0, 0];
		%% 新旧名称相同
                Name =:= NewName -> [4, 0, 0, 0, 0, 0, 0];
                true ->
                    NowTime      = util:unixtime(),
                    MaxRenameNum = data_pet:get_pet_config(maxinum_rename_num, []),
                    IsSameDate   = util:is_same_date(NowTime, StatusPet#status_pet.pet_rename_lasttime),
                    if  %% 改名次数达到上限
                        IsSameDate andalso StatusPet#status_pet.pet_rename_num >= MaxRenameNum ->
                            [7, 0, 0, 0, 0, 0, 0];
                        true ->
                            NewRenameNum = case IsSameDate of
                                               false -> 1;
                                               true-> StatusPet#status_pet.pet_rename_num+1
                                           end,
                            case lib_pet:rename_pet(PetId, PetName, Status#player_status.id, NewRenameNum, NowTime) of
                                ok  ->
				    %% 更新缓存
                                    PetNew = Pet#player_pet{name       = NewName,
							    name_upper = string:to_upper(util:make_sure_list(NewName))},
                                    lib_pet:update_pet(PetNew),
                                    [1, PetFigure, PetNimbus, PetLevel, PetAptitude, NewRenameNum, NowTime];
                                _   ->
                                    [0, 0, 0, 0, 0, 0, 0]
                            end
                    end
            end
    end.

%% -----------------------------------------------------------------
%% 宠物出战
%% @return:[结果，宠物战斗属性，潜能加成属性，形象，光环，等级，名字，资质，潜能阶段加成属性，技能加成属性]
%% -----------------------------------------------------------------
fighting_pet(Status, [PetId]) ->
    Pet = lib_pet:get_pet(PetId),
    if  %% 宠物不存在
        Pet =:= []  -> [2, [], [], 0, 0, 0, <<>>, 0, 0];
        true ->
            [PlayerId, FightFlag, PetAttr, PetPotentialAttr, PetFigure, PetNimbus, PetLevel, PetName, PetStrength, BasePetAptitude, ExtraPetAptitude] = [Pet#player_pet.player_id, Pet#player_pet.fight_flag, Pet#player_pet.pet_attr, Pet#player_pet.pet_potential_attr, Pet#player_pet.figure, Pet#player_pet.nimbus, Pet#player_pet.level, Pet#player_pet.name, Pet#player_pet.strength, Pet#player_pet.base_aptitude, Pet#player_pet.extra_aptitude],
            if  
                %% 玩家等级不足34级
                Status#player_status.lv < 34 -> [7, [], [], 0, 0, 0, <<>>, 0, 0];
                %% 该宠物不归你所有
                PlayerId /= Status#player_status.id -> [3, [], [], 0, 0, 0, <<>>, 0, 0];
		%% 宠物已经出战
                FightFlag == 1 -> [4, [], [], 0, 0, 0, <<>>, 0, 0];
		%% 宠物快乐值为0
                PetStrength == 0 -> [6, [], [], 0, 0, 0, <<>>, 0, 0];
                true ->
                    FightingPet  = lib_pet:get_fighting_pet(PlayerId),
                    if  %% 已经有其他宠物出战
                        FightingPet =/= [] -> [5, [], [], 0, 0, 0, <<>>, 0, 0];
                        true ->
                            case lib_pet:fighting_pet(PetId) of
                                ok  ->
				    %% 更新缓存
                                    NowTime = util:unixtime(),
                                    PetNew = Pet#player_pet{fight_flag        = 1,
							    fight_starttime   = NowTime,
							    strength_nexttime = util:floor(NowTime/60)
							   },
                                    lib_pet:update_pet(PetNew),
                                    [1, PetAttr, PetPotentialAttr, PetFigure, PetNimbus, PetLevel, PetName, BasePetAptitude, ExtraPetAptitude];
                                _  ->
                                    [0, [], [], 0, 0, 0, <<>>, 0, 0]
                            end
                    end
            end
    end.

%% -----------------------------------------------------------------
%% 宠物休息
%% -----------------------------------------------------------------
rest_pet(Status, [PetId]) ->
    Pet = lib_pet:get_pet(PetId),
    if  %% 宠物不存在
        Pet =:= []  -> [2, [], []];
        true ->
            [PlayerId, FightFlag, FightStartTime, UpgradeExp, Level] = [Pet#player_pet.player_id, Pet#player_pet.fight_flag, Pet#player_pet.fight_starttime, Pet#player_pet.upgrade_exp, Pet#player_pet.level],
            if  %% 该宠物不归你所有
                PlayerId =/= Status#player_status.id -> [3, [], []];
		%% 宠物已经休息
                FightFlag =:= 0 -> [4, [], []];
                true ->
		    %% 计算升级经验
		    NewUpgradeExp = lib_pet:calc_upgrade_exp(FightFlag, FightStartTime, UpgradeExp, Level, PlayerId),
		    case lib_pet:rest_pet(PetId, NewUpgradeExp) of
			ok  ->
			    %% 更新缓存
			    PetNew = Pet#player_pet{fight_flag        = 0,
						    fight_starttime   = 0,
						    upgrade_exp       = NewUpgradeExp,
						    strength_nexttime = 0},
			    lib_pet:update_pet(PetNew),
			    [1, lib_pet:get_zero_pet_attribute(), lib_pet:get_zero_pet_potential_attribute()];
			_   ->
			    [0, [], []]
		    end
            end
    end.

%% -----------------------------------------------------------------
%% 宠物升级
%% -----------------------------------------------------------------
upgrade_pet(Status, [PetId]) ->
    Pet = lib_pet:get_pet(PetId),
    if  %% 宠物不存在
        Pet =:= []  -> 
            [2, Status, 0, 0];
        true ->
            [PlayerId, Level, UpgradeExp, PetFigure, PetNimbus, PetName, Growth, PetAptitude, ForzaScale, 
	     WitScale,AgileScale, ThewScale, PetSkillAttr, _PetPotentialAttr] = 
		[
		 Pet#player_pet.player_id,Pet#player_pet.level,Pet#player_pet.upgrade_exp,Pet#player_pet.figure,Pet#player_pet.nimbus,
		 Pet#player_pet.name, Pet#player_pet.growth,Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude,Pet#player_pet.forza_scale,Pet#player_pet.wit_scale, 
		 Pet#player_pet.agile_scale,Pet#player_pet.thew_scale,Pet#player_pet.pet_skill_attr,Pet#player_pet.pet_potential_attr],
            MaxLevel                       = data_pet:get_pet_config(maxinum_level, []),
            NextLevelExp  = data_pet:get_upgrade_info(Level),
            if  %% 该宠物不归你所有
                PlayerId /= Status#player_status.id -> 
                    [3, Status, Level, UpgradeExp];
		%% 宠物等级已经和玩家等级相等
                Level == Status#player_status.lv -> 
                    [4, Status, Level, UpgradeExp];
		%% 宠物已升到最高级
                Level >= MaxLevel -> 
                    [5, Status, Level, UpgradeExp];
		%% 宠物升级经验不够
                UpgradeExp < NextLevelExp -> 
                    [6, Status, Level, UpgradeExp];
                true ->
		    {NewLevel, _ExpLeft} = lib_pet:calc_exp_to_player_lv(Level, Status#player_status.lv, UpgradeExp),
                    %% 升级后经验变为0
                    ExpLeft = 0,
                    %% NewLevel       = Level+1,
                    NewNextLevelExp  = data_pet:get_upgrade_info(NewLevel),
                    [NewPetForza, NewPetWit, NewPetAgile, NewPetThew] = lib_pet:calc_attr(Growth, NewLevel, [ForzaScale,WitScale,AgileScale, ThewScale]),
                    NewPetAttr = lib_pet:calc_pet_attribute(NewPetForza, NewPetWit, NewPetAgile, NewPetThew, PetAptitude),
                    [NewHpLim,NewMpLim,NewAtt,NewDef,NewHit,NewDodge,NewCrit,NewTen,NewFire,NewIce,NewDrug,NewHit1,NewHit2] = lib_pet:calc_pet_attr_total(Status, NewPetAttr, PetSkillAttr, lib_pet:calc_potential_attr(Pet),Pet#player_pet.figure, Pet#player_pet.base_aptitude_attr),
                    NewComatPower = lib_pet:calc_pet_comat_power(NewHpLim,NewAtt,NewDef,NewHit,NewDodge,NewCrit,NewTen,NewFire,NewIce,NewDrug,NewHit1,NewHit2),
                    NewBaseAddition = lib_pet:calc_base_addition([NewPetForza, NewPetWit, NewPetAgile, NewPetThew], [ForzaScale,WitScale,AgileScale, ThewScale], NewLevel),
                    [NewForzaAddition,NewWitAddition,NewAgileAddition,NewThewAddition] = NewBaseAddition,
                    %% ExpLeft   = UpgradeExp-NextLevelExp,
                    case lib_pet:upgrade_pet(PetId, NewLevel, ExpLeft,NewPetForza,NewPetWit,NewPetAgile,NewPetThew,NewComatPower) of
                        ok  ->
			    %% 更新缓存
                            PetNew = Pet#player_pet{level = NewLevel,
						    upgrade_exp = ExpLeft,
						    forza = NewPetForza,
						    wit = NewPetWit,
						    agile = NewPetAgile,
						    thew = NewPetThew,
						    pet_attr = NewPetAttr,
						    combat_power = NewComatPower,
						    base_addition = NewBaseAddition
						   },
                            lib_pet:update_pet(PetNew),
			    lib_pet:update_combat_on_db(PetNew#player_pet.combat_power, PetNew#player_pet.id),
                            {ok, BinData} = pt_410:write(41008, [PetId, NewLevel, ExpLeft, NewNextLevelExp, NewPetForza,NewPetWit,NewPetAgile,NewPetThew,NewHpLim,NewMpLim,NewAtt,NewDef,NewHit,NewDodge,NewCrit,NewTen,NewForzaAddition,NewWitAddition,NewAgileAddition,NewThewAddition, NewComatPower]),
                            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
                            PetStatus = Status#player_status.pet,
                            NewPetStatus = PetStatus#status_pet{ pet_level = NewLevel, pet_attribute = NewPetAttr },
                            Status1 = Status#player_status{ pet = NewPetStatus },
			    Q1 = io_lib:format(<<"select type_id, exp from pet_potential_exp where player_id=~p and pet_id=~p">>,[PlayerId, PetId]),
			    case db:get_all(Q1) of
				[] -> [];
				AllType ->
				    lists:foreach(fun([Type, TypeExp]) ->
							  PetTmp = lib_pet:get_pet(PetId),
							  lib_pet:add_potential_exp(Status1, PetTmp, Type, TypeExp, upgrade)
						  end, AllType)
			    end,
			    PetNew1 = lib_pet:get_pet(PetId),
			    NewStatus = lib_pet:calc_player_attribute_by_pet_potential_attr(Status1, lib_pet:calc_potential_attr(PetNew1)),
			    %% 发送形象改变通知到场景
                            lib_pet:send_figure_change_notify(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, NewStatus#player_status.id,  NewStatus#player_status.platform, NewStatus#player_status.server_num, PetFigure, PetNimbus, NewLevel, PetName, PetAptitude),
			    %% 记录日志
                            send_log_pet(upgrade_pet, Status#player_status.id, PetId, [Level, NewLevel]),
			    pp_pet:handle(41001, NewStatus, [PetId]),
                            [1, NewStatus, NewLevel, ExpLeft];
                        _   -> 
                            [0, Status, Level, UpgradeExp]
                    end
            end
    end.

%% -----------------------------------------------------------------
%% 升级经验同步
%% -----------------------------------------------------------------
upgrade_exp_sync(Status, []) ->
    Pet = lib_pet:get_fighting_pet(Status#player_status.id),
    case Pet =:= [] of
        true ->
            [1, Status, 0, 0, 0];
        false ->
            [PetId, FightFlag, FightStartTime, UpgradeExp, _Level, PlayerId] = [Pet#player_pet.id, Pet#player_pet.fight_flag, Pet#player_pet.fight_starttime, Pet#player_pet.upgrade_exp, Pet#player_pet.level, Pet#player_pet.player_id],
            NowTime       = util:unixtime(),
            NewUpgradeExp = lib_pet:calc_upgrade_exp(FightFlag, FightStartTime, UpgradeExp, Status#player_status.lv, PlayerId),
            case lib_pet:upgrade_exp_sync(PetId, NewUpgradeExp) of
		ok  ->
		    %% 更新缓存
		    PetNew = Pet#player_pet{upgrade_exp     = NewUpgradeExp,
					    fight_starttime = NowTime},
		    lib_pet:update_pet(PetNew),
		    [_Result, NewStatus, NewPetLevel, NewPetExp] = upgrade_pet(Status, [PetId]),
			%% 目标：将宠物升到20级 201
			mod_target:trigger(NewStatus#player_status.status_target, NewStatus#player_status.id, 201, NewPetLevel),
            %% 目标：将宠物提升到40级  401 
            mod_target:trigger(NewStatus#player_status.status_target, NewStatus#player_status.id, 401, NewPetLevel),
		    [1, NewStatus, PetId, NewPetLevel, NewPetExp];
		_ -> [0, Status, 0, 0, 0]
            end
    end.

%% -----------------------------------------------------------------
%% 使用经验丹升级经验
%% -----------------------------------------------------------------
upgrade_exp_by_med(Status, [GoodsTypeId, GoodsId, GoodsUseNum]) ->
    Pet = lib_pet:get_fighting_pet(Status#player_status.id),
    case Pet =:= [] of
        true ->
            [2, Status, 0, 0, 0];
	false ->
	    MaxLevel = data_pet:get_pet_config(maxinum_level, []),
	    PetId = Pet#player_pet.id, 
	    Level = Pet#player_pet.level,
	    if
		%% 宠物等级已经和玩家等级相等
		Level =:= Status#player_status.lv -> 
		    [3, Status, PetId, 0, 0];
		%% 宠物已升到最高级
		Level >= MaxLevel -> 
		    [4, Status, PetId, 0, 0];
		true ->
		    Go = Status#player_status.goods,
		    case gen_server:call(Go#status_goods.goods_pid, {'delete_list', [{GoodsId, GoodsUseNum}]}) of
			1 ->
			    %% log:log_goods_use(PlayerId, MedicineId, GoodsUseNum),
			    %% log:log_throw(pet_grow, PlayerId, GoodsId, MedicineId, GoodsUseNum, 0, 0),
			    OldUpgradeExp = Pet#player_pet.upgrade_exp,
			    NewUpgradeExp = data_pet:get_upgrade_exp_by_medicine(GoodsTypeId, GoodsUseNum),
			    lib_pet:upgrade_exp_sync(PetId, OldUpgradeExp + NewUpgradeExp),
			    %% 更新缓存
			    PetNew = Pet#player_pet{upgrade_exp = OldUpgradeExp + NewUpgradeExp},
			    lib_pet:update_pet(PetNew),
			    [_Result, NewStatus, NewPetLevel, _NewPetExp] = upgrade_pet(Status, [PetId]),
                %% 目标：将宠物升到20级  201 
                mod_target:trigger(NewStatus#player_status.status_target, NewStatus#player_status.id, 201, NewPetLevel),
                %% 目标：将宠物提升到40级  401 
                mod_target:trigger(NewStatus#player_status.status_target, NewStatus#player_status.id, 401, NewPetLevel),
			    [1, NewStatus, PetId, NewPetLevel, NewUpgradeExp];
			_GoodsModuleCode ->   
			    [0, Status, PetId, 0, 0]
		    end
	    end
    end.

%% -----------------------------------------------------------------
%% 宠物喂养
%% -----------------------------------------------------------------
feed_pet(Status, [PetId, GoodsId, GoodsUseNum]) ->
    Go = Status#player_status.goods,
    if  %% 你已经死亡
	Status#player_status.hp =< 0 -> [2, 0];
        true ->
            Pet = lib_pet:get_pet(PetId),
            if  %% 宠物不存在
                Pet =:= []  -> [3, 0];
                true ->
                    [PlayerId, PetStrength, PetStrengThreshold] =
			[Pet#player_pet.player_id, Pet#player_pet.strength, Pet#player_pet.strength_threshold],
                    if  %% 宠物不归你所有
                        PlayerId =/= Status#player_status.id -> [4, 0];
			%% 宠物快乐值已满
                        PetStrength >= PetStrengThreshold -> [5, 0];
                        true ->
                            Dict = lib_goods_dict:get_player_dict(Status),
                            Goods = lib_goods_util:get_goods(GoodsId, Dict),
                            if  %% 物品不存在
                                Goods =:= []  -> [6, 0];
                                true ->
                                    [FoodGoodsType, FoodGoodsSubType] = data_pet:get_pet_config(goods_pet_food,[]),
                                    [GoodsPlayerId, GoodsTypeId, GoodsType, GoodsSubtype, GoodsNum]  =
                                        [Goods#goods.player_id, Goods#goods.goods_id, Goods#goods.type, Goods#goods.subtype, Goods#goods.num],
                                    if  %% 物品不归你所有
                                        GoodsPlayerId =/= Status#player_status.id -> [7, 0];
					%% 该物品不是食物
                                        ((GoodsType /= FoodGoodsType) and (GoodsSubtype /= FoodGoodsSubType)) -> [8, 0];
                                        true ->
                                            BaseGoodsPet = lib_pet:get_base_goods_pet(GoodsTypeId),
                                            case BaseGoodsPet =:= [] of
                                                true  ->
                                                    util:errlog("feed_pet: Cannot find base goods pet in cache, id=[~p]", [GoodsTypeId]),
                                                    [0, 0];
                                                false ->                                                    
                                                    if  %% 单个物品数量不够
                                                        GoodsNum < GoodsUseNum ->
							    %% 试图扣取多个格子物品
                                                            case gen_server:call(Go#status_goods.goods_pid, {'delete_list', [{GoodsId, GoodsUseNum}]}) of
								%% 扣取物品成功
                                                                1 ->
								    log:log_goods_use(PlayerId, GoodsTypeId, GoodsUseNum),
								    %% log:log_throw(pet_feed, PlayerId, GoodsId, GoodsTypeId, GoodsUseNum, 0, 0),
                                                                    FoodEffect = BaseGoodsPet#base_goods_pet.effect,
                                                                    PetStrengthTotal = PetStrength+GoodsUseNum*FoodEffect,
                                                                    NewPetStrength   = case PetStrengthTotal >= PetStrengThreshold of
                                                                                           true  -> PetStrengThreshold;
                                                                                           false -> PetStrengthTotal
                                                                                       end,
                                                                    case lib_pet:change_strength(PetId, NewPetStrength) of
                                                                        ok ->
									    %% 更新宠物缓存                                 
                                                                            PetNew = Pet#player_pet{strength = NewPetStrength},
                                                                            lib_pet:update_pet(PetNew),
                                                                            [1, NewPetStrength];
									%% 出错
                                                                        _   -> [0, 0]
                                                                    end;
								%% 扣取物品失败
                                                                0 ->
                                                                    [0, 0];
								%% 物品数量不够
                                                                _ ->
                                                                    [9, 0]
                                                            end;
							%% 单个物品数量足够
                                                        true ->
							    %% 扣取物品
                                                            case gen_server:call(Go#status_goods.goods_pid, {'delete_one', GoodsId, GoodsUseNum}) of
								%% 扣取物品成功
                                                                1 ->
								    log:log_goods_use(PlayerId, GoodsTypeId, GoodsUseNum),
								    %% log:log_throw(pet_feed, PlayerId, GoodsId, GoodsTypeId, GoodsUseNum, 0, 0),
                                                                    FoodEffect = BaseGoodsPet#base_goods_pet.effect,
                                                                    PetStrengthTotal = PetStrength+GoodsUseNum*FoodEffect,
                                                                    NewPetStrength   = case PetStrengthTotal >= PetStrengThreshold of
                                                                                           true  -> PetStrengThreshold;
                                                                                           false -> PetStrengthTotal
                                                                                       end,
                                                                    case lib_pet:change_strength(PetId, NewPetStrength) of
                                                                        ok ->
									    %% 更新缓存
                                                                            PetNew = Pet#player_pet{strength = NewPetStrength},
                                                                            lib_pet:update_pet(PetNew),
                                                                            [1, NewPetStrength];
									%% 出错
                                                                        _   -> [0, 0]
                                                                    end;
								%% 扣取物品失败
                                                                GoodsModuleCode ->
                                                                    util:errlog("feed_pet: Call goods module faild, result code=[~p]", [GoodsModuleCode]),
                                                                    [0, 0]
                                                            end
                                                    end
                                            end                                            
                                    end
                            end
		    end
            end
    end.

%% -----------------------------------------------------------------
%% 体力值同步
%% 修改历史： 2011/01/12 为防止外挂拦截体力值同步消息导致体力值扣取不到，
%%                       每次体力值同步时间记录在strength_nexttime字段，
%%                       角色下线时服务器再进行必要的补扣。
%% -----------------------------------------------------------------
strength_sync(Status, []) ->
    Pet = lib_pet:get_fighting_pet(Status#player_status.id),
    case Pet =:= [] of
        true ->
            [1, 0, 0, 0];
        false ->
            NowTime = util:floor(util:unixtime()/60),
            [PetId, Quality, Strength, StrengthNextTime, PlayerId, FightFlag, FightStartTime, UpgradeExp, Level] =
		[Pet#player_pet.id, Pet#player_pet.quality, Pet#player_pet.strength, Pet#player_pet.strength_nexttime, Pet#player_pet.player_id, Pet#player_pet.fight_flag, Pet#player_pet.fight_starttime, Pet#player_pet.upgrade_exp, Pet#player_pet.level],
            if  %% 同步时间到达
                NowTime > StrengthNextTime ->
		    %% 计算新的体力值
                    SyncStrength      = data_pet:get_strength_sync_value(Quality),
                    NewStrength = case Strength > SyncStrength of
                                      true  -> Strength-SyncStrength;
                                      false -> 0
                                  end,
		    %% 更新数据库
                    case lib_pet:change_strength(PetId, NewStrength) of
                        ok ->
			    %% 更新缓存
                            case NewStrength =< 0 of
                                true ->
                                    NewUpgradeExp = lib_pet:calc_upgrade_exp(FightFlag, FightStartTime, UpgradeExp, Level, PlayerId),
                                    PetNew = Pet#player_pet{strength = NewStrength,
							    strength_nexttime = 0,
							    fight_flag = 0,
							    fight_starttime = 0,
							    upgrade_exp = NewUpgradeExp},
                                    lib_pet:update_pet(PetNew);
                                false->
                                    PetNew = Pet#player_pet{strength = NewStrength,
							    strength_nexttime = NowTime},
                                    lib_pet:update_pet(PetNew)
                            end,
                            [1, PetId, NewStrength, 1];
                        _ ->
                            [0, 0, 0, 0]
                    end;
		%% 同步时间未到
                true ->
                    [1, 0, 0, 0]
            end
    end.

%% -----------------------------------------------------------------
%% 宠物继承
%% 1- 新宠物将保留主宠形像，自动保留最高的资质、成长，原副宠回收。
%% 2- 自动保留高等级宠物的等级
%% 修改记录: 1. 副宠技能不再转移至主宠身上   
%% -----------------------------------------------------------------
derive_pet(Status, [PetId1, PetId2, DeriveFigure]) ->
    case lib_pet:is_exists_figure_change_pet(Status#player_status.id) of
	false ->
	    Pet1  = lib_pet:get_pet(PetId1),
	    Pet2  = lib_pet:get_pet(PetId2),
	    Cost = data_pet:get_pet_config(derive_cost, []),
	    if  
		%% 资金不足
		Status#player_status.coin < Cost -> [10, Status]; 
		%% 主宠不存在
		Pet1 =:= []  -> [2, Status];
		%% 副宠不存在
		Pet2 =:= []  -> [3, Status];
		true ->
		    [PlayerId1, FightFlag1, Name1, _PetTypeId1, OriginFigure1, Figure1, BaseAptitude1, ExtraAptitude1,  _Quality1, ExtraAptitudeMax1, Growth1, GrowthExp1, GrowthMax1, Level1, _Skills1, Potentials1, ForzaScale1, WitScale1, AgileScale1, ThewScale1, Strength1] = [Pet1#player_pet.player_id, Pet1#player_pet.fight_flag, Pet1#player_pet.name, Pet1#player_pet.type_id, Pet1#player_pet.origin_figure, Pet1#player_pet.figure, Pet1#player_pet.base_aptitude, Pet1#player_pet.extra_aptitude, Pet1#player_pet.quality, Pet1#player_pet.extra_aptitude_max, Pet1#player_pet.growth, Pet1#player_pet.growth_exp, Pet1#player_pet.maxinum_growth, Pet1#player_pet.level, Pet1#player_pet.skills,Pet1#player_pet.potentials, Pet1#player_pet.forza_scale, Pet1#player_pet.wit_scale, Pet1#player_pet.agile_scale, Pet1#player_pet.thew_scale, Pet1#player_pet.strength],
		    [PlayerId2, FightFlag2, Name2, _PetTypeId2, OriginFigure2, Figure2, BaseAptitude2, ExtraAptitude2,_Quality2, ExtraAptitudeMax2, Growth2, GrowthExp2, GrowthMax2, Level2, _Skills2, Potentials2, Strength2] = [Pet2#player_pet.player_id, Pet2#player_pet.fight_flag, Pet2#player_pet.name, Pet2#player_pet.type_id, Pet2#player_pet.origin_figure, Pet2#player_pet.figure, Pet2#player_pet.base_aptitude, Pet2#player_pet.extra_aptitude, Pet2#player_pet.quality, Pet2#player_pet.extra_aptitude_max, Pet2#player_pet.growth, Pet2#player_pet.growth_exp, Pet2#player_pet.maxinum_growth, Pet2#player_pet.level, Pet2#player_pet.skills, Pet2#player_pet.potentials, Pet2#player_pet.strength],
		    if  %% 主宠不归你所有
			PlayerId1 =/= Status#player_status.id -> [4, Status];
			%% 副宠不归你所有
			PlayerId2 =/= Status#player_status.id -> [5, Status];
			%% 主宠正在放出
			FightFlag1   =:= 1 -> [6, Status];
			%% 副宠正在放出
			FightFlag2   =:= 1 -> [7, Status];
			%% 主副宠相同
			PetId1 =:= PetId2 -> [8, Status];
			true ->
			    %% 新资质取两者中最高的
			    NewBaseAptitude = case BaseAptitude1 > BaseAptitude2 of
					      true -> BaseAptitude1;
					      false-> BaseAptitude2
					  end,
                NewExtraAptitude = case ExtraAptitude1 > ExtraAptitude2 of 
                    true -> ExtraAptitude1;
                    false -> ExtraAptitude2
                end,
			    NewQuality = data_pet:get_quality(NewBaseAptitude + NewExtraAptitude),
			    %% 新资质上限取两者中最高的
			    NewExtraAptitudeMax = case ExtraAptitudeMax1 > ExtraAptitudeMax2 of
						       true ->  ExtraAptitudeMax1;
						       false -> ExtraAptitudeMax2
						   end,
			    %% 新成长取两者中最高的,形像光环根据成长值来定
			    NewGrowth = case Growth1 > Growth2 of
					    true ->  Growth1;
					    false -> Growth2
					end,
			    {SubFigure, NewNimbus} = data_pet:get_growth_phase_info(NewGrowth, figure),
			    {NewOriginFigure, NewFigure} = case DeriveFigure of
							       0 -> {OriginFigure1, lib_pet:make_pet_figure(lib_pet:get_pet_figure_type(Figure1), SubFigure)};
							       1 -> {OriginFigure2, lib_pet:make_pet_figure(lib_pet:get_pet_figure_type(Figure2), SubFigure)}
							   end,
			    %% 新成长经验两者取最高的
			    NewGrowthExp = case GrowthExp1 > GrowthExp2 of
					       true ->  GrowthExp1;
					       false -> GrowthExp2
					   end,
			    %% 新成长上限两者取最高的
			    NewMaxinumGrowth = case GrowthMax1 > GrowthMax2 of
						   true ->  GrowthMax1;
						   false -> GrowthMax2
					       end,
			    %% 新快乐值两者取最低的
			    NewStrength = case Strength1 > Strength2 of
					      true -> Strength2;
					      false -> Strength1
					  end,
			    %% 新等级取两者中最高的,新技能取最高等级宠物的技能
			    {NewLevel, NewPetSkills, NewExp} = case Level1 > Level2 of
								   true ->  {Level1, Pet1#player_pet.skills, Pet1#player_pet.upgrade_exp};
								   false -> {Level2, Pet2#player_pet.skills, Pet2#player_pet.upgrade_exp}
							       end,
			    _NewPotentials = merge_potential(Potentials1, Potentials2, []),  
			    NewPotentials = merge_potential2(Pet1#player_pet.level, _NewPotentials, []),
			    %%                     PotentialAverageLev = lib_pet:calc_potential_average_lev(NewPotentials),
			    %%                     MaxSkillNum = data_pet_skill:get_max_skill_num(PotentialAverageLev),
			    %%                     DeffSkills = merge_skill(Skills1, Skills2, MaxSkillNum),
			    [NewForza, NewWit, NewAgile, NewThew] = lib_pet:calc_attr(NewGrowth, NewLevel, [ForzaScale1, WitScale1, AgileScale1, ThewScale1]),
			    %% 基本属性加成
			    NewBaseAddition = lib_pet:calc_base_addition([NewForza, NewWit, NewAgile, NewThew], [ForzaScale1, WitScale1, AgileScale1, ThewScale1], NewLevel),
			    case lib_pet:derive_pet(PetId2, PetId1, NewBaseAptitude, NewExtraAptitude, NewExtraAptitudeMax, NewGrowth, NewGrowthExp, NewMaxinumGrowth, NewLevel, NewQuality, NewPotentials, NewForza, NewWit, NewAgile, NewThew, NewPetSkills) of
				ok ->
				    %% 重新计算属性加层
				    NewPetAttr = lib_pet:calc_pet_attribute(NewForza, NewWit, NewAgile, NewThew, NewBaseAptitude+NewExtraAptitude),
				    %% 更新宠物缓存
				    lib_pet:delete_pet(PetId2),
				    %%                             NewPetSkills = lists:concat([Pet1#player_pet.skills,DeffSkills]),
				    NewPetSkillAttr = lib_pet:calc_pet_skill_attribute(NewLevel, NewPetSkills),
				    NewPetPotentialsAttr = lib_pet:calc_potential_attr_base(NewPotentials),
				    PPA = data_pet_potential:calc_potential_phase_addition(lib_pet:calc_potential_average_lev(NewPotentials)),
                    %% 重新计算基础资质固有加成
                    BaseAptitudeAttr = data_pet:calc_pet_aptitude_attr(NewBaseAptitude),
				    %% 沿用主宠id
				    NewPetTmp  = Pet1#player_pet{
						   forza                          = NewForza,
						   wit                            = NewWit,
						   agile                          = NewAgile,
						   thew                           = NewThew,
						   base_addition                  = NewBaseAddition,
						   base_aptitude                  = NewBaseAptitude,
                           extra_aptitude                 = NewExtraAptitude,
						   extra_aptitude_max             = NewExtraAptitudeMax,
						   quality                        = NewQuality,
						   pet_attr                       = NewPetAttr,
						   growth                         = NewGrowth,
						   growth_exp                     = NewGrowthExp,
						   maxinum_growth                 = NewMaxinumGrowth,
						   level                          = NewLevel,
						   potentials                     = NewPotentials,
						   pet_potential_attr             = NewPetPotentialsAttr,
						   pet_potential_phase_addition   = PPA,
						   upgrade_exp                    = NewExp,
						   skills                         = NewPetSkills,
						   pet_skill_attr                 = NewPetSkillAttr,
						   origin_figure                  = NewOriginFigure,
						   figure                         = NewFigure,
						   nimbus                         = NewNimbus,
						   strength                       = NewStrength,
                           base_aptitude_attr             = BaseAptitudeAttr
						  },
				    NewCombatPower = lib_pet:calc_pet_comat_power_by_pet(Status, NewPetTmp),
				    NewPet = NewPetTmp#player_pet{combat_power = NewCombatPower},
				    lib_pet:update_pet(NewPet),
				    lib_pet:update_combat_on_db(NewPet#player_pet.combat_power, NewPet#player_pet.id),
				    case Pet1#player_pet.fight_flag of
					%%放出
					1 ->
					    NewStatus = lib_pet:calc_player_attribute(Status, NewPetAttr, NewPetSkillAttr, lib_pet:calc_potential_attr(NewPet),BaseAptitudeAttr);
					%%未放出
					0 ->
					    NewStatus = Status
				    end,
				    %% 目标：获得一个资质大于680的宠物 301
				    mod_target:trigger(Status#player_status.status_target, NewStatus#player_status.id, 301, NewBaseAptitude+NewExtraAptitude),
				    %% 记录日志
				    SQL = io_lib:format(?SQL_PET_UPDATE_GROWTH_FIGURE_NIMBUS, [NewGrowth, NewFigure, NewNimbus, NewPet#player_pet.id]),
				    db:execute(SQL),
				    Pet1BaseAttr = [Pet1#player_pet.forza, Pet1#player_pet.wit, Pet1#player_pet.agile, Pet1#player_pet.thew],
				    Pet2BaseAttr = [Pet2#player_pet.forza, Pet2#player_pet.wit, Pet2#player_pet.agile, Pet2#player_pet.thew],
				    NewPetInfo = [NewPet#player_pet.level, NewPet#player_pet.base_aptitude+NewPet#player_pet.extra_aptitude, NewPet#player_pet.growth, [NewPet#player_pet.forza, NewPet#player_pet.wit, NewPet#player_pet.agile, NewPet#player_pet.thew]],
				    send_log_pet(derive_pet, Status#player_status.id, PetId1, [PetId1, Name1, Level1, BaseAptitude1+ExtraAptitude1, ExtraAptitudeMax1, Growth1, Potentials1, Pet1BaseAttr, PetId2, Name2, Level2, BaseAptitude2+ExtraAptitude2, ExtraAptitudeMax2, Growth2, Potentials2, Pet2BaseAttr, NewPetInfo]),
				    [1, NewStatus];
				_ ->
				    [0, Status]
			    end
		    end
	    end;
	true ->
	    [11, Status]
    end.

%% merge_skill(Skills1, Skills2, MaxSkillNum) ->
%%     Skills1TypeList = lists:map(fun(Skill1) -> Skill1#pet_skill.type_id end, Skills1),
%%     Skills2TypeList = lists:map(fun(Skill2) -> Skill2#pet_skill.type_id end, Skills2),
%%     
%%     DeffTypeList = Skills2TypeList -- Skills1TypeList,
%%     CanLearnNum = MaxSkillNum-length(Skills1),
%%     DeffTypeList1 = util:list_shuffle(DeffTypeList),
%%     DeffTypeList2 = lists:sublist(DeffTypeList1, CanLearnNum),
%%     if
%%         DeffTypeList2 =:= [] ->
%%             [];
%%         true ->
%%             F = fun(SkillTypeId) ->
%%                     case lists:keysearch(SkillTypeId, 4, Skills2) of
%%                         {value, _S} -> _S;
%%                         false -> []
%%                     end
%%                 end,
%%             DeffSkillList = lists:map(F, DeffTypeList2),
%%             lists:flatten(DeffSkillList)
%%     end.
%% -----------------------------------------------------------------
%% 属性还童
%% -----------------------------------------------------------------
restore_attr(Status, [PetId, GoodsId, GoodsUseNum]) ->
    Pet = lib_pet:get_pet(PetId),
    Go = Status#player_status.goods,
    if  %% 宠物不存在
        Pet =:= []  -> [2, 0, 0, 0, 0];
        true ->
            [PlayerId, Growth] = 
		[Pet#player_pet.player_id, Pet#player_pet.growth],
            if  %% 宠物不归你所有
                PlayerId /= Status#player_status.id -> [3, 0, 0, 0, 0];
                true ->
                    Dict = lib_goods_dict:get_player_dict(Status),
                    Goods = lib_goods_util:get_goods(GoodsId, Dict),
                    if  %% 该物品不存在
                        Goods =:= []  -> [5, 0, 0, 0, 0];
                        true ->
                            [MedicineGoodsType, MedicineGoodsSubType] = data_pet:get_pet_config(goods_restore_attr_medicine,[]),
                            [GoodsPlayerId, _GoodsTypeId, GoodsType, GoodsSubtype, _GoodsNum]  =
                                [Goods#goods.player_id, Goods#goods.goods_id, Goods#goods.type, Goods#goods.subtype, Goods#goods.num],
                            if  %% 物品不归你所有
                                GoodsPlayerId /= Status#player_status.id -> [6, 0, 0, 0, 0];
				%% 该物品不是还原丹
                                ((GoodsType /= MedicineGoodsType) and (GoodsSubtype /= MedicineGoodsSubType)) -> [7, 0, 0, 0, 0];
                                true ->
                                    case gen_server:call(Go#status_goods.goods_pid, {'delete_one', GoodsId, GoodsUseNum}) of
                                        1 ->
                                            [ForzaScale, WitScale, AgileScale, ThewScale] = data_pet:get_growth_scale(Growth),
                                            lib_pet:update_last_scale_on_db(ForzaScale, WitScale, AgileScale, ThewScale, PetId),
					    %% 更新缓存
                                            PetNew = Pet#player_pet{last_forza_scale    = ForzaScale,
                                                                    last_wit_scale      = WitScale,
                                                                    last_agile_scale    = AgileScale,
                                                                    last_thew_scale     = ThewScale},
                                            lib_pet:update_pet(PetNew),
                                            [NewForza, NewWit, NewAgile, NewThew] = lib_pet:calc_attr(Growth, PetNew#player_pet.level, [ForzaScale, WitScale, AgileScale, ThewScale]),
                                            [1, NewForza, NewWit, NewAgile, NewThew];
					%% 扣取物品失败
                                        0 ->
                                            [0, 0, 0, 0, 0];
					%% 物品数量不够
                                        GoodsModuleCode ->
                                            util:errlog("restore_attr: Call goods module faild, result code=[~p]", [GoodsModuleCode]),
                                            [8, 0, 0, 0, 0]
                                    end
                            end
		    end
            end
    end.

%% -----------------------------------------------------------------
%% 宠物还童替换
%% -----------------------------------------------------------------
replace_attr(Status, [PetId]) ->
    Pet = lib_pet:get_pet(PetId),
    if  %% 宠物不存在
        Pet =:= []  -> [2, 0, []];
        true ->
            [PlayerId, FightFlag, Growth, Level, Aptitude, LastForzaScale, LastWitScale, LastAgileScale, LastThewScale] = 
		[Pet#player_pet.player_id, Pet#player_pet.fight_flag, Pet#player_pet.growth, Pet#player_pet.level, Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude, Pet#player_pet.last_forza_scale, Pet#player_pet.last_wit_scale, Pet#player_pet.last_agile_scale, Pet#player_pet.last_thew_scale],
            if  %% 宠物不归你所有
                PlayerId /= Status#player_status.id -> [3, 0, []];
                (LastForzaScale+LastWitScale+LastAgileScale+LastThewScale) =< 0 -> [0 , 0, []];
                true ->
                    [NewForza, NewWit, NewAgile, NewThew] = lib_pet:calc_attr(Growth, Level, [LastForzaScale, LastWitScale, LastAgileScale, LastThewScale]),
                    NewPetAttr = lib_pet:calc_pet_attribute(NewForza, NewWit, NewAgile, NewThew, Aptitude),
                    lib_pet:update_last_scale_on_db(0, 0, 0, 0, PetId),
		    %% 更新缓存
                    PetNew = Pet#player_pet{forza    = NewForza,
                                            wit      = NewWit,
                                            agile    = NewAgile,
                                            thew     = NewThew,
                                            pet_attr = NewPetAttr,
                                            forza_scale = LastForzaScale, 
                                            wit_scale = LastWitScale, 
                                            agile_scale = LastAgileScale,
                                            thew_scale = LastThewScale,
                                            last_forza_scale = 0, 
                                            last_wit_scale = 0, 
                                            last_agile_scale = 0,
                                            last_thew_scale = 0
					   },
                    lib_pet:update_pet(PetNew),
                    lib_pet:update_scale_on_db(LastForzaScale, LastWitScale, LastAgileScale, LastThewScale, PetId),
                    case FightFlag =:= 1 of
                        true ->
                            [1, 1, NewPetAttr];
                        false ->
                            [1, 0, NewPetAttr]
                    end                    
            end
    end.
%% -----------------------------------------------------------------
%% 宠物成长
%% -----------------------------------------------------------------
%% @param:IsUseMedicine: notmed(atom)非成长丹成长 | 物品类型id(number)  GoodsId:丹药物品id
%% @return:[#player_status, 提升成长错误码, 角色属性改变标志, 新宠物属性列表, 增加提升次数, 描述信息, 是否10倍经验, 是否升阶]
grow_up(Status, PetId, IsUseMedicine, GoodsId, GoodsUseNum) ->
    Pet = lib_pet:get_pet(PetId),
    Go = Status#player_status.goods,
    %_DailyCount = mod_daily_dict:get_count(Status#player_status.id, 5000000), %%宠物提升成长总计数
    %_MaxinumGrowthTime = data_pet:get_pet_config(maxinum_growth_time, []), 
    FreeDailyCount = mod_daily_dict:get_count(Status#player_status.id, 5000003), %%宠物提升成长免费计数
    FreeGrowthTime = data_pet:get_pet_config(free_growth_time, []),
    if  %% 宠物不存在
        Pet =:= []  -> [Status, 2, 0, [], 0, <<>>, 0, 0, 0];
        true ->
            [PlayerId, FightFlag, Growth, MaxGrowth] = [Pet#player_pet.player_id, Pet#player_pet.fight_flag, Pet#player_pet.growth, Pet#player_pet.maxinum_growth],
            if  %% 宠物不归你所有
                PlayerId =/= Status#player_status.id -> [Status, 3, 0, [], 0, <<>>, 0, 0, 0];
		%% 宠物已达到成长值上限
                Growth >= MaxGrowth -> [Status, 4, 0, [], 0, <<>>, 0, 0, 0];
                %% 玩家等级不够
                Status#player_status.lv < 40 -> [Status, 0, 0, [], 0, <<>>, 0, 0, 0];
                true ->
		    %% Res:执行结果, Reason:原因, GrowthExp2:{经验倍率，元宝经验}, Status2:#player_status, GrowType:0免费，1铜币，2道具，3元宝
                    [Res, Reason, GrowthExp2, Status2, GrowType] = 
			case IsUseMedicine of
			    MedicineId when is_number(MedicineId) ->
				case gen_server:call(Go#status_goods.goods_pid, {'delete_list', [{GoodsId, GoodsUseNum}]}) of
				    1 ->
					%% log:log_goods_use(PlayerId, MedicineId, GoodsUseNum),
					%% log:log_throw(pet_grow, PlayerId, GoodsId, MedicineId, GoodsUseNum, 0, 0),
					GrowthExp1 = data_pet:get_growth_exp_by_medicine(MedicineId, GoodsUseNum),
					%% 获得10倍经验或者直接加1的，额外增加一次提升次数
					case GrowthExp1 of
					    {five, _} ->	mod_daily_dict:increment(Status#player_status.id, 5000000);
					    {direct, _} -> mod_daily_dict:increment(Status#player_status.id, 5000000);
					    {medicine, _} -> skip;
					    _ -> mod_daily_dict:increment(Status#player_status.id, 5000000)
					end,
					%lib_qixi:update_player_task(Status#player_status.id, t1),
					[1, 0, GrowthExp1, Status, 2];
				    GoodsModuleCode ->   
					util:errlog("grow_up: Call goods module faild, result code=[~p]", [GoodsModuleCode]),
					[0, 0, 0, Status, 2]
				end;
			    _ ->
				case FreeDailyCount < FreeGrowthTime of 
				    %%未超过每日免费提升
				    true ->
					mod_daily_dict:increment(PlayerId, 5000003), %% 免费宠物提升成长--------5000003
					mod_daily_dict:increment(PlayerId, 5000000), %% 宠物提升成长总次数--------5000000
					CurrentGrowthExp = Pet#player_pet.growth_exp,
					NewGrowthExp = data_pet:get_grow_exp(Pet#player_pet.growth),
					GrowthExp1 = data_pet:get_growth_exp(free, CurrentGrowthExp, NewGrowthExp, Pet#player_pet.growth),
					%lib_qixi:update_player_task(Status#player_status.id, t1),
					%% ConsumptionStatus = lib_player:add_consumption(petcz,Status,0,1),
					ConsumptionStatus = Status,
					[1, 0, GrowthExp1, ConsumptionStatus, 0];
				    false ->
                    %% 成长丹类型		
					GoodsTypeId = data_pet:get_pet_config(grow_up_goods, []),
                    %% 成长丹数量
                    SingleGrowNum = data_pet:get_single_grow_goods_num(Growth),
					case gen_server:call(Go#status_goods.goods_pid, {'delete_more', GoodsTypeId, SingleGrowNum}) of 
                        %% 成功
                        1 -> 
                            log:log_goods_use(Status#player_status.id, GoodsTypeId, SingleGrowNum),
                            CurrentGrowthExp = Pet#player_pet.growth_exp,
                            NewGrowthExp = data_pet:get_grow_exp(Pet#player_pet.growth),
                            GrowthExp1 = data_pet:get_growth_exp(item, CurrentGrowthExp, NewGrowthExp, Pet#player_pet.growth),
                            case GrowthExp1 of
                                {five, _} -> mod_daily_dict:increment(Status#player_status.id, 5000000);
                                {direct, _} -> mod_daily_dict:increment(Status#player_status.id, 5000000);
                                {medicine, _} -> skip;
                                _ -> mod_daily_dict:increment(Status#player_status.id, 5000000)
                            end,
                            [1, 0, GrowthExp1, Status, 2];
                        _ ->
                        [0, 6, 0, Status, 2]
                    end
                end
            end,
            case Res =:= 1 of
			    %% 提升成功
                true ->
                    pp_login_gift:handle(31204, Status2, no),
			        %% Growth3:提升后的成长值
                    [NewPetAttr, Growth3, GrowthExp3] = lib_pet:add_growth_exp(Status, Pet, GrowthExp2), 
			         %% 目标：将宠物的成长提升到20以上  405
			         mod_target:trigger(Status2#player_status.status_target, Status2#player_status.id, 405, Growth3),
                     mod_achieve:trigger_role(Status2#player_status.achieve, Status2#player_status.id, 66, 0, 1),
                     if
                        Growth3 > Pet#player_pet.growth -> mod_achieve:trigger_role(Status2#player_status.achieve, Status2#player_status.id, 18, 0, Growth3);
                        true -> skip
                    end,
			        %% 触发名人堂：宝贝来了，第一个宠物成长达到35
                    if
                        Growth3 >= 40 -> mod_fame:trigger(Status2#player_status.mergetime, Status2#player_status.id, 6, 0, Growth3);
                        true -> skip
                    end,
			       %% _Type:提升类型 _Exp:获得的成长经验
                    {_Type, _Exp} = GrowthExp2,
			      %% [成长倍率，额外提升，信息，是否10倍]
                    [GrowthMul3, Again, Msg, TenMul] = 
				    case _Type of
				        direct ->
					       [1, 1, data_pet_text:get_msg(11), 0];  %% 元宝提升，直接提升1
				        five ->
					       Format = data_pet_text:get_msg(12),
					       _Msg = io_lib:format(Format, [_Exp]),
					       [5, 0, list_to_binary(_Msg), 1]; %% 元宝提升
				        medicine ->
					       [1, 0, <<>>, 0]; %% 成长丹提升
				        _ ->
					       Format = data_pet_text:get_msg(13),
					       _Msg = io_lib:format(Format, [_Exp]),
					       [1, 0, list_to_binary(_Msg), 0]  %% 元宝提升
				    end,
                    IsUpgradePhase = data_pet:is_growth_upgrade_phase(Growth, Growth3),
                    % %% 如果升级了，把宠物的经验值置0
                    % case IsUpgradePhase =:= 1 of 
                    %     true ->
                    %         GrowthExp4 = 0,
                    %         NewPet = Pet#player_pet{growth_exp = GrowthExp4},
                    %         lib_pet:update(NewPet),
                    %         Sql = io_lib:format(?SQL_PET_UPDATE_GROWTHEXP, [GrowthExp4, NewPet#player_pet.id]),
                    %         db:execute(Sql);
                    %     false ->
                    %         GrowthExp4 = GrowthExp3
                    % end,
                    send_log_pet(grow_up, Status2#player_status.id, PetId, [GrowType, GrowthMul3, Pet#player_pet.growth_exp, GrowthExp3, Growth, Growth3, GrowthExp3]),
			       case FightFlag =:= 1 of               
                        true ->
                            [Status2, 1, 1, NewPetAttr, Again, Msg, TenMul, IsUpgradePhase, _Exp];
                        false ->
                            [Status2, 1, 0, NewPetAttr, Again, Msg, TenMul, IsUpgradePhase, _Exp]
                   end;
                false ->
                    [Status2, Reason, 0, [], 0, <<>>, 0, 0, 0]
            end
        end
    end.

grow_up_batch(Status, PetId) ->
    Pet = lib_pet:get_pet(PetId),
    _Go = Status#player_status.goods,
    DailyCount = mod_daily_dict:get_count(Status#player_status.id, 5000000), %%宠物提升成长总计数
    FreeDailyCount = mod_daily_dict:get_count(Status#player_status.id, 5000003), %%宠物提升成长免费计数
    FreeGrowthTime = data_pet:get_pet_config(free_growth_time, []),
    if  %% 宠物不存在
        Pet =:= []  -> [Status, 2, 0, [], 0, []];
        true ->
            [PlayerId, FightFlag, Growth, MaxGrowth] = [Pet#player_pet.player_id, Pet#player_pet.fight_flag, Pet#player_pet.growth, Pet#player_pet.maxinum_growth],
            if  %% 宠物不归你所有
                PlayerId =/= Status#player_status.id -> [Status, 3, 0, [], 0, []];
		%% 宠物已达到成长值上限
                Growth >= MaxGrowth -> [Status, 4, 0, [], 0, []];
                %% 宠物等级不够
                Status#player_status.lv < 40 -> [Status, 0, 0, [], 0, []];
                true ->
		    %% Res:执行结果, Reason:原因, GrowthExpList:[{经验倍率，元宝经验},.....], Status2:#player_status, GrowType:0免费，1铜币，2道具，3元宝
             %% 批量成长
                    [Res, Reason, GrowthExpList, Status2, GrowType] = 
                    case FreeDailyCount < FreeGrowthTime of
                        %% 未超过每日免费提升
                        true -> 
                            %% 所需的成长丹类型和数量
                            GoodsTypeId = data_pet:get_pet_config(grow_up_goods, []),
                            SingleGrowNum = data_pet:get_single_grow_goods_num(Growth),
                            case DailyCount >= 1 of 
                                true ->
                                    TotalGrowNum = 10*SingleGrowNum;
                                false ->
                                    TotalGrowNum = 9*SingleGrowNum
                            end,
                            GoodsNumOwn = mod_other_call:get_goods_num(Status, GoodsTypeId, 0),
                            case GoodsNumOwn < TotalGrowNum of 
                            %% 道具不足
                                true -> 
                                    [0, 6, [], Status, 2];
                                false ->
                                    CurrentGrowthExp = Pet#player_pet.growth_exp,
                                    GrowthExpLevelMax = data_pet:get_grow_exp(Pet#player_pet.growth), 
                                    GrowthExpFree = data_pet:get_growth_exp(free, CurrentGrowthExp, GrowthExpLevelMax, Pet#player_pet.growth),
                                    ExpList = lists:map(fun(_) -> 
                                        data_pet:get_growth_exp(item, CurrentGrowthExp, GrowthExpLevelMax, Pet#player_pet.growth)
                                        end,lists:seq(1, 9)),
                                    _NewExpList = [GrowthExpFree|ExpList],
                                    NewExpList = lib_pet:is_upgrade_batch_grow(_NewExpList, CurrentGrowthExp, Pet#player_pet.growth, false, []),
                                    %% 实际所用的成长丹数量
                                    _UseGoodsNum = length(NewExpList) - 1,
                                    UseGoodsNum = SingleGrowNum*_UseGoodsNum,
                                    case GoodsNumOwn < UseGoodsNum of 
                                        true -> 
                                            [0, 6, [], Status, 2];
                                        false -> 
                                            %%扣物品和提升次数
                                            lib_player:update_player_info(Status#player_status.id, [{use_goods, {GoodsTypeId, UseGoodsNum}}]),
                                            log:log_goods_use(Status#player_status.id, GoodsTypeId, UseGoodsNum),
                                            mod_daily_dict:increment(PlayerId, 5000003), %% 免费宠物提升成长--------5000003
                                            mod_daily_dict:set_count(PlayerId, 5000000, DailyCount + _UseGoodsNum), %% 宠物提升成长总次数--------5000000
                                            [1, 0, NewExpList, Status, 2]
                                    end
                            end;
                        false -> 
                            %% 所需的成长丹类型和数量
                             GoodsTypeId = data_pet:get_pet_config(grow_up_goods, []),
                            SingleGrowNum = data_pet:get_single_grow_goods_num(Growth),
                            GoodsTypeNum = 10*SingleGrowNum,
                            GoodsNumOwn = mod_other_call:get_goods_num(Status, GoodsTypeId, 0),
                            case GoodsNumOwn < GoodsTypeNum of 
                                true -> 
                                    [0, 6, [], Status, 2];
                                false -> 
                                    GrowthExpLevelMax = data_pet:get_grow_exp(Pet#player_pet.growth),
                                    CurrentGrowthExp = Pet#player_pet.growth_exp,
                                    Seq = lists:seq(1, 10),
                                    ExpList = lists:map(fun(_) ->
                                        data_pet:get_growth_exp(item, CurrentGrowthExp, GrowthExpLevelMax, Pet#player_pet.growth)
                                            end, Seq),
                                    NewExpList = lib_pet:is_upgrade_batch_grow(ExpList, CurrentGrowthExp, Pet#player_pet.growth, false, []),
                                    %% 实际使用的成长丹数量
                                    _UseGoodsNum = length(NewExpList),
                                    UseGoodsNum = _UseGoodsNum*SingleGrowNum,
                                    case GoodsNumOwn < UseGoodsNum of 
                                        true -> 
                                            [0, 6, [], Status, 2];
                                        false -> 
                                            lib_player:update_player_info(Status#player_status.id, [{use_goods, {GoodsTypeId, UseGoodsNum}}]),
                                            log:log_goods_use(Status#player_status.id, GoodsTypeId, UseGoodsNum),
                                            mod_daily_dict:set_count(PlayerId, 5000000, DailyCount + UseGoodsNum),
                                            [1, 0, NewExpList, Status, 2]
                                    end 
                            end
                end,       
            case Res =:= 1 of
			%% 提升成功
            true ->
                pp_login_gift:handle(31204, Status2, no),
			    %% Growth3:提升后的成长值
			    ExpValue = lists:foldl(fun(X, Sum) ->
							   {_, Val} = X,
							   Val + Sum
						   end, 0 ,GrowthExpList),
                            [NewPetAttr, Growth3, GrowthExp3] = lib_pet:add_growth_exp(Status, Pet, ExpValue), 
			    %% 目标：将宠物的成长提升到20以上 405
			    mod_target:trigger(Status2#player_status.status_target, Status2#player_status.id, 405, Growth3),
                            mod_achieve:trigger_role(Status2#player_status.achieve, Status2#player_status.id, 66, 0, 1),
                            if
                                Growth3 > Pet#player_pet.growth -> mod_achieve:trigger_role(Status2#player_status.achieve, Status2#player_status.id, 18, 0, Growth3);
                                true -> skip
                            end,
			    %% 触发名人堂：宝贝来了，第一个宠物成长达到35
                            if
                                Growth3 >= 40 -> mod_fame:trigger(Status2#player_status.mergetime, Status2#player_status.id, 6, 0, Growth3);
                                true -> skip
                            end,
                IsUpgradePhase = data_pet:is_growth_upgrade_phase(Growth, Growth3),
                    % %% 如果升级了，把宠物的经验值置0
                    % case IsUpgradePhase =:= 1 of 
                    %     true ->
                    %         GrowthExp4 = 0,
                    %         NewPet = Pet#player_pet{growth_exp = GrowthExp4},
                    %         lib_pet:update(NewPet),
                    %         Sql = io_lib:format(?SQL_PET_UPDATE_GROWTHEXP, [GrowthExp4, NewPet#player_pet.id]),
                    %         db:execute(Sql);
                    %     false ->
                    %         GrowthExp4 = GrowthExp3
                    % end,
			    send_log_pet(grow_up, Status2#player_status.id, PetId, [GrowType, 0, Pet#player_pet.growth_exp, GrowthExp3, Growth, Growth3, GrowthExp3]),
                %IsUpgradePhase = data_pet:is_growth_upgrade_phase(Growth, Growth3),
			    case FightFlag =:= 1 of
                                true ->
                                    [Status2, 1, 1, NewPetAttr, IsUpgradePhase, GrowthExpList];
                                false ->
                                    [Status2, 1, 0, NewPetAttr, IsUpgradePhase, GrowthExpList]
                            end;
            false ->
                [Status2, Reason, 0, [], 0, []]
            end
            end
    end.




%% -----------------------------------------------------------------
%% 宠物展示
%% -----------------------------------------------------------------
show_pet(Status, [PetId, PlayerId]) ->
    case Status#player_status.id =:= PlayerId of
	false ->
	    BOOL = lib_player:is_online_global(PlayerId),
	    if  %% 玩家不在线
		BOOL =:= false ->
		    %% 从数据库查找
		    Q1 = io_lib:format(<<"select pet.id,pet.`name`,player_low.nickname,pet.`level`,pet.quality,pet.figure,pet.nimbus,pet.base_aptitude, pet.extra_aptitude, pet.growth,pet.combat_power FROM pet,player_low where pet.player_id=player_low.id and player_low.id=~p and pet.id=~p">>,[PlayerId, PetId]),
		    case db:get_row(Q1) of
			[] -> [0, <<>>];
			R ->
			    [Id,_PetName,_PlayerName,Lv,Quality,Figure,Nimbus,BaseAptitude, ExtraAptitude, Growth,CombatPower] = R,
			    Q2 = io_lib:format(<<"select id,type_id,level,type FROM pet_skill where pet_id=~p">>,[PetId]),
			    _Skills = case db:get_all(Q2) of
					  [] -> [];
					  List ->
					      lists:map(fun([SkillId,Skill,SkillLv,SkillType]) ->
								SkillTypeId = lib_pet:make_pet_skill_type_id(Skill, SkillLv),
								<<SkillId:32,  SkillTypeId:32, SkillLv:16, SkillType:8>>
							end, List)
				      end,
		    Q3 = io_lib:format(<<"select potential_type_id, lv FROM pet_potential where pet_id=~p">>,[PetId]),
		    PotentialLv = case db:get_all(Q3) of
				      [] -> 0;
				      _Potential ->
					  LvSum = lists:foldl(fun([PotentialTypeId, AccLv], AccIn) ->
								      case PotentialTypeId of
									  2 -> AccIn;
									  12 -> AccIn;
									  _ -> AccLv + AccIn
								      end
							      end, 0, _Potential),
					  LvSum div (length(_Potential) - 2)
					  end,
			    PetName = pt:write_string(_PetName),
			    PlayerName = pt:write_string(_PlayerName),
			    Skills = list_to_binary(_Skills),
			    SkillsLen = length(_Skills),
                %% 手机版资质 = 基础资质 + 额外资质
                Aptitude = BaseAptitude + ExtraAptitude,
			    [1,<<Id:32,PetName/binary, PlayerName/binary, Lv:16,Quality:8, SkillsLen:16, Skills/binary,Figure:16, Nimbus:16, Aptitude:16, Growth:32, PotentialLv:16, CombatPower:32>>]
		    end;
		true ->
		    Pet1 = lib_player:rpc_call_by_id(PlayerId, lib_pet, get_pet, [PetId]),
		    if  %% 宠物不存在
			Pet1 =:= [] ->
			    [0, <<>>];
			true ->
			    case lib_player:get_player_info(PlayerId, nickname) of
				false -> [0, <<>>];
				PlayerName -> 
				    %% 解析宠物信息
				    PetBin = lib_pet:parse_show_pet_info(Pet1, PlayerName),
				    [1, PetBin]
			    end
		    end
	    end;
	true ->
	    Pet1 = lib_pet:get_pet(PetId),
	    if  %% 宠物不存在
		Pet1 =:= [] ->
		    [0, <<>>];
		true ->
		    %% 解析宠物信息
		    PetBin = lib_pet:parse_show_pet_info(Pet1, Status#player_status.nickname),
		    [1, PetBin]
	    end
    end.

%% -----------------------------------------------------------------
%% 宠物幻化值排行榜
%% -----------------------------------------------------------------
show_pet_figure_change(Status, [PetId]) ->
    Pet1 = lib_pet:get_fighting_pet(PetId),
    if  %% 宠物不存在
	Pet1 =:= [] ->
	    [0, <<>>];
	true ->
	    %% 解析宠物信息
	    PetBin = lib_pet:parse_show_pet_figure_change_info(Pet1, Status#player_status.nickname, Status#player_status.unreal_figure_activate, Status#player_status.pet_figure_value),
	    [1, PetBin]
    end.

show_pet_figure_change_from_db(PlayerId) ->
    %% 从数据库查找
    Q1 = io_lib:format(<<"select pet.id,pet.`name`,player_low.nickname,pet.`level`,pet.quality,pet.figure,pet.nimbus,pet.aptitude,pet.growth,pet.combat_power FROM pet,player_low where pet.player_id=player_low.id and player_low.id=~p and pet.fight_flag=1">>,[PlayerId]),
    case db:get_row(Q1) of
	[] -> [0, <<>>];
	R ->
	    [PetId,_PetName,_PlayerName,Lv,Quality,Figure,Nimbus,Aptitude,Growth,CombatPower] = R,
	    Q2 = io_lib:format(<<"select id,type_id,level,type FROM pet_skill where pet_id=~p">>,[PetId]),
	    _Skills = case db:get_all(Q2) of
			  [] -> [];
			  _SkillList ->
			      lists:map(fun([SkillId,Skill,SkillLv,SkillType]) ->
						SkillTypeId = lib_pet:make_pet_skill_type_id(Skill, SkillLv),
						<<SkillId:32,  SkillTypeId:32, SkillLv:16, SkillType:8>>
					end, _SkillList)
		      end,
	    Q3 = io_lib:format(<<"select potential_type_id, lv FROM pet_potential where pet_id=~p">>,[PetId]),
	    PotentialLv = case db:get_all(Q3) of
			      [] -> 0;
			      _Potential ->
				  LvSum = lists:foldl(fun([PotentialTypeId, AccLv], AccIn) ->
							      case PotentialTypeId of
								  2 -> AccIn;
								  12 -> AccIn;
								  _ -> AccLv + AccIn
							      end
						      end, 0, _Potential),
				  LvSum div (length(_Potential) - 2)
			  end,
	    Q4 = io_lib:format(<<"select type_id,figure_id,change_flag,activate_flag,last_time from pet_figure_change where player_id=~p">>, [PlayerId]),
	    _FigureList = case db:get_all(Q4) of
			      [] -> [];
			      FList -> [<<FTypeId:32, FigureId:16, ChangeFlag:8, ActivateFlag:8, LastTime:32>> || [FTypeId, FigureId, ChangeFlag, ActivateFlag, LastTime] <- FList]
			  end,
	    Q5 = io_lib:format(<<"select `value` from pet_figure_change_value where player_id=~p">>, [PlayerId]),
	    FigureVal = case db:get_one(Q5) of
			    null -> 0;
			    _FigureVal -> _FigureVal
			end,
	    PetName = pt:write_string(_PetName),
	    PlayerName = pt:write_string(_PlayerName),
	    FigureList = list_to_binary(_FigureList),
	    FigureListLen = length(_FigureList),
	    [1,<<PetId:32,PetName/binary, PlayerName/binary, Lv:16,Quality:8, FigureListLen:16, FigureList/binary, Figure:16, Nimbus:16, Aptitude:16, Growth:32, PotentialLv:16, CombatPower:32, FigureVal:32>>]
    end.


%% -----------------------------------------------------------------
%% 宠物资质提升
%% -----------------------------------------------------------------
%%  [Status, 2, 0, [], 0] = [PlayerStatus，结果，出战状态，属性列表，新资质值]
aptitude_up(Status, PetId, GoodsTypeId, GoodsId, GoodsUseNum) ->
    Pet = lib_pet:get_pet(PetId),
    Go = Status#player_status.goods,
    if  %% 宠物不存在
        Pet =:= []  -> [Status, 2, 0, [], 0];
	%%Pet#player_pet.aptitude >= 1000 -> [Status, 0, 0, [], 0];
        true ->
            [PlayerId, FightFlag] = [Pet#player_pet.player_id, Pet#player_pet.fight_flag],
            if  %% 宠物不归你所有
                PlayerId =/= Status#player_status.id -> [Status, 3, 0, [], 0];
                %% 宠物已达最大资质值
                Pet#player_pet.extra_aptitude >= Pet#player_pet.extra_aptitude_max -> [Status, 4, 0, [], 0];
                true ->
		    %% Res:结果, Reason:原因, Status2:#player_status
                    [Res, Reason, Status2] = 
			case gen_server:call(Go#status_goods.goods_pid, {'delete_list', [{GoodsId, GoodsUseNum}]}) of
			    1 ->
				%% log:log_goods_use(PlayerId, GoodsTypeId, GoodsUseNum),
				%% log:log_throw(pet_aptitude, PlayerId, GoodsId, GoodsTypeId, GoodsUseNum, 0, 0),
				[1, 0, Status];
			    GoodsModuleCode ->   
				util:errlog("grow_up: Call goods module faild, result code=[~p]", [GoodsModuleCode]),
				[0, 0, Status]
			end,
                    case Res =:= 1 of
			%% 提升成功
                        true ->
                            [NewPetAttr, NewAptitude, Value] = lib_pet:add_aptitude(Pet, GoodsTypeId),
			    catch db:execute(io_lib:format(<<"insert into log_pet_up_aptitude(player_id,old_aptitude,new_aptitude,aptitude,ts) values(~p,~p,~p,~p,~p)">>,[Status2#player_status.id,Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude,NewAptitude,Value,util:unixtime()])),
                            case FightFlag =:= 1 of
                                true ->
                                    Status3 = Status2#player_status{pet = Status2#player_status.pet#status_pet{pet_aptitude = NewAptitude}},
                                    [Status3, 1, 1, NewPetAttr, NewAptitude];
                                false ->
                                    [Status2, 1, 0, NewPetAttr, NewAptitude]
                            end;
                        false ->
                            [Status2, Reason, 0, [], 0]
                    end
            end
    end.
%% -----------------------------------------------------------------
%% 宠物出战替换
%% -----------------------------------------------------------------
fighting_pet_replace(Status, [PetId]) ->
    Pet = lib_pet:get_pet(PetId),
    if  %% 宠物不存在
        Pet =:= []  -> [2, [], [], 0, 0, 0, <<>>, 0];
        true ->
            [PlayerId, FightFlag, PetAttr, PetPotentialAttr, PetFigure, PetNimbus, PetLevel, PetName, PetStrength, PetAptitude] = [Pet#player_pet.player_id, Pet#player_pet.fight_flag, Pet#player_pet.pet_attr, Pet#player_pet.pet_potential_attr, Pet#player_pet.figure, Pet#player_pet.nimbus,Pet#player_pet.level, Pet#player_pet.name, Pet#player_pet.strength, Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude],
            if  %% 该宠物不归你所有
                PlayerId =/= Status#player_status.id -> [3, [], [], 0, 0, 0, <<>>, 0];
		%% 宠物已经出战
                FightFlag =:= 1 -> [4, [], [], 0, 0, 0, <<>>, 0];
        %% 玩家34级才能出战,如果现在有出战宠物
                Status#player_status.lv < 34 -> [6, [], [], 0, 0, 0, <<>>, 0];
		%% 宠物快乐值为0
                PetStrength =:= 0 -> [5, [], [], 0, 0, 0, <<>>, 0];
                true ->
                    FightingPet  = lib_pet:get_fighting_pet(PlayerId),
                    if  %% 已经有其他宠物出战
                        FightingPet =/= [] ->
                            [PetId1, PlayerId1, FightFlag1, FightStartTime1, UpgradeExp1, Level1] = [FightingPet#player_pet.id, FightingPet#player_pet.player_id, FightingPet#player_pet.fight_flag, FightingPet#player_pet.fight_starttime, FightingPet#player_pet.upgrade_exp, FightingPet#player_pet.level],
			    %% 计算升级经验
                            NewUpgradeExp1 = lib_pet:calc_upgrade_exp(FightFlag1, FightStartTime1, UpgradeExp1, Level1, PlayerId1),
                            case lib_pet:rest_pet(PetId1, NewUpgradeExp1) of
                                ok  ->
				    %% 更新缓存
                                    PetNew1 = FightingPet#player_pet{fight_flag        = 0,
								     fight_starttime   = 0,
								     upgrade_exp       = NewUpgradeExp1,
								     strength_nexttime = 0},
                                    lib_pet:update_pet(PetNew1),
                                    case lib_pet:fighting_pet(PetId) of
                                        ok  ->
					    %% 更新缓存
                                            NowTime = util:unixtime(),
                                            PetNew = Pet#player_pet{fight_flag        = 1,
								    fight_starttime   = NowTime,
								    strength_nexttime = util:floor(NowTime/60)
								   },
                                            lib_pet:update_pet(PetNew),
                                            [1, PetAttr, PetPotentialAttr, PetFigure, PetNimbus, PetLevel, PetName, PetAptitude];
                                        _  ->
                                            [0, [], [], 0, 0, 0, <<>>, 0]
                                    end;
				_   ->
				    [0, [], [], 0, 0, 0, <<>>, 0]
                            end;
			%% 没有其他宠物正在出战
                        true ->
                            case lib_pet:fighting_pet(PetId) of
                                ok  ->
				    %% 更新缓存
                                    NowTime = util:unixtime(),
                                    PetNew = Pet#player_pet{fight_flag        = 1,
							    fight_starttime   = NowTime,
							    strength_nexttime = util:floor(NowTime/60)
							   },
                                    lib_pet:update_pet(PetNew),
                                    [1, PetAttr, PetPotentialAttr, PetFigure, PetNimbus, PetLevel, PetName, PetAptitude];
                                _  ->
                                    [0, [], [], 0, 0, 0, <<>>, 0]
                            end
                    end
            end
    end.
%% -----------------------------------------------------------------
%% 潜能修行
%% -----------------------------------------------------------------
practice_potential(Status, PetId, Type, IsUseMedicine, GoodsId, GoodsUseNum) -> 
    PlayerId = Status#player_status.id,
    case IsUseMedicine of 
        notmed -> 
            case Type =:= 0 of 
                true -> 
                    [Result, Status1, TypeNumExpArray, TypeExpArray, LvUpList] = practice_potential_once(Status, PetId, IsUseMedicine, GoodsId, GoodsUseNum),
                    Pet = lib_pet:get_pet(PetId),
                    AvgPotential = lib_pet:calc_potential_average_lev(Pet#player_pet.potentials),
        
                    %% 数量
                    _SinglePotentialNum = data_pet_potential:get_single_potential_goods_num(AvgPotential),
                    NthPotential = mod_daily_dict:get_count(PlayerId, 5000006),
                    case NthPotential >= 1 of 
                        true ->
                            SinglePotentialNum = _SinglePotentialNum,
                            BatchPracticeCost = 10*_SinglePotentialNum;
                        false ->
                            SinglePotentialNum = 0,
                            BatchPracticeCost = 9*_SinglePotentialNum
                    end,
                    {ok, BinData} = pt_410:write(41018, [Result, PetId, TypeNumExpArray, TypeExpArray, SinglePotentialNum, BatchPracticeCost, 0, 0, 0, LvUpList]),
                    lib_server_send:send_to_sid(Status1#player_status.sid, BinData),
                    %lib_player:refresh_client(Status#player_status.id, 2),
                    Status2 = Status1,
                    Status2;
                false -> 
                    Pet = lib_pet:get_pet(PetId),
                    AvgPotential = lib_pet:calc_potential_average_lev(Pet#player_pet.potentials),
                    PotentialGoodsType = data_pet:get_pet_config(potential_goods, []),    
                    %% 数量
                    _SinglePotentialNum = data_pet_potential:get_single_potential_goods_num(AvgPotential),
                    AlreadyPractice = mod_daily_dict:get_count(PlayerId, 5000006),
                    case AlreadyPractice >= 1 of 
                        true ->
                            SinglePotentialNum = _SinglePotentialNum,
                            BatchPracticeCost = 10*_SinglePotentialNum;
                        false ->
                            SinglePotentialNum = 0,
                            BatchPracticeCost = 9*_SinglePotentialNum
                    end,
                    GoodsNumOwn = mod_other_call:get_goods_num(Status, PotentialGoodsType, 0),
                    if 
                        GoodsNumOwn < BatchPracticeCost -> 
                            {ok, BinData} = pt_410:write(41018, [4, PetId, [], [], SinglePotentialNum, BatchPracticeCost, 0, 0, 1, []]),
                            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
                            Status;
                        true -> 
                            [Result, Status1, TypeNumExpArray, TypeExpArray, LvUpList] = practice_potential_batch(Status, PetId, BatchPracticeCost),
                            %% 取下次批量所需的修行卷和数量
                            NthPotential = mod_daily_dict:get_count(PlayerId, 5000006),
                            NewPet = lib_pet:get_pet(PetId),
                            NewAvgPotential = lib_pet:calc_potential_average_lev(NewPet#player_pet.potentials),
                            _NewSingleNum = data_pet_potential:get_single_potential_goods_num(NewAvgPotential),
                            case NthPotential >= 1 of
                                true ->
                                    NewSingleNum = _NewSingleNum,
                                    NewBatchPracticeCost = 10*_NewSingleNum;
                                false ->
                                    NewSingleNum = 0,
                                    NewBatchPracticeCost = 9*_NewSingleNum
                            end,
                            {ok, BinData} = pt_410:write(41018, [Result, PetId, TypeNumExpArray, TypeExpArray, NewSingleNum, NewBatchPracticeCost, 0, 0, 1, LvUpList]),
                            lib_server_send:send_to_sid(Status1#player_status.sid, BinData),
                            lib_player:refresh_client(Status1#player_status.id, 2),
                            Status2 = Status1,
                            Status2
                    end
            end;
        MedicineId when is_number(MedicineId) -> 
            [Result, Status1, TypeNumExpArray, TypeExpArray, LvUpList] = practice_potential_once(Status, PetId, IsUseMedicine, GoodsId, GoodsUseNum),
            %% 取下次修行所需要的修行符类型和数量
            Pet = lib_pet:get_pet(PetId),
            AvgPotential = lib_pet:calc_potential_average_lev(Pet#player_pet.potentials),
           _SinglePotentialNum = data_pet_potential:get_single_potential_goods_num(AvgPotential),
            NthPotential = mod_daily_dict:get_count(PlayerId, 5000006),
            case NthPotential >= 1 of 
                true ->
                    SinglePotentialNum = _SinglePotentialNum,
                    BatchPracticeCost = 10*_SinglePotentialNum;
                false ->
                    SinglePotentialNum = 0,
                    BatchPracticeCost = 9*_SinglePotentialNum
            end,
            {_, Exp} = data_pet:get_potential_exp_by_medicine(IsUseMedicine, GoodsUseNum),
            {ok, BinData} = pt_410:write(41018, [Result, PetId, TypeNumExpArray, TypeExpArray, SinglePotentialNum, BatchPracticeCost, 1, Exp, 0, LvUpList]),
            lib_server_send:send_to_sid(Status1#player_status.sid, BinData),
            lib_player:refresh_client(Status1#player_status.id, 2),
            Status1
    end.


%% @param:IsUseMedicine: notmed(atom)非潜能丹成长 | 物品类型id(number)  GoodsId:丹药物品id
practice_potential_once(Status, PetId, IsUseMedicine, GoodsId, GoodsUseNum) -> 
    Pet = lib_pet:get_pet(PetId),
    Go = Status#player_status.goods,
    %% 修行卷类型和数量
    AvgPotential = lib_pet:calc_potential_average_lev(Pet#player_pet.potentials),
    PotentialGoodsType = data_pet:get_pet_config(potential_goods, []),
    GoodsNumOwn = mod_other_call:get_goods_num(Status, PotentialGoodsType, 0),
    NeedGoodsNum = data_pet_potential:get_single_potential_goods_num(AvgPotential),
    IsAllPotentialExceed = lib_pet:check_all_potential_exceed_limit_lv(Pet#player_pet.potentials, Pet#player_pet.level),
    if 
        Pet =:= [] -> [2, Status, [], [], []];
        IsAllPotentialExceed =:= true -> [5, Status, [], [], []];
        Status#player_status.lv < 37 -> [0, Status, [], [], []];
        true -> 
            [PlayerId, FightFlag] = [Pet#player_pet.player_id, Pet#player_pet.fight_flag],
            if 
                PlayerId =/= Status#player_status.id -> [3, Status, [], [], []];
                true -> 
                    PracticeType = 
                    case IsUseMedicine of 
                        notmed -> 
                            PracticeCount = mod_daily_dict:get_count(PlayerId, 5000006),
                            case PracticeCount < 1 of 
                                true -> 
                                    free_practice;
                                false -> 
                                    %% 修行卷类型
                                    if 
                                        GoodsNumOwn < NeedGoodsNum -> 
                                            not_enough_goods;
                                        true -> 
                                            item_practice
                                    end
                            end;
                        _ -> 
                            medicine_practice 
                    end,
                    %OneType = data_pet_potential:get_one_potential_type(PracticeType),%只有4种，类似[12,11,12,11]
                    %OneType = [3],
                    TypeExp = data_pet_potential:get_potentials_type_and_exp2(),
                    %TypeExp = data_pet_potential:get_potential_exp_by_one(OneType),%[{11,{1,5,1}},{12,{2,15,3}},{类型，{个数，经验，倍率}}...]
                    %{TypeId, ExpOnce} = data_pet_potential:get_potentials_one(PracticeType),    
                    %io:format("mod_pet TypeId:~p, ExpOnce:~p~n", [TypeId, ExpOnce]),
                    case PracticeType =/= not_enough_goods of 
                        false -> [4, Status, [], [], []];
                        true -> 
                            [Result, Status2] = case PracticeType =:= medicine_practice of 
                            false -> 
                                if 
                                    PracticeType =:= free_practice -> 
                                        mod_daily_dict:increment(Status#player_status.id, 5000002),
                                        mod_daily_dict:increment(Status#player_status.id, 5000006),
                                        lib_pet:add_potential_exp(Status, Pet, [TypeExp], PracticeType),
                                        [1, Status];
                                    true -> 
                                        %% 扣除物品
                                        lib_player:update_player_info(Status#player_status.id, [{use_goods, {PotentialGoodsType, NeedGoodsNum}}]),
                                        log:log_goods_use(Status#player_status.id, PotentialGoodsType, NeedGoodsNum),
                                        lib_pet:add_potential_exp(Status, Pet, [TypeExp], PracticeType),
                                        [1, Status]
                                end;
                            %% 药品提升
                            true -> 
                                {_Mul, Exp} = data_pet:get_potential_exp_by_medicine(IsUseMedicine, GoodsUseNum),
                                case gen_server:call(Go#status_goods.goods_pid, {'delete_list', [{GoodsId, GoodsUseNum}]}) of 
                                    1 -> 
                                        lib_pet:add_potential_exp(Status, Pet, 12, Exp, PracticeType),
                                        log:log_goods_use(PlayerId, IsUseMedicine, GoodsUseNum),
                                        [1, Status];
                                    GoodsModuleCode -> 
                                        util:errlog("practice potential: Call goods module faild, result code=[~p]", [GoodsModuleCode]),
                                            [0, Status]
                                end 
                            end,
                            %io:format("mod_pet,Result:~p~n", [Result]),
                            case Result =:= 1 of 
                                false -> 
                                    [0, Status, [], [], []];
                                true -> 
                                    NewPet = lib_pet:get_pet(PetId),
                                    case FightFlag =:= 1 of 
                                        true -> 
                                            _Status2 = lib_pet:calc_player_attribute_by_pet_potential_attr(Status2, lib_pet:calc_potential_attr(NewPet));
                                        false -> 
                                            _Status2 = Status2 
                                    end,
                                    pp_login_gift:handle(31204, _Status2, no),
                                    TypeNumExpArray = [{TNEATypeId, TNEANum, TNEAExp} || {TNEATypeId, {TNEANum, TNEAExp, _}} <- [TypeExp]],
                                    %% 旧协议所用
                                    %TypeNumExpArray = [{12, 4, 0}],
                                    TypeExpArray = [{TEATypeId, TEAExp} || {TEATypeId, {_, TEAExp, _}} <- [TypeExp]],
                                    %TypeExpArray = [{TypeId, ExpOnce}],
                                    LvUpList = lib_pet:filter_upgrade_potential(Pet#player_pet.potentials, NewPet#player_pet.potentials),
                                    [Result, _Status2, TypeNumExpArray, TypeExpArray, LvUpList]
                            end
                    end 
            end 
    end.

%% 批量修行
practice_potential_batch(Status, PetId, _PracticeCost) -> 
    Pet = lib_pet:get_pet(PetId),
    IsAllPotentialExceed = lib_pet:check_all_potential_exceed_limit_lv(Pet#player_pet.potentials, Pet#player_pet.level),
    if 
        Pet =:= [] -> [2, Status, [], [], []];
        %% 宠物等级不够
        Status#player_status.lv < 37 -> [0, Status, [], [], []];
        IsAllPotentialExceed =:= true -> [5, Status, [], [], []];
        true -> 
            [PlayerId, FightFlag] = [Pet#player_pet.player_id, Pet#player_pet.fight_flag],
            if 
                PlayerId =/= Status#player_status.id -> [3, Status, [], [], []];
                true -> 
                    PracticeType = item_practice,
                    %% 批量经验
                    TypeExpList = data_pet_potential:get_potentials_batch(10, []),
                    %% 判断修行卷是否足够 
                    AvgPotential = lib_pet:calc_potential_average_lev(Pet#player_pet.potentials),
                    PotentialGoodsType = data_pet:get_pet_config(potential_goods, []),
                    SinglePotentialNum = data_pet_potential:get_single_potential_goods_num(AvgPotential),
                    AlreadyPractice = mod_daily_dict:get_count(PlayerId, 5000006),
                    case AlreadyPractice >= 1 of 
                        true ->
                            BatchPracticeCost = 10*SinglePotentialNum;
                        false ->
                            BatchPracticeCost = 9*SinglePotentialNum
                    end,
                    GoodsNumOwn = mod_other_call:get_goods_num(Status, PotentialGoodsType, 0),
                    case GoodsNumOwn < BatchPracticeCost of 
                        true -> [4, Status, [], [], []];
                        false -> 
                            %% 批量修行,如果升阶了就会停下来
                            UseTypeExpList = lib_pet:add_potential_exp(Status, Pet, TypeExpList, PracticeType),
                            _UseNumTrue = length(UseTypeExpList),
                            UseNumTrue = _UseNumTrue*SinglePotentialNum,
                            case GoodsNumOwn < min(UseNumTrue, BatchPracticeCost) of 
                                true -> [4, Status, [], [], []];
                                false -> 
                                    lib_player:update_player_info(Status#player_status.id, [{use_goods, {PotentialGoodsType, min(UseNumTrue, BatchPracticeCost)}}]),
                                    log:log_goods_use(Status#player_status.id, PotentialGoodsType, min(UseNumTrue, BatchPracticeCost)),
                                    mod_daily_dict:plus_count(Status#player_status.id, 5000006, UseNumTrue),
                                    mod_daily_dict:increment(Status#player_status.id, 5000002),
                                    NewPet = lib_pet:get_pet(PetId),
                                    case FightFlag =:= 1 of 
                                        true -> 
                                            Status2 = lib_pet:calc_player_attribute_by_pet_potential_attr(Status, lib_pet:calc_potential_attr(NewPet));
                                        false -> 
                                            Status2 = Status 
                                    end,
                                    pp_login_gift:handle(31204, Status2, no),
                                    TypeNumExpArray = [{12, 4, 0}],
                                    TypeExpArray = [{TEATypeId, TEAExp} || {TEATypeId, {_, TEAExp, _}} <- UseTypeExpList],
                                    LvUpList = lib_pet:filter_upgrade_potential(Pet#player_pet.potentials, NewPet#player_pet.potentials),
                                    [1, Status2, TypeNumExpArray, TypeExpArray, LvUpList]
                            end 
                    end 
            end 
    end.




%% 融合主副宠潜能等级和经验
merge_potential([], [_H2|_T2], List) ->
    List;
merge_potential([_H1|_T1], [], List) ->
    List;
merge_potential([], [], List) ->
    List;
merge_potential([H1|T1], [H2|T2], List) ->
    Lv1 = H1#pet_potential.lv,
    Lv2 = H2#pet_potential.lv,
    NewLv = case Lv1 < Lv2 of
                true -> Lv2;
                false -> Lv1
            end,
    Exp1 = H1#pet_potential.exp,
    Exp2 = H2#pet_potential.exp,
    NewExp = Exp1+Exp2,
    NewH = H1#pet_potential{ lv = NewLv, exp = NewExp },
    merge_potential(T1, T2, [NewH|List]).

%% 潜能经验融合后处理
%% PetLv:主宠等级
merge_potential2(_, [], List) ->
    List;
merge_potential2(PetLv, [H|T], List) ->
    OldExp = H#pet_potential.exp,
    OldLv = H#pet_potential.lv,
    NewLevelExp = data_pet_potential:get_level_exp(OldLv), %%取得融合后下一等级的潜能经验
    if
        NewLevelExp =< OldExp ->		%%融合后潜能经验达到下一等级
            if
                OldLv+1 > PetLv -> 		%%潜能等级大于宠物等级，跳过
                    merge_potential2(PetLv, T, [H|List]);
                true ->
                    NewExp = OldExp-NewLevelExp,
                    NewH = H#pet_potential{ lv = OldLv+1, exp = NewExp }, %%潜能升级
                    merge_potential2(PetLv, T, [NewH|List])
            end;
        true ->
	    merge_potential2(PetLv, T, [H|List]) 
    end.

%% 宠物砸蛋(暂废)
egg_broken(Status) ->
    PlayerId = Status#player_status.id,
    PlayerLevel = Status#player_status.lv,
    Pet = lib_pet:get_maxinum_growth_pet(PlayerId),
    MaxEggBrokenTime = data_pet:get_pet_config(maxinum_egg_broken_time, []),
    DefaultEggBrokenTime = data_pet:get_pet_config(default_egg_broken_time, []),
    EggBrokenDaily = mod_daily_dict:get_count(PlayerId, 5000004),   %% 宠物砸蛋次数------------5000004
    EggBrokenAgain = mod_daily_dict:get_count(PlayerId, 5000005),   %% 再砸一次
    EggBrokenTime = DefaultEggBrokenTime - EggBrokenDaily + EggBrokenAgain, %% mod_daily_dict:get_count(PlayerId, 5000008), 
    CoinCost = data_pet:get_egg_broken_cost(PlayerLevel),
    if
        Pet =:= [] -> [2, Status, 0, 0]; %% 还没宠物
        EggBrokenTime =< 0 orelse EggBrokenDaily >= MaxEggBrokenTime ->
	    [3, Status, 0, 0]; %% 今天砸蛋次数已满
        Status#player_status.coin + Status#player_status.bcoin < CoinCost -> [4, Status, 0, 0]; %% 铜币不足
        true ->
            Mult = data_pet:get_egg_broken_mult(Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude),
	    %% 5倍砸蛋经验
	    if
	    	Mult =:= 5 ->
	    	    lib_chat:send_TV({all}, 0, 2, ["zadan", 1, PlayerId, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image]);
	    	true ->
	    	    []
	    end,
            AddExp = lib_pet:calc_egg_broken_exp(Mult, PlayerLevel),
            NewStatus = lib_player:add_exp(Status, AddExp),
	    %%砸蛋再砸一次
            FakeAgain = data_pet:get_growth_phase_info(Pet#player_pet.growth, err_broken),
	    AgainCount = mod_daily_dict:get_count(PlayerId, 5000005), %是否已经再砸一次
            if
                FakeAgain =:= 1 andalso AgainCount < 1 ->
		    Again = FakeAgain,
                    mod_daily_dict:set_count(PlayerId, 5000005, 1),  %% 宠物再砸一次次数--------5000005
		    lib_chat:send_TV({all}, 0, 2, ["zadan", 2, PlayerId, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image]);
                true ->
		    Again = 0%% ,
                    %% mod_daily_dict:set_count(PlayerId, 5000008, EggBrokenTime-1)
            end,
            mod_daily_dict:increment(PlayerId, 5000004),
            pp_login_gift:handle(31204, NewStatus, no),
            NewStatus1 = lib_goods_util:cost_money(NewStatus, CoinCost, coin),
	    log:log_consume(break_egg, coin, NewStatus, NewStatus1, "pet break egg"),
            send_log_pet(egg_broken, PlayerId, Pet#player_pet.id, [Pet#player_pet.growth, Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude, CoinCost, Mult, AddExp, Again]),
            [1, NewStatus1, Again, AddExp]
    end.

%% -----------------------------------------------------------------
%% 技能学习
%% -----------------------------------------------------------------
learn_skill(Status, [PetId, GoodsId, GoodsTypeId, GoodsUseNum, LockList, StoneList]) ->
    GoodsPid = Status#player_status.goods#status_goods.goods_pid,
    Pet = lib_pet:get_fighting_pet(Status#player_status.id),
    GoodsType = data_goods_type:get(GoodsTypeId),
    [Result3, Status3, PetId3, OldSkillId3, OldSkillTypeId3, NewSkillId3, NewSkillTypeId3] = 
	if  %% 宠物不存在
	    Pet =:= []  ->
		[2, Status, 0, 0, 0, 0, 0];
	    Pet#player_pet.id =/= PetId ->
		[12, Status, 0, 0, 0, 0, 0];
	    %% %% 该物品不存在
	    %% GoodsInfo =:= [] ->
	    %% 	[4, Status, 0, 0, 0, 0, 0];
	    GoodsType#ets_goods_type.level > Status#player_status.lv ->
		[16, Status, 0, 0, 0, 0, 0];
	    true ->
		%% [GoodsId, GoodsNum, GoodsOwnerId, GoodsTypeId] = [GoodsInfo#goods.id, GoodsInfo#goods.num, GoodsInfo#goods.player_id, GoodsInfo#goods.goods_id],
		PotentialAverageLev = lib_pet:calc_potential_average_lev(Pet#player_pet.potentials),
		SkillCount  = lib_pet:get_pet_skill_count(PetId),
		SkillIdList = lib_pet:get_pet_skill_id(PetId),
		MaxSkillNum = data_pet_skill:get_max_skill_num(PotentialAverageLev, Pet#player_pet.growth),
		BaseSkillId = data_pet_skill:get_skill_series_by_goods_type_id(GoodsTypeId),
		Skill = lib_pet:get_pet_skill_by_type_id(PetId, BaseSkillId),
		case lib_pet:is_learned_pre_skill(Skill, GoodsTypeId) of
		    {false, Reason}->
			[Reason, Status, 0, 0, 0, 0, 0];
		    _ ->
			if
			    %% PlayerId =/= GoodsOwnerId ->
			    %% 	[5, Status, 0, 0, 0, 0, 0];
			    %% GoodsNum < GoodsUseNum ->
			    %% 	[6, Status, 0, 0, 0, 0, 0];
			    SkillCount >= MaxSkillNum ->
				%% 格子已满，只能升级同种技能或替换已有技能
				case lists:member(BaseSkillId, SkillIdList) of
				    true ->
					%% 学习的是已有技能
					case data_pet_skill:get_skill_type_by_goods_type(GoodsTypeId) of
					    2 ->
						ActiveSkill = lists:filter(fun(PetSkill)-> PetSkill#pet_skill.type =:= 2 end, Pet#player_pet.skills),
						ActiveSkillCount = length(ActiveSkill),
						MaxActiveSkillCount = data_pet_skill:get_pet_config(maxinum_active_skill, []),
						ActiveSkill = lib_pet:get_pet_active_skill(Pet#player_pet.id),
						%% 主动类技能最多学习2个     
						case ActiveSkillCount >= MaxActiveSkillCount of
						    true ->
							case lists:keymember(BaseSkillId, 4, ActiveSkill) of
							    false ->
								[11, Status, Pet#player_pet.id, 0, 0, 0, 0];
							    true ->
								replace_skill(Status, Pet, GoodsTypeId, GoodsId, GoodsPid, GoodsUseNum, LockList, StoneList)
							end;
						    false ->
							replace_skill(Status, Pet, GoodsTypeId, GoodsId, GoodsPid, GoodsUseNum, LockList, StoneList)
						end;
					    _ ->
						PassiveSkill = lists:filter(fun(PetSkill)-> PetSkill#pet_skill.type =:= 0 end, Pet#player_pet.skills),
						PassiveSkillCount = length(PassiveSkill),
						MaxPassiveSkillCount = data_pet_skill:get_pet_config(maxinum_passive_skill, []),
						PassiveSkill = lib_pet:get_pet_passive_skill(Pet#player_pet.id),
						%% 被动技能最多学习8个     
						case PassiveSkillCount >= MaxPassiveSkillCount of
						    true ->
							case lists:keymember(BaseSkillId, 4, PassiveSkill) of
							    false ->
								[14, Status, Pet#player_pet.id, 0, 0, 0, 0];
							    true ->
								replace_skill(Status, Pet, GoodsTypeId, GoodsId, GoodsPid, GoodsUseNum, LockList, StoneList)
							end;
						    false ->
							replace_skill(Status, Pet, GoodsTypeId, GoodsId, GoodsPid, GoodsUseNum, LockList, StoneList)
						end
					end;
				    false ->
					%% 学习的不是已有技能
					[7, Status, Pet#player_pet.id, 0, 0, 0, 0] %%宠物技能达到上限
				end;
			    true ->
				case data_pet_skill:get_skill_type_by_goods_type(GoodsTypeId) of
				    2 ->
					case lib_pet:can_learn_second_active_skill(Pet, GoodsTypeId) of
					    true -> replace_skill(Status, Pet, GoodsTypeId, GoodsId, GoodsPid, GoodsUseNum, LockList, StoneList);
					    active_limit -> [11, Status, Pet#player_pet.id, 0, 0, 0, 0];
					    pal_limit -> [13, Status, Pet#player_pet.id, 0, 0, 0, 0]
					end;
				    _ ->
					case lib_pet:can_learn_passive_skill(Pet, GoodsTypeId) of
					    true -> replace_skill(Status, Pet, GoodsTypeId, GoodsId, GoodsPid, GoodsUseNum, LockList, StoneList);
					    passive_limit -> [14, Status, Pet#player_pet.id, 0, 0, 0, 0];
					    pal_limit -> [15, Status, Pet#player_pet.id, 0, 0, 0, 0]
					end
				end
			end
		end
	end,
    {ok, BinData} = pt_410:write(41020, [Result3,PetId3, OldSkillId3, OldSkillTypeId3, NewSkillId3, NewSkillTypeId3]),
    lib_server_send:send_to_sid(Status3#player_status.sid, BinData),
    Status3.

is_replace_skill(SkillCount, GoodsTypeId, Pet, LockList, Status) ->
    TempSkillCount = SkillCount+1,
    ReplaceProbability = data_pet_skill:get_pet_skill_probability(TempSkillCount),
    BaseSkillId = data_pet_skill:get_skill_series_by_goods_type_id(GoodsTypeId),
    %% 验证LockList里的ID是否全部合法
    RealLockList = case LockList =/= [] of
		       true ->
			   case mod_other_call:get_goods_num(Status, 625001, 0) >= length(LockList) of
			       true ->
				   lists:filter(fun(X) ->
							case lists:keyfind(X, 4, Pet#player_pet.skills) of
							    false -> false;
							    LockSkill ->
								LockSkill#pet_skill.level >= 1 %暂时改为1级也能锁
							end
						end, LockList);
			       false ->
				   false
			   end;
		       false ->
			   [BaseSkillId]
		   end,
    case RealLockList of
	false -> false;
	_ ->
	    ReplaceSkillList = lists:filter(fun(X) ->
						    case lists:member(X#pet_skill.type_id, [BaseSkillId | RealLockList]) of
							true -> false;
							false -> true
						    end
					    end, Pet#player_pet.skills),
	    Rand = util:rand(1, 100),
	    if
		Rand =< ReplaceProbability andalso ReplaceSkillList =/= []->
		    {true, ReplaceSkillList};
		true ->
		    {false, ReplaceSkillList}
	    end
    end.

%% @return:[Result, Status, Pet#player_pet.id, NewPetSkillId, GoodsTypeId, NewPetSkillId, GoodsTypeId];
replace_skill(Status, Pet, GoodsTypeId, GoodsId, GoodsPid, GoodsUseNum, LockList, StoneList) ->
    SkillCount  = length(Pet#player_pet.skills),
    case is_replace_skill(SkillCount, GoodsTypeId, Pet, LockList, Status) of
	false -> [0, Status, Pet#player_pet.id, 0, 0, 0, 0];
	{Replace, ReplaceSkillList} ->
	    [PetId, PetLevel] = [Pet#player_pet.id, Pet#player_pet.level],
	    case Replace of
		false ->				%%学习新技能或者升级原有技能
		    case lib_pet:learn_new_skill(Pet, GoodsTypeId, GoodsId, GoodsPid, GoodsUseNum, StoneList) of
			{ok, NewPetSkillId, OldSkillLv, NewSkillLv} ->
			    spawn(fun()->
					  log:log_goods_use(Status#player_status.id, GoodsTypeId, GoodsUseNum),
					  log:log_goods_use(Status#player_status.id, 625001, length(LockList))
				  end),
			    %% 重新计算属性加成
			    [PetSkills, PetSkillAttr] = lib_pet:get_skill_list(PetId, PetLevel),
			    %% 更新宠物缓存
			    NewPetTmp = Pet#player_pet{skills = PetSkills,
						       pet_skill_attr = PetSkillAttr},
			    CombatPower = lib_pet:calc_pet_comat_power_by_pet(Status, NewPetTmp),
			    NewPet = NewPetTmp#player_pet{combat_power = CombatPower},
			    lib_pet:update_pet(NewPet),
			    lib_pet:update_combat_on_db(NewPet#player_pet.combat_power, NewPet#player_pet.id),
			    Status1 = lib_pet:calc_player_attribute(Status, NewPet#player_pet.pet_attr, PetSkillAttr),
			    IsReplace = 0,
			    OldSkillTypeId = lib_pet:make_pet_skill_type_id(GoodsTypeId, OldSkillLv),
			    NewSkillTypeId = lib_pet:make_pet_skill_type_id(GoodsTypeId, NewSkillLv),
			    OldSkillsLog = [lib_pet:make_pet_skill_type_id(OldSkillLog#pet_skill.type_id, OldSkillLog#pet_skill.level) || OldSkillLog <- Pet#player_pet.skills],
			    NewSkillsLog = [lib_pet:make_pet_skill_type_id(NewSkillLog#pet_skill.type_id, NewSkillLog#pet_skill.level) || NewSkillLog <- NewPet#player_pet.skills],
			    send_log_pet(learn_skill, Status#player_status.id, PetId, [IsReplace, GoodsTypeId, util:term_to_string(OldSkillsLog), util:term_to_string(NewSkillsLog), util:term_to_string(LockList), ""]),
			    [1, Status1, Pet#player_pet.id, NewPetSkillId, OldSkillTypeId, NewPetSkillId, NewSkillTypeId];
			trigger_limit ->
			    [9, Status, Pet#player_pet.id, 0, 0, 0, 0];
			active_limit ->
			    [11, Status, Pet#player_pet.id, 0, 0, 0, 0];
			pal_limit ->
			    [13, Status, Pet#player_pet.id, 0, 0, 0, 0];
			lv_limit ->
			    [16, Status, Pet#player_pet.id, 0, 0, 0, 0];
			_ ->
			    %% [0, Status, Pet#player_pet.id, 0, GoodsTypeId, 0, 0]
			    [0, Status, Pet#player_pet.id, 0, 0, 0, 0]
		    end;
		true ->					%%降级其它技能
		    ReplaceCount = length(ReplaceSkillList),
		    Rand = util:rand(1, ReplaceCount),
		    ReadyToReplace = lists:nth(Rand, ReplaceSkillList),
		    Pet2 = case ReadyToReplace#pet_skill.level =< 1 of
			       true ->
				   [_Result, NewPetSkills, NewPetAttr, NewPetSkillAttr, _ForgetSkillId] = mod_pet:forget_skill2(Status, [PetId, ReadyToReplace#pet_skill.type_id]),
				   Pet1 = Pet#player_pet{skills = NewPetSkills,
							 pet_skill_attr = NewPetSkillAttr,
							 pet_attr = NewPetAttr
							},
				   lib_pet:update_pet(Pet1),
				   Pet1;
			       false ->
				   PetSkills = Pet#player_pet.skills,
				   UpgradeSkill = ReadyToReplace#pet_skill{level = ReadyToReplace#pet_skill.level - 1},
				   NewPetSkills = lists:keyreplace(UpgradeSkill#pet_skill.type_id, 4, PetSkills, UpgradeSkill),
				   Pet1 = Pet#player_pet{ skills = NewPetSkills },
				   lib_pet:update_pet(Pet1),
				   SQL = io_lib:format(<<"update pet_skill set level=~p where pet_id=~p and type_id=~p">>, [UpgradeSkill#pet_skill.level, PetId, UpgradeSkill#pet_skill.type_id]),
				   db:execute(SQL),
				   OldSkillsLog = [lib_pet:make_pet_skill_type_id(OldSkillLog#pet_skill.type_id, OldSkillLog#pet_skill.level) || OldSkillLog <- Pet#player_pet.skills],
				   NewSkillsLog = [lib_pet:make_pet_skill_type_id(NewSkillLog#pet_skill.type_id, NewSkillLog#pet_skill.level) || NewSkillLog <- Pet1#player_pet.skills],
				   send_log_pet(forget_skill, Status#player_status.id, PetId, [1, GoodsTypeId, util:term_to_string(OldSkillsLog), util:term_to_string(NewSkillsLog), util:term_to_string(LockList), "degrade"]),
				   Pet1
			   end,
		    case lib_pet:learn_new_skill(Pet2, GoodsTypeId, GoodsId, GoodsPid, GoodsUseNum, StoneList) of
			{ok, NewPetSkillId, _OldSkillLv, _NewSkillLv} ->
			    spawn(fun()->
					  log:log_goods_use(Status#player_status.id, GoodsTypeId, GoodsUseNum),
					  log:log_goods_use(Status#player_status.id, 625001, length(LockList))
				  end),
			    %% 重新计算属性加成
			    [FinalPetSkills, PetSkillAttr] = lib_pet:get_skill_list(PetId, PetLevel),
			    %% 更新宠物缓存
			    NewPetTmp = Pet2#player_pet{skills = FinalPetSkills,
							pet_skill_attr = PetSkillAttr},
			    CombatPower = lib_pet:calc_pet_comat_power_by_pet(Status, NewPetTmp),
			    NewPet = NewPetTmp#player_pet{combat_power = CombatPower},
			    lib_pet:update_pet(NewPet),
			    lib_pet:update_combat_on_db(NewPet#player_pet.combat_power, NewPet#player_pet.id),
			    Status1 = lib_pet:calc_player_attribute(Status, NewPet#player_pet.pet_attr, PetSkillAttr),
			    IsReplace = 1,
			    OldSkillTypeId = lib_pet:make_pet_skill_type_id(ReadyToReplace#pet_skill.type_id, ReadyToReplace#pet_skill.level),
			    NewSkillTypeId = GoodsTypeId,
			    OldLog = [lib_pet:make_pet_skill_type_id(OldSkillLog#pet_skill.type_id, OldSkillLog#pet_skill.level) || OldSkillLog <- Pet2#player_pet.skills],
			    NewLog = [lib_pet:make_pet_skill_type_id(NewSkillLog#pet_skill.type_id, NewSkillLog#pet_skill.level) || NewSkillLog <- NewPet#player_pet.skills],
			    send_log_pet(learn_skill, Status1#player_status.id, PetId, [IsReplace, GoodsTypeId, util:term_to_string(OldLog), util:term_to_string(NewLog), util:term_to_string(LockList), ""]),
			    [1, Status1, Pet#player_pet.id, ReadyToReplace#pet_skill.id, OldSkillTypeId, NewPetSkillId, NewSkillTypeId];
			trigger_limit ->
			    [9, Status, Pet#player_pet.id, 0, 0, 0, 0];
			active_limit ->
			    [11, Status, Pet#player_pet.id, 0, 0, 0, 0];
			pal_limit ->
			    [13, Status, Pet#player_pet.id, 0, 0, 0, 0];
			lv_limit ->
			    [16, Status, Pet#player_pet.id, 0, 0, 0, 0];
			_ ->
			    [0, Status, Pet#player_pet.id, 0, 0, 0, 0]
		    end
	    end
    end.

%% -----------------------------------------------------------------
%% 技能遗忘,替换技能时调用
%% -----------------------------------------------------------------
forget_skill2(Status, [PetId, SkillTypeId]) ->
    Pet = lib_pet:get_pet(PetId),
    if  %% 宠物不存在
        Pet =:= []  -> [2, [], [], [], 0];
        true ->
            [PlayerId, PetLevel, PetAttr] =
                [Pet#player_pet.player_id, Pet#player_pet.level, Pet#player_pet.pet_attr],
            if  %% 宠物不归你所有
                PlayerId /= Status#player_status.id -> [3, [], [], [], 0];
                true ->
                    Skill = lib_pet:get_pet_skill_by_type_id(PetId, SkillTypeId),
                    case Skill of
			%% 被遗忘的技能不存在
                        false ->
                            [4, [], [], [], 0];
                        _ ->
                            case lib_pet:forget_skill(PetId, SkillTypeId) of
                                ok ->
				    %% 更新缓存
                                    lib_pet:delete_pet_skill_by_pet_id_type_id(PetId, SkillTypeId),
                                    [NewPetSkills, NewPetSkillAttr] = lib_pet:get_skill_list(PetId, PetLevel),
				    PetTmp = lib_pet:get_pet(PetId),
				    NewPetTmp = PetTmp#player_pet{pet_skill_attr = NewPetSkillAttr},
				    CombatPower = lib_pet:calc_pet_comat_power_by_pet(Status, NewPetTmp),
				    NewPet = NewPetTmp#player_pet{combat_power = CombatPower},
				    lib_pet:update_pet(NewPet),
				    lib_pet:update_combat_on_db(NewPet#player_pet.combat_power, NewPet#player_pet.id),
				    ForgetSkillId = lib_pet:make_pet_skill_type_id(Skill#pet_skill.type_id, Skill#pet_skill.level),
				    OldSkillsLog = [lib_pet:make_pet_skill_type_id(OldSkillLog#pet_skill.type_id, OldSkillLog#pet_skill.level) || OldSkillLog <- Pet#player_pet.skills],
				    NewSkillsLog = [lib_pet:make_pet_skill_type_id(NewSkillLog#pet_skill.type_id, NewSkillLog#pet_skill.level) || NewSkillLog <- NewPet#player_pet.skills],
				    send_log_pet(forget_skill, Status#player_status.id, PetId, [0, 0, util:term_to_string(OldSkillsLog), util:term_to_string(NewSkillsLog), util:term_to_string([]), "forget"]),
                                    [1, NewPetSkills, PetAttr, NewPetSkillAttr, ForgetSkillId];
                                _   ->
                                    [0, [], [], [], 0]
                            end
                    end
            end
    end.



%% -----------------------------------------------------------------
%% 激活新形象
%% @return [Result, List]
%% List = [{figure_id,change_flag,activate_flag,LeftTime}]
%% -----------------------------------------------------------------
activate_figure(Status, [GoodsInfo, GoodsUseNum]) ->
    PlayerId = Status#player_status.id,
    GoodsPid = Status#player_status.goods#status_goods.goods_pid,
    if
	GoodsInfo =:= [] ->
	    [3,[],Status];
	true ->
	    [GoodsId, GoodsNum, GoodsOwnerId, GoodsTypeId] = [GoodsInfo#goods.id, GoodsInfo#goods.num, GoodsInfo#goods.player_id, GoodsInfo#goods.goods_id],
	    if   
		PlayerId =/= GoodsOwnerId ->
		    [4,[],Status];	%物品不是你的
		GoodsNum < GoodsUseNum ->
		    [5,[],Status];	%数量不足
		true ->
		    FigureGoods = data_pet_figure:get(GoodsTypeId),
		    FigureId = FigureGoods#base_goods_figure.figure_id,
		    LastTime = FigureGoods#base_goods_figure.last_time * 3600, %Figure#base_goods_figure.last_time单位为小时,为0即为永久幻化
		    ActivateFlag = case LastTime of
				       0 -> 1;
				       _ -> 2
				   end,
		    ActivateValue = FigureGoods#base_goods_figure.activate_value,
		    ActivateTime = util:unixtime(),
		    case lib_pet:activate_new_figure(Status, GoodsTypeId, FigureId, ActivateFlag, ActivateValue, ActivateTime, LastTime, GoodsId, GoodsPid, GoodsUseNum) of
			{ok, NewStatus} ->
			    ActivateFigureList = NewStatus#player_status.unreal_figure_activate,
			    SendList = lists:map(fun(Record) ->
							LeftTime = util:unixtime() - (Record#pet_activate_figure.activate_time + Record#pet_activate_figure.last_time),
							{Record#pet_activate_figure.type_id,
							 lib_pet:make_pet_figure(Record#pet_activate_figure.figure_id, 0),
							 Record#pet_activate_figure.change_flag,	
							 Record#pet_activate_figure.activate_flag,
							 LeftTime}
						end, ActivateFigureList),
			    [1,SendList,NewStatus];
			_  ->
			    [0,[],Status]
		    end
	    end
    end.

change_figure(PetId, FigureId, Status) ->
    case lib_pet:is_exists_figure_change_pet(Status#player_status.id) of
	false ->
	    Pet = lib_pet:get_fighting_pet(Status#player_status.id),
	    if
		Pet =:= [] ->
		    [2, Status];
		Pet#player_pet.id =/= PetId ->
		    [2, Status];
		true ->
		    %% 验证形象是否激活
		    ActivateFigures = Status#player_status.unreal_figure_activate,
		    case ActivateFigures of
			[] ->
			    %% 没有激活过任何形象
			    [0, Status];
			_ ->
			    case lib_pet:get_figure_activate(ActivateFigures, FigureId) of
				false ->
				    [0, Status];
				ActivateFigure ->
				    Flag = ActivateFigure#pet_activate_figure.activate_flag,
				    %% 验证是否已经过期
				    case Flag of
					0 -> [0, Status];
					1 ->
					    %% 永久激活，改变形象
					    {SubFigure0, _Nimbus} = data_pet:get_growth_phase_info(Pet#player_pet.growth, figure),
					    Figure = lib_pet:make_pet_figure(FigureId div 100, SubFigure0),
					    NewActivateFigures = lib_pet:replace_using_figure(ActivateFigures, ActivateFigure),
					    NewPetTmp = Pet#player_pet{
							  change_flag = 1,
							  figure = Figure,
							  figure_type = 0 %永久幻化
							 },
					    lib_pet:update_pet(NewPetTmp),
					    Status1 = Status#player_status{unreal_figure_activate = NewActivateFigures},
					    SQL1 = io_lib:format(<<"update pet set new_figure=~p, change_flag=~p, figure_type=~p where id=~p">>,[Figure, 1, 0, PetId]),
					    db:execute(SQL1),
					    %% 更新宠物缓存
					    CombatPower = lib_pet:calc_pet_comat_power_by_pet(Status1, NewPetTmp),
					    NewPet = NewPetTmp#player_pet{combat_power = CombatPower},
					    lib_pet:update_pet(NewPet),
					    lib_pet:update_combat_on_db(NewPet#player_pet.combat_power, NewPet#player_pet.id),
					    %% 发送宠物形象改变通知到场景
					    pp_pet:handle(41001, Status1, [PetId]),
					    FightingPet = lib_pet:get_fighting_pet(Status1#player_status.id),
					    case FightingPet#player_pet.id =:= PetId of
						true ->
						    %% 出战宠物，改变属性
						    PetFigureAttr = lib_pet:filter_figure_attr(ActivateFigures),
						    _Status1 = Status1#player_status{pet=Status1#player_status.pet#status_pet{pet_figure_attribute=PetFigureAttr}},
						    %% 重新计算属性加成
						    Status2 = lib_pet:calc_player_attribute(_Status1),
						    NewStatus = Status2,
						    lib_pet:send_figure_change_notify(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, NewPet#player_pet.figure, NewPet#player_pet.nimbus, NewPet#player_pet.level, NewPet#player_pet.name, NewPet#player_pet.base_aptitude+NewPet#player_pet.extra_aptitude);
						false ->
						    NewStatus = Status1
					    end,
					    [1, NewStatus];
					2 ->
					    [0, Status]
					    %% %% 限时激活，检查是否过期
					    %% Now = util:unixtime(),
					    %% case Now > ActivateFigure#pet_activate_figure.activate_time + ActivateFigure#pet_activate_figure.last_time of
					    %% 	true ->
					    %% 	    %% 限时激活已经过期
					    %% 	    NewActivateFigures = lists:keydelete(ActivateFigure#pet_activate_figure.id, 2, ActivateFigures),
					    %% 	    NewPet = Pet#player_pet{
					    %% 		       change_flag = 0,
					    %% 		       figure = Pet#player_pet.origin_figure,
					    %% 		       figure_type = 1 %限时幻化
					    %% 		      },
					    %% 	    lib_pet:update_pet(NewPet),
					    %% 	    Status1 = Status#player_status{unreal_figure_activate = NewActivateFigures},
					    %% 	    SQL = io_lib:format(<<"delete from pet_figure_change where id=~p">>,[ActivateFigure#pet_activate_figure.id]),
					    %% 	    db:execute(SQL),
					    %% 	    SQL1 = io_lib:format(<<"update pet set new_figure=~p, change_flag=~p, figure_type=~p where id=~p">>,[Pet#player_pet.origin_figure, 0, 1, PetId]),
					    %% 	    db:execute(SQL1),
					    %% 	    %% 发送宠物形象改变通知到场景
					    %% 	    pp_pet:handle(41001, Status1, [PetId]),
					    %% 	    FightingPet = lib_pet:get_fighting_pet(Status1#player_status.id),
					    %% 	    case FightingPet#player_pet.id =:= PetId of
					    %% 		true ->
					    %% 		    %% 出战宠物，改变属性
					    %% 		    _Status1 = Status1#player_status{pet=Status1#player_status.pet#status_pet{pet_figure_attribute=lib_pet:get_zero_pet_figure_attribute()}},
					    %% 		    %% 重新计算属性加成
					    %% 		    Status2 = lib_pet:calc_player_attribute(_Status1),
					    %% 		    NewStatus = Status2,
					    %% 		    lib_pet:send_figure_change_notify(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, NewStatus#player_status.id,  NewStatus#player_status.platform, NewStatus#player_status.server_num, NewPet#player_pet.figure, NewPet#player_pet.nimbus, NewPet#player_pet.level, NewPet#player_pet.name, NewPet#player_pet.aptitude);
					    %% 		false ->
					    %% 		    NewStatus = Status1
					    %% 	    end,
					    %% 	    [0, NewStatus];
					    %% 	false ->
					    %% 	    %% 限时激活未过期
					    %% 	    {SubFigure0, _Nimbus} = data_pet:get_growth_phase_info(Pet#player_pet.growth, figure),
					    %% 	    Figure = lib_pet:make_pet_figure(FigureId div 100, SubFigure0),
					    %% 	    NewActivateFigures = lib_pet:replace_using_figure(ActivateFigures, ActivateFigure),
					    %% 	    ExpireTime = ActivateFigure#pet_activate_figure.activate_time + ActivateFigure#pet_activate_figure.last_time,
					    %% 	    NewPet = Pet#player_pet{
					    %% 		       change_flag = 1,
					    %% 		       figure = Figure,
					    %% 		       figure_expire_time = ExpireTime,
					    %% 		       figure_type = 1 %限时幻化
					    %% 		      },
					    %% 	    lib_pet:update_pet(NewPet),
					    %% 	    Status1 = Status#player_status{unreal_figure_activate = NewActivateFigures},
					    %% 	    SQL1 = io_lib:format(<<"update pet set new_figure=~p, change_flag=~p, figure_type=~p, figure_expire_time=~p where id=~p">>,[Figure, 1, 1, ExpireTime, PetId]),
					    %% 	    db:execute(SQL1),
					    %% 	    %% 发送宠物形象改变通知到场景
					    %% 	    pp_pet:handle(41001, Status1, [PetId]),
					    %% 	    FightingPet = lib_pet:get_fighting_pet(Status1#player_status.id),
					    %% 	    case FightingPet#player_pet.id =:= PetId of
					    %% 		true ->
					    %% 		    %% 出战宠物，改变属性
					    %% 		    PetFigureAttr = lib_pet:filter_figure_attr(ActivateFigures),
					    %% 		    _Status1 = Status1#player_status{pet=Status1#player_status.pet#status_pet{pet_figure_attribute=PetFigureAttr}},
					    %% 		    %% 重新计算属性加成
					    %% 		    Status2 = lib_pet:calc_player_attribute(_Status1),
					    %% 		    NewStatus = Status2,
					    %% 		    lib_pet:send_figure_change_notify(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, NewPet#player_pet.figure, NewPet#player_pet.nimbus, NewPet#player_pet.level, NewPet#player_pet.name, NewPet#player_pet.aptitude);
					    %% 		false ->
					    %% 		    NewStatus = Status1
					    %% 	    end,
					    %% 	    [1, NewStatus]
					    %% end
				    end
			    end
		    end
	    end;
	true ->
	    [3, Status]
    end.


cancel_change_figure(PetId, FigureId, Status) ->
    Pet = lib_pet:get_pet(PetId),
    if
	Pet =:= [] ->
	    [0, Status];
	true ->
	    %% 验证形象是否激活
	    ActivateFigures = Status#player_status.unreal_figure_activate,
	    case ActivateFigures of
		[] ->
		    %% 没有激活过任何形象
		    [0, Status];
		_ ->
		    case lib_pet:get_figure_activate(ActivateFigures, FigureId) of
			false ->
			    [0, Status];
			ActivateFigure ->
			    NewActivateFigure = ActivateFigure#pet_activate_figure{change_flag = 0},
			    NewActivateFigures = lists:keyreplace(NewActivateFigure#pet_activate_figure.id, 2, ActivateFigures, NewActivateFigure),
			    {SubFigure0, _Nimbus} = data_pet:get_growth_phase_info(Pet#player_pet.growth, figure),
			    OriginFigure = lib_pet:make_pet_figure(Pet#player_pet.origin_figure div 100, SubFigure0),
			    NewPetTmp = Pet#player_pet{
				       change_flag = 0,
				       figure = OriginFigure,
				       figure_type = 0
				      },
			    lib_pet:update_pet(NewPetTmp),
			    Status1 = Status#player_status{unreal_figure_activate = NewActivateFigures},
			    F = fun() ->
					SQL = io_lib:format(<<"update pet_figure_change set change_flag=~p where id=~p">>,[0,NewActivateFigure#pet_activate_figure.id]),
					db:execute(SQL),
					SQL1 = io_lib:format(<<"update pet set new_figure=~p, change_flag=~p, figure_type=~p where id=~p">>,[Pet#player_pet.origin_figure, 0, 1, PetId]),
					db:execute(SQL1)
				end,
			    db:transaction(F),
			    %% 更新宠物缓存
			    CombatPower = lib_pet:calc_pet_comat_power_by_pet(Status1, NewPetTmp),
			    NewPet = NewPetTmp#player_pet{combat_power = CombatPower},
			    lib_pet:update_pet(NewPet),
			    lib_pet:update_combat_on_db(NewPet#player_pet.combat_power, NewPet#player_pet.id),
			    %% 发送宠物形象改变通知到场景
			    pp_pet:handle(41001, Status1, [PetId]),
			    case lib_pet:get_fighting_pet(Status1#player_status.id) of
				[] -> NewStatus = Status1;
				FightingPet ->
				    case FightingPet#player_pet.id =:= PetId of
					true ->
					    %% 重新计算属性加成
					    Status2 = lib_pet:calc_player_attribute(Status1),
					    NewStatus = Status2,
					    lib_pet:send_figure_change_notify(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, NewPet#player_pet.figure, NewPet#player_pet.nimbus, NewPet#player_pet.level, NewPet#player_pet.name, NewPet#player_pet.base_aptitude+NewPet#player_pet.extra_aptitude);
					false ->
					    NewStatus = Status1
				    end
			    end,
			    [1, NewStatus]
		    end
	    end
    end.
