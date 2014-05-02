%%%--------------------------------------
%%% @Module  : pp_chat
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.05.06
%%% @Description:  聊天功能
%%%--------------------------------------
-module(pp_chat).
-export([handle/3]).
-include("common.hrl").
-include("server.hrl").
-include("unite.hrl").
-include("record.hrl").
-include("chat.hrl").
-include("goods.hrl").

-define(HORN_MAX_LENGTH, 100).   %% 小喇叭消息最大长度(截取前100字节,1汉字=3字节,1英文=1字节)
-define(MAX_LENGTH, 500).        %% 小喇叭消息列表最大长度
-define(CHAT_WORLD, 10).         %% 世界频道发言间隔
-define(CHAT_SCENE, 6).          %% 场景频道发言间隔
-define(KF_CHAT_SCENE, 10).      %% 跨服频道发言间隔
-define(CHAT_REALM, 6).          %% 国家频道发言间隔
-define(CHAT_GUILD, 0).          %% 帮派频道发言间隔

%% 聊天类型
-define(TYPE_WORLD,     1).      %% 世界
-define(TYPE_SCENE,     2).      %% 场景
-define(TYPE_REAMLM,    3).      %% 阵营
-define(TYPE_GUILD,     4).      %% 帮派
-define(TYPE_TEAM,      5).      %% 队伍
-define(TYPE_PRIVATE,   6).      %% 私聊
-define(TYPE_CITY_WAR,  7).      %% 城战
-define(TYPE_KF,        8).      %% 跨服
-define(TYPE_INFORM,    9).      %% 举报

-define(FT_Bugle_Call,611301).      %% 飞天号角
-define(CT_Bugle_Call,611302).      %% 冲天号角 
-define(GUILD_Bugle_Call,412002).   %% 帮派传音
-define(XN_Bugle_Call,611306).      %% 新年号角
-define(MAX_Bugle_Call_Size,500).   %% 最大号角队列数

