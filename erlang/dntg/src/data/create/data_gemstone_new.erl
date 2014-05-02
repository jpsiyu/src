%%%---------------------------------------
%%% @Module  : data_gemstone_new
%%% @Description : 宝石系统
%%%---------------------------------------
-module(data_gemstone_new).
-compile(export_all).
-include("gemstone.hrl").


get_gemstone_active(1,1) -> 
	#gemstone_active{equip_pos=1,gem_pos=1,type=3,cost=20000,equip_min=30};

get_gemstone_active(1,2) -> 
	#gemstone_active{equip_pos=1,gem_pos=2,type=7,cost=50000,equip_min=40};

get_gemstone_active(1,3) -> 
	#gemstone_active{equip_pos=1,gem_pos=3,type=5,cost=100000,equip_min=50};

get_gemstone_active(1,4) -> 
	#gemstone_active{equip_pos=1,gem_pos=4,type=9,cost=200000,equip_min=60};

get_gemstone_active(2,1) -> 
	#gemstone_active{equip_pos=2,gem_pos=1,type=4,cost=20000,equip_min=30};

get_gemstone_active(2,2) -> 
	#gemstone_active{equip_pos=2,gem_pos=2,type=16,cost=50000,equip_min=40};

get_gemstone_active(2,3) -> 
	#gemstone_active{equip_pos=2,gem_pos=3,type=8,cost=100000,equip_min=50};

get_gemstone_active(2,4) -> 
	#gemstone_active{equip_pos=2,gem_pos=4,type=10,cost=200000,equip_min=60};

get_gemstone_active(3,1) -> 
	#gemstone_active{equip_pos=3,gem_pos=1,type=1,cost=20000,equip_min=30};

get_gemstone_active(3,2) -> 
	#gemstone_active{equip_pos=3,gem_pos=2,type=16,cost=50000,equip_min=40};

get_gemstone_active(3,3) -> 
	#gemstone_active{equip_pos=3,gem_pos=3,type=4,cost=100000,equip_min=50};

get_gemstone_active(3,4) -> 
	#gemstone_active{equip_pos=3,gem_pos=4,type=12,cost=200000,equip_min=60};

get_gemstone_active(4,1) -> 
	#gemstone_active{equip_pos=4,gem_pos=1,type=16,cost=20000,equip_min=30};

get_gemstone_active(4,2) -> 
	#gemstone_active{equip_pos=4,gem_pos=2,type=6,cost=50000,equip_min=40};

get_gemstone_active(4,3) -> 
	#gemstone_active{equip_pos=4,gem_pos=3,type=8,cost=100000,equip_min=50};

get_gemstone_active(4,4) -> 
	#gemstone_active{equip_pos=4,gem_pos=4,type=10,cost=200000,equip_min=60};

get_gemstone_active(5,1) -> 
	#gemstone_active{equip_pos=5,gem_pos=1,type=6,cost=20000,equip_min=30};

get_gemstone_active(5,2) -> 
	#gemstone_active{equip_pos=5,gem_pos=2,type=4,cost=50000,equip_min=40};

get_gemstone_active(5,3) -> 
	#gemstone_active{equip_pos=5,gem_pos=3,type=1,cost=100000,equip_min=50};

get_gemstone_active(5,4) -> 
	#gemstone_active{equip_pos=5,gem_pos=4,type=10,cost=200000,equip_min=60};

get_gemstone_active(6,1) -> 
	#gemstone_active{equip_pos=6,gem_pos=1,type=4,cost=20000,equip_min=30};

get_gemstone_active(6,2) -> 
	#gemstone_active{equip_pos=6,gem_pos=2,type=1,cost=50000,equip_min=40};

get_gemstone_active(6,3) -> 
	#gemstone_active{equip_pos=6,gem_pos=3,type=8,cost=100000,equip_min=50};

get_gemstone_active(6,4) -> 
	#gemstone_active{equip_pos=6,gem_pos=4,type=12,cost=200000,equip_min=60};

get_gemstone_active(7,1) -> 
	#gemstone_active{equip_pos=7,gem_pos=1,type=4,cost=20000,equip_min=30};

