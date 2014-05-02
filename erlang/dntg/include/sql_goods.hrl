%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2011-12-13
%% Description: 物品装备SQL定义
%% --------------------------------------------------------

-define(SQL_MON_DROP_COUNTER,       <<"select mon_id,drop_num,drop_time,mon_num,mon_time from `mon_drop_counter` ">>).
-define(SQL_GOODS_DROP_NUM,         <<"select goods_id,goods_num from `base_goods_drop_num` ">>).

-define(SQL_LAST_INSERT_ID,         <<"SELECT LAST_INSERT_ID() ">>).
-define(SQL_GOODS_INSERT,           <<"insert into `goods` set player_id=~p, type=~p, subtype=~p, price_type=~p, price=~p, sell_price=~p, vitality=~p, spirit=~p, hp=~p, mp=~p, forza=~p, agile=~p, wit=~p, att=~p, def=~p, hit=~p, dodge=~p, crit=~p, ten=~p, speed=~p, suit_id=~p, skill_id=~p, expire_time=~p, create_time=UNIX_TIMESTAMP() ">>).
-define(SQL_GOODS_LOW_INSERT,       <<"insert into `goods_low` set gid=~p, pid=~p, gtype_id=~p, equip_type=~p, bind=~p, trade=~p, sell=~p, isdrop=~p, level=~p, stren=~p, stren_ratio=~p, hole=~p, hole1_goods=~p, hole2_goods=~p, hole3_goods=~p, color=~p, addition_1='~s', addition_2 = '~s', addition_3 = '~s', first_prefix=~p, prefix=~p, min_star=~p, wash_time=~p, note='~s', ice=~p, fire=~p, drug=~p ">>).
-define(SQL_GOODS_HIGHT_INSERT,     <<"insert into `goods_high` set gid=~p, pid=~p, goods_id=~p, guild_id=~p, attrition=~p, use_num=~p, location=~p, cell=~p, num=~p ">>).
-define(SQL_GOODS_HIGHT_COUNT,      <<"select count(gid) from `goods_high` where pid = ~p and location = ~p ">>).

-define(SQL_GOODS_SELECT_BY_ID,     <<"select id, player_id, guild_id, goods_id, type, subtype, equip_type, price_type, price, sell_price, bind, trade, sell, isdrop, level, vitality, spirit, hp, mp, forza, agile, wit, att, def, hit, dodge, crit, ten, speed, attrition, use_num, suit_id, skill_id, stren, stren_ratio, hole, hole1_goods, hole2_goods, hole3_goods, addition_1, addition_2, addition_3, location, cell, num, color, expire_time, first_prefix, prefix, min_star, wash_time, note, ice, fire, drug from `goods` left join `goods_low` gl on id=gl.gid left join `goods_high` gh on id=gh.gid where id=~p ">>).

