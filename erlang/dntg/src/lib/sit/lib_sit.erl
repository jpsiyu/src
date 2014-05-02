%% --------------------------------------------------------
%% @Module:           |lib_sit
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-03-28
%% @Description:      |双修打坐
%% --------------------------------------------------------
-module(lib_sit).
-include("server.hrl").
-include("unite.hrl").
-include("scene.hrl").

-export([
         trans/1,									   %%|解析打坐所需要的玩家信息
         shuangxiu_invite/2,                            %%|双修邀请
         shuangxiu_respond/2,						   %%|双修邀请回应
         shuangxiu/5,								   %%|双修开始
         shuangxiu_interrupt/3,						   %%|双修中断
         shuangxiu_check/1,							   %%|双修条件检查
         shuangxiu_offline/1,						   %%|取消自身打坐----有双修就通知----offline
         sit_down/1,									   %%|打坐开始
         sit_down_reply/1,							   %%|打坐中---回复,+经验等
         sit_up/1,									   %%|打坐停止
         count_sittime/1,							   %%|计时
         get_new_sit_xl_time/1,						   %%|上线初始化离线打坐时间
         get_sit_xl_time/1,							   %%|获取离线时间
         set_sit_xl_time/2,							   %%|减少离线时间
         party_send/1,
         party_send_all/1
        ]).

