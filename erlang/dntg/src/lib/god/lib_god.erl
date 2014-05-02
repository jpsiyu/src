%% Author: Administrator
%% Created: 2013-1-4
%% Description: TODO: Add description to lib_god
-module(lib_god).

%%
%% Include files
%%
-include("server.hrl").
-include("unite.hrl").
-include("god.hrl").
%%
%% Exported Functions
%%
-compile(export_all).

%%
%% API Functions
%%

execute_48501(UniteStatus,Mod,Status,Config_end_time)->
	{Hour,Minutes,Second} = time(),
	Now_time = (Hour*60 + Minutes)*60 + Second,
	if
		Status/=1->
			ResTime = 0;
		true->
			if
				Now_time>Config_end_time->
					ResTime = 0;
				true->
					ResTime = Config_end_time-Now_time
			end
	end,
	God_no = data_god:get_god_no(data_god:get(open_day)),
	{ok, BinData} = pt_485:write(48501, [Mod,Status,ResTime,God_no]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_48502(UniteStatus,Combat_power)->
	Plat = config:get_platform(),
	Server_id = config:get_server_num(),
	Node = mod_disperse:get_clusters_node(),
	case lib_player:get_player_info(UniteStatus#unite_status.id,hightest_combat_power) of
		Result when is_integer(Result)->
			Hightest_combat_power = Result;
		_->
			Hightest_combat_power = 0
	end,
	mod_clusters_node:apply_cast(mod_god,goin,[out,Node,Plat,Server_id,
											   UniteStatus#unite_status.id,UniteStatus#unite_status.name,
											   UniteStatus#unite_status.realm,UniteStatus#unite_status.sex,
											   UniteStatus#unite_status.career,UniteStatus#unite_status.image,
											   UniteStatus#unite_status.lv,Combat_power,Hightest_combat_power]),
	ok.

execute_48503(UniteStatus)->
	God_Scene_id_flag1 = lists:member(UniteStatus#unite_status.scene, data_god:get(scene_id1)),
	if
		God_Scene_id_flag1 =:= true->
			Plat = config:get_platform(),
			Server_id = config:get_server_num(),
			Node = mod_disperse:get_clusters_node(),
			mod_clusters_node:apply_cast(mod_god,goout,[Node,Plat,Server_id,UniteStatus#unite_status.id]);
		true->
			void
	end,
	ok.

execute_48506(UniteStatus,Params,Mod)->
	God_Scene_id_flag1 = lists:member(UniteStatus#unite_status.scene, data_god:get(scene_id1)),
	if
		God_Scene_id_flag1 =:= true andalso Mod>=1 andalso Mod=<3->%%总决赛不能选择对手
			Plat = config:get_platform(),
			Server_id = config:get_server_num(),
			Node = mod_disperse:get_clusters_node(),
			[B_plat,B_server_id,B_id] = Params,
			mod_clusters_node:apply_cast(mod_god,select_enemy,
										 [Node,Plat,Server_id,UniteStatus#unite_status.id,
										  B_plat,B_server_id,B_id]);
		true->void
	end,
	ok.

execute_48511(UniteStatus)->
	Plat = config:get_platform(),
	Server_id = config:get_server_num(),
	Node = mod_disperse:get_clusters_node(),
	mod_clusters_node:apply_cast(mod_god,pk_list,
		[Node,Plat,Server_id,UniteStatus#unite_status.id]),
	ok.

execute_48512(UniteStatus,Params)->
	[Room_no] = Params,
	Plat = config:get_platform(),
	Server_id = config:get_server_num(),
	mod_god_state:top_list(Plat,Server_id,UniteStatus#unite_status.id,Room_no),
	ok.

execute_48514(UniteStatus,Params)->
	[Flat,Server_id,Id] = Params,
	PalyerStatus = lib_player:get_player_info(UniteStatus#unite_status.id),
	mod_god_state:vote_relive(PalyerStatus,Flat,Server_id,Id),
	ok.

execute_48515(UniteStatus,Mod)->
	God_Scene_id_flag1 = lists:member(UniteStatus#unite_status.scene, data_god:get(scene_id1)),
	if
		God_Scene_id_flag1 =:= true andalso Mod>=1 andalso Mod=<3->%%总决赛不能选择对手
			Plat = config:get_platform(),
			Server_id = config:get_server_num(),
			Node = mod_disperse:get_clusters_node(),
			mod_clusters_node:apply_cast(mod_god,system_select,
										 [Node,Plat,Server_id,UniteStatus#unite_status.id]);
		true->void
	end,
	ok.

execute_48516(UniteStatus,Params)->
	[God_no] = Params,
	Temp_God_list = mod_god_state:get_god_top50(God_no),
	God_list = [{
		G#god.flat,							
		G#god.server_id,          
		G#god.id,									
		G#god.god_no,           						
		G#god.name,							
		G#god.country,						
		G#god.sex,								
		G#god.carrer,							
		G#god.image,							
		G#god.lv,									
		max(G#god.power,G#god.high_power),							
		G#god.sea_win_loop,				
		G#god.sea_loop,						
		G#god.sea_score,					
		G#god.group_room_no,			
		G#god.group_win_loop,			
		G#god.group_loop,					
		G#god.group_score,				
		G#god.group_vote,					
		G#god.group_relive_is_up,	
		G#god.relive_win_loop,		
		G#god.relive_loop,				
		G#god.relive_score,				
		G#god.relive_vote,				
		G#god.sort_win_loop,			
		G#god.sort_loop,					
		G#god.sort_score,					
		G#god.sort_vote,					
		G#god.praise,							
		G#god.despise		 
	}||G<-Temp_God_list],
	%%验证次数是否用完
	case lib_player:get_player_info(UniteStatus#unite_status.id,god) of
		God when is_record(God, status_god)->
			{Year,Month,Day} = date(),
			{{L_Year,L_Month,L_Day},_} = calendar:now_to_local_time(util:unixtime_to_now(God#status_god.bs_time)),
			Max_bs_num = data_god:get(max_bs_num),
			if
				Year=:=L_Year andalso Month=:=L_Month andalso Day=:=L_Day-> %%同一天
					Temp_RestBs = Max_bs_num - God#status_god.bs_num,
					if
						Temp_RestBs<0->
							RestBs = 0;
						true->
							RestBs = Temp_RestBs
					end;
				true->
					RestBs = Max_bs_num
			end;
		_->
			RestBs = 0
	end,
	{ok, BinData} = pt_485:write(48516, [God_list,RestBs]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_48517(UniteStatus,Params)->
	[Flat,Server_id,Id,God_no,Type] = Params,
	Min_bs_lv = data_god:get(min_bs_lv),
	if
		Min_bs_lv=<UniteStatus#unite_status.lv->
			%%验证次数是否用完
			case lib_player:get_player_info(UniteStatus#unite_status.id, god) of
				God when is_record(God, status_god)->
					{Year,Month,Day} = date(),
					{{L_Year,L_Month,L_Day},_} = calendar:now_to_local_time(util:unixtime_to_now(God#status_god.bs_time)),
					Max_bs_num = data_god:get(max_bs_num),
					if
						Year=:=L_Year andalso Month=:=L_Month andalso Day=:=L_Day-> %%同一天
							Temp_RestBs = Max_bs_num - God#status_god.bs_num,
							if
								Temp_RestBs<0->
									RestBs = 0;
								true->
									RestBs = Temp_RestBs
							end,
							if
								RestBs=:=0-> %%无次数
									{ok, BinData} = pt_485:write(48517, [Flat,Server_id,Id,God_no,Type,3,RestBs]),
		    						lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
								true->
									mod_god_state:bs(UniteStatus#unite_status.id,RestBs-1,Flat,Server_id,Id,God_no,Type)
							end;
						true->
							RestBs = Max_bs_num-1,
							mod_god_state:bs(UniteStatus#unite_status.id,RestBs,Flat,Server_id,Id,God_no,Type)
					end;
				_R->
					{ok, BinData} = pt_485:write(48517, [Flat,Server_id,Id,God_no,Type,4,0]),
		    		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
			end;
		true->
			{ok, BinData} = pt_485:write(48517, [Flat,Server_id,Id,God_no,Type,4,0]),
    		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end,
	ok.

%%按模式获得对应积分
get_score(Mod,God)->
	case Mod of
		1->God#god.sea_score;
		2->God#god.group_score;
		3->God#god.relive_score;
		4->God#god.sort_score;
		_->0
	end.

%%检测是否是成员top50
member([],_Flat,_Server_id,_Id,_God_no)->{error,no_match};
member([G|T],Flat,Server_id,Id,God_no)->	
	if
		G#god.flat=:=Flat andalso G#god.server_id=:=Server_id andalso G#god.id=:=Id->
			{ok,G};
		true->
			member(T,Flat,Server_id,Id,God_no)
	end.

%%提供给mod_server_cast使用
set_data_sub(Status)->
	Now_time = util:unixtime(),
	{Year,Month,Day} = date(),
	{{L_Year,L_Month,L_Day},_} = calendar:now_to_local_time(util:unixtime_to_now(Status#player_status.god#status_god.bs_time)),
	if
		Year=:=L_Year andalso Month=:=L_Month andalso Day=:=L_Day-> %%同一天
			Bs_num = Status#player_status.god#status_god.bs_num + 1,
			lib_god:update_player_god(Status#player_status.id,Bs_num,Now_time);
		true->%%不是同一天
			Bs_num = 1,
			if
				Status#player_status.god#status_god.bs_time=<0-> %%没有记录
					lib_god:insert_player_god(Status#player_status.id,Bs_num,Now_time);
				true-> %%有记录
					lib_god:update_player_god(Status#player_status.id,Bs_num,Now_time)
			end
	end,
	New_God = Status#player_status.god#status_god{
		bs_num = Bs_num,
		bs_time = Now_time
	},
	Status#player_status{
		god = New_God
	}.

%%加载玩家BS记录
load_player_god(Id)->
	SQL = io_lib:format(<<"select * from player_god where id=~p">>,[Id]),
	case db:get_row(SQL) of
		[] ->
			#status_god{};
		L ->
			list_to_tuple([status_god|L])
	end.

%%插入记录
insert_player_god(Id,Bs_num,Bs_time)->
	SQL = io_lib:format(<<"insert into player_god(id,bs_num,bs_time) values(~p,~p,~p)">>,[Id,Bs_num,Bs_time]),
	db:execute(SQL),
	ok.
	
%%更改玩家鄙视记录
update_player_god(Id,Bs_num,Bs_time)->
	SQL = io_lib:format(<<"update player_god set bs_num=~p,bs_time=~p where id=~p">>,[Bs_num,Bs_time,Id]),
	db:execute(SQL),
	ok.

%%人气PK投票，扣除材料
vote_relive(PlayerStatus)->
	Xinyangzhixin_id = data_god:get(xinyangzhixin_id),
	%%扣除材料
    Flag = lib_meridian:delete_goods(PlayerStatus,[[Xinyangzhixin_id,1]]),
	case Flag of
		false->void;
		true->
			log:log_throw(vote_relive, PlayerStatus#player_status.id, 0, Xinyangzhixin_id, 1, 0, 0)
	end,
	Flag.

%%投票胜出的名额差
lists_elements([],_Temp_Top15,Size)->Size;
lists_elements([God|T],Temp_Top15,Size)->
	Flag = lists:member(God, Temp_Top15),										   
	case Flag of
		false->
			lists_elements(T,Temp_Top15,Size);
		true->
			lists_elements(T,Temp_Top15,Size+1)
	end.

%%对投票人员进行猜中与否奖励
%% @param Top2 [#god]
vote_relive_balance(Top2)->
	Y_gift_id = data_god:get(y_vote_relive_gift_id),	
	N_gift_id = data_god:get(n_vote_relive_gift_id),
	_Xinyangzhixin_id = data_god:get(xinyangzhixin_id),
	Title1 = data_mail_log_text:get_mail_log_text(god_title_vote_relive6),
	Title2 = data_mail_log_text:get_mail_log_text(god_title_vote_relive7),

	{Top2Str,TopListStr} = make_str_4_vote_relive(Top2,"",""),
	%%找出猜中的ID，并发奖
	SQL1 = io_lib:format(<<"select id_a,count(*) from vote_relive 
						   where concat(flat_b,'_',server_id_b,'_',id_b) in (~s) 
						   group by id_a">>,
						[Top2Str]),
	Y_vote_list = db:get_all(SQL1),
	lists:foreach(fun([Id_a,Count])-> 
		if
			Count>100->_Gift_num = 100;
			Count>0->_Gift_num = Count;
			true->_Gift_num = 1
		end,
		Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_vote_relive6),[TopListStr,Count]),
		%%礼包
		lib_mail:send_sys_mail_bg([Id_a], Title1, Content, Y_gift_id, 2, 0, 0,Count,0,0,0,0),
		timer:sleep(200)
		%%信仰之心
%% 		lib_mail:send_sys_mail_bg([Id_a], Title1, Content, Xinyangzhixin_id, 2, 0, 0,Gift_num,0,0,0,0),
%% 		timer:sleep(200)
	end, Y_vote_list),
	%%找出没有猜中的ID，并发奖
	SQL2 = io_lib:format(<<"select id_a,count(*) from vote_relive 
						   where concat(flat_b,'_',server_id_b,'_',id_b) not in (~s) 
						   group by id_a">>,
							[Top2Str]),
	N_vote_list = db:get_all(SQL2),	
	lists:foreach(fun([Id_a,Count])-> 
		Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_vote_relive7),[TopListStr,Count]),
		lib_mail:send_sys_mail_bg([Id_a], Title2, Content, N_gift_id, 2, 0, 0,Count,0,0,0,0),
		timer:sleep(200)
	end, N_vote_list).
make_str_4_vote_relive([],Top2Str,TopListStr)->
	if
		Top2Str=:=""-> New_Top2Str = "''";
		true-> New_Top2Str = Top2Str
	end,
	{New_Top2Str,TopListStr};
make_str_4_vote_relive([God|T],Top2Str,TopListStr)->	
	if
		Top2Str=:=""->
			New_Top2Str = "'" ++ God#god.flat ++ "_" 
							  ++ integer_to_list(God#god.server_id) ++ "_" 
							  ++ integer_to_list(God#god.id) ++ "'";
		true->
			New_Top2Str = Top2Str ++ ",'" ++ God#god.flat ++ "_" 
							  ++ integer_to_list(God#god.server_id) ++ "_" 
							  ++ integer_to_list(God#god.id) ++ "'" 
	end,
	Plat = config:get_platform(),
	Server = data_mail_log_text:get_mail_log_text(server),
	if
		Plat =:= God#god.flat ->
			Plat_txt = data_mail_log_text:get_mail_log_text(plat_b);
		true->
			Plat_txt = data_mail_log_text:get_mail_log_text(plat_w)
	end,
	if
		TopListStr=:=""->
			New_TopListStr = Plat_txt ++ integer_to_list(God#god.server_id) ++ Server ++ God#god.name;
		true->
			New_TopListStr = TopListStr ++ "、" ++ Plat_txt ++ integer_to_list(God#god.server_id) ++ Server ++ God#god.name
	end,
	make_str_4_vote_relive(T,New_Top2Str,New_TopListStr).

%%添加诸神经验
insert_into_god_exp(Uid,Name,Country,Sex,Carrer,Image,Btime,Etime,Rate,Pos,Time)->
	SQL = io_lib:format(<<"insert into god_exp(uid,name,country,sex,carrer,image,b_time,e_time,rate,pos,time) 
						   values(~p,'~s',~p,~p,~p,~p,~p,~p,~p,~p,~p)">>,
						[Uid,Name,Country,Sex,Carrer,Image,Btime,Etime,Rate,Pos,Time]),
	db:execute(SQL),
	ok.

%%清楚过期的诸神记录
delete_god_exp()->
	Now_time = util:unixtime(),
	SQL = io_lib:format(<<"delete from god_exp where e_time<~p">>,[Now_time]),
	db:execute(SQL),
	ok.

%%加载诸神经验
load_god_exp()->
	SQL = io_lib:format(<<"select * from god_exp">>,[]),
	db:get_all(SQL).

%%人气PK投票日志
insert_into_vote_relive(Id_a,Flat_b,Server_id_b,Id_b)->
	SQL = io_lib:format(<<"insert into vote_relive (Id_a,Flat_b,Server_id_b,Id_b) 
						   values(~p,'~s',~p,~p)">>,
						[Id_a,Flat_b,Server_id_b,Id_b]),
	db:execute(SQL),
	ok.

%%删除人气PK记录
delete_vote_relive()->
	SQL = io_lib:format(<<"delete from vote_relive">>,[]),
	db:execute(SQL),
	ok.

%% 人气PK投票
update_vote_relive(Flat,Server_id,Id,God_no)->
	SQL = io_lib:format(<<"update god set relive_vote=relive_vote+1 
						   where flat='~s' and server_id=~p and id=~p and god_no=~p">>,
						[Flat,Server_id,Id,God_no]),
	db:execute(SQL),
	ok.

%%更新总决赛记录
update_god_sort(Flat,Server_id,Id,God_no,Node,Sort_win_loop,Sort_loop,Sort_score)->
	SQL = io_lib:format(<<"update god set sort_win_loop=~p,sort_loop=~p,sort_score=~p,node='~s' 
						   where flat='~s' and server_id=~p and id=~p and god_no=~p">>,
						[Sort_win_loop,Sort_loop,Sort_score,Node,Flat,Server_id,Id,God_no]),
	db:execute(SQL),
	ok.

%%更新复活赛记录
update_god_relive(Flat,Server_id,Id,God_no,Node,Relive_win_loop,Relive_loop,Relive_score)->
	SQL = io_lib:format(<<"update god set relive_win_loop=~p,relive_loop=~p,relive_score=~p,node='~s' 
						   where flat='~s' and server_id=~p and id=~p and god_no=~p">>,
						[Relive_win_loop,Relive_loop,Relive_score,Node,Flat,Server_id,Id,God_no]),
	db:execute(SQL),
	ok.

%%更新复活赛提拔记录
update_god_is_relive_balace(God_no)->
	SQL = io_lib:format(<<"update god set is_relive_balace=1 where god_no=~p">>,[God_no]),
	db:execute(SQL),
	ok.

update_god_bs(Flat,Server_id,Id,God_no,Praise,Despise)->
	SQL = io_lib:format(<<"update god set praise=~p,despise=~p where flat='~s' and server_id=~p and id=~p and god_no=~p">>,[Praise,Despise,Flat,Server_id,Id,God_no]),
	db:execute(SQL),
	ok.

%%更新小组赛晋级资格
update_group_relive_is_up(Flat,Server_id,Id,God_no,Node,Group_relive_is_up)->
	SQL = io_lib:format(<<"update god set group_relive_is_up=~p,node='~s' 
						   where flat='~s' and server_id=~p and id=~p and god_no=~p">>,
						[Group_relive_is_up,Node,Flat,Server_id,Id,God_no]),
	db:execute(SQL),
	ok.

%%更新小组赛记录
update_god_group(Flat,Server_id,Id,God_no,Node,Group_win_loop,Group_loop,Group_score)->
	SQL = io_lib:format(<<"update god set group_win_loop=~p,group_loop=~p,group_score=~p,node='~s' 
						   where flat='~s' and server_id=~p and id=~p and god_no=~p">>,
						[Group_win_loop,Group_loop,Group_score,Node,Flat,Server_id,Id,God_no]),
	db:execute(SQL),
	ok.

%%更新房间号
update_group_room_no(Flat,Server_id,Id,God_no,Node,Group_room_no)->
	SQL = io_lib:format(<<"update god set group_room_no=~p,node='~s'
						   where flat='~s' and server_id=~p and id=~p and god_no=~p">>,
						[Group_room_no,Node,Flat,Server_id,Id,God_no]),
	db:execute(SQL),
	ok.

%%更新房间号(秘籍用，全部丢一个房间里)
update_group_room_no()->
	SQL = io_lib:format(<<"update god set group_room_no=1">>,[]),
	db:execute(SQL),
	ok.

%% 插入记录
insert_god(Flat,Server_id,Id,God_no,Node,Name,Country,Sex,Carrer,Image,Lv,Power,High_power,Sea_win_loop,Sea_loop,Sea_score)->
	Create_time = util:unixtime(),
	SQL = io_lib:format(<<"insert into god(flat,server_id,id,god_no,node,name,country,sex,carrer,image,lv,power,high_power,sea_win_loop,sea_loop,sea_score,create_time) 
						   values('~s',~p,~p,~p,'~s','~s',~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p)">>, 
						[Flat,Server_id,Id,God_no,Node,Name,Country,Sex,Carrer,Image,Lv,Power,High_power,Sea_win_loop,Sea_loop,Sea_score,Create_time]),
	db:execute(SQL),
	ok.

%%删除某一届数据
delete_god(God_no)->
	SQL = io_lib:format(<<"delete from god where god_no=~p">>,[God_no]),
	db:execute(SQL),
	ok.

%%查询所有打过总决赛的名单(所有届)(跨服节点方法)
load_god_top50()->
	SQL = io_lib:format(<<"select * from god where group_relive_is_up=1">>,[]),
	Temp_God_List = db:get_all(SQL),
	God_dict = dict:new(),
	God_list = [#god{
		flat = binary_to_list(Flat),										      		               
		server_id = Server_id,                                  
		id = Id,											  		               
		god_no = God_no,     
		node = list_to_atom(binary_to_list(Node)),                        
		name = binary_to_list(Name),	
		country = Country,
		sex = Sex,
		carrer = Carrer,
		image = Image,									  		               
		lv = Lv,										    	                 
		power = Power,	
		high_power = High_power,											               
		sea_win_loop = Sea_win_loop,						  		             
		sea_loop = Sea_loop,							    	                 
		sea_score = Sea_score,										               
		group_room_no = Group_room_no,
		group_win_loop = Group_win_loop,					  		             
		group_loop = Group_loop,							  		             
		group_score = Group_score,						  	                 
		group_vote = Group_vote,
		group_relive_is_up = Group_relive_is_up,							  		             
		relive_win_loop = Relive_win_loop,							               
		relive_loop = Relive_loop,									               
		relive_score = Relive_score,						  		             
		relive_vote = Relive_vote,									               
		sort_win_loop = Sort_win_loop,								               
		sort_loop = Sort_loop,										               
		sort_score = Sort_score,							  		             
		sort_vote = Sort_vote,										               
		create_time = Create_time,
		praise = Praise,
		despise = Despise,
		is_relive_balace = Is_relive_balace
	 }||[
		Flat,										
		Server_id,               
		Id,											
		God_no,     
		Node,      
		Name,
		Country,
		Sex,
		Carrer,
		Image,
		Lv,										  
		Power,	
		High_power,									
		Sea_win_loop,						
		Sea_loop,							  
		Sea_score,								
		Group_room_no,
		Group_win_loop,					
		Group_loop,							
		Group_score,						  
		Group_vote,	
		Group_relive_is_up,						
		Relive_win_loop,					
		Relive_loop,							
		Relive_score,						
		Relive_vote,							
		Sort_win_loop,						
		Sort_loop,								
		Sort_score,							
		Sort_vote,								
		Create_time,
		Praise,
		Despise,
		Is_relive_balace]<-Temp_God_List],
	New_God_dict = load_god_top50_sub(God_list,God_dict),
	%%推送至各服
	mod_clusters_center:apply_to_all_node(mod_god_state,set_god_top50,[New_God_dict]),
	New_God_dict.
load_god_top50_sub([],God_dict)->God_dict;
load_god_top50_sub([G|T],God_dict)->
	case dict:is_key(G#god.god_no, God_dict) of
		false->
			V = [G];
		true->
			Temp_V = dict:fetch(G#god.god_no, God_dict),
			V = Temp_V ++ [G]
	end,
	load_god_top50_sub(T,dict:store(G#god.god_no, V, God_dict)).

%%查询某一次活动记录(海选后人员才有记录)
%% @param Function_time 活动时间
%% @return [#god{}]
load_god(Temp_God_no)->
	SQL = io_lib:format(<<"select * from god where god_no=~p">>,[Temp_God_no]),
	Temp_God_List = db:get_all(SQL),
	God_dict = dict:new(),
	God_list = [#god{
		flat = binary_to_list(Flat),										      		               
		server_id = Server_id,                                  
		id = Id,											  		               
		god_no = God_no,     
		node = list_to_atom(binary_to_list(Node)),                        
		name = binary_to_list(Name),	
		country = Country,
		sex = Sex,
		carrer = Carrer,
		image = Image,									  		               
		lv = Lv,										    	                 
		power = Power,	
		high_power = High_power,											               
		sea_win_loop = Sea_win_loop,						  		             
		sea_loop = Sea_loop,							    	                 
		sea_score = Sea_score,										               
		group_room_no = Group_room_no,
		group_win_loop = Group_win_loop,					  		             
		group_loop = Group_loop,							  		             
		group_score = Group_score,						  	                 
		group_vote = Group_vote,
		group_relive_is_up = Group_relive_is_up,							  		             
		relive_win_loop = Relive_win_loop,							               
		relive_loop = Relive_loop,									               
		relive_score = Relive_score,						  		             
		relive_vote = Relive_vote,									               
		sort_win_loop = Sort_win_loop,								               
		sort_loop = Sort_loop,										               
		sort_score = Sort_score,							  		             
		sort_vote = Sort_vote,										               
		create_time = Create_time,
		praise = Praise,
		despise = Despise,
		is_relive_balace = Is_relive_balace
	 }||[
		Flat,										
		Server_id,               
		Id,											
		God_no,     
		Node,      
		Name,
		Country,
		Sex,
		Carrer,
		Image,
		Lv,										  
		Power,	
		High_power,									
		Sea_win_loop,						
		Sea_loop,							  
		Sea_score,								
		Group_room_no,
		Group_win_loop,					
		Group_loop,							
		Group_score,						  
		Group_vote,	
		Group_relive_is_up,						
		Relive_win_loop,					
		Relive_loop,							
		Relive_score,						
		Relive_vote,							
		Sort_win_loop,						
		Sort_loop,								
		Sort_score,							
		Sort_vote,								
		Create_time,
		Praise,
		Despise,
		Is_relive_balace]<-Temp_God_List],
	load_god_sub(God_list,God_dict).
load_god_sub([],God_dict)->God_dict;
load_god_sub([G|T],God_dict)->
	load_god_sub(T,dict:store({G#god.flat,G#god.server_id,G#god.id}, G, God_dict)).

%%
%% Local Functions
%%
%%某一赛事是否结束
is_end(Open_time,Mod,Next_mod)->
	if
		Mod /= Next_mod->
			{Hour,Minute,_Second} = time(),
			case lib_god:get_next_time(Open_time,Hour,Minute) of
				{ok,_}->false;
				_->true
			end;
		true->false
	end.

%% 获取下一场比赛时间
%% @param Now_Hour 当前时间_小时
%% @param Now_Minute 当前时间_分钟
%% @param Open_time_List 配置的可开启时刻
%% @return {ok,[A_hour,A_minute,A_E_hour,A_E_minute]}|{error,none}
get_next_time(Open_time_List,Now_Hour,Now_Minute)->
	%% 按时间升序排列
	Sort_Open_time_List = lists:sort(fun({A_hour,A_minute,_A_E_hour,_A_E_minute},
										 {B_hour,B_minute,_B_E_hour,_B_E_minute})-> 
		if
			A_hour < B_hour -> true;
			A_hour =:= B_hour -> 
				if
					A_minute=<B_minute -> true;
					A_minute>B_minute -> false
				end;
			A_hour > B_hour -> false
		end
	end, Open_time_List),
	get_next_time_sub(Sort_Open_time_List,[Now_Hour,Now_Minute]).
get_next_time_sub([],[_Now_Hour,_Now_Minute])->{error,none};
get_next_time_sub([{A_hour,A_minute,A_E_hour,A_E_minute}|T],[Now_Hour,Now_Minute])->
	if
		A_hour<Now_Hour->get_next_time_sub(T,[Now_Hour,Now_Minute]);
		A_hour =:= Now_Hour -> 
			if
				A_minute=<Now_Minute -> get_next_time_sub(T,[Now_Hour,Now_Minute]);
				A_minute>Now_Minute -> {ok,[A_hour,A_minute,A_E_hour,A_E_minute]}
			end;
		A_hour > Now_Hour -> 
			{ok,[A_hour,A_minute,A_E_hour,A_E_minute]}
	end.

%%登陆时踢出
login_out_god(PlayerStates)->
	Bd_1v1_Scene_id1_flag = lists:member(PlayerStates#player_status.scene, data_god:get(scene_id1)),
	Bd_1v1_Scene_id2_flag = lists:member(PlayerStates#player_status.scene, data_god:get(scene_id2)),
	[SceneId,X,Y] = data_god:get(leave_scene),
	if
		Bd_1v1_Scene_id1_flag =:= true orelse Bd_1v1_Scene_id2_flag =:= true-> % 准备区的，丢出来
			NewPlayerStates = PlayerStates#player_status{
				 scene = SceneId,                    % 场景id
			     copy_id = 0,                        % 副本id 
			     y = X,
			     x = Y
			},
			NewPlayerStates;
		true->PlayerStates
	end.

%%结算时踢人方法
goout(Id)->
	[Scene_id_leave,X,Y] = data_god:get(leave_scene),
	case lib_player:get_player_info(Id, scene) of
		Scene when is_integer(Scene)->
			Flag1 = lists:member(Scene, data_god:get(scene_id1)),
			Flag2 = lists:member(Scene, data_god:get(scene_id2)),
			case Flag1 orelse Flag2 of
				false->void;
				true->
					lib_scene:player_change_scene_queue(Id,Scene_id_leave,0,X,Y,0)
			end;
		_->void
	end,
	ok.

%%补偿礼包
buchang(T_Node,Id,Sea_win_loop,Sea_loop)->
	Node = list_to_atom(T_Node),
	%%勋章
	{Xunzhang_id,_Xunzhang_num} = data_god:get_xunzhang_sea(Sea_win_loop,Sea_loop),
	Xunzhang_num = 150,
	{Belief_id,_Belief_num} = data_god:get_belief(Sea_win_loop,Sea_loop),
	Belief_num = 3,
	Title = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sea_3),[]),
	Content = io_lib:format(data_mail_log_text:get_mail_log_text(god_content_sea2),[]),
	mod_clusters_center:apply_cast(Node,lib_mail,send_sys_mail_bg_4_1v1,[[Id], Title, Content, Xunzhang_id, 2, 0, 0,Xunzhang_num,0,0,0,0]),
	timer:sleep(80),
	%%信仰之心
	Title_belief = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sea_1),[]),
	mod_clusters_center:apply_cast(Node,lib_mail,send_sys_mail_bg_4_1v1,[[Id], Title_belief, Content, Belief_id, 2, 0, 0,Belief_num,0,0,0,0]),
	timer:sleep(80),
	%%发放礼包
	{Gift_id,Gift_num} = data_god:get_gift_sea(9999999),
	if
		Gift_num=<0->void;
		true->
			Title_canyu = io_lib:format(data_mail_log_text:get_mail_log_text(god_title_sea_2),[]),
			mod_clusters_center:apply_cast(Node,lib_mail,send_sys_mail_bg_4_1v1,[[Id], Title_canyu, Content, Gift_id, 2, 0, 0,Gift_num,0,0,0,0])
	end,
	timer:sleep(80),
	ok.

%%单服获取状态
set_mod_and_status()->
	Node = mod_disperse:get_clusters_node(),
	mod_clusters_node:apply_cast(mod_god,set_mod_and_status,[Node]),
	ok.

%%下面是秘籍专用方法
dgod(God_no)->
	mod_clusters_node:apply_cast(lib_god,delete_god,[God_no]),
	ok.

open_god(Mod,Next_Mod,God_no,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute)->
	mod_clusters_node:apply_cast(mod_god_mgr,mt_start_link,[Mod,Next_Mod,God_no,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute]),
	ok.

godvoterelive()->
	mod_clusters_node:apply_cast(mod_god,vote_relive_list,[]),
	ok.

godresetgrouproom()->
	mod_clusters_node:apply_cast(lib_god,update_group_room_no,[]),
	ok.
	
