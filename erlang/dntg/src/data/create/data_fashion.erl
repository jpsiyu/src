
%%%---------------------------------------
%%% @Module  : data_fashion
%%% @Author  : xhg
%%% @Email   : xuhuguang@gmail.com
%%% @Created : 2014-04-29 16:16:32
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_fashion).
-compile(export_all).
-include("goods.hrl").
get_fashion_stren(1) ->
    #fashion_stren{level=1,addition=15,figure=15,att=0,hit=0,crite=0,percent=[]};
get_fashion_stren(2) ->
    #fashion_stren{level=2,addition=30,figure=30,att=0,hit=0,crite=0,percent=[]};
get_fashion_stren(3) ->
    #fashion_stren{level=3,addition=45,figure=45,att=0,hit=0,crite=0,percent=[]};
get_fashion_stren(4) ->
    #fashion_stren{level=4,addition=60,figure=60,att=0,hit=0,crite=0,percent=[]};
get_fashion_stren(5) ->
    #fashion_stren{level=5,addition=75,figure=75,att=0,hit=0,crite=0,percent=[]};
get_fashion_stren(6) ->
    #fashion_stren{level=6,addition=100,figure=100,att=5,hit=5,crite=2,percent=[]};
get_fashion_stren(7) ->
    #fashion_stren{level=7,addition=125,figure=125,att=15,hit=15,crite=4,percent=[]};
get_fashion_stren(8) ->
    #fashion_stren{level=8,addition=150,figure=150,att=25,hit=25,crite=6,percent=[]};
get_fashion_stren(9) ->
    #fashion_stren{level=9,addition=175,figure=175,att=35,hit=35,crite=8,percent=[]};
get_fashion_stren(10) ->
    #fashion_stren{level=10,addition=200,figure=200,att=45,hit=45,crite=10,percent=[]};
get_fashion_stren(11) ->
    #fashion_stren{level=11,addition=250,figure=250,att=65,hit=65,crite=15,percent=[]};
get_fashion_stren(12) ->
    #fashion_stren{level=12,addition=300,figure=300,att=90,hit=90,crite=20,percent=[{53,1}]};
get_fashion_stren(_LEVEL) ->
[].
