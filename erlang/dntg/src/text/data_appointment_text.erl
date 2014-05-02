%%%-----------------------------------
%%% @Module  : data_appointment_text
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_appointment_text).
-export([get_sys_msg/1,
         get_sys_mail/2,
         get_log_consume_text/2,
         get_question_text/0]).

get_sys_msg(Type) ->
    case Type of
        1 ->
            ["正在约会中，不能放弃该任务！"];
        2 ->
            ["系统刚刚检测到您使用非法软件进行操作，影响游戏公平性，取消本次答题奖励！"];
        3 ->
            ["你们共同答对了~p道趣味题目，增加~p%的经验奖励"]
    end.

get_sys_mail(Type, Sex) ->
    case Type of
        2 ->
            case Sex =:= 1 of
                true ->
                    ["您收到了一份仙侣奇缘礼物", " 送给你一份 琉璃凤钗！期待与你共谱一段仙侣奇缘！"];
                false ->
                    ["您收到了一份仙侣奇缘礼物", " 送给你一份 同心玉佩！期待与你共谱一段仙侣奇缘！"]
            end;
        1 ->
            case Sex =:= 1 of
                true ->
                    ["您收到了一份仙侣奇缘礼物", " 送给你一份 沉香玉镯！期待与你共谱一段仙侣奇缘！"];
                false ->
                    ["您收到了一份仙侣奇缘礼物", " 送给你一份 五彩香囊！期待与你共谱一段仙侣奇缘！"]
            end;
        3 ->
            ["一份特别的礼物！", "您的亲密好友 ", " 在仙侣奇缘中送给你一份特别的礼物！"]
    end.

get_log_consume_text(Type, SubType) ->
    case Type of
		xlqy_game ->
			["仙侣奇缘种花游戏奖励元宝刷新"];
        xlqy_item ->
            case SubType of
                gold ->
                    ["仙侣奇缘元宝赠送"];
                coin ->
                    ["仙侣奇缘铜钱赠送"]
            end;
        xlqy_bang ->
            ["仙侣奇缘亲密度赠送"];
        xlqy_log ->
            ["仙侣奇缘元宝刷新"]
    end.

get_question_text() ->
    [<<"心有灵犀互动游戏即将开始，您是否参与？\n（本环节将测试双方配合默契度，通过互相配合完成小游戏可以增加默契度，并得到额外奖励）">>, <<"是">>, <<"否">>].