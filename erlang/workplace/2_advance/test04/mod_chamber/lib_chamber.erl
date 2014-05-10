-module(lib_chamber).
-include("chamber.hrl").
-compile(export_all).

%% apply bridal chamber
apply_chamber(WeddingId, MaleId, FemaleId) ->
	case if_chamber_exist(WeddingId) of
		false ->
			gen_server:cast(whereis(?MOD_CHAMBER), {apply_chamber, WeddingId, MaleId, FemaleId});
		true ->
			skip
	end.

%% retrun chamber by wedding id
return_chamber(WeddingId) ->
	case if_chamber_exist(WeddingId) of
		true ->
			BC = gen_server:call(whereis(?MOD_CHAMBER), {return_chamber, WeddingId}),
			BC;
		false ->
			skip
	end.

%% check if chamber exist
if_chamber_exist(WeddingId) ->
	Boolean = gen_server:call(whereis(?MOD_CHAMBER), {if_chamber_exist, WeddingId}),
	Boolean.

%% delete chamber by wedding id
delete_chamber(WeddingId) ->
	case if_chamber_exist(WeddingId) of
		true ->
			gen_server:cast(whereis(?MOD_CHAMBER), {delete_chamber, WeddingId});
		false ->
			skip
	end.

%% if is_endoor
is_endoor(WeddingId) ->
	case if_chamber_exist(WeddingId) of
		true ->
			IsEndoor = gen_server:call(whereis(?MOD_CHAMBER), {is_endoor, WeddingId}),
			case IsEndoor of
				1 ->
					true;
				_ ->
					false
			end;
		false ->
			skip
	end.

%% if is_drink
is_drink(WeddingId) ->
	case if_chamber_exist(WeddingId) of
		true ->
			IsDrink = gen_server:call(whereis(?MOD_CHAMBER), {is_drink, WeddingId}),
			case IsDrink of
				1 ->
					true;
				_ ->
					false
			end;
		false ->
			skip
	end.

%% if is_love_whisper
is_love_whisper(WeddingId) ->
	case if_chamber_exist(WeddingId) of
		true ->
			IsLoveWhisper = gen_server:call(whereis(?MOD_CHAMBER), {is_love_whisper, WeddingId}),
			case IsLoveWhisper of
				1 ->
					true;
				_ ->
					false
			end;
		false ->
			skip
	end.

%% if is_kiss
is_kiss(WeddingId) ->
	case if_chamber_exist(WeddingId) of
		true ->
			IsKiss = gen_server:call(whereis(?MOD_CHAMBER), {is_kiss, WeddingId}),
			case IsKiss of
				1 ->
					true;
				_ ->
					false
			end;
		false ->
			skip
	end.

%% if is_bed_
is_bed(WeddingId) ->
	case if_chamber_exist(WeddingId) of
		true ->
			IsBed = gen_server:call(whereis(?MOD_CHAMBER), {is_bed, WeddingId}),
			case IsBed of
				1 ->
					true;
				_ ->
					false
			end;
		false ->
			skip
	end.

%% if is_enjoy
is_enjoy(WeddingId) ->
	case if_chamber_exist(WeddingId) of
		true ->
			IsEnjoy = gen_server:call(whereis(?MOD_CHAMBER), {is_enjoy, WeddingId}),
			case IsEnjoy of
				1 ->
					true;
				_ ->
					false
			end;
		false ->
			skip
	end.

%% if is_satisf_report
is_satisf_report(WeddingId) ->
	case if_chamber_exist(WeddingId) of
		true ->
			IsSatisf = gen_server:call(whereis(?MOD_CHAMBER), {is_satisf_report, WeddingId}),
			case IsSatisf of
				1 ->
					true;
				_ ->
					false
			end;
		false ->
			skip
	end.

%% set male's satisfication
set_male_satisf(WeddingId, Satisf) ->
	case if_chamber_exist(WeddingId) of
		true ->
			gen_server:cast(whereis(?MOD_CHAMBER), {male_satisf, WeddingId, Satisf});
		false ->
			skip
	end.

%% set female's satisfication
set_female_satisf(WeddingId, Satisf) ->
	case if_chamber_exist(WeddingId) of
		true ->
			gen_server:cast(whereis(?MOD_CHAMBER), {female_satisf, WeddingId, Satisf});
		false ->
			skip
	end.

%% set activity state
set_activity_state(WeddingId, ActivityId) ->
	case if_chamber_exist(WeddingId) of
		true ->
			gen_server:cast(whereis(?MOD_CHAMBER), {set_activity_state, WeddingId, ActivityId});
		false ->
			skip
	end.

%% update activity state
%% activity_id activity_state
%% 0			not start
%% 1			endoor
%% 2			drink
%% 3			whisper
%% 4			kiss
%% 5			bed	
%% 6			enjoy	
%% 7			satisf_report
%% 8			end
update_activity_state(Old, Rule) ->
	New = case Rule of
		normal ->
			Old + 1;
		vip ->
			8
	end,
	case New > 8 of
		true ->
			New2 = 0;
		false ->
			New2 = New
	end,
	New2.
