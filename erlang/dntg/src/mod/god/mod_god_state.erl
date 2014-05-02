%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2013-1-7
%%% -------------------------------------------------------------------
-module(mod_god_state).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("server.hrl").
-include("god.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

-record(state, {
	mod = 0, 							%%赛事模式：0无赛事、1海选赛、2小组赛、3复活赛/人气赛、4总决赛
	status = 0,  						%%开启状态: 0 未开启 1 进行中 2 已结束
	config_end_time = 0, 				%%比赛结束时间
	last_fetch_time = 0,				%%上一次获取最新数据时间
	last_status_fetch_time = 0,
	god_room_dict = dict:new(),			%%小组赛房间列表
	god_dict = dict:new(),				%%最近一期记录
	god_exp_list = [],					%%是否加经验列表
	god_top50_dict = dict:new(),			%%历届前50名单(key:god_no value:[God])
	last_bs_time = 0					%%最后鄙视时间
}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call({global, ?MODULE}, stop).

%% ====================================================================
%% Server functions
%% ====================================================================
%%鄙视崇拜
bs(Uid,RestBs,Flat,Server_id,Id,God_no,Type)->
	gen_server:cast({global, ?MODULE}, {bs,Uid,RestBs,Flat,Server_id,Id,God_no,Type}).

%%设置全服经验
set_god_exp(God,TPos)->
	gen_server:cast({global, ?MODULE}, {set_god_exp,God,TPos}).

%%设置历届前50名
set_god_top50(God_top50_dict)->
	gen_server:cast({global, ?MODULE}, {set_god_top50,God_top50_dict}).

%%设置赛事模式和状态
set_mod_and_status(Mod,Status,Config_end_time)->
	gen_server:cast({global, ?MODULE}, {set_mod_and_status,Mod,Status,Config_end_time}).

%%设置诸神记录
set_god_and_room_dict(God_dict,God_room_dict)->
	gen_server:cast({global, ?MODULE}, {set_god_and_room_dict,God_dict,God_room_dict}).

%%获取历届前50名
%% @return [God]
get_god_top50(God_no)->
	gen_server:call({global, ?MODULE}, {get_god_top50,God_no}).

%%获取赛事模式和状态
%% @return {Mod,Status,Config_end_time}
get_mod_and_status()->
	gen_server:call({global, ?MODULE}, {get_mod_and_status}).

%%排行榜
top_list(Flat,Server_id,Id,Room_no)->
	gen_server:cast({global, ?MODULE}, {top_list,Flat,Server_id,Id,Room_no}).

%%人气PK投票奖励
vote_relive_balance(Top2)->
	gen_server:cast({global, ?MODULE}, {vote_relive_balance,Top2}).

%%投票
%% @param UniteStatus #unite_status
%% @param Flat
%% @param Server_id
%% @param Id
vote_relive(PalyerStatus,Flat,Server_id,Id)->
	gen_server:cast({global, ?MODULE}, {vote_relive,PalyerStatus,Flat,Server_id,Id}).

%%诸神经验倍数
get_god_exp_rate()->
	gen_server:call({global, ?MODULE}, {get_god_exp_rate}).

%%强制刷新排行榜
top_list_all(Mod,God_room_dict,God_dict)->
	gen_server:cast({global, ?MODULE}, {top_list_all,Mod,God_room_dict,God_dict}).
%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
	Now_time = util:unixtime(),
	God_exp_list = lib_god:load_god_exp(),
	lists:foreach(fun([_Id,_Uid,Name,Country,Sex,Carrer,Image,B_time,_E_time,_Rate,Pos,Time])-> 
		if
			Now_time<B_time->
				spawn(fun()-> 
					timer:sleep(B_time-Now_time),	
					%%发送传闻
					lib_chat:send_TV({all},1,1,[ztstart,Pos,Time,Name,Country,Sex,Carrer,Image])
				end);
			true->void
		end
	end, God_exp_list),
	Node = mod_disperse:get_clusters_node(),
	mod_clusters_node:apply_cast(mod_god,set_mod_and_status,[Node]),
	mod_clusters_node:apply_cast(mod_god,set_god_and_room_dict,[Node]),
    {ok, #state{
		god_exp_list = God_exp_list,
		last_fetch_time = Now_time
	}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({get_god_top50,God_no}, _From, State) ->
	case dict:is_key(God_no, State#state.god_top50_dict) of
		false->God_top50_List = [];
		true->
			God_top50_List = dict:fetch(God_no, State#state.god_top50_dict)
	end,
	
	%%更新机制
	Now_time = util:unixtime(),
	if
		Now_time - State#state.last_bs_time > 1*60->
			Node = mod_disperse:get_clusters_node(),
			mod_clusters_node:apply_cast(mod_god,set_god_top50,[Node]),
			New_State = State#state{
				last_bs_time = Now_time
			};
		true->
			New_State = State
	end,
	
	{reply, God_top50_List, New_State};

handle_call({get_god_exp_rate}, _From, State) ->
	God_exp_list = State#state.god_exp_list,
	Rate = get_god_exp_sub(God_exp_list),
	{reply, Rate, State};

handle_call({get_mod_and_status}, _From, State) ->
	Reply = {State#state.mod,State#state.status,State#state.config_end_time},
	
	%%是否需要更新排行榜
	Status = State#state.status,
	Now_time = util:unixtime(),
	Node = mod_disperse:get_clusters_node(),
	if
		Status=:=1->
			if
				Now_time-State#state.last_status_fetch_time>=1*60 ->
					mod_clusters_node:apply_cast(mod_god,set_mod_and_status,[Node]),
					New_State = State#state{
						last_status_fetch_time = Now_time
					};
				true->
					New_State = State
			end;
		true->
			if
				Now_time-State#state.last_status_fetch_time>=1*60->%%非比赛期间
					mod_clusters_node:apply_cast(mod_god,set_mod_and_status,[Node]),
					New_State = State#state{
						last_status_fetch_time = Now_time
					};
				true->
					New_State = State
			end
	end,
	
    {reply, Reply, New_State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({bs,Uid,RestBs,Flat,Server_id,Id,God_no,Type}, State) ->
	case dict:is_key(God_no, State#state.god_top50_dict) of
		false->
			Result = 2,
			New_State = State;
		true->
			Top50_list = dict:fetch(God_no, State#state.god_top50_dict),
			case lib_god:member(Top50_list,Flat,Server_id,Id,God_no) of
				{ok,G}->%%是成员
					%%更改记录、领取铜币
					T_Top50_list = lists:delete(G, Top50_list),
					case Type of
						1->
							New_G = G#god{
								praise = G#god.praise + 1
							};
						_->
							New_G = G#god{
								despise = G#god.despise + 1		  
							}
					end,
					New_Top50_list = T_Top50_list ++ [New_G],
					New_God_top50_dict = dict:store(God_no, New_Top50_list, State#state.god_top50_dict),
					%%更改跨服数据
					mod_clusters_node:apply_cast(mod_god,bs,[Flat,Server_id,Id,God_no,Type]),
					%%更改鄙视次数、添加绑定铜币
					Bs_money = data_god:get(bs_money),
					lib_player:update_player_info(Uid,[{god,no_value},{add_coin,Bs_money}]),
					Result = 1,
					New_State = State#state{
						god_top50_dict = New_God_top50_dict
					};
				_->%%不是成员
					Result = 2,
					New_State = State
			end
	end,
	{ok, BinData} = pt_485:write(48517, [Flat,Server_id,Id,God_no,Type,Result,RestBs]),
	lib_unite_send:send_to_uid(Uid, BinData),
	
	{noreply, New_State};  

handle_cast({set_god_top50,God_top50_dict}, State) ->
	Now_time = util:unixtime(),
	New_State = State#state{
		god_top50_dict = God_top50_dict,	
		last_bs_time = Now_time
	},
	{noreply, New_State};

handle_cast({set_god_exp,God,TPos}, State) ->
	Add_Hour = data_god:get_god_exp_time(TPos),
	%%倍率
	Rate = 1,
	if
		Add_Hour>0->
			{Year,Month,Day} = date(),
			Days = calendar:date_to_gregorian_days(Year,Month,Day),
			{Next_Year,Next_Month,Next_Day} = calendar:gregorian_days_to_date(Days+1),
			Next_Hour = data_god:get(god_exp_time),
			if
				(Next_Hour+Add_Hour) =< 24->
					{Next_Year2,Next_Month2,Next_Day2} = calendar:gregorian_days_to_date(Days+1),
					Next_Hour2 = Next_Hour+Add_Hour;
				true->
					if
						(Next_Hour+Add_Hour) rem 24=:=0->
							Day_gap = (Next_Hour+Add_Hour) div 24,
							Next_Hour2 = (Next_Hour+Add_Hour) rem 24,
							{Next_Year2,Next_Month2,Next_Day2} = calendar:gregorian_days_to_date(Days+1+Day_gap);
						true->
							Day_gap = ((Next_Hour+Add_Hour) div 24) + 1,
							Next_Hour2 = (Next_Hour+Add_Hour) rem 24,
							{Next_Year2,Next_Month2,Next_Day2} = calendar:gregorian_days_to_date(Days+1+Day_gap)
					end
			end,
			B_time = util:unixtime({{Next_Year,Next_Month,Next_Day},{Next_Hour,0,0}}),
			E_time = util:unixtime({{Next_Year2,Next_Month2,Next_Day2},{Next_Hour2,0,0}}),
			lib_god:insert_into_god_exp(God#god.id,God#god.name,God#god.country,God#god.sex,
										God#god.carrer,God#god.image,B_time,E_time,Rate,TPos,Add_Hour),
			New_State = State#state{
				god_exp_list = State#state.god_exp_list	++ 
							   [0,God#god.id,God#god.name,God#god.country,God#god.sex,
								God#god.carrer,God#god.image,B_time,E_time,Rate,TPos,Add_Hour]					
			},
			NowTime = util:unixtime(),
			spawn(fun()-> 
				Sleep_time = B_time-NowTime,						  
				if
					Sleep_time>0->
						timer:sleep(Sleep_time),
						%%发送传闻
						lib_chat:send_TV({all},1,1,[ztstart,TPos,Add_Hour,God#god.name,God#god.country,God#god.sex,
										God#god.carrer,God#god.image]);
					true->
						void
				end
			end);
		true->
			New_State = State
	end,
	
	{noreply, New_State};

handle_cast({vote_relive_balance,Top2}, State) ->
	lib_god:vote_relive_balance(Top2),
	{noreply, State};

handle_cast({vote_relive,PalyerStatus,Flat,Server_id,Id}, State) ->
	Mod = State#state.mod,
	if
		Mod/=3->
			New_State = State,
			Result = 2;
		true->
			case dict:is_key({Flat,Server_id,Id}, State#state.god_dict) of
				false->
					New_State = State,
					Result = 4;
				true->
					case is_record(PalyerStatus, player_status) of
						false->
							New_State = State,
							Result = 3;
						true->
							God = dict:fetch({Flat,Server_id,Id}, State#state.god_dict),
							if
								God#god.group_relive_is_up=:=1->%%已经晋级
									New_State = State,
									Result = 4;
								true->
									case lib_god:vote_relive(PalyerStatus) of
										false->
											New_State = State,
											Result = 3;
										true->
											Result = 1,
											New_God = God#god{
												relive_vote = God#god.relive_vote+1				  
											},
											New_God_dict = dict:store({Flat,Server_id,Id},New_God,State#state.god_dict),
											New_State = State#state{
												god_dict = New_God_dict				
											},
											lib_god:insert_into_vote_relive(PalyerStatus#player_status.id,Flat,Server_id,Id),
											%%发送到跨服操作数据
											mod_clusters_node:apply_cast(mod_god,vote_relive,[Flat,Server_id,Id])
									end
							end
					end
			end
	end,
	{ok, BinData} = pt_485:write(48514, [Result,Flat,Server_id,Id]),
    lib_unite_send:send_to_uid(PalyerStatus#player_status.id, BinData),

	{noreply, New_State};

handle_cast({top_list_all,Mod,God_room_dict,God_dict}, State) ->
	God_dict_list = dict:to_list(God_dict),
	Flat = config:get_platform(),
	Server_id = config:get_server_num(),
	lists:foreach(fun({_K,G})-> 
		if
			Flat=:=G#god.flat andalso Server_id=:=G#god.server_id->
				if
					Mod =:= 1->
						Top_list = top_list_sea(God_dict);
					Mod =:= 2->
						Top_list = top_list_group(Flat,Server_id,G#god.id,G#god.room_no,God_room_dict,God_dict);
					Mod =:= 3->
						Top_list = top_list_relive(God_dict);
					Mod =:= 4->
						Top_list = top_list_sort(God_dict);
					true->
						Top_list = []
				end,
				
				if
					1=<Mod andalso Mod=<4 andalso length(Top_list)>0->
						Fin_Top_list = top_list_deal(Mod,1,Top_list,[]),
						MyScore = lib_god:get_score(Mod,G),
						{ok, BinData} = pt_485:write(48512, [Mod,Fin_Top_list,MyScore]),
			    		lib_unite_send:send_to_uid(G#god.id, BinData);
					true->void
				end;
			true->void
		end
	end, God_dict_list),
	
	{noreply, State};

handle_cast({top_list,Flat,Server_id,Id,Room_no}, State) ->
	%%拿本次排行榜数据
	Mod = State#state.mod,
	if
		Mod =:= 1->
			Top_list = top_list_sea(State#state.god_dict);
		Mod =:= 2->
			Top_list = top_list_group(Flat,Server_id,Id,Room_no,State#state.god_room_dict,State#state.god_dict);
		Mod =:= 3->
			Top_list = top_list_relive(State#state.god_dict);
		Mod =:= 4->
			Top_list = top_list_sort(State#state.god_dict);
		true->
			Top_list = []
	end,
	
	if
		1=<Mod andalso Mod=<4 andalso length(Top_list)>0->
			Fin_Top_list = top_list_deal(Mod,1,Top_list,[]),
			case dict:is_key({Flat,Server_id,Id}, State#state.god_dict) of
				false->G = #god{};
				true->G = dict:fetch({Flat,Server_id,Id}, State#state.god_dict)
			end,
			MyScore = lib_god:get_score(Mod,G), 
			{ok, BinData} = pt_485:write(48512, [Mod,Fin_Top_list,MyScore]),
    		lib_unite_send:send_to_uid(Id, BinData);
		true->void
	end,
	
	%%是否需要更新排行榜
	Status = State#state.status,
	Now_time = util:unixtime(),
	Node = mod_disperse:get_clusters_node(),
	if
		Status=:=1->
			if
				Now_time-State#state.last_fetch_time>=1*60 ->
					mod_clusters_node:apply_cast(mod_god,set_god_and_room_dict,[Node]),
						New_State = State#state{
							last_fetch_time = Now_time
						};
				true->
						New_State = State
			end;
		true->
			if
				Now_time-State#state.last_fetch_time>=1*60->%%非比赛期间
					mod_clusters_node:apply_cast(mod_god,set_god_and_room_dict,[Node]),
					New_State = State#state{
						last_fetch_time = Now_time
					};
				true->
					New_State = State
			end
	end,
	
	{noreply, New_State};

handle_cast({set_god_and_room_dict,God_dict,God_room_dict}, State) ->
	New_State = State#state{
		god_dict = God_dict,		
		god_room_dict = God_room_dict,
		last_fetch_time = util:unixtime()
	},							
	
	{noreply, New_State};

handle_cast({set_mod_and_status,Mod,Status,Config_end_time}, State) ->
	The_mod = State#state.mod,
	The_status = State#state.status,
	New_State = State#state{
		mod = Mod,
		status = Status,
		config_end_time = Config_end_time,
		last_status_fetch_time = util:unixtime()				
	},
	
	if
		The_mod/=Mod orelse The_status/=Status->
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
			Min_lv = data_god:get(min_lv),
			lib_unite_send:send_to_all(Min_lv,999, BinData);
		true->
			void
	end,
	
	{noreply, New_State};

handle_cast(stop, State) ->
	{stop, normal, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

%%诸神经验倍数
get_god_exp_sub([])->0;
get_god_exp_sub([[_Id,_Uid,_Name,_Country,_Sex,_Carrer,_Image,B_time,E_time,Rate,_TPos,_Add_Hour]|T])->
	Now_time = util:unixtime(),
	if
		B_time=<Now_time andalso Now_time=<E_time->
			Rate;
		true->
			get_god_exp_sub(T)
	end.

%%排行榜处理
top_list_deal(_Mod,_Pos,[],Top_list)->Top_list;
top_list_deal(Mod,Pos,[God|T],Top_list)->
	case Mod of
		1->
			Win_loop = God#god.sea_win_loop,
			Loop = God#god.sea_loop,
			Score = God#god.sea_score;
		2->
			Win_loop = God#god.group_win_loop,
			Loop = God#god.group_loop,
			Score = God#god.group_score;
		3->
			Win_loop = God#god.relive_win_loop,
			Loop = God#god.relive_loop,
			Score = God#god.relive_score;
		4->
			Win_loop = God#god.sort_win_loop,
			Loop = God#god.sort_loop,
			Score = God#god.sort_score;
		_->
			Win_loop = 0,
			Loop = 0,
			Score = 0
	end,
	top_list_deal(Mod,Pos+1,T,Top_list ++[{Pos,God#god.flat,God#god.server_id,
	  God#god.id,God#god.name,God#god.country,
	  God#god.sex,God#god.carrer,God#god.image,
	  God#god.lv,God#god.power,Win_loop,Loop,Score,God#god.room_no,
	  God#god.group_vote,God#god.relive_vote,God#god.sort_vote}]).

%%总决赛排序
top_list_sort(God_dict)->
	God_dict_list = dict:to_list(God_dict),
	God_list = [G||{_K,G}<-God_dict_list,G#god.group_relive_is_up=:=1],
	%% 排序
	Sort_God_list = lists:sort(fun(G_a,G_b)-> 
		if
			G_a#god.sort_win_loop>G_b#god.sort_win_loop->true;
			G_a#god.sort_win_loop=:=G_b#god.sort_win_loop->
				if
					G_a#god.sort_score>G_b#god.sort_score->true;
					G_a#god.sort_score=:=G_b#god.sort_score->
						if
							G_a#god.high_power>G_b#god.high_power->true;
							G_a#god.high_power=:=G_b#god.high_power->
								if
									G_a#god.lv>=G_b#god.lv->true;
									true->false
								end;
							G_a#god.high_power<G_b#god.high_power->false
						end;
					G_a#god.sort_score<G_b#god.sort_score->false
				end;
			G_a#god.sort_win_loop<G_b#god.sort_win_loop->false
		end										   
	end,God_list),
	Sort_God_list.

%%复活赛排序
top_list_relive(God_dict)->
	Temp_God_dict_list = dict:to_list(God_dict),
	God_list = [G||{_K,G}<-Temp_God_dict_list,G#god.group_relive_is_up=:=0],
	%%排序：积分高、战力高、等级高
	Sort_God_sea_list = lists:sort(fun(G_a,G_b)-> 
		if
			G_a#god.relive_score>G_b#god.relive_score->true;
			G_a#god.relive_score=:=G_b#god.relive_score->
				if
					G_a#god.high_power>G_b#god.high_power->true;
					G_a#god.high_power=:=G_b#god.high_power->
						if
							G_a#god.lv>=G_b#god.lv->true;
							true->false
						end;
					G_a#god.high_power<G_b#god.high_power->false
				end;
			G_a#god.relive_score<G_b#god.relive_score->false
		end
	end, God_list),
	Sort_God_sea_list.

%%小组赛排序
top_list_group(Flat,Server_id,Id,Room_no,God_room_dict,God_dict)->
	if
		Room_no=:=0-> %%选自己组
			case dict:is_key({Flat,Server_id,Id}, God_dict) of
				false-> %%无记录
					F_Room_no = 1;
				true->
					God = dict:fetch({Flat,Server_id,Id}, God_dict),
					F_Room_no = God#god.room_no
			end;
		true->
			F_Room_no = Room_no
	end,
	Scene_id1 = lists:nth(1,data_god:get(scene_id1)),
	case dict:is_key({Scene_id1,F_Room_no}, God_room_dict) of
		false->
			Top_list = [];
		true->
			God_room = dict:fetch({Scene_id1,F_Room_no}, God_room_dict),
			%% 排序每个房间人员							  
			Player_list = God_room#god_room.player_list,
			Sort_player_list = lists:sort(fun({Flat_a,Server_id_a,Id_a},{Flat_b,Server_id_b,Id_b})-> 
				G_a = dict:fetch({Flat_a,Server_id_a,Id_a}, God_dict),
				G_b = dict:fetch({Flat_b,Server_id_b,Id_b}, God_dict),
				if
					G_a#god.group_score>G_b#god.group_score->true;
					G_a#god.group_score=:=G_b#god.group_score->
						if
							G_a#god.group_loop>G_b#god.group_loop->false;
							G_a#god.group_loop=:=G_b#god.group_loop->
								if
									G_a#god.high_power>G_b#god.high_power->true;
									G_a#god.high_power=:=G_b#god.high_power->
										if
											G_a#god.lv>=G_b#god.lv->true;
											true->false
										end;
									G_a#god.high_power<G_b#god.high_power->false
								end;
							G_a#god.group_loop<G_b#god.group_loop->true
						end;
					G_a#god.group_score<G_b#god.group_score->false
				end
			end, Player_list),
			Top_list = top_list_group_sub(Sort_player_list,God_dict,[])
	end,
	Top_list.
top_list_group_sub([],_God_dict,Top_list)->Top_list;
top_list_group_sub([{Flat,Server_id,Id}|T],God_dict,Top_list)->	
	case dict:is_key({Flat,Server_id,Id}, God_dict) of
		false->
			top_list_group_sub(T,God_dict,Top_list);
		true->
			God = dict:fetch({Flat,Server_id,Id}, God_dict),
			top_list_group_sub(T,God_dict,Top_list++[God])
	end.
	
%%海选赛排序
top_list_sea(God_dict)->
	God_dict_list = dict:to_list(God_dict),
	%%获取本场实际参与玩家
	God_sea_list = [V||{_K,V}<-God_dict_list,V#god.is_db=:=0],
	%%排序：积分高、战力高、等级高
	Sort_God_sea_list = lists:sort(fun(G_a,G_b)-> 
		if
			G_a#god.sea_score>G_b#god.sea_score->true;
			G_a#god.sea_score=:=G_b#god.sea_score->
				if
					G_a#god.high_power>G_b#god.high_power->true;
					G_a#god.high_power=:=G_b#god.high_power->
						if
							G_a#god.lv>=G_b#god.lv->true;
							true->false
						end;
					G_a#god.high_power<G_b#god.high_power->false
				end;
			G_a#god.sea_score<G_b#god.sea_score->false
		end
	end, God_sea_list),
	if
		length(Sort_God_sea_list)>160->
			{Top_100_list,_} = lists:split(160, Sort_God_sea_list);
		true->
			Top_100_list = Sort_God_sea_list
	end,
	Top_100_list.
