%%%---------------------------------------
%%% @Module  : data_tower
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  爬塔
%%%---------------------------------------
-module(data_tower).
-compile(export_all).
-include("tower.hrl").


get(300) -> 
	#tower{sid=300, time=200, level=1, exp=21000, llpt=0, items=[], total_exp=21000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30092,60],[30093,35],[30094,5]], mon_place= [{32, 54},{7,41},{17,20}]};
get(301) -> 
	#tower{sid=301, time=200, level=2, exp=24000, llpt=0, items=[], total_exp=45000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=30, box_count=1, box_mon_rate=[[30092,60],[30093,35],[30094,5]], mon_place=[{13,36},{23,28},{24,55},{36,45}]};
get(302) -> 
	#tower{sid=302, time=200, level=3, exp=27000, llpt=0, items=[], total_exp=72000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=20, box_count=1, box_mon_rate=[[30092,60],[30093,35],[30094,5]], mon_place=[{39,60},{40,41},{27,57},{17,39},{28,27}]};
get(303) -> 
	#tower{sid=303, time=260, level=5, exp=33000, llpt=0, items=[], total_exp=135000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=30, box_count=1, box_mon_rate=[[30092,60],[30093,35],[30094,5]], mon_place=[{23,41},{31,26},{28,52},{46,50},{36,51}]};
get(304) -> 
	#tower{sid=304, time=200, level=6, exp=36000, llpt=0, items=[], total_exp=171000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=10, box_count=1, box_mon_rate=[[30092,60],[30093,35],[30094,5]], mon_place=[{26,51},{31,39},{22,36},{16,44},{19,55}]};
get(305) -> 
	#tower{sid=305, time=200, level=7, exp=39000, llpt=0, items=[], total_exp=210000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=20, box_count=1, box_mon_rate=[[30092,60],[30093,35],[30094,5]], mon_place=[{12,18},{3,24},{9,29},{9,61},{20,42},{31,51}]};
get(306) -> 
	#tower{sid=306, time=260, level=10, exp=48000, llpt=0, items=[], total_exp=345000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=30, box_count=1, box_mon_rate=[[30092,60],[30093,35],[30094,5]], mon_place=[{36,40},{18,48},{4,32},{28,23},{12,10}]};
get(307) -> 
	#tower{sid=307, time=200, level=4, exp=30000, llpt=0, items=[], total_exp=102000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=20, box_count=1, box_mon_rate=[[30092,60],[30093,35],[30094,5]], mon_place=[{37,54},{29,39},{28,31},{17,42},{21,45}]};
get(308) -> 
	#tower{sid=308, time=200, level=8, exp=42000, llpt=0, items=[], total_exp=252000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=20, box_count=1, box_mon_rate=[[30092,60],[30093,35],[30094,5]], mon_place=[{36,48},{43,37},{31,37},{21,40},{30,24}]};
get(309) -> 
	#tower{sid=309, time=200, level=9, exp=45000, llpt=0, items=[], total_exp=297000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=20, box_count=1, box_mon_rate=[[30092,60],[30093,35],[30094,5]], mon_place=[{40,50},{43,39},{33,31},{16,33},{32,39}]};
get(310) -> 
	#tower{sid=310, time=1800, level=5, exp=0, llpt=0, items=[], total_exp=135000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(311) -> 
	#tower{sid=311, time=1800, level=10, exp=0, llpt=0, items=[], total_exp=345000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(312) -> 
	#tower{sid=312, time=200, level=11, exp=52000, llpt=0, items=[], total_exp=397000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[[30095,60],[30096,35],[30097,5]], mon_place=[{33,60},{19,41},{32,29},{42,45},{30,44}]};
get(313) -> 
	#tower{sid=313, time=200, level=12, exp=56000, llpt=0, items=[], total_exp=453000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30095,60],[30096,35],[30097,5]], mon_place=[{33,60},{19,41},{32,29},{42,45},{30,44}]};
get(314) -> 
	#tower{sid=314, time=200, level=13, exp=60000, llpt=0, items=[], total_exp=513000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30095,60],[30096,35],[30097,5]], mon_place=[{22,55},{28,33},{15,25}]};
get(315) -> 
	#tower{sid=315, time=200, level=14, exp=64000, llpt=0, items=[], total_exp=577000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30095,60],[30096,35],[30097,5]], mon_place=[{22,55},{28,33},{15,25},{9,51}]};
get(316) -> 
	#tower{sid=316, time=260, level=15, exp=68000, llpt=0, items=[], total_exp=645000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30095,60],[30096,35],[30097,5]], mon_place=[{28,59},{37,51},{21,40},{29,27}]};
