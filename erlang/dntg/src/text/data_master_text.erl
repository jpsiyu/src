%%%-----------------------------------
%%% @Module  : data_master_text
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_master_text).
-export([get_master_mail_text/1,
         get_master_mail_text/2]).

get_master_mail_text(SubjectType) ->
    get_master_mail_text(SubjectType, 0).

get_master_mail_text(SubjectType, EvaluateType) ->
    case SubjectType of
        master_apply ->
            Title   = "拜师申请",
            Content = "您已经成功向【~s】发出拜师申请，你们现在是准师徒关系，请耐心等待您师傅的批准确认。在准师徒关系时，您也可以正常汇报成绩，领取升级奖励，师傅离线也不影响正常汇报。所以请务必努力争取成为一名合格的正式徒弟。";
        master_apply_join ->
            Title   = "拜师成功",
            Content = "恭喜您成为【~s】的徒弟。请努力升级，您在20级、30级以及出师时都可以获得相应的礼包奖励。与师傅组队打怪可额外获得经验奖励。在您升级的时候，点击【K】键打开师徒面板进行【成绩汇报】，可以获得大量经验奖励。";
        master_apply_reject ->
            Title   = "拜师被拒绝",
            Content = "玩家【~s】拒绝了您的拜师申请，认为您达不到作为他徒弟的标准。建议您在拜师前先与师傅交谈，表现您拜师的诚意，这样可以增加拜师成功的机会。";
        master_finish ->
            Title   = "徒弟出师",
            Content = case EvaluateType of
                        1 -> "徒弟【~s】成功出师，给您的评价是[态度很好，帮助极大]，您获得了200师道值和出师礼包奖励。";
                        2 -> "徒弟【~s】成功出师，给您的评价是[态度较好，有点帮助]，您获得了100师道值和出师礼包奖励。";
                        _ -> "徒弟【~s】成功出师，给您的评价是[没有优点，没有缺点]，您获得了出师礼包奖励。"
                      end;
        master_finish0 ->
            Title   = "徒弟出师",
            Content = "徒弟【~s】成功出师，给您的评价是[他就一打酱油的]，您不能获得徒弟出师奖励。";
        master_finish1 ->
            Title   = "出师成功",
            Content = "恭喜你成功出师，获得出师礼包奖励。";
        master_kickout ->
            Title   = "逐出师门",
            Content = "你被师傅【~s】逐出了师门。";
        master_quit ->
            Title   = "退出师门",
            Content = "你徒弟【~s】退出了师门。";
        master_report_hint ->
            Title   = "汇报成绩",
            Content = "恭喜您达到【~p】级，及时向师父汇报成绩可以获得大量经验奖励。点击键盘快捷键【K】可以打开师徒汇报界面。";
        master_finish_hint ->
            Title   = "出师提示",
            Content = "恭喜您达到【~p】级，可以在本国国都的师徒NPC处出师，出师后可以获得出师礼包。";
        master_invite_join ->
            Title   = "拜师邀请成功",
            Content = "恭喜您收【~s】为徒弟。请努力帮助徒弟升级，徒弟升级汇报，你可获得经验和师道值奖励。带徒弟组队打怪，也可额外获得经验奖励。";
        master_first_join1 ->
            Title   = "首次拜师礼包",
            Content = "恭喜您成为【~s】的徒弟，这是代表您师傅送给您的见面礼。请努力升级，您在20级、30级以及出师时都可以获得相应的礼包奖励。与师傅组队打怪可额外获得经验奖励。";
        master_invite_reject ->
            Title   = "拜师邀请被拒",
            Content = "玩家【~s】拒绝了你的拜师邀请。";
        master_uplevel_award ->
            Title   = "徒弟升级",
            Content = "恭喜您的徒弟【~s】达到【~p】级，请继续努力帮助他快速出师。";
        master_uplevel_20_award1 ->
            Title   = "徒弟升级奖励礼包",
            Content = "恭喜您达到【~p】级，获得升级奖励礼包。";
        master_uplevel_30_award1 ->
            Title   = "徒弟升级奖励礼包",
            Content = "恭喜您达到【~p】级，获得升级奖励礼包。";
        master_auto_cancel_register ->
            Title   = "伯乐榜登记失效",
            Content = "您在伯乐榜登记已经超过【~p】天，系统自动帮您下榜；如有需要，可以点击【K】键打开师徒面板、切换到伯乐榜界面再次登记。"
    end,
    [Title, Content].

