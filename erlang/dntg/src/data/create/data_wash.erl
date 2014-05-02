%%%---------------------------------------
%%% @Module  : data_wash
%%% @Description : 洗炼配置
%%%---------------------------------------
-module(data_wash).
-compile(export_all).
-include("goods.hrl").


get_wash_rule(1) -> 
    #ets_wash_rule{level=1,coin=1000,num=3};

get_wash_rule(2) -> 
    #ets_wash_rule{level=2,coin=2000,num=3};

get_wash_rule(3) -> 
    #ets_wash_rule{level=3,coin=3000,num=3};

get_wash_rule(_Level) ->
    [].


get_wash_attribute_type(10) -> 
    #ets_wash_attribute_type{type=10,type_list=[{5,3},{18,5},{18,7},{8,1},{6,2},{15,13},{15,14},{15,15}]};
get_wash_attribute_type(20) -> 
    #ets_wash_attribute_type{type=20,type_list=[{12,4},{12,6},{14,8},{8,1},{6,2},{16,13},{16,14},{16,15}]};
get_wash_attribute_type(21) -> 
    #ets_wash_attribute_type{type=21,type_list=[{12,4},{12,6},{14,8},{8,1},{6,2},{16,13},{16,14},{16,15}]};
get_wash_attribute_type(22) -> 
    #ets_wash_attribute_type{type=22,type_list=[{12,4},{12,6},{14,8},{8,1},{6,2},{16,13},{16,14},{16,15}]};
get_wash_attribute_type(23) -> 
    #ets_wash_attribute_type{type=23,type_list=[{12,4},{12,6},{14,8},{8,1},{6,2},{16,13},{16,14},{16,15}]};
get_wash_attribute_type(24) -> 
    #ets_wash_attribute_type{type=24,type_list=[{12,4},{12,6},{14,8},{8,1},{6,2},{16,13},{16,14},{16,15}]};
get_wash_attribute_type(25) -> 
    #ets_wash_attribute_type{type=25,type_list=[{12,4},{12,6},{14,8},{8,1},{6,2},{16,13},{16,14},{16,15}]};
get_wash_attribute_type(30) -> 
    #ets_wash_attribute_type{type=30,type_list=[{12,4},{12,6},{14,8},{8,1},{6,2},{16,13},{16,14},{16,15}]};
get_wash_attribute_type(32) -> 
    #ets_wash_attribute_type{type=32,type_list=[{5,3},{18,5},{18,7},{8,1},{6,2},{15,13},{15,14},{15,15}]};
get_wash_attribute_type(33) -> 
    #ets_wash_attribute_type{type=33,type_list=[{5,3},{18,5},{18,7},{8,1},{6,2},{15,13},{15,14},{15,15}]};
get_wash_attribute_type(_) ->
    [].


get_wash_star(1) -> 
    #ets_wash_star{level=1,star_list=[{895, 3},{850,4},{820,5},{770,6},{730,7},{690,8},{650,9},{610,10},{570,11},{530,12},{490,13},{450,14},{400,15},{350,16},{300,17},{250,18},{200,19},{150,20},{100,21},{70,22},{55,23},{40,24},{30,25}]};
get_wash_star(2) -> 
    #ets_wash_star{level=2,star_list=[{895, 7},{855,8},{805,9},{760,10},{710,11},{665,12},{615,13},{570,14},{525,15},{480,16},{435,17},{390,18},{345,19},{300,20},{241,21},{220,22},{200,23},{180,24},{160,25},{140,26},{120,27},{100,28},{80,29},{60,30},{38,31},{33,32},{30,33},{26,34},{23,35}]};
get_wash_star(3) -> 
    #ets_wash_star{level=3,star_list=[{770, 10},{732,11},{697,12},{658,13},{624,14},{590,15},{556,16},{522,17},{488,18},{456,19},{424,20},{392,21},{360,22},{328,23},{296,24},{264,25},{232,26},{200,27},{160,28},{150,29},{140,30},{130,31},{120,32},{110,33},{100,34},{90,35},{80,36},{70,37},{60,38},{50,39},{32,40},{29,41},{26,42},{23,43},{21,44},{20,45}]};
get_wash_star(_) -> [].



get_wash_value(1,1,3) -> 
    #ets_wash_value{level=1,type=1,star=3,value=96};
get_wash_value(1,2,3) -> 
    #ets_wash_value{level=1,type=2,star=3,value=12};
get_wash_value(1,3,3) -> 
    #ets_wash_value{level=1,type=3,star=3,value=9};
get_wash_value(1,4,3) -> 
    #ets_wash_value{level=1,type=4,star=3,value=15};
get_wash_value(1,5,3) -> 
    #ets_wash_value{level=1,type=5,star=3,value=12};
get_wash_value(1,6,3) -> 
    #ets_wash_value{level=1,type=6,star=3,value=12};
get_wash_value(1,7,3) -> 
    #ets_wash_value{level=1,type=7,star=3,value=3};
get_wash_value(1,8,3) -> 
    #ets_wash_value{level=1,type=8,star=3,value=9};
get_wash_value(1,13,3) -> 
    #ets_wash_value{level=1,type=13,star=3,value=36};
get_wash_value(1,14,3) -> 
    #ets_wash_value{level=1,type=14,star=3,value=36};
get_wash_value(1,15,3) -> 
    #ets_wash_value{level=1,type=15,star=3,value=36};
get_wash_value(1,1,4) -> 
    #ets_wash_value{level=1,type=1,star=4,value=128};
get_wash_value(1,2,4) -> 
    #ets_wash_value{level=1,type=2,star=4,value=16};
get_wash_value(1,3,4) -> 
    #ets_wash_value{level=1,type=3,star=4,value=12};
get_wash_value(1,4,4) -> 
    #ets_wash_value{level=1,type=4,star=4,value=20};
get_wash_value(1,5,4) -> 
    #ets_wash_value{level=1,type=5,star=4,value=16};
get_wash_value(1,6,4) -> 
    #ets_wash_value{level=1,type=6,star=4,value=16};
get_wash_value(1,7,4) -> 
    #ets_wash_value{level=1,type=7,star=4,value=4};
get_wash_value(1,8,4) -> 
    #ets_wash_value{level=1,type=8,star=4,value=12};
get_wash_value(1,13,4) -> 
    #ets_wash_value{level=1,type=13,star=4,value=48};
get_wash_value(1,14,4) -> 
    #ets_wash_value{level=1,type=14,star=4,value=48};
get_wash_value(1,15,4) -> 
    #ets_wash_value{level=1,type=15,star=4,value=48};
get_wash_value(1,1,5) -> 
    #ets_wash_value{level=1,type=1,star=5,value=160};
get_wash_value(1,2,5) -> 
    #ets_wash_value{level=1,type=2,star=5,value=20};
get_wash_value(1,3,5) -> 
    #ets_wash_value{level=1,type=3,star=5,value=15};
get_wash_value(1,4,5) -> 
    #ets_wash_value{level=1,type=4,star=5,value=25};
get_wash_value(1,5,5) -> 
    #ets_wash_value{level=1,type=5,star=5,value=20};
get_wash_value(1,6,5) -> 
    #ets_wash_value{level=1,type=6,star=5,value=20};
get_wash_value(1,7,5) -> 
    #ets_wash_value{level=1,type=7,star=5,value=5};
get_wash_value(1,8,5) -> 
    #ets_wash_value{level=1,type=8,star=5,value=15};
get_wash_value(1,13,5) -> 
    #ets_wash_value{level=1,type=13,star=5,value=60};
get_wash_value(1,14,5) -> 
    #ets_wash_value{level=1,type=14,star=5,value=60};
get_wash_value(1,15,5) -> 
    #ets_wash_value{level=1,type=15,star=5,value=60};
get_wash_value(1,1,6) -> 
    #ets_wash_value{level=1,type=1,star=6,value=192};
get_wash_value(1,2,6) -> 
    #ets_wash_value{level=1,type=2,star=6,value=24};
get_wash_value(1,3,6) -> 
    #ets_wash_value{level=1,type=3,star=6,value=18};
get_wash_value(1,4,6) -> 
    #ets_wash_value{level=1,type=4,star=6,value=30};
get_wash_value(1,5,6) -> 
    #ets_wash_value{level=1,type=5,star=6,value=24};
get_wash_value(1,6,6) -> 
    #ets_wash_value{level=1,type=6,star=6,value=24};
get_wash_value(1,7,6) -> 
    #ets_wash_value{level=1,type=7,star=6,value=6};
get_wash_value(1,8,6) -> 
    #ets_wash_value{level=1,type=8,star=6,value=18};
get_wash_value(1,13,6) -> 
    #ets_wash_value{level=1,type=13,star=6,value=72};
get_wash_value(1,14,6) -> 
    #ets_wash_value{level=1,type=14,star=6,value=72};
get_wash_value(1,15,6) -> 
    #ets_wash_value{level=1,type=15,star=6,value=72};
get_wash_value(1,1,7) -> 
    #ets_wash_value{level=1,type=1,star=7,value=224};
get_wash_value(2,1,7) -> 
    #ets_wash_value{level=2,type=1,star=7,value=224};
get_wash_value(1,2,7) -> 
    #ets_wash_value{level=1,type=2,star=7,value=28};
get_wash_value(2,2,7) -> 
    #ets_wash_value{level=2,type=2,star=7,value=28};
get_wash_value(1,3,7) -> 
    #ets_wash_value{level=1,type=3,star=7,value=21};
get_wash_value(2,3,7) -> 
    #ets_wash_value{level=2,type=3,star=7,value=21};
get_wash_value(1,4,7) -> 
    #ets_wash_value{level=1,type=4,star=7,value=35};
get_wash_value(2,4,7) -> 
    #ets_wash_value{level=2,type=4,star=7,value=35};
get_wash_value(1,5,7) -> 
    #ets_wash_value{level=1,type=5,star=7,value=28};
get_wash_value(2,5,7) -> 
    #ets_wash_value{level=2,type=5,star=7,value=28};
get_wash_value(1,6,7) -> 
    #ets_wash_value{level=1,type=6,star=7,value=28};
get_wash_value(2,6,7) -> 
    #ets_wash_value{level=2,type=6,star=7,value=28};
get_wash_value(1,7,7) -> 
    #ets_wash_value{level=1,type=7,star=7,value=7};
get_wash_value(2,7,7) -> 
    #ets_wash_value{level=2,type=7,star=7,value=7};
get_wash_value(1,8,7) -> 
    #ets_wash_value{level=1,type=8,star=7,value=21};
get_wash_value(2,8,7) -> 
    #ets_wash_value{level=2,type=8,star=7,value=21};
get_wash_value(1,13,7) -> 
    #ets_wash_value{level=1,type=13,star=7,value=84};
get_wash_value(2,13,7) -> 
    #ets_wash_value{level=2,type=13,star=7,value=84};
get_wash_value(1,14,7) -> 
    #ets_wash_value{level=1,type=14,star=7,value=84};
get_wash_value(2,14,7) -> 
    #ets_wash_value{level=2,type=14,star=7,value=84};
get_wash_value(1,15,7) -> 
    #ets_wash_value{level=1,type=15,star=7,value=84};
get_wash_value(2,15,7) -> 
    #ets_wash_value{level=2,type=15,star=7,value=84};
get_wash_value(1,1,8) -> 
    #ets_wash_value{level=1,type=1,star=8,value=256};
get_wash_value(2,1,8) -> 
    #ets_wash_value{level=2,type=1,star=8,value=256};
get_wash_value(1,2,8) -> 
    #ets_wash_value{level=1,type=2,star=8,value=32};
get_wash_value(2,2,8) -> 
    #ets_wash_value{level=2,type=2,star=8,value=32};
get_wash_value(1,3,8) -> 
    #ets_wash_value{level=1,type=3,star=8,value=24};
get_wash_value(2,3,8) -> 
    #ets_wash_value{level=2,type=3,star=8,value=24};
get_wash_value(1,4,8) -> 
    #ets_wash_value{level=1,type=4,star=8,value=40};
get_wash_value(2,4,8) -> 
    #ets_wash_value{level=2,type=4,star=8,value=40};
get_wash_value(1,5,8) -> 
    #ets_wash_value{level=1,type=5,star=8,value=32};
get_wash_value(2,5,8) -> 
    #ets_wash_value{level=2,type=5,star=8,value=32};
get_wash_value(1,6,8) -> 
    #ets_wash_value{level=1,type=6,star=8,value=32};
get_wash_value(2,6,8) -> 
    #ets_wash_value{level=2,type=6,star=8,value=32};
get_wash_value(1,7,8) -> 
    #ets_wash_value{level=1,type=7,star=8,value=8};
get_wash_value(2,7,8) -> 
    #ets_wash_value{level=2,type=7,star=8,value=8};
get_wash_value(1,8,8) -> 
    #ets_wash_value{level=1,type=8,star=8,value=24};
get_wash_value(2,8,8) -> 
    #ets_wash_value{level=2,type=8,star=8,value=24};
get_wash_value(1,13,8) -> 
    #ets_wash_value{level=1,type=13,star=8,value=96};
get_wash_value(2,13,8) -> 
    #ets_wash_value{level=2,type=13,star=8,value=96};
get_wash_value(1,14,8) -> 
    #ets_wash_value{level=1,type=14,star=8,value=96};
get_wash_value(2,14,8) -> 
    #ets_wash_value{level=2,type=14,star=8,value=96};
get_wash_value(1,15,8) -> 
    #ets_wash_value{level=1,type=15,star=8,value=96};
get_wash_value(2,15,8) -> 
    #ets_wash_value{level=2,type=15,star=8,value=96};
get_wash_value(1,1,9) -> 
    #ets_wash_value{level=1,type=1,star=9,value=288};
get_wash_value(2,1,9) -> 
    #ets_wash_value{level=2,type=1,star=9,value=288};
get_wash_value(1,2,9) -> 
    #ets_wash_value{level=1,type=2,star=9,value=36};
get_wash_value(2,2,9) -> 
    #ets_wash_value{level=2,type=2,star=9,value=36};
get_wash_value(1,3,9) -> 
    #ets_wash_value{level=1,type=3,star=9,value=27};
get_wash_value(2,3,9) -> 
    #ets_wash_value{level=2,type=3,star=9,value=27};
get_wash_value(1,4,9) -> 
    #ets_wash_value{level=1,type=4,star=9,value=45};
get_wash_value(2,4,9) -> 
    #ets_wash_value{level=2,type=4,star=9,value=45};
get_wash_value(1,5,9) -> 
    #ets_wash_value{level=1,type=5,star=9,value=36};
get_wash_value(2,5,9) -> 
    #ets_wash_value{level=2,type=5,star=9,value=36};
get_wash_value(1,6,9) -> 
    #ets_wash_value{level=1,type=6,star=9,value=36};
get_wash_value(2,6,9) -> 
    #ets_wash_value{level=2,type=6,star=9,value=36};
get_wash_value(1,7,9) -> 
    #ets_wash_value{level=1,type=7,star=9,value=9};
get_wash_value(2,7,9) -> 
    #ets_wash_value{level=2,type=7,star=9,value=9};
