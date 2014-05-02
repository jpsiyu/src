%%%------------------------------------------------
%%% @Module  : pt_630
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.4
%%% @Description: 生肖大奖
%%%------------------------------------

-module(pt_630).
-export([read/2, write/2]).

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(63001, _) ->
    {ok, no};

read(63002, _) ->
    {ok, no};

read(63003, _) ->
    {ok, no};

read(63005, _) ->
    {ok, no};

read(63006, _) ->
    {ok, no};

read(63007, _) ->
    {ok, no};

%% 用户点击投注
read(63010, <<Local1:8, Option1:8, Local2:8, Option2:8, Local3:8, Option3:8, Local4:8, Option4:8>>) ->
	{ok, [Local1, Option1, Local2, Option2, Local3, Option3, Local4, Option4]};

read(63011, _) ->
    {ok, no};

read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================

%%% 获取个人已投注信息(公共线)
write(63001, [Local1, Option1, Local2, Option2, Local3, Option3, Local4, Option4]) ->
	case Local1 =:= 0 of
		true  -> Data = <<0:16>>;
		false -> Data = <<4:16, Local1:8, Option1:8, Local2:8, Option2:8, Local3:8, Option3:8, Local4:8, Option4:8>>
	end,
    {ok, pt:pack(63001, Data)};

%%% 刷新其他用户投注信息(公共线)
write(63002, Bin) ->
	Data = Bin,
    {ok, pt:pack(63002, Data)};

%%% 开奖倒计时通知(公共线)
write(63003, Time) ->
	Data = <<Time:32>>,
    {ok, pt:pack(63003, Data)};

%%% 服务器主动发开始倒计时(公共线)
write(63004, Time) ->
	Data = <<0:8, Time:32>>,
    {ok, pt:pack(63004, Data)};

%%% 倒计时完，获取开奖信息(公共线)
write(63005, [L1, L2, L3, L4, L5, L6, L7, L8, L9, Award, L10, Is_drow]) ->
	{Lpos1, Lop1, Lnum1} = L1,
	{Lpos2, Lop2, Lnum2} = L2,
	{Lpos3, Lop3, Lnum3} = L3,
	{Lpos4, Lop4, Lnum4} = L4,
	io:format("~p,~p,~p,~p", [L1,L2,L3,L4]),
	{Law5, Lnum5, Lgold5, Lbgold5, Lbcopper5, Lex5} = L5,
	{Law6, Lnum6, Lgold6, Lbgold6, Lbcopper6, Lex6} = L6,
	{Law7, Lnum7, Lgold7, Lbgold7, Lbcopper7, Lex7} = L7,
	{Law8, Lnum8, Lgold8, Lbgold8, Lbcopper8, Lex8} = L8,
	{Law9, Lnum9, Lgold9, Lbgold9, Lbcopper9, Lex9} = L9,
	[{Local1, Option1}, {Local2, Option2}, {Local3, Option3}, {Local4, Option4}] = L10,
	case Local1 =:= 0 of
		true ->
			Data = <<4:16, Lpos1:8, Lop1:8, Lnum1:16, Lpos2:8, Lop2:8, Lnum2:16, Lpos3:8, Lop3:8, Lnum3:16, Lpos4:8, Lop4:8, Lnum4:16, 5:16, Law5:8, Lnum5:32, Lgold5:32, Lbgold5:32, Lbcopper5:32, Lex5:32, Law6:8, Lnum6:32, Lgold6:32, Lbgold6:32, Lbcopper6:32, Lex6:32, Law7:8, Lnum7:32, Lgold7:32, Lbgold7:32, Lbcopper7:32, Lex7:32, Law8:8, Lnum8:32, Lgold8:32, Lbgold8:32, Lbcopper8:32, Lex8:32, Law9:8, Lnum9:32, Lgold9:32, Lbgold9:32, Lbcopper9:32, Lex9:32, Award:8, 0:16, Local1:8, Option1:8, Local2:8, Option2:8, Local3:8, Option3:8, Local4:8, Option4:8, Is_drow:8>>;
		false ->
			Data = <<4:16, Lpos1:8, Lop1:8, Lnum1:16, Lpos2:8, Lop2:8, Lnum2:16, Lpos3:8, Lop3:8, Lnum3:16, Lpos4:8, Lop4:8, Lnum4:16, 5:16, Law5:8, Lnum5:32, Lgold5:32, Lbgold5:32, Lbcopper5:32, Lex5:32, Law6:8, Lnum6:32, Lgold6:32, Lbgold6:32, Lbcopper6:32, Lex6:32, Law7:8, Lnum7:32, Lgold7:32, Lbgold7:32, Lbcopper7:32, Lex7:32, Law8:8, Lnum8:32, Lgold8:32, Lbgold8:32, Lbcopper8:32, Lex8:32, Law9:8, Lnum9:32, Lgold9:32, Lbgold9:32, Lbcopper9:32, Lex9:32, Award:8, 4:16, Local1:8, Option1:8, Local2:8, Option2:8, Local3:8, Option3:8, Local4:8, Option4:8, Is_drow:8>>
	end,
    {ok, pt:pack(63005, Data)};

%%% 获取中奖名单(公共线)
write(63006, Bin) ->
	Data = Bin,
    {ok, pt:pack(63006, Data)};

%%% 返回用户的活动状态(公共线)
write(63007, Status) ->
	Data = <<Status:8>>,
    {ok, pt:pack(63007, Data)};

%%% 活动关闭，广播(公共线)
write(63008, _) ->
	Data = <<0:8>>,
    {ok, pt:pack(63008, Data)};

%%% 活动结束,发送可领奖的提示(仅针对未领奖用户)
write(63009, [Res]) ->
	Data = <<Res:8>>,
    {ok, pt:pack(63009, Data)};

%%% 用户点击投注(公共线)
write(63010, Res) ->
	Data = <<Res:8>>,
    {ok, pt:pack(63010, Data)};

%%% 用户领奖(公共线)
write(63011, {Res, Award}) ->
	_Award = list_to_binary(Award),
	AL = byte_size(_Award),
	Data = <<Res:8, AL:16, _Award/binary>>,
    {ok, pt:pack(63011, Data)};

write(63015, GoodsTypeId) ->
    {ok, pt:pack(63015, <<GoodsTypeId:32>>)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.

