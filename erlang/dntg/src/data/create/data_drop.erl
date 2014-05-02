%%%---------------------------------------
%%% @Module  : data_drop
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:28
%%% @Description:  生成掉落规则
%%%---------------------------------------
-module(data_drop).
-compile(export_all).
-include("drop.hrl").


get_task_mon(501038) -> [10401];
get_task_mon(501030) -> [16101];
get_task_mon(501027) -> [16104];
get_task_mon(501008) -> [10201];
get_task_mon(501006) -> [10202];
get_task_mon(501007) -> [10203];
get_task_mon(501010) -> [10204];
get_task_mon(501005) -> [10205];
get_task_mon(501004) -> [10206];
get_task_mon(501028) -> [10207];
get_task_mon(501011) -> [10208];
get_task_mon(501019) -> [24001];
get_task_mon(501018) -> [24002];
get_task_mon(501031) -> [16102,16103,16104,16105,16106,16107];
get_task_mon(501032) -> [24003,24004,24005,24006,24007,24008];
get_task_mon(501033) -> [10301,10302,10303,10304,10305,10306];
get_task_mon(501034) -> [10307,10308,10309,10310,10311,10312];
get_task_mon(501002) -> [30001];
get_task_mon(501003) -> [30002];
get_task_mon(_GoodsTypeId) -> [].

get_num_list() ->
    [{1,1}].

get_rule(10201) ->
	#ets_drop_rule{ mon_id=10201, boss=0, task=1, broad=0,
        drop_list = [14],
        drop_rule = [],
        counter_goods = []
    };
get_rule(10202) ->
	#ets_drop_rule{ mon_id=10202, boss=0, task=1, broad=0,
        drop_list = [15],
        drop_rule = [],
        counter_goods = []
    };
get_rule(10203) ->
	#ets_drop_rule{ mon_id=10203, boss=0, task=1, broad=0,
        drop_list = [16],
        drop_rule = [],
        counter_goods = []
    };
get_rule(10204) ->
	#ets_drop_rule{ mon_id=10204, boss=0, task=1, broad=0,
        drop_list = [17],
        drop_rule = [],
        counter_goods = []
    };
get_rule(10205) ->
	#ets_drop_rule{ mon_id=10205, boss=0, task=1, broad=0,
        drop_list = [18],
        drop_rule = [],
        counter_goods = []
    };
get_rule(10206) ->
	#ets_drop_rule{ mon_id=10206, boss=0, task=1, broad=0,
        drop_list = [19],
        drop_rule = [],
        counter_goods = []
    };
get_rule(10207) ->
	#ets_drop_rule{ mon_id=10207, boss=0, task=1, broad=0,
        drop_list = [20],
        drop_rule = [],
        counter_goods = []
    };
get_rule(10208) ->
	#ets_drop_rule{ mon_id=10208, boss=0, task=1, broad=0,
        drop_list = [21],
        drop_rule = [],
        counter_goods = []
    };
get_rule(10301) ->
	#ets_drop_rule{ mon_id=10301, boss=0, task=1, broad=0,
        drop_list = [29,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10302) ->
	#ets_drop_rule{ mon_id=10302, boss=0, task=1, broad=0,
        drop_list = [29,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10303) ->
	#ets_drop_rule{ mon_id=10303, boss=0, task=1, broad=0,
        drop_list = [29,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10304) ->
	#ets_drop_rule{ mon_id=10304, boss=0, task=1, broad=0,
        drop_list = [29,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10305) ->
	#ets_drop_rule{ mon_id=10305, boss=0, task=1, broad=0,
        drop_list = [29,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10306) ->
	#ets_drop_rule{ mon_id=10306, boss=0, task=1, broad=0,
        drop_list = [29,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10307) ->
	#ets_drop_rule{ mon_id=10307, boss=0, task=1, broad=0,
        drop_list = [30,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10308) ->
	#ets_drop_rule{ mon_id=10308, boss=0, task=1, broad=0,
        drop_list = [30,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10309) ->
	#ets_drop_rule{ mon_id=10309, boss=0, task=1, broad=0,
        drop_list = [30,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10310) ->
	#ets_drop_rule{ mon_id=10310, boss=0, task=1, broad=0,
        drop_list = [30,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10311) ->
	#ets_drop_rule{ mon_id=10311, boss=0, task=1, broad=0,
        drop_list = [30,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10312) ->
	#ets_drop_rule{ mon_id=10312, boss=0, task=1, broad=0,
        drop_list = [30,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10401) ->
	#ets_drop_rule{ mon_id=10401, boss=0, task=1, broad=0,
        drop_list = [22],
        drop_rule = [],
        counter_goods = []
    };
