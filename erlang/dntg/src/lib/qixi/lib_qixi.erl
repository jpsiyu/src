%%%-------------------------------------------------------------------
%%% @Module	: lib_qixi
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 21 Aug 2012
%%% @Description: 
%%%-------------------------------------------------------------------
-module(lib_qixi).
-include("activity.hrl").
-include("gift.hrl").
-include("server.hrl").
-include("qixi.hrl").
-compile(export_all).
%% 每天首次登录获得礼包
%% @return {false, ErrorCode} | true
can_get_login_award(PS, GiftId) ->
    case PS#player_status.lv >= 30 of
	true ->
	    case data_qixi:is_qixi_time() of
		true ->
		    case get_daily_type_by_gift_id(GiftId) of
			false -> {false, 3};
			{false,_,_} -> {false, 3};
			{{GiftNum, _, Condition}, DailyType, _} ->
			    case GiftNum of
				1 ->
				    get_gift_by_condition(PS, Condition, DailyType);
				2 ->
				    get_gift_by_condition(PS, Condition, DailyType);
				3 ->
				    get_gift_by_condition(PS, Condition, DailyType);
				4 ->
				    get_gift_by_condition(PS, Condition, DailyType);
				_ ->
				    {false, 3}
			    end
		    end;
		false -> {false, 6}
	    end;
	false -> {false, 5}
    end.

%% 领取连续登录礼包
get_qixi_login_continuation_award(DailyPid, PlayerId) ->
    {_, Open} = case lists:keyfind(1, 1, data_qixi_config:get_qixi_award_open()) of
		    false -> {0, 0};
		    Any -> Any
		end,
    case Open of
	1 ->
	    case data_qixi:is_qixi_time() of
		true ->
		    StartDay = data_qixi:get_start_day(),
		    EndDay = data_qixi:get_end_day(),
		    DiffDays = util:get_diff_days(EndDay, StartDay),
		    LoginDays = get_login_continuation(PlayerId),
		    case LoginDays >= DiffDays of
			true ->
			    {_, Title, Content, GiftId} = lists:keyfind(1, 1, data_qixi_config:get_qixi_mail_config()),
			    {_,DailyType,_} = lib_qixi:get_daily_type_by_gift_id(GiftId),
			    case mod_daily:get_count(DailyPid, PlayerId, DailyType) of
				0 ->
				    mod_daily:increment(DailyPid, PlayerId, DailyType),
				    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[PlayerId], Title, Content, GiftId, 1, 0, 0,1,0,0,0,0]); %%连续登录礼包
				_ -> []
			    end;
			    %% Q1 = io_lib:format(<<"delete from login_continuation where player_id=~p">>,[PlayerId]),
			    %% db:execute(Q1);
			false ->
			    %% 保留最后一天的天数
			    []
			    %% case util:unixdate() >= EndDay of
			    %% 	true ->
			    %% 	    Q2 = io_lib:format(<<"delete from login_continuation where player_id=~p">>,[PlayerId]),
			    %% 	    db:execute(Q2);
			    %% 	false -> []
			    %% end
		    end;
		false -> []
	    end;
	_ -> []
    end.

check_special_login_continuation_award(PlayerId) ->
    Key = "special_lc_award"++PlayerId,
    StartDay = data_qixi:get_start_day(12),
    LoginDays = get_login_continuation(PlayerId),
    case get(Key) of
	undefined ->
	    case db:get_one(io_lib:format(<<"select award from login_continuation_award where player_id=~p">>, [PlayerId])) of
		null ->
		    %%{天数, GiftId, 数量, 是否按登录天数发, 领取状态}
		    InitGift = data_qixi:get_init_special_gift_id_list(StartDay, LoginDays),
		    db:execute(io_lib:format(<<"insert into login_continuation_award(player_id, award) values(~p, '~s')">>, [PlayerId, util:term_to_string(InitGift)])),
		    put(Key, InitGift),
		    InitGift;
		R ->
		    RL = lib_goods_util:to_term(R),
		    InitGift = data_qixi:get_init_special_gift_id_list(StartDay, LoginDays, RL),
		    put(Key, InitGift),
		    InitGift
	    end;
	GiftList -> GiftList
    end.
		    
