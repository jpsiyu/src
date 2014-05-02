%%------------------------------------------------------------------------------
%% @Module  : quiz.hrl
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.31
%% @Description: 答题数据定义
%%------------------------------------------------------------------------------

%% 答题
-define(ETS_QUIZ, ets_quiz).                %% 日常题库.
-define(ETS_QUIZ_OTHER, ets_quiz_other).    %% 主题题库.
-define(ETS_QUIZ_S, ets_quiz_s).            %% 特别活动题库.
-define(ETS_QUIZ_ANSWER, ets_quiz_answer).  %% 每次答题记录表
-define(ETS_QUIZ_MEMBER, ets_quiz_member).  %% 参加答题的玩家


%% 答题服务器状态
-record(quiz_state, {
     state = 0,       %% 答题器状态:0非答题状态 1报名状态 2答题状态
	 start_time = 0,  %% 答题活动开始时间.	 
     sign_time = 0,   %% 注册时间
     answer_time = 0, %% 作答时间
     righ_option = 0, %% 正确选项
	 count = 0,       %% 选项个数

     all_turn = 0,    %% 总答题轮数
     now_turn = 0,    %% 当前答题轮数
     type = 0,        %% 答题类型

     option1_num = 0, %% 选择1人数
     option2_num = 0, %% 选择2人数
     option3_num = 0, %% 选择3人数
     option4_num = 0  %% 选择4人数
}).

%% 答题定时器服务器状态
-record(quiz_timer_state, {
    sign_time = 0,    %% 剩余注册时间
    answer_time = 0,  %% 剩余答题时间
    turn  = 0,        %% 答题活动轮数
    type = 0,         %% 答题活动类型【0普通答题、1活动答题】
    subject_type = 1, %% 答题主题类型
    quiz_pid = none   %5 答题器进程ID
}).

%% 题库
-record(ets_quiz, {
        id = 0,                %% 玩家Id
        content= "",           %% 正确答案(1-4)
        correct=1,             %% 
        option1="",            %% 
        option2="",            %% 
        option3="",            %% 
        option4=""             %% 
    }).

%% 特别活动题库
-record(ets_quiz_s, {
        id = 0,                %% 玩家Id
        content= "",           %% 正确答案(1-4)
        correct=1,             %% 
        option1="",            %% 
        option2="",            %% 
        option3="",            %% 
        option4=""             %% 
    }).
    
%% 参加答题的玩家
-record(quiz_member, {
          role_id              %% 玩家ID
          ,name= <<>>          %% 角色名
          ,realm=0             %% 阵营
          ,turn=0              %% 当前是第几轮答题
          ,score=0             %% 得分
		  ,exp=0               %% 经验
          ,continue=0          %% 连续答对数
          ,right=0             %% 总答对题数
          ,genius=0            %% 本次答题总获得文彩
          ,turn_genius=0       %% 本回合获得文采
          ,turn_option=0       %% 本回合选择答案(写轮眼和放大镜)
          ,lucky=3             %% 幸运星
          ,copy_eye=3          %% 写轮眼
          ,scale=3             %% 放大镜
          ,lv=0                %% 
          }).


%% 每次答题记录表
-record(quiz_answer, {
          role_id=0            %% 主建
          ,type=0              %% 普通答题，写轮眼，放大镜
          ,option=0            %% 答案题目(如果是写轮眼，答案是复制role_id)
          ,time=0              %% 回答用时
          ,lucky}).            %% 是否使用幸运星

%% 答题进程记录表
-record(quiz_process,{
        id = 0,                %% ID
        type = 0,              %% 进程类型：1控制进程 2服务进程
        pid = none             %% 进程id
        }).

-define(QUIZ_ACTIVITY_DAY, [2,4,6]).    %% 一周开放时间(星期)
-define(QUIZ_TOTAL_SUBJECT, 30).        %% 一轮活动总题数，30
-define(QUIZ_S_TOTAL_SUBJECT, 30).      %% 特别活动总题数，5

-define(QUIZ_AWARD_GENIUS, 1).          %% 每次答题正确奖励文采

-define(QUIZ_TOP_SIZE, 10).             %% 每次显示排行头X人

%%　-define(QUIZ_NOTICE_TIME, 60*10).       %% 公告活动即将开始报名到可以报名时长(秒)
-define(QUIZ_NOTICE_TIME, 30).          %% 公告活动即将开始报名到可以报名时长(秒)
-define(QUIZ_TOTAL_TIME, 60*25).        %% 答题总时长(秒)（报名时间+答题时间）
-define(QUIZ_TOTAL_ANSWER_TIME, 60*15). %% 公告活动即将开始报名到可以报名时长(秒)

-define(QUIZ_ANSWER_TIME,    15).       %% 15秒答题

-define(QUIZ_READ_TO_ANSWER, 5*1000).   %% 阅题时间(比实际快3秒)
-define(QUIZ_ANSWER_TO_COUNT, 10*1000). %% 答题时间
-define(QUIZ_COUNT_TO_SEND, 5*1000).    %% 统计到发题间隔

-define(QUIZ_NORMAL_MODE, 0).            %% 正常模式答题
-define(QUIZ_COPY_MODE,   1).            %% 写轮眼模式答题
-define(QUIZ_SCALE_MODE,  2).            %% 放大镜模式答题

-define(OPTION_TIME, [12,0]).            %% 答题开始时间
-define(OPTION_S_TIME, [18, 25]).        %% 特别答题开始时间

-define(QUIZ_START_LEVEL,  31).          %% 答题开始等级
