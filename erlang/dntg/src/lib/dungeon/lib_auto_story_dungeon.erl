%%------------------------------------------------------------------------------
%% @Module  : lib_auto_story_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.9.19
%% @Description: 剧情副本自动挂机
%%------------------------------------------------------------------------------


-module(lib_auto_story_dungeon).
-include("server.hrl").
-include("scene.hrl").
-include("goods.hrl").
-include("drop.hrl").
-include("dungeon.hrl").
-include("sql_dungeon.hrl").


%% 公共函数：外部模块调用.
-export([
		login_init/1,                    %% 登录初始化.		 
        start_auto/3,                    %% 开始挂机.
        stop_auto/1,                     %% 停止挂机.
        get_auto_info/1,                 %% 获取挂机信息.
        calc_auto/1,                     %% 计算副本挂机结果.
		set_next_calc_time/2,            %% 设置下一次计算的时间.
		is_auto_story/2	                 %% 是否在挂机中.
    ]).
	
%% 内部函数：副本服务本身调用.
-export([
		new/1,                           %% 新建挂机信息.
		save/1,                          %% 保存挂机信息.
	    reload/1,                        %% 所有数据重载.
		get_info/1,                      %% 获取挂机信息.
		set_whpt/2,                      %% 设置武魂值.  
		mon_drop/2,                      %% 怪物掉落.
	    make_goods_list/2,               %% 组合物品[物品ID, 物品数量].
		filter_reduce_list/4,            %% 过虑衰减物品.
		send_mail/1                      %% 发送挂机结果邮件.		
    ]).
  
%% --------------------------------- 公共函数 ----------------------------------

%% 登录初始化.
login_init(PlayerId) ->
	reload(PlayerId),	
	calc_auto(PlayerId).

%% 开始挂机.
start_auto(PlayerId, DungeonId, AutoNum) ->

	%1.获取自动挂机信息.
	Data = get_info(PlayerId),

	%2.判断是否在挂机中.
	Result =
	    case Data#auto_story_dun_record.state == 1 of
	        true ->
	            0;
            false ->
                Chapter = data_story_dun_config:get_chapter_id(DungeonId),
                NowTime = util:unixtime(),
                Data2 = Data#auto_story_dun_record{
                    id           = PlayerId,
                    begin_time   = NowTime,
                    exp          = 0,
                    wuhun        = 0,
                    finish       = 0,
                    chapter      = Chapter,
                    dungeon_id   = DungeonId,
                    auto_num     = AutoNum,
                    state        = 1},
                save(Data2),
                1
        end,

	{ok, BinData} = pt_610:write(61011, Result),
	lib_server_send:send_to_uid(PlayerId, BinData).	

%% 停止挂机.
stop_auto(PlayerId) ->
	
	%1.获取自动挂机信息.
	Data = get_info(PlayerId),

	%2.判断是否在挂机中.
	Result =
	    case Data#auto_story_dun_record.state =:= 1 of
	        true ->
				%.计算挂机结果.
				calc_auto(PlayerId),
				
				%.清除剧情副本自动挂机结算定时器.
                RefreshTimer = get("calc_auto_story_dungeon"),
                util:cancel_timer(RefreshTimer),

				%.清空挂机信息.
				AutoData1 = #auto_story_dun_record{id = PlayerId},
				erase(?AUTO_STORY_DUNGEON_KEY(PlayerId)),
				save(AutoData1),
	            1;
	        false ->
				0
	    end,

	{ok, BinData} = pt_610:write(61012, Result),
	lib_server_send:send_to_uid(PlayerId, BinData).	

%% 获取挂机信息.
get_auto_info(PlayerId) ->
    calc_auto(PlayerId),
    send_auto_info(PlayerId).