get_rule(16101) ->
	#ets_drop_rule{ mon_id=16101, boss=0, task=1, broad=0,
        drop_list = [23],
        drop_rule = [],
        counter_goods = []
    };
get_rule(16102) ->
	#ets_drop_rule{ mon_id=16102, boss=0, task=1, broad=0,
        drop_list = [27,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(16103) ->
	#ets_drop_rule{ mon_id=16103, boss=0, task=1, broad=0,
        drop_list = [27,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(16104) ->
	#ets_drop_rule{ mon_id=16104, boss=0, task=1, broad=0,
        drop_list = [24,27,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(16105) ->
	#ets_drop_rule{ mon_id=16105, boss=0, task=1, broad=0,
        drop_list = [27,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(16106) ->
	#ets_drop_rule{ mon_id=16106, boss=0, task=1, broad=0,
        drop_list = [27,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(16107) ->
	#ets_drop_rule{ mon_id=16107, boss=0, task=1, broad=0,
        drop_list = [27,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(20119) ->
	#ets_drop_rule{ mon_id=20119, boss=0, task=1, broad=0,
        drop_list = [12],
        drop_rule = [],
        counter_goods = []
    };
get_rule(20120) ->
	#ets_drop_rule{ mon_id=20120, boss=0, task=1, broad=0,
        drop_list = [13],
        drop_rule = [],
        counter_goods = []
    };
get_rule(23323) ->
	#ets_drop_rule{ mon_id=23323, boss=0, task=0, broad=1,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1},{300,1},{301,1},{301,1},{302,1}],400},{[{300,1},{300,1},{301,1},{302,1}],200},{[{300,1},{300,1},{301,1}],400}],
        counter_goods = []
    };
get_rule(23324) ->
	#ets_drop_rule{ mon_id=23324, boss=0, task=0, broad=1,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1},{300,1},{302,1},{301,1},{301,1}],500},{[{300,1},{300,1},{300,1},{302,1},{301,1},{301,1}],200},{[{300,1},{300,1},{300,1},{302,1}],300}],
        counter_goods = []
    };
get_rule(23325) ->
	#ets_drop_rule{ mon_id=23325, boss=0, task=0, broad=1,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1},{300,1},{300,1},{302,1},{302,1},{303,1}],800},{[{300,1},{300,1},{300,1},{302,1},{302,1}],200}],
        counter_goods = []
    };
get_rule(23326) ->
	#ets_drop_rule{ mon_id=23326, boss=0, task=0, broad=1,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1},{300,1},{300,1},{302,1},{302,1},{302,1},{303,1}],300},{[{300,1},{300,1},{300,1},{302,1},{302,1},{303,1}],200},{[{300,1},{300,1},{300,1},{300,1},{302,1},{302,1},{303,1}],200}],
        counter_goods = []
    };
get_rule(24001) ->
	#ets_drop_rule{ mon_id=24001, boss=0, task=1, broad=0,
        drop_list = [25],
        drop_rule = [],
        counter_goods = []
    };
get_rule(24002) ->
	#ets_drop_rule{ mon_id=24002, boss=0, task=1, broad=0,
        drop_list = [26],
        drop_rule = [],
        counter_goods = []
    };
