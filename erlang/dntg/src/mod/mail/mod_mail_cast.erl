%%%------------------------------------
%%% @Module  : mod_mail_cast
%%% @Author  : zhenghehe
%%% @Created : 2012.02.01
%%% @Description: 信件cast处理
%%%------------------------------------
-module(mod_mail_cast).
-export([handle_cast/2]).
-include("common.hrl").
-include("mail.hrl").
-include("server.hrl").


%% 通知更新邮件列表
handle_cast({'update_mail_info', PlayerId, MailInfoList, RoleInfo}, State) ->
    lib_mail:update_mail_info(PlayerId, MailInfoList, RoleInfo),
    {noreply, State};

%% 发系统信件，不返回处理结果 13参数
handle_cast({'send_sys_mail', [PlayerId, OldTitle, OldContent, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold]}, State) ->
    lib_mail:send_sys_mail(PlayerId, OldTitle, OldContent, GoodsId, IdType, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold),
    {noreply, State};

%% 发系统信件，不返回处理结果 包括物品
handle_cast({'send_sys_mail', [PlayerId, Title, Content, GoodsId, GoodsNum, Coin, Gold]}, State) ->
    lib_mail:send_sys_mail(PlayerId, Title, Content, GoodsId, GoodsNum, Coin, Gold),
    {noreply, State};

%% 发系统信件，不返回处理结果 
handle_cast({'send_sys_mail', [PlayerInfoList, Title, Content]}, State) ->
    lib_mail:send_sys_mail(PlayerInfoList, Title, Content),
    {noreply, State};

%% 清理信件
handle_cast('clean_mail', State) ->
    spawn(
        fun() ->
            timer:sleep(5 * 60 * 1000),
            lib_mail:clean_mail()
        end),
    {noreply, State};

%% 记录消费
handle_cast({'log_mail_info', PlayerStatus, NewStatus, MailInfo, Postage, Attachment}, State) ->
    Type = mail_send,
    [CostCoin, GoodsId, GoodsTypeId, GoodsNum] = Attachment,
    [MailId, SId, UId, Time] = MailInfo,
    case PlayerStatus#player_status.coin == NewStatus#player_status.coin of
        true ->
            MoneyType = bcoin;
        false ->
            MoneyType = coin
    end,
    Text = data_mail_log_text:get_mail_log_text(log_mail_info),
    About = io_lib:format(Text, [Postage, CostCoin]),
    log:log_consume(Type, MoneyType, PlayerStatus, NewStatus, About),
    case CostCoin == 0 andalso GoodsId == 0 of
        true ->
            ok;
        false ->
            lib_mail:log_mail_attachment(MailId, SId, UId, Time, CostCoin, GoodsId, GoodsTypeId, GoodsNum)
    end,
    {noreply, State};

%% 记录消费
handle_cast({'log_mail_info', MailInfo, _Postage, Attachment}, State) ->
    _Type = mail_send,
    [CostCoin, GoodsId, GoodsTypeId, GoodsNum] = Attachment,
    [MailId, SId, UId, Time] = MailInfo,
    case CostCoin == 0 andalso GoodsId == 0 of
        true ->
            ok;
        false ->
            lib_mail:log_mail_attachment(MailId, SId, UId, Time, CostCoin, GoodsId, GoodsTypeId, GoodsNum)
    end,
    {noreply, State};

%% 记录收取货币附件
handle_cast({'log_get_money', MailId, SId, Timestamp, PlayerStatus, NewStatus}, State) ->
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
    end,
    {noreply, State};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_mail:handle_cast not match: ~p", [Event]),
    {noreply, Status}.