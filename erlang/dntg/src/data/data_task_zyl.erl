%%%------------------------------------------------
%%% File    : data_task_zyl
%%% Author  : hekai
%%% Created : 2012-07-31
%%% Description: 诛妖令配置
%%%------------------------------------------------
-module(data_task_zyl).
-compile(export_all).

get_task_config(Type, _Args) ->
    case Type of
        maxinum_trigger_daily -> 5;
        min_trigger_lv -> 30;
%%         "zyl_id_1" -> 671001;
%% 		"zyl_id_2" -> 671002;
%% 		"zyl_id_3" -> 671003;
%% 		"zyl_id_4" -> 671004
        "zyl_id_1" -> 671001;
        "zyl_id_2" -> 671001;
        "zyl_id_3" -> 671001;
        "zyl_id_4" -> 671001
    end.

%% 获取诛妖令经验
get_zyl_exp(Level, Type) ->
	%% 级别  品质  经验
	ExpInfo =
    [
    [3, 1, 10080],
    [3, 2, 14400],
    [3, 3, 18720],
    [3, 4, 23040],
    [4, 1, 22680],
    [4, 2, 32400],
    [4, 3, 42120],
    [4, 4, 51840],
    [5, 1, 33880],
    [5, 2, 48400],
    [5, 3, 62920],
    [5, 4, 77440],
    [6, 1, 47320],
    [6, 2, 67600],
    [6, 3, 87880],
    [6, 4, 108160],
    [7, 1, 53000],
    [7, 2, 90000],
    [7, 3, 117000],
    [7, 4, 144000]
    ],
    Exp = [Exp ||[_Level,_Type,Exp] <-ExpInfo, _Level =:= Level, _Type =:= Type],
    case Exp /=[] of
		true -> 
			[Exp1] = Exp,
		    Exp1;
		false -> 0
    end.

%% 获取诛妖令铜币
get_zyl_coin(Level, Type) ->
	%% 级别  品质  铜币
	CoinInfo =
    [
    [3, 1, 1640],
    [3, 2, 2000],
    [3, 3, 2680],
    [3, 4, 3180],
    [4, 1, 2460],
    [4, 2, 3000],
    [4, 3, 4020],
    [4, 4, 4770],
    [5, 1, 3280],
    [5, 2, 4000],
    [5, 3, 5360],
    [5, 4, 6360],
    [6, 1, 4510],
    [6, 2, 5500],
    [6, 3, 7370],
    [6, 4, 8745],
    [7, 1, 5904],
    [7, 2, 7200],
    [7, 3, 9648],
    [7, 4, 11448]
    ],
    Coin = [Coin ||[_Level,_Type,Coin] <-CoinInfo, _Level =:= Level, _Type =:= Type],
	case Coin /=[] of
		true -> 
			[Coin1] = Coin,
		    Coin1;
		false -> 0
    end.
    



