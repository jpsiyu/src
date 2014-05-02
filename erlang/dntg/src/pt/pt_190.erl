%%------------------------------------
%%% @Module     : pt_190
%%% @Author     : zhenghehe
%%% @Created    : 2010.05.24
%%% @Description: 信件协议处理
%%%------------------------------------
-module(pt_190).
%% -export([]).
-compile(export_all).
-include("record.hrl").
-include("mail.hrl").
%%
%%客户端 -> 服务端 ----------------------------
%%

%% 发送信件 
read(19001, Bin) ->
	{Name, Bin2} = pt:read_string(Bin),
	{Title, Bin3} = pt:read_string(Bin2),
	{Content, Bin4} = pt:read_string(Bin3),
	<<GoodsId:32, GoodsNum:32, Coin:32>> = Bin4,
	{ok, [[Name], Title, Content, GoodsId, GoodsNum, Coin]};

%% 获取信件
read(19002, Bin) ->
    case Bin of
        <<Id:32>> ->
            {ok, Id};
        _ ->
            {error, no_match}
    end;

%% 删除信件
read(19003, Bin) ->                 %% 选中删除
    <<N:16, Bin2/binary>> = Bin,
    case get_list2([], Bin2, N) of
        error ->
            {error, no_match};
        {IdList, _RestBin} ->
            {ok, IdList}
    end;

%% 获取信件列表
read(19004, _) ->
    {ok, get_maillist};

%% 查询有无未读邮件
read(19005, _) ->
    {ok, check_unread};

%% 提取附件
read(19006, <<MailId:32>>) ->
    {ok, MailId};

%% 邮件锁定与解锁
read(19007, Data) ->
    <<MailId:32, _/binary>> = Data,
    {ok, MailId};

%% 发送帮派邮件
read(19008, Bin) ->
    {Title, Bin2} = pt:read_string(Bin),
    {Content, _} = pt:read_string(Bin2),
    {ok, [Title, Content]};

%% 玩家反馈
read(19010, <<Type:16, Bin/binary>>) ->
    case pt:read_string(Bin) of
        {[], <<>>} ->
            {error, no_match};
        {Title, Bin2} ->
            case pt:read_string(Bin2) of
                {[], <<>>} ->
                    {error, no_match};
                {Content, _} ->
                    {ok, [Type, Title, Content]}
            end
    end;

%% 玩家反馈
read(19011, <<ZhanLi:32, Bin/binary>>) ->
	{Time, Bin1} = pt:read_string(Bin),
	{Title, Bin2} = pt:read_string(Bin1),
	{Content, Bin3} = pt:read_string(Bin2),
	<<ConType:8, Bin4/binary>> = Bin3,
	{Context, _} = pt:read_string(Bin4),
    {ok, [ZhanLi, Time, Title, Content, ConType, Context]};

%% 玩家反馈查询
read(19012, <<Page:32>>) ->
    {ok, [Page]};

%% 玩家反馈积分查询
read(19013, _) ->
    {ok, 19013};

%% 玩家反馈积分兑换
read(19014, <<GiftId:8>>) ->
    {ok, [GiftId]};

%% 玩家反馈详情查询
read(19015, <<FKId:32>>) ->
    {ok, [FKId]};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%% 回应客户端发信
write(19001, Data) ->
    case Data of
        [SendStatus, NameList] ->
            case is_integer(SendStatus) of
                true ->
                    if
                        SendStatus == 6 ->
                            F = fun({_, Name}) ->
                                    Name1 = list_to_binary(Name),
                                    Len = byte_size(Name1),
                                    <<Len:16, Name1/binary>>
                            end,
                            Num = length(NameList),
                            BinList = list_to_binary( [F(Name) || Name <- NameList] ),
                            {ok, pt:pack(19001, <<6:16, Num:16, BinList/binary>>)};
                        true ->
                            {ok, pt:pack(19001, <<SendStatus:16, 0:16>>)}
                    end;
                false ->
                    {error, no_match}
            end;
        _ ->
            {error, no_match}
    end;

