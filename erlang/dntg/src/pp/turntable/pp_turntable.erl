%%%-------------------------------------------------------------------
%%% @Module	: pp_turntable
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 31 May 2012
%%% @Description: 转盘
%%%-------------------------------------------------------------------
-module(pp_turntable).
-include("unite.hrl").
-include("server.hrl").
-include("common.hrl").
-export([handle/3]).

%% 获取剩余次数
handle(62000, US, get_free) ->
    case mod_turntable:private_check_time() of
	true ->
	    try
		case mod_turntable:get_free(US#unite_status.id, US#unite_status.lv, US#unite_status.vip) of
		    {error, Code} ->
			Error = Code,
			FreeCnt = 0,
			ItemIDList = data_turntable:get_init_goods();
		    Cnt ->
			Error = 0,
			FreeCnt = Cnt,
			ItemIDList = data_turntable:get_init_goods()    %%初始化转盘物品ID
		end,
		%%发送剩余次数
		{ok, BinData} = pt_620:write(62000, [Error, FreeCnt, ItemIDList]),
		lib_unite_send:send_to_sid(US#unite_status.sid, BinData),

		%%发送累积铜币
		LastCoin = mod_turntable:get_acccoin(),
		{ok, BinData1} = pt_620:write(62003, [LastCoin]),
		lib_unite_send:send_to_sid(US#unite_status.sid, BinData1),

		%%发送火眼金睛
		case mod_turntable:get_last_ultimate_winner() of
		    false ->
			IsWin = 0,
			Winner = 0,
			WinnerName = list_to_binary(""),
			UltimateCoin = LastCoin;
		    Result ->
			IsWin = 1,
			{Winner, Name, UltimateCoin} = Result,
			case Name of
			    Name when is_binary(Name) ->
				WinnerName = Name;
			    _ ->
				WinnerName = list_to_binary(Name)
			end
		end,
		{ok, BinUltimate} = pt_620:write(62010, [IsWin, Winner, WinnerName, UltimateCoin]),
		lib_unite_send:send_to_sid(US#unite_status.sid, BinUltimate),

		%%发送最近8条item
		ItemList = mod_turntable:get_latest_item(),
		case ItemList =/= [] of
		    true ->
			F = fun(Record) ->
				    {player_goods,PlayerID, NickName, ItemID, Coin, _TS} = Record,
				    case NickName of
					NickName when is_binary(NickName) ->
					    Name1 = NickName;
					_ ->
					    Name1 = list_to_binary(NickName)
				    end,
				    {ok, BinData2} = pt_620:write(62001, [PlayerID, Name1, ItemID, Coin]),
				    lib_unite_send:send_to_sid(US#unite_status.sid, BinData2)
			    end,
			lists:foreach(F, ItemList);
		    false ->
			false
		end
	    catch
		Reason ->
		    util:errlog("pp_turntable_62000 error Reason=~p~n",[Reason])
	    end;
	false ->
	    []
    end;

%% 转盘请求
handle(62002, PS, request_play) ->
    case mod_turntable:private_check_time() of
	true ->
	    case catch mod_turntable:request_play(PS) of
		{error, Code} ->
		    {ok, BinData} = pt_620:write(62002, [Code, 0]),
		    mod_disperse:cast_to_unite(lib_unite_send, send_to_one, [PS#player_status.id, BinData]);
		Reply when is_list(Reply) ->
		    [ItemID, Coin] = Reply,
		    {ok, BinData} = pt_620:write(62002, [0, ItemID]),
		    mod_disperse:cast_to_unite(lib_unite_send, send_to_one, [PS#player_status.id, BinData]),
		    {ok, BinData1} = pt_620:write(62003, [Coin]),
		    mod_disperse:cast_to_unite(lib_unite_send, send_to_one, [PS#player_status.id, BinData1]);
		Reason ->
		    util:errlog("pp_turntable_62002 error Reason=~p~n",[Reason]),
		    {ok, BinData} = pt_620:write(62002, [3, 0]),
		    mod_disperse:cast_to_unite(lib_unite_send, send_to_one, [PS#player_status.id, BinData])
	    end;
	false ->
	    []
    end;

%% 更新累积铜币
handle(62003, US, get_acccoin) ->
    case mod_turntable:private_check_time() of
	true ->
	    case catch mod_turntable:get_acccoin() of
		LastCoin when is_number(LastCoin) ->
		    {ok, BinData} = pt_620:write(62003, [LastCoin]),
		    lib_unite_send:send_to_sid(US#unite_status.sid, BinData);
		Reason ->
		    util:errlog("pp_turntable_62003 error Reason=~p~n",[Reason])
	    end;
	false ->
	    []
    end;

%% 触发钱雨效果
handle(62005, _US, money_rain) ->
    ok;
%% 活动倒计时
handle(62006, _US, remain_time) ->
    ok;

%% 错误处理
handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_turntable no match", []),
    {error, "pp_turntable no match"}.

