%%%------------------------------------------------
%%% File    : sql_fly.hrl
%%% Author  : zhenghehe
%%% Created : 2011-12-07
%%% Description: 飞行系统sql文件
%%%------------------------------------------------
-define(FLY_SELECT_ONE, <<"select id, fly_status, goods_id, fly_mount, fly_mount_speed, permanent, left_time, last_goods_id from fly where id=~p limit 1">>).
-define(FLY_INSERT, <<"replace into fly(id, fly_status, goods_id, fly_mount, fly_mount_speed, permanent, left_time, last_goods_id) values(~p,~p,~p,~p,~p,~p,~p,~p)">>).
-define(FLY_DELETE, <<"delete from fly where id=~p">>).