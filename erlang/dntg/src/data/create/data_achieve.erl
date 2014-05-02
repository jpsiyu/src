%%%---------------------------------------
%%% @Module  : data_achieve
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  成就
%%%---------------------------------------
-module(data_achieve).
-compile(export_all).
-include("achieve.hrl").


get_by_type(1) ->
    [get_base(Id) || Id <- [100001,100002,100003,100004,100005,100006,100007,100008,100901,100902,100903,100904,101301,101302,101303,101304,101401,101402,101403,101404,101501,101502,101503,101504]];

get_by_type(2) ->
    [get_base(Id) || Id <- [110101,110102,110103,110104,110201,110202,110203,110204,110205,110206,110207,110208,110401,110402,110403,110404,110405,110406,110407,110601,110602,110603,110604,110605,110606]];

get_by_type(4) ->
    [get_base(Id) || Id <- [130101,130102,130103,130104,130105,130106,130201,130202,130203,130204,130205,130501,130502,130503,130504,131801,131802,131803,132101,132102,132103,132104,132105,132901,132902,132903,132904,132905,132906,132907,136501,136601]];

get_by_type(5) ->
    [get_base(Id) || Id <- [143001,143002,143003,143004,143005,143006,143051,143052,143053,143054,143055,143056,143101,143102,143103,143104,143401,143402,143403,143404]];

get_by_type(6) ->
    [get_base(Id) || Id <- [150001,150002,150003,150201,150303,151001,151002,151003,151101,151102,151103,151104,151105,151106,151301,151302,151303,151304,151401,151402,151403,151404]];

get_by_type(7) ->
    [get_base(Id) || Id <- [160401,160402,160403,160404,160501,160502,160503,160504,160601,160602,160603,160604]];

get_by_type(_Id) ->
    [].

get_by_type_id(1, 0) ->
    [get_base(Id) || Id <- [100001,100002,100003,100004,100005,100006,100007,100008]];

get_by_type_id(1, 9) ->
    [get_base(Id) || Id <- [100901,100902,100903,100904]];

get_by_type_id(1, 13) ->
    [get_base(Id) || Id <- [101301,101302,101303,101304]];

get_by_type_id(1, 14) ->
    [get_base(Id) || Id <- [101401,101402,101403,101404]];

get_by_type_id(1, 15) ->
    [get_base(Id) || Id <- [101501,101502,101503,101504]];

get_by_type_id(2, 9) ->
    [get_base(Id) || Id <- [110101,110102,110103]];

get_by_type_id(2, 11) ->
    [get_base(Id) || Id <- [110104]];

get_by_type_id(2, 10) ->
    [get_base(Id) || Id <- [110201,110202,110203,110204]];

get_by_type_id(2, 12) ->
    [get_base(Id) || Id <- [110205,110206,110207]];

get_by_type_id(2, 13) ->
    [get_base(Id) || Id <- [110208]];

get_by_type_id(2, 4) ->
    [get_base(Id) || Id <- [110401,110402,110403,110404,110405,110406,110407]];

get_by_type_id(2, 6) ->
    [get_base(Id) || Id <- [110601,110602,110603,110604,110605,110606]];

get_by_type_id(4, 1) ->
    [get_base(Id) || Id <- [130101,130102,130103,130104,130105,130106]];

get_by_type_id(4, 2) ->
    [get_base(Id) || Id <- [130201,130202,130203,130204,130205]];

get_by_type_id(4, 5) ->
    [get_base(Id) || Id <- [130501,130502,130503,130504]];

get_by_type_id(4, 18) ->
    [get_base(Id) || Id <- [131801,131802,131803,136601]];

get_by_type_id(4, 30) ->
    [get_base(Id) || Id <- [132101,132102,132103,132104,132105]];

get_by_type_id(4, 29) ->
    [get_base(Id) || Id <- [132901,132902,132903,132904,132905,132906,132907]];

get_by_type_id(4, 66) ->
    [get_base(Id) || Id <- [136501]];

get_by_type_id(5, 36) ->
    [get_base(Id) || Id <- [143001,143002,143003,143004,143005,143006]];

get_by_type_id(5, 37) ->
    [get_base(Id) || Id <- [143051,143052,143053,143054,143055,143056]];

get_by_type_id(5, 31) ->
    [get_base(Id) || Id <- [143101,143102,143103,143104]];

get_by_type_id(5, 34) ->
    [get_base(Id) || Id <- [143401,143402,143403,143404]];

get_by_type_id(6, 0) ->
    [get_base(Id) || Id <- [150001,150002,150003]];

get_by_type_id(6, 2) ->
    [get_base(Id) || Id <- [150201]];

