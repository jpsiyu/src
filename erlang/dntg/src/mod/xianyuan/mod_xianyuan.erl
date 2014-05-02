%%%--------------------------------------
%%% @Module  :  mod_xianyuan 
%%% @Author  :  hekai
%%% @Email   :  hekai@jieyou.cn
%%% @Created :  2012-9-27
%%% @Description: 仙缘系统
%%%---------------------------------------

-module(mod_xianyuan).
-behaviour(gen_server).
-include("server.hrl").
-include("common.hrl").
-include("xianyuan.hrl").

-export([
	start/1,				%% 启动进程
	stop/1,					%% 停止进程
	xy_practice/4,			%% 仙缘修炼
	xy_practice_commit/5,	%% 仙缘修炼2
	clearCD/2,              %% 修炼加速
	xy_info/2,              %% 仙缘修炼、境界信息
	count_attribute/1,		%% 计算仙缘系统附加人物属性加成
	count_attribute_2/1,    %% 计算仙缘系统附加属性加成【基础属性与加成分开显示】
	count_base_attribute/1, %% 计算仙缘系统附加人物基础属性加成
	get_sweetness/1,		%% 获取甜蜜度
	use_sweet_goods/1,      %% 使用增加甜蜜度的物品
	get_JLevel/1,			%% 获取境界等级
	getPlayer_xianyuan/1    %% 获取仙缘状态数据
]).
-export([
	init/1,
	handle_call/3,
	handle_cast/2,
	handle_info/2,
	terminate/2,
	code_change/3
]).

%% 启动进程
%% @param Uid 玩家ID
start(Uid) -> gen_server:start_link(?MODULE, [Uid], []).

%%停止进程
stop(Pid) ->
	case is_pid(Pid) andalso is_process_alive(Pid) of
		true -> gen_server:cast(Pid, stop);
		false -> skip
	end.

%% 仙缘修炼
xy_practice(Pid, Xy_type, NCloseness, PS) ->
	gen_server:call(Pid, {xy_practice, Xy_type, NCloseness, PS}).

%% 仙缘修炼2
xy_practice_commit(Pid, Xy_type, NCloseness, Need_closeness2, PS) ->
	gen_server:call(Pid, {xy_practice_commit, Xy_type, NCloseness, Need_closeness2, PS}).

%% 修炼加速
clearCD(Pid, PlayerStatus) ->
	gen_server:call(Pid, {clearCD, PlayerStatus}).

%% 仙缘修炼、境界信息
xy_info(Pid, PS) ->
	gen_server:call(Pid, {xy_info, PS}).

