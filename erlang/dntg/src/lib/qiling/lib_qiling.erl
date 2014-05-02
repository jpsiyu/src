%%%-------------------------------------------------------------------
%%% @Module	: lib_qiling
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 31 Oct 2012
%%% @Description: 器灵
%%%-------------------------------------------------------------------
-module(lib_qiling).
-compile(export_all).
-include("server.hrl").
init_qiling_attr(PlayerId) ->
    Q = io_lib:format(<<"select attr_list from qiling where player_id=~p order by attr_type">>,[PlayerId]),
    case db:get_all(Q) of
	[] ->
	    QiLing = #status_qiling{
	      %% [{位置，开启，等级，经验},...]
	      forza = [{1,1,0,0},{2,0,0,0},{3,0,0,0},{4,0,0,0},{5,0,0,0},{6,0,0,0}],
	      agile = [{1,1,0,0},{2,0,0,0},{3,0,0,0},{4,0,0,0},{5,0,0,0},{6,0,0,0}],
	      wit = [{1,1,0,0},{2,0,0,0},{3,0,0,0},{4,0,0,0},{5,0,0,0},{6,0,0,0}],
	      thew = [{1,1,0,0},{2,0,0,0},{3,0,0,0},{4,0,0,0},{5,0,0,0},{6,0,0,0}]
	     },
	    F = fun() ->
			db:execute(io_lib:format(<<"insert into qiling(player_id,attr_type,attr_list) values(~p,~p,'~s')">>,[PlayerId,1,util:term_to_string(QiLing#status_qiling.forza)])),
			db:execute(io_lib:format(<<"insert into qiling(player_id,attr_type,attr_list) values(~p,~p,'~s')">>,[PlayerId,2,util:term_to_string(QiLing#status_qiling.agile)])),
			db:execute(io_lib:format(<<"insert into qiling(player_id,attr_type,attr_list) values(~p,~p,'~s')">>,[PlayerId,3,util:term_to_string(QiLing#status_qiling.wit)])),
			db:execute(io_lib:format(<<"insert into qiling(player_id,attr_type,attr_list) values(~p,~p,'~s')">>,[PlayerId,4,util:term_to_string(QiLing#status_qiling.thew)]))
		end,
	    db:transaction(F),
	    QiLing;
	List ->
	    [Forza, Agile, Wit, Thew] = lists:map(fun([X]) -> lib_goods_util:to_term(X) end, List),
	    #status_qiling{
	      %% [{位置，开启，等级，经验},...]
	      forza = Forza,
	      agile = Agile,
	      wit = Wit,
	      thew = Thew
	     }
    end.
calc_qiling_type_lv(QiLingType) ->
    lists:foldl(fun({_Pos, Open, Lv, _Exp}, LvSum) ->
			case Open =:= 1 of
			    true -> Lv + LvSum;
			    false -> LvSum
			end
		end, 0, QiLingType).

get_four_qiling_type_lv(QiLing) ->
    ForzaLv = calc_qiling_type_lv(QiLing#status_qiling.forza),
    AgileLv = calc_qiling_type_lv(QiLing#status_qiling.agile),
    WitLv = calc_qiling_type_lv(QiLing#status_qiling.wit),
    ThewLv = calc_qiling_type_lv(QiLing#status_qiling.thew),
    [{1,ForzaLv}, {2,AgileLv}, {3,WitLv}, {4,ThewLv}].
get_init_ratio() ->
    [{1,25},{2,25},{3,25},{4,25}].
%% @param: QiLingLvList:[{1,ForzaLv}, {2,AgileLv}, {3,WitLv}, {4,ThewLv}]
adjust_ratio(Ratio, QiLingLvList) ->
    %% 是否存在不同等级 
    case is_all_same(QiLingLvList, 2) of
	true -> Ratio;
	false ->
	    InitRatio = Ratio,
	    %% 先找出最低级的属性
	    {MinType, MinTypeLv} = min_ex(QiLingLvList, 2),
	    OtherThree = lists:keydelete(MinType, 1, InitRatio),
	    TotalRatio = lib_goods_util:get_ratio_total(OtherThree, 2),
	    Rand = util:rand(1, TotalRatio),
	    {MaxTypeTmp,_} = lib_goods_util:find_ratio(OtherThree, 0, Rand, 2),
	    {MaxType, MaxTypeLv} = lists:keyfind(MaxTypeTmp, 1, QiLingLvList),
	    {_, MinTypeRatio} = lists:keyfind(MinType, 1, InitRatio),
	    {_, MaxTypeRatio} = lists:keyfind(MaxType, 1, InitRatio),
	    %% 相差1级,低级加5%概率，从高级的扣
	    NewMaxTypeRatioTmp = MaxTypeRatio - (MaxTypeLv - MinTypeLv) * 5,
	    NewMaxTypeRatio = case NewMaxTypeRatioTmp < 0 of
				  true -> 0;
				  false -> NewMaxTypeRatioTmp
			      end,
	    NewMinTypeRatio = MinTypeRatio + MaxTypeRatio - NewMaxTypeRatio,
	    List1 = lists:keyreplace(MinType, 1, InitRatio, {MinType, NewMinTypeRatio}),
	    lists:keyreplace(MaxType, 1, List1, {MaxType, NewMaxTypeRatio})
    end.
%% 器灵培养
%% @return: false | {Type,Pos,NewPS}
cultivate_qiling(PS) ->
    Ball = generate_qiling_ball(PS),
    case add_exp(PS, Ball, 1) of
	[false, ErrorCode] -> [false,ErrorCode];
	{Pos, NewQiLing} ->
	    %% lib_qixi:update_player_task_batch(PS#player_status.id, qhs, 1),
	    {Ball, Pos, PS#player_status{qiling_attr = NewQiLing}}
    end.
		    
generate_qiling_ball(PS) ->
    LvList = get_four_qiling_type_lv(PS#player_status.qiling_attr),
    InitRatio = get_init_ratio(),
    NewRatio = adjust_ratio(InitRatio, LvList),
    TotalRatio = lib_goods_util:get_ratio_total(NewRatio, 2),
    Rand = util:rand(1, TotalRatio),
    {Type, _} = lib_goods_util:find_ratio(NewRatio, 0, Rand, 2),
    Type.
%% 开孔
%% @return: NewPS  |  [false, ErrorCode]
open_pos(PS) ->
    QiLing = PS#player_status.qiling_attr,
    GoodsPid = PS#player_status.goods#status_goods.goods_pid,
    ForzaOpen = length(lists:filter(fun({_,Open,_,_}) -> Open =:= 1 end, QiLing#status_qiling.forza)),
    AgileOpen = length(lists:filter(fun({_,Open,_,_}) -> Open =:= 1 end, QiLing#status_qiling.agile)),
    WitOpen = length(lists:filter(fun({_,Open,_,_}) -> Open =:= 1 end, QiLing#status_qiling.wit)),
    ThewOpen = length(lists:filter(fun({_,Open,_,_}) -> Open =:= 1 end, QiLing#status_qiling.thew)),
    MinOpen = lists:min([ForzaOpen,AgileOpen,WitOpen,ThewOpen]),
    Result =
	if
	    MinOpen >= 6 ->
		[false, 4];
	    MinOpen =:= ThewOpen ->
		{_,List} = lists:keyfind(4, 1, data_qiling:get_open_pos_config()),
		{_, GoodsTypeId, GoodsNum} = lists:keyfind(ThewOpen+1, 1, List),
		case gen_server:call(GoodsPid, {'delete_more', GoodsTypeId, GoodsNum}) of
		    1 ->
			catch log:log_goods_use(PS#player_status.id, GoodsTypeId, GoodsNum),
			{thew, QiLing#status_qiling{thew = lists:keyreplace(ThewOpen+1,1,QiLing#status_qiling.thew,{ThewOpen+1,1,0,0})}};
		    Error -> [false, Error]
		end;
	    MinOpen =:= AgileOpen ->
		{_,List} = lists:keyfind(2, 1, data_qiling:get_open_pos_config()),
		{_, GoodsTypeId, GoodsNum} = lists:keyfind(AgileOpen+1, 1, List),
		case gen_server:call(GoodsPid, {'delete_more', GoodsTypeId, GoodsNum}) of
		    1 ->
			catch log:log_goods_use(PS#player_status.id, GoodsTypeId, GoodsNum),
			{agile, QiLing#status_qiling{agile = lists:keyreplace(AgileOpen+1,1,QiLing#status_qiling.agile,{AgileOpen+1,1,0,0})}};
		    Error -> [false, Error]
		end;
	    MinOpen =:= WitOpen ->
		{_,List} = lists:keyfind(3, 1, data_qiling:get_open_pos_config()),
		{_, GoodsTypeId, GoodsNum} = lists:keyfind(WitOpen+1, 1, List),
		case gen_server:call(GoodsPid, {'delete_more', GoodsTypeId, GoodsNum}) of
		    1 ->
			catch log:log_goods_use(PS#player_status.id, GoodsTypeId, GoodsNum),
			{wit, QiLing#status_qiling{wit = lists:keyreplace(WitOpen+1,1,QiLing#status_qiling.wit,{WitOpen+1,1,0,0})}};
		    Error -> [false, Error]
		end;
	    MinOpen =:= ForzaOpen ->
		{_,List} = lists:keyfind(1, 1, data_qiling:get_open_pos_config()),
		{_, GoodsTypeId, GoodsNum} = lists:keyfind(ForzaOpen+1, 1, List),
		case gen_server:call(GoodsPid, {'delete_more', GoodsTypeId, GoodsNum}) of
		    1 ->
			catch log:log_goods_use(PS#player_status.id, GoodsTypeId, GoodsNum),
			{forza, QiLing#status_qiling{forza = lists:keyreplace(ForzaOpen+1,1,QiLing#status_qiling.forza,{ForzaOpen+1,1,0,0})}};
		    Error -> [false, Error]
		end;
	    true ->
		[false, 0]
	end,
    case Result of
	[false, ErrorCode] -> [false, ErrorCode];
	{Type, NewQiLing} ->
	    case Type of
		forza ->
		    db:execute(io_lib:format(<<"insert into qiling set player_id=~p, attr_type=~p, attr_list='~s' on duplicate key update attr_list='~s'">>,[PS#player_status.id, 1, util:term_to_string(NewQiLing#status_qiling.forza), util:term_to_string(NewQiLing#status_qiling.forza)])),
		    catch lib_qiling:log_qiling(1, QiLing#status_qiling.forza, NewQiLing#status_qiling.forza, PS#player_status.id, 1);
		agile ->
		    db:execute(io_lib:format(<<"insert into qiling set player_id=~p, attr_type=~p, attr_list='~s' on duplicate key update attr_list='~s'">>,[PS#player_status.id, 2, util:term_to_string(NewQiLing#status_qiling.agile), util:term_to_string(NewQiLing#status_qiling.agile)])),
		    catch lib_qiling:log_qiling(2, QiLing#status_qiling.agile, NewQiLing#status_qiling.agile, PS#player_status.id, 1);
		wit ->
		    db:execute(io_lib:format(<<"insert into qiling set player_id=~p, attr_type=~p, attr_list='~s' on duplicate key update attr_list='~s'">>,[PS#player_status.id, 3, util:term_to_string(NewQiLing#status_qiling.wit), util:term_to_string(NewQiLing#status_qiling.wit)])),
		    catch lib_qiling:log_qiling(3, QiLing#status_qiling.wit, NewQiLing#status_qiling.wit, PS#player_status.id, 1);
		thew ->
		    db:execute(io_lib:format(<<"insert into qiling set player_id=~p, attr_type=~p, attr_list='~s' on duplicate key update attr_list='~s'">>,[PS#player_status.id, 4, util:term_to_string(NewQiLing#status_qiling.thew), util:term_to_string(NewQiLing#status_qiling.thew)])),
		    catch lib_qiling:log_qiling(4, QiLing#status_qiling.thew, NewQiLing#status_qiling.thew, PS#player_status.id, 1)
	    end,
	    PS#player_status{qiling_attr = NewQiLing}
    end.
%% 装备或者加经验
%% @return {Pos,#status_qiling{}} | [false, ErrorCode]
add_exp(PS, Type, Val) ->
    QiLing = PS#player_status.qiling_attr,
    GoodsPid = PS#player_status.goods#status_goods.goods_pid,
    case Type of
	1 ->
	    case add_type_exp(GoodsPid, QiLing#status_qiling.forza, Val) of
		[false, ErrorCode] -> [false, ErrorCode];
		{Pos, NewQiLing} ->
		    db:execute(io_lib:format(<<"insert into qiling set player_id=~p, attr_type=~p, attr_list='~s' on duplicate key update attr_list='~s'">>,[PS#player_status.id, Type, util:term_to_string(NewQiLing), util:term_to_string(NewQiLing)])),
		    spawn(fun() ->
				  log:log_goods_use(PS#player_status.id, 602101, 1),
				  lib_qiling:log_qiling(Type, QiLing#status_qiling.forza, NewQiLing, PS#player_status.id, 2)
			  end),
		    {Pos, QiLing#status_qiling{forza = NewQiLing}}
	    end;
	2 ->
	    case add_type_exp(GoodsPid, QiLing#status_qiling.agile, Val) of
		[false, ErrorCode] -> [false, ErrorCode];
		{Pos, NewQiLing} ->
		    db:execute(io_lib:format(<<"insert into qiling set player_id=~p, attr_type=~p, attr_list='~s' on duplicate key update attr_list='~s'">>,[PS#player_status.id, Type, util:term_to_string(NewQiLing), util:term_to_string(NewQiLing)])),
		    spawn(fun() ->
				  log:log_goods_use(PS#player_status.id, 602101, 1),
				  lib_qiling:log_qiling(Type, QiLing#status_qiling.agile, NewQiLing, PS#player_status.id, 2)
			  end),
		    {Pos, QiLing#status_qiling{agile = NewQiLing}}
	    end;
	3 ->
	    case add_type_exp(GoodsPid, QiLing#status_qiling.wit, Val) of
		[false, ErrorCode] -> [false, ErrorCode];
		{Pos, NewQiLing} ->
		    db:execute(io_lib:format(<<"insert into qiling set player_id=~p, attr_type=~p, attr_list='~s' on duplicate key update attr_list='~s'">>,[PS#player_status.id, Type, util:term_to_string(NewQiLing), util:term_to_string(NewQiLing)])),
		    spawn(fun() ->
				  log:log_goods_use(PS#player_status.id, 602101, 1),
				  lib_qiling:log_qiling(Type, QiLing#status_qiling.wit, NewQiLing, PS#player_status.id, 2)
			  end),
		    {Pos, QiLing#status_qiling{wit = NewQiLing}}
	    end;
	4 ->
	    case add_type_exp(GoodsPid, QiLing#status_qiling.thew, Val) of
		[false, ErrorCode] -> [false, ErrorCode];
		{Pos, NewQiLing} ->
		    db:execute(io_lib:format(<<"insert into qiling set player_id=~p, attr_type=~p, attr_list='~s' on duplicate key update attr_list='~s'">>,[PS#player_status.id, Type, util:term_to_string(NewQiLing), util:term_to_string(NewQiLing)])),
		    spawn(fun() ->
				  log:log_goods_use(PS#player_status.id, 602101, 1),
				  lib_qiling:log_qiling(Type, QiLing#status_qiling.thew, NewQiLing, PS#player_status.id, 2)
			  end),
		    {Pos, QiLing#status_qiling{thew = NewQiLing}}
	    end
    end.
%% @param: QiLingType:#status_qiling.forza|agile|wit|thew
%% @return: {Pos,#status_qiling.forza|agile|wit|thew} | [false,ErrorCode]
add_type_exp(GoodsPid, QiLingType, Val) ->
    case filter_empty_pos(QiLingType) of
	[] ->
	    {Pos,Open,OldLv,OldExp} = filter_min_lv_available(QiLingType),
	    case lists:keyfind(OldLv+1, 1, data_qiling:get_lv_up_config()) of
		false -> [false, 4];
		{_,NeedExp,_} ->
		    case gen_server:call(GoodsPid, {'delete_more', 602101, 1}) of
			1 ->
			    case OldExp + Val >= NeedExp of
				true -> {Pos, lists:keyreplace(Pos, 1, QiLingType, {Pos,Open,OldLv+1,OldExp+Val})};
				false -> {Pos, lists:keyreplace(Pos, 1, QiLingType, {Pos,Open,OldLv,OldExp+Val})}
			    end;
			Error -> [false, Error]
		    end
	    end;
	EmptyList ->
	    case gen_server:call(GoodsPid, {'delete_more', 602101, 1}) of
		1 ->
		    {Pos,Open,_,OldExp} = min_ex(EmptyList, 1),
		    {Pos, lists:keyreplace(Pos, 1, QiLingType, {Pos,Open,1,OldExp})};
		Error -> [false, Error]
	    end
    end.
%% @param: QiLing #status_qiling{}
calc_qiling_attr(QiLing) ->
    Forza = calc_qiling_attr_by_type(QiLing#status_qiling.forza),
    Agile = calc_qiling_attr_by_type(QiLing#status_qiling.agile),
    Wit = calc_qiling_attr_by_type(QiLing#status_qiling.wit),
    Thew = calc_qiling_attr_by_type(QiLing#status_qiling.thew),
    [Forza, Agile, Wit, Thew].
calc_qiling_attr_by_type(QiLingType) ->
    lists:foldl(fun({_,_,Lv,_}, Acc) ->
			case lists:keyfind(Lv, 1, data_qiling:get_lv_up_config()) of
			    false -> Acc;
			    {_,_,Val} -> Acc + Val
			end
		end, 0, QiLingType).
	
filter_empty_pos(AttrList) ->
    lists:filter(fun({_,Open,Lv,_}) ->
			 Open =:= 1 andalso Lv =< 0
		 end, AttrList).
filter_min_lv_available(AttrList) ->
    OpenList = lists:filter(fun({_,Open,_,_}) ->
				    Open =:= 1
			    end, AttrList),
    min_ex(OpenList, 3).
log_qiling(AttrType, OldList, NewList, PlayerId, OpType) ->
    Q = io_lib:format(<<"insert into log_qiling(player_id,attr_type,old_attr,new_attr,op_type) values(~p,~p,'~s','~s',~p)">>,[PlayerId, AttrType, util:term_to_string(OldList), util:term_to_string(NewList), OpType]),
    db:execute(Q).


min_ex([H|T], N) -> min_ex(T, H, N).

min_ex([H|T], Min, N) when element(N, H) < element(N, Min) -> min_ex(T, H, N);
min_ex([_|T], Min, N) -> min_ex(T, Min, N);
min_ex([], Min, _) -> Min. 



is_all_same([H|T], N) -> is_all_same(T, H, N).

is_all_same([H|T], Min, N) when element(N, H) =:= element(N, Min) -> is_all_same(T, H, N);
is_all_same(L, _, _) when L =/= [] -> false;
is_all_same([], _, _) -> true. 

