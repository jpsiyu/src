%%%---------------------------------------
%%% @Module  : data_xianyuan_sweetness
%%% @Author  : hekai
%%% @Created : 2012-10-17 
%%% @Description:  仙缘系统--使用甜蜜果获取甜蜜度配置
%%%---------------------------------------
-module(data_xianyuan_sweetness).
-compile(export_all).

%% 甜蜜度配置
get_sweetness_config(Sweetness) ->
	if  
		Sweetness >= 1400 ->
			[{10,1},{5,1},{2,1},{1,96}];
		Sweetness >= 1250 ->
			[{10,1},{5,1},{2,80},{1,16}];
		Sweetness >= 1150 ->
			[{50,1},{10,2},{5,80},{4,17}];
		Sweetness >= 1050 ->
			[{50,1},{10,80},{5,19}];
		Sweetness >= 1000 ->
			[{50,100}]								
	end.

%% 甜蜜果效果求值
%% @NSweetness 当前甜蜜度
get_sweetness(NSweetness)->
	SweetnessConfig = get_sweetness_config(NSweetness),
    Sum = lists:foldl(fun({_, Probability}, Acc)-> Probability+Acc end, 0, SweetnessConfig),
    Rand = util:rand(1, Sum),	
    sweetness_loop(Rand, SweetnessConfig, 0).

sweetness_loop(_Rand, [], _Acc) ->
	2;
sweetness_loop(Rand, [H|T], Acc) ->
	{Sweetness_add, Probability} = H,
	if 
		Rand<Probability+Acc ->
			Sweetness_add;
		true ->
			sweetness_loop(Rand, T, Probability+Acc)
	end.
		
