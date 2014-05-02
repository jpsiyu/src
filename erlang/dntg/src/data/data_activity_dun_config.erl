%%------------------------------------------------------------------------------
%%% @Module  : data_activity_dun_config
%%% @Author  : liangjianxiong
%%% @Email   : ljianxiong@qq.com
%%% @Created : 2013.3.5
%%% @Description: 活动副本配置
%%------------------------------------------------------------------------------


-module(data_activity_dun_config).


%% 公共函数：外部模块调用.
-export([
		 get_mon_score/1           %% 得到怪物的积分.
]).

%% 得到怪物的积分.
get_mon_score(MonId)->
	case MonId of
		98102 -> 300;
		98103 -> 600;
		98104 -> 1200;
		98123 -> 2000;
		_ -> undefined
	end.
