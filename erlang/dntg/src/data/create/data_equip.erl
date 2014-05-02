%%%---------------------------------------
%%% @Module  : data_equip
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:32
%%% @Description:  装备强化规则
%%%---------------------------------------
-module(data_equip).
-compile(export_all).
-include("goods.hrl").

%%通过装备类型和强化等级获取记录

get_strengthen(1, 1) -> 
	#ets_goods_strengthen{id=10001,type=1,strengthen=1,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=857,is_upgrade=0,fail_num=0};
get_strengthen(1, 2) -> 
	#ets_goods_strengthen{id=10002,type=1,strengthen=2,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1028,is_upgrade=0,fail_num=0};
get_strengthen(1, 3) -> 
	#ets_goods_strengthen{id=10003,type=1,strengthen=3,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1200,is_upgrade=0,fail_num=0};
get_strengthen(1, 4) -> 
	#ets_goods_strengthen{id=10004,type=1,strengthen=4,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1371,is_upgrade=0,fail_num=0};
get_strengthen(1, 5) -> 
	#ets_goods_strengthen{id=10005,type=1,strengthen=5,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1543,is_upgrade=0,fail_num=0};
get_strengthen(1, 6) -> 
	#ets_goods_strengthen{id=10006,type=1,strengthen=6,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1714,is_upgrade=0,fail_num=0};
get_strengthen(1, 7) -> 
	#ets_goods_strengthen{id=10007,type=1,strengthen=7,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1885,is_upgrade=0,fail_num=0};
get_strengthen(1, 8) -> 
	#ets_goods_strengthen{id=10008,type=1,strengthen=8,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=2057,is_upgrade=0,fail_num=0};
get_strengthen(1, 9) -> 
	#ets_goods_strengthen{id=10009,type=1,strengthen=9,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=2228,is_upgrade=0,fail_num=0};
get_strengthen(1, 10) -> 
	#ets_goods_strengthen{id=10010,type=1,strengthen=10,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=2399,is_upgrade=1,fail_num=0};
get_strengthen(1, 11) -> 
	#ets_goods_strengthen{id=10011,type=1,strengthen=11,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=5142,is_upgrade=0,fail_num=0};
get_strengthen(1, 12) -> 
	#ets_goods_strengthen{id=10012,type=1,strengthen=12,sratio=[9800,9800,9800,9800,9800],cratio=98,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=5399,is_upgrade=0,fail_num=0};
get_strengthen(1, 13) -> 
	#ets_goods_strengthen{id=10013,type=1,strengthen=13,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=5656,is_upgrade=0,fail_num=0};
get_strengthen(1, 14) -> 
	#ets_goods_strengthen{id=10014,type=1,strengthen=14,sratio=[9400,9400,9400,9400,9400],cratio=94,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=5913,is_upgrade=0,fail_num=0};
get_strengthen(1, 15) -> 
	#ets_goods_strengthen{id=10015,type=1,strengthen=15,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=6170,is_upgrade=0,fail_num=0};
get_strengthen(1, 16) -> 
	#ets_goods_strengthen{id=10016,type=1,strengthen=16,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=6427,is_upgrade=0,fail_num=0};
get_strengthen(1, 17) -> 
	#ets_goods_strengthen{id=10017,type=1,strengthen=17,sratio=[8800,8800,8800,8800,8800],cratio=88,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=6684,is_upgrade=0,fail_num=0};
get_strengthen(1, 18) -> 
	#ets_goods_strengthen{id=10018,type=1,strengthen=18,sratio=[8600,8600,8600,8600,8600],cratio=86,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=6941,is_upgrade=0,fail_num=0};
get_strengthen(1, 19) -> 
	#ets_goods_strengthen{id=10019,type=1,strengthen=19,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=7198,is_upgrade=0,fail_num=0};
get_strengthen(1, 20) -> 
	#ets_goods_strengthen{id=10020,type=1,strengthen=20,sratio=[6500,6500,6500,6500,6500],cratio=65,lucky_id=[121002],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=10,coin=7456,is_upgrade=1,fail_num=0};
get_strengthen(1, 21) -> 
	#ets_goods_strengthen{id=10021,type=1,strengthen=21,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=13711,is_upgrade=0,fail_num=0};
get_strengthen(1, 22) -> 
	#ets_goods_strengthen{id=10022,type=1,strengthen=22,sratio=[9300,9300,9300,9300,9300],cratio=93,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=14226,is_upgrade=0,fail_num=0};
get_strengthen(1, 23) -> 
	#ets_goods_strengthen{id=10023,type=1,strengthen=23,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=14740,is_upgrade=0,fail_num=0};
get_strengthen(1, 24) -> 
	#ets_goods_strengthen{id=10024,type=1,strengthen=24,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=15254,is_upgrade=0,fail_num=0};
get_strengthen(1, 25) -> 
	#ets_goods_strengthen{id=10025,type=1,strengthen=25,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=15768,is_upgrade=0,fail_num=0};
get_strengthen(1, 26) -> 
	#ets_goods_strengthen{id=10026,type=1,strengthen=26,sratio=[8100,8100,8100,8100,8100],cratio=81,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=16282,is_upgrade=0,fail_num=0};
get_strengthen(1, 27) -> 
	#ets_goods_strengthen{id=10027,type=1,strengthen=27,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=16796,is_upgrade=0,fail_num=0};
get_strengthen(1, 28) -> 
	#ets_goods_strengthen{id=10028,type=1,strengthen=28,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=17311,is_upgrade=0,fail_num=0};
get_strengthen(1, 29) -> 
	#ets_goods_strengthen{id=10029,type=1,strengthen=29,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=17825,is_upgrade=0,fail_num=0};
get_strengthen(1, 30) -> 
	#ets_goods_strengthen{id=10030,type=1,strengthen=30,sratio=[5000,5000,5000,5000,5000],cratio=50,lucky_id=[121003],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=15,coin=18339,is_upgrade=1,fail_num=0};
get_strengthen(1, 31) -> 
	#ets_goods_strengthen{id=10031,type=1,strengthen=31,sratio=[9500,9500,9500,9500,9500],cratio=95,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=34279,is_upgrade=0,fail_num=0};
get_strengthen(1, 32) -> 
	#ets_goods_strengthen{id=10032,type=1,strengthen=32,sratio=[9100,9100,9100,9100,9100],cratio=91,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=37158,is_upgrade=0,fail_num=0};
get_strengthen(1, 33) -> 
	#ets_goods_strengthen{id=10033,type=1,strengthen=33,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=40037,is_upgrade=0,fail_num=0};
get_strengthen(1, 34) -> 
	#ets_goods_strengthen{id=10034,type=1,strengthen=34,sratio=[8300,8300,8300,8300,8300],cratio=83,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=42917,is_upgrade=0,fail_num=0};
get_strengthen(1, 35) -> 
	#ets_goods_strengthen{id=10035,type=1,strengthen=35,sratio=[7900,7900,7900,7900,7900],cratio=79,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=45796,is_upgrade=0,fail_num=0};
get_strengthen(1, 36) -> 
	#ets_goods_strengthen{id=10036,type=1,strengthen=36,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=48675,is_upgrade=0,fail_num=0};
get_strengthen(1, 37) -> 
	#ets_goods_strengthen{id=10037,type=1,strengthen=37,sratio=[7100,7100,7100,7100,7100],cratio=71,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=51555,is_upgrade=0,fail_num=0};
get_strengthen(1, 38) -> 
	#ets_goods_strengthen{id=10038,type=1,strengthen=38,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=54434,is_upgrade=0,fail_num=0};
get_strengthen(1, 39) -> 
	#ets_goods_strengthen{id=10039,type=1,strengthen=39,sratio=[6300,6300,6300,6300,6300],cratio=63,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=57314,is_upgrade=0,fail_num=0};
get_strengthen(1, 40) -> 
	#ets_goods_strengthen{id=10040,type=1,strengthen=40,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121004],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=20,coin=60193,is_upgrade=1,fail_num=0};
get_strengthen(1, 41) -> 
	#ets_goods_strengthen{id=10041,type=1,strengthen=41,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=102836,is_upgrade=0,fail_num=0};
get_strengthen(1, 42) -> 
	#ets_goods_strengthen{id=10042,type=1,strengthen=42,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=109006,is_upgrade=0,fail_num=0};
get_strengthen(1, 43) -> 
	#ets_goods_strengthen{id=10043,type=1,strengthen=43,sratio=[8200,8200,8200,8200,8200],cratio=82,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=115176,is_upgrade=0,fail_num=0};
get_strengthen(1, 44) -> 
	#ets_goods_strengthen{id=10044,type=1,strengthen=44,sratio=[7700,7700,7700,7700,7700],cratio=77,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=121346,is_upgrade=0,fail_num=0};
get_strengthen(1, 45) -> 
	#ets_goods_strengthen{id=10045,type=1,strengthen=45,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=127516,is_upgrade=0,fail_num=0};
get_strengthen(1, 46) -> 
	#ets_goods_strengthen{id=10046,type=1,strengthen=46,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=133686,is_upgrade=0,fail_num=0};
get_strengthen(1, 47) -> 
	#ets_goods_strengthen{id=10047,type=1,strengthen=47,sratio=[6200,6200,6200,6200,6200],cratio=62,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=139856,is_upgrade=0,fail_num=0};
get_strengthen(1, 48) -> 
	#ets_goods_strengthen{id=10048,type=1,strengthen=48,sratio=[5700,5700,5700,5700,5700],cratio=57,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=146026,is_upgrade=0,fail_num=0};
get_strengthen(1, 49) -> 
	#ets_goods_strengthen{id=10049,type=1,strengthen=49,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=152197,is_upgrade=0,fail_num=0};
get_strengthen(1, 50) -> 
	#ets_goods_strengthen{id=10050,type=1,strengthen=50,sratio=[2500,2500,2500,2500,2500],cratio=25,lucky_id=[121005],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=25,coin=158367,is_upgrade=1,fail_num=0};
get_strengthen(1, 51) -> 
	#ets_goods_strengthen{id=10051,type=1,strengthen=51,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=205671,is_upgrade=0,fail_num=0};
get_strengthen(1, 52) -> 
	#ets_goods_strengthen{id=10052,type=1,strengthen=52,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=213898,is_upgrade=0,fail_num=0};
get_strengthen(1, 53) -> 
	#ets_goods_strengthen{id=10053,type=1,strengthen=53,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=222125,is_upgrade=0,fail_num=0};
get_strengthen(1, 54) -> 
	#ets_goods_strengthen{id=10054,type=1,strengthen=54,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=230352,is_upgrade=0,fail_num=0};
get_strengthen(1, 55) -> 
	#ets_goods_strengthen{id=10055,type=1,strengthen=55,sratio=[6000,6000,6000,6000,6000],cratio=60,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=238578,is_upgrade=0,fail_num=0};
get_strengthen(1, 56) -> 
	#ets_goods_strengthen{id=10056,type=1,strengthen=56,sratio=[5400,5400,5400,5400,5400],cratio=54,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=246805,is_upgrade=0,fail_num=0};
get_strengthen(1, 57) -> 
	#ets_goods_strengthen{id=10057,type=1,strengthen=57,sratio=[4800,4800,4800,4800,4800],cratio=48,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=255032,is_upgrade=0,fail_num=0};
get_strengthen(1, 58) -> 
	#ets_goods_strengthen{id=10058,type=1,strengthen=58,sratio=[4200,4200,4200,4200,4200],cratio=42,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=263259,is_upgrade=0,fail_num=0};
get_strengthen(1, 59) -> 
	#ets_goods_strengthen{id=10059,type=1,strengthen=59,sratio=[3600,3600,3600,3600,3600],cratio=36,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=271486,is_upgrade=0,fail_num=0};
get_strengthen(1, 60) -> 
	#ets_goods_strengthen{id=10060,type=1,strengthen=60,sratio=[2000,2000,2000,2000,2000],cratio=20,lucky_id=[121006],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=30,coin=279713,is_upgrade=1,fail_num=0};
get_strengthen(1, 61) -> 
	#ets_goods_strengthen{id=10061,type=1,strengthen=61,sratio=[8000,8000,8000,8000,8000],cratio=80,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=377064,is_upgrade=0,fail_num=0};
get_strengthen(1, 62) -> 
	#ets_goods_strengthen{id=10062,type=1,strengthen=62,sratio=[7300,7300,7300,7300,7300],cratio=73,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=388718,is_upgrade=0,fail_num=0};
get_strengthen(1, 63) -> 
	#ets_goods_strengthen{id=10063,type=1,strengthen=63,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=400373,is_upgrade=0,fail_num=0};
get_strengthen(1, 64) -> 
	#ets_goods_strengthen{id=10064,type=1,strengthen=64,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=412028,is_upgrade=0,fail_num=0};
get_strengthen(1, 65) -> 
	#ets_goods_strengthen{id=10065,type=1,strengthen=65,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=423682,is_upgrade=0,fail_num=0};
get_strengthen(1, 66) -> 
	#ets_goods_strengthen{id=10066,type=1,strengthen=66,sratio=[4500,4500,4500,4500,4500],cratio=45,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=435337,is_upgrade=0,fail_num=0};
get_strengthen(1, 67) -> 
	#ets_goods_strengthen{id=10067,type=1,strengthen=67,sratio=[3800,3800,3800,3800,3800],cratio=38,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=446992,is_upgrade=0,fail_num=0};
get_strengthen(1, 68) -> 
	#ets_goods_strengthen{id=10068,type=1,strengthen=68,sratio=[3100,3100,3100,3100,3100],cratio=31,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=458646,is_upgrade=0,fail_num=0};
get_strengthen(1, 69) -> 
	#ets_goods_strengthen{id=10069,type=1,strengthen=69,sratio=[2400,2400,2400,2400,2400],cratio=24,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=470301,is_upgrade=0,fail_num=0};
get_strengthen(1, 70) -> 
	#ets_goods_strengthen{id=10070,type=1,strengthen=70,sratio=[1200,1200,1200,1200,1200],cratio=12,lucky_id=[121007],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=40,coin=481956,is_upgrade=1,fail_num=0};
get_strengthen(1, 71) -> 
	#ets_goods_strengthen{id=10071,type=1,strengthen=71,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=617013,is_upgrade=0,fail_num=0};
get_strengthen(1, 72) -> 
	#ets_goods_strengthen{id=10072,type=1,strengthen=72,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=632233,is_upgrade=0,fail_num=0};
get_strengthen(1, 73) -> 
	#ets_goods_strengthen{id=10073,type=1,strengthen=73,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=647452,is_upgrade=0,fail_num=0};
get_strengthen(1, 74) -> 
	#ets_goods_strengthen{id=10074,type=1,strengthen=74,sratio=[5100,5100,5100,5100,5100],cratio=51,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=662672,is_upgrade=0,fail_num=0};
get_strengthen(1, 75) -> 
	#ets_goods_strengthen{id=10075,type=1,strengthen=75,sratio=[4300,4300,4300,4300,4300],cratio=43,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=677892,is_upgrade=0,fail_num=0};
get_strengthen(1, 76) -> 
	#ets_goods_strengthen{id=10076,type=1,strengthen=76,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=693111,is_upgrade=0,fail_num=0};
get_strengthen(1, 77) -> 
	#ets_goods_strengthen{id=10077,type=1,strengthen=77,sratio=[2700,2700,2700,2700,2700],cratio=27,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=708331,is_upgrade=0,fail_num=0};
get_strengthen(1, 78) -> 
	#ets_goods_strengthen{id=10078,type=1,strengthen=78,sratio=[1900,1900,1900,1900,1900],cratio=19,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=723551,is_upgrade=0,fail_num=0};
get_strengthen(1, 79) -> 
	#ets_goods_strengthen{id=10079,type=1,strengthen=79,sratio=[1100,1100,1100,1100,1100],cratio=11,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=738770,is_upgrade=0,fail_num=0};
get_strengthen(1, 80) -> 
	#ets_goods_strengthen{id=10080,type=1,strengthen=80,sratio=[700,700,700,700,700],cratio=7,lucky_id=[121008],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=50,coin=753990,is_upgrade=1,fail_num=0};
get_strengthen(2, 1) -> 
	#ets_goods_strengthen{id=20001,type=2,strengthen=1,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=451,is_upgrade=0,fail_num=0};
get_strengthen(2, 2) -> 
	#ets_goods_strengthen{id=20002,type=2,strengthen=2,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=542,is_upgrade=0,fail_num=0};
get_strengthen(2, 3) -> 
	#ets_goods_strengthen{id=20003,type=2,strengthen=3,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=632,is_upgrade=0,fail_num=0};
get_strengthen(2, 4) -> 
	#ets_goods_strengthen{id=20004,type=2,strengthen=4,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=722,is_upgrade=0,fail_num=0};
get_strengthen(2, 5) -> 
	#ets_goods_strengthen{id=20005,type=2,strengthen=5,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=813,is_upgrade=0,fail_num=0};
get_strengthen(2, 6) -> 
	#ets_goods_strengthen{id=20006,type=2,strengthen=6,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=903,is_upgrade=0,fail_num=0};
get_strengthen(2, 7) -> 
	#ets_goods_strengthen{id=20007,type=2,strengthen=7,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=993,is_upgrade=0,fail_num=0};
get_strengthen(2, 8) -> 
	#ets_goods_strengthen{id=20008,type=2,strengthen=8,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1084,is_upgrade=0,fail_num=0};
get_strengthen(2, 9) -> 
	#ets_goods_strengthen{id=20009,type=2,strengthen=9,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1174,is_upgrade=0,fail_num=0};
get_strengthen(2, 10) -> 
	#ets_goods_strengthen{id=20010,type=2,strengthen=10,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=1264,is_upgrade=1,fail_num=0};
get_strengthen(2, 11) -> 
	#ets_goods_strengthen{id=20011,type=2,strengthen=11,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=2709,is_upgrade=0,fail_num=0};
get_strengthen(2, 12) -> 
	#ets_goods_strengthen{id=20012,type=2,strengthen=12,sratio=[9800,9800,9800,9800,9800],cratio=98,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=2844,is_upgrade=0,fail_num=0};
get_strengthen(2, 13) -> 
	#ets_goods_strengthen{id=20013,type=2,strengthen=13,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=2980,is_upgrade=0,fail_num=0};
get_strengthen(2, 14) -> 
	#ets_goods_strengthen{id=20014,type=2,strengthen=14,sratio=[9400,9400,9400,9400,9400],cratio=94,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3115,is_upgrade=0,fail_num=0};
get_strengthen(2, 15) -> 
	#ets_goods_strengthen{id=20015,type=2,strengthen=15,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3251,is_upgrade=0,fail_num=0};
get_strengthen(2, 16) -> 
	#ets_goods_strengthen{id=20016,type=2,strengthen=16,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3386,is_upgrade=0,fail_num=0};
get_strengthen(2, 17) -> 
	#ets_goods_strengthen{id=20017,type=2,strengthen=17,sratio=[8800,8800,8800,8800,8800],cratio=88,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3521,is_upgrade=0,fail_num=0};
get_strengthen(2, 18) -> 
	#ets_goods_strengthen{id=20018,type=2,strengthen=18,sratio=[8600,8600,8600,8600,8600],cratio=86,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3657,is_upgrade=0,fail_num=0};
get_strengthen(2, 19) -> 
	#ets_goods_strengthen{id=20019,type=2,strengthen=19,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3792,is_upgrade=0,fail_num=0};
get_strengthen(2, 20) -> 
	#ets_goods_strengthen{id=20020,type=2,strengthen=20,sratio=[6500,6500,6500,6500,6500],cratio=65,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=10,coin=3928,is_upgrade=1,fail_num=0};
get_strengthen(2, 21) -> 
	#ets_goods_strengthen{id=20021,type=2,strengthen=21,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=7223,is_upgrade=0,fail_num=0};
get_strengthen(2, 22) -> 
	#ets_goods_strengthen{id=20022,type=2,strengthen=22,sratio=[9300,9300,9300,9300,9300],cratio=93,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=7494,is_upgrade=0,fail_num=0};
get_strengthen(2, 23) -> 
	#ets_goods_strengthen{id=20023,type=2,strengthen=23,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=7765,is_upgrade=0,fail_num=0};
get_strengthen(2, 24) -> 
	#ets_goods_strengthen{id=20024,type=2,strengthen=24,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8036,is_upgrade=0,fail_num=0};
get_strengthen(2, 25) -> 
	#ets_goods_strengthen{id=20025,type=2,strengthen=25,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8307,is_upgrade=0,fail_num=0};
get_strengthen(2, 26) -> 
	#ets_goods_strengthen{id=20026,type=2,strengthen=26,sratio=[8100,8100,8100,8100,8100],cratio=81,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8578,is_upgrade=0,fail_num=0};
get_strengthen(2, 27) -> 
	#ets_goods_strengthen{id=20027,type=2,strengthen=27,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8849,is_upgrade=0,fail_num=0};
get_strengthen(2, 28) -> 
	#ets_goods_strengthen{id=20028,type=2,strengthen=28,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=9120,is_upgrade=0,fail_num=0};
get_strengthen(2, 29) -> 
	#ets_goods_strengthen{id=20029,type=2,strengthen=29,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=9390,is_upgrade=0,fail_num=0};
get_strengthen(2, 30) -> 
	#ets_goods_strengthen{id=20030,type=2,strengthen=30,sratio=[5000,5000,5000,5000,5000],cratio=50,lucky_id=[121003],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=15,coin=9661,is_upgrade=1,fail_num=0};
get_strengthen(2, 31) -> 
	#ets_goods_strengthen{id=20031,type=2,strengthen=31,sratio=[9500,9500,9500,9500,9500],cratio=95,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=18058,is_upgrade=0,fail_num=0};
get_strengthen(2, 32) -> 
	#ets_goods_strengthen{id=20032,type=2,strengthen=32,sratio=[9100,9100,9100,9100,9100],cratio=91,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=19575,is_upgrade=0,fail_num=0};
get_strengthen(2, 33) -> 
	#ets_goods_strengthen{id=20033,type=2,strengthen=33,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=21092,is_upgrade=0,fail_num=0};
get_strengthen(2, 34) -> 
	#ets_goods_strengthen{id=20034,type=2,strengthen=34,sratio=[8300,8300,8300,8300,8300],cratio=83,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=22609,is_upgrade=0,fail_num=0};
get_strengthen(2, 35) -> 
	#ets_goods_strengthen{id=20035,type=2,strengthen=35,sratio=[7900,7900,7900,7900,7900],cratio=79,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=24126,is_upgrade=0,fail_num=0};
get_strengthen(2, 36) -> 
	#ets_goods_strengthen{id=20036,type=2,strengthen=36,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=25643,is_upgrade=0,fail_num=0};
get_strengthen(2, 37) -> 
	#ets_goods_strengthen{id=20037,type=2,strengthen=37,sratio=[7100,7100,7100,7100,7100],cratio=71,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=27160,is_upgrade=0,fail_num=0};
get_strengthen(2, 38) -> 
	#ets_goods_strengthen{id=20038,type=2,strengthen=38,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=28677,is_upgrade=0,fail_num=0};
get_strengthen(2, 39) -> 
	#ets_goods_strengthen{id=20039,type=2,strengthen=39,sratio=[6300,6300,6300,6300,6300],cratio=63,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=30194,is_upgrade=0,fail_num=0};
get_strengthen(2, 40) -> 
	#ets_goods_strengthen{id=20040,type=2,strengthen=40,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121004],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=20,coin=31711,is_upgrade=1,fail_num=0};
get_strengthen(2, 41) -> 
	#ets_goods_strengthen{id=20041,type=2,strengthen=41,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=54175,is_upgrade=0,fail_num=0};
get_strengthen(2, 42) -> 
	#ets_goods_strengthen{id=20042,type=2,strengthen=42,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=57426,is_upgrade=0,fail_num=0};
get_strengthen(2, 43) -> 
	#ets_goods_strengthen{id=20043,type=2,strengthen=43,sratio=[8200,8200,8200,8200,8200],cratio=82,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=60676,is_upgrade=0,fail_num=0};
get_strengthen(2, 44) -> 
	#ets_goods_strengthen{id=20044,type=2,strengthen=44,sratio=[7700,7700,7700,7700,7700],cratio=77,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=63927,is_upgrade=0,fail_num=0};
get_strengthen(2, 45) -> 
	#ets_goods_strengthen{id=20045,type=2,strengthen=45,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=67177,is_upgrade=0,fail_num=0};
get_strengthen(2, 46) -> 
	#ets_goods_strengthen{id=20046,type=2,strengthen=46,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=70428,is_upgrade=0,fail_num=0};
get_strengthen(2, 47) -> 
	#ets_goods_strengthen{id=20047,type=2,strengthen=47,sratio=[6200,6200,6200,6200,6200],cratio=62,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=73678,is_upgrade=0,fail_num=0};
get_strengthen(2, 48) -> 
	#ets_goods_strengthen{id=20048,type=2,strengthen=48,sratio=[5700,5700,5700,5700,5700],cratio=57,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=76929,is_upgrade=0,fail_num=0};
get_strengthen(2, 49) -> 
	#ets_goods_strengthen{id=20049,type=2,strengthen=49,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=80179,is_upgrade=0,fail_num=0};
get_strengthen(2, 50) -> 
	#ets_goods_strengthen{id=20050,type=2,strengthen=50,sratio=[2500,2500,2500,2500,2500],cratio=25,lucky_id=[121005],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=25,coin=83430,is_upgrade=1,fail_num=0};
get_strengthen(2, 51) -> 
	#ets_goods_strengthen{id=20051,type=2,strengthen=51,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=108351,is_upgrade=0,fail_num=0};
get_strengthen(2, 52) -> 
	#ets_goods_strengthen{id=20052,type=2,strengthen=52,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=112685,is_upgrade=0,fail_num=0};
get_strengthen(2, 53) -> 
	#ets_goods_strengthen{id=20053,type=2,strengthen=53,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=117019,is_upgrade=0,fail_num=0};
get_strengthen(2, 54) -> 
	#ets_goods_strengthen{id=20054,type=2,strengthen=54,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=121353,is_upgrade=0,fail_num=0};
get_strengthen(2, 55) -> 
	#ets_goods_strengthen{id=20055,type=2,strengthen=55,sratio=[6000,6000,6000,6000,6000],cratio=60,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=125687,is_upgrade=0,fail_num=0};
get_strengthen(2, 56) -> 
	#ets_goods_strengthen{id=20056,type=2,strengthen=56,sratio=[5400,5400,5400,5400,5400],cratio=54,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=130021,is_upgrade=0,fail_num=0};
get_strengthen(2, 57) -> 
	#ets_goods_strengthen{id=20057,type=2,strengthen=57,sratio=[4800,4800,4800,4800,4800],cratio=48,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=134355,is_upgrade=0,fail_num=0};
get_strengthen(2, 58) -> 
	#ets_goods_strengthen{id=20058,type=2,strengthen=58,sratio=[4200,4200,4200,4200,4200],cratio=42,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=138689,is_upgrade=0,fail_num=0};
get_strengthen(2, 59) -> 
	#ets_goods_strengthen{id=20059,type=2,strengthen=59,sratio=[3600,3600,3600,3600,3600],cratio=36,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=143023,is_upgrade=0,fail_num=0};
get_strengthen(2, 60) -> 
	#ets_goods_strengthen{id=20060,type=2,strengthen=60,sratio=[2000,2000,2000,2000,2000],cratio=20,lucky_id=[121006],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=30,coin=147357,is_upgrade=1,fail_num=0};
get_strengthen(2, 61) -> 
	#ets_goods_strengthen{id=20061,type=2,strengthen=61,sratio=[8000,8000,8000,8000,8000],cratio=80,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=198643,is_upgrade=0,fail_num=0};
get_strengthen(2, 62) -> 
	#ets_goods_strengthen{id=20062,type=2,strengthen=62,sratio=[7300,7300,7300,7300,7300],cratio=73,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=204783,is_upgrade=0,fail_num=0};
get_strengthen(2, 63) -> 
	#ets_goods_strengthen{id=20063,type=2,strengthen=63,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=210923,is_upgrade=0,fail_num=0};
get_strengthen(2, 64) -> 
	#ets_goods_strengthen{id=20064,type=2,strengthen=64,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=217062,is_upgrade=0,fail_num=0};
get_strengthen(2, 65) -> 
	#ets_goods_strengthen{id=20065,type=2,strengthen=65,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=223202,is_upgrade=0,fail_num=0};
get_strengthen(2, 66) -> 
	#ets_goods_strengthen{id=20066,type=2,strengthen=66,sratio=[4500,4500,4500,4500,4500],cratio=45,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=229342,is_upgrade=0,fail_num=0};
get_strengthen(2, 67) -> 
	#ets_goods_strengthen{id=20067,type=2,strengthen=67,sratio=[3800,3800,3800,3800,3800],cratio=38,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=235482,is_upgrade=0,fail_num=0};
get_strengthen(2, 68) -> 
	#ets_goods_strengthen{id=20068,type=2,strengthen=68,sratio=[3100,3100,3100,3100,3100],cratio=31,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=241622,is_upgrade=0,fail_num=0};
get_strengthen(2, 69) -> 
	#ets_goods_strengthen{id=20069,type=2,strengthen=69,sratio=[2400,2400,2400,2400,2400],cratio=24,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=247762,is_upgrade=0,fail_num=0};
get_strengthen(2, 70) -> 
	#ets_goods_strengthen{id=20070,type=2,strengthen=70,sratio=[1200,1200,1200,1200,1200],cratio=12,lucky_id=[121007],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=40,coin=253902,is_upgrade=1,fail_num=0};
get_strengthen(2, 71) -> 
	#ets_goods_strengthen{id=20071,type=2,strengthen=71,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=325052,is_upgrade=0,fail_num=0};
get_strengthen(2, 72) -> 
	#ets_goods_strengthen{id=20072,type=2,strengthen=72,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=333070,is_upgrade=0,fail_num=0};
get_strengthen(2, 73) -> 
	#ets_goods_strengthen{id=20073,type=2,strengthen=73,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=341088,is_upgrade=0,fail_num=0};
get_strengthen(2, 74) -> 
	#ets_goods_strengthen{id=20074,type=2,strengthen=74,sratio=[5100,5100,5100,5100,5100],cratio=51,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=349106,is_upgrade=0,fail_num=0};
get_strengthen(2, 75) -> 
	#ets_goods_strengthen{id=20075,type=2,strengthen=75,sratio=[4300,4300,4300,4300,4300],cratio=43,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=357124,is_upgrade=0,fail_num=0};
get_strengthen(2, 76) -> 
	#ets_goods_strengthen{id=20076,type=2,strengthen=76,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=365142,is_upgrade=0,fail_num=0};
get_strengthen(2, 77) -> 
	#ets_goods_strengthen{id=20077,type=2,strengthen=77,sratio=[2700,2700,2700,2700,2700],cratio=27,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=373160,is_upgrade=0,fail_num=0};
get_strengthen(2, 78) -> 
	#ets_goods_strengthen{id=20078,type=2,strengthen=78,sratio=[1900,1900,1900,1900,1900],cratio=19,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=381178,is_upgrade=0,fail_num=0};
get_strengthen(2, 79) -> 
	#ets_goods_strengthen{id=20079,type=2,strengthen=79,sratio=[1100,1100,1100,1100,1100],cratio=11,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=389196,is_upgrade=0,fail_num=0};
get_strengthen(2, 80) -> 
	#ets_goods_strengthen{id=20080,type=2,strengthen=80,sratio=[700,700,700,700,700],cratio=7,lucky_id=[121008],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=50,coin=397213,is_upgrade=1,fail_num=0};
get_strengthen(3, 1) -> 
	#ets_goods_strengthen{id=30001,type=3,strengthen=1,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=451,is_upgrade=0,fail_num=0};
get_strengthen(3, 2) -> 
	#ets_goods_strengthen{id=30002,type=3,strengthen=2,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=542,is_upgrade=0,fail_num=0};
get_strengthen(3, 3) -> 
	#ets_goods_strengthen{id=30003,type=3,strengthen=3,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=632,is_upgrade=0,fail_num=0};
get_strengthen(3, 4) -> 
	#ets_goods_strengthen{id=30004,type=3,strengthen=4,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=722,is_upgrade=0,fail_num=0};
get_strengthen(3, 5) -> 
	#ets_goods_strengthen{id=30005,type=3,strengthen=5,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=813,is_upgrade=0,fail_num=0};
get_strengthen(3, 6) -> 
	#ets_goods_strengthen{id=30006,type=3,strengthen=6,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=903,is_upgrade=0,fail_num=0};
get_strengthen(3, 7) -> 
	#ets_goods_strengthen{id=30007,type=3,strengthen=7,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=993,is_upgrade=0,fail_num=0};
get_strengthen(3, 8) -> 
	#ets_goods_strengthen{id=30008,type=3,strengthen=8,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1084,is_upgrade=0,fail_num=0};
get_strengthen(3, 9) -> 
	#ets_goods_strengthen{id=30009,type=3,strengthen=9,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1174,is_upgrade=0,fail_num=0};
get_strengthen(3, 10) -> 
	#ets_goods_strengthen{id=30010,type=3,strengthen=10,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=1264,is_upgrade=1,fail_num=0};