-define(SQL_GOODS_LIST_BY_LOCATION, <<"select id, player_id, guild_id, goods_id, type, subtype, equip_type, price_type, price, sell_price, bind, trade, sell, isdrop, level, vitality, spirit, hp, mp, forza, agile, wit, att, def, hit, dodge, crit, ten, speed, attrition, use_num, suit_id, skill_id, stren, stren_ratio, hole, hole1_goods, hole2_goods, hole3_goods, addition_1, addition_2, addition_3, location, cell, num, color, expire_time, first_prefix, prefix, min_star, wash_time,note, ice, fire, drug from `goods_high` gh left join `goods_low` gl on gh.gid=gl.gid left join `goods` g on gh.gid=g.id where gh.pid = ~p and location = ~p ">>).
-define(SQL_GOODS_LIST_BY_LOCATION2,<<"select id, player_id, guild_id, goods_id, type, subtype, equip_type, price_type, price, sell_price, bind, trade, sell, isdrop, level, vitality, spirit, hp, mp, forza, agile, wit, att, def, hit, dodge, crit, ten, speed, attrition, use_num, suit_id, skill_id, stren, stren_ratio, hole, hole1_goods, hole2_goods, hole3_goods, addition_1,addition_2,addition_3, location, cell, num, color, expire_time, first_prefix, prefix, min_star, wash_time, note, ice, fire, drug from `goods_high` gh left join `goods_low` gl on gh.gid=gl.gid left join `goods` g on gh.gid=g.id where location = ~p ">>).
-define(SQL_GOODS_LIST_BY_TYPE1,    <<"select id, player_id, guild_id, goods_id, type, subtype, equip_type, price_type, price, sell_price, bind, trade, sell, isdrop, level, vitality, spirit, hp, mp, forza, agile, wit, att, def, hit, dodge, crit, ten, speed, attrition, use_num, suit_id, skill_id, stren, stren_ratio, hole, hole1_goods, hole2_goods, hole3_goods, addition_1,addition_2,addition_3, location, cell, num, color, expire_time, first_prefix, prefix, min_star, wash_time, note, ice, fire, drug from `goods_high` gh left join `goods_low` gl on gh.gid=gl.gid left join `goods` g on gh.gid=g.id where gh.pid = ~p and location = ~p and goods_id = ~p and bind = ~p ">>).
-define(SQL_GOODS_LIST_BY_TYPE2,    <<"select id, player_id, guild_id, goods_id, type, subtype, equip_type, price_type, price, sell_price, bind, trade, sell, isdrop, level, vitality, spirit, hp, mp, forza, agile, wit, att, def, hit, dodge, crit, ten, speed, attrition, use_num, suit_id, skill_id, stren, stren_ratio, hole, hole1_goods, hole2_goods, hole3_goods, addition_1,addition_2,addition_3, location, cell, num, color, expire_time, first_prefix, prefix, min_star, wash_time, note, ice, fire, drug from `goods_high` gh left join `goods_low` gl on gh.gid=gl.gid left join `goods` g on gh.gid=g.id where gh.pid = ~p and location = ~p and goods_id = ~p ">>).
-define(SQL_GOODS_LIST_BY_SELL,     <<"select id, player_id, guild_id, goods_id, type, subtype, equip_type, price_type, price, sell_price, bind, trade, sell, isdrop, level, vitality, spirit, hp, mp, forza, agile, wit, att, def, hit, dodge, crit, ten, speed, attrition, use_num, suit_id, skill_id, stren, stren_ratio, hole, hole1_goods, hole2_goods, hole3_goods, addition_1, addition_2, addition_3, location, cell, num, color, expire_time, first_prefix, prefix, min_star, wash_time, note, ice, fire, drug from `goods_high` gh left join `goods_low` gl on gh.gid=gl.gid left join `goods` g on gh.gid=g.id where gh.location = ~p and g.type=~p ">>).
-define(SQL_GOODS_LIST_BY_GUILD,    <<"select id, player_id, guild_id, goods_id, type, subtype, equip_type, price_type, price, sell_price, bind, trade, sell, isdrop, level, vitality, spirit, hp, mp, forza, agile, wit, att, def, hit, dodge, crit, ten, speed, attrition, use_num, suit_id, skill_id, stren, stren_ratio, hole, hole1_goods, hole2_goods, hole3_goods, addition_1,addition_2,addition_3, location, cell, num, color, expire_time, first_prefix, prefix, min_star, wash_time, note, ice, fire, drug from `goods_high` gh left join `goods_low` gl on gh.gid=gl.gid left join `goods` g on gh.gid=g.id where gh.guild_id = ~p ">>).
-define(SQL_GOODS_LIST_BY_EXPIRE,   <<"select g.id,gh.goods_id,gh.num,gh.location,gl.first_prefix,gl.prefix,gl.stren,g.type,gl.equip_type from `goods` g left join `goods_high` gh on g.id=gh.gid left join `goods_low` gl on g.id=gl.gid where g.player_id = ~p and g.expire_time > 0 and g.expire_time <= ~p ">>).
-define(SQL_STORAGE_LIST_BY_GUILD,  <<"select gid, cell, num from `goods_high` where guild_id = ~p and goods_id = ~p and num < ~p for update ">>).
-define(SQL_STORAGE_LIST_BY_TYPE,   <<"select gh.gid, gh.cell, gh.num from `goods_high` gh left join `goods_low` gl on gh.gid=gl.gid where  gh.pid = ~p and gh.location = ~p and gh.goods_id = ~p and gl.bind = ~p and gh.num < ~p ">>).
-define(SQL_STORAGE_LIST_BY_GID,    <<"select pid, guild_id, num from `goods_high` where gid = ~p for update ">>).
-define(SQL_STORAGE_TYPE_COUNT1,    <<"select sum(num) from `goods_high` where guild_id = ~p and goods_id = ~p ">>).
-define(SQL_STORAGE_TYPE_COUNT2,    <<"select sum(gh.num) from `goods_high` gh left join `goods_low` gl on gh.gid=gl.gid  where gh.pid = ~p and gh.location = ~p and gh.goods_id = ~p and gl.bind = ~p ">>).
-define(SQL_STORAGE_COUNT1,         <<"select count(gid) from `goods_high` where guild_id = ~p ">>).
-define(SQL_STORAGE_COUNT2,         <<"select count(gid) from `goods_high` where pid = ~p and location = ~p ">>).