get_wash_value(1,8,9) -> 
    #ets_wash_value{level=1,type=8,star=9,value=27};
get_wash_value(2,8,9) -> 
    #ets_wash_value{level=2,type=8,star=9,value=27};
get_wash_value(1,13,9) -> 
    #ets_wash_value{level=1,type=13,star=9,value=108};
get_wash_value(2,13,9) -> 
    #ets_wash_value{level=2,type=13,star=9,value=108};
get_wash_value(1,14,9) -> 
    #ets_wash_value{level=1,type=14,star=9,value=108};
get_wash_value(2,14,9) -> 
    #ets_wash_value{level=2,type=14,star=9,value=108};
get_wash_value(1,15,9) -> 
    #ets_wash_value{level=1,type=15,star=9,value=108};
get_wash_value(2,15,9) -> 
    #ets_wash_value{level=2,type=15,star=9,value=108};
get_wash_value(1,1,10) -> 
    #ets_wash_value{level=1,type=1,star=10,value=320};
get_wash_value(2,1,10) -> 
    #ets_wash_value{level=2,type=1,star=10,value=320};
get_wash_value(3,1,10) -> 
    #ets_wash_value{level=3,type=1,star=10,value=320};
get_wash_value(1,2,10) -> 
    #ets_wash_value{level=1,type=2,star=10,value=40};
get_wash_value(2,2,10) -> 
    #ets_wash_value{level=2,type=2,star=10,value=40};
get_wash_value(3,2,10) -> 
    #ets_wash_value{level=3,type=2,star=10,value=40};
get_wash_value(1,3,10) -> 
    #ets_wash_value{level=1,type=3,star=10,value=30};
get_wash_value(2,3,10) -> 
    #ets_wash_value{level=2,type=3,star=10,value=30};
get_wash_value(3,3,10) -> 
    #ets_wash_value{level=3,type=3,star=10,value=30};
get_wash_value(1,4,10) -> 
    #ets_wash_value{level=1,type=4,star=10,value=50};
get_wash_value(2,4,10) -> 
    #ets_wash_value{level=2,type=4,star=10,value=50};
get_wash_value(3,4,10) -> 
    #ets_wash_value{level=3,type=4,star=10,value=50};
get_wash_value(1,5,10) -> 
    #ets_wash_value{level=1,type=5,star=10,value=40};
get_wash_value(2,5,10) -> 
    #ets_wash_value{level=2,type=5,star=10,value=40};
get_wash_value(3,5,10) -> 
    #ets_wash_value{level=3,type=5,star=10,value=40};
get_wash_value(1,6,10) -> 
    #ets_wash_value{level=1,type=6,star=10,value=40};
get_wash_value(2,6,10) -> 
    #ets_wash_value{level=2,type=6,star=10,value=40};
get_wash_value(3,6,10) -> 
    #ets_wash_value{level=3,type=6,star=10,value=40};
get_wash_value(1,7,10) -> 
    #ets_wash_value{level=1,type=7,star=10,value=10};
get_wash_value(2,7,10) -> 
    #ets_wash_value{level=2,type=7,star=10,value=10};
get_wash_value(3,7,10) -> 
    #ets_wash_value{level=3,type=7,star=10,value=10};
get_wash_value(1,8,10) -> 
    #ets_wash_value{level=1,type=8,star=10,value=30};
get_wash_value(2,8,10) -> 
    #ets_wash_value{level=2,type=8,star=10,value=30};
get_wash_value(3,8,10) -> 
    #ets_wash_value{level=3,type=8,star=10,value=30};
get_wash_value(1,13,10) -> 
    #ets_wash_value{level=1,type=13,star=10,value=120};
get_wash_value(2,13,10) -> 
    #ets_wash_value{level=2,type=13,star=10,value=120};
get_wash_value(3,13,10) -> 
    #ets_wash_value{level=3,type=13,star=10,value=120};
get_wash_value(1,14,10) -> 
    #ets_wash_value{level=1,type=14,star=10,value=120};
get_wash_value(2,14,10) -> 
    #ets_wash_value{level=2,type=14,star=10,value=120};
get_wash_value(3,14,10) -> 
    #ets_wash_value{level=3,type=14,star=10,value=120};
get_wash_value(1,15,10) -> 
    #ets_wash_value{level=1,type=15,star=10,value=120};
get_wash_value(2,15,10) -> 
    #ets_wash_value{level=2,type=15,star=10,value=120};
get_wash_value(3,15,10) -> 
    #ets_wash_value{level=3,type=15,star=10,value=120};
get_wash_value(1,1,11) -> 
    #ets_wash_value{level=1,type=1,star=11,value=352};
get_wash_value(2,1,11) -> 
    #ets_wash_value{level=2,type=1,star=11,value=352};
get_wash_value(3,1,11) -> 
    #ets_wash_value{level=3,type=1,star=11,value=352};
get_wash_value(1,2,11) -> 
    #ets_wash_value{level=1,type=2,star=11,value=44};
get_wash_value(2,2,11) -> 
    #ets_wash_value{level=2,type=2,star=11,value=44};
get_wash_value(3,2,11) -> 
    #ets_wash_value{level=3,type=2,star=11,value=44};
get_wash_value(1,3,11) -> 
    #ets_wash_value{level=1,type=3,star=11,value=33};
get_wash_value(2,3,11) -> 
    #ets_wash_value{level=2,type=3,star=11,value=33};
get_wash_value(3,3,11) -> 
    #ets_wash_value{level=3,type=3,star=11,value=33};
get_wash_value(1,4,11) -> 
    #ets_wash_value{level=1,type=4,star=11,value=55};
get_wash_value(2,4,11) -> 
    #ets_wash_value{level=2,type=4,star=11,value=55};
get_wash_value(3,4,11) -> 
    #ets_wash_value{level=3,type=4,star=11,value=55};
get_wash_value(1,5,11) -> 
    #ets_wash_value{level=1,type=5,star=11,value=44};
get_wash_value(2,5,11) -> 
    #ets_wash_value{level=2,type=5,star=11,value=44};
get_wash_value(3,5,11) -> 
    #ets_wash_value{level=3,type=5,star=11,value=44};
get_wash_value(1,6,11) -> 
    #ets_wash_value{level=1,type=6,star=11,value=44};
get_wash_value(2,6,11) -> 
    #ets_wash_value{level=2,type=6,star=11,value=44};
get_wash_value(3,6,11) -> 
    #ets_wash_value{level=3,type=6,star=11,value=44};
get_wash_value(1,7,11) -> 
    #ets_wash_value{level=1,type=7,star=11,value=11};
get_wash_value(2,7,11) -> 
    #ets_wash_value{level=2,type=7,star=11,value=11};
get_wash_value(3,7,11) -> 
    #ets_wash_value{level=3,type=7,star=11,value=11};
get_wash_value(1,8,11) -> 
    #ets_wash_value{level=1,type=8,star=11,value=33};
get_wash_value(2,8,11) -> 
    #ets_wash_value{level=2,type=8,star=11,value=33};
get_wash_value(3,8,11) -> 
    #ets_wash_value{level=3,type=8,star=11,value=33};
get_wash_value(1,13,11) -> 
    #ets_wash_value{level=1,type=13,star=11,value=132};
get_wash_value(2,13,11) -> 
    #ets_wash_value{level=2,type=13,star=11,value=132};
get_wash_value(3,13,11) -> 
    #ets_wash_value{level=3,type=13,star=11,value=132};
get_wash_value(1,14,11) -> 
    #ets_wash_value{level=1,type=14,star=11,value=132};
get_wash_value(2,14,11) -> 
    #ets_wash_value{level=2,type=14,star=11,value=132};
get_wash_value(3,14,11) -> 
    #ets_wash_value{level=3,type=14,star=11,value=132};
get_wash_value(1,15,11) -> 
    #ets_wash_value{level=1,type=15,star=11,value=132};
get_wash_value(2,15,11) -> 
    #ets_wash_value{level=2,type=15,star=11,value=132};
get_wash_value(3,15,11) -> 
    #ets_wash_value{level=3,type=15,star=11,value=132};
get_wash_value(1,1,12) -> 
    #ets_wash_value{level=1,type=1,star=12,value=384};
get_wash_value(2,1,12) -> 
    #ets_wash_value{level=2,type=1,star=12,value=384};
get_wash_value(3,1,12) -> 
    #ets_wash_value{level=3,type=1,star=12,value=384};
get_wash_value(1,2,12) -> 
    #ets_wash_value{level=1,type=2,star=12,value=48};
get_wash_value(2,2,12) -> 
    #ets_wash_value{level=2,type=2,star=12,value=48};
get_wash_value(3,2,12) -> 
    #ets_wash_value{level=3,type=2,star=12,value=48};
get_wash_value(1,3,12) -> 
    #ets_wash_value{level=1,type=3,star=12,value=36};
get_wash_value(2,3,12) -> 
    #ets_wash_value{level=2,type=3,star=12,value=36};
get_wash_value(3,3,12) -> 
    #ets_wash_value{level=3,type=3,star=12,value=36};
get_wash_value(1,4,12) -> 
    #ets_wash_value{level=1,type=4,star=12,value=60};
get_wash_value(2,4,12) -> 
    #ets_wash_value{level=2,type=4,star=12,value=60};
get_wash_value(3,4,12) -> 
    #ets_wash_value{level=3,type=4,star=12,value=60};
get_wash_value(1,5,12) -> 
    #ets_wash_value{level=1,type=5,star=12,value=48};
get_wash_value(2,5,12) -> 
    #ets_wash_value{level=2,type=5,star=12,value=48};
get_wash_value(3,5,12) -> 
    #ets_wash_value{level=3,type=5,star=12,value=48};
get_wash_value(1,6,12) -> 
    #ets_wash_value{level=1,type=6,star=12,value=48};
get_wash_value(2,6,12) -> 
    #ets_wash_value{level=2,type=6,star=12,value=48};
get_wash_value(3,6,12) -> 
    #ets_wash_value{level=3,type=6,star=12,value=48};
get_wash_value(1,7,12) -> 
    #ets_wash_value{level=1,type=7,star=12,value=12};
get_wash_value(2,7,12) -> 
    #ets_wash_value{level=2,type=7,star=12,value=12};
get_wash_value(3,7,12) -> 
    #ets_wash_value{level=3,type=7,star=12,value=12};
get_wash_value(1,8,12) -> 
    #ets_wash_value{level=1,type=8,star=12,value=36};
get_wash_value(2,8,12) -> 
    #ets_wash_value{level=2,type=8,star=12,value=36};
get_wash_value(3,8,12) -> 
    #ets_wash_value{level=3,type=8,star=12,value=36};
get_wash_value(1,13,12) -> 
    #ets_wash_value{level=1,type=13,star=12,value=144};
get_wash_value(2,13,12) -> 
    #ets_wash_value{level=2,type=13,star=12,value=144};
get_wash_value(3,13,12) -> 
    #ets_wash_value{level=3,type=13,star=12,value=144};
get_wash_value(1,14,12) -> 
    #ets_wash_value{level=1,type=14,star=12,value=144};
get_wash_value(2,14,12) -> 
    #ets_wash_value{level=2,type=14,star=12,value=144};
get_wash_value(3,14,12) -> 
    #ets_wash_value{level=3,type=14,star=12,value=144};
get_wash_value(1,15,12) -> 
    #ets_wash_value{level=1,type=15,star=12,value=144};
get_wash_value(2,15,12) -> 
    #ets_wash_value{level=2,type=15,star=12,value=144};
get_wash_value(3,15,12) -> 
    #ets_wash_value{level=3,type=15,star=12,value=144};
get_wash_value(1,1,13) -> 
    #ets_wash_value{level=1,type=1,star=13,value=416};
get_wash_value(2,1,13) -> 
    #ets_wash_value{level=2,type=1,star=13,value=416};
get_wash_value(3,1,13) -> 
    #ets_wash_value{level=3,type=1,star=13,value=416};
get_wash_value(1,2,13) -> 
    #ets_wash_value{level=1,type=2,star=13,value=52};
get_wash_value(2,2,13) -> 
    #ets_wash_value{level=2,type=2,star=13,value=52};
get_wash_value(3,2,13) -> 
    #ets_wash_value{level=3,type=2,star=13,value=52};
get_wash_value(1,3,13) -> 
    #ets_wash_value{level=1,type=3,star=13,value=39};
get_wash_value(2,3,13) -> 
    #ets_wash_value{level=2,type=3,star=13,value=39};
get_wash_value(3,3,13) -> 
    #ets_wash_value{level=3,type=3,star=13,value=39};
get_wash_value(1,4,13) -> 
    #ets_wash_value{level=1,type=4,star=13,value=65};
get_wash_value(2,4,13) -> 
    #ets_wash_value{level=2,type=4,star=13,value=65};
get_wash_value(3,4,13) -> 
    #ets_wash_value{level=3,type=4,star=13,value=65};
get_wash_value(1,5,13) -> 
    #ets_wash_value{level=1,type=5,star=13,value=52};
get_wash_value(2,5,13) -> 
    #ets_wash_value{level=2,type=5,star=13,value=52};
get_wash_value(3,5,13) -> 
    #ets_wash_value{level=3,type=5,star=13,value=52};
get_wash_value(1,6,13) -> 
    #ets_wash_value{level=1,type=6,star=13,value=52};
get_wash_value(2,6,13) -> 
    #ets_wash_value{level=2,type=6,star=13,value=52};
get_wash_value(3,6,13) -> 
    #ets_wash_value{level=3,type=6,star=13,value=52};
get_wash_value(1,7,13) -> 
    #ets_wash_value{level=1,type=7,star=13,value=13};
get_wash_value(2,7,13) -> 
    #ets_wash_value{level=2,type=7,star=13,value=13};
get_wash_value(3,7,13) -> 
    #ets_wash_value{level=3,type=7,star=13,value=13};
get_wash_value(1,8,13) -> 
    #ets_wash_value{level=1,type=8,star=13,value=39};
get_wash_value(2,8,13) -> 
    #ets_wash_value{level=2,type=8,star=13,value=39};
get_wash_value(3,8,13) -> 
    #ets_wash_value{level=3,type=8,star=13,value=39};
get_wash_value(1,13,13) -> 
    #ets_wash_value{level=1,type=13,star=13,value=156};
get_wash_value(2,13,13) -> 
    #ets_wash_value{level=2,type=13,star=13,value=156};
get_wash_value(3,13,13) -> 
    #ets_wash_value{level=3,type=13,star=13,value=156};
get_wash_value(1,14,13) -> 
    #ets_wash_value{level=1,type=14,star=13,value=156};
get_wash_value(2,14,13) -> 
    #ets_wash_value{level=2,type=14,star=13,value=156};
get_wash_value(3,14,13) -> 
    #ets_wash_value{level=3,type=14,star=13,value=156};
get_wash_value(1,15,13) -> 
    #ets_wash_value{level=1,type=15,star=13,value=156};
get_wash_value(2,15,13) -> 
    #ets_wash_value{level=2,type=15,star=13,value=156};
get_wash_value(3,15,13) -> 
    #ets_wash_value{level=3,type=15,star=13,value=156};
