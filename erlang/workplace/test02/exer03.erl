-module(exer03).
-compile(export_all).

create(N) ->
	[Num || Num <- lists:seq(1, N)].

r_create(N) ->
	List = create(N),
	lists:reverse(List).
