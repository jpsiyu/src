%%------------------------------------------------------------------------------
%% @Module  : data_quiz
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.9.7
%% @Description: 答题配置
%%------------------------------------------------------------------------------
-module(data_quiz).
-compile(export_all).

%% 基础数据配置
get_quiz_config(Type)->
	case Type of
        % 邮件标题
        title1 -> "智力大PK， 答题勇夺魁";
        % 邮件内容
        content1 -> "亲爱的玩家：\n恭喜您在本次智力答题活动中榜上有名，挑战智力高峰，在全服玩家中脱颖而出，成为您恩师的骄傲哦！大闹天宫送上大礼一份，祝贺你啦！";
		_ ->void
	end.
