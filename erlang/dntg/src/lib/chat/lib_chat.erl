%%%-----------------------------------
%%% @Module  : lib_chat
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.07.22
%%% @Description: 聊天
%%%-----------------------------------
-module(lib_chat).
-export([
	 update_sys_notice_4_houtai/0,
	 update_sys_notice/0,
	 forbid_chat_4_houtai/2,
	 set_lim_right_4_houtai/2,
     update_user_info_4_vip_type/2,
	 release_chat_4_houtai/1,
	 forbid_chat/3,
	 release_chat/2,
	 set_lim_right/2,
	 get_talk_lim/1,
	 be_lim_talk/1,
	 chat_too_frequently/2, 
	 send_sys_msg/2, 
	 send_sys_msg_one/2, 
	 rpc_send_sys_msg_one/2, 
	 rpc_send_msg_one/2,
	 send_TV/4,
	 make_tv/2,
	 record_content/2,
	 is_in_blacklist/2,
	 record_nofriends_chat/2,
	 is_friends/2,
	 is_pay/1,
	 is_chat_forbid/1,
	 forbid_chat_db/4,
	 is_sys_send_goods/3,
	 make_send_tv_list/2,
	 log_forbid_chat/3,      %% 禁言日志
	 chat_rule_3/3,
	 chat_rule_5/2,
	 get_fashionRing/1,
	 get_vip_data/1
	 ]).
-include("unite.hrl").
-include("server.hrl").
-include("chat.hrl").
-include("rela.hrl").

%%系统公告
update_sys_notice_4_houtai() ->
    mod_disperse:call_to_unite(lib_chat,update_sys_notice,[]),
    ok.
    
%%禁言
%%@param UidList [id1,id2,...]
forbid_chat_4_houtai(UidList,Limit_time)->
	mod_disperse:call_to_unite(lib_chat,forbid_chat,[UidList,Limit_time, 1]).

%%设置禁言权限
%%@param UidList [id1,id2,...]
%%@Lim_right 0无权限 1有权限
set_lim_right_4_houtai(UidList, Lim_right) ->
	mod_disperse:call_to_unite(lib_chat,set_lim_right,[UidList,Lim_right]).

%%释放禁言
%%@param UidList [id1,id2,...]
release_chat_4_houtai(UidList)->
    mod_disperse:call_to_unite(lib_chat,release_chat,[UidList, 1]). 