get_rule(24003) ->
	#ets_drop_rule{ mon_id=24003, boss=0, task=1, broad=0,
        drop_list = [28,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(24004) ->
	#ets_drop_rule{ mon_id=24004, boss=0, task=1, broad=0,
        drop_list = [28,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(24005) ->
	#ets_drop_rule{ mon_id=24005, boss=0, task=1, broad=0,
        drop_list = [28,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(24006) ->
	#ets_drop_rule{ mon_id=24006, boss=0, task=1, broad=0,
        drop_list = [28,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(24007) ->
	#ets_drop_rule{ mon_id=24007, boss=0, task=1, broad=0,
        drop_list = [28,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(24008) ->
	#ets_drop_rule{ mon_id=24008, boss=0, task=1, broad=0,
        drop_list = [28,31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(30018) ->
	#ets_drop_rule{ mon_id=30018, boss=0, task=1, broad=0,
        drop_list = [11],
        drop_rule = [],
        counter_goods = []
    };
get_rule(34002) ->
	#ets_drop_rule{ mon_id=34002, boss=1, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],500},{[{103,1},{103,1},{103,1}],500}],
        counter_goods = []
    };
get_rule(34004) ->
	#ets_drop_rule{ mon_id=34004, boss=1, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],500},{[{103,1},{103,1},{103,1}],500}],
        counter_goods = []
    };
get_rule(34006) ->
	#ets_drop_rule{ mon_id=34006, boss=1, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],500},{[{103,1},{103,1},{103,1}],500}],
        counter_goods = []
    };
get_rule(34008) ->
	#ets_drop_rule{ mon_id=34008, boss=1, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],500},{[{103,1},{103,1},{103,1}],500}],
        counter_goods = []
    };
get_rule(34010) ->
	#ets_drop_rule{ mon_id=34010, boss=1, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],500},{[{103,1},{103,1},{103,1}],500}],
        counter_goods = []
    };
get_rule(34012) ->
	#ets_drop_rule{ mon_id=34012, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],500},{[{103,1},{103,1},{103,1}],500}],
        counter_goods = []
    };
get_rule(34014) ->
	#ets_drop_rule{ mon_id=34014, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],500},{[{103,1},{103,1},{103,1}],500}],
        counter_goods = []
    };
get_rule(34016) ->
	#ets_drop_rule{ mon_id=34016, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],500},{[{103,1},{103,1},{103,1}],500}],
        counter_goods = []
    };
get_rule(34018) ->
	#ets_drop_rule{ mon_id=34018, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],500},{[{103,1},{103,1},{103,1}],500}],
        counter_goods = []
    };
get_rule(34020) ->
	#ets_drop_rule{ mon_id=34020, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],500},{[{103,1},{103,1},{103,1}],500}],
        counter_goods = []
    };
get_rule(34022) ->
	#ets_drop_rule{ mon_id=34022, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],480},{[{103,1},{103,1},{103,1}],520}],
        counter_goods = []
    };
get_rule(34024) ->
	#ets_drop_rule{ mon_id=34024, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],460},{[{103,1},{103,1},{103,1}],540}],
        counter_goods = []
    };
get_rule(34026) ->
	#ets_drop_rule{ mon_id=34026, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],440},{[{103,1},{103,1},{103,1}],560}],
        counter_goods = []
    };
get_rule(34028) ->
	#ets_drop_rule{ mon_id=34028, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],420},{[{103,1},{103,1},{103,1}],580}],
        counter_goods = []
    };
get_rule(34030) ->
	#ets_drop_rule{ mon_id=34030, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],400},{[{103,1},{103,1},{103,1}],600}],
        counter_goods = []
    };
get_rule(34032) ->
	#ets_drop_rule{ mon_id=34032, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],380},{[{103,1},{103,1},{103,1}],620}],
        counter_goods = []
    };
get_rule(34034) ->
	#ets_drop_rule{ mon_id=34034, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],360},{[{103,1},{103,1},{103,1}],640}],
        counter_goods = []
    };
