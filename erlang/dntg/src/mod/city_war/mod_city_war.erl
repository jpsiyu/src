%%%------------------------------------
%%% @Module  : mod_city_war
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.12.13
%%% @Description: 城战
%%%------------------------------------
-module(mod_city_war).
-behaviour(gen_server).
-export(
    [
        start_link/0,
        stop/0,
        init/1,
        handle_call/3,
        handle_cast/2,
        handle_info/2,
        terminate/2,
        code_change/3,
        seize_revive_place/1,
        test/0,
        set_all_time/1,
        init_all/0,
        continue_city_war/0,
        before_broadcast/0,
        after_broadcast/0,
        get_apply_info/1,
        aid_or_cancel/1,
        get_approval_info/1,
        approval_apply/1,
        get_seize_info/1,
        donate_coin/1,
        enter_war/1,
        logout_deal/1,
        change_career/1,
        del_a_career/1,
        init_mon/0,
        get_revive_place/1,
        info_panel1/1,
        info_panel2/2,
        info_panel3/1,
        refresh_mon/0,
        timing_broad/0,
        update_door_blood/1,
        minus_revive_car/3,
        minus_revive_bomb/3,
        minus_a_car/0,
        timing_revive/0,
        clear_all_out/0,
        minus_a_career/1,
        add_score/2,
        die_deal/1,
        attacker_win/0,
        account/0,
        end_deal/1,
        add_guild_score/2,
        get_next_revive_time/1,
        gm_apply/1,
        picture0/1,
        picture1/1,
        picture2/1,
        reset_all/0,
        delete_revive_list/1,
        get_statue/1,
        set_statue/1,
        reset_statue/1,
        no_open_broadcast/0,
        send_winner_tv/1,
        get_winner_guild/1,
        minus_a_tower/0,
        is_att_def/1,
        minus_a_collect_car/0,
        add_end_seize_time/0
    ]
).
-include("guild.hrl").
-include("server.hrl").
-include("city_war.hrl").

%% 测试使用
test() ->
    gen_server:call(misc:get_global_pid(?MODULE),{test}).

%% 设置活动相关时间
set_all_time([ConfigBeginHour, ConfigBeginMinute, ConfigEndHour, ConfigEndMinute, EndSeizeHour, EndSeizeMinute, ApplyEndHour, ApplyEndMinute, OpenDays, SeizeDays]) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{set_all_time, ConfigBeginHour, ConfigBeginMinute, ConfigEndHour, ConfigEndMinute, EndSeizeHour, EndSeizeMinute, ApplyEndHour, ApplyEndMinute, OpenDays, SeizeDays}).

%% 数据初始化
init_all() ->
    gen_server:call(misc:get_global_pid(?MODULE),{init_all}).

%% 继续攻城战(周六重启时)
continue_city_war() ->
    gen_server:call(misc:get_global_pid(?MODULE),{continue_city_war}).

%% 活动开始前的广播
before_broadcast() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{before_broadcast}).

%% 活动开始后的广播
after_broadcast() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{after_broadcast}).

%% 报名信息
get_apply_info(UniteStatus) -> 
    gen_server:cast(misc:get_global_pid(?MODULE),{get_apply_info, UniteStatus}).

%% 援助/取消申请/撤兵
aid_or_cancel([UniteStatus, AidTarget]) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{aid_or_cancel, UniteStatus, AidTarget}).

%% 获取审批信息
get_approval_info([UniteStatus, Type]) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{get_approval_info, UniteStatus, Type}).

%% 审批申请信息
approval_apply([UniteStatus, GuildId, Answer]) -> 
    gen_server:cast(misc:get_global_pid(?MODULE),{approval_apply, UniteStatus, GuildId, Answer}).

%% 获取抢夺信息
get_seize_info(UniteStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{get_seize_info, UniteStatus}).

%% 捐献铜币
donate_coin([PlayerStatus, Num]) ->
    gen_server:call(misc:get_global_pid(?MODULE),{donate_coin, PlayerStatus, Num}).

%% 进入活动
enter_war(UniteStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{enter_war, UniteStatus}).

%% 下线处理
logout_deal(PlayerStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{logout_deal, PlayerStatus}).