%% 获取信件
write(19002, [Result | RestData]) ->
    case Result of
        2 ->
            MailId = RestData,
            {ok, pt:pack(19002, <<
                    2:16,           % 结果，成功-1 / 无该信件-2 / 读取信件失败-3
                    MailId:32,      % int:32 信件id
                    2:8,            % int:8  锁定状态
                    0:32,           % int:32 时间戳（不成功为0）
                    0:16,           % string 发件人（不成功为空）
                    0:16,           % string 信件标题（不成功为空）
                    0:16,           % string 信件内容（不成功为空）
                    0:32,           % int:32 物品类型ID（无则为0）
                    0:32,           % int:32 物品数量
                    0:32,           % int:32 绑定铜币
                    0:32,           % int:32 铜钱数
                    0:32,           % int:32 银两数
                    0:32,           % int:32 元宝数
                    1:8,            % int:8  邮件类型
                    0:16,           % int:16 网址列表长度
                    0:8,            % int:8  玩家等级(读信失败或系统为0)
                    0:32            % int:32 发件人Id
                    >>)};
        3 ->
            MailId = RestData,
            {ok, pt:pack(19002, <<
                    3:16,           % 结果，成功-1 / 无该信件-2 / 读取信件失败-3
                    MailId:32,      % int:32 信件id
                    2:8,            % int:8  锁定状态
                    0:32,           % int:32 时间戳（不成功为0）
                    0:16,           % string 发件人（不成功为空）
                    0:16,           % string 信件标题（不成功为空）
                    0:16,           % string 信件内容（不成功为空）
                    0:32,           % int:32 物品类型ID（无则为0）
                    0:32,           % int:32 物品数量
                    0:32,           % int:32 绑定铜币
                    0:32,           % int:32 铜钱数
                    0:32,           % int:32 银两数
                    0:32,           % int:32 元宝数
                    1:8,            % int:8  邮件类型
                    0:16,           % int:16 网址列表长度
                    0:8,            % int:8  玩家等级(读信失败或系统为0)
                    0:32            % int:32 发件人Id
                    >>)};
        1 ->
            case is_record(RestData, mail) of
                true ->
                    MailId = RestData#mail.id,
                    Type = RestData#mail.type,
                    Locked = RestData#mail.locked,
                    Timestamp = RestData#mail.timestamp,
                    SName = RestData#mail.sname,
                    Title = RestData#mail.title,
                    Content = RestData#mail.content,
                    GoodsTypeId = RestData#mail.goods_type_id,
                    GoodsNum = RestData#mail.goods_num,
                    BCoin = RestData#mail.bcoin,
                    Coin = RestData#mail.coin,
                    Silver = RestData#mail.silver,
                    Gold = RestData#mail.gold,
                    Urls = RestData#mail.urls,
                    RoleLv = RestData#mail.slv,
                    SId = RestData#mail.sid,
                    BinUrls = lib_mail:pack_urls(Urls),
                    LenName = byte_size(SName),
                    LenTitle = byte_size(Title),
                    LenContent = byte_size(Content),
                    {ok, pt:pack(19002, <<1:16, MailId:32, Locked:8, Timestamp:32, LenName:16, SName/binary, LenTitle:16, Title/binary, LenContent:16, Content/binary, GoodsTypeId:32, GoodsNum:32, BCoin:32, Coin:32, Silver:32, Gold:32, Type:8, BinUrls/binary, RoleLv:8, SId:32>>)};
                false ->
                    {error, no_match}
            end;
        _ ->
            {error, no_match}
    end;

%% 删除信件
write(19003, Result) ->
    {ok, pt:pack(19003, <<Result:16>>)};

