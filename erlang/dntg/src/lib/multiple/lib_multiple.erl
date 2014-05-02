%% Author: Administrator
%% Created: 2012-9-20
%% Description: TODO: Add description to lib_multiple
-module(lib_multiple).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([get_multiple_by_type/2,load/0]).

%%
%% API Functions
%%
%% 计算出来的倍数，默认是1倍
%% @param Type 
%%      1 黄金沙滩
%%      2 蝴蝶谷
%%      3 帮派战
%%      4 竞技场
%%      5 答题
%%      6 活跃度额外奖励
%% @param AllData 所有基础数据(按活动开始时间排序)，取值如下：
%%          #player_status.all_multiple_data
%% 			#unite_status.all_multiple_data
%%      当实在拿不到这两状态的时候，不频繁调用的情况下，用 mod_multiple:get_all_data()
%% @return int
get_multiple_by_type(_Type,[])->1;
get_multiple_by_type(Type,AllData)->
	NowTime = util:unixtime(),
	Buff_num_List = [Buff_num||[_Id,Buff_type,Buff_num,Start_time,End_time]<-AllData,
							   Start_time=<NowTime,
							   NowTime=<End_time,
							   Type=:=Buff_type],
	case Buff_num_List of
		[]->1;
		_-> %%获取第一个数据
			lists:nth(1, Buff_num_List)
	end.

load()->
	Sql = io_lib:format(<<"select * from base_game_buff where end_time>~p order by start_time">>,
						[util:unixtime()]),
	db:get_all(Sql).
	
%%
%% Local Functions
%%

