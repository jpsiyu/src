-module(mod_chamber_cast).
-include("chamber.hrl").
-export([handle_cast/2]).

%% apply for bridal chamber
handle_cast({apply_chamber, WeddingId, MaleId, FemaleId}, State) ->
	%% creat a chamber
	Chamber = #chamber{wedding_id = WeddingId,
					   male_id = MaleId,
					   female_id = FemaleId},
	ets:insert(?ETS_CHAMBER, Chamber),
	{noreply, State};

%% delete bridal chamber
handle_cast({delete_chamber, WeddingId}, State) ->
	ets:delete(?ETS_CHAMBER, WeddingId),
	{noreply, State};

%% hand on male's satisf
handle_cast({male_satisf, WeddingId, MaleSatisf}, State) ->
	ets:update_element(?ETS_CHAMBER, WeddingId, {#chamber.male_satisf, MaleSatisf}),
	{noreply, State};

%% hand on female's satisf
handle_cast({female_satisf, WeddingId, FemaleSatisf}, State) ->
	ets:update_element(?ETS_CHAMBER, WeddingId, {#chamber.female_satisf, FemaleSatisf}),
	{noreply, State};

%% set activity state
handle_cast({set_activity_state, WeddingId, ActivityId}, State) ->
	ets:update_element(?ETS_CHAMBER, WeddingId, {#chamber.activity_state, ActivityId}),
	{noreply, State};
	
handle_cast(_Event, State) ->
	skip,
	{noreply, State}.