get_wash_value(1,1,14) -> 
    #ets_wash_value{level=1,type=1,star=14,value=448};
get_wash_value(2,1,14) -> 
    #ets_wash_value{level=2,type=1,star=14,value=448};
get_wash_value(3,1,14) -> 
    #ets_wash_value{level=3,type=1,star=14,value=448};
get_wash_value(1,2,14) -> 
    #ets_wash_value{level=1,type=2,star=14,value=56};
get_wash_value(2,2,14) -> 
    #ets_wash_value{level=2,type=2,star=14,value=56};
get_wash_value(3,2,14) -> 
    #ets_wash_value{level=3,type=2,star=14,value=56};
get_wash_value(1,3,14) -> 
    #ets_wash_value{level=1,type=3,star=14,value=42};
get_wash_value(2,3,14) -> 
    #ets_wash_value{level=2,type=3,star=14,value=42};
get_wash_value(3,3,14) -> 
    #ets_wash_value{level=3,type=3,star=14,value=42};
get_wash_value(1,4,14) -> 
    #ets_wash_value{level=1,type=4,star=14,value=70};
get_wash_value(2,4,14) -> 
    #ets_wash_value{level=2,type=4,star=14,value=70};
get_wash_value(3,4,14) -> 
    #ets_wash_value{level=3,type=4,star=14,value=70};
get_wash_value(1,5,14) -> 
    #ets_wash_value{level=1,type=5,star=14,value=56};
get_wash_value(2,5,14) -> 
    #ets_wash_value{level=2,type=5,star=14,value=56};
get_wash_value(3,5,14) -> 
    #ets_wash_value{level=3,type=5,star=14,value=56};
get_wash_value(1,6,14) -> 
    #ets_wash_value{level=1,type=6,star=14,value=56};
get_wash_value(2,6,14) -> 
    #ets_wash_value{level=2,type=6,star=14,value=56};
get_wash_value(3,6,14) -> 
    #ets_wash_value{level=3,type=6,star=14,value=56};
get_wash_value(1,7,14) -> 
    #ets_wash_value{level=1,type=7,star=14,value=14};
get_wash_value(2,7,14) -> 
    #ets_wash_value{level=2,type=7,star=14,value=14};
get_wash_value(3,7,14) -> 
    #ets_wash_value{level=3,type=7,star=14,value=14};
get_wash_value(1,8,14) -> 
    #ets_wash_value{level=1,type=8,star=14,value=42};
get_wash_value(2,8,14) -> 
    #ets_wash_value{level=2,type=8,star=14,value=42};
get_wash_value(3,8,14) -> 
    #ets_wash_value{level=3,type=8,star=14,value=42};
get_wash_value(1,13,14) -> 
    #ets_wash_value{level=1,type=13,star=14,value=168};
get_wash_value(2,13,14) -> 
    #ets_wash_value{level=2,type=13,star=14,value=168};
get_wash_value(3,13,14) -> 
    #ets_wash_value{level=3,type=13,star=14,value=168};
get_wash_value(1,14,14) -> 
    #ets_wash_value{level=1,type=14,star=14,value=168};
get_wash_value(2,14,14) -> 
    #ets_wash_value{level=2,type=14,star=14,value=168};
get_wash_value(3,14,14) -> 
    #ets_wash_value{level=3,type=14,star=14,value=168};
get_wash_value(1,15,14) -> 
    #ets_wash_value{level=1,type=15,star=14,value=168};
get_wash_value(2,15,14) -> 
    #ets_wash_value{level=2,type=15,star=14,value=168};
get_wash_value(3,15,14) -> 
    #ets_wash_value{level=3,type=15,star=14,value=168};
get_wash_value(1,1,15) -> 
    #ets_wash_value{level=1,type=1,star=15,value=480};
get_wash_value(2,1,15) -> 
    #ets_wash_value{level=2,type=1,star=15,value=480};
get_wash_value(3,1,15) -> 
    #ets_wash_value{level=3,type=1,star=15,value=480};
get_wash_value(1,2,15) -> 
    #ets_wash_value{level=1,type=2,star=15,value=60};
get_wash_value(2,2,15) -> 
    #ets_wash_value{level=2,type=2,star=15,value=60};
get_wash_value(3,2,15) -> 
    #ets_wash_value{level=3,type=2,star=15,value=60};
get_wash_value(1,3,15) -> 
    #ets_wash_value{level=1,type=3,star=15,value=45};
get_wash_value(2,3,15) -> 
    #ets_wash_value{level=2,type=3,star=15,value=45};
get_wash_value(3,3,15) -> 
    #ets_wash_value{level=3,type=3,star=15,value=45};
get_wash_value(1,4,15) -> 
    #ets_wash_value{level=1,type=4,star=15,value=75};
get_wash_value(2,4,15) -> 
    #ets_wash_value{level=2,type=4,star=15,value=75};
get_wash_value(3,4,15) -> 
    #ets_wash_value{level=3,type=4,star=15,value=75};
get_wash_value(1,5,15) -> 
    #ets_wash_value{level=1,type=5,star=15,value=60};
get_wash_value(2,5,15) -> 
    #ets_wash_value{level=2,type=5,star=15,value=60};
get_wash_value(3,5,15) -> 
    #ets_wash_value{level=3,type=5,star=15,value=60};
get_wash_value(1,6,15) -> 
    #ets_wash_value{level=1,type=6,star=15,value=60};
get_wash_value(2,6,15) -> 
    #ets_wash_value{level=2,type=6,star=15,value=60};
get_wash_value(3,6,15) -> 
    #ets_wash_value{level=3,type=6,star=15,value=60};
get_wash_value(1,7,15) -> 
    #ets_wash_value{level=1,type=7,star=15,value=15};
get_wash_value(2,7,15) -> 
    #ets_wash_value{level=2,type=7,star=15,value=15};
get_wash_value(3,7,15) -> 
    #ets_wash_value{level=3,type=7,star=15,value=15};
get_wash_value(1,8,15) -> 
    #ets_wash_value{level=1,type=8,star=15,value=45};
get_wash_value(2,8,15) -> 
    #ets_wash_value{level=2,type=8,star=15,value=45};
get_wash_value(3,8,15) -> 
    #ets_wash_value{level=3,type=8,star=15,value=45};
get_wash_value(1,13,15) -> 
    #ets_wash_value{level=1,type=13,star=15,value=180};
get_wash_value(2,13,15) -> 
    #ets_wash_value{level=2,type=13,star=15,value=180};
get_wash_value(3,13,15) -> 
    #ets_wash_value{level=3,type=13,star=15,value=180};
get_wash_value(1,14,15) -> 
    #ets_wash_value{level=1,type=14,star=15,value=180};
get_wash_value(2,14,15) -> 
    #ets_wash_value{level=2,type=14,star=15,value=180};
get_wash_value(3,14,15) -> 
    #ets_wash_value{level=3,type=14,star=15,value=180};
get_wash_value(1,15,15) -> 
    #ets_wash_value{level=1,type=15,star=15,value=180};
get_wash_value(2,15,15) -> 
    #ets_wash_value{level=2,type=15,star=15,value=180};
get_wash_value(3,15,15) -> 
    #ets_wash_value{level=3,type=15,star=15,value=180};
get_wash_value(1,1,16) -> 
    #ets_wash_value{level=1,type=1,star=16,value=512};
get_wash_value(2,1,16) -> 
    #ets_wash_value{level=2,type=1,star=16,value=512};
get_wash_value(3,1,16) -> 
    #ets_wash_value{level=3,type=1,star=16,value=512};
get_wash_value(1,2,16) -> 
    #ets_wash_value{level=1,type=2,star=16,value=64};
get_wash_value(2,2,16) -> 
    #ets_wash_value{level=2,type=2,star=16,value=64};
get_wash_value(3,2,16) -> 
    #ets_wash_value{level=3,type=2,star=16,value=64};
get_wash_value(1,3,16) -> 
    #ets_wash_value{level=1,type=3,star=16,value=48};
get_wash_value(2,3,16) -> 
    #ets_wash_value{level=2,type=3,star=16,value=48};
get_wash_value(3,3,16) -> 
    #ets_wash_value{level=3,type=3,star=16,value=48};
get_wash_value(1,4,16) -> 
    #ets_wash_value{level=1,type=4,star=16,value=80};
get_wash_value(2,4,16) -> 
    #ets_wash_value{level=2,type=4,star=16,value=80};
get_wash_value(3,4,16) -> 
    #ets_wash_value{level=3,type=4,star=16,value=80};
get_wash_value(1,5,16) -> 
    #ets_wash_value{level=1,type=5,star=16,value=64};
get_wash_value(2,5,16) -> 
    #ets_wash_value{level=2,type=5,star=16,value=64};
get_wash_value(3,5,16) -> 
    #ets_wash_value{level=3,type=5,star=16,value=64};
get_wash_value(1,6,16) -> 
    #ets_wash_value{level=1,type=6,star=16,value=64};
get_wash_value(2,6,16) -> 
    #ets_wash_value{level=2,type=6,star=16,value=64};
get_wash_value(3,6,16) -> 
    #ets_wash_value{level=3,type=6,star=16,value=64};
get_wash_value(1,7,16) -> 
    #ets_wash_value{level=1,type=7,star=16,value=16};
get_wash_value(2,7,16) -> 
    #ets_wash_value{level=2,type=7,star=16,value=16};
get_wash_value(3,7,16) -> 
    #ets_wash_value{level=3,type=7,star=16,value=16};
get_wash_value(1,8,16) -> 
    #ets_wash_value{level=1,type=8,star=16,value=48};
get_wash_value(2,8,16) -> 
    #ets_wash_value{level=2,type=8,star=16,value=48};
get_wash_value(3,8,16) -> 
    #ets_wash_value{level=3,type=8,star=16,value=48};
get_wash_value(1,13,16) -> 
    #ets_wash_value{level=1,type=13,star=16,value=192};
get_wash_value(2,13,16) -> 
    #ets_wash_value{level=2,type=13,star=16,value=192};
get_wash_value(3,13,16) -> 
    #ets_wash_value{level=3,type=13,star=16,value=192};
get_wash_value(1,14,16) -> 
    #ets_wash_value{level=1,type=14,star=16,value=192};
get_wash_value(2,14,16) -> 
    #ets_wash_value{level=2,type=14,star=16,value=192};
get_wash_value(3,14,16) -> 
    #ets_wash_value{level=3,type=14,star=16,value=192};
get_wash_value(1,15,16) -> 
    #ets_wash_value{level=1,type=15,star=16,value=192};
get_wash_value(2,15,16) -> 
    #ets_wash_value{level=2,type=15,star=16,value=192};
get_wash_value(3,15,16) -> 
    #ets_wash_value{level=3,type=15,star=16,value=192};
get_wash_value(1,1,17) -> 
    #ets_wash_value{level=1,type=1,star=17,value=544};
get_wash_value(2,1,17) -> 
    #ets_wash_value{level=2,type=1,star=17,value=544};
get_wash_value(3,1,17) -> 
    #ets_wash_value{level=3,type=1,star=17,value=544};
get_wash_value(1,2,17) -> 
    #ets_wash_value{level=1,type=2,star=17,value=68};
get_wash_value(2,2,17) -> 
    #ets_wash_value{level=2,type=2,star=17,value=68};
get_wash_value(3,2,17) -> 
    #ets_wash_value{level=3,type=2,star=17,value=68};
get_wash_value(1,3,17) -> 
    #ets_wash_value{level=1,type=3,star=17,value=51};
get_wash_value(2,3,17) -> 
    #ets_wash_value{level=2,type=3,star=17,value=51};
get_wash_value(3,3,17) -> 
    #ets_wash_value{level=3,type=3,star=17,value=51};
get_wash_value(1,4,17) -> 
    #ets_wash_value{level=1,type=4,star=17,value=85};
get_wash_value(2,4,17) -> 
    #ets_wash_value{level=2,type=4,star=17,value=85};
get_wash_value(3,4,17) -> 
    #ets_wash_value{level=3,type=4,star=17,value=85};
get_wash_value(1,5,17) -> 
    #ets_wash_value{level=1,type=5,star=17,value=68};
get_wash_value(2,5,17) -> 
    #ets_wash_value{level=2,type=5,star=17,value=68};
get_wash_value(3,5,17) -> 
    #ets_wash_value{level=3,type=5,star=17,value=68};
get_wash_value(1,6,17) -> 
    #ets_wash_value{level=1,type=6,star=17,value=68};
get_wash_value(2,6,17) -> 
    #ets_wash_value{level=2,type=6,star=17,value=68};
get_wash_value(3,6,17) -> 
    #ets_wash_value{level=3,type=6,star=17,value=68};
get_wash_value(1,7,17) -> 
    #ets_wash_value{level=1,type=7,star=17,value=17};
get_wash_value(2,7,17) -> 
    #ets_wash_value{level=2,type=7,star=17,value=17};
get_wash_value(3,7,17) -> 
    #ets_wash_value{level=3,type=7,star=17,value=17};
get_wash_value(1,8,17) -> 
    #ets_wash_value{level=1,type=8,star=17,value=51};
get_wash_value(2,8,17) -> 
    #ets_wash_value{level=2,type=8,star=17,value=51};
get_wash_value(3,8,17) -> 
    #ets_wash_value{level=3,type=8,star=17,value=51};
get_wash_value(1,13,17) -> 
    #ets_wash_value{level=1,type=13,star=17,value=204};
get_wash_value(2,13,17) -> 
    #ets_wash_value{level=2,type=13,star=17,value=204};
get_wash_value(3,13,17) -> 
    #ets_wash_value{level=3,type=13,star=17,value=204};
get_wash_value(1,14,17) -> 
    #ets_wash_value{level=1,type=14,star=17,value=204};
get_wash_value(2,14,17) -> 
    #ets_wash_value{level=2,type=14,star=17,value=204};
get_wash_value(3,14,17) -> 
    #ets_wash_value{level=3,type=14,star=17,value=204};
get_wash_value(1,15,17) -> 
    #ets_wash_value{level=1,type=15,star=17,value=204};
get_wash_value(2,15,17) -> 
    #ets_wash_value{level=2,type=15,star=17,value=204};
get_wash_value(3,15,17) -> 
    #ets_wash_value{level=3,type=15,star=17,value=204};
get_wash_value(1,1,18) -> 
    #ets_wash_value{level=1,type=1,star=18,value=576};
get_wash_value(2,1,18) -> 
    #ets_wash_value{level=2,type=1,star=18,value=576};
get_wash_value(3,1,18) -> 
    #ets_wash_value{level=3,type=1,star=18,value=576};
get_wash_value(1,2,18) -> 
    #ets_wash_value{level=1,type=2,star=18,value=72};
get_wash_value(2,2,18) -> 
    #ets_wash_value{level=2,type=2,star=18,value=72};
get_wash_value(3,2,18) -> 
    #ets_wash_value{level=3,type=2,star=18,value=72};
get_wash_value(1,3,18) -> 
    #ets_wash_value{level=1,type=3,star=18,value=54};
get_wash_value(2,3,18) -> 
    #ets_wash_value{level=2,type=3,star=18,value=54};
