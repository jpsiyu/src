%%%---------------------------------------------
%%% @Module  : test_rela
%%% @Author  : zhenghehe
%%% @Created : 2011.12.27
%%% @Description: 信件系统测试脚本
%%%---------------------------------------------
-module(test_mail).
-compile(export_all).
start() ->
    case gen_tcp:connect("localhost", 9010, [binary, {packet, 0}]) of
        {ok, Socket1} ->
            gen_tcp:send(Socket1, <<"<policy-file-request/>\0">>),
            rec(Socket1),
            gen_tcp:close(Socket1);
        {error, _Reason1} ->
            io:format("connect failed!~n")
	end,
    case gen_tcp:connect("localhost", 9010, [binary, {packet, 0}]) of
		{ok, Socket} ->
			login(Socket),
            %create(Socket),
            enter(Socket),
            get_unite_login_info(Socket),
            keep_alive(Socket),
            ok;
		{error, _Reason} ->
            io:format("connect failed!~n")
	end.

%%登陆
login(Socket) ->
    L = byte_size( <<1:16,10000:16,2:32,1273027133:32,3:16,"htc",32:16,"b33d9ace076ca0ac7a8afa56923a03a4">>),
    gen_tcp:send(Socket, <<L:16,10000:16,2:32,1273027133:32,3:16,"htc",32:16,"b33d9ace076ca0ac7a8afa56923a03a4">>),
    rec(Socket).

%%创建角色
create(Socket) -> 
    L = byte_size( <<1:16,10003:16,1:8,1:8,1:8,6:16,"异界">>),
    gen_tcp:send(Socket, <<L:16,10003:16,1:8,1:8,1:8,6:16,"异界">>),
    rec(Socket).

%%选择角色进入
enter(Socket) ->
    gen_tcp:send(Socket, <<8:16,10004:16, 3:32>>),
    rec(Socket).

%%获取socket登录验证所需信息
get_unite_login_info(Socket) ->
	gen_tcp:send(Socket, <<5:16,10090:16,1:8>>),
    rec(Socket).

%%心跳包
keep_alive(Socket) ->
    L = byte_size(<<1:16, 10006:16>>),
    gen_tcp:send(Socket, <<L:16, 10006:16>>),
    rec(Socket),
    timer:sleep(5000),
    keep_alive(Socket).

%%聊天登录
unite([Ip, Port, Uid, Utstamp, Ticket]) ->
	case gen_tcp:connect(Ip, Port, [binary, {packet, 0}]) of
        {ok, Socket1} ->
            gen_tcp:send(Socket1, <<"<policy-file-request/>\0">>),
            rec(Socket1),
            gen_tcp:close(Socket1);
        {error, _Reason1} ->
            io:format("unite connect failed!~n")
	end,
	case gen_tcp:connect(Ip, Port, [binary, {packet, 0}]) of
		{ok, Socket} ->
                unite_login(Socket, Uid, Utstamp, Ticket),
                unite_rec(Socket),
                RNameList = ["霍娅澜", "荆惠菁", "逍遥剑侠", "荒古", "荒古2", "融河言", "ssssss", "申屠娣琴"],
                send_mail(Socket, RNameList),
                unite_rec(Socket),
                RNameList1 = ["申屠娣琴"],
                send_mail(Socket, RNameList1),
                unite_rec(Socket),
                mail_list(Socket),
                get_attach(Socket),
                ok;
		{error, _Reason} ->
            io:format("unite connect failed!~n")
	end.
unite_login(Socket, Uid, Utstamp, Ticket) ->
	Bin = write_string(Ticket),
	L = byte_size( <<1:16,10092:16,Uid:32,Utstamp:32,Bin/binary>>),
    gen_tcp:send(Socket, <<L:16,10092:16,Uid:32,Utstamp:32,Bin/binary>>).

%%写信
send_mail(Socket, RNameList) ->
    RNameL = length(RNameList),
    RNameBinList = [write_string(X) || X <- RNameList],
    RNameBinListBin = list_to_binary(RNameBinList),
    Title = "测试信件",
    TitleBin = write_string(Title),
    Content = "测试信件内容",
    ContentBin = write_string(Content),
    GoodsId = 0,
    GoodsNum = 0,
    Coin = 0,
    Data = <<RNameL:16, RNameBinListBin/binary, TitleBin/binary, ContentBin/binary, GoodsId:32, GoodsNum:32, Coin:32>>,
    DataSend = pt:pack(19001, Data),
    gen_tcp:send(Socket, DataSend).

%%获取信件列表
mail_list(Socket) ->
    L = byte_size(<<1:16, 19004:16>>),
    gen_tcp:send(Socket, <<L:16, 19004:16>>),
    unite_rec(Socket).

%%授信
get_mail(MailIdlist, Socket) when length(MailIdlist)>0 ->
    [Id|Tail] = MailIdlist,
    L = byte_size(<<1:16, 19002:16, Id:32>>),
    gen_tcp:send(Socket, <<L:16, 19002:16, Id:32>>),
    unite_rec(Socket),
    get_mail(Tail, Socket);
get_mail([], _Socket) ->
    ok.

%%提取附件
get_attach(Socket) ->
    L = byte_size(<<1:16, 19006:16, 67:32>>),
    gen_tcp:send(Socket, <<L:16, 19006:16, 67:32>>),
    unite_rec(Socket),
    unite_rec(Socket).
