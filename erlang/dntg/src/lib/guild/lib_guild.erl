%% --------------------------------------------------------
%% @Module:           |lib_guild
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-00-00
%% @Description:      |帮派业务处理
%% --------------------------------------------------------

-module(lib_guild).
-include("common.hrl").
-include("record.hrl").
-include("server.hrl").
-include("goods.hrl").
-include("guild.hrl").
-include("sql_guild.hrl").
-include("unite.hrl").
-include("scene.hrl").
-include("sql_player.hrl").

-compile(export_all).

%%=========================================================================
%% 业务操作函数 
%%=========================================================================

%%判断是否为指定帮派职位
%% @param Type 职位类型(帮主bz,副帮主fbz,长老zl,堂主tz,帮众bzz)
%% @return true|false
is_guild_position(Type,Guild_position)->
	case Type of
		bz -> Guild_position=:=1;
		fbz -> Guild_position=:=2;
		zl -> Guild_position=:=3;
		tz -> Guild_position=:=4;
		bzz -> Guild_position=:=5;
		_->false
	end.

%% -----------------------------------------------------------------
%% 角色登录(供给公共线保留) 
%% -----------------------------------------------------------------
role_login(PlayerId) ->
	SQL  = io_lib:format(?SQL_PLAYER_GUILD_ID_SELECT, [PlayerId]),
    PlayerGuildId  = db:get_one(SQL),
	[GuildId, GuildName, GuildPosition, GuildLv] = case PlayerGuildId of
		0->	%% 玩家帮派ID为0
			[0, [], 0, 0];
		_->
			SQLGN = io_lib:format(?SQL_GET_GUILD_LV, [PlayerGuildId]),
			case db:get_one(SQLGN) of
				null -> %% 需要修正
					%% 删除成员表数据
					Data1 = [PlayerId, PlayerGuildId],
				    SQL1  = io_lib:format(?SQL_GUILD_MEMBER_DELETE_ONE, Data1),
				    db:execute(SQL1),
					%% 删除 玩家表数据
				    Data2 = [0, PlayerId],
				    SQL2  = io_lib:format(?SQL_PLAYER_LOW_UPDATE_GUILD_ID, Data2),
				    db:execute(SQL2),
					[0, [], 0, 0];
				_GuildLv -> %% 不需要修正
					Data1 = [PlayerId],
			        SQL1  = io_lib:format(?SQL_GUILD_MEMBER_SELECT_LOGIN, Data1),
			        case db:get_row(SQL1) of
						[_GuildId, _GuildName, _GuildPosition] ->
							[_GuildId, _GuildName, _GuildPosition, _GuildLv];
						_ -> 
				            [0, [], 0, 0]
					end
			end
	end,
	Gr = case GuildId =:= 0 of
			 true ->
				 {[], []};
			 false ->
				 [_, FList, EList] = case guild_rela_handle:db_read(GuildId) of
										 [] ->
											 [0, [], []];
										 RR ->
											 RR
									 end,
				 {FList, EList}
		 end,
	Sql = io_lib:format(?SQL_GUILD_GA_STAGE_SELECT_ONE, [GuildId]),
    [Stage, _StageExp] = case GuildId =:= 0 of
							 true ->
								 [1, 0];
							 false ->
								 case db:get_row(Sql) of
							        [] -> %% 没有数据
										[1, 0];
							        [_, StageOld, StageExpOld] ->
										[StageOld, StageExpOld]
							    end
						 end,
	[GuildId, util:make_sure_list(GuildName), GuildPosition, GuildLv, Gr, Stage].

role_login_unite(PlayerId) ->
	SQL  = io_lib:format(?SQL_PLAYER_GUILD_ID_SELECT, [PlayerId]),
    PlayerGuildId  = db:get_one(SQL),
	case PlayerGuildId of
		0->	%% 玩家帮派ID为0
			[0, <<>>, 0];
		_->
			[GuildId, GuildName, GuildPosition] = case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
		        GuildMember when is_record(GuildMember, ets_guild_member) ->
					GuildMemberNew = case GuildMember#ets_guild_member.position =:= 1 of
						true ->
							%% 读取数据库
							[DBChiefId, DBChiefName] = lib_guild_base:get_guild_c_db(GuildMember#ets_guild_member.guild_id),
							case DBChiefId of
								0 ->
									GuildMember#ets_guild_member{online_flag = 1};
								_ ->
									case DBChiefId =:= PlayerId of
										true ->
											GuildMember#ets_guild_member{online_flag = 1};
										false ->
											%% 修正缓存数据
											gen_server:cast(mod_guild, {fix_chief, GuildMember#ets_guild_member.guild_id, DBChiefId, DBChiefName}),
											GuildMember#ets_guild_member{online_flag = 1, position = 5}
									end
							end;
						false ->
							GuildMember#ets_guild_member{online_flag = 1}
					end, 
		            lib_guild_base:update_guild_member(GuildMemberNew),
					[GuildMemberNew#ets_guild_member.guild_id
					, GuildMemberNew#ets_guild_member.guild_name
					, GuildMemberNew#ets_guild_member.position];
		        _ ->
					Data1 = [PlayerId],
		            SQL1  = io_lib:format(?SQL_GUILD_MEMBER_SELECT_LOGIN, Data1),
		            case db:get_row(SQL1) of
						[_GuildId, _GuildName, _GuildPosition] ->
							[_GuildId, _GuildName, _GuildPosition];
						_ -> 
				            [0, <<>>, 0]
					end
		    end,
			case GuildPosition =:= 1 of
                true -> %% 帮主 记录登陆记录
                    spawn(fun() ->
                                timer:sleep(30 * 1000),
                                pp_change_name:can_change_guild(GuildId, PlayerId)
                        end),
					gen_server:cast(mod_guild, {chief_login, GuildId, PlayerId});
				false ->
					skip
			end,
			{ok, BinData} = pt_400:write(40099, [GuildId, util:make_sure_list(GuildName), GuildPosition]),
    		lib_unite_send:send_to_one(PlayerId, BinData),
			GuildLevel = get_guild_lv_only(GuildId),
			lib_player:update_player_info(PlayerId, [{guild_syn, [GuildId, GuildName, GuildPosition, GuildLevel]}]),
			[GuildId, GuildName, GuildPosition]
	end.

role_login_guild(PlayerId) ->
	case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
		GuildMember when is_record(GuildMember, ets_guild_member) ->
			NowTime     = util:unixtime(),
            GuildMemberNew = GuildMember#ets_guild_member{online_flag = 1, last_login_time = NowTime},
			lib_guild_base:update_guild_member(GuildMemberNew),
			lib_guild_base:update_guild_member_base1(GuildMemberNew);
        _ -> 
			void
    end.
%% -----------------------------------------------------------------
%% 角色_上线职位修正
%% -----------------------------------------------------------------
fix_chief([GuildMember, PlayerId]) ->
    GuildId    = GuildMember#ets_guild_member.guild_id,
    PlayerName = GuildMember#ets_guild_member.name,
    PlayerId   = GuildMember#ets_guild_member.id,
    Position   = GuildMember#ets_guild_member.position,
    SQL        = io_lib:format(?SQL_GUILD_MEMBER_SELECT_POSITION, [PlayerId]),
    Position1  = db:get_one(SQL),
    NewPosition
        = case Position1 =:= [] of
              true -> Position;
              false-> Position1
          end,
    case Position =/= NewPosition andalso NewPosition == 1 of
        true ->
            Guild      = mod_disperse:call_to_unite(lib_guild_base, get_guild, [GuildId]),
            case Guild =/= [] of
                true ->
                    ChiefId        = Guild#ets_guild.chief_id,
                    ChiefName      = Guild#ets_guild.chief_name,
                    DeputyChief1Id = Guild#ets_guild.deputy_chief1_id,
                    DeputyChief2Id = Guild#ets_guild.deputy_chief2_id,
                    case Position == 2 of
                        % 原来是副帮主1且帮主不是自己
                        true when DeputyChief1Id == PlayerId andalso ChiefId > 0 andalso ChiefId =/= PlayerId ->
                            GuildNew = Guild#ets_guild{chief_id           = PlayerId,
                                                       chief_name         = PlayerName,
                                                       deputy_chief1_id   = ChiefId,
                                                       deputy_chief1_name = ChiefName},
							lib_guild:update_guild(GuildNew, PlayerId),
                            demise_chief_logic(ChiefId, PlayerId, PlayerName, GuildId);
                        % 原来是副帮主2且帮主不是自己
                        true when DeputyChief2Id == PlayerId andalso ChiefId > 0 andalso ChiefId =/= PlayerId ->
                            GuildNew = Guild#ets_guild{chief_id           = PlayerId,
                                                       chief_name         = PlayerName,
                                                       deputy_chief2_id   = ChiefId,
                                                       deputy_chief2_name = ChiefName},
                            lib_guild:update_guild(GuildNew, PlayerId),
                            demise_chief_logic(ChiefId, PlayerId, PlayerName, GuildId);
                        % 原来是副帮主1且帮主不存在
                        true when DeputyChief1Id == PlayerId andalso ChiefId == 0 ->
                            GuildNew = Guild#ets_guild{chief_id           = PlayerId,
                                                       chief_name         = PlayerName,
                                                       deputy_chief1_id   = 0,
                                                       deputy_chief1_name = <<>>},
                            lib_guild:update_guild(GuildNew, PlayerId),
                            set_position_logic(PlayerId, 1);
                        % 原来是副帮主2且帮主不存在
                        true when DeputyChief2Id == PlayerId andalso ChiefId == 0 ->
                            GuildNew = Guild#ets_guild{chief_id           = PlayerId,
                                                       chief_name         = PlayerName,
                                                       deputy_chief2_id   = 0,
                                                       deputy_chief2_name = <<>>},
                            lib_guild:update_guild(GuildNew, PlayerId),
                            set_position_logic(PlayerId, 1);
                        % 原来是副帮主1且是帮主
                        true when DeputyChief1Id == PlayerId andalso ChiefId == PlayerId ->
                            GuildNew = Guild#ets_guild{deputy_chief1_id   = 0,
                                                       deputy_chief1_name = <<>>},
                            lib_guild:update_guild(GuildNew, PlayerId),
                            set_position_logic(PlayerId, 1);
                        % 原来是副帮主2且是帮主
                        true when DeputyChief2Id == PlayerId andalso ChiefId == PlayerId ->
                            GuildNew = Guild#ets_guild{deputy_chief2_id   = 0,
                                                       deputy_chief2_name = <<>>},
                            lib_guild:update_guild(GuildNew, PlayerId),
                            set_position_logic(PlayerId, 1);
                        true ->
                            void;
                        % 原来不是副帮主且帮主不是自己
                        false when ChiefId > 0 andalso ChiefId =/= PlayerId ->
                            GuildNew = Guild#ets_guild{chief_id           = PlayerId,
                                                       chief_name         = PlayerName},
                            lib_guild:update_guild(GuildNew, PlayerId),
                            set_position_logic(PlayerId, 1),
                            set_position_logic(ChiefId, Position);
                        % 原来不是副帮主且帮主不存在
                        false when ChiefId == 0 ->
                            GuildNew = Guild#ets_guild{chief_id           = PlayerId,
                                                       chief_name         = PlayerName},
                            lib_guild:update_guild(GuildNew, PlayerId),
                            set_position_logic(PlayerId, 1);
                        % 原来不是副帮主且是帮主
                        false when ChiefId == PlayerId ->
                            set_position_logic(PlayerId, 1);
                        false ->
                            viod
                    end;
                false->
                    void
            end;
        false->
            void
    end.

%% -----------------------------------------------------------------
%% 角色退出
%% -----------------------------------------------------------------
role_logout(PlayerId) when erlang:is_integer(PlayerId)->
    mod_disperse:cast_to_unite(lib_guild, role_logout, [[PlayerId]]),
	ok;
role_logout([PlayerId]) ->
	lib_guild_base:update_guild_member([offline, PlayerId]).

%% -----------------------------------------------------------------
%% 角色升级
%% -----------------------------------------------------------------
role_upgrade(PlayerId, Level) ->
    case  mod_disperse:call_to_unite(lib_guild_base, get_guild_member_by_player_id, [PlayerId]) of
        GuildMember when is_record(GuildMember, ets_guild_member) ->
            GuildMemberNew = GuildMember#ets_guild_member{level = Level},
            mod_disperse:cast_to_unite(lib_guild_base, update_guild_member, [GuildMemberNew]);
		_ -> []
    end,
    case  mod_disperse:call_to_unite(lib_guild_base, get_guild_apply_by_player_id, [PlayerId]) of
        GuildApply when is_record(GuildApply, ets_guild_apply) ->
            GuildApplyNew = GuildApply#ets_guild_apply{player_level = Level},
            mod_disperse:cast_to_unite(lib_guild_base, update_guild_apply, [GuildApplyNew]);
		[] -> 
			[]
    end.

%% -----------------------------------------------------------------
%% 删除角色
%% -----------------------------------------------------------------
delete_role(PlayerId) ->
    case  mod_disperse:call_to_unite(lib_guild_base, get_guild_member_by_player_id, [PlayerId]) of
        % 参加了帮派
        GuildMember when is_record(GuildMember, ets_guild_member) ->
            case GuildMember#ets_guild_member.position of
                1 ->
                    confirm_disband_guild(GuildMember#ets_guild_member.guild_id, GuildMember#ets_guild_member.guild_name, 1);
                _ ->
                    GuildId = GuildMember#ets_guild_member.guild_id,
                    Guild   = mod_disperse:call_to_unite(lib_guild_base, get_guild, [GuildId]),
                    case Guild of
                        [] ->
                            ?ERR("delete_role: Not find guild, id=[~p]", [GuildId]);
                        _  ->
                            NewGuildMemberNum = Guild#ets_guild.member_num-1,
                            case remove_guild_member(PlayerId, GuildId, NewGuildMemberNum) of
                                ok ->
                                    case PlayerId == Guild#ets_guild.deputy_chief1_id of
                                        % 副帮主1被删除
                                        true ->
                                            GuildNew = Guild#ets_guild{member_num         = NewGuildMemberNum,
                                                                       deputy_chief_num   = Guild#ets_guild.deputy_chief_num -1,
                                                                       deputy_chief1_id   = 0,
                                                                       deputy_chief1_name = <<>>},
                                            lib_guild:update_guild(GuildNew, PlayerId);
                                        % 副帮主2被删除
                                        false when PlayerId == Guild#ets_guild.deputy_chief2_id ->
                                            GuildNew = Guild#ets_guild{member_num         = NewGuildMemberNum,
                                                                       deputy_chief_num   = Guild#ets_guild.deputy_chief_num -1,
                                                                       deputy_chief2_id   = 0,
                                                                       deputy_chief2_name = <<>>},
                                            lib_guild:update_guild(GuildNew, PlayerId);
                                        % 非副帮主1被删除
                                        false ->
                                            GuildNew = Guild#ets_guild{member_num = NewGuildMemberNum},
                                            lib_guild:update_guild(GuildNew, PlayerId)
                                    end;
                                _  ->
                                    void
                            end,
                            % 删除帮派申请
                            mod_disperse:cast_to_unite(lib_guild, remove_guild_invite_all, [PlayerId]),
                            % 删除帮派邀请
                            mod_disperse:cast_to_unite(lib_guild, remove_guild_apply_all, [PlayerId])
                    end
            end;
		% 未参加帮派
        [] ->
            % 删除帮派申请
            mod_disperse:cast_to_unite(lib_guild, remove_guild_invite_all, [PlayerId]),
            % 删除帮派邀请
            mod_disperse:cast_to_unite(lib_guild, remove_guild_apply_all, [PlayerId])
    end,
    ok.

%% -----------------------------------------------------------------
%% 创建帮派
%% 修改历史：2010/10/30 创建帮派时的帮派宗旨改为帮派公告
%% MergeTime : 合服标识，在#unite_status.mergetime
%% -----------------------------------------------------------------
create_guild(MergeTime, PlayerId, PlayerName, PlayerRealm, GuildName, GuildTenet, UseType) ->
    CreateTime              = util:unixtime(),
    FreeDay                 = data_guild:get_guild_config(contribution_free_day, []),
    ContributionGetNextTime = CreateTime + FreeDay*(?ONE_DAY_SECONDS),
    Level = case UseType of
                0 -> 1;
                1 -> 2
            end,
    Data       = [GuildName, GuildTenet, PlayerId, PlayerName, PlayerId, PlayerName, PlayerRealm, CreateTime, ContributionGetNextTime, Level, UseType, 1, 1, 1, 1, 1, 1,util:term_to_string([0,0])],
    SQL        = io_lib:format(?SQL_GUILD_INSERT, Data),
    db:execute(SQL),
    Data1   = [GuildName],
    SQL1    = io_lib:format(?SQL_GUILD_SELECT_CREATE, Data1),
    Guild = db:get_row(SQL1),
    if Guild =:= [] ->
            ?ERR("create_guild: guild id is null, name=[~s]", [GuildName]),
            error;
        true ->
            [GuildId|_]   = Guild,
            Data2         = [PlayerId, PlayerName, GuildId, GuildName, 1, CreateTime],
            SQL2          = io_lib:format(?SQL_GUILD_MEMBER_INSERT, Data2),
            db:execute(SQL2),
			Data_Low         = [GuildId, PlayerId],
		    SQL1_Low         = io_lib:format(?SQL_PLAYER_LOW_UPDATE_GUILD_ID, Data_Low),
			db:execute(SQL1_Low),
            remove_guild_apply_all(PlayerId),
            remove_guild_invite_all(PlayerId),
            lib_guild_base:load_guild_into_ets(Guild),
			lib_factionwar:insert_into_factionwar(GuildId,GuildName,PlayerId,PlayerRealm),
			%% 触发名人堂：第一面旗，第一个建立帮会
			lib_player_unite:trigger_fame(PlayerId, [MergeTime, PlayerId, 11, 0, 1]),
            {ok, GuildId}
	end.

%% -----------------------------------------------------------------
%% 申请解散帮派
%% -----------------------------------------------------------------
apply_disband_guild(GuildId) ->
    % 更新帮派
    ConfirmDay  = data_guild:get_guild_config(disband_confirm_day, []),
    ConfirmTime = util:unixtime() + ConfirmDay*(?ONE_DAY_SECONDS),
    Data        = [1, ConfirmTime, GuildId],
    SQL         = io_lib:format(?SQL_GUILD_UPDATE_DISBAND_INFO, Data),
    db:execute(SQL),
    [ok, ConfirmTime].

%% -----------------------------------------------------------------
%% 确认解散帮派
%% -----------------------------------------------------------------
confirm_disband_guild(GuildId, GuildName, ConfirmResult) ->
    if ConfirmResult == 0 ->
            % 更新帮派表
            Data = [0, 0, GuildId],
            SQL  = io_lib:format(?SQL_GUILD_UPDATE_DISBAND_INFO, Data),
            db:execute(SQL);
       true ->
		   case db:transaction(fun() ->confirm_disband_guild_db(GuildId, GuildName) end) of
				ok ->
		    		lib_goods_util:delete_goods_by_guild(GuildId),
		            %% 邮件通知给帮派成员
		            NameList  = get_member_name_list(GuildId),
		            mod_guild:send_guild_mail(guild_disband, [GuildId, GuildName, NameList]),
                    %% 给帮派成员发送神炉返利
                    lib_guild_base:send_furnace_back(GuildId),
		            lib_guild_base:delete_guild(GuildId),
		            lib_guild_base:delete_guild_member_by_guild_id(GuildId),
		            lib_guild_base:delete_guild_invite_by_guild_id(GuildId),
		            lib_guild_base:delete_guild_apply_by_guild_id(GuildId),
					ok;
				_ ->
					false
			end
    end,
    ok.

confirm_disband_guild_db(GuildId, _GuildName) ->
	%lib_city_war:delete_win_guild(GuildId),
    Data = [GuildId],
    SQL  = io_lib:format(?SQL_GUILD_DELETE, Data),
    db:execute(SQL),
    Data1 = [GuildId],
    SQL1  = io_lib:format(?SQL_GUILD_MEMBER_DELETE, Data1),
    db:execute(SQL1),
    Data2 = [GuildId],
    SQL2  = io_lib:format(?SQL_GUILD_APPLY_DELETE, Data2),
    db:execute(SQL2),
    Data3 = [GuildId],
    SQL3  = io_lib:format(?SQL_GUILD_INVITE_DELETE, Data3),
    db:execute(SQL3),
    Data4 = [GuildId],
    SQL4  = io_lib:format(?SQL_GUILD_EVENT_DELETE, Data4),
    db:execute(SQL4),
	Data5 = [GuildId],
    SQL5  = io_lib:format("delete from factionwar where faction_id = ~p", Data5),
    db:execute(SQL5),
	Data6 = [GuildId],
	%% 删除神兽升级记录
    SQL6  = io_lib:format(?SQL_GUILD_GODANIMAL_DELETE_ONE, Data6),
    db:execute(SQL6),
	%% 删除神兽升阶记录
	SQL7  = io_lib:format(?SQL_GUILD_GA_STAGE_DELETE_ONE, Data6),
    db:execute(SQL7),
	ok.
	
