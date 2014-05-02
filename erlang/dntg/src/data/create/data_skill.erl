%%%---------------------------------------
%%% @Module  : data_skill
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:25:38
%%% @Description:  技能
%%%---------------------------------------
-module(data_skill).
-export([get/2, get_ids/1, get_max_lv/1]).
-include("skill.hrl").

get_ids(0) ->
	[400001,400002,400003,400004,400005,400006,400007,400008,400009,400101,900001,900002];
get_ids(1) ->
	[100101,100102,100103,100104,100105,100106,100201,100202,100203,100204,100205,100206,101999];
get_ids(2) ->
	[200101,200102,200103,200104,200105,200106,200199,200201,200202,200203,200204,200205,200206];
get_ids(3) ->
	[300101,300102,300103,300104,300105,300106,300201,300202,300203,300204,300205,300206,300298,300299].

get(100101, Lv) ->
	#player_skill{ 
		skill_id=100101, 
		name = <<"鸣金淬火">>,
		career = 1,
		type = 1,
		obj = 2,
		mod = 2,
		cd = 800,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 3,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,2},{coin,400}],
					use_condition = [],
					combat_power = 0,
					area = 1,
					distance = 0,
					att_num = 2,
					data = [{att, [1000,1,2,-0.35,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,17},{coin,600}],
					use_condition = [],
					combat_power = 0,
					area = 1,
					distance = 0,
					att_num = 2,
					data = [{att, [1000,1,4,-0.35,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,28},{coin,1400}],
					use_condition = [],
					combat_power = 0,
					area = 1,
					distance = 0,
					att_num = 2,
					data = [{att, [1000,1,6,-0.35,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,2900}],
					use_condition = [],
					combat_power = 0,
					area = 2,
					distance = 0,
					att_num = 3,
					data = [{att, [1000,1,8,-0.35,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,5400}],
					use_condition = [],
					combat_power = 0,
					area = 2,
					distance = 0,
					att_num = 3,
					data = [{att, [1000,1,10,-0.35,0,0,[]]}]};
			true -> [] 
		end
	};
get(100102, Lv) ->
	#player_skill{ 
		skill_id=100102, 
		name = <<"烈火燎原">>,
		career = 1,
		type = 1,
		obj = 1,
		mod = 2,
		cd = 10800,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [{800,101999},{800,101999},{800,101999},{800,101999}],
		base_effect_id = 0,
		use_time = 4000,
		is_calc_hurt = 1,
		status = 1,
		aoe_mod = 1,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,8},{coin,500}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,12,0.15,4800,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,17},{coin,700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,24,0.15,4800,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,25},{coin,1020}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,36,0.15,4800,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,1460}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,48,0.15,4800,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,41},{coin,2020}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,60,0.15,4800,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,44},{coin,2700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,72,0.15,4800,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,3500}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,84,0.15,4800,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,4420}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,96,0.15,4800,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,5460}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,108,0.15,4800,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,6620}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,120,0.15,4800,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,7900}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,132,0.15,4800,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,9300}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,144,0.15,4800,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,10820}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,156,0.15,4800,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,12420}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,168,0.15,4800,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,14100}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,180,0.15,4800,0,[]]}]};
			Lv =:= 16 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,15860}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,192,0.15,4800,0,[]]}]};
			Lv =:= 17 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,17700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,204,0.15,4800,0,[]]}]};
			Lv =:= 18 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,19620}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,216,0.15,4800,0,[]]}]};
			Lv =:= 19 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,21620}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,228,0.15,4800,0,[]]}]};
			Lv =:= 20 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,23700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,240,0.15,4800,0,[]]}]};
			Lv =:= 21 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,25860}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,252,0.15,4800,0,[]]}]};
			Lv =:= 22 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,28100}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,264,0.15,4800,0,[]]}]};
			Lv =:= 23 -> 
				#skill_lv_data{
					learn_condition = [{lv,75},{coin,30420}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,276,0.15,4800,0,[]]}]};
			Lv =:= 24 -> 
				#skill_lv_data{
					learn_condition = [{lv,76},{coin,32820}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,288,0.15,4800,0,[]]}]};
			Lv =:= 25 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,35300}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,300,0.15,4800,0,[]]}]};
			true -> [] 
		end
	};
get(100103, Lv) ->
	#player_skill{ 
		skill_id=100103, 
		name = <<"玄火震世">>,
		career = 1,
		type = 1,
		obj = 1,
		mod = 2,
		cd = 2800,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 1,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,20},{coin,600}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,15,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,25},{coin,1200}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,30,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,1950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,45,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,2850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,60,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,3900}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,75,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,5100}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,90,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,6450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,105,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,7950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,120,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,9600}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,135,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,11400}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,150,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,13350}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,165,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,15450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,180,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,17650}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,195,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,19950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,210,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,22350}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,225,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 16 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,24850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,240,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 17 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,27450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,255,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 18 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,30150}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,270,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 19 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,32950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,285,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 20 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,35850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,300,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 21 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,38850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,315,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 22 -> 
				#skill_lv_data{
					learn_condition = [{lv,75},{coin,41950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,330,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 23 -> 
				#skill_lv_data{
					learn_condition = [{lv,76},{coin,45150}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,345,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 24 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,48450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,360,0.1,0,0,[]]},{hate, 1000}]};
			Lv =:= 25 -> 
				#skill_lv_data{
					learn_condition = [{lv,78},{coin,51850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,375,0.1,0,0,[]]},{hate, 1000}]};
			true -> [] 
		end
	};
get(100104, Lv) ->
	#player_skill{ 
		skill_id=100104, 
		name = <<"千机神引">>,
		career = 1,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 7500,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,31},{coin,1000}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,18,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,35},{coin,3100}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,36,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,5500}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,54,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,8200}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,72,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,11200}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,90,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,14500}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,108,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,18100}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,126,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,22000}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,144,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,26200}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,162,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,30700}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,180,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,35500}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,198,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,40600}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,216,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,46000}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,234,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,51700}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,252,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,57700}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,270,0.24,0,0,[]]},{hold, [1000,2,0,[]]}]};
			true -> [] 
		end
	};
get(100105, Lv) ->
	#player_skill{ 
		skill_id=100105, 
		name = <<"长生诀">>,
		career = 1,
		type = 2,
		obj = 1,
		mod = 1,
		cd = 0,
		attime = 0,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 0,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,1200}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,217,0,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,38},{coin,3960}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,440,0,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,6960}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,663,0,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,10200}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,886,0,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,13680}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,1109,0,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,17400}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,1326,0,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,21360}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,1549,0,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,25560}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,1772,0,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,30000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,1995,0,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,34680}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,2218,0,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,39600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,2441,0,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,44760}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,2658,0,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,50160}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,2881,0,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,55800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,3104,0,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,61680}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{blood, [1000,1,3327,0,0,0,[]]}]};
			true -> [] 
		end
	};
