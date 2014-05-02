%%%--------------------------------------
%%% @Module  : data_activity
%%% @Author  : zzm
%%% @Email   : ming_up@163.com
%%% @Created : 2013.8.2
%%% @Description: uc相关活动和代码变更
%%%--------------------------------------

-module(lib_uc).
-include("server.hrl").
-include("guild.hrl").
-compile(export_all).

-define(ACTIVITY_BEGIN_TIME, {{2013,8,14},{0,0,0}}).
-define(ACTIVITY_ENd_TIME,   {{2013,8,21},{0,0,0}}).

%% 总开关
switch(F, Arg) -> 
    Now   = util:unixtime(),
    Begin = util:unixtime(?ACTIVITY_BEGIN_TIME),
    End   = util:unixtime(?ACTIVITY_ENd_TIME),
    case Now >= Begin andalso Now =< End of
        true ->  erlang:apply(lib_uc, F, Arg);
        false -> skip
    end.

%% 活动1 首次登陆送元宝(pp_login)
create_role_send_gold(Id) -> 
    lib_mail:send_sys_mail(Id, "删档测试活动—创建角色奖励", "亲爱的玩家朋友：\n    恭喜您！您已成功的在《大闹天宫》的世界中创建了角色，并获得了3000元宝奖励（元宝可在【商城】使用，购买强力道具）。随着您的角色等级的提升，您将结识更多的朋友，体验更多的功能，还将有更多的惊喜等着您哦！\n   怎么样？是不是很期待呢？那就赶紧行动", 0, 0, 0, 3000),

    lib_mail:send_sys_mail([Id], "首次登陆系统邮件", "尊敬的玩家：\n    大家好，首先祝贺各位成为《大闹天宫》的第一批测试玩家，也感谢大家对我们《大闹天宫》的支持。我们的游戏目前是删档测试，大家在游戏里有什么问题可以在【设置-GM】咨询客服或者加入玩家交流qq群，群号：163508459，祝大家游戏愉快。").

%% 活动2 每天登陆送元宝
login_daily_send_gold(Id, ContinuousDays) ->
    Gold = case ContinuousDays of
        0 -> 0;
        1 -> 500;
        2 -> 800;
        3 -> 1200;
        _ -> 1200
    end,
    case Gold > 0 of
        true  -> lib_mail:send_sys_mail(Id, "删档测试活动—每日登陆奖励", "亲爱的玩家朋友：\n   恭喜您！为了感谢您对《大闹天宫》的支持，我们将送出500-1200元宝奖励（元宝可在【商城】使用，购买强力道具）。首次删档测试活动期间，每天首次登陆，都将获得丰厚的奖励哦！\n   期待明天再次与您见面！", 0, 0, 0, Gold);
        false -> skip
    end,

    lib_mail:send_sys_mail([Id], "欢迎来到《大闹天宫》", "欢迎大家来到《大闹天宫》~加入QQ交流群163508459，可以及时反馈大家的意见和游戏问题哦~ \n 也可以通过游戏下方【设置-GM】按钮，和UC《大闹天宫》论坛将意见反馈给我们哦~我们会及时查看！\n \n《大闹天宫》团队敬上").

%% 活动3 签到送好礼
%% 充值和非充值礼包调整为一样
%% data_activity:get_seven_day_login_gift/1

%% 活动4 新手礼包
%% 去掉新手cd-key验证

%% 活动5 四十而立
lv_40_send_gold(Id, Lv) -> 
    case Lv == 40 of
        true  -> 
            EndTime = util:unixtime(?ACTIVITY_BEGIN_TIME) + 24*60*60,
            Now     = util:unixtime(),
            case Now =< EndTime of
                true -> 
                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Id], "40级奖励", "亲爱的玩家朋友：\n    恭喜您已成功升级到40级，并获得1000元宝和250000W铜币奖励，（元宝可在【商城】使用，购买强力道具）。随着您的角色等级的提升，您将结识更多的朋友，体验更多的功能，还将有更多的惊喜等着您哦！", 0, 0, 0, 0, 0, 0, 250000, 0, 1000]);
                false -> skip
            end;
        false -> skip
    end.

%% 活动6 我的帮派，我们的家
guild_lv_4_send_gold(GuildId) -> 
    spawn(fun() -> 
            GuildMemberList         = lib_guild_base:get_guild_member_by_guild_id(GuildId),
            GuildMemberListLvMore40 = [Member#ets_guild_member.id || Member <- GuildMemberList, Member#ets_guild_member.level >= 40, Member#ets_guild_member.position /=1],
            GuildMaster             = [Member#ets_guild_member.id || Member <- GuildMemberList, Member#ets_guild_member.level >= 40, Member#ets_guild_member.position == 1],
            %% 大于40级的帮众
            %send_sys_mail_bg(PlayerInfoList, Title, Content, GoodsTypeId, Bind, Stren, Prefix, GoodsNum, BCoin, Coin, Silver, Gold)
            case GuildMemberListLvMore40 of
                [] -> skip;
                _ -> 
                    lib_mail:send_sys_mail_bg(GuildMemberListLvMore40, "帮派等级奖励", "亲爱的帮众：\n    恭喜您的帮派已成功升级到4级，并获得1000元宝奖励，（元宝可在【商城】使用，购买强力道具）。继续为帮派贡献，提升帮派实力，您将获得更多的朋友，体验更多的功能，还将有更多的惊喜等着您哦！", 0, 0, 0, 0, 0, 0, 0, 0, 1000)
            end,
            %% 帮主
            case GuildMaster of
                [] -> skip;
                _ -> 
                    lib_mail:send_sys_mail_bg(GuildMaster, "帮派等级奖励", "亲爱的帮主：\n    恭喜您的帮派已成功升级到4级，并获得2000元宝奖励，（元宝可在【商城】使用，购买强力道具）。继续提升帮派实力，您将获得更多的帮众，体验更多的功能，还将有更多的惊喜等着您哦！", 0, 0, 0, 0, 0, 0, 0, 0, 2000)
            end
    end).
