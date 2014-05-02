%%%---------------------------------------
%%% @Module  : data_gemstone
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:32
%%% @Description:  宝石合成，镶嵌
%%%---------------------------------------
-module(data_gemstone).
-compile(export_all).
-include("goods.hrl").

%% 通过宝石ID及数量获取合成数据
get_compose_rule(111401, 2) -> 
	#ets_goods_compose{id=1, goods_id=111401, goods_num=2, ratio=25, new_id=111402, coin=500};
get_compose_rule(111401, 3) -> 
	#ets_goods_compose{id=2, goods_id=111401, goods_num=3, ratio=50, new_id=111402, coin=500};
get_compose_rule(111401, 4) -> 
	#ets_goods_compose{id=3, goods_id=111401, goods_num=4, ratio=75, new_id=111402, coin=500};
get_compose_rule(111402, 2) -> 
	#ets_goods_compose{id=5, goods_id=111402, goods_num=2, ratio=25, new_id=111403, coin=1000};
get_compose_rule(111402, 3) -> 
	#ets_goods_compose{id=6, goods_id=111402, goods_num=3, ratio=50, new_id=111403, coin=1000};
get_compose_rule(111402, 4) -> 
	#ets_goods_compose{id=7, goods_id=111402, goods_num=4, ratio=75, new_id=111403, coin=1000};
get_compose_rule(111403, 2) -> 
	#ets_goods_compose{id=9, goods_id=111403, goods_num=2, ratio=25, new_id=111404, coin=2000};
get_compose_rule(111403, 3) -> 
	#ets_goods_compose{id=10, goods_id=111403, goods_num=3, ratio=50, new_id=111404, coin=2000};
get_compose_rule(111403, 4) -> 
	#ets_goods_compose{id=11, goods_id=111403, goods_num=4, ratio=75, new_id=111404, coin=2000};
get_compose_rule(111404, 2) -> 
	#ets_goods_compose{id=13, goods_id=111404, goods_num=2, ratio=25, new_id=111405, coin=4000};
get_compose_rule(111404, 3) -> 
	#ets_goods_compose{id=14, goods_id=111404, goods_num=3, ratio=50, new_id=111405, coin=4000};
get_compose_rule(111404, 4) -> 
	#ets_goods_compose{id=15, goods_id=111404, goods_num=4, ratio=75, new_id=111405, coin=4000};
get_compose_rule(111405, 2) -> 
	#ets_goods_compose{id=17, goods_id=111405, goods_num=2, ratio=25, new_id=111406, coin=8000};
get_compose_rule(111405, 3) -> 
	#ets_goods_compose{id=18, goods_id=111405, goods_num=3, ratio=50, new_id=111406, coin=8000};
get_compose_rule(111405, 4) -> 
	#ets_goods_compose{id=19, goods_id=111405, goods_num=4, ratio=75, new_id=111406, coin=8000};
get_compose_rule(111406, 2) -> 
	#ets_goods_compose{id=21, goods_id=111406, goods_num=2, ratio=25, new_id=111407, coin=16000};
get_compose_rule(111406, 3) -> 
	#ets_goods_compose{id=22, goods_id=111406, goods_num=3, ratio=50, new_id=111407, coin=16000};
get_compose_rule(111406, 4) -> 
	#ets_goods_compose{id=23, goods_id=111406, goods_num=4, ratio=75, new_id=111407, coin=16000};
get_compose_rule(111407, 2) -> 
	#ets_goods_compose{id=25, goods_id=111407, goods_num=2, ratio=25, new_id=111408, coin=32000};
get_compose_rule(111407, 3) -> 
	#ets_goods_compose{id=26, goods_id=111407, goods_num=3, ratio=50, new_id=111408, coin=32000};
get_compose_rule(111407, 4) -> 
	#ets_goods_compose{id=27, goods_id=111407, goods_num=4, ratio=75, new_id=111408, coin=32000};
get_compose_rule(111408, 2) -> 
	#ets_goods_compose{id=29, goods_id=111408, goods_num=2, ratio=25, new_id=111409, coin=64000};
get_compose_rule(111408, 3) -> 
	#ets_goods_compose{id=30, goods_id=111408, goods_num=3, ratio=50, new_id=111409, coin=64000};
get_compose_rule(111408, 4) -> 
	#ets_goods_compose{id=31, goods_id=111408, goods_num=4, ratio=75, new_id=111409, coin=64000};
get_compose_rule(111411, 2) -> 
	#ets_goods_compose{id=37, goods_id=111411, goods_num=2, ratio=25, new_id=111412, coin=500};
get_compose_rule(111411, 3) -> 
	#ets_goods_compose{id=38, goods_id=111411, goods_num=3, ratio=50, new_id=111412, coin=500};
get_compose_rule(111411, 4) -> 
	#ets_goods_compose{id=39, goods_id=111411, goods_num=4, ratio=75, new_id=111412, coin=500};
