%%%------------------------------------
%%% @Module     : lib_secondary_password
%%% @Author     : huangyongxing
%%% @Email      : huangyongxing@yeah.net
%%% @Created    : 2011.04.09
%%% @Description: 二级密码
%%%------------------------------------
-module(lib_secondary_password).
-export(
    [
        query_is_set_protected_info/1,  %% 查询是否设置过密保
        check_protected_while_login/1,  %% 登录时查询二级密码设置状态
        query_rest_times/3,         %% 查询删改剩余次数
        set_secondary_password/2,   %% 设置保护问题及二级密码
        is_pass/1,                  %% 查询登录后是否已经输入过正确密码
		is_pass_only_check/1,
        role_logout/1,              %% 角色下线清理ETS表
        get_protected_question/3,   %% 查询密码保护问题
        delete_password/3,          %% 删除密码
        change_password/4,          %% 修改密码
        enter_password/2            %% 输入密码
    ]).
-include("common.hrl").
-include("record.hrl").
-include("guild.hrl").
-include("server.hrl").

%% 每日计数器
-define(CHANGE_DAILY_TYPE, 2610).
-define(DELETE_DAILY_TYPE, 2611).

%% 每日上限
-define(CHANGE_DAILY_MAX, 5).
-define(DELETE_DAILY_MAX, 5).

%% 密码长度
-define(MIN_LEN_OF_PW, 5).
-define(MAX_LEN_OF_PW, 9).

%% 问题列表
get_question_list() ->
    [
        {1, <<"你所在小学的名字">>},
        {2, <<"你所在中学的名字">>},
        {3, <<"你所在大学的名字">>},
        {4, <<"你喜欢的人是谁">>},
        {5, <<"你喜欢什么颜色">>},
        {6, <<"你最喜欢的数字是什么">>},
        {7, <<"你最喜欢的单词是什么">>},
        {8, <<"你最喜欢的食物是什么">>},
        {9, <<"你最大的愿望是什么">>},
        {10, <<"你最想做的事情是什么">>}
    ].

load_protected_info_from_db(RoleId) ->
    Sql = lists:concat(["select `question1`, `question2`, `answer1`, `answer2`, `password` from `secondary_password` where id = ", RoleId, " limit 1"]),
    db:get_all(Sql).

%% 转换为ETS表记录形式 -> record()
trans_to_ets([RoleId, Q1, Q2, A1, A2, PW]) ->
	if 
		PW =/= <<>>->
			Is_pass = false;
		true->
			Is_pass = true
	end,
    #secondary_password{
        id = RoleId,
        is_pass = Is_pass,    %% 默认状态为未通过验证
        error_times = 0,
        question1 = Q1,
        question2 = Q2,
        answer1 = A1,
        answer2 = A2,
        password = PW
    }.

%% 检查二级密码设置状态（角色上线操作）
check_protected_while_login(RoleId) ->
    case load_protected_info_to_ets(RoleId) of
        false -> 0;
        Record ->
            case is_set_password(Record) of
                true -> 1;
                false -> 0
            end
    end.

%% 角色下线操作
role_logout(RoleId) ->
    ets:delete(?SECONDARY_PASSWORD, RoleId).

%% 从数据库中加载密保信息到ETS表 -> false | record()
load_protected_info_to_ets(RoleId) ->
    case (catch load_protected_info_from_db(RoleId)) of
        [[Q1, Q2, A1, A2, PW]] ->
            Record = trans_to_ets([RoleId, Q1, Q2, A1, A2, PW]),
            ets:insert(?SECONDARY_PASSWORD, Record),
            Record;
        [] ->     %% 查询到无二级密码信息时，也插入记录，便于判断
            Record = trans_to_ets([RoleId, 0, 0, <<>>, <<>>, <<>>]),
            ets:insert(?SECONDARY_PASSWORD, Record),
            Record;
        _ ->
            false
    end.

%% 查询角色的二级密码信息 -> false | record()
get_protected_info(RoleId) ->
    case ets:lookup(?SECONDARY_PASSWORD, RoleId) of
        [Record] ->
            Record;
        _ ->
            load_protected_info_to_ets(RoleId)
    end.

