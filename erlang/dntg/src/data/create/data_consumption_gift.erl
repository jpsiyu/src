%%%---------------------------------------
%% Author: Administrator
%% Created: 2014-04-29 16:16:32
%% Description: TODO: 活动消费返礼配置需求
-module(data_consumption_gift).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([get_element/0, all_data/0]).

%%
%% API Functions
%%
%%
%% Local Functions
%%
%%获取当前正在进行的活动
get_element()->
	NowTime = util:unixtime(),
	The_OpenDay = util:get_open_day(),
	All_Data = all_data(),
	Gifting_Data = [{OpenDay,BeginTime,EndTime,GiftList}||
					{OpenDay,BeginTime,EndTime,GiftList}<-All_Data,
					BeginTime=<NowTime,NowTime=<EndTime,
					OpenDay=<The_OpenDay],
	if
		length(Gifting_Data)>0->
			Sort_Gifting_Data = lists:sort(fun({_,A_BeginTime,_A_EndTime,_},{_,B_BeginTime,_B_EndTime,_})-> 
				if
					A_BeginTime=<B_BeginTime->false;
					true->true
				end
			end, Gifting_Data),
			{_,F_BeginTime,F_EndTime,F_GiftList} = lists:last(Sort_Gifting_Data),
			Element = {F_BeginTime,F_EndTime,F_GiftList};
		true->Element = []
	end,
	Element.

%% 所有基础数据
%% 消费类型：all、taobao、shangcheng、petcz、petqn
%% 元素格式：{开服后几天有效,活动开始时间,活动结束时间,[{条件序号,消费类型,消费额度,消费次数,奖励物品Id,物品数量},{条件序号,消费类型,消费额度,消费次数,奖励物品Id,物品数量}]}

all_data()->
			[{0,1364490000,1364918399,[{1,repeat,88888888,0,534238,1},{2,all,888,0,534213,1},{3,all,2888,0,534214,1},{4,all,4888,0,534215,1},{5,all,9888,0,534216,1},{6,all,16888,0,534217,1},{7,all,26888,0,534218,1}]}].
