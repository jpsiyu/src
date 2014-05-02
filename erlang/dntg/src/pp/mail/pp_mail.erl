%% --------------------------------------------------------
%% @Module:           |pp_mail
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-04-16
%% @Description:      |邮件处理
%% --------------------------------------------------------
-module(pp_mail).
-export([handle/3, handle_server/3, mail_ban_log/4, bg_score_add/3]).
-include("common.hrl").
-include("mail.hrl").
-include("unite.hrl").
-include("server.hrl").

%% 客户端发信
handle(19001, UniteStatus, Data) ->
	%% 每日邮件发送数量
	MailToday = mod_daily_dict:get_count(UniteStatus#unite_status.id, 1900001),
	case MailToday >= 50 orelse UniteStatus#unite_status.lv < 20 orelse (MailToday > 10 andalso UniteStatus#unite_status.lv < 40) of
		true ->
			{ok, BinData12} = pt_190:write(19001, [12, []]),   
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData12),
			ok;
		false ->
			mod_daily_dict:increment(UniteStatus#unite_status.id, 1900001),
		    [NameList, Title, Content, GoodsId, GoodsNum, Coin] = Data,
            {ok, BinData} = case lib_mail:send_priv_mail(UniteStatus, NameList, Title, Content, GoodsId, GoodsNum, Coin) of
                {ok, ok} ->
                    pt_190:write(19001, [1, []]);            %% 发送成功
                {error, Reason} ->
                    pt_190:write(19001, [Reason, []]);
                {_VList, IList, ok} ->  
                    %% {发送成功名单，发送失败名单}
                    case IList of
                        [] ->
                            pt_190:write(19001, [1, []]);    %% 发送成功
                        _ ->
                            pt_190:write(19001, [6, IList])  %% 部分发送失败
                    end;
				_R ->
					pt_190:write(19001, [0, []])    %% 发送成功
            end,
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
            lib_unite:refresh_client(2, UniteStatus#unite_status.sid),   %% 刷新背包
            {ok, UniteStatus}
	end;

%% 获取信件
handle(19002, UniteStatus, MailId) ->
    case lib_mail:get_mail(MailId, UniteStatus#unite_status.id) of
        {ok, Mail} ->
            {ok, BinData} = pt_190:write(19002, [1 | Mail]);
        {error, ErrorCode} ->
            {ok, BinData} = pt_190:write(19002, [ErrorCode | MailId])
    end,
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 删除信件
handle(19003, UniteStatus, Data) ->
    IdList = Data,
    case lib_mail:del_mail(IdList, UniteStatus#unite_status.id) of
        ok ->
            {ok, BinData} = pt_190:write(19003, 1);
        _ ->
            {ok, BinData} = pt_190:write(19003, 0)
    end,
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 获取信件列表
handle(19004, UniteStatus, get_maillist) ->
    Maillist = lib_mail:get_sub_maillist(UniteStatus#unite_status.id),   %% 获取用户信件列表
    CurrTimestamp = util:unixtime(),
    {ok, BinData} = pt_190:write(19004, [1, CurrTimestamp, Maillist]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 查询有无未读邮件
handle(19005, UniteStatus, check_unread) ->
    Maillist = lib_mail:get_sub_maillist(UniteStatus#unite_status.id),
    Result = lib_mail:check_unread(Maillist),
    {ok, BinData} = pt_190:write(19005, Result),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 提取附件
handle(19006, UniteStatus, MailId) ->
    case lib_mail:get_attachment(UniteStatus, MailId) of
        {ok, GoodsId, IsGetMoneySuc} ->
            {ok, BinData} = pt_190:write(19006, [1, MailId, GoodsId, IsGetMoneySuc]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
        {error, ErrorCode} ->
            {ok, BinData} = pt_190:write(19006, [ErrorCode, MailId, 0, 0]),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
    end,
    lib_unite:refresh_client(2, UniteStatus#unite_status.sid),   %% 刷新背包
    {ok, UniteStatus};

%% 邮件锁定与解锁
handle(19007, UniteStatus, MailId) ->
    Result = lib_mail:change_lock_state(MailId, UniteStatus#unite_status.id),
    {ok, BinData} = pt_190:write(19007, Result),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);

%% 发送帮派邮件
handle(19008, UniteStatus, [Title, Content]) ->
    case lib_mail:send_guild_mail(UniteStatus, Title, Content) of
        {ok, ok} ->
            {ok, BinData} = pt_190:write(19008, 1),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
        {error, Error} ->
            {ok, BinData} = pt_190:write(19008, Error),
            lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
        _ ->
            skip
    end;

%% 处理玩家反馈信息
handle(19010, UniteStatus, Data) ->
    [Type, Title, Content] = Data,
	Timestamp = util:unixtime(),
    InValid1 = util:check_keyword(Title),
	InValid2 = lib_mail:check_content(Content),
	case InValid1 =:= true orelse InValid2 =/= true of
		true ->
			{ok, BinData} = pt_190:write(19010, [3]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData);
		false ->
			Res = case get(send_to_gm_time) of
				undefined ->
					PlayerId = UniteStatus#unite_status.id,
				    [EtsUnite] = mod_chat_agent:lookup(PlayerId),
				    PlayerName = EtsUnite#ets_unite.name,
					Socket = UniteStatus#unite_status.socket,
		            Address = util:get_ip(Socket),
					lib_mail:feedback(Type, Title, Content, Address, PlayerId, PlayerName),
					put(send_to_gm_time, Timestamp),
					1;
				TimeS ->
					case TimeS + 60 * 10 < Timestamp of
						true ->
							PlayerId = UniteStatus#unite_status.id,
						    [EtsUnite] = mod_chat_agent:lookup(PlayerId),
						    PlayerName = EtsUnite#ets_unite.name,
							Socket = UniteStatus#unite_status.socket,
							Address = util:get_ip(Socket),
							lib_mail:feedback(Type, Title, Content, Address, PlayerId, PlayerName),
							put(send_to_gm_time, Timestamp),
							1;
						false ->
							0
					end
			end,	
			{ok, BinData} = pt_190:write(19010, [Res]),
			lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData)
	end;

handle(_, _, _) ->
    ?DEBUG("pp_mail no match", []),
    {error, "pp_mail no match"}.

%% 防工作室(只能在游戏线调用)
mail_ban_log(PS, ReceiverId, GoodsId, Coin) ->
	ScoreNow = lib_anti_brush:get_anti_brush_score(PS),
	case ScoreNow >= ?MAIL_S_LIMIT of
		true ->
			skip;
		false ->
			case GoodsId =:= 0 andalso Coin < ?MAIL_C_LIMIT of
				true ->
					skip;
				false ->
					mod_mail_check:one_mail([PS#player_status.id, ReceiverId, GoodsId, Coin])
			end
	end.
	
%% 处理玩家反馈信息
handle_server(19011, PS, Data) ->
    [ZhanLi, Time, Title, Content, ConType, Con] = Data,
	NowTime = util:unixtime(),
	IsTimeOk = case get(send_to_fb) of
		undefined ->
			ok;
		STime ->
			case STime + 60 * 10 < NowTime of
				true ->
					ok;
				false ->
					{ok, BinDataT} = pt_190:write(19011, [3]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinDataT),
					false
			end
	end,
	case IsTimeOk of
		ok ->
			InValid1 = util:check_keyword(Time),
			InValid2 = lib_mail:check_content(Title),
		    InValid3 = lib_mail:check_content(Content),
			InValid4 = lib_mail:check_content(Con),
			case InValid1 =:= true orelse InValid2 =/= true orelse InValid3 =/= true orelse InValid4 =/= true of
				true ->
					{ok, BinData} = pt_190:write(19011, [2]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData);
				false ->
					put(send_to_fb, NowTime),
					CZ = lib_recharge:get_total(PS#player_status.id),
					save_19011(PS#player_status.id
							  , PS#player_status.nickname
							  , ZhanLi
							  , CZ
							  , NowTime
							  , Time
							  , Title
							  , Content
							  , ConType
							  , Con),
					{ok, BinData} = pt_190:write(19011, [1]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData),
					ok
			end;
		_ ->
			ok
	end;

%% 查询反馈记录
handle_server(19012, PS, [PageN]) ->
	NowTime = util:unixtime(),
	case PageN > 0 of
		true ->
			LastCheckTime = case get(cha_19012_time) of
				undefined ->
					0;
				Value ->
					Value
			end,
			PageAll = case NowTime - LastCheckTime > 10 of
				true ->
					Dlist = get_f_info_db(PS#player_status.id),
					put(cha_19012, Dlist),
					Dlist;
				false ->
					case get(cha_19012) of
						undefined ->
							Dlist = get_f_info_db(PS#player_status.id),
							put(cha_19012, Dlist),
							Dlist;
						Value2 ->
							Value2
					end
			end,
			{ok, BinData} = pt_190:write(19012, [1, PageAll]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		false ->
			ok
	end;

%% 查询反馈积分
handle_server(19013, PS, Data) ->
	case Data > 0 of
		true ->
			ScoreAllOld = get_s_info_db(PS#player_status.id),
			{ok, BinData} = pt_190:write(19013, [1, ScoreAllOld]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		false ->
			ok
	end;

%% 反馈积分兑换
handle_server(19014, PS, [GiftId]) ->
	case GiftId of
		1 ->
			case del_score(PS#player_status.id, 50) of
				{ok, 1} ->
					Go = PS#player_status.goods,
					case gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', [], [{534069, 1}]}) of
						ok ->
							{ok, BinData} = pt_190:write(19014, [1]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData);
						_ ->
							{ok, BinData} = pt_190:write(19014, [0]),
							lib_server_send:send_to_sid(PS#player_status.sid, BinData)
					end;
				_ ->
					{ok, BinData} = pt_190:write(19014, [0]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			end,
			ok;
		_ ->
			ok
	end;

%% 查看反馈详情
handle_server(19015, PS, [FKId]) ->
	case FKId > 0 of
		true ->
			FKList = case get(cha_19012) of
				undefined ->
					Dlist = get_f_info_db(PS#player_status.id),
					put(cha_19012, Dlist),
					Dlist;
				Value2 ->
					Value2
			end,
			case [Content || [Id, _Time, _Title, Content, _Opt, _Score] <- FKList, Id == FKId] of
				[NewFk] ->
					{ok, BinData} = pt_190:write(19015, [1, FKId, NewFk]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData);
				_ ->
					{ok, BinData} = pt_190:write(19015, [0, FKId, <<>>]),
					lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			end,
			ok;
		_ ->
			ok
	end;

handle_server(_, _, _) ->
    ?DEBUG("pp_mail no match", []),
    {error, "pp_mail no match"}.

save_19011(RoleId, RoleName, ZhanLi, CZ, NowTime, Time, Title, Content, ConType, Con) ->
	Sql = io_lib:format("insert into feedback_private(
role_id, role_name, power, pay_num, TIME, h_time, title, content, context_type, context) 
values(~p, '~s', ~p, ~p, ~p, '~s', '~s', '~s', ~p, '~s')"
					   , [RoleId, RoleName, ZhanLi, CZ, NowTime, Time, Title, Content, ConType, Con]),
	db:execute(Sql).

get_f_info_db(RoleId) ->
	Sql = io_lib:format("select id, TIME, title, content, opt, score from feedback_private where role_id = ~p ", [RoleId]),
	case db:get_all(Sql) of
		[] ->
			[];
		List ->
			List
	end.

get_s_info_db(RoleId) ->
	Sql2 = io_lib:format("select score from feedback_score where role_id = ~p ", [RoleId]),
	case db:get_one(Sql2) of
		ScoreAllOld when erlang:is_integer(ScoreAllOld)->
			ScoreAllOld;
		_ ->
			0
	end.

del_score(RoleId, ScoreDel) ->
	case db:transaction(fun() -> del_score_db(RoleId, ScoreDel) end) of
		{ok, N} ->
			{ok, N};
		_ ->
			error
	end.

del_score_db(RoleId, ScoreDel) ->
	Sql2 = io_lib:format("select score from feedback_score where role_id = ~p ", [RoleId]),
	case db:get_one(Sql2) of
		ScoreAllOld when erlang:is_integer(ScoreAllOld)->
			case ScoreAllOld >= ScoreDel of
				true ->
					Sql3 = io_lib:format("replace into feedback_score(role_id, score) values (~p, ~p)", [RoleId, ScoreAllOld - ScoreDel]),
					db:execute(Sql3),
					{ok, 1};
				false ->
					{ok, 2}
			end;
		_ ->
			{ok, 0}
	end.

bg_score_add(RoleId, Score, CId) ->
	case db:transaction(fun() -> bg_score_add_db(RoleId, Score, CId) end) of
		ok ->
			ok;
		_ ->
			error
	end.

bg_score_add_db(RoleId, Score, CId) ->
	Sql = io_lib:format("update feedback_private set opt = ~p, score = ~p where id =~p ", [1, Score, CId]),
	db:execute(Sql),
	Sql2 = io_lib:format("select score from feedback_score where role_id = ~p ", [RoleId]),
	ScoreAllNew = case db:get_one(Sql2) of
		ScoreAllOld when erlang:is_integer(ScoreAllOld)->
			ScoreAllOld + Score;
		_ ->
			Score
	end,
	Sql3 = io_lib:format("replace into feedback_score(role_id, score) values (~p, ~p)", [RoleId, ScoreAllNew]),
	db:execute(Sql3),
	ok.
	