get_compose_rule(111412, 2) -> 
	#ets_goods_compose{id=41, goods_id=111412, goods_num=2, ratio=25, new_id=111413, coin=1000};
get_compose_rule(111412, 3) -> 
	#ets_goods_compose{id=42, goods_id=111412, goods_num=3, ratio=50, new_id=111413, coin=1000};
get_compose_rule(111412, 4) -> 
	#ets_goods_compose{id=43, goods_id=111412, goods_num=4, ratio=75, new_id=111413, coin=1000};
get_compose_rule(111413, 2) -> 
	#ets_goods_compose{id=45, goods_id=111413, goods_num=2, ratio=25, new_id=111414, coin=2000};
get_compose_rule(111413, 3) -> 
	#ets_goods_compose{id=46, goods_id=111413, goods_num=3, ratio=50, new_id=111414, coin=2000};
get_compose_rule(111413, 4) -> 
	#ets_goods_compose{id=47, goods_id=111413, goods_num=4, ratio=75, new_id=111414, coin=2000};
get_compose_rule(111414, 2) -> 
	#ets_goods_compose{id=49, goods_id=111414, goods_num=2, ratio=25, new_id=111415, coin=4000};
get_compose_rule(111414, 3) -> 
	#ets_goods_compose{id=50, goods_id=111414, goods_num=3, ratio=50, new_id=111415, coin=4000};
get_compose_rule(111414, 4) -> 
	#ets_goods_compose{id=51, goods_id=111414, goods_num=4, ratio=75, new_id=111415, coin=4000};
get_compose_rule(111415, 2) -> 
	#ets_goods_compose{id=53, goods_id=111415, goods_num=2, ratio=25, new_id=111416, coin=8000};
get_compose_rule(111415, 3) -> 
	#ets_goods_compose{id=54, goods_id=111415, goods_num=3, ratio=50, new_id=111416, coin=8000};
get_compose_rule(111415, 4) -> 
	#ets_goods_compose{id=55, goods_id=111415, goods_num=4, ratio=75, new_id=111416, coin=8000};
get_compose_rule(111416, 2) -> 
	#ets_goods_compose{id=57, goods_id=111416, goods_num=2, ratio=25, new_id=111417, coin=16000};
get_compose_rule(111416, 3) -> 
	#ets_goods_compose{id=58, goods_id=111416, goods_num=3, ratio=50, new_id=111417, coin=16000};
get_compose_rule(111416, 4) -> 
	#ets_goods_compose{id=59, goods_id=111416, goods_num=4, ratio=75, new_id=111417, coin=16000};
get_compose_rule(111417, 2) -> 
	#ets_goods_compose{id=61, goods_id=111417, goods_num=2, ratio=25, new_id=111418, coin=32000};
get_compose_rule(111417, 3) -> 
	#ets_goods_compose{id=62, goods_id=111417, goods_num=3, ratio=50, new_id=111418, coin=32000};
get_compose_rule(111417, 4) -> 
	#ets_goods_compose{id=63, goods_id=111417, goods_num=4, ratio=75, new_id=111418, coin=32000};
get_compose_rule(111418, 2) -> 
	#ets_goods_compose{id=65, goods_id=111418, goods_num=2, ratio=25, new_id=111419, coin=64000};
get_compose_rule(111418, 3) -> 
	#ets_goods_compose{id=66, goods_id=111418, goods_num=3, ratio=50, new_id=111419, coin=64000};
get_compose_rule(111418, 4) -> 
	#ets_goods_compose{id=67, goods_id=111418, goods_num=4, ratio=75, new_id=111419, coin=64000};
get_compose_rule(111421, 2) -> 
	#ets_goods_compose{id=73, goods_id=111421, goods_num=2, ratio=25, new_id=111422, coin=500};
get_compose_rule(111421, 3) -> 
	#ets_goods_compose{id=74, goods_id=111421, goods_num=3, ratio=50, new_id=111422, coin=500};
get_compose_rule(111421, 4) -> 
	#ets_goods_compose{id=75, goods_id=111421, goods_num=4, ratio=75, new_id=111422, coin=500};
get_compose_rule(111422, 2) -> 
	#ets_goods_compose{id=77, goods_id=111422, goods_num=2, ratio=25, new_id=111423, coin=1000};
get_compose_rule(111422, 3) -> 
	#ets_goods_compose{id=78, goods_id=111422, goods_num=3, ratio=50, new_id=111423, coin=1000};
get_compose_rule(111422, 4) -> 
	#ets_goods_compose{id=79, goods_id=111422, goods_num=4, ratio=75, new_id=111423, coin=1000};
get_compose_rule(111423, 2) -> 
	#ets_goods_compose{id=81, goods_id=111423, goods_num=2, ratio=25, new_id=111424, coin=2000};
get_compose_rule(111423, 3) -> 
	#ets_goods_compose{id=82, goods_id=111423, goods_num=3, ratio=50, new_id=111424, coin=2000};