get_by_type_id(6, 3) ->
    [get_base(Id) || Id <- [150303]];

get_by_type_id(6, 10) ->
    [get_base(Id) || Id <- [151001,151002,151003]];

get_by_type_id(6, 11) ->
    [get_base(Id) || Id <- [151101,151102,151103,151104,151105,151106]];

get_by_type_id(6, 13) ->
    [get_base(Id) || Id <- [151301,151302,151303,151304]];

get_by_type_id(6, 14) ->
    [get_base(Id) || Id <- [151401,151402,151403,151404]];

get_by_type_id(7, 4) ->
    [get_base(Id) || Id <- [160401,160402,160403,160404]];

get_by_type_id(7, 5) ->
    [get_base(Id) || Id <- [160501,160502,160503,160504]];

get_by_type_id(7, 6) ->
    [get_base(Id) || Id <- [160601,160602,160603,160604]];

get_by_type_id(_Type, _TypeId) ->
    [].

get_base(100001) ->
	#base_achieve{id=100001, type=1, type_id=0, lim_num=0, is_count=0, name_id=201703, score=20, type_list=[101320], sort_type=10, sort_id=1};
get_base(100002) ->
	#base_achieve{id=100002, type=1, type_id=0, lim_num=0, is_count=0, name_id=0, score=25, type_list=[101990], sort_type=10, sort_id=2};
get_base(100003) ->
	#base_achieve{id=100003, type=1, type_id=0, lim_num=0, is_count=0, name_id=0, score=30, type_list=[103050], sort_type=10, sort_id=3};
get_base(100004) ->
	#base_achieve{id=100004, type=1, type_id=0, lim_num=0, is_count=0, name_id=0, score=35, type_list=[103560], sort_type=10, sort_id=4};
get_base(100005) ->
	#base_achieve{id=100005, type=1, type_id=0, lim_num=0, is_count=0, name_id=0, score=40, type_list=[104210], sort_type=10, sort_id=5};
get_base(100006) ->
	#base_achieve{id=100006, type=1, type_id=0, lim_num=0, is_count=0, name_id=0, score=45, type_list=[1], sort_type=10, sort_id=6};
get_base(100007) ->
	#base_achieve{id=100007, type=1, type_id=0, lim_num=0, is_count=0, name_id=0, score=60, type_list=[1], sort_type=10, sort_id=7};
get_base(100008) ->
	#base_achieve{id=100008, type=1, type_id=0, lim_num=0, is_count=0, name_id=0, score=80, type_list=[1], sort_type=10, sort_id=8};
get_base(100901) ->
	#base_achieve{id=100901, type=1, type_id=9, lim_num=10, is_count=1, name_id=0, score=20, type_list=[], sort_type=19, sort_id=1};
get_base(100902) ->
	#base_achieve{id=100902, type=1, type_id=9, lim_num=50, is_count=1, name_id=0, score=30, type_list=[], sort_type=19, sort_id=2};
get_base(100903) ->
	#base_achieve{id=100903, type=1, type_id=9, lim_num=300, is_count=1, name_id=0, score=40, type_list=[], sort_type=19, sort_id=3};
get_base(100904) ->
	#base_achieve{id=100904, type=1, type_id=9, lim_num=1000, is_count=1, name_id=0, score=60, type_list=[], sort_type=19, sort_id=4};
get_base(101301) ->
	#base_achieve{id=101301, type=1, type_id=13, lim_num=3, is_count=1, name_id=0, score=20, type_list=[], sort_type=113, sort_id=1};
get_base(101302) ->
	#base_achieve{id=101302, type=1, type_id=13, lim_num=10, is_count=1, name_id=0, score=30, type_list=[], sort_type=113, sort_id=2};
get_base(101303) ->
	#base_achieve{id=101303, type=1, type_id=13, lim_num=60, is_count=1, name_id=0, score=40, type_list=[], sort_type=113, sort_id=3};
get_base(101304) ->
	#base_achieve{id=101304, type=1, type_id=13, lim_num=200, is_count=1, name_id=0, score=60, type_list=[], sort_type=113, sort_id=4};
get_base(101401) ->
	#base_achieve{id=101401, type=1, type_id=14, lim_num=50, is_count=1, name_id=0, score=20, type_list=[], sort_type=114, sort_id=1};
get_base(101402) ->
	#base_achieve{id=101402, type=1, type_id=14, lim_num=200, is_count=1, name_id=0, score=30, type_list=[], sort_type=114, sort_id=2};
get_base(101403) ->
	#base_achieve{id=101403, type=1, type_id=14, lim_num=1000, is_count=1, name_id=0, score=40, type_list=[], sort_type=114, sort_id=3};