%%禁言
%%@param UidList [id1,id2,...]
%%@param Talk_lim_type 1 gm或指导员禁言 2违反规则自动禁言A  3违反规则自动禁言B  4被举报次数过多禁言
forbid_chat(UidList,Limit_time,Talk_lim_type)->
	TALK_LIMIT_TIME = case Limit_time of
	    0 -> ?TALK_LIMIT_TIME_0;
        1 -> ?TALK_LIMIT_TIME_1;
        2 -> ?TALK_LIMIT_TIME_2;
	    3 -> ?TALK_LIMIT_TIME_3;
        4 -> ?TALK_LIMIT_TIME_4;
        5 -> ?TALK_LIMIT_TIME_5;
        6 -> ?TALK_LIMIT_TIME_6;
		7 -> ?TALK_LIMIT_TIME_7;
		8 -> ?TALK_LIMIT_TIME_8
        end,
	Time = util:unixtime()+TALK_LIMIT_TIME,
	lists:foreach(fun(Uid)-> 
		%%检查目标玩家是否在线
		case mod_chat_agent:lookup(Uid) of
	        [] ->
			log_forbid_chat(Uid, Talk_lim_type, TALK_LIMIT_TIME),
		    forbid_chat_db(Uid,1,Talk_lim_type,Time);
        	[Player] ->
				log_forbid_chat(Uid, Talk_lim_type, TALK_LIMIT_TIME),
				gen_server:cast(Player#ets_unite.pid, {'set_data', [{talk_lim, 1},{talk_lim_time, Time}] }),
				forbid_chat_db(Uid,1,Talk_lim_type,Time)
		end				  
    end, UidList),
	1.

%%释放禁言
%%@param UidList [id1,id2,...]
%%@param Type 解禁类型 1 gm或管理员手动解禁 2自动解禁
release_chat(UidList, Type)->
	Time = util:unixtime(),
	lists:foreach(fun(Uid)->
		%%检查目标玩家是否在线
		case mod_chat_agent:lookup(Uid) of
	        [] ->
				log_realese_chat(Uid, Type),
				mod_daily_dict:set_count(Uid, 7000001, 0),
				mod_daily_dict:set_count(Uid, 7000003, 0),
				mod_chat_forbid:release_chat_forbid(Uid),
		        forbid_chat_db(Uid,0,0,Time);
	        [Player] ->
				log_realese_chat(Uid, Type),
				mod_daily_dict:set_count(Uid, 7000001, 0),
				mod_daily_dict:set_count(Uid, 7000003, 0),
				mod_chat_forbid:release_chat_forbid(Uid),
				gen_server:cast(Player#ets_unite.pid, {'set_data', [{talk_lim, 0},{talk_lim_time, Time}] }),
				forbid_chat_db(Uid,0,0,Time)
		end				  
	end, UidList),
	1.

%%设置禁言权限
set_lim_right(UidList, Lim_right) ->
	lists:foreach(fun(Uid)->
		%%检查目标玩家是否在线
		case mod_chat_agent:lookup(Uid) of
	        [] ->
		        set_lim_right_db(Uid, Lim_right);
	        [Player] ->				
				gen_server:cast(Player#ets_unite.pid, {'set_data', [{talk_lim_right, Lim_right}]}),
				set_lim_right_db(Uid, Lim_right)
		end				  
	end, UidList),
	1.

%%设置禁言
%% @param Id
%% @param Talk_lim
%% @param Talk_lim_type 1 gm或指导员禁言 2违反规则自动禁言A  3违反规则自动禁言B  4被举报次数过多禁言 5世界发言次数限制
%% @param Talk_lim_time
forbid_chat_db(Id,Talk_lim, Talk_lim_type, Talk_lim_time)->	
	db:execute(io_lib:format(?SQL_UPDATE_TALK_LIM, [Talk_lim, Talk_lim_type, Talk_lim_time,Id])),
	ok.

%%获取禁言信息
get_talk_lim(Id) ->
	db:get_row(io_lib:format(?SQL_SELECT_TALK_LIM,[Id])).

%%设置禁言权限
set_lim_right_db(Id, Lim_right) ->
	db:execute(io_lib:format(?SQL_UPDATE_LIM_RIGHT, [Lim_right, Id])),
	ok.

%%被禁言通知
be_lim_talk(Status) ->
	Talk_lim_time = Status#unite_status.talk_lim_time,
	Time = util:unixtime(),
	Release_after = Talk_lim_time - Time, %%release_after秒后释放禁言
	{ok, BinData} = pt_110:write(11042, Release_after),
	lib_unite_send:send_to_sid(Status#unite_status.sid, BinData).

%% 玩家是否被禁言
is_chat_forbid(Id) ->
	case mod_chat_agent:lookup(Id) of
        [] ->
			[Talk_lim, _, _] = get_talk_lim(Id),
			case Talk_lim of
				1 -> true;
				_ -> false 
			end;
        [Player] ->	
			case Player#ets_unite.talk_lim of
				1 -> true;
				_ -> false 
			end
	end.

%%更新玩家好友等级
update_user_info_4_vip_type(Uid,VipType)->
	%%检查目标玩家是否在线
	case mod_chat_agent:lookup(Uid) of
        [] ->
            void;
        [Player] ->
			New_Player = Player#ets_unite{vip=VipType},
			mod_chat_agent:insert(New_Player)
	end.

%%发言过频通知
chat_too_frequently(Id, Sid) ->
    {ok, BinData} = pt_110:write(11010, Id),
    lib_unite_send:send_to_sid(Sid, BinData).

%%发聊天系统信息
send_sys_msg(Sid, Msg) ->
    {ok, BinData} = pt_110:write(11004, Msg),
    lib_unite_send:send_to_scene(Sid, BinData).

%%发送系统信息给某个玩家
send_sys_msg_one(Sid, Msg) when is_tuple(Sid)->
    {ok, BinData} = pt_110:write(11004, Msg),
    lib_unite_send:send_to_sid(Sid, BinData);

send_sys_msg_one(Id, Msg) when is_integer(Id)->
    {ok, BinData} = pt_110:write(11004, Msg),
    lib_unite_send:send_to_uid(Id, BinData).

rpc_send_sys_msg_one(Id, Msg) when is_integer(Id)->
    {ok, BinData} = pt_110:write(11004, Msg),
    mod_disperse:cast_to_unite(lib_unite_send, send_to_uid, [Id, BinData]).

rpc_send_msg_one(Id, BinData) when is_integer(Id)->
    mod_disperse:cast_to_unite(lib_unite_send, send_to_uid, [Id, BinData]).

%% 更新系统公告
update_sys_notice() ->
    Now = util:unixtime(),
    Q = io_lib:format(<<"select `type`,`color`,`content`,`url`,`num`,`span`,`start_time`,`end_time`,`status` from notice where `end_time` > ~p">>, [Now]),
    Result = case db:get_all(Q) of
		 [] ->
		     [];
		 List ->
		     ets:insert(ets_sys_notice, {sys_notice, List}),
		     List
	     end,
    {ok, BinData} = pt_110:write(11050, [Result]),
    lib_unite_send:send_to_all(BinData).

%%发送传闻、电视
%%@param BroadcastRange 广播方式：
%%          {scene,SceneId,CopyId}   场景ID、副本ID
%%          {guild,GuildId}    帮派ID
%%          {realm,Realm}      阵营值(国家)
%%          {team,TeamId}      队伍传闻
%%          {all}              世界传闻(默认传闻)
%%@param IsUniteLine 是否公共线：1是 0不是
%%@param Type 发送类型
%%@param Msg 内容（内含一定规则,由客户端制定）  [param1,param2,...] 
send_TV(BroadcastRange,IsUniteLine,Type,Msg)->
    BinData = make_tv(Type,Msg),	
	case IsUniteLine of
		1->
			case BroadcastRange of
				{scene,SceneId,CopyId} ->lib_unite_send:send_to_scene(SceneId,CopyId,BinData);
				{guild,GuildId} -> lib_unite_send:send_to_guild(GuildId,BinData);
				{realm,Realm} -> lib_unite_send:send_to_realm(Realm,BinData);
				{team,TeamId} -> lib_unite_send:send_to_realm(TeamId,BinData);
				{all} -> lib_unite_send:send_to_all(BinData);
				_-> lib_unite_send:send_to_all(BinData)
			end;
		_->
			case BroadcastRange of
				{scene,SceneId,CopyId} -> mod_disperse:call_to_unite(lib_unite_send, send_to_scene, [SceneId,CopyId,BinData]);
				{guild,GuildId} -> mod_disperse:call_to_unite(lib_unite_send, send_to_guild, [GuildId,BinData]);
				{realm,Realm} -> mod_disperse:call_to_unite(lib_unite_send, send_to_realm, [Realm,BinData]);
				{team,TeamId} -> mod_disperse:call_to_unite(lib_unite_send, send_to_team, [TeamId,BinData]);
				{all}-> mod_disperse:call_to_unite(lib_unite_send, send_to_all, [BinData]);
		_->mod_disperse:call_to_unite(lib_unite_send, send_to_all, [BinData])
			end
	end.
%%制作传闻协议包
make_tv(Type,Msg)->
	MsgList = lists:concat(make_send_tv_list(Msg, [])),
	{ok, BinData} = pt_110:write(11014, [Type,MsgList]),
	BinData.

%% 生成传闻连接字符
make_send_tv_list([], NewList) ->
    NewList;
make_send_tv_list([L | []], NewList) ->
    NewList ++ [change_make_send_type(L)];
make_send_tv_list([L | T], NewList) ->
    make_send_tv_list(T, NewList ++ [change_make_send_type(L)] ++ [","]).

change_make_send_type(Data) when is_binary(Data)->
    binary_to_list(Data);
change_make_send_type(Data) ->
    Data.


%% 给非好友发送私聊次数超过30条自动禁言半小时
record_nofriends_chat(AId, BId) ->
	Reply = is_friends(AId, BId),
	case Reply of
		true -> skip;
		false ->
			Count = mod_daily_dict:get_count(AId, 7000001),
			case Count >?ALLOW_CHAT_NUM_2 of
				true ->					
					forbid_chat([AId], 2, 2);
				false ->
					mod_daily_dict:increment(AId, 7000001)
			end
	end.

%% 记录1分钟内玩家聊天内容
record_content(PS, Content) ->
	Now = util:unixtime(),
	Pre_time =  PS#unite_status.prev_record_time,
	case  (Now - Pre_time) > 1*60 of
		true ->
			New_Player = PS#unite_status{prev_record_time=Now, record_content=[Content]},
			[0, New_Player];
		false ->
			Record_content = PS#unite_status.record_content,
			case lists:member(Content, Record_content) of
				true ->
					Num = count_num(Record_content, Content, 0),
					case Num =<2 of
						true ->
							%% 限制记录数量为10条,控制占用内存量
							case length(Record_content) <10 of
								true -> 
									New_Player = PS#unite_status{record_content= Record_content ++ [Content]};
								false -> New_Player = PS
							end,
							[0, New_Player];
                        false -> [1, PS]			
					end;
				false ->
					case length(Record_content) <10 of
						true -> 					
							New_Player = PS#unite_status{record_content= Record_content ++ [Content]};
						false -> New_Player = PS
					end,
                    [0, New_Player]
			end
	end.

%% 统计聊天内容出现次数
count_num([],  _Content, Num) ->Num;
count_num([H|T], Content, Num) ->	
	case H =:= Content of
		true -> count_num(T, Content, Num+1);
		false -> count_num(T, Content, Num)
	end.

%% 关系是否为黑名单
%% @parma Pid:玩家AId的Pid
is_in_blacklist(AId, BId) ->
	case misc:get_player_process(AId) of
		Pid when is_pid(Pid) ->			
			case misc:is_process_alive(Pid) of 
				true -> gen_server:call(Pid, {'is_in_blacklist', Pid, AId, BId});	
				false -> false
			end;		
		 _ ->
			false
	end.

%% 是否好友
is_friends(AId, BId) ->
	case misc:get_player_process(AId) of
		Pid when is_pid(Pid) ->	
			case misc:is_process_alive(Pid) of 
				true ->
					Reply = gen_server:call(Pid, {'get_rela_by_ABId', Pid, AId, BId}),
					case Reply of
						[] -> false;
						[Rela] ->							
							case Rela#ets_rela.rela of
								1 -> true;
								4 -> true;
								_ -> false
							end
					end;					
				false ->
					false
			end;
		 _ ->
			false
	end.

%% 是否冲过值
is_pay(Uid) ->
	case misc:get_player_process(Uid) of
		Pid when is_pid(Pid) ->			
			case misc:is_process_alive(Pid) of 
				true ->
					gen_server:call(Pid, {'is_pay'});
				false -> false
			end;		
		 _ ->
			false
	end.

%% 禁言日志
log_forbid_chat(Id, Type, Limit_time) ->
	Info = data_chat_forbid_text:get_forbid_type(Type),
	Info2 = io_lib:format(Info, [Limit_time div 60]),
	Is_Admin = data_chat_forbid_text:is_admin_forbid(Type),
	NowTime = util:unixtime(),
	Data = [erlang:integer_to_list(Id), Info2, NowTime, Is_Admin],
	SQL  = io_lib:format(?SQL_LOG_FORBID_CHAT, Data),
	db:execute(SQL).

%% 禁言解除日志
log_realese_chat(Id, Type) ->
	Info = data_chat_forbid_text:get_release_type(Type),
	Is_Admin = data_chat_forbid_text:is_admin_forbid(Type),	
	NowTime = util:unixtime(),
	Data = [erlang:integer_to_list(Id), Info, NowTime, Is_Admin],
	SQL  = io_lib:format(?SQL_LOG_RELEAS_CHAT, Data),
	db:execute(SQL).

private_get_index([], _Target, Index) ->
	Index;
private_get_index([H|T], Target, Index) ->
	case H=:=Target of
		true ->
			private_get_index([], Target, Index);
		false ->
			private_get_index(T, Target, Index+1)
	end.

is_sys_send_goods([], PBin,_Lv) ->
	PBin;
%% 是否发送物品
%% 判断消息内容中是否发送了物品
%% 系统物品消息格式: [特殊处理后的物品Id,物品名,颜色码]
is_sys_send_goods(Data, PBin, Lv) ->
	case is_list(Data) of
		true ->	
			%% 判断是否含'['和']'
			case lists:member(91, Data) andalso lists:member(93, Data) of
				true ->
					Index_91 = private_get_index(Data, 91, 1),
					Index_93 = private_get_index(Data, 93, 1),
					%% 判断'['位于']'前，且它们位置大于1					
					case Index_93>1 andalso Index_91>=1  andalso Index_93>Index_91 of
						true ->
							Pre = lists:nth(Index_93-1, Data),
							%% 判断']'前一个数据是否0-4,即颜色
							case Pre>=48 andalso Pre=<52 of
								true ->
									F = fun(D, Acc0) ->
										case D=:= 44 of
											true -> Acc0+1;
											false -> Acc0
										end
									end,
									%% 判断','数量是否大于等于2
									Count = lists:foldl(F, 0, Data),
									case Count>=2 andalso Index_93-2>0 of
										true ->
											Pre_2 = lists:nth(Index_93-2, Data),
											%% 判断']'前两个数据是否','
											case Pre_2 =:= 44 of
												true ->
													SubList1 = lists:sublist(Data, 1, Index_91-1),
													GoodMsg = lists:sublist(Data, Index_91, Index_93-Index_91+1),
													SubList2 = lists:sublist(Data, Index_93+1, length(Data)),													
													Bin1 = util:filter_text(SubList1, Lv),
													GoodMsg1 = list_to_binary(GoodMsg),
													%% Bin2 = util:filter_text(SubList2, Lv),													
												    %% Len = byte_size(GoodMsg1),
													%% GoodMsgBin = pt:write_string(GoodMsg),													
													AllBin = <<PBin/binary, Bin1/binary, GoodMsg1/binary>>,
													is_sys_send_goods(SubList2, AllBin, Lv);													
												false ->
													DBin = util:filter_text(Data, Lv),
													is_sys_send_goods([], <<PBin/binary, DBin/binary>>, Lv)
											end;
										false -> 
											DBin = util:filter_text(Data, Lv),
											is_sys_send_goods([], <<PBin/binary, DBin/binary>>, Lv)
									end;
								false ->
									DBin = util:filter_text(Data, Lv),
									is_sys_send_goods([], <<PBin/binary, DBin/binary>>, Lv)
							end;
						false ->
							DBin = util:filter_text(Data, Lv),
							is_sys_send_goods([], <<PBin/binary, DBin/binary>>, Lv)
					end;					
				false ->
					DBin = util:filter_text(Data, Lv),
					is_sys_send_goods([], <<PBin/binary, DBin/binary>>, Lv)
			end;			
		false ->
			DBin = util:filter_text(Data, Lv),
			is_sys_send_goods([], <<PBin/binary, DBin/binary>>, Lv)
	end.

%% 获取玩家VIP数据
get_vip_data(PlayerId) ->
	case lib_player:get_player_info(PlayerId, vip) of
		false -> VipType2 = false;
		VipType -> VipType2 = VipType		
	end,
	case lib_player:get_player_info(PlayerId, vip_growth_lv) of
		false -> VipGthv2 = false;
		VipGthv -> VipGthv2 = VipGthv
	end,
	case VipType2=/=false andalso VipGthv2=/=false of
		true -> [VipType2, VipGthv2];
		false -> []
	end.

%% 40级下, 玩家每日最多私聊20个玩家
%% @Id   自己Id
%% @Uid  私聊对方Id
chat_rule_3(Status, Id, Uid)->
	Count = mod_chat_forbid:record_personal_chat(Id, Uid),	
	Now = util:unixtime(),
	case Count>?ALLOW_CHAT_NUM_1 of
		true ->
			Time = Now+?TALK_LIMIT_TIME_2,
			NewStatus = Status#unite_status{talk_lim=1,talk_lim_time=Time},
			lib_chat:forbid_chat_db(Id,1,3,Time),
			lib_chat:log_forbid_chat(Id, 3, ?TALK_LIMIT_TIME_2),
			{ok, NewStatus}; 
		false -> skip
	end.

%% 42级下，每天世界发言次数限制
chat_rule_5(Status, Content)->	
	%% 排除加好友情况 
	case private_check_for_reject(util:make_sure_list(Content), ?CHAT_RULE_5_REJECT, false) of
		true -> skip;
		false ->
			case Status#unite_status.lv<42 andalso lib_chat:is_pay(Status#unite_status.id)=:= false andalso Status#unite_status.gm<1 of
				true ->
					Now = util:unixtime(),
					Id = Status#unite_status.id,
					Count = mod_daily_dict:get_count(Id, 7000003),
					LimitNum = Status#unite_status.lv*3+20,
					case Count >= LimitNum of
						true ->
							Time = Now+?TALK_LIMIT_TIME_2,
							NewStatus = Status#unite_status{talk_lim=1,talk_lim_time=Time},
							lib_chat:forbid_chat_db(Id,1,5,Time),
							lib_chat:log_forbid_chat(Id, 5, ?TALK_LIMIT_TIME_2),
							{ok, NewStatus}; 
						false ->
							mod_daily_dict:increment(Id, 7000003),	
							{ok, Status}
					end;			
				false ->
					{ok, Status}
			end
	end.

private_check_for_reject(_, _, true) ->
	true;
private_check_for_reject(_, [], Flag) ->
	Flag;
private_check_for_reject(Content, [H|T],Flag) ->
	case string:str(Content, H)=:=0 of
		true -> private_check_for_reject(Content, T, Flag);
		false ->  private_check_for_reject(Content, T, true)
	end.


%% 获取玩家V时装戒指
get_fashionRing(PlayerId) ->
	case lib_player:get_player_info(PlayerId, fashion_ring) of
		false -> RashionRing = 0;
		RashionRing -> skip		
	end,
	RashionRing.
