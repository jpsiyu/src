%%%--------------------------------------
%%% @Module  : physical.hrl
%%% @Author  : xieyunfei
%%% @Email   : xieyunfei@jieyoumail.com
%%% @Created : 2014.2.13
%%% @Description: 体力值系统
%%%--------------------------------------

-define(SQL_PHYSICAL_UPDATE, <<"UPDATE player_state SET physical=~p WHERE id=~p LIMIT 1">>).

%%第一次创建角色时候要插入一条记录
-define(SQL_ROLE_PHYSICAL_REPLACE,<<"replace into role_physical (role_id, physical_count,last_time) values (~p,~p,~p)">>).
%% 获取role_physical所需数据
-define(SQL_ROLE_PHYSICAL_DATA, <<"select `physical_count`, `last_time` from role_physical where role_id=~p limit 1">>).
%%下线时候记录玩家的体力值和冷却时间起点
-define(SQL_ROLE_PHYSICAL_UPDATE,<<"update role_physical set `physical_count`=~p, `last_time`=~p, where role_id=~p">>).


-define(PHYSICAL_SUB_BIAO, 105).			%% 消耗-领取镖车

-record(base_physical, {
	scene_id = 0,				%% 副本的场景id
	take_off = 0		%% 扣除体力值
}).

-record(clear_cd_time_gold, {
	cost_cumulate = 1,	%% 元宝清除cd次数
	cost_gold = 5		%%  该次消耗元宝数
}).
