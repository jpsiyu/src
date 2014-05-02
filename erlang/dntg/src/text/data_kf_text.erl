%%%--------------------------------------
%%% @Module  : data_kf_text
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.12.21
%%% @Description: 跨服活动相关
%%%--------------------------------------

-module(data_kf_text).
-compile(export_all).

%%==================== 跨服3v3 ====================%%
get_3v3_mail_title() -> "3V3竞技参与奖励".
get_3v3_mail_content() -> "恭喜你在参与本轮3V3竞技 ~p 场比赛，总共获胜 ~p 场，失败 ~p 场，累计获得 ~p个跨服竞技勋章奖励。".

get_3v3_top_100_title() -> "跨服竞技积分第 ~p 名奖励".
get_3v3_top_100_content() -> "恭喜你在这一轮的跨服竞技比赛中榜上有名，获得第 ~p 名。".

get_bd_3v3_rank_title() -> "3V3积分排行奖励".
get_bd_3v3_rank_content1() -> "恭喜您在本次3V3积分排行榜中榜上有名，位列第 ~p 名。".
get_bd_3v3_rank_content2() -> "恭喜您在本次3V3积分排行榜中榜上有名，位列第 ~p-~p 名。".
get_bd_3v3_rank_content3() -> "恭喜您在本次3V3积分排行榜中榜上有名，位列第 ~p 名以上。".
