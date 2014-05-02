%%%------------------------------------
%%% @Module  : mod_server_cast
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.12.16
%%% @Description: 角色cast处理
%%%------------------------------------
-module(mod_server_cast).
-export([handle_cast/2,set_data/2]).
-include("server.hrl").
-include("scene.hrl").
-include("buff.hrl").
-include("goods.hrl").
-include("pet.hrl").
-include("common.hrl").
-include("rela.hrl").
-include("figure.hrl").
-include("drop.hrl").
-include("activity.hrl").
-include("predefine.hrl").

%% 设置玩家属性(按属性列表更新)远程调用
%% @spec set_data(AttrKeyValueList,Pid) -> noprc | ok
%% AttrKeyValueList 属性列表 [{Key,Value},{Key,Value},...] Key为原子类型，Value为所需参数数据
%% Pid 玩家进程
%% @end
set_data(AttrKeyValueList, Pid) -> 
    case is_pid(Pid) andalso misc:is_process_alive(Pid) of
        true -> case catch gen_server:cast(Pid, {'set_data', AttrKeyValueList}) of
                {'EXIT', _R} -> 
                    util:errlog("ERROR mod_server_cast:set_data/2, Arg:[~p, ~p], Reason = ~p~n", [AttrKeyValueList, Pid, _R]);
                _ -> ok
            end;
        false -> noprc
    end.

