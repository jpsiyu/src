%%%-------------------------------------------------------------------
%%% @Module	: lib_turntable
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 22 Jun 2012
%%% @Description: 
%%%-------------------------------------------------------------------
-module(lib_turntable).
-include("server.hrl").
-export([trans/1]).

trans(PS) ->
    [
     PS#player_status.id, 
     PS#player_status.sid, 
     PS#player_status.nickname, 
     PS#player_status.coin,
     PS#player_status.bcoin,
     PS#player_status.sex,
     PS#player_status.career,
     PS#player_status.image,
     PS#player_status.realm,
     PS#player_status.goods
    ].
