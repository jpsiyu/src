%%%--------------------------------------
%%% @Module  : lib_fcm
%%% @Author  : shebiao
%%% @Email   : shebiao@jieyou.com
%%% @Created : 2010.09.28
%%% @Description : 防沉迷
%%%--------------------------------------
-module(lib_fcm).
-include("common.hrl").
-compile(export_all).

%%=========================================================================
%% 一些定义
%%=========================================================================
%-define(DEFINE_FCM_HALF_EXP_TIME,          3*60*60). % 收益减半时间
-define(DEFINE_FCM_ZERO_EXP_TIME,          3*60*60). % 收益置0时间
-define(DEFINE_FCM_RESET_OFFLINE_TIME,     5*60*60). % 收入恢复的离线时间

%-define(DEFINE_FCM_HALF_EXP_TIME,          5*60). % 收益减半时间
%-define(DEFINE_FCM_ZERO_EXP_TIME,          10*60). % 收益置0时间
%-define(DEFINE_FCM_RESET_OFFLINE_TIME,     3*60). % 收入恢复的离线时间

%%=========================================================================
%% SQL定义
%%=========================================================================

%% -----------------------------------------------------------------
%% 防沉迷表SQL
%% -----------------------------------------------------------------
-define(SQL_FCM_SELECT_FCM_INFO,           "select name, id_card_no, under_age_flag from fcm where id=~p LIMIT 1").
%-define(SQL_FCM_INSERT,                    "insert into fcm(id, name, id_card_no, under_age_flag, create_time) values(~p, '~s', '~s', ~p, ~p)").
-define(SQL_FCM_INSERT2,                   "insert into fcm(id, name, id_card_no, under_age_flag, is_reg, create_time) values(~p, '~s', '~s', ~p, ~p, ~p)").
-define(SQL_FCM_DELETE,                    "delete from fcm where id=~p").
-define(SQL_FCM_UPDATE,                    "update fcm set under_age_flag=~p, is_reg=~p where id=~p ").

%% -----------------------------------------------------------------
%% 角色表SQL
%% -----------------------------------------------------------------
-define(SQL_PLAYER_LOGIN_SELECT_FCM_INFO,  "select last_login_time, last_logout_time, fcm_online_time, fcm_offline_time from player_login where id=~p LIMIT 1").
-define(SQL_PLAYER_LOGIN_UPDATE_FCM_INFO,  "update player_login set last_logout_time=~p, fcm_online_time=~p, fcm_offline_time=~p where id=~p").

%%=========================================================================
%% 初始化回调函数
%%=========================================================================

%% -----------------------------------------------------------------
%% 角色登录
%% -----------------------------------------------------------------
role_login(PlayerId) ->
    %% 从player_low表获取离线信息
    SQL1 = io_lib:format(<<"select last_login_time, logout_time, fcm_online_time, fcm_offline_time from player_login where id=~p LIMIT 1">>, [PlayerId]),
    [LastLoginTime, LastLogoutTime, OnlineTime, OfflineTime] = db:get_row(SQL1),
    %% 用户是否已在服务器登记
	SQL2  = io_lib:format(<<"select name, id_card_no, under_age_flag from fcm where id=~p LIMIT 1">>, [PlayerId]),
	case db:get_row(SQL2) of
        [] ->
            _Name = <<>>,
            _IdCardNo = <<>>,
			UnderAgeFlag = 1,
            %% 写入数据库
            SQL3 = io_lib:format(<<"insert into fcm set id = ~p, under_age_flag = 1">>, [PlayerId]),
            db:execute(SQL3),
            State = 0;
		[_Name, _IdCardNo, _UnderAgeFlag] ->
			UnderAgeFlag = _UnderAgeFlag,
            State = case length(binary_to_list(_IdCardNo)) of
                0 -> 0;
                _ -> 1
            end
    end,
    %% 判断是否已过1天
    NowTime = util:unixtime(),
    TempOfflineTime = case LastLogoutTime of
                         % 首次登录
                         0 -> ?DEFINE_FCM_RESET_OFFLINE_TIME;
                         % 非首次登录
                         _ -> OfflineTime+NowTime-LastLogoutTime
                     end,
    %% 对未成年人进行处理
	%% 0 获取身份失败
    %% 1 身份已经提交
    %% 2 身份未提交
    case UnderAgeFlag of
        0 -> skip;
        _ ->
            case TempOfflineTime >= ?DEFINE_FCM_RESET_OFFLINE_TIME of
                % 重新累计
                true  -> 
                    mod_fcm:insert(PlayerId, LastLoginTime, 0, 0, State, 0, _Name, _IdCardNo),
                    SQL4  = io_lib:format(<<"update player_login set fcm_online_time = 0, fcm_offline_time = 0 where id = ~p">>, [PlayerId]),
                    db:execute(SQL4);
                % 继续累计
                false -> 
                    %% 可能会出现负数情况，当服务器时间比最近登录时间小时
                    case OnlineTime > 0 of
                        true -> OnlineTime1 = OnlineTime;
                        false -> OnlineTime1 = 0
                    end,
                    case TempOfflineTime > 0 of
                        true -> TempOfflineTime1 = TempOfflineTime;
                        false -> TempOfflineTime1 = 0
                    end,
                    mod_fcm:insert(PlayerId, LastLoginTime, OnlineTime1, TempOfflineTime1, State, 0, _Name, _IdCardNo),
                    SQL4  = io_lib:format(<<"update player_login set fcm_online_time = ~p, fcm_offline_time = ~p where id = ~p">>, [OnlineTime1, TempOfflineTime1, PlayerId]),
                    db:execute(SQL4)
            end
    end,
    %% 是否第二天登录
    Date1 = date(),
	{Date2, _Time2} = util:seconds_to_localtime(LastLogoutTime),
    case Date1 =:= Date2 of
        true ->
            skip;
        false ->
            %% 每天进行清0处理
            SQL5  = io_lib:format(<<"update player_login set fcm_online_time = 0, fcm_offline_time = 0 where id = ~p">>, [PlayerId]),
            db:execute(SQL5),
            case UnderAgeFlag of
                0 -> skip;
                _ -> mod_fcm:insert(PlayerId, LastLoginTime, 0, 0, State, 0, _Name, _IdCardNo)
            end
    end.

