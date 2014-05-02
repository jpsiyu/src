-module(server).
-compile(export_all).

start(Port) ->
	{ok, LisSock} = gen_tcp:listen(Port, [binary, {packet, 0}, {active, false}]),
	spawn(fun() -> acceptor(LisSock) end).

acceptor(LisSock) ->
	{ok, AccSock} = gen_tcp:accept(LisSock),
	io:format("socket connected~n"),
	gen_tcp:send(AccSock, <<"OK">>),
	spawn(fun() -> acceptor(LisSock) end),
	do_recv(AccSock).

do_recv(AccSock) ->
	case gen_tcp:recv(AccSock, 0) of
		{ok, Bin}  ->
			io:format("~p~n", [Bin]),
			do_recv(AccSock);
		{error, _Reason} ->
			io:format("failed~n")
	end.
