%%%---------------------------------------
%%% @Module  : data_fame
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:28
%%% @Description:  名人堂
%%%---------------------------------------
-module(data_fame).
-compile(export_all).
-include("fame.hrl").

%% 按分类获取荣誉列表
get_list_by_type(1) -> 
	[get_fame(Id) || Id <- [10101]];
get_list_by_type(2) -> 
	[get_fame(Id) || Id <- [10201]];
get_list_by_type(4) -> 
	[get_fame(Id) || Id <- [10401]];
get_list_by_type(5) -> 
	[get_fame(Id) || Id <- [10501]];
get_list_by_type(6) -> 
	[get_fame(Id) || Id <- [10701]];
get_list_by_type(7) -> 
	[get_fame(Id) || Id <- [10801]];
get_list_by_type(8) -> 
	[get_fame(Id) || Id <- [10901]];
get_list_by_type(9) -> 
	[get_fame(Id) || Id <- [11001]];
get_list_by_type(10) -> 
	[get_fame(Id) || Id <- [11101]];
get_list_by_type(11) -> 
	[get_fame(Id) || Id <- [11201]];
get_list_by_type(13) -> 
	[get_fame(Id) || Id <- [11301]];
get_list_by_type(12) -> 
	[get_fame(Id) || Id <- [11401]];
get_list_by_type(25) -> 
	[get_fame(Id) || Id <- [11501]];
get_list_by_type(14) -> 
	[get_fame(Id) || Id <- [11601]];
get_list_by_type(15) -> 
	[get_fame(Id) || Id <- [11701]];
get_list_by_type(16) -> 
	[get_fame(Id) || Id <- [11801]];
get_list_by_type(17) -> 
	[get_fame(Id) || Id <- [11901]];
get_list_by_type(18) -> 
	[get_fame(Id) || Id <- [12001]];
get_list_by_type(20) -> 
	[get_fame(Id) || Id <- [12201]];
get_list_by_type(21) -> 
	[get_fame(Id) || Id <- [12301]];
get_list_by_type(22) -> 
	[get_fame(Id) || Id <- [12401]];
get_list_by_type(23) -> 
	[get_fame(Id) || Id <- [12501]];
get_list_by_type(24) -> 
	[get_fame(Id) || Id <- [12601]];
get_list_by_type(_Type) -> [].

get_ids(0) -> [10101,10201,10401,10501,10701,10801,10901,11001,11101,11201,11301,11401];
get_ids(1) -> [11501,11601,11701,11801,11901,12001,12201,12301,12401,12501,12601];
get_ids(_) -> [10101,10201,10401,10501,10701,10801,10901,11001,11101,11201,11301,11401,11501,11601,11701,11801,11901,12001,12201,12301,12401,12501,12601].

get_ids_list(0) -> [get_fame(Id) || Id <- get_ids(0)];
get_ids_list(1) -> [get_fame(Id) || Id <- get_ids(1)];
get_ids_list(_) -> [get_fame(Id) || Id <- get_ids(all)].

%% 通过id获得荣誉数据
get_fame(10101) ->
	#base_fame{id=10101, type=1, merge=0,name= <<"副本突击">>, desc= <<"第一个击杀多人九重天的神兽白虎">>, target_id=[30115], num=1, award=[], design_id=201601};
get_fame(10201) ->
	#base_fame{id=10201, type=2, merge=0,name= <<"如日中天">>, desc= <<"第一个国家声望达到1000">>, target_id=[], num=1000, award=[], design_id=201602};
get_fame(10401) ->
	#base_fame{id=10401, type=4, merge=0,name= <<"匠心第一">>, desc= <<"第一个将武器强化到7级">>, target_id=[], num=7, award=[], design_id=201604};
get_fame(10501) ->
	#base_fame{id=10501, type=5, merge=0,name= <<"真有一套">>, desc= <<"第一个穿戴紫色套装全部部件">>, target_id=[10040,10140,10240,10042,10142,10242], num=1, award=[], design_id=201605};
get_fame(10701) ->
	#base_fame{id=10701, type=6, merge=0,name= <<"宝贝来了">>, desc= <<"第一个宠物成长达到40">>, target_id=[], num=40, award=[], design_id=201607};
