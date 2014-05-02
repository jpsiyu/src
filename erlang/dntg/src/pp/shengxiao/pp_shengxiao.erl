%%%--------------------------------------
%%% @Module  : pp_shengxiao
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.5.30
%%% @Description:  生肖大奖功能
%%%--------------------------------------

-module(pp_shengxiao).
-export([handle/3, pack_list/1, pack_list_winner/1]).
-include("common.hrl").
-include("unite.hrl").

%% 获取个人已投注信息(公共线)
handle(63001, Status, _Bin) ->
	%io:format("recv 63001~n"),
	[{Local1, Option1}, {Local2, Option2}, {Local3, Option3}, {Local4, Option4}] = lib_shengxiao:member(Status#unite_status.id),
	{ok, BinData} = pt_630:write(63001, [Local1, Option1, Local2, Option2, Local3, Option3, Local4, Option4]),
	%io:format("63001:~p~n", [BinData]),
	lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 刷新其他用户投注信息(公共线)
handle(63002, Status, _Bin) ->
	%io:format("recv 63002~n"),
    List = lib_shengxiao:other_betting(),
	{ok, BinData} = pt_630:write(63002, pack_list(List)),
	%io:format("63002:~p~n", [BinData]),
	lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 开奖倒计时通知(公共线)
handle(63003, Status, _Bin) ->
	%io:format("recv 63003~n"),
    Time = lib_shengxiao:lottery_countdown(),
	{ok, BinData} = pt_630:write(63003, Time),
	%io:format("63003:~p~n", [BinData]),
	lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 倒计时完，获取开奖信息(公共线)
handle(63005, Status, _Bin) ->
	%io:format("recv 63005~n"),
    [L1, L2, L3, L4, L5, L6, L7, L8, L9, Award, L10, IsDrow] = lib_shengxiao:lottery_info(Status#unite_status.id),
	{ok, BinData} = pt_630:write(63005, [L1, L2, L3, L4, L5, L6, L7, L8, L9, Award, L10, IsDrow]),
	%io:format("63005:~p~n", [BinData]),
	lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 获取中奖名单(公共线)
handle(63006, Status, _Bin) ->
	%io:format("recv 63006~n"),
    List = lib_shengxiao:winner(),
	{ok, BinData} = pt_630:write(63006, pack_list_winner(List)),
	%io:format("63006:~p~n", [BinData]),
	lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 返回用户的活动状态(公共线)
handle(63007, Status, _Bin) ->
	%io:format("recv 63007~n"),
    Stat = lib_shengxiao:user_state(Status#unite_status.id),
	{ok, BinData} = pt_630:write(63007, Stat),
	%io:format("63007:~p~n", [BinData]),
	lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);

%% 用户点击投注(公共线)
handle(63010, Status, [Pos1, Select1, Pos2, Select2, Pos3, Select3, Pos4, Select4]) ->
    case Pos1 >= 1 andalso Pos1 =< 4 andalso Pos2 >= 1 andalso Pos2 =< 4 andalso Pos3 >= 1 andalso Pos3 =< 4 andalso Pos4 >= 1 andalso Pos4 =< 4 andalso Select1 >= 1 andalso Select1 =< 12 andalso Select2 >= 1 andalso Select2 =< 12 andalso Select3 >= 1 andalso Select3 =< 12 andalso Select4 >= 1 andalso Select4 =< 12 of
        true ->
            %io:format("recv 63010~n"),
            {Res, Status1} = lib_shengxiao:bet(Status, Pos1, Select1, Pos2, Select2, Pos3, Select3, Pos4, Select4),
            {ok, BinData} = pt_630:write(63010, Res),
            %io:format("63010:~p~n", [BinData]),
            lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
            {ok, Status1};
        false -> skip
    end;

%% 用户领奖(公共线)
handle(63011, Status, _Bin) ->
	%io:format("recv 63011~n"),
	{Res, Award, Status1} = lib_shengxiao:award(Status),
	{ok, BinData} = pt_630:write(63011, {Res, Award}),
	%io:format("63011:~p~n", [BinData]),
	lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
	{ok, Status1};

handle(_Cmd, _LogicStatus, _Data) ->
    ?DEBUG("pp_shengxiao no match", []),
    {error, "pp_shengxiao no match"}.

%% 打包其他用户的投注信息
pack_list(List) ->
    Fun = fun(Elem) ->
				{Role_id, Name, Other} = Elem,
				Role_id1 = Role_id,
				Name1    = list_to_binary(Name),
				%Name1    = Name,
				Other1   = list_to_binary(Other),
				NL       = byte_size(Name1),
				OL       = byte_size(Other1),
				<<Role_id1:32, NL:16, Name1/binary, OL:16, Other1/binary>>
    end,
    BinList = list_to_binary([Fun(X) || X <- List]),
    Size  = length(List),
    <<Size:16, BinList/binary>>.

%% 打包获奖者信息
pack_list_winner(List) ->
	Fun = fun(Elem) ->
				{Id, Name, IsDrow, Award} = Elem,
				Id1      = Id,
				Name1    = list_to_binary(Name),
				IsDrow1 = IsDrow,
				Award1   = Award,
				NL       = byte_size(Name1),
				<<Id1:32, NL:16, Name1/binary, IsDrow1:8, Award1:8>>
    end,
    BinList = list_to_binary([Fun(X) || X <- List]),
    Size  = length(List),
    <<Size:16, BinList/binary>>.