get_rule(34036) ->
	#ets_drop_rule{ mon_id=34036, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],340},{[{103,1},{103,1},{103,1}],660}],
        counter_goods = []
    };
get_rule(34038) ->
	#ets_drop_rule{ mon_id=34038, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],320},{[{103,1},{103,1},{103,1}],680}],
        counter_goods = []
    };
get_rule(34040) ->
	#ets_drop_rule{ mon_id=34040, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],300},{[{103,1},{103,1},{103,1}],700}],
        counter_goods = []
    };
get_rule(34042) ->
	#ets_drop_rule{ mon_id=34042, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],280},{[{103,1},{103,1},{103,1}],720}],
        counter_goods = []
    };
get_rule(34044) ->
	#ets_drop_rule{ mon_id=34044, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],260},{[{103,1},{103,1},{103,1}],740}],
        counter_goods = []
    };
get_rule(34046) ->
	#ets_drop_rule{ mon_id=34046, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],240},{[{103,1},{103,1},{103,1}],760}],
        counter_goods = []
    };
get_rule(34048) ->
	#ets_drop_rule{ mon_id=34048, boss=0, task=0, broad=1,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],220},{[{103,1},{103,1},{103,1}],780}],
        counter_goods = []
    };
get_rule(56201) ->
	#ets_drop_rule{ mon_id=56201, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],980},{[{200,1}],20}],
        counter_goods = []
    };
get_rule(56404) ->
	#ets_drop_rule{ mon_id=56404, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],940},{[{200,1}],60}],
        counter_goods = []
    };
get_rule(56414) ->
	#ets_drop_rule{ mon_id=56414, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],900},{[{200,1}],100}],
        counter_goods = []
    };
get_rule(56504) ->
	#ets_drop_rule{ mon_id=56504, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],860},{[{200,1}],140}],
        counter_goods = []
    };
get_rule(56604) ->
	#ets_drop_rule{ mon_id=56604, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],820},{[{200,1}],180}],
        counter_goods = []
    };
get_rule(56704) ->
	#ets_drop_rule{ mon_id=56704, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],780},{[{200,1}],220}],
        counter_goods = []
    };
get_rule(56804) ->
	#ets_drop_rule{ mon_id=56804, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],740},{[{200,1}],260}],
        counter_goods = []
    };
get_rule(56904) ->
	#ets_drop_rule{ mon_id=56904, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],700},{[{200,1}],300}],
        counter_goods = []
    };
get_rule(57004) ->
	#ets_drop_rule{ mon_id=57004, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],660},{[{200,1}],340}],
        counter_goods = []
    };
get_rule(57104) ->
	#ets_drop_rule{ mon_id=57104, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],620},{[{200,1}],380}],
        counter_goods = []
    };
get_rule(57204) ->
	#ets_drop_rule{ mon_id=57204, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],580},{[{200,1}],420}],
        counter_goods = []
    };
get_rule(57304) ->
	#ets_drop_rule{ mon_id=57304, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],540},{[{200,1}],460}],
        counter_goods = []
    };
get_rule(57404) ->
	#ets_drop_rule{ mon_id=57404, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],500},{[{200,1}],500}],
        counter_goods = []
    };
get_rule(57504) ->
	#ets_drop_rule{ mon_id=57504, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],460},{[{200,1}],540}],
        counter_goods = []
    };
get_rule(57604) ->
	#ets_drop_rule{ mon_id=57604, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],420},{[{200,1}],580}],
        counter_goods = []
    };
get_rule(57705) ->
	#ets_drop_rule{ mon_id=57705, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],380},{[{200,1}],620}],
        counter_goods = []
    };
get_rule(57804) ->
	#ets_drop_rule{ mon_id=57804, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],340},{[{200,1}],660}],
        counter_goods = []
    };
get_rule(57904) ->
	#ets_drop_rule{ mon_id=57904, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],300},{[{200,1}],700}],
        counter_goods = []
    };
