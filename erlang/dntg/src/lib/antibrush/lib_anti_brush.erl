%%------------------------------------------------------------------------------
%% @Module  : lib_anti_brush
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.9.13
%% @Description: 防刷机制
%%------------------------------------------------------------------------------

-module(lib_anti_brush).
-include("server.hrl").
-include("sql_anti_brush.hrl").

-export([calc_anti_brush_score/1,       %% 计算防刷积分.
		 get_anti_brush_score/1,        %% 得到防刷积分.
		 guild_anti_brush_clear/0,      %% 每天数据清除.
		 set_guild_anti_brush_score/1   %% 设置帮派防刷积分.
		]).

%% 查询帮派厢房等级.
-define(sql_select_guild_house_level, <<"SELECT `house_level` FROM `guild` WHERE id=~p">>).

%% 计算防刷积分.
calc_anti_brush_score(PlayerStatus) ->
	%返回是否绑定.
	NowScore = get_anti_brush_score(PlayerStatus),
	case NowScore > 20 of
		true -> false;
		false -> true
	end.

%% 得到防刷积分.
get_anti_brush_score(PlayerStatus) ->
	PlayerId = PlayerStatus#player_status.id,
	
	%1.计算得到今天的积分.
	Score1 = 0 ,%%get_active_score(PlayerStatus),          %% 1.得到活跃度积分.change by xieyunfei
	Score2 = get_vip_score(PlayerStatus) + Score1,         %% 2.得到VIP积分.
	Score3 = get_recharge_score(PlayerStatus) + Score2,    %% 3.历史充值.
	Score4 = get_online_score(PlayerStatus) + Score3,      %% 4.当天累积在线时间（小时）.
	Score5 = get_combatpower_score(PlayerStatus) + Score4, %% 5.等级战力比.
	Score6 = get_ip_score(PlayerStatus) + Score5,          %% 6.同IP帐号数.
	Score7 = get_realm_score(PlayerStatus) + Score6,       %% 7.是否有阵营声望.
	Score8 = get_guild_score(PlayerStatus) + Score7,       %% 8.是否有帮派（2级）.
	Score9 = get_world_level_score(PlayerStatus) + Score8, %% 9.是否高于世界平均等级-5.

	%2.得到前三天的平均分.
	GuildScore = get_guild_anti_brush_score(PlayerStatus),	
	OldScore = get_3_day_score(PlayerId, Score9, GuildScore),

	%3.得到现在的积分.
	NowScore = 
		case Score9 < 20 andalso OldScore =/= 0 of
			true -> OldScore;
			false -> Score9
		end,

	%4.保存积分.	
	save_anti_brush_score(PlayerId, Score9, GuildScore),
	NowScore.