get(100106, Lv) ->
	#player_skill{ 
		skill_id=100106, 
		name = <<"鸿蒙初辟">>,
		career = 1,
		type = 3,
		obj = 1,
		mod = 1,
		cd = 8000,
		attime = 0,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,0}],
					use_condition = [{mp,50}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,1,0,0.35,3000,0,[]]},{hurt_del, [1000,1,0,0.15,3000,0,[]]},{add_blood, [1000,1,0,0.15,[1,0],0,[]]}]};
			true -> [] 
		end
	};
get(100201, Lv) ->
	#player_skill{ 
		skill_id=100201, 
		name = <<"神魔斩·截">>,
		career = 1,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 800,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,20000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,20,-0.1,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,45},{coin,28000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,40,-0.1,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,37000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,60,-0.1,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,47000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,80,-0.1,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,58000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,100,-0.1,0,0,[]]}]};
			true -> [] 
		end
	};
get(100202, Lv) ->
	#player_skill{ 
		skill_id=100202, 
		name = <<"神魔斩·伤">>,
		career = 1,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 8300,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,30000}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.1,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,10,0.18,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,42},{coin,36000}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.11,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,20,0.18,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,44},{coin,42300}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.12,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,30,0.18,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,48900}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.13,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,40,0.18,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,48},{coin,55800}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.14,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,50,0.18,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,63000}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.15,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,60,0.18,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,70500}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.16,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,70,0.18,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,78300}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.17,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,80,0.18,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,86400}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.18,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,90,0.18,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,94800}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.19,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,100,0.18,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,103500}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.2,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,110,0.18,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,112650}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.21,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,120,0.18,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,122250}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.22,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,130,0.18,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,132300}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.23,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,140,0.18,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,142800}],
					use_condition = [{mp,20}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{speed, [1000,2,0,-0.24,2000,0,[]]},{hp, [1000,1,0,-0.1,0,0,[]]},{hp, [1000,2,150,0.18,0,0,[]]}]};
			true -> [] 
		end
	};
get(100203, Lv) ->
	#player_skill{ 
		skill_id=100203, 
		name = <<"神魔斩·凝">>,
		career = 1,
		type = 3,
		obj = 1,
		mod = 1,
		cd = 9000,
		attime = 0,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 0,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,40000}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.20,3000,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,45},{coin,48600}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.21,3000,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,57600}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.22,3000,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,67000}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.23,3000,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,51},{coin,76800}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.24,3000,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,53},{coin,87000}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.25,3000,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,97600}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.26,3000,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,57},{coin,108600}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.27,3000,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,59},{coin,120000}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.28,3000,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,131800}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.29,3000,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,144000}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.30,3000,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,156800}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.31,3000,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,170200}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.32,3000,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,184200}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.33,3000,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,76},{coin,198800}],
					use_condition = [{mp,25}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{ftsh, [1000,1,0,0.34,3000,0,[]]}]};
			true -> [] 
		end
	};
get(100204, Lv) ->
	#player_skill{ 
		skill_id=100204, 
		name = <<"神魔斩·狂">>,
		career = 1,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 4500,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,50000}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,42,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,61750}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,84,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,51},{coin,74000}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,126,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,53},{coin,86750}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,168,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,100000}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,210,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,57},{coin,113750}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,252,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,59},{coin,128000}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,294,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,142750}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,336,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,63},{coin,158000}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,378,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,65},{coin,173750}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,420,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,190000}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,462,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,69},{coin,206750}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,504,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,224000}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,546,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,241750}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,588,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,260250}],
					use_condition = [{mp,30}],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,630,0.22,0,0,[]]},{speed, [1000,2,0,-0.99,1500,0,[]]}]};
			true -> [] 
		end
	};
get(100205, Lv) ->
	#player_skill{ 
		skill_id=100205, 
		name = <<"神体术">>,
		career = 1,
		type = 2,
		obj = 2,
		mod = 1,
		cd = 0,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 0,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,60000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,25,0,0,0,[]]},{fire_def, [1000,1,25,0,0,0,[]]},{ice_def, [1000,1,25,0,0,0,[]]},{drug_def, [1000,1,25,0,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,75000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,50,0,0,0,[]]},{fire_def, [1000,1,50,0,0,0,[]]},{ice_def, [1000,1,50,0,0,0,[]]},{drug_def, [1000,1,50,0,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,90600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,75,0,0,0,[]]},{fire_def, [1000,1,75,0,0,0,[]]},{ice_def, [1000,1,75,0,0,0,[]]},{drug_def, [1000,1,75,0,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,106800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,100,0,0,0,[]]},{fire_def, [1000,1,100,0,0,0,[]]},{ice_def, [1000,1,100,0,0,0,[]]},{drug_def, [1000,1,100,0,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,123600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,125,0,0,0,[]]},{fire_def, [1000,1,125,0,0,0,[]]},{ice_def, [1000,1,125,0,0,0,[]]},{drug_def, [1000,1,125,0,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,141000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,150,0,0,0,[]]},{fire_def, [1000,1,150,0,0,0,[]]},{ice_def, [1000,1,150,0,0,0,[]]},{drug_def, [1000,1,150,0,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,159000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,175,0,0,0,[]]},{fire_def, [1000,1,175,0,0,0,[]]},{ice_def, [1000,1,175,0,0,0,[]]},{drug_def, [1000,1,175,0,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,177600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,200,0,0,0,[]]},{fire_def, [1000,1,200,0,0,0,[]]},{ice_def, [1000,1,200,0,0,0,[]]},{drug_def, [1000,1,200,0,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,196800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,225,0,0,0,[]]},{fire_def, [1000,1,225,0,0,0,[]]},{ice_def, [1000,1,225,0,0,0,[]]},{drug_def, [1000,1,225,0,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,216600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,250,0,0,0,[]]},{fire_def, [1000,1,250,0,0,0,[]]},{ice_def, [1000,1,250,0,0,0,[]]},{drug_def, [1000,1,250,0,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,237000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,275,0,0,0,[]]},{fire_def, [1000,1,275,0,0,0,[]]},{ice_def, [1000,1,275,0,0,0,[]]},{drug_def, [1000,1,275,0,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,258000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,300,0,0,0,[]]},{fire_def, [1000,1,300,0,0,0,[]]},{ice_def, [1000,1,300,0,0,0,[]]},{drug_def, [1000,1,300,0,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,279600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,325,0,0,0,[]]},{fire_def, [1000,1,325,0,0,0,[]]},{ice_def, [1000,1,325,0,0,0,[]]},{drug_def, [1000,1,325,0,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,301800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,350,0,0,0,[]]},{fire_def, [1000,1,350,0,0,0,[]]},{ice_def, [1000,1,350,0,0,0,[]]},{drug_def, [1000,1,350,0,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,80},{coin,324900}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{def, [1000,1,375,0,0,0,[]]},{fire_def, [1000,1,375,0,0,0,[]]},{ice_def, [1000,1,375,0,0,0,[]]},{drug_def, [1000,1,375,0,0,0,[]]}]};
			true -> [] 
		end
	};
