%%%------------------------------------
%%% @Module  : mod_shengxiao_new
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.5.30
%%% @Description: 生肖大奖处理
%%%------------------------------------

-module(mod_shengxiao_new).
-behaviour(gen_server).
-include("shengxiao.hrl").
-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-compile(export_all).

%% 活动关闭
close() -> 
	gen_server:call(?MODULE, stop).

%% 获取用户信息(63001)
%% 返回值: 一个shengxiao_member记录
member(Id) -> 
	gen_server:call(?MODULE, {member, Id}).

%% 获取member、select、tongji信息
%% Kind: member | select | tongji
%% 返回值: [#shengxiao_member] | [{Pos, A, Num}] | [{Award, Num, Gold, Bgold, Bcoin, Exp}]
dict_get(Kind) -> 
	gen_server:call(?MODULE, {dict_get, Kind}).

%% 秘籍测试
gm_test() -> 
	gen_server:call(?MODULE, gm_test).

%% 中奖号码情况
%% Pos: 位置(1 | 2 | 3 | 4)
%% 返回值: {Pos, 生肖(数字1-12), 选择人数}
select(Pos) -> 
	gen_server:call(?MODULE, {select, Pos}).

%% 中奖情况统计
%% Award: 中奖级别(0 | 1 | 2 | 3 | 4 = 特等奖 | 一等奖 | 二等奖 | 三等奖 | 参与奖)
%% 返回值: {Award, 中奖人数, 奖励金币, 奖励绑定金币, 奖励绑定铜钱, 奖励经验}
tongji(Award) -> 
	gen_server:call(?MODULE, {tongji, Award}).

%% 用户点击投注, 把相关数据写入进程字典中
%% Id: 用户Id
%% ShengxiaoMember: shengxiao_member记录
put_member(Id, ShengxiaoMember) ->
	gen_server:call(?MODULE, {put_member, Id, ShengxiaoMember}).

%% 记录中奖情况
%% Award: 中奖级别
%% Any: {Award, Num, Gold, Bgold, Bcoin, Exp}
put_tongji(Award, Any) -> 
	gen_server:call(?MODULE, {put_tongji, Award, Any}).

%% 记录每个中奖生肖所数人数
%% Pos: 位置(1 | 2 | 3 | 4)
%% Any: {Pos, A, Num}
put_select(Pos, Any) -> 
	gen_server:call(?MODULE, {put_select, Pos, Any}).

%% GM秘籍: 记录结束时间
put_gm(Endtime) -> 
	gen_server:call(?MODULE, {put_gm, Endtime}).

%% 清空数据
clear_data() -> 
	gen_server:call(?MODULE, clear_data).


start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    process_flag(trap_exit, true),
    spawn(fun() ->
                db:execute(io_lib:format(<<"insert into log_shengxiao_info set time = ~p">>, [util:unixtime()]))
        end),
    {ok, 0}.

handle_call(Request, From, State) ->
    mod_shengxiao_new_call:handle_call(Request, From, State).

handle_cast(Msg, State) ->
    mod_shengxiao_new_cast:handle_cast(Msg, State).

handle_info(Info, State) ->
    mod_shengxiao_new_info:handle_info(Info, State).

terminate(_Reason, _Status) ->
    %catch util:errlog("~p terminate!! ~n", [?MODULE]),
    ok.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

