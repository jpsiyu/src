%%%-----------------------------------
%%% @Module  : log
%%% @Author  : xhg
%%% @Email   : xuhuguang@jieyou.com
%%% @Created : 2010.07.23
%%% @Description: 游戏日志
%%%-----------------------------------

-module(log).
-include("server.hrl").
-include("goods.hrl").
-include("gift.hrl").
-include("sell.hrl").
-include("mount.hrl").
-compile(export_all).

%% 装备强化日志
log_stren(GoodsInfo, StoneId, StoneTypeId, Ratio, Cost, Status, Lv, LuckyId, About) ->
    Sql = io_lib:format(<<"insert into `log_stren` set `time`=UNIX_TIMESTAMP(), `player_id`=~p, `lv`=~p, `gid`=~p, `goods_id`=~p, `subtype`=~p, `level`=~p, `stren`=~p, `stren_ratio`=~p, `sid`=~p, `stone_id`=~p, `ratio`=~p, `cost`=~p, `status`=~p, `lucky_id`=~p, `about`='~s'  ">>,
                                [GoodsInfo#goods.player_id, Lv, GoodsInfo#goods.id, GoodsInfo#goods.goods_id, GoodsInfo#goods.subtype, data_goods:get_level(GoodsInfo#goods.level), GoodsInfo#goods.stren, GoodsInfo#goods.stren_ratio, StoneId, StoneTypeId, Ratio, Cost, Status, LuckyId, About ]),
    db:execute(Sql),
    ok.

%% 坐骑强化日志
log_mount_stren(Mount, StoneTypeId, Ratio, Cost, Status, Lv, LuckyId, About) ->
    Sql = io_lib:format(<<"insert into `log_mount_stren` set `time`=UNIX_TIMESTAMP(), `role_id`=~p, `lv`=~p, `mount_id`=~p, `type_id`=~p, `figure`=~p, `stren`=~p, `stren_ratio`=~p, `stone_id`=~p, `stone_num`=1, `ratio`=~p, `cost`=~p, `status`=~p, `lucky_id`=~p, `about`='~s'  ">>, [Mount#ets_mount.role_id, Lv, Mount#ets_mount.id, Mount#ets_mount.type_id, Mount#ets_mount.figure, Mount#ets_mount.stren, Mount#ets_mount.stren_ratio, StoneTypeId, Ratio, Cost, Status, LuckyId, About ]),
    db:execute(Sql),
    ok.

%% 坐骑进阶升星
log_mount_upgrade(Mount, NewMount, Lv, GoodsId, Num, Cost, Ratio, Ram, Status, About) ->
    Sql = io_lib:format(<<"insert into log_mount_upgrade set `time`=UNIX_TIMESTAMP(), `role_id`=~p, `lv`=~p, `mount_id`=~p, `old_type`=~p, 
                           `new_type`=~p, `level`=~p, `star`=~p, `star_value`=~p, `rune_id`=~p, `rune_num`=~p, `ratio`=~p, 
                           `ram`=~p, `cost`=~p, `status`=~p, `about`='~s'  ">>, 
                        [Mount#ets_mount.role_id, Lv, Mount#ets_mount.id, Mount#ets_mount.type_id, NewMount#ets_mount.type_id, 
                         NewMount#ets_mount.level, NewMount#ets_mount.star,NewMount#ets_mount.star_value, GoodsId, Num, Ratio, 
                         Ram, Cost, Status, About ]),
    db:execute(Sql),
    ok.

log_mount_upfly(Mount, NewMount, GoodsId, Num, Cost, Ratio, Status, Lv, UpValue, About) ->
    Sql = io_lib:format(<<"insert into `log_mount_upfly` set
        `time`=UNIX_TIMESTAMP(), `role_id`=~p, `lv`=~p, `mount_id`=~p,
        `old_type`=~p, `new_type`=~p, `stren`=~p, `fly_value`=~p, `rune_id`=~p, `rune_num`=~p, `ratio`=~p, `cost`=~p, `status`=~p, `about`='~s'  ">>, [Mount#ets_mount.role_id, Lv, Mount#ets_mount.id, Mount#ets_mount.type_id, NewMount#ets_mount.type_id, Mount#ets_mount.stren, UpValue, GoodsId, Num, Ratio, Cost, Status, About ]),
    db:execute(Sql),
    ok.

%% 坐骑资质
%% Mount, NewMount,PS#player_status.lv, Type, 0, 0, Coin, About
log_mount_quality(Mount, NewMount, Lv, Type, GoodsId, Num, Cost, About) ->
    Sql = io_lib:format(<<"insert into `log_mount_quality` set `time`=UNIX_TIMESTAMP(), `role_id`=~p, `lv`=~p, `mount_id`=~p, `type`=~p,
                          `old_quality_attr`='~s', `temp_quality_attr`='~s', `quality_lv`=~p, `goods_id`=~p, `num`=~p, `cost`=~p, `about`='~s'">>,
                        [Mount#ets_mount.role_id, Lv, Mount#ets_mount.id, Type, util:term_to_string(NewMount#ets_mount.quality_attr), 
                         util:term_to_string(NewMount#ets_mount.temp_quality_attr), Mount#ets_mount.quality_lv, GoodsId, Num, Cost, About]),
    db:execute(Sql),
    ok.


%% 坐骑资质替换保留
log_mount_quality_replace(Mount, NewMount, Lv, Type) ->
    Sql = io_lib:format(<<"insert into `log_mount_quality_replace` set `time`=UNIX_TIMESTAMP(), `role_id`=~p, `lv`=~p, `mount_id`=~p, 
                           `type`=~p,  `old_quality_attr`='~s', `new_quality_attr`='~s', `old_quality_lv`=~p, `new_quality_lv`=~p">>, 
                        [Mount#ets_mount.role_id, Lv, Mount#ets_mount.id, Type, 
                         util:term_to_string(Mount#ets_mount.quality_attr), 
                         util:term_to_string(NewMount#ets_mount.quality_attr), 
                         Mount#ets_mount.quality_lv,
                         NewMount#ets_mount.quality_lv]),
    db:execute(Sql),
    ok.

%% 灵犀记录
log_mount_lingxi(Mount, NewMount, Lv, GoodsId, Num) ->
    Sql = io_lib:format(<<"insert into `log_mount_lingxi` set `time`=UNIX_TIMESTAMP(), `role_id`=~p, `lv`=~p, `mount_id`=~p, 
                           `old_lingxi_num`=~p, `new_ling_num`=~p, `old_lingxi_attr`='~s', `new_ling_attr`='~s', `goods_id`=~p, `num`=~p">>, 
                        [Mount#ets_mount.role_id, Lv, Mount#ets_mount.id, Mount#ets_mount.lingxi_num,
                         NewMount#ets_mount.lingxi_num, util:term_to_string(Mount#ets_mount.lingxi_attr), 
                         util:term_to_string(NewMount#ets_mount.lingxi_attr), GoodsId, Num]),
    db:execute(Sql),
    ok.

%% 坐骑激活日志
log_mount_card(Mount, Gid, GoodsId, GoodsNum) ->
    Sql = io_lib:format(<<"insert into `log_mount_card` set `role_id`=~p, `gid`=~p, `goods_id`=~p, `goods_num`=~p, `mount_id`=~p, `type_id`=~p, `figure`=~p, `stren`=~p, `time`=UNIX_TIMESTAMP() ">>,
                          [Mount#ets_mount.role_id, Gid, GoodsId, GoodsNum, Mount#ets_mount.id, Mount#ets_mount.type_id, Mount#ets_mount.figure, Mount#ets_mount.stren]),
    db:execute(Sql),
    ok.

%% 装备品质升级日志
log_quality_up(PlayerStatus, GoodsInfo, StoneId, Cost, Status) ->
    Sql = io_lib:format(<<"insert into `log_quality_up` set time=UNIX_TIMESTAMP(), player_id=~p, gid=~p, goods_id=~p, subtype=~p, level=~p, stone_id=~p, cost=~p, status=~p  ">>,
                                [PlayerStatus#player_status.id, GoodsInfo#goods.id, GoodsInfo#goods.goods_id, GoodsInfo#goods.subtype, data_goods:get_level(GoodsInfo#goods.level), StoneId, Cost, Status ]),
    db:execute(Sql),
    ok.

%% 宝箱兑换日志
log_box_exchange(Pid, StoneTypeId, Num, NewGoodsId) ->
    Sql = io_lib:format(<<"insert into `log_box_exchange` set time=UNIX_TIMESTAMP(), pid=~p, stone_id=~p, stone_num=~p, new_gid=~p ">>, [Pid, StoneTypeId, Num, NewGoodsId]),
    db:execute(Sql),
    ok.

%% 宝石合成日志
log_compose(PlayerId, Lv, Rule, Subtype, RuneId, RuneNum, Cost, Status, About) ->
    Sql = io_lib:format(<<"insert into `log_compose` set `time`=UNIX_TIMESTAMP(), `player_id`=~p, `lv`=~p, `goods_id`=~p, `subtype`=~p, `stone_num`=~p, `new_id`=~p, `rune_id`=~p, `rune_num`=~p, `cost`=~p, `status`=~p, `about`='~s'  ">>,
                                [PlayerId, Lv, Rule#ets_goods_compose.goods_id, Subtype, Rule#ets_goods_compose.goods_num, Rule#ets_goods_compose.new_id, RuneId, RuneNum, Cost, Status, About]),
    db:execute(Sql),
    ok.

%% 宝石镶嵌日志
log_inlay(GoodsInfo, StoneId, StoneTypeId, Cost, Status, Lv, About) ->
    Sql = io_lib:format(<<"insert into `log_inlay` set `time`=UNIX_TIMESTAMP(), `player_id`=~p, `lv`=~p, `gid`=~p, `goods_id`=~p, `level`=~p, `sid`=~p, `stone_id`=~p, `cost`=~p, `status`=~p, `about`='~s'  ">>,
                                [GoodsInfo#goods.player_id, Lv, GoodsInfo#goods.id, GoodsInfo#goods.goods_id, data_goods:get_level(GoodsInfo#goods.level), StoneId, StoneTypeId, Cost, Status, About ]),
    db:execute(Sql),
    ok.

%% 宝石拆除日志
log_backout(GoodsInfo, StoneId, NewStoneId, Cost, Status, About) ->
    Sql = io_lib:format(<<"insert into `log_backout` set time=UNIX_TIMESTAMP(), player_id=~p, gid=~p, goods_id=~p, level=~p, stone1_id=~p, stone2_id=~p, cost=~p, status=~p, `about`='~s' ">>,
                                [GoodsInfo#goods.player_id, GoodsInfo#goods.id, GoodsInfo#goods.goods_id, data_goods:get_level(GoodsInfo#goods.level), StoneId, NewStoneId, Cost, Status, About ]),
    db:execute(Sql),
    ok.

%% 消费日志
%% Type : 消费类型 term    data_goods:get_consume_type(Type)
%% MoneyType : 金钱类型 term  (coin, bcoin, gold, bgold)
%% PlayerStatus : 消费前的玩家状态  record
%% NewPlayerStatus : 消费后的玩家状态  record
%% About : 消费内容 string
log_consume(Type, MoneyType, PlayerStatus, NewPlayerStatus, About) ->
    log_consume(Type, MoneyType, PlayerStatus, NewPlayerStatus, 0, 0, About).

log_consume(Type, MoneyType, PlayerStatus, NewPlayerStatus, GoodsTypeId, GoodsNum, About) ->
    ConsumeType = data_goods:get_consume_type(Type),
    if  MoneyType =:= coin orelse MoneyType =:= bcoin ->
            Cost_coin = PlayerStatus#player_status.coin - NewPlayerStatus#player_status.coin,
            Cost_bcoin = PlayerStatus#player_status.bcoin - NewPlayerStatus#player_status.bcoin,
            Remain_coin = NewPlayerStatus#player_status.coin,
            Remain_bcoin = NewPlayerStatus#player_status.bcoin,
            Lv = NewPlayerStatus#player_status.lv,
            Sql = io_lib:format(<<"insert into `log_consume_coin` set time=UNIX_TIMESTAMP(), consume_type=~p, player_id=~p, goods_id=~p, goods_num=~p, cost_coin=~p, cost_bcoin=~p, remain_coin=~p, remain_bcoin=~p, about='~s',lv = ~p">>,
                                        [ConsumeType, PlayerStatus#player_status.id, GoodsTypeId, GoodsNum, Cost_coin, Cost_bcoin, Remain_coin, Remain_bcoin, About, Lv ]),
            db:execute(Sql);
        MoneyType =:= gold orelse MoneyType =:= bgold orelse MoneyType =:= silver orelse MoneyType =:= silver_and_gold ->
            Cost_bgold = PlayerStatus#player_status.bgold - NewPlayerStatus#player_status.bgold,
            Cost_gold = PlayerStatus#player_status.gold - NewPlayerStatus#player_status.gold,
            Remain_bgold = NewPlayerStatus#player_status.bgold,
            Remain_gold = NewPlayerStatus#player_status.gold,
            Lv = NewPlayerStatus#player_status.lv,
            Sql = io_lib:format(<<"insert into `log_consume_gold` set time=UNIX_TIMESTAMP(), consume_type=~p, player_id=~p, goods_id=~p, goods_num=~p, cost_gold=~p, cost_bgold=~p, remain_gold=~p, remain_bgold=~p, about='~s', lv = ~p ">>,
                                        [ConsumeType, PlayerStatus#player_status.id, GoodsTypeId, GoodsNum, Cost_gold, Cost_bgold, Remain_gold, Remain_bgold, About, Lv]),
            db:execute(Sql);
        MoneyType =:= point ->  
            Cost_point = PlayerStatus#player_status.point - NewPlayerStatus#player_status.point,
            Remain_point = NewPlayerStatus#player_status.point,
            Sql = io_lib:format(<<"insert into `log_consume_point` set time=UNIX_TIMESTAMP(), consume_type=~p, player_id=~p, goods_id=~p, goods_num=~p, cost_point=~p, remain_point=~p, about='~s' ">>,
                                        [ConsumeType, PlayerStatus#player_status.id, GoodsTypeId, GoodsNum, Cost_point, Remain_point, About ]),
            db:execute(Sql);
        true -> skip
    end,
    ok.

%% 积分兑换，帮战和竞技场
log_consume_point(Type, Id, Totle, RestScore, About) ->
    ConsumeType = data_goods:get_consume_type(Type),
    Cost_point = Totle - RestScore,
    Sql = io_lib:format(<<"insert into `log_consume_point` set time=UNIX_TIMESTAMP(), consume_type=~p, player_id=~p, goods_id=~p, goods_num=~p, cost_point=~p, remain_point=~p, about='~s' ">>,[ConsumeType, Id, 0, 0, Cost_point, RestScore, About]),
    db:execute(Sql),
    ok.

%% 货币生产日志
%% Type : 生产类型 term    data_goods:get_produce_type(Type)
%% MoneyType : 金钱类型 term  (coin, bcoin, gold, bgold)
%% PlayerStatus : 生产前的玩家状态  record
%% NewPlayerStatus : 生产后的玩家状态  record
%% About : 消费内容 string
%% 	TODO :
%%		【 注意】：这个方法在充值lib_recharge:pay_offline中，会模拟出PlayerStatus跟NewPlayerStatus
%%						因此，如果需要用到coin, bcoin, bgold, gold, id之外的数据，需要通知同步修改，否则影响充值处理
log_produce(Type, MoneyType, PlayerStatus, NewPlayerStatus, About) ->
    ProduceType = data_goods:get_produce_type(Type),
    case MoneyType =:= coin orelse MoneyType =:= bcoin of
        true ->
            Got_coin = NewPlayerStatus#player_status.coin - PlayerStatus#player_status.coin,
            Got_bcoin = NewPlayerStatus#player_status.bcoin - PlayerStatus#player_status.bcoin,
            Remain_coin = NewPlayerStatus#player_status.coin,
            Remain_bcoin = NewPlayerStatus#player_status.bcoin,
            Sql = io_lib:format(<<"insert into `log_produce_coin` set time=UNIX_TIMESTAMP(), produce_type=~p, player_id=~p, got_coin=~p, got_bcoin=~p, remain_coin=~p, remain_bcoin=~p, about='~s' ">>,
                                        [ProduceType, PlayerStatus#player_status.id, Got_coin, Got_bcoin, Remain_coin, Remain_bcoin, About ]),
            db:execute(Sql);
        false when MoneyType =:= gold orelse MoneyType =:= bgold ->
            Got_bgold = NewPlayerStatus#player_status.bgold - PlayerStatus#player_status.bgold,
            Got_gold = NewPlayerStatus#player_status.gold - PlayerStatus#player_status.gold,
            Remain_bgold = NewPlayerStatus#player_status.bgold,
            Remain_gold = NewPlayerStatus#player_status.gold,
            Sql = io_lib:format(<<"insert into `log_produce_gold` set time=UNIX_TIMESTAMP(), produce_type=~p, player_id=~p, got_gold=~p, got_bgold=~p, remain_gold=~p, remain_bgold=~p, about='~s' ">>,
                                        [ProduceType, PlayerStatus#player_status.id, Got_gold, Got_bgold, Remain_gold, Remain_bgold, About ]),
            db:execute(Sql);
        _ -> skip
    end,
    ok.

%% 物品产出日志
log_goods(Type, SubType, GoodsTypeId, GoodsNum, PlayerId) ->
    TypeId = data_goods:get_goods_produce_type(Type),
    Sql = io_lib:format(<<"insert into `log_goods` set time=UNIX_TIMESTAMP(), type=~p, subtype=~p, goods_id=~p, goods_num=~p, player_id=~p ">>,
                                [TypeId, SubType, GoodsTypeId, GoodsNum, PlayerId]),
    db:execute(Sql),
    ok.

%% 挂售日志
log_sell(Type, SellInfo, PayerId, MailId) ->
    Sql = io_lib:format(<<"insert into `log_sell` set `time`=UNIX_TIMESTAMP(), `type`=~p, `seller`=~p, `payer`=~p, `gid`=~p, `goods_id`=~p, `goods_num`=~p, `price_type`=~p, `price`=~p, `sell_time`=~p, `mail`=~p, `sell_id`=~p ">>,
                                [Type, SellInfo#ets_sell.pid, PayerId, SellInfo#ets_sell.gid, SellInfo#ets_sell.goods_id, SellInfo#ets_sell.num, SellInfo#ets_sell.price_type, SellInfo#ets_sell.price, SellInfo#ets_sell.time, MailId, SellInfo#ets_sell.id]),
    db:execute(Sql),
    ok.

%% 求购日志
log_buy(Type, WtbInfo, Payer, MailId) ->
    Sql = io_lib:format(<<"insert into `log_wtb` set `time`=UNIX_TIMESTAMP(), `type`=~p, `payer`=~p, `seller`=~p, `goods_id`=~p, `goods_num`=~p, `prefix`=~p, `stren`=~p, `price_type`=~p, `price`=~p, `sell_time`=~p, `mail`=~p, `wtb_id`=~p ">>,
                                [Type, WtbInfo#ets_buy.pid, Payer, WtbInfo#ets_buy.goods_id, WtbInfo#ets_buy.num, WtbInfo#ets_buy.prefix, WtbInfo#ets_buy.stren, WtbInfo#ets_buy.price_type, WtbInfo#ets_buy.price, WtbInfo#ets_buy.time, MailId, WtbInfo#ets_buy.id]),
    db:execute(Sql),
    ok.
log_pay_buy(Type, WtbInfo, GoodsInfo, GoodsNum, MailId) ->
    Sql = io_lib:format(<<"insert into `log_wtb` set `time`=UNIX_TIMESTAMP(), `type`=~p, `payer`=~p, `seller`=~p, `gid`=~p, `goods_id`=~p, `goods_num`=~p, `prefix`=~p, `stren`=~p, `price_type`=~p, `price`=~p, `sell_time`=~p, `mail`=~p, `wtb_id`=~p ">>,
                                [Type, WtbInfo#ets_buy.pid, GoodsInfo#goods.player_id, GoodsInfo#goods.id, GoodsInfo#goods.goods_id, GoodsNum, GoodsInfo#goods.prefix, GoodsInfo#goods.stren, WtbInfo#ets_buy.price_type, WtbInfo#ets_buy.price, WtbInfo#ets_buy.time, MailId, WtbInfo#ets_buy.id]),
    db:execute(Sql),
    ok.

%% 销毁日志
log_throw(Type, PlayerId, GoodsId, GoodsTypeId, GoodsNum, Prefix, Stren) ->
    TypeId = data_goods:get_goods_passoff_type(Type),
    Sql = io_lib:format(<<"insert into `log_throw` set `time`=UNIX_TIMESTAMP(), `type`=~p, `pid`=~p, `gid`=~p, `goods_id`=~p, `goods_num`=~p, `prefix`=~p, `stren`=~p ">>,
                                [TypeId, PlayerId, GoodsId, GoodsTypeId, GoodsNum, Prefix, Stren]),
    db:execute(Sql),
    ok.

%% 交易日志
log_trade(PlayerId1, PlayerId2, Coin1, Coin2, About1, About2) ->
    Sql = io_lib:format(<<"insert into `log_trade` set time=UNIX_TIMESTAMP(), pid1=~p, pid2=~p, coin1=~p, coin2=~p, about1='~s', about2='~s' ">>,
                                [PlayerId1, PlayerId2, Coin1, Coin2, About1, About2]),
    db:execute(Sql),
    ok.

%% 管理员日志
log_admin(About) ->
    Sql = io_lib:format(<<"insert into `adminlog` set ctime=UNIX_TIMESTAMP(), text='~s' ">>,
                                [About]),
    db:execute(Sql),
    ok.

%% 宝箱日志
log_box(Type, PlayerId, BoxId, BoxNum, GoodsTypeId, GoodsNum, Bind) ->
    Sql = io_lib:format(<<"insert into `log_box` set `type`=~p, `time`=UNIX_TIMESTAMP(), `pid`=~p, `box_id`=~p, `box_num`=~p, `goods_id`=~p, `goods_num`=~p, `bind`=~p ">>,
                                [Type, PlayerId, BoxId, BoxNum, GoodsTypeId, GoodsNum, Bind]),
    db:execute(Sql),
    ok.

%% 帮派物品日志
log_guild_goods(Type, PlayerId, GuildId, GoodsInfo, GoodsNum) ->
    Sql = io_lib:format(<<"insert into `log_guild_goods` set time=UNIX_TIMESTAMP(), gid=~p, type=~p, goods_id=~p, goods_num=~p, pid=~p, guild_id=~p ">>,
                                [GoodsInfo#goods.id, Type, GoodsInfo#goods.goods_id, GoodsNum, PlayerId, GuildId]),
    db:execute(Sql),
    ok.

%% 装备合成日志
log_equip_compose(PlayerId, About) ->
    Sql = io_lib:format(<<"insert into `log_equip_compose` set time=UNIX_TIMESTAMP(), pid=~p, about='~s' ">>,
                                [PlayerId, About]),
    db:execute(Sql),
    ok.

%% 装备继承日志
log_equip_inherit(PlayerId, About) ->
    Sql = io_lib:format(<<"insert into `log_equip_inherit` set time=UNIX_TIMESTAMP(), pid=~p, about='~s' ">>,
                                [PlayerId, About]),
    db:execute(Sql),
    ok.

%% 装备洗炼日志
log_equip_wash(PlayerId, About, GoodsTypeId, Addition, Id) ->
    Sql = io_lib:format(<<"insert into `log_equip_wash` set time=UNIX_TIMESTAMP(), pid=~p, about='~s', type_id=~p, list='~s', goods_id=~p ">>,
                                [PlayerId, About, GoodsTypeId, util:term_to_string(Addition), Id]),
    db:execute(Sql),
    ok.

%% 装备分解日志
log_equip_resolve(PlayerId, About, List) ->
    Sql = io_lib:format(<<"insert into `log_equip_resolve` set time=UNIX_TIMESTAMP(), pid=~p, about='~s', list='~s' ">>,
                                [PlayerId, About, util:term_to_string(List)]),
    db:execute(Sql),
    ok.

%% 兑换日志
log_exchange(PlayerId, RawGoods, DstGoods, ExchangeId, ExchangeNum, RawScore, DstScore) ->
    Sql = io_lib:format(<<"insert into `log_exchange` set `time`=UNIX_TIMESTAMP(), `pid`=~p, `raw_goods`='~s', `dst_goods`='~s', `exchange_id`=~p, `exchange_num`=~p, `raw_score`=~p, `dst_score`=~p ">>,
                                [PlayerId, util:term_to_string(RawGoods), util:term_to_string(DstGoods), ExchangeId, ExchangeNum, RawScore, DstScore]),
    db:execute(Sql),
    ok.

%% 装备精炼日志
log_weapon_compose(PlayerId, RuleInfo, OldGoodsInfo, NewGoodsInfo, About) ->
    Sql = io_lib:format(<<"insert into `log_weapon_compose` set time=UNIX_TIMESTAMP(), pid=~p, gid=~p, goods_id=~p, stone_id=~p, stone_num=~p, stuff_id=~p, stuff_num=~p, new_gid=~p, new_goods=~p, cost=~p, llpt=~p, status=1, about='~s' ">>,
                                [PlayerId, OldGoodsInfo#goods.id, OldGoodsInfo#goods.goods_id, RuleInfo#ets_weapon_compose.stone_id, RuleInfo#ets_weapon_compose.stone_num, RuleInfo#ets_weapon_compose.stuff_id, RuleInfo#ets_weapon_compose.stuff_num, NewGoodsInfo#goods.id, NewGoodsInfo#goods.goods_id, RuleInfo#ets_weapon_compose.coin, 0, About]),
    db:execute(Sql),
    ok.

%% 装备进阶日志
log_equip_advanced(PlayerId, RuleInfo, OldGoodsInfo, NewGoodsInfo, About) ->
    Sql = io_lib:format(<<"insert into `log_equip_advanced` set time=UNIX_TIMESTAMP(), pid=~p, gid=~p, goods_id=~p, stone_id=~p, stone_num=~p, stuff_id=~p, stuff_num=~p, new_gid=~p, new_goods=~p, cost=~p, llpt=~p, status=1, about='~s' ">>,
                                [PlayerId, OldGoodsInfo#goods.id, OldGoodsInfo#goods.goods_id, RuleInfo#ets_weapon_compose.stone_id, RuleInfo#ets_weapon_compose.stone_num, RuleInfo#ets_weapon_compose.stuff_id, RuleInfo#ets_weapon_compose.stuff_num, NewGoodsInfo#goods.id, NewGoodsInfo#goods.goods_id, RuleInfo#ets_weapon_compose.coin, 0, About]),
    db:execute(Sql),
    ok.

%% 远征岛日志
log_tower(PlayerId, Nickname, TowerName, Level, Passtime, Honour, TotalHonour, KingHonour, TotalKingHonour) ->
    Sql = io_lib:format(<<"insert into `log_tower` set time=UNIX_TIMESTAMP(), player_id = ~p, nickname = '~s', layer=~p, passtime=~p, honour=~p, total_honour=~p, towername = '~s', king_honour = ~p, total_king_honour = ~p">>, [PlayerId, Nickname, Level, Passtime, Honour, TotalHonour, TowerName, KingHonour, TotalKingHonour]),
    db:execute(Sql),
    ok.

%% 玩家在线时长
log_online_time(PlayerStatus) ->
    Time = util:unixdate(),
    NowTime = util:unixtime(),
    Sql = io_lib:format(<<"select id,ol_time from `log_online_time` where role_id=~p and ctime=~p limit 1">>, [PlayerStatus#player_status.id, Time]),
    case db:get_row(Sql) of
        [] ->
            OnlineTime = case NowTime > PlayerStatus#player_status.last_login_time of
                             true -> NowTime - PlayerStatus#player_status.last_login_time;
                             false -> 0
                         end,
            Sql1 = io_lib:format(<<"insert into `log_online_time` set role_id=~p, ol_time=~p, ctime=~p">>, [PlayerStatus#player_status.id, OnlineTime, Time]),
            db:execute(Sql1);
        [Id, Ol_time] ->
            OnlineTime = case NowTime > PlayerStatus#player_status.last_login_time of
                             true -> NowTime - PlayerStatus#player_status.last_login_time + Ol_time;
                             false -> Ol_time
                         end,
            Sql1 = io_lib:format(<<"update `log_online_time` set ol_time=~p where id=~p ">>, [OnlineTime, Id]),
            db:execute(Sql1)
    end,
    ok.

%% 装备淬炼日志
log_gift(PlayerId, GoodsId, GiftInfo, About) ->
    Sql = io_lib:format(<<"insert into `log_gift` set time=UNIX_TIMESTAMP(), pid = ~p, gid = ~p, goods_id = ~p, gift_id = ~p, about='~s' ">>, [PlayerId, GoodsId, GiftInfo#ets_gift.goods_id, GiftInfo#ets_gift.id, About]),
    db:execute(Sql),
    ok.

%% 矿石掉落
log_ore_drop(Type, SubType, GoodsTypeId, Num, PlayerId) ->
     Sql = io_lib:format(<<"insert into `log_ore_drop` set time=UNIX_TIMESTAMP(), type=~p, subtype=~p, goods_id=~p, goods_num=~p, player_id=~p ">>, [Type, SubType, GoodsTypeId, Num, PlayerId]),
    db:execute(Sql),
    ok.

%% 帮派奖励物品
log_guild_award(Type, GuildId, PlayerId, About) ->
     Sql = io_lib:format(<<"insert into `log_guild_award` set time=UNIX_TIMESTAMP(), type=~p, guild_id=~p, player_id=~p, about='~s' ">>, [Type, GuildId, PlayerId, About]),
    db:execute(Sql),
    ok.

%% 礼包日志
log_gift(PlayerId, GoodsId, GoodsTypeId, GiftId, About) ->
     Sql = io_lib:format(<<"insert into `log_gift` set time=UNIX_TIMESTAMP(), pid=~p, gid=~p, goods_id=~p, gift_id=~p, about='~s' ">>,
                [PlayerId, GoodsId, GoodsTypeId, GiftId, About]),
    db:execute(Sql),
    ok.

%% 升级日志
log_uplv(PlayerId, Lv) ->
     Sql = io_lib:format(<<"insert into `log_uplv` set time=UNIX_TIMESTAMP(), pid=~p, lv=~p ">>,
                [PlayerId, Lv]),
    db:execute(Sql),
    ok.

%% 成就日志
log_chengjiu(Role_id, Chengjiu_id, Num, Count, Cjpt) ->
     Sql = io_lib:format(<<"insert into `log_chengjiu` set time=UNIX_TIMESTAMP(), role_id=~p, chengjiu_id=~p, num=~p, count=~p, cjpt=~p ">>,
                [Role_id, Chengjiu_id, Num, Count, Cjpt]),
    db:execute(Sql),
    ok.

%% 登录日志, type 0登录, 1注册
log_login(PlayerId, Ip) ->
    Sql = io_lib:format(<<"insert into `log_login` set `time`=UNIX_TIMESTAMP(), `player_id`=~p, `ip`='~s' ">>,
                                [PlayerId, util:ip2bin(Ip)]),
    db:execute(Sql),
    ok.

%% 回头率日志
log_comeback(PlayerId, Lv) ->
    Sql = io_lib:format(<<"insert into `log_comeback` set `ctime`=UNIX_TIMESTAMP(), `role_id`=~p, `lv`=~p ">>, [PlayerId, Lv]),
    db:execute(Sql),
    ok.

%% 活跃度领取宝箱日志
log_target_day(PlayerId, TargetId, FinNum) ->
    Sql = io_lib:format(<<"insert into `log_target_day` set `time`=UNIX_TIMESTAMP(), `player_id`=~p, `target_id`=~p, `fin_num`= ~p">>,[PlayerId, TargetId, FinNum]),
    db:execute(Sql),
    ok.

%% 物品使用日志
log_goods_use(Role_id, GoodsId, GoodsNum) ->
    Sql = io_lib:format("insert into `log_goods_use` set `time`=UNIX_TIMESTAMP(), `role_id`=~p, `goods_id`=~p, `goods_num`=~p ",
                            [Role_id, GoodsId, GoodsNum]),
    db:execute(Sql),
    ok.

%% 装备进阶日志
equip_upgrade(Rule, PlayerId, Gid, NewId, RuneId, RuneNum, Cost, Status, About) ->
    NewGoods = case Status =:= 1 of 
                   true -> Rule#ets_equip_upgrade.new_id; 
                   false -> 0 
               end,
    Sql = io_lib:format(<<"insert into `log_equip_upgrade` set `time`=UNIX_TIMESTAMP(), `pid`=~p, `gid`=~p, `goods_id`=~p, `stuff1_id`=~p, `stuff1_num`=~p, `stuff2_id`=~p, `stuff2_num`=~p, `stuff3_id`=~p, `stuff3_num`=~p, `rune_id`=~p, `rune_num`=~p, `new_gid`=~p, `new_goods`=~p, `cost`=~p, `status`=~p, `about`='~s' ">>,
                                [PlayerId, Gid, Rule#ets_equip_upgrade.goods_id, Rule#ets_equip_upgrade.trip_id, Rule#ets_equip_upgrade.trip_num, Rule#ets_equip_upgrade.stone_id, Rule#ets_equip_upgrade.stone_num, Rule#ets_equip_upgrade.iron_id, Rule#ets_equip_upgrade.iron_num, RuneId, RuneNum, NewId, NewGoods, Cost, Status, About]),
    db:execute(Sql),
    ok.

%% 帮派公共技能激活日志
log_guild_skill_active(PlayerId, GuildId, SkillId, SkillLv, LeftMaterial) -> 
    Sql = lists:concat(["insert into `log_guild_skill_active`set `time`=UNIX_TIMESTAMP(), player_id = ", PlayerId, ", guild_id = ",GuildId,", skill_id = ",SkillId,", skill_lv = ", SkillLv, ", left_material = ", LeftMaterial]),
    db:execute(Sql),
    ok.

%% 返利日志
log_rebate(Type, Player_id, Got_gold, Got_rebate, Got_point, Remain_point, Remain_rebate, Base_rebate, Ctime, About) ->
    Sql = io_lib:format(<<"insert into `log_rebate` set `type`=~p, `player_id`=~p, `got_gold`=~p, `got_rebate`=~p, `got_point`=~p, `remain_point`=~p, `remain_rebate`=~p, `base_rebate`=~p, `ctime`=~p, `about`='~s' ">>,
                                [Type, Player_id, Got_gold, Got_rebate, Got_point, Remain_point, Remain_rebate, Base_rebate, Ctime, About ]),
    db:execute(Sql),
    ok.

%% 赠送祝福露日志
log_guild_skill_point(GiveId, RecId, GoodsTypeId, GoodsNum) -> 
    Sql = io_lib:format(<<"insert into `log_guild_skill_point` set `give_id`=~p, `rec_id`=~p, `goods_type_id`=~p, `goods_num`=~p, `time`=UNIX_TIMESTAMP()">>,[GiveId, RecId, GoodsTypeId, GoodsNum]),
    db:execute(Sql),
    ok.

%% 删除好友日志
log_friend_delete(IdA, IdB, Type) ->
    Sql = io_lib:format(<<"insert into `log_friend_delete` set `idA`=~p, `idB`=~p, `type`=~p, `time`=UNIX_TIMESTAMP()">>, [IdA, IdB, Type]),
    db:execute(Sql),
    ok.

%% 幸运转盘日志
log_lucky_box(Role_id, Goods_id) ->
    Sql = io_lib:format(<<"insert into `log_lucky_box` set `role_id`=~p, `goods_id`=~p, `time`=UNIX_TIMESTAMP()">>, [Role_id, Goods_id]),
    db:execute(Sql),
    ok.

%% 神秘商店日志
log_secret_shop(Type, Role_id, Goods_id, Goods_num) ->
    Sql = io_lib:format(<<"insert into `log_secret_shop` set `type`=~p, `role_id`=~p, `goods_id`=~p, `goods_num`=~p, `time`=UNIX_TIMESTAMP()">>,
        [Type, Role_id, Goods_id, Goods_num]),
    db:execute(Sql),
    ok.

%% 炼化日志
log_forge(PlayerId, ForgeId, GoodsTypeId, GoodsNum, Status) ->
    Sql = io_lib:format(<<"insert into `log_forge` set time=UNIX_TIMESTAMP(), pid=~p, forge_id=~p, goods_id=~p, goods_num=~p, status=~p ">>,
                                [PlayerId, ForgeId, GoodsTypeId, GoodsNum, Status]),
    db:execute(Sql),
    ok.

%% 触发到活跃度提升时写入
log_active(RoleId, RoleName, RoleLevel, ActiveId, Active) ->
	db:execute(
		io_lib:format(
			<<"INSERT INTO `log_active` SET `role_id`=~p, `role_name`='~s', `role_level`=~p, `active_id`=~p, `active`=~p, `time`=UNIX_TIMESTAMP()">>,
			[RoleId, RoleName, RoleLevel, ActiveId, Active]
		)  
	),
    ok.

%% 答题日志.
log_quiz(RoleId, Rank, Score, Exp) ->
	db:execute(
		io_lib:format(
			<<"INSERT INTO `log_quiz` SET `role_id`=~p, `rank`=~p, 
		     `score`=~p, `exp`=~p, `time`=UNIX_TIMESTAMP()">>,
			[RoleId, Rank, Score, Exp]
		)  
	),
    ok.

%% 铜币副本日志.
log_coin_dungeon(RoleId, RoleLevel, Coin, BCoin, BeginTime, LogoutType, CombatPower) ->
	db:execute(
		io_lib:format(
			<<"INSERT INTO `log_coin_dungeon` SET `role_id`=~p, 
			  `coin`=~p, `bcoin`=~p, `begin_time`=~p, 
			  `time`=UNIX_TIMESTAMP(), `role_level`=~p, 
			  `logout_type`=~p, `combat_power`=~p">>,
			[RoleId, Coin, BCoin, BeginTime, RoleLevel, LogoutType, CombatPower]
		)  
	),
    ok.

%% 宠物副本日志.
log_pet_dungeon(RoleId, RoleLevel, BeginTime, LogoutType, CombatPower) ->
	db:execute(
		io_lib:format(
			<<"INSERT INTO `log_pet_dungeon` SET `role_id`=~p, 
			  `role_level`=~p, `begin_time`=~p, `time`=UNIX_TIMESTAMP(),
			  `logout_type`=~p, `combat_power`=~p">>,
			[RoleId, RoleLevel, BeginTime, LogoutType, CombatPower]
		)  
	),
    ok.

%% 装备副本日志.
log_tower_dungeon(RoleId, RoleLevel, Type, Level, TotalTime, GoodsId, MemberIds, 
				  BeginTime, LastLayerTime, LogoutType, CombatPower) ->
	db:execute(
		io_lib:format(
			<<"INSERT INTO `log_tower_dungeon` SET `role_id`=~p, 
			  `role_level`=~p, `type`=~p, `level`=~p,
			  `total_time`=~p,`good_id`=~p, `begin_time`=~p, 
			  `last_layer_time` = ~p, `time`=UNIX_TIMESTAMP(), 
			   member_ids = '~s', `logout_type`=~p, `combat_power`=~p">>,
			[RoleId, RoleLevel, Type, Level, TotalTime, GoodsId, BeginTime, 
			 LastLayerTime, util:term_to_bitstring(MemberIds), 
			 LogoutType, CombatPower]
		)  
	),
    ok.

%% 塔防副本日志.
log_king_dungeon(RoleId, RoleLevel, Type, Level, LevelTime, MemberIds, 
				  BeginTime, LogoutType, CombatPower, Records, BuildingList) ->
	db:execute(
		io_lib:format(
			<<"INSERT INTO `log_king_dungeon` SET `role_id`=~p, 
			  `role_level`=~p, `type`=~p, `level`=~p, `level_time`=~p, 
			  `member_ids`= '~s',`begin_time`=~p, `end_time`=UNIX_TIMESTAMP(), 
			  `logout_type`=~p, `combat_power`=~p, `records`= '~s',
			  `building_list`= '~s'">>,
			[RoleId, RoleLevel, Type, Level, LevelTime, util:term_to_bitstring(MemberIds),
			 BeginTime, LogoutType, CombatPower, util:term_to_bitstring(Records),
			 util:term_to_bitstring(BuildingList)]
		)  
	),
    ok.

%% 经验副本日志.
log_exp_dungeon(RoleId, Level, IsUse, GoodsId, BeginTime, LogoutType, CombatPower) ->
	db:execute(
		io_lib:format(
			<<"INSERT INTO `log_exp_dungeon` SET `role_id`=~p,`level`=~p,
			  `is_use`=~p,`good_id`=~p, `begin_time`=~p, 
			  `time`=UNIX_TIMESTAMP(), `logout_type`=~p, `combat_power`=~p">>,
			[RoleId, Level, IsUse, GoodsId, BeginTime, LogoutType, CombatPower]
		)  
	),
    ok.

%% 连连看副本日志.
log_lian_dungeon(RoleId, RoleLevel, Score, GoodsId, BeginTime, LogoutType, CombatPower) ->
	db:execute(
		io_lib:format(
			<<"INSERT INTO `log_lian_dungeon` SET `role_id`=~p, 
			  `role_level`=~p, `score`=~p, `goods_id`=~p, 
			  `begin_time`=~p, `end_time`=UNIX_TIMESTAMP(), 
			  `logout_type`=~p, `combat_power`=~p">>,
			[RoleId, RoleLevel, Score, GoodsId, BeginTime, LogoutType, CombatPower]
		)  
	),
    ok.

%% 飞行副本日志.
log_fly_dungeon(RoleId, RoleLevel, BeginTime, LogoutType, CombatPower, 
				Score, Level, Star) ->
	db:execute(
		io_lib:format(
			<<"INSERT INTO `log_fly_dungeon` SET `role_id`=~p, 
			  `role_level`=~p, `begin_time`=~p, `end_time`=UNIX_TIMESTAMP(), 
			  `logout_type`=~p, `combat_power`=~p, `score`=~p,
			  `level`=~p,`Star`=~p">>,
			[RoleId, RoleLevel, BeginTime, LogoutType, CombatPower, Score,
			 Level, Star]
		)  
	),
    ok.

%% BOSS召唤日志.
log_call_boss(SceneName, MonId, MonName, MonColor) ->
	db:execute(
		io_lib:format(
			<<"INSERT INTO `log_call_boss` SET `scene_name`='~s',`mon_id`=~p,
			  `mon_name`='~s',`mon_color`=~p,`time`=UNIX_TIMESTAMP()">>,
			[SceneName, MonId, MonName, MonColor]
		)  
	),
    ok.

%% 注灵日志
log_reiki(PlayerStatus, GoodsInfo, Llpt, Type, Status, OldLevel, NewLevel,
    OldQi, NewQi, Times, Att, Attribute, Gold) ->
    Sql = io_lib:format(<<"insert into log_reiki set pid=~p, goods_id=~p,
        type=~p,old_level=~p, level=~p, old_qi_level=~p, qi_level=~p,
        times=~p, att='~s', attribute='~s', llpt=~p, gold=~p, status=~p,`time`=UNIX_TIMESTAMP()">>,
        [PlayerStatus#player_status.id, GoodsInfo#goods.goods_id, Type, OldLevel, NewLevel,
    OldQi, NewQi, Times, Att, Attribute, Llpt, Gold, Status]),
    db:execute(Sql),
    ok.

%% 帮派升级
log_guild_upgrade(Id, Level, OldLevel) ->
    Sql = io_lib:format(
		<<"insert into log_guild_upgrade set guild_id=~p, level=~p, old_level=~p, time=UNIX_TIMESTAMP()">>,
        [Id, Level, OldLevel]
	),
    db:execute(Sql),
    ok.

%% 使用元宝道具
log_gold_goods(Id, GoodsId, Gold) ->
    Sql = io_lib:format(
		<<"insert into log_gold_goods set id=~p, gold=~p, goods_id=~p, time=UNIX_TIMESTAMP()">>,
        [Id, GoodsId, Gold]
	),
    db:execute(Sql),
    ok.

%% 幸运转盘日志
log_table(Id, GoodsId, GoodsTypeId) ->
    Sql = io_lib:format(<<"insert into log_table set pid=~p, goods_id=~p, get_type=~p, time=UNIX_TIMESTAMP()">>, [Id, GoodsId, GoodsTypeId]),
    db:execute(Sql),
    ok.

log_mount_discard(Pid, Mount) ->
    Sql = io_lib:format(<<"insert into log_mount_discard set time=UNIX_TIMESTAMP(), role_id=~p, mount_id=~p, type_id=~p, figure=~p, stren=~p, power=~p">>, [Pid, Mount#ets_mount.id, Mount#ets_mount.type_id, Mount#ets_mount.figure, Mount#ets_mount.stren, Mount#ets_mount.combat_power]),
    db:execute(Sql),
    ok.

log_temp_bag(Pid, GoodsTypeId, Num, Prefix, Stren, Bind) ->
    Sql = io_lib:format(<<"insert into log_temp_bag set time=UNIX_TIMESTAMP(), pid=~p, goods_id=~p, num=~p, prefix=~p, stren=~p, bind=~p">>, [Pid, GoodsTypeId, Num, Prefix, Stren, Bind]),
    db:execute(Sql),
    ok.