get(100206, Lv) ->
	#player_skill{ 
		skill_id=100206, 
		name = <<"碎梦摇魂">>,
		career = 1,
		type = 1,
		obj = 1,
		mod = 2,
		cd = 8000,
		attime = 0,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40}],
					use_condition = [],
					combat_power = 0,
					area = 2,
					distance = 0,
					att_num = 0,
					data = [{att, [1000,2,0,-0.15,3000,0,[]]}]};
			true -> [] 
		end
	};
get(101999, Lv) ->
	#player_skill{ 
		skill_id=101999, 
		name = <<"烈火燎原关联">>,
		career = 1,
		type = 4,
		obj = 1,
		mod = 2,
		cd = 0,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 1,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,5},{coin,500}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,8},{coin,700}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,11},{coin,1020}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,14},{coin,1460}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,17},{coin,2020}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,20},{coin,2700}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,23},{coin,3500}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,26},{coin,4420}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,29},{coin,5460}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,32},{coin,6620}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,35},{coin,7900}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,38},{coin,9300}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,10820}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,42},{coin,12420}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,44},{coin,14100}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 16 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,15860}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 17 -> 
				#skill_lv_data{
					learn_condition = [{lv,48},{coin,17700}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 18 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,19620}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 19 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,21620}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 20 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,23700}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 21 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,25860}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 22 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,28100}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 23 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,30420}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 24 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,32820}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			Lv =:= 25 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,35300}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,0,0.15,4800,0,[]]}]};
			true -> [] 
		end
	};
get(200101, Lv) ->
	#player_skill{ 
		skill_id=200101, 
		name = <<"坎水真诀">>,
		career = 2,
		type = 1,
		obj = 2,
		mod = 2,
		cd = 800,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,2},{coin,400}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 2,
					data = [{att, [1000,1,2,-0.35,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,17},{coin,600}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 2,
					data = [{att, [1000,1,4,-0.35,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,28},{coin,1400}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 2,
					data = [{att, [1000,1,6,-0.35,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,2900}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 3,
					data = [{att, [1000,1,8,-0.35,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,5400}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 3,
					data = [{att, [1000,1,10,-0.35,0,0,[]]}]};
			true -> [] 
		end
	};
get(200102, Lv) ->
	#player_skill{ 
		skill_id=200102, 
		name = <<"六合寒水">>,
		career = 2,
		type = 1,
		obj = 2,
		mod = 2,
		cd = 2200,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 1,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,8},{coin,500}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,13,0.17,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,17},{coin,700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,26,0.17,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,25},{coin,1020}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,39,0.17,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,1460}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,52,0.17,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,41},{coin,2020}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,65,0.17,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,44},{coin,2700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,78,0.17,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,3500}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,91,0.17,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,4420}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,104,0.17,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,5460}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,117,0.17,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,6620}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,130,0.17,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,7900}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,143,0.17,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,9300}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,156,0.17,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,10820}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,169,0.17,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,12420}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,182,0.17,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,14100}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,195,0.17,0,0,[]]}]};
			Lv =:= 16 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,15860}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,208,0.17,0,0,[]]}]};
			Lv =:= 17 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,17700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,221,0.17,0,0,[]]}]};
			Lv =:= 18 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,19620}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,234,0.17,0,0,[]]}]};
			Lv =:= 19 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,21620}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,247,0.17,0,0,[]]}]};
			Lv =:= 20 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,23700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,260,0.17,0,0,[]]}]};
			Lv =:= 21 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,25860}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,273,0.17,0,0,[]]}]};
			Lv =:= 22 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,28100}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,286,0.17,0,0,[]]}]};
			Lv =:= 23 -> 
				#skill_lv_data{
					learn_condition = [{lv,75},{coin,30420}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,299,0.17,0,0,[]]}]};
			Lv =:= 24 -> 
				#skill_lv_data{
					learn_condition = [{lv,76},{coin,32820}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,312,0.17,0,0,[]]}]};
			Lv =:= 25 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,35300}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 4,
					att_num = 5,
					data = [{att, [1000,1,325,0.17,0,0,[]]}]};
			true -> [] 
		end
	};
get(200103, Lv) ->
	#player_skill{ 
		skill_id=200103, 
		name = <<"夜阑听雨">>,
		career = 2,
		type = 1,
		obj = 1,
		mod = 2,
		cd = 7500,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [{800,200199},{800,200199},{800,200199}],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 2,
		aoe_mod = 1,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,20},{coin,600}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,5,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-5,-0.15,[1,0],0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,25},{coin,1200}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,10,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-10,-0.15,[1,0],0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,1950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,15,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-15,-0.15,[1,0],0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,2850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,20,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-20,-0.15,[1,0],0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,3900}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,25,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-25,-0.15,[1,0],0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,5100}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,30,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-30,-0.15,[1,0],0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,6450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,35,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-35,-0.15,[1,0],0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,7950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,40,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-40,-0.15,[1,0],0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,9600}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,45,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-45,-0.15,[1,0],0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,11400}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,50,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-50,-0.15,[1,0],0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,13350}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,55,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-55,-0.15,[1,0],0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,15450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,60,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-60,-0.15,[1,0],0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,17650}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 3,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,65,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-65,-0.15,[1,0],0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,19950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,70,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-70,-0.15,[1,0],0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,22350}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,75,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-75,-0.15,[1,0],0,[]]}]};
			Lv =:= 16 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,24850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,80,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-80,-0.15,[1,0],0,[]]}]};
			Lv =:= 17 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,27450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,85,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-85,-0.15,[1,0],0,[]]}]};
			Lv =:= 18 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,30150}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,90,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-90,-0.15,[1,0],0,[]]}]};
			Lv =:= 19 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,32950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,95,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-95,-0.15,[1,0],0,[]]}]};
			Lv =:= 20 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,35850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,100,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-100,-0.15,[1,0],0,[]]}]};
			Lv =:= 21 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,38850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,105,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-105,-0.15,[1,0],0,[]]}]};
			Lv =:= 22 -> 
				#skill_lv_data{
					learn_condition = [{lv,75},{coin,41950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,110,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-110,-0.15,[1,0],0,[]]}]};
			Lv =:= 23 -> 
				#skill_lv_data{
					learn_condition = [{lv,76},{coin,45150}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,115,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-115,-0.15,[1,0],0,[]]}]};
			Lv =:= 24 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,48450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,120,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-120,-0.15,[1,0],0,[]]}]};
			Lv =:= 25 -> 
				#skill_lv_data{
					learn_condition = [{lv,78},{coin,51850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,1,125,0.15,[1,0],0,[]]},{add_blood_ac_att, [1000,2,-125,-0.15,[1,0],0,[]]}]};
			true -> [] 
		end
	};