get_strengthen(3, 11) -> 
	#ets_goods_strengthen{id=30011,type=3,strengthen=11,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=2709,is_upgrade=0,fail_num=0};
get_strengthen(3, 12) -> 
	#ets_goods_strengthen{id=30012,type=3,strengthen=12,sratio=[9800,9800,9800,9800,9800],cratio=98,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=2844,is_upgrade=0,fail_num=0};
get_strengthen(3, 13) -> 
	#ets_goods_strengthen{id=30013,type=3,strengthen=13,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=2980,is_upgrade=0,fail_num=0};
get_strengthen(3, 14) -> 
	#ets_goods_strengthen{id=30014,type=3,strengthen=14,sratio=[9400,9400,9400,9400,9400],cratio=94,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3115,is_upgrade=0,fail_num=0};
get_strengthen(3, 15) -> 
	#ets_goods_strengthen{id=30015,type=3,strengthen=15,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3251,is_upgrade=0,fail_num=0};
get_strengthen(3, 16) -> 
	#ets_goods_strengthen{id=30016,type=3,strengthen=16,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3386,is_upgrade=0,fail_num=0};
get_strengthen(3, 17) -> 
	#ets_goods_strengthen{id=30017,type=3,strengthen=17,sratio=[8800,8800,8800,8800,8800],cratio=88,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3521,is_upgrade=0,fail_num=0};
get_strengthen(3, 18) -> 
	#ets_goods_strengthen{id=30018,type=3,strengthen=18,sratio=[8600,8600,8600,8600,8600],cratio=86,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3657,is_upgrade=0,fail_num=0};
get_strengthen(3, 19) -> 
	#ets_goods_strengthen{id=30019,type=3,strengthen=19,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3792,is_upgrade=0,fail_num=0};
get_strengthen(3, 20) -> 
	#ets_goods_strengthen{id=30020,type=3,strengthen=20,sratio=[6500,6500,6500,6500,6500],cratio=65,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=10,coin=3928,is_upgrade=1,fail_num=0};
get_strengthen(3, 21) -> 
	#ets_goods_strengthen{id=30021,type=3,strengthen=21,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=7223,is_upgrade=0,fail_num=0};
get_strengthen(3, 22) -> 
	#ets_goods_strengthen{id=30022,type=3,strengthen=22,sratio=[9300,9300,9300,9300,9300],cratio=93,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=7494,is_upgrade=0,fail_num=0};
get_strengthen(3, 23) -> 
	#ets_goods_strengthen{id=30023,type=3,strengthen=23,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=7765,is_upgrade=0,fail_num=0};
get_strengthen(3, 24) -> 
	#ets_goods_strengthen{id=30024,type=3,strengthen=24,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8036,is_upgrade=0,fail_num=0};
get_strengthen(3, 25) -> 
	#ets_goods_strengthen{id=30025,type=3,strengthen=25,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8307,is_upgrade=0,fail_num=0};
get_strengthen(3, 26) -> 
	#ets_goods_strengthen{id=30026,type=3,strengthen=26,sratio=[8100,8100,8100,8100,8100],cratio=81,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8578,is_upgrade=0,fail_num=0};
get_strengthen(3, 27) -> 
	#ets_goods_strengthen{id=30027,type=3,strengthen=27,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8849,is_upgrade=0,fail_num=0};
get_strengthen(3, 28) -> 
	#ets_goods_strengthen{id=30028,type=3,strengthen=28,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=9120,is_upgrade=0,fail_num=0};
get_strengthen(3, 29) -> 
	#ets_goods_strengthen{id=30029,type=3,strengthen=29,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=9390,is_upgrade=0,fail_num=0};
get_strengthen(3, 30) -> 
	#ets_goods_strengthen{id=30030,type=3,strengthen=30,sratio=[5000,5000,5000,5000,5000],cratio=50,lucky_id=[121003],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=15,coin=9661,is_upgrade=1,fail_num=0};
get_strengthen(3, 31) -> 
	#ets_goods_strengthen{id=30031,type=3,strengthen=31,sratio=[9500,9500,9500,9500,9500],cratio=95,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=18058,is_upgrade=0,fail_num=0};
get_strengthen(3, 32) -> 
	#ets_goods_strengthen{id=30032,type=3,strengthen=32,sratio=[9100,9100,9100,9100,9100],cratio=91,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=19575,is_upgrade=0,fail_num=0};
get_strengthen(3, 33) -> 
	#ets_goods_strengthen{id=30033,type=3,strengthen=33,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=21092,is_upgrade=0,fail_num=0};
get_strengthen(3, 34) -> 
	#ets_goods_strengthen{id=30034,type=3,strengthen=34,sratio=[8300,8300,8300,8300,8300],cratio=83,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=22609,is_upgrade=0,fail_num=0};
get_strengthen(3, 35) -> 
	#ets_goods_strengthen{id=30035,type=3,strengthen=35,sratio=[7900,7900,7900,7900,7900],cratio=79,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=24126,is_upgrade=0,fail_num=0};
get_strengthen(3, 36) -> 
	#ets_goods_strengthen{id=30036,type=3,strengthen=36,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=25643,is_upgrade=0,fail_num=0};
get_strengthen(3, 37) -> 
	#ets_goods_strengthen{id=30037,type=3,strengthen=37,sratio=[7100,7100,7100,7100,7100],cratio=71,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=27160,is_upgrade=0,fail_num=0};
get_strengthen(3, 38) -> 
	#ets_goods_strengthen{id=30038,type=3,strengthen=38,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=28677,is_upgrade=0,fail_num=0};
get_strengthen(3, 39) -> 
	#ets_goods_strengthen{id=30039,type=3,strengthen=39,sratio=[6300,6300,6300,6300,6300],cratio=63,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=30194,is_upgrade=0,fail_num=0};
get_strengthen(3, 40) -> 
	#ets_goods_strengthen{id=30040,type=3,strengthen=40,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121004],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=20,coin=31711,is_upgrade=1,fail_num=0};
get_strengthen(3, 41) -> 
	#ets_goods_strengthen{id=30041,type=3,strengthen=41,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=54175,is_upgrade=0,fail_num=0};
get_strengthen(3, 42) -> 
	#ets_goods_strengthen{id=30042,type=3,strengthen=42,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=57426,is_upgrade=0,fail_num=0};
get_strengthen(3, 43) -> 
	#ets_goods_strengthen{id=30043,type=3,strengthen=43,sratio=[8200,8200,8200,8200,8200],cratio=82,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=60676,is_upgrade=0,fail_num=0};
get_strengthen(3, 44) -> 
	#ets_goods_strengthen{id=30044,type=3,strengthen=44,sratio=[7700,7700,7700,7700,7700],cratio=77,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=63927,is_upgrade=0,fail_num=0};
get_strengthen(3, 45) -> 
	#ets_goods_strengthen{id=30045,type=3,strengthen=45,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=67177,is_upgrade=0,fail_num=0};
get_strengthen(3, 46) -> 
	#ets_goods_strengthen{id=30046,type=3,strengthen=46,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=70428,is_upgrade=0,fail_num=0};
get_strengthen(3, 47) -> 
	#ets_goods_strengthen{id=30047,type=3,strengthen=47,sratio=[6200,6200,6200,6200,6200],cratio=62,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=73678,is_upgrade=0,fail_num=0};
get_strengthen(3, 48) -> 
	#ets_goods_strengthen{id=30048,type=3,strengthen=48,sratio=[5700,5700,5700,5700,5700],cratio=57,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=76929,is_upgrade=0,fail_num=0};
get_strengthen(3, 49) -> 
	#ets_goods_strengthen{id=30049,type=3,strengthen=49,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=80179,is_upgrade=0,fail_num=0};
get_strengthen(3, 50) -> 
	#ets_goods_strengthen{id=30050,type=3,strengthen=50,sratio=[2500,2500,2500,2500,2500],cratio=25,lucky_id=[121005],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=25,coin=83430,is_upgrade=1,fail_num=0};
get_strengthen(3, 51) -> 
	#ets_goods_strengthen{id=30051,type=3,strengthen=51,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=108351,is_upgrade=0,fail_num=0};
get_strengthen(3, 52) -> 
	#ets_goods_strengthen{id=30052,type=3,strengthen=52,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=112685,is_upgrade=0,fail_num=0};
get_strengthen(3, 53) -> 
	#ets_goods_strengthen{id=30053,type=3,strengthen=53,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=117019,is_upgrade=0,fail_num=0};
get_strengthen(3, 54) -> 
	#ets_goods_strengthen{id=30054,type=3,strengthen=54,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=121353,is_upgrade=0,fail_num=0};
get_strengthen(3, 55) -> 
	#ets_goods_strengthen{id=30055,type=3,strengthen=55,sratio=[6000,6000,6000,6000,6000],cratio=60,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=125687,is_upgrade=0,fail_num=0};
get_strengthen(3, 56) -> 
	#ets_goods_strengthen{id=30056,type=3,strengthen=56,sratio=[5400,5400,5400,5400,5400],cratio=54,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=130021,is_upgrade=0,fail_num=0};
get_strengthen(3, 57) -> 
	#ets_goods_strengthen{id=30057,type=3,strengthen=57,sratio=[4800,4800,4800,4800,4800],cratio=48,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=134355,is_upgrade=0,fail_num=0};
get_strengthen(3, 58) -> 
	#ets_goods_strengthen{id=30058,type=3,strengthen=58,sratio=[4200,4200,4200,4200,4200],cratio=42,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=138689,is_upgrade=0,fail_num=0};
get_strengthen(3, 59) -> 
	#ets_goods_strengthen{id=30059,type=3,strengthen=59,sratio=[3600,3600,3600,3600,3600],cratio=36,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=143023,is_upgrade=0,fail_num=0};
get_strengthen(3, 60) -> 
	#ets_goods_strengthen{id=30060,type=3,strengthen=60,sratio=[2000,2000,2000,2000,2000],cratio=20,lucky_id=[121006],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=30,coin=147357,is_upgrade=1,fail_num=0};
get_strengthen(3, 61) -> 
	#ets_goods_strengthen{id=30061,type=3,strengthen=61,sratio=[8000,8000,8000,8000,8000],cratio=80,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=198643,is_upgrade=0,fail_num=0};
get_strengthen(3, 62) -> 
	#ets_goods_strengthen{id=30062,type=3,strengthen=62,sratio=[7300,7300,7300,7300,7300],cratio=73,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=204783,is_upgrade=0,fail_num=0};
get_strengthen(3, 63) -> 
	#ets_goods_strengthen{id=30063,type=3,strengthen=63,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=210923,is_upgrade=0,fail_num=0};
get_strengthen(3, 64) -> 
	#ets_goods_strengthen{id=30064,type=3,strengthen=64,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=217062,is_upgrade=0,fail_num=0};
get_strengthen(3, 65) -> 
	#ets_goods_strengthen{id=30065,type=3,strengthen=65,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=223202,is_upgrade=0,fail_num=0};
get_strengthen(3, 66) -> 
	#ets_goods_strengthen{id=30066,type=3,strengthen=66,sratio=[4500,4500,4500,4500,4500],cratio=45,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=229342,is_upgrade=0,fail_num=0};
get_strengthen(3, 67) -> 
	#ets_goods_strengthen{id=30067,type=3,strengthen=67,sratio=[3800,3800,3800,3800,3800],cratio=38,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=235482,is_upgrade=0,fail_num=0};
get_strengthen(3, 68) -> 
	#ets_goods_strengthen{id=30068,type=3,strengthen=68,sratio=[3100,3100,3100,3100,3100],cratio=31,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=241622,is_upgrade=0,fail_num=0};
get_strengthen(3, 69) -> 
	#ets_goods_strengthen{id=30069,type=3,strengthen=69,sratio=[2400,2400,2400,2400,2400],cratio=24,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=247762,is_upgrade=0,fail_num=0};
get_strengthen(3, 70) -> 
	#ets_goods_strengthen{id=30070,type=3,strengthen=70,sratio=[1200,1200,1200,1200,1200],cratio=12,lucky_id=[121007],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=40,coin=253902,is_upgrade=1,fail_num=0};
get_strengthen(3, 71) -> 
	#ets_goods_strengthen{id=30071,type=3,strengthen=71,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=325052,is_upgrade=0,fail_num=0};
get_strengthen(3, 72) -> 
	#ets_goods_strengthen{id=30072,type=3,strengthen=72,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=333070,is_upgrade=0,fail_num=0};
get_strengthen(3, 73) -> 
	#ets_goods_strengthen{id=30073,type=3,strengthen=73,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=341088,is_upgrade=0,fail_num=0};
get_strengthen(3, 74) -> 
	#ets_goods_strengthen{id=30074,type=3,strengthen=74,sratio=[5100,5100,5100,5100,5100],cratio=51,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=349106,is_upgrade=0,fail_num=0};
get_strengthen(3, 75) -> 
	#ets_goods_strengthen{id=30075,type=3,strengthen=75,sratio=[4300,4300,4300,4300,4300],cratio=43,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=357124,is_upgrade=0,fail_num=0};
get_strengthen(3, 76) -> 
	#ets_goods_strengthen{id=30076,type=3,strengthen=76,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=365142,is_upgrade=0,fail_num=0};
get_strengthen(3, 77) -> 
	#ets_goods_strengthen{id=30077,type=3,strengthen=77,sratio=[2700,2700,2700,2700,2700],cratio=27,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=373160,is_upgrade=0,fail_num=0};
get_strengthen(3, 78) -> 
	#ets_goods_strengthen{id=30078,type=3,strengthen=78,sratio=[1900,1900,1900,1900,1900],cratio=19,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=381178,is_upgrade=0,fail_num=0};
get_strengthen(3, 79) -> 
	#ets_goods_strengthen{id=30079,type=3,strengthen=79,sratio=[1100,1100,1100,1100,1100],cratio=11,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=389196,is_upgrade=0,fail_num=0};
get_strengthen(3, 80) -> 
	#ets_goods_strengthen{id=30080,type=3,strengthen=80,sratio=[700,700,700,700,700],cratio=7,lucky_id=[121008],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=50,coin=397213,is_upgrade=1,fail_num=0};
get_strengthen(4, 1) -> 
	#ets_goods_strengthen{id=40001,type=4,strengthen=1,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=338,is_upgrade=0,fail_num=0};
get_strengthen(4, 2) -> 
	#ets_goods_strengthen{id=40002,type=4,strengthen=2,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,3}],stone_id=111041,stone_num=1,coin=405,is_upgrade=0,fail_num=0};
get_strengthen(4, 3) -> 
	#ets_goods_strengthen{id=40003,type=4,strengthen=3,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,4}],stone_id=111041,stone_num=1,coin=473,is_upgrade=0,fail_num=0};
get_strengthen(4, 4) -> 
	#ets_goods_strengthen{id=40004,type=4,strengthen=4,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,5}],stone_id=111041,stone_num=1,coin=540,is_upgrade=0,fail_num=0};
get_strengthen(4, 5) -> 
	#ets_goods_strengthen{id=40005,type=4,strengthen=5,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,6}],stone_id=111041,stone_num=1,coin=608,is_upgrade=0,fail_num=0};
get_strengthen(4, 6) -> 
	#ets_goods_strengthen{id=40006,type=4,strengthen=6,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,7}],stone_id=111041,stone_num=1,coin=675,is_upgrade=0,fail_num=0};
get_strengthen(4, 7) -> 
	#ets_goods_strengthen{id=40007,type=4,strengthen=7,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,8}],stone_id=111041,stone_num=1,coin=743,is_upgrade=0,fail_num=0};
get_strengthen(4, 8) -> 
	#ets_goods_strengthen{id=40008,type=4,strengthen=8,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,9}],stone_id=111041,stone_num=1,coin=810,is_upgrade=0,fail_num=0};
get_strengthen(4, 9) -> 
	#ets_goods_strengthen{id=40009,type=4,strengthen=9,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,10}],stone_id=111041,stone_num=1,coin=878,is_upgrade=0,fail_num=0};
get_strengthen(4, 10) -> 
	#ets_goods_strengthen{id=40010,type=4,strengthen=10,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,11}],stone_id=111041,stone_num=1,coin=945,is_upgrade=0,fail_num=0};
get_strengthen(4, 11) -> 
	#ets_goods_strengthen{id=40011,type=4,strengthen=11,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,12}],stone_id=111041,stone_num=2,coin=2025,is_upgrade=0,fail_num=0};
get_strengthen(4, 12) -> 
	#ets_goods_strengthen{id=40012,type=4,strengthen=12,sratio=[9800,9800,9800,9800,9800],cratio=98,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,13}],stone_id=111041,stone_num=2,coin=2126,is_upgrade=0,fail_num=0};
get_strengthen(4, 13) -> 
	#ets_goods_strengthen{id=40013,type=4,strengthen=13,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,14}],stone_id=111041,stone_num=2,coin=2228,is_upgrade=0,fail_num=0};
get_strengthen(4, 14) -> 
	#ets_goods_strengthen{id=40014,type=4,strengthen=14,sratio=[9400,9400,9400,9400,9400],cratio=94,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,15}],stone_id=111041,stone_num=2,coin=2329,is_upgrade=0,fail_num=0};
get_strengthen(4, 15) -> 
	#ets_goods_strengthen{id=40015,type=4,strengthen=15,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,16}],stone_id=111041,stone_num=2,coin=2430,is_upgrade=0,fail_num=0};
get_strengthen(4, 16) -> 
	#ets_goods_strengthen{id=40016,type=4,strengthen=16,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,17}],stone_id=111041,stone_num=2,coin=2531,is_upgrade=0,fail_num=0};
get_strengthen(4, 17) -> 
	#ets_goods_strengthen{id=40017,type=4,strengthen=17,sratio=[8800,8800,8800,8800,8800],cratio=88,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,18}],stone_id=111041,stone_num=2,coin=2633,is_upgrade=0,fail_num=0};
get_strengthen(4, 18) -> 
	#ets_goods_strengthen{id=40018,type=4,strengthen=18,sratio=[8600,8600,8600,8600,8600],cratio=86,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,19}],stone_id=111041,stone_num=2,coin=2734,is_upgrade=0,fail_num=0};
get_strengthen(4, 19) -> 
	#ets_goods_strengthen{id=40019,type=4,strengthen=19,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,20}],stone_id=111041,stone_num=2,coin=2835,is_upgrade=0,fail_num=0};
get_strengthen(4, 20) -> 
	#ets_goods_strengthen{id=40020,type=4,strengthen=20,sratio=[6500,6500,6500,6500,6500],cratio=65,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,21}],stone_id=111041,stone_num=2,coin=2936,is_upgrade=0,fail_num=0};
get_strengthen(4, 21) -> 
	#ets_goods_strengthen{id=40021,type=4,strengthen=21,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,22}],stone_id=111041,stone_num=3,coin=5400,is_upgrade=0,fail_num=0};
get_strengthen(4, 22) -> 
	#ets_goods_strengthen{id=40022,type=4,strengthen=22,sratio=[9300,9300,9300,9300,9300],cratio=93,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,23}],stone_id=111041,stone_num=3,coin=5603,is_upgrade=0,fail_num=0};
get_strengthen(4, 23) -> 
	#ets_goods_strengthen{id=40023,type=4,strengthen=23,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,24}],stone_id=111041,stone_num=3,coin=5805,is_upgrade=0,fail_num=0};
get_strengthen(4, 24) -> 
	#ets_goods_strengthen{id=40024,type=4,strengthen=24,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,25}],stone_id=111041,stone_num=3,coin=6008,is_upgrade=0,fail_num=0};
get_strengthen(4, 25) -> 
	#ets_goods_strengthen{id=40025,type=4,strengthen=25,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,26}],stone_id=111041,stone_num=3,coin=6210,is_upgrade=0,fail_num=0};
get_strengthen(4, 26) -> 
	#ets_goods_strengthen{id=40026,type=4,strengthen=26,sratio=[8100,8100,8100,8100,8100],cratio=81,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,27}],stone_id=111041,stone_num=3,coin=6413,is_upgrade=0,fail_num=0};
get_strengthen(4, 27) -> 
	#ets_goods_strengthen{id=40027,type=4,strengthen=27,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,28}],stone_id=111041,stone_num=3,coin=6615,is_upgrade=0,fail_num=0};
get_strengthen(4, 28) -> 
	#ets_goods_strengthen{id=40028,type=4,strengthen=28,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,29}],stone_id=111041,stone_num=3,coin=6818,is_upgrade=0,fail_num=0};
get_strengthen(4, 29) -> 
	#ets_goods_strengthen{id=40029,type=4,strengthen=29,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,30}],stone_id=111041,stone_num=3,coin=7021,is_upgrade=0,fail_num=0};
get_strengthen(4, 30) -> 
	#ets_goods_strengthen{id=40030,type=4,strengthen=30,sratio=[5000,5000,5000,5000,5000],cratio=50,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,31}],stone_id=111041,stone_num=3,coin=7223,is_upgrade=0,fail_num=0};
get_strengthen(4, 31) -> 
	#ets_goods_strengthen{id=40031,type=4,strengthen=31,sratio=[9500,9500,9500,9500,9500],cratio=95,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,32}],stone_id=111041,stone_num=3,coin=13501,is_upgrade=0,fail_num=0};
get_strengthen(4, 32) -> 
	#ets_goods_strengthen{id=40032,type=4,strengthen=32,sratio=[9100,9100,9100,9100,9100],cratio=91,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,33}],stone_id=111041,stone_num=3,coin=14635,is_upgrade=0,fail_num=0};
get_strengthen(4, 33) -> 
	#ets_goods_strengthen{id=40033,type=4,strengthen=33,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=3,coin=15769,is_upgrade=0,fail_num=0};
get_strengthen(4, 34) -> 
	#ets_goods_strengthen{id=40034,type=4,strengthen=34,sratio=[8300,8300,8300,8300,8300],cratio=83,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=3,coin=16903,is_upgrade=0,fail_num=0};
get_strengthen(4, 35) -> 
	#ets_goods_strengthen{id=40035,type=4,strengthen=35,sratio=[7900,7900,7900,7900,7900],cratio=79,lucky_id=[121004],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=15,coin=18037,is_upgrade=1,fail_num=0};
get_strengthen(4, 36) -> 
	#ets_goods_strengthen{id=40036,type=4,strengthen=36,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=5,coin=19171,is_upgrade=0,fail_num=0};
get_strengthen(4, 37) -> 
	#ets_goods_strengthen{id=40037,type=4,strengthen=37,sratio=[7100,7100,7100,7100,7100],cratio=71,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=5,coin=20305,is_upgrade=0,fail_num=0};
get_strengthen(4, 38) -> 
	#ets_goods_strengthen{id=40038,type=4,strengthen=38,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=5,coin=21440,is_upgrade=0,fail_num=0};
get_strengthen(4, 39) -> 
	#ets_goods_strengthen{id=40039,type=4,strengthen=39,sratio=[6300,6300,6300,6300,6300],cratio=63,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=22574,is_upgrade=0,fail_num=0};
get_strengthen(4, 40) -> 
	#ets_goods_strengthen{id=40040,type=4,strengthen=40,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=23708,is_upgrade=0,fail_num=0};
get_strengthen(4, 41) -> 
	#ets_goods_strengthen{id=40041,type=4,strengthen=41,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=40503,is_upgrade=0,fail_num=0};
get_strengthen(4, 42) -> 
	#ets_goods_strengthen{id=40042,type=4,strengthen=42,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=42933,is_upgrade=0,fail_num=0};
get_strengthen(4, 43) -> 
	#ets_goods_strengthen{id=40043,type=4,strengthen=43,sratio=[8200,8200,8200,8200,8200],cratio=82,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=45363,is_upgrade=0,fail_num=0};
get_strengthen(4, 44) -> 
	#ets_goods_strengthen{id=40044,type=4,strengthen=44,sratio=[7700,7700,7700,7700,7700],cratio=77,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=47794,is_upgrade=0,fail_num=0};
get_strengthen(4, 45) -> 
	#ets_goods_strengthen{id=40045,type=4,strengthen=45,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121005],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=20,coin=50224,is_upgrade=1,fail_num=0};
get_strengthen(4, 46) -> 
	#ets_goods_strengthen{id=40046,type=4,strengthen=46,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=7,coin=52654,is_upgrade=0,fail_num=0};
get_strengthen(4, 47) -> 
	#ets_goods_strengthen{id=40047,type=4,strengthen=47,sratio=[6200,6200,6200,6200,6200],cratio=62,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=7,coin=55084,is_upgrade=0,fail_num=0};
get_strengthen(4, 48) -> 
	#ets_goods_strengthen{id=40048,type=4,strengthen=48,sratio=[5700,5700,5700,5700,5700],cratio=57,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=7,coin=57514,is_upgrade=0,fail_num=0};
get_strengthen(4, 49) -> 
	#ets_goods_strengthen{id=40049,type=4,strengthen=49,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=59944,is_upgrade=0,fail_num=0};
get_strengthen(4, 50) -> 
	#ets_goods_strengthen{id=40050,type=4,strengthen=50,sratio=[2500,2500,2500,2500,2500],cratio=25,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=62375,is_upgrade=0,fail_num=0};
get_strengthen(4, 51) -> 
	#ets_goods_strengthen{id=40051,type=4,strengthen=51,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=81006,is_upgrade=0,fail_num=0};
get_strengthen(4, 52) -> 
	#ets_goods_strengthen{id=40052,type=4,strengthen=52,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=84246,is_upgrade=0,fail_num=0};
get_strengthen(4, 53) -> 
	#ets_goods_strengthen{id=40053,type=4,strengthen=53,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=87486,is_upgrade=0,fail_num=0};
get_strengthen(4, 54) -> 
	#ets_goods_strengthen{id=40054,type=4,strengthen=54,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=90727,is_upgrade=0,fail_num=0};
get_strengthen(4, 55) -> 
	#ets_goods_strengthen{id=40055,type=4,strengthen=55,sratio=[6000,6000,6000,6000,6000],cratio=60,lucky_id=[121006],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=25,coin=93967,is_upgrade=1,fail_num=0};
get_strengthen(4, 56) -> 
	#ets_goods_strengthen{id=40056,type=4,strengthen=56,sratio=[5400,5400,5400,5400,5400],cratio=54,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=9,coin=97207,is_upgrade=0,fail_num=0};
get_strengthen(4, 57) -> 
	#ets_goods_strengthen{id=40057,type=4,strengthen=57,sratio=[4800,4800,4800,4800,4800],cratio=48,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=9,coin=100447,is_upgrade=0,fail_num=0};
get_strengthen(4, 58) -> 
	#ets_goods_strengthen{id=40058,type=4,strengthen=58,sratio=[4200,4200,4200,4200,4200],cratio=42,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=9,coin=103688,is_upgrade=0,fail_num=0};
get_strengthen(4, 59) -> 
	#ets_goods_strengthen{id=40059,type=4,strengthen=59,sratio=[3600,3600,3600,3600,3600],cratio=36,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=106928,is_upgrade=0,fail_num=0};
get_strengthen(4, 60) -> 
	#ets_goods_strengthen{id=40060,type=4,strengthen=60,sratio=[2000,2000,2000,2000,2000],cratio=20,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=110168,is_upgrade=0,fail_num=0};
get_strengthen(4, 61) -> 
	#ets_goods_strengthen{id=40061,type=4,strengthen=61,sratio=[8000,8000,8000,8000,8000],cratio=80,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=148511,is_upgrade=0,fail_num=0};
get_strengthen(4, 62) -> 
	#ets_goods_strengthen{id=40062,type=4,strengthen=62,sratio=[7300,7300,7300,7300,7300],cratio=73,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=153101,is_upgrade=0,fail_num=0};
get_strengthen(4, 63) -> 
	#ets_goods_strengthen{id=40063,type=4,strengthen=63,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=157692,is_upgrade=0,fail_num=0};
get_strengthen(4, 64) -> 
	#ets_goods_strengthen{id=40064,type=4,strengthen=64,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=162282,is_upgrade=0,fail_num=0};
get_strengthen(4, 65) -> 
	#ets_goods_strengthen{id=40065,type=4,strengthen=65,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121007],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=30,coin=166872,is_upgrade=1,fail_num=0};
get_strengthen(4, 66) -> 
	#ets_goods_strengthen{id=40066,type=4,strengthen=66,sratio=[4500,4500,4500,4500,4500],cratio=45,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=11,coin=171463,is_upgrade=0,fail_num=0};
get_strengthen(4, 67) -> 
	#ets_goods_strengthen{id=40067,type=4,strengthen=67,sratio=[3800,3800,3800,3800,3800],cratio=38,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=11,coin=176053,is_upgrade=0,fail_num=0};
get_strengthen(4, 68) -> 
	#ets_goods_strengthen{id=40068,type=4,strengthen=68,sratio=[3100,3100,3100,3100,3100],cratio=31,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=11,coin=180643,is_upgrade=0,fail_num=0};
get_strengthen(4, 69) -> 
	#ets_goods_strengthen{id=40069,type=4,strengthen=69,sratio=[2400,2400,2400,2400,2400],cratio=24,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=185234,is_upgrade=0,fail_num=0};
get_strengthen(4, 70) -> 
	#ets_goods_strengthen{id=40070,type=4,strengthen=70,sratio=[1200,1200,1200,1200,1200],cratio=12,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=189824,is_upgrade=0,fail_num=0};
get_strengthen(4, 71) -> 
	#ets_goods_strengthen{id=40071,type=4,strengthen=71,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=243018,is_upgrade=0,fail_num=0};
get_strengthen(4, 72) -> 
	#ets_goods_strengthen{id=40072,type=4,strengthen=72,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=249012,is_upgrade=0,fail_num=0};
get_strengthen(4, 73) -> 
	#ets_goods_strengthen{id=40073,type=4,strengthen=73,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=255007,is_upgrade=0,fail_num=0};
get_strengthen(4, 74) -> 
	#ets_goods_strengthen{id=40074,type=4,strengthen=74,sratio=[5100,5100,5100,5100,5100],cratio=51,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=261001,is_upgrade=0,fail_num=0};
get_strengthen(4, 75) -> 
	#ets_goods_strengthen{id=40075,type=4,strengthen=75,sratio=[4300,4300,4300,4300,4300],cratio=43,lucky_id=[121008],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=35,coin=266996,is_upgrade=1,fail_num=0};
get_strengthen(4, 76) -> 
	#ets_goods_strengthen{id=40076,type=4,strengthen=76,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=13,coin=272990,is_upgrade=0,fail_num=0};
get_strengthen(4, 77) -> 
	#ets_goods_strengthen{id=40077,type=4,strengthen=77,sratio=[2700,2700,2700,2700,2700],cratio=27,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=13,coin=278985,is_upgrade=0,fail_num=0};
get_strengthen(4, 78) -> 
	#ets_goods_strengthen{id=40078,type=4,strengthen=78,sratio=[1900,1900,1900,1900,1900],cratio=19,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=13,coin=284979,is_upgrade=0,fail_num=0};
get_strengthen(4, 79) -> 
	#ets_goods_strengthen{id=40079,type=4,strengthen=79,sratio=[1100,1100,1100,1100,1100],cratio=11,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=13,coin=290973,is_upgrade=0,fail_num=0};
get_strengthen(4, 80) -> 
	#ets_goods_strengthen{id=40080,type=4,strengthen=80,sratio=[700,700,700,700,700],cratio=7,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=13,coin=296968,is_upgrade=0,fail_num=0};
get_strengthen(5, 1) -> 
	#ets_goods_strengthen{id=50001,type=5,strengthen=1,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=338,is_upgrade=0,fail_num=0};
get_strengthen(5, 2) -> 
	#ets_goods_strengthen{id=50002,type=5,strengthen=2,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,3}],stone_id=111041,stone_num=1,coin=405,is_upgrade=0,fail_num=0};
get_strengthen(5, 3) -> 
	#ets_goods_strengthen{id=50003,type=5,strengthen=3,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,4}],stone_id=111041,stone_num=1,coin=473,is_upgrade=0,fail_num=0};
get_strengthen(5, 4) -> 
	#ets_goods_strengthen{id=50004,type=5,strengthen=4,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,5}],stone_id=111041,stone_num=1,coin=540,is_upgrade=0,fail_num=0};
get_strengthen(5, 5) -> 
	#ets_goods_strengthen{id=50005,type=5,strengthen=5,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,6}],stone_id=111041,stone_num=1,coin=608,is_upgrade=0,fail_num=0};
get_strengthen(5, 6) -> 
	#ets_goods_strengthen{id=50006,type=5,strengthen=6,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,7}],stone_id=111041,stone_num=1,coin=675,is_upgrade=0,fail_num=0};
get_strengthen(5, 7) -> 
	#ets_goods_strengthen{id=50007,type=5,strengthen=7,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,8}],stone_id=111041,stone_num=1,coin=743,is_upgrade=0,fail_num=0};
get_strengthen(5, 8) -> 
	#ets_goods_strengthen{id=50008,type=5,strengthen=8,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,9}],stone_id=111041,stone_num=1,coin=810,is_upgrade=0,fail_num=0};
get_strengthen(5, 9) -> 
	#ets_goods_strengthen{id=50009,type=5,strengthen=9,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,10}],stone_id=111041,stone_num=1,coin=878,is_upgrade=0,fail_num=0};
