%%%------------------------------------
%%% @Module  : mod_daily
%%% @Author  : zhenghehe
%%% @Created : 2010.09.26
%%% @Description: 每天记录器
%%%------------------------------------

%%%-----------缓存日常(不记录数据库)-------------------------

%%	玩家在线时长-------- 9000002(只在离线时候记录,不可以直接获取使用,获取在线时长请用lib_player:get_online_time/1)
%%	玩家当天在线时长-------- 9000003(获取在线时长请用lib_player:get_online_time_today/1)
%%% 玩家运势感谢日常--- 3701001
%%% 玩家运势被感谢日常--- 3701002

%%%-----------缓存日常-------------------------

%%% 副本--------------------100 - 999type
%%% #######黄茬专用4位##########
%%% 修炼--------------------1000
%%% vip飞鞋-----------------1005
%%% 休养生息----------------1006
%%% 帮派boss----------------1007
%%% 喝酒数量----------------1008
%%% 帮派boss喂养次数--------1009
%%% 挑逗boss次数------------1010
%%% 是否领取本日塔防波数-----1020
%%% 沙滩-恶搞-----------1021
%%% 沙滩-示好-----------1022
%%% 沙滩-是否互动-----------1023
%%% 已经购买彩票------------1024
%%% 已经领取参与奖----------1025
%%% 特等奖玩家是否在线------1026
%%% 智力答题次数------------1027

%%% 领取城攻经验BUFF--------1102

%%% 每天更换头像次数--------1300
%%% 领取国家声望排行前十奖励1351
%%% 接收好友祝福次数--------1400
%%% 接收利是次数--------1401
%%% 限时热卖0元宝区---------1500
%%% 限时热卖1元宝区---------1501
%%% 限时热卖2元宝区---------1502
%%% 连续登录商店------------1503
%%% 商城活动---------------1510
%%% 宝箱活动---------------1511
%%% 充值活动---------------1512
%%% 物品掉落id--------------1515
%%% 兑换元旦礼包一 ---------1601
%%% 兑换元旦礼包二----------1602
%%% 兑换元旦礼包三----------1603
%%% 兑换竞技场--------------1604
%%% 兑换新春礼包------------1605
%%% 兑换新年红包------------1606
%%% 兑换帮派战功------------1607
%%% 兑换师道值--------------1608
%%% 兑换橙水晶--------------1609
%%% 跨服商店兑换-------------1610
%%% 副本声望兑换-------------1611
%%% 诸天争霸----------------1612
%%% 活跃度兑换---------------1613
%%% 发信--------------------1901
%%% 英雄帖------------------2000
%%% 排行榜崇拜鄙视----------2200
%%% 矿石掉落----------------2300 - 2399
%%% 二级密码修改与删除------2610 , 2611
%%% 仙侣奇缘被邀请次数------2700
%%% 仙侣奇缘邀请次数--------2701
%%% vip 仙侣刷新次数--------2702
%%% 仙侣情缘游戏操作--------2705
%%% 塔副本跳层次数----------2800
%%% 塔副本跳层附加次数------2801
%%% 送花--------------------2900 - 2902
%%% 每天在线时间------------3600
%%% 双修亲密度--------------3701
%%% 仙侣奇缘任务完成次数----3800
%%% 个人财富每天可捐献上限--4001
%%% 个人接收祝福露每天上限--4002
%%% 刷新摇钱树次数----------4079
%%% 每天VIP红包开启次数-----4501
%%% vip每天刷新镖车次数-----4600
%%% 镖车护送次数------------4700
%%% 每天输入验证码领奖励次数--5500
%%% 每天放弃结婚任务的次数--5600
%%% 玩家切换头像次数--------5700
%%% 玩家参与3v3战斗次数 --------5705

%%%---------- 运营活动使用段 6050~7050 start ----------%%%
%%% 封测期每日登录奖励------------6050
%%% 开服七天每日登录奖励------------6051
%%% 限时名人堂初始化标记------------6052
%%% 节日贺卡发送数量----------------6053
%%%---------- 运营活动使用段 6050~7050 end ----------%%%


%%%---------- 中秋国庆活动使用段 7060~ start ----------%%%
%%% 领取活跃达到80礼包标识------------7060
%%% 领取活跃达到100礼包标识------------7061
%%% 领取活跃达到120礼包标识------------7062
%%%---------- 中秋国庆活动使用段 7060~ end ----------%%%


%%%---------- 七夕活动使用段 7701~7750 start ----------%%%
%% 完成护送任务次数 ------------  7701
%% 完成平乱任务次数 ------------  7702
%% 完成皇榜次数 ------------  7703
%% 完成诛妖贴任务次数 ------------  7704
%% 完成帮派试炼任务次数 ------------  7705
%% 完成仙侣奇缘任务次数 ------------  7706
%% 七夕活动任务可领取奖励数目------------7710
%% 七夕活动登录礼包可领取奖励数目------------7711
%% 七夕活动第一礼包领取标记--------- 7721
%% 七夕活动第二礼包领取标记--------- 7722
%% 七夕活动第三礼包领取标记--------- 7723
%% 七夕活动第四礼包领取标记--------- 7724
%% 类推
%% 特殊连续登录礼包领取标记---------7750
%%%---------- 七夕活动使用段 7701~7750 end ----------%%%

