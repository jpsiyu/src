%%%---------------------------------------
%%% @Module  : data_suit
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:32
%%% @Description:  称号相关
%%%---------------------------------------
-module(data_suit).
-compile(export_all).
-include("goods.hrl").

%%通过套装id获取记录
get_belong(10040) -> 
	#suit_belong{suit_id=10040,level=40,series=1,max=6};
get_belong(10042) -> 
	#suit_belong{suit_id=10042,level=42,series=1,max=6};
get_belong(10050) -> 
	#suit_belong{suit_id=10050,level=50,series=1,max=6};
get_belong(10052) -> 
	#suit_belong{suit_id=10052,level=52,series=1,max=6};
get_belong(10060) -> 
	#suit_belong{suit_id=10060,level=60,series=1,max=6};
get_belong(10062) -> 
	#suit_belong{suit_id=10062,level=62,series=1,max=6};
get_belong(10070) -> 
	#suit_belong{suit_id=10070,level=70,series=1,max=6};
get_belong(10072) -> 
	#suit_belong{suit_id=10072,level=72,series=1,max=6};
get_belong(10075) -> 
	#suit_belong{suit_id=10075,level=75,series=1,max=6};
get_belong(10085) -> 
	#suit_belong{suit_id=10085,level=85,series=1,max=6};
get_belong(10140) -> 
	#suit_belong{suit_id=10140,level=40,series=1,max=6};
get_belong(10142) -> 
	#suit_belong{suit_id=10142,level=42,series=1,max=6};
get_belong(10150) -> 
	#suit_belong{suit_id=10150,level=50,series=1,max=6};
get_belong(10152) -> 
	#suit_belong{suit_id=10152,level=52,series=1,max=6};
get_belong(10160) -> 
	#suit_belong{suit_id=10160,level=60,series=1,max=6};
get_belong(10162) -> 
	#suit_belong{suit_id=10162,level=62,series=1,max=6};
get_belong(10170) -> 
	#suit_belong{suit_id=10170,level=70,series=1,max=6};
get_belong(10172) -> 
	#suit_belong{suit_id=10172,level=72,series=1,max=6};
get_belong(10175) -> 
	#suit_belong{suit_id=10175,level=75,series=1,max=6};
get_belong(10185) -> 
	#suit_belong{suit_id=10185,level=85,series=1,max=6};
get_belong(10240) -> 
	#suit_belong{suit_id=10240,level=40,series=1,max=6};
get_belong(10242) -> 
	#suit_belong{suit_id=10242,level=42,series=1,max=6};
get_belong(10250) -> 
	#suit_belong{suit_id=10250,level=50,series=1,max=6};
get_belong(10252) -> 
	#suit_belong{suit_id=10252,level=52,series=1,max=6};
get_belong(10260) -> 
	#suit_belong{suit_id=10260,level=60,series=1,max=6};
get_belong(10262) -> 
	#suit_belong{suit_id=10262,level=62,series=1,max=6};
get_belong(10270) -> 
	#suit_belong{suit_id=10270,level=70,series=1,max=6};
get_belong(10272) -> 
	#suit_belong{suit_id=10272,level=72,series=1,max=6};
get_belong(10275) -> 
	#suit_belong{suit_id=10275,level=75,series=1,max=6};
get_belong(10285) -> 
	#suit_belong{suit_id=10285,level=85,series=1,max=6};
get_belong(30030) -> 
	#suit_belong{suit_id=30030,level=30,series=3,max=6};
get_belong(30040) -> 
	#suit_belong{suit_id=30040,level=40,series=3,max=6};
get_belong(30042) -> 
	#suit_belong{suit_id=30042,level=42,series=3,max=6};
get_belong(30050) -> 
	#suit_belong{suit_id=30050,level=50,series=3,max=6};
get_belong(30052) -> 
	#suit_belong{suit_id=30052,level=52,series=3,max=6};
get_belong(30060) -> 
	#suit_belong{suit_id=30060,level=60,series=3,max=6};