get_strengthen(5, 10) -> 
	#ets_goods_strengthen{id=50010,type=5,strengthen=10,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,11}],stone_id=111041,stone_num=1,coin=945,is_upgrade=0,fail_num=0};
get_strengthen(5, 11) -> 
	#ets_goods_strengthen{id=50011,type=5,strengthen=11,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,12}],stone_id=111041,stone_num=2,coin=2025,is_upgrade=0,fail_num=0};
get_strengthen(5, 12) -> 
	#ets_goods_strengthen{id=50012,type=5,strengthen=12,sratio=[9800,9800,9800,9800,9800],cratio=98,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,13}],stone_id=111041,stone_num=2,coin=2126,is_upgrade=0,fail_num=0};
get_strengthen(5, 13) -> 
	#ets_goods_strengthen{id=50013,type=5,strengthen=13,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,14}],stone_id=111041,stone_num=2,coin=2228,is_upgrade=0,fail_num=0};
get_strengthen(5, 14) -> 
	#ets_goods_strengthen{id=50014,type=5,strengthen=14,sratio=[9400,9400,9400,9400,9400],cratio=94,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,15}],stone_id=111041,stone_num=2,coin=2329,is_upgrade=0,fail_num=0};
get_strengthen(5, 15) -> 
	#ets_goods_strengthen{id=50015,type=5,strengthen=15,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,16}],stone_id=111041,stone_num=2,coin=2430,is_upgrade=0,fail_num=0};
get_strengthen(5, 16) -> 
	#ets_goods_strengthen{id=50016,type=5,strengthen=16,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,17}],stone_id=111041,stone_num=2,coin=2531,is_upgrade=0,fail_num=0};
get_strengthen(5, 17) -> 
	#ets_goods_strengthen{id=50017,type=5,strengthen=17,sratio=[8800,8800,8800,8800,8800],cratio=88,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,18}],stone_id=111041,stone_num=2,coin=2633,is_upgrade=0,fail_num=0};
get_strengthen(5, 18) -> 
	#ets_goods_strengthen{id=50018,type=5,strengthen=18,sratio=[8600,8600,8600,8600,8600],cratio=86,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,19}],stone_id=111041,stone_num=2,coin=2734,is_upgrade=0,fail_num=0};
get_strengthen(5, 19) -> 
	#ets_goods_strengthen{id=50019,type=5,strengthen=19,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,20}],stone_id=111041,stone_num=2,coin=2835,is_upgrade=0,fail_num=0};
get_strengthen(5, 20) -> 
	#ets_goods_strengthen{id=50020,type=5,strengthen=20,sratio=[6500,6500,6500,6500,6500],cratio=65,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,21}],stone_id=111041,stone_num=2,coin=2936,is_upgrade=0,fail_num=0};
get_strengthen(5, 21) -> 
	#ets_goods_strengthen{id=50021,type=5,strengthen=21,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,22}],stone_id=111041,stone_num=3,coin=5400,is_upgrade=0,fail_num=0};
get_strengthen(5, 22) -> 
	#ets_goods_strengthen{id=50022,type=5,strengthen=22,sratio=[9300,9300,9300,9300,9300],cratio=93,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,23}],stone_id=111041,stone_num=3,coin=5603,is_upgrade=0,fail_num=0};
get_strengthen(5, 23) -> 
	#ets_goods_strengthen{id=50023,type=5,strengthen=23,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,24}],stone_id=111041,stone_num=3,coin=5805,is_upgrade=0,fail_num=0};
get_strengthen(5, 24) -> 
	#ets_goods_strengthen{id=50024,type=5,strengthen=24,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,25}],stone_id=111041,stone_num=3,coin=6008,is_upgrade=0,fail_num=0};
get_strengthen(5, 25) -> 
	#ets_goods_strengthen{id=50025,type=5,strengthen=25,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,26}],stone_id=111041,stone_num=3,coin=6210,is_upgrade=0,fail_num=0};
get_strengthen(5, 26) -> 
	#ets_goods_strengthen{id=50026,type=5,strengthen=26,sratio=[8100,8100,8100,8100,8100],cratio=81,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,27}],stone_id=111041,stone_num=3,coin=6413,is_upgrade=0,fail_num=0};
get_strengthen(5, 27) -> 
	#ets_goods_strengthen{id=50027,type=5,strengthen=27,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,28}],stone_id=111041,stone_num=3,coin=6615,is_upgrade=0,fail_num=0};
get_strengthen(5, 28) -> 
	#ets_goods_strengthen{id=50028,type=5,strengthen=28,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,29}],stone_id=111041,stone_num=3,coin=6818,is_upgrade=0,fail_num=0};
get_strengthen(5, 29) -> 
	#ets_goods_strengthen{id=50029,type=5,strengthen=29,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,30}],stone_id=111041,stone_num=3,coin=7021,is_upgrade=0,fail_num=0};
get_strengthen(5, 30) -> 
	#ets_goods_strengthen{id=50030,type=5,strengthen=30,sratio=[5000,5000,5000,5000,5000],cratio=50,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,31}],stone_id=111041,stone_num=3,coin=7223,is_upgrade=0,fail_num=0};
get_strengthen(5, 31) -> 
	#ets_goods_strengthen{id=50031,type=5,strengthen=31,sratio=[9500,9500,9500,9500,9500],cratio=95,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,32}],stone_id=111041,stone_num=3,coin=13501,is_upgrade=0,fail_num=0};
get_strengthen(5, 32) -> 
	#ets_goods_strengthen{id=50032,type=5,strengthen=32,sratio=[9100,9100,9100,9100,9100],cratio=91,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,33}],stone_id=111041,stone_num=3,coin=14635,is_upgrade=0,fail_num=0};
get_strengthen(5, 33) -> 
	#ets_goods_strengthen{id=50033,type=5,strengthen=33,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=3,coin=15769,is_upgrade=0,fail_num=0};
get_strengthen(5, 34) -> 
	#ets_goods_strengthen{id=50034,type=5,strengthen=34,sratio=[8300,8300,8300,8300,8300],cratio=83,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=3,coin=16903,is_upgrade=0,fail_num=0};
get_strengthen(5, 35) -> 
	#ets_goods_strengthen{id=50035,type=5,strengthen=35,sratio=[7900,7900,7900,7900,7900],cratio=79,lucky_id=[121004],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=15,coin=18037,is_upgrade=1,fail_num=0};
get_strengthen(5, 36) -> 
	#ets_goods_strengthen{id=50036,type=5,strengthen=36,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=5,coin=19171,is_upgrade=0,fail_num=0};
get_strengthen(5, 37) -> 
	#ets_goods_strengthen{id=50037,type=5,strengthen=37,sratio=[7100,7100,7100,7100,7100],cratio=71,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=5,coin=20305,is_upgrade=0,fail_num=0};
get_strengthen(5, 38) -> 
	#ets_goods_strengthen{id=50038,type=5,strengthen=38,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=5,coin=21440,is_upgrade=0,fail_num=0};
get_strengthen(5, 39) -> 
	#ets_goods_strengthen{id=50039,type=5,strengthen=39,sratio=[6300,6300,6300,6300,6300],cratio=63,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=22574,is_upgrade=0,fail_num=0};
get_strengthen(5, 40) -> 
	#ets_goods_strengthen{id=50040,type=5,strengthen=40,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=23708,is_upgrade=0,fail_num=0};
get_strengthen(5, 41) -> 
	#ets_goods_strengthen{id=50041,type=5,strengthen=41,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=40503,is_upgrade=0,fail_num=0};
get_strengthen(5, 42) -> 
	#ets_goods_strengthen{id=50042,type=5,strengthen=42,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=42933,is_upgrade=0,fail_num=0};
get_strengthen(5, 43) -> 
	#ets_goods_strengthen{id=50043,type=5,strengthen=43,sratio=[8200,8200,8200,8200,8200],cratio=82,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=45363,is_upgrade=0,fail_num=0};
get_strengthen(5, 44) -> 
	#ets_goods_strengthen{id=50044,type=5,strengthen=44,sratio=[7700,7700,7700,7700,7700],cratio=77,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=47794,is_upgrade=0,fail_num=0};
get_strengthen(5, 45) -> 
	#ets_goods_strengthen{id=50045,type=5,strengthen=45,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121005],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=20,coin=50224,is_upgrade=1,fail_num=0};
get_strengthen(5, 46) -> 
	#ets_goods_strengthen{id=50046,type=5,strengthen=46,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=7,coin=52654,is_upgrade=0,fail_num=0};
get_strengthen(5, 47) -> 
	#ets_goods_strengthen{id=50047,type=5,strengthen=47,sratio=[6200,6200,6200,6200,6200],cratio=62,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=7,coin=55084,is_upgrade=0,fail_num=0};
get_strengthen(5, 48) -> 
	#ets_goods_strengthen{id=50048,type=5,strengthen=48,sratio=[5700,5700,5700,5700,5700],cratio=57,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=7,coin=57514,is_upgrade=0,fail_num=0};
get_strengthen(5, 49) -> 
	#ets_goods_strengthen{id=50049,type=5,strengthen=49,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=59944,is_upgrade=0,fail_num=0};
get_strengthen(5, 50) -> 
	#ets_goods_strengthen{id=50050,type=5,strengthen=50,sratio=[2500,2500,2500,2500,2500],cratio=25,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=62375,is_upgrade=0,fail_num=0};
get_strengthen(5, 51) -> 
	#ets_goods_strengthen{id=50051,type=5,strengthen=51,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=81006,is_upgrade=0,fail_num=0};
get_strengthen(5, 52) -> 
	#ets_goods_strengthen{id=50052,type=5,strengthen=52,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=84246,is_upgrade=0,fail_num=0};
get_strengthen(5, 53) -> 
	#ets_goods_strengthen{id=50053,type=5,strengthen=53,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=87486,is_upgrade=0,fail_num=0};
get_strengthen(5, 54) -> 
	#ets_goods_strengthen{id=50054,type=5,strengthen=54,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=90727,is_upgrade=0,fail_num=0};
get_strengthen(5, 55) -> 
	#ets_goods_strengthen{id=50055,type=5,strengthen=55,sratio=[6000,6000,6000,6000,6000],cratio=60,lucky_id=[121006],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=25,coin=93967,is_upgrade=1,fail_num=0};
get_strengthen(5, 56) -> 
	#ets_goods_strengthen{id=50056,type=5,strengthen=56,sratio=[5400,5400,5400,5400,5400],cratio=54,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=9,coin=97207,is_upgrade=0,fail_num=0};
get_strengthen(5, 57) -> 
	#ets_goods_strengthen{id=50057,type=5,strengthen=57,sratio=[4800,4800,4800,4800,4800],cratio=48,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=9,coin=100447,is_upgrade=0,fail_num=0};
get_strengthen(5, 58) -> 
	#ets_goods_strengthen{id=50058,type=5,strengthen=58,sratio=[4200,4200,4200,4200,4200],cratio=42,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=9,coin=103688,is_upgrade=0,fail_num=0};
get_strengthen(5, 59) -> 
	#ets_goods_strengthen{id=50059,type=5,strengthen=59,sratio=[3600,3600,3600,3600,3600],cratio=36,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=106928,is_upgrade=0,fail_num=0};
get_strengthen(5, 60) -> 
	#ets_goods_strengthen{id=50060,type=5,strengthen=60,sratio=[2000,2000,2000,2000,2000],cratio=20,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=110168,is_upgrade=0,fail_num=0};
get_strengthen(5, 61) -> 
	#ets_goods_strengthen{id=50061,type=5,strengthen=61,sratio=[8000,8000,8000,8000,8000],cratio=80,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=148511,is_upgrade=0,fail_num=0};
get_strengthen(5, 62) -> 
	#ets_goods_strengthen{id=50062,type=5,strengthen=62,sratio=[7300,7300,7300,7300,7300],cratio=73,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=153101,is_upgrade=0,fail_num=0};
get_strengthen(5, 63) -> 
	#ets_goods_strengthen{id=50063,type=5,strengthen=63,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=157692,is_upgrade=0,fail_num=0};
get_strengthen(5, 64) -> 
	#ets_goods_strengthen{id=50064,type=5,strengthen=64,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=162282,is_upgrade=0,fail_num=0};
get_strengthen(5, 65) -> 
	#ets_goods_strengthen{id=50065,type=5,strengthen=65,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121007],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=30,coin=166872,is_upgrade=1,fail_num=0};
get_strengthen(5, 66) -> 
	#ets_goods_strengthen{id=50066,type=5,strengthen=66,sratio=[4500,4500,4500,4500,4500],cratio=45,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=11,coin=171463,is_upgrade=0,fail_num=0};
get_strengthen(5, 67) -> 
	#ets_goods_strengthen{id=50067,type=5,strengthen=67,sratio=[3800,3800,3800,3800,3800],cratio=38,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=11,coin=176053,is_upgrade=0,fail_num=0};
get_strengthen(5, 68) -> 
	#ets_goods_strengthen{id=50068,type=5,strengthen=68,sratio=[3100,3100,3100,3100,3100],cratio=31,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=11,coin=180643,is_upgrade=0,fail_num=0};
get_strengthen(5, 69) -> 
	#ets_goods_strengthen{id=50069,type=5,strengthen=69,sratio=[2400,2400,2400,2400,2400],cratio=24,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=185234,is_upgrade=0,fail_num=0};
get_strengthen(5, 70) -> 
	#ets_goods_strengthen{id=50070,type=5,strengthen=70,sratio=[1200,1200,1200,1200,1200],cratio=12,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=189824,is_upgrade=0,fail_num=0};
get_strengthen(5, 71) -> 
	#ets_goods_strengthen{id=50071,type=5,strengthen=71,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=243018,is_upgrade=0,fail_num=0};
get_strengthen(5, 72) -> 
	#ets_goods_strengthen{id=50072,type=5,strengthen=72,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=249012,is_upgrade=0,fail_num=0};
get_strengthen(5, 73) -> 
	#ets_goods_strengthen{id=50073,type=5,strengthen=73,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=255007,is_upgrade=0,fail_num=0};
get_strengthen(5, 74) -> 
	#ets_goods_strengthen{id=50074,type=5,strengthen=74,sratio=[5100,5100,5100,5100,5100],cratio=51,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=261001,is_upgrade=0,fail_num=0};
get_strengthen(5, 75) -> 
	#ets_goods_strengthen{id=50075,type=5,strengthen=75,sratio=[4300,4300,4300,4300,4300],cratio=43,lucky_id=[121008],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=35,coin=266996,is_upgrade=1,fail_num=0};
get_strengthen(5, 76) -> 
	#ets_goods_strengthen{id=50076,type=5,strengthen=76,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=13,coin=272990,is_upgrade=0,fail_num=0};
get_strengthen(5, 77) -> 
	#ets_goods_strengthen{id=50077,type=5,strengthen=77,sratio=[2700,2700,2700,2700,2700],cratio=27,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=13,coin=278985,is_upgrade=0,fail_num=0};
get_strengthen(5, 78) -> 
	#ets_goods_strengthen{id=50078,type=5,strengthen=78,sratio=[1900,1900,1900,1900,1900],cratio=19,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=13,coin=284979,is_upgrade=0,fail_num=0};
get_strengthen(5, 79) -> 
	#ets_goods_strengthen{id=50079,type=5,strengthen=79,sratio=[1100,1100,1100,1100,1100],cratio=11,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=13,coin=290973,is_upgrade=0,fail_num=0};
get_strengthen(5, 80) -> 
	#ets_goods_strengthen{id=50080,type=5,strengthen=80,sratio=[700,700,700,700,700],cratio=7,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=13,coin=296968,is_upgrade=0,fail_num=0};
get_strengthen(6, 1) -> 
	#ets_goods_strengthen{id=60001,type=6,strengthen=1,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=451,is_upgrade=0,fail_num=0};
get_strengthen(6, 2) -> 
	#ets_goods_strengthen{id=60002,type=6,strengthen=2,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=542,is_upgrade=0,fail_num=0};
get_strengthen(6, 3) -> 
	#ets_goods_strengthen{id=60003,type=6,strengthen=3,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=632,is_upgrade=0,fail_num=0};
get_strengthen(6, 4) -> 
	#ets_goods_strengthen{id=60004,type=6,strengthen=4,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=722,is_upgrade=0,fail_num=0};
get_strengthen(6, 5) -> 
	#ets_goods_strengthen{id=60005,type=6,strengthen=5,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=813,is_upgrade=0,fail_num=0};
get_strengthen(6, 6) -> 
	#ets_goods_strengthen{id=60006,type=6,strengthen=6,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=903,is_upgrade=0,fail_num=0};
get_strengthen(6, 7) -> 
	#ets_goods_strengthen{id=60007,type=6,strengthen=7,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=993,is_upgrade=0,fail_num=0};
get_strengthen(6, 8) -> 
	#ets_goods_strengthen{id=60008,type=6,strengthen=8,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1084,is_upgrade=0,fail_num=0};
get_strengthen(6, 9) -> 
	#ets_goods_strengthen{id=60009,type=6,strengthen=9,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=1174,is_upgrade=0,fail_num=0};
get_strengthen(6, 10) -> 
	#ets_goods_strengthen{id=60010,type=6,strengthen=10,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=1264,is_upgrade=1,fail_num=0};
get_strengthen(6, 11) -> 
	#ets_goods_strengthen{id=60011,type=6,strengthen=11,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=2709,is_upgrade=0,fail_num=0};
get_strengthen(6, 12) -> 
	#ets_goods_strengthen{id=60012,type=6,strengthen=12,sratio=[9800,9800,9800,9800,9800],cratio=98,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=2844,is_upgrade=0,fail_num=0};
get_strengthen(6, 13) -> 
	#ets_goods_strengthen{id=60013,type=6,strengthen=13,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=2980,is_upgrade=0,fail_num=0};
get_strengthen(6, 14) -> 
	#ets_goods_strengthen{id=60014,type=6,strengthen=14,sratio=[9400,9400,9400,9400,9400],cratio=94,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3115,is_upgrade=0,fail_num=0};
get_strengthen(6, 15) -> 
	#ets_goods_strengthen{id=60015,type=6,strengthen=15,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3251,is_upgrade=0,fail_num=0};
get_strengthen(6, 16) -> 
	#ets_goods_strengthen{id=60016,type=6,strengthen=16,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3386,is_upgrade=0,fail_num=0};
get_strengthen(6, 17) -> 
	#ets_goods_strengthen{id=60017,type=6,strengthen=17,sratio=[8800,8800,8800,8800,8800],cratio=88,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3521,is_upgrade=0,fail_num=0};
get_strengthen(6, 18) -> 
	#ets_goods_strengthen{id=60018,type=6,strengthen=18,sratio=[8600,8600,8600,8600,8600],cratio=86,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3657,is_upgrade=0,fail_num=0};
get_strengthen(6, 19) -> 
	#ets_goods_strengthen{id=60019,type=6,strengthen=19,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=2,coin=3792,is_upgrade=0,fail_num=0};
get_strengthen(6, 20) -> 
	#ets_goods_strengthen{id=60020,type=6,strengthen=20,sratio=[6500,6500,6500,6500,6500],cratio=65,lucky_id=[121002],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=10,coin=3928,is_upgrade=1,fail_num=0};
get_strengthen(6, 21) -> 
	#ets_goods_strengthen{id=60021,type=6,strengthen=21,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=7223,is_upgrade=0,fail_num=0};
get_strengthen(6, 22) -> 
	#ets_goods_strengthen{id=60022,type=6,strengthen=22,sratio=[9300,9300,9300,9300,9300],cratio=93,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=7494,is_upgrade=0,fail_num=0};
get_strengthen(6, 23) -> 
	#ets_goods_strengthen{id=60023,type=6,strengthen=23,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=7765,is_upgrade=0,fail_num=0};
get_strengthen(6, 24) -> 
	#ets_goods_strengthen{id=60024,type=6,strengthen=24,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8036,is_upgrade=0,fail_num=0};
get_strengthen(6, 25) -> 
	#ets_goods_strengthen{id=60025,type=6,strengthen=25,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8307,is_upgrade=0,fail_num=0};
get_strengthen(6, 26) -> 
	#ets_goods_strengthen{id=60026,type=6,strengthen=26,sratio=[8100,8100,8100,8100,8100],cratio=81,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8578,is_upgrade=0,fail_num=0};
get_strengthen(6, 27) -> 
	#ets_goods_strengthen{id=60027,type=6,strengthen=27,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=8849,is_upgrade=0,fail_num=0};
get_strengthen(6, 28) -> 
	#ets_goods_strengthen{id=60028,type=6,strengthen=28,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=9120,is_upgrade=0,fail_num=0};
get_strengthen(6, 29) -> 
	#ets_goods_strengthen{id=60029,type=6,strengthen=29,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=3,coin=9390,is_upgrade=0,fail_num=0};
get_strengthen(6, 30) -> 
	#ets_goods_strengthen{id=60030,type=6,strengthen=30,sratio=[5000,5000,5000,5000,5000],cratio=50,lucky_id=[121003],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=15,coin=9661,is_upgrade=1,fail_num=0};
get_strengthen(6, 31) -> 
	#ets_goods_strengthen{id=60031,type=6,strengthen=31,sratio=[9500,9500,9500,9500,9500],cratio=95,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=18058,is_upgrade=0,fail_num=0};
get_strengthen(6, 32) -> 
	#ets_goods_strengthen{id=60032,type=6,strengthen=32,sratio=[9100,9100,9100,9100,9100],cratio=91,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=19575,is_upgrade=0,fail_num=0};
get_strengthen(6, 33) -> 
	#ets_goods_strengthen{id=60033,type=6,strengthen=33,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=21092,is_upgrade=0,fail_num=0};
get_strengthen(6, 34) -> 
	#ets_goods_strengthen{id=60034,type=6,strengthen=34,sratio=[8300,8300,8300,8300,8300],cratio=83,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=22609,is_upgrade=0,fail_num=0};
get_strengthen(6, 35) -> 
	#ets_goods_strengthen{id=60035,type=6,strengthen=35,sratio=[7900,7900,7900,7900,7900],cratio=79,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=24126,is_upgrade=0,fail_num=0};
get_strengthen(6, 36) -> 
	#ets_goods_strengthen{id=60036,type=6,strengthen=36,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=25643,is_upgrade=0,fail_num=0};
get_strengthen(6, 37) -> 
	#ets_goods_strengthen{id=60037,type=6,strengthen=37,sratio=[7100,7100,7100,7100,7100],cratio=71,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=27160,is_upgrade=0,fail_num=0};
get_strengthen(6, 38) -> 
	#ets_goods_strengthen{id=60038,type=6,strengthen=38,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=28677,is_upgrade=0,fail_num=0};
get_strengthen(6, 39) -> 
	#ets_goods_strengthen{id=60039,type=6,strengthen=39,sratio=[6300,6300,6300,6300,6300],cratio=63,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=5,coin=30194,is_upgrade=0,fail_num=0};
get_strengthen(6, 40) -> 
	#ets_goods_strengthen{id=60040,type=6,strengthen=40,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121004],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=20,coin=31711,is_upgrade=1,fail_num=0};
get_strengthen(6, 41) -> 
	#ets_goods_strengthen{id=60041,type=6,strengthen=41,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=54175,is_upgrade=0,fail_num=0};
get_strengthen(6, 42) -> 
	#ets_goods_strengthen{id=60042,type=6,strengthen=42,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=57426,is_upgrade=0,fail_num=0};
get_strengthen(6, 43) -> 
	#ets_goods_strengthen{id=60043,type=6,strengthen=43,sratio=[8200,8200,8200,8200,8200],cratio=82,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=60676,is_upgrade=0,fail_num=0};
get_strengthen(6, 44) -> 
	#ets_goods_strengthen{id=60044,type=6,strengthen=44,sratio=[7700,7700,7700,7700,7700],cratio=77,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=63927,is_upgrade=0,fail_num=0};
get_strengthen(6, 45) -> 
	#ets_goods_strengthen{id=60045,type=6,strengthen=45,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=67177,is_upgrade=0,fail_num=0};
get_strengthen(6, 46) -> 
	#ets_goods_strengthen{id=60046,type=6,strengthen=46,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=70428,is_upgrade=0,fail_num=0};
get_strengthen(6, 47) -> 
	#ets_goods_strengthen{id=60047,type=6,strengthen=47,sratio=[6200,6200,6200,6200,6200],cratio=62,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=73678,is_upgrade=0,fail_num=0};
get_strengthen(6, 48) -> 
	#ets_goods_strengthen{id=60048,type=6,strengthen=48,sratio=[5700,5700,5700,5700,5700],cratio=57,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=76929,is_upgrade=0,fail_num=0};
get_strengthen(6, 49) -> 
	#ets_goods_strengthen{id=60049,type=6,strengthen=49,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=7,coin=80179,is_upgrade=0,fail_num=0};
get_strengthen(6, 50) -> 
	#ets_goods_strengthen{id=60050,type=6,strengthen=50,sratio=[2500,2500,2500,2500,2500],cratio=25,lucky_id=[121005],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=25,coin=83430,is_upgrade=1,fail_num=0};
get_strengthen(6, 51) -> 
	#ets_goods_strengthen{id=60051,type=6,strengthen=51,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=108351,is_upgrade=0,fail_num=0};
get_strengthen(6, 52) -> 
	#ets_goods_strengthen{id=60052,type=6,strengthen=52,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=112685,is_upgrade=0,fail_num=0};
get_strengthen(6, 53) -> 
	#ets_goods_strengthen{id=60053,type=6,strengthen=53,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=117019,is_upgrade=0,fail_num=0};
get_strengthen(6, 54) -> 
	#ets_goods_strengthen{id=60054,type=6,strengthen=54,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=121353,is_upgrade=0,fail_num=0};
get_strengthen(6, 55) -> 
	#ets_goods_strengthen{id=60055,type=6,strengthen=55,sratio=[6000,6000,6000,6000,6000],cratio=60,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=125687,is_upgrade=0,fail_num=0};
get_strengthen(6, 56) -> 
	#ets_goods_strengthen{id=60056,type=6,strengthen=56,sratio=[5400,5400,5400,5400,5400],cratio=54,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=130021,is_upgrade=0,fail_num=0};
get_strengthen(6, 57) -> 
	#ets_goods_strengthen{id=60057,type=6,strengthen=57,sratio=[4800,4800,4800,4800,4800],cratio=48,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=134355,is_upgrade=0,fail_num=0};
get_strengthen(6, 58) -> 
	#ets_goods_strengthen{id=60058,type=6,strengthen=58,sratio=[4200,4200,4200,4200,4200],cratio=42,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=138689,is_upgrade=0,fail_num=0};
get_strengthen(6, 59) -> 
	#ets_goods_strengthen{id=60059,type=6,strengthen=59,sratio=[3600,3600,3600,3600,3600],cratio=36,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=9,coin=143023,is_upgrade=0,fail_num=0};
get_strengthen(6, 60) -> 
	#ets_goods_strengthen{id=60060,type=6,strengthen=60,sratio=[2000,2000,2000,2000,2000],cratio=20,lucky_id=[121006],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=30,coin=147357,is_upgrade=1,fail_num=0};
get_strengthen(6, 61) -> 
	#ets_goods_strengthen{id=60061,type=6,strengthen=61,sratio=[8000,8000,8000,8000,8000],cratio=80,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=198643,is_upgrade=0,fail_num=0};
get_strengthen(6, 62) -> 
	#ets_goods_strengthen{id=60062,type=6,strengthen=62,sratio=[7300,7300,7300,7300,7300],cratio=73,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=204783,is_upgrade=0,fail_num=0};
get_strengthen(6, 63) -> 
	#ets_goods_strengthen{id=60063,type=6,strengthen=63,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=210923,is_upgrade=0,fail_num=0};
get_strengthen(6, 64) -> 
	#ets_goods_strengthen{id=60064,type=6,strengthen=64,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=217062,is_upgrade=0,fail_num=0};
get_strengthen(6, 65) -> 
	#ets_goods_strengthen{id=60065,type=6,strengthen=65,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=223202,is_upgrade=0,fail_num=0};
get_strengthen(6, 66) -> 
	#ets_goods_strengthen{id=60066,type=6,strengthen=66,sratio=[4500,4500,4500,4500,4500],cratio=45,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=229342,is_upgrade=0,fail_num=0};
get_strengthen(6, 67) -> 
	#ets_goods_strengthen{id=60067,type=6,strengthen=67,sratio=[3800,3800,3800,3800,3800],cratio=38,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=235482,is_upgrade=0,fail_num=0};
get_strengthen(6, 68) -> 
	#ets_goods_strengthen{id=60068,type=6,strengthen=68,sratio=[3100,3100,3100,3100,3100],cratio=31,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=241622,is_upgrade=0,fail_num=0};
get_strengthen(6, 69) -> 
	#ets_goods_strengthen{id=60069,type=6,strengthen=69,sratio=[2400,2400,2400,2400,2400],cratio=24,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=12,coin=247762,is_upgrade=0,fail_num=0};
get_strengthen(6, 70) -> 
	#ets_goods_strengthen{id=60070,type=6,strengthen=70,sratio=[1200,1200,1200,1200,1200],cratio=12,lucky_id=[121007],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=40,coin=253902,is_upgrade=1,fail_num=0};
get_strengthen(6, 71) -> 
	#ets_goods_strengthen{id=60071,type=6,strengthen=71,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=325052,is_upgrade=0,fail_num=0};
get_strengthen(6, 72) -> 
	#ets_goods_strengthen{id=60072,type=6,strengthen=72,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=333070,is_upgrade=0,fail_num=0};
get_strengthen(6, 73) -> 
	#ets_goods_strengthen{id=60073,type=6,strengthen=73,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=341088,is_upgrade=0,fail_num=0};
get_strengthen(6, 74) -> 
	#ets_goods_strengthen{id=60074,type=6,strengthen=74,sratio=[5100,5100,5100,5100,5100],cratio=51,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=349106,is_upgrade=0,fail_num=0};
get_strengthen(6, 75) -> 
	#ets_goods_strengthen{id=60075,type=6,strengthen=75,sratio=[4300,4300,4300,4300,4300],cratio=43,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=357124,is_upgrade=0,fail_num=0};
get_strengthen(6, 76) -> 
	#ets_goods_strengthen{id=60076,type=6,strengthen=76,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=365142,is_upgrade=0,fail_num=0};
get_strengthen(6, 77) -> 
	#ets_goods_strengthen{id=60077,type=6,strengthen=77,sratio=[2700,2700,2700,2700,2700],cratio=27,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=373160,is_upgrade=0,fail_num=0};
get_strengthen(6, 78) -> 
	#ets_goods_strengthen{id=60078,type=6,strengthen=78,sratio=[1900,1900,1900,1900,1900],cratio=19,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=381178,is_upgrade=0,fail_num=0};
get_strengthen(6, 79) -> 
	#ets_goods_strengthen{id=60079,type=6,strengthen=79,sratio=[1100,1100,1100,1100,1100],cratio=11,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=15,coin=389196,is_upgrade=0,fail_num=0};
get_strengthen(6, 80) -> 
	#ets_goods_strengthen{id=60080,type=6,strengthen=80,sratio=[700,700,700,700,700],cratio=7,lucky_id=[121008],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=50,coin=397213,is_upgrade=1,fail_num=0};
get_strengthen(7, 1) -> 
	#ets_goods_strengthen{id=70001,type=7,strengthen=1,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,2}],stone_id=111041,stone_num=1,coin=211,is_upgrade=0,fail_num=0};
get_strengthen(7, 2) -> 
	#ets_goods_strengthen{id=70002,type=7,strengthen=2,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,3}],stone_id=111041,stone_num=1,coin=253,is_upgrade=0,fail_num=0};
get_strengthen(7, 3) -> 
	#ets_goods_strengthen{id=70003,type=7,strengthen=3,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,4}],stone_id=111041,stone_num=1,coin=295,is_upgrade=0,fail_num=0};
get_strengthen(7, 4) -> 
	#ets_goods_strengthen{id=70004,type=7,strengthen=4,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,5}],stone_id=111041,stone_num=1,coin=337,is_upgrade=0,fail_num=0};
get_strengthen(7, 5) -> 
	#ets_goods_strengthen{id=70005,type=7,strengthen=5,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,6}],stone_id=111041,stone_num=1,coin=380,is_upgrade=0,fail_num=0};
get_strengthen(7, 6) -> 
	#ets_goods_strengthen{id=70006,type=7,strengthen=6,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,7}],stone_id=111041,stone_num=1,coin=422,is_upgrade=0,fail_num=0};
get_strengthen(7, 7) -> 
	#ets_goods_strengthen{id=70007,type=7,strengthen=7,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,8}],stone_id=111041,stone_num=1,coin=464,is_upgrade=0,fail_num=0};
get_strengthen(7, 8) -> 
	#ets_goods_strengthen{id=70008,type=7,strengthen=8,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,9}],stone_id=111041,stone_num=1,coin=506,is_upgrade=0,fail_num=0};
get_strengthen(7, 9) -> 
	#ets_goods_strengthen{id=70009,type=7,strengthen=9,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,10}],stone_id=111041,stone_num=1,coin=548,is_upgrade=0,fail_num=0};