get(200104, Lv) ->
	#player_skill{ 
		skill_id=200104, 
		name = <<"浪兮滔天">>,
		career = 2,
		type = 1,
		obj = 1,
		mod = 2,
		cd = 8500,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 1,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,31},{coin,1000}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,25,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,35},{coin,3100}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,50,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,5500}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,75,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,8200}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,100,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,11200}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,125,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,14500}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,150,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,18100}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,175,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,22000}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,200,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,26200}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,225,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,30700}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,250,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,35500}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,275,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,40600}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,300,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,46000}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,325,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,51700}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,350,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,57700}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,375,0.22,0,0,[]]},{back, [1000,2,4,0,[]]}]};
			true -> [] 
		end
	};
get(200105, Lv) ->
	#player_skill{ 
		skill_id=200105, 
		name = <<"观心">>,
		career = 2,
		type = 2,
		obj = 1,
		mod = 1,
		cd = 0,
		attime = 0,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 0,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,1200}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,41,0,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,38},{coin,3960}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,82,0,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,6960}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,125,0,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,10200}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,167,0,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,13680}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,209,0,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,17400}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,250,0,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,21360}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,292,0,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,25560}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,334,0,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,30000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,376,0,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,34680}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,418,0,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,39600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,460,0,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,44760}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,501,0,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,50160}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,543,0,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,55800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,585,0,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,61680}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{hit, [1000,1,627,0,0,0,[]]}]};
			true -> [] 
		end
	};
get(200106, Lv) ->
	#player_skill{ 
		skill_id=200106, 
		name = <<"水之灵">>,
		career = 2,
		type = 3,
		obj = 1,
		mod = 1,
		cd = 8000,
		attime = 0,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,0}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{att, [1000,1,0,0.15,3000,0,[]]}]};
			true -> [] 
		end
	};
get(200199, Lv) ->
	#player_skill{ 
		skill_id=200199, 
		name = <<"夜阑听雨关联">>,
		career = 2,
		type = 4,
		obj = 1,
		mod = 2,
		cd = 0,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 1,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,12},{coin,600}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-7,-0.15,[1,0],0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,17},{coin,1200}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-14,-0.15,[1,0],0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,22},{coin,2050}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-21,-0.15,[1,0],0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,21},{coin,3150}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-28,-0.15,[1,0],0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,26},{coin,4200}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-35,-0.15,[1,0],0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,29},{coin,5500}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-42,-0.15,[1,0],0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,32},{coin,6950}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-49,-0.15,[1,0],0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,35},{coin,8550}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-56,-0.15,[1,0],0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,38},{coin,10300}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-63,-0.15,[1,0],0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,41},{coin,12200}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-70,-0.15,[1,0],0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,44},{coin,14250}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-77,-0.15,[1,0],0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,16450}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-84,-0.15,[1,0],0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,18800}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-91,-0.15,[1,0],0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,53},{coin,21300}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-98,-0.15,[1,0],0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,23950}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-105,-0.15,[1,0],0,[]]}]};
			Lv =:= 16 -> 
				#skill_lv_data{
					learn_condition = [{lv,57},{coin,26700}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-112,-0.15,[1,0],0,[]]}]};
			Lv =:= 17 -> 
				#skill_lv_data{
					learn_condition = [{lv,59},{coin,29550}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-119,-0.15,[1,0],0,[]]}]};
			Lv =:= 18 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,32500}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-126,-0.15,[1,0],0,[]]}]};
			Lv =:= 19 -> 
				#skill_lv_data{
					learn_condition = [{lv,63},{coin,35550}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-133,-0.15,[1,0],0,[]]}]};
			Lv =:= 20 -> 
				#skill_lv_data{
					learn_condition = [{lv,65},{coin,38700}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-140,-0.15,[1,0],0,[]]}]};
			Lv =:= 21 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,41950}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-147,-0.15,[1,0],0,[]]}]};
			Lv =:= 22 -> 
				#skill_lv_data{
					learn_condition = [{lv,69},{coin,45300}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-154,-0.15,[1,0],0,[]]}]};
			Lv =:= 23 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,48750}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-161,-0.15,[1,0],0,[]]}]};
			Lv =:= 24 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,52300}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-168,-0.15,[1,0],0,[]]}]};
			Lv =:= 25 -> 
				#skill_lv_data{
					learn_condition = [{lv,75},{coin,55950}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{add_blood_ac_att, [1000,2,-175,-0.15,[1,0],0,[]]}]};
			true -> [] 
		end
	};
get(200201, Lv) ->
	#player_skill{ 
		skill_id=200201, 
		name = <<"天元·驭雷术">>,
		career = 2,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 800,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,20000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,20,-0.1,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,45},{coin,28000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,40,-0.1,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,37000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,60,-0.1,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,47000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,80,-0.1,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,58000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,100,-0.1,0,0,[]]}]};
			true -> [] 
		end
	};
get(200202, Lv) ->
	#player_skill{ 
		skill_id=200202, 
		name = <<"天元·轰天雷">>,
		career = 2,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 4500,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 2,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,30000}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,63,0.45,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,42},{coin,36000}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,126,0.45,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,44},{coin,42300}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,189,0.45,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,48900}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,252,0.45,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,48},{coin,55800}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,315,0.45,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,63000}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,378,0.45,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,70500}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,441,0.45,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,78300}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,504,0.45,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,86400}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,567,0.45,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,94800}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,630,0.45,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,103500}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,693,0.45,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,112650}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,756,0.45,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,122250}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,819,0.45,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,132300}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,882,0.45,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,142800}],
					use_condition = [],
					combat_power = 0,
					area = 4,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,945,0.45,0,0,[]]}]};
			true -> [] 
		end
	};
