-module(exer05).
-compile(export_all).


%% start proc ring simulator
start(Msg_num, Proc_num, Msg) ->
	Lproc = proc_ring(Proc_num, self()),
	ring_msg(Msg_num, Lproc, Msg).

%% each process will do this method
loop(Front_proc) ->
	receive 
		{msg, Msg, Msg_num} ->
			io:format("~p got ~pth msg: ~p~n", [self(), Msg_num, Msg]),
			Front_proc ! {msg, Msg, Msg_num},
			loop(Front_proc);
		{stop, Reason, _Msg_num} ->
			io:format("proc ~p stop ~p~n", [self(), Reason]),
			Front_proc ! {msg, Reason, _Msg_num}
	end.

%% generate proc ring
proc_ring(0, Pid) ->
	Pid;	
proc_ring(Proc_num, _Pid) ->
	Cpid = spawn(fun() -> loop(self()) end),
	proc_ring(Proc_num - 1, Cpid).

%% sent msg throuht ring
ring_msg(0, _Cpid, _Msg) ->
	ok;
ring_msg(Msg_num, Cpid, Msg) ->
	Cpid ! {msg, Msg, Msg_num},
	ring_msg(Msg_num -1, Cpid, Msg).