get_gemstone_active(7,2) -> 
	#gemstone_active{equip_pos=7,gem_pos=2,type=6,cost=50000,equip_min=40};

get_gemstone_active(7,3) -> 
	#gemstone_active{equip_pos=7,gem_pos=3,type=1,cost=100000,equip_min=50};

get_gemstone_active(7,4) -> 
	#gemstone_active{equip_pos=7,gem_pos=4,type=12,cost=200000,equip_min=60};

get_gemstone_active(8,1) -> 
	#gemstone_active{equip_pos=8,gem_pos=1,type=16,cost=20000,equip_min=30};

get_gemstone_active(8,2) -> 
	#gemstone_active{equip_pos=8,gem_pos=2,type=6,cost=50000,equip_min=40};

get_gemstone_active(8,3) -> 
	#gemstone_active{equip_pos=8,gem_pos=3,type=8,cost=100000,equip_min=50};

get_gemstone_active(8,4) -> 
	#gemstone_active{equip_pos=8,gem_pos=4,type=10,cost=200000,equip_min=60};

get_gemstone_active(9,1) -> 
	#gemstone_active{equip_pos=9,gem_pos=1,type=16,cost=20000,equip_min=30};

get_gemstone_active(9,2) -> 
	#gemstone_active{equip_pos=9,gem_pos=2,type=6,cost=50000,equip_min=40};

get_gemstone_active(9,3) -> 
	#gemstone_active{equip_pos=9,gem_pos=3,type=8,cost=100000,equip_min=50};

get_gemstone_active(9,4) -> 
	#gemstone_active{equip_pos=9,gem_pos=4,type=10,cost=200000,equip_min=60};

get_gemstone_active(10,1) -> 
	#gemstone_active{equip_pos=10,gem_pos=1,type=7,cost=20000,equip_min=30};

get_gemstone_active(10,2) -> 
	#gemstone_active{equip_pos=10,gem_pos=2,type=5,cost=50000,equip_min=40};

get_gemstone_active(10,3) -> 
	#gemstone_active{equip_pos=10,gem_pos=3,type=3,cost=100000,equip_min=50};

get_gemstone_active(10,4) -> 
	#gemstone_active{equip_pos=10,gem_pos=4,type=11,cost=200000,equip_min=60};

get_gemstone_active(11,1) -> 
	#gemstone_active{equip_pos=11,gem_pos=1,type=7,cost=20000,equip_min=30};

get_gemstone_active(11,2) -> 
	#gemstone_active{equip_pos=11,gem_pos=2,type=5,cost=50000,equip_min=40};

get_gemstone_active(11,3) -> 
	#gemstone_active{equip_pos=11,gem_pos=3,type=3,cost=100000,equip_min=50};

get_gemstone_active(11,4) -> 
	#gemstone_active{equip_pos=11,gem_pos=4,type=11,cost=200000,equip_min=60};

get_gemstone_active(12,1) -> 
	#gemstone_active{equip_pos=12,gem_pos=1,type=5,cost=20000,equip_min=30};

get_gemstone_active(12,2) -> 
	#gemstone_active{equip_pos=12,gem_pos=2,type=3,cost=50000,equip_min=40};

get_gemstone_active(12,3) -> 
	#gemstone_active{equip_pos=12,gem_pos=3,type=7,cost=100000,equip_min=50};

get_gemstone_active(12,4) -> 
	#gemstone_active{equip_pos=12,gem_pos=4,type=9,cost=200000,equip_min=60};

get_gemstone_active(_EquipPos, _GemPos) -> 
    [].

get_gemstone_attr(1,1) -> 
	#gemstone_attr{type=1,level=1,exp_limit=75,attr=200};

get_gemstone_attr(1,2) -> 
	#gemstone_attr{type=1,level=2,exp_limit=110,attr=375};

get_gemstone_attr(1,3) -> 
	#gemstone_attr{type=1,level=3,exp_limit=170,attr=562};

get_gemstone_attr(1,4) -> 
	#gemstone_attr{type=1,level=4,exp_limit=254,attr=774};