get_base(101404) ->
	#base_achieve{id=101404, type=1, type_id=14, lim_num=2000, is_count=1, name_id=0, score=60, type_list=[], sort_type=114, sort_id=4};
get_base(101501) ->
	#base_achieve{id=101501, type=1, type_id=15, lim_num=10, is_count=1, name_id=0, score=20, type_list=[], sort_type=115, sort_id=1};
get_base(101502) ->
	#base_achieve{id=101502, type=1, type_id=15, lim_num=100, is_count=1, name_id=0, score=30, type_list=[], sort_type=115, sort_id=2};
get_base(101503) ->
	#base_achieve{id=101503, type=1, type_id=15, lim_num=500, is_count=1, name_id=0, score=40, type_list=[], sort_type=115, sort_id=3};
get_base(101504) ->
	#base_achieve{id=101504, type=1, type_id=15, lim_num=2000, is_count=1, name_id=0, score=60, type_list=[], sort_type=115, sort_id=4};
get_base(110101) ->
	#base_achieve{id=110101, type=2, type_id=9, lim_num=40, is_count=0, name_id=0, score=30, type_list=[], sort_type=29, sort_id=2};
get_base(110102) ->
	#base_achieve{id=110102, type=2, type_id=9, lim_num=50, is_count=0, name_id=0, score=40, type_list=[], sort_type=29, sort_id=3};
get_base(110103) ->
	#base_achieve{id=110103, type=2, type_id=9, lim_num=60, is_count=0, name_id=0, score=60, type_list=[], sort_type=29, sort_id=4};
get_base(110104) ->
	#base_achieve{id=110104, type=2, type_id=11, lim_num=60, is_count=0, name_id=0, score=80, type_list=[], sort_type=29, sort_id=5};
get_base(110201) ->
	#base_achieve{id=110201, type=2, type_id=10, lim_num=40, is_count=0, name_id=201707, score=20, type_list=[10040,10140,10240], sort_type=210, sort_id=1};
get_base(110202) ->
	#base_achieve{id=110202, type=2, type_id=10, lim_num=50, is_count=0, name_id=0, score=40, type_list=[10050,10150,10250], sort_type=210, sort_id=2};
get_base(110203) ->
	#base_achieve{id=110203, type=2, type_id=10, lim_num=60, is_count=0, name_id=0, score=60, type_list=[10060,10160,10260], sort_type=210, sort_id=3};
get_base(110204) ->
	#base_achieve{id=110204, type=2, type_id=10, lim_num=70, is_count=0, name_id=0, score=80, type_list=[10072,10172,10272], sort_type=210, sort_id=4};
get_base(110205) ->
	#base_achieve{id=110205, type=2, type_id=12, lim_num=40, is_count=0, name_id=201708, score=40, type_list=[10042,10142,10242], sort_type=212, sort_id=1};
get_base(110206) ->
	#base_achieve{id=110206, type=2, type_id=12, lim_num=50, is_count=0, name_id=0, score=60, type_list=[10052,10152,10252], sort_type=212, sort_id=2};
get_base(110207) ->
	#base_achieve{id=110207, type=2, type_id=12, lim_num=60, is_count=0, name_id=0, score=80, type_list=[10062,10162,10262], sort_type=212, sort_id=3};
get_base(110208) ->
	#base_achieve{id=110208, type=2, type_id=13, lim_num=60, is_count=0, name_id=201709, score=200, type_list=[10075,10175,10275], sort_type=212, sort_id=4};
get_base(110401) ->
	#base_achieve{id=110401, type=2, type_id=4, lim_num=3, is_count=0, name_id=201710, score=20, type_list=[], sort_type=24, sort_id=1};
get_base(110402) ->
	#base_achieve{id=110402, type=2, type_id=4, lim_num=4, is_count=0, name_id=0, score=30, type_list=[], sort_type=24, sort_id=2};
get_base(110403) ->
	#base_achieve{id=110403, type=2, type_id=4, lim_num=5, is_count=0, name_id=0, score=40, type_list=[], sort_type=24, sort_id=3};
get_base(110404) ->
	#base_achieve{id=110404, type=2, type_id=4, lim_num=6, is_count=0, name_id=0, score=50, type_list=[], sort_type=24, sort_id=4};
get_base(110405) ->
	#base_achieve{id=110405, type=2, type_id=4, lim_num=7, is_count=0, name_id=0, score=80, type_list=[], sort_type=24, sort_id=5};
get_base(110406) ->
	#base_achieve{id=110406, type=2, type_id=4, lim_num=8, is_count=0, name_id=0, score=100, type_list=[], sort_type=24, sort_id=6};
