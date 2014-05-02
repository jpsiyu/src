%%%--------------------------------------
%%% @Module  : pp_player
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.06.13
%%% @Description:  角色功能管理
%%%--------------------------------------
-module(pp_player).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("unite.hrl").
-include("buff.hrl").
-include("butterfly.hrl").
-include("scene.hrl").

%%查询当前玩家信息
handle(13001, Status, _) ->
    lib_player_server:execute_13001(Status);

%%查询玩家信息
handle(13004, Status, Id) ->
    case lib_player:is_online_global(Id) of
        true ->
            lib_player_server:execute_13004(Status,Id),
			case Status#player_status.id =/= Id of
				true ->
					{ok, BinData} =pt_130:write(13066, [Status#player_status.sex, Status#player_status.nickname]),
					lib_server_send:send_to_uid(Id, BinData);
				false -> skip
			end;			
        false ->
            {ok, BinData} = pt_130:write(13004, []),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end;

%%请求快捷栏
handle(13007, Status, _) ->
    {ok, BinData} = pt_130:write(13007, Status#player_status.quickbar),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%%保存快捷栏
handle(13008, Status, [T, S, Id]) ->
    {ok, BinData} = pt_130:write(13008, 1),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    Quickbar = lib_player:save_quickbar([T, S, Id], Status#player_status.quickbar),
    Status1 = Status#player_status{quickbar= Quickbar},
    {ok, Status1};

%%删除快捷栏
handle(13009, Status, T) ->
    {ok, BinData} = pt_130:write(13009, 1),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    Quickbar = lib_player:delete_quickbar(T, Status#player_status.quickbar),
    Status1 = Status#player_status{quickbar= Quickbar},
    {ok, Status1};

%%替换快捷栏
handle(13010, Status, [T1, T2]) ->
    {ok, BinData} = pt_130:write(13010, 1),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    Quickbar = lib_player:replace_quickbar(T1, T2,  Status#player_status.quickbar),
    Status1 = Status#player_status{quickbar= Quickbar},
    {ok, Status1};

%%更新客户端
handle(13011, Status, _)->
    lib_player:send_attribute_change_notify(Status, 1),
    {ok, Status};

%%切换PK状态
handle(13012, Status, [ID]) ->
	%% BOSS场景可以切换除和平以外的所有方式
	%% 0和平 1全体 2国家 3帮派 4队伍 5善恶 6阵营(竞技场等特殊场景) 7幽灵(和平状态)
	%获取要传送地图场景数据.
    %% 客户端发过来的协议只能切换0-5模式，6、7由服务端调用
    if 
        ID >= 0 andalso ID =< 5 ->
            PresentScene = 
            case data_scene:get(Status#player_status.scene) of
                [] -> 
                    #ets_scene{};
                SceneData ->
                    SceneData
            end,
            %% Boss场景PK状态限制
            case PresentScene#ets_scene.type =:= ?SCENE_TYPE_BOSS andalso ID =/= 2 andalso ID =/= 3 of
                true -> 
                    %通知本人
                    Pk = Status#player_status.pk,
                    {ok, BinData1} = pt_130:write(13012, [8,Pk#status_pk.pk_status,0]),
                    lib_server_send:send_to_sid(Status#player_status.sid, BinData1),
                    ok;
                false ->
                    {_,ErrorCode,_,_,NewStatus} = lib_player:change_pkstatus(Status, ID),
                    case ErrorCode of
                        0 ->
                            {ok, NewStatus};
                        _ ->
                            ok
                    end
            end;
        true -> skip
    end;

%%获取Buff列表
handle(13014, Status, _) ->
    case Status#player_status.player_buff of
    %case buff_dict:match_one(Status#player_status.id) of
        [] -> skip;
        BuffList ->
            NowTime = util:unixtime(),
            SceneId = Status#player_status.scene,
            NewBuffList = [BuffInfo || BuffInfo <- BuffList, BuffInfo#ets_buff.end_time > NowTime,
                                BuffInfo#ets_buff.scene =:= [] orelse lists:member(SceneId, BuffInfo#ets_buff.scene)],
            lib_player:send_buff_notice(Status, NewBuffList)
    end;

%%buff消失时调用
handle(13015, Status, Id) ->
	case is_integer(Id) andalso Id > 0 of
		true ->
            case lib_buff:lookup_id(Status#player_status.player_buff, Id) of
			%case buff_dict:lookup_id(Id) of
				undefined ->
					skip;
				Buff when is_record(Buff, ets_buff) ->
					%% 蝴蝶谷使用到的buffId
					ButterflyIdList = [?BUTTERFLY_BUFF_SPEED_UP_ID, ?BUTTERFLY_BUFF_SPEED_DOWN_ID, ?BUTTERFLY_BUFF_DOUBLE_ID],
					case lists:member(Buff#ets_buff.attribute_id, ButterflyIdList) of
						true ->
							lib_butterfly_goods:invalid_buff(Status, Buff);
						_ ->
							skip
					end;
				_ ->
					skip
			end;
		_ ->
			skip
	end;

%% 获取怒气值/怒气上限
handle(13033, Status, _) ->
    lib_player:update_anger(Status),
    ok;

%% 获取血包列表
handle(13060, Status, _) ->
    List = lib_hp_bag:get_bag_list(Status#player_status.id),
    {ok, BinData} = pt_130:write(13060, List),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%% 血包回复
handle(13061, Status, Type) ->
    Data = case lib_hp_bag:is_bag(Type) of
                false -> 
                    %% lib_hp_bag:reply_hm(Status, Type);
                    {fail, 3};
                true -> 
                    lib_hp_bag:reply(Status, Type)
           end,
    case Data of
        {fail, Res} ->
            {ok, BinData} = pt_130:write(13061, [Res, Type, 0, 0, 0, 0]),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        {ok, NewPlayerStatus, Goods_id, Bag_num, Span} ->
            {ok, BinData} = pt_130:write(13061, [1, Type, Goods_id, Bag_num, Span, NewPlayerStatus#player_status.mp]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            case NewPlayerStatus#player_status.hp =/= Status#player_status.hp 
                orelse NewPlayerStatus#player_status.mp =/= Status#player_status.mp of
                true ->
                    {ok, BinData1} = pt_120:write(12009, [NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.platform, NewPlayerStatus#player_status.server_num, NewPlayerStatus#player_status.hp, NewPlayerStatus#player_status.hp_lim]),
                    lib_server_send:send_to_area_scene(NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.copy_id, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, BinData1),
                    {ok, hp_mp, NewPlayerStatus};
                false -> 
                    {ok, NewPlayerStatus}
            end;
        _ ->
            {ok, BinData} = pt_130:write(13061, [0, Type, 0, 0, 0, 0]),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end;

handle(13201, PS, _) ->
    case lib_server_dict:fly_prop() of
        [] ->
            skip;
        {FlyStatus, GoodsTypeId, FlyMountId, FlyMountSpeed, Permanent, TriggerTime, LeftTime, LastGoodsTypeId} ->
            if
                FlyStatus == 0 ->
                    case lib_fly_mount:can_fly(PS) of
                        true ->
                            if
                                FlyStatus == 0 ->
                                    case GoodsTypeId>0 andalso (Permanent ==1 orelse LeftTime >0) of
                                        true ->
                                            Mou = PS#player_status.mount,
                                            PS1 = lib_player:count_player_speed(PS#player_status{mount=Mou#status_mount{fly_mount = FlyMountId, fly_mount_speed = FlyMountSpeed}}),
                                            Mou1 = PS1#player_status.mount,
                                            lib_fly_mount:send_fly_mount_notify(PS1#player_status.id, PS1#player_status.platform, PS1#player_status.server_num, PS1#player_status.speed, Mou1#status_mount.fly_mount, PS1#player_status.scene, PS1#player_status.copy_id, 1, LeftTime),
                                            NewFlyStatus = 1,
                                            lib_server_dict:fly_prop({NewFlyStatus, GoodsTypeId, FlyMountId, FlyMountSpeed, Permanent, util:unixtime(), LeftTime, LastGoodsTypeId}),
                                            {ok, BinData} = pt_130:write(13201, [1]),
                                            lib_server_send:send_to_sid(PS#player_status.sid, BinData),
                                            {ok, PS1};
                                        false ->
                                            skip
                                    end;
                                true ->
                                    skip
                            end;
                        false ->
                            %% 该场景不能飞行
                            {ok, BinData} = pt_130:write(13201, [0]),
                            lib_server_send:send_to_sid(PS#player_status.sid, BinData)
                    end;
                true ->
                    %% 下飞行坐骑
                    NewFlyStatus = 0,
                    lib_server_dict:fly_prop({NewFlyStatus, GoodsTypeId, FlyMountId, FlyMountSpeed, Permanent, 0, LeftTime-util:unixtime()+TriggerTime, LastGoodsTypeId}),
                    lib_fly_mount:send_fly_mount_notify(PS#player_status.id, PS#player_status.platform, PS#player_status.server_num, PS#player_status.speed, 0, PS#player_status.scene, PS#player_status.copy_id, 0, 0),
                    {ok, BinData} = pt_130:write(13201, [2]),
                    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
            end
                    
    end;

%% add by xieyunfei
%% 体力值每个小时加一点
handle(13030, Status, []) ->
    %%io:format("handle MODULE:~p LINE:~p Value:~p ~n",[?MODULE,?LINE,13030]),
    {Refresh,NewStatus} = lib_physical:check_physical(Status),
    %%io:format("MODULE:~p LINE:~p Refresh:~p ~n",[?MODULE,?LINE,Refresh]),
    {ok, BinData} = pt_130:write(13030, Refresh),
    lib_server_send:send_one(NewStatus#player_status.socket, BinData),
    {ok, NewStatus};

%% add by xieyunfei
%% 获得角色体力信息
handle(13031, Status, []) ->
	%%io:format("handle MODULE:~p LINE:~p Value:~p ~n",[?MODULE,?LINE,13031]),
    [PhysicalCount,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,_CumulateTime,CostGold] = lib_physical:get_player_physical_data(Status),
	%%io:format("MODULE:~p LINE:~p Value:~p ~n",[?MODULE,?LINE,_Print]),
    {ok, BinData} = pt_130:write(13031, [PhysicalCount,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,CostGold]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, Status};



%% add by xieyunfei
%% 加速清除冷却时间，加一点体力值。
handle(13032, Status, []) ->
    %%io:format("handle MODULE:~p LINE:~p Value:~p ~n",[?MODULE,?LINE,13032]),
    [IsAccelerat,NewStatus] = lib_physical:accelerat(Status),
    %%io:format("MODULE:~p LINE:~p IsAccelerat:~p  NewStatus:~p ~n",[?MODULE,?LINE,IsAccelerat,NewStatus]),
    {ok, BinData} = pt_130:write(13032, IsAccelerat),
    lib_server_send:send_one(NewStatus#player_status.socket, BinData),
    case IsAccelerat =:= 1 of
        true ->
            [PhysicalCount,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,_CumulateTime,CostGold] = lib_physical:get_player_physical_data(NewStatus),
            {ok, PhysicalBinData} = pt_130:write(13031, [PhysicalCount,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,CostGold]),
            lib_server_send:send_one(NewStatus#player_status.socket, PhysicalBinData);
        false ->
            skip
    end,
    {ok, NewStatus};

%% 上线获取技能
handle(13034, Status, []) ->
    if
        Status#player_status.scene == 234 -> 
            {ok, BinData} = pt_130:write(13034, [1, [{1, 501001}, {1, 501002}, {1, 501003}]]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            Status#player_status.copy_id ! {'del_kingdom_skill', 3, Status#player_status.id},
            ok;
        Status#player_status.scene == 235 -> 
            {ok, BinData} = pt_130:write(13034, [1, [{1, 502001}, {1, 502002}, {1, 502003}]]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            Status#player_status.copy_id ! {'del_kingdom_skill', 3, Status#player_status.id},
            ok;
        true -> ok
    end;

%% 请求充值
handle(13051, Status, get_pay) ->
	case catch lib_recharge:pay(Status) of
		[NewStatus, _]  ->	     
			%% 发送属性变化通知
			lib_player:send_attribute_change_notify(NewStatus, 4),
			{ok, NewStatus};
		R->
			util:errlog("13051, pay, recharge :  error = ~p~n", [R]),
			%% 关闭socket 
			lib_server_send:send_to_sid(Status#player_status.sid, close)
	end;

%% 变性
handle(13065, Status, _) ->
    {Res, NewStatus, _NewId} = lib_marriage:changesex(Status),
    {ok, BinData} = pt_130:write(13065, [Res]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, equip, NewStatus};

%% 头像信息
handle(13067, Status, _) ->
	Data = lib_player:get_player_image_data(Status),	
    {ok, BinData} = pt_130:write(13067, Data),
	lib_server_send:send_one(Status#player_status.socket, BinData);

%% 切换头像
handle(13068, Status, [ImageId, ImageType]) ->	
	Daily_num_config = data_image:image_config(dialy_num),
	Daily_num = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5700),
	case ImageId =/= Status#player_status.image of
		true ->
			ResultCode = lib_player:change_player_image(Status, ImageId, ImageType),
			case ResultCode of
				0 ->
					NewStatus = Status#player_status{image= ImageId},
					mod_scene_agent:update(change_image, NewStatus), 
					{ok, BinDataF} = pt_120:write(12003, NewStatus),
					lib_server_send:send_to_area_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, BinDataF),
					lib_player:send_attribute_change_notify(NewStatus, 5),
					%% 头像同步到公共线
					lib_player:update_unite_info(NewStatus#player_status.unite_pid, [{image, ImageId}]),
					%% 头像同步到组队
					lib_team:update_team_info(NewStatus#player_status.pid_team),
					lib_guild:fix_guild_member_image_s(NewStatus#player_status.id, ImageId);					
				_ ->
					NewStatus = Status
			end;
		false ->
			ResultCode = 0,
			NewStatus = Status
	end,	
	LeftNum = Daily_num_config - Daily_num,
	{ok, BinData} = pt_130:write(13068, [ResultCode, LeftNum]),
	lib_server_send:send_one(NewStatus#player_status.socket, BinData),	
	{ok, NewStatus};

%% 使用朱颜果道具
handle(13069, Status, [ImageId]) ->
	ResultCode = lib_player:activate_player_image(Status, ImageId),
	case ResultCode of
		0 ->
			Special_image = Status#player_status.special_image,
			Special_image2 = [ImageId|Special_image],
			NewStatus = Status#player_status{special_image= Special_image2},
			handle(13067, NewStatus, []);
		_ ->
			NewStatus =Status
	end,
	{ok, BinData} = pt_130:write(13069, [ResultCode]),
	lib_server_send:send_one(NewStatus#player_status.socket, BinData),
	{ok, NewStatus};

%% 修改/查询玩家配置
handle(13070, Status, [Type, List]) ->
    {Res, SysConf} = if
        Type == 0 -> %% 请求
            {1, Status#player_status.sys_conf};
        Type == 1 -> %% 修改
            NewSysConf = lib_player:set_sys_conf(List, Status#player_status.sys_conf),
            {1, NewSysConf};
        true -> %% 错误类型
            {0, Status#player_status.sys_conf}
    end,
    {ok, BinData} = pt_130:write(13070, [Res, SysConf]),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, Status#player_status{sys_conf = SysConf}};

handle(13081, Status, PlayerId) ->
    case PlayerId =:= Status#player_status.id of 
        true ->
            Err = 3,
            NewNum = 0, 
            {ok, BinData} = pt_130:write(13081, [Err, NewNum]),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        false ->
            lib_player:update_player_info(PlayerId, [{increment_praise, [Status#player_status.id, Status#player_status.nickname]}])
    end,
    ok;

%% 获取个人照片
handle(13083, Status, Picture) ->
    Sql = io_lib:format(<<"update player_low set picture = '~s' where id = ~p">>, [Picture, Status#player_status.id]),
    db:execute(Sql),
    NewStatus = Status#player_status{picture = Picture},
    Res = 1,
    {ok, BinData} = pt_130:write(13083, [Res, Picture]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    %handle(13001, NewStatus, no),
    {ok, NewStatus};

%% 设置GPS经纬度
handle(13084, Status, [Longitude, Latitude]) when is_integer(Longitude) andalso is_integer(Latitude) -> 
    {ok, BinData} = pt_130:write(13084, 1),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
    mod_disperse:cast_to_unite(lib_relationship, update_user_rela_info, [Status#player_status.id, Status#player_status.lv, Status#player_status.vip#status_vip.vip_type, Status#player_status.nickname, Status#player_status.sex, Status#player_status.realm, Status#player_status.career, 1, Status#player_status.scene, Status#player_status.last_login_time, Status#player_status.image, Status#player_status.longitude, Status#player_status.latiude]),
    {ok, Status#player_status{longitude=Longitude, latiude=Latitude}};

handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_player no match", []),
    {error, "pp_player no match"}.
