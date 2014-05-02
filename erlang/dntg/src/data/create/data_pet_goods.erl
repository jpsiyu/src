%%%---------------------------------------
%%% @Module  : data_pet_goods
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:28
%%% @Description:  宠物相关
%%%---------------------------------------
-module(data_pet_goods).
-export([get/1]).
-include("pet.hrl").

%%通过id获取记录
get(621000) -> 
	#base_goods_pet{id=621000,name= <<"狐小倩">>,base_aptitude=700,extra_aptitude_max=799,aptitude_ratio=[{700,730,400},{731,750,250},{751,760,200},{761,770,100},{771,780,30},{781,790,15},{791,799,5}],growth_min=0,growth_max=80,effect=2,probability=0,sell=0,type=62,subtype=10,color=3,price=2500,level=0,expire_time=0};


get(621001) -> 
	#base_goods_pet{id=621001,name= <<"胖胖猫">>,base_aptitude=301,extra_aptitude_max=500,aptitude_ratio=[{300,500,1000}],growth_min=0,growth_max=80,effect=1,probability=0,sell=0,type=62,subtype=10,color=0,price=50000,level=0,expire_time=0};


get(621002) -> 
	#base_goods_pet{id=621002,name= <<"萌悟空">>,base_aptitude=700,extra_aptitude_max=799,aptitude_ratio=[{700,730,200},{731,750,300},{751,760,400},{761,770,60},{771,780,25},{781,790,10},{791,799,5}],growth_min=0,growth_max=80,effect=3,probability=0,sell=0,type=62,subtype=10,color=3,price=50000,level=0,expire_time=0};


get(621003) -> 
	#base_goods_pet{id=621003,name= <<"胖胖猫">>,base_aptitude=301,extra_aptitude_max=550,aptitude_ratio=[{301,550,1000}],growth_min=0,growth_max=80,effect=1,probability=0,sell=0,type=62,subtype=10,color=0,price=50000,level=0,expire_time=0};


get(621004) -> 
	#base_goods_pet{id=621004,name= <<"胖胖猫">>,base_aptitude=401,extra_aptitude_max=600,aptitude_ratio=[{401,600,1000}],growth_min=0,growth_max=80,effect=1,probability=0,sell=0,type=62,subtype=10,color=1,price=50000,level=0,expire_time=0};


get(621005) -> 
	#base_goods_pet{id=621005,name= <<"胖胖猫">>,base_aptitude=501,extra_aptitude_max=650,aptitude_ratio=[{501,650,1000}],growth_min=0,growth_max=80,effect=1,probability=0,sell=0,type=62,subtype=10,color=2,price=50000,level=0,expire_time=0};


get(621006) -> 
	#base_goods_pet{id=621006,name= <<"胖胖猫">>,base_aptitude=601,extra_aptitude_max=700,aptitude_ratio=[{601,700,1000}],growth_min=0,growth_max=80,effect=1,probability=0,sell=0,type=62,subtype=10,color=3,price=50000,level=0,expire_time=0};


get(621007) -> 
	#base_goods_pet{id=621007,name= <<"胖胖猫">>,base_aptitude=681,extra_aptitude_max=750,aptitude_ratio=[{681,750,1000}],growth_min=0,growth_max=80,effect=1,probability=0,sell=0,type=62,subtype=10,color=3,price=50000,level=0,expire_time=0};


get(621008) -> 
	#base_goods_pet{id=621008,name= <<"小天蓬">>,base_aptitude=650,extra_aptitude_max=770,aptitude_ratio=[{650,700,300},{701,710,200},{711,720,200},{721,740,150},{741,760,100},{761,770,50}],growth_min=0,growth_max=80,effect=4,probability=0,sell=0,type=62,subtype=10,color=3,price=50000,level=0,expire_time=0};


get(621013) -> 
	#base_goods_pet{id=621013,name= <<"小飞龙">>,base_aptitude=700,extra_aptitude_max=799,aptitude_ratio=[{700,730,300},{731,750,300},{751,760,220},{761,770,120},{771,780,30},{781,790,20},{791,799,10}],growth_min=0,growth_max=80,effect=5,probability=0,sell=0,type=62,subtype=10,color=0,price=0,level=0,expire_time=0};


get(621101) -> 
	#base_goods_pet{id=621101,name= <<"资质符">>,base_aptitude=0,extra_aptitude_max=0,aptitude_ratio=[{1,60},{2,30},{3,10}],growth_min=0,growth_max=0,effect=0,probability=0,sell=0,type=62,subtype=11,color=3,price=0,level=0,expire_time=0};


get(621301) -> 
	#base_goods_pet{id=621301,name= <<"小型宠物口粮">>,base_aptitude=0,extra_aptitude_max=0,aptitude_ratio=0,growth_min=0,growth_max=0,effect=30,probability=0,sell=0,type=62,subtype=13,color=0,price=10,level=0,expire_time=0};


get(621302) -> 
	#base_goods_pet{id=621302,name= <<"中型宠物口粮">>,base_aptitude=0,extra_aptitude_max=0,aptitude_ratio=0,growth_min=0,growth_max=0,effect=75,probability=0,sell=0,type=62,subtype=13,color=1,price=100,level=0,expire_time=0};


get(621303) -> 
	#base_goods_pet{id=621303,name= <<"大型宠物口粮">>,base_aptitude=0,extra_aptitude_max=0,aptitude_ratio=0,growth_min=0,growth_max=0,effect=150,probability=0,sell=0,type=62,subtype=13,color=2,price=250,level=0,expire_time=0};


get(623001) -> 
	#base_goods_pet{id=623001,name= <<"小型宠物经验丹">>,base_aptitude=0,extra_aptitude_max=0,aptitude_ratio=0,growth_min=0,growth_max=0,effect=2000,probability=0,sell=0,type=62,subtype=30,color=1,price=0,level=0,expire_time=0};


get(623002) -> 
	#base_goods_pet{id=623002,name= <<"中型宠物经验丹">>,base_aptitude=0,extra_aptitude_max=0,aptitude_ratio=0,growth_min=0,growth_max=0,effect=4000,probability=0,sell=0,type=62,subtype=30,color=2,price=0,level=0,expire_time=0};


get(623003) -> 
	#base_goods_pet{id=623003,name= <<"大型宠物经验丹">>,base_aptitude=0,extra_aptitude_max=0,aptitude_ratio=0,growth_min=0,growth_max=0,effect=8000,probability=0,sell=0,type=62,subtype=30,color=3,price=0,level=0,expire_time=0};


get(623004) -> 
	#base_goods_pet{id=623004,name= <<"巨型宠物经验丹">>,base_aptitude=0,extra_aptitude_max=0,aptitude_ratio=0,growth_min=0,growth_max=0,effect=16000,probability=0,sell=0,type=62,subtype=30,color=4,price=0,level=0,expire_time=0};


get(_) ->
	[].

