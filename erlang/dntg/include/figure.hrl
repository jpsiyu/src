%% ---------------------------------------------------------
%% Author:  
%% Email:   
%% Created: 
%% Description: 
%% --------------------------------------------------------

%% 变身buff 的Type 是97 AttributeId 也是97
-define(FIGURE_BUFF_TYPE, 97).			%% 类型
-define(FIGURE_BUFF_ATTID, 97).			%% 类型

-define(FIGURE_GOODS_1, 523000).			%% 类型
-define(FIGURE_GOODS_2, 523499).			%% 类型

%% 兑换记录
-record(figure, { goods_id = 0
				, figure = 0
				, time = 0
				, hp_lim = 0
				, att = 10
				, def = 0
				, speed = 0
				, hit = 0
				, dodge = 0
				, crit = 0
				, ten = 0
				, fire = 0
				, ice = 0
				, drug = 0 
				}).