%% 信件列表
write(19004, [Result, CurrTimestamp, Maillist]) ->
    case Result of
        0 ->
            {ok, pt:pack(19004, <<0:16, CurrTimestamp:32, 0:16>>)};
        1 ->
            F = fun(Mail) ->
                    Id        = Mail#mail.id,
                    Type      = Mail#mail.type,
                    State     = Mail#mail.state,
                    Locked    = Mail#mail.locked,
                    Timestamp = Mail#mail.timestamp,
                    SName     = <<>>,       %% 客户端未使用
                    Title     = Mail#mail.title,
                    GoodsId   = Mail#mail.goods_id,
                    BCoin     = Mail#mail.bcoin,
                    Coin      = Mail#mail.coin,
                    Silver    = Mail#mail.silver,
                    Gold      = Mail#mail.gold,
                    case GoodsId /= 0 orelse BCoin /= 0 orelse Coin /= 0 orelse Silver /= 0 orelse Gold /= 0 of    %% 有附件
                        true ->
                            Attach = 1;
                        false ->
                            Attach = 0
                    end,
                    LenName  = byte_size(SName),
                    LenTitle = byte_size(Title),
                    <<Id:32, Type:16, State:16, Timestamp:32, LenName:16, SName/binary, LenTitle:16, Title/binary, Attach:16, Locked:8>>
            end,
            MailNum = length(Maillist),
            BinList = list_to_binary([F(Mail) || Mail <- Maillist]),
            {ok, pt:pack(19004, <<1:16, CurrTimestamp:32, MailNum:16, BinList/binary>>)};
        _ ->
            {error, no_match}
    end;

%% 新信件通知
%% AnyUnread 0-无未读邮件, 1-有未读邮件, 2-查询失败
%% AnyWillOutDate 0-无将过期的带附件邮件, 1-有...
%% UnreadNum 未读邮件数
write(19005, [AnyUnread, AnyWillOutDate, UnreadNum]) ->
    {ok, pt:pack(19005, <<AnyUnread:16, AnyWillOutDate:8, UnreadNum:16>>)};

%% 提取附件
write(19006, [Result, MailId, GoodsId, IsGetMoneySuc]) ->
    {ok, pt:pack(19006, <<Result:16, MailId:32, GoodsId:32, IsGetMoneySuc:16>>)};

%% 邮件锁定与解锁
write(19007, {Result, MailId}) ->
    {ok, pt:pack(19007, <<Result:16, MailId:32>>)};

%% 发送帮派邮件
write(19008, Result) ->
    {ok, pt:pack(19008, <<Result:16>>)};

%% 玩家反馈
write(19010, [Result]) ->
    {ok, pt:pack(19010, <<Result:16>>)};

%% 玩家反馈2
write(19011, [Result]) ->
    {ok, pt:pack(19011, <<Result:16>>)};

%% 玩家反馈查询
write(19012, [Result, List]) ->
	BinList = pack_19012(List),
    {ok, pt:pack(19012, <<Result:8, BinList/binary>>)};

%% 玩家反馈积分查询
write(19013, [Result, Score]) ->
    {ok, pt:pack(19013, <<Result:8, Score:32>>)};

%% 玩家反馈积分兑换
write(19014, [Result]) ->
    {ok, pt:pack(19014, <<Result:8>>)};

%% 玩家反馈查询详情
write(19015, [Result, Id, Cont]) ->
	BinCont = pt:write_string(Cont),
    {ok, pt:pack(19015, <<Result:8, Id:32, BinCont/binary>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

%% 获取列表（读取角色名称列表）
%% 列表每项为String，对应<<Length:16, String/binary>>
%% AccList列表累加器，使用时初始为[]
get_list(AccList, Bin, N) when N > 0 ->
    case Bin of
        <<Len:16, Bin2/binary>> ->
            <<Item:Len/binary-unit:8, Rest/binary>> = Bin2,
            Item2 = binary_to_list(Item),
            NewList = [Item2 | AccList],
            get_list(NewList, Rest, N - 1);
        _R1 ->
            error
    end;
get_list(AccList, Bin, _) ->
    {AccList, Bin}.

%% 获取列表（读取信件id列表）
%% 列表每项为int32
get_list2(AccList, Bin, N) when N > 0 ->
    case Bin of
        <<Item:32, Bin2/binary>> ->
            NewList = [Item | AccList],
            get_list2(NewList, Bin2, N - 1);
        _ ->
            error
    end;
get_list2(AccList, Bin, _N) ->
    {AccList, Bin}.

%% -----------------------------------------------------------------
%% 打包19012
%% -----------------------------------------------------------------
pack_19012([]) ->
    <<0:16, <<>>/binary>>;
pack_19012(List) ->
    Rlen = length(List),
    F = fun([Id, Time, Title, _Content, Opt, Score]) ->
		BinTitle = pt:write_string(Title),
        <<Id:32, Time:32, BinTitle/binary, Opt:16, Score:32>>
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.