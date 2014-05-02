-module(exer06).
-compile(export_all).

smaller(List, N) ->
	Nlist = s_match(List, N, []),
	reverse(Nlist).

s_match([], _N, Nlist) ->
	Nlist;
s_match([H | T], N, Nlist) ->
	case H =< N of	
		true ->
			s_match(T, N, [H | Nlist]);
		false ->
			s_match(T, N, Nlist)
	end.

reverse(List) ->
	r_match(List, []).

r_match([], Nlist) ->
	Nlist;
r_match([H | T], Nlist) ->
	r_match(T, [H | Nlist]).

denest(List) ->
	case has_nest(List) of
		true ->
			Nlist = d_match(List, []),
			denest(Nlist);
		false ->
			List
	end.
	
d_match([], Nlist) ->
	Nlist;
d_match([H | T], Nlist) ->
	case is_list(H) of
		true ->
			d_match(T, Nlist ++ H);
		false ->
			d_match(T, Nlist ++ [H])
	end.

has_nest([]) ->
	false;
has_nest([H | T]) ->
	case is_list(H)	of
		true ->
			true;
		false ->
			has_nest(T)
	end.
