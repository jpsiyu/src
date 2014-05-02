%%%---------------------------------------
%%% @Module  : data_king_dun
%%% @Author  : liangjianxiong
%%% @Email   : ljianxiong@qq.com
%%% @Created : 2014-04-29 16:16:32
%%% @Description:  皇家守卫军塔防副本配置
%%%---------------------------------------
-module(data_king_dun).
-compile(export_all).
-include("king_dun.hrl").

get(1) -> 
        #king_dun_data{level=1, mon_id=35101, mon_name = <<"">>, mon_count=15, time=3, direction=[{1,5},{2,5},{3,5}], exp=10000, score=9, kill_mon=[], next_level=0};
get(2) -> 
        #king_dun_data{level=2, mon_id=35102, mon_name = <<"">>, mon_count=15, time=50, direction=[{1,5},{2,5},{3,5}], exp=11000, score=10, kill_mon=[], next_level=0};
get(3) -> 
        #king_dun_data{level=3, mon_id=35103, mon_name = <<"">>, mon_count=15, time=50, direction=[{1,5},{2,5},{3,5}], exp=12000, score=10, kill_mon=[], next_level=0};
get(4) -> 
        #king_dun_data{level=4, mon_id=35104, mon_name = <<"">>, mon_count=15, time=50, direction=[{1,5},{2,5},{3,5}], exp=13000, score=11, kill_mon=[], next_level=0};
get(5) -> 
        #king_dun_data{level=5, mon_id=35105, mon_name = <<"">>, mon_count=1, time=50, direction=[{2,1}], exp=14000, score=60, kill_mon=[1,2,3,4,6,7,8,9], next_level=10};
get(6) -> 
        #king_dun_data{level=6, mon_id=35106, mon_name = <<"">>, mon_count=15, time=50, direction=[{1,5},{2,5},{3,5}], exp=15000, score=11, kill_mon=[], next_level=0};
get(7) -> 
        #king_dun_data{level=7, mon_id=35107, mon_name = <<"">>, mon_count=15, time=50, direction=[{1,5},{2,5},{3,5}], exp=16000, score=12, kill_mon=[], next_level=0};
get(8) -> 
        #king_dun_data{level=8, mon_id=35108, mon_name = <<"">>, mon_count=15, time=50, direction=[{1,5},{2,5},{3,5}], exp=17000, score=12, kill_mon=[], next_level=0};
get(9) -> 
        #king_dun_data{level=9, mon_id=35109, mon_name = <<"">>, mon_count=15, time=50, direction=[{1,5},{2,5},{3,5}], exp=18000, score=13, kill_mon=[], next_level=0};
get(10) -> 
        #king_dun_data{level=10, mon_id=35110, mon_name = <<"">>, mon_count=1, time=40, direction=[{2,1}], exp=19000, score=110, kill_mon=[11,12,13,14], next_level=15};
get(11) -> 
        #king_dun_data{level=11, mon_id=35111, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=20000, score=13, kill_mon=[], next_level=0};
get(12) -> 
        #king_dun_data{level=12, mon_id=35112, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=21000, score=14, kill_mon=[], next_level=0};
get(13) -> 
        #king_dun_data{level=13, mon_id=35113, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=22000, score=14, kill_mon=[], next_level=0};
get(14) -> 
        #king_dun_data{level=14, mon_id=35114, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=23000, score=15, kill_mon=[], next_level=0};
get(15) -> 
        #king_dun_data{level=15, mon_id=35115, mon_name = <<"">>, mon_count=1, time=40, direction=[{2,1}], exp=24000, score=160, kill_mon=[16,17,18,19], next_level=20};
get(16) -> 
        #king_dun_data{level=16, mon_id=35116, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=25000, score=15, kill_mon=[], next_level=0};
get(17) -> 
        #king_dun_data{level=17, mon_id=35117, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=26000, score=16, kill_mon=[], next_level=0};
get(18) -> 
        #king_dun_data{level=18, mon_id=35118, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=27000, score=16, kill_mon=[], next_level=0};
get(19) -> 
        #king_dun_data{level=19, mon_id=35119, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=28000, score=17, kill_mon=[], next_level=0};
get(20) -> 
        #king_dun_data{level=20, mon_id=35120, mon_name = <<"">>, mon_count=1, time=40, direction=[{2,1}], exp=29000, score=210, kill_mon=[21,22,23,24], next_level=25};
get(21) -> 
        #king_dun_data{level=21, mon_id=35121, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=30000, score=17, kill_mon=[], next_level=0};
