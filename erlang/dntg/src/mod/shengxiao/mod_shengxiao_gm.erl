%%%------------------------------------
%%% @Module  : mod_shengxiao_gm
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.6
%%% @Description: 生肖大奖秘籍
%%%------------------------------------

-module(mod_shengxiao_gm).
-export([start/1, bet/1]).
-include("shengxiao.hrl").

%% 活动开始
%% Long:活动持续时间(秒)
start(Long) ->
	mod_shengxiao_tick_new_gm:start_link(Long),
	ok.

%% 用户抽奖
bet(Id) ->
	[NickName, _Sex, _Lv, _Career, _Realm, _GuildId, _Mount_limit, _HusongNpc, _Image|_] = lib_player:get_player_low_data(Id),
	lib_shengxiao_new:bet_gm(Id, binary_to_list(NickName), 1, 1, Id rem 12 + 1, 2, (Id + 1) rem 12 + 1, 3, (Id + 2) rem 12 + 1, 4, (Id + 3) rem 12 + 1),
	ok.
