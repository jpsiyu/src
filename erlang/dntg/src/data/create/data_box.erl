
%%%---------------------------------------
%%% @Module  : data_box
%%% @Author  : xhg
%%% @Email   : xuhuguang@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_box).
-compile(export_all).
-include("box.hrl").

get_all() ->
    [1,2,3,4].

get_box(1) ->
    #ets_box{ 
        id=1, 
        name = <<"海底淘宝">>,
        price=10,
        price2=95,
        price3=450,
        base_goods=[221102],
        guard_num=200,
        ratio=10000,
        high_box=0,
        high_player=0,
        goods_list=[{111041,1},{121001,1},{121002,1},{624201,1},{624201,2},{624201,4},{624201,8},{112104,1},{601601,1},{621002,1},{624801,1},{624801,2},{624801,4},{624801,8},{111481,1},{111482,1},{111483,1},{111491,1},{111492,1},{111493,1},{111501,1},{111502,1},{111503,1},{205101,1},{205201,1},{205301,1},{206101,1},{206201,1},{206301,1},{621301,1},{621302,1},{621303,1},{211001,1},{211002,1},{211003,1},{221101,1},{221102,1},{221103,1},{231201,1},{231201,2},{231201,4},{222001,1},{222101,1}]
    };
get_box(2) ->
    #ets_box{ 
        id=2, 
        name = <<"仙境淘宝">>,
        price=20,
        price2=190,
        price3=900,
        base_goods=[221102],
        guard_num=300,
        ratio=10000,
        high_box=0,
        high_player=0,
        goods_list=[{122506,1},{112303,1},{112304,1},{601501,1},{601602,1},{111021,1},{111022,1},{111023,1},{111024,1},{111025,1},{111026,1},{111401,1},{111411,1},{111421,1},{111431,1},{111441,1},{111451,1},{111461,1},{111471,1},{111402,1},{111412,1},{111422,1},{111432,1},{111442,1},{111452,1},{111462,1},{111472,1},{111403,1},{111413,1},{111423,1},{111433,1},{111443,1},{111453,1},{111463,1},{111473,1},{121302,1},{121402,1},{121702,1},{121001,1},{121002,1},{121003,1},{121004,1},{121005,1},{231202,1},{121006,1},{205301,1},{206301,1},{212102,1},{212202,1},{212302,1},{221103,1},{221102,1},{221002,1},{621302,1},{625001,1},{623203,1},{624802,1},{624801,1},{624201,1},{624202,1},{221202,1},{112105,1}]
    };
get_box(3) ->
    #ets_box{ 
        id=3, 
        name = <<"骑兵远征">>,
        price=20,
        price2=190,
        price3=900,
        base_goods=[221102],
        guard_num=0,
        ratio=10000,
        high_box=0,
        high_player=0,
        goods_list=[{221102,1}]
    };
get_box(4) ->
    #ets_box{ 
        id=4, 
        name = <<"神兵远征">>,
        price=40,
        price2=380,
        price3=1800,
        base_goods=[221102],
        guard_num=0,
        ratio=10000,
        high_box=0,
        high_player=0,
        goods_list=[{221102,1}]
    };
get_box(_BoxId) ->
    [].

get_box_goods(1, 111041, 1) ->
    #ets_box_goods{ id=1, box_id=1, goods_id=111041, goods_num=1, type=0, bind=0, notice=0, ratio=450, ratio_start=1, ratio_end=450, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 121001, 1) ->
    #ets_box_goods{ id=2, box_id=1, goods_id=121001, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=451, ratio_end=550, lim_career=0, lim_box=0, lim_player=0, lim_num=10 };
get_box_goods(1, 121002, 1) ->
    #ets_box_goods{ id=3, box_id=1, goods_id=121002, goods_num=1, type=1, bind=0, notice=1, ratio=50, ratio_start=551, ratio_end=600, lim_career=0, lim_box=0, lim_player=0, lim_num=30 };
