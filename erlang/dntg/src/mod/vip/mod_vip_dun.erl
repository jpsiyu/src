%%%------------------------------------
%%% @Module  : mod_vip_dun
%%% @Author  : guoxi
%%% @Email   : 178912295@qq.com
%%% @Created : 2012.02.25
%%% @Description: VIP副本
%%%------------------------------------

-module(mod_vip_dun).
-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3, stop/0]).
-export(
    [
        timing_clear/0,
        send_player_out/1,
        re_connect/1,
        vip_dun_logout_deal/1,
        get_player_dun/1,
        enter_vip_dun/3,
        player_logout/1,
        get_vip_dun_info/1,
        flag/5,
        get_mon_time/1,
        get_questions/1,
        answer_question/2,
        select_right_answer/1,
        clear_wrong_answer/1,
        guessing_game/2,
        vip_dun_battle_award/2,
        minus_skill/2,
        send_goods_award/2,
        check_buy_num/1,
        buy_num/1,
        get_vip_dun_shop_list/1,
        get_call_shop_list/1,
        guessing_point/2,
        start_battle/2,
        end_battle/2,
        add_round/1,
        create_four_mon/3,
        update_boss_id/2,
        boss_die/2,
        create_goods/4,
        goto/2
    ]
).
-include("vip_dun.hrl").

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call(misc:get_global_pid(?MODULE), stop).

%% 定时清理
timing_clear() ->
    gen_server:cast(misc:get_global_pid(?MODULE),{timing_clear}).

%% 把玩家踢出副本
send_player_out(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{send_player_out, PlayerId}).

%% 断线重连
re_connect(PlayerStatus) ->
    gen_server:call(misc:get_global_pid(?MODULE),{re_connect, PlayerStatus}).

%% 下线处理
vip_dun_logout_deal(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{vip_dun_logout_deal, PlayerId}).

%% 获取玩家副本信息(for test)
get_player_dun(PlayerId) ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_player_dun, PlayerId}).

%% 进入VIP副本
enter_vip_dun(PlayerId, PlayerLv, StatusVip) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{enter_vip_dun, PlayerId, PlayerLv, StatusVip}).

%% 退出VIP副本
player_logout(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{player_logout, PlayerId}).

%% 获取VIP副本信息 
get_vip_dun_info(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{get_vip_dun_info, PlayerId}).

%% 掷骰子
flag(PlayerId, PlayerLv, SceneId, CopyId, CheckNum) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{flag, PlayerId, PlayerLv, SceneId, CopyId, CheckNum}).

%% 杀怪用时
get_mon_time(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{get_mon_time, PlayerId}).

%% 获取题目
get_questions(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{get_questions, PlayerId}).

%% 回答问题
answer_question(PlayerStatus, Answer) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{answer_question, PlayerStatus, Answer}).

%% 选择正确答题
select_right_answer(PlayerStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{select_right_answer, PlayerStatus}).

%% 去掉两个错误答题
clear_wrong_answer(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{clear_wrong_answer, PlayerId}).

%% 猜拳
guessing_game(PlayerStatus, Answer) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{guessing_game, PlayerStatus, Answer}).

%% 发送战斗奖励
vip_dun_battle_award(PlayerStatus, Time) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{vip_dun_battle_award, PlayerStatus, Time}).

%% 减少技能数量
minus_skill(PlayerId, Skill) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{minus_skill, PlayerId, Skill}).

%% 发送战斗/采集奖励
send_goods_award(PlayerStatus, MonId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{send_goods_award, PlayerStatus, MonId}).

%% 检测购买骰子次数
check_buy_num(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{check_buy_num, PlayerId}).

%% 购买骰子次数
buy_num(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{buy_num, PlayerId}).

%% VIP副本商店列表
get_vip_dun_shop_list(PlayerStatus) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{get_vip_dun_shop_list, PlayerStatus}).

%% call操作获取VIP副本商店列表
get_call_shop_list(PlayerId) ->
    gen_server:call(misc:get_global_pid(?MODULE),{get_call_shop_list, PlayerId}).

