%%%-----------------------------------
%%% @Module  : data_mail_log_text
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_mail_log_text).
-export([get_mail_log_text/1]).

get_mail_log_text(SubjectType) ->
    case SubjectType of
		plat_b->"本服";
		plat_w->"外域";
		server->"服";
		god_title_sea_1->"海选赛奖励-制胜礼包";
		god_title_sea_2->"海选赛奖励-参与礼包";
		god_title_sea_3->"海选赛奖励-跨服勋章";
		god_title_group_1->"小组赛奖励-制胜礼包";
		god_title_group_2->"小组赛奖励-排名礼包";
		god_title_group_3->"小组赛奖励-跨服勋章";
		god_title_relive_1->"复活赛奖励-霸者之心";
		god_title_relive_2->"复活赛奖励-参与礼包";
		god_title_relive_3->"复活赛奖励-跨服勋章";
		god_title_sort_1->"总决赛奖励-排名礼包";
		god_title_sort_2->"总决赛奖励-跨服勋章";
		god_title_sort_3->"总决赛奖励-惊天战神";
		god_title_sort_4->"总决赛奖励-信仰之神";
		god_title_sea->
			"诸天仙道大会之海选赛";
		god_content_sea->
			"感谢您对诸天仙道大会的支持，现根据您的战场表现发放奖励。本场参与比赛共~p场，胜利~p场，获得积分~p,排名第~p名。";
		god_content_sea2->
			"您已经成功小组晋级，无法参加本场海选，现发放补偿奖励。";
		god_title_sea3->
			"诸天仙道大会之海选赛晋级成功";
		god_content_sea3->
			"恭喜您，您以排名第~p晋级小组赛成功。";
		god_title_sea4->
			"诸天仙道大会之海选赛晋级失败";
		god_content_sea4->
			"很遗憾，您以排名第~p名晋级小组赛失败，请在下一场海选赛中再接再厉！";
		god_title_group->
			"诸天仙道大会之小组赛";
		god_content_group->
			"感谢您对诸天仙道大会的支持，现根据您的战场表现发放奖励。本场参与比赛共~p场，胜利~p场，获得积分~p,排名第~p名。";
		god_title_group2->
			"诸天仙道大会之小组赛";
		god_content_group2->
			"还有下一场小组赛，将在最后一场小组赛结束后结算";
		god_title_group3->
			"诸天仙道大会之小组赛晋级成功";
		god_content_group3->
			"恭喜您，您以小组排名第~p晋级总决赛成功。";
		god_title_group4->
			"诸天仙道大会之小组赛晋级失败";
		god_content_group4->
			"恭喜您，您以小组排名第~p晋级小组赛失败。请参与下一场复活赛或人气赛。";
		god_title_relive->
			"诸天仙道大会之复活赛";
		god_content_relive->
			"感谢您对诸天仙道大会的支持，现根据您的战场表现发放奖励。本场参与比赛共~p场，胜利~p场，获得积分~p,排名第~p名。";
		god_title_relive2->
			"诸天仙道大会之复活赛";
		god_content_relive2->
			"将在最后人气赛截止时当天24时结算";
		god_title_relive3->
			"诸天仙道大会之复活赛晋级成功";
		god_content_relive3->
			"恭喜您，您以排名第~p晋级总决赛成功。";
		god_title_relive4->
			"诸天仙道大会之复活赛晋级失败";
		god_content_relive4->
			"恭喜您，您以排名第~p晋级小组赛失败。";
		god_title_relive5->
			"诸天仙道大会之复活赛晋级成功";
		god_content_relive5->
			"恭喜您，您以复活赛排名第~p,人气PK前3名晋级总决赛成功。";
		god_title_vote_relive6->
			"诸天仙道大会之人气PK猜中奖励";
		god_content_vote_relive6->
			"人气PK前3名分别是：~s，恭喜仙友神机妙算猜中~p注，奖励请查收。";
		god_title_vote_relive7->
			"诸天仙道大会之人气PK未猜中奖励";
		god_content_vote_relive7->
			"人气PK前3名分别是：~s，仙友共有~p注未能猜中，感谢您的参与，奖励请查收。";
		god_title_sort->
			"诸天仙道大会之总决赛";
		god_content_sort->
			"感谢您对诸天仙道大会的支持，现根据您的战场表现发放奖励。本场参与比赛共~p场，胜利~p场，获得积分~p,总决赛排名第~p名。";
		god_content_sort22->
			"感谢您对诸天仙道大会的支持，现根据您的战场表现发放奖励。本场参与比赛共~p场，胜利~p场，获得积分~p,总积分排名第~p名。";
		god_content_sort3->
			"感谢您对诸天仙道大会的支持，现根据您的战场表现发放奖励。本场参与比赛共~p场，胜利~p场，获得积分~p,人气投票排名第~p名。";
		god_title_sort2->
			"诸天仙道大会之总决赛";
		god_content_sort2->
			"还有下一场总决赛，将在最后一场总决赛结束后结算";
		arena_title->
			"竞技场第一奖励";
		arena_content->
			"恭喜您获得今天竞技场第一，并获得全服唯一的坐骑变幻劵一张。";
		peach_title->
			"蟠桃会奖励";
		peach_content->
			"恭喜您在蟠桃会中获得~p个蟠桃，奖励如下：宝石碎片~p个（发放奖励的同时清空了您的蟠桃数）";
		peach_title2->
			"蟠桃会翻牌奖励";
		peach_content2->
			"恭喜您找回蟠桃会的部分损失，总计~p个宝石碎片。";
		kf_1v1_title2->
			"1V1竞技排名第~p名奖励";
		kf_1v1_content2->
			"恭喜你在这一轮的1V1竞技比赛中榜上有名，获得第 ~p名。";
		kf_1v1_title->
			"1V1竞技参与奖励";
		kf_1v1_content->
			"恭喜在参与本轮1V1竞技~p场比赛中获胜~p场，失败了~p场，累积获得跨服竞技勋章x~p奖励。";
		bless_title->
			"祝福回赠";
		bless_content->
			<<"您的好友~s赠送了~s，作为祝福答谢礼物。">>;
		factionwar_title->
			"帮战奖励";
		factionwar_content->
			"在本次帮战中，你所在帮派排名第~p，帮内战功前~p名玩家获得~p个帮战礼包奖励。";
		factionwar_title2->
			"帮战斗神榜奖励";
		factionwar_content2->
			"您在本次帮战中共击杀~p人，斗神榜排名第~p，获得~p个帮战礼包奖励。";
        log_mail_info ->
            "发信邮资~p, 附件铜币~p";
        log_get_money ->
            "收取附件 发件人Id: ~p MailId:~p 发件:~p";
		log_ban_mail ->
            "邮件超出正常封号"
    end.