get_wash_value(3,3,18) -> 
    #ets_wash_value{level=3,type=3,star=18,value=54};
get_wash_value(1,4,18) -> 
    #ets_wash_value{level=1,type=4,star=18,value=90};
get_wash_value(2,4,18) -> 
    #ets_wash_value{level=2,type=4,star=18,value=90};
get_wash_value(3,4,18) -> 
    #ets_wash_value{level=3,type=4,star=18,value=90};
get_wash_value(1,5,18) -> 
    #ets_wash_value{level=1,type=5,star=18,value=72};
get_wash_value(2,5,18) -> 
    #ets_wash_value{level=2,type=5,star=18,value=72};
get_wash_value(3,5,18) -> 
    #ets_wash_value{level=3,type=5,star=18,value=72};
get_wash_value(1,6,18) -> 
    #ets_wash_value{level=1,type=6,star=18,value=72};
get_wash_value(2,6,18) -> 
    #ets_wash_value{level=2,type=6,star=18,value=72};
get_wash_value(3,6,18) -> 
    #ets_wash_value{level=3,type=6,star=18,value=72};
get_wash_value(1,7,18) -> 
    #ets_wash_value{level=1,type=7,star=18,value=18};
get_wash_value(2,7,18) -> 
    #ets_wash_value{level=2,type=7,star=18,value=18};
get_wash_value(3,7,18) -> 
    #ets_wash_value{level=3,type=7,star=18,value=18};
get_wash_value(1,8,18) -> 
    #ets_wash_value{level=1,type=8,star=18,value=54};
get_wash_value(2,8,18) -> 
    #ets_wash_value{level=2,type=8,star=18,value=54};
get_wash_value(3,8,18) -> 
    #ets_wash_value{level=3,type=8,star=18,value=54};
get_wash_value(1,13,18) -> 
    #ets_wash_value{level=1,type=13,star=18,value=216};
get_wash_value(2,13,18) -> 
    #ets_wash_value{level=2,type=13,star=18,value=216};
get_wash_value(3,13,18) -> 
    #ets_wash_value{level=3,type=13,star=18,value=216};
get_wash_value(1,14,18) -> 
    #ets_wash_value{level=1,type=14,star=18,value=216};
get_wash_value(2,14,18) -> 
    #ets_wash_value{level=2,type=14,star=18,value=216};
get_wash_value(3,14,18) -> 
    #ets_wash_value{level=3,type=14,star=18,value=216};
get_wash_value(1,15,18) -> 
    #ets_wash_value{level=1,type=15,star=18,value=216};
get_wash_value(2,15,18) -> 
    #ets_wash_value{level=2,type=15,star=18,value=216};
get_wash_value(3,15,18) -> 
    #ets_wash_value{level=3,type=15,star=18,value=216};
get_wash_value(1,1,19) -> 
    #ets_wash_value{level=1,type=1,star=19,value=608};
get_wash_value(2,1,19) -> 
    #ets_wash_value{level=2,type=1,star=19,value=608};
get_wash_value(3,1,19) -> 
    #ets_wash_value{level=3,type=1,star=19,value=608};
get_wash_value(1,2,19) -> 
    #ets_wash_value{level=1,type=2,star=19,value=76};
get_wash_value(2,2,19) -> 
    #ets_wash_value{level=2,type=2,star=19,value=76};
get_wash_value(3,2,19) -> 
    #ets_wash_value{level=3,type=2,star=19,value=76};
get_wash_value(1,3,19) -> 
    #ets_wash_value{level=1,type=3,star=19,value=57};
get_wash_value(2,3,19) -> 
    #ets_wash_value{level=2,type=3,star=19,value=57};
get_wash_value(3,3,19) -> 
    #ets_wash_value{level=3,type=3,star=19,value=57};
get_wash_value(1,4,19) -> 
    #ets_wash_value{level=1,type=4,star=19,value=95};
get_wash_value(2,4,19) -> 
    #ets_wash_value{level=2,type=4,star=19,value=95};
get_wash_value(3,4,19) -> 
    #ets_wash_value{level=3,type=4,star=19,value=95};
get_wash_value(1,5,19) -> 
    #ets_wash_value{level=1,type=5,star=19,value=76};
get_wash_value(2,5,19) -> 
    #ets_wash_value{level=2,type=5,star=19,value=76};
get_wash_value(3,5,19) -> 
    #ets_wash_value{level=3,type=5,star=19,value=76};
get_wash_value(1,6,19) -> 
    #ets_wash_value{level=1,type=6,star=19,value=76};
get_wash_value(2,6,19) -> 
    #ets_wash_value{level=2,type=6,star=19,value=76};
get_wash_value(3,6,19) -> 
    #ets_wash_value{level=3,type=6,star=19,value=76};
get_wash_value(1,7,19) -> 
    #ets_wash_value{level=1,type=7,star=19,value=19};
get_wash_value(2,7,19) -> 
    #ets_wash_value{level=2,type=7,star=19,value=19};
get_wash_value(3,7,19) -> 
    #ets_wash_value{level=3,type=7,star=19,value=19};
get_wash_value(1,8,19) -> 
    #ets_wash_value{level=1,type=8,star=19,value=57};
get_wash_value(2,8,19) -> 
    #ets_wash_value{level=2,type=8,star=19,value=57};
get_wash_value(3,8,19) -> 
    #ets_wash_value{level=3,type=8,star=19,value=57};
get_wash_value(1,13,19) -> 
    #ets_wash_value{level=1,type=13,star=19,value=228};
get_wash_value(2,13,19) -> 
    #ets_wash_value{level=2,type=13,star=19,value=228};
get_wash_value(3,13,19) -> 
    #ets_wash_value{level=3,type=13,star=19,value=228};
get_wash_value(1,14,19) -> 
    #ets_wash_value{level=1,type=14,star=19,value=228};
get_wash_value(2,14,19) -> 
    #ets_wash_value{level=2,type=14,star=19,value=228};
get_wash_value(3,14,19) -> 
    #ets_wash_value{level=3,type=14,star=19,value=228};
get_wash_value(1,15,19) -> 
    #ets_wash_value{level=1,type=15,star=19,value=228};
get_wash_value(2,15,19) -> 
    #ets_wash_value{level=2,type=15,star=19,value=228};
get_wash_value(3,15,19) -> 
    #ets_wash_value{level=3,type=15,star=19,value=228};
get_wash_value(1,1,20) -> 
    #ets_wash_value{level=1,type=1,star=20,value=640};
get_wash_value(2,1,20) -> 
    #ets_wash_value{level=2,type=1,star=20,value=640};
get_wash_value(3,1,20) -> 
    #ets_wash_value{level=3,type=1,star=20,value=640};
get_wash_value(1,2,20) -> 
    #ets_wash_value{level=1,type=2,star=20,value=80};
get_wash_value(2,2,20) -> 
    #ets_wash_value{level=2,type=2,star=20,value=80};
get_wash_value(3,2,20) -> 
    #ets_wash_value{level=3,type=2,star=20,value=80};
get_wash_value(1,3,20) -> 
    #ets_wash_value{level=1,type=3,star=20,value=60};
get_wash_value(2,3,20) -> 
    #ets_wash_value{level=2,type=3,star=20,value=60};
get_wash_value(3,3,20) -> 
    #ets_wash_value{level=3,type=3,star=20,value=60};
get_wash_value(1,4,20) -> 
    #ets_wash_value{level=1,type=4,star=20,value=100};
get_wash_value(2,4,20) -> 
    #ets_wash_value{level=2,type=4,star=20,value=100};
get_wash_value(3,4,20) -> 
    #ets_wash_value{level=3,type=4,star=20,value=100};
get_wash_value(1,5,20) -> 
    #ets_wash_value{level=1,type=5,star=20,value=80};
get_wash_value(2,5,20) -> 
    #ets_wash_value{level=2,type=5,star=20,value=80};
get_wash_value(3,5,20) -> 
    #ets_wash_value{level=3,type=5,star=20,value=80};
get_wash_value(1,6,20) -> 
    #ets_wash_value{level=1,type=6,star=20,value=80};
get_wash_value(2,6,20) -> 
    #ets_wash_value{level=2,type=6,star=20,value=80};
get_wash_value(3,6,20) -> 
    #ets_wash_value{level=3,type=6,star=20,value=80};
get_wash_value(1,7,20) -> 
    #ets_wash_value{level=1,type=7,star=20,value=20};
get_wash_value(2,7,20) -> 
    #ets_wash_value{level=2,type=7,star=20,value=20};
get_wash_value(3,7,20) -> 
    #ets_wash_value{level=3,type=7,star=20,value=20};
get_wash_value(1,8,20) -> 
    #ets_wash_value{level=1,type=8,star=20,value=60};
get_wash_value(2,8,20) -> 
    #ets_wash_value{level=2,type=8,star=20,value=60};
get_wash_value(3,8,20) -> 
    #ets_wash_value{level=3,type=8,star=20,value=60};
get_wash_value(1,13,20) -> 
    #ets_wash_value{level=1,type=13,star=20,value=240};
get_wash_value(2,13,20) -> 
    #ets_wash_value{level=2,type=13,star=20,value=240};
get_wash_value(3,13,20) -> 
    #ets_wash_value{level=3,type=13,star=20,value=240};
get_wash_value(1,14,20) -> 
    #ets_wash_value{level=1,type=14,star=20,value=240};
get_wash_value(2,14,20) -> 
    #ets_wash_value{level=2,type=14,star=20,value=240};
get_wash_value(3,14,20) -> 
    #ets_wash_value{level=3,type=14,star=20,value=240};
get_wash_value(1,15,20) -> 
    #ets_wash_value{level=1,type=15,star=20,value=240};
get_wash_value(2,15,20) -> 
    #ets_wash_value{level=2,type=15,star=20,value=240};
get_wash_value(3,15,20) -> 
    #ets_wash_value{level=3,type=15,star=20,value=240};
get_wash_value(1,1,21) -> 
    #ets_wash_value{level=1,type=1,star=21,value=672};
get_wash_value(2,1,21) -> 
    #ets_wash_value{level=2,type=1,star=21,value=672};
get_wash_value(3,1,21) -> 
    #ets_wash_value{level=3,type=1,star=21,value=672};
get_wash_value(1,2,21) -> 
    #ets_wash_value{level=1,type=2,star=21,value=84};
get_wash_value(2,2,21) -> 
    #ets_wash_value{level=2,type=2,star=21,value=84};
get_wash_value(3,2,21) -> 
    #ets_wash_value{level=3,type=2,star=21,value=84};
get_wash_value(1,3,21) -> 
    #ets_wash_value{level=1,type=3,star=21,value=63};
get_wash_value(2,3,21) -> 
    #ets_wash_value{level=2,type=3,star=21,value=63};
get_wash_value(3,3,21) -> 
    #ets_wash_value{level=3,type=3,star=21,value=63};
get_wash_value(1,4,21) -> 
    #ets_wash_value{level=1,type=4,star=21,value=105};
get_wash_value(2,4,21) -> 
    #ets_wash_value{level=2,type=4,star=21,value=105};
get_wash_value(3,4,21) -> 
    #ets_wash_value{level=3,type=4,star=21,value=105};
get_wash_value(1,5,21) -> 
    #ets_wash_value{level=1,type=5,star=21,value=84};
get_wash_value(2,5,21) -> 
    #ets_wash_value{level=2,type=5,star=21,value=84};
get_wash_value(3,5,21) -> 
    #ets_wash_value{level=3,type=5,star=21,value=84};
get_wash_value(1,6,21) -> 
    #ets_wash_value{level=1,type=6,star=21,value=84};
get_wash_value(2,6,21) -> 
    #ets_wash_value{level=2,type=6,star=21,value=84};
get_wash_value(3,6,21) -> 
    #ets_wash_value{level=3,type=6,star=21,value=84};
get_wash_value(1,7,21) -> 
    #ets_wash_value{level=1,type=7,star=21,value=21};
get_wash_value(2,7,21) -> 
    #ets_wash_value{level=2,type=7,star=21,value=21};
get_wash_value(3,7,21) -> 
    #ets_wash_value{level=3,type=7,star=21,value=21};
get_wash_value(1,8,21) -> 
    #ets_wash_value{level=1,type=8,star=21,value=63};
get_wash_value(2,8,21) -> 
    #ets_wash_value{level=2,type=8,star=21,value=63};
get_wash_value(3,8,21) -> 
    #ets_wash_value{level=3,type=8,star=21,value=63};
get_wash_value(1,13,21) -> 
    #ets_wash_value{level=1,type=13,star=21,value=252};
get_wash_value(2,13,21) -> 
    #ets_wash_value{level=2,type=13,star=21,value=252};
get_wash_value(3,13,21) -> 
    #ets_wash_value{level=3,type=13,star=21,value=252};
get_wash_value(1,14,21) -> 
    #ets_wash_value{level=1,type=14,star=21,value=252};
get_wash_value(2,14,21) -> 
    #ets_wash_value{level=2,type=14,star=21,value=252};
get_wash_value(3,14,21) -> 
    #ets_wash_value{level=3,type=14,star=21,value=252};
get_wash_value(1,15,21) -> 
    #ets_wash_value{level=1,type=15,star=21,value=252};
get_wash_value(2,15,21) -> 
    #ets_wash_value{level=2,type=15,star=21,value=252};
get_wash_value(3,15,21) -> 
    #ets_wash_value{level=3,type=15,star=21,value=252};
get_wash_value(1,1,22) -> 
    #ets_wash_value{level=1,type=1,star=22,value=704};
get_wash_value(2,1,22) -> 
    #ets_wash_value{level=2,type=1,star=22,value=704};
get_wash_value(3,1,22) -> 
    #ets_wash_value{level=3,type=1,star=22,value=704};
get_wash_value(1,2,22) -> 
    #ets_wash_value{level=1,type=2,star=22,value=88};
get_wash_value(2,2,22) -> 
    #ets_wash_value{level=2,type=2,star=22,value=88};
get_wash_value(3,2,22) -> 
    #ets_wash_value{level=3,type=2,star=22,value=88};
get_wash_value(1,3,22) -> 
    #ets_wash_value{level=1,type=3,star=22,value=66};
get_wash_value(2,3,22) -> 
    #ets_wash_value{level=2,type=3,star=22,value=66};
get_wash_value(3,3,22) -> 
    #ets_wash_value{level=3,type=3,star=22,value=66};
get_wash_value(1,4,22) -> 
    #ets_wash_value{level=1,type=4,star=22,value=110};
get_wash_value(2,4,22) -> 
    #ets_wash_value{level=2,type=4,star=22,value=110};
get_wash_value(3,4,22) -> 
    #ets_wash_value{level=3,type=4,star=22,value=110};
get_wash_value(1,5,22) -> 
    #ets_wash_value{level=1,type=5,star=22,value=88};
get_wash_value(2,5,22) -> 
    #ets_wash_value{level=2,type=5,star=22,value=88};
get_wash_value(3,5,22) -> 
    #ets_wash_value{level=3,type=5,star=22,value=88};
get_wash_value(1,6,22) -> 
    #ets_wash_value{level=1,type=6,star=22,value=88};