%% 猜大小
guessing_point(PlayerStatus, Ans) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{guessing_point, PlayerStatus, Ans}).

%% 圈数加一(成功则传送玩家至第一格，失败则不做处理)
add_round(PlayerId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{add_round, PlayerId}).

%% BOSS格生成4个小怪
create_four_mon(PlayerId, X, Y) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{create_four_mon, PlayerId, X, Y}).

%% 更新BOSS的ID
update_boss_id(PlayerId, BossId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{update_boss_id, PlayerId, BossId}).

%% BOSS死亡
boss_die(PlayerId, MonId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{boss_die, PlayerId, MonId}).

%% 生成掉落
create_goods(PlayerStatus, GoodsList, X, Y) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{create_goods, PlayerStatus, GoodsList, X, Y}).

%% 直接跳到第几格
goto(PlayerId, Num) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{goto, PlayerId, Num}).


%%%%% 外部调用接口 %%%%%

%% 开始打怪
start_battle(PlayerId, MonId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{start_battle, PlayerId, MonId}).

%% 结束打怪
end_battle(PlayerId, MonId) ->
    gen_server:cast(misc:get_global_pid(?MODULE),{end_battle, PlayerId, MonId}).

init([]) ->
    State = #vip_dun_state{},
    {ok, State}.

%% ==========  call  ==========

%% 容错

