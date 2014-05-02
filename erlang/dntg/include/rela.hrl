%%%------------------------------------------------
%%% File    : rela.erl
%%% Author  : zhenghehe
%%% Created : 2012-02-01
%%% Description: 好友record定义
%%%------------------------------------------------

-define(FD_NUM_MAX, 200). %%最大好友数
-define(GROUP_NUM_MAX, 5). %% 分组最大数量
-define(ENEMY_LOCATION_TIME, 30 * 60). %% 赏恶令持续时间
-define(MAX_BLESS_ACCEPT, 15). %%最大接受好友祝福次数
-define(MAX_BLESS_SEND, 30). %%每天能送出的祝福数
-define(BLESS_UP_EXP, 14). %%升级玩家祝福经验
-define(BLESS_NO_UP_EXP, 14). %%非升级玩家祝福经验
-define(BLESS_UP_LLPT, 0). %%升级玩家祝福历练经验
-define(BLESS_NO_UP_LLPT, 0). %%非升级玩家祝福历练经验
-define(Exp_Llpt_Bottle_Max_Lv,40). %%进经验瓶最大等级

%% 账户注册时更库
-define(sql_insert_player_bless_one, <<"insert into `player_bless` (`id`) values (~p)">>).
-define(sql_select_player_bless, <<"select id,bless_exp,bless_llpt,bless_is_exchange,bless_send,bless_friend_used,bless_send_last_time from `player_bless` where id=~p">>).
-define(SQL_UPDATE_BLESS_EXP_LLPT,<<"update player_bless set bless_exp=bless_exp+~p,bless_llpt=bless_llpt+~p where id=~p">>).%%更改祝福经验、历练
-define(SQL_UPDATE_BLESS_SEND,<<"update player_bless set bless_send=~p,bless_send_last_time=~p where id=~p">>). %%更改祝福发送状态
-define(SQL_UPDATE_BLESS_is_exchange,<<"update player_bless set bless_is_exchange=~p where id=~p">>).  %%更改兑换状态
-define(SQL_UPDATE_BLESS_friend_used,<<"update player_bless set bless_friend_used=bless_friend_used+1 where id=~p">>).  %%更改一键征友次数

%%关系列表
-record(ets_rela, 
	{
	  id = 0,             %% 记录id
	  idA = 0,            %% 角色A的id
	  idB = 0,            %% 角色B的id
	  rela = 0,           %% 与B的关系(0:没关系1:好友2:黑名单3:仇人4:好友且仇人5:仇人且黑名单)
	  intimacy = 0,       %% 亲密度
	  group = 0,          %% B所在分组
	  closely = 0,        %% 是否为密友
	  location = 0,       %% 是否显示位置
	  killed_by_enemy = 0,%% 被仇人杀死多少次
	  hatred_value = 0,   %% 仇恨值
	  location_time = 0,  %% 显示位置到期时间
	  bless_gift_id = 0,  %% 好友祝福曾送最贵礼包
	  wanted = 0,	      %% 是否通辑玩家idB
	  xlqy = 0,	          %% 仙侣奇缘次数
	  show_enemy = 0	  %% 仇人图标
	}
       ).

%%好友资料
-record(ets_rela_info, 
	{
	  id = 0,                  %%角色id
	  nickname = [],           %%角色名字
	  sex = 0,                 %%角色性别
	  lv = 0,                  %%角色等级
	  career = 0,              %%角色职业
	  vip = 0,                 %%vip类型
	  realm = 0,               %%国家
	  image = 0,               %%角色头像
	  online_flag = 0,	       %%在线标志
	  scene = 0,		       %%场景id
      longitude = 0,           %% 经度
      latitude = 0,             %% 纬度
	  last_login_time = util:now()      %%最近登录时间
	}).

%% 好友分组列表
-record(ets_rela_group, 
	{
	  id = 0,  %%组ID
	  uid = 0,         %% 玩家id
	  group = data_rela_text:get_def_group_name()      %% 好友分组，默认分组名。数据库中存储玩家自命名组名。
	}).