get_compose_rule(111423, 4) -> 
	#ets_goods_compose{id=83, goods_id=111423, goods_num=4, ratio=75, new_id=111424, coin=2000};
get_compose_rule(111424, 2) -> 
	#ets_goods_compose{id=85, goods_id=111424, goods_num=2, ratio=25, new_id=111425, coin=4000};
get_compose_rule(111424, 3) -> 
	#ets_goods_compose{id=86, goods_id=111424, goods_num=3, ratio=50, new_id=111425, coin=4000};
get_compose_rule(111424, 4) -> 
	#ets_goods_compose{id=87, goods_id=111424, goods_num=4, ratio=75, new_id=111425, coin=4000};
get_compose_rule(111425, 2) -> 
	#ets_goods_compose{id=89, goods_id=111425, goods_num=2, ratio=25, new_id=111426, coin=8000};
get_compose_rule(111425, 3) -> 
	#ets_goods_compose{id=90, goods_id=111425, goods_num=3, ratio=50, new_id=111426, coin=8000};
get_compose_rule(111425, 4) -> 
	#ets_goods_compose{id=91, goods_id=111425, goods_num=4, ratio=75, new_id=111426, coin=8000};
get_compose_rule(111426, 2) -> 
	#ets_goods_compose{id=93, goods_id=111426, goods_num=2, ratio=25, new_id=111427, coin=16000};
get_compose_rule(111426, 3) -> 
	#ets_goods_compose{id=94, goods_id=111426, goods_num=3, ratio=50, new_id=111427, coin=16000};
get_compose_rule(111426, 4) -> 
	#ets_goods_compose{id=95, goods_id=111426, goods_num=4, ratio=75, new_id=111427, coin=16000};
get_compose_rule(111427, 2) -> 
	#ets_goods_compose{id=97, goods_id=111427, goods_num=2, ratio=25, new_id=111428, coin=32000};
get_compose_rule(111427, 3) -> 
	#ets_goods_compose{id=98, goods_id=111427, goods_num=3, ratio=50, new_id=111428, coin=32000};
get_compose_rule(111427, 4) -> 
	#ets_goods_compose{id=99, goods_id=111427, goods_num=4, ratio=75, new_id=111428, coin=32000};
get_compose_rule(111428, 2) -> 
	#ets_goods_compose{id=101, goods_id=111428, goods_num=2, ratio=25, new_id=111429, coin=64000};
get_compose_rule(111428, 3) -> 
	#ets_goods_compose{id=102, goods_id=111428, goods_num=3, ratio=50, new_id=111429, coin=64000};
get_compose_rule(111428, 4) -> 
	#ets_goods_compose{id=103, goods_id=111428, goods_num=4, ratio=75, new_id=111429, coin=64000};
get_compose_rule(111431, 2) -> 
	#ets_goods_compose{id=109, goods_id=111431, goods_num=2, ratio=25, new_id=111432, coin=500};
get_compose_rule(111431, 3) -> 
	#ets_goods_compose{id=110, goods_id=111431, goods_num=3, ratio=50, new_id=111432, coin=500};
get_compose_rule(111431, 4) -> 
	#ets_goods_compose{id=111, goods_id=111431, goods_num=4, ratio=75, new_id=111432, coin=500};
get_compose_rule(111432, 2) -> 
	#ets_goods_compose{id=113, goods_id=111432, goods_num=2, ratio=25, new_id=111433, coin=1000};
get_compose_rule(111432, 3) -> 
	#ets_goods_compose{id=114, goods_id=111432, goods_num=3, ratio=50, new_id=111433, coin=1000};
get_compose_rule(111432, 4) -> 
	#ets_goods_compose{id=115, goods_id=111432, goods_num=4, ratio=75, new_id=111433, coin=1000};
get_compose_rule(111433, 2) -> 
	#ets_goods_compose{id=117, goods_id=111433, goods_num=2, ratio=25, new_id=111434, coin=2000};
get_compose_rule(111433, 3) -> 
	#ets_goods_compose{id=118, goods_id=111433, goods_num=3, ratio=50, new_id=111434, coin=2000};
get_compose_rule(111433, 4) -> 
	#ets_goods_compose{id=119, goods_id=111433, goods_num=4, ratio=75, new_id=111434, coin=2000};
get_compose_rule(111434, 2) -> 
	#ets_goods_compose{id=121, goods_id=111434, goods_num=2, ratio=25, new_id=111435, coin=4000};
get_compose_rule(111434, 3) -> 
	#ets_goods_compose{id=122, goods_id=111434, goods_num=3, ratio=50, new_id=111435, coin=4000};
get_compose_rule(111434, 4) -> 
	#ets_goods_compose{id=123, goods_id=111434, goods_num=4, ratio=75, new_id=111435, coin=4000};
