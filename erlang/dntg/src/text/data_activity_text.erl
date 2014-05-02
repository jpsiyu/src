%%%--------------------------------------
%%% @Module  : data_activity_text
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.6.25
%%% @Description: 运营活动中文配置
%%%--------------------------------------

-module(data_activity_text).
-compile(export_all).

%% 收藏游戏奖励
collect_game_award(Type) ->
    case Type of
        email_title ->
            ["删档测试活动—游戏收藏奖励"];
        email_content ->
			 ["亲爱的玩家朋友：\n　　恭喜您！您已经成功收藏了《大闹天宫》，并获得了500绑定元宝奖励（绑定元宝可在【商城--绑定元宝专区】使用，购买强力道具）。赶快开始游戏，体验《大闹天宫》为您带来无限的乐趣吧！"]
    end.

%% 开服七天--玩家等级榜前10
seven_day_player_level(Type) ->
    case Type of
        title ->
            ["新服活动——等级榜前十奖励"];
        content ->
			 ["尊敬的玩家，开服活动已经结束，现在兑现奖励！在开服第7天24:00时，您的等级排名前十，获得冲级奖励！感谢您对大闹天宫的支持与青睐，我们必将不负众望。详情参考开服活动之“等级榜——冲级达人大作战”。"]
    end.

%% 开服七天--玩家战力榜前10
seven_day_player_power(Type) ->
    case Type of
        title ->
            ["新服活动——战力榜前十奖励"];
        content ->
			 ["尊敬的玩家，开服活动已经结束，现在兑现奖励！在开服第7天24:00时，您的战力排名前十，获得最强勇士奖励！感谢您对大闹天宫的支持与青睐，我们必将不负众望。详情参考开服活动之“战力榜——斗破苍穹，雄霸天下”。"]
    end.

%% 开服七天--玩家元神榜前10
seven_day_player_meridian(Type) ->
    case Type of
        title ->
            ["新服活动——元神榜前十奖励"];
        content ->
			 ["尊敬的玩家，开服活动已经结束，现在是兑现奖励的时候！在开服第7天24:00时，您在元神榜上排名前十，获得元神礼包！感谢您对大闹天宫的支持与青睐，我们必将不负众望。详情参考开服活动之“元神榜——无量天尊，洞破天机”。"]
    end.

%% 开服七天--宠物等级榜前10
seven_day_pet_level(Type) ->
    case Type of
        title ->
            ["新服活动——宠物等级榜前十奖励"];
        content ->
			 ["尊敬的玩家，开服活动已经结束，现在是兑现奖励的时候！在开服第7天24:00时，您的宠物等级排名前十，获得宠物等级礼包！感谢您对大闹天宫的支持与青睐，我们必将不负众望。详情参考开服活动之“宠物等级榜——御兽之术，神宠速成”。"]
    end.

%% 开服七天--宠物战力榜前10
seven_day_pet_power(Type) ->
    case Type of
        title ->
            ["新服活动——宠物战力榜前十奖励"];
        content ->
			 ["尊敬的玩家，开服活动已经结束，现在是兑现奖励的时候！在开服第7天24:00时，您的宠物战力排名前十，获得宠物战力礼包！感谢您对大闹天宫的支持与青睐，我们必将不负众望。详情参考开服活动之“宠物战力榜——人宠合一，羽化登仙”。"]
    end.

%% 开服七天--竞技场前3
seven_day_arena_fighting(Type) ->
    case Type of
        title ->
            ["开服活动之竞技场，奖励到了！"];
        content ->
			 ["尊敬的玩家，“开服活动之竞技场”已经结束，现在是兑现奖励的时候！在开服前三场的竞技中，您的积分排名前三，获得竞技礼包！感谢您对大闹天宫的支持与青睐，我们必将不负众望。详情参考开服活动之“最强竞技战——无上竞技，战火咆哮”。"]
    end.

%% 开服七天--帮派战前3
seven_day_guild_fighting(Type) ->
    case Type of
        title ->
            ["开服活动之帮派战，奖励到了！"];
        content ->
			 ["尊敬的玩家，“开服活动之帮派战”已经结束，现在是兑现奖励的时候！在开服前三场的帮派战中，您的帮派积分排名前三，获得帮派战帮主礼包！感谢您对大闹天宫的支持与青睐，我们必将不负众望。详情参考开服活动之“最强帮派战——无兄弟，不帮派”。"]
    end.

%% 开服七天--九重天霸主
seven_day_ninesky_dungeon(Type) ->
    case Type of
        title ->
            ["新服活动——霸主榜上有名奖励"];
        content ->
			 ["尊敬的玩家，开服活动已经结束，现在是兑现奖励的时候！开服前七天，您在九重天霸主榜上占据了一席之地，因此获得霸主礼包！感谢您对大闹天宫的支持与青睐，我们必将不负众望。详情参考开服活动之“最强霸主榜——征服九重天，称霸大闹天宫”。"]
    end.