-define(SQL_GOODS_UPDATE_NUM,       <<"update `goods_high` set num = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_CELL,      <<"update `goods_high` set location = ~p, cell = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_CELL_NUM,  <<"update `goods_high` set location = ~p, cell = ~p, num = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_CELL_USENUM,<<"update `goods_high` set location = ~p, cell = ~p, use_num = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_USENUM,    <<"update `goods_high` set use_num = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_ATTRITION1,<<"update `goods_high` set use_num = use_num - (~p) where pid = ~p and location = ~p and use_num > ~p and attrition > 0 ">>).
-define(SQL_GOODS_UPDATE_ATTRITION2,<<"update `goods_high` set use_num = 0 where pid = ~p and location = ~p and use_num <= ~p and use_num > 0 and attrition > 0 ">>).
-define(SQL_GOODS_UPDATE_BIND,      <<"update `goods_low` set bind = 2, trade = 1 where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_QUALITY,   <<"update `goods_low` set prefix=~p, bind=~p, trade = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_QUALITY_FIRST_PREFIX,   <<"update `goods_low` set first_prefix=~p, color=~p, bind=~p, trade = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_QUALITY_PREFIX,   <<"update `goods_low` set prefix=~p, bind=~p, trade = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_STREN,     <<"update `goods_low` set stren = ~p, stren_ratio = ~p, bind = ~p, trade = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_EXPIRE,    <<"update `goods` set expire_time = ~p where id = ~p ">>).
-define(SQL_GOODS_UPDATE_HOLE1,     <<"update `goods_low` set hole = ~p, bind = ~p, trade = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_HOLE2,     <<"update `goods_low` set hole1_goods = ~p, hole2_goods = ~p, hole3_goods = ~p, bind = ~p, trade = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_ADDITION_1,  <<"update `goods_low` set addition_1='~s', bind = ~p, trade = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_ADDITION_2,  <<"update `goods_low` set addition_2='~s', bind = ~p, trade = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_ADDITION_3,  <<"update `goods_low` set addition_3='~s', bind = ~p, trade = ~p where gid = ~p ">>).

-define(SQL_GOODS_UPDATE_INFO,      <<"update `goods_low` set bind = ~p, trade = ~p, wash_time = ~p, min_star = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_ATTR1,      <<"update `goods_low` set addition_1=~p where gid=~p">>).
-define(SQL_GOODS_UPDATE_ATTR2,      <<"update `goods_low` set addition_2=~p where gid=~p">>).
-define(SQL_GOODS_UPDATE_ATTR3,      <<"update `goods_low` set addition_3=~p where gid=~p">>).

-define(SQL_GOODS_UPDATE_GUILD2,    <<"update `goods_low` set pid = ~p, bind = ~p, trade = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_GUILD3,     <<"update `goods_high` set pid = ~p, guild_id = ~p, location = ~p, cell = ~p, num = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_PLAYER1,   <<"update `goods` set player_id = ~p where id = ~p ">>).
-define(SQL_GOODS_UPDATE_PLAYER2,   <<"update `goods_low` set pid = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_PLAYER3,   <<"update `goods_high` set pid = ~p, location = ~p, cell = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_GOODS1,    <<"update `goods_high` set goods_id = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_GOODS2,    <<"update `goods_low` set gtype_id = ~p, color = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_GOODS3,    <<"update `goods_low` set gtype_id = ~p, bind = ~p, trade = ~p where gid = ~p ">>).
-define(SQL_GOODS_UPDATE_SOUL,      <<"update `goods_low` set `soul`='~s', `bind` = ~p, `trade` = ~p where `gid` = ~p ">>).
-define(SQL_GOODS_DELETE_BY_ID,                 <<"delete `goods_high`,`goods_low`,`goods` from `goods_high`,`goods_low`,`goods` where `goods_high`.gid=`goods_low`.gid and `goods_high`.gid=`goods`.id and `goods_high`.gid = ~p">>).
-define(SQL_GOODS_DELETE_BY_PLAYER,             <<"delete `goods_high`,`goods_low`,`goods` from `goods_high`,`goods_low`,`goods` where `goods_high`.gid=`goods_low`.gid and `goods_high`.gid=`goods`.id and `goods_high`.pid = ~p">>).
-define(SQL_GOODS_DELETE_BY_LOCATION,           <<"delete `goods_high`,`goods_low`,`goods` from `goods_high`,`goods_low`,`goods` where `goods_high`.gid=`goods_low`.gid and `goods_high`.gid=`goods`.id and `goods_high`.pid = ~p and `goods_high`.location = ~p ">>).
-define(SQL_GOODS_DELETE_BY_GUILD,              <<"delete `goods_high`,`goods_low`,`goods` from `goods_high`,`goods_low`,`goods` where `goods_high`.gid=`goods_low`.gid and `goods_high`.gid=`goods`.id and `goods_high`.guild_id = ~p">>).

-define(SQL_PLAYER_UPDATE_MONEY,                <<"update `player_high` set `coin`=~p, `bgold`=~p, `gold`=~p, `bcoin`=~p where `id`=~p">>).
-define(SQL_PLAYER_UPDATE_POINT,				<<"update `player_low` set `point`=~p where `id`=~p">>).				
-define(SQL_PLAYER_UPDATE_CELL,                 <<"update `player_attr` set cell_num=~p where id=~p">>).
-define(SQL_PLAYER_UPDATE_STORAGE_NUM,          <<"update `player_attr` set storage_num=~p where id=~p">>).

%% gift_list 
-define(SQL_GIFT_QUEUE_INSERT,                  <<"insert into `gift_list` set player_id=~p, gift_id=~p, give_time=~p, status=~p ">>).
-define(SQL_GIFT_QUEUE_INSERT_FULL,             <<"insert into `gift_list` set player_id=~p, gift_id=~p, give_time=~p, get_num=~p, get_time=~p, status=~p ">>).
-define(SQL_GIFT_QUEUE_UPDATE_GIVE,             <<"update `gift_list` set give_time=~p, get_time=0, status=~p where player_id=~p and gift_id=~p ">>).
-define(SQL_GIFT_QUEUE_UPDATE_GET,              <<"update `gift_list` set get_num=get_num+1, get_time=~p, status=1 where player_id=~p and gift_id=~p ">>).
-define(SQL_GIFT_QUEUE_UPDATE_OFFLINE,          <<"update `gift_list` set offline_time=~p where player_id=~p and gift_id=~p ">>).
-define(SQL_GIFT_QUEUE_SELECT,                  <<"select gift_id, give_time from `gift_list` where player_id=~p and gift_id=~p limit 1 ">>).
-define(SQL_GIFT_QUEUE_SELECT_ONLINE,           <<"select gift_id, give_time, offline_time from `gift_list` where player_id=~p and status=0 limit 1 ">>).
-define(SQL_GIFT_QUEUE_SELECT_GOT,              <<"select gift_id from `gift_list` where player_id=~p and status=1 ">>).
-define(SQL_GIFT_QUEUE_DELETE,                  <<"delete from `gift_list` where player_id=~p ">>).

%% gift_card
-define(SQL_GIFT_CARD_INSERT,                   <<"insert into `gift_card` set player_id=~p, card_no='~s', type=~p, time=~p, status=1 ">>).
-define(SQL_GIFT_CARD_SELECT,                   <<"select status from `gift_card` where card_no='~s' ">>).
-define(SQL_GIFT_CARD_BASE_SELECT,              <<"select card_no from `base_gift_card` where accname='~s' limit 1 ">>).

%% gift2_card 
-define(SQL_GIFT2_SELECT,                       <<"select id, name, url, bind, lv, coin, bcoin, gold, silver, goods_list, is_show, time_start, time_end, status from `base_gift2` where status=1 ">>).
-define(SQL_GIFT2_CARD_SELECT,                  <<"select status from `gift2_card` where card_no='~s' and gift_id=~p ">>).
-define(SQL_GIFT2_CARD_UPDATE,                  <<"update `gift2_card` set player_id=~p, time=UNIX_TIMESTAMP(), status=1 where card_no='~s' ">>).

%% mon_drop_counter
-define(SQL_CHARGE_SELECT,                      <<"select id from `charge` where player_id=~p and status=1 limit 1 ">>).
-define(SQL_DROP_COUNTER_SELECT,                <<"select mon_id,drop_num,drop_time,mon_num,mon_time from `mon_drop_counter` where mon_id = ~p ">>).
-define(SQL_DROP_COUNTER_INSERT,                <<"insert into `mon_drop_counter` set mon_id=~p, drop_num=~p, drop_time=~p, mon_num=~p, mon_time=~p ">>).
-define(SQL_DROP_COUNTER_UPDATE,                <<"update `mon_drop_counter` set drop_num=~p, drop_time=~p, mon_num=~p, mon_time=~p where mon_id=~p ">>).

%% mon_goods_counter
-define(SQL_MON_GOODS_COUNTER_SELECT,           <<"select goods_id,goods_num,drop_num,time from `mon_goods_counter` ">>).
-define(SQL_MON_GOODS_COUNTER_INSERT,           <<"insert into `mon_goods_counter` set goods_id=~p, goods_num=~p, drop_num=~p, time=~p ">>).
-define(SQL_MON_GOODS_COUNTER_UPDATE1,          <<"update `mon_goods_counter` set goods_num=~p where goods_id=~p ">>).
-define(SQL_MON_GOODS_COUNTER_UPDATE2,          <<"update `mon_goods_counter` set drop_num=~p, time=~p where goods_id=~p ">>).
-define(SQL_MON_GOODS_COUNTER_DELETE,           <<"delete from `mon_goods_counter` where goods_id=~p ">>).

-define(SQL_SELL_SELECT,                        <<"select id, class1, class2, gid, pid, nickname, accname, goods_id, goods_name, num, type, subtype, lv, lv_num, color, career, price_type, price, time, end_time, is_expire, expire_time from `sell_list` ">>).
-define(SQL_SELL_SELECT_ID,                     <<"select id, class1, class2, gid, pid, nickname, accname, goods_id, goods_name, num, type, subtype, lv, lv_num, color, career, price_type, price, time, end_time, is_expire, expire_time from `sell_list` where id=~p ">>).
-define(SQL_SELL_SELECT_ID2,                    <<"select id from `sell_list` where id=~p for update ">>).
-define(SQL_SELL_SELECT_PLAYER,                 <<"select id, class1, class2, gid, pid, nickname, accname, goods_id, goods_name, num, type, subtype, lv, lv_num, color, career, price_type, price, time, end_time, is_expire, expire_time from `sell_list` where pid=~p ">>).

%% sell
-define(SQL_SELL_INSERT,                        <<"insert into `sell_list` set class1=~p, class2=~p, gid=~p, pid=~p, nickname='~s', accname='~s', goods_id=~p, goods_name='~s', num=~p, type=~p, subtype=~p, lv=~p, lv_num=~p, color=~p, career=~p, price_type=~p, price=~p, time=~p, end_time=~p ">>).
-define(SQL_SELL_DELETE,                        <<"delete from `sell_list` where id=~p ">>).
-define(SQL_SELL_DELETE_PLAYER,                 <<"delete from `sell_list` where pid=~p ">>).
-define(SQL_SELL_DELETE_GID,                    <<"delete from `sell_list` where gid > 0 and gid=~p ">>).

-define(SQL_DROP_FACTOR_SELECT,                 <<"select id, drop_factor, drop_factor_list, time from `drop_factor` where id=1 ">>).

%% 得到玩家身上的武器.
-define(SQL_GOODS_GET_WEAPON,      <<"select goods_id from `goods` left join `goods_high` gh on id=gh.gid where player_id=~p and type=10 and subtype=10 and location=1">>).
%% 得到玩家身上的衣服.
-define(SQL_GOODS_GET_ARMOR,      <<"select goods_id from `goods` left join `goods_high` gh on id=gh.gid where player_id=~p and type=10 and subtype=21 and location=1">>).
%% 得到玩家身上的时装武器.
-define(SQL_GOODS_GET_FASHION_WEAPON,      <<"select goods_id from `goods` left join `goods_high` gh on id=gh.gid where player_id=~p and type=10 and subtype=61 and location=1">>).
%% 得到玩家身上的时装衣服.
-define(SQL_GOODS_GET_FASHION_ARMOR,      <<"select goods_id from `goods` left join `goods_high` gh on id=gh.gid where player_id=~p and type=10 and subtype=60 and location=1">>).
%% 得到玩家身上的时装饰品.
-define(SQL_GOODS_GET_FASHION_ACCESSORY,      <<"select goods_id from `goods` left join `goods_high` gh on id=gh.gid where player_id=~p and type=10 and subtype=62 and location=1">>).