%% -----------------------------------------------------------------
%% 角色退出
%% -----------------------------------------------------------------
role_logout(PlayerId, LastLoginTime, OnlineTime, OfflineTime) ->
	%% 用户是否已在服务器登记
	SQL2  = io_lib:format(?SQL_FCM_SELECT_FCM_INFO, [PlayerId]),
	case db:get_row(SQL2) of
        [] ->
			UnderAgeFlag = 1;
		[_Name, _IdCardNo, _UnderAgeFlag] ->
			UnderAgeFlag = _UnderAgeFlag
	end,
	%% 对未成年人进行处理
	case UnderAgeFlag of
		0 -> skip;
		_ ->
    		% 计算上线以来的时间并进行累加
    		NowTime       = util:unixtime(),
    		NewOnlineTime = OnlineTime + NowTime - LastLoginTime,
			%% 可能会出现负数情况，当服务器时间比最近登录时间小时
			case NewOnlineTime > 0 of
				true -> NewOnlineTime1 = NewOnlineTime;
				false -> NewOnlineTime1 = 0
			end,
			case OfflineTime > 0 of
				true -> OfflineTime1 = OfflineTime;
				false -> OfflineTime1 = 0
			end,
    		Data = [NowTime, NewOnlineTime1, OfflineTime1, PlayerId],
    		SQL  = io_lib:format(?SQL_PLAYER_LOGIN_UPDATE_FCM_INFO, Data),
			mod_fcm:delete(PlayerId),
    		%?DEBUG("role_logout: SQL=[~s]", [SQL]),
    		db:execute(SQL)
	end.

%% 时间戳转为日期
timestamp_to_datetime(Timestamp) ->
    Seconds1 = calendar:datetime_to_gregorian_seconds({{1970,1,1}, {8,0,0}}),
    Seconds2 = Timestamp + Seconds1,
    calendar:gregorian_seconds_to_datetime(Seconds2).

%% -----------------------------------------------------------------
%% 角色删除
%% -----------------------------------------------------------------
delete_role(PlayerId) ->
    Data = [PlayerId],
    SQL  = io_lib:format(?SQL_FCM_DELETE, Data),
	mod_fcm:delete(PlayerId),
    %?DEBUG("delete_role: SQL=[~s]", [SQL]),
    db_sql:execute(SQL),
    ok.

%%=========================================================================
%% 业务处理函数
%%=========================================================================

%% -----------------------------------------------------------------
%% 沉迷身份获取
%% -----------------------------------------------------------------
%get_fcm_info(PlayerId) ->
%    %?DEBUG("get_fcm_info: PlayerId=[~p]", [PlayerId]),
%    Data = [PlayerId],
%    SQL  = io_lib:format(?SQL_FCM_SELECT_FCM_INFO, Data),
%    %?DEBUG("get_fcm_info: SQL=[~s]", [SQL]),
%    FcmInfo = db_sql:get_row(SQL),
%    case FcmInfo of
%        [] ->
%            null;
%        _ ->
%            [Name, IdCardNo, UnderAgeFlag] = FcmInfo,
%            [ok, Name, IdCardNo, UnderAgeFlag]
%    end.

