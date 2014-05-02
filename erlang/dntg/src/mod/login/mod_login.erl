%%%-----------------------------------
%%% @Module  : mod_login
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.06.14
%%% @Description: 登陆模块
%%%-----------------------------------
-module(mod_login).
-export([
        login/2, 
        logout/1, 
        stop_player/1, 
        stop_all/0, 
        send_msg/1, 
        unite_login/2,
        save_online/1,
		save_online/2,
        check_unite_online/2
    ]).
-include("common.hrl").
-include("record.hrl").
-include("server.hrl").
-include("unite.hrl").
-include("goods.hrl").
-include("buff.hrl").
-include("sql_rank.hrl").
-include("marriage.hrl").
-include("scene.hrl").

%%用户登陆
login(do, [Id, Ip, Socket])  ->
    %% 检查用户登陆和状态已经登陆的踢出出去
    check_player(Id),
    {ok, Pid} = mod_server:start(),
    Time = util:unixtime()+1,
    %%更新
    case lib_login:update_login_data(Id, Ip, Time) of
        1 -> %%登陆启动
            case catch server_login([Id, Socket, Time, Pid]) of
                {'EXIT', _R1} ->
                    catch util:errlog("login error :~p", [_R1]),
                    {error, 0};
                _R2 ->
                    %% 登录日志
                    log:log_login(Id, Ip),
                    {ok, Pid}
            end;
        _Error ->
            {error, 0}
    end;

%%登陆检查入口
%%Data:登陆验证数据
%%Arg:tcp的Socket进程,socket ID
login(start, [Id, Accname, Ip, Socket]) ->
    case lib_login:get_player_login_by_id(Id) of
        [] ->
            {error, 0};
        [Aname, Status] ->
            case Status of
                0 -> %%正常
                    case binary_to_list(Aname) =:= Accname of
                        true ->
                            login(do, [Id, Ip, Socket]);
                        false ->
                            {error, 0}
                    end;
                1 -> %% 封号
                    {error, 6};
                2 -> %% 买卖元宝封号
                    {error, 7};
                3 -> %% 不正当竞争封号
                    {error, 8};
                _ -> %% 状态不正常 
                    {error, 9}
            end
    end;

login(_R, _S) ->
    {error, 0}.

%%检查用户是否登陆了
check_player(Id) ->
    case lib_player:get_pid_by_id(Id) of
        false ->
			check_dets(Id);
        Pid ->
            login_outside(Id, Pid),
            mod_disperse:cast_to_unite(mod_login, check_unite_online, [Id, 0]), 
            timer:sleep(2000)
    end.

%% 检查dets是否回写
check_dets(Id) ->
	case mod_dets:lookup(?DETS_PLAYER_STATUS, Id) of
		[PS] ->
			case catch logout(PS) of
				{'EXIT', R} ->
					util:errlog("logout check_dets:~p~n", [R]);
				_ ->
					skip
			end;
		_ ->
			skip
	end.

login_outside(Id, Pid) ->
    %通知客户端账户在别处登陆
    {ok, BinData} = pt_590:write(59004, 5),
    lib_server_send:send_to_uid(Id, BinData),
    %% 关闭socket
    %lib_server_send:send_to_uid(Id, close).
    logout(Pid),
    ok.

%% 把玩家踢出去
stop_player(PlayerId) ->
    case lib_player:get_pid_by_id(PlayerId) of
        false -> skip;
        Pid -> logout(Pid)
    end.

%% 把所有在线玩家踢出去
stop_all() ->
    mod_ban:ban_all(),
    do_stop_all(ets:tab2list(?ETS_ONLINE)).

%% 让所有玩家自动退出
do_stop_all([]) ->
    ok;