get_belong(30062) -> 
	#suit_belong{suit_id=30062,level=62,series=3,max=6};
get_belong(30070) -> 
	#suit_belong{suit_id=30070,level=70,series=3,max=6};
get_belong(30072) -> 
	#suit_belong{suit_id=30072,level=72,series=3,max=6};
get_belong(30075) -> 
	#suit_belong{suit_id=30075,level=75,series=3,max=6};
get_belong(30085) -> 
	#suit_belong{suit_id=30085,level=85,series=3,max=6};
get_belong(_) ->
	[].

%%通过套装id和套装件数获取记录
get_attribute(10040, 2) -> 
	#suit_attribute{suit_id=10040,name= <<"菩提套装（40级）">>,suit_num=2,value_type=[{1,750}]};
get_attribute(10040, 4) -> 
	#suit_attribute{suit_id=10040,name= <<"菩提套装（40级）">>,suit_num=4,value_type=[{1,750},{4,220}]};
get_attribute(10040, 6) -> 
	#suit_attribute{suit_id=10040,name= <<"菩提套装（40级）">>,suit_num=6,value_type=[{1,750},{4,220},{3,93}]};
get_attribute(10042, 2) -> 
	#suit_attribute{suit_id=10042,name= <<"菩提（真）套装（40级）">>,suit_num=2,value_type=[{1,900}]};
get_attribute(10042, 4) -> 
	#suit_attribute{suit_id=10042,name= <<"菩提（真）套装（40级）">>,suit_num=4,value_type=[{1,900},{16,220}]};
get_attribute(10042, 6) -> 
	#suit_attribute{suit_id=10042,name= <<"菩提（真）套装（40级）">>,suit_num=6,value_type=[{1,900},{16,220},{3,110}]};
get_attribute(10050, 2) -> 
	#suit_attribute{suit_id=10050,name= <<"菩提套装（50级）">>,suit_num=2,value_type=[{1,900}]};
get_attribute(10050, 4) -> 
	#suit_attribute{suit_id=10050,name= <<"菩提套装（50级）">>,suit_num=4,value_type=[{1,900},{4,260}]};
get_attribute(10050, 6) -> 
	#suit_attribute{suit_id=10050,name= <<"菩提套装（50级）">>,suit_num=6,value_type=[{1,900},{4,260},{3,110}]};
get_attribute(10052, 2) -> 
	#suit_attribute{suit_id=10052,name= <<"菩提（真）套装（50级）">>,suit_num=2,value_type=[{1,1050}]};
get_attribute(10052, 4) -> 
	#suit_attribute{suit_id=10052,name= <<"菩提（真）套装（50级）">>,suit_num=4,value_type=[{1,1050},{16,260}]};
get_attribute(10052, 6) -> 
	#suit_attribute{suit_id=10052,name= <<"菩提（真）套装（50级）">>,suit_num=6,value_type=[{1,1050},{16,260},{3,130}]};
get_attribute(10060, 2) -> 
	#suit_attribute{suit_id=10060,name= <<"菩提套装（60级）">>,suit_num=2,value_type=[{1,1050}]};
get_attribute(10060, 4) -> 
	#suit_attribute{suit_id=10060,name= <<"菩提套装（60级）">>,suit_num=4,value_type=[{1,1050},{4,306}]};
get_attribute(10060, 6) -> 
	#suit_attribute{suit_id=10060,name= <<"菩提套装（60级）">>,suit_num=6,value_type=[{1,1050},{4,306},{3,130}]};
get_attribute(10062, 2) -> 
	#suit_attribute{suit_id=10062,name= <<"菩提（真）套装（60级）">>,suit_num=2,value_type=[{1,1228}]};
get_attribute(10062, 4) -> 
	#suit_attribute{suit_id=10062,name= <<"菩提（真）套装（60级）">>,suit_num=4,value_type=[{1,1228},{16,306}]};
get_attribute(10062, 6) -> 
	#suit_attribute{suit_id=10062,name= <<"菩提（真）套装（60级）">>,suit_num=6,value_type=[{1,1228},{16,306},{3,153}]};
