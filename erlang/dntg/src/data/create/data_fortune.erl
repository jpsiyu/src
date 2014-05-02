%%%---------------------------------------
%%% @Module  : data_fortune
%%% @Author  : xhg
%%% @Email   : xuhuguang@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_fortune).
-compile(export_all).

%% 根据任务ID获取任务  
%% @return 任务类型, 日常ID, 数量, 名称 
 		get_task_info() -> 
 		[{1,1,3700002,150,"帮派砥柱"},{2,1,3700003,5,"帮派摇奖"},{3,1,3700004,1,"帮派商城"},{4,1,3700005,1,"限时抢购"},{5,1,3700006,1,"物美价廉"},{6,1,3700007,5,"铜钱天降"},{7,1,3700008,1,"活跃分子"},{8,1,3700010,1,"劫财劫色"},{9,1,3700012,1,"我淘我乐"}].
%% 根据颜色获取任务奖励
%% @param 颜色ID
%% @return 物品奖励数量 帮派资金 神兽成长值 经验 礼包ID
    	
    		get_color_prize(1,55) -> {1,0,0,12,0};
    		get_color_prize(1,60) -> {2,0,0,12,0};
    		get_color_prize(1,100) -> {3,0,0,12,0};
    		get_color_prize(2,55) -> {2,0,0,15,0};
    		get_color_prize(2,60) -> {3,0,0,15,0};
    		get_color_prize(2,100) -> {4,0,0,15,0};
    		get_color_prize(3,55) -> {3,0,0,17,0};
    		get_color_prize(3,60) -> {4,0,0,17,0};
    		get_color_prize(3,100) -> {5,0,0,17,0};
    		get_color_prize(4,55) -> {4,0,0,20,0};
    		get_color_prize(4,60) -> {5,0,0,20,0};
    		get_color_prize(4,100) -> {6,0,0,20,0};
    		get_color_prize(5,55) -> {5,0,0,25,0};
    		get_color_prize(5,60) -> {6,0,0,25,0};
    		get_color_prize(5,100) -> {7,0,0,25,0};
    	get_color_prize(_ColorId,_Lv) ->
    [].
