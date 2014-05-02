%%%------------------------------------
%%% @Module  : timer_marriage
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.25
%%% @Description: 结婚(1分钟)
%%%------------------------------------
-module(timer_marriage).
-export([init/0, handle/1, terminate/2]).
-include("common.hrl").

%%=========================================================================
%% 一些定义
%% TODO: 定义模块状态。
%%=========================================================================

%%=========================================================================
%% 回调接口
%% TODO: 实现回调接口。
%%=========================================================================

%% -----------------------------------------------------------------
%% @desc     启动回调函数，用来初始化资源。
%% @param
%% @return  {ok, State}     : 启动正常
%%           {ignore, Reason}: 启动异常，本模块将被忽略不执行
%%           {stop, Reason}  : 启动异常，需要停止所有后台定时模块
%% -----------------------------------------------------------------
init() ->
    {ok, 0}.

%% -----------------------------------------------------------------
%% @desc     服务回调函数，用来执行业务操作。
%% @param    State          : 初始化或者上一次服务返回的状态
%% @return  {ok, NewState}  : 服务正常，返回新状态
%%           {ignore, Reason}: 服务异常，本模块以后将被忽略不执行，模块的terminate函数将被回调
%%           {stop, Reason}  : 服务异常，需要停止所有后台定时模块，所有模块的terminate函数将被回调
%% -----------------------------------------------------------------
handle(State) ->
    proc_contr(),
    {ok, State}.

%% -----------------------------------------------------------------
%% @desc     停止回调函数，用来销毁资源。
%% @param    Reason        : 停止原因
%% @param    State         : 初始化或者上一次服务返回的状态
%% @return   ok
%% -----------------------------------------------------------------
terminate(Reason, State) ->
    ?DEBUG("================Terming..., Reason=[~w], Statee = [~w]", [Reason, State]),
    ok.

%%=========================================================================
%% 业务处理
%% TODO: 实现业务处理。
%%=========================================================================

%% -----------------------------------------------------------------
%% 每1分钟检查一次
%% -----------------------------------------------------------------
%% 流程控制
proc_contr() -> 
    %% 处理离婚事务
    mod_marriage:deal_divorce(),
    %% 清除活动数据
    {_Year, _Month, _Day} = date(),
    {_Hour, _Min, _Sec} = time(),
    {{_BeginYear1, _BeginMonth1, _BeginDay1}, {_BeginHour1, _BeginMin1, _BeginSec1}} = data_marriage:get_marriage_config(activity_begin1),
    {{_EndYear1, _EndMonth1, _EndDay1}, {_EndHour1, _EndMin1, _EndSec1}} = data_marriage:get_marriage_config(activity_end1),
    {{_BeginYear2, _BeginMonth2, _BeginDay2}, {_BeginHour2, _BeginMin2, _BeginSec2}} = data_marriage:get_marriage_config(activity_begin2),
    {{_EndYear2, _EndMonth2, _EndDay2}, {_EndHour2, _EndMin2, _EndSec2}} = data_marriage:get_marriage_config(activity_end2),
    case {_BeginYear1, _BeginMonth1, _BeginDay1, _BeginHour1, _BeginMin1} =:= {_Year, _Month, _Day, _Hour, _Min} orelse {_EndYear1, _EndMonth1, _EndDay1, _EndHour1, _EndMin1} =:= {_Year, _Month, _Day, _Hour, _Min} orelse {_BeginYear2, _BeginMonth2, _BeginDay2, _BeginHour2, _BeginMin2} =:= {_Year, _Month, _Day, _Hour, _Min} orelse {_EndYear2, _EndMonth2, _EndDay2, _EndHour2, _EndMin2} =:= {_Year, _Month, _Day, _Hour, _Min} of
        true ->
            db:execute(<<"delete from marriage_activity">>);
        false ->
            skip
    end,
    %% 喜宴或巡游时段初始化（每日0点清空）
    case {_Hour, _Min} =:= {0, 0} of
        true ->
            mod_marriage:clear_wedding_cruise_list();
        false ->
            skip
    end,
    %% 喜宴或巡游时段超时（每小时整理）
    case _Min of
        16 ->
            mod_marriage:set_overtime();
        46 ->
            mod_marriage:set_overtime();
        _ ->
            skip
    end,
    case _Hour >= 9 andalso _Hour =< 21 of
        true ->
            %% 婚宴
            List1 = mod_marriage:get_all_wedding(),
            %% 预约婚礼前10分钟
            case _Min >= 50 of
                true ->
                    case _Min of
                        %% 给双方发邮件提醒
                        50 ->
                            lib_marriage:send_email_notice(List1);
                        _ ->
                            skip
                    end,
                    %% 倒计时
                    lib_marriage:send_countdown(List1);
                false ->
                    skip
            end,
            case _Min =< 30 of
                true -> 
                    %io:format("List2:~p, _Min:~p~n", [List2, _Min]),
                    case _Min of
                        %% 婚礼开始
                        0 -> 
                            lib_marriage:send_countdown2(List1, 0),
                            %% 清除气氛值
                            mod_marriage:clear_mood();
                        %% 结束前5分钟
                        25 ->
                            lib_marriage:before_end(List1);
                        %% 婚礼结束
                        30 -> 
                            lib_marriage:send_all_out(List1);
                        _ ->
                            skip
                    end,
                    %% 婚宴剩余时间
                    lib_marriage:send_resttime(List1);
                false ->
                    skip
            end,

            %% 巡游
            List2 = mod_marriage:get_all_cruise(),
            %io:format("List2:~p~n", [List2]),
            %% 巡游前5分钟
            case _Min >= 25 andalso _Min < 30 of
                true ->
                    case _Min of
                        %% 给双方发邮件提醒
                        25 ->
                            lib_marriage_cruise:send_email_notice(List2);
                        _ ->
                            skip
                    end,
                    %% 倒计时
                    lib_marriage_cruise:send_countdown(List2);
                false ->
                    skip
            end,
            %% 巡游
            case _Min >= 30 of
                true ->
                    case _Min of
                        30 ->
                            lib_marriage_cruise:send_countdown2(List2, 0);
                        _ ->
                            skip
                    end,
                    %% 倒计时
                    lib_marriage_cruise:send_resttime(List2);
                false ->
                    skip
            end;
        false ->
            skip
    end.