%% -----------------------------------------------------------------
%% 添加帮派加入申请
%% -----------------------------------------------------------------
add_guild_apply(PlayerId, GuildId) ->
    Data       = [PlayerId, GuildId],
    SQL        = io_lib:format(?SQL_GUILD_APPLY_DELETE_ONE, Data),
    db:execute(SQL),
    CreateTime  = util:unixtime(),
    Data1       = [PlayerId, GuildId, CreateTime],
    SQL1        = io_lib:format(?SQL_GUILD_APPLY_INSERT, Data1),
    db:execute(SQL1),
    Data2 = [PlayerId, GuildId],
    SQL2  = io_lib:format(?SQL_GUILD_APPLY_SELECT_BY_2, Data2),
    [_Id, _GuildId, _PlayerId, _CreateTime, _NickName, _Sex, _Lv, _Career] = db:get_row(SQL2),
    SQL3 = io_lib:format(?sql_player_vip_data, [_PlayerId]),
    [_VipType, _VipTime, _VipBagFlag] = db:get_row(SQL3),
    GuildApply = [_Id, _GuildId, _PlayerId, _CreateTime, _NickName, _Sex,  _Lv, _Career, _VipType],
    lib_guild_base:load_guild_apply_into_ets(GuildApply),
    ok.
    
%% -----------------------------------------------------------------
%% 添加帮派邀请
%% -----------------------------------------------------------------
add_guild_invite(PlayerId, GuildId) ->
    CreateTime = util:unixtime(),
    Data       = [PlayerId, GuildId, CreateTime],
    SQL        = io_lib:format(?SQL_GUILD_INVITE_INSERT, Data),
    db:execute(SQL),
    Data1 = [PlayerId, GuildId],
    SQL1  = io_lib:format(?SQL_GUILD_INVITE_SELECT_NEW, Data1),
    GuildInvite = db:get_row(SQL1),
    lib_guild_base:load_guild_invite_into_ets(GuildInvite),
    ok.

%% -----------------------------------------------------------------
%% 删除帮派申请
%% -----------------------------------------------------------------
remove_guild_apply(PlayerId, GuildId) ->
    Data = [PlayerId, GuildId],    
    SQL  = io_lib:format(?SQL_GUILD_APPLY_DELETE_ONE, Data),
    db:execute(SQL),
    lib_guild_base:delete_guild_apply_by_player_id(PlayerId, GuildId),
    ok.

%% -----------------------------------------------------------------
%% 删除帮派邀请
%% -----------------------------------------------------------------
remove_guild_invite(PlayerId, GuildId) ->
    Data = [PlayerId, GuildId],
    SQL  = io_lib:format(?SQL_GUILD_INVITE_DELETE_ONE, Data),
    db:execute(SQL),
    lib_guild_base:delete_guild_invite_by_player_id(PlayerId, GuildId),
    ok.

%% -----------------------------------------------------------------
%% 删除角色所有的帮派申请
%% -----------------------------------------------------------------
remove_guild_apply_all(PlayerId) ->
    Data = [PlayerId],
    SQL  = io_lib:format(?SQL_GUILD_APPLY_DELETE_ALL, Data),
    db:execute(SQL),
    lib_guild_base:delete_guild_apply_by_player_id(PlayerId),
    ok.

%% -----------------------------------------------------------------
%% 删除帮派邀请
%% -----------------------------------------------------------------
remove_guild_invite_all(PlayerId) ->
    Data = [PlayerId],
    SQL  = io_lib:format(?SQL_GUILD_INVITE_DELETE_ALL, Data),
    db:execute(SQL),
    lib_guild_base:delete_guild_invite_by_player_id(PlayerId),
    ok.

%% -----------------------------------------------------------------
%% 添加新成员
%% 并发冲突解决：
%% 1- 帮主或者副帮主同时审批加入某个相同成员时可能造成并发冲突。
%% 2- 同时插入成员记录会造成字段唯一值的约束违背导致失败。
%% 3- 程序判断操作是否成功，如果成功则更新缓存，否则仅通知客户端操作失败。
%% -----------------------------------------------------------------
add_guild_member(PlayerId, PlayerName, GuildId, GuildName, GuildLv, GuildPosition, MemberNum) ->
	case db:transaction(fun() ->add_guild_member_db(PlayerId, PlayerName, GuildId, GuildName, GuildLv, GuildPosition, MemberNum) end) of
		{ok, GuildMember} ->
    		lib_guild_base:delete_guild_invite_by_player_id(PlayerId),
		    lib_guild_base:delete_guild_apply_by_player_id(PlayerId),
			lib_guild_base:load_guild_member_into_ets(GuildMember),
			ok;
		_ ->
			false
	end.

add_guild_member_db(PlayerId, PlayerName, GuildId, GuildName, _GuildLv, GuildPosition, MemberNum) ->
    CreateTime    = util:unixtime(),
    Data          = [PlayerId, PlayerName, GuildId, GuildName, GuildPosition, CreateTime],
    SQL           = io_lib:format(?SQL_GUILD_MEMBER_INSERT, Data),
	Data_Low         = [GuildId, PlayerId],
    SQL1_Low         = io_lib:format(?SQL_PLAYER_LOW_UPDATE_GUILD_ID, Data_Low),
	db:execute(SQL1_Low),
	db:execute(SQL),
    modify_guild_member_num(GuildId, MemberNum),
    DataAPPLY = [PlayerId],
    SQLAPPLY  = io_lib:format(?SQL_GUILD_APPLY_DELETE_ALL, DataAPPLY),
    db:execute(SQLAPPLY),
    DataINVITE = [PlayerId],
    SQLINVITE  = io_lib:format(?SQL_GUILD_INVITE_DELETE_ALL, DataINVITE),
    db:execute(SQLINVITE),
    Data1 = [PlayerId],
    SQL1  = io_lib:format(?SQL_GUILD_MEMBER_SELECT_NEW, Data1),
    [_Id, _Name, _GuildId, _GuildName, _DonateTotal, _DonateTotalCard, _DonateTotalCoin, _DonateLastTime, _DonateTotalLastDay, _DonateTotalLastWeek, _PaidGetLastTime, _CreateTime, _Title, _Remark, _Honor, _DepotStoreLastTime, _DepotStoreNum, _Position, _Version, _Donate,_PaidAdd, _Sex, _Level, _Career, _Image, _Material, _FurnaceBack, _DailyFurnaceBack] = db:get_row(SQL1),
    SQL2 = io_lib:format(?SQL_PLAYER_LOGIN_SELECT_LAST_LOGIN_TIME, [PlayerId]),
    _LastLoginTime = db:get_one(SQL2),
    SQL3 = io_lib:format(?sql_player_vip_data, [PlayerId]),
    [_VipType, _VipTime, _VipBagFlag] = db:get_row(SQL3),
    %% 帮派战功
    FactionWar = lib_factionwar:load_player_factionwar_guild(_Id),
    GMM = [_Id, _Name, _GuildId, _GuildName, _DonateTotal, _DonateTotalCard, _DonateTotalCoin, _DonateLastTime, _DonateTotalLastDay, _DonateTotalLastWeek, _PaidGetLastTime, _CreateTime, _Title, _Remark, _Honor, _DepotStoreLastTime, _DepotStoreNum, _Position, _Version, _Donate, _PaidAdd, _Sex, _Level, _Career, _LastLoginTime, _Image, _VipType, _Material, _FurnaceBack, _DailyFurnaceBack, FactionWar],
	{ok, GMM}.
	