get_attribute(10070, 2) -> 
	#suit_attribute{suit_id=10070,name= <<"菩提套装（70级）">>,suit_num=2,value_type=[{1,1250}]};
get_attribute(10070, 4) -> 
	#suit_attribute{suit_id=10070,name= <<"菩提套装（70级）">>,suit_num=4,value_type=[{1,1250},{4,360}]};
get_attribute(10070, 6) -> 
	#suit_attribute{suit_id=10070,name= <<"菩提套装（70级）">>,suit_num=6,value_type=[{1,1250},{4,360},{3,156}]};
get_attribute(10072, 2) -> 
	#suit_attribute{suit_id=10072,name= <<"菩提（真）套装（70级）">>,suit_num=2,value_type=[{1,1445}]};
get_attribute(10072, 4) -> 
	#suit_attribute{suit_id=10072,name= <<"菩提（真）套装（70级）">>,suit_num=4,value_type=[{1,1445},{16,360}]};
get_attribute(10072, 6) -> 
	#suit_attribute{suit_id=10072,name= <<"菩提（真）套装（70级）">>,suit_num=6,value_type=[{1,1445},{16,360},{3,180}]};
get_attribute(10075, 2) -> 
	#suit_attribute{suit_id=10075,name= <<"菩提·六道套装">>,suit_num=2,value_type=[{1,1700}]};
get_attribute(10075, 4) -> 
	#suit_attribute{suit_id=10075,name= <<"菩提·六道套装">>,suit_num=4,value_type=[{1,1700},{16,425}]};
get_attribute(10075, 6) -> 
	#suit_attribute{suit_id=10075,name= <<"菩提·六道套装">>,suit_num=6,value_type=[{1,1700},{16,425},{3,212}]};
get_attribute(10085, 2) -> 
	#suit_attribute{suit_id=10085,name= <<"菩提·七曜套装">>,suit_num=2,value_type=[{1,2000}]};
get_attribute(10085, 4) -> 
	#suit_attribute{suit_id=10085,name= <<"菩提·七曜套装">>,suit_num=4,value_type=[{1,2000},{16,500}]};
get_attribute(10085, 6) -> 
	#suit_attribute{suit_id=10085,name= <<"菩提·七曜套装">>,suit_num=6,value_type=[{1,2000},{16,500},{3,250}]};
get_attribute(10140, 2) -> 
	#suit_attribute{suit_id=10140,name= <<"酆都套装（40级）">>,suit_num=2,value_type=[{6,112}]};
get_attribute(10140, 4) -> 
	#suit_attribute{suit_id=10140,name= <<"酆都套装（40级）">>,suit_num=4,value_type=[{6,112},{4,220}]};
get_attribute(10140, 6) -> 
	#suit_attribute{suit_id=10140,name= <<"酆都套装（40级）">>,suit_num=6,value_type=[{6,112},{4,220},{3,93}]};
get_attribute(10142, 2) -> 
	#suit_attribute{suit_id=10142,name= <<"酆都（真）套装（40级）">>,suit_num=2,value_type=[{6,132}]};
get_attribute(10142, 4) -> 
	#suit_attribute{suit_id=10142,name= <<"酆都（真）套装（40级）">>,suit_num=4,value_type=[{6,132},{16,220}]};
get_attribute(10142, 6) -> 
	#suit_attribute{suit_id=10142,name= <<"酆都（真）套装（40级）">>,suit_num=6,value_type=[{6,132},{16,220},{3,110}]};
get_attribute(10150, 2) -> 
	#suit_attribute{suit_id=10150,name= <<"酆都套装（50级）">>,suit_num=2,value_type=[{6,132}]};
get_attribute(10150, 4) -> 
	#suit_attribute{suit_id=10150,name= <<"酆都套装（50级）">>,suit_num=4,value_type=[{6,132},{4,260}]};
