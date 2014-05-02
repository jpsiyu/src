%%%-------------------------------------------------------------------
%%% @Module	: data_qixi_text
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	: 23 Aug 2012
%%% @Description: 
%%%-------------------------------------------------------------------
-module(data_qixi_text).
-compile(export_all).

get_mail_title(Num) ->
    case Num of
	1 -> "天使降临，您是我们的魅力宝贝";
	2 -> "九九重阳连续登陆礼"
    end.
	    
get_mail_content(Num) ->
    case Num of
	1 ->
	    "亲爱的玩家：\n恭喜您在大闹天宫开学活动期间获得每日鲜花榜第一名，先送上超人气全服唯一奖励！天使宝贝，魅力无法阻挡！ ";
	2 ->
	    "亲爱的玩家：\n感谢您对大闹天宫的支持，您九九重阳活动期间连续登陆三天，大闹天宫额外赠送您好礼一份！祝您游戏愉快！ "
    end.