%%世界
handle(11001, UniteStatus, [Data, TkTime, Ticket]) when is_list(Data)->
    #unite_status{
        id    = Id,
        name  = Name,
        realm = Realm,
        sex   = Sex,
        gm    = GM,
        career = Career,
        vip    = Vip,
        lv     = Lv
    } = UniteStatus,

    case check_talk_condition(UniteStatus, ?TYPE_WORLD, TkTime, Ticket) of
        false -> skip;
        true  -> 
            %% 时装戒指
            FashionRing = lib_chat:get_fashionRing(Id),
            %聊天过滤
            if
                GM == 1 -> 
                    DataSend = util:filter_text_gm(Data);
                true ->
                    DataSend = lib_chat:is_sys_send_goods(Data, <<>>, Lv)	                                  
            end,
            Data1             = [Id, Name, Realm, Sex, DataSend, GM, Vip, Career, FashionRing],
            {ok, BinData}     = pt_110:write(11001, Data1),
            [Count, Status1]  = lib_chat:record_content(UniteStatus, Data),				
            %% 是否gm
            case GM of
                1 ->
                    lib_unite_send:send_to_all(BinData);
                _ ->
                    %% 是否多次发送同样内容
                    case Count =:= 0 of
                        true ->
                            if 
                                Lv < 10 ->
                                    lib_unite_send:send_to_scene(UniteStatus#unite_status.scene, UniteStatus#unite_status.copy_id, BinData);
                                %% 30级以下含特定屏蔽词处理
                                Lv < 30 ->
                                    case Data =:= binary_to_list(DataSend) of
                                        true -> lib_unite_send:send_to_all(BinData);
                                        false -> lib_unite_send:send_to_uid(Id, BinData)
                                    end;
                                true ->
                                    lib_unite_send:send_to_all(BinData)
                            end,
                            %% 世界聊天规则
                            lib_chat:chat_rule_5(Status1, Data);
                        false ->
                            %% 50级以下重复内容处理
                            case Lv =< 50 of
                                true  -> lib_unite_send:send_to_uid(Id, BinData);
                                false -> lib_unite_send:send_to_all(BinData)
                            end,
                            %% 世界聊天规则
                            lib_chat:chat_rule_5(Status1, Data)
                    end
            end														                            
    end;


%%私聊
%%_Uid:用户ID
%%_Nick:用户名
%%Data:内容
%%_Uid 和 _Nick 任意一个即可
handle(11002, Status, [Uid, Nick, Data, FaceType, Color, IsMove, XyzMsg, ScenceId, X, Y, TkTime, Ticket])
when is_list(Data)->
    [Id, Sid] = [Status#unite_status.id, Status#unite_status.sid],
    Now = util:unixtime(),
    case util:check_char_encrypt(Id, TkTime, Ticket) andalso Status#unite_status.lv >=10 of
        false ->
            skip;
        true ->			
            case Status#unite_status.talk_lim =:= 1 andalso Now < Status#unite_status.talk_lim_time of
                true ->
	            lib_chat:be_lim_talk(Status);
                false ->
                    case Status#unite_status.talk_lim =:= 1 of
                        true ->
                            % 解除禁言
			    			lib_chat:release_chat([Id], 2);
                        false ->
                            skip
                    end,
					%% 时装戒指
					FashionRing = lib_chat:get_fashionRing(Status#unite_status.id),
                    Data1 = [Id, Status#unite_status.name, Data, Status#unite_status.sex, Status#unite_status.career, FaceType, Color, IsMove, XyzMsg, ScenceId, X, Y, FashionRing],
                    {ok, BinData} = pt_110:write(11002, Data1),
                    {ok, BinData1} = pt_110:write(11011, Uid),
					%% 聊天过滤
                    case Status#unite_status.gm of
                        1 ->
                             DataSend = util:filter_text_gm(Data);
                        _ ->    
							DataSend = lib_chat:is_sys_send_goods(Data, <<>>, Status#unite_status.lv)
                    end,
					%% 30级以下玩家私聊,消息涉及违规内容
					case Status#unite_status.lv<30 andalso  Data =/= binary_to_list(DataSend) andalso Status#unite_status.gm<1 of
						true ->  skip;								
						false -> %% 40级以前,不能与非好友的玩家进行私聊,杜绝小号的骚扰信息(仅限非充值玩家)  							
							case Status#unite_status.lv<40 andalso lib_chat:is_friends(Id, Uid) =:= false
									andalso lib_chat:is_pay(Id)=:= false  andalso Status#unite_status.gm<1 of
								true ->
									skip;
								false ->
									if
										Uid > 0 ->
											case mod_chat_agent:lookup(Uid) of
												[] ->
													lib_unite_send:send_to_sid(Sid, BinData1), ok;
												[R] ->		
													Is_black1 = lib_chat:is_in_blacklist(Uid, Id),
													Is_black2 = lib_chat:is_in_blacklist(Id, Uid),
													case  (Is_black1 orelse Is_black2) andalso Status#unite_status.gm<1 of
														true -> skip;
														false ->  lib_unite_send:send_to_sid(R#ets_unite.sid, BinData)
													end,	
													%% 私聊聊天规则
													case Status#unite_status.lv<42 andalso lib_chat:is_pay(Id)=:= false andalso Status#unite_status.gm<1 of											
														true ->													
															lib_chat:record_nofriends_chat(Id, Uid),
														    lib_chat:chat_rule_3(Status, Id, Uid);
														false -> skip
													end
											end;
										is_list(Nick) ->
											case mod_chat_agent:match(match_name, [util:make_sure_list(Nick)]) of
												[] ->
													lib_unite_send:send_to_sid(Sid, BinData1), ok;
												[R] ->
													Is_black1 = lib_chat:is_in_blacklist(Uid, Id),
													Is_black2 = lib_chat:is_in_blacklist(Id, Uid),
													case  (Is_black1 orelse Is_black2) andalso Status#unite_status.gm<1 of
														true -> skip;
														false ->  lib_unite_send:send_to_sid(R#ets_unite.sid, BinData)
													end,
													%% 私聊聊天规则
													case Status#unite_status.lv<42 andalso lib_chat:is_pay(Id)=:= false andalso Status#unite_status.gm<1 of
														true ->
															lib_chat:record_nofriends_chat(Id, Uid),
															lib_chat:chat_rule_3(Status, Id, Uid);
														false -> skip
													end
											end
							end							
                    end
			 end                    
        end
    end;

%%场景
handle(11003, Status, [Data, TkTime, Ticket]) when is_list(Data)->
    [Id, Sid] = [Status#unite_status.id, Status#unite_status.sid],
    Now = util:unixtime(),
    Time = get_time(?TYPE_SCENE),
    case Now - Time < ?CHAT_SCENE of
        true ->
            lib_chat:chat_too_frequently(Id, Sid);
        _ ->
            case util:check_char_encrypt(Id, TkTime, Ticket) of
                false ->
                    skip;
                true ->
                    case Status#unite_status.talk_lim =:= 1 andalso Now < Status#unite_status.talk_lim_time of
                        true ->
                            lib_chat:be_lim_talk(Status);
                        false ->
                            case Status#unite_status.talk_lim =:= 1 of
                                true ->
									% 解除禁言
						    	    lib_chat:release_chat([Id], 2);
                                false ->
                                    skip
                            end,
                            put_time(?TYPE_SCENE,Now),
                            % 阵营
                            Realm = Status#unite_status.realm,
                            % 性别
                            Sex   = Status#unite_status.sex,
							%% 时装戒指
							FashionRing = lib_chat:get_fashionRing(Status#unite_status.id),
                            %聊天过滤
                            case Status#unite_status.gm of
                                1 ->
                                    DataSend = util:filter_text_gm(Data);
                                _ ->
                                    DataSend = lib_chat:is_sys_send_goods(Data, <<>>, Status#unite_status.lv)
                            end,
                            Data1 = [Status#unite_status.id, Status#unite_status.name, Realm, Sex, DataSend, Status#unite_status.gm,Status#unite_status.vip, Status#unite_status.career, FashionRing],
                            {ok, BinData} = pt_110:write(11003, Data1),
                            lib_unite_send:send_to_scene(Status#unite_status.scene, Status#unite_status.copy_id, BinData)
                    end
            end
    end;

%%帮派聊天
handle(11005, Status, [Data, GuildPosition,Color,ScenceId,X,Y,PositionContent,TkTime,Ticket,FortuneId])
when is_list(Data)->
    [Id, Sid] = [Status#unite_status.id, Status#unite_status.sid],
    Now = util:unixtime(),
    Time = get_time(?TYPE_GUILD),
    case Now - Time < ?CHAT_GUILD of
        true ->
            lib_chat:chat_too_frequently(Id, Sid);
        _ ->
            case util:check_char_encrypt(Id, TkTime, Ticket) of
                false ->
                    skip;
                true ->
                    case (Status#unite_status.talk_lim =:= 1 andalso Now < Status#unite_status.talk_lim_time) of
                        true ->
							lib_chat:be_lim_talk(Status);
                        false ->
                            case Status#unite_status.talk_lim =:= 1 of
                                true ->
									% 解除禁言
									lib_chat:release_chat([Id], 2);
                                false ->
                                    skip
                            end,				
                            put_time(?TYPE_GUILD,Now),
                            % 阵营
                            Realm = Status#unite_status.realm,
                            % 性别
                            Sex   = Status#unite_status.sex,
							%% 时装戒指
							FashionRing = lib_chat:get_fashionRing(Status#unite_status.id),
                            %聊天过滤
                            case Status#unite_status.gm of
                                1 ->
                                    DataSend = util:filter_text_gm(Data);
                                _ ->
                                    DataSend = lib_chat:is_sys_send_goods(Data, <<>>, Status#unite_status.lv)								
                            end,
                            Data1 = [Status#unite_status.id, Status#unite_status.name, Realm, Sex, DataSend, Status#unite_status.gm,Status#unite_status.vip, 
									 Status#unite_status.career, GuildPosition,Color,ScenceId,X,Y,PositionContent,FortuneId, FashionRing],
                            {ok, BinData} = pt_110:write(11005, Data1),
                            lib_unite_send:send_to_guild(Status#unite_status.guild_id, BinData)                          
                    end
            end
    end;

%%队伍
handle(11006, Status, [Data, TeamId, TkTime, Ticket])
when is_list(Data)->
    [Id, _Sid] = [Status#unite_status.id, Status#unite_status.sid],
    Now = util:unixtime(),
    case util:check_char_encrypt(Id, TkTime, Ticket) of
        false ->
            skip;
        true ->
            case (Status#unite_status.talk_lim =:= 1 andalso Now < Status#unite_status.talk_lim_time) of
                true ->
		   			 lib_chat:be_lim_talk(Status);
                false ->
                    case Status#unite_status.talk_lim =:= 1 of
                        true ->
							% 解除禁言
							lib_chat:release_chat([Id], 2);
                        false ->
                            skip
                    end,
                    %% 队伍校正
                    case TeamId =:= Status#unite_status.team_id of
                        true ->  
							Status1 = Status;
                        false ->
							%% 获取队长ID.
							TeamPid = lib_player:get_player_info(Id, pid_team),
							TeamId2 = lib_team:get_leaderid(TeamPid),
							Status1 = Status#unite_status{team_id = TeamId2},
							case mod_chat_agent:lookup(Status#unite_status.id) of
								[] -> skip;
								[Player] -> mod_chat_agent:insert(Player#ets_unite{team_id = TeamId2})
							end					
                    end,
                    % 阵营
                    Realm = Status1#unite_status.realm,
                    % 性别
                    Sex   = Status1#unite_status.sex,
					%% 时装戒指
					FashionRing = lib_chat:get_fashionRing(Status#unite_status.id),
                    %聊天过滤
                    case Status1#unite_status.gm of
                        1 ->
                            DataSend = util:filter_text_gm(Data);
                        _ ->
							DataSend = lib_chat:is_sys_send_goods(Data, <<>>, Status#unite_status.lv)
                    end,
                    Data1 = [Status1#unite_status.id, Status1#unite_status.name, Realm, Sex, DataSend, Status1#unite_status.gm,Status1#unite_status.vip, Status1#unite_status.career, FashionRing],
                    {ok, BinData} = pt_110:write(11006, Data1),
                    lib_unite_send:send_to_team(TeamId, BinData),
					{ok, Status1}
            end
    end;

%%阵营
handle(11008, Status, [Data, TkTime, Ticket])
when is_list(Data)->
    [Id, Sid] = [Status#unite_status.id, Status#unite_status.sid],
    Now = util:unixtime(),
    Time = get_time(?TYPE_REAMLM),
    case Now - Time < ?CHAT_REALM of
        true ->
            lib_chat:chat_too_frequently(Id, Sid);
        _ ->
            case util:check_char_encrypt(Id, TkTime, Ticket) of
                false ->
                    skip;
                true ->
                    case Status#unite_status.talk_lim =:= 1 andalso Now < Status#unite_status.talk_lim_time of
                        true ->
							lib_chat:be_lim_talk(Status);
                        false ->
                            case Status#unite_status.talk_lim =:= 1 of
                                true ->
									% 解除禁言
									lib_chat:release_chat([Id], 2);
                                false ->
                                    skip
                            end,
                            put_time(?TYPE_REAMLM,Now),
                            % 阵营
                            Realm = Status#unite_status.realm,
                            % 性别
                            Sex   = Status#unite_status.sex,
							%% 时装戒指
							FashionRing = lib_chat:get_fashionRing(Status#unite_status.id),
                            %聊天过滤
                            case Status#unite_status.gm of
                                1 ->
                                    DataSend = util:filter_text_gm(Data);
                                _ ->
                                    DataSend = lib_chat:is_sys_send_goods(Data, <<>>, Status#unite_status.lv)
                            end,
							
							%% 30级以下不合法信息处理
							Is_legal = 						
							case Status#unite_status.lv >=30 of
								true -> 0;									
								false -> 
									case Data =:= binary_to_list(DataSend)  of
										true -> 0;
										false -> 1
									end
							end, 	
							Data1 = [Status#unite_status.id, Status#unite_status.name, Realm, Sex, DataSend, Status#unite_status.gm,Status#unite_status.vip, Status#unite_status.career, FashionRing],
							{ok, BinData} = pt_110:write(11008, Data1),
							case  Is_legal of
								0 -> lib_unite_send:send_to_realm(Realm, BinData);
								1 -> lib_unite_send:send_to_uid(Status#unite_status.id, BinData)
							end
                    end
            end
    end;



%%聊天输入状态
%%_Uid:用户ID
%%_Nick:用户名
%%_InputState:用户输入状态
%%_Uid 和 _Nick 任意一个即可
handle(11012, Status, [Uid, InputState]) ->
    [Id, Sid] = [Status#unite_status.id, Status#unite_status.sid],
    Now = util:unixtime(),
    case mod_chat_agent:lookup(Id) of
        [] ->
            skip;
        [Player] ->			
            case Player#ets_unite.talk_lim =:= 1 andalso Now < Player#ets_unite.talk_lim_time of
                true ->					
	            	lib_chat:be_lim_talk(Status);
                false ->
                    case Player#ets_unite.talk_lim =:= 1 of
                        true ->
                             % 解除禁言
			   				 lib_chat:release_chat([Id], 2);
                        false ->
                            skip
                    end,					
                    Data1 = [Id, InputState],
                    {ok, BinData} = pt_110:write(11012, Data1),
                    {ok, BinData1} = pt_110:write(11011, Uid),					
                    if
                        Uid > 0 ->
                            case mod_chat_agent:lookup(Uid) of
                                [] ->
                                    lib_unite_send:send_to_sid(Sid, BinData1), ok;
                                [R] ->
                                    lib_unite_send:send_to_sid(R#ets_unite.sid, BinData)
                            end;
                        true ->
							skip
                    end
	     end
    end;



%%取私聊所需信息
handle(11013, Status, UId)->
    case mod_chat_agent:lookup(UId) of
        [] ->
            OnlineFlag = 0,
            Id = UId,
            Name = "",
            Sex = 0,
            Career = 0,
            Vip = 0,
            Image = 0,
            Level = 0,
            GuildName = "",
            Realm = 0,
            GuildId = 0,
			Ringfashion = 0;
        [Player] ->
            OnlineFlag = 1,
            Id = Player#ets_unite.id,
            Name = Player#ets_unite.name,
            Sex = Player#ets_unite.sex,
            Career = Player#ets_unite.career,
            Vip = Player#ets_unite.vip,
            Image = Player#ets_unite.image,
            Level = Player#ets_unite.lv,
            GuildName = Player#ets_unite.guild_name,
            Realm = Player#ets_unite.realm,
            GuildId = Player#ets_unite.guild_id,
			Ringfashion = lib_chat:get_fashionRing(Player#ets_unite.id)
    end,
    Data1 = [OnlineFlag, Id, Name, Sex, Career, Vip, Image, Level, GuildName, Realm, GuildId, Ringfashion],
	{ok, BinData} = pt_110:write(11013, Data1),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%%传闻、电视测试
handle(11014, _Status, [Type,Msg]) ->
	{ok, BinData} = pt_110:write(11014, [Type,Msg]),
    lib_unite_send:send_to_all(BinData);

%%发送坐标
handle(11016, Status, [Channel, Content, SceneId, X, Y, Content2]) ->
    [Id, _Sid] = [Status#unite_status.id, Status#unite_status.sid],
    Now = util:unixtime(),
    case mod_chat_agent:lookup(Id) of
        [] ->
            skip;
        [Player] ->			
            case Player#ets_unite.talk_lim =:= 1 andalso Now < Player#ets_unite.talk_lim_time of
                true ->					
	            	lib_chat:be_lim_talk(Status);
                false ->
                    case Player#ets_unite.talk_lim =:= 1 of
                        true ->
                             % 解除禁言
			   				 lib_chat:release_chat([Id], 2);
                        false ->
                            skip
                    end,				
					Name = Player#ets_unite.name,
					Realm = Player#ets_unite.realm,
					Sex = Player#ets_unite.sex,
					Gm = Player#ets_unite.gm,					
					Vip = Player#ets_unite.vip,
					Career = Player#ets_unite.career,
					%% 时装戒指
					FashionRing = lib_chat:get_fashionRing(Status#unite_status.id),

					Data = [Id, Name, Realm, Sex, Gm, Vip, Career, Content, SceneId, X, Y, Channel, Content2, FashionRing],
					{ok, BinData} = pt_110:write(11016, Data),
					case Channel of		%%0世界 1场景 2阵营 3帮派 4队伍
						0 -> lib_unite_send:send_to_all(BinData);
						1 -> lib_unite_send:send_to_scene(Player#ets_unite.scene, Player#ets_unite.copy_id, BinData);
						2 -> lib_unite_send:send_to_realm(Player#ets_unite.realm, BinData);
						3 -> lib_unite_send:send_to_guild(Player#ets_unite.guild_id, BinData);
						4 -> lib_unite_send:send_to_team(Player#ets_unite.team_id, BinData);
					    _ -> skip
					end					
			end
	end;
	
%% 向客户端广播喇叭消息
handle(11031, Status, [Color,Content,Type,Channel,Channel_id]) ->
    [Id, _Sid] = [Status#unite_status.id, Status#unite_status.sid],
    Now = util:unixtime(),
    case mod_chat_agent:lookup(Id) of
        [] ->
            skip;
        [Player] ->
		case  Player#ets_unite.lv >= 30 of
            true ->
                case Player#ets_unite.talk_lim =:= 1 andalso Now < Player#ets_unite.talk_lim_time of
                   true ->
	              	 lib_chat:be_lim_talk(Status);
                  	 false ->
                   	 case Player#ets_unite.talk_lim =:= 1 of
                        true ->
                            % 解除禁言
 						    lib_chat:release_chat([Id], 2);
                        false ->
                            skip
                  	  end,
						Size = mod_chat_bugle_call:get_list_size(),
                        if
							?MAX_Bugle_Call_Size=<Size-> %排队人数过多
								Result = 4;
							true->
								case Type of
									0-> %飞天号角  扣除材料
									VipData = lib_chat:get_vip_data(Status#unite_status.id),									
									case VipData =/= [] of
										true -> [VipType, VipGthv]=VipData;
										false -> VipType=0, VipGthv=0
									end,
									FreeNum = data_vip_new:get_ft_bugle_num(VipGthv),
									UsedCount = mod_daily_dict:get_count(Status#unite_status.id, 7000002),
									case VipType=:=3 andalso UsedCount<FreeNum of	
										true ->
											mod_daily_dict:increment(Status#unite_status.id, 7000002),
											Result = 1;
										false ->
											case lib_meridian:delete_goods_by_list(Status#unite_status.id,[[?FT_Bugle_Call,1]]) of
												false->Result = 2;
												true->											
													%% 材料消费日志
													log:log_goods_use(Status#unite_status.id, ?FT_Bugle_Call, 1),
													Result = 1
											end
									end;									
									1-> %冲天号角 扣除材料
									case lib_meridian:delete_goods_by_list(Status#unite_status.id,[[?CT_Bugle_Call,1]]) of
										false->Result = 2;
										true->
											log:log_goods_use(Status#unite_status.id, ?CT_Bugle_Call, 1),
											Result = 1
									end;
									5-> %新年号角 扣除材料
									case lib_meridian:delete_goods_by_list(Status#unite_status.id,[[?XN_Bugle_Call,1]]) of
										false->Result = 2;
										true->
											log:log_goods_use(Status#unite_status.id, ?XN_Bugle_Call, 1),
											Result = 1
									end;
									4 -> %仙宴传音
										case Channel =:= 3 of
											true ->
												GuildId = Status#unite_status.guild_id,
												PartyName = "GuildParty" ++ integer_to_list(GuildId),
												case misc:whereis_name(global, PartyName) of
													undefined ->
														Result = 0;
													Pid when is_pid(Pid) ->
														{MoodAdd, _NumLimit, _EfType} = data_guild:get_party_good_ef(?GUILD_Bugle_Call),
													    MoodNow = lib_guild_scene:get_part_mood([GuildId]),															
														Name = Status#unite_status.name,															
														case lib_meridian:delete_goods_by_list(Status#unite_status.id,[[?GUILD_Bugle_Call,1]]) of
															false->Result = 2;
															true->
																log:log_goods_use(Status#unite_status.id, ?GUILD_Bugle_Call, 1),
																%% 仙宴期间使用传音，气氛值未满情况增加气氛值
																if 
																	MoodNow > 1000 ->
																		lib_guild_scene:add_part_mood([7, 0, 0, Name, GuildId, 0, ?GUILD_Bugle_Call]);
																	true ->
																		lib_guild_scene:add_part_mood([1, 0, 0, Name, GuildId, MoodAdd, ?GUILD_Bugle_Call])
																end,
																Result = 1
														end
												end;
											false ->
												Result = 0
										end;
									_->
										Result = 0
								end
						end,
					case Result of
						1-> 
							%% 过滤敏感字
                    		case Status#unite_status.gm of
                        		1 ->
                            		DataSend = util:filter_text_gm(Content);
                        		_ ->
									DataSend = lib_chat:is_sys_send_goods(Content, <<>>, Status#unite_status.lv)
							end,					
							mod_chat_bugle_call:put_element(#call{
									id=Status#unite_status.id, 			%% 角色ID
									nickname=Status#unite_status.name,	%% 角色名
									realm=Status#unite_status.realm,	%% 阵营
									sex=Status#unite_status.sex,		%% 性别
									color=Color,						%% 颜色
									content=DataSend,					%% 内容
									gm=Status#unite_status.gm,			%% GM
									vip=Status#unite_status.vip,		%% VIP
									work=Status#unite_status.career,	%% 职业
									type=Type,							%% 喇叭类型  1飞天号角 2冲天号角 3生日号角 4新婚号角
									image=Status#unite_status.image,	%% 头像ID 
									channel=Channel,                    %% 发送频道 0世界 1场景 2阵营 3帮派 4队伍 
									channel_id = Channel_id,			%% Id 如场景Id、帮派Id
									ringfashion=lib_chat:get_fashionRing(Status#unite_status.id) %%戒指时装
									});
						_->void
					end,					

					{ok, BinData} = pt_110:write(11031, [Result,Size,Type]),
    				lib_unite_send:send_to_sid(Status#unite_status.sid, BinData)
        	    end;
		  false ->
                 {ok, BinData} = pt_110:write(11031, [7,0,0]),
    			 lib_unite_send:send_to_sid(Status#unite_status.sid, BinData)
		  end
    end;


handle(11033, Status, []) ->
	Size = mod_chat_bugle_call:get_list_size(),
	{ok, BinData} = pt_110:write(11033, [1,Size]),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%%禁言
handle(11040, Status, [Uid,Limit_time]) ->
	case Status#unite_status.gm of
		1->%是GM					
			Result = lib_chat:forbid_chat([Uid],Limit_time,1),
			mod_chat_bugle_call:remove_msg(Uid);
		2->%新手指导员					
			case Status#unite_status.talk_lim_right of
				1 ->
					Result = lib_chat:forbid_chat([Uid],Limit_time,1),
					mod_chat_bugle_call:remove_msg(Uid);
				_ -> Result = 2
			end;
		_->%非GM
			Result = 0
	end,
	{ok, BinData} = pt_110:write(11040, [Result]),
	lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%%解除禁言
handle(11041, Status, [Uid]) ->
	case Status#unite_status.gm of
		1->%是GM
			Result = lib_chat:release_chat([Uid], 1);
		2->%新手指导员
			case Status#unite_status.talk_lim_right of
				1 ->
					Result = lib_chat:release_chat([Uid], 1);
				_ -> Result = 2
			end;
		_->%非GM
			Result = 0
	end,
	{ok, BinData} = pt_110:write(11041, [Result]),
	lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);


%%获取禁言信息
handle(11043, Status, [Uid]) ->
	case mod_chat_agent:lookup(Status#unite_status.id) of
        [] ->
            ok;
        [_Player] ->
		    [Talk_lim, _Talk_lim_time, _Talk_lim_right] = lib_chat:get_talk_lim(Uid),
		    {ok, BinData} = pt_110:write(11043, Talk_lim),
		    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData)
	end;


%% 聊天举报
handle(11044, Status, [TargetId]) ->
	Now = util:unixtime(),
    Time = get_time(?TYPE_INFORM),
	case Now - Time < ?CHAT_REALM of
        true ->
            skip;
		false ->
			case mod_chat_agent:lookup(Status#unite_status.id) of
				[] ->
					ok;
				[_Player] ->
					put_time(?TYPE_INFORM,Time),
					Is_friends = lib_chat:is_friends(Status#unite_status.id, TargetId),
					case Is_friends of
						true -> ReturnCode = 2;					
						false ->
							case lib_chat:is_pay(TargetId) of
								true -> 									
									ReturnCode = 1;	
								false ->
									Count = mod_chat_forbid:inform_chat(Status#unite_status.id, TargetId),
									case Count>?ALLOW_INFORM_NUM andalso lib_chat:is_chat_forbid(TargetId) =/=true of
										true -> lib_chat:forbid_chat([TargetId],2,4); 
										false -> skip
									end,
									ReturnCode = 1
							end
					end,					
					{ok, BinData} = pt_110:write(11044, [ReturnCode]),
					lib_unite_send:send_to_sid(Status#unite_status.sid, BinData)
			end
	end;	

handle(11050, Status, []) ->
    Now = util:unixtime(),
    case ets:lookup(ets_sys_notice, sys_notice) of
	[] ->
	    Q = io_lib:format(<<"select `type`,`color`,`content`,`url`,`num`,`span`,`start_time`,`end_time`,`status` from notice where `end_time` > ~p">>, [Now]),
	    case db:get_all(Q) of
		[] ->
		    Result = [];
		List ->
		    Result = List
	    end,
	    ets:insert(ets_sys_notice, {sys_notice, Result});
	[{sys_notice, List}] ->
	    Result = List
    end,
    {ok, BinData} = pt_110:write(11050, [Result]),
    lib_unite_send:send_to_one(Status#unite_status.id, BinData);


%% 发送组队招募信息
handle(11020, Status, [Lv,Energy,Msg,Type]) ->
	case lib_player:get_player_info(Status#unite_status.id) of
		PlayerStatus when is_record(PlayerStatus, player_status) ->
			%% 时装戒指
			FashionRing = lib_chat:get_fashionRing(Status#unite_status.id),
			Data = [Status#unite_status.id, 
					Status#unite_status.name, 
					Status#unite_status.realm, 
					Status#unite_status.sex, 
					Msg, 
					PlayerStatus#player_status.gm,
					Status#unite_status.vip, 
					Status#unite_status.career,
					Status#unite_status.image,
					Lv,
					Energy,
					Status#unite_status.lv, 
					Type,
					FashionRing],
			{ok, BinData} = pt_110:write(11020, Data),
			case Type of	%% 招募消息发送范围 0世界 1场景 2阵营 3帮派
				0 -> lib_unite_send:send_to_all(BinData);
				1 -> lib_unite_send:send_to_scene(Status#unite_status.scene, 
												  Status#unite_status.copy_id, 
												  BinData);
				2 -> lib_unite_send:send_to_realm(Status#unite_status.realm, BinData);
				3 -> lib_unite_send:send_to_guild(Status#unite_status.guild_id, BinData);
				_ -> skip
			end;
		_Other ->
			skip
	end;

%%进入聊天服务器后的心跳包
handle(11202, Status, _) when is_record(Status, unite_status) ->
    Time = util:longunixtime(),
    T = case get("pp_base_heartbeat_last_time") of
        undefined->
            0;
        _T ->
            _T
    end,
    put("pp_base_heartbeat_last_time", Time),
    case Time - T < 4800 of
        true ->
            {ok, BinData} = pt_590:write(59004, 4),
            lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
            mod_login:logout(Status#unite_status.pid);
        false ->
            skip
    end,
    {ok, BinData2} = pt_112:write(11202, []),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData2),
    ok;

%%[跨服]--场景
%%场景
handle(11062, Status, [Data, TkTime, Ticket, Platform, ServerID]) 
when is_list(Data)->
    [Id, Sid] = [Status#unite_status.id, Status#unite_status.sid],
    Now = util:unixtime(),
    Time = get_time(?TYPE_KF),
	IS_clScene= lib_scene:is_clusters_scene(Status#unite_status.scene),
	case IS_clScene of
		true ->
			case Now - Time < ?KF_CHAT_SCENE of
				true ->
					lib_chat:chat_too_frequently(Id, Sid);
				_ ->
					case util:check_char_encrypt(Id, TkTime, Ticket) of
						false ->
							skip;
						true ->
							case Status#unite_status.talk_lim =:= 1 andalso Now < Status#unite_status.talk_lim_time of
								true ->
									lib_chat:be_lim_talk(Status);
								false ->
									case Status#unite_status.talk_lim =:= 1 of
										true ->
											% 解除禁言
											lib_chat:release_chat([Id], 2);
										false ->
											skip
									end,
									put_time(?TYPE_KF, Now),
									% 阵营
									Realm = Status#unite_status.realm,
									% 性别
									Sex   = Status#unite_status.sex,
									%% 时装戒指
									FashionRing = lib_chat:get_fashionRing(Status#unite_status.id),
									%聊天过滤
									case Status#unite_status.gm of
										1 ->
											DataSend = util:filter_text_gm(Data);
										_ ->
											DataSend = lib_chat:is_sys_send_goods(Data, <<>>, Status#unite_status.lv)
									end,
									Data1 = [Status#unite_status.id, Status#unite_status.name, Realm, Sex, DataSend, Status#unite_status.gm,Status#unite_status.vip, Status#unite_status.career, Platform, ServerID, FashionRing],
									{ok, BinData} = pt_110:write(11062, Data1),
									lib_clusters_center:send_to_scene(Status#unite_status.scene, BinData)
							end
					end
			end;
		false -> skip
	end;

%%攻城战聊天
handle(11070, Status, [Data, TkTime, Ticket]) when is_list(Data)->
    [Id, Sid] = [Status#unite_status.id, Status#unite_status.sid],
    Now = util:unixtime(),
    Time = get_time(?TYPE_CITY_WAR),
    case Now - Time < ?CHAT_SCENE of
        true ->
            lib_chat:chat_too_frequently(Id, Sid);
        _ ->
            case util:check_char_encrypt(Id, TkTime, Ticket) of
                false ->
                    skip;
                true ->
                    case Status#unite_status.talk_lim =:= 1 andalso Now < Status#unite_status.talk_lim_time of
                        true ->
   		            lib_chat:be_lim_talk(Status);
                        false ->
                            case Status#unite_status.talk_lim =:= 1 of
                                true ->
									% 解除禁言
						    	    lib_chat:release_chat([Id], 2);
                                false ->
                                    skip
                            end,
                            put_time(?TYPE_CITY_WAR, Now),
                            % 阵营
                            Realm = Status#unite_status.realm,
                            % 性别
                            Sex   = Status#unite_status.sex,
							%% 时装戒指
							FashionRing = lib_chat:get_fashionRing(Status#unite_status.id),
                            %聊天过滤
                            if
                                Status#unite_status.gm == 1 -> 
                                    DataSend = util:filter_text_gm(Data);
                                true ->
                                    DataSend = lib_chat:is_sys_send_goods(Data, <<>>, Status#unite_status.lv)
                            end,
                            Data1 = [Status#unite_status.id, Status#unite_status.name, Realm, Sex, DataSend, Status#unite_status.gm,Status#unite_status.vip, Status#unite_status.career, Status#unite_status.group,FashionRing],
                            {ok, BinData} = pt_110:write(11070, Data1),
                            lib_unite_send:send_to_scene(Status#unite_status.scene, Status#unite_status.copy_id, BinData)
                    end
            end
    end;

%% VIP免费号角剩余数量
handle(11071, PlayerStatus, _) ->
    StatusVip = PlayerStatus#player_status.vip,
    GrowthLv = StatusVip#status_vip.growth_lv,
    FreeNum = data_vip_new:get_ft_bugle_num(GrowthLv),
    UsedCount = mod_daily_dict:get_count(PlayerStatus#player_status.id, 7000002),
    _RestNum = FreeNum - UsedCount,
    RestNum = case _RestNum > 0 of
        true -> _RestNum;
        false -> 0
    end,
    %io:format("RestNum:~p~n", [RestNum]),
    {ok, BinData} = pt_110:write(11071, [RestNum]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%% 发送语音聊天
handle(11080, UniteStatus, [MsgType, ReceiveId, VoiceMsgTime, TkTime, Ticket, DataSend, ClientAutoId]) -> 
       #unite_status{
        id    = Id,
        name  = Name,
        realm = Realm,
        sex   = Sex,
        gm    = GM,
        career = Career,
        vip    = Vip
    } = UniteStatus,

    case check_talk_condition(UniteStatus, MsgType, TkTime, Ticket) of
        false -> skip;
        true  -> 
             %TmpAutoId = case get(process_dict_auto_voice_id) of
             %    undefined -> mod_daily:get_count(UniteStatus#unite_status.dailypid, UniteStatus#unite_status.id, 700201);
             %    AutoId    -> AutoId
             %end,
             %NewAutoId = case TmpAutoId >= 99 of
             %    true  -> 1;
             %    false -> TmpAutoId + 1
             %end,
             %SaveAutoId = Id*100 + NewAutoId,
             %put(process_dict_auto_voice_id, NewAutoId),
             Data  = [ClientAutoId, Id, Name, Realm, Sex, GM, Vip, Career, MsgType, ReceiveId, VoiceMsgTime, TkTime, Ticket],
             mod_chat_voice:send_voice(Id, ClientAutoId, DataSend),
             {ok, BinData} = pt_110:write(11080, Data),
             send_msg(MsgType, UniteStatus, ReceiveId, BinData),
             %mod_daily:set_count(UniteStatus#unite_status.dailypid, UniteStatus#unite_status.id, 700201, NewAutoId),
             ok
    end;

%% 获取语音内容
handle(11081, UniteStatus, [ClientAutoId, TkTime, Ticket]) -> 
    #unite_status{id=Id, sid=Sid} = UniteStatus,
    case util:check_char_encrypt(Id, TkTime, Ticket) of
        false ->
            skip;
        true ->
            mod_chat_voice:get_voice_data(Id, ClientAutoId, Sid, TkTime, Ticket)
    end;


%% 发送图片
handle(11082, UniteStatus, [MsgType, ReceiveId, IsEnd, TkTime, Ticket, TinyPicture, RealPicture]) -> 
       #unite_status{
        id    = Id,
        name  = Name,
        realm = Realm,
        sex   = Sex,
        gm    = GM,
        career = Career,
        vip    = Vip,
        sid    = Sid
    } = UniteStatus,
    
    case IsEnd of
        0 -> %% 图片还没有传送完毕, 先存储一部分到玩家进程，等待下一部分
            case get(process_dict_picture_data) of
                undefined -> 
                    put(process_dict_picture_data, {TinyPicture, RealPicture});
                {PreTinyPicture, PreRealPicture} -> 
                    NewData = {list_to_binary([PreTinyPicture, TinyPicture]), list_to_binary([PreRealPicture, RealPicture])},
                    put(process_dict_picture_data, NewData)
            end,
            %% 告诉客户端图片分部传送成功,可以传下一分部了
            {ok, BinData} = pt_110:write(11084, 1),
            lib_server_send:send_to_sid(Sid, BinData);
        1 ->  %% 图片传送完毕
             case get(process_dict_picture_data) of
                 undefined -> 
                     FinTinyPicture = TinyPicture,
                     FinRealPicture = RealPicture;
                 {PreTinyPicture, PreRealPicture} -> 
                     FinTinyPicture = list_to_binary([PreTinyPicture, TinyPicture]), 
                     FinRealPicture = list_to_binary([PreRealPicture, RealPicture])
             end,

             erase(process_dict_picture_data),

             case check_talk_condition(UniteStatus, MsgType, TkTime, Ticket) of
                 false -> skip;
                 true  -> 
                     TmpAutoId = case get(process_dict_auto_picture_id) of
                         undefined -> mod_daily:get_count(UniteStatus#unite_status.dailypid, UniteStatus#unite_status.id, 700202);
                         AutoId    -> AutoId
                     end,
                     NewAutoId = case TmpAutoId >= 99 of
                         true  -> 1;
                         false -> TmpAutoId + 1
                     end,
                     SaveAutoId = Id*100 + NewAutoId,
                     put(process_dict_auto_picture_id, NewAutoId),
                     Data  = [SaveAutoId, Id, Name, Realm, Sex, GM, Vip, Career, MsgType, ReceiveId, FinTinyPicture, TkTime, Ticket],
                     mod_chat_voice:send_picture(SaveAutoId, FinRealPicture),
                     {ok, BinData} = pt_110:write(11082, Data),
                     send_msg(MsgType, UniteStatus, ReceiveId, BinData),
                     mod_daily:set_count(UniteStatus#unite_status.dailypid, UniteStatus#unite_status.id, 700202, NewAutoId),
                     ok
             end
     end;

%% 获取图片内容
handle(11083, UniteStatus, [AutoId, TkTime, Ticket]) -> 
    #unite_status{id=Id, sid=Sid} = UniteStatus,
    case util:check_char_encrypt(Id, TkTime, Ticket) of
        false ->
            skip;
        true ->
            mod_chat_voice:get_picture_data(AutoId, Sid, TkTime, Ticket)
    end;

%% 保存语音文字内容
handle(11085, UniteStatus, [ClientAutoId, VoiceTextData]) -> 
    #unite_status{id=Id, sid=Sid} = UniteStatus,
    mod_chat_voice:send_voice_text(Id, ClientAutoId, Sid, VoiceTextData),
    ok;


%% 获取语音文字内容
handle(11086, UniteStatus, [ClientAutoId, PlayerId]) -> 
    #unite_status{id=_Id, sid=Sid} = UniteStatus,
    mod_chat_voice:get_voice_text_data(PlayerId, ClientAutoId, Sid),
    ok;

    
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_chat no match", []),
    {error, "pp_chat no match"}.

%% 根据不同的聊天类型发送不同的消息
send_msg(MsgType, UniteStatus, ReceiveId, BinData) -> 
    #unite_status{id = Id, gm = GM, lv = Lv, scene = Scene, copy_id = CopyId,
                  guild_id = GuildId, team_id=TeamId, realm = Realm, sid=Sid
    } = UniteStatus,
    case MsgType of
        ?TYPE_WORLD  -> lib_unite_send:send_to_all(BinData);
        ?TYPE_SCENE  -> lib_unite_send:send_to_scene(Scene, CopyId, BinData);
        ?TYPE_REAMLM -> lib_unite_send:send_to_realm(Realm, BinData);
        ?TYPE_GUILD  -> lib_unite_send:send_to_guild(GuildId, BinData); 
        ?TYPE_TEAM   -> lib_unite_send:send_to_team(TeamId, BinData);
        ?TYPE_PRIVATE -> 
            case mod_chat_agent:lookup(ReceiveId) of
                [] ->
                    ok;
                [R] ->
                    Is_black1 = lib_chat:is_in_blacklist(ReceiveId, Id),
                    Is_black2 = lib_chat:is_in_blacklist(Id, ReceiveId),
                    case  (Is_black1 orelse Is_black2) andalso GM < 1 of
                        true  -> skip;
                        false -> lib_unite_send:send_to_sid(R#ets_unite.sid, BinData)
                    end,
                    %% 私聊聊天规则
                    case Lv < 42 andalso lib_chat:is_pay(Id)=:= false andalso GM < 1 of											
                        true ->				
                            lib_chat:record_nofriends_chat(Id, ReceiveId),
                            lib_chat:chat_rule_3(UniteStatus, Id, ReceiveId);
                        false -> skip
                    end
            end;
        _ -> lib_unite_send:send_to_sid(Sid, BinData)
    end.

%%获取上次发言时间
get_time(Channel) -> 
    case get(Channel) of
        undefined ->
            0;
        Time ->
            Time
    end.

%% 写入当前发言时间
put_time(Channel, Time) -> put(Channel, Time).

%% 获取不同类型的cd时间
get_cd(Channel) -> 
    case Channel of
        ?TYPE_WORLD  -> ?CHAT_WORLD;
        ?TYPE_SCENE  -> ?CHAT_SCENE;
        ?TYPE_REAMLM -> ?CHAT_REALM;
        ?TYPE_GUILD  -> ?CHAT_GUILD;
        _            -> 1
    end.

%% 检查是否能聊天
check_talk_condition(UniteStatus, MsgType, TkTime, Ticket) -> 
    #unite_status{
        id = Id,
        sid = Sid,
        talk_lim = TalkLim,
        talk_lim_time = TalkLimTime
    } = UniteStatus,
    Now = util:unixtime(),
    Time = get_time(MsgType),
    CD   = get_cd(MsgType),
    case Now - Time < CD of
        true  ->  
            lib_chat:chat_too_frequently(Id, Sid),
            false;
        false -> 
            case util:check_char_encrypt(Id, TkTime, Ticket) of
                false -> false;
                true  -> 
                    case TalkLim == 1 andalso Now < TalkLimTime of
                        true  ->					
                            lib_chat:be_lim_talk(UniteStatus),
                            false;
                        false ->
                            case TalkLim == 1 of
                                true  ->
                                    % 解除禁言
                                    lib_chat:release_chat([Id], 2);
                                false ->
                                    skip
                            end,
                            put_time(MsgType, Now),
                            true
                    end
            end
    end.
