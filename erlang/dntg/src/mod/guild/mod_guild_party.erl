%%%------------------------------------
%%% @Module  : mod_guild_party
%%% @Author  : hekai
%%% @Email   : hekai@jieyou.cn
%%% @Created : 2012.9.24
%%% @Description: 
%%%------------------------------------

-module(mod_guild_party).
-behaviour(gen_server).
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("sql_guild.hrl").
-include("guild.hrl").
-compile(export_all).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
	NodeId = mod_disperse:node_id(),
	case NodeId =:= 10 of
		true ->
			spawn(fun() ->
						timer:sleep(1*60*1000),
						start_party()					
				end
			);
		false -> skip
	end,
    {ok, 0}.

start_party() ->
	%% 初始化已经预约的帮派仙宴
	Sql = ?SQL_GUILD_PARTY_BOOKING,
	Booking_log = db:get_all(Sql),
	F = fun([Guild_id, Guild_name, Sponsor_id, Sponsor_name, Sponsor_image, Sponsor_sex, Sponsor_voc, Party_type, Booking_time], Count) ->
			NowTime = util:unixtime(),
			case (Count rem 20) =:=0  andalso Count =/=0 of
				true ->
					timer:sleep(100);
				false ->
					skip
			end,
			case Booking_time>NowTime of
				true ->
					DailyGuildId = 4000000 + Guild_id,
					DailySS = mod_daily_dict:get_count(DailyGuildId, 4007804),
					%% 检测是否在延迟启动过程中有预约记录
					case DailySS>0 of
						true -> skip;
						false ->
							PartyName = ?GUILD_PARTYL ++ integer_to_list(Guild_id),	
							case misc:whereis_name(global,PartyName) of
								undefined ->								
									%% 启动帮派宴会服务
									Start_After = Booking_time - NowTime,
									Db_flag = 1,
									mod_party_timer:start_link([Start_After, [Guild_id
												, Guild_name
												, Sponsor_id
												, Sponsor_name
												, Sponsor_image
												, Sponsor_sex
												, Sponsor_voc
												, Party_type
												, Db_flag]]),
									Time0 =  util:unixdate(),
									Time48 = (Booking_time - Time0) div 60 div 30,
									mod_daily_dict:set_count(DailyGuildId, 4007804, Time48);
								_ ->
									skip
							end
					end;					
				false ->
					Sql2 = 	io_lib:format(?SQL_GUILD_PARTY_DELETE, [Guild_id]),
					db:execute(Sql2)
			end,
			Count+1
	end,
	lists:foldl(F, 0, Booking_log).

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("guild_party:handle_call not match: ~p~n", [Event]),
    {reply, ok, Status}.

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("guild_party:handle_cast not match: ~p~n", [Event]),
    {noreply, Status}.

%% handle_info信息处理
%% 默认匹配
handle_info(Info, Status) ->
    catch util:errlog("guild_party:handle_info not match: ~p~n", [Info]),
    {noreply, Status}.

terminate(_Reason, _Status) ->
    %catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.
