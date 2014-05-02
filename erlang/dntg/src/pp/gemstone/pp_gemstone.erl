%%%------------------------------------
%%% module  : pp_gemstone
%%% @Author : huangwenjie
%%% @Email  : 1015099316@qq.com
%%% @Create : 2014.2.19
%%% @Description: 宝石系统
%%%-------------------------------------
-module(pp_gemstone).
-include("server.hrl").
-include("common.hrl").
-include("gemstone.hrl").
-compile(export_all).
-export([handle/3]).

%% 获取界面信息
handle(16600, PS, _) -> 
    GemStonesInfo = lib_gemstone:parse_gemstone_list(PS),
    {ok, BinData} = pt_166:write(16600, GemStonesInfo),
    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
    {ok, PS};

%% 获取单个宝石栏的信息
handle(16601, PS, [EquipPos, GemPos]) -> 
    GemStonesInfo = lib_gemstone:parse_gemstone_one(PS, EquipPos, GemPos),
    {ok, BinData} = pt_166:write(16601, GemStonesInfo),
    lib_server_send:send_to_sid(PS#player_status.sid, BinData),
    {ok, PS};

%% 激活宝石栏位置
handle(16602, PS, [EquipPos, GemPos]) -> 
    Result = lib_gemstone:active_gemstone(PS, EquipPos, GemPos),  
    case Result of 
        {fail, Error} -> 
            {ok, BinData} = pt_166:write(16602, [Error, EquipPos, GemPos]),
            lib_server_send:send_to_sid(PS#player_status.sid, BinData);
        {ok, NewPS} -> 
            NewPS2 = lib_gemstone:count_player_attr(NewPS),
            lib_player:send_attribute_change_notify(NewPS2, 1),
            {ok, BinData} = pt_166:write(16602, [1, EquipPos, GemPos]),
            lib_server_send:send_to_sid(NewPS#player_status.sid, BinData),
            handle(16601, NewPS2, [EquipPos, GemPos]),
            %% 目标:激活多少个宝石栏
            GemstoneList = mod_gemstone:get_all(NewPS2#player_status.gem_pid, NewPS2#player_status.id),
            Length =length(GemstoneList),
            mod_target:trigger(NewPS2#player_status.status_target, NewPS2#player_status.id, 305, Length),
            {ok, battle_hp_mp, NewPS2}
    end;

%% 宝石栏升级
handle(16603, PlayerStatus, [EquipPos, GemPos, GoodsList]) -> 
    Go = PlayerStatus#player_status.goods,
    PlayerId = PlayerStatus#player_status.id,
    GemPid = PlayerStatus#player_status.gem_pid,
    case lib_gemstone:get_one_active_gemstone(GemPid, PlayerId, EquipPos, GemPos) of 
        GemStone when is_record(GemStone, gemstone) -> 
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'gemstone_upgrade', PlayerStatus, GemStone, GoodsList}) of 
                {ok, [Res, NewPS, IsUpgrade, Exp]} -> 
                    NewPS2 = lib_gemstone:count_player_attr(NewPS),
                    lib_player:send_attribute_change_notify(NewPS2, 1),
                    lib_player:refresh_client(NewPS2#player_status.id, 2),
                    {ok, BinData} = pt_166:write(16603, [Res, IsUpgrade, Exp]),
                    lib_server_send:send_to_sid(NewPS2#player_status.sid, BinData),
                    handle(16601, NewPS2, [EquipPos, GemPos]),
                    {ok, battle_hp_mp, NewPS2};
                {'EXIT', _} -> 
                    {ok, BinData} = pt_166:write(16603, [0, 0, 0]),
                    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
            end;
        _ -> 
            {ok, BinData} = pt_166:write(16603, [3, 0, 0]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
    end;

%% 查看宝石的总属性
handle(16604, PlayerStatus, [PlayerId]) ->
    case PlayerStatus#player_status.id =:= PlayerId of 
        true ->
            [Result, Data] = lib_gemstone:get_gemstone_attr_all(PlayerStatus, PlayerStatus#player_status.sid),
            {ok, BinData} = pt_166:write(16604, [Result, Data]),
            lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
        false ->
            case lib_player:get_player_info(PlayerId, pid) of 
                false ->
                    {ok, BinData} = pt_166:write(16604, [0, []]),
                    lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
                Pid ->
                    gen_server:cast(Pid, {'show_gemstone_all_attr', PlayerStatus#player_status.sid}),
                    ok
            end
    end;

%% 错误处理
handle(Cmd, Status, _Data) ->
    util:errlog("pp_gemstone no match, Cmd = ~p~n", [Cmd]),
    {ok, Status}.







