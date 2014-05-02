%%%--------------------------------------
%%% @Module  : lib_physical
%%% @Author  : xieyunfei
%%% @Email   : xieyunfei@jieyoumail.com
%%% @Created : 2014.2.13
%%% @Description: 体力值系统
%%%--------------------------------------

-module(lib_physical).
-include("server.hrl").
-include("physical.hrl").
-export([
	get_switch/0,
	insert_role_physical/1,
	load_player_physical/3,
	write_player_physical/1,
	get_player_physical_data/1,
	check_physical/1,
	vip_change/2,
    get_scene_cost/1,
	is_enough_physical/2,
    is_enough_physical_by_other_pid/2,
	accelerat/1,
	cost_physical/2,
    other_pid_cost/2,
    updat_physical/1
]).


%% 功能开关：false关，true开
get_switch() ->
	lib_switch:get_switch(physical).

%% 创建角色体力值不存在时候插入一条新纪录
%% 目前在玩家下线时候已经做了这个步骤，预留以后使用
%% 存在：false，不存在：true。
insert_role_physical(RoleId) ->
	case db:get_row(io_lib:format(?SQL_ROLE_PHYSICAL_DATA, [RoleId])) of 
        [] -> db:execute(io_lib:format(?SQL_ROLE_PHYSICAL_REPLACE, [RoleId,5,0])),
			  true;
        _Other -> false
	end.

%% RoleId：玩家Id,DailyPid：玩家日常进程PID,VipType：玩家的vip类型。
%% 在玩家登陆时候获取player_physical登陆所需数据
%% @return[PhysicalCount,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,CumulateTime,WhetherUse]。
load_player_physical(RoleId,DailyPid,VipType) ->
	%%io:format("MODULE:~p LINE:~p ~n",[?MODULE,?LINE]),
    [PhysicalCount,CumulateTime,WhetherUse] = case db:get_row(io_lib:format(?SQL_ROLE_PHYSICAL_DATA, [RoleId])) of 
        [] -> [5, 0, 0];
        [PhysicalCountLast, CumulateTimeLast] -> [PhysicalCountLast, CumulateTimeLast, 1]
    end,
	AcceleratUse =  mod_daily:get_count(DailyPid, RoleId, 7000001),
	NowTime = util:unixtime(),
	UseTimeLen = NowTime - CumulateTime,
	PhysicalAdd = UseTimeLen div 3600,
	NewCumulateTime = UseTimeLen rem 3600,
	[NowPhysical,PhysicalSum,AcceleratSum,CdTime,NowCumulateTime] = case VipType of
		0 ->
			case PhysicalCount + PhysicalAdd >= 5 of
			   true -> [5,5,3,0,0];
			   _ ->	
				   case PhysicalAdd >= 1 of
					   true ->
						   [PhysicalCount + PhysicalAdd,5,3,3600-NewCumulateTime,NowTime-NewCumulateTime];
					   _ ->
						   [PhysicalCount,5,3,3600-NewCumulateTime,CumulateTime]
				   end				   
			end;																																		
		1 ->
			case PhysicalCount + PhysicalAdd >= 6 of
			   true -> [6,6,4,0,0];
			   _ ->	
				   case PhysicalAdd >= 1 of
					   true ->
						   [PhysicalCount + PhysicalAdd,6,4,3600-NewCumulateTime,NowTime-NewCumulateTime];
					   _ ->
						   [PhysicalCount,6,4,3600-NewCumulateTime,CumulateTime]
				   end				   
			end;																	
		2 ->
			case PhysicalCount + PhysicalAdd >= 7 of
			   true -> [7,7,5,0,0];
			   _ ->	
				   case PhysicalAdd >= 1 of
					   true ->
						   [PhysicalCount + PhysicalAdd,7,5,3600-NewCumulateTime,NowTime-NewCumulateTime];
					   _ ->
						   [PhysicalCount,7,5,3600-NewCumulateTime,CumulateTime]
				   end				   
			end;
		3 ->
			case PhysicalCount + PhysicalAdd >= 8 of
			   true -> [8,8,6,0,0];
			   _ ->	
				   case PhysicalAdd >= 1 of
					   true ->
						   [PhysicalCount + PhysicalAdd,8,6,3600-NewCumulateTime,NowTime-NewCumulateTime];
					   _ ->
						   [PhysicalCount,8,6,3600-NewCumulateTime,CumulateTime]
				   end				   
			end;
		_ ->
		case PhysicalCount + PhysicalAdd >= 5 of
		   true -> [5,5,3,0,0];
		   _ ->	
			   case PhysicalAdd >= 1 of
				   true ->
					   [PhysicalCount + PhysicalAdd,5,3,3600-NewCumulateTime,NowTime-NewCumulateTime];
				   _ ->
					   [PhysicalCount,5,3,3600-NewCumulateTime,CumulateTime]
			   end				   
		end
	end,
	[NowPhysical,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,NowCumulateTime,WhetherUse].

