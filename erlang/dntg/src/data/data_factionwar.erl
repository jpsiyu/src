%% Author: zengzhaoyuan
%% Created: 2012-7-3
%% Description: TODO: Add description to new_file
-module(data_factionwar).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([get_npc_type_id/0,
		 add_score_by_no/1,
		 get_factionwar_config/1,
		 get_process_when_attacked/2,
		 get_score_by_factionwar_no/1,
		 get_fy_id_by_kill_mon/1,
		 get_zl_fy_id/1,
		 get_no_rate/1,
		 get_buff/0,
		 buff_ids/0,
		 get_rand_score/0,
		 get_build/1]).

%%
%% API Functions
%%
%% 帮战基础配置
get_factionwar_config(Type)->
	case Type of
		% 开放日期(星期几)
        open_day -> [2,4,6];
		%open_day -> [];
		% 帮战报名起始时刻(周2\4\6)
		time->[20,15];
		% 报名时间(分钟)
		sign_up_time->15;
		% 每轮耗时(分钟)
		loop_time->30;
		% 每张图最多帮派数
		max_faction->125;
		% 每轮终止入场时间(每轮结束前)(秒)(一定要比每轮耗时小)
%% 		no_in_time->15*60;
		no_in_time->30;
		% 帮战地图
		scene_id->106;
		% 最大帮派报名数
		max_sign_up_factionwar->125;
		% 帮战五个出生点
		born->[{6,23},{44,23},{25,55}];
		% 帮战五个复活点
		revive->[{6,23},{44,23},{25,55}];
		% 离开帮战场景的默认位置[场景类型ID, X坐标, Y坐标]
		leave_scene -> [102, 36, 47];
		% 帮派等级
		faction_lv->1;
		% 参赛扣除帮派资金
		money->100;
		% 最小报名数量
		min_sign_up_member->1;
		% 允许参加帮战最低等级
		lv->38;
		% 允许死亡次数(6次以后即为幽灵状态)
		dead_num->124;
		% 每击杀一个敌对帮派获取积分
		kill_score->3;
		% 助攻分
		hold_kill_score ->1;
		% 被杀获得积分
		killed_score->1;
		% 击杀或被击杀金箍棒帮众额外积分
		jgb_kill_ext_score->2;
		% 最大怒气值次数
		max_anger -> 3;
		% 怒气技能ID
		anger_skill_id -> 400006;
		% 战场扫描加分间隔(占领封印5分，金箍棒10分,只针对帮派加分)(分钟)
		add_score_time -> 1;
		add_score_fy -> 15;
		add_score_jgb -> 30;
		% 召唤Buff采集怪时间紧间隔(3分钟)
		call_buff_time -> 3;
		% 封印坐标
		fy1_id -> [10543,10545,10539];
		fy2_id -> [10544,10546,10540];
		fy_posion-> [[25,16],[11,40],[38,40]];
		% 五行神兽Id[青龙，白虎，朱雀]
		fy_mon_kill_score->30;
		fy_mons -> [10548, 10549, 10550];
		% 金箍棒ID (前边未占领，后边被占领)
		jgb_id -> [10507,10500];
		% 金箍棒刷新坐标
		jgb_posion->[26,32];
		% 金箍棒首杀分
		jgb_first_kill_score->50;
		% 采集怪
		cjs_id->10547;
		% 采集怪每个击杀获得的分
		cjs_kill_score-> 5;
		% 金灿灿野怪(五个复活点刷新，每次20个，全死了再刷)
		jcc_id -> 10506;
		% 无敌技能
		skill_wd->400007;
		% 礼包ID
		gift_id->532220;
		% 帮主技能CD时间(分钟)
		leader_skill_cd->5;
        % 帮派神石积分
        stone_score_list -> [1,2,4,7,10];
		% 默认返回值
		_->no_config
	end.

%%需要记分怪物列表
get_npc_type_id()->
	%%[10537,10539,10541,10543,10545,10538,10540,10542,10544,10546,10507,10500,10547,10548,10549,10550,10551,10552].
	[10543, 10545, 10539, 10544, 10546, 10540, 10507, 10500, 10548, 10549, 10550, 10547].

%% 获取Buff列表。
get_buff()->
	get_buff_sub(buff_pos(),[]).
get_buff_sub([],Result)->Result;
get_buff_sub([[X,Y]|T],Result)->
	Ids = buff_ids(),
	Len = length(Ids),
	N = util:rand(1, Len),
	Id = lists:nth(N, Ids),
	get_buff_sub(T,Result++[[Id,X,Y]]).	
%%Buff位置
buff_pos()->
	[[114,29],[118,47],[117,63],[117,124],[96,132],
	 [116,132],[43,135],[26,137],[15,122],[9,72],
	 [12,40],[7,32],[45,19],[68,20],[74,30]].
%%Buff Id
buff_ids()->
	[42011,42012,42013,42021].

%%按帮派排名给分
%%@param No 帮派排名
add_score_by_no(No)->
	case No of
		1->150;
		2->100;
		3->50;
		4->30;
		5->10;
		_->0
	end.

%%获取一个随机战分
get_rand_score()->
	Rand_score = [{100,1,5},{200,6,20},{300,21,80},{400,81,95},{500,96,100}],
	Rate = util:rand(1,100),
	[F_Score] = [Score||{Score,Rate_min,Rate_max}<-Rand_score,Rate_min=<Rate,Rate=<Rate_max],
	F_Score.

%%
%% Local Functions
%%
%% 击杀神兽后的封印ID及坐标
get_fy_id_by_kill_mon(NPCId)->
	case NPCId of
		10548->[10544,25,16];
		10549->[10546,11,40];
		10550->[10540,38,40]	
	end.

%%获取占领封印类型ID
get_zl_fy_id(NPCId)->
	case NPCId of
		10543->[10544,22,16];
		10545->[10546,11,40];
		10539->[10540,38,40];
		10544->[10544,22,16];
		10546->[10546,11,40];
		10540->[10540,38,40]
	end.

%% 遭受攻击时，获取金箍棒读条进度
%% @param CurrentProcess 当前进度值，上限为100.
%% @param IsFaintAttack 是否被眩晕  1是 0非
%% @param int 最终进度
get_process_when_attacked(CurrentProcess,IsFaint)->
	case IsFaint of
		1->0; %被眩晕，直接打断
		_->
			Rate = util:rand(1, 100),
			if
				Rate=<15-> %概率发生
					if
						CurrentProcess=<20->0;    %不足20%，直接归0
						true->CurrentProcess-20   %打退20%
					end;
				true-> % 概率未发生，不打断
					CurrentProcess
			end
	end.

%% 按帮战名次获取的积分
%% @param FactionwarNo 帮战名次
%% @return Score
get_score_by_factionwar_no(FactionwarNo)->
	case FactionwarNo of
		1->5;
		2->4;
		3->3;
		4->2;
		_->1
	end.

%%按帮战最终名次获取建设度
get_build(FactionNo)->
	case FactionNo of
		1->800;
		2->600;
		3->580;
		4->560;
		5->540;
		6->500;
		7->480;
		8->460;
		9->440;
		10->420;
		_->360
	end.

%%按帮战最终名次获取名次系数
get_no_rate(FactionNo)->
	case FactionNo of
		1->11;
		2->10;
		3->9;
		4->8;
		5->7;
		6->6;
		7->5;
		8->4;
		9->3;
		10->2;
		_->1
	end.
	