get_fame(10801) ->
	#base_fame{id=10801, type=7, merge=0,name= <<"不灭元神">>, desc= <<"第一个元神总等级超过200">>, target_id=[], num=200, award=[], design_id=201608};
get_fame(10901) ->
	#base_fame{id=10901, type=8, merge=0,name= <<"冲级！">>, desc= <<"第一个人物达到50">>, target_id=[], num=50, award=[], design_id=201609};
get_fame(11001) ->
	#base_fame{id=11001, type=9, merge=0,name= <<"领军天下">>, desc= <<"第一个战力达到8000">>, target_id=[], num=8000, award=[], design_id=201610};
get_fame(11101) ->
	#base_fame{id=11101, type=10, merge=0,name= <<"我爱钻石">>, desc= <<"第一个镶嵌5级宝石">>, target_id=[], num=5, award=[], design_id=201611};
get_fame(11201) ->
	#base_fame{id=11201, type=11, merge=0,name= <<"第一面旗">>, desc= <<"第一个建立帮会">>, target_id=[], num=1, award=[], design_id=201612};
get_fame(11301) ->
	#base_fame{id=11301, type=13, merge=0,name= <<"成就达人">>, desc= <<"第一个成就达到1000点数">>, target_id=[], num=1000, award=[], design_id=201613};
get_fame(11401) ->
	#base_fame{id=11401, type=12, merge=0,name= <<"谁人不识君">>, desc= <<"第一个拥有200个好友">>, target_id=[], num=200, award=[], design_id=201614};
get_fame(11501) ->
	#base_fame{id=11501, type=25, merge=1,name= <<"谁能挡我">>, desc= <<"合区首次帮战的杀人第一">>, target_id=[], num=1, award=[], design_id=201615};
get_fame(11601) ->
	#base_fame{id=11601, type=14, merge=1,name= <<"征战诸天">>, desc= <<"合区首次帮战的获胜帮派的帮主">>, target_id=[], num=1, award=[], design_id=201616};
get_fame(11701) ->
	#base_fame{id=11701, type=15, merge=1,name= <<"无敌斗圣">>, desc= <<"合区首次竞技场的积分第一">>, target_id=[], num=1, award=[], design_id=201617};
get_fame(11801) ->
	#base_fame{id=11801, type=16, merge=1,name= <<"死亡收割">>, desc= <<"合区首次竞技场的杀人数第一">>, target_id=[], num=1, award=[], design_id=201618};
get_fame(11901) ->
	#base_fame{id=11901, type=17, merge=1,name= <<"合服我最帅">>, desc= <<"合区首日的护花榜第一">>, target_id=[], num=1, award=[], design_id=201619};
get_fame(12001) ->
	#base_fame{id=12001, type=18, merge=1,name= <<"合服我最靓">>, desc= <<"合区首日的鲜花榜第一">>, target_id=[], num=1, award=[], design_id=201620};
get_fame(12201) ->
	#base_fame{id=12201, type=20, merge=1,name= <<"天道霸主">>, desc= <<"合区首日的单人九重天30层霸主">>, target_id=[], num=1, award=[], design_id=201622};
get_fame(12301) ->
	#base_fame{id=12301, type=21, merge=1,name= <<"制霸九天">>, desc= <<"合区首日的多人九重天30层霸主">>, target_id=[30], num=1, award=[], design_id=201623};
get_fame(12401) ->
	#base_fame{id=12401, type=22, merge=1,name= <<"至尊神器">>, desc= <<"合区首日的武器榜第一">>, target_id=[], num=1, award=[], design_id=201624};
get_fame(12501) ->
	#base_fame{id=12501, type=23, merge=1,name= <<"阵营第一">>, desc= <<"合区首日的声望榜第一">>, target_id=[], num=1, award=[], design_id=201625};
get_fame(12601) ->
	#base_fame{id=12601, type=24, merge=1,name= <<"西游首富">>, desc= <<"合区首日的财富榜第一">>, target_id=[], num=1, award=[], design_id=201626};
get_fame(_Id) ->
	[].

