%%%---------------------------------------------
%%% @Module  : test_rela
%%% @Author  : zhenghehe
%%% @Created : 2011.12.24
%%% @Description: 好友系统测试脚本
%%%---------------------------------------------
-module(test_rela).
-export([start/0]).
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
            get_rela_login_info(Socket),
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
get_rela_login_info(Socket) ->
	gen_tcp:send(Socket, <<5:16,10090:16,1:8>>),
    rec(Socket).

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
                rela_friendlist(Socket),
                ok;
		{error, _Reason} ->
            io:format("unite connect failed!~n")
	end.
unite_login(Socket, Uid, Utstamp, Ticket) ->
	Bin = write_string(Ticket),
	L = byte_size( <<1:16,10092:16,Uid:32,Utstamp:32,Bin/binary>>),
    gen_tcp:send(Socket, <<L:16,10092:16,Uid:32,Utstamp:32,Bin/binary>>).
rela_friendlist(Socket) ->
    gen_tcp:send(Socket, <<4:16,14000:16>>),
    unite_rec(Socket).
unite_rec(Socket) ->
    receive
	    {tcp, Socket, <<_L:16, 10092:16, Code:8>>} ->
            io:format("recv unite login ~p~n",[[10092, Code]]);
        {tcp, Socket, <<_L:16, 14000:16, _Bin/binary>>} ->
            io:format("recv 14000~n");
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

