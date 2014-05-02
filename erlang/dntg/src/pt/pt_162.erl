%%%-------------------------------------------------------------------
%%% @Module	: pt_162
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 21 Dec 2012
%%% @Description: 
%%%-------------------------------------------------------------------
-module(pt_162).
-include("flyer.hrl").
-export([read/2, write/2]).

%%客户端 -> 服务端 ----------------------------
%% 请求飞行器列表
read(16200, _) ->
    {ok, []};

%% 获取飞行器详细信息
read(16201, <<Nth:8>>) ->
    {ok, [Nth]};

%% 飞行器解封
read(16202, <<No:8>>) ->
    {ok, [No]};

%% 飞行器训练
read(16203, <<No:8>>) ->
    {ok, [No]};

%% 飞行器飞行
read(16204, <<No:8>>) ->
    {ok, [No]};

%% 飞行器停止飞行
read(16205, <<No:8>>) ->
    {ok, [No]};

%% 飞行器装备
read(16206, <<No:8>>) ->
    {ok, [No]};

%% 飞行器卸下
read(16207, <<No:8>>) ->
    {ok, [No]};

%% 飞行器升星
read(16208, <<No:8, Num:16, Bin/binary>>) ->
    {_Rest, GoodsList} = pt:read_id_num_list(Bin, [], Num),
    {ok, [No, GoodsList]};

%% 飞行器回退
read(16209, <<No:8, IsTick:8, Bin/binary>>) ->
    {StarNum, _} = pt:read_string(Bin),
    {ok, [No, StarNum, IsTick]};

read(16210, <<No:8, Type:8>>) ->
    {ok, [No, Type]};
read(16211, <<PlayerId:32, No:8>>) ->
    {ok, [PlayerId, No]};

read(16212, <<PlayerId:32, No:8>>) ->
    {ok, [PlayerId, No]};

read(16213, _) ->
    {ok, []};

read(_Cmd, _R) ->
    {error, no_match}.

write(16200, [Records, CanTrainNum]) ->
    Len = length(Records),
    Bin = list_to_binary(Records),
    Data = <<Len:8, Len:16, Bin/binary, CanTrainNum:8>>,
    {ok, pt:pack(16200, Data)};

write(16201, [Records]) ->
    Data = <<Records/binary>>,
    {ok, pt:pack(16201, Data)};

write(16202, [Result, Nth]) ->
    Data = <<Result:16, Nth:8>>,
    {ok, pt:pack(16202, Data)};

write(16203, [Result, Nth]) ->
    Data = <<Result:16, Nth:8>>,
    {ok, pt:pack(16203, Data)};
write(16204, [Result, Nth]) ->
    Data = <<Result:8, Nth:8>>,
    {ok, pt:pack(16204, Data)};
write(16205, [Result, Nth]) ->
    Data = <<Result:8, Nth:8>>,
    {ok, pt:pack(16205, Data)};
write(16206, [Result, Nth]) ->
    Data = <<Result:8, Nth:8>>,
    {ok, pt:pack(16206, Data)};
write(16207, [Result, Nth]) ->
    Data = <<Result:8, Nth:8>>,
    {ok, pt:pack(16207, Data)};
write(16208, [Result, Nth, Star]) ->
    case is_record(Star, flyer_star) of
	true ->
	    StarBin = lib_flyer:parse_flyer_star_list(Star);
	false ->
	    StarBin = <<>>
    end,
    Data = <<Result:16, Nth:8, StarBin/binary>>,
    {ok, pt:pack(16208, Data)};
write(16209, [Result, Nth, Star]) ->
    case is_record(Star, flyer_star) of
	true ->
	    StarBin = lib_flyer:parse_flyer_star_list(Star);
	false ->
	    StarBin = <<>>
    end,
    Data = <<Result:16, Nth:8, StarBin/binary>>,
    {ok, pt:pack(16209, Data)};
write(16210, [L, CombatPower, LookType]) ->
    Len = length(L),
    List = [<<Type:8,Val:16>> || {Type,Val} <- L],
    Bin = list_to_binary(List),
    Data = <<Len:16, Bin/binary, CombatPower:32, LookType:8>>,
    {ok, pt:pack(16210, Data)};
write(16211, [Nth, L, CombatPower, Name, LimitStars]) ->
    BinName = pt:write_string(Name),
    List = lists:map(fun(V) -> Val = V#flyer_star.star_value, <<Val:16>> end, L),
    Len = length(List),
    Bin = list_to_binary(List),
    Data = <<Nth:8, Len:16, Bin/binary, CombatPower:32, BinName/binary, LimitStars:16>>,
    {ok, pt:pack(16211, Data)};
write(16212, [_FlyerName, _PlayerName, TrainLv, FlyerFigure, CombatPower, _StarList, MaxStar, Quality, Nth]) ->
    FlyerName = pt:write_string(_FlyerName),
    PlayerName = pt:write_string(_PlayerName),
    StarListLen = length(_StarList),
    StarList = [<<StarValue:16>> || StarValue <- _StarList],
    StarListBin = list_to_binary(StarList),
    Data = <<FlyerName/binary, PlayerName/binary, TrainLv:16, FlyerFigure:16, CombatPower:32, StarListLen:16, StarListBin/binary, MaxStar:16, Quality:8, Nth:8>>,
    {ok, pt:pack(16212, Data)};

write(16213, [Total, Num, QualityList]) ->
    Len = length(QualityList),
    _QualityBin = [<<Nth:8, Quality:8>> || {Nth, Quality} <- QualityList],
    QualityBin = list_to_binary(_QualityBin),
    Data = <<Total:16, Num:8, Len:16, QualityBin/binary>>,
    {ok, pt:pack(16213, Data)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

%% read_id_num_list(<<Id:32, Num:16, Rest/binary>>, List, ListNum) when ListNum > 0 ->
%%     NewList = [{Id, Num} | List],
%%     read_id_num_list(Rest, NewList, ListNum - 1);
%% read_id_num_list(_, List, _) -> List.