%% 查询是否设置过二级密码 -> [Result, IsSetAnswer, IsSetPassword]
query_is_set_protected_info(RoleId) ->
    case get_protected_info(RoleId) of
        false -> [0, 0, 0];     %% 查询出错
        Record ->
            IsSetAnswer =
            case is_set_protected_answer(Record) of
                true -> 1;      %% 已经设置
                false -> 0      %% 未曾设置
            end,
            IsSetPassword =
            case is_set_password(Record) of
                true -> 1;
                false -> 0
            end,
            [1, IsSetAnswer, IsSetPassword]
    end.

%% 查询删除或者修改剩余次数 -> integer()
query_rest_times(Dailypid,RoleId, Type) ->
    case Type of
        change -> ?CHANGE_DAILY_MAX - mod_daily:get_count(Dailypid,RoleId, ?CHANGE_DAILY_TYPE);
        _ ->      ?DELETE_DAILY_MAX - mod_daily:get_count(Dailypid,RoleId, ?DELETE_DAILY_TYPE)
    end.

check_length(Password, Answer1, Answer2) ->
    case util:check_length(Password, ?MIN_LEN_OF_PW, ?MAX_LEN_OF_PW) of
        true ->
            case util:check_length(Answer1, 1, 40) andalso util:check_length(Answer2, 1, 40) of
                true ->
                    true;
                false ->    %% 答案长度有误
                    {error, 6}
            end;
        false ->    %% 密码长度有误
            {error, 5}
    end.

%% 设置二级密码 -> ok | {error, ErrorCode}
set_secondary_password(RoleId, [Question1Id, Question2Id, Answer1, Answer2, Password]) ->
    case get_protected_info(RoleId) of
        false ->    %% 查询出错
            {error, 0};
        Record ->
            case is_set_protected_answer(Record) of
                true ->     %% 已经设置过密保
                    case is_set_password(Record) of
                        true ->     %% 已经设置过密码
                            {error, 2};
                        false ->
                            case is_valid_question_id(Question1Id, Question2Id) of
                                true ->
                                    case is_true_answer(Record, [Answer1, Answer2]) of
                                        true ->
                                            NewPassword = util:md5(Password),
                                            Sql = lists:concat(["update `secondary_password` set `password` = '", NewPassword, "' where id = ", RoleId, " limit 1"]),
                                            case (catch db:execute(Sql) ) of
                                                {'EXIT', _} ->
                                                    {error, 3};
                                                _ ->
                                                    BinPassword = object_to_binary(NewPassword),
                                                    NewRecord = Record#secondary_password{ password = BinPassword },
                                                    ets:insert(?SECONDARY_PASSWORD, NewRecord),
                                                    ok
                                            end;
                                        false ->
                                            {error, 7}
                                    end;
                                false ->
                                    {error, 4}
                            end
                    end;
                false ->    %% 首次设置密保
                    case is_valid_question_id(Question1Id, Question2Id) of
                        true ->
                            case check_length(Password, Answer1, Answer2) of
                                true ->
                                    NewAnswer1 = util:md5(Answer1),
                                    NewAnswer2 = util:md5(Answer2),
                                    NewPassword = util:md5(Password),
                                    Sql = lists:concat(["insert into `secondary_password` (`id`, `question1`, `question2`, `answer1`, `answer2`, `password`) values (", RoleId, ",", Question1Id, ",", Question2Id, ",'", NewAnswer1, "','", NewAnswer2, "','", NewPassword, "')"]),
                                    case (catch db:execute(Sql)) of
                                        {'EXIT', _} ->  %% 写入数据出错
                                            {error, 3};
                                        _ ->
                                            BinAnswer1 = object_to_binary(NewAnswer1),
                                            BinAnswer2 = object_to_binary(NewAnswer2),
                                            BinPassword = object_to_binary(NewPassword),
                                            NewRecord = trans_to_ets([RoleId, Question1Id, Question2Id, BinAnswer1, BinAnswer2, BinPassword]),
                                            ets:insert(?SECONDARY_PASSWORD, NewRecord),
                                            ok
                                    end;
                                {error, ErrorCode} ->
                                    {error, ErrorCode}
                            end;
                        false ->    %% 无效的问题Id
                            {error, 4}
                    end
            end
    end.

%% 验证问题Id是否有效 -> true | false
is_valid_question_id(QId, QId) ->
    false;