get_attribute(10150, 6) -> 
	#suit_attribute{suit_id=10150,name= <<"酆都套装（50级）">>,suit_num=6,value_type=[{6,132},{4,260},{3,110}]};
get_attribute(10152, 2) -> 
	#suit_attribute{suit_id=10152,name= <<"酆都（真）套装（50级）">>,suit_num=2,value_type=[{6,156}]};
get_attribute(10152, 4) -> 
	#suit_attribute{suit_id=10152,name= <<"酆都（真）套装（50级）">>,suit_num=4,value_type=[{6,156},{16,260}]};
get_attribute(10152, 6) -> 
	#suit_attribute{suit_id=10152,name= <<"酆都（真）套装（50级）">>,suit_num=6,value_type=[{6,156},{16,260},{3,130}]};
get_attribute(10160, 2) -> 
	#suit_attribute{suit_id=10160,name= <<"酆都套装（60级）">>,suit_num=2,value_type=[{6,156}]};
get_attribute(10160, 4) -> 
	#suit_attribute{suit_id=10160,name= <<"酆都套装（60级）">>,suit_num=4,value_type=[{6,156},{4,306}]};
get_attribute(10160, 6) -> 
	#suit_attribute{suit_id=10160,name= <<"酆都套装（60级）">>,suit_num=6,value_type=[{6,156},{4,306},{3,130}]};
get_attribute(10162, 2) -> 
	#suit_attribute{suit_id=10162,name= <<"酆都（真）套装（60级）">>,suit_num=2,value_type=[{6,184}]};
get_attribute(10162, 4) -> 
	#suit_attribute{suit_id=10162,name= <<"酆都（真）套装（60级）">>,suit_num=4,value_type=[{6,184},{16,306}]};
get_attribute(10162, 6) -> 
	#suit_attribute{suit_id=10162,name= <<"酆都（真）套装（60级）">>,suit_num=6,value_type=[{6,184},{16,306},{3,153}]};
get_attribute(10170, 2) -> 
	#suit_attribute{suit_id=10170,name= <<"酆都套装（70级）">>,suit_num=2,value_type=[{6,184}]};
get_attribute(10170, 4) -> 
	#suit_attribute{suit_id=10170,name= <<"酆都套装（70级）">>,suit_num=4,value_type=[{6,184},{4,360}]};
get_attribute(10170, 6) -> 
	#suit_attribute{suit_id=10170,name= <<"酆都套装（70级）">>,suit_num=6,value_type=[{6,184},{4,360},{3,156}]};
get_attribute(10172, 2) -> 
	#suit_attribute{suit_id=10172,name= <<"酆都（真）套装（70级）">>,suit_num=2,value_type=[{6,216}]};
get_attribute(10172, 4) -> 
	#suit_attribute{suit_id=10172,name= <<"酆都（真）套装（70级）">>,suit_num=4,value_type=[{6,216},{16,360}]};
get_attribute(10172, 6) -> 
	#suit_attribute{suit_id=10172,name= <<"酆都（真）套装（70级）">>,suit_num=6,value_type=[{6,216},{16,360},{3,180}]};
get_attribute(10175, 2) -> 
	#suit_attribute{suit_id=10175,name= <<"酆都·六道套装">>,suit_num=2,value_type=[{6,255}]};
get_attribute(10175, 4) -> 
	#suit_attribute{suit_id=10175,name= <<"酆都·六道套装">>,suit_num=4,value_type=[{6,255},{16,425}]};
get_attribute(10175, 6) -> 
	#suit_attribute{suit_id=10175,name= <<"酆都·六道套装">>,suit_num=6,value_type=[{6,255},{16,425},{3,212}]};
get_attribute(10185, 2) -> 
	#suit_attribute{suit_id=10185,name= <<"酆都·七曜套装">>,suit_num=2,value_type=[{6,300}]};
get_attribute(10185, 4) -> 
	#suit_attribute{suit_id=10185,name= <<"酆都·七曜套装">>,suit_num=4,value_type=[{6,300},{16,500}]};
