%% --------------------------------------------------------
%% @Module:           |pt_361
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-00-00
%% @Description:      |开箱子
%% --------------------------------------------------------
-module(pp_kaixiangzi).
-export([handle/3]).
-compile(export_all).
-include("goods.hrl").
-include("buff.hrl").
-include("figure.hrl").
-include("unite.hrl").
-include("common.hrl").
-include("server.hrl").

-define(JCCS, 1).
-define(JCLIMIT, 15).

handle(36101, PlayerStatus, [PackageId]) ->
	PlayerId = PlayerStatus#player_status.id,
	PackageList = get_pass_id_list(),
	case lists:keyfind(PackageId, 1, PackageList) of
		{GiftId, Type} ->
			case get_all_gift(Type) of
				[] ->
					ok;
				GiftList -> %% 生成奖励
					WishValue = get_wishvalue(PlayerId, GiftId),
					XYWPId = get_xy_gift(Type),
					ListStep1 = make_tuplelist(1, GiftList, [], XYWPId, WishValue),
					ListStep2 = new_sort(12, ListStep1),
					WishValue = get_wishvalue(PlayerId, GiftId),
					put({PlayerId, GiftId, list}, ListStep2),
					ListStep3 = [{Num2, GoodsTypeId2, GoodsNum2}||{Num2, GoodsTypeId2, GoodsNum2, _} <- ListStep2],
					{ok, BinData} = pt_361:write(36101, [1, WishValue, ListStep3]),
					lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
			end;
		_ ->
			ok
	end,
	ok;

