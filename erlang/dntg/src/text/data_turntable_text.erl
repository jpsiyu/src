%%%-------------------------------------------------------------------
%%% @Module	: data_turntable_text
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	:  9 Jun 2012
%%% @Description: 转盘传闻
%%%-------------------------------------------------------------------
-module(data_turntable_text).
-include("server.hrl").
-compile(export_all).

get_cw_message(PS, Award, Coin) ->
    ID = PS#player_status.id,
    Realm = PS#player_status.realm,
    Name = PS#player_status.nickname,
    Sex = PS#player_status.sex,
    Career = PS#player_status.career,
    Head = PS#player_status.image,
    case Award of
	888888 ->
	    ["findTS", 2, ID, Realm, Name, Sex, Career, Head, Coin];
	777777 ->
	    ["findTS", 3, ID, Realm, Name, Sex, Career, Head, Coin];
	666666 ->
	    ["findTS", 4, ID, Realm, Name, Sex, Career, Head, Coin];
	Award when Award =/= 555555 ->
	    ["findTS", 5, ID, Realm, Name, Sex, Career, Head, Award];
	_ ->
	    nomatch
    end.

get_consume_text(Type) ->
    case Type of
	cost_coin ->
	    "寻找唐僧消耗非绑定铜币";
	add_coin ->
	    "寻找唐僧获得非绑定铜币";
	add_bcoin ->
	    "寻找唐僧获得绑定铜币"
    end.