get_base(110407) ->
	#base_achieve{id=110407, type=2, type_id=4, lim_num=9, is_count=0, name_id=0, score=200, type_list=[], sort_type=24, sort_id=7};
get_base(110601) ->
	#base_achieve{id=110601, type=2, type_id=6, lim_num=10, is_count=0, name_id=0, score=30, type_list=[], sort_type=26, sort_id=2};
get_base(110602) ->
	#base_achieve{id=110602, type=2, type_id=6, lim_num=15, is_count=0, name_id=0, score=60, type_list=[], sort_type=26, sort_id=3};
get_base(110603) ->
	#base_achieve{id=110603, type=2, type_id=6, lim_num=20, is_count=0, name_id=0, score=80, type_list=[], sort_type=26, sort_id=4};
get_base(110604) ->
	#base_achieve{id=110604, type=2, type_id=6, lim_num=25, is_count=0, name_id=0, score=100, type_list=[], sort_type=26, sort_id=5};
get_base(110605) ->
	#base_achieve{id=110605, type=2, type_id=6, lim_num=30, is_count=0, name_id=0, score=150, type_list=[], sort_type=26, sort_id=6};
get_base(110606) ->
	#base_achieve{id=110606, type=2, type_id=6, lim_num=35, is_count=0, name_id=0, score=200, type_list=[], sort_type=26, sort_id=7};
get_base(130101) ->
	#base_achieve{id=130101, type=4, type_id=1, lim_num=30, is_count=0, name_id=0, score=20, type_list=[], sort_type=41, sort_id=1};
get_base(130102) ->
	#base_achieve{id=130102, type=4, type_id=1, lim_num=40, is_count=0, name_id=0, score=30, type_list=[], sort_type=41, sort_id=2};
get_base(130103) ->
	#base_achieve{id=130103, type=4, type_id=1, lim_num=50, is_count=0, name_id=0, score=40, type_list=[], sort_type=41, sort_id=3};
get_base(130104) ->
	#base_achieve{id=130104, type=4, type_id=1, lim_num=60, is_count=0, name_id=0, score=60, type_list=[], sort_type=41, sort_id=4};
get_base(130105) ->
	#base_achieve{id=130105, type=4, type_id=1, lim_num=70, is_count=0, name_id=0, score=70, type_list=[], sort_type=41, sort_id=5};
get_base(130106) ->
	#base_achieve{id=130106, type=4, type_id=1, lim_num=80, is_count=0, name_id=0, score=80, type_list=[], sort_type=41, sort_id=6};
get_base(130201) ->
	#base_achieve{id=130201, type=4, type_id=2, lim_num=100000, is_count=0, name_id=0, score=20, type_list=[], sort_type=42, sort_id=1};
get_base(130202) ->
	#base_achieve{id=130202, type=4, type_id=2, lim_num=1000000, is_count=0, name_id=0, score=30, type_list=[], sort_type=42, sort_id=2};
get_base(130203) ->
	#base_achieve{id=130203, type=4, type_id=2, lim_num=10000000, is_count=0, name_id=201701, score=40, type_list=[], sort_type=42, sort_id=3};
get_base(130204) ->
	#base_achieve{id=130204, type=4, type_id=2, lim_num=100000000, is_count=0, name_id=0, score=60, type_list=[], sort_type=42, sort_id=4};
get_base(130205) ->
	#base_achieve{id=130205, type=4, type_id=2, lim_num=500000000, is_count=0, name_id=201725, score=150, type_list=[], sort_type=42, sort_id=5};
get_base(130501) ->
	#base_achieve{id=130501, type=4, type_id=5, lim_num=50, is_count=0, name_id=0, score=20, type_list=[], sort_type=45, sort_id=1};
get_base(130502) ->
	#base_achieve{id=130502, type=4, type_id=5, lim_num=500, is_count=0, name_id=0, score=30, type_list=[], sort_type=45, sort_id=2};
get_base(130503) ->
	#base_achieve{id=130503, type=4, type_id=5, lim_num=2000, is_count=0, name_id=201702, score=40, type_list=[], sort_type=45, sort_id=3};
get_base(130504) ->
	#base_achieve{id=130504, type=4, type_id=5, lim_num=10000, is_count=0, name_id=0, score=60, type_list=[], sort_type=45, sort_id=4};
get_base(131801) ->
	#base_achieve{id=131801, type=4, type_id=18, lim_num=40, is_count=0, name_id=0, score=40, type_list=[], sort_type=418, sort_id=3};
