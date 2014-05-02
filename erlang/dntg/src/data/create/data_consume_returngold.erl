%%%---------------------------------------
%% Author: Administrator
%% Created: 
%% Description: TODO: 消费返元宝
-module(data_consume_returngold).
-compile(export_all).

%% 活动是否正在开启
is_openning() ->
	NowTime = util:unixtime(),
	OpenDay = util:get_open_day(),
	[NeedOpenday, StartTime, EndTime|_] = all_data(),
	OpenDay>=NeedOpenday andalso  NowTime>=StartTime andalso NowTime<EndTime.

%% 获取活动时间
get_time() ->
	[_, StartTime, EndTime|_] = all_data(),
	[StartTime, EndTime].

%% 获取可领取红包起始时间
get_fetch_time() ->
	[_,_,_,_,_,FetchTime] =all_data(),
	FetchTime.

%% 消费类型是否开启
%% @Param Type 消费类型
%% @return true 开始| false 不开启
consume_is_open(Type) ->
	[_, _, _, ConsumeList|_] = all_data(),
	Res = lists:keyfind(Type, 1, ConsumeList),
	case Res=:=false of
		true -> false;
		false ->
			{_, Flag} = Res,
			case Flag=:=1 of
				true -> true;
				false -> false
			end
	end.

%% 获取返还数据
get_return_config() ->
	[_, _, _, _,ReturnData|_] = all_data(),
	ReturnData.

%% 基础数据
%% @消费类型: param taobao(淘宝),shangcheng(商城),petcz(宠物成长),petqn(宠物潜能),petjn(神秘刷新+神秘购买),cmsd(财迷商店),marryxyan(结婚喜宴),marryxyou(结婚巡游),vipup(VIP升级
%% @[开服几天后有效, 活动开始时间, 活动结束时间, [消费开启状态], [消费返回元宝比例],红包领取起始时间]
%% @消费开启状态 [{taobao,1},{shangcheng,0}...] 
%%  0不开启|1开启
%% @消费返回元宝比例 [{88,10},{888,15}]
%%  88为消费额阶段1,10为千分之十
all_data()->
	[0,1360080000,1361203199,[{taobao,0},{shangcheng,1},{petcz,0},{petqn,0},{petjn,1},{cmsd,1},{marryxyan,0},{marryxyou,0},{vipup,0}],[{888,534198},{1888,534199}],1361030442].
