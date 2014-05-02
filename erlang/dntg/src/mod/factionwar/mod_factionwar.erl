%%% -------------------------------------------------------------------
%%% Author  : zengzhaoyuan
%%% Description :
%%%
%%% Created : 2012-5-22
%%% -------------------------------------------------------------------
-module(mod_factionwar).
-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([set_time/5]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).
-include("unite.hrl").
-include("server.hrl").
-include("factionwar.hrl").
-include("guild.hrl").

-record(state, {top_100_player_factionwar = [], %%前100名玩家记录
				factionwar_dbs = dict:new(),  %帮战积分历史记录 Key:FactionId  Value:#factionwar_db
				factionwar_stauts=1,  %帮战状态 1还未开启 2报名中 3开启中 4当天已结束
				config_begin_hour=0,
				config_begin_minute=0,
				sign_up_time = 0,
				loop_time = 0, %每轮耗时
				max_faction = 0, %每张图最大允许进入帮派
				loop = 0,  %总轮次
				current_loop = 0,  %当前进行的轮次
				last_time = 0, %本轮起始时刻
				can_sign_up_factions = dict:new(), %帮派资料字典，可以报名的帮派（3级以上资金100000以上）Key:帮派ID Value:[FactionId,Name,Realm,Level]
				sign_up_succ_factions = [], %报名成功帮派 [Id1,Id2...]
				sign_up_fail_factions = [], %报名失败帮派 [Id1,Id2...]
				factionwar_sign_up_dict = dict:new(), %%帮派报名记录（key:帮派ID,value:帮众ID列表）
				factionwar_dict = dict:new(), %帮战本场记录(key:帮派ID value:帮派记录)
				merber_dict = dict:new(), %帮战成员本场记录(key:玩家ID value:玩家记录)
				max_warid = 0,    %%本轮最大战场号
				group = dict:new(),		%帮派每轮分组列表（列表顺序即是名次）key:currentLoop_组号  value:[Id1,Id2,Id3...]
				pass_faction = [],  %被淘汰帮派ID列表
				jgb_faction = dict:new(),   	%本轮次占领金箍棒帮派（Key:currentLoop_组号   value:{factionId,memberId}）
				skill_have_used = dict:new(),  %%储存上次使用过技能的时间 key:factionId_技能类型  Value:{类型，时间}
				fy_id_dict = dict:new()	   %%封印怪物ID（Key:currentLoop_组号   value:[{monTypeId,monId,Uid,FactionId,FactionName},...]）当怪没有归属的时候，Uid,FactionId值为0
}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

%% ====================================================================
%% Server functions
%% ====================================================================
%% 获取帮战周战分记录
%% @param FactionId 帮派Id
%% @return {error,no_match} | {ok,[faction_war_week_score,faction_war_last_time]}
get_faction_war_week_score(FactionId)->
	gen_server:call(misc:get_global_pid(?MODULE),{get_faction_war_week_score,FactionId}).

%%召唤Buff怪物
% call_buff()->
% 	gen_server:cast(misc:get_global_pid(?MODULE),{call_buff}).

%%获取帮主ID信息
%% @param FactionId 帮派ID
get_chief_id(FactionId)->
	gen_server:call(misc:get_global_pid(?MODULE),{get_chief_id,FactionId}).

%%获取召集信息
%% @param FactionId 帮派ID
%% @return {ok,{}}
get_zj(FactionId,Id)->
	gen_server:call(misc:get_global_pid(?MODULE),{get_zj,FactionId,Id}).

%%是否是金箍棒占领帮派
%%@param Uid 玩家ID
%%@return 0非 1是
is_jgb_faction(Uid)->
	gen_server:call(misc:get_global_pid(?MODULE),{is_jgb_faction,Uid}).

%% 帮主技能
%% @param UniteStatus #unite_status
%% @param Type
use_faction_leader_skill(UniteStatus,Type,{Scene,Copy_id,X,Y})->
	gen_server:call(misc:get_global_pid(?MODULE),{use_faction_leader_skill,UniteStatus,Type,{Scene,Copy_id,X,Y}}).

%% 帮战个人积分榜
%% @param UniteStatus #unite_status
%% @return [Result,WarScore,LastKillNum,No,FactionNo,ResultList]
top_list()->
	gen_server:call(misc:get_global_pid(?MODULE),{top_list}).

%%判断是否幽灵状态
%% @param Uid 玩家ID
%% @return 1幽灵 0非幽灵
is_spirit(Uid)->
	gen_server:call(misc:get_global_pid(?MODULE),{is_spirit,Uid}).

%%通过玩家ID，获取玩家竞技场所在阵营
%%@param Id 玩家ID
%%@return 0时为错 1~5
get_born_pos(Uid)->
	gen_server:call(misc:get_global_pid(?MODULE),{get_born_pos,Uid}).

%%是否可以占领金箍棒
%%@param Id 玩家ID
%%@return true|false
can_kill_jgb(Uid)->
	gen_server:call(misc:get_global_pid(?MODULE),{can_kill_jgb,Uid}).

%%占领封印、金箍棒定时加分
add_score()->
	gen_server:cast(misc:get_global_pid(?MODULE),{add_score}).

%%加载一次数据
load_factionwar_dbs()->
	gen_server:cast(misc:get_global_pid(?MODULE),{load_factionwar_dbs}).

%%设置帮战积分
%%@param Type 设分类型player|npc|stone
%%@param Uid 玩家ID
%%@param KilledUidOrNpcTypeId (Type=stone时, 取帮派神石类型【1-5】)
set_score(Type,Uid,KilledUidOrNpcTypeId,Uid_AchieveOrNPCId,KilledUid_Achieve,_HitList)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_score,Type,Uid,KilledUidOrNpcTypeId,Uid_AchieveOrNPCId,KilledUid_Achieve,_HitList}).

%%成员报名
%% @param UniteStatus #unite_status
%% @return [Result,SignUpNum]
member_sign_up(UniteStatus)->
	gen_server:call(misc:get_global_pid(?MODULE),{member_sign_up,UniteStatus}).

%%成员进入帮战战场
%% @param UniteStatus #unite_status
%% @return [Result,Loop,RestTime]
enter_factionwar(UniteStatus)->
	gen_server:call(misc:get_global_pid(?MODULE),{enter_factionwar,UniteStatus}).

%%帮战战况详情
%% @param UniteStatus #unite_status
%% @return [RestTime,FactionWarScore,Score,Anger,RestRevive,
%%	 	    IsGetJGB,FactionName,FactionWarList,KillList]
get_factionwar_info(Uid)->
	gen_server:cast(misc:get_global_pid(?MODULE),{get_factionwar_info,Uid}).

%%获取怒气值
%% @param UniteStatus #unite_status
%% @return int 0不可以 1可以
can_use_anger(UniteStatus)->
	gen_server:call(misc:get_global_pid(?MODULE),{can_use_anger,UniteStatus}).

%%释放怒气
%% @param UniteStatus #unite_status
%% @return int 1成功 2失败
use_anger(UniteStatus)->
	gen_server:call(misc:get_global_pid(?MODULE),{use_anger,UniteStatus}).

%%退出帮战战场
%%@param UniteStatus #unite_status
%%@return 0退出失败 1退出成功
exit_factionwar(UniteStatus)->
	gen_server:call(misc:get_global_pid(?MODULE),{exit_factionwar,UniteStatus}).

%%设置帮战时间(不方法不可随便调用，会重置所有属性，很危险)
set_time(Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_time,Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction}).

%%设置帮战状态
%% @param Factionwar_Stauts 帮战状态 1还未开启 2报名中 3开启中 4当天已结束
set_status(Factionwar_Stauts)->
	gen_server:cast(misc:get_global_pid(?MODULE),{set_status,Factionwar_Stauts}).

%% 获取帮战状态
%% @param FactionId 帮派ID
%% @return [Result,RestTime,WarNo]
get_status(FactionId)->
	gen_server:call(misc:get_global_pid(?MODULE),{get_status,FactionId}).

%%获取是否有下一轮
%% @return 1有下一轮 0无下一轮
have_next_loop()->
	gen_server:call(misc:get_global_pid(?MODULE),{have_next_loop}).

%% 帮战报名
sign_up_factionwar()->
	gen_server:cast(misc:get_global_pid(?MODULE),{sign_up_factionwar}).

%% 开启帮战
%% @param NowTime 当前时间
open_factionwar(NowTime)->
	gen_server:cast(misc:get_global_pid(?MODULE),{open_factionwar,NowTime}).

%% 结束每一轮
%% @param NowTime 当前时间
cancle_round_factionwar(NowTime)->
	gen_server:cast(misc:get_global_pid(?MODULE),{cancle_round_factionwar,NowTime}).

%% 结束帮战
end_factionwar(Config_Begin_Hour,Config_Begin_Minute,Sign_up_time,Loop_Time,Max_faction)->
	gen_server:cast(misc:get_global_pid(?MODULE),{end_factionwar,Config_Begin_Hour,Config_Begin_Minute,Sign_up_time,Loop_Time,Max_faction}).
