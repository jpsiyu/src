%% --------------------------------------------------------
%% @Module:           |lib_mail
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-04-16
%% @Description:      |邮件处理LIB 
%% --------------------------------------------------------
-module(lib_mail).
-export(
    [
        change_lock_state/2,        %% 邮件锁定与解锁
        check_keyword/2,            %% 检查字符串中是否存在非法字符
        check_unread/1,             %% 查询是否存在未读信件及将过期的附件
        clean_mail/0,               %% 清除过期邮件
        del_mail/2,                 %% 删除信件
        delete_role/1,              %% 删除角色时清除邮件数据
        feedback/6,                 %% 玩家反馈（GM提交）
        get_attachment/2,           %% 获取附件
        get_goods_type_id/1,        %% 获取物品类型ID
        get_mail/2,                 %% 获取邮件
        get_sub_maillist/1,         %% 获取邮件列表
        get_unixtime/0,             %% 获取Unix时间戳（微秒）
        make_insert_sql/3,          %% 生成插入多条记录的语句
        pack_urls/1,                %% Url信息列表打包成二进制数据（数据打包使用）
        rand_insert_mail/3,         %% 随机插入信件（测试用） 
        send_priv_mail/7,           %% 发送私人邮件
        send_sys_mail/3,            %% 发送系统邮件（无附件）
        send_sys_mail/7,            %% 发送系统邮件（向单个角色发放金钱，未更新内存邮件数据）
        unixtime_to_time_string/1,  %% 时间戳转换为易识别时间字符串
        update_mail_info/3,         %% 更新所有战区角色邮件数据
        role_login/1,      			%% 上线初始化角色邮件数据
		save_mail_dict/2,			%% 保存或更新整个Mail进程字典
		get_mail_dict/1,			%% 获取Mail进程字典内容
		get_mail_dict/2,			
  		get_mail_dict/3,
		get_mail_by_MailID/2,  		%% 根据mailid获取邮件
		update_mail_by_one/2,		%% 更新Mail进程字典___由于单个邮件信息改变
		insert_mail_by_one/2,		%% 向进程字典插入一个邮件
	 	delete_mail_by_MailId/2		%% 删除Mail进程字典中一个邮件
	 ]).
-compile(export_all).
-include("common.hrl").
-include("record.hrl").
-include("server.hrl").
-include("goods.hrl").
-include("unite.hrl").
-include("mail.hrl").
-include("rela.hrl").
-include("guild.hrl").
-include("def_goods.hrl").

