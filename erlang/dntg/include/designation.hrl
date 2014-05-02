%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.19
%%% @Description: 称号
%%%--------------------------------------

%% 保存角色拥有称号的db表名称
-define(TABLE_ROLE_DESIGNATION, role_designation).
-define(DESIGN_GUILD_MASTER_ID, 201503).		%% 帮战胜利后，帮主获得的称号id
-define(DESIGN_GUILD_MEMBER_ID, 201651).		%% 帮战胜利后，帮众获得的称号id

-define(SQL_DESIGN_INSERT, <<"INSERT INTO role_designation SET role_id=~p, design_type=~p, design_id=~p, display=~p, replace_content='~s', get_time=~p, end_time=~p">>).
-define(SQL_DESIGN_GET_STAT, <<"SELECT design_id, design_type, user_id, user_name FROM role_designation_stat WHERE design_id=~p">>).
-define(SQL_DESIGN_DELETE_STAT, <<"DELETE FROM role_designation_stat WHERE design_id=~p">>).
-define(SQL_DESIGN_INSERT_STAT, <<"INSERT INTO role_designation_stat(design_id, design_type, user_id, user_name) VALUES (~p, ~p, ~p, '~s')">>).
-define(SQL_DESIGN_UPDATE_STAT, <<"UPDATE role_designation_stat SET user_id=~p, user_name='~s'  WHERE design_id=~p">>).
-define(SQL_DESIGN_DELETE, <<"DELETE FROM role_designation WHERE role_id=~p AND design_id=~p">>).
-define(SQL_DESIGN_DELETE2, <<"DELETE FROM role_designation WHERE design_id=~p">>).
-define(SQL_DESIGN_GET_ALL, <<"SELECT role_id, design_type, design_id, display, replace_content, get_time, end_time FROM role_designation WHERE role_id=~p">>).
-define(SQL_DESIGN_FETCH_ROW, <<"SELECT * FROM role_designation WHERE role_id=~p AND design_id=~p">>).
-define(SQL_DESIGN_UPDATE, <<"UPDATE role_designation SET display=~p, get_time=~p, end_time=~p WHERE role_id=~p AND design_id=~p">>).
-define(SQL_DESIGN_GET_ROLE_BY_DESIGN, <<"SELECT role_id FROM role_designation WHERE design_id=~p">>).
-define(SQL_DESIGN_CHANGE_REPLACE, <<"UPDATE role_designation SET replace_content='~s' WHERE role_id=~p AND design_id=~p">>).
-define(SQL_DESIGN_GET_BY_ROLE_TYPE, <<"SELECT role_id, design_type, design_id  FROM role_designation WHERE role_id=~p AND design_type=~p limit 1">>).
-define(SQL_DESIGN_UPDATE_BY_ROLE_TYPE, <<"UPDATE role_designation SET design_id=~p, get_time=~p WHERE role_id=~p AND design_type=~p">>).


%% 角色拥有的称号字段定义
-record(role_designation, {
	role_id = 0,				%% 角色id
	design_type = 0,			%% 称号类型
	design_id = 0,				%% 称号id
	display = 0,				%% 是否显示
	content = "",				%% 替换内容
	get_time = 0,				%% 获得时间
	end_time = 0				%% 显示结束时间
}).

%% 称号字段定义
-record(designation, {
	id = 0,						%% 称号id
	type = 0,					%% 类型，1图片称号，2纯文字称号，3动态文字称号
	name = <<"">>,	
	describe = <<"">>,
	sex_limit = -1,				%% 性别，0女，1男
	display = 0,				%% 是否显示
	notice = 0,
	onlyone = 0,
	time_limit = 0,
	overlying = 0,				%% 可否叠加，0不可，1可以
	att = 0,
	def = 0,
	hp = 0,
	mp = 0,
	forza = 0,
	agile = 0,
	wit = 0,
	hit = 0,
	dodge = 0,
	crit = 0,
	ten = 0,
	res = 0,
	thew = 0,
	addbase = 0,				%% 基础属性，会影响力量，敏捷，智力，体质
	fire = 0,
	ice = 0,
	drug = 0
}).