%% 领取新春连续登录礼包
get_special_login_continuation_award(PS) ->
    DailyPid = PS#player_status.dailypid,
    PlayerId = PS#player_status.id,
    case data_qixi:is_special_time(12) of
	true ->
	    StartDay = data_qixi:get_start_day(12),
	    LoginDays = get_login_continuation(PlayerId),
	    %% 领奖
	    case mod_daily:get_count(DailyPid, PlayerId, 7750) of
		0 ->
		    case data_qixi:get_special_gift_id(StartDay, LoginDays) of
			false -> [];
			{Day,GiftId,Num,Condition} ->
			    case GiftId =:= 534194 andalso PS#player_status.lv < 40 of
				false ->
				    GoodsPid = PS#player_status.goods#status_goods.goods_pid,
				    case gen_server:call(GoodsPid, {'give_more_bind', [], [{GiftId, Num}]}) of
					ok ->
					    mod_daily:increment(DailyPid, PlayerId, 7750),
					    GiftList = check_special_login_continuation_award(PlayerId),
					    NewGiftList = lists:keyreplace(Day, 1, GiftList, {Day,GiftId,Num,Condition,2}),
					    db:execute(io_lib:format(<<"update login_continuation_award set award='~s' where player_id=~p">>, [util:term_to_string(NewGiftList), PlayerId])),
					    Key = "special_lc_award"++PlayerId,
					    put(Key, NewGiftList),
					    {ok, Bin27711} = pt_277:write(27711, [1, GiftId]),
					    lib_server_send:send_to_sid(PS#player_status.sid, Bin27711),
					    {ok, Bin27712} = pt_277:write(27712, [NewGiftList]),
					    lib_server_send:send_to_sid(PS#player_status.sid, Bin27712);
					_ ->
					    {ok, BinData} = pt_277:write(27711, [0, GiftId]),
					    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
				    end;
				true ->
				    {ok, BinData} = pt_277:write(27711, [3, GiftId]),
				    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			    end
		    end;
		_ ->
		    {ok, BinData} = pt_277:write(27711, [2, 0]),
		    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	    end;
	false -> []
    end.

%% 记录连续登录天数
save_qixi_login_continuation(PlayerId) ->
    {_, Open} = case lists:keyfind(1, 1, data_qixi_config:get_qixi_award_open()) of
		    false -> {0, 0};
		    Any -> Any
		end,
    case Open of
	1 ->
	    case data_qixi:is_qixi_time() of
		true -> save_login_continuation(PlayerId);
		false ->
		    %% 保留最后一天的天数
		    case util:unixdate() > data_qixi:get_end_day() of
			true ->
			    Q1 = io_lib:format(<<"delete from login_continuation where player_id=~p">>,[PlayerId]),
			    db:execute(Q1);
			false -> []
		    end
	    end;
	_ ->
	    save_special_login_continuation(PlayerId)
    end.

save_special_login_continuation(PlayerId) ->
    case data_qixi:is_special_time(12) of
	true -> save_login_continuation(PlayerId);
	false ->
	    %% 保留最后一天的天数
	    case util:unixdate() > data_qixi:get_end_day(12) of
		true ->
		    Q1 = io_lib:format(<<"delete from login_continuation where player_id=~p">>,[PlayerId]),
		    db:execute(Q1);
		false -> []
	    end
    end.

save_login_continuation_in_time(StartDay, EndDay, PlayerId) ->
    Now = util:unixtime(),
    case Now >= StartDay andalso Now =< EndDay of
	true -> save_login_continuation(PlayerId);
	false -> []
    end.
save_login_continuation(PlayerId) ->
    Q1 = io_lib:format(<<"select last_login from login_continuation where player_id=~p">>,[PlayerId]),
    case db:get_one(Q1) of
	null ->
	    Q2 = io_lib:format(<<"insert into login_continuation(player_id, last_login, count) values(~p,~p,~p)">>,[PlayerId,util:unixdate(),1]),
	    db:execute(Q2);
	Last ->
	    NowTime = util:unixtime(),
	    case NowTime > Last + 24 * 3600 of
		true ->
		    %% 第二天，次数加1
		    Q3 = io_lib:format(<<"update login_continuation set last_login=~p, count=count+~p where player_id=~p">>,[util:unixdate(),1,PlayerId]),
		    db:execute(Q3);
		false -> []			%同一天
	    end
    end.

%% 获取连续登录天数
get_login_continuation(PlayerId) ->
    Q1 = io_lib:format(<<"select count from login_continuation where player_id=~p">>,[PlayerId]),
    case db:get_one(Q1) of
	null -> 0;
	Any -> Any
    end.
	    
%% 更新任务次数
%% @param: Type
%% 1护送
%% 2平乱
%% 3皇榜
%% 4诛妖
%% 5帮派试炼
%% 6仙侣奇缘
%% 7活跃度
%% 8跨服3v3
%% 9多人副本20层
%% 10多人炼狱10波
%% 11...15洗炼（紫色以上）
%% 16...20神秘商店刷新
%% 21...25淘宝
update_player_task(Id, Type) ->
    case data_qixi:is_qixi_time() of
	true ->
	    mod_qixi:update_player_task(Id, Type, 1);
	false ->
	    skip
    end.
%% 更新任务次数
update_player_task(Id, Type, Num) ->
    case data_qixi:is_qixi_time() of
	true ->
	    mod_qixi:update_player_task(Id, Type, Num);
	false ->
	    skip
    end.


%% 批量更新任务次数，用于任务可叠加的情况
update_player_task_batch(Id, TypeList, Num) ->
    case data_qixi:is_qixi_time() of
	true ->
	    mod_qixi:update_player_task_batch(Id, TypeList, Num);
	false ->
	    skip
    end.
%% 登录时获取当天各任务次数，但不写进数据库
update_task_from_login(PlayerId, DailyPid) ->
    case data_qixi:is_qixi_time() of
	true ->
	    Hs = mod_daily:get_count(DailyPid, PlayerId, 4700),
	    mod_qixi:update_player_task_from_login(PlayerId, 1, Hs),
	    Zyt = mod_daily:get_count(DailyPid, PlayerId, 5000040) + mod_daily:get_count(DailyPid, PlayerId, 5000090),
	    mod_qixi:update_player_task_from_login(PlayerId, 4, Zyt),
	    Xlqy = mod_daily:get_count(DailyPid, PlayerId, 3800),
	    mod_qixi:update_player_task_from_login(PlayerId, 6, Xlqy),
	    Bpsl = mod_daily:get_count(DailyPid, PlayerId, 6000003),
	    mod_qixi:update_player_task_from_login(PlayerId, 5, Bpsl),
	    Hb = mod_daily:get_count(DailyPid, PlayerId, 5000010),
	    mod_qixi:update_player_task_from_login(PlayerId, 3, Hb),
	    Pl = mod_daily:get_count(DailyPid, PlayerId, 5000020),
	    mod_qixi:update_player_task_from_login(PlayerId, 2, Pl);
	false ->
	    []
    end.
    

%% 获取任务完成情况
get_finish_task(Id) ->
    Activity =  mod_qixi:lookup_player_task(Id),
    pack_list(Activity).

%% 获取任务完成状态，是否可以领取奖励
%% @return: 0可领，1已领，2条件不足
get_status(Current, Max, IsGet) ->
    if
	IsGet =:= 1 -> 1;
	Current >= Max andalso IsGet =:= 0 -> 0;
	true -> 2
    end.
%% 发送奖励
send_award(PS, Type) ->
    Count = mod_qixi:lookup_player_task_by_type(PS#player_status.id, Type),
    case Count >= get_task_max_by_type(Type) of
	true ->
	    %% 达到条件，发送奖励
	    case mod_qixi:check_get_by_type(PS#player_status.id, Type) of
		%% 未领过
		0 ->
		    CellNum = gen_server:call(PS#player_status.goods#status_goods.goods_pid, {'cell_num'}),
		    case CellNum =< 0 of
			true ->
			    {ok, Bin} = pt_277:write(27701, [2, 0, 0]), %背包已满
			    lib_server_send:send_to_sid(PS#player_status.sid, Bin);
			false ->
			    GoodsTypeId = get_task_goods(Type),
			    GoodsPid = PS#player_status.goods#status_goods.goods_pid,
			    Num = get_award_num_by_type(Type),
			    gen_server:call(GoodsPid, {'give_more_bind', [], [{GoodsTypeId, Num}]}), 
			    log:log_goods(qixi, 0, GoodsTypeId, Num, PS#player_status.id),
			    mod_qixi:update_get_by_type(PS#player_status.id, Type, PS#player_status.dailypid), %登记已领
			    {ok, Bin} = pt_277:write(27701, [1, GoodsTypeId, Num]),
			    lib_server_send:send_to_sid(PS#player_status.sid, Bin)
		    end;
		_ ->
		    {ok, Bin} = pt_277:write(27701, [1, 0, 0]), %已领
		    lib_server_send:send_to_sid(PS#player_status.sid, Bin)
	    end;
	false ->
	    %% 未完成任务
	    {ok, Bin} = pt_277:write(27701, [0, 0, 0]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin)
    end.

%% 获取奖励物品数量
get_award_num_by_type(Type) ->
    L = data_qixi_config:get_task_config(),
    case lists:keyfind(Type, 1 ,L) of
	false -> 0;
	{_,_,_,GoodsNum} -> GoodsNum
    end.

%% 奖励物品
get_task_goods(Type) ->
    L = data_qixi_config:get_task_config(),
    case lists:keyfind(Type, 1 ,L) of
	false -> 0;
	{_,_,GoodsTypeId,_} -> GoodsTypeId
    end.

%% 获取完成任务需要的最大次数
get_task_max_by_type(Type) ->    
    L = data_qixi_config:get_task_config(),
    case lists:keyfind(Type, 1 ,L) of
	false -> 99999999;
	{_,TotalNum,_,_} -> TotalNum
    end.

%% 获取鲜花榜魅力值>999的玩家
get_max_ml_player() ->
    %% SQL = io_lib:format(<<"SELECT player_pt.id FROM player_pt, player_low WHERE player_low.id = player_pt.id AND player_low.sex = 2 AND player_pt.mlpt >= 999 ORDER BY player_pt.mlpt DESC limit 1">>,[]), 
    SQL = io_lib:format(<<"select `id`,`name`,`value` from `rank_daily_flower` where `sex` = 2 and `value` >= 999 order by `value` desc limit 1">>,[]),
    case db:get_row(SQL) of
	[] -> null;
	Row ->
	    Row
    end.
get_mlpt_player() ->
    mod_qixi:get_mlpt_player().
%% 发送XX宝贝奖励
send_max_ml_gift() ->
    {_, Open} = case lists:keyfind(2, 1, data_qixi_config:get_qixi_award_open()) of
		    false -> {0, 0};
		    Any -> Any
		end,
    case Open of
	1 ->
	    case get_max_ml_player() of
		null -> skip;
		Row ->
		    TS = util:unixtime(),
		    [Id,_Name,Value] = Row,
		    SQL = io_lib:format(<<"insert into qixi_babe(player_id,value,time) values(~p,~p,~p)">>,[Id, Value, TS]),
		    db:execute(SQL),
		    case lists:keyfind(2, 1, data_qixi_config:get_qixi_mail_config()) of
			false -> [];
			{_, Title, Content, GiftId} ->
			    lib_mail:send_sys_mail(Id, Title, Content, GiftId, 1, 0, 0, 0, 0) %七夕宝贝礼包
		    end
	    end;
	_  -> []
    end.
%% 根据礼包ID获取要领的是哪种类型礼包
get_daily_type_by_gift_id(GiftId) ->
    GiftList = data_qixi:get_gift_id(),
    lists:keyfind(GiftId, 3, GiftList).

%% 根据条件判断礼包是否可领
%% @return: {false, ErrorCode} | true
get_gift_by_condition(PS, Condition, DailyType) ->
    %% Condition 由后台来配，扩展直接增加序号
    case Condition of
	1 ->
	    case PS#player_status.lv < 50 of
		true ->
		    case mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, DailyType) > 0 of
			true -> {false, 4};
			false -> true
		    end;
		false -> {false, 10}
	    end;
	2 ->
	    %% 改为>=50级可领
	    case PS#player_status.lv >= 50 of
		true ->
		    case mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, DailyType) > 0 of
			true -> {false, 4};
			false -> true
		    end;
		false -> {false, 10}
	    end;
	3 ->
	    %% 每日充值含使用元宝卡
	    case mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, DailyType) > 0 of
		true -> {false, 4};
		false ->
		    Num1 = lib_recharge_ds:get_pay_task_total(PS#player_status.id, util:unixdate(), util:unixdate() + 86400),
		    Num2 = lib_recharge_ds:get_gold_goods_total(PS#player_status.id, util:unixdate(), util:unixdate() + 86400),
		    TotalNum = Num1 + Num2,
		    case TotalNum > 0 of
			true -> true;
			false ->
			    {false, 8}
		    end
	    end;
	4 ->
	    %% 连续登录
	    case mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, DailyType) > 0 of
		true -> {false, 4};
		false -> {false, 2}		%连续登录自动发奖
	    end;
	_ ->
	    {false, 3}
    end.


%% 打包列表需要信息
get_pack_list_element(Type) ->
    %% L = [{类型,总次数,物品ID,物品数量},..]
    L = data_qixi_config:get_task_config(),
    case lists:keyfind(Type, 1, L) of
	false -> {Type, 99999999, 0, 0};
	R -> R
    end.
	
%% 打包完成情况列表
pack_list(Activity) ->
    case Activity =:= [] of
	false ->
	    lists:map(fun({Type, CurrentNum, IsGet}) ->
			      {_, TotalNum, GoodsTypeId, GoodsNum} = get_pack_list_element(Type),
			      {Type, CurrentNum, TotalNum, GoodsTypeId, GoodsNum, get_status(CurrentNum, TotalNum, IsGet)}
		      end, Activity);
	_ ->
	    L = data_qixi_config:get_task_config(),
	    lists:map(fun({Type, TotalNum, GoodsTypeId, GoodsNum}) ->
			      {Type, 0, TotalNum, GoodsTypeId, GoodsNum, 2}
		      end, L)
    end.
%% 可领任务奖励数目
remain_task_award_num(PS) ->
    case lists:keyfind(4, 1, data_qixi_config:get_qixi_award_open()) of
	{_,Open} ->
	    case Open of
		1 ->
		    Activity = mod_qixi:lookup_player_task(PS#player_status.id),
		    List = pack_list(Activity),
		    lists:foldl(
		      fun(X, AccIn) ->
			      case element(6, X) =:= 0 of
				  true -> AccIn + 1;
				  false -> AccIn
			      end
		      end, 0, List);
		_ -> 0
	    end;
	false -> 0
    end.

filter_task_award_num(List) ->
    case lists:keyfind(4, 1, data_qixi_config:get_qixi_award_open()) of
	{_,Open} ->
	    case Open of
		1 ->
		    lists:foldl(
		      fun(X, AccIn) ->
			      case element(6, X) =:= 0 of
				  true -> AccIn + 1;
				  false -> AccIn
			      end
		      end, 0, List);
		_ -> 0
	    end;
	false -> 0
    end.

%% 可领登录奖励数目
remain_login_award_num(PS) ->
    case lists:keyfind(3, 1, data_qixi_config:get_qixi_award_open()) of
	{_,Open} ->
	    case Open of
		1 ->
		    GetList = lists:map(fun(X) ->
						{_, _, GiftId} = X,
						case lib_qixi:can_get_login_award(PS, GiftId) of
						    true -> {GiftId, 1};
						    {false, 4} -> {GiftId, 2};
						    _ -> {GiftId, 0}
						end
					end, data_qixi:get_gift_id()),
		    lists:foldl(
		      fun(X, AccIn) ->
			      case element(2, X) of
				  1 -> AccIn + 1;
				  _ -> AccIn
			      end
		      end, 0, GetList);
		_ -> 0
	    end;
	false -> 0
    end.