%% 实名注册状态, 0 表示未填写实名信息  1 表示填写了实名信息且已经成年  2 表示填写了实 名但未成年
get_fcm_info(PlayerId, IsReg) ->
    case mod_fcm:get_by_id(PlayerId) of
        %% 内存找到玩家信息，玩家未成年
        {_LastLoginTime, _OnLineTime, _OffLineTime, _State, _WriteSql, Name, IdCardNo} ->
            %% 0 获取身份失败
            %% 1 身份已经提交
            %% 2 身份未提交
            %% 3 身份已提交且为未成年人，因累计离线时间不够禁止游戏。
            %% 4 身份未提交，因累计离线时间不够禁止游戏。
            case calc_fcm_state(util:unixtime() - _LastLoginTime + _OnLineTime) of
                %% 已进入非健康时间
                2 -> 
                    case IsReg of
                        0 ->
                            %% 在我们服务器注册
                            case _State of
                                %% 未注册
                                0 ->
                                    [4, Name, IdCardNo, 1];
                                %% 已注册
                                _ ->
                                    [3, Name, IdCardNo, 1]
                            end;
                        1 -> 
                            mod_fcm:delete(PlayerId),
                            [1, Name, IdCardNo, 0];
                        2 ->
                            [3, Name, IdCardNo, 1]
                    end;
                %% 未进入非健康时间
                0 -> 
                    case IsReg of
                        0 -> 
                            %% 在我们服务器注册
                            case _State of
                                %% 未注册
                                0 ->
                                    [2, Name, IdCardNo, 1];
                                %% 已注册
                                _ ->
                                    [1, Name, IdCardNo, 1]
                            end;
                        1 ->
                            mod_fcm:delete(PlayerId),
                            [1, Name, IdCardNo, 0];
                        2 -> 
                            [1, Name, IdCardNo, 1]
                    end
            end;
        %% 内存找不到玩家信息，玩家已成年已提交
        _ -> 
            [1, <<>>, <<>>, 0]
    end.

%% -----------------------------------------------------------------
%% 沉迷身份提交
%% -----------------------------------------------------------------
submit_fcm_info(PlayerId, Name, IdCardNo, UnderAgeFlag, IsReg) ->
    %% 如果已在平台提交过，则跳过
    case IsReg of
        0 ->
            case mod_fcm:get_by_id(PlayerId) of
                %% 内存无数据，已成年，不用再提交
                undefined ->
                    Res = 0;
                %% 内在有数据，未成年，可提交
                {_LastLoginTime, _OnLineTime, _OffLineTime, _State, _WriteSql, _Name, _IdCardNo} ->
                    NowTime = util:unixtime(),
                    SQL2  = io_lib:format(<<"update fcm set name = '~s', id_card_no = '~s', under_age_flag = ~p, is_reg = ~p, create_time = ~p where id = ~p">>, [Name, IdCardNo, UnderAgeFlag, IsReg, NowTime, PlayerId]),
                    db:execute(SQL2),
                    case UnderAgeFlag of
                        %% 更新内存
                        1 ->
                            mod_fcm:insert(PlayerId, _LastLoginTime, _OnLineTime, _OffLineTime, 1, _WriteSql, _Name, _IdCardNo);
                        %% 已成年，从内存删去
                        0 ->
                            mod_fcm:delete(PlayerId)
                    end,
                    Res = 1
            end;
        _ -> 
            Res = 0
    end,
    Res.

%% 0 健康时间通知（每1小时一次）
%% 2 非健康时间通知（每15分钟一次）
calc_fcm_state(OnlineTime) ->
    ZeroExpTime = case application:get_env(fcm_max_value) of
                      {ok, Value2} -> Value2;
                      _ -> ?DEFINE_FCM_ZERO_EXP_TIME
                  end,
    if  OnlineTime >= ZeroExpTime -> 2;
        true -> 0
    end.