is_valid_question_id(QId1, QId2) ->
    AllQuestions = get_question_list(),
    lists:keymember(QId1, 1, AllQuestions) andalso lists:keymember(QId2, 1, AllQuestions).

%% 是否设置过密保
is_set_protected_answer(Record) ->
    Record#secondary_password.question1 =/= 0.

%% 检查是否设置过二级密码
is_set_password(Record) ->
    Record#secondary_password.password =/= <<>>.

%% 检查是否有效的答案 -> true | false
is_true_answer(Record, [A1, A2]) ->
    Answer1 = util:md5(A1),
    Answer2 = util:md5(A2),
    BinAnswer1 = object_to_binary(Answer1),
    BinAnswer2 = object_to_binary(Answer2),
    Record#secondary_password.answer1 =:= BinAnswer1 andalso Record#secondary_password.answer2 =:= BinAnswer2.

%% 检查是否正确密码 -> true | false
is_true_password(Record, Password) ->
    EncryptPassword = util:md5(Password),
    BinPassword = object_to_binary(EncryptPassword),
    Record#secondary_password.password =:= BinPassword.

%% 检查是否已经通过密码验证 -> true | false
is_pass(PlayerStatus) when is_record(PlayerStatus,player_status) ->
    case get_protected_info(PlayerStatus#player_status.id) of
        false ->    %% 查询二级密码出错，进行通知
            {ok, BinData} = pt_260:write(26016, 0),
            lib_server_send:send_to_uid(PlayerStatus#player_status.id, BinData),
            false;
        Record ->
            case Record#secondary_password.is_pass =:= true of
                false ->     %% 未验证
                    case is_set_password(Record) of
                        false ->    %% 未设置二级密码或者未设置密保
                            true;
                        true ->     %% 未通过验证，通知客户端弹出密码验证框
                            {ok, BinData} = pt_260:write(26016, 3),
                            lib_server_send:send_to_uid(PlayerStatus#player_status.id, BinData),
                            false
                    end;
                true ->     %% 已经验证过
                    true
            end
    end;
is_pass(_PlayerStatus)->false.%添加容错

%% 检查是否已经通过密码验证 -> true | false
is_pass_only_check(PlayerStatus) when is_record(PlayerStatus,player_status) ->
    case get_protected_info(PlayerStatus#player_status.id) of
        false ->    %% 查询二级密码出错，进行通知
            false;
        Record ->
            case Record#secondary_password.is_pass =:= true of
                false ->     %% 未验证
                    case is_set_password(Record) of
                        false ->    %% 未设置二级密码或者未设置密保
                            true;
                        true ->     %% 未通过验证，通知客户端弹出密码验证框
                            false
                    end;
                true ->     %% 已经验证过
                    true
            end
    end;
is_pass_only_check(_PlayerStatus)->false.%添加容错

object_to_binary(Term) when is_list(Term) -> list_to_binary(Term);
object_to_binary(Term) when is_binary(Term) -> Term;
object_to_binary(_) -> <<>>.

%% 查询密码保护问题(删除/再次设置密码) -> [Result, QId1, QId2, RestTimes]
get_protected_question(Dailypid,RoleId, Type) ->
    RestTimes = query_rest_times(Dailypid,RoleId, delete),
    case get_protected_info(RoleId) of
        false ->    %% 查询出错
            [0, 0, 0, RestTimes];
        Record ->
            case is_set_protected_answer(Record) of
                true ->
                    QId1 = Record#secondary_password.question1,
                    QId2 = Record#secondary_password.question2,
                    Result =
                    case Type of
                        0 -> 1;
                        _ -> 3
                    end,
                    [Result, QId1, QId2, RestTimes];
                false ->    %% 未设置密码及答案
                    [2, 0, 0, RestTimes]
            end
    end.

%% 删除二级密码 -> {ok, RestTimes} | {error, ErrorCode, RestTimes}
delete_password(Dailypid,RoleId, [Answer1, Answer2]) ->
    DailyTimes = mod_daily:get_count(Dailypid,RoleId, ?DELETE_DAILY_TYPE),
    NowRestTimes = ?DELETE_DAILY_MAX - DailyTimes,
    case NowRestTimes > 0 of
        true ->
            case get_protected_info(RoleId) of
                false ->    %% 查询出错
                    {error, 0, NowRestTimes};
                Record ->
                    case is_set_protected_answer(Record) of
                        true ->
                            case is_set_password(Record) of
                                true ->
                                    case is_true_answer(Record, [Answer1, Answer2]) of
                                        true ->
                                            case (catch change_password_on_db(RoleId, "") ) of
                                                {'EXIT', _} ->
                                                    {error, 2, NowRestTimes};
                                                _ ->
                                                    NewRecord = Record#secondary_password{password = <<>>},
                                                    ets:insert(?SECONDARY_PASSWORD, NewRecord),
                                                    mod_daily:increment(Dailypid,RoleId, ?DELETE_DAILY_TYPE),
                                                    {ok, NowRestTimes -1}
                                            end;
                                        false ->    %% 密保答案有误
                                            mod_daily:increment(Dailypid,RoleId, ?DELETE_DAILY_TYPE),
                                            {error, 3, NowRestTimes - 1}
                                    end;
                                false ->    %% 未设置密码
                                    {error, 4, NowRestTimes}
                            end;
                        false ->    %% 未设置过密保
                            {error, 6, NowRestTimes}
                    end
            end;
        false ->    %% 达到每天删除次数上限
            {error, 5, 0}
    end.

%% 修改二级密码 -> {ok, RestTimes} | {error, ErrorCode, RestTimes}
change_password(Dailypid,RoleId, OldPassword, NewPassword) ->
    DailyTimes = mod_daily:get_count(Dailypid,RoleId, ?CHANGE_DAILY_TYPE),
    NowRestTimes = ?CHANGE_DAILY_MAX - DailyTimes,
    case NowRestTimes > 0 of
        true ->
            case get_protected_info(RoleId) of
                false ->    %% 查询出错
                    {error, 0, NowRestTimes};
                Record ->
                    case is_set_protected_answer(Record) of
                        true ->
                            case is_true_password(Record, OldPassword) of
                                true ->     %% 原密码对
                                    case util:check_length(NewPassword, ?MIN_LEN_OF_PW, ?MAX_LEN_OF_PW) of
                                        true ->
                                            NewPassword2 = util:md5(NewPassword),
                                            case (catch change_password_on_db(RoleId, NewPassword2) ) of
                                                {'EXIT', _} ->
                                                    {error, 2, NowRestTimes};
                                                _ ->
                                                    BinNewPassword = object_to_binary(NewPassword2),
                                                    NewRecord = Record#secondary_password{password = BinNewPassword},
                                                    ets:insert(?SECONDARY_PASSWORD, NewRecord),
                                                    mod_daily:increment(Dailypid,RoleId, ?CHANGE_DAILY_TYPE),
                                                    {ok, NowRestTimes - 1}
                                            end;
                                        false ->    %% 长度有误
                                            {error, 6, NowRestTimes}
                                    end;
                                false ->    %% 密码错误
                                    mod_daily:increment(Dailypid,RoleId, ?CHANGE_DAILY_TYPE),
                                    {error, 3, NowRestTimes - 1}
                            end;
                        false ->    %% 未设置密保
                            {error, 4, NowRestTimes}
                    end
            end;
        false ->    %% 达到每天修改次数上限
            {error, 5, 0}
    end.

%% 修改二级密码
change_password_on_db(RoleId, NewPassword) ->
    Sql = lists:concat(["update `secondary_password` set `password` = '", NewPassword, "' where id =", RoleId, " limit 1"]),
    db:execute(Sql).

%% 输入密码 -> ok | {error, ErrorCode}
enter_password(RoleId, Password) ->
    case get_protected_info(RoleId) of
        false ->    %% 查询出错
            {error, 0};
        Record ->
            case Record#secondary_password.is_pass =:= true of
                true ->     %% 已经通过验证
                    {error, 4};
                false ->
                    case is_set_protected_answer(Record) of
                        true ->
                            case is_true_password(Record, Password) of
                                true ->
                                    NewRecord = Record#secondary_password{ is_pass = true, error_times = 0 },
                                    ets:insert(?SECONDARY_PASSWORD, NewRecord),
                                    ok;
                                false ->    %% 密码错误 TODO 一定次数踢下线
                                    {error, 2}
                            end;
                        false ->    %% 未设置过密保
                            {error, 3}
                    end
            end
    end.
