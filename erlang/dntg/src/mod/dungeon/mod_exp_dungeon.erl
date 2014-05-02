%%------------------------------------------------------------------------------
%% @Module  : mod_exp_dungeon
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.10
%% @Description: 经验副本服务
%%------------------------------------------------------------------------------

-module(mod_exp_dungeon).
-export([create_scene/3,      %% 创建经验副本场景.
		 kill_npc/4,          %% 杀死怪物事件.
		 create_mon/5         %% 创建怪物.
		 ]).

-include("scene.hrl").
-include("dungeon.hrl").


%% --------------------------------- 公共函数 ----------------------------------
  
%% 创建经验副本场景
create_scene(SceneId, CopyId, State) ->
	%1.创建怪物.
    spawn(fun() -> 
                timer:sleep(3000),
                mod_scene_agent:apply_cast(SceneId, mod_exp_dungeon, create_mon, 
                    [SceneId, CopyId, State#dungeon_state.level,63001,1]) 
        end
    ),

	%2.修改副本场景ID.
    ChangeSceneId = fun(DunScene) ->
            case DunScene#dungeon_scene.sid =:= SceneId of
                true -> 
                    DunScene#dungeon_scene{id = SceneId};
                false -> 
                    DunScene
            end
    end,
    ExpDun = #exp_dun{level=1, need_kill_mon_num=8},
    NewState = State#dungeon_state{
        exp_dun = ExpDun, 
        scene_list = [ChangeSceneId(DunScene)||DunScene<-State#dungeon_state.scene_list]},
 	{SceneId, NewState}.

%% 杀怪事件.
kill_npc(State, Scene, _SceneResId, [_MonId|_]) ->
    #dungeon_state{level=Level, exp_dun=ExpDun} = State,
    case ExpDun of
		%1.不是经验副本
        [] ->
        	State;
		%2.经验副本杀怪事件处理
        #exp_dun{level=MonLevel, kill_mon_num=KillMonNum, 
            need_kill_mon_num = NeedKillMonNum, total_kill_mon_num = TotalKillMonNum} -> 
            case MonLevel >= 9 of %% 达到最大轮数
                true -> State;
                false -> 
                    case KillMonNum + 1 >= NeedKillMonNum of
                        true -> %% 创建下波怪物
                            NextMonId = get_level_mon_id(MonLevel+1),
                            mod_scene_agent:apply_cast(Scene, mod_exp_dungeon, create_mon, 
                                [Scene, self(), Level, NextMonId, MonLevel+1]),
                            NewExpDun = ExpDun#exp_dun{level=MonLevel+1, kill_mon_num=0, 
                                need_kill_mon_num = 8, total_kill_mon_num = TotalKillMonNum+1},
                            State#dungeon_state{exp_dun=NewExpDun};
                        false -> %% 击杀怪物数量+1
                            NewExpDun = ExpDun#exp_dun{kill_mon_num=KillMonNum + 1, total_kill_mon_num = TotalKillMonNum+1},
                            State#dungeon_state{exp_dun=NewExpDun}
                    end
            end
    end.

%% 创建怪物.
create_mon(SceneId, CopyId, Level, MonId, MonLevel) ->
    MonLocal = [{14,30},{17,30},{20,30},{14,33},{20,33},{14,36},{17,36},{20,36}],
    Args = [
        {auto_att, 0},
        {hp,    round(get_hp_value (MonLevel, Level))},
        {hp_lim,round(get_hp_value (MonLevel, Level))},
        {att, round(get_att_value(MonLevel, Level))},
        {exp, round(get_exp_value(MonLevel, Level))},
        {lv,  Level}
    ],
    [mod_mon_create:create_mon_cast(MonId, SceneId, X, Y, 1, CopyId, 1, Args) || {X,Y} <- MonLocal].

get_level_mon_id(Level) -> 
    case Level of
        1  -> 63001;
        2  -> 63001;
        3  -> 63001;
        4  -> 63002;
        5  -> 63002;
        6  -> 63002;
        7  -> 63003;
        8  -> 63003;
        9  -> 63003;
        _  -> 63003
    end.

%% 获取对应轮数怪物hp数值
get_hp_value(Level, PLv) -> 
    case Level of
        1 -> PLv*PLv*PLv*4*(PLv/40-(PLv-40)/150)/420;
        2 -> PLv*PLv*PLv*4*(PLv/40-(PLv-40)/150)/420;
        3 -> PLv*PLv*PLv*4*(PLv/40-(PLv-40)/150)/420;
        4 -> PLv*PLv*PLv*6*(PLv/40-(PLv-40)/150)/420;
        5 -> PLv*PLv*PLv*6*(PLv/40-(PLv-40)/150)/420;
        6 -> PLv*PLv*PLv*6*(PLv/40-(PLv-40)/150)/420;
        7 -> PLv*PLv*PLv*9*(PLv/40-(PLv-40)/150)/420;
        8 -> PLv*PLv*PLv*9*(PLv/40-(PLv-40)/150)/420;
        9 -> PLv*PLv*PLv*9*(PLv/40-(PLv-40)/150)/420;
        _ -> PLv*PLv*PLv*9*(PLv/40-(PLv-40)/150)/420
    end.

%% 获取对应轮数怪物攻击数值
get_att_value(Level, PLv) -> 
    case Level of
        1 -> PLv*PLv*7/500;
        2 -> PLv*PLv*7/500;
        3 -> PLv*PLv*7/500;
        4 -> PLv*PLv*10/500;
        5 -> PLv*PLv*10/500;
        6 -> PLv*PLv*10/500;
        7 -> PLv*PLv*15/500;
        8 -> PLv*PLv*15/500;
        9 -> PLv*PLv*15/500;
        _ -> PLv*PLv*15/500
    end.

%% 获取对应轮数怪物经验数值
get_exp_value(Level, PLv) -> 
    case Level of
        1 -> PLv*PLv*60/24;
        2 -> PLv*PLv*60/24;
        3 -> PLv*PLv*60/24;
        4 -> PLv*PLv*70/24;
        5 -> PLv*PLv*70/24;
        6 -> PLv*PLv*70/24;
        7 -> PLv*PLv*90/24;
        8 -> PLv*PLv*90/24;
        9 -> PLv*PLv*90/24;
        _ -> PLv*PLv*90/24
    end.

