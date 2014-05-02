%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-5-22
%% Description: TODO:
%% --------------------------------------------------------
-module(mod_secret_shop_call).
-export([handle_call/3]).
-include("shop.hrl").

%% 获取商店列表
handle_call({'list', PlayerId}, _From, Status) ->
    case dict:is_key(PlayerId, Status#state.dict) of
        true ->
            List = dict:fetch(PlayerId, Status#state.dict);
        false ->
            List = []
    end,
    {reply, List, Status};

%% 查询公告列表
handle_call({'notice_list'}, _From, Status) ->
    {reply, Status#state.notice, Status};
    
%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_secret_shop:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.