%% 获取玩家副本信息(for test)
handle_call({get_player_dun, PlayerId}, _From, State) ->
    Reply = dict:find(PlayerId, State#vip_dun_state.player_dun),
    {reply, Reply, State};

%% 断线重连
handle_call({re_connect, PlayerStatus}, _From, State) ->
    [Reply, NewState] = lib_vip_dun:re_connect(PlayerStatus, State),
    {reply, Reply, NewState};

%% call操作获取VIP副本商店列表
handle_call({get_call_shop_list, PlayerId}, _From, State) ->
    Reply = lib_vip_dun:get_call_shop_list(PlayerId, State),
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    Reply = {ok, ok},
    {reply, Reply, State}.

%% ==========  cast  ==========

%% 定时清理
handle_cast({timing_clear}, State) ->
    lib_vip_dun:timing_clear(State),
    {noreply, State};

%% 把玩家踢出副本
handle_cast({send_player_out, PlayerId}, State) ->
    NewState = lib_vip_dun:send_player_out(PlayerId, State),
    {noreply, NewState};

%% 下线处理
handle_cast({vip_dun_logout_deal, PlayerId}, State) ->
    NewState = lib_vip_dun:vip_dun_logout_deal(PlayerId, State),
    {noreply, NewState};

%% 进入VIP副本
handle_cast({enter_vip_dun, PlayerId, PlayerLv, StatusVip}, State) ->
    NewState = lib_vip_dun:enter_vip_dun(PlayerId, PlayerLv, StatusVip, State),
    {noreply, NewState};

%% 退出VIP副本
handle_cast({player_logout, PlayerId}, State) ->
    NewState = lib_vip_dun:player_logout(PlayerId, State),
    {noreply, NewState};

%% 获取VIP副本信息
handle_cast({get_vip_dun_info, PlayerId}, State) ->
    NewState = lib_vip_dun:get_vip_dun_info(PlayerId, State),
    {noreply, NewState};

%% 掷骰子
handle_cast({flag, PlayerId, PlayerLv, SceneId, CopyId, CheckNum}, State) ->
    NewState = lib_vip_dun:flag(PlayerId, PlayerLv, SceneId, CopyId, State, CheckNum),
    {noreply, NewState};

%% 杀怪用时
handle_cast({get_mon_time, PlayerId}, State) ->
    lib_vip_dun:get_mon_time(PlayerId, State),
    {noreply, State};

%% 获取题目
handle_cast({get_questions, PlayerId}, State) ->
    NewState = lib_vip_dun:get_questions(PlayerId, State),
    {noreply, NewState};

%% 回答问题
handle_cast({answer_question, PlayerStatus, Answer}, State) ->
    NewState = lib_vip_dun:answer_question(PlayerStatus, State, Answer),
    {noreply, NewState};

%% 选择正确答题
handle_cast({select_right_answer, PlayerStatus}, State) ->
    NewState = lib_vip_dun:select_right_answer(PlayerStatus, State),
    {noreply, NewState};

%% 去掉两个错误答题
handle_cast({clear_wrong_answer, PlayerId}, State) ->
    NewState = lib_vip_dun:clear_wrong_answer(PlayerId, State),
    {noreply, NewState};

%% 猜拳
handle_cast({guessing_game, PlayerStatus, Answer}, State) ->
    NewState = lib_vip_dun:guessing_game(PlayerStatus, State, Answer),
    {noreply, NewState};

%% 开始打怪
handle_cast({start_battle, PlayerId, MonId}, State) ->
    NewState = lib_vip_dun:start_battle(PlayerId, MonId, State),
    {noreply, NewState};

%% 结束打怪
handle_cast({end_battle, PlayerId, MonId}, State) ->
    NewState = lib_vip_dun:end_battle(PlayerId, MonId, State),
    {noreply, NewState};

%% 发送战斗奖励
handle_cast({vip_dun_battle_award, PlayerStatus, Time}, State) ->
    lib_vip_dun:vip_dun_battle_award(PlayerStatus, Time, State),
    {noreply, State};

%% 减少技能数量
handle_cast({minus_skill, PlayerId, Skill}, State) ->
    NewState = lib_vip_dun:minus_skill(PlayerId, Skill, State),
    {noreply, NewState};

%% 发送战斗/采集奖励
handle_cast({send_goods_award, PlayerStatus, MonId}, State) ->
    NewState = lib_vip_dun:send_goods_award(PlayerStatus, MonId, State),
    {noreply, NewState};

%% 检测购买骰子次数
handle_cast({check_buy_num, PlayerId}, State) ->
    lib_vip_dun:check_buy_num(PlayerId, State),
    {noreply, State};

%% 购买骰子次数
handle_cast({buy_num, PlayerId}, State) ->
    NewState = lib_vip_dun:buy_num(PlayerId, State),
    {noreply, NewState};

%% VIP副本商店列表
handle_cast({get_vip_dun_shop_list, PlayerStatus}, State) ->
    lib_vip_dun:get_vip_dun_shop_list(PlayerStatus, State),
    {noreply, State};

%% 猜大小
handle_cast({guessing_point, PlayerStatus, Ans}, State) ->
    NewState = lib_vip_dun:guessing_point(PlayerStatus, Ans, State),
    {noreply, NewState};

%% 圈数加一(成功则传送玩家至第一格，失败则不做处理)
handle_cast({add_round, PlayerId}, State) ->
    NewState = lib_vip_dun:add_round(PlayerId, State),
    {noreply, NewState};

%% BOSS格生成4个小怪
handle_cast({create_four_mon, PlayerId, X, Y}, State) ->
    NewState = lib_vip_dun:create_four_mon(PlayerId, X, Y, State),
    {noreply, NewState};

%% 更新BOSS的ID
handle_cast({update_boss_id, PlayerId, BossId}, State) ->
    NewState = lib_vip_dun:update_boss_id(PlayerId, BossId, State),
    {noreply, NewState};

%% BOSS死亡
handle_cast({boss_die, PlayerId, MonId}, State) ->
    NewState = lib_vip_dun:boss_die(PlayerId, MonId, State),
    {noreply, NewState};

%% 生成掉落
handle_cast({create_goods, PlayerStatus, GoodsList, X, Y}, State) ->
    lib_vip_dun:create_goods(GoodsList, PlayerStatus, X, Y),
    {noreply, State};

%% 直接跳到第几格
handle_cast({goto, PlayerId, Num}, State) ->
    NewState = lib_vip_dun:goto(PlayerId, Num, State),
    {noreply, NewState};

%% 容错
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
