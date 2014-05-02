%%%------------------------------------------------
%%% File    : lang_login.hrl
%%% Author  : xyao
%%% @Email  : jiexiaowen@gmail.com
%%% Created : 2011-12-07
%%% Description: 角色系统sql文件
%%%------------------------------------------------

%% 设置在线状态 
-define(set_role_online,<<"update `player_login`  set `online_flag` = 0">>).

%% 根据角色名称查找ID
-define(sql_role_id_by_name,<<"select id from player_low where nickname = '~s' limit 1">>).

%% 根据id查找账户名称
-define(sql_role_accname_by_id,<<"select accname from player_login where id = ~p limit 1">>).

%% 根据账户名称查找ID
-define(sql_role_id_by_accname,<<"select id from player_login where accname = '~s' limit 1">>).


%% 根据账户名称查找角色个数
-define(sql_role_any_id_by_accname,<<"select id from player_login where accname = '~s'">>).

%% 获取玩家最高等级
-define(sql_role_max_lv,<<"select max(lv) from player_low">>).

%% 获取player_login登陆所需数据
-define(sql_player_login_data,<<"select `accname`, `gm`, `talk_lim`, `talk_lim_time`,last_logout_time,offline_time, `talk_lim_right` from `player_login` where id=~p limit 1">>).

%%更新离线时间
-define(sql_player_update_login_data_offline_time,<<"update player_login set offline_time=~p,last_logout_time=~p where id=~p">>).

%%更新离线时间
-define(sql_player_update_login_data_last_logout_time,<<"update player_login set last_logout_time=~p where id=~p">>).

%% 获取player_high登陆所需数据
-define(sql_player_high_data,<<"select `gold`, `bgold`, `coin`, `bcoin`, `exp` from `player_high` where id=~p limit 1">>).