get(317) -> 
	#tower{sid=317, time=1800, level=15, exp=0, llpt=0, items=[], total_exp=645000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(318) -> 
	#tower{sid=318, time=200, level=16, exp=72000, llpt=0, items=[], total_exp=717000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30095,60],[30096,35],[30097,5]], mon_place=[{24,44},{32,36},{39,28},{27,27}]};
get(319) -> 
	#tower{sid=319, time=200, level=17, exp=76000, llpt=0, items=[], total_exp=793000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30095,60],[30096,35],[30097,5]], mon_place=[{24,44},{32,36},{39,28},{27,27}]};
get(320) -> 
	#tower{sid=320, time=200, level=18, exp=80000, llpt=0, items=[], total_exp=873000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30095,60],[30096,35],[30097,5]], mon_place=[{26,51},{34,40},{27,28},{11,44},{15,44}]};
get(321) -> 
	#tower{sid=321, time=200, level=19, exp=84000, llpt=0, items=[], total_exp=957000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30095,60],[30096,35],[30097,5]], mon_place=[{26,51},{34,40},{27,28},{11,44},{15,44}]};
get(322) -> 
	#tower{sid=322, time=260, level=20, exp=88000, llpt=0, items=[], total_exp=1045000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30095,60],[30096,35],[30097,5]], mon_place=[{31,52},{18,37},{29,37},{44,39},{31,38}]};
get(323) -> 
	#tower{sid=323, time=1800, level=20, exp=0, llpt=0, items=[], total_exp=1045000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(325) -> 
	#tower{sid=325, time=180, level=21, exp=93000, llpt=0, items=[], total_exp=1138000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30098,60],[30099,35],[30100,5]], mon_place=[{21,59},{21,46},{9,43},{24,35},{33,51}]};
get(326) -> 
	#tower{sid=326, time=240, level=22, exp=98000, llpt=0, items=[], total_exp=1236000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30098,60],[30099,35],[30100,5]], mon_place=[{23,45},{39,30},{13,30},{22,19}]};
get(327) -> 
	#tower{sid=327, time=180, level=23, exp=103000, llpt=0, items=[], total_exp=1339000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30098,60],[30099,35],[30100,5]], mon_place=[{21,55},{8,43},{23,31},{33,45},{20,43}]};
get(328) -> 
	#tower{sid=328, time=240, level=24, exp=108000, llpt=0, items=[], total_exp=1447000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30098,60],[30099,35],[30100,5]], mon_place=[{26,45},{35,39},{50,51},{38,64}]};
get(329) -> 
	#tower{sid=329, time=1800, level=24, exp=0, llpt=0, items=[], total_exp=1447000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(330) -> 
	#tower{sid=330, time=180, level=25, exp=113000, llpt=0, items=[], total_exp=1560000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30098,60],[30099,35],[30100,5]], mon_place=[{23,45},{10,35},{19,33},{20,24},{33,38}]};
get(331) -> 
	#tower{sid=331, time=240, level=26, exp=118000, llpt=0, items=[], total_exp=1678000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30098,60],[30099,35],[30100,5]], mon_place=[{23,45},{39,30},{13,30},{22,19}]};
get(333) -> 
	#tower{sid=333, time=180, level=27, exp=123000, llpt=0, items=[], total_exp=1801000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30098,60],[30099,35],[30100,5]], mon_place=[{21,54},{15,46},{27,33},{34,40},{22,41}]};
get(334) -> 
	#tower{sid=334, time=240, level=28, exp=128000, llpt=0, items=[], total_exp=1929000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30098,60],[30099,35],[30100,5]], mon_place=[{36,41},{7,44},{27,24},{13,10}]};
get(335) -> 
	#tower{sid=335, time=1800, level=28, exp=0, llpt=0, items=[], total_exp=1929000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(336) -> 
	#tower{sid=336, time=180, level=29, exp=133000, llpt=0, items=[], total_exp=2062000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30098,60],[30099,35],[30100,5]], mon_place=[{21,59},{21,46},{9,43},{24,35},{33,51}]};
get(337) -> 
	#tower{sid=337, time=240, level=30, exp=138000, llpt=0, items=[], total_exp=2200000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=50, box_count=1, box_mon_rate=[[30098,60],[30099,35],[30100,5]], mon_place=[{28,26},{34,40},{21,51},{9,44},{12,28}]};
