-module(if_sign).
-compile(export_all).

week_sign_init() ->
	[{1, 0, 624201, 1},
	 {2, 1, 624201, 1},
	 {3, 0, 624201, 1},
	 {4, 1, 624201, 1},
	 {5, 0, 624201, 1},
	 {6, 0, 624201, 1},
	 {7, 0, 624201, 1}
	].

if_sign(WeekDay, List)  ->
	case lists:keyfind(WeekDay, 1, List) of
		{_, IfSigned, _, _} ->
			case IfSigned of
				1 ->
					true;
				_ ->
					false
			end;
		false ->
			false
	end.