%% 获取player_low登陆所需数据
-define(sql_player_low_data,<<"select `nickname`, `sex`, `lv`, `career`,  `realm`, `guild_id`, `mount_limit`, 
    `husong_npc`, `image`,`body`, `feet`, `picture` from `player_low` where id=~p limit 1">>).

%%change by xieyunfei
%%删了physical字段，physical现在变为记录，保存在`role_physical`表中
%% 获取player_state登陆所需数据
-define(sql_player_state_data,<<"select `scene`, `x`, `y`, `hp`, `mp`, `quickbar`, `pk_value`, `pk_status`, `pk_status_change_time`, `hide_weapon`, `hide_armor`, `hide_accessory`, `hide_head`, `hide_tail`, `hide_ring`, `guild_quit_lasttime`, `guild_quit_num` , `fix_chengjiu` , `sittimeleft`, `sittimetoday`, `anger`, `skill_cd`, `sys_conf`, `shake_money_time` from `player_state` where id=~p limit 1">>).

%% 获取player_attr登陆所需数据
-define(sql_player_attr_data,<<"select `forza`, `agile`, `wit`, `thew`, `hp_bag`, `mp_bag`, `cell_num`, `storage_num`, `crit`, `ten`, `hightest_combat_power`  from player_attr where id=~p limit 1">>).

%% 获取player_pt所需数据
-define(sql_player_pt_data, <<"select `llpt`, `xwpt`, `fbpt`, `fbpt2`, `bppt`, `gjpt`, `mlpt`, `cjpt`,whpt, get_praise from player_pt where id =~p limit 1">>).

%% 获取player_pt所需数据
-define(sql_player_vip_data, <<"select `vip_type`, `vip_time`, `vip_bag_flag` from player_vip where id=~p limit 1">>).

%% 获取VIP新版信息
-define(sql_player_vip_new_data, <<"select `growth_exp`, `weeknum`, `login_num`, `get_award` from vip_info where id=~p limit 1">>).

%% 获取player_consumption所需数据
-define(sql_player_consumption_data, <<"select uid,end_time,eqout_taobao,times_taobao,eqout_shangcheng,times_shangcheng,eqout_petcz,times_petcz,eqout_petqn,times_petqn,
										eqout_smsx,times_smsx,eqout_smgm,times_smgm,eqout_petjn,times_petjn,eqout_cmsd,times_cmsd,
										gift,repeat_count from player_consumption where uid=~p limit 1">>).

-define(sql_insert_log_player_consumption, <<"insert into `log_player_consumption` (`uid`, `end_time`, `eqout_taobao`, `times_taobao`, `eqout_shangcheng`, `times_shangcheng`, `eqout_petcz`, `times_petcz`, `eqout_petqn`, `times_petqn`, `eqout_smsx`, `times_smsx`, `eqout_smgm`, `times_smgm`, `eqout_petjn`, `times_petjn`, `eqout_cmsd`, `times_cmsd`, `gift`, `repeat_count`, `delete_time`) values (~p, ~p, ~p, ~p,~p, ~p, ~p,~p, ~p, ~p,~p, ~p, ~p,~p, ~p, ~p,~p, ~p, '~s',~p,~p)">>).	

%% 删除player_consumption所需数据
-define(sql_delete_player_consumption_data, <<"delete from player_consumption where uid=~p">>).

%% 获取player_pet所需数据
-define(sql_player_pet_data, <<"select `pet_capacity`, `pet_rename_num`, `pet_rename_lasttime` from player_pet where id=~p limit 1">>).

%% 获取player guild数据
-define(sql_player_guild_data, <<"select a.guild_id, a.guild_name, a.position, b.level from guild_member a left join guild b on a.guild_id=b.id where a.id=~p limit 1">>).

%% 更新llpt
-define(sql_update_llpt, <<"update `player_pt` set llpt = ~p where id = ~p ">>).

%% 更新xwpt
-define(sql_update_xwpt, <<"update `player_pt` set xwpt = ~p where id = ~p ">>).

%% 更新bppt
-define(sql_update_bppt, <<"update `player_pt` set bppt = ~p where id = ~p ">>).

%% 更新gjpt
-define(sql_update_gjpt, <<"update `player_pt` set gjpt = ~p where id = ~p ">>).

%% 更新fbpt
-define(sql_update_fbpt, <<"update `player_pt` set fbpt = ~p where id = ~p ">>).

%% 更新fbpt2
-define(sql_update_fbpt2, <<"update `player_pt` set fbpt2 = ~p where id = ~p ">>).

%% 更新mlpt
-define(sql_update_mlpt, <<"update `player_pt` set mlpt = ~p where id = ~p ">>).

%% 更新cjpt
-define(sql_update_cjpt, <<"update `player_pt` set cjpt = ~p where id = ~p ">>).

%% 更新whpt
-define(sql_update_whpt, <<"update `player_pt` set whpt = ~p where id = ~p ">>).

%%更新高频数据
-define(sql_update_player_high,<<"update `player_high` set `gold`=~p, `bgold`=~p, `coin`=~p, `bcoin`=~p, `exp`=~p where id=~p">>).
%%更新货币
-define(sql_update_player_money, <<"update `player_high` set `gold`=~p, `bgold`=~p, `coin`=~p, `bcoin`=~p where id=~p">>).

%%change by xieyunfei
%%删了physical字段，physical现在变为记录，保存在`role_physical`表中
%%更新player_state数据
-define(sql_update_player_state,<<"update `player_state` set `scene`=~p, `x`=~p, `y`=~p, `hp`=~p, `mp`=~p, `quickbar`='~s', `pk_value` = ~p, `pk_status` = ~p, `pk_status_change_time` = ~p, `sittimeleft`=~p, `sittimetoday`=~p, `anger`=~p , `skill_cd`='~s', `sys_conf`='~s', `shake_money_time`=~p where id=~p">>).
-define(sql_update_player_state2,<<"update `player_state` set `scene`=~p, `x`=~p, `y`=~p, `hp`=~p, `mp`=~p, `quickbar`='~s',`sittimeleft`=~p, `sittimetoday`=~p, `anger`=~p , `skill_cd`='~s' where id=~p">>).

%% 更新时装
-define(sql_update_fashion, <<"update `player_state` set `hide_weapon`=~p, `hide_armor`=~p, `hide_accessory`=~p, `hide_head`=~p, `hide_tail`=~p, `hide_ring`=~p where id=~p">>).

%% 取得指定帐号的角色列表 
-define(sql_role_list,<<"select n.id, n.status, w.nickname, w.sex, w.lv, w.career, w.realm from player_login as n left join player_low as w  on w.id = n.id where n.accname='~s'">>).

%% 根据id查找登陆所需信息
-define(sql_player_login_by_id,<<"select `accname`, `status` from `player_login` where `id` = ~p limit 1">>).

%% 更新登陆需要的记录
-define(sql_update_login_data,<<"update `player_login` set `last_login_time`= ~p, `last_login_ip`  = '~s', `online_flag`=1 where id = ~p">>).

%% 插入buff
-define(sql_insert_buff, <<"insert into `buff` set pid = ~p, type = ~p, goods_id = ~p, attribute_id = ~p, value = ~p, end_time = ~p, scene='~s' ">>).
%% 更新buff
-define(sql_update_buff, <<"update `buff` set goods_id = ~p, value = ~p, end_time = ~p, scene='~s' where id = ~p ">>).
%% 删除buff
-define(sql_delete_buff, <<"delete from `buff` where id = ~p ">>).
%% 删除玩家buff
-define(sql_delete_player_buff, <<"delete from `buff` where pid = ~p ">>).
%% 查询buff
-define(sql_select_buff_all, <<"select id,pid,type,goods_id,attribute_id,value,end_time,scene from `buff` where pid = ~p ">>).
%% 注册角色
%% 更新登陆需要的记录
-define(sql_insert_player_login_one,<<"insert into `player_login` (accid, accname, reg_time, reg_ip, source) values (~p,'~s',~p,'~s','~s')">>).
-define(sql_insert_player_high_one,<<"insert into `player_high` (id) values (~p)">>).
-define(sql_insert_player_low_one,<<"insert into `player_low` (id, `nickname`, `sex`, `lv`, `career`, `realm`) values (~p, '~s', ~p, ~p, ~p, ~p)">>).

%% change by xieyunfei
%% 去掉体力值字段
-define(sql_insert_player_state_one,<<"insert into `player_state` (id, scene, x, y, hp, mp) values (~p, ~p, ~p, ~p, ~p, ~p)">>).
-define(sql_insert_player_attr_one,<<"insert into `player_attr` (`id`, `forza`, `agile`, `wit`, `thew`, `cell_num`, `storage_num`, `ten`, `crit`) values (~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p)">>).
-define(sql_insert_player_pt_one,<<"insert into `player_pt` (`id`) values (~p)">>).
-define(sql_insert_player_vip_one,<<"insert into `player_vip` (`id`) values (~p)">>).
-define(sql_insert_player_pet_one, <<"insert into `player_pet` (`id`) values (~p)">>).
-define(sql_insert_player_recharge_one, <<"insert into `player_recharge`(`id`)  values (~p)">>).

-define(UPDATE_PLAYER_LOW_SET_HUSONG_COLOR, <<"update player_low set husong_npc = ~p where id = ~p">>).
-define(SELECT_PLAYER_LOW_HUSONG_COLOR, <<"select husong_npc from player_low where id = ~p">>).
-define(UPDATE_PLAYER_LOW_SET_HUSONG_REF, <<"update player_low set husong_ref = ~p where id = ~p">>).
-define(SELECT_PLAYER_LOW_HUSONG_REF, <<"select husong_ref from player_low where id = ~p">>).

-define(select_player_low_image, <<"select image from player_low where id = ~p">>).
-define(sql_player_last_login_time,<<"select last_login_time from player_login  where id=~p limit 1">>).

-define(sql_update_hightest_combat_power,<<"update `player_attr` set `hightest_combat_power`= ~p where `id`= ~p">>).
-define(sql_select_hightest_combat_power,<<"select  `hightest_combat_power` from  `player_attr`  where `id`= ~p limit 1">>).
