%%%-----------------------------------
%%% @Module  : lib_tower_dungeon
%%% @Author  : zzm
%%% @Email   : ming_up@gmail.com
%%% @Created : 2011.01.06
%%% @Description: 锁妖塔（如无特殊说明，都在公共服务器执行）
%%%-----------------------------------

-module(lib_tower_dungeon).

%% 公共函数：外部模块调用.
-export([
        get_master/0,                    %% 获取所有霸主
        get_master/1,                    %% 获取一层的霸主
        online/0,                        %% 上线锁妖塔初始
        be_master/6,                     %% 是否能当上霸主
        next_level_get_master/2,         %% 获取霸主
        clean_master_reward/0,           %% 每天12点清理领过奖励的霸主
        dis_master/0,                    %% 霸主显示
        rank_master/1,                   %% 霸主排行榜
		get_master_player_id_list/1,     %% 获取霸主id列表.
        check_honour/3,                  %% 所有人的荣誉是否大于Num值
		set_tower_reward/2,              %% 设置爬塔副本奖励.
		get_tower_reward/1               %% 获取爬塔副本奖励.
    ]).

%% 内部函数：副本服务本身调用.
-export([
        set_master/4,                    %% 写入霸主
        update_master/5,                 %% 更新霸主
		delete_master/1,                 %% 删除该层霸主
        is_master/2,                     %% 是否是霸主
        get_reward/2,                    %% 领取奖励
        tower_reward_mail/20,            %% 远征岛邮件奖励内容        
		repair_tower_name/1,             %% 修复塔名字函数
        is_can_skip_floor/1,             %% 是否可以跳层
        is_can_skip_floor_leader/1,      %% 是否可以跳层，只检查队长
        reward/9,                        %% 奖励结算
		send_tower_cw/3                  %% 发送当上霸主的传闻.
    ]).

%-include("record.hrl").
-include("common.hrl").
-include("server.hrl").
-include("dungeon.hrl").
-include("tower.hrl").
-include("sql_dungeon.hrl").

%% 获取一层的霸主
get_master(SceneId) ->
	Sql = io_lib:format(?sql_select_tower_masters, [SceneId]),    
    case db:get_row(Sql) of
        [] -> [];
        [SceneId, P, PassTime, Re, DunId] -> 
            case util:bitstring_to_term(P) of 
                undefined -> [];
                Players -> 
                    case util:bitstring_to_term(Re) of
                        undefined -> [];
                        Reward -> [SceneId, Players, PassTime, Reward, DunId]
                    end
            end
    end.

%% 写入霸主
set_master(SceneId, Players, PassTime, DunId) ->
    case util:term_to_bitstring(Players) of
        <<"undefined">> -> error;
        P ->
			Sql = io_lib:format(?sql_insert_tower_masters, [SceneId, P, PassTime, DunId]),
            db:execute(Sql),
            ets:insert(?ETS_TOWER_MASTER, 
                #ets_tower_master{
                    sid = SceneId,
                    players = Players,
                    passtime = PassTime,
                    dun_id = DunId
                })
    end.

%% 更新霸主
update_master(SceneId, Players, PassTime, Reward, DunId) ->
    case util:term_to_bitstring(Players) of
        <<"undefined">> -> error;
        P -> case util:term_to_bitstring(Reward) of
                <<"undefined">> -> error;
                Re ->
					Sql = io_lib:format(?sql_replace_tower_masters, [SceneId, P, PassTime, Re, DunId]),
                    db:execute(Sql),
                    ets:insert(?ETS_TOWER_MASTER, 
                        #ets_tower_master{
                            sid = SceneId,
                            players = Players,
                            passtime = PassTime,
                            reward = Reward,
                            dun_id = DunId
                        })
            end
    end.

%% 删除该层霸主
delete_master(Sid) ->
    ets:delete(?ETS_TOWER_MASTER, Sid),
	Sql = io_lib:format(?sql_delete_tower_masters, [Sid]),
    db:execute(Sql).

