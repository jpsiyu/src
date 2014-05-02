%%%-------------------------------------------------------------------
%%% @Module	: pp_qiling
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	:  2 Nov 2012
%%% @Description: 器灵
%%%-------------------------------------------------------------------
-module(pp_qiling).
-include("server.hrl").
-export([handle/3]).

%% 查询器灵信息
handle(17200, PS, _) ->
    Forza = PS#player_status.qiling_attr#status_qiling.forza,
    Agile = PS#player_status.qiling_attr#status_qiling.agile,
    Wit = PS#player_status.qiling_attr#status_qiling.wit,
    Thew = PS#player_status.qiling_attr#status_qiling.thew,
    {ok, Bin} = pt_172:write(17200, [Forza, Agile, Wit, Thew]),
    lib_server_send:send_to_sid(PS#player_status.sid, Bin);

%% 器灵开孔
handle(17201, PS, _) ->
    case lib_qiling:open_pos(PS) of
	[false, ErrorCode] ->
	    {ok, Bin} = pt_172:write(17201, [ErrorCode]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin);
	NewPS ->
	    {ok, Bin} = pt_172:write(17201, [1]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin),
	    {ok, NewPS}
    end;
%% 器灵培养
handle(17202, PS, _) ->
    case lib_qiling:cultivate_qiling(PS) of
	[false, ErrorCode] ->
	    {ok, Bin} = pt_172:write(17202, [ErrorCode, 0, 0]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin);
	{Type, Pos, NewPSTmp} ->
	    LvList = lib_qiling:get_four_qiling_type_lv(NewPSTmp#player_status.qiling_attr),
	    {_, Lv} = lists:keyfind(Type, 1, LvList),
	    %% 成就：神器附魔，附魔单个属性总等级达到N级
	    mod_achieve:trigger_role(PS#player_status.achieve, PS#player_status.id, 35, 0, Lv),
	    {ok, Bin} = pt_172:write(17202, [1, Type, Pos]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin),
	    NewPS = lib_player:count_player_attribute(NewPSTmp),
	    lib_player:send_attribute_change_notify(NewPS, 1),
	    {ok, battle_hp_mp, NewPS}
    end;
%% 器灵属性查询
handle(17203, PS, [PlayerId]) ->
    case PlayerId =:= PS#player_status.id of
	true ->
	    [Forza, Agile, Wit, Thew] = lib_qiling:calc_qiling_attr(PS#player_status.qiling_attr),
	    {ok, Bin} = pt_172:write(17203, [Forza, Agile, Wit, Thew, PlayerId]),
	    lib_server_send:send_to_sid(PS#player_status.sid, Bin) ;
	false ->
	    case lib_player:get_player_info(PlayerId, pid) of
		false -> [];
		Pid -> gen_server:cast(Pid, {'show_qiling_attr', PS#player_status.sid, PlayerId})
	    end
    end;

%% 错误处理
handle(_Cmd, _Status, _Data) ->
    {error, "pp_qixi no match"}.