get(200203, Lv) ->
	#player_skill{ 
		skill_id=200203, 
		name = <<"天元·雷罡朔">>,
		career = 2,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 6400,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,40000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,42,0.28,0,0,[]]},{speed, [1000,2,0,-0.13,3000,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,45},{coin,48600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,84,0.28,0,0,[]]},{speed, [1000,2,0,-0.15,3000,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,57600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,126,0.28,0,0,[]]},{speed, [1000,2,0,-0.17,3000,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,67000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,168,0.28,0,0,[]]},{speed, [1000,2,0,-0.19,3000,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,51},{coin,76800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,210,0.28,0,0,[]]},{speed, [1000,2,0,-0.21,3000,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,53},{coin,87000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,252,0.28,0,0,[]]},{speed, [1000,2,0,-0.23,3000,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,97600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,294,0.28,0,0,[]]},{speed, [1000,2,0,-0.25,3000,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,57},{coin,108600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,336,0.28,0,0,[]]},{speed, [1000,2,0,-0.27,3000,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,59},{coin,120000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,378,0.28,0,0,[]]},{speed, [1000,2,0,-0.29,3000,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,131800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,420,0.28,0,0,[]]},{speed, [1000,2,0,-0.3,3000,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,144000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,462,0.28,0,0,[]]},{speed, [1000,2,0,-0.31,3000,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,156800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,504,0.28,0,0,[]]},{speed, [1000,2,0,-0.32,3000,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,170200}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,546,0.28,0,0,[]]},{speed, [1000,2,0,-0.33,3000,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,184200}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,588,0.28,0,0,[]]},{speed, [1000,2,0,-0.34,3000,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,76},{coin,198800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,630,0.28,0,0,[]]},{speed, [1000,2,0,-0.35,3000,0,[]]}]};
			true -> [] 
		end
	};
get(200204, Lv) ->
	#player_skill{ 
		skill_id=200204, 
		name = <<"天元·雷光遁">>,
		career = 2,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 8400,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,50000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-17,-0.55,1,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,61750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-34,-0.55,1,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,51},{coin,74000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-51,-0.55,1,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,53},{coin,86750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-68,-0.55,[3,800],0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,100000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-85,-0.55,[3,800],0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,57},{coin,113750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-102,-0.55,[3,800],0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,59},{coin,128000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-119,-0.55,[3,800],0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,142750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-136,-0.55,[3,800],0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,63},{coin,158000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-153,-0.55,[3,800],0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,65},{coin,173750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-170,-0.55,[3,800],0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,190000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-187,-0.55,[3,800],0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,69},{coin,206750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-204,-0.55,[3,800],0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,224000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-221,-0.55,[3,800],0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,241750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-238,-0.55,[3,800],0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,260250}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,17,-0.45,0,0,[]]},{att, [1000,2,0,0.2,2400,0,[]]},{cm, [1000,2,0,0,2400,0,[]]},{change_hp_ac_lim, [1000,2,-255,-0.55,[3,800],0,[]]}]};
			true -> [] 
		end
	};
get(200205, Lv) ->
	#player_skill{ 
		skill_id=200205, 
		name = <<"狂法">>,
		career = 2,
		type = 2,
		obj = 2,
		mod = 1,
		cd = 0,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 0,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,60000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,17,0,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,75000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,35,0,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,90600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,53,0,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,106800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,71,0,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,123600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,88,0,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,141000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,106,0,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,159000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,124,0,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,177600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,142,0,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,196800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,160,0,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,216600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,177,0,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,237000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,195,0,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,258000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,213,0,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,279600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,231,0,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,301800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,248,0,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,80},{coin,324900}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,266,0,0,0,[]]}]};
			true -> [] 
		end
	};
get(200206, Lv) ->
	#player_skill{ 
		skill_id=200206, 
		name = <<"雷之灵">>,
		career = 2,
		type = 3,
		obj = 1,
		mod = 1,
		cd = 8000,
		attime = 0,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{shield, [1000,1,0,0.2,50000,0,[]]}]};
			true -> [] 
		end
	};
get(300101, Lv) ->
	#player_skill{ 
		skill_id=300101, 
		name = <<"六道轮回">>,
		career = 3,
		type = 1,
		obj = 2,
		mod = 2,
		cd = 800,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 3,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,2},{coin,400}],
					use_condition = [],
					combat_power = 0,
					area = 1,
					distance = 2,
					att_num = 2,
					data = [{att, [1000,1,2,-0.35,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,17},{coin,600}],
					use_condition = [],
					combat_power = 0,
					area = 1,
					distance = 2,
					att_num = 2,
					data = [{att, [1000,1,4,-0.35,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,28},{coin,1400}],
					use_condition = [],
					combat_power = 0,
					area = 2,
					distance = 2,
					att_num = 2,
					data = [{att, [1000,1,6,-0.35,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,2900}],
					use_condition = [],
					combat_power = 0,
					area = 2,
					distance = 2,
					att_num = 3,
					data = [{att, [1000,1,8,-0.35,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,5400}],
					use_condition = [],
					combat_power = 0,
					area = 3,
					distance = 2,
					att_num = 3,
					data = [{att, [1000,1,10,-0.35,0,0,[]]}]};
			true -> [] 
		end
	};
get(300102, Lv) ->
	#player_skill{ 
		skill_id=300102, 
		name = <<"歃血为盟">>,
		career = 3,
		type = 1,
		obj = 1,
		mod = 2,
		cd = 5000,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 1,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,8},{coin,500}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,15,0.18,0,0,[]]},{drug, [1000,2,-10,0,[3,1000],0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,17},{coin,700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,30,0.18,0,0,[]]},{drug, [1000,2,-15,0,[3,1000],0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,25},{coin,1020}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,45,0.18,0,0,[]]},{drug, [1000,2,-20,0,[3,1000],0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,1460}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,60,0.18,0,0,[]]},{drug, [1000,2,-25,0,[3,1000],0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,41},{coin,2020}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,75,0.18,0,0,[]]},{drug, [1000,2,-30,0,[3,1000],0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,44},{coin,2700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,90,0.18,0,0,[]]},{drug, [1000,2,-35,0,[3,1000],0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,3500}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,105,0.18,0,0,[]]},{drug, [1000,2,-40,0,[3,1000],0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,4420}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,120,0.18,0,0,[]]},{drug, [1000,2,-45,0,[3,1000],0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,5460}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,135,0.18,0,0,[]]},{drug, [1000,2,-50,0,[3,1000],0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,6620}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,150,0.18,0,0,[]]},{drug, [1000,2,-60,0,[3,1000],0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,7900}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,165,0.18,0,0,[]]},{drug, [1000,2,-70,0,[3,1000],0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,9300}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,180,0.18,0,0,[]]},{drug, [1000,2,-80,0,[3,1000],0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,10820}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,195,0.18,0,0,[]]},{drug, [1000,2,-90,0,[3,1000],0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,12420}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,210,0.18,0,0,[]]},{drug, [1000,2,-100,0,[3,1000],0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,14100}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,225,0.18,0,0,[]]},{drug, [1000,2,-110,0,[3,1000],0,[]]}]};
			Lv =:= 16 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,15860}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,240,0.18,0,0,[]]},{drug, [1000,2,-120,0,[3,1000],0,[]]}]};
			Lv =:= 17 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,17700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,255,0.18,0,0,[]]},{drug, [1000,2,-130,0,[3,1000],0,[]]}]};
			Lv =:= 18 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,19620}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,270,0.18,0,0,[]]},{drug, [1000,2,-140,0,[3,1000],0,[]]}]};
			Lv =:= 19 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,21620}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,295,0.18,0,0,[]]},{drug, [1000,2,-150,0,[3,1000],0,[]]}]};
			Lv =:= 20 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,23700}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,310,0.18,0,0,[]]},{drug, [1000,2,-160,0,[3,1000],0,[]]}]};
			Lv =:= 21 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,25860}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,325,0.18,0,0,[]]},{drug, [1000,2,-170,0,[3,1000],0,[]]}]};
			Lv =:= 22 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,28100}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,340,0.18,0,0,[]]},{drug, [1000,2,-180,0,[3,1000],0,[]]}]};
			Lv =:= 23 -> 
				#skill_lv_data{
					learn_condition = [{lv,75},{coin,30420}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,355,0.18,0,0,[]]},{drug, [1000,2,-190,0,[3,1000],0,[]]}]};
			Lv =:= 24 -> 
				#skill_lv_data{
					learn_condition = [{lv,76},{coin,32820}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,370,0.18,0,0,[]]},{drug, [1000,2,-200,0,[3,1000],0,[]]}]};
			Lv =:= 25 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,35300}],
					use_condition = [{mp,10}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,385,0.18,0,0,[]]},{drug, [1000,2,-210,0,[3,1000],0,[]]}]};
			true -> [] 
		end
	};
