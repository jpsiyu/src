%%%------------------------------------
%%% @Module  : mod_unite_cast
%%% @Author  : zhenghehe
%%% @Created : 2011.12.16
%%% @Description: 公共服务cast处理
%%%------------------------------------
-module(mod_unite_cast).
-export([handle_cast/2]).
-include("unite.hrl").
-include("server.hrl").
-include("common.hrl").
-include("scene.hrl").
-include("rela.hrl").

%%==========基础功能base============
%%写入用户信息
handle_cast({'base_set_data', UniteStatus}, _Status) ->
    {noreply, UniteStatus};

%%更新用户信息
handle_cast({'set_data', AttrKeyValueList}, Status) ->
    NewStatus = tranc_list_to_unitestatus(AttrKeyValueList, Status),
    mod_login:save_online(NewStatus),
    {noreply, NewStatus};

%% -----------------------------------------------------------------
%% 拜师申请
%% -----------------------------------------------------------------
handle_cast({'master_apply',[PlayerId, PlayerName]}, Status) ->
    {ok, Bin} = pt_440:write(44000, [0, PlayerId, PlayerName]),
    case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status};
        _R2 ->
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 拜师申请成功
%% -----------------------------------------------------------------
handle_cast({'master_apply_join',[PlayerId, PlayerName]}, Status) ->
    NowTime = util:unixtime(),
    M = Status#unite_status.master,
    Status1 = Status#unite_status{master=M#status_master{master_join_lasttime = NowTime}},
    {ok, Bin} = pt_440:write(44000, [1, PlayerId, PlayerName]),
    case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status1};
        _R2 ->
            {noreply, Status1}
    end;

%% -----------------------------------------------------------------
%% 逐出师门
%% -----------------------------------------------------------------
handle_cast({'master_kickout',[PlayerId, PlayerName]}, Status) ->
    NowTime = util:unixtime(),
    Master = Status#unite_status.master,
    Status1 = Status#unite_status{master=Master#status_master{master_quit_lasttime=NowTime}},
    {ok, Bin} = pt_440:write(44000, [2, PlayerId, PlayerName]),
    case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status1};
        _R2 ->
            {noreply, Status1}
    end;

%% -----------------------------------------------------------------
%% 退出师门
%% -----------------------------------------------------------------
handle_cast({'master_quit',[PlayerId, PlayerName]}, Status) ->
    {ok, Bin} = pt_440:write(44000, [3, PlayerId, PlayerName]),
    case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status};
        _R2 ->
            {noreply, Status}
    end;


%% -----------------------------------------------------------------
%% 汇报成绩
%% -----------------------------------------------------------------
handle_cast({'master_report',[PlayerId, PlayerName, ExpAdd, ScoreAdd]}, Status) ->
    %PlayerStatus = lib_player:get_player_info(Status#unite_status.id),
    %PlayerStatus1   = lib_player:add_exp(PlayerStatus, ExpAdd),
    gen_server:cast(misc:get_player_process(Status#unite_status.id), {'set_data', [{add_exp, ExpAdd}]}),
    Master = Status#unite_status.master,
    NewScore  = Master#status_master.master_score + ScoreAdd,
    Status2   = Status#unite_status{master=Master#status_master{master_score = NewScore}},
    {ok, Bin} = pt_440:write(44000, [5, PlayerId, PlayerName, ExpAdd, ScoreAdd]),
    case catch lib_unite_send:send_to_sid(Status2#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status2};
        _R2 ->
            {noreply, Status2}
    end;

%% -----------------------------------------------------------------
%% 出师
%% -----------------------------------------------------------------
handle_cast({'master_finish',[PlayerId, PlayerName, ScoreAdd]}, Status) ->
    Master = Status#unite_status.master,
    NewScore  = Master#status_master.master_score + ScoreAdd,
    Status1   = Status#unite_status{master=Master#status_master{master_score = NewScore}},
    % 发送通知
    {ok, Bin} = pt_440:write(44000, [6, PlayerId, PlayerName, ScoreAdd]),
    case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status1};
        _R2 ->
            {noreply, Status1}
    end;

%% -----------------------------------------------------------------
%% 拜师申请拒绝
%% -----------------------------------------------------------------
handle_cast({'master_apply_reject',[PlayerId, PlayerName]}, Status) ->
    {ok, Bin} = pt_440:write(44000, [7, PlayerId, PlayerName]),
    case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status};
        _R2 ->
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 拜师被取消
%% -----------------------------------------------------------------
handle_cast({'master_apply_cancel',[PlayerId, PlayerName]}, Status) ->
    {ok, Bin} = pt_440:write(44000, [8, PlayerId, PlayerName]),
    case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status};
        _R2 ->
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 拜师邀请
%% -----------------------------------------------------------------
handle_cast({'master_invite',[PlayerId, PlayerName, Line, Realm, Level]}, Status) ->
    {ok, Bin} = pt_440:write(44000, [9, PlayerId, PlayerName, Line, Realm, Level]),
    case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status};
        _R2 ->
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 拜师邀请拒绝
%% -----------------------------------------------------------------
handle_cast({'master_invite_reject',[PlayerId, PlayerName]}, Status) ->
    {ok, Bin} = pt_440:write(44000, [10, PlayerId, PlayerName]),
    case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status};
        _R2 ->
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 拜师邀请成功
%% -----------------------------------------------------------------
handle_cast({'master_invite_join',[PlayerId, PlayerName]}, Status) ->
    {ok, Bin} = pt_440:write(44000, [11, PlayerId, PlayerName]),
    case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status};
        _R2 ->
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 拜师邀请取消
%% -----------------------------------------------------------------
handle_cast({'master_invite_cancel',[PlayerId, PlayerName]}, Status) ->
    {ok, Bin} = pt_440:write(44000, [12, PlayerId, PlayerName]),
    case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
        {'EXIT', _R1} ->
            {stop, normal, Status};
        _R2 ->
            {noreply, Status}
    end;


