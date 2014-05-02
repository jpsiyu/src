%% --------------------------------------------------------
%% @Module:           |pt_270
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-04-10
%% @Description:      |仙侣奇缘 协议收发
%% --------------------------------------------------------
-module(pt_270).
-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%

%%    请求两位异性 ##############  
read(27000, <<Type:8>>) ->
    {ok, [Type]};

%%    发送邀请给异性 ############
read(27001, <<TargetPlayId:32>>) ->
    {ok, [TargetPlayId]};

%%    收到邀请回应 ############
read(27003, <<TargetPlayId:32,Option:8>>) ->
    {ok, [TargetPlayId, Option]};

%%    对异性使用物品   ###########
read(27005, Info) ->
	<<TargetPlayId:32, Type:8, Option:8>> = Info,
    {ok, [TargetPlayId, Type, Option]};

%%    广播蜡烛  #############

read(27006, _) ->
    {ok, broadcast_candle};

%%    增加经验 #############
read(27007, _) ->
    {ok, exp_add};

%%    经验结束  #############
read(27008, <<TaskId:32>>) ->
    {ok, [TaskId]};

%%    对对方的评价 #############
read(27010, <<TargetPlayId:32,Type:8,Rose:16>>) ->
    {ok, [TargetPlayId, Type, Rose]};

%%    取消约会 #############
read(27012, _) ->
    {ok, end_appointment};

%%    上线获取仙侣情缘状态 ############
read(27014, _) ->
    {ok, get_xlqy_state};

%%    仙侣奇缘聊天 ############
read(27016, <<TargetPlayId:32>>) ->
    {ok, [TargetPlayId]};

%%    获取仙侣奇缘小蜡烛 ############
read(27018, _) ->
    {ok, get_xlqy_candle};

%%    获取红粉、蓝颜 ############
read(27020, _) ->
    {ok, get_appointment};

%%    发题目(只用于发送询问是否开始小游戏) ############
read(27021, _) ->
    {ok, send_questions};

%%    答题目(只用于发送询问是否开始小游戏) ############
read(27022, <<Answer:8>>) ->
    {ok, [Answer]};

%%    答题结束 ############
read(27023, _) ->
    {ok, xlqy_test_end};

%%    定时请求 刷新鲜花 ############
read(27024, _) ->
    {ok, xlqy_game_refresh};

%%    抽奖_小游戏奖励类型
read(27029, _)->
	{ok, xlqy_get_new_prize};

%%    种花_开始
read(27030, _)->
	{ok, xlqy_confirm_flower_start};

%%    除虫/浇水
read(27032, <<OptStep:8, OptFlower:8>>)->
	{ok, [OptStep, OptFlower]};

%% 传送
read(27051, <<SceneId:32, X:16, Y:16>>) ->
    {ok, [SceneId, X, Y]};

%% 参加自愿同意(无红颜/蓝颜) 
read(27052, _) ->
    {ok, xlqy_v};

%% 玩家登陆所在区域(精确到市)
read(27053, <<Location:16>>) ->
    {ok, Location};

%%    获取双方情缘次数
read(27065, _)->
	{ok, no};

%%    无匹配 ##############
read(_, _) ->
    {error, no_match}.


%%
%%服务端 -> 客户端 ------------------------------------
%%


%%    请求两位异性
%%@param: 		Res	  					|int:8  结果
%%@param:		TargetArray    			|binary 伴侣列表
%%@param:		Time_Left    			|int:32 刷新剩余时间
%%@param:		VipTimes    			|int:8 	VIP剩余次数
write(27000,[Res, TargetArray, Time_Left, VipTimes])->
%% 	io:format("DataxDatax  : ~p~n", [TargetArray]), 
	case Res of
		1->
			Datax = pack_27000(TargetArray),
			Info = <<Res:8, Datax/binary, Time_Left:32, VipTimes:8>>;
		0->
			Info = <<Res:8, 0:16, Time_Left:32, VipTimes:8>>;
		2->
			Info = <<Res:8, 0:16, Time_Left:32, VipTimes:8>>;
		_->
			Info = <<Res:8, 0:16, Time_Left:32, VipTimes:8>>
	end,
	{ok, pt:pack(27000, Info)};