get_box_goods(1, 624201, 1) ->
    #ets_box_goods{ id=4, box_id=1, goods_id=624201, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=601, ratio_end=900, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 624201, 2) ->
    #ets_box_goods{ id=5, box_id=1, goods_id=624201, goods_num=2, type=0, bind=0, notice=0, ratio=200, ratio_start=901, ratio_end=1100, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 624201, 4) ->
    #ets_box_goods{ id=6, box_id=1, goods_id=624201, goods_num=4, type=0, bind=0, notice=0, ratio=100, ratio_start=1101, ratio_end=1200, lim_career=0, lim_box=0, lim_player=0, lim_num=8 };
get_box_goods(1, 624201, 8) ->
    #ets_box_goods{ id=7, box_id=1, goods_id=624201, goods_num=8, type=0, bind=0, notice=1, ratio=75, ratio_start=1201, ratio_end=1275, lim_career=0, lim_box=0, lim_player=0, lim_num=8 };
get_box_goods(1, 112104, 1) ->
    #ets_box_goods{ id=8, box_id=1, goods_id=112104, goods_num=1, type=1, bind=0, notice=1, ratio=90, ratio_start=1276, ratio_end=1365, lim_career=0, lim_box=0, lim_player=0, lim_num=50 };
get_box_goods(1, 601601, 1) ->
    #ets_box_goods{ id=9, box_id=1, goods_id=601601, goods_num=1, type=0, bind=0, notice=0, ratio=150, ratio_start=1366, ratio_end=1515, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 621002, 1) ->
    #ets_box_goods{ id=10, box_id=1, goods_id=621002, goods_num=1, type=1, bind=0, notice=1, ratio=5, ratio_start=1516, ratio_end=1520, lim_career=0, lim_box=0, lim_player=0, lim_num=150 };
get_box_goods(1, 624801, 1) ->
    #ets_box_goods{ id=11, box_id=1, goods_id=624801, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=1521, ratio_end=1820, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 624801, 2) ->
    #ets_box_goods{ id=12, box_id=1, goods_id=624801, goods_num=2, type=0, bind=0, notice=0, ratio=200, ratio_start=1821, ratio_end=2020, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 624801, 4) ->
    #ets_box_goods{ id=13, box_id=1, goods_id=624801, goods_num=4, type=0, bind=0, notice=0, ratio=100, ratio_start=2021, ratio_end=2120, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 624801, 8) ->
    #ets_box_goods{ id=14, box_id=1, goods_id=624801, goods_num=8, type=0, bind=0, notice=1, ratio=80, ratio_start=2121, ratio_end=2200, lim_career=0, lim_box=0, lim_player=0, lim_num=8 };
get_box_goods(1, 111481, 1) ->
    #ets_box_goods{ id=15, box_id=1, goods_id=111481, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=2201, ratio_end=2500, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 111482, 1) ->
    #ets_box_goods{ id=16, box_id=1, goods_id=111482, goods_num=1, type=0, bind=0, notice=0, ratio=150, ratio_start=2501, ratio_end=2650, lim_career=0, lim_box=0, lim_player=0, lim_num=8 };
get_box_goods(1, 111483, 1) ->
    #ets_box_goods{ id=17, box_id=1, goods_id=111483, goods_num=1, type=1, bind=0, notice=1, ratio=50, ratio_start=2651, ratio_end=2700, lim_career=0, lim_box=0, lim_player=0, lim_num=20 };
get_box_goods(1, 111491, 1) ->
    #ets_box_goods{ id=18, box_id=1, goods_id=111491, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=2701, ratio_end=3000, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 111492, 1) ->
    #ets_box_goods{ id=19, box_id=1, goods_id=111492, goods_num=1, type=0, bind=0, notice=0, ratio=150, ratio_start=3001, ratio_end=3150, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 111493, 1) ->
    #ets_box_goods{ id=20, box_id=1, goods_id=111493, goods_num=1, type=1, bind=0, notice=1, ratio=50, ratio_start=3151, ratio_end=3200, lim_career=0, lim_box=0, lim_player=0, lim_num=8 };