%% 双修邀请
shuangxiu_invite(Status, PlayerId) ->
    SceneId1 = Status#player_status.scene,
    Sit = Status#player_status.sit,
    Mou = Status#player_status.mount,	
    if  %% 无法邀请自己本身
        Status#player_status.id =:= PlayerId ->
            {fail, 2};
        %% 自己正在双修中，无法邀请
        Sit#status_sit.sit_down =:= 2 ->
            {fail, 3};
        %% 骑着坐骑不能双修
        Mou#status_mount.mount > 0 ->
            {fail, 8};
        %% 该场景不能双修
        SceneId1 =:= 222 orelse SceneId1 =:= 992 ->
            {fail, 9};
        true ->
            case lib_player:get_player_info(PlayerId, lib_sit) of
                Player when is_record(Player, player_status_sit) ->
                    case Player#player_status_sit.sit#status_sit.sit_down =:= 2 of
                        %% 对方已在双修中，无法邀请
                        true -> {fail, 5};
                        false ->
                            case (Status#player_status.scene =:= Player#player_status_sit.scene
                                andalso abs(Status#player_status.x - Player#player_status_sit.x) =< 5
                                andalso abs(Status#player_status.y - Player#player_status_sit.y) =< 5 ) of
                                    %% 与对方距离过远，无法邀请
                                    false -> {fail, 6};
									%% 成功返回双修信息.
                                    true -> {ok, Player}
                            end
                    end;
				%% 对方不在线，无法邀请
                _ -> {fail, 4}
            end
    end.

%% 双修邀请回应
shuangxiu_respond(Status, Player) ->
    SceneId1 = Status#player_status.scene,
    Sit = Status#player_status.sit,
    Mou = Status#player_status.mount,
    if  %% 无法回应自己本身
        Status#player_status.id =:= Player#player_status_sit.id ->
            {fail, 3};
        %% 自己正在双修中，无法回应
        Sit#status_sit.sit_down =:= 2 ->
            {fail, 4};
        %% 对方已在双修中，无法加入双修
        Player#player_status_sit.sit#status_sit.sit_down =:= 2 ->
            {fail, 5};
        %% 骑着坐骑不能双修
        Mou#status_mount.mount > 0 ->
            {fail, 8};
        %% 该场景不能双修
        SceneId1 =:= 222 orelse SceneId1 =:= 992 ->
            {fail, 9};
        true ->
            case (Status#player_status.scene =:= Player#player_status_sit.scene
                andalso abs(Status#player_status.x - Player#player_status_sit.x) =< 3
                andalso abs(Status#player_status.y - Player#player_status_sit.y) =< 3 ) of
                    %% 与对方距离过远，无法加入双修
                    false -> {fail, 6};
                    true ->
		    Shuanxiu_r_call = gen:call(Player#player_status_sit.pid, '$gen_call', {'shuangxiu_recv', Status}),
                        case Shuanxiu_r_call of
                            {ok, {fail, Res}} ->
                                {fail, Res};
                            {ok, {ok, NowTime}} ->
                                NewStatus = shuangxiu(Status, Player#player_status_sit.id, Player#player_status_sit.figure, Player#player_status_sit.pid, NowTime),
                                {ok, NewStatus};
                            {'EXIT',_Reason} ->
                                 {fail, 0}
                        end
            end
    end.

%% 双修开始
%% PlayerId:  双修玩家ID
%% NowTime:   记录开始时间
shuangxiu(Status, PlayerId, PlayerFigure, PlayerPid, NowTime) ->
    %%NewStatus = gen_server:cast(Player#ets_online.pid, {'shuangxiu_interrupt', PlayerId, NowTime})
	Sit = Status#player_status.sit,
    NewStatus = Status#player_status{ sit=Sit#status_sit{sit_down = 2, sit_hp_time = NowTime, sit_exp_time = NowTime, sit_llpt_time = NowTime, sit_intimacy_time = NowTime, sit_role = PlayerId, sit_role_figure = PlayerFigure, sit_role_pid = PlayerPid} },
    mod_scene_agent:update(sit, NewStatus),
	NewStatus.

%% 双修停止
%% PlayerId:  双修玩家ID
%% PlayerName:   记录开始时间
shuangxiu_interrupt(Status, PlayerId, PlayerName) ->
    Sit = Status#player_status.sit,
	NewStatus = Status#player_status{sit=Sit#status_sit{sit_down = 1, sit_llpt_time = 0, sit_intimacy_time = 0, sit_role = 0, sit_role_figure= 0, sit_role_pid = 0} },
    mod_scene_agent:update(sit, NewStatus),
	Time_Left = 24*60*60 - Status#player_status.sit_time_today,
    {ok, BinData} = pt_131:write(13106, [4, PlayerId, Time_Left, PlayerName]),
    lib_server_send:send_to_uid(Status#player_status.id, BinData),
 	{ok, Bin} = pt_131:write(13101, [Status#player_status.id, Time_Left]),
    lib_server_send:send_to_area_scene(Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y, Bin),
	NewStatus.

%% 双修条件检查
shuangxiu_check(Status) ->
    Sit = Status#player_status.sit,
    if	
        Sit#status_sit.sit_down =/= 2 -> false;				   		%% 判断是否在双修状态
        Sit#status_sit.sit_role =< 0 -> false;                 		%% 判断是否有双修同伴
        true ->
            IsPlayerOnline = lib_player:get_player_info(Sit#status_sit.sit_role, lib_sit),
            case IsPlayerOnline of
                Player when is_record(Player, player_status_sit)->
                    case Player#player_status_sit.sit#status_sit.sit_down =/= 2 of
                        true -> false;						   		%% 判断对方是否已在双修状态
                        false ->
                            %% 判断双方是否在同一个场景,双方距离
                            case (Status#player_status.scene =:= Player#player_status_sit.scene
                                  orelse abs(Status#player_status.x - Player#player_status_sit.x) =< 3
                                  orelse abs(Status#player_status.y - Player#player_status_sit.y) =< 3 ) of
                                false -> {false, Player};
                                true -> true
                            end
                    end;
                _ -> false
            end
    end.

%% 打坐
sit_down(Status) ->
    NowTime = util:unixtime(),
    Sit = Status#player_status.sit,
	Time_Left = 24*60*60 - Status#player_status.sit_time_today,
    NewStatus = Status#player_status{sit=Sit#status_sit{sit_down = 1, sit_hp_time = NowTime, sit_exp_time = NowTime}},
    {ok, Bin} = pt_131:write(13101, [Status#player_status.id, Time_Left]),
    lib_server_send:send_to_area_scene(Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y, Bin),
    mod_scene_agent:update(sit, NewStatus),
	NewStatus.

%% 打坐回复----
%% 回血----回气---增加经验----增加历练----!!未添加增加亲密度!!----
%% 打坐可以回复气血:每三秒回复:										等级*等级*0.1+10
%% 打坐可以回复内力:每三秒回复:										等级*等级*0.02+5
%% 			--双修加成												等级*等级*0.125-------VIP+0.025/0.05/0.075
%% 打坐经验--                   										等级*等级*0.25
sit_down_reply(Status0) ->
    NowTime = util:unixtime(),
    Sit0 = Status0#player_status.sit,
    %% 检查双修--------
    if  Sit0#status_sit.sit_down =:= 2 andalso (NowTime - Sit0#status_sit.sit_exp_time) >= 30
	->
            case shuangxiu_check(Status0) of
                false ->
                    Status = shuangxiu_interrupt(Status0, Status0#player_status.id, Status0#player_status.nickname);
                {false, Player} ->									%%对方距离过远
                    Status = shuangxiu_interrupt(Status0, Status0#player_status.id, Status0#player_status.nickname),
                    gen_server:cast(Player#player_status_sit.pid, {'shuangxiu_interrupt', Status0#player_status.id, Status0#player_status.nickname});
                true ->
                    Status = Status0
            end;
        true -> Status = Status0
    end,
    Sit = Status#player_status.sit,
    %%  															增加气血内力
    if  Sit#status_sit.sit_down > 0 andalso (NowTime - Sit#status_sit.sit_hp_time) >= 3  ->
            %% 														更新时间
            Status1 = Status#player_status{ sit=Sit#status_sit{sit_hp_time = NowTime} },
            %% 														增加气血内力
            if  (Status#player_status.hp_lim > Status#player_status.hp orelse Status#player_status.mp_lim > Status#player_status.mp) ->
                    Hp = Status#player_status.hp + round(Status#player_status.lv * Status#player_status.lv * 0.1 + 10),
                    Mp = Status#player_status.mp + round(Status#player_status.lv * Status#player_status.lv * 0.02 + 10),
                    NewHp = case Hp > Status#player_status.hp_lim of true -> Status#player_status.hp_lim; false -> Hp end,
                    NewMp = case Mp > Status#player_status.mp_lim of true -> Status#player_status.mp_lim; false -> Mp end,
					Status2 = Status1#player_status{ hp = NewHp, mp = NewMp },
					%%												气血增加了
                    case Status2#player_status.hp =/= Status#player_status.hp of
                        true ->
                            {ok, Bin} = pt_120:write(12009, [Status2#player_status.id, Status2#player_status.platform, Status2#player_status.server_num, Status2#player_status.hp, Status2#player_status.hp_lim]),
                            lib_server_send:send_to_area_scene(Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y, Bin);
                        false -> skip
                    end;
                true ->
                    Status2 = Status1
            end;
        true ->
            Status2 = Status
    end,
    %% --双修加成
    %%增加经验--           
    Exp_Add = if  
		  Sit#status_sit.sit_down > 0 andalso (NowTime - Sit#status_sit.sit_exp_time) >= 30
		  ->
		      %% 更新时间
		      Sit_xl = count_sittime(Status2),
		      Sit_Me = Sit#status_sit{sit_exp_time = NowTime},
		      Status3 = Sit_xl#player_status{sit = Sit_Me},
		      %% 打坐经验
		      _Exp = round(Status#player_status.lv * Status#player_status.lv * 0.37),
		      %% 双修经验
		      _Exp2 = case Sit#status_sit.sit_down =:= 2 of
				  true ->
				      Vip = Status#player_status.vip,
				      case Vip#status_vip.vip_type of
					  1 -> round(Status#player_status.lv * Status#player_status.lv * 0.099);
					  2 -> round(Status#player_status.lv * Status#player_status.lv * 0.108);
					  3 -> round(Status#player_status.lv * Status#player_status.lv * 0.117);
					  _ -> round(Status#player_status.lv * Status#player_status.lv * 0.09)
				      end;
				  false -> 0
			      end,
                      ExpTimes = case Status0#player_status.scene =:= data_marriage:get_marriage_config(scene_id) andalso lib_marriage:near_by_point(Status0#player_status.x, Status0#player_status.y) =:= true of
				     true -> 1.5;
				     false -> 1
				 end,
                      Exp = round(_Exp * ExpTimes),
                      Exp2 = round(_Exp2 * ExpTimes),
		      %% 离线经验
		      %% round(Status#player_status.lv * Status#player_status.lv / (Status#player_status.lv + 666) * 666 * 0.375),
		      %% 变身派对
		      Exp3 = case data_sit:can_get_party_addition(Status2#player_status.figure, Status2#player_status.sit#status_sit.sit_role_figure, Status2#player_status.scene, Status2#player_status.x, Status2#player_status.y) of
				 true -> round(Status2#player_status.lv * Status2#player_status.lv * 1.5) * 4;
				 false -> 0
			     end,
		      case (Exp + Exp2 + Exp3) > 0 of
			  true -> Status4 = lib_player:add_exp(Status3, round(Exp + Exp2 + Exp3));
			  false -> Status4 = Status3
		      end,
		      Exp + Exp2 + Exp3;
		  true ->
		      Status4 = Status2,
		      0
	      end,
    %% 发送消息
    case Status2#player_status.mp =/= Status#player_status.mp orelse (NowTime - Sit#status_sit.sit_exp_time) >= 30
    of
        true ->
            {ok, Bin2} = pt_131:write(13102, [Status2#player_status.mp, Status2#player_status.mp_lim, Exp_Add]),
            lib_server_send:send_to_uid(Status#player_status.id, Bin2);
        false -> skip
    end,
    %% 																增加历练
    if  Sit#status_sit.sit_down =:= 2 andalso (NowTime - Sit#status_sit.sit_llpt_time) >= 30
	->
            %% 														更新时间
            Sit4 = Status4#player_status.sit,
            Status5 = Status4#player_status{ sit=Sit4#status_sit{sit_llpt_time = NowTime} },
            Llpt = round(Status#player_status.lv * Status#player_status.lv * 0.0033+1),
	    %% 变身派对
	    Llpt1 = case data_sit:can_get_party_addition(Status5#player_status.figure, Status5#player_status.sit#status_sit.sit_role_figure, Status5#player_status.scene, Status5#player_status.x, Status5#player_status.y) of
			true -> round((100-(10-Status#player_status.lv*0.1)*(10-Status#player_status.lv*0.1)) * 3.6) * 4;
			false -> 0
		    end,
	    TotalLlpt = Llpt + Llpt1,
            case TotalLlpt > 0 of
                true ->
                    Status6 = lib_player:add_pt(llpt, Status5, TotalLlpt);
                false -> Status6 = Status5
            end;
        true ->
            Status6 = Status4
    end,
 	%%												增加亲密度
    if Sit#status_sit.sit_down =:= 2 andalso (NowTime - Sit#status_sit.sit_intimacy_time) >= 30
       ->
            %% 														更新时间
            Sit6 = Status6#player_status.sit,
            Status7 = Status6#player_status{ sit=Sit6#status_sit{sit_intimacy_time = NowTime} },
            Count = mod_daily_dict:get_count(Status6#player_status.id, 3701),
%% 			io:format("Count ~p~n", [Count]),
            case Count < 200 of
                true ->
                    IntimacyAdd = 1,
                    Sit6 = Status6#player_status.sit,
					lib_relationship:update_Intimacy(Status6#player_status.pid, Status6#player_status.id, Sit#status_sit.sit_role, IntimacyAdd),
					mod_daily_dict:plus_count(Status6#player_status.id, 3701, IntimacyAdd);
                false -> skip
            end;
        true ->
            Status7 = Status6
    end,
    Status7.

%% 取消打坐
sit_up(Status) ->
    Sit = Status#player_status.sit,
	NowTime = util:unixtime(),
    case Sit#status_sit.sit_down =:= 2 andalso Sit#status_sit.sit_role > 0 of
        true ->
            shuangxiu_offline(Status);
        false -> Status
    end,
	NewSitTime = Status#player_status.sit_time_today + NowTime - Sit#status_sit.sit_hp_time,
	StatusNext = Status#player_status{sit_time_today = NewSitTime},
    NewStatus = StatusNext#player_status{sit=Sit#status_sit{sit_down = 0, sit_hp_time = 0, sit_exp_time = 0, sit_llpt_time = 0, sit_intimacy_time = 0, sit_role = 0, sit_role_pid = 0, sit_role_figure = 0} },
    mod_scene_agent:update(sit, NewStatus),
    {ok, Bin} = pt_131:write(13103, Status#player_status.id),
    lib_server_send:send_to_area_scene(Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y, Bin),
	NewStatus.

%% 取消自身打坐----有双修就通知----offline
shuangxiu_offline(Status) ->
    Sit = Status#player_status.sit,
    case Sit#status_sit.sit_down =:= 2 andalso Sit#status_sit.sit_role > 0 of
        true ->
			IsPlayerOnline = lib_player:get_player_info(Sit#status_sit.sit_role, lib_sit),
            case IsPlayerOnline of
                Player when is_record(Player, player_status_sit) ->
                    gen_server:cast(Player#player_status_sit.pid, {'shuangxiu_interrupt', Status#player_status.id, Status#player_status.nickname});
                _ -> skip
            end;
        false -> Status
    end,
    ok.

%%Description:  							|计算打坐时间:仅供离线打坐使用
%%Description:    							|每次增加经验的时候更新30秒一加
%%@param:		Status2		   				|#player_status
count_sittime(Status2) ->
	NewSitTime = Status2#player_status.sit_time_today + 30,
	StatusNext = Status2#player_status{sit_time_today = NewSitTime},
	StatusNext.
	
%%Description:  							|登录时候
%%@return	:    							|#player_status 更新了离线时间
get_new_sit_xl_time(PlayerState) ->
	Old_Sit_Lx_Time = PlayerState#player_status.sit_time_left,
    Last_logout_time1 = db:get_one(io_lib:format(<<"select last_logout_time from player_login where id=~p">>, [PlayerState#player_status.id])),
	NowTime = util:unixtime(),
	Last_logout_time = case Last_logout_time1 of
		0->
			NowTime;
		_->
			Last_logout_time1
	end,
	case util:is_same_date(NowTime, Last_logout_time) of
		true->%%今天已经登陆过了
			PlayerState;
		false->%%本日首次登陆
			%%Sit = PlayerState#player_status.sit,
			Sit_Time_Old = PlayerState#player_status.sit_time_today,
			Living_days = util:get_diff_days(NowTime, Last_logout_time) - 1,
			Living_Time = Living_days * 24 * 60 * 60,
			New_Sit_Lx_Time = Old_Sit_Lx_Time + Living_Time - Sit_Time_Old,
			New_Sit_Lx_Time2 = case New_Sit_Lx_Time > 168*60*60 of
				true->
					168*60*60;
				false->
					New_Sit_Lx_Time
			end,
			PlayerState2 = PlayerState#player_status{sit_time_today = 0, sit_time_left = New_Sit_Lx_Time2},
			PlayerState2
	end.
			
%%Description:  							|获取离线时间
%%@return	:    	    					|返回的时间
get_sit_xl_time(PlayerStatus)->
	PlayerStatus#player_status.sit_time_left.
	
%%Description:  							|减少离线时间_手动
%%@return	:    		PlayerS2			|#player_status
set_sit_xl_time(PlayerStatus,TimeMi)->
	Old_sit_xl_Time = PlayerStatus#player_status.sit_time_left,
	NewTime = Old_sit_xl_Time - TimeMi,
	PlayerS2 = PlayerStatus#player_status{sit_time_left = NewTime},
	PlayerS2.
	
%%Description:  							|获取打坐双修所需的玩家信息(其他玩家)
trans(PlayerStatus)->
	MySitPs = #player_status_sit{
		mount = PlayerStatus#player_status.mount,
		copy_id = PlayerStatus#player_status.copy_id,
		scene = PlayerStatus#player_status.scene,                       % 场景id		
		y = PlayerStatus#player_status.y,                          		% 人物坐标_X
        x = PlayerStatus#player_status.x,                          		% 人物坐标_Y
		id = PlayerStatus#player_status.id,                         	% 玩家ID
        pid = PlayerStatus#player_status.pid,                           % 玩家进程
        sid = PlayerStatus#player_status.sid,                           % 发送进程
		sit = PlayerStatus#player_status.sit,                           % 
		sex = PlayerStatus#player_status.sex,
		lv = PlayerStatus#player_status.lv,
		nickname = PlayerStatus#player_status.nickname,
		realm = PlayerStatus#player_status.realm,
		career = PlayerStatus#player_status.career,
	  figure = PlayerStatus#player_status.figure
	},
	MySitPs.
	
party_send(PlayerId) ->	
    case data_sit:get_remain_party_time() of
	0 -> [];
	RemainTime ->
	    {ok, BinData} = pt_131:write(13114, [1, RemainTime]),
	    lib_unite_send:send_to_one(PlayerId, BinData)
    end.

party_send_all(Flag) ->
    case data_sit:get_remain_party_time() of
	0 ->
	    {ok, BinData} = pt_131:write(13114, [Flag, 0]),
	    lib_unite_send:send_to_all(BinData);
	RemainTime ->
	    {ok, BinData} = pt_131:write(13114, [Flag, RemainTime]),
	    lib_unite_send:send_to_all(BinData)
    end.

%%--------------------- E N D --------- E N D ----------------------------------
