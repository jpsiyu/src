%%%-------------------------------------------------------------------
%%% @Module	: pp_firstgift
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 18 Jul 2012
%%% @Description: 首服礼包+西行礼包
%%%-------------------------------------------------------------------
-module(pp_firstgift).
-export([handle/3]).
-include("gift.hrl").
-include("server.hrl").

%% 获取手机和邮箱信息
%% handle(31600, PS, [Phone, Email]) ->
%%     case lib_firstgift:check_get(PS#player_status.id) of
%% 	false ->				%未领礼包
%% 	    if 
%% 		Phone =:= [] andalso Email =/= [] -> %只填邮箱
%% 		    case lib_firstgift:validate_email(Email) of
%% 			true ->
%% 			    lib_firstgift:put_to_db([PS#player_status.id, PS#player_status.accname, Phone, Email, 1]), %成功填写邮箱
%% 			    {ok, BinData} = pt_316:write(31600, [0]), 
%% 			    lib_server_send:send_one(PS#player_status.socket, BinData);
%% 			false ->
%% 			    {ok, BinData} = pt_316:write(31600, [2]), %邮箱验证失败
%% 			    lib_server_send:send_one(PS#player_status.socket, BinData)
%% 		    end;
%% 		Phone =/= [] andalso Email =:= [] -> %只填手机
%% 		    case lib_firstgift:validate_phone(Phone) of
%% 			true ->
%% 			    lib_firstgift:put_to_db([PS#player_status.id, PS#player_status.accname, Phone, Email, 1]), %成功填写手机
%% 			    {ok, BinData} = pt_316:write(31600, [0]), 
%% 			    lib_server_send:send_one(PS#player_status.socket, BinData);
%% 			false ->
%% 			    {ok, BinData} = pt_316:write(31600, [1]), %手机验证失败
%% 			    lib_server_send:send_one(PS#player_status.socket, BinData)
%% 		    end;
%% 		Phone =/= [] andalso Email =/= [] -> %都填了
%% 		    case lib_firstgift:validate_phone(Phone) of
%% 			true ->
%% 			    case lib_firstgift:validate_email(Email) of
%% 				true ->
%% 				    lib_firstgift:put_to_db([PS#player_status.id, PS#player_status.accname, Phone, Email, 1]), %成功
%% 				    {ok, BinData} = pt_316:write(31600, [0]),
%% 				    lib_server_send:send_one(PS#player_status.socket, BinData);
%% 				false ->
%% 				    {ok, BinData} = pt_316:write(31600, [2]),
%% 				    lib_server_send:send_one(PS#player_status.socket, BinData)
%% 			    end;
%% 			false ->
%% 			    {ok, BinData} = pt_316:write(31600, [1]), 
%% 			    lib_server_send:send_one(PS#player_status.socket, BinData)
%% 		    end;
%% 		true ->
%% 		    {ok, BinData} = pt_316:write(31600, [1]), 
%% 		    lib_server_send:send_one(PS#player_status.socket, BinData)
%% 	    end;
%% 	true ->					%已领过手机礼包
%% 	    []
%%     end;
handle(31600, PS, [Activity, Update, Charge, Time1, Time2, Time3, Phone]) ->
    case lib_firstgift:check_get(PS#player_status.id) of
	false ->				%未领礼包
	    case Phone =/= [] of
		true ->
		    case lib_firstgift:validate_phone(Phone) of
			true ->
			    lib_firstgift:put_to_db([PS#player_status.id, PS#player_status.accname, Activity, Update, Charge, Time1, Time2, Time3, Phone, 1, util:unixtime()]),
			    {ok, BinData} = pt_316:write(31600, [0]), %成功
			    lib_server_send:send_one(PS#player_status.socket, BinData);
			false ->
			    {ok, BinData} = pt_316:write(31600, [1]), %手机错误
			    lib_server_send:send_one(PS#player_status.socket, BinData)
		    end;
		false ->
		    {ok, BinData} = pt_316:write(31600, [1]), %手机错误，为空
		    lib_server_send:send_one(PS#player_status.socket, BinData)
	    end;
	true ->
	    {ok, BinData} = pt_316:write(31600, [2]), %已经填过
	    lib_server_send:send_one(PS#player_status.socket, BinData)
    end;
		    
handle(Cmd, _PlayerStatus, _R) ->
    util:errlog("pp_gift handle ~p error~n", [Cmd]).