get_box_goods(1, 111501, 1) ->
    #ets_box_goods{ id=21, box_id=1, goods_id=111501, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=3201, ratio_end=3500, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 111502, 1) ->
    #ets_box_goods{ id=22, box_id=1, goods_id=111502, goods_num=1, type=0, bind=0, notice=0, ratio=150, ratio_start=3501, ratio_end=3650, lim_career=0, lim_box=0, lim_player=0, lim_num=8 };
get_box_goods(1, 111503, 1) ->
    #ets_box_goods{ id=23, box_id=1, goods_id=111503, goods_num=1, type=1, bind=0, notice=1, ratio=50, ratio_start=3651, ratio_end=3700, lim_career=0, lim_box=0, lim_player=0, lim_num=20 };
get_box_goods(1, 205101, 1) ->
    #ets_box_goods{ id=24, box_id=1, goods_id=205101, goods_num=1, type=0, bind=0, notice=0, ratio=600, ratio_start=3701, ratio_end=4300, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 205201, 1) ->
    #ets_box_goods{ id=25, box_id=1, goods_id=205201, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=4301, ratio_end=4600, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 205301, 1) ->
    #ets_box_goods{ id=26, box_id=1, goods_id=205301, goods_num=1, type=0, bind=0, notice=1, ratio=100, ratio_start=4601, ratio_end=4700, lim_career=0, lim_box=0, lim_player=0, lim_num=8 };
get_box_goods(1, 206101, 1) ->
    #ets_box_goods{ id=27, box_id=1, goods_id=206101, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=4701, ratio_end=5000, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 206201, 1) ->
    #ets_box_goods{ id=28, box_id=1, goods_id=206201, goods_num=1, type=0, bind=0, notice=0, ratio=200, ratio_start=5001, ratio_end=5200, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 206301, 1) ->
    #ets_box_goods{ id=29, box_id=1, goods_id=206301, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=5201, ratio_end=5300, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 621301, 1) ->
    #ets_box_goods{ id=30, box_id=1, goods_id=621301, goods_num=1, type=0, bind=0, notice=0, ratio=400, ratio_start=5301, ratio_end=5700, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 621302, 1) ->
    #ets_box_goods{ id=31, box_id=1, goods_id=621302, goods_num=1, type=0, bind=0, notice=0, ratio=200, ratio_start=5701, ratio_end=5900, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 621303, 1) ->
    #ets_box_goods{ id=32, box_id=1, goods_id=621303, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=5901, ratio_end=6000, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 211001, 1) ->
    #ets_box_goods{ id=33, box_id=1, goods_id=211001, goods_num=1, type=0, bind=0, notice=0, ratio=400, ratio_start=6001, ratio_end=6400, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 211002, 1) ->
    #ets_box_goods{ id=34, box_id=1, goods_id=211002, goods_num=1, type=0, bind=0, notice=0, ratio=200, ratio_start=6401, ratio_end=6600, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 211003, 1) ->
    #ets_box_goods{ id=35, box_id=1, goods_id=211003, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=6601, ratio_end=6700, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 221101, 1) ->
    #ets_box_goods{ id=36, box_id=1, goods_id=221101, goods_num=1, type=0, bind=0, notice=0, ratio=900, ratio_start=6701, ratio_end=7600, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 221102, 1) ->
    #ets_box_goods{ id=37, box_id=1, goods_id=221102, goods_num=1, type=0, bind=0, notice=0, ratio=800, ratio_start=7601, ratio_end=8400, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 221103, 1) ->
    #ets_box_goods{ id=38, box_id=1, goods_id=221103, goods_num=1, type=0, bind=0, notice=0, ratio=600, ratio_start=8401, ratio_end=9000, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 231201, 1) ->
    #ets_box_goods{ id=39, box_id=1, goods_id=231201, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=9001, ratio_end=9300, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 231201, 2) ->
    #ets_box_goods{ id=40, box_id=1, goods_id=231201, goods_num=2, type=0, bind=0, notice=0, ratio=200, ratio_start=9301, ratio_end=9500, lim_career=0, lim_box=0, lim_player=0, lim_num=8 };
