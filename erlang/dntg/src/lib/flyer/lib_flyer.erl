%%%-------------------------------------------------------------------
%%% @Module	: lib_flyer
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 18 Dec 2012
%%% @Description: 飞行器
%%%-------------------------------------------------------------------
-module(lib_flyer).
-include("flyer.hrl").
-include("server.hrl").
-compile(export_all).

make_flyer_record([Id, Nth, PlayerId, Open, Level, Stars, State, Speed, Name, CombatPower, BackCount, Quality]) ->
    #flyer{
	    id = Id,
	    nth = Nth,
	    player_id = PlayerId,
	    open = Open,
	    level = Level,
	    stars = Stars,
	    state = State,
	    speed = Speed,
	    name = Name,
	    combat_power = CombatPower,
	    back_count = BackCount,
	    quality = Quality
	  }.
make_flyer_star_record([PlayerId, FlyerId, StarAttr, StarValue, TS, StarNum]) ->
    #flyer_star{
		 flyer_id = FlyerId,
		 star_attr = lib_goods_util:to_term(StarAttr),
		 star_value = StarValue,
		 player_id = PlayerId,
		 ts = TS,
		 star_num = lib_goods_util:to_term(StarNum)
	       }.
activate_flyer_by_mount(Pid, PlayerId) ->
    gen_server:call(Pid, {'apply_call', lib_flyer, unlock_flyer_by_mount, [Pid, PlayerId]}).

role_login(Pid, PlayerId) ->
    gen_server:call(Pid, {'apply_call', lib_flyer, init_flyer, [PlayerId]}).

