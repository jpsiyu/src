-module(exer02).
-compile(export_all).

s(N, Msg) ->
	spawn(fun() -> start(N, Msg) end),
	timer:sleep(5000),
	ok.

start(0, _Msg) ->
	io:format("process ring finish~n");
start(N, Msg) ->
	Pid = spawn_link(fun() -> start(N-1, Msg) end),
	io:format("Process ~p started~n", [N]),
	Pid ! {msg, Msg},
	loop(N).

loop(N) ->
	receive 
		{msg, Msg} -> 
			io:format("Process ~p got msg: ~p~n", [N, Msg]);
		stop ->
			io:format("Process ~p terminate~n", [N]);
		_ ->
			loop(N)	
	end.