get(22) -> 
        #king_dun_data{level=22, mon_id=35122, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=31000, score=18, kill_mon=[], next_level=0};
get(23) -> 
        #king_dun_data{level=23, mon_id=35123, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=32000, score=18, kill_mon=[], next_level=0};
get(24) -> 
        #king_dun_data{level=24, mon_id=35124, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=33000, score=19, kill_mon=[], next_level=0};
get(25) -> 
        #king_dun_data{level=25, mon_id=35125, mon_name = <<"">>, mon_count=1, time=40, direction=[{2,1}], exp=34000, score=260, kill_mon=[26,27,28,29], next_level=30};
get(26) -> 
        #king_dun_data{level=26, mon_id=35126, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=35000, score=19, kill_mon=[], next_level=0};
get(27) -> 
        #king_dun_data{level=27, mon_id=35127, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=36000, score=20, kill_mon=[], next_level=0};
get(28) -> 
        #king_dun_data{level=28, mon_id=35128, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=37000, score=20, kill_mon=[], next_level=0};
get(29) -> 
        #king_dun_data{level=29, mon_id=35129, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=38000, score=21, kill_mon=[], next_level=0};
get(30) -> 
        #king_dun_data{level=30, mon_id=35130, mon_name = <<"">>, mon_count=1, time=40, direction=[{2,1}], exp=39000, score=310, kill_mon=[31,32,33,34], next_level=35};
get(31) -> 
        #king_dun_data{level=31, mon_id=35131, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=40000, score=21, kill_mon=[], next_level=0};
get(32) -> 
        #king_dun_data{level=32, mon_id=35132, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=41000, score=22, kill_mon=[], next_level=0};
get(33) -> 
        #king_dun_data{level=33, mon_id=35133, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=42000, score=22, kill_mon=[], next_level=0};
get(34) -> 
        #king_dun_data{level=34, mon_id=35134, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=43000, score=23, kill_mon=[], next_level=0};
get(35) -> 
        #king_dun_data{level=35, mon_id=35135, mon_name = <<"">>, mon_count=1, time=40, direction=[{2,1}], exp=44000, score=360, kill_mon=[36,37,38,39], next_level=40};
get(36) -> 
        #king_dun_data{level=36, mon_id=35136, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=45000, score=23, kill_mon=[], next_level=0};
get(37) -> 
        #king_dun_data{level=37, mon_id=35137, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=46000, score=24, kill_mon=[], next_level=0};
get(38) -> 
        #king_dun_data{level=38, mon_id=35138, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=47000, score=24, kill_mon=[], next_level=0};
get(39) -> 
        #king_dun_data{level=39, mon_id=35139, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=48000, score=25, kill_mon=[], next_level=0};
get(40) -> 
        #king_dun_data{level=40, mon_id=35140, mon_name = <<"">>, mon_count=1, time=40, direction=[{2,1}], exp=49000, score=410, kill_mon=[41,42,43,44], next_level=45};
get(41) -> 
        #king_dun_data{level=41, mon_id=35141, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=50000, score=25, kill_mon=[], next_level=0};
get(42) -> 
        #king_dun_data{level=42, mon_id=35142, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=51000, score=26, kill_mon=[], next_level=0};
get(43) -> 
        #king_dun_data{level=43, mon_id=35143, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=52000, score=26, kill_mon=[], next_level=0};
get(44) -> 
        #king_dun_data{level=44, mon_id=35144, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=53000, score=27, kill_mon=[], next_level=0};
get(45) -> 
        #king_dun_data{level=45, mon_id=35145, mon_name = <<"">>, mon_count=1, time=40, direction=[{2,1}], exp=54000, score=460, kill_mon=[46,47,48,49], next_level=50};
get(46) -> 
        #king_dun_data{level=46, mon_id=35146, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=55000, score=27, kill_mon=[], next_level=0};
get(47) -> 
        #king_dun_data{level=47, mon_id=35147, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=56000, score=28, kill_mon=[], next_level=0};
get(48) -> 
        #king_dun_data{level=48, mon_id=35148, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=57000, score=28, kill_mon=[], next_level=0};
get(49) -> 
        #king_dun_data{level=49, mon_id=35149, mon_name = <<"">>, mon_count=15, time=40, direction=[{1,5},{2,5},{3,5}], exp=58000, score=29, kill_mon=[], next_level=0};
get(50) -> 
        #king_dun_data{level=50, mon_id=35150, mon_name = <<"">>, mon_count=1, time=40, direction=[{2,1}], exp=59000, score=510, kill_mon=[], next_level=0};
get(_Level) ->
	#king_dun_data{}.
