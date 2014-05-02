%%------------------------------------------------------------------------------
%% @Module  : sql_quiz.hrl
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.6.1
%% @Description: 答题系统sql文件
%%------------------------------------------------------------------------------

%% 日常题库. 
-define(sql_select_base_subject, <<"SELECT id, content, correct, option1, 
									option2, option3, option4 FROM `base_subject`">>).


%% 特殊题库.
-define(sql_select_base_subject_s, <<"SELECT id, content, correct, option1, 
									  option2, option3, option4 FROM `base_subject_s`">>).

%% 主题题库.
-define(sql_select_base_subject_other, <<"SELECT id, content, correct, option1, 
									     option2, option3, option4 FROM
										 `base_subject_other` where subject_type=~p">>).