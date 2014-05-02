%%%---------------------------------------
%%%--------------------------------------
%%% @Module  : data_activity_festival
%%% @Description: 贺卡配置
%%%--------------------------------------
-module(data_activity_festival).
-compile(export_all).
-include("activity.hrl").

%% 是否节日活动时间
is_festival_day() ->
	StartDay = 1356969630,
	EndDay = 1357401350,	
	NowTime = util:unixtime(),
	NowTime>= StartDay andalso NowTime=<EndDay.

%% 贺卡礼物消耗[道具](物品ID)->消耗数量
get_festivial_card_gift_cost2(534097) -> 1;
get_festivial_card_gift_cost2(534098) -> 2;
get_festivial_card_gift_cost2(534099) -> 3;
get_festivial_card_gift_cost2(534100) -> 4;
get_festivial_card_gift_cost2(534101) -> 5;
get_festivial_card_gift_cost2(_GoodsId) -> 0.

%% 贺卡消耗[铜币](贺卡ID)->消耗铜币
get_festivial_card_cost(101) -> 50000;
get_festivial_card_cost(102) -> 100000;
get_festivial_card_cost(103) -> 150000;
get_festivial_card_cost(104) -> 200000;
get_festivial_card_cost(106) -> 50000;
get_festivial_card_cost(107) -> 50000;
get_festivial_card_cost(108) -> 50000;
get_festivial_card_cost(109) -> 100000;
get_festivial_card_cost(110) -> 50000;
get_festivial_card_cost(111) -> 50000;
get_festivial_card_cost(112) -> 50000;
get_festivial_card_cost(113) -> 50000;
get_festivial_card_cost(114) -> 50000;
get_festivial_card_cost(_CardId) -> 0.

%% 不含系统，贺卡礼物消耗[道具](物品ID)
get_festivial_card_gift() ->
	[0, 534097,534098,534099,534100,534101].		

%% 不含系统，贺卡消耗[铜币](贺卡ID)
get_festivial_card_id() ->
	[0, 101,102,103,104,106,107,108,109,110,111,112,113,114].		

%% 贺卡常量配置
get_festivial_card_constant(Type) ->
	if 
		Type =:= cost_goods_id -> 522009;
		true -> 0
	end.	

%%祝福语
sys_festivial_card_wishmsg() ->
	"漫天雪花飘飞，迎来了新年，让久违的心灵相聚吧，我深深的祝福你：新年快乐!".

%% 暂时不分等级,后面可根据需要扩展
sys_festivial_card_gift() ->
	531401.

%%系统默认发送贺卡ID
sys_festivial_card_id() ->
	105.

