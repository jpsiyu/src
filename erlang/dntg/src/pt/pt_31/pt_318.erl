%%%------------------------------------
%%% @Module  : pt_318
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2013.02.01
%%% @Description: 经验材料召回活动
%%%------------------------------------
-module(pt_318).
-export([read/2, write/2]).

%% 是否显示小图标
read(31800,  _) ->
    {ok, []};

%% 显示信息
read(31801,  _) ->
    {ok, []};

%% 领取
read(31802,  <<Type:8, Num:32, CostType:8>>) ->
    {ok, [Type, Num, CostType]};

%% 错误
read(_Cmd, _R) ->
    {error, no_match}.

%% 是否显示小图标
write(31800, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(31800, Data)};

%% 显示信息
write(31801, [_List1, _List2]) ->
    List1 = lists:keysort(1, _List1),
    List2 = lists:keysort(1, _List2),
    Data = pack(List1, List2),
    {ok, pt:pack(31801, Data)};

%% 领取
write(31802, [Res, Str]) ->
    Str1 = pt:write_string(util:make_sure_list(Str)),
    Data = <<Res:8, Str1/binary>>,
    {ok, pt:pack(31802, Data)};
    
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

pack(List1, List2) ->
    Fun1 = fun(Elem1) ->
            {Type, Num, Exp} = Elem1,
            Per = data_off_line:get_per_goods_num(Type),
            <<Type:8, Num:8, Exp:32, Per:8>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List1]),
    Size1  = length(List1),
    Fun2 = fun(Elem2) ->
            {Type, Num, AwardNum, LastLevel, GoodsId} = Elem2,
            <<Type:8, Num:8, AwardNum:8, LastLevel:8, GoodsId:32>>
    end,
    BinList2 = list_to_binary([Fun2(X) || X <- List2]),
    Size2  = length(List2),
    <<Size1:16, BinList1/binary, Size2:16, BinList2/binary>>.
