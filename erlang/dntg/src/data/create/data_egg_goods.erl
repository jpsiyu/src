%%%---------------------------------------
%%% @Module  : data_egg_goods
%%% @Description : 砸蛋
%%%---------------------------------------
-module(data_egg_goods).
-compile(export_all).
-include("pet.hrl").


get_egg_type(1) -> 
    #pet_egg{egg_type=1,money_type=1,used_price=3000,used_price2=0,cd_time=6000,base_goods=501202,goods_list=[{1,99,[205101,624801,624201,621302,621301,621006,621005,621004,621003,612501,501202,206101,671001]}],save_count=0,save_goods_list=0};

get_egg_type(2) -> 
    #pet_egg{egg_type=2,money_type=1,used_price=6000,used_price2=0,cd_time=12000,base_goods=501202,goods_list=[{1,99,[205101,624801,624201,621303,621302,621301,621007,621006,621005,621004,621003,612501,501202,206101,671001]}],save_count=0,save_goods_list=0};

get_egg_type(3) -> 
    #pet_egg{egg_type=3,money_type=2,used_price=0,used_price2=8,cd_time=0,base_goods=501202,goods_list=[{1,99,[205101,624801,624201,621303,621302,621301,621008,621007,621006,621005,621004,621003,612501,501202,206101,671001]}],save_count=50,save_goods_list=[{621006,90},{621007,10}]};

get_egg_type(_)->
   [].

get_egg_good(205101,1) -> 
    #pet_egg_goods{good_id=205101,egg_type=1,type=0,bind=0,notice=0,rate=40,lim_num=0,lv=[1,99]};

get_egg_good(205101,2) -> 
    #pet_egg_goods{good_id=205101,egg_type=2,type=0,bind=0,notice=0,rate=20,lim_num=0,lv=[1,99]};

get_egg_good(205101,3) -> 
    #pet_egg_goods{good_id=205101,egg_type=3,type=0,bind=1,notice=0,rate=160,lim_num=0,lv=[1,99]};

get_egg_good(206101,1) -> 
    #pet_egg_goods{good_id=206101,egg_type=1,type=0,bind=0,notice=0,rate=40,lim_num=0,lv=[1,99]};

get_egg_good(206101,2) -> 
    #pet_egg_goods{good_id=206101,egg_type=2,type=0,bind=0,notice=0,rate=20,lim_num=0,lv=[1,99]};

get_egg_good(206101,3) -> 
    #pet_egg_goods{good_id=206101,egg_type=3,type=0,bind=1,notice=0,rate=160,lim_num=0,lv=[1,99]};

get_egg_good(501202,1) -> 
    #pet_egg_goods{good_id=501202,egg_type=1,type=0,bind=0,notice=0,rate=50,lim_num=0,lv=[1,99]};

get_egg_good(501202,2) -> 
    #pet_egg_goods{good_id=501202,egg_type=2,type=0,bind=0,notice=0,rate=30,lim_num=0,lv=[1,99]};

get_egg_good(501202,3) -> 
    #pet_egg_goods{good_id=501202,egg_type=3,type=0,bind=1,notice=0,rate=200,lim_num=0,lv=[1,99]};

get_egg_good(612501,1) -> 
    #pet_egg_goods{good_id=612501,egg_type=1,type=0,bind=0,notice=0,rate=50,lim_num=0,lv=[1,99]};

get_egg_good(612501,2) -> 
    #pet_egg_goods{good_id=612501,egg_type=2,type=0,bind=0,notice=0,rate=30,lim_num=0,lv=[1,99]};

get_egg_good(612501,3) -> 
    #pet_egg_goods{good_id=612501,egg_type=3,type=0,bind=1,notice=0,rate=200,lim_num=0,lv=[1,99]};

get_egg_good(621003,1) -> 
    #pet_egg_goods{good_id=621003,egg_type=1,type=0,bind=0,notice=0,rate=100,lim_num=0,lv=[1,99]};

get_egg_good(621003,2) -> 
    #pet_egg_goods{good_id=621003,egg_type=2,type=0,bind=0,notice=0,rate=40,lim_num=0,lv=[1,99]};

get_egg_good(621003,3) -> 
    #pet_egg_goods{good_id=621003,egg_type=3,type=0,bind=1,notice=0,rate=0,lim_num=0,lv=[1,99]};

get_egg_good(621004,1) -> 
    #pet_egg_goods{good_id=621004,egg_type=1,type=0,bind=0,notice=0,rate=50,lim_num=0,lv=[1,99]};

get_egg_good(621004,2) -> 
    #pet_egg_goods{good_id=621004,egg_type=2,type=0,bind=0,notice=0,rate=40,lim_num=0,lv=[1,99]};

get_egg_good(621004,3) -> 
    #pet_egg_goods{good_id=621004,egg_type=3,type=0,bind=1,notice=0,rate=0,lim_num=0,lv=[1,99]};

