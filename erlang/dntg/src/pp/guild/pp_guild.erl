%% --------------------------------------------------------
%% @Module:           |pp_guild
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-05
%% @Description:      |帮派处理借口包括帮派(补)
%% --------------------------------------------------------

-module(pp_guild).
-export([handle/4, handle/3]). 
-include("common.hrl").
-include("qlc.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("guild.hrl").
-include("buff.hrl").
-include("sql_guild.hrl").
-import(data_guild, [get_guild_config/2]).
%%=========================================================================
%% 接口函数
%%=========================================================================

%% 整合入口
handle(check, CMD, UniteStatus, Info) -> 
	LimitSelf = data_guild:get_guild_today_limit(0),
	case lists:member(CMD, LimitSelf) of
		false ->
			handle(CMD, UniteStatus, Info);
		true ->
			case lib_guild:guild_today_check(UniteStatus#unite_status.id, UniteStatus#unite_status.id) of
				false->
					ok;
				true ->
					handle(CMD, UniteStatus, Info)
			end
	end.

%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 						帮派基础功能
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 创建帮派  
%% -----------------------------------------------------------------
handle(40001, UniteStatus, [UseType, GuildName, GuildTenet]) when is_record(UniteStatus, unite_status) ->
	PlayerId = UniteStatus#unite_status.id,
	case lib_guild:guild_today_times(PlayerId, PlayerId) of
		true ->
		    [Result, GuildId, CoinLeft, BindCoinLeft] = mod_guild:create_guild(UniteStatus, [UseType, GuildName, GuildTenet]),
		    if  %% 创建成功且使用了钱币
		        ((Result == 1) and (UseType == 0)) ->
					%% 完成加入帮派任务
					lib_task:finish_join_guild_task(UniteStatus#unite_status.id),
		            %% 发送邮件 
					mod_guild:send_guild_mail(guild_create, [PlayerId, UniteStatus#unite_status.name, GuildId, GuildName]),
		%%          %% 发送传闻
					lib_chat:send_TV({all},1, 3
									,[bangpai
									 ,1
									 ,UniteStatus#unite_status.id
									 ,UniteStatus#unite_status.realm
									 ,UniteStatus#unite_status.name
									 ,UniteStatus#unite_status.sex
									 ,UniteStatus#unite_status.career
									 ,UniteStatus#unite_status.image
									 ,GuildName
									 ,GuildId
									 ]),
					{ok, BinData} = pt_400:write(40001, [Result, GuildId,  util:make_sure_binary(GuildName), 1, UseType, CoinLeft, BindCoinLeft]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
					%% 同步玩家自己的帮派信息 (同时同步3个地方)
					GuildPosition = 1,		%% 我是帮主
					NewUniteStatus = lib_guild:guild_self_syn(UniteStatus, [GuildId, util:make_sure_binary(GuildName), GuildPosition]),
			
				%% %% 触发成就
				StatusAchieve = lib_player:get_player_info(PlayerId, achieve),
		            	lib_player_unite:trigger_achieve(PlayerId, trigger_social, [StatusAchieve, PlayerId, 2, 0, 1]),
		
				%% 目标203:创建或加入帮派
				StatusTarget = lib_player:get_player_info(PlayerId, status_target),
				lib_player_unite:trigger_target(PlayerId, [StatusTarget, PlayerId, 203, []]),
		
		            {ok, NewUniteStatus};
		        %% 创建成功且使用了建设令
		        ((Result == 1) and (UseType == 1)) ->
				%% 完成加入帮派任务
					lib_task:finish_join_guild_task(UniteStatus#unite_status.id),
		            % 发送邮件
		            mod_guild:send_guild_mail(guild_create, [PlayerId, UniteStatus#unite_status.name, GuildId, GuildName]),
		            %% 发送回应
		            {ok, BinData} = pt_400:write(40001, [Result, GuildId,  util:make_sure_binary(GuildName), 1, UseType, CoinLeft, BindCoinLeft]),
					lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            %% 发送传闻
					lib_chat:send_TV({all},1, 3
									,[bangpai
									 ,1
									 ,UniteStatus#unite_status.id
									 ,UniteStatus#unite_status.realm
									 ,UniteStatus#unite_status.name
									 ,UniteStatus#unite_status.sex
									 ,UniteStatus#unite_status.career
									 ,UniteStatus#unite_status.image
									 ,GuildName
									 ,GuildId
									 ]),
		
			%% 触发成就
			StatusAchieve = lib_player:get_player_info(PlayerId, achieve),
		        lib_player_unite:trigger_achieve(PlayerId, trigger_social, [StatusAchieve, PlayerId, 2, 0, 1]),
			    
			%% 目标203:创建或加入帮派
			StatusTarget = lib_player:get_player_info(PlayerId, status_target),
			lib_player_unite:trigger_target(PlayerId, [StatusTarget, PlayerId, 203, []]),
		
			%% 同步玩家自己的帮派信息 (同时同步3个地方)
					GuildPosition = 1,		%% 我是帮主
					NewUniteStatus = lib_guild:guild_self_syn(UniteStatus, [GuildId, util:make_sure_binary(GuildName), GuildPosition]),
		            {ok, NewUniteStatus};
		        true ->%% 其他情况
		            %% 发送回应
		            {ok, BinData} = pt_400:write(40001, [Result, GuildId, util:make_sure_binary(GuildName), 1, UseType, CoinLeft, BindCoinLeft]),
					lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            ok
		    end;
		false ->
			ok
	end;

    
%% -----------------------------------------------------------------
%% 解散帮派
%% -----------------------------------------------------------------
handle(40002, UniteStatus, [GuildId]) ->
	case UniteStatus#unite_status.guild_id =:= GuildId andalso GuildId =/= 0 of
		true ->
			%% 判断人数
			Result = mod_guild:apply_disband_guild(UniteStatus, [GuildId]),
		    if  % 申请成功
		        Result == 1 ->
		            % 发送回应
		            {ok, BinData} = pt_400:write(40002, Result),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            % 广播帮派成员
		            lib_guild:send_guild(GuildId, 'guild_apply_disband', 
		                                            [UniteStatus#unite_status.id, UniteStatus#unite_status.name, 
		                                             GuildId, UniteStatus#unite_status.guild_name]),
		            % 邮件通知给帮派成员
		            mod_guild:send_guild_mail(guild_apply_disband, [UniteStatus#unite_status.id, UniteStatus#unite_status.name, GuildId, UniteStatus#unite_status.guild_name]),
		            ok;
		        % 申请失败
		        true ->
		            % 发送回应
		            {ok, BinData} = pt_400:write(40002, Result),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            ok
		    end;
		false ->
			% 发送回应
            {ok, BinData} = pt_400:write(40002, 4),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end;
    
%% -----------------------------------------------------------------
%% 确认解散帮派
%% -----------------------------------------------------------------
handle(40003, UniteStatus, [GuildId, ConfirmResult]) ->
	case UniteStatus#unite_status.guild_id =:= GuildId andalso GuildId =/= 0  of
		true ->
			Result = mod_guild:confirm_disband_guild(UniteStatus, [GuildId, ConfirmResult]),
			if  % 确定解散且成功
		        ((Result == 1) and (ConfirmResult == 1)) ->
		            % 发送回应
		            {ok, BinData} = pt_400:write(40003, [Result, GuildId, util:make_sure_binary(UniteStatus#unite_status.guild_name), ConfirmResult]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            % 广播帮派成员
		            lib_guild:send_guild(GuildId, 'guild_disband', [UniteStatus#unite_status.guild_id, UniteStatus#unite_status.guild_name]),            
		            %% 同步玩家自己的帮派信息 (同时同步3个地方)
					NewUniteStatus = lib_guild:guild_self_syn(UniteStatus, [0, [], 0]),
		            {ok, NewUniteStatus};
		        % 取消解散且成功
		        ((Result == 1) and (ConfirmResult == 0)) ->
		            % 广播帮派成员
		            lib_guild:send_guild(GuildId, 'guild_cancel_disband', [UniteStatus#unite_status.id
																		  , UniteStatus#unite_status.name
																		  , UniteStatus#unite_status.guild_id
																		  , UniteStatus#unite_status.guild_name]),
		            % 邮件通知给帮派成员
		            mod_guild:send_guild_mail(guild_cancel_disband, [UniteStatus#unite_status.id
																	  , UniteStatus#unite_status.name
																	  , UniteStatus#unite_status.guild_id
																	  , UniteStatus#unite_status.guild_name]),
		            % 发送回应
		            {ok, BinData} = pt_400:write(40003, [Result, GuildId, util:make_sure_binary(UniteStatus#unite_status.guild_name), ConfirmResult]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            ok;
		        % 其他情况
		        true ->
		            % 发送回应
		            {ok, BinData} = pt_400:write(40003, [Result, GuildId, util:make_sure_binary(UniteStatus#unite_status.guild_name), ConfirmResult]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            ok
		    end;
		false ->
			{ok, BinData} = pt_400:write(40003, [4, GuildId, util:make_sure_binary(UniteStatus#unite_status.guild_name), ConfirmResult]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            ok
	end;

%% -----------------------------------------------------------------
%% 获取帮派列表
%% -----------------------------------------------------------------
handle(40010, UniteStatus, [PageSize, PageNo]) ->
    [Result, PageTotal, PageNo, RecordNum, Data] = mod_guild:list_guild(UniteStatus, [PageSize, PageNo]),
    {ok, BinData} = pt_400:write(40010, [Result, PageTotal, PageNo, RecordNum, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 查看本帮信息
%% -----------------------------------------------------------------
handle(40014, UniteStatus, [GuildId]) ->
	case GuildId =:= UniteStatus#unite_status.guild_id andalso GuildId =/= 0 of
		true ->
			[Result, Data] = lib_guild:get_guild_info(UniteStatus#unite_status.guild_id),
		    {ok, BinData} = pt_400:write(40014, [Result, Data]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		false ->
			skip
	end,
    ok;

%% -----------------------------------------------------------------
%% 修改帮派公告
%% -----------------------------------------------------------------
handle(40016, UniteStatus, [GuildId, Announce]) ->
	case GuildId =:= UniteStatus#unite_status.guild_id andalso GuildId =/= 0 of
		true ->
		    [Result, AnnounceNew] = mod_guild:modify_guild_announce(UniteStatus, [GuildId, Announce]),
		    if  % 修改成功
		        Result == 1 ->
		            {ok, BinData} = pt_400:write(40016, [Result, GuildId, util:make_sure_binary(AnnounceNew)]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            % 通知帮派成员
		            lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_modify_announce', [UniteStatus#unite_status.id, UniteStatus#unite_status.name, Announce]),
		            ok;
		        true ->
		            {ok, BinData} = pt_400:write(40016, [Result, GuildId, util:make_sure_binary(AnnounceNew)]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            ok
		    end;
		false ->
			{ok, BinData} = pt_400:write(40016, [4, GuildId, <<>>]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end;
    
%% %% -----------------------------------------------------------------
%% %% 捐献钱币
%% %% -----------------------------------------------------------------
%% handle(40019, UniteStatus, [GuildId, Num]) ->
%% 	case GuildId =:= UniteStatus#unite_status.guild_id andalso GuildId =/= 0 andalso Num >= 0 of
%% 		true ->
%% 		    [Result, CoinLeft, BindCoinLeft, DonationAdd, PaidAdd] = mod_guild:donate_money(UniteStatus, [GuildId, Num]),
%% 		    if  % 捐献成功
%% 		        Result == 1 ->
%% 		            % 发送回应
%% 		            {ok, BinData} = pt_400:write(40019, [Result, CoinLeft, BindCoinLeft, DonationAdd, PaidAdd]),
%% 		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
%% 		            % 记录帮派事件
%% 		            lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 9, [UniteStatus#unite_status.id
%% 																		   , UniteStatus#unite_status.name
%% 																		   , UniteStatus#unite_status.guild_position, Num]),
%% 		            % 通知帮派成员
%% 		            lib_guild:send_guild(UniteStatus#unite_status.guild_id
%% 										, 'guild_donate_money'
%% 										, [UniteStatus#unite_status.id, UniteStatus#unite_status.name, Num, DonationAdd, PaidAdd]),
%% 		            %% 触发成就
%% 		%%          lib_achieve:trigger_hd(Status#player_status.id, 5, DonationAdd),
%% 		            ok;
%% 		        Result == 6 ->
%% 		            ok;
%% 		        % 捐献失败
%% 		        true ->
%% 		            % 发送回应
%% 		            {ok, BinData} = pt_400:write(40019, [Result, CoinLeft, BindCoinLeft, DonationAdd, PaidAdd]),
%% 		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
%% 		            ok
%% 		    end;
%% 		false ->
%% 			{ok, BinData} = pt_400:write(40019, [2, 0, 0, 0, 0]),
%% 		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
%% 	end;

%% -----------------------------------------------------------------
%% 捐献帮派建设卡
%% -----------------------------------------------------------------
handle(40020, UniteStatus, [GuildId, CardNum]) ->
	case GuildId =:= UniteStatus#unite_status.guild_id andalso GuildId =/= 0 andalso CardNum >= 0 of
		true ->
		    [Result, OldLevel, NewLevel, DonationAdd, PaidAdd, MaterialAdd] = mod_guild:donate_contribution_card(UniteStatus, [GuildId, CardNum]),
		    if Result == 1 ->
                    RoleId = UniteStatus#unite_status.id,
                    case lib_player:get_player_info(RoleId, pid) of
                        RolePid when erlang:is_pid(RolePid) -> 
                            gen_server:cast(RolePid, {'refresh_daily_welfare'});
                        _ -> 
                            skip
                    end,
		            % 记录帮派事件
		            lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 10, [UniteStatus#unite_status.id
																					 , UniteStatus#unite_status.name
																					 , UniteStatus#unite_status.guild_position
																					 , CardNum]),
		            % 通知帮派成员
		            lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_donate_contribution_card', [UniteStatus#unite_status.id
																											  , UniteStatus#unite_status.name
																											  , CardNum
																											  , DonationAdd
																											  , PaidAdd
																											  , MaterialAdd]),
		            % 如果帮派升级则也通知帮派成员
		            if  (OldLevel < NewLevel) ->
		                    lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_upgrade', [UniteStatus#unite_status.guild_id
																									 , UniteStatus#unite_status.guild_name
																									 , OldLevel
																									 , NewLevel]);
		                true ->
		                    void
		            end,
					MetarialCount = mod_daily_dict:get_count(UniteStatus#unite_status.id, 4001),
		            case MetarialCount =< 500 of
		                true ->
							MetarialLeftCount = 500 - MetarialCount,
		                    {ok, BinData} = pt_400:write(40020, [Result, DonationAdd, PaidAdd, MaterialAdd, MetarialLeftCount]),
		                    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		                    ok;
		                false -> 
		                    {ok, BinData} = pt_400:write(40020, [Result, DonationAdd, PaidAdd, 0, 0]),
		                    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		                    ok
		            end;
		        Result == 6 ->%% 		没有输入二级密码暂时使用捐献失败 
		            {ok, BinData} = pt_400:write(40020, [Result, DonationAdd, PaidAdd, 0, 0]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            ok;
		        %% 捐献失败
		        true ->
		            %% 发送回应
		            {ok, BinData} = pt_400:write(40020, [Result, DonationAdd, PaidAdd, 0, 0]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            ok
		    end;
		false ->
			%% 发送回应
            {ok, BinData} = pt_400:write(40020, [0, 0, 0, 0, 0]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
			ok
	end;

%% -----------------------------------------------------------------
%% 获取捐献列表
%% -----------------------------------------------------------------
handle(40021, UniteStatus, [GuildId, PageSize, PageNo]) ->
	case GuildId =:= UniteStatus#unite_status.guild_id andalso GuildId =/= 0 of
		true ->
		    [Result, PageTotal, PageNo, RecordNum, Data] = mod_guild:list_donate(UniteStatus, [GuildId, PageSize, PageNo]),
		    {ok, BinData} = pt_400:write(40021, [Result, PageTotal, PageNo, RecordNum, Data]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		    ok;
		false ->
			ok
	end;

%% %% -----------------------------------------------------------------
%% %% 领取日福利
%% %% -----------------------------------------------------------------
%% handle(40023, UniteStatus, [GuildId]) ->
%% 	case GuildId =:= UniteStatus#unite_status.guild_id andalso GuildId =/= 0 of
%% 		true ->
%% 		    [Result, Num, BindCoinLeft] = mod_guild:get_paid(UniteStatus, [GuildId]),
%% 		    if
%% 		        % 领取成功
%% 		        Result == 1 ->
%% 		            % 发送回应
%% 		            {ok, BinData} = pt_400:write(40023, [Result, Num, BindCoinLeft]),
%% 		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
%% 		            ok;
%% 		        % 领取失败
%% 		        true ->
%% 		            % 发送回应
%% 		            {ok, BinData} = pt_400:write(40023, [Result, Num, BindCoinLeft]),
%% 		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
%% 		            ok
%% 		    end;
%% 		false ->
%% 			% 发送回应
%%             {ok, BinData} = pt_400:write(40023, [3, 0, 0]),
%%             lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
%% 			ok
%% 	end;

%% -----------------------------------------------------------------
%% 捐献元宝
%% -----------------------------------------------------------------
handle(40072, UniteStatus, Gold) -> 
	case Gold >= 0 of
		true ->
			[Res, OldLevel, NewLevel, DonationAdd, PaidAdd, ContributionAdd] = mod_guild:donate_gold(UniteStatus, [UniteStatus#unite_status.guild_id, Gold]),
		    if
		        Res == 1 ->
		            % 记录帮派事件
		            lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 13, [UniteStatus#unite_status.id
																					 , UniteStatus#unite_status.name
																					 , UniteStatus#unite_status.guild_position
																					 , Gold]),
                    RoleId = UniteStatus#unite_status.id,
                    case lib_player:get_player_info(RoleId, pid) of
                        RolePid when erlang:is_pid(RolePid) -> 
                            gen_server:cast(RolePid, {'refresh_daily_welfare'});
                        _ -> 
                            skip
                    end,
		            if  
						(OldLevel < NewLevel) ->
		                    lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_upgrade', [UniteStatus#unite_status.guild_id
																							, UniteStatus#unite_status.guild_name
																							, OldLevel
																							, NewLevel]);
		                true ->
		                    void
		            end;
		        true -> skip
		    end,
		    {ok, BinData} = pt_400:write(40072, [Res, DonationAdd, PaidAdd, Gold, ContributionAdd]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		    ok;
		false ->
			ok
	end;


%% -----------------------------------------------------------------
%% 查询帮派
%% -----------------------------------------------------------------
handle(40034, UniteStatus, [Realm, GuildName, ChiefName, PageSize, PageNo, WashType, SelfShow]) ->
    case UniteStatus#unite_status.guild_id =:= 0 andalso (WashType=:=2 orelse WashType=:=3) of
		 true ->
			 {ok, BinDatax} = pt_400:write(40034, [0, 0, 0, 0, 0, <<>>]),
    		 lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinDatax);
		 false ->
			 [Result, ApplyGuildId, PageTotal, PageNo, RecordNum, Data] = mod_guild:search_guild(UniteStatus, [Realm, GuildName, ChiefName, PageSize, PageNo, WashType, SelfShow]),
			 {ok, BinData} = pt_400:write(40034, [Result, ApplyGuildId, PageTotal, PageNo, RecordNum, Data]),
    		 lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end,
	ok;

%% -----------------------------------------------------------------
%% 合服改名 此功能未开发
%% -----------------------------------------------------------------
handle(40039, UniteStatus, [GuildId, GuildName]) ->
	case GuildId =:= UniteStatus#unite_status.guild_id andalso GuildId =/= 0 of
		true ->
		    PlayerId = UniteStatus#unite_status.id,
		    [Result, _GoldLeft] = mod_guild:rename_guild(UniteStatus, [GuildId, GuildName]),
		    {ok, BinData} = pt_400:write(40039, [Result, util:make_sure_binary(GuildName)]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		    if Result == 1 ->
		           % 消息通知帮派成员
		           lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_rename', [PlayerId, UniteStatus#unite_status.name, GuildId, GuildName]),
		           ok;
		       true ->
		           ok
		    end;
		false ->
			{ok, BinData} = pt_400:write(40039, [3, util:make_sure_binary(GuildName)]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end;

%% -----------------------------------------------------------------
%% 使用弹劾令
%% -----------------------------------------------------------------
handle(40052, UniteStatus, [GoodsId, _GoodsUseNum]) ->
    [Result, ChiefId, ChiefName, ChiefPosition] = mod_guild:impeach_chief(UniteStatus, [GoodsId, 1]),
    {ok, BinData} = pt_400:write(40052, [Result]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    if  % 成功
        Result == 1 ->
            % 记录帮派事件
            lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 8, [UniteStatus#unite_status.id
																			, UniteStatus#unite_status.guild_position
																			, UniteStatus#unite_status.name
																			, ChiefId
																			, ChiefName
																			, ChiefPosition]),
            % 消息通知帮派成员
            lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_impeach_chief', [UniteStatus#unite_status.id
																						   , UniteStatus#unite_status.name
																						   , UniteStatus#unite_status.guild_position
																						   , ChiefId, ChiefName]),
            % 邮件通知帮派成员
            mod_guild:send_guild_mail(guild_impeach_chief, [UniteStatus#unite_status.guild_id
														   , UniteStatus#unite_status.id
														   , UniteStatus#unite_status.name
														   , ChiefId
														   , ChiefName]),
            %% 同步玩家自己的帮派信息 (同时同步3个地方)
			GuildPosition = 1,		%% 我是帮主
			NewUniteStatus = lib_guild:guild_self_syn(UniteStatus, [UniteStatus#unite_status.guild_id
																   , util:make_sure_binary(UniteStatus#unite_status.guild_name), GuildPosition]),
            {ok, NewUniteStatus};
        true ->
            ok
    end;

%% -----------------------------------------------------------------
%% 使用集结令
%% -----------------------------------------------------------------
handle(40053, UniteStatus, [GoodsId, _GoodsUseNum]) ->
    case lib_player:get_player_info(UniteStatus#unite_status.id, scene_base) of
		[MyScene, MyCopyId, MyX, MyY] when MyCopyId =:= 0 ->
			Result = mod_guild:gather_member(UniteStatus, [GoodsId, 1], [MyScene, MyCopyId, MyX, MyY]),
		    {ok, BinData} = pt_400:write(40053, [Result]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
			if  % 成功
		        Result == 1 ->
		            % 通知帮派成员
		            lib_guild:send_guild(UniteStatus#unite_status.guild_id
										, 'guild_gather_member'
										, [UniteStatus#unite_status.id
										  , UniteStatus#unite_status.name
										  , MyScene
										  , MyX
										  , MyY]);
		        true ->
		            void
		    end;
		_ ->
			{ok, BinData} = pt_400:write(40053, [0]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end,
    ok;

%% -----------------------------------------------------------------
%% 获取帮派事件
%% -----------------------------------------------------------------
handle(40055, UniteStatus, [MenuType, PageSize, PageNum]) ->
    [Code, PageTotle, PageNow, List] = lib_guild:get_guild_event(UniteStatus#unite_status.id, UniteStatus#unite_status.guild_id, MenuType, PageSize, PageNum),
    {ok, BinData} = pt_400:write(40055, [Code, MenuType, PageTotle, PageNow, List]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 取消帮派合并申请
%% -----------------------------------------------------------------
handle(40057, UniteStatus, [Type]) ->
	GuildId = UniteStatus#unite_status.guild_id,
	case Type =:= 1 of
		true ->
			[Code] = case lib_guild:get_guild(GuildId) of
													SelfGuild when is_record(SelfGuild, ets_guild) ->
														mod_guild:make_merge_0(GuildId, 0),
														case SelfGuild#ets_guild.merge_guild_id =:= 0 of
															true ->
																skip;
															false ->
																mod_guild:make_merge_0(SelfGuild#ets_guild.merge_guild_id, 0)
														end,
														[1];
													_->
														[0]
												end,
			{ok, BinData} = pt_400:write(40057, [Code]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		false ->
			skip
	end,
	ok;

%% -----------------------------------------------------------------
%% 合并申请
%% -----------------------------------------------------------------
handle(40059, UniteStatus, _) ->
	GuildId = UniteStatus#unite_status.guild_id,
	[Code, Gid, Glv, RecName, TypeXS, GMN] = case lib_guild:get_guild(UniteStatus#unite_status.guild_id) of
		Guild when is_record(Guild, ets_guild) ->
			case Guild#ets_guild.merge_guild_id =:= 0 of
				true ->
					[0,0,0,<<>>,0,0];
				false ->
					case Guild#ets_guild.merge_guild_direction =:= 3 of
						true ->
							case lib_guild:get_guild(Guild#ets_guild.merge_guild_id) of
								GuildF when is_record(GuildF, ets_guild) ->
									[1, GuildF#ets_guild.id, GuildF#ets_guild.level, GuildF#ets_guild.name, 0, GuildF#ets_guild.member_num];
								_ ->
									mod_guild:make_merge_0(GuildId, 0),
									[0,0,0,<<>>,0,0]
							end;
						false ->
							case lib_guild:get_guild(Guild#ets_guild.merge_guild_id) of
								GuildF when is_record(GuildF, ets_guild) ->
									[1, GuildF#ets_guild.id, GuildF#ets_guild.level, GuildF#ets_guild.name, 1, GuildF#ets_guild.member_num];
								_ ->
									mod_guild:make_merge_0(GuildId, 0),
									[0,0,0,<<>>,0,0]
							end
					end
			end;
		_ ->
			[0,0,0,<<>>,0,0]
	end,
	{ok, BinData} = pt_400:write(40059, [Code, Gid, Glv, RecName, TypeXS, GMN]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 合并申请
%% -----------------------------------------------------------------
handle(40060, UniteStatus, [TargetGuildId]) ->
	[Result] = case mod_daily_dict:get_special_info({UniteStatus#unite_status.guild_id, hebing}) of
		hebing ->
			[12];
		_ ->
			CountHB = mod_daily_dict:get_count(4000000 + TargetGuildId, 4006101),
			case CountHB >= 10 of
				true ->
					[13];
				false ->
					mod_guild:invite_merge_guild(UniteStatus, [TargetGuildId])
			end
	end,
	{ok, BinData} = pt_400:write(40060, [Result]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 合并申请回应 
%% -----------------------------------------------------------------
handle(40061, UniteStatus, [HbGuildId, ResponseResult]) ->
%	case mod_city_war:is_att_def(HbGuildId) of
%		true ->
%			{ok, BinData} = pt_400:write(40061, [12]),
%		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
%		false ->
		    [Result] = mod_guild:response_merge_guild_invite(UniteStatus, [HbGuildId, ResponseResult]),
			{ok, BinData} = pt_400:write(40061, [Result]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
%	end,
    ok;
	  
%% -----------------------------------------------------------------
%% 获取帮派通讯录
%% -----------------------------------------------------------------
handle(40095, UniteStatus, [GuildId, PlayerId, PageSize, PageNum]) ->
	[1, PageTotal, PageNo, RowsPage] = lib_guild:get_contact_book(UniteStatus, GuildId, PlayerId, PageSize, PageNum),
    {ok, BinData} = pt_400:write(40095, [GuildId, PageTotal, PageNo, RowsPage]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% -----------------------------------------------------------------
%% 修改自己的帮派通讯录
%% -----------------------------------------------------------------
handle(40096, UniteStatus, [PlayerId, PlayerName, City, QQ, PhoneNum, BirDay, HideType]) ->
	PS_G_ID = UniteStatus#unite_status.guild_id,
	Res = lib_guild:set_contact_book([PlayerId, PS_G_ID, PlayerName, City, QQ, PhoneNum, BirDay, HideType, UniteStatus#unite_status.lv]),
	{ok, BinData} = pt_400:write(40096, [Res]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 					帮派成员管理相关功能
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 申请加入
%% -----------------------------------------------------------------
handle(40004, UniteStatus, [GuildId]) ->    
%% 	QXTime = case mod_daily_dict:get_special_info({UniteStatus#unite_status.id, 40320, 40320}) of
	QXTime = case get({UniteStatus#unite_status.id, 40320, 40320}) of
				 R when erlang:is_integer(R)->
					 NowTime = util:unixtime(),
					 case NowTime - R > 5 of
						 true ->
							 0;
						 _ ->
							 1
					 end;
				 _ ->
					 0
			 end,
	case QXTime =/= 0 of
		true ->
			{ok, BinData} = pt_400:write(40004, [9, 0, 0]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		false ->
			case lib_guild:guild_today_times(UniteStatus#unite_status.id, UniteStatus#unite_status.id) of
				true ->
				    [Result, _GuildName, ApplyGuildId, ApplySetting] = mod_guild:apply_join_guild(UniteStatus, [GuildId]),
				    if  % 申请成功
				        Result == 1 ->
				        	case ApplySetting =:= 1 of 
				        		true ->
				        			PlayerInfo = 
				        			[UniteStatus#unite_status.id,
				        			 util:make_sure_binary(UniteStatus#unite_status.name),
				        			 UniteStatus#unite_status.realm,
				        			 UniteStatus#unite_status.career,
				        			 UniteStatus#unite_status.sex,
				        			 UniteStatus#unite_status.image,
				        			 UniteStatus#unite_status.lv,
				        			 UniteStatus#unite_status.guild_id,
				        			 util:make_sure_binary(UniteStatus#unite_status.guild_name),
				        			 UniteStatus#unite_status.guild_position],
				        			lib_guild:auto_join(UniteStatus#unite_status.id, GuildId, PlayerInfo, _GuildName),
				            		% 发送回应
				            		{ok, BinData} = pt_400:write(40004, [11, GuildId, ApplyGuildId]),
				            		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				            	false ->
				            		{ok, BinData} = pt_400:write(40004, [Result, GuildId, ApplyGuildId]),
				            		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
				            		% 广播帮派官员（副帮主以上）
									lib_guild:send_guild_official(2, GuildId, 'guild_apply_join', [UniteStatus#unite_status.id, UniteStatus#unite_status.name])
				            end,
				            ok;
				        % 申请失败
				        true ->
				            % 发送回应
				            {ok, BinData} = pt_400:write(40004, [Result, GuildId, ApplyGuildId]),
				            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
				            ok
				    end;
				false ->
					ok
			end
	end;

%% -----------------------------------------------------------------
%% 审批加入
%% -----------------------------------------------------------------
handle(40005, UniteStatus, [TargetPlayerId, HandleResult]) ->
	case lib_guild:guild_today_times(UniteStatus#unite_status.id, TargetPlayerId) of
		true ->
			Data_Return	= mod_guild:guild_member_contrl(UniteStatus, [1, 40005, [TargetPlayerId, HandleResult]]),
			[Result, [PlayerName, GuildPosition, PlayerCarrer, PlayerSex, PlayerImage, PlayerLv]] = case length(Data_Return) of
				1->
					[D] = Data_Return,
					[D,[0,0,0,0,0,0]];
				2->
					Data_Return;
				_->
					[0,[0,0,0,0,0,0]]
			end,
		    if  %% 审批加入成功且允许
		        ((Result == 1) and (HandleResult == 1)) ->
					%% 完成加入帮派任务
					lib_task:finish_join_guild_task(TargetPlayerId),
		            %% 发送回应
		            {ok, BinData} = pt_400:write(40005, Result),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            %% 记录帮派事件
		            lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 1, [TargetPlayerId, PlayerName, GuildPosition]),
		            %% 广播帮派成员
		            lib_guild:send_guild_except_one(UniteStatus#unite_status.guild_id, TargetPlayerId, 'guild_new_member'
												   , [TargetPlayerId, PlayerName, UniteStatus#unite_status.guild_id
													 , UniteStatus#unite_status.guild_name
													 , GuildPosition
													 , 0
													 , PlayerCarrer, PlayerSex, PlayerImage, PlayerLv]),
		            %% 邮件通知给被审批人
		            mod_guild:send_guild_mail(guild_new_member, [TargetPlayerId
																, PlayerName
																, UniteStatus#unite_status.guild_id
																, UniteStatus#unite_status.guild_name]),
				%% 触发成就
				StatusAchieve = lib_player:get_player_info(TargetPlayerId, achieve),
				lib_player_unite:trigger_achieve(TargetPlayerId, trigger_social, [StatusAchieve, TargetPlayerId, 2, 0, 1]),
		
				%% 目标203:创建或加入帮派
				StatusTarget = lib_player:get_player_info(TargetPlayerId, status_target),
				lib_player_unite:trigger_target(TargetPlayerId, [StatusTarget, TargetPlayerId, 203, []]),
		
					%% 同步 其他玩家的帮派信息
					lib_guild:guild_other_syn([TargetPlayerId
											 , UniteStatus#unite_status.guild_id
											 , UniteStatus#unite_status.guild_name
											 , GuildPosition]),
		            ok;
		        %% 审批加入成功且拒绝
		        ((Result == 1) and (HandleResult == 0)) ->
		            % 发送回应
		            {ok, BinData} = pt_400:write(40005, Result),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            % 广播帮派成员
		            lib_guild:send_one(TargetPlayerId, 'guild_reject_apply', [UniteStatus#unite_status.guild_id, UniteStatus#unite_status.guild_name]),
		            ok;
		        %% 其他情况
		        true ->
		            %% 发送回应
		            {ok, BinData} = pt_400:write(40005, Result),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            ok
		    end;
		false ->
			ok
	end;

%% -----------------------------------------------------------------
%% 邀请加入
%% -----------------------------------------------------------------
handle(40006, UniteStatus, [PlayerName]) ->
	case lib_scene:is_clusters_scene(UniteStatus#unite_status.scene) of
		true ->
			ok;
		false ->
			case lib_guild_base:get_player_guild_info2_by_name(PlayerName) of
				[TargetPlayerId, _, _, _, _, _, _, _, _, _] ->
					case lib_guild:guild_today_times(UniteStatus#unite_status.id, TargetPlayerId) of
						true ->
						    Data_Return = mod_guild:guild_member_contrl(UniteStatus, [1, 40006, [PlayerName]]),
							case length(Data_Return) of
								1->
									[Result] = Data_Return,
									[PlayerId]= [0];
								2->
									[Result, PlayerId] = Data_Return;
								_->
									[Result, PlayerId] = [0,0]
							end,
						    if  % 邀请成功
						        Result == 1 ->
						            % 发送回应
						            {ok, BinData} = pt_400:write(40006, Result),
						            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
						            % 通知被邀请人
						            lib_guild:send_one(PlayerId, 'guild_invite_join', [PlayerId
																					  , PlayerName
																					  , UniteStatus#unite_status.guild_id
																					  , UniteStatus#unite_status.guild_name]),
						            % 邮件通知给被邀请人
						            mod_guild:send_guild_mail(guild_invite_join, [PlayerId
																				 , PlayerName
																				 , UniteStatus#unite_status.guild_id
																				 , UniteStatus#unite_status.guild_name]),
									%% 记录次数
									mod_daily_dict:increment(UniteStatus#unite_status.id, 40006001),
						            ok;
						        % 邀请失败
						        true ->
						            %% 发送回应
						            {ok, BinData} = pt_400:write(40006, Result),
						            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
						            ok
						    end;
						false ->
							ok
					end;
				_ ->
					{ok, BinData} = pt_400:write(40006, 4),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            ok
			end
	end;
	

%% -----------------------------------------------------------------
%% 邀请回应
%% -----------------------------------------------------------------
handle(40007, UniteStatus, [GuildId, ResponseResult]) ->    
	case lib_guild:guild_today_times(UniteStatus#unite_status.id, UniteStatus#unite_status.id) of
		true ->
			SelfPlayerId = UniteStatus#unite_status.id,
		    [Result, GuildName, GuildPosition, GuildLevel] = mod_guild:response_invite_guild(UniteStatus, [GuildId, ResponseResult]),
		    if  % 回应成功且加入帮派
		        ((Result == 1) and (ResponseResult == 1)) ->
				%% 完成加入帮派任务
					lib_task:finish_join_guild_task(UniteStatus#unite_status.id),
		            % 发送回应
		            {ok, BinData} = pt_400:write(40007, [Result, ResponseResult, GuildId, GuildName, GuildPosition]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            % 记录帮派事件
		            lib_guild:log_guild_event(GuildId, 1, [SelfPlayerId, UniteStatus#unite_status.name, GuildPosition]),
		            % 广播帮派成员
		            lib_guild:send_guild(GuildId, 'guild_new_member', [SelfPlayerId, UniteStatus#unite_status.name, GuildId, GuildName, GuildPosition, GuildLevel, UniteStatus#unite_status.career, UniteStatus#unite_status.sex, UniteStatus#unite_status.image, UniteStatus#unite_status.lv]),
		            % 邮件通知给新成员
		            mod_guild:send_guild_mail(guild_new_member, [SelfPlayerId, UniteStatus#unite_status.name, GuildId, GuildName]),
		
				%% 触发成就
				StatusAchieve = lib_player:get_player_info(SelfPlayerId, achieve),
				lib_player_unite:trigger_achieve(SelfPlayerId, trigger_social, [StatusAchieve, UniteStatus#unite_status.id, 2, 0, 1]),
			
				%% 目标203:创建或加入帮派
				StatusTarget = lib_player:get_player_info(SelfPlayerId, status_target),
				lib_player_unite:trigger_target(SelfPlayerId, [StatusTarget, SelfPlayerId, 203, []]),
		
					%% 同步玩家自己的帮派信息 (同时同步3个地方)
					NewUniteStatus = lib_guild:guild_self_syn(UniteStatus, [GuildId, util:make_sure_binary(GuildName), 5]),
		            {ok, NewUniteStatus};
		        % 回应成功且拒绝入帮
		        ((Result == 1) and (ResponseResult == 0)) ->
		            % 发送回应
		            {ok, BinData} = pt_400:write(40007, [Result, ResponseResult, GuildId, GuildName, GuildPosition]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            % 广播帮派成员(仅发送帮主副帮主)
		            lib_guild:send_guild_official(2, GuildId, 'guild_reject_invite', [UniteStatus#unite_status.id, UniteStatus#unite_status.name]),
		            ok;
		        % 回应失败
		        true ->
		            % 发送回应
		            {ok, BinData} = pt_400:write(40007, [Result, ResponseResult, GuildId, GuildName, GuildPosition]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
		            ok
		    end;
		false ->
			ok
	end;

%% -----------------------------------------------------------------
%% 踢出帮派
%% -----------------------------------------------------------------
handle(40008, UniteStatus, [TargetPlayerId]) ->
	_SelfPlayerId = UniteStatus#unite_status.id,
    Data_Return = mod_guild:guild_member_contrl(UniteStatus, [1, 40008, [TargetPlayerId]]),
	case length(Data_Return) of
		1->
			[Result] = Data_Return,
			[PlayerName, GuildPosition]= [0,0];
		3->
			[Result, PlayerName, GuildPosition] = Data_Return;
		_->
			[Result, PlayerName, GuildPosition] = [0,0,0]
	end,
    if  % 踢出成功
        Result == 1 ->
            % 发送回应
            {ok, BinData} = pt_400:write(40008, Result),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            % 记录帮派事件
            lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 2, [TargetPlayerId, PlayerName, GuildPosition]),
            % 通知帮派成员
            lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_kickout'
								, [TargetPlayerId
								  , PlayerName
								  , UniteStatus#unite_status.guild_id
								  , UniteStatus#unite_status.guild_name]),
            % 邮件通知给被踢出人
            mod_guild:send_guild_mail(guild_kickout, [TargetPlayerId, PlayerName, UniteStatus#unite_status.guild_id, UniteStatus#unite_status.guild_name]),
			%% 同步 其他玩家的帮派信息
			lib_guild:guild_other_syn([TargetPlayerId
									 , 0
									 , []
									 , 0]),
            ok;
        % 踢出失败
        true ->
            % 发送回应
            {ok, BinData} = pt_400:write(40008, Result),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            ok
    end;

%% -----------------------------------------------------------------
%% 退出帮派
%% -----------------------------------------------------------------
handle(40009, UniteStatus, [GuildId]) ->
	_SelfPlayerId = UniteStatus#unite_status.id,
    [Result] = mod_guild:guild_member_contrl(UniteStatus, [0, 40009, [GuildId]]),
    if  % 退出成功
        Result == 1 ->
            % 发送回应
            {ok, BinData} = pt_400:write(40009, Result),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            % 记录帮派事件
            lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 3
									 , [UniteStatus#unite_status.id
									   , UniteStatus#unite_status.name
									   , UniteStatus#unite_status.guild_position]),
            % 通知帮派成员
            lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_quit'
								, [UniteStatus#unite_status.id
								  , UniteStatus#unite_status.name
								  , UniteStatus#unite_status.guild_id
								  , UniteStatus#unite_status.guild_name]),
			%% 同步玩家自己的帮派信息 (同时同步3个地方)
			NewUniteStatus = lib_guild:guild_self_syn(UniteStatus, [0, [], 0]),
            {ok, NewUniteStatus};
        % 退出失败
        true ->
            % 发送回应
            {ok, BinData} = pt_400:write(40009, Result),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            ok
    end;

%% -----------------------------------------------------------------
%% 获取帮派成员列表
%% -----------------------------------------------------------------
handle(40011, UniteStatus, [GuildId, PageSize, PageNo, Type]) ->
    [Result, PageTotal, PageNo, RecordNum, Data] = mod_guild:list_guild_member(UniteStatus, [GuildId, PageSize, PageNo, Type]),
    {ok, BinData} = pt_400:write(40011, [Result, PageTotal, PageNo, RecordNum, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 获取帮派申请列表
%% -----------------------------------------------------------------
handle(40012, UniteStatus, [GuildId, PageSize, PageNo]) ->
    [Result, PageTotal, PageNo, RecordNum, Data] = mod_guild:list_guild_apply(UniteStatus, [GuildId, PageSize, PageNo]),
    {ok, BinData} = pt_400:write(40012, [Result, PageTotal, PageNo, RecordNum, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 获取帮派邀请列表
%% -----------------------------------------------------------------
handle(40013, UniteStatus, [PlayerId, PageSize, PageNo]) ->
    [Result, PageTotal, PageNo, RecordNum, Data] = mod_guild:list_guild_invite(UniteStatus, [PlayerId, PageSize, PageNo]),
    {ok, BinData} = pt_400:write(40013, [Result, PageTotal, PageNo, RecordNum, Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 职位设置
%% -----------------------------------------------------------------
handle(40017, UniteStatus, [PlayerId, GuildPosition]) ->
	case lib_guild:guild_today_check(UniteStatus#unite_status.id, PlayerId) of
		false->
			ok;
		true ->
			case GuildPosition =< 5 of
				true ->
					_SelfPlayerId = UniteStatus#unite_status.id,
				    Data_Return = mod_guild:guild_member_contrl(UniteStatus, [1, 40017, [PlayerId, GuildPosition]]),
					[Result, PlayerName, OldGuildPostion] = case length(Data_Return) of
						1->
							[D] = Data_Return,
							[D, 0, 0];
						3->
							Data_Return;
						_->
							[0,0,0]
					end,
				    if  % 踢出成功
				        Result == 1 ->
				            % 发送回应
				            {ok, BinData} = pt_400:write(40017, Result),
				            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
				            case OldGuildPostion < GuildPosition of
				                % 降职（仅被降职成员收到）
				                true ->
				                    % 记录帮派事件
				                    lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 5, [PlayerId, PlayerName, OldGuildPostion, GuildPosition]),
				                    % 通知帮派成员
				                    lib_guild:send_one(PlayerId, 'guild_set_position', [PlayerId, PlayerName, OldGuildPostion, GuildPosition]);
				                % 升职（通知帮派成员）
				                false ->
				                    % 记录帮派事件
				                    lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 4, [PlayerId, PlayerName, OldGuildPostion, GuildPosition]),
				                    % 通知帮派成员
				                    lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_set_position', [PlayerId, PlayerName, OldGuildPostion, GuildPosition])
				            end,
							%% 同步 其他玩家的帮派信息
							lib_guild:guild_other_syn([PlayerId
													 , UniteStatus#unite_status.guild_id
													 , UniteStatus#unite_status.guild_name
													 , GuildPosition]),
				            ok;
				        % 踢出失败
				        true ->
				            % 发送回应
				            {ok, BinData} = pt_400:write(40017, Result),
				            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
				            ok
				    end;
				false ->
					ok
			end
	end;
	

%% -----------------------------------------------------------------
%% 帮主转让帮派
%% -----------------------------------------------------------------
handle(40018, UniteStatus, [PlayerName]) ->
	%% 根据名字查找ID
	case mod_chat_agent:match(match_name, [util:make_sure_list(PlayerName)]) of
		[] ->
			{ok, BinData} = pt_400:write(40018, 7),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		[Player] ->
			case lib_guild:guild_today_check(UniteStatus#unite_status.id, Player#ets_unite.id) of
				false->
					{ok, BinData} = pt_400:write(40018, 8),
					lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				true ->
					_SelfPlayerId = UniteStatus#unite_status.id,
					Data_Return =  mod_guild:guild_member_contrl(UniteStatus, [1, 40018, [PlayerName]]),
					[Result, PlayerId, GuildPosition] = case length(Data_Return) of
															1->
																[D] = Data_Return,
																[D, 0, 0];
															3->
																Data_Return;
															_->
																[0,0,0]
														end,
					if % 禅让成功
						Result == 1 ->
							% 发送回应
							{ok, BinData} = pt_400:write(40018, Result),
							lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
							%% 记录帮派事件
							lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 6
													  , [UniteStatus#unite_status.id
														 , UniteStatus#unite_status.name
														 , UniteStatus#unite_status.guild_position
														 , PlayerId, PlayerName, GuildPosition]),
							%% 消息通知帮派成员
							lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_demise_chief'
												 , [UniteStatus#unite_status.id, UniteStatus#unite_status.name, PlayerId, PlayerName]),			
							%% 同步 其他玩家的帮派信息
							lib_guild:guild_other_syn([PlayerId
													   , UniteStatus#unite_status.guild_id
													   , UniteStatus#unite_status.guild_name
													   , 1]),
							%% 同步玩家自己的帮派信息 (同时同步3个地方)
							NewUniteStatus = lib_guild:guild_self_syn(UniteStatus, [UniteStatus#unite_status.guild_id
																					, UniteStatus#unite_status.guild_name
																					, 5]),
							{ok, NewUniteStatus};
						true ->
							% 发送回应
							{ok, BinData} = pt_400:write(40018, Result),
							lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
							ok
					end
			end
	end;
		
	

%% -----------------------------------------------------------------
%% 辞去官职
%% -----------------------------------------------------------------
handle(40022, UniteStatus, [GuildId]) ->
	_SelfPlayerId = UniteStatus#unite_status.id,
    Data_Return = mod_guild:guild_member_contrl(UniteStatus, [0, 40022, [GuildId]]),
	[Result, NewPosition] = case length(Data_Return) of
		1->
			[D] = Data_Return,
			[D, 0];
		3->
			Data_Return;
		_->
			[0,0]
	end,
    if
        % 辞去成功
        Result == 1 ->
            % 发送回应
            {ok, BinData} = pt_400:write(40022, Result),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            % 记录帮派事件
            lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 7
									 , [UniteStatus#unite_status.id
									   , UniteStatus#unite_status.name
									   , UniteStatus#unite_status.guild_position, NewPosition]),
            % 通知帮派官员（帮主和副帮主）
            lib_guild:send_guild_official(2, UniteStatus#unite_status.guild_id, 'guild_resign_position'
										 , [UniteStatus#unite_status.id
										   , UniteStatus#unite_status.name
										   , UniteStatus#unite_status.guild_position, NewPosition]),
            %% 同步玩家自己的帮派信息 (同时同步3个地方)
			NewUniteStatus = lib_guild:guild_self_syn(UniteStatus, [UniteStatus#unite_status.guild_id
																   , UniteStatus#unite_status.guild_name
																   , 5]),
            {ok, NewUniteStatus};
        % 创建失败
        true ->
            % 发送回应
            {ok, BinData} = pt_400:write(40022, Result),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            ok
    end;

%% -----------------------------------------------------------------
%% 查看成员信息
%% -----------------------------------------------------------------
handle(40024, UniteStatus, [GuildId, PlayerId]) ->
    [Result, Data] = lib_guild:get_member_info([GuildId, PlayerId]),
    {ok, BinData} = pt_400:write(40024, [Result,Data]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 授予头衔
%% -----------------------------------------------------------------
handle(40025, UniteStatus, [_GuildId, PlayerId, Title]) ->
    Data_Return = mod_guild:guild_member_contrl(UniteStatus, [1, 40025, [PlayerId, Title]]),
	case length(Data_Return) of
		1->
			[Result] = Data_Return,
			[PlayerName]= [<<>>];
		3->
			[Result, PlayerName] = Data_Return;
		_->
			[Result, PlayerName] = [0,<<>>]
	end,
    if  Result == 1 ->
            {ok, BinData} = pt_400:write(40025, Result),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            % 通知帮派成员
            lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_give_title', [PlayerId, PlayerName, Title]),
            ok;
        true ->
            {ok, BinData} = pt_400:write(40025, Result),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            ok
    end;
    
%% -----------------------------------------------------------------
%% 修改个人备注
%% -----------------------------------------------------------------
handle(40026, UniteStatus, [GuildId, Remark]) ->
    [Result] = mod_guild:guild_member_contrl(UniteStatus, [0, 40026, [GuildId, Remark]]),
    {ok, BinData} = pt_400:write(40026, [Result, GuildId, util:make_sure_binary(Remark)]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 入帮祝福		
%% -----------------------------------------------------------------
handle(40063, UniteStatus, [PlayerId, Type, GoodsNum]) ->
	DailyTimes1 = mod_daily_dict:get_count(PlayerId, 40063001),
	DailyTimes2 = mod_daily_dict:get_count(PlayerId, 40063002),
    case DailyTimes1 >= 200 of
        true ->
            {ok, BinData} = pt_400:write(40063, [0, Type, GoodsNum]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
        false ->
            case DailyTimes2 >= 200 of
                true ->
                    {ok, BinData} = pt_400:write(40063, [0, Type, GoodsNum]),
                    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
                false ->
                    case GoodsNum >= 0 of
                        true ->
                            _SelfPlayerId = UniteStatus#unite_status.id,
                            [Result, PlayerName] = mod_guild:join_bless(UniteStatus, [PlayerId, Type, GoodsNum]),
                            {ok, BinData} = pt_400:write(40063, [Result, Type, GoodsNum]),
                            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
                            if  Result == 1 ->
                                    if  % 欢迎
                                        Type == 0 ->
                                            lib_guild:send_one(PlayerId, 'guild_join_bless'
                                                              , [PlayerId
                                                                , PlayerName
                                                                , UniteStatus#unite_status.id
                                                                , UniteStatus#unite_status.name
                                                                , UniteStatus#unite_status.guild_position
                                                                , Type, GoodsNum]);
                                        true ->
                                            lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_join_bless'
                                                                , [PlayerId, PlayerName
                                                                  , UniteStatus#unite_status.id
                                                                  , UniteStatus#unite_status.name
                                                                  , UniteStatus#unite_status.guild_position
                                                                  , Type, GoodsNum])
                                    end,
                                    if  % 欢迎
                                        Type == 0 ->
			                                mod_daily_dict:increment(PlayerId, 40063001),
                                            lib_player:update_player_info(PlayerId, [{add_exp, 88}]),
                                            ok;
                                        % 送钱
                                        Type == 1 ->
			                                mod_daily_dict:increment(PlayerId, 40063002),
                                            lib_player:update_player_info(PlayerId, [{add_coin, 88}]),
                                            ok;
                                        % 送其他
                                        true ->
                                            ok
                                    end;
                                true ->
                                    ok
                            end;
                        false ->
                            ok
                    end
            end
    end;


%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 					帮派建筑物相关功能
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 获取仓库物品列表
%% -----------------------------------------------------------------
handle(40027, UniteStatus, [GuildId]) ->
    [Result, RecordNum, Records] = mod_guild:list_depot_goods(UniteStatus, [GuildId]),
    {ok, BinData} = pt_400:write(40027, [Result, RecordNum, Records]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
    ok;

%% -----------------------------------------------------------------
%% 帮派仓库存入物品
%% -----------------------------------------------------------------
handle(40028, UniteStatus, [GuildId, GoodsId, GoodsName, GoodsNum]) ->
    Result = mod_guild:store_into_depot(UniteStatus, [GuildId, GoodsId, GoodsNum]),
    if  % 升级成功
        Result == 1 ->
            {ok, BinData} = pt_400:write(40028, [Result, GuildId, GoodsId, GoodsNum]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            %% 记录帮派事件
            lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 16
									 , [UniteStatus#unite_status.id
									   , UniteStatus#unite_status.name
									   , UniteStatus#unite_status.guild_position
									   , GoodsId, GoodsName, GoodsNum]),
            %% 通知帮派成员
            lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_store_into_depot'
								, [UniteStatus#unite_status.id
								  , UniteStatus#unite_status.name
								  , GoodsId, GoodsName, GoodsNum]),
            ok;
        true ->
            {ok, BinData} = pt_400:write(40028, [Result, GuildId, GoodsId, GoodsNum]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            ok
    end;

%% -----------------------------------------------------------------
%% 帮派仓库取出物品
%% -----------------------------------------------------------------
handle(40029, UniteStatus, [GuildId, GoodsId, GoodsName, GoodsNum]) ->
    [Result, DonationDeduct] = mod_guild:take_out_depot(UniteStatus, [GuildId, GoodsId, GoodsNum, GoodsName]),
    if  % 取出成功
        Result == 1 ->
            {ok, BinData} = pt_400:write(40029, [Result, GuildId, DonationDeduct, GoodsId, GoodsNum]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            %% 记录帮派事件
            %% 通知帮派成员
            lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_take_out_depot'
								, [UniteStatus#unite_status.id
								  , UniteStatus#unite_status.name
								  , GoodsId, GoodsName, GoodsNum]),
            ok;
        true ->
            {ok, BinData} = pt_400:write(40029, [Result, GuildId, DonationDeduct, GoodsId, GoodsNum]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            ok
    end;

%% -----------------------------------------------------------------
%% 帮派仓库删除物品
%% -----------------------------------------------------------------
handle(40030, UniteStatus, [GuildId, GoodsId, GoodsName, GoodsNum]) ->
    Result = mod_guild:delete_from_depot(UniteStatus, [GuildId, GoodsId, GoodsNum]),
    if  % 升级成功
        Result == 1 ->
            {ok, BinData} = pt_400:write(40030, [Result, GuildId]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            % 通知帮派成员
            lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_delete_from_depot'
								, [UniteStatus#unite_status.id
								  , UniteStatus#unite_status.name
								  , GoodsId, GoodsName, GoodsNum]),
            ok;
        true ->
            {ok, BinData} = pt_400:write(40030, [Result, GuildId]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            ok
    end;

%% -----------------------------------------------------------------
%% 新的帮派建筑升级
%% -----------------------------------------------------------------
handle(40031, UniteStatus, [GuildId, BuildType]) ->
	case BuildType of
		5 ->
			Infomation = mod_guild:upgrade_build(UniteStatus,[GuildId, BuildType, UniteStatus#unite_status.sid]),
			[Result, _, OldLevel, NewLevel, UpgradeInfo] = Infomation,
			{ok, BinData} = pt_400:write(40031, [Result, GuildId, OldLevel, NewLevel, UpgradeInfo]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		_ ->
			ok
	end,
	ok;

handle(40035, UniteStatus, _Type) ->
	pp_guild_scene:handle(40100, UniteStatus, [_Type]),
	ok;

%% -----------------------------------------------------------------
%% 帮派祭坛
%% -----------------------------------------------------------------
handle(40078, UniteStatus, [GuildId]) ->
	case UniteStatus#unite_status.guild_id =:= GuildId andalso GuildId =/= 0 of
		true ->
			[Code, AltarLevel, ListId, GoodList] = lib_guild:get_guild_altar_info([GuildId, UniteStatus#unite_status.id]),
			case Code =:= 1 of 
				true ->
					[Daily_Type_ID, _, PrayTimes, FundsCost, _, _] = data_guild:get_altar_info(AltarLevel),
					DailyPrayTimes = mod_daily_dict:get_count(UniteStatus#unite_status.id, Daily_Type_ID),
					TimesLeft = PrayTimes + ?MFYJCS, 
					{ok, BinData} = pt_400:write(40078, [Code, GuildId, AltarLevel, DailyPrayTimes, TimesLeft, FundsCost, ListId, GoodList]),
				    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				false ->
					{ok, BinData} = pt_400:write(40078, [Code, GuildId, AltarLevel, 0, 0, 0, 0, []]),
				    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
			end;
		false ->
			ok
	end;

%% -----------------------------------------------------------------
%% 帮派祭坛
%% -----------------------------------------------------------------
handle(40079, UniteStatus, [GuildId, Artar_List_Id]) ->
	case Artar_List_Id =/= UniteStatus#unite_status.id orelse GuildId =/= UniteStatus#unite_status.guild_id of
		true ->
			ok;
		false ->
			case lib_guild_base:get_guild(UniteStatus#unite_status.guild_id) of
				GuildInfo when is_record(GuildInfo, ets_guild) ->
					[Daily_Type_ID, _, PrayTimes, MaterialCost, _, _] = data_guild:get_altar_info(GuildInfo#ets_guild.altar_level),
					DailyPrayTimes = mod_daily_dict:get_count(UniteStatus#unite_status.id, Daily_Type_ID),  %% 已经祈福次数
					TimesLeft = PrayTimes - DailyPrayTimes + ?MFYJCS,%% 写死
					case TimesLeft =< 0 of
						true->	%% 剩余次数为0无法祈福
								{ok, BinData} = pt_400:write(40079, [6, GuildId, 0, 0, 0, 0]),
							    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
						false->	%% 可以祈福_次数+1
								{Res, IconNum, GoodsTypeId, GoodsNum} = lib_guild:get_altar_pray(UniteStatus, [Daily_Type_ID, MaterialCost]),
								lib_player:update_player_info(UniteStatus#unite_status.id, [{refresh_login_gift, no}]),
								DailyPrayTimes_New = mod_daily_dict:get_count(UniteStatus#unite_status.id, Daily_Type_ID),  %% 已经祈福次数
								CWWP = data_guild:get_yj_chuanwen_list(),
								case Res =:= 1 of
									true ->
										%% 运势任务(3700003:帮派摇奖)
										lib_fortune:fortune_daily(UniteStatus#unite_status.id, 3700003, 1);
									_ ->
										skip
								end, 
								case lists:member(GoodsTypeId, CWWP) of
									true ->
										erlang:spawn(fun()->
												 [IdT, RealmT, NicknameT, SexT, CareerT, IimageT] = lib_player:get_player_info(UniteStatus#unite_status.id, sendTv_Message),
												 lib_chat:send_TV({all},1, 2,[guildYJ, IdT, RealmT, NicknameT, SexT, CareerT, IimageT, GoodsTypeId])
									 	end);
									false ->
										skip
								end,
								{ok, BinData} = pt_400:write(40079, [Res, GuildId, DailyPrayTimes_New, IconNum, GoodsTypeId, GoodsNum]),
							    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
								mod_daily_dict:set_count(UniteStatus#unite_status.id, 4007902, 0),
								mod_daily_dict:set_count(UniteStatus#unite_status.id, 4007903, 0),
								ok
					end;
				_ ->
					ok
			end
	end;

%% -----------------------------------------------------------------
%% 帮派神炉
%% -----------------------------------------------------------------
handle(40080, UniteStatus, [GuildId]) ->
	case UniteStatus#unite_status.guild_id =:= GuildId of
		true ->
			[Code, GuildId, FurnaceLevel, NowAdd, NextLvAdd, CNow, CTop] = case lib_guild_base:get_guild(UniteStatus#unite_status.guild_id) of
					[] ->
						[0, GuildId, 0, 0, 0, 0, 0];
					Guild ->
						[Num1, _, _] = data_guild:get_furnace_info(Guild#ets_guild.furnace_level),
						[Num2, _, _] = data_guild:get_furnace_info(Guild#ets_guild.furnace_level + 1),
						case lib_guild_base:get_guild_member_by_player_id(UniteStatus#unite_status.id) of
							Gmember when is_record(Gmember, ets_guild_member) ->
								NumLimit = data_guild:get_f_limit(Guild#ets_guild.furnace_level),
								[1, GuildId, Guild#ets_guild.furnace_level, Num1, Num2, Gmember#ets_guild_member.furnace_back, NumLimit];
							_->
								[0, GuildId, 0, 0, 0, 0, 0]
						end
			end,
			{ok, BinData} = pt_400:write(40080, [Code, GuildId, FurnaceLevel, NowAdd, NextLvAdd, CNow, CTop]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		false ->
			ok
	end;

%% -----------------------------------------------------------------
%% 帮派神炉 
%% -----------------------------------------------------------------
handle(40083, UniteStatus, _) ->
	[Res, Num] = case lib_guild:get_furnace_back(UniteStatus#unite_status.id, UniteStatus#unite_status.guild_id) of
			{ok, FurnaceBack} ->
				send_furnaceback_unite(UniteStatus#unite_status.id, {'furnaceback', FurnaceBack}),
				[1, FurnaceBack];
			_ ->
				[0, 0]
	end,
	{ok, BinData} = pt_400:write(40083, [Res, Num]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% -----------------------------------------------------------------
%% 获取帮派商城物品列表
%% -----------------------------------------------------------------
handle(40091, UniteStatus, [GuildId, MallLevel]) ->
    [Result, MallGoodsList] = lib_guild:get_guild_mall_goods_list(UniteStatus, GuildId, MallLevel),

    %% 取玩家帮派财富和帮派战功
    GuildMember = lib_guild_base:get_guild_member_by_player_id(UniteStatus#unite_status.id),
    case is_record(GuildMember, ets_guild_member) of 
    	false -> % 没有帮派
    		Caifu = 0,
    		FactionWar = lib_player:get_player_info(UniteStatus#unite_status.id, factionwar),
    		FactionWarScore = FactionWar#status_factionwar.war_score - FactionWar#status_factionwar.war_score_used;
    	true ->
    		Caifu = GuildMember#ets_guild_member.material,
    		FactionWar = GuildMember#ets_guild_member.factionwar,
    		FactionWarScore = FactionWar#factionwar_info.war_score - FactionWar#factionwar_info.war_score_used
    end,
	{ok, BinData} = pt_400:write(40091, [Result, MallLevel, MallGoodsList, Caifu, FactionWarScore]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% -----------------------------------------------------------------
%% 兑换帮派商城物品
%% -----------------------------------------------------------------
handle(40092, UniteStatus, [GoodsTypeId, NUnitNum]) ->
	case NUnitNum >= 0 of
		true ->
		    [Result, GoodsTypeId, GoodsNum, RestExchangeNum] =  lib_guild:exchange_mall_goods_with_material(UniteStatus, [GoodsTypeId, NUnitNum]),
		    %% 取玩家帮派财富和帮派战功
    		GuildMember = lib_guild_base:get_guild_member_by_player_id(UniteStatus#unite_status.id),
    		case is_record(GuildMember, ets_guild_member) of 
    			true -> % 没有帮派
    				Caifu = 0,
    				FactionWar = lib_player:get_player_info(UniteStatus#unite_status.id, factionwar),
    				FactionWarScore = FactionWar#status_factionwar.war_score - FactionWar#status_factionwar.war_score_used;
    			false ->
    				Caifu = GuildMember#ets_guild_member.material,
    				FactionWar = GuildMember#ets_guild_member.factionwar,
    				FactionWarScore = FactionWar#factionwar_info.war_score - FactionWar#factionwar_info.war_score_used
    		end,
		    {ok, BinData} = pt_400:write(40092, [Result, GoodsTypeId, GoodsNum, RestExchangeNum, Caifu, FactionWarScore]),
		    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
			ok;
		false ->
			ok
	end;



%% %% -----------------------------------------------------------------
%% %% 获取帮派技能列表
%% %% -----------------------------------------------------------------
%% handle(40070, UniteStatus, [GuildId, _PlayerId]) ->
%%     [Guild_Level, Player_bpgx, Guild_SkillList] = lib_guild:get_guild_skill_info([GuildId, UniteStatus#unite_status.id]),
%% 	%% io:format("Format:~p~n",[Guild_SkillList]),
%% 	%% K = lib_guild:get_guild_skill_add([_PlayerId, 10001]),
%% 	%% io:format("Format:~p~n",[K]),
%% 	{ok, BinData} = pt_400:write(40070, [1, Guild_Level, Player_bpgx, Guild_SkillList]),
%%     lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% %% -----------------------------------------------------------------
%% %% 请求帮派目标信息
%% %% ----------------------------------------------------------------
%% handle(40081,  UniteStatus, [GuildId, BaseType]) ->
%% 	%%[AchieveType, MaxLevel, BaseType] = data_guild:get_guild_achieve_info_data(BaseType, 3),
%% 	AchieveList = data_guild:get_guild_achieve_info_data(BaseType, 3),
%% 	case erlang:length(AchieveList) of
%% 		0 ->
%% 			%%错误的类型
%% 			{ok, BinData} = pt_400:write(40081, [0, GuildId, []]),
%%     		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
%% 		_Length ->
%% 			F = fun({AchieveType, _, _}) ->
%% 						One_ = lib_guild:get_guild_achieved_info([GuildId, AchieveType]),
%% 						erlang:tuple_to_list(One_)
%% 			end,
%% 			List_For_Pack = [F(D) || D <- AchieveList],
%% 			{ok, BinData} = pt_400:write(40081, [1, GuildId, List_For_Pack]),
%% 			%% io:format("Format:~p~n",[BinData]),
%%     		lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
%% 	end;

%% %% -----------------------------------------------------------------
%% %% 帮派目标领奖
%% %% ----------------------------------------------------------------
%% handle(40082,  UniteStatus, [GuildId, FullAchieveId]) ->
%% 	AchieveType = FullAchieveId div 10,
%% 	AchieveLevel = FullAchieveId rem 10,
%% 	Result = lib_guild:get_guild_achieved_prize([UniteStatus#unite_status.id, GuildId, AchieveType, AchieveLevel]),
%% 	%% 发送帮派通知
%% 	%% lib_guild:send_guild(GuildId, 'guild_achieve_prize_got', [UniteStatus#unite_status.id, UniteStatus#unite_status.name, GuildId, GuildName, GuildPosition, GuildLevel, UniteStatus#unite_status.career, UniteStatus#unite_status.sex, UniteStatus#unite_status.image, UniteStatus#unite_status.lv]),
%%     {ok, BinData} = pt_400:write(40082, [Result]),
%%     lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% -----------------------------------------------------------------
%% 直接解散帮派
%% -----------------------------------------------------------------
handle(40094, UniteStatus, [GuildId]) ->
	% case mod_city_war:is_att_def(GuildId) of
	% 	true ->
	% 		{ok, BinData} = pt_400:write(40094, 7),
 %            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	% 		ok;
	% 	_ ->
			case UniteStatus#unite_status.guild_id =:= GuildId andalso GuildId =/= 0 of
				true ->
					%% 判断人数
					Result = mod_guild:just_disband_guild(UniteStatus, [GuildId]),
				    if  % 申请成功
				        Result == 1 ->
				            % 发送回应
				            {ok, BinData} = pt_400:write(40094, Result),
				            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
				            % 广播帮派成员
				            lib_guild:send_guild(GuildId, 'guild_disband', [UniteStatus#unite_status.guild_id, UniteStatus#unite_status.guild_name]),            
		%% 		            %% 同步玩家自己的帮派信息 (同时同步3个地方)
		%% 					NewUniteStatus = lib_guild:guild_self_syn(UniteStatus, [0, [], 0]),
				            %% 邮件通知给帮派成员
		%% 		            mod_guild:send_guild_mail(guild_apply_disband, [UniteStatus#unite_status.id, UniteStatus#unite_status.name, GuildId, UniteStatus#unite_status.guild_name]),
				            ok;
				        % 申请失败
				        true ->
				            % 发送回应
				            {ok, BinData} = pt_400:write(40094, Result),
				            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
				            ok
				    end;
				false ->
					% 发送回应
		            {ok, BinData} = pt_400:write(40094, 4),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
			end;
%	end;

%% -----------------------------------------------------------------
%% 帮主群发公告信息_弹窗_40000
%% -----------------------------------------------------------------
handle(40097, UniteStatus, [GuildId, PlayerId, PlayerName, Title, Content]) ->
	DailyChiefAnn = mod_daily_dict:get_count(UniteStatus#unite_status.id, 4009701),
	case DailyChiefAnn >= 10 of
		true ->
			{ok, BinData} = pt_400:write(40097, [0]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		false ->
			lib_guild:send_guild(UniteStatus#unite_status.guild_id, 'guild_chief_ann_all', [GuildId, PlayerId, PlayerName, Title, Content]),
			mod_daily_dict:increment(UniteStatus#unite_status.id, 4009701),
			{ok, BinData} = pt_400:write(40097, [1]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end,
	ok;


%% -----------------------------------------------------------------
%% 玩家登陆游戏获取帮派信息
%% -----------------------------------------------------------------
handle(40099, UniteStatus, _) ->
	lib_guild:role_login_unite(UniteStatus#unite_status.id),
	ok;




%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 		 				403接入功能
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 取消申请
%% -----------------------------------------------------------------
handle(40320, UniteStatus, [GuildId]) ->
	NowTime = util:unixtime(),
	case GuildId > 0 andalso UniteStatus#unite_status.guild_id == 0 of
		true ->
			mod_guild:del_guild_apply(UniteStatus, GuildId),
			mod_daily_dict:set_special_info({UniteStatus#unite_status.id, 40320, 40320}, NowTime),
			put({UniteStatus#unite_status.id, 40320, 40320}, NowTime),
			{ok, BinData} = pt_403:write(40320, [1]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            ok;
		false ->
			ok
	end;

%% -----------------------------------------------------------------
%% 获取自己的福利信息
%% -----------------------------------------------------------------
handle(40321, UniteStatus, _) ->
	RoleId = UniteStatus#unite_status.id,
	case UniteStatus#unite_status.guild_id =:= 0 of
		true ->
			ok;
		false ->
			case lib_guild_base:get_guild_member_by_player_id(RoleId) of
				GuildMember when is_record(GuildMember, ets_guild_member) ->
					TodayDonate = mod_daily_dict:get_count(RoleId, 3700002),
					BaseList = lists:seq(1, 6),
					AllNum = if
						TodayDonate >= 300 -> 6;
						TodayDonate >= 200 -> 5;
						TodayDonate >= 100 -> 4;
						TodayDonate >= 50 -> 3;
						TodayDonate >= 30 -> 2;
						TodayDonate >= 10 -> 1;
						true -> 1
					end,
					LastList = case mod_daily_dict:get_special_info({RoleId, fuli}) of
						undefined ->
							NewList = lists:map(fun(Num) ->
											  case Num > AllNum of
												  true ->
													  {Num, 0, 1};
												  false ->
													  {Num, 1, 1}
											  end
									  end, BaseList),
							mod_daily_dict:set_special_info({RoleId, fuli}, NewList),
							NewList;
						OldInfo ->
							NewListX = lists:map(fun({A, _B, C}) ->
											  case A > AllNum of
												  true ->
													  {A, 0, C};
												  false ->
													  {A, 1, C}
											  end
									  end, OldInfo),
							mod_daily_dict:set_special_info({RoleId, fuli}, NewListX),
							NewListX
					end,
					{ok, BinData} = pt_403:write(40321, [TodayDonate, LastList]),
					lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				_ ->
					ok
			end
	end;

%% -----------------------------------------------------------------
%% 领取自己的福利信息
%% -----------------------------------------------------------------
handle(40322, UniteStatus, [FDMumber]) ->
	RoleId = UniteStatus#unite_status.id,
	case FDMumber > 6 orelse FDMumber< 1 of
		true ->
			ok;
		false ->
			case UniteStatus#unite_status.guild_id =:= 0 of
				true ->
					ok;
				false ->
					case lib_guild_base:get_guild_member_by_player_id(RoleId) of
						GuildMember when is_record(GuildMember, ets_guild_member) ->
							Res = case mod_daily_dict:get_special_info({RoleId, fuli}) of
								undefined ->
									0;
								OldInfo ->
									{_PackageId, TimesLeft, IsC} = lists:nth(FDMumber, OldInfo),
									case TimesLeft > 0 andalso IsC > 0 of
										true ->
										    case lib_player:get_player_info(RoleId, pid) of
												RolePid when erlang:is_pid(RolePid) ->
		                                            GiveList = [{?FULIWUPI, 1}],  
													case send_fuli_unite(RoleId, GiveList, bind) of
            											ok ->
															NewInfo = lists:map(fun({A, B, C}) ->
																						case A =:= FDMumber of
																							true ->
																								{A, 0, 0};
																							false ->
																								{A, B, C}
																						end
																				end, OldInfo),
															mod_daily_dict:set_special_info({RoleId, fuli}, NewInfo),
                                                            gen_server:cast(RolePid, {'refresh_daily_welfare'}),
															1;
		                                                {fail, ResX} ->
		                                                    case ResX of
		                                                        2 ->    %% 物品类型不存在
		                                                           	0;
		                                                        3 ->    %% 背包空间不足
		                                                            2;
		                                                        _ ->    %% 失败
		                                                            0
		                                                    end;
		                                                _ ->    %% 失败
		                                                    0
		                                            end;
												_ ->
													0
											end;
										false ->
											3
									end
							end,
							{ok, BinData} = pt_403:write(40322, [Res, FDMumber]),
							lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
						_ ->
							ok
					end
			end
	end;

%% -----------------------------------------------------------------
%% 建筑升级(1 神炉 2 商城 3 仓库 4 祭坛) 
%% -----------------------------------------------------------------
handle(40331, UniteStatus, [BuildType, CoinNum]) ->
	GuildId = UniteStatus#unite_status.guild_id,
	IsWrite = CoinNum rem 1000,
	case GuildId =/= 0 andalso CoinNum > 0 andalso BuildType >= 1 andalso BuildType =< 4 andalso IsWrite =:= 0 of
		true ->
			Res = mod_guild:build_donate(UniteStatus, [BuildType, CoinNum]),
			case Res =:= 1 of
				true ->
					lib_guild:donate_money(UniteStatus#unite_status.id, GuildId, CoinNum),
					DonateMoneyRatio = data_guild:get_guild_config(donate_money_ratio, []),
    				DonateAdd = (CoinNum * DonateMoneyRatio) div 1000,
		            {ok, BinData0} = pt_400:write(40019, [1, 0, 0, DonateAdd, 0]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData0),
		            lib_guild:log_guild_event(UniteStatus#unite_status.guild_id, 9, [UniteStatus#unite_status.id
																		   , UniteStatus#unite_status.name
																		   , UniteStatus#unite_status.guild_position, CoinNum]),
					ok;
				false ->
					ok
			end,
            {ok, BinData} = pt_403:write(40331, [Res]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		false ->
			ok
	end;

handle(40332, UniteStatus, [BuildType]) ->
	GuildId = UniteStatus#unite_status.guild_id,
	case GuildId =/= 0 andalso BuildType >= 1 andalso BuildType =< 4 of
		true ->
			case lib_guild:get_guild(GuildId) of
				Guild when is_record(Guild, ets_guild) ->
					[BuildLV, Threshold, NowGrows] = mod_guild:get_build_cz(Guild, BuildType),
					CoinNeed = Threshold - NowGrows,
		            {ok, BinData} = pt_403:write(40332, [1, Threshold, NowGrows, CoinNeed, BuildType, BuildLV]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				_ ->
		            {ok, BinData} = pt_403:write(40332, [0, 0, 0, 0, 0, 0]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
			end;
		false ->
            {ok, BinData} = pt_403:write(40332, [0, 0, 0, 0, 0, 0]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end;

%% -----------------------------------------------------------------
%% 建筑升级(1 神炉 2 商城 3 仓库 4 祭坛)
%% -----------------------------------------------------------------
handle(40333, UniteStatus, [BuildType, Fonds]) ->
	GuildId = UniteStatus#unite_status.guild_id,
	IsWrite = Fonds rem 1000,
	case GuildId =/= 0 andalso Fonds > 0 andalso BuildType >= 1 andalso BuildType =< 4 andalso IsWrite =:= 0 andalso UniteStatus#unite_status.guild_position =:= 1 of
		true ->
			Res = mod_guild:build_donate_funds(UniteStatus, [BuildType, Fonds]),
            {ok, BinData} = pt_403:write(40333, [Res]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		false ->
			ok
	end;

%% -----------------------------------------------------------------
%% 获取个人财富
%% -----------------------------------------------------------------
handle(40335, UniteStatus, _) ->
	GuildId = UniteStatus#unite_status.guild_id,
	case GuildId =/= 0 of
		true ->
			CaiFu = case catch gen_server:call(mod_guild, {get_guild_member_caifu, UniteStatus#unite_status.id}) of
				D when erlang:is_integer(D) ->
					D;
				_ ->
					0
			end,
            {ok, BinData} = pt_403:write(40335, [1, CaiFu]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		false ->
			ok
	end;

%% -----------------------------------------------------------------
%% 查询同盟关系
%% -----------------------------------------------------------------
handle(40340, UniteStatus, _) ->
	GuildId = UniteStatus#unite_status.guild_id,
	case GuildId =/= 0 of
		true ->
			RelaDict = guild_rela_handle:get_self_rela(GuildId),
			DictList = dict:to_list(RelaDict),
			FList = [OneGuildIdF||{OneGuildIdF, TypeF} <- DictList, TypeF =:= 1],
			EList = [OneGuildIdE||{OneGuildIdE, TypeE} <- DictList, TypeE =:= 2],
			{ok, BinData} = pt_403:write(40340, [1, FList, EList]),
	        lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		false ->
			{ok, BinData} = pt_403:write(40340, [1, [], []]),
	        lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end;

%% -----------------------------------------------------------------
%% 更改与指定帮派的关系
%% -----------------------------------------------------------------
handle(40341, UniteStatus, [TGuildId, Type]) ->
	GuildId = UniteStatus#unite_status.guild_id,
	case GuildId =:= 0 orelse TGuildId =:= 0 of
		true ->
			ok;
		false ->
			Res = case Type =:= 1 of
				true ->
					case lib_guild:get_guild(GuildId) of
						GuildSelf when is_record(GuildSelf, ets_guild)->
							case lib_guild:get_guild(TGuildId) of
								GuildTarget when is_record(GuildTarget, ets_guild)->
									case mod_chat_agent:lookup(GuildTarget#ets_guild.chief_id) of
									    [Player] when is_record(Player, ets_unite)->
											{ok, BinData1} = pt_403:write(40342, [1
																		, GuildSelf#ets_guild.id
																		, GuildSelf#ets_guild.name
																		, GuildSelf#ets_guild.level
																		, GuildSelf#ets_guild.member_num
																		, GuildSelf#ets_guild.realm]),
		            						lib_unite_send:send_to_uid(GuildTarget#ets_guild.chief_id, BinData1),
											mod_daily_dict:set_special_info({GuildId, TGuildId}, apply),
										   1;
									    _ ->
										   3
								    end;
								_ ->
									0
							end;
						_ ->
							0
					end;
				false ->
					guild_rela_handle:change_rela(UniteStatus, TGuildId, Type)
			end,
            {ok, BinData} = pt_403:write(40341, [Res, Type]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end;

%% -----------------------------------------------------------------
%% 更改与指定帮派的关系
%% -----------------------------------------------------------------
handle(40343, UniteStatus, [TGuildId, Type]) ->
	GuildId = UniteStatus#unite_status.guild_id,
	case GuildId =:= 0 orelse TGuildId =:= 0 of
		true ->
			ok;
		false ->
			case Type =:= 1 of
				true ->
					Res = case mod_daily_dict:get_special_info({TGuildId, GuildId}) of
						apply ->
							guild_rela_handle:change_rela(UniteStatus, TGuildId, 1);
						_ ->
							3
					end,
					case Res =/= 1 of
						true ->
							case lib_guild:get_guild(TGuildId) of
								TGuild when is_record(TGuild, ets_guild) ->
									{ok, BinData41} = pt_403:write(40344, [6, UniteStatus#unite_status.guild_name]),
				            		lib_unite_send:send_to_uid(TGuild#ets_guild.chief_id, BinData41);
								_->
									skip
							end;
						_ ->
							skip
					end,
		            {ok, BinData} = pt_403:write(40343, [Res]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
				_ ->
					mod_daily_dict:set_special_info({GuildId, TGuildId}, refuse),
					case lib_guild:get_guild(TGuildId) of
						TGuild when is_record(TGuild, ets_guild) ->
							{ok, BinData41} = pt_403:write(40344, [5, UniteStatus#unite_status.guild_name]),
		            		lib_unite_send:send_to_uid(TGuild#ets_guild.chief_id, BinData41);
						_->
							skip
					end,
					{ok, BinData} = pt_403:write(40343, [1]),
		            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
			end
	end;

%% -----------------------------------------------------------------
%%  查询神兽信息(新)
%% -----------------------------------------------------------------
handle(40350, UniteStatus, _) ->
	GuildId = UniteStatus#unite_status.guild_id,
	case UniteStatus#unite_status.guild_id =:= 0 of
		true ->
			ok;
		false ->
			[GaLv, GaStage, GaStageExp] = lib_guild_ga:get_ga_stage(GuildId),
			{MId, _} = data_guild:get_ga_mod_id(GaLv),
			{ok, BinData} = pt_403:write(40350, [GaLv, GaStage, GaStageExp, MId]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end,
	ok;

%% -----------------------------------------------------------------
%% 捐献给帮派神兽
%% -----------------------------------------------------------------
handle(40351, UniteStatus, [Num]) ->
	GuildId = UniteStatus#unite_status.guild_id,
	RoleId = UniteStatus#unite_status.id,
	case UniteStatus#unite_status.guild_id =:= 0 of
		true ->
			ok;
		false ->
			Res = lib_guild_ga:ga_donate_stage(GuildId, RoleId, Num),
			{ok, BinData} = pt_403:write(40351, [Res]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end,
	ok;

%% -----------------------------------------------------------------
%% 查看申请加入帮派设置
%% -----------------------------------------------------------------
handle(40352, UniteStatus, _) ->
	GuildId = UniteStatus#unite_status.guild_id,
	case lib_guild:get_guild(GuildId) of
		TGuild when is_record(TGuild, ets_guild) ->
			Type = TGuild#ets_guild.apply_setting,
			[Level, Power] = TGuild#ets_guild.auto_passconfig,
			{ok, BinData} = pt_403:write(40352, [Type, Level, Power]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		_->
			skip
	end;

%% -----------------------------------------------------------------
%% 申请加入帮派设置
%% -----------------------------------------------------------------
handle(40353, UniteStatus, [Type, Level, Power]) when Type > 0 andalso Type =< 3 ->
	GuildId = UniteStatus#unite_status.guild_id,
	Position = UniteStatus#unite_status.guild_position,
	case Position > 0 andalso Position < 3 of 
		true ->
			case lib_guild:get_guild(GuildId) of 
				TGuild when is_record(TGuild, ets_guild) ->
					SQL = io_lib:format(?SQL_GUILD_UPDATE_APPLYSETTING, [Type, util:term_to_string([Level, Power]), GuildId]),
					db:execute(SQL),
					NewTTGuild = TGuild#ets_guild{apply_setting = Type, auto_passconfig = [Level, Power]},
					lib_guild:update_guild(NewTTGuild),
					Result = 1;
				_ -> 
					Result = 0
			end;
		false ->
			Result = 2
	end,
	{ok, BinData} = pt_403:write(40353, [Result]),
	lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
handle(_Cmd, _Status, _Data) ->
    ?ERR("pp_guild no match", []),
    {error, "pp_guild no match"}.

send_fuli_unite(PlayerId, GoodsList, Type) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
            gen_server:call(Pid, {send_fuli_unite, Type, GoodsList});
        _ ->
            0
    end.

send_furnaceback_unite(PlayerId, {'furnaceback', Bcoin}) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'furnaceback', Bcoin});
        _ ->
            0
    end.
