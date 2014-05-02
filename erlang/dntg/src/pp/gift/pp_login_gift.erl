%%------------------------------------------------------------------------------
%% @Module  : pp_login_gift
%% @Author  : HHL
%% @Email   : 
%% @Created : 2014.3.7
%% @Description: 登录签到奖励功能
%%------------------------------------------------------------------------------
-module(pp_login_gift).
-export([handle/3]).
-include("gift.hrl").
-include("server.hrl").
-include("login_count.hrl").


%% 查询可领取连续登录奖励
%%  ContinuousDays:当前连续登录天数
%%  NoLoginDays: 此前未登录天数
%%  IsCharged: 是否已充值（0否/1是）
handle(31200, PlayerStatus, _) ->
    case lib_login_gift:query_all_gift_info(PlayerStatus) of
        {ok, ContinuousDays, NoLoginDays, IsCharged, ContinuousGiftInfo, NoLoginGiftInfo} ->
            {ok, BinData} = pt_312:write(31200, [1, ContinuousDays, NoLoginDays, IsCharged, ContinuousGiftInfo, NoLoginGiftInfo]);
        _ ->
            {ok, BinData} = pt_312:write(31200, [0, 0, 0, 0, [], []])
    end,
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);

%% 领取连续登录奖励
handle(31201, PlayerStatus, [Type, Days]) ->
    case lib_login_gift:get_continuous_login_gift(PlayerStatus, Days, Type) of
        {ok, NewPlayerStatus, GiveList} ->
            {ok, BinData} = pt_312:write(31201, [Type, Days, 1]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            lib_login_gift:notice_get_gift(NewPlayerStatus, GiveList),
            {ok, NewPlayerStatus};
        {error, ErrorCode} ->
            {ok, BinData} = pt_312:write(31201, [Type, Days, ErrorCode]),
            lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);
        _ ->
            skip
    end;