get_egg_good(621005,1) -> 
    #pet_egg_goods{good_id=621005,egg_type=1,type=0,bind=0,notice=0,rate=25,lim_num=0,lv=[1,99]};

get_egg_good(621005,2) -> 
    #pet_egg_goods{good_id=621005,egg_type=2,type=0,bind=0,notice=0,rate=20,lim_num=0,lv=[1,99]};

get_egg_good(621005,3) -> 
    #pet_egg_goods{good_id=621005,egg_type=3,type=0,bind=1,notice=0,rate=120,lim_num=0,lv=[1,99]};

get_egg_good(621006,1) -> 
    #pet_egg_goods{good_id=621006,egg_type=1,type=1,bind=0,notice=1,rate=5,lim_num=20,lv=[1,99]};

get_egg_good(621006,2) -> 
    #pet_egg_goods{good_id=621006,egg_type=2,type=1,bind=0,notice=1,rate=5,lim_num=20,lv=[1,99]};

get_egg_good(621006,3) -> 
    #pet_egg_goods{good_id=621006,egg_type=3,type=1,bind=1,notice=1,rate=40,lim_num=10,lv=[1,99]};

get_egg_good(621007,2) -> 
    #pet_egg_goods{good_id=621007,egg_type=2,type=1,bind=0,notice=1,rate=2,lim_num=40,lv=[1,99]};

get_egg_good(621007,3) -> 
    #pet_egg_goods{good_id=621007,egg_type=3,type=1,bind=1,notice=1,rate=10,lim_num=30,lv=[1,99]};

get_egg_good(621008,3) -> 
    #pet_egg_goods{good_id=621008,egg_type=3,type=1,bind=1,notice=1,rate=1,lim_num=50,lv=[1,99]};

get_egg_good(621301,1) -> 
    #pet_egg_goods{good_id=621301,egg_type=1,type=0,bind=0,notice=0,rate=80,lim_num=0,lv=[1,99]};

get_egg_good(621301,2) -> 
    #pet_egg_goods{good_id=621301,egg_type=2,type=0,bind=0,notice=0,rate=40,lim_num=0,lv=[1,99]};

get_egg_good(621301,3) -> 
    #pet_egg_goods{good_id=621301,egg_type=3,type=0,bind=1,notice=0,rate=160,lim_num=0,lv=[1,99]};

get_egg_good(621302,1) -> 
    #pet_egg_goods{good_id=621302,egg_type=1,type=0,bind=0,notice=0,rate=20,lim_num=5,lv=[1,99]};

get_egg_good(621302,2) -> 
    #pet_egg_goods{good_id=621302,egg_type=2,type=0,bind=0,notice=0,rate=15,lim_num=0,lv=[1,99]};

get_egg_good(621302,3) -> 
    #pet_egg_goods{good_id=621302,egg_type=3,type=0,bind=1,notice=0,rate=60,lim_num=0,lv=[1,99]};

get_egg_good(621303,2) -> 
    #pet_egg_goods{good_id=621303,egg_type=2,type=1,bind=0,notice=1,rate=5,lim_num=10,lv=[1,99]};

get_egg_good(621303,3) -> 
    #pet_egg_goods{good_id=621303,egg_type=3,type=1,bind=1,notice=1,rate=40,lim_num=5,lv=[1,99]};

get_egg_good(624201,1) -> 
    #pet_egg_goods{good_id=624201,egg_type=1,type=0,bind=0,notice=0,rate=20,lim_num=5,lv=[1,99]};

get_egg_good(624201,2) -> 
    #pet_egg_goods{good_id=624201,egg_type=2,type=0,bind=0,notice=0,rate=60,lim_num=5,lv=[1,99]};

get_egg_good(624201,3) -> 
    #pet_egg_goods{good_id=624201,egg_type=3,type=0,bind=1,notice=0,rate=200,lim_num=0,lv=[1,99]};

get_egg_good(624801,1) -> 
    #pet_egg_goods{good_id=624801,egg_type=1,type=0,bind=0,notice=0,rate=20,lim_num=5,lv=[1,99]};

get_egg_good(624801,2) -> 
    #pet_egg_goods{good_id=624801,egg_type=2,type=0,bind=0,notice=0,rate=60,lim_num=5,lv=[1,99]};

get_egg_good(624801,3) -> 
    #pet_egg_goods{good_id=624801,egg_type=3,type=0,bind=1,notice=0,rate=200,lim_num=0,lv=[1,99]};

get_egg_good(671001,1) -> 
    #pet_egg_goods{good_id=671001,egg_type=1,type=0,bind=0,notice=0,rate=40,lim_num=0,lv=[1,99]};

get_egg_good(671001,2) -> 
    #pet_egg_goods{good_id=671001,egg_type=2,type=0,bind=0,notice=0,rate=15,lim_num=0,lv=[1,99]};

get_egg_good(671001,3) -> 
    #pet_egg_goods{good_id=671001,egg_type=3,type=0,bind=1,notice=0,rate=120,lim_num=0,lv=[1,99]};

get_egg_good(_GoodId, _Type) -> [].

