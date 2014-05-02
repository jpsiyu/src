%%%---------------------------------------
%%% @Module  : data_designation
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:28
%%% @Description:  称号相关
%%%---------------------------------------
-module(data_designation).
-compile(export_all).
-include("designation.hrl").

%%通过id获取记录
get_by_id(200101) -> 
	#designation{id=200101,type=1,name= <<"斗战胜佛">>,describe= <<"战力排行第1名">>,sex_limit=-1,display=1,notice=1,att=50,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=1,time_limit=0,overlying=1};
get_by_id(200102) -> 
	#designation{id=200102,type=1,name= <<"斗破苍穹">>,describe= <<"战力排行第2-10名">>,sex_limit=-1,display=1,notice=0,att=30,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(200301) -> 
	#designation{id=200301,type=1,name= <<"独孤求败">>,describe= <<"声望排行第1名">>,sex_limit=-1,display=1,notice=1,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=45,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=1,time_limit=0,overlying=0};
get_by_id(200302) -> 
	#designation{id=200302,type=1,name= <<"笑傲仙凡">>,describe= <<"声望排行第2-10名">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=27,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(200401) -> 
	#designation{id=200401,type=1,name= <<"纵横无敌">>,describe= <<"竞技场每周积分第1名">>,sex_limit=-1,display=1,notice=1,att=35,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=1,time_limit=0,overlying=0};
get_by_id(200402) -> 
	#designation{id=200402,type=1,name= <<"叱咤疆场">>,describe= <<"竞技场每周积分第2-10名">>,sex_limit=-1,display=1,notice=0,att=20,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(200601) -> 
	#designation{id=200601,type=1,name= <<"西游第一">>,describe= <<"等级排行第1名">>,sex_limit=-1,display=1,notice=1,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=72,dodge=60,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=1,time_limit=0,overlying=0};
get_by_id(200602) -> 
	#designation{id=200602,type=1,name= <<"绝顶高手">>,describe= <<"等级排行第2-10名">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=43,dodge=36,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(200701) -> 
	#designation{id=200701,type=1,name= <<"富甲天下">>,describe= <<"财富排行第1名">>,sex_limit=-1,display=1,notice=1,att=0,def=90,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=1,time_limit=0,overlying=0};
get_by_id(200702) -> 
	#designation{id=200702,type=1,name= <<"腰缠万贯">>,describe= <<"财富排行第2-10名">>,sex_limit=-1,display=1,notice=0,att=0,def=60,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201409) -> 
	#designation{id=201409,type=1,name= <<"天下无敌">>,describe= <<"竞技场积分第一">>,sex_limit=-1,display=1,notice=1,att=23,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=1,time_limit=0,overlying=0};
get_by_id(201502) -> 
	#designation{id=201502,type=1,name= <<"新手指导员">>,describe= <<"系统指定的指导员，有无数惊喜的哦">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=1};
get_by_id(201503) -> 
	#designation{id=201503,type=1,name= <<"称霸天下">>,describe= <<"帮派战中获得第一的帮派，帮主可获得此称号">>,sex_limit=-1,display=1,notice=1,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=50,dodge=52,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=1,time_limit=0,overlying=1};
