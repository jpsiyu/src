%%%-------------------------------------------------------------------
%%% @Module	: turntable
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	:  5 Jul 2012
%%% @Description: 转盘record定义
%%%-------------------------------------------------------------------


-define(ETS_PLAYER_GOODS, player_goods).
-record(player_ratio, {free_cnt=0, coin_cnt=0, award1=0, award2=0, award3=0, award4=0, item1=0, item2=0, item3=0, item4=0}).
-record(player_goods, {id=0, nickname="", itemid=0, coin=0, timestamp=0}).
-record(db_record, {player_id=0, play_type=0, award=0, count=0, time}).