%%%---------- 福利使用段 7751~7760 start ----------%%%
%% 每天翻牌次数 ----------------7751
%% 类推
%%%---------- 福利使用段 7751~7760 start ----------%%%

%% 神秘商店每天免费次数------------8001
%% 神秘商店自动刷新时间------------8002

%% 坐骑资质培养次数---------------8010


%% 摇钱树领取奖励物品6类型---------------------8885
%% 摇钱树领取奖励物品12类型--------------------8886
%% 摇钱树领取奖励物品18类型--------------------8887
%% 摇钱树领取奖励物品24类型--------------------8888
%% 摇钱树次数------------------------------8889
%% 摇钱树领取奖励物品次数----------------------8890


%% 离线活动：进入钓鱼场景 ----------8894
%% 离线活动：进入蝴蝶场景 ----------8895


%% 9000 - 9999 新版VIP使用----------------9000 - 9999
%% VIP等级特权绑定元宝--------------------9000
%% VIP等级特权绑定铜币--------------------9001
%% VIP任务接取次数------------------------9010
%% VIP任务-"累积在线"完成次数-------------9011
%% VIP任务-"活跃度"完成次数---------------9012
%% 9000 - 9999 新版VIP使用----------------9000 - 9999

%%% 每天发送好友祝福次数----10000
%%% 精力值------------------10001
%%% 成功劫镖次数------------10002
%%% 被劫镖次数--------------10003
%%% 运镖求救次数------------10005
%%% 开服前七天的VIP周礼包，每天领取标记--------10007



%% 12000 - 12999 新版VIP使用----------------12000 - 12999
%% 新VIP每日福利--------------------------12000
%% 每日登录增加/减少经验------------------12001
%% VIP摇奖当前需要摇奖金币----------------12002
%% VIP摇奖每日次数------------------------12003
%% 12000 - 12999 新版VIP使用----------------12000 - 12999

%% 飞行器训练次数 ----------------------13001 - 13100

%% 进入VIP副本 -------------------------45101

%%% 開服前10天每日領取綁定元寶-------6631451
%%% 排行榜奖励--------------2210801~2210899
%%% 玩家今日运势------------3700001
%%% 玩家运势需要检查的日常--- 3700002 ~ 3700099
%%% 帮派商城物品兑换--------4009101~4009199
%%% 帮派祭坛抽奖次数--------4007801
%%% 帮派祭坛抽奖记录--------4007802
%%% 帮派宴会吃食物--------4007803
%%% 帮派宴会启动次数--------4007804
%%% 帮派退出时间(今日)--------4007805
%%% 帮派退出次数(今日)--------4007806
%%% 帮派上次查看帮派历史时间(今日)--------4007807
%%% 帮派召唤神兽次数--------4007808
%%% 帮派召唤神兽时间--------4007809
%%% 帮派宴会采集蟠桃/人参/瑶池--------4007810~4007912
%%% 帮派神炉每天捐献铜钱数量 --------4008000
%%% 宠物提升成长------------5000000
%%% 宠物元宝提升成长--------5000001
%%% 免费修行潜能-----------5000002
%%% 免费宠物提升成长--------5000003
%%% New 砸蛋
%%% 宠物彩蛋砸蛋次数--------5000004
%%% 宠物金蛋砸蛋次数--------5000005
%%% end
%%% 宠物潜能提升次数--------5000006
%%% 宠物刷新技能次数--------5000007
%%% 宠物实际砸蛋次数--------5000008
%%% 爱情长跑领取道具--------------------333444
%%% 完成诛妖任务次数--------6000000
%%% 完成皇榜任务次数--------6000001
%%% 完成平乱任务次数--------6000002
%%% 完成试炼任务次数--------6000003
%%% 完成日常任务次数--------6000004

%%% 竞技场次数--------6000005
%%% 帮派战次数--------6000006
%%% 蟠桃会任务次数--------6000007
%%% 完成试炼任务次数--------6000008
%%% 完成日常任务次数--------6000009
%%% 活跃度完成项数---------60000010

%%% 7000001-7000100留给体力在系统用
%%% 体力值系统每天已经使用清除CD的次数---7000001

%%% 当天发送语音自增id（值为1-99）-------7000201
%%% 当天发送图片自增id（值为1-99）-------7000202


%%%---------- 特殊情况处理 start ----------%%%
%%% 这一部分，是处理role_id=0 的公共数据处理，不针玩家
%%% 但也是以天为单位的数据
%%% 中秋国庆活动魅力排行榜邮件奖励标识------1000
%%%---------- 特殊情况处理 end ----------%%%


-module(mod_daily).
-include("daily.hrl").
-include("record.hrl").
-include("server.hrl").
-compile(export_all).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).



%% 下线操作
stop(Pid) ->
    gen_server:cast(Pid, stop).

%% 获取整个记录器
get(Pid, RoleId, Type) ->
    gen_server:call(Pid, {get, [RoleId, Type]}).