%% 踢出到指定场景的默认点
handle_cast({'KICK_OUT_TO_SCENE', EtsScene}, Status) ->
    %% W = Status#player_status.wedding,
    NewPlayerStatus =
    Status#player_status{
        scene = EtsScene#ets_scene.id,
        x = EtsScene#ets_scene.x,
        y = EtsScene#ets_scene.y
    },
    {ok, BinData} = pt_120:write(12005, [NewPlayerStatus#player_status.scene, NewPlayerStatus#player_status.x, NewPlayerStatus#player_status.y, EtsScene#ets_scene.name, EtsScene#ets_scene.id]),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    lib_player:update_player_status(NewPlayerStatus#player_status.id, NewPlayerStatus),
    {noreply, Status};

% -- 帮派 -----
handle_cast({'guild', {Type, Data}}, Status) ->
    mod_unite_guild_cast:handle_cast({Type, Data}, Status);

%% 默认匹配
handle_cast(Event, Status) ->
    catch util:errlog("mod_unite:handle_cast not match: ~p", [Event]),
    {noreply, Status}.

%% 按列表内容修改unite_status属性
tranc_list_to_unitestatus([], US) ->
    US;
tranc_list_to_unitestatus([{K, V} | T], US) ->
    _US = case K of
		realm ->
            US#unite_status{realm = V};
        lv ->
		  lib_relationship:update_user_rela_lv(US#unite_status.id, V),
            US#unite_status{lv = V};
        scene ->
		  lib_relationship:update_user_rela_scene(US#unite_status.id, V),
            US#unite_status{scene = V};
        copy_id ->
            US#unite_status{copy_id = V};
        team_id ->
            US#unite_status{team_id = V};
        image ->
            US#unite_status{image = V};
		guild_id ->
            US#unite_status{guild_id = V};
		guild_name ->
            US#unite_status{guild_name = V};
		guild_position ->
            US#unite_status{guild_position = V};
		vip ->
			lib_chat:update_user_info_4_vip_type(US#unite_status.id,V),
            US#unite_status{vip = V};
		war_end_time ->
			US#unite_status{war_end_time = V};
		talk_lim ->
			US#unite_status{talk_lim = V};
        talk_lim_time ->
			US#unite_status{talk_lim_time = V};
		talk_lim_right ->
			US#unite_status{talk_lim_right = V};
        loverun_data ->
            US#unite_status{loverun_data = V};
        group -> 
            US#unite_status{group = V};
        sex ->
            US#unite_status{sex = V};
        _ ->
            US	  
	end,
    tranc_list_to_unitestatus(T, _US).

