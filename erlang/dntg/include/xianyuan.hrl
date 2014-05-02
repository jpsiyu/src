%%%--------------------------------------
%%% @Module  :  xianyuan 
%%% @Author  :  hekai
%%% @Email   :  hekai@jieyou.cn
%%% @Created :  2012-9-27
%%% @Description: 仙缘系统
%%%---------------------------------------
-define(MAX_XY_LV, 60).
-define(UPDATE_PTYPE_TO_0, <<"update xianyuan set ptype =0 ,ptype2 = ~p where uid = ~p">>).
-define(UPDATE_XIANYUAN_JJIE, <<"update xianyuan set jjie = ~p, sweetness=~p where uid = ~p">>).
-define(UPDATE_XIANYUAN_SWEET, <<"update xianyuan set sweetness=~p where uid = ~p">>).
-define(FIND_XIANYUAN, <<"select * from xianyuan where uid = ~p">>).
-define(INSERT_XIANYUAN, <<"insert into xianyuan(uid,ptype2,sweetness) values(~p,~p,~p)">>).
-define(FIND_PARNER, <<"select career,nickname from player_low where id = ~p">>).
-define(INSERT_CP_SKILL, <<"insert skill_couple(uid,skill_id,lv,cd) values(~p,~p,~p,~p)">>).
-define(FIND_CP_SKILL, <<"select skill_id,lv,cd from skill_couple where uid=~p">>).
-define(UPDATE_CP_SKILL_CD, <<"update skill_couple set cd = ~p where uid = ~p and skill_id = ~p">>).
-define(UPDATE_CP_SKILL_LV, <<"update skill_couple set lv = ~p where uid = ~p and skill_id = ~p">>).
-define(ADD_LOG_XIANYUAN, <<"insert into log_xianyuan(uid,name,xl_time,type,lv,sweetness1,sweetness2) values(~p,'~s',~p,~p,~p,~p,~p)">>).
-define(FIND_TYPE_10, <<"select drugdef from xianyuan where uid=~p">>).
-define(UPDATE_XIANYUAN, <<"update xianyuan set 		
						  `hpmp`=~p,
						  `def`=~p,
						  `doom`=~p,
						  `jook`=~p,
						  `tenacity`=~p,
						  `sudatt`=~p,
						  `att`=~p,
						  `firedef`=~p,
						  `icedef`=~p,
						  `drugdef`=~p,
						  `jjie`=~p,
						  `ptype`=~p,
						  `ptype2`=~p,
						  `cdtime`=~p,
						  `sweetness`=~p	
						where `uid`=~p">>).

%% 玩家仙缘修炼、境界数据
-record(player_xianyuan,
        {
		  uid=0,       %%玩家ID,
		  hpmp=0,      %%气血、内力内功等级,
		  def=0,       %%防御内功等级,
		  doom=0,      %%命中内功等级,
		  jook=0,      %%闪避内功等级,
		  tenacity=0,  %%坚韧内功等级,
		  sudatt=0,    %%暴击内功等级,
		  att=0,       %%攻击内功等级,
		  firedef=0,   %%火坑内功等级,
		  icedef=0,    %%冰抗内功等级,
		  drugdef=0,   %%毒抗内功等级,
		  jjie=0,      %%境界等级,共4个
		  ptype = 0,   %%当前修炼类型
		  ptype2 = 1,   %%上一次修炼类型
		  cdtime =0,   %%开始CD时间
		  sweetness =1000 %%甜蜜度
        }).

%%　仙缘修炼数据
-record(data_xianyuan,{
	xianyuan_type = 0,  %% 仙缘类型
	xianyuan_level = 0, %% 仙缘级别 
	value = [],			%% 属性值,如[{1,50}, {2,25}]
	need_closeness = 0, %% 需要消耗的亲密度
	need_cdtime = 0,	%% 修炼时间,单位秒
	precondition = [],	%% 前置条件 [{类型,级别}, {类型,级别}]
	nextcondition = []  %% 后置修炼 [{类型,级别}, {类型,级别}]
	}).

%% 仙缘境界数据
-record(data_jjie,{
		jlevel =0,				        %% 境界等级
		need_sweetness ={1000,1000},	%% 境界触发需要的甜蜜度
		value = []				        %% 属性值 [气血,雷抗性,水抗性,冥抗性]
	}).

%% 夫妻技能 -- 天涯咫尺
-record(cp_skill_1,{
	skill_id=0,			%% 技能Id
	need_cd =0,			%% 需要Cd时间
	condition = {0,0}	%% 激活条件
	}).

%% 夫妻技能 -- 相濡以沫
-record(cp_skill_2,{
	skill_id=0,			%% 技能Id
	need_cd =0,         %% 需要Cd时间
	condition = {0,0},  %% 激活条件
	add_hp =0			%% 增加血量
	}).
