-module(str_left_shift).
-compile(export_all).

%% left shift: "abcde" -> "cdeab"
%% violence
left_shift(Str, 0) ->
	Str;
left_shift(Str, N) when is_list(Str), is_integer(N) -> 
	[H | T] = Str,
	left_shift(lists:append(T, [H]), N-1);
left_shift(_Str, _N)  ->
	io:format("usage: left_shift(List, Num) ~n").