get_compose_rule(111435, 2) -> 
	#ets_goods_compose{id=125, goods_id=111435, goods_num=2, ratio=25, new_id=111436, coin=8000};
get_compose_rule(111435, 3) -> 
	#ets_goods_compose{id=126, goods_id=111435, goods_num=3, ratio=50, new_id=111436, coin=8000};
get_compose_rule(111435, 4) -> 
	#ets_goods_compose{id=127, goods_id=111435, goods_num=4, ratio=75, new_id=111436, coin=8000};
get_compose_rule(111436, 2) -> 
	#ets_goods_compose{id=129, goods_id=111436, goods_num=2, ratio=25, new_id=111437, coin=16000};
get_compose_rule(111436, 3) -> 
	#ets_goods_compose{id=130, goods_id=111436, goods_num=3, ratio=50, new_id=111437, coin=16000};
get_compose_rule(111436, 4) -> 
	#ets_goods_compose{id=131, goods_id=111436, goods_num=4, ratio=75, new_id=111437, coin=16000};
get_compose_rule(111437, 2) -> 
	#ets_goods_compose{id=133, goods_id=111437, goods_num=2, ratio=25, new_id=111438, coin=32000};
get_compose_rule(111437, 3) -> 
	#ets_goods_compose{id=134, goods_id=111437, goods_num=3, ratio=50, new_id=111438, coin=32000};
get_compose_rule(111437, 4) -> 
	#ets_goods_compose{id=135, goods_id=111437, goods_num=4, ratio=75, new_id=111438, coin=32000};
get_compose_rule(111438, 2) -> 
	#ets_goods_compose{id=137, goods_id=111438, goods_num=2, ratio=25, new_id=111439, coin=64000};
get_compose_rule(111438, 3) -> 
	#ets_goods_compose{id=138, goods_id=111438, goods_num=3, ratio=50, new_id=111439, coin=64000};
get_compose_rule(111438, 4) -> 
	#ets_goods_compose{id=139, goods_id=111438, goods_num=4, ratio=75, new_id=111439, coin=64000};
get_compose_rule(111441, 2) -> 
	#ets_goods_compose{id=145, goods_id=111441, goods_num=2, ratio=25, new_id=111442, coin=500};
get_compose_rule(111441, 3) -> 
	#ets_goods_compose{id=146, goods_id=111441, goods_num=3, ratio=50, new_id=111442, coin=500};
get_compose_rule(111441, 4) -> 
	#ets_goods_compose{id=147, goods_id=111441, goods_num=4, ratio=75, new_id=111442, coin=500};
get_compose_rule(111442, 2) -> 
	#ets_goods_compose{id=149, goods_id=111442, goods_num=2, ratio=25, new_id=111443, coin=1000};
get_compose_rule(111442, 3) -> 
	#ets_goods_compose{id=150, goods_id=111442, goods_num=3, ratio=50, new_id=111443, coin=1000};
get_compose_rule(111442, 4) -> 
	#ets_goods_compose{id=151, goods_id=111442, goods_num=4, ratio=75, new_id=111443, coin=1000};
get_compose_rule(111443, 2) -> 
	#ets_goods_compose{id=153, goods_id=111443, goods_num=2, ratio=25, new_id=111444, coin=2000};
get_compose_rule(111443, 3) -> 
	#ets_goods_compose{id=154, goods_id=111443, goods_num=3, ratio=50, new_id=111444, coin=2000};
get_compose_rule(111443, 4) -> 
	#ets_goods_compose{id=155, goods_id=111443, goods_num=4, ratio=75, new_id=111444, coin=2000};
get_compose_rule(111444, 2) -> 
	#ets_goods_compose{id=157, goods_id=111444, goods_num=2, ratio=25, new_id=111445, coin=4000};
get_compose_rule(111444, 3) -> 
	#ets_goods_compose{id=158, goods_id=111444, goods_num=3, ratio=50, new_id=111445, coin=4000};
get_compose_rule(111444, 4) -> 
	#ets_goods_compose{id=159, goods_id=111444, goods_num=4, ratio=75, new_id=111445, coin=4000};
get_compose_rule(111445, 2) -> 
	#ets_goods_compose{id=161, goods_id=111445, goods_num=2, ratio=25, new_id=111446, coin=8000};
get_compose_rule(111445, 3) -> 
	#ets_goods_compose{id=162, goods_id=111445, goods_num=3, ratio=50, new_id=111446, coin=8000};
get_compose_rule(111445, 4) -> 
	#ets_goods_compose{id=163, goods_id=111445, goods_num=4, ratio=75, new_id=111446, coin=8000};
get_compose_rule(111446, 2) -> 
	#ets_goods_compose{id=165, goods_id=111446, goods_num=2, ratio=25, new_id=111447, coin=16000};
get_compose_rule(111446, 3) -> 
	#ets_goods_compose{id=166, goods_id=111446, goods_num=3, ratio=50, new_id=111447, coin=16000};