get_wash_value(2,6,22) -> 
    #ets_wash_value{level=2,type=6,star=22,value=88};
get_wash_value(3,6,22) -> 
    #ets_wash_value{level=3,type=6,star=22,value=88};
get_wash_value(1,7,22) -> 
    #ets_wash_value{level=1,type=7,star=22,value=22};
get_wash_value(2,7,22) -> 
    #ets_wash_value{level=2,type=7,star=22,value=22};
get_wash_value(3,7,22) -> 
    #ets_wash_value{level=3,type=7,star=22,value=22};
get_wash_value(1,8,22) -> 
    #ets_wash_value{level=1,type=8,star=22,value=66};
get_wash_value(2,8,22) -> 
    #ets_wash_value{level=2,type=8,star=22,value=66};
get_wash_value(3,8,22) -> 
    #ets_wash_value{level=3,type=8,star=22,value=66};
get_wash_value(1,13,22) -> 
    #ets_wash_value{level=1,type=13,star=22,value=264};
get_wash_value(2,13,22) -> 
    #ets_wash_value{level=2,type=13,star=22,value=264};
get_wash_value(3,13,22) -> 
    #ets_wash_value{level=3,type=13,star=22,value=264};
get_wash_value(1,14,22) -> 
    #ets_wash_value{level=1,type=14,star=22,value=264};
get_wash_value(2,14,22) -> 
    #ets_wash_value{level=2,type=14,star=22,value=264};
get_wash_value(3,14,22) -> 
    #ets_wash_value{level=3,type=14,star=22,value=264};
get_wash_value(1,15,22) -> 
    #ets_wash_value{level=1,type=15,star=22,value=264};
get_wash_value(2,15,22) -> 
    #ets_wash_value{level=2,type=15,star=22,value=264};
get_wash_value(3,15,22) -> 
    #ets_wash_value{level=3,type=15,star=22,value=264};
get_wash_value(1,1,23) -> 
    #ets_wash_value{level=1,type=1,star=23,value=736};
get_wash_value(2,1,23) -> 
    #ets_wash_value{level=2,type=1,star=23,value=736};
get_wash_value(3,1,23) -> 
    #ets_wash_value{level=3,type=1,star=23,value=736};
get_wash_value(1,2,23) -> 
    #ets_wash_value{level=1,type=2,star=23,value=92};
get_wash_value(2,2,23) -> 
    #ets_wash_value{level=2,type=2,star=23,value=92};
get_wash_value(3,2,23) -> 
    #ets_wash_value{level=3,type=2,star=23,value=92};
get_wash_value(1,3,23) -> 
    #ets_wash_value{level=1,type=3,star=23,value=69};
get_wash_value(2,3,23) -> 
    #ets_wash_value{level=2,type=3,star=23,value=69};
get_wash_value(3,3,23) -> 
    #ets_wash_value{level=3,type=3,star=23,value=69};
get_wash_value(1,4,23) -> 
    #ets_wash_value{level=1,type=4,star=23,value=115};
get_wash_value(2,4,23) -> 
    #ets_wash_value{level=2,type=4,star=23,value=115};
get_wash_value(3,4,23) -> 
    #ets_wash_value{level=3,type=4,star=23,value=115};
get_wash_value(1,5,23) -> 
    #ets_wash_value{level=1,type=5,star=23,value=92};
get_wash_value(2,5,23) -> 
    #ets_wash_value{level=2,type=5,star=23,value=92};
get_wash_value(3,5,23) -> 
    #ets_wash_value{level=3,type=5,star=23,value=92};
get_wash_value(1,6,23) -> 
    #ets_wash_value{level=1,type=6,star=23,value=92};
get_wash_value(2,6,23) -> 
    #ets_wash_value{level=2,type=6,star=23,value=92};
get_wash_value(3,6,23) -> 
    #ets_wash_value{level=3,type=6,star=23,value=92};
get_wash_value(1,7,23) -> 
    #ets_wash_value{level=1,type=7,star=23,value=23};
get_wash_value(2,7,23) -> 
    #ets_wash_value{level=2,type=7,star=23,value=23};
get_wash_value(3,7,23) -> 
    #ets_wash_value{level=3,type=7,star=23,value=23};
get_wash_value(1,8,23) -> 
    #ets_wash_value{level=1,type=8,star=23,value=69};
get_wash_value(2,8,23) -> 
    #ets_wash_value{level=2,type=8,star=23,value=69};
get_wash_value(3,8,23) -> 
    #ets_wash_value{level=3,type=8,star=23,value=69};
get_wash_value(1,13,23) -> 
    #ets_wash_value{level=1,type=13,star=23,value=276};
get_wash_value(2,13,23) -> 
    #ets_wash_value{level=2,type=13,star=23,value=276};
get_wash_value(3,13,23) -> 
    #ets_wash_value{level=3,type=13,star=23,value=276};
get_wash_value(1,14,23) -> 
    #ets_wash_value{level=1,type=14,star=23,value=276};
get_wash_value(2,14,23) -> 
    #ets_wash_value{level=2,type=14,star=23,value=276};
get_wash_value(3,14,23) -> 
    #ets_wash_value{level=3,type=14,star=23,value=276};
get_wash_value(1,15,23) -> 
    #ets_wash_value{level=1,type=15,star=23,value=276};
get_wash_value(2,15,23) -> 
    #ets_wash_value{level=2,type=15,star=23,value=276};
get_wash_value(3,15,23) -> 
    #ets_wash_value{level=3,type=15,star=23,value=276};
get_wash_value(1,1,24) -> 
    #ets_wash_value{level=1,type=1,star=24,value=768};
get_wash_value(2,1,24) -> 
    #ets_wash_value{level=2,type=1,star=24,value=768};
get_wash_value(3,1,24) -> 
    #ets_wash_value{level=3,type=1,star=24,value=768};
get_wash_value(1,2,24) -> 
    #ets_wash_value{level=1,type=2,star=24,value=96};
get_wash_value(2,2,24) -> 
    #ets_wash_value{level=2,type=2,star=24,value=96};
get_wash_value(3,2,24) -> 
    #ets_wash_value{level=3,type=2,star=24,value=96};
get_wash_value(1,3,24) -> 
    #ets_wash_value{level=1,type=3,star=24,value=72};
get_wash_value(2,3,24) -> 
    #ets_wash_value{level=2,type=3,star=24,value=72};
get_wash_value(3,3,24) -> 
    #ets_wash_value{level=3,type=3,star=24,value=72};
get_wash_value(1,4,24) -> 
    #ets_wash_value{level=1,type=4,star=24,value=120};
get_wash_value(2,4,24) -> 
    #ets_wash_value{level=2,type=4,star=24,value=120};
get_wash_value(3,4,24) -> 
    #ets_wash_value{level=3,type=4,star=24,value=120};
get_wash_value(1,5,24) -> 
    #ets_wash_value{level=1,type=5,star=24,value=96};
get_wash_value(2,5,24) -> 
    #ets_wash_value{level=2,type=5,star=24,value=96};
get_wash_value(3,5,24) -> 
    #ets_wash_value{level=3,type=5,star=24,value=96};
get_wash_value(1,6,24) -> 
    #ets_wash_value{level=1,type=6,star=24,value=96};
get_wash_value(2,6,24) -> 
    #ets_wash_value{level=2,type=6,star=24,value=96};
get_wash_value(3,6,24) -> 
    #ets_wash_value{level=3,type=6,star=24,value=96};
get_wash_value(1,7,24) -> 
    #ets_wash_value{level=1,type=7,star=24,value=24};
get_wash_value(2,7,24) -> 
    #ets_wash_value{level=2,type=7,star=24,value=24};
get_wash_value(3,7,24) -> 
    #ets_wash_value{level=3,type=7,star=24,value=24};
get_wash_value(1,8,24) -> 
    #ets_wash_value{level=1,type=8,star=24,value=72};
get_wash_value(2,8,24) -> 
    #ets_wash_value{level=2,type=8,star=24,value=72};
get_wash_value(3,8,24) -> 
    #ets_wash_value{level=3,type=8,star=24,value=72};
get_wash_value(1,13,24) -> 
    #ets_wash_value{level=1,type=13,star=24,value=288};
get_wash_value(2,13,24) -> 
    #ets_wash_value{level=2,type=13,star=24,value=288};
get_wash_value(3,13,24) -> 
    #ets_wash_value{level=3,type=13,star=24,value=288};
get_wash_value(1,14,24) -> 
    #ets_wash_value{level=1,type=14,star=24,value=288};
get_wash_value(2,14,24) -> 
    #ets_wash_value{level=2,type=14,star=24,value=288};
get_wash_value(3,14,24) -> 
    #ets_wash_value{level=3,type=14,star=24,value=288};
get_wash_value(1,15,24) -> 
    #ets_wash_value{level=1,type=15,star=24,value=288};
get_wash_value(2,15,24) -> 
    #ets_wash_value{level=2,type=15,star=24,value=288};
get_wash_value(3,15,24) -> 
    #ets_wash_value{level=3,type=15,star=24,value=288};
get_wash_value(1,1,25) -> 
    #ets_wash_value{level=1,type=1,star=25,value=800};
get_wash_value(2,1,25) -> 
    #ets_wash_value{level=2,type=1,star=25,value=800};
get_wash_value(3,1,25) -> 
    #ets_wash_value{level=3,type=1,star=25,value=800};
get_wash_value(1,2,25) -> 
    #ets_wash_value{level=1,type=2,star=25,value=100};
get_wash_value(2,2,25) -> 
    #ets_wash_value{level=2,type=2,star=25,value=100};
get_wash_value(3,2,25) -> 
    #ets_wash_value{level=3,type=2,star=25,value=100};
get_wash_value(1,3,25) -> 
    #ets_wash_value{level=1,type=3,star=25,value=75};
get_wash_value(2,3,25) -> 
    #ets_wash_value{level=2,type=3,star=25,value=75};
get_wash_value(3,3,25) -> 
    #ets_wash_value{level=3,type=3,star=25,value=75};
get_wash_value(1,4,25) -> 
    #ets_wash_value{level=1,type=4,star=25,value=125};
get_wash_value(2,4,25) -> 
    #ets_wash_value{level=2,type=4,star=25,value=125};
get_wash_value(3,4,25) -> 
    #ets_wash_value{level=3,type=4,star=25,value=125};
get_wash_value(1,5,25) -> 
    #ets_wash_value{level=1,type=5,star=25,value=100};
get_wash_value(2,5,25) -> 
    #ets_wash_value{level=2,type=5,star=25,value=100};
get_wash_value(3,5,25) -> 
    #ets_wash_value{level=3,type=5,star=25,value=100};
get_wash_value(1,6,25) -> 
    #ets_wash_value{level=1,type=6,star=25,value=100};
get_wash_value(2,6,25) -> 
    #ets_wash_value{level=2,type=6,star=25,value=100};
get_wash_value(3,6,25) -> 
    #ets_wash_value{level=3,type=6,star=25,value=100};
get_wash_value(1,7,25) -> 
    #ets_wash_value{level=1,type=7,star=25,value=25};
get_wash_value(2,7,25) -> 
    #ets_wash_value{level=2,type=7,star=25,value=25};
get_wash_value(3,7,25) -> 
    #ets_wash_value{level=3,type=7,star=25,value=25};
get_wash_value(1,8,25) -> 
    #ets_wash_value{level=1,type=8,star=25,value=75};
get_wash_value(2,8,25) -> 
    #ets_wash_value{level=2,type=8,star=25,value=75};
get_wash_value(3,8,25) -> 
    #ets_wash_value{level=3,type=8,star=25,value=75};
get_wash_value(1,13,25) -> 
    #ets_wash_value{level=1,type=13,star=25,value=300};
get_wash_value(2,13,25) -> 
    #ets_wash_value{level=2,type=13,star=25,value=300};
get_wash_value(3,13,25) -> 
    #ets_wash_value{level=3,type=13,star=25,value=300};
get_wash_value(1,14,25) -> 
    #ets_wash_value{level=1,type=14,star=25,value=300};
get_wash_value(2,14,25) -> 
    #ets_wash_value{level=2,type=14,star=25,value=300};
get_wash_value(3,14,25) -> 
    #ets_wash_value{level=3,type=14,star=25,value=300};
get_wash_value(1,15,25) -> 
    #ets_wash_value{level=1,type=15,star=25,value=300};
get_wash_value(2,15,25) -> 
    #ets_wash_value{level=2,type=15,star=25,value=300};
get_wash_value(3,15,25) -> 
    #ets_wash_value{level=3,type=15,star=25,value=300};
get_wash_value(2,1,26) -> 
    #ets_wash_value{level=2,type=1,star=26,value=832};
get_wash_value(3,1,26) -> 
    #ets_wash_value{level=3,type=1,star=26,value=832};
get_wash_value(2,2,26) -> 
    #ets_wash_value{level=2,type=2,star=26,value=104};
get_wash_value(3,2,26) -> 
    #ets_wash_value{level=3,type=2,star=26,value=104};
get_wash_value(2,3,26) -> 
    #ets_wash_value{level=2,type=3,star=26,value=78};
get_wash_value(3,3,26) -> 
    #ets_wash_value{level=3,type=3,star=26,value=78};
get_wash_value(2,4,26) -> 
    #ets_wash_value{level=2,type=4,star=26,value=130};
get_wash_value(3,4,26) -> 
    #ets_wash_value{level=3,type=4,star=26,value=130};
get_wash_value(2,5,26) -> 
    #ets_wash_value{level=2,type=5,star=26,value=104};
get_wash_value(3,5,26) -> 
    #ets_wash_value{level=3,type=5,star=26,value=104};
get_wash_value(2,6,26) -> 
    #ets_wash_value{level=2,type=6,star=26,value=104};
get_wash_value(3,6,26) -> 
    #ets_wash_value{level=3,type=6,star=26,value=104};
get_wash_value(2,7,26) -> 
    #ets_wash_value{level=2,type=7,star=26,value=26};
get_wash_value(3,7,26) -> 
    #ets_wash_value{level=3,type=7,star=26,value=26};
get_wash_value(2,8,26) -> 
    #ets_wash_value{level=2,type=8,star=26,value=78};
get_wash_value(3,8,26) -> 
    #ets_wash_value{level=3,type=8,star=26,value=78};
get_wash_value(2,13,26) -> 
    #ets_wash_value{level=2,type=13,star=26,value=312};
get_wash_value(3,13,26) -> 
    #ets_wash_value{level=3,type=13,star=26,value=312};
get_wash_value(2,14,26) -> 
    #ets_wash_value{level=2,type=14,star=26,value=312};
get_wash_value(3,14,26) -> 
    #ets_wash_value{level=3,type=14,star=26,value=312};
get_wash_value(2,15,26) -> 
    #ets_wash_value{level=2,type=15,star=26,value=312};
get_wash_value(3,15,26) -> 
    #ets_wash_value{level=3,type=15,star=26,value=312};
get_wash_value(2,1,27) -> 
    #ets_wash_value{level=2,type=1,star=27,value=864};
get_wash_value(3,1,27) -> 
    #ets_wash_value{level=3,type=1,star=27,value=864};
