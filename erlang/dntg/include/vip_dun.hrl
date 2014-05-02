%%%--------------------------------------
%%% @Module  :  vip_dun
%%% @Author  :  guoxi
%%% @Email   :  178912295@qq.com
%%% @Created :  2013.02.25
%%% @Description: vip副本
%%%---------------------------------------

-record(vip_dun_state,
    {
        max_id = 0,                 %ID
        player_dun = dict:new()     %玩家副本信息
    }
).

-record(player_dun,
    {
        player_id = 0,     %玩家ID
        player_lv = 0,     %玩家等级
        copy_id = 0,       %房间ID
        enter_time = 0,    %进入时间
        off_line_time = 0, %离线时间
        flag_num = 0,      %掷骰子次数
        can_flag = 1,      %当前是否可掷骰子 1.可 2.不可
        skill_list = [],   %技能情况
        total_num = 1,     %总格数
        now_num = 1,       %当前在第几格
        now_xy = {0, 0},   %当前格子坐标
        now_state = 0,     %当前格子类型
        battle_start_time = 0, %战斗开始时间
        boss_id = 0,       %BOSS的唯一ID
        talk_type = 0,     %说话类型
        need_kill_mon = 0, %需要杀死的小怪ID
        quiz = "",         %问题
        section1 = "",     %答案1
        section2 = "",     %答案2
        section3 = "",     %答案3
        section4 = "",     %答案4
        correct = 0,       %正确答案
        question_time = 0, %答题开始时间
        half_award = 0,    %减半奖励剩余格数
        buy_num = 0,       %已购买骰子次数
        dun_num = 0        %参与VIP副本次数
    }
).