get_gemstone_attr(1,5) -> 
	#gemstone_attr{type=1,level=5,exp_limit=449,attr=1023};

get_gemstone_attr(1,6) -> 
	#gemstone_attr{type=1,level=6,exp_limit=796,attr=1322};

get_gemstone_attr(1,7) -> 
	#gemstone_attr{type=1,level=7,exp_limit=1195,attr=1633};

get_gemstone_attr(1,8) -> 
	#gemstone_attr{type=1,level=8,exp_limit=1744,attr=1994};

get_gemstone_attr(1,9) -> 
	#gemstone_attr{type=1,level=9,exp_limit=2790,attr=2405};

get_gemstone_attr(1,10) -> 
	#gemstone_attr{type=1,level=10,exp_limit=0,attr=2928};

get_gemstone_attr(3,1) -> 
	#gemstone_attr{type=3,level=1,exp_limit=90,attr=16};

get_gemstone_attr(3,2) -> 
	#gemstone_attr{type=3,level=2,exp_limit=132,attr=30};

get_gemstone_attr(3,3) -> 
	#gemstone_attr{type=3,level=3,exp_limit=204,attr=45};

get_gemstone_attr(3,4) -> 
	#gemstone_attr{type=3,level=4,exp_limit=306,attr=62};

get_gemstone_attr(3,5) -> 
	#gemstone_attr{type=3,level=5,exp_limit=540,attr=82};

get_gemstone_attr(3,6) -> 
	#gemstone_attr{type=3,level=6,exp_limit=960,attr=106};

get_gemstone_attr(3,7) -> 
	#gemstone_attr{type=3,level=7,exp_limit=1440,attr=131};

get_gemstone_attr(3,8) -> 
	#gemstone_attr{type=3,level=8,exp_limit=2100,attr=160};

get_gemstone_attr(3,9) -> 
	#gemstone_attr{type=3,level=9,exp_limit=3360,attr=193};

get_gemstone_attr(3,10) -> 
	#gemstone_attr{type=3,level=10,exp_limit=0,attr=235};

get_gemstone_attr(4,1) -> 
	#gemstone_attr{type=4,level=1,exp_limit=25,attr=15};

get_gemstone_attr(4,2) -> 
	#gemstone_attr{type=4,level=2,exp_limit=37,attr=27};

get_gemstone_attr(4,3) -> 
	#gemstone_attr{type=4,level=3,exp_limit=78,attr=40};

get_gemstone_attr(4,4) -> 
	#gemstone_attr{type=4,level=4,exp_limit=130,attr=60};

get_gemstone_attr(4,5) -> 
	#gemstone_attr{type=4,level=5,exp_limit=221,attr=86};

get_gemstone_attr(4,6) -> 
	#gemstone_attr{type=4,level=6,exp_limit=427,attr=116};

get_gemstone_attr(4,7) -> 
	#gemstone_attr{type=4,level=7,exp_limit=600,attr=150};

get_gemstone_attr(4,8) -> 
	#gemstone_attr{type=4,level=8,exp_limit=790,attr=187};

get_gemstone_attr(4,9) -> 
	#gemstone_attr{type=4,level=9,exp_limit=1229,attr=225};

get_gemstone_attr(4,10) -> 
	#gemstone_attr{type=4,level=10,exp_limit=0,attr=272};

get_gemstone_attr(5,1) -> 
	#gemstone_attr{type=5,level=1,exp_limit=17,attr=10};

get_gemstone_attr(5,2) -> 
	#gemstone_attr{type=5,level=2,exp_limit=27,attr=18};

get_gemstone_attr(5,3) -> 
	#gemstone_attr{type=5,level=3,exp_limit=57,attr=27};

get_gemstone_attr(5,4) -> 
	#gemstone_attr{type=5,level=4,exp_limit=93,attr=41};

get_gemstone_attr(5,5) -> 
	#gemstone_attr{type=5,level=5,exp_limit=160,attr=59};

get_gemstone_attr(5,6) -> 
	#gemstone_attr{type=5,level=6,exp_limit=313,attr=80};

