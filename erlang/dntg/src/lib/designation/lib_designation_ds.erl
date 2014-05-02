%%%--------------------------------------
%%% @Module  : lib_designation_ds
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.19
%%% @Description: 称号数据源模块，操作底层数据，方便以后优化这一块
%%%--------------------------------------

-module(lib_designation_ds).
-compile(export_all).
-include("server.hrl").
-include("designation.hrl").

%% 插入获得的称号
insert(RoleId, DesignType, DesignId, Display, ReplaceContent, GetTime, KeepTime) ->
	EndTime = case KeepTime > 0 of
		true -> GetTime + KeepTime;
		_ -> 0
	end,
	%% TODO
	InsertSql = <<"REPLACE INTO role_designation SET role_id=~p, design_type=~p, design_id=~p, display=~p, replace_content='~s', get_time=~p, end_time=~p">>,
	db:execute(
		io_lib:format(InsertSql, [RoleId, DesignType, DesignId, Display, ReplaceContent, GetTime, EndTime])
	).

%% 通过id获取当前玩家的称号
get_by_design_id(RoleId, DesignId) ->
	Sql = io_lib:format(?SQL_DESIGN_FETCH_ROW, [RoleId, DesignId]),
	case db:get_row(Sql) of
        [] -> 
            [];
        List when is_list(List) ->
			private_db_to_record(List);
        _ ->
            []
    end.

%% 从数据库读出列表
%% return [#role_designation,...]
get_all_by_role(RoleId) ->
	Sql = io_lib:format(?SQL_DESIGN_GET_ALL, [RoleId]),
	case db:get_all(Sql) of
        [] -> 
            [];
        List when is_list(List) ->
			NowTime = util:unixtime(),
			lists:foldl(fun([TTRoleId, DesignType, DesignId, Display, ReplaceContent, GetTime, EndTime], GetList) -> 
				%% 取消掉过期的称号
				case EndTime > 0 andalso EndTime < NowTime of
					true ->
						%% 去掉过期的称号
						lib_designation:remove_design_in_server(TTRoleId, DesignId),

						GetList;
					_ ->
						[private_db_to_record([TTRoleId, DesignType, DesignId, Display, ReplaceContent, GetTime, EndTime]) | GetList]
				end
			end, [], List);
        _ ->
            []
    end.

%% 更新称号
update_design(RoleDesign) ->
	Sql = io_lib:format(?SQL_DESIGN_UPDATE, [
		RoleDesign#role_designation.display,
		RoleDesign#role_designation.get_time,
		RoleDesign#role_designation.end_time,
		RoleDesign#role_designation.role_id,
		RoleDesign#role_designation.design_id
	]),
	db:execute(Sql).

%% 删除称号
delete_design_by_id(RoleId, DesignId) ->
	db:execute(
		io_lib:format(?SQL_DESIGN_DELETE, [RoleId, DesignId])  
	).

%% 获得称号统计数据
get_stat(DesignId) ->
	db:get_row(
		io_lib:format(?SQL_DESIGN_GET_STAT, [DesignId])  
	).

%% 插入称号统计数据
insert_stat(DesignId, DesignType, RoleId, NickName) ->
	db:execute(
		io_lib:format(?SQL_DESIGN_INSERT_STAT, [DesignId, DesignType, RoleId, NickName])  
	).

%% 插入称号统计数据
update_stat(DesignId, RoleId, NickName) ->
	db:execute(
		io_lib:format(?SQL_DESIGN_UPDATE_STAT, [RoleId, NickName, DesignId])  
	).

%% 通过称号id删除所有统计记录
delete_stat_by_designid(DesignId) ->
	db:execute(
		io_lib:format(?SQL_DESIGN_DELETE_STAT, [DesignId])  
	).

%% 将DBRow记录转成#role_designation
private_db_to_record(DBRow) ->
	[RoleId, DesignType, DesignId, Display, Content, GetTime, EndTime] = DBRow,
	#role_designation{
		role_id = RoleId,
		design_type = DesignType,
		design_id = DesignId,
		display = Display,
		content = Content,
		get_time = GetTime,
		end_time = EndTime
	}.

%% 根据玩家id和称号类型提取称号数据
get_design_by_role_type(RoleId, Type)->
    SeSQL = io_lib:format(?SQL_DESIGN_GET_BY_ROLE_TYPE, [RoleId, Type]),
    db:get_all(SeSQL). 

%% 根据玩家id和称号类型更新称号数
update_design_by_role_type(DesignId, GetTime, RoleId, Type)->  
    UpSQL = io_lib:format(?SQL_DESIGN_UPDATE_BY_ROLE_TYPE, [DesignId, GetTime, RoleId, Type]),
    db:execute(UpSQL).