add_guild_member_award(Guild, NewGuildMemberNum) ->
    ContributionTotal  = case NewGuildMemberNum =< 10 of
                             true -> Guild#ets_guild.contribution + 100;
                             false-> Guild#ets_guild.contribution
                         end,
    [NewLevel, NewMemberCapacity, NewContribution, NewContributionThreshold, NewContributionDaily] = calc_new_level(Guild#ets_guild.level, ContributionTotal, Guild#ets_guild.member_capacity, Guild#ets_guild.level),
    if  % (1) 帮派升级
        NewLevel > Guild#ets_guild.level ->
			lib_guild:get_guild_award(Guild#ets_guild.level, NewLevel, Guild#ets_guild.id),
            Data1 = [NewLevel, NewContribution, Guild#ets_guild.id],
            SQL1  = io_lib:format(?SQL_GUILD_UPDATE_GRADE, Data1),
            db:execute(SQL1),
            % 更新缓存
            GuildNew = Guild#ets_guild{level                  = NewLevel,
                                       member_capacity        = NewMemberCapacity,
                                       contribution           = NewContribution,
                                       contribution_threshold = NewContributionThreshold,
                                       contribution_daily     = NewContributionDaily,
                                       member_num             = NewGuildMemberNum},
           lib_guild:update_guild(GuildNew),
           % 通知成员
           lib_guild:send_guild(Guild#ets_guild.id, 'guild_upgrade', [Guild#ets_guild.id, Guild#ets_guild.name, Guild#ets_guild.level, NewLevel]);
        % (2) 帮派没有升级
        true ->
            Data1 = [ContributionTotal, Guild#ets_guild.id],
            SQL1  = io_lib:format(?SQL_GUILD_UPDATE_CONTRIBUTION, Data1),
            db:execute(SQL1),
            % 更新缓存
            GuildNew = Guild#ets_guild{contribution           = NewContribution,
                                       member_num             = NewGuildMemberNum},
            lib_guild:update_guild(GuildNew)
    end.

%% -----------------------------------------------------------------
%% 删除成员
%% -----------------------------------------------------------------
remove_guild_member(PlayerId, GuildId, MemberNum) ->
	%% 更改退帮次数
    change_guild_quit_num(PlayerId),
    Data1 = [PlayerId, GuildId],
    SQL1  = io_lib:format(?SQL_GUILD_MEMBER_DELETE_ONE, Data1),
    db:execute(SQL1),
    Data2 = [0, PlayerId],
    SQL2  = io_lib:format(?SQL_PLAYER_LOW_UPDATE_GUILD_ID, Data2),
    db:execute(SQL2),
    modify_guild_member_num(GuildId, MemberNum),
    ok.

%% -----------------------------------------------------------------
%% 查询帮派_获取帮派列表_帮派列表打包_分页等处理
%% @param  Type:      查询类型: 0 全部, 1 按ID查询, 2 按名字查询, 3 按等级查询, 4 按解散状态查询, 5 UPPERNAME查询, 
%%							    6 按国家查询, 7 按帮主名字查询 8 同时输入帮主名字和帮派名字
%%							    11 国家,帮派名字, 12 国家,帮主名字 13, 国家, 帮派名字, 帮主名字
%% -----------------------------------------------------------------
search_guild(PlayerId, Realm, GuildName, ChiefName, PageSize, PageNo, WashType, SelfGuildId, SelfShow) ->
    ApplyGuild = lib_guild_base:get_guild_apply_by_player_id(PlayerId),
	AppIdList = [{OneApp#ets_guild_apply.guild_id}||OneApp <- ApplyGuild],
    Guilds = case Realm == 0 of
                 true ->
                     case GuildName =:= <<>> andalso ChiefName =:= <<>> of
                         true  ->
							gen_server:call(mod_guild, {get_guild, [0, 0]}, 7000);
                         false when GuildName =/= <<>> andalso ChiefName =:= <<>>  ->
							gen_server:call(mod_guild, {get_guild, [GuildName, 2]}, 7000);
                         false when GuildName =:= <<>> andalso ChiefName =/= <<>>  ->
							gen_server:call(mod_guild, {get_guild, [ChiefName, 7]}, 7000);
                         false when GuildName =/= <<>> andalso ChiefName =/= <<>>  ->
							gen_server:call(mod_guild, {get_guild, [[GuildName, ChiefName], 8]}, 7000)
                     end;
                 false  ->
                     case GuildName =:= <<>> andalso ChiefName =:= <<>> of
                         true  ->
                            gen_server:call(mod_guild, {get_guild, [Realm, 6]}, 7000);
                         false when GuildName =/= <<>> andalso ChiefName =:= <<>>  ->
                            gen_server:call(mod_guild, {get_guild, [[Realm, GuildName], 11]}, 7000);
                         false when GuildName =:= <<>> andalso ChiefName =/= <<>>  ->
                            gen_server:call(mod_guild, {get_guild, [[Realm, ChiefName], 12]}, 7000);
                         false when GuildName =/= <<>> andalso ChiefName =/= <<>>  ->
                            gen_server:call(mod_guild, {get_guild, [[Realm, GuildName, ChiefName], 13]}, 7000)
                     end
             end,
	Guild_List = [Guild_R || {_, Guild_R} <- Guilds],
	GuildRelaDict = guild_rela_handle:get_self_rela(SelfGuildId),
	WashedGuildList = case WashType of
						  0 ->
							  Guild_List;
						  1 ->
							  [GuildOne || GuildOne <- Guild_List, GuildOne#ets_guild.member_capacity > GuildOne#ets_guild.member_num];
						  2 ->
							  [GuildOne || GuildOne <- Guild_List, dict:find(GuildOne#ets_guild.id, GuildRelaDict) =/=  error];
						  3 ->
							  Step1 = [GuildOne1 || GuildOne1 <- Guild_List, dict:find(GuildOne1#ets_guild.id, GuildRelaDict) =/= error],
							  [GuildOne || GuildOne <- Step1, GuildOne#ets_guild.member_capacity > GuildOne#ets_guild.member_num];
						  4 ->
							  [GuildOne || GuildOne <- Guild_List, dict:find(GuildOne#ets_guild.id, GuildRelaDict) =:=  error];
						  _ ->
							  Guild_List
    end,
	SelfChekGuildList = case SelfShow of
						  0 ->
							  [GuildOne2 || GuildOne2 <- WashedGuildList, GuildOne2#ets_guild.id =/= SelfGuildId];
						  _ ->
							  WashedGuildList
    end,
    SortedGuilds = lists:sort(fun sort_guild_by_level/2, SelfChekGuildList),
    RecordTotal  = length(SortedGuilds),
    {PageTotal, StartPos, RecordNum} = calc_page_cache(RecordTotal, PageSize, PageNo),
    RowsPage = lists:sublist(SortedGuilds, StartPos, PageSize),
	GuildIdList = [GuildOne#ets_guild.id || GuildOne <- RowsPage],
	MoreInfo = gen_server:call(mod_guild, {get_40034_more, [GuildIdList]}),
	PageAddApp = lists:map(fun(GOne)-> handle_apply_info(GOne, AppIdList, GuildRelaDict, MoreInfo) end, RowsPage),
    Records = lists:map(fun handle_guild_page/1, PageAddApp),
    [1, 0, PageTotal, PageNo, RecordNum, list_to_binary(Records)].


%% 私有_处理帮派列表
sort_guild_by_level(Guild1, Guild2) ->
    case Guild1#ets_guild.level < Guild2#ets_guild.level of
        true  -> false;
        false when (Guild1#ets_guild.level == Guild2#ets_guild.level) andalso (Guild1#ets_guild.house_level < Guild2#ets_guild.house_level) -> false;
        false when (Guild1#ets_guild.level == Guild2#ets_guild.level) andalso (Guild1#ets_guild.house_level == Guild2#ets_guild.house_level) andalso (Guild1#ets_guild.member_num < Guild2#ets_guild.member_num) -> false;
        false when (Guild1#ets_guild.level == Guild2#ets_guild.level) andalso (Guild1#ets_guild.house_level == Guild2#ets_guild.house_level) andalso (Guild1#ets_guild.member_num == Guild2#ets_guild.member_num) andalso (Guild1#ets_guild.contribution < Guild2#ets_guild.contribution) -> false;
        false when (Guild1#ets_guild.level == Guild2#ets_guild.level) andalso (Guild1#ets_guild.house_level == Guild2#ets_guild.house_level) andalso (Guild1#ets_guild.member_num == Guild2#ets_guild.member_num) andalso (Guild1#ets_guild.contribution == Guild2#ets_guild.contribution) andalso (Guild1#ets_guild.funds < Guild2#ets_guild.funds) -> false;
        false when (Guild1#ets_guild.level == Guild2#ets_guild.level) andalso (Guild1#ets_guild.house_level == Guild2#ets_guild.house_level) andalso (Guild1#ets_guild.member_num == Guild2#ets_guild.member_num) andalso (Guild1#ets_guild.contribution == Guild2#ets_guild.contribution) andalso (Guild1#ets_guild.funds == Guild2#ets_guild.funds) andalso (Guild1#ets_guild.id > Guild2#ets_guild.id) -> false;
        false -> true
    end.
handle_guild_page([GuildId, GuildName, ChiefId, ChiefName, MemberNum, MemberCapacity, Level, Realm, Tenet, Funds, Announce, CreateType, HouseLevel, Is_Apply, Rela, Vip, Friend, ApplySetting, MinApplyLevel, MinApplyPower]) ->
    GuildNameLen = byte_size(util:make_sure_binary(GuildName)),
    ChiefNameLen = byte_size(util:make_sure_binary(ChiefName)),
    TenetLen     = byte_size(util:make_sure_binary(Tenet)),
    AnnounceLen  = byte_size(util:make_sure_binary(Announce)),
    [FriendLen, FriendName]  = case Friend == [] of
					 true ->
						 [0, <<>>];
					 false ->
						 [byte_size(util:make_sure_binary(Friend)), Friend]
				 end,
    <<GuildId:32, GuildNameLen:16, GuildName/binary, ChiefId:32, ChiefNameLen:16, ChiefName/binary, MemberNum:16, MemberCapacity:16, Level:16, Realm:16, TenetLen:16, Tenet/binary, Funds:32, AnnounceLen:16, Announce/binary, CreateType:8, HouseLevel:16, Is_Apply:8, Rela:8, Vip:16, FriendLen:16, FriendName/binary, ApplySetting:8, MinApplyLevel:8, MinApplyPower:32>>.

%% 添加是否申请记录和帮派关系信息
handle_apply_info(Guild, AppIdList, RelaDict, MoreInfo)->
	[GuildId, GuildName, ChiefId, ChiefName, MemberNum, MemberCapacity, Level, Realm, Tenet, Funds, Announce, CreateType, HouseLevel, ApplySetting, AutoPassConfig] =
        [Guild#ets_guild.id, Guild#ets_guild.name, Guild#ets_guild.chief_id, Guild#ets_guild.chief_name, Guild#ets_guild.member_num, Guild#ets_guild.member_capacity, Guild#ets_guild.level, Guild#ets_guild.realm, Guild#ets_guild.tenet, Guild#ets_guild.funds, Guild#ets_guild.announce, Guild#ets_guild.create_type, Guild#ets_guild.house_level, Guild#ets_guild.apply_setting, Guild#ets_guild.auto_passconfig],
	Is_Apply = case lists:keyfind(GuildId, 1, AppIdList) of
				   false ->
					   0;
				   _ ->
					   1
			   end,
	Rela = case dict:find(GuildId, RelaDict) of
			   {ok, Value} ->
				   Value;
			   _ ->
				   0
		   end,
	[Vip, Friend] = case lists:keyfind(GuildId, 1, MoreInfo) of
	   {_, VipX, FriendX} ->
		   [VipX, FriendX];
	   _ ->
		   [0, []]
    end,
    [MinApplyLevel, MinApplyPower] = case AutoPassConfig of 
        [_MinApplyLevel, _MinApplyPower] -> [_MinApplyLevel, _MinApplyPower];
        _ -> [0, 0]
    end,
	[GuildId, GuildName, ChiefId, ChiefName, MemberNum, MemberCapacity, Level, Realm, Tenet, Funds, Announce, CreateType, HouseLevel, Is_Apply, Rela, Vip, Friend, ApplySetting, MinApplyLevel, MinApplyPower].

%% get_guild_page(PageSize, PageNo) ->
%%     % 获取总记录数
%%     Guilds = lib_guild_base:get_guild_all(),
%%     SortedGuilds = lists:sort(fun sort_guild_by_level/2, Guilds),
%%     RecordTotal  = length(SortedGuilds),
%%     {PageTotal, StartPos, RecordNum} = calc_page_cache(RecordTotal, PageSize, PageNo),
%%     RowsPage = lists:sublist(SortedGuilds, StartPos, PageSize),
%%     % 处理分页
%%     Records = lists:map(fun handle_guild_page/1, RowsPage),
%%     [1, PageTotal, PageNo, RecordNum, list_to_binary(Records)].

%% -----------------------------------------------------------------
%% 获取成员列表
%% 默认排序:	Type    0 => 根据在线否,是否VIP 职位等
%% 排序类型:    		1 => 日贡献降序  
%% 排序类型:       		2 => 周贡献降序  
%% 排序类型:        	3 => 总贡献降序
%% -----------------------------------------------------------------
get_guild_member_page(GuildId, PageSize, PageNo, Type) ->
    %?DEBUG("get_guild_member_page: GuildId=[~p], PageSize=[~p], PageNo=[~p]", [GuildId, PageSize, PageNo]),
	F = fun(GuildMember1, GuildMember2) ->
				case Type of
					0 ->
					    case GuildMember1#ets_guild_member.online_flag < GuildMember2#ets_guild_member.online_flag of
					        true -> false;
					        false when GuildMember1#ets_guild_member.online_flag == GuildMember2#ets_guild_member.online_flag andalso GuildMember1#ets_guild_member.position > GuildMember2#ets_guild_member.position -> false;
					        false when GuildMember1#ets_guild_member.online_flag == GuildMember2#ets_guild_member.online_flag andalso GuildMember1#ets_guild_member.position == GuildMember2#ets_guild_member.position andalso GuildMember1#ets_guild_member.vip < GuildMember2#ets_guild_member.vip -> false;
					        false-> true
					    end;
					1 ->
						DonateDaliy1 = mod_daily_dict:get_count(GuildMember1#ets_guild_member.id, 3700002),
						DonateDaliy2 = mod_daily_dict:get_count(GuildMember2#ets_guild_member.id, 3700002),
						case DonateDaliy1 >= DonateDaliy2 of
					        true -> true;
					        false-> false
					    end;
					2 ->
						case GuildMember1#ets_guild_member.donate_total_lastweek >= GuildMember2#ets_guild_member.donate_total_lastweek of
					        true -> true;
					        false-> false
					    end;
					3 ->
						case GuildMember1#ets_guild_member.donate_total >= GuildMember2#ets_guild_member.donate_total of
					        true -> true;
					        false-> false
					    end;
					_->
						true
				end
		end,
    % 获取总记录数
    GuildMembers = lib_guild_base:get_guild_member_by_guild_id(GuildId),
    SortedGuildMembers = lists:sort(F, GuildMembers),
    RecordTotal  = length(SortedGuildMembers),
    % 计算分页
    {PageTotal, StartPos, RecordNum} = calc_page_cache(RecordTotal, PageSize, PageNo),
    %?DEBUG("get_guild_member_page: PageTotal=[~p], StartPos=[~p], RecordNum=[~p]", [PageTotal, StartPos, RecordNum]),
    % 获取分页
    RowsPage = lists:sublist(SortedGuildMembers, StartPos, PageSize),
    % 处理分页
    Records = lists:map(fun handle_member_page/1, RowsPage),
    % 发送回应
    [1, PageTotal, PageNo, RecordNum, list_to_binary(Records)].


%% 私有_处理成员列表
handle_member_page(GuildMember) ->
    [PlayerId, PlayerName, PlayerSex, PlayerLevel, GuildPosition, Donate, OnlineFlag, PlayerCareer, GuildTitle, LastLoginTime, Image, Vip] =
        [GuildMember#ets_guild_member.id, GuildMember#ets_guild_member.name, GuildMember#ets_guild_member.sex, GuildMember#ets_guild_member.level, GuildMember#ets_guild_member.position, GuildMember#ets_guild_member.donate, GuildMember#ets_guild_member.online_flag, GuildMember#ets_guild_member.career, GuildMember#ets_guild_member.title, GuildMember#ets_guild_member.last_login_time, GuildMember#ets_guild_member.image, GuildMember#ets_guild_member.vip],
    PlayerNameLen = byte_size(PlayerName),
    GuildTitleLen = byte_size(GuildTitle),
%% 	DonateDaliy = GuildMember#ets_guild_member.donate,
	DonateDaliy = mod_daily_dict:get_count(PlayerId, 3700002),
	DonateWeek = GuildMember#ets_guild_member.donate_total_lastweek,
	DonateTotal = GuildMember#ets_guild_member.donate_total,
	IsOldBUck = 0,
%% 	[{_, IsOldBUck}] = lib_special_activity:is_old_buck([PlayerId]),
    <<PlayerId:32, PlayerNameLen:16, PlayerName/binary, PlayerSex:16, PlayerCareer:16, PlayerLevel:16, GuildPosition:16, Donate:32, OnlineFlag:16, GuildTitleLen:16, GuildTitle/binary, LastLoginTime:32, Image:16, Vip:8, DonateDaliy:32, DonateWeek:32, DonateTotal:32, IsOldBUck:8>>.

%% -----------------------------------------------------------------
%% 获取申请列表
%% -----------------------------------------------------------------
get_guild_apply_page(GuildId, PageSize, PageNo) ->
    %?DEBUG("get_guild_apply_page: GuildId=[~p], PageSize=[~p], PageNo=[~p]", [GuildId, PageSize, PageNo]),
    % 获取总记录数
    GuildApplys = lib_guild_base:get_guild_apply_by_guild_id(GuildId),
    RecordTotal  = length(GuildApplys),
    % 计算分页
    {PageTotal, StartPos, RecordNum} = calc_page_cache(RecordTotal, PageSize, PageNo),
    %?DEBUG("get_guild_apply_page: PageTotal=[~p], StartPos=[~p], RecordNum=[~p]", [PageTotal, StartPos, RecordNum]),
    % 获取分页
    RowsPage = lists:sublist(GuildApplys, StartPos, PageSize),
    % 处理分页
    Records = lists:map(fun handle_apply_page/1, RowsPage),
    % 发送回应
    [1, PageTotal, PageNo, RecordNum, list_to_binary(Records)].

%% 私有_处理申请列表
handle_apply_page(GuildApply) ->
    [PlayerId, PlayerName, PlayerSex, PlayerLevel, ApplyTime, PlayerCareer, OnlineFlag, PlayerVipType] =
        [GuildApply#ets_guild_apply.player_id, GuildApply#ets_guild_apply.player_name, GuildApply#ets_guild_apply.player_sex, GuildApply#ets_guild_apply.player_level, GuildApply#ets_guild_apply.create_time, GuildApply#ets_guild_apply.player_career, GuildApply#ets_guild_apply.online_flag, GuildApply#ets_guild_apply.player_vip_type],
    PlayerNameLen = byte_size(PlayerName),
    <<PlayerId:32, PlayerNameLen:16, PlayerName/binary, PlayerSex:16, PlayerCareer:16, PlayerLevel:16, ApplyTime:32, OnlineFlag:8, PlayerVipType:8>>.

%% -----------------------------------------------------------------
%% 获取邀请列表
%% -----------------------------------------------------------------
get_guild_invite_page(PlayerId, PageSize, PageNo) ->
    %?DEBUG("get_guild_invite_page: PlayerId=[~p], PageSize=[~p], PageNo=[~p]", [PlayerId, PageSize, PageNo]),
    % 获取总记录数
    GuildInvites = lib_guild_base:get_guild_invite_by_player_id(PlayerId),
    RecordTotal = length(GuildInvites),
    % 计算分页
    {PageTotal, StartPos, RecordNum} = calc_page_cache(RecordTotal, PageSize, PageNo),
    %?DEBUG("get_guild_invite_page: PageTotal=[~p], StartPos=[~p], RecordNum=[~p]", [PageTotal, StartPos, RecordNum]),
    % 获取分页
    RowsPage = lists:sublist(GuildInvites, StartPos, PageSize),
    % 处理分页
    Records = lists:map(fun handle_invite_page/1, RowsPage),
    % 发送回应
    [1, PageTotal, PageNo, RecordNum, list_to_binary(Records)].

%% 私有_处理邀请列表
handle_invite_page(GuildInvite) ->
    [GuildId, InviteTime] =
        [GuildInvite#ets_guild_invite.guild_id, GuildInvite#ets_guild_invite.create_time],
    Guild = lib_guild_base:get_guild(GuildId),
    case Guild of
        [] ->
            <<>>;
        _ ->
            [GuildName, ChiefId, ChiefName, MemberNum, MemberCapacity, Level, Realm, Tenet, Funds, Announce]
                = [Guild#ets_guild.name, Guild#ets_guild.chief_id, Guild#ets_guild.chief_name, Guild#ets_guild.member_num, Guild#ets_guild.member_capacity, Guild#ets_guild.level, Guild#ets_guild.realm, Guild#ets_guild.tenet, Guild#ets_guild.funds, Guild#ets_guild.announce],
            GuildNameLen = byte_size(GuildName),
            ChiefNameLen = byte_size(ChiefName),
            TenetLen     = byte_size(Tenet),
            AnnounceLen  = byte_size(Announce),
            <<GuildId:32, GuildNameLen:16, GuildName/binary, ChiefId:32, ChiefNameLen:16, ChiefName/binary, MemberNum:16, MemberCapacity:16, Level:16, Realm:16, TenetLen:16, Tenet/binary, InviteTime:32, Funds:32, AnnounceLen:16, Announce/binary>>
    end.
    
%% -----------------------------------------------------------------
%% 获取帮派信息_包括为协议打包
%% -----------------------------------------------------------------
get_guild_info(GuildId) ->
    Guild = lib_guild_base:get_guild(GuildId),
    if  % 帮派不存在
        Guild =:= [] ->
            [2, <<>>];
        true ->
			[     GuildId                  						    %%      Int32	帮派ID
				, Guild_name                 						%%      String	帮派名称
				, Guild_announce    								%%      String	帮派公告
				, Guild_realm                  						%% 		Int16	阵营
				, Guild_level               						%% 		Int16	级别
				, Guild_reputation               					%% 		Int16	声望
				, Guild_funds										%%      Int32	帮派资金
				, Guild_contribution								%%      Int32	帮派建设
				, Guild_contribution_daily							%%      Int16	每日建设
				, Guild_qq											%%      Int32	QQ群号
				, Guild_create_time									%%      Int32	创建时间
				, Guild_contribution_threshold						%%      Int32	建设上限
				, Guild_disband_flag								%%		Int16	解散标记，0为正常，1为解散中
				, Guild_disband_confirm_time 						%%     	Int32	解散确认时间，1970年以来的秒数
			] = [ Guild#ets_guild.id                 				%%      Int32	帮派ID
				, Guild#ets_guild.name             					%%      String	帮派名称
				, Guild#ets_guild.announce    						%%      String	帮派公告
				, Guild#ets_guild.realm                 			%% 		Int16	阵营
				, Guild#ets_guild.level               				%% 		Int16	级别
				, Guild#ets_guild.reputation               			%% 		Int16	声望
				, Guild#ets_guild.funds								%%      Int32	帮派资金
				, Guild#ets_guild.contribution						%%      Int32	帮派建设
				, Guild#ets_guild.contribution_daily				%%      Int16	每日建设
				, Guild#ets_guild.qq								%%      Int32	QQ群号
				, Guild#ets_guild.create_time						%%      Int32	创建时间
				, Guild#ets_guild.contribution_threshold			%%      Int32	建设上限
				, Guild#ets_guild.disband_flag						%%		Int16	解散标记，0为正常，1为解散中
				, Guild#ets_guild.disband_confirm_time				%%     	Int32	解散确认时间，1970年以来的秒数
			],
			[	  Guild_chief_id									%%      Int32	帮主ID
				, Guild_chief_name									%%      String	帮主名称
				, Guild_deputy_chief1_id							%%      Int32	副帮主1ID
				, Guild_deputy_chief1_name							%%      String	副帮主1名称
				, Guild_deputy_chief2_id							%%      Int32	副帮主2ID
				, Guild_deputy_chief2_name							%%      String	副帮主2名称
				, Guild_deputy_chief_num							%%      Int16	副帮主数
				, Guild_member_num									%%      Int16	成员数
				, Guild_member_capacity								%%      Int16	最大成员数
			] = [ Guild#ets_guild.chief_id							%%      Int32	帮主ID
				, Guild#ets_guild.chief_name						%%      String	帮主名称
				, Guild#ets_guild.deputy_chief1_id					%%      Int32	副帮主1ID
				, Guild#ets_guild.deputy_chief1_name				%%      String	副帮主1名称
				, Guild#ets_guild.deputy_chief2_id					%%      Int32	副帮主2ID
				, Guild#ets_guild.deputy_chief2_name				%%      String	副帮主2名称
				, Guild#ets_guild.deputy_chief_num					%%      Int16	副帮主数
				, Guild#ets_guild.member_num						%%      Int16	成员数
				, Guild#ets_guild.member_capacity					%%      Int16	最大成员数
			],
			[	  Guild_furnace_level								%% 		Int16	神炉等级
				, Guild_mall_level									%% 		Int16   帮派商城等级
				, Guild_depot_level									%% 		Int16	仓库等级
				, Guild_altar_level									%% 		Int16	祭坛等级
				, Guild_house_level									%% 		Int16   厢房等级
			] = [ Guild#ets_guild.furnace_level						%% 		Int16	神炉等级
				, Guild#ets_guild.mall_level						%% 		Int16   帮派商城等级
				, Guild#ets_guild.depot_level						%% 		Int16	仓库等级
				, Guild#ets_guild.altar_level						%% 		Int16	祭坛等级
				, Guild#ets_guild.house_level						%% 		Int16   厢房等级
			],
			[	  Guild_leve_1_last									%%    	Int16	一级持续天数
				, Guild_base_left									%%    	Int16	基本计数器
			] = [ Guild#ets_guild.leve_1_last						%%    	Int16	一级持续天数
				, Guild#ets_guild.base_left							%%    	Int16	基本计数器
			],			
			%%	打包
			Bin_Guild_name = pt:write_string(Guild_name),               
			Bin_Guild_announce = pt:write_string(Guild_announce),  		
			BaseGuildInfo = <<
				  GuildId:32                  							%%      Int32	帮派ID
				, Bin_Guild_name/binary									%%      String	帮派名称
				, Bin_Guild_announce/binary								%%      String	帮派公告
				, Guild_realm:16                  						%% 		Int16	阵营
				, Guild_level:16               							%% 		Int16	级别
				, Guild_reputation:16               					%% 		Int16	声望
				, Guild_funds:32										%%      Int32	帮派资金
				, Guild_contribution:32									%%      Int32	帮派建设
				, Guild_contribution_daily:16							%%      Int16	每日建设
				, Guild_qq:32											%%      Int32	QQ群号
				, Guild_create_time:32									%%      Int32	创建时间
				, Guild_contribution_threshold:32						%%      Int32	建设上限
				, Guild_disband_flag:16									%%		Int16	解散标记，0为正常，1为解散中
				, Guild_disband_confirm_time:32 						%%     	Int32	解散确认时间，1970年以来的秒数
				>>,
			Bin_Guild_chief_name = pt:write_string(Guild_chief_name),  
			Bin_Guild_deputy_chief1_name = pt:write_string(Guild_deputy_chief1_name), 
			Bin_Guild_deputy_chief2_name = pt:write_string(Guild_deputy_chief2_name), 
			BaseMemberInfo = <<  Guild_chief_id:32						%%      Int32	帮主ID
							, Bin_Guild_chief_name/binary				%%      String	帮主名称
							, Guild_deputy_chief1_id:32					%%      Int32	副帮主1ID
							, Bin_Guild_deputy_chief1_name/binary		%%      String	副帮主1名称
							, Guild_deputy_chief2_id:32					%%      Int32	副帮主2ID
							, Bin_Guild_deputy_chief2_name/binary		%%      String	副帮主2名称
							, Guild_deputy_chief_num:16					%%      Int16	副帮主数
							, Guild_member_num:16						%%      Int16	成员数
							, Guild_member_capacity:16					%%      Int16	最大成员数
						  >>,
			GuildBuildInfo = <<
							  Guild_furnace_level:16					%% 		Int16	神炉等级
							, Guild_mall_level:16						%% 		Int16   帮派商城等级
							, Guild_depot_level:16						%% 		Int16	仓库等级
							, Guild_altar_level:16						%% 		Int16	祭坛等级
							, Guild_house_level:16						%% 		Int16   厢房等级
							  >>,
			GuildBattleInfo = <<Guild_leve_1_last:16					%%    	Int16	一级持续天数
							   , Guild_base_left:16>>,					%%    	Int16	基本计数器
            [1, <<BaseGuildInfo/binary, BaseMemberInfo/binary, GuildBuildInfo/binary, GuildBattleInfo/binary>>]
    end.

%% -----------------------------------------------------------------
%% 修改帮派成员数
%% -----------------------------------------------------------------
modify_guild_member_num(GuildId, MemberNum) ->
    %?DEBUG("modify_guild_member_num: GuildId=[~p], MemberNum=[~p]", [GuildId, MemberNum]),
    Data = [MemberNum, GuildId],
    SQL = io_lib:format(?SQL_GUILD_UPDATE_MEMBER_NUM, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 修改帮派公告
%% -----------------------------------------------------------------
modify_guild_announce(GuildId, Announce) ->
    %?DEBUG("modify_guild_announce: GuildId=[~p], Announce=[~s]", [GuildId, Announce]),
    Data = [Announce, GuildId],
    SQL = io_lib:format(?SQL_GUILD_UPDATE_ANNOUNCE, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 职位设置
%% 并发冲突解决：
%% 1- 帮主或者副帮主同时设置某个相同成员时可能造成并发冲突。
%% 2- 程序使用乐观锁并判断操作影响的行数，如果成功影响的行数不为1则更新缓存，否则仅通知客户端操作失败。
%% -----------------------------------------------------------------
set_position(PlayerId, NewGuildPosition) ->
    % 更新成员表
    GuildMember = lib_guild_base:get_guild_member_by_player_id(PlayerId),
    NowTime     = util:unixtime(),
    Data = [NewGuildPosition, NowTime, PlayerId],
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_POSITION1, Data),
    case db:execute(SQL) of
        1 ->
            GuildMemberNew = GuildMember#ets_guild_member{position = NewGuildPosition,
                                                          version  = NowTime},
            lib_guild_base:update_guild_member(GuildMemberNew),
            % 更新帮派表
            case NewGuildPosition == 1 of
                true ->
                    PlayerName = GuildMember#ets_guild_member.name,
                    GuildId    = GuildMember#ets_guild_member.guild_id,
                    Data2 = [PlayerId, PlayerName, GuildId],
                    SQL2  = io_lib:format(?SQL_GUILD_UPDATE_CHANGE_CHIEF, Data2),
                    db:execute(SQL2);
                false->
                    void
            end,
            ok;
        _ ->
            error
    end.

%% -----------------------------------------------------------------
%% 职位设置_角色_上线职位修正
%% -----------------------------------------------------------------
set_position_logic(PlayerId, NewGuildPosition) ->
    % 更新成员表
    GuildMember = mod_disperse:call_to_unite(lib_guild_base, get_guild_member_by_player_id, [PlayerId]),
    NowTime     = util:unixtime(),
    Data = [NewGuildPosition, NowTime, PlayerId],
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_POSITION1, Data),
    case db:execute(SQL) of
        1 ->
            GuildMemberNew = GuildMember#ets_guild_member{position = NewGuildPosition,
                                                          version  = NowTime},
            mod_disperse:cast_to_unite(lib_guild_base, update_guild_member, [GuildMemberNew]),
            % 更新帮派表
            case NewGuildPosition == 1 of
                true ->
                    PlayerName = GuildMember#ets_guild_member.name,
                    GuildId    = GuildMember#ets_guild_member.guild_id,
                    Data2 = [PlayerId, PlayerName, GuildId],
                    SQL2  = io_lib:format(?SQL_GUILD_UPDATE_CHANGE_CHIEF, Data2),
                    db:execute(SQL2);
                false->
                    void
            end,
            ok;
        _ ->
            error
    end.

%% -----------------------------------------------------------------
%% 帮主转让帮派
%% -----------------------------------------------------------------
demise_chief(PlayerId1, PlayerId2, PlayerName2, GuildId) ->
    GuildMember1 = lib_guild_base:get_guild_member_by_player_id(PlayerId1),
    GuildMember2 = lib_guild_base:get_guild_member_by_player_id(PlayerId2),
	NowTime      = util:unixtime(),
    case db:transaction(fun() -> demise_chief_db(PlayerId1, PlayerId2, PlayerName2, GuildId) end) of
		ok ->
		    % 更新缓存
		    GuildMemberNew1 = GuildMember1#ets_guild_member{position = 5,
		                                                    version  = NowTime},
		    lib_guild_base:update_guild_member(GuildMemberNew1),    
		    GuildMemberNew2 = GuildMember2#ets_guild_member{position = 1,
		                                                    version  = NowTime},
		    lib_guild_base:update_guild_member(GuildMemberNew2),
			ok;
		_ ->
			false
	end.

demise_chief_db(PlayerId1, PlayerId2, PlayerName2, GuildId)->
	NowTime      = util:unixtime(),
	%% 更新成员表
    Data = [5, NowTime, PlayerId1],
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_POSITION1, Data),
    db:execute(SQL),
    Data1 = [1, NowTime, PlayerId2],
    SQL1  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_POSITION1, Data1),
    db:execute(SQL1),
    % 更新帮派表
    Data2 = [PlayerId2, PlayerName2, GuildId],
    SQL2  = io_lib:format(?SQL_GUILD_UPDATE_CHANGE_CHIEF, Data2),
    db:execute(SQL2),
	ok.

%% -----------------------------------------------------------------
%% 帮主转让帮派_角色_上线职位修正
%% -----------------------------------------------------------------
demise_chief_logic(PlayerId1, PlayerId2, PlayerName2, GuildId) ->
    GuildMember1 = mod_disperse:call_to_unite(lib_guild_base, get_guild_member_by_player_id, [PlayerId1]),
    GuildMember2 = mod_disperse:call_to_unite(lib_guild_base, get_guild_member_by_player_id, [PlayerId2]),
    NowTime      = util:unixtime(),
    % 更新成员表
%    Data = [2, NowTime, PlayerId1, GuildMember1#ets_guild_member.version],
%    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_POSITION, Data),
    Data = [2, NowTime, PlayerId1],
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_POSITION1, Data),
    db:execute(SQL),
%    Data1 = [1, NowTime, PlayerId2, GuildMember2#ets_guild_member.version],
%    SQL1  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_POSITION, Data1),
    Data1 = [1, NowTime, PlayerId2],
    SQL1  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_POSITION1, Data1),
    db:execute(SQL1),
    % 更新帮派表
    Data2 = [PlayerId2, PlayerName2, GuildId],
    SQL2  = io_lib:format(?SQL_GUILD_UPDATE_CHANGE_CHIEF, Data2),
    db:execute(SQL2),
    % 更新缓存
    GuildMemberNew1 = GuildMember1#ets_guild_member{position = 5,
                                                    version  = NowTime},
    mod_disperse:cast_to_unite(lib_guild_base, update_guild_member, [GuildMemberNew1]),    
    GuildMemberNew2 = GuildMember2#ets_guild_member{position = 1,
                                                    version  = NowTime},
    mod_disperse:cast_to_unite(lib_guild_base, update_guild_member, [GuildMemberNew2]),
    ok.

%% -----------------------------------------------------------------
%% 捐献铜币 1000铜币=10帮派贡献=100每日福利=1000帮派资金 
%% -----------------------------------------------------------------
donate_money(PlayerId, GuildId, Num) ->
    % 更新帮派表
    Data1 = [Num, GuildId],
    SQL1  = io_lib:format(?SQL_GUILD_UPDATE_ADD_FUNDS, Data1),
    db:execute(SQL1),
    % 计算增加的帮贡
    DonateMoneyRatio = data_guild:get_guild_config(donate_money_ratio, []),
    DonateAdd        = (Num * DonateMoneyRatio) div 1000,
    % 更新帮派成员表
    case add_donation(PlayerId, DonateAdd, 1) of
        [ok, PaidAdd] ->
            [ok, DonateAdd, PaidAdd];
        _ ->
            error
    end.

%% -----------------------------------------------------------------
%% 捐献帮派建设卡 1建设令=100帮派建设=10帮派贡献=100每日福利=10帮派财富
%% @return 未升级：[0, 新帮派建设值]
%%          升级  ：[1, 新成员上限, 新级别, 新帮派建设值(0), 新每日建设值, 新帮派建设上限, 新自动解散标志位(0)]
%%          出错  ：error
%% -----------------------------------------------------------------
donate_contribution_card(PlayerId, GuildId, Num, Level, Contribution, MemerCapactiy) ->
	%% 计算捐献增加的帮派贡献
    DonateRatio   = data_guild:get_guild_config(donate_contribution_card_ratio, []),
    DonateAdd     = Num * DonateRatio,
	%% 增加的帮派财富
	MAdd = Num * 10,
    %% 更新成员财富信息
	GuildMember = lib_guild_base:get_guild_member_by_player_id(PlayerId),
	lib_guild_base:update_guild_member(GuildMember#ets_guild_member{material = GuildMember#ets_guild_member.material + MAdd}),
	%% 记录捐献建设卡的日常
	mod_daily_dict:plus_count(PlayerId, 4001, MAdd),
    case add_donation(PlayerId, DonateAdd, 2) of
        [ok, PaidAdd] ->
            %% 计算增加的帮派建设
            ContributionRatio  = data_guild:get_guild_config(contribution_card_ratio, []),
            ContributionTotal  = Contribution + Num * ContributionRatio,
            %% 处理帮派升级
            [NewLevel, NewMemberCapcity, NewContribution, NewContributionThreshold, NewContributionDaily] = calc_new_level(Level, ContributionTotal, MemerCapactiy, Level),
            %% 更新帮派表
            if  % (1) 帮派升级
                NewLevel > Level ->
					lib_guild:get_guild_award(Level, NewLevel, GuildId),
                    Data1 = [NewLevel, NewContribution, GuildId],
                    SQL1  = io_lib:format(?SQL_GUILD_UPDATE_GRADE, Data1),
                    db:execute(SQL1),
                    [1, NewMemberCapcity, NewLevel, NewContribution, NewContributionDaily, NewContributionThreshold, 0, DonateAdd, PaidAdd, MAdd];
                % (2) 帮派没有升级
                true ->
                    Data1 = [ContributionTotal, GuildId],
                    SQL1  = io_lib:format(?SQL_GUILD_UPDATE_CONTRIBUTION, Data1),
                    db:execute(SQL1),
                    [0, ContributionTotal, DonateAdd, PaidAdd, MAdd]
            end;
       _ ->
           error
    end.

%% -----------------------------------------------------------------
%% 捐献元宝  1元宝=1帮派财富=10帮派建设度=10贡献度
%% @return 未升级：[0, 新帮派建设值]
%%          升级  ：[1, 新成员上限, 新级别, 新帮派建设值(0), 新每日建设值, 新帮派建设上限, 新自动解散标志位(0)]
%%          出错  ：error
%% -----------------------------------------------------------------
donate_gold(PlayerId, GuildId, GoldNum, Level, Contribution, MemerCapactiy) ->
    %% 增加的帮派财富
	MAdd = GoldNum * 1,
	%% 增加的帮派建设度
	ContributionTotal  = Contribution + GoldNum * 10,
	%% 增加的贡献度
	DonateAdd = GoldNum * 10,
   	%% 更新玩家帮派信息
	GuildMember = lib_guild_base:get_guild_member_by_player_id(PlayerId),
	lib_guild_base:update_guild_member(GuildMember#ets_guild_member{material = GuildMember#ets_guild_member.material + MAdd}),
    %% 增加贡献度
	case add_donation(PlayerId, DonateAdd, 2) of
        [ok, _PaidAdd] ->
            [NewLevel, NewMemberCapcity, NewContribution, NewContributionThreshold, NewContributionDaily] = calc_new_level(Level, ContributionTotal, MemerCapactiy, Level),
		    % 更新帮派表
		    if  % (1) 帮派升级
		        NewLevel > Level ->
					lib_guild:get_guild_award(Level, NewLevel, GuildId),
		            Data1 = [NewLevel, NewContribution, GuildId],
		            SQL1  = io_lib:format(?SQL_GUILD_UPDATE_GRADE, Data1),
		            db:execute(SQL1),
		            [1, NewMemberCapcity, NewLevel, NewContribution, NewContributionDaily, NewContributionThreshold, 0, 0, 0];
		        % (2) 帮派没有升级
		        true ->
		            Data1 = [ContributionTotal, GuildId],
		            SQL1  = io_lib:format(?SQL_GUILD_UPDATE_CONTRIBUTION, Data1),
		            db:execute(SQL1),
		            [0, ContributionTotal, 0, 0]
		    end;
       _ ->
           error
    end.

    

%% -----------------------------------------------------------------
%% 帮派升级
%% -----------------------------------------------------------------
calc_new_level(Level, Contribution, MemerCapacity, CurLevel) ->
	case Level of
		?GUILD_TOP_LEVEL ->
			[MemberCapacityConfig, ContributionThresholdConfig, ContributionDailyConfig] = data_guild:get_level_info(Level),
			[CurMemberCapcityConfig, _CurContributionThresholdConfig, _CurContributionDailyConfig] = data_guild:get_level_info(CurLevel),
            [Level, MemberCapacityConfig+(MemerCapacity-CurMemberCapcityConfig), Contribution, ContributionThresholdConfig, ContributionDailyConfig];
		_ ->
			[MemberCapacityConfig, ContributionThresholdConfig, ContributionDailyConfig] = data_guild:get_level_info(Level),
		    case Contribution >= ContributionThresholdConfig of
		        true ->
		             calc_new_level(Level+1, Contribution-ContributionThresholdConfig, MemerCapacity, CurLevel);
		        false ->
		             case Level of
		                 1 ->
		                     [Level, MemerCapacity, Contribution, ContributionThresholdConfig, ContributionDailyConfig];
		                 _ ->
		                     [CurMemberCapcityConfig, _CurContributionThresholdConfig, _CurContributionDailyConfig] = data_guild:get_level_info(CurLevel),
		                     [Level, MemberCapacityConfig+(MemerCapacity-CurMemberCapcityConfig), Contribution, ContributionThresholdConfig, ContributionDailyConfig]
		             end
		    end
	end.

%% -----------------------------------------------------------------
%% 增加帮贡 帮派资金 每日福利 统一调用这里
%% @param  PlayerId   角色ID
%%          DonateAdd  增加的帮贡
%%          AddReason  增加的原因 0做任务等直接增加 1捐献钱币 2捐献建设卡 3升级厢房 4喂养BOSS
%% -----------------------------------------------------------------
add_donation(PlayerId, DonateAdd, AddReason) ->
    % 查询贡献信息
	case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
		GuildMember when is_record(GuildMember, ets_guild_member) ->
			[Donate, DonateTotal, DonateTotalCard, DonateTotalCoin, DonateLastTime, DonateTotalLastWeek, DonateTotalLastdDay, PaidAdd] =
                [GuildMember#ets_guild_member.donate, GuildMember#ets_guild_member.donate_total, GuildMember#ets_guild_member.donate_total_card, GuildMember#ets_guild_member.donate_total_coin, GuildMember#ets_guild_member.donate_lasttime, GuildMember#ets_guild_member.donate_total_lastweek, GuildMember#ets_guild_member.donate_total_lastday, GuildMember#ets_guild_member.paid_add],
            DonateTime      = util:unixtime(),
            SameDay         = util:is_same_date(DonateTime, DonateLastTime),
            SameWeek        = util:is_same_week(DonateTime, DonateLastTime),
            % 计算增加的日福利
            PaidDonateRatio = data_guild:get_guild_config(paid_donate_ration, []),
            PaidAddTemp     = DonateAdd * PaidDonateRatio,
            NewPaidAdd      = PaidAdd + PaidAddTemp,
            % {增加的日福利,总贡献剩余,总贡献,总建设贡献,总资金贡献}
            {NewPaidAdd, NewDonate, NewDonateTotal, NewDonateTotalCard, NewDonateTotalCoin}
                = case AddReason of
                      % 做任务等直接增加
                      0 -> {NewPaidAdd, Donate+DonateAdd, DonateTotal+DonateAdd, DonateTotalCard, DonateTotalCoin};
                      % 捐献钱币
                      1 -> {NewPaidAdd, Donate+DonateAdd, DonateTotal+DonateAdd, DonateTotalCard, DonateTotalCoin+DonateAdd};
                      % 捐献建设卡
                      2 -> {NewPaidAdd, Donate+DonateAdd, DonateTotal+DonateAdd, DonateTotalCard+DonateAdd, DonateTotalCoin};
                      % 升级厢房
                      3 -> {NewPaidAdd, Donate+DonateAdd, DonateTotal+DonateAdd, DonateTotalCard, DonateTotalCoin};
                      % 捐献元宝
                      5 -> {NewPaidAdd, Donate+DonateAdd, DonateTotal+DonateAdd, DonateTotalCard, DonateTotalCoin};
                      % 其他情况
                      _ -> {NewPaidAdd, Donate+DonateAdd, DonateTotal+DonateAdd, DonateTotalCard, DonateTotalCoin}
                  end,            
            if  % 同一个星期且同一天
               (SameDay == true) ->
                    Data3 = [NewDonate, NewDonateTotal, NewDonateTotalCard, NewDonateTotalCoin, DonateTime, DonateTotalLastWeek+DonateAdd, DonateTotalLastdDay+DonateAdd, NewPaidAdd, PlayerId],
                    SQL3  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_DONATE_INFO, Data3),
                    %?DEBUG("add_donation: SQL=[~s]", [SQL3]),
                    db:execute(SQL3),
                    % 更新缓存
                    GuildMemberNew = GuildMember#ets_guild_member{donate                = NewDonate,
                                                                  donate_total          = NewDonateTotal,
                                                                  donate_total_card     = NewDonateTotalCard,
                                                                  donate_total_coin     = NewDonateTotalCoin,
                                                                  donate_lasttime       = DonateTime,
                                                                  donate_total_lastweek = DonateTotalLastWeek+DonateAdd,
                                                                  donate_total_lastday  = DonateTotalLastdDay+DonateAdd,
                                                                  paid_add              = NewPaidAdd},
                    lib_guild_base:update_guild_member(GuildMemberNew);
              % 同一个星期且不同天
              ((SameWeek == true) and (SameDay == false)) ->
                    Data3 = [NewDonate, NewDonateTotal, NewDonateTotalCard, NewDonateTotalCoin, DonateTime, DonateTotalLastWeek+DonateAdd, DonateAdd, NewPaidAdd, PlayerId],
                    SQL3  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_DONATE_INFO, Data3),
                    %?DEBUG("add_donation: SQL=[~s]", [SQL3]),
                    db:execute(SQL3),
                    % 更新缓存
                    GuildMemberNew = GuildMember#ets_guild_member{donate                = NewDonate,
                                                                  donate_total          = NewDonateTotal,
                                                                  donate_total_card     = NewDonateTotalCard,
                                                                  donate_total_coin     = NewDonateTotalCoin,
                                                                  donate_lasttime       = DonateTime,
                                                                  donate_total_lastweek = DonateTotalLastWeek+DonateAdd,
                                                                  donate_total_lastday  = DonateAdd,
                                                                  paid_add              = NewPaidAdd},
                    lib_guild_base:update_guild_member(GuildMemberNew);
              % 不同一个星期且不同天
              (SameWeek == false) ->
                    Data3 = [NewDonate, NewDonateTotal, NewDonateTotalCard, NewDonateTotalCoin, DonateTime, DonateAdd, DonateAdd, NewPaidAdd, PlayerId],
                    SQL3  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_DONATE_INFO, Data3),
                    %?DEBUG("add_donation: SQL=[~s]", [SQL3]),
                    db:execute(SQL3),
                    % 更新缓存
                    GuildMemberNew = GuildMember#ets_guild_member{donate                = NewDonate,
                                                                  donate_total          = NewDonateTotal,
                                                                  donate_total_card     = NewDonateTotalCard,
                                                                  donate_total_coin     = NewDonateTotalCoin,
                                                                  donate_lasttime       = DonateTime,
                                                                  donate_total_lastweek = DonateAdd,
                                                                  donate_total_lastday  = DonateAdd,
                                                                  paid_add              = NewPaidAdd},
                    lib_guild_base:update_guild_member(GuildMemberNew);
               true ->
                    void
           end,
		   %% 运势任务(3700002:帮派砥柱)
		   lib_fortune:fortune_daily(PlayerId, 3700002, DonateAdd),
		   %% 添加贡献成就
			StatusAchieve = lib_player:get_player_info(PlayerId, achieve),
		   lib_player_unite:trigger_achieve(PlayerId, trigger_social, [StatusAchieve, PlayerId, 10, 0, NewDonateTotal]),
           %% 完成捐献任务
           case NewDonateTotal >= 200 of
                true ->
                    lib_player:rpc_cast_by_id(PlayerId, lib_task, event, [bpgx, do, PlayerId]);
                false-> void
            end,
           [ok, PaidAddTemp];
		_ -> % 帮派成员不存在
			?ERR("add_donation: guild member not find ,id=[~p]", [PlayerId]),
            error
	end.
    
%% -----------------------------------------------------------------
%% 获取捐献列表
%% -----------------------------------------------------------------
get_donate_page(GuildId, PageSize, PageNo) ->
    %?DEBUG("get_donate_page: GuildId=[~p], PageSize=[~p], PageNo=[~p]", [GuildId, PageSize, PageNo]),
    % 获取总记录数
    GuildMembers = lib_guild_base:get_guild_member_by_guild_id(GuildId),
    RecordTotal  = length(GuildMembers),
    % 计算分页
    {PageTotal, StartPos, RecordNum} = calc_page_cache(RecordTotal, PageSize, PageNo),
    %?DEBUG("get_donate_page: PageTotal=[~p], StartPos=[~p], RecordNum=[~p]", [PageTotal, StartPos, RecordNum]),
    % 获取分页
    RowsPage = lists:sublist(GuildMembers, StartPos, PageSize),
    % 处理分页
    Records = lists:map(fun handle_donate_page/1, RowsPage),
    % 发送回应
    [1, PageTotal, PageNo, RecordNum, list_to_binary(Records)].

%% 私有_帮派贡献分页
handle_donate_page(GuildMember) ->
    [PlayerId, PalyerName, PlayerLevel, GuildPosition, DonateLastTime, DonateTotal, DonateTotalCard, DonateTotalCoin, DonateTotalLastWeek, DonateTotalLastDay, PlayerSex, PlayerCareer, OnlineFlag, LastLoginTime, Image, Vip] =
        [GuildMember#ets_guild_member.id, GuildMember#ets_guild_member.name, GuildMember#ets_guild_member.level, GuildMember#ets_guild_member.position, GuildMember#ets_guild_member.donate_lasttime, GuildMember#ets_guild_member.donate_total, GuildMember#ets_guild_member.donate_total_card, GuildMember#ets_guild_member.donate_total_coin, GuildMember#ets_guild_member.donate_total_lastweek, GuildMember#ets_guild_member.donate_total_lastday, GuildMember#ets_guild_member.sex, GuildMember#ets_guild_member.career, GuildMember#ets_guild_member.online_flag, GuildMember#ets_guild_member.last_login_time, GuildMember#ets_guild_member.image, GuildMember#ets_guild_member.vip],
    PlayerNameLen = byte_size(PalyerName),
    NowTime       = util:unixtime(),
    SameDay       = util:is_same_date(NowTime, DonateLastTime),
    SameWeek      = util:is_same_week(NowTime, DonateLastTime),
    if  % 同一个星期且同一天
        (SameDay == true) ->
            <<PlayerId:32, PlayerNameLen:16, PalyerName/binary, PlayerLevel:16, GuildPosition:16, DonateTotal:32, DonateTotalLastWeek:32, DonateTotalLastDay:32, PlayerSex:16, PlayerCareer:16, DonateTotalCard:32, DonateTotalCoin:32, OnlineFlag:8, LastLoginTime:32, Image:16, Vip:8>>;
        % 同一个星期且不同天
        ((SameWeek == true) and (SameDay == false)) ->
            <<PlayerId:32, PlayerNameLen:16, PalyerName/binary, PlayerLevel:16, GuildPosition:16, DonateTotal:32, DonateTotalLastWeek:32, 0:32, PlayerSex:16, PlayerCareer:16, DonateTotalCard:32, DonateTotalCoin:32, OnlineFlag:8, LastLoginTime:32, Image:16, Vip:8>>;
        % 不同一个星期且不同天
        (SameWeek == false) ->
             <<PlayerId:32, PlayerNameLen:16, PalyerName/binary, PlayerLevel:16, GuildPosition:16, DonateTotal:32, 0:32, 0:32, PlayerSex:16, PlayerCareer:16, DonateTotalCard:32, DonateTotalCoin:32, OnlineFlag:8, LastLoginTime:32, Image:16, Vip:8>>;
        true ->
             <<PlayerId:32, PlayerNameLen:16, PalyerName/binary, PlayerLevel:16, GuildPosition:16, DonateTotal:32, 0:32, 0:32, PlayerSex:16, PlayerCareer:16, DonateTotalCard:32, DonateTotalCoin:32, OnlineFlag:8, LastLoginTime:32, Image:16, Vip:8>>
    end.

%% -----------------------------------------------------------------
%% 获取日福利
%% -----------------------------------------------------------------
get_paid(PlayerId, NowTime) ->
    % 更新帮派成员表
    Data1 = [NowTime, 0, PlayerId],
    SQL1  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_PAID, Data1),
    db:execute(SQL1),
    ok.

%% -----------------------------------------------------------------
%% 获取成员信息
%% -----------------------------------------------------------------
get_member_info([GuildId, PlayerId]) ->
    % 获取帮派等级
	Guild = lib_guild_base:get_guild(GuildId),
	case lib_guild_base:get_guild(GuildId) of
		Guild when is_record(Guild, ets_guild) ->
			GuildLevel = Guild#ets_guild.level,
            % 获取成员信息
			case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
				GuildMember when is_record(GuildMember, ets_guild_member) ->
					[Id, Nickname, Lv, GuildPosition, DonateTotal, DonateLastTime, DonateTotalLastWeek, _DonateTotalLastDay, Title, Remark, Honor, Career, Donate, PaidAdd, Material, PaidGetLastTime] =
                        [GuildMember#ets_guild_member.id, GuildMember#ets_guild_member.name, 
                         GuildMember#ets_guild_member.level, GuildMember#ets_guild_member.position, 
                         GuildMember#ets_guild_member.donate_total, GuildMember#ets_guild_member.donate_lasttime, 
                         GuildMember#ets_guild_member.donate_total_lastweek, GuildMember#ets_guild_member.donate_total_lastday,
                         GuildMember#ets_guild_member.title, GuildMember#ets_guild_member.remark, GuildMember#ets_guild_member.honor, 
                         GuildMember#ets_guild_member.career, GuildMember#ets_guild_member.donate, GuildMember#ets_guild_member.paid_add, 
                         GuildMember#ets_guild_member.material, GuildMember#ets_guild_member.paid_get_lasttime],
                    NowTime       = util:unixtime(),
                    SameDay       = util:is_same_date(NowTime, DonateLastTime),
                    SameWeek      = util:is_same_week(NowTime, DonateLastTime),                    
                    NicknameLen   = byte_size(Nickname),
                    TitleLen      = byte_size(Title),
                    RemarkLen     = byte_size(Remark),
                    PaidDaily     = calc_paid_daily(GuildLevel, GuildPosition, PaidAdd),
                    PaidGetFlag   = case util:is_same_date(PaidGetLastTime, NowTime) of
                                        true -> 1;
                                        false-> 0
                                    end,
					TodayDonate = mod_daily_dict:get_count(PlayerId, 3700002),
					MetarialCountx = mod_daily_dict:get_count(PlayerId, 4001), %% 每天捐献的帮派令牌数
					MetarialCount = erlang:round(MetarialCountx/10),
					if % 同一个星期且同一天
                       (SameDay == true) ->
                            [1, <<Id:32, NicknameLen:16, Nickname/binary, Career:16, Lv:16, GuildPosition:16, DonateTotal:32, DonateTotalLastWeek:32, TodayDonate:32, PaidDaily:32, TitleLen:16, Title/binary, RemarkLen:16, Remark/binary, Honor:32, Donate:32, Material:32, PaidGetFlag:8, 0:32, MetarialCount:16>>];
                        % 同一个星期且不同天
                        ((SameWeek == true) and (SameDay == false)) ->
                            [1, <<Id:32, NicknameLen:16, Nickname/binary, Career:16, Lv:16, GuildPosition:16, DonateTotal:32, DonateTotalLastWeek:32, TodayDonate:32, PaidDaily:32, TitleLen:16, Title/binary, RemarkLen:16, Remark/binary, Honor:32, Donate:32, Material:32, PaidGetFlag:8, 0:32, MetarialCount:16>>];
                        % 不同一个星期且不同天
                        (SameWeek == false) ->
                            [1, <<Id:32, NicknameLen:16, Nickname/binary, Career:16, Lv:16, GuildPosition:16, DonateTotal:32, 0:32, TodayDonate:32, PaidDaily:32, TitleLen:16, Title/binary, RemarkLen:16, Remark/binary, Honor:32, Donate:32, Material:32, PaidGetFlag:8, 0:32, MetarialCount:16>>];
                        true ->
                            [1, <<Id:32, NicknameLen:16, Nickname/binary, Career:16, Lv:16, GuildPosition:16, DonateTotal:32, 0:32, TodayDonate:32, PaidDaily:32, TitleLen:16, Title/binary, RemarkLen:16, Remark/binary, Honor:32, Donate:32, Material:32, PaidGetFlag:8, 0:32, MetarialCount:16>>]
                    end;
				_ ->	% 帮派不存在该成员
					[3, <<>>]
			end;
		_ ->	% 帮派不存在
			[2, <<>>]
	end.

%% ------------------------------------------------------------------
%% 授予头衔
%% -----------------------------------------------------------------
give_title(PlayerId, Title) ->
    % 更新帮派成员表
    Data = [Title, PlayerId],
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_TITLE, Data),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 修改个人备注
%% -----------------------------------------------------------------
modify_remark(PlayerId, Remark) ->
    %?DEBUG("modify_remark: PlayerId=[~p], Remark=[~s]", [PlayerId, Remark]),
    % 更新帮派成员表
    Data = [Remark, PlayerId],
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_REMARK, Data),
    %?DEBUG("modify_remark: SQL=[~s]", [SQL]),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 获取仓库物品列表
%% -----------------------------------------------------------------
list_depot_goods(GuildId) ->
    %?DEBUG("list_depot_goods: GuildId=[~p]", [GuildId]),
    GoodsList = lib_goods_util:get_guild_goods_list(GuildId),
    case GoodsList of
        [] ->
            [1, 0, <<>>];
        _  ->
            Records = lists:map(fun handle_depot_goods_page/1, GoodsList),
            [1, length(GoodsList), list_to_binary(Records)]
    end.

%% 私有_处理仓库物品
handle_depot_goods_page(Goods) ->
    [Id, TypeId, Cell, Num, Stren] = [Goods#goods.id, Goods#goods.goods_id,Goods#goods.cell,Goods#goods.num,Goods#goods.stren],
    <<Id:32, TypeId:32, Cell:16, Num:16, Stren:16>>.

%% -----------------------------------------------------------------
%% 帮派仓库存入物品
%% -----------------------------------------------------------------
store_into_depot(PlayerId, NowTime, NewStoreNum) ->
    % 更新帮派成员表
    Data = [NowTime, NewStoreNum, PlayerId],
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_DEPOT_STORE_INTO, Data),
    %?DEBUG("store_into_depot: SQL=[~s]", [SQL]),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 帮派仓库取出物品
%% -----------------------------------------------------------------
take_out_depot(PlayerId, NewDonation) ->
    %?DEBUG("take_out_depot: PlayerId=[~p],NewDonation=[~p]", [PlayerId, NewDonation]),
    % 更新帮派成员表
    Data = [NewDonation, PlayerId],
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_DEPOT_TAKE_OUT, Data),
    %?DEBUG("take_out_depot: SQL=[~s]", [SQL]),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 计算每日福利
%% -----------------------------------------------------------------
calc_paid_daily(GuildLevel, GuildPosition, PaidAdd) ->
    ?DEBUG("GuildLevel=[~p], GuildPosition=[~p], PaidAdd=[~p]", [GuildLevel, GuildPosition, PaidAdd]),
    PaidBase      = data_guild:get_paid_daily(GuildLevel, GuildPosition),
    PaidBase+PaidAdd.

%% -----------------------------------------------------------------
%% 合服改名 
%% -----------------------------------------------------------------
rename_guild(GuildId, NewName, _RenameFlag, _PlayerId) ->
    % 更新数据库
    % (1) 帮派表
    Data = [NewName, GuildId],
    SQL = io_lib:format(?SQL_GUILD_UPDATE_RENAME, Data),
    ?DEBUG("rename_guild: SQL=[~s]", [SQL]),
    db:execute(SQL),
    % (2) 帮派成员表
    Data1 = [NewName, GuildId],
    SQL1 = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_RENAME_GUILD, Data1),
    ?DEBUG("rename_guild: SQL=[~s]", [SQL1]),
    db:execute(SQL1),
    ok.

%% -----------------------------------------------------------------
%% 弹劾帮主
%% -----------------------------------------------------------------
impeach_chief(PlayerId, PlayerName, PlayerPosition, GuildChief, GuildId) ->
    GuildMember = lib_guild_base:get_guild_member_by_player_id(PlayerId),
    NowTime     = util:unixtime(),
	case db:transaction(fun() -> impeach_chief_db(PlayerId, PlayerName, PlayerPosition, GuildChief, GuildId) end) of
		ok ->
			% 更新缓存
		    NewGuildMember = GuildMember#ets_guild_member{position = 1,
		                                                  version  = NowTime},
		    lib_guild_base:update_guild_member(NewGuildMember),
		    NewGuildChief  = GuildChief#ets_guild_member{position = PlayerPosition,
		                                                 version  = NowTime},
		    lib_guild_base:update_guild_member(NewGuildChief),
			ok;
		_ ->			
			false
	end.

impeach_chief_db(PlayerId, PlayerName, PlayerPosition, GuildChief, GuildId) ->
	NowTime     = util:unixtime(),
    % 更新成员表
    % (1) 更新旧帮主
    Data = [PlayerPosition, NowTime, GuildChief#ets_guild_member.id],
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_POSITION1, Data),
    db:execute(SQL),
    % (2) 更新新帮主
    Data1 = [1, NowTime, PlayerId],
    SQL1  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_POSITION1, Data1),
    db:execute(SQL1),
    % 更新帮派表
    Data2 = [PlayerId, PlayerName, GuildId],
    SQL2  = io_lib:format(?SQL_GUILD_UPDATE_CHANGE_CHIEF, Data2),
    db:execute(SQL2),
	ok.

%% -----------------------------------------------------------------
%% 合并帮派
%% -----------------------------------------------------------------
merge_guild(DeleteGuild, ReserveGuild) ->
    [DeleteGuildId, DeleteGuildMemberNum, DeleteGuildFunds] = [DeleteGuild#ets_guild.id, DeleteGuild#ets_guild.member_num, DeleteGuild#ets_guild.funds],
    [ReserveGuildId, ReserveGuildName, ReserveGuildMemberNum, ReserveGuildFunds] = [ReserveGuild#ets_guild.id, ReserveGuild#ets_guild.name, ReserveGuild#ets_guild.member_num, ReserveGuild#ets_guild.funds],
    NewGuildPosition = data_guild:get_guild_config(default_position, []),
    % 1- 更新数据库
    % (1) 更新解散帮派成员表的帮派ID，帮派名称和职位
    Data = [ReserveGuildId, ReserveGuildName, NewGuildPosition, DeleteGuildId],
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_MERGE, Data),
    db:execute(SQL),
    % (2) 更新保留帮派表的成员个数和帮派资金
    NewGuildNum  = DeleteGuildMemberNum+ReserveGuildMemberNum,
    NewGuildFuns = DeleteGuildFunds+ReserveGuildFunds,
    Data1 = [NewGuildNum, NewGuildFuns, ReserveGuildId],
    SQL1  = io_lib:format(?SQL_GUILD_UPDATE_MERGE, Data1),
    db:execute(SQL1),
	%lib_city_war:delete_win_guild(DeleteGuild),
    % (3) 删除解散帮派表
    Data2 = [DeleteGuildId],
    SQL2  = io_lib:format(?SQL_GUILD_DELETE, Data2),
    db:execute(SQL2),
    % (4) 删除解散帮派申请表
    Data3 = [DeleteGuildId],
    SQL3  = io_lib:format(?SQL_GUILD_APPLY_DELETE, Data3),
    db:execute(SQL3),
    % (5) 删除解散帮派邀请表
    Data4 = [DeleteGuildId],
    SQL4  = io_lib:format(?SQL_GUILD_INVITE_DELETE, Data4),
    db:execute(SQL4),
    % (6) 删除解散帮派事件表
    Data5 = [DeleteGuildId],
    SQL5  = io_lib:format(?SQL_GUILD_EVENT_DELETE, Data5),
    db:execute(SQL5),
    % 2- 删除帮派仓库物品
    lib_goods_util:delete_goods_by_guild(DeleteGuildId),
    % 4- 更新缓存
    % (1) 更新解散帮派成员缓存的帮派ID，帮派名称和职位
    DeleteGuildMemberList = lib_guild_base:get_guild_member_by_guild_id(DeleteGuildId),
    merge_guild_helper(DeleteGuildMemberList, ReserveGuildId, ReserveGuildName, NewGuildPosition),
    % (2) 更新保留帮派缓存的成员个数
    NewReserveGuild = ReserveGuild#ets_guild{member_num  = NewGuildNum,
                                             funds       = NewGuildFuns},
    update_guild(NewReserveGuild),
    % (3) 删除解散帮派缓存
    lib_guild_base:delete_guild(DeleteGuildId),
    % (4) 更新解散帮派邀请缓存
    lib_guild_base:delete_guild_invite_by_guild_id(DeleteGuildId),
    % (5) 更新解散帮派邀请缓存
    lib_guild_base:delete_guild_apply_by_guild_id(DeleteGuildId),
    ok.

%% 私有_合并帮派
merge_guild_helper([], _GuildId, _GuildName, _GuildPosition) ->
    void;
merge_guild_helper([H|T], GuildId, GuildName, GuildPosition) ->
    NewGuildMember = H#ets_guild_member{guild_id   = GuildId,
                                        guild_name = GuildName,
                                        position   = GuildPosition},
    lib_guild_base:update_guild_member(NewGuildMember),
    merge_guild_helper(T, GuildId, GuildName, GuildPosition).

%% -----------------------------------------------------------------
%% 改变帮派资金 0 失败 1成功
%% @param Funds_Change = Int:正数为增加_负数为减少
%% -----------------------------------------------------------------
%% change_guild_funds_logic([GuildId, PlayerId, Funds_Change]) ->
%% 	case get_guild(GuildId) of
%% 		[] ->
%% 			0;
%% 		[GuildInfo] ->
%% 			NewFunds = GuildInfo#ets_guild.funds + Funds_Change,
%% 			if
%% 				NewFunds < 0 ->
%% 					0;
%% 				true ->
%% 					Data = [NewFunds, GuildId],
%% 					SQL  = io_lib:format(?SQL_GUILD_UPDATE_FUNDS, Data),
%% 		    		db:execute(SQL),
%% 					%% 更新帮派信息
%% 					lib_guild:update_guild(GuildInfo, PlayerId),
%% 					1
%% 		    end
%%     end.

%% -----------------------------------------------------------------
%% 改变帮派建设 0 失败 1成功
%% @param Contribution_Change = Int:正数为增加_负数为减少
%% -----------------------------------------------------------------
change_guild_contribution([GuildId, PlayerId, Contribution_Change]) ->
	case get_guild(GuildId) of
		[] ->
			0;
		[GuildInfo] ->
			NewContribution = GuildInfo#ets_guild.contribution + Contribution_Change,
			Data = if
						NewContribution < 0 ->
							[0, GuildId];
						true ->
							[NewContribution, GuildId]
				   end,
    		SQL  = io_lib:format(?SQL_GUILD_UPDATE_CONTRIBUTION, Data),
    		db:execute(SQL),
			%% 调用_更新帮派信息 update_guild(Guild)
   			lib_guild:update_guild(GuildInfo, PlayerId),
			1
    end.

%% %% -----------------------------------------------------------------
%% %% 改变帮派成员头像
%% %% -----------------------------------------------------------------
%% change_guild_member_image_logic(PlayerId, NewImage) ->
%%     case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
%%         GuildMember when is_record(GuildMember, ets_guild_member) ->
%%             NewGuildMember = GuildMember#ets_guild_member{image = NewImage},
%%             lib_guild_base:update_guild_member(NewGuildMember);
%%         _->
%%             void
%%     end.

%% -----------------------------------------------------------------
%% 改变帮派成员VIP类型
%% -----------------------------------------------------------------
change_vip(PlayerId, NewVip) ->
    case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
        GuildMember when is_record(GuildMember, ets_guild_member) ->
            NewGuildMember = GuildMember#ets_guild_member{vip = NewVip},
            lib_guild_base:update_guild_member(NewGuildMember);
        _->
            void
    end,
    case lib_guild_base:get_guild_apply_by_player_id(PlayerId) of
        GuildApply when is_record(GuildApply, ets_guild_apply) ->
            NewGuildApply = GuildApply#ets_guild_apply{player_vip_type = NewVip},
            lib_guild_base:update_guild_apply(NewGuildApply);
        _->
            void
    end.

%% -----------------------------------------------------------------
%% 改变帮派成员性别
%% -----------------------------------------------------------------
change_sex(PlayerId, NewSex) ->
    case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
        GuildMember when is_record(GuildMember, ets_guild_member) ->
            NewGuildMember = GuildMember#ets_guild_member{sex = NewSex},
            lib_guild_base:update_guild_member(NewGuildMember);
        _->
            void
    end.

%% -----------------------------------------------------------------
%% 更改退帮次数 
%% -----------------------------------------------------------------
change_guild_quit_num(PlayerId) ->
    SQL  = io_lib:format(?SQL_PLAYER_SELECT_QUIT_GIULD_NUM, [PlayerId]),
    case db:get_row(SQL) of
        [] ->
            ok;
        [QuitNum, QuitLastTime] ->
            NowTime = util:unixtime(),
            NewQuitNum = case util:is_same_date(NowTime, QuitLastTime) of
                             true -> QuitNum+1;
                             false-> 1
                         end,
            SQL1  = io_lib:format(?SQL_PLAYER_UPDATE_QUIT_GIULD_NUM, [NewQuitNum, NowTime, PlayerId]),
            db:execute(SQL1),
            ok
    end.

%%=========================================================================
%% 邮件服务
%%=========================================================================
send_mail(SubjectType, Param) ->
    [Title, Format] = data_guild_text:get_mail_text(SubjectType),
    [PlayerList, TitleNew, ContentNew] = case SubjectType of
                  guild_create ->
                      [_PlayerId, PlayerName, _GuildId, _GuildName] = Param,
                      NameList  = [PlayerName],
                      Content   = io_lib:format(Format, []),
                      [NameList, Title, Content];
                  guild_apply_disband ->
                      [_PlayerId, _PlayerName, GuildId, GuildName] = Param,
                      NameList  = get_member_name_list(GuildId),
                      Content   = io_lib:format(Format, [GuildName]),
                      [NameList, Title, Content];
                  guild_cancel_disband ->
                      [_PlayerId, _PlayerName, GuildId, GuildName] = Param,
                      NameList  = get_member_name_list(GuildId),
                      Content   = io_lib:format(Format, [GuildName]),
                      [NameList, Title, Content];
                  guild_auto_cancel_disband ->
                      [GuildId, GuildName, ExpiredDay] = Param,
                      NameList  = get_member_name_list(GuildId),
                      Content   = io_lib:format(Format, [GuildName, ExpiredDay]),
                      [NameList, Title, Content];
                  guild_disband ->
                      [_GuildId, GuildName, MemberNameList] = Param,
                      NameList  = MemberNameList,
                      Content   = io_lib:format(Format, [GuildName]),
                      [NameList, Title, Content];
                  guild_auto_disband ->
                      [GuildId, GuildName, ExpiredDay] = Param,
                      NameList  = get_member_name_list(GuildId),
                      Content   = io_lib:format(Format, [GuildName, ExpiredDay]),
                      [NameList, Title, Content];
                  guild_degrade ->
                      [GuildId, GuildName, OldLevel, NewLevel] = Param,
                      NameList  = get_member_name_list(GuildId),
                      Content   = io_lib:format(Format, [GuildName, OldLevel, NewLevel]),
                      [NameList, Title, Content];
                  guild_apply_join ->
                      [_PlayerId, PlayerName, GuildId, GuildName] = Param,
                      NameList = get_official_name_list(GuildId, 3),
                      Content  = io_lib:format(Format, [PlayerName, GuildName]),
                      [NameList, Title, Content];
                  guild_reject_apply ->
                      [_PlayerId, PlayerName, _GuildId, GuildName] = Param,
                      NameList = [PlayerName],
                      Content  = io_lib:format(Format, [GuildName]),
                      [NameList, Title, Content];
                  guild_new_member ->
                      [_PlayerId, PlayerName, _GuildId, GuildName] = Param,
                      NameList = [PlayerName] ,
                      Content  = io_lib:format(Format, [GuildName]),
                      [NameList, Title, Content];
                  guild_invite_join ->
                      [_PlayerId, PlayerName, _GuildId, GuildName] = Param,
                      NameList = [PlayerName],
                      Content = io_lib:format(Format, [GuildName]),
                      [NameList, Title, Content];
                  guild_kickout ->
                      [_PlayerId, PlayerName, _GuildId, GuildName] = Param,
                      NameList = [PlayerName],
                      Content = io_lib:format(Format, [GuildName]),
                      [NameList, Title, Content];
                  guild_battle_apply ->
                      [GuildId, _GuildName, Month, Day, Hour, Min] = Param,
                      NameList  = get_member_name_list(GuildId),
                      Content   = io_lib:format(Format, [Month, Day, Hour, Min]),
                      [NameList, Title, Content];
                  guild_battle_apply_tip ->
                      NameList  = lib_guild_battle:get_apply_tip_member_name_list(),
                      Content   = io_lib:format(Format, []),
                      [NameList, Title, Content];
                  guild_battle_award ->
                      [_PlayerId, PlayerName, Month, Day, Hour, Min, GuildRank, Rank] = Param,
                      NameList = [PlayerName],
                      Content   = io_lib:format(Format, [Month, Day, Hour, Min, GuildRank, Rank]),
                      [NameList, Title, Content];
                  guild_battle_guild_award ->
                      [GuildId, _GuildName, Month, Day, Hour, Min, GuildRank] = Param,
                      NameList  = get_range_official_name_list(GuildId, 1, 2),
                      Content   = io_lib:format(Format, [Month, Day, Hour, Min, GuildRank]),
                      [NameList, Title, Content];                 
                  guild_award_alloc ->
                      [PlayerName] = Param,
                      NameList  = [PlayerName],
                      Content   = <<Format>>,
                      [NameList, Title, Content];
                  guild_impeach_chief ->
                      [GuildId, _PlayerId, PlayerName, _ChiefId, ChiefName] = Param,
                      NameList  = get_member_name_list(GuildId),
                      Content   = io_lib:format(Format, [PlayerName, ChiefName]),
                      [NameList, Title, Content];
                  guild_demise_chief ->
                      [GuildId, _ChiefId, ChiefName, _PlayerId, PlayerName] = Param,
                      NameList  = get_member_name_list(GuildId),
                      Content   = io_lib:format(Format, [ChiefName, PlayerName]),
                      [NameList, Title, Content];
                  guild_merge ->
                      [_DeleteGuildId, DeleteGuildName, ReserveGuildId, ReserveGuildName] = Param,
                      NameList  = get_member_name_list(ReserveGuildId),
                      Content   = io_lib:format(Format, [DeleteGuildName, ReserveGuildName]),
                      [NameList, Title, Content]
              end,
	gen_server:cast(mod_mail, {send_sys_mail, [PlayerList, TitleNew, ContentNew]}).

%% 私有_邮件服务
get_member_name_list(GuildId) ->
    MemberList = lib_guild_base:get_guild_member_by_guild_id(GuildId),
    get_member_name_list_helper(MemberList, []).
get_member_name_list_helper([], NameList) ->
    NameList;
get_member_name_list_helper(MemberList, NameList) ->
    [Member|MemberLeft] = MemberList,
    get_member_name_list_helper(MemberLeft, NameList++[Member#ets_guild_member.name]).

%% 私有_邮件服务
get_official_name_list(GuildId, Position) ->
    GuildMembers = lib_guild_base:get_guild_official(GuildId, Position),
    get_official_name_list_helper(GuildMembers, []).

%% 私有_邮件服务
get_official_name_list_helper([], NameListNew) ->
    NameListNew;
get_official_name_list_helper(GuildMembers, NameListNew) ->
    [GuildMember|GuildMemberLeft] = GuildMembers,
    get_official_name_list_helper(GuildMemberLeft, NameListNew++[GuildMember#ets_guild_member.name]).

%% 私有_邮件服务
get_range_official_name_list(GuildId, StartPosition, EndPosition) ->
    get_range_official_name_list_helper(GuildId, StartPosition, EndPosition, []).
get_range_official_name_list_helper(_GuildId, StartPosition, EndPosition, NameList) when StartPosition > EndPosition ->
    NameList;
get_range_official_name_list_helper(GuildId, StartPosition, EndPosition, NameList) ->
    GuildMembers   = lib_guild_base:get_guild_official(GuildId, StartPosition),
    TempNameList   = lib_guild_base:get_official_name_list_helper(GuildMembers, []),
    get_range_official_name_list_helper(GuildId, StartPosition+1, EndPosition, NameList++TempNameList).

%% -----------------------------------------------------------------
%% 发送消息给帮派所有成员
%% -----------------------------------------------------------------
send_guild(GuildId, MsgType, Bin) ->
%% 	Pids = ets:match(?ETS_UNITE, #ets_unite{pid='$1', guild_id=GuildId, _='_'}),
	Pids = mod_chat_agent:match(guild_id_pid_sid, [GuildId]),
	F = fun(P) ->
				gen_server:cast(P, {'guild',{MsgType, Bin}})
		end,
	[F(Pid) || [_, Pid, _] <- Pids].

%% -----------------------------------------------------------------
%% 发送消息给帮派所有成员（排除其中一个）
%% -----------------------------------------------------------------
send_guild_except_one(GuildId, PlayerId, MsgType, Bin) ->
    Ids =  mod_chat_agent:match(guild_id_pid_sid, [GuildId]),
    F = fun([PlayerId1, PlayerPid]) ->
        case PlayerId1 =/= PlayerId of
            true -> gen_server:cast(PlayerPid, {'guild',{MsgType, Bin}});
            false-> void
        end
    end,
    [F([Id, Pid]) || [Id, Pid, _] <- Ids].

%% -----------------------------------------------------------------
%% 发送消息给帮派官员
%% -----------------------------------------------------------------
send_guild_official(0, _GuildId, _MsgType, _Bin) ->
    void;
send_guild_official(GuildPosition, GuildId, MsgType, Bin) ->
    Pids =  mod_chat_agent:match(guild_id_pid_sid, [GuildId, GuildPosition]),
    F = fun(P) ->
        gen_server:cast(P, {'guild',{MsgType, Bin}})
    end,
    [F(Pid) || [_, Pid, _] <- Pids],
    send_guild_official(GuildPosition-1, GuildId, MsgType, Bin).

%% -----------------------------------------------------------------
%% 发送消息给单个成员
%% -----------------------------------------------------------------
send_one(PlayerId, MsgType, Bin) ->
    case mod_chat_agent:lookup(PlayerId) of
		[] ->
			skip;
		[EU] ->
			gen_server:cast(EU#ets_unite.pid, {'guild',{MsgType, Bin}})
	end.

%% -----------------------------------------------------------------
%% 私有_计算分页（起始位置为1）
%% -----------------------------------------------------------------
calc_page_cache(RecordTotal, PageSize, PageNo) ->
    PageTotal = (RecordTotal+PageSize-1) div PageSize,
    StartPos = (PageNo - 1) * PageSize + 1,
    if
        ((PageNo > PageTotal) or (PageNo < 1)) ->
            {PageTotal, 1, 0};
        true ->
            if
                PageNo*PageSize > RecordTotal ->
                    {PageTotal, StartPos, RecordTotal-(PageNo-1) * PageSize};
                true ->
                    {PageTotal, StartPos, PageSize}
            end
    end.

%% -----------------------------------------------------------------
%% 获取物品信息
%% -----------------------------------------------------------------
get_goods_type_by_type_info(GoodsType, GoodsSubType) ->
    case data_goods_type:get_by_type(GoodsType, GoodsSubType) of
        [] -> [];
        [Id|_] -> data_goods_type:get(Id)
    end.

%% -----------------------------------------------------------------
%% 获取物品类型
%% -----------------------------------------------------------------
get_goods_type(GoodsId) ->
    data_goods_type:get(GoodsId).

%% 使用物品

del_goods_unite(PlayerId, GoodsTypeId, Num) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
            gen_server:call(Pid, {del_goods_unite, GoodsTypeId, Num});
        _ ->
            0
    end.

%%% ============================================================
%%%                         帮派商城
%%% ============================================================

%% 查询帮派商城物品列表
get_guild_mall_goods_list(UniteStatus, GuildId, _MallLevel) ->
   	PlayerId = UniteStatus#unite_status.id,
    case lib_guild_base:get_guild(GuildId) of
        [] ->   %% 未加入帮派
            [0, []];
        Guild ->
			MallLevel = case Guild#ets_guild.mall_level > Guild#ets_guild.level of
							true ->
								Guild#ets_guild.level;
							false ->
								Guild#ets_guild.mall_level
						end,
            RoleLevel = UniteStatus#unite_status.lv,
            AllGoodsList0 = data_guild:get_guild_mall_goods_list(),
			AllGoodsList = lists:reverse(AllGoodsList0),
            MallGoodsList =
            lists:foldl(
                fun(MallGoodsInfo, AccList) ->
                        {GoodsTypeId, UnitGoodsCost, UnitGoodsType, UnitGoodsNum, MallDailyMaxNumList, DailyType, MinLevel, MaxLevel} = MallGoodsInfo,
						Lv_Limit = get_exchange_level(MallDailyMaxNumList, 1),
                        case RoleLevel >= MinLevel andalso RoleLevel =< MaxLevel of
                            true ->
								case lists:keyfind(GoodsTypeId, 1, AccList) of
									false->
		                                MallDailyMaxNum = lists:nth(MallLevel, MallDailyMaxNumList),
		                                ExchangedNum = mod_daily_dict:get_count(PlayerId, DailyType),   %% 查询每天兑换数
		                            	[{GoodsTypeId, UnitGoodsCost, UnitGoodsType, UnitGoodsNum, MallDailyMaxNum, ExchangedNum, DailyType, Lv_Limit} | AccList];
									{_, _, _, _, MallDailyMaxNumOld0, _, _, Lv_Limit0} ->
		                                MallDailyMaxNum = lists:nth(MallLevel, MallDailyMaxNumList),
										case MallDailyMaxNum > MallDailyMaxNumOld0 of
											true ->
												Lv_Limit1 = case Lv_Limit0 >= Lv_Limit of
													true ->
														Lv_Limit;
													false ->
														Lv_Limit0
												end,
												ExchangedNum = mod_daily_dict:get_count(PlayerId, DailyType),   %% 查询每天兑换数
												NewTuple = {GoodsTypeId, UnitGoodsCost, UnitGoodsType, UnitGoodsNum, MallDailyMaxNum, ExchangedNum, DailyType, Lv_Limit1},
												lists:keyreplace(GoodsTypeId, 1, AccList, NewTuple);
											false ->
												AccList
										end
								end;
                            false ->    %% 玩家等级不符合
								AccList
                        end
                end, [], AllGoodsList),
			MallGoodsListSort = lists:sort(fun(A, B) ->
							   erlang:element(7, A) =< erlang:element(7, B)
					   end, MallGoodsList),
            [1, MallGoodsListSort]
    end.

get_exchange_level(MallDailyMaxNumList, N) ->
	[H|T] = MallDailyMaxNumList,
	case N >= 15 of
		true ->
			15;
		false ->
			case H > 0 of
				true ->
					N;
				false ->
					NNext = N + 1,
					get_exchange_level(T, NNext)
			end
	end.

exchange_mall_goods_with_material(UniteStatus, [GoodsTypeId, NUnitNum]) ->
    GuildId = UniteStatus#unite_status.guild_id,
	Guild = lib_guild_base:get_guild(GuildId),
	case Guild =:= [] of
        true -> %% 帮派信息不存在
            [2, 0, 0, 0];
        false->
			MallLevel = case Guild#ets_guild.mall_level > Guild#ets_guild.level of
							true ->
								Guild#ets_guild.level;
							false ->
								Guild#ets_guild.mall_level
						end,
			GuildMember = lib_guild_base:get_guild_member_by_player_id(UniteStatus#unite_status.id),
			case GuildMember =:= [] of
				true ->%% 帮派成员信息不存在
					[2, 0, 0, 0];
				false ->
					case NUnitNum > 0 of
				        true ->
				            [Result,MallGoodsList] = get_guild_mall_goods_list(UniteStatus, GuildId, MallLevel),
				            case Result of
				                1 ->
				                    case lists:keyfind(GoodsTypeId, 1, MallGoodsList) of
				                        false ->  %% 帮派商城等级不够 不可兑换此商品
				                            [5, GoodsTypeId, 0, 0];
				                        {GoodsTypeId, UnitGoodsCost, UniteGoodsType, _UnitGoodsNum, DailyMaxExchangeNum, DailyExchangedNum, DailyType, _} ->
				                            RoleId = UniteStatus#unite_status.id,
				                            case DailyExchangedNum + NUnitNum > DailyMaxExchangeNum of
				                                true ->     %% 兑换数量超出每天限制
				                                    [3, GoodsTypeId, 0, 0];
				                                false ->
				                                    NeedMaterial = NUnitNum * UnitGoodsCost,
                                                    %%帮派战功和帮派财富兑换
                                                    case UniteGoodsType of 
                                                        1 -> % 帮派财富
				                                            RoleMaterial = GuildMember#ets_guild_member.material;
                                                        2 -> % 帮派战功
                                                            Factionwar = GuildMember#ets_guild_member.factionwar,
                                                            RoleMaterial = Factionwar#factionwar_info.war_score-Factionwar#factionwar_info.war_score_used
                                                    end,
				                                    case NeedMaterial > RoleMaterial of
				                                        true ->     %% 个人帮派财富不足
				                                            [4, GoodsTypeId, 0, 0];
				                                        false ->%% {equip, GoodsTypeId, Prefix, Stren }
				                                            GiveList = [{GoodsTypeId, NUnitNum}],  %% 绑定物品
															case send_goods_unite(RoleId, GiveList, bind) of
				                                                ok ->
																	%% 运势任务(3700004:帮派商城)
																	lib_fortune:fortune_daily(RoleId, 3700004, 1),
                                                                    %% 更细玩家的帮派财富或者帮派战功
                                                                    case UniteGoodsType of
                                                                        1 -> % 帮派财富
				                                                            lib_guild_base:update_guild_member(GuildMember#ets_guild_member{material = RoleMaterial - NeedMaterial});   
                                                                        _ -> %帮派战功
                                                                            _FactionWar = GuildMember#ets_guild_member.factionwar,
                                                                            NewFactionWar = _FactionWar#factionwar_info{
                                                                                war_score_used = _FactionWar#factionwar_info.war_score_used+NeedMaterial
                                                                            },
                                                                            lib_guild_base:update_guild_member(GuildMember#ets_guild_member{factionwar = NewFactionWar}),
                                                                            lib_player:update_player_info(GuildMember#ets_guild_member.id, [{factionwar_used, NeedMaterial}])
                                                                    end,
																	mod_daily_dict:plus_count(RoleId, DailyType, NUnitNum),
				                                                    log_guild_mall_exchange(RoleId, GoodsTypeId, DailyExchangedNum, NeedMaterial),
				                                                    lib_player:refresh_client(RoleId, 2),
				                                                    [1, GoodsTypeId, DailyMaxExchangeNum, DailyExchangedNum + NUnitNum];
				                                                {fail, Res} ->
				                                                    case Res of
				                                                        2 ->    %% 物品类型不存在
				                                                            [6, GoodsTypeId, 0, 0];
				                                                        3 ->    %% 背包空间不足
				                                                            [7, GoodsTypeId, 0, 0];
				                                                        _ ->    %% 失败
				                                                            [0, GoodsTypeId, 0, 0]
				                                                    end;
				                                                _ ->    %% 失败
				                                                    [0, GoodsTypeId, 0, 0]
				                                            end
				                                    end
				                            end
				                    end;
				                _ ->
				                    [2, GoodsTypeId, 0, 0]
				            end;
				        false ->    %% 兑换数量错误
				            [0, GoodsTypeId, 0, 0]
				    end
			end
	end.

%% 帮派商城兑换日志
log_guild_mall_exchange(RoleId, GoodsTypeId, ExchangeNum, MaterialCost) ->
    Sql = lists:concat(["INSERT INTO log_guild_mall_exchange (role_id,goods_type_id,exchange_num,material_cost,`time`) VALUES (", RoleId, ",", GoodsTypeId, ",", ExchangeNum, ",", MaterialCost, ",UNIX_TIMESTAMP())"]),
    db:execute(Sql).

%% -----------------------------------------------------------------
%% 帮派历史事件功能
%% -----------------------------------------------------------------

%% 获取帮派历史事件
get_guild_event(RoleId, GuildId, MenuType, PageSize, PageNo) ->
    case GuildId == 0 of
        %% 没有帮派
        true ->
            [2, 0, 0, []];
        false ->
            Guild = lib_guild_base:get_guild(GuildId),
            case Guild =:= [] of
                %% 帮派信息不存在
                true ->
                    [0, 0, 0, []];
                false->
					GuildEventList = case MenuType of
						0->
							%% 写入查询时间记录
							NowTime = util:unixtime(),
							SearchTime = mod_daily_dict:get_count(RoleId, 4007807),
							case NowTime - SearchTime >= 60 of
								false ->
									case get(guildevent) of
										undefined ->
											Data = [GuildId],
				                    		SQL  = io_lib:format(?SQL_GUILD_EVENT_SELECT, Data),
				                    		AllGE = db:get_all(SQL),
											mod_daily_dict:set_count(RoleId, 4007807, NowTime),
											%% 把目前的历史记录插入缓存
											put(guildevent, AllGE),
											AllGE;
										ValueGE ->
											ValueGE
									end;
								true ->
									Data = [GuildId],
		                    		SQL  = io_lib:format(?SQL_GUILD_EVENT_SELECT, Data),
		                    		AllGE = db:get_all(SQL),
									mod_daily_dict:set_count(RoleId, 4007807, NowTime),
									%% 把目前的历史记录插入缓存
									put(guildevent, AllGE),
									AllGE
							end;
						_->
							Data = [GuildId, MenuType],
                    		SQL  = io_lib:format(?SQL_GUILD_EVENT_SELECT_BY_TYPE, Data),
                    		db:get_all(SQL)
					end,
					GuildEventLength = length(GuildEventList),
				    %% 计算分页
				    {PageTotal, StartPos, _RecordNum} = calc_page_cache(GuildEventLength, PageSize, PageNo),
				    %% 获取分页
				    RowsPage = lists:sublist(GuildEventList, StartPos, PageSize),
                    [1,  PageTotal, PageNo, RowsPage]
            end
    end.

%% 记录帮派历史事件
log_guild_event(GuildId, EventType, EventParam) ->
    EventTime     = util:unixtime(),
    {MenuType, NewEventParam} = case EventType of
        % 加入帮派
        1 ->
            [PlayerId, PlayerName, Position] = EventParam,
            PlayerIdList  = integer_to_list(PlayerId),
            PositionList  = integer_to_list(Position),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, PositionList]),
			{5, A2};
        % 踢出帮派
        2 ->
            [PlayerId, PlayerName, Position] = EventParam,
            PlayerIdList  = integer_to_list(PlayerId),
            PositionList  = integer_to_list(Position),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, PositionList]),
			{4, A2};
        % 退出帮派
        3 ->
            [PlayerId, PlayerName, Position] = EventParam,
            PlayerIdList  = integer_to_list(PlayerId),
            PositionList  = integer_to_list(Position),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, PositionList]),
			{4, A2};
        % 升职
        4 ->
           [PlayerId, PlayerName,OldPosition, NewPosition] = EventParam,
            PlayerIdList    = integer_to_list(PlayerId),
            OldPositionList = integer_to_list(OldPosition),
            NewPositionList = integer_to_list(NewPosition),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, OldPositionList, ?SEPARATOR_STRING, NewPositionList]),
			{1, A2};
        % 降职
        5 ->
            [PlayerId, PlayerName,OldPosition, NewPosition] = EventParam,
            PlayerIdList    = integer_to_list(PlayerId),
            OldPositionList = integer_to_list(OldPosition),
            NewPositionList = integer_to_list(NewPosition),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, OldPositionList, ?SEPARATOR_STRING, NewPositionList]),
			{1, A2};
        % 禅让
        6 ->
            [PlayerId, PlayerName, Position, NewChiefId, NewChiefName, NewChiefOldPostion] = EventParam,
            PlayerIdList           = integer_to_list(PlayerId),
            NewChiefIdList         = integer_to_list(NewChiefId),
            PositionList           = integer_to_list(Position),
            NewChiefOldPostionList = integer_to_list(NewChiefOldPostion),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, PositionList, ?SEPARATOR_STRING, NewChiefIdList, ?SEPARATOR_STRING, NewChiefName, ?SEPARATOR_STRING, NewChiefOldPostionList]),
			{1, A2};
        % 辞官
        7 ->
            [PlayerId, PlayerName,OldPosition, NewPosition] = EventParam,
            PlayerIdList    = integer_to_list(PlayerId),
            OldPositionList = integer_to_list(OldPosition),
            NewPositionList = integer_to_list(NewPosition),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, OldPositionList, ?SEPARATOR_STRING, NewPositionList]),
			{1, A2};
        % 弹劾
        8 ->
            [PlayerId, Position, PlayerName, ChiefId, ChiefName, ChiefPosition] = EventParam,
            PlayerIdList      = integer_to_list(PlayerId),
            PositionList      = integer_to_list(Position),
            ChiefIdList       = integer_to_list(ChiefId),
            ChiefPositionList = integer_to_list(ChiefPosition),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, PositionList, ?SEPARATOR_STRING, ChiefIdList, ?SEPARATOR_STRING, ChiefName, ?SEPARATOR_STRING, ChiefPositionList]),
			{1, A2};
        % 捐钱
        9 ->
            [PlayerId, PlayerName, Position, Num] = EventParam,
            PlayerIdList  = integer_to_list(PlayerId),
            PositionList  = integer_to_list(Position),
            NumList       = integer_to_list(Num),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, PositionList, ?SEPARATOR_STRING, NumList]),
			{6, A2};
        % 捐建设令
        10 ->
            [PlayerId, PlayerName, Position, Num] = EventParam,
            PlayerIdList  = integer_to_list(PlayerId),
            PositionList  = integer_to_list(Position),
            NumList       = integer_to_list(Num),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, PositionList, ?SEPARATOR_STRING, NumList]),
			{6, A2};
        % 分配奖励_不要了
        11 ->
            skip;
        % 领取奖励_不要了
        12 ->
            skip;
        % 捐献元宝
        13 -> 
            [PlayerId, PlayerName, Position, GoldNum] = EventParam,
            PlayerIdList    = integer_to_list(PlayerId),
            PositionList    = integer_to_list(Position),
            GoldNumList     = integer_to_list(GoldNum),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, PositionList, ?SEPARATOR_STRING, GoldNumList]),
		    {6, A2};
        % 升级技能
        14 -> 
            skip;
        % 获得亲密度礼包
        15 ->
          	skip;
        % 物品存入仓库
        16 ->
            [PlayerId, PlayerName, Position, GoodsId, GoodsName, GoodsNum] = EventParam,
            PlayerIdList  = integer_to_list(PlayerId),
            PositionList  = integer_to_list(Position),
            % 获取物品类型ID
            Go = lib_player:get_player_info(PlayerId, goods),
            [Goods, _, _] =  gen_server:call(Go#status_goods.goods_pid, {'info_other', GoodsId}),
            GoodsTypeId     = case Goods =:= [] of
                                  true -> 0;
                                  false-> Goods#goods.goods_id
                              end,
            GoodsTypeIdList = integer_to_list(GoodsTypeId),
            GoodsNumList    = integer_to_list(GoodsNum),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, PositionList, ?SEPARATOR_STRING, GoodsTypeIdList, ?SEPARATOR_STRING, GoodsName, ?SEPARATOR_STRING, GoodsNumList]),
			{7, A2};
        % 物品取出仓库
        17 ->
            [PlayerId, PlayerName, Position, GoodsTypeInfo, GoodsName, GoodsNum] = EventParam,
            PlayerIdList  = integer_to_list(PlayerId),
            PositionList  = integer_to_list(Position),
            GoodsNumList    = integer_to_list(GoodsNum),
            GoodsTypeIdList = integer_to_list(GoodsTypeInfo#ets_goods_type.goods_id),
            A2 = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, PositionList, ?SEPARATOR_STRING, GoodsTypeIdList, ?SEPARATOR_STRING, GoodsName, ?SEPARATOR_STRING, GoodsNumList]),
			{7, A2};
		% 升级帮派神炉
        21 ->
            [OldLevel, NewLevel] = EventParam,
            OldLevelList  = integer_to_list(OldLevel),
            NewLevelList  = integer_to_list(NewLevel),
		    A2 = list_to_binary([OldLevelList, ?SEPARATOR_STRING, NewLevelList]),
			{2, A2};
		% 升级帮派商城
        22 ->
            [OldLevel, NewLevel] = EventParam,
            OldLevelList  = integer_to_list(OldLevel),
            NewLevelList  = integer_to_list(NewLevel),
		    A2 = list_to_binary([OldLevelList, ?SEPARATOR_STRING, NewLevelList]),
			{2, A2};
		% 升级帮派仓库
        23 ->
            [OldLevel, NewLevel] = EventParam,
            OldLevelList  = integer_to_list(OldLevel),
            NewLevelList  = integer_to_list(NewLevel),
		    A2 = list_to_binary([OldLevelList, ?SEPARATOR_STRING, NewLevelList]),
			{2, A2};
		% 升级帮派祭坛
        24 ->
            [OldLevel, NewLevel] = EventParam,
            OldLevelList  = integer_to_list(OldLevel),
            NewLevelList  = integer_to_list(NewLevel),
		    A2 = list_to_binary([OldLevelList, ?SEPARATOR_STRING, NewLevelList]),
			{2, A2};
		% 升级帮派厢房
        25 ->
			[OldLevel, NewLevel, NewMemberCapacity, DonationAdd, PaidAdd] = EventParam,
            OldLevelList  = integer_to_list(OldLevel),
            NewLevelList  = integer_to_list(NewLevel),
			NewMemberCapacityList  = integer_to_list(NewMemberCapacity),
            DonationAddList  = integer_to_list(DonationAdd),
			PaidAddList  = integer_to_list(PaidAdd),
		    A2 = list_to_binary([OldLevelList, ?SEPARATOR_STRING
								 , NewLevelList, ?SEPARATOR_STRING
								 , NewMemberCapacityList, ?SEPARATOR_STRING
								 , DonationAddList, ?SEPARATOR_STRING
								 , PaidAddList]),
			{2, A2};
		% 帮战记录
        30 ->
			[Count, Rank] = EventParam,
            CountList  = integer_to_list(Count),
            RankList  = integer_to_list(Rank),
		    A2 = list_to_binary([CountList, ?SEPARATOR_STRING
								 , RankList]),
			{3, A2}
    end,
    Data       = [GuildId, EventTime, MenuType, EventType, NewEventParam],
    SQL        = io_lib:format(?SQL_GUILD_EVENT_INSERT, Data),
    %?DEBUG("log_guild_event: SQL=[~s]", [SQL]),
    db:execute(SQL),
    ok.

