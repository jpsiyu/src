%%%-------------------------------------------------------------------
%%% @Module	: pp_flyer
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 21 Dec 2012
%%% @Description: 
%%%-------------------------------------------------------------------
-module(pp_flyer).
-include("server.hrl").
-include("unite.hrl").
-include("common.hrl").
-include("flyer.hrl").
-include("mount.hrl").
-export([handle/3]).

%% 获取飞行器列表
handle(16200, PS, _) ->
    Flyers = lib_flyer:get_all(PS#player_status.id),
    FlyersInfo = lib_flyer:parse_flyer_list(Flyers),
    CanTrainFlyer = lists:filter(fun(Flyer) -> Flyer#flyer.open == 1 end, Flyers),
    CanTrainNum = lib_flyer:get_can_train_flyer_num(PS#player_status.id, PS#player_status.dailypid, CanTrainFlyer), 
    {ok, BinData} = pt_162:write(16200, [FlyersInfo, CanTrainNum]),
    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
    ok;

%% 获取飞行器详细信息
handle(16201, PS, [Nth]) ->
    Flyer = lib_flyer:get_one(PS#player_status.id, Nth),
    TrainCount = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 13000 + Nth),
    FlyerBin = lib_flyer:parse_flyer_info(Flyer, Nth, TrainCount),
    {ok, BinData} = pt_162:write(16201, [FlyerBin]),
    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
    ok;

%% 元宝解封飞行器
handle(16202, _PS, [_Nth]) ->
    %% Result = lib_flyer:unlock_flyer_by_gold(PS, Nth),
    %% case Result of
    %% 	{ok, 1, PS1} ->
    %% 	    %% 计算属性值
    %% 	    NewPS = lib_flyer:count_attribute_base(PS1),
    %% 	    lib_player:send_attribute_change_notify(NewPS, 1),
    %% 	    {ok, BinData} = pt_162:write(16202, [1, Nth]),
    %% 	    lib_server_send:send_to_sid(NewPS#player_status.sid, BinData),
    %% 	    {ok, battle_hp_mp, NewPS};
    %% 	{fail, Error, PS1} ->
    %% 	    {ok, BinData} = pt_162:write(16202, [Error, Nth]),
    %% 	    lib_server_send:send_to_sid(PS1#player_status.sid, BinData),
    %% 	    {ok, PS1}
    %% end;
    ok;

%% 训练飞行器
handle(16203, PS, [Nth]) ->
    case lib_flyer:check_can_play(PS, Nth) of
	false -> [];
	true ->
	    Result = lib_flyer:train_flyer(PS, Nth),
	    case Result of
		{fail, Error} ->
		    {ok, BinData} = pt_162:write(16203, [Error, Nth]),
		    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		%% 训练成功
		{ok, Flyer, PS1} ->
		    MaxLv = data_flyer:get_max_lv(Nth),
		    %% 自动解封下一只
		    case Flyer#flyer.nth < 9 andalso Flyer#flyer.level =:= MaxLv of
			true ->
			    %% 到达训练顶级
			    case lib_flyer:unlock_flyer_auto(PS1#player_status.id, Flyer#flyer.nth + 1) of
				{0, _} -> {ok, Data} = pt_162:write(16203, [2, Flyer#flyer.nth + 1]),
					  lib_server_send:send_to_sid(PS1#player_status.sid, Data);
				{1, _} ->
				    mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 36, 0, Flyer#flyer.nth + 1),
				    {ok, Data} = pt_162:write(16203, [3, Flyer#flyer.nth + 1]),
				    lib_server_send:send_to_sid(PS1#player_status.sid, Data)
			    end;
			false -> []
		    end,
		    mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 36, 0, Flyer#flyer.nth),
		    NewPS = lib_flyer:count_attribute_train(PS1),
		    lib_player:send_attribute_change_notify(NewPS, 1),
		    {ok, BinData} = pt_162:write(16203, [1, Nth]),
		    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
		    handle(16200, NewPS, 16200),
		    {ok, battle_hp_mp, NewPS}
	    end
    end;

%% 上飞行器
handle(16204, PS, [Nth]) ->
    Mount = PS#player_status.mount,
    M = lib_mount:get_equip_mount(PS#player_status.id, Mount#status_mount.mount_dict),
    MountLv = M#ets_mount.level,
    case PS#player_status.lv >= 60 orelse MountLv >= 3 of
	false ->
	    PS1 = PS#player_status{flyer_attr = PS#player_status.flyer_attr#status_flyer{figure = 0, sky_figure = 0}},
	    {ok, flyer, PS1};
	true ->
	    case lib_flyer:check_span_time(PS#player_status.id) of
		ok ->
			HS = PS#player_status.husong,
			case HS#status_husong.husong == 0 of
			    true ->
				SceneType = lib_scene:get_res_type(PS#player_status.scene),
				IsSceneLegal = data_flyer:is_scene_legal(SceneType, PS#player_status.scene),
				if
				    IsSceneLegal =:= true ->
					case lib_flyer:check_can_fly(PS, Nth) of
					    {fail, Error} ->
						{ok, BinData} = pt_162:write(16204, [Error, Nth]),
						lib_server_send:send_to_sid(PS#player_status.sid, BinData);
					    {ok, PS1} ->
						%% 飞
						PS2 = lib_player:count_player_speed(PS1),
						{ok, BinData} = pt_162:write(16204, [1, Nth]),
						lib_server_send:send_to_sid(PS2#player_status.sid, BinData),
						lib_flyer:send_flyer_fly_notice(PS2, Nth),
						{ok, flyer, PS2}
					end;
				    true -> []
				end;
			    _ ->
				ok
			end;
		_ ->
		    {ok, BinData} = pt_162:write(16204, [6, Nth]),
		    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	    end
    end;

%% 下飞行器
handle(16205, PS, [Nth]) ->
    %%九重天
    Mount = PS#player_status.mount,
    M = lib_mount:get_equip_mount(PS#player_status.id, Mount#status_mount.mount_dict),
    MountLv = M#ets_mount.level,
    case PS#player_status.lv >= 60 orelse MountLv >= 3 of
	false ->
	    PS1 = PS#player_status{flyer_attr = PS#player_status.flyer_attr#status_flyer{figure = 0, sky_figure = 0}},
	    {ok, flyer, PS1};
	true ->
	    case lib_scene:get_res_type(PS#player_status.scene) =:= 6 andalso PS#player_status.scene < 340 of
		true -> [];
		false ->
		    case lib_flyer:get_flying_flyer(PS#player_status.id) of
			[] ->
			    {ok, BinData} = pt_162:write(16205, [2, Nth]),
			    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
			Flyer ->
			    case Flyer#flyer.nth =:= Nth of
				true ->
				    Flyer1 = Flyer#flyer{state = 1},
				    lib_flyer:update_flyer(PS#player_status.id, Flyer1),
				    PS1 = PS#player_status{flyer_attr = PS#player_status.flyer_attr#status_flyer{speed = 0, figure = 0}},
				    PS2 = lib_player:count_player_speed(PS1),
				    {ok, BinData} = pt_162:write(16205, [1, Nth]),
				    lib_server_send:send_to_sid(PS2#player_status.sid, BinData),
				    lib_flyer:send_flyer_fly_notice(PS2, 0),
				    {ok, flyer, PS2};
				false ->
				    {ok, BinData} = pt_162:write(16205, [0, Nth]),
				    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			    end
		    end
	    end
    end;

%% 装备飞行器
handle(16206, PS, [Nth]) ->
    case lib_flyer:get_flying_flyer(PS#player_status.id) of
	[] ->
	    %% 没有飞行中的飞行器
	    case lib_flyer:get_equip_flyer(PS#player_status.id) of
		[] ->
		    %% 没有装备飞行器
		    case lib_flyer:equip_flyer(PS, Nth) of
			{fail, Error} ->
			    {ok, BinData} = pt_162:write(16206, [Error, Nth]),
			    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
			{ok, PS1} ->
			    {ok, BinData} = pt_162:write(16206, [1, Nth]),
			    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
			    {ok, flyer, PS1}
		    end;
		Equip ->
		    case Equip#flyer.nth =:= Nth of
			%% 已装备
			true ->
			    {ok, BinData} = pt_162:write(16206, [2, Nth]),
			    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
			false ->
			    %% 替换装备中的飞行器
			    case lib_flyer:change_equip_flyer(PS, Nth, Equip) of
				{fail, Error} ->
				    {ok, BinData} = pt_162:write(16206, [Error, Nth]),
				    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
				{ok, PS1} ->
				    {ok, BinData} = pt_162:write(16206, [1, Nth]),
				    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
				    {ok, flyer, PS1}
			    end
		    end
	    end;
	Flying ->
	    case Flying#flyer.nth =:= Nth of
		true ->
		    {ok, BinData} = pt_162:write(16206, [2, Nth]),
		    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		false ->
		    {ok, BinData} = pt_162:write(16206, [3, Nth]),
		    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	    end
    end;

%% 卸下飞行器
handle(16207, PS, [Nth]) ->
    case lib_flyer:get_flying_flyer(PS#player_status.id) of
	[] -> 
	    case lib_flyer:get_equip_flyer(PS#player_status.id) of
		[] ->
		    {ok, BinData} = pt_162:write(16207, [2, Nth]),
		    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		Equip ->
		    case Equip#flyer.nth =:= Nth of
			true ->
			    case lib_flyer:dismount_flyer(PS, Nth) of
				{fail, Error} ->
				    {ok, BinData} = pt_162:write(16207, [Error, Nth]),
				    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
				{ok, PS1} ->
				    {ok, BinData} = pt_162:write(16207, [1, Nth]),
				    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
				    {ok, flyer, PS1}
			    end;
			false ->
			    {ok, BinData} = pt_162:write(16207, [3, Nth]),
			    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
		    end
	    end;
	_ ->
	    %% 飞行器飞行中
	    {ok, BinData} = pt_162:write(16207, [4, Nth]),
	    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
    end;

%% 升星
handle(16208, PS, [Nth, GoodsList]) ->
    case lib_flyer:check_can_play(PS, Nth) of
	false -> [];
	true ->
	    Result = lib_flyer:upgrade_star(PS, Nth, GoodsList),
	    case Result of
		{fail, Error} ->
		    {ok, BinData} = pt_162:write(16208, [Error, Nth, []]),
		    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		{ok, Star, PS1} ->
		    PS2 = lib_flyer:unlock_10th_flyer(PS1),
		    NewPS = lib_flyer:count_attribute_star(PS2),
		    lib_player:send_attribute_change_notify(NewPS, 1),
		    {ok, BinData} = pt_162:write(16208, [1, Nth, Star]),
		    lib_server_send:send_to_sid(NewPS#player_status.sid, BinData),
		    {ok, battle_hp_mp, NewPS}
	    end
    end;

%% 回退
handle(16209, PS, [Nth, StarNum, IsTick]) ->
    case lib_flyer:check_can_play(PS, Nth) of
	false -> [];
	true ->
	    Result = lib_flyer:backward_star(PS, Nth, StarNum, IsTick),
	    case Result of
		{fail, Error} ->
		    {ok, BinData} = pt_162:write(16209, [Error, Nth, []]),
		    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		{ok, PS1} ->
		    PS2 = lib_flyer:unlock_10th_flyer(PS1),
		    NewPS = lib_flyer:count_attribute_star(PS2),
		    lib_player:send_attribute_change_notify(NewPS, 1),
		    {ok, battle_hp_mp, NewPS}
	    end
    end;

%% 训练属性预览
handle(16210, PS, [Nth, LookType]) ->
    case LookType of
	0 ->
	    %% 总览
	    case lib_flyer:get_all(PS#player_status.id) of
		[] -> {TotalAttr, CombatPower} = {[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}], 0};
		Flyers ->
		    OneAttr = lists:foldl(fun(Flyer, Acc) ->
						  SingleAttr = lib_flyer:calc_flyer_attr_single_for_preview(Flyer),
						  lists:zipwith(fun({N,X},{N,Y}) -> {N,X+Y} end, SingleAttr, Acc)
					  end, [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}], Flyers),
		    %% BaseAttr = PS#player_status.flyer_attr#status_flyer.base_attr,
		    %% TrainAttr = PS#player_status.flyer_attr#status_flyer.train_attr,
		    %% StarAttr = PS#player_status.flyer_attr#status_flyer.star_attr,
		    NineStarAttr = PS#player_status.flyer_attr#status_flyer.convergence_attr,
		    %% OneAttr = lists:zipwith3(fun({N,X},{N,Y},{N,Z}) -> {N,X+Y+Z} end, BaseAttr, TrainAttr, StarAttr),
		    {TotalAttr, CombatPower} = case lists:zipwith(fun({NN,XX},{NN,YY}) -> {NN,XX+YY} end, OneAttr, NineStarAttr) of
						   [] -> {[{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}], 0};
						   Any ->
						       CP = lib_flyer:count_all_flyer_combat_power(Any),
						       {Any, CP}
					       end
	    end,
	    {ok, BinData} = pt_162:write(16210, [TotalAttr, CombatPower, LookType]),
	    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
	1 ->
	    case lib_flyer:get_all(PS#player_status.id) of 
		[] ->
		    {fail, 0};
		Flyers ->
		    case lists:keyfind(Nth, 3, Flyers) of
			false -> {fail, 0};
			Flyer ->
			    case Flyer#flyer.level >= data_flyer:get_max_lv(Flyer#flyer.nth) of
				true -> {fail, 0};
				false ->
				    Flyer1 = Flyer#flyer{ level=Flyer#flyer.level+1 },
				    Attr = lib_flyer:calc_flyer_attr_single_for_preview(Flyer1),
				    CombatPower = lib_flyer:count_flyer_combat_power_by_flyer(Flyer1),
				    {ok, BinData} = pt_162:write(16210, [Attr, CombatPower, LookType]),
				    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
			    end
		    end
	    end;
	_ -> {fail, 0}
    end;

%% 展示
handle(16211, PS, [PlayerId, Nth]) ->
    case PS#player_status.id =:= PlayerId of
	true ->
	    lib_flyer:show_flyer(PlayerId, PlayerId, Nth);
	false ->
	    lib_player:rpc_cast_by_id(PlayerId, lib_flyer, show_flyer, [PS#player_status.id, PlayerId, Nth])
    end;

handle(16212, PS, [PlayerId, Nth]) ->
    case PS#player_status.id =:= PlayerId of
	true ->
	    lib_flyer:show_flyer_for_rank(PS#player_status.id, PS, Nth);
	false ->
	    case lib_player:get_player_info(PlayerId, pid) of
		false -> lib_flyer:show_flyer_for_rank_from_db(PS#player_status.id, PlayerId, Nth);
		Pid -> gen_server:cast(Pid, {'show_flyer_for_rank', PS#player_status.id, Nth})
	    end
    end;


handle(16213, PS, _) ->
    Flyers = lib_flyer:get_all(PS#player_status.id),
    TotalScore = lib_flyer:calc_nine_star_convergence_total_score(Flyers),
    Num = data_flyer:get_nine_star_convergence_num(TotalScore),
    QualityList = lists:map(fun(X) -> {X#flyer.nth, data_flyer:get_flyer_quality(X#flyer.nth, X#flyer.stars)} end, Flyers),
    {ok, BinData} = pt_162:write(16213, [TotalScore, Num, QualityList]),
    lib_server_send:send_to_sid(PS#player_status.sid, BinData);

%% 错误处理
handle(_Cmd, _Status, _Data) ->
    {error, "pp_flyer no match"}.

