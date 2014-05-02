%%------------------------------------------------------------------------------
%% @Module  : pt_610
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.4.25
%% @Description: 基础副本和铜币副本协议定义
%%------------------------------------------------------------------------------

-module(pt_610).
-export([read/2, write/2]).
-include("server.hrl").
-include("scene.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%

%% 离开副本
read(61000, _) ->
	{ok, []};

%% 请求副本场景时间
read(61001, <<Q:32>>) ->
    {ok, Q};

%% 特殊副本场景剩余时间
read(61002, <<SceneResId:32>>) ->
    {ok, SceneResId};

%% 场景区域切换
read(61003, <<SceneId:32>>) ->
    {ok, SceneId};

%% 获取副本剩余次数.
read(61004, <<DungeonId:32>>) ->
    {ok, DungeonId};

%% 获取所有副本剩余次数.
read(61005, _) ->
    {ok, []};

%% 获取怪物的击杀统计
read(61007, <<SceneId:32>>) ->
    {ok, SceneId};

%% 获取所有副本累计次数.
read(61008, <<PlayerId:32>>) ->
    {ok, PlayerId};

%% 获取剧情副本通关奖励.
read(61009, _) ->
    {ok, []};

%% 领取剧情副本通关奖励.
read(61010, <<DungeonId:32>>) ->
    {ok, DungeonId};

%% 开始剧情副本挂机.
%read(61011, <<DungonCount:16, DungeonList/binary>>) ->
%    {ok, get_id_list(DungonCount, [DungeonList], [])};

%% 开始剧情副本（封魔录）挂机.
read(61011, <<DungeonId:32, AutoNum:8>>) ->
    {ok, [DungeonId, AutoNum]};
 
%% 停止剧情副本（封魔录）挂机.
read(61012, _) ->
    {ok, []};

%% 获取剧情副本（封魔录）挂机信息.
read(61013, _) ->
    {ok, []};

%% 获取剧情副本霸主.
read(61014, _) ->
    {ok, []};

%% 获取封魔录称号信息
read(61015, _) ->
    {ok, []};

%% 激活封魔录称号
read(61016, _) ->
    {ok, []};

%% 连连看副本开始刷怪.
read(61040, _) ->
    {ok, []};

%% 连连看副本更新积分.
read(61041, _) ->
    {ok, []};

%% 连连看副本清怪.
read(61044, _) ->
    {ok, []};

%% 新版钱多多副本副本信息.
read(61050, _) ->
    {ok, []};

%% 结束钱多多副本抽奖.
read(61052, _) ->
    {ok, []};

%% 拾取金币.
read(61053, <<MonCount:16, MonList/binary>>) ->	
    {ok, get_id_list(MonCount, [MonList], [])};

%% 拾取金币倒计时结束.
read(61055, _) ->
    {ok, []};

%% 重新登录获取钱多多信息.
read(61056, _) ->
    {ok, []};   

%% 活动副本得到积分.
read(61060, _) ->
    {ok, []};

%% 飞行副本更新积分.
read(61070, _) ->
    {ok, []};

%% 飞行副本更新星星.
read(61071, _) ->
    {ok, []};

%% 飞行副本查询难度.
read(61072, _) ->
    {ok, []};

%% 飞行副本显示计时.
read(61073, _) ->
    {ok, []};

%% 飞行副本更新阴阳BOSS值.
read(61074, _) ->
    {ok, []};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%% 发送副本场景时间
write(61001, [Time, Count]) ->
    {ok, pt:pack(61001, <<Time:32, Count:16>>)};

%% 特殊副本场景剩余时间
write(61002, Time) ->
    {ok, pt:pack(61002, <<Time:32>>)};
   
%% 场景区域切换
write(61003, [SceneId, AreaId]) ->
    {ok, pt:pack(61003, <<SceneId:32, AreaId:32>>)};

%% 获取副本剩余次数.
write(61004, [DungeonId, Count, CountLim]) ->
	{ok, pt:pack(61004, <<DungeonId:32, Count:16, CountLim:16>>)};
    
%% 获取所有副本剩余次数.
write(61005, [TotalScore, CountList]) ->
	Len = length(CountList),
	Fun = fun({DungeonId, Count, CountLim, CoolTime, Score, PassTime}) ->
            <<DungeonId:32, Count:16, CountLim:16, CoolTime:32, Score:16, PassTime:32>>
    end,
    NewCountList = list_to_binary([Fun(X) || X <- CountList]),
    {ok, pt:pack(61005, <<TotalScore:32, Len:16, NewCountList/binary>>)};   

%% 通关记录.
write(61006, [DungeonId, Level, IsNewRecord, TotalTimer, Layer, KillMon, TotalExp, TotalCoin, WHPT]) ->
    {ok, pt:pack(61006, <<DungeonId:32, Level:8, IsNewRecord:8, TotalTimer:32, 
						  Layer:8, KillMon:16, TotalExp:32, TotalCoin:32, WHPT:32>>)};
%% 获取怪物的击杀统计
write(61007, [Resutl, MonList]) ->
    Fun = fun([MonId, MonIcon, TotalCount, NowCount]) ->    
        <<MonId:32, MonIcon:32, TotalCount:16, NowCount:16>>
    end,
    BinList = list_to_binary([Fun(X) || X <- MonList]),
    Size  = length(MonList),
    {ok, pt:pack(61007, <<Resutl:8, Size:16, BinList/binary>>)};

%% 获取所有副本累计次数.
write(61008, [PlayerId, CountList]) ->
    Fun = fun({Dungeon, TotalCount}) ->    
        <<Dungeon:32, TotalCount:16>>
    end,
    BinList = list_to_binary([Fun(X) || X <- CountList]),
    Size  = length(CountList),
    {ok, pt:pack(61008, <<PlayerId:32, Size:16, BinList/binary>>)};

%% 获取剧情副本通关奖励.
write(61009, CountList) ->
    Fun = fun({DungeonId, GiftId, HaveGet}) ->    
        <<DungeonId:32, GiftId:32, HaveGet:8>>
    end,
    BinList = list_to_binary([Fun(X) || X <- CountList]),
    Size  = length(CountList),
    {ok, pt:pack(61009, <<Size:16, BinList/binary>>)};

%% 领取剧情副本通关奖励.
write(61010, Result) ->
    {ok, pt:pack(61010, <<Result:8>>)};

%% 开始剧情副本挂机.
write(61011, Result) ->
    {ok, pt:pack(61011, <<Result:8>>)};

%% 停止剧情副本挂机.
write(61012, Result) ->
    {ok, pt:pack(61012, <<Result:8>>)};

%% 获取剧情副本挂机信息.
write(61013, [Result, Time, LeftAutoNum, DungeonId, DropList]) ->
	
	% 物品列表.
	FunGoodsList = 
		fun({GoodsId, Count}) ->				
        	<<GoodsId:32, Count:32>>
    end,

	% 副本掉落列表.
	FunDungeonDrop = 
		fun({Exp, WuHun, GoodsList}) ->
		    GoodsBinList = list_to_binary([FunGoodsList(X) || X <- GoodsList]),
		    GoodsListSize  = length(GoodsList),				
        	<<Exp:32, 
			  WuHun:32, 
			  GoodsListSize:16, 
			  GoodsBinList/binary>>
    end,
    DropBinList = list_to_binary([FunDungeonDrop(X) || X <- DropList, X =/= []]),
    DropListSize  = length(DropList),
	
    {ok, pt:pack(61013, <<Result:8, 
						   Time:32,
                           LeftAutoNum:8, 
						   DungeonId:32,
						   DropListSize:16,
						   DropBinList/binary>>)};

%% 获取剧情副本霸主.
write(61014, MasterList) ->
	%1.通关记录列表.
	FunRecordList = 
		fun({DungeonId, Score, PassTime}) ->
        	<<DungeonId:32, Score:16, PassTime:32>>
    	end,
	
	%2.霸主列表.
	FunMasterList = 
		fun({Chapter, PlayerId, PlayerName, PlayerSex, PlayerCareer, RecordList}) ->
			PlayerNameBin = pt:write_string(PlayerName),
		    RecordListBin = list_to_binary([FunRecordList(X) || X <- RecordList]),
		    RecordListSize  = length(RecordList),
        	<<Chapter:32, PlayerId:32, PlayerNameBin/binary, PlayerSex:8, PlayerCareer:8,
			  RecordListSize:16, RecordListBin/binary>>
    end,
    MasterListBin = list_to_binary([FunMasterList(Master) || Master <- MasterList]),
    MasterListSize  = length(MasterList),
    {ok, pt:pack(61014, <<MasterListSize:16, MasterListBin/binary>>)};


%% 获取剧情封魔录称号.
write(61015, [List]) ->
    Len  = length(List),   
    Bin = list_to_binary(List),
    {ok, pt:pack(61015, <<Len:16, Bin/binary>>)};


%% 获取剧情封魔录称号.
write(61016, [Code]) ->
    {ok, pt:pack(61016, <<Code:8>>)};

%% 连连看副本更新积分.
write(61041, [Score, TotalScore, Combo, PositionList]) ->
	FunPositionList = 
		fun({Id, X, Y}) ->
        	<<Id:32, X:16, Y:16>>
    	end,
    PositionListBin = list_to_binary([FunPositionList(Position) || Position <- PositionList]),
    PositionListSize  = length(PositionList),	
    {ok, pt:pack(61041, <<Combo:32, Score:32, TotalScore:32, 
						   PositionListSize:16, PositionListBin/binary>>)};

%% 连连看副本更新时间.
write(61042, [AddTime, TotalTime]) ->
    {ok, pt:pack(61042, <<AddTime:32, TotalTime:32>>)};

%% 连连看副本更新怪物列表.
write(61043, MonList) ->
	FunMonList = 
		fun(Id) ->
        	<<Id:32>>
    	end,
    MonListBin = list_to_binary([FunMonList(Mon) || Mon <- MonList]),
    MonListSize  = length(MonList),	
    {ok, pt:pack(61043, <<MonListSize:16, MonListBin/binary>>)};

%% 新版钱多多副本信息
write(61050, [Coin, BCoin, BossNum, MonNum, Combo, MaxCombo, Step, LeftTime]) ->
    {ok, pt:pack(61050, <<Coin:32, BCoin:32, BossNum:16, MonNum:16, Combo:16, MaxCombo:16, Step:8, LeftTime:32>>)};

%% 开启钱多多副本抽奖
write(61051, CoinNum) ->
    {ok, pt:pack(61051, <<CoinNum:16>>)};

%% 返回拾取金币倒计时
write(61052, LeftTime) ->
    {ok, pt:pack(61052, <<LeftTime:32>>)};

%% 拾取金币
write(61053, [Res, MonId, PickCoinNo]) ->
    {ok, pt:pack(61053, <<Res:8, MonId:32, PickCoinNo:16>>)};

%% 发放钱多多奖励
write(61054, [TotalCoin, TotalBCoin, KillMon, KillBoss, MaxCombo]) ->
    {ok, pt:pack(61054, <<TotalCoin:32, TotalBCoin:32, KillMon:16, KillBoss:16, MaxCombo:16>>)};

%% 拾取金币结束
write(61055, []) ->
    {ok, pt:pack(61055, <<>>)};

%% 更新铜币副本场景时间.
write(61057, [NewCloseTime, Step]) ->
    {ok, pt:pack(61057, <<NewCloseTime:32, Step:8>>)};

%% 生成下一波小怪.
%% 1刷小怪，2刷BOSS.
write(61058, MonType) ->
    {ok, pt:pack(61058, <<MonType:8>>)};  

%% 活动副本得到积分.
write(61060, [Score, TotalScore]) ->
    {ok, pt:pack(61060, <<Score:32, TotalScore:32>>)};

%% 飞行副本更新积分.
write(61070, [Score, TotalScore]) ->
    {ok, pt:pack(61070, <<Score:32, TotalScore:32>>)};

%% 飞行副本更新星星.
write(61071, [Star, TotalStar]) ->
    {ok, pt:pack(61071, <<Star:32, TotalStar:32>>)};

%% 飞行副本查询难度.
write(61072, [Level]) ->
    {ok, pt:pack(61072, <<Level:32>>)};

%% 飞行副本显示计时.
write(61073, [AddTime, Time, TotalTime, IsStart]) ->
    {ok, pt:pack(61073, <<AddTime:32, Time:32, TotalTime:32, IsStart:8>>)};

%% 飞行更新阴阳BOSS值.
write(61074, [YinValue, YangValue]) ->
    {ok, pt:pack(61074, <<YinValue:32, YangValue:32>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

get_id_list(_MonCount, [], ReturnList) ->
	ReturnList;
get_id_list(0, [_MonList], ReturnList) ->
	ReturnList;
get_id_list(1, [<<MonId:32>>], ReturnList) ->
	ReturnList++[MonId];
get_id_list(MonCount, [<<MonId:32, MonList/binary>>], ReturnList) ->
	if MonCount =< 0 ->
		get_id_list(0, [], ReturnList);
	true ->
		get_id_list(MonCount-1, [MonList], ReturnList++[MonId])
	end.