%% 得到前三天平均分.
get_3_day_score(PlayerId, NowScore, GuildScore) ->
	NowTime = util:unixtime(),
	case get("anti_brush_score") of
		undefined ->
			%% 第一次登录，插入初始记录
			case db:get_row(io_lib:format(?sql_select_anti_brush, [PlayerId])) of				
				[] ->
					PlayerScore = [PlayerId, NowScore, NowTime, 0, 0, 0, 0, 0, 0, GuildScore],
					db:execute(io_lib:format(?sql_replace_anti_brush, PlayerScore)),
					put("anti_brush_score", []),
					0;
				_ScoreList ->
					[_PlayerId, _Score1, _Time1, _Score2, _Time2, _Score3, 
					 _Time3, _Score4, _Time4] = _ScoreList,

					%1.第一天.
					Days1 = util:get_diff_days(NowTime, _Time1),
					ScoreList1 =
						case Days1 > 1 andalso Days1 < 5 of
							true ->
								[{_Score1, _Time1}];
							false ->
								[]
						end,

					%2.第二天.
					Days2 = util:get_diff_days(NowTime, _Time2),
					ScoreList2 =
						case Days2 > 1 andalso Days2 < 5 of
							true ->
								ScoreList1 ++ [{_Score2, _Time2}];
							false ->
								ScoreList1
						end,

					%3.第三天.
					Days3 = util:get_diff_days(NowTime, _Time3),
					ScoreList3 =
						case Days3 > 1 andalso Days3 < 5 of
							true ->
								ScoreList2 ++ [{_Score3, _Time3}];
							false ->
								ScoreList2
						end,

					%4.第四天.
					Days4 = util:get_diff_days(NowTime, _Time4),
					ScoreList4 =
						case Days4 > 1 andalso Days4 < 5 of
							true ->
								ScoreList3 ++ [{_Score4, _Time4}];
							false ->
								ScoreList3
						end,					
					put("anti_brush_score", ScoreList4),
					TotalScore = lists:sum([Score1 || {Score1, _Time5} <- ScoreList4]),
					Len = length(ScoreList4),
                    case Len > 0 of
                        true ->
					        round(TotalScore/Len);
                        false ->
                            0
                    end
			end;
		_ScoreList ->
			TotalScore = lists:sum([Score1 || {Score1, _Time1} <- _ScoreList]),
			Len = length(_ScoreList),
            case Len > 0 of
                true ->
			        round(TotalScore/Len);
                false ->
                    0
            end
	end.

%% 保存积分.
save_anti_brush_score(PlayerId, NowScore, GuildScore) ->
	NowTime = util:unixtime(),
	case get("anti_brush_score") of
		undefined ->
			skip;
		_ScoreList ->
			Len = length(_ScoreList),
			PlayerScore = 
				case Len of
					1 ->
						[{_Score1, _Time1}] = _ScoreList,
						[PlayerId, _Score1, _Time1, NowScore, NowTime, 0,0,0,0, GuildScore];
					2 ->
						[{_Score1, _Time1},{_Score2, _Time2}] = _ScoreList,
						[PlayerId, _Score1, _Time1, _Score2, _Time2, NowScore, NowTime, 0,0, GuildScore];
					3 ->
						[{_Score1, _Time1},{_Score2, _Time2},{_Score3, _Time3}] = _ScoreList,
						[PlayerId, _Score1, _Time1, _Score2, _Time2, _Score3, _Time3, NowScore, NowTime, GuildScore];
					_Other -> 
						[PlayerId, NowScore, NowTime, 0,0,0,0,0,0, GuildScore]
				end,
			db:execute(io_lib:format(?sql_replace_anti_brush, PlayerScore))
	end.