get_attribute(10185, 6) -> 
	#suit_attribute{suit_id=10185,name= <<"酆都·七曜套装">>,suit_num=6,value_type=[{6,300},{16,500},{3,250}]};
get_attribute(10240, 2) -> 
	#suit_attribute{suit_id=10240,name= <<"谪仙套装（40级）">>,suit_num=2,value_type=[{5,136}]};
get_attribute(10240, 4) -> 
	#suit_attribute{suit_id=10240,name= <<"谪仙套装（40级）">>,suit_num=4,value_type=[{5,136},{4,220}]};
get_attribute(10240, 6) -> 
	#suit_attribute{suit_id=10240,name= <<"谪仙套装（40级）">>,suit_num=6,value_type=[{5,136},{4,220},{3,93}]};
get_attribute(10242, 2) -> 
	#suit_attribute{suit_id=10242,name= <<"谪仙（真）套装（40级）">>,suit_num=2,value_type=[{5,160}]};
get_attribute(10242, 4) -> 
	#suit_attribute{suit_id=10242,name= <<"谪仙（真）套装（40级）">>,suit_num=4,value_type=[{5,160},{16,220}]};
get_attribute(10242, 6) -> 
	#suit_attribute{suit_id=10242,name= <<"谪仙（真）套装（40级）">>,suit_num=6,value_type=[{5,160},{16,220},{3,110}]};
get_attribute(10250, 2) -> 
	#suit_attribute{suit_id=10250,name= <<"谪仙套装（50级）">>,suit_num=2,value_type=[{5,160}]};
get_attribute(10250, 4) -> 
	#suit_attribute{suit_id=10250,name= <<"谪仙套装（50级）">>,suit_num=4,value_type=[{5,160},{4,260}]};
get_attribute(10250, 6) -> 
	#suit_attribute{suit_id=10250,name= <<"谪仙套装（50级）">>,suit_num=6,value_type=[{5,160},{4,260},{3,110}]};
get_attribute(10252, 2) -> 
	#suit_attribute{suit_id=10252,name= <<"谪仙（真）套装（50级）">>,suit_num=2,value_type=[{5,188}]};
get_attribute(10252, 4) -> 
	#suit_attribute{suit_id=10252,name= <<"谪仙（真）套装（50级）">>,suit_num=4,value_type=[{5,188},{16,260}]};
get_attribute(10252, 6) -> 
	#suit_attribute{suit_id=10252,name= <<"谪仙（真）套装（50级）">>,suit_num=6,value_type=[{5,188},{16,260},{3,130}]};
get_attribute(10260, 2) -> 
	#suit_attribute{suit_id=10260,name= <<"谪仙套装（60级）">>,suit_num=2,value_type=[{5,188}]};
get_attribute(10260, 4) -> 
	#suit_attribute{suit_id=10260,name= <<"谪仙套装（60级）">>,suit_num=4,value_type=[{5,188},{4,306}]};
get_attribute(10260, 6) -> 
	#suit_attribute{suit_id=10260,name= <<"谪仙套装（60级）">>,suit_num=6,value_type=[{5,188},{4,306},{3,130}]};
get_attribute(10262, 2) -> 
	#suit_attribute{suit_id=10262,name= <<"谪仙（真）套装（60级）">>,suit_num=2,value_type=[{5,221}]};
get_attribute(10262, 4) -> 
	#suit_attribute{suit_id=10262,name= <<"谪仙（真）套装（60级）">>,suit_num=4,value_type=[{5,221},{16,306}]};
get_attribute(10262, 6) -> 
	#suit_attribute{suit_id=10262,name= <<"谪仙（真）套装（60级）">>,suit_num=6,value_type=[{5,221},{16,306},{3,153}]};
get_attribute(10270, 2) -> 
	#suit_attribute{suit_id=10270,name= <<"谪仙套装（70级）">>,suit_num=2,value_type=[{5,221}]};
get_attribute(10270, 4) -> 
	#suit_attribute{suit_id=10270,name= <<"谪仙套装（70级）">>,suit_num=4,value_type=[{5,221},{4,360}]};
