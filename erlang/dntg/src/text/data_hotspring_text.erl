%%%--------------------------------------
%%% @Module  : data_hotspring_text
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.5.7
%%% @Description: 温泉中文语言
%%%--------------------------------------

-module(data_hotspring_text).
-export([get_msg/1]).

get_msg(Type) ->
	case Type of
		1 ->
			<<"温馨提示：亲爱的玩家们，现在已经到了午饭时间，请记得在开心游戏的同时别忘记就餐哦！广陵温泉已经开放，大家可以在享受午餐的同时放松放松哦！">>;
		2 ->
			<<"温馨提示：亲爱的玩家们，现在已经到了午饭时间，请记得在开心游戏的同时别忘记就餐哦！广陵温泉已经开放，大家可以在享受午餐的同时放松放松哦！">>
	end.