get_base(131802) ->
	#base_achieve{id=131802, type=4, type_id=18, lim_num=50, is_count=0, name_id=0, score=60, type_list=[], sort_type=418, sort_id=4};
get_base(131803) ->
	#base_achieve{id=131803, type=4, type_id=18, lim_num=60, is_count=0, name_id=0, score=80, type_list=[], sort_type=418, sort_id=5};
get_base(132101) ->
	#base_achieve{id=132101, type=4, type_id=30, lim_num=10, is_count=0, name_id=0, score=20, type_list=[], sort_type=421, sort_id=1};
get_base(132102) ->
	#base_achieve{id=132102, type=4, type_id=30, lim_num=100, is_count=0, name_id=0, score=30, type_list=[], sort_type=421, sort_id=2};
get_base(132103) ->
	#base_achieve{id=132103, type=4, type_id=30, lim_num=200, is_count=0, name_id=0, score=40, type_list=[], sort_type=421, sort_id=3};
get_base(132104) ->
	#base_achieve{id=132104, type=4, type_id=30, lim_num=360, is_count=0, name_id=0, score=60, type_list=[], sort_type=421, sort_id=4};
get_base(132105) ->
	#base_achieve{id=132105, type=4, type_id=30, lim_num=699, is_count=0, name_id=0, score=100, type_list=[], sort_type=421, sort_id=5};
get_base(132901) ->
	#base_achieve{id=132901, type=4, type_id=29, lim_num=5, is_count=1, name_id=0, score=20, type_list=[], sort_type=429, sort_id=1};
get_base(132902) ->
	#base_achieve{id=132902, type=4, type_id=29, lim_num=100, is_count=1, name_id=0, score=30, type_list=[], sort_type=429, sort_id=2};
get_base(132903) ->
	#base_achieve{id=132903, type=4, type_id=29, lim_num=1000, is_count=1, name_id=0, score=40, type_list=[], sort_type=429, sort_id=3};
get_base(132904) ->
	#base_achieve{id=132904, type=4, type_id=29, lim_num=5000, is_count=1, name_id=0, score=60, type_list=[], sort_type=429, sort_id=4};
get_base(132905) ->
	#base_achieve{id=132905, type=4, type_id=29, lim_num=10000, is_count=1, name_id=0, score=100, type_list=[], sort_type=429, sort_id=5};
get_base(132906) ->
	#base_achieve{id=132906, type=4, type_id=29, lim_num=50000, is_count=1, name_id=0, score=150, type_list=[], sort_type=429, sort_id=6};
get_base(132907) ->
	#base_achieve{id=132907, type=4, type_id=29, lim_num=100000, is_count=1, name_id=0, score=200, type_list=[], sort_type=429, sort_id=7};
get_base(136501) ->
	#base_achieve{id=136501, type=4, type_id=66, lim_num=1, is_count=0, name_id=0, score=20, type_list=[], sort_type=418, sort_id=1};
get_base(136601) ->
	#base_achieve{id=136601, type=4, type_id=18, lim_num=30, is_count=0, name_id=0, score=25, type_list=[], sort_type=418, sort_id=2};
get_base(143001) ->
	#base_achieve{id=143001, type=5, type_id=36, lim_num=1, is_count=1, name_id=0, score=20, type_list=[40006,40008,40009,40010,40011,16101,16102,16120,16121], sort_type=536, sort_id=1};
get_base(143002) ->
	#base_achieve{id=143002, type=5, type_id=36, lim_num=10, is_count=1, name_id=0, score=25, type_list=[40006,40008,40009,40010,40011,16101,16102,16120,16121], sort_type=536, sort_id=2};
get_base(143003) ->
	#base_achieve{id=143003, type=5, type_id=36, lim_num=100, is_count=1, name_id=0, score=30, type_list=[40006,40008,40009,40010,40011,16101,16102,16120,16121], sort_type=536, sort_id=3};
get_base(143004) ->
	#base_achieve{id=143004, type=5, type_id=36, lim_num=500, is_count=1, name_id=0, score=40, type_list=[40006,40008,40009,40010,40011,16101,16102,16120,16121], sort_type=536, sort_id=4};
get_base(143005) ->
	#base_achieve{id=143005, type=5, type_id=36, lim_num=1200, is_count=1, name_id=0, score=60, type_list=[40006,40008,40009,40010,40011,16101,16102,16120,16121], sort_type=536, sort_id=5};
get_base(143006) ->
	#base_achieve{id=143006, type=5, type_id=36, lim_num=2000, is_count=1, name_id=0, score=80, type_list=[40006,40008,40009,40010,40011,16101,16102,16120,16121], sort_type=536, sort_id=6};
