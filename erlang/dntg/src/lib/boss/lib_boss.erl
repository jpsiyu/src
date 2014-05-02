%%------------------------------------------------------------------------------
%% @Module  : lib_boss
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.6.20
%% @Description: BOSS系统逻辑
%%------------------------------------------------------------------------------

-module(lib_boss).
-include("common.hrl").
-include("boss.hrl"). 
-include("scene.hrl").
-include("server.hrl").

-export([
		 create_mon/1,         %% 生成指定怪物.
		 load/0,               %% 载入数据.
		 check_all/1,          %% 怪物列表审.
         do_check/1,           %% 怪物单个审查.
         mon_check_long/1,     %% 时长类型怪物检查.
         mon_check_point/1,    %% 时点类型怪物检查.
		 create_mon2/4,        %% 刷新黄眉老佛、白骨精和赤鬼王专用. 
         send_notice/6,        %% 发送公告.
         get_boss_type/2,      %% 获取刷新boss的类型.
         call_mon/6,           %% 召唤怪物.
		 add_log/2             %% 增加BOSS召唤日志.
%%       call_mon/2,           %% 召唤怪物:1001场景不符 1002坐标不符.
%%       notice_boss_kill/2,   %% 杀死BOSS传闻.   
]).


%生成指定怪物
create_mon([BossID, Scene, X, Y, Aticve]) ->
    MonId = lib_mon:sync_create_mon(BossID, Scene, X, Y, Aticve, 0, 1, []),
