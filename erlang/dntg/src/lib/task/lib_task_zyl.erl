%%%-----------------------------------
%%% @Module  : lib_task_zyl
%%% @Author  : hekai
%%% @Created : 2012.07.31
%%% @Description: 诛妖令
%%%-----------------------------------
-module(lib_task_zyl).
-compile(export_all).
-include("server.hrl").
-include("goods.hrl").
-include("def_goods.hrl").
-define(update_player_coin_exp,<<"update `player_high` set  `bcoin`=~p, `exp`=~p where id=~p">>).
-define(get_palyer_lv,<<"select  `lv`  from `player_low` where id=~p limit 1">>).


online(Status) ->
    gen_server:call(Status#player_status.pid, {'apply_call', lib_task_zyl, online_on_pid, [Status]}).


online_on_pid(Status) ->   
	load_num(Status),   
    ok.

%% 获取当前拥有诛妖帖数量、已发布、领取数量
get_num(Status) ->
	Color = [1, 2, 3, 4],	
	[[Type,goodsNum(Status, "zyl_id_"++integer_to_list(Type)),get("zyl_publish_" ++ integer_to_list(Type)), get("zyl_bget_" ++ integer_to_list(Type))]||Type<-Color].


%% 加载诛妖令已发布、被领取数量;
load_num(Status) ->
    Color = [1, 2, 3, 4],	
	%% 加载诛妖令已发布、被领取数量 
	F1 = fun(Type1) ->  
		SQL1_1 = io_lib:format("select count(*) from task_zyl where role_id = ~p and type = ~p",[Status#player_status.id, Type1]),
		SQL1_2 = io_lib:format("select count(*) from task_zyl where role_id = ~p and type = ~p and status = ~p",[Status#player_status.id, Type1, 1]),
		[Num1_1] = db:get_row(SQL1_1),
        [Num1_2] = db:get_row(SQL1_2),
		Tp1 = integer_to_list(Type1),		
		%% 已发布
		DictType1 = "zyl_publish_" ++ Tp1,
        erase(DictType1),
		put(DictType1,Num1_1),

		%% 被领取
		DictType2 = "zyl_bget_" ++ Tp1,			
		erase(DictType2),
		put(DictType2,Num1_2)			
		end,
	lists:map(F1, Color),
     
	%% 加载我的诛妖任务,控制品质
	SQL_color = io_lib:format("select task_id,type from log_zyl where role_id = ~p and status= ~p",[Status#player_status.id, 0]),
	My_color = db:get_all(SQL_color),
    
	erase(zyl_my_color),
	case length(My_color)>0 of
		true ->			
			F = fun(Task_Id, My_Color) ->
					IS_trigger_30000 =lib_task:get_one_trigger(Status#player_status.tid , Task_Id),
					case IS_trigger_30000 of
						false -> 
							%% 两端不匹配:删除对应品质数据
							SQL = io_lib:format("delete  from  log_zyl  where type = ~p and role_id = ~p",[My_Color, Status#player_status.id]),							
    						db:execute(SQL),                        
							My_color_dict = get(zyl_my_color),
							case My_color_dict /= undefined of
								true -> skip;
								false -> put(zyl_my_color, [])
							end;
						_ ->
							%% 加载我的诛妖品质
							My_color_dict = get(zyl_my_color),
							case My_color_dict /= undefined of
								true ->	put(zyl_my_color, [My_Color|My_color_dict]);
								false -> put(zyl_my_color, [My_Color])
							end	
					end
				end,
			[F(X,Y)||[X,Y]<-My_color];
		false ->  put(zyl_my_color, [])					
	end.
	
%% 发布诛妖令
publish_zyl(Status, Type) ->
	%% 更新缓存:已发布诛妖令
	Tp = integer_to_list(Type),
    DictType = "zyl_publish_" ++ Tp,	
	Publish_num = get(DictType),
	case Publish_num of
		undefined ->
			put(DictType, 1);
		_ ->
			put(DictType, Publish_num +1)
	end,	
    %% 更新诛妖榜
	Zyl_now = get_zyl_now(Type),
	set_zyl_now(Zyl_now +1 ,Type),
    
	%%mod_active:trigger(Status#player_status.status_active, 11, 0, Status#player_status.vip#status_vip.vip_type),
    Time = util:unixtime(),
	mod_daily:increment(Status#player_status.dailypid, Status#player_status.id, 5000040),
    lib_qixi:update_player_task(Status#player_status.id, 4),
	SQL = io_lib:format("insert into task_zyl (type, role_id, publish_time, status) values (~p,~p,~p,~p)  ", [Type, Status#player_status.id, Time, 0]),
    db:execute(SQL),
	%% 随机额外发布玩法
	private_auto_rand_publish(Type),
	%% 诛妖帖品质自动转换
	case Type =:=1 andalso Zyl_now >= 1025 of
		true -> 
			SQL1 = io_lib:format("select id,role_id from task_zyl where type = ~p and status = ~p  order by publish_time asc limit 1025",[1, 0]),
			Task_zyl = db:get_all(SQL1),			
			private_auto_convert_db(Task_zyl),
			timer:sleep(2*1000),
			%%　更新诛妖榜帖子数量缓存
			Zyl_now1 = get_zyl_now(Type),
			set_zyl_now(Zyl_now1 -1025 ,Type),    
			Zyl_now2 = get_zyl_now(2),
			set_zyl_now(Zyl_now2 +(1025 div 25), 2),
			%% 诛妖令被领取奖励、通知
			private_auto_convert_msg(lists:filter(fun([_, Publisher]) ->
									 Publisher =/= 0
									 end, Task_zyl));	
		false -> skip
	end.

private_auto_rand_publish(Type) ->
	BaseNum = 1000,
	Type2 = Type +1,
	IsAutoPublish =
	case Type of
		1 -> util:rand(1, BaseNum)=< 20;
		2 -> util:rand(1, BaseNum)=< 5;
		3 -> util:rand(1, BaseNum)=< 1;
		_ -> false
	end,
	case IsAutoPublish of
		true ->
			SQL = io_lib:format("insert into task_zyl (type, role_id, publish_time, status) values (~p,~p,~p,~p)  ", [Type2, 0, util:unixtime(), 0]),
			db:execute(SQL),
			Zyl_now = get_zyl_now(Type2),
			set_zyl_now(Zyl_now +1 ,Type2);
		false -> skip
	end.

private_auto_convert_msg(Zyt_list) ->
	F = fun(Role_id)	->
			bget_reward_msg(Role_id, 1)	
	end,
	spawn(
	fun() ->
		lists:foldl(
			fun([_, Role_id], Counter) ->
					catch F(Role_id),
					case Counter < 50 of
						true ->
							Counter + 1;
						false ->
							timer:sleep(200),
							1
					end
			end, 1, Zyt_list)
		end).

private_auto_convert_db(Zyt_list) ->
	Time = util:unixtime(),
	spawn(
	fun() ->
		lists:foldl(
			fun([Id, _], Counter) ->
				case Counter < 26 of
					true ->
						SQL2 = io_lib:format("update task_zyl set  status =~p  where id = ~p",[1, Id]),
                        db:execute(SQL2),					
						Counter + 1;
					false ->
						SQL3 = io_lib:format("insert into task_zyl (type, role_id, publish_time, status) values (~p,~p,~p,~p)  ", [2, 0, Time, 0]),			
						db:execute(SQL3),
						timer:sleep(100),
						1
				end
			end, 1, Zyt_list)
	end).

%% 领取诛妖令
get_zyl(Status, Type, TaskId) ->
    Time = util:unixtime(),
	SQL1 = io_lib:format("select id,role_id from task_zyl where type = ~p and status = ~p  order by publish_time asc limit 1",[Type, 0]),

	Task_zyl = db:get_row(SQL1),
	case Task_zyl =/= [] of
		true ->
			[Id, Role_id] =  Task_zyl,
			SQL2 = io_lib:format("update task_zyl set  status =~p  where id = ~p",[1, Id]),
			SQL3 = io_lib:format("insert into log_zyl (type, role_id, get_time, status, task_id) values(~p,~p,~p,~p,~p)",[Type, Status#player_status.id, Time, 0, TaskId]),
			F = fun()->
				db:execute(SQL2),
				db:execute(SQL3)
			end,
			db:transaction(F),
    
			%% 诛妖贴品质控制
			My_color = get(zyl_my_color),
			case My_color of
				undefined ->
					Len = 0;
				_ ->
					Len = length(My_color)
			end,			
			case Len <1 of
				true ->  put(zyl_my_color,[Type]);
				false -> put(zyl_my_color,[Type|My_color])
			end,
            
			%% 更新诛妖榜帖子数量
			Zyl_now = get_zyl_now(Type),
			case Zyl_now >=1 of
				true -> set_zyl_now(Zyl_now-1,Type);
				false -> set_zyl_now(0,Type)
			end,
			lib_qixi:update_player_task(Status#player_status.id, 4),

			set_daily(Status, Type),
   			Role_id;
		false ->
			%% 修正缓存与数据库不同步
			set_zyl_now(0,Type),
			null
	end.


%% 完成诛妖令任务
finish_task(TaskId, ParamList, PS) ->
    lib_player:rpc_cast_by_id(PS#player_status.id, lib_task_zyl, finish_task_on_pid, [PS, TaskId]),
    %% mod_achieve:trigger_task(PS#player_status.achieve, PS#player_status.id, 15, 0, 1),
	%%lib_task_cumulate:finish_task(PS#player_status.id, 3),
	mod_task:normal_finish(TaskId, ParamList, PS).
	
finish_task_on_pid(Status, TaskId) ->
    Level = Status#player_status.lv,
    TaskZyl = data_task_zyl_lv:get_ids(Level),
	C =[Color||[Color, Id] <-TaskZyl, Id =:= TaskId],
	case C =/= [] of
		true ->
			private_finish_task(Status, C);
		false ->
			TaskZyl2 = data_task_zyl_lv:get_ids(Level-10),
			C2 =[Color2||[Color2, Id2] <-TaskZyl2, Id2 =:= TaskId],
			case C2 =/= [] of
				true -> private_finish_task(Status, C2);
				false -> skip
			end
	end.

private_finish_task(Status, C) ->
	[C1] = C,
	My_color = get(zyl_my_color),
	case My_color =/= undefined of
		true ->
			My_color2 = lists:delete(C1,My_color),
			put(zyl_my_color,My_color2);
		false -> skip
	end,			
	%% 数据库处理:删除对应品质数据
	SQL = io_lib:format("delete  from  log_zyl  where type = ~p and role_id = ~p",[C1, Status#player_status.id]),
	db:execute(SQL).

%% 放弃任务,用于任务追踪栏
cancel_task(PS, TaskId) ->
    %% finish_task_on_pid(PS, TaskId).
    lib_player:rpc_cast_by_id(PS#player_status.id, lib_task_zyl, finish_task_on_pid, [PS, TaskId]).

%% 获取物品数量
goodsNum(Status, Type_id) ->
    GoodsTypeId = data_task_zyl:get_task_config(Type_id, []),
    lib_goods_info:get_goods_num(Status, GoodsTypeId, 0).	


%% 获取每日领取的诛妖令
get_daily(Status, Type) ->
	Dialy_id = case Type of
					1 -> 5000050; 
					2 -> 5000060;
					3 -> 5000070;
					4 -> 5000080;
					_ -> 0
					end,
	mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, Dialy_id).

%% 设置每日领取诛妖令加1
set_daily(Status, Type) ->
	Dialy_id = case Type of
					1 -> 5000050; 
					2 -> 5000060;
					3 -> 5000070;
					4 -> 5000080;
					_ -> 0
				end,
	mod_daily:increment(Status#player_status.dailypid, Status#player_status.id, 5000090),
	mod_daily:increment(Status#player_status.dailypid, Status#player_status.id, Dialy_id).

%% 设置诛妖榜某品质现有诛妖贴数量
set_zyl_now(Num,Type) ->
   gen_server:call(misc:get_global_pid(mod_task_zyl), {set_zyl_now, [Num,Type]}).

%% 获取诛妖榜某品质现有诛妖贴数量
get_zyl_now(Type) ->
   gen_server:call(misc:get_global_pid(mod_task_zyl), {get_zyl_now, [Type]}).

%% 重置全局诛妖帖任务
rest_zyl() ->
	gen_server:cast(misc:get_global_pid(mod_task_zyl), {reset_zyl}).

%% 更新用户诛妖帖被领数量缓存
update_bget(Type) ->
	Tp = integer_to_list(Type),				
	%% 被领取
	DictType = "zyl_bget_" ++ Tp,			
	Bget = get(DictType),
	Bget2 = 
	case Bget =:= undefined of
		true -> 0;
		false -> Bget + 1
	end,
	put(DictType, Bget2).

%% 离线用户诛妖贴被领取奖励
outline_reward(Bcoin, Exp, Role_id) ->
	case lib_player:get_player_high_data(Role_id) of
		[_Gold, _Bgold, _Coin, Bcoin_num, Exp_num] ->
			TotalBCoin = Bcoin_num + Bcoin,
            TotalExp = Exp_num + Exp,
			SQL = io_lib:format(?update_player_coin_exp,[TotalBCoin, TotalExp, Role_id]),
		    db:execute(SQL);
		_ ->
			skip
	end.

%% 在线用户诛妖贴被领取奖励
online_reward(Coin, Exp, Role_id) ->
	case misc:get_player_process(Role_id) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'task_zyl_reward', Coin, Exp});
        _ ->
            void
    end.   

%% 获取玩家等级
get_palyer_lv(RoleId) ->
 	Lv = db:get_row(io_lib:format(?get_palyer_lv, [RoleId])),
	case Lv =/= [] of
		true -> [Level] = Lv, Level;
		false -> 0
	end.


%% 诛妖令被领取奖励、通知 
bget_reward_msg(Publish_Role_id, Type) ->
	Player_lv = get_palyer_lv(Publish_Role_id),
	Lv = Player_lv div 10,
	Bcoin = data_task_zyl:get_zyl_coin(Lv, Type),
	Exp =data_task_zyl:get_zyl_exp(Lv, Type),
	case lib_player:is_online_global(Publish_Role_id)  of
		true ->
			%%Pub_PS = lib_player:get_player_info(Publish_Role_id),
			%% 在线用户诛妖贴被领取奖励
			online_reward(Bcoin, Exp, Publish_Role_id),
			%% 更新用户诛妖帖被领数量缓存
			lib_player:rpc_cast_by_id(Publish_Role_id, lib_task_zyl, update_bget, [Type]),
			{ok, Bindata} = pt_307:write(30704, [Bcoin, Exp]),
			%% 发送被领取通知
			lib_server_send:send_to_uid(Publish_Role_id, Bindata);
		false ->
			%% 离线用户诛妖贴被领取奖励 
			outline_reward(Bcoin, Exp, Publish_Role_id)
	end.


dict_get(DictType) ->
	erlang:get(DictType).
    
dict_put(DictType, Value) ->
	erlang:put(DictType, Value).

dict_erase(DictType) ->
	erlang:erase(DictType).

%% -----------------------------------------------------------------
%% 获取物品信息
%% -----------------------------------------------------------------
get_goods_type_by_type_info(GoodsType, GoodsSubType) ->
    case data_goods_type:get_by_type(GoodsType, GoodsSubType) of
        [] -> [];
        [Id|_] -> data_goods_type:get(Id)
    end.

%% -----------------------------------------------------------------
%% 获取物品类型
%% -----------------------------------------------------------------
get_goods_type(GoodsId) ->
    data_goods_type:get(GoodsId).