get_compose_rule(111446, 4) -> 
	#ets_goods_compose{id=167, goods_id=111446, goods_num=4, ratio=75, new_id=111447, coin=16000};
get_compose_rule(111447, 2) -> 
	#ets_goods_compose{id=169, goods_id=111447, goods_num=2, ratio=25, new_id=111448, coin=32000};
get_compose_rule(111447, 3) -> 
	#ets_goods_compose{id=170, goods_id=111447, goods_num=3, ratio=50, new_id=111448, coin=32000};
get_compose_rule(111447, 4) -> 
	#ets_goods_compose{id=171, goods_id=111447, goods_num=4, ratio=75, new_id=111448, coin=32000};
get_compose_rule(111448, 2) -> 
	#ets_goods_compose{id=173, goods_id=111448, goods_num=2, ratio=25, new_id=111449, coin=64000};
get_compose_rule(111448, 3) -> 
	#ets_goods_compose{id=174, goods_id=111448, goods_num=3, ratio=50, new_id=111449, coin=64000};
get_compose_rule(111448, 4) -> 
	#ets_goods_compose{id=175, goods_id=111448, goods_num=4, ratio=75, new_id=111449, coin=64000};
get_compose_rule(111451, 2) -> 
	#ets_goods_compose{id=181, goods_id=111451, goods_num=2, ratio=25, new_id=111452, coin=500};
get_compose_rule(111451, 3) -> 
	#ets_goods_compose{id=182, goods_id=111451, goods_num=3, ratio=50, new_id=111452, coin=500};
get_compose_rule(111451, 4) -> 
	#ets_goods_compose{id=183, goods_id=111451, goods_num=4, ratio=75, new_id=111452, coin=500};
get_compose_rule(111452, 2) -> 
	#ets_goods_compose{id=185, goods_id=111452, goods_num=2, ratio=25, new_id=111453, coin=1000};
get_compose_rule(111452, 3) -> 
	#ets_goods_compose{id=186, goods_id=111452, goods_num=3, ratio=50, new_id=111453, coin=1000};
get_compose_rule(111452, 4) -> 
	#ets_goods_compose{id=187, goods_id=111452, goods_num=4, ratio=75, new_id=111453, coin=1000};
get_compose_rule(111453, 2) -> 
	#ets_goods_compose{id=189, goods_id=111453, goods_num=2, ratio=25, new_id=111454, coin=2000};
get_compose_rule(111453, 3) -> 
	#ets_goods_compose{id=190, goods_id=111453, goods_num=3, ratio=50, new_id=111454, coin=2000};
get_compose_rule(111453, 4) -> 
	#ets_goods_compose{id=191, goods_id=111453, goods_num=4, ratio=75, new_id=111454, coin=2000};
get_compose_rule(111454, 2) -> 
	#ets_goods_compose{id=193, goods_id=111454, goods_num=2, ratio=25, new_id=111455, coin=4000};
get_compose_rule(111454, 3) -> 
	#ets_goods_compose{id=194, goods_id=111454, goods_num=3, ratio=50, new_id=111455, coin=4000};
get_compose_rule(111454, 4) -> 
	#ets_goods_compose{id=195, goods_id=111454, goods_num=4, ratio=75, new_id=111455, coin=4000};
get_compose_rule(111455, 2) -> 
	#ets_goods_compose{id=197, goods_id=111455, goods_num=2, ratio=25, new_id=111456, coin=8000};
get_compose_rule(111455, 3) -> 
	#ets_goods_compose{id=198, goods_id=111455, goods_num=3, ratio=50, new_id=111456, coin=8000};
get_compose_rule(111455, 4) -> 
	#ets_goods_compose{id=199, goods_id=111455, goods_num=4, ratio=75, new_id=111456, coin=8000};
get_compose_rule(111456, 2) -> 
	#ets_goods_compose{id=201, goods_id=111456, goods_num=2, ratio=25, new_id=111457, coin=16000};
get_compose_rule(111456, 3) -> 
	#ets_goods_compose{id=202, goods_id=111456, goods_num=3, ratio=50, new_id=111457, coin=16000};
get_compose_rule(111456, 4) -> 
	#ets_goods_compose{id=203, goods_id=111456, goods_num=4, ratio=75, new_id=111457, coin=16000};
get_compose_rule(111457, 2) -> 
	#ets_goods_compose{id=205, goods_id=111457, goods_num=2, ratio=25, new_id=111458, coin=32000};
get_compose_rule(111457, 3) -> 
	#ets_goods_compose{id=206, goods_id=111457, goods_num=3, ratio=50, new_id=111458, coin=32000};
get_compose_rule(111457, 4) -> 
	#ets_goods_compose{id=207, goods_id=111457, goods_num=4, ratio=75, new_id=111458, coin=32000};
get_compose_rule(111458, 2) -> 
	#ets_goods_compose{id=209, goods_id=111458, goods_num=2, ratio=25, new_id=111459, coin=64000};
