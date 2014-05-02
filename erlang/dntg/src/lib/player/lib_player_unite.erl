%% Author: zengzhaoyuan
%% Created: 2012-6-7
%% Description: TODO: 本文件方法，只适合公共线内部调用

-module(lib_player_unite).
-export([
		update_unite_info/2,
        get_unite_status_unite/1,
		spend_assets_status_unite/5,	 	%% 消耗玩家财富(元宝,铜币等等)
		trigger_achieve/3,						%% 触发成就
		trigger_target/2,							%% 触发西游目标
		trigger_fame/2,							%% 触发名人堂
		%% change by xieyunfei
		%%add_physical/2,							%% 扣减或增加体力
		add_exp_by_id/2	, 						%% 增加玩家经验
		trigger_active/2,							%% 触发活跃度
        get_unite_pid/1
    ]).
-include("unite.hrl").

%% 更新公共线的ets_unite数据
%% id:公共线用户pid
%% AttrKeyValueList:需要更新的列表[{sex, 1}, {name, Name}]
update_unite_info(Id, AttrKeyValueList) ->
	case lib_player_unite:get_unite_pid(Id) of
		false->void;
		UnitePid->
			gen_server:cast(UnitePid, {'set_data', AttrKeyValueList})		
	end.

%% 获取用户的公共服信息
get_unite_status_unite(Id) ->
    case misc:get_unite_process(Id) of
        Pid when is_pid(Pid) ->
            case catch gen:call(Pid, '$gen_call', 'base_data') of
                {ok, Res} ->
                    Res;
                _ ->
                    #unite_status{}
            end;
        _ ->
            #unite_status{}
    end.

%% 花费_使用玩家资产
%% @param PlayerId 玩家ID
%% @param Num 消费数量
%% @param Type 消费类型  原子
%% @param ConsumeType 产生消费的记录类型  原子 
%% @param ConsumeInfo 记录相关的信息      字符串
%% @return {ok, ok} 成功扣费并记录 
%%		   {error,ErrorCode}  0错误的玩家ID,1元宝不足,2参数错误 3无玩家进程 
spend_assets_status_unite(PlayerId, Num, Type, ConsumeType, ConsumeInfo) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
            gen_server:call(Pid, {spend_assets, [PlayerId, Num, Type, ConsumeType, ConsumeInfo]});
        _ ->
            {error,3}
    end.

%% 触发成就
%% @param PlayerId			玩家ID
%% @param TriggerType	触发类型，有trigger_task | trigger_equip | trigger_role | trigger_trial | trigger_social | trigger_hidden
%% @param Arg				参数
%% eg:lib_player_unite:trigger_achieve(PlayerId, trigger_trial, [PlayerId, 31, 0, 1]),
trigger_achieve(PlayerId, TriggerType, Arg) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
			gen_server:cast(Pid, {'apply_cast', mod_achieve, TriggerType, Arg});
        _ -> 
			%% 如果玩家游戏线刚好掉线，则不处理，等待GM等去修复
            skip
    end.

%% 触发名人堂
%% @param PlayerId		玩家ID
%% @param Arg 			参数
%% eg: lib_player_unite:trigger_fame(PlayerId, [合服时间mergetime, 玩家ID, 8, 0, 人物等级]) 
trigger_fame(PlayerId, Arg) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
			gen_server:cast(Pid, {'apply_cast', mod_fame, trigger, Arg});
        _ -> 
            skip
    end.

%% 触发西游目标
%% @param PlayerId		玩家ID
%% @param Arg 			参数
%% eg: lib_player_unite:trigger_target(PlayerId, [玩家ID, 8, 0, 人物等级]) 
trigger_target(PlayerId, Arg) ->
	case misc:get_player_process(PlayerId) of
		Pid when is_pid(Pid) ->
			gen_server:cast(Pid, {'apply_cast', mod_target, trigger, Arg});
		_ -> 
			case Arg of
				[_, _, TargetId, _] ->
					lib_target:trigger_offline(PlayerId, TargetId);
				_ ->
					skip
			end
    end.

%% change by xieyunfei 关闭之前增加体力值接口
%% 扣除或添加体力值
%% @param PlayerId		玩家ID
%% @param AddType 	操作类型，值从physical.hrl中获得
%% add_physical(PlayerId, CheckType) ->
%% 	case misc:get_player_process(PlayerId) of
%%         Pid when is_pid(Pid) ->
%% 			gen_server:cast(Pid, {add_physical, [PlayerId, CheckType]});
%%         _ -> 
%%             skip
%%     end.

%% 公共线增加玩家经验
%% @param PlayerId		玩家ID
%% @param 经验增加值		参数
add_exp_by_id(PlayerId, ExpAdd) ->
	case misc:get_player_process(PlayerId) of
		Pid when is_pid(Pid) ->
			gen_server:cast(Pid, {'EXP', ExpAdd});
        _ -> 
            skip
    end.

%% 触发活跃度
%% @param PlayerId		玩家ID
%% @param Arg 			参数
%% eg: lib_player_unite:trigger_active(玩家ID, [玩家ID, 4, 0]) 
trigger_active(PlayerId, Arg) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
			gen_server:cast(Pid, {trigger_active, Arg});		
        _ -> 
            skip
    end.

%%获取公共性进程
get_unite_pid(PlayerId) ->
	case misc:get_unite_process(PlayerId) of
        Pid when is_pid(Pid) ->
            Pid;
        _ ->
            false
    end.