%% 邮件锁定与解锁
%% @spec change_lock_state(MailId, PlayerId) -> {Result, MailId}
%%  Result : 0 => 锁定失败(无信件)  1 => 锁定成功  2 => 锁定失败(数量限制)  3 => 解锁成功
change_lock_state(MailId, PlayerId) ->
	MailSelect = get_mail_by_MailID(PlayerId, MailId),
    case MailSelect of
        [] ->   %% 无该信件
            {0, MailId};
        Mail ->
            Locked = Mail#mail.locked,
            case Locked of
                1 ->    %% 已锁定的邮件，执行解锁操作
                    Sql = lists:concat(["update mail_attr set locked = 2 where id = ", MailId, " limit 1"]),
                    db:execute(Sql),
					MailSelectNew = MailSelect#mail{locked = 2},
					update_mail_by_one(PlayerId, MailSelectNew),
                    {3, MailId};
                _ ->    %% 未锁定的邮件，执行锁定操作
					LockedListx = get_mail_dict(PlayerId),
					LockedList = [NListx||NListx<-LockedListx, NListx#mail.locked =:= 1],
                    case length(LockedList) < ?MAX_LOCK_NUM of
                        true ->
                            Sql = lists:concat(["update mail_attr set locked = 1 where id = ", MailId, " limit 1"]),
                            db:execute(Sql),
                            MailSelectNew = MailSelect#mail{locked = 1},
							update_mail_by_one(PlayerId, MailSelectNew),
                            {1, MailId};
                        false ->    %% 锁定数量达到上限
                            {2, MailId}
                    end
            end
    end.

%% 检查内容（数据库字符集UTF-8，为varchar(500)，限制160汉字）
check_content(Content) ->
    case util:check_length(Content, 320) of
        true ->
            case check_keyword(Content, ?ESC_CHARS) of
                false ->
                    true;
                true ->
                    {error, ?CONTENT_SENSITIVE}
            end;
        false ->
            {error, ?WRONG_CONTENT}       %% 内容长度非法
    end.

%% 检查帐户情况
%% @spec check_fee(BCoin, Coin, CostA, CostB) -> {ok, NewBCoin, NewCoin} | {error, ErrorCode}
%%      CostA : 优先使用绑定铜支付，不足以非绑定铜支付；CostB : 非绑定铜支付
check_fee(BCoin, Coin, CostA, CostB) ->
    case BCoin > CostA of
        true ->
            NewBCoin = BCoin - CostA,
            NewCoin  = Coin  - CostB;
        false ->
            NewBCoin = 0,
            NewCoin  = Coin + BCoin - CostA - CostB
    end,
    case NewCoin >= 0 of
        true ->
            {ok, NewBCoin, NewCoin};
        false ->
            {error, ?NOT_ENOUGH_COIN}
    end.

%% 检查关键字，存在非法字符返回true，否则false
%% @spec check_keyword(Text, Words) -> false | true
%% @param Text : 需要检查的字符串（或字符串的二进制形式）
%% @param Words: 非法字符列表
check_keyword(_, []) ->
    false;
check_keyword(Text, [Word | Words]) ->
    case re:run(Text, Word, [{capture, none}]) of
        match ->
            true;
        nomatch ->
            check_keyword(Text, Words)
    end.

%% 检查信件是否合法，如合法，返回有效的角色信息列表与无效的角色信息列表
%% @spec check_mail(Type, NameList, Title, Content, GoodsId, Coin, SenderName) ->
%%          {ok, {PlayerId, PlayerName}} | {error, ErrorCode} | {VList, IList}
%%      VList : {PlayerId, PlayerName}
%%      IList : {   0    , PlayerName}
check_mail(Type, NameList, Title, Content, GoodsId, Coin, SenderName) ->
    F = fun() ->
            G = fun(Item) ->
                    PlayerName = object_to_list(Item),  %% 确保名字为字符串
                    check_name(PlayerName)
            end,
            case length(NameList) of
                1 ->
                    [Item] = NameList,
                    case (GoodsId > 0 orelse Coin > 0) andalso SenderName =:= Item of
                        true ->
                            {error, ?CANNOT_SEND_TO_SELF};
                        false ->
                            case G(Item) of
                                {0, _} ->
                                    {error, ?WRONG_NAME};
                                {PlayerId, PlayerName} ->
                                    {ok, {PlayerId, PlayerName}}
                            end
                    end;
                _ ->
                    case GoodsId == 0 andalso Coin == 0 of
                        true ->
                            NewNameList = [G(Item) || Item <- NameList],
                            {VList, IList} = lists:partition(
                                fun(X) ->
                                        {PlayerId, _} = X,
                                        PlayerId /= 0
                                end,
                                NewNameList),
                            case VList of
                                [] ->
                                    {error, ?WRONG_NAME};
                                _ ->
                                    {VList, IList}
                            end;
                        false ->            %% 发信给多人有附件，不合法
                            {error, ?CANNOT_SEND_ATTACH}
                    end
            end
    end,
    case Type of
        priv ->
            case check_mail_title_and_content(Title, Content) of
                true ->
                    F();
                Error ->
                    Error
            end;
        sys ->
            case util:check_length(Title, 50) of
                true ->
                    case util:check_length(Content, 500) of
                        true ->
                            F();
                        false ->
                            {error, ?WRONG_CONTENT}
                    end;
                false ->
                    {error, ?WRONG_TITLE}
            end
    end.

%% 检查邮件标题和内容
check_mail_title_and_content(Title, Content) ->
    case check_title(Title) of      %% 检查标题合法性
        true ->
            case check_content(Content) of  %% 检查内容合法性
                true ->
                    true;
                Error ->
                    Error
            end;
        Error ->
            Error
    end.

%% 检查是否存在角色，返回角色Id和角色名字，如果角色不存在，返回Id为0
%% @spec check_name(Name) -> {PlayerId, PlayerName}
check_name(Name) ->
%%     case ets:match(?ETS_UNITE, #ets_unite{name = Name, id = '$1', _ = '_'}) of
	case mod_chat_agent:match(match_name, [util:make_sure_list(Name)]) of
        [] ->
            case check_keyword(util:make_sure_list(Name), ?ESC_CHARS) of
                true ->     %% 名字中含破坏SQL语句的非法字符
                    {0, Name};
                false ->
                    case lib_player:get_role_id_by_name(util:make_sure_list(Name)) of
                        null ->
                            {0, Name};
                        PlayerId ->
                            {PlayerId, Name}
                    end
            end;
        [Player] ->
            {Player#ets_unite.id, Name}
    end.

%% 检查主题长度（数据库字符集UTF-8，为varchar(50)，限制16汉字）
check_title(Title) ->
    case util:check_length(Title, 32) of
        true ->
            case check_keyword(Title, ?ESC_CHARS) of
                false ->
                    true;
                true ->
                    {error, ?TITLE_SENSITIVE}
            end;
        false ->
           {error, ?WRONG_TITLE}     %% title长度非法
   end.

%% 查询未读邮件数（用于下线保存时查询）-------待修改
get_unread_num(PlayerId) ->
	MailIdListx = get_mail_dict(PlayerId),
	MailIdList = [NList||NList<-MailIdListx,NList#mail.state =:= 2],
    length(MailIdList).

%% 检查未读邮件及即将过期的附件邮件 -> [AnyUnread, AnyWillOutDate, UnreadNum]
check_unread(Maillist) ->
    NowTime = util:unixtime(),
    [UnreadNum, AnyWillOutDate, _] = lists:foldl(fun check_unread/2, [0, 0, NowTime], Maillist),
    AnyUnread =
    case UnreadNum > 0 of
        true -> 1;
        false -> 0
    end,
    [AnyUnread, AnyWillOutDate, UnreadNum].

check_unread(EtsMail, [UnreadNum, AnyWillOutDate, NowTime]) ->
    NewUnreadNum =
    case EtsMail#mail.state =:= 2 of
        true -> UnreadNum + 1;
        false -> UnreadNum
    end,
    NewAnyWillOutDate =
    case AnyWillOutDate =:= 1 of
        true -> 1;
        false ->
            case EtsMail#mail.locked =:= 2 andalso (NowTime - EtsMail#mail.timestamp > ?WARN_TIME) of
                true ->
                    case (EtsMail#mail.goods_id + EtsMail#mail.bcoin + EtsMail#mail.coin + EtsMail#mail.silver + EtsMail#mail.gold) > 0 of
                        true -> 1;
                        false -> AnyWillOutDate
                    end;
                false ->
                    AnyWillOutDate
            end
    end,
    [NewUnreadNum, NewAnyWillOutDate, NowTime].

%% 清理过期邮件
%% @spec clean_mail() -> ok 
clean_mail() ->
    NowTime = get_unixtime(),
    Time = NowTime - ?TIME_LIMIT * 1000000,
    Sql = lists:concat(["select id,uid,goods_id,id_type,goods_num from mail_attr where locked=2 and timestamp<=", Time, " limit 1"]),
    clean_mail(Sql).

%% 清理邮件
clean_mail(Sql) ->
    case (catch db:get_all(Sql)) of
        [[MailId, PlayerId, GoodsId, IdType, GoodsNum]] ->
            del_out_date_mail([MailId, PlayerId, GoodsId, IdType, GoodsNum]),
            timer:sleep(3000),
            clean_mail(Sql);
        [] ->
            ok;
        Other ->
            ?ERR("~nSql:~p~nErrorInfo:~w~n", [Sql, Other])
    end.

%% 上线清理邮件----------待修改
clean_mail_while_login(PlayerId, DelNum) ->
	Maillistx = get_mail_dict(PlayerId),
	Maillist = [NList||NList<-Maillistx,NList#mail.goods_id=:=0 
										andalso NList#mail.bcoin=:=0 
										andalso NList#mail.coin=:=0 
										andalso NList#mail.silver=:=0 
										andalso NList#mail.gold=:=0],
    NewList = lists:sort(fun sort_by_time_asc/2, Maillist),
    SubMaillist = lists:sublist(NewList, DelNum),
    lists:foreach(fun(Mail) -> timer:sleep(500), del_one_mail(PlayerId, Mail) end, SubMaillist),
    refresh_maillist(PlayerId).



%% 根据Id列表删除信件
%% @spec del_mail(IdList, PlayerId) -> ok | error
del_mail(IdList, PlayerId) when is_list(IdList) ->
	%%Maillist = lists:flatten( [ ets:select(?ETS_MAIL, [{#mail{id = Id, locked = 2, uid = PlayerId, _ = '_'}, [], ['$_']}]) || Id <- IdList ] ),
	Maillist = [get_mail_by_MailID(PlayerId, Id)|| Id <- IdList],
    lists:foreach(fun(Mail) -> del_one_mail(PlayerId, Mail) end, Maillist),
    refresh_maillist(PlayerId),
    ok;
del_mail(_, _) ->
    error.



%% 删除一封信件，退回附件
del_one_mail(PlayerId, Mail) when is_record(Mail, mail) ->
    MailId    = Mail#mail.id,
    Locked    = Mail#mail.locked,
    GoodsId   = Mail#mail.goods_id,
    BCoin     = Mail#mail.bcoin,
    Coin      = Mail#mail.coin,
    Silver    = Mail#mail.silver,
    Gold      = Mail#mail.gold,
    Money = BCoin + Coin + Silver + Gold,
    if
        Locked == 1 ->      %% 邮件锁定，不删除
            skip;
        true ->
            case Money /= 0 orelse GoodsId /= 0 of
                true ->     %% 有附件，不删除
                    skip;
                false ->
                    del_mail_from_database(MailId),
					delete_mail_by_MailId(PlayerId, MailId)
            end
    end;
del_one_mail(_PlayerId, _) ->
    skip.

%% 从数据库中删除信件
del_mail_from_database(MailId) ->
    Sql = lists:concat(["SELECT id FROM mail_content WHERE id=", MailId, " LIMIT 1"]),
    case db:get_one(Sql) of
        null ->
            SqlDel = lists:concat(["DELETE FROM mail_attr WHERE id=", MailId, " LIMIT 1"]),
            db:execute(SqlDel);
        _ ->
            F = fun() ->
                    SqlDel1 = lists:concat(["DELETE FROM mail_attr WHERE id=", MailId, " LIMIT 1"]),
                    SqlDel2 = lists:concat(["DELETE FROM mail_content WHERE id=", MailId, " LIMIT 1"]),
                    db:execute(SqlDel1),
                    db:execute(SqlDel2)
            end,
            db:transaction(F)
    end,
    ok.
%% 删除过期邮件操作
del_out_date_mail([MailId, PlayerId, GoodsId, IdType, GoodsNum]) ->
    del_mail_from_database(MailId),
    case IdType == 0 andalso GoodsId /=0 of
        true ->     %% 附件为实际物品
            Sql = lists:concat(["select gh.goods_id, gh.location, gl.prefix, gl.stren from goods_high gh left join `goods_low` gl on gh.gid=gl.gid where gh.gid = ", GoodsId, " limit 1"]),
            case db:get_all(Sql) of
                [[GoodsTypeId, Location, Prefix, Stren]] ->
                    case Location =:= ?GOODS_LOC_MAIL of
                        true ->
                            lib_goods_util:delete_goods(GoodsId),
                            log:log_throw(throw, PlayerId, GoodsId, GoodsTypeId, GoodsNum, Prefix, Stren);
                        false ->
                            skip
                    end;
                _ ->    %% 已经找不到物品了
                    skip
            end;
        false ->
            skip
    end,
    del_out_date_ets_mail(PlayerId, MailId).

del_out_date_ets_mail(PlayerId, MailId) ->
    case lib_player:is_online_unite(PlayerId) of
        true ->
			delete_mail_by_MailId(PlayerId, MailId), %%删除MAIL字典中的
            CurrTimestamp = util:unixtime(),
			Maillist = get_sub_maillist(PlayerId),   %% 获取用户信件列表
            {ok, BinData} = pt_190:write(19004, [1, CurrTimestamp, Maillist]),
            lib_unite_send:send_to_one(PlayerId, BinData),
            ok;
        false ->
            ok
    end.

%% 数据库中去掉邮件物品附件（由物品进程的事务中处理）
delete_attachment_on_db(MailId) ->
    Sql = lists:concat(["update mail_attr set goods_id = 0, goods_num = 0 where id = ", MailId, " limit 1"]),
    db:execute(Sql).

%% 去掉信件的物品附件
delete_attachment_on_ets(PlayerId,MailId) ->
	Mail = get_mail_by_MailID(PlayerId,MailId),
    NewMail = Mail#mail{
        goods_id = 0,
        goods_type_id = 0,
        goods_num = 0
    },
	update_mail_by_one(PlayerId, NewMail).

%% 数据库中去掉邮件钱币附件
delete_mail_money_on_db(MailId) ->
    Sql = lists:concat(["update mail_attr set bcoin = 0, coin = 0, silver = 0, gold = 0 where id = ", MailId, " limit 1"]),
    db:execute(Sql).

%% 去掉信件中的钱币附件
delete_mail_money_on_ets(PlayerId,MailId) ->
	Mail = get_mail_by_MailID(PlayerId,MailId),
    NewMail = Mail#mail{
        bcoin = 0,
        coin = 0,
        silver = 0,
        gold = 0
    },
	update_mail_by_one(PlayerId, NewMail).

%% 去除邮件中的过期物品
delete_mail_goods_on_db(GoodsId) ->
    Sql = lists:concat(["update mail_attr set goods_id = 0 where goods_id = ", GoodsId, " limit 1"]),
    db:execute(Sql).

%% 删除角色，清理邮件数据
delete_role(PlayerId) ->
    Sql1 = lists:concat(["delete from mail_attr where uid = ", PlayerId]),
    Sql2 = lists:concat(["delete from mail_content where player_id = ", PlayerId]),
    db:execute(Sql1),
    db:execute(Sql2),
    ok.

%% 插入玩家反馈至数据库的feedback表
feedback(Type, Title, Content, Address, PlayerId, PlayerName) ->
    Server = atom_to_list(node()),
    Timestamp = util:unixtime(),
    {A, B, C, D} = Address,
    IP = lists:concat([A, ".", B, ".", C, ".", D]),
    Sql = lists:concat(["insert into feedback (type, player_id, player_name, title, content, timestamp, ip, server) values (", Type, ",", PlayerId, ",'", PlayerName, "','", Title, "','", Content, "',", Timestamp, ",'", IP, "','", Server, "')"]),
    db:execute(Sql).

%% 获取附件(物品和钱币是分开事务处理的)
%% 操作顺序_先清除附件_后交给玩家
%% @spec get_attachment(PlayerStatus, MailId) -> {ok, GoodsId, NewPlayerStatus, IsGetMoneySuc} | {error, Reason}
get_attachment(UniteStatus, MailId) ->
    case get_mail(MailId, UniteStatus#unite_status.id) of
        {ok, Mail} ->
			case lib_player:get_player_info(UniteStatus#unite_status.id, pid) of
				PlayerServerPid when is_pid(PlayerServerPid) ->
					%% 清除金钱
					delete_mail_money_on_ets(UniteStatus#unite_status.id, MailId),
					InfoPack = {get_attachment, [Mail, UniteStatus#unite_status.id]},
					case gen_server:call(PlayerServerPid, InfoPack) of
						{ok, GoodsId, IsGetMoneySuc} ->
							%% 清除物品
							delete_attachment_on_ets(UniteStatus#unite_status.id, MailId),
							{ok, GoodsId, IsGetMoneySuc};
						{error, ErrorCode} ->
							{error, ErrorCode};
						_ ->
							{error, ?OTHER_ERROR}
					end;
				_ ->
					{error, ?OTHER_ERROR}
			end;
        {error, _} ->
            {error, ?OTHER_ERROR}
    end.

%% 获取邮件附件处理(仅限mod_server_call中调用)
%% @spec get_attachment(Mail, PlayerId, PlayerStatus) -> {ok, GoodsId, NewPlayerStatus, IsGetMoneySuc} | {error, PlayerStatus}
get_attachment_server(Mail, _PlayerId, PlayerStatus) ->
	MailId = Mail#mail.id,
	GoodsId = Mail#mail.goods_id,
	IdType = Mail#mail.id_type,
	Bind = Mail#mail.bind,
	Stren = Mail#mail.stren,
	Prefix = Mail#mail.prefix,
	GoodsNum = Mail#mail.goods_num,
	BCoin = Mail#mail.bcoin,
	Coin = Mail#mail.coin,
	Silver = Mail#mail.silver,
	Gold = Mail#mail.gold,
	Money = BCoin + Coin + Silver + Gold,
	NewBCoin = PlayerStatus#player_status.bcoin + BCoin,
	NewCoin = PlayerStatus#player_status.coin + Coin,
	NewSilver = PlayerStatus#player_status.bgold + Silver,
	NewGold = PlayerStatus#player_status.gold + Gold,
	case GoodsId == 0 andalso Money == 0 of
		false ->            %% 有附件
			case GoodsId == 0 of
				false ->        %% 有物品
					case Money == 0 of
						true ->     %% 仅物品附件
							case handle_goods_recv(PlayerStatus, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, MailId, Mail) of
								ok ->
									%% 修改邮件缓存
%% 									delete_attachment_on_ets(PlayerStatus#player_status.id, MailId),
									case IdType == 0 of
										true ->     %% GoodsId返回给客户端，以清除该物品的缓存
											{ok, GoodsId, PlayerStatus, 1};
										false ->
											{ok, 0, PlayerStatus, 1}
									end;
								{error, ErrorCode} ->
									{error, ErrorCode}
							end;
						false ->    %% 同时有物品和钱币附件
							case handle_goods_recv(PlayerStatus, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, MailId, Mail) of
								ok ->
									%% 修改邮件缓存
%% 									delete_attachment_on_ets(PlayerStatus#player_status.id, MailId),
									F = fun() ->
												delete_mail_money_on_db(MailId),
												handle_money_recv(PlayerStatus, NewBCoin, NewCoin, NewSilver, NewGold)
										end,
									case db:transaction(F) of
										{ok, NewStatus} ->  %% 收取物品及钱币均成功
											%% 修改邮件缓存
%% 											delete_mail_money_on_ets(PlayerStatus#player_status.id, MailId),
%% 											mod_mail:log_get_money(MailId, Mail#mail.sid, Mail#mail.timestamp, PlayerStatus, NewStatus),
											log_get_money(MailId, Mail#mail.sid, Mail#mail.timestamp, PlayerStatus, NewStatus),
											case IdType == 0 of
												true ->
													{ok, GoodsId, NewStatus, 1};
												false ->
													{ok, 0, NewStatus, 1}
											end;
										_Error ->           %% 收取物品附件成功，但是收取钱币失败
											case IdType == 0 of
												true ->
													{ok, GoodsId, PlayerStatus, 0};
												false ->
													{ok, 0, PlayerStatus, 0}
											end
									end;
								{error, ErrorCode} ->
									{error, ErrorCode}
							end
					end;
				true ->         %% 只有钱币
					F = fun() ->
								delete_mail_money_on_db(MailId),
								handle_money_recv(PlayerStatus, NewBCoin, NewCoin, NewSilver, NewGold)
						end,
					case db:transaction(F) of
						{ok, NewStatus} ->
							%% 修改邮件缓存
%% 							delete_mail_money_on_ets(PlayerStatus#player_status.id, MailId),
%% 							mod_mail:log_get_money(MailId, Mail#mail.sid, Mail#mail.timestamp, PlayerStatus, NewStatus),
							log_get_money(MailId, Mail#mail.sid, Mail#mail.timestamp, PlayerStatus, NewStatus),
							{ok, 0, NewStatus, 1};
						_Error ->
							{error, ?OTHER_ERROR}
					end
			end;
		true ->             %% 无附件
			{error, ?ATTACH_NOT_EXIST}
	end.

%% 根据物品Id获得物品类型Id
%% @spec get_goods_type_id(GoodsId) -> GoodsTypeId | 0
get_goods_type_id(GoodsId) ->
    Sql = lists:concat(["select gtype_id from goods_low where gid = ", GoodsId, " limit 1"]),
    case db:get_all(Sql) of
        [] ->
            0;
        [[GoodsTypeId]] ->
            GoodsTypeId
    end.

%% 帮派玩家Id列表
get_guild_member_id_list(GuildId) ->
	Guild_List = gen_server:call(mod_guild, {get_guild_member, [GuildId, 0]}, 7000),
	[D#ets_guild_member.id||D<-Guild_List].

%% 获取信件		--------待修改
%% @spec get_mail(MailId, PlayerId) -> {ok, Mail} | {error, ErrorCode}
%%  Mail : record()
get_mail(MailId, PlayerId) ->
	MailSelect = get_mail_by_MailID(PlayerId, MailId),
    case MailSelect of
        [] ->
            {error, 2};     %% ErrorCode == 2 表示没有该信件
        Mail ->
            case Mail#mail.content =:= <<>> of
                true ->     %% 信件内容尚未加载
                    Sql1 = lists:concat(["select content from mail_content where id = ", MailId, " limit 1"]),
                    case db:get_all(Sql1) of
                        [] ->       %% 在数据库表mail_content中无该信件
                            {error, 2};
                        [[Content]] ->
                            if
                                Mail#mail.state == 2 ->   %% 更新未读信件状态为已读
                                    Sql2 = lists:concat(["update mail_attr set state = 1 where id = ", MailId, " limit 1"]),
                                    db:execute(Sql2);
                                true ->
                                    ok
                            end,
                            case Mail#mail.type == 1 of
                                true ->     %% 系统邮件检查是否带网址
                                    {ok, NewContent, Urls} = get_new_content(Content);
                                false ->    %% 私人邮件及帮派邮件 不需要处理
                                    NewContent = Content,
                                    Urls = []
                            end,
                            case Mail#mail.sname =:= null of
                                true ->
                                    case get_role_info(Mail#mail.sid) of
                                        [[Bin, SLv]] ->
                                            SName = Bin;
                                        _ ->
                                            SName = <<>>,
                                            SLv = 0
                                    end;
                                false ->
                                    SName = Mail#mail.sname,
                                    SLv = Mail#mail.slv
                            end,
                            NewMail = Mail#mail{state = 1, sname = SName, slv = SLv, content = NewContent, urls = Urls},
                            %%ets:insert(?ETS_MAIL, NewMail),
							update_mail_by_one(PlayerId, NewMail),
                            {ok, NewMail}
                    end;
                false ->    %% 信件内容已经加载
                    {ok, Mail}
            end
    end.

%% 获取用户信件列表
%% @spec get_maillist_from_database(PlayerId) -> Maillist
get_maillist_from_database(PlayerId) ->
    Sql = lists:concat(["select * from mail_attr where uid = ", PlayerId]),
    db:get_all(Sql).


%% 获取匹配替换后的字符串及网址信息
%% @spec get_new_content(OldContent) -> {ok, NewContent, Urls}
get_new_content(OldContent) ->
    case re:split(OldContent, "\\[/url\\]") of  %% 以网址结束标记来划分字符串
        [OldContent] ->
            {ok, OldContent, []};
        BinStrList ->
            F = fun
                ([Bin], NewBinList, Urls, _G) ->
                    NewContent = list_to_binary(lists:reverse([Bin | NewBinList])),
                    {ok, NewContent, lists:reverse(Urls) };
                (BinList, NewBinList, Urls, G) ->
                    [Bin | RestList] = BinList,
                    case re:run(Bin, "\\[url http.*\\]", [{capture, first}]) of
                        nomatch ->
                            NewBinList2 = [ <<"[/url]">> | [ Bin | NewBinList]],
                            G(RestList, NewBinList2, Urls, G);
                        {match, [{Start, Len}]} ->
                            Str = binary_to_list(Bin),
                            SourceUrl = lists:sublist(Str, Start + 6, Len - 6),
                            case (catch lists:nthtail(Start + Len, Str)) of
                                {'EXIT', _} ->
                                    SourceName = SourceUrl;
                                "" ->
                                    SourceName = SourceUrl;
                                SourceName ->
                                    ok
                            end,
                            UrlId = length(Urls),
                            NewUrls = [{UrlId, SourceName, SourceUrl} | Urls],
                            NewBin = list_to_binary( re:replace(Bin, "\\[url.*", lists:concat(["{", UrlId, "}"])) ),
                            NewBinList2 = [NewBin | NewBinList],
                            G(RestList, NewBinList2, NewUrls, G)
                    end
            end,
            F(BinStrList, [], [], F)
    end.

%% %% 后台发信使用 分类在线或不在线玩家
%% splitplayer([], ErrorList, OkList) ->
%% 	{ErrorList, OkList};
%% splitplayer(PlayerInfoList, ErrorList, OkList) ->
%% 	[PlayerInfo|PlayerInfoListNext] = PlayerInfoList,
%% 	case get_role_id(PlayerInfo) of
%% 		0 ->
%% 			ErrorListNext = [PlayerInfo|ErrorList],
%% 			splitplayer(PlayerInfoListNext, ErrorListNext, OkList);
%% 		PlayerId ->
%% 			OkListNext = [PlayerId|OkList],
%% 			splitplayer(PlayerInfoListNext, ErrorList, OkListNext)
%% 	end.




%% 输入角色Id或角色名，获得角色Id,
get_role_id(PlayerInfo) when is_integer(PlayerInfo) ->
    PlayerInfo;
get_role_id(PlayerInfo) when is_list(PlayerInfo) ->
	case mod_chat_agent:match(match_name, [util:make_sure_list(PlayerInfo)]) of
%%     case ets:select(?ETS_UNITE, [{#ets_unite{name = PlayerInfo, id = '$1', _ = '_'}, [], ['$1']}]) of
        [] ->
            case lib_player:get_role_id_by_name(PlayerInfo) of
                null ->
                    0;
                PlayerId ->
                    PlayerId
            end;
        [Player] ->
            Player#ets_unite.id
    end;
get_role_id(PlayerInfo) when is_binary(PlayerInfo) ->
    Name = binary_to_list(PlayerInfo),
    get_role_id(Name);
get_role_id(_) ->
    0.

%% 获取玩家等级
get_role_lv(Id) ->
    Sql = lists:concat(["select lv from player_low where id = ", Id, " limit 1"]),
    db:get_one(Sql).

%% 由角色ID获得角色名
%% @spec get_role_info(Id) -> [[BinName, Lv]] | []
get_role_info(Id) ->
    Sql = lists:concat(["select nickname, lv from player_low where id = ", Id, " limit 1"]),
    db:get_all(Sql).

%% 将列表项格式化成字符串的形式（供生成插入语句时使用）
%% @spec get_string([], List) -> string()
get_string(String, []) ->
    String;
get_string(String, List) ->
    [Item | NewList] = List,
    if
        String =/= [] ->
            case is_list(Item) of
                true ->
                    NewStr = lists:concat([String, ",", "'", Item, "'"]);
                false ->
                    NewStr = lists:concat([String, ",", Item])
            end;
        true ->
            case is_list(Item) of
                true ->
                    NewStr = lists:concat(["'", Item, "'"]);
                false ->
                    NewStr = lists:concat([Item])
            end
    end,
    get_string(NewStr, NewList).

%% 获取一定长度的邮件列表
%% @spec get_sub_maillist(PlayerId) -> Maillist
get_sub_maillist(PlayerId) ->
    Maillist = get_mail_dict(PlayerId),
    case length(Maillist) < ?MAX_LEN_OF_MAILLIST of
        true ->
            Maillist;
        false ->
            NewList = lists:sort(fun sort_by_time_desc/2, Maillist),
            lists:sublist(NewList, ?MAX_LEN_OF_MAILLIST)
    end.
get_sub_maillist_from_others(PlayerId) ->
    Maillist = get_mail_dict_from_others(PlayerId),
    case length(Maillist) < ?MAX_LEN_OF_MAILLIST of
        true ->
            Maillist;
        false ->
            NewList = lists:sort(fun sort_by_time_desc/2, Maillist),
            lists:sublist(NewList, ?MAX_LEN_OF_MAILLIST)
    end.
%% 获得Unix时间戳（微秒数）
get_unixtime() ->
    {Mega, Secs, MicroSecs} = mod_time:now(),
    Mega * 1000000000000 + Secs * 1000000 + MicroSecs.

%% 处理发信时的物品附件
%% @spec handle_goods_send(GoodsPid, GoodsId, IdType, GoodsNum, PlayerId, MailInfo, PlayerInfo) -> {ok, NewGoodsId, MailAttribute} | {error, ErrorCode}
handle_goods_send(GoodsPid, GoodsId, IdType, GoodsNum, PlayerId, MailInfo, PlayerInfo) ->
    case IdType == 0 of     %% GoodsId为物品Id
        true ->
            case gen_server:call(GoodsPid, {'movein_mail', GoodsId, GoodsNum, PlayerId, MailInfo, PlayerInfo}) of
                {ok, NewGoodsId, MailAttribute} ->
                    {ok, NewGoodsId, MailAttribute};
                {fail, 0} ->        %% 处理失败
                    {error, ?OTHER_ERROR};
                {fail, 2} ->        %% 物品不存在
                    {error, ?GOODS_NOT_EXIST};
                {fail, 3} ->        %% 物品不属于该玩家所有
                    {error, ?GOODS_NOT_IN_PACKAGE};
                {fail, 4} ->        %% 物品不在背包
                    {error, ?GOODS_NOT_IN_PACKAGE};
                {fail, 5} ->        %% 物品数量不正确
                    {error, ?GOODS_NUM_NOT_ENOUGH};
                {fail, 6} ->        %% 物品不可交易
                    {error, ?ATTACH_CANNOT_SEND};
                _Other ->           %% 其他（如{fail, 8}-正在交易中）
                    {error, ?OTHER_ERROR}
            end;
        false ->
            {error, ?OTHER_ERROR}
    end.

%% 处理物品附件（提取附件时）
%% @spec handle_goods_recv(PlayerStatus, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, MailId) -> ok | {error, ErrorCode}
handle_goods_recv(PlayerStatus, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, MailId, Mail) ->
    Go = PlayerStatus#player_status.goods,
    if
        IdType == 0 ->  %% GoodsId为物品Id，此情况下，删除邮件物品附件信息由物品进程处理了
            case gen_server:call(Go#status_goods.goods_pid, {'moveout_mail', GoodsId, MailId}) of
                ok ->
					log_mail_get_goods(Mail),
                    ok;
                {fail, 2} ->        %% 物品不存在
                    {error, ?GOODS_NOT_EXIST_2};
                {fail, 4} ->        %% 物品不在附件
                    {error, ?ATTACH_NOT_EXIST};
                {fail, 5} ->        %% 背包格子不足
                    {error, ?NOT_ENOUGH_SPACE};
                _Other ->           %% 处理失败，包括{fail, 0}、{fail, 3}及其它错误
                    {error, ?OTHER_ERROR}
            end;
        true ->         %% GoodsId为物品类型Id
            GoodsList = [{goods, GoodsId, GoodsNum, Prefix, Stren, Bind}],
            case gen_server:call(Go#status_goods.goods_pid, {'give_more', PlayerStatus, GoodsList}) of
                ok ->
					log_mail_get_goods(Mail),
                    delete_attachment_on_db(MailId),    %% 删除邮件物品附件信息
                    ok;
                {fail, 2} ->        %% 类型不存在
                    {error, ?GOODS_NOT_EXIST_2};
                {fail, 3} ->        %% 背包空间不足
                    {error, ?NOT_ENOUGH_SPACE};
                Error ->                %% 未知错误
                    ?ERR("~nmodule:~p, line:~p~nError : ~p~n", [?MODULE, ?LINE, Error]),
                    {error, ?OTHER_ERROR}
            end
    end.

%% 处理发信时的金钱支出
%% @spec handle_money_send(PlayerStatus, NewBCoin, NewCoin) -> {ok, NewStatus}
handle_money_send(PlayerStatus, NewBCoin, NewCoin) ->
    handle_money_send_on_db(PlayerStatus#player_status.id, NewBCoin, NewCoin),
    NewStatus = PlayerStatus#player_status{bcoin = NewBCoin, coin = NewCoin},
    {ok, NewStatus}.

handle_money_send_on_db(PlayerId, NewBCoin, NewCoin) ->
    Sql = lists:concat(["update player_high set bcoin = ", NewBCoin, ", coin = ", NewCoin, " where id = ", PlayerId, " limit 1"]),
    db:execute(Sql).

%% 处理金钱附件（提取附件时）
%% @spec handle_money_recv(PlayerStatus, NewBCoin, NewCoin, NewSilver, NewGold) -> {ok, NewStatus}
handle_money_recv(PlayerStatus, NewBCoin, NewCoin, NewSilver, NewGold) ->
    Sql = lists:concat(["update player_high set bcoin = ", NewBCoin, ", coin = ", NewCoin, ", bgold = ", NewSilver, ", gold = ", NewGold, " where id = ", PlayerStatus#player_status.id, " limit 1"]),
    db:execute(Sql),
	case NewCoin > 0 of
		true ->
			%% 成就：西游巨富，拥有N万铜钱
			lib_player_unite:trigger_achieve(PlayerStatus#player_status.id, trigger_role, [PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 2, 0, NewCoin]);
		_ ->
			skip
	end,
    NewStatus = PlayerStatus#player_status{bcoin = NewBCoin, coin = NewCoin, bgold = NewSilver, gold = NewGold},
    {ok, NewStatus}.

%% 处理私人玩家带物品附件的邮件发送（由物品进程调用，统一事务处理）
%% @return {ok, MailAttribute}
handle_mail_send(MailInfo, PlayerInfo, NewGoodsId) ->
    [Type, SId, UId, Title, Content, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold] = MailInfo,
    [PlayerId, NewBCoin, NewCoin] = PlayerInfo,
    handle_money_send_on_db(PlayerId, NewBCoin, NewCoin),   %% 更新数据库中人物金钱信息
    insert_mail(Type, SId, UId, Title, Content, NewGoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold).

%% 插入新信件，返回信件属性列表
insert_mail(Type, SId, UId, Title, Content, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold) ->
    F = fun () ->
            LongTimestamp = get_unixtime(),
            Sql1 = lists:concat(["insert into mail_attr (type, state, timestamp, sid, uid, title, goods_id, id_type, bind, stren, prefix, goods_num, bcoin, coin, silver, gold) values (", Type, ",2,", LongTimestamp, ",", SId, ",", UId, ",'", Title, " ',", GoodsId, ",", IdType, ",", Bind, ",", Stren, ",", Prefix, ",", GoodsNum, ",", BCoin, ",", Coin, ",", Silver, ",", Gold, ")"]),
            db:execute(Sql1),
            Sql2 = "SELECT LAST_INSERT_ID()",
            NewId = db:get_one(Sql2),
            Sql3 = lists:concat(["insert into mail_content (id, player_id, content) values (", NewId, ", ", UId, ", '", Content, "')"]),
            db:execute(Sql3),
            {ok, [NewId, Type, 2, 2, LongTimestamp, SId, UId, list_to_binary(Title), GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold]}
    end,
    db:transaction(F).

%% 插入信件 写入数据库_收到的信件_还是以事务的方式才能正常
insert_mail_no_transaction(Type, SId, UId, Title, Content, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold) ->
     F = fun () ->
            LongTimestamp = get_unixtime(),
            Sql1 = lists:concat(["insert into mail_attr (type, state, timestamp, sid, uid, title, goods_id, id_type, bind, stren, prefix, goods_num, bcoin, coin, silver, gold) values (", Type, ",2,", LongTimestamp, ",", SId, ",", UId, ",'", Title, " ',", GoodsId, ",", IdType, ",", Bind, ",", Stren, ",", Prefix, ",", GoodsNum, ",", BCoin, ",", Coin, ",", Silver, ",", Gold, ")"]),
            db:execute(Sql1),
            Sql2 = "SELECT LAST_INSERT_ID()",
            NewId = db:get_one(Sql2),
            Sql3 = lists:concat(["insert into mail_content (id, player_id, content) values (", NewId, ", ", UId, ", '", Content, "')"]),
            db:execute(Sql3),
            {ok, [NewId, Type, 2, 2, LongTimestamp, SId, UId, list_to_binary(Title), GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold]}
    end,
    db:transaction(F).
    %%{ok, [NewId, Type, 2, 2, LongTimestamp, SId, UId, list_to_binary(Title), GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold]}.

%% 记录邮件附件信息
log_mail_attachment(MailId, SId, UId, Time, Coin, GoodsId, GoodsTypeId, GoodsNum) ->
    Sql = lists:concat(["insert into log_mail_info (id, pid1, pid2, coin, time, about) values (", MailId, ",", SId, ",", UId, ",", Coin, ",", Time, ",'", GoodsId, ":", GoodsTypeId, ":", GoodsNum, "')"]),
    db:execute(Sql).

%% 记录邮件收取物品附件信息
log_mail_get_goods(Mail) ->
	MailId = Mail#mail.id,
	SId = Mail#mail.sid,
	UId = Mail#mail.uid,
	GoodsId = Mail#mail.goods_id,
%% 	GoodsTypeId = Mail#mail.goods_type_id,
	GoodsNum = Mail#mail.goods_num,
	Type = Mail#mail.type,
	Title = util:object_to_list(Mail#mail.title),
    NowTime = util:unixtime(),
    Sql = lists:concat(["insert into log_mail_get_goods (id, type, timestamp, sid, uid, title, goods_id, goods_num) values (", MailId, ",", Type, ",", NowTime, ",", SId, ",", UId, ",'", Title, "',", GoodsId, ",", GoodsNum, ")"]),
    db:execute(Sql).

%% 生成插入多条记录的MySql语句（插入多条记录非标准SQL语句）
%% @spec make_insert_sql(Tab, FieldList, ValueLists) -> string()
%%  ValueLists : [ValueListA, ValueListB, ...], 形式：[[IdA, NameA], [IdB, NameB], ...]
make_insert_sql(Tab, FieldList, ValueLists) ->
    F0 = fun
        (AccList, [], _G) ->
            AccList;
        (AccList, [ValueList | Rest], G) ->
            TempStr = get_string([], ValueList),
            G([TempStr | AccList], Rest, G)
    end,
    F1 = fun
        ([], Str, _G) ->
            Str;
        ([Item | Rest], Str, G) ->
            case Str == "" of
                true ->
                    NewStr = lists:concat(["(", Item, ")"]);
                false ->
                    NewStr = lists:concat([Str, ", (", Item, ")"])
            end,
            G(Rest, NewStr, G)
    end,
    FieldListStr = get_string([], FieldList),
    ValueStrs = F0([], ValueLists, F0),
    ValueListStr = F1(ValueStrs, "", F1),
    lists:concat(["insert into ", Tab, " (", FieldListStr, ") values ", ValueListStr]).

%% 将邮件信息变成邮件记录______
%% @spec make_into_mail(MailInfo) -> Mail
%%      MailInfo      : {MailAttribute, RoleInfo} | MailAttribute
%%      MailAttribute : list()
%%      Mail          : record()
make_into_mail({MailAttribute, []}) ->
    make_into_mail(MailAttribute);
make_into_mail(MailInfo) ->
    case MailInfo of
        {MailAttribute, RoleInfo} ->
            [MailId, Type, State, Locked, LongTimestamp, SId, UId, Title, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold] = MailAttribute,
            if
                Type =:= 1 ->   %% 系统
                    NewSId = 0,
                    SName = <<"系统">>,
                    SLv = 0;
                Type =:= 3 ->   %% 帮派
                    NewSId = 0,
                    SName = <<"帮派">>,
                    SLv = 0;
                true ->         %% 私人
                    NewSId = SId,
                    [Name, SLv] = RoleInfo,
                    case is_binary(Name) of
                        true ->
                            SName = Name;
                        false when is_list(Name) ->
                            SName = list_to_binary(Name);
                        false ->
                            SName = null
                    end
            end;
        MailAttribute ->
            [MailId, Type, State, Locked, LongTimestamp, SId, UId, Title, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold] = MailAttribute,
            if
                Type =:= 1 ->   %% 系统
                    NewSId = 0,
                    SName = <<"系统">>;
                Type =:= 3 ->   %% 帮派
                    NewSId = 0,
                    SName = <<"帮派">>;
                true ->         %% 私人
                    NewSId = SId,
                    SName = null
            end,
            SLv = 0
    end,
    case IdType == 0 of     %% GoodsId表示物品Id
        true ->
            case GoodsId == 0 of
                true ->
                    GoodsTypeId = 0;
                false ->
                    GoodsTypeId = get_goods_type_id(GoodsId)
            end;
        false ->            %% GoodsId表示物品类型Id
            GoodsTypeId = GoodsId
    end,
    Timestamp = LongTimestamp div 1000000,
    #mail{
        id          = MailId,
        type        = Type,
        state       = State,
        locked      = Locked,
        timestamp   = Timestamp,
        sid         = NewSId,
        sname       = SName,		%% 发件人名字 (binary())，第一次读信时加载     
        slv         = SLv,		    %% 发件人等级，第一次读信时加载           
        uid         = UId,
        title       = Title,
		content 	= <<>>,     	%% 信件内容 (binary())，第一次读信时加载
		urls        = [],           %% 网址信息( [{UrlId, UrlName, Url}, ...] )，第一次读信时生成
        goods_id    = GoodsId,
        id_type     = IdType,
        bind        = Bind,			%% 是否绑定（当id_type为1时有效）
        stren       = Stren,		%% 强化等级（当id_type为1时有效）
        prefix      = Prefix,		%% 前缀（当id_type为1时有效）
        goods_type_id = GoodsTypeId,
        goods_num   = GoodsNum,
        bcoin       = BCoin,
        coin        = Coin,
        silver      = Silver,
        gold        = Gold
    }.


%% 新信件通知
new_mail_notify(PlayerId) ->
    case mod_chat_agent:lookup(PlayerId) of
        [] ->
            false;
        [Player] ->
            Maillist = get_sub_maillist(PlayerId),
            Result = check_unread(Maillist),
            {ok, Bin} = pt_190:write(19005, Result),
            lib_unite_send:send_to_sid(Player#ets_unite.sid, Bin),
            true
    end.

%% 转换为list
object_to_list(Object) when is_binary(Object) ->
    binary_to_list(Object);
object_to_list(Object) when is_list(Object) ->
    Object;
object_to_list(_) ->
    [].

%% 将Url信息列表打包成二进制数据，发送给客户端（供协议19002打包使用）
%% @spec pack_urls(Urls) -> BinUrlInfo
pack_urls(Urls) ->
    Len = length(Urls),
    case Len of
        0 ->
            <<0:16>>;
        _ ->
            F = fun({UrlId, UrlName, Url}) ->
                    BinName = list_to_binary(UrlName),
                    BinUrl = list_to_binary(Url),
                    Len1 = byte_size(BinName),
                    Len2 = byte_size(BinUrl),
                    <<UrlId:8, Len1:16, BinName/binary, Len2:16, BinUrl/binary>>
            end,
            BinList = list_to_binary( [F(UrlInfo) || UrlInfo <- Urls] ),
            <<Len:16, BinList/binary>>
    end.


%% 发送信件给一个收件人
%% @spec send_mail_to_one/13 -> ok | {ok, NewPlayerStatus} | {error, ErrorCode}
send_mail_to_one(Type, SenderId, RInfo, Title, Content, GoodsId, IdType, GoodsNum, Coin, UniteStatus) ->      
    {ReceiverId, _RName} = RInfo,
	case Type of
	    1 -> %% 系统信件
	        {error, ?OTHER_ERROR};
	    2 -> %% 私人信件
	        case Coin > 0 of
                true -> Postage = ?POSTAGE2;    %% 有钱币附件
                false -> Postage = ?POSTAGE
            end,
			PlayerServerPid = lib_player:get_player_info(SenderId, pid),
			InfoPack = {send_priv_mail, [SenderId, ReceiverId, Title, Content, GoodsId, IdType, GoodsNum, Postage, Coin]},
			case gen_server:call(PlayerServerPid, InfoPack) of
				{ok, GoodsId, GoodsTypeId, MailAttribute} -> %% 扣费以及写入邮件SQL成功
					MailId = hd(MailAttribute),
                    MailTime = lists:nth(5, MailAttribute) div 1000000,
                    MailInfo = [MailId, SenderId, ReceiverId, MailTime],
                    Attachment = [Coin, GoodsId, GoodsTypeId, GoodsNum],   %% [CostCoin, GoodsId, GoodsTypeId, GoodsNum]
					%% 写入日志
                    mod_mail:log_mail_info(MailInfo, ?POSTAGE, Attachment),
                    update_mail_info(ReceiverId, [MailAttribute], [UniteStatus#unite_status.name, UniteStatus#unite_status.lv]),
					{ok, ok};
				_ ->
					{error, ?OTHER_ERROR}
			end;
	    _ ->
	        {error, ?OTHER_ERROR}
	end.


%% 发送帮派邮件
%% 不允许发送金钱,附件等等的,所有直接扣费,扣费成就就直接发
send_guild_mail(UniteStatus, OldTitle, OldContent) ->
	SelfPlayerId = UniteStatus#unite_status.id,
    case UniteStatus#unite_status.guild_position =:= 1 of
        true ->     %% 是帮主
			Text = data_mail_log_text:get_mail_log_text(log_mail_info),
			About = io_lib:format(Text, [?POSTAGE, 0]),
			case lib_player_unite:spend_assets_status_unite(SelfPlayerId, ?POSTAGE, coin, mail_send, About) of
				{ok, ok} ->%% 扣费成功 
					DailyTimes = mod_daily_dict:get_count(SelfPlayerId, ?DAILY_TYPE_MAIL),
                    case DailyTimes < ?MAX_NUM of
                        true ->
                            Title = util:object_to_list(OldTitle),
                            Content = util:object_to_list(OldContent),
                            case check_mail_title_and_content(Title, Content) of
                                true ->
                                    Members = get_guild_member_id_list(UniteStatus#unite_status.guild_id),
                                    F = fun
                                        (0) ->
                                            skip;
                                        (PlayerId) ->
                                            case insert_mail(3, 0, PlayerId, Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) of
                                                {ok, MailAttribute} ->
                                                    update_mail_info(PlayerId, [MailAttribute], <<"帮派">>);
                                                _Error ->
                                                    error
                                            end
                                    end,
                                    case length(Members) > 10 of
                                        true ->     %% 超出10封，每插入10封信件延时一次
                                            spawn(
                                                fun() ->
                                                        lists:foldl(
                                                            fun(PlayerId, Counter) ->
                                                                    case Counter < 10 of
                                                                        true ->     %% 连续插入数小于10封
                                                                            F(PlayerId),
                                                                            Counter + 1;
                                                                        false ->    %% 延时后再插入
                                                                            timer:sleep(100),
                                                                            F(PlayerId),
                                                                            1
                                                                    end
                                                            end, 0, Members)
                                                end);
                                        false ->
                                            lists:foreach(fun(PlayerId) -> F(PlayerId) end, Members)
                                    end,
                                    MailInfo = [0, SelfPlayerId, 0, util:unixtime()],
                                    Attachment = [0, 0, 0, 0],
                                    mod_mail:log_mail_info(MailInfo, ?POSTAGE, Attachment),
                                    mod_daily_dict:increment(SelfPlayerId, ?DAILY_TYPE_MAIL),
                                    {ok, ok};
                                Error ->
                                    Error
                            end;
                        false ->    %% 已达到今天最大发送量
                            {error, ?MAX_TIMES}
                    end;
				{error, _IRes} -> %% 扣除铜币不足(扣除铜币失败)
					{error, 7}
			end;
        false ->    %% 非帮主
            {error, 16}
    end.

%% 发送私人信件
%% @spec send_priv_mail/7 -> {ok, NewPlayerStatus} | {VList, IList, NewPlayerStatus} | {error, ErrorCode}
%% @var     VList : 发送成功名单， IList : 发送失败名单
send_priv_mail(UniteStatus, NameList, OldTitle, OldContent, GoodsId, GoodsNum, Coin) ->
    Title = util:make_sure_list(OldTitle),       %% 确保标题和内容为字符串
    Content = util:make_sure_list(OldContent),
    IdType = 0,     %% 玩家发送的物品附件GoodsId为物品Id
    PlayerId = UniteStatus#unite_status.id,
	NameListLength = erlang:length(NameList),
    case NameListLength > 1 of
        false ->
            case check_mail(priv, NameList, Title, Content, GoodsId, Coin, UniteStatus#unite_status.name) of
                {error, Reason} ->
                    {error, Reason};
                {ok, RInfo} ->
					send_mail_to_one(2, PlayerId, RInfo, Title, Content, GoodsId, IdType, GoodsNum, Coin, UniteStatus)
            end;
        true ->     %% 已达到今天最大发送量
            {error, ?MAX_TIMES}
    end.

%% 发送无附件的系统信件
%% @spec send_sys_mail(PlayerInfoList, Title, Content) -> ok
%%      PlayerInfoList : 名字(string() | binary())列表、角色Id列表 或 混合列表
send_sys_mail(PlayerInfoList, Title, Content) ->
    send_sys_mail_2(PlayerInfoList, Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0).

%% 交易发放金钱（未更新ETS表），默认使用物品Id发送物品
%% @spec send_sys_mail/7 -> {ok, MailInfo}
send_sys_mail(PlayerId, Title, Content, GoodsId, GoodsNum, Coin, Gold) ->
    send_sys_mail(PlayerId, Title, Content, GoodsId, 0, 0, 0, 0, GoodsNum, 0, Coin, 0, Gold).

%% 发送系统邮件（未更新ETS表），默认使用物品类型Id发送物品
%% @spec send_sys_mail/9 -> {ok, MailInfo}
send_sys_mail(PlayerId, Title, Content, GoodsTypeId, GoodsNum, BCoin, Coin, Silver, Gold) when is_integer(PlayerId) ->
    send_sys_mail(PlayerId, Title, Content, GoodsTypeId, 1, 0, 0, 0, GoodsNum, BCoin, Coin, Silver, Gold).

%% 发送系统信件，交易发放金钱（未更新ETS表）***
%% @spec send_sys_mail/13 -> {ok, MailInfo}
send_sys_mail(PlayerId, OldTitle, OldContent, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold) when is_integer(PlayerId) ->
    Title = util:object_to_list(OldTitle),
    Content = util:object_to_list(OldContent),
    insert_mail_no_transaction(1, 0, PlayerId, Title, Content, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold).

%% 发送系统信件 ***
%% 如果需要带链接，有如下两种格式：
%%      1. [url http://web.4399.com/yxyz]英雄远征[/url] —— 客户端显示链接名为[url...]与[/url]之间文本
%%      2. [url http://web.4399.com/yxyz][/url] —— 客户端显示链接名为网址
%% @spec send_sys_mail/10 -> {ok, InvalidList} | {error, Reason}
%%          IdType      : 0 -> GoodsId表示物品Id  /  1 -> GoodsId表示物品类型Id
%%          InvalidList : 未发送的名单
%%          Reason      : 错误码（数字），对应含义见宏定义
%% send_sys_mail(NameList, OldTitle, OldContent, GoodsId, IdType, GoodsNum, BCoin, Coin, Silver, Gold) ->
%%     Title = util:object_to_list(OldTitle),       %% 确保标题和内容为字符串
%%     Content = util:object_to_list(OldContent),
%%     case check_mail(sys, NameList, Title, Content, GoodsId, Coin, "") of
%%         {error, Reason} ->
%%             {error, Reason};
%%         {ok, RInfo} ->
%%             case send_mail_to_one(1, 0, RInfo, Title, Content, GoodsId, IdType, GoodsNum, BCoin, Coin, Silver, Gold, []) of
%%                 ok ->               %% 发送成功
%%                     {ok, []};
%% 				{ok , _} ->               %% 发送成功
%%                     {ok, []};
%%                 {error, Reason} ->
%%                     {erorr, Reason}
%%             end;
%%         {ValidInfoList, InvalidInfoList} ->
%%             case send_mail_to_some(1, 0, ValidInfoList, Title, Content, GoodsId, IdType, GoodsNum, BCoin, Coin, Silver, Gold, []) of
%%                 {error, Reason} ->
%%                     {error, Reason};
%%                 {_ValidList, OldInvalidList} ->
%%                     NewInvalidList = InvalidInfoList ++ OldInvalidList,
%%                     {ok, NewInvalidList}
%%             end
%%     end.

%% 发送系统邮件 从游戏线调用 12个参数
%% ([Id列表], 标题, 内容, 物品类型ID, 绑定类型(1是使用后绑定2是绑定), 强化等级, 前缀, 物品数量, 绑定铜币, 非绑定铜币, 绑定元宝, 非绑定元宝)
send_sys_mail_server(PlayerInfoList, Title, Content, GoodsTypeId, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold) ->
    mod_disperse:cast_to_unite(lib_mail
							  , send_sys_mail_2
							  , [PlayerInfoList, Title, Content, GoodsTypeId, 1, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold]).

send_sys_mail_online(Title, Content, GoodsTypeId, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold) ->
	mod_disperse:cast_to_unite(lib_mail
							  , send_sys_mail_online
							  , [[1, Title, Content, GoodsTypeId, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold]]).

send_sys_mail_online([1, Title, Content, GoodsTypeId, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold]) ->
%% 	Ids = ets:match(?ETS_UNITE, #ets_unite{id='$1', _='_'}),
	Ids = mod_chat_agent:match(all_ids, []),
	NewIds = [OneId||OneId <- Ids],
	send_sys_mail_2(NewIds, Title, Content, GoodsTypeId, 1, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold).

%% 发送系统邮件，调用 send_sys_mail_2/13 发信
%% ([Id列表], 标题, 内容, 物品类型ID, 绑定类型(1是使用后绑定2是绑定), 强化等级, 前缀, 物品数量, 绑定铜币, 非绑定铜币, 绑定元宝, 非绑定元宝)
send_sys_mail_bg(PlayerInfoList, Title, Content, GoodsTypeId, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold) ->
    send_sys_mail_2(PlayerInfoList, Title, Content, GoodsTypeId, 1, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold).
%%1v1专用
send_sys_mail_bg_4_1v1(PlayerInfoList, Title, Content, GoodsTypeId, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold)->
	mod_disperse:cast_to_unite(lib_mail,send_sys_mail_bg,[PlayerInfoList, Title, Content, GoodsTypeId, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold]).

%% 发送系统邮件，收信时根据类型Id生成物品 ***
%% @spec send_sys_mail_2/13 -> ok
%%      PlayerInfoList : 名字(string() | binary())列表、 角色Id列表
%%      后台使用:包含角色名字或Id的二进制字符串如：<<"[12,34]">>、<<"[\"80\",\"测试\"]">>、<<"[12, \"测试\"]">>
%%      Title、Content : string() | binary()
send_sys_mail_2(PlayerInfoList, Title, Content, GoodsTypeId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold) ->
    NewTitle = util:object_to_list(Title),
    NewContent = util:object_to_list(Content),
    if
        is_list(PlayerInfoList) ->
            NewInfoList = PlayerInfoList;
        is_binary(PlayerInfoList) ->
            NewInfoList = lib_goods_util:to_term(PlayerInfoList);
        true ->     %% 不能处理，未发送
            NewInfoList = []
    end,
    PlayerIdList = lists:map(fun get_role_id/1, NewInfoList),
    F = fun
        (0) ->
            skip;
        (PlayerId) ->
            case insert_mail(1, 0, PlayerId, NewTitle, NewContent, GoodsTypeId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold) of
                {ok, MailAttribute} ->
                    update_mail_info(PlayerId, [MailAttribute], <<"系统">>);
                _Error ->
                    error
            end
    end,
    case length(PlayerIdList) > 10 of
        true ->
            spawn(
                fun() ->
                        lists:foldl(
                            fun(Id, Counter) ->
                                    catch F(Id),
                                    case Counter < 20 of
                                        true ->
                                            Counter + 1;
                                        false ->
                                            timer:sleep(200),
                                            1
                                    end
                            end, 1, PlayerIdList)
                end);
        false ->
            lists:foreach(fun(Id) -> catch F(Id) end, PlayerIdList)
    end,
    ok.

%% 向所有玩家发送系统邮件，可群发物品附件（后台使用）***
send_sys_mail_to_all(Title, Content, GoodsTypeId, Bind, GoodsNum, BCoin, Coin, Silver, Gold) ->
    send_sys_mail_to_all(Title, Content, GoodsTypeId, Bind, GoodsNum, BCoin, Coin, Silver, Gold, 0, 0).

send_sys_mail_to_all(Title, Content, GoodsTypeId, Bind, GoodsNum, BCoin, Coin, Silver, Gold, LevelLimit) ->
	mod_disperse:cast_to_unite(lib_mail
							  , send_sys_mail_to_all
							  ,[Title, Content, GoodsTypeId, Bind, GoodsNum, BCoin, Coin, Silver, Gold, LevelLimit, 0]).

send_sys_mail_to_all(Title, Content, GoodsTypeId, Bind, GoodsNum, BCoin, Coin, Silver, Gold, LevelLimit, IsOnline) ->
    if
        IsOnline =:= 1 ->   %% 在线
            Sql = lists:concat(["select id from player_low where lv>=", LevelLimit]);
        IsOnline =:= 2 ->   %% 不在线
            Sql = lists:concat(["select id from player_low where lv>=", LevelLimit]);
        true ->             %% 0 包括在线与不在线
            Sql = lists:concat(["select id from player_low where lv>=", LevelLimit ])
    end,
    case db:get_all(Sql) of
        [] ->
            ok;
        InfoList ->
            PlayerInfoList = lists:flatten(InfoList),
            send_sys_mail_2(PlayerInfoList, Title, Content, GoodsTypeId, 1, Bind, 0, 0, GoodsNum, BCoin, Coin, Silver, Gold)
    end.

%% 根据时间升序排序
sort_by_time_asc(MailA, MailB) ->
    MailA#mail.timestamp < MailB#mail.timestamp.

%% 根据时间降序排序
sort_by_time_desc(MailA, MailB) ->
    MailA#mail.timestamp > MailB#mail.timestamp.

%% 时间戳（秒级）转为易辨别时间字符串
%% 例如： 1291014369 -> "2010-11-29 15:6:9"
unixtime_to_time_string(Timestamp) ->
    {{Year, Month, Day}, {Hour, Minute, Second}} = calendar:now_to_local_time({Timestamp  div 1000000, Timestamp rem 1000000, 0}),
    lists:concat([Year, "-", Month, "-", Day, " ", Hour, ":", Minute, ":", Second]).

%% 更新内存及客户端邮件信息（收件人所在战区）
%% @spec update_mail_info(PlayerId, MailInfoList, SenderInfo) -> ok
%%      PlayerId : 收件人Id， MailInfoList = [MailInfo]， MailInfo : list()， SenderInfo : [Name, Level]
update_mail_info(PlayerId, MailInfoList, SenderInfo) ->      %% 发件人为系统时，SenderInfo未使用
    case mod_chat_agent:lookup(PlayerId) of
        [Player] ->
            case SenderInfo of
                [SName, Lv] ->
                    RoleInfo = [SName, Lv];
                _ ->
                    RoleInfo = []
            end,
            lists:foreach(      %% 插入信件信息到内存
                        fun(MailInfo) ->
                        Mail = make_into_mail({MailInfo, RoleInfo}),
						insert_mail_by_one(PlayerId, Mail)
                        end,
                        MailInfoList),
            CurrTimestamp = util:unixtime(),
			Maillist = get_sub_maillist_from_others(PlayerId),
            {ok, BinData} = pt_190:write(19004, [1, CurrTimestamp, Maillist]),   %% 刷新客户端邮件列表
            lib_unite_send:send_to_sid(Player#ets_unite.sid, BinData),
            Result = check_unread(Maillist),
            {ok, BinData2} = pt_190:write(19005, Result),    %% 新未读邮件通知
            lib_unite_send:send_to_sid(Player#ets_unite.sid, BinData2),
			ok;
        _ ->
            error
    end.

%% 更新客户端邮件列表
refresh_client_maillist(PlayerId) ->
    case lib_player:is_online_unite(PlayerId) of
        true ->
            Maillist = get_sub_maillist(PlayerId),   %% 获取用户信件列表
            CurrTimestamp = util:unixtime(),
            {ok, BinData} = pt_190:write(19004, [1, CurrTimestamp, Maillist]),
            lib_unite_send:send_to_uid(PlayerId, BinData),
            true;
        false ->
            false
    end.

%% 更新客户端邮件列表（所有战区）
refresh_maillist(PlayerId) ->
    refresh_client_maillist(PlayerId).

%% 新信件通知（所有战区）
newmail_notify(PlayerId) ->
    new_mail_notify(PlayerId).

%% 初始化角色邮件数据
role_login(PlayerId) ->
    MailList = get_maillist_from_database(PlayerId),
	FormatMailList = [make_into_mail(MailInfo)||MailInfo<-MailList],
	save_mail_dict_first(PlayerId, FormatMailList),
	%% 判断邮件数量,较多就清理
    case length(FormatMailList) >= ?MAX_LEN_OF_MAILLIST of
        true ->     
            spawn(fun() -> clean_mail_while_login(PlayerId, ?DEL_LEN) end);
         false ->
            skip
    end.
	

%% --------------------------------------------------------
%%			处理Mail进程字典
%% --------------------------------------------------------

%%    存储Mail进程字典
%%@return:		  FormatMailList		|Mail进程字典的内容
save_mail_dict_first(PlayerId, FormatMailList)->
	Save_At_Pid = get_unite_pid(PlayerId),
	NewMailKey = "Mails_"++integer_to_list(PlayerId),
	case Save_At_Pid=:=self() of
		true->
			case put(NewMailKey,FormatMailList) of
				undefined->
					FormatMailList;
				_->
					FormatMailList
			end;
		false->
			case gen_server:call(Save_At_Pid, {'save_mail_all', NewMailKey,FormatMailList}, 7000) of
				[]->
					[];
				Rmaillist->
					Rmaillist
			end
	 end.
				
save_mail_dict(PlayerId, FormatMailList)->
	NewMailKey = "Mails_"++integer_to_list(PlayerId),
	case put(NewMailKey,FormatMailList) of
		undefined->
			FormatMailList;
		_->
			FormatMailList
	end.
					
%%    获取进程字典内容_只get自己的
%%@return:		       					|Mail进程字典的内容
get_mail_dict(PlayerId)->
	NewMailKey = "Mails_"++integer_to_list(PlayerId),
	case get(NewMailKey) of
		undefined -> 
			MailList = get_maillist_from_database(PlayerId),
			FormatMailList = [make_into_mail(MailInfo)||MailInfo<-MailList],
			save_mail_dict(PlayerId, FormatMailList);
		Value->
			Value
	end.
	
get_mail_dict_from_others(PlayerId)->
	Save_At_Pid = get_unite_pid(PlayerId),
	NewMailKey = "Mails_"++integer_to_list(PlayerId),
	%%io:format("get_mail_dict_from_others: ~p  :   ~p~n",[Save_At_Pid,self()]),
	case Save_At_Pid=:=self() of
		true->
			case get(NewMailKey) of
				undefined -> 
					MailList = get_maillist_from_database(PlayerId),
					FormatMailList = [make_into_mail(MailInfo)||MailInfo<-MailList],
					save_mail_dict(PlayerId, FormatMailList);
				Value->
					Value
			end;
		false->
			case gen_server:call(Save_At_Pid, {'get_mail_all', PlayerId}, 7000) of
				[]->
					[];
				Rmaillist->
					Rmaillist
			end
	end.


%%    根据邮件ID获取邮件_只get自己的
%%@return:		  Mail_select 			|选出来的邮件,非空时候是一个tuple
get_mail_by_MailID(PlayerId, MailId)->
	Mail_List_got = get_mail_dict(PlayerId),
	[Mail_select] = case [R_ || R_ <- Mail_List_got, R_#mail.id =:= MailId] of
		[]->
			[[]];
		_Res->
			_Res
	end,
	Mail_select.


%%    更新进程字典___由于单个邮件信息改变
%%@return:		  NewMailDict			|跟新后Mail进程字典的内容
update_mail_by_one(PlayerId, OneMail)->
	Mail_Dict = get_mail_dict(PlayerId),
	F = fun(Mail_S) ->
			   case Mail_S#mail.id=:=OneMail#mail.id of
				   true->
					  OneMail;
				   false->
					  Mail_S
				end
		end,
	NewMailDict = [F(D) || D <- Mail_Dict],
	save_mail_dict(PlayerId, NewMailDict),
	NewMailDict.

%%    更新进程字典___由于单个邮件信息改变
%%@return:		  NewMailDict			|跟新后Mail进程字典的内容
insert_mail_by_one(PlayerId, OneMail)->
	Save_At_Pid = get_unite_pid(PlayerId),
%% 	io:format("~n Save_At_Pid :: ~p~n~n!! MY Pid Is::~p~n",[Save_At_Pid,self()]),
	NewMailKey = "Mails_"++integer_to_list(PlayerId),
	NewMailDict = case Save_At_Pid=:=self() of
		false->
			case gen_server:call(Save_At_Pid, {'save_one_mail', PlayerId, OneMail}) of
				[]->
					[];
				Rmaillist->
					Rmaillist
			end;
		true->
			case get(NewMailKey) of
				undefined -> 
					MailList = get_maillist_from_database(PlayerId),
					FormatMailList = [make_into_mail(MailInfo)||MailInfo<-MailList],
					put(NewMailKey,FormatMailList),
					FormatMailList;
				Value->
					put(NewMailKey,[OneMail|Value]),
					[OneMail|Value]
			end
	end,
	NewMailDict.	

%%    删除单条mail记录
%%@return:		  New_Mail_Dict_saved	|新储存的mail进程字典
delete_mail_by_MailId(PlayerId, MailId)->
	Mail_Dict = get_mail_dict(PlayerId),
	Mail_select = get_mail_by_MailID(PlayerId, MailId),
	New_Mail_Dict = lists:delete(Mail_select, Mail_Dict),
	New_Mail_Dict_saved = save_mail_dict(PlayerId, New_Mail_Dict),
	New_Mail_Dict_saved.

%% 获取用户的公共服进程ID
get_unite_pid(Id) ->
    case mod_chat_agent:lookup(Id) of
        [] ->
            error;
        [Player] ->
			Player#ets_unite.pid
    end.


%% --------------------------------------------------------
%%			Alarm!!!!!!!!!!!!!!!!!!私有函数
%% 			请勿在任何非指定函数中调用一下函数
%% --------------------------------------------------------






%% 随机插入信件到数据库（测试用）
%% Start: 起始编号，N 数量
rand_insert_mail(UId, Start, N) ->
    Content = lists:concat(["测试邮件", Start]),
    Title = lists:concat(["标题", Start]),
    Type = random:uniform(2),
    if
        Type =/= 2 ->
            SId = 0;
        true ->
            SId = random:uniform(100)
    end,
    GoodsId = 0,
    IdType = 0,
    GoodsNum = 0,
    BCoin = 0,
    Coin = 0,
    Silver = 0,
    Gold = 0,
    case insert_mail(Type, SId, UId, Title, Content, GoodsId, IdType, 0, 0, 0, GoodsNum, BCoin, Coin, Silver, Gold) of
        {ok, MailAttribute} ->
            update_mail_info(UId, [MailAttribute], []),
            case N =< 1 of
                true ->
                    newmail_notify(UId),
                    ok;
                false ->
                    timer:sleep(500),
                    rand_insert_mail(UId, Start + 1, N - 1)
            end;
        _Error ->
            skip
    end.


	

%% @    根据特定条件获取邮件list-----实验
%% 				  						|可以根据多条件查询和多条件进行不同的查询
%% @param:		  Conditions			|undefined = 无条件默认值 
%% @param:		  Conditions			|条件形式Conditions = [{A, B},{C, D}] A,C是记录项名,B,D是值
%% @return:		  Mail_Dict				|筛选过后的列表
get_mail_dict(PlayerId, Conditions)->
	Flag = 0,
	get_mail_dict(PlayerId, Conditions, Flag).
get_mail_dict(PlayerId, Conditions, Flag)->
	NewMailKey = "Mails_"++integer_to_list(PlayerId),
	Mail_Dict_All = case get(NewMailKey) of
		undefined -> 
			MailList = get_maillist_from_database(PlayerId),
			FormatMailList = [make_into_mail(MailInfo)||MailInfo<-MailList],
			save_mail_dict(PlayerId, FormatMailList);
		Value->
			Value
	end,
	Mail_Dict = case Conditions of
		undefined->
			Mail_Dict_All;
		[]->
			Mail_Dict_All;
		_->
			Mail_defined = tuple_to_list(?Mail_Record_Def),
			LSBL = get_mail_loop(Mail_defined, Conditions, Mail_Dict_All, [], Flag),
			LSBL
	end,
	Mail_Dict.

%% @    This is For !get_mail_dict/3! Only
get_mail_loop(_, [], _, Mail_Dict_got, _)->
	Mail_Dict_got;
get_mail_loop(_Mail_defined, Conditions, Mail_Dict, Mail_Dict_got, Flag)->
	[H0|T0] = Conditions,
	case Flag of
		0-> %%多条件记录查询_条件不独立_Conditions是AND关系
			Mail_Dict_got_New = get_mail_mut_Conditions(_Mail_defined,H0,Mail_Dict),
			get_mail_loop(_Mail_defined, T0, Mail_Dict_got_New, Mail_Dict_got_New, Flag);
		1->%%多条记录不同条件查询_每个条件独立_
			Mail_this_get = get_mail_mut_Conditions(_Mail_defined,H0,Mail_Dict),
			case Mail_this_get of
				[]->
					Mail_Dict_got_New = Mail_Dict_got,
					get_mail_loop(_Mail_defined, T0, Mail_Dict, Mail_Dict_got_New, Flag);
				_->
				  	Mail_Dict_got_New = [get_mail_mut_Conditions(_Mail_defined,H0,Mail_Dict)|Mail_Dict_got],
					get_mail_loop(_Mail_defined, T0, Mail_Dict, Mail_Dict_got_New, Flag)
			end;
		_->%%未定义的操作_默认操作为操作0多条件记录查询
			Mail_Dict_got_New = get_mail_mut_Conditions(_Mail_defined,H0,Mail_Dict),
			get_mail_loop(_Mail_defined, T0, Mail_Dict_got_New, Mail_Dict_got_New, Flag)
	end.
%% @    This is For !get_mail_dict/3! Only
get_mail_mut_Conditions(_Mail_defined, H0, Mail_Dict)->
	Mail_Dict_Ls_1 = case is_tuple(Mail_Dict) of
		true->
			[tuple_to_list(Mail_Dict)];
		false->
			[tuple_to_list(R_t) || R_t <- Mail_Dict]
	end,
	Mail_Dict_New_1 = [ture_to_rigt_list(_Mail_defined,TR,H0,[HR|TR]) || [HR|TR] <- Mail_Dict_Ls_1],
	Mail_Dict_New = [R_end || R_end <- Mail_Dict_New_1, R_end=/=[]],
	case length(Mail_Dict_New) of
		1->
			[Mail_Dict_New_X]= Mail_Dict_New,
			Mail_Dict_New_X;
		_->
			Mail_Dict_New
	end.
%% @    This is For !get_mail_dict/3! Only
ture_to_rigt_list(C, D, HC, RealList)->
	G = lists:zipwith(fun(X, Y) -> {X, Y} end, C, D),
	case HC of
		{Atom_Name,Value}->
			case [{Atom_Name_Now,Value_Now} || {Atom_Name_Now,Value_Now} <- G, Atom_Name_Now =:= Atom_Name, Value_Now =:= Value] of
				[]->
					[];
				_->
					list_to_tuple(RealList)
			end;
		_->
		  []
	end.

%% 记录收取货币附件
log_get_money(MailId, SId, Timestamp, PlayerStatus, NewStatus) ->
    BCoin = NewStatus#player_status.bcoin - PlayerStatus#player_status.bcoin,
    Coin = NewStatus#player_status.coin - PlayerStatus#player_status.coin,
    Silver = NewStatus#player_status.bgold - PlayerStatus#player_status.bgold,
    Gold = NewStatus#player_status.gold - PlayerStatus#player_status.gold,
    Time = lib_mail:unixtime_to_time_string(Timestamp),
    Text = data_mail_log_text:get_mail_log_text(log_get_money),
    About = io_lib:format(Text, [SId, MailId, Time]),
    if
        BCoin + Coin > 0 ->
            case Coin > 0 of
                true ->
                    MoneyTypeA = coin;
                false ->
                    MoneyTypeA = bcoin
            end,
            log:log_produce(mail_attachment, MoneyTypeA, PlayerStatus, NewStatus, About);
        true ->
            skip
    end,
    if
        Silver + Gold > 0 ->
            case Gold > 0 of
                true ->
                    MoneyTypeB = gold;
                false ->
                    MoneyTypeB = bgold
            end,
            log:log_produce(mail_attachment, MoneyTypeB, PlayerStatus, NewStatus, About);
        true ->
            skip
    end.

%% %% 发送信件给多个收件人
%% %% @spec send_mail_to_some/13 -> {error, ErrorCode} | {VList, IList} | {VList, IList, NewPlayerStatus}
%% %%      VList : 信件已正确发送的收件人列表
%% %%      IList : 未正确发送的收件人列表
%% send_mail_to_some(Type, SId, InfoList, Title, Content, GoodsId, IdType,
%%     GoodsNum, BCoin, Coin, Silver, Gold, PlayerStatus) ->
%%     F = fun({UId, _RName}) ->
%%             case Type of
%%                 1 ->    %% 系统信件
%%                     case GoodsId == 0 orelse IdType /= 0 of
%%                         true ->     %% GoodsId为物品类型Id 或者 无物品附件
%%                             case insert_mail(Type, 0, UId, Title, Content, GoodsId, IdType, 0, 0, 0, GoodsNum, BCoin, Coin, Silver, Gold) of
%%                                 {ok, MailAttribute} ->
%%                                     update_mail_info(UId, [MailAttribute], []),
%%                                     true;
%%                                 _Error ->
%%                                     false
%%                             end;
%%                         _ ->        %% GoodsId为物品Id，不能群发
%%                             false
%%                     end;
%%                 2 ->    %% 私人信件
%%                     case GoodsId == 0 andalso Coin == 0 of
%%                         true ->     %% 无附件
%%                             case insert_mail(Type, SId, UId, Title, Content, 0, IdType, 0, 0, 0, 0, BCoin, Coin, Silver, Gold) of
%%                                 {ok, MailAttribute} ->
%%                                     update_mail_info(UId, [MailAttribute], [PlayerStatus#player_status.nickname, PlayerStatus#player_status.lv]),
%%                                     true;
%%                                 _Error ->
%%                                     false
%%                             end;
%%                         false ->   %% 不可群发附件
%%                             false
%%                     end;
%%                 _ ->
%%                     false
%%             end
%%     end,
%%     case Type of
%%         1 ->
%%             lists:partition(F, InfoList);
%%         2 ->
%%             NewCoin = PlayerStatus#player_status.coin - ?POSTAGE,
%%             case NewCoin >= 0 of
%%                 true ->
%%                     {VList, IList} = lists:partition(F, InfoList),
%%                     case VList of
%%                         [] ->   %% 无成功发送
%%                             {error, ?WRONG_NAME};
%%                         _ ->    %% 扣费
%%                             MailInfo = [0, SId, 0, util:unixtime()],
%%                             Attachment = [0, 0, 0, 0],
%%                             NewStatus = lib_goods_util:cost_money(PlayerStatus, ?POSTAGE, coin),
%%                             log:log_consume(send_mail, coin, PlayerStatus, NewStatus, ""),
%%                             mod_mail:log_mail_info(PlayerStatus, NewStatus, MailInfo, ?POSTAGE, Attachment),
%%                             {VList, IList, NewStatus}
%%                     end;
%%                 false ->
%%                     {error, ?NOT_ENOUGH_COIN}
%%             end;
%%         _ ->
%%             {error, ?OTHER_ERROR}
%%     end.