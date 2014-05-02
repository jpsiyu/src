-module(exer01).
-compile(export_all).

start() ->
	Pid = spawn(fun() -> loop() end),
	register(?MODULE, Pid).

loop() ->
	receive
		{print, Msg} ->
			io:format("~p~n", [Msg]),
			loop();
		{stop, Reason} ->
			io:format("stop receive, ~p~n", [Reason])
	end.

print(Msg) ->
	?MODULE ! {print, Msg}.

stop(Reason) ->
	?MODULE ! {stop, Reason}.