get_base(143051) ->
	#base_achieve{id=143051, type=5, type_id=37, lim_num=1, is_count=1, name_id=0, score=20, type_list=[40300,40301,40302,40303,40304,40005,40031,40032,40033,40034,40040,40041,40042,40043,40044,16110,16111,16112,16113,40050,40051,40052,40053,40054,40061,40062,40063,40064,40065,40066,40067,40068,40069,40070,40071,40072,40073,40074,40075,40076,40077,40078,40079,40080,40081,40082,40083,40084,40085,40086,40087,40088,40089,40090], sort_type=537, sort_id=1};
get_base(143052) ->
	#base_achieve{id=143052, type=5, type_id=37, lim_num=10, is_count=1, name_id=0, score=30, type_list=[40300,40301,40302,40303,40304,40005,40031,40032,40033,40034,40040,40041,40042,40043,40044,16110,16111,16112,16113,40050,40051,40052,40053,40054,40061,40062,40063,40064,40065,40066,40067,40068,40069,40070,40071,40072,40073,40074,40075,40076,40077,40078,40079,40080,40081,40082,40083,40084,40085,40086,40087,40088,40089,40090], sort_type=537, sort_id=2};
get_base(143053) ->
	#base_achieve{id=143053, type=5, type_id=37, lim_num=100, is_count=1, name_id=0, score=40, type_list=[40300,40301,40302,40303,40304,40005,40031,40032,40033,40034,40040,40041,40042,40043,40044,16110,16111,16112,16113,40050,40051,40052,40053,40054,40061,40062,40063,40064,40065,40066,40067,40068,40069,40070,40071,40072,40073,40074,40075,40076,40077,40078,40079,40080,40081,40082,40083,40084,40085,40086,40087,40088,40089,40090], sort_type=537, sort_id=3};
get_base(143054) ->
	#base_achieve{id=143054, type=5, type_id=37, lim_num=500, is_count=1, name_id=0, score=60, type_list=[40300,40301,40302,40303,40304,40005,40031,40032,40033,40034,40040,40041,40042,40043,40044,16110,16111,16112,16113,40050,40051,40052,40053,40054,40061,40062,40063,40064,40065,40066,40067,40068,40069,40070,40071,40072,40073,40074,40075,40076,40077,40078,40079,40080,40081,40082,40083,40084,40085,40086,40087,40088,40089,40090], sort_type=537, sort_id=4};
get_base(143055) ->
	#base_achieve{id=143055, type=5, type_id=37, lim_num=1200, is_count=1, name_id=0, score=80, type_list=[40300,40301,40302,40303,40304,40005,40031,40032,40033,40034,40040,40041,40042,40043,40044,16110,16111,16112,16113,40050,40051,40052,40053,40054,40061,40062,40063,40064,40065,40066,40067,40068,40069,40070,40071,40072,40073,40074,40075,40076,40077,40078,40079,40080,40081,40082,40083,40084,40085,40086,40087,40088,40089,40090], sort_type=537, sort_id=5};
get_base(143056) ->
	#base_achieve{id=143056, type=5, type_id=37, lim_num=2000, is_count=1, name_id=0, score=100, type_list=[40300,40301,40302,40303,40304,40005,40031,40032,40033,40034,40040,40041,40042,40043,40044,16110,16111,16112,16113,40050,40051,40052,40053,40054,40061,40062,40063,40064,40065,40066,40067,40068,40069,40070,40071,40072,40073,40074,40075,40076,40077,40078,40079,40080,40081,40082,40083,40084,40085,40086,40087,40088,40089,40090], sort_type=537, sort_id=6};
get_base(143101) ->
	#base_achieve{id=143101, type=5, type_id=31, lim_num=1, is_count=1, name_id=201712, score=20, type_list=[], sort_type=531, sort_id=1};
get_base(143102) ->
	#base_achieve{id=143102, type=5, type_id=31, lim_num=50, is_count=1, name_id=0, score=30, type_list=[], sort_type=531, sort_id=2};
get_base(143103) ->
	#base_achieve{id=143103, type=5, type_id=31, lim_num=500, is_count=1, name_id=0, score=40, type_list=[], sort_type=531, sort_id=3};
get_base(143104) ->
	#base_achieve{id=143104, type=5, type_id=31, lim_num=2000, is_count=1, name_id=0, score=60, type_list=[], sort_type=531, sort_id=4};
get_base(143401) ->
	#base_achieve{id=143401, type=5, type_id=34, lim_num=500, is_count=1, name_id=0, score=20, type_list=[], sort_type=534, sort_id=1};