get_strengthen(7, 10) -> 
	#ets_goods_strengthen{id=70010,type=7,strengthen=10,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121001],protect_id=0,fail_level=[{100, 0},{0,1},{0,11}],stone_id=111041,stone_num=1,coin=590,is_upgrade=0,fail_num=0};
get_strengthen(7, 11) -> 
	#ets_goods_strengthen{id=70011,type=7,strengthen=11,sratio=[10000,10000,10000,10000,10000],cratio=100,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,12}],stone_id=111041,stone_num=2,coin=1265,is_upgrade=0,fail_num=0};
get_strengthen(7, 12) -> 
	#ets_goods_strengthen{id=70012,type=7,strengthen=12,sratio=[9800,9800,9800,9800,9800],cratio=98,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,13}],stone_id=111041,stone_num=2,coin=1328,is_upgrade=0,fail_num=0};
get_strengthen(7, 13) -> 
	#ets_goods_strengthen{id=70013,type=7,strengthen=13,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,14}],stone_id=111041,stone_num=2,coin=1392,is_upgrade=0,fail_num=0};
get_strengthen(7, 14) -> 
	#ets_goods_strengthen{id=70014,type=7,strengthen=14,sratio=[9400,9400,9400,9400,9400],cratio=94,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,15}],stone_id=111041,stone_num=2,coin=1455,is_upgrade=0,fail_num=0};
get_strengthen(7, 15) -> 
	#ets_goods_strengthen{id=70015,type=7,strengthen=15,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,16}],stone_id=111041,stone_num=2,coin=1518,is_upgrade=0,fail_num=0};
get_strengthen(7, 16) -> 
	#ets_goods_strengthen{id=70016,type=7,strengthen=16,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,17}],stone_id=111041,stone_num=2,coin=1581,is_upgrade=0,fail_num=0};
get_strengthen(7, 17) -> 
	#ets_goods_strengthen{id=70017,type=7,strengthen=17,sratio=[8800,8800,8800,8800,8800],cratio=88,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,18}],stone_id=111041,stone_num=2,coin=1645,is_upgrade=0,fail_num=0};
get_strengthen(7, 18) -> 
	#ets_goods_strengthen{id=70018,type=7,strengthen=18,sratio=[8600,8600,8600,8600,8600],cratio=86,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,19}],stone_id=111041,stone_num=2,coin=1708,is_upgrade=0,fail_num=0};
get_strengthen(7, 19) -> 
	#ets_goods_strengthen{id=70019,type=7,strengthen=19,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,20}],stone_id=111041,stone_num=2,coin=1771,is_upgrade=0,fail_num=0};
get_strengthen(7, 20) -> 
	#ets_goods_strengthen{id=70020,type=7,strengthen=20,sratio=[6500,6500,6500,6500,6500],cratio=65,lucky_id=[121002],protect_id=0,fail_level=[{100, 0},{0,1},{0,21}],stone_id=111041,stone_num=2,coin=1834,is_upgrade=0,fail_num=0};
get_strengthen(7, 21) -> 
	#ets_goods_strengthen{id=70021,type=7,strengthen=21,sratio=[9600,9600,9600,9600,9600],cratio=96,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,22}],stone_id=111041,stone_num=3,coin=3374,is_upgrade=0,fail_num=0};
get_strengthen(7, 22) -> 
	#ets_goods_strengthen{id=70022,type=7,strengthen=22,sratio=[9300,9300,9300,9300,9300],cratio=93,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,23}],stone_id=111041,stone_num=3,coin=3500,is_upgrade=0,fail_num=0};
get_strengthen(7, 23) -> 
	#ets_goods_strengthen{id=70023,type=7,strengthen=23,sratio=[9000,9000,9000,9000,9000],cratio=90,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,24}],stone_id=111041,stone_num=3,coin=3627,is_upgrade=0,fail_num=0};
get_strengthen(7, 24) -> 
	#ets_goods_strengthen{id=70024,type=7,strengthen=24,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,25}],stone_id=111041,stone_num=3,coin=3753,is_upgrade=0,fail_num=0};
get_strengthen(7, 25) -> 
	#ets_goods_strengthen{id=70025,type=7,strengthen=25,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,26}],stone_id=111041,stone_num=3,coin=3880,is_upgrade=0,fail_num=0};
get_strengthen(7, 26) -> 
	#ets_goods_strengthen{id=70026,type=7,strengthen=26,sratio=[8100,8100,8100,8100,8100],cratio=81,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,27}],stone_id=111041,stone_num=3,coin=4006,is_upgrade=0,fail_num=0};
get_strengthen(7, 27) -> 
	#ets_goods_strengthen{id=70027,type=7,strengthen=27,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,28}],stone_id=111041,stone_num=3,coin=4133,is_upgrade=0,fail_num=0};
get_strengthen(7, 28) -> 
	#ets_goods_strengthen{id=70028,type=7,strengthen=28,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,29}],stone_id=111041,stone_num=3,coin=4259,is_upgrade=0,fail_num=0};
get_strengthen(7, 29) -> 
	#ets_goods_strengthen{id=70029,type=7,strengthen=29,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,30}],stone_id=111041,stone_num=3,coin=4386,is_upgrade=0,fail_num=0};
get_strengthen(7, 30) -> 
	#ets_goods_strengthen{id=70030,type=7,strengthen=30,sratio=[5000,5000,5000,5000,5000],cratio=50,lucky_id=[121003],protect_id=0,fail_level=[{100, 0},{0,1},{0,31}],stone_id=111041,stone_num=3,coin=4512,is_upgrade=0,fail_num=0};
get_strengthen(7, 31) -> 
	#ets_goods_strengthen{id=70031,type=7,strengthen=31,sratio=[9500,9500,9500,9500,9500],cratio=95,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,32}],stone_id=111041,stone_num=3,coin=8434,is_upgrade=0,fail_num=0};
get_strengthen(7, 32) -> 
	#ets_goods_strengthen{id=70032,type=7,strengthen=32,sratio=[9100,9100,9100,9100,9100],cratio=91,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,33}],stone_id=111041,stone_num=3,coin=9142,is_upgrade=0,fail_num=0};
get_strengthen(7, 33) -> 
	#ets_goods_strengthen{id=70033,type=7,strengthen=33,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=3,coin=9851,is_upgrade=0,fail_num=0};
get_strengthen(7, 34) -> 
	#ets_goods_strengthen{id=70034,type=7,strengthen=34,sratio=[8300,8300,8300,8300,8300],cratio=83,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=3,coin=10559,is_upgrade=0,fail_num=0};
get_strengthen(7, 35) -> 
	#ets_goods_strengthen{id=70035,type=7,strengthen=35,sratio=[7900,7900,7900,7900,7900],cratio=79,lucky_id=[121004],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=15,coin=11268,is_upgrade=1,fail_num=0};
get_strengthen(7, 36) -> 
	#ets_goods_strengthen{id=70036,type=7,strengthen=36,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=5,coin=11976,is_upgrade=0,fail_num=0};
get_strengthen(7, 37) -> 
	#ets_goods_strengthen{id=70037,type=7,strengthen=37,sratio=[7100,7100,7100,7100,7100],cratio=71,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=5,coin=12685,is_upgrade=0,fail_num=0};
get_strengthen(7, 38) -> 
	#ets_goods_strengthen{id=70038,type=7,strengthen=38,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=5,coin=13393,is_upgrade=0,fail_num=0};
get_strengthen(7, 39) -> 
	#ets_goods_strengthen{id=70039,type=7,strengthen=39,sratio=[6300,6300,6300,6300,6300],cratio=63,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=14102,is_upgrade=0,fail_num=0};
get_strengthen(7, 40) -> 
	#ets_goods_strengthen{id=70040,type=7,strengthen=40,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121004],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=14810,is_upgrade=0,fail_num=0};
get_strengthen(7, 41) -> 
	#ets_goods_strengthen{id=70041,type=7,strengthen=41,sratio=[9200,9200,9200,9200,9200],cratio=92,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=25302,is_upgrade=0,fail_num=0};
get_strengthen(7, 42) -> 
	#ets_goods_strengthen{id=70042,type=7,strengthen=42,sratio=[8700,8700,8700,8700,8700],cratio=87,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=26820,is_upgrade=0,fail_num=0};
get_strengthen(7, 43) -> 
	#ets_goods_strengthen{id=70043,type=7,strengthen=43,sratio=[8200,8200,8200,8200,8200],cratio=82,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=28338,is_upgrade=0,fail_num=0};
get_strengthen(7, 44) -> 
	#ets_goods_strengthen{id=70044,type=7,strengthen=44,sratio=[7700,7700,7700,7700,7700],cratio=77,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=5,coin=29856,is_upgrade=0,fail_num=0};
get_strengthen(7, 45) -> 
	#ets_goods_strengthen{id=70045,type=7,strengthen=45,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121005],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=20,coin=31374,is_upgrade=1,fail_num=0};
get_strengthen(7, 46) -> 
	#ets_goods_strengthen{id=70046,type=7,strengthen=46,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=7,coin=32892,is_upgrade=0,fail_num=0};
get_strengthen(7, 47) -> 
	#ets_goods_strengthen{id=70047,type=7,strengthen=47,sratio=[6200,6200,6200,6200,6200],cratio=62,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=7,coin=34410,is_upgrade=0,fail_num=0};
get_strengthen(7, 48) -> 
	#ets_goods_strengthen{id=70048,type=7,strengthen=48,sratio=[5700,5700,5700,5700,5700],cratio=57,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=7,coin=35929,is_upgrade=0,fail_num=0};
get_strengthen(7, 49) -> 
	#ets_goods_strengthen{id=70049,type=7,strengthen=49,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=37447,is_upgrade=0,fail_num=0};
get_strengthen(7, 50) -> 
	#ets_goods_strengthen{id=70050,type=7,strengthen=50,sratio=[2500,2500,2500,2500,2500],cratio=25,lucky_id=[121005],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=38965,is_upgrade=0,fail_num=0};
get_strengthen(7, 51) -> 
	#ets_goods_strengthen{id=70051,type=7,strengthen=51,sratio=[8400,8400,8400,8400,8400],cratio=84,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=50604,is_upgrade=0,fail_num=0};
get_strengthen(7, 52) -> 
	#ets_goods_strengthen{id=70052,type=7,strengthen=52,sratio=[7800,7800,7800,7800,7800],cratio=78,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=52628,is_upgrade=0,fail_num=0};
get_strengthen(7, 53) -> 
	#ets_goods_strengthen{id=70053,type=7,strengthen=53,sratio=[7200,7200,7200,7200,7200],cratio=72,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=54652,is_upgrade=0,fail_num=0};
get_strengthen(7, 54) -> 
	#ets_goods_strengthen{id=70054,type=7,strengthen=54,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=7,coin=56676,is_upgrade=0,fail_num=0};
get_strengthen(7, 55) -> 
	#ets_goods_strengthen{id=70055,type=7,strengthen=55,sratio=[6000,6000,6000,6000,6000],cratio=60,lucky_id=[121006],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=25,coin=58700,is_upgrade=1,fail_num=0};
get_strengthen(7, 56) -> 
	#ets_goods_strengthen{id=70056,type=7,strengthen=56,sratio=[5400,5400,5400,5400,5400],cratio=54,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=9,coin=60724,is_upgrade=0,fail_num=0};
get_strengthen(7, 57) -> 
	#ets_goods_strengthen{id=70057,type=7,strengthen=57,sratio=[4800,4800,4800,4800,4800],cratio=48,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=9,coin=62748,is_upgrade=0,fail_num=0};
get_strengthen(7, 58) -> 
	#ets_goods_strengthen{id=70058,type=7,strengthen=58,sratio=[4200,4200,4200,4200,4200],cratio=42,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=9,coin=64773,is_upgrade=0,fail_num=0};
get_strengthen(7, 59) -> 
	#ets_goods_strengthen{id=70059,type=7,strengthen=59,sratio=[3600,3600,3600,3600,3600],cratio=36,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=66797,is_upgrade=0,fail_num=0};
get_strengthen(7, 60) -> 
	#ets_goods_strengthen{id=70060,type=7,strengthen=60,sratio=[2000,2000,2000,2000,2000],cratio=20,lucky_id=[121006],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=68821,is_upgrade=0,fail_num=0};
get_strengthen(7, 61) -> 
	#ets_goods_strengthen{id=70061,type=7,strengthen=61,sratio=[8000,8000,8000,8000,8000],cratio=80,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=92773,is_upgrade=0,fail_num=0};
get_strengthen(7, 62) -> 
	#ets_goods_strengthen{id=70062,type=7,strengthen=62,sratio=[7300,7300,7300,7300,7300],cratio=73,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=95641,is_upgrade=0,fail_num=0};
get_strengthen(7, 63) -> 
	#ets_goods_strengthen{id=70063,type=7,strengthen=63,sratio=[6600,6600,6600,6600,6600],cratio=66,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=98508,is_upgrade=0,fail_num=0};
get_strengthen(7, 64) -> 
	#ets_goods_strengthen{id=70064,type=7,strengthen=64,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=9,coin=101376,is_upgrade=0,fail_num=0};
get_strengthen(7, 65) -> 
	#ets_goods_strengthen{id=70065,type=7,strengthen=65,sratio=[5200,5200,5200,5200,5200],cratio=52,lucky_id=[121007],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=30,coin=104243,is_upgrade=1,fail_num=0};
get_strengthen(7, 66) -> 
	#ets_goods_strengthen{id=70066,type=7,strengthen=66,sratio=[4500,4500,4500,4500,4500],cratio=45,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=11,coin=107111,is_upgrade=0,fail_num=0};
get_strengthen(7, 67) -> 
	#ets_goods_strengthen{id=70067,type=7,strengthen=67,sratio=[3800,3800,3800,3800,3800],cratio=38,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=11,coin=109978,is_upgrade=0,fail_num=0};
get_strengthen(7, 68) -> 
	#ets_goods_strengthen{id=70068,type=7,strengthen=68,sratio=[3100,3100,3100,3100,3100],cratio=31,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=11,coin=112846,is_upgrade=0,fail_num=0};
get_strengthen(7, 69) -> 
	#ets_goods_strengthen{id=70069,type=7,strengthen=69,sratio=[2400,2400,2400,2400,2400],cratio=24,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=115713,is_upgrade=0,fail_num=0};
get_strengthen(7, 70) -> 
	#ets_goods_strengthen{id=70070,type=7,strengthen=70,sratio=[1200,1200,1200,1200,1200],cratio=12,lucky_id=[121007],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=118581,is_upgrade=0,fail_num=0};
get_strengthen(7, 71) -> 
	#ets_goods_strengthen{id=70071,type=7,strengthen=71,sratio=[7500,7500,7500,7500,7500],cratio=75,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=151811,is_upgrade=0,fail_num=0};
get_strengthen(7, 72) -> 
	#ets_goods_strengthen{id=70072,type=7,strengthen=72,sratio=[6700,6700,6700,6700,6700],cratio=67,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=155555,is_upgrade=0,fail_num=0};
get_strengthen(7, 73) -> 
	#ets_goods_strengthen{id=70073,type=7,strengthen=73,sratio=[5900,5900,5900,5900,5900],cratio=59,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=159300,is_upgrade=0,fail_num=0};
get_strengthen(7, 74) -> 
	#ets_goods_strengthen{id=70074,type=7,strengthen=74,sratio=[5100,5100,5100,5100,5100],cratio=51,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=11,coin=163045,is_upgrade=0,fail_num=0};
get_strengthen(7, 75) -> 
	#ets_goods_strengthen{id=70075,type=7,strengthen=75,sratio=[4300,4300,4300,4300,4300],cratio=43,lucky_id=[121008],protect_id=0,fail_level=[{20, 0},{50,1},{30,2}],stone_id=111041,stone_num=35,coin=166789,is_upgrade=1,fail_num=0};
get_strengthen(7, 76) -> 
	#ets_goods_strengthen{id=70076,type=7,strengthen=76,sratio=[3500,3500,3500,3500,3500],cratio=35,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,34}],stone_id=111041,stone_num=13,coin=170534,is_upgrade=0,fail_num=0};
get_strengthen(7, 77) -> 
	#ets_goods_strengthen{id=70077,type=7,strengthen=77,sratio=[2700,2700,2700,2700,2700],cratio=27,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,35}],stone_id=111041,stone_num=13,coin=174279,is_upgrade=0,fail_num=0};
get_strengthen(7, 78) -> 
	#ets_goods_strengthen{id=70078,type=7,strengthen=78,sratio=[1900,1900,1900,1900,1900],cratio=19,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,36}],stone_id=111041,stone_num=13,coin=178023,is_upgrade=0,fail_num=0};
get_strengthen(7, 79) -> 
	#ets_goods_strengthen{id=70079,type=7,strengthen=79,sratio=[1100,1100,1100,1100,1100],cratio=11,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=13,coin=181768,is_upgrade=0,fail_num=0};
get_strengthen(7, 80) -> 
	#ets_goods_strengthen{id=70080,type=7,strengthen=80,sratio=[700,700,700,700,700],cratio=7,lucky_id=[121008],protect_id=0,fail_level=[{100, 0},{0,1},{0,37}],stone_id=111041,stone_num=13,coin=185513,is_upgrade=0,fail_num=0};
get_strengthen(_, _) ->
	[].



%%通过装备类型，强化等级，装备等级获取数据

get_stren7_reward(1, 9, 1) -> 
	[{7, 10}, {53, 0}];
get_stren7_reward(_, _, _) ->
	[].



%%通过强化等级获取强化奖励基础加成
get_stren_factor(1,1) -> 0;
get_stren_factor(2,1) -> 0;
get_stren_factor(3,1) -> 0;
get_stren_factor(4,1) -> 0;
get_stren_factor(5,1) -> 0;
get_stren_factor(6,1) -> 0;
get_stren_factor(7,1) -> 0;
get_stren_factor(1,2) -> 0;
get_stren_factor(2,2) -> 0;
get_stren_factor(3,2) -> 0;
get_stren_factor(4,2) -> 0;
get_stren_factor(5,2) -> 0;
get_stren_factor(6,2) -> 0;
get_stren_factor(7,2) -> 0;
get_stren_factor(1,3) -> 0;
get_stren_factor(2,3) -> 0;
get_stren_factor(3,3) -> 0;
get_stren_factor(4,3) -> 0;
get_stren_factor(5,3) -> 0;
get_stren_factor(6,3) -> 0;
get_stren_factor(7,3) -> 0;
get_stren_factor(1,4) -> 0;
get_stren_factor(2,4) -> 0;
get_stren_factor(3,4) -> 0;
get_stren_factor(4,4) -> 0;
get_stren_factor(5,4) -> 0;
get_stren_factor(6,4) -> 0;
get_stren_factor(7,4) -> 0;
get_stren_factor(1,5) -> 0;
get_stren_factor(2,5) -> 0;
get_stren_factor(3,5) -> 0;
get_stren_factor(4,5) -> 0;
get_stren_factor(5,5) -> 0;
get_stren_factor(6,5) -> 0;
get_stren_factor(7,5) -> 0;
get_stren_factor(1,6) -> 0;
get_stren_factor(2,6) -> 0;
get_stren_factor(3,6) -> 0;
get_stren_factor(4,6) -> 0;
get_stren_factor(5,6) -> 0;
get_stren_factor(6,6) -> 0;
get_stren_factor(7,6) -> 0;
get_stren_factor(1,7) -> 0;
get_stren_factor(2,7) -> 0;
get_stren_factor(3,7) -> 0;
get_stren_factor(4,7) -> 0;
get_stren_factor(5,7) -> 0;
get_stren_factor(6,7) -> 0;
get_stren_factor(7,7) -> 0;
get_stren_factor(1,8) -> 0;
get_stren_factor(2,8) -> 0;
get_stren_factor(3,8) -> 0;
get_stren_factor(4,8) -> 0;
get_stren_factor(5,8) -> 0;
get_stren_factor(6,8) -> 0;
get_stren_factor(7,8) -> 0;
get_stren_factor(1,9) -> 0;
get_stren_factor(2,9) -> 0;
get_stren_factor(3,9) -> 0;
get_stren_factor(4,9) -> 0;
get_stren_factor(5,9) -> 0;
get_stren_factor(6,9) -> 0;
get_stren_factor(7,9) -> 0;
get_stren_factor(1,10) -> 0;
get_stren_factor(2,10) -> 0;
get_stren_factor(3,10) -> 0;
get_stren_factor(4,10) -> 0;
get_stren_factor(5,10) -> 0;
get_stren_factor(6,10) -> 0;
get_stren_factor(7,10) -> 0;
get_stren_factor(1,11) -> 0;
get_stren_factor(2,11) -> 0;
get_stren_factor(3,11) -> 0;
get_stren_factor(4,11) -> 0;
get_stren_factor(5,11) -> 0;
get_stren_factor(6,11) -> 0;
get_stren_factor(7,11) -> 0;
get_stren_factor(1,12) -> 0;
get_stren_factor(2,12) -> 0;
get_stren_factor(3,12) -> 0;
get_stren_factor(4,12) -> 0;
get_stren_factor(5,12) -> 0;
get_stren_factor(6,12) -> 0;
get_stren_factor(7,12) -> 0;
get_stren_factor(1,13) -> 0;
get_stren_factor(2,13) -> 0;
get_stren_factor(3,13) -> 0;
get_stren_factor(4,13) -> 0;
get_stren_factor(5,13) -> 0;
get_stren_factor(6,13) -> 0;
get_stren_factor(7,13) -> 0;
get_stren_factor(1,14) -> 0;
get_stren_factor(2,14) -> 0;
get_stren_factor(3,14) -> 0;
get_stren_factor(4,14) -> 0;
get_stren_factor(5,14) -> 0;
get_stren_factor(6,14) -> 0;
get_stren_factor(7,14) -> 0;
get_stren_factor(1,15) -> 0;
get_stren_factor(2,15) -> 0;
get_stren_factor(3,15) -> 0;
get_stren_factor(4,15) -> 0;
get_stren_factor(5,15) -> 0;
get_stren_factor(6,15) -> 0;
get_stren_factor(7,15) -> 0;
get_stren_factor(1,16) -> 0;
get_stren_factor(2,16) -> 0;
get_stren_factor(3,16) -> 0;
get_stren_factor(4,16) -> 0;
get_stren_factor(5,16) -> 0;
get_stren_factor(6,16) -> 0;
get_stren_factor(7,16) -> 0;
get_stren_factor(1,17) -> 0;
get_stren_factor(2,17) -> 0;
get_stren_factor(3,17) -> 0;
get_stren_factor(4,17) -> 0;
get_stren_factor(5,17) -> 0;
get_stren_factor(6,17) -> 0;
get_stren_factor(7,17) -> 0;
get_stren_factor(1,18) -> 0;
get_stren_factor(2,18) -> 0;
get_stren_factor(3,18) -> 0;
get_stren_factor(4,18) -> 0;
get_stren_factor(5,18) -> 0;
get_stren_factor(6,18) -> 0;
get_stren_factor(7,18) -> 0;
get_stren_factor(1,19) -> 0;
get_stren_factor(2,19) -> 0;
get_stren_factor(3,19) -> 0;
get_stren_factor(4,19) -> 0;
get_stren_factor(5,19) -> 0;
get_stren_factor(6,19) -> 0;
get_stren_factor(7,19) -> 0;
get_stren_factor(1,20) -> 0;
get_stren_factor(2,20) -> 0;
get_stren_factor(3,20) -> 0;
get_stren_factor(4,20) -> 0;
get_stren_factor(5,20) -> 0;
get_stren_factor(6,20) -> 0;
get_stren_factor(7,20) -> 0;
get_stren_factor(1,21) -> 0;
get_stren_factor(2,21) -> 0;
get_stren_factor(3,21) -> 0;
get_stren_factor(4,21) -> 0;
get_stren_factor(5,21) -> 0;
get_stren_factor(6,21) -> 0;
get_stren_factor(7,21) -> 0;
get_stren_factor(1,22) -> 0;
get_stren_factor(2,22) -> 0;
get_stren_factor(3,22) -> 0;
get_stren_factor(4,22) -> 0;
get_stren_factor(5,22) -> 0;
get_stren_factor(6,22) -> 0;
get_stren_factor(7,22) -> 0;
get_stren_factor(1,23) -> 0;
get_stren_factor(2,23) -> 0;
get_stren_factor(3,23) -> 0;
get_stren_factor(4,23) -> 0;
get_stren_factor(5,23) -> 0;
get_stren_factor(6,23) -> 0;
get_stren_factor(7,23) -> 0;
get_stren_factor(1,24) -> 0;
get_stren_factor(2,24) -> 0;
get_stren_factor(3,24) -> 0;
get_stren_factor(4,24) -> 0;
get_stren_factor(5,24) -> 0;
get_stren_factor(6,24) -> 0;
get_stren_factor(7,24) -> 0;
get_stren_factor(1,25) -> 0;
get_stren_factor(2,25) -> 0;
get_stren_factor(3,25) -> 0;
get_stren_factor(4,25) -> 0;
get_stren_factor(5,25) -> 0;
get_stren_factor(6,25) -> 0;
get_stren_factor(7,25) -> 0;
get_stren_factor(1,26) -> 0;
get_stren_factor(2,26) -> 0;
get_stren_factor(3,26) -> 0;
get_stren_factor(4,26) -> 0;
get_stren_factor(5,26) -> 0;
get_stren_factor(6,26) -> 0;
get_stren_factor(7,26) -> 0;
get_stren_factor(1,27) -> 0;
get_stren_factor(2,27) -> 0;
get_stren_factor(3,27) -> 0;
get_stren_factor(4,27) -> 0;
get_stren_factor(5,27) -> 0;
get_stren_factor(6,27) -> 0;
get_stren_factor(7,27) -> 0;
get_stren_factor(1,28) -> 0;
get_stren_factor(2,28) -> 0;
get_stren_factor(3,28) -> 0;
get_stren_factor(4,28) -> 0;
get_stren_factor(5,28) -> 0;
get_stren_factor(6,28) -> 0;
get_stren_factor(7,28) -> 0;
get_stren_factor(1,29) -> 0;
get_stren_factor(2,29) -> 0;
get_stren_factor(3,29) -> 0;
get_stren_factor(4,29) -> 0;
get_stren_factor(5,29) -> 0;
get_stren_factor(6,29) -> 0;
get_stren_factor(7,29) -> 0;
get_stren_factor(1,30) -> 0;
get_stren_factor(2,30) -> 0;
get_stren_factor(3,30) -> 0;
get_stren_factor(4,30) -> 0;
get_stren_factor(5,30) -> 0;
get_stren_factor(6,30) -> 0;
get_stren_factor(7,30) -> 0;
get_stren_factor(1,31) -> 0;
get_stren_factor(2,31) -> 0;
get_stren_factor(3,31) -> 0;
get_stren_factor(4,31) -> 0;
get_stren_factor(5,31) -> 0;
get_stren_factor(6,31) -> 0;
get_stren_factor(7,31) -> 0;
get_stren_factor(1,32) -> 0;
get_stren_factor(2,32) -> 0;
get_stren_factor(3,32) -> 0;
get_stren_factor(4,32) -> 0;
get_stren_factor(5,32) -> 0;
get_stren_factor(6,32) -> 0;
get_stren_factor(7,32) -> 0;
get_stren_factor(1,33) -> 0;
get_stren_factor(2,33) -> 0;
get_stren_factor(3,33) -> 0;
get_stren_factor(4,33) -> 0;
get_stren_factor(5,33) -> 0;
get_stren_factor(6,33) -> 0;
get_stren_factor(7,33) -> 0;
get_stren_factor(1,34) -> 0;
get_stren_factor(2,34) -> 0;
get_stren_factor(3,34) -> 0;
get_stren_factor(4,34) -> 0;
get_stren_factor(5,34) -> 0;
get_stren_factor(6,34) -> 0;
get_stren_factor(7,34) -> 0;
get_stren_factor(1,35) -> 0;
get_stren_factor(2,35) -> 0;
get_stren_factor(3,35) -> 0;
get_stren_factor(4,35) -> 0;
get_stren_factor(5,35) -> 0;
get_stren_factor(6,35) -> 0;
get_stren_factor(7,35) -> 0;
get_stren_factor(1,36) -> 0;
get_stren_factor(2,36) -> 0;
get_stren_factor(3,36) -> 0;
get_stren_factor(4,36) -> 0;
get_stren_factor(5,36) -> 0;
get_stren_factor(6,36) -> 0;
get_stren_factor(7,36) -> 0;
get_stren_factor(1,37) -> 0;
get_stren_factor(2,37) -> 0;
get_stren_factor(3,37) -> 0;
get_stren_factor(4,37) -> 0;
get_stren_factor(5,37) -> 0;
get_stren_factor(6,37) -> 0;
get_stren_factor(7,37) -> 0;
get_stren_factor(1,38) -> 0;
get_stren_factor(2,38) -> 0;
get_stren_factor(3,38) -> 0;
get_stren_factor(4,38) -> 0;
get_stren_factor(5,38) -> 0;
get_stren_factor(6,38) -> 0;
get_stren_factor(7,38) -> 0;
get_stren_factor(1,39) -> 0;
get_stren_factor(2,39) -> 0;
get_stren_factor(3,39) -> 0;
get_stren_factor(4,39) -> 0;
get_stren_factor(5,39) -> 0;
get_stren_factor(6,39) -> 0;
get_stren_factor(7,39) -> 0;
get_stren_factor(1,40) -> 0;
get_stren_factor(2,40) -> 0;
get_stren_factor(3,40) -> 0;
get_stren_factor(4,40) -> 0;
get_stren_factor(5,40) -> 0;
get_stren_factor(6,40) -> 0;
get_stren_factor(7,40) -> 0;
get_stren_factor(1,41) -> 0;
get_stren_factor(2,41) -> 0;
get_stren_factor(3,41) -> 0;
get_stren_factor(4,41) -> 0;
get_stren_factor(5,41) -> 0;
get_stren_factor(6,41) -> 0;
get_stren_factor(7,41) -> 0;
get_stren_factor(1,42) -> 0;
get_stren_factor(2,42) -> 0;
get_stren_factor(3,42) -> 0;
get_stren_factor(4,42) -> 0;
get_stren_factor(5,42) -> 0;
get_stren_factor(6,42) -> 0;
get_stren_factor(7,42) -> 0;
get_stren_factor(1,43) -> 0;
get_stren_factor(2,43) -> 0;
get_stren_factor(3,43) -> 0;
get_stren_factor(4,43) -> 0;
get_stren_factor(5,43) -> 0;
get_stren_factor(6,43) -> 0;
get_stren_factor(7,43) -> 0;
get_stren_factor(1,44) -> 0;
get_stren_factor(2,44) -> 0;
get_stren_factor(3,44) -> 0;
get_stren_factor(4,44) -> 0;
get_stren_factor(5,44) -> 0;
get_stren_factor(6,44) -> 0;
get_stren_factor(7,44) -> 0;
get_stren_factor(1,45) -> 0;
get_stren_factor(2,45) -> 0;
get_stren_factor(3,45) -> 0;
get_stren_factor(4,45) -> 0;
get_stren_factor(5,45) -> 0;
get_stren_factor(6,45) -> 0;
get_stren_factor(7,45) -> 0;
get_stren_factor(1,46) -> 0;
get_stren_factor(2,46) -> 0;
get_stren_factor(3,46) -> 0;
get_stren_factor(4,46) -> 0;
get_stren_factor(5,46) -> 0;
get_stren_factor(6,46) -> 0;
get_stren_factor(7,46) -> 0;
get_stren_factor(1,47) -> 0;
get_stren_factor(2,47) -> 0;
get_stren_factor(3,47) -> 0;
get_stren_factor(4,47) -> 0;
get_stren_factor(5,47) -> 0;
get_stren_factor(6,47) -> 0;
get_stren_factor(7,47) -> 0;
get_stren_factor(1,48) -> 0;
get_stren_factor(2,48) -> 0;
get_stren_factor(3,48) -> 0;
get_stren_factor(4,48) -> 0;
get_stren_factor(5,48) -> 0;
get_stren_factor(6,48) -> 0;
get_stren_factor(7,48) -> 0;
get_stren_factor(1,49) -> 0;
get_stren_factor(2,49) -> 0;
get_stren_factor(3,49) -> 0;
get_stren_factor(4,49) -> 0;
get_stren_factor(5,49) -> 0;
get_stren_factor(6,49) -> 0;
get_stren_factor(7,49) -> 0;
get_stren_factor(1,50) -> 0;
get_stren_factor(2,50) -> 0;
get_stren_factor(3,50) -> 0;
get_stren_factor(4,50) -> 0;
get_stren_factor(5,50) -> 0;
get_stren_factor(6,50) -> 0;
get_stren_factor(7,50) -> 0;
get_stren_factor(1,51) -> 0;
get_stren_factor(2,51) -> 0;
get_stren_factor(3,51) -> 0;
get_stren_factor(4,51) -> 0;
get_stren_factor(5,51) -> 0;
get_stren_factor(6,51) -> 0;
get_stren_factor(7,51) -> 0;
get_stren_factor(1,52) -> 0;
get_stren_factor(2,52) -> 0;
get_stren_factor(3,52) -> 0;
get_stren_factor(4,52) -> 0;
get_stren_factor(5,52) -> 0;
get_stren_factor(6,52) -> 0;
get_stren_factor(7,52) -> 0;
get_stren_factor(1,53) -> 0;
get_stren_factor(2,53) -> 0;
get_stren_factor(3,53) -> 0;
get_stren_factor(4,53) -> 0;
get_stren_factor(5,53) -> 0;
get_stren_factor(6,53) -> 0;
get_stren_factor(7,53) -> 0;
get_stren_factor(1,54) -> 0;
get_stren_factor(2,54) -> 0;
get_stren_factor(3,54) -> 0;
get_stren_factor(4,54) -> 0;
get_stren_factor(5,54) -> 0;
get_stren_factor(6,54) -> 0;
get_stren_factor(7,54) -> 0;
get_stren_factor(1,55) -> 0;
get_stren_factor(2,55) -> 0;
get_stren_factor(3,55) -> 0;
get_stren_factor(4,55) -> 0;
get_stren_factor(5,55) -> 0;
get_stren_factor(6,55) -> 0;
get_stren_factor(7,55) -> 0;
get_stren_factor(1,56) -> 0;
get_stren_factor(2,56) -> 0;
get_stren_factor(3,56) -> 0;
get_stren_factor(4,56) -> 0;
get_stren_factor(5,56) -> 0;
get_stren_factor(6,56) -> 0;
get_stren_factor(7,56) -> 0;
get_stren_factor(1,57) -> 0;
get_stren_factor(2,57) -> 0;
get_stren_factor(3,57) -> 0;
get_stren_factor(4,57) -> 0;
get_stren_factor(5,57) -> 0;
get_stren_factor(6,57) -> 0;
get_stren_factor(7,57) -> 0;
get_stren_factor(1,58) -> 0;
get_stren_factor(2,58) -> 0;
get_stren_factor(3,58) -> 0;
get_stren_factor(4,58) -> 0;
get_stren_factor(5,58) -> 0;
get_stren_factor(6,58) -> 0;
get_stren_factor(7,58) -> 0;
get_stren_factor(1,59) -> 0;
get_stren_factor(2,59) -> 0;
get_stren_factor(3,59) -> 0;
get_stren_factor(4,59) -> 0;
get_stren_factor(5,59) -> 0;
get_stren_factor(6,59) -> 0;
get_stren_factor(7,59) -> 0;
get_stren_factor(1,60) -> 0;
get_stren_factor(2,60) -> 0;
get_stren_factor(3,60) -> 0;
get_stren_factor(4,60) -> 0;
get_stren_factor(5,60) -> 0;
get_stren_factor(6,60) -> 0;
get_stren_factor(7,60) -> 0;
get_stren_factor(1,61) -> 0;
get_stren_factor(2,61) -> 0;
get_stren_factor(3,61) -> 0;
get_stren_factor(4,61) -> 0;
get_stren_factor(5,61) -> 0;
get_stren_factor(6,61) -> 0;
get_stren_factor(7,61) -> 0;
get_stren_factor(1,62) -> 0;
get_stren_factor(2,62) -> 0;
get_stren_factor(3,62) -> 0;
get_stren_factor(4,62) -> 0;
get_stren_factor(5,62) -> 0;
get_stren_factor(6,62) -> 0;
get_stren_factor(7,62) -> 0;
get_stren_factor(1,63) -> 0;
get_stren_factor(2,63) -> 0;
get_stren_factor(3,63) -> 0;
get_stren_factor(4,63) -> 0;
get_stren_factor(5,63) -> 0;
get_stren_factor(6,63) -> 0;
get_stren_factor(7,63) -> 0;
get_stren_factor(1,64) -> 0;
get_stren_factor(2,64) -> 0;
get_stren_factor(3,64) -> 0;
get_stren_factor(4,64) -> 0;
get_stren_factor(5,64) -> 0;
get_stren_factor(6,64) -> 0;
get_stren_factor(7,64) -> 0;
get_stren_factor(1,65) -> 0;
get_stren_factor(2,65) -> 0;
get_stren_factor(3,65) -> 0;
get_stren_factor(4,65) -> 0;
get_stren_factor(5,65) -> 0;
get_stren_factor(6,65) -> 0;
get_stren_factor(7,65) -> 0;
get_stren_factor(1,66) -> 0;
get_stren_factor(2,66) -> 0;
get_stren_factor(3,66) -> 0;
get_stren_factor(4,66) -> 0;
get_stren_factor(5,66) -> 0;
get_stren_factor(6,66) -> 0;
get_stren_factor(7,66) -> 0;
get_stren_factor(1,67) -> 0;
get_stren_factor(2,67) -> 0;
get_stren_factor(3,67) -> 0;
get_stren_factor(4,67) -> 0;
get_stren_factor(5,67) -> 0;
get_stren_factor(6,67) -> 0;
get_stren_factor(7,67) -> 0;
get_stren_factor(1,68) -> 0;
get_stren_factor(2,68) -> 0;
get_stren_factor(3,68) -> 0;
get_stren_factor(4,68) -> 0;
get_stren_factor(5,68) -> 0;
get_stren_factor(6,68) -> 0;
get_stren_factor(7,68) -> 0;
get_stren_factor(1,69) -> 0;
get_stren_factor(2,69) -> 0;
get_stren_factor(3,69) -> 0;
get_stren_factor(4,69) -> 0;
get_stren_factor(5,69) -> 0;
get_stren_factor(6,69) -> 0;
get_stren_factor(7,69) -> 0;
get_stren_factor(1,70) -> 0;
get_stren_factor(2,70) -> 0;
get_stren_factor(3,70) -> 0;
get_stren_factor(4,70) -> 0;
get_stren_factor(5,70) -> 0;
get_stren_factor(6,70) -> 0;
get_stren_factor(7,70) -> 0;
get_stren_factor(1,71) -> 0;
get_stren_factor(2,71) -> 0;
get_stren_factor(3,71) -> 0;
get_stren_factor(4,71) -> 0;
get_stren_factor(5,71) -> 0;
get_stren_factor(6,71) -> 0;
get_stren_factor(7,71) -> 0;
get_stren_factor(1,72) -> 0;
get_stren_factor(2,72) -> 0;
get_stren_factor(3,72) -> 0;
get_stren_factor(4,72) -> 0;
get_stren_factor(5,72) -> 0;
get_stren_factor(6,72) -> 0;
get_stren_factor(7,72) -> 0;
get_stren_factor(1,73) -> 0;
get_stren_factor(2,73) -> 0;
get_stren_factor(3,73) -> 0;
get_stren_factor(4,73) -> 0;
get_stren_factor(5,73) -> 0;
get_stren_factor(6,73) -> 0;
get_stren_factor(7,73) -> 0;
get_stren_factor(1,74) -> 0;
get_stren_factor(2,74) -> 0;
get_stren_factor(3,74) -> 0;
get_stren_factor(4,74) -> 0;
get_stren_factor(5,74) -> 0;
get_stren_factor(6,74) -> 0;
get_stren_factor(7,74) -> 0;
get_stren_factor(1,75) -> 0;
get_stren_factor(2,75) -> 0;
get_stren_factor(3,75) -> 0;
get_stren_factor(4,75) -> 0;
get_stren_factor(5,75) -> 0;
get_stren_factor(6,75) -> 0;
get_stren_factor(7,75) -> 0;
get_stren_factor(1,76) -> 0;
get_stren_factor(2,76) -> 0;
get_stren_factor(3,76) -> 0;
get_stren_factor(4,76) -> 0;
get_stren_factor(5,76) -> 0;
get_stren_factor(6,76) -> 0;
get_stren_factor(7,76) -> 0;
get_stren_factor(1,77) -> 0;
get_stren_factor(2,77) -> 0;
get_stren_factor(3,77) -> 0;
get_stren_factor(4,77) -> 0;
get_stren_factor(5,77) -> 0;
get_stren_factor(6,77) -> 0;
get_stren_factor(7,77) -> 0;
get_stren_factor(1,78) -> 0;
get_stren_factor(2,78) -> 0;
get_stren_factor(3,78) -> 0;
get_stren_factor(4,78) -> 0;
get_stren_factor(5,78) -> 0;
get_stren_factor(6,78) -> 0;
get_stren_factor(7,78) -> 0;
get_stren_factor(1,79) -> 0;
get_stren_factor(2,79) -> 0;
get_stren_factor(3,79) -> 0;
get_stren_factor(4,79) -> 0;
get_stren_factor(5,79) -> 0;
get_stren_factor(6,79) -> 0;
get_stren_factor(7,79) -> 0;
get_stren_factor(1,80) -> 0;
get_stren_factor(2,80) -> 0;
get_stren_factor(3,80) -> 0;
get_stren_factor(4,80) -> 0;
get_stren_factor(5,80) -> 0;
get_stren_factor(6,80) -> 0;
get_stren_factor(7,80) -> 0;
get_stren_factor(_,_) -> 0.