%% 客户端请求玩家在线时间
execute_42003(Id) ->
    NowTime = util:unixtime(),
    case mod_fcm:get_by_id(Id) of
        undefined -> skip;
        {_LastLoginTime, _OnlineTime, _OffLineTime, _State, _WriteSql, _Name, _IdCardNo} ->
            %io:format("NowTime:~p, _LastLoginTime:~p, _OnlineTime:~p~n", [NowTime, _LastLoginTime, _OnlineTime]),
            OnlineTime = NowTime - _LastLoginTime + _OnlineTime,
            %io:format("OnlineTime:~p~n", [OnlineTime]),
            %% 可能会出现负数情况，当服务器时间比最近登录时间小时
            case OnlineTime > 0 of
                true -> OnlineTime1 = OnlineTime;
                false -> OnlineTime1 = 0
            end,
            case _OffLineTime > 0 of
                true -> _OffLineTime1 = _OffLineTime;
                false -> _OffLineTime1 = 0
            end,
            case lib_fcm:calc_fcm_state(OnlineTime1) of
                %% 1小时
                0 ->
                    mod_fcm:insert(Id, NowTime, OnlineTime1, _OffLineTime1, _State, _WriteSql, _Name, _IdCardNo),
                    FcmTime1 = 60 * 60,
                    case OnlineTime1 > FcmTime1 andalso OnlineTime1 - (OnlineTime1 div FcmTime1) * FcmTime1 > 0 andalso OnlineTime1 - (OnlineTime1 div FcmTime1) * FcmTime1 < 120 of
                        true ->
                            %io:format("2min~n"),
                            case _State of
                                0 ->
                                    {ok, BinData} = pt_420:write(42003, [0, 0, OnlineTime1]);
                                _ ->
                                    {ok, BinData} = pt_420:write(42003, [2, 0, OnlineTime1])
                            end,
                            %io:format("0, OnlineTime:~p~n", [OnlineTime1]),
                            lib_server_send:send_to_uid(Id, BinData);
                        false -> skip
                    end,
                    %% 还有5分钟时发一次提示
                    case ?DEFINE_FCM_ZERO_EXP_TIME - OnlineTime1 < 6 * 60 andalso ?DEFINE_FCM_ZERO_EXP_TIME - OnlineTime1 > 4 * 60 of
                        false -> skip;
                        true -> 
                            case _State of
                                0 ->
                                    {ok, BinData2} = pt_420:write(42003, [0, 0, OnlineTime1]);
                                _ ->
                                    {ok, BinData2} = pt_420:write(42003, [2, 0, OnlineTime1])
                            end,
                            %io:format("0-2, OnlineTime:~p~n", [OnlineTime1]),
                            lib_server_send:send_to_uid(Id, BinData2)
                    end;
                %% 15分钟
                2 ->
                    mod_fcm:insert(Id, NowTime, OnlineTime1, _OffLineTime1, _State, _WriteSql, _Name, _IdCardNo),
                    FcmTime2 = 15 * 60,
                    case OnlineTime1 > FcmTime2 andalso OnlineTime1 - (OnlineTime1 div FcmTime2) * FcmTime2 > 0 andalso OnlineTime1 - (OnlineTime1 div FcmTime2) * FcmTime2 < 120 of
                        true ->
                            %io:format("1min~n"),
                            case _State of
                                %% 身份未提交
                                0 ->
                                    {ok, BinData} = pt_420:write(42003, [2, 2, OnlineTime1]);
                                %% 身份已提交
                                _ ->
                                    {ok, BinData} = pt_420:write(42003, [1, 2, OnlineTime1])
                            end,
                            %io:format("2, OnlineTime:~p~n", [OnlineTime1]),
                            lib_server_send:send_to_uid(Id, BinData);
                        false -> skip
                    end;
                _ -> skip
            end
    end.



%%=========================================================================
%% 工具函数
%%=========================================================================

%% -----------------------------------------------------------------
%% 检查身份证号的有效性
%% 注意:位数可以15或18。
%% -----------------------------------------------------------------
validate_idcard(IdCardNo) ->
    Len =  string:len(IdCardNo),
    % 必须为15位或18位
    case Len == 15 orelse Len == 18 of
        true ->
            % 必须全为数字
            case validate_idcard_number(IdCardNo) of
                true ->
                    NewIdCardNo = change_idcard_15to18(IdCardNo),
                    % 其中的出生日期和校验码必须有效
                    case validate_idcard_date(NewIdCardNo) andalso validate_idcard_checksum(NewIdCardNo) of
                        true  -> true;
                        false -> false
                    end;
                false -> false
            end;
        false -> false
    end.

validate_name(Name) ->
    util:check_length(Name, 12).

%% -----------------------------------------------------------------
%% 检查身份证号数字位
%% -----------------------------------------------------------------
validate_idcard_number(IdCardNo) ->
    validate_idcard_number_helper(IdCardNo, 1).
validate_idcard_number_helper([], _Count) ->
    true;
