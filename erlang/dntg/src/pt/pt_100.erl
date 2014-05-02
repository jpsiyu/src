%%%-----------------------------------
%%% @Module  : pt_100
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.04.29
%%% @Description: 注册登录系统
%%%-----------------------------------
-module(pt_100).
-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%

%%登陆
read(10000, <<Accid:32, Tstamp:32, Bin/binary>>) ->
    {Accname, Bin1} = pt:read_string(Bin),
    {Ticket, _} = pt:read_string(Bin1),
    {ok, [Accid, Accname, Tstamp, Ticket]};

%%退出
read(10001, _) ->
    {ok, logout};

%%读取列表
read(10002, _R) ->
    {ok, []};

%%创建角色
read(10003, <<Realm:8, Career:8, Sex:8, Bin/binary>>) ->
    {Name, Bin1} = pt:read_string(Bin),
    {Source, _} = pt:read_string(Bin1),
    {ok, [Realm, Career, Sex, Name, Source]};

%%选择角色进入游戏
read(10004, <<Id:32, Time:32, Bin/binary>>) ->
    {Ticket, _} = pt:read_string(Bin),
    {ok, [Id, Time, Ticket]};

%%删除角色
read(10005, <<Id:32>>) ->
    {ok, Id};

%%心跳包
read(10006, _) ->
    {ok, heartbeat};

%% 检查
read(10010, <<Bin/binary>>) ->
	{Name, _} = pt:read_string(Bin),
    {ok, [Name]};

%% 查看在线人数
read(10016, _) ->
    {ok, []};

%%获取聊天功能系统验证所需信息
%%read(10090, _) ->
%%    {ok, info};
read(10090, _) ->
    {ok, info};

%%公共系统登陆
read(10091, <<Id:32, Time:32, Bin/binary>>) ->
    {Ticket, _} = pt:read_string(Bin),
    {ok, [Id, Time, Ticket]};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%%登陆返回
write(10000, [Code, Num, Career, Time]) ->
    {ok, pt:pack(10000, <<Code:32, Num:8, Career:8, Time:64>>)};

%%登陆退出
write(10001, _) ->
    Data = <<>>,
    {ok, pt:pack(10001, Data)};

%% 打包角色列表
write(10002, []) ->
    N = 0,
    LB = <<>>,
    {ok, pt:pack(10002, <<N:16, LB/binary>>)};
write(10002, L) ->
    N = length(L),
    F = fun([Pid, Status, Name, Sex, Lv, Career, Realm, WeaponGoodsId, ArmorGoodsId,
			FashionWeaponGoodsId, FashionArmorGoodsId, FashionAccessoryGoodsId]) ->
            Name1 = pt:write_string(Name),
            <<Pid:32, Status:8, Career:8, Sex:8, Lv:16, Name1/binary, Realm:8,
			  WeaponGoodsId:32, ArmorGoodsId:32, FashionWeaponGoodsId:32, 
			  FashionArmorGoodsId:32, FashionAccessoryGoodsId:32>>
    end,
    LB = list_to_binary([F(X) || X <- L]),
    {ok, pt:pack(10002, <<N:16, LB/binary>>)};

%%创建角色
write(10003, [Code, Id]) ->
    Data = <<Code:8, Id:32>>,
    {ok,  pt:pack(10003, Data)};

%%选择角色进入游戏
write(10004, Code) ->
    Data = <<Code:8>>,
    {ok, pt:pack(10004, Data)};

%%删除角色
write(10005, Code) ->
    Data = <<Code:16>>,
    {ok, pt:pack(10005, Data)};

%%心跳包
write(10006, _) ->
    {ok, pt:pack(10006, <<>>)};

%%检查
write(10010, [Res]) ->
    {ok, pt:pack(10010, <<Res:8>>)};

%%获取在线人数
write(10016, Num) ->
    {ok, pt:pack(10016, <<Num:32>>)};

%%获取聊天功能系统验证所需信息
write(10090, [Time, Port, Ip, Ticket]) ->
    Ip1 = pt:write_string(Ip),
    Ticket1 = pt:write_string(Ticket),
    {ok, pt:pack(10090, <<Time:32, Port:16, Ip1/binary, Ticket1/binary>>)};

%%公共系统登陆
write(10091, Code) ->
    {ok, pt:pack(10091, <<Code:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
