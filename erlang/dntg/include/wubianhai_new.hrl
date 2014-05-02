%%%------------------------------------
%%% @Module  : wubianhai_new
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.7.6
%%% @Description: �����칬(�ޱߺ�)
%%%------------------------------------

%% ��¼�������
-define(SQL_INSERT_PLAYER_WUBIANHAI, <<"insert into `player_wubianhai` (`id`,`task1_num`,`task2_num`,`task3_num`,`task4_num`,`task5_num`,`task6_num`,`task7_num`,`kill_num`) values (~p,~p,~p,~p,~p,~p,~p,~p,~p)">>).
%% ��ȡplayer_wubianhai��������
-define(SQL_PLAYER_WUBIANHAI_DATA, <<"select `task1_num`,`task2_num`,`task3_num`,`task4_num`,`task5_num`,`task6_num`,`task7_num`,`kill_num` from player_wubianhai where id=~p limit 1">>).
%% �����������
-define(SQL_WUBIANHAI_DPDATE_WUBIANHAI, <<"update player_wubianhai set `task1_num`=~p,`task2_num`=~p,`task3_num`=~p,`task4_num`=~p,`task5_num`=~p,`task6_num`=~p,`task7_num`=~p,`kill_num`=~p where `id`=~p">>).

%% �����𷿼�
-record(arena_room, {
	room_lv=0, %��������
    id=0, 	%����ID
	num=0	%��ǰ�����˿���
}).

%% ��ҵ�һ�β鿴��������������ʱ�ĵȼ�
-record(arena_player_lv, {
    id=0, 	%���ID
	lv=0	%��ʱ�ȼ�
}).

-record(task, {
				id=0,  %���Id
				tid=0, %����Id
				mon_id=0, %�������Id
				num=0, %��Ҫ����
				now_num=0, %��������
				award_id_list = [], %������ƷID
				exp=0, 	%��������
				lilian=0,	%��������
				task_name="",	%��������
				get_award=0,	%1 ����ȡ���� 2 δ��ȡ
				kill_name="",	%��ɱ���
				kill_num=0,		%��Ҫ��ɱ���������
				now_kill=0,		%���ڻ�ɱ���������
				mon_x=0,		%�����Զ�Ѱ·����X
				mon_y=0			%�����Զ�Ѱ·����Y
}).

%% ��ҵ�һ�β鿴��������������ʱ�ĵȼ�
-record(arena, {
    id=0, 	%���ID
	pid = none, %��ҹ����߽���ID
	nickname=0, %����ǳ�
	contry = 0, %��ҹ���
	sex = 0,	%�Ա�
	career = 0,	%ְҵ
	image = 0,	%ͷ��
	player_lv = 0, %��ҵȼ�
	room_lv=0, %��������
	room_id=0, %����ID
	task1=#task{}, %����
	task2=#task{},
	task3=#task{},
	task4=#task{},
	task5=#task{},
	task6=#task{},
	task7=#task{}
}).

%%��ɱ���
-record(killed,{
	uid=0, %��ɱ���ID
	time=0 %��ɱʱ��(ʱ����֮��)			
}).

-record(state, {
				arena_stauts=0,  %�״̬ 0��δ���� 1������ 2�����ѽ���
				config_begin_hour=0,
				config_begin_minute=0,
				config_end_hour=0,
				config_end_minute=0,
				arena_player_lv_dict = dict:new(), %%Key:���ID--Value:��ʱ��ҵȼ�
				arena_room_1_max_id=0, 	%35-45����������ID
				arena_room_2_max_id=0,	%45-55����������ID
				arena_room_3_max_id=0,	%55-65����������ID
				arena_room_4_max_id=0,	%65�������ϳ�������ID
				arena_room_1_dict = dict:new(),
				arena_room_2_dict = dict:new(),
				arena_room_3_dict = dict:new(),
				arena_room_4_dict = dict:new(),
				arena_1_dict = dict:new(),
				arena_2_dict = dict:new(),
				arena_3_dict = dict:new(),
				arena_4_dict = dict:new()
}).
