%%%----------------------------------------------------
%%% @Module: lib_shengxiao
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.5.30
%%% @Description:  生肖大奖功能
%%%----------------------------------------------------

-module(lib_shengxiao).
-export([member/1, other_betting/0, lottery_countdown/0, lottery_info/1, winner/0, user_state/1, bet/9, award/1]).
-include("shengxiao.hrl").

%% 获取个人已投注信息(63001)
member(PlayerId) ->
	lib_shengxiao_new:member(PlayerId).

%% 刷新其他用户投注信息(63002)
other_betting() ->
	lib_shengxiao_new:other_betting().

%% 开奖倒计时通知(63003)
lottery_countdown() ->
	lib_shengxiao_new:lottery_countdown().

%% 倒计时完，获取开奖信息(63005)
lottery_info(PlayerId) ->
	lib_shengxiao_new:lottery_info(PlayerId).

%% 获取中奖名单(63006)
winner() ->
	lib_shengxiao_new:winner().

%% 返回用户的活动状态(63007)
user_state(PlayerId) ->
	lib_shengxiao_new:user_status(PlayerId).

%% 用户点击投注(63010)
bet(Status, Pos1, Select1, Pos2, Select2, Pos3, Select3, Pos4, Select4) ->
	lib_shengxiao_new:bet(Status, Pos1, Select1, Pos2, Select2, Pos3, Select3, Pos4, Select4).

%% 用户领奖(63011)
award(Status) ->
	lib_shengxiao_new:award(Status).