%% 发送结果到客户端
send_auto_info(PlayerId) -> 
    	%% 获取自动挂机信息.
	Data = get_info(PlayerId),

    %% 取值
    #auto_story_dun_record{
        state       = State,
        auto_num    = AutoNum,
        begin_time  = BeginTime,
        finish      = Finish,
        dungeon_id  = DungeonId,
        drop_data_list = DropDataList
    } = Data,

	%% 计算剩余时间.
    CloseTime = case State == 1 of
        true ->
            NowTime = util:unixtime(),
            AutoTime = data_story_dun_config:get_config(auto_time),
            TotalTime = AutoNum * AutoTime,
            CloseTime1 = BeginTime + TotalTime - NowTime,
            max(0, CloseTime1);
        false ->
            0
    end,
	
	%% 获取副本掉落列表.
    FunDropList = fun(DropData) ->
            {
                DropData#auto_drop_record.exp,
                DropData#auto_drop_record.wuhun,
                DropData#auto_drop_record.goods_list
            }
    end,
    DropList = [FunDropList(E)||E<-DropDataList],

	%% 发送给客户端.
	{ok, BinData} = pt_610:write(61013, [Data#auto_story_dun_record.state, 
										 CloseTime, 
                                         max(0, AutoNum-Finish),
                                         DungeonId,
									     DropList]),	
	lib_server_send:send_to_uid(PlayerId, BinData).

%% 设置下一次计算的时间.
set_next_calc_time(_DungeonDataPid, PlayerId) -> 
	
    %% 计算剩余时间.
    Data = get_info(PlayerId),

    %% 取值
    #auto_story_dun_record{
        state       = State
        %auto_num    = AutoNum,
        %begin_time  = BeginTime,
        %finish      = Finish
    } = Data,

    Time = case State =:= 1 of
        true ->
            data_story_dun_config:get_config(auto_time);
            %NowTime = util:unixtime(),
            %AutoTime = data_story_dun_config:get_config(auto_time),
            %TotalTime = (AutoNum - Finish) * AutoTime, 
            %CloseTime1 = BeginTime + TotalTime - NowTime,
            %max(0, CloseTime1);
        false ->
            0
    end,
	%% 设置定时器.	
	case Time of
		0 ->
			put("calc_auto_story_dungeon", undefined);
		_Time -> skip
			%RefreshTimer = erlang:send_after(Time*1000, DungeonDataPid, {'calc_auto_story_dungeon', PlayerId}),
			%put("calc_auto_story_dungeon", RefreshTimer)
	end.

%% 是否在挂机中.
is_auto_story(PlayerId, DungeonId) ->
	case data_dungeon:get(DungeonId) of
		[] ->
			false;
		DungeonData ->	
			case DungeonData#dungeon.type of
				?DUNGEON_TYPE_STORY ->
					AutoData = get_info(PlayerId),
					case DungeonId =:= AutoData#auto_story_dun_record.dungeon_id of
						true -> 
							true;
						false ->
							false
					end;	
				_ ->
					false
			end
	end.

%% --------------------------------- 内部函数 ----------------------------------

%% 计算副本挂机结果.
calc_auto(PlayerId) ->
	AutoData = get_info(PlayerId),
    #auto_story_dun_record{
        state        = State,
        begin_time   = BeginTime,
        finish       = Finish,
        id           = PlayerId,
        auto_num     = AutoNum,
        dungeon_id   = DungeonId,
        drop_data_list = DropDataList
    } = AutoData,
	
	{Success, PlayerPid, DailyPid, PlayerLevel} = 
		case lib_player:get_player_info(PlayerId, auto_story_dungeon) of
			{ok, _PlayerPid, _DailyPid, _PlayerLevel} ->
			    case is_pid(_DailyPid) andalso misc:is_process_alive(_DailyPid) of
				    false -> 
						{false, 0, 0, 0};
				    true -> 
				        {true, _PlayerPid, _DailyPid, _PlayerLevel}
			    end;
			_ ->
				{false, 0, 0, 0}
		end,

	case State == 1 andalso Success of
		true ->
			%1.得到现在完成几个副本.
			AutoTime  = data_story_dun_config:get_config(auto_time),
			NowFinish = (util:unixtime()-BeginTime) div AutoTime,
			TotalLen  = AutoNum,
		
			%2.是否可以发送奖励.
            case Finish < TotalLen of
                true ->
                    F = fun(I, TmpDropDataList) -> 
                            DropData = calc_reward(DungeonId, PlayerId, PlayerPid, DailyPid, PlayerLevel, I),
                            {ok, TmpDropDataList++[DropData]}
                    end,
                    %2.计算奖励.
                    RewardFinish = min(NowFinish, TotalLen),
                    {ok, NewDropDataList} = util:for(Finish+1, RewardFinish, F, DropDataList),

                    AutoData1 = get_info(PlayerId),
                    %3.保存现在的结果. 
                    AutoData2 = 
                    case NowFinish >= TotalLen of
                        %1.已经完成了挂机.
                        true ->
                            %% 发送挂机结果邮件.
                            send_mail(PlayerId),

                            save(AutoData1#auto_story_dun_record{finish=TotalLen, drop_data_list = NewDropDataList}),
                            send_auto_info(PlayerId),

                            %2.清空挂机信息.
                            erase(?AUTO_STORY_DUNGEON_KEY(PlayerId)),
                            AutoData1#auto_story_dun_record{
                                id           = PlayerId,
                                dungeon_list = [],
                                begin_time   = 0,
                                exp          = 0,
                                wuhun        = 0,
                                finish       = 0,
                                chapter      = 0,
                                state        = 0,
                                dungeon_id   = 0,
                                auto_num     = 0,
                                drop_data_list=[]
                            };
                        %2.还没完成挂机.														  
                        false -> 
                            AutoData1#auto_story_dun_record{finish=NowFinish, drop_data_list=NewDropDataList}
                    end,
                    save(AutoData2);

                    %4.判断自己是否可以成为霸主.
                    %lib_story_dungeon:save_story_total_score(PlayerId, DungeonId);
				false -> 
					skip
			end;
		false ->
			skip
	end.