get_wash_value(2,2,27) -> 
    #ets_wash_value{level=2,type=2,star=27,value=108};
get_wash_value(3,2,27) -> 
    #ets_wash_value{level=3,type=2,star=27,value=108};
get_wash_value(2,3,27) -> 
    #ets_wash_value{level=2,type=3,star=27,value=81};
get_wash_value(3,3,27) -> 
    #ets_wash_value{level=3,type=3,star=27,value=81};
get_wash_value(2,4,27) -> 
    #ets_wash_value{level=2,type=4,star=27,value=135};
get_wash_value(3,4,27) -> 
    #ets_wash_value{level=3,type=4,star=27,value=135};
get_wash_value(2,5,27) -> 
    #ets_wash_value{level=2,type=5,star=27,value=108};
get_wash_value(3,5,27) -> 
    #ets_wash_value{level=3,type=5,star=27,value=108};
get_wash_value(2,6,27) -> 
    #ets_wash_value{level=2,type=6,star=27,value=108};
get_wash_value(3,6,27) -> 
    #ets_wash_value{level=3,type=6,star=27,value=108};
get_wash_value(2,7,27) -> 
    #ets_wash_value{level=2,type=7,star=27,value=27};
get_wash_value(3,7,27) -> 
    #ets_wash_value{level=3,type=7,star=27,value=27};
get_wash_value(2,8,27) -> 
    #ets_wash_value{level=2,type=8,star=27,value=81};
get_wash_value(3,8,27) -> 
    #ets_wash_value{level=3,type=8,star=27,value=81};
get_wash_value(2,13,27) -> 
    #ets_wash_value{level=2,type=13,star=27,value=324};
get_wash_value(3,13,27) -> 
    #ets_wash_value{level=3,type=13,star=27,value=324};
get_wash_value(2,14,27) -> 
    #ets_wash_value{level=2,type=14,star=27,value=324};
get_wash_value(3,14,27) -> 
    #ets_wash_value{level=3,type=14,star=27,value=324};
get_wash_value(2,15,27) -> 
    #ets_wash_value{level=2,type=15,star=27,value=324};
get_wash_value(3,15,27) -> 
    #ets_wash_value{level=3,type=15,star=27,value=324};
get_wash_value(2,1,28) -> 
    #ets_wash_value{level=2,type=1,star=28,value=896};
get_wash_value(3,1,28) -> 
    #ets_wash_value{level=3,type=1,star=28,value=896};
get_wash_value(2,2,28) -> 
    #ets_wash_value{level=2,type=2,star=28,value=112};
get_wash_value(3,2,28) -> 
    #ets_wash_value{level=3,type=2,star=28,value=112};
get_wash_value(2,3,28) -> 
    #ets_wash_value{level=2,type=3,star=28,value=84};
get_wash_value(3,3,28) -> 
    #ets_wash_value{level=3,type=3,star=28,value=84};
get_wash_value(2,4,28) -> 
    #ets_wash_value{level=2,type=4,star=28,value=140};
get_wash_value(3,4,28) -> 
    #ets_wash_value{level=3,type=4,star=28,value=140};
get_wash_value(2,5,28) -> 
    #ets_wash_value{level=2,type=5,star=28,value=112};
get_wash_value(3,5,28) -> 
    #ets_wash_value{level=3,type=5,star=28,value=112};
get_wash_value(2,6,28) -> 
    #ets_wash_value{level=2,type=6,star=28,value=112};
get_wash_value(3,6,28) -> 
    #ets_wash_value{level=3,type=6,star=28,value=112};
get_wash_value(2,7,28) -> 
    #ets_wash_value{level=2,type=7,star=28,value=28};
get_wash_value(3,7,28) -> 
    #ets_wash_value{level=3,type=7,star=28,value=28};
get_wash_value(2,8,28) -> 
    #ets_wash_value{level=2,type=8,star=28,value=84};
get_wash_value(3,8,28) -> 
    #ets_wash_value{level=3,type=8,star=28,value=84};
get_wash_value(2,13,28) -> 
    #ets_wash_value{level=2,type=13,star=28,value=336};
get_wash_value(3,13,28) -> 
    #ets_wash_value{level=3,type=13,star=28,value=336};
get_wash_value(2,14,28) -> 
    #ets_wash_value{level=2,type=14,star=28,value=336};
get_wash_value(3,14,28) -> 
    #ets_wash_value{level=3,type=14,star=28,value=336};
get_wash_value(2,15,28) -> 
    #ets_wash_value{level=2,type=15,star=28,value=336};
get_wash_value(3,15,28) -> 
    #ets_wash_value{level=3,type=15,star=28,value=336};
get_wash_value(2,1,29) -> 
    #ets_wash_value{level=2,type=1,star=29,value=928};
get_wash_value(3,1,29) -> 
    #ets_wash_value{level=3,type=1,star=29,value=928};
get_wash_value(2,2,29) -> 
    #ets_wash_value{level=2,type=2,star=29,value=116};
get_wash_value(3,2,29) -> 
    #ets_wash_value{level=3,type=2,star=29,value=116};
get_wash_value(2,3,29) -> 
    #ets_wash_value{level=2,type=3,star=29,value=87};
get_wash_value(3,3,29) -> 
    #ets_wash_value{level=3,type=3,star=29,value=87};
get_wash_value(2,4,29) -> 
    #ets_wash_value{level=2,type=4,star=29,value=145};
get_wash_value(3,4,29) -> 
    #ets_wash_value{level=3,type=4,star=29,value=145};
get_wash_value(2,5,29) -> 
    #ets_wash_value{level=2,type=5,star=29,value=116};
get_wash_value(3,5,29) -> 
    #ets_wash_value{level=3,type=5,star=29,value=116};
get_wash_value(2,6,29) -> 
    #ets_wash_value{level=2,type=6,star=29,value=116};
get_wash_value(3,6,29) -> 
    #ets_wash_value{level=3,type=6,star=29,value=116};
get_wash_value(2,7,29) -> 
    #ets_wash_value{level=2,type=7,star=29,value=29};
get_wash_value(3,7,29) -> 
    #ets_wash_value{level=3,type=7,star=29,value=29};
get_wash_value(2,8,29) -> 
    #ets_wash_value{level=2,type=8,star=29,value=87};
get_wash_value(3,8,29) -> 
    #ets_wash_value{level=3,type=8,star=29,value=87};
get_wash_value(2,13,29) -> 
    #ets_wash_value{level=2,type=13,star=29,value=348};
get_wash_value(3,13,29) -> 
    #ets_wash_value{level=3,type=13,star=29,value=348};
get_wash_value(2,14,29) -> 
    #ets_wash_value{level=2,type=14,star=29,value=348};
get_wash_value(3,14,29) -> 
    #ets_wash_value{level=3,type=14,star=29,value=348};
get_wash_value(2,15,29) -> 
    #ets_wash_value{level=2,type=15,star=29,value=348};
get_wash_value(3,15,29) -> 
    #ets_wash_value{level=3,type=15,star=29,value=348};
get_wash_value(2,1,30) -> 
    #ets_wash_value{level=2,type=1,star=30,value=960};
get_wash_value(3,1,30) -> 
    #ets_wash_value{level=3,type=1,star=30,value=960};
get_wash_value(2,2,30) -> 
    #ets_wash_value{level=2,type=2,star=30,value=120};
get_wash_value(3,2,30) -> 
    #ets_wash_value{level=3,type=2,star=30,value=120};
get_wash_value(2,3,30) -> 
    #ets_wash_value{level=2,type=3,star=30,value=90};
get_wash_value(3,3,30) -> 
    #ets_wash_value{level=3,type=3,star=30,value=90};
get_wash_value(2,4,30) -> 
    #ets_wash_value{level=2,type=4,star=30,value=150};
get_wash_value(3,4,30) -> 
    #ets_wash_value{level=3,type=4,star=30,value=150};
get_wash_value(2,5,30) -> 
    #ets_wash_value{level=2,type=5,star=30,value=120};
get_wash_value(3,5,30) -> 
    #ets_wash_value{level=3,type=5,star=30,value=120};
get_wash_value(2,6,30) -> 
    #ets_wash_value{level=2,type=6,star=30,value=120};
get_wash_value(3,6,30) -> 
    #ets_wash_value{level=3,type=6,star=30,value=120};
get_wash_value(2,7,30) -> 
    #ets_wash_value{level=2,type=7,star=30,value=30};
get_wash_value(3,7,30) -> 
    #ets_wash_value{level=3,type=7,star=30,value=30};
get_wash_value(2,8,30) -> 
    #ets_wash_value{level=2,type=8,star=30,value=90};
get_wash_value(3,8,30) -> 
    #ets_wash_value{level=3,type=8,star=30,value=90};
get_wash_value(2,13,30) -> 
    #ets_wash_value{level=2,type=13,star=30,value=360};
get_wash_value(3,13,30) -> 
    #ets_wash_value{level=3,type=13,star=30,value=360};
get_wash_value(2,14,30) -> 
    #ets_wash_value{level=2,type=14,star=30,value=360};
get_wash_value(3,14,30) -> 
    #ets_wash_value{level=3,type=14,star=30,value=360};
get_wash_value(2,15,30) -> 
    #ets_wash_value{level=2,type=15,star=30,value=360};
get_wash_value(3,15,30) -> 
    #ets_wash_value{level=3,type=15,star=30,value=360};
get_wash_value(2,1,31) -> 
    #ets_wash_value{level=2,type=1,star=31,value=992};
get_wash_value(3,1,31) -> 
    #ets_wash_value{level=3,type=1,star=31,value=992};
get_wash_value(2,2,31) -> 
    #ets_wash_value{level=2,type=2,star=31,value=124};
get_wash_value(3,2,31) -> 
    #ets_wash_value{level=3,type=2,star=31,value=124};
get_wash_value(2,3,31) -> 
    #ets_wash_value{level=2,type=3,star=31,value=93};
get_wash_value(3,3,31) -> 
    #ets_wash_value{level=3,type=3,star=31,value=93};
get_wash_value(2,4,31) -> 
    #ets_wash_value{level=2,type=4,star=31,value=155};
get_wash_value(3,4,31) -> 
    #ets_wash_value{level=3,type=4,star=31,value=155};
get_wash_value(2,5,31) -> 
    #ets_wash_value{level=2,type=5,star=31,value=124};
get_wash_value(3,5,31) -> 
    #ets_wash_value{level=3,type=5,star=31,value=124};
get_wash_value(2,6,31) -> 
    #ets_wash_value{level=2,type=6,star=31,value=124};
get_wash_value(3,6,31) -> 
    #ets_wash_value{level=3,type=6,star=31,value=124};
get_wash_value(2,7,31) -> 
    #ets_wash_value{level=2,type=7,star=31,value=31};
get_wash_value(3,7,31) -> 
    #ets_wash_value{level=3,type=7,star=31,value=31};
get_wash_value(2,8,31) -> 
    #ets_wash_value{level=2,type=8,star=31,value=93};
get_wash_value(3,8,31) -> 
    #ets_wash_value{level=3,type=8,star=31,value=93};
get_wash_value(2,13,31) -> 
    #ets_wash_value{level=2,type=13,star=31,value=372};
get_wash_value(3,13,31) -> 
    #ets_wash_value{level=3,type=13,star=31,value=372};
get_wash_value(2,14,31) -> 
    #ets_wash_value{level=2,type=14,star=31,value=372};
get_wash_value(3,14,31) -> 
    #ets_wash_value{level=3,type=14,star=31,value=372};
get_wash_value(2,15,31) -> 
    #ets_wash_value{level=2,type=15,star=31,value=372};
get_wash_value(3,15,31) -> 
    #ets_wash_value{level=3,type=15,star=31,value=372};
get_wash_value(2,1,32) -> 
    #ets_wash_value{level=2,type=1,star=32,value=1024};
get_wash_value(3,1,32) -> 
    #ets_wash_value{level=3,type=1,star=32,value=1024};
get_wash_value(2,2,32) -> 
    #ets_wash_value{level=2,type=2,star=32,value=128};
get_wash_value(3,2,32) -> 
    #ets_wash_value{level=3,type=2,star=32,value=128};
get_wash_value(2,3,32) -> 
    #ets_wash_value{level=2,type=3,star=32,value=96};
get_wash_value(3,3,32) -> 
    #ets_wash_value{level=3,type=3,star=32,value=96};
get_wash_value(2,4,32) -> 
    #ets_wash_value{level=2,type=4,star=32,value=160};
get_wash_value(3,4,32) -> 
    #ets_wash_value{level=3,type=4,star=32,value=160};
get_wash_value(2,5,32) -> 
    #ets_wash_value{level=2,type=5,star=32,value=128};
get_wash_value(3,5,32) -> 
    #ets_wash_value{level=3,type=5,star=32,value=128};
get_wash_value(2,6,32) -> 
    #ets_wash_value{level=2,type=6,star=32,value=128};
get_wash_value(3,6,32) -> 
    #ets_wash_value{level=3,type=6,star=32,value=128};
get_wash_value(2,7,32) -> 
    #ets_wash_value{level=2,type=7,star=32,value=32};
get_wash_value(3,7,32) -> 
    #ets_wash_value{level=3,type=7,star=32,value=32};
get_wash_value(2,8,32) -> 
    #ets_wash_value{level=2,type=8,star=32,value=96};
get_wash_value(3,8,32) -> 
    #ets_wash_value{level=3,type=8,star=32,value=96};
get_wash_value(2,13,32) -> 
    #ets_wash_value{level=2,type=13,star=32,value=384};
get_wash_value(3,13,32) -> 
    #ets_wash_value{level=3,type=13,star=32,value=384};
get_wash_value(2,14,32) -> 
    #ets_wash_value{level=2,type=14,star=32,value=384};
get_wash_value(3,14,32) -> 
    #ets_wash_value{level=3,type=14,star=32,value=384};
get_wash_value(2,15,32) -> 
    #ets_wash_value{level=2,type=15,star=32,value=384};
get_wash_value(3,15,32) -> 
    #ets_wash_value{level=3,type=15,star=32,value=384};
get_wash_value(2,1,33) -> 
    #ets_wash_value{level=2,type=1,star=33,value=1056};
get_wash_value(3,1,33) -> 
    #ets_wash_value{level=3,type=1,star=33,value=1056};
get_wash_value(2,2,33) -> 
    #ets_wash_value{level=2,type=2,star=33,value=132};
get_wash_value(3,2,33) -> 
    #ets_wash_value{level=3,type=2,star=33,value=132};
get_wash_value(2,3,33) -> 
    #ets_wash_value{level=2,type=3,star=33,value=99};
get_wash_value(3,3,33) -> 
    #ets_wash_value{level=3,type=3,star=33,value=99};
get_wash_value(2,4,33) -> 
    #ets_wash_value{level=2,type=4,star=33,value=165};
get_wash_value(3,4,33) -> 
    #ets_wash_value{level=3,type=4,star=33,value=165};
get_wash_value(2,5,33) -> 
    #ets_wash_value{level=2,type=5,star=33,value=132};
get_wash_value(3,5,33) -> 
    #ets_wash_value{level=3,type=5,star=33,value=132};
