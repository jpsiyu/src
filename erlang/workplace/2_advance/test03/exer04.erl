-module(exer04).
-compile(export_all).

%% start a process ring simulation
start(Msg_num, Proc_num, Msg) ->
	Ring = proc_ring(Proc_num, []),
	ring_msg(Msg_num, Msg_num, {msg, Msg}, Ring),
	ring_msg(1, 1, {stop, normal}, Ring).

%% each process will run this function
loop() ->
	receive
		{{stop, Reason}, _Msg_num} ->
			io:format("~p:~p, ~p~n", [self(), stop, Reason]);
		{{msg, Msg}, Msg_num} ->
			io:format("~p got ~pth msg: ~p~n", [self(), Msg_num, Msg]),
			loop()
	end.

%% generate a process ring using list
proc_ring(0, Ring) ->
	Ring;
proc_ring(Proc_num, Ring) ->
	Pid = spawn(fun() -> loop() end),
	proc_ring(Proc_num - 1, lists:append(Ring, [Pid])).

%% sent message throught ring
ring_msg(0, _Max, _Msg, _Ring) ->
	ok;
ring_msg(Msg_num, Max, Msg, Ring) ->
	[Proc ! {Msg, Max - Msg_num + 1} || Proc <- Ring],
	ring_msg(Msg_num - 1, Max, Msg, Ring).