get(300103, Lv) ->
	#player_skill{ 
		skill_id=300103, 
		name = <<"血影狂澜">>,
		career = 3,
		type = 1,
		obj = 1,
		mod = 2,
		cd = 3000,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 1,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,20},{coin,600}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,16,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,25},{coin,1200}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,32,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,1950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,48,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,2850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,64,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,3900}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,80,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,5100}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,96,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,6450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,112,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,7950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,128,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,9600}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,144,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,11400}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,160,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,13350}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,176,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,15450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,192,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,17650}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,208,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,19950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,224,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,22350}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,240,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 16 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,24850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,256,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 17 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,27450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,272,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 18 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,30150}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,288,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 19 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,32950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,304,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 20 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,35850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,320,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 21 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,38850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,336,0.2,0,0,[]]},{suck_blood, [1000,1,0,0.15,0,0,[]]}]};
			Lv =:= 22 -> 
				#skill_lv_data{
					learn_condition = [{lv,75},{coin,41950}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,352,0.2,0,0,[]]}]};
			Lv =:= 23 -> 
				#skill_lv_data{
					learn_condition = [{lv,76},{coin,45150}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,368,0.2,0,0,[]]}]};
			Lv =:= 24 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,48450}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,384,0.2,0,0,[]]}]};
			Lv =:= 25 -> 
				#skill_lv_data{
					learn_condition = [{lv,78},{coin,51850}],
					use_condition = [{mp,12}],
					combat_power = 0,
					area = 3,
					distance = 0,
					att_num = 5,
					data = [{att, [1000,1,400,0.2,0,0,[]]}]};
			true -> [] 
		end
	};
get(300104, Lv) ->
	#player_skill{ 
		skill_id=300104, 
		name = <<"魅影神踪">>,
		career = 3,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 7500,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,31},{coin,1000}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,40,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,35},{coin,3100}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,80,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,5500}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,120,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,8200}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,160,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,11200}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,200,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,14500}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,240,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,18100}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,280,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,22000}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,320,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,26200}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,360,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,30700}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,400,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,35500}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,440,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,40600}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,480,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,46000}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,520,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,51700}],
					use_condition = [{mp,15}],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,560,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,57700}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,600,0.25,0,0,[]]},{yun, [1000,2,0,0,1750,0,[]]},{hold, [1000,1,300104,[]]}]};
			true -> [] 
		end
	};
get(300105, Lv) ->
	#player_skill{ 
		skill_id=300105, 
		name = <<"疾闪">>,
		career = 3,
		type = 2,
		obj = 1,
		mod = 1,
		cd = 0,
		attime = 0,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 0,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,33},{coin,1200}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,35,0,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,38},{coin,3960}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,70,0,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,6960}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,105,0,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,10200}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,140,0,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,13680}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,175,0,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,17400}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,210,0,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,21360}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,245,0,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,25560}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,280,0,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,30000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,315,0,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,34680}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,350,0,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,39600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,385,0,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,44760}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,420,0,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,50160}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,455,0,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,55800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,490,0,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,61680}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{dodge, [1000,1,525,0,0,0,[]]}]};
			true -> [] 
		end
	};
get(300106, Lv) ->
	#player_skill{ 
		skill_id=300106, 
		name = <<"寂灭杀">>,
		career = 3,
		type = 3,
		obj = 1,
		mod = 1,
		cd = 8000,
		attime = 0,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,0}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,99999999,0,3000,0,[]]}]};
			true -> [] 
		end
	};
get(300201, Lv) ->
	#player_skill{ 
		skill_id=300201, 
		name = <<"刺杀术·疾影">>,
		career = 3,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 800,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,20000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,20,-0.1,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,45},{coin,28000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,40,-0.1,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,37000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,60,-0.1,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,47000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,80,-0.1,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,58000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,100,-0.1,0,0,[]]}]};
			true -> [] 
		end
	};
get(300202, Lv) ->
	#player_skill{ 
		skill_id=300202, 
		name = <<"刺杀术·残影">>,
		career = 3,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 7200,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40},{coin,30000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,40,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,42},{coin,36000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,80,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,44},{coin,42300}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,120,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,46},{coin,48900}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,160,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,48},{coin,55800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,200,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,63000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,240,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,70500}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,280,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,78300}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,320,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,86400}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,360,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,94800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,400,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,103500}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,440,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,112650}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,480,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,122250}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,520,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,132300}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,560,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,142800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 4,
					att_num = 1,
					data = [{att, [1000,1,600,0.26,0,0,[]]},{fire_def, [1000,2,0,-0.15,5000,0,[]]},{ice_def, [1000,2,0,-0.15,5000,0,[]]},{drug_def, [1000,2,0,-0.15,5000,0,[]]}]};
			true -> [] 
		end
	};
