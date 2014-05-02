%%%--------------------------------------
%%% @Module  : pp_change_name
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.18
%%% @Description:  改名
%%%--------------------------------------

-module(pp_change_name).
-compile(export_all).
-include("server.hrl").
-include("common.hrl").
-include("guild.hrl").
-include("rela.hrl").

%% 玩家改名
handle(10101, Status, [Name]) ->
	%io:format("recv 10101~n"),
    case is_record(Status, player_status) =:= true andalso is_list(Name) =:= true of
        true ->
            SQL1 = io_lib:format(<<"select c_rename from player_low where id = ~p limit 1">>, [Status#player_status.id]),
            case db:get_row(SQL1) of
                [] ->
                    Err = 2;
                [CRename] ->
                    %% 判断是否可以改名
                    case CRename of
                        1 -> 
                            case pp_login:validate_name(Name) of
                                %% 非法字符
                                {false, 4} ->
                                    Err = 6;
                                %% 角色名称长度为2~6个汉字
                                {false, 5} ->
                                    Err = 5;
                                %% 判断角色名是有敏感词
                                {false, 7} ->
                                    Err = 4;
                                %% 角色名称已经被使用
                                {false, 3} ->
                                    Err = 3;
                                true -> 
                                    Err = player_change_name(Status, Name),
                                    case Err of
                                        1 ->
                                            %% 发送传闻
                                            lib_chat:send_TV({all}, 0, 2, ["changename", Status#player_status.nickname, Status#player_status.id, Status#player_status.realm, Name, Status#player_status.sex, Status#player_status.career, Status#player_status.image]),
                                            NewStatus = Status#player_status{
                                                nickname = Name
                                            },
                                            lib_designation:change_name(NewStatus),
                                            send_email_to_friend(Status, NewStatus);
                                        _ ->
                                            skip
                                    end;
                                _ -> 
                                    Err = 0
                            end;
                        _ ->
                            %% 是否有改名卡
                            GoodsTypeId = 612601,
                            case mod_other_call:get_goods_num(Status, GoodsTypeId, 0) > 0 of
                                true ->
                                    case pp_login:validate_name(Name) of
                                        %% 非法字符
                                        {false, 4} ->
                                            Err = 6;
                                        %% 角色名称长度为2~6个汉字
                                        {false, 5} ->
                                            Err = 5;
                                        %% 判断角色名是有敏感词
                                        {false, 7} ->
                                            Err = 4;
                                        %% 角色名称已经被使用
                                        {false, 3} ->
                                            Err = 3;
                                        true -> 
                                            Err = player_change_name(Status, Name),
                                            case Err of
                                                1 ->
                                                    %% 发送传闻
                                                    lib_chat:send_TV({all}, 0, 2, ["changename", Status#player_status.nickname, Status#player_status.id, Status#player_status.realm, Name, Status#player_status.sex, Status#player_status.career, Status#player_status.image]),
                                                    %% 扣除物品
                                                    lib_player:update_player_info(Status#player_status.id, [{use_goods, {GoodsTypeId, 1}}]),
                                                    log:log_goods_use(Status#player_status.id, GoodsTypeId, 1),

                                                    NewStatus = Status#player_status{
                                                        nickname = Name
                                                    },
                                                    lib_designation:change_name(NewStatus),
                                                    send_email_to_friend(Status, NewStatus);
                                                _ ->
                                                    skip
                                            end
                                    end;
                                false ->
                                    Err = 7
                            end                            
                    end
            end,
            {ok, BinData} = pt_101:write(10101, [Err]),
            %io:format("10101:~p~n", [Err]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData);
        false -> 
            skip
    end;

%% 帮派改名
handle(10111, Status, [GuildId, GuildName]) ->
    %io:format("recv 10111~n"),
    case is_record(Status, player_status) =:= true andalso is_list(GuildName) of
        true ->
            SQL1 = io_lib:format(<<"select c_rename from guild where id = ~p limit 1">>, [GuildId]),
            %% 判断该玩家是否拥有帮派
            case db:get_row(SQL1) of
                [] ->
                    Err = 0;
                [CRename] ->
                    %% 判断是否可以改名
                    case CRename of
                        1 ->
                            % 帮派名长度非法
                            NameLenValid = util:check_length(GuildName, 14),
                            case NameLenValid of
                                false -> 
                                    Err = 4;
                                true ->
                                    % 帮派名内容非法
                                    NameContentInValid = util:check_keyword(GuildName),
                                    case NameContentInValid of
                                        true ->
                                            Err = 5;
                                        false ->
                                            % 帮派名已存在
                                            NewGuildName = string:to_upper(util:make_sure_list(GuildName)),
                                            GuildUpper   = lib_guild_base:get_guild_by_name_upper(NewGuildName),
                                            case GuildUpper of
                                                [] -> 
                                                    F = fun() ->
                                                            db:execute(io_lib:format(<<"update guild set name = '~s', c_rename = 0 where id = ~p">>, [GuildName, GuildId])),
                                                            SQL2 = io_lib:format(<<"select id from guild_member where guild_id = ~p">>, [GuildId]),
                                                            case db:get_all(SQL2) of
                                                                [] -> 
                                                                    skip;
                                                                AllMemberId ->
                                                                    update_guild_member(AllMemberId, GuildName, 0)
                                                            end
                                                    end,
                                                    db:transaction(F),
                                                    NewGuildName = string:to_upper(util:make_sure_list(GuildName)),
                                                    NewNameUp = lib_guild_base:get_guild_by_name_upper(NewGuildName),
                                                    mod_disperse:cast_to_unite(lib_guild, gaimin_hefu, [GuildId, GuildName, NewNameUp]),
                                                    mod_disperse:cast_to_unite(lib_guild, send_guild, [GuildId, 'guild_self_syn_guildname', [GuildId, GuildName]]),
                                                    Err = 1;
                                                _ -> 
                                                    Err = 3
                                            end
                                    end
                            end;
                        _ -> 
                            Err = 2
                    end
            end,
            {ok, BinData} = pt_101:write(10111, [Err]),
            %io:format("10111:~p~n", [Err]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData);
        false ->
            skip
    end;

handle(_Cmd, _LogicStatus, _Data) ->
    ?DEBUG("pp_change_name no match", []),
    {error, "pp_change_name no match"}.

update_guild_member([], _GuildName, _N) -> skip;
update_guild_member([[H] | T], GuildName, N) ->
    case N rem 5 of
        0 ->
            timer:sleep(20);
        _ -> 
            skip
    end,
    db:execute(io_lib:format(<<"update guild_member set guild_name = '~s' where id = ~p">>, [GuildName, H])),
    update_guild_member(T, GuildName, N + 1).

can_change_name(PlayerId) ->
    SQL10 = io_lib:format(<<"select c_rename from player_low where id = ~p limit 1">>, [PlayerId]),
    case db:get_row(SQL10) of
        [] ->
            skip;
        [CRename] ->
            case CRename of
                1 ->
                    {ok, BinData10} = pt_101:write(10100, [1]),
                    lib_server_send:send_to_uid(PlayerId, BinData10);
                _ -> 
                    skip
            end
    end.

can_change_guild(GuildId, PlayerId) ->
    SQL10 = io_lib:format(<<"select c_rename from guild where id = ~p limit 1">>, [GuildId]),
    case db:get_row(SQL10) of
        [] ->
            skip;
        [CRename] ->
            case CRename of
                1 ->
                    {ok, BinData10} = pt_101:write(10100, [2]),
                    lib_server_send:send_to_uid(PlayerId, BinData10);
                _ -> 
                    skip
            end
    end.

player_change_name(Status, Name) ->
    F = fun() ->
            db:execute(io_lib:format(<<"update charge set nickname = '~s' where player_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update equip_rank set role_name = '~s' where role_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update feedback set player_name = '~s' where player_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update guild_member set name = '~s' where id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update internal_manage set nickname = '~s' where id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update log_active set role_name = '~s' where role_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update log_flower set fromname = '~s' where fromid = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update log_flower set toname = '~s' where toid = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update log_gm_mail set nickname = '~s' where id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update log_recharge set playername = '~s' where playerid = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update log_sell set nickname1 = '~s' where seller = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update log_sell set nickname2 = '~s' where payer = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update log_tower set nickname = '~s' where player_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update master set name = '~s' where id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update master_apprentice set name = '~s' where id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update player_low set nickname = '~s', c_rename = 0 where id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update rank_coin_dungeon set role_name = '~s' where role_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update rank_king_dungeon set role_name = '~s' where role_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update rank_daily_flower set name = '~s' where id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update rank_equip set role_name = '~s' where role_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update rank_hotspring set nickname = '~s' where id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update sell_list set nickname = '~s' where pid = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update guild set initiator_name = '~s' where initiator_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update guild set chief_name = '~s' where chief_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update log_xianyuan set name = '~s' where uid = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update feedback set player_name = '~s' where player_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update activity_festival_card set sender_name = '~s' where sender_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update log_festival_card set sender_name = '~s' where sender_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update activity_festivial_lamp set role_name = '~s' where role_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update rank_fly_dungeon set role_name = '~s' where role_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update guild_dun set player_name = '~s' where player_id = ~p">>, [Name, Status#player_status.id])),
            db:execute(io_lib:format(<<"update log_guild_dun set player_name = '~s' where player_id = ~p">>, [Name, Status#player_status.id])),
            ok
    end,
    case db:transaction(F) of
        ok ->
            case mod_disperse:call_to_unite(lib_guild_base, get_guild_member_by_player_id, [Status#player_status.id]) of
                Any when is_record(Any, ets_guild_member) ->
                    %% 是否为帮主
                    case Any#ets_guild_member.position of
                        1 ->
                            case mod_disperse:call_to_unite(lib_guild_base, get_guild, [Any#ets_guild_member.guild_id]) of
                                GuildInfo when is_record(GuildInfo, ets_guild) ->
                                    mod_disperse:cast_to_unite(lib_guild_base, update_guild, [GuildInfo#ets_guild{chief_name = list_to_binary(Name)}]);
                                _ -> skip
                            end;
                        _ ->
                            skip
                    end,
                    mod_disperse:cast_to_unite(lib_guild_base, update_guild_member, [Any#ets_guild_member{name = list_to_binary(Name)}]);
                _Other -> 
                    skip
            end,
            Err = 1;
        _Error -> 
            catch util:errlog("change name error : ~p", [_Error]),
            Err = 0
    end,
    Err.

%% 给好友发送改名邮件
send_email_to_friend(Status, NewStatus) ->
    FriendList = lib_relationship:load_relas_by_id(Status#player_status.pid, Status#player_status.id, 1),
    send_email_to_friend2(Status, NewStatus, FriendList).

send_email_to_friend2(_Status, _NewStatus, []) -> skip;
send_email_to_friend2(Status, NewStatus, [H | T]) ->
    case is_record(H, ets_rela) of
        true ->
            Title = data_change_name_text:get_change_name_text(1),
            Content0 = data_change_name_text:get_change_name_text(2),
            Content = io_lib:format(Content0, [util:make_sure_list(Status#player_status.nickname), util:make_sure_list(NewStatus#player_status.nickname)]),
            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[H#ets_rela.idB], Title, Content, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        false ->
            skip
    end,
    send_email_to_friend2(Status, NewStatus, T).
