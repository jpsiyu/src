-module(mod_chamber_call).
-include("chamber.hrl").
-export([handle_call/3]).

%% return chamber by wedding id
handle_call({return_chamber, WeddingId}, _From, State) ->
	Reply = ets:lookup(?ETS_CHAMBER, WeddingId),
	{reply, Reply, State};

%% if is_endoor
handle_call({is_endoor, WeddingId}, _From, State) ->
	Reply = ets:lookup_element(?ETS_CHAMBER, WeddingId, #chamber.is_endoor),
	{reply, Reply, State};

%% if is_drink
handle_call({is_drink, WeddingId}, _From, State) ->
	Reply = ets:lookup_element(?ETS_CHAMBER, WeddingId, #chamber.is_drink),
	{reply, Reply, State};

%% if is_love_whisper
handle_call({is_love_whisper, WeddingId}, _From, State) ->
	Reply = ets:lookup_element(?ETS_CHAMBER, WeddingId, #chamber.is_love_whisper),
	{reply, Reply, State};

%% if is_kiss
handle_call({is_kiss, WeddingId}, _From, State) ->
	Reply = ets:lookup_element(?ETS_CHAMBER, WeddingId, #chamber.is_kiss),
	{reply, Reply, State};

%% if is_bed
handle_call({is_bed, WeddingId}, _From, State) ->
	Reply = ets:lookup_element(?ETS_CHAMBER, WeddingId, #chamber.is_bed),
	{reply, Reply, State};

%% if is_satisf
handle_call({is_satisf_report, WeddingId}, _From, State) ->
	Reply = ets:lookup_element(?ETS_CHAMBER, WeddingId, #chamber.is_satisf_report),
	{reply, Reply, State};

%% if is_bed
handle_call({is_enjoy, WeddingId}, _From, State) ->
	Reply = ets:lookup_element(?ETS_CHAMBER, WeddingId, #chamber.is_enjoy),
	{reply, Reply, State};

%% if chamer exist
handle_call({if_chamber_exist, WeddingId}, _From, State) ->
	Match = {chamber, WeddingId, '$1', '_', '_', '_', '_',
			'_', '_', '_', '_', '_', '_', '_', '_', '_'},
	Result = ets:match(?ETS_CHAMBER, Match),
	Reply = case Result of
		[] ->
			false;
		_ ->
			true
	end,
	{reply, Reply, State};

handle_call(_Event, _From, State) ->
	{reply, ok, State}.
