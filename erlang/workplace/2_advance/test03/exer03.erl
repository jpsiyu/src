-module(exer03).
-compile(export_all).


%% parent start
start() ->
	Pid = spawn(fun() -> do_trace() end),
	erlang:trace_pattern({?MODULE, '_', '_'}, 
							[{'_', [], [{return_trace}]}], 
							[local]),
	erlang:trace(Pid, true, [call, procs]),
	Pid ! start2,
	recv_loop().
	
%% parent receive trace messages
recv_loop() ->
	receive 
		{trace, _, call, X} ->
			io:format("call: ~p~n", [X]),
			recv_loop();
		{trace, _, return_from, Call, Ret} ->
			io:format("return from ~p => ~p~n", [Call, Ret]),
			recv_loop();
		Other ->
			io:format("~p~n", [Other]),
			recv_loop()
	end.

%% child process operation
do_trace() ->
	receive 
		start1 ->
			f(4);
		start2 ->
			loop()
	end.

%% fun1
f(0) -> 0;
f(1) -> 1;
f(N) -> f(N-1) + f(N - 2).

%% fun2
loop() ->
	io:format("Hello~n"),
	timer:sleep(2000),
	loop().

%% test
test1() ->
	start().

test2() ->
	dbg:tracer(),
	dbg:tpl(?MODULE, f, '_',
		[{'_', [], [{return_trace}]}]), 
	dbg:p(all, [c]),
	f(4).
