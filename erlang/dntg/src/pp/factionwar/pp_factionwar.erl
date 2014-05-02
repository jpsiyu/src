%% Author: zengzhaoyuan
%% Created: 2012-5-22
%% Description: TODO: Add description to pp_arena_new
-module(pp_factionwar).
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([handle/3]).
-include("unite.hrl").
-include("server.hrl").
%%
%% API Functions
%%

%% 其他公共线协议
handle(Cmd, UniteStatus,_Params) when is_record(UniteStatus, unite_status) ->
	%%不改变状态，返回值为ok，改变状态，返回{ok, NewPlayerStatus}
	[Result,_RestTime,_SignUpNo,_Loop_time,_Loop]=mod_factionwar:get_status(UniteStatus#unite_status.guild_id),
	Flag = lists:member(Cmd,[40205,40208,40209,40210]),
	if
		%过滤帮战结束或未开始所不允许的协议
		(Result=:=1 orelse Result=:=4) andalso Flag ->
			ok;
		true->
			case Cmd of
				40201->lib_factionwar:execute_40201(UniteStatus);
				40203->lib_factionwar:execute_40203(UniteStatus);
				40205->lib_factionwar:execute_40205(UniteStatus);
				40208->
					SceneId = data_factionwar:get_factionwar_config(scene_id),
					if
						SceneId =:= UniteStatus#unite_status.scene-> %限制场景
							lib_factionwar:execute_40208(UniteStatus#unite_status.id);
						true->
							ok
					end;
				40209->
					[BUid] = _Params,
					lib_factionwar:execute_40209(UniteStatus,BUid);
				40210->
					[Type] = _Params,
					Flag = lists:member(Type, [1,2,3]),
					case Flag of						
						false->ok;
						true->lib_factionwar:execute_40210(UniteStatus,Type)
					end;
				40212->lib_factionwar:execute_40212(UniteStatus);
				40214->
					[PageNow] = _Params,
					lib_factionwar:execute_40214(UniteStatus,PageNow);
				40216->lib_factionwar:execute_40216(UniteStatus);
				40219->
					SceneId = data_factionwar:get_factionwar_config(scene_id),
					if
						SceneId =:= UniteStatus#unite_status.scene-> %限制场景
							lib_factionwar:execute_40219(UniteStatus);
						true->
							ok
					end;
				_ -> ok
			end
	end;

%% 游戏线协议
%% 交付帮派水晶
handle(40217, #player_status{factionwar_stone = FactionStone, scene = Scene, x = X, y = Y} = Status, []) -> 
    {Res, NewStatus} = if
        FactionStone == 0 -> {2, Status}; %% 失败，身上没有石头
        Scene /= 106 orelse 
        (
            (abs(X - 25)  < 5 andalso abs(Y - 55)  < 5)  orelse 
            (abs(X - 6) < 5 andalso abs(Y - 23)  < 5)  orelse
            (abs(X - 44)  < 5 andalso abs(Y - 23) < 5)      
        ) == false  -> {3, Status}; %% 失败，需在npc附近交付水晶
        true -> 
            MStatus = lib_factionwar:del_stone(Status, 1),
            {1, MStatus}
    end,
    {ok, BinData} = pt_402:write(40217, Res), 
    lib_server_send:send_one(Status#player_status.socket, BinData),
    {ok, NewStatus};

%% 取消运送水晶
handle(40220, #player_status{factionwar_stone = FactionStone} = Status, []) -> 
    if
        FactionStone == 0 -> skip;
        true -> 
            MStatus = lib_factionwar:del_stone(Status, 2),
            {ok, MStatus}
    end;

handle(Cmd, _, _) -> 
    catch util:errlog("pp_factionwar handle no match CMD ~p~n", [Cmd]),
    ok.

%%
%% Local Functions
%%