get_rule(58004) ->
	#ets_drop_rule{ mon_id=58004, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],260},{[{200,1}],740}],
        counter_goods = []
    };
get_rule(58104) ->
	#ets_drop_rule{ mon_id=58104, boss=0, task=0, broad=1,
        drop_list = [9,10],
        drop_rule = [{[{200,1},{200,1}],220},{[{200,1}],780}],
        counter_goods = []
    };
get_rule(10701) ->
	#ets_drop_rule{ mon_id=10701, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{200,1},{200,1}],180},{[{200,1}],820}],
        counter_goods = []
    };
get_rule(10702) ->
	#ets_drop_rule{ mon_id=10702, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10703) ->
	#ets_drop_rule{ mon_id=10703, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10704) ->
	#ets_drop_rule{ mon_id=10704, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10705) ->
	#ets_drop_rule{ mon_id=10705, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10706) ->
	#ets_drop_rule{ mon_id=10706, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10707) ->
	#ets_drop_rule{ mon_id=10707, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10801) ->
	#ets_drop_rule{ mon_id=10801, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10802) ->
	#ets_drop_rule{ mon_id=10802, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10803) ->
	#ets_drop_rule{ mon_id=10803, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10804) ->
	#ets_drop_rule{ mon_id=10804, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10805) ->
	#ets_drop_rule{ mon_id=10805, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(10806) ->
	#ets_drop_rule{ mon_id=10806, boss=0, task=0, broad=1,
        drop_list = [31],
        drop_rule = [{[{420,1}],10}],
        counter_goods = []
    };
get_rule(23327) ->
	#ets_drop_rule{ mon_id=23327, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23328) ->
	#ets_drop_rule{ mon_id=23328, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23329) ->
	#ets_drop_rule{ mon_id=23329, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23330) ->
	#ets_drop_rule{ mon_id=23330, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23331) ->
	#ets_drop_rule{ mon_id=23331, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23332) ->
	#ets_drop_rule{ mon_id=23332, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23333) ->
	#ets_drop_rule{ mon_id=23333, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23334) ->
	#ets_drop_rule{ mon_id=23334, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23335) ->
	#ets_drop_rule{ mon_id=23335, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23336) ->
	#ets_drop_rule{ mon_id=23336, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23337) ->
	#ets_drop_rule{ mon_id=23337, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23338) ->
	#ets_drop_rule{ mon_id=23338, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23339) ->
	#ets_drop_rule{ mon_id=23339, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23340) ->
	#ets_drop_rule{ mon_id=23340, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23341) ->
	#ets_drop_rule{ mon_id=23341, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23342) ->
	#ets_drop_rule{ mon_id=23342, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23343) ->
	#ets_drop_rule{ mon_id=23343, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23344) ->
	#ets_drop_rule{ mon_id=23344, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23345) ->
	#ets_drop_rule{ mon_id=23345, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23346) ->
	#ets_drop_rule{ mon_id=23346, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23347) ->
	#ets_drop_rule{ mon_id=23347, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23348) ->
	#ets_drop_rule{ mon_id=23348, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23349) ->
	#ets_drop_rule{ mon_id=23349, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23350) ->
	#ets_drop_rule{ mon_id=23350, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23351) ->
	#ets_drop_rule{ mon_id=23351, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23352) ->
	#ets_drop_rule{ mon_id=23352, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23353) ->
	#ets_drop_rule{ mon_id=23353, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23354) ->
	#ets_drop_rule{ mon_id=23354, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23355) ->
	#ets_drop_rule{ mon_id=23355, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23356) ->
	#ets_drop_rule{ mon_id=23356, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23357) ->
	#ets_drop_rule{ mon_id=23357, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23358) ->
	#ets_drop_rule{ mon_id=23358, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23359) ->
	#ets_drop_rule{ mon_id=23359, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23360) ->
	#ets_drop_rule{ mon_id=23360, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23361) ->
	#ets_drop_rule{ mon_id=23361, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23362) ->
	#ets_drop_rule{ mon_id=23362, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23363) ->
	#ets_drop_rule{ mon_id=23363, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23364) ->
	#ets_drop_rule{ mon_id=23364, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23365) ->
	#ets_drop_rule{ mon_id=23365, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23366) ->
	#ets_drop_rule{ mon_id=23366, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23367) ->
	#ets_drop_rule{ mon_id=23367, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23368) ->
	#ets_drop_rule{ mon_id=23368, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23369) ->
	#ets_drop_rule{ mon_id=23369, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(23370) ->
	#ets_drop_rule{ mon_id=23370, boss=0, task=0, broad=0,
        drop_list = [6,7,8],
        drop_rule = [{[{300,1}],280}],
        counter_goods = []
    };
