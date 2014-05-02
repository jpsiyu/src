%%%------------------------------------
%%% @Module  : mod_fcm_cast
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.28
%%% @Description: handle_cast
%%%------------------------------------
-module(mod_fcm_cast).
-export([handle_cast/2]).

%% 删除操作
handle_cast({delete_id, Id}, Status) ->
	erase({ets_buff, Id}),
    {noreply, Status};

%% 插入操作
handle_cast({insert, Id, LastLoginTime, OnLineTime, OffLineTime, State, WriteSql, Name, IdCardNo}, Status) ->
	put({fcm, Id}, {LastLoginTime, OnLineTime, OffLineTime, State, WriteSql, Name, IdCardNo}),
    {noreply, Status};

%% 根据用户Id删除
handle_cast({delete, Id}, Status) ->
	erase({fcm, Id}),
    {noreply, Status};

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_fcm_cast:handle_cast not match: ~p", [Event]),
    {noreply, Status}.