%%    发送邀请给异性 
%%@param: 		Res	  					|int:8  结果
%%@param:		TargetPlayerName    	|string 玩家名字
%%@param:		TargePlayerId    		|int:32 玩家id
write(27001,[Res, TargetPlayerName, TargePlayerId ])->
	Bin_TargetPlayerName = pt:write_string(TargetPlayerName),
	Info = <<Res:8, Bin_TargetPlayerName/binary, TargePlayerId:32>>,
	{ok, pt:pack(27001, Info)};

%%    通知异性(通知被邀请者)
%%@param:		FromPlayerId    		|int:32 玩家id
%%@param:		FromPlayerName    		|string 玩家名字
write(27002,[FromPlayerId, FromPlayerName, Sex, Lv, Voc, Realm, Weapon, Clothes])->
	Bin_FromPlayerName = pt:write_string(FromPlayerName),
	Info = <<FromPlayerId:32, Bin_FromPlayerName/binary, Sex:8, Lv:32, Voc:8, Realm:8, Weapon:32, Clothes:32>>,
	{ok, pt:pack(27002, Info)};

%%    回应收到的邀请
%%@param:		Res			    		|int:8  结果
%%@param:		FromPlayerId    		|int:32 玩家id
%%@param:		FromPlayerName    		|string 玩家名字
write(27003,[Res, FromPlayerName,FromPlayerId])->
	Bin_FromPlayerName = pt:write_string(FromPlayerName),
	Info = <<Res:8, FromPlayerId:32, Bin_FromPlayerName/binary>>,
	{ok, pt:pack(27003, Info)};

%%    结果反馈给发起人 
%%@param:		TargetPlayerId    		|int:32 玩家id
%%@param:		TargetPlayerName    	|string 玩家名字
%%@param:		Res			    		|int:8  结果
write(27004,[TargetPlayerId, TargetPlayerName, Res])->
	Bin_TargetPlayerName = pt:write_string(TargetPlayerName),
	Info = <<TargetPlayerId:32, Bin_TargetPlayerName/binary, Res:8>>,
	{ok, pt:pack(27004, Info)};

%%    对异性使用物品
%%@param:		Res			    		|int:8  结果
write(27005,[Res])->
	Info = <<Res:8>>,
	{ok, pt:pack(27005, Info)};

%%    广播蜡烛
%%@param:		XPos			    	|int:32 X
%%@param:		YPos			    	|int:32 Y
%%@param:		TimeLeft		    	|int:32 剩余时间
%%@param:		Res				    	|int:8  结果
write(27006,[[XPos, YPos], TimeLeft, Res])->
	Info = <<XPos:32, YPos:32, TimeLeft:32, Res:8>>,
	{ok, pt:pack(27006, Info)};

%%    评价对方
%%@param:		OppositePlayerId    	|int:32 玩家id
%%@param:		OppositePlayerName    	|string 玩家名字
write(27009,[OppositePlayerId, OppositePlayerName])->
	Bin_OppositePlayerName = pt:write_string(OppositePlayerName),
	Info = <<OppositePlayerId:32, Bin_OppositePlayerName/binary>>,
	{ok, pt:pack(27009, Info)};

%%    评价结果显示
%%@param:		FromPlayerId    		int:32 玩家id
%%@param:    	FromPlayerName			string 玩家名字 FromPlayerId
%%@param:    	Sex						int:8  性别
%%@param:		Image					int:32  头像ID
%%@param:		Voc						int:8  职业
%%@param:    	Con						int:8  评价内容
%%@param:    	Rose					int:8  送玫瑰结果
write(27011,[FromPlayerId, FromPlayerName, Sex, Image, Voc, Con, Rose])->
	Bin_FromPlayerName = pt:write_string(FromPlayerName),
	Info = <<FromPlayerId:32, Bin_FromPlayerName/binary, Sex:8, Image:32, Voc:8, Con:8, Rose:16>>,
	{ok, pt:pack(27011, Info)};

%%    取消约会
%%@param:		Res			    		|int:8  结果
write(27012,[Res])->
	Info = <<Res:8>>,
	{ok, pt:pack(27012, Info)};

