
%%%---------------------------------------
%%% @Module  : data_hp_bag
%%% @Author  : xhg
%%% @Email   : xuhuguang@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_hp_bag).
-compile(export_all).
-include("goods.hrl").

get(1) ->
	#base_hp_bag{ type = 1, reply_span = 2, scene_lim = [], scene_allow = [] };
get(2) ->
	#base_hp_bag{ type = 2, reply_span = 2, scene_lim = [], scene_allow = [] };
get(5) ->
	#base_hp_bag{ type = 5, reply_span = 5, scene_lim = [], scene_allow = [] };
get(6) ->
	#base_hp_bag{ type = 6, reply_span = 5, scene_lim = [], scene_allow = [] };
get(7) ->
	#base_hp_bag{ type = 7, reply_span = 10, scene_lim = [], scene_allow = [5] };
get(8) ->
	#base_hp_bag{ type = 8, reply_span = 10, scene_lim = [], scene_allow = [5] };
get(_Id) ->
    [].

%%血包法包的上限和单次回复又角色等级决定，
%% [{0,29},50000,500]说明，[{0,29}]：0到29级，50000：血池上限，500：单次回复量
get_bag_data() -> 
	[[{0,20},200000,75],[{21,29},396000,150],[{30,39},648000,250],[{40,49},1044000,400],[{50,59},1566000,600],[{60,69},2340000,900],[{70,79},3420000,1300],[{80,89},4680000,1800],[{80,999},4680000,1800]].

get_reply_num(107) -> 0;
get_reply_num(200301) -> 2250;
get_reply_num(200401) -> 500;
get_reply_num(201101) -> 125;
get_reply_num(201111) -> 5000;
get_reply_num(201121) -> 1200;
get_reply_num(201301) -> 250;
get_reply_num(201401) -> 750;
get_reply_num(201501) -> 1125;
get_reply_num(201601) -> 1625;
get_reply_num(201701) -> 2250;
get_reply_num(201801) -> 3375;
get_reply_num(202101) -> 20;
get_reply_num(202111) -> 1000;
get_reply_num(202121) -> 0;
get_reply_num(202301) -> 50;
get_reply_num(202401) -> 150;
get_reply_num(202501) -> 225;
get_reply_num(202601) -> 350;
get_reply_num(202701) -> 500;
get_reply_num(202702) -> 3375;
get_reply_num(202801) -> 750;
get_reply_num(205101) -> 0;
get_reply_num(205201) -> 0;
get_reply_num(205301) -> 0;
get_reply_num(205401) -> 0;
get_reply_num(206101) -> 0;
get_reply_num(206201) -> 0;
get_reply_num(206301) -> 0;
get_reply_num(206401) -> 0;
get_reply_num(207201) -> 4000;
get_reply_num(207301) -> 4000;
get_reply_num(208201) -> 1000;
get_reply_num(208301) -> 1000;
get_reply_num(_GoodsId) -> 0.