get_gemstone_attr(5,7) -> 
	#gemstone_attr{type=5,level=7,exp_limit=438,attr=104};

get_gemstone_attr(5,8) -> 
	#gemstone_attr{type=5,level=8,exp_limit=583,attr=130};

get_gemstone_attr(5,9) -> 
	#gemstone_attr{type=5,level=9,exp_limit=896,attr=157};

get_gemstone_attr(5,10) -> 
	#gemstone_attr{type=5,level=10,exp_limit=0,attr=190};

get_gemstone_attr(6,1) -> 
	#gemstone_attr{type=6,level=1,exp_limit=17,attr=8};

get_gemstone_attr(6,2) -> 
	#gemstone_attr{type=6,level=2,exp_limit=24,attr=15};

get_gemstone_attr(6,3) -> 
	#gemstone_attr{type=6,level=3,exp_limit=56,attr=22};

get_gemstone_attr(6,4) -> 
	#gemstone_attr{type=6,level=4,exp_limit=89,attr=34};

get_gemstone_attr(6,5) -> 
	#gemstone_attr{type=6,level=5,exp_limit=157,attr=49};

get_gemstone_attr(6,6) -> 
	#gemstone_attr{type=6,level=6,exp_limit=312,attr=67};

get_gemstone_attr(6,7) -> 
	#gemstone_attr{type=6,level=7,exp_limit=461,attr=88};

get_gemstone_attr(6,8) -> 
	#gemstone_attr{type=6,level=8,exp_limit=615,attr=112};

get_gemstone_attr(6,9) -> 
	#gemstone_attr{type=6,level=9,exp_limit=990,attr=137};

get_gemstone_attr(6,10) -> 
	#gemstone_attr{type=6,level=10,exp_limit=0,attr=169};

get_gemstone_attr(7,1) -> 
	#gemstone_attr{type=7,level=1,exp_limit=28,attr=6};

get_gemstone_attr(7,2) -> 
	#gemstone_attr{type=7,level=2,exp_limit=46,attr=11};

get_gemstone_attr(7,3) -> 
	#gemstone_attr{type=7,level=3,exp_limit=93,attr=17};

get_gemstone_attr(7,4) -> 
	#gemstone_attr{type=7,level=4,exp_limit=158,attr=26};

get_gemstone_attr(7,5) -> 
	#gemstone_attr{type=7,level=5,exp_limit=272,attr=38};

get_gemstone_attr(7,6) -> 
	#gemstone_attr{type=7,level=6,exp_limit=530,attr=52};

get_gemstone_attr(7,7) -> 
	#gemstone_attr{type=7,level=7,exp_limit=728,attr=68};

get_gemstone_attr(7,8) -> 
	#gemstone_attr{type=7,level=8,exp_limit=988,attr=85};

get_gemstone_attr(7,9) -> 
	#gemstone_attr{type=7,level=9,exp_limit=1518,attr=103};

get_gemstone_attr(7,10) -> 
	#gemstone_attr{type=7,level=10,exp_limit=0,attr=125};

get_gemstone_attr(8,1) -> 
	#gemstone_attr{type=8,level=1,exp_limit=28,attr=12};

get_gemstone_attr(8,2) -> 
	#gemstone_attr{type=8,level=2,exp_limit=46,attr=22};

get_gemstone_attr(8,3) -> 
	#gemstone_attr{type=8,level=3,exp_limit=94,attr=34};

get_gemstone_attr(8,4) -> 
	#gemstone_attr{type=8,level=4,exp_limit=160,attr=52};

get_gemstone_attr(8,5) -> 
	#gemstone_attr{type=8,level=5,exp_limit=275,attr=76};

get_gemstone_attr(8,6) -> 
	#gemstone_attr{type=8,level=6,exp_limit=536,attr=104};

get_gemstone_attr(8,7) -> 
	#gemstone_attr{type=8,level=7,exp_limit=735,attr=136};

get_gemstone_attr(8,8) -> 
	#gemstone_attr{type=8,level=8,exp_limit=998,attr=170};

get_gemstone_attr(8,9) -> 
	#gemstone_attr{type=8,level=9,exp_limit=1534,attr=206};

