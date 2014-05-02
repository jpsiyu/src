%%%--------------------------------------
%% @Module  : pp_special_activity
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-05
%% @Description:      |特殊活动
%% --------------------------------------------------------
-module(pp_special_activity).
-export([handle/3]).

-include("common.hrl").
-include("unite.hrl").
-include("rela.hrl").
-include("server.hrl").
-include("scene.hrl").

%% 老玩家招募 :　查询活动基本信息
handle(31700, Status, _) ->
	Res = lib_special_activity:get_type(Status),
    {ok,BinData} = pt_317:write(31700, [Res]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%% 老玩家招募 :　自己邀请方(显示可以邀请别人的界面)
handle(31701, Status, _) ->
	[Res, GiftId, RoleNum, GiftGotNum, TimeLeft] = lib_special_activity:inviter_get_info(Status),
    {ok,BinData} = pt_317:write(31701, [Res, GiftId, RoleNum, GiftGotNum, TimeLeft]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%% 老玩家招募 :　老玩家方(显示回归任务的界面)
handle(31702, Status, _) ->
	[Res, Name, TaskArray] = lib_special_activity:old_buck_get_info(Status),
	NowTime = util:unixtime(),
	CheckTime02 = util:unixtime({{2013,1,6},{0,0,0}}),
	TimeLeft = case CheckTime02 >= NowTime of
				   true ->
					   CheckTime02 - NowTime;
				   _ ->
					   0
			   end,
    {ok,BinData} = pt_317:write(31702, [Res, Name, TaskArray, TimeLeft]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%% 老玩家招募 :　感激一名邀请人
handle(31703, Status, [Name]) ->
%% 	io:format("NeedTime ~p", [Name]),
	Res = lib_special_activity:input_inviter(Status, Name),
%% 	io:format("NeedTime ~p ~p", [Res, 323]),
    {ok,BinData} = pt_317:write(31703, [Res]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%% 老玩家招募 :　领取礼包(检查背包)
handle(31704, Status, [Type, Num]) ->
	Res = lib_special_activity:get_gift(Status, Type, Num),
%% 	io:format("NeedTime ~p", [Res]),
    {ok,BinData} = pt_317:write(31704, [Res]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
handle(_Cmd, _Status, _Data) ->
    ?ERR("pp_guild no match", []),
    {error, "pp_guild no match"}.