get_rule(30001) ->
	#ets_drop_rule{ mon_id=30001, boss=0, task=0, broad=1,
        drop_list = [32],
        drop_rule = [],
        counter_goods = []
    };
get_rule(30002) ->
	#ets_drop_rule{ mon_id=30002, boss=0, task=0, broad=1,
        drop_list = [33],
        drop_rule = [],
        counter_goods = []
    };
get_rule(34050) ->
	#ets_drop_rule{ mon_id=34050, boss=0, task=0, broad=0,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],200},{[{103,1},{103,1},{103,1}],800}],
        counter_goods = []
    };
get_rule(34052) ->
	#ets_drop_rule{ mon_id=34052, boss=0, task=0, broad=0,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],180},{[{103,1},{103,1},{103,1}],820}],
        counter_goods = []
    };
get_rule(34054) ->
	#ets_drop_rule{ mon_id=34054, boss=0, task=0, broad=0,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],160},{[{103,1},{103,1},{103,1}],840}],
        counter_goods = []
    };
get_rule(34056) ->
	#ets_drop_rule{ mon_id=34056, boss=0, task=0, broad=0,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],140},{[{103,1},{103,1},{103,1}],860}],
        counter_goods = []
    };
get_rule(34058) ->
	#ets_drop_rule{ mon_id=34058, boss=0, task=0, broad=0,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],120},{[{103,1},{103,1},{103,1}],880}],
        counter_goods = []
    };
get_rule(34060) ->
	#ets_drop_rule{ mon_id=34060, boss=0, task=0, broad=0,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],100},{[{103,1},{103,1},{103,1}],900}],
        counter_goods = []
    };
get_rule(34062) ->
	#ets_drop_rule{ mon_id=34062, boss=0, task=0, broad=0,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],80},{[{103,1},{103,1},{103,1}],920}],
        counter_goods = []
    };
get_rule(34064) ->
	#ets_drop_rule{ mon_id=34064, boss=0, task=0, broad=0,
        drop_list = [5],
        drop_rule = [{[{103,1},{103,1}],60},{[{103,1},{103,1},{103,1}],940}],
        counter_goods = []
    };
get_rule(30100) ->
	#ets_drop_rule{ mon_id=30100, boss=0, task=0, broad=0,
        drop_list = [34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49],
        drop_rule = [{[{500,1},{502,1},{503,1},{503,1},{503,1},{503,1},{504,1},{505,1},{506,1},{507,1}],500},{[{500,1},{503,1},{503,1},{503,1},{503,1},{504,1},{505,1},{506,1},{507,1}],500}],
        counter_goods = []
    };
get_rule(30200) ->
	#ets_drop_rule{ mon_id=30200, boss=0, task=0, broad=0,
        drop_list = [34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49],
        drop_rule = [{[{500,1},{502,1},{503,1},{503,1},{503,1},{503,1},{504,1},{505,1},{506,1},{507,1}],500},{[{500,1},{503,1},{503,1},{503,1},{503,1},{504,1},{505,1},{506,1},{507,1}],500}],
        counter_goods = []
    };
