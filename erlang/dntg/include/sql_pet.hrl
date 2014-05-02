%%%------------------------------------------------
%%% File    : sql_pet.hrl
%%% Author  : zhenghehe
%%% Created : 2012-01-17
%%% Description: 宠物系统sql文件
%%%------------------------------------------------
%%=========================================================================
%% SQL定义
%%=========================================================================

%% -----------------------------------------------------------------
%% 角色表SQL
%% -----------------------------------------------------------------
-define(SQL_PLAYER_HIGH_UPDATE_COIN_BOTH,                "update player_high set coin=~p,bcoin=~p where id=~p").
-define(SQL_PLAYER_HIGH_UPDATE_GOLD_COIN,                "update player_high set gold=~p,coin=~p,bcoin=~p where id=~p").
-define(SQL_PLAYER_PET_UPDATE_PET_CAPACITY,              "update player_pet set pet_capacity=~p where id=~p").
-define(SQL_PLAYER_PET_UPDATE_PET_CAPTURE,               "update player_pet set pet_capture_num=~p, pet_capture_lasttime=~p where id=~p").
-define(SQL_PLAYER_PET_UPDATE_PET_RENAME,                "update player_pet set pet_rename_num=~p, pet_rename_lasttime=~p where id=~p").
-define(SQL_PLAYER_HIGH_UPDATE_GOLD,                     "update player_high set gold=~p where id=~p").

%% -----------------------------------------------------------------
%% 宠物表SQL
%% -----------------------------------------------------------------
-define(SQL_PET_INSERT,                                "insert into pet(player_id,type_id,figure,nimbus,name,forza, wit, agile, thew, quality,base_aptitude,extra_aptitude,extra_aptitude_max,level,strength,growth,growth_exp,maxinum_growth,forza_scale, wit_scale , agile_scale, thew_scale, create_time, combat_power) values(~p,~p,~p,~p,'~s',~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p, ~p)").
-define(SQL_PET_SELECT_ALL,                            "select id,name,player_id,type_id,figure,new_figure,change_flag,figure_type,figure_expire_time,level,base_aptitude,extra_aptitude,extra_aptitude_max,quality,forza,wit,agile,thew,growth,growth_exp,maxinum_growth,strength,fight_flag,upgrade_exp,create_time,forza_scale, wit_scale , agile_scale, thew_scale, last_forza_scale, last_wit_scale , last_agile_scale, last_thew_scale, combat_power,nimbus from pet where player_id=~p").
-define(SQL_PET_SELECT_INCUBATE_PET,                   "select id,name,player_id,type_id,figure,new_figure,change_flag,figure_type,figure_expire_time,level,base_aptitude,extra_aptitude,extra_aptitude_max,quality,forza,wit,agile,thew,growth,growth_exp,maxinum_growth,strength,fight_flag,upgrade_exp,create_time,forza_scale, wit_scale , agile_scale, thew_scale, last_forza_scale, last_wit_scale , last_agile_scale, last_thew_scale, combat_power,nimbus from pet where player_id=~p and type_id=~p and create_time=~p order by id desc limit 1").
-define(SQL_PET_SELECT_SHOW_INFO,                      "select id,name,level,quality,forza,wit,agile,thew,base_aptitude, extra_base_aptitude, figure,nimbus,extra_aptitude_max,growth from pet where id=~p").

