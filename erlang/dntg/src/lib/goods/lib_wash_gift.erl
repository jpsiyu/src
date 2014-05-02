%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-9-14
%% Description: 洗炼礼包
%% --------------------------------------------------------
-module(lib_wash_gift).
-compile(export_all).
-include("goods.hrl").
-include("server.hrl").

%% 洗炼活动列表
get_wash_gift_list(Id) ->
    Sql = io_lib:format(<<"select num, gift_list from wash_gift where pid = ~p">>, [Id]),
    case db:get_row(Sql) of
        [] ->
            [[], []];
        [Num, GiftList] ->
            GiveList = get_gift_id(Num),
            [util:bitstring_to_term(GiftList), GiveList]
    end.   

%% 旧攻击数
get_old_att(Id) ->
    Sql = io_lib:format(<<"select num from wash_gift where pid = ~p">>, [Id]),
    case db:get_row(Sql) of
        [] ->
            0;
        [N] ->
            N
    end.

%% 更新
update_wash_gift(Id, Gid, Num, Type) ->
    case Type of
        insert ->
            Sql1 = io_lib:format(<<"insert into wash_gift set pid = ~p, gid = ~p, num=~p">>, [Id, Gid, Num]),
            db:execute(Sql1);
        update ->
            Sql1 = io_lib:format(<<"update wash_gift set num=~p, gid = ~p where pid = ~p">>, [Num, Gid, Id]),
            db:execute(Sql1)
    end.


%% 礼包ID
get_gift_id(Num) ->
    if
        Num =:= 1 ->
            [534030];
        Num =:= 2 ->
            [534030, 534031];
        Num =:= 3 ->
            [534030, 534031, 534032];
        Num =:= 4 ->
            [534030, 534031, 534032, 534033];
        Num =:= 5 ->
            [534030, 534031, 534032, 534033, 534034];
        true ->
            []
    end.

%% 0:不可领取 1:可以领取 2 已经领取
check_giftid_status([], _GetList, _GiveList, L) ->
    L;
check_giftid_status([GiftId|T], GetList, GiveList, L) ->
    case lists:member(GiftId, GetList) of
        true ->
            check_giftid_status(T, GetList, GiveList, [{GiftId,2}|L]);
        false ->
            case lists:member(GiftId, GiveList) of
                true ->
                    check_giftid_status(T, GetList, GiveList, [{GiftId,1}|L]);
                false ->
                    check_giftid_status(T, GetList, GiveList, [{GiftId,0}|L])
            end
    end.

%% 攻击条数
get_att_num([], N) ->
    N;
get_att_num([{Type, _Star, _Value, _Color, _Min, _Max}|T], N) ->
    if
        Type =:= 3 ->
            get_att_num(T, N+1);
        true ->
            get_att_num(T, N)
    end.

check_get_gift(PlayerStatus, GiftId) ->
    GiftList = get_gift_id(5),
    case lists:member(GiftId, GiftList) of
        false ->
            {fail, 2};
        true ->
           [GetList, _] = get_wash_gift_list(PlayerStatus#player_status.id),
           case lists:member(GiftId, GetList) of
               true ->
                   %% 已经领取过
                    {fail, 3};
                false ->
                    case data_activity_time:get_activity_time(8) of
                        false ->    %% 活动时间已经过了
                            {fail, 5};
                        true ->
                            N = get_old_att(PlayerStatus#player_status.id),
                            List = get_gift_id(N),
                            case lists:member(GiftId, List) of
                                false ->    %% 攻击数量不够
                                    {fail, 4};
                                true ->
                                    {ok, GiftId, GetList}
                            end
                    end
            end
    end.

update_get_gift(Pid, GiftId, List) ->
    NewList = [GiftId] ++ List,
    Sql = io_lib:format(<<"update wash_gift set gift_list = '~s', time=UNIX_TIMESTAMP() where pid = ~p">>, [util:term_to_bitstring(NewList), Pid]),
    db:execute(Sql).
    

