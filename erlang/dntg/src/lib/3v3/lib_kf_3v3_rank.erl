%%%--------------------------------------
%%% @Module : lib_kf_3v3_rank
%%% @Author : calvin
%%% @Email : calvinzhong888@gmail.com
%%% @Created : 2013.3.1
%%% @Description : 跨服3v3排行榜相关
%%%--------------------------------------

-module(lib_kf_3v3_rank).
-include("rank.hrl").
-include("kf_3v3.hrl").
-compile(export_all).

%% 刷新本地周积分榜
refresh_bd_week_rank() ->
	List = db:get_all(io_lib:format(?SQL_BD_3V3_RANK_SELECT, [100])),
	ets:insert(
		?MODULE_RANK,
		#ets_module_rank{type_id = ?MODULE_RANK_1, rank_list = List}
	).

%% 获取本地周积分榜
get_bd_week_rank() ->
	case ets:lookup(?MODULE_RANK, ?MODULE_RANK_1) of
		[Rd] when is_record(Rd, ets_module_rank) ->
			case Rd#ets_module_rank.rank_list of
				undefined -> [];
				_ -> Rd#ets_module_rank.rank_list
			end;
		_ ->
			[]
	end.

%% 发送本地周积分榜奖励
send_bd_week_award() ->
	LimitDown = data_kf_3v3:get_config(bd_rank_award_score),
	case db:get_all(io_lib:format(?SQL_BD_3V3_RANK_ID, [LimitDown])) of
		[] ->
			skip;
		List ->
			Title = data_kf_text:get_bd_3v3_rank_title(),
			Content = data_kf_text:get_bd_3v3_rank_content1(),
			Content2 = data_kf_text:get_bd_3v3_rank_content2(),
			Content3 = data_kf_text:get_bd_3v3_rank_content3(),

			[_, L1, L2, L3, L4, L5] = 
			lists:foldl(fun([Id], [Position, List1, List2, List3, List4, List5]) ->
				if
					Position =:= 1 ->
						[Position + 1, [Id | List1], List2, List3, List4, List5];
					Position < 11 ->
						[Position + 1, List1, [Id | List2], List3, List4, List5];
					Position < 51 ->
						[Position + 1, List1, List2, [Id | List3], List4, List5];
					Position < 101 ->
						[Position + 1, List1, List2, List3, [Id | List4], List5];
					true ->
						[Position + 1, List1, List2, List3, List4, [Id | List5]]
				end
			end, [1, [], [], [], [], []], List),
			NewContent = io_lib:format(Content, [1]),
			private_send_gift_mail(L1, Title, NewContent, 535570),
			NewContent2 = io_lib:format(Content2, [2, 10]),
			private_send_gift_mail(L2, Title, NewContent2, 535571),
			NewContent3 = io_lib:format(Content2, [11, 50]),
			private_send_gift_mail(L3, Title, NewContent3, 535572),
			NewContent4 = io_lib:format(Content2, [51, 100]),
			private_send_gift_mail(L4, Title, NewContent4, 535573),
			NewContent5 = io_lib:format(Content3, [101]),
			private_send_gift_mail(L5, Title, NewContent5, 535574),

			spawn(fun() ->
				%% 清掉数据，再刷新一次榜单
				private_clean_bd_week_rank(),
				refresh_bd_week_rank()
			end)
	end.

%% 发送邮件
private_send_gift_mail(SendIds, Title, Content, GiftId) ->
	GoodsTypeId = lib_gift_new:get_goodsid_by_giftid(GiftId),
	case SendIds of
		[] -> skip;
		_ -> lib_mail:send_sys_mail_bg(SendIds, Title, Content, GoodsTypeId, 2, 0, 0, 1, 0, 0, 0, 0)
	end.

%% 清除本地3v3周榜数据
private_clean_bd_week_rank() ->
	db:execute(io_lib:format(?SQL_BD_3V3_RANK_TRUNCATE, [])).