get_compose_rule(111458, 3) -> 
	#ets_goods_compose{id=210, goods_id=111458, goods_num=3, ratio=50, new_id=111459, coin=64000};
get_compose_rule(111458, 4) -> 
	#ets_goods_compose{id=211, goods_id=111458, goods_num=4, ratio=75, new_id=111459, coin=64000};
get_compose_rule(111461, 2) -> 
	#ets_goods_compose{id=217, goods_id=111461, goods_num=2, ratio=25, new_id=111462, coin=500};
get_compose_rule(111461, 3) -> 
	#ets_goods_compose{id=218, goods_id=111461, goods_num=3, ratio=50, new_id=111462, coin=500};
get_compose_rule(111461, 4) -> 
	#ets_goods_compose{id=219, goods_id=111461, goods_num=4, ratio=75, new_id=111462, coin=500};
get_compose_rule(111462, 2) -> 
	#ets_goods_compose{id=221, goods_id=111462, goods_num=2, ratio=25, new_id=111463, coin=1000};
get_compose_rule(111462, 3) -> 
	#ets_goods_compose{id=222, goods_id=111462, goods_num=3, ratio=50, new_id=111463, coin=1000};
get_compose_rule(111462, 4) -> 
	#ets_goods_compose{id=223, goods_id=111462, goods_num=4, ratio=75, new_id=111463, coin=1000};
get_compose_rule(111463, 2) -> 
	#ets_goods_compose{id=225, goods_id=111463, goods_num=2, ratio=25, new_id=111464, coin=2000};
get_compose_rule(111463, 3) -> 
	#ets_goods_compose{id=226, goods_id=111463, goods_num=3, ratio=50, new_id=111464, coin=2000};
get_compose_rule(111463, 4) -> 
	#ets_goods_compose{id=227, goods_id=111463, goods_num=4, ratio=75, new_id=111464, coin=2000};
get_compose_rule(111464, 2) -> 
	#ets_goods_compose{id=229, goods_id=111464, goods_num=2, ratio=25, new_id=111465, coin=4000};
get_compose_rule(111464, 3) -> 
	#ets_goods_compose{id=230, goods_id=111464, goods_num=3, ratio=50, new_id=111465, coin=4000};
get_compose_rule(111464, 4) -> 
	#ets_goods_compose{id=231, goods_id=111464, goods_num=4, ratio=75, new_id=111465, coin=4000};
get_compose_rule(111465, 2) -> 
	#ets_goods_compose{id=233, goods_id=111465, goods_num=2, ratio=25, new_id=111466, coin=8000};
get_compose_rule(111465, 3) -> 
	#ets_goods_compose{id=234, goods_id=111465, goods_num=3, ratio=50, new_id=111466, coin=8000};
get_compose_rule(111465, 4) -> 
	#ets_goods_compose{id=235, goods_id=111465, goods_num=4, ratio=75, new_id=111466, coin=8000};
get_compose_rule(111466, 2) -> 
	#ets_goods_compose{id=237, goods_id=111466, goods_num=2, ratio=25, new_id=111467, coin=16000};
get_compose_rule(111466, 3) -> 
	#ets_goods_compose{id=238, goods_id=111466, goods_num=3, ratio=50, new_id=111467, coin=16000};
get_compose_rule(111466, 4) -> 
	#ets_goods_compose{id=239, goods_id=111466, goods_num=4, ratio=75, new_id=111467, coin=16000};
get_compose_rule(111467, 2) -> 
	#ets_goods_compose{id=241, goods_id=111467, goods_num=2, ratio=25, new_id=111468, coin=32000};
get_compose_rule(111467, 3) -> 
	#ets_goods_compose{id=242, goods_id=111467, goods_num=3, ratio=50, new_id=111468, coin=32000};
get_compose_rule(111467, 4) -> 
	#ets_goods_compose{id=243, goods_id=111467, goods_num=4, ratio=75, new_id=111468, coin=32000};
get_compose_rule(111468, 2) -> 
	#ets_goods_compose{id=245, goods_id=111468, goods_num=2, ratio=25, new_id=111469, coin=64000};
get_compose_rule(111468, 3) -> 
	#ets_goods_compose{id=246, goods_id=111468, goods_num=3, ratio=50, new_id=111469, coin=64000};
get_compose_rule(111468, 4) -> 
	#ets_goods_compose{id=247, goods_id=111468, goods_num=4, ratio=75, new_id=111469, coin=64000};
get_compose_rule(111471, 2) -> 
	#ets_goods_compose{id=253, goods_id=111471, goods_num=2, ratio=25, new_id=111472, coin=500};
get_compose_rule(111471, 3) -> 
	#ets_goods_compose{id=254, goods_id=111471, goods_num=3, ratio=50, new_id=111472, coin=500};