get_gemstone_attr(8,10) -> 
	#gemstone_attr{type=8,level=10,exp_limit=0,attr=250};

get_gemstone_attr(9,1) -> 
	#gemstone_attr{type=9,level=1,exp_limit=115,attr=19};

get_gemstone_attr(9,2) -> 
	#gemstone_attr{type=9,level=2,exp_limit=166,attr=36};

get_gemstone_attr(9,3) -> 
	#gemstone_attr{type=9,level=3,exp_limit=252,attr=54};

get_gemstone_attr(9,4) -> 
	#gemstone_attr{type=9,level=4,exp_limit=386,attr=74};

get_gemstone_attr(9,5) -> 
	#gemstone_attr{type=9,level=5,exp_limit=685,attr=98};

get_gemstone_attr(9,6) -> 
	#gemstone_attr{type=9,level=6,exp_limit=1210,attr=127};

get_gemstone_attr(9,7) -> 
	#gemstone_attr{type=9,level=7,exp_limit=1825,attr=157};

get_gemstone_attr(9,8) -> 
	#gemstone_attr{type=9,level=8,exp_limit=2606,attr=192};

get_gemstone_attr(9,9) -> 
	#gemstone_attr{type=9,level=9,exp_limit=4284,attr=231};

get_gemstone_attr(9,10) -> 
	#gemstone_attr{type=9,level=10,exp_limit=0,attr=282};

get_gemstone_attr(10,1) -> 
	#gemstone_attr{type=10,level=1,exp_limit=21,attr=5};

get_gemstone_attr(10,2) -> 
	#gemstone_attr{type=10,level=2,exp_limit=29,attr=9};

get_gemstone_attr(10,3) -> 
	#gemstone_attr{type=10,level=3,exp_limit=70,attr=13};

get_gemstone_attr(10,4) -> 
	#gemstone_attr{type=10,level=4,exp_limit=101,attr=20};

get_gemstone_attr(10,5) -> 
	#gemstone_attr{type=10,level=5,exp_limit=186,attr=28};

get_gemstone_attr(10,6) -> 
	#gemstone_attr{type=10,level=6,exp_limit=350,attr=38};

get_gemstone_attr(10,7) -> 
	#gemstone_attr{type=10,level=7,exp_limit=535,attr=49};

get_gemstone_attr(10,8) -> 
	#gemstone_attr{type=10,level=8,exp_limit=685,attr=62};

get_gemstone_attr(10,9) -> 
	#gemstone_attr{type=10,level=9,exp_limit=1126,attr=75};

get_gemstone_attr(10,10) -> 
	#gemstone_attr{type=10,level=10,exp_limit=0,attr=92};

get_gemstone_attr(11,1) -> 
	#gemstone_attr{type=11,level=1,exp_limit=35,attr=8};

get_gemstone_attr(11,2) -> 
	#gemstone_attr{type=11,level=2,exp_limit=56,attr=14};

get_gemstone_attr(11,3) -> 
	#gemstone_attr{type=11,level=3,exp_limit=109,attr=21};

get_gemstone_attr(11,4) -> 
	#gemstone_attr{type=11,level=4,exp_limit=181,attr=31};

get_gemstone_attr(11,5) -> 
	#gemstone_attr{type=11,level=5,exp_limit=307,attr=44};

get_gemstone_attr(11,6) -> 
	#gemstone_attr{type=11,level=6,exp_limit=594,attr=59};

get_gemstone_attr(11,7) -> 
	#gemstone_attr{type=11,level=7,exp_limit=858,attr=76};

get_gemstone_attr(11,8) -> 
	#gemstone_attr{type=11,level=8,exp_limit=1100,attr=95};

get_gemstone_attr(11,9) -> 
	#gemstone_attr{type=11,level=9,exp_limit=1673,attr=114};

get_gemstone_attr(11,10) -> 
	#gemstone_attr{type=11,level=10,exp_limit=0,attr=137};

get_gemstone_attr(12,1) -> 
	#gemstone_attr{type=12,level=1,exp_limit=90,attr=15};

