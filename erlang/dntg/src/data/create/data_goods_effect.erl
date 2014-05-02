
%%%---------------------------------------
%%% @Module  : data_goods_effect
%%% @Author  : xhg
%%% @Email   : xuhuguang@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_goods_effect).
-export([get_val/2, get/1]).
-include("goods.hrl").

get_val(Id, Type) ->
    case data_goods_effect:get(Id) of
        [] when Type =:= buff -> [];
        [] -> 0;
        Info ->
            case Type of
                exp -> Info#ets_goods_effect.exp;
                coin -> Info#ets_goods_effect.coin;
                bcoin -> Info#ets_goods_effect.bcoin;
                llpt -> Info#ets_goods_effect.llpt;
                xwpt -> Info#ets_goods_effect.xwpt;
                whpt -> Info#ets_goods_effect.whpt;
                arena -> Info#ets_goods_effect.arena;
                battle_score -> Info#ets_goods_effect.battle_score;
                honour -> Info#ets_goods_effect.honour;
                bag_num -> Info#ets_goods_effect.bag_num;
                time -> Info#ets_goods_effect.time;
                fashion -> Info#ets_goods_effect.fashion;
                buff -> {Info#ets_goods_effect.buf_type, Info#ets_goods_effect.buf_attr, Info#ets_goods_effect.buf_val, Info#ets_goods_effect.buf_time, Info#ets_goods_effect.buf_scene};
                _ -> []
            end
    end.

get(211001) ->
    #ets_goods_effect{ goods_id=211001, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=1, buf_attr=60, buf_val=0.50, buf_time=3600, buf_scene=[] };
get(211002) ->
    #ets_goods_effect{ goods_id=211002, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=1, buf_attr=60, buf_val=0.50, buf_time=10800, buf_scene=[] };
get(211003) ->
    #ets_goods_effect{ goods_id=211003, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=1, buf_attr=60, buf_val=0.50, buf_time=21600, buf_scene=[] };
get(212101) ->
    #ets_goods_effect{ goods_id=212101, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=53, buf_val=0.05, buf_time=600, buf_scene=[] };
get(212102) ->
    #ets_goods_effect{ goods_id=212102, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=53, buf_val=0.10, buf_time=600, buf_scene=[] };
get(212103) ->
    #ets_goods_effect{ goods_id=212103, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=53, buf_val=0.15, buf_time=600, buf_scene=[] };
get(212201) ->
    #ets_goods_effect{ goods_id=212201, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=54, buf_val=0.05, buf_time=600, buf_scene=[] };
get(212202) ->
    #ets_goods_effect{ goods_id=212202, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=54, buf_val=0.10, buf_time=600, buf_scene=[] };
get(212203) ->
    #ets_goods_effect{ goods_id=212203, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=54, buf_val=0.15, buf_time=600, buf_scene=[] };
get(212301) ->
    #ets_goods_effect{ goods_id=212301, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=51, buf_val=0.05, buf_time=600, buf_scene=[] };
get(212302) ->
    #ets_goods_effect{ goods_id=212302, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=51, buf_val=0.10, buf_time=600, buf_scene=[] };
get(212303) ->
    #ets_goods_effect{ goods_id=212303, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=51, buf_val=0.15, buf_time=600, buf_scene=[] };
get(212401) ->
    #ets_goods_effect{ goods_id=212401, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=52, buf_val=0.05, buf_time=600, buf_scene=[] };
get(212402) ->
    #ets_goods_effect{ goods_id=212402, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=52, buf_val=0.10, buf_time=600, buf_scene=[] };
get(212403) ->
    #ets_goods_effect{ goods_id=212403, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=52, buf_val=0.15, buf_time=600, buf_scene=[] };
get(212501) ->
    #ets_goods_effect{ goods_id=212501, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=56, buf_val=0.05, buf_time=600, buf_scene=[] };
get(212502) ->
    #ets_goods_effect{ goods_id=212502, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=56, buf_val=0.10, buf_time=600, buf_scene=[] };
get(212503) ->
    #ets_goods_effect{ goods_id=212503, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=56, buf_val=0.15, buf_time=600, buf_scene=[] };
get(212601) ->
    #ets_goods_effect{ goods_id=212601, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=55, buf_val=0.05, buf_time=600, buf_scene=[] };
get(212602) ->
    #ets_goods_effect{ goods_id=212602, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=55, buf_val=0.10, buf_time=600, buf_scene=[] };
get(212603) ->
    #ets_goods_effect{ goods_id=212603, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=55, buf_val=0.15, buf_time=600, buf_scene=[] };
get(212701) ->
    #ets_goods_effect{ goods_id=212701, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=57, buf_val=0.05, buf_time=600, buf_scene=[] };
get(212702) ->
    #ets_goods_effect{ goods_id=212702, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=57, buf_val=0.10, buf_time=600, buf_scene=[] };
get(212703) ->
    #ets_goods_effect{ goods_id=212703, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=57, buf_val=0.15, buf_time=600, buf_scene=[] };
get(212801) ->
    #ets_goods_effect{ goods_id=212801, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=58, buf_val=0.05, buf_time=600, buf_scene=[] };
get(212802) ->
    #ets_goods_effect{ goods_id=212802, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=58, buf_val=0.10, buf_time=600, buf_scene=[] };
get(212803) ->
    #ets_goods_effect{ goods_id=212803, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=2, buf_attr=58, buf_val=0.15, buf_time=600, buf_scene=[] };
get(212901) ->
    #ets_goods_effect{ goods_id=212901, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=3, buf_attr=61, buf_val=0.50, buf_time=3600, buf_scene=[] };
get(212902) ->
    #ets_goods_effect{ goods_id=212902, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=3, buf_attr=61, buf_val=0.50, buf_time=10800, buf_scene=[] };
get(212903) ->
    #ets_goods_effect{ goods_id=212903, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=3, fashion=[], buf_type=3, buf_attr=61, buf_val=0.50, buf_time=21600, buf_scene=[] };
get(214001) ->
    #ets_goods_effect{ goods_id=214001, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=4, buf_attr=62, buf_val=0.95, buf_time=300, buf_scene=[] };
get(214002) ->
    #ets_goods_effect{ goods_id=214002, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=4, buf_attr=62, buf_val=1.00, buf_time=300, buf_scene=[] };
get(214003) ->
    #ets_goods_effect{ goods_id=214003, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=4, buf_attr=62, buf_val=1.10, buf_time=300, buf_scene=[] };
get(214004) ->
    #ets_goods_effect{ goods_id=214004, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=4, buf_attr=62, buf_val=1.25, buf_time=300, buf_scene=[] };
get(214101) ->
    #ets_goods_effect{ goods_id=214101, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=2, fashion=[], buf_type=2, buf_attr=67, buf_val=0.10, buf_time=3600, buf_scene=[] };
get(214103) ->
    #ets_goods_effect{ goods_id=214103, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=6, buf_attr=69, buf_val=0.12, buf_time=1800, buf_scene=[] };
get(214104) ->
    #ets_goods_effect{ goods_id=214104, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=6, buf_attr=69, buf_val=0.24, buf_time=1800, buf_scene=[] };
get(214105) ->
    #ets_goods_effect{ goods_id=214105, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=6, buf_attr=69, buf_val=0.36, buf_time=1800, buf_scene=[] };
get(214106) ->
    #ets_goods_effect{ goods_id=214106, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=6, buf_attr=69, buf_val=0.48, buf_time=1800, buf_scene=[] };
get(214107) ->
    #ets_goods_effect{ goods_id=214107, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=6, buf_attr=69, buf_val=0.60, buf_time=1800, buf_scene=[] };
get(214401) ->
    #ets_goods_effect{ goods_id=214401, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=6, buf_attr=68, buf_val=1.00, buf_time=7200, buf_scene=[] };
get(214501) ->
    #ets_goods_effect{ goods_id=214501, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=7, buf_attr=18, buf_val=5.00, buf_time=3600, buf_scene=[] };
get(214502) ->
    #ets_goods_effect{ goods_id=214502, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=7, buf_attr=18, buf_val=5.00, buf_time=7200, buf_scene=[] };
get(214503) ->
    #ets_goods_effect{ goods_id=214503, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=7, buf_attr=18, buf_val=5.00, buf_time=10800, buf_scene=[] };
get(221001) ->
    #ets_goods_effect{ goods_id=221001, exp=5000, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221002) ->
    #ets_goods_effect{ goods_id=221002, exp=10000, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221003) ->
    #ets_goods_effect{ goods_id=221003, exp=50000, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221004) ->
    #ets_goods_effect{ goods_id=221004, exp=1000000, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221005) ->
    #ets_goods_effect{ goods_id=221005, exp=10000, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221006) ->
    #ets_goods_effect{ goods_id=221006, exp=2500, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221007) ->
    #ets_goods_effect{ goods_id=221007, exp=2500, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221008) ->
    #ets_goods_effect{ goods_id=221008, exp=2500, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221009) ->
    #ets_goods_effect{ goods_id=221009, exp=100000, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221101) ->
    #ets_goods_effect{ goods_id=221101, exp=0, coin=1000, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221102) ->
    #ets_goods_effect{ goods_id=221102, exp=0, coin=5000, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221103) ->
    #ets_goods_effect{ goods_id=221103, exp=0, coin=10000, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221105) ->
    #ets_goods_effect{ goods_id=221105, exp=0, coin=0, bcoin=1000, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221114) ->
    #ets_goods_effect{ goods_id=221114, exp=0, coin=15000, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221115) ->
    #ets_goods_effect{ goods_id=221115, exp=0, coin=25000, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221201) ->
    #ets_goods_effect{ goods_id=221201, exp=0, coin=0, bcoin=0, llpt=100, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221202) ->
    #ets_goods_effect{ goods_id=221202, exp=0, coin=0, bcoin=0, llpt=200, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221203) ->
    #ets_goods_effect{ goods_id=221203, exp=0, coin=0, bcoin=0, llpt=500, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221204) ->
    #ets_goods_effect{ goods_id=221204, exp=0, coin=0, bcoin=0, llpt=750, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221205) ->
    #ets_goods_effect{ goods_id=221205, exp=0, coin=0, bcoin=0, llpt=10000, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221206) ->
    #ets_goods_effect{ goods_id=221206, exp=0, coin=0, bcoin=0, llpt=500, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221207) ->
    #ets_goods_effect{ goods_id=221207, exp=0, coin=0, bcoin=0, llpt=500, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221208) ->
    #ets_goods_effect{ goods_id=221208, exp=1000, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221209) ->
    #ets_goods_effect{ goods_id=221209, exp=1000, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221210) ->
    #ets_goods_effect{ goods_id=221210, exp=1000, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221211) ->
    #ets_goods_effect{ goods_id=221211, exp=1000, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221212) ->
    #ets_goods_effect{ goods_id=221212, exp=0, coin=0, bcoin=0, llpt=500, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221213) ->
    #ets_goods_effect{ goods_id=221213, exp=0, coin=0, bcoin=0, llpt=100, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221214) ->
    #ets_goods_effect{ goods_id=221214, exp=0, coin=0, bcoin=0, llpt=100, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221215) ->
    #ets_goods_effect{ goods_id=221215, exp=0, coin=0, bcoin=0, llpt=100, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221216) ->
    #ets_goods_effect{ goods_id=221216, exp=0, coin=0, bcoin=0, llpt=100, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221217) ->
    #ets_goods_effect{ goods_id=221217, exp=0, coin=0, bcoin=0, llpt=100, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221218) ->
    #ets_goods_effect{ goods_id=221218, exp=0, coin=0, bcoin=0, llpt=500, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221219) ->
    #ets_goods_effect{ goods_id=221219, exp=0, coin=0, bcoin=0, llpt=500, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221220) ->
    #ets_goods_effect{ goods_id=221220, exp=0, coin=0, bcoin=0, llpt=500, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221221) ->
    #ets_goods_effect{ goods_id=221221, exp=0, coin=0, bcoin=0, llpt=500, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221222) ->
    #ets_goods_effect{ goods_id=221222, exp=0, coin=0, bcoin=0, llpt=500, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221223) ->
    #ets_goods_effect{ goods_id=221223, exp=0, coin=0, bcoin=0, llpt=200, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221301) ->
    #ets_goods_effect{ goods_id=221301, exp=0, coin=0, bcoin=0, llpt=0, xwpt=100, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221302) ->
    #ets_goods_effect{ goods_id=221302, exp=0, coin=0, bcoin=0, llpt=0, xwpt=200, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221303) ->
    #ets_goods_effect{ goods_id=221303, exp=0, coin=0, bcoin=0, llpt=0, xwpt=500, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221304) ->
    #ets_goods_effect{ goods_id=221304, exp=0, coin=0, bcoin=0, llpt=0, xwpt=600, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221501) ->
    #ets_goods_effect{ goods_id=221501, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=50, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221502) ->
    #ets_goods_effect{ goods_id=221502, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=500, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(221503) ->
    #ets_goods_effect{ goods_id=221503, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=2500, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(222001) ->
    #ets_goods_effect{ goods_id=222001, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=1, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(222002) ->
    #ets_goods_effect{ goods_id=222002, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=6, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(222101) ->
    #ets_goods_effect{ goods_id=222101, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=1, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(222102) ->
    #ets_goods_effect{ goods_id=222102, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=6, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(222201) ->
    #ets_goods_effect{ goods_id=222201, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=5, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(222401) ->
    #ets_goods_effect{ goods_id=222401, exp=0, coin=0, bcoin=0, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=6, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(521301) ->
    #ets_goods_effect{ goods_id=521301, exp=0, coin=0, bcoin=5000, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(521302) ->
    #ets_goods_effect{ goods_id=521302, exp=0, coin=0, bcoin=5000, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(521303) ->
    #ets_goods_effect{ goods_id=521303, exp=0, coin=0, bcoin=5000, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(521304) ->
    #ets_goods_effect{ goods_id=521304, exp=0, coin=0, bcoin=5000, llpt=0, xwpt=0, whpt=0, arena=0, battle_score=0, honour=0, bag_num=0, time=0, fashion=[], buf_type=0, buf_attr=0, buf_val=0.00, buf_time=0, buf_scene=[] };
get(_Id) ->
    [].