do_stop_all([H | T]) ->
    {ok, BinData} = pt_590:write(59004, 9),
	lib_server_send:send_to_uid(H#ets_online.id, BinData),
    %% 关闭socket
    lib_server_send:send_to_sid(H#ets_online.sid, close),
    timer:sleep(50),
    do_stop_all(T).

%%退出登陆
logout(Pid) when is_pid(Pid) ->
    case misc:is_process_alive(Pid) of
        true ->
            mod_server:stop(Pid);
        false ->
            skip
    end;

%%退出游戏系统
logout(PS) when is_record(PS, player_status)->
	%% 更新离线时间------
	TimeLogout = util:unixtime()+1,
	


    %%删除ETS记录
    ets:delete(?ETS_ONLINE, PS#player_status.id),

    %%玩家离开场景
    lib_scene:leave_scene(PS),
    mod_dets:insert(?DETS_PLAYER_STATUS, PS),

    %% add by xieyunfei
	%% 下线时候保存角色体力值和冷却倒计时
	lib_physical:write_player_physical(PS),

    %%清理宠物模块
    lib_pet:role_logout(PS#player_status.id, PS#player_status.last_login_time),
    lib_dict:stop(pet),

    %% 更新好友ets中自己的信息
    lib_relationship:send_online_change(PS#player_status.pid, PS#player_status.id, 0),
    mod_disperse:cast_to_unite(lib_relationship, update_user_rela_info, [PS#player_status.id, PS#player_status.lv, PS#player_status.vip#status_vip.vip_type, PS#player_status.nickname, PS#player_status.sex, PS#player_status.realm, PS#player_status.career, 0, PS#player_status.scene, PS#player_status.last_login_time, PS#player_status.image, PS#player_status.longitude, PS#player_status.latiude]),

    Sit = PS#player_status.sit,
    %% 中断交易
    pp_sell:stop_sell(PS),
    %%玩家下线，如有队伍，则离开队伍
    pp_team:handle(24005, PS, offline),
    %% 清除排队换场景
    misc:get_global_pid(mod_change_scene) ! {'offline', PS#player_status.id},
    %% 清除血包
    lib_hp_bag:offline(PS#player_status.id),
	%% 目标
 	mod_target:offline(PS#player_status.status_target, PS#player_status.id),
	%% 成就
 	mod_achieve:offline(PS#player_status.achieve, PS#player_status.id),
    %% 回写已接任务
    lib_task:update_all_trigger(PS#player_status.tid, PS#player_status.id, PS),
    %% 关闭点赞进程
    mod_praise:stop(PS#player_status.praise_pid),
    %%复活
    case PS#player_status.hp of
        0 ->
            pp_battle:handle(20004, PS, [2]);
        _ ->
            ok
    end,
    %% 双修
    case Sit#status_sit.sit_down =:= 2 of
        true -> lib_sit:shuangxiu_offline(PS);
        false -> skip
    end,

	%% 特殊场景坐标处理
	Bd_1v1_Scene_id1 = data_kf_1v1:get_bd_1v1_config(scene_id1),
	Bd_1v1_Scene_id2 = data_kf_1v1:get_bd_1v1_config(scene_id2),
	Platform = config:get_platform(),
	ServerNum = config:get_server_num(),
	Node = mod_disperse:get_clusters_node(),
	if
		PS#player_status.scene =:= Bd_1v1_Scene_id1 
		  orelse PS#player_status.scene =:= Bd_1v1_Scene_id2-> %%在1v1准备区里
			mod_clusters_node:apply_cast(mod_kf_1v1,when_logout,[Platform,ServerNum,PS#player_status.id,PS#player_status.hp,
										PS#player_status.hp_lim,PS#player_status.combat_power,1]);
		true->void
	end,

	%%诸神
	God_Scene_id_flag1 = lists:member(PS#player_status.scene, data_god:get(scene_id1)),
	God_Scene_id_flag2 = lists:member(PS#player_status.scene, data_god:get(scene_id2)),
	if
		God_Scene_id_flag1 =:= true 
		  orelse God_Scene_id_flag2 =:= true-> %%在1v1准备区里
			mod_clusters_node:apply_cast(mod_god,goout,[Node,Platform,ServerNum,PS#player_status.id]);
		true->void
	end,

	%% 跨服3v3中
	case PS#player_status.scene =:= data_kf_3v3:get_config(scene_id1) 
		orelse lists:member(PS#player_status.scene, data_kf_3v3:get_config(scene_pk_ids)) of
		true ->
			mod_clusters_node:apply_cast(mod_kf_3v3, when_logout, [
				Platform, ServerNum, PS#player_status.id
			]);
		_ -> 
			skip
	end,

	{Guild_SceneId, _, _} = data_guild:get_guild_scene_info(0),
    %%关闭南天门
%% 	WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
	VipSceceId = data_vip_new:get_config(scene_id),
    VipSceceId2 = data_vip_new:get_config(scene_id2),
	LoverunId = data_loverun:get_loverun_config(scene_id),
 	{ButterflySceneId, _, _} = data_butterfly:get_scene(),
    FishId = data_fish:get_sceneid(),
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    VipDunScene = data_vip_dun:get_vip_dun_config(scene_id),
	[Scene, X, Y] = if
        %%关闭南天门
%% 		%% 判断是否在大闹天宫
%% 		PS#player_status.scene =:= WubianhaiSceneId ->
%% 			lib_wubianhai_new:login_out_wubianhai(PS);
		%% 判断是否在VIP挂机场景
		PS#player_status.scene =:= VipSceceId orelse PS#player_status.scene =:= VipSceceId2 ->
			lib_vip:login_out(PS);
        %% 判断是否在爱情长跑场景
        PS#player_status.scene =:= LoverunId ->
            mod_loverun:out_room(PS#player_status.id),
            mod_loverun:logout(PS),
            data_loverun:get_loverun_config(leave_scene2);
	    %% 判断是否在沙滩
	    PS#player_status.scene =:= 231 orelse PS#player_status.scene =:= 232 ->
		    lib_hotspring:offline(PS),
		    tuple_to_list(data_hotspring:get_outer_scene());
        %% 判断是否在帮派场景
        PS#player_status.scene =:= Guild_SceneId ->
            tuple_to_list(data_hotspring:get_outer_scene());
 		%% 判断是否在蝴蝶谷场景
        PS#player_status.scene =:= ButterflySceneId ->
			%% 房间人数减1
			mod_butterfly:change_num(PS#player_status.copy_id, -1),
            tuple_to_list(data_butterfly:get_outer_scene());
        PS#player_status.scene =:= FishId ->
            tuple_to_list(data_fish:get_outer_scene());
        %% 判断是否在攻城战场景
        PS#player_status.scene =:= CityWarSceneId ->
            lib_city_war:logout_deal(PS);
        %% 判断是否在VIP副本场景
        PS#player_status.scene =:= VipDunScene ->
            mod_vip_dun:vip_dun_logout_deal(PS#player_status.id);
        true ->
			%% 如果在玩家副本，这里将获取副本的外场景id和坐标
		    Is_In_Dungeon = lib_dungeon:get_outside_scene(PS#player_status.scene),
		    if
		        %% 判断是否在副本
		        Is_In_Dungeon =/= false ->
		            Is_In_Dungeon;
				true ->
            		[PS#player_status.scene, PS#player_status.x, PS#player_status.y]
			end
    end,

    %% 任务清除
    mod_task:stop(PS#player_status.tid),
    %% 下线每日记录器清除
    mod_daily:stop(PS#player_status.dailypid),
    %% 经验累积任务清除
    %lib_task_cumulate:offline(PS#player_status.id),
    %% 飞行系统下线保存
    lib_fly_mount:offline(PS),
    %% 委托任务清除
    %mod_task_proxy:offline(PS#player_status.id),
    %% 保存装备磨损
    Go = PS#player_status.goods,
    Dict = case gen:call(Go#status_goods.goods_pid, '$gen_call', {'get_dict'}) of
               {ok, D} ->
                   D;
               {'EXIT', _Reason} ->
                   []
           end,
    lib_goods_util:goods_offline(PS#player_status.id, Go#status_goods.equip_attrit, Dict),
    %% 关闭物品进程
    mod_goods:stop(Go#status_goods.goods_pid),
	%% =bai关闭经脉系统 B
	mod_meridian:stop(PS#player_status.player_meridian),
	%% =bai关闭经脉系统 E
    %% 关闭宝石进程
    mod_gemstone:stop(PS#player_status.gem_pid),
	%% 清空二级密码信息
	lib_secondary_password:role_logout(PS#player_status.id),
	%% 在线倒计时奖励
	lib_gift_online:offline_do_onlie_award(PS),
    %% 更新连续登录信息
    lib_login_gift:calc_days_while_logout(PS),
    lib_login_gift:cumulative_logout(PS),
    %% 保存记录---场景和位置
    PS1 = PS#player_status{scene=Scene, x = X, y=Y},
    PS2 = lib_husong:offline(PS1),
    %% 保存player_state数据
    lib_player:update_player_state(PS2),
    %% 保存高频数据
    lib_player:update_player_exp(PS2),
	db:execute(io_lib:format(<<"update `player_login` set `last_logout_time`= ~p, `online_flag`=0, `logout_time`= ~p where id = ~p">>
							 , [TimeLogout, TimeLogout, PS#player_status.id])),
	%% 删除VIP祝福BUFF
	mod_vip:logout(PS),
	%% 删除防沉迷系统信息
	ModFcm = mod_fcm:get_by_id(PS#player_status.id),
	case ModFcm of
		{_LastLoginTime, _OnLineTime, _OffLineTime, _State, _Write, _Name, _IdCardNo} -> lib_fcm:role_logout(PS#player_status.id, _LastLoginTime, _OnLineTime, _OffLineTime);
		_ -> skip
	end,
	%% 保存皇榜任务可接任务
	%% lib_task_eb:offline(PS), 
	lib_task_eb:set_active_task_eb(PS#player_status.id, lib_dict:get(active_task_eb)),
    lib_task_cumulate:server_logout(PS),
	%% 写入在线时长日常
	TimeBe = TimeLogout - PS#player_status.last_login_time,
	mod_daily_dict:plus_count(PS#player_status.id, 9000002, TimeBe),

	%% 处理当天在线时长
	LogoutDay = util:unixdate(TimeLogout),
	TodayLogoutTime = case PS#player_status.last_login_time < LogoutDay of
		true ->
			TimeLogout - LogoutDay;
		_ ->
			TimeLogout - PS#player_status.last_login_time
	end,
	mod_daily_dict:plus_count(PS#player_status.id, 9000003, TodayLogoutTime),

    %% 记录在线时长，大于三分钟的写入数据库中
    lib_login:log_all_online(PS),
	%% 钓鱼
	lib_fish:offline(PS),
	%% 捕捉蝴蝶
	lib_butterfly:offline(PS),
    %% 离开结婚场景
    lib_marriage:leave_wedding(PS),
	%% 关闭仙缘进程
	mod_xianyuan:stop(PS#player_status.player_xianyuan),
	%% 限时名人堂（活动）
	lib_fame_limit:offline(PS),
    lib_mount2:mount_offline(PS),
	%% 计算防刷积分.
	lib_anti_brush:calc_anti_brush_score(PS),
    %% 删除dets
    mod_dets:delete(?DETS_PLAYER_STATUS, PS#player_status.id),
    ok;

%%退出公共系统
logout(US) when is_record(US, unite_status)->
    %%清理帮派模块
    lib_guild:role_logout([US#unite_status.id]),
    %% 仙侣奇缘保存
    lib_appointment:offline_unite(US#unite_status.id),
    mod_chat_agent:delete(US#unite_status.id),
    ok.

%% 游戏服务器登陆
server_login([Id, Socket, LastLoginTime, Pid]) ->
	NowTime = util:unixtime(),
    %% 玩家玩家数据
    [Accname, Gm, TalkLim, TalkLimTime, Last_logout_time, _Offline_time, Talk_lim_right] = lib_player:get_player_login_data(Id),
	[NickName, Sex, Lv, Career, Realm, _GuildId, Mount_limit, HusongNpc,
        Image, Body, Feet, Picture] = lib_player:get_player_low_data(Id),
	[Gold, Bgold, Coin, Bcoin, Exp] = lib_player:get_player_high_data(Id),
	
	%%change by xieyunfei
	%%删了physical字段，physical现在变为记录，保存在`role_physical`表中
	[_Scene, _X, _Y, _Hp, Mp, Quickbar, PKValue, PkStatus, PkStatusChangeTime, HideWeapon, HideArmor, HideAcce, HideHead, HideTail, HideRing, GuildQuitLasttime, GuildQuitNum, _FixChengjiu, SitTimeLeft, SitTimeToday, Anger, SkillCd, SysConf, ShakeMoneyTime] = lib_player:get_player_state_data(Id),
    %% 血量判断
    Hp = case _Hp =< 0 of
        true -> 100;
        false -> _Hp
    end,
	[Forza, Agile, Wit, Thew, _HpBag, _MpBag, CellNum, StorageNum, Crit, Ten, Hightest_combat_power]  = lib_player:get_player_attr_data(Id),
	[Llpt, Xwpt, Fbpt, Fbpt2, Bppt, Gjpt, Mlpt, Cjpt,Whpt, GetPraise] = lib_player:get_player_pt_data(Id),
	[Vip, VipTime, _Vip_bag_flag] = lib_player:get_player_vip_data(Id),
    [_VipGrowthExp, WeekNum, LoginNum, VipGetAward] = case lib_player:get_player_vip_new_data(Id) of
        [] ->
            db:execute(io_lib:format(<<"insert into vip_info set id = ~p ON DUPLICATE KEY UPDATE id = ~p">>, [Id, Id])),
            [0, calendar:iso_week_number(), 1, 0];
        [_VipGrowthExp2, _WeekNum, _LoginNum, _VipGetAward] ->
            [_VipGrowthExp2, _WeekNum, _LoginNum, _VipGetAward];
        _VipError ->
            catch util:errlog("vip login error: ~p", [_VipError]),
            [0, calendar:iso_week_number(), 1, 0]
    end,
    case util:bitstring_to_term(_Vip_bag_flag) of
        undefined -> Vip_bag_flag = [];
        Vip_bag_flag -> skip
    end,
	[PetCapacity, PetRenameNum, PetRenameLasttime] = lib_player:get_player_pet_data(Id),
	%%加载竞技场数据
    Arena = lib_player:get_player_arena_data(Id), 
    %%加载帮战信息
    Factionwar = lib_factionwar:load_player_factionwar(Id),
	%%加载蟠桃信息
    Peach = lib_peach:load_player_peach(Id),
	%%加载消费礼包信息
	Consumption = lib_player:get_player_consumption(Id),
	%%加载本地1v1信息
	[Kf_1v1, Kf3v3] = lib_kf_1v1:load_player_kf_1v1(Id),
	%%加载诸神鄙视记录
	God = lib_god:load_player_god(Id),
    %% 修复坐标
    [Scene, X, Y] = lib_scene:repair_xy(Lv, _Scene, _X, _Y),
	%%计算离线挂机时间
	if
		Last_logout_time=<0->
			TimeNowGap = 0;
		true->
			TimeNowGap = (NowTime-Last_logout_time) div (60*60)
	end,
	if
		0<TimeNowGap->
			if
				240=<_Offline_time + TimeNowGap->
					Offline_time = 240;
				true->
					Offline_time = _Offline_time + TimeNowGap
			end,
			lib_player:update_player_login_offline_time(Id,Offline_time,NowTime);
		true-> Offline_time = _Offline_time
	end,
	%% 打开广播信息进程
    Sid = spawn_link(fun()->send_msg(Socket) end),
    misc:register(global, misc:player_send_process_name(Id, 1), Sid),
    %Sid = list_to_tuple(lists:map(
    %    fun(Wid)->
    %            SendPro = spawn_link(fun()->send_msg(Socket) end),
    %            misc:register(global, misc:player_send_process_name(Id, Wid), SendPro),
    %            SendPro
    %    end,lists:seq(1, ?SERVER_SEND_MSG))),
    %% 时装变幻
    lib_fashion_change2:init_fashion(Id),
    %% 飞行器初始化
    %%　_Flyers = lib_flyer:role_login(Pid, Id),
    %% 60级默认帮其开第一个飞行器
    %% Flyers = case Lv >= 60 andalso length(_Flyers) =< 0 of
	%%	 false -> _Flyers;
	%%	 true ->
	%%	     {_, UnlockFlyer} = gen_server:call(Pid, {'apply_call', lib_flyer, unlock_flyer_auto, [Id, 1]}),
	%%	     UnlockFlyer
	%%     end,
    %% 坐骑初始化
    MountDict = dict:new(),
    MountDict2 = lib_mount:mount_init(Id, MountDict),
    %% io:format("~p ~p MountDict2:~p~n", [?MODULE, ?LINE, MountDict2]),
    %%　坐骑幻化数据初始化    
    MountChangeDict = dict:new(),
    MountChangeDict2 = lib_mount:mount_change_init(Id, MountChangeDict),
    %% io:format("~p ~p MountChangeDict:~p~n", [?MODULE, ?LINE, MountChangeDict]),
    %% 根据玩家获取坐骑数据
    [MountId, MountFigure, MountSpeed, MountAttribute] = lib_mount:get_mount_info_by_role(Id, MountDict2),
    %% [Mount_id,Mount_figure,Mount_speed,Mount_attribute, Flyer, Flyers1] = lib_mount:get_mount_info_by_role(Id, MountDict2, Flyers, Pid),
    %% FlyerSpeed = lib_flyer:get_flying_flyer_speed(Flyers1),
    %% FlyerBaseAttr = lib_flyer:calc_flyer_base_attr(Flyers1),
    %% FlyerTrainAttr = lib_flyer:calc_flyer_train_attr(Flyers1),
    %% FlyerStarAttr = lib_flyer:calc_flyer_star_attr(Flyers1),
    %% FlyerNineStarAttr = lib_flyer:calc_nine_star_convergence_attr(Flyers1),
    %% FlyerFigure = lib_flyer:pack_flyer_figure_from_login(Flyers1),
    %% FlyerAttr = #status_flyer{
    %%   base_attr = FlyerBaseAttr,
    %%   train_attr = FlyerTrainAttr,
    %%   star_attr = FlyerStarAttr,
    %%   speed = FlyerSpeed,
    %%   figure = 0,
    %%   sky_figure = FlyerFigure,
    %%   convergence_attr = FlyerNineStarAttr
    %%  },
    %% BUFF状态初始化 
    lib_player:init_player_buff(Id),
    %% 宠物初始化
    [PetId, PetFigure, PetNimbus, PetName, PetLevel, PetAptitude, PetAttr, PetSkillAttr, PetPotentialAttr, PetAptitudeAttr, PetSkills] = lib_pet:role_login(Pid, Id, Career),
    PetFigureActivate = lib_pet:load_pet_figure_activate(Id),
    PetFigureAttr = lib_pet:filter_figure_attr(PetFigureActivate),
    PetFigureValue = lib_pet:get_figure_change_value(Id),
    %% 宠物技能刷新初始化
    [LuckyVal, BlessVal, RefreshList, RefreshBGold, RefreshGold] = lib_pet:get_refresh_skill_info(Id),
    %% 更新好友ets中自己的信息
    mod_disperse:cast_to_unite(lib_relationship, update_user_rela_info, [Id, Lv, Vip, NickName, Sex, Realm, Career, 1, Scene, Last_logout_time, Image, 0, 0]),
    lib_relationship:send_online_change(Pid, Id, 1),
    %% 获取技能
    {Skill, BattleStatus, SkillAttribute, AngerLim} = lib_skill:online(Id, Career),
    %% 物品模块
    {ok, GoodsPid} = mod_goods:start(Id, CellNum),
    GoodsStatus = gen_server:call(GoodsPid, {'get_goods_status'}),
    %% 副本数据管理模块
    {ok, DungeonDataPid} = mod_dungeon_data:start_link(),
	%% 称号
	DesignList = lib_designation:online(Id),
	%% 目标
	{ok, StatusTarget} = mod_target:online(Id),
	%% 成就
	{ok, StatusAchieve} = mod_achieve:start_link(Id),
	%% 获取所有在线礼包数据，供下面涉及到的各方法使用，不需要再查库
	_AllGiftList = lib_gift:get_all_record(Id),
    
    %% 气血初始
    lib_hp_bag:init(Id),
    %% 启动任务进程
    {ok, Tid} = mod_task:start(),
	%% 启动任务进程
    {ok, DailyPid} = mod_daily:start_link(Id),
    %% 新版VIP
    [VipGrowthExp, NewLoginNum, NewVipGetAward] = lib_vip_info:login_cul([Id, DailyPid, _VipGrowthExp, VipTime, Vip, WeekNum, LoginNum, VipGetAward]),
    OldVipGrowthLv = data_vip_new:get_growth_lv(_VipGrowthExp),
    VipGrowthLv = data_vip_new:get_growth_lv(VipGrowthExp),
    _NewVipGetAward2 = case VipGrowthLv > OldVipGrowthLv of
        true -> 
            db:execute(io_lib:format(<<"update vip_info set get_award = 0 where id = ~p">>, [Id])),
            0;
        false -> 
            NewVipGetAward
    end,
	%% 启动皇榜任务进程
	%% mod_task_eb:start(),
	%% 技能初始化
    SkillCd1 = case util:bitstring_to_term(SkillCd) of
        undefined -> [];
        Skc when is_list(Skc) -> Skc;
        _ -> []
    end,
    SkillStatus = #status_skill{
        skill_attribute = SkillAttribute,
        skill_list = Skill,
        skill_cd   = SkillCd1
    },
    %% 玩家配置
    SysConf1 =  case util:bitstring_to_term(SysConf) of
        undefined -> [];
        SysC when is_list(SysC) -> SysC;
        _ -> []
    end,
    %%启动经脉
    {ok,Player_Meridian} = mod_meridian:start(Id),
    %%vip判断
    Now = util:unixtime(),
    case Now > VipTime andalso Vip > 0 of
        true ->
            _Vip = 0,
            Vip_Time = 0,
            %通知排行榜 
            lib_vip:change_vip(Socket, Vip, Id);
        false ->
            _Vip = Vip,
            Vip_Time = VipTime
    end,
	%% 帮派初始化 
	[GuildId, GuildName, GuildPosition, GuildLv, GuildRela, Stage] = lib_guild:role_login(Id),
    %IsCityWarWin = lib_city_war:is_city_war_win(GuildId),
	GuildStatus = #status_guild{guild_id = GuildId
							   , guild_name = GuildName
							   , guild_lv = GuildLv
							   , guild_position = GuildPosition
							   , guild_quit_lasttime = GuildQuitLasttime
							   , guild_quit_num = GuildQuitNum
							   , guild_ga_stage = Stage
                               %, is_city_war_win = IsCityWarWin
                           },
	%% 帮派神兽技能初始化
	GuildAnimalSkill = lib_guild_ga:init_ga_skill(Id),
    Pet = #status_pet{
        pet_attribute   = PetAttr,
        pet_id = PetId,
        pet_figure = PetFigure,
        pet_nimbus = PetNimbus,
        pet_name = binary_to_list(PetName),
        pet_level = PetLevel,
        pet_aptitude = PetAptitude,
        pet_capacity = PetCapacity,
        pet_rename_num = PetRenameNum,
        pet_rename_lasttime = PetRenameLasttime,
        pet_potential_attribute = PetPotentialAttr,
        pet_skill_attribute = PetSkillAttr,
      pet_figure_attribute = PetFigureAttr,
      pet_aptitude_attribute = PetAptitudeAttr
    },
    Husong = #status_husong{
        husong_npc = HusongNpc
    },
	case PkStatus of
		6->T_PkStatus = 2;
		7->T_PkStatus = 3;
		8->T_PkStatus = 3;
		9->T_PkStatus = 2;
		_->T_PkStatus = PkStatus
	end,
    PK = #status_pk{
        pk_status = T_PkStatus,                      
        pk_status_change_time = PkStatusChangeTime,          
        pk_value = PKValue
    },
    %% 好友祝福
    Bless = lib_relationship:load_player_bless(Id),
	%% 是否充值，true或false
	IsPay = lib_recharge:get_total(Id) > 0,
    %% 形象转换
    Cdict = dict:new(),
    %% 衣橱
    Wardrobe = lib_fashion_change2:init_wardrobe(Id),
    %% 宝箱兑换
    _Edict = dict:new(),
    Edict = lib_box:init_exchange_record(Id, _Edict),
    %% 玩家所在服
    PlayerServerId = case db:get_row(io_lib:format(<<"select server_id from player_login where id = ~p">>, [Id])) of
        [] ->
            0;
        [_ServerId] ->
            _ServerId
    end,
    NewPlayerServerId = case PlayerServerId of
        0 ->
            util:get_server_id();
        _ -> PlayerServerId
    end,
    %% 玩家结婚信息
    %MarriageInfo = mod_marriage:get_marry_info(Id),
    %Marriage = case is_record(MarriageInfo, marriage) of
    %    true -> MarriageInfo;
    %    false -> lib_marriage:login_init_marriage([Id, Sex])
    %end, 
    %IsCruise = case Marriage#marriage.cruise_state of
    %    2 -> 1;
    %    _ -> 0
    %end,
    %MarParnerId = case Id =:= Marriage#marriage.male_id of
    %    true -> Marriage#marriage.female_id;
    %    false -> Marriage#marriage.male_id
    %end,
    %[_ParnerNickName, _ParnerSex, _ParnerLv, _ParnerCareer, _ParnerRealm, _ParnerGuildId, _ParnerMount_limit, _ParnerHusongNpc, _Image, _, _] = case lib_player:get_player_low_data(MarParnerId) of
    %    [] -> [<<>>, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    %    _AnyData1 -> _AnyData1
    %end,
    %MarParnerName = binary_to_list(_ParnerNickName),
    %MarriageTaskInfo = mod_marriage:get_marriage_task_player(Id),
    %MarriageTask = case is_record(MarriageTaskInfo, marriage_task) of
    %    true -> MarriageTaskInfo;
    %    false -> lib_marriage:login_init_task([Marriage#marriage.id, Marriage#marriage.male_id, Marriage#marriage.female_id])
    %end,
    %DivorceState = lib_marriage:get_divorce_state([Marriage, Id, Sex]),
    %Visible = case IsCruise of
    %    1 -> 1;
    %    _ -> 0
    %end,
    %StatusMarriage = #status_marriage{     %%玩家结婚信息
    %    id = Marriage#marriage.id,
    %    parner_id = MarParnerId,
    %    parner_name = MarParnerName,
    %    register_time = Marriage#marriage.register_time,
    %    wedding_time = Marriage#marriage.wedding_time,
    %    cruise_time = Marriage#marriage.cruise_time,
    %    task = MarriageTask,
    %    is_cruise = IsCruise,
    %    divorce = Marriage#marriage.divorce,
    %    divorce_state = DivorceState
    %},
    %[NewScene, NewX, NewY] = case lib_marriage:marry_state(StatusMarriage) of
    %    8 ->
    %        MarriageMonId = mod_marriage:get_mon_id(),
    %        MarriageMon = mod_scene_agent:apply_call(102, lib_mon, lookup, [102, MarriageMonId]),
    %        case is_record(MarriageMon, ets_mon) of
    %            false ->
    %                [102, 163, 222];
    %            true ->
    %                [102, MarriageMon#ets_mon.x, MarriageMon#ets_mon.y]
    %        end;
    %    _ ->
    %        [Scene, X, Y]
    %end,
    StatusMarriage = #status_marriage{},
    [NewScene, NewX, NewY] = [Scene, X, Y],
	%%仙缘初始化
    {ok,Player_xianyuan} = mod_xianyuan:start(Id),
    %% 器灵属性初始化
    QiLingAttr = lib_qiling:init_qiling_attr(Id),
	%% 世界等级额外经验加成
	WorldLevel = mod_disperse:call_to_unite(mod_rank, get_world_level, []),
    %% 攻城战buff
    %CityWarExpBuff = case db:get_row(io_lib:format(<<"select buff_week, buff_state from player_city_war where player_id = ~p limit 1">>, [Id])) of
    %    [] ->
    %        db:execute(io_lib:format(<<"insert into player_city_war set player_id = ~p">>, [Id])),
    %        [0, 0];
    %    [_BuffWeek, _BuffState] ->
    %        [_BuffWeek, _BuffState];
    %    _ ->
    %        {_Year, _NowWeekNum} = calendar:iso_week_number(),
    %        [_NowWeekNum, 1]
    %end,
    %CityWarWinNum = lib_city_war:get_city_war_win_num(),
    StatusVip = #status_vip{
        vip_type = _Vip, 
        vip_end_time = Vip_Time, 
        vip_bag_flag = Vip_bag_flag,
        growth_exp = VipGrowthExp,
        growth_lv = VipGrowthLv,
        login_num = NewLoginNum,
        get_award = NewVipGetAward
    },
    %% 登录初始化离线奖励信息
    InitOffLineAward = lib_off_line:login_init([Id, Lv, Offline_time, StatusVip]),
    %% 玩家身上的BUFF
    PlayerBuff = case buff_dict:match_one(Id) of
        BuffList when is_list(BuffList) ->
            BuffList;
        _ ->
            []
    end,
	%% add by xieyunfei
	%%登陆时候加载体力值系统的信息
	[NowPhysical,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,NowCumulateTime,WhetherUse] = lib_physical:load_player_physical(Id,DailyPid,StatusVip#status_vip.vip_type),
	StatusPhysical = #status_physical{
	physical_count = NowPhysical,
	physical_sum = PhysicalSum,
	accelerat_use = AcceleratUse,		
	accelerat_sum = AcceleratSum,		
	cd_time = CdTime,			
	cumulate_time = NowCumulateTime,
    whether_use = WhetherUse										  
	},
	
    %% 宝石系统进程
    {ok,GemPid} = mod_gemstone:start_link(),
    %% 启动点赞进程
    {ok, PraisePid} = mod_praise:start_link(),
    mod_praise:role_login(Id, PraisePid),
    TaskSrSQL = io_lib:format("select task_id,color from task_sr_bag where player_id=~p and type = ~p limit 1", [Id, 0]),
    TaskSrColor = case db:get_row(TaskSrSQL) of
        [_, TaskSrColor1] -> TaskSrColor1;
        _ -> 0
    end,
    %% 初始化在线礼包数据
    OnlineGiftRecord = lib_gift_online:load(Id, Lv),
    %% 设置mod_player 状态
    _PlayerStatus = #player_status {
        id = Id,
        sid = Sid,
        accname = binary_to_list(Accname),
        nickname = binary_to_list(NickName),
        sex = Sex,
        lv = Lv,
        scene = NewScene,
        x = NewX,
        y = NewY,
        exp = Exp,
        exp_lim = lib_player:next_lv_exp(Lv),
        hp = Hp,
        mp = Mp,
        anger = Anger,
        anger_lim = AngerLim,
        gm = Gm,
        llpt = Llpt,
        xwpt = Xwpt,
        fbpt = Fbpt,
        fbpt2 = Fbpt2,
        gjpt = Gjpt,
        mlpt = Mlpt,
		cjpt = Cjpt,
		whpt = Whpt,
        bppt = Bppt,
        talk_lim = TalkLim,
        talk_lim_time = TalkLimTime,
		talk_lim_right = Talk_lim_right,
        socket = Socket,
        last_login_time = LastLoginTime,
        pid = Pid,
        tid = Tid,
        career = Career,
        realm = Realm,
        vip = StatusVip,
        gold = Gold,
        bgold = Bgold,
        coin = Coin,
        bcoin = Bcoin,
        att_area = case Career =:= 2 of true -> 6; false -> 2 end,
        base_attribute = [Forza, Agile, Wit, Thew, Ten, Crit],
        skill = SkillStatus,
        battle_status = BattleStatus,     
        quickbar = case util:bitstring_to_term(Quickbar) of undefined -> []; Qb -> Qb end,
		pid_dungeon_data = DungeonDataPid,
        cell_num = CellNum,          
        storage_num = StorageNum,
        hp_bag=#status_hp{},
		guild=GuildStatus,
		is_pay = IsPay,
        goods=#status_goods{goods_pid = GoodsPid,
            equip_current = GoodsStatus#goods_status.equip_current,
            fashion_weapon = lib_goods_util:get_equip_fashion(Id, 61, GoodsStatus#goods_status.dict),
            fashion_armor = lib_goods_util:get_equip_fashion(Id, 60, GoodsStatus#goods_status.dict),
            fashion_accessory = lib_goods_util:get_equip_fashion(Id, 62, GoodsStatus#goods_status.dict),
            fashion_head = lib_goods_util:get_equip_fashion(Id, 63, GoodsStatus#goods_status.dict),
            fashion_tail = lib_goods_util:get_equip_fashion(Id, 64, GoodsStatus#goods_status.dict),
            fashion_ring = lib_goods_util:get_equip_fashion(Id, 65, GoodsStatus#goods_status.dict),
            equip_attribute = lib_goods_util:get_equip_affect(#player_status{id=Id}, GoodsStatus#goods_status.stren7_num, GoodsStatus#goods_status.dict),
            hide_fashion_weapon = HideWeapon,
            hide_fashion_armor = HideArmor,
            hide_fashion_accessory = HideAcce,
            hide_head = HideHead, 
            hide_tail = HideTail,
            hide_ring = HideRing,
            suit_id = GoodsStatus#goods_status.suit_id,
            stren7_num = GoodsStatus#goods_status.stren7_num,
            body_effect = Body,
            feet_effect = Feet
        },
		achieve = StatusAchieve,
		achieve_arr = lib_achieve_new:online(Id),
        mount=#status_mount{mount_speed = MountSpeed,
                            mount_attribute = MountAttribute,
                            mount = MountId,
                            mount_figure = MountFigure,
                            mount_lim = Mount_limit,
                            mount_dict = MountDict2,
                            %% flyer = Flyer,
                            change_dict = MountChangeDict2
                           },
		designation=DesignList,
        buff_attribute = lib_player:get_buff_attribute(Id, 100), %%场景号到时再初始化,暂用100
        pet = Pet,
        pet_refresh_skill = #status_pet_refresh_skill{lucky=LuckyVal,
						    bless=BlessVal,
						    refresh_list=RefreshList,
						    bgold=RefreshBGold,
						    gold=RefreshGold
						   },
        unreal_figure_activate = PetFigureActivate,
        pet_figure_value = PetFigureValue,
      	bless = Bless, %%好友祝福
		physical = StatusPhysical,
        husong = Husong,
        pk = PK,
        player_meridian = Player_Meridian,     %% 设置玩家经脉属性的PID。
		sit_time_today = SitTimeToday,		   %% 打坐时间
		sit_time_left = SitTimeLeft,			   %% 设置玩家离线打坐时间
		last_logout_time = NowTime, 	%%上一次退出游戏时间(unixtime，秒)
		offline_time=Offline_time,
		eb_next_ref_time = Now,                %% 设置皇榜任务下次刷新时间 
		status_target = StatusTarget,
		arena = Arena,
        factionwar = Factionwar,
		peach = Peach,
		consumption = Consumption,
		kf_1v1 = Kf_1v1,
		god = God,
		kf_3v3 = Kf3v3,
        change_dict = Cdict,
        exchange_dict = Edict,
        wardrobe = Wardrobe,
		status_active = mod_active:online(Id),
		dailypid = DailyPid,               		%% 玩家日常服务PID(每个玩家不一样)
		all_multiple_data = mod_multiple:get_all_data(),   % 获取所有多倍经验配置数据
        server_id = NewPlayerServerId,   %% 玩家所在服
        marriage = StatusMarriage,
        temp_dict = lib_temp_bag:init_temp_list(Id),
		player_xianyuan = Player_xianyuan,
        mergetime = lib_activity_merge:get_activity_time(),
		image = Image,
        qiling_attr = QiLingAttr,
		guild_rela = GuildRela,
		guild_ga_skill = GuildAnimalSkill,
        %% flyer_attr = FlyerAttr,
        platform = config:get_platform(),
        server_num = config:get_server_num(),
		hightest_combat_power = Hightest_combat_power,
		world_level = WorldLevel,
        sys_conf = SysConf1,
        %city_war_exp_buff = CityWarExpBuff,
        %city_war_win_num = CityWarWinNum,
        off_line_award = InitOffLineAward,
        player_buff = PlayerBuff,
        %visible = Visible,
        gem_pid = GemPid,
        shake_money_time = ShakeMoneyTime,
        praise_pid = PraisePid,
        get_praise = GetPraise,
        task_sr_colour = TaskSrColor,
        picture = Picture,
        online_award = OnlineGiftRecord
    },
    %% add by xieyunfei 测试体力值接口使用的
    pp_vip:handle(45062, _PlayerStatus, []),
    pp_player:handle(13060, _PlayerStatus, []),
    lib_fashion_change2:get_wear_degree(_PlayerStatus),
    %% 罪恶值登记
    GjptPlayerStatus = case _PlayerStatus#player_status.pk#status_pk.pk_value > 0 of
        true -> 
            mod_gjpt:player_reg(_PlayerStatus#player_status.id, _PlayerStatus#player_status.pk#status_pk.pk_value),
            %% 罪恶值大于500需要扔进监狱
            mod_gjpt:put_to_prison(_PlayerStatus);
        false -> 
            %% 罪恶值为0且在监狱中的要传送出来
            mod_gjpt:put_to_prison(_PlayerStatus)
    end,
    %% 处理攻城战buff
    %{noreply, CityWarBuffPlayerStatus} = lib_city_war:del_city_war_buff(GjptPlayerStatus),
    %% 退出攻城战场景
    %CityWarPlayerStatus = lib_city_war:login_out(CityWarBuffPlayerStatus),
    %% 退出结婚场景
    WeddingPlayerStatus = lib_marriage:login_out(GjptPlayerStatus),
    %% 退出爱情长跑场景
    LoverunPlayerStatus = lib_loverun:login_out(WeddingPlayerStatus),
    %% 功能累积初始化
    lib_task_cumulate:server_login(LoverunPlayerStatus),
	%% 退出竞技场
	Arena_PlayerStatus = lib_arena_new:login_out_arena(LoverunPlayerStatus),
	%% 退出帮战
	Factionwar_PlayerStatus = lib_factionwar:login_out_factionwar(Arena_PlayerStatus),
	%% 退出蟠桃园
	Peach_PlayerStatus = lib_peach:login_out_peach(Factionwar_PlayerStatus),
	%% 退出本服1v1
	Bd_1v1_PlayerStatus = lib_kf_1v1:login_out_bd_1v1(Peach_PlayerStatus),
	%% 退出诸神
	God_PlayerStatus = lib_god:login_out_god(Bd_1v1_PlayerStatus),
	%% 退出跨服服3v3
	Kf3v3PlayerStatus = lib_kf_3v3:reset_to_default_scene(God_PlayerStatus),
    %%关闭南天门
	%% 退出大闹天宫
%% 	Wubianhai_PlayerStatus = lib_wubianhai_new:login_in_wubianhai(Kf3v3PlayerStatus),
    %% 处理VIP祝福BUFF
	VipBuff_State = mod_vip:login_init(Kf3v3PlayerStatus),
	%% 退出VIP挂机
	VIP_PlayerStatus = lib_vip:login_in_vip(VipBuff_State),
    %% 进入某些场景需要增加buff
    SkillBuffPlayerStatus = lib_skill_buff:specail_scene_buff(VIP_PlayerStatus, VIP_PlayerStatus#player_status.scene, 0),
    %% Vip副本断线重连处理
    VipDunPlayerStatus = mod_vip_dun:re_connect(SkillBuffPlayerStatus),
    %% 退出帮派活动
    GuildDunPlayerStatus = lib_guild_dun:login_out(VipDunPlayerStatus),
	%% 初始化新的离线时间
	_PlayerStatus1 = GuildDunPlayerStatus, %% lib_sit:get_new_sit_xl_time(Arena_PlayerStatus),
    %% 初始化任务
    lib_task:flush_role_task(Tid, _PlayerStatus1),
    %% todo: 默认触发第一个任务，目前先放到这里
    case _PlayerStatus1#player_status.lv > 1 of
        true ->
            ok;
        false ->
            lib_task:trigger(Tid, 100010, _PlayerStatus1)
    end,
	%% 检查个别任务完成状态
	lib_task:login_update_all_trigger(Tid, _PlayerStatus1#player_status.id, _PlayerStatus1),
    %% 初始化皇榜任务
    lib_task_eb:online(_PlayerStatus1),
    %% 初始化平乱任务
    lib_task_sr:online(_PlayerStatus1),
    %% 初始化诛妖令任务
    lib_task_zyl:online(_PlayerStatus1),
    
    %% 上线归队
    _PlayerStatus21 = lib_team:back_to_dungeon(_PlayerStatus1),
    %% 飞行坐骑
    _PlayerStatus2 = lib_fly_mount:online(_PlayerStatus21),
    %% 护送任务
    _PlayerStatus3 = lib_husong:online(_PlayerStatus2),
    %% 计算属性
    _PlayerStatus4 = lib_player:count_player_speed(_PlayerStatus3),
    _PlayerStatus5 = lib_pet:login_add_active_skill(_PlayerStatus4, PetSkills),
	%% 初始化夫妻技能
	_PlayerStatus6 = lib_xianyuan:online(_PlayerStatus5),	
	%% 判读是否需要展现变身形象
	_PlayerStatus7 = lib_figure:get_figure_broadcast(_PlayerStatus6),
	%% 判读是否需要展现器灵形象
	_PlayerStatus8 = pp_equip:qiling_login(_PlayerStatus7),
	%% 初始化玩家特殊头像
	_PlayerStatus9 = lib_player:load_player_image(_PlayerStatus8),
    %%　修复玩家坐骑的形象
    %%　_PlayerStatus10 = lib_mount_repair:repair_mount_change(_PlayerStatus9),
    %% 初始玩家装备技能    
    _PlayerStatus11 = lib_goods_util:get_medal_skill_online(_PlayerStatus9, GoodsStatus#goods_status.dict),
    Goods = _PlayerStatus11#player_status.goods,
    _PlayerStatus12 = _PlayerStatus11#player_status{goods=Goods#status_goods{equip_attribute = lib_goods_util:get_equip_affect(_PlayerStatus11, GoodsStatus#goods_status.stren7_num, GoodsStatus#goods_status.dict)}},
    _PlayerStatus13 = lib_player:count_player_attribute(_PlayerStatus12),
    %% 检查幻化是否过期
    _PlayerStatus14 = lib_mount2:check_mount_time(_PlayerStatus13),
     %% 初始化玩家宝石栏属性
    _PlayerStatus15 = lib_gemstone:role_login(GemPid, _PlayerStatus14),    
	PlayerStatus=lib_player:count_hightest_combat_power(_PlayerStatus15),

    %% 把数据传到玩家进程里
    gen_server:cast(Pid, {'base_set_data', PlayerStatus}),
    PlayerProcessName = misc:player_process_name(Id),
    misc:register(global, PlayerProcessName, Pid),
    %%更新ETS_ONLINE在线表
    save_online(PlayerStatus),
    %% 委托任务
    %mod_task_proxy:online(PlayerStatus#player_status.tid, PlayerStatus#player_status.id),
    %% 初始化经验累积任务
    %lib_task_cumulate:online(PlayerStatus),
    %% 处理连续登录奖励和回归礼包信息
    lib_login_gift:calc_days_while_login(PlayerStatus),
    %%　初始化累积登录信息
    lib_login_gift:online(PlayerStatus#player_status.id),
	%% 战斗力更新到排行榜中
 	lib_rank_refresh:refresh_rank_online(PlayerStatus),
	%% 处理防沉迷系统信息
	lib_fcm:role_login(_PlayerStatus#player_status.id),
    %% 开服前七天发送VIP周礼包(改为玩家手动领取)
    %lib_vip:send_week_vip_gift(_PlayerStatus),
    %% 节日活动相关
    lib_qixi:save_qixi_login_continuation(_PlayerStatus#player_status.id),
    lib_qixi:get_qixi_login_continuation_award(_PlayerStatus#player_status.dailypid, _PlayerStatus#player_status.id),
    lib_qixi:update_task_from_login(_PlayerStatus#player_status.id, _PlayerStatus#player_status.dailypid),
    %% 玩家是否可改名
    spawn(fun() ->
                timer:sleep(30 * 1000),
                pp_change_name:can_change_name(_PlayerStatus#player_status.id)
        end),
	mod_dungeon_data:online(DungeonDataPid, Id),

	%% 开服七天签到礼包拿到处理
	lib_activity:seven_day_signup(_PlayerStatus#player_status.id),
	%% 运营活动登录处理
	lib_activity:process_activity_login(_PlayerStatus),
	lib_festival_card:online(_PlayerStatus),
    lib_activity_festival:send_fr_gift_auto(_PlayerStatus),
	lib_special_activity:role_login(_PlayerStatus#player_status.id),
	lib_special_activity:add_old_buck_task(_PlayerStatus#player_status.id, 1),
    
    %% 长安城主登录触发更新雕像
   % case GuildPosition =:= 1 andalso IsCityWarWin =:= 1 of
   %     true ->
   %         mod_city_war:reset_statue(_PlayerStatus);
   %     false ->
   %         skip
   % end,
    ok.

%% 公共线系统登陆
unite_login(Id, Socket) ->
    %% 检查在线
    check_unite_online(Id, 2000),
    {ok, Pid} = mod_unite:start(),
    %% 打开广播信息进程 
    Sid = spawn_link(fun()->send_msg(Socket) end),
    %Sid = list_to_tuple(lists:map(fun(_)-> spawn_link(fun()->send_msg(Socket) end) end,lists:duplicate(?UNITE_SEND_MSG, 1))),
    case lib_player:get_player_info(Id, unite) of
        PlayerStatusUnite when is_record(PlayerStatusUnite, player_status_unite) ->
            %% 初始仙侣奇缘相关信息
            NowParterId = lib_appointment:online_unite(Id),
            %% 帮派成员登陆
            lib_guild:role_login_guild(Id),
            [Talk_lim, Talk_lim_time, Talk_lim_right] = lib_chat:get_talk_lim(Id),
            case catch mod_loverun:get_begin_end_time() of
                {BeginHour, BeginMin, EndHour, EndMin, ApplyTime} -> 
                    ok;
                _Reason -> 
                    {BeginHour, BeginMin, EndHour, EndMin, ApplyTime} = lib_loverun:get_start_time()
            end,
            %% 获取队长ID.
            TeamPid = lib_player:get_player_info(Id, pid_team),
            TeamId = lib_team:get_leaderid(TeamPid),
			%% 世界等级额外经验加成
			WorldLevel = mod_rank:get_world_level(),

            UniteStatus = #unite_status{
                id = Id, 
                pid = Pid,
                name = PlayerStatusUnite#player_status_unite.name,
                team_id = TeamId,
                sex = PlayerStatusUnite#player_status_unite.sex,
                lv = PlayerStatusUnite#player_status_unite.lv,
                scene = PlayerStatusUnite#player_status_unite.scene,
                realm = PlayerStatusUnite#player_status_unite.realm,
                socket = Socket,
                career = PlayerStatusUnite#player_status_unite.career,
                guild_id = PlayerStatusUnite#player_status_unite.guild_id,
                guild_name = PlayerStatusUnite#player_status_unite.guild_name,
                guild_position = PlayerStatusUnite#player_status_unite.guild_position,
                image = PlayerStatusUnite#player_status_unite.image,
                sid = Sid,
                last_login_time = PlayerStatusUnite#player_status_unite.last_login_time,
                appointment = NowParterId,
                gm = PlayerStatusUnite#player_status_unite.gm,
                vip = PlayerStatusUnite#player_status_unite.vip,
                platform = PlayerStatusUnite#player_status_unite.platform,
                server_num = PlayerStatusUnite#player_status_unite.server_num,
                talk_lim = Talk_lim,
                talk_lim_time = Talk_lim_time,
				talk_lim_right = Talk_lim_right,
				dailypid = PlayerStatusUnite#player_status_unite.dailypid,
                loverun_data = [BeginHour, BeginMin, EndHour, EndMin, ApplyTime],
				all_multiple_data = mod_multiple:get_all_data(),   % 获取所有多倍经验配置数据
				world_level = WorldLevel,
				mergetime = lib_activity_merge:get_activity_time()
            },

            UniteProcessName = misc:unite_process_name(Id),
            misc:register(global, UniteProcessName, Pid),
            %% 写入ets
            save_online(UniteStatus, base),
            gen_server:cast(Pid, {'base_set_data', UniteStatus}),
            %% 把公共线pid更新到player_status
            lib_player:update_player_info(Id, [{unite_pid, Pid}]),

            %% 上线初始化角色邮件数据
            lib_mail:role_login(UniteStatus#unite_status.id),
            lib_secret_shop:init(UniteStatus#unite_status.id, UniteStatus#unite_status.lv),
            %% 初始化运势信息
            lib_fortune:role_login(Id),
            %% 发送战斗力排行第一传闻
			lib_rank:send_first_fight_rank_cw(UniteStatus#unite_status.id, UniteStatus#unite_status.career),

            %%     io:format("unite login ok!....~p~n", [UniteStatus#unite_status.id]),
            %%关闭南天门
            %%lib_wubianhai_new:login_send(Id, UniteStatus#unite_status.lv),
            %% 寻找唐僧活动登录显示图标
            mod_turntable:login_send(Id),
	    lib_sit:party_send(Id),
            {ok, Pid};
        _R ->
            _R
    end.

%% 是否在线
check_unite_online(Id, Time) ->
    case mod_chat_agent:lookup(Id) of
        [S] ->
            lib_unite_send:send_to_sid(S#ets_unite.sid, close);
        _ ->
            skip
    end,
    case  Time > 0 of
        true ->
            timer:sleep(2000);
        false ->
            skip
    end.

%%发消息
send_msg(Socket) ->
    receive
        {send, close} ->
            gen_tcp:close(Socket),
            send_msg(Socket);
        {send, Bin} ->
            gen_tcp:send(Socket, Bin),
            send_msg(Socket);
        _ ->
            send_msg(Socket)
    end.

%% 同步更新ETS中的角色数据
save_online(PlayerStatus) when is_record(PlayerStatus, player_status)->
    ets:insert(?ETS_ONLINE, #ets_online{
            id = PlayerStatus#player_status.id,
            sid = PlayerStatus#player_status.sid,
            pid = PlayerStatus#player_status.pid,
            tid = PlayerStatus#player_status.tid
        });

save_online(UniteStatus) when is_record(UniteStatus, unite_status)->
	case mod_chat_agent:lookup(UniteStatus#unite_status.id) of
        [] -> mod_chat_agent:insert(#ets_unite{
									            id = UniteStatus#unite_status.id,
									            pid = UniteStatus#unite_status.pid,
									            name = UniteStatus#unite_status.name,
									            sex = UniteStatus#unite_status.sex,
									            lv = UniteStatus#unite_status.lv,
									            scene = UniteStatus#unite_status.scene,
									            copy_id = UniteStatus#unite_status.copy_id,
									            team_id = UniteStatus#unite_status.team_id,
									            realm = UniteStatus#unite_status.realm,
									            career = UniteStatus#unite_status.career,
									            guild_id = UniteStatus#unite_status.guild_id,
									            guild_name = UniteStatus#unite_status.guild_name,
									            guild_position = UniteStatus#unite_status.guild_position,
									            image = UniteStatus#unite_status.image,
									            sid = UniteStatus#unite_status.sid,
									            last_login_time = UniteStatus#unite_status.last_login_time,
												gm = UniteStatus#unite_status.gm,
												vip = UniteStatus#unite_status.vip,
											    talk_lim = UniteStatus#unite_status.talk_lim,
											    talk_lim_time = UniteStatus#unite_status.talk_lim_time,
												talk_lim_right = UniteStatus#unite_status.talk_lim_right
											  }
								 );
        [R1] ->
            mod_chat_agent:insert(R1#ets_unite{
									            id = UniteStatus#unite_status.id,
									            pid = UniteStatus#unite_status.pid,
									            name = UniteStatus#unite_status.name,
									            sex = UniteStatus#unite_status.sex,
									            lv = UniteStatus#unite_status.lv,
									            scene = UniteStatus#unite_status.scene,
									            copy_id = UniteStatus#unite_status.copy_id,
									            team_id = UniteStatus#unite_status.team_id,
									            realm = UniteStatus#unite_status.realm,
									            career = UniteStatus#unite_status.career,
									            guild_id = UniteStatus#unite_status.guild_id,
									            guild_name = UniteStatus#unite_status.guild_name,
									            guild_position = UniteStatus#unite_status.guild_position,
									            image = UniteStatus#unite_status.image,
									            sid = UniteStatus#unite_status.sid,
									            last_login_time = UniteStatus#unite_status.last_login_time,
												gm = UniteStatus#unite_status.gm,
												vip = UniteStatus#unite_status.vip,
											    talk_lim = UniteStatus#unite_status.talk_lim,
											    talk_lim_time = UniteStatus#unite_status.talk_lim_time,
												talk_lim_right = UniteStatus#unite_status.talk_lim_right
											  }
								 )
    end;

save_online(R) ->
    util:errlog("save_online error :~p", [R]).



save_online(UniteStatus, base) when is_record(UniteStatus, unite_status)->
    mod_chat_agent:insert(#ets_unite{
            id = UniteStatus#unite_status.id,
            pid = UniteStatus#unite_status.pid,
            name = UniteStatus#unite_status.name,
            sex = UniteStatus#unite_status.sex,
            lv = UniteStatus#unite_status.lv,
            scene = UniteStatus#unite_status.scene,
            copy_id = UniteStatus#unite_status.copy_id,
            team_id = UniteStatus#unite_status.team_id,
            realm = UniteStatus#unite_status.realm,
            career = UniteStatus#unite_status.career,
            guild_id = UniteStatus#unite_status.guild_id,
            guild_name = UniteStatus#unite_status.guild_name,
            guild_position = UniteStatus#unite_status.guild_position,
			appointment = UniteStatus#unite_status.appointment,
            image = UniteStatus#unite_status.image,
            sid = UniteStatus#unite_status.sid,
            last_login_time = UniteStatus#unite_status.last_login_time,
			gm = UniteStatus#unite_status.gm,
			vip = UniteStatus#unite_status.vip,
			talk_lim = UniteStatus#unite_status.talk_lim,
			talk_lim_time = UniteStatus#unite_status.talk_lim_time,
			talk_lim_right = UniteStatus#unite_status.talk_lim_right
        }
    );

save_online(R, _) ->
    util:errlog("save_online base error :~p", [R]).