%% 计算奖励.
calc_reward(DungeonId, PlayerId, PlayerPid, _DailyPid, PlayerLevel, DropNo) ->
	case data_story_dun_config:get_mon_id(DungeonId) of
		0 ->
			skip;
		MonId ->			
			case data_mon:get(MonId) of
				[] ->skip;
				MonData ->
					MonLevel = MonData#ets_mon.lv,
					Exp = MonData#ets_mon.exp,
					
					%1.扣除副本次数.
					%AutoData0 = get_info(PlayerId),
				    %NowTime = util:unixtime(),
				    %{TodayMight, _NextMight} = util:get_midnight_seconds(NowTime),					
					%case AutoData0#auto_story_dun_record.begin_time > TodayMight of
					%	true ->
					%		%1.每日次数加一.
					%		%mod_daily:increment(DailyPid, PlayerId, DungeonId),		
					%		%2.剧情副本杀死BOSS总次数才加一.
					%		mod_dungeon_data:increment_total_count(self(), PlayerId, DungeonId);
					%	false ->
					%		mod_dungeon_data:increment_total_count(self(), PlayerId, DungeonId)
					%end,

                    mod_dungeon_data:increment_total_count(self(), PlayerId, DungeonId),

					%1.经验.
                    Exp2 = Exp*lib_player:reduce_mon_exp_arg(PlayerLevel, MonLevel),
					Exp3 = round(Exp2),
					gen_server:cast(PlayerPid, {'EXP', Exp3}),
		
					%2.武魂值.
					WuHun = set_whpt(MonId, PlayerPid),
					
					%3.掉落物品.
					DropList = mon_drop(MonData, PlayerLevel),
		
					%4.保存经验和武魂值.
					AutoData = get_info(PlayerId),
					Exp4 = Exp3 + AutoData#auto_story_dun_record.exp,
					WuHun2 = WuHun + AutoData#auto_story_dun_record.wuhun,			
					AutoData2 = AutoData#auto_story_dun_record{exp=Exp4, wuhun = WuHun2},
					save(AutoData2),
		
					%% 剧情副本自动挂机奖励物品.
				    Chapter = data_story_dun_config:get_chapter_id(DungeonId),
					gen_server:cast(PlayerPid, {'auto_story_dungeon_drop', DropList, Chapter}),
					
					DropList2 = [{DropInfo#ets_drop_goods.goods_id, 1}|| DropInfo <- DropList],
					DropList3 = make_goods_list([], DropList2),

					
					%% 剧情副本掉落.
					DropRecord = #auto_drop_record{
						dungeon_id = DungeonId,
                        drop_no = DropNo,
						exp = Exp3,
						wuhun = WuHun,
						goods_list = DropList3
					},

                    DropRecord
			end
	end.	

%% 新建挂机信息.
new([PlayerId, DungeonId, BeginTime, Exp, WuHun, Finish, AutoNum]) ->	
    #auto_story_dun_record{
        id           = PlayerId,
		dungeon_id   = DungeonId,
		begin_time   = BeginTime,
		exp          = Exp,
		wuhun        = WuHun,
		finish       = Finish,
        auto_num     = AutoNum,
		state        = case BeginTime > 0 of true -> 1; false -> 0 end						   
    }.