get(300203, Lv) ->
	#player_skill{ 
		skill_id=300203, 
		name = <<"刺杀术·影遁">>,
		career = 3,
		type = 3,
		obj = 1,
		mod = 1,
		cd = 15000,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,43},{coin,40000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.13,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,45},{coin,48600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.15,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,57600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.17,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,67000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.19,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,51},{coin,76800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.21,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,53},{coin,87000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.23,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,97600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.25,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,57},{coin,108600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.27,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,59},{coin,120000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.29,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,131800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.3,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,144000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.31,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,156800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.32,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,170200}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.33,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,73},{coin,184200}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.34,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,76},{coin,198800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{speed, [1000,1,0,0.35,5000,0,[]]},{immune_effect, [1000,1,0,0,5000,0,[]]}]};
			true -> [] 
		end
	};
get(300204, Lv) ->
	#player_skill{ 
		skill_id=300204, 
		name = <<"刺杀术·狂影">>,
		career = 3,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 10400,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [{400,300298},{400,300299}],
		base_effect_id = 0,
		use_time = 1200,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,50000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,60,0.2,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,61750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,120,0.2,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,51},{coin,74000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,180,0.2,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,53},{coin,86750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,240,0.2,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,100000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,300,0.2,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,57},{coin,113750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,360,0.2,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,59},{coin,128000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,420,0.2,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,142750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,480,0.2,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,63},{coin,158000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,540,0.2,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,65},{coin,173750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,600,0.2,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,190000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,660,0.2,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,69},{coin,206750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,720,0.2,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,224000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,780,0.2,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,241750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,840,0.2,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,260250}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,900,0.2,0,0,[]]}]};
			true -> [] 
		end
	};
get(300205, Lv) ->
	#player_skill{ 
		skill_id=300205, 
		name = <<"催命">>,
		career = 3,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 0,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,50},{coin,60000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,20,0,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,52},{coin,75000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,40,0,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,54},{coin,90600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,60,0,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,56},{coin,106800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,80,0,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,58},{coin,123600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,100,0,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,60},{coin,141000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,120,0,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,62},{coin,159000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,140,0,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,64},{coin,177600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,160,0,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,66},{coin,196800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,180,0,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,68},{coin,216600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,200,0,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,70},{coin,237000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,220,0,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,72},{coin,258000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,240,0,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,279600}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,260,0,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,301800}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,280,0,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,80},{coin,324900}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{crit, [1000,1,300,0,0,0,[]]}]};
			true -> [] 
		end
	};
get(300206, Lv) ->
	#player_skill{ 
		skill_id=300206, 
		name = <<"失魂引">>,
		career = 3,
		type = 3,
		obj = 1,
		mod = 1,
		cd = 8000,
		attime = 0,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,40}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{dodge, [1000,1,0,2.0,3000,0,[]]}]};
			true -> [] 
		end
	};
get(300298, Lv) ->
	#player_skill{ 
		skill_id=300298, 
		name = <<"狂影关联技1">>,
		career = 3,
		type = 4,
		obj = 2,
		mod = 1,
		cd = 0,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,50000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,61750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,51},{coin,74000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,53},{coin,86750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,100000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,57},{coin,113750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,59},{coin,128000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,142750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,63},{coin,158000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,65},{coin,173750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,190000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,69},{coin,206750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,224000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,241750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,260250}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.25,0,0,[]]}]};
			true -> [] 
		end
	};
get(300299, Lv) ->
	#player_skill{ 
		skill_id=300299, 
		name = <<"狂影关联技2">>,
		career = 3,
		type = 4,
		obj = 2,
		mod = 1,
		cd = 0,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,47},{coin,50000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]},{hp, [1000,2,0,0.35,0,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [{lv,49},{coin,61750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]},{hp, [1000,2,0,0.01,4000,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [{lv,51},{coin,74000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [{lv,53},{coin,86750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [{lv,55},{coin,100000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 6 -> 
				#skill_lv_data{
					learn_condition = [{lv,57},{coin,113750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 7 -> 
				#skill_lv_data{
					learn_condition = [{lv,59},{coin,128000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 8 -> 
				#skill_lv_data{
					learn_condition = [{lv,61},{coin,142750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 9 -> 
				#skill_lv_data{
					learn_condition = [{lv,63},{coin,158000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 10 -> 
				#skill_lv_data{
					learn_condition = [{lv,65},{coin,173750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 11 -> 
				#skill_lv_data{
					learn_condition = [{lv,67},{coin,190000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 12 -> 
				#skill_lv_data{
					learn_condition = [{lv,69},{coin,206750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 13 -> 
				#skill_lv_data{
					learn_condition = [{lv,71},{coin,224000}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 14 -> 
				#skill_lv_data{
					learn_condition = [{lv,74},{coin,241750}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			Lv =:= 15 -> 
				#skill_lv_data{
					learn_condition = [{lv,77},{coin,260250}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,0,0.3,0,0,[]]}]};
			true -> [] 
		end
	};
get(400001, Lv) ->
	#player_skill{ 
		skill_id=400001, 
		name = <<"竞技场-诛仙指">>,
		career = 0,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 50000,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 1,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,0},{coin,0},{zq,0},{pro,100}],
					use_condition = [],
					combat_power = 0,
					area = 1,
					distance = 3,
					att_num = 1,
					data = [{hit, [1000,1,99999,0,0,0,[]]},{change_hp_ac_lim, [1000,2,0,0.35,0,0,[]]}]};
			true -> [] 
		end
	};
get(400002, Lv) ->
	#player_skill{ 
		skill_id=400002, 
		name = <<"白骨-BUFF攻击">>,
		career = 0,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 800,
		attime = 1,
		limit = [],
		stack = 50,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 100,
		is_calc_hurt = 1,
		status = 1,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,0},{coin,0},{zq,0},{pro,100}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 1,
					data = [{att, [1000,1,20,0,1200,0,[]]},{def, [1000,2,0,-0.07,4000,0,[]]},{hit, [1000,2,0,-0.07,4000,0,[]]},{dodge, [1000,2,0,-0.07,4000,0,[]]},{crit, [1000,2,0,-0.07,4000,0,[]]},{ten, [1000,2,0,-0.07,4000,0,[]]},{fire_def, [1000,2,0,-0.07,4000,0,[]]},{ice_def, [1000,2,0,-0.07,4000,0,[]]},{drug_def, [1000,2,0,-0.07,4000,0,[]]}]};
			true -> [] 
		end
	};
get(400003, Lv) ->
	#player_skill{ 
		skill_id=400003, 
		name = <<"BOSS-击晕">>,
		career = 0,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 10000,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,0},{coin,0},{zq,0},{pro,100}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{yun, [1000,2,0,0,3000,0,[]]}]};
			true -> [] 
		end
	};
get(400004, Lv) ->
	#player_skill{ 
		skill_id=400004, 
		name = <<"BOSS-击晕后爆发">>,
		career = 0,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 10000,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,0},{coin,0},{zq,0},{pro,100}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{att, [1000,1,9999,0,0,0,[]]},{hit, [1000,1,9999,0,0,0,[]]},{crit, [1000,1,9999,0,0,0,[]]}]};
			true -> [] 
		end
	};
get(400005, Lv) ->
	#player_skill{ 
		skill_id=400005, 
		name = <<"小怪-自爆特效">>,
		career = 0,
		type = 1,
		obj = 1,
		mod = 2,
		cd = 50000,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,0},{coin,0},{zq,0},{pro,100}],
					use_condition = [],
					combat_power = 0,
					area = 2,
					distance = 0,
					att_num = 6,
					data = [{att, [1000,1,99999,0,0,0,[]]}]};
			true -> [] 
		end
	};
get(400006, Lv) ->
	#player_skill{ 
		skill_id=400006, 
		name = <<"小怪-自爆伤害">>,
		career = 0,
		type = 1,
		obj = 1,
		mod = 2,
		cd = 0,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 1,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,0},{coin,0},{zq,0},{pro,100}],
					use_condition = [],
					combat_power = 0,
					area = 2,
					distance = 0,
					att_num = 6,
					data = [{att, [1000,1,99999,0,0,0,[]]}]};
			true -> [] 
		end
	};
