%%%-------------------------------------------------------------------
%%% @Module	: pp_qixi
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 21 Aug 2012
%%% @Description: 
%%%-------------------------------------------------------------------
-module(pp_qixi).
-include("server.hrl").
-include("unite.hrl").
-include("common.hrl").
-include("gift.hrl").
-export([handle/3]).

%% 查询活动完成情况
handle(27700, PS, _) ->
    case data_qixi:is_qixi_time() of
	true ->
	    Data = lib_qixi:get_finish_task(PS#player_status.id),
	    {ok, Bin} = pt_277:write(27700, [Data]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin);
	false ->
	    skip
    end;

%% 领取奖励
handle(27701, PS, [Type]) ->
    case data_qixi:is_qixi_time() of
	true ->
	    %% 判断Type是否完成，完成发送奖励，未完成返回错误码
	    lib_qixi:send_award(PS, Type);
	false ->
	    skip
    end;

%% 查询领取登录礼包 
handle(27702, PS, _) ->
    %% 返回礼包领取状态
    case data_qixi:is_qixi_time() of
	true ->
	    GetList = lists:map(fun(X) ->
					{_, _, GiftId} = X,
					case lib_qixi:can_get_login_award(PS, GiftId) of
					    true -> {GiftId, 1};
					    {false, 4} -> {GiftId, 2};
					    _ -> {GiftId, 0}
					end
				end, data_qixi:get_gift_id()),
	    {ok, Bin} = pt_277:write(27702, [GetList]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin),
	    %% 连续登录天数
	    {_, Open} = case lists:keyfind(1, 1, data_qixi_config:get_qixi_award_open()) of
			    false -> {0, 0};
			    Any -> Any
			end,
	    case Open of
		1 ->
		    LoginDays = lib_qixi:get_login_continuation(PS#player_status.id),
		    {ok, LoginDaysBin} = pt_277:write(27709, [LoginDays]),
		    lib_server_send:send_to_sid(PS#player_status.sid, LoginDaysBin);
		_ -> []
	    end,
	    TaskNum = lib_qixi:remain_task_award_num(PS),
	    LoginNum = lib_qixi:remain_login_award_num(PS),
	    TotalNum = TaskNum + LoginNum,
	    mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, 7710, TaskNum),
	    mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, 7711, LoginNum),
	    {ok, Bin27708} = pt_277:write(27708, [TotalNum]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin27708);
	false ->
	    skip
    end;

%% 领取登录礼包
handle(27703, PS, [GiftId]) ->
    case lib_qixi:can_get_login_award(PS, GiftId) of
	true ->
	    G = PS#player_status.goods,
	    case gen_server:call(G#status_goods.goods_pid, {'fetch_gift', PS, GiftId}) of
		[ok, NewPS] ->
		    {ok, BinData} = pt_277:write(27703, [1, GiftId]),
		    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
		    {_,DailyType,_} = lib_qixi:get_daily_type_by_gift_id(GiftId),
		    mod_daily:increment(PS#player_status.dailypid, PS#player_status.id, DailyType),
		    case mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 7711) =< 0 of
			true -> [];
			false ->
			    mod_daily:decrement(PS#player_status.dailypid, PS#player_status.id, 7711)
		    end,
		    handle(27708, PS, ""),
		    {ok, NewPS};
		[error, ErrorCode] ->
		    {ok, BinData} = pt_277:write(27703, [ErrorCode, GiftId]),
		    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
	    end;
	{false, ErrorCode} ->
	    {ok, BinData} = pt_277:write(27703, [ErrorCode, GiftId]),
	    lib_server_send:send_to_sid(PS#player_status.sid, BinData)
    end;
%% 活动图标
handle(27704, PS, _) ->
    case data_qixi:is_qixi_time() of
	true ->
	    {ok, Bin27704} = pt_277:write(27704, []),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin27704),
	    TaskNum = lib_qixi:remain_task_award_num(PS),
	    LoginNum = lib_qixi:remain_login_award_num(PS),
	    TotalNum = TaskNum + LoginNum,
	    mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, 7710, TaskNum),
	    mod_daily:set_count(PS#player_status.dailypid, PS#player_status.id, 7711, LoginNum),
	    {ok, Bin27708} = pt_277:write(27708, [TotalNum]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin27708);
	false ->
	    skip
    end;

%% 魅力榜
handle(27705, PS, _) ->
    case data_qixi:is_qixi_time() of
	true ->
	    %% 魅力榜
	    List = case lib_qixi:get_mlpt_player() of
		       null -> [];
		       R -> R
		   end,
	    RList = lists:reverse(List),
	    {ok, Bin} = pt_277:write(27705, [RList]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin);
	false ->
	    skip
    end;

%% 查询活动完成情况
handle(27706, PS, _) ->
    case data_qixi:is_qixi_time() of
	true ->
	    Data = lib_qixi:get_finish_task(PS#player_status.id),
	    {ok, Bin} = pt_277:write(27706, [Data]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin);
	false ->
	    skip
    end;
%% 领取奖励
handle(27707, PS, [Type]) ->
    case data_qixi:is_qixi_time() of
	true ->
	    %% 判断Type是否完成，完成发送奖励，未完成返回错误码
	    lib_qixi:send_award(PS, Type+6, xss);
	false ->
	    skip
    end;

%% 推送可领取奖励数目
handle(27708, PS, _) ->
    TotalNum = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 7710) + mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 7711),
    {ok, Bin} = pt_277:write(27708, [TotalNum]),
    lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 显示剩余时间
handle(27710, PS, _) ->
    QixiTime = data_qixi:get_end_day() - util:unixtime(),
    {ok, Bin} = pt_277:write(27710, [QixiTime]),
    lib_server_send:send_to_sid(PS#player_status.sid, Bin);

handle(27711, PS, _) ->
    case data_qixi:is_special_time(12) of
	true -> lib_qixi:get_special_login_continuation_award(PS);
	false -> []
    end;

handle(27712, PS, _) ->
    case data_qixi:is_special_time(12) of
	true ->
	    %%[{天数, GiftId, 数量, 是否按登录天数发, 领取状态}...]
	    GiftList = lib_qixi:check_special_login_continuation_award(PS#player_status.id),
	    {ok, BinData} = pt_277:write(27712, [GiftList]),
	    lib_server_send:send_to_sid(PS#player_status.sid, BinData);
	false ->
	    []
    end;







%% 错误处理
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_qixi no match", []),
	{error, "pp_qixi no match"}.