%% 开服七天--成就榜前3
seven_day_player_achieve(Type) ->
    case Type of
        title ->
            ["新服活动——成就榜前三奖励"];
        content ->
			 ["尊敬的玩家，开服活动已经结束，现在是兑现奖励的时候！开服前七天，您的成就点数在全服排名前三，获得成就大奖！感谢您对大闹天宫的支持与青睐，我们必将不负众望。详情参考开服活动之“西游成就榜——我是成就控”。"]
    end.

%% 开服七天--帮派等级4级
seven_day_guild_level(Type) ->
    case Type of
        title ->
            ["开服7天了，奖励到账了！"];
        content ->
			 ["尊敬的玩家，现在是兑现奖励的时候！开服前七天，您的帮派等级达到4级以上，因此而获得奖励！感谢您对大闹天宫的支持与青睐，我们必将不负众望。详情参考开服活动之“帮派风采——我的帮派，我的家”。"]
    end.

%% 中秋国庆活动：魅力榜
get_middle_and_national_charm_title() -> ["明送秋波情意浓，榜上有名好礼到"].
get_middle_and_national_charm_content(1) -> ["亲爱的玩家，恭喜你在本次鲜花魅力榜活动中，魅力榜上有名,名列第一名，无上风姿迷倒万千玩家，送上好礼一份，请查收哦！"];
get_middle_and_national_charm_content(2) -> ["亲爱的玩家，恭喜你在本次鲜花魅力榜活动中，魅力榜上有名,名列第二名，无上风姿迷倒万千玩家，送上好礼一份，请查收哦！"];
get_middle_and_national_charm_content(3) -> ["亲爱的玩家，恭喜你在本次鲜花魅力榜活动中，魅力榜上有名,名列第三名，无上风姿迷倒万千玩家，送上好礼一份，请查收哦！"];
get_middle_and_national_charm_content(4) -> ["亲爱的玩家，恭喜你在本次鲜花魅力榜活动中，魅力榜上有名,名列第四至十名，无上风姿迷倒万千玩家，送上好礼一份，请查收哦！"].

%% 合服：战力榜争夺战，谁主沉浮，邮件标题
get_merge_power_rank_title() -> ["战力榜争夺战，谁主沉浮"].
get_merge_power_rank_content() -> ["战力榜争夺战，谁主沉浮战力榜争夺战，谁主沉浮战力榜争夺战，谁主沉浮"].

%% 合服活动：全服感恩回馈大礼包
get_merge_login_title() -> ["合服回馈奖励（全服感恩回馈大礼包）"].
get_merge_login_content() -> ["感谢大家对《大闹天宫》的支持！现为您送上合服回馈大礼包！"].

%% 合服活动：累积充值礼包
get_merge_recharge_gift_title(535201) -> ["累计充值奖励（合服88元礼包）"];
get_merge_recharge_gift_title(535202) -> ["累计充值奖励（合服288元礼包）"];
get_merge_recharge_gift_title(535203) -> ["累计充值奖励（合服588元礼包）"];
get_merge_recharge_gift_title(535204) -> ["累计充值奖励（合服988元礼包）"];
get_merge_recharge_gift_title(535205) -> ["累计充值奖励（合服1988元礼包）"];
get_merge_recharge_gift_title(535206) -> ["累计充值奖励（合服2988元礼包）"];
get_merge_recharge_gift_title(_) -> [""].
get_merge_recharge_gift_content() -> ["感谢大家对《大闹天宫》的支持！祝您游戏愉快！"].

%% 限时名人堂邮件标题：
get_fame_limit_title(8001) -> ["一掷千金达人榜榜上有名奖励到！"];
get_fame_limit_title(8002) -> ["淘宝达人榜榜上有名奖励到！"];
get_fame_limit_title(8003) -> ["练级狂人榜榜上有名奖励到！"];
get_fame_limit_title(8004) -> ["一代宗师榜榜上有名奖励到！"].

