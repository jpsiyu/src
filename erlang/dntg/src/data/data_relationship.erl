%%%-------------------------------------------------------------------
%%% @Module	: data_relationship
%%% @Author	: liangjianzhao
%%% @Email	: 298053832@qq.com
%%% @Created	:  5 Feb 2013
%%% @Description: 
%%%-------------------------------------------------------------------
-module(data_relationship).
-compile(export_all).

get_mail_title(Type) ->
    case Type of
	1 -> "新春拜年有惊喜";
	2 -> "新春拜年送惊喜";
	3 -> "拜年利是到";
	_ -> ""
    end.
	    
get_mail_content(Type,Name) ->
    case Type of
	1 -> lists:concat(["你为好友送上拜年祝福，获得惊喜一份，请查收哦。"]);
	2 -> lists:concat(["你的好友",Name,"为你送上拜年祝福同时，您获得拜年礼包一份，请查收哦！"]);
	3 -> lists:concat(["您为好友",Name,"送上新年拜年祝福，让TA极为感动，回赠您拜年利是，请查收哦！"]);
	_ -> ""
    end.
