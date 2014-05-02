-module(exer04).
-compile(export_all).

number_printer(N) ->
	[io:format("Number: ~p~n", [Num]) || Num <- lists:seq(1, N)].
	
even_number_printer(N) ->
	[io:format("Even number: ~p~n", [Num]) || Num <- lists:seq(1, N), Num rem 2 =:= 0].
