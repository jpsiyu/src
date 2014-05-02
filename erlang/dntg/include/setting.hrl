%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.6.24
%%% @Description: 设定
%%%--------------------------------------

-define(sql_setting_update_setting, <<"UPDATE role_setting SET onhook='~s' WHERE id=~p">>).
-define(sql_setting_get_setting, <<"SELECT `onhook` FROM role_setting WHERE id=~p LIMIT 1">>).
-define(sql_setting_insert_setting, <<"INSERT INTO role_setting SET id=~p, onhook='~s'">>).
-define(ROLE_SETTING(RoleId), lists:concat(["role_setting_", RoleId])).
%% 挂机配置最长字符数
-define(ONHOOK_LENGTH, 950).