%%通过强化等级获取强化奖励数值
get_stren_limit(1,1) -> 
	[{1,0},{2,0},{3,12},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,1) -> 
	[{1,0},{2,0},{3,0},{4,9},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,9},{14,9},{15,9}];
get_stren_limit(3,1) -> 
	[{1,28},{2,0},{3,0},{4,0},{5,0},{6,8},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,1) -> 
	[{1,0},{2,0},{3,3},{4,0},{5,4},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,1) -> 
	[{1,0},{2,0},{3,4},{4,0},{5,6},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,1) -> 
	[{1,68},{2,0},{3,0},{4,14},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,1) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,9},{14,9},{15,9}];
get_stren_limit(1,2) -> 
	[{1,0},{2,0},{3,24},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,2) -> 
	[{1,0},{2,0},{3,0},{4,18},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,18},{14,18},{15,18}];
get_stren_limit(3,2) -> 
	[{1,56},{2,0},{3,0},{4,0},{5,0},{6,16},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,2) -> 
	[{1,0},{2,0},{3,6},{4,0},{5,8},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,2) -> 
	[{1,0},{2,0},{3,8},{4,0},{5,12},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,2) -> 
	[{1,136},{2,0},{3,0},{4,28},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,2) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,18},{14,18},{15,18}];
get_stren_limit(1,3) -> 
	[{1,0},{2,0},{3,36},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,3) -> 
	[{1,0},{2,0},{3,0},{4,27},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,27},{14,27},{15,27}];
get_stren_limit(3,3) -> 
	[{1,84},{2,0},{3,0},{4,0},{5,0},{6,24},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,3) -> 
	[{1,0},{2,0},{3,9},{4,0},{5,12},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,3) -> 
	[{1,0},{2,0},{3,12},{4,0},{5,18},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,3) -> 
	[{1,204},{2,0},{3,0},{4,42},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,3) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,27},{14,27},{15,27}];
get_stren_limit(1,4) -> 
	[{1,0},{2,0},{3,48},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,4) -> 
	[{1,0},{2,0},{3,0},{4,36},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,36},{14,36},{15,36}];
get_stren_limit(3,4) -> 
	[{1,112},{2,0},{3,0},{4,0},{5,0},{6,32},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,4) -> 
	[{1,0},{2,0},{3,12},{4,0},{5,16},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,4) -> 
	[{1,0},{2,0},{3,16},{4,0},{5,24},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,4) -> 
	[{1,272},{2,0},{3,0},{4,56},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,4) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,36},{14,36},{15,36}];
get_stren_limit(1,5) -> 
	[{1,0},{2,0},{3,60},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,5) -> 
	[{1,0},{2,0},{3,0},{4,45},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,45},{14,45},{15,45}];
get_stren_limit(3,5) -> 
	[{1,140},{2,0},{3,0},{4,0},{5,0},{6,40},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,5) -> 
	[{1,0},{2,0},{3,15},{4,0},{5,20},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,5) -> 
	[{1,0},{2,0},{3,20},{4,0},{5,30},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,5) -> 
	[{1,340},{2,0},{3,0},{4,70},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,5) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,45},{14,45},{15,45}];
get_stren_limit(1,6) -> 
	[{1,0},{2,0},{3,72},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,6) -> 
	[{1,0},{2,0},{3,0},{4,54},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,54},{14,54},{15,54}];
get_stren_limit(3,6) -> 
	[{1,168},{2,0},{3,0},{4,0},{5,0},{6,48},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,6) -> 
	[{1,0},{2,0},{3,18},{4,0},{5,24},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,6) -> 
	[{1,0},{2,0},{3,24},{4,0},{5,36},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,6) -> 
	[{1,408},{2,0},{3,0},{4,84},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,6) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,54},{14,54},{15,54}];
get_stren_limit(1,7) -> 
	[{1,0},{2,0},{3,84},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,7) -> 
	[{1,0},{2,0},{3,0},{4,63},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,63},{14,63},{15,63}];
get_stren_limit(3,7) -> 
	[{1,196},{2,0},{3,0},{4,0},{5,0},{6,56},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,7) -> 
	[{1,0},{2,0},{3,21},{4,0},{5,28},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,7) -> 
	[{1,0},{2,0},{3,28},{4,0},{5,42},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,7) -> 
	[{1,476},{2,0},{3,0},{4,98},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,7) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,63},{14,63},{15,63}];
get_stren_limit(1,8) -> 
	[{1,0},{2,0},{3,96},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,8) -> 
	[{1,0},{2,0},{3,0},{4,72},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,72},{14,72},{15,72}];
get_stren_limit(3,8) -> 
	[{1,224},{2,0},{3,0},{4,0},{5,0},{6,64},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,8) -> 
	[{1,0},{2,0},{3,24},{4,0},{5,32},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,8) -> 
	[{1,0},{2,0},{3,32},{4,0},{5,48},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,8) -> 
	[{1,544},{2,0},{3,0},{4,112},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,8) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,72},{14,72},{15,72}];
get_stren_limit(1,9) -> 
	[{1,0},{2,0},{3,108},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,9) -> 
	[{1,0},{2,0},{3,0},{4,81},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,81},{14,81},{15,81}];
get_stren_limit(3,9) -> 
	[{1,252},{2,0},{3,0},{4,0},{5,0},{6,72},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,9) -> 
	[{1,0},{2,0},{3,27},{4,0},{5,36},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,9) -> 
	[{1,0},{2,0},{3,36},{4,0},{5,54},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,9) -> 
	[{1,612},{2,0},{3,0},{4,126},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,9) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,81},{14,81},{15,81}];
get_stren_limit(1,10) -> 
	[{1,0},{2,0},{3,143},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,10) -> 
	[{1,0},{2,0},{3,0},{4,90},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,90},{14,90},{15,90}];
get_stren_limit(3,10) -> 
	[{1,280},{2,0},{3,0},{4,0},{5,0},{6,95},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,10) -> 
	[{1,0},{2,0},{3,30},{4,0},{5,40},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,10) -> 
	[{1,0},{2,0},{3,40},{4,0},{5,60},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,10) -> 
	[{1,820},{2,0},{3,0},{4,168},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,10) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,90},{14,90},{15,90}];
get_stren_limit(1,11) -> 
	[{1,0},{2,0},{3,155},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,11) -> 
	[{1,0},{2,0},{3,0},{4,99},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,99},{14,99},{15,99}];
get_stren_limit(3,11) -> 
	[{1,308},{2,0},{3,0},{4,0},{5,0},{6,103},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,11) -> 
	[{1,0},{2,0},{3,33},{4,0},{5,44},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,11) -> 
	[{1,0},{2,0},{3,44},{4,0},{5,66},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,11) -> 
	[{1,888},{2,0},{3,0},{4,182},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,11) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,99},{14,99},{15,99}];
get_stren_limit(1,12) -> 
	[{1,0},{2,0},{3,167},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,12) -> 
	[{1,0},{2,0},{3,0},{4,108},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,108},{14,108},{15,108}];
get_stren_limit(3,12) -> 
	[{1,336},{2,0},{3,0},{4,0},{5,0},{6,111},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,12) -> 
	[{1,0},{2,0},{3,36},{4,0},{5,48},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,12) -> 
	[{1,0},{2,0},{3,48},{4,0},{5,72},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,12) -> 
	[{1,956},{2,0},{3,0},{4,196},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,12) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,108},{14,108},{15,108}];
get_stren_limit(1,13) -> 
	[{1,0},{2,0},{3,179},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,13) -> 
	[{1,0},{2,0},{3,0},{4,117},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,117},{14,117},{15,117}];
get_stren_limit(3,13) -> 
	[{1,364},{2,0},{3,0},{4,0},{5,0},{6,119},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,13) -> 
	[{1,0},{2,0},{3,39},{4,0},{5,52},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,13) -> 
	[{1,0},{2,0},{3,52},{4,0},{5,78},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,13) -> 
	[{1,1024},{2,0},{3,0},{4,210},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,13) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,117},{14,117},{15,117}];
get_stren_limit(1,14) -> 
	[{1,0},{2,0},{3,191},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,14) -> 
	[{1,0},{2,0},{3,0},{4,126},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,126},{14,126},{15,126}];
get_stren_limit(3,14) -> 
	[{1,392},{2,0},{3,0},{4,0},{5,0},{6,127},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,14) -> 
	[{1,0},{2,0},{3,42},{4,0},{5,56},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,14) -> 
	[{1,0},{2,0},{3,56},{4,0},{5,84},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,14) -> 
	[{1,1092},{2,0},{3,0},{4,224},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,14) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,126},{14,126},{15,126}];
get_stren_limit(1,15) -> 
	[{1,0},{2,0},{3,203},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,15) -> 
	[{1,0},{2,0},{3,0},{4,135},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,135},{14,135},{15,135}];
get_stren_limit(3,15) -> 
	[{1,420},{2,0},{3,0},{4,0},{5,0},{6,135},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,15) -> 
	[{1,0},{2,0},{3,45},{4,0},{5,60},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,15) -> 
	[{1,0},{2,0},{3,60},{4,0},{5,90},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,15) -> 
	[{1,1160},{2,0},{3,0},{4,238},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,15) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,135},{14,135},{15,135}];
get_stren_limit(1,16) -> 
	[{1,0},{2,0},{3,215},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,16) -> 
	[{1,0},{2,0},{3,0},{4,144},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,144},{14,144},{15,144}];
get_stren_limit(3,16) -> 
	[{1,448},{2,0},{3,0},{4,0},{5,0},{6,143},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,16) -> 
	[{1,0},{2,0},{3,48},{4,0},{5,64},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,16) -> 
	[{1,0},{2,0},{3,64},{4,0},{5,96},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,16) -> 
	[{1,1228},{2,0},{3,0},{4,252},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,16) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,144},{14,144},{15,144}];
get_stren_limit(1,17) -> 
	[{1,0},{2,0},{3,227},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,17) -> 
	[{1,0},{2,0},{3,0},{4,153},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,153},{14,153},{15,153}];
get_stren_limit(3,17) -> 
	[{1,476},{2,0},{3,0},{4,0},{5,0},{6,151},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,17) -> 
	[{1,0},{2,0},{3,51},{4,0},{5,68},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,17) -> 
	[{1,0},{2,0},{3,68},{4,0},{5,102},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,17) -> 
	[{1,1296},{2,0},{3,0},{4,266},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,17) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,153},{14,153},{15,153}];
get_stren_limit(1,18) -> 
	[{1,0},{2,0},{3,239},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,18) -> 
	[{1,0},{2,0},{3,0},{4,162},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,162},{14,162},{15,162}];
get_stren_limit(3,18) -> 
	[{1,504},{2,0},{3,0},{4,0},{5,0},{6,159},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,18) -> 
	[{1,0},{2,0},{3,54},{4,0},{5,72},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,18) -> 
	[{1,0},{2,0},{3,72},{4,0},{5,108},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,18) -> 
	[{1,1364},{2,0},{3,0},{4,280},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,18) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,162},{14,162},{15,162}];
get_stren_limit(1,19) -> 
	[{1,0},{2,0},{3,251},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,19) -> 
	[{1,0},{2,0},{3,0},{4,171},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,171},{14,171},{15,171}];
get_stren_limit(3,19) -> 
	[{1,532},{2,0},{3,0},{4,0},{5,0},{6,167},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,19) -> 
	[{1,0},{2,0},{3,57},{4,0},{5,76},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,19) -> 
	[{1,0},{2,0},{3,76},{4,0},{5,114},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,19) -> 
	[{1,1432},{2,0},{3,0},{4,294},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,19) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,171},{14,171},{15,171}];
get_stren_limit(1,20) -> 
	[{1,0},{2,0},{3,301},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,20) -> 
	[{1,0},{2,0},{3,0},{4,180},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,180},{14,180},{15,180}];
get_stren_limit(3,20) -> 
	[{1,560},{2,0},{3,0},{4,0},{5,0},{6,201},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,20) -> 
	[{1,0},{2,0},{3,60},{4,0},{5,80},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,20) -> 
	[{1,0},{2,0},{3,80},{4,0},{5,120},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,20) -> 
	[{1,1723},{2,0},{3,0},{4,352},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,20) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,180},{14,180},{15,180}];
get_stren_limit(1,21) -> 
	[{1,0},{2,0},{3,314},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,21) -> 
	[{1,0},{2,0},{3,0},{4,191},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,191},{14,191},{15,191}];
get_stren_limit(3,21) -> 
	[{1,592},{2,0},{3,0},{4,0},{5,0},{6,209},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,21) -> 
	[{1,0},{2,0},{3,63},{4,0},{5,85},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,21) -> 
	[{1,0},{2,0},{3,84},{4,0},{5,127},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,21) -> 
	[{1,1802},{2,0},{3,0},{4,368},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,21) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,190},{14,190},{15,190}];
get_stren_limit(1,22) -> 
	[{1,0},{2,0},{3,327},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,22) -> 
	[{1,0},{2,0},{3,0},{4,202},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,202},{14,202},{15,202}];
get_stren_limit(3,22) -> 
	[{1,624},{2,0},{3,0},{4,0},{5,0},{6,217},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,22) -> 
	[{1,0},{2,0},{3,66},{4,0},{5,90},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,22) -> 
	[{1,0},{2,0},{3,88},{4,0},{5,134},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,22) -> 
	[{1,1881},{2,0},{3,0},{4,384},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,22) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,200},{14,200},{15,200}];
get_stren_limit(1,23) -> 
	[{1,0},{2,0},{3,340},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,23) -> 
	[{1,0},{2,0},{3,0},{4,213},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,213},{14,213},{15,213}];
get_stren_limit(3,23) -> 
	[{1,656},{2,0},{3,0},{4,0},{5,0},{6,225},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,23) -> 
	[{1,0},{2,0},{3,69},{4,0},{5,95},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,23) -> 
	[{1,0},{2,0},{3,92},{4,0},{5,141},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,23) -> 
	[{1,1960},{2,0},{3,0},{4,400},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,23) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,210},{14,210},{15,210}];
get_stren_limit(1,24) -> 
	[{1,0},{2,0},{3,353},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,24) -> 
	[{1,0},{2,0},{3,0},{4,224},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,224},{14,224},{15,224}];
get_stren_limit(3,24) -> 
	[{1,688},{2,0},{3,0},{4,0},{5,0},{6,233},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,24) -> 
	[{1,0},{2,0},{3,72},{4,0},{5,100},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,24) -> 
	[{1,0},{2,0},{3,96},{4,0},{5,148},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,24) -> 
	[{1,2039},{2,0},{3,0},{4,416},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,24) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,220},{14,220},{15,220}];
get_stren_limit(1,25) -> 
	[{1,0},{2,0},{3,366},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,25) -> 
	[{1,0},{2,0},{3,0},{4,235},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,235},{14,235},{15,235}];
get_stren_limit(3,25) -> 
	[{1,720},{2,0},{3,0},{4,0},{5,0},{6,241},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,25) -> 
	[{1,0},{2,0},{3,75},{4,0},{5,105},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,25) -> 
	[{1,0},{2,0},{3,100},{4,0},{5,155},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,25) -> 
	[{1,2118},{2,0},{3,0},{4,432},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,25) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,230},{14,230},{15,230}];
get_stren_limit(1,26) -> 
	[{1,0},{2,0},{3,379},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,26) -> 
	[{1,0},{2,0},{3,0},{4,246},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,246},{14,246},{15,246}];
get_stren_limit(3,26) -> 
	[{1,752},{2,0},{3,0},{4,0},{5,0},{6,249},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,26) -> 
	[{1,0},{2,0},{3,78},{4,0},{5,110},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,26) -> 
	[{1,0},{2,0},{3,105},{4,0},{5,162},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,26) -> 
	[{1,2197},{2,0},{3,0},{4,448},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,26) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,240},{14,240},{15,240}];
get_stren_limit(1,27) -> 
	[{1,0},{2,0},{3,392},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,27) -> 
	[{1,0},{2,0},{3,0},{4,257},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,257},{14,257},{15,257}];
get_stren_limit(3,27) -> 
	[{1,784},{2,0},{3,0},{4,0},{5,0},{6,257},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,27) -> 
	[{1,0},{2,0},{3,81},{4,0},{5,115},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,27) -> 
	[{1,0},{2,0},{3,110},{4,0},{5,169},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,27) -> 
	[{1,2276},{2,0},{3,0},{4,464},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,27) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,250},{14,250},{15,250}];
get_stren_limit(1,28) -> 
	[{1,0},{2,0},{3,405},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,28) -> 
	[{1,0},{2,0},{3,0},{4,268},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,268},{14,268},{15,268}];
get_stren_limit(3,28) -> 
	[{1,816},{2,0},{3,0},{4,0},{5,0},{6,265},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,28) -> 
	[{1,0},{2,0},{3,84},{4,0},{5,120},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,28) -> 
	[{1,0},{2,0},{3,115},{4,0},{5,176},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,28) -> 
	[{1,2355},{2,0},{3,0},{4,480},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,28) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,260},{14,260},{15,260}];
get_stren_limit(1,29) -> 
	[{1,0},{2,0},{3,418},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,29) -> 
	[{1,0},{2,0},{3,0},{4,279},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,279},{14,279},{15,279}];
get_stren_limit(3,29) -> 
	[{1,848},{2,0},{3,0},{4,0},{5,0},{6,273},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,29) -> 
	[{1,0},{2,0},{3,87},{4,0},{5,125},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,29) -> 
	[{1,0},{2,0},{3,120},{4,0},{5,183},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,29) -> 
	[{1,2434},{2,0},{3,0},{4,496},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,29) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,270},{14,270},{15,270}];
get_stren_limit(1,30) -> 
	[{1,0},{2,0},{3,483},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,30) -> 
	[{1,0},{2,0},{3,0},{4,290},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,290},{14,290},{15,290}];
get_stren_limit(3,30) -> 
	[{1,880},{2,0},{3,0},{4,0},{5,0},{6,319},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,30) -> 
	[{1,0},{2,0},{3,90},{4,0},{5,130},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,30) -> 
	[{1,0},{2,0},{3,125},{4,0},{5,190},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,30) -> 
	[{1,2819},{2,0},{3,0},{4,573},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,30) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,280},{14,280},{15,280}];
get_stren_limit(1,31) -> 
	[{1,0},{2,0},{3,497},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,31) -> 
	[{1,0},{2,0},{3,0},{4,301},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,301},{14,301},{15,301}];
get_stren_limit(3,31) -> 
	[{1,915},{2,0},{3,0},{4,0},{5,0},{6,328},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,31) -> 
	[{1,0},{2,0},{3,93},{4,0},{5,136},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,31) -> 
	[{1,0},{2,0},{3,130},{4,0},{5,198},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,31) -> 
	[{1,2902},{2,0},{3,0},{4,590},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,31) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,291},{14,291},{15,291}];
get_stren_limit(1,32) -> 
	[{1,0},{2,0},{3,511},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,32) -> 
	[{1,0},{2,0},{3,0},{4,312},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,312},{14,312},{15,312}];
get_stren_limit(3,32) -> 
	[{1,950},{2,0},{3,0},{4,0},{5,0},{6,337},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,32) -> 
	[{1,0},{2,0},{3,96},{4,0},{5,142},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,32) -> 
	[{1,0},{2,0},{3,135},{4,0},{5,206},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,32) -> 
	[{1,2985},{2,0},{3,0},{4,607},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,32) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,302},{14,302},{15,302}];
get_stren_limit(1,33) -> 
	[{1,0},{2,0},{3,525},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,33) -> 
	[{1,0},{2,0},{3,0},{4,323},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,323},{14,323},{15,323}];
get_stren_limit(3,33) -> 
	[{1,985},{2,0},{3,0},{4,0},{5,0},{6,346},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,33) -> 
	[{1,0},{2,0},{3,99},{4,0},{5,148},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,33) -> 
	[{1,0},{2,0},{3,140},{4,0},{5,214},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,33) -> 
	[{1,3068},{2,0},{3,0},{4,624},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,33) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,313},{14,313},{15,313}];
get_stren_limit(1,34) -> 
	[{1,0},{2,0},{3,539},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,34) -> 
	[{1,0},{2,0},{3,0},{4,334},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,334},{14,334},{15,334}];
get_stren_limit(3,34) -> 
	[{1,1020},{2,0},{3,0},{4,0},{5,0},{6,355},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,34) -> 
	[{1,0},{2,0},{3,102},{4,0},{5,154},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,34) -> 
	[{1,0},{2,0},{3,145},{4,0},{5,222},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,34) -> 
	[{1,3151},{2,0},{3,0},{4,641},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,34) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,324},{14,324},{15,324}];
get_stren_limit(1,35) -> 
	[{1,0},{2,0},{3,553},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,35) -> 
	[{1,0},{2,0},{3,0},{4,345},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,345},{14,345},{15,345}];
get_stren_limit(3,35) -> 
	[{1,1055},{2,0},{3,0},{4,0},{5,0},{6,364},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,35) -> 
	[{1,0},{2,0},{3,122},{4,0},{5,180},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,35) -> 
	[{1,0},{2,0},{3,171},{4,0},{5,255},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,35) -> 
	[{1,3234},{2,0},{3,0},{4,658},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,35) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,383},{14,383},{15,383}];
get_stren_limit(1,36) -> 
	[{1,0},{2,0},{3,567},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,36) -> 
	[{1,0},{2,0},{3,0},{4,356},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,356},{14,356},{15,356}];
get_stren_limit(3,36) -> 
	[{1,1090},{2,0},{3,0},{4,0},{5,0},{6,373},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,36) -> 
	[{1,0},{2,0},{3,126},{4,0},{5,186},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,36) -> 
	[{1,0},{2,0},{3,177},{4,0},{5,262},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,36) -> 
	[{1,3317},{2,0},{3,0},{4,675},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,36) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,394},{14,394},{15,394}];
get_stren_limit(1,37) -> 
	[{1,0},{2,0},{3,581},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,37) -> 
	[{1,0},{2,0},{3,0},{4,367},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,367},{14,367},{15,367}];
get_stren_limit(3,37) -> 
	[{1,1125},{2,0},{3,0},{4,0},{5,0},{6,382},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,37) -> 
	[{1,0},{2,0},{3,130},{4,0},{5,192},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,37) -> 
	[{1,0},{2,0},{3,183},{4,0},{5,269},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,37) -> 
	[{1,3400},{2,0},{3,0},{4,692},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,37) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,405},{14,405},{15,405}];
get_stren_limit(1,38) -> 
	[{1,0},{2,0},{3,595},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,38) -> 
	[{1,0},{2,0},{3,0},{4,378},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,378},{14,378},{15,378}];
get_stren_limit(3,38) -> 
	[{1,1160},{2,0},{3,0},{4,0},{5,0},{6,391},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,38) -> 
	[{1,0},{2,0},{3,134},{4,0},{5,198},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,38) -> 
	[{1,0},{2,0},{3,189},{4,0},{5,276},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,38) -> 
	[{1,3483},{2,0},{3,0},{4,709},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,38) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,416},{14,416},{15,416}];
get_stren_limit(1,39) -> 
	[{1,0},{2,0},{3,609},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,39) -> 
	[{1,0},{2,0},{3,0},{4,389},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,389},{14,389},{15,389}];
get_stren_limit(3,39) -> 
	[{1,1195},{2,0},{3,0},{4,0},{5,0},{6,400},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,39) -> 
	[{1,0},{2,0},{3,138},{4,0},{5,204},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,39) -> 
	[{1,0},{2,0},{3,195},{4,0},{5,283},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,39) -> 
	[{1,3566},{2,0},{3,0},{4,726},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,39) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,427},{14,427},{15,427}];
get_stren_limit(1,40) -> 
	[{1,0},{2,0},{3,689},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,40) -> 
	[{1,0},{2,0},{3,0},{4,449},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,449},{14,449},{15,449}];
get_stren_limit(3,40) -> 
	[{1,1370},{2,0},{3,0},{4,0},{5,0},{6,456},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,40) -> 
	[{1,0},{2,0},{3,142},{4,0},{5,209},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,40) -> 
	[{1,0},{2,0},{3,201},{4,0},{5,290},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,40) -> 
	[{1,4030},{2,0},{3,0},{4,819},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,40) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,438},{14,438},{15,438}];
get_stren_limit(1,41) -> 
	[{1,0},{2,0},{3,704},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,41) -> 
	[{1,0},{2,0},{3,0},{4,461},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,461},{14,461},{15,461}];
