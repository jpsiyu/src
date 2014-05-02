%% --------------------------------------------------------
%% @Module:           |mod_guild
%% @Author:           |wzh
%% @Email:            |45517168@qq.com
%% @Created:          |2012-00-00
%% @Description:      |帮派处理_帮派进程于公共线内启动
%% --------------------------------------------------------

-module(mod_guild).
-behaviour(gen_server).
-include("common.hrl").
-include("goods.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("guild.hrl").
-include("sql_guild.hrl").

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%%=========================================================================
%% 接口函数 
%%=========================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(?MODULE, stop).

daily_work() ->
	case lib_guild_base:get_all_guild_id() of
		[] ->
			skip;
		Gids ->
			erlang:spawn(fun()->
								 lists:map(fun(GuildId)->
												gen_server:cast(?MODULE, {daily_work, GuildId}),
												SleepTime = util:rand(1000, 2000),
						 						timer:sleep(SleepTime)
										   end, Gids)
						 end)
	end.

%% 被删除
handle_expired_disband() ->
    gen_server:cast(?MODULE, 'handle_expired_disband').

%% 被删除
handle_auto_disband() ->
    gen_server:cast(?MODULE, 'handle_auto_disband').

%% 被删除
handle_daily_construction() ->
    gen_server:cast(?MODULE, 'handle_daily_construction').

%% 被删除
handle_expired_event() ->
    gen_server:cast(?MODULE, 'handle_expired_event').

send_guild_mail(SubjectType, Param) ->
	%% 更改为直接调用邮件cast
	?ERR("SEND GUILD MAIL ERR, type=[~p], subtype=[~p]", [SubjectType, Param]),
	lib_guild:send_mail(SubjectType, Param).

init([]) ->
    process_flag(trap_exit, true),
    NewState = lib_guild_base:init_guild(),
    {ok, NewState}.

%%=========================================================================
%% 回调函数_同步
%%=========================================================================
handle_call(Request, From, State) ->
    case catch mod_guild_call:handle_call(Request, From, State) of
        {reply, NewFrom, NewState} ->
            {reply, NewFrom, NewState};
        Reason ->
             util:errlog("mod_guild_call error: ~p, Reason=~p~n",[Request, Reason]),
             {reply, error, State}
    end.

%%=========================================================================
%% 回调函数_异步
%%=========================================================================
handle_cast(Msg, State) ->
    case catch mod_guild_cast:handle_cast(Msg, State)of
        {noreply, NewState} ->
            {noreply, NewState};
        Reason ->
            util:errlog("mod_guild_cast error: ~p, Reason:=~p~n",[Msg, Reason]),
            {noreply, State}
    end.

%%=========================================================================
%% 回调函数_任意
%%=========================================================================
handle_info(Info, State) ->
    case catch mod_guild_info:handle_info(Info, State) of
        {noreply, NewState} ->
            {noreply, NewState};
        Reason ->
            util:errlog("mod_guild_info error: ~p, Reason:=~p~n",[Info, Reason]),
            {noreply, State}
    end.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%=========================================================================
%% 业务处理函数
%%=========================================================================

%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 						帮派基础功能
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 创建帮派
%% -----------------------------------------------------------------
create_guild(UniteStatus, [UseType, GuildName, GuildTenet]) ->
	%% 检查关键字
    NameLenValid        = util:check_length(GuildName, 14),
    NameContentInValid  = util:check_keyword(GuildName),
    TenetLenValid       = util:check_length(GuildTenet, 100),
    TenetContentInValid = util:check_keyword(GuildTenet),
	PlayerId = UniteStatus#unite_status.id,
	%% 获取成员帮派信息
	[GuildIdOld, _GuildNameOld, _GuildPositionOld]
	= [UniteStatus#unite_status.guild_id, UniteStatus#unite_status.guild_name, UniteStatus#unite_status.guild_position],
    %% 获取玩家物品信息
    case lib_player:get_player_info(PlayerId, goods) of
		PlayerGoods when is_record(PlayerGoods, status_goods) ->
		    if  % 你已经拥有帮派
		        GuildIdOld /= 0 -> [2, 0, 0, 0];
		        % 你还没有国家
		        UniteStatus#unite_status.realm == 0 -> [11, 0, 0, 0];
		        % 帮派名长度非法
		        NameLenValid == false -> [7, 0, 0, 0];
		        % 帮派名内容非法
		        NameContentInValid == true -> [8, 0, 0, 0];
		        % 帮派宗旨长度非法
		        TenetLenValid == false -> [9, 0, 0, 0];
		        % 帮派宗旨内容非法
		        TenetContentInValid == true -> [10, 0, 0, 0];
		        true ->
		            CreateLevel  = data_guild:get_guild_config(create_level, []),
		            if  % 你级别不够
		                UniteStatus#unite_status.lv < CreateLevel -> [3, 0, 0, 0];
		                true ->
		                    NewGuildName = string:to_upper(util:make_sure_list(GuildName)),
		                    GuildUpper   = lib_guild_base:get_guild_by_name_upper(NewGuildName),
		                    if  % 帮派名已存在
		                        GuildUpper =/= [] -> [6, 0, 0, 0];
		                        true ->
		                            case UseType of
		                                0 ->%% 使用铜钱 获取铜钱花费
		                                    CreateCoin = data_guild:get_guild_config(create_coin, []),
											%% 扣费
											case lib_player_unite:spend_assets_status_unite(PlayerId, CreateCoin, coin, guild_create, "") of
												{ok, ok} ->
													 case lib_guild:create_guild(UniteStatus#unite_status.mergetime, UniteStatus#unite_status.id
																				, UniteStatus#unite_status.name
																				, UniteStatus#unite_status.realm, GuildName, GuildTenet, UseType) of
		                                                 {ok, GuildId} -> [1, GuildId, 0, 0];
		                                                  _ -> [0, 0, 0, 0]
		                                             end;
												{error, _IRes} -> %% 扣除铜币不足(扣除铜币失败)
													[4, 0, 0, 0]
											end;
		                                % 使用帮派令
		                                1 ->
		                                    [Type, SubType, UseNum] = data_guild:get_guild_config(guild_token, []),
		                                    GoodsType = lib_guild:get_goods_type_by_type_info(Type, SubType),
		                                    if  % 帮派令类型信息不存在
		                                        GoodsType =:= [] ->
		                                            ?ERR("create_guild: Faild to find goods type, type=[~p], subtype=[~p]", [Type, SubType]),
		                                            [0, 0, 0, 0];
		                                        true ->
		                                            case gen_server:call(PlayerGoods#status_goods.goods_pid, {'delete_more', GoodsType#ets_goods_type.goods_id, UseNum}) of
		                                                % 扣取物品成功
		                                                1 ->
															log:log_throw(guild_create, PlayerId, 0, GoodsType#ets_goods_type.goods_id, UseNum, 0, 0),
		                                                    case lib_guild:create_guild(UniteStatus#unite_status.mergetime,UniteStatus#unite_status.id
																						, UniteStatus#unite_status.name
																						, UniteStatus#unite_status.realm, GuildName, GuildTenet, UseType) of
		                                                        {ok, GuildId} -> [1, GuildId, 0, 0];
		                                                        _ -> [0, 0, 0, 0]
		                                                    end;
		                                                % 扣取物品失败
		                                                0 ->
		                                                    ?ERR("create_guild: Call goods module faild", []),
		                                                    [0, 0, 0, 0];
		                                                % 物品数量不够
		                                                _ ->
		                                                    [5, 0, 0, 0]
		                                            end
		                                    end
		                            end
		                    end                   
		            end
		    end;
		_ ->
			[0, 0, 0, 0]
	end.

%% -----------------------------------------------------------------
%% 申请解散帮派
%% -----------------------------------------------------------------
apply_disband_guild(UniteStatus, [GuildId]) ->
    %?DEBUG("apply_disband_guild: GuildId=[~p]", [GuildId]),
    Guild = lib_guild:get_guild(GuildId),
    if % 帮派不存在
       Guild =:= [] -> 2;
       true ->
           DisbandFlag = Guild#ets_guild.disband_flag,
           if  % 你尚未加入任何帮派
               GuildId == 0 -> 3;
               % 你不是该帮派成员
               UniteStatus#unite_status.guild_id /= GuildId -> 4;
               % 你无权解散该帮派
               UniteStatus#unite_status.guild_position > 1 -> 5;
               % 你已经申请解散
               DisbandFlag == 1 -> 6;
               % 可以解散帮派
               true ->
                   case lib_guild:apply_disband_guild(GuildId) of
                        [ok, ConfirmTime]  ->
                            % 更新帮派缓存
                            GuildNew = Guild#ets_guild{disband_flag         = 1,
                                                       disband_confirm_time = ConfirmTime},
                            lib_guild:update_guild(GuildNew, UniteStatus#unite_status.id),
                            1;
                        _   -> 0
                   end
            end
    end.

%% -----------------------------------------------------------------
%% 确认解散帮派
%% -----------------------------------------------------------------
confirm_disband_guild(UniteStatus, [GuildId, ConfirmResult]) ->
    Guild = lib_guild:get_guild(GuildId),
    NowTime = util:unixtime(),
    if % 帮派不存在
       Guild =:= [] -> 2;
       true ->
           [DisbandFlag, DisbandConfirmTime] = [Guild#ets_guild.disband_flag, Guild#ets_guild.disband_confirm_time],
           if  
               % 你不是该帮派成员
               UniteStatus#unite_status.guild_id /= GuildId -> 4;
               % 你无权确认解散该帮派
               UniteStatus#unite_status.guild_position > 1 -> 5;
               % 你未申请解散
               DisbandFlag == 0 -> 6;
               % 申请后3天才能确认正式解散
               ((ConfirmResult== 1) and (NowTime < DisbandConfirmTime)) -> 7;
               % 可以解散帮派
               true ->
                   case lib_guild:confirm_disband_guild(GuildId, UniteStatus#unite_status.guild_name, ConfirmResult) of
                        ok  ->
                            if  % 取消解散
                                ConfirmResult == 0 ->
                                    % 更新缓存
                                    GuildNew = Guild#ets_guild{disband_flag         = 0,
                                                               disband_confirm_time = 0},
                                    lib_guild:update_guild(GuildNew, UniteStatus#unite_status.id);
                                true ->
                                    void
                            end,
                            1;
                        _   -> 0
                   end
            end
    end.

%% -----------------------------------------------------------------
%% 直接解散帮派
%% -----------------------------------------------------------------
just_disband_guild(UniteStatus, [GuildId]) ->
    Guild = lib_guild:get_guild(GuildId),
    if % 帮派不存在
       Guild =:= [] -> 2;
       true ->
           if  
               % 你不是该帮派成员
               UniteStatus#unite_status.guild_id /= GuildId -> 4;
               % 你无权确认解散该帮派
               UniteStatus#unite_status.guild_position > 1 -> 5;
			   %% 成员数大于5人
			   Guild#ets_guild.member_num > 5 -> 6;
               % 可以解散帮派
               true -> 
                   case lib_guild:confirm_disband_guild(GuildId, UniteStatus#unite_status.guild_name, 1) of
                        ok  -> 1;
                        _   -> 0
                   end
            end
    end.

%% -----------------------------------------------------------------
%% 获取帮派列表
%% -----------------------------------------------------------------
list_guild(_Status, [PageSize, PageNo]) ->
    lib_guild:get_guild_page(PageSize, PageNo).

%% -----------------------------------------------------------------
%% 入帮祝福
%% -----------------------------------------------------------------
join_bless(UniteStatus, [PlayerId, _Type, GoodsNum]) ->
	SelfPlayerId = UniteStatus#unite_status.id,
    if  % 你没有帮派
        UniteStatus#unite_status.guild_id == 0 -> [2, <<>>];
		true ->
		    %% 扣费
			case lib_player_unite:spend_assets_status_unite(SelfPlayerId, GoodsNum, bcoin, guild_join_bless, "") of
				{ok, ok} ->
					 case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
						   GuildMember when is_record(GuildMember, ets_guild_member) ->
							   if
								   % 对方和你不同帮派
								   UniteStatus#unite_status.guild_id =/= GuildMember#ets_guild_member.guild_id -> [4, <<>>];
								   true ->   [1, GuildMember#ets_guild_member.name]
							   end;
						   _ ->
							   [3, <<>>]
					   end;
				{error, _IRes} -> %% 扣除铜币不足(扣除铜币失败)
					[5, <<>>]%% 铜币不够
			end
    end.

%% -----------------------------------------------------------------
%% 修改帮派公告
%% -----------------------------------------------------------------
modify_guild_announce(UniteStatus, [GuildId, AnnounceC]) ->
    %?DEBUG("modify_guild_tenet: GuildId=[~p], Announce=[~s]", [GuildId, Announce]),
    Guild = lib_guild:get_guild(GuildId),
    AnnounceLenValid        = util:check_length(AnnounceC, 100),
	Announce = util:filter_text(AnnounceC, UniteStatus#unite_status.lv),
	AnnounceContentInValid  = lib_mail:check_content(AnnounceC),
    Res = if  % 帮派不存在
        Guild =:= [] -> 2;
        % 帮派公告长度非法
        AnnounceLenValid == false -> 6;
		% 帮派公告内容非法
        AnnounceContentInValid =/= true -> 7;
        true ->
            if  % 你没有加入任何帮派
                UniteStatus#unite_status.guild_id == 0 -> 3;
                % 你不是该帮派成员
                UniteStatus#unite_status.guild_id /= GuildId -> 4;
                % 你无权修改(帮主和副帮主可以)
                UniteStatus#unite_status.guild_position > 2 -> 5;
                % 可以修改
                true ->
                    case lib_guild:modify_guild_announce(GuildId, Announce) of
                        ok  ->
                            % 更新缓存
                            AnnounceBin = util:make_sure_binary(Announce),
                            GuildNew = Guild#ets_guild{announce = AnnounceBin},
                            lib_guild:update_guild(GuildNew, UniteStatus#unite_status.id),
                            1;
                        _   -> 0
                    end
            end
    end, 
	[Res, Announce].

%% -----------------------------------------------------------------
%% 捐献铜币 1000铜币=10帮派贡献=100每日福利=1000帮派资金
%% ------------------------------------------------------------------
%% donate_money(UniteStatus, [GuildId, Num]) ->
%% 	PlayerId = UniteStatus#unite_status.id,
%%     if   %% 你没有加入任何帮派
%%          UniteStatus#unite_status.guild_id == 0 -> [3, 0, 0, 0, 0];
%% %%          你不是该帮派成员
%%          UniteStatus#unite_status.guild_id /= GuildId -> [4, 0, 0, 0, 0];
%% %%       你没有输入二级密码
%%          true ->
%%              Guild = lib_guild:get_guild(GuildId),
%%              if  % 帮派不存在
%%                  Guild =:= [] -> [2, 0, 0, 0, 0];
%%                  true ->
%% 					%% 扣费
%% 					case lib_player_unite:spend_assets_status_unite(PlayerId, Num, rcoin, guild_donate, "") of
%% 						{ok, ok} ->
%% 							 case lib_guild:donate_money(PlayerId, GuildId, Num) of
%% 		                         [ok, DonationAdd, PaidAdd]  ->
%% 		                             % 更新缓存
%% 		                             GuildNew = Guild#ets_guild{funds = Guild#ets_guild.funds + Num},
%% 		                             lib_guild:update_guild(GuildNew, PlayerId),
%% 		                             [1, 0, 0, DonationAdd, PaidAdd];
%% 		                         _   ->
%% 		                             [0, 0, 0, 0, 0]
%% 		                     end;
%% 						{error, _IRes} -> %% 扣除铜币不足(扣除铜币失败)
%% 							[4, 0, 0, 0, 0]
%% 					end
%%              end             
%%    end.

%% -----------------------------------------------------------------
%% 捐献帮派建设卡 1建设令=100帮派建设=10帮派贡献=100每日福利=10帮派财富
%% -----------------------------------------------------------------
donate_contribution_card(UniteStatus, [GuildId, Num]) ->
	PlayerId = UniteStatus#unite_status.id,
    %% 获取玩家物品信息
    case lib_player:get_player_info(PlayerId, goods) of
		PlayerGoods when is_record(PlayerGoods, status_goods) ->
		    if   % 你没有加入任何帮派
		         UniteStatus#unite_status.guild_id == 0 -> [2, 0, 0, 0, 0, 0];
		         % 你不是该帮派成员
		         UniteStatus#unite_status.guild_id /= GuildId -> [3, 0, 0, 0, 0, 0];
		         true ->
		             [Type, SubType] = data_guild:get_guild_config(contribution_card, []),
		             GoodsType       = lib_guild:get_goods_type_by_type_info(Type, SubType),
		             if  % 没有帮派建设卡
		                 GoodsType =:= [] ->
		                     [0, 0, 0, 0, 0, 0];
		                 true ->
		                     Guild = lib_guild:get_guild(GuildId),
		                     if  % 帮派不存在
		                         Guild =:= []  -> [5, 0, 0, 0, 0, 0];
		                         true ->
		                             case gen_server:call(PlayerGoods#status_goods.goods_pid, {'delete_more', GoodsType#ets_goods_type.goods_id, Num}) of
		                                 % 扣取物品成功
		                                 1 ->
											log:log_throw(guild_donate, PlayerId, 0, GoodsType#ets_goods_type.goods_id, Num, 0, 0),
		                                    [Level,Contribution,_ContributionThreshold,MemberCapacity] = [Guild#ets_guild.level, Guild#ets_guild.contribution, Guild#ets_guild.contribution_threshold, Guild#ets_guild.member_capacity],
		                                    case lib_guild:donate_contribution_card(PlayerId, GuildId, Num, Level, Contribution, MemberCapacity) of
		                                        % 帮派未升级
		                                        [0, ContributionNew, DonationAdd, PaidAdd, MaterialAdd]  ->
		                                            % 更新缓存
		                                            GuildNew = Guild#ets_guild{contribution = ContributionNew},
		                                            lib_guild:update_guild(GuildNew, PlayerId),
		                                            [1, Level, Level, DonationAdd, PaidAdd, MaterialAdd];
		                                        % 帮派升级
		                                        [1, MemberCapacityNew, LevelNew, ContributionNew, ContributionDailyNew, ContributionThresholdNew, DisbandDeadlineTime, DonationAdd, PaidAdd, MaterialAdd]  ->
		                                            % 更新缓存
		                                            GuildNew = Guild#ets_guild{member_capacity        = MemberCapacityNew,
		                                                                       level                  = LevelNew,
		                                                                       contribution           = ContributionNew,
		                                                                       contribution_daily     = ContributionDailyNew,
		                                                                       contribution_threshold = ContributionThresholdNew,
		                                                                       disband_deadline_time  = DisbandDeadlineTime},
		                                            lib_guild:update_guild(GuildNew, PlayerId),
		                                            [1, Level, LevelNew, DonationAdd, PaidAdd, MaterialAdd];
		                                        % 出错
		                                        _   ->
		                                            [0, 0, 0, 0, 0, 0]
		                                    end;
		                                  % 扣取物品失败
		                                  0 ->
		                                       ?ERR("donate_contribution_card: Call goods module faild", []),
		                                       [0, 0, 0, 0, 0, 0];
		                                  % 物品数量不够
		                                  _ ->
		                                       [4, 0, 0, 0, 0, 0]
		                             end
		                     end
		             end
		   end;
		_ ->
			[0, 0, 0, 0, 0, 0]
	end.

%% -----------------------------------------------------------------
%% 捐献元宝
%% -----------------------------------------------------------------
donate_gold(UniteStatus, [GuildId, GoldNum]) ->
    PlayerId = UniteStatus#unite_status.id,
    if   % 你没有加入任何帮派
         UniteStatus#unite_status.guild_id == 0 -> [2, 0, 0, 0, 0, 0];
         % 你不是该帮派成员
         UniteStatus#unite_status.guild_id /= GuildId -> [3, 0, 0, 0, 0, 0];
%%          % 你没有输入二级密码
%%          IsPass =:= false -> [6, 0, 0, 0, 0, 0];
         true ->
             Guild = lib_guild:get_guild(GuildId),
             if  % 帮派不存在
                 Guild =:= []  -> [5, 0, 0, 0, 0, 0];
                 true ->
    				[Text] = data_log_consume_text:get_log_consume_text(guild_material),
					%% 扣费
					case lib_player_unite:spend_assets_status_unite(PlayerId, GoldNum, gold, guild_donate, Text) of
						{ok, ok} ->
							 [Level,Contribution,_ContributionThreshold,MemberCapacity] = [Guild#ets_guild.level, Guild#ets_guild.contribution, Guild#ets_guild.contribution_threshold, Guild#ets_guild.member_capacity],
		                     case lib_guild:donate_gold(PlayerId, GuildId, GoldNum, Level, Contribution, MemberCapacity) of
		                         % 帮派未升级
		                         [0, ContributionNew, DonationAdd, PaidAdd]  ->
		                             % 更新缓存
		                             GuildNew = Guild#ets_guild{contribution = ContributionNew},
		                             lib_guild:update_guild(GuildNew, PlayerId),
		                             [1, Level, Level, DonationAdd, PaidAdd, ContributionNew - Contribution];
		                         % 帮派升级
		                         [1, MemberCapacityNew, LevelNew, ContributionNew, ContributionDailyNew, ContributionThresholdNew, DisbandDeadlineTime, DonationAdd, PaidAdd]  ->
		                             % 更新缓存
		                             GuildNew = Guild#ets_guild{member_capacity        = MemberCapacityNew,
		                                 level                  = LevelNew,
		                                 contribution           = ContributionNew,
		                                 contribution_daily     = ContributionDailyNew,
		                                 contribution_threshold = ContributionThresholdNew,
		                                 disband_deadline_time  = DisbandDeadlineTime},
		                             lib_guild:update_guild(GuildNew, PlayerId),
									 ContributionShow = GoldNum * 10,
		                             [1, Level, LevelNew, DonationAdd, PaidAdd, ContributionShow];
		                         % 出错
		                         _   ->
		                             [0, 0, 0, 0, 0, 0]
		                     end;
						{error, _IRes} -> %% 扣除铜币不足(扣除铜币失败)
							[4, 0, 0, 0, 0, 0]
					end
             end
     end.

%% -----------------------------------------------------------------
%% 获取捐献列表
%% -----------------------------------------------------------------
list_donate(_Status, [GuildId, PageSize, PageNo]) ->
    %?DEBUG("list_donate: GuildId=[~p], PageSize=[~p], PageNo=[~p]", [GuildId, PageSize, PageNo]),
    lib_guild:get_donate_page(GuildId, PageSize, PageNo).
   

%% -----------------------------------------------------------------
%% 领取日福利
%% -----------------------------------------------------------------
get_paid(UniteStatus, [GuildId]) ->
	PlayerId = UniteStatus#unite_status.id,
    if   % 你没有加入任何帮派
         UniteStatus#unite_status.guild_id == 0 -> [2, 0, 0];
         % 你不是该帮派成员
         UniteStatus#unite_status.guild_id /= GuildId -> [3, 0, 0];
         true ->
			 case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
				 GuildMember when is_record(GuildMember, ets_guild_member) ->
					 PaidLastTime   = GuildMember#ets_guild_member.paid_get_lasttime,
                     NowTime        = util:unixtime(),
                     SameDay        = util:is_same_date(PaidLastTime, NowTime),
                     if  % 已经领取过
                         SameDay == true -> [4, 0, 0];
                         true ->
                             Guild   = lib_guild:get_guild(GuildId),
                             if  % 帮派不存在
                                 Guild =:= []  ->
                                     ?ERR("get_paid: guild not found, id=[~p]", [GuildId]),
                                     [5, 0, 0];
                                 true ->
                                     GuildLevel    = Guild#ets_guild.level,
                                     PaidDaily     = lib_guild:calc_paid_daily(GuildLevel
																			  , UniteStatus#unite_status.guild_position
																			  , GuildMember#ets_guild_member.paid_add),
									 %% 更新玩家数据
									 lib_player:update_player_info(PlayerId, [{add_coin, PaidDaily}]),
                                     case lib_guild:get_paid(PlayerId, NowTime) of
                                        ok ->
                                            % 更新缓存
                                            GuildMemberNew = GuildMember#ets_guild_member{paid_get_lasttime    = NowTime,
                                                                                          paid_add = 0},
                                            lib_guild_base:update_guild_member(GuildMemberNew),
                                            [1, PaidDaily, 0];
                                        _  ->
                                            [0, 0, 0]
                                     end
                             end
                     end;
				 _ ->% 成员不存在
					 [0, 0, 0]
			 end
    end.

%% -----------------------------------------------------------------
%% 查询帮派
%% -----------------------------------------------------------------
search_guild(UniteStatus, [Realm, GuildName, ChiefName, PageSize, PageNo, WashType, SelfShow]) ->
    %%?DEBUG("list_guild: Realm=[~p], GuildName=[~s], ChiefName=[~s], PageSize=[~p], PageNo=[~p]", [Realm, GuildName, ChiefName, PageSize, PageNo]),
    lib_guild:search_guild(UniteStatus#unite_status.id, Realm, util:make_sure_binary(GuildName), util:make_sure_binary(ChiefName), PageSize, PageNo, WashType, UniteStatus#unite_status.guild_id, SelfShow).

%% -----------------------------------------------------------------
%% 合服改名
%% -----------------------------------------------------------------
rename_guild(UniteStatus, [GuildId, GuildName]) ->
    PlayerId = UniteStatus#unite_status.id,
    %?DEBUG("rename_guild: GuildId=[~p], GuildName=[~s]", [GuildId, GuildName]),
    NameLenValid        = util:check_length(GuildName, 16),
    NameContentInValid  = util:check_keyword(GuildName),
    if  % 你没有帮派
        UniteStatus#unite_status.guild_id == 0 -> [2, 0];
        % 你不是该帮派成员
        UniteStatus#unite_status.guild_id /= GuildId -> [3, 0];
        % 你权限不够
        UniteStatus#unite_status.guild_position /= 1 -> [4, 0];
        % 帮派名长度非法
        NameLenValid == false -> [5, 0];
        % 帮派名内容非法
        NameContentInValid == true -> [6, 0];
        true ->
            GuildNameList  = util:make_sure_list(GuildName),
            GuildNameBin   = util:make_sure_binary(GuildName),
            GuildNameUpper = string:to_upper(GuildNameList),
            GuildUpper     = lib_guild_base:get_guild_by_name_upper(GuildNameUpper),
            if  % 帮派名已存在
                GuildUpper =/= [] -> [7, 0];
                true ->
                    Guild   = lib_guild:get_guild(GuildId),
                    if  % 帮派不存在
                        Guild =:= []  ->
                            ?ERR("rename_guild: guild not found, id=[~p]", [GuildId]),
                            [8, 0];
                        true ->
                            RenameGold = case Guild#ets_guild.rename_flag == 0 of
                                             true -> data_guild:get_guild_config(rename_gold, []);
                                             false-> 0
                                         end,
							case lib_player_unite:spend_assets_status_unite(PlayerId, RenameGold, gold, guild_rename, "") of
								{ok, ok} ->
									case lib_guild:rename_guild(GuildId, GuildName, Guild#ets_guild.rename_flag, PlayerId) of
                                        ok ->
                                            % 更新帮派缓存
                                            NewGuild = Guild#ets_guild{rename_flag = 0,
                                                                       name        = GuildNameBin,
                                                                       name_upper  = GuildNameUpper},
                                            lib_guild:update_guild(NewGuild, rename_guild),
                                            % 更新帮派成员缓存
                                            GuildMembers = lib_guild_base:get_guild_member_by_guild_id(GuildId),
                                            Fun = fun(GuildMember) ->
                                                      NewGuildMember = GuildMember#ets_guild_member{guild_name = GuildNameBin},
                                                      lib_guild_base:update_guild_member(NewGuildMember)
                                                  end,
                                            lists:foreach(Fun, GuildMembers),
                                            [1, 0];
                                        _  ->
                                            [0, 0]
                                    end;
								{error, _IRes} -> %% 扣除铜币不足(扣除铜币失败)
									[9, 0]
							end
                    end
            end
    end.


%% -----------------------------------------------------------------
%% 使用弹劾令_411401_1
%% -----------------------------------------------------------------
impeach_chief(UniteStatus, [_GoodsId, GoodsUseNum]) ->
    PlayerId = UniteStatus#unite_status.id,
    %% 获取玩家物品信息
    case lib_player:get_player_info(PlayerId, goods) of
		PlayerGoods when is_record(PlayerGoods, status_goods) ->
		    if   % 你没有加入任何帮派
		         UniteStatus#unite_status.guild_id == 0 -> 
		             [2, 0, <<>>, 0];
		         % 你不能弹劾自己
		         UniteStatus#unite_status.guild_position == 1 ->
		             [3, 0, <<>>, 0];
		         true ->
		             Guild       = lib_guild:get_guild(UniteStatus#unite_status.guild_id),
		             if  % 帮派不存在
		                 Guild =:= [] ->
		                      [0, 0, <<>>, 0];
		                 true ->
							  case lib_guild_base:get_guild_member_by_player_id(Guild#ets_guild.chief_id) of
								  GuildChief when is_record(GuildChief, ets_guild_member) ->
									  %%计算帮主离线时间
									  ChiefLoginTime = GuildChief#ets_guild_member.last_login_time,
		                        	  TimeCC = util:diff_day(ChiefLoginTime),
		%% 							  io:format("~n ~p ~n", [TimeCC]),
		                              if  
										  TimeCC < 3 -> [4, 0, <<>>, 0];
		                                  true ->
											  [Type, SubType] = data_guild:get_guild_config(impeach_chief_token, []),
		                                      GoodsType       = lib_guild:get_goods_type_by_type_info(Type, SubType),
		                                      if  % 该物品不存在
		                                          GoodsType =:= []  ->
		                                              [5, 0, <<>>, 0];
		                                          true ->             
		                                               PlayerName     = UniteStatus#unite_status.name,
		                                               PlayerPosition = UniteStatus#unite_status.guild_position,
		                                               GuildId        = UniteStatus#unite_status.guild_id,
		                                               ChiefId        = GuildChief#ets_guild_member.id,
		                                               ChiefName      = GuildChief#ets_guild_member.name,
													   case gen_server:call(PlayerGoods#status_goods.goods_pid, {'delete_more', GoodsType#ets_goods_type.goods_id, GoodsUseNum}) of
		                                                   %　扣取成功
		                                                   1 ->
		                                                        case lib_guild:impeach_chief(PlayerId, PlayerName, PlayerPosition, GuildChief, GuildId) of
		                                                            ok ->
		                                                                case PlayerId == Guild#ets_guild.deputy_chief1_id of
		                                                                    % 自己是副帮主1
		                                                                    true ->
		                                                                        GuildNew = Guild#ets_guild{chief_id           = PlayerId,
		                                                                                                   chief_name         = util:make_sure_binary(PlayerName),
		                                                                                                   deputy_chief1_id   = 0,
		                                                                                                   deputy_chief1_name = <<>>,
																										   base_left = 0},
		                                                                        lib_guild:update_guild(GuildNew, PlayerId);
		                                                                    % 自己是副帮主2
		                                                                    false when PlayerId == Guild#ets_guild.deputy_chief2_id ->
		                                                                        GuildNew = Guild#ets_guild{chief_id           = PlayerId,
		                                                                                                   chief_name         = util:make_sure_binary(PlayerName),
		                                                                                                   deputy_chief2_id   = 0,
		                                                                                                   deputy_chief2_name = <<>>,
																										   base_left = 0},
		                                                                        lib_guild:update_guild(GuildNew, PlayerId);
		                                                                    % 自己是帮众
		                                                                    false ->
		                                                                        GuildNew = Guild#ets_guild{chief_id           = PlayerId,
		                                                                                                   chief_name         = util:make_sure_binary(PlayerName),
																										   base_left = 0},
		                                                                        lib_guild:update_guild(GuildNew, PlayerId)
		                                                                end,
		                                                                [1, ChiefId, ChiefName, 1];
		                                                             _  ->
		                                                                [0, 0, <<>>, 0]
		                                                        end;
		                                                    %　扣取失败
		                                                    GoodsModuleCode ->
		                                                        ?ERR("impeach_chief: Call goods module faild, result code=[~p]", [GoodsModuleCode]),
		                                                        [5, 0, <<>>, 0]
		                                               end
		                                      end
		                              end;
								  _ ->% 帮主不存在
									  [0, 0, <<>>, 0]
							  end
		             end             
		   end;
		_ ->
			[5, 0, <<>>, 0]
	end.

%% -----------------------------------------------------------------
%% 使用集结令
%% -----------------------------------------------------------------
gather_member(UniteStatus, [GoodsId, GoodsUseNum], [MyScene, _MyCopyId, _MyX, _MyY]) ->
    PlayerId = UniteStatus#unite_status.id,
    %% 获取玩家物品信息
    case lib_player:get_player_info(PlayerId, goods) of
		PlayerGoods when is_record(PlayerGoods, status_goods) ->
		    if  % 你没有加入任何帮派
		        UniteStatus#unite_status.guild_id == 0 -> 2;
		        % 你权限不够
		        UniteStatus#unite_status.guild_position > 2 -> 3;
		        true ->
		            CanTransport = case lists:member(MyScene, ?FORBIMAP) orelse mod_scene_agent:apply_call(MyScene, lib_scene, is_dungeon_scene, [MyScene]) of
		                               true -> false;
		                               false-> true
		                            end,
		            if  %% 该场景不能传送
		                CanTransport =:= false -> 4;
		                true ->
		                    Goods = lib_player:rpc_call_by_id(PlayerId, lib_goods_util, get_goods_info, [GoodsId]),
		                    if  %% 该物品不存在
		                        Goods =:= []  -> 5;
		                        true -> 
		                            [TokenGoodsType, TokenGoodsSubType] = data_guild:get_guild_config(gather_member_token,[]),
		                            [GoodsPlayerId, GoodsType, GoodsSubtype, GoodsNum] = [Goods#goods.player_id, Goods#goods.type, Goods#goods.subtype, Goods#goods.num],
		                            if  % 物品不归你所有
		                                GoodsPlayerId /= PlayerId -> 6;
		                                % 该物品不是弹劾令
		                                ((GoodsType /= TokenGoodsType) and (GoodsSubtype /= TokenGoodsSubType)) -> 7;
		                                % 物品数量不够
		                                GoodsNum < GoodsUseNum -> 8;
		                                true ->
		                                    case gen_server:call(PlayerGoods#status_goods.goods_pid, {'delete_one', GoodsId, GoodsUseNum}) of
		                                        % 扣取成功
		                                        1 ->
		                                            1;
		                                        % 扣取失败
		                                        GoodsModuleCode ->
		                                            ?ERR("gather_member: Call goods module faild, result code=[~p]", [GoodsModuleCode]),
		                                            0
		                                    end
		                            end
		                    end
		            end
		    end;
		_ ->
			0
	end.

%% -----------------------------------------------------------------
%% 合并申请
%% -----------------------------------------------------------------
invite_merge_guild(UniteStatus, [TargetGuildId]) ->
	_SelfPlayerId = UniteStatus#unite_status.id,
	case lib_factionwar:is_factionwar(TargetGuildId) of
		false ->
		    if  
				UniteStatus#unite_status.guild_id =:= TargetGuildId -> [2]; 			%% 不能跟自己帮派合并
		        UniteStatus#unite_status.guild_id =:= 0 -> [3]; 						%% 你没有帮派
		        UniteStatus#unite_status.guild_position =/= 1 -> [4];					%% 你不是帮主，不能发起邀请
		        true ->
					case lib_guild:get_guild(UniteStatus#unite_status.guild_id) of
						SelfGuild when is_record(SelfGuild, ets_guild) ->
							case lib_guild:get_guild(TargetGuildId) of
								TargetGuild when is_record(TargetGuild, ets_guild) ->
									TargetChiefId = TargetGuild#ets_guild.chief_id,
									case mod_chat_agent:lookup(TargetChiefId) of
										[Player] when is_record(Player, ets_unite)->
											if
												UniteStatus#unite_status.realm =/= Player#ets_unite.realm -> 
													[6];								%% 国家不同 
												true ->
													case TargetGuild#ets_guild.member_capacity >=
														TargetGuild#ets_guild.member_num + SelfGuild#ets_guild.member_num of
														true ->
															case SelfGuild#ets_guild.merge_guild_id =:= 0 of
																true ->
																	case TargetGuild#ets_guild.merge_guild_id =:= 0 of
																		true ->
																			NewSelfGuild = SelfGuild#ets_guild{merge_guild_id = TargetGuild#ets_guild.id, merge_guild_direction = 1},
																			NewTargetGuild = TargetGuild#ets_guild{merge_guild_id = SelfGuild#ets_guild.id, merge_guild_direction = 3},
																			lib_guild:update_guild(NewSelfGuild),
																			lib_guild:update_guild(NewTargetGuild),
																			%% 发送合并请求给对方帮主更改自己和对方帮派的合并信息 
																			{ok, BinData} = pt_400:write(40059, [1
																												, UniteStatus#unite_status.guild_id
																												, SelfGuild#ets_guild.level
																												, UniteStatus#unite_status.guild_name 
																												, 0
																												, SelfGuild#ets_guild.member_num]),
																			lib_unite_send:send_to_one(TargetChiefId, BinData),
																			[1];
																		false ->
																			[10]		%% 目标帮派有未处理的合并申请
																	end;
																false ->
																	[11]				%% 自身帮派有未处理的合并申请
															end;
														false ->
															[9]							%% 超过帮派人数上限
													end
											end;
										_ ->
											[5]											%% 目标帮主不在线
									end;
								_ ->
									[0]													%% 错误的目标帮派(提示未知错误)
							end;
						_ ->
							[0]															%% 错误的自身帮派(提示未知错误)
					end
			end;
		true ->
			[7]																			%% 帮战期间不能操作
	end.

%% -----------------------------------------------------------------
%% 回应合并邀请
%% -----------------------------------------------------------------
response_merge_guild_invite(UniteStatus, [HbGuildId, ResponseResult]) ->
	_SelfPlayerId = UniteStatus#unite_status.id,
	case lib_factionwar:is_factionwar(HbGuildId) of
		false ->
		    if  
				UniteStatus#unite_status.guild_id =:= HbGuildId -> [2]; 				
		        UniteStatus#unite_status.guild_id =:= 0 -> [3]; 						
		        UniteStatus#unite_status.guild_position =/= 1 -> [4];					
		        true ->
					case lib_guild:get_guild(UniteStatus#unite_status.guild_id) of
						SelfGuild when is_record(SelfGuild, ets_guild) ->
							case ResponseResult =:= 0 of
								true ->
									make_merge_0(UniteStatus#unite_status.guild_id, 0),
									make_merge_0(HbGuildId, 1),
									[1];
								false when ResponseResult =:= 1 ->
									case lib_guild:get_guild(HbGuildId) of
										HbGuild when is_record(HbGuild, ets_guild) ->
											case SelfGuild#ets_guild.merge_guild_direction =:= 3 andalso HbGuild#ets_guild.merge_guild_direction =:= 1 of
												true ->
													HbGuildChiefId = HbGuild#ets_guild.chief_id,
													case mod_chat_agent:lookup(HbGuildChiefId) of
														[Player] when is_record(Player, ets_unite) ->
															if
																UniteStatus#unite_status.realm =/= Player#ets_unite.realm -> 
																	[6];								
																true -> 
																	case SelfGuild#ets_guild.member_capacity >=
																		HbGuild#ets_guild.member_num + SelfGuild#ets_guild.member_num of
																		true ->
																			case SelfGuild#ets_guild.merge_guild_id =:= HbGuild#ets_guild.id of
																				true ->
																					case HbGuild#ets_guild.merge_guild_id =:= SelfGuild#ets_guild.id of
																						true ->
																							case db:transaction(fun() ->make_merge_1(HbGuild, SelfGuild) end) of
												                                               ok -> 
													   mod_daily_dict:set_special_info({UniteStatus#unite_status.guild_id, hebing}, hebing),
													   make_merge_0(UniteStatus#unite_status.guild_id, 0),
													   MeMeList = gen_server:call(mod_guild, {make_merge_1, [HbGuild#ets_guild.id, SelfGuild#ets_guild.id, SelfGuild#ets_guild.name]}, 5000),
													   make_merge_2(MeMeList, SelfGuild#ets_guild.id, SelfGuild#ets_guild.name, 5),
													   mod_daily_dict:plus_count(4000000 + UniteStatus#unite_status.guild_id, 4006101, 1),
		                                               [1];
												                                               _ ->
												                                                   [0]
												                                            end;
																						false ->
																							make_merge_0(UniteStatus#unite_status.guild_id, 0),
																							make_merge_0(HbGuildId, 1),
																							[10]
																					end;
																				false ->
																					make_merge_0(UniteStatus#unite_status.guild_id, 0),
																					make_merge_0(HbGuildId, 1),
																					[11]		
																			end;
																		false ->
																			[9]					
																	end
															end;
														_ ->
															[5]									
													end;
												_->
													[0]
											end;
										_ ->
											[0]											
									end;
								_ ->
									[0]													
							end;
						_ ->
							[0]															
					end
			end;
		true ->
			[7]																			
	end.

make_merge_0(GuildId, Type) ->
	case lib_guild:get_guild(GuildId) of
		TargetGuild when is_record(TargetGuild, ets_guild) ->
			NewTargetGuild = TargetGuild#ets_guild{merge_guild_id = 0, merge_guild_direction = 0},
			lib_guild:update_guild(NewTargetGuild),
			case Type =:= 1 of
				true ->
					{ok, BinData} = pt_400:write(40058, [0]),
					lib_unite_send:send_to_one(TargetGuild#ets_guild.chief_id, BinData);
				false ->
					skip
			end;
		_ ->
			skip
	end,
	ok.

make_merge_1(DelGuild, NewGuild) ->
	DelGuildId = DelGuild#ets_guild.id,
	NewGuildId = NewGuild#ets_guild.id,
	NewGuildName = NewGuild#ets_guild.name,
	%lib_city_war:delete_win_guild(DelGuildId),
    % (1) 更新解散帮派成员表的帮派ID，帮派名称和职位
    Data = [NewGuildId, NewGuildName, 5, DelGuildId],
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_MERGE, Data),
    db:execute(SQL),
    % (2) 更新帮派表的成员个数
    NewGuildNum  = DelGuild#ets_guild.member_num+NewGuild#ets_guild.member_num,
    Data1 = [NewGuildNum, NewGuildId],
    SQL1  = io_lib:format(?SQL_GUILD_UPDATE_MERGE, Data1),
    db:execute(SQL1),
	% (3) 删除解散帮派表
    Data2 = [DelGuildId],
    SQL2  = io_lib:format(?SQL_GUILD_DELETE, Data2),
    db:execute(SQL2),
    % (4) 删除解散帮派申请表
    Data3 = [DelGuildId],
    SQL3  = io_lib:format(?SQL_GUILD_APPLY_DELETE, Data3),
    db:execute(SQL3),
    % (5) 删除解散帮派邀请表
    Data4 = [DelGuildId],
    SQL4  = io_lib:format(?SQL_GUILD_INVITE_DELETE, Data4),
    db:execute(SQL4),
    % (6) 删除解散帮派事件表
    Data5 = [DelGuildId],
    SQL5  = io_lib:format(?SQL_GUILD_EVENT_DELETE, Data5),
    db:execute(SQL5),
    % (6) 删除帮派仓库物品(只操作数据库)
    lib_goods_util:delete_goods_by_guild(DelGuildId),
	Data6 = [DelGuildId],
	%% 删除神兽升级记录
    SQL6  = io_lib:format(?SQL_GUILD_GODANIMAL_DELETE_ONE, Data6),
    db:execute(SQL6),
	%% 删除神兽升阶记录
	SQL7  = io_lib:format(?SQL_GUILD_GA_STAGE_DELETE_ONE, Data6),
    db:execute(SQL7),
	% (7) 更新玩家表的帮派属性
	Data8 = [NewGuildId, DelGuildId],
    SQL8  = io_lib:format(?SQL_PLAYER_UPDATE_MERGE, Data8),
    db:execute(SQL8),
	ok.

make_merge_2([], _GuildId, _GuildName, _Position) ->
	ok;
make_merge_2(MeMeList, GuildId, GuildName, Position) ->
	[H|T] = MeMeList,
	lib_guild:guild_other_syn([H, GuildId, GuildName, Position]),
	[Title, Format] = data_guild_text:get_mail_text(hbyj01),
	Content = io_lib:format(Format, [GuildName]),
	lib_mail:send_sys_mail_bg([H], Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0),
	make_merge_2(T, GuildId, GuildName, Position).

%% -----------------------------------------------------------------
%% 帮主召唤
%% -----------------------------------------------------------------
gather_member2(PlayerStatus, [Content]) ->
    ContentLenValid        = util:check_length(Content, 100),
    Gs = PlayerStatus#player_status.guild,
    if  % 你没有加入任何帮派
        Gs#status_guild.guild_id == 0 -> [2, 0];
        % 你不是帮主
        Gs#status_guild.guild_position > 1 -> [3, 0];
        % 召唤内容太长
        ContentLenValid == false -> [6, 0];
        true ->
            MyScene = PlayerStatus#player_status.scene,
            CanTransport = case lists:member(MyScene, ?FORBIMAP) orelse mod_scene_agent:apply_call(MyScene, lib_scene, is_dungeon_scene, [MyScene]) of
                               true -> false;
                               false-> true
                            end,
            if  % 该场景不能传送
                CanTransport =:= false -> [4, 0];
                true ->
                    Guild   = lib_guild:get_guild(Gs#status_guild.guild_id),
                    if  % 帮派不存在
                        Guild =:= []  ->
                            [0, 0];
                        true ->
                            [GatherMemberLastTime] = [Guild#ets_guild.gather_member_lasttime],
                            GatherMemberInterval   = data_guild:get_guild_config(gather_member_interval, []),
                            NowTime                = util:unixtime(),
                            if  NowTime-GatherMemberLastTime < GatherMemberInterval ->
                                    LeftTime = GatherMemberInterval-(NowTime-GatherMemberLastTime),
                                    [7, LeftTime];
                                true ->
                                    GuildNew = Guild#ets_guild{gather_member_lasttime = NowTime},
                                    lib_guild:update_guild(GuildNew, PlayerStatus#player_status.id),
                                    [1, 0]
                            end
                    end
            end
    end.

%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 					帮派成员管理相关功能 
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 帮派成员管理_入口
%% -----------------------------------------------------------------
guild_member_contrl(UniteStatus, [TargetType, OptType, Data])->
	SelfPlayerId = UniteStatus#unite_status.id,
	Gs = lib_player:get_player_info(SelfPlayerId, guild),
	_Inf = if
		Gs =:= false -> [2];
		Gs =:= [] -> [2];
		Gs#status_guild.guild_id =:= 0 -> [2];							%% 玩家无帮派
		true -> 
    		Guild = lib_guild:get_guild(Gs#status_guild.guild_id),		%% 获取帮派信息
			if
				Guild =:= [] -> [2];										%% 判断帮派是否存在
				true ->
					case TargetType of
						0 ->%% 自己
							[GuildId|Dataleft] = Data,
							if
								Guild#ets_guild.id /= GuildId -> [4];
								true ->
									guild_member_contrl_self(UniteStatus, Guild, Gs, [OptType, Dataleft])
							end;
						1 ->%% 对其他成员
							[PlayerWho|Dataleft] = Data,
							Target_PlayerInfo = case OptType of
								40006 ->
									lib_guild_base:get_player_guild_info2_by_name(PlayerWho);
								40018 ->
									lib_guild_base:get_player_guild_info2_by_name(PlayerWho);
								_ ->
									lib_guild_base:get_player_guild_info2_by_id(PlayerWho)
							end,
							if
								Target_PlayerInfo =:= [] -> [0];				%% 目标玩家不存在
								Gs#status_guild.guild_position > 2 -> [3];		%% 对其他玩家的操作最少要副帮主
								true ->
									guild_member_contrl_others(UniteStatus, Guild, Gs, [OptType, Target_PlayerInfo, Dataleft])
							end
					end
			end
	end.

%% -----------------------------------------------------------------
%% 申请加入帮派
%% -----------------------------------------------------------------
apply_join_guild(UniteStatus, [GuildId]) ->
	PlayerId = UniteStatus#unite_status.id,
	case lib_guild:get_guild(GuildId) of
		Guild when is_record(Guild, ets_guild) ->
		    [GuildRealm, GuildName, GuildMemberNum, GuildHouseLevel, ApplySetting, AutoPassConfig] = [Guild#ets_guild.realm, Guild#ets_guild.name, Guild#ets_guild.member_num, Guild#ets_guild.house_level, Guild#ets_guild.apply_setting, Guild#ets_guild.auto_passconfig],
        [MemberCapacityThisLevel, _, _] = data_guild:get_level_info(Guild#ets_guild.level),
			  NewGuildMemberCapacity = lib_guild:calc_member_capacity(MemberCapacityThisLevel, GuildHouseLevel),
            if  % 你已经加入帮派
                UniteStatus#unite_status.guild_id /= 0 -> [3, <<>>, 0, ApplySetting];
                % 你还没有国家
                UniteStatus#unite_status.realm == 0 -> [8, <<>>, 0, ApplySetting];
                % 国家不同
                UniteStatus#unite_status.realm /= GuildRealm -> [4, <<>>, 0, ApplySetting];
                % 帮众数已满
                GuildMemberNum >=  NewGuildMemberCapacity -> [5, <<>>, 0, ApplySetting];
                % 拒绝所有申请
                ApplySetting=:=2 -> [10, <<>>, 0, ApplySetting];
                true ->
					          ApplyGuildId = case lib_guild_base:get_guild_apply_by_player_id(PlayerId, GuildId) of 
										    GuildApply when is_record(GuildApply, ets_guild_apply) ->
											      GuildApply#ets_guild_apply.guild_id;
										        _ -> 0
									  end,
                    %% 取玩家战斗力
                    CompatPower = lib_player:get_player_info(UniteStatus#unite_status.id, combat_power),
                    [MinLevel, MinPower] = 
                        case AutoPassConfig of 
                            [_MinLevel, _MinPower] -> [_MinLevel, _MinPower];
                            _ -> [0, 0]
                        end,

                    if  % 你已经申请加入该帮派
                        ApplyGuildId  == GuildId  ->
                            [6, <<>>, 0, ApplySetting];
                        UniteStatus#unite_status.lv < MinLevel orelse CompatPower < MinPower ->
                            [12, <<>>, 0, ApplySetting];
                        true ->
                            GuildApplys = lib_guild_base:get_guild_apply_by_guild_id(GuildId),
                            ApplyMaxNum = data_guild:get_guild_config(apply_max_num, []),
                            if  length(GuildApplys) >= ApplyMaxNum ->
                                        [9, <<>>, 0, ApplySetting];
                                true ->
                                    case lib_guild:add_guild_apply(PlayerId, GuildId) of
                                        ok  -> [1, GuildName, ApplyGuildId, ApplySetting];
                                        _   -> [0, <<>>, 0, ApplySetting]
                                    end
                            end
                    end
            end;
		_ ->
			[2, <<>>, 0]
	end.


del_guild_apply(UniteStatus, GuildId) ->
	PlayerId = UniteStatus#unite_status.id,
	case lib_guild_base:get_guild_apply_by_player_id(PlayerId, GuildId) of 
		GuildApply when is_record(GuildApply, ets_guild_apply) ->
			lib_guild:remove_guild_apply(PlayerId, GuildId),
			1;
		_ -> 
			2
	end.

%% -----------------------------------------------------------------
%% 回应帮派邀请
%% -----------------------------------------------------------------
response_invite_guild(UniteStatus, [GuildId, ResponseResult]) ->
    Guild = lib_guild:get_guild(GuildId),
	PlayerId = UniteStatus#unite_status.id,
    if  % 帮派不存在
        Guild =:= [] -> [2, <<>>, 0, 0];
        true ->
            [GuildName, GuildMemberNum, GuildHouseLevel] = [Guild#ets_guild.name, Guild#ets_guild.member_num, Guild#ets_guild.house_level],
            [MemberCapacityThisLevel, _, _] = data_guild:get_level_info(Guild#ets_guild.level),
			NewGuildMemberCapacity = lib_guild:calc_member_capacity(MemberCapacityThisLevel, GuildHouseLevel),
            GuildInvite = lib_guild_base:get_guild_invite_by_player_id(PlayerId, GuildId),
            if  % 你不在邀请列表
                GuildInvite =:= [] -> [3, <<>>, 0, 0];
                % 同意加入但已经拥有帮派
                ((UniteStatus#unite_status.guild_id /= 0) and (ResponseResult == 1)) -> [4, <<>>, 0, 0];
                % 同意加入但帮众数已满
                ((GuildMemberNum >= NewGuildMemberCapacity) and (ResponseResult == 1)) -> [5, <<>>, 0, 0];
                % 拒绝加入
                ResponseResult == 0 ->
                    % 从邀请列表中删除
                    case lib_guild:remove_guild_invite(PlayerId, GuildId) of
                         ok -> [1, <<>>, 0, 0];
                         _  -> [0, <<>>, 0, 0]
                    end;
                % 允许加入
                true ->
                    DefaultPostion = data_guild:get_guild_config(default_position, []),
                    NewGuildMemberNum = GuildMemberNum+1,
					GuildLv = Guild#ets_guild.level,
                    case lib_guild:add_guild_member(PlayerId, UniteStatus#unite_status.name, GuildId, GuildName, GuildLv, DefaultPostion, NewGuildMemberNum) of
                        ok ->
                            %% 更新玩家GUILD信息
                            lib_guild:add_guild_member_award(Guild, NewGuildMemberNum),
                            % 发送通知
                            lib_guild:send_one(UniteStatus#unite_status.id, 'guild_new_member', [UniteStatus#unite_status.id
																								  , UniteStatus#unite_status.name
																								  , GuildId
																								  , GuildName
																								  , DefaultPostion
																								  , Guild#ets_guild.level
																								  , UniteStatus#unite_status.career
																								  , UniteStatus#unite_status.sex
																								  , UniteStatus#unite_status.image
																								  , UniteStatus#unite_status.lv]),
                            [1, GuildName, DefaultPostion, Guild#ets_guild.level];
                        _  -> [0, <<>>, 0, 0]
                    end
            end
    end.

%% -----------------------------------------------------------------
%% 获取邀请列表
%% -----------------------------------------------------------------
list_guild_invite(_Status, [PlayerId, PageSize, PageNo]) ->
    lib_guild:get_guild_invite_page(PlayerId, PageSize, PageNo).

%% -----------------------------------------------------------------
%% 获取申请列表  更换为传输PlayerStatus,原来是_Status
%% -----------------------------------------------------------------
list_guild_apply(_Status, [GuildId, PageSize, PageNo]) ->
    lib_guild:get_guild_apply_page(GuildId, PageSize, PageNo).

%% -----------------------------------------------------------------
%% 获取成员列表 更换为传输PlayerStatus,原来是_Status0 
%% -----------------------------------------------------------------
list_guild_member(_Status, [GuildId, PageSize, PageNo, Type]) ->
    lib_guild:get_guild_member_page(GuildId, PageSize, PageNo, Type).

%% -----------------------------------------------------------------
%% 帮派成员管理_对他人的操作_基本判断,目标是否存在判断
%% -----------------------------------------------------------------
guild_member_contrl_others(UniteStatus, GuildSelf, GsPlayer, [OptType, Target_PlayerInfo, Dataleft]) ->
	_BaseReturn = case OptType of
		40005 ->
			%% 审批申请加入帮派
			handle_apply_guild(UniteStatus, GuildSelf, GsPlayer, [Target_PlayerInfo, Dataleft]);
		40006 ->
			%% 邀请他人加入帮派
			invite_join_guild(UniteStatus, GuildSelf, GsPlayer, [Target_PlayerInfo, Dataleft]);
		40008 ->
			%% 踢出帮派 
			kickout_guild(UniteStatus, GuildSelf, GsPlayer, [Target_PlayerInfo, Dataleft]);
		40025 ->
			%% 授予头衔
			give_tile(UniteStatus, GuildSelf, GsPlayer, [Target_PlayerInfo, Dataleft]);
		40017 ->
			%% 职位设置
			set_position(UniteStatus, GuildSelf, GsPlayer, [Target_PlayerInfo, Dataleft]);
		40018 ->
			%% 帮主转让帮派
			demise_chief(UniteStatus, GuildSelf, GsPlayer, [Target_PlayerInfo, Dataleft])
	end.

%% 审批申请加入帮派
handle_apply_guild(_UniteStatus, GuildSelf, GsPlayer, [Target_PlayerInfo, Dataleft]) ->
    [PlayerId, PlayerNickname, _, PlayerCarrer, PlayerSex, PlayerImage, PlayerLv, PlayerGuildId, _, _]
	= Target_PlayerInfo,
	[GuildMemberNum, GuildMemberCapacity, _GuildHouseLevel]
	= [GuildSelf#ets_guild.member_num, GuildSelf#ets_guild.member_capacity, GuildSelf#ets_guild.house_level],
    NewGuildMemberCapacity = GuildMemberCapacity,
	[HandleResult] = Dataleft,
	GuildApply = case lib_guild_base:get_guild_apply_by_player_id(PlayerId, GuildSelf#ets_guild.id) of 
						R when is_record(R, ets_guild_apply) ->
								R;
						_R -> 	[]
				 end,
	if  
    	GuildApply =:= [] -> [5, [<<>>, 0, 0, 0, 0, 0]];									%% 不在申请列表
		HandleResult == 0 ->										%% 拒绝申请列表_从申请列表中删除
             case lib_guild:remove_guild_apply(PlayerId, GsPlayer#status_guild.guild_id) of
                 ok -> [1, [<<>>, 0, 0, 0, 0, 0]];
                 _  -> [0, [<<>>, 0, 0, 0, 0, 0]]
             end;
		GuildMemberNum >=  NewGuildMemberCapacity -> [7, [<<>>, 0, 0, 0, 0, 0]];			%% 人数已满
		((PlayerGuildId /= 0) and (HandleResult == 1)) -> [6, [<<>>, 0, 0, 0, 0, 0]];
		true ->
			 DefaultPostion    = data_guild:get_guild_config(default_position, []),
             NewGuildMemberNum = GuildMemberNum + 1,
			 GuildLv = GuildSelf#ets_guild.level,
             case lib_guild:add_guild_member(PlayerId, PlayerNickname, GsPlayer#status_guild.guild_id, GsPlayer#status_guild.guild_name, GuildLv, DefaultPostion,NewGuildMemberNum) of
                 ok ->
                     %% 更新缓存
					 GStatus = #status_guild{guild_id = GsPlayer#status_guild.guild_id
											, guild_name = GsPlayer#status_guild.guild_name
											, guild_lv = GuildLv, guild_position = DefaultPostion},
					 lib_player:update_player_info(PlayerId, [{guild, GStatus}]),
                     lib_guild:add_guild_member_award(GuildSelf, NewGuildMemberNum),
                     %% 发送通知
                     lib_guild:send_one(PlayerId, 'guild_new_member', [PlayerId, PlayerNickname, GsPlayer#status_guild.guild_id, GsPlayer#status_guild.guild_name, DefaultPostion, GsPlayer#status_guild.guild_lv, PlayerCarrer, PlayerSex, PlayerImage, PlayerLv]),
					 %% 更新玩家公共线GUILD_ID
					 case mod_chat_agent:lookup(PlayerId) of
						[] ->
							[];
						[Player] ->
							mod_chat_agent:insert(Player#ets_unite{
					            guild_id = GuildSelf#ets_guild.id,
					            guild_name = GuildSelf#ets_guild.name,
					            guild_position = DefaultPostion
					        }),
							lib_player:update_unite_info(Player#ets_unite.pid, [{guild_id, GuildSelf#ets_guild.id}
																			   ,{guild_name, GuildSelf#ets_guild.name}
																			   ,{guild_position, DefaultPostion}])
					 end,
                     [1, [PlayerNickname, 5, PlayerCarrer, PlayerSex, PlayerImage, PlayerLv]];
                 _  ->
                     [0, [<<>>, 0, 0, 0, 0, 0]]
             end                                    
	end.

%% 邀请加入帮派
invite_join_guild(UniteStatus, GuildSelf, GsPlayer, [Target_PlayerInfo, _Dataleft]) ->
	DNum = mod_daily_dict:get_count(UniteStatus#unite_status.id, 40006001),
	[PlayerId, _, PlayerRealm, _, _, _, _, PlayerGuildId, _, _]
	= Target_PlayerInfo,
	[GuildMemberNum, GuildHouseLevel]
	= [GuildSelf#ets_guild.member_num, GuildSelf#ets_guild.house_level],
    [MemberCapacityThisLevel, _, _] = data_guild:get_level_info(GuildSelf#ets_guild.level),
	NewGuildMemberCapacity = lib_guild:calc_member_capacity(MemberCapacityThisLevel, GuildHouseLevel),
	%% 对3级一下帮派邀请做出限制
	case DNum > 50 andalso GuildSelf#ets_guild.level < 3 of
		true ->
			[0, 0];
		false ->
		    if  
				PlayerGuildId /= 0 -> [5, 0];% 对方已经拥有帮派
		        PlayerRealm == 0 -> [9, 0]; % 对方还没有国家
		        PlayerRealm /= UniteStatus#unite_status.realm -> [6, 0];% 国家不同
		        GuildMemberNum >=  NewGuildMemberCapacity -> [7, 0];% 帮众数已满
		        true ->
		            GuildInvite = lib_guild_base:get_guild_invite_by_player_id(PlayerId, GsPlayer#status_guild.guild_id),
		            if  % 已邀请过
		                GuildInvite =/= [] -> [8, 0];
		                true ->
		                    case lib_guild:add_guild_invite(PlayerId, GsPlayer#status_guild.guild_id) of
		                        ok  -> [1, PlayerId];
		                        _   -> [0, 0]
		                    end
		            end
		    end
	end.

%% 踢出帮派_踢出帮派场景
kickout_guild(UniteStatus, GuildSelf, GsPlayer, [Target_PlayerInfo, _Dataleft]) ->
	SelfPlayerId = UniteStatus#unite_status.id,
	[PlayerId, PlayerNickname, _, _, _, _, _, PlayerGuildId, _, PlayerGuildPosition]	
	= Target_PlayerInfo,
	GuildMemberNum = GuildSelf#ets_guild.member_num,
	[DeputyChiefId1, DeputyChiefId2, DeputyChiefNum]
	= [GuildSelf#ets_guild.deputy_chief1_id, GuildSelf#ets_guild.deputy_chief2_id, GuildSelf#ets_guild.deputy_chief_num],
    if  
        PlayerId == SelfPlayerId -> [4, <<>>, 0];					% 不能T自己
		PlayerGuildId == 0 -> [6, <<>>, 0];											% 对方没有帮派
        PlayerGuildId /= GsPlayer#status_guild.guild_id -> [7, <<>>, 0];					% 对方不是本帮成员
        PlayerGuildPosition =< GsPlayer#status_guild.guild_position -> [8, <<>>, 0]; 		% 对方职位不在你之下
        true ->
            NewGuildMemberNum = GuildMemberNum - 1,
            case db:transaction(fun() ->lib_guild:remove_guild_member(PlayerId, GsPlayer#status_guild.guild_id, NewGuildMemberNum) end) of
                ok ->
				    lib_guild_base:delete_guild_member_by_player_id(PlayerId),
                    case PlayerId == DeputyChiefId1 of
                        true ->
                            GuildNew = GuildSelf#ets_guild{member_num         = NewGuildMemberNum,
                                                       deputy_chief_num   = DeputyChiefNum -1,
                                                       deputy_chief1_id   = 0,
                                                       deputy_chief1_name = <<>>},
                            lib_guild:update_guild(GuildNew, SelfPlayerId);
                        false when PlayerId == DeputyChiefId2 ->
                            GuildNew = GuildSelf#ets_guild{member_num         = NewGuildMemberNum,
                                                       deputy_chief_num   = DeputyChiefNum -1,
                                                       deputy_chief2_id   = 0,
                                                       deputy_chief2_name = <<>>},
                            lib_guild:update_guild(GuildNew, SelfPlayerId);
                        false ->
                            GuildNew = GuildSelf#ets_guild{member_num = NewGuildMemberNum},
                            lib_guild:update_guild(GuildNew, SelfPlayerId)
                    end,
                    [1, PlayerNickname, PlayerGuildPosition];
                _  ->
                    [0, <<>>, 0]
            end
	end.

%% 授予头衔
give_tile(_UniteStatus, _GuildSelf, GsPlayer, [Target_PlayerInfo, Dataleft]) ->
	[PlayerId, PlayerNickname, _, _, _, _, _, PlayerGuildId, _, _]
	= Target_PlayerInfo,
    [Title] = Dataleft,
	if  
        GsPlayer#status_guild.guild_position > 1;							%% 帮主才能操作
		PlayerGuildId == 0 -> [6, <<>>];							%% 对方没有帮派
        PlayerGuildId /= GsPlayer#status_guild.guild_id -> [7, <<>>];		%% 对方不是本帮成员
        true ->
            case lib_guild:give_title(PlayerId, Title) of
                ok ->
                    GuildMember    = lib_guild_base:get_guild_member_by_player_id(PlayerId),
                    TitleBin       = util:make_sure_binary(Title),
                    GuildMemberNew = GuildMember#ets_guild_member{title = TitleBin},
                    lib_guild_base:update_guild_member(GuildMemberNew),
                    [1, PlayerNickname];
                _ ->
                    [0, <<>>]
            end
    end.

%% 职位设置
set_position(UniteStatus, GuildSelf, GsPlayer, [Target_PlayerInfo, Dataleft]) ->
	SelfPlayerId = UniteStatus#unite_status.id,
	[PlayerId, PlayerNickname, _, _, _, _, _, PlayerGuildId, _, PlayerGuildPosition]
	= Target_PlayerInfo,
	[DeputyChiefId1, DeputyChiefId2, DeputyChiefNum]
	= [GuildSelf#ets_guild.deputy_chief1_id, GuildSelf#ets_guild.deputy_chief2_id, GuildSelf#ets_guild.deputy_chief_num],
    [GuildPosition] = Dataleft,
	if  
		PlayerId == SelfPlayerId  -> [4, <<>>, 0];% 不能自封职位
		GuildPosition =< GsPlayer#status_guild.guild_position -> [5, <<>>, 0];% 你要设置的职位不比你的低
        PlayerGuildId == 0 -> [7, <<>>, 0];% 对方没有帮派
        PlayerGuildId /= GsPlayer#status_guild.guild_id -> [8, <<>>, 0];% 对方不是本帮成员
        PlayerGuildPosition =< GsPlayer#status_guild.guild_position -> [9, <<>>, 0];% 对方职位不比你低
        ((PlayerGuildPosition > GuildPosition) and (GuildPosition == 2) and (DeputyChiefId1 > 0 andalso DeputyChiefId2 > 0)) -> [10, <<>>, 0]; % 副帮主个数已满
        PlayerGuildPosition == GuildPosition -> [1, PlayerNickname, PlayerGuildPosition]; % 职位没有改变
        true ->
			%% no transaction
            case lib_guild:set_position(PlayerId, GuildPosition) of
                ok  ->
                    case ((PlayerId == DeputyChiefId1) and (GuildPosition /= 2)) of
                        true ->
                            GuildNew = GuildSelf#ets_guild{deputy_chief_num   = DeputyChiefNum-1,
                                                       deputy_chief1_id   = 0,
                                                       deputy_chief1_name = <<>>},
                            lib_guild:update_guild(GuildNew, SelfPlayerId);
                        false when ((PlayerId == DeputyChiefId2) and (GuildPosition /= 2)) ->
                            GuildNew = GuildSelf#ets_guild{deputy_chief_num   = DeputyChiefNum-1,
                                                       deputy_chief2_id   = 0,
                                                       deputy_chief2_name = <<>>},
                            lib_guild:update_guild(GuildNew, SelfPlayerId);
                        false when ((DeputyChiefId1 == 0) and (GuildPosition == 2)) ->
                            GuildNew = GuildSelf#ets_guild{deputy_chief_num   = DeputyChiefNum+1,
                                                       deputy_chief1_id   = PlayerId,
                                                       deputy_chief1_name = util:make_sure_binary(PlayerNickname)},
                            lib_guild:update_guild(GuildNew, SelfPlayerId);
                       false when ((DeputyChiefId2 == 0) and (GuildPosition == 2)) ->
                             GuildNew = GuildSelf#ets_guild{deputy_chief_num   = DeputyChiefNum+1,
                                                       deputy_chief2_id   = PlayerId,
                                                       deputy_chief2_name = util:make_sure_binary(PlayerNickname)},
                           lib_guild:update_guild(GuildNew, SelfPlayerId);
                        false ->
                            void
                    end,
                    [1, PlayerNickname, PlayerGuildPosition];
                _  -> [0, <<>>, 0]
            end
    end.

%% 帮主转让帮派
demise_chief(UniteStatus, GuildSelf, GsPlayer, [Target_PlayerInfo, _Dataleft]) ->
	SelfPlayerId = UniteStatus#unite_status.id,
	[PlayerId, PlayerNickname, _, _, _, _, _, PlayerGuildId, _, PlayerGuildPosition]
	= Target_PlayerInfo,
    if  
		GsPlayer#status_guild.guild_position /= 1 -> [3, 0, 0];% 你不是帮主
    	PlayerId == SelfPlayerId  -> [4, 0, 0];% 不能禅让给自己
		PlayerGuildId /= GsPlayer#status_guild.guild_id -> [6, 0, 0];% 对方不是本帮成员
		true ->
			case lib_guild:demise_chief(SelfPlayerId, PlayerId, PlayerNickname, GsPlayer#status_guild.guild_id) of
				ok ->
					GuildNew = case PlayerId =:= GuildSelf#ets_guild.deputy_chief1_id of
						true ->
							 GuildSelf#ets_guild{chief_id           = PlayerId,
												chief_name         = util:make_sure_binary(PlayerNickname),
												deputy_chief_num   = GuildSelf#ets_guild.deputy_chief_num-1,
                                                deputy_chief1_id   = 0,
                                                deputy_chief1_name = <<>>};
						false when (PlayerId =:= GuildSelf#ets_guild.deputy_chief2_id) ->
							 GuildSelf#ets_guild{chief_id           = PlayerId,
												chief_name         = util:make_sure_binary(PlayerNickname),
												deputy_chief_num   = GuildSelf#ets_guild.deputy_chief_num-1,
                                                deputy_chief2_id   = 0,
                                                deputy_chief2_name = <<>>};
						false ->
							 GuildSelf#ets_guild{chief_id           = PlayerId,
												chief_name         = util:make_sure_binary(PlayerNickname)}
					end,
					lib_guild:update_guild(GuildNew, SelfPlayerId),
					[1, PlayerId, PlayerGuildPosition];
				_ ->
					[0, 0, 0]
			end
	end.


%% -----------------------------------------------------------------
%% 帮派成员管理_对自己的操作
%% -----------------------------------------------------------------
guild_member_contrl_self(UniteStatus, GuildSelf, GsPlayer, [OptType, Dataleft])->
	SelfPlayerId = UniteStatus#unite_status.id,
	_BaseReturn = case OptType of
		40009 ->
			if
				GsPlayer#status_guild.guild_position < 2 -> [5];
				true ->
					NewGuildMemberNum = GuildSelf#ets_guild.member_num - 1,
					case db:transaction(fun() ->lib_guild:remove_guild_member(SelfPlayerId, GsPlayer#status_guild.guild_id, NewGuildMemberNum) end) of
						ok ->
						    lib_guild_base:delete_guild_member_by_player_id(SelfPlayerId),
							GuildNew = case SelfPlayerId == GuildSelf#ets_guild.deputy_chief1_id of		%% 更新缓存
								true ->
									GuildSelf#ets_guild{member_num         = NewGuildMemberNum,
															   deputy_chief_num   = GuildSelf#ets_guild.deputy_chief_num -1,
															   deputy_chief1_id   = 0,
															   deputy_chief1_name = <<>>};
								false when SelfPlayerId == GuildSelf#ets_guild.deputy_chief2_id ->
									GuildSelf#ets_guild{member_num         = NewGuildMemberNum,
															   deputy_chief_num   = GuildSelf#ets_guild.deputy_chief_num -1,
															   deputy_chief2_id   = 0,
															   deputy_chief2_name = <<>>};
								false ->
									GuildSelf#ets_guild{member_num = NewGuildMemberNum}
							end,
							lib_guild:update_guild(GuildNew, SelfPlayerId),
							[1];
						_ ->
							[0]
					end
			end;
		40022 ->
			DefautPosition = data_guild:get_guild_config(default_position, []),
			if
				GsPlayer#status_guild.guild_position == DefautPosition -> [4, GsPlayer#status_guild.guild_position];	%% 你没有官职
				GsPlayer#status_guild.guild_position == 1 -> [5, GsPlayer#status_guild.guild_position];					%% 帮主不能辞去官职
				true ->
					%% no transaction
					case lib_guild:set_position(SelfPlayerId, DefautPosition) of
						ok ->
							case SelfPlayerId == GuildSelf#ets_guild.deputy_chief1_id of
								true ->
									GuildNew = GuildSelf#ets_guild{deputy_chief_num   = GuildSelf#ets_guild.deputy_chief_num-1,
															   deputy_chief1_id   = 0,
															   deputy_chief1_name = <<>>},
									lib_guild:update_guild(GuildNew, SelfPlayerId);
								false when SelfPlayerId == GuildSelf#ets_guild.deputy_chief2_id ->
									GuildNew = GuildSelf#ets_guild{deputy_chief_num   = GuildSelf#ets_guild.deputy_chief_num-1,
															   deputy_chief2_id   = 0,
															   deputy_chief2_name = <<>>},
									lib_guild:update_guild(GuildNew, SelfPlayerId);
								false ->
									void
							end,
							[1, DefautPosition];
						_  ->  [0, GsPlayer#status_guild.guild_position]
					end
			end;
		40026 ->
			[Remark] = Dataleft,
			RemarkLenValid        = util:check_length(Remark, 100),
			RemarkContentInValid  = util:check_keyword(Remark),
			if
				RemarkLenValid == false -> [4];						%% 个人备注长度非法
				RemarkContentInValid == true -> [5];					%% 个人备注内容非法
				true ->
					case lib_guild:modify_remark(SelfPlayerId, Remark) of
						ok ->
							GuildMember    = lib_guild_base:get_guild_member_by_player_id(SelfPlayerId),
							RemarkBin      = util:make_sure_binary(Remark),
							GuildMemberNew = GuildMember#ets_guild_member{remark = RemarkBin},
							lib_guild_base:update_guild_member(GuildMemberNew),
							[1];
						_ ->  [0]
					end
			end
	end.

%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 					帮派建筑物相关功能 
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 获取仓库物品列表
%% -----------------------------------------------------------------
list_depot_goods(_UniteStatus, [GuildId]) ->
    lib_guild:list_depot_goods(GuildId).

%% -----------------------------------------------------------------
%% 帮派仓库存入物品
%% -----------------------------------------------------------------
store_into_depot(UniteStatus, [GuildId, GoodsId, GoodsNum]) ->
	SelfPlayerId = UniteStatus#unite_status.id,
    case lib_player:get_player_info(SelfPlayerId, goods) of
		Go when is_record(Go, status_goods) ->
		    if   
		         UniteStatus#unite_status.guild_id == 0 -> 2;
		         UniteStatus#unite_status.guild_id /= GuildId  -> 3;
		         true ->
					 case lib_guild:get_guild(GuildId) of
						 Guild when is_record(Guild, ets_guild) ->
							 case lib_guild_base:get_guild_member_by_player_id(SelfPlayerId) of
								 GuildMember when is_record(GuildMember, ets_guild_member) ->
									 [StoreLastTime, StoreNum] = [GuildMember#ets_guild_member.depot_store_lasttime
																 , GuildMember#ets_guild_member.depot_store_num],
				                     MaxStoreNum = data_guild:get_guild_config(depot_max_store_num, []),
				                     NowTime = util:unixtime(),
				                     IsSameDate = util:is_same_date(NowTime, StoreLastTime),
				                     if  
				                         ((UniteStatus#unite_status.guild_position > 2) and (IsSameDate == true) and (StoreNum >= MaxStoreNum)) ->
				                             5;
				                         true ->
				                             DepotLevel = Guild#ets_guild.depot_level,
				                             [CellNum, _UpgradeFunds, _UpgradeContribution] = data_guild:get_depot_info(DepotLevel),
				                             case gen_server:call(Go#status_goods.goods_pid, {'movein_guild', GuildId, CellNum, GoodsId, GoodsNum}) of
				                                 ok ->
				                                     NewStoreNum = case IsSameDate of
				                                                       true  -> StoreNum+1;
				                                                       false -> 1
				                                                   end,
				                                     case lib_guild:store_into_depot(SelfPlayerId, NowTime, NewStoreNum) of
				                                         ok ->
				                                             GuildMemberNew = GuildMember#ets_guild_member{depot_store_lasttime  = NowTime,
				                                                                                           depot_store_num       = NewStoreNum},
				                                             lib_guild_base:update_guild_member(GuildMemberNew),
				                                             1;
				                                         _  -> 0
				                                     end;
				                                 {fail, ResultCode} ->
				                                     case ResultCode of
				                                         0 -> 0;
				                                         % 物品或者物品类型不存在
				                                         2 -> 6;
				                                         % 物品不属于你所有
				                                         3 -> 7;
				                                         % 物品不在背包
				                                         4 -> 8;
				                                         % 物品数量不正确
				                                         5 -> 9;
				                                         % 绑定物品不可存入
				                                         6 -> 10;
				                                         % 帮派仓库格子不足
				                                         7 -> 11;
				                                         % 物品正在交易
				                                         8 -> 12;
				                                         % 其他类型
				                                         _ -> 0
				                                     end
				                             end
				                     end;
								 _ -> 
									?ERR("store_into_depot: guild member not found, id=[~p]", [SelfPlayerId]),
		                     		0
							 end;
						 _ ->% 帮派不存在
							 ?ERR("store_into_depot: guild not found, id=[~p]", [GuildId]),
		                     4
					 end
		    end;
		_ ->
			0
	end.

%% -----------------------------------------------------------------
%% 帮派仓库取出物品
%% -----------------------------------------------------------------
take_out_depot(UniteStatus, [GuildId, GoodsId, GoodsNum, GoodsName]) ->
	SelfPlayerId = UniteStatus#unite_status.id,
    case lib_player:get_player_info(SelfPlayerId, goods) of
		Go when is_record(Go, status_goods) ->
		    if   % 你没有加入任何帮派
		         UniteStatus#unite_status.guild_id == 0 -> [2, 0];
		         UniteStatus#unite_status.guild_id /= GuildId  -> [3, 0];
		         true ->
		             Guild       = lib_guild:get_guild(GuildId),
		             GuildMember = lib_guild_base:get_guild_member_by_player_id(SelfPlayerId),
					 case lib_guild:get_guild(GuildId) of
						 Guild when is_record(Guild, ets_guild) ->
							 case lib_guild_base:get_guild_member_by_player_id(SelfPlayerId) of
								 GuildMember when is_record(GuildMember, ets_guild_member) ->
									 Donation        = GuildMember#ets_guild_member.donate,
				                     TakeOutDonation = data_guild:get_guild_config(depot_take_out_donation, []),
				                     if  
				                         Donation < TakeOutDonation ->
				                             [10, 0];
				                         true ->
				                             case gen_server:call(Go#status_goods.goods_pid, {'moveout_guild', GuildId, GoodsId, GoodsNum}) of
				                                 {ok, GoodsTypeInfo} ->
													%% 记录帮派事件
										            lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 17
																			 , [UniteStatus#unite_status.id
																			   , UniteStatus#unite_status.name
																			   , UniteStatus#unite_status.guild_position
																			   , GoodsTypeInfo, GoodsName, GoodsNum]),
				                                     NewDonation = Donation-TakeOutDonation,
				                                     case lib_guild:take_out_depot(SelfPlayerId, NewDonation) of
				                                         ok ->
				                                             GuildMemberNew = GuildMember#ets_guild_member{donate  = NewDonation},
				                                             lib_guild_base:update_guild_member(GuildMemberNew),
				                                             [1, TakeOutDonation];
				                                         _  ->
				                                             [0, 0]
				                                     end;
				                                 {fail, ResultCode} ->
				                                     case ResultCode of
				                                         0 -> [0, 0];
				                                         % 物品或者物品类型不存在
				                                         2 -> [5, 0];
				                                         % 物品不属于帮派所有
				                                         3 -> [6, 0];
				                                         % 物品不在帮派仓库
				                                         4 -> [7, 0];
				                                         % 物品数量不正确
				                                         5 -> [8, 0];
				                                         % 背包格子不足
				                                         6 -> [9, 0];
				                                         % 物品正在交易中
				                                         8 -> [11, 0];
				                                         % 其他类型错误
				                                         _ -> [0, 0]
				                                    end
				                             end
				                    end;        
								 _ -> % 成员信息不存在
									?ERR("take_out_depot: guild member not found, id=[~p]", [SelfPlayerId]),
		                     		[0, 0]
							 end;
						 _ ->% 帮派不存在
							 ?ERR("take_out_depot: guild not found, id=[~p]", [GuildId]),
		                     [4, 0]
					 end
		    end;
		_ ->
			[0, 0]
	end.

%% -----------------------------------------------------------------
%% 帮派仓库删除物品
%% -----------------------------------------------------------------
delete_from_depot(UniteStatus, [GuildId, GoodsId, _GoodsNum]) ->
	SelfPlayerId = UniteStatus#unite_status.id,
    case lib_player:get_player_info(SelfPlayerId, goods) of
		Go when is_record(Go, status_goods) -> 
		    if   % 你没有加入任何帮派
		         UniteStatus#unite_status.guild_id == 0 -> 2;
		         UniteStatus#unite_status.guild_id /= GuildId  -> 3;
		         UniteStatus#unite_status.guild_position > 2   -> 4;
		         true ->
		             Guild       = lib_guild:get_guild(GuildId),
		             if  
		                 Guild =:= [] ->
		                     ?ERR("delete_from_depot: guild not found, id=[~p]", [GuildId]),
		                     5; 
		                 true ->
		                     case gen_server:call(Go#status_goods.goods_pid, {'delete_guild', GuildId, GoodsId}) of
		                         ok ->
		                             1;
		                         {fail, ResultCode} ->
		                             case ResultCode of
		                                 0 -> 0;
		                                 % 物品不存在
		                                 2 -> 6;
		                                 % 物品不属于帮派所有
		                                 3 -> 7;
		                                 % 物品不在帮派仓库
		                                 4 -> 8;
		                                 % 物品不可丢弃
		                                 5 -> 9;
		                                 % 其他类型错误
		                                 _ -> 0
		                             end
		                     end
		             end
		    end;
		_ ->
			0
	end.



%% -----------------------------------------------------------------
%% 升级建筑 XF_ONLY
%% -----------------------------------------------------------------
upgrade_build(UniteStatus, [GuildId, BuildType, Sid]) ->
	SelfPlayerId = UniteStatus#unite_status.id,
	if
		UniteStatus#unite_status.guild_id == 0 -> 
			[2, 0, 0, 0, <<>>];%% 你没有加入任何帮派
        UniteStatus#unite_status.guild_id /= GuildId  -> 
			[3, 0, 0, 0, <<>>];%% 你不是该帮派成员
		true ->
			Guild = lib_guild_base:get_guild(UniteStatus#unite_status.guild_id),
			if  
	            Guild =:= []  ->
					[5, 0, 0, 0, <<>>];% 帮派不存在
				true ->
					[GuildLevel, Contribution, Funds] = [Guild#ets_guild.level, Guild#ets_guild.contribution, Guild#ets_guild.funds],
					Builds_Level = [Guild#ets_guild.furnace_level
						, Guild#ets_guild.mall_level
						, Guild#ets_guild.depot_level
						, Guild#ets_guild.altar_level
						, Guild#ets_guild.house_level],
					PositionLimit = UniteStatus#unite_status.guild_position,
					case BuildType =< length(Builds_Level) of
						false ->
							[5, 0, 0, 0, <<>>];
						true ->
							Build_Level = lists:nth(BuildType, Builds_Level),
							New_Build_Level = Build_Level + 1,
							Build_Info = data_guild:get_build_info(Build_Level, BuildType, 0),
							Guild_Dict_Name = "Dict_Ls"++integer_to_list(GuildId),
							[ComInf_S, ComInf, Data_P] = case BuildType of	
								1 ->%% 神炉__只比较_权限_等级_资金_建设度
									[_ProbabilityAdd, UpgradeFunds, UpgradeContribution] = Build_Info,
									NewContribution = Contribution - UpgradeContribution,
									NewFunds = Funds - UpgradeFunds,
									Guild_Dict = Guild#ets_guild{furnace_level = New_Build_Level,contribution = NewContribution,funds = NewFunds},
									put(Guild_Dict_Name, Guild_Dict),
									[  [1, GuildLevel, UpgradeFunds, UpgradeContribution, 0]
									 , [PositionLimit, New_Build_Level, Funds, Contribution, 0]
									 , [New_Build_Level, NewContribution, NewFunds, GuildId]];
								2 ->%% 商城_只比较_权限_等级_资金_建设度
									[UpgradeContribution, UpgradeFunds] = Build_Info,
									NewContribution = Contribution - UpgradeContribution,
									NewFunds = Funds - UpgradeFunds, 
									NewMallContri = Guild#ets_guild.mall_contri,
									Guild_Dict = Guild#ets_guild{mall_level = New_Build_Level,contribution = NewContribution,funds = NewFunds,mall_contri = NewMallContri},
									put(Guild_Dict_Name, Guild_Dict),
									[  [2, GuildLevel, UpgradeFunds, UpgradeContribution, 0]
									 , [PositionLimit, New_Build_Level, Funds, Contribution, 0]
									 , [New_Build_Level, NewMallContri, NewContribution, NewFunds, GuildId]];
								3 ->%% 仓库__只比较_权限_等级_资金_建设度
									[_CellNum, UpgradeFunds, UpgradeContribution] = Build_Info,
									NewContribution = Contribution - UpgradeContribution,
									NewFunds = Funds - UpgradeFunds,
									Guild_Dict = Guild#ets_guild{depot_level  = New_Build_Level,contribution = NewContribution,funds = NewFunds},
									put(Guild_Dict_Name, Guild_Dict),
									[  [1, GuildLevel, UpgradeFunds, UpgradeContribution, 0]
									 , [PositionLimit, New_Build_Level, Funds, Contribution, 0]
									 , [New_Build_Level, NewContribution, NewFunds, GuildId]];
								4 ->%% 祭坛__只比较_权限_等级_资金_建设度 Daily_Type_ID, Level, Num, MaterialCost, Coin, Contribution
									[_DailyId, _AltarLevel, _UseTimes, _CostFunds, UpgradeFunds, UpgradeContribution] = Build_Info,
									NewContribution = Contribution - UpgradeContribution,
									NewFunds = Funds - UpgradeFunds,
									Guild_Dict = Guild#ets_guild{altar_level  = New_Build_Level,contribution = NewContribution,funds = NewFunds},
									put(Guild_Dict_Name, Guild_Dict),
									[  [1, GuildLevel, UpgradeFunds, UpgradeContribution, 0]
									 , [PositionLimit, New_Build_Level, Funds, Contribution, 0]
									 , [New_Build_Level, NewContribution, NewFunds, GuildId]];
								5 ->%% 厢房升级_只比较权限_等级_元宝
									[MaxHouseLevel, UpgradeGold] = Build_Info,
									PlayerId = SelfPlayerId,
									NowGold = lib_player:get_player_info(PlayerId, gold),
									GoldLeft = NowGold - UpgradeGold,
									[MemberCapacityThisLevel, _, _] = data_guild:get_level_info(Guild#ets_guild.level),
									NewGMCapacity = lib_guild:calc_member_capacity(MemberCapacityThisLevel, New_Build_Level),
									Guild_Dict = Guild#ets_guild{house_level = New_Build_Level, member_capacity = NewGMCapacity},
									put(Guild_Dict_Name, Guild_Dict),
									[  [3, MaxHouseLevel, 0, 0, UpgradeGold]
									 , [PositionLimit, New_Build_Level, 0, 0, NowGold]
									 , [[New_Build_Level, GuildId],[GoldLeft, PlayerId], UpgradeGold, Sid]]
							end,
							case lib_guild:compare_build_upgrade(ComInf_S, ComInf) of
								all_pass ->
									case lib_guild:upgrade_build(GuildId, BuildType, Data_P, New_Build_Level) of
										ok-> %%升级成功_普通建筑;
											case erase(Guild_Dict_Name) of
												undefined ->
													[0, 0, 0, 0, <<>>];
												GuildNew ->
													lib_guild:update_guild(GuildNew, SelfPlayerId),
													lib_guild:log_guild_event(GuildId, 20+BuildType, [Build_Level, New_Build_Level]),
													[_, _, FundsCost, ContributionCost, _] = ComInf_S,
													InfoPakage = [FundsCost, ?SEPARATOR_STRING, ContributionCost], 
													[1, 0, Build_Level, New_Build_Level, term_to_binary(InfoPakage)]
											 end;
										[ok_house, DonateAdd, PaidAdd]->  %%升级成功_帮派厢房
											case erase(Guild_Dict_Name) of
												undefined ->
													[0, 0, 0, 0, <<>>];
												GuildNew ->
													lib_guild:update_guild(GuildNew, SelfPlayerId),
													[MemberCapacityThisLevel2, _, _] = data_guild:get_level_info(GuildNew#ets_guild.level),
													NewGuildMemberCapacity = lib_guild:calc_member_capacity(MemberCapacityThisLevel2, New_Build_Level),
													lib_guild:log_guild_event(GuildId, 20+BuildType, [Build_Level
																									 , New_Build_Level
																									 , NewGuildMemberCapacity
																									 , DonateAdd
																									 , PaidAdd]),
													InfoPakage = [NewGuildMemberCapacity, ?SEPARATOR_STRING, DonateAdd, ?SEPARATOR_STRING, PaidAdd], 
													[1, 0, Build_Level, New_Build_Level, term_to_binary(InfoPakage)]
											end;
										error ->
											[0, 0, 0, 0, <<>>]
									end;
								Res ->
									[Res, 0, 0, 0, <<>>]
							end
					end
			 end
	end.

%% 返回结果,需求的成长值,当前成长值
get_build_cz(Guild, BuildType)->
	if
		BuildType =:= 1 -> 
			[_ProbabilityAdd, JXCost, _UpgradeContribution] = data_guild:get_build_info(Guild#ets_guild.furnace_level, BuildType, 0),
			[Guild#ets_guild.furnace_level, JXCost, Guild#ets_guild.furnace_growth];	%% 神炉

		BuildType =:= 2 -> 
			[_UpgradeContribution, JXCost] = data_guild:get_build_info(Guild#ets_guild.mall_level, BuildType, 0),
			[Guild#ets_guild.mall_level, JXCost, Guild#ets_guild.mall_growth];	%% 商城

		BuildType =:= 3 -> 
			[_CellNum, JXCost, _UpgradeContribution] = data_guild:get_build_info(Guild#ets_guild.depot_level, BuildType, 0),
			[Guild#ets_guild.depot_level, JXCost, Guild#ets_guild.depot_growth];	%% 仓库

		BuildType =:= 4 -> 
			[_, _, _, _, JXCost, _] = data_guild:get_build_info(Guild#ets_guild.altar_level, BuildType, 0),
			[Guild#ets_guild.altar_level, JXCost, Guild#ets_guild.altar_growth];	%% 祭坛
		true ->
			[0, 0]
	end.

%% -----------------------------------------------------------------
%% 捐献建筑
%% ------------------------------------------------------------------
build_donate(UniteStatus, [BuildType, CoinNum])->
	PlayerId = UniteStatus#unite_status.id,
	GuildId = UniteStatus#unite_status.guild_id,
	gen_server:call(mod_guild, {build_donate, [GuildId, PlayerId, BuildType, CoinNum]}).

%% -----------------------------------------------------------------
%% 捐献建筑
%% ------------------------------------------------------------------
build_donate_funds(UniteStatus, [BuildType, CoinNum])->
	PlayerId = UniteStatus#unite_status.id,
	GuildId = UniteStatus#unite_status.guild_id,
	gen_server:call(mod_guild, {build_donate_funds, [GuildId, PlayerId, BuildType, CoinNum]}).

furnace_up(DonateCoin, Guild) ->
	[BuildLV, Threshold, NowGrows] = mod_guild:get_build_cz(Guild, 1),
	case NowGrows + DonateCoin >= Threshold of
		true -> %% 升级
			lib_guild:upgrade_build_new(Guild#ets_guild.id, 1, [BuildLV + 1, 0, Guild#ets_guild.id], BuildLV + 1),
			Guild#ets_guild{furnace_level = Guild#ets_guild.furnace_level + 1, furnace_growth = 0};
		false -> %% 未升级
			lib_guild:upgrade_build_new(Guild#ets_guild.id, 1, [BuildLV, NowGrows + DonateCoin, Guild#ets_guild.id], BuildLV),
			Guild#ets_guild{furnace_level = Guild#ets_guild.furnace_level, furnace_growth = NowGrows + DonateCoin}
	end.

mall_up(DonateCoin, Guild) ->
	[BuildLV, Threshold, NowGrows] = mod_guild:get_build_cz(Guild, 2),
	case NowGrows + DonateCoin >= Threshold of
		true -> %% 升级
			lib_guild:upgrade_build_new(Guild#ets_guild.id, 2, [BuildLV + 1, 0, Guild#ets_guild.id], BuildLV + 1),
			Guild#ets_guild{mall_level = BuildLV + 1, mall_growth = 0};
		false -> %% 未升级
			lib_guild:upgrade_build_new(Guild#ets_guild.id, 2, [BuildLV, NowGrows + DonateCoin, Guild#ets_guild.id], BuildLV),
			Guild#ets_guild{mall_level = BuildLV, mall_growth = NowGrows + DonateCoin}
	end.

depot_up(DonateCoin, Guild) ->
	[BuildLV, Threshold, NowGrows] = mod_guild:get_build_cz(Guild, 3),
	case NowGrows + DonateCoin >= Threshold of
		true -> %% 升级
			lib_guild:upgrade_build_new(Guild#ets_guild.id, 3, [BuildLV + 1, 0, Guild#ets_guild.id], BuildLV + 1),
			Guild#ets_guild{depot_level = BuildLV + 1, depot_growth = 0};
		false -> %% 未升级
			lib_guild:upgrade_build_new(Guild#ets_guild.id, 3, [BuildLV, NowGrows + DonateCoin, Guild#ets_guild.id], BuildLV),
			Guild#ets_guild{depot_level = BuildLV, depot_growth = NowGrows + DonateCoin}
	end.

altar_up(DonateCoin, Guild) ->
	[BuildLV, Threshold, NowGrows] = mod_guild:get_build_cz(Guild, 4),
	case NowGrows + DonateCoin >= Threshold of
		true -> %% 升级
			lib_guild:upgrade_build_new(Guild#ets_guild.id, 4, [BuildLV + 1, 0, Guild#ets_guild.id], BuildLV + 1),
			Guild#ets_guild{altar_level = BuildLV + 1,  altar_growth = 0};
		false -> %% 未升级
			lib_guild:upgrade_build_new(Guild#ets_guild.id, 4, [BuildLV, NowGrows + DonateCoin, Guild#ets_guild.id], BuildLV),
			Guild#ets_guild{altar_level = BuildLV,  altar_growth = NowGrows + DonateCoin}
	end.

%% ------------------------------- E N D --------------------------------------- 