get_wash_value(2,6,33) -> 
    #ets_wash_value{level=2,type=6,star=33,value=132};
get_wash_value(3,6,33) -> 
    #ets_wash_value{level=3,type=6,star=33,value=132};
get_wash_value(2,7,33) -> 
    #ets_wash_value{level=2,type=7,star=33,value=33};
get_wash_value(3,7,33) -> 
    #ets_wash_value{level=3,type=7,star=33,value=33};
get_wash_value(2,8,33) -> 
    #ets_wash_value{level=2,type=8,star=33,value=99};
get_wash_value(3,8,33) -> 
    #ets_wash_value{level=3,type=8,star=33,value=99};
get_wash_value(2,13,33) -> 
    #ets_wash_value{level=2,type=13,star=33,value=396};
get_wash_value(3,13,33) -> 
    #ets_wash_value{level=3,type=13,star=33,value=396};
get_wash_value(2,14,33) -> 
    #ets_wash_value{level=2,type=14,star=33,value=396};
get_wash_value(3,14,33) -> 
    #ets_wash_value{level=3,type=14,star=33,value=396};
get_wash_value(2,15,33) -> 
    #ets_wash_value{level=2,type=15,star=33,value=396};
get_wash_value(3,15,33) -> 
    #ets_wash_value{level=3,type=15,star=33,value=396};
get_wash_value(2,1,34) -> 
    #ets_wash_value{level=2,type=1,star=34,value=1088};
get_wash_value(3,1,34) -> 
    #ets_wash_value{level=3,type=1,star=34,value=1088};
get_wash_value(2,2,34) -> 
    #ets_wash_value{level=2,type=2,star=34,value=136};
get_wash_value(3,2,34) -> 
    #ets_wash_value{level=3,type=2,star=34,value=136};
get_wash_value(2,3,34) -> 
    #ets_wash_value{level=2,type=3,star=34,value=102};
get_wash_value(3,3,34) -> 
    #ets_wash_value{level=3,type=3,star=34,value=102};
get_wash_value(2,4,34) -> 
    #ets_wash_value{level=2,type=4,star=34,value=170};
get_wash_value(3,4,34) -> 
    #ets_wash_value{level=3,type=4,star=34,value=170};
get_wash_value(2,5,34) -> 
    #ets_wash_value{level=2,type=5,star=34,value=136};
get_wash_value(3,5,34) -> 
    #ets_wash_value{level=3,type=5,star=34,value=136};
get_wash_value(2,6,34) -> 
    #ets_wash_value{level=2,type=6,star=34,value=136};
get_wash_value(3,6,34) -> 
    #ets_wash_value{level=3,type=6,star=34,value=136};
get_wash_value(2,7,34) -> 
    #ets_wash_value{level=2,type=7,star=34,value=34};
get_wash_value(3,7,34) -> 
    #ets_wash_value{level=3,type=7,star=34,value=34};
get_wash_value(2,8,34) -> 
    #ets_wash_value{level=2,type=8,star=34,value=102};
get_wash_value(3,8,34) -> 
    #ets_wash_value{level=3,type=8,star=34,value=102};
get_wash_value(2,13,34) -> 
    #ets_wash_value{level=2,type=13,star=34,value=408};
get_wash_value(3,13,34) -> 
    #ets_wash_value{level=3,type=13,star=34,value=408};
get_wash_value(2,14,34) -> 
    #ets_wash_value{level=2,type=14,star=34,value=408};
get_wash_value(3,14,34) -> 
    #ets_wash_value{level=3,type=14,star=34,value=408};
get_wash_value(2,15,34) -> 
    #ets_wash_value{level=2,type=15,star=34,value=408};
get_wash_value(3,15,34) -> 
    #ets_wash_value{level=3,type=15,star=34,value=408};
get_wash_value(2,1,35) -> 
    #ets_wash_value{level=2,type=1,star=35,value=1120};
get_wash_value(3,1,35) -> 
    #ets_wash_value{level=3,type=1,star=35,value=1120};
get_wash_value(2,2,35) -> 
    #ets_wash_value{level=2,type=2,star=35,value=140};
get_wash_value(3,2,35) -> 
    #ets_wash_value{level=3,type=2,star=35,value=140};
get_wash_value(2,3,35) -> 
    #ets_wash_value{level=2,type=3,star=35,value=105};
get_wash_value(3,3,35) -> 
    #ets_wash_value{level=3,type=3,star=35,value=105};
get_wash_value(2,4,35) -> 
    #ets_wash_value{level=2,type=4,star=35,value=175};
get_wash_value(3,4,35) -> 
    #ets_wash_value{level=3,type=4,star=35,value=175};
get_wash_value(2,5,35) -> 
    #ets_wash_value{level=2,type=5,star=35,value=140};
get_wash_value(3,5,35) -> 
    #ets_wash_value{level=3,type=5,star=35,value=140};
get_wash_value(2,6,35) -> 
    #ets_wash_value{level=2,type=6,star=35,value=140};
get_wash_value(3,6,35) -> 
    #ets_wash_value{level=3,type=6,star=35,value=140};
get_wash_value(2,7,35) -> 
    #ets_wash_value{level=2,type=7,star=35,value=35};
get_wash_value(3,7,35) -> 
    #ets_wash_value{level=3,type=7,star=35,value=35};
get_wash_value(2,8,35) -> 
    #ets_wash_value{level=2,type=8,star=35,value=105};
get_wash_value(3,8,35) -> 
    #ets_wash_value{level=3,type=8,star=35,value=105};
get_wash_value(2,13,35) -> 
    #ets_wash_value{level=2,type=13,star=35,value=420};
get_wash_value(3,13,35) -> 
    #ets_wash_value{level=3,type=13,star=35,value=420};
get_wash_value(2,14,35) -> 
    #ets_wash_value{level=2,type=14,star=35,value=420};
get_wash_value(3,14,35) -> 
    #ets_wash_value{level=3,type=14,star=35,value=420};
get_wash_value(2,15,35) -> 
    #ets_wash_value{level=2,type=15,star=35,value=420};
get_wash_value(3,15,35) -> 
    #ets_wash_value{level=3,type=15,star=35,value=420};
get_wash_value(3,1,36) -> 
    #ets_wash_value{level=3,type=1,star=36,value=1152};
get_wash_value(3,2,36) -> 
    #ets_wash_value{level=3,type=2,star=36,value=144};
get_wash_value(3,3,36) -> 
    #ets_wash_value{level=3,type=3,star=36,value=108};
get_wash_value(3,4,36) -> 
    #ets_wash_value{level=3,type=4,star=36,value=180};
get_wash_value(3,5,36) -> 
    #ets_wash_value{level=3,type=5,star=36,value=144};
get_wash_value(3,6,36) -> 
    #ets_wash_value{level=3,type=6,star=36,value=144};
get_wash_value(3,7,36) -> 
    #ets_wash_value{level=3,type=7,star=36,value=36};
get_wash_value(3,8,36) -> 
    #ets_wash_value{level=3,type=8,star=36,value=108};
get_wash_value(3,13,36) -> 
    #ets_wash_value{level=3,type=13,star=36,value=432};
get_wash_value(3,14,36) -> 
    #ets_wash_value{level=3,type=14,star=36,value=432};
get_wash_value(3,15,36) -> 
    #ets_wash_value{level=3,type=15,star=36,value=432};
get_wash_value(3,1,37) -> 
    #ets_wash_value{level=3,type=1,star=37,value=1184};
get_wash_value(3,2,37) -> 
    #ets_wash_value{level=3,type=2,star=37,value=148};
get_wash_value(3,3,37) -> 
    #ets_wash_value{level=3,type=3,star=37,value=111};
get_wash_value(3,4,37) -> 
    #ets_wash_value{level=3,type=4,star=37,value=185};
get_wash_value(3,5,37) -> 
    #ets_wash_value{level=3,type=5,star=37,value=148};
get_wash_value(3,6,37) -> 
    #ets_wash_value{level=3,type=6,star=37,value=148};
get_wash_value(3,7,37) -> 
    #ets_wash_value{level=3,type=7,star=37,value=37};
get_wash_value(3,8,37) -> 
    #ets_wash_value{level=3,type=8,star=37,value=111};
get_wash_value(3,13,37) -> 
    #ets_wash_value{level=3,type=13,star=37,value=444};
get_wash_value(3,14,37) -> 
    #ets_wash_value{level=3,type=14,star=37,value=444};
get_wash_value(3,15,37) -> 
    #ets_wash_value{level=3,type=15,star=37,value=444};
get_wash_value(3,1,38) -> 
    #ets_wash_value{level=3,type=1,star=38,value=1216};
get_wash_value(3,2,38) -> 
    #ets_wash_value{level=3,type=2,star=38,value=152};
get_wash_value(3,3,38) -> 
    #ets_wash_value{level=3,type=3,star=38,value=114};
get_wash_value(3,4,38) -> 
    #ets_wash_value{level=3,type=4,star=38,value=190};
get_wash_value(3,5,38) -> 
    #ets_wash_value{level=3,type=5,star=38,value=152};
get_wash_value(3,6,38) -> 
    #ets_wash_value{level=3,type=6,star=38,value=152};
get_wash_value(3,7,38) -> 
    #ets_wash_value{level=3,type=7,star=38,value=38};
get_wash_value(3,8,38) -> 
    #ets_wash_value{level=3,type=8,star=38,value=114};
get_wash_value(3,13,38) -> 
    #ets_wash_value{level=3,type=13,star=38,value=456};
get_wash_value(3,14,38) -> 
    #ets_wash_value{level=3,type=14,star=38,value=456};
get_wash_value(3,15,38) -> 
    #ets_wash_value{level=3,type=15,star=38,value=456};
get_wash_value(3,1,39) -> 
    #ets_wash_value{level=3,type=1,star=39,value=1248};
get_wash_value(3,2,39) -> 
    #ets_wash_value{level=3,type=2,star=39,value=156};
get_wash_value(3,3,39) -> 
    #ets_wash_value{level=3,type=3,star=39,value=117};
get_wash_value(3,4,39) -> 
    #ets_wash_value{level=3,type=4,star=39,value=195};
get_wash_value(3,5,39) -> 
    #ets_wash_value{level=3,type=5,star=39,value=156};
get_wash_value(3,6,39) -> 
    #ets_wash_value{level=3,type=6,star=39,value=156};
get_wash_value(3,7,39) -> 
    #ets_wash_value{level=3,type=7,star=39,value=39};
get_wash_value(3,8,39) -> 
    #ets_wash_value{level=3,type=8,star=39,value=117};
get_wash_value(3,13,39) -> 
    #ets_wash_value{level=3,type=13,star=39,value=468};
get_wash_value(3,14,39) -> 
    #ets_wash_value{level=3,type=14,star=39,value=468};
get_wash_value(3,15,39) -> 
    #ets_wash_value{level=3,type=15,star=39,value=468};
get_wash_value(3,1,40) -> 
    #ets_wash_value{level=3,type=1,star=40,value=1280};
get_wash_value(3,2,40) -> 
    #ets_wash_value{level=3,type=2,star=40,value=160};
get_wash_value(3,3,40) -> 
    #ets_wash_value{level=3,type=3,star=40,value=120};
get_wash_value(3,4,40) -> 
    #ets_wash_value{level=3,type=4,star=40,value=200};
get_wash_value(3,5,40) -> 
    #ets_wash_value{level=3,type=5,star=40,value=160};
get_wash_value(3,6,40) -> 
    #ets_wash_value{level=3,type=6,star=40,value=160};
get_wash_value(3,7,40) -> 
    #ets_wash_value{level=3,type=7,star=40,value=40};
get_wash_value(3,8,40) -> 
    #ets_wash_value{level=3,type=8,star=40,value=120};
get_wash_value(3,13,40) -> 
    #ets_wash_value{level=3,type=13,star=40,value=480};
get_wash_value(3,14,40) -> 
    #ets_wash_value{level=3,type=14,star=40,value=480};
get_wash_value(3,15,40) -> 
    #ets_wash_value{level=3,type=15,star=40,value=480};
get_wash_value(3,1,41) -> 
    #ets_wash_value{level=3,type=1,star=41,value=1312};
get_wash_value(3,2,41) -> 
    #ets_wash_value{level=3,type=2,star=41,value=164};
get_wash_value(3,3,41) -> 
    #ets_wash_value{level=3,type=3,star=41,value=123};
get_wash_value(3,4,41) -> 
    #ets_wash_value{level=3,type=4,star=41,value=205};
get_wash_value(3,5,41) -> 
    #ets_wash_value{level=3,type=5,star=41,value=164};
get_wash_value(3,6,41) -> 
    #ets_wash_value{level=3,type=6,star=41,value=164};
get_wash_value(3,7,41) -> 
    #ets_wash_value{level=3,type=7,star=41,value=41};
get_wash_value(3,8,41) -> 
    #ets_wash_value{level=3,type=8,star=41,value=123};
get_wash_value(3,13,41) -> 
    #ets_wash_value{level=3,type=13,star=41,value=492};
get_wash_value(3,14,41) -> 
    #ets_wash_value{level=3,type=14,star=41,value=492};
get_wash_value(3,15,41) -> 
    #ets_wash_value{level=3,type=15,star=41,value=492};
get_wash_value(3,1,42) -> 
    #ets_wash_value{level=3,type=1,star=42,value=1344};
get_wash_value(3,2,42) -> 
    #ets_wash_value{level=3,type=2,star=42,value=168};
get_wash_value(3,3,42) -> 
    #ets_wash_value{level=3,type=3,star=42,value=126};
get_wash_value(3,4,42) -> 
    #ets_wash_value{level=3,type=4,star=42,value=210};
get_wash_value(3,5,42) -> 
    #ets_wash_value{level=3,type=5,star=42,value=168};
get_wash_value(3,6,42) -> 
    #ets_wash_value{level=3,type=6,star=42,value=168};
get_wash_value(3,7,42) -> 
    #ets_wash_value{level=3,type=7,star=42,value=42};
get_wash_value(3,8,42) -> 
    #ets_wash_value{level=3,type=8,star=42,value=126};
get_wash_value(3,13,42) -> 
    #ets_wash_value{level=3,type=13,star=42,value=504};
get_wash_value(3,14,42) -> 
    #ets_wash_value{level=3,type=14,star=42,value=504};
get_wash_value(3,15,42) -> 
    #ets_wash_value{level=3,type=15,star=42,value=504};
get_wash_value(3,1,43) -> 
    #ets_wash_value{level=3,type=1,star=43,value=1376};
get_wash_value(3,2,43) -> 
    #ets_wash_value{level=3,type=2,star=43,value=172};
get_wash_value(3,3,43) -> 
    #ets_wash_value{level=3,type=3,star=43,value=129};
get_wash_value(3,4,43) -> 
    #ets_wash_value{level=3,type=4,star=43,value=215};
get_wash_value(3,5,43) -> 
    #ets_wash_value{level=3,type=5,star=43,value=172};
get_wash_value(3,6,43) -> 
    #ets_wash_value{level=3,type=6,star=43,value=172};