handle(36102, PlayerStatus, [PackageId]) ->
	PlayerId = PlayerStatus#player_status.id,
	PackageList = get_pass_id_list(),
	case lists:keyfind(PackageId, 1, PackageList) of
		{GiftId, Type} ->
			case get({PlayerId, GiftId, list}) of
				undefined ->
					{ok, BinData} = pt_361:write(36102, [2, 0, 0, 0, 0]),
					lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
				ListGot -> 
					WishValue = get_wishvalue(PlayerId, GiftId),
					XYWPId = get_xy_gift(Type),
					GLList = [GL||{_, _, _, GL}<-ListGot],
					GLLimitStep1 = lists:sum(GLList),
					RandNum = util:rand(1, GLLimitStep1),
					case get_zjwp(ListGot, RandNum, WishValue, XYWPId) of
						{XHNum, GoodsGetId, GoodsGetNum} ->
							Go = PlayerStatus#player_status.goods,
                            case gen_server:call(Go#status_goods.goods_pid,{'delete_more', GiftId, 1}) of
                                1 ->
									case gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', [], [{GoodsGetId, GoodsGetNum}]}) of
										ok ->
											WishValueNew = case XYWPId =:= GoodsGetId of
												true ->
													0;
												false ->
													WishValue + 1
											end, 
											save_wishvalue(PlayerId, GiftId, WishValueNew),
										    erlang:erase({PlayerId, GiftId, list}),
											log_kaixiangzi(PlayerStatus#player_status.id, GoodsGetId, GoodsGetNum, GiftId),
											{ok, BinData} = pt_361:write(36102, [1, WishValueNew, XHNum, GoodsGetId, GoodsGetNum]),
											lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
										_ ->
											[Title, Content] = data_guild_text:get_mail_text(kaixiangzi),
											lib_mail:send_sys_mail_server([PlayerId], Title, Content, GoodsGetId, 1, 0, 0, GoodsGetNum, 0, 0, 0, 0),
										    {ok, BinData} = pt_361:write(36102, [3, 0, 0, 0, 0]),
											lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
								    end,
									lib_player:refresh_client(PlayerStatus#player_status.id, 2),
									CWLists = get_cw_list(),
									case lists:member(GoodsGetId, CWLists) of
										true ->
											lib_chat:send_TV({all}, 0, 2, 
															 [
															  "openRareItem", PlayerStatus#player_status.id, PlayerStatus#player_status.realm, PlayerStatus#player_status.nickname,
															  PlayerStatus#player_status.sex, PlayerStatus#player_status.career, 0, PackageId, GoodsGetId
															 ]
															);
										false ->
											skip
									end,
									ok;
                                Recv->
									case Recv =:= 2 orelse Recv =:= 3 of
										true -> %%没有物品或数量不足
											{ok, BinData} = pt_361:write(36102, [4, 0, 0, 0, 0]),
											lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
										false -> %% 无定义的错误类型
											{ok, BinData} = pt_361:write(36102, [0, 0, 0, 0, 0]),
											lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
									end
                            end;
						_R ->
							{ok, BinData} = pt_361:write(36102, [0, 0, 0, 0, 0]),
							lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
					end
			end;
		_ ->
			ok
	end,
	ok;

handle(36111, PlayerStatus, [GoodsIdIn]) ->
	case lib_goods_util:get_goods_by_id(GoodsIdIn) of
		Goods when erlang:is_record(Goods, goods) ->
			Goods = lib_goods_util:get_goods_by_id(GoodsIdIn),
			ExpireTime = Goods#goods.expire_time,
			GoodsTypeIdIn = Goods#goods.goods_id,
			NowTime = util:unixtime(),
			case ExpireTime > 0 andalso ExpireTime < NowTime of
				true ->
					{ok, BinData} = pt_361:write(36111, [0]),
					lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
				false ->
					case GoodsTypeIdIn >= ?FIGURE_GOODS_1 andalso GoodsTypeIdIn =< ?FIGURE_GOODS_2 of
						true ->
							Go = PlayerStatus#player_status.goods,
				            case gen_server:call(Go#status_goods.goods_pid,{'delete_one', GoodsIdIn, 1}) of
				                1 ->
									GoodsTypeId = case GoodsTypeIdIn =:= 523007 of
										true ->
											ListR = [523008, 523009, 523010, 523011, 523021, 523022, 523023, 523024],
											Rand2 = util:rand(1, erlang:length(ListR)),
											lists:nth(Rand2, ListR);
										false ->
											GoodsTypeIdIn
									end,
									NewS = lib_figure:use_figure_goods(PlayerStatus, GoodsTypeId),
									{ok, BinData} = pt_361:write(36111, [1]),
									lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
									{ok, NewS};
				                _->
									{ok, BinData} = pt_361:write(36111, [0]),
									lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
				            end;
						_ ->
							{ok, BinData} = pt_361:write(36111, [0]),
							lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
					end
			end;
		_ ->
			{ok, BinData} = pt_361:write(36111, [0]),
			lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData)
	end;

handle(36112, PlayerStatus, _) ->
    case lib_buff:match_three(PlayerStatus#player_status.player_buff, ?FIGURE_BUFF_TYPE, ?FIGURE_BUFF_ATTID, []) of
	%case lib_player:get_player_buff(PlayerStatus#player_status.id, ?FIGURE_BUFF_TYPE, ?FIGURE_BUFF_ATTID) of
 	 	[] -> 
			{ok, BinData} = pt_361:write(36112, [1]),
			lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData);
  		[BuffInfo] -> 
			%% 取消BUFF
			lib_player:del_buff(BuffInfo#ets_buff.id),
			buff_dict:delete_id(BuffInfo#ets_buff.id),
			NewBuffInfo = BuffInfo#ets_buff{end_time = 0}, 
			lib_player:send_buff_notice(PlayerStatus, [NewBuffInfo]),
			%% 处理属性
			BuffAttribute = lib_player:get_buff_attribute(PlayerStatus#player_status.id, PlayerStatus#player_status.scene),
            NewPlayerStatus = lib_player:count_player_attribute(PlayerStatus#player_status{buff_attribute = BuffAttribute}),
			lib_player:send_attribute_change_notify(NewPlayerStatus, 0),
			%% 处理形象
			NextPs = case data_figure:get(BuffInfo#ets_buff.goods_id) of
				[]-> 
					NewPlayerStatus;
				_Figure ->
                    NewPlayerStatusF = lib_figure:change(NewPlayerStatus, {0, 0}),
					NewPlayerStatusF
			end,
			{ok, BinData} = pt_361:write(36112, [1]),
			lib_server_send:send_to_sid(PlayerStatus#player_status.sid, BinData),
			{ok, NextPs}
 	end;

handle(Cmd, _PlayerStatus, _R) ->
    util:errlog("pp_kaixiangzi handle nomatch ~p error~n", [Cmd]).

get_zjwp(ListGot, RandNum, WishValue, XYWPId) ->
	case WishValue >= ?JCLIMIT of
		true ->
			case [{Num2, GoodsTypeId2, GoodsNum2}||{Num2, GoodsTypeId2, GoodsNum2, _} <- ListGot, GoodsTypeId2 =:= XYWPId] of
				[{Num, GoodsTypeId, GoodsNum}] ->
					{Num, GoodsTypeId, GoodsNum};
				_ ->
					get_zj(ListGot, RandNum, 0)
			end;
		false ->
			get_zj(ListGot, RandNum, 0)
	end.

get_zj([], _R1, _R2)->
	io:format("R ~p  ~p~n", [_R1, _R2]),
	error;
get_zj(ListGot, RandNum, Acc)->
	[ListGot0|ListGotT] = ListGot,
	{Num2, GoodsTypeId2, GoodsNum2, GL} = ListGot0,
	GLNow = GL + Acc,
	case RandNum =< GLNow of
		true ->
			{Num2, GoodsTypeId2, GoodsNum2};
		false ->
			get_zj(ListGotT, RandNum, GLNow)
	end.

get_pass_id_list()->
	[{532250,1}, {532251,2}].

get_all_gift(Type)->
	List = [
			[{112201,80}
			, {112704,20}
			, {601701,5}
			, {112302,5}
			, {206201,5}
			, {601501,90}
			, {112104,1}
			, {112303,20}
			, {112214,1}
			, {112304,1}
			, {111024,10}
			, {205201,1}],
			[ {112201,80}
			, {112202,20}
			, {112704,16}
			, {112705,4}
			, {601701,10}
			, {112105,1}
			, {601501,90}
			, {112303,20}
			, {112214,5}
			, {112304,10}
			, {111024,10}
			, {205301,1}]
		   ],
	case Type > erlang:length(List) of
		true ->
			[];
		false ->
			lists:nth(Type, List)
	end.

get_cw_list()->
	[112104,112105,112202,112705,601701].

get_xy_gift(Type)->
	List = [112104, 112105],
	case Type > erlang:length(List) of
		true ->
			0;
		false ->
			lists:nth(Type, List)
	end.

make_tuplelist(_, [], List2, _, _)->
	List2;
make_tuplelist(Num, List1, List2, XYWPId, WishValue)->
	[CNth0|ListT] = List1,
	{GTId, GL} = CNth0,
	GLNew = case GTId =:= XYWPId of
				true ->
					GL + WishValue * ?JCCS;
				false ->
					GL
			end,
	case Num =:= 1 of
		true ->
			make_tuplelist(Num + 1, ListT, [{Num, GTId, 1, GLNew}], XYWPId, WishValue);
		false ->
			make_tuplelist(Num + 1, ListT, [{Num, GTId, 1, GLNew}|List2], XYWPId, WishValue)
	end.
	
new_sort(0, List)->
	List;
new_sort(Num, List)->
	ChangDu = erlang:length(List),
	ChangeNum = util:rand(1, ChangDu),
	[CNth0|_ListT] = List,
	CNth1 = lists:keyfind(ChangeNum, 1, List),
	ListStep2 = lists:map(fun(NowIs) ->
					  case NowIs =:= CNth0 of
						  true ->
							  CNth1;
						  false ->
							  case NowIs =:= CNth1 of
								  true ->
									  CNth0;
								  false ->
									  NowIs
							  end
					  end
			  end, List),
	new_sort(Num - 1, ListStep2).


save_wishvalue(RoleId, GiftId, Value)->
	case db:transaction(fun() ->
								DataLow = [RoleId, GiftId],
							    SQLLow = io_lib:format("SELECT wish_count FROM player_wish WHERE roleid=~p and giftid=~p", DataLow),
								SQL = case db:get_one(SQLLow) of
									null ->
										io_lib:format("insert into player_wish(roleid, giftid, wish_count) values (~p,~p,~p)", [RoleId, GiftId, Value]);
									_WC ->
										io_lib:format("update player_wish set wish_count=~p WHERE roleid=~p and giftid=~p", [Value, RoleId, GiftId])
								end,
								db:execute(SQL),
								{ok, Value}
						end) of
		{ok, _} -> %% 插入缓存
			put({RoleId, GiftId, wishvalue}, Value),
			{ok, Value};
		R ->
			{error, R}
	end.

get_wishvalue(RoleId, GiftId)->
	case get({RoleId, GiftId, wishvalue}) of
		undefined ->
			DataLow = [RoleId, GiftId],
			SQLLow = io_lib:format("SELECT wish_count FROM player_wish WHERE roleid=~p and giftid=~p", DataLow),
			case db:get_one(SQLLow) of
				null ->
					save_wishvalue(RoleId, GiftId, 0),
					0;
				WC ->
					put({RoleId, GiftId, wishvalue}, WC),
					WC
			end;
		Value ->
			Value
	end.

log_kaixiangzi(PlayerId, GoodsId, GoodsNum, GiftId) ->
	NowTime = util:unixtime(),
	SQL = io_lib:format("insert into log_kaixiangzi(roleid, goods_id, goods_num, xiangzi_id, time) values (~p,~p,~p,~p,~p)", [PlayerId, GoodsId, GoodsNum, GiftId, NowTime]),
	db:execute(SQL),
	ok.
