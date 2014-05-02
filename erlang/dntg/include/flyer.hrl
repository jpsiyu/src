%%%-------------------------------------------------------------------
%%% @Module	: flyer
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 19 Dec 2012
%%% @Description: 飞行器头文件
%%%-------------------------------------------------------------------

-record(flyer_star,
	{
	  flyer_id = 0,					%飞行器ID
	  star_attr = [],				%星星属性
	  star_value = 0,				%星星评分
	  player_id = 0,				%玩家ID
	  ts = 0,					%时间戳
	  star_num = ""					%星星序号(字符串形式)
	}
       ).
-record(flyer,
	{
	  id = 0,				%纪录ID
	  nth = 0,				%第N个飞行器
	  player_id = 0,			%玩家ID
	  open = 0,				%是否开启
	  level = 0,				%训练等级
	  %% base_attr = [],			%基础属性
	  %% train_attr = [],			%训练属性
	  stars = [],				%星星列表[#flyer_star{},...]
	  state = 0,				%0卸下1装备2飞行
	  speed = 0,				%速度
	  name = "",				%名称
	  combat_power = 0,			%战力
	  back_count = 0,			%回退次数
	  quality = 1				%飞行器品质
	}
       ).


