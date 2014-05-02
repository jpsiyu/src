%%%---------------------------------------
%%% @Module  : data_yunyouboss
%%% @Created : 2014-02-14 15:53:41
%% @Author  : xieyunfei
%% @Email   : xieyunfei@jieyoumail.com
%%% @Description:  云游BOSS配置
%%%---------------------------------------
-module(data_physical_gold).
-compile(export_all).
-include("physical.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([get_clear_cd_time_gold/1]).


get_clear_cd_time_gold(CostCumulate) ->
	#clear_cd_time_gold{
						cost_cumulate = _CostCumulate,
						cost_gold = CostGold
    		} = get_gold(CostCumulate),
	CostGold.
	
%%这里面参数是用元宝清除cd的次数（即cost_cumulate的次数），cost_gold是要扣的元宝数  

get_gold(1) ->
		#clear_cd_time_gold{
						cost_cumulate = 1,
						cost_gold = 5
    		};
get_gold(2) ->
		#clear_cd_time_gold{
						cost_cumulate = 2,
						cost_gold = 10
    		};
get_gold(3) ->
		#clear_cd_time_gold{
						cost_cumulate = 3,
						cost_gold = 15
    		};
get_gold(4) ->
		#clear_cd_time_gold{
						cost_cumulate = 4,
						cost_gold = 20
    		};
get_gold(5) ->
		#clear_cd_time_gold{
						cost_cumulate = 5,
						cost_gold = 25
    		};
get_gold(6) ->
		#clear_cd_time_gold{
						cost_cumulate = 6,
						cost_gold = 30
    		};

get_gold(_Id) ->
		#clear_cd_time_gold{
			cost_cumulate = 6,
			cost_gold = 30
    		}.
