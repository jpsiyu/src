-module(str_left_shift).
-compile(export_all).

%% left shift: "abcde" -> "cdeab"
left_shift(Str, 0) ->
	Str;
left_shift([H | T], N) ->
	left_shift(lists:append(T, [H]), N-1).