%% 重置连续登录天数
handle(31202, PlayerStatus, _) ->
    {result, Result} = lib_login_gift:reset_login_days(PlayerStatus),
    {ok, BinData} = pt_312:write(31202, Result),
    lib_server_send:send_one(PlayerStatus#player_status.socket, BinData);


%% 每日福利列表
handle(31204, PS, _) ->
    RoleId = PS#player_status.id,
    DailyPid = PS#player_status.dailypid,
    [TotalNum, NowNum] = case mod_disperse:call_to_unite(lib_guild, get_daily_times, [RoleId]) of
							 [A, B] -> [A, B];
							 _ -> [1, 0]
						 end,
    [YaoNowNum, _YaoTotalNum] = lib_guild:get_altar_times_server(PS#player_status.guild#status_guild.guild_id, RoleId),
    YaoTotalNum = case _YaoTotalNum of
                     0 -> 1;
                     _ -> _YaoTotalNum
                  end,
    List = [
        {1, 
            mod_daily:get_count(DailyPid, RoleId, 1500) + 
            mod_daily:get_count(DailyPid, RoleId, 1501) + 
            mod_daily:get_count(DailyPid, RoleId, 1502), 0}, 
        {2, mod_daily_dict:get_count(RoleId, 5000004), 0},
        {3, mod_daily_dict:get_count(RoleId, 5000000), 0},
        {4, mod_daily_dict:get_count(RoleId, 5000006), 0}, 
        {5, NowNum, TotalNum},
        {6, mod_daily:get_count(DailyPid, RoleId, 8889), data_shake_money:get_max(PS#player_status.lv)},
        {7, YaoNowNum, YaoTotalNum},
        {8, mod_daily:get_count(DailyPid, RoleId, 1301) + 
            mod_daily:get_count(DailyPid, RoleId, 1302) + 
            mod_daily:get_count(DailyPid, RoleId, 1303) + 
            mod_daily:get_count(DailyPid, RoleId, 1304), 0},
        {9, mod_daily:get_count(DailyPid, RoleId, 10007), 0}],
    {ok, BinData} = pt_312:write(31204, [List]),
    lib_server_send:send_one(PS#player_status.socket, BinData);


%% 累积登录信息
handle(31205, PS, _) ->
    List = lib_login_gift:get_cumulative_login_info(PS#player_status.id, PS#player_status.dailypid, PS#player_status.vip#status_vip.vip_type),
    VipType = PS#player_status.vip#status_vip.vip_type,
    {ok, BinData} = pt_312:write(31205, [VipType | List]),
    lib_server_send:send_one(PS#player_status.socket, BinData);


%% 累积签到
%% Type 1：签到; 2:单日补签; 3:一键补签
handle(31206, PS, [Type, Day, Count]) ->
    RoleId = PS#player_status.id,
    VipType = PS#player_status.vip#status_vip.vip_type,
    case Type=:=1 orelse Type=:=2 orelse Type=:=3 of
        true ->
            if
                Type=:=1 orelse Type=:=2 ->
                    Result =  lib_login_gift:sign_days_op(RoleId, VipType, Type, Day, 1);
                true ->
                    Result =  lib_login_gift:sign_days_op(RoleId, VipType, Type, 0, Count)
            end,
            case Result of
                {ok, BinData} -> 
                    lib_server_send:send_one(PS#player_status.socket, BinData),
                    handle(31205, PS, []);
                {fail, BinData} ->
                     lib_server_send:send_one(PS#player_status.socket, BinData)
            end;
        _ ->
            {ok, BinData} = pt_312:write(31206, [6]),
            lib_server_send:send_one(PS#player_status.socket, BinData)
    end;


%%　签到物品领取
handle(31207, PS, [SignCount, GoodId, Type]) ->
    RoleId = PS#player_status.id,
    VipType = PS#player_status.vip#status_vip.vip_type,
    GoodPid = PS#player_status.goods#status_goods.goods_pid,
    if
        Type =:= 2  andalso VipType < 1 ->
            {ok, BinData} = pt_312:write(31207, [2, []]),
            lib_server_send:send_one(PS#player_status.socket, BinData);
        true ->
            [Code, SignCountGoods] = lib_login_gift:get_sign_goods(RoleId, GoodPid, SignCount, GoodId, Type),
            {ok, BinData} = pt_312:write(31207, [Code, SignCountGoods]),
            lib_server_send:send_one(PS#player_status.socket, BinData)
    end;

%% 翻牌信息
handle(31208, PS, _) ->
    case PS#player_status.lv < 25 of
        true ->
            {ok, BinData} = pt_312:write(31208, [4, []]),
            lib_server_send:send_to_sid(PS#player_status.sid, BinData);     
        false ->
            TotalDropCount = lib_login_gift:get_total_drop_count(PS#player_status.id),
            UsedDropCount = mod_daily:get_count(PS#player_status.dailypid, PS#player_status.id, 7751),
            DropCountLess = TotalDropCount - UsedDropCount,
            
            if
                DropCountLess =< 0 ->
                    {ok, BinData} = pt_312:write(31208, [0, []]);
                DropCountLess >= 1 andalso DropCountLess =< 3 ->
                    DropGoods = case lib_login_gift:get_drop_goods(PS#player_status.lv) of
                                    [] -> [];
                                    DropAny -> DropAny
                                end, 
                    if
                        DropGoods =:= [] ->
                            {ok, BinData} = pt_312:write(31208, [5, []]);
                        true ->
                            %% 清理随机物品缓存
                            erase(?FAN_PAI_KEY(PS#player_status.id)),
                            put(?FAN_PAI_KEY(PS#player_status.id), DropGoods),
                            {ok, BinData} = pt_312:write(31208, [DropCountLess, DropGoods])
                    end;
                true ->
                    {ok, BinData} = pt_312:write(31208, [5, []])
            end,
            lib_server_send:send_to_sid(PS#player_status.sid, BinData)
    end;

%% 周连续登录翻牌
handle(31209, PS, _) ->
    case lib_login_gift:get_drop_award(PS) of
        {fail, Error} ->
            {ok, BinData} = pt_312:write(31209, [Error, 0, 0]),
            lib_server_send:send_to_sid(PS#player_status.sid, BinData);     
        {ok, GoodsTypeId, Num} ->
            %% io:format("~p ~p GoodsTypeId:~p, Num:~p~n", [?MODULE, ?LINE, GoodsTypeId, Num]),
            {ok, BinData} = pt_312:write(31209, [1, GoodsTypeId, Num]),
            lib_server_send:send_to_sid(PS#player_status.sid, BinData),
            handle(31208, PS, [])
    end;

%% 测试方便修改数据
handle(31299, PS, cl) ->
    lib_login_gift:tt(PS#player_status.id);

handle(_Cmd, _PS, _R) ->
    util:errlog("~p ~p _Cmd:~p, _R:~p~n", [?MODULE, ?LINE, _Cmd, _R]).