%% -----------------------------------------------------------------
%% 帮派祭坛功能
%% -----------------------------------------------------------------

%% 获取帮派祭坛信息
get_guild_altar_info([GuildId, PlayerId]) ->
	case lib_guild_base:get_guild(GuildId) of
		[] -> %%没有帮派_帮派ID不存在
		   [2, 0, 0, []];
		GuildInfo -> 
			case GuildInfo#ets_guild.altar_level < 1 of
				true ->
					[2, 0, 0, []];
				false ->
					case mod_daily_dict:get_special_info({PlayerId, 4007904}) of
						undefined -> %% 没有数据
							AltarLevel = GuildInfo#ets_guild.altar_level,
							%% 获取所有物品列表(1-10级)
							GoodsList = data_guild:get_altar_goods(),
							GoodsList_This_Level = [D || D <- GoodsList, erlang:element(2, D) =< AltarLevel],
							Probability_List = [erlang:element(5, D) || D <- GoodsList_This_Level],
							Probability_For_Use = altar_probability_handle(Probability_List, [{0,0,0}]),
                    
							Kb = lists:sum(Probability_List),
							%% 生成中奖物品
							{ChoosedId, ChoosedNum} = case mod_daily_dict:get_count(PlayerId, 4007902) of
								0 ->
									%% 没有物品
									Rand2 = util:rand(0, Kb-1),
									Rand3 = util:rand(1, 100),
									Rand4 = util:rand(0, Kb-1),
									Rand1 = case Rand3 < 50 of
												true ->
													Rand2;
												false ->
													Rand4
											end,
									_Rand1 = util:rand(1, 100),
									%% 按照概率随机
									[{Filter, _, _}] = lists:filter(fun(X) -> {_ThisD, H, T} = X, Rand1 >= H andalso Rand1 < T end, Probability_For_Use),
									{_, _, GoodsTypeId1, GoodsNum1, _} = lists:keyfind(Filter, 5, GoodsList_This_Level),
									mod_daily_dict:set_count(PlayerId, 4007902, GoodsTypeId1),
									mod_daily_dict:set_count(PlayerId, 4007903, GoodsNum1),
									{GoodsTypeId1, GoodsNum1};
								GoodsIdSaved ->
									GoodsNumSaved = mod_daily_dict:get_count(PlayerId, 4007903),
									{GoodsIdSaved, GoodsNumSaved}
							end,
							GoodsListStep1 = altar_tccf(GoodsList, []),
							[BaodiId1, BaodiId2] = altar_baodi(),
							GoodsListTCL = lists:filter(fun({_, _, GoodsTypeIdTC, _, _}) ->
																   GoodsTypeIdTC =/= ChoosedId andalso GoodsTypeIdTC =/= BaodiId1 andalso GoodsTypeIdTC =/= BaodiId2
														   end, GoodsListStep1),
							[BWin, B1, B2] = altar_rand3(),
							GoodListOver = altar_over(12, {ChoosedId, ChoosedNum}, BaodiId1, BaodiId2, BWin, B1, B2, GoodsListTCL, []),
							%% 记录各种信息
							mod_daily_dict:set_count(PlayerId, 4007904, BWin),
							mod_daily_dict:set_special_info({PlayerId, 4007904}, GoodListOver),
							[1, AltarLevel, PlayerId, GoodListOver];
					GoodListS ->
							AltarLevel = GuildInfo#ets_guild.altar_level,
							[1, AltarLevel, PlayerId, GoodListS]
					end
			end
	end.

