%%%--------------------------------------
%%% @Module  : pp_city_war
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.13
%%% @Description:  城战
%%%--------------------------------------

-module(pp_city_war).
-compile(export_all).
-include("common.hrl").
-include("unite.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("goods.hrl").

%% 图标0
handle(64100, UniteStatus, _) ->
    %% cast处理
    catch mod_city_war:picture0(UniteStatus);

%% 图标1
handle(64101, UniteStatus, _) ->
    %% cast处理
    catch mod_city_war:picture1(UniteStatus);

%% 图标2
handle(64102, UniteStatus, _) ->
    %% cast处理
    catch mod_city_war:picture2(UniteStatus);

%% 报名信息
handle(64103, UniteStatus, _) ->
    %% cast处理
    catch mod_city_war:get_apply_info(UniteStatus);

%% 援助/取消申请/撤兵
handle(64104, UniteStatus, [AidTarget]) ->
    %% 数据检验
    case lists:member(AidTarget, [1, 2]) of
        true ->
            case lists:member(UniteStatus#unite_status.guild_position, [1, 2]) of
                true ->
                    %% cast处理
                    catch mod_city_war:aid_or_cancel([UniteStatus, AidTarget]);
                %% 失败，只有帮主或副帮主才能进行该操作
                false ->
                    Res = 2,
                    Str = data_city_war_text:get_city_war_error_tips(6),
                    {ok, BinData} = pt_641:write(64104, [Res, Str]),
                    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData)
            end;
        false ->
            skip
    end;

%% 获取审批信息
handle(64105, UniteStatus, [Type]) ->
    %% 数据验证
    case lists:member(Type, [1, 2]) of
        true ->
            case lists:member(UniteStatus#unite_status.guild_position, [1, 2]) of
                true ->
                    %% cast处理
                    catch mod_city_war:get_approval_info([UniteStatus, Type]);
                %% 失败，只有帮主或副帮主才能进行该操作
                false ->
                    Res = 2,
                    Str = data_city_war_text:get_city_war_error_tips(6),
                    ApprovalInfoList = [],
                    {ok, BinData} = pt_641:write(64105, [Res, Str, ApprovalInfoList]),
                    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData)
            end;
        false ->
            skip
    end;

%% 审批申请信息
handle(64106, UniteStatus, [GuildId, Answer]) ->
    %% 数据验证
    case GuildId > 0 andalso lists:member(Answer, [1, 2, 3]) of
        true ->
            case lists:member(UniteStatus#unite_status.guild_position, [1, 2]) of
                true ->
                    %% cast处理
                    catch mod_city_war:approval_apply([UniteStatus, GuildId, Answer]);
                %% 失败，只有帮主或副帮主才能进行该操作
                false -> 
                    Res = 2,
                    Str = data_city_war_text:get_city_war_error_tips(6),
                    {ok, BinData} = pt_641:write(64106, [Res, Str]),
                    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData)
            end;
        false ->
            skip
    end;

%% 获取抢夺信息
handle(64107, UniteStatus, _) ->
    %% cast处理
    catch mod_city_war:get_seize_info(UniteStatus);

%% 捐献铜币
handle(64108, PlayerStatus, [Num]) ->
    %% 数据验证
    case Num > 0 of
        true ->
            case Num < 50000 of
                %% 捐献必须大于50000铜币
                true -> 
                    Res = 2,
                    Str = data_city_war_text:get_city_war_error_tips(46),
                    NewPlayerStatus = PlayerStatus;
                false ->
                    %% 是否为帮主或副帮主
                    case lists:member(PlayerStatus#player_status.guild#status_guild.guild_position, [1, 2]) of
                        true ->
                            %% 帮派等级是否大于等于2级
                            case PlayerStatus#player_status.guild#status_guild.guild_lv >= 2 of
                                true ->
                                    [NewPlayerStatus, Res, Str] = case mod_city_war:donate_coin([PlayerStatus, Num]) of
                                        {ok, _BackInfo} -> _BackInfo;
                                        _ -> [PlayerStatus, 2, data_city_war_text:get_city_war_error_tips(1)]
                                    end,
                                    lib_player:refresh_client(PlayerStatus#player_status.id, 2);
                                %% 失败，帮派等级大于或等于2级才能抢夺进攻权
                                false ->
                                    Res = 2,
                                    Str = data_city_war_text:get_city_war_error_tips(42),
                                    NewPlayerStatus = PlayerStatus
                            end;
                        %% 失败，只有帮主或副帮主才能进行该操作
                        false ->
                            Res = 2,
                            Str = data_city_war_text:get_city_war_error_tips(6),
                            NewPlayerStatus = PlayerStatus
                    end
            end,
            {ok, BinData} = pt_641:write(64108, [Res, Str]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        false ->
            NewPlayerStatus = PlayerStatus
    end,
    lib_player:refresh_client(PlayerStatus#player_status.id, 2),
    {ok, NewPlayerStatus};

%% 进入/退出活动
handle(64109, UniteStatus, [Type]) ->
    case Type of
        %% 进入
        1 ->
            case UniteStatus#unite_status.guild_id of
                %% 失败，未加入任务帮派
                0 ->
                    Str = data_city_war_text:get_city_war_error_tips(19),
                    {ok, BinData} = pt_641:write(64109, [2, Str]),
                    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData);
                _ ->
                    MinLv = data_city_war:get_city_war_config(min_lv),
                    case UniteStatus#unite_status.lv < MinLv of
                        %% 失败，等级大于35级的玩家才能进入
                        true ->
                            Str = data_city_war_text:get_city_war_error_tips(24),
                            {ok, BinData} = pt_641:write(64109, [2, Str]),
                            lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData);
                        false ->
                            %% 只有野外、普通和安全场景可进入
                            SceneType = lib_scene:get_res_type(UniteStatus#unite_status.scene),
                            case lists:member(SceneType, [?SCENE_TYPE_NORMAL, ?SCENE_TYPE_OUTSIDE, ?SCENE_TYPE_SAFE]) of
                                true ->
                                    case lib_player:get_player_info(UniteStatus#unite_status.id, can_transferable) of
                                        true ->
                                            mod_city_war:enter_war(UniteStatus);
                                        %% 失败，当前状态不允许传送进入
                                        _ ->
                                            Str = data_city_war_text:get_city_war_error_tips(40),
                                            {ok, BinData} = pt_641:write(64109, [2, Str]),
                                            lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData)
                                    end;
                                %% 失败，该场景无法进入攻城战
                                false ->
                                    Str = data_city_war_text:get_city_war_error_tips(32),
                                    {ok, BinData} = pt_641:write(64109, [2, Str]),
                                    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData)
                            end
                    end
            end;
        %% 退出
        _ ->
            CitySceneId = data_city_war:get_city_war_config(scene_id),
            case UniteStatus#unite_status.scene =:= CitySceneId of
                true ->
                    %% 切换场景
                    lib_city_war:quit_war(UniteStatus#unite_status.id),
                    Str = data_city_war_text:get_city_war_error_tips(18),
                    {ok, BinData} = pt_641:write(64109, [1, Str]),
                    lib_unite_send:send_one(UniteStatus#unite_status.socket, BinData);
                %% 不在活动场景内
                false ->
                    skip
            end
    end;

%% 职业变换
handle(64110, UniteStatus, [Type]) ->
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    case UniteStatus#unite_status.scene of
        CityWarSceneId ->
            lib_player:update_player_info(UniteStatus#unite_status.id, [{city_war_change_career, Type}]);
        %% 不在活动场景内
        _ ->
            skip
    end;

%% 城战面板1(定时广播，客户端也可以主动申请)
handle(64111, UniteStatus, _) ->
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    case UniteStatus#unite_status.scene of
        CityWarSceneId ->
            mod_city_war:info_panel1(UniteStatus);
        _ ->
            skip
    end;

%% 城战面板2(及时更新)
handle(64112, UniteStatus, _) ->
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    case UniteStatus#unite_status.scene of
        CityWarSceneId ->
            mod_city_war:info_panel2(UniteStatus#unite_status.guild_id, UniteStatus#unite_status.id);
        _ ->
            skip
    end;

%% 放下炸弹
handle(64113, PlayerStatus, []) ->
    NewStatus = lib_city_war_battle:del_battle_status(PlayerStatus, 3),
    {ok, NewStatus};

%% 城战面板3(及时更新)
handle(64114, UniteStatus, _) ->
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    case UniteStatus#unite_status.scene of
        CityWarSceneId ->
            mod_city_war:info_panel3(UniteStatus);
        _ ->
            skip
    end;

%% 复活剩余时间
handle(64117, UniteStatus, _) ->
    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
    case UniteStatus#unite_status.scene of
        CityWarSceneId ->
            %% cast处理
            catch mod_city_war:get_next_revive_time(UniteStatus);
        _ ->
            skip
    end;

%% 领取城战经验BUFF
handle(64120, PlayerStatus, _) ->
    case PlayerStatus#player_status.guild#status_guild.is_city_war_win of
        %% 失败，只有攻城战获胜帮派的成员才能领取该BUFF
        0 ->
            Res = 2,
            Str = data_city_war_text:get_city_war_error_tips(37),
            NewPlayerStatus = PlayerStatus;
        _ ->
            [LastWeekNum, BuffState] = PlayerStatus#player_status.city_war_exp_buff,
            {_Year, NowWeekNum} = calendar:iso_week_number(),
            case LastWeekNum =:= NowWeekNum andalso BuffState =:= 1 of
                %% 失败，本周已领取
                true ->
                    Res = 2,
                    Str = data_city_war_text:get_city_war_error_tips(41),
                    NewPlayerStatus = PlayerStatus;
                false ->
                    EtsGoodsEffect = data_goods_effect:get(214401),
                    NowTime = util:unixtime(),
                    NewBuffInfo = lib_player:add_player_buff(PlayerStatus#player_status.id, EtsGoodsEffect#ets_goods_effect.buf_type, EtsGoodsEffect#ets_goods_effect.goods_id, EtsGoodsEffect#ets_goods_effect.buf_attr, EtsGoodsEffect#ets_goods_effect.buf_val, NowTime + EtsGoodsEffect#ets_goods_effect.buf_time, EtsGoodsEffect#ets_goods_effect.buf_scene),
                    buff_dict:insert_buff(NewBuffInfo),
                    lib_player:send_buff_notice(PlayerStatus, [NewBuffInfo]),
                    Res = 1,
                    Str = data_city_war_text:get_city_war_error_tips(39),
                    db:execute(io_lib:format(<<"update player_city_war set buff_week = ~p, buff_state = ~p where player_id = ~p">>, [NowWeekNum, 1, PlayerStatus#player_status.id])),
                    NewPlayerStatus = PlayerStatus#player_status{
                        city_war_exp_buff = [NowWeekNum, 1]
                    }
            end
    end,
    {ok, BinData} = pt_641:write(64120, [Res, Str]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    {ok, NewPlayerStatus};

%% 获取雕像
handle(64121, PlayerStatus, _) ->
    %% cast处理
    catch mod_city_war:get_statue(PlayerStatus#player_status.id);

%% 获胜帮派
handle(64122, PlayerStatus, _) ->
    %% cast处理
    catch mod_city_war:get_winner_guild(PlayerStatus#player_status.id);

handle(_Cmd, _LogicStatus, _Data) ->
    ?DEBUG("pp_city_war no match", []),
    {error, "pp_city_war no match"}.