get(400007, Lv) ->
	#player_skill{ 
		skill_id=400007, 
		name = <<"怪物加防">>,
		career = 0,
		type = 1,
		obj = 1,
		mod = 1,
		cd = 30000,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 0,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,0},{coin,0},{zq,0},{pro,100}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{def, [1000,2,0,2000,20000,0,[]]},{ten, [1000,2,0,2000,20000,0,[]]},{fire_def, [1000,2,0,2000,20000,0,[]]},{ice_def, [1000,2,0,2000,20000,0,[]]},{drug_def, [1000,2,0,2000,20000,0,[]]}]};
			true -> [] 
		end
	};
get(400008, Lv) ->
	#player_skill{ 
		skill_id=400008, 
		name = <<"招法盾怪">>,
		career = 0,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 40000,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 0,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,0},{coin,0},{zq,0},{pro,100}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{call_mon, [1000,1,[{30102,2,1,[]}],0,[]]}]};
			true -> [] 
		end
	};
get(400009, Lv) ->
	#player_skill{ 
		skill_id=400009, 
		name = <<"招自爆怪">>,
		career = 0,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 50000,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 0,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [{lv,0},{coin,0},{zq,0},{pro,100}],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{call_mon, [1000,1,[{30103,2,1,[]}],0,[]]}]};
			true -> [] 
		end
	};
get(400101, Lv) ->
	#player_skill{ 
		skill_id=400101, 
		name = <<"怪物普攻">>,
		career = 0,
		type = 1,
		obj = 2,
		mod = 1,
		cd = 0,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = []};
			true -> [] 
		end
	};
get(900001, Lv) ->
	#player_skill{ 
		skill_id=900001, 
		name = <<"宠物副本狂暴BUFF">>,
		career = 0,
		type = 3,
		obj = 1,
		mod = 1,
		cd = 0,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{att, [1000,1,0,3,15000,0,[]]}]};
			true -> [] 
		end
	};
get(900002, Lv) ->
	#player_skill{ 
		skill_id=900002, 
		name = <<"丢你雷啊">>,
		career = 0,
		type = 3,
		obj = 1,
		mod = 1,
		cd = 0,
		attime = 1,
		limit = [],
		stack = 0,
		skill_link = [],
		combo_skill = [],
		base_effect_id = 0,
		use_time = 0,
		is_calc_hurt = 1,
		status = 0,
		aoe_mod = 0,
		lv = Lv,
		data = if
			Lv =:= 1 -> 
				#skill_lv_data{
					learn_condition = [],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{att, [1000,1,0,0.25,1500000,0,[]]}]};
			Lv =:= 2 -> 
				#skill_lv_data{
					learn_condition = [],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{att, [1000,1,0,0.5,1500000,0,[]]}]};
			Lv =:= 3 -> 
				#skill_lv_data{
					learn_condition = [],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{att, [1000,1,0,0.75,1500000,0,[]]}]};
			Lv =:= 4 -> 
				#skill_lv_data{
					learn_condition = [],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{att, [1000,1,0,1,1500000,0,[]]}]};
			Lv =:= 5 -> 
				#skill_lv_data{
					learn_condition = [],
					use_condition = [],
					combat_power = 0,
					area = 0,
					distance = 0,
					att_num = 0,
					data = [{att, [1000,1,0,1.25,1500000,0,[]]}]};
			true -> [] 
		end
	};

get(_Id, _Lv) ->
    [].

get_max_lv(100101) -> 5;
get_max_lv(100102) -> 25;
get_max_lv(100103) -> 25;
get_max_lv(100104) -> 15;
get_max_lv(100105) -> 15;
get_max_lv(100106) -> 1;
get_max_lv(100201) -> 5;
get_max_lv(100202) -> 15;
get_max_lv(100203) -> 15;
get_max_lv(100204) -> 15;
get_max_lv(100205) -> 15;
get_max_lv(100206) -> 1;
get_max_lv(101999) -> 25;
get_max_lv(200101) -> 5;
get_max_lv(200102) -> 25;
get_max_lv(200103) -> 25;
get_max_lv(200104) -> 15;
get_max_lv(200105) -> 15;
get_max_lv(200106) -> 1;
get_max_lv(200199) -> 25;
get_max_lv(200201) -> 5;
get_max_lv(200202) -> 15;
get_max_lv(200203) -> 15;
get_max_lv(200204) -> 15;
get_max_lv(200205) -> 15;
get_max_lv(200206) -> 1;
get_max_lv(300101) -> 5;
get_max_lv(300102) -> 25;
get_max_lv(300103) -> 25;
get_max_lv(300104) -> 15;
get_max_lv(300105) -> 15;
get_max_lv(300106) -> 1;
get_max_lv(300201) -> 5;
get_max_lv(300202) -> 15;
get_max_lv(300203) -> 15;
get_max_lv(300204) -> 15;
get_max_lv(300205) -> 15;
get_max_lv(300206) -> 1;
get_max_lv(300298) -> 15;
get_max_lv(300299) -> 15;
get_max_lv(400001) -> 1;
get_max_lv(400002) -> 1;
get_max_lv(400003) -> 1;
get_max_lv(400004) -> 1;
get_max_lv(400005) -> 1;
get_max_lv(400006) -> 1;
get_max_lv(400007) -> 1;
get_max_lv(400008) -> 1;
get_max_lv(400009) -> 1;
get_max_lv(400101) -> 1;
get_max_lv(900001) -> 1;
get_max_lv(900002) -> 5;
get_max_lv(_Id) -> 
	0.