%% 取玩家的整个记录
get_all(Pid, RoleId) ->
    gen_server:call(Pid, {get_all, [RoleId]}).

%% 获取数量
get_count(Pid, RoleId, Type) ->
    gen_server:call(Pid, {get_count, [RoleId, Type]}).

%% 加一操作
increment(Pid, RoleId, Type) ->
    plus_count(Pid, RoleId, Type, 1).

%% 减一操作
decrement(Pid, RoleId, Type) ->
    cut_count(Pid, RoleId, Type, 1).

%% 设置数量
set_count(Pid, RoleId, Type, Count) ->
    gen_server:call(Pid, {set_count, [RoleId, Type, Count]}).

%% 获取刷新时间
get_refresh_time(Pid, RoleId, Type) ->
	gen_server:call(Pid, {get_refresh_time, [RoleId, Type]}).
   
%% 更新刷新时间
set_refresh_time(Pid, RoleId, Type) ->
	gen_server:call(Pid, {set_refresh_time, [RoleId, Type]}).

%% 追加数量
plus_count(Pid, RoleId, Type, Count) ->
    gen_server:call(Pid, {plus_count, [RoleId, Type, Count]}).

%% 扣除数量
cut_count(Pid, RoleId, Type, Count) ->
    gen_server:call(Pid, {cut_count, [RoleId, Type, Count]}).

new([Pid, RoleId, Type, Count]) ->  
    gen_server:call(Pid, {new, [[RoleId, Type, Count]]});

new([Pid, RoleId, Type]) ->  
    gen_server:call(Pid, {new, [[RoleId, Type]]}).

save(Pid, RoleDaily) ->
    gen_server:call(Pid, {save, [RoleDaily]}).

%% 获取皇榜任务和平乱任务次数
get_task_count(Pid, RoleId) ->
    gen_server:call(Pid, {get_task_count, [RoleId]}).

%% 获取特殊数据：针对个人的数据，但不入库，只保存在进程中
get_special_info(Pid, Key) ->
	gen_server:call(Pid, {get_special_info, [Key]}).

%% 设置特殊数据：针对个人的数据，但不入库，只保存在进程中
set_special_info(Pid, Key, Value) ->
	gen_server:call(Pid, {set_special_info, [Key, Value]}).

start_link(RoleId) ->
    gen_server:start_link(?MODULE, [RoleId], []).

init([RoleId]) ->
    lib_daily:online(RoleId),
    {ok, ?MODULE}.

%%每日清空缓存
handle_cast({daily_clear_0, RoleId}, Status) ->
	erase(?DAILY_KEY(RoleId)),
    {noreply, Status};

%%停止任务进程
handle_cast(stop, Status) ->
    {stop, normal, Status};

%% cast数据调用
handle_cast({Fun, Arg}, Status) ->
    apply(lib_daily, Fun, Arg),
    {noreply, Status};

handle_cast(_R , Status) ->
    {noreply, Status}.

%% call数据调用
handle_call({Fun, Arg} , _FROM, Status) ->
    {reply, apply(lib_daily, Fun, Arg), Status};

handle_call(_R , _FROM, Status) ->
    {reply, ok, Status}.

handle_info(_Reason, Status) ->
    {noreply, Status}.

terminate(_Reason, Status) ->
    {ok, Status}.

code_change(_OldVsn, Status, _Extra)->
    {ok, Status}.

%% 每天数据清除(公共线)
daily_clear() ->
	catch db:execute_nohalt(io_lib:format(?sql_daily_clear, [])),
    %%通知线路更新
    Server = mod_disperse:node_list(),
    F = fun(S) ->
            rpc:cast(S#node.node, mod_daily, daily_clear_ref, [])
    end,
    [F(S) || S <- Server].

%% 清除每个游戏线内所有玩家的Daily数据
daily_clear_ref() ->
    Data = ets:tab2list(?ETS_ONLINE),
    [gen_server:cast(D#ets_online.pid, {'refresh_and_clear_daily'}) || D <- Data],
    ok.

%% 后台使用,清除所有人的日常
daily_clear_all_houtai() ->
	mod_disperse:cast_to_unite(mod_daily, daily_clear, []),
	mod_disperse:cast_to_unite(mod_daily_dict, daily_clear, []),
	mod_disperse:cast_to_unite(lib_fortune, clear_all_fortune_log, []).

%% 清除某玩家的指定日常(只能用于在线玩家)
daily_clear_role_one(RoleId, Type) ->
	mod_daily_dict:set_count(RoleId, Type, 0),
	case lib_player:get_player_info(RoleId, dailypid) of
		DailyPid when is_pid(DailyPid) ->
			set_count(DailyPid, RoleId, Type, 0);
		_ ->
			skip
	end.

%% 清除某玩家的所有日常(只能用于在线玩家)
daily_clear_role_all(RoleId) ->
	case lib_player:get_player_info(RoleId, dailypid) of
		DailyPid when is_pid(DailyPid) ->
			gen_server:cast(DailyPid, {daily_clear_0, RoleId});
		_ ->
			skip
	end.
