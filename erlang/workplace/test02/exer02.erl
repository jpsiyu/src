-module(exer02).
-compile(export_all).

sum(N) ->
	add(N, 0).

add(0, S) ->
	S;
add(N, S) ->
	add(N -1, S + N).

sum(N, M) ->
	R = add(N, M, 0),
	R.

add(N, N, R) -> 
	R + N;
add(N, M, R) ->
	add(N + 1, M, R + N).