get(340) -> 
	#tower{sid=340, time=120, level=1, exp=10500, llpt=0, items=[], total_exp=10500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(341) -> 
	#tower{sid=341, time=120, level=2, exp=12000, llpt=0, items=[], total_exp=22500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(342) -> 
	#tower{sid=342, time=120, level=3, exp=13500, llpt=0, items=[], total_exp=36000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(343) -> 
	#tower{sid=343, time=120, level=4, exp=15000, llpt=0, items=[], total_exp=51000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(344) -> 
	#tower{sid=344, time=120, level=5, exp=16500, llpt=0, items=[], total_exp=67500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(345) -> 
	#tower{sid=345, time=1800, level=5, exp=0, llpt=0, items=[], total_exp=67500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(346) -> 
	#tower{sid=346, time=120, level=6, exp=18000, llpt=0, items=[], total_exp=85500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(347) -> 
	#tower{sid=347, time=120, level=7, exp=19500, llpt=0, items=[], total_exp=105000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(348) -> 
	#tower{sid=348, time=120, level=8, exp=21000, llpt=0, items=[], total_exp=126000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(349) -> 
	#tower{sid=349, time=120, level=9, exp=22500, llpt=0, items=[], total_exp=148500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(350) -> 
	#tower{sid=350, time=120, level=10, exp=24000, llpt=0, items=[], total_exp=172500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(351) -> 
	#tower{sid=351, time=1800, level=10, exp=0, llpt=0, items=[], total_exp=172500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(352) -> 
	#tower{sid=352, time=120, level=11, exp=26000, llpt=0, items=[], total_exp=198500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(353) -> 
	#tower{sid=353, time=120, level=12, exp=28000, llpt=0, items=[], total_exp=226500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(354) -> 
	#tower{sid=354, time=120, level=13, exp=30000, llpt=0, items=[], total_exp=256500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(355) -> 
	#tower{sid=355, time=120, level=14, exp=32000, llpt=0, items=[], total_exp=288500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(356) -> 
	#tower{sid=356, time=120, level=15, exp=34000, llpt=0, items=[], total_exp=322500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(357) -> 
	#tower{sid=357, time=1800, level=15, exp=0, llpt=0, items=[], total_exp=322500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(358) -> 
	#tower{sid=358, time=120, level=16, exp=36000, llpt=0, items=[], total_exp=358500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(359) -> 
	#tower{sid=359, time=120, level=17, exp=38000, llpt=0, items=[], total_exp=396500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(360) -> 
	#tower{sid=360, time=120, level=18, exp=40000, llpt=0, items=[], total_exp=436500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(361) -> 
	#tower{sid=361, time=120, level=19, exp=42000, llpt=0, items=[], total_exp=478500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(362) -> 
	#tower{sid=362, time=120, level=20, exp=44000, llpt=0, items=[], total_exp=522500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(363) -> 
	#tower{sid=363, time=1800, level=20, exp=0, llpt=0, items=[], total_exp=522500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(364) -> 
	#tower{sid=364, time=100, level=21, exp=46500, llpt=0, items=[], total_exp=569000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(365) -> 
	#tower{sid=365, time=100, level=22, exp=49000, llpt=0, items=[], total_exp=618000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(366) -> 
	#tower{sid=366, time=100, level=23, exp=51500, llpt=0, items=[], total_exp=669500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(367) -> 
	#tower{sid=367, time=100, level=24, exp=54000, llpt=0, items=[], total_exp=723500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(368) -> 
	#tower{sid=368, time=1800, level=24, exp=0, llpt=0, items=[], total_exp=618000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(369) -> 
	#tower{sid=369, time=100, level=25, exp=56500, llpt=0, items=[], total_exp=780000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(370) -> 
	#tower{sid=370, time=100, level=26, exp=59000, llpt=0, items=[], total_exp=839000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(371) -> 
	#tower{sid=371, time=100, level=27, exp=61500, llpt=0, items=[], total_exp=900500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(372) -> 
	#tower{sid=372, time=100, level=28, exp=64000, llpt=0, items=[], total_exp=964500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(373) -> 
	#tower{sid=373, time=1800, level=28, exp=0, llpt=0, items=[], total_exp=723500, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(374) -> 
	#tower{sid=374, time=100, level=29, exp=66500, llpt=0, items=[], total_exp=1031000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(375) -> 
	#tower{sid=375, time=100, level=30, exp=69000, llpt=0, items=[], total_exp=1100000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=1, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(900) -> 
	#tower{sid=900, time=600, level=1, exp=21000, llpt=0, items=[], total_exp=21000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(901) -> 
	#tower{sid=901, time=600, level=2, exp=24000, llpt=0, items=[], total_exp=45000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(902) -> 
	#tower{sid=902, time=600, level=3, exp=27000, llpt=0, items=[], total_exp=72000, total_llpt=0, total_items=[], master_exp=0, master_llpt=0, be_master=0, honour=0, total_honour=0, king_honour=0, total_king_honour=0, box_rate=0, box_count=0, box_mon_rate=[], mon_place=[]};
get(_Sid) ->
	#tower{}.

