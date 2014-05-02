%%%------------------------------------------------
%%% @Module  : pt_420
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.28
%%% @Description: 防沉迷系统
%%%------------------------------------

-module(pt_420).
-export([read/2, write/2]).

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(42001, <<Status:8>>) ->
    {ok, Status};

read(42002, <<Status:8, Bin/binary>>) ->
	{Name, Bin1} = pt:read_string(Bin),
	{IdCardNo, _} = pt:read_string(Bin1),
	{ok, [Status, Name, IdCardNo]};

read(42003, _) ->
    {ok, no};

read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================

%%% 身份获取
write(42001, [Status, Name, IdCardNo, UnderAgeFlag]) ->
%	Name1     = list_to_binary(Name),
	NL        = byte_size(Name),
%	IdCardNo1 = list_to_binary(IdCardNo),
	IL        = byte_size(IdCardNo),
	Data = <<Status:8, NL:16, Name/binary, IL:16, IdCardNo/binary, UnderAgeFlag:8>>,
    {ok, pt:pack(42001, Data)};

%%% 身份提交
write(42002, [Status, UnderAgeFlag]) ->
	Data = <<Status:8, UnderAgeFlag:8>>,
    {ok, pt:pack(42002, Data)};

%%% 沉迷计时同步
write(42003, [State, Type, OnlineTime]) ->
	Data = <<State:8, Type:8, OnlineTime:32>>,
    {ok, pt:pack(42003, Data)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.