altar_tccf([], BackList)->
	BackList;
altar_tccf(FromList, BackList)->
	[H|T] = FromList,
	{_, _, GoodsTypeIdTC, _, _} = H,
	BackListNext = case lists:any(fun({_, _, GoodsTypeId, _, _}) -> GoodsTypeId =:= GoodsTypeIdTC end, BackList) of
		true ->
			BackList;
		false ->
			[H|BackList]
	end,
	altar_tccf(T, BackListNext).


%% 生成新的神坛物品列表
altar_probability_handle([], F)->
	F4 = lists:reverse(F), 
	[_|Probability] = F4,
	lists:reverse(Probability);
altar_probability_handle(D, F)->
	[ThisD|D_Next] = D,
	[ThisF|_] = F,
	{_, _H, T} = ThisF,
	F_2 = ThisD + T,
	N = {ThisD, T, F_2},
	F_Next = [N|F],							  
	altar_probability_handle(D_Next, F_Next).

altar_baodi()->
	BdList = [601701,601601,624801],
	B1 = util:rand(1, 3), 
	Id1 = lists:nth(B1, BdList),
	BdList2 = lists:filter(fun(Id) ->
								 Id =/= Id1
						   end, BdList),
	B2 = util:rand(1, 2), 
	Id2 = lists:nth(B2, BdList2),
	[Id1, Id2].