get_box_goods(1, 231201, 4) ->
    #ets_box_goods{ id=41, box_id=1, goods_id=231201, goods_num=4, type=1, bind=0, notice=1, ratio=100, ratio_start=9501, ratio_end=9600, lim_career=0, lim_box=0, lim_player=0, lim_num=20 };
get_box_goods(1, 222001, 1) ->
    #ets_box_goods{ id=42, box_id=1, goods_id=222001, goods_num=1, type=0, bind=0, notice=0, ratio=200, ratio_start=9601, ratio_end=9800, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(1, 222101, 1) ->
    #ets_box_goods{ id=43, box_id=1, goods_id=222101, goods_num=1, type=0, bind=0, notice=0, ratio=200, ratio_start=9801, ratio_end=10000, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 122506, 1) ->
    #ets_box_goods{ id=61, box_id=2, goods_id=122506, goods_num=1, type=0, bind=0, notice=0, ratio=30, ratio_start=1, ratio_end=30, lim_career=0, lim_box=0, lim_player=0, lim_num=80 };
get_box_goods(2, 112303, 1) ->
    #ets_box_goods{ id=62, box_id=2, goods_id=112303, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=31, ratio_end=130, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 112304, 1) ->
    #ets_box_goods{ id=63, box_id=2, goods_id=112304, goods_num=1, type=0, bind=0, notice=0, ratio=50, ratio_start=131, ratio_end=180, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 601501, 1) ->
    #ets_box_goods{ id=64, box_id=2, goods_id=601501, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=181, ratio_end=480, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 601602, 1) ->
    #ets_box_goods{ id=65, box_id=2, goods_id=601602, goods_num=1, type=0, bind=0, notice=0, ratio=0, ratio_start=0, ratio_end=0, lim_career=0, lim_box=0, lim_player=0, lim_num=80 };
