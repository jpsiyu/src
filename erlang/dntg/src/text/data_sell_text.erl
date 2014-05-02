%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-8
%% Description: TODO:
%% --------------------------------------------------------
-module(data_sell_text).
-compile(export_all).

mail_text(Type) ->
    case Type of
        gold ->
            Title = "您成功挂售了[~s]",
            Content = "您成功挂售了[~s]，获得了~p元宝，请注意收取附件";
        coin ->
            Title = "您成功挂售了[~s]",
            Content = "您成功挂售了[~s]，获得了~p铜币，请注意收取附件";
        send ->
            Title = "感谢信",
            Content = "~s, 为了感谢您，将他的英雄任务刷新成为橙色，特意奉上【~s】作为答谢礼物，请及时查收。";
        sell ->
            Title = "您挂售的【~s】已过期下架",
            Content = "您的【~s】超过挂售时间，无人购买，现退还给您，请注意收取附件";
		gs_alarm ->
            Title = "市场挂售到期",
            Content = "您在市场挂售的【~s】拍卖时间已过，请尽快在[我的上架]中再次挂售或者取回物品"
    end,
    [Title, Content].

mail_sys() ->
    <<"系统">>.

goods_name(Type) ->
    if 
        Type =:= 1 ->
            <<"铜钱">>;
        Type =:= 0 ->
            <<"元宝">>;
        true ->
            <<>>
    end.

vip_name(Type) ->
    if
        Type =:= 1 ->
            "黄金";
        Type =:= 2 ->
            "白金";
        Type =:= 3 ->
            "钻石";
        true ->
            "黄金"
    end.

vip_text(Type) ->
    if
        Type =:= 1 ->
            Title = "VIP到期邮件提醒",
            Content = "亲爱的大闹天宫朋友，您的~sVIP已到期，相应的VIP福利将无法使用，我们诚邀您再次回到VIP家族。",
            [Title, Content];
        Type =:= 2 ->
            Title = "恭喜您成为尊贵的黄金VIP会员",
            Content = "恭喜您成为尊贵的黄金VIP会员，您可立即享受多倍经验、强化加成、免费飞行等超多特权福利，您还可免费获得一个价值420元宝的黄金VIP礼包",
            [Title, Content];
        Type =:= 3 ->
            Title = "恭喜您成为尊贵的白金VIP会员",
            Content = "恭喜您成为尊贵的白金VIP会员，您可立即享受多倍经验、强化加成、免费飞行等超多特权福利，您还可免费获得一个价值680元宝的白金VIP礼包",
            [Title, Content];
        Type =:= 4 ->
            Title = "恭喜您成为尊贵的钻石VIP会员",
            Content = "恭喜您成为尊贵的钻石VIP会员，您可立即享受多倍经验、强化加成、免费飞行等超多特权福利，您还可免费获得一个价值1350元宝的钻石VIP礼包",
            [Title, Content];
        Type =:= 5 ->
            "获得绑定元宝 ~p";
        Type =:= 6 ->
            "获得绑定铜钱 ~p";
        Type =:= 7 ->
            "获得 黄金VIP礼包";
        Type =:= 8 ->
            "获得 白金VIP礼包";
        Type =:= 9 ->
            "获得 钻石VIP礼包";
        Type =:= 10 ->
            "领取VIP祝福成功";
        true ->
            skip
    end.

goods_text(Type) ->
    case Type of
        1 ->
            "您的[";
        2 ->
            "时装]已经过期，请您在衣橱里查看，强化至+7以后可以继续使用。";
        3 ->
            "过期提醒"
    end.
            
    
        
    





