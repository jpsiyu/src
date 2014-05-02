%%%--------------------------------------
%%% @Module  : data_active
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.4
%%% @Description: 活跃度
%%%--------------------------------------

-module(data_active).
-compile(export_all).

%% 获得操作项id
%% 1护送美女
%% 2南天门
%% 3黄金沙滩
%% 4智力答题
%% 5竞技帮派
%% 6经验副本
%% 7宠物副本
%% 8铜币副本
%% 9平乱任务
%% 10皇榜任务
%% 11诛妖任务
%% 12装备副本
%% 13捕抓蝴蝶
%% 14当天在线累计时长
%% 1   护送美女
%% 2   南天门
%% 4   智力答题
%% 5   帮派战 竞技场  蟠桃会
%% 6   经验副本
%% 7   宠物副本
%% 8   铜币副本
%% 9   平乱任务
%% 11  诛妖任务
%% 12  装备副本
%% 14  在线时长
%% 15  封魔录副本
%% 16  阵营任务
%% 17  摇钱树
get_opt_ids() -> [1, 4, 5, 6, 7, 8, 9, 11, 12, 15, 16, 17].

get_active_sum(Lv) -> 
    if 
        Lv =< 15 -> 1;
        Lv =< 20 -> 2;
        Lv =< 29 -> 3;
        Lv =< 30 -> 5;
        Lv =< 31 -> 8;
        Lv =< 33 -> 9;
        Lv =< 34 -> 11;
        Lv =< 38 -> 12;
        true -> 12
    end.

%% 获得奖励项id
get_award_ids() -> [1, 2, 3, 4, 5, 6, 7, 8].

%% 获取活跃度上限
get_limit_up() -> 150.

%% 获得奖励需要的活跃度
get_award_score_by_id(1) -> 10;
get_award_score_by_id(2) -> 20;
get_award_score_by_id(3) -> 30;
get_award_score_by_id(4) -> 40;
get_award_score_by_id(5) -> 60;
get_award_score_by_id(6) -> 80;
get_award_score_by_id(7) -> 100;
get_award_score_by_id(8) -> 120;
get_award_score_by_id(_) -> 1000.

%% 获取每个操作项的活跃度（现在每项操作项都是一样的）
get_active_by_opt() -> 10.

%% 每次获得的活跃度（现在每项操作项都是一样的）
add_active_by_opt() -> 10.

%% 1   护送美女
%% 2   南天门
%% 3   黄金沙滩
%% 4   智力答题
%% 5   竞技场/帮派战/蟠桃会 20  
%% 6   经验副本
%% 7   宠物副本
%% 8   铜币副本
%% 9   平乱任务
%% 10  皇榜任务
%% 11  诛妖任务
%% 12  装备副本
%% 14  在线时长
%% 13  捕抓蝴蝶
%% 15  封魔录副本
%% 16  阵营任务 20
%% 17  摇钱树


%%新活跃度
get_active_by_type(Type,VipType) ->
        Base =
        if 
        Type =:= 1 -> 10;
        %%Type =:= 2 -> 20;
        %%Type =:= 3 -> 5;
        Type =:= 4 -> 10;
        Type =:= 5 -> 20;
        Type =:= 6 -> 10;
        Type =:= 7 -> 10;
        Type =:= 8 -> 10;
        Type =:= 9 -> 10;
        %%Type =:= 10 -> 5;
        Type =:= 11 -> 10;
        Type =:= 12 -> 10;
        %%Type =:= 13 -> 1;
        %%Type =:= 14 -> 10;
        Type =:= 15 -> 10;
        Type =:= 16 -> 20;
        Type =:= 17 -> 10;
        true -> 0
    end,
    case VipType of
        1 -> round(1.1*Base);
        2 -> round(1.2*Base);
        3 -> round(1.3*Base);
        _ -> Base
    end.
    

%% 取得阶段id
get_step(LV) when LV < 45 -> 1;
get_step(LV) when LV < 55 -> 2;
get_step(_) -> 3.

%% 获取礼包id
%% 玩家等级1~49为1阶段，50~59为2阶段，60以上为3阶段
%% 格式：阶段, 活跃度
get_gift(1, 1) -> 531711;
get_gift(1, 2) -> 531712;
get_gift(1, 3) -> 531713;
get_gift(1, 4) -> 531714;
get_gift(1, 5) -> 531715;
get_gift(1, 6) -> 531716;
get_gift(1, 7) -> 531717;
get_gift(1, 8) -> 531718;
get_gift(2, 1) -> 531721;
get_gift(2, 2) -> 531722;
get_gift(2, 3) -> 531723;
get_gift(2, 4) -> 531724;
get_gift(2, 5) -> 531725;
get_gift(2, 6) -> 531726;
get_gift(2, 7) -> 531727;
get_gift(2, 8) -> 531728;
get_gift(3, 1) -> 531731;
get_gift(3, 2) -> 531732;
get_gift(3, 3) -> 531733;
get_gift(3, 4) -> 531734;
get_gift(3, 5) -> 531735;
get_gift(3, 6) -> 531736;
get_gift(3, 7) -> 531737;
get_gift(3, 8) -> 531738;
get_gift(_, _) -> 0.

%% 通过奖励id获得配置[需要的活跃度， 经验]
get_award_config(1, LV) -> [10, 5 * (LV * LV + 2880)];
get_award_config(2, LV) -> [20, 5 * (LV * LV + 2881)];
get_award_config(3, LV) -> [30, 5 * (LV * LV + 2882)];
get_award_config(4, LV) -> [40, 10 * (LV * LV + 2883)];
get_award_config(5, LV) -> [60, 10 * (LV * LV + 2884)];
get_award_config(6, LV) -> [80, 20 * (LV * LV + 2885)];
get_award_config(7, LV) -> [100, 20 * (LV * LV + 2886)];
get_award_config(8, LV) -> [120, 25 * (LV * LV + 2887)];
get_award_config(_, _) -> [0, 0].

%% 获取最后一个礼包id列表，用来判断发传闻
get_last_gift_ids() -> [531718, 531728, 531738].

%% 获得目标id
in_target_list(_Type) -> [].

%% 1   护送美女
%% 2   南天门
%% 3   黄金沙滩
%% 4   智力答题
%% 5   竞技场/帮派战/蟠桃会 2 20  
%% 6   经验副本 2
%% 7   宠物副本
%% 8   铜币副本
%% 9   平乱任务 10
%% 10  皇榜任务
%% 11  诛妖任务 3
%% 12  装备副本
%% 14  在线时长 1.5
%% 13  捕抓蝴蝶
%% 15  封魔录副本
%% 16  阵营任务 20
%% 17  摇钱树


%% 获得每种操作项需要完成的次数
%% 3  10 13 14 暂时关闭
require_opt_num(Type) ->
	if 
		Type =:= 1 -> 1;
		Type =:= 2 -> 1;
		Type =:= 3 -> 1;
		Type =:= 4 -> 1;
		Type =:= 5 -> 2;
		Type =:= 6 -> 2;
		Type =:= 7 -> 1;
		Type =:= 8 -> 1;
		Type =:= 9 -> 10;
		Type =:= 10 -> 1;
		Type =:= 11 -> 3;
		Type =:= 12 -> 1;
		Type =:= 13 -> 1;
		Type =:= 14 -> 1;
        Type =:= 15 -> 1;
        Type =:= 16 -> 1;
        Type =:= 17 -> 1;
		true -> 0
	end.