get_box_goods(2, 111021, 1) ->
    #ets_box_goods{ id=66, box_id=2, goods_id=111021, goods_num=1, type=0, bind=0, notice=0, ratio=200, ratio_start=481, ratio_end=680, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111022, 1) ->
    #ets_box_goods{ id=67, box_id=2, goods_id=111022, goods_num=1, type=0, bind=0, notice=0, ratio=500, ratio_start=681, ratio_end=1180, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111023, 1) ->
    #ets_box_goods{ id=68, box_id=2, goods_id=111023, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=1181, ratio_end=1480, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111024, 1) ->
    #ets_box_goods{ id=69, box_id=2, goods_id=111024, goods_num=1, type=0, bind=0, notice=0, ratio=200, ratio_start=1481, ratio_end=1680, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111025, 1) ->
    #ets_box_goods{ id=70, box_id=2, goods_id=111025, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=1681, ratio_end=1780, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111026, 1) ->
    #ets_box_goods{ id=71, box_id=2, goods_id=111026, goods_num=1, type=0, bind=0, notice=0, ratio=50, ratio_start=1781, ratio_end=1830, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111401, 1) ->
    #ets_box_goods{ id=72, box_id=2, goods_id=111401, goods_num=1, type=0, bind=0, notice=0, ratio=90, ratio_start=1831, ratio_end=1920, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111411, 1) ->
    #ets_box_goods{ id=73, box_id=2, goods_id=111411, goods_num=1, type=0, bind=0, notice=0, ratio=270, ratio_start=1921, ratio_end=2190, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111421, 1) ->
    #ets_box_goods{ id=74, box_id=2, goods_id=111421, goods_num=1, type=0, bind=0, notice=0, ratio=180, ratio_start=2191, ratio_end=2370, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111431, 1) ->
    #ets_box_goods{ id=75, box_id=2, goods_id=111431, goods_num=1, type=0, bind=0, notice=0, ratio=180, ratio_start=2371, ratio_end=2550, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111441, 1) ->
    #ets_box_goods{ id=76, box_id=2, goods_id=111441, goods_num=1, type=0, bind=0, notice=0, ratio=270, ratio_start=2551, ratio_end=2820, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111451, 1) ->
    #ets_box_goods{ id=77, box_id=2, goods_id=111451, goods_num=1, type=0, bind=0, notice=0, ratio=270, ratio_start=2821, ratio_end=3090, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111461, 1) ->
    #ets_box_goods{ id=78, box_id=2, goods_id=111461, goods_num=1, type=0, bind=0, notice=0, ratio=270, ratio_start=3091, ratio_end=3360, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111471, 1) ->
    #ets_box_goods{ id=79, box_id=2, goods_id=111471, goods_num=1, type=0, bind=0, notice=0, ratio=360, ratio_start=3361, ratio_end=3720, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111402, 1) ->
    #ets_box_goods{ id=80, box_id=2, goods_id=111402, goods_num=1, type=0, bind=0, notice=0, ratio=60, ratio_start=3721, ratio_end=3780, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111412, 1) ->
    #ets_box_goods{ id=81, box_id=2, goods_id=111412, goods_num=1, type=0, bind=0, notice=0, ratio=180, ratio_start=3781, ratio_end=3960, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111422, 1) ->
    #ets_box_goods{ id=82, box_id=2, goods_id=111422, goods_num=1, type=0, bind=0, notice=0, ratio=120, ratio_start=3961, ratio_end=4080, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111432, 1) ->
    #ets_box_goods{ id=83, box_id=2, goods_id=111432, goods_num=1, type=0, bind=0, notice=0, ratio=120, ratio_start=4081, ratio_end=4200, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111442, 1) ->
    #ets_box_goods{ id=84, box_id=2, goods_id=111442, goods_num=1, type=0, bind=0, notice=0, ratio=180, ratio_start=4201, ratio_end=4380, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111452, 1) ->
    #ets_box_goods{ id=85, box_id=2, goods_id=111452, goods_num=1, type=0, bind=0, notice=0, ratio=180, ratio_start=4381, ratio_end=4560, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111462, 1) ->
    #ets_box_goods{ id=86, box_id=2, goods_id=111462, goods_num=1, type=0, bind=0, notice=0, ratio=180, ratio_start=4561, ratio_end=4740, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111472, 1) ->
    #ets_box_goods{ id=87, box_id=2, goods_id=111472, goods_num=1, type=0, bind=0, notice=0, ratio=240, ratio_start=4741, ratio_end=4980, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 111403, 1) ->
    #ets_box_goods{ id=88, box_id=2, goods_id=111403, goods_num=1, type=0, bind=0, notice=0, ratio=20, ratio_start=4981, ratio_end=5000, lim_career=0, lim_box=0, lim_player=0, lim_num=50 };
get_box_goods(2, 111413, 1) ->
    #ets_box_goods{ id=89, box_id=2, goods_id=111413, goods_num=1, type=0, bind=0, notice=0, ratio=60, ratio_start=5001, ratio_end=5060, lim_career=0, lim_box=0, lim_player=0, lim_num=20 };
get_box_goods(2, 111423, 1) ->
    #ets_box_goods{ id=90, box_id=2, goods_id=111423, goods_num=1, type=0, bind=0, notice=0, ratio=40, ratio_start=5061, ratio_end=5100, lim_career=0, lim_box=0, lim_player=0, lim_num=30 };
get_box_goods(2, 111433, 1) ->
    #ets_box_goods{ id=91, box_id=2, goods_id=111433, goods_num=1, type=0, bind=0, notice=0, ratio=40, ratio_start=5101, ratio_end=5140, lim_career=0, lim_box=0, lim_player=0, lim_num=20 };
