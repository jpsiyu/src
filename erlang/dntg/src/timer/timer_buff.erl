%%%------------------------------------
%%% @Module  : timer_buff
%%% @Author  : zhenghehe
%%% @Created : 2010.10.27
%%% @Description: BUFF定时服务
%%%------------------------------------
-module(timer_buff).
-export([init/0, handle/1, terminate/2]).
-include("common.hrl").
-include("server.hrl").
-include("figure.hrl").
-include("buff.hrl").

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
    {_Hour, _Min, _Sec} = time(),
    case _Min rem 5 of
        0 -> refresh_buff();
        _ -> skip
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

%%=========================================================================
%% 业务处理
%% TODO: 实现业务处理。
%%=========================================================================

%% -----------------------------------------------------------------
%% 每10分钟更新一次BUFF
%% -----------------------------------------------------------------
refresh_buff() ->
	lists:foldl(fun refresh_buff/2, util:unixtime(), buff_dict:get_all()).

refresh_buff(BuffInfo, NowTime) ->
    case NowTime >= BuffInfo#ets_buff.end_time + 60 of
        false -> skip;
        true ->
            case misc:get_player_process(BuffInfo#ets_buff.pid) of
                Pid when is_pid(Pid) ->
                    gen_server:cast(Pid, {'del_buff', BuffInfo#ets_buff.id}),
					case BuffInfo#ets_buff.attribute_id =:= ?FIGURE_BUFF_TYPE of
						true ->
							gen_server:cast(Pid, {'del_figure', BuffInfo#ets_buff.goods_id});
						false ->
							case BuffInfo#ets_buff.attribute_id =:= 98 of
								true ->
									gen_server:cast(Pid, {'del_qiling_figure', BuffInfo#ets_buff.goods_id});
								false ->
									ok
							end
					end;
                _ ->
                    buff_dict:delete_id(BuffInfo#ets_buff.id)
            end,
            %% 设置祝福剩余时间为0
            case BuffInfo#ets_buff.type of
                7 ->
                    %io:format("1~n"),
                    case mod_vip:lookup_pid(BuffInfo#ets_buff.pid) of
                        undefined -> skip;
                        EtsVipBuff when is_record(EtsVipBuff, ets_vip_buff) ->
                            %Id = EtsVipBuff#ets_vip_buff.id,
                            Buff = EtsVipBuff#ets_vip_buff.buff,
                            case EtsVipBuff#ets_vip_buff.state of
                                %% 处于解冻状态中时
                                1 ->
                                    %io:format("2~n"),
                                    mod_vip:insert_buff(EtsVipBuff#ets_vip_buff{buff = Buff, rest_time = 0, state = 2});
                                _ ->
                                    %io:format("3~n"),
                                    skip
                            end;
                        EtsVipBuff ->
                            catch util:errlog("EtsVipBuff badrecord:~p !! ~n", [EtsVipBuff])
                    end;
                _ ->
                    %io:format("4~n"),
                    skip
            end
    end,
    NowTime.