get_compose_rule(111471, 4) -> 
	#ets_goods_compose{id=255, goods_id=111471, goods_num=4, ratio=75, new_id=111472, coin=500};
get_compose_rule(111472, 2) -> 
	#ets_goods_compose{id=257, goods_id=111472, goods_num=2, ratio=25, new_id=111473, coin=1000};
get_compose_rule(111472, 3) -> 
	#ets_goods_compose{id=258, goods_id=111472, goods_num=3, ratio=50, new_id=111473, coin=1000};
get_compose_rule(111472, 4) -> 
	#ets_goods_compose{id=259, goods_id=111472, goods_num=4, ratio=75, new_id=111473, coin=1000};
get_compose_rule(111473, 2) -> 
	#ets_goods_compose{id=261, goods_id=111473, goods_num=2, ratio=25, new_id=111474, coin=2000};
get_compose_rule(111473, 3) -> 
	#ets_goods_compose{id=262, goods_id=111473, goods_num=3, ratio=50, new_id=111474, coin=2000};
get_compose_rule(111473, 4) -> 
	#ets_goods_compose{id=263, goods_id=111473, goods_num=4, ratio=75, new_id=111474, coin=2000};
get_compose_rule(111474, 2) -> 
	#ets_goods_compose{id=265, goods_id=111474, goods_num=2, ratio=25, new_id=111475, coin=4000};
get_compose_rule(111474, 3) -> 
	#ets_goods_compose{id=266, goods_id=111474, goods_num=3, ratio=50, new_id=111475, coin=4000};
get_compose_rule(111474, 4) -> 
	#ets_goods_compose{id=267, goods_id=111474, goods_num=4, ratio=75, new_id=111475, coin=4000};
get_compose_rule(111475, 2) -> 
	#ets_goods_compose{id=269, goods_id=111475, goods_num=2, ratio=25, new_id=111476, coin=8000};
get_compose_rule(111475, 3) -> 
	#ets_goods_compose{id=270, goods_id=111475, goods_num=3, ratio=50, new_id=111476, coin=8000};
get_compose_rule(111475, 4) -> 
	#ets_goods_compose{id=271, goods_id=111475, goods_num=4, ratio=75, new_id=111476, coin=8000};
get_compose_rule(111476, 2) -> 
	#ets_goods_compose{id=273, goods_id=111476, goods_num=2, ratio=25, new_id=111477, coin=16000};
get_compose_rule(111476, 3) -> 
	#ets_goods_compose{id=274, goods_id=111476, goods_num=3, ratio=50, new_id=111477, coin=16000};
get_compose_rule(111476, 4) -> 
	#ets_goods_compose{id=275, goods_id=111476, goods_num=4, ratio=75, new_id=111477, coin=16000};
get_compose_rule(111477, 2) -> 
	#ets_goods_compose{id=277, goods_id=111477, goods_num=2, ratio=25, new_id=111478, coin=32000};
get_compose_rule(111477, 3) -> 
	#ets_goods_compose{id=278, goods_id=111477, goods_num=3, ratio=50, new_id=111478, coin=32000};
get_compose_rule(111477, 4) -> 
	#ets_goods_compose{id=279, goods_id=111477, goods_num=4, ratio=75, new_id=111478, coin=32000};
get_compose_rule(111478, 2) -> 
	#ets_goods_compose{id=281, goods_id=111478, goods_num=2, ratio=25, new_id=111479, coin=64000};
get_compose_rule(111478, 3) -> 
	#ets_goods_compose{id=282, goods_id=111478, goods_num=3, ratio=50, new_id=111479, coin=64000};
get_compose_rule(111478, 4) -> 
	#ets_goods_compose{id=283, goods_id=111478, goods_num=4, ratio=75, new_id=111479, coin=64000};
get_compose_rule(_, _) ->
	[].

