%% ---------------------------------------------------------
%% Author:  zzy
%% Email:   156702030@qq.com
%% Created: 2012-2-3
%% Description: 经脉数据
%% --------------------------------------------------------

%% 经脉最高级别
-define(MERIDIAN_MAX_LV, 100). 
%% 境界最大值
-define(MERIDIAN_MAX_GEN, 25).
%% 内功每次升级大小
-define(MER_UP_GAP, 1). 
%% 境界每次升级大小
-define(GEN_UP_GAP, 1). 
%% 境界成长丹类型ID
-define(GEN_DAN_GOOD_ID, 231201).
%% 境界保护符类型ID
-define(GEN_BAOHU_GOOD_ID, 231202).
%% 境界失败附加成功率1%
-define(GEN_FAIL_ADD_RATE, 1).
%% VIP提升概率百分比
-define(VIP_RATE, 5). 


%% 玩家经脉、根骨、慧根数据表。
-record(player_meridian,
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
		  ghpmp=0,     %%气血、内力境界等级,
		  gdef=0,      %%防御境界等级,
		  gdoom=0,     %%命中境界等级,
		  gjook=0,     %%闪避境界等级,
		  gtenacity=0, %%坚韧境界等级,
		  gsudatt=0,   %%暴击境界等级,
		  gatt=0,      %%攻击境界等级,
		  gfiredef=0,  %%火坑境界等级,
		  gicedef=0,   %%冰抗境界等级,
		  gdrugdef=0,  %%毒抗境界等级,
		  grhprmp=0,    %%气血、内力境界附加成功率,
		  grdef=0,     %%防御境界附加成功率,
		  grdoom=0,    %%命中境界附加成功率,
		  grjook=0,    %%闪避境界附加成功率,
		  grtenacity=0,%%坚韧境界附加成功率,
		  grsudatt=0,  %%暴击境界附加成功率,
		  gratt=0,     %%攻击境界附加成功率,
		  grfiredef=0, %%火坑境界附加成功率,
		  gricedef=0,  %%冰抗境界附加成功率,
		  grdrugdef=0,  %%毒抗境界附加成功率
		  mid = 0, 		%%元神类型
		  cdtime = 0,    %%CD时间
		  thpmp=0,      %%气血、内力已突破等级,
		  tdef=0,       %%防御已突破等级,
		  tdoom=0,      %%命中已突破等级,
		  tjook=0,      %%闪避内功已突破等级,
		  ttenacity=0,  %%坚韧已突破等级,
		  tsudatt=0,    %%暴击已突破等级,
		  tatt=0,       %%攻击已突破等级,
		  tfiredef=0,   %%火坑已突破等级,
		  ticedef=0,    %%冰抗已突破等级,
		  tdrugdef=0   %%毒抗已突破等级,
        }).

%%产品经脉数据
-record(data_meridian, {
		ntype = 0,  		%%经脉类型ID(1-8)
		nlevel = 0,  		%%经脉等级(1-17)
		need_level = 0, 	%%经脉开启需求玩家等级
		preconditon = [],   %%前置条件(要求前置脉必须达到多少级)
		need_llpt = 0, 		%%需求历练声望
		need_coin = 0, 		%%升级所需金钱
		need_whpt = 0,		%%升级所需武魂
		need_cd = 0,        %%升级所需要CD时间
		nvalue = 0, 		%%属性值(由type字段值决定是哪种值)
		need_goods_id = 0,	%%突破丹ID(不需要突破时填0)  
		need_goods_num = 0	%%突破丹数量
    }).

%% 产品根骨数据
-record(data_meridian_gen, {
		ntype = 0,  	%%经脉类型ID(1-8)							
		nlevel = 0,		%%经脉等级(1-20)
		need_coin = 0, 	%%消耗铜币
		rate = 0, 		%%成功率(0~100) 百分比
		addrate = 0, 	%%加成(0~100) 是个百分比
        add = 0,        %%固定加成属性
		failto = -1, 	%%失败后掉级(-1为不掉级，0~20为所掉级)
		need_goods_id = 0,  %%境界成长符(不需要时填0)
        need_goods_num = 1  %%境界成长符数量(不需要时填0)
    }).