get_stren_limit(3,41) -> 
	[{1,1410},{2,0},{3,0},{4,0},{5,0},{6,465},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,41) -> 
	[{1,0},{2,0},{3,146},{4,0},{5,215},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,41) -> 
	[{1,0},{2,0},{3,207},{4,0},{5,297},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,41) -> 
	[{1,4121},{2,0},{3,0},{4,837},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,41) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,450},{14,450},{15,450}];
get_stren_limit(1,42) -> 
	[{1,0},{2,0},{3,719},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,42) -> 
	[{1,0},{2,0},{3,0},{4,473},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,473},{14,473},{15,473}];
get_stren_limit(3,42) -> 
	[{1,1450},{2,0},{3,0},{4,0},{5,0},{6,474},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,42) -> 
	[{1,0},{2,0},{3,150},{4,0},{5,221},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,42) -> 
	[{1,0},{2,0},{3,213},{4,0},{5,304},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,42) -> 
	[{1,4212},{2,0},{3,0},{4,855},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,42) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,462},{14,462},{15,462}];
get_stren_limit(1,43) -> 
	[{1,0},{2,0},{3,734},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,43) -> 
	[{1,0},{2,0},{3,0},{4,485},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,485},{14,485},{15,485}];
get_stren_limit(3,43) -> 
	[{1,1490},{2,0},{3,0},{4,0},{5,0},{6,483},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,43) -> 
	[{1,0},{2,0},{3,154},{4,0},{5,227},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,43) -> 
	[{1,0},{2,0},{3,219},{4,0},{5,311},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,43) -> 
	[{1,4303},{2,0},{3,0},{4,873},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,43) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,474},{14,474},{15,474}];
get_stren_limit(1,44) -> 
	[{1,0},{2,0},{3,749},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,44) -> 
	[{1,0},{2,0},{3,0},{4,497},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,497},{14,497},{15,497}];
get_stren_limit(3,44) -> 
	[{1,1530},{2,0},{3,0},{4,0},{5,0},{6,492},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,44) -> 
	[{1,0},{2,0},{3,158},{4,0},{5,233},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,44) -> 
	[{1,0},{2,0},{3,225},{4,0},{5,318},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,44) -> 
	[{1,4394},{2,0},{3,0},{4,891},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,44) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,486},{14,486},{15,486}];
get_stren_limit(1,45) -> 
	[{1,0},{2,0},{3,764},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,45) -> 
	[{1,0},{2,0},{3,0},{4,509},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,509},{14,509},{15,509}];
get_stren_limit(3,45) -> 
	[{1,1570},{2,0},{3,0},{4,0},{5,0},{6,501},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,45) -> 
	[{1,0},{2,0},{3,183},{4,0},{5,264},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,45) -> 
	[{1,0},{2,0},{3,257},{4,0},{5,358},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,45) -> 
	[{1,4485},{2,0},{3,0},{4,909},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,45) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,560},{14,560},{15,560}];
get_stren_limit(1,46) -> 
	[{1,0},{2,0},{3,779},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,46) -> 
	[{1,0},{2,0},{3,0},{4,521},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,521},{14,521},{15,521}];
get_stren_limit(3,46) -> 
	[{1,1610},{2,0},{3,0},{4,0},{5,0},{6,510},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,46) -> 
	[{1,0},{2,0},{3,187},{4,0},{5,270},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,46) -> 
	[{1,0},{2,0},{3,263},{4,0},{5,366},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,46) -> 
	[{1,4576},{2,0},{3,0},{4,927},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,46) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,572},{14,572},{15,572}];
get_stren_limit(1,47) -> 
	[{1,0},{2,0},{3,794},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,47) -> 
	[{1,0},{2,0},{3,0},{4,533},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,533},{14,533},{15,533}];
get_stren_limit(3,47) -> 
	[{1,1650},{2,0},{3,0},{4,0},{5,0},{6,519},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,47) -> 
	[{1,0},{2,0},{3,191},{4,0},{5,276},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,47) -> 
	[{1,0},{2,0},{3,269},{4,0},{5,374},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,47) -> 
	[{1,4667},{2,0},{3,0},{4,945},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,47) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,584},{14,584},{15,584}];
get_stren_limit(1,48) -> 
	[{1,0},{2,0},{3,809},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,48) -> 
	[{1,0},{2,0},{3,0},{4,545},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,545},{14,545},{15,545}];
get_stren_limit(3,48) -> 
	[{1,1690},{2,0},{3,0},{4,0},{5,0},{6,528},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,48) -> 
	[{1,0},{2,0},{3,195},{4,0},{5,282},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,48) -> 
	[{1,0},{2,0},{3,275},{4,0},{5,382},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,48) -> 
	[{1,4758},{2,0},{3,0},{4,963},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,48) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,596},{14,596},{15,596}];
get_stren_limit(1,49) -> 
	[{1,0},{2,0},{3,824},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,49) -> 
	[{1,0},{2,0},{3,0},{4,557},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,557},{14,557},{15,557}];
get_stren_limit(3,49) -> 
	[{1,1730},{2,0},{3,0},{4,0},{5,0},{6,537},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,49) -> 
	[{1,0},{2,0},{3,199},{4,0},{5,288},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,49) -> 
	[{1,0},{2,0},{3,281},{4,0},{5,390},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,49) -> 
	[{1,4849},{2,0},{3,0},{4,981},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,49) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,608},{14,608},{15,608}];
get_stren_limit(1,50) -> 
	[{1,0},{2,0},{3,924},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,50) -> 
	[{1,0},{2,0},{3,0},{4,635},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,635},{14,635},{15,635}];
get_stren_limit(3,50) -> 
	[{1,1940},{2,0},{3,0},{4,0},{5,0},{6,611},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,50) -> 
	[{1,0},{2,0},{3,203},{4,0},{5,293},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,50) -> 
	[{1,0},{2,0},{3,287},{4,0},{5,397},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,50) -> 
	[{1,5438},{2,0},{3,0},{4,1099},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,50) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,620},{14,620},{15,620}];
get_stren_limit(1,51) -> 
	[{1,0},{2,0},{3,940},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,51) -> 
	[{1,0},{2,0},{3,0},{4,647},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,647},{14,647},{15,647}];
get_stren_limit(3,51) -> 
	[{1,1985},{2,0},{3,0},{4,0},{5,0},{6,620},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,51) -> 
	[{1,0},{2,0},{3,207},{4,0},{5,298},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,51) -> 
	[{1,0},{2,0},{3,293},{4,0},{5,404},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,51) -> 
	[{1,5532},{2,0},{3,0},{4,1118},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,51) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,632},{14,632},{15,632}];
get_stren_limit(1,52) -> 
	[{1,0},{2,0},{3,956},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,52) -> 
	[{1,0},{2,0},{3,0},{4,659},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,659},{14,659},{15,659}];
get_stren_limit(3,52) -> 
	[{1,2030},{2,0},{3,0},{4,0},{5,0},{6,629},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,52) -> 
	[{1,0},{2,0},{3,211},{4,0},{5,303},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,52) -> 
	[{1,0},{2,0},{3,299},{4,0},{5,411},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,52) -> 
	[{1,5626},{2,0},{3,0},{4,1137},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,52) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,644},{14,644},{15,644}];
get_stren_limit(1,53) -> 
	[{1,0},{2,0},{3,972},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,53) -> 
	[{1,0},{2,0},{3,0},{4,671},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,671},{14,671},{15,671}];
get_stren_limit(3,53) -> 
	[{1,2075},{2,0},{3,0},{4,0},{5,0},{6,638},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,53) -> 
	[{1,0},{2,0},{3,215},{4,0},{5,308},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,53) -> 
	[{1,0},{2,0},{3,305},{4,0},{5,418},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,53) -> 
	[{1,5720},{2,0},{3,0},{4,1156},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,53) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,656},{14,656},{15,656}];
get_stren_limit(1,54) -> 
	[{1,0},{2,0},{3,988},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,54) -> 
	[{1,0},{2,0},{3,0},{4,683},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,683},{14,683},{15,683}];
get_stren_limit(3,54) -> 
	[{1,2120},{2,0},{3,0},{4,0},{5,0},{6,647},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,54) -> 
	[{1,0},{2,0},{3,219},{4,0},{5,313},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,54) -> 
	[{1,0},{2,0},{3,311},{4,0},{5,425},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,54) -> 
	[{1,5814},{2,0},{3,0},{4,1175},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,54) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,668},{14,668},{15,668}];
get_stren_limit(1,55) -> 
	[{1,0},{2,0},{3,1004},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,55) -> 
	[{1,0},{2,0},{3,0},{4,695},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,695},{14,695},{15,695}];
get_stren_limit(3,55) -> 
	[{1,2165},{2,0},{3,0},{4,0},{5,0},{6,656},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,55) -> 
	[{1,0},{2,0},{3,254},{4,0},{5,359},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,55) -> 
	[{1,0},{2,0},{3,356},{4,0},{5,483},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,55) -> 
	[{1,5908},{2,0},{3,0},{4,1194},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,55) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,758},{14,758},{15,758}];
get_stren_limit(1,56) -> 
	[{1,0},{2,0},{3,1020},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,56) -> 
	[{1,0},{2,0},{3,0},{4,707},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,707},{14,707},{15,707}];
get_stren_limit(3,56) -> 
	[{1,2210},{2,0},{3,0},{4,0},{5,0},{6,665},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,56) -> 
	[{1,0},{2,0},{3,258},{4,0},{5,364},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,56) -> 
	[{1,0},{2,0},{3,362},{4,0},{5,491},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,56) -> 
	[{1,6002},{2,0},{3,0},{4,1213},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,56) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,770},{14,770},{15,770}];
get_stren_limit(1,57) -> 
	[{1,0},{2,0},{3,1036},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,57) -> 
	[{1,0},{2,0},{3,0},{4,719},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,719},{14,719},{15,719}];
get_stren_limit(3,57) -> 
	[{1,2255},{2,0},{3,0},{4,0},{5,0},{6,674},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,57) -> 
	[{1,0},{2,0},{3,262},{4,0},{5,369},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,57) -> 
	[{1,0},{2,0},{3,368},{4,0},{5,499},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,57) -> 
	[{1,6096},{2,0},{3,0},{4,1232},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,57) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,782},{14,782},{15,782}];
get_stren_limit(1,58) -> 
	[{1,0},{2,0},{3,1052},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,58) -> 
	[{1,0},{2,0},{3,0},{4,731},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,731},{14,731},{15,731}];
get_stren_limit(3,58) -> 
	[{1,2300},{2,0},{3,0},{4,0},{5,0},{6,683},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,58) -> 
	[{1,0},{2,0},{3,266},{4,0},{5,374},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,58) -> 
	[{1,0},{2,0},{3,374},{4,0},{5,507},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,58) -> 
	[{1,6190},{2,0},{3,0},{4,1251},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,58) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,794},{14,794},{15,794}];
get_stren_limit(1,59) -> 
	[{1,0},{2,0},{3,1068},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,59) -> 
	[{1,0},{2,0},{3,0},{4,743},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,743},{14,743},{15,743}];
get_stren_limit(3,59) -> 
	[{1,2345},{2,0},{3,0},{4,0},{5,0},{6,692},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,59) -> 
	[{1,0},{2,0},{3,270},{4,0},{5,379},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,59) -> 
	[{1,0},{2,0},{3,380},{4,0},{5,515},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,59) -> 
	[{1,6284},{2,0},{3,0},{4,1270},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,59) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,806},{14,806},{15,806}];
get_stren_limit(1,60) -> 
	[{1,0},{2,0},{3,1188},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,60) -> 
	[{1,0},{2,0},{3,0},{4,845},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,845},{14,845},{15,845}];
get_stren_limit(3,60) -> 
	[{1,2610},{2,0},{3,0},{4,0},{5,0},{6,780},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,60) -> 
	[{1,0},{2,0},{3,274},{4,0},{5,384},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,60) -> 
	[{1,0},{2,0},{3,386},{4,0},{5,523},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,60) -> 
	[{1,6982},{2,0},{3,0},{4,1410},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,60) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,818},{14,818},{15,818}];
get_stren_limit(1,61) -> 
	[{1,0},{2,0},{3,1205},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,61) -> 
	[{1,0},{2,0},{3,0},{4,858},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,858},{14,858},{15,858}];
get_stren_limit(3,61) -> 
	[{1,2658},{2,0},{3,0},{4,0},{5,0},{6,790},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,61) -> 
	[{1,0},{2,0},{3,278},{4,0},{5,389},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,61) -> 
	[{1,0},{2,0},{3,392},{4,0},{5,531},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,61) -> 
	[{1,7080},{2,0},{3,0},{4,1430},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,61) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,831},{14,831},{15,831}];
get_stren_limit(1,62) -> 
	[{1,0},{2,0},{3,1222},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,62) -> 
	[{1,0},{2,0},{3,0},{4,871},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,871},{14,871},{15,871}];
get_stren_limit(3,62) -> 
	[{1,2706},{2,0},{3,0},{4,0},{5,0},{6,800},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,62) -> 
	[{1,0},{2,0},{3,282},{4,0},{5,394},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,62) -> 
	[{1,0},{2,0},{3,398},{4,0},{5,539},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,62) -> 
	[{1,7178},{2,0},{3,0},{4,1450},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,62) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,844},{14,844},{15,844}];
get_stren_limit(1,63) -> 
	[{1,0},{2,0},{3,1239},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,63) -> 
	[{1,0},{2,0},{3,0},{4,884},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,884},{14,884},{15,884}];
get_stren_limit(3,63) -> 
	[{1,2754},{2,0},{3,0},{4,0},{5,0},{6,810},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,63) -> 
	[{1,0},{2,0},{3,286},{4,0},{5,399},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,63) -> 
	[{1,0},{2,0},{3,404},{4,0},{5,547},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,63) -> 
	[{1,7276},{2,0},{3,0},{4,1470},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,63) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,857},{14,857},{15,857}];
get_stren_limit(1,64) -> 
	[{1,0},{2,0},{3,1256},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,64) -> 
	[{1,0},{2,0},{3,0},{4,897},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,897},{14,897},{15,897}];
get_stren_limit(3,64) -> 
	[{1,2802},{2,0},{3,0},{4,0},{5,0},{6,820},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,64) -> 
	[{1,0},{2,0},{3,290},{4,0},{5,404},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,64) -> 
	[{1,0},{2,0},{3,410},{4,0},{5,555},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,64) -> 
	[{1,7374},{2,0},{3,0},{4,1490},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,64) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,870},{14,870},{15,870}];
get_stren_limit(1,65) -> 
	[{1,0},{2,0},{3,1273},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,65) -> 
	[{1,0},{2,0},{3,0},{4,910},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,910},{14,910},{15,910}];
get_stren_limit(3,65) -> 
	[{1,2850},{2,0},{3,0},{4,0},{5,0},{6,830},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,65) -> 
	[{1,0},{2,0},{3,335},{4,0},{5,456},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,65) -> 
	[{1,0},{2,0},{3,467},{4,0},{5,621},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,65) -> 
	[{1,7472},{2,0},{3,0},{4,1510},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,65) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,974},{14,974},{15,974}];
get_stren_limit(1,66) -> 
	[{1,0},{2,0},{3,1290},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,66) -> 
	[{1,0},{2,0},{3,0},{4,923},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,923},{14,923},{15,923}];
get_stren_limit(3,66) -> 
	[{1,2898},{2,0},{3,0},{4,0},{5,0},{6,840},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,66) -> 
	[{1,0},{2,0},{3,339},{4,0},{5,462},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,66) -> 
	[{1,0},{2,0},{3,474},{4,0},{5,629},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,66) -> 
	[{1,7570},{2,0},{3,0},{4,1530},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,66) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,987},{14,987},{15,987}];
get_stren_limit(1,67) -> 
	[{1,0},{2,0},{3,1307},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,67) -> 
	[{1,0},{2,0},{3,0},{4,936},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,936},{14,936},{15,936}];
get_stren_limit(3,67) -> 
	[{1,2946},{2,0},{3,0},{4,0},{5,0},{6,850},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,67) -> 
	[{1,0},{2,0},{3,343},{4,0},{5,468},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,67) -> 
	[{1,0},{2,0},{3,481},{4,0},{5,637},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,67) -> 
	[{1,7668},{2,0},{3,0},{4,1550},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,67) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1000},{14,1000},{15,1000}];
get_stren_limit(1,68) -> 
	[{1,0},{2,0},{3,1324},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,68) -> 
	[{1,0},{2,0},{3,0},{4,949},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,949},{14,949},{15,949}];
get_stren_limit(3,68) -> 
	[{1,2994},{2,0},{3,0},{4,0},{5,0},{6,860},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,68) -> 
	[{1,0},{2,0},{3,347},{4,0},{5,474},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,68) -> 
	[{1,0},{2,0},{3,488},{4,0},{5,645},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,68) -> 
	[{1,7766},{2,0},{3,0},{4,1570},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,68) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1013},{14,1013},{15,1013}];
get_stren_limit(1,69) -> 
	[{1,0},{2,0},{3,1341},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,69) -> 
	[{1,0},{2,0},{3,0},{4,962},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,962},{14,962},{15,962}];
get_stren_limit(3,69) -> 
	[{1,3042},{2,0},{3,0},{4,0},{5,0},{6,870},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,69) -> 
	[{1,0},{2,0},{3,351},{4,0},{5,480},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,69) -> 
	[{1,0},{2,0},{3,495},{4,0},{5,653},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,69) -> 
	[{1,7864},{2,0},{3,0},{4,1590},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,69) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1026},{14,1026},{15,1026}];
get_stren_limit(1,70) -> 
	[{1,0},{2,0},{3,1481},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,70) -> 
	[{1,0},{2,0},{3,0},{4,1090},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1090},{14,1090},{15,1090}];
get_stren_limit(3,70) -> 
	[{1,3362},{2,0},{3,0},{4,0},{5,0},{6,970},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,70) -> 
	[{1,0},{2,0},{3,355},{4,0},{5,486},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,70) -> 
	[{1,0},{2,0},{3,502},{4,0},{5,661},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,70) -> 
	[{1,8687},{2,0},{3,0},{4,1755},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,70) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1039},{14,1039},{15,1039}];
get_stren_limit(1,71) -> 
	[{1,0},{2,0},{3,1499},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,71) -> 
	[{1,0},{2,0},{3,0},{4,1104},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1104},{14,1104},{15,1104}];
get_stren_limit(3,71) -> 
	[{1,3414},{2,0},{3,0},{4,0},{5,0},{6,980},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,71) -> 
	[{1,0},{2,0},{3,360},{4,0},{5,492},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,71) -> 
	[{1,0},{2,0},{3,509},{4,0},{5,669},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,71) -> 
	[{1,8793},{2,0},{3,0},{4,1776},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,71) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1053},{14,1053},{15,1053}];
get_stren_limit(1,72) -> 
	[{1,0},{2,0},{3,1517},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,72) -> 
	[{1,0},{2,0},{3,0},{4,1118},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1118},{14,1118},{15,1118}];
get_stren_limit(3,72) -> 
	[{1,3466},{2,0},{3,0},{4,0},{5,0},{6,990},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,72) -> 
	[{1,0},{2,0},{3,365},{4,0},{5,498},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,72) -> 
	[{1,0},{2,0},{3,516},{4,0},{5,677},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,72) -> 
	[{1,8899},{2,0},{3,0},{4,1797},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,72) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1067},{14,1067},{15,1067}];
get_stren_limit(1,73) -> 
	[{1,0},{2,0},{3,1535},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,73) -> 
	[{1,0},{2,0},{3,0},{4,1132},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1132},{14,1132},{15,1132}];
get_stren_limit(3,73) -> 
	[{1,3518},{2,0},{3,0},{4,0},{5,0},{6,1000},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,73) -> 
	[{1,0},{2,0},{3,370},{4,0},{5,504},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,73) -> 
	[{1,0},{2,0},{3,523},{4,0},{5,685},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,73) -> 
	[{1,9005},{2,0},{3,0},{4,1818},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,73) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1081},{14,1081},{15,1081}];
get_stren_limit(1,74) -> 
	[{1,0},{2,0},{3,1553},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,74) -> 
	[{1,0},{2,0},{3,0},{4,1146},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1146},{14,1146},{15,1146}];
get_stren_limit(3,74) -> 
	[{1,3570},{2,0},{3,0},{4,0},{5,0},{6,1010},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,74) -> 
	[{1,0},{2,0},{3,375},{4,0},{5,510},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,74) -> 
	[{1,0},{2,0},{3,530},{4,0},{5,693},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,74) -> 
	[{1,9111},{2,0},{3,0},{4,1839},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,74) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1095},{14,1095},{15,1095}];
get_stren_limit(1,75) -> 
	[{1,0},{2,0},{3,1571},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,75) -> 
	[{1,0},{2,0},{3,0},{4,1160},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1160},{14,1160},{15,1160}];
get_stren_limit(3,75) -> 
	[{1,3622},{2,0},{3,0},{4,0},{5,0},{6,1020},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,75) -> 
	[{1,0},{2,0},{3,435},{4,0},{5,590},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,75) -> 
	[{1,0},{2,0},{3,606},{4,0},{5,794},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,75) -> 
	[{1,9217},{2,0},{3,0},{4,1860},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,75) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1215},{14,1215},{15,1215}];
get_stren_limit(1,76) -> 
	[{1,0},{2,0},{3,1589},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,76) -> 
	[{1,0},{2,0},{3,0},{4,1174},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1174},{14,1174},{15,1174}];
get_stren_limit(3,76) -> 
	[{1,3674},{2,0},{3,0},{4,0},{5,0},{6,1030},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,76) -> 
	[{1,0},{2,0},{3,440},{4,0},{5,597},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,76) -> 
	[{1,0},{2,0},{3,614},{4,0},{5,803},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,76) -> 
	[{1,9323},{2,0},{3,0},{4,1881},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,76) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1229},{14,1229},{15,1229}];
get_stren_limit(1,77) -> 
	[{1,0},{2,0},{3,1607},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,77) -> 
	[{1,0},{2,0},{3,0},{4,1188},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1188},{14,1188},{15,1188}];
get_stren_limit(3,77) -> 
	[{1,3726},{2,0},{3,0},{4,0},{5,0},{6,1040},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,77) -> 
	[{1,0},{2,0},{3,445},{4,0},{5,604},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,77) -> 
	[{1,0},{2,0},{3,622},{4,0},{5,812},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,77) -> 
	[{1,9429},{2,0},{3,0},{4,1902},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,77) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1243},{14,1243},{15,1243}];
get_stren_limit(1,78) -> 
	[{1,0},{2,0},{3,1625},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,78) -> 
	[{1,0},{2,0},{3,0},{4,1202},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1202},{14,1202},{15,1202}];
get_stren_limit(3,78) -> 
	[{1,3778},{2,0},{3,0},{4,0},{5,0},{6,1050},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,78) -> 
	[{1,0},{2,0},{3,450},{4,0},{5,611},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,78) -> 
	[{1,0},{2,0},{3,630},{4,0},{5,821},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,78) -> 
	[{1,9535},{2,0},{3,0},{4,1923},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,78) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1257},{14,1257},{15,1257}];
get_stren_limit(1,79) -> 
	[{1,0},{2,0},{3,1643},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,79) -> 
	[{1,0},{2,0},{3,0},{4,1216},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1216},{14,1216},{15,1216}];
get_stren_limit(3,79) -> 
	[{1,3830},{2,0},{3,0},{4,0},{5,0},{6,1060},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,79) -> 
	[{1,0},{2,0},{3,455},{4,0},{5,618},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,79) -> 
	[{1,0},{2,0},{3,638},{4,0},{5,830},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,79) -> 
	[{1,9641},{2,0},{3,0},{4,1944},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,79) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1271},{14,1271},{15,1271}];
get_stren_limit(1,80) -> 
	[{1,0},{2,0},{3,1803},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(2,80) -> 
	[{1,0},{2,0},{3,0},{4,1361},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1361},{14,1361},{15,1361}];
get_stren_limit(3,80) -> 
	[{1,4180},{2,0},{3,0},{4,0},{5,0},{6,1170},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(4,80) -> 
	[{1,0},{2,0},{3,460},{4,0},{5,625},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(5,80) -> 
	[{1,0},{2,0},{3,646},{4,0},{5,839},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(6,80) -> 
	[{1,10577},{2,0},{3,0},{4,2132},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}];
get_stren_limit(7,80) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,1285},{14,1285},{15,1285}];
get_stren_limit(_,_) ->
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0},{11,0},{13,0},{14,0},{15,0}].



%%通过装备等级，强化等级获取数据

get_whole_reward(1, 7) -> 
[{3,75},{4,75},{1,750},{2,75},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,75},{13,0},{14,0},{15,0}];
get_whole_reward(1, 8) -> 
[{3,150},{4,150},{1,1500},{2,150},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,150},{13,0},{14,0},{15,0}];
get_whole_reward(1, 9) -> 
[{3,225},{4,225},{1,2250},{2,225},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,225},{13,0},{14,0},{15,0}];
get_whole_reward(1, 10) -> 
[{3,300},{4,300},{1,3000},{2,300},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,300},{13,0},{14,0},{15,0}];
get_whole_reward(1, 11) -> 
[{3,450},{4,450},{1,4500},{2,450},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,450},{13,0},{14,0},{15,0}];
get_whole_reward(1, 12) -> 
[{3,600},{4,600},{1,6000},{2,600},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,600},{13,0},{14,0},{15,0}];
get_whole_reward(2, 7) -> 
[{3,75},{4,75},{1,750},{2,75},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,75},{13,0},{14,0},{15,0}];
get_whole_reward(2, 8) -> 
[{3,150},{4,150},{1,1500},{2,150},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,150},{13,0},{14,0},{15,0}];
get_whole_reward(2, 9) -> 
[{3,225},{4,225},{1,2250},{2,225},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,225},{13,0},{14,0},{15,0}];
get_whole_reward(2, 10) -> 
[{3,300},{4,300},{1,3000},{2,300},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,300},{13,0},{14,0},{15,0}];
get_whole_reward(2, 11) -> 
[{3,450},{4,450},{1,4500},{2,450},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,450},{13,0},{14,0},{15,0}];
get_whole_reward(2, 12) -> 
[{3,600},{4,600},{1,6000},{2,600},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,600},{13,0},{14,0},{15,0}];
get_whole_reward(3, 7) -> 
[{3,75},{4,75},{1,750},{2,75},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,75},{13,0},{14,0},{15,0}];
get_whole_reward(3, 8) -> 
[{3,150},{4,150},{1,1500},{2,150},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,150},{13,0},{14,0},{15,0}];
get_whole_reward(3, 9) -> 
[{3,225},{4,225},{1,2250},{2,225},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,225},{13,0},{14,0},{15,0}];
get_whole_reward(3, 10) -> 
[{3,300},{4,300},{1,3000},{2,300},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,300},{13,0},{14,0},{15,0}];
get_whole_reward(3, 11) -> 
[{3,450},{4,450},{1,4500},{2,450},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,450},{13,0},{14,0},{15,0}];
get_whole_reward(3, 12) -> 
[{3,600},{4,600},{1,6000},{2,600},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,600},{13,0},{14,0},{15,0}];
get_whole_reward(4, 7) -> 
[{3,87},{4,87},{1,875},{2,87},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,87},{13,0},{14,0},{15,0}];
get_whole_reward(4, 8) -> 
[{3,174},{4,174},{1,1750},{2,174},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,174},{13,0},{14,0},{15,0}];
get_whole_reward(4, 9) -> 
[{3,261},{4,261},{1,2625},{2,261},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,261},{13,0},{14,0},{15,0}];
get_whole_reward(4, 10) -> 
[{3,328},{4,328},{1,3500},{2,328},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,328},{13,0},{14,0},{15,0}];
get_whole_reward(4, 11) -> 
[{3,522},{4,522},{1,5250},{2,522},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,522},{13,0},{14,0},{15,0}];
get_whole_reward(4, 12) -> 
[{3,700},{4,700},{1,7000},{2,700},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,700},{13,0},{14,0},{15,0}];
get_whole_reward(5, 7) -> 
[{3,100},{4,100},{1,1000},{2,100},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,100},{13,0},{14,0},{15,0}];
get_whole_reward(5, 8) -> 
[{3,200},{4,200},{1,2000},{2,200},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,200},{13,0},{14,0},{15,0}];
get_whole_reward(5, 9) -> 
[{3,300},{4,300},{1,3000},{2,300},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,300},{13,0},{14,0},{15,0}];
get_whole_reward(5, 10) -> 
[{3,400},{4,400},{1,4000},{2,400},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,400},{13,0},{14,0},{15,0}];
get_whole_reward(5, 11) -> 
[{3,600},{4,600},{1,6000},{2,600},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,600},{13,0},{14,0},{15,0}];
get_whole_reward(5, 12) -> 
[{3,800},{4,800},{1,8000},{2,800},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,800},{13,0},{14,0},{15,0}];
get_whole_reward(6, 7) -> 
[{3,112},{4,112},{1,1125},{2,112},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,112},{13,0},{14,0},{15,0}];
get_whole_reward(6, 8) -> 
[{3,224},{4,224},{1,2250},{2,224},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,224},{13,0},{14,0},{15,0}];
get_whole_reward(6, 9) -> 
[{3,336},{4,336},{1,3375},{2,336},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,336},{13,0},{14,0},{15,0}];
get_whole_reward(6, 10) -> 
[{3,448},{4,448},{1,4500},{2,448},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,448},{13,0},{14,0},{15,0}];
get_whole_reward(6, 11) -> 
[{3,672},{4,672},{1,6750},{2,672},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,672},{13,0},{14,0},{15,0}];
get_whole_reward(6, 12) -> 
[{3,900},{4,900},{1,9000},{2,900},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,900},{13,0},{14,0},{15,0}];
get_whole_reward(7, 7) -> 
[{3,125},{4,125},{1,1250},{2,125},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,125},{13,0},{14,0},{15,0}];
get_whole_reward(7, 8) -> 
[{3,250},{4,250},{1,2500},{2,250},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,250},{13,0},{14,0},{15,0}];
get_whole_reward(7, 9) -> 
[{3,375},{4,375},{1,3750},{2,375},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,375},{13,0},{14,0},{15,0}];
get_whole_reward(7, 10) -> 
[{3,500},{4,500},{1,5000},{2,500},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,500},{13,0},{14,0},{15,0}];
get_whole_reward(7, 11) -> 
[{3,750},{4,750},{1,7500},{2,750},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,750},{13,0},{14,0},{15,0}];
get_whole_reward(7, 12) -> 
[{3,1000},{4,1000},{1,10000},{2,1000},{9,0},{10,0},{11,0},{5,0},{6,0},{7,0},{8,0},{16,1000},{13,0},{14,0},{15,0}];
get_whole_reward(_, _) ->
	[].



%%通过幸运符id获取记录
get_lucky(121001) -> 
	#ets_stren_lucky{lucky_id=121001,ratio=10000,level=10};
get_lucky(121002) -> 
	#ets_stren_lucky{lucky_id=121002,ratio=10000,level=20};
get_lucky(121003) -> 
	#ets_stren_lucky{lucky_id=121003,ratio=10000,level=30};
get_lucky(121004) -> 
	#ets_stren_lucky{lucky_id=121004,ratio=10000,level=40};
get_lucky(121005) -> 
	#ets_stren_lucky{lucky_id=121005,ratio=10000,level=50};
get_lucky(121006) -> 
	#ets_stren_lucky{lucky_id=121006,ratio=10000,level=60};
get_lucky(121007) -> 
	#ets_stren_lucky{lucky_id=121007,ratio=10000,level=70};
get_lucky(121008) -> 
	#ets_stren_lucky{lucky_id=121008,ratio=10000,level=80};
get_lucky(121009) -> 
	#ets_stren_lucky{lucky_id=121009,ratio=10000,level=9};
get_lucky(121010) -> 
	#ets_stren_lucky{lucky_id=121010,ratio=10000,level=10};
get_lucky(121011) -> 
	#ets_stren_lucky{lucky_id=121011,ratio=10000,level=11};
get_lucky(121012) -> 
	#ets_stren_lucky{lucky_id=121012,ratio=10000,level=12};
get_lucky(121036) -> 
	#ets_stren_lucky{lucky_id=121036,ratio=10000,level=6};
get_lucky(_) ->
	[].



%%装备品质升级规则：通过装备等级和品质前缀获取记录
get_quality(1,1, 1) -> 
	#ets_goods_quality_upgrade{id=10001,type=1,equip_type=1,prefix=1,stone_id=112711,stone_num=1,coin=10000,less_level=30};
get_quality(1,1, 2) -> 
	#ets_goods_quality_upgrade{id=10002,type=1,equip_type=1,prefix=2,stone_id=112712,stone_num=1,coin=20000,less_level=40};
get_quality(1,1, 3) -> 
	#ets_goods_quality_upgrade{id=10003,type=1,equip_type=1,prefix=3,stone_id=112713,stone_num=1,coin=40000,less_level=50};
get_quality(1,1, 4) -> 
	#ets_goods_quality_upgrade{id=10004,type=1,equip_type=1,prefix=4,stone_id=112714,stone_num=1,coin=80000,less_level=60};