%%    取消约会通知
%%@param:		FromPlayerName    		|string 玩家名字--主动取消方
%%@param:		TargetPlayerName    	|string 玩家名字--被动接受方
write(27013,[FromPlayerName, TargetPlayerName])->
	Bin_FromPlayerName = pt:write_string(FromPlayerName),
	Bin_TargetPlayerName = pt:write_string(TargetPlayerName),
	Info = <<Bin_FromPlayerName/binary, Bin_TargetPlayerName/binary>>,
	{ok, pt:pack(27013, Info)};

%%    上线获取仙侣情缘状态
%%@param:		PlayerId    			|int:32 玩家id
%% @param:		TargetPlayerName    	|string 玩家名字
write(27014,[Step, PlayerId, TargetPlayerName])->
	Bin_TargetPlayerName = pt:write_string(TargetPlayerName),
	Info = <<PlayerId:32, Bin_TargetPlayerName/binary, Step:16>>,
	{ok, pt:pack(27014, Info)};

%%    邀请方"缘"字
%% @param:		TargetPlayerId    		|int:32 玩家id
%% @param:		TargetPlayerName    	|string 玩家名字
%% @param:		Type			    	|int:8  评价内容
write(27015,[Step, TargetPlayerId, TargetPlayerName, Type])->
	Bin_TargetPlayerName = pt:write_string(TargetPlayerName),
	Info = <<TargetPlayerId:32, Bin_TargetPlayerName/binary, Type:8, Step:16>>,
	{ok, pt:pack(27015, Info)};

%%    仙侣奇缘聊天
%% @param:		TargetPlayerId    		|int:32 玩家id
%% @param:		TargetPlayerName    	|string 玩家名字
%% @param:		Sex				    	|int:8  性别
%% @param:		Voc				    	|int:8  职业
write(27016,[TargetPlayerId, TargetPlayerName, Sex, Voc])->
	Bin_TargetPlayerName = pt:write_string(TargetPlayerName),
	Info = <<TargetPlayerId:32, Bin_TargetPlayerName/binary,  Sex:8, Voc:8>>,
	{ok, pt:pack(27016, Info)};

%%    获取仙侣奇缘小蜡烛 
%% @param:		ListCandle		    	|Array  蜡烛
write(27018,[ListCandle])->
	Info = pack_27018(ListCandle),
	{ok, pt:pack(27018, Info)};

%%    广播仙侣奇缘小蜡烛 
%% @param:		Res			    		|int:8  结果
%% @param:		TimeLeft			    |int:32 时间
%% @param:		Type				    |int:8	类型
%% @param:		PartnerId				|int:32 约会对象ID
%% @param:		PartnerName				|string 约会对象名字
%% @param:		TypeA				    |int:8	约会形式
%% @param:		TypeB				    |int:8	双休邀请
write(27019,[Res, TimeLeft, Type, PartnerId, PartnerName, TypeA, TypeB])->
	Bin_PartnerName = pt:write_string(PartnerName),
	Info = <<Res:8, TimeLeft:32, Type:8, PartnerId:32, Bin_PartnerName/binary, TypeA:8, TypeB:8>>,
	{ok, pt:pack(27019, Info)};

%%    获取红粉、蓝颜
%% @param:		TargetPlayerId			|int:32 结果
%% @param:		TargetPlayerName    	|string 玩家名字
write(27020,[TargetPlayerId, TargetPlayerName, Type, Sex, Lv, Voc, Realm, Weapon, Clothes])->
	Bin_TargetPlayerName = pt:write_string(TargetPlayerName),
	Info = <<TargetPlayerId:32, Bin_TargetPlayerName/binary, Type:8, Sex:8, Lv:32, Voc:8, Realm:8, Weapon:32, Clothes:32>>,
	{ok, pt:pack(27020, Info)};

%%    发题目 (只用于发送询问是否开始小游戏)
write(27021,[Res])->
	Info = <<Res:8>>,
	{ok, pt:pack(27021, Info)};

%%    答题目 (只用于发送询问是否开始小游戏)
%% @param:		Res					    |int:8(0 => 失败 1 => 成功 2 => 已经答过了)
write(27022,[Res])->
	Info = <<Res:8>>,
	{ok, pt:pack(27022, Info)};

%%    答题结束 
%% @param:		Res					    |int:16 默契度
write(27023,[Res])->
	Info = <<Res:8>>,
	{ok, pt:pack(27023, Info)};