get_rule(30300) ->
	#ets_drop_rule{ mon_id=30300, boss=0, task=0, broad=0,
        drop_list = [34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49],
        drop_rule = [{[{500,1},{502,1},{503,1},{503,1},{503,1},{503,1},{504,1},{505,1},{506,1},{507,1}],500},{[{500,1},{503,1},{503,1},{503,1},{503,1},{504,1},{505,1},{506,1},{507,1}],500}],
        counter_goods = []
    };
get_rule(30500) ->
	#ets_drop_rule{ mon_id=30500, boss=0, task=0, broad=0,
        drop_list = [34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49],
        drop_rule = [{[{503,1},{503,1},{503,1},{504,1},{505,1},{506,1},{507,1}],1000}],
        counter_goods = []
    };
get_rule(30501) ->
	#ets_drop_rule{ mon_id=30501, boss=0, task=0, broad=0,
        drop_list = [34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49],
        drop_rule = [{[{503,1},{503,1},{503,1},{504,1},{505,1},{506,1},{507,1}],1000}],
        counter_goods = []
    };
get_rule(30502) ->
	#ets_drop_rule{ mon_id=30502, boss=0, task=0, broad=0,
        drop_list = [34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49],
        drop_rule = [{[{500,1},{502,1},{503,1},{503,1},{503,1},{503,1},{504,1},{505,1},{506,1},{507,1}],500},{[{500,1},{503,1},{503,1},{503,1},{503,1},{504,1},{505,1},{506,1},{507,1}],500}],
        counter_goods = []
    };
get_rule(12007) ->
	#ets_drop_rule{ mon_id=12007, boss=0, task=0, broad=0,
        drop_list = [40,41,42,43,44,45,46,47,48,49],
        drop_rule = [{[{505,1},{506,1},{507,1}],1000}],
        counter_goods = []
    };
get_rule(_MonId) ->
    [].

