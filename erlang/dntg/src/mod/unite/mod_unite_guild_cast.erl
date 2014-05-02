%% ---------------------------------------------------------
%% Author:  吴振华
%% Created: 2012-5-5
%% Description: 帮派cast
%% --------------------------------------------------------
-module(mod_unite_guild_cast).
-export([handle_cast/2]).
-include("common.hrl").
-include("server.hrl").
-include("buff.hrl").
-include("scene.hrl").
-include("unite.hrl").

%% -----------------------------------------------------------------
%% 帮派申请解散
%% -----------------------------------------------------------------
handle_cast({'guild_apply_disband',[_PlayerId, _PlayerName, GuildId, GuildName]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [0, GuildId, GuildName]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派新成员加入
%% -----------------------------------------------------------------
handle_cast({'guild_new_member',[PlayerId, PlayerName, GuildId, GuildName, _GuildPosition, _GLV, Career, Sex, Image, Level]}, Status) ->
    % 更新聊天信息
    case PlayerId == Status#unite_status.id of
        true  -> % 自己加入
            {ok, Bin} = pt_400:write(40000, [1, PlayerId, PlayerName, GuildId, GuildName, Career, Sex, Image, Level]),
            case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
                {'EXIT', _R1} ->
                    {stop, normal, Status};
                _R2 ->
                    {noreply, Status}
            end;
        false -> % 其他人加入
            {ok, Bin} = pt_400:write(40000, [1, PlayerId, PlayerName, GuildId, GuildName, Career, Sex, Image, Level]),
            catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 帮派邀请加入
%% -----------------------------------------------------------------
handle_cast({'guild_invite_join',[_PlayerId, _PlayerName, GuildId, GuildName]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [2, GuildId, GuildName]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派成员被踢出
%% -----------------------------------------------------------------
handle_cast({'guild_kickout',[PlayerId, PlayerName, GuildId, GuildName]}, Status) ->
    % 更新聊天信息
    case PlayerId == Status#unite_status.id  of
        % 自己被踢出
        true  ->
            {ok, Bin} = pt_400:write(40000, [3, PlayerId, PlayerName, GuildId, GuildName]),
            case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
                {'EXIT', _R1} ->
                    {stop, normal, Status};
                _R2 ->
                    {noreply, Status}
            end;
        false ->
            % 发送通知
            {ok, Bin} = pt_400:write(40000, [3, PlayerId, PlayerName, GuildId, GuildName]),
            catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 帮派成员退出
%% -----------------------------------------------------------------
handle_cast({'guild_quit',[PlayerId, PlayerName, GuildId, GuildName]}, Status) ->
    % 更新聊天信息
    {ok, Bin} = pt_400:write(40000, [4, PlayerId, PlayerName, GuildId, GuildName]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派职位改变
%% -----------------------------------------------------------------
handle_cast({'guild_set_position',[PlayerId, PlayerName, OldPosition, NewPosition]}, Status) ->
    MsgType = case OldPosition < NewPosition of
                  true  -> 6;
                  false -> 5
    end,
    case PlayerId == Status#unite_status.id  of
        true  ->
            {ok, Bin} = pt_400:write(40000, [MsgType, PlayerId, PlayerName, OldPosition, NewPosition]),
            case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
                {'EXIT', _R1} ->
                    {stop, normal, Status};
                _R2 ->
                    {noreply, Status}
            end;
        false ->
            {ok, Bin} = pt_400:write(40000, [MsgType, PlayerId, PlayerName, OldPosition, NewPosition]),
            catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 帮派帮主禅让
%% -----------------------------------------------------------------
handle_cast({'guild_demise_chief',[OldChiefId, OldChiefName, NewChiefId, NewChiefName]}, Status) ->
    case NewChiefId == Status#unite_status.id  of
        true  ->
            {ok, Bin} = pt_400:write(40000, [7, OldChiefId, OldChiefName, NewChiefId, NewChiefName]),
            case catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin) of
                {'EXIT', _R1} ->
                    {stop, normal, Status};
                _R2 ->
                    {noreply, Status}
            end;
        false ->
            {ok, Bin} = pt_400:write(40000, [7, OldChiefId, OldChiefName, NewChiefId, NewChiefName]),
            catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 帮主群发公告
%% -----------------------------------------------------------------
handle_cast({'guild_chief_ann_all', [GuildId, RoleId, RoleName, Title, Contents]}, Status) ->
    {ok, BinData} = pt_400:write(40000, [38, GuildId, RoleId, RoleName, Title, Contents]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派成员辞官
%% -----------------------------------------------------------------
handle_cast({'guild_resign_position', [PlayerId, PlayerName, OldPosition, NewPosition]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [8, PlayerId, PlayerName, OldPosition, NewPosition]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派正式解散
%% -----------------------------------------------------------------
handle_cast({'guild_disband',[GuildId, GuildName]}, Status) ->
    %% 同步帮派信息
	NewUniteStatus = lib_guild:guild_self_syn(Status, [0, util:make_sure_binary([]), 0]),
    {ok, Bin} = pt_400:write(40000, [9, GuildId, GuildName]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, NewUniteStatus};

%% -----------------------------------------------------------------
%% 帮派取消解散
%% -----------------------------------------------------------------
handle_cast({'guild_cancel_disband',[_PlayerId, _PlayerName, GuildId, GuildName]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [10, GuildId, GuildName]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派升级
%% -----------------------------------------------------------------
handle_cast({'guild_upgrade',[GuildId, GuildName, OldLevel, NewLevel]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [11, GuildId, GuildName, OldLevel, NewLevel]),
	case misc:get_player_process(Status#unite_status.id) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {guild_upgrade, NewLevel});
        _ ->
            skip
    end,
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派降级
%% -----------------------------------------------------------------
handle_cast({'guild_degrade',[GuildId, GuildName, OldLevel, NewLevel]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [12, GuildId, GuildName, OldLevel, NewLevel]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派钱币捐献
%% -----------------------------------------------------------------
handle_cast({'guild_donate_money',[PlayerId, PlayerName, Num, DonationAdd, PaidAdd]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [13, PlayerId, PlayerName, Num, DonationAdd, PaidAdd]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派建设卡捐献
%% -----------------------------------------------------------------
handle_cast({'guild_donate_contribution_card',[PlayerId, PlayerName, CardNum, DonationAdd, PaidAdd, MaterialAdd]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [14, PlayerId, PlayerName, CardNum, DonationAdd, PaidAdd, MaterialAdd]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派申请加入
%% -----------------------------------------------------------------
handle_cast({'guild_apply_join',[PlayerId, PlayerName]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [15, PlayerId, PlayerName]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派拒绝邀请
%% -----------------------------------------------------------------
handle_cast({'guild_reject_invite',[PlayerId, PlayerName]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [16, PlayerId, PlayerName]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派掉级解散
%% -----------------------------------------------------------------
handle_cast({'guild_auto_disband',[GuildId, GuildName]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [17, GuildId, GuildName]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派拒绝申请
%% -----------------------------------------------------------------
handle_cast({'guild_reject_apply',[GuildId, GuildName]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [18, GuildId, GuildName]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派头衔授予
%% -----------------------------------------------------------------
handle_cast({'guild_give_title',[PlayerId, PlayerName, Title]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [19, PlayerId, PlayerName, Title]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派仓库存入物品
%% -----------------------------------------------------------------
handle_cast({'guild_store_into_depot',[PlayerId, PlayerName, GoodsId, GoodsName, GoodsNum]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [20, PlayerId, PlayerName, GoodsId, GoodsName, GoodsNum]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};


%% -----------------------------------------------------------------
%% 帮派仓库取出物品
%% -----------------------------------------------------------------
handle_cast({'guild_take_out_depot',[PlayerId, PlayerName, GoodsId, GoodsName, GoodsNum]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [21, PlayerId, PlayerName, GoodsId, GoodsName, GoodsNum]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派仓库删除物品
%% -----------------------------------------------------------------
handle_cast({'guild_delete_from_depot',[PlayerId, PlayerName, GoodsId, GoodsName, GoodsNum]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [22, PlayerId, PlayerName, GoodsId, GoodsName, GoodsNum]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派升级厢房
%% -----------------------------------------------------------------
handle_cast({'guild_upgrade_house',[PlayerId, PlayerName, OldLevel, NewLevel, NewMemberCapacity, DonationAdd, PaidAdd]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [27, PlayerId, PlayerName, OldLevel, NewLevel, NewMemberCapacity, DonationAdd, PaidAdd]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};
%% -----------------------------------------------------------------
%% 帮派升级仓库
%% -----------------------------------------------------------------
handle_cast({'guild_upgrade_depot',[GuildId, GuildName, OldLevel, NewLevel]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [23, GuildId, GuildName, OldLevel, NewLevel]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派修改公告
%% -----------------------------------------------------------------
handle_cast({'guild_modify_announce',[PlayerId, PlayerName, Announce]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [25, PlayerId, PlayerName, Announce]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派修改宗旨
%% -----------------------------------------------------------------
handle_cast({'guild_modify_tenet',[PlayerId, PlayerName, Tenet]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [26, PlayerId, PlayerName, Tenet]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派奖励刷新
%% -----------------------------------------------------------------
handle_cast({'guild_battle_guild_award',[GuildId, GuildName, PlayerId, PlayerName]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [28, GuildId, GuildName, PlayerId, PlayerName]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派个人奖励刷新
%% -----------------------------------------------------------------
handle_cast({'guild_battle_pernal_award',[PlayerId, _PlayerName]}, Status) ->
    case PlayerId == Status#unite_status.id  of
        true  ->
            {ok, Bin} = pt_400:write(40000, [29]),
            catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
            {noreply, Status};
        false->
            void
    end;

%% -----------------------------------------------------------------
%% 帮派弹劾帮主
%% -----------------------------------------------------------------
handle_cast({'guild_impeach_chief',[PlayerId, PlayerName, _PlayerPosition, ChiefId, ChiefName]}, Status) ->
%%     PlayerStatus = lib_guild:get_guild_playerinfo(Status#unite_status.id),
%%     Gs = PlayerStatus#player_status.guild,
    case ChiefId == Status#unite_status.id  of
        % 自己被弹劾
        true  ->
%%             PlayerStatus1 = PlayerStatus#player_status{guild=Gs#status_guild{guild_position = PlayerPosition}},
%%             Rgp_From_Ps = lib_guild:trans_to_guild(PlayerStatus1),
%%     		lib_player:update_player_info(PlayerStatus1#player_status.id, [{guild_user, Rgp_From_Ps}]),
%%             Status1 = Status#unite_status{
%%                                         guild_position = PlayerPosition
%%                                         },
%%             mod_login:save_online(Status1),
            {ok, Bin} = pt_400:write(40000, [30, PlayerId, PlayerName, ChiefId, ChiefName]),
            catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
            {noreply, Status};
        % 其他人被弹劾
        false ->
            {ok, Bin} = pt_400:write(40000, [30, PlayerId, PlayerName, ChiefId, ChiefName]),
            catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
            {noreply, Status}
    end;
    
%% -----------------------------------------------------------------
%% 帮派集结
%% -----------------------------------------------------------------
handle_cast({'guild_gather_member',[PlayerId, PlayerName, SceneId, X, Y]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [31, PlayerId, PlayerName, SceneId, X, Y]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派合并邀请
%% -----------------------------------------------------------------
handle_cast({'guild_invite_merge',[PlayerId, PlayerName, DeleteGuildId, DeleteGuildName, ReserveGuildId, ReserveGuildName]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [33, PlayerId, PlayerName, DeleteGuildId, DeleteGuildName, ReserveGuildId, ReserveGuildName]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派合并成功
%% -----------------------------------------------------------------
handle_cast({'guild_merge',[DeleteGuildId, DeleteGuildName, ReserveGuildId, ReserveGuildName, _DefaultPosition, _ReserveGuildLevel]}, Status) ->
    case DeleteGuildId == Status#unite_status.guild_id  of
        % 帮派被合并
        true  ->
            % 发送通知
            {ok, Bin} = pt_400:write(40000, [34, DeleteGuildId, DeleteGuildName, ReserveGuildId, ReserveGuildName]),
            catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
            {noreply, Status};
        % 帮派被保留
        false ->
            % 发送通知
            {ok, Bin} = pt_400:write(40000, [34, DeleteGuildId, DeleteGuildName, ReserveGuildId, ReserveGuildName]),
            catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 帮主召唤
%% -----------------------------------------------------------------
handle_cast({'guild_gather_member2',[PlayerId, PlayerName, SceneId, X, Y, Content]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [35, PlayerId, PlayerName, SceneId, X, Y, Content]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 入帮祝福
%% -----------------------------------------------------------------
handle_cast({'guild_join_bless',[BlessedPlayerId, BlessedPlayerName, PlayerId, PlayerName, Position, Type, _GoodsNum]}, Status) ->
    case Type == 1 andalso BlessedPlayerId == Status#unite_status.id of
        true ->
			lib_player:update_player_info(BlessedPlayerId, [{add_coin, 88}]);
        false when Type == 0 andalso BlessedPlayerId == Status#unite_status.id ->
            lib_player:update_player_info(BlessedPlayerId, [{add_exp, 88}]);
        false->
            skip
    end,
    {ok, Bin} = pt_400:write(40000, [36, BlessedPlayerId, BlessedPlayerName, PlayerId, PlayerName, Position, Type, _GoodsNum]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派帮派商城升级
%% -----------------------------------------------------------------
handle_cast({'guild_upgrade_mall',[GuildId, GuildName, OldMallLevel, NewMallLevel]}, Status) ->
    {ok, Bin} = pt_400:write(40000, [37, GuildId, GuildName, OldMallLevel, NewMallLevel]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, Bin),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派改名
%% -----------------------------------------------------------------
handle_cast({'guild_rename',[PlayerId, _PlayerName, _GuildId, _GuildName]}, Status) ->
    case PlayerId =/= Status#unite_status.id  of
        % 不是自己改的名
        true  ->
            {noreply, Status};
        % 自己改的名
        false ->
            {noreply, Status}
    end;

%% -----------------------------------------------------------------
%% 帮派_宴会举行
%% -----------------------------------------------------------------
handle_cast({'guild_party_will_start', [RoleId, RoleName, PartyType, StartTime]}, Status) ->
    {ok, BinData} = pt_400:write(40000, [51, RoleId, RoleName, PartyType, StartTime]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派_宴会开始公告
%% -----------------------------------------------------------------
handle_cast({'guild_party_starting', [RoleId, RoleName, PartyType, StartTime]}, Status) ->
    {ok, BinData} = pt_400:write(40000, [52, RoleId, RoleName, PartyType, StartTime]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮宴传音
%% -----------------------------------------------------------------
handle_cast({'guild_party_ann', [RoleId, RoleName, PartyType, StartTime]}, Status) ->
    {ok, BinData} = pt_400:write(40000, [53, RoleId, RoleName, PartyType, StartTime]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派神兽可以升级通知_只发给帮主_副帮主
%% -----------------------------------------------------------------
handle_cast({'guild_godanimal_full', [Res]}, Status) ->
    {ok, BinData} = pt_400:write(40000, [55, Res]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派神兽战斗召唤_通知
%% -----------------------------------------------------------------
handle_cast({'guild_godanimal_call', [Res, Time]}, Status) ->
    {ok, BinData} = pt_400:write(40000, [57, Res, Time]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    {noreply, Status};

%% -----------------------------------------------------------------
%% 帮派神兽战斗召唤_通知
%% -----------------------------------------------------------------
handle_cast({'guild_godanimal_start', [Res]}, Status) ->
    {ok, BinData} = pt_400:write(40000, [56, Res]),
    catch lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    {noreply, Status};

%% 同步帮派等级
handle_cast({'guild_lv', _Lv}, Status) ->
    {noreply, Status};

%% 同步帮派神兽阶段
handle_cast({guild_ga_stage, Stage}, Status) ->
	lib_player:update_player_info(Status#unite_status.id, [{guild_ga_stage, Stage}]),
    {noreply, Status};


%% 同步玩家的帮派信息:用于对他人的操作
handle_cast({'guild_member_syn', [GuildId, GuildName, GuildPosition]}, Status) ->
	NewUniteS = Status#unite_status{guild_id = GuildId, guild_name = GuildName, guild_position = GuildPosition},
	lib_guild:update_ets_unite(NewUniteS),
    {noreply, NewUniteS};

%% 同步自己的帮派信息(帮派名)
handle_cast({'guild_self_syn_guildname', [GuildId, GuildName]}, Status) ->
    NewUniteS = lib_guild:guild_self_syn(Status, [GuildId, GuildName, Status#unite_status.guild_position]),
	lib_guild:update_ets_unite(NewUniteS),
    {noreply, NewUniteS}.