%% 设置玩家属性(按属性列表更新)
%% @param AttrKeyValueList 属性列表 [{Key,Value},{Key,Value},...] Key为原子类型，Value为所需参数数据
%% @param Status 当前玩家状态
%% @return NewStatus 新玩家状态
set_data_sub(AttrKeyValueList,Status)->
    case AttrKeyValueList of
        []->Status;
        _->
            [{Key,Value}|T] = AttrKeyValueList,
            case Key of
				god->%%诸神
					NewStatus = lib_god:set_data_sub(Status),
					NewStatus;
				update_cjpt ->
					NewStatus = Status#player_status{cjpt = Value},
					NewStatus;
				set_physicl -> %%更新体力值信息 add by xieyunfei
					[NowPhysical,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,NowCumulateTime] = Value,
					NewStatus = Status#player_status.physical#status_physical{	
						physical_count = NowPhysical,
						physical_sum = PhysicalSum,
						accelerat_use = AcceleratUse,		
						accelerat_sum = AcceleratSum,		
						cd_time = CdTime,			
						cumulate_time = NowCumulateTime	},
					lib_player:send_attribute_change_notify(NewStatus, 2),
					NewStatus;
                cost_physical -> 
                    case lib_physical:cost_physical(Status, Value) of
                        {error, Error} -> 
                            catch util:errlog("mod_server_cast:set_data_sub cost_physical/2 error ~p~n", [Error]),
                            NewStatus = Status;
                        {ok, NewStatus} -> skip
                    end;
                task_sr_colour ->
                    NewStatus = Status#player_status{task_sr_colour = Value};
                kf_1v1->%%跨服1v1
                    [Loop,WinLoop,Hp,Pt,Score] = Value,
                    NewStatus = lib_kf_1v1:execute_end_bd_1v1(Status,[Loop,WinLoop,Hp,Pt,Score]),
                    lib_player:send_attribute_change_notify(NewStatus, 0),
                    NewStatus;
                kf_3v3 ->
                    NewStatus = lib_kf_3v3:update_player_info(Status, Value),
					lib_player:send_attribute_change_notify(NewStatus, 0),
					NewStatus;
                kf_3v3_pk ->
                    NewKf3v3Pk = Status#player_status.kf_3v3#status_kf_3v3{
						team_side = Value
					},
                    NewStatus = Status#player_status{kf_3v3 = NewKf3v3Pk};
                peach-> %蟠桃园
                    [Score,Acquisition,Plunder,Robbed,Now_Time,Peach_Card_good_num] = Value,
                    NewStatus = lib_peach:update_player_peach(Status,[Score,Acquisition,Plunder,Robbed,Now_Time,Peach_Card_good_num]),
                    NewStatus;
                peach_num -> %蟠桃园（变身广播用）
                    NewStatus = Status#player_status{peach_num = Value},
                    NewStatus;
                factionwar-> %帮战
                    [WarScore,KillNum,NowTime,Uid] = Value,
                    NewStatus = lib_factionwar:update_player_factionwar(Status,[WarScore,KillNum,NowTime,Uid]),
                    lib_player:send_attribute_change_notify(NewStatus, 0),
                    NewStatus;
                factionwar_used ->
                    Factionwar = Status#player_status.factionwar,
                    New_Factionwar = Factionwar#status_factionwar{war_score_used=Factionwar#status_factionwar.war_score_used+Value},
                    NewStatus = Status#player_status{factionwar = New_Factionwar},
                    lib_factionwar:update_factionwar_used_score(Status#player_status.id, Value),
                    NewStatus;
                arena -> %竞技场
                    [RoomLv,Room_Id,Score,Kill_num,Killed_Num,Max_continuous_kill] = Value,
                    NewStatus = lib_arena_new:execute_end_arena(Status, [RoomLv,Room_Id,Score,Kill_num,Killed_Num,Max_continuous_kill]),
                    lib_player:send_attribute_change_notify(NewStatus, 0),
                    NewStatus;
                %% 				guild_user ->
                %% 					NewStatus = lib_guild:set_player_data(Status, Value);
                arena_anger -> %更新竞技场怒气
                    lib_arena_new:update_anger(Status#player_status.id),
                    NewStatus = Status,
                    NewStatus;
                guild ->
                    NewStatus = Status#player_status{guild = Value};
                guild_syn ->
                    NewStatus = lib_guild:guild_server_syn(Status, Value);
                guild_ga_stage ->
                    PSGS = Status#player_status.guild,
                    NewPSGS = PSGS#status_guild{guild_ga_stage = Value},
                    NewStatus = Status#player_status{guild = NewPSGS};
                add_exp -> %%增加经验
                    NewStatus = lib_player:add_exp(Status, Value);
                add_llpt -> %%增加历练声望
                    NewStatus = lib_player:add_pt(llpt, Status, Value);
                unite_pid -> %%更新公共线pid
                    NewStatus = Status#player_status{unite_pid = Value};
                coin ->
                    NewStatus = Status#player_status{coin = Value};
                bcoin ->
                    NewStatus = Status#player_status{bcoin = Value};
                add_turntable_coin ->
                    NewStatus = lib_player:add_coin(Status, Value),
                    log:log_produce(find_lucky, coin, Status, NewStatus, data_turntable_text:get_consume_text(add_coin)),
                    NewStatus;
                add_turntable_bcoin ->
                    NewStatus = lib_goods_util:add_money(Status, Value, coin),
                    log:log_produce(find_lucky, bcoin, Status, NewStatus, data_turntable_text:get_consume_text(add_coin)),
                    NewStatus;
                cost_turntable_coin ->
                    NewStatus = lib_goods_util:cost_money(Status, Value, rcoin),
                    log:log_consume(find_lucky, coin, Status, NewStatus, data_turntable_text:get_consume_text(cost_coin)),
                    NewStatus;
                cost_shengxiao_coin ->
                    NewStatus = lib_goods_util:cost_money(Status, Value, rcoin),
                    log:log_consume(lunar, coin, Status, NewStatus, "lunar coin");
                add_shengxiao_gold ->
                    NewStatus = lib_goods_util:add_money(Status, Value, gold),
                    log:log_produce(lunar, gold, Status, NewStatus, "lunar gold");
                add_shengxiao_bgold ->
                    NewStatus = lib_goods_util:add_money(Status, Value, bgold),
                    log:log_produce(lunar, bgold, Status, NewStatus, "lunar bgold");
                add_shengxiao_bcoin ->
                    NewStatus = lib_goods_util:add_money(Status, Value, coin),
                    log:log_produce(lunar, coin, Status, NewStatus, "lunar coin");
                add_coin ->
                    NewStatus = lib_player:add_coin(Status, Value);
                cost_coin ->
                    NewStatus = lib_goods_util:cost_money(Status, Value, rcoin);
                add_gold ->
                    NewStatus = lib_goods_util:add_money(Status, Value, gold);
                add_bgold ->
                    NewStatus = lib_goods_util:add_money(Status, Value, bgold);
                add_bcoin ->
                    NewStatus = lib_goods_util:add_money(Status, Value, coin);
                %% 设置最新体力值
                set_physical ->
                    [Physical,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,CumulateTime] = Value,
                    NewStatus = Status#player_status{physical=#status_physical{physical_count=Physical,physical_sum = PhysicalSum,
                    accelerat_use=AcceleratUse,accelerat_sum=AcceleratSum,cd_time=CdTime, cumulate_time=CumulateTime}},
                    %% 刷新玩家属性
                    lib_player_server:execute_13001(NewStatus);
                hp -> %% 设置气血
                    NewStatus = Status#player_status{hp = Value};
                resume_hp_lim -> %% 回复气血
                    NewStatus = Status#player_status{hp = Status#player_status.hp_lim},
                    {ok, Bin} = pt_120:write(12009, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, NewStatus#player_status.hp, NewStatus#player_status.hp_lim]),
                    lib_server_send:send_to_area_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, Bin),
                    mod_scene_agent:update(hp_mp, NewStatus);
                mp -> %% 设置内力
                    NewStatus = Status#player_status{mp = Value};
                anger ->
                    NewStatus = Status#player_status{anger = Value};
                figure -> 
                    NewStatus = lib_figure:change(Status, Value),
                    %mod_scene_agent:update(figure, NewStatus),
                    NewStatus;
                group -> 
                    NewStatus = Status#player_status{group = Value},
                    mod_scene_agent:update(group, NewStatus),
                    NewStatus;
		%%  跨服3v3队伍id，此id并不是本服组队的队伍id
		kf_teamid ->
			NewStatus = Status#player_status{kf_teamid = Value},
			NewStatus;
                war_end_time ->
                    NewStatus = Status#player_status{war_end_time = Value};
                wubianhai_buff-> %%保底玩法代码
                    NewStatus = Status;
                add_whpt ->
                    NewStatus = lib_player:add_pt(whpt, Status, Value),
                    lib_player:send_attribute_change_notify(NewStatus, 0);
                add_fbpt ->
                    NewStatus = lib_player:add_pt(fbpt, Status, Value),
                    lib_player:send_attribute_change_notify(NewStatus, 0);
                add_fbpt2 ->
                    NewStatus = lib_player:add_pt(fbpt2, Status, Value),
                    lib_player:send_attribute_change_notify(NewStatus, 0);
                mlpt -> 
                    NewStatus = lib_player:add_pt(mlpt, Status, Value),
                    lib_player:send_attribute_change_notify(NewStatus, 0);
                save_design ->
                    NewStatus = Status#player_status{designation = Value};
                % 红名玩家死亡扣钱
                cost_red_name ->
                    case Status#player_status.coin + Status#player_status.bcoin >= Value of
                        true ->
                            NewStatus = lib_goods_util:cost_money(Status, Value, fcoin);
                        false ->
                            NewStatus = lib_goods_util:cost_money(Status, Status#player_status.coin + Status#player_status.bcoin, fcoin)
                    end,
                    case Status#player_status.coin =:= NewStatus#player_status.coin of
                        false -> log:log_consume(kill, coin, Status, NewStatus, "red_name");
                        true -> skip
                    end,
                    case Status#player_status.bcoin =:= NewStatus#player_status.bcoin of
                        false -> log:log_consume(kill, bcoin, Status, NewStatus, "red_name");
                        true -> skip
                    end;
                % 扣除国家声望
                minus_gjpt -> 
                    NewStatus = lib_player:minus_pt(gjpt, Status, Value),
                    lib_player:refresh_client(NewStatus),
                    lib_player:send_attribute_change_notify(NewStatus, 0);
                % 增加国家声望
                add_gjpt -> 
                    NewStatus = lib_player:add_pt(gjpt, Status, Value),
                    lib_player:refresh_client(NewStatus),
                    lib_player:send_attribute_change_notify(NewStatus, 0);
                % 增加罪恶值
                add_pk_value -> 
                    C = Status#player_status.pk#status_pk.pk_value + Value,
                    NewPk = Status#player_status.pk#status_pk{pk_value = C},
                    NewStatus = Status#player_status{pk = NewPk},
                    mod_gjpt:player_reg(NewStatus#player_status.id, C),
                    lib_player:update_player_state(NewStatus),
                    lib_player:add_pk_value_deal(Status, NewStatus);
                % 减少罪恶值
                minus_pk_value -> 
                    C = Status#player_status.pk#status_pk.pk_value - Value,
                    C1 = case C > 0 of
                        true -> C;
                        false -> 0
                    end,
                    case Status#player_status.pk#status_pk.pk_value > 0 of
                        true -> 
                            %% 右下角提示“减少罪恶值XX”
                            Msg = lists:concat([data_gjpt_text:get_gjpt_text(0), Status#player_status.pk#status_pk.pk_value - C1, data_gjpt_text:get_gjpt_text(1)]),
                            {ok, BinData} = pt_110:write(11004, Msg),
                            lib_unite_send:send_one(Status#player_status.socket, BinData);
                        false -> skip
                    end,
                    NewPk = Status#player_status.pk#status_pk{pk_value = C1},
                    NewStatus = Status#player_status{pk = NewPk},
                    mod_gjpt:player_reg(NewStatus#player_status.id, C1),
                    lib_player:update_player_state(NewStatus),
                    lib_player:minus_pk_value_deal(Status, NewStatus);
                pk_value -> 
                    {_Result, _ErrorCode, _NewType, _LTime, PkStatus} = lib_player:change_pkstatus(Status, Value),
                    NewStatus = PkStatus;
                % 伴侣ID
                parner_id ->
                    NewStatus = Status#player_status{parner_id = Value};
                % 长跑数据
                loverun_data ->
                    NewStatus = Status#player_status{loverun_data = Value};
                % 长跑状态
                loverun_state ->
                    NewStatus = Status#player_status{loverun_state = Value};
                % 南天门活动时间
                wubianhai_time -> 
                    NewStatus = Status#player_status{wubianhai_time = Value};
                % 保存钓鱼数据
                save_fish_status ->
                    NewStatus = Status#player_status{fish = Value},
                    lib_fish:refresh_award(NewStatus),
                    NewStatus;
                marriage_marry ->
                    Marriage = Status#player_status.marriage,
                    NewStatus = Status#player_status{marriage = Marriage#status_marriage{register_time = Value}},
                    mod_scene_agent:update(marriage_parner_id, NewStatus),
                    pp_player:handle(13011, NewStatus, no);
                marriage_wedding -> 
                    Marriage = Status#player_status.marriage,
                    NewStatus = Status#player_status{marriage = Marriage#status_marriage{wedding_time = Value}};
                marriage_cruise_time -> 
                    Marriage = Status#player_status.marriage,
                    NewStatus = Status#player_status{marriage = Marriage#status_marriage{cruise_time = Value}};
                marriage_cruise ->
                    Marriage = Status#player_status.marriage,
                    Visible = case Value of
                        1 -> 1;
                        _ -> 0
                    end,
                    NewStatus = Status#player_status
                    {
                        visible = Visible,
                        marriage = Marriage#status_marriage
                        {
                            is_cruise = Value
                        }
                    },
                    mod_scene_agent:update(is_cruise, NewStatus),
                    {ok, BinData} = pt_120:write(12003, NewStatus),
                    lib_server_send:send_to_area_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, BinData);
                marriage ->
                    NewStatus = Status#player_status{marriage = Value},
                    mod_scene_agent:update(marriage_parner_id, NewStatus),
                    pp_player:handle(13011, NewStatus, no);
                marriage_task ->
                    Marriage = Status#player_status.marriage,
                    NewStatus = Status#player_status{marriage = Marriage#status_marriage{task = Value}};
                marriage_cost ->
                    _NewStatus = lib_goods_util:cost_money(Status, Value, rcoin),
                    NewStatus = _NewStatus#player_status
                    {
                        marriage = _NewStatus#player_status.marriage#status_marriage
                        {
                            divorce = 0,
                            divorce_state = 0
                        }
                    },
                    lib_player:refresh_client(Status#player_status.id, 2),
                    log:log_consume(marriage, coin, Status, NewStatus, "marry cost");
                refresh_login_gift ->
                    NewStatus = Status,
                    pp_login_gift:handle(31204, Status, no);
                use_goods ->
                    NewStatus = Status,
                    {GoodsTypeId, GoodsNum} = Value,
                    gen_server:call(Status#player_status.goods#status_goods.goods_pid, {'delete_more', GoodsTypeId, GoodsNum});
                %% 增加VIP成长经验
                add_growth_exp ->
                    StatusVip = Status#player_status.vip,
                    case StatusVip#status_vip.vip_type of
                        3 ->
                            GrowthExp = StatusVip#status_vip.growth_exp,
                            NewValue = GrowthExp + Value,
                            Lv = data_vip_new:get_growth_lv(GrowthExp),
                            NewLv = data_vip_new:get_growth_lv(NewValue),
                            NewStatusVip = case NewLv > Lv of
                                true ->
                                    db:execute(io_lib:format(<<"update vip_info set get_award = 0 where id = ~p">>, [Status#player_status.id])),
                                    StatusVip#status_vip{
                                        growth_exp = NewValue,
                                        growth_lv = NewLv,
                                        get_award = 0
                                    };
                                false ->
                                    StatusVip#status_vip{
                                        growth_exp = NewValue,
                                        growth_lv = NewLv
                                    }
                            end,
                            NextExp = data_vip_new:get_next_exp(NewValue),
                            _RestTime = Status#player_status.vip#status_vip.vip_end_time - util:unixtime(),
                            RestTime = case _RestTime > 0 of
                                true -> _RestTime;
                                false -> 0
                            end,
                            DailyAdd = data_vip_new:add_growth_exp(GrowthExp),
                            {ok, BinData} = pt_450:write(45016, [NewValue, NextExp, NewLv, RestTime, DailyAdd]),
                            lib_server_send:send_one(Status#player_status.socket, BinData),
                            %% 更新数据库
                            db:execute(io_lib:format(<<"update vip_info set growth_exp = ~p where id = ~p">>, [NewValue, Status#player_status.id])),
                            NewStatus = Status#player_status{
                                vip = NewStatusVip
                            },
                            %% 是否移出世界等级图标
                            case NewLv =/= StatusVip#status_vip.growth_lv of
                                true -> 
                                    lib_rank_helper:world_remove_buff(NewStatus);
                                false ->
                                    skip
                            end;
                        _ ->
                            NewStatus = Status
                    end;
                %% 强制转换PK状态
                force_change_pk_status ->
                    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                    Value2 = case Value of
                        99 -> 
                            %% 在攻城战场景特殊处理
                            case Status#player_status.scene of
                                CityWarSceneId ->
                                    %% 判断玩家是否处于灵魂状态
                                    case Status#player_status.pk#status_pk.pk_status of
                                        7 ->
                                            %% 死亡列表中删除玩家
                                            mod_city_war:delete_revive_list(Status#player_status.id),
                                            1;
                                        _ ->
                                            Status#player_status.pk#status_pk.pk_status
                                    end;
                                _ ->
                                    Status#player_status.pk#status_pk.pk_status
                            end;
                        _ -> Value
                    end,
                    Pk = Status#player_status.pk,
                    Now = util:unixtime(),
                    NewStatus = Status#player_status{
                        pk = Pk#status_pk{
                            pk_status = Value2, 
                            pk_status_change_time = Now,
                            old_pk_status = Status#player_status.pk#status_pk.pk_status
                        }
                    },
                    %% 如果PK状态值没改变则不处理
                    case Status#player_status.pk#status_pk.pk_status of
                        Value2 ->
                            skip;
                        _ ->
                            mod_scene_agent:update(pk, NewStatus),
                            %通知场景的玩家
                            {ok, BinData} = pt_120:write(12084, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Value2, Pk#status_pk.pk_value]),
                            lib_server_send:send_to_scene(Status#player_status.scene, Status#player_status.copy_id, BinData),
                            %每次更改PK状态保存一下坐标
                            lib_player:update_player_state(Status),
                            %% 在攻城战场景特殊处理
                            case Status#player_status.scene =:= CityWarSceneId andalso Value2 =/= 7 of
                                true ->
                                    {ok, BinData2} = pt_130:write(13012, [0, 0, Value2]),
                                    lib_server_send:send_one(Status#player_status.socket, BinData2);
                                false ->
                                    skip
                            end
                    end;
                %% 有玩家改名，需要修改其伴侣的称号名称
                change_design ->
                    NewStatus = lib_designation:change_name_on_ps_status(Status, Value);
                visible -> %% 0为可见 | 1为不可见 
                    NewStatus = Status#player_status{visible = Value};
                refresh_45018 ->
                    pp_vip:handle(45018, Status, no),
                    NewStatus = Status;
                factionwar_stone ->
                    NewStatus = if
                        Value == 0 andalso  Status#player_status.factionwar_stone < 11 -> 
                            lib_factionwar:del_stone(Status, 2);
                        Value == 0 andalso  Status#player_status.factionwar_stone < 21 -> 
                            lib_city_war_battle:add_battle_status(Status, #ets_mon{}, Value);
                        Value < 11 -> lib_factionwar:add_stone(Status, Value, 2);
                        Value < 21 -> lib_city_war_battle:add_battle_status(Status, #ets_mon{}, Value);
                        true -> Status
                    end;
                city_war_clear_out ->
                    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                    case Status#player_status.scene of
                        CityWarSceneId ->
                            lib_city_war:quit_war(Status#player_status.id);
                        _ ->
                            skip
                    end,
                    _NewStatus = lib_city_war:logout_re_status(Status),
                    {noreply, NewStatus} = lib_city_war:del_city_war_buff(Status);
                city_war_logout ->
                    mod_city_war:logout_deal(Status),
                    NewStatus = lib_city_war:logout_re_status(Status);
                update_city_war_panel2 ->
                    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                    case Status#player_status.scene of
                        CityWarSceneId ->
                            mod_city_war:info_panel2(Status#player_status.guild#status_guild.guild_id, Status#player_status.id);
                        _ ->
                            skip
                    end,
                    NewStatus = Status;
                city_war_account_add ->
                    mod_city_war:add_score(Status#player_status.id, Value),
                    NewStatus = Status;
                reset_city_war ->
                    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                    case Status#player_status.scene of
                        CityWarSceneId ->
                            Group = Status#player_status.group,
                            NewGroup = case Group of
                                1 -> 2;
                                _ -> 1
                            end,
                            _NewStatus = Status#player_status{
                                group = NewGroup,
                                hp = Status#player_status.hp_lim,
                                mp = Status#player_status.mp_lim
                            },
                            mod_scene_agent:update(group, _NewStatus),
                            ReviveList = case NewGroup of
                                %% 进攻方复活点
                                1 -> data_city_war:get_city_war_config(get_attacker_born);
                                %% 防守方复活点
                                _ -> [[74, 122], [74, 122]]
                                    %data_city_war:get_city_war_config(get_defender_born)
                            end,
                            Len = length(ReviveList),
                            N = util:rand(1, Len),
                            [_X, _Y] = lists:nth(N, ReviveList),
                            [X, Y] = data_city_war:get_repair_xy(_X, _Y),
                            _NewStatus2 = lib_scene:change_scene(_NewStatus, CityWarSceneId, 0, X, Y, false),
                            CityWarRevivePlace = case NewGroup of
                                1 -> data_city_war:get_city_war_config(get_attacker_born);
                                _ -> data_city_war:get_city_war_config(get_defender_born)
                            end,
                            NewStatus = _NewStatus2#player_status{
                                city_war_revive_place = CityWarRevivePlace
                            };
                        _ ->
                            NewStatus = Status
                    end;
                city_war_award ->
                    %db:execute(io_lib:format(<<"insert into player_city_war set player_id = ~p, last_add_time = ~p, score = ~p ON DUPLICATE KEY UPDATE last_add_time = ~p, score = score + ~p">>, [Status#player_status.id, util:unixtime(), 200, util:unixtime(), 200])),
                    WarScore = Value,
                    db:execute(io_lib:format(<<"insert into player_factionwar set id = ~p, war_score = ~p, war_last_time = ~p ON DUPLICATE KEY UPDATE war_score = war_score + ~p">>, [Status#player_status.id, WarScore, util:unixtime(), WarScore])),
                    Factionwar = Status#player_status.factionwar,
                    New_Factionwar = Factionwar#status_factionwar{
                        war_score = Factionwar#status_factionwar.war_score + WarScore			%个人帮战战功
                    },  
                    _NewStatus = Status#player_status{factionwar=New_Factionwar},
                    Exp = Status#player_status.lv * Status#player_status.lv * 600,
                    NewStatus = lib_player:add_exp(_NewStatus, Exp),
                    lib_player:send_attribute_change_notify(NewStatus, 1);
                %% 回复旧的PK状态
                re_pk_status ->
                    Pk = Status#player_status.pk,
                    OldPkStatus = Pk#status_pk.old_pk_status,
                    NewStatus = Status#player_status{
                        pk = Pk#status_pk{
                            pk_status = OldPkStatus,
                            old_pk_status = Status#player_status.pk#status_pk.pk_status
                        }
                    },
                    mod_scene_agent:update(pk, NewStatus),
                    %通知场景的玩家
                    {ok, BinData} = pt_120:write(12084, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, OldPkStatus, Pk#status_pk.pk_value]),
                    lib_server_send:send_to_scene(Status#player_status.scene, Status#player_status.copy_id, BinData),
                    %每次更改PK状态保存一下坐标
                    lib_player:update_player_state(Status);
                %% 幽灵状态切换场景自动改回来
                soul_pk_change ->
                    case Status#player_status.pk#status_pk.pk_status of
                        7 ->
                            Pk = Status#player_status.pk,
                            NewStatus = Status#player_status{
                                pk = Pk#status_pk{
                                    pk_status = Value,
                                    old_pk_status = Status#player_status.pk#status_pk.pk_status
                                }
                            },
                            mod_scene_agent:update(pk, NewStatus),
                            %通知场景的玩家
                            {ok, BinData} = pt_120:write(12084, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Value, Pk#status_pk.pk_value]),
                            lib_server_send:send_to_scene(Status#player_status.scene, Status#player_status.copy_id, BinData),
                            {ok, BinData2} = pt_130:write(13012, [0, 0, Value]),
                            lib_server_send:send_one(Status#player_status.socket, BinData2);
                        _ ->
                            NewStatus = Status
                    end;
                set_city_war_revive_place ->
                    NewStatus = Status#player_status{
                        city_war_revive_place = Value
                    };
                is_city_war_win ->
                    GuildId = Status#player_status.guild#status_guild.guild_id,
                    IsCityWarWin = case db:get_row(<<"select winner_guild_id from log_city_war order by win_time desc limit 1">>) of
                        [GuildId] ->
                            1;
                        _ ->
                            0
                    end,
                    StatusGuild = Status#player_status.guild,
                    NewStatus = Status#player_status{
                        guild = StatusGuild#status_guild{
                            is_city_war_win = IsCityWarWin
                        }
                    };
                update_statue ->
                    mod_city_war:set_statue(Status),
                    NewStatus = Status;
                castellan ->
                    %% 长安城主传闻
                    mod_city_war:send_winner_tv(Status),
                    %lib_chat:send_TV({all}, 0, 2, ["castellanLine", 1, Status#player_status.id, Status#player_status.career, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image]),
                    NewStatus = Status;
                stop_loverun ->
                    NewStatus = Status,
                    mod_loverun:stop_run(Status);
                city_war_change_career -> 
                    lib_city_war:change_career_check([Status, Value]),
                    NewStatus = Status;
                send_to_loverun_parner ->
                    {Scene, CopyId, X, Y} = {Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y},
                    lib_scene:player_change_scene(Value, Scene, CopyId, X, Y, false),
                    NewStatus = Status;
                minus_off_line_count ->
                    {Type, Num, NowLevel} = Value,
                    NewOffLineAward = lib_off_line:update_list([Status#player_status.off_line_award, Type, Num, NowLevel, Status#player_status.lv, Status#player_status.id, Status#player_status.vip]),
                    NewStatus = Status#player_status{
                        off_line_award = NewOffLineAward
                    };
                del_player_buff ->
                    PlayerBuff = Status#player_status.player_buff,
                    NewPlayerBuff = lib_buff:del_buff_by_id(PlayerBuff, Value#ets_buff.id, PlayerBuff),
                    NewStatus = Status#player_status{
                        player_buff = NewPlayerBuff
                    };
                add_player_buff ->
                    PlayerBuff = Status#player_status.player_buff,
                    _NewPlayerBuff = lib_buff:del_buff_by_id(PlayerBuff, Value#ets_buff.id, PlayerBuff),
                    NewPlayerBuff = [Value | _NewPlayerBuff],
                    NewStatus = Status#player_status{
                        player_buff = NewPlayerBuff
                    };
                del_all_player_buff ->
                    NewStatus = Status#player_status{
                        player_buff = []
                    };
                add_city_war_buff ->
                    {noreply, NewStatus} = lib_city_war:add_city_war_buff(Status),
                    mod_scene_agent:update(battle_attr, NewStatus),
                    mod_scene_agent:update(hp_mp, NewStatus);
                del_city_war_buff ->
                    {noreply, NewStatus} = lib_city_war:del_city_war_buff(Status),
                    mod_scene_agent:update(battle_attr, NewStatus),
                    mod_scene_agent:update(hp_mp, NewStatus);
                vip_dun_clear_out ->
                    VipDunSceneId = data_vip_dun:get_vip_dun_config(scene_id),
                    case Status#player_status.scene =:= VipDunSceneId of
                        true ->
                            [SceneId, X, Y] = data_vip_dun:get_vip_dun_config(leave),
                            CopyId = 0,
                            lib_scene:player_change_scene(Status#player_status.id, SceneId, CopyId, X, Y, false);
                        false ->
                            skip
                    end,
                    NewStatus = Status;
                vip_dun_send_back ->
                    [X, Y] = Value,
                    lib_scene:player_change_scene(Status#player_status.id, Status#player_status.scene, Status#player_status.copy_id, X, Y, false),
                    NewStatus = Status;
                vip_dun_battle_award ->
                    mod_vip_dun:vip_dun_battle_award(Status, Value),
                    NewStatus = Status;
                add_vip_dun_bcoin ->
                    NewStatus = lib_goods_util:add_money(Status, Value, coin),
                    log:log_produce(vip_dun, coin, Status, NewStatus, "vip dun");
                vip_dun_send ->
                    VipDunScene = data_vip_dun:get_vip_dun_config(scene_id),
                    case Status#player_status.scene of
                        VipDunScene ->
                            lib_server_send:send_one(Status#player_status.socket, Value);
                        _ ->
                            skip
                    end,
                    NewStatus = Status;
                vip_dun_scene_send ->
                    lib_server_send:send_to_scene(Status#player_status.scene, Status#player_status.copy_id, Value),
                    NewStatus = Status;
                vip_dun_create_goods ->
                    [GoodsList, X, Y] = Value,
                    mod_vip_dun:create_goods(Status, GoodsList, X, Y),
                    NewStatus = Status;
                check_vip_dun_buy_num ->
                    NeedGold = data_vip_dun:get_vip_dun_buy_gold(Value),
                    case NeedGold of
                        %% 超过次数上限
                        0 ->
                            Res = 3,
                            RestNum = 0,
                            NextGold = 0,
                            NewStatus = Status;
                        _ ->
                            case Status#player_status.gold < NeedGold of
                                %% 元宝不足
                                true ->
                                    Res = 2,
                                    RestNum = 0,
                                    NextGold = 0,
                                    NewStatus = Status;
                                false ->
                                    NewStatus = lib_goods_util:cost_money(Status, NeedGold, gold),
                                    log:log_consume(vip_dun_buy_num, gold, Status, NewStatus, "vip dun buy num"),
                                    Res = 1,
                                    RestNum = data_vip_dun:get_vip_dun_config(max_buy_num) - Value,
                                    NextGold = data_vip_dun:get_vip_dun_buy_gold(Value + 1),
                                    mod_vip_dun:buy_num(Status#player_status.id),
                                    lib_player:refresh_client(Status#player_status.id, 2)
                            end
                    end,
                    case Res of
                        1 ->
                            skip;
                        _ ->
                            {ok, BinData} = pt_451:write(45113, [Res, RestNum, NextGold]),
                            lib_server_send:send_one(Status#player_status.socket, BinData)
                    end;
				unite_to_server ->
                    lib_server_send:send_one(Status#player_status.socket, Value),
                    NewStatus = Status;
				unite_to_server_scene ->
                    lib_server_send:send_to_scene(Status#player_status.scene, Status#player_status.copy_id, Value),
                    NewStatus = Status;
				guild_dun_award ->
					[Llpt, Caifu] = Value,
					NewStatus = lib_player:add_pt(llpt, Status, Llpt),
					lib_player:send_attribute_change_notify(NewStatus, 0),
					lib_guild_base:add_guild_caifu_server(NewStatus#player_status.id, Caifu);
                increment_praise ->
                    [SendId, SendName] = Value,
                    NewPraise = mod_praise:increment_praise(Status#player_status.praise_pid, SendId, SendName, Status#player_status.id, Status#player_status.get_praise, Status#player_status.nickname),
                    NewStatus = Status#player_status{get_praise = NewPraise};
                _ ->
                    NewStatus = Status
            end,
            set_data_sub(T,NewStatus)
    end.

%%==========基础功能base============
%%写入用户信息
handle_cast({'base_set_data', PlayerStatus}, _Status) ->
    {noreply, PlayerStatus};

%% 分类设置/更新玩家信息|(因为各属性更改规则不一致，故需要特殊写规则，请维护上面set_data_sub()函数)
%% @param Type 更新数据的类型_根据此类型来对Info解包
%% @param Info 更新所包含的数据
handle_cast({'set_data', AttrKeyValueList}, Status) ->
	%% 根据类型_调用各个功能自己的组合函数来更新玩家信息，请维护set_data_sub()函数。
	NewPlayerStatus = set_data_sub(AttrKeyValueList,Status),
	{noreply, NewPlayerStatus};

%%改变PK状态(不需要返回值时调用)
handle_cast({change_pk_status,Type},Status) ->
    {_Result, _ErrorCode, _NewType, _LTime, NewStatus1} = lib_player:change_pkstatus(Status, Type),
    {noreply, NewStatus1};

%%提取对应卡牌的物品(不需要返回值时调用)
handle_cast({get_card_good,Type},Status) ->
    case Type of
		1-> %%蟠桃园
		   NewStatus=lib_peach:server_send_mail(Status);
		_->NewStatus=Status
	end,
    {noreply, NewStatus};

%% 调用模块函数
handle_cast({'apply_cast', Moudle, Method, Args}, Status) ->
	%io:format("mod_server_cast apply_cast Moudle = ~p, Method = ~p, Args = ~p~n",[Moudle, Method, Args]),
	case catch apply(Moudle, Method, Args) of
		{'EXIT', Info} ->
			util:errlog("mod_server_call apply_call error Moudle = ~p, Method = ~p, Args = ~p, Reason = ~p~n",
						[Moudle, Method, Args, Info]);
		_ ->
			ok
	end,
	{noreply, Status};

handle_cast({'OUT_KUANG'}, Status) ->
    NewStatus = Status#player_status{scene=Status#player_status.guild#status_guild.guild_id + 1000, x = 43, y=48},
    Sid = Status#player_status.guild#status_guild.guild_id + 1000,
    {ok, BinData} = pt_120:write(12005, [NewStatus#player_status.scene, NewStatus#player_status.x, NewStatus#player_status.y, <<>>, Sid]),
    lib_server_send:send_one(NewStatus#player_status.socket, BinData),
    {noreply, NewStatus};

%%更改玩家场景
handle_cast({change_scene,SceneId,CopyId,X,Y,Need_Out},Status) ->            
    %% 可以传送的场景
    VipDunScene = data_vip_dun:get_vip_dun_config(scene_id),
	GuildDunScene = [data_guild_dun:get_dun_config(dun1_scene), data_guild_dun:get_dun_config(dun2_scene), data_guild_dun:get_dun_config(dun3_scene)],
    CanChangeScene = [VipDunScene|GuildDunScene],
	NewStatus = 
        case lib_scene:is_dungeon_scene(Status#player_status.scene) andalso lists:member(Status#player_status.scene, CanChangeScene) =:= false of
                true ->
					%副本地图无法传送.
				    {ok, BinData} = pt_450:write(45001, [2, 0]),
				    lib_server_send:send_one(Status#player_status.socket, BinData),
					Status;
                _ ->
					lib_scene:change_scene(Status,SceneId,CopyId,X,Y,Need_Out)
        end,	
	{noreply, NewStatus};

%% 怪物掉落
handle_cast({'drop', [{Id, Mid, SceneId, CopyId, X, Y, Exp, Level, DropNum, Group, Skip}, Klist, Att1, Att2]}, Status) ->
    _Mon = data_mon:get(Mid),
    Mon = _Mon#ets_mon{
        id = Id,
        mid = Mid,
        scene = SceneId,
        copy_id = CopyId,
        x = X,
        y = Y,
        drop_num = DropNum,
        exp = Exp,
        lv = Level,
        group = Group,
        skip = Skip
    },
    lib_mon_die:drop(Mon#ets_mon.kind, Status, Mon, Klist, Att1, Att2),
    lib_mon_die:execute_any_fun(Mon, Status, Klist),
    NewStatus = if
        Mid == 10547 -> lib_factionwar:add_stone(Status, 1, 1); %% 帮派水晶采集
        Mid == 42011 orelse Mid == 42012 orelse Mid == 42013 orelse Mid == 42021-> %% 帮派战采集变身 
            SkillId = lib_figure:mon_skill(Mid),
            MyKey  = [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num],
            lib_battle:battle_use_whole_skill(Status#player_status.scene, MyKey, SkillId, MyKey),
            Status;
        Mid == 40419 orelse Mid == 40431 orelse Mid == 40432 -> % 城战炸弹/炮塔/攻城车/弩车
            lib_city_war_battle:add_battle_status(Status, Mon, 1);
        (Mid == 40421 orelse Mid == 40461 orelse Mid == 40471) andalso Status#player_status.group == Group andalso Group /= 0 -> % 城战炮塔
            lib_city_war_battle:add_battle_status(Status, Mon, 1);
        true -> Status
    end,
    {noreply, NewStatus};

%% -------------------------组队副本---------------------------------------------

%% 设置组队数据
%% Type: 0(没有组队)|1(队长)|2(队员) 
handle_cast({'set_team', TeamPid, Leader, LeaderId}, Status) ->
	%1.更新玩家进程.
    NewStatus = Status#player_status{pid_team = TeamPid, leader = Leader},
	%2.更新场景进程.
    mod_scene_agent:update(team, NewStatus),
	%3.通知附近的玩家.
    {ok, BinData} = pt_120:write(12018, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Leader]), 
    lib_server_send:send_to_area_scene(Status#player_status.scene, 
                    				   Status#player_status.copy_id, 
                    				   Status#player_status.x,  
                    				   Status#player_status.y, 
                    				   BinData),
	%4.更新公共线的组队ID.
	lib_player:update_unite_info(Status#player_status.unite_pid, 
    							[{team_id, LeaderId}]),

    {noreply, NewStatus};    

%% 设置副本进程PID
handle_cast({set_dungeon_pid, Val}, Status) ->
    NewStatus = Status#player_status{copy_id = Val},
    {noreply, NewStatus};

%% 副本传出保存坐标
handle_cast({'DR_SENT_OUT', Scene, X, Y, _NowScene}, _Status) ->
%%     Status = lib_skill:update_skill_attribute_for_ps(_Status),
    NewStatus = _Status#player_status{copy_id = 0, scene = Scene, x = X, y = Y},
    Status1 = lib_scene:change_scene_handler(NewStatus, Scene, _Status#player_status.scene),
    {noreply, Status1};


%% 副本再来一次重新请求12005
handle_cast({'DR_SENT_OUT_TRY_AGAIN', Scene, X, Y, NowScene}, _Status) ->
    NewStatus = _Status#player_status{copy_id = 0, scene = Scene, x = X, y = Y},
    Status1 = lib_scene:change_scene_handler(NewStatus, Scene, _Status#player_status.scene),
    case pp_scene:handle(12005, Status1, NowScene) of
        {ok, Status2} -> Status2;
        _ ->
            {ok, BinData} = pt_120:write(12005, [Scene, X, Y, lib_scene:get_scene_name(Scene), Scene]),
            lib_server_send:send_to_sid(_Status#player_status.sid, BinData),
            Status2 = Status1
    end,
    {noreply, Status2};

%% 铜币副本发放奖励.
handle_cast({'coin_dungeon_reward', _Coin, Bcoin}, Status) ->
	%1.增加绑定铜币.
	if 
		Bcoin > 0 ->
			NewStatus1 = lib_player:add_coin(Status, Bcoin),	
			log:log_produce(coin_dungeon, coin, Status, NewStatus1, "");
		true ->
			skip
	end,
    {noreply, Status};

%% 铜币副本发放奖励绑定铜币.
handle_cast({'coin_dungeon_reward_coin', Coin}, Status) ->
    NewStatus2 = 
    if 
        Coin > 0 ->
            NewStatus1 = lib_player:add_coin(Status, Coin),	
            log:log_produce(coin_dungeon, coin, Status, NewStatus1, "coin_dungeon"),
            lib_player:refresh_client(Status#player_status.id, 2),
            NewStatus1;
        true ->
            Status
    end,
    {noreply, NewStatus2};

%% 锁妖塔奖励每层经验.
handle_cast({'tower_reward_exp', Exp, Llpt, _DunId, _Level, _MemberIds}, Status) ->
    Status1 = lib_player:add_exp(Status, Exp, 0),
    Status2 = lib_player:add_pt(llpt, Status1, Llpt),
    {noreply, Status2};

%% 锁妖塔奖励
handle_cast({'tower_reward', _Exp, _Llpt, Items, Honour, KingHonour, Level, Time, TowerName}, Status) ->
    case Items of
        [] -> ok;
        _ -> 
			G = Status#player_status.goods,
			catch gen_server:call(G#status_goods.goods_pid, {'give_more', Status, Items})
    end,
    %Status1 = lib_player:add_exp(Status, Exp, 0),
    %Status2 = lib_player:add_pt(llpt, Status1, Llpt),
    %% 远征岛日志
    log:log_tower(
        Status#player_status.id, 
        Status#player_status.nickname, 
        TowerName,
        Level,
        Time,
        Honour,
        0,
        KingHonour,
        0
    ),
    %% 通知客户端刷新    
    lib_player:refresh_client(Status#player_status.id, 1), %% 更新背包
    {noreply, Status};
    
%% 增加连砍状态加成.
handle_cast({'combo_buff', _Combo, _MaxCombo, SkillLv}, Status) ->
    NextSkillLv = case get(coin_dungeon_combo_buff) of
        undefined -> SkillLv;
        SaveLv    -> max(SaveLv, SkillLv)
    end,
    NewStatus = lib_skill_buff:add_buff([{?COIN_DUN_COMBO_SKILL_ID, NextSkillLv}], Status, util:longunixtime()),
    mod_scene_agent:update(battle_attr, NewStatus),
    {noreply, NewStatus};

%% 上线增加连砍状态加成.
handle_cast({'combo_buff_online', MaxCombo}, Status) ->
    NewStatus = lib_skill_buff:coin_dun_combo_skill_online(Status, MaxCombo),
    {noreply, NewStatus};

%% 剧情副本自动挂机奖励物品.
handle_cast({'auto_story_dungeon_drop', DropList, Pos}, Status) ->
	Status1 = 
		case DropList of 
			[] ->
				Status;
			_DropList ->
				%1.发到临时背包.
				lib_temp_bag:insert_temp_goods(Status, DropList, Pos)
		end,
	[log:log_goods(story_dungeon, 
				   0, 
				   DropInfo#ets_drop_goods.goods_id, 
				   1, 
				   Status#player_status.id)|| DropInfo <- DropList],
    {noreply, Status1};

%% 获取副本总积分得到的属性加成.
handle_cast('count_base_attribute', Status) ->
     NewStatus  = lib_player:count_player_attribute(Status),
     lib_player:send_attribute_change_notify(NewStatus, 0),
    {noreply, NewStatus};

%% 设置帮派防刷积分.
handle_cast('set_guild_anti_brush_score', Status) ->
	lib_anti_brush:set_guild_anti_brush_score(Status),
    {noreply, Status};

%% 塔防副本复活.
handle_cast('king_dun_revive', Status) ->
    HpLim = round(Status#player_status.hp_lim * 0.05),
    if
		%1.血量大于某个值，玩家未死亡
	    Status#player_status.hp > HpLim ->
            {noreply, Status};

		%2.处理复活的事情.
        true ->
            {Result,Status1} = lib_battle:revive(Status, 3),
		    {ok, BinData} = pt_200:write(20004, [Result]),
		    lib_server_send:send_to_sid(Status1#player_status.sid, BinData),
			{noreply, Status1}
    end;

%% 异步复活.
handle_cast({'asyn_revive', R}, Status) ->
    Hp = case is_float(R) of
        true -> round(Status#player_status.hp_lim * R);
        false -> R
    end,
    Mp = case is_float(R) of
        true -> round(Status#player_status.mp_lim * R);
        false -> R
    end,
    PKStatus = set_data_sub(Status, [{re_pk_status, no}]),
    {Result,Status1} = lib_battle:revive(PKStatus#player_status{hp=Hp, mp=Mp}, 4),
    {ok, BinData} = pt_200:write(20004, [Result]),
    lib_server_send:send_to_sid(Status1#player_status.sid, BinData),
    {noreply, Status1};

%% -------------------------组队副本end---------------------------------------------

%% 设置战斗组队数据
%% Group: 战斗分组 
handle_cast({'set_group', Group}, Status) ->
	%1.更新玩家进程.
    NewStatus = Status#player_status{group = Group},
	%2.更新场景进程.
    mod_scene_agent:update(group, NewStatus),
    {noreply, NewStatus};
    
%% 祝福积累
handle_cast({'GREETING_ACC', Exp, Llpt}, Status) ->
    AccNum = case get('GREETING_ACC') of
        undefined -> 0;
        GA -> GA
    end,
    NewGreetingExp = Status#player_status.greeting_acc_exp + Exp,
    NewGreetingLlpt = Status#player_status.greeting_acc_llpt + Llpt,
    NewStatus = Status#player_status{greeting_acc_exp = NewGreetingExp, greeting_acc_llpt = NewGreetingLlpt},
    case AccNum > 7 of
        true -> %%写数据库 
            put('GREETING_ACC', 0),
            lib_relationship2:db_update_greeting_acc(Status#player_status.id, NewGreetingExp, NewGreetingLlpt),
            skip;
        false ->
            put('GREETING_ACC', AccNum + 1)
    end,
    {noreply, NewStatus};


%% 发送好友祝福改变状态
handle_cast({'SET_GREETING_SEND', Exp, Llpt}, Status) ->
    Status1 = lib_player:add_exp(Status, Exp, 0),
    Status2 = lib_player:add_pt(llpt, Status1, Llpt),
    %mod_daily:increment(Status#player_status.id, 10000),
    {noreply, Status2};

%% 接受好友祝福改变状态
handle_cast({'SET_GREETING_ACCEPT', Exp, Llpt}, Status) ->
    Status1 = lib_player:add_exp(Status, Exp, 1),
    Status2 = lib_player:add_pt(llpt, Status1, Llpt),
    {noreply, Status2};

%% 验证码通过后通知玩家更改状态
handle_cast({'CAPTCHA_PASS', CaptchaTypeNum}, PlayerStatus) ->
    if
        CaptchaTypeNum =:= 2 -> %% 登录验证
            NewPlayerStatus = lib_doubt_account:pass_login_check(PlayerStatus),
            Result = {ok, NewPlayerStatus};
%%         CaptchaTypeNum =:= 3 -> %% 钱多多验证
%%             Result = lib_doubt_account:pass_coin_check(PlayerStatus);
        CaptchaTypeNum =:= 4 -> %% 运镖验证码
            Result = lib_doubt_account:pass_yunbiao_check(PlayerStatus);
        true ->
            Result = ok
    end,
    case Result of
        {ok, NewStatus} when is_record(NewStatus, player_status) ->
            {noreply, NewStatus};
%%         {ok, NewStatus} ->
%%             catch util:errlog("badrecord:==captch type num:~p==id:~p==~p", [CaptchaTypeNum, PlayerStatus#player_status.id, NewStatus]),
%%             {noreply, PlayerStatus};
        {ok, NewStatus} ->
            {noreply, NewStatus};
        _ ->
            {noreply, PlayerStatus}
    end;




%% BUFF状态删除 
handle_cast({'del_buff', BuffId}, Status) ->
    case lib_player:del_player_buff(Status, BuffId) of
        {fail, _Res} -> {noreply, Status};
        {ok, NewStatus} -> 
            mod_scene_agent:update(battle_attr, NewStatus),
            mod_scene_agent:update(hp_mp, NewStatus),
            {noreply, NewStatus}
%%         {ok, NewStatus} -> {noreply, NewStatus}
    end;

%%  器灵状态删除 
handle_cast({'del_qiling_figure', _GoodsTypeId}, Status) ->
    NewPlayerStatusF = Status#player_status{qiling = 0},
	mod_scene_agent:update(qiling_figure, NewPlayerStatusF), 
	{ok, BinDataF} = pt_120:write(12003, NewPlayerStatusF),
	lib_server_send:send_to_area_scene(NewPlayerStatusF#player_status.scene, NewPlayerStatusF#player_status.copy_id, NewPlayerStatusF#player_status.x, NewPlayerStatusF#player_status.y, BinDataF),
	{ok, BinData} = pt_130:write(13001, NewPlayerStatusF),
	lib_server_send:send_to_sid(NewPlayerStatusF#player_status.sid, BinData),
	{noreply, NewPlayerStatusF};

%% 变身状态删除
handle_cast({'del_figure', _GoodsTypeId}, Status) ->
    NewPlayerStatusF = lib_figure:change(Status, {0, 0}),
    %Status#player_status{figure = 0},
	%mod_scene_agent:update(figure, NewPlayerStatusF), 
	%{ok, BinDataF} = pt_120:write(12099, [NewPlayerStatusF#player_status.id, NewPlayerStatusF#player_status.platform, NewPlayerStatusF#player_status.server_num, 0, 0]),
	%lib_server_send:send_to_area_scene(NewPlayerStatusF#player_status.scene, NewPlayerStatusF#player_status.copy_id, NewPlayerStatusF#player_status.x, NewPlayerStatusF#player_status.y, BinDataF),
	{ok, BinData} = pt_361:write(36112, [1]),
	lib_server_send:send_to_sid(NewPlayerStatusF#player_status.sid, BinData),
	{noreply, NewPlayerStatusF};

%% ------------------------------------打坐双修---------------------------------------------
%% 取消打坐
handle_cast({'sit_up'}, Status) ->
    NewStatus = lib_sit:sit_up(Status),
    {noreply, NewStatus};
%% 双修开始
handle_cast({'shuangxiu_start',PlayerId,NowTime}, Status) ->
    Sit = Status#player_status.sit,
    NewStatus = Status#player_status{ sit=Sit#status_sit{sit_down = 2, sit_hp_time = NowTime, sit_exp_time = NowTime, sit_llpt_time = NowTime, sit_intimacy_time = NowTime, sit_role = PlayerId} },
    {noreply, NewStatus};
%% 双修中断
handle_cast({'shuangxiu_interrupt', PlayerId, PlayerName}, Status) ->
    Sit = Status#player_status.sit,
    case Sit#status_sit.sit_down =:= 2 andalso Sit#status_sit.sit_role =:= PlayerId of
        true ->
            NewStatus = lib_sit:shuangxiu_interrupt(Status, PlayerId, PlayerName),
            {noreply, NewStatus};
        false ->
            {noreply, Status}
    end;
%% 双修形象改变
handle_cast({'shuangxiu_figure', FigureId, PlayerId}, Status) ->
    Sit = Status#player_status.sit,
    case Sit#status_sit.sit_down =:= 2 andalso Sit#status_sit.sit_role =:= PlayerId of
        true ->
            NewStatus = Status#player_status{sit=Status#player_status.sit#status_sit{sit_role_figure=FigureId}},
            {noreply, NewStatus};
        false ->
            {noreply, Status}
    end;
%% -----------------------------------任务------------------------------------------
%%完成任务
handle_cast({'fin_task', Minfo}, Status) ->
    lib_task:fin_task(Status, Minfo),
    {noreply, Status};

%%完成搜集任务
handle_cast({'fin_task_goods', TaskList, Minfo}, Status) ->
    lib_task:fin_task_goods(Status, TaskList, Minfo),
    {noreply, Status};

%% 刷新任务
handle_cast({'refresh_npc_ico'}, Status) ->
    lib_scene:refresh_npc_ico(Status),
    {noreply, Status};

%% 增加经验.
handle_cast({'EXP', Exp}, Status) ->
	Exp1 = calc_exp(Exp, Status),
    Status1 = lib_player:add_exp(Status, Exp1, 1, 1),
    {noreply, Status1};

%% -------------------------------------------------------------------
%%  VIP Buff加成
%% -------------------------------------------------------------------
handle_cast({'vipbuff', GoodsTypeId}, Status) ->
    case data_goods_effect:get_val(GoodsTypeId, buff) of
        [] ->
            {noreply, Status};
        {Type, AttributeId, Value, Time, SceneLimit} ->
             NowTime = util:unixtime(),
             case lib_buff:match_three(Status#player_status.player_buff, Type, AttributeId, []) of
             %case lib_player:get_player_buff(Status#player_status.id, Type, AttributeId) of
                 [] ->
                     NewBuffInfo = lib_player:add_player_buff(Status#player_status.id, Type, GoodsTypeId, AttributeId, Value, NowTime+Time, SceneLimit);
                 [BuffInfo] ->
                     NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsTypeId, Value, NowTime+Time, SceneLimit)
             end,
			 %% 领取祝福,state设为1
			 mod_vip:insert_buff(#ets_vip_buff{id = Status#player_status.id, buff = NewBuffInfo, rest_time = Time, state = 1}),
			 buff_dict:insert_buff(NewBuffInfo),
             lib_player:send_buff_notice(Status, [NewBuffInfo]),
             BuffAttribute = lib_player:get_buff_attribute(Status#player_status.id, Status#player_status.scene),
             NewStatus     = lib_player:count_player_attribute(Status#player_status{buff_attribute = BuffAttribute}),
             lib_player:send_attribute_change_notify(NewStatus, 0),
             {noreply, NewStatus};
	 	_Any -> skip
    end;
%% --------------------pet------------------begin
%% 宠物幻化排行榜
handle_cast({'show_pet_figure_change', Sid, PetId}, Status) ->
    [Result, InfoBin] = mod_pet:show_pet_figure_change(Status, [PetId]),
    {ok, Bin} = pt_410:write(41038, [Result, InfoBin]),
    lib_server_send:send_to_sid(Sid, Bin),
    {noreply, Status};
handle_cast({'show_fighting_pet_info', Sid}, Status) ->
    [Result, InfoBin] = lib_pet:get_fighting_pet_info(Status),
    {ok, Bin} = pt_410:write(41039, [Result, InfoBin]),
    lib_server_send:send_to_sid(Sid, Bin),
    {noreply, Status};    
%% 孵化宠物
handle_cast({'incubate_pet', [GoodsInfo, GoodsUseNum]}, Status) ->
    NewStatus = pp_pet:handle(41003, Status, [GoodsInfo, GoodsUseNum]),
    {noreply, NewStatus};

%% 喂养宠物
handle_cast({'feed_pet', [GoodsInfo, GoodsUseNum]}, Status) ->
    Pet = lib_pet:get_fighting_pet(Status#player_status.id),
    if  % 宠物不存在
        Pet =/= []  ->
            pp_pet:handle(41010, Status, [Pet#player_pet.id, GoodsInfo#goods.id, GoodsUseNum]);
        true ->
            skip
    end,
    {noreply, Status};

handle_cast({'pet_figure_activate', [GoodsInfo, GoodsUseNum]}, Status) ->
    [Result, SendList, NewStatus] = mod_pet:activate_figure(Status, [GoodsInfo, GoodsUseNum]),
    ChangePetId = case lib_pet:get_exists_figure_change_pet(Status#player_status.id) of
		      false -> 0;
		      Pet -> Pet#player_pet.id
		  end,
    {ok, BinData} = pt_410:write(41028, [Result, NewStatus#player_status.pet_figure_value, SendList, ChangePetId]),
    lib_server_send:send_to_sid(NewStatus#player_status.sid, BinData),
    {noreply, NewStatus};
						 
%% 宠物潜能修行
handle_cast({'practice_potential', [GoodsInfo, GoodsUseNum]}, Status) ->
    FightingPet = lib_pet:get_fighting_pet(Status#player_status.id),
    if  % 宠物不存在
	FightingPet =/= []  ->
	    PetId = FightingPet#player_pet.id,
	    NewStatus = mod_pet:practice_potential(Status, PetId, 0, GoodsInfo#goods.goods_id, GoodsInfo#goods.id, GoodsUseNum),
	    pp_pet:handle(41001, NewStatus, [PetId]),
	    mod_scene_agent:update(pet, NewStatus);
	true ->
	    NewStatus = Status
    end,
    {noreply, NewStatus};

%% 宠物成长提升
handle_cast({'pet_grow_up', [GoodsInfo, GoodsUseNum]}, Status) ->
    FightingPet = lib_pet:get_fighting_pet(Status#player_status.id),
    NewStatus3 = 
	case FightingPet =/= [] of
	    true ->
		PetId = FightingPet#player_pet.id,
		[NewStatus, Result, RoleAttrChangeFlag, NewPetAttr, Again, Msg, TenMul, UpGradePhase, Exp] = mod_pet:grow_up(Status, PetId, GoodsInfo#goods.goods_id, GoodsInfo#goods.id, GoodsUseNum),
		%% 发送回应
        Pet = lib_pet:get_pet(PetId),
		NthGrow = mod_daily_dict:get_count(Status#player_status.id, 5000000),
		%NextCost = data_pet:get_growth_gold_cost(NthGrow + 1),
		%BatchGrowCost = data_pet:get_grow_up_cost_batch(10, NthGrow),
        _SingleNum = data_pet:get_single_grow_goods_num(Pet#player_pet.growth),
        case NthGrow >= 1 of 
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
			lib_task:event(pet_grow_up, do, Status#player_status.id),
			pp_pet:handle(41001, NewStatus, [PetId]),
			Pt = NewStatus#player_status.pet,
			%Pet = lib_pet:get_pet(PetId),
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
				mod_scene_agent:update(pet_addition, NewStatus2),
				NewStatus2;
			    false ->
				NewStatus
			end; 
		    false ->
			NewStatus
		end;
	    false ->
		Status
	end,
    {noreply, NewStatus3};

%% 宠物资质提升
handle_cast({'pet_aptitude_up', [GoodsInfo, GoodsUseNum]}, Status) ->
    FightingPet = lib_pet:get_fighting_pet(Status#player_status.id),
    NewStatus3 = 
	case FightingPet =/= [] of
	    true ->
		PetId = FightingPet#player_pet.id,
        %% 宠物资质 = 基础资质+ 额外资质
		OldExtraAptitude = FightingPet#player_pet.extra_aptitude,
        BaseAptitude = FightingPet#player_pet.base_aptitude,
        OldAptitude = OldExtraAptitude + BaseAptitude,
		[NewStatus, Result, RoleAttrChangeFlag, NewPetAttr, NewAptitude] = mod_pet:aptitude_up(Status, PetId, GoodsInfo#goods.goods_id, GoodsInfo#goods.id, GoodsUseNum),
		{ok, BinData} = pt_410:write(41027, [Result, PetId, max(0, NewAptitude - OldAptitude)]),
		lib_server_send:send_to_sid(NewStatus#player_status.sid, BinData),
		case Result =:= 1 of
		    true ->		
			pp_pet:handle(41001, NewStatus, [PetId]),
			Pt = NewStatus#player_status.pet,
			Pet = lib_pet:get_pet(PetId),
			if
			    Pt#status_pet.pet_id =:= PetId andalso Pet =/= [] ->
				%% 发送宠物形象改变通知到场景
				lib_pet:send_figure_change_notify(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, Pet#player_pet.figure, Pet#player_pet.nimbus, Pet#player_pet.level, Pet#player_pet.name, NewAptitude);
			    true ->
				skip
			end,
			case RoleAttrChangeFlag =:= 1 of
			    true ->
				NewStatus2 = lib_pet:calc_player_attribute(NewStatus, NewPetAttr),
				%mod_scene_agent:update(pet_addition, NewStatus2),
                mod_scene_agent:update(pet, NewStatus2),
                mod_scene_agent:update(battle_attr, NewStatus2),
				NewStatus2;
			    false ->
				NewStatus
			end; 
		    false ->
			NewStatus
		end;
	    false ->
		Status
	end,
    {noreply, NewStatus3};

%% 宠物经验提升
handle_cast({'pet_upgrade', [GoodsInfo, GoodsUseNum]}, Status) ->
    [Result, NewStatus, PetId, NewPetLevel, NewPetExp] =  mod_pet:upgrade_exp_by_med(Status, [GoodsInfo#goods.goods_id, GoodsInfo#goods.id, GoodsUseNum]),
    {ok, BinData} = pt_410:write(41040, [Result, PetId, NewPetLevel, NewPetExp]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    {noreply, NewStatus};
%% --------------------------------pet------------------------end

handle_cast({'show_qiling_attr', Sid, PlayerId}, Status) ->
    [Forza, Agile, Wit, Thew] = lib_qiling:calc_qiling_attr(Status#player_status.qiling_attr),
    {ok, Bin} = pt_172:write(17203, [Forza, Agile, Wit, Thew, PlayerId]),
    lib_server_send:send_to_sid(Sid, Bin),
    {noreply, Status};

handle_cast({'show_flyer_for_rank', LookId, Nth}, Status) ->
    lib_flyer:show_flyer_for_rank(LookId, Status, Nth),
    {noreply, Status};
    
%% 刷新可以皇榜任务列表
handle_cast({'sys_refresh_task_eb'}, Status) ->
    MinTriggerLv = data_task_eb:get_task_config(min_trigger_lv, []),
    if
        Status#player_status.lv >= MinTriggerLv ->
            lib_task_eb:sys_refresh_task_eb(Status),
            pp_task_eb:handle(30400, Status, []);
        true ->
            skip
    end,
    {noreply, Status};

%% 使用飞行道具
handle_cast({'use_fly_goods', [GoodsInfo]}, Status) ->
    {ok, NewStatus} = lib_fly_mount:use_goods(Status, [GoodsInfo]),
    {noreply, NewStatus};

%% 涮出一个平乱任务
handle_cast({'refresh_task_sr_init'}, Status) ->
	MinTriggerLv = data_task_sr:get_task_config(min_trigger_lv, []),
	if
        Status#player_status.lv >= MinTriggerLv ->
            lib_task_sr:refresh_task_sr(Status, 0, Status#player_status.task_sr_colour),
            pp_task_sr:handle(30500, Status, []);
        true ->
            skip
    end,
    {noreply, Status};

%% 劫镖者获得一半奖励
handle_cast({'intercept_husong', Exp,Coin}, Status) ->
    NewStatus1 = lib_player:add_coin(Status, Coin),
    NewStatus2 = lib_player:add_exp(NewStatus1, Exp),
    lib_player:refresh_client(NewStatus2#player_status.id, 1), %% 更新背包
%%     util:errlog("intercept_husong:pid=~p Exp=~p Coin=~p", [NewStatus2#player_status.id, Exp,Coin]),
    {noreply, NewStatus2};

%% 被劫镖获得一半奖励
handle_cast({'reward_husong', Exp,Coin}, Status) ->
    NewStatus1 = lib_player:add_coin(Status, Coin),
    NewStatus2 = lib_player:add_exp(NewStatus1, Exp),
    lib_player:refresh_client(NewStatus2#player_status.id, 1), %% 更新背包
%%     util:errlog("reward_husong:pid=~p Exp=~p Coin=~p", [NewStatus2#player_status.id, Exp,Coin]),
    {noreply, NewStatus2};

%% 帮派宴会_赠送
handle_cast({'guild_party_thank', [Num, Type, LLPT, GuildId]}, Status) ->	
    NewStatus = lib_player:add_pt(llpt, Status, LLPT),
	lib_player:send_attribute_change_notify(NewStatus, 0),
	{ok, BinData} = pt_401:write(40114, [Num, Type, LLPT, NewStatus#player_status.nickname]),
	%% lib_server_send:send_one(NewStatus#player_status.socket, BinData),
	lib_server_send:send_to_scene(105, GuildId, BinData),
    {noreply, NewStatus};

%% 触发护送奖励
handle_cast({'husong_reward', Mul}, Status) ->
    pp_husong:handle(46005, Status, [Mul]),
    {noreply, Status};

%% 双倍护送开始通知
handle_cast({'guoyun_notify', []}, Status) ->
    Time = lib_husong:guoyun_left_time(util:unixtime()),
    {ok, BinData} = pt_460:write(46010, [Time]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    {noreply, Status};

%% 使用技能书
handle_cast({'use_skill_book', [SkillId, GoodsId]}, Status) ->
    NewStatus = lib_skill:use_skill_book(Status, SkillId, GoodsId),
    {noreply, NewStatus};

%% 中断交易
handle_cast({'stop_sell'}, Status) ->
    G = Status#player_status.goods,
    Sell = Status#player_status.sell,
    gen_server:cast(G#status_goods.goods_pid, {'stop_sell'}),
    NewPlayerStatus = Status#player_status{sell=Sell#status_sell{sell_status=0, sell_id=0, sell_list=[]}},
    {ok, BinData} = pt_180:write(18001, [NewPlayerStatus#player_status.id, 0, NewPlayerStatus#player_status.nickname, 
                                        NewPlayerStatus#player_status.lv, NewPlayerStatus#player_status.combat_power,
                                    NewPlayerStatus#player_status.vip#status_vip.vip_type]),
    lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
    {noreply, NewPlayerStatus};

%% %% [公共线调用] 增加或扣除体力值
%% handle_cast({'add_physical', [PlayerId, CheckType]}, Status) ->
%% 	Physical = lib_physical:add_in_unite(PlayerId, Status#player_status.physical, CheckType),
%% 	NewStatus = Status#player_status{physical = Physical},
%% 	%% 刷新玩家属性
%% 	lib_player_server:execute_13001(NewStatus),
%%     {noreply, NewStatus};

%% 增加或扣除成就点
handle_cast({'add_cjpt', [Score]}, Status) ->
	NewStatus = lib_player:add_pt(cjpt, Status, Score),
	{noreply, NewStatus};

%% 触发活跃度
handle_cast({'trigger_active', [_Role, Type, TargetId]}, Status) ->
	mod_active:trigger(Status#player_status.status_active, Type, TargetId, Status#player_status.vip#status_vip.vip_type),
	{noreply, Status};

%% 触发目标
handle_cast({trigger_target, [RoleId, Type, TargetId]}, Status) ->
	mod_target:trigger(Status#player_status.status_target, RoleId, Type, TargetId),
	{noreply, Status};

%% 分享队友钓鱼积分
handle_cast({share_fish_score, [CopyId, Score]}, Status) ->
	NewStatus = lib_fish:share_score(Status, CopyId, Score),
	{noreply, NewStatus};

%% 蝴蝶谷：捕蝴蝶增加积分
handle_cast({add_butterfly_score, [MonId]}, Status) ->
	NewStatus = lib_butterfly:add_score(Status, MonId),
	{noreply, NewStatus};

%% 蝴蝶谷：分享队友捕蝴蝶积分
handle_cast({share_butterfly_score, [[CopyId, Score]]}, Status) ->
	NewStatus = lib_butterfly:share_score(Status, CopyId, Score),
	{noreply, NewStatus};

%% 击杀BOSS
handle_cast({'kill_boss', [Boss, Mid]}, Status) ->
	case Boss of
		%% 野外boss
		1 -> 
			%% 成就：剿灭群妖,击败猪魔王、蝎子精等任意精英BOSS累积N次
			case lists:member(Mid, [40006,40008,40009,40010,16101,16102,16120,16121,40011]) of
				true ->
					mod_achieve:trigger_trial(Status#player_status.achieve, Status#player_status.id, 36, Mid, 1);
				_ ->
					skip
			end;
		%% 世界boss
		3 ->
			WorldBossList = [40005,40031,40032,40033,40034,40040,40041,40042,40043,40044,16110,
				16111,16112,16113,40050,40051,40052,40053,40054,40061,40062,40063,40064,40065,40066,
				40067,40068,40069,40070,40071,40072,40073,40074,40075,40076,40077,40078,40079,40080,
				40300,40301,40302,40303,40304,40081,40082,40083,40084,40085,40086,40087,40088,40089,40090],
			case lists:member(Mid, WorldBossList) of
				true ->
					mod_achieve:trigger_trial(Status#player_status.achieve, Status#player_status.id, 37, Mid, 1);
				_ ->
					skip
			end;
		_ ->
			skip
	end,
    
	%% 目标：通关封魔录3关 104
	case lists:member(Mid, [56414]) of
		true ->
            %% 目标：通关封魔录3关 104
			mod_target:trigger(Status#player_status.status_target, Status#player_status.id, 104, Mid);
		_ ->
			skip
	end,

    %%  目标：通关24关装备副本 403
    case lists:member(Mid, [34048]) of
        true ->
            %% 目标：通关24关装备副本 403
            mod_target:trigger(Status#player_status.status_target, Status#player_status.id, 403, Mid);
        _ ->
            skip
    end,

        %% 目标：通关封魔录8层 404
    case lists:member(Mid, [56904]) of
        true ->
            %% 目标：通关封魔录8层 404
            mod_target:trigger(Status#player_status.status_target, Status#player_status.id, 404, Mid);
        _ ->
            skip
    end,
	
	{noreply, Status};

%% 0点刷新任务
handle_cast({'refresh_and_clear_task'}, Status)  ->
    case is_process_alive(Status#player_status.tid) of
        true ->
            lib_task:daily_clear_dict(Status),
            lib_task:refresh_task(Status);
        false ->
            skip
    end,
    {noreply, Status};


%% 0点刷新日常
handle_cast({'refresh_and_clear_daily'}, Status)  ->
    gen_server:cast(Status#player_status.dailypid, {daily_clear_0, Status#player_status.id}),
    {noreply, Status};

%% 帮宴赋予奖励
handle_cast({'guild_party_add', Type, Mood}, Status) ->
	EXPA1 = case Type of
		1->40;
		2->80;
		3->120
	end,
	ExpAdd = round((EXPA1 * Mood * 0.000105) * Status#player_status.lv * Status#player_status.lv),
	LLPTAdd =round((100 - (10 - Status#player_status.lv * 0.1) * (10 - Status#player_status.lv * 0.1)) * EXPA1 * 0.1),
	%% 加经验
	Status1 = lib_player:add_exp(Status, ExpAdd, 1, 2),
	%% 加历练声望
	Status2 = lib_player:add_pt(llpt, Status1, LLPTAdd),
	%% 累积经验、历练
	case get(guild_party_exp) of
		undefined ->
			put(guild_party_exp, ExpAdd);
         Exp ->
			put(guild_party_exp, Exp+ExpAdd)
	end,
	case get(guild_party_llpt) of
		undefined ->
			put(guild_party_llpt, LLPTAdd);
         Llpt ->
			put(guild_party_llpt, Llpt+LLPTAdd)
	end,
	lib_player:send_attribute_change_notify(Status2, 0),
    {noreply, Status2};

%% 帮宴经验、气氛值消息
handle_cast({'guild_party_exp', Type, Time_Left, Mood, InfoType, Info, JoinNum, Upgrader}, Status)  ->
	%% 累积经验、历练
	case get(guild_party_exp) of
		undefined ->			
			All_Exp =0;
         Exp ->
			All_Exp =Exp 
	end,
	case get(guild_party_llpt) of
		undefined ->
			All_Llpt =0;
         Llpt ->
			All_Llpt =Llpt
	end,
	{ok, BinData} = pt_401:write(40108, [Time_Left, Mood, InfoType, Info, JoinNum, All_Exp, All_Llpt, Upgrader, Type]),			
	lib_server_send:send_to_uid(Status#player_status.id, BinData),
	{noreply, Status};



%% 答题奖励(增加玩家文采值和经验).
handle_cast({'quiz_reward', Genius, Exp}, Status) ->
    NewGenius = Status#player_status.chengjiu#status_chengjiu.genius + Genius,
    NewChengjiu = Status#player_status.chengjiu,
    NewStatus = Status#player_status{chengjiu = NewChengjiu#status_chengjiu{genius = NewGenius}},
    NewStatus1 = lib_player:add_exp(NewStatus, Exp),
    {noreply, NewStatus1};
    
%% 使用物品触发任务
handle_cast({'use_task_goods', [GoodsInfo, GoodsUseNum]}, Status) ->
    Go = Status#player_status.goods,
    TaskId = data_task_goods:get_trigger_task(GoodsInfo#goods.goods_id),
    NewStatus = 
    case pp_task:handle(30003, Status, [TaskId]) of
        {ok, NewRS} ->
            case gen_server:call(Go#status_goods.goods_pid, {'delete_one', GoodsInfo#goods.id, GoodsUseNum}) of
                1 ->
                    NewRS;
                _GoodsModuleCode ->
                    NewRS
            end;
        _ ->
            Status
    end,
    {noreply, NewStatus};

%% 完成仙侣情缘任务
handle_cast({'finish_task_unite', PlayerId}, Status) ->
	case PlayerId =:= Status#player_status.id of
		true ->
			%% 完成任务
			lib_task:event(Status#player_status.tid, xlqy, do, Status#player_status.id),
%% 			io:format("~p~n", [PlayerId]),
 			%% 刷新NPC
			{ok, BinData} = pt_300:write(30004, [1, <<>>]),
%% 			io:format("TaskId ~p~n", [TaskId]),
	 		lib_server_send:send_one(Status#player_status.socket, BinData);
		_ ->
			skip
	end,
    {noreply, Status};

%% 标志排队换线
handle_cast({'change_scene_sign', [SceneId, CopyId, X, Y, Value]}, Status) ->
	case lib_scene:is_dungeon_scene(Status#player_status.scene) of
		true ->
			%副本地图无法传送.
			{ok, BinData} = pt_450:write(45001, [2, 0]),
			lib_server_send:send_one(Status#player_status.socket, BinData),
			{noreply, Status};
		_ ->
			Kf3v3Ids = data_kf_3v3:get_config(scene_pk_ids),
			Kf3v3InScene = lists:member(SceneId, Kf3v3Ids),
			Kf3v3InScene2 = lists:member(Status#player_status.scene, Kf3v3Ids),

            GodIds = data_god:get(scene_id2),
            GodInScene = lists:member(SceneId, GodIds),
            GodInScene2 = lists:member(Status#player_status.scene, GodIds),
			
			if
				SceneId == 251 orelse Status#player_status.scene == 251 orelse
                Kf3v3InScene == true orelse Kf3v3InScene2 == true orelse 
                GodInScene == true orelse GodInScene2 == true ->
					NewStatus = lib_scene:change_scene(Status,SceneId,CopyId,X,Y,false),
					LastStatus = case is_list(Value) of %% 自定义结构,换场景后执行的代码
						true -> set_data_sub(Value, NewStatus);
						false ->  NewStatus
					end,
					{noreply, LastStatus};

                true -> 
                    %% 额外处理的场景
                    LoverunSceneId = data_loverun:get_loverun_config(scene_id),
                    ExtraScene = [LoverunSceneId],
                    case SceneId == Status#player_status.scene andalso lists:member(Status#player_status.scene, ExtraScene) =:= false of %% 如果已经在这个场景了就不要使用排队传送了
                        true -> {noreply, Status};
                        false -> 
                            %% 发送到排队进程
                            case lib_scene:is_clusters_scene(SceneId) of
                                true -> 
                                    Node = mod_disperse:get_clusters_node(),
                                    mod_clusters_node:apply_cast(mod_change_scene_cls_center, cls_cen_change_scene_queue, [Node, {Status#player_status.id, Status#player_status.platform, Status#player_status.server_num}, Status#player_status.pid, SceneId, CopyId, X, Y, Value]);
                                false -> 
                                    misc:get_global_pid(mod_change_scene) ! {'change_scene', Status#player_status.id, Status#player_status.pid, SceneId, CopyId, X, Y, Value}
                            end,
                            {noreply, Status#player_status{change_scene_sign = 1}}
                    end 
            end
    end;

%% 排队换线
handle_cast({'change_scene', [SceneId, CopyId, X, Y, Value]}, Status) ->
    Status1 = lib_scene:change_scene(Status, SceneId, CopyId, X, Y,true),
    NewStatus = Status1#player_status{change_scene_sign = 0},
    LastStatus = case is_list(Value) of %% 自定义结构,换场景后执行的代码
        true -> set_data_sub(Value, NewStatus);
        false ->  NewStatus
    end,
    {noreply, LastStatus};

%% 充值
handle_cast({'pay'}, Status) ->
	[NewStatus, _MailNum] = lib_recharge:pay(Status),
    %% 发送属性变化通知
	lib_player:send_attribute_change_notify(NewStatus, 4),
	{noreply, NewStatus};

%% 发送南天门奖励
handle_cast({'send_wubianhai_award', [GoodsPid, AwardIdList, Tid, Id, Exp, Lilian]}, Status) ->
    Times = lib_multiple:get_multiple_by_type(10, Status#player_status.all_multiple_data),
    NewAwardIdList = times_award(Times, AwardIdList, AwardIdList),
	lib_wubianhai_new:send_award(GoodsPid, NewAwardIdList, Tid, Id),
	NewStatus1 = lib_player:add_exp(Status, Exp * Times),
	NewStatus2 = lib_player:add_pt(llpt, NewStatus1, Lilian * Times),
    mod_active:trigger(Status#player_status.status_active, 2, 0, Status#player_status.vip#status_vip.vip_type),
	{noreply, NewStatus2};

%% 南天门杀怪处理
handle_cast({'wubianhai_kill_mon', MonId}, Status) ->
    lib_wubianhai_new:kill_mon(Status, MonId),
	{noreply, Status};

%% 南天门杀怪处理
handle_cast({'wubianhai_team_kill_mon', MonId}, Status) ->
    mod_wubianhai_new:kill_mon(Status#player_status.id, MonId),
    lib_wubianhai_new:refresh_task(Status#player_status.scene, Status#player_status.id),
	{noreply, Status};

%% 南天门结束，把玩家踢出
handle_cast({'wubianhai_end', _}, Status) ->
    {ok, wubianhai, NewStatus2} = pp_wubianhai:handle(64002, Status, [2, 1, 1]),
    mod_scene_agent:update(wubianhai, NewStatus2),
	{noreply, NewStatus2};

%% 南天门：给玩家加Buff
handle_cast({'add_wubianhai_buff'}, Status) ->
    lib_wubianhai_new:server_cast_add_buff(Status);

%% 南天门：删除玩家Buff
handle_cast({'del_wubianhai_buff'}, Status) ->
	lib_wubianhai_new:server_cast_del_buff(Status);

%% 南天门内添加三职业Buff
handle_cast({'wubianhai_is_three_career'}, Status) ->
	%% 队伍人数、是否为三职业
	%% 判断是否三职业
	case is_pid(Status#player_status.pid_team) of
		true ->
			TeamState = gen_server:call(Status#player_status.pid_team, 'get_team_state'),
			case lib_team:is_three_career(TeamState) of
				true -> 
					{noreply, NewStatus} = lib_wubianhai_new:server_cast_add_buff(Status),
					{noreply, NewStatus};
				false -> {noreply, Status}
			end;
		false -> {noreply, Status}
	end;

%% 删除南天门组队Buff
handle_cast({'del_wubianhai_team_buff'}, Status) ->
	case is_pid(Status#player_status.pid_team) of
		true ->
			TeamState = gen_server:call(Status#player_status.pid_team, 'get_team_state'),
			lib_wubianhai_new:del_wubianhai_buff(TeamState),
			{noreply, Status};
		false -> {noreply, Status}
	end;

%% 诛妖贴被领取奖励
handle_cast({'task_zyl_reward', Bcoin, Exp}, Status) ->       
	NewStatus1 = lib_player:add_coin(Status, Bcoin),
	NewStatus2 = lib_player:add_exp(NewStatus1, Exp),
    lib_player:refresh_client(NewStatus2#player_status.id, 2), %% 更新背包
    {noreply, NewStatus2};

%% 绑定称号
handle_cast({'bind_design', [RoleId, DesignId, ReplaceContent]}, Status) ->
    lib_designation:bind_design(RoleId, DesignId, ReplaceContent, 0),
    {noreply, Status};

%% 移除称号
handle_cast({'remove_design', [_RoleId, DesignId]}, Status) ->
    NewStatus = lib_designation:remove_design_on_my_process(Status, DesignId),
    {noreply, NewStatus};

%% 限时名人堂（活动）成为雕像
handle_cast({'fame_limit_be_statue', Type}, Status) ->
	lib_fame_limit:make_master(Type, Status),
	{noreply, Status};

%% [通用]活动结束，把玩家踢出活动场景
handle_cast({'leave_scene', ActivityType, _Arg}, Status) ->
	if
		ActivityType =:= hotspring ->
    		{ok, NewStatus} = pp_hotspring:handle(33002, Status, leave_scene),
			{noreply, NewStatus};
		true ->
			{noreply, Status}
	end;

%% 完成加入帮派任务
handle_cast({'finish_join_guild_task_unite'}, Status) ->
	lib_task:event(Status#player_status.tid, join_guild, do, Status#player_status.id),
    {noreply, Status};

%% ------------------------------------好友-----------------------------------------begin
handle_cast({'del_rela_for_divorce', [BId]}, Status) ->
    Relas = lib_relationship:load_relas(Status#player_status.pid,Status#player_status.id),
    case [R||R<-Relas,R#ets_rela.idA=:=Status#player_status.id,R#ets_rela.idB=:=BId] of
	[] -> [];
	[Rela]->
	    DRelas = lists:delete(Rela, Relas),
	    lib_relationship:setRelas(Status#player_status.pid,DRelas)
    end,
    {noreply, Status};
handle_cast({'ack_add_rela', [AId,_Type,Result]}, Status) ->
    lib_relationship:ack_add_rela(Status, [AId,_Type,Result]),
    {noreply, Status};
handle_cast({'cancel_closely', [AId]}, Status) ->
    lib_relationship:update_closely(Status#player_status.pid, Status#player_status.id, AId, 0),
    pp_relationship:handle(14003, Status, [1]),
    {noreply, Status};
handle_cast({'ack_add_closely_rela', [AId,Result]}, Status) ->
    lib_relationship:ack_add_closely_rela(Status, [AId,Result]),
    {noreply, Status};
%% handle_cast({'update_user_friend_lv', Id, V}, Status) ->
%%     lib_relationship:update_user_info_by_in_4_lv(Id, V),
%%     {noreply, Status};
%%好友升级祝福通知
handle_cast({'bless_notice_handle', IdB, Nick, Lv, Sex, Career, Image, Realm, TheDate}, Status) ->
    if
	20 =< Status#player_status.lv-> %20级以上玩家收到
	    Bless = Status#player_status.bless,
	    if
		TheDate =:= Bless#status_bless.bless_send_last_time -> %同一天
		    if
			%%超出最大祝福数
			?MAX_BLESS_SEND =< Bless#status_bless.bless_send -> void;
			true->
			    {ok,BinData} = pt_140:write(14015, [IdB,Nick,Lv,Sex,Career,Image,Bless#status_bless.bless_send,Realm]),
			    lib_server_send:send_to_uid(Status#player_status.id, BinData)	
		    end;
		true->
		    {ok,BinData} = pt_140:write(14015, [IdB,Nick,Lv,Sex,Career,Image,0,Realm]),
		    lib_server_send:send_to_uid(Status#player_status.id, BinData)	
	    end;
	true->
	    void
    end,
    {noreply, Status};
%% ------------------------------------好友-----------------------------------------end

%% 爱情长跑中同步男女玩家坐标
handle_cast({'update_parner_xy', X, Y, Fly}, Status) ->
    mod_scene_agent:move(X, Y, Fly, Status),
    NewStatus = Status#player_status{x = X, y = Y},
    {noreply, NewStatus};

%% 爱情长跑结束，把玩家踢出
handle_cast({'loverun_end', _}, Status) ->
    %io:format("loverun_end~n"),
    pp_loverun:handle(34303, Status, [2, 1]),
	{noreply, Status};

%% 神炉领奖
handle_cast({'furnaceback', Bcoin}, Status) ->
	NewStatus1 = lib_player:add_coin(Status, Bcoin),
	log:log_produce(guild_furnaceback, coin, Status, NewStatus1, "Guild_FurnaceBack"),
	lib_player:refresh_client(Status#player_status.id, 2),
	{noreply, NewStatus1};

%% 刷新每日福利
handle_cast({'refresh_daily_welfare'}, Status) ->
	pp_login_gift:handle(31204, Status, no),
	{noreply, Status};

%% 刷新同步帮派等级
handle_cast({guild_upgrade, Newlevel}, Status) ->
	Gs = Status#player_status.guild,
	PlayerStatus1 = Status#player_status{guild=Gs#status_guild{guild_lv = Newlevel}},
	{noreply, PlayerStatus1};

%% 抢帮派水晶
handle_cast({'factionwar_stone', Stone}, Status) ->
    PlayerStatus1 = lib_factionwar:add_stone(Status, Stone, 2),
    {noreply, PlayerStatus1};

%% 邮件封号检查
handle_cast(mail_ban_check, Status) ->
    mod_mail_check:mail_ban_check(Status),
    {noreply, Status};

%% 更改帮派联盟关系 
handle_cast({guild_rela, FList, EList}, Status) ->
    mod_scene_agent:update(guild_rela, [Status#player_status.id, Status#player_status.scene, FList, EList]),
	NewS = Status#player_status{guild_rela = {FList, EList}},
    {noreply, NewS};

%% 发送系统贺卡
handle_cast({'sys_send_festivial_card'}, Status)  ->
	lib_festival_card:sys_send_festivial_card(Status),	
    {noreply, Status};

%% 校验活动消费额
handle_cast({'adjuest_expenditure_for_houtai', [Expenditure, Time]}, Status)  ->
	lib_activity:adjuest_expenditure(Status#player_status.id, Expenditure, Time),
    {noreply, Status};

%% 激活完成充值任务
handle_cast({'finish_pay_task_houtai', [TaskId]}, Status)  ->
	mod_task:finish_pay_task_forhoutai(Status, TaskId),
    {noreply, Status};

%% VIP副本杀怪处理
handle_cast({'vip_dun_kill_mon', MonId}, Status) ->
    lib_vip_dun:kill_mon(Status, MonId),
	{noreply, Status};


%% 装备副本抽奖处理
handle_cast({'equip_give_goods', GoodsList, TotalCoin, TotalBGold, DunName, Type}, Status) ->
    GoodsLen = length(GoodsList),
    Goods = Status#player_status.goods,
    CellNum = gen_server:call(Goods#status_goods.goods_pid, {'cell_num'}),
    if
        GoodsLen =:= 0 ->
            skip;
        true ->
            if
                CellNum > GoodsLen ->
                    gen_server:call(Goods#status_goods.goods_pid, {'give_more', Status, GoodsList});
                true ->
                    if
                        Type =:= 1 ->
                            Title = data_dungeon_text:get_equip_config(title),
                            Content1 = data_dungeon_text:get_equip_config(content),
                            Content = io_lib:format(Content1, [DunName]),
                            [{goods, GoodId, Num, _Bind}] = GoodsList,
                            lib_equip_energy_dungeon:send_good_mail(Status#player_status.id, Title, Content, GoodId, Num);
                        Type =:= 2 ->
                            Title = data_dungeon_text:get_equip_config(title1),
                            Content1 = data_dungeon_text:get_equip_config(content1),
                            Content = io_lib:format(Content1, [DunName]),
                            lists:foreach(fun({goods, GoodId, Num, _Bind}) ->
                                              lib_equip_energy_dungeon:send_good_mail(Status#player_status.id, Title, Content, GoodId, Num)
                                          end, GoodsList)
                    end
            end
    end,
    if
        TotalCoin > 0 andalso TotalBGold > 0 ->
            NewStatus1 = lib_player:add_money(Status, TotalCoin, coin),
            log:log_produce(equip_zhuan_pan_coin, coin, Status, NewStatus1, "equip_zhuan_pan_coin"),
            NewStatus2 = lib_player:add_money(NewStatus1, TotalBGold, bgold),
            log:log_produce(equip_zhuan_pan_bgold, bgold, NewStatus1, NewStatus2, "equip_zhuan_pan_bglod");
            %% lib_player:refresh_client(NewStatus2#player_status.id, 2);
        TotalCoin > 0 ->
            NewStatus2 = lib_player:add_money(Status, TotalCoin, coin),
            log:log_produce(equip_zhuan_pan_coin, coin, Status, NewStatus2, "equip_zhuan_pan_coin");
        TotalBGold > 0 ->
            NewStatus2 = lib_player:add_money(Status, TotalBGold, bgold),
            log:log_produce(equip_zhuan_pan_bgold, bgold, Status, NewStatus2, "equip_zhuan_pan_bglod");
        true -> 
            NewStatus2 = Status
    end,
    pp_goods:handle(15010, NewStatus2, 4),
    {noreply, NewStatus2};

%% 查看别人宝石属性
handle_cast({'show_gemstone_all_attr', Sid}, Status) ->
    lib_gemstone:get_gemstone_attr_all(Status, Sid),
    {noreply, Status};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_server_cast:handle_cast not match: ~p~n", [Event]),
    {noreply, Status}.

%% 计算获得的经验.
calc_exp(Exp, Status) ->
    %会员经验
    Vip = Status#player_status.vip,
    VipCount = 
		case Vip#status_vip.vip_type of	        
	        0 -> 0;   %非会员.	        
	        1 -> 0.2; %黄金会员.	        
	        2 -> 0.3; %白金会员.        
	        3 -> 0.5; %紫金会员.
	        _ -> 0    %防出错.
	    end,

	%% 世界等级经验加成
	WorldLevelAddition = lib_rank_helper:get_world_percent(Status),

	%% 诸神经验倍数
	God_exp_rate = 0, %mod_god_state:get_god_exp_rate(),

	%% 总公式
    Exp1 = round(Exp * (1 + God_exp_rate + lib_player:get_exp_buff(Status) + WorldLevelAddition + VipCount + lib_player:get_city_war_exp_buff(Status))),

	Exp1.

times_award(1, AwardIdList, _OldAwardIdList) -> AwardIdList;
times_award(Times, AwardIdList, OldAwardIdList) ->
    times_award(Times - 1, AwardIdList ++ OldAwardIdList, OldAwardIdList).