%%     %通知客户端
%%     R = lib_mon:lookup(?ETS_MON, Scene, MonId),
%%     [Status] = R,
%%     {ok, BinData} = pt_12:write(12007, Status),
%%     %城门怪物做特殊处理-全地图广播
%%     case lists:member(BossID, [22428,22429,22430]) of
%%         true ->
%%             rpc:cast(Status#ets_mon.link_node, lib_send_logic, send_to_scene, [Status#ets_mon.line, Status#ets_mon.scene, BinData]);
%%         _ ->
%%             rpc:cast(Status#ets_mon.link_node, lib_send_logic, send_to_area_scene, [Status#ets_mon.line, Status#ets_mon.scene, X, Y, BinData])
%%     end,
    MonId.

%% 载入数据.
load() ->
    BossList = data_boss:get_boss_list(),
    F = fun(Id) ->
        Record = data_boss:get(Id),
        #monitem{
            id = Record#ets_boss.id,                                          %% 数据库ID
            boss_id = Record#ets_boss.boss_id,                                %% 怪物类型ID
            boss_rate = Record#ets_boss.boss_rate,                            %% 刷新概率
            refresh_type = Record#ets_boss.refresh_type,                      %% 刷新类型【0定时长刷新，1定时间点刷新】
            refresh_times = Record#ets_boss.refresh_times,                    %% 刷新时长
            refresh_times_point_6 = Record#ets_boss.refresh_times_point_6,    %% 刷新时间点[6小时]
            refresh_times_point_3 = Record#ets_boss.refresh_times_point_3,    %% 刷新时间点[3小时]
            refresh_place = Record#ets_boss.refresh_place,                    %% 刷新地点
            refresh_num = Record#ets_boss.refresh_num,                        %% 刷新数量
            notice = Record#ets_boss.notice,                                  %% 是否公告
            living_time = Record#ets_boss.living_time,                        %% 出生后存活时间
            active = Record#ets_boss.active,                                  %% 是否主动攻击敌人
            starttime = Record#ets_boss.starttime,                            %% 怪物开始刷新日期
            endtime = Record#ets_boss.endtime,                                %% 怪物结束刷新日期
            mon_id = Record#ets_boss.boss_id,                                 %% 怪物Id
            mon_type = Record#ets_boss.mon_type,                              %% 怪物类型【0默认怪物，1委托销毁怪物】
            mon_born_time = Record#ets_boss.mon_born_time,                    %% 出生时间
            mon_die_time = Record#ets_boss.mon_die_time,                      %% 死亡时间
            mon_check_time = Record#ets_boss.mon_check_time                   %% 上次定时器扫描时间
        }
    end,
    Monitems = lists:map(F, BossList),
    #boss_state{monitems=Monitems}.

%% 怪物列表审查
check_all(Monitems) ->
    NewMonitems = lists:map(fun do_check/1,Monitems),
    %去除废弃怪物
    F = fun(M) ->
        case M#monitem.mon_id =:= 0 andalso M#monitem.id =:= 0 
			andalso M#monitem.boss_id =:= 0  of
            true ->
                false;
            _ ->
                true
        end
    end,
    NewMonitems1 = lists:takewhile(F, NewMonitems),
    NewMonitems1.

%% 怪物单个审查
do_check(Monitem) ->
    Now = util:unixtime(),
    %有效日期
    try case (Now >= Monitem#monitem.starttime andalso  
		Now =<  Monitem#monitem.endtime) 
  		orelse (Monitem#monitem.starttime =:= 0 
		andalso Monitem#monitem.endtime =:= 0) of
            true ->
                %刷新类型
                case Monitem#monitem.refresh_type of
                    0 ->
                        mon_check_long(Monitem);
                    1 ->
                        mon_check_point(Monitem);
                    _ ->
                        Monitem
                end;
            false ->
                Monitem
        end
   catch
        _ = _ -> Monitem
   end.

%% 时长类型怪物检查
mon_check_long(Monitem) ->
    %存活
    Now = util:unixtime(),	
    Th = util:rand(1, length(Monitem#monitem.refresh_place)),
    {Scene, X, Y} = lists:nth(Th, Monitem#monitem.refresh_place),
	
	MonIdList = lib_mon:get_scene_mon_by_mids(Scene, 0, [Monitem#monitem.mon_id], all),
														
	case MonIdList of
        [] ->
            %是否为托管怪物
            case Monitem#monitem.mon_type of
                1 ->
                    #monitem{};
                _ ->
                    %1.第一次检测到死亡的时间.
                    NewMonitem = case Monitem#monitem.mon_die_time =:= 0 
									 andalso Monitem#monitem.mon_born_time > 0  of
                        true ->
                            Monitem#monitem{mon_die_time=Now};
                        _ ->
                            Monitem
                    end,				
					TimeLong = NewMonitem#monitem.refresh_times,
                    %2.是否到重生时间
                    case Now - NewMonitem#monitem.mon_die_time >= TimeLong of
                        true ->
                            BOSS_ID = get_boss_type(NewMonitem#monitem.boss_id, NewMonitem#monitem.boss_rate),
                            _Mon_id = create_mon([BOSS_ID, Scene, X, Y, NewMonitem#monitem.active]),
							add_log(BOSS_ID, Scene),
                            case NewMonitem#monitem.notice > 0 of
                                true ->
                                    spawn(fun()->
                                            send_notice(Scene, X, Y, NewMonitem, BOSS_ID,1)
                                    end);
                                _ ->
                                    ok
                            end,
                            NewMonitem#monitem{
                                        mon_id=BOSS_ID,
                                        mon_born_time=Now,
                                        mon_die_time=0,
                                        mon_check_time=Now};
                        _ ->
                            NewMonitem#monitem{mon_check_time=Now}
                    end
            end;
        _ ->
            %是否委托怪物
            case Monitem#monitem.mon_type of
                1 ->
                    case Now - Monitem#monitem.mon_born_time >= Monitem#monitem.living_time 
						andalso Monitem#monitem.living_time > 0 of
                        true ->
                            lib_mon:clear_scene_mon_by_mids(Scene, 0, 1, [Monitem#monitem.mon_id]),
                            #monitem{};
                        _ ->
                            Monitem#monitem{mon_check_time=Now}
                    end;
                0 ->
                   BorTime = Now - Monitem#monitem.mon_born_time,
                   case  BorTime >= Monitem#monitem.living_time andalso Monitem#monitem.living_time > 0 of
                        true ->
                            lib_mon:clear_scene_mon_by_mids(Scene, 0, 1, [Monitem#monitem.mon_id]),
                            spawn(fun()->
								send_notice(Scene, X, Y, Monitem, Monitem#monitem.mon_id,2)
                            end),
                            Monitem#monitem{
                                        mon_id=0,
                                        mon_born_time=0,
                                        mon_die_time=Now,
                                        mon_check_time=Now};
                        _ ->
                            Monitem#monitem{mon_check_time=Now}
                   end
            end
    end.

%% 时点类型怪物检查
mon_check_point(Monitem) ->
    
	%1.得到时间.
    Now = util:unixtime(),
    {Hour,Min,_} = time(),
	_BossId1 = Monitem#monitem.boss_id,
	BossKey = lists:concat(["BossId",_BossId1]),	
	
	%2.得到刷新的地点.
    RePlace =case Monitem#monitem.boss_id =:= 22001 of
        true ->
            {220,35,48};
        _ ->
			case get(BossKey) of
				undefined ->
					Th = util:rand(1, length(Monitem#monitem.refresh_place)),
					lists:nth(Th, Monitem#monitem.refresh_place);
				_SceneId ->
					case _BossId1 of
						40005 -> {_SceneId,20,37};
						40040 -> {_SceneId,23,23};
						40050 -> {_SceneId,20,35};
						_ -> {_SceneId,23,23}
					end
			end
    end,
    {Scene, X, Y} = RePlace,
	
	MonIdList = lib_mon:get_scene_mon_by_mids(Scene, 0, [Monitem#monitem.mon_id], all),
	
	case MonIdList of	
		%1.BOSS怪物不存在.
        [] ->
            FunCheckTime = 
				fun([_Hour, _Min]) ->
                    case Hour =:= _Hour andalso Min =:= _Min of
                        true ->
                            true;
                        _ ->
                            false
                    end
                end,		
			TimePoint = Monitem#monitem.refresh_times_point_3, 
            Result = lists:any(FunCheckTime, TimePoint),
            case Result of
                true ->
                    BOSS_ID = get_boss_type(Monitem#monitem.boss_id, Monitem#monitem.boss_rate),
                    _Mon_id =
						case Monitem#monitem.boss_id of
							%% 刷新黄眉老佛专用.
							40005 ->								
								create_mon2(Monitem#monitem.boss_id, BOSS_ID, [404,405,406], Monitem#monitem.active);
							%% 刷新白骨精专用.
							40040 ->								
								create_mon2(Monitem#monitem.boss_id, BOSS_ID, [402,410,411], Monitem#monitem.active);
							%% 刷新赤鬼王专用.
							40050 ->								
								create_mon2(Monitem#monitem.boss_id, BOSS_ID, [403,408,409], Monitem#monitem.active);							
							_Other ->
								create_mon([BOSS_ID, Scene, X, Y, Monitem#monitem.active])
						end,
					add_log(BOSS_ID, Scene),
                    case Monitem#monitem.notice > 0 of
                        true ->
                            spawn(fun()->
                                    send_notice(Scene, X, Y, Monitem, BOSS_ID, 1)
                            end);
                        _ ->
                            ok
                    end,
                    Monitem#monitem{
                                mon_id=BOSS_ID,
                                mon_born_time=Now,
                                mon_die_time=0,
                                mon_check_time=Now};
                false ->
                    Monitem#monitem{mon_check_time=Now}
            end;		
		%2.BOSS怪物不存在.
        _ ->
            %是否委托怪物
            case Monitem#monitem.mon_type of
                1 ->
                    case Now - Monitem#monitem.mon_born_time >= Monitem#monitem.living_time 
						andalso Monitem#monitem.living_time > 0 of
                        true ->
                            #monitem{};
                        _ ->
                            Monitem#monitem{mon_check_time=Now}
                    end;
                0 ->
                   BorTime = Now - Monitem#monitem.mon_born_time,
                   case BorTime >= Monitem#monitem.living_time andalso Monitem#monitem.living_time > 0 of
                        true ->
                            lib_mon:clear_scene_mon_by_mids(Scene, 0, 1, [Monitem#monitem.mon_id]),
                            Monitem#monitem{
                                        mon_id=0,
                                        mon_born_time=0,
                                        mon_die_time=Now,
                                        mon_check_time=Now};
                        _ ->
                            Monitem#monitem{mon_check_time=Now}
                   end
            end
    end.

%% 刷新黄眉老佛、白骨精和赤鬼王专用.
create_mon2(BossId, MonId, SceneList, Active) ->
	%1.杀死场景所有怪.
    FunCleaMon = fun(SceneId) ->		    
            lib_mon:clear_scene_mon(SceneId, 0, 1)
    end,
	[FunCleaMon(SceneId) || SceneId <- SceneList],
	
	SceneList1 = util:list_shuffle(SceneList),
	[Scene1, Scene2, Scene3] = SceneList1,
	
	BossKey = lists:concat(["BossId",BossId]),
	put(BossKey, Scene3),
	
	%2.生成怪物.
	_Mon_id = 
		case MonId of
			40005 ->%黄梅老佛.
				create_mon([40061, Scene1, 20, 37, Active]),
				create_mon([40066, Scene2, 20, 37, Active]),
				create_mon([MonId, Scene3, 20, 37, Active]);
			40031 ->%黄梅老佛.
				create_mon([40062, Scene1, 20, 37, Active]),
				create_mon([40067, Scene2, 20, 37, Active]),
				create_mon([MonId, Scene3, 20, 37, Active]);
			40032 ->%黄梅老佛.
				create_mon([40063, Scene1, 20, 37, Active]),
				create_mon([40068, Scene2, 20, 37, Active]),
				create_mon([MonId, Scene3, 20, 37, Active]);
			40033 ->%黄梅老佛.
				create_mon([40064, Scene1, 20, 37, Active]),
				create_mon([40069, Scene2, 20, 37, Active]),
				create_mon([MonId, Scene3, 20, 37, Active]);
			40034 ->%黄梅老佛.
				create_mon([40065, Scene1, 20, 37, Active]),
				create_mon([40070, Scene2, 20, 37, Active]),
				create_mon([MonId, Scene3, 20, 37, Active]);
			40040 ->%白骨精.
				create_mon([40071, Scene1, 23, 23, Active]),
				create_mon([40076, Scene2, 23, 23, Active]),
				create_mon([MonId, Scene3, 23, 23, Active]);
			40041 ->%白骨精.
				create_mon([40072, Scene1, 23, 23, Active]),
				create_mon([40077, Scene2, 23, 23, Active]),
				create_mon([MonId, Scene3, 23, 23, Active]);
			40042 ->%白骨精. 
				create_mon([40073, Scene1, 23, 23, Active]),
				create_mon([40078, Scene2, 23, 23, Active]),
				create_mon([MonId, Scene3, 23, 23, Active]);
			40043 ->%白骨精.
				create_mon([40074, Scene1, 23, 23, Active]),
				create_mon([40079, Scene2, 23, 23, Active]),
				create_mon([MonId, Scene3, 23, 23, Active]);
			40044 ->%白骨精.
				create_mon([40075, Scene1, 23, 23, Active]),
				create_mon([40080, Scene2, 23, 23, Active]),
				create_mon([MonId, Scene3, 23, 23, Active]);
			40050 ->%赤鬼王.
				create_mon([40081, Scene1, 20, 35, Active]),
				create_mon([40086, Scene2, 20, 35, Active]),
				create_mon([MonId, Scene3, 20, 35, Active]);
			40051 ->%赤鬼王.
				create_mon([40082, Scene1, 20, 35, Active]),
				create_mon([40087, Scene2, 20, 35, Active]),
				create_mon([MonId, Scene3, 20, 35, Active]);
			40052 ->%赤鬼王.
				create_mon([40083, Scene1, 20, 35, Active]),
				create_mon([40088, Scene2, 20, 35, Active]),
				create_mon([MonId, Scene3, 20, 35, Active]);
			40053 ->%赤鬼王. 
				create_mon([40084, Scene1, 20, 35, Active]),
				create_mon([40089, Scene2, 20, 35, Active]),
				create_mon([MonId, Scene3, 20, 35, Active]);
			40054 ->%赤鬼王.
				create_mon([40085, Scene1, 20, 35, Active]),
				create_mon([40090, Scene2, 20, 35, Active]),
				create_mon([MonId, Scene3, 20, 35, Active]);			
			_Other ->
				MonId
		end,
	_Mon_id.


%% 发送公告.
send_notice(Scene, X, Y, Monitem, BOSS_ID, _Type) ->

	%1.查询BOSS的坐标.
	[SceneId, X2, Y2] = case data_scene_id:get_boss_xy(BOSS_ID) of
		[] -> [Scene, X, Y];
		[S, X1, Y1] -> [S, X1, Y1]
	end,
	SceneName = case data_scene:get(SceneId) of
		[] -> <<"">>;
		SceneData -> SceneData#ets_scene.name
	end,
	
	%2.发送普通BOSS公告.
	case BOSS_ID < 99010 orelse BOSS_ID > 99055 of
		true ->
			case Monitem#monitem.boss_rate of
				[] ->
					 case data_mon:get(BOSS_ID) of
		        		[] ->skip;
		        		Mon ->
							lib_chat:send_TV({all},1,2, ["yewaiBoss", 1, 
										     Mon#ets_mon.name, 
										     Mon#ets_mon.color, 
										     SceneId, X2, Y2, SceneName])
					end;
				_ ->
					case data_mon:get(BOSS_ID) of
		        		[] ->skip;
		        		Mon ->
							lib_chat:send_TV({all},1,2, ["globalBoss", 1, 
										     Mon#ets_mon.name, 
										     Mon#ets_mon.color, 
										     SceneId, X2, Y2, SceneName])
					end
			end;
		false ->
			skip
	end,

	%3.发送国庆活动怪物公告.
	case BOSS_ID of
		%1.东瀛魔精
		99010 -> 
			lib_chat:send_TV({all},1,1, ["showWokou"]);
		%2.五彩月兔
		99015 -> 
			lib_chat:send_TV({all},1,1, ["showYuetu"]);
		_ ->
			skip
	end,
	ok.

%% 获取刷新boss的类型
get_boss_type(BossId, BossRate) ->
    case BossRate of
        [] ->
            BossId;
        _ ->
            %总概率
            F = fun([_, R1], Sum1) ->
                Sum1 + R1
            end,
            AllRate = lists:foldl(F, 0, BossRate),
            %随机刷新
            M = util:rand(1, AllRate),
            F1 = fun([BossId0, R2], [Sum2, BossId1]) ->
                    case M > Sum2 andalso M =< Sum2 + R2 of
                        true ->
                            [Sum2 + R2, BossId0];
                        _ ->
                            [Sum2 + R2, BossId1]
                    end
            end,
            [_, BossId2] = lists:foldl(F1, [0, 0], BossRate),
            %二次修正
            case BossId2 of
                0 ->
                    BossId;
                _ ->
                    BossId2
            end
    end.


%% 召唤怪物
call_mon(PlayerStatus, IsSendNotice, MonId, SceneId, X, Y) ->	

	%得到怪物数据.
	case data_mon:get(MonId) of
		[] ->skip;
		Mon ->
			%1.创建怪物.
            lib_mon:async_create_mon(MonId, SceneId, X, Y, 1, 0, 1, 
										 [
                                             {owner_id, PlayerStatus#player_status.id}, 
                                             {mon_name, list_to_binary([PlayerStatus#player_status.nickname,"召唤的", Mon#ets_mon.name])}
                                         ]),
			
			%2.发送云游BOSS公告.
			case IsSendNotice == 1 of
				true ->
					send_call_mon_notice(PlayerStatus, SceneId, X, Y, MonId);
				false ->
					skip
			end,			
			
			%3.添加监控.
			%20分钟存活时间.
			LivingTime = 1200,
			mod_disperse:cast_to_unite(mod_boss, watch, [[MonId, LivingTime, SceneId, X, Y]])	
	end.
	
%% 发送云游BOSS公告.
send_call_mon_notice(PlayerStatus, SceneId, X, Y, BOSS_ID) ->

	%1.得到场景的名字.
	SceneName = case data_scene:get(SceneId) of
		[] -> <<"">>;
		SceneData -> SceneData#ets_scene.name
	end,
	
	%2.得到怪物数据.
	case data_mon:get(BOSS_ID) of
		[] ->skip;
		Mon ->
			lib_chat:send_TV({all},0,2, ["openFengyin", 1,
							 PlayerStatus#player_status.id,
							 PlayerStatus#player_status.realm,
							 PlayerStatus#player_status.nickname, 
							 PlayerStatus#player_status.sex, 
							 PlayerStatus#player_status.career, 
							 PlayerStatus#player_status.image,  
						     Mon#ets_mon.name, 
						     Mon#ets_mon.color,
							 SceneName, 
						     SceneId, 
							 X, 
							 Y])
	end,
	ok.

%% 增加BOSS召唤日志.
add_log(MonId, SceneId) ->

	%1.得到场景的名字.
	SceneName = 
		case data_scene:get(SceneId) of
			[] -> <<"">>;
			SceneData -> SceneData#ets_scene.name
		end,
	
	%2.得到怪物数据.
	case data_mon:get(MonId) of
		[] ->skip;
		MonData ->
	 		log:log_call_boss(SceneName,
							  MonId,
							  MonData#ets_mon.name, 
					          MonData#ets_mon.color)
	end,
	ok.
%% 
%% %%召唤怪物:1001场景不符 1002坐标不符
%% call_mon(Player_Status, GoodsID) ->
%%     MonInfo = data_mon_call:get(GoodsID),
%%     Call_scene = MonInfo#mon_call.call_scene,
%%     Boss_Id = MonInfo#mon_call.boss_id,
%%     [X_small, X_big] = MonInfo#mon_call.call_x_rand,
%%     [Y_small, Y_big]  = MonInfo#mon_call.call_y_rand,
%%     [C_x, C_y]  = MonInfo#mon_call.born_x_y,
%%     LivingTime = MonInfo#mon_call.livingtime,
%%     %招呼场景
%%     RealScene = get_real_scene(Player_Status#player_status.scene),
%%     case catch RealScene =:= Call_scene orelse Call_scene =:= 0 of
%%         true ->
%%             %安全场景无法召唤
%%             Scene = data_scene:get(RealScene),
%%             case Scene#ets_scene.type =:= ?SCENE_TYPE_SAFE of
%%                 true ->
%%                     {fail, 1541};
%%                 _ ->
%%                     %召唤位置
%%                     X = Player_Status#player_status.x,
%%                     Y = Player_Status#player_status.y,
%%         %            io:format("X=~p~n", [X]),
%%         %            io:format("Y=~p~n", [Y]),
%%         %            io:format("X_s=~p~n", [X_small]),
%%         %            io:format("X_b=~p~n", [X_big]),
%%         %            io:format("Y_s=~p~n", [Y_small]),
%%         %            io:format("Y_b=~p~n~n", [Y_big]),
%%                     %是否规定范围使用
%%                     case X_small>0 andalso X_big>0 andalso Y_small>0 andalso Y_big>0 of
%%                         true ->
%%                             case X >= X_small andalso X =< X_big andalso Y >= Y_small andalso Y =< Y_big of
%%                                 true ->
%%                                     %是否规定出生坐标
%%                                     case C_x > 0 andalso C_y >0 of
%%                                         true ->
%%                                             _C_x = C_x,
%%                                             _C_y = C_y;
%%                                         false ->
%%                                             _C_x = Player_Status#player_status.x,
%%                                             _C_y = Player_Status#player_status.y
%%                                     end,
%%                                     Sid = get_real_scene(Player_Status#player_status.scene),
%%                                     Mid = create_mon([Boss_Id, Player_Status#player_status.scene, _C_x, _C_y, 1, Sid]),
%%                                     %怪物监控
%%                                     case LivingTime > 0 of
%%                                         true ->
%%                                             mod_boss:watch([Mid, LivingTime]);
%%                                         false ->
%%                                             ok
%%                                     end,
%%                                     {ok, Player_Status};
%%                                 false ->
%%                                     {fail, 1542}
%%                             end;
%%                        false ->
%%                             %是否规定出生坐标
%%                             case C_x > 0 andalso C_y >0 of
%%                                 true ->
%%                                     _C_x = C_x,
%%                                     _C_y = C_y;
%%                                 false ->
%%                                     _C_x = Player_Status#player_status.x,
%%                                     _C_y = Player_Status#player_status.y
%%                             end,
%%                             Sid = get_real_scene(Player_Status#player_status.scene),
%%                             Mid = create_mon([Boss_Id, Player_Status#player_status.scene, _C_x, _C_y, 1, Sid]),
%%                             %添加监控
%%                             case LivingTime > 0 of
%%                                 true ->
%%                                     mod_boss:watch([Mid, LivingTime]);
%%                                 false ->
%%                                     ok
%%                             end,
%%                             {ok, Player_Status}
%%                    end
%%                 end;
%%             false ->
%%                 {fail, 1541}
%%     end.
%% 
%% get_real_scene(Id) ->
%%     case ets:lookup(?ETS_SCENE, Id) of
%%         []  -> 0;
%%         [S] -> S#ets_scene.sid
%%     end.
%% 

%% notice_boss_kill(_PlayerStatus, _Mid) ->
%%     ok.
%% %    case lists:member(Mid, [22043, 99501]) of
%% %        true ->
%% %            Mname = case Mid of
%% %                22043 ->
%% %                    "无双";
%% %                99501 ->
%% %                    "苍狼王"
%% %            end,
%% %            MyMs = io_lib:format("厉害，~s 将 BOSS ~s 斩于马下！！", [PlayerStatus#player_status.nickname,Mname]),
%% %            lib_chat:send_quiz_notice(MyMs);
%% %        _ ->
%% %            ok
%% %    end.