get_gemstone_attr(12,2) -> 
	#gemstone_attr{type=12,level=2,exp_limit=122,attr=28};

get_gemstone_attr(12,3) -> 
	#gemstone_attr{type=12,level=3,exp_limit=193,attr=41};

get_gemstone_attr(12,4) -> 
	#gemstone_attr{type=12,level=4,exp_limit=295,attr=56};

get_gemstone_attr(12,5) -> 
	#gemstone_attr{type=12,level=5,exp_limit=506,attr=74};

get_gemstone_attr(12,6) -> 
	#gemstone_attr{type=12,level=6,exp_limit=905,attr=95};

get_gemstone_attr(12,7) -> 
	#gemstone_attr{type=12,level=7,exp_limit=1330,attr=117};

get_gemstone_attr(12,8) -> 
	#gemstone_attr{type=12,level=8,exp_limit=1977,attr=142};

get_gemstone_attr(12,9) -> 
	#gemstone_attr{type=12,level=9,exp_limit=3171,attr=171};

get_gemstone_attr(12,10) -> 
	#gemstone_attr{type=12,level=10,exp_limit=0,attr=208};

get_gemstone_attr(16,1) -> 
	#gemstone_attr{type=16,level=1,exp_limit=25,attr=15};

get_gemstone_attr(16,2) -> 
	#gemstone_attr{type=16,level=2,exp_limit=37,attr=27};

get_gemstone_attr(16,3) -> 
	#gemstone_attr{type=16,level=3,exp_limit=78,attr=40};

get_gemstone_attr(16,4) -> 
	#gemstone_attr{type=16,level=4,exp_limit=130,attr=60};

get_gemstone_attr(16,5) -> 
	#gemstone_attr{type=16,level=5,exp_limit=221,attr=86};

get_gemstone_attr(16,6) -> 
	#gemstone_attr{type=16,level=6,exp_limit=427,attr=116};

get_gemstone_attr(16,7) -> 
	#gemstone_attr{type=16,level=7,exp_limit=600,attr=150};

get_gemstone_attr(16,8) -> 
	#gemstone_attr{type=16,level=8,exp_limit=790,attr=187};

get_gemstone_attr(16,9) -> 
	#gemstone_attr{type=16,level=9,exp_limit=1229,attr=225};

get_gemstone_attr(16,10) -> 
	#gemstone_attr{type=16,level=10,exp_limit=0,attr=272};

get_gemstone_attr(_Type, _Level) -> 
    [].

get_gemstone_upgrade(111481) -> 
	#gemstone_upgrade{goods_type_id=111481,add_exp=[{3,10},{5,10},{7,10}]};

get_gemstone_upgrade(111482) -> 
	#gemstone_upgrade{goods_type_id=111482,add_exp=[{3,30},{5,30},{7,30}]};

get_gemstone_upgrade(111483) -> 
	#gemstone_upgrade{goods_type_id=111483,add_exp=[{3,90},{5,90},{7,90}]};

get_gemstone_upgrade(111491) -> 
	#gemstone_upgrade{goods_type_id=111491,add_exp=[{1,10},{4,10},{6,10},{16,10},{8,10}]};

get_gemstone_upgrade(111492) -> 
	#gemstone_upgrade{goods_type_id=111492,add_exp=[{1,30},{4,30},{6,30},{16,30},{8,30}]};

get_gemstone_upgrade(111493) -> 
	#gemstone_upgrade{goods_type_id=111493,add_exp=[{1,90},{4,90},{6,90},{16,90},{8,90}]};

get_gemstone_upgrade(111501) -> 
	#gemstone_upgrade{goods_type_id=111501,add_exp=[{10,10},{11,10},{12,10},{9,10}]};

get_gemstone_upgrade(111502) -> 
	#gemstone_upgrade{goods_type_id=111502,add_exp=[{10,30},{11,30},{12,30},{9,30}]};

get_gemstone_upgrade(111503) -> 
	#gemstone_upgrade{goods_type_id=111503,add_exp=[{10,90},{11,90},{12,90},{9,90}]};

get_gemstone_upgrade(_GoodsTypeId) -> 
    [].