altar_over(0, _, _, _, _, _, _, _, BackList)->
	BackList;
altar_over(Num, {IdWin, WinNum}, Id1, Id2, BWin, B1, B2, GoodsListTCL, BackList)->
	LenthTCL = erlang:length(GoodsListTCL),
	[BackListNext, GoodsListTCLNextX] = case Num =:= BWin of
		true ->
			BackListNew1 = [{Num, IdWin, WinNum}|BackList],
			[BackListNew1, GoodsListTCL];
		false ->
			case Num =:= B1 of
				true ->
					BackListNew2 = [{Num, Id1, 1}|BackList],
					[BackListNew2, GoodsListTCL];
				false ->
					case Num =:= B2 of
						true ->
							BackListNew3 = [{Num, Id2, 1}|BackList],
							[BackListNew3, GoodsListTCL];
						false ->
							Rand3 = util:rand(1, LenthTCL),
							{_, _, GoodsTypeIdme, GoodsNum, _} = lists:nth(Rand3, GoodsListTCL),
							NewGoodsListTCLzzz = lists:filter(fun({_, _, GoodsTypeIdTC, _, _}) ->	 
																case GoodsTypeIdTC =/= GoodsTypeIdme of
																	true ->
																		true;
																	false ->
																		false
																end
														   end, GoodsListTCL),
							BackListNew4 = [{Num, GoodsTypeIdme, GoodsNum}|BackList],
							[BackListNew4, NewGoodsListTCLzzz]
					end
			end
	end,
	altar_over(Num - 1, {IdWin, WinNum}, Id1, Id2, BWin, B1, B2, GoodsListTCLNextX, BackListNext).