get_base(143402) ->
	#base_achieve{id=143402, type=5, type_id=34, lim_num=5000, is_count=1, name_id=0, score=30, type_list=[], sort_type=534, sort_id=2};
get_base(143403) ->
	#base_achieve{id=143403, type=5, type_id=34, lim_num=50000, is_count=1, name_id=0, score=40, type_list=[], sort_type=534, sort_id=3};
get_base(143404) ->
	#base_achieve{id=143404, type=5, type_id=34, lim_num=200000, is_count=1, name_id=0, score=60, type_list=[], sort_type=534, sort_id=4};
get_base(150001) ->
	#base_achieve{id=150001, type=6, type_id=0, lim_num=1, is_count=0, name_id=0, score=20, type_list=[], sort_type=60, sort_id=1};
get_base(150002) ->
	#base_achieve{id=150002, type=6, type_id=0, lim_num=50, is_count=0, name_id=0, score=30, type_list=[], sort_type=60, sort_id=2};
get_base(150003) ->
	#base_achieve{id=150003, type=6, type_id=0, lim_num=100, is_count=0, name_id=201715, score=40, type_list=[], sort_type=60, sort_id=3};
get_base(150201) ->
	#base_achieve{id=150201, type=6, type_id=2, lim_num=1, is_count=0, name_id=0, score=20, type_list=[], sort_type=610, sort_id=1};
get_base(150303) ->
	#base_achieve{id=150303, type=6, type_id=3, lim_num=1, is_count=1, name_id=0, score=20, type_list=[], sort_type=611, sort_id=1};
get_base(151001) ->
	#base_achieve{id=151001, type=6, type_id=10, lim_num=8000, is_count=1, name_id=0, score=30, type_list=[], sort_type=610, sort_id=2};
get_base(151002) ->
	#base_achieve{id=151002, type=6, type_id=10, lim_num=50000, is_count=1, name_id=0, score=40, type_list=[], sort_type=610, sort_id=3};
get_base(151003) ->
	#base_achieve{id=151003, type=6, type_id=10, lim_num=300000, is_count=1, name_id=0, score=60, type_list=[], sort_type=610, sort_id=4};
get_base(151101) ->
	#base_achieve{id=151101, type=6, type_id=11, lim_num=1000, is_count=1, name_id=0, score=30, type_list=[], sort_type=611, sort_id=2};
get_base(151102) ->
	#base_achieve{id=151102, type=6, type_id=11, lim_num=10000, is_count=1, name_id=0, score=40, type_list=[], sort_type=611, sort_id=3};
get_base(151103) ->
	#base_achieve{id=151103, type=6, type_id=11, lim_num=50000, is_count=1, name_id=0, score=50, type_list=[], sort_type=611, sort_id=4};
get_base(151104) ->
	#base_achieve{id=151104, type=6, type_id=11, lim_num=100000, is_count=1, name_id=0, score=60, type_list=[], sort_type=611, sort_id=5};
get_base(151105) ->
	#base_achieve{id=151105, type=6, type_id=11, lim_num=500000, is_count=1, name_id=0, score=70, type_list=[], sort_type=611, sort_id=6};
get_base(151106) ->
	#base_achieve{id=151106, type=6, type_id=11, lim_num=1000000, is_count=1, name_id=0, score=80, type_list=[], sort_type=611, sort_id=7};
get_base(151301) ->
	#base_achieve{id=151301, type=6, type_id=13, lim_num=2, is_count=1, name_id=0, score=20, type_list=[], sort_type=613, sort_id=1};
get_base(151302) ->
	#base_achieve{id=151302, type=6, type_id=13, lim_num=30, is_count=1, name_id=0, score=30, type_list=[], sort_type=613, sort_id=2};
get_base(151303) ->
	#base_achieve{id=151303, type=6, type_id=13, lim_num=500, is_count=1, name_id=0, score=40, type_list=[], sort_type=613, sort_id=3};
get_base(151304) ->
	#base_achieve{id=151304, type=6, type_id=13, lim_num=1000, is_count=1, name_id=0, score=60, type_list=[], sort_type=613, sort_id=4};
get_base(151401) ->
	#base_achieve{id=151401, type=6, type_id=14, lim_num=1, is_count=1, name_id=0, score=20, type_list=[], sort_type=614, sort_id=1};
get_base(151402) ->
	#base_achieve{id=151402, type=6, type_id=14, lim_num=50, is_count=1, name_id=0, score=30, type_list=[], sort_type=614, sort_id=2};
get_base(151403) ->
	#base_achieve{id=151403, type=6, type_id=14, lim_num=300, is_count=1, name_id=201717, score=40, type_list=[], sort_type=614, sort_id=3};