init_flyer(PlayerId) ->
    _Stars =
	case db:get_all(io_lib:format(<<"select * from flyer_stars where player_id=~p">>, [PlayerId])) of
	    [] -> [];
	    SAll ->
		lists:map(fun([_PlayerId, FlyerId, StarAttr, StarValue, TS, StarSN]) ->
				  make_flyer_star_record([PlayerId, FlyerId, StarAttr, StarValue, TS, StarSN])
			  end, SAll)
	end,
    case db:get_all(io_lib:format(<<"select * from flyer where player_id=~p">>, [PlayerId])) of
	[] -> [];
	FAll ->
	    Key = lists:concat([lib_flyer, PlayerId]),
	    Flyers = lists:map(fun([Id, Nth, _PlayerId, Open, Level, State, Speed, _Name, CombatPower, BackCount, Quality]) ->
				       Stars = lists:filter(fun(Star) -> Star#flyer_star.flyer_id =:= Id end, _Stars),
				       Name = data_flyer:get_name(Nth),
				       case Quality =:= 0 of
					   true -> update_flyer_quality_to_db(Id, Nth, Stars);
					   false -> []
				       end,
				       make_flyer_record([Id, Nth, PlayerId, Open, Level, Stars, State, Speed, Name, CombatPower, BackCount, Quality])
			       end, FAll),
	    put(Key, Flyers),
	    Flyers
    end.

update_flyer_quality_to_db(Id, Nth, Stars) ->
    Quality = data_flyer:get_flyer_quality(Nth, Stars),
    db:execute(io_lib:format(<<"update flyer set quality=~p where id=~p">>, [Quality, Id])).

check_can_fly(PS, Nth) ->
    case get_flying_flyer(PS#player_status.id) of
	[] ->
	    case get_equip_flyer(PS#player_status.id) of
		[] -> {fail, 2};
		Flyer ->
		    case Flyer#flyer.nth =:= Nth of
			true ->
			    Flyer1 = Flyer#flyer{state = 2},
			    update_flyer(PS#player_status.id, Flyer1),
			    FlyerFigure = pack_flyer_figure(PS#player_status.id, Nth),
			    PS1 = PS#player_status{flyer_attr = PS#player_status.flyer_attr#status_flyer{speed = Flyer#flyer.speed, figure = FlyerFigure}},
			    {ok, PS1};
			false -> {fail, 3}
		    end
	    end;
	Flying ->
	    case Flying#flyer.nth =:= Nth of
		true -> {fail, 4};
		false -> {fail, 5}
	    end
    end.
%% 检查解封状态
check_unlock_condition(PS, Nth) ->
    NeedGold = data_flyer:get_unlock_gold(Nth),
    case PS#player_status.gold >= NeedGold of
	true ->
	    case get_one(PS#player_status.id, Nth) of
		[] ->
		    case Nth =:= 1 of
			true ->
			    {ok, NeedGold};
			false ->
			    case get_one(PS#player_status.id, Nth-1) of
				[] ->
				    {fail, 2};
				Flyer ->
				    case Flyer#flyer.open =:= 1 of
					true ->
					    {ok, NeedGold};
					false ->
					    {fail, 3}
				    end
			    end
		    end;
		_ -> {fail,4}
	    end;
	false ->
	    {fail, 5}
    end.
%% 元宝解封
unlock_flyer_by_gold(PS, Nth) ->
    case check_unlock_condition(PS, Nth) of
	{ok, NeedGold} ->
	    PS1 = lib_goods_util:cost_money(PS, NeedGold, gold),
	    Speed = data_flyer:get_speed(Nth),
	    Name = data_flyer:get_name(Nth),
	    CombatPower = count_unlock_combat_power(Nth),
	    %% 插入数据库
	    db:execute(io_lib:format(<<"insert into flyer(nth, player_id, open, level, state, speed, name, combat_power, quality) values(~p, ~p, ~p, ~p, ~p, ~p, '~s', ~p, ~p)">>, [Nth, PS#player_status.id, 1, 0, 0, Speed, util:term_to_string(Name), CombatPower, 1])),
	    case db:get_one(io_lib:format(<<"select id from flyer where player_id=~p and nth=~p">>, [PS#player_status.id , Nth])) of
		false -> {fail, 0, PS1};
		Id ->
		    Flyer = #flyer{
		      id = Id,
		      nth = Nth,
		      player_id = PS#player_status.id,
		      open = 1,
		      level = 0,
		      state = 0,
		      speed = Speed,
		      name = Name,
		      combat_power = CombatPower
		     },
		    insert_flyer(PS#player_status.id, Flyer),
		    {ok, 1, PS1}
	    end;
	{fail, Error} ->
	    %% 解封失败
	    {fail, Error, PS}
    end.
%% 自动解封
unlock_flyer_auto(PlayerId, Nth) ->
    case get_one(PlayerId, Nth) =:= [] of
	true ->
	    %% 插入数据库
	    Speed = data_flyer:get_speed(Nth),
	    Name = data_flyer:get_name(Nth),
	    CombatPower = count_unlock_combat_power(Nth),
	    case Nth =:= 1 of
		true -> State = 1;
		false -> State = 0
	    end,
	    db:execute(io_lib:format(<<"insert into flyer(nth, player_id, open, level, state, speed, name, combat_power, quality) values(~p, ~p, ~p, ~p, ~p, ~p, '~s', ~p, ~p)">>, [Nth, PlayerId, 1, 0, State, Speed, util:term_to_string(Name), CombatPower, 1])),
	    case db:get_one(io_lib:format(<<"select id from flyer where player_id=~p and nth=~p">>, [PlayerId , Nth])) of
		false -> {0, []};
		Id ->
		    Flyer = #flyer{
		      id = Id,
		      nth = Nth,
		      player_id = PlayerId,
		      open = 1,
		      level = 0,
		      state = State,
		      speed = Speed,
		      name = Name,
		      combat_power = CombatPower
		     },
		    insert_flyer(PlayerId, Flyer),
		    {1, [Flyer]}
	    end;
	One -> {1, [One]}
    end.

unlock_flyer_auto2(PlayerId, Nth) ->
    case get_one(PlayerId, Nth) =:= [] of
	true ->
	    %% 插入数据库
	    Speed = data_flyer:get_speed(Nth),
	    Name = data_flyer:get_name(Nth),
	    CombatPower = count_unlock_combat_power(Nth),
	    case Nth =:= 1 of
		true -> State = 1;
		false -> State = 0
	    end,
	    db:execute(io_lib:format(<<"insert into flyer(nth, player_id, open, level, state, speed, name, combat_power, quality) values(~p, ~p, ~p, ~p, ~p, ~p, '~s', ~p, ~p)">>, [Nth, PlayerId, 1, 0, State, Speed, util:term_to_string(Name), CombatPower, 1])),
	    case db:get_one(io_lib:format(<<"select id from flyer where player_id=~p and nth=~p">>, [PlayerId , Nth])) of
		false -> {0, []};
		Id ->
		    Flyer = #flyer{
		      id = Id,
		      nth = Nth,
		      player_id = PlayerId,
		      open = 1,
		      level = 0,
		      state = State,
		      speed = Speed,
		      name = Name,
		      combat_power = CombatPower
		     },
		    insert_flyer(PlayerId, Flyer),
		    {1, [Flyer]}
	    end;
	One -> {2, [One]}
    end.

unlock_10th_flyer(PS1) ->
    Flyers = get_all(PS1#player_status.id),
    case length(Flyers) < 9 of
	true -> PS1;
	false ->
	    case calc_nine_star_convergence_total_score(Flyers) >= 108 of
		true ->
		    case unlock_flyer_auto2(PS1#player_status.id, 10) of
			{0, _} ->
			    {ok, Data} = pt_162:write(16203, [2, 10]),
			    lib_server_send:send_to_sid(PS1#player_status.sid, Data),
			    PS1;
			{1, _} ->
			    lib_chat:send_TV({all}, 0, 2, ["flyopen", PS1#player_status.id, PS1#player_status.realm, PS1#player_status.nickname, PS1#player_status.sex, PS1#player_status.career, PS1#player_status.image, data_flyer:get_name(10), 10]),
			    {ok, Data} = pt_162:write(16203, [3, 10]),
			    lib_server_send:send_to_sid(PS1#player_status.sid, Data),
			    count_attribute_base(PS1);
			_ -> PS1
		    end;
		false -> PS1
	    end
    end.

%% 坐骑升阶自动解封
unlock_flyer_by_mount(Pid, PlayerId) ->
    case self() =:= Pid of
	true ->
	    unlock_flyer_by_mount_sub(PlayerId);
	false ->
	    gen_server:cast(Pid, {'apply_cast', lib_flyer, unlock_flyer_by_mount_sub, [PlayerId]})
    end.

unlock_flyer_by_mount_sub(PlayerId) ->
    case get_all(PlayerId) of
	[] -> unlock_flyer_auto(PlayerId, 1), get_all(PlayerId);
	All -> All
    end.

get_can_train_flyer_num(PlayerId, DailyPid, Flyers) ->
    lists:foldl(fun(Flyer, Acc) ->
			Can = case Flyer#flyer.level >= data_flyer:get_max_lv(Flyer#flyer.nth) of
				  true -> 0;
				  false ->
				      case mod_daily:get_count(DailyPid, PlayerId, 13000 + Flyer#flyer.nth) >= 1 of
					  true -> 0;
					  false -> 1
				      end
			      end,
			Can + Acc
		end, 0, Flyers).

%% 训练飞行器
train_flyer(PS, Nth) ->
    MaxLv = data_flyer:get_max_lv(Nth),
    case get_one(PS#player_status.id, Nth) of 
	[] ->
	    {fail, 0};
	Flyer ->
	    case Flyer#flyer.level >= MaxLv of
		true -> {fail, 6};
		false ->
		    case mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 13000 + Nth) >= 1 of
			true -> {fail, 5};
			false ->
			    CoinCost = data_flyer:get_train_cost(Nth),
			    case lib_goods_util:is_enough_money(PS, CoinCost, coin) of
				true ->
				    mod_daily:increment(PS#player_status.dailypid, PS#player_status.id, 13000 + Nth),
				    PS1 = lib_goods_util:cost_money(PS, CoinCost, coin),
				    Flyer1 = Flyer#flyer{ level=Flyer#flyer.level+1 },
				    CombatPower = count_flyer_combat_power_by_flyer(Flyer1),
				    db:execute(io_lib:format(<<"update flyer set level=~p, combat_power=~p, name='~s' where id=~p">>, [Flyer1#flyer.level, CombatPower, util:term_to_string(Flyer1#flyer.name), Flyer1#flyer.id])),
				    Flyer2 = Flyer1#flyer{ combat_power = CombatPower },
				    update_flyer(PS1#player_status.id, Flyer2),
				    log:log_consume(flyer_train, coin, PS, PS1, "flyer_train"),
				    log_flyer_train(PS1#player_status.id, Nth, Flyer#flyer.level, Flyer1#flyer.level),
				    {ok, Flyer2, PS1};
				false ->
				    {fail, 4}
			    end
		    end
	    end
    end.
%% 飞行器升星
%% @return: {fail, Error} | {ok, #flyer_star{}, #player_status{}}
upgrade_star(PS, Nth, GoodsList) ->
    case get_one(PS#player_status.id, Nth) of
	[] -> {fail, 0};
	Flyer ->
	    StarNum = length(Flyer#flyer.stars),
	    case StarNum >= data_flyer:get_flyer_max_star(Nth) of
		true -> {fail, 6};
		false ->
		    case data_flyer:get_upgrade_cost(Nth, StarNum + 1) of
			false -> {fail, 2};
			{GoodsNeed, CoinCost} ->
			    OwnGoodsNum = mod_other_call:get_goods_num(PS, 691101, 0),
			    IsEnoughMoney = lib_goods_util:is_enough_money(PS, CoinCost, coin),
			    if
				OwnGoodsNum < GoodsNeed ->
				    {fail, 3};
				IsEnoughMoney =:= false ->
				    {fail, 4};
				true ->
				    case gen_server:call(PS#player_status.goods#status_goods.goods_pid, {'delete_list', GoodsList}) of
					1 ->
					    PS1 = lib_goods_util:cost_money(PS, CoinCost, coin),
					    lib_player:refresh_client(PS1#player_status.id, 2),
					    TS = util:longunixtime(),
					    StarSN = integer_to_list(TS),
					    AttrTypeList = get_star_attr_type(),
					    StarType = get_star_type(Flyer#flyer.back_count, Flyer#flyer.nth, Flyer#flyer.stars),
					    DistributeList = distribute_star(StarType, AttrTypeList),
					    StarAttr = case lists:keyfind(Nth, 1, data_flyer:get_attr_val_ratio()) of
							   false -> [];
							   {_, L} ->
							       lists:map(fun({Type, Val}) ->
										 {_, Param} = lists:keyfind(Type, 1, L),
										 {Type, round(Val / Param)}
									 end, DistributeList)
						       end,
					    db:execute(io_lib:format(<<"insert into flyer_stars(player_id, flyer_id, star_attr, star_value, ts, star_num) values(~p, ~p, '~s', ~p, ~p, '~s')">>, [PS1#player_status.id, Flyer#flyer.id, util:term_to_string(StarAttr), StarType, TS, util:term_to_string(StarSN)])),
					    FlyerStar = #flyer_star{
					      flyer_id = Flyer#flyer.id,
					      star_attr = StarAttr,
					      star_value = StarType,
					      player_id = PS1#player_status.id,
					      ts = TS,
					      star_num = StarSN
					     },
					    NewStars = [FlyerStar | Flyer#flyer.stars],
					    Quality = data_flyer:get_flyer_quality(Flyer#flyer.nth, NewStars),
					    Flyer1 = Flyer#flyer{stars = NewStars, quality = Quality},
					    CombatPower = count_flyer_combat_power_by_flyer(Flyer1),
					    db:execute(io_lib:format(<<"update flyer set combat_power=~p, quality=~p where id=~p">>, [CombatPower, Flyer1#flyer.quality, Flyer1#flyer.id])),
					    Flyer2 = Flyer1#flyer{ combat_power = CombatPower },
					    update_flyer(PS1#player_status.id, Flyer2),
					    AllStarLv = data_flyer:get_all_star_addition(Flyer2#flyer.nth, Flyer2#flyer.stars),
					    case AllStarLv of
						0.1 -> lib_chat:send_TV({all}, 0, 2, ["flyupg", PS1#player_status.id, PS1#player_status.realm, PS1#player_status.nickname, PS1#player_status.sex, PS1#player_status.career, PS1#player_status.image, Flyer2#flyer.name, Flyer2#flyer.nth, 1]),
						       mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 4); %仙器;
						0.2 -> lib_chat:send_TV({all}, 0, 2, ["flyupg", PS1#player_status.id, PS1#player_status.realm, PS1#player_status.nickname, PS1#player_status.sex, PS1#player_status.career, PS1#player_status.image, Flyer2#flyer.name, Flyer2#flyer.nth, 2]),
						       mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 5); %神器;;
						0.025 -> mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 2); %法器
						0.05 -> mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 3); %灵器
						_ -> []
					    end,
					    if
						(Nth >= 4 andalso Nth =< 8) andalso AllStarLv >= 0.1->
						    %% 全星级紫月解封
						    case lib_flyer:unlock_flyer_auto2(PS1#player_status.id, Flyer2#flyer.nth + 1) of
							{0, _} ->
							    {ok, Data} = pt_162:write(16203, [2, Flyer2#flyer.nth + 1]),
							    lib_server_send:send_to_sid(PS1#player_status.sid, Data),
							    PS2 = PS1;
							{1, _} ->
							    lib_chat:send_TV({all}, 0, 2, ["flyopen", PS1#player_status.id, PS1#player_status.realm, PS1#player_status.nickname, PS1#player_status.sex, PS1#player_status.career, PS1#player_status.image, data_flyer:get_name(Flyer2#flyer.nth+1), Flyer2#flyer.nth + 1]),
							    {ok, Data} = pt_162:write(16203, [3, Flyer2#flyer.nth + 1]),
							    lib_server_send:send_to_sid(PS1#player_status.sid, Data),
							    PS2 = count_attribute_base(PS1);
							_ -> PS2 = PS1
						    end;
						Nth < 4 andalso AllStarLv >= 0.05 ->
						    %% 全星级蓝月解封
						    case lib_flyer:unlock_flyer_auto2(PS1#player_status.id, Flyer2#flyer.nth + 1) of
							{0, _} ->
							    {ok, Data} = pt_162:write(16203, [2, Flyer2#flyer.nth + 1]),
							    lib_server_send:send_to_sid(PS1#player_status.sid, Data),
							    PS2 = PS1;
							{1, _} ->
							    lib_chat:send_TV({all}, 0, 2, ["flyopen", PS1#player_status.id, PS1#player_status.realm, PS1#player_status.nickname, PS1#player_status.sex, PS1#player_status.career, PS1#player_status.image, data_flyer:get_name(Flyer2#flyer.nth+1), Flyer2#flyer.nth + 1]),
							    {ok, Data} = pt_162:write(16203, [3, Flyer2#flyer.nth + 1]),
							    lib_server_send:send_to_sid(PS1#player_status.sid, Data),
							    PS2 = count_attribute_base(PS1);
							_ -> PS2 = PS1
						    end;
						true -> PS2 = PS1
					    end,
					    log:log_consume(flyer_upgrade_star, coin, PS, PS2, "flyer_upgrade_star"),
					    log:log_goods_use(PS1#player_status.id, 691101, GoodsNeed),
					    log_flyer_star(PS1#player_status.id, Flyer2#flyer.nth, FlyerStar, 1),
					    {ok, FlyerStar, PS2};
					_ ->
					    {fail, 5}
				    end
			    end
		    end
	    end
    end.

%% 飞行器升星,回退专用
%% @return: {#flyer_star{}, #player_status{}}
upgrade_star_for_backward(PS1, Flyer, Star, IsTick) ->
    Flyer1 = Flyer#flyer{back_count = Flyer#flyer.back_count + 1},
    StarType = get_star_type(Flyer1#flyer.back_count, Flyer1#flyer.nth, Flyer1#flyer.stars),
    MinStarValue = Star#flyer_star.star_value,
    case IsTick =:= 1 of
	false ->
	    upgrade_star_for_backward_sub(PS1, Flyer1, Star, StarType);
	true ->
	    case StarType < MinStarValue of
		true ->
		    %% 新产生的星星比原来还差
		    AttrTypeList = get_star_attr_type(),
		    DistributeList = distribute_star(StarType, AttrTypeList),
		    StarAttr = case lists:keyfind(Flyer1#flyer.nth, 1, data_flyer:get_attr_val_ratio()) of
				   false -> [];
				   {_, L} ->
				       lists:map(fun({Type, Val}) ->
							 {_, Param} = lists:keyfind(Type, 1, L),
							 {Type, round(Val / Param)}
						 end, DistributeList)
			       end,
		    TS = util:longunixtime(),
		    StarSN = integer_to_list(TS),
		    FlyerStar = #flyer_star{
		      flyer_id = Flyer1#flyer.id,
		      star_attr = StarAttr,
		      star_value = StarType,
		      player_id = PS1#player_status.id,
		      ts = TS,
		      star_num = StarSN
		     },
		    {ok, BinData} = pt_162:write(16209, [7, Flyer#flyer.nth, FlyerStar]),
		    lib_server_send:send_to_sid(PS1#player_status.sid, BinData),
		    db:execute(io_lib:format(<<"update flyer set back_count=~p where id=~p">>, [Flyer1#flyer.back_count, Flyer1#flyer.id])),
		    update_flyer(PS1#player_status.id, Flyer1),
		    case data_flyer:get_flyer_quality(Flyer1#flyer.nth, Flyer1#flyer.stars) of
			2 -> mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 2); %法器
			3 -> mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 3); %灵器
			4 -> mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 4); %仙器;
			5 -> mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 5); %神器;;
			_ -> []
		    end,
		    {Star, PS1};
		false ->
		    upgrade_star_for_backward_sub(PS1, Flyer1, Star, StarType)
	    end
    end.
%% @return: {#flyer_star{}, #player_status{}}
upgrade_star_for_backward_sub(PS1, Flyer1, Star, StarType) ->
    PlayerId = PS1#player_status.id,
    TS = util:longunixtime(),
    StarSN = integer_to_list(TS),
    db:execute(io_lib:format(<<"delete from flyer_stars where flyer_id=~p and ts=~p">>,[Star#flyer_star.flyer_id, Star#flyer_star.ts])),
    Flyer2 = Flyer1#flyer{
	       stars = lists:keydelete(Star#flyer_star.ts, 6, Flyer1#flyer.stars)
	      },
    AttrTypeList = get_star_attr_type(),
    DistributeList = distribute_star(StarType, AttrTypeList),
    StarAttr = case lists:keyfind(Flyer2#flyer.nth, 1, data_flyer:get_attr_val_ratio()) of
		   false -> [];
		   {_, L} ->
		       lists:map(fun({Type, Val}) ->
					 {_, Param} = lists:keyfind(Type, 1, L),
					 {Type, round(Val / Param)}
				 end, DistributeList)
	       end,
    db:execute(io_lib:format(<<"insert into flyer_stars(player_id, flyer_id, star_attr, star_value, ts, star_num) values(~p, ~p, '~s', ~p, ~p, '~s')">>, [PlayerId, Flyer2#flyer.id, util:term_to_string(StarAttr), StarType, TS, util:term_to_string(StarSN)])),
    FlyerStar = #flyer_star{
      flyer_id = Flyer2#flyer.id,
      star_attr = StarAttr,
      star_value = StarType,
      player_id = PlayerId,
      ts = TS,
      star_num = StarSN
     },
    NewStars = [FlyerStar | Flyer2#flyer.stars],
    Quality = data_flyer:get_flyer_quality(Flyer2#flyer.nth, NewStars),
    Flyer3 = Flyer2#flyer{stars = NewStars, quality = Quality},
    CombatPower = count_flyer_combat_power_by_flyer(Flyer3),
    db:execute(io_lib:format(<<"update flyer set combat_power=~p, back_count=~p, quality=~p where id=~p">>, [CombatPower, Flyer3#flyer.back_count, Flyer3#flyer.quality, Flyer3#flyer.id])),
    Flyer4 = Flyer3#flyer{ combat_power = CombatPower },
    update_flyer(PlayerId, Flyer4),
    Nth = Flyer4#flyer.nth,
    AllStarLv = data_flyer:get_all_star_addition(Flyer4#flyer.nth, Flyer4#flyer.stars),
    Key = lists:concat(["flyersendtv", PS1#player_status.id]),
    case get(Key) of
	undefined ->
	    case AllStarLv of
		0.1 ->
		    lib_chat:send_TV({all}, 0, 2, ["flyupg", PS1#player_status.id, PS1#player_status.realm, PS1#player_status.nickname, PS1#player_status.sex, PS1#player_status.career, PS1#player_status.image, Flyer4#flyer.name, Flyer4#flyer.nth, 1]),
		    put(Key, 0.1),
		    mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 4); %仙器;
		0.2 ->
		    lib_chat:send_TV({all}, 0, 2, ["flyupg", PS1#player_status.id, PS1#player_status.realm, PS1#player_status.nickname, PS1#player_status.sex, PS1#player_status.career, PS1#player_status.image, Flyer4#flyer.name, Flyer4#flyer.nth, 2]),
		    put(Key, 0.2),
		    mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 5); %神器;
		0.025 -> mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 2); %法器
		0.05 -> mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 3); %灵器
		_ -> []
	    end;
	Any ->
	    case AllStarLv > Any of
		true ->
		    put(Key, AllStarLv),
		    lib_chat:send_TV({all}, 0, 2, ["flyupg", PS1#player_status.id, PS1#player_status.realm, PS1#player_status.nickname, PS1#player_status.sex, PS1#player_status.career, PS1#player_status.image, Flyer4#flyer.name, Flyer4#flyer.nth, 2]),
		    mod_achieve:trigger_role(PS1#player_status.achieve, PS1#player_status.id, 37, 0, 5); %神器;
		false -> []
	    end
    end,
    if
	(Nth >= 4 andalso Nth =< 8) andalso AllStarLv >= 0.1->
	    %% 全星级紫月解封
	    case lib_flyer:unlock_flyer_auto2(PlayerId, Flyer4#flyer.nth + 1) of
		{0, _} ->
		    {ok, Data} = pt_162:write(16203, [2, Flyer4#flyer.nth + 1]),
		    lib_server_send:send_to_uid(PlayerId, Data),
		    PS2 = PS1;
		{1, _} ->
		    lib_chat:send_TV({all}, 0, 2, ["flyopen", PS1#player_status.id, PS1#player_status.realm, PS1#player_status.nickname, PS1#player_status.sex, PS1#player_status.career, PS1#player_status.image, data_flyer:get_name(Flyer4#flyer.nth+1), Flyer4#flyer.nth + 1]),
		    {ok, Data} = pt_162:write(16203, [3, Flyer4#flyer.nth + 1]),
		    lib_server_send:send_to_uid(PlayerId, Data),
		    PS2 = count_attribute_base(PS1);
		_ -> PS2 = PS1
	    end;
	Nth < 4 andalso AllStarLv >= 0.05 ->
	    %% 全星级蓝月解封
	    case lib_flyer:unlock_flyer_auto2(PlayerId, Flyer4#flyer.nth + 1) of
		{0, _} ->
		    {ok, Data} = pt_162:write(16203, [2, Flyer4#flyer.nth + 1]),
		    lib_server_send:send_to_uid(PlayerId, Data),
		    PS2 = PS1;
		{1, _} ->
		    lib_chat:send_TV({all}, 0, 2, ["flyopen", PS1#player_status.id, PS1#player_status.realm, PS1#player_status.nickname, PS1#player_status.sex, PS1#player_status.career, PS1#player_status.image, data_flyer:get_name(Flyer4#flyer.nth+1), Flyer4#flyer.nth + 1]),
		    {ok, Data} = pt_162:write(16203, [3, Flyer4#flyer.nth + 1]),
		    lib_server_send:send_to_uid(PlayerId, Data),
		    PS2 = count_attribute_base(PS1);
		_ -> PS2 = PS1
	    end;
	true -> PS2 = PS1
    end,
    log_flyer_star(PlayerId, Flyer4#flyer.nth, Star, 2),
    log_flyer_star(PlayerId, Flyer4#flyer.nth, FlyerStar, 1),
    {FlyerStar, PS2}.
%% 飞行器回退
backward_star(PS, Nth, ChosenStar, IsTick) ->
    case get_one(PS#player_status.id, Nth) of
	[] -> {fail, 0};
	Flyer ->
	    StarNum = length(Flyer#flyer.stars),
	    case StarNum >= data_flyer:get_flyer_max_star(Flyer#flyer.nth) of
		false -> {fail, 5};
		true ->
		    case data_flyer:get_backward_cost(Nth, StarNum) of 
			false -> {fail, 2};
			BackCoinCost ->
			    case data_flyer:get_upgrade_cost(Nth, StarNum) of
				false -> {fail, 2};
				{GoodsNeed, UpCoinCost} ->
				    OwnGoodsNum = mod_other_call:get_goods_num(PS, 691101, 0),
				    TotalCost = BackCoinCost + UpCoinCost,
				    IsEnoughMoney = lib_goods_util:is_enough_money(PS, TotalCost, coin),
				    if
					OwnGoodsNum < GoodsNeed ->
					    {fail, 6};
					IsEnoughMoney =:= false ->
					    {fail, 3};
					true ->
					    case gen_server:call(PS#player_status.goods#status_goods.goods_pid, {'delete_more', 691101, GoodsNeed}) of
						1 ->
						    PS1 = lib_goods_util:cost_money(PS, TotalCost, coin),
						    lib_player:refresh_client(PS1#player_status.id, 2),
						    case choose_star(Flyer#flyer.stars, ChosenStar) of
							Star when is_record(Star, flyer_star) ->
							    {FlyerStar, PS2} = upgrade_star_for_backward(PS1, Flyer, Star, IsTick),
							    log:log_consume(flyer_backward, coin, PS, PS2, "flyer_backward"),
							    log:log_goods_use(PS2#player_status.id, 691101, GoodsNeed),
							    case Star#flyer_star.ts =/= FlyerStar#flyer_star.ts of
								true ->
								    {ok, BinData} = pt_162:write(16209, [1, Nth, FlyerStar]),
								    lib_server_send:send_to_sid(PS2#player_status.sid, BinData);
								false -> []
							    end,
							    {ok, PS2};
							_ ->
							    {fail, 0}
						    end;
						_ -> {fail, 0}
					    end
				    end
			    end
		    end
	    end
    end.
	    
choose_star(Stars, _ChosenStar) ->
    %% case ChosenStar =/= "" of
    %% 	true -> 
    %% 	    case lists:keyfind(ChosenStar, 7, Stars) of
    %% 		false -> {fail, 0};
    %% 		Star -> Star
    %% 	    end;
    %% 	false ->
    %% 	    get_flyer_min_value_star(Stars)
    %% end.
    get_flyer_min_value_star(Stars).

%% 获得飞行器最差的一颗星
%% @return: #flyer_star{}
get_flyer_min_value_star(Stars) ->
    _Star = util:min_ex(Stars, 4),
    SameValueStar = lists:filter(fun(X) -> _Star#flyer_star.star_value =:= X#flyer_star.star_value end, Stars),
    util:max_ex(SameValueStar, 6).
			 

%% 获得3种属性
%% @return: [Type1,Type2,Type3]
get_star_attr_type() ->
    RatioList = data_flyer:get_attr_type_ratio(),
    Rand = util:rand(1,3),
    lists:map(fun(_) ->
		      {Type, _} = get_rand_from_ratio_list(2, RatioList),
		      Type
	      end, lists:seq(1,Rand)).

%% 产生星星概率调整
adjust_star_type_ratio(OriginRatioList, Stars) ->
    StarQuality = lists:map(fun(Star) -> data_flyer:get_one_star_quality(Star) end, Stars),
    SunNum = length(lists:filter(fun(X) -> X >= 5 end, StarQuality)),
    StarNum = length(Stars),
    if
	SunNum =< StarNum div 3 ->
	    lists:map(fun({Type, Ratio}) ->
			      case Type >= 95 andalso Type =< 100 of
				  false -> {Type,Ratio};
				  true -> {Type,Ratio * 2}
			      end
		      end, OriginRatioList);		     
	SunNum =< (StarNum * 2) div 3 ->
	    OriginRatioList;
	true ->
	    lists:map(fun({Type, Ratio}) ->
			      case Type >= 95 andalso Type =< 100 of
				  false -> {Type,Ratio};
				  true -> {Type,round(Ratio * 0.8)}
			      end
		      end, OriginRatioList)
    end.
					 
%% 获得星星的类型
get_star_type(BackCount, Nth, Stars) ->
    OriginRatioList = data_flyer:get_star_type_ratio(),
    AdjustRatioList = adjust_star_type_ratio(OriginRatioList, Stars),
    AdjustLen = length(AdjustRatioList),
    %% 回退25次，下限值加1
    Div = data_flyer:get_backcount(Nth),
    LowerLimit = BackCount div Div + 1,
    Start = case LowerLimit > AdjustLen of
		true -> AdjustLen;
		false -> LowerLimit
	    end,
    RatioList = lists:sublist(AdjustRatioList, Start, AdjustLen),
    {Type, _} = get_rand_from_ratio_list(2, RatioList),
    Type.
%% 分配数值到每颗星上
%% @return: [{Type, StarDistribute},...]
distribute_star(Star, AttrList) ->
    Len = length(AttrList),
    case Len of
	1 ->
	    RandList = [Star];
	2 ->
	    Rand1 = util:rand(3, Star-3),
	    Rand2 = Star-Rand1,
	    RandList = [Rand1, Rand2];
	3 ->
	    Rand1 = util:rand(3, Star-6),
	    Rand2 = util:rand(3, Star-Rand1-3),
	    Rand3 = Star - Rand1 -Rand2,
	    RandList = [Rand1, Rand2, Rand3]
    end,
    lists:zip(AttrList, RandList).
%% -----------------------------进程字典操作------------------------begin
insert_flyer(PlayerId, Flyer) ->
    Key = lists:concat([lib_flyer, PlayerId]),
    AllFlyer = get_all(PlayerId),
    Flyers = [Flyer | AllFlyer],
    SortFlyers = lists:keysort(3, Flyers),
    put(Key, SortFlyers).

update_flyer(PlayerId, Flyer) ->
    Key = lists:concat([lib_flyer, PlayerId]),
    AllFlyer = get_all(PlayerId),
    NewAllFlyer = lists:keyreplace(Flyer#flyer.id, 2, AllFlyer, Flyer),
    put(Key, NewAllFlyer).

get_all(PlayerId) ->
    Key = lists:concat([lib_flyer, PlayerId]),
    case get(Key) of
	undefined -> [];
	Any -> Any
    end.

get_one(PlayerId, Nth) ->
    AllFlyer = get_all(PlayerId),
    case lists:keyfind(Nth, 3, AllFlyer) of
	false -> [];
	Any -> Any
    end.

get_one_by_flyer_id(PlayerId, FlyerId) ->
    AllFlyer = get_all(PlayerId),
    case lists:keyfind(FlyerId, 2, AllFlyer) of
	false -> [];
	Any -> Any
    end.
erase_all(PlayerId) ->
    Key = lists:concat([lib_flyer, PlayerId]),
    erase(Key).
%% -----------------------------进程字典操作------------------------end

%% 获得装备了的飞行器
get_equip_flyer(PlayerId) ->
    Flyers = get_all(PlayerId),
    case lists:filter(fun(X) -> X#flyer.state =:= 1 end, Flyers) of
	[] -> [];
	[H|_] -> H
    end.
%% 获得正在飞行的飞行器
get_flying_flyer(PlayerId) ->
    Flyers = get_all(PlayerId),
    case lists:filter(fun(X) -> X#flyer.state =:= 2 end, Flyers) of
	[] -> [];
	[H|_] -> H
    end.
get_flying_flyer_speed(Flyers) ->
    case lists:filter(fun(X) -> X#flyer.state =:= 2 end, Flyers) of
	[] -> 0;
	[H|_] -> H#flyer.speed
    end.
get_equip_or_flying_flyer(PlayerId) ->
    Flyers = get_all(PlayerId),
    case lists:filter(fun(X) -> X#flyer.state =:=1 orelse X#flyer.state =:= 2 end, Flyers) of
	[] -> [];
	[H|_] -> H
    end.
%% 获得装备了的飞行器的速度
get_equip_flyer_speed(PlayerId) ->
    case get_equip_or_flying_flyer(PlayerId) of
	[] -> 0;
	Flyer -> Flyer#flyer.speed
    end.

%% 装备飞行器
equip_flyer(PS, Nth) ->
    PlayerId = PS#player_status.id,
    case get_one(PlayerId, Nth) of
	[] -> {fail, 0};
	Flyer ->
	    Flyer1 = Flyer#flyer{state = 1},
	    db:execute(io_lib:format(<<"update flyer set state=~p where id=~p">>,[1,Flyer1#flyer.id])),
	    update_flyer(PlayerId, Flyer1),
	    FlyerFigure = pack_flyer_figure(PlayerId, Nth),
	    PS1 = PS#player_status{flyer_attr = PS#player_status.flyer_attr#status_flyer{sky_figure = FlyerFigure}},
	    {ok, PS1}
    end.

%% 卸下飞行器
dismount_flyer(PS, Nth) ->
    PlayerId = PS#player_status.id,
    case get_one(PlayerId, Nth) of
	[] -> {fail, 0};
	Flyer ->
	    Flyer1 = Flyer#flyer{state = 0},
	    db:execute(io_lib:format(<<"update flyer set state=~p where id=~p">>,[0,Flyer1#flyer.id])),
	    update_flyer(PlayerId, Flyer1),
	    PS1 = PS#player_status{flyer_attr = PS#player_status.flyer_attr#status_flyer{figure = 0, sky_figure = 0}},
	    {ok, PS1}
    end.
%% %% 切换装备中的飞行器
%% @param: EquipFlyer:装备中的飞行器
change_equip_flyer(PS, Nth, EquipFlyer) ->
    PlayerId = PS#player_status.id,
    case get_one(PlayerId, Nth) of
	[] -> {fail, 0};
	Flyer ->
	    F = fun() ->
			db:execute(io_lib:format(<<"update flyer set state=~p where id=~p">>,[0, EquipFlyer#flyer.id])),
			db:execute(io_lib:format(<<"update flyer set state=~p where id=~p">>,[1, Flyer#flyer.id]))
		end,
	    db:transaction(F),
	    EquipFlyer1 = EquipFlyer#flyer{state = 0},
	    update_flyer(PlayerId, EquipFlyer1),
	    Flyer1 = Flyer#flyer{state = 1},
	    update_flyer(PlayerId, Flyer1),
	    FlyerFigure = pack_flyer_figure(PlayerId, Flyer1#flyer.nth),
	    PS1 = PS#player_status{flyer_attr = PS#player_status.flyer_attr#status_flyer{sky_figure = FlyerFigure}},
	    {ok, PS1}
    end.
%% @param N:概率在列表中的位置 L:概率列表
get_rand_from_ratio_list(N, L) ->
    TotalRatio = lib_goods_util:get_ratio_total(L, N),
    Rand = util:rand(1, TotalRatio),
    lib_goods_util:find_ratio(L, 0, Rand, N).
%% 计算单个飞行器所有属性加成 
calc_flyer_attr_single(Flyer) ->
    Addition = data_flyer:get_all_star_addition(Flyer#flyer.nth, Flyer#flyer.stars),
    BaseAttrList = data_flyer_config:get_base_attr_config(),
    TrainAttrList = data_flyer_config:get_train_attr_config(),
    BaseAttr =
	case lists:keyfind(Flyer#flyer.nth, 1, BaseAttrList) of
	    false -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
	    %% {_, BL} -> [{BLT,round(BLV*(1+Addition))} || {BLT,BLV}<- BL]
	    {_, BL} -> BL
	end,
    TrainAttr =
	case lists:keyfind(Flyer#flyer.nth, 1, TrainAttrList) of
	    false -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
	    {_, TL} -> [{TLT,Flyer#flyer.level*TLV} || {TLT,TLV} <- TL]
	end,
    Stars = Flyer#flyer.stars,
    StarAttr =
	lists:foldl(fun(Star, Sum) ->
			    Attr = Star#flyer_star.star_attr,
			    SL = expand_star_attr(Attr),
			    lists:zipwith(fun({N, X},{N, Y}) -> {N, X+Y} end, SL, Sum)
		    end, [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}], Stars),
    %% StarAttr = [{SLT,round(SLV*(1+Addition))} || {SLT,SLV} <- _StarAttr],
    lists:zipwith3(fun({N,X},{N,Y},{N,Z}) -> round((X+Y+Z)*(1+Addition)) end, BaseAttr, TrainAttr, StarAttr).

%% 计算单个飞行器所有属性加成 
calc_flyer_attr_single_for_preview(Flyer) ->
    Addition = data_flyer:get_all_star_addition(Flyer#flyer.nth, Flyer#flyer.stars),
    BaseAttrList = data_flyer_config:get_base_attr_config(),
    TrainAttrList = data_flyer_config:get_train_attr_config(),
    BaseAttr =
	case lists:keyfind(Flyer#flyer.nth, 1, BaseAttrList) of
	    false -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
	    %% {_, BL} -> [{BLT,round(BLV*(1+Addition))} || {BLT,BLV}<- BL]
	    {_, BL} -> BL
	end,
    TrainAttr =
	case lists:keyfind(Flyer#flyer.nth, 1, TrainAttrList) of
	    false -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
	    {_, TL} -> [{TLT,Flyer#flyer.level*TLV} || {TLT,TLV} <- TL]
	end,
    Stars = Flyer#flyer.stars,
    StarAttr =
	lists:foldl(fun(Star, Sum) ->
			    Attr = Star#flyer_star.star_attr,
			    SL = expand_star_attr(Attr),
			    lists:zipwith(fun({N, X},{N, Y}) -> {N, X+Y} end, SL, Sum)
		    end, [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}], Stars),
    %% StarAttr = [{SLT,round(SLV*(1+Addition))} || {SLT,SLV} <- _StarAttr],
    lists:zipwith3(fun({N,X},{N,Y},{N,Z}) -> {N,round((X+Y+Z)*(1+Addition))} end, BaseAttr, TrainAttr, StarAttr).
%% 计算所有飞行器基础属性加成 
calc_flyer_base_attr(Flyers) ->
    case Flyers =:= [] of
	true -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
	false ->
	    BaseAttrList = data_flyer_config:get_base_attr_config(),
	    Foldl = lists:foldl(fun(FlyerX, Acc) ->
				Addition = data_flyer:get_all_star_addition(FlyerX#flyer.nth, FlyerX#flyer.stars),
				BaseAttr =
				    case lists:keyfind(FlyerX#flyer.nth, 1, BaseAttrList) of
					false -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
					{_, L} -> [{Type, V*(1+Addition)} || {Type,V} <- L]
				    end,
				lists:zipwith(fun({N,X},{N,Y}) -> {N, X+Y} end, BaseAttr, Acc)
				end, [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}], Flyers),
	    [{Type, round(V)} || {Type, V} <- Foldl]
    end.
%% 计算所有飞行器训练属性加成 
calc_flyer_train_attr(Flyers) ->
    case Flyers =:= [] of
	true -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
	false ->
	    TrainAttrList = data_flyer_config:get_train_attr_config(),
	    Foldl = lists:foldl(fun(FlyerX, Acc) ->
				Addition = data_flyer:get_all_star_addition(FlyerX#flyer.nth, FlyerX#flyer.stars),
				TrainAttr =
				    case lists:keyfind(FlyerX#flyer.nth, 1, TrainAttrList) of
					false -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
					{_, L} -> [{Type, (FlyerX#flyer.level*V)*(1+Addition)} || {Type, V} <- L]
				    end,
				lists:zipwith(fun({N,X},{N,Y}) -> {N, X+Y} end, TrainAttr, Acc)
				end, [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}], Flyers),
	    [{Type, round(V)} || {Type, V} <- Foldl]
    end.
%% 计算所有飞行器星星属性加成
calc_flyer_star_attr(Flyers) ->
    case Flyers =:= [] of
	true -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
	false ->
	    Foldl = lists:foldl(
	      fun(FlyerX, Acc) ->
		      Stars = FlyerX#flyer.stars,
		      Addition = data_flyer:get_all_star_addition(FlyerX#flyer.nth, Stars),
		      StarAttr =
			  lists:foldl(fun(Star, Sum) ->
					      Attr = Star#flyer_star.star_attr,
					      L = expand_star_attr(Attr),
					      lists:zipwith(fun({N, X},{N, Y}) -> {N, X+Y} end, L, Sum)
				      end, [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}], Stars),
		      StarAttr1 = [{Type,V*(1+Addition)} || {Type, V} <- StarAttr],
		      lists:zipwith(fun({N,X},{N,Y}) -> {N, X+Y} end, StarAttr1, Acc)
	      end, [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}], Flyers),
	    [{Type, round(V)} || {Type, V} <- Foldl]
    end.

%% 九星连珠总分
calc_nine_star_convergence_total_score(Flyers) ->
    %% {{数量,品质},分数}
    FinalList = [{{1,2},12}, {{1,3},12}, {{1,4},12}, {{1,5},12},
		 {{2,2},12}, {{2,3},24}, {{2,4},24}, {{2,5},24}, 
		 {{3,2},12}, {{3,3},36}, {{3,4},36}, {{3,5},36},
		 {{4,2},12}, {{4,3},48}, {{4,4},48}, {{4,5},48},
		 {{5,2},12}, {{5,3},48}, {{5,4},60}, {{5,5},60},
		 {{6,2},12}, {{6,3},48}, {{6,4},72}, {{6,5},72},
		 {{7,2},12}, {{7,3},48}, {{7,4},84}, {{7,5},84},
		 {{8,2},12}, {{8,3},48}, {{8,4},84}, {{8,5},96},
		 {{9,2},12}, {{9,3},48}, {{9,4},84}, {{9,5},108},
		 {{10,2},12}, {{10,3},48}, {{10,4},84}, {{10,5},108}],
    QualityList = lists:map(fun(X) -> data_flyer:get_flyer_quality(X#flyer.nth, X#flyer.stars) end, Flyers),
    SortList = lists:sort(QualityList),
    L = lists:foldl(fun(X,Acc) ->
			case lists:keyfind(X,1,Acc) of
			    false -> [{X, 1} | Acc];
			    {Finded, Num} -> lists:keyreplace(Finded, 1, Acc, {Finded, Num+1})
			end
		    end, [], SortList),
    NewList = lists:map(fun({Quality,Num}) ->
				MaxCount = lists:foldl(fun({Q,N}, Acc) ->
							       case Q > Quality of
								   true -> Acc + N;
								   false -> Acc
							       end
						   end, 0, L) + Num,
				calc_nine_star_convergence_total_score(MaxCount, Quality, FinalList)
			end, L),
    case NewList =:= [] of
	true -> 0;
	false -> lists:max(NewList)
    end.

calc_nine_star_convergence_total_score(MaxCount, Quality, L) ->
    case lists:keyfind({MaxCount, Quality}, 1, L) of
	false -> 0;
	{_,Score} -> Score
    end.
	
%% 九星连珠属性加成
calc_nine_star_convergence_attr(Flyers) ->
    NineStarAttr = data_flyer_config:get_nine_star_convergence_attr(),
    Score = calc_nine_star_convergence_total_score(Flyers),
    if
	Score < 12 ->
	    [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
	Score < 24 ->
	    data_flyer:get_nine_star_convergence_attr_sub(1, NineStarAttr);
	Score < 36 ->
	    data_flyer:get_nine_star_convergence_attr_sub(2, NineStarAttr);
	Score < 48 ->
	    data_flyer:get_nine_star_convergence_attr_sub(3, NineStarAttr);
	Score < 60 ->
	    data_flyer:get_nine_star_convergence_attr_sub(4, NineStarAttr);
	Score < 72 ->
	    data_flyer:get_nine_star_convergence_attr_sub(5, NineStarAttr);
	Score < 84 ->
	    data_flyer:get_nine_star_convergence_attr_sub(6, NineStarAttr);
	Score < 96 ->
	    data_flyer:get_nine_star_convergence_attr_sub(7, NineStarAttr);
	Score < 108 ->
	    data_flyer:get_nine_star_convergence_attr_sub(8, NineStarAttr);
	true ->
	    data_flyer:get_nine_star_convergence_attr_sub(9, NineStarAttr)
    end.

expand_star_attr(StarAttr) ->
    FullList =
	lists:map(fun(Y) ->
			  {Type, _} = Y,
			  lists:map(fun(X) ->
					    case Type =:= X of
						true -> Y;
						false -> {X, 0}
					    end
				    end, [1,2,3,4,5,6,7,8,9,10])
		  end, StarAttr),
    lists:foldl(fun(Z, Acc) ->
			lists:zipwith(fun({N, Xx},{N, Yy}) -> {N, Xx+Yy} end, Z, Acc)
		end, [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}], FullList).
count_attribute_base(PS) ->
    case get_all(PS#player_status.id) of
	[] -> PS;
	Flyers ->
	    FlyerAttr = PS#player_status.flyer_attr,
	    BaseAttr = calc_flyer_base_attr(Flyers),
	    NewFlyerAttr = FlyerAttr#status_flyer{ base_attr = BaseAttr },
	    PS1 = PS#player_status{flyer_attr = NewFlyerAttr},
	    lib_player:count_player_attribute(PS1)
    end.
count_attribute_train(PS) ->    
    case get_all(PS#player_status.id) of
	[] -> PS;
	Flyers ->
	    FlyerAttr = PS#player_status.flyer_attr,
	    TrainAttr = calc_flyer_train_attr(Flyers),
	    NewFlyerAttr = FlyerAttr#status_flyer{ train_attr = TrainAttr },
	    PS1 = PS#player_status{flyer_attr = NewFlyerAttr},
	    lib_player:count_player_attribute(PS1)
    end.

count_attribute_star(PS) ->
    case get_all(PS#player_status.id) of
	[] -> PS;
	Flyers ->
	    FlyerAttr = PS#player_status.flyer_attr,
	    StarAttr = calc_flyer_star_attr(Flyers),
	    NineStarAttr = calc_nine_star_convergence_attr(Flyers),
	    NewFlyerAttr = FlyerAttr#status_flyer{ star_attr = StarAttr, convergence_attr = NineStarAttr },
	    PS1 = PS#player_status{flyer_attr = NewFlyerAttr},
	    lib_player:count_player_attribute(PS1)
    end.
%% 计算全部属性加成
%% @prarm: PS 
%% @return: NewPS
count_attribute_all(PS) ->
    case get_all(PS#player_status.id) of
	[] -> PS;
	Flyers ->
	    FlyerAttr = PS#player_status.flyer_attr,
	    BaseAttr = calc_flyer_base_attr(Flyers),
	    TrainAttr = calc_flyer_train_attr(Flyers),
	    StarAttr = calc_flyer_star_attr(Flyers),
	    NineStarAttr = calc_nine_star_convergence_attr(Flyers),
	    NewFlyerAttr = FlyerAttr#status_flyer{
			     base_attr = BaseAttr,
			     train_attr = TrainAttr,
			     star_attr = StarAttr,
			     convergence_attr = NineStarAttr
			    },
	    PS1 = PS#player_status{flyer_attr = NewFlyerAttr},
	    lib_player:count_player_attribute(PS1)
    end.
				   
compose_attr(Attr) ->
    BaseAttr = Attr#status_flyer.base_attr,
    TrainAttr = Attr#status_flyer.train_attr,
    StarAttr = Attr#status_flyer.star_attr,
    NineStarAttr = Attr#status_flyer.convergence_attr,
    OneAttr = lists:zipwith3(fun({N,X},{N,Y},{N,Z}) -> {N, X+Y+Z} end, BaseAttr, TrainAttr, StarAttr),
    lists:zipwith(fun({NN,XX},{NN,YY}) -> XX+YY end, OneAttr, NineStarAttr).
			  
			   
count_unlock_combat_power(Nth) ->
    BaseAttrList = data_flyer_config:get_base_attr_config(),
    [{_,Hp},{_,Att},{_,Def},{_,Fire},{_,Ice},{_,Drug},{_,Hit},{_,Dodge},{_,Crit},{_,Ten}] = 
	case lists:keyfind(Nth, 1, BaseAttrList) of
	    false -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
	    {_, L} -> L
	end,
    round(Hp*0.06 + Att*0.8988 + Def*0.3 + (Fire+Ice+Drug)*0.1 + Hit*0.3113 + Dodge*0.3736 + Crit*1 + Ten*0.5).
count_flyer_combat_power_by_flyer(Flyer) ->			 
    [Hp,Att,Def,Fire,Ice,Drug,Hit,Dodge,Crit,Ten] = calc_flyer_attr_single(Flyer),
    round(Hp*0.06 + Att*0.8988 + Def*0.3 + (Fire+Ice+Drug)*0.1 + Hit*0.3113 + Dodge*0.3736 + Crit*1 + Ten*0.5).

count_all_flyer_combat_power(TotalAttr) ->
    [{1,Hp},{2,Att},{3,Def},{4,Fire},{5,Ice},{6,Drug},{7,Hit},{8,Dodge},{9,Crit},{10,Ten}] = TotalAttr,
    round(Hp*0.06 + Att*0.8988 + Def*0.3 + (Fire+Ice+Drug)*0.1 + Hit*0.3113 + Dodge*0.3736 + Crit*1 + Ten*0.5).

%% -----------------------------------一系列打包操作-----------------------------begin
%% 分离和补全列表
parse_flyer_list(Flyers) ->
    FlyerListLen = length(Flyers),
    case FlyerListLen >= 10 of
	true ->
	    pack_bin_list(Flyers);
	false ->
	    {FillList,_} = lists:foldl(
			 fun(Nth, Acc) ->
				 {Records, N} = Acc,
				 Name = data_flyer:get_name(Nth),
				 Record = #flyer{nth=Nth, name=Name},
				 {[Record | Records], N}
			 end, {Flyers, 0}, lists:seq(FlyerListLen+1, 10)),
	    pack_bin_list(lists:keysort(3, FillList))
    end.

pack_bin_list(Flyers) ->
    lists:map(
      fun(Flyer) ->
	      [FlyerId, FlyerNth, FlyerState, FlyerName, FlyerOpen, FlyerLv] = [Flyer#flyer.id, Flyer#flyer.nth, Flyer#flyer.state, pt:write_string(Flyer#flyer.name), Flyer#flyer.open, Flyer#flyer.level],
	      <<FlyerId:32, FlyerNth:8, FlyerState:8, FlyerName/binary, FlyerOpen:8, FlyerLv:8>>
      end, Flyers).

parse_flyer_star_list(Star) ->
    StarValue = Star#flyer_star.star_value,
    StarAttr = Star#flyer_star.star_attr,
    StarAttrLen = length(StarAttr),
    AttrList = if
		   StarAttrLen =:= 1 ->
		       [{Type, Val}] = StarAttr,
		       [<<Type:8, Val:16>>];
		   StarAttrLen =:= 2 ->
		       [{T1,V1},{T2,V2}] = StarAttr,
		       case T1 =:= T2 of
			   true ->
			       Val = V1 + V2,
			       [<<T1:8, Val:16>>];
			   false ->
			       [<<T1:8, V1:16>>,<<T2:8, V2:16>>]
		       end;
		   StarAttrLen =:= 3 ->
		       [{T1,V1},{T2,V2},{T3,V3}] = StarAttr,
		       if
			   T1 =:= T2 andalso T1 =:= T3 ->
			       Val = V1 + V2 + V3,
			       [<<T1:8, Val:16>>];
			   T1 =:= T2 andalso T1 =/= T3 ->
			       Val = V1 + V2,
			       [<<T1:8, Val:16>>, <<T3:8, V3:16>>];
			   T1 =:= T3 andalso T1 =/= T2 ->
			       Val = V1 + V3,
			       [<<T1:8, Val:16>>, <<T2:8, V2:16>>];
			   T2 =:= T3 andalso T1 =/= T2 ->
			       Val = V2 + V3,
			       [<<T1:8, V1:16>>, <<T2:8, Val:16>>];
			   true ->
			       [<<T1:8, V1:16>>, <<T2:8, V2:16>>, <<T3:8, V3:16>>]
		       end;
		   true ->
		       []
	       end,
    BinLen = length(AttrList),
    Bin = list_to_binary(AttrList),
    StarSN = pt:write_string(Star#flyer_star.star_num),
    <<StarValue:16, BinLen:16, Bin/binary, StarSN/binary>>.
    
parse_flyer_info(Flyer, Nth, TrainCount) ->
    case is_record(Flyer, flyer) of
	true ->
	    [Hp, Att, Def, Fire, Ice, Drug, Hit, Dodge, Crit, Ten] = calc_flyer_attr_single(Flyer),
	    [Id, Name, Speed, Nth, State, CurrentLv, MaxLv, CombatPower, MaxFlyerStars, Open] = [Flyer#flyer.id, pt:write_string(Flyer#flyer.name), Flyer#flyer.speed, Flyer#flyer.nth, Flyer#flyer.state, Flyer#flyer.level, data_flyer:get_max_lv(Flyer#flyer.nth), Flyer#flyer.combat_power, data_flyer:get_flyer_max_star(Flyer#flyer.nth), Flyer#flyer.open],
	    Stars = Flyer#flyer.stars,
	    SortStarsList = lists:reverse(lists:keysort(4, Stars)),
	    StarsList =
		lists:map(fun(X) ->
				  StarAttrArray = parse_flyer_star_list(X),
				  <<StarAttrArray/binary>>
			  end, SortStarsList),
	    StarsListLen = length(StarsList),
	    StarsBin = list_to_binary(StarsList),
	    [Hp, Att, Def, Fire, Ice, Drug, Hit, Dodge, Crit, Ten] = calc_flyer_attr_single(Flyer),
	    <<Id:32, Name/binary, Speed:16, Nth:8, Open:8, CurrentLv:16, MaxLv:16, Hp:16, Att:16, Def:16, Fire:16, Ice:16, Drug:16, Hit:16, Dodge:16, Crit:16, Ten:16, CombatPower:32, MaxFlyerStars:8, StarsListLen:16, StarsBin/binary, State:8, TrainCount:8>>;
	false ->
	    Name = pt:write_string(data_flyer:get_name(Nth)),
	    MaxFlyerStars = data_flyer:get_flyer_max_star(Nth),
	    Speed = data_flyer:get_speed(Nth),
	    CombatPower = count_unlock_combat_power(Nth),
	    MaxLv = data_flyer:get_max_lv(Nth),
	    BaseAttrList = data_flyer_config:get_base_attr_config(),
	    BaseAttr =
		case lists:keyfind(Nth, 1, BaseAttrList) of
		    false -> [{1,0},{2,0},{3,0},{4,0},{5,0},{6,0},{7,0},{8,0},{9,0},{10,0}];
		    {_, BL} -> BL
		end,
	    [{_,Hp},{_,Att},{_,Def},{_,Fire},{_,Ice},{_,Drug},{_,Hit},{_,Dodge},{_,Crit},{_,Ten}] = BaseAttr,
	    <<0:32, Name/binary, Speed:16, Nth:8, 0:8, 0:16, MaxLv:16, Hp:16, Att:16, Def:16, Fire:16, Ice:16, Drug:16, Hit:16, Dodge:16, Crit:16, Ten:16, CombatPower:32, MaxFlyerStars:8, 0:16, <<>>/binary, 0:8, 0:8>>
    end.
%% -----------------------------------一系列打包操作-----------------------------end

send_flyer_fly_notice(PS, Nth) ->
    FlyerFigure = pack_flyer_figure(PS#player_status.id, Nth),
    {ok, Bin12301} = pt_123:write(12301, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num, FlyerFigure, PS#player_status.speed]),
    lib_server_send:send_to_area_scene(PS#player_status.scene, 
				       PS#player_status.copy_id,
				       PS#player_status.x, 
				       PS#player_status.y, Bin12301),
    {ok, Bin12003} = pt_120:write(12003, PS),
    lib_server_send:send_to_area_scene(PS#player_status.scene, PS#player_status.copy_id, PS#player_status.x, PS#player_status.y, Bin12003).

pack_flyer_figure(PlayerId, Nth) ->
    case get_one(PlayerId, Nth) of
	[] -> 0;
	Flyer ->
	    Param = data_flyer:get_all_star_figure(Nth, Flyer#flyer.stars),
	    Nth * 10 + Param
    end.

pack_flyer_figure_from_login(Flyers) ->
    Flying = case lists:filter(fun(X) -> X#flyer.state =:= 1 end, Flyers) of
		 [] -> [];
		 [H|_] -> H
	     end,
    case Flying =:= [] of
	true -> 0;
	false -> 
	    Param = data_flyer:get_all_star_figure(Flying#flyer.nth, Flying#flyer.stars),
	    Flying#flyer.nth * 10 + Param
    end.
%% ---------------------各种展示-------------------begin
show_flyer(LookPlayer, PlayerId, Nth) ->
    case lib_flyer:get_one(PlayerId, Nth) of
	[] -> [];
	Flyer ->
	    {ok, BinData} = pt_162:write(16211, [Flyer#flyer.nth, Flyer#flyer.stars, Flyer#flyer.combat_power, Flyer#flyer.name, data_flyer:get_flyer_max_star(Flyer#flyer.nth)]),
	    lib_server_send:send_to_uid(LookPlayer, BinData)
    end.

show_flyer_for_rank(LookId, PS, Nth) ->
    case lib_flyer:get_one(PS#player_status.id, Nth) of
	[] -> [];
	Flyer ->
	    FlyerFigure = pack_flyer_figure(PS#player_status.id, Nth),
	    FlyerStars = lists:reverse(lists:sort([Star#flyer_star.star_value || Star <- Flyer#flyer.stars])),
	    {ok, BinData} = pt_162:write(16212, [Flyer#flyer.name, PS#player_status.nickname, Flyer#flyer.level, FlyerFigure, Flyer#flyer.combat_power, FlyerStars, data_flyer:get_flyer_max_star(Nth), Flyer#flyer.quality, Nth]),
	    lib_server_send:send_to_uid(LookId, BinData)
    end.


show_flyer_for_rank_from_db(LookId, PlayerId, Nth) ->
    PlayerName = case db:get_one(io_lib:format(<<"select nickname from player_low where id=~p">>, [PlayerId])) of
		     false -> "";
		     Any -> Any
		 end,
    case db:get_row(io_lib:format(<<"select * from flyer where player_id=~p and nth=~p">>, [PlayerId, Nth])) of
	[] -> [];
	[Id, Nth, _, Open, Level, State, Speed, _Name, CombatPower, BackCount, Quality] ->
	    Name = data_flyer:get_name(Nth),
	    Stars =
		case db:get_all(io_lib:format(<<"select * from flyer_stars where player_id=~p and flyer_id=~p">>, [PlayerId, Id])) of
		    [] -> [];
		    SAll ->
			lists:map(fun([_, FlyerId, StarAttr, StarValue, TS, StarSN]) -> make_flyer_star_record([PlayerId, FlyerId, StarAttr, StarValue, TS, StarSN]) end, SAll)
		end,
	    Flyer = make_flyer_record([Id, Nth, PlayerId, Open, Level, Stars, State, Speed, Name, CombatPower, BackCount, Quality]),
	    Param = data_flyer:get_all_star_figure(Nth, Flyer#flyer.stars),
	    FlyerFigure = Nth * 10 + Param,
	    FlyerStars = lists:reverse(lists:sort([Star#flyer_star.star_value || Star <- Flyer#flyer.stars])),
	    {ok, BinData} = pt_162:write(16212, [Flyer#flyer.name, PlayerName, Flyer#flyer.level, FlyerFigure, Flyer#flyer.combat_power, FlyerStars, data_flyer:get_flyer_max_star(Nth), Flyer#flyer.quality, Nth]),
	    lib_server_send:send_to_uid(LookId, BinData)
    end.
%% ---------------------各种展示-------------------end


%% -----------------日志------------------begin
log_flyer_star(PlayerId, Nth, Star, Type) ->
    catch db:execute(io_lib:format(<<"insert into log_flyer_star(player_id, nth, star_attr, star_value, ts, type) values(~p,~p,'~s',~p,~p,~p)">>, [PlayerId, Nth, util:term_to_string(Star#flyer_star.star_attr), Star#flyer_star.star_value, util:unixtime(), Type])).

log_flyer_train(PlayerId, Nth, OldLv, NewLv) ->
    catch db:execute(io_lib:format(<<"insert into log_flyer_train(player_id, nth, old_lv, new_lv, ts) values(~p,~p,~p,~p,~p)">>, [PlayerId, Nth, OldLv, NewLv, util:unixtime()])).    
%% -----------------日志------------------end
check_span_time(PlayerID) ->
    Now = util:unixtime(),
    Span = io_lib:format("~pflyer_fly", [PlayerID]),
    case get(Span) of
	undefined ->
	    put(Span, Now),
	    ok;
	SpanTime ->
	    if
		%% 2次玩的间隔
		Now - SpanTime >= 5 -> 
		    put(Span, Now),
		    ok;
		true ->
		    error
	    end
    end.

check_span_time2(PlayerID) ->
    Now = util:longunixtime(),
    Span = io_lib:format("~pflyer_play", [PlayerID]),
    case get(Span) of
	undefined ->
	    put(Span, Now),
	    ok;
	SpanTime ->
	    if
		%% 2次玩的间隔
		Now - SpanTime >= 5 -> 
		    put(Span, Now),
		    ok;
		true ->
		    error
	    end
    end.

check_can_play(PS, Nth) ->
    SpanTime = check_span_time2(PS#player_status.id),
    if
	PS#player_status.lv < 60 -> false;
	Nth > 10 -> false;
	SpanTime =/= ok -> false;
	true -> true
    end.
	