get_box_goods(2, 111443, 1) ->
    #ets_box_goods{ id=92, box_id=2, goods_id=111443, goods_num=1, type=0, bind=0, notice=0, ratio=60, ratio_start=5141, ratio_end=5200, lim_career=0, lim_box=0, lim_player=0, lim_num=20 };
get_box_goods(2, 111453, 1) ->
    #ets_box_goods{ id=93, box_id=2, goods_id=111453, goods_num=1, type=0, bind=0, notice=0, ratio=60, ratio_start=5201, ratio_end=5260, lim_career=0, lim_box=0, lim_player=0, lim_num=20 };
get_box_goods(2, 111463, 1) ->
    #ets_box_goods{ id=94, box_id=2, goods_id=111463, goods_num=1, type=0, bind=0, notice=0, ratio=60, ratio_start=5261, ratio_end=5320, lim_career=0, lim_box=0, lim_player=0, lim_num=20 };
get_box_goods(2, 111473, 1) ->
    #ets_box_goods{ id=95, box_id=2, goods_id=111473, goods_num=1, type=0, bind=0, notice=0, ratio=80, ratio_start=5321, ratio_end=5400, lim_career=0, lim_box=0, lim_player=0, lim_num=20 };
get_box_goods(2, 121302, 1) ->
    #ets_box_goods{ id=96, box_id=2, goods_id=121302, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=5401, ratio_end=5700, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 121402, 1) ->
    #ets_box_goods{ id=97, box_id=2, goods_id=121402, goods_num=1, type=0, bind=0, notice=0, ratio=200, ratio_start=5701, ratio_end=5900, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 121702, 1) ->
    #ets_box_goods{ id=98, box_id=2, goods_id=121702, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=5901, ratio_end=6000, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 121001, 1) ->
    #ets_box_goods{ id=99, box_id=2, goods_id=121001, goods_num=1, type=0, bind=0, notice=0, ratio=200, ratio_start=6001, ratio_end=6200, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 121002, 1) ->
    #ets_box_goods{ id=100, box_id=2, goods_id=121002, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=6201, ratio_end=6300, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 121003, 1) ->
    #ets_box_goods{ id=101, box_id=2, goods_id=121003, goods_num=1, type=0, bind=0, notice=0, ratio=50, ratio_start=6301, ratio_end=6350, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 121004, 1) ->
    #ets_box_goods{ id=102, box_id=2, goods_id=121004, goods_num=1, type=0, bind=0, notice=0, ratio=25, ratio_start=6351, ratio_end=6375, lim_career=0, lim_box=0, lim_player=0, lim_num=50 };
get_box_goods(2, 121005, 1) ->
    #ets_box_goods{ id=103, box_id=2, goods_id=121005, goods_num=1, type=0, bind=0, notice=0, ratio=12, ratio_start=6376, ratio_end=6387, lim_career=0, lim_box=0, lim_player=0, lim_num=50 };
get_box_goods(2, 231202, 1) ->
    #ets_box_goods{ id=104, box_id=2, goods_id=231202, goods_num=1, type=0, bind=0, notice=0, ratio=12, ratio_start=6388, ratio_end=6399, lim_career=0, lim_box=0, lim_player=0, lim_num=30 };
get_box_goods(2, 121006, 1) ->
    #ets_box_goods{ id=105, box_id=2, goods_id=121006, goods_num=1, type=0, bind=0, notice=0, ratio=5, ratio_start=6400, ratio_end=6404, lim_career=0, lim_box=0, lim_player=0, lim_num=80 };