get_attribute(10270, 6) -> 
	#suit_attribute{suit_id=10270,name= <<"谪仙套装（70级）">>,suit_num=6,value_type=[{5,221},{4,360},{3,156}]};
get_attribute(10272, 2) -> 
	#suit_attribute{suit_id=10272,name= <<"谪仙（真）套装（70级）">>,suit_num=2,value_type=[{5,260}]};
get_attribute(10272, 4) -> 
	#suit_attribute{suit_id=10272,name= <<"谪仙（真）套装（70级）">>,suit_num=4,value_type=[{5,260},{16,360}]};
get_attribute(10272, 6) -> 
	#suit_attribute{suit_id=10272,name= <<"谪仙（真）套装（70级）">>,suit_num=6,value_type=[{5,260},{16,360},{3,180}]};
get_attribute(10275, 2) -> 
	#suit_attribute{suit_id=10275,name= <<"谪仙·六道套装">>,suit_num=2,value_type=[{5,306}]};
get_attribute(10275, 4) -> 
	#suit_attribute{suit_id=10275,name= <<"谪仙·六道套装">>,suit_num=4,value_type=[{5,306},{16,425}]};
get_attribute(10275, 6) -> 
	#suit_attribute{suit_id=10275,name= <<"谪仙·六道套装">>,suit_num=6,value_type=[{5,306},{16,425},{3,212}]};
get_attribute(10285, 2) -> 
	#suit_attribute{suit_id=10285,name= <<"谪仙·七曜套装">>,suit_num=2,value_type=[{5,360}]};
get_attribute(10285, 4) -> 
	#suit_attribute{suit_id=10285,name= <<"谪仙·七曜套装">>,suit_num=4,value_type=[{5,360},{16,500}]};
get_attribute(10285, 6) -> 
	#suit_attribute{suit_id=10285,name= <<"谪仙·七曜套装">>,suit_num=6,value_type=[{5,360},{16,500},{3,250}]};
get_attribute(30030, 2) -> 
	#suit_attribute{suit_id=30030,name= <<"30级灵魂套装">>,suit_num=2,value_type=[{5,33}]};
get_attribute(30030, 4) -> 
	#suit_attribute{suit_id=30030,name= <<"30级灵魂套装">>,suit_num=4,value_type=[{5,33},{7,15}]};
get_attribute(30030, 6) -> 
	#suit_attribute{suit_id=30030,name= <<"30级灵魂套装">>,suit_num=6,value_type=[{5,33},{7,15},{3,20}]};
get_attribute(30040, 2) -> 
	#suit_attribute{suit_id=30040,name= <<"怒电">>,suit_num=2,value_type=[{5,66}]};
get_attribute(30040, 4) -> 
	#suit_attribute{suit_id=30040,name= <<"怒电">>,suit_num=4,value_type=[{5,66},{7,30}]};
get_attribute(30040, 6) -> 
	#suit_attribute{suit_id=30040,name= <<"怒电">>,suit_num=6,value_type=[{5,66},{7,30},{3,52}]};
get_attribute(30042, 2) -> 
	#suit_attribute{suit_id=30042,name= <<"怒电（真）">>,suit_num=2,value_type=[{5,132}]};
get_attribute(30042, 4) -> 
	#suit_attribute{suit_id=30042,name= <<"怒电（真）">>,suit_num=4,value_type=[{5,132},{7,60}]};
get_attribute(30042, 6) -> 
	#suit_attribute{suit_id=30042,name= <<"怒电（真）">>,suit_num=6,value_type=[{5,132},{7,60},{3,105}]};
get_attribute(30050, 2) -> 
	#suit_attribute{suit_id=30050,name= <<"鉴云">>,suit_num=2,value_type=[{5,78}]};
get_attribute(30050, 4) -> 
	#suit_attribute{suit_id=30050,name= <<"鉴云">>,suit_num=4,value_type=[{5,78},{7,35}]};
