%%%--------------------------------------
%%% @Module  : data_merge
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.9.27
%%% @Description: 合服活动
%%%--------------------------------------

-module(data_merge).
-compile(export_all).

%% 充值活动持续天数
get_recharge_day() -> 5.

%% 帮战活动持续天数
get_guild_day() -> 5.

%% 排行榜活动持续天数
get_rank_day() -> 5.

%% 合服活动中最长的活动天数
get_longest_day() -> 7.

%% 全服感恩回馈大礼包
get_mail_gift() -> 535207.

%% 通过礼包id取出需要的元宝数
get_recharge_gift_and_gold() -> 
	[
		[535201, 880],
		[535202, 2880],
		[535203, 5880],
		[535204, 9880],
		[535205, 19880],
		[535206, 29880]
	].

%% 获取礼包：玩家战力榜第1名，第2至5名，第6至10名
get_rank_gift(1001, 1) -> 535208;
get_rank_gift(1001, 2) -> 535209;
get_rank_gift(1001, 3) -> 535210;
%% 获取礼包：宠物战力榜第1名，第2至5名，第6至10名
get_rank_gift(2001, 1) -> 535211;
get_rank_gift(2001, 2) -> 535212;
get_rank_gift(2001, 3) -> 535213;
%% 获取礼包：竞技场每日上榜第1名，第2至5名，第6至10名
get_rank_gift(5001, 1) -> 535214;
get_rank_gift(5001, 2) -> 535215;
get_rank_gift(5001, 3) -> 535216;
get_rank_gift(_, _) -> 0.
%% 获取礼包：第一名帮主和帮众，第二名全部，第三名全部
get_guild_gift(1, 1) -> 535217;
get_guild_gift(1, 2) -> 535218;
get_guild_gift(2, 0) -> 535219;
get_guild_gift(3, 0) -> 535220;
get_guild_gift(_, _) -> 535220.