get_box_goods(2, 205301, 1) ->
    #ets_box_goods{ id=106, box_id=2, goods_id=205301, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=6405, ratio_end=6504, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 206301, 1) ->
    #ets_box_goods{ id=107, box_id=2, goods_id=206301, goods_num=1, type=0, bind=0, notice=0, ratio=350, ratio_start=6505, ratio_end=6854, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 212102, 1) ->
    #ets_box_goods{ id=108, box_id=2, goods_id=212102, goods_num=1, type=0, bind=0, notice=0, ratio=50, ratio_start=6855, ratio_end=6904, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 212202, 1) ->
    #ets_box_goods{ id=109, box_id=2, goods_id=212202, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=6905, ratio_end=7004, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 212302, 1) ->
    #ets_box_goods{ id=110, box_id=2, goods_id=212302, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=7005, ratio_end=7104, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 221103, 1) ->
    #ets_box_goods{ id=111, box_id=2, goods_id=221103, goods_num=1, type=0, bind=0, notice=0, ratio=500, ratio_start=7105, ratio_end=7604, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 221102, 1) ->
    #ets_box_goods{ id=112, box_id=2, goods_id=221102, goods_num=1, type=0, bind=0, notice=0, ratio=600, ratio_start=7605, ratio_end=8204, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 221002, 1) ->
    #ets_box_goods{ id=113, box_id=2, goods_id=221002, goods_num=1, type=0, bind=0, notice=0, ratio=0, ratio_start=0, ratio_end=0, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 621302, 1) ->
    #ets_box_goods{ id=114, box_id=2, goods_id=621302, goods_num=1, type=0, bind=0, notice=0, ratio=500, ratio_start=8205, ratio_end=8704, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 625001, 1) ->
    #ets_box_goods{ id=115, box_id=2, goods_id=625001, goods_num=1, type=0, bind=0, notice=0, ratio=0, ratio_start=0, ratio_end=0, lim_career=0, lim_box=0, lim_player=0, lim_num=50 };
get_box_goods(2, 623203, 1) ->
    #ets_box_goods{ id=116, box_id=2, goods_id=623203, goods_num=1, type=0, bind=0, notice=0, ratio=0, ratio_start=0, ratio_end=0, lim_career=0, lim_box=0, lim_player=0, lim_num=100 };
get_box_goods(2, 624802, 1) ->
    #ets_box_goods{ id=117, box_id=2, goods_id=624802, goods_num=1, type=0, bind=0, notice=0, ratio=300, ratio_start=8705, ratio_end=9004, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 624801, 1) ->
    #ets_box_goods{ id=118, box_id=2, goods_id=624801, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=9005, ratio_end=9104, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 624201, 1) ->
    #ets_box_goods{ id=119, box_id=2, goods_id=624201, goods_num=1, type=0, bind=0, notice=0, ratio=25, ratio_start=9105, ratio_end=9129, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 624202, 1) ->
    #ets_box_goods{ id=120, box_id=2, goods_id=624202, goods_num=1, type=0, bind=0, notice=0, ratio=250, ratio_start=9130, ratio_end=9379, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 221202, 1) ->
    #ets_box_goods{ id=121, box_id=2, goods_id=221202, goods_num=1, type=0, bind=0, notice=0, ratio=200, ratio_start=9380, ratio_end=9579, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(2, 112105, 1) ->
    #ets_box_goods{ id=122, box_id=2, goods_id=112105, goods_num=1, type=0, bind=0, notice=0, ratio=100, ratio_start=9580, ratio_end=9679, lim_career=0, lim_box=0, lim_player=0, lim_num=50 };
get_box_goods(3, 221102, 1) ->
    #ets_box_goods{ id=123, box_id=3, goods_id=221102, goods_num=1, type=0, bind=0, notice=0, ratio=800, ratio_start=1, ratio_end=800, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(4, 221102, 1) ->
    #ets_box_goods{ id=124, box_id=4, goods_id=221102, goods_num=1, type=0, bind=0, notice=0, ratio=800, ratio_start=1, ratio_end=800, lim_career=0, lim_box=0, lim_player=0, lim_num=0 };
get_box_goods(_BoxId, _GoodsTypeId,_Goodsnum) ->
    [].
