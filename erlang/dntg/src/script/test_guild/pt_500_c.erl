%%%---------------------------------------------
%%% @Module  : pt_500_c
%%% @Author  : zhenghehe
%%% @Created : 2012.01.16
%%% @Description: 帮战系统测试客户端组包解包
%%%---------------------------------------------
-module(pt_500_c).
-compile(export_all).
write(50001, []) ->
	{ok, pt:pack(50001, <<>>)};
write(50003, []) ->
	{ok, pt:pack(50003, <<>>)};
write(50004, []) ->
	{ok, pt:pack(50004, <<>>)};
write(50007, []) ->
	{ok, pt:pack(50007, <<>>)};
write(50015, [PageSize, PageNo]) ->
	Data = <<PageSize:16, PageNo:16>>,
	{ok, pt:pack(50015, Data)};
write(50017, []) ->
	{ok, pt:pack(50017, <<>>)};
write(50018, [PageSize, PageNo]) ->
	Data = <<PageSize:16, PageNo:16>>,
	{ok, pt:pack(50018, Data)};
write(50021, []) ->
	{ok, pt:pack(50021, <<>>)};
write(50022, []) ->
	{ok, pt:pack(50022, <<>>)};
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

read(50001, <<Error:16>>) ->
	Error;
read(50003, <<Error:16, Zone:16>>) ->
	{Error, Zone};
read(50004, <<Error:16>>) ->
	Error;
read(_Cmd, _R) ->
    {error, no_match}.