-define(SQL_PET_UPDATE_SCALE,                          "update pet set forza_scale=~p, wit_scale=~p, agile_scale=~p, thew_scale=~p where id=~p").
-define(SQL_PET_UPDATE_LAST_SCALE,                     "update pet set last_forza_scale=~p, last_wit_scale=~p, last_agile_scale=~p, last_thew_scale=~p where id=~p").         
-define(SQL_PET_UPDATE_INIT,                           "update pet set figure=~p, origin_figure=~p, figure_change_flag=~p, figure_change_lefttime=~p where id=~p").
-define(SQL_PET_UPDATE_RENAME_INFO,                    "update pet set name = '~s' where id = ~p").
-define(SQL_PET_UPDATE_FIGHT,                          "update pet set fight_flag=~p where id = ~p").
-define(SQL_PET_UPDATE_REST,                           "update pet set fight_flag=~p, upgrade_exp=~p where id = ~p").
-define(SQL_PET_UPDATE_UPGRADE,                        "update pet set level=~p, upgrade_exp=~p,forza=~p,wit=~p,agile=~p,thew=~p,combat_power=~p where id=~p").
-define(SQL_PET_UPDATE_UPGRADE_EXP,                    "update pet set upgrade_exp=~p where id=~p").
-define(SQL_PET_UPDATE_STRENGTH,                       "update pet set strength=~p where id=~p").
-define(SQL_PET_UPDATE_ZERO_STRENGTH,                  "update pet set strength=~p, fight_flag=~p where id=~p").
-define(SQL_PET_UPDATE_APTITUDE,                       "update pet set aptitude=~p, quality=~p where id=~p").
-define(SQL_PET_UPDATE_UNALLOC_ATTR,                   "update pet set forza=~p,wit=~p,agile=~p,thew=~p,unalloc_attr=~p where id=~p").
-define(SQL_PET_UPDATE_CHANGE_FIGURE,                  "update pet set figure=~p, origin_figure=~p, figure_change_flag=~p, figure_change_lefttime=~p where id=~p").
-define(SQL_PET_UPDATE_LOGOUT,                         "update pet set fight_flag=~p, strength=~p, new_figure=~p, upgrade_exp=~p, combat_power=~p where id=~p").
-define(SQL_PET_UPDATE_DERIVE,                         "update pet set forza=~p, wit=~p, agile=~p, thew=~p, base_aptitude=~p, extra_aptitude = ~p, extra_aptitude_max=~p, quality=~p, growth=~p, growth_exp=~p, maxinum_growth=~p, level=~p where id=~p").
-define(SQL_PET_UPDATE_APTITUDE_THRESHOLD,             "update pet set aptitude_threshold=~p where id=~p").
-define(SQL_PET_UPDATE_GROWTH,                         "update pet set growth=~p where id=~p").
-define(SQL_PET_UPDATE_GROWTHEXP,                      "update pet set growth_exp=~p where id=~p").
%% -define(SQL_PET_UPDATE_GROWTH_EXP,                     "update pet set growth=~p, growth_exp=~p where id=~p").
-define(SQL_PET_UPDATE_UPGRADE_GROWTH,                 "update pet set forza=~p,wit=~p,agile=~p,thew=~p,forza_scale=~p,wit_scale=~p,agile_scale=~p,thew_scale=~p,growth=~p, growth_exp=~p, new_figure=~p, nimbus=~p, extra_aptitude_max = ~p where id=~p").
-define(SQL_PET_UPDATE_GROWTH_FIGURE_NIMBUS,           "update pet set growth=~p, figure=~p, nimbus=~p where id=~p").
-define(SQL_PET_DELETE,                                "delete from pet where id = ~p").
-define(SQL_PET_DELETE_ROLE,                           "delete from pet where player_id = ~p").

%% -----------------------------------------------------------------
%% 宠物物品配置表SQL
%% -----------------------------------------------------------------
-define(SQL_BASE_GOODS_PET_SELECT_ALL,                 "select a.id,a.name,a.aptitude_min,a.aptitude_max,a.growth_min,a.growth_max,a.effect,a.probability,a.sell,b.type,b.subtype,b.color,b.price,b.level,b.expire_time from base_goods_pet a join base_goods b on a.id=b.goods_id").

%% -----------------------------------------------------------------
%% 宠物日志表SQL
%% -----------------------------------------------------------------
-define(SQL_LOG_PET_INSERT,                            "insert into log_pet(player_id,pet_id,time,type,status,info) values(~p,~p,~p,~p,~p,'~s')").
-define(SQL_LOG_PET_INSERT_INCUBATE,                   "insert into log_pet_incubate(player_id,egg_id,pet_id,aptitude,time) values(~p,~p,~p,~p,~p)").
-define(SQL_LOG_PET_INSERT_SKILL,                      "insert into log_pet_skill(player_id,pet_id,skill_book_id,is_replace,old_skill,new_skill,time,locklist,ps) values(~p,~p,~p,~p,'~s','~s',~p,'~s','~s')").
-define(SQL_LOG_PET_INSERT_POTENTIAL,                  "insert into log_pet_potential(player_id,pet_id,practice_type,potential_id,exp_ratio,old_exp,new_exp,old_lv,new_lv,time) values(~p,~p,'~s',~p,~p,~p,~p,~p,~p,~p)").
-define(SQL_LOG_PET_INSERT_GROWTH,                     "insert into log_pet_growth(player_id,pet_id,grow_type,exp_ratio,old_exp,new_exp,old_growth,new_growth,time) values(~p,~p,~p,~p,~p,~p,~p,~p,~p)").
-define(SQL_LOG_PET_INSERT_DERIVE,                     "insert into log_pet_derive(player_id,pri_pet_id,pri_pet_name,pri_pet_info,sec_pet_id,sec_pet_name,sec_pet_info,derive_pet_info,time) values(~p,~p,'~s','~s',~p,'~s','~s','~s',~p)").
-define(SQL_LOG_PET_DELETE,                            "delete from log_pet where time <= ~p").

%% -----------------------------------------------------------------
%% 宠物潜能表SQL
%% -----------------------------------------------------------------
-define(SQL_PET_POTENTIAL_INSERT,                      "replace into pet_potential(pet_id,location,potential_type_id,lv,exp,create_time,name) values(~p,~p,~p,~p,~p,~p,'~s')").
-define(SQL_PET_POTENTIAL_DERIVE,                      "insert into pet_potential(pet_id,location,potential_type_id,lv,exp,create_time,name) values(~p,~p,~p,~p,~p,~p,'~s')").                                                   
-define(SQL_PET_POTENTIAL_SELECT_ALL,                  "select pet_id,location,potential_type_id,lv,exp,create_time,name from pet_potential where pet_id=~p").
-define(SQL_PET_POTENTIAL_SELECT_ONE,                  "select pet_id,location,potential_type_id,lv,exp,create_time,name from pet_potential where pet_id=~p and potential_type_id=~p and create_time=~p limit 1").

-define(SQL_PET_POTENTIAL_DELETE,                      "delete from pet_potential where pet_id = ~p").
-define(SQL_PET_POTENTIAL_UPDATE_LV_EXP,               "update pet_potential set lv = ~p, exp = ~p where pet_id = ~p and potential_type_id = ~p").       
-define(SQL_PET_POTENTIAL_UPDATE_EXP,                  "update pet_potential set exp = ~p where pet_id = ~p and potential_type_id = ~p").
%% -----------------------------------------------------------------
%% 宠物技能表SQL
%% -----------------------------------------------------------------
-define(SQL_PET_SKILL_INSERT,                          "insert into pet_skill(pet_id,type_id,type, level) values(~p,~p,~p,~p)").
-define(SQL_PET_SKILL_SELECT_NEW,                      "select id,pet_id,type_id,type, level from pet_skill where pet_id=~p and type_id=~p").
-define(SQL_PET_SKILL_DELETE_FORGET_SKILL,             "delete from pet_skill where pet_id=~p and type_id=~p").
-define(SQL_PET_SKILL_SELECT_ONE_PET,                  "select id,pet_id,type_id,type, level from pet_skill where pet_id=~p").
-define(SQL_PET_SKILL_DELETE,                          "delete from pet_skill where pet_id = ~p").
%% -define(SQL_PET_SKILL_UPDATE_DERIVE,                   "update pet_skill set pet_id=~p where pet_id=~p and id=~p").

%% -----------------------------------------------------------------
%% 宠物砸蛋SQL
%% -----------------------------------------------------------------
-define(SQL_RE_PET_EGG,                      
        <<"REPLACE INTO log_pet_egg(role_id, egg_cd, get_good, time) VALUES (~p,'~s','~s',~p)">>).
-define(SQL_IN_PET_EGG,                      
        <<"INSERT INTO log_pet_egg(role_id, egg_cd, get_good, time) VALUES (~p,'~s','~s',~p)">>).
-define(SQL_SE_PET_EGG_BY_ROLE,
        <<"SELECT role_id, egg_cd, get_good, time FROM log_pet_egg WHERE role_id=~p">>).
-define(SQL_UP_PET_EGG_BY_ROLE,
        <<"UPDATE log_pet_egg SET egg_cd = '~s', get_good = '~s', time = ~p WHERE role_id=~p">>).