%% 保存挂机信息.
save(AutoData) ->
	PlayerId = AutoData#auto_story_dun_record.id,
	put(?AUTO_STORY_DUNGEON_KEY(PlayerId), AutoData),
	db:execute(
		io_lib:format(?sql_replace_player_story_dungeon, [
			PlayerId,
            AutoData#auto_story_dun_record.dungeon_id,
			AutoData#auto_story_dun_record.begin_time,
			AutoData#auto_story_dun_record.exp,
			AutoData#auto_story_dun_record.wuhun,
			AutoData#auto_story_dun_record.finish,
            AutoData#auto_story_dun_record.auto_num]
		)
	).

%% 所有数据重载.
reload(PlayerId) ->
    Key = ?AUTO_STORY_DUNGEON_KEY(PlayerId),
	erase(Key),
	Sql = io_lib:format(?sql_select_player_story_dungeon, [PlayerId]),
    case db:get_row(Sql) of
        [] ->
			AutoData = #auto_story_dun_record{id = PlayerId},	
			put(Key, AutoData),
			AutoData;
        [PlayerId, DungeonId, BeginTime, Exp, WuHun, Finish, AutoNum] ->
			AutoData = new([ PlayerId, 
							 DungeonId, 
							 BeginTime, 
							 Exp, 
							 WuHun, 
							 Finish, 
							 AutoNum]),
			put(Key, AutoData),
			AutoData
    end.

%% 获取挂机信息.
get_info(PlayerId) ->
	Data1 = get(?AUTO_STORY_DUNGEON_KEY(PlayerId)),
    case Data1 =:= undefined of
        true ->
            reload(PlayerId);
        false ->
            Data1
    end.

%% 设置武魂值
set_whpt(MonId, PlayerPid) ->
	%1.计算武魂值.
	WHPT = data_story_dun_config:get_whpt(MonId),
	
	%2.发给玩家武魂值.			
	if WHPT > 0 ->
			gen_server:cast(PlayerPid, {'set_data', [{add_whpt, WHPT}]});
	    true ->
			skip
	end,

	%3.返回武魂值.
	WHPT.

%% 怪物掉落.
mon_drop(MonData, PlayerLevel) ->
    case data_drop:get_rule(MonData#ets_mon.mid) of
        %1.掉落规则不存在.
        [] ->
            [];
		
        %2.普通怪掉落.
        DropRule when DropRule#ets_drop_rule.boss =:= 0 ->
		    %% 取掉落物品列表
		    [StableGoods, _TaskGoods, RandGoods, _, _] = lib_goods_drop:get_drop_goods_list(DropRule),
		    %% 取随机物品掉落数列表
		    DropNumList = lib_goods_drop:get_drop_num_list(DropRule),
		    %% 掉落物品
		    DropGoods = lib_goods_drop:drop_goods_list(RandGoods, DropNumList),
		    DropList = StableGoods ++ DropGoods,
			%% 过虑衰减物品.
			filter_reduce_list(DropList, [], PlayerLevel, MonData#ets_mon.lv);
		
		%3.BOSS怪掉落.
        DropRule ->
			%% 取掉落物品列表
            [StableGoods, _TaskGoods, RandGoods, _, _] = lib_goods_drop:get_drop_goods_list(DropRule),
            NowTime = util:unixdate(),
            %% 过滤随机掉落物品列表
            RandGoods2 = lib_goods_drop:filter_goods(RandGoods, {NowTime, DropRule#ets_drop_rule.counter_goods}),
            DropNumList = lib_goods_drop:get_drop_num_list(DropRule),
			%% 掉落物品
            DropGoods = lib_goods_drop:drop_goods_list(RandGoods2, DropNumList),
            DropList = StableGoods ++ DropGoods,
			%% 过虑衰减物品.
			filter_reduce_list(DropList, [], PlayerLevel, MonData#ets_mon.lv)
    end.

%% 组合物品[物品ID, 物品数量].
make_goods_list(GoodsList1, []) ->
	GoodsList1;
make_goods_list(GoodsList1, [{Key, Count}|GoodsList2]) ->
    case lists:keyfind(Key, 1, GoodsList1) of
        false -> 
			make_goods_list(GoodsList1++[{Key, Count}], GoodsList2);
        {_Key1, Count1} ->			
            NewGoodsList = lists:keyreplace(Key, 1, GoodsList1, {Key, Count1 + Count}),
			make_goods_list(NewGoodsList, GoodsList2)
	end.
									  
%% 过虑衰减物品.
filter_reduce_list([], L, _PlayerLevel, _MonLevel) ->
    L;
filter_reduce_list([DropInfo|H], L, PlayerLevel, MonLevel) ->
    if
        is_record(DropInfo, ets_drop_goods) =:= true ->
            case DropInfo#ets_drop_goods.reduce =:= 0 of
                true ->
                    filter_reduce_list(H, [DropInfo|L], PlayerLevel, MonLevel);
                false ->
                    Rand = util:rand(1, 100),
                    Level = round(PlayerLevel - MonLevel),
                    if
                        Level >= 5 andalso Level < 8 andalso Rand < 25 ->
                            filter_reduce_list(H, L, PlayerLevel, MonLevel);
                        Level >= 8 andalso Level < 11 andalso Rand < 50 ->
                            filter_reduce_list(H, L, PlayerLevel, MonLevel);
                        Level >= 11 andalso Level < 15 andalso Rand < 75 ->
                            filter_reduce_list(H, L, PlayerLevel, MonLevel);
                        Level >= 15 ->
                            filter_reduce_list(H, L,PlayerLevel, MonLevel);
                        true ->
                            filter_reduce_list(H, [DropInfo|L], PlayerLevel, MonLevel)
                    end
            end;
        true ->
            filter_reduce_list(H, L, PlayerLevel, MonLevel)
    end.

%% 组合物品文本[物品ID, 物品数量].
make_goods_text(GoodsTextList, []) ->
	GoodsTextList;
make_goods_text(GoodsTextList, [{Key, Count}|GoodsList]) ->
	case data_goods_type:get(Key) of
		%% 物品不存在
        [] -> 
            make_goods_text(GoodsTextList, GoodsList);
        GoodsTypeInfo ->
			GoodsTextList2 = 
				lists:concat([
				    GoodsTextList,
					"\n　　",
					binary_to_list(GoodsTypeInfo#ets_goods_type.goods_name),
					"*",
					Count]),
			make_goods_text(GoodsTextList2, GoodsList)
	end.

%% 发送挂机结果邮件.
send_mail(PlayerId) ->
	%1.获取自动挂机信息.
	Data = get_info(PlayerId),
    #auto_story_dun_record{
        drop_data_list = DropDataList,
        auto_num = AutoNum
    } = Data,
	
	%4.获取副本掉落列表.
    F = fun(DropData) -> DropData#auto_drop_record.goods_list end,
    DropGoodsList = lists:flatmap(F, DropDataList),
	DropGoodsList2 = make_goods_list([], DropGoodsList), 
	GoodsTextList = make_goods_text([], DropGoodsList2),
	
	GoodsLen = length(DropGoodsList2),
	Text =
		case GoodsLen of
			0 ->
				data_dungeon_text:get_auto_story_config(
			           content1, 
					   [AutoNum,
						Data#auto_story_dun_record.exp,
						Data#auto_story_dun_record.wuhun]);
			_ ->
				data_dungeon_text:get_auto_story_config(
			           content2, 
					   [AutoNum,
						Data#auto_story_dun_record.exp,
						Data#auto_story_dun_record.wuhun,
						GoodsTextList])
			end,
	mod_disperse:cast_to_unite(lib_mail, send_sys_mail,
		[[PlayerId],
		 data_dungeon_text:get_auto_story_config(title1,1),
		 Text]).