altar_rand3() ->
	B1 = util:rand(1, 12),
	case B1 > 6 of
		true ->
			B2 = util:rand(1, B1 - 1),
			case B2 > 3 of
				true ->
					B3 = util:rand(1, 3),
					[B1, B2, B3];
				false ->
					B3 = util:rand(4, B1 - 1),
					[B1, B2, B3]
			end;
		false ->
			B2 = util:rand(B1 + 1, 12),
			case B2 > 9 of
				true ->
					B3 = util:rand(B1 + 1, 9),
					[B1, B2, B3];
				false ->
					B3 = util:rand(10, 12),
					[B1, B2, B3]
			end
	end.
	
	
	
%% 帮派祭坛祈祷处理
get_altar_pray(UniteStatus, [Daily_Type_ID, MaterialCost])->
	PlayerId = UniteStatus#unite_status.id,
	GuildMember = lib_guild_base:get_guild_member_by_player_id(PlayerId),
	NowYaoJiangTime = mod_daily_dict:get_count(UniteStatus#unite_status.id, Daily_Type_ID),  %% 已经祈福次数
	case GuildMember#ets_guild_member.material - MaterialCost >= 0 orelse NowYaoJiangTime < 3 of
		false ->%% 帮派财富不够
			{5, 0, 0, 0};
		true ->
			case mod_daily_dict:get_special_info({PlayerId, 4007904}) of
				undefined -> %% 列表丢失
					{2, 0, 0, 0};
				GoodList_Filter ->
					case mod_daily_dict:get_count(PlayerId, 4007904) of
						0 -> %% 中奖编号丢失(提示列表丢失)
							{2, 0, 0, 0};
						RandC ->
							case lists:keyfind(RandC, 1, GoodList_Filter) of
								false ->%% 中奖编号丢失(提示列表丢失)
									{2, 0, 0, 0};
								{IconNum, GoodsTypeId, GoodsNum} ->
									GiveList = [{GoodsTypeId, GoodsNum}],
									case send_goods_unite(PlayerId, GiveList, bind) of
										ok ->
											MaterialCostTrue = case NowYaoJiangTime < 3 of
																   true ->
																	   0;
																   false ->
																	   MaterialCost
															   end,
											NewGuildMember = GuildMember#ets_guild_member{material = GuildMember#ets_guild_member.material - MaterialCostTrue},
											lib_guild_base:update_guild_member(NewGuildMember),
											mod_daily_dict:plus_count(PlayerId, Daily_Type_ID, 1),
											mod_daily_dict:set_count(PlayerId, 4007904, 0),
											%% 清理祭坛物品列表
											mod_daily_dict:set_special_info({PlayerId, 4007904}, undefined),
											log:log_goods(get_altar_pray, 0, GoodsTypeId, GoodsNum, PlayerId),
						                    {1, IconNum, GoodsTypeId, GoodsNum};
						                {fail, Res} ->
											case Res of
												2 ->    %% 物品类型不存在
						                                    {3, 0, 0, 0};
												3 ->    %% 背包空间不足
						                                    {4, 0, 0, 0};
												_ ->    %% 失败
						                                    {0, 0, 0, 0}
											end;
										_ ->    		%% 失败
						                                    {0, 0, 0, 0}                                          
									 end;
								_V ->
									{0, 0, 0, 0}
							end
					end
			end
	end.

%% -----------------------------------------------------------------------------
%% 帮派通讯录功能
%% -----------------------------------------------------------------------------

%% 获得帮派通讯录
get_contact_book(UniteStatus, GuildId, PlayerId, PageSize, PageNo) ->
	GuildBookAllx = gen_server:call(mod_guild, {get_guild_contact_info, GuildId}),
	PS_G_P = UniteStatus#unite_status.guild_position,
	F = fun([PlayerId_LS, _, _, _, _, _, _, HideType_LS, _], Stype) ->
				if 
					PlayerId_LS =:= PlayerId->
						true;
					HideType_LS =:= 1->
						true;
					HideType_LS =:= 2 andalso Stype =:= 1->
						true;
					true ->
						false
				end
	end,
	GuildBookAll = case PS_G_P of
		1->
			lists:filter(fun(X) -> F(X, 1) end, GuildBookAllx);
		_->
			lists:filter(fun(X) -> F(X, 0) end, GuildBookAllx)
	end,
	GuildBookLength = length(GuildBookAll),
    %% 计算分页
    {PageTotal, StartPos, _RecordNum} = calc_page_cache(GuildBookLength, PageSize, PageNo),
    %% 获取分页
    RowsPage = lists:sublist(GuildBookAll, StartPos, PageSize),
    %% 发送回应
    [1, PageTotal, PageNo, RowsPage].


%% 设置自己的通讯录 
set_contact_book([PlayerId, GuildId, PlayerName, City, QQ, PhoneNum, BirDay, HideType, PlayerLv])->
	case check_contact_list(PhoneNum, QQ) of
		true -> 
			gen_server:call(mod_guild, {set_guild_contact_info, [PlayerId, GuildId, PlayerName, City, QQ, PhoneNum, BirDay, HideType, PlayerLv]}),
			1;
		{false, K} -> 
			K
	end.


%% 验证手机号码和QQ号码
check_contact_list(Phone, QQ) ->
	PhoneL = length(Phone),
	QQLx = length(QQ),
	if 
		Phone == [] andalso QQ == [] -> true;
		PhoneL /= 11 -> {false, 2};
		QQLx < 5 -> {false, 3};
      	true ->
           QQL = count(QQ),
           QQlen = length(QQL),
           QQTF = [Num > 7||{_, Num} <- QQL],
           QQFlag = lists:member(true, QQTF),
           if
               QQlen < 2 orelse QQFlag -> {false, 3};
               true -> 
                   case Phone of
                       [N1, N2, _N3|_T] -> 
                           if 
                               N1 /= $1 -> {false, 2}; 
                               N2 /= $3 andalso N2 /= $4 andalso N2 /= $5 andalso N2 /= $8 -> {false, 2};
%%                             N3 /= $3 andalso N3 /= $4 andalso N3 /= $5 andalso N3 /= $6 andalso N3 /= $7 andalso N3 /= $8 -> {false, 5};
                               true -> true
                           end;
                       _ -> {false, 0}
                   end
           end
   end.

%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 			　　代码整理区_MARKED_BY_WUZHENHUA
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% 帮派建筑升级判定_判定值_当前值_权限_级别_资金_建设度_元宝
compare_build_upgrade([Limit_Standard, BuildLevel_Standard, Funds_Standard, Contribution_Standard, Gold_Standard], [Limit, BuildLevel, Funds, Contribution, Gold])->
	if
        Limit > Limit_Standard  -> 4;
		BuildLevel > BuildLevel_Standard -> 6;
		Funds < Funds_Standard -> 7;
		Contribution < Contribution_Standard -> 8;
		Gold < Gold_Standard -> 7;
		true ->
			all_pass
	end.

%% 升级帮派建筑
upgrade_build(GuildId, BuildType, UpgradeInfo, New_Build_Level) ->
	case BuildType of	
		5 ->
			[[NewGuildHouseLevel, _],[_GoldLeft, PlayerId], GoldNum, _Sid] = UpgradeInfo,
			DonateRatio = data_guild:get_guild_config(donate_house_gold_ratio, []),
    		DonateAdd   = GoldNum * DonateRatio,
			case lib_player_unite:spend_assets_status_unite(PlayerId, GoldNum, gold, guild_house_upgrade, "") of
				{ok, ok} ->
					 case add_donation(PlayerId, DonateAdd, 3) of
				        [ok, PaidAdd] ->
				            Data  = [NewGuildHouseLevel, GuildId],
				            SQL    = io_lib:format(?SQL_GUILD_UPDATE_UPGRADE_HOUSE, Data),
				            db:execute(SQL),
							set_guild_achieved_info([GuildId, 10001, New_Build_Level, 0]),
				            [ok_house, DonateAdd, PaidAdd];
				       _ ->
				           error
				    end;
				{error, _IRes} -> %% 扣除铜币不足(扣除铜币失败)
					error
			end;
		_ ->
			error
	end.

%% 升级帮派建筑新(在帮派进程内,不能调用成就)
upgrade_build_new(_GuildId, BuildType, UpgradeInfo, _New_Build_Level) ->
	case BuildType of	
		1 ->
			Sql = io_lib:format(?SQL_GUILD_UPDATE_UPGRADE_FURNACE, UpgradeInfo),
			db:execute(Sql),
			ok;
		2 ->
			Sql = io_lib:format(?SQL_GUILD_UPDATE_UPGRADE_MALL, UpgradeInfo),
			db:execute(Sql),
			ok;
		3 ->
			Sql  = io_lib:format(?SQL_GUILD_UPDATE_UPGRADE_DEPOT, UpgradeInfo),
			db:execute(Sql),
			ok;
		4 ->
			Sql  = io_lib:format(?SQL_GUILD_UPDATE_UPGRADE_ALTAR, UpgradeInfo),
			db:execute(Sql),
			ok;
		_ ->
			error
	end.

%% 获取帮派神炉的强化成功率加成
%% @param 玩家ID, 帮派ID, 铜币消耗 
get_furnace_add(RoleId, GuildId, CoinCost)->
	mod_disperse:call_to_unite(lib_guild, get_furnace_add, [unite, RoleId, GuildId, CoinCost]).

get_furnace_add(unite, _RoleId, GuildId, _CoinCost) ->
	case lib_guild_base:get_guild(GuildId) of
		Guild when is_record(Guild, ets_guild) ->
			[Num, _Coin, _Contribution] = data_guild:get_furnace_info(Guild#ets_guild.furnace_level),
			Num;
		_ ->
			0
	end.


%% 强化后帮派神炉返利
%% @param PS, 铜币消耗
put_furnace_back(PlayerStatus, CoinCost) ->
	RoleId = PlayerStatus#player_status.id,
	GuildId = PlayerStatus#player_status.guild#status_guild.guild_id,
	case CoinCost > 0 andalso GuildId > 0 of
		true ->  %% 添加返利
			mod_disperse:cast_to_unite(lib_guild, put_furnace_back, [unite, RoleId, GuildId, CoinCost]);
		false -> %% 不添加返利
			ok
	end.

put_furnace_back(unite, RoleId, GuildId, CoinCost) ->
	gen_server:cast(mod_guild, {put_furnace_back, RoleId, GuildId, CoinCost}).

check_furnace_back(RoleId, GuildId) ->
	gen_server:call(mod_guild, {check_furnace_back, RoleId, GuildId}).

get_furnace_back(RoleId, GuildId) ->
	gen_server:call(mod_guild, {get_furnace_back, RoleId, GuildId}).

%% 成员容量_获取
calc_member_capacity(MemberCapacity, HouseLevel) ->
    MemberCapacity+HouseLevel*5.

%% 获取帮派技能_个人
get_guild_skill_info([GuildId, PlayerId])->
	GuildMember = lib_guild_base:get_guild_member_by_player_id(PlayerId),
	Guild_Info = get_guild(GuildId),
	[Guild_Level, Player_Donate] = [Guild_Info#ets_guild.level, GuildMember#ets_guild_member.donate_total],
	Player_Guild_Skill = gen_server:call(mod_guild, {get_guild_skill_player, [GuildId, GuildMember]}),
	Player_Guild_Skill_Pack = lists:map(fun(D) -> {_, Skill_Id, Skill_Level, _A, _B, Skill_Add} = D, [Skill_Id, Skill_Level, 0, 0, Skill_Add] end, Player_Guild_Skill),
	[Guild_Level, Player_Donate, Player_Guild_Skill_Pack].

%% 获取帮派技能加成
%% @param Check_Type = 加成的类型 ==> 10001:经验加成	 10002:修理费减少 10003:坐骑移动速度加成 
%%									  10004:打怪铜币获取加成 10005:NPC购买物品价格减少 10006:历练获得加成 10007: 修为获得加成	
%% @return 加成比例 INT							
get_guild_skill_add([PlayerId, Check_Type])->
	GuildMember = lib_guild_base:get_guild_member_by_player_id(PlayerId),
	[_,_,Personal_Guild_Skill] = get_guild_skill_info([GuildMember#ets_guild_member.guild_id, PlayerId]), 
	case lists:keyfind(Check_Type, 1, [erlang:list_to_tuple(D)|| D<-Personal_Guild_Skill]) of
		false ->
			0;
		Value ->
			{_, _, _, _, Skill_Add} = Value,
			Skill_Add
	end.

%% -----------------------------------------------------------------
%% 帮派成就相关
%% -----------------------------------------------------------------

%% 获得帮派成就
get_guild_achieved_info([GuildId, AchieveType]) ->
	%% 获取目前帮派已在进行中的成就_
	GuildBookAll = gen_server:call(mod_guild, {get_guild_achieve_info, GuildId}),
	case lists:keysearch(AchieveType, 2, GuildBookAll) of
		false ->
			%% 找不到_就构造一个新的
			gen_server:call(mod_guild, {new_guild_achieve_info, [GuildId, AchieveType]});
		{value, Value} ->
			Value
	end.

%% 帮派目标领奖
get_guild_achieved_prize([PlayerId, GuildId, AchieveType, _AchieveLevel]) ->
	case gen_server:call(mod_guild, {get_guild_achieve_info, [GuildId, AchieveType]}) of
		[0,_] ->
			%% 领取失败
			0;
		[1,[G_Funds ,G_Contribution ,G_menber_Donate ,G_menber_Material]] ->
			%% 领取成功_发放奖励
			gen_server:cast(mod_guild, {send_achieved_prize, [PlayerId, GuildId, G_Funds ,G_Contribution ,G_menber_Donate ,G_menber_Material]}),
			1
	end.

%% 异步使用_帮派目标奖励发送
send_achieved_prize([PlayerId, GuildId, _G_Funds ,G_Contribution ,G_menber_Donate ,G_menber_Material]) ->
	%% 更新帮派建设度
	change_guild_contribution([GuildId, PlayerId, G_Contribution]),
	%% 更新帮派成员财富和贡献度所有成员
	Pids = mod_chat_agent:match(guild_id_pid_sid, [GuildId]),
	Bin = [PlayerId, G_menber_Donate ,G_menber_Material],
	F = fun([_, P, _]) ->
				gen_server:cast(P, {'guild',{change_guild_member2, Bin}})
		end,
	lists:foreach(F, Pids).

%% 更新帮派成就_由事件触发_
set_guild_achieved_info([GuildId, AchievedType, Condition1_num, Condition2_num])->
	gen_server:call(mod_guild, {set_guild_achieve_info, [GuildId, AchievedType, Condition1_num, Condition2_num]}).

%% -----------------------------------------------------------------
%% 直接对lib_guild_base的调用
%% -----------------------------------------------------------------

%% 更新帮派数据_无用户信息
update_guild(GuildInfo) ->
	lib_guild_base:update_guild(GuildInfo).

%% 更新帮派数据_有用户信息
update_guild(GuildInfo, PlayerId) ->
	case get_unite_pid(PlayerId)==self() of
		true->
			%%在公共线
			lib_guild_base:update_guild(GuildInfo);
		false->
			%%不在公共线
			mod_disperse:cast_to_unite(lib_guild_base, update_guild, [GuildInfo])
	end.

%% 获取帮派数据
get_guild(GuildId) ->
	lib_guild_base:get_guild(GuildId).

%% 从公共线发放 物品
send_goods_unite(PlayerId, GoodsList, Type) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
            gen_server:call(Pid, {send_goods_unite, Type, GoodsList});
        _ ->
            0
    end.

%% 获取用户的公共服进程ID
get_unite_pid(Id) ->
    case mod_chat_agent:lookup(Id) of
        [] ->
            error;
        [Player] ->
			Player#ets_unite.pid
    end.

get_unite_player(Id) ->
    case mod_chat_agent:lookup(Id) of
        [Player] when is_record(Player, ets_unite)->
			Player;
		_ ->
			[]
    end.

%% 同步自己的帮派信息(需要同步_游戏线,公共线,聊天线,帮派成员数据)_此方法在公共线调用
guild_self_syn(UniteStatus, [GuildId, GuildName, GuildPosition]) ->
	PlayerId = UniteStatus#unite_status.id,
	%% 同步聊天线
	case mod_chat_agent:lookup(PlayerId) of
		[] ->
			[];
		[Player] ->
			mod_chat_agent:insert(Player#ets_unite{
	            guild_id = GuildId,
	            guild_name = util:make_sure_list(GuildName),
	            guild_position = GuildPosition
	        })
	 end,
	GuildLevel = get_guild_lv_only(GuildId),
	%% 同步游戏线
	lib_player:update_player_info(PlayerId, [{guild_syn, [GuildId, GuildName, GuildPosition, GuildLevel]}]),
	%% 发送40099同步玩家帮派信息
	GuildNameList = util:make_sure_list(GuildName),
	{ok, BinData} = pt_400:write(40099, [GuildId, GuildNameList, GuildPosition]),
	lib_unite_send:send_to_one(PlayerId, BinData),
	%% 同步帮派同盟信息
	case GuildId =/= UniteStatus#unite_status.guild_id of
		true ->
			[FList, EList] = case GuildId =/= 0 of
				true ->
					GuildRelaDict = guild_rela_handle:get_self_rela(GuildId),
					DictList = dict:to_list(GuildRelaDict),
					FList1 = [OneGuildIdF||{OneGuildIdF, TypeF} <- DictList, TypeF =:= 1],
					EList1 = [OneGuildIdE||{OneGuildIdE, TypeE} <- DictList, TypeE =:= 2],
					[FList1, EList1];
				false ->
					[[], []]
			end,
			{ok, BinDataGuild} = pt_403:write(40340, [1, FList, EList]),
			lib_unite_send:send_to_guild(GuildId, BinDataGuild),
			guild_rela_handle:syn_server(PlayerId, FList, EList);
		false ->
			skip
	end,
	NewUniteStatus = UniteStatus#unite_status{guild_id = GuildId, guild_name = GuildName, guild_position = GuildPosition},
	NewUniteStatus.

%% 同步他人的帮派信息(需要同步_游戏线,公共线,聊天线,帮派成员数据)_此方法在公共线调用

%% 用于对他人的帮派信息变更操作(如:踢出帮派等)
guild_other_syn([PlayerId, GuildId, GuildName, GuildPosition]) ->
	%% 同步公共线unite_status
	updata_unite_status([PlayerId, GuildId, GuildName, GuildPosition]),
	%% 同步聊天线(这里有一次冗余)
	case mod_chat_agent:lookup(PlayerId) of
		[] ->
			[];
		[Player] ->
			mod_chat_agent:insert(Player#ets_unite{
	            guild_id = GuildId,
	            guild_name = util:make_sure_list(GuildName),
	            guild_position = GuildPosition
	        })
	 end,
	GuildLevel = get_guild_lv_only(GuildId),
	%% 同步游戏线
	lib_player:update_player_info(PlayerId, [{guild_syn, [GuildId, util:make_sure_list(GuildName), GuildPosition, GuildLevel]}]),
	%% 发送40099同步玩家帮派信息
	GuildNameList = util:make_sure_list(GuildName),
	{ok, BinData} = pt_400:write(40099, [GuildId, GuildNameList, GuildPosition]),
	lib_unite_send:send_to_one(PlayerId, BinData).

%% 同步游戏线玩家帮派信息
guild_server_syn(PlayerStatus, [GuildId, GuildName, GuildPosition, GuildLevel]) ->
	GSOld = PlayerStatus#player_status.guild,
	GuildStatus = GSOld#status_guild{
        guild_id = GuildId
        ,guild_name = util:make_sure_list(GuildName)
		,guild_lv = GuildLevel
        ,guild_position = GuildPosition
    },
	%% 同步帮战表
	case GSOld#status_guild.guild_position =/= GuildPosition andalso GuildPosition =:= 1 of
		true ->
			lib_factionwar:update_factionwar_chief_id(GuildId, PlayerStatus#player_status.id);
		false ->
			skip
	end,
	PlayerStatusNew = PlayerStatus#player_status{guild = GuildStatus},
	mod_scene_agent:update(guild, PlayerStatusNew),
	case GuildId =:= 0 of
		true->
			guild_server_quit(PlayerStatus#player_status.id),
			{SceneId, OutSceneId, X, Y} = data_guild:get_guild_scene_out(),
			case PlayerStatus#player_status.scene =:= SceneId of
				false ->
					skip;
				true ->
					lib_scene:player_change_scene(PlayerStatus#player_status.id, OutSceneId, 0, X, Y,true)
			end,
			PlayerStatusNew;
		false ->
			PlayerStatusNew
	end.

%% 更新玩家退帮次数和时间
guild_server_quit(RoleId) -> 
	NowTime = util:unixtime(),
	mod_daily_dict:set_count(RoleId, 4007805, NowTime),
	mod_daily_dict:plus_count(RoleId, 4007806, 1).

%% 同步玩家的公共线信息([GuildId, GuildName, GuildPosition]) ->
updata_unite_status([PlayerId, GuildId, GuildName, GuildPosition]) ->
	 case mod_chat_agent:lookup(PlayerId) of
		[] ->
			[];
		[Player] ->
			gen_server:cast(Player#ets_unite.pid, {'guild',{'guild_member_syn', [GuildId, GuildName, GuildPosition]}})
	 end.

%% 同步玩家的聊天信息
update_ets_unite(UniteStatus) ->
	 case mod_chat_agent:lookup( UniteStatus#unite_status.id) of
		[] ->
			[];
		[Player] ->
			mod_chat_agent:insert(Player#ets_unite{
	            guild_id = UniteStatus#unite_status.guild_id,
	            guild_name = util:make_sure_list(UniteStatus#unite_status.guild_name),
	            guild_position = UniteStatus#unite_status.guild_position
	        })
	 end.

%%    统计一个列表里面相同元素的个数
count(L) -> count(L, []).
count([], L2) -> lists:reverse(lists:keysort(2, L2));
count(L, L2) -> 
    [H|T] = L,
    NewL2 = case lists:keyfind(H, 1, L2) of
        false -> L2 ++ [{H, 1}];
        {H, Num} -> lists:keyreplace(H, 1, L2, {H, Num + 1})
    end,
    count(T, NewL2).

%% -----------------------------------------------------------------
%% 增加建设度,供给帮派战使用
%% -----------------------------------------------------------------
factionwer_add_contribution(GuildId, ContributionAdd) ->
	case get_guild(GuildId) of
		Guild when is_record(Guild, ets_guild) ->
			% 计算增加的帮派建设
		    ContributionTotal = Guild#ets_guild.contribution + ContributionAdd,
		    % 处理帮派升级
		    [NewLevel, NewMemberCapacity, NewContribution, NewContributionThreshold, NewContributionDaily] = calc_new_level(Guild#ets_guild.level, ContributionTotal, Guild#ets_guild.member_capacity, Guild#ets_guild.level),
		    % 更新帮派表
		    if  % (1) 帮派升级
		        NewLevel > Guild#ets_guild.level ->
					lib_guild:get_guild_award(Guild#ets_guild.level, NewLevel, GuildId),
		            Data1 = [NewLevel, NewContribution, Guild#ets_guild.id],
		            SQL1  = io_lib:format(?SQL_GUILD_UPDATE_GRADE, Data1),
		            db:execute(SQL1),
		            % 更新缓存
		            GuildNew = Guild#ets_guild{level                  = NewLevel,
		                                       member_capacity        = NewMemberCapacity,
		                                       contribution           = NewContribution,
		                                       contribution_threshold = NewContributionThreshold,
		                                       contribution_daily     = NewContributionDaily},
		           lib_guild:update_guild(GuildNew),
		           % 通知成员
		           lib_guild:send_guild(Guild#ets_guild.id, 'guild_upgrade', [Guild#ets_guild.id, Guild#ets_guild.name, Guild#ets_guild.level, NewLevel]);
		        % (2) 帮派没有升级
		        true ->
		            Data1 = [ContributionTotal, Guild#ets_guild.id],
		            SQL1  = io_lib:format(?SQL_GUILD_UPDATE_CONTRIBUTION, Data1),
		            db:execute(SQL1),
		            % 更新缓存
		            GuildNew = Guild#ets_guild{contribution           = NewContribution},
		            lib_guild:update_guild(GuildNew)
		    end;
		_R ->
			skip
	end.

%% -----------------------------------------------------------------
%% 帮派退帮后的操作检查
%% @param OptRoleId   操作者ID
%% @param CheckRoleId 被检查者ID
%% -----------------------------------------------------------------
guild_today_check(OptRoleId, CheckRoleId)->
	GuildQuitNum = mod_daily_dict:get_count(CheckRoleId, 4007806),
	case GuildQuitNum >= 1 of
		true->
			{ok, BinData} = case OptRoleId =:= CheckRoleId of
								true ->
									pt_400:write(40098, [1]);
								false ->
									pt_400:write(40098, [2])
							end,
		    lib_unite_send:send_to_one(OptRoleId, BinData),
			false;
		false ->
			true
	end.

guild_today_times(OptRoleId, BeOptRoleId)->
	GuildQuitNum = mod_daily_dict:get_count(BeOptRoleId, 4007806),
	case GuildQuitNum >= 10 of
		true->
			{ok, BinData} = case OptRoleId =:= BeOptRoleId of
								true ->
									pt_400:write(40098, [3]);
								false ->
									pt_400:write(40098, [4])
							end,
		    lib_unite_send:send_to_one(OptRoleId, BinData),
			false;
		false ->
			true
	end.

get_guild_award(Level, NewLevel, GuildId) ->
	%% 处理开服7天活动之帮派升4级
	case Level < 4 andalso NewLevel >= 4 of
		true ->
			case db:get_all(io_lib:format(?SQL_GUILD_UPGRADE_LOG, [GuildId])) of
				[] ->
					%lib_rank_activity:get_guild_award(GuildId),
                    lib_uc:switch(guild_lv_4_send_gold, [GuildId]);
				List ->
					Bool = lists:any(fun([PLevel]) -> 
						PLevel == 4
					end, List),
					case Bool of
						true ->
							skip;
						_ ->
                            lib_uc:switch(guild_lv_4_send_gold, [GuildId])
							%lib_rank_activity:get_guild_award(GuildId)
					end
			end;
		_ ->
			skip
	end,
	%% 升级日志
	log:log_guild_upgrade(GuildId, NewLevel, Level).

get_daily_times(RoleId)->
	case lib_guild_base:get_guild_member_by_player_id(RoleId) of
		GuildMember when is_record(GuildMember, ets_guild_member) ->
			TodayDonate = mod_daily_dict:get_count(RoleId, 3700002),
			AllNum = if
				TodayDonate >= 300 -> 6;
				TodayDonate >= 200 -> 5;
				TodayDonate >= 100 -> 4;
				TodayDonate >= 50 -> 3;
				TodayDonate >= 30 -> 2;
				TodayDonate >= 10 -> 1;
				true -> 1
			end,
			case mod_daily_dict:get_special_info({RoleId, fuli}) of
				undefined ->
					[1, 0];
				OldInfo ->
					NewListX = lists:filter(fun({_A, _B, C}) ->
									  C =:= 0 
								 end, OldInfo),
					DDD = erlang:length(NewListX), 
					case DDD >= AllNum of
						true ->
							[AllNum, AllNum];
						false ->
							[AllNum, DDD]
					end
			end;
		_ ->
			[1, 0]
	end.

get_guild_lv_only(GuildId)->
	case gen_server:call(mod_guild, {get_guild_level, GuildId}) of
        Res when erlang:is_integer(Res) ->
            Res;
        _R ->
			SQLGN = io_lib:format(?SQL_GET_GUILD_LV, [GuildId]),
			case db:get_one(SQLGN) of
				null -> 	%% 需要修正
					0;
				_GuildLv -> %% 不需要修正
					_GuildLv
			end
    end.

gaimin_hefu(GuildId, GuildName, NewNameUp) ->
	gen_server:cast(mod_guild, {gai_ming, GuildId, GuildName, NewNameUp}).
	
%% 获取帮主ID
get_bz_id(GuildId)->
	case lib_guild_base:get_guild(GuildId) of
		D when erlang:is_record(D, ets_guild) ->
			D#ets_guild.chief_id;
		_ ->
			0
	end.
 
get_altar_times_server(GuildId, RoleId)->
	case mod_disperse:call_to_unite(lib_guild, get_altar_times, [GuildId, RoleId]) of
		[A, B] ->
			[A, B];
		_ ->
			[0, 0]
	end.

get_altar_times(GuildId, RoleId)->
	case lib_guild_base:get_guild(GuildId) of
		Guild when erlang:is_record(Guild, ets_guild) ->
			[Daily_Type_ID, _, PrayTimes, _, _, _] = data_guild:get_altar_info(Guild#ets_guild.altar_level),
			DailyPrayTimes = mod_daily_dict:get_count(RoleId, Daily_Type_ID),
			TimesAll = PrayTimes + ?MFYJCS,
			[DailyPrayTimes, TimesAll];
		_ ->
			[0, 0]
	end.

%% 后台使用,修复玩家缓存数据
fix_guild_member_s(PlayerId) ->
	SQL  = io_lib:format("SELECT material FROM guild_member where id = ~p", [PlayerId]),
    case db:get_one(SQL) of
		null ->
			error;
		Met ->
			mod_disperse:cast_to_unite(lib_guild, fix_guild_member_u, [Met, PlayerId]),
			ok
	end.

fix_guild_member_u(Met, PlayerId) ->
	case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
        GuildMember when is_record(GuildMember, ets_guild_member) ->
            GuildMemberNew = GuildMember#ets_guild_member{material = Met},
            lib_guild_base:update_guild_member(GuildMemberNew);
        _ ->
			ok
    end.

%% 同步帮派玩家头像数据
fix_guild_member_image_s(PlayerId, Image) ->
	mod_disperse:cast_to_unite(lib_guild, fix_guild_member_image_u, [PlayerId, Image]).

fix_guild_member_image_u(PlayerId, Image) ->
	case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
        GuildMember when is_record(GuildMember, ets_guild_member) ->
            GuildMemberNew = GuildMember#ets_guild_member{image = Image},
            lib_guild_base:update_guild_member(GuildMemberNew);
        _ ->
			ok
    end.

%% 自动进入帮派
auto_join(TargetPlayerId, GuildId, PlayerInfo, GuildName) ->
    case lib_guild:guild_today_times(TargetPlayerId, TargetPlayerId) of
        true ->
            EtsGuild = lib_guild:get_guild(GuildId),    
            case EtsGuild=/=[] andalso PlayerInfo=/=[] of
                false -> skip;
                true ->
                    Gs = #status_guild{
                        guild_id =  GuildId,
                        guild_name = GuildName,
                        guild_lv = EtsGuild#ets_guild.level
                    },                  
                    Data_Return = mod_guild:guild_member_contrl_others([], EtsGuild, Gs, [40005, PlayerInfo, [1]]),
                    [Result, [PlayerName, GuildPosition, PlayerCarrer, PlayerSex, PlayerImage, PlayerLv]] = case length(Data_Return) of
                        1->
                            [D] = Data_Return,
                            [D,[0,0,0,0,0,0]];
                        2->
                            Data_Return;
                        _->
                            [0,[0,0,0,0,0,0]]
                    end,
                    case Result == 1 of
                        true ->
                            %% 完成加入帮派任务
                            lib_task:finish_join_guild_task(TargetPlayerId),
                            %% 记录帮派事件
                            lib_guild:log_guild_event(GuildId, 1, [TargetPlayerId, PlayerName, GuildPosition]),
                            %% 广播帮派成员
                            lib_guild:send_guild_except_one(GuildId, TargetPlayerId, 'guild_new_member'
                                , [TargetPlayerId, PlayerName, GuildId
                                    , GuildName
                                    , GuildPosition
                                    , 0
                                    , PlayerCarrer, PlayerSex, PlayerImage, PlayerLv]),
                            %% 邮件通知给被审批人
                            mod_guild:send_guild_mail(guild_new_member, [TargetPlayerId
                                                                , PlayerName
                                                                , GuildId
                                                                , GuildName]),
                            %% 触发成就
                            StatusAchieve = lib_player:get_player_info(TargetPlayerId, achieve),
                            lib_player_unite:trigger_achieve(TargetPlayerId, trigger_social, [StatusAchieve, TargetPlayerId, 2, 0, 1]),
                            %% 目标202:创建或加入帮派
                            StatusTarget = lib_player:get_player_info(TargetPlayerId, status_target),
                            lib_player_unite:trigger_target(TargetPlayerId, [StatusTarget, TargetPlayerId, 202, []]),
                            %% 同步 其他玩家的帮派信息
                            lib_guild:guild_other_syn([TargetPlayerId, GuildId, GuildName, GuildPosition]);
                        false -> skip
                    end
            end;                        
        false -> ok
    end.

%% 帮派buff处理
%% change_scene_handler(Status, EnterSceneId, LevelSceneId) ->
%% 	GaBuffScene = Status#player_status.guild#status_guild.ga_buff_scene,
%% 	if
%% 		EnterSceneId =:= GaBuffScene ->
%% 			%% 进入场景_加buff
%% 			Status;
%% 		LevelSceneId =:= GaBuffScene ->
%% 			%% 离开场景_移除buff
%% 			Status;
%% 		true ->
%% 			Status
%% 	end.
%% ------------------------------- E N D --------------------------------------- 