%% 得到活跃度积分.
get_active_score(PS) ->
    ActiveScore = mod_active:get_my_active(PS#player_status.status_active),
	case ActiveScore of
		10 -> 1;
		20 -> 2;
		30 -> 3;
		40 -> 4;
		60 -> 5;
		80 -> 8;
		100 -> 9;
		120 -> 10;
		_ ->
			case ActiveScore > 120 of
				true -> 10;
				false -> 0
			end
	end.

%% 得到VIP积分.
get_vip_score(PlayerStatus) ->
    Vip = PlayerStatus#player_status.vip,
	case Vip#status_vip.vip_type of	        
        0 -> 0;       %% 非会员.	        
        _Other -> 10  %% 会员.
    end.

%% 历史充值.
get_recharge_score(PlayerStatus) ->
	TotalRecharge = lib_recharge:get_total(PlayerStatus#player_status.id),
	case TotalRecharge >= 1 of
		true -> 20;
		false -> 0
	end.

%% 当天累积在线时间（小时）.
get_online_score(PlayerStatus) ->
    OnlineTime = lib_player:get_online_time(PlayerStatus),
	OnlineHour = (OnlineTime div 60) div 60,
	case OnlineHour of
		1 -> 2;
		2 -> 3;
		3 -> 4;
		4 -> 5;
		5 -> 6;
		6 -> 7;
		7 -> 7;
		8 -> 8;
		_ ->
			case OnlineHour > 8 of
				true -> 8;
				false -> 0
			end
	end.

%% 等级战力比.
get_combatpower_score(PlayerStatus) ->
    Cpower = PlayerStatus#player_status.combat_power,
	LvLimit = PlayerStatus#player_status.lv div 10,
	CpowerLimit = get_power_limit(LvLimit),
	case Cpower > CpowerLimit of
		true ->
			3;
		false ->
			0
	end.

%% 获得战斗力限制
get_power_limit(Lv) ->
	TList = [
	    {3, 1000},
	    {4, 2000},
		{5, 4000},
	    {6, 4000},
	    {7, 5000},
		{8, 7000},
	    {9, 8000}
    ],
	case lists:keyfind(Lv, 1, TList) of
		false ->
			0;
		{_, Limit} ->
			Limit
	end.	

%% 同IP帐号数.
get_ip_score(_PlayerStatus) ->
	0.

%% 是否有阵营声望.
get_realm_score(PlayerStatus) ->
    Realm = PlayerStatus#player_status.realm,
	case Realm > 0 of	        
        true -> 2;	        
        false -> 0
    end.

%% 是否有帮派（1级）.
get_guild_score(PlayerStatus) ->
    GuildLevel = PlayerStatus#player_status.guild#status_guild.guild_lv,
	GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
	case GuildId =< 0 of
		true ->
			0;
		false ->
			%1.如果玩家的帮派大于2级.
			case GuildLevel >= 2 of	        
		        true ->
					20;	        
		        false ->
					%2.帮派的厢房等级是否大于等于1.
					case get_guild_house_level(GuildId) >= 1 of
						true ->
							20;							
						false ->
							%3.帮派内当天登录的所有玩家的平均积分.
							get_guild_anti_brush_score(PlayerStatus)
					end
		    end
	end.

%% 查询帮派厢房等级.
get_guild_house_level(GuildId) ->	
	case db:get_one(io_lib:format(?sql_select_guild_house_level, [GuildId])) of				
		null ->
			0;
		HouseLevel -> 
			case HouseLevel =< 0 of
				true ->
					0;
				false ->
					HouseLevel
			end
	end.

%% 是否高于世界平均等级-5.
get_world_level_score(PlayerStatus) ->
	%1.得到世界等级.
    WorldLevel = 
		case mod_disperse:call_to_unite(mod_rank,get_average_level, []) of
            AverageLevel when is_integer(AverageLevel)-> 
                AverageLevel+5;
			_Other ->
                40
        end,
	
	%2.计算积分.	
	PlayerLevel = PlayerStatus#player_status.lv,
	case PlayerLevel >= WorldLevel of	        
        true -> 5;	        
        false -> 0
    end.

%% 每天数据清除.
guild_anti_brush_clear() ->
	catch db:execute_nohalt(io_lib:format(?sql_clear_guild_anti_brush, [])).

%% 得到帮派当天平均积分.
get_guild_anti_brush_score(PlayerStatus) ->
	GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
	case db:get_row(io_lib:format(?sql_select_guild_anti_brush, [GuildId])) of				
		[] ->
			0;
		_GulidScore ->
			[TotalScore, Count] = _GulidScore,
			TotalScore div Count
	end.

%% 设置帮派防刷积分.
set_guild_anti_brush_score(PlayerStatus) ->
	%1.得到玩家的积分.
	GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
	PlayerScore = get_anti_brush_score(PlayerStatus),
	case GuildId >= 1 of
		true ->
			%2.得到帮派的积分.
			GulidScore = 
				case db:get_row(io_lib:format(?sql_select_guild_anti_brush, [GuildId])) of				
					[] ->
						[GuildId, PlayerScore, 1];
					GulidScore2 ->
						[TotalScore, Count] = GulidScore2,
						[GuildId, TotalScore+PlayerScore, Count+1]
				end,
		
			%3.保存数据.
			db:execute(io_lib:format(?sql_replace_guild_anti_brush, GulidScore));
		false ->
			skip
	end.