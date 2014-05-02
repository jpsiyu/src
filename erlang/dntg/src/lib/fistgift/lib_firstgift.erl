%%%-------------------------------------------------------------------
%%% @Module	: lib_firstgift
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 18 Jul 2012
%%% @Description: 首服礼包
%%%-------------------------------------------------------------------
-module(lib_firstgift).
-include("common.hrl").
-compile(export_all).

%%=========================================================================
%% SQL定义
%%=========================================================================
-define(SQL_FG_SELECT,                    "select is_get from first_gift where player_id=~p LIMIT 1").
-define(SQL_FG_INSERT,                    "insert into first_gift(player_id, acc_name, phone, email, is_get) values(~p, '~s', '~s', '~s', ~p)").

%% 西行礼包
-define(SQL_VG_SELECT,                    "select `is_get` from visit_gift where player_id=~p LIMIT 1").
-define(SQL_VG_INSERT,                    "insert into visit_gift(`player_id`, `acc_name`, `activity`, `update`, `charge`, `t1`, `t2`, `t3`, `phone`, `is_get`,`timestamp`) values(~p, '~s', ~p, ~p, ~p, ~p, ~p, ~p, '~s', ~p, ~p)").


%% -----------------------------------------------------------------
%% 角色登录
%% -----------------------------------------------------------------
check_get(PlayerId) ->
    %% SQL  = io_lib:format(?SQL_FG_SELECT, [PlayerId]),
    SQL  = io_lib:format(?SQL_VG_SELECT, [PlayerId]),
    case db:get_one(SQL) of
	1 ->
	    true;
	_ ->
	    false
    end.
put_to_db(Record) ->
    %% SQL  = io_lib:format(?SQL_FG_INSERT, Record),
    SQL  = io_lib:format(?SQL_VG_INSERT, Record),
    db:execute(SQL).

login_send(Id, Lv) ->
    spawn(fun() -> 
		  login_send(Id, Lv, delay),
		  timer:sleep(10000),
		  login_send(Id, Lv, delay),
		  timer:sleep(10000),
		  login_send(Id, Lv, delay) end).

login_send(Id, Lv, delay) ->
    case Lv >= 35 of
	true ->
	    case check_get(Id) of
		false ->
		    %% 未到级数，发送图标
		    {ok, BinData} = pt_316:write(31601, []),
		    lib_unite_send:send_to_one(Id, BinData);
		true ->
		    []
	    end;
	false ->
	    []
    end.
	    
%% -----------------------------------------------------------------
%% 检查手机号,使用正则表达式
%% -----------------------------------------------------------------
validate_phone(Phone) ->
    ValidPhone = make_sure_list(Phone),
    %% Reg = "^0{0,1}(13[4-9]|15[7-9]|15[0-2]|18[7-8])[0-9]{8}$",
    Reg = "^0{0,1}(13[0-9]|15[0-9]|147|18[0-9])[0-9]{8}$", %新增的联通号，电信号段,移动TD-SCDMA
    case re:run(ValidPhone, Reg) of
	nomatch -> false;
	_ -> true
    end.
%% -----------------------------------------------------------------
%% 检查邮箱,使用正则表达式
%% -----------------------------------------------------------------
validate_email(Email) ->
    ValidEmail = make_sure_list(Email),
    Reg = "^([a-zA-Z0-9]+[_|\-|\.]?)*[a-zA-Z0-9]+@([a-zA-Z0-9]+[_|\-|\.]?)*[a-zA-Z0-9]+\.[a-zA-Z]{2,3}$",
    case re:run(ValidEmail, Reg) of
	nomatch -> false;
	_ -> true
    end.
%% -----------------------------------------------------------------
%% 确保字符串类型为二进制
%% -----------------------------------------------------------------
make_sure_binary(String) ->
    case is_binary(String) of
        true  -> String;
        false when is_list(String) -> list_to_binary(String);
        false ->
            ?ERR("make_sure_binary: Error string=[~w]", [String]),
            String
    end.

%% -----------------------------------------------------------------
%% 确保字符串类型为列表
%% -----------------------------------------------------------------
make_sure_list(String) ->
    case is_list(String) of
        true  -> String;
        false when is_binary(String) -> binary_to_list(String);
        false ->
            ?ERR("make_sure_list: Error string=[~w]", [String]),
            String
    end.