get_attribute(30050, 6) -> 
	#suit_attribute{suit_id=30050,name= <<"鉴云">>,suit_num=6,value_type=[{5,78},{7,35},{3,62}]};
get_attribute(30052, 2) -> 
	#suit_attribute{suit_id=30052,name= <<"鉴云（真）">>,suit_num=2,value_type=[{5,156}]};
get_attribute(30052, 4) -> 
	#suit_attribute{suit_id=30052,name= <<"鉴云（真）">>,suit_num=4,value_type=[{5,156},{7,70}]};
get_attribute(30052, 6) -> 
	#suit_attribute{suit_id=30052,name= <<"鉴云（真）">>,suit_num=6,value_type=[{5,156},{7,70},{3,124}]};
get_attribute(30060, 2) -> 
	#suit_attribute{suit_id=30060,name= <<"傲月">>,suit_num=2,value_type=[{5,92}]};
get_attribute(30060, 4) -> 
	#suit_attribute{suit_id=30060,name= <<"傲月">>,suit_num=4,value_type=[{5,92},{7,40}]};
get_attribute(30060, 6) -> 
	#suit_attribute{suit_id=30060,name= <<"傲月">>,suit_num=6,value_type=[{5,92},{7,40},{3,72}]};
get_attribute(30062, 2) -> 
	#suit_attribute{suit_id=30062,name= <<"傲月（真）">>,suit_num=2,value_type=[{5,184}]};
get_attribute(30062, 4) -> 
	#suit_attribute{suit_id=30062,name= <<"傲月（真）">>,suit_num=4,value_type=[{5,184},{7,82}]};
get_attribute(30062, 6) -> 
	#suit_attribute{suit_id=30062,name= <<"傲月（真）">>,suit_num=6,value_type=[{5,184},{7,82},{3,145}]};
get_attribute(30070, 2) -> 
	#suit_attribute{suit_id=30070,name= <<"啸天">>,suit_num=2,value_type=[{5,108}]};
get_attribute(30070, 4) -> 
	#suit_attribute{suit_id=30070,name= <<"啸天">>,suit_num=4,value_type=[{5,108},{7,50}]};
get_attribute(30070, 6) -> 
	#suit_attribute{suit_id=30070,name= <<"啸天">>,suit_num=6,value_type=[{5,108},{7,50},{3,85}]};
get_attribute(30072, 2) -> 
	#suit_attribute{suit_id=30072,name= <<"啸天（真）">>,suit_num=2,value_type=[{5,216}]};
get_attribute(30072, 4) -> 
	#suit_attribute{suit_id=30072,name= <<"啸天（真）">>,suit_num=4,value_type=[{5,216},{7,98}]};
get_attribute(30072, 6) -> 
	#suit_attribute{suit_id=30072,name= <<"啸天（真）">>,suit_num=6,value_type=[{5,216},{7,98},{3,170}]};
get_attribute(30075, 2) -> 
	#suit_attribute{suit_id=30075,name= <<"六道轮回">>,suit_num=2,value_type=[{5,255}]};
get_attribute(30075, 4) -> 
	#suit_attribute{suit_id=30075,name= <<"六道轮回">>,suit_num=4,value_type=[{5,255},{7,116}]};
get_attribute(30075, 6) -> 
	#suit_attribute{suit_id=30075,name= <<"六道轮回">>,suit_num=6,value_type=[{5,255},{7,116},{3,200}]};
get_attribute(30085, 2) -> 
	#suit_attribute{suit_id=30085,name= <<"七曜逐日">>,suit_num=2,value_type=[{5,300}]};
get_attribute(30085, 4) -> 
	#suit_attribute{suit_id=30085,name= <<"七曜逐日">>,suit_num=4,value_type=[{5,300},{7,136}]};
get_attribute(30085, 6) -> 
	#suit_attribute{suit_id=30085,name= <<"七曜逐日">>,suit_num=6,value_type=[{5,300},{7,136},{3,238}]};
get_attribute(_, _) ->
	[].