get_quality(1,1, 5) -> 
	#ets_goods_quality_upgrade{id=10005,type=1,equip_type=1,prefix=5,stone_id=112715,stone_num=1,coin=150000,less_level=70};
get_quality(1,1, 6) -> 
	#ets_goods_quality_upgrade{id=10006,type=1,equip_type=1,prefix=6,stone_id=112716,stone_num=1,coin=300000,less_level=80};
get_quality(1,2, 1) -> 
	#ets_goods_quality_upgrade{id=10007,type=1,equip_type=2,prefix=1,stone_id=112104,stone_num=1,coin=10000,less_level=30};
get_quality(1,2, 2) -> 
	#ets_goods_quality_upgrade{id=10008,type=1,equip_type=2,prefix=2,stone_id=112104,stone_num=2,coin=20000,less_level=40};
get_quality(1,2, 3) -> 
	#ets_goods_quality_upgrade{id=10009,type=1,equip_type=2,prefix=3,stone_id=112104,stone_num=4,coin=40000,less_level=50};
get_quality(1,2, 4) -> 
	#ets_goods_quality_upgrade{id=10010,type=1,equip_type=2,prefix=4,stone_id=112105,stone_num=3,coin=80000,less_level=60};
get_quality(1,2, 5) -> 
	#ets_goods_quality_upgrade{id=10011,type=1,equip_type=2,prefix=5,stone_id=112105,stone_num=5,coin=150000,less_level=70};
get_quality(1,2, 6) -> 
	#ets_goods_quality_upgrade{id=10012,type=1,equip_type=2,prefix=6,stone_id=112105,stone_num=7,coin=300000,less_level=80};
get_quality(1,3, 1) -> 
	#ets_goods_quality_upgrade{id=10013,type=1,equip_type=3,prefix=1,stone_id=112104,stone_num=1,coin=10000,less_level=30};
get_quality(1,3, 2) -> 
	#ets_goods_quality_upgrade{id=10014,type=1,equip_type=3,prefix=2,stone_id=112104,stone_num=2,coin=20000,less_level=40};
get_quality(1,3, 3) -> 
	#ets_goods_quality_upgrade{id=10015,type=1,equip_type=3,prefix=3,stone_id=112104,stone_num=4,coin=40000,less_level=50};
get_quality(1,3, 4) -> 
	#ets_goods_quality_upgrade{id=10016,type=1,equip_type=3,prefix=4,stone_id=112105,stone_num=3,coin=80000,less_level=60};
get_quality(1,3, 5) -> 
	#ets_goods_quality_upgrade{id=10017,type=1,equip_type=3,prefix=5,stone_id=112105,stone_num=5,coin=150000,less_level=70};
get_quality(1,3, 6) -> 
	#ets_goods_quality_upgrade{id=10018,type=1,equip_type=3,prefix=6,stone_id=112105,stone_num=7,coin=300000,less_level=80};
get_quality(1,4, 1) -> 
	#ets_goods_quality_upgrade{id=10019,type=1,equip_type=4,prefix=1,stone_id=112731,stone_num=1,coin=10000,less_level=35};
get_quality(1,4, 2) -> 
	#ets_goods_quality_upgrade{id=10020,type=1,equip_type=4,prefix=2,stone_id=112732,stone_num=1,coin=20000,less_level=45};
get_quality(1,4, 3) -> 
	#ets_goods_quality_upgrade{id=10021,type=1,equip_type=4,prefix=3,stone_id=112733,stone_num=1,coin=40000,less_level=55};
get_quality(1,4, 4) -> 
	#ets_goods_quality_upgrade{id=10022,type=1,equip_type=4,prefix=4,stone_id=112734,stone_num=1,coin=80000,less_level=65};
get_quality(1,4, 5) -> 
	#ets_goods_quality_upgrade{id=10023,type=1,equip_type=4,prefix=5,stone_id=112735,stone_num=1,coin=150000,less_level=75};
get_quality(1,4, 6) -> 
	#ets_goods_quality_upgrade{id=10024,type=1,equip_type=4,prefix=6,stone_id=112736,stone_num=1,coin=300000,less_level=85};
get_quality(1,5, 1) -> 
	#ets_goods_quality_upgrade{id=10025,type=1,equip_type=5,prefix=1,stone_id=112721,stone_num=1,coin=10000,less_level=35};
get_quality(1,5, 2) -> 
	#ets_goods_quality_upgrade{id=10026,type=1,equip_type=5,prefix=2,stone_id=112722,stone_num=1,coin=20000,less_level=45};
get_quality(1,5, 3) -> 
	#ets_goods_quality_upgrade{id=10027,type=1,equip_type=5,prefix=3,stone_id=112723,stone_num=1,coin=40000,less_level=55};
get_quality(1,5, 4) -> 
	#ets_goods_quality_upgrade{id=10028,type=1,equip_type=5,prefix=4,stone_id=112724,stone_num=1,coin=80000,less_level=65};
get_quality(1,5, 5) -> 
	#ets_goods_quality_upgrade{id=10029,type=1,equip_type=5,prefix=5,stone_id=112725,stone_num=1,coin=150000,less_level=75};
get_quality(1,5, 6) -> 
	#ets_goods_quality_upgrade{id=10030,type=1,equip_type=5,prefix=6,stone_id=112726,stone_num=1,coin=300000,less_level=85};
get_quality(1,6, 1) -> 
	#ets_goods_quality_upgrade{id=10031,type=1,equip_type=6,prefix=1,stone_id=112104,stone_num=2,coin=10000,less_level=30};
get_quality(1,6, 2) -> 
	#ets_goods_quality_upgrade{id=10032,type=1,equip_type=6,prefix=2,stone_id=112104,stone_num=5,coin=20000,less_level=40};
get_quality(1,6, 3) -> 
	#ets_goods_quality_upgrade{id=10033,type=1,equip_type=6,prefix=3,stone_id=112104,stone_num=8,coin=40000,less_level=50};
get_quality(1,6, 4) -> 
	#ets_goods_quality_upgrade{id=10034,type=1,equip_type=6,prefix=4,stone_id=112105,stone_num=5,coin=80000,less_level=60};
get_quality(1,6, 5) -> 
	#ets_goods_quality_upgrade{id=10035,type=1,equip_type=6,prefix=5,stone_id=112105,stone_num=7,coin=150000,less_level=70};
get_quality(1,6, 6) -> 
	#ets_goods_quality_upgrade{id=10036,type=1,equip_type=6,prefix=6,stone_id=112105,stone_num=9,coin=300000,less_level=80};
get_quality(1,7, 1) -> 
	#ets_goods_quality_upgrade{id=10037,type=1,equip_type=7,prefix=1,stone_id=112751,stone_num=1,coin=10000,less_level=35};
get_quality(1,7, 2) -> 
	#ets_goods_quality_upgrade{id=10038,type=1,equip_type=7,prefix=2,stone_id=112752,stone_num=1,coin=20000,less_level=45};
get_quality(1,7, 3) -> 
	#ets_goods_quality_upgrade{id=10039,type=1,equip_type=7,prefix=3,stone_id=112753,stone_num=1,coin=40000,less_level=55};
get_quality(1,7, 4) -> 
	#ets_goods_quality_upgrade{id=10040,type=1,equip_type=7,prefix=4,stone_id=112754,stone_num=1,coin=80000,less_level=65};
get_quality(1,7, 5) -> 
	#ets_goods_quality_upgrade{id=10041,type=1,equip_type=7,prefix=5,stone_id=112755,stone_num=1,coin=150000,less_level=75};
get_quality(1,7, 6) -> 
	#ets_goods_quality_upgrade{id=10042,type=1,equip_type=7,prefix=6,stone_id=112756,stone_num=1,coin=300000,less_level=85};
get_quality(2,1, 1) -> 
	#ets_goods_quality_upgrade{id=10043,type=2,equip_type=1,prefix=1,stone_id=601601,stone_num=12,coin=5000,less_level=0};
get_quality(2,1, 2) -> 
	#ets_goods_quality_upgrade{id=10044,type=2,equip_type=1,prefix=2,stone_id=601601,stone_num=24,coin=10000,less_level=0};
get_quality(2,1, 3) -> 
	#ets_goods_quality_upgrade{id=10045,type=2,equip_type=1,prefix=3,stone_id=601601,stone_num=40,coin=20000,less_level=0};
get_quality(2,2, 1) -> 
	#ets_goods_quality_upgrade{id=10046,type=2,equip_type=2,prefix=1,stone_id=601601,stone_num=12,coin=5000,less_level=0};
get_quality(2,2, 2) -> 
	#ets_goods_quality_upgrade{id=10047,type=2,equip_type=2,prefix=2,stone_id=601601,stone_num=24,coin=10000,less_level=0};
get_quality(2,2, 3) -> 
	#ets_goods_quality_upgrade{id=10048,type=2,equip_type=2,prefix=3,stone_id=601601,stone_num=40,coin=20000,less_level=0};
get_quality(2,3, 1) -> 
	#ets_goods_quality_upgrade{id=10049,type=2,equip_type=3,prefix=1,stone_id=601601,stone_num=12,coin=5000,less_level=0};
get_quality(2,3, 2) -> 
	#ets_goods_quality_upgrade{id=10050,type=2,equip_type=3,prefix=2,stone_id=601601,stone_num=24,coin=10000,less_level=0};
get_quality(2,3, 3) -> 
	#ets_goods_quality_upgrade{id=10051,type=2,equip_type=3,prefix=3,stone_id=601601,stone_num=40,coin=20000,less_level=0};
get_quality(2,4, 1) -> 
	#ets_goods_quality_upgrade{id=10052,type=2,equip_type=4,prefix=1,stone_id=601601,stone_num=12,coin=5000,less_level=0};
get_quality(2,4, 2) -> 
	#ets_goods_quality_upgrade{id=10053,type=2,equip_type=4,prefix=2,stone_id=601601,stone_num=24,coin=10000,less_level=0};
get_quality(2,4, 3) -> 
	#ets_goods_quality_upgrade{id=10054,type=2,equip_type=4,prefix=3,stone_id=601601,stone_num=40,coin=20000,less_level=0};
get_quality(2,5, 1) -> 
	#ets_goods_quality_upgrade{id=10055,type=2,equip_type=5,prefix=1,stone_id=601601,stone_num=12,coin=5000,less_level=0};
get_quality(2,5, 2) -> 
	#ets_goods_quality_upgrade{id=10056,type=2,equip_type=5,prefix=2,stone_id=601601,stone_num=24,coin=10000,less_level=0};
get_quality(2,5, 3) -> 
	#ets_goods_quality_upgrade{id=10057,type=2,equip_type=5,prefix=3,stone_id=601601,stone_num=40,coin=20000,less_level=0};
get_quality(2,6, 1) -> 
	#ets_goods_quality_upgrade{id=10058,type=2,equip_type=6,prefix=1,stone_id=601601,stone_num=12,coin=5000,less_level=0};
get_quality(2,6, 2) -> 
	#ets_goods_quality_upgrade{id=10059,type=2,equip_type=6,prefix=2,stone_id=601601,stone_num=24,coin=10000,less_level=0};
get_quality(2,6, 3) -> 
	#ets_goods_quality_upgrade{id=10060,type=2,equip_type=6,prefix=3,stone_id=601601,stone_num=40,coin=20000,less_level=0};
get_quality(2,7, 1) -> 
	#ets_goods_quality_upgrade{id=10061,type=2,equip_type=7,prefix=1,stone_id=601601,stone_num=12,coin=5000,less_level=0};
get_quality(2,7, 2) -> 
	#ets_goods_quality_upgrade{id=10062,type=2,equip_type=7,prefix=2,stone_id=601601,stone_num=24,coin=10000,less_level=0};
get_quality(2,7, 3) -> 
	#ets_goods_quality_upgrade{id=10063,type=2,equip_type=7,prefix=3,stone_id=601601,stone_num=40,coin=20000,less_level=0};
get_quality(_, _,_) ->
	[].



%%通过强化等级获取品质奖励基础加成
get_quality_factor(1,1,1) -> 0;
get_quality_factor(2,1,1) -> 10;
get_quality_factor(1,2,1) -> 0;
get_quality_factor(2,2,1) -> 10;
get_quality_factor(1,3,1) -> 0;
get_quality_factor(2,3,1) -> 10;
get_quality_factor(1,4,1) -> 0;
get_quality_factor(2,4,1) -> 10;
get_quality_factor(1,5,1) -> 0;
get_quality_factor(2,5,1) -> 10;
get_quality_factor(1,6,1) -> 0;
get_quality_factor(2,6,1) -> 10;
get_quality_factor(1,7,1) -> 0;
get_quality_factor(2,7,1) -> 10;
get_quality_factor(1,1,2) -> 0;
get_quality_factor(2,1,2) -> 20;
get_quality_factor(1,2,2) -> 0;
get_quality_factor(2,2,2) -> 20;
get_quality_factor(1,3,2) -> 0;
get_quality_factor(2,3,2) -> 20;
get_quality_factor(1,4,2) -> 0;
get_quality_factor(2,4,2) -> 20;
get_quality_factor(1,5,2) -> 0;
get_quality_factor(2,5,2) -> 20;
get_quality_factor(1,6,2) -> 0;
get_quality_factor(2,6,2) -> 20;
get_quality_factor(1,7,2) -> 0;
get_quality_factor(2,7,2) -> 20;
get_quality_factor(1,1,3) -> 0;
get_quality_factor(2,1,3) -> 35;
get_quality_factor(1,2,3) -> 0;
get_quality_factor(2,2,3) -> 35;
get_quality_factor(1,3,3) -> 0;
get_quality_factor(2,3,3) -> 35;
get_quality_factor(1,4,3) -> 0;
get_quality_factor(2,4,3) -> 35;
get_quality_factor(1,5,3) -> 0;
get_quality_factor(2,5,3) -> 35;
get_quality_factor(1,6,3) -> 0;
get_quality_factor(2,6,3) -> 35;
get_quality_factor(1,7,3) -> 0;
get_quality_factor(2,7,3) -> 35;
get_quality_factor(1,1,4) -> 0;
get_quality_factor(1,2,4) -> 0;
get_quality_factor(1,3,4) -> 0;
get_quality_factor(1,4,4) -> 0;
get_quality_factor(1,5,4) -> 0;
get_quality_factor(1,6,4) -> 0;
get_quality_factor(1,7,4) -> 0;
get_quality_factor(1,1,5) -> 0;
get_quality_factor(1,2,5) -> 0;
get_quality_factor(1,3,5) -> 0;
get_quality_factor(1,4,5) -> 0;
get_quality_factor(1,5,5) -> 0;
get_quality_factor(1,6,5) -> 0;
get_quality_factor(1,7,5) -> 0;
get_quality_factor(1,1,6) -> 0;
get_quality_factor(1,2,6) -> 0;
get_quality_factor(1,3,6) -> 0;
get_quality_factor(1,4,6) -> 0;
get_quality_factor(1,5,6) -> 0;
get_quality_factor(1,6,6) -> 0;
get_quality_factor(1,7,6) -> 0;
get_quality_factor(_,_,_) -> 0.

%%通过品质前缀获取奖励数值
get_quality_limit(1,1,1) -> 
	[{1,0},{2,0},{3,163},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,1,1) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,2,1) -> 
	[{1,0},{2,0},{3,0},{4,150},{5,0},{6,0},{7,0},{8,0},{13,150},{14,150},{15,150},{16,0}];
get_quality_limit(2,2,1) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,3,1) -> 
	[{1,565},{2,0},{3,0},{4,0},{5,0},{6,75},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,3,1) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,4,1) -> 
	[{1,0},{2,0},{3,44},{4,0},{5,44},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,4,1) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,5,1) -> 
	[{1,0},{2,0},{3,44},{4,0},{5,88},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,5,1) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,6,1) -> 
	[{1,762},{2,0},{3,0},{4,229},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,6,1) -> 
	[{1,1574},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,7,1) -> 
	[{1,2495},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,120},{15,120},{16,0}];
get_quality_limit(2,7,1) -> 
	[{1,3491},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,1,2) -> 
	[{1,4572},{2,0},{3,339},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,1,2) -> 
	[{1,5847},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,2,2) -> 
	[{1,0},{2,0},{3,0},{4,312},{5,0},{6,0},{7,0},{8,0},{13,312},{14,312},{15,312},{16,0}];
get_quality_limit(2,2,2) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,3,2) -> 
	[{1,1169},{2,0},{3,0},{4,0},{5,0},{6,156},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,3,2) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,4,2) -> 
	[{1,0},{2,0},{3,91},{4,0},{5,91},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,4,2) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,5,2) -> 
	[{1,0},{2,0},{3,91},{4,0},{5,183},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,5,2) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,6,2) -> 
	[{1,1574},{2,0},{3,0},{4,475},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,6,2) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,7,2) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,250},{14,250},{15,250},{16,0}];
get_quality_limit(2,7,2) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,1,3) -> 
	[{1,0},{2,0},{3,537},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,1,3) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,2,3) -> 
	[{1,0},{2,0},{3,0},{4,494},{5,0},{6,0},{7,0},{8,0},{13,494},{14,494},{15,494},{16,0}];
get_quality_limit(2,2,3) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,3,3) -> 
	[{1,1852},{2,0},{3,0},{4,0},{5,0},{6,248},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,3,3) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,4,3) -> 
	[{1,0},{2,0},{3,145},{4,0},{5,145},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,4,3) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,5,3) -> 
	[{1,0},{2,0},{3,145},{4,0},{5,290},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,5,3) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,6,3) -> 
	[{1,2495},{2,0},{3,0},{4,752},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(2,6,3) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,7,3) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,396},{14,396},{15,396},{16,0}];
get_quality_limit(2,7,3) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,1,4) -> 
	[{1,0},{2,0},{3,750},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,2,4) -> 
	[{1,0},{2,0},{3,0},{4,691},{5,0},{6,0},{7,0},{8,0},{13,691},{14,691},{15,691},{16,0}];
get_quality_limit(1,3,4) -> 
	[{1,2588},{2,0},{3,0},{4,0},{5,0},{6,346},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,4,4) -> 
	[{1,0},{2,0},{3,202},{4,0},{5,202},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,5,4) -> 
	[{1,0},{2,0},{3,202},{4,0},{5,405},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,6,4) -> 
	[{1,3491},{2,0},{3,0},{4,1051},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,7,4) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,553},{14,553},{15,553},{16,0}];
get_quality_limit(1,1,5) -> 
	[{1,0},{2,0},{3,982},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,2,5) -> 
	[{1,0},{2,0},{3,0},{4,905},{5,0},{6,0},{7,0},{8,0},{13,905},{14,905},{15,905},{16,0}];
get_quality_limit(1,3,5) -> 
	[{1,3390},{2,0},{3,0},{4,0},{5,0},{6,454},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,4,5) -> 
	[{1,0},{2,0},{3,265},{4,0},{5,265},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,5,5) -> 
	[{1,0},{2,0},{3,265},{4,0},{5,531},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,6,5) -> 
	[{1,4572},{2,0},{3,0},{4,1377},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,7,5) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,724},{14,724},{15,724},{16,0}];
get_quality_limit(1,1,6) -> 
	[{1,0},{2,0},{3,1257},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,2,6) -> 
	[{1,0},{2,0},{3,0},{4,1158},{5,0},{6,0},{7,0},{8,0},{13,1158},{14,1158},{15,1158},{16,0}];
get_quality_limit(1,3,6) -> 
	[{1,4336},{2,0},{3,0},{4,0},{5,0},{6,580},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,4,6) -> 
	[{1,0},{2,0},{3,339},{4,0},{5,339},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,5,6) -> 
	[{1,0},{2,0},{3,339},{4,0},{5,679},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,6,6) -> 
	[{1,5847},{2,0},{3,0},{4,1762},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}];
get_quality_limit(1,7,6) -> 
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,927},{14,927},{15,927},{16,0}];
get_quality_limit(_,_,_) ->
	[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{13,0},{14,0},{15,0},{16,0}].



%%装备进阶规则：通过物品id获取记录
get_upgrade(10101101) -> 
	#ets_equip_upgrade{goods_id=10101101,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10101111,coin=5000,less_stren=9};

get_upgrade(10101111) -> 
	#ets_equip_upgrade{goods_id=10101111,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10101121,coin=5000,less_stren=19};

get_upgrade(10101121) -> 
	#ets_equip_upgrade{goods_id=10101121,trip_id=112201,trip_num=4,stone_id=601701,stone_num=5,iron_id=112704,iron_num=2,protect_id=0,new_id=10101131,coin=5000,less_stren=29};

get_upgrade(10101129) -> 
	#ets_equip_upgrade{goods_id=10101129,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10101131,coin=10000,less_stren=29};

get_upgrade(10101131) -> 
	#ets_equip_upgrade{goods_id=10101131,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10101141,coin=10000,less_stren=39};

get_upgrade(10101141) -> 
	#ets_equip_upgrade{goods_id=10101141,trip_id=112202,trip_num=9,stone_id=601701,stone_num=13,iron_id=112705,iron_num=5,protect_id=0,new_id=10101151,coin=20000,less_stren=49};

get_upgrade(10101151) -> 
	#ets_equip_upgrade{goods_id=10101151,trip_id=112203,trip_num=12,stone_id=601701,stone_num=18,iron_id=112706,iron_num=7,protect_id=0,new_id=10101161,coin=40000,less_stren=59};

get_upgrade(10101161) -> 
	#ets_equip_upgrade{goods_id=10101161,trip_id=112204,trip_num=14,stone_id=601701,stone_num=30,iron_id=112707,iron_num=10,protect_id=0,new_id=10101171,coin=80000,less_stren=69};

get_upgrade(10101171) -> 
	#ets_equip_upgrade{goods_id=10101171,trip_id=112205,trip_num=25,stone_id=601701,stone_num=42,iron_id=112708,iron_num=15,protect_id=0,new_id=10101181,coin=150000,less_stren=79};

get_upgrade(10101201) -> 
	#ets_equip_upgrade{goods_id=10101201,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10101211,coin=5000,less_stren=9};

get_upgrade(10101211) -> 
	#ets_equip_upgrade{goods_id=10101211,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10101221,coin=5000,less_stren=19};

get_upgrade(10101221) -> 
	#ets_equip_upgrade{goods_id=10101221,trip_id=112201,trip_num=4,stone_id=601701,stone_num=5,iron_id=112704,iron_num=2,protect_id=0,new_id=10101231,coin=5000,less_stren=29};

get_upgrade(10101229) -> 
	#ets_equip_upgrade{goods_id=10101229,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10101231,coin=10000,less_stren=29};

get_upgrade(10101231) -> 
	#ets_equip_upgrade{goods_id=10101231,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10101241,coin=10000,less_stren=39};

get_upgrade(10101241) -> 
	#ets_equip_upgrade{goods_id=10101241,trip_id=112202,trip_num=9,stone_id=601701,stone_num=13,iron_id=112705,iron_num=5,protect_id=0,new_id=10101251,coin=20000,less_stren=49};

get_upgrade(10101251) -> 
	#ets_equip_upgrade{goods_id=10101251,trip_id=112203,trip_num=12,stone_id=601701,stone_num=18,iron_id=112706,iron_num=7,protect_id=0,new_id=10101261,coin=40000,less_stren=59};

get_upgrade(10101261) -> 
	#ets_equip_upgrade{goods_id=10101261,trip_id=112204,trip_num=14,stone_id=601701,stone_num=30,iron_id=112707,iron_num=10,protect_id=0,new_id=10101271,coin=80000,less_stren=69};

get_upgrade(10101271) -> 
	#ets_equip_upgrade{goods_id=10101271,trip_id=112205,trip_num=25,stone_id=601701,stone_num=42,iron_id=112708,iron_num=15,protect_id=0,new_id=10101281,coin=150000,less_stren=79};

get_upgrade(10102101) -> 
	#ets_equip_upgrade{goods_id=10102101,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10102111,coin=5000,less_stren=9};

get_upgrade(10102111) -> 
	#ets_equip_upgrade{goods_id=10102111,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10102121,coin=5000,less_stren=19};

get_upgrade(10102121) -> 
	#ets_equip_upgrade{goods_id=10102121,trip_id=112201,trip_num=4,stone_id=601701,stone_num=5,iron_id=112704,iron_num=2,protect_id=0,new_id=10102131,coin=5000,less_stren=29};

get_upgrade(10102129) -> 
	#ets_equip_upgrade{goods_id=10102129,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10102131,coin=10000,less_stren=29};

get_upgrade(10102131) -> 
	#ets_equip_upgrade{goods_id=10102131,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10102141,coin=10000,less_stren=39};

get_upgrade(10102141) -> 
	#ets_equip_upgrade{goods_id=10102141,trip_id=112202,trip_num=9,stone_id=601701,stone_num=13,iron_id=112705,iron_num=5,protect_id=0,new_id=10102151,coin=20000,less_stren=49};

get_upgrade(10102151) -> 
	#ets_equip_upgrade{goods_id=10102151,trip_id=112203,trip_num=12,stone_id=601701,stone_num=18,iron_id=112706,iron_num=7,protect_id=0,new_id=10102161,coin=40000,less_stren=59};

get_upgrade(10102161) -> 
	#ets_equip_upgrade{goods_id=10102161,trip_id=112204,trip_num=14,stone_id=601701,stone_num=30,iron_id=112707,iron_num=10,protect_id=0,new_id=10102171,coin=80000,less_stren=69};

get_upgrade(10102171) -> 
	#ets_equip_upgrade{goods_id=10102171,trip_id=112205,trip_num=25,stone_id=601701,stone_num=42,iron_id=112708,iron_num=15,protect_id=0,new_id=10102181,coin=150000,less_stren=79};

get_upgrade(10102201) -> 
	#ets_equip_upgrade{goods_id=10102201,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10102211,coin=5000,less_stren=9};

get_upgrade(10102211) -> 
	#ets_equip_upgrade{goods_id=10102211,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10102221,coin=5000,less_stren=19};

get_upgrade(10102221) -> 
	#ets_equip_upgrade{goods_id=10102221,trip_id=112201,trip_num=4,stone_id=601701,stone_num=5,iron_id=112704,iron_num=2,protect_id=0,new_id=10102231,coin=5000,less_stren=29};

get_upgrade(10102229) -> 
	#ets_equip_upgrade{goods_id=10102229,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10102231,coin=10000,less_stren=29};

get_upgrade(10102231) -> 
	#ets_equip_upgrade{goods_id=10102231,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10102241,coin=10000,less_stren=39};

get_upgrade(10102241) -> 
	#ets_equip_upgrade{goods_id=10102241,trip_id=112202,trip_num=9,stone_id=601701,stone_num=13,iron_id=112705,iron_num=5,protect_id=0,new_id=10102251,coin=20000,less_stren=49};

get_upgrade(10102251) -> 
	#ets_equip_upgrade{goods_id=10102251,trip_id=112203,trip_num=12,stone_id=601701,stone_num=18,iron_id=112706,iron_num=7,protect_id=0,new_id=10102261,coin=40000,less_stren=59};

get_upgrade(10102261) -> 
	#ets_equip_upgrade{goods_id=10102261,trip_id=112204,trip_num=14,stone_id=601701,stone_num=30,iron_id=112707,iron_num=10,protect_id=0,new_id=10102271,coin=80000,less_stren=69};

get_upgrade(10102271) -> 
	#ets_equip_upgrade{goods_id=10102271,trip_id=112205,trip_num=25,stone_id=601701,stone_num=42,iron_id=112708,iron_num=15,protect_id=0,new_id=10102281,coin=150000,less_stren=79};

get_upgrade(10103101) -> 
	#ets_equip_upgrade{goods_id=10103101,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10103111,coin=5000,less_stren=9};

get_upgrade(10103111) -> 
	#ets_equip_upgrade{goods_id=10103111,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10103121,coin=5000,less_stren=19};

get_upgrade(10103121) -> 
	#ets_equip_upgrade{goods_id=10103121,trip_id=112201,trip_num=4,stone_id=601701,stone_num=5,iron_id=112704,iron_num=2,protect_id=0,new_id=10103131,coin=5000,less_stren=29};

get_upgrade(10103129) -> 
	#ets_equip_upgrade{goods_id=10103129,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10103131,coin=10000,less_stren=29};

get_upgrade(10103131) -> 
	#ets_equip_upgrade{goods_id=10103131,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10103141,coin=10000,less_stren=39};

get_upgrade(10103141) -> 
	#ets_equip_upgrade{goods_id=10103141,trip_id=112202,trip_num=9,stone_id=601701,stone_num=13,iron_id=112705,iron_num=5,protect_id=0,new_id=10103151,coin=20000,less_stren=49};

get_upgrade(10103151) -> 
	#ets_equip_upgrade{goods_id=10103151,trip_id=112203,trip_num=12,stone_id=601701,stone_num=18,iron_id=112706,iron_num=7,protect_id=0,new_id=10103161,coin=40000,less_stren=59};

get_upgrade(10103161) -> 
	#ets_equip_upgrade{goods_id=10103161,trip_id=112204,trip_num=14,stone_id=601701,stone_num=30,iron_id=112707,iron_num=10,protect_id=0,new_id=10103171,coin=80000,less_stren=69};

get_upgrade(10103171) -> 
	#ets_equip_upgrade{goods_id=10103171,trip_id=112205,trip_num=25,stone_id=601701,stone_num=42,iron_id=112708,iron_num=15,protect_id=0,new_id=10103181,coin=150000,less_stren=79};

get_upgrade(10103201) -> 
	#ets_equip_upgrade{goods_id=10103201,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10103211,coin=5000,less_stren=9};

get_upgrade(10103211) -> 
	#ets_equip_upgrade{goods_id=10103211,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10103221,coin=5000,less_stren=19};

get_upgrade(10103221) -> 
	#ets_equip_upgrade{goods_id=10103221,trip_id=112201,trip_num=4,stone_id=601701,stone_num=5,iron_id=112704,iron_num=2,protect_id=0,new_id=10103231,coin=5000,less_stren=29};

get_upgrade(10103229) -> 
	#ets_equip_upgrade{goods_id=10103229,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10103231,coin=10000,less_stren=29};

get_upgrade(10103231) -> 
	#ets_equip_upgrade{goods_id=10103231,trip_id=112201,trip_num=8,stone_id=601701,stone_num=8,iron_id=112704,iron_num=4,protect_id=0,new_id=10103241,coin=10000,less_stren=39};

get_upgrade(10103241) -> 
	#ets_equip_upgrade{goods_id=10103241,trip_id=112202,trip_num=9,stone_id=601701,stone_num=13,iron_id=112705,iron_num=5,protect_id=0,new_id=10103251,coin=20000,less_stren=49};

get_upgrade(10103251) -> 
	#ets_equip_upgrade{goods_id=10103251,trip_id=112203,trip_num=12,stone_id=601701,stone_num=18,iron_id=112706,iron_num=7,protect_id=0,new_id=10103261,coin=40000,less_stren=59};

get_upgrade(10103261) -> 
	#ets_equip_upgrade{goods_id=10103261,trip_id=112204,trip_num=14,stone_id=601701,stone_num=30,iron_id=112707,iron_num=10,protect_id=0,new_id=10103271,coin=80000,less_stren=69};

get_upgrade(10103271) -> 
	#ets_equip_upgrade{goods_id=10103271,trip_id=112205,trip_num=25,stone_id=601701,stone_num=42,iron_id=112708,iron_num=15,protect_id=0,new_id=10103281,coin=150000,less_stren=79};

get_upgrade(10201021) -> 
	#ets_equip_upgrade{goods_id=10201021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10201031,coin=5000,less_stren=29};

get_upgrade(10201031) -> 
	#ets_equip_upgrade{goods_id=10201031,trip_id=112201,trip_num=9,stone_id=601701,stone_num=0,iron_id=112704,iron_num=3,protect_id=0,new_id=10201041,coin=10000,less_stren=39};

get_upgrade(10201041) -> 
	#ets_equip_upgrade{goods_id=10201041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=3,protect_id=0,new_id=10201051,coin=20000,less_stren=49};

get_upgrade(10201051) -> 
	#ets_equip_upgrade{goods_id=10201051,trip_id=112203,trip_num=10,stone_id=601701,stone_num=0,iron_id=112706,iron_num=4,protect_id=0,new_id=10201061,coin=40000,less_stren=59};

get_upgrade(10201061) -> 
	#ets_equip_upgrade{goods_id=10201061,trip_id=112204,trip_num=14,stone_id=601701,stone_num=0,iron_id=112707,iron_num=5,protect_id=0,new_id=10201071,coin=80000,less_stren=69};

get_upgrade(10201071) -> 
	#ets_equip_upgrade{goods_id=10201071,trip_id=112205,trip_num=17,stone_id=601701,stone_num=0,iron_id=112708,iron_num=9,protect_id=0,new_id=10201081,coin=150000,less_stren=79};

get_upgrade(10202021) -> 
	#ets_equip_upgrade{goods_id=10202021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10202031,coin=5000,less_stren=29};

get_upgrade(10202031) -> 
	#ets_equip_upgrade{goods_id=10202031,trip_id=112201,trip_num=9,stone_id=601701,stone_num=0,iron_id=112704,iron_num=3,protect_id=0,new_id=10202041,coin=10000,less_stren=39};

