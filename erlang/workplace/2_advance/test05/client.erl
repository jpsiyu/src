-module(client).
-compile(export_all).

start(IP, Port) ->
	{ok, Socket} = gen_tcp:connect(IP, Port, []),
	gen_tcp:send(Socket, write(10000, 112358, "zxy_112358", 1, 1)),
	receive
		Msg ->
			io:format("~p~n", [Msg])
	end.
	

write(10000, Accid, Accname, Tstamp, Ticket) ->
	AB = write_string(Accname),
	TB = write_string(Ticket),
	pack(10000, <<Accid:32, Tstamp:32, AB/binary, TB/binary>>).

write_string(S) when is_list(S) ->
	SB = iolist_to_binary(S),
	L = byte_size(SB),
	<<L:16, SB/binary>>;
write_string(S) when is_binary(S) ->
	L = byte_size(S),
	<<L:16, S/binary>>;
write_string(S) when is_integer(S) ->
	SS = integer_to_list(S),
	SB = list_to_binary(SS),
	L = byte_size(SB),
	<<L:16, SB/binary>>;
write_string(_S) ->
	<<0:16, <<>>/binary>>.

%% add head
pack(Cmd, Data) ->
	pack(Cmd, Data, 0).
pack(Cmd, Data, Zip) ->
	case Zip == 1 orelse byte_size(Data) > 100 of
		true ->
			Data1 = zlib:compress(Data),
			L = byte_size(Data1) + 7,
			<<L:32, Cmd:16, 1:8, Data1/binary>>;
		false ->
			L = byte_size(Data) + 7,
			<<L:32, Cmd:16, 0:8, Data/binary>>
	end.