get_goods(1) ->
	#ets_drop_goods{ id=1, type=0, list_id=40, goods_id=112302, ratio=500, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(2) ->
	#ets_drop_goods{ id=2, type=0, list_id=100, goods_id=112201, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(3) ->
	#ets_drop_goods{ id=3, type=0, list_id=101, goods_id=112704, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(4) ->
	#ets_drop_goods{ id=4, type=0, list_id=102, goods_id=601701, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(5) ->
	#ets_drop_goods{ id=5, type=0, list_id=103, goods_id=111041, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(9) ->
	#ets_drop_goods{ id=9, type=0, list_id=200, goods_id=231201, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(10) ->
	#ets_drop_goods{ id=10, type=0, list_id=201, goods_id=111041, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(6) ->
	#ets_drop_goods{ id=6, type=0, list_id=300, goods_id=623001, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(7) ->
	#ets_drop_goods{ id=7, type=0, list_id=301, goods_id=623002, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(8) ->
	#ets_drop_goods{ id=8, type=0, list_id=302, goods_id=623003, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(11) ->
	#ets_drop_goods{ id=11, type=2, list_id=400, goods_id=501038, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(12) ->
	#ets_drop_goods{ id=12, type=2, list_id=401, goods_id=501030, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(13) ->
	#ets_drop_goods{ id=13, type=2, list_id=402, goods_id=501027, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(14) ->
	#ets_drop_goods{ id=14, type=2, list_id=403, goods_id=501008, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(15) ->
	#ets_drop_goods{ id=15, type=2, list_id=404, goods_id=501006, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(16) ->
	#ets_drop_goods{ id=16, type=2, list_id=405, goods_id=501007, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(17) ->
	#ets_drop_goods{ id=17, type=2, list_id=406, goods_id=501010, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(18) ->
	#ets_drop_goods{ id=18, type=2, list_id=407, goods_id=501005, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(19) ->
	#ets_drop_goods{ id=19, type=2, list_id=408, goods_id=501004, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(20) ->
	#ets_drop_goods{ id=20, type=2, list_id=409, goods_id=501028, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(21) ->
	#ets_drop_goods{ id=21, type=2, list_id=410, goods_id=501011, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(22) ->
	#ets_drop_goods{ id=22, type=2, list_id=411, goods_id=501038, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(23) ->
	#ets_drop_goods{ id=23, type=2, list_id=412, goods_id=501030, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(24) ->
	#ets_drop_goods{ id=24, type=2, list_id=413, goods_id=501027, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(25) ->
	#ets_drop_goods{ id=25, type=2, list_id=414, goods_id=501019, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(26) ->
	#ets_drop_goods{ id=26, type=2, list_id=415, goods_id=501018, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(27) ->
	#ets_drop_goods{ id=27, type=2, list_id=416, goods_id=501031, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(28) ->
	#ets_drop_goods{ id=28, type=2, list_id=417, goods_id=501032, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(29) ->
	#ets_drop_goods{ id=29, type=2, list_id=418, goods_id=501033, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(30) ->
	#ets_drop_goods{ id=30, type=2, list_id=419, goods_id=501034, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(31) ->
	#ets_drop_goods{ id=31, type=0, list_id=420, goods_id=671001, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(32) ->
	#ets_drop_goods{ id=32, type=2, list_id=421, goods_id=501002, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(33) ->
	#ets_drop_goods{ id=33, type=2, list_id=422, goods_id=501003, ratio=1000, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(34) ->
	#ets_drop_goods{ id=34, type=0, list_id=500, goods_id=601601, ratio=330, num=1, stren=0, prefix=0, power_bind=0, bind=1, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(35) ->
	#ets_drop_goods{ id=35, type=0, list_id=500, goods_id=601601, ratio=670, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(36) ->
	#ets_drop_goods{ id=36, type=0, list_id=501, goods_id=112752, ratio=330, num=1, stren=0, prefix=0, power_bind=0, bind=1, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(37) ->
	#ets_drop_goods{ id=37, type=0, list_id=501, goods_id=112752, ratio=670, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(39) ->
	#ets_drop_goods{ id=39, type=0, list_id=502, goods_id=112751, ratio=670, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(38) ->
	#ets_drop_goods{ id=38, type=0, list_id=502, goods_id=112751, ratio=330, num=1, stren=0, prefix=0, power_bind=0, bind=1, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(40) ->
	#ets_drop_goods{ id=40, type=0, list_id=503, goods_id=111041, ratio=330, num=1, stren=0, prefix=0, power_bind=0, bind=1, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(41) ->
	#ets_drop_goods{ id=41, type=0, list_id=503, goods_id=111041, ratio=670, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(42) ->
	#ets_drop_goods{ id=42, type=0, list_id=504, goods_id=112301, ratio=330, num=1, stren=0, prefix=0, power_bind=0, bind=1, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(43) ->
	#ets_drop_goods{ id=43, type=0, list_id=504, goods_id=112301, ratio=670, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(45) ->
	#ets_drop_goods{ id=45, type=0, list_id=505, goods_id=111481, ratio=670, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(44) ->
	#ets_drop_goods{ id=44, type=0, list_id=505, goods_id=111481, ratio=330, num=1, stren=0, prefix=0, power_bind=0, bind=1, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(46) ->
	#ets_drop_goods{ id=46, type=0, list_id=506, goods_id=111491, ratio=330, num=1, stren=0, prefix=0, power_bind=0, bind=1, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(47) ->
	#ets_drop_goods{ id=47, type=0, list_id=506, goods_id=111491, ratio=670, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(48) ->
	#ets_drop_goods{ id=48, type=0, list_id=507, goods_id=111501, ratio=330, num=1, stren=0, prefix=0, power_bind=0, bind=1, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(49) ->
	#ets_drop_goods{ id=49, type=0, list_id=507, goods_id=111501, ratio=670, num=1, stren=0, prefix=0, power_bind=0, bind=2, notice=0,factor=0, reduce=0, recharge_bind=0, vip_bind=0, guild_bind=0, hour_start=0, hour_end=0, time_start=0, time_end=0, replace_list=[] };
get_goods(_Id) ->
    [].