validate_idcard_number_helper(IdCardNo, Count) ->
    [CardNo|LeftCardNo] = IdCardNo,
    case  Count == 17 of
        true  -> true;
        false ->
            case CardNo >= 48 andalso CardNo =< 57 of
                true  ->
                    validate_idcard_number_helper(LeftCardNo, Count+1);
                false ->
                    false
            end
    end.

%% -----------------------------------------------------------------
%% 校验身份证中的出生日期
%% -----------------------------------------------------------------
validate_idcard_date(IdCardNo) ->
    [BirthYear, BirthMonth, Birthday] = get_idcard_date(IdCardNo),
    {{NowYear, NowMonth, NowDay}, {_Hour, _Min, _Sec}} = calendar:local_time(),
    case BirthYear >= NowYear andalso BirthMonth >= NowMonth andalso Birthday >= NowDay of
        true -> false;
        false when  BirthYear =< 1850 -> false;
        false when  BirthMonth =< 0 orelse BirthMonth >= 13 -> false;
        false when  Birthday   =< 0 orelse Birthday   >= 32 -> false;
        false -> true
    end.

%% -----------------------------------------------------------------
%% 校验身份证中的校验值
%% -----------------------------------------------------------------
validate_idcard_checksum(IdCardNo) ->
    Prefix   = string:sub_string(IdCardNo, 1, 17),
    Checksum = string:sub_string(IdCardNo, 18, 18),
    case Checksum =:= calc_idcard_checksum(Prefix) of
        true  -> true;
        false -> false
    end.

%% -----------------------------------------------------------------
%% 获得身份证中的出生日期
%% -----------------------------------------------------------------
get_idcard_date(IdCardNo) ->
    BirthYearStr   = string:sub_string(IdCardNo, 7, 10),
    BirthMonthStr  = string:sub_string(IdCardNo, 11, 12),
    BirthdayStr    = string:sub_string(IdCardNo,13, 14),
    {BirthYear,_}  = string:to_integer(BirthYearStr),
    {BirthMonth,_} = string:to_integer(BirthMonthStr),
    {Birthday,_}   = string:to_integer(BirthdayStr),
    [BirthYear, BirthMonth, Birthday].

%% -----------------------------------------------------------------
%% 判断是否未成年
%% -----------------------------------------------------------------
is_idcard_under_age(IdCardNo) ->
    [BirthYear, BirthMonth, Birthday] = get_idcard_date(IdCardNo),
    {{NowYear, NowMonth, NowDay}, {_Hour, _Min, _Sec}} = calendar:local_time(),
    Age = NowYear - BirthYear + 1,
    case Age > 18 of
        true -> false;
        false when Age < 18 -> true;
        false when Age == 18 ->
            case BirthMonth >= NowMonth andalso Birthday >= NowDay of
                true -> false;
                false -> true
            end
    end.

%% -----------------------------------------------------------------
%% 将15位身份证升级到18位
%% -----------------------------------------------------------------
change_idcard_15to18(IdCardNo) ->
    case string:len(IdCardNo) of
        18 ->
            IdCardNo;
        _ ->
    	    Address  = string:sub_string(IdCardNo, 1, 6),
            Birthday = string:sub_string(IdCardNo, 7, 12),
            SeqCode  = string:sub_string(IdCardNo, 13, 15),
            IdCardTemp = case SeqCode =:= "996" orelse SeqCode =:="997" orelse SeqCode =:="998" orelse SeqCode =:="999"of
                             % 如果身份证顺序码是996 997 998 999，这些是为百岁以上老人的特殊编码
                             true ->
                                 Address++"18"++Birthday++SeqCode;
                             false ->
                                 Address++"19"++Birthday++SeqCode
                         end,
            CheckSum = calc_idcard_checksum(IdCardTemp),
            IdCardTemp++CheckSum
    end.

%% -----------------------------------------------------------------
%% 根据身份证前17位获得校验码
%% -----------------------------------------------------------------
calc_idcard_checksum(IdCardNo) ->
   calc_idcard_checksum_helper(IdCardNo, 0, 1).
calc_idcard_checksum_helper([], CheckSum, _Count) ->
    CheksumList = ["1", "0", "X", "9", "8", "7", "6", "5", "4", "3", "2"],
    Index = (CheckSum rem 11) + 1,
    lists:nth(Index, CheksumList);
calc_idcard_checksum_helper(IdCardNo, CheckSum, Count) ->
    FactorList  = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2],
    [CardNo|LeftCardNo] = IdCardNo,
    No     = CardNo-48,
    Factor = lists:nth(Count, FactorList),
    calc_idcard_checksum_helper(LeftCardNo, CheckSum+No*Factor, Count+1).
    
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