%% 退出时候把player_physical信息写到数据库
%% 只保存体力值数量和体力值冷却时间,从没使用过体力值的玩家不做保存。
write_player_physical(RoleStatus) ->
	%%io:format("MODULE:~p LINE:~p ~n",[?MODULE,?LINE]),
    case RoleStatus#player_status.physical#status_physical.whether_use =:= 1 of
        true ->
            db:execute(io_lib:format(?SQL_ROLE_PHYSICAL_REPLACE, [RoleStatus#player_status.id,
                                                                  RoleStatus#player_status.physical#status_physical.physical_count,
                                                                  RoleStatus#player_status.physical#status_physical.cumulate_time]));
        false ->
            skip
    end.

%% 获取角色的体力信息
%% RoleStatus：玩家的状态。
%% @return [PhysicalCount,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,CumulateTime]。
get_player_physical_data(RoleStatus) ->
	%%io:format("MODULE:~p LINE:~p ~n",[?MODULE,?LINE]),
	#status_physical{	
		physical_count = PhysicalCount,
		physical_sum = PhysicalSum,
		accelerat_use = AcceleratUse,		
		accelerat_sum = AcceleratSum,				
		cumulate_time = CumulateTime} = RoleStatus#player_status.physical,
    NowTime = util:unixtime(),
    CostGold = case AcceleratUse >= AcceleratSum of
        true ->
            0;
        false ->          
            data_physical_gold:get_clear_cd_time_gold(AcceleratUse+1)
    end,
    CdTime = case CumulateTime =:= 0 of
        true ->
            0;
        false ->
            3600 - (NowTime - CumulateTime)
    end,
	[PhysicalCount,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,CumulateTime,CostGold].


%% 体力值每个小时加一点
%% @return  {Refresh,NewRoleStatus}.
%% RoleStatus：玩家的状态，
%% NewRoleStatus：玩家最新状态，Refresh：是否刷新，1：体力值增加了，客户端要刷新；0：体力值不变，客户端不用刷新。
check_physical(RoleStatus) ->
	%%io:format("MODULE:~p LINE:~p ~n",[?MODULE,?LINE]),
	#status_physical{	
		physical_count = PhysicalCount,
		physical_sum = PhysicalSum,
		accelerat_use = _AcceleratUse,		
		cd_time = _CdTime,			
		cumulate_time = CumulateTime} = RoleStatus#player_status.physical,
	NowTime = util:unixtime(),
	NowAcceleratUse = mod_daily:get_count(RoleStatus#player_status.dailypid, RoleStatus#player_status.id, 7000001),
	UseTimeLen = NowTime - CumulateTime,
	PhysicalAdd = UseTimeLen div 3600,
	NowCumulateTime = UseTimeLen rem 3600,
    %%io:format("MODULE:~p LINE:~p NowAcceleratUse:~p ~n",[?MODULE,?LINE,NowAcceleratUse]),
	{Refresh, NewPhysicalCount, NewAcceleratUse, NewCdTime, NewCumulateTime}= 
    case PhysicalCount + PhysicalAdd >= PhysicalSum of
	   true -> 
		   case PhysicalCount >= PhysicalSum of
			   true ->
                    {0, PhysicalSum, NowAcceleratUse, 0, 0};
               _ ->
		            {1, PhysicalSum, NowAcceleratUse, 0, 0}
           end;
	   _ ->	
		   case PhysicalAdd >= 1 of
			   true ->
				   {1, PhysicalCount + PhysicalAdd, NowAcceleratUse, 3600-NowCumulateTime, NowTime-NowCumulateTime};
			   _ ->
				   {0, PhysicalCount, NowAcceleratUse, _CdTime, CumulateTime}
		   end				   
	end,
    PhysicalMsg=RoleStatus#player_status.physical#status_physical{physical_count=NewPhysicalCount, accelerat_use=NewAcceleratUse,
                                   cd_time=NewCdTime, cumulate_time=NewCumulateTime},
    %% 保存进#player_status中
    {Refresh,RoleStatus#player_status{physical = PhysicalMsg}}.

%% RoleStatus：玩家的状态。VipType:玩家的vip类型
%%vip类型改变时候重新计算体力值,如果体力值变化时候cast回玩家进程。
vip_change(RoleStatus,VipType) ->
	%%io:format("MODULE:~p LINE:~p ~n",[?MODULE,?LINE]),
	#status_physical{	
	physical_count = NowPhysical,
	physical_sum = PhysicalSum,
	accelerat_use = AcceleratUse,		
	accelerat_sum = _AcceleratSum,		
	cd_time = _CdTime,			
	cumulate_time = _NowCumulateTime	} = RoleStatus#player_status.physical,
	[NewPhysicalSum,NewAcceleratSum] = 
		if VipType =:= 0 ->
			   [5,3];
		   VipType =:= 1 ->
			   [6,4];
		   VipType =:= 2 ->
			   [7,5];
		   VipType =:= 3 ->
			   [8,6];
		   true ->
			   [5,3]
		end,
	if NewPhysicalSum =:= PhysicalSum ->
		   skip;
	   NewPhysicalSum > PhysicalSum ->
		   AddPhysical = NewPhysicalSum - PhysicalSum,
		   %% 保存进#player_status中
		   case is_pid(RoleStatus#player_status.pid) of
				true ->
					gen_server:cast(RoleStatus#player_status.pid, {'set_data', [{set_physical, [RoleStatus#player_status.physical#status_physical.physical_count+AddPhysical,
						NewPhysicalSum,AcceleratUse,NewAcceleratSum,RoleStatus#player_status.physical#status_physical.cd_time,
						RoleStatus#player_status.physical#status_physical.cumulate_time]}]});
				_ ->
					skip
			end;
%% 	   NewPhysicalSum < PhysicalSum ->
		true ->
		   DelPhysical = PhysicalSum - NewPhysicalSum,
		   NewPhysical = case (NewPhysicalSum - DelPhysical =< NowPhysical) of
							 true ->
								 NewPhysicalSum - DelPhysical;
							 _ ->
								 NowPhysical
						 end,
		   		   %% 保存进#player_status中
		   case is_pid(RoleStatus#player_status.pid) of
				true ->
					case NewPhysical >= NewPhysicalSum - DelPhysical of
						true ->
							gen_server:cast(RoleStatus#player_status.pid, {'set_data', [{set_physical, [NewPhysical,
								NewPhysicalSum,AcceleratUse,NewAcceleratSum,0,0]}]});
						_ ->
							gen_server:cast(RoleStatus#player_status.pid, {'set_data', [{set_physical, [NewPhysical,
								NewPhysicalSum,AcceleratUse,NewAcceleratSum,RoleStatus#player_status.physical#status_physical.cd_time,
								RoleStatus#player_status.physical#status_physical.cumulate_time]}]})
					end;
				_ ->
					skip	  
			end
	end.
			

%% 获取该场景要消费体力值数
%% SceneId：场景Id。
%% @return  扣几点体力值.
%% 在data_physical里面配置，配置里面不存在时候返回扣体力值数为0.
get_scene_cost(SceneId) ->
    case data_physical:get_base(SceneId) of
        [] ->
            0;
        BasePhysical when is_record(BasePhysical, base_physical)->
            BasePhysical#base_physical.take_off;
        _ ->
            0
    end.
		
							
		   
%% 判断是否够体力
%% RoleStatus：玩家的状态，CostCount:扣除的体力值数量
%% 如果关了体力值系统，永远返回true
%% @return bool	true足够， false:不足，2种情况，体力不足或者CostCount为负数
is_enough_physical(RoleStatus, CostCount) ->
    case get_switch() of
        true ->
        	case CostCount >=0 andalso (RoleStatus#player_status.physical#status_physical.physical_count >= CostCount) of
        		true ->
        			true;
        		_ ->
        			false
            end;
        _ ->
            true
	end.

%% 非玩家进程判断是否够体力
%% RoleId：玩家RoleId，CostCount:扣除的体力值数量
%% 如果关了体力值系统，永远返回true
%% @return bool true足够， false:不足，2种情况，体力不足或者CostCount为负数
is_enough_physical_by_other_pid(RoleId, CostCount) ->
    case get_switch() of
        true ->
            RoleStatus = case lib_player:get_player_info(RoleId) of
                false -> false;
                _Status -> _Status
            end,
            case CostCount >=0 andalso (RoleStatus#player_status.physical#status_physical.physical_count >= CostCount) of
                true ->
                    true;
                _ ->
                    false
            end;
        _ ->
            true
    end.


%% 消耗元宝加速清除冷却。
%% RoleStatus：玩家的状态。
%% @return  {IsAccelerat,NewRoleStatus}.
%% IsAccelerat：是否满足加速， 满足加速:1；不满足加速（2当天加速的次数用完,3体力值满不需要加速，4、元宝不足，）
%% NewRoleStatus：玩家最新状态
accelerat(RoleStatus) ->
	%%io:format("MODULE:~p LINE:~p ~n",[?MODULE,?LINE]),
	#status_physical{	
	physical_count = NowPhysical,
	physical_sum = PhysicalSum,
	accelerat_use = _AcceleratUse,		
	accelerat_sum = AcceleratSum,		
	cd_time = _CdTime,			
	cumulate_time = _NowCumulateTime} = RoleStatus#player_status.physical,
	NowTime = util:unixtime(),
	AcceleratUse = mod_daily:get_count(RoleStatus#player_status.dailypid, RoleStatus#player_status.id, 7000001),
	[IsAccelerat,NewRoleStatus] = case AcceleratUse+1 > AcceleratSum orelse  (NowPhysical >= PhysicalSum)of
		true ->
            case AcceleratUse+1 > AcceleratSum of
                true ->
                    [2,RoleStatus];
                false ->
                    [3,RoleStatus]
            end;
		_ ->
			CostGold = data_physical_gold:get_clear_cd_time_gold(AcceleratUse+1),
			case (RoleStatus#player_status.gold+RoleStatus#player_status.bgold) >= CostGold of
				true ->
                    case NowPhysical + 1 >= PhysicalSum of
					   true ->
						   	_RoleStatus = lib_goods_util:cost_money(RoleStatus, CostGold, silver_and_gold),
							lib_player:send_attribute_change_notify(_RoleStatus, 2),
						    mod_daily:increment(_RoleStatus#player_status.dailypid, _RoleStatus#player_status.id, 7000001),
                            PhysicalMsg = RoleStatus#player_status.physical#status_physical{physical_count=PhysicalSum,
                                                                                            accelerat_use=AcceleratUse+1,
                                                                                            cd_time=0, cumulate_time=0},
							[1,_RoleStatus#player_status{physical = PhysicalMsg}];
					   _ ->
						   	_RoleStatus = lib_goods_util:cost_money(RoleStatus, CostGold, silver_and_gold),
							mod_daily:increment(_RoleStatus#player_status.dailypid, _RoleStatus#player_status.id, 7000001),
							lib_player:send_attribute_change_notify(_RoleStatus, 2),
                            PhysicalMsg = RoleStatus#player_status.physical#status_physical{physical_count=NowPhysical+1,
                                                                                            accelerat_use=AcceleratUse+1,
                                                                                            cd_time=3600,
                                                                                            cumulate_time=NowTime},
							[1,_RoleStatus#player_status{physical = PhysicalMsg}]
					end;
				_ ->
					[4,RoleStatus]
			end
		end,
    
		%% 保存进#player_status中
        [IsAccelerat,NewRoleStatus].



%% 消耗体力
%% RoleStatus：玩家的状态，CostCount:扣除的体力值数量
%% @return	{error, 2}：体力不足。有两种可能，一种是体力真的不足，一种是CostCount传来一个负数。
%%					{ok, 玩家最新状态}：
%% 功能模块需要自己觉得保存最新体力值
cost_physical(RoleStatus, 0) -> {ok, RoleStatus};
cost_physical(RoleStatus, CostCount) ->
	%%io:format("MODULE:~p LINE:~p ~n",[?MODULE,?LINE]),
	case get_switch() of
		true ->
			case private_cost_physical(RoleStatus, CostCount) of
				{error, ErrorCode} ->
                    %%io:format("ErrorCode:~p ~n",[ErrorCode]),
					{error, ErrorCode};
				{ok, NewRoleStatus} ->
                    pp_player:handle(13031, NewRoleStatus, []),
                    %%io:format("PhysicalPrint:~p ~n",[NewRoleStatus#player_status.physical]),
					{ok, NewRoleStatus}
			end;
		_ ->
            %%io:format("PhysicalPrint:~p ~n",[RoleStatus#player_status.physical]),
			{ok, RoleStatus}
	end.



%% 扣除体力值内部函数，被cost_physical调用，外面模块不能调用。
%% RoleStatus：玩家的状态，CostCount:扣除的体力值数量
%% @return  {error, 2}：体力不足。有两种可能，一种是体力真的不足，一种是CostCount传来一个负数。
%%                  {ok, 玩家最新状态}：

private_cost_physical(RoleStatus, CostCount) ->
	%%io:format("MODULE:~p LINE:~p ~n",[?MODULE,?LINE]),
    #status_physical{	
        physical_count = NowPhysical,
        physical_sum = PhysicalSum,
        accelerat_use = _AcceleratUse,		
        accelerat_sum = _AcceleratSum,		
        cd_time = _CdTime,			
        cumulate_time = _NowCumulateTime} = RoleStatus#player_status.physical,
    %%io:format("MODULE:~p LINE:~p ~n",[?MODULE,?LINE]),
	case CostCount >= 0 andalso (NowPhysical >= CostCount) of
		true ->
            case NowPhysical >= PhysicalSum of
                true ->
                    NowTime = util:unixtime(),
                    PhysicalMsg = RoleStatus#player_status.physical#status_physical{
                        physical_count=NowPhysical-CostCount,
                        cd_time=3600,
                        cumulate_time=NowTime,
                        whether_use=1},
                    {ok,RoleStatus#player_status{physical=PhysicalMsg}};
                _ ->
                    PhysicalMsg = RoleStatus#player_status.physical#status_physical{physical_count=NowPhysical-CostCount,
                                                                                    whether_use=1},
                    {ok,RoleStatus#player_status{physical=PhysicalMsg}}
            end;
		_ ->
            io:format("MODULE:~p LINE:~p ~n",[?MODULE,?LINE]),
			{error, 2}
	end.

%% 其他进程扣体力值
other_pid_cost(RoleId, CostCount) ->
    Pid = case lib_player:get_player_info(RoleId, pid) of
        false  -> false;
        TmpPid -> TmpPid
    end,
    gen_server:cast(Pid, {'set_data', [{cost_physical, CostCount}]}).

%% call更新玩家状态
updat_physical(RoleStatus) ->
    case is_pid(RoleStatus#player_status.pid) of
        true ->
            gen_server:call(RoleStatus#player_status.pid, {'updat_physical',RoleStatus}),
            1;
        _ ->
            0
    end.


%% %% 获取用于每日计数器使用的id，为7000001至70000XX
%% private_get_store_key(Type) ->
%% 	7000000 + Type.