%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

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
handle_call({get_faction_war_week_score,FactionId}, _From, State) ->
	case dict:is_key(FactionId, State#state.factionwar_dbs) of
		false->Reply = {error,no_record};
		true->
			Factionwar_db = dict:fetch(FactionId, State#state.factionwar_dbs),
			Reply = {ok,[Factionwar_db#factionwar_db.faction_war_week_score,
						 Factionwar_db#factionwar_db.faction_war_last_time]}
	end,
	{reply, Reply, State};  

handle_call({get_chief_id,FactionId}, _From, State) ->
	case dict:is_key(FactionId, State#state.factionwar_dbs) of
		false->Reply = 0;
		true->
			Factionwar_db = dict:fetch(FactionId, State#state.factionwar_dbs),
			Reply = Factionwar_db#factionwar_db.faction_chief_id
	end,
	{reply, Reply, State};

handle_call({get_zj,FactionId,Id}, _From, State) ->
	case dict:is_key(FactionId, State#state.factionwar_dict) of
		false->Reply=4;%没有参战
		true->
			Key = integer_to_list(FactionId)++ "_" ++integer_to_list(1),
			case dict:is_key(Key, State#state.skill_have_used) of
				false->Reply=2; %没有召集过
				true->
					{_T,Time,{Scene,Copy_id,X,Y}} = dict:fetch(Key, State#state.skill_have_used),
					{_,{Hour,Minute,Second}} = calendar:local_time(),
					NowTime = (Hour*60+Minute)*60 + Second,
					Leader_skill_cd = data_factionwar:get_factionwar_config(leader_skill_cd),
					if
						Leader_skill_cd*60<(NowTime-Time)-> %%超过5分钟
							Reply = 5;
						true-> %%不超过5分钟
							%切换场景
							lib_scene:player_change_scene(Id,Scene,Copy_id,X,Y,false),
							Reply = 1
					end
			end
	end,
	{reply, Reply, State};

handle_call({is_jgb_faction,Uid}, _From, State) ->
	case dict:is_key(Uid, State#state.merber_dict) of
		false->Reply = 0;
		true->
			Member = dict:fetch(Uid, State#state.merber_dict),
			Factionwar = dict:fetch(Member#member.faction_id, State#state.factionwar_dict),
			CopyId = integer_to_list(State#state.current_loop)++ "_" ++integer_to_list(Factionwar#factionwar.war_id),
			case dict:is_key(CopyId, State#state.jgb_faction) of
				false->Reply = 0;
				true->
					{FactionId,_} = dict:fetch(CopyId, State#state.jgb_faction),
					if
						FactionId =:= Member#member.faction_id->Reply = 1;
						true->Reply = 0
					end
			end
	end,
	{reply, Reply, State};

handle_call({use_faction_leader_skill,UniteStatus,Type,{Scene,Copy_id,X,Y}}, _From, State) ->
	FactionId = UniteStatus#unite_status.guild_id,
	case dict:is_key(FactionId, State#state.factionwar_dict) of
		false->
			Reply = 4,
			New_State = State;
		true->
			Key = integer_to_list(UniteStatus#unite_status.guild_id)++ "_" ++integer_to_list(Type),
			{_,{Hour,Minute,Second}} = calendar:local_time(),
			NowTime = (Hour*60+Minute)*60 + Second,
			case dict:is_key(Key, State#state.skill_have_used) of
				false -> 
					New_Skill_have_used = dict:store(Key,{Key,NowTime,{Scene,Copy_id,X,Y}},State#state.skill_have_used),
					New_State = State#state{skill_have_used=New_Skill_have_used},
					Reply = 1;
				true->
					{_T,Time,_} = dict:fetch(Key, State#state.skill_have_used),
					Leader_skill_cd = data_factionwar:get_factionwar_config(leader_skill_cd),
					if
						Leader_skill_cd*60 < (NowTime-Time)-> %%超过5分钟
							New_Skill_have_used = dict:store(Key,{Key,NowTime,{Scene,Copy_id,X,Y}},State#state.skill_have_used),
							New_State = State#state{skill_have_used=New_Skill_have_used},
							Reply = 1;
						true-> %%不超过5分钟
							Reply = 2,
							New_State = State
					end
			end,
			case Reply of
				1->
					Factionwar = dict:fetch(FactionId, State#state.factionwar_dict),
					case Type of
						1->%召唤帮众
							lists:foreach(fun(Uid)->
								case dict:is_key(Uid, State#state.merber_dict) of
									false->void;
									true->
										Merber = dict:fetch(Uid, State#state.merber_dict),
										{ok,DataBin} = pt_402:write(40215, []),
										case Merber#member.is_in_war of
											1->
												if
													Uid=:=UniteStatus#unite_status.id->void;
													true->lib_unite_send:send_to_uid(Uid, DataBin)
												end;
											_->void
										end
								end
							end, Factionwar#factionwar.member_ids);
						_->void
					end;
				_->void
			end
	end,
	
	{reply, Reply, New_State};

%% [Result,WarScore,LastKillNum,No,FactionNo,ResultList]
handle_call({top_list}, _From, State) ->
	Factionwar_dbs = State#state.factionwar_dbs,
	Top_100_player_factionwar = State#state.top_100_player_factionwar, %%前100名玩家记录
	{reply, {Factionwar_dbs,Top_100_player_factionwar}, State};

handle_call({is_spirit,Uid}, _From, State) ->
	case dict:is_key(Uid, State#state.merber_dict) of
		false->Reply = 0;
		true->
			Member = dict:fetch(Uid, State#state.merber_dict),
			Dead_num = data_factionwar:get_factionwar_config(dead_num),
			if 
				Member#member.killed_num=<Dead_num->
					Reply=0;
				true->Reply=1
			end
	end,
	{reply, Reply, State};

handle_call({can_kill_jgb,Uid}, _From, State) ->
	case State#state.factionwar_stauts of
		3->
			case dict:is_key(Uid, State#state.merber_dict) of
				false->Reply = false;
				true->
					Member = dict:fetch(Uid, State#state.merber_dict),
					Factionwar = dict:fetch(Member#member.faction_id, State#state.factionwar_dict),
					CopyId = integer_to_list(State#state.current_loop)++ "_" ++integer_to_list(Factionwar#factionwar.war_id),
					case dict:is_key(CopyId, State#state.fy_id_dict) of
						false->Reply = false;
						true->
							Fy_Id = dict:fetch(CopyId, State#state.fy_id_dict),
							Reply = have_Fy(Fy_Id,Member#member.faction_id)
					end
			end;
		_->Reply = false
	end,
	{reply, Reply, State};

handle_call({get_born_pos,Uid}, _From, State) ->
	case dict:is_key(Uid, State#state.merber_dict) of
		false->
			[SceneId,X,Y] = data_factionwar:get_factionwar_config(leave_scene),
			Reply = [0,SceneId,0,X,Y];
		true->
			Member = dict:fetch(Uid, State#state.merber_dict),
			Factionwar = dict:fetch(Member#member.faction_id, State#state.factionwar_dict),
			Scene_Born_List = data_factionwar:get_factionwar_config(born),
			Scene_id = data_factionwar:get_factionwar_config(scene_id),
			CopyId = integer_to_list(State#state.current_loop)++ "_" ++integer_to_list(Factionwar#factionwar.war_id),
			{T_X,T_Y} = lists:nth(Factionwar#factionwar.born_pos, Scene_Born_List),
			case dict:is_key(CopyId, State#state.fy_id_dict) of
				false->{X,Y} = {T_X,T_Y};
				true->
					Fy_Id = dict:fetch(CopyId, State#state.fy_id_dict),
					{X,Y} = get_Fy_X_Y(Fy_Id,Member#member.faction_id,{T_X,T_Y})
			end,
			Reply = [Factionwar#factionwar.born_pos,Scene_id,CopyId,X,Y]
	end,
	{reply, Reply, State};

handle_call({member_sign_up,UniteStatus}, _From, State) ->
	FactionId = UniteStatus#unite_status.guild_id,
	case FactionId of
		0->New_State = State,Result=5,SignUpNum=0; %不合法帮派ID
		_->
			case dict:is_key(FactionId, State#state.can_sign_up_factions) of
				false->New_State = State,Result=7,SignUpNum=0; %不合法帮派ID
				true->
					case State#state.factionwar_stauts of
						2-> %报名阶段
							Lv = data_factionwar:get_factionwar_config(lv),
							if
								UniteStatus#unite_status.lv<Lv-> %等级不够
									New_State = State,Result=2,SignUpNum=0;
								true->
									Factionwar_sign_up_dict = State#state.factionwar_sign_up_dict,
									case dict:is_key(FactionId, Factionwar_sign_up_dict) of
										false->%还没有人报名
%% 											Money = data_factionwar:get_factionwar_config(money),
%% 											%%扣除帮派财富，如果报名失败，重新归还。
%% 											case lib_guild_base:guild_reduce_funds(FactionId, Money) of
%% 												false->New_State = State,Result=3,SignUpNum=0; %帮派资产不够
%% 												true->
													New_Factionwar_sign_up_dict = dict:store(FactionId, [UniteStatus#unite_status.id], Factionwar_sign_up_dict),
													New_State = State#state{factionwar_sign_up_dict=New_Factionwar_sign_up_dict},
													Result=1,SignUpNum=1;	
%% 											end;
										true->%已有人报过名
											MemberIds = dict:fetch(FactionId, Factionwar_sign_up_dict),
											case lists:member(UniteStatus#unite_status.id, MemberIds) of
												false->%未报过名
													New_Factionwar_sign_up_dict = dict:store(FactionId, MemberIds ++ [UniteStatus#unite_status.id], Factionwar_sign_up_dict),
													New_State = State#state{factionwar_sign_up_dict=New_Factionwar_sign_up_dict},
													Result=1,SignUpNum=length(MemberIds)+1;
												true->%已报过名
													New_State = State,
													Result=6,SignUpNum=length(MemberIds)
											end
									end
							end;
						_->%非报名阶段
							New_State = State,Result=4,SignUpNum=0
					end
			end
	end,
	{reply, [Result,SignUpNum], New_State};

handle_call({enter_factionwar,UniteStatus}, _From, State) ->
	case State#state.factionwar_stauts of
		3->
			FactionId = UniteStatus#unite_status.guild_id,
			Factionwar_dict = State#state.factionwar_dict,
			case dict:is_key(FactionId, Factionwar_dict) of
				false-> %没有成功报名的帮派
					New_State = State,Result=4,Loop=0,CurrentLoop=0,RestTime=0;
				true-> %成功报名帮派
					Factionwar = dict:fetch(FactionId, Factionwar_dict),
					case lists:member(FactionId, State#state.pass_faction) of
						false-> %%非淘汰帮派
							%计算剩余时间
							{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
							NowTime = (Hour*60+Minute)*60 + Second,
							Config_Begin_Hour = State#state.config_begin_hour,
							Config_Begin_Minute = State#state.config_begin_minute,
							Sign_up_time = State#state.sign_up_time,
							Current_Loop = State#state.current_loop,
							Loop_Time = State#state.loop_time,
							Config_FactionWar_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute + Sign_up_time)*60,%%帮战开始时刻
							Loop_End = Config_FactionWar_Begin+Current_Loop*Loop_Time*60,%%帮战结束时刻
							if
								Loop_End<NowTime->RestTime=0;
								true->RestTime = Loop_End-NowTime
							end,
							%%判断是否已经超出限制进入时间
							No_in_time = data_factionwar:get_factionwar_config(no_in_time),
							if
								RestTime =< No_in_time ->
									New_State = State,Result=7,
									Loop=State#state.loop,CurrentLoop=State#state.current_loop;
								true->
									case lib_player:get_player_info(UniteStatus#unite_status.id, pk) of
										false-> Pk_status = 2;
										Pk -> Pk_status = Pk#status_pk.pk_status
									end,
									Merber_dict = State#state.merber_dict,
									case dict:is_key(UniteStatus#unite_status.id, Merber_dict) of
										false-> %%还未进入过帮战战场
											Member = #member{            %参赛帮众
														id = UniteStatus#unite_status.id,					%帮众角色ID
														name = UniteStatus#unite_status.name,				%帮众昵称
														realm = UniteStatus#unite_status.realm, %阵营
														sex = UniteStatus#unite_status.sex, %性别
														carrer = UniteStatus#unite_status.career, %职业
														image = UniteStatus#unite_status.image,
														lv = UniteStatus#unite_status.lv,
														faction_id = UniteStatus#unite_status.guild_id,			%帮派ID
														faction_name = Factionwar#factionwar.faction_name,
														is_in_war = 1,
														war_id = Factionwar#factionwar.war_id,	%战场ID
														war_score = 0,		    %个人帮战战分
														kill_num = 0, 			%个人杀人数
														killed_num = 0,         %单轮被杀次数
														anger = 0,				%怒气值
														pk_status = Pk_status
													},
											New_Merber_dict = dict:store(UniteStatus#unite_status.id, Member, Merber_dict),
											New_Factionwar = Factionwar#factionwar{member_ids=Factionwar#factionwar.member_ids++[UniteStatus#unite_status.id]},
											New_factionwar_dict = dict:store(FactionId, New_Factionwar,State#state.factionwar_dict),
											New_State = State#state{merber_dict=New_Merber_dict,
																	factionwar_dict = New_factionwar_dict};
										true-> %%有进入过帮战战场
											Member = dict:fetch(UniteStatus#unite_status.id, Merber_dict),
											New_Member = Member#member{is_in_war=1,war_id = Factionwar#factionwar.war_id,pk_status = Pk_status},
											New_Merber_dict = dict:store(UniteStatus#unite_status.id, New_Member, Merber_dict),
											New_State = State#state{merber_dict=New_Merber_dict}
								end,
								%切换进入地图
								Scene_id = data_factionwar:get_factionwar_config(scene_id),
								Born = data_factionwar:get_factionwar_config(born),
								{X,Y} = lists:nth(Factionwar#factionwar.born_pos, Born),
								CopyId = integer_to_list(State#state.current_loop)++ "_" ++integer_to_list(Factionwar#factionwar.war_id),
								Dead_num = data_factionwar:get_factionwar_config(dead_num),
								if
									Dead_num=<Member#member.killed_num->
										Pk_Status = 7;
									true->
										Pk_Status = 8
								end,
								lib_player:change_pk_status_cast(UniteStatus#unite_status.id,Pk_Status), %%切换阵营
								lib_scene:player_change_scene_queue(UniteStatus#unite_status.id,Scene_id,CopyId,X,Y,[{group,FactionId}]),
								Result=1,Loop=State#state.loop,CurrentLoop=State#state.current_loop	
							end;
						true->%%淘汰帮派
							New_State = State,Result=6,Loop=0,CurrentLoop=0,RestTime=0
					end
			end;
		4->New_State = State,Result=3,Loop=0,CurrentLoop=0,RestTime=0;
		_->New_State = State,Result=2,Loop=0,CurrentLoop=0,RestTime=0
	end,
	{reply, [Result,Loop,CurrentLoop,RestTime], New_State};

handle_call({can_use_anger,UniteState}, _From, State) ->
	case dict:is_key(UniteState#unite_status.id, State#state.merber_dict) of
		false->Can_Use_Anger=0;
		true->
			Merber = dict:fetch(UniteState#unite_status.id, State#state.merber_dict),
			Max_anger = data_factionwar:get_factionwar_config(max_anger),
			if
				Max_anger=<Merber#member.anger->Can_Use_Anger=1;
				true->Can_Use_Anger=0
			end
	end,
	{reply, Can_Use_Anger,State};

handle_call({use_anger,UniteState}, _From, State) -> 
	case dict:is_key(UniteState#unite_status.id, State#state.merber_dict) of
		false->Result=2,New_State = State;
		true->
			Merber = dict:fetch(UniteState#unite_status.id, State#state.merber_dict),
			Dead_num = data_factionwar:get_factionwar_config(dead_num),
			if
				Dead_num=<Merber#member.killed_num->
					Result=3,New_State = State;
				true->
					Result = 1,
					New_Member = Merber#member{anger = 0},
					New_Merber_dict = dict:store(UniteState#unite_status.id, New_Member, State#state.merber_dict),
					New_State = State#state{merber_dict=New_Merber_dict}	
			end
	end,
	{reply, Result, New_State};

handle_call({exit_factionwar,UniteState}, _From, State) ->  
	case dict:is_key(UniteState#unite_status.id, State#state.merber_dict) of
		false->New_State=State,Pk_status = 2;
		true->
			Member = dict:fetch(UniteState#unite_status.id, State#state.merber_dict),
			New_Member = Member#member{is_in_war=0},
			Pk_status = Member#member.pk_status,
			New_merber_dict = dict:store(UniteState#unite_status.id, New_Member, State#state.merber_dict),
			New_State = State#state{merber_dict=New_merber_dict}
	end,
	[SceneId,X,Y] = data_factionwar:get_factionwar_config(leave_scene),
	%%设置PK状态
	lib_player:change_pk_status_cast(UniteState#unite_status.id,Pk_status), %%切换阵营
	lib_scene:player_change_scene_queue(UniteState#unite_status.id,SceneId,0,X,Y,[{group,0}]),
	{reply, 1, New_State};

handle_call({get_status,FactionId}, _From, State) ->
	Status = State#state.factionwar_stauts,
	case Status of
		2-> %%报名阶段
			{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
			Config_Begin_Hour = State#state.config_begin_hour,
			Config_Begin_Minute = State#state.config_begin_minute,
			Sign_up_time = State#state.sign_up_time,
			Temp_RestTime=(Config_Begin_Hour*60+Config_Begin_Minute + Sign_up_time)*60 - (Hour*60*60+Minute*60+Second),
			if
				Temp_RestTime<0->RestTime = 0;
				true->RestTime = Temp_RestTime
			end,
			case dict:is_key(FactionId, State#state.factionwar_sign_up_dict) of
				false->SignUpNum=0;
				true->
					SignUpList = dict:fetch(FactionId, State#state.factionwar_sign_up_dict),
					SignUpNum=length(SignUpList)
			end;
		3-> %%帮战进行时
			RestTime=0,
			case dict:is_key(FactionId, State#state.factionwar_sign_up_dict) of
				false->SignUpNum=0;
				true->
					SignUpList = dict:fetch(FactionId, State#state.factionwar_sign_up_dict),
					SignUpNum=length(SignUpList)
			end;
		_->
			RestTime=0,SignUpNum=0
	end,
	Reply = [Status,RestTime,SignUpNum,State#state.loop_time,State#state.loop],
	{reply, Reply, State};

handle_call({have_next_loop}, _From, State) ->
	Current_loop = State#state.current_loop,
	Loop = State#state.loop,
	if
		Loop =:= 0 -> Reply = 0;
		Loop=<Current_loop -> Reply = 0;
		true->Reply = 1
	end,
	{reply, Reply, State};
	
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
handle_cast({get_factionwar_info,Uid}, State) -> 
	%计算剩余时间
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60 + Second,
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
	Sign_up_time = State#state.sign_up_time,
	Loop = State#state.loop,
	Loop_Time = State#state.loop_time,
	Config_FactionWar_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute + Sign_up_time)*60,%%帮战开始时刻
	Config_End = Config_FactionWar_Begin+Loop*Loop_Time*60,%%帮战结束时刻
	if
		Config_End<NowTime->RestTime=0;
		true->RestTime = Config_End-NowTime
	end,
	%% 个人
	case dict:is_key(Uid, State#state.merber_dict) of
		false->Score=0,Anger=0,RestRevive=0,FactionWarScore=0,WarId=0;
		true->
			Member = dict:fetch(Uid, State#state.merber_dict),
			Dead_num = data_factionwar:get_factionwar_config(dead_num),
			Score=Member#member.war_score,Anger=Member#member.anger,
			if 
				Member#member.killed_num=<Dead_num->
					RestRevive=Dead_num - Member#member.killed_num;
				true->RestRevive=0
			end,
			%% 帮战战分
			FactionId = Member#member.faction_id,
			case dict:is_key(FactionId, State#state.factionwar_dict) of
				false->FactionWarScore=0,WarId=0;
				true->
					Factionwar = dict:fetch(FactionId, State#state.factionwar_dict),
					FactionWarScore = Factionwar#factionwar.war_score,
					WarId=Factionwar#factionwar.war_id
			end
	end,
	%金箍棒占领情况
	CopyId = integer_to_list(State#state.current_loop)++ "_" ++integer_to_list(WarId),
	case WarId of
		0->
			IsGetJGB=0,FactionName= <<"">>,FactionWarList=[],KillList=[],Jgb_FactionId=0;
		_->
			case dict:is_key(CopyId, State#state.jgb_faction) of
				false-> %%无占领金箍棒帮派
					IsGetJGB=0,FactionName= <<"">>,Jgb_FactionId=0;
				true ->
					{FactionId1,_MemberId} = dict:fetch(CopyId, State#state.jgb_faction),
					Temp_Factionwar = dict:fetch(FactionId1, State#state.factionwar_dict),
					IsGetJGB=1,FactionName=Temp_Factionwar#factionwar.faction_name,
					Jgb_FactionId=FactionId1
			end,
			case dict:is_key(CopyId, State#state.group) of
				false->GroupList = [];
				true->GroupList = dict:fetch(CopyId, State#state.group)
			end,
			{Temp_FactionWarList,Temp_KillList} = get_info_list(GroupList,State,{[],[]}),
			_FactionWarList = lists:sort(fun({_A_Faction_name,_A_RestNum,_A_War_Score},{_B_Faction_name,_B_RestNum,_B_War_Score})-> 
				if
					_B_War_Score<_A_War_Score->true;
					_B_War_Score=:=_A_War_Score->
						if
							_B_RestNum=<_A_RestNum->true;
							true->false
						end;
					true->false
				end
			end,Temp_FactionWarList),
			_KillList = lists:sort(fun({_A_Name,_A_Faction_name,_A_Kill_num},{_B_Name,_B_Faction_name,_B_Kill_num})-> 
				if
					_B_Kill_num=<_A_Kill_num->true;
					true->false
				end
			end,Temp_KillList),
			if
				5<length(_FactionWarList)->
					{FactionWarList,_} = lists:split(5, _FactionWarList);
				true->
					FactionWarList = _FactionWarList
			end,
			if
				10<length(_KillList)->
					{KillList,_} = lists:split(10, _KillList);
				true->
					KillList = _KillList
			end
	end,
	% 封印怪物占领详情
	case dict:is_key(CopyId, State#state.fy_id_dict) of
		false->
			FyList = [];
		true->
			FyList = dict:fetch(CopyId, State#state.fy_id_dict)
	end,
	% 发送协议
	{ok,BinData} = pt_402:write(40208, [RestTime,FactionWarScore,Score,Anger,RestRevive,
			  					IsGetJGB,FactionName,FactionWarList,KillList,Jgb_FactionId,
							    FyList]),
	lib_unite_send:send_to_uid(Uid, BinData),
	
	{noreply, State};

handle_cast({call_buff}, State) ->
	SceneId = data_factionwar:get_factionwar_config(scene_id),
	%% 清空所有Buff
	Buff_ids = data_factionwar:buff_ids(),
	lists:foreach(fun(Buff_id)-> 
		lib_mon:clear_scene_mon_by_mid(SceneId, Buff_id, 1)
	end, Buff_ids),
	%% 召唤所有新Buff
	Buffs = data_factionwar:get_buff(),
	Keys = dict:fetch_keys(State#state.group),
	lists:foreach(fun(Key)-> 
		Tokens = string:tokens(Key, "_"),
		if
			length(Tokens)=:=2->
				First_tokens = lists:nth(1,Tokens),
				Current_loop = integer_to_list(State#state.current_loop),
				if
					First_tokens =:= Current_loop ->%同一轮的怪
						lists:foreach(fun([Buff_id,X,Y])-> 
							lib_mon:create_mon(Buff_id, SceneId,X,Y, 0, Key, 0, 0)
						end, Buffs),
						%%发送传闻
						lib_chat:send_TV({scene,SceneId,Key},1,2,[refleshyuansen]);
					true->void
				end;		
			true->void
		end
	end, Keys),
	
	{noreply, State};

handle_cast({add_score}, State) ->
	%CopyId = integer_to_list(State#state.current_loop)++ "_" ++integer_to_list(Factionwar#factionwar.war_id),
	Current_loop = integer_to_list(State#state.current_loop),
	Fy_id_List = dict:to_list(State#state.fy_id_dict),
	Jgb_List = dict:to_list(State#state.jgb_faction),
	
	New_State1 = add_score_fy(Fy_id_List,Current_loop,State),
	New_State2 = add_score_jgb(Jgb_List,Current_loop,New_State1),
	
	{noreply, New_State2};

handle_cast({set_score,Type,Uid,KilledUidOrNpcTypeId,Uid_AchieveOrNPCId,KilledUid_Achieve,_HitList}, State) ->
	case Type of
		player->
			case dict:is_key(Uid,State#state.merber_dict) andalso dict:is_key(KilledUidOrNpcTypeId,State#state.merber_dict) of
				false->NewState = State;
				true->
					%%读取配置文件
					Kill_score = data_factionwar:get_factionwar_config(kill_score),
					Killed_score = data_factionwar:get_factionwar_config(killed_score),
					Jgb_kill_ext_score = data_factionwar:get_factionwar_config(jgb_kill_ext_score),
					Max_anger = data_factionwar:get_factionwar_config(max_anger),
					%%获取玩家参赛记录
					Uid_Member = dict:fetch(Uid, State#state.merber_dict),
					KilledUidOrNpcTypeId_Member = dict:fetch(KilledUidOrNpcTypeId, State#state.merber_dict),
					%%帮派记录
					Uid_Faction_id = Uid_Member#member.faction_id,
					KilledUidOrNpcTypeId_Faction_id = KilledUidOrNpcTypeId_Member#member.faction_id,
					Uid_Factionwar = dict:fetch(Uid_Faction_id, State#state.factionwar_dict),
					KilledUidOrNpcTypeId_Factionwar = dict:fetch(KilledUidOrNpcTypeId_Faction_id, State#state.factionwar_dict),
					%%检测是否为金箍棒占领帮派
					case Uid_Factionwar#factionwar.is_capture_jgb=:=1 
						orelse KilledUidOrNpcTypeId_Factionwar#factionwar.is_capture_jgb=:=1 of
						false-> Kill_Ext_War_score = 0;
						true-> Kill_Ext_War_score = Jgb_kill_ext_score
					end,
					if
						Uid_Member#member.anger-1<0->
							Uid_Anger = 0;
						true->Uid_Anger = Uid_Member#member.anger-1
					end,
					if
						Max_anger<KilledUidOrNpcTypeId_Member#member.anger+1->
							Killed_Anger = Max_anger;
						true->Killed_Anger = KilledUidOrNpcTypeId_Member#member.anger+1
					end,
					%%更改玩家记录
					New_Uid_Member = Uid_Member#member{
						war_score = Uid_Member#member.war_score + Kill_score + Kill_Ext_War_score,
						kill_num = Uid_Member#member.kill_num + 1,
						anger = Uid_Anger						   
					},
					New_Killed_Member = KilledUidOrNpcTypeId_Member#member{
						war_score = KilledUidOrNpcTypeId_Member#member.war_score + Killed_score,
						killed_num = KilledUidOrNpcTypeId_Member#member.killed_num + 1,
						anger = Killed_Anger						   
					},
					%%设置幽灵状态
					Ddead_num = data_factionwar:get_factionwar_config(dead_num),
					if
						Ddead_num=<New_Killed_Member#member.killed_num->
							lib_player:change_pk_status_cast(KilledUidOrNpcTypeId,7); %%切换阵营
						true->
							void
					end,
					New_Uid_Factionwar = Uid_Factionwar#factionwar{
 						war_score = Uid_Factionwar#factionwar.war_score + Kill_score + Kill_Ext_War_score
					},
					New_Killed_Factionwar =	KilledUidOrNpcTypeId_Factionwar#factionwar{
						war_score = KilledUidOrNpcTypeId_Factionwar#factionwar.war_score + Killed_score													   
					}, 
					New_Merber_dict1 = dict:store(Uid, New_Uid_Member, State#state.merber_dict),
					New_Merber_dict2 = dict:store(KilledUidOrNpcTypeId, New_Killed_Member, New_Merber_dict1),
					New_Factionwar_dict1 = dict:store(Uid_Faction_id, New_Uid_Factionwar, State#state.factionwar_dict),
					New_Factionwar_dict2 = dict:store(KilledUidOrNpcTypeId_Faction_id, New_Killed_Factionwar, New_Factionwar_dict1),
					_NewState = State#state{
						factionwar_dict = New_Factionwar_dict2,
						merber_dict = New_Merber_dict2					
					},
					%%设置助攻分
					NewState = set_hit_score(_HitList,util:longunixtime(),_NewState),
					%%成就
					lib_player_unite:trigger_achieve(Uid, trigger_trial, [Uid_AchieveOrNPCId, Uid, 34, 0, Kill_score + Kill_Ext_War_score]),
					lib_player_unite:trigger_achieve(KilledUidOrNpcTypeId, trigger_trial, [KilledUid_Achieve, KilledUidOrNpcTypeId, 34, 0, Killed_score])
			end;
		npc->
			case dict:is_key(Uid, State#state.merber_dict) of
				false->NewState = State;
				true->
					Member = dict:fetch(Uid, State#state.merber_dict),
					Factionwar = dict:fetch(Member#member.faction_id, State#state.factionwar_dict),
					[Jgb_id1,Jgb_id2] = data_factionwar:get_factionwar_config(jgb_id),
					Scene_id = data_factionwar:get_factionwar_config(scene_id),
					[Jgb_posion_x,Jgb_posion_y] = data_factionwar:get_factionwar_config(jgb_posion),
					[Fy1_id1,Fy1_id2,Fy1_id3] = data_factionwar:get_factionwar_config(fy1_id),
					[Fy2_id1,Fy2_id2,Fy2_id3] = data_factionwar:get_factionwar_config(fy2_id),
					CopyId = integer_to_list(State#state.current_loop)++ "_" ++integer_to_list(Factionwar#factionwar.war_id),
					Flag_Fy1 = lists:member(KilledUidOrNpcTypeId, [Fy1_id1,Fy1_id2,Fy1_id3]),
					Flag_Fy2 = lists:member(KilledUidOrNpcTypeId, [Fy2_id1,Fy2_id2,Fy2_id3]),
					Cjs_id = data_factionwar:get_factionwar_config(cjs_id),
					Fy_mons = data_factionwar:get_factionwar_config(fy_mons),
					Flag_Fy_Mon = lists:member(KilledUidOrNpcTypeId, Fy_mons),
					if
						Flag_Fy_Mon =:= true -> %五行神兽
							%% 加分
							Fy_mon_kill_score = data_factionwar:get_factionwar_config(fy_mon_kill_score),
							Member_ids = Factionwar#factionwar.member_ids,
							Factionwar_Add_War_score = Fy_mon_kill_score * length(Member_ids),
							Temp_Factionwar = Factionwar#factionwar{war_score = Factionwar#factionwar.war_score + Factionwar_Add_War_score},
							Temp_Factionwar_Dict = dict:store(Factionwar#factionwar.faction_id, Temp_Factionwar, State#state.factionwar_dict),
							Temp_State = State#state{factionwar_dict=Temp_Factionwar_Dict},
							_NewState = add_fy_mon_kill_score(Member_ids,Fy_mon_kill_score,Temp_State),
							%重置上次占领的怪
							case dict:is_key(CopyId, State#state.fy_id_dict) of
								false-> %%暂无记录
									Fy_id = [];
								true->
									Fy_id = dict:fetch(CopyId, State#state.fy_id_dict)
							end,
							_Fy_id = reset_fy(Fy_id,Factionwar#factionwar.faction_id,[Scene_id,CopyId],[]),
							%% 召唤封印
							[Fy_Type_id,Fy_x,Fy_y] = data_factionwar:get_fy_id_by_kill_mon(KilledUidOrNpcTypeId),
							World_lv = lib_player:world_lv(1),
							Zl_fy_Id = lib_mon:sync_create_mon(Fy_Type_id, Scene_id,Fy_x,Fy_y, 0, CopyId, 1,[{auto_lv,World_lv}, {group,Factionwar#factionwar.faction_id}]),
							%%monTypeId,monId,Uid,FactionId
							New_Fy_id = _Fy_id ++ [{Fy_Type_id,Zl_fy_Id,Uid,Factionwar#factionwar.faction_id,Factionwar#factionwar.faction_name}],
							New_Fy_id_Dict = dict:store(CopyId, New_Fy_id,State#state.fy_id_dict),
							NewState = _NewState#state{fy_id_dict=New_Fy_id_Dict};
						Flag_Fy1 orelse Flag_Fy2-> %封印怪
							case dict:is_key(CopyId, State#state.fy_id_dict) of
								false-> %%对应物怪物记录，有异常情况
									NewState = State;
								true->
									Fy_id = dict:fetch(CopyId, State#state.fy_id_dict),
									Mon = [{MonTypeId,MonId,MonUid,MonFactionId,FactionName}||
										   {MonTypeId,MonId,MonUid,MonFactionId,FactionName}<-Fy_id,
											 MonTypeId=:=KilledUidOrNpcTypeId,
											 MonId=:=Uid_AchieveOrNPCId],
									case Mon of
										[]->NewState = State; %非本场景的怪，直接跳过
										[{MonTypeId,MonId,MonUid,MonFactionId,FactionName}]->%是本场的怪
											%处理怪物（清理重召）
											[Zl_fy_id,Zl_fy_id_X,Zl_fy_id_Y] = data_factionwar:get_zl_fy_id(KilledUidOrNpcTypeId),
											%lib_mon:clear_scene_mon_by_mid(Scene_id, CopyId, MonTypeId, 1),
											World_lv = lib_player:world_lv(1),
											Zl_fy_Id1 = lib_mon:sync_create_mon(Zl_fy_id, Scene_id,Zl_fy_id_X, Zl_fy_id_Y, 0, CopyId, 1, [{auto_lv,World_lv}, {group,Factionwar#factionwar.faction_id}]),
											Temp_Fy_id = lists:delete({MonTypeId,MonId,MonUid,MonFactionId,FactionName}, Fy_id),
											%重置上次占领的怪
											_Fy_id = reset_fy(Temp_Fy_id,Factionwar#factionwar.faction_id,[Scene_id,CopyId],[]),
											%%monTypeId,monId,Uid,FactionId
											New_Fy_id = _Fy_id ++ [{Zl_fy_id,Zl_fy_Id1,Uid,Factionwar#factionwar.faction_id,Factionwar#factionwar.faction_name}],
											New_Fy_id_Dict = dict:store(CopyId, New_Fy_id,State#state.fy_id_dict),
											NewState = State#state{fy_id_dict=New_Fy_id_Dict}
									end
							end;
						KilledUidOrNpcTypeId=:=Jgb_id1 orelse KilledUidOrNpcTypeId=:=Jgb_id2-> %金箍棒
                            lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [Jgb_id1,Jgb_id2]),
							lib_mon:sync_create_mon(Jgb_id2, Scene_id, Jgb_posion_x, Jgb_posion_y, 0, CopyId, 1, [{auto_lv,0}, {group, Factionwar#factionwar.faction_id}]),
							Jgb_first_kill_score = data_factionwar:get_factionwar_config(jgb_first_kill_score),
							if
								KilledUidOrNpcTypeId=:=Jgb_id1-> %%第一种怪物,添加首杀分
									Len = length(Factionwar#factionwar.member_ids),
									New_factionwar = Factionwar#factionwar{war_score = Factionwar#factionwar.war_score + Jgb_first_kill_score*Len,
																		   is_capture_jgb=1};
								true->
									New_factionwar = Factionwar#factionwar{is_capture_jgb=1}
							end,
							New_factionwar_dict = dict:store(Member#member.faction_id, New_factionwar, State#state.factionwar_dict),
							case dict:is_key(CopyId, State#state.jgb_faction) of
								false->
									New_factionwar_dict1 = New_factionwar_dict;
								true->
									{Jgb_faction_id,_MemberId} = dict:fetch(CopyId, State#state.jgb_faction),
									Jgb_factionwar = dict:fetch(Jgb_faction_id, New_factionwar_dict),
									New_Jgb_factionwar = Jgb_factionwar#factionwar{is_capture_jgb=0},
									New_factionwar_dict1 = dict:store(Jgb_faction_id, New_Jgb_factionwar, New_factionwar_dict)
							end,
							New_Jgb_faction_dict = dict:store(CopyId, {Member#member.faction_id,Uid}, State#state.jgb_faction),
							%%发送传闻
							lib_chat:send_TV({scene,Scene_id,CopyId},1,2,[guildswar,
																		  1,
																		  Member#member.id,
																		  Member#member.realm,
																		  Member#member.name,
																		  Member#member.sex,
																		  Member#member.carrer,
																		  Member#member.image,
																		  Member#member.faction_name]),
							T_NewState = State#state{
								factionwar_dict = New_factionwar_dict1,
								jgb_faction = New_Jgb_faction_dict			   
							},
							if
								KilledUidOrNpcTypeId=:=Jgb_id1-> %%第一种怪物,添加首杀分
									NewState = set_jgb_first_kill_score(Factionwar#factionwar.member_ids,Jgb_first_kill_score,T_NewState);
								true->
									NewState = T_NewState
							end;
						KilledUidOrNpcTypeId=:=Cjs_id -> %%采集石怪
							Cjs_kill_score = data_factionwar:get_factionwar_config(cjs_kill_score),
							New_Member = Member#member{war_score=Member#member.war_score+Cjs_kill_score},
							New_factionwar = Factionwar#factionwar{war_score = Factionwar#factionwar.war_score + Cjs_kill_score},
							New_Member_Dict = dict:store(Uid, New_Member, State#state.merber_dict),
							New_factionwar_Dict = dict:store(Member#member.faction_id, New_factionwar, State#state.factionwar_dict),
							NewState = State#state{
								merber_dict = New_Member_Dict,
								factionwar_dict = New_factionwar_Dict			   
							};
						true->NewState = State
					end
			end;
        stone -> %% 帮派神石
            case dict:is_key(Uid, State#state.merber_dict) of
                false->NewState = State;
                true->
                    Member = dict:fetch(Uid, State#state.merber_dict),
                    Factionwar = dict:fetch(Member#member.faction_id, State#state.factionwar_dict),
                    StoneScoreList = data_factionwar:get_factionwar_config(stone_score_list),
                    StoneScore = lists:nth(KilledUidOrNpcTypeId, StoneScoreList),
                    New_Member = Member#member{war_score=Member#member.war_score+StoneScore},
                    New_factionwar = Factionwar#factionwar{war_score = Factionwar#factionwar.war_score + StoneScore},
                    New_Member_Dict = dict:store(Uid, New_Member, State#state.merber_dict),
                    New_factionwar_Dict = dict:store(Member#member.faction_id, New_factionwar, State#state.factionwar_dict),
                    NewState = State#state{
                        merber_dict = New_Member_Dict,
                        factionwar_dict = New_factionwar_Dict			   
                    }
            end;
		_->NewState = State
	end,
	{noreply, NewState};

handle_cast({set_time,Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction}, State) ->
	NewState = set_time_sub(Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction,State),
	Factionwar_dbs_Dict = lib_factionwar:load_factionwar(),
	NewState2 = NewState#state{
		factionwar_dbs = Factionwar_dbs_Dict
	},
	{noreply, NewState2};

handle_cast({load_factionwar_dbs}, State) ->
	Factionwar_dbs_Dict = lib_factionwar:load_factionwar(),
	NewState = State#state{
		factionwar_dbs = Factionwar_dbs_Dict
	},
	{noreply, NewState};

handle_cast({set_status,Factionwar_Stauts}, State) ->
	New_State = State#state{factionwar_stauts = Factionwar_Stauts},
    {noreply, New_State};

handle_cast({sign_up_factionwar}, State) ->
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
	Sign_up_time = State#state.sign_up_time,
	RestTime=(Config_Begin_Hour*60+Config_Begin_Minute+Sign_up_time)*60-(Hour*60*60+Minute*60+Second),			
	{ok,BinData} = pt_402:write(40202, [RestTime,State#state.loop_time]),
	%%向所有3级以上资金100000以上帮派发送此协议
	Faction_lv = data_factionwar:get_factionwar_config(faction_lv),
	Can_sign_up_factions_List = lib_factionwar:get_faction_ids_by_lv_and_funds(Faction_lv),
	Factionwar_dbs_Dict = lib_factionwar:load_factionwar(),
	New_Can_sign_up_factions = put_can_sign_up_factions(Can_sign_up_factions_List,State#state.can_sign_up_factions),
	%%向所有达到等级玩家发送协议
	MinLv = data_factionwar:get_factionwar_config(lv),
	lib_unite_send:send_to_all(MinLv, 999, BinData),
	New_State = #state{factionwar_dbs = Factionwar_dbs_Dict,
					   factionwar_stauts = 2,
					   can_sign_up_factions = New_Can_sign_up_factions,
					   top_100_player_factionwar = State#state.top_100_player_factionwar,	
					   config_begin_hour= State#state.config_begin_hour,
					   config_begin_minute= State#state.config_begin_minute,
					   sign_up_time = State#state.sign_up_time,
					   loop_time = State#state.loop_time,
					   max_faction = State#state.max_faction
	},
    {noreply, New_State};

handle_cast({open_factionwar,_NowTime}, State) ->
	Temp_State1 = State#state{
		factionwar_stauts = 3,
		last_time = _NowTime %本轮起始时刻
	},
	%%分配战场
	%%筛选报名成功队伍及失败队伍
	Factionwar_sign_up_dict_list = dict:to_list(Temp_State1#state.factionwar_sign_up_dict),
	[Sign_up_succ_factions,Sign_up_fail_factions] = get_sign_up_succ_and_fail_faction(Factionwar_sign_up_dict_list,[[],[]]),
	Max_faction_num = Temp_State1#state.max_faction,
	Loop = lib_factionwar:get_loop(length(Sign_up_succ_factions),Max_faction_num,0),
	if
		0<Loop->
			Temp_State = Temp_State1#state{current_loop = 1,loop=Loop},
			%%按照各帮派历史总积分排序，并进行分组
			Sort_List_by_history_score = lists:sort(fun(A,B)-> 
				case dict:is_key(A, Temp_State#state.factionwar_dbs) of
					false->A_Score = 0;
					true->
						Temp = dict:fetch(A, Temp_State#state.factionwar_dbs),
						A_Score = Temp#factionwar_db.faction_score
				end,
				case dict:is_key(B, Temp_State#state.factionwar_dbs) of
					false->B_Score = 0;
					true->
						Temp2 = dict:fetch(B, Temp_State#state.factionwar_dbs),
						B_Score = Temp2#factionwar_db.faction_score
				end,
				if
					A_Score=<B_Score->false;
					true->true
				end
			end, Sign_up_succ_factions),
			New_State = make_group(Sort_List_by_history_score,Temp_State);
		true->
			New_State = Temp_State1
	end,
	%计算剩余时间
	{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
	NowTime = (Hour*60+Minute)*60 + Second,
	Config_Begin_Hour = State#state.config_begin_hour,
	Config_Begin_Minute = State#state.config_begin_minute,
	Sign_up_time = State#state.sign_up_time,
	Loop_Time = State#state.loop_time,
	Config_FactionWar_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute + Sign_up_time)*60,%%帮战开始时刻
	Config_End = Config_FactionWar_Begin+Loop*Loop_Time*60,%%帮战结束时刻
	if
		Config_End<NowTime->RestTime=0;
		true->RestTime = Config_End-NowTime
	end,
	%%向所有参与报名帮派发送参展结果协议
	lists:foreach(fun(E)-> 
		{ok,BinData} = pt_402:write(40204, [1,Loop,RestTime]),
		lib_unite_send:send_to_guild(E, BinData)					  
    end, Sign_up_succ_factions),
	%%向所有报名失败帮派返回资金及结果协议
%% 	Money = data_factionwar:get_factionwar_config(money),
	lists:foreach(fun(E)-> 
%% 		lib_guild_base:guild_add_funds(E, Money),						  
		{ok,BinData} = pt_402:write(40204, [0,Loop,RestTime]),
		lib_unite_send:send_to_guild(E, BinData)					  
    end, Sign_up_fail_factions),
	Final_New_State = New_State#state{
		sign_up_succ_factions = Sign_up_succ_factions,
		sign_up_fail_factions = Sign_up_fail_factions
    },
    {noreply, Final_New_State};

handle_cast({cancle_round_factionwar,NowTime}, State) ->
	%%排序，计算出晋级名单及下一轮分组名单
	{SortList,New_State} = sort_by_each_round(0,State),
	New_State2 = New_State#state{factionwar_stauts = 3,
							current_loop = New_State#state.current_loop+1,  %当前进行的轮次
							last_time = NowTime %本轮起始时刻
	},
	%%计算下一轮分组名单
	New_State3 = make_group(SortList,New_State2),
    {noreply, New_State3};

handle_cast({end_factionwar,Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction}, State) ->
	%%发送结束协议
	{ok,_Data_Bin} = pt_402:write(40213, []),
	lib_unite_send:send_to_all(_Data_Bin),
	%%有成功报名的帮派，才能往下走
	Sign_up_succ_factions = State#state.sign_up_succ_factions,
	if
		0<length(Sign_up_succ_factions)->
			%%分组，设置积分
			{_SortList,New_State1} = sort_by_each_round(1,State),
			New_State = New_State1#state{factionwar_stauts = 4},
			%%排序个人
			MemberList = dict:to_list(New_State#state.merber_dict),
			Sort_MemberList = lists:sort(fun({_K1,V1},{_K2,V2})-> 
				if
					V2#member.kill_num<V1#member.kill_num->true;
					V2#member.kill_num =:= V1#member.kill_num->
						if
							V2#member.war_score=<V1#member.war_score->true;
							true->false	
						end;
					true->false
				end
     		end, MemberList),
			Temp_Sort_MemberList = [{V#member.name,V#member.faction_name,V#member.kill_num}||{_K,V}<-Sort_MemberList],
			if
				110<length(Temp_Sort_MemberList)->
					{Final_Sort_MemberList,_} = lists:split(110, Temp_Sort_MemberList);
				true->
					Final_Sort_MemberList = Temp_Sort_MemberList
			end,
			%%排序帮派
			FactionwarList = dict:to_list(New_State#state.factionwar_dict),
			Sort_FactionwarList = lists:sort(fun({_K1,V1},{_K2,V2})-> 
				if
					V2#factionwar.score<V1#factionwar.score->true;
					V2#factionwar.score=:=V1#factionwar.score->
						if
							V2#factionwar.war_score=<V1#factionwar.war_score->true;
							true->false
						end;
					true->false
				end
  			end, FactionwarList),
			Multiple_all_data = mod_multiple:get_all_data(),
			Multiple = lib_multiple:get_multiple_by_type(3,Multiple_all_data),
			Final_Sort_factionwar = [{V#factionwar.faction_name,V#factionwar.faction_realm,
									  V#factionwar.score,Multiple*V#factionwar.war_score}||{_K,V}<-Sort_FactionwarList],
			if
				0<length(Final_Sort_factionwar)->
					{Faction_name,_,_,_} = lists:nth(1, Final_Sort_factionwar);
				true->Faction_name= <<"">>
			end,
			%% 重置所有帮战最后获胜标志
			lib_factionwar:update_reset_last_is_win(),
			Factionwar_dbs_List = dict:to_list(New_State#state.factionwar_dbs),
			New_factionwar_dbs = reset_last_is_win_db(Factionwar_dbs_List,dict:new()),
			New_State_Reset = New_State#state{factionwar_dbs=New_factionwar_dbs},
			{Temp_New_State,TopFactionList,TopFactionList10} = get_no(Multiple,New_State_Reset,util:unixtime(),Faction_name,
													 Sort_FactionwarList,Sort_MemberList,
													 Final_Sort_MemberList,Final_Sort_factionwar,[],[],1),
			%% 帮派战结束时，插入排前三的帮派帮主的id
			%% List : 如[121, 12, 34]或[121, 34]
			spawn(fun()-> 
				lib_rank_activity:insert_guild_stat(TopFactionList)
			end),
			spawn(fun()-> 
				%%参数为前10名的帮派id
				lib_activity_merge:guild_award(TopFactionList10)
			end);
		true->
			Temp_New_State = State#state{factionwar_stauts = 4}
	end,
	spawn(fun()-> 
		%% 清除本副本所有怪物
		Scene_id = data_factionwar:get_factionwar_config(scene_id),
        lib_mon:clear_scene_mon(Scene_id,[],1)
	end),
	New_State2 = set_time_sub(Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction,Temp_New_State),
    {noreply, New_State2};

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
%%获取击杀和未击杀神兽
get_Fy_mon_List([],_Fy_mon_List_Killed,Result)->Result;
get_Fy_mon_List([H|T],Fy_mon_List_Killed,Result)->
	case lists:member(H, Fy_mon_List_Killed) of
		false->get_Fy_mon_List(T,Fy_mon_List_Killed,Result++[{H,0}]);
		true->get_Fy_mon_List(T,Fy_mon_List_Killed,Result++[{H,1}])
	end.

%%定时加分
add_score_jgb([],_Current_loop,State)->State;
add_score_jgb([{K,{FactionId,_Uid}}|T],Current_loop,State)->
	K_List = string:tokens(K, "_"),
	if
		0<length(K_List)->
			First_K_List = lists:nth(1, K_List),
			if
				First_K_List=:=Current_loop->
					case dict:is_key(FactionId, State#state.factionwar_dict) of
						false->add_score_jgb(T,Current_loop,State);
						true->
							Factionwar = dict:fetch(FactionId, State#state.factionwar_dict),
							Add_score_jgb = data_factionwar:get_factionwar_config(add_score_jgb),
							New_Factionwar = Factionwar#factionwar{war_score=Factionwar#factionwar.war_score + Add_score_jgb},
							New_Factionwar_dict = dict:store(FactionId, New_Factionwar,State#state.factionwar_dict),
							add_score_jgb(T,Current_loop,State#state{factionwar_dict=New_Factionwar_dict})
					end;
				true->
					add_score_jgb(T,Current_loop,State)
			end;
		true->
			add_score_jgb(T,Current_loop,State)
	end.
add_score_fy([],_Current_loop,State)->State;
add_score_fy([{K,V}|T],Current_loop,State)->
	K_List = string:tokens(K, "_"),
	if
		0<length(K_List)->
			First_K_List = lists:nth(1, K_List),
			if
				First_K_List=:=Current_loop->
					T_MonFactionIdList = [MonFactionId||{_MonTypeId,_MonId,_MonUid,MonFactionId,_FactionName}<-V,MonFactionId/=0],
					case lists_unit(T_MonFactionIdList,[]) of
						[]->
							add_score_fy(T,Current_loop,State);
						MonFactionIdList->
							New_State = add_score_fy_sub(MonFactionIdList,State),
							add_score_fy(T,Current_loop,New_State)
					end;
				true->
					add_score_fy(T,Current_loop,State)
			end;
		true->
			add_score_fy(T,Current_loop,State)
	end.
add_score_fy_sub([],State)->State;
add_score_fy_sub([H|T],State)->
	case dict:is_key(H, State#state.factionwar_dict) of
		false->
			add_score_fy_sub(T,State);
		true->
			Factionwar = dict:fetch(H, State#state.factionwar_dict),
			Add_score_fy = data_factionwar:get_factionwar_config(add_score_fy),
			New_Factionwar = Factionwar#factionwar{war_score=Factionwar#factionwar.war_score + Add_score_fy},
			New_Factionwar_dict = dict:store(H, New_Factionwar,State#state.factionwar_dict),
			add_score_fy_sub(T,State#state{factionwar_dict=New_Factionwar_dict})
	end.
lists_unit([],Resut)->Resut;
lists_unit([H|T],Resut)->
	case lists:member(H, Resut) of
		false->lists_unit(T,Resut++[H]);
		true->
			lists_unit(T,Resut)
	end.

% 重置最后一次夺冠纪录
reset_last_is_win_db(Factionwar_Db_List,FactionwarDb_dict)->
	case Factionwar_Db_List of
		[]->FactionwarDb_dict;
		[{K,V}|T]->
			New_V = V#factionwar_db{last_is_win=0},
			reset_last_is_win_db(T,dict:store(K, New_V, FactionwarDb_dict))
	end.

%%设置时间的子方法
set_time_sub(Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction,State)->
	% 帮战历史记录(积分榜之类)
	Top_100_player_factionwar = lib_factionwar:get_top_100_player_factionwar(),
	NewState = State#state{
		top_100_player_factionwar = Top_100_player_factionwar,	
		config_begin_hour=Config_Begin_Hour,
		config_begin_minute=Config_Begin_Minute,
		sign_up_time = Sign_Up_Time,
		loop_time = Loop_Time,
		max_faction = Max_faction
	},
	NewState.

%%设置金箍棒首杀分
set_jgb_first_kill_score(Member_ids,Jgb_first_kill_score,State)->
	case Member_ids of
		[]->State;
		[H|T]->
			case dict:is_key(H, State#state.merber_dict) of
				false->set_jgb_first_kill_score(T,Jgb_first_kill_score,State);
				true->
					Member = dict:fetch(H, State#state.merber_dict),
					New_Member = Member#member{war_score=Member#member.war_score+Jgb_first_kill_score},
					New_Member_dict = dict:store(H, New_Member, State#state.merber_dict),
					New_State = State#state{merber_dict=New_Member_dict},
					set_jgb_first_kill_score(T,Jgb_first_kill_score,New_State)
			end
	end.

%%帮派是否有封印
have_Fy(Fy_Id,Faction_id)->
	case Fy_Id of
		[]->false;
		[{_MonTypeId,_MonId,_Uid,T_FactionId,_FactionName}|T]->
			if
				Faction_id=:=T_FactionId->
					true;
				true->
					have_Fy(T,Faction_id)
			end
	end.
	
%%获取封印位置，供复活用
get_Fy_X_Y(Fy_Id,Faction_id,{X,Y})->
	case Fy_Id of
		[]->{X,Y};
		[{MonTypeId,_MonId,_Uid,T_FactionId,_FactionName}|T]->
			if
				Faction_id=:=T_FactionId->
					[_,N_X,N_Y] = data_factionwar:get_zl_fy_id(MonTypeId),
					{N_X,N_Y};%复活位置偏移
				true->
					get_Fy_X_Y(T,Faction_id,{X,Y})
			end
	end.

%%清理上一个占领的封印
reset_fy(Temp_Fy_id,FactionId,[Scene_id,CopyId],Fy_ids)->
	case Temp_Fy_id of
		[]->Fy_ids;
		[{MonTypeId,MonId,MonUid,MonFactionId,FactionName}|T]->
			if
				MonFactionId=:=FactionId->
					[Reset_fy_id,Reset_fy_id_X,Reset_fy_id_Y] = data_factionwar:get_zl_fy_id(MonTypeId),
                    lib_mon:clear_scene_mon_by_mids(Scene_id, CopyId, 1, [MonTypeId]),
					World_lv = lib_player:world_lv(1),
					Reset_Mon_Id1 = lib_mon:sync_create_mon(Reset_fy_id, Scene_id, Reset_fy_id_X,Reset_fy_id_Y, 0, CopyId, 1,  [{auto_lv, World_lv}, {group, 0}]),
					reset_fy(T,FactionId,[Scene_id,CopyId],Fy_ids++[{Reset_fy_id,Reset_Mon_Id1,0,0,<<"">>}]);
				true->
					reset_fy(T,FactionId,[Scene_id,CopyId],Fy_ids++[{MonTypeId,MonId,MonUid,MonFactionId,FactionName}])
			end
	end.

%%添加封印首杀分
%% @param Member_ids 成员列表
%% @param Fy_first_kill_score 首杀分
%% @param State #state
%% @return New_State
add_fy_mon_kill_score(Member_ids,Fy_first_kill_score,State)->
	case Member_ids of
		[]->State;
		[H|T]->
			case dict:is_key(H, State#state.merber_dict) of
				false->add_fy_mon_kill_score(T,Fy_first_kill_score,State);
				true->
					Member = dict:fetch(H, State#state.merber_dict),
					New_Member = Member#member{war_score=Member#member.war_score+Fy_first_kill_score},
					New_merber_dict = dict:store(H, New_Member, State#state.merber_dict),
					New_State = State#state{merber_dict = New_merber_dict},
					add_fy_mon_kill_score(T,Fy_first_kill_score,New_State)
			end
	end.

%%设置助攻分
%% @param _HitList 助攻列表
%% @param NowTime 
%% @param State #state
%% @return #state
set_hit_score(_HitList,NowTime,State)->
	case _HitList of
		[{Uid,Time}|T]->
			if
				3*1000<(NowTime-Time)->set_hit_score(T,NowTime,State);
				true->
					case dict:is_key(Uid,State#state.merber_dict) of
						false->set_hit_score(T,NowTime,State);
						true->
							Uid_Member = dict:fetch(Uid, State#state.merber_dict),
							Hold_kill_score = data_factionwar:get_factionwar_config(hold_kill_score),
							New_Uid_Member = Uid_Member#member{
								war_score = Uid_Member#member.war_score + Hold_kill_score
							},
							New_Merber_dict = dict:store(Uid, New_Uid_Member, State#state.merber_dict),
							NewState = State#state{
								merber_dict = New_Merber_dict					
							},
							set_hit_score(T,NowTime,NewState)
					end
			end;
		_->State
	end.

%%获取帮派记录排名
get_factionwar_db_no(Factionwar_dbs_to_list,FactionId,{Index,List})->
	case Factionwar_dbs_to_list of
		[]->{Index,List};
		[{K,V}|T]->
			if
				K=:=FactionId->
					New_Index = Index+1;
				true->
					New_Index = Index
			end,
			New_List = List ++ [{V#factionwar_db.faction_name,
								 V#factionwar_db.faction_realm,
								 V#factionwar_db.faction_score,
								 V#factionwar_db.faction_war_score}],
			get_factionwar_db_no(T,FactionId,{New_Index,New_List})
	end.

%%帮战结束后，进行的一些处理
%%@param Faction_name 排名第一帮派名称
get_no(Multiple,State,NowTime,Faction_name,Sort_FactionwarList,Sort_MemberList,Final_Sort_MemberList,Final_Sort_factionwar,TopFactionList,TopFactionList10,Index)->
	case Sort_FactionwarList of
		[]->{State,TopFactionList,TopFactionList10};
		[{FactionId,Factionwar}|T]->
			Member_ids = Factionwar#factionwar.member_ids,
			Sort_Member_ids = lists:sort(fun(Id1,Id2)-> 
				Member1 = dict:fetch(Id1, State#state.merber_dict),	
				Member2 = dict:fetch(Id2, State#state.merber_dict),
				if%%按战分排序
					Member2#member.war_score=<Member1#member.war_score->true;
					true->false
				end
			end, Member_ids),
			if
				Index=<3 ->
					New_TopFactionList = TopFactionList ++ [FactionId];
				true->
					New_TopFactionList = TopFactionList
			end,
			if
				Index=<10 ->
					New_TopFactionList10 = TopFactionList10 ++ [FactionId];
				true->
					New_TopFactionList10 = TopFactionList10
			end,
			%%更新帮派帮战记录
			case Index of
				1->
				   %% 帮战结束传第一名的帮派id进来，公共线调用
				   spawn(fun()-> 
					   lib_designation:bind_guild_design(FactionId, 1),
					   %% 合服名人堂：帮战的获胜帮派的帮主
					   FactionLeaderId = lib_guild:get_bz_id(FactionId),
					   lib_player_unite:trigger_fame(FactionLeaderId, [lib_activity_merge:get_activity_time(), FactionLeaderId, 11601, 0, 1])
				   end),
				   IsFinalWin = 1,
				   lib_factionwar:update_last_is_win(FactionId);%更新获胜标志
				_->IsFinalWin = 0
			end,
			Factionwar_db = dict:fetch(FactionId, State#state.factionwar_dbs),
			New_Factionwar_db = lib_factionwar:update_factionwar(Factionwar#factionwar.score,
											 Multiple*Factionwar#factionwar.war_score,
											 NowTime,IsFinalWin,FactionId,Factionwar_db),
			Add_Score_by_no = data_factionwar:add_score_by_no(Index),
			New_factionwar_dbs = dict:store(FactionId, New_Factionwar_db, State#state.factionwar_dbs),
			New_State = State#state{factionwar_dbs=New_factionwar_dbs},
			%%开启进程，操作每个帮派内部奖励
			spawn(fun()->				
				%%计算帮派获取奖励
				Factionwar_No_Rate = data_factionwar:get_no_rate(Index),
				Factionwar_Build = data_factionwar:get_build(Index),
				%1.帮派--帮派资金
				Factionwar_Funds = Factionwar_No_Rate*Factionwar#factionwar.faction_level*Factionwar#factionwar.score,
				%%2.帮派--帮派建设度
				Factionwar_Build_Value = Factionwar_Build*Factionwar#factionwar.faction_level,
				%%2.个人--帮派财富
				Add_Material = Factionwar#factionwar.score*100,
				gen_server:cast(mod_guild, {factionwer_prize, [FactionId, Factionwar_Funds, Factionwar_Build_Value, Member_ids, Add_Material]}),
				lists:foreach(fun(Id)-> 
					{Kill_num,War_score,No,Lv} = get_no_sub(Multiple,Add_Score_by_no,NowTime,Id,Sort_MemberList,1),
					%%1.个人--经验、帮战记录		
					Add_Exp = round(Lv*Lv*(150+War_score*0.15)),
					Rand_Score = data_factionwar:get_rand_score(),
					case lib_player:update_player_info(Id, [{add_exp,Add_Exp},{factionwar,[War_score+Rand_Score,Kill_num,NowTime,Id]}]) of
						skip->
							%% 同步到帮派成员字段
							gen_server:cast(mod_guild, {factionwar_info, [Id, War_score+Rand_Score,Kill_num,NowTime]}),
							lib_factionwar:update_player_factionwar(Id,War_score+Rand_Score,Kill_num,NowTime);
						_->
							%% 同步到帮派成员字段
							gen_server:cast(mod_guild, {factionwar_info, [Id, War_score+Rand_Score,Kill_num,NowTime]})
					end,
					{ok,DataBin} = pt_402:write(40211, [Faction_name,Kill_num,War_score,Add_Material,
														Index,
														Multiple*Factionwar#factionwar.war_score,
														Add_Exp,
														Final_Sort_factionwar,
														Final_Sort_MemberList]),
					lib_unite_send:send_to_uid(Id, DataBin),
					{ok,DataBin_r} = pt_402:write(40221, [Rand_Score]),
					lib_unite_send:send_to_uid(Id, DataBin_r),
					%%发送礼包
					case No of
						1->
							Gift_Id = data_factionwar:get_factionwar_config(gift_id),
							Gift_Num = 2,
							%%发送邮件
							Title2 = data_mail_log_text:get_mail_log_text(factionwar_title2),
							Content2 = io_lib:format(data_mail_log_text:get_mail_log_text(factionwar_content2),[Kill_num,No,Gift_Num]),
							lib_mail:send_sys_mail_bg([Id], Title2, Content2, Gift_Id, 2, 0, 0,Gift_Num,0,0,0,0),
							spawn(fun()-> 
								%% 合服名人堂：帮派战杀人第一
								lib_player_unite:trigger_fame(Id, [lib_activity_merge:get_activity_time(), Id, 11501, 0, 1])			  
							end);
						_->void
					end,
					timer:sleep(100) %每条协议睡200毫秒
				end, Member_ids),
				%%发送邮件礼包
				spawn(fun()-> 
					send_gift(Index,Sort_Member_ids,1)
				end),
				% 记录帮派事件
				lib_guild:log_guild_event(FactionId, 30, [Factionwar#factionwar.war_score,Index])
			end),
			get_no(Multiple,New_State,NowTime,Faction_name,T,Sort_MemberList,Final_Sort_MemberList,Final_Sort_factionwar,New_TopFactionList,New_TopFactionList10,Index+1)
	end.
%%发送邮件礼品
send_gift(Index,Sort_Member_ids,Pos)->
	case Sort_Member_ids of
		[]->void;
		[H|T]->
			if
				1=:=Index andalso Pos=<10->
					send_mail_gift(Index,10,2,H);
				2=:=Index andalso Pos=<10->
					send_mail_gift(Index,10,1,H);
				3=:=Index andalso Pos=<10->
					send_mail_gift(Index,10,1,H);
				4=:=Index andalso Pos=<5->
					send_mail_gift(Index,5,1,H);
				5=:=Index andalso Pos=<5->
					send_mail_gift(Index,5,1,H);
				true->void
			end,
			timer:sleep(50),
			send_gift(Index,T,Pos+1)
	end.
%%发送邮件礼包
send_mail_gift(Index,Pos,Num,Uid)->
	Gift_Id = data_factionwar:get_factionwar_config(gift_id),
	%%发送邮件
	Title = data_mail_log_text:get_mail_log_text(factionwar_title),
	Content = io_lib:format(data_mail_log_text:get_mail_log_text(factionwar_content),[Index,Pos,Num]),
	lib_mail:send_sys_mail_bg([Uid], Title, Content, Gift_Id, 2, 0, 0,Num,0,0,0,0).

get_no_sub(Multiple,Add_Score_by_no,NowTime,Id,Sort_MemberList,Index)->
	case Sort_MemberList of
		[]->{0,0,0,0};
		[{MemberId,Member}|T]->
			if
				Id=:=MemberId->
					{Member#member.kill_num,Multiple*(Member#member.war_score+Add_Score_by_no),Index,Member#member.lv};
				true->get_no_sub(Multiple,Add_Score_by_no,NowTime,Id,T,Index+1)
			end
	end.

%% 获取每组帮派积分列表级帮众杀人列表
%% @param GroupList 组帮派列表
%% @param State #state
%% @return {FactionWarList,KillList}  
%%		FactionWarList->[{Faction_name,RestNum,War_Score},...]
%%      KillList ->[{Member#member.name,Faction_name,Member#member.kill_num},...]
get_info_list(GroupList,State,{FactionWarList,KillList})->
	case GroupList of
		[]->{FactionWarList,KillList};
		[H|T]->
			FactionWar = dict:fetch(H, State#state.factionwar_dict),
			Faction_name = FactionWar#factionwar.faction_name,
			War_Score = FactionWar#factionwar.war_score,
			Member_ids = FactionWar#factionwar.member_ids,
			{RestNum,MemberList} = get_info_list_sub(Member_ids,Faction_name,State,{0,[]}),
			get_info_list(T,State,{FactionWarList++[{Faction_name,RestNum,War_Score}],
								   KillList++MemberList})
	end.
get_info_list_sub(Member_ids,Faction_name,State,{RestNum,MemberList})->
	case Member_ids of
		[]->{RestNum,MemberList};
		[H|T]->
			Member = dict:fetch(H, State#state.merber_dict),
			Dead_num = data_factionwar:get_factionwar_config(dead_num),
			%%剩余活人
			if
				1=:=Member#member.is_in_war andalso Member#member.killed_num=<Dead_num->
					New_RestNum = RestNum+1;
				true->New_RestNum = RestNum
			end,
			New_MemberList = MemberList++[{Member#member.name,Faction_name,Member#member.kill_num}],
			get_info_list_sub(T,Faction_name,State,{New_RestNum,New_MemberList})
	end.

%%给当前轮排序，并给出晋级有序帮派ID列表
%%@param IsEnd 是否是结束 1是 0非
%%@param State #state
%%@return {[id1,id2,...],New_State}
sort_by_each_round(IsEnd,State)->
	{List,New_State} = sort_by_each_round_sub(IsEnd,1,{[],State}),
	SortList = sort_by_each_group(List,New_State),
	{SortList,New_State}.
sort_by_each_round_sub(IsEnd,WarId,{List,State})->
	if
		State#state.max_warid<WarId->{List,State};
		true->
			CopyId = integer_to_list(State#state.current_loop)++ "_" ++integer_to_list(WarId),
			SigleGroupList = dict:fetch(CopyId, State#state.group),
			SortList = sort_by_each_group(SigleGroupList,State),
			{SuccList,ResultState} = set_score_by_factionwar_no(IsEnd,SortList,State),
			sort_by_each_round_sub(IsEnd,WarId+1,{List++SuccList,ResultState})
	end.
%%供每轮切换时使用，帮战结束时不用该方法
%%单组排序：1.金箍棒占领，占领方胜 2.是否全部幽灵状态，非幽灵泰获胜 3战分，战分高胜  4人数，入场人数少获胜
%%@param SigleGroupList 单组帮派ID列表
%%@param State 本Mod状态#state
%%@return SortList
sort_by_each_group(SigleGroupList,State)->
	%%排序
	SortList = lists:sort(fun(A,B)->
		A_factionwar = dict:fetch(A, State#state.factionwar_dict),
		B_factionwar = dict:fetch(B, State#state.factionwar_dict),
		%%1.金箍棒占领，占领方胜 
		if
			B_factionwar#factionwar.is_capture_jgb < A_factionwar#factionwar.is_capture_jgb->true;%有占领
			B_factionwar#factionwar.is_capture_jgb =:= A_factionwar#factionwar.is_capture_jgb-> %均未占领
				A_is_all_spirit = is_all_spirit(A_factionwar#factionwar.member_ids,State),	
				B_is_all_spirit = is_all_spirit(B_factionwar#factionwar.member_ids,State),
				%%2.是否全部幽灵状态，非幽灵泰获胜
				if
					A_is_all_spirit<B_is_all_spirit->true;
					A_is_all_spirit=:=B_is_all_spirit->
						%%3战分，战分高胜
						if
							B_factionwar#factionwar.war_score<A_factionwar#factionwar.war_score->true;
							B_factionwar#factionwar.war_score =:= A_factionwar#factionwar.war_score->
								%4人数，入场人数少获胜
								A_length = length(A_factionwar#factionwar.member_ids),
								B_length = length(B_factionwar#factionwar.member_ids),
								if
									A_length=<B_length->true;
									true->false
								end;
							true->false
						end;
					true->false
				end;
			true->false	
		end
    end,SigleGroupList),
	SortList.
%%%%供每轮切换时使用，帮战结束时不用该方法
%% 获取每组第一，及设置新状态
%% @param SortList 单组已排序
%% @param State #state
%% @return {SuccList,ResultState} SuccList->[第一帮派ID或没有] ResultState新#state
set_score_by_factionwar_no(IsEnd,SortList,State)->
	%%获取单组第一ID，及新State
	if
		0<length(SortList)->
			FactionId = lists:nth(1, SortList),
			SuccList = [FactionId],
			%%重置本帮参与成员的死亡记录（只对晋级帮派操作）
			New_State = reset_killed_num(IsEnd,FactionId,State),
			ResultState = set_score_by_factionwar_no_sub(IsEnd,SortList,1,New_State);
		true->
			SuccList = [],
			ResultState = State
	end,
	{SuccList,ResultState}.
%%重置玩家被杀记录
reset_killed_num(IsEnd,FactionId,State)->
	case IsEnd of
		1->State;
		_->
			Factionwar = dict:fetch(FactionId, State#state.factionwar_dict),
			Member_ids = Factionwar#factionwar.member_ids,
			reset_killed_num_sub(Member_ids,State)
	end.
reset_killed_num_sub(Member_ids,State)->
	case Member_ids of
		[]->State;
		[H|T]->
			Member = dict:fetch(H, State#state.merber_dict),
			New_Member = Member#member{killed_num = 0},
			New_Merber_dict = dict:store(H, New_Member, State#state.merber_dict),
			New_State = State#state{merber_dict=New_Merber_dict},
			reset_killed_num_sub(T,New_State)
	end.
%%按照排序，改变对应帮派积分
set_score_by_factionwar_no_sub(IsEnd,SortList,Index,State)->
	case SortList of
		[]->State;
		[H|T]->
			Score = data_factionwar:get_score_by_factionwar_no(Index),
			Factionwar = dict:fetch(H, State#state.factionwar_dict),
			if
				1/=Index->
					{ok,DataBin} = pt_402:write(40206, [0]),
					New_pass_faction = State#state.pass_faction++[H];
				true->
					{ok,DataBin} = pt_402:write(40206, [1]),
					New_pass_faction = State#state.pass_faction
			end,
			case IsEnd of
				1->
					void;
				_->
				   lib_unite_send:send_to_guild(H, DataBin)
			end,
			New_Factionwar = Factionwar#factionwar{
				score = Factionwar#factionwar.score + Score
      		},
			New_factionwar_dict = dict:store(H, New_Factionwar, State#state.factionwar_dict),
			New_state = State#state{factionwar_dict=New_factionwar_dict,pass_faction=New_pass_faction},
			set_score_by_factionwar_no_sub(IsEnd,T,Index+1,New_state)
	end.
%%检测帮派幽灵状态，只要有一个死亡次数未到，就返回0
%%@param Member_ids 成员ID列表
%%@param State #state
%%@return 0非亡灵状态 1亡灵
is_all_spirit(Member_ids,State)->
	case Member_ids of
		[]->1;
		[H|T]->
			Dead_num = data_factionwar:get_factionwar_config(dead_num),
			Member = dict:fetch(H, State#state.merber_dict),
			if
				Dead_num<Member#member.kill_num-> %%已死，下一个
					is_all_spirit(T,State);
				true-> %%未死，需判断
					%计算入场剩余时间
					{{_,_,_},{Hour,Minute,Second}} = calendar:local_time(),
					NowTime = (Hour*60+Minute)*60 + Second,
					Config_Begin_Hour = State#state.config_begin_hour,
					Config_Begin_Minute = State#state.config_begin_minute,
					Sign_up_time = State#state.sign_up_time,
					Current_Loop = State#state.current_loop,
					Loop_Time = State#state.loop_time,
					Config_FactionWar_Begin = (Config_Begin_Hour*60 + Config_Begin_Minute + Sign_up_time)*60,%%帮战开始时刻
					Loop_End = Config_FactionWar_Begin+Current_Loop*Loop_Time*60,%%帮战结束时刻
					if
						Loop_End<NowTime->RestTime=0;
						true->RestTime = Loop_End-NowTime
					end,
					%%判断是否已经超出限制进入时间
					No_in_time = data_factionwar:get_factionwar_config(no_in_time),
					if
						RestTime =< No_in_time ->
							Is_No_in = 1;
						true->
							Is_No_in = 0
					end,
					case Is_No_in of
						0-> %还可以入场，则算还有未死玩家
							0;
						_-> %不可入场，则算死亡玩家
							if
								Member#member.is_in_war=:=1->0;%%在场内没死
								true-> %%在场外活着，算死亡，下一个
									is_all_spirit(T,State)
							end
					end
			end
	end.

%%设置帮战历史记录Factionwar_dbs字典
%% @param Factionwar_dbs_List 列表
%% @param Factionwar_dbs 初始字典
%% @return 新字典 
put_factionwar_dbs(Factionwar_dbs_List,Factionwar_dbs)->
	case Factionwar_dbs_List of
		[]->Factionwar_dbs;
		[H|T]->
			New_Factionwar_dbs = dict:store(H#factionwar_db.faction_id, H, Factionwar_dbs),
			put_factionwar_dbs(T,New_Factionwar_dbs)
	end.

%%设置可报名帮派基本资料
%% @param Can_sign_up_factions_List [[FactionId,FactionName,FactionRealm,Level]...]数据库查询出来的帮派信息
%% @param Can_sign_up_factions 初始dict字典
%% @return 新dict字典
put_can_sign_up_factions(Can_sign_up_factions_List,Can_sign_up_factions)->
	case Can_sign_up_factions_List of
		[]->Can_sign_up_factions;
		[[FactionId,FactionName,FactionRealm,Level]|T]->
			New_Can_sign_up_factions = dict:store(FactionId, [FactionId,FactionName,FactionRealm,Level], Can_sign_up_factions),
			put_can_sign_up_factions(T,New_Can_sign_up_factions)
	end.

%% 计算队伍分组
%% 分组算法：(比如11个帮派参与)
%%    1. 计算出有几个房间，房间数为3。
%%    2. 按照如下顺序分配。(如下队伍分配规则)
%%                   房间1   房间2   房间3
%%                    1		 2      3
%%                    6      5      4
%%                    7      8      9
%%                           11     10
%% @param Sort_List 排好序的ID列表
%% @param State 成功报名帮派
%% @return 分组名单列表 [[#factionwar_db,...],[#factionwar_db,...],[#factionwar_db,...]...]
make_group(Sort_List,State)->
	%%读取每张地图最大容量
	Max_faction = State#state.max_faction,
	%%计算房间数
	Sort_List_length = length(Sort_List),
	if
		Sort_List_length rem Max_faction /= 0 ->	%%不能整除
			Room_Num = (Sort_List_length div Max_faction)+1;
		true->%%能整除
			Room_Num = Sort_List_length div Max_faction
	end,
	GroupList = make_group_sub(Sort_List,Room_Num,0,lists:duplicate(Room_Num, [])),
	%% 清除本副本所有怪物
	Scene_id = data_factionwar:get_factionwar_config(scene_id),
    lib_mon:clear_scene_mon(Scene_id,[],1),
	make_group_sub2(GroupList,1,State).

%%处理战场分配逻辑
%%@param GroupList 已经分组列表 [[F1,F2...],[F1,F2,...]...]
%%@param WarId 战场ID,调用时，赋值1即可
%%@param State 本Mod的#state
%%@return 新的state 
make_group_sub2(GroupList,WarId,State)->
	case GroupList of
		[]->State;
		[H|T]->
			%%设置轮次分组情况
			CopyId = integer_to_list(State#state.current_loop)++ "_" ++integer_to_list(WarId),
			Scene_id = data_factionwar:get_factionwar_config(scene_id),
			[[Fy_posion1_X,Fy_posion1_Y],
			 [Fy_posion2_X,Fy_posion2_Y],
			 [Fy_posion3_X,Fy_posion3_Y]] = data_factionwar:get_factionwar_config(fy_posion),
			[Jgb_id1,_Jgb_id2] = data_factionwar:get_factionwar_config(jgb_id),					
			[Jgb_posion_x,Jgb_posion_y] = data_factionwar:get_factionwar_config(jgb_posion),
			[Fy_mons_1,Fy_mons_2,Fy_mons_3] = data_factionwar:get_factionwar_config(fy_mons),
			%% 召唤所有地图编辑器怪物
    		mod_scene_agent:apply_call(Scene_id, mod_scene, copy_dungeon_scene, [Scene_id, CopyId, 0, 0]), 
			%% 召唤所有指定怪物（神兽、金箍棒）
			World_lv = lib_player:world_lv(1),
            lib_mon:async_create_mon(Fy_mons_1, Scene_id, Fy_posion1_X,Fy_posion1_Y, 0, CopyId, 1, [{auto_lv, World_lv}]),
			lib_mon:async_create_mon(Fy_mons_2, Scene_id, Fy_posion2_X,Fy_posion2_Y, 0, CopyId, 1, [{auto_lv, World_lv}]),
			lib_mon:async_create_mon(Fy_mons_3, Scene_id, Fy_posion3_X,Fy_posion3_Y, 0, CopyId, 1, [{auto_lv, World_lv}]),
            lib_mon:async_create_mon(Jgb_id1, Scene_id, Jgb_posion_x, Jgb_posion_y, 0, CopyId, 1, []),
			New_State1 = State#state{
				max_warid = WarId,
				group = dict:store(CopyId, H, State#state.group)
			},
			New_State = make_group_sub3(H,WarId,1,New_State1),
			make_group_sub2(T,WarId+1,New_State)
	end.
%%处理单组帮战记录情况
%%@param SigleGroupList 单个分组列表
%%@param WarId 战场ID
%%@param Born_pos 出生点(调用时，赋值1即可)
%%@param State 本Mod的#state
%%@return 新的state 
make_group_sub3(SigleGroupList,WarId,Born_pos,State)->
	case SigleGroupList of
		[]->State;
		[H|T]->
			%%设置帮派记录战场号
			case dict:is_key(H, State#state.factionwar_dict) of
				false->
					[FactionId,FactionName,FactionRealm,Level] = dict:fetch(H, State#state.can_sign_up_factions),
					Factionwar = #factionwar{       %帮派记录
						faction_id = FactionId,		   %帮派ID
						faction_name = FactionName,	   %帮派名字
						faction_realm = FactionRealm,     %帮派阵营
						faction_level = Level, 			 %帮派等级
						war_id = WarId,    		   %战场ID
						born_pos = Born_pos	   %长生点
					};
				true->
					Temp = dict:fetch(H, State#state.factionwar_dict),
					Factionwar = Temp#factionwar{       %帮派记录
						war_id = WarId,    		   %战场ID
						born_pos = Born_pos		%长生点
					}
			end,
			New_Factionwar_dict = dict:store(H, Factionwar, State#state.factionwar_dict),
			New_State = State#state{
				factionwar_dict = New_Factionwar_dict
			},
			Born = data_factionwar:get_factionwar_config(born),
			if
				length(Born)=<Born_pos->
					Next_Born_Pos = 1;
				true->
					Next_Born_Pos = Born_pos+1
			end,
			make_group_sub3(T,WarId,Next_Born_Pos,New_State)
	end.

%% 获取房间分配
%% @param Sort_List [id1,id2,id3...]已排序列表
%% @param Room_Num 房间容量
%% @param IsReverse 是否反转数组   1是 0非（第一轮请填0）
%% @return Result [[id1,id2,...],[id1,id2,...],[id1,id2,...]...]
make_group_sub(Sort_List,Room_Num,IsReverse,ResultList)->
	case Sort_List of
		[]->ResultList;
		_->
			if
				Room_Num=<length(Sort_List)->
					{List1,List2}=lists:split(Room_Num, Sort_List);
				true->
					List1 = Sort_List,
					List2 = []
			end,
			case IsReverse of
				1-> %需要倒序
					Merge_list = merge_list(lists:reverse(ResultList),List1,[]), %把数组倒过来合并
					Final_ResultList = lists:reverse(Merge_list), %把数组倒回去
					make_group_sub(List2,Room_Num,0,Final_ResultList);
				_-> %不需要倒序
					Final_ResultList = merge_list(ResultList,List1,[]),
					make_group_sub(List2,Room_Num,1,Final_ResultList)
			end
	end.
%% 合并两列表
%%@param List1 每个元素是列表
%%@param List2 每个元素是一种数据
merge_list(List1,List2,Result)->
	case List1 of
		[]->Result;
		[H1|T1]->
			case List2 of
				[]->FinalResult = Result++[H1],T2=[];
				[H2|T2]->
					FinalResult = Result++[H1++[H2]]
			end,
			merge_list(T1,T2,FinalResult)
	end.

%%获取报名成功和失败的列表
%% @param Factionwar_sign_up_dict_list 报名字典
%% @param Result 返回结果 [SuccList,FailList] [List->Id1,Id2...]
get_sign_up_succ_and_fail_faction(Factionwar_sign_up_dict_list,Result)->
	case Factionwar_sign_up_dict_list of
		[]->Result;
		[{K,V}|T]->
			Min_sign_up_member = data_factionwar:get_factionwar_config(min_sign_up_member),
			Max_sign_up_factionwar = data_factionwar:get_factionwar_config(max_sign_up_factionwar),
			[SuccList,FailList] = Result,
			if
				Min_sign_up_member=<length(V)->
					if
						Max_sign_up_factionwar<length(SuccList)-> %%超过最大报名帮派
							Final_SuccList = SuccList,
							Final_FailList = FailList++[K];
						true->
							Final_SuccList = SuccList++[K],
							Final_FailList = FailList
					end;
				true->
					Final_SuccList = SuccList,
					Final_FailList = FailList++[K]
			end,
			get_sign_up_succ_and_fail_faction(T,[Final_SuccList,Final_FailList])
	end.
	
	
	