%%计算仙缘系统附加人物属性加成
%% @param PS 玩家状态
%% @return [气血，....，毒抗]  
count_attribute(PS)->
	Player_xianyuan = getPlayer_xianyuan(PS#player_status.player_xianyuan),
    lib_xianyuan:count_attribute(PS, Player_xianyuan).

%%基础属性与加成分开显示 
count_attribute_2(PS)->
	Player_xianyuan = getPlayer_xianyuan(PS#player_status.player_xianyuan),
    lib_xianyuan:count_attribute_2(PS, Player_xianyuan).

%%计算仙缘系统附加人物基础属性加成
%% @param PS 玩家状态
%% @return [力量、体制、灵力、身法]
count_base_attribute(PS) ->
	Player_xianyuan = getPlayer_xianyuan(PS#player_status.player_xianyuan),
    lib_xianyuan:count_base_attribute(Player_xianyuan).

%% 获取仙缘状态数据
getPlayer_xianyuan(Pid) ->
	case misc:is_process_alive(Pid) of
		false->#player_xianyuan{};
		true->gen_server:call(Pid,{getPlayer_xianyuan})
	end.

%% 获取甜蜜度
get_sweetness(Pid) ->
	Player_xianyuan = getPlayer_xianyuan(Pid),
	Player_xianyuan#player_xianyuan.sweetness.

%% 使用增加甜蜜度的物品
use_sweet_goods(PS) ->
	gen_server:call(PS#player_status.player_xianyuan, {use_sweet_goods, PS}).

%% 获取境界等级
get_JLevel(Pid) ->
	Player_xianyuan = getPlayer_xianyuan(Pid),
	Player_xianyuan#player_xianyuan.jjie.

%%----------------- 下面为回调函数 -----------------%%
init([Uid]) ->
   	State = lib_xianyuan:load(Uid),
    {ok, State}.

handle_call({xy_practice, Xy_type, NCloseness, _PS}, _From, State) ->	
	%% 是否有正在修炼的仙缘
	Ptype = State#player_xianyuan.ptype,
	Ptype2 = State#player_xianyuan.ptype2,
	case Ptype of
		0 -> IsCding= 0; 
		_->	%% 正在修炼情况		
			Xy_type_lv_1 = lib_xianyuan:get_xianyuan_level(State, 1, Ptype), 
			Xy_data_1 = lib_xianyuan:get_data_xianyuan(Ptype, Xy_type_lv_1),
			if  
				Xy_data_1 =:= #data_xianyuan{} ->				
					IsCding= 0;
				true -> 
					P_time = util:unixtime() - State#player_xianyuan.cdtime,
					if
						P_time > Xy_data_1#data_xianyuan.need_cdtime ->
							IsCding= 0;
						true ->
							IsCding= 1
					end
			end							
	end,
	case IsCding of
		1 -> % 有正在修炼的仙缘
			Result = 5, Need_closeness = 0,  State2 = State; 
		0 ->
			%% 需要修炼
			Xy_type_lv_2 = lib_xianyuan:get_xianyuan_level(State, 1, Xy_type),
			Xy_data_2 = lib_xianyuan:get_data_xianyuan(Xy_type, Xy_type_lv_2),
			if  %% 数据配置不全			
				Xy_data_2 =:= #data_xianyuan{} -> 
					Result = 2, Need_closeness = 0, State2 = State;
				%% 修炼达到最高级别
				Xy_type_lv_2 >= ?MAX_XY_LV ->			  
					Result = 8, Need_closeness = 0, State2 = State;
				%% 判断是否跨级(向上/向下)修炼
				true ->
					Last_Xy_type_lv = lib_xianyuan:get_xianyuan_level(State, 1, Ptype2),
					Last_Xy_data = lib_xianyuan:get_data_xianyuan(Ptype2, Last_Xy_type_lv),					
					Next = Last_Xy_data#data_xianyuan.nextcondition,
					case Next of
						[{Next_type,Next_lv}] ->
							case Next_type=:=Xy_type andalso Next_lv=:=(Xy_type_lv_2+1) of
								true ->
									Xy_data_3 = lib_xianyuan:get_data_xianyuan(Xy_type, Xy_type_lv_2+1),
									if   %% 数据配置不全			
										Xy_data_3 =:= #data_xianyuan{} ->
											Result = 2, Need_closeness = 0, State2 = State;
										true ->	%% 判断亲密度是否足够																			
											Need_closeness2 = Xy_data_3#data_xianyuan.need_closeness,
											if  %% 亲密度不够
												NCloseness =:= void orelse NCloseness < Need_closeness2  -> 
													Result = 4, Need_closeness = 0, State2 = State; 
												true ->											
													Result = 1, Need_closeness = Need_closeness2, State2 = State
											end
									end;
								false ->
									Result = 3, Need_closeness = 0, State2 = State
							end;
						[] ->
							Result = 2, Need_closeness = 0, State2 = State
					end										
			end
	end,
	{reply, [Result, Need_closeness], State2};


handle_call({xy_practice_commit, Xy_type, NCloseness, Need_closeness2, PS}, _From, State) ->
	Xy_type_lv = lib_xianyuan:get_xianyuan_level(State, 1, Xy_type),
	Player_xianyuan = lib_xianyuan:update(State, Xy_type, Xy_type_lv+1),
	%% 修炼日志
	NowTime = util:unixtime(),
	SQL = io_lib:format(?ADD_LOG_XIANYUAN, [PS#player_status.id, PS#player_status.nickname,
			NowTime, Xy_type,Xy_type_lv+1, NCloseness, NCloseness-Need_closeness2]),
	db:execute(SQL),
	Result = 1, State2 = Player_xianyuan,
	{reply, Result, State2};

handle_call({clearCD,PlayerStatus}, _From, State) ->
	%% 是否有正在修炼的仙缘
	Ptype = State#player_xianyuan.ptype,
	case Ptype of
		0->	%无正在修炼仙缘 
			RestCdTime = 0,
			IsCDing = 0;
		_-> 
			%% 正在修炼情况		
			Xy_type_lv = lib_xianyuan:get_xianyuan_level(State, 1, Ptype), 
			Xy_data = lib_xianyuan:get_data_xianyuan(Ptype, Xy_type_lv),
			if
				Xy_data=:=#data_xianyuan{} -> 
					RestCdTime = 0,
					IsCDing = 0;
                true -> 
					P_time = util:unixtime() - State#player_xianyuan.cdtime,
					if  
						P_time > Xy_data#data_xianyuan.need_cdtime -> 
							RestCdTime = 0,
							IsCDing = 0;
						true-> % 正在修炼仙缘
							RestCdTime = Xy_data#data_xianyuan.need_cdtime-P_time,
							IsCDing = 1
					end
			end
	end,
	case IsCDing of
		1->
		   %%计算元宝
		   Yb = RestCdTime div 60,		    
		   case RestCdTime rem 60 =/= 0 of
				true -> T_Yb = Yb+1;					
				false -> T_Yb = Yb					
			end,
		   %%VIP
		   Vip = PlayerStatus#player_status.vip,
		   Vip_type = Vip#status_vip.vip_type,
		   if
			   Vip_type =<3 andalso Vip_type >=1 ->
				   IsVip=1;
			   true ->
				   IsVip=0
			end,
			if
				IsVip=:=0 ->
						Yb2 = T_Yb;
				true -> Yb2 = 0
			end,
		   if
				PlayerStatus#player_status.gold<Yb2->
					Result = 3,Reply = ok,State2 = State;
				true->
					%%扣除金钱
					NewPlayer_Status = lib_goods_util:cost_money(PlayerStatus, Yb2, gold),
					% 写消费日志
					case Yb2>0 of
						true ->							
							About = lists:concat(["clearXyCD_",Ptype]),
							log:log_consume(xy_clearXyCD, gold, PlayerStatus, NewPlayer_Status, About),
							lib_player:refresh_client(NewPlayer_Status#player_status.id, 2);
						false ->
							skip
					end,
					%% --- 记录上一次修炼,激活夫妻技能[暂时屏蔽]--
					Xy_type_lv2 = lib_xianyuan:get_xianyuan_level(State, 1, Ptype),						
					lib_xianyuan:update_ptype_to_0(Ptype, NewPlayer_Status#player_status.id),	
					%% 升级夫妻技能
					NewPlayer_Status2 = lib_xianyuan:upgrade_cp_skill(NewPlayer_Status, Ptype, Xy_type_lv2),
					%%NewPlayer_Status2 = PlayerStatus,
					Result = 1,Reply = NewPlayer_Status2, State2 = State#player_xianyuan{ptype2=Ptype, ptype=0}
		   end;
		_->
		   Result = 2,Reply = ok,State2 = State
	end,
	{ok,BinData} = pt_272:write(27202,[Result]),
    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
    {reply, Reply, State2};

handle_call({xy_info, PlayerStatus}, _From, State) ->
	Ptype = State#player_xianyuan.ptype,	
	Ptype2 = State#player_xianyuan.ptype2,
    if 		
		%% 查询当前修炼,当前有修炼
		Ptype =/= 0 ->
			Ptime = util:unixtime() - State#player_xianyuan.cdtime,
			Jjie_lv = lib_xianyuan:get_xianyuan_level(State, 2, Ptype), 
			Xy_type_lv = lib_xianyuan:get_xianyuan_level(State, 1, Ptype), 
			Xy_data = lib_xianyuan:get_data_xianyuan(Ptype, Xy_type_lv),			
			if
				%% 修炼完成
				Ptime > Xy_data#data_xianyuan.need_cdtime  ->
					%% --- 记录上一次修炼,激活夫妻技能 [暂时屏蔽]--						
					lib_xianyuan:update_ptype_to_0(Ptype, PlayerStatus#player_status.id),
					%% =======升级夫妻技能=======
					NewPlayer_Status = lib_xianyuan:upgrade_cp_skill(PlayerStatus, Ptype, Xy_type_lv),	
					%%NewPlayer_Status = PlayerStatus,
					State2 = State#player_xianyuan{ptype2=Ptype, ptype=0},
					%%  判断是否修炼至终极
					case Ptype =:= 10 andalso Xy_type_lv >=?MAX_XY_LV of 
						true ->
							Xtype = Ptype, Xlv = Xy_type_lv;
						false ->
							Nextcondition = Xy_data#data_xianyuan.nextcondition,
							[{Ntype, Nlv}] = Nextcondition,								
							Xtype = Ntype, Xlv = Nlv
					end,					
					NewPS =NewPlayer_Status, Jlv = Jjie_lv, RestCdTime = 0, IsCDing = 0, NotifyFlag=1;
					%% 正在修炼
				true ->
					State2 =State, Xtype = Ptype, Xlv = Xy_type_lv, Jlv = Jjie_lv,
					RestCdTime = Xy_data#data_xianyuan.need_cdtime - Ptime,
					IsCDing = 1, NewPS= PlayerStatus, NotifyFlag=0
			end;
			%% 查询上一次修炼,当前无修炼
		true ->
			Jjie_lv = lib_xianyuan:get_xianyuan_level(State, 2, Ptype2), 
			Xy_type_lv = lib_xianyuan:get_xianyuan_level(State, 1, Ptype2), 			
			Xy_data = lib_xianyuan:get_data_xianyuan(Ptype2, Xy_type_lv),
			%% 判断是否修炼至终极
			case Ptype2 =:= 10 andalso Xy_type_lv >=?MAX_XY_LV of 
				true ->
					Xtype = Ptype2, Xlv = Xy_type_lv;
				false ->
					Nextcondition = Xy_data#data_xianyuan.nextcondition,
					[{Ntype, Nlv}] = Nextcondition,								
					Xtype = Ntype, Xlv = Nlv
			end,			
			Jlv = Jjie_lv, State2 =State, RestCdTime = 0, IsCDing = 0,NewPS= PlayerStatus,NotifyFlag=0	
	end,	
	{reply, {Xtype, Xlv, Jlv, RestCdTime, IsCDing, NewPS, NotifyFlag}, State2};

handle_call({getPlayer_xianyuan}, _From, State) ->
	{reply, State, State};

handle_call({use_sweet_goods, PS}, _From, State) ->
	ReturnCode = lib_xianyuan:use_sweet_goods(PS, State),
	case ReturnCode of
		1 ->						
		%% --- 触发境界--		
		NJlevel = State#player_xianyuan.jjie,
		%% 获取甜蜜果使用效果
		Sweetness_add =data_xianyuan_sweetness:get_sweetness(State#player_xianyuan.sweetness),
		NSweetness =  State#player_xianyuan.sweetness+Sweetness_add,
		Jlevel = lib_xianyuan:trigger_jjie(PS, NJlevel, NSweetness),
		case Jlevel > NJlevel of
			true ->
				%% 更新甜蜜度以及境界级别
				NewState = State#player_xianyuan{sweetness=NSweetness, jjie=Jlevel},
				lib_xianyuan:update_jjie([Jlevel, NSweetness], PS#player_status.id);
			false ->
				%% 更新甜蜜度
				NewState = State#player_xianyuan{sweetness=NSweetness},
				lib_xianyuan:update_sweet(NSweetness, PS#player_status.id)
		end;
		_ ->
			NewState = State, Sweetness_add=0
	end,
	{reply, {ReturnCode, Sweetness_add}, NewState};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_xianyuan:handle_call not match: ~p~n", [Event]),
    {reply, ok, Status}.

%%停止游戏进程
handle_cast(stop, State) ->
    {stop, normal, State};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_xianyuan:handle_cast not match: ~p~n", [Event]),
    {noreply, Status}.

%% handle_info信息处理
%% 默认匹配
handle_info(Info, Status) ->
    catch util:errlog("mod_xianyuan:handle_info not match: ~p~n", [Info]),
    {noreply, Status}.

terminate(_Reason, _Status) ->
    %catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