%% 通过宝石ID获取镶嵌数据
get_inlay_rule(111411) -> 
	#ets_goods_inlay{id=1, goods_id=111411, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111412) -> 
	#ets_goods_inlay{id=2, goods_id=111412, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111419) -> 
	#ets_goods_inlay{id=4, goods_id=111419, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111413) -> 
	#ets_goods_inlay{id=5, goods_id=111413, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111414) -> 
	#ets_goods_inlay{id=6, goods_id=111414, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111415) -> 
	#ets_goods_inlay{id=7, goods_id=111415, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111416) -> 
	#ets_goods_inlay{id=8, goods_id=111416, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111417) -> 
	#ets_goods_inlay{id=9, goods_id=111417, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111418) -> 
	#ets_goods_inlay{id=10, goods_id=111418, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111421) -> 
	#ets_goods_inlay{id=12, goods_id=111421, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111422) -> 
	#ets_goods_inlay{id=13, goods_id=111422, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111423) -> 
	#ets_goods_inlay{id=14, goods_id=111423, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111424) -> 
	#ets_goods_inlay{id=15, goods_id=111424, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111425) -> 
	#ets_goods_inlay{id=16, goods_id=111425, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111426) -> 
	#ets_goods_inlay{id=17, goods_id=111426, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111427) -> 
	#ets_goods_inlay{id=18, goods_id=111427, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111428) -> 
	#ets_goods_inlay{id=19, goods_id=111428, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111429) -> 
	#ets_goods_inlay{id=20, goods_id=111429, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111431) -> 
	#ets_goods_inlay{id=23, goods_id=111431, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111432) -> 
	#ets_goods_inlay{id=24, goods_id=111432, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111433) -> 
	#ets_goods_inlay{id=25, goods_id=111433, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111434) -> 
	#ets_goods_inlay{id=26, goods_id=111434, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111435) -> 
	#ets_goods_inlay{id=27, goods_id=111435, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111436) -> 
	#ets_goods_inlay{id=28, goods_id=111436, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111437) -> 
	#ets_goods_inlay{id=29, goods_id=111437, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111438) -> 
	#ets_goods_inlay{id=30, goods_id=111438, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111439) -> 
	#ets_goods_inlay{id=31, goods_id=111439, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111441) -> 
	#ets_goods_inlay{id=33, goods_id=111441, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111442) -> 
	#ets_goods_inlay{id=34, goods_id=111442, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111443) -> 
	#ets_goods_inlay{id=35, goods_id=111443, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111444) -> 
	#ets_goods_inlay{id=36, goods_id=111444, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111445) -> 
	#ets_goods_inlay{id=37, goods_id=111445, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111446) -> 
	#ets_goods_inlay{id=38, goods_id=111446, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111447) -> 
	#ets_goods_inlay{id=39, goods_id=111447, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111448) -> 
	#ets_goods_inlay{id=40, goods_id=111448, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111449) -> 
	#ets_goods_inlay{id=41, goods_id=111449, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111451) -> 
	#ets_goods_inlay{id=43, goods_id=111451, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111452) -> 
	#ets_goods_inlay{id=44, goods_id=111452, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111453) -> 
	#ets_goods_inlay{id=45, goods_id=111453, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111454) -> 
	#ets_goods_inlay{id=46, goods_id=111454, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111455) -> 
	#ets_goods_inlay{id=47, goods_id=111455, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111456) -> 
	#ets_goods_inlay{id=48, goods_id=111456, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111457) -> 
	#ets_goods_inlay{id=49, goods_id=111457, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111458) -> 
	#ets_goods_inlay{id=50, goods_id=111458, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111459) -> 
	#ets_goods_inlay{id=51, goods_id=111459, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111461) -> 
	#ets_goods_inlay{id=53, goods_id=111461, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111462) -> 
	#ets_goods_inlay{id=54, goods_id=111462, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111463) -> 
	#ets_goods_inlay{id=55, goods_id=111463, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111464) -> 
	#ets_goods_inlay{id=56, goods_id=111464, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111465) -> 
	#ets_goods_inlay{id=57, goods_id=111465, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111466) -> 
	#ets_goods_inlay{id=58, goods_id=111466, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111467) -> 
	#ets_goods_inlay{id=59, goods_id=111467, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111468) -> 
	#ets_goods_inlay{id=60, goods_id=111468, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111469) -> 
	#ets_goods_inlay{id=61, goods_id=111469, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111471) -> 
	#ets_goods_inlay{id=63, goods_id=111471, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111472) -> 
	#ets_goods_inlay{id=64, goods_id=111472, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111473) -> 
	#ets_goods_inlay{id=65, goods_id=111473, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111474) -> 
	#ets_goods_inlay{id=66, goods_id=111474, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111475) -> 
	#ets_goods_inlay{id=67, goods_id=111475, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111476) -> 
	#ets_goods_inlay{id=68, goods_id=111476, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111477) -> 
	#ets_goods_inlay{id=69, goods_id=111477, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111478) -> 
	#ets_goods_inlay{id=70, goods_id=111478, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111479) -> 
	#ets_goods_inlay{id=71, goods_id=111479, coin=1000, equip_types=[20,21,22,23,24,25,30]};
get_inlay_rule(111409) -> 
	#ets_goods_inlay{id=83, goods_id=111409, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111408) -> 
	#ets_goods_inlay{id=84, goods_id=111408, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111407) -> 
	#ets_goods_inlay{id=85, goods_id=111407, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111406) -> 
	#ets_goods_inlay{id=86, goods_id=111406, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111405) -> 
	#ets_goods_inlay{id=87, goods_id=111405, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111404) -> 
	#ets_goods_inlay{id=88, goods_id=111404, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111403) -> 
	#ets_goods_inlay{id=89, goods_id=111403, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111402) -> 
	#ets_goods_inlay{id=90, goods_id=111402, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(111401) -> 
	#ets_goods_inlay{id=91, goods_id=111401, coin=1000, equip_types=[10,33,32]};
get_inlay_rule(_) ->
	[].

