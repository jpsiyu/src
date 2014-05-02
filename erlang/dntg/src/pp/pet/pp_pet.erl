%%%--------------------------------------
%%% @Module  : pp_pet
%%% @Author  : zhenghehe
%%% @Created : 2010.07.03
%%% @Description: 宠物
%%%--------------------------------------
-module(pp_pet).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("pet.hrl").
-include("scene.hrl").
-include("goods.hrl").
%%=========================================================================
%% 接口函数
%%=========================================================================

%% -----------------------------------------------------------------
%% 获取宠物信息
%% -----------------------------------------------------------------
handle(41001, Status, [PetId]) ->
    [Result, Data] = mod_pet:get_pet_info(Status, [PetId]),   
    {ok, BinData} = pt_410:write(41001, [Result,Data]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    handle(41042, Status, []),
    ok;

%% -----------------------------------------------------------------
%% 获取宠物列表
%% -----------------------------------------------------------------
handle(41002, Status, [PlayerId]) ->
    [Result, PetMaxNum, RecordNum, Data] = mod_pet:get_pet_list(Status, [PlayerId]),
    {ok, BinData} = pt_410:write(41002, [Result, PlayerId, PetMaxNum, RecordNum, Data]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    handle(41042, Status, []),
	%% lib_task:event(pet_grow_up, do, Status#player_status.id), %% 打开宠物面板即完成宠物相关引导任务
    ok;


%% -----------------------------------------------------------------
%% 宠物孵化
%% -----------------------------------------------------------------
handle(41003, Status, [GoodsInfo, GoodsUseNum]) ->
    [Result, PetId, PetName, GoodsTypeId] = mod_pet:incubate_pet(Status, [GoodsInfo, GoodsUseNum]),
    if (Result == 1) ->
            lib_task:event(Status#player_status.tid, use_equip, {GoodsTypeId}, Status#player_status.id);
        true ->
            void
    end,
    {ok, BinData} = pt_410:write(41003, [Result, PetId, PetName, GoodsTypeId]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    if 
        (Result == 1) ->
            case lib_pet:get_pet_count(Status#player_status.id) =:= 1 andalso Status#player_status.lv >= 34 of
                true ->
                    case handle(41006, Status, [PetId]) of
                        {ok, pet_addition, Status2} ->
                            Status2;
                        _ ->
                            Status
                    end;
                false ->
                    Status
            end;
        true ->
            Status
    end;

%% -----------------------------------------------------------------
%% 宠物放生
%% -----------------------------------------------------------------
handle(41004, Status, [PetId]) ->
    case lib_secondary_password:is_pass(Status) of
        false -> 
            skip;
        true ->
	    Result = mod_pet:free_pet(Status, [PetId]),
	    FigureList = Status#player_status.unreal_figure_activate,
	    NewFigureList = lib_pet:reset_figure_using_flag(FigureList),
	    Status1 = Status#player_status{unreal_figure_activate=NewFigureList},
	    if  Result == 6 ->
		    ok;
		true ->
		    {ok, BinData} = pt_410:write(41004, [Result, PetId]),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
		    ok
	    end,
	    {ok, pet_addition, Status1}
    end;
    
%% -----------------------------------------------------------------
%% 宠物改名
%% -----------------------------------------------------------------
handle(41005, Status, [PetId, PetName]) ->
    [Result, PetFigure, PetNimbus, PetLevel, PetAptitude, PetRenameNum, PetRenameLastTime] = mod_pet:rename_pet(Status, [PetId, PetName]),
    Pt = Status#player_status.pet,
    if  Result == 1 ->
            if  % 出战宠物
                Pt#status_pet.pet_id == PetId ->
                    % 发送宠物形象改变通知到场景
                    lib_pet:send_figure_change_notify(Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y, Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, PetFigure, PetNimbus, PetLevel,  util:make_sure_binary(PetName), PetAptitude);
                true ->
                    void
            end,
            % 发送回应
            {ok, BinData} = pt_410:write(41005, [Result, PetId, util:make_sure_binary(PetName)]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData),            
            % 更新状态
            Status1 = Status#player_status{pet=Pt#status_pet{pet_name  = util:make_sure_list(PetName),
                                           pet_rename_num = PetRenameNum,
                                           pet_rename_lasttime = PetRenameLastTime}},
            % 返回新状态
            {ok, Status1};
        true ->
            % 发送回应
            {ok, BinData} = pt_410:write(41005, [Result, PetId, util:make_sure_binary(PetName)]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
            ok
    end;
    

%% -----------------------------------------------------------------
%% 宠物出战
%% -----------------------------------------------------------------
handle(41006, Status, [PetId]) ->
 %    case Status#player_status.scene =:= 250 orelse Status#player_status.scene =:= 251 orelse Status#player_status.scene =:= 252 orelse lists:member(Status#player_status.scene, data_kf_3v3:get_config(scene_pk_ids)) of
	% true ->
	%     {ok, BinData} = pt_410:write(41006, [0, PetId]),
 %            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
	%     ok;
	% false ->
	    [Result, PetAttr, _PetPotentialAttr, PetFigure, PetNimbus, PetLevel, PetName, BasePetAptitude, ExtraPetAptitude] = mod_pet:fighting_pet(Status, [PetId]),
        PetAptitude = BasePetAptitude+ExtraPetAptitude,
	    Pt = Status#player_status.pet,
	    if  Result == 1 ->          
		    %% 发送宠物形象改变通知到场景
		    lib_pet:send_figure_change_notify(Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y, Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, PetFigure, PetNimbus, PetLevel, PetName, PetAptitude),
		    NewPet = lib_pet:get_pet(PetId),
		    PetPotentialAttr = lib_pet:calc_potential_attr(NewPet),
		    PetSkillAttr = lib_pet:calc_pet_skill_attribute(PetLevel, NewPet#player_pet.skills),
		    PetFigureAttr = lib_pet:filter_figure_attr(Status#player_status.unreal_figure_activate),
            PetAptitudeAttr = data_pet:calc_pet_aptitude_attr(BasePetAptitude),
		    %% 更新出战宠物信息
		    Status1 = Status#player_status{pet=Pt#status_pet{pet_id       = PetId,
								     pet_figure   = PetFigure,
								     pet_nimbus   = PetNimbus,
								     pet_level    = PetLevel,
								     pet_name     = util:make_sure_list(PetName),
								     pet_attribute = PetAttr,
								     pet_potential_attribute = PetPotentialAttr,
								     pet_skill_attribute = PetSkillAttr,
								     pet_figure_attribute=PetFigureAttr,
                                     pet_aptitude_attribute = PetAptitudeAttr,
								     pet_aptitude = PetAptitude
								    }},
		    %% 角色属性加点
		    Status2 = lib_pet:calc_player_attribute(Status1),
		    lib_player:send_attribute_change_notify(Status2, 1),
		    %% 发送回应
		    {ok, BinData} = pt_410:write(41006, [Result, PetId]),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
		    %% 宠物主动技能
		    Status3 = lib_pet:add_active_skill(Status2),
		    %% 返回新状态
		    {ok, pet_addition, Status3};
		true ->
		    {ok, BinData} = pt_410:write(41006, [Result, PetId]),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
		    ok
	    end;
    % end;


%% -----------------------------------------------------------------
%% 宠物休息
%% -----------------------------------------------------------------
handle(41007, Status, [PetId]) ->
    %% case Status#player_status.scene =:= 250 orelse Status#player_status.scene =:= 251 orelse Status#player_status.scene =:= 252 orelse Status#player_status.scene =:= 253 of
    %% 	true ->
    %% 	    {ok, BinData} = pt_410:write(41007, [0, PetId]),
    %%         lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    %% 	    ok;
    %% 	false ->
    [Result, _PetAttr, _PetPotentialAttr] = mod_pet:rest_pet(Status, [PetId]),
    Pt = Status#player_status.pet,
    if  Result =:= 1 ->
	    %% 发送回应
	    {ok, BinData} = pt_410:write(41007, [Result, PetId]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
	    %% 发送宠物形象改变通知到场景
	    lib_pet:send_figure_change_notify(Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y, Status#player_status.id, "", 0, 0, 0, 0, <<>>, 0),
	    %% 更新出战宠物信息
	    Status1 = Status#player_status{pet=Pt#status_pet{pet_id       = 0,
							     pet_figure   = 0,
							     pet_nimbus   = 0,
							     pet_level    = 0,
							     pet_name     = util:make_sure_list(<<>>),
							     pet_attribute = lib_pet:get_zero_pet_attribute(),
							     pet_potential_attribute = lib_pet:get_zero_pet_potential_attribute(),
							     pet_skill_attribute = lib_pet:get_zero_pet_skill_attribute(),
							     pet_figure_attribute = lib_pet:get_zero_pet_figure_attribute(),
                                 pet_aptitude_attribute = lib_pet:get_zero_pet_aptitude_attribute(),
							     pet_aptitude = 0}},
	    %% 角色属性减点
	    Status2 = lib_pet:calc_player_attribute(Status1),
	    lib_player:send_attribute_change_notify(Status2, 1),
	    %% 宠物去掉主动技能
	    Status3 = lib_skill:del_all_pet_skill(Status2),
	    %% 返回新状态
	    {ok, pet_addition, Status3};
	true ->
	    {ok, BinData} = pt_410:write(41007, [Result, PetId]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
	    ok
    %% end
    end;

%% -----------------------------------------------------------------
%% 升级经验同步
%% -----------------------------------------------------------------
handle(41009, Status, []) ->
    [Result, NewStatus, PetId, PetLevel, UpgradeExp] = mod_pet:upgrade_exp_sync(Status, []),
    if  % 同步成功且有宠物升级经验变化
        ((Result == 1) and (PetId == 0)) ->
            ok;
        true ->
            {ok, BinData} = pt_410:write(41009, [Result, PetId, PetLevel, UpgradeExp]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
            {ok, NewStatus}
    end;

%% -----------------------------------------------------------------
%% 宠物喂养
%% -----------------------------------------------------------------
handle(41010, Status, [PetId, GoodsId, GoodsUseNum]) ->
    [Result, Strength] = mod_pet:feed_pet(Status, [PetId, GoodsId, GoodsUseNum]),
    {ok, BinData} = pt_410:write(41010, [Result, PetId, Strength]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 体力值同步
%% -----------------------------------------------------------------
handle(41011, Status, []) ->
    [Result, PetId, PetStrength, PetAttrChangeFlag] = mod_pet:strength_sync(Status, []),
    if  %% 同步成功且没有宠物属性受变化
        ((Result =:= 1) and (PetId =:= 0)) ->
            ok;
        %% 同步成功且有宠物属性受变化
        ((Result =:= 1) and (PetId =/= 0) and (PetAttrChangeFlag =:= 1)) ->
            %% 发送回应
            {ok, BinData} = pt_410:write(41011, [Result, PetId, PetStrength, PetAttrChangeFlag]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
            %% 收回宠物
            if  PetStrength =< 0 ->
                    handle(41007, Status, [PetId]);
		true ->
                    void
            end;
        true ->
            {ok, BinData} = pt_410:write(41011, [Result, PetId, PetStrength, PetAttrChangeFlag]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
            ok
    end;

%% -----------------------------------------------------------------
%% 宠物继承
%% -----------------------------------------------------------------
handle(41012, Status, [PetId1, PetId2, Figure]) ->
    [Result, NewStatus] = mod_pet:derive_pet(Status, [PetId1,PetId2,Figure]),
    {ok, BinData} = pt_410:write(41012, [Result, PetId1, PetId2]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    case Result =:= 1 of
        true -> 
            CostPS = lib_goods_util:cost_money(NewStatus, data_pet:get_pet_config(derive_cost, []), coin),
            Text = data_pet_text:get_msg(6),
            log:log_consume(derive_pet, coin, Status, CostPS, Text),
            lib_player:refresh_client(Status#player_status.id, 2),
			lib_task:event(pet_derive, do, NewStatus#player_status.id),
            handle(41001, CostPS, [PetId1]),
            {ok, CostPS};
        false -> {ok ,NewStatus}
    end;

%% -----------------------------------------------------------------
%% 购买宠物栏
%% -----------------------------------------------------------------
handle(41013, Status, []) ->
    [Result, PetMaxNum, PetCapacity, GoldLeft] = mod_pet:buy_pet_capacity(Status, []),
    Pt = Status#player_status.pet,
    if  % 成功
        Result == 1 ->
            {ok, BinData} = pt_410:write(41013, [Result, PetMaxNum]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
            % 更新状态
            Status1 = Status#player_status{gold  = GoldLeft,
                                          pet=Pt#status_pet{pet_capacity = PetCapacity}},
            % 记录消费日志
            log:log_consume(pet_capacity, gold, Status, Status1, ""),
            % 刷新背包
            lib_player:refresh_client(Status#player_status.id, 2),
            {ok, Status1};
         true ->
            {ok, BinData} = pt_410:write(41013, [Result, PetMaxNum]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
             ok
    end;

%% 封测版--暂时屏蔽
%% -----------------------------------------------------------------
%% 属性还童
%% -----------------------------------------------------------------
handle(41014, _Status, [_PetId, _GoodsId, _GoodsUseNum]) ->
%%     [Result, NewForza, NewWit, NewAgile, NewThew] = mod_pet:restore_attr(Status, [PetId, GoodsId, GoodsUseNum]),
%%     {ok, BinData} = pt_410:write(41014, [Result, PetId, NewForza, NewWit, NewAgile, NewThew]),
%%     lib_server_send:send_to_sid(Status#player_status.sid, BinData),
%%     CostPS = lib_goods_util:cost_money(Status, 10000, coin),
%%     Text = data_pet_text:get_msg(10),
%%     log:log_consume(restore_attr, coin, Status, CostPS, Text),
%%     lib_player:refresh_client(Status#player_status.id, 2),
%%     {ok, CostPS};
    skip;

%% 封测版--暂时屏蔽
%% -----------------------------------------------------------------
%% 宠物还童替换
%% -----------------------------------------------------------------
handle(41022, _Status, [_PetId]) ->                    
%%     [Result, RoleAttrChangeFlag, NewPetAttr] = mod_pet:replace_attr(Status, [PetId]),
%%     if
%%         Result =:= 1 ->
%%             {ok, BinData} = pt_410:write(41022, [Result, PetId]),
%%             lib_server_send:send_to_sid(Status#player_status.sid, BinData),
%%             handle(41001, Status, [PetId]),
%%             case RoleAttrChangeFlag =:= 1 of
%%                 true ->
%%                     NewStatus = lib_pet:calc_player_attribute(Status, NewPetAttr),
%%                     {ok, NewStatus};
%%                 false ->
%%                     skip
%%             end;            
%%         true ->
%%             {ok, BinData} = pt_410:write(41022, [Result, PetId]),
%%             lib_server_send:send_to_sid(Status#player_status.sid, BinData)
%%     end;
    skip;

%% -----------------------------------------------------------------
%% 宠物成长
%% -----------------------------------------------------------------
handle(41015, Status, [PetId]) ->
    OldPet = lib_pet:get_pet(PetId),
    OldGrowth = OldPet#player_pet.growth,
    [NewStatus, Result, RoleAttrChangeFlag, NewPetAttr, Again, Msg, TenMul, UpGradePhase, Exp] = mod_pet:grow_up(Status, PetId, notmed, 0, 0),
    %% 发送回应
    %NthGrow = mod_daily_dict:get_count(Status#player_status.id, 5000000),
    %%NextCost = data_pet:get_growth_gold_cost(NthGrow + 1),
    Pt = NewStatus#player_status.pet,
    Pet = lib_pet:get_pet(PetId),
    NewGrowth = Pet#player_pet.growth,
    DailyCount = mod_daily_dict:get_count(Status#player_status.id, 5000000),
    _SingleNum = data_pet:get_single_grow_goods_num(NewGrowth),
    case DailyCount >= 1 of 
        true ->
            SingleNum = _SingleNum,
            BatchGrowCost = 10*_SingleNum;
        false ->
            SingleNum = 0,
            BatchGrowCost = 9*_SingleNum
    end,
    {ok, BinData} = pt_410:write(41015, [Result, PetId, Again, Msg, TenMul, UpGradePhase, Exp, SingleNum, BatchGrowCost]),
    lib_server_send:send_to_sid(NewStatus#player_status.sid, BinData),
    case Result =:= 1 of
        true ->
        %% 更新其他宠物成长和潜能是否免费
        handle(41042, NewStatus, []),
	    %% 触发传闻
	    case NewGrowth > OldGrowth of
		true ->
		    if
			NewGrowth =:= 30 orelse NewGrowth =:= 40 orelse NewGrowth =:= 50 orelse NewGrowth =:= 60 orelse NewGrowth =:= 70 orelse NewGrowth =:= 80 ->
			    lib_chat:send_TV({all}, 0, 2, [petGrowUp, NewGrowth, Status#player_status.id, Status#player_status.realm,Status#player_status.nickname,Status#player_status.sex, Status#player_status.career, Status#player_status.image, Pet#player_pet.name, data_pet:get_quality(Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude)]);
			true ->
			    []
		    end;
		false ->
		    []
	    end,
	    lib_task:event(pet_grow_up, do, Status#player_status.id),
            handle(41001, NewStatus, [PetId]),
            if
                Pt#status_pet.pet_id =:= PetId andalso Pet =/= [] ->
		    %% 发送宠物形象改变通知到场景
                    lib_pet:send_figure_change_notify(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, Pet#player_pet.figure, Pet#player_pet.nimbus, Pet#player_pet.level, Pet#player_pet.name, Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude);
                true ->
                    skip
            end,
            case RoleAttrChangeFlag =:= 1 of
                true ->
                    NewStatus2 = lib_pet:calc_player_attribute(NewStatus, NewPetAttr),
                    {ok, pet_addition, NewStatus2};
                false ->
                    {ok, NewStatus}
            end; 
        false ->
            skip
    end;

%% 宠物技能学习
handle(41020, Status, [PetId, GoodsId, GoodsTypeId, LockList, StoneList]) ->
    case lib_secondary_password:is_pass(Status) of
        false -> 
            skip;
        true ->
	    Status1 = mod_pet:learn_skill(Status, [PetId, GoodsId, GoodsTypeId, 1, LockList, StoneList]),
	    Status2 = lib_pet:del_and_reload_pet_skill(Status1),
	    {ok, pet_addition, Status2}
    end;

%% -----------------------------------------------------------------
%% 宠物批量成长
%% -----------------------------------------------------------------
handle(41031, Status, [PetId]) ->
    OldPet = lib_pet:get_pet(PetId),
    OldGrowth = OldPet#player_pet.growth,
    [NewStatus, Result, RoleAttrChangeFlag, NewPetAttr, UpGradePhase, ExpList] = mod_pet:grow_up_batch(Status, PetId),
    %% 发送回应
     NthGrow = mod_daily_dict:get_count(Status#player_status.id, 5000000),
    Pet = lib_pet:get_pet(PetId),
    _SingleNum = data_pet:get_single_grow_goods_num(Pet#player_pet.growth),
    case NthGrow >= 1 of 
        true ->
            SingleNum = _SingleNum,
            BatchGrowCost = 10*_SingleNum;
        false ->
            SingleNum = 0,
            BatchGrowCost = 9*SingleNum
    end,
    {ok, BinData} = pt_410:write(41031, [Result, PetId, UpGradePhase, SingleNum, BatchGrowCost, ExpList]),
    lib_server_send:send_to_sid(NewStatus#player_status.sid, BinData),
    case Result =:= 1 of
        true ->
            %% 更新其他宠物的成长和潜能是否免费
            handle(41042, NewStatus, []),
            Pt = NewStatus#player_status.pet,
            Pet = lib_pet:get_pet(PetId),
	    NewGrowth = Pet#player_pet.growth,
	    %% 触发传闻
	    case NewGrowth > OldGrowth of
		true ->
		    if
			NewGrowth =:= 30 orelse NewGrowth =:= 40 orelse NewGrowth =:= 50 orelse NewGrowth =:= 60 orelse NewGrowth =:= 70 orelse NewGrowth =:= 80 ->
			    lib_chat:send_TV({all}, 0, 2, [petGrowUp, NewGrowth, Status#player_status.id, Status#player_status.realm,Status#player_status.nickname,Status#player_status.sex, Status#player_status.career, Status#player_status.image, Pet#player_pet.name, data_pet:get_quality(Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude)]);
			true ->
			    []
		    end;
		false ->
		    []
	    end,
	    lib_task:event(pet_grow_up, do, Status#player_status.id), 
            handle(41001, NewStatus, [PetId]),
            if
                Pt#status_pet.pet_id =:= PetId andalso Pet =/= [] ->
		    %% 发送宠物形象改变通知到场景
                    lib_pet:send_figure_change_notify(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, Pet#player_pet.figure, Pet#player_pet.nimbus, Pet#player_pet.level, Pet#player_pet.name, Pet#player_pet.base_aptitude+Pet#player_pet.extra_aptitude);
                true ->
                    skip
            end,
            case RoleAttrChangeFlag =:= 1 of
                true ->
                    NewStatus2 = lib_pet:calc_player_attribute(NewStatus, NewPetAttr),
                    {ok, pet_addition, NewStatus2};
                false ->
                    {ok, NewStatus}
            end; 
        false ->
            skip
    end;


%% -----------------------------------------------------------------
%% 宠物展示
%% -----------------------------------------------------------------
handle(41016, Status, [PetId, PlayerId]) ->
    [Result, Data] = mod_pet:show_pet(Status, [PetId, PlayerId]),
    {ok, BinData} = pt_410:write(41026, [Result,Data]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 宠物出战替换
%% -----------------------------------------------------------------
handle(41017, Status, [PetId]) ->
 %    case Status#player_status.scene =:= 250 orelse Status#player_status.scene =:= 251 orelse Status#player_status.scene =:= 252 orelse lists:member(Status#player_status.scene, data_kf_3v3:get_config(scene_pk_ids)) of
	% true ->
	%     {ok, BinData} = pt_410:write(41017, [0, PetId]),
 %            lib_server_send:send_to_sid(Status#player_status.sid, BinData),
 %            ok;
	% false ->
	    [Result, PetAttr, _PetPotentialAttr, PetFigure, PetNimbus, PetLevel, PetName, PetAptitude] = mod_pet:fighting_pet_replace(Status, [PetId]),
	    Pt = Status#player_status.pet,
	    if  Result == 1 ->
						% 发送宠物形象改变通知到场景
		    lib_pet:send_figure_change_notify(Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y, Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, PetFigure, PetNimbus, PetLevel, PetName, PetAptitude),
		    NewPet = lib_pet:get_pet(PetId),
		    PetPotentialAttr = lib_pet:calc_potential_attr(NewPet),
		    PetSkillAttr = lib_pet:calc_pet_skill_attribute(PetLevel, NewPet#player_pet.skills),
		    PetFigureAttr = lib_pet:filter_figure_attr(Status#player_status.unreal_figure_activate),
		    Status1 = Status#player_status{pet=Pt#status_pet{pet_id       = PetId,
								     pet_figure   = PetFigure,
								     pet_nimbus   = PetNimbus,
								     pet_level    = PetLevel,
								     pet_name     = util:make_sure_list(PetName),
								     pet_attribute = PetAttr,
								     pet_potential_attribute = PetPotentialAttr,
								     pet_skill_attribute = PetSkillAttr,
								     pet_figure_attribute=PetFigureAttr,
								     pet_aptitude = PetAptitude
								    }},
		    %% 角色属性加点
		    Status2 = lib_pet:calc_player_attribute(Status1),
		    lib_player:send_attribute_change_notify(Status2, 1),
		    %% 发送回应
		    {ok, BinData} = pt_410:write(41017, [Result, PetId]),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
		    %% 宠物主动技能加成
		    Status3 = lib_pet:del_and_reload_pet_skill(Status2),
		    %% 返回新状态
		    {ok, pet_addition, Status3};
		true ->
		    {ok, BinData} = pt_410:write(41017, [Result, PetId]),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
		    ok
	    end;
    % end;

%% -----------------------------------------------------------------
%% 潜能修行
%% @param:Type:修行类型 0单次修行 1批量修行
%% -----------------------------------------------------------------
handle(41018, Status, [PetId, Type]) ->
    case check_span_time_long(pp_pet41018, Status#player_status.id, Type, 500) of
	true ->
	    NewStatus= mod_pet:practice_potential(Status, PetId, Type, notmed, 0, 0),
	    handle(41001, NewStatus, [PetId]),
        handle(41042, NewStatus, []),
	    {ok, pet, NewStatus};
	false ->
	    []
    end;
%%     if
%%         UpGrade =:= upgrade ->
%%             handle(41001, NewStatus, [PetId]),
%%             {ok, NewStatus};
%%         true ->
%%             ok
%%     end;

%% -----------------------------------------------------------------
%% 宠物砸蛋:Type:1,2,3
%% -----------------------------------------------------------------
%% handle(41019, Status, [Type]) ->
%%     [Result, NewStatus, Again, AddExp] = mod_pet:egg_broken(Status),
%%     if
%%         Result =:= 1 ->
%%             {ok, BinData} = pt_410:write(41019, [Result, Again, AddExp]),
%%             lib_server_send:send_to_sid(NewStatus#player_status.sid, BinData),
%%             {ok, NewStatus};
%%         true ->
%%             {ok, BinData} = pt_410:write(41019, [Result, Again, AddExp]),
%%             lib_server_send:send_to_sid(NewStatus#player_status.sid, BinData)
%%     end;

%%　获取砸蛋信息
handle(41050, Status, _Data) ->
    EggList = lib_pet_egg:get_egg_info(Status),
    %% io:format("~p ~p EggList:~p~n", [?MODULE, ?LINE, EggList]),
    {ok, BinData} = pt_410:write(41050, [EggList]),
    %% io:format("~p ~p BinData:~p~n", [?MODULE, ?LINE, BinData]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);



%%　砸蛋操作
handle(41019, Status, [Type]) ->
    case lib_pet_egg:egg_broken(Status, Type) of
        {error, PS, Code} -> 
            %% io:format("~p ~p Code:~p~n", [?MODULE, ?LINE, Code]),
            {ok, BinData} = pt_410:write(41019, [Code, []]),
            lib_server_send:send_to_sid(PS#player_status.sid, BinData);
        {ok, PS, [GiveGoods, NoticeList], Code} -> 
            spawn(fun() ->
                    if 
                        length(NoticeList) > 0 ->
                            {ok, BinData2} = pt_170:write(41052, [PS#player_status.id, PS#player_status.realm, PS#player_status.nickname,
                                                                  Type, NoticeList]),
                            
                            lib_chat:send_TV({all},0, 2, ["egg", 1, PS#player_status.id, PS#player_status.realm, PS#player_status.nickname, 
                                                          PS#player_status.sex, PS#player_status.career, PS#player_status.image] ++ NoticeList),
                            lib_server_send:send_to_all(BinData2);
                       true -> skip
                    end
                  end),
            %% io:format("~p ~p [GiveGoods, NoticeList]:~p,~n Code:~p~n", [?MODULE, ?LINE, [GiveGoods, NoticeList], Code]),
            {ok, BinData} = pt_410:write(41019, [Code, GiveGoods]),
            lib_server_send:send_to_sid(PS#player_status.sid, BinData),
            handle(41050, PS, []),
            handle(41051, PS, []),
            {ok, PS}
    end;


%%　获取砸蛋公告信息
handle(41051, Status, _Data) ->
    mod_disperse:cast_to_unite(lib_pet_egg, get_egg_notice, [Status]);


%% -----------------------------------------------------------------
%% 技能遗忘
%% -----------------------------------------------------------------
handle(41021, Status, [PetId, SkillTypeId]) ->
    case lib_secondary_password:is_pass(Status)  of
        false ->
            skip;
        true ->
	    [Result, NewSkills, PetAttr, PetSkillAttr, ForgetSkillId] = mod_pet:forget_skill2(Status, [PetId, SkillTypeId]),
						% 发送回应
	    {ok, BinData} = pt_410:write(41021, [Result, PetId, ForgetSkillId, NewSkills]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
	    handle(41001, Status, [PetId]),
	    Pt = Status#player_status.pet,
	    if  % 成功且为出战宠物
		Result == 1 andalso Pt#status_pet.pet_id == PetId ->
		    Status1 = lib_pet:calc_player_attribute(Status, PetAttr, PetSkillAttr),
		    Status2 = lib_pet:del_and_reload_pet_skill(Status1),
		    {ok, pet_addition, Status2};
		true ->
		    ok
	    end
    end;


%% 宠物排行榜
handle(41023, Status, [PetId, PetOwner]) ->
    [Result, InfoBin] = mod_pet:show_pet(Status, [PetId, PetOwner]),
    {ok, Bin} = pt_410:write(41023, [Result, InfoBin]),
    lib_server_send:send_to_sid(Status#player_status.sid, Bin),
    ok;

handle(41024, _Status, _) ->
    ok;
handle(41025, _Status, _) ->
    ok;
handle(41026, _Status, _) ->
    ok;

handle(41028, Status, _) ->
    FigureChangePetId = case lib_pet:get_exists_figure_change_pet(Status#player_status.id) of
			    false -> 0;
			    Pet -> Pet#player_pet.id
			end,
    ActivateFigureList = Status#player_status.unreal_figure_activate,
    SendList = lists:map(fun(Record) ->
				 LeftTime = util:unixtime() - (Record#pet_activate_figure.activate_time + Record#pet_activate_figure.last_time),
				 {Record#pet_activate_figure.type_id,
				  lib_pet:make_pet_figure(Record#pet_activate_figure.figure_id, 0),
				  Record#pet_activate_figure.change_flag,	
				  Record#pet_activate_figure.activate_flag,
				  LeftTime}
			 end, ActivateFigureList),
    {ok, BinData} = pt_410:write(41028, [1, Status#player_status.pet_figure_value, SendList, FigureChangePetId]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%% 宠物幻化使用
handle(41029, Status, [PetId, FigureId]) ->
    [Result, NewStatus] = mod_pet:change_figure(PetId, FigureId, Status),
    {ok, BinData} = pt_410:write(41029, [Result, PetId, FigureId]),
    lib_server_send:send_to_sid(NewStatus#player_status.sid, BinData),
    {ok, pet_addition, NewStatus};

%% 宠物幻化取消
handle(41030, Status, [PetId, FigureId]) ->
    [Result, NewStatus] = mod_pet:cancel_change_figure(PetId, FigureId, Status),
    {ok, BinData} = pt_410:write(41030, [Result]),
    lib_server_send:send_to_sid(NewStatus#player_status.sid, BinData),
    {ok, pet_addition, NewStatus};

%% 获取宠物技能刷新列表
handle(41032, Status, _) ->
    [LuckyVal, BlessVal, FreeCount, BoxList] = lib_pet:get_refresh_skill(Status),
    {ok, BinData} = pt_410:write(41032, [LuckyVal, BlessVal, FreeCount, BoxList]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    ok;
%% 宠物技能刷新
handle(41033, Status, [Type,UseBindGold]) ->
    case lib_pet:check_span_time(Status#player_status.id) of
	ok ->
	    [Result, Status1] = lib_pet:refresh_skill(Status, Type, UseBindGold),
	    %% if
	    %% 	Result =:= 1 ->
	    %% 	    case Type of
	    %% 		0 -> lib_task:fin_task_vip(Status, 700050, 1);
	    %% 		1 -> lib_task:fin_task_vip(Status, 700050, 10);
	    %% 		_ -> []
	    %% 	    end;
	    %% 	true -> []
	    %% end,
	    {ok, BinData} = pt_410:write(41033, [Result]),
	    lib_server_send:send_to_sid(Status1#player_status.sid, BinData),
	    {ok, Status1};
	_ -> []
    end;
%% 抄写刷新出来的物品
handle(41034, Status, [GoodsTypeId, Bind, CopyType]) ->
    [Result, Status1] = lib_pet:copy_skill(Status, GoodsTypeId, Bind, CopyType),
	case Result =:= 1 of
		true ->
			%% 运势任务(3700014:神秘商店)
			lib_fortune:fortune_daily(Status#player_status.id, 3700014, 1);
		false ->
			skip
	end,
    {ok, BinData} = pt_410:write(41034, [Result, GoodsTypeId]),
    lib_server_send:send_to_sid(Status1#player_status.sid, BinData),
    {ok, Status1};
%% 祝福值兑换物品
handle(41035, Status, [GoodsTypeId]) ->
    [Result, Status1] = lib_pet:withdraw_bless_goods(Status, GoodsTypeId),
    {ok, BinData} = pt_410:write(41035, [Result, GoodsTypeId]),
    lib_server_send:send_to_sid(Status1#player_status.sid, BinData),
    {ok, Status1};
%% 宠物技能刷新广播
handle(41036, Status, _) ->
    {AllNotice, OneNotice} = mod_pet_refresh_skill:get_one_and_all_record(Status#player_status.id),
    {ok, BinData} = pt_410:write(41036, [AllNotice, OneNotice]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    ok;
%% 宠物蛋预览
handle(41037, Status, [PetId, Aptitude, PetName, Figure, Growth, Quality]) ->
    {ok, BinData} = pt_410:write(41037, [PetId, Aptitude, PetName, Figure, Growth, Quality]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    ok;
%% 宠物幻化值排行榜
handle(41038, Status, [PetId, PlayerId]) ->
    case Status#player_status.id =:= PlayerId of
	true ->
	    [Result, InfoBin] = mod_pet:show_pet_figure_change(Status, [PetId]),
	    {ok, Bin} = pt_410:write(41038, [Result, InfoBin]),
	    lib_server_send:send_to_sid(Status#player_status.sid, Bin);
	false ->
	    case lib_player:get_player_info(PlayerId, pid) of
		false ->
		    [Result, InfoBin] = mod_pet:show_pet_figure_change_from_db(PlayerId),
		    {ok, Bin} = pt_410:write(41038, [Result, InfoBin]),
		    lib_server_send:send_to_sid(Status#player_status.sid, Bin);
		Pid ->
		    gen_server:cast(Pid, {'show_pet_figure_change', Status#player_status.sid, PetId}),
		    ok
	    end
    end;
handle(41039, Status, [PlayerId]) ->
    case Status#player_status.id =:= PlayerId of
    	true ->
	       [Result, Data] = lib_pet:get_fighting_pet_info(Status),
	       {ok, BinData} = pt_410:write(41039, [Result,Data]),
	       lib_server_send:send_to_sid(Status#player_status.sid, BinData);
    	false ->
    	    case lib_player:get_player_info(PlayerId, pid) of
                false ->
                    {ok, BinData} = pt_410:write(41039, [0,<<>>]),
                    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
                Pid ->
                    gen_server:cast(Pid, {'show_fighting_pet_info', Status#player_status.sid}),
                    ok
    	    end
    end;

handle(41042, Status, []) ->
    GrowthTimes = mod_daily_dict:get_count(Status#player_status.id, 5000000),
    PotentialTimes = mod_daily_dict:get_count(Status#player_status.id, 5000006),
    case GrowthTimes >= 1 of 
        true ->
            GrowFree = 0;
        false ->
            GrowFree = 1
    end,
    case PotentialTimes >= 1 of 
        true ->
            PotentialFree = 0;
        false ->
            PotentialFree = 1
    end, 
    {ok, BinData} = pt_410:write(41042, [GrowFree, PotentialFree]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
handle(_Cmd, _Status, _Data) ->
    ?ERR("pp_pet no match", []),
    {error, "pp_pet no match"}.



check_span_time_long(Key, PlayerId, Type, Time) ->
    case Type of 
        0 ->
            true;
        _ ->
            Now = util:longunixtime(),
            Span = lists:concat([PlayerId, Key]),
            case get(Span) of
	           undefined ->
	               put(Span, Now),
	               true;
	           SpanTime ->
	               if
		          %% 2次玩的间隔
		              Now - SpanTime >= Time -> 
		                  put(Span, Now),
		                  true;
		              true ->
		                  false
	               end
            end
    end.