%%    答题提示
%% @param:		Res					    |int:8 (0 => 双方答案相同 1 => 双方答案不相同 2 => 双方回答正确 3 => 双方回答有错误)
%% @param:		Exp_Add				    |int:32 经验
%% @param:		Right_Num			    |int:16 连续答对xx题
%% @param:		Consensus_Add		    |int:16 增加的默契度
write(27025,[Res, Exp_Add, Right_Num, Consensus_Add])->
	Info = <<Res:8, Exp_Add:32, Right_Num:16, Consensus_Add:16>>,
	{ok, pt:pack(27025, Info)};

%%    关闭答题界面
%% @param:		Res		   				|int:8 (0 => 自己不同意答题 1 => 对方不同意答题)
write(27026,[Res])->
	Info = <<Res:8>>,
	{ok, pt:pack(27026, Info)};

%%    抽奖_小游戏奖励类型
%% @param:		Res		   				|int:8 (0 失败 1 成功 2 元宝不足)
%% @param:		PrizeType		   		|int:8 (奖励类型)
write(27029,[Res, PrizeType])->
	Info = <<Res:8, PrizeType:8>>,
	{ok, pt:pack(27029, Info)};

%%    种花_开始
write(27030,[PrizeType, OptType, MonId, X, Y, TimeLeft, PartnerName])->
	Bin_PartnerName = pt:write_string(PartnerName),
	Info = <<PrizeType:8, OptType:8, MonId:32, X:16, Y:16, TimeLeft:32, Bin_PartnerName/binary>>,
	{ok, pt:pack(27030, Info)};

%%    刷新花状态
%% @param:		F1, F2, F3, F4 			|int:8 (4朵花的状态)
write(27031,[F1, F2, F3, F4, TimeLeft, TotleScore])->
	Info = <<F1:8, F2:8, F3:8, F4:8, TimeLeft:32, TotleScore:32>>,
	{ok, pt:pack(27031, Info)};

%%    除虫/浇水
%% @param:		Res		   				|int:8 (0 => 失败 1 => 成功)
write(27032,[Res])->
	Info = <<Res:8>>,
	{ok, pt:pack(27032, Info)};

%%    开花
%% @param:		Res		   				|int:8 (0 错误 1 开一朵 2 开并蒂)
write(27033,[Res, TotleFlower, DoubleFlower])->
	Info = <<Res:8, TotleFlower:16, DoubleFlower:16>>,
	{ok, pt:pack(27033, Info)};

%%    种花结束
write(27034,[PrizeType, PrizeNum])->
	Info = <<PrizeType:8, PrizeNum:32>>,
	{ok, pt:pack(27034, Info)};

%%    传送
write(27051,[Res])->
	Info = <<Res:8>>,
	{ok, pt:pack(27051, Info)};

%%    参加自愿同意(无红颜/蓝颜)
write(27052,[Res])->
	Info = <<Res:8>>,
	{ok, pt:pack(27052, Info)};

%%    参加自愿同意(无红颜/蓝颜)
write(27054, _)->
	Info = <<1:8>>,
	{ok, pt:pack(27054, Info)};

%%    获取双方情缘次数
write(27065, [Res, Num, MaxNum])->
	Info = <<Res:8, Num:16, MaxNum:16>>,
	{ok, pt:pack(27065, Info)};

%%    抽奖_小游戏奖励类型
write(_, _) ->
    {ok, pt:pack(0, <<>>)}.

%%
%%-------- 数据处理 ------------------------------------
%%
%% 打包27000
pack_27000([]) ->
    <<0:16, <<>>/binary>>;
pack_27000(List) ->
    Rlen = length(List),
    F = fun([TargetPlayerId, TargetPlayerName, Type1, Type2, Sex, Lv, Voc, Realm, Weapon, Clothes]) ->
        Bin_TargetPlayerName = pt:write_string(TargetPlayerName),
        <<TargetPlayerId:32, Bin_TargetPlayerName/binary, Type1:8, Type2:8, Sex:8, Lv:32, Voc:8, Realm:8, Weapon:32, Clothes:32>>
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.
%% 打包27018
pack_27018([]) ->
    <<0:16, <<>>/binary>>;
pack_27018(List) ->
    Rlen = length(List),
    F = fun([Xpos, Ypos]) ->
        <<Xpos:32, Ypos:32>>
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.




%%--------------------- E N D --------- E N D ----------------------------------