%% 职业变换
change_career([PlayerStatus, Type]) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{change_career, PlayerStatus, Type}).

%% 删除一个职业
del_a_career([PlayerId, FigureId]) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{del_a_career, PlayerId, FigureId}).

%% 怪物初始化
init_mon() -> 
    gen_server:cast(misc:get_global_pid(?MODULE),{init_mon}).

%% 进攻方抢占复活点
seize_revive_place(Mon) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{seize_revive_place, Mon}).

%% 获取复活地点
%% Type：1.进攻方 2.防守方
get_revive_place(Type) ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_revive_place, Type}).

%% 城战面板1(定时更新，客户端也可以主动申请)
info_panel1(UniteStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{info_panel1, UniteStatus}).

%% 城战面板2(及时更新)
info_panel2(GuildId, PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{info_panel2, GuildId, PlayerId}).

%% 城战面板3(及时更新)
info_panel3(UniteStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{info_panel3, UniteStatus}).

%% 定时刷新怪物
refresh_mon() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{refresh_mon}).

%% 定时广播
timing_broad() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{timing_broad}).

%% 更新城门血量
update_door_blood([MonId, Hp, HpLim, Mid]) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{update_door_blood, MonId, Hp, HpLim, Mid}).

%% 复活点内的攻城车数量减一
minus_revive_car(Mid, X, Y) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{minus_revive_car, Mid, X, Y}).

%% 复活点内的炸弹数量减一
minus_revive_bomb(Mid, X, Y) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{minus_revive_bomb, Mid, X, Y}).

%% 攻城车总数减一
minus_a_car() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{minus_a_car}).

%% 定时复活
timing_revive() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{timing_revive}).

%% 把全部人清出场
clear_all_out() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{clear_all_out}).

%% 医仙、鬼巫数量减一
minus_a_career(PlayerStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{minus_a_career, PlayerStatus}).

%% 玩家加分
add_score(PlayerId, Score) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{add_score, PlayerId, Score}).

%% 死亡处理
die_deal(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{die_deal, PlayerId}).

%% 进攻方胜利
attacker_win() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{attacker_win}).

%% 结算
account() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{account}).

%% 弹出结算面板、发送奖励
end_deal(Type) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{end_deal, Type}).

%% 帮派加分
add_guild_score(GuildId, Score) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{add_guild_score, GuildId, Score}).

%% 复活剩余时间
get_next_revive_time(UniteStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{get_next_revive_time, UniteStatus}).

%% 秘籍获得抢夺权限
gm_apply(GuildId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{gm_apply, GuildId}).

%% 图标0
picture0(UniteStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{picture0, UniteStatus}).

%% 图标1
picture1(UniteStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{picture1, UniteStatus}).

%% 图标2
picture2(UniteStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{picture2, UniteStatus}).

%% 攻防互换
reset_all() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{reset_all}).

%% 删除复活列表
delete_revive_list(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{delete_revive_list, PlayerId}).

%% 获取雕像
get_statue(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{get_statue, PlayerId}).

%% 设置雕像
set_statue(PlayerStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{set_statue, PlayerStatus}).

%% 设置雕像
reset_statue(PlayerStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{reset_statue, PlayerStatus}).

%% 未开启广播长安城主信息
no_open_broadcast() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{no_open_broadcast}).

%% 长安城主传闻
send_winner_tv(PlayerStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{send_winner_tv, PlayerStatus}).

%% 获胜帮派
get_winner_guild(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{get_winner_guild, PlayerId}).

%% 箭塔总数减一
minus_a_tower() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{minus_a_tower}).

%% 是否为进攻方或者防守方
is_att_def(GuildId) ->
    gen_server:call(misc:get_global_pid(?MODULE),{is_att_def, GuildId}).

%% 采集攻城车数量减一
minus_a_collect_car() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{minus_a_collect_car}).

%% 增加抢夺时间
add_end_seize_time() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{add_end_seize_time}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

init([]) ->
    lib_city_war:init_win_info(),
    {ok, #city_war_state{}}.

handle_call(Request, From, State) ->
    mod_city_war_call:handle_call(Request, From, State).

handle_cast(Msg, State) ->
    mod_city_war_cast:handle_cast(Msg, State).

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