get_upgrade(10202041) -> 
	#ets_equip_upgrade{goods_id=10202041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=3,protect_id=0,new_id=10202051,coin=20000,less_stren=49};

get_upgrade(10202051) -> 
	#ets_equip_upgrade{goods_id=10202051,trip_id=112203,trip_num=10,stone_id=601701,stone_num=0,iron_id=112706,iron_num=4,protect_id=0,new_id=10202061,coin=40000,less_stren=59};

get_upgrade(10202061) -> 
	#ets_equip_upgrade{goods_id=10202061,trip_id=112204,trip_num=14,stone_id=601701,stone_num=0,iron_id=112707,iron_num=5,protect_id=0,new_id=10202071,coin=80000,less_stren=69};

get_upgrade(10202071) -> 
	#ets_equip_upgrade{goods_id=10202071,trip_id=112205,trip_num=17,stone_id=601701,stone_num=0,iron_id=112708,iron_num=9,protect_id=0,new_id=10202081,coin=150000,less_stren=79};

get_upgrade(10203021) -> 
	#ets_equip_upgrade{goods_id=10203021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10203031,coin=5000,less_stren=29};

get_upgrade(10203031) -> 
	#ets_equip_upgrade{goods_id=10203031,trip_id=112201,trip_num=9,stone_id=601701,stone_num=0,iron_id=112704,iron_num=3,protect_id=0,new_id=10203041,coin=10000,less_stren=39};

get_upgrade(10203041) -> 
	#ets_equip_upgrade{goods_id=10203041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=3,protect_id=0,new_id=10203051,coin=20000,less_stren=49};

get_upgrade(10203051) -> 
	#ets_equip_upgrade{goods_id=10203051,trip_id=112203,trip_num=10,stone_id=601701,stone_num=0,iron_id=112706,iron_num=4,protect_id=0,new_id=10203061,coin=40000,less_stren=59};

get_upgrade(10203061) -> 
	#ets_equip_upgrade{goods_id=10203061,trip_id=112204,trip_num=14,stone_id=601701,stone_num=0,iron_id=112707,iron_num=5,protect_id=0,new_id=10203071,coin=80000,less_stren=69};

get_upgrade(10203071) -> 
	#ets_equip_upgrade{goods_id=10203071,trip_id=112205,trip_num=17,stone_id=601701,stone_num=0,iron_id=112708,iron_num=9,protect_id=0,new_id=10203081,coin=150000,less_stren=79};

get_upgrade(10211001) -> 
	#ets_equip_upgrade{goods_id=10211001,trip_id=112201,trip_num=2,stone_id=601701,stone_num=0,iron_id=112704,iron_num=1,protect_id=0,new_id=10211011,coin=5000,less_stren=9};

get_upgrade(10211011) -> 
	#ets_equip_upgrade{goods_id=10211011,trip_id=112201,trip_num=2,stone_id=601701,stone_num=0,iron_id=112704,iron_num=1,protect_id=0,new_id=10211021,coin=5000,less_stren=19};

get_upgrade(10211021) -> 
	#ets_equip_upgrade{goods_id=10211021,trip_id=112201,trip_num=6,stone_id=601701,stone_num=0,iron_id=112704,iron_num=4,protect_id=0,new_id=10211031,coin=5000,less_stren=29};

get_upgrade(10211031) -> 
	#ets_equip_upgrade{goods_id=10211031,trip_id=112201,trip_num=10,stone_id=601701,stone_num=0,iron_id=112704,iron_num=5,protect_id=0,new_id=10211041,coin=10000,less_stren=39};

get_upgrade(10211041) -> 
	#ets_equip_upgrade{goods_id=10211041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=4,protect_id=0,new_id=10211051,coin=20000,less_stren=49};

get_upgrade(10211051) -> 
	#ets_equip_upgrade{goods_id=10211051,trip_id=112203,trip_num=9,stone_id=601701,stone_num=0,iron_id=112706,iron_num=5,protect_id=0,new_id=10211061,coin=40000,less_stren=59};

get_upgrade(10211061) -> 
	#ets_equip_upgrade{goods_id=10211061,trip_id=112204,trip_num=12,stone_id=601701,stone_num=0,iron_id=112707,iron_num=6,protect_id=0,new_id=10211071,coin=80000,less_stren=69};

get_upgrade(10211071) -> 
	#ets_equip_upgrade{goods_id=10211071,trip_id=112205,trip_num=15,stone_id=601701,stone_num=0,iron_id=112708,iron_num=10,protect_id=0,new_id=10211081,coin=150000,less_stren=79};

get_upgrade(10212001) -> 
	#ets_equip_upgrade{goods_id=10212001,trip_id=112201,trip_num=2,stone_id=601701,stone_num=0,iron_id=112704,iron_num=1,protect_id=0,new_id=10212011,coin=5000,less_stren=9};

get_upgrade(10212011) -> 
	#ets_equip_upgrade{goods_id=10212011,trip_id=112201,trip_num=2,stone_id=601701,stone_num=0,iron_id=112704,iron_num=1,protect_id=0,new_id=10212021,coin=5000,less_stren=19};

get_upgrade(10212021) -> 
	#ets_equip_upgrade{goods_id=10212021,trip_id=112201,trip_num=6,stone_id=601701,stone_num=0,iron_id=112704,iron_num=4,protect_id=0,new_id=10212031,coin=5000,less_stren=29};

get_upgrade(10212031) -> 
	#ets_equip_upgrade{goods_id=10212031,trip_id=112201,trip_num=10,stone_id=601701,stone_num=0,iron_id=112704,iron_num=5,protect_id=0,new_id=10212041,coin=10000,less_stren=39};

get_upgrade(10212041) -> 
	#ets_equip_upgrade{goods_id=10212041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=4,protect_id=0,new_id=10212051,coin=20000,less_stren=49};

get_upgrade(10212051) -> 
	#ets_equip_upgrade{goods_id=10212051,trip_id=112203,trip_num=9,stone_id=601701,stone_num=0,iron_id=112706,iron_num=5,protect_id=0,new_id=10212061,coin=40000,less_stren=59};

get_upgrade(10212061) -> 
	#ets_equip_upgrade{goods_id=10212061,trip_id=112204,trip_num=12,stone_id=601701,stone_num=0,iron_id=112707,iron_num=6,protect_id=0,new_id=10212071,coin=80000,less_stren=69};

get_upgrade(10212071) -> 
	#ets_equip_upgrade{goods_id=10212071,trip_id=112205,trip_num=15,stone_id=601701,stone_num=0,iron_id=112708,iron_num=10,protect_id=0,new_id=10212081,coin=150000,less_stren=79};

get_upgrade(10213001) -> 
	#ets_equip_upgrade{goods_id=10213001,trip_id=112201,trip_num=2,stone_id=601701,stone_num=0,iron_id=112704,iron_num=1,protect_id=0,new_id=10213011,coin=5000,less_stren=9};

get_upgrade(10213011) -> 
	#ets_equip_upgrade{goods_id=10213011,trip_id=112201,trip_num=2,stone_id=601701,stone_num=0,iron_id=112704,iron_num=1,protect_id=0,new_id=10213021,coin=5000,less_stren=19};

get_upgrade(10213021) -> 
	#ets_equip_upgrade{goods_id=10213021,trip_id=112201,trip_num=6,stone_id=601701,stone_num=0,iron_id=112704,iron_num=4,protect_id=0,new_id=10213031,coin=5000,less_stren=29};

get_upgrade(10213031) -> 
	#ets_equip_upgrade{goods_id=10213031,trip_id=112201,trip_num=10,stone_id=601701,stone_num=0,iron_id=112704,iron_num=5,protect_id=0,new_id=10213041,coin=10000,less_stren=39};

get_upgrade(10213041) -> 
	#ets_equip_upgrade{goods_id=10213041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=4,protect_id=0,new_id=10213051,coin=20000,less_stren=49};

get_upgrade(10213051) -> 
	#ets_equip_upgrade{goods_id=10213051,trip_id=112203,trip_num=9,stone_id=601701,stone_num=0,iron_id=112706,iron_num=5,protect_id=0,new_id=10213061,coin=40000,less_stren=59};

get_upgrade(10213061) -> 
	#ets_equip_upgrade{goods_id=10213061,trip_id=112204,trip_num=12,stone_id=601701,stone_num=0,iron_id=112707,iron_num=6,protect_id=0,new_id=10213071,coin=80000,less_stren=69};

get_upgrade(10213071) -> 
	#ets_equip_upgrade{goods_id=10213071,trip_id=112205,trip_num=15,stone_id=601701,stone_num=0,iron_id=112708,iron_num=10,protect_id=0,new_id=10213081,coin=150000,less_stren=79};

get_upgrade(10221021) -> 
	#ets_equip_upgrade{goods_id=10221021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10221031,coin=5000,less_stren=29};

get_upgrade(10221031) -> 
	#ets_equip_upgrade{goods_id=10221031,trip_id=112201,trip_num=9,stone_id=601701,stone_num=0,iron_id=112704,iron_num=3,protect_id=0,new_id=10221041,coin=10000,less_stren=39};

get_upgrade(10221041) -> 
	#ets_equip_upgrade{goods_id=10221041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=3,protect_id=0,new_id=10221051,coin=20000,less_stren=49};

get_upgrade(10221051) -> 
	#ets_equip_upgrade{goods_id=10221051,trip_id=112203,trip_num=10,stone_id=601701,stone_num=0,iron_id=112706,iron_num=4,protect_id=0,new_id=10221061,coin=40000,less_stren=59};

get_upgrade(10221061) -> 
	#ets_equip_upgrade{goods_id=10221061,trip_id=112204,trip_num=14,stone_id=601701,stone_num=0,iron_id=112707,iron_num=5,protect_id=0,new_id=10221071,coin=80000,less_stren=69};

get_upgrade(10221071) -> 
	#ets_equip_upgrade{goods_id=10221071,trip_id=112205,trip_num=17,stone_id=601701,stone_num=0,iron_id=112708,iron_num=9,protect_id=0,new_id=10221081,coin=150000,less_stren=79};

get_upgrade(10222021) -> 
	#ets_equip_upgrade{goods_id=10222021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10222031,coin=5000,less_stren=29};

get_upgrade(10222031) -> 
	#ets_equip_upgrade{goods_id=10222031,trip_id=112201,trip_num=9,stone_id=601701,stone_num=0,iron_id=112704,iron_num=3,protect_id=0,new_id=10222041,coin=10000,less_stren=39};

get_upgrade(10222041) -> 
	#ets_equip_upgrade{goods_id=10222041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=3,protect_id=0,new_id=10222051,coin=20000,less_stren=49};

get_upgrade(10222051) -> 
	#ets_equip_upgrade{goods_id=10222051,trip_id=112203,trip_num=10,stone_id=601701,stone_num=0,iron_id=112706,iron_num=4,protect_id=0,new_id=10222061,coin=40000,less_stren=59};

get_upgrade(10222061) -> 
	#ets_equip_upgrade{goods_id=10222061,trip_id=112204,trip_num=14,stone_id=601701,stone_num=0,iron_id=112707,iron_num=5,protect_id=0,new_id=10222071,coin=80000,less_stren=69};

get_upgrade(10222071) -> 
	#ets_equip_upgrade{goods_id=10222071,trip_id=112205,trip_num=17,stone_id=601701,stone_num=0,iron_id=112708,iron_num=9,protect_id=0,new_id=10222081,coin=150000,less_stren=79};

get_upgrade(10223021) -> 
	#ets_equip_upgrade{goods_id=10223021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10223031,coin=5000,less_stren=29};

get_upgrade(10223031) -> 
	#ets_equip_upgrade{goods_id=10223031,trip_id=112201,trip_num=9,stone_id=601701,stone_num=0,iron_id=112704,iron_num=3,protect_id=0,new_id=10223041,coin=10000,less_stren=39};

get_upgrade(10223041) -> 
	#ets_equip_upgrade{goods_id=10223041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=3,protect_id=0,new_id=10223051,coin=20000,less_stren=49};

get_upgrade(10223051) -> 
	#ets_equip_upgrade{goods_id=10223051,trip_id=112203,trip_num=10,stone_id=601701,stone_num=0,iron_id=112706,iron_num=4,protect_id=0,new_id=10223061,coin=40000,less_stren=59};

get_upgrade(10223061) -> 
	#ets_equip_upgrade{goods_id=10223061,trip_id=112204,trip_num=14,stone_id=601701,stone_num=0,iron_id=112707,iron_num=5,protect_id=0,new_id=10223071,coin=80000,less_stren=69};

get_upgrade(10223071) -> 
	#ets_equip_upgrade{goods_id=10223071,trip_id=112205,trip_num=17,stone_id=601701,stone_num=0,iron_id=112708,iron_num=9,protect_id=0,new_id=10223081,coin=150000,less_stren=79};

get_upgrade(10231021) -> 
	#ets_equip_upgrade{goods_id=10231021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10231031,coin=5000,less_stren=29};

get_upgrade(10231031) -> 
	#ets_equip_upgrade{goods_id=10231031,trip_id=112201,trip_num=9,stone_id=601701,stone_num=0,iron_id=112704,iron_num=3,protect_id=0,new_id=10231041,coin=10000,less_stren=39};

get_upgrade(10231041) -> 
	#ets_equip_upgrade{goods_id=10231041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=3,protect_id=0,new_id=10231051,coin=20000,less_stren=49};

get_upgrade(10231051) -> 
	#ets_equip_upgrade{goods_id=10231051,trip_id=112203,trip_num=10,stone_id=601701,stone_num=0,iron_id=112706,iron_num=4,protect_id=0,new_id=10231061,coin=40000,less_stren=59};

get_upgrade(10231061) -> 
	#ets_equip_upgrade{goods_id=10231061,trip_id=112204,trip_num=14,stone_id=601701,stone_num=0,iron_id=112707,iron_num=5,protect_id=0,new_id=10231071,coin=80000,less_stren=69};

get_upgrade(10231071) -> 
	#ets_equip_upgrade{goods_id=10231071,trip_id=112205,trip_num=17,stone_id=601701,stone_num=0,iron_id=112708,iron_num=9,protect_id=0,new_id=10231081,coin=150000,less_stren=79};

get_upgrade(10232021) -> 
	#ets_equip_upgrade{goods_id=10232021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10232031,coin=5000,less_stren=29};

get_upgrade(10232031) -> 
	#ets_equip_upgrade{goods_id=10232031,trip_id=112201,trip_num=9,stone_id=601701,stone_num=0,iron_id=112704,iron_num=3,protect_id=0,new_id=10232041,coin=10000,less_stren=39};

get_upgrade(10232041) -> 
	#ets_equip_upgrade{goods_id=10232041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=3,protect_id=0,new_id=10232051,coin=20000,less_stren=49};

get_upgrade(10232051) -> 
	#ets_equip_upgrade{goods_id=10232051,trip_id=112203,trip_num=10,stone_id=601701,stone_num=0,iron_id=112706,iron_num=4,protect_id=0,new_id=10232061,coin=40000,less_stren=59};

get_upgrade(10232061) -> 
	#ets_equip_upgrade{goods_id=10232061,trip_id=112204,trip_num=14,stone_id=601701,stone_num=0,iron_id=112707,iron_num=5,protect_id=0,new_id=10232071,coin=80000,less_stren=69};

get_upgrade(10232071) -> 
	#ets_equip_upgrade{goods_id=10232071,trip_id=112205,trip_num=17,stone_id=601701,stone_num=0,iron_id=112708,iron_num=9,protect_id=0,new_id=10232081,coin=150000,less_stren=79};

get_upgrade(10233021) -> 
	#ets_equip_upgrade{goods_id=10233021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10233031,coin=5000,less_stren=29};

get_upgrade(10233031) -> 
	#ets_equip_upgrade{goods_id=10233031,trip_id=112201,trip_num=9,stone_id=601701,stone_num=0,iron_id=112704,iron_num=3,protect_id=0,new_id=10233041,coin=10000,less_stren=39};

get_upgrade(10233041) -> 
	#ets_equip_upgrade{goods_id=10233041,trip_id=112202,trip_num=8,stone_id=601701,stone_num=0,iron_id=112705,iron_num=3,protect_id=0,new_id=10233051,coin=20000,less_stren=49};

get_upgrade(10233051) -> 
	#ets_equip_upgrade{goods_id=10233051,trip_id=112203,trip_num=10,stone_id=601701,stone_num=0,iron_id=112706,iron_num=4,protect_id=0,new_id=10233061,coin=40000,less_stren=59};

get_upgrade(10233061) -> 
	#ets_equip_upgrade{goods_id=10233061,trip_id=112204,trip_num=14,stone_id=601701,stone_num=0,iron_id=112707,iron_num=5,protect_id=0,new_id=10233071,coin=80000,less_stren=69};

get_upgrade(10233071) -> 
	#ets_equip_upgrade{goods_id=10233071,trip_id=112205,trip_num=17,stone_id=601701,stone_num=0,iron_id=112708,iron_num=9,protect_id=0,new_id=10233081,coin=150000,less_stren=79};

get_upgrade(10241021) -> 
	#ets_equip_upgrade{goods_id=10241021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10241031,coin=5000,less_stren=29};

get_upgrade(10241031) -> 
	#ets_equip_upgrade{goods_id=10241031,trip_id=112201,trip_num=8,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10241041,coin=10000,less_stren=39};

get_upgrade(10241041) -> 
	#ets_equip_upgrade{goods_id=10241041,trip_id=112202,trip_num=6,stone_id=601701,stone_num=0,iron_id=112705,iron_num=2,protect_id=0,new_id=10241051,coin=20000,less_stren=49};

get_upgrade(10241051) -> 
	#ets_equip_upgrade{goods_id=10241051,trip_id=112203,trip_num=6,stone_id=601701,stone_num=0,iron_id=112706,iron_num=3,protect_id=0,new_id=10241061,coin=40000,less_stren=59};

get_upgrade(10241061) -> 
	#ets_equip_upgrade{goods_id=10241061,trip_id=112204,trip_num=8,stone_id=601701,stone_num=0,iron_id=112707,iron_num=4,protect_id=0,new_id=10241071,coin=80000,less_stren=69};

get_upgrade(10241071) -> 
	#ets_equip_upgrade{goods_id=10241071,trip_id=112205,trip_num=12,stone_id=601701,stone_num=0,iron_id=112708,iron_num=6,protect_id=0,new_id=10241081,coin=150000,less_stren=79};

get_upgrade(10242021) -> 
	#ets_equip_upgrade{goods_id=10242021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10242031,coin=5000,less_stren=29};

get_upgrade(10242031) -> 
	#ets_equip_upgrade{goods_id=10242031,trip_id=112201,trip_num=8,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10242041,coin=10000,less_stren=39};

get_upgrade(10242041) -> 
	#ets_equip_upgrade{goods_id=10242041,trip_id=112202,trip_num=6,stone_id=601701,stone_num=0,iron_id=112705,iron_num=2,protect_id=0,new_id=10242051,coin=20000,less_stren=49};

get_upgrade(10242051) -> 
	#ets_equip_upgrade{goods_id=10242051,trip_id=112203,trip_num=6,stone_id=601701,stone_num=0,iron_id=112706,iron_num=3,protect_id=0,new_id=10242061,coin=40000,less_stren=59};

get_upgrade(10242061) -> 
	#ets_equip_upgrade{goods_id=10242061,trip_id=112204,trip_num=8,stone_id=601701,stone_num=0,iron_id=112707,iron_num=4,protect_id=0,new_id=10242071,coin=80000,less_stren=69};

get_upgrade(10242071) -> 
	#ets_equip_upgrade{goods_id=10242071,trip_id=112205,trip_num=12,stone_id=601701,stone_num=0,iron_id=112708,iron_num=6,protect_id=0,new_id=10242081,coin=150000,less_stren=79};

get_upgrade(10243021) -> 
	#ets_equip_upgrade{goods_id=10243021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10243031,coin=5000,less_stren=29};

get_upgrade(10243031) -> 
	#ets_equip_upgrade{goods_id=10243031,trip_id=112201,trip_num=8,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10243041,coin=10000,less_stren=39};

get_upgrade(10243041) -> 
	#ets_equip_upgrade{goods_id=10243041,trip_id=112202,trip_num=6,stone_id=601701,stone_num=0,iron_id=112705,iron_num=2,protect_id=0,new_id=10243051,coin=20000,less_stren=49};

get_upgrade(10243051) -> 
	#ets_equip_upgrade{goods_id=10243051,trip_id=112203,trip_num=6,stone_id=601701,stone_num=0,iron_id=112706,iron_num=3,protect_id=0,new_id=10243061,coin=40000,less_stren=59};

get_upgrade(10243061) -> 
	#ets_equip_upgrade{goods_id=10243061,trip_id=112204,trip_num=8,stone_id=601701,stone_num=0,iron_id=112707,iron_num=4,protect_id=0,new_id=10243071,coin=80000,less_stren=69};

get_upgrade(10243071) -> 
	#ets_equip_upgrade{goods_id=10243071,trip_id=112205,trip_num=12,stone_id=601701,stone_num=0,iron_id=112708,iron_num=6,protect_id=0,new_id=10243081,coin=150000,less_stren=79};

get_upgrade(10251021) -> 
	#ets_equip_upgrade{goods_id=10251021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10251031,coin=5000,less_stren=29};

get_upgrade(10251031) -> 
	#ets_equip_upgrade{goods_id=10251031,trip_id=112201,trip_num=8,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10251041,coin=10000,less_stren=39};

get_upgrade(10251041) -> 
	#ets_equip_upgrade{goods_id=10251041,trip_id=112202,trip_num=6,stone_id=601701,stone_num=0,iron_id=112705,iron_num=2,protect_id=0,new_id=10251051,coin=20000,less_stren=49};

get_upgrade(10251051) -> 
	#ets_equip_upgrade{goods_id=10251051,trip_id=112203,trip_num=6,stone_id=601701,stone_num=0,iron_id=112706,iron_num=3,protect_id=0,new_id=10251061,coin=40000,less_stren=59};

get_upgrade(10251061) -> 
	#ets_equip_upgrade{goods_id=10251061,trip_id=112204,trip_num=8,stone_id=601701,stone_num=0,iron_id=112707,iron_num=4,protect_id=0,new_id=10251071,coin=80000,less_stren=69};

get_upgrade(10251071) -> 
	#ets_equip_upgrade{goods_id=10251071,trip_id=112205,trip_num=12,stone_id=601701,stone_num=0,iron_id=112708,iron_num=6,protect_id=0,new_id=10251081,coin=150000,less_stren=79};

get_upgrade(10252021) -> 
	#ets_equip_upgrade{goods_id=10252021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10252031,coin=5000,less_stren=29};

get_upgrade(10252031) -> 
	#ets_equip_upgrade{goods_id=10252031,trip_id=112201,trip_num=8,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10252041,coin=10000,less_stren=39};

get_upgrade(10252041) -> 
	#ets_equip_upgrade{goods_id=10252041,trip_id=112202,trip_num=6,stone_id=601701,stone_num=0,iron_id=112705,iron_num=2,protect_id=0,new_id=10252051,coin=20000,less_stren=49};

get_upgrade(10252051) -> 
	#ets_equip_upgrade{goods_id=10252051,trip_id=112203,trip_num=6,stone_id=601701,stone_num=0,iron_id=112706,iron_num=3,protect_id=0,new_id=10252061,coin=40000,less_stren=59};

get_upgrade(10252061) -> 
	#ets_equip_upgrade{goods_id=10252061,trip_id=112204,trip_num=8,stone_id=601701,stone_num=0,iron_id=112707,iron_num=4,protect_id=0,new_id=10252071,coin=80000,less_stren=69};

get_upgrade(10252071) -> 
	#ets_equip_upgrade{goods_id=10252071,trip_id=112205,trip_num=12,stone_id=601701,stone_num=0,iron_id=112708,iron_num=6,protect_id=0,new_id=10252081,coin=150000,less_stren=79};

get_upgrade(10253021) -> 
	#ets_equip_upgrade{goods_id=10253021,trip_id=112201,trip_num=5,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10253031,coin=5000,less_stren=29};

get_upgrade(10253031) -> 
	#ets_equip_upgrade{goods_id=10253031,trip_id=112201,trip_num=8,stone_id=601701,stone_num=0,iron_id=112704,iron_num=2,protect_id=0,new_id=10253041,coin=10000,less_stren=39};

get_upgrade(10253041) -> 
	#ets_equip_upgrade{goods_id=10253041,trip_id=112202,trip_num=6,stone_id=601701,stone_num=0,iron_id=112705,iron_num=2,protect_id=0,new_id=10253051,coin=20000,less_stren=49};

get_upgrade(10253051) -> 
	#ets_equip_upgrade{goods_id=10253051,trip_id=112203,trip_num=6,stone_id=601701,stone_num=0,iron_id=112706,iron_num=3,protect_id=0,new_id=10253061,coin=40000,less_stren=59};

get_upgrade(10253061) -> 
	#ets_equip_upgrade{goods_id=10253061,trip_id=112204,trip_num=8,stone_id=601701,stone_num=0,iron_id=112707,iron_num=4,protect_id=0,new_id=10253071,coin=80000,less_stren=69};

get_upgrade(10253071) -> 
	#ets_equip_upgrade{goods_id=10253071,trip_id=112205,trip_num=12,stone_id=601701,stone_num=0,iron_id=112708,iron_num=6,protect_id=0,new_id=10253081,coin=150000,less_stren=79};

get_upgrade(10300021) -> 
	#ets_equip_upgrade{goods_id=10300021,trip_id=112201,trip_num=2,stone_id=601701,stone_num=20,iron_id=112704,iron_num=1,protect_id=0,new_id=10300031,coin=5000,less_stren=34};

get_upgrade(10300031) -> 
	#ets_equip_upgrade{goods_id=10300031,trip_id=112201,trip_num=3,stone_id=601701,stone_num=1,iron_id=112704,iron_num=2,protect_id=0,new_id=10300041,coin=10000,less_stren=44};

get_upgrade(10300041) -> 
	#ets_equip_upgrade{goods_id=10300041,trip_id=112202,trip_num=2,stone_id=601701,stone_num=0,iron_id=112705,iron_num=2,protect_id=0,new_id=10300051,coin=20000,less_stren=54};

get_upgrade(10300051) -> 
	#ets_equip_upgrade{goods_id=10300051,trip_id=112203,trip_num=4,stone_id=601701,stone_num=0,iron_id=112706,iron_num=2,protect_id=0,new_id=10300061,coin=40000,less_stren=64};

get_upgrade(10300061) -> 
	#ets_equip_upgrade{goods_id=10300061,trip_id=112204,trip_num=5,stone_id=601701,stone_num=0,iron_id=112707,iron_num=3,protect_id=0,new_id=10300071,coin=80000,less_stren=74};

get_upgrade(10320021) -> 
	#ets_equip_upgrade{goods_id=10320021,trip_id=112201,trip_num=2,stone_id=601701,stone_num=1,iron_id=112704,iron_num=1,protect_id=0,new_id=10320031,coin=5000,less_stren=34};

get_upgrade(10320031) -> 
	#ets_equip_upgrade{goods_id=10320031,trip_id=112201,trip_num=4,stone_id=601701,stone_num=2,iron_id=112704,iron_num=2,protect_id=0,new_id=10320041,coin=10000,less_stren=44};

get_upgrade(10320041) -> 
	#ets_equip_upgrade{goods_id=10320041,trip_id=112202,trip_num=5,stone_id=601701,stone_num=4,iron_id=112705,iron_num=2,protect_id=0,new_id=10320051,coin=20000,less_stren=54};

get_upgrade(10320051) -> 
	#ets_equip_upgrade{goods_id=10320051,trip_id=112203,trip_num=6,stone_id=601701,stone_num=7,iron_id=112706,iron_num=3,protect_id=0,new_id=10320061,coin=40000,less_stren=64};

get_upgrade(10320061) -> 
	#ets_equip_upgrade{goods_id=10320061,trip_id=112204,trip_num=9,stone_id=601701,stone_num=10,iron_id=112707,iron_num=4,protect_id=0,new_id=10320071,coin=80000,less_stren=74};

get_upgrade(10331021) -> 
	#ets_equip_upgrade{goods_id=10331021,trip_id=112201,trip_num=3,stone_id=601701,stone_num=2,iron_id=112704,iron_num=1,protect_id=0,new_id=10331031,coin=5000,less_stren=34};

get_upgrade(10331031) -> 
	#ets_equip_upgrade{goods_id=10331031,trip_id=112201,trip_num=5,stone_id=601701,stone_num=3,iron_id=112704,iron_num=2,protect_id=0,new_id=10331041,coin=10000,less_stren=44};

get_upgrade(10331041) -> 
	#ets_equip_upgrade{goods_id=10331041,trip_id=112202,trip_num=6,stone_id=601701,stone_num=6,iron_id=112705,iron_num=2,protect_id=0,new_id=10331051,coin=20000,less_stren=54};

get_upgrade(10331051) -> 
	#ets_equip_upgrade{goods_id=10331051,trip_id=112203,trip_num=8,stone_id=601701,stone_num=9,iron_id=112706,iron_num=3,protect_id=0,new_id=10331061,coin=40000,less_stren=64};

get_upgrade(10331061) -> 
	#ets_equip_upgrade{goods_id=10331061,trip_id=112204,trip_num=11,stone_id=601701,stone_num=12,iron_id=112707,iron_num=4,protect_id=0,new_id=10331071,coin=80000,less_stren=74};

get_upgrade(10332021) -> 
	#ets_equip_upgrade{goods_id=10332021,trip_id=112201,trip_num=3,stone_id=601701,stone_num=2,iron_id=112704,iron_num=1,protect_id=0,new_id=10332031,coin=5000,less_stren=34};

get_upgrade(10332031) -> 
	#ets_equip_upgrade{goods_id=10332031,trip_id=112201,trip_num=5,stone_id=601701,stone_num=3,iron_id=112704,iron_num=2,protect_id=0,new_id=10332041,coin=10000,less_stren=44};

get_upgrade(10332041) -> 
	#ets_equip_upgrade{goods_id=10332041,trip_id=112202,trip_num=6,stone_id=601701,stone_num=6,iron_id=112705,iron_num=2,protect_id=0,new_id=10332051,coin=20000,less_stren=54};

get_upgrade(10332051) -> 
	#ets_equip_upgrade{goods_id=10332051,trip_id=112203,trip_num=8,stone_id=601701,stone_num=9,iron_id=112706,iron_num=3,protect_id=0,new_id=10332061,coin=40000,less_stren=64};

get_upgrade(10332061) -> 
	#ets_equip_upgrade{goods_id=10332061,trip_id=112204,trip_num=11,stone_id=601701,stone_num=12,iron_id=112707,iron_num=4,protect_id=0,new_id=10332071,coin=80000,less_stren=74};

get_upgrade(10333021) -> 
	#ets_equip_upgrade{goods_id=10333021,trip_id=112201,trip_num=3,stone_id=601701,stone_num=2,iron_id=112704,iron_num=1,protect_id=0,new_id=10333031,coin=5000,less_stren=34};

get_upgrade(10333031) -> 
	#ets_equip_upgrade{goods_id=10333031,trip_id=112201,trip_num=5,stone_id=601701,stone_num=3,iron_id=112704,iron_num=2,protect_id=0,new_id=10333041,coin=10000,less_stren=44};

get_upgrade(10333041) -> 
	#ets_equip_upgrade{goods_id=10333041,trip_id=112202,trip_num=6,stone_id=601701,stone_num=6,iron_id=112705,iron_num=2,protect_id=0,new_id=10333051,coin=20000,less_stren=54};

get_upgrade(10333051) -> 
	#ets_equip_upgrade{goods_id=10333051,trip_id=112203,trip_num=8,stone_id=601701,stone_num=9,iron_id=112706,iron_num=3,protect_id=0,new_id=10333061,coin=40000,less_stren=64};

get_upgrade(10333061) -> 
	#ets_equip_upgrade{goods_id=10333061,trip_id=112204,trip_num=11,stone_id=601701,stone_num=12,iron_id=112707,iron_num=4,protect_id=0,new_id=10333071,coin=80000,less_stren=74};

get_upgrade(_) ->
	[].



%%装备继承规则
get_inherit(0) -> 
	#ets_inherit{level=0,inherit_id=122601,num=1,coin=60000};

get_inherit(1) -> 
	#ets_inherit{level=1,inherit_id=122601,num=1,coin=60000};

get_inherit(2) -> 
	#ets_inherit{level=2,inherit_id=122601,num=1,coin=60000};

get_inherit(3) -> 
	#ets_inherit{level=3,inherit_id=122601,num=1,coin=60000};

get_inherit(4) -> 
	#ets_inherit{level=4,inherit_id=122601,num=1,coin=60000};

get_inherit(5) -> 
	#ets_inherit{level=5,inherit_id=122601,num=2,coin=60000};

get_inherit(6) -> 
	#ets_inherit{level=6,inherit_id=122601,num=3,coin=60000};

get_inherit(7) -> 
	#ets_inherit{level=7,inherit_id=122601,num=4,coin=60000};

get_inherit(_) ->
	[].



