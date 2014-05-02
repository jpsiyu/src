-module(exer08).
-compile(export_all).

classify(C) ->
	case is_integer(C) of
		true ->
			{num, C};
		false ->
			case C of
				"+" ->
					{op, plus};
				"-" ->
					{op, minus};
				"*" ->
					{op, multiply};
				"/" ->
					{op, divide};
				"~" ->
					negitive;
				"(" ->
					lbracket;
				")" ->
					rbracket;
				_ ->
					unexpected
			end
	end.			


handle([], Stack) ->
	Stack;
handle([H | T], Stack) ->
	case classify(H) of
		unexpected ->
			error;
		lbracket ->
			handle(T, Stack);
		{num, C} ->
			handle(T, [{num, C} | Stack]);
		{op, Op} ->
			handle(T, [ Op | Stack]);
		rbracket ->
			[N2, Op, N1] = Stack,
			Group = {Op, N1, N2},
			handle(T, [Group]);
		_ ->
			undo
	end.

transfer(D1, D2, Op) ->
	case is_integer(D1)	of
		true ->
			Fir = ["("] ++ [D1] ++ [Op];
		false ->
			Fir = ["("] ++ D1 ++ [Op]
	end,
	case is_integer(D2) of
		true ->
			Sec = Fir ++ [D2] ++ [")"];
		false ->
			Sec = Fir ++ D2 ++ [")"]
	end,
	Sec.
