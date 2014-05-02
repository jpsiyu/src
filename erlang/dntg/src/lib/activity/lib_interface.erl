%%%--------------------------------------
%%% @Module  : lib_interface
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.19
%%% @Description: 外部接口
%%%--------------------------------------

-module(lib_interface).
-include("card.hrl").
-include("server.hrl").
-compile(export_all).

%% 推广兑换礼包
%% CardType : 卡类型（暂时不需要判断这个类型）
%% CardNo : 卡号
%% 目前有两种情况会在推广兑换这里换取礼包
%% <1> 通用规则礼包
%% <2> 根据卡号在预先生成的表中查找卡号是否存在
%% 返回：{error, 错误码}，错误码有：
%%  1成功
%%  2卡号过长，
%%  3卡号错误
%%  4卡号已经被领取
%%  5卡号过期
%%  6操作太快
%%  7已经使用过同类卡号
%%  8卡号没有绑定礼包
%%  100 礼包数据不存在
%%  101 礼包状态为无效
%%  102 未到领取礼包时间
%%  103 已过了领取礼包时间
%%  104 礼包物品不存在
%%  105 背包格子不足
%%  999 领取礼包失败
trigger_card(PS, CardType, CardNo) ->
	NowTime = util:unixtime(),
    %% 先判断是不是通用规则礼包，取出礼包id
    CommonGiftId = private_check_card_no1(CardNo, PS#player_status.accname),
    if
		%% 福利面板合作推广礼包
		CardType =:= 100 ->
			%% 对卡号作基础检查
            case private_check_card(PS, CardNo, NowTime) of
                {ok, GiftId} ->
                    case lib_gift_new:get_gift_fetch_status(PS#player_status.id, GiftId) of
                        -1 ->
                            case private_fetch_gift(PS, CardNo, GiftId, NowTime) of
                                {ok, NewPS} ->
                                    {ok, NewPS, GiftId};
                                {error, ErrorCode} ->
                                    {error, ErrorCode};
                                {db_error, {error, ErrorCode}} ->
                                    {error, ErrorCode};
                                _ ->
                                    {error, 999}
                            end;
                        _ ->
                            %% 已经使用过同类卡号
                            {error, 7}
                    end;
                {error, ErrorCode} ->
                    {error, ErrorCode}
            end;
	
%% 			%% 对卡号作基础检查
%%             case private_check_card(PS, CardNo, NowTime) of
%%                 {ok, GiftId} ->
%% 					F = fun() ->
%% 						G = PS#player_status.goods,
%% 						case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
%% 							{ok, [ok, NewPS]} ->
%% 								db:execute(io_lib:format(?sql_card_update, [PS#player_status.id, PS#player_status.nickname, NowTime, 1, CardNo])),
%% 								{ok, NewPS};
%% 							{ok, [error, ErrorCode]} ->
%% 								{error, ErrorCode};
%% 							_ ->
%% 								{error, 999}
%% 						end
%% 					end,
%%                     case lib_goods_util:transaction(F) of
%%                         {ok, NewPS} ->
%%                             {ok, NewPS, GiftId};
%%                         {error, ErrorCode} ->
%%                             {error, ErrorCode};
%% 						{db_error,{error,ErrorCode}} ->
%% 							{error, ErrorCode};
%%                         _ ->
%%                             {error, 999}
%%                     end;
%%                 {error, ErrorCode} ->
%%                     {error, ErrorCode}
%%             end;

        %% 大于0表示是通用规则礼包
        CommonGiftId > 0 ->
            %% 判断是否已经领取过该礼包
            case lib_gift_new:get_gift_fetch_status(PS#player_status.id, CommonGiftId) of
                1 ->
                    {error, 7};
                _ ->
                    F = fun() ->
                        G = PS#player_status.goods,
                        case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, CommonGiftId}) of
                            {ok, [ok, NewPS]} ->
                                lib_gift_new:trigger_finish(PS#player_status.id, CommonGiftId),
                                {ok, NewPS, CommonGiftId};
                            {ok, [error, ErrorCode]} ->
                                {error, ErrorCode};
                            R ->
                                util:errlog("fetch_gift error!, Module=lib_interface, Fun=trigger_card, Error = ~p~n", [R]),
                                {error, 999}
                        end
                    end,
                    lib_goods_util:transaction(F)
            end;

        true ->
            %% 对卡号作基础检查
            case private_check_card(PS, CardNo, NowTime) of
                {ok, GiftId} ->
                    case lib_gift_new:get_gift_fetch_status(PS#player_status.id, GiftId) of
                        -1 ->
                            case private_fetch_gift(PS, CardNo, GiftId, NowTime) of
                                {ok, NewPS} ->
                                    {ok, NewPS, GiftId};
                                {error, ErrorCode} ->
                                    {error, ErrorCode};
                                {db_error, {error, ErrorCode}} ->
                                    {error, ErrorCode};
                                _ ->
                                    {error, 999}
                            end;
                        _ ->
                            %% 已经使用过同类卡号
                            {error, 7}
                    end;
                {error, ErrorCode} ->
                    {error, ErrorCode}
            end
    end.

%% 基本检查卡号是否可以使用
private_check_card(_PS, CardNo, NowTime) ->
	%% 判断是否操作时间过快，因为下面要操作数据库，避免被刷
	case util:check_length(CardNo, ?CARD_MAX_LENGTH) of
		true ->
			case db:get_row(io_lib:format(?sql_card_get_row, [CardNo])) of
				[CardExpire, GiftId, Status] ->
					case Status =:= 0 of
						true ->
							case CardExpire > 0 andalso CardExpire < NowTime of
								false ->
									case GiftId > 0 of
										true ->
											{ok, GiftId};
										_ ->
											%% 卡号没有绑定礼包
											{error, 8}
									end;
								_ ->
									%% 卡号过期
									{error, 5}
							end;
						_ ->
							%% 卡号已经被领取
							{error, 4}
					end;
				_ ->
					%% 卡号错误
					{error, 3}
			end;
		_ ->
			%% 长度过长
			{error, 2}
	end.

%% 领取礼包
private_fetch_gift(PS, CardNo, GiftId, NowTime) ->
	F = fun() ->
		G = PS#player_status.goods,
		case gen:call(G#status_goods.goods_pid, '$gen_call', {'fetch_gift', PS, GiftId}) of
			{ok, [ok, NewPS]} ->
				db:execute(io_lib:format(?sql_card_update, [PS#player_status.id, PS#player_status.nickname, NowTime, 1, CardNo])),
				lib_gift_new:trigger_finish(PS#player_status.id, GiftId),
				{ok, NewPS};
			{ok, [error, ErrorCode]} ->
				{error, ErrorCode};
			R ->
				util:errlog("fetch_gift error!, Module=lib_interface, Fun=private_fetch_gift, Error = ~p~n", [R]),
				{error, 999}
		end
	end,
   lib_goods_util:transaction(F).

%% 通用礼包规则判断
%% md5(key + game + server + username + type)
%% 返回：礼包id，如果为0表示卡号错误
private_check_card_no1(Card, AccName) ->
    GameName = "zxy",
    Key = data_gift_config:get_common_gift_key(),
	ServerIds = ["S0" | config:get_server_id()],
    case ServerIds of
		List when is_list(List) ->
            LastGiftId = 
            lists:foldl(fun([GiftType, GiftId], GId) ->
                TargetGiftId = 
                lists:foldl(fun(SId, ParGiftId) -> 
                    Md5 = string:to_lower(util:md5(lists:concat([Key, GameName, SId, AccName, "lb", GiftType]))),
					case Card =:= Md5 of
                        true ->
                            GiftId;
                        _ ->
                            ParGiftId
                    end
                end, 0, ServerIds),
                case TargetGiftId > 0 of
                    true ->
                        TargetGiftId;
                    _ ->
                        GId
                end
            end, 0, data_gift_config:get_common_rule_gift()),
            LastGiftId;
		_ ->
            0
	end.