get_by_id(201651) -> 
	#designation{id=201651,type=1,name= <<"帮战称雄">>,describe= <<"帮派战中获得第一的帮派，帮众可获得此称号">>,sex_limit=-1,display=1,notice=1,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=42,dodge=36,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201701) -> 
	#designation{id=201701,type=2,name= <<"不差钱">>,describe= <<"完成“西游巨富（3）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201702) -> 
	#designation{id=201702,type=2,name= <<"奉旨杀人">>,describe= <<"完成“奉旨杀人（3）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201703) -> 
	#designation{id=201703,type=2,name= <<"西游小仙">>,describe= <<"完成“漫漫西行路（1）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201705) -> 
	#designation{id=201705,type=2,name= <<"仙侣奇缘">>,describe= <<"完成“仙侣奇缘（1）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201706) -> 
	#designation{id=201706,type=2,name= <<"时髦神装">>,describe= <<"完成“时髦神装（2）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201707) -> 
	#designation{id=201707,type=2,name= <<"碎片达人">>,describe= <<"完成“碎片达人（1）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201708) -> 
	#designation{id=201708,type=2,name= <<"红得发紫">>,describe= <<"完成“红得发紫（1）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201709) -> 
	#designation{id=201709,type=2,name= <<"六道轮回">>,describe= <<"完成“六道轮回”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201710) -> 
	#designation{id=201710,type=2,name= <<"石头记">>,describe= <<"完成“石头记（1）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201711) -> 
	#designation{id=201711,type=2,name= <<"洗刷刷">>,describe= <<"完成“我爱洗刷（1）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201712) -> 
	#designation{id=201712,type=2,name= <<"杀生成仁">>,describe= <<"完成“杀生成仁（1）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201713) -> 
	#designation{id=201713,type=2,name= <<"闯天路">>,describe= <<"完成“闯天路（5）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201715) -> 
	#designation{id=201715,type=2,name= <<"相知满天下">>,describe= <<"完成“高朋满座（3）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201717) -> 
	#designation{id=201717,type=2,name= <<"盗圣">>,describe= <<"完成“盗圣（3）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201718) -> 
	#designation{id=201718,type=2,name= <<"碎石之痛">>,describe= <<"完成“心痛感觉（2）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201719) -> 
	#designation{id=201719,type=2,name= <<"漫漫强化路">>,describe= <<"完成“强化之殇（1）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201720) -> 
	#designation{id=201720,type=2,name= <<"刀剑无眼">>,describe= <<"完成“刀剑无眼（1）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201721) -> 
	#designation{id=201721,type=2,name= <<"帮主，他打我！">>,describe= <<"完成“帮主，他打我！（1）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201722) -> 
	#designation{id=201722,type=2,name= <<"地上真凉">>,describe= <<"完成“地上很凉（1）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201723) -> 
	#designation{id=201723,type=2,name= <<"捣蛋专家">>,describe= <<"完成“沙滩捣蛋鬼（3）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201724) -> 
	#designation{id=201724,type=2,name= <<"我晕晕晕">>,describe= <<"完成“被锤晕啦！（3）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201725) -> 
	#designation{id=201725,type=2,name= <<"我是财神">>,describe= <<"完成“西游巨富（5）”成就可获得此称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201801) -> 
	#designation{id=201801,type=3,name= "~s的相公",describe= <<"结婚啦！向世界宣布你的归属吧！">>,sex_limit=1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201802) -> 
	#designation{id=201802,type=3,name= "~s的娘子",describe= <<"结婚啦！向世界宣布你的归属吧！">>,sex_limit=0,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201803) -> 
	#designation{id=201803,type=3,name= "~s的帮主",describe= <<"俺可是帮主哦，帮主哦！">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201804) -> 
	#designation{id=201804,type=3,name= "~s的副帮主",describe= <<"副帮主啦，别叫我帮主，会不好意思的">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201805) -> 
	#designation{id=201805,type=3,name= "~s的长老",describe= <<"帮派长老，帮派的核心力量">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(201806) -> 
	#designation{id=201806,type=3,name= "~s的帮众",describe= <<"我可是代表广大仙友的哦">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203001) -> 
	#designation{id=203001,type=5,name= <<"斩妖一层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203002) -> 
	#designation{id=203002,type=5,name= <<"斩妖二层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203003) -> 
	#designation{id=203003,type=5,name= <<"斩妖三层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203004) -> 
	#designation{id=203004,type=5,name= <<"斩妖四层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203005) -> 
	#designation{id=203005,type=5,name= <<"斩妖五层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203006) -> 
	#designation{id=203006,type=5,name= <<"斩妖六层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203007) -> 
	#designation{id=203007,type=5,name= <<"斩妖七层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203008) -> 
	#designation{id=203008,type=5,name= <<"斩妖八层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203009) -> 
	#designation{id=203009,type=5,name= <<"除魔一层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203010) -> 
	#designation{id=203010,type=5,name= <<"除魔二层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203011) -> 
	#designation{id=203011,type=5,name= <<"除魔三层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203012) -> 
	#designation{id=203012,type=5,name= <<"除魔四层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203013) -> 
	#designation{id=203013,type=5,name= <<"除魔五层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203014) -> 
	#designation{id=203014,type=5,name= <<"除魔六层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203015) -> 
	#designation{id=203015,type=5,name= <<"除魔七层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203016) -> 
	#designation{id=203016,type=5,name= <<"除魔八层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203017) -> 
	#designation{id=203017,type=5,name= <<"谪仙一层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203018) -> 
	#designation{id=203018,type=5,name= <<"谪仙二层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203019) -> 
	#designation{id=203019,type=5,name= <<"谪仙三层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203020) -> 
	#designation{id=203020,type=5,name= <<"谪仙四层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203021) -> 
	#designation{id=203021,type=5,name= <<"谪仙五层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203022) -> 
	#designation{id=203022,type=5,name= <<"谪仙六层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203023) -> 
	#designation{id=203023,type=5,name= <<"谪仙七层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203024) -> 
	#designation{id=203024,type=5,name= <<"谪仙八层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203025) -> 
	#designation{id=203025,type=5,name= <<"诛神一层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203026) -> 
	#designation{id=203026,type=5,name= <<"诛神二层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203027) -> 
	#designation{id=203027,type=5,name= <<"诛神三层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203028) -> 
	#designation{id=203028,type=5,name= <<"诛神四层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203029) -> 
	#designation{id=203029,type=5,name= <<"诛神五层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203030) -> 
	#designation{id=203030,type=5,name= <<"诛神六层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203031) -> 
	#designation{id=203031,type=5,name= <<"诛神七层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(203032) -> 
	#designation{id=203032,type=5,name= <<"诛神八层">>,describe= <<"三星评价通关封魔对应副本可获此封魔称号">>,sex_limit=-1,display=1,notice=0,att=0,def=0,hp=0,mp=0,forza=0,agile=0,wit=0,hit=0,dodge=0,crit=0,ten=0,res=0,thew=0,addbase=0,fire=0,ice=0,drug=0,onlyone=0,time_limit=0,overlying=0};
get_by_id(_) ->
	[].

%% 最多可显示称号个数
get_max_show_num() -> 2.

%% 最多可显示的炫耀称号个数
get_max_flaunt_num() -> 2.

