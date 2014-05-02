%%%------------------------------------
%%% @Module  : timer_vip
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2013.03.05
%%% @Description: VIP定时器
%%%------------------------------------

-module(timer_vip).
-compile(export_all).
-include("common.hrl").
-define(CYCLE_MIN, 30).
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
    {ok, ?MODULE}.

%% -----------------------------------------------------------------
%% @desc     服务回调函数，用来执行业务操作。
%% @param    State          : 初始化或者上一次服务返回的状态
%% @return  {ok, NewState}  : 服务正常，返回新状态
%%           {ignore, Reason}: 服务异常，本模块以后将被忽略不执行，模块的terminate函数将被回调
%%           {stop, Reason}  : 服务异常，需要停止所有后台定时模块，所有模块的terminate函数将被回调
%% -----------------------------------------------------------------
handle(State) ->
    {_Hour, Min, _Sec} = time(),
    CycleMin = ?CYCLE_MIN,
    %% 检测玩家是否马上过期
    case Min rem CycleMin of
        0 ->
            spawn(fun() ->
                        OneDay1 = util:unixtime() + 1 * 24 * 3600,
                        OneDay2 = util:unixtime() + 1 * 24 * 3600 + CycleMin * 60,
                        ThreeDay1 = util:unixtime() + 3 * 24 * 3600,
                        ThreeDay2 = util:unixtime() + 3 * 24 * 3600 + CycleMin * 60,
                        SevenDay1 = util:unixtime() + 7 * 24 * 3600,
                        SevenDay2 = util:unixtime() + 7 * 24 * 3600 + CycleMin * 60,
                        case db:get_all(io_lib:format(<<"select id, vip_type from player_vip where (vip_type = 1 and vip_time > ~p and vip_time < ~p) or (vip_type = 2 and vip_time > ~p and vip_time < ~p) or (vip_type = 3 and vip_time > ~p and vip_time < ~p)">>, [OneDay1, OneDay2, ThreeDay1, ThreeDay2, SevenDay1, SevenDay2])) of
                            [] ->
                                skip;
                            List when is_list(List) ->
                                send_mail(List);
                            _ ->
                                skip
                        end
                end);
        _ ->
            skip
    end,
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

send_mail([]) -> skip;
send_mail([H | T]) ->
    case H of
        [PlayerId, VipType] ->
            Title = data_vip_text:get_vip_text(7),
            Content = case VipType of
                1 ->
                    data_vip_text:get_vip_text(8);
                2 ->
                    data_vip_text:get_vip_text(9);
                _ ->
                    data_vip_text:get_vip_text(10)
            end,
            lib_mail:send_sys_mail_bg([PlayerId], Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        _ ->
            skip
    end,
    send_mail(T).
