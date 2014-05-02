%%%------------------------------------
%%% @Module  : pp_vip_dun
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.02.25
%%% @Description: VIP副本
%%%------------------------------------

-module(pp_vip_dun).
-export([handle/3]).
-include("server.hrl").
-include("common.hrl").

%% 进入vip副本
handle(45101, PlayerStatus, _) ->
    case lib_player:is_transferable(PlayerStatus) of
        %% 失败，当前状态不允许传送
        false ->
            Res = 2,
            Str = data_vip_dun_text:get_vip_dun_error(5);
        true ->
            case mod_daily:get_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 45101) > 0 of
                false ->
                    MinLv = data_vip_dun:get_vip_dun_config(min_lv),
                    case PlayerStatus#player_status.lv >= MinLv of
                        true ->
                            case lists:member(PlayerStatus#player_status.vip#status_vip.vip_type, [1, 2, 3]) of
                                %% 正在进入VIP副本
                                true ->
                                    Res = 1,
                                    Str = data_vip_dun_text:get_vip_dun_error(0),
                                    mod_vip_dun:enter_vip_dun(PlayerStatus#player_status.id, PlayerStatus#player_status.lv, PlayerStatus#player_status.vip),
                                    mod_daily:increment(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, 45101),
                                    VipDunScene = data_vip_dun:get_vip_dun_config(scene_id),
                                    mod_daily:set_count(PlayerStatus#player_status.dailypid, PlayerStatus#player_status.id, VipDunScene, 1);
                                %% 失败，VIP半年卡、VIP月卡、VIP周卡才能进行挑战
                                false ->
                                    Res = 2,
                                    Str = data_vip_dun_text:get_vip_dun_error(3)
                            end;
                        %% 失败，35级以上玩家才能进行挑战
                        false ->
                            Res = 2,
                            Str = io_lib:format(data_vip_dun_text:get_vip_dun_error(2), [MinLv])
                    end;
                %% 失败，今天挑战次数已满
                true ->
                    Res = 2,
                    Str = data_vip_dun_text:get_vip_dun_error(1)
            end
    end,
    {ok, BinData} = pt_451:write(45101, [Res, Str]),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
    ok;

%% 退出vip副本
handle(45102, PlayerStatus, _) ->
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    case PlayerStatus#player_status.scene =:= SceneId of
        true ->
            [LeaveScene, LeaveX, LeaveY] = data_vip_dun:get_vip_dun_config(leave),
            NewPlayerStatus = lib_scene:change_scene(PlayerStatus, LeaveScene, 0, LeaveX, LeaveY, false),
            %NewPlayerStatus = PlayerStatus,
            %lib_scene:player_change_scene(PlayerStatus#player_status.id, LeaveScene, 0, LeaveX, LeaveY, false),
            mod_vip_dun:player_logout(PlayerStatus#player_status.id),
            Res = 1,
            %% 正在退出VIP副本
            Str = data_vip_dun_text:get_vip_dun_error(4),
            {ok, BinData} = pt_451:write(45102, [Res, Str]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData),
            {ok, NewPlayerStatus};
        false ->
            skip
    end;

%% 副本信息
handle(45103, PlayerStatus, _) ->
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    case PlayerStatus#player_status.scene =:= SceneId of
        true ->
            mod_vip_dun:get_vip_dun_info(PlayerStatus#player_status.id);
        false ->
            skip
    end,
	ok;

%% 投掷骰子
handle(45105, PlayerStatus, _) ->
	SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    case PlayerStatus#player_status.scene =:= SceneId of
        true ->
            mod_vip_dun:flag(PlayerStatus#player_status.id, PlayerStatus#player_status.lv, PlayerStatus#player_status.scene, PlayerStatus#player_status.copy_id, 0);
        false ->
            skip
    end,
	ok;

%% 杀怪用时
handle(45106, PlayerStatus, _) ->
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    case PlayerStatus#player_status.scene =:= SceneId of
        true ->
            mod_vip_dun:get_mon_time(PlayerStatus#player_status.id);
        false ->
            skip
    end,
	ok;

%% 获取题目
handle(45107, PlayerStatus, _) ->
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    case PlayerStatus#player_status.scene =:= SceneId of
        true ->
            mod_vip_dun:get_questions(PlayerStatus#player_status.id);
        false ->
            skip
    end,
	ok;

%% 回答题目
handle(45108, PlayerStatus, [Answer]) ->
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    case PlayerStatus#player_status.scene =:= SceneId of
        true ->
            mod_vip_dun:answer_question(PlayerStatus, Answer);
        false ->
            skip
    end,
	ok;

%% 选择正确答案
handle(45109, PlayerStatus, _) ->
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    case PlayerStatus#player_status.scene =:= SceneId of
        true ->
            mod_vip_dun:select_right_answer(PlayerStatus);
        false ->
            skip
    end,
	ok;

%% 去掉2个错误答题
handle(45110, PlayerStatus, _) ->
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    case PlayerStatus#player_status.scene =:= SceneId of
        true ->
            mod_vip_dun:clear_wrong_answer(PlayerStatus#player_status.id);
        false ->
            skip
    end,
	ok;

%% 猜拳
handle(45111, PlayerStatus, [Answer]) ->
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    case PlayerStatus#player_status.scene =:= SceneId of
        true ->
            mod_vip_dun:guessing_game(PlayerStatus, Answer);
        false ->
            skip
    end,
	ok;

%% 购买骰子次数
handle(45113, PlayerStatus, _) ->
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    case PlayerStatus#player_status.scene =:= SceneId of
        true ->
            mod_vip_dun:check_buy_num(PlayerStatus#player_status.id);
        false ->
            skip
    end,
	ok;

%% 赌神(压大小)
handle(45115, PlayerStatus, [Ans]) ->
    SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    case PlayerStatus#player_status.scene =:= SceneId of
        true ->
            mod_vip_dun:guessing_point(PlayerStatus, Ans);
        false ->
            skip
    end,
	ok;

%% 圈数加一(成功则传送玩家至第一格，失败则不做处理)
handle(45116, _PlayerStatus, _) ->
    %SceneId = data_vip_dun:get_vip_dun_config(scene_id),
    %case PlayerStatus#player_status.scene =:= SceneId of
    %    true ->
    %        mod_vip_dun:add_round(PlayerStatus#player_status.id);
    %    false ->
    %        skip
    %end,
	ok;

handle(_Cmd, _LogicStatus, _Data) ->
    ?DEBUG("pp_vip_dun no match", []),
    {error, "pp_vip_dun no match"}.
