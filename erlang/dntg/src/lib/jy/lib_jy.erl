%%%-----------------------------------
%%% @Module  : lib_jy
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.06.15
%%% @Description: 景阳累积
%%%-----------------------------------
-module(lib_jy).
-export([
        add_log/1,
        cale_con_exp/2,
        get_con_exp/1,
        get_con_exp_gold/1,
        get_con_exp_goods/1
        ]).
-include("common.hrl").
%-include("record.hrl").
-include("server.hrl").
-define(CONTIME, 86400). %一天

%% 记录景阳日志
%% Id:玩家id
add_log(Id) ->
    T2 = util:unixdate(),
    T1 = get_db_time(Id),
    if 
        T1 =/=0 andalso T2 - T1 > ?CONTIME -> %% 时间足够获得累积经验就不覆盖了
            skip;
        true ->
            write_db_time(Id, T2) 
    end.

%% 获取数据库jy时间
%% Id:玩家id
get_db_time(Id)->
    case get("lib_jy_get_con_exp") of
        undefined->
            _T2 = case db:get_one(lists:concat(["select `time` from `log_jy` where role_id = ",Id," limit 1"])) of
                null ->
                    0;
                _T1 ->
                    _T1
            end,
            put("lib_jy_get_con_exp", _T2),
            _T2;
        _T3 ->
            _T3
    end.

%% 记录最新景阳时间
write_db_time(Id, T) ->
    db:execute(lists:concat(["replace into `log_jy` (`role_id`, `time`) values (",Id,",",T,")"])),
    put("lib_jy_get_con_exp", T).

%% 计算景阳副本所得经验
%% Id:玩家id
cale_con_exp(Id, Lv) ->
    T2 = util:unixdate(),
    T1 = case get_db_time(Id) of
        0 ->
            T2;
        T ->
            T
    end,

    if 
        T2 - T1 > ?CONTIME ->
            round(math:pow(Lv,3)*10.08);
        true ->
            0
    end.

%% 获取景阳副本所得经验
%% Id:玩家id
%% 返回player_status
get_con_exp(Status) ->
    Exp = cale_con_exp(Status#player_status.id, Status#player_status.lv),
    %% 看今天是否已经进入了副本
    Count = mod_daily:get_count(Status#player_status.id, 630),
    T = case Count > 0 of
        true ->
            util:unixdate();
        false ->
            util:unixdate()-?CONTIME
    end,
    case Exp > 0 of
        true ->
            write_db_time(Status#player_status.id, T),
            lib_player:add_exp(Status, Exp);
        false ->
            Status
    end.

get_con_exp_gold(Status) ->
    Exp = trunc(cale_con_exp(Status#player_status.id, Status#player_status.lv) / 0.6),
    NeedGold = trunc((Exp) / 50000),
    case Status#player_status.gold < NeedGold of
        true ->
            {0, Status};
        false ->
            %扣钱
            NewStatus = lib_goods_util:cost_money(Status, NeedGold, gold),
            log:log_consume(outline_jy, gold, Status, NewStatus, ""),
            %加景阳
            %% 看今天是否已经进入了副本
            Count = mod_daily:get_count(Status#player_status.id, 630),
            T = case Count > 0 of
                true ->
                    util:unixdate();
                false ->
                    util:unixdate()-?CONTIME
            end,
            case Exp > 0 of
                true ->
                    write_db_time(NewStatus#player_status.id, T),
                    NewStatus1 =  lib_player:add_exp(NewStatus, trunc(Exp)),
                    {1, NewStatus1 };
                false ->
                    {0, Status}
            end
    end.


get_con_exp_goods(Player_Status) ->
    Exp = trunc(cale_con_exp(Player_Status#player_status.id, Player_Status#player_status.lv) / 0.6),
    NeedGold = trunc((Exp) / 50000),
    Goodsid  = case Player_Status#player_status.lv >= 50 of true -> 672002; _ -> 672001 end,
    GoodsNum = util:ceil(NeedGold/10),
    Go = Player_Status#player_status.goods,
    R = gen_server:call(Go#status_goods.goods_pid, {'delete_more', Goodsid, GoodsNum}),
    case R of
        1 ->
            %% 看今天是否已经进入了副本
            Count = mod_daily:get_count(Player_Status#player_status.id, 630),
            T = case Count > 0 of
                true ->
                    util:unixdate();
                false ->
                    util:unixdate()-?CONTIME
            end,
            case Exp > 0 of
                true ->
                    write_db_time(Player_Status#player_status.id, T),
                    NewStatus1 =  lib_player:add_exp(Player_Status, trunc(Exp)),
                    {1, NewStatus1 };
                false ->
                    {0, Player_Status}
            end;
        _ ->
            {2, Player_Status}
    end.