get_wash_value(3,7,43) -> 
    #ets_wash_value{level=3,type=7,star=43,value=43};
get_wash_value(3,8,43) -> 
    #ets_wash_value{level=3,type=8,star=43,value=129};
get_wash_value(3,13,43) -> 
    #ets_wash_value{level=3,type=13,star=43,value=516};
get_wash_value(3,14,43) -> 
    #ets_wash_value{level=3,type=14,star=43,value=516};
get_wash_value(3,15,43) -> 
    #ets_wash_value{level=3,type=15,star=43,value=516};
get_wash_value(3,1,44) -> 
    #ets_wash_value{level=3,type=1,star=44,value=1408};
get_wash_value(3,2,44) -> 
    #ets_wash_value{level=3,type=2,star=44,value=176};
get_wash_value(3,3,44) -> 
    #ets_wash_value{level=3,type=3,star=44,value=132};
get_wash_value(3,4,44) -> 
    #ets_wash_value{level=3,type=4,star=44,value=220};
get_wash_value(3,5,44) -> 
    #ets_wash_value{level=3,type=5,star=44,value=176};
get_wash_value(3,6,44) -> 
    #ets_wash_value{level=3,type=6,star=44,value=176};
get_wash_value(3,7,44) -> 
    #ets_wash_value{level=3,type=7,star=44,value=44};
get_wash_value(3,8,44) -> 
    #ets_wash_value{level=3,type=8,star=44,value=132};
get_wash_value(3,13,44) -> 
    #ets_wash_value{level=3,type=13,star=44,value=528};
get_wash_value(3,14,44) -> 
    #ets_wash_value{level=3,type=14,star=44,value=528};
get_wash_value(3,15,44) -> 
    #ets_wash_value{level=3,type=15,star=44,value=528};
get_wash_value(3,1,45) -> 
    #ets_wash_value{level=3,type=1,star=45,value=1440};
get_wash_value(3,2,45) -> 
    #ets_wash_value{level=3,type=2,star=45,value=180};
get_wash_value(3,3,45) -> 
    #ets_wash_value{level=3,type=3,star=45,value=135};
get_wash_value(3,4,45) -> 
    #ets_wash_value{level=3,type=4,star=45,value=225};
get_wash_value(3,5,45) -> 
    #ets_wash_value{level=3,type=5,star=45,value=180};
get_wash_value(3,6,45) -> 
    #ets_wash_value{level=3,type=6,star=45,value=180};
get_wash_value(3,7,45) -> 
    #ets_wash_value{level=3,type=7,star=45,value=45};
get_wash_value(3,8,45) -> 
    #ets_wash_value{level=3,type=8,star=45,value=135};
get_wash_value(3,13,45) -> 
    #ets_wash_value{level=3,type=13,star=45,value=540};
get_wash_value(3,14,45) -> 
    #ets_wash_value{level=3,type=14,star=45,value=540};
get_wash_value(3,15,45) -> 
    #ets_wash_value{level=3,type=15,star=45,value=540};
get_wash_value(_,_,_) -> [].



get_wash_color(1,3) -> 
    #ets_wash_color{level=1,star=3,color=1};
get_wash_color(1,4) -> 
    #ets_wash_color{level=1,star=4,color=1};
get_wash_color(1,5) -> 
    #ets_wash_color{level=1,star=5,color=1};
get_wash_color(1,6) -> 
    #ets_wash_color{level=1,star=6,color=1};
get_wash_color(1,7) -> 
    #ets_wash_color{level=1,star=7,color=1};
get_wash_color(1,8) -> 
    #ets_wash_color{level=1,star=8,color=1};
get_wash_color(1,9) -> 
    #ets_wash_color{level=1,star=9,color=1};
get_wash_color(1,10) -> 
    #ets_wash_color{level=1,star=10,color=1};
get_wash_color(1,11) -> 
    #ets_wash_color{level=1,star=11,color=1};
get_wash_color(1,12) -> 
    #ets_wash_color{level=1,star=12,color=1};
get_wash_color(1,13) -> 
    #ets_wash_color{level=1,star=13,color=1};
get_wash_color(1,14) -> 
    #ets_wash_color{level=1,star=14,color=1};
get_wash_color(1,15) -> 
    #ets_wash_color{level=1,star=15,color=2};
get_wash_color(1,16) -> 
    #ets_wash_color{level=1,star=16,color=2};
get_wash_color(1,17) -> 
    #ets_wash_color{level=1,star=17,color=2};
get_wash_color(1,18) -> 
    #ets_wash_color{level=1,star=18,color=2};
get_wash_color(1,19) -> 
    #ets_wash_color{level=1,star=19,color=2};
get_wash_color(1,20) -> 
    #ets_wash_color{level=1,star=20,color=2};
get_wash_color(1,21) -> 
    #ets_wash_color{level=1,star=21,color=2};
get_wash_color(1,22) -> 
    #ets_wash_color{level=1,star=22,color=3};
get_wash_color(1,23) -> 
    #ets_wash_color{level=1,star=23,color=3};
get_wash_color(1,24) -> 
    #ets_wash_color{level=1,star=24,color=3};
get_wash_color(1,25) -> 
    #ets_wash_color{level=1,star=25,color=4};
get_wash_color(2,7) -> 
    #ets_wash_color{level=2,star=7,color=1};
get_wash_color(2,8) -> 
    #ets_wash_color{level=2,star=8,color=1};
get_wash_color(2,9) -> 
    #ets_wash_color{level=2,star=9,color=1};
get_wash_color(2,10) -> 
    #ets_wash_color{level=2,star=10,color=1};
get_wash_color(2,11) -> 
    #ets_wash_color{level=2,star=11,color=1};
get_wash_color(2,12) -> 
    #ets_wash_color{level=2,star=12,color=1};
get_wash_color(2,13) -> 
    #ets_wash_color{level=2,star=13,color=1};
get_wash_color(2,14) -> 
    #ets_wash_color{level=2,star=14,color=1};
get_wash_color(2,15) -> 
    #ets_wash_color{level=2,star=15,color=1};
get_wash_color(2,16) -> 
    #ets_wash_color{level=2,star=16,color=1};
get_wash_color(2,17) -> 
    #ets_wash_color{level=2,star=17,color=1};
get_wash_color(2,18) -> 
    #ets_wash_color{level=2,star=18,color=1};
get_wash_color(2,19) -> 
    #ets_wash_color{level=2,star=19,color=1};
get_wash_color(2,20) -> 
    #ets_wash_color{level=2,star=20,color=1};
get_wash_color(2,21) -> 
    #ets_wash_color{level=2,star=21,color=2};
get_wash_color(2,22) -> 
    #ets_wash_color{level=2,star=22,color=2};
get_wash_color(2,23) -> 
    #ets_wash_color{level=2,star=23,color=2};
get_wash_color(2,24) -> 
    #ets_wash_color{level=2,star=24,color=2};
get_wash_color(2,25) -> 
    #ets_wash_color{level=2,star=25,color=2};
get_wash_color(2,26) -> 
    #ets_wash_color{level=2,star=26,color=2};
get_wash_color(2,27) -> 
    #ets_wash_color{level=2,star=27,color=2};
get_wash_color(2,28) -> 
    #ets_wash_color{level=2,star=28,color=2};
get_wash_color(2,29) -> 
    #ets_wash_color{level=2,star=29,color=2};
get_wash_color(2,30) -> 
    #ets_wash_color{level=2,star=30,color=2};
get_wash_color(2,31) -> 
    #ets_wash_color{level=2,star=31,color=3};
get_wash_color(2,32) -> 
    #ets_wash_color{level=2,star=32,color=3};
get_wash_color(2,33) -> 
    #ets_wash_color{level=2,star=33,color=3};
get_wash_color(2,34) -> 
    #ets_wash_color{level=2,star=34,color=3};
get_wash_color(2,35) -> 
    #ets_wash_color{level=2,star=35,color=4};
get_wash_color(3,10) -> 
    #ets_wash_color{level=3,star=10,color=1};
get_wash_color(3,11) -> 
    #ets_wash_color{level=3,star=11,color=1};
get_wash_color(3,12) -> 
    #ets_wash_color{level=3,star=12,color=1};
get_wash_color(3,13) -> 
    #ets_wash_color{level=3,star=13,color=1};
get_wash_color(3,14) -> 
    #ets_wash_color{level=3,star=14,color=1};
get_wash_color(3,15) -> 
    #ets_wash_color{level=3,star=15,color=1};
get_wash_color(3,16) -> 
    #ets_wash_color{level=3,star=16,color=1};
get_wash_color(3,17) -> 
    #ets_wash_color{level=3,star=17,color=1};
get_wash_color(3,18) -> 
    #ets_wash_color{level=3,star=18,color=1};
get_wash_color(3,19) -> 
    #ets_wash_color{level=3,star=19,color=1};
get_wash_color(3,20) -> 
    #ets_wash_color{level=3,star=20,color=1};
get_wash_color(3,21) -> 
    #ets_wash_color{level=3,star=21,color=1};
get_wash_color(3,22) -> 
    #ets_wash_color{level=3,star=22,color=1};
get_wash_color(3,23) -> 
    #ets_wash_color{level=3,star=23,color=1};
get_wash_color(3,24) -> 
    #ets_wash_color{level=3,star=24,color=1};
get_wash_color(3,25) -> 
    #ets_wash_color{level=3,star=25,color=1};
get_wash_color(3,26) -> 
    #ets_wash_color{level=3,star=26,color=1};
get_wash_color(3,27) -> 
    #ets_wash_color{level=3,star=27,color=1};
get_wash_color(3,28) -> 
    #ets_wash_color{level=3,star=28,color=2};
get_wash_color(3,29) -> 
    #ets_wash_color{level=3,star=29,color=2};
get_wash_color(3,30) -> 
    #ets_wash_color{level=3,star=30,color=2};
get_wash_color(3,31) -> 
    #ets_wash_color{level=3,star=31,color=2};
get_wash_color(3,32) -> 
    #ets_wash_color{level=3,star=32,color=2};
get_wash_color(3,33) -> 
    #ets_wash_color{level=3,star=33,color=2};
get_wash_color(3,34) -> 
    #ets_wash_color{level=3,star=34,color=2};
get_wash_color(3,35) -> 
    #ets_wash_color{level=3,star=35,color=2};
get_wash_color(3,36) -> 
    #ets_wash_color{level=3,star=36,color=2};
get_wash_color(3,37) -> 
    #ets_wash_color{level=3,star=37,color=2};
get_wash_color(3,38) -> 
    #ets_wash_color{level=3,star=38,color=2};
get_wash_color(3,39) -> 
    #ets_wash_color{level=3,star=39,color=2};
get_wash_color(3,40) -> 
    #ets_wash_color{level=3,star=40,color=3};
get_wash_color(3,41) -> 
    #ets_wash_color{level=3,star=41,color=3};
get_wash_color(3,42) -> 
    #ets_wash_color{level=3,star=42,color=3};
get_wash_color(3,43) -> 
    #ets_wash_color{level=3,star=43,color=3};
get_wash_color(3,44) -> 
    #ets_wash_color{level=3,star=44,color=3};
get_wash_color(3,45) -> 
    #ets_wash_color{level=3,star=45,color=4};
get_wash_color(_, _) ->
    [].



get_wash_value_rang(1,1) -> 
    #ets_wash_value_rang{level=1,type=1,rang={96,800}};
get_wash_value_rang(1,2) -> 
    #ets_wash_value_rang{level=1,type=2,rang={12,100}};
get_wash_value_rang(1,3) -> 
    #ets_wash_value_rang{level=1,type=3,rang={9,75}};
get_wash_value_rang(1,4) -> 
    #ets_wash_value_rang{level=1,type=4,rang={15,125}};
get_wash_value_rang(1,5) -> 
    #ets_wash_value_rang{level=1,type=5,rang={12,100}};
get_wash_value_rang(1,6) -> 
    #ets_wash_value_rang{level=1,type=6,rang={12,100}};
get_wash_value_rang(1,7) -> 
    #ets_wash_value_rang{level=1,type=7,rang={3,25}};
get_wash_value_rang(1,8) -> 
    #ets_wash_value_rang{level=1,type=8,rang={9,75}};
get_wash_value_rang(1,13) -> 
    #ets_wash_value_rang{level=1,type=13,rang={36,300}};
get_wash_value_rang(1,14) -> 
    #ets_wash_value_rang{level=1,type=14,rang={36,300}};
get_wash_value_rang(1,15) -> 
    #ets_wash_value_rang{level=1,type=15,rang={36,300}};
get_wash_value_rang(2,1) -> 
    #ets_wash_value_rang{level=2,type=1,rang={224,1120}};
get_wash_value_rang(2,2) -> 
    #ets_wash_value_rang{level=2,type=2,rang={28,140}};
get_wash_value_rang(2,3) -> 
    #ets_wash_value_rang{level=2,type=3,rang={21,105}};
get_wash_value_rang(2,4) -> 
    #ets_wash_value_rang{level=2,type=4,rang={35,175}};
get_wash_value_rang(2,5) -> 
    #ets_wash_value_rang{level=2,type=5,rang={28,140}};
get_wash_value_rang(2,6) -> 
    #ets_wash_value_rang{level=2,type=6,rang={28,140}};
get_wash_value_rang(2,7) -> 
    #ets_wash_value_rang{level=2,type=7,rang={7,35}};
get_wash_value_rang(2,8) -> 
    #ets_wash_value_rang{level=2,type=8,rang={21,105}};
get_wash_value_rang(2,13) -> 
    #ets_wash_value_rang{level=2,type=13,rang={84,420}};
get_wash_value_rang(2,14) -> 
    #ets_wash_value_rang{level=2,type=14,rang={84,420}};
get_wash_value_rang(2,15) -> 
    #ets_wash_value_rang{level=2,type=15,rang={84,420}};
get_wash_value_rang(3,1) -> 
    #ets_wash_value_rang{level=3,type=1,rang={320,1440}};
get_wash_value_rang(3,2) -> 
    #ets_wash_value_rang{level=3,type=2,rang={40,180}};
get_wash_value_rang(3,3) -> 
    #ets_wash_value_rang{level=3,type=3,rang={30,135}};
get_wash_value_rang(3,4) -> 
    #ets_wash_value_rang{level=3,type=4,rang={50,225}};
get_wash_value_rang(3,5) -> 
    #ets_wash_value_rang{level=3,type=5,rang={40,180}};
get_wash_value_rang(3,6) -> 
    #ets_wash_value_rang{level=3,type=6,rang={40,180}};
get_wash_value_rang(3,7) -> 
    #ets_wash_value_rang{level=3,type=7,rang={10,45}};
get_wash_value_rang(3,8) -> 
    #ets_wash_value_rang{level=3,type=8,rang={30,135}};
get_wash_value_rang(3,13) -> 
    #ets_wash_value_rang{level=3,type=13,rang={120,540}};
get_wash_value_rang(3,14) -> 
    #ets_wash_value_rang{level=3,type=14,rang={120,540}};
get_wash_value_rang(3,15) -> 
    #ets_wash_value_rang{level=3,type=15,rang={120,540}};
get_wash_value_rang(_, _) ->
    [].