unite_rec(Socket) ->
    receive
	    {tcp, Socket, <<_L:16, 10092:16, Code:8>>} ->
            io:format("recv unite login ~p~n",[[10092, Code]]);
        {tcp, Socket, <<_L:16, 19004:16, Tag:16, Timestamp:32, MailNum:16, Bin/binary>>} ->
            io:format("recv cmd=~p Tag=~p Timestamp=~p MailNum=~p~n", [19004, Tag, Timestamp, MailNum]),
            case MailNum of
                0 ->
                    skip;
                _R ->
                    {MailIdlist, _Res} = get_list([], Bin, MailNum),
                    case MailIdlist of
                        [] ->
                            skip;
                        _OTHER ->
                            io:format("MailIdlist=~p~n", [MailIdlist]),
                            get_mail(MailIdlist, Socket)
                    end
            end;
        {tcp, Socket, <<_L:16, 19002:16, Tag:16, MailId:32, _Bin/binary>>} ->
            io:format("recv cmd=~p Tag=~p MailId=~p~n", [19002, Tag, MailId]);
        {tcp ,Socket, <<_L:16, 19006:16, Tag:16, MailId:32>>} ->
            io:format("recv cmd=~p Tag=~p MailId=~p~n", [19006, Tag, MailId]);
        {tcp, Socket, <<_L:16, 19001:16, Status:16, Bin/binary>>} ->
            case Status of
                0 ->
                    io:format("发送失败~n");
                1 ->
                    io:format("发送成功~n");
                2 ->
                    io:format("发送失败，标题不合法（非法字符/长度超限）~n");
                3 ->
                    io:format("发送失败，内容不合法（非法字符/长度超限）~n");
                4 ->
                    io:format("发送失败，发送多人时带附件~n");
                5 ->
                    io:format("发送失败，无合法收件人~n");
                6 ->
                    io:format("部分发送失败~n"),
                    <<Num:16, Bin2/binary>> = Bin,
                    {NameList, _} = pt_190:get_list([], Bin2, Num),
                    io:format("NameList:~p~n", [NameList]);
                7 ->
                    io:format("发送失败，金钱不足~n");
                8 ->
                    io:format("发送失败，物品数量不足~n");
                9 ->
                    io:format("发送失败，物品不存在~n");
                10 ->
                    io:format("发送失败，物品不在背包~n");
                11 ->
                    io:format("发送失败，该物品不能发送~n")
            end;
		{tcp_closed, Socket}->
            io:format("socket close~n"),
            gen_tcp:close(Socket)
    after 5000 ->
        ok
    end.

rec(Socket) ->
    receive
        {tcp, Socket, <<"<cross-domain-policy><allow-access-from domain='*' to-ports='*' /></cross-domain-policy>">>} -> 
            io:format("revc : ~p~n", ["flash_file"]);
		{tcp, Socket, <<_L:16, 10091:16, Code:8>>} ->
			io:format("recv chat login ~p~n",[[10091, Code]]);
        {tcp, Socket, <<_L:16,Cmd:16, Bin:16>>} -> 
            io:format("revc : ~p~n", [[Cmd, Bin]]);
        {tcp, Socket, <<_L:16, 59004:16, Code:16>>} ->
            io:format("recv: ~p ~p~n", [59004, Code]);
        {tcp, Socket, <<_L:16, Cmd:16, Code:8>>} ->
            io:format("revc : ~p~n", [[Cmd, Code]]);
        {tcp, Socket, <<_L:16, 10000:16, Uid:32>>} ->
            io:format("recv : ~p ~p~n", [10000, Uid]);
        {tcp, Socket, <<_L:16, 10003:16, Res:8, Uid:32>>} ->
            io:format("recv : ~p ~p ~p~n", [10003, Res, Uid]);
        {tcp, Socket, <<_L:16, 10006:16>>} ->
            %io:format("recv : ~p~n", [10006]);
            skip;
    	{tcp, Socket, <<_L:16, 10090:16, Utstamp:32, Port:16, Bin/binary>>} ->
            {Ip, Bin1} = read_string(Bin),
            {Ticket, Res} = read_string(Bin1),
            <<Mark:8>> = Res,
            io:format("recv : ~p~n", [[10090, Utstamp, Port, Ip, Ticket, Mark]]),
            if 
                Mark =:= 1 ->
                    spawn(fun()->unite([Ip, Port, 3, Utstamp, Ticket])end);
                true ->
                    ok
            end;
        {tcp_closed, Socket} ->
            gen_tcp:close(Socket)
    end.

%%读取字符串
read_string(Bin) ->
    case Bin of
        <<Len:16, Bin1/binary>> ->
            case Bin1 of
                <<Str:Len/binary-unit:8, Rest/binary>> ->
                    {binary_to_list(Str), Rest};
                _R1 ->
                    {[],<<>>}
            end;
        _R1 ->
            {[],<<>>}
    end.
%%打包字符串
write_string(S) when is_list(S)->
    SB = iolist_to_binary(S),
    L = byte_size(SB),
    <<L:16, SB/binary>>;

write_string(S) when is_binary(S)->
    L = byte_size(S),
    <<L:16, S/binary>>.

get_list(AccList, Bin, N) when N>0 ->
    case Bin of
        <<Id:32, Type:16, State:16, Timestamp:32, Bin2/binary>> ->
            {SName, Rest} = read_string(Bin2),
            {Title, Rest1} = read_string(Rest),
            <<Attach:16, Rest2/binary>> = Rest1,
            io:format("Id=~p Type=~p State=~p Timestamp=~p SName=~p Title=~p Attach=~p~n", [Id, Type, State, Timestamp, SName, Title, Attach]),
            NewList = [Id | AccList],
            get_list(NewList, Rest2, N-1);
        _R1 ->
            error
    end;

get_list(AccList, Bin, _) ->
    {AccList, Bin}.