%% 获取所有霸主
get_master() ->
    case db:get_all(?sql_select_all_tower_masters) of
        R when is_list(R) -> 
            F = fun([SceneId, P, PassTime, Re, DunId]) -> 
                    case util:bitstring_to_term(P) of 
                        undefined -> [];
                        Players -> case util:bitstring_to_term(Re) of
                                undefined -> [];
                                Reward ->
                                    ets:insert(?ETS_TOWER_MASTER, #ets_tower_master{
                                            sid = SceneId,
                                            players = Players,
                                            passtime = PassTime,
                                            reward = Reward,
                                            dun_id = DunId
                                        }),
                                    update_master(SceneId, Players, PassTime, Reward, DunId),
                                    [[SceneId, Players, PassTime, Reward, DunId]]
                            end
                    end
            end,
            %[F(E) || E <- R];
            lists:flatmap(F, R);
        _ -> []
    end.

%% 上线锁妖塔初始
online() ->
    get_master(),
    %% 其他功能初始数据
    lib_achieved_name:init_overlords_info(),
    ok.

%% 是否能当上霸主
be_master(SceneId, Players, Time, _Online, TowerName, DunId) -> %% 这里的SceneId是资源id

    %定义清除前面的霸主内部函数.
    FunClearMaster
		= fun(Masters) ->
            %Id = element(1, Master),
            MasterIds = [element(1, P)||P <- Masters],
            case is_master(MasterIds, DunId) of
                [] -> Masters;
                [R|_] -> 
                    case SceneId >= R#ets_tower_master.sid  of 
                        true -> %% 现在的层数比以前的层数大
                            %case lists:keydelete(Id, 1, R#ets_tower_master.players) of
                                %[] -> 
                                    delete_master(R#ets_tower_master.sid),
                                %MasL -> update_master(R#ets_tower_master.sid, 
								%					  MasL, 
								%					  R#ets_tower_master.passtime, 
								%					  R#ets_tower_master.reward,
								%					  R#ets_tower_master.dun_id)
                            %end,
                            Masters;
                        false -> []
                    end
            end
    	end,
	
    case ets:lookup(?ETS_TOWER_MASTER, SceneId) of
		%1.这层没有设置霸主.
        [] -> 
            %NewPlayers = lists:flatmap(FunClearMaster, Players),
            NewPlayers = FunClearMaster(Players),
            case NewPlayers of
                [] -> ok;
                _ ->
					TowerInfo = data_tower:get(SceneId),
					%1.闯天路：单人通过九重天的第N层.
					if length(NewPlayers) == 1 andalso DunId == 340 ->
						[Player1] = NewPlayers, 
						{Id, _Lv, _Realm, _Career, _Sex, _Weapon, _Cloth, _WLight, 
						 _CLight, _ShiZhuang, _SuitId, _Vip, _Nick} = Player1,
						case lib_player:get_player_info(Id, achieve) of
							false -> ok;
							StatusAchieve -> lib_player_unite:trigger_achieve(Id, trigger_trial, [StatusAchieve, Id, 32, 0, TowerInfo#tower.level])
						end;
						true -> ok
					end,

					%2.设置霸主数据.
                    set_master(SceneId, NewPlayers, Time, DunId),
                    %spawn(fun lib_achieved_name:handle_overlords_change/0),
                    %TowerInfo = data_tower:get(SceneId),					
                    %lib_chat:send_cw_tower(NewPlayers, TowerInfo#tower.level, Online, TowerName)

					%3.发送当上霸主的传闻.
					send_tower_cw(NewPlayers, TowerInfo#tower.level, TowerName)					
            end;
		%2.这层已经存在霸主.
        [R] -> 
            case R#ets_tower_master.passtime > Time of
                true -> 
                    %NewPlayers = lists:flatmap(FunClearMaster, Players),
                    NewPlayers = FunClearMaster(Players),
                    case NewPlayers of
                        [] -> ok;
                        _ ->
							TowerInfo = data_tower:get(SceneId),
							
							%2.更新霸主数据.
                            update_master(SceneId, NewPlayers, Time, [], R#ets_tower_master.dun_id),
                            %spawn(fun lib_achieved_name:handle_overlords_change/0),
                            %TowerInfo = data_tower:get(SceneId)
                            %lib_chat:send_cw_tower(NewPlayers, TowerInfo#tower.level, Online, TowerName)

							%3.发送当上霸主的传闻.
							send_tower_cw(NewPlayers, TowerInfo#tower.level, TowerName)	
                    end;
                false -> ok
            end
    end.

%% 获取霸主
next_level_get_master(Ids, SceneId) -> %% 这里的SceneId是资源id
    case ets:lookup(?ETS_TOWER_MASTER, SceneId) of
        [] ->
			ok;
        [R] ->
            {ok, BinData} = pt_280:write(28001, [R#ets_tower_master.players, R#ets_tower_master.passtime]),
            [lib_unite_send:send_to_one(Id, BinData) || Id <- Ids]
    end.

%% 是否是霸主 -> [] | R(record:ets_tower_master)
is_master(Ids, DunId) ->
    %io:format("towername:~s~n", [TowerName]),
    %L = ets:tab2list(?ETS_TOWER_MASTER),
    L = ets:match_object(?ETS_TOWER_MASTER, #ets_tower_master{dun_id = DunId, _ = '_'}),
    Len = length(Ids),
    F = fun(R) ->
            case Len == length(R#ets_tower_master.players) of
                false -> [];
                true -> 
                     MasterIds = [element(1, Element) || Element <- R#ets_tower_master.players],
                     case MasterIds -- Ids of
                         [] -> [R];
                         _  -> []
                     end
             end
            %case lists:keyfind(Id, 1, R#ets_tower_master.players) of
            %    false -> [];
            %    _ -> [R]
            %end
    end, 
    lists:flatmap(F, L).

%% 领取奖励
get_reward(Id, DunId) ->
    case is_master([Id], DunId) of
        [] -> not_master;
        L ->
            F = fun(R) ->
                    case lists:member(Id, R#ets_tower_master.reward) of
                        false -> [R#ets_tower_master.sid];
                        true -> [0]
                    end
            end,
            L1 = lists:flatmap(F, L),
            case lists:member(0, L1) of
                true -> has_gotten;
                false ->
                    RewardSid = lists:max(L1),
                    case ets:lookup(?ETS_TOWER_MASTER, RewardSid) of
                        [] -> ok;
                        [R2] -> 
                            update_master(R2#ets_tower_master.sid, 
										  R2#ets_tower_master.players, 
										  R2#ets_tower_master.passtime, 
										  [Id|R2#ets_tower_master.reward], 
										  R2#ets_tower_master.dun_id)
                    end,
                    RewardSid
            end
    end.

%% 每天12点清理领过奖励的霸主
clean_master_reward() -> 
    db:execute(?sql_update_tower_masters),
    L = ets:tab2list(?ETS_TOWER_MASTER),
    [ets:insert(?ETS_TOWER_MASTER, R#ets_tower_master{reward = []}) || R <- L].

%% 霸主显示
dis_master() ->
    L = ets:tab2list(?ETS_TOWER_MASTER),
    F = fun(ETM) ->
            PL = [{Id, Nick}||{Id, _Lv, _Realm, _Career, _Sex, _Weapon, _Cloth, 
							   _WLight, _CLight, _ShiZhuang, _SuitId, _Vip, Nick} 
				 <- ETM#ets_tower_master.players],
            TowerInfo = data_tower:get(ETM#ets_tower_master.sid),
            {TowerInfo#tower.level, PL, 
			 ETM#ets_tower_master.passtime, 
			 ETM#ets_tower_master.dun_id}
    end,
    [F(X)||X<-L].

%% 霸主排行榜
%% Type: 1单人九重天, 2多人九重天
rank_master(Type) ->
    DunId = case Type of
        1 -> 340;
        2 -> 300;
        _ -> 300
    end,
    %L = ets:tab2list(?ETS_TOWER_MASTER),
    L = ets:match_object(?ETS_TOWER_MASTER, #ets_tower_master{dun_id = DunId, _ = '_'}),
    F = fun(ETM) ->
            PL = [Nick || {_Id, _Lv, _Realm, _Career, _Sex, _Weapon, _Cloth, 
						   _WLight, _CLight, _ShiZhuang, _SuitId, _Vip, Nick} 
				 <- ETM#ets_tower_master.players],
            TowerInfo = data_tower:get(ETM#ets_tower_master.sid),
            [TowerInfo#tower.level, PL, ETM#ets_tower_master.passtime]
    end,
    [F(X)||X<-L].

%% 获取霸主id列表.
%% Type: 1单人九重天, 2多人九重天
get_master_player_id_list(Type) ->
    DunId = case Type of
        1 -> 340;
        2 -> 300;
        _ -> 300
    end,
    %L = ets:tab2list(?ETS_TOWER_MASTER),
    L = ets:match_object(?ETS_TOWER_MASTER, #ets_tower_master{dun_id = DunId, _ = '_'}),
    F = fun(ETM) ->
            PL = [Id || {Id, _Lv, _Realm, _Career, _Sex, _Weapon, _Cloth, 
						   _WLight, _CLight, _ShiZhuang, _SuitId, _Vip, _Nick} 
				 <- ETM#ets_tower_master.players],
            TowerInfo = data_tower:get(ETM#ets_tower_master.sid),
            [TowerInfo#tower.level, PL, ETM#ets_tower_master.passtime]
    end,
    [F(X)||X<-L].

%% 所有人的荣誉是否大于Num值
check_honour(Status, Ids, Num) ->
    Fun = 
		fun(MemberId, LastResult) ->
			Result =				
				if
					%1.检测自己的等级. 
					MemberId == Status#player_status.id ->
				   		Status#player_status.chengjiu#status_chengjiu.honour >= Num;
				    %2.检测别人的等级.
				 	true ->  
			            case lib_player:get_player_info(MemberId) of
			                [] -> false;
			                PlayerStatus -> 
			                    %io:format("Id:~p, Honour:~p~n", [R#ets_online.id, R#ets_online.honour]),
			                    PlayerStatus#player_status.chengjiu#status_chengjiu.honour >= Num
			            end
				end,
            Result and LastResult
    	end,
    lists:foldl(Fun, true, Ids).

%% 远征岛邮件奖励内容
tower_reward_mail(Uid, PlayerLevel, TowerType, TowerName, Level, Exp, Llpt, 
				  _Honour, _KingHonour, ExReward, LineSign, _ActiveScene, 
				  _ActiveBox, TotalTime, MemberIds, BeginTime, LastLayerTime, 
				  Ratio, LogoutType, CombatPower) ->
    %% 倍数
    {Times, TowerName1} = case Ratio > 0 of
        true ->  {2, data_dungeon_text:get_tower_text(4, [TowerName])};
        false -> {1, TowerName}
    end,
    ExpMsg = case Exp > 0 of
        true -> lists:concat([trunc(Exp*Times), data_dungeon_text:get_tower_text(19)]);
        false -> ""
    end,
    LlMsg = case Llpt > 0 of
        true -> lists:concat([trunc(Llpt*Times), data_dungeon_text:get_tower_text(20)]);
        false -> ""
    end,
    ExRewardMsg = case ExReward =:= 1 of
        true -> data_dungeon_text:get_tower_text(21);
        false -> ""
    end,
    %HonourMsg = case Honour > 0 of
    %    true -> lists:concat([trunc(Honour*Times), data_dungeon_text:get_tower_text(22)]);
    %    false -> ""
    %end,
    %KingHonourMsg = case KingHonour > 0 of
    %    true -> lists:concat([trunc(KingHonour*Times), data_dungeon_text:get_tower_text(23)]);
    %    false -> ""
    %end,
    LineSignMsg = case LineSign =:= 0 of
        true -> 
			lists:concat([data_dungeon_text:get_tower_text(24), 
						  TowerName1, 
						  data_dungeon_text:get_tower_text(25),
						  Level,
						  data_dungeon_text:get_tower_text(26)]);
        false -> 
			lists:concat([data_dungeon_text:get_tower_text(27),
						  TowerName1,
						  data_dungeon_text:get_tower_text(5),
						  Level, 
						  data_dungeon_text:get_tower_text(28)])
    end,
%%     %% 跳层礼包
%%     {GoodsId, GoodsNum} = case {ActiveScene, ActiveBox} of
%%         {309, 0} -> {532209, 1};
%%         {420, 0} -> {533402, 1};
%%         {440, 0} -> {533403, 1};
%%         {450, 0} -> {533404, 1};
%%         _ -> {0, 0}
%%     end,

    %% 跳层礼包
    GoodsNum = Times,
    GoodsId = 
		if 
			Level >= 3 andalso Level =< 14 -> 
				532213;
			Level >= 15 andalso Level =< 25 -> 
				532214;
			Level >= 26 -> 
				532215;		
			true -> 
				0
	    end,
    case Exp > 0 orelse Llpt > 0 of
        true ->
            case GoodsId /= 0 of
                true -> 
					mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, 
						[[Uid], TowerName1 ++ data_dungeon_text:get_tower_text(29),
						lists:concat([data_dungeon_text:get_tower_text(30), 
									  LineSignMsg, 
                                      %HonourMsg, 
									  %KingHonourMsg,
									  data_dungeon_text:get_tower_text(31), 
									  ExpMsg, 
									  LlMsg, 
									  data_dungeon_text:get_tower_text(32), 
									  ExRewardMsg]), 
									  GoodsId, 2, 0, 0, GoodsNum, 0, 0, 0, 0]);
                false ->
					mod_disperse:cast_to_unite(lib_mail, send_sys_mail,
						[[Uid], TowerName1 ++ data_dungeon_text:get_tower_text(29), 
						lists:concat([data_dungeon_text:get_tower_text(30), 
									 LineSignMsg, 
									 %HonourMsg, 
									 %KingHonourMsg,
									 %data_dungeon_text:get_tower_text(31), 
									 ExpMsg, LlMsg, 
									 data_dungeon_text:get_tower_text(32), 
									 ExRewardMsg])])
            end,
		log:log_tower_dungeon(Uid, PlayerLevel, TowerType, Level, TotalTime, 
			GoodsId, MemberIds, BeginTime, LastLayerTime, LogoutType, CombatPower);
        false -> ok
    end.

%% 修复塔名字函数
repair_tower_name(Sid) ->
    case Sid < 431 of
        true -> 
			data_dungeon_text:get_tower_text(33);
        false -> 
			data_dungeon_text:get_tower_text(34)
    end.

%% 是否可以跳层
is_can_skip_floor(_MbIds) ->
	ok.
%%     Fun = fun(Id, {Result, Nicks}) ->
%%             {Result1, Nick} = case ets:lookup(?ETS_ONLINE, Id) of
%%                [] -> {true, []};
%%                [Player] -> case mod_daily:get_count(Id, 2800) < (Player#ets_online.vip_type + mod_daily:get_count(Id, 2801)) of
%%                         true -> {true, []};
%%                         false -> {false, Player#ets_online.nickname}
%%                     end
%%             end,
%%             {Result1 and Result, [Nick]++" "++Nicks} 
%%     end,
%%     lists:foldl(Fun, {true, []}, MbIds).

%% 是否可以跳层，只检查队长
is_can_skip_floor_leader(Status) ->
	mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 2800) < Status#player_status.vip#status_vip.vip_type.

%% 奖励结算 -> {经验，历练声望，物品列表，荣誉，帝王谷荣誉，是否经验加成，是否奖励宝盒, 塔名字, 奖励层数, 所耗总时间} | false
%% Type: 1 表示正常奖励, 0 表示中途下线奖励
reward(Id, PlayerLevel, DungeonId, _DungeonDataPid, Type, LastLayerTime, Ratio, 
	   LogoutType, CombatPower) ->
    case get_tower_reward(Id) of
        [] -> 
			false;
        [R] ->
            [Exp, Llpt, Items, Honour, KingHonour, ActiveBox] = case R#ets_tower_reward.reward_sid == 0 of
                true -> [0, 0, [], 0, 0, 0];
                false -> 
                    TowerInfo = data_tower:get(R#ets_tower_reward.reward_sid),
                    [TowerInfo#tower.total_exp, 
                        TowerInfo#tower.total_llpt, 
                        TowerInfo#tower.total_items,
                        TowerInfo#tower.total_honour,
                        TowerInfo#tower.total_king_honour,
                        1
                    ]
            end,
            TowerInfo2 = data_tower:get(R#ets_tower_reward.fin_sid),
			set_tower_reward(Id, R#ets_tower_reward{reward_sid = R#ets_tower_reward.fin_sid}),
            case TowerInfo2#tower.total_exp - Exp > 0 of
                true ->
                    DungeonInfo = data_dungeon:get(R#ets_tower_reward.begin_sid),
                    TowerName = binary_to_list(DungeonInfo#dungeon.name),
                    AfterCutItems = TowerInfo2#tower.total_items -- Items,
                    AfterCutHonour = TowerInfo2#tower.total_honour - Honour,
                    AfterCutKingHonour = TowerInfo2#tower.total_king_honour - KingHonour,
                    {AfterExRExp, AfterExRLlpt, ExRewardSign} = case R#ets_tower_reward.exreward of
                        1 ->  %% 一般奖励
                            {TowerInfo2#tower.total_exp - Exp, TowerInfo2#tower.total_llpt - Llpt, 0};
                        ExReward -> %% 三种职业提高20%的奖励
                            {round((TowerInfo2#tower.total_exp - Exp)*ExReward), 
							 round((TowerInfo2#tower.total_llpt - Llpt)*ExReward), 1}
                    end,
                    %1.发送邮件.
					TotalTime = util:unixtime() - R#ets_tower_reward.dungeon_time,
					TowerType = 
						case DungeonId of
							300 -> 2; %多人副本.
							340 -> 1; %单人.
							_   -> 3
						end,
                    tower_reward_mail(Id, PlayerLevel, TowerType, TowerName, TowerInfo2#tower.level, 
									  AfterExRExp, AfterExRLlpt, AfterCutHonour, 
									  AfterCutKingHonour, ExRewardSign, Type, 
									  R#ets_tower_reward.active_scene, ActiveBox, 
									  TotalTime, 
									  R#ets_tower_reward.member_ids,
									  R#ets_tower_reward.dungeon_time,
                                      LastLayerTime, Ratio, LogoutType, CombatPower),
                    %% 清理副本奖励
                    erase_tower_reward(Id),
                    CountNum = case Ratio > 0 of
                        true -> 2;
                        false -> 1
                    end,
                    case TowerType of
                        1 -> 
                            %打完单人九重天
                            lib_off_line:add_off_line_count(Id, 9, CountNum, TowerInfo2#tower.level);
                        2 -> 
                            %打完多人九重天
                            lib_off_line:add_off_line_count(Id, 10, CountNum, TowerInfo2#tower.level);
                        3 -> skip
                    end,
                    
                    {AfterExRExp, AfterExRLlpt, AfterCutItems, AfterCutHonour, 
					 AfterCutKingHonour, ExRewardSign, ActiveBox, TowerName, 
					 TowerInfo2#tower.level, TotalTime};
                false -> false
            end
    end.

%% 发送当上霸主的传闻.
send_tower_cw(PlayerList, Level, TowerName) ->
	[Count,Id1, Realm1, Nick1, Sex1, Career1, HeadType1,
	Id2, Realm2, Nick2, Sex2, Career2, HeadType2,
	Id3, Realm3, Nick3, Sex3, Career3, HeadType3] =
		case length(PlayerList) of
			1 ->[Player1] = PlayerList, 
				{_Id1, _Lv1, _Realm1, _Career1, _Sex1, _Weapon1, _Cloth1, _WLight1, 
				  _CLight1, _ShiZhuang1, _SuitId1, _Vip1, _Nick1} = Player1,				 
				[1, _Id1, _Realm1, _Nick1, _Sex1, _Career1, 0,
				    0,0,"",0,0,0,
				 	0,0,"",0,0,0];
			2 -> [Player1, Player2] = PlayerList,
				 {_Id1, _Lv1, _Realm1, _Career1, _Sex1, _Weapon1, _Cloth1, _WLight1, 
				  _CLight1, _ShiZhuang1, _SuitId1, _Vip1, _Nick1} = Player1,
				 {_Id2, _Lv2, _Realm2, _Career2, _Sex2, _Weapon2, _Cloth2, _WLight2, 
				  _CLight2, _ShiZhuang2, _SuitId2, _Vip2, _Nick2} = Player2,	
				[2, _Id1, _Realm1, _Nick1, _Sex1, _Career1, 0,
				    _Id2, _Realm2, _Nick2, _Sex2, _Career2, 0,
				 	0,0,"",0,0,0];
			3 -> [Player1, Player2, Player3] = PlayerList,
				 {_Id1, _Lv1, _Realm1, _Career1, _Sex1, _Weapon1, _Cloth1, _WLight1, 
				  _CLight1, _ShiZhuang1, _SuitId1, _Vip1, _Nick1} = Player1,
				 {_Id2, _Lv2, _Realm2, _Career2, _Sex2, _Weapon2, _Cloth2, _WLight2, 
				  _CLight2, _ShiZhuang2, _SuitId2, _Vip2, _Nick2} = Player2,
				 {_Id3, _Lv3, _Realm3, _Career3, _Sex3, _Weapon3, _Cloth3, _WLight3, 
				  _CLight3, _ShiZhuang3, _SuitId3, _Vip3, _Nick3} = Player3,				  
				[3, _Id1, _Realm1, _Nick1, _Sex1, _Career1, 0,
				    _Id2, _Realm2, _Nick2, _Sex2, _Career2, 0,
				    _Id3, _Realm3, _Nick3, _Sex3, _Career3, 0]
		end,

	lib_chat:send_TV({all},1,2, 
		["jiuchongtian", 1, TowerName, 102, 139, 124, Level, Count,
		Id1, Realm1, Nick1, Sex1, Career1, HeadType1,
		Id2, Realm2, Nick2, Sex2, Career2, HeadType2,
		Id3, Realm3, Nick3, Sex3, Career3, HeadType3
		]).


%% 设置爬塔副本奖励.
set_tower_reward(PlayerId, TowerReward)->
	RewardKey = lists:concat(["tower_reward", PlayerId]),
	put(RewardKey, TowerReward).

%% 获取爬塔副本奖励.
get_tower_reward(PlayerId)->
	RewardKey = lists:concat(["tower_reward",PlayerId]),
	case get(RewardKey) of
		undefined ->
			[];
		TowerReward ->
			[TowerReward]
	end.

%% 清除爬塔副本奖励.
erase_tower_reward(PlayerId)->
    RewardKey = lists:concat(["tower_reward",PlayerId]),
    erase(RewardKey).
