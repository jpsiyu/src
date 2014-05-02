%%%--------------------------------------
%%% @Module  : mod_rank_cast
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2012.6.29
%%% @Description :  排行榜
%%%--------------------------------------

-module(mod_rank_call).
-include("rank.hrl").
-export([handle_call/3]).

%% 获取排行榜前50级玩家等级平均值
handle_call({'get_average_level'}, _From, State) ->
	AveLevel = lib_rank:get_average_level(),
	{reply, AveLevel, State};

%% 获取排行榜前50级玩家等级平均值
%% 早上3点刷新等级值
handle_call({'get_world_level'}, _From, State) ->
	NowTime = util:unixtime(),
	ThreeTime = util:unixdate(NowTime) + 3 * 3600,

	{Level, Time} = State#rank_state.world_level,
	Result = 
	case Level =:= 0 of
		true ->
			RankLevel = lib_rank:get_average_level(),
			AveLevel = case RankLevel =:= 0 of
				true -> 30;
				_ -> RankLevel
			end,
			{AveLevel, NowTime};
		_ ->
			case NowTime > ThreeTime andalso Time < ThreeTime of
				true ->
					RankLevel = lib_rank:get_average_level(),
					AveLevel = case RankLevel =:= 0 of
						true -> 30;
						_ -> RankLevel
					end,
					{AveLevel, NowTime};
				_ ->
					{Level, Time}
			end
	end,

	{reply, Result, State#rank_state{world_level = Result}};

%% 默认匹配
handle_call(Event, _From, State) ->
    catch util:errlog("mod_rank:handle_call not match: ~p", [Event]),
    {reply, ok, State}.
