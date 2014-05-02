%%%------------------------------------
%%% @Module  : mod_shengxiao_new_call
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.5.31
%%% @Description: 生肖大奖call
%%%------------------------------------
-module(mod_shengxiao_new_call).
-export([handle_call/3]).

%% 活动关闭
handle_call(stop, _From, Status) ->
	{stop, normal, stopped, Status};

%% 获取用户信息(63001)
handle_call({member, Id}, _From, Status) ->
	User = get({member, Id}),
	{reply, User, Status};

%% 获取member、select、tongji信息
%% Kind: member | select | tongji
%% 返回值: [#shengxiao_member] | [{Pos, A, Num}] | [{Award, Num, Gold, Bgold, Bcoin, Exp}]
handle_call({dict_get, Kind}, _From, Status) ->
    L = case Kind of
        %% 列表大于3时，隐藏固定3个玩家的投注信息
        get_other -> 
            _L = lib_shengxiao_new:list_deal(get(), member),
            case length(_L) > 3 of
                true -> 
                    case get(hide_three) of
                        HideList when is_list(HideList) ->
                            _L -- HideList;
                        _ ->
                            put(hide_three, lists:sublist(_L, 3)),
                            _L -- lists:sublist(_L, 3)
                    end;
                false -> _L
            end;
        _ ->
	        lib_shengxiao_new:list_deal(get(), Kind)
    end,
	{reply, L, Status};

%% 秘籍测试
handle_call(gm_test, _From, Status) ->
	Rep = get(gm),
	{reply, Rep, Status};

%% 中奖号码情况
%% Pos: 位置(1 | 2 | 3 | 4)
%% 返回值: {Pos, 生肖(数字1-12), 选择人数}
handle_call({select, Pos}, _From, Status) ->
	Rep = get({select, Pos}),
	{reply, Rep, Status};

%% 中奖情况统计
%% Award: 中奖级别(0 | 1 | 2 | 3 | 4 = 特等奖 | 一等奖 | 二等奖 | 三等奖 | 参与奖)
%% 返回值: {Award, 中奖人数, 奖励金币, 奖励绑定金币, 奖励绑定铜钱, 奖励经验}
handle_call({tongji, Award}, _From, Status) ->
	Rep = get({tongji, Award}),
	{reply, Rep, Status};

%% 用户点击投注, 把相关数据写入进程字典中
%% Id: 用户Id
%% ShengxiaoMember: shengxiao_member记录
handle_call({put_member, Id, ShengxiaoMember}, _From, Status) ->
	put({member, Id}, ShengxiaoMember),
    {reply, ok, Status};

%% 记录中奖情况
%% Award: 中奖级别
%% Any: {Award, Num, Gold, Bgold, Bcoin, Exp}
handle_call({put_tongji, Award, Any}, _From, Status) ->
	put({tongji, Award}, Any),
    {reply, ok, Status};

%% 记录每个中奖生肖所数人数
%% Pos: 位置(1 | 2 | 3 | 4)
%% Any: {Pos, A, Num}
handle_call({put_select, Pos, Any}, _From, Status) ->
	put({select, Pos}, Any),
    {reply, ok, Status};

%% GM秘籍: 记录结束时间
handle_call({put_gm, Endtime}, _From, Status) ->
	put(gm, Endtime),
    {reply, ok, Status};

%% 清空数据
handle_call(clear_data, _From, Status) ->
	erase(),
    {reply, ok, Status};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_shengxiao_new:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.
