%%%-----------------------------------
%%% @Module  : data_guild_text
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_guild_text).
-export([get_mail_text/1, 
         get_guidboos_text/1,
         get_boss_name/1,
         get_boss_name2/1,
         get_wealth/0]).

get_mail_text(Type) ->
    case Type of 
		guild_apply_join ->
          Title    = "帮派加入申请",
          Content  = "玩家【~s】申请加入本帮派【~s】。",
          [Title, Content];
		guild_invite_join ->
          Title   = "帮派邀请",
          Content = "你被邀请加入帮派【~s】。",
          [Title, Content];
        guild_create ->
          Title     = "创建帮派",
          Content   = "恭喜英雄开山立派，创建帮派之后可以集结无数同道中人共创霸业！每个帮派均有属于自己的帮派大厅、帮派仓库、帮派频道，以及本帮专属的帮派神兽，恭贺建帮之喜，预祝马到功成！。",
          [Title, Content];
        guild_apply_disband ->
            Title     = "帮派被申请解散",
            Content   = "你的帮派【~s】被帮主申请解散。",
            [Title, Content];
        guild_cancel_disband ->
            Title     = "帮派解散被取消",
            Content   = "你的帮派【~s】被帮主取消解散。",
            [Title, Content];
        guild_auto_cancel_disband ->
            Title     = "帮派解散被取消",
            Content   = "你的帮派【~s】，解散申请连续【~p】天没有得到帮主确认，被自动取消解散。",
            [Title, Content];
        guild_disband ->
            Title     = "帮派已解散",
            Content   = "你的帮派【~s】已正式解散。",
            [Title, Content];
        guild_auto_disband ->
            Title     = "帮派面临解散",
            Content   = "你的帮派【~s】不够收取每日建设，【~p】天内再不升级，会被自动解散。",
            [Title, Content];
		guild_auto_disband2 ->
            Title     = "帮派面临解散",
            Content   = "你的帮派不够收取每日建设，面临解散",
            [Title, Content];
        guild_degrade ->
            Title     = "帮派自动降级",
            Content   = "你的帮派【~s】不够收取每日建设，已从【~p】级降到【~p】级。",
            [Title, Content];
		guild_level_1 ->
            Title     = "帮派自动降级",
            Content   = "您当前的帮派为【~p】级，【~p】天后如果还为【~p】级将被删除。",
            [Title, Content];
        guild_reject_apply ->
            Title    = "帮派申请被拒绝",
            Content  = "帮派【~s】拒绝了你的加入申请。",
            [Title, Content];
        guild_new_member ->
            Title    = "成功加入帮派",
            Content  = "恭喜你成功加入了帮派【~s】。",
            [Title, Content];
        guild_kickout ->
            Title   = "你被踢出帮派",
            Content = "你被踢出了帮派【~s】。",
            [Title, Content];
        guild_battle_apply ->
            Title     = "帮战报名通知",
            Content   = "本帮已成功报名~p月~p日~p点~p分举行的帮派战，请各位帮派成员准时参加。",
            [Title, Content];
        guild_battle_apply_tip ->
            Title     = "帮战报名提醒",
            Content   = "本场帮派战已结束，请您及时报名下一场帮派战，预祝您的帮派取得优异成绩。",
            [Title, Content];
        guild_battle_award ->
            Title     = "帮战礼盒",
            Content   = "你参加~p月~p日~p点~p分进行的帮战，帮派获得第~p名，个人战功位列帮派第~p，奖励礼盒一份。",
            [Title, Content];
        guild_battle_guild_award ->
            Title     = "本帮帮战奖励",
            Content   = "本帮参加~p月~p日~p点~p分进行的帮战，获得第~p名，帮派奖励已发到奖励仓库。",
            [Title, Content];                 
        guild_award_alloc ->
            Title     = "帮派奖励",
            Content   = "你获得了帮主分配的奖励，请在帮派奖励领取界面查收。",
            [Title, Content];
        guild_impeach_chief ->
            Title     = "帮主被弹劾",
            Content   = "本帮成员【~s】成功弹劾【~s】成为新任帮主。",
            [Title, Content];
        guild_demise_chief ->
            Title     = "帮主禅让",
            Content   = "【~s】已将帮主禅让给本帮成员【~s】。",
            [Title, Content];
        guild_merge ->
            Title     = "帮派合并成功",
            Content   = "帮派【~s】已成功合并到帮派【~s】。",
            [Title, Content];
        siege_battle_apply ->
            Title     = "城战报名通知",
            Content   = "本帮已成功报名~p月~p日~p点~p分举行的武陵城战，请各位帮派成员准时参加。",
            [Title, Content];
        siege_battle_award ->
            Title     = "城战礼盒",
            Content   = "你参加~p月~p日~p点~p分进行的武陵城战，奖励礼盒一份。",
            [Title, Content];
        siege_battle_guild_award ->
            Title     = "本帮城战奖励",
            Content   = "本帮参加~p月~p日~p点~p分进行的武陵城战，礼包奖励已发到奖励仓库。",
            [Title, Content];
		fortune_thank ->
            Title     = "您收到一份试炼答谢礼物",
            Content   = "帮派成员【~s】为感谢您帮忙将试炼任务刷新橙色品质，特意赠上厚礼表达感谢之情！ ",
            [Title, Content];
		ga_party_mail_1 ->
            Title     = "帮派仙宴",
            Content   = "【~s】慷慨解囊，将在~p点~p分于帮派驻地举办蟠桃仙宴。参加将有机会获得大量经验、历练和绑定铜币奖励，请准时参加",
			Title2     = "筹办福袋",
            Content2   = "特赠上筹办福袋（蟠桃仙宴）感谢您为帮派成员的慷慨解囊！",
            [Title, Content, Title2, Content2];
		ga_party_mail_2 ->
            Title     = "帮派仙宴",
            Content   = "【~s】慷慨解囊，将在~p点~p分于帮派驻地举办人参果仙宴。参加将有机会获得大量经验、历练和绑定铜币奖励，请准时参加",
			Title2     = "筹办福袋",
            Content2   = "特赠上筹办福袋（人参果仙宴）感谢您为帮派成员的慷慨解囊！",
            [Title, Content, Title2, Content2];
		ga_party_mail_3 ->
            Title     = "帮派仙宴",
            Content   = "【~s】慷慨解囊，将在~p点~p分于帮派驻地举办瑶池仙宴。参加将有机会获得大量经验、历练和绑定铜币奖励，请准时参加",
			Title2     = "筹办福袋",
            Content2   = "特赠上筹办福袋（瑶池仙宴）感谢您为帮派成员的慷慨解囊！",
            [Title, Content, Title2, Content2];
		ga_animal_booking ->
			Title = "帮派神兽",
			Content = "本帮派将在~p点~p分于帮派驻地挑战帮派神兽。参加将有机会获得大量经验和珍贵道具奖励，请准时参加",
			[Title, Content];
		ga_top_1 ->
            Title     = "守护神兽第一奖励",
            Content   = "恭喜您在守护神兽战斗中力压群雄，伤害输出排名第一！奖励超级神兽礼包一个(~p级别)",
            [Title, Content];
		ga_top_2 ->
            Title     = "守护神兽第二奖励",
            Content   = "恭喜您在守护神兽战斗中力压群雄，伤害输出排名第二！奖励超级神兽礼包一个(~p级别)",
            [Title, Content];
		ga_top_3 ->
          	Title     = "守护神兽第三奖励",
            Content   = "恭喜您在守护神兽战斗中力压群雄，伤害输出排名第三！奖励超级神兽礼包一个(~p级别)",
            [Title, Content];
		ga_roll_win ->
          	Title     = "守护神兽奖励",
            Content   = "恭喜您在守护神兽中掷出了【~p】点，赢得了奖励",
            [Title, Content];
		hbyj01 ->
          	Title     = "帮派合并",
            Content   = "您所在的帮派合并进入~s帮派，共图大业。",
            [Title, Content];
		ga_top_last ->
          	Title     = "神兽击最终击杀奖励",
            Content   = "恭喜您在守护神兽战斗中力压群雄，最终击杀神兽！奖励超级神兽礼包一个（~p级）。",
            [Title, Content];
        kaixiangzi ->
            Title     = "开启礼包",
            Content   = "您的背包已满，开启礼包获得XXX将通过邮件附件方式发送给您。",
            [Title, Content];
		qinmi_reward ->
            Title     = "帮派神兽亲密排行奖励",
            Content   = "恭喜你在本次召唤神兽时神兽亲密排行第~p，系统代表帮主特奖励你~p个“神兽亲密礼包”",
            [Title, Content];
		rela_normal_1 ->
            Title     = "帮派关系变更[普通]",
            Content   = "【~s】帮派将和您帮派的关系更改成普通",
            [Title, Content];
		rela_normal_2 ->
            Title     = "帮派关系变更[普通]",
            Content   = "您和【~s】帮派的关系更改成普通",
            [Title, Content];
		rela_friend ->
            Title     = "帮派关系变更[联盟]",
            Content   = "【~s】帮派和您的帮派结为联盟",
            [Title, Content];
		rela_enemy_1 ->
            Title     = "帮派关系变更[敌对]",
            Content   = "【~s】帮派将您帮派设为敌对关系",
            [Title, Content];
		rela_enemy_2 ->
            Title     = "帮派关系变更[敌对]",
            Content   = "您帮派将【~s】设为敌对关系 ",
            [Title, Content];
		open_guild_dun ->
			Title     = "帮派活动",
            Content   = "本周帮派活动将于周~s~p点~p分开启!",
            [Title, Content];
		guild_dun_award ->
			Title     = "恭喜,通过关卡",
            Content   = "恭喜您通过帮派活动闪电陷阱，特送上礼包一份，希望再接再厉! ",
            [Title, Content];
        guild_furance ->
            Title     = "帮派神炉返利",
            Content   = "领取帮派神炉返利铜钱~p!",
            [Title, Content]
    end.

get_guidboos_text(Type) ->
    case Type of
        guidboos_notice ->
            ["帮派驯兽场入口已经开启！各位兄弟请速速前往消灭帮派神兽！"];
        guidboos_notice2 ->
            ["被击败，留下神秘宝物，在帮派驯兽场内涌出大量经验！"];
        guidboos_notice3 ->
            ["本帮已成功击杀帮派神兽 ~s，你现在可尽情享受帮派篝火经验奖励，道具奖励已发放到帮派奖励仓库"];
        boss_kill ->
            ["厉害，~s 将 BOSS ~s 斩于马下！！"]
    end.

get_boss_name(Mid) ->
    case Mid of
        60101 ->
            "【BOSS】灵";
        60102 ->
            "【BOSS】妖";
        60103 ->
            "【BOSS】仙";
        60104 ->
            "【BOSS】魔";
        60105 ->
            "【BOSS】神";
        60111 ->
            "【BOSS】真神";
        60113 ->
            "【BOSS】玉兔";
        _ ->
            "【BOSS】灵"
   end.

get_boss_name2(Mid) ->
    case Mid of
        22043 ->
            "无双";
        99501 ->
            "苍狼王"
    end.

get_wealth() ->
    "帮派财富增加了".
