%%%---------------------------------------
%% @Module  : data_activity_time
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.9.7
%% @Description: 活动开启时间
%%------------------------------------------------------------------------------
-module(data_activity_time).
-compile(export_all).

%% 获得活动开启时间.
%% @param Type 
%%      1 黄金沙滩
%%      2 蝴蝶谷
%%      3 帮派战
%%      4 竞技场
%%      5 答题
%%      6 活跃度额外奖励
%%      7 怪物攻城
%%      8 洗炼活动
%%      9 节日活动
%%      10 充值活动
%% @return int
get_activity_time(Type)->
	Data = get_data(Type),
	case Data of
		[]->
			false;
		_->
			NowTime = util:unixtime(),
			get_activity_time_sub(Data,NowTime)
	end.
get_activity_time_sub(Data,NowTime)->
	case Data of
		[]->
			false;
		[{_,BeginDate,EndDate}|T]->
			if
				BeginDate=<NowTime andalso NowTime=<EndDate->
					true;
				true->
					get_activity_time_sub(T,NowTime)
			end;
		[_|T]->
			get_activity_time_sub(T,NowTime)
	end.

%% 获取活动的开始和结束时间
get_time_by_type(Type) ->
	Result = lists:filter(fun({Id, _, _}) -> 
		Type == Id
	end, get_data()),
	case Result of
		[{_, Start, End}] -> [Start, End];
		_ -> []
	end.
	
%% @param Type 
%%      1 黄金沙滩
%%      2 蝴蝶谷
%%      3 帮派战
%%      4 竞技场
%%      5 答题
%%      6 活跃度额外奖励
%%      7 怪物攻城
%%      8 洗炼活动
%%      9 节日活动
%%      10 充值活动
%% @return [{类型,活动开始时间,活动截止时间}]
get_data(Type)->
	case Type of
	_->[]
	end.

%%获取所有活动时间配置数据
	get_data()->
	[].