get_fame_limit_content(8001, 1) -> ["恭喜你在西游达人榜之一掷千金榜上榜上有名，位列第一，俯视众生，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8001, 2) -> ["恭喜你在西游达人榜之一掷千金榜上榜上有名，位列第二至十名，脱颖而出，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8001, 3) -> ["恭喜你在西游达人榜之一掷千金榜上榜上有名，位列第十一至五十名，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8001, 4) -> ["恭喜你在西游达人榜之一掷千金榜上榜上有名，位列第五十一至一百名，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8002, 1) -> ["恭喜你在西游达人榜之淘宝达人榜上榜上有名，位列第一，俯视众生，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8002, 2) -> ["恭喜你在西游达人榜之淘宝达人榜上榜上有名，位列第二至十名，脱颖而出，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8002, 3) -> ["恭喜你在西游达人榜之淘宝达人榜上榜上有名，位列第十一至五十名，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8002, 4) -> ["恭喜你在西游达人榜之淘宝达人榜上榜上有名，位列第五十一至一百名，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8003, 1) -> ["恭喜你在西游达人榜之练级狂人榜上榜上有名，位列第一，俯视众生，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8003, 2) -> ["恭喜你在西游达人榜之练级狂人榜上榜上有名，位列第二至十名，脱颖而出，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8003, 3) -> ["恭喜你在西游达人榜之练级狂人榜上榜上有名，位列第十一至五十名，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8003, 4) -> ["恭喜你在西游达人榜之练级狂人榜上榜上有名，位列第五十一至一百名，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8004, 1) -> ["恭喜你在西游达人榜之一代宗师上榜上有名，位列第一，俯视众生，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8004, 2) -> ["恭喜你在西游达人榜之一代宗师上榜上有名，位列第二至十名，脱颖而出，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8004, 3) -> ["恭喜你在西游达人榜之一代宗师上榜上有名，位列第十一至五十名，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(8004, 4) -> ["恭喜你在西游达人榜之一代宗师上榜上有名，位列第五十一至一百名，大闹天宫特此送上大礼一份，祝您游戏愉快！"];
get_fame_limit_content(_, _) -> [""].

%% 幸福回归活动 
back_activity(2) ->
	{"幸福回归，星级好礼连续拿", "亲爱的玩家，欢迎回到大闹天宫神奇世界！宝剑赠英雄，美酒筹知己，归来有惊喜，为您奉上豪礼一份！", 534077, 534078};
back_activity(3) ->
	{"幸福回归，充值玩家回归送大礼", "亲爱的玩家，欢迎回到大闹天宫神奇世界！您在本次幸福回归活动中首次充值获得好礼并获得百分之五充值返利，请查收哦！精彩可期待，祝您游戏愉快！", 534079, 0}.

get_1v1_week_award_title() -> "1V1竞技周积分第~p名奖励".
get_1v1_week_award_content() -> "恭喜你在上周的1V1竞技周积分排行中榜上有名，获得第 ~p 名。".

get_1v1_week_award_append_title() -> ["1V1竞技周积分达标奖励"].
get_1v1_week_award_append_content() -> ["恭喜你在上周的1V1竞技周积分榜中获得达标奖励，请再接再励。"].
									  

get_3v3_week_award_title() -> "3V3竞技MVP排行第~p名奖励".
get_3v3_week_award_content() -> "恭喜你在上周的3V3竞技MVP排行中榜上有名，获得第 ~p 名，获得MVP ~p 场。".

get_3v3_week_award_append_title() -> ["3V3竞技MVP排行达标奖励"].
get_3v3_week_award_append_content() -> ["恭喜你在上周的3V3竞技MVP排行中获得达标奖励，请再接再励。"].

get_player_consumption_reissue_title() -> "消费返礼礼包送到".
get_player_consumption_reissue_content() -> "亲爱的玩家，您在此次消费返礼活动中获得消费礼包尚未领取，现为您包邮到家，请查收哦！".

get_player_consume_returngold_title() -> "恭喜发财，红包送达".
get_player_consume_returngold_content() -> "亲爱的玩家，您在此次消费返红包活动中尚有红包未领取，现通过邮件发送给您，请您查收，祝游戏愉快！".

%% 跨服鲜花奖励
kf_flower_ranl(Type) ->
    case Type of
        title_count ->
            "累计跨服鲜花榜奖励到";
        title_daily ->
            "每日跨服鲜花榜奖励到";
        content_daily ->
			 "恭喜你在昨日跨服鲜花榜上榜上有名，名列第~p，获得丰厚奖励一份，请查收哦！";
        content_count ->
			"恭喜你在3月8日至10日三天的累计跨服鲜花榜榜上有名，名列第~p，获得丰厚奖励一份，请查收哦！"
    end.

get_notice_lamp_wish_max_title() -> "百花之王满载祝福至".
get_notice_lamp_wish_max_content() -> "亲爱的玩家，恭喜您载种的牡丹满载好友祝福，现在可以前往收获啦！您的牡丹坐标是(~p,~p)！".

get_notice_lamp_award_title() -> "繁花似锦牡丹收获礼".
get_notice_lamp_award_content() -> "亲爱的玩家，恭喜您您载种的牡丹满载好友祝福，在其怒放期间您未收获，系统代为收获，请查收！".

get_single_recharge_title() -> "充值惊喜礼包到".
get_single_recharge_content() -> "亲爱的玩家，您在本次单笔充值送惊喜活动中尚有未领取的礼包，系统为您包邮送上，请查收哦！".
    
get_festival_recharge_title() -> "充值好礼到".
get_festival_recharge_content() -> "亲爱的玩家，您在本次充值活动中尚有礼包未领取，系统为您包邮送上，请查收哦！".


%% 斗战封神活动奖励
kf_power_rank_all_title() -> "斗战封神战力奖励".
kf_power_rank_all_content() -> "亲爱的玩家，恭喜你战力超群，在斗战封神活动中，可获得对应战力奖励一份，由于你未在本次斗战封神活动期间领取，现系统为你包邮送上，请查收。".
kf_power_rank_top3_title() -> "斗战封神单服奖励".
kf_power_rank_top3_content() -> "亲爱的玩家，你当前的战力达很遗憾未能达到斗战封神战力奖励标准，但您的战力在本服傲视群雄，为您送上奖励一份，请查收。".