get_base(151404) ->
	#base_achieve{id=151404, type=6, type_id=14, lim_num=1800, is_count=1, name_id=0, score=60, type_list=[], sort_type=614, sort_id=4};
get_base(160401) ->
	#base_achieve{id=160401, type=7, type_id=4, lim_num=30, is_count=1, name_id=201720, score=20, type_list=[], sort_type=74, sort_id=1};
get_base(160402) ->
	#base_achieve{id=160402, type=7, type_id=4, lim_num=200, is_count=1, name_id=0, score=30, type_list=[], sort_type=74, sort_id=2};
get_base(160403) ->
	#base_achieve{id=160403, type=7, type_id=4, lim_num=800, is_count=1, name_id=0, score=40, type_list=[], sort_type=74, sort_id=3};
get_base(160404) ->
	#base_achieve{id=160404, type=7, type_id=4, lim_num=3000, is_count=1, name_id=0, score=60, type_list=[], sort_type=74, sort_id=4};
get_base(160501) ->
	#base_achieve{id=160501, type=7, type_id=5, lim_num=30, is_count=1, name_id=201721, score=20, type_list=[], sort_type=75, sort_id=1};
get_base(160502) ->
	#base_achieve{id=160502, type=7, type_id=5, lim_num=200, is_count=1, name_id=0, score=30, type_list=[], sort_type=75, sort_id=2};
get_base(160503) ->
	#base_achieve{id=160503, type=7, type_id=5, lim_num=800, is_count=1, name_id=0, score=40, type_list=[], sort_type=75, sort_id=3};
get_base(160504) ->
	#base_achieve{id=160504, type=7, type_id=5, lim_num=3000, is_count=1, name_id=0, score=60, type_list=[], sort_type=75, sort_id=4};
get_base(160601) ->
	#base_achieve{id=160601, type=7, type_id=6, lim_num=30, is_count=1, name_id=201722, score=20, type_list=[], sort_type=76, sort_id=1};
get_base(160602) ->
	#base_achieve{id=160602, type=7, type_id=6, lim_num=300, is_count=1, name_id=0, score=30, type_list=[], sort_type=76, sort_id=2};
get_base(160603) ->
	#base_achieve{id=160603, type=7, type_id=6, lim_num=1200, is_count=1, name_id=0, score=40, type_list=[], sort_type=76, sort_id=3};
get_base(160604) ->
	#base_achieve{id=160604, type=7, type_id=6, lim_num=8000, is_count=1, name_id=0, score=60, type_list=[], sort_type=76, sort_id=4};
get_base(_Id) ->
    [].


%% 取大类成长各等级所需要成就点数
get_score_by(Type, Level) ->
	Tuple = {Type, Level},
	case Tuple of
		{1, 0} -> 225;
		{1, 1} -> 500;
		{1, 2} -> 655;
		{1, 3} -> 1235;
		{2, 0} -> 210;
		{2, 1} -> 485;
		{2, 2} -> 1450;
		{2, 3} -> 2890;
		{4, 0} -> 165;
		{4, 1} -> 495;
		{4, 2} -> 858;
		{4, 3} -> 1485;
		{5, 0} -> 125;
		{5, 1} -> 300;
		{5, 2} -> 1225;
		{5, 3} -> 1885;
		{6, 0} -> 215;
		{6, 1} -> 500;
		{6, 2} -> 575;
		{6, 3} -> 1190;
		{7, 0} -> 65;
		{7, 1} -> 160;
		{7, 2} -> 400;
		{7, 3} -> 900;
		_ -> 0
	end.

%% 取大类成长各等级奖励的物品ID
get_award_id(Type, Level) ->
	Tuple = {Type, Level},
	case Tuple of		
		{1, 1} -> 111041;
		{1, 2} -> 111042;
		{1, 3} -> 111043;
		{1, 4} -> 111044;
		{2, 1} -> 111041;
		{2, 2} -> 111042;
		{2, 3} -> 111043;
		{2, 4} -> 111044;
		{4, 1} -> 111041;
		{4, 2} -> 111042;
		{4, 3} -> 111043;
		{4, 4} -> 111044;
		{5, 1} -> 111041;
		{5, 2} -> 111042;
		{5, 3} -> 111043;
		{5, 4} -> 111044;
		{6, 1} -> 111041;
		{6, 2} -> 111042;
		{6, 3} -> 111043;
		{6, 4} -> 111044;
		{7, 1} -> 111041;
		{7, 2} -> 111042;
		{7, 3} -> 111043;
		{7, 4} -> 111044;
		_ -> 0
	end.

%% 获取成就点上限值
get_score_limitup() ->
	11290.
