%%%------------------------------------
%%% @Module  : city_war
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.13
%%% @Description: ��ս
%%%------------------------------------

%% �ʱ�����
-record(city_war_state, 
    {
        config_begin_hour = 0,
        config_begin_minute = 0,
        config_end_hour = 0,
        config_end_minute = 0,
        end_seize_hour = 0,
        end_seize_minute = 0,
        apply_end_hour = 0,
        apply_end_minute = 0,
        open_days = 0,
        seize_days = 0
    }
).

%% ��ս����Ϣ
-record(city_war_info, {
        %% ������������Ϣ {GuildId, {OnlineNum, Score, EtsGuild}}
        attacker_info = dict:new(),
        %% ���ط�������Ϣ {GuildId, {OnlineNum, Score, EtsGuild}}
        defender_info = dict:new(),
        %% �����Ϣ {PlayerId, {State, Score}}  State: 1.���� 2.����
        player_info = dict:new(),
        %% ������Ϣ {Type, {MonId, Blood}}   Type: 1-5.����   Blood: Ѫ���ٷֱ�
        monster_info = dict:new(),
        %% ����������
        attacker_online_num = 0,
        defender_online_num = 0,
        %% �����������
        attacker_revive_place = [],
        %% ���ط������
        defender_revive_place = [],
        %% ������ҽ������
        attacker_doctor_num = 0,
        %% ��������������
        attacker_ghost_num = 0,
        %% ���ط�ҽ������
        defender_doctor_num = 0,
        %% ���ط���������
        defender_ghost_num = 0,
        %% �����Ḵ������
        revive_mon_id = [],
        %% ����1ը��
        bomb_list1 = [],
        %% ����2ը��
        bomb_list2 = [],
        %% ����㹥�ǳ���
        car1_list1 = [],
        car1_list2 = [],
        car2_list1 = [],
        car2_list2 = [],
        %% ���ϴ��ڹ��ǳ�����
        total_car_num = 0,
        %% ���ϴ��ڼ�������
        total_tower_num = 0,
        %% �����б�
        die_list = [],
        %% �ڼ���
        count = 1,
        %% �´θ���ʱ��
        next_revive_time = 0,
        %% �ɼ����ǳ�����
        collect_car_num = 0,
        %% ����Ԯ��������
        att_aid_num = 0,
        %% ����Ԯ��������
        def_aid_num = 0
}).
