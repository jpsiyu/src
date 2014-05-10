-define(ETS_CHAMBER, chamber).

-define(MOD_CHAMBER, mod_chamber).

%% chamber
-record(chamber, {
		wedding_id = 0,			%% wedding id
		male_id = 0,			%% male id
		female_id = 0,			%% female id
		is_endoor = 0,			%% if male into door
		is_drink = 0, 			%% if they drink
		is_love_whisper = 0,	%% if they whisper
		is_kiss = 0,			%% if they kiss
		is_bed = 0, 			%% if they go to bed
		is_enjoy = 0,			%% if they enjoy
		is_satisf_report = 0,	%% if they hand on report
		male_satisf = 0,		%% how satisfy male feels
		female_satisf = 0,   	%% how satisfy female feels
		activity_state = 0,		%% which activity we are in
		begin_time = 0,			%% chamber begin time
		end_time = 0 			%% chamber end time
}).
