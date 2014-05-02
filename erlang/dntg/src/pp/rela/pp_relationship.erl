%%%--------------------------------------
%%% @Module  : pp_relationship
%%% @Author  : zhenghehe
%%% @Created : 2011.12.23
%%% @Description:  管理玩家间的关系
%%%--------------------------------------
-module(pp_relationship).
-export([handle/3]).

-include("common.hrl").
-include("unite.hrl").
-include("rela.hrl").
-include("server.hrl").
-include("scene.hrl").
%%14模块错误码
handle(14000, Status, [ErrorCode]) ->
    {ok,BinData} = pt_140:write(14000,[ErrorCode]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%%添加好友请求
%% List:请求列表[{BId,Type}]
%%BId:接收方用户ID
%%Type:加好友的类型(1:常规加好友,2:黑名单里加好友,3:仇人里加好友)
handle(14001, Status, List) ->
    case Status#player_status.scene =:= 250 orelse Status#player_status.scene =:= 251 of
	false ->
	    F = fun({BId, Type}) ->
			if
			    Status#player_status.id =:= BId ->
				handle(14000, Status, [1008]);
			    true ->
				Length = lib_relationship:get_friends_size(Status#player_status.pid,Status#player_status.id), 
				if
				    Length >= ?FD_NUM_MAX->
					handle(14000, Status, [1003]);
				    true->
					%%检查目标玩家是否在线
					case lib_player:get_pid_by_id(BId) of 
					    false ->
						handle(14000, Status, [1001]);
					    Pid ->
						%%判断目标玩家是否超过好友数上限
						LengthB = lib_relationship:get_friends_size(Pid, BId), 
						if
						    LengthB >= ?FD_NUM_MAX->
							handle(14000, Status, [1017]);
						    true ->
							lib_task:event(add_friend, do, Status#player_status.id),%%  完成添加好友任务
							%%验证是否已为好友关系
							case lib_relationship:get_rela_by_ABId(Status#player_status.pid,Status#player_status.id,BId) of
							    []->
								%%无任何关系,继续好友添加流程
								{ok,BinData} = pt_140:write(14001, [Status#player_status.id,Status#player_status.nickname,Type,Status#player_status.lv,Status#player_status.career,Status#player_status.realm,Status#player_status.sex,Status#player_status.image]),
								lib_server_send:send_to_uid(BId, BinData);
							    [L]->
								if
								    L#ets_rela.rela =:= 1 orelse L#ets_rela.rela =:= 4->
									handle(14000, Status, [1002]);
								    %%非好友关系,继续好友添加流程
								    true ->
									{ok,BinData} = pt_140:write(14001, [Status#player_status.id,Status#player_status.nickname,Type,Status#player_status.lv,Status#player_status.career,Status#player_status.realm,Status#player_status.sex,Status#player_status.image]),
									lib_server_send:send_to_uid(BId, BinData)
								end					
							end	
						end
					end
				end
			end,
			timer:sleep(50)
		end,
	    lists:foreach(F, List);
	true -> []
    end;

%%回应添加好友请求
%% List:回应列表[{BId,Type,Result}]
%% AId:发起方用户ID
%% Type:加好友的类型(1:常规加好友,2:黑名单里加好友,3:仇人里加好友)
%% Result:1接受|0拒绝
handle(14002, Status, List) ->
    case Status#player_status.scene =:= 250 orelse Status#player_status.scene =:= 251 of
	false ->
	    F = fun({AId, _Type, Result}) ->
			%%检查发起方是否在线
			case lib_player:get_pid_by_id(AId) of
			    false ->
				handle(14000, Status, [1001]);
			    Pid ->
				%%判断自己是否超过好友数上限
				Length = lib_relationship:get_friends_size(Status#player_status.pid,Status#player_status.id), 
				if
				    Length >= ?FD_NUM_MAX->
					handle(14000, Status, [1003]);
				    true ->
					%%判断对方是否超过好友数上限
					LengthB = lib_relationship:get_friends_size(Pid,AId), 
					if
					    LengthB >= ?FD_NUM_MAX->
						handle(14000, Status, [1017]);
					    true ->
						%%当接受添加好友请求时，做相关处理
						if
						    Result =:= 1 ->
							case lib_relationship:get_rela_by_ABId(Status#player_status.pid,Status#player_status.id,AId) of
							    %%无任何好友关系
							    [] -> 
								lib_relationship:add_rela(Status#player_status.pid,Status#player_status.id, AId, 1, Status#player_status.status_target);
							    %%更新好友关系
							    [L1] ->
								if
								    L1#ets_rela.rela =:= 2-> %仅为仇人，变成好友且仇人
									lib_relationship:update_rela(Status#player_status.pid,Status#player_status.id, AId, 4);
								    L1#ets_rela.rela =:= 3-> %仅为黑名单，变成好友
									lib_relationship:update_rela(Status#player_status.pid,Status#player_status.id, AId, 1);
								    L1#ets_rela.rela =:= 5-> %仇人且黑名单，变成好友且仇人
									lib_relationship:update_rela(Status#player_status.pid,Status#player_status.id, AId, 4);
								    true -> void
								end
							end,
							%% cast到AId那边做回应处理
							gen_server:cast(Pid, {'ack_add_rela', [Status#player_status.id, _Type, Result]}),
							StatusBin = lib_relationship:get_friend_info(Status),
							lib_server_send:send_to_uid(AId, StatusBin),
							StatusRelaSize = lib_relationship:get_friends_size(Status#player_status.pid,Status#player_status.id),
							%% 触发名人堂：谁人不识君，第一个拥有200个好友
							mod_fame:trigger(Status#player_status.mergetime, Status#player_status.id, 12, 0, StatusRelaSize),
							%% 触发成就：高朋满座：拥有N个好友
							%% StatusAchieve = Status#player_status.achieve,
							mod_achieve:trigger_social(Status#player_status.achieve, Status#player_status.id, 0, 0, StatusRelaSize);
						    true ->void
						end,
						%%向客户端返回处理结果
						{ok,BinData} = pt_140:write(14002, [Status#player_status.id,Status#player_status.nickname,Status#player_status.lv,Status#player_status.career,Result]),
						lib_server_send:send_to_uid(AId, BinData)	
					end
				end,
				timer:sleep(50)
			end
		end,
	    lists:foreach(F, List),
	    handle(14003, Status, [1]),
	    handle(14003, Status, [2]),
	    handle(14003, Status, [3]);
	true -> []
    end;

%%请求好友列表
handle(14003, Status, [Type]) ->
    %%加载或查询玩家的好友信息
    case Type of
	1 ->
	    L1 = lib_relationship:get_rela_list(Status#player_status.pid,Status#player_status.id,1),
	    L2 = lib_relationship:get_rela_list(Status#player_status.pid,Status#player_status.id,4),
	    L = lists:concat([L1,L2]),
	    {ok,BinData} = pt_140:write(14003, [L,Type]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
	2 ->
	    L1 = lib_relationship:get_rela_list(Status#player_status.pid,Status#player_status.id,2),
	    L2 = lib_relationship:get_rela_list(Status#player_status.pid,Status#player_status.id,4),
	    L3 = lib_relationship:get_rela_list(Status#player_status.pid,Status#player_status.id,5),
	    L = lists:concat([L1,L2,L3]),
	    {ok,BinData} = pt_140:write(14003, [L,Type]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
	3 ->
	    L1 = lib_relationship:get_rela_list(Status#player_status.pid,Status#player_status.id,3),
	    L2 = lib_relationship:get_rela_list(Status#player_status.pid,Status#player_status.id,5),
	    L = lists:concat([L1,L2]),
	    {ok,BinData} = pt_140:write(14003, [L,Type]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
	_ ->
	    []
    end;
	
%%请求删除好友
%% List:[{IdB}]
%% Type =:= 2时删除仇人
handle(14004, Status, [List,Type]) ->
    F = fun({IdB}) ->
		case Status#player_status.marriage#status_marriage.parner_id =:= IdB of
		    true -> [];
		    false ->
			case lib_relationship:remove_rela(Status#player_status.pid,Status#player_status.id,IdB,Type) of
			    none -> handle(14000, Status, [1004]),Flag = 0;
			    ok -> Flag = 1
			end,
			{ok,BinData} = pt_140:write(14004, [Flag]),
			lib_server_send:send_to_sid(Status#player_status.sid, BinData),
			timer:sleep(50)
		end
	end,
    lists:foreach(F, List),
    handle(14003, Status, [1]),
    handle(14003, Status, [2]),
    handle(14003, Status, [3]),
    EnemyList = lib_relationship:get_show_enemy_list(Status#player_status.pid, Status#player_status.id),
    {ok,Bin} = pt_140:write(14025, [EnemyList]),
    lib_server_send:send_to_sid(Status#player_status.sid, Bin);


%%更改好友关系
handle(14005, Status, [IdB,Type]) ->
    case Status#player_status.scene =:= 250 orelse Status#player_status.scene =:= 251 of
	false ->
	    case Type of
		1 -> %%好友有上限
		    Length = lib_relationship:get_friends_size(Status#player_status.pid,Status#player_status.id), 
		    if
			Length >= ?FD_NUM_MAX->
			    handle(14000, Status, [1003]);
			true->
			    lib_relationship:add_friend(Status#player_status.pid,Status#player_status.id, IdB, Status#player_status.status_target)
		    end;
		2 ->
		    lib_relationship:add_enemy(Status#player_status.pid,Status#player_status.id, IdB);
		3 ->
		    lib_relationship:add_blacklist(Status#player_status.pid,Status#player_status.id, IdB),
		    {ok,BinData} = pt_140:write(14005, [1]),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
		_ -> false
	    end,
	    handle(14003, Status, [1]),
	    handle(14003, Status, [2]),
	    handle(14003, Status, [3]);
	true -> []
    end;

%%请求新增好友分组
handle(14006, Status, [Name]) ->
    case util:check_keyword(Name) of
	false ->
	    %%加载玩家的好友分组列表
	    L = lib_relationship:load_user_rela_groupnames(Status#player_status.pid,Status#player_status.id),
	    if 
		length(L) >= ?GROUP_NUM_MAX - 1 ->
		    handle(14000, Status, [1006]),Flag = 0;
		true->
		    lib_relationship:add_rela_group(Status#player_status.pid,Status#player_status.id,Name),
		    handle(14007, Status, no),
		    Flag = 1
	    end,
	    {ok,BinData} = pt_140:write(14006, [Flag]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
	_ ->
	    {ok,BinData} = pt_140:write(14006, [0]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData)
    end;

%%获取好友分组列表 
handle(14007, Status, _) ->
    %%加载玩家的好友分组列表
    L = lib_relationship:load_user_rela_groupnames(Status#player_status.pid,Status#player_status.id),
    {ok,BinData} = pt_140:write(14007, [L]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%%删除好友分组
handle(14008, Status, [Id]) ->
    %%加载玩家的好友分组列表
    L = lib_relationship:load_user_rela_groupnames(Status#player_status.pid,Status#player_status.id),
    case [R||R<-L,R#ets_rela_group.id =:= Id] of
        [] -> 
	    handle(14000, Status, [1007]),
	    Flag = 0;
        [Rela_group] ->
	    if
		Rela_group#ets_rela_group.uid =:= Status#player_status.id ->
		    lib_relationship:delete_rela_group(Status#player_status.pid,Status#player_status.id,Id),
		    Flag = 1,
		    handle(14007, Status, Id);
		true -> 
		    handle(14000, Status, [1007]),
		    Flag = 0
	    end
    end,
    {ok,BinData} = pt_140:write(14008, [Flag]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%%更改好友分组名字
handle(14009, Status, [Id,Name]) ->
    case util:check_keyword(Name) of
	false ->
	    %%加载玩家的好友分组列表
	    L = lib_relationship:load_user_rela_groupnames(Status#player_status.pid,Status#player_status.id),
	    case [R||R<-L,R#ets_rela_group.id =:= Id] of
		[] -> 
		    handle(14000, Status, [1007]),
		    Flag = 0;
		[Rela_group] ->
		    if
			Rela_group#ets_rela_group.uid =:= Status#player_status.id ->
			    lib_relationship:update_rela_group_name(Status#player_status.pid,Status#player_status.id,Id,Name),
			    Flag = 1,
			    handle(14007, Status, Id);
			true -> 
			    handle(14000, Status, [1007]),
			    Flag = 0
		    end
	    end,
	    {ok,BinData} = pt_140:write(14009, [Flag]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
	_ ->
	    {ok,BinData} = pt_140:write(14009, [0]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData)
    end;

%%更改好友所在分组
handle(14010, Status, [IdB,Id]) ->
    %%验证好友关系
    case lib_relationship:get_rela_by_ABId(Status#player_status.pid,Status#player_status.id,IdB) of
	[]->
	    %%无任何关系
	    handle(14000, Status, [1004]),
	    Flag = 0;
        [L]->
	    if
		L#ets_rela.rela =/=1 andalso L#ets_rela.rela =/= 4->
		    handle(14000, Status, [1004]),
		    Flag = 0;
		true ->
		    %%加载玩家的好友分组列表
                    K = lib_relationship:load_user_rela_groupnames(Status#player_status.pid,Status#player_status.id),
		    case [R||R<-K,R#ets_rela_group.id =:= Id] of
			[] -> 
			    if
				Id =:= 0->%%移动到系统默认组
				    ok = lib_relationship:update_rela_group_id(Status#player_status.pid,Status#player_status.id,IdB,Id),
				    handle(14003, Status, [1]),
				    handle(14007, Status, Id),
				    Flag = 1;
				true->
				    handle(14000, Status, [1007]),
				    Flag = 0
			    end;
			[Rela_group] ->
			    if
				Rela_group#ets_rela_group.uid =:= Status#player_status.id ->
				    ok = lib_relationship:update_rela_group_id(Status#player_status.pid,Status#player_status.id,IdB,Id),
				    handle(14003, Status, [1]),
				    handle(14007, Status, Id),
				    Flag = 1;
				true -> 
				    handle(14000, Status, [1007]),
				    Flag = 0
			    end
		    end
	    end
    end,
    {ok,BinData} = pt_140:write(14010, [Flag]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%%按昵称搜索在线玩家
%% Status:#unite_status
handle(14011, Status, [Name]) ->
    %%检查目标玩家是否在线
    %% 	case ets:tab2list(?ETS_UNITE) of
    case mod_chat_agent:match(match_name, [util:make_sure_list(Name)]) of
	[] ->
            {ok,BinData} = pt_140:write(14011,[[]]),
	    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData);
        [L] ->
            R = [L],
	    {ok,BinData} = pt_140:write(14011, [R]),
            lib_unite_send:send_to_sid(Status#unite_status.sid, BinData)
    end;

%%添加密友请求
%%BId:接收方用户ID
handle(14012, Status, [BId]) ->
    if
        Status#player_status.id =:= BId ->
	    handle(14000, Status, [1009]);
        true ->
	    Length = lib_relationship:get_closely_relas_size(Status#player_status.pid,Status#player_status.id), 
	    Closely_max = lib_relationship:get_closely_max(Status#player_status.vip#status_vip.vip_type),
	    if
		Length >= Closely_max->
		    handle(14000, Status, [1012]);
		true->
		    %%检查目标玩家是否在线
		    case lib_player:get_pid_by_id(BId) of
			false ->
			    handle(14000, Status, [1001]);
			Pid ->
			    PlayerLength = lib_relationship:get_closely_relas_size(Pid, BId), 
			    Vip = lib_player:get_player_info(BId, vip),
			    PlayerClosely_max = lib_relationship:get_closely_max(Vip),
			    if
				PlayerLength >= PlayerClosely_max->
				    handle(14000, Status, [1014]);
				true->
				    %%验证是否已为好友关系
				    case lib_relationship:get_rela_by_ABId(Status#player_status.pid,Status#player_status.id,BId) of
					[]->
					    %%无任何关系,终止添加过程
					    handle(14000, Status, [1010]);
					[L]->
					    if
						L#ets_rela.rela =:= 1 orelse L#ets_rela.rela =:= 4 ->
						    if
							L#ets_rela.closely =:= 1->
							    handle(14000, Status, [1010]);
							true->
							    {ok,BinData} = pt_140:write(14012, [Status#player_status.id,Status#player_status.nickname,Status#player_status.lv,Status#player_status.career]),
							    lib_server_send:send_to_uid(BId, BinData)
						    end;
						%%非好友关系,终止添加过程
						true ->
						    handle(14000, Status, [1010])
					    end					
				    end
			    end
		    end
	    end
    end;

%%回应添加密友请求
handle(14013, Status, [AId,Result]) ->
    %%检查目标玩家是否在线
    case lib_player:get_pid_by_id(AId) of
        false ->
            handle(14000, Status, [1001]);
        Pid ->
	    %%判断自己是否超过密友数上限
	    Length = lib_relationship:get_closely_relas_size(Status#player_status.pid,Status#player_status.id), 
	    Closely_max = lib_relationship:get_closely_max(Status#player_status.vip#status_vip.vip_type),
	    if
		Length >= Closely_max->
		    handle(14000, Status, [1012]);
		true ->
		    %%当接受添加好友请求时，做相关处理
		    if
			Result =:= 1 ->
			    case lib_relationship:get_rela_by_ABId(Status#player_status.pid,Status#player_status.id,AId) of
				%%无任何好友关系
				[] -> 
				    handle(14000, Status, [1010]);
				%%更新好友关系
				[L1] ->
				    if
					%% 双方为好友关系
					L1#ets_rela.rela =:= 1 orelse L1#ets_rela.rela =:= 4->
					    lib_relationship:update_closely(Status#player_status.pid,Status#player_status.id, AId, 1);
					true -> void
				    end
			    end,
			    gen_server:cast(Pid, {'ack_add_closely_rela', [Status#player_status.id, Result]}),
			    %%更新双方的好友列表信息
			    handle(14003, Status, [1]),
			    handle(14003, Status, [2]),
			    handle(14003, Status, [3]);
			true ->void
		    end,
		    %%向客户端返回处理结果
		    {ok,BinData} = pt_140:write(14013, [Status#player_status.id,Status#player_status.nickname,Status#player_status.lv,Status#player_status.realm,Result]),
		    lib_server_send:send_to_uid(AId, BinData)
	    end
    end;

%%取消密友请求
%%BId:接收方用户ID
handle(14014, Status, [BId]) ->
    if
        Status#player_status.id =:= BId ->
	    Result = 0,
	    handle(14000, Status, [1009]);
        true ->
	    %%验证是否已为好友关系
	    case lib_relationship:get_rela_by_ABId(Status#player_status.pid,Status#player_status.id,BId) of
		[]->
		    %%无任何关系,终止添加过程
		    Result = 0,
		    handle(14000, Status, [1010]);
                [L]->
		    if
			L#ets_rela.rela =:= 1 orelse L#ets_rela.rela =:= 4 ->
			    if
				L#ets_rela.closely =:= 1->
				    Result = 1,
				    lib_relationship:update_closely(Status#player_status.pid,Status#player_status.id, BId, 0),
				    case lib_player:get_pid_by_id(BId) of
					false ->
					    db:execute(io_lib:format(<<"update relationship set closely=~p where (idA=~p and idB=~p) and (rela=1 or rela=4)">>, [0,BId,Status#player_status.id]));
					BPid ->
					    gen_server:cast(BPid, {'cancel_closely', [Status#player_status.id]})
				    end,
				    handle(14003, Status, [1]);
				true->
				    Result = 0,
				    handle(14000, Status, [1013])
			    end;
			%%非好友关系,终止添加过程
			true ->
			    Result = 0,
			    handle(14000, Status, [1010])
                    end					
	    end
    end,
    {ok,BinData} = pt_140:write(14014, [Result]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData);

%%好友祝福
%%UpId:被祝福玩家ID _UpLv:被祝福玩家等级
handle(14016, Status, [UpId,_UpLv,BlessType]) ->
    case is_record(Status, player_status) of
	true ->
	    Bless = Status#player_status.bless,
	    {{Year,Month,Day},_Time} = calendar:local_time(),
	    The_Date = lists:concat([Year,"-",Month,"-",Day]),
	    if
		The_Date =:= Bless#status_bless.bless_send_last_time -> %同一天
		    if
			Bless#status_bless.bless_send < ?MAX_BLESS_SEND ->
			    Bless_send = Bless#status_bless.bless_send + 1,
			    Bless_Flag = 1; %祝福次数+1
			true->
			    Bless_send = ?MAX_BLESS_SEND,
			    Bless_Flag = 0 %当天祝福次数已满
		    end;
		true->
		    Bless_send = 1,
		    Bless_Flag = 1  %祝福已隔天
	    end,
	    if
		Bless_Flag =:= 1 ->
		    %%检查目标玩家是否在线
		    case lib_player:get_pid_by_id(UpId) of
			false ->
			    handle(14000, Status, [1015]);
			Pid ->
			    case lib_relationship:get_rela_by_ABId(Pid,UpId,Status#player_status.id) of %好友是单方向维护的
				[]->
				    handle(14000, Status, [1004]);
				[Rela]->
				    case mod_exit:lookup_send_gift(Status#player_status.id, _UpLv, UpId) of
					undefined ->
					    Reply = gen_server:call(Pid, {'friend_bless', [Status#player_status.lv,_UpLv,BlessType]}),
					    [{Total_Exp_NO_Up, Total_LLPT_NO_Up}, {UpLv, Exp, Llpt, ExtExp, ExtLlpt,Cishu}] = Reply,
					    %%更改非升级玩家属性
					    Status1 = lib_player:add_exp(Status, Total_Exp_NO_Up),
					    Status2 = lib_player:add_pt(llpt, Status1, Total_LLPT_NO_Up),
					    lib_relationship:update_bless_send(Status2#player_status.id,Bless_send,The_Date),
					    New_Bless = Bless#status_bless{
							  bless_send = Bless_send,   %%当天好友祝福发送次数
							  bless_send_last_time = The_Date   %%最后一次发送祝福日期
							 },
					    NewStatus = Status2#player_status{bless=New_Bless},
					    if
						Cishu =< ?MAX_BLESS_ACCEPT ->
						    %%发送协议
						    {ok,Bin_14016} = pt_140:write(14016, [Total_Exp_NO_Up,Total_LLPT_NO_Up,Bless_send]),
						    lib_server_send:send_to_sid(NewStatus#player_status.sid, Bin_14016),
						    %%发给升级方
						    {ok,Bin_14017} = pt_140:write(14017, [Status#player_status.id,
											  Status#player_status.nickname,
											  BlessType,
											  UpLv,
											  Exp,
											  Llpt,
											  ExtExp,
											  ExtLlpt,
											  Rela#ets_rela.bless_gift_id]),
						    lib_server_send:send_to_uid(UpId, Bin_14017),
						    mod_exit:insert_send_gift(NewStatus#player_status.id, _UpLv, UpId);
						true ->
						    []
					    end;
					_ ->
					    NewStatus = Status
				    end,
				    {ok, NewStatus}
			    end
		    end;
		true->
		    handle(14000, Status, [1016])
	    end;
	false ->
	    []
    end;

%%回赠领取
%%BId:接收方用户ID
handle(14018, PS, List) ->
    case is_record(PS, player_status) of
	true ->
	    F = fun({Uid,Lv,_Exp,_Llpt,_ExtExp,_ExtLlpt,BackBlessType}, Status) ->
			case lib_relationship:get_rela_by_ABId(Status#player_status.pid,Status#player_status.id,Uid) of
			    []->
				handle(14000, Status, [1004]),
				{ok, Status};
			    [_Rela]->
				if
				    Lv >= 26 andalso Lv =< 100 ->
					case mod_exit:lookup_bless_gift(Status#player_status.id, Lv, Uid) of
					    undefined ->
						[Gift_Id,Gift_Price,Gift_Name] = lib_relationship:get_bless_gift(BackBlessType),
						if
						    Gift_Id =:= 0 andalso Gift_Price =:= 0->
							mod_exit:insert_bless_gift(Status#player_status.id, Lv, Uid),
							StatusCostOk = Status,
							Flag = true;
						    true->
							case lib_goods_util:is_enough_money(Status, Gift_Price, gold) of
							    true ->
								timer:sleep(50),
								StatusCostOk = lib_goods_util:cost_money(Status, Gift_Price, gold),
								mod_exit:insert_bless_gift(Status#player_status.id, Lv, Uid),
								log:log_consume(bless_gift, gold, Status, StatusCostOk, lists:concat(["Bless Gift ",Gift_Id])),
								%%发送邮件
								Title = data_mail_log_text:get_mail_log_text(bless_title),
								Content = io_lib:format(data_mail_log_text:get_mail_log_text(bless_content),[Status#player_status.nickname,Gift_Name]),
								mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg,[[Uid], Title, Content, Gift_Id, 2, 0, 0,1,0,0,0,0]),
								%%检查目标玩家是否在线，更新最贵祝福礼包
								case lib_player:get_pid_by_id(Uid) of
								    false ->
									void;
								    Pid ->
									Reply = gen_server:call(Pid, {'friend_bless_gift', Status#player_status.id, Gift_Id}),
									{FriendId, FriendRealm, FriendNick, FriendSex, FriendCareer, FriendImage} = Reply,
									%%好友祝福馈赠传闻
									lib_chat:send_TV({all},0,2,[friendZF,1,FriendId,FriendRealm,FriendNick,FriendSex,FriendCareer,FriendImage,Status#player_status.id,Status#player_status.realm,Status#player_status.nickname,Status#player_status.sex,Status#player_status.career,Status#player_status.image,Gift_Id])
								end,
								Flag = true;
							    false ->	
								StatusCostOk = Status,
								Flag = false
							end
						end;
					    _ ->
						StatusCostOk = Status,
						Flag = true
					end;
				    true ->
					StatusCostOk = Status,
					Flag = true
				end,
				case Flag of
				    false->
					{ok,Bin_14018} = pt_140:write(14018, [2,Uid,Lv]),
					lib_server_send:send_to_sid(Status#player_status.sid, Bin_14018),
					{ok, StatusCostOk};
				    true->
					{ok,Bin_14018} = pt_140:write(14018, [1,Uid,Lv]),
					lib_server_send:send_to_sid(Status#player_status.sid, Bin_14018),
					{ok, StatusCostOk}
				end
			end
		end,
	    {ok ,NewPS} = lib_relationship:foreach_ex(F, List, PS),
	    lib_player:refresh_client(NewPS#player_status.id, 2),
	    {ok, NewPS};
	false ->
	    []
    end;
%% 查看经验瓶
handle(14019, Status, []) ->
    Bless = Status#player_status.bless,
    {ok,Bin_14019} = pt_140:write(14019, [Bless#status_bless.bless_is_exchange,
					  Bless#status_bless.bless_exp,
					  Bless#status_bless.bless_llpt,
					  Bless#status_bless.bless_friend_used]),
    lib_server_send:send_to_sid(Status#player_status.sid, Bin_14019),
    ok;
%% 领取经验瓶
handle(14020, Status, []) ->
    Bless = Status#player_status.bless,
    case Bless#status_bless.bless_is_exchange of
	0->
	    Status1 = lib_player:add_exp(Status, Bless#status_bless.bless_exp),
	    Status2 = lib_player:add_pt(llpt, Status1, Bless#status_bless.bless_llpt),
	    lib_relationship:update_bless_exchange(Status2#player_status.id,1),
	    NewBless = Bless#status_bless{
			  bless_is_exchange = 1
			 },
	    Flag = 1;
	_->
	    Status2 = Status,
	    NewBless = Bless,
	    Flag = 0
    end,
    {ok,Bin_14020} = pt_140:write(14020, [Flag]),
    lib_server_send:send_to_sid(Status#player_status.sid, Bin_14020),
    NewStatus = Status2#player_status{bless=NewBless},
    handle(14019, NewStatus, []),
    {ok,NewStatus};

%% 使用一键征好友
handle(14022, Status, []) ->
    Lv = Status#player_status.lv,
    Bless = Status#player_status.bless,
    if
	33 =< Lv->
	    if
		Bless#status_bless.bless_friend_used < 3->
		    Flag = true;
		true->
		    Flag = false
	    end;
	29 =< Lv->
	    if
		Bless#status_bless.bless_friend_used < 2->
		    Flag = true;
		true->
		    Flag = false
	    end;
	22 =< Lv->
	    if
		Bless#status_bless.bless_friend_used < 1->
		    Flag = true;
		true->
		    Flag = false
	    end;
	true->
	    Flag = false
    end,
    case Flag of
	false->
	    {ok,Bin_14022} = pt_140:write(14022, [Bless#status_bless.bless_friend_used]),
	    lib_server_send:send_to_sid(Status#player_status.sid, Bin_14022),
	    NewStatus = Status;
	true->
	    NewBless = Bless#status_bless{bless_friend_used = Bless#status_bless.bless_friend_used + 1},
	    lib_relationship:update_bless_friend_used(Status#player_status.id),
	    {ok,Bin_14022} = pt_140:write(14022, [Bless#status_bless.bless_friend_used + 1]),
	    lib_server_send:send_to_sid(Status#player_status.sid, Bin_14022),
	    NewStatus = Status#player_status{bless=NewBless}
    end,
    {ok,NewStatus};

%% 使用通缉令
handle(14023, Status, [WantedId, GoodsTypeId]) ->
    case mod_disperse:call_to_unite(mod_chat_agent, lookup, [WantedId]) of
	[] -> SceneName = <<"">>;
	[Player] ->
	    Scene = data_scene:get(Player#ets_unite.scene),
	    case is_record(Scene, ets_scene) of
		false-> SceneName = <<"">>;
		true-> SceneName = Scene#ets_scene.name
	    end
    end,
    Goods = Status#player_status.goods,
    case gen_server:call(Goods#status_goods.goods_pid, {'delete_more', GoodsTypeId, 1}) of
	1 ->
	    {ok,Bin} = pt_140:write(14023, [1, SceneName]),
	    lib_server_send:send_to_sid(Status#player_status.sid, Bin),
	    lib_relationship:update_wanted(Status#player_status.pid, Status#player_status.id, WantedId, 1),
	    handle(14003, Status, [2]),
	    spawn(fun() ->
			  timer:sleep(30 * 60 * 1000),
			  lib_relationship:update_wanted(Status#player_status.pid, Status#player_status.id, WantedId, 0),			  
			  handle(14003, Status, [2])
		     end);
	GoodsModuleCode ->
	    util:errlog("pp_relationship: Call goods module faild, result code=[~p]", [GoodsModuleCode]),
	    {ok,Bin} = pt_140:write(14023, [0, <<"">>]),
	    lib_server_send:send_to_sid(Status#player_status.sid, Bin)
    end;
%% 仇人标识
handle(14025, Status, _) ->
    EnemyList = lib_relationship:get_show_enemy_list(Status#player_status.pid, Status#player_status.id),
    {ok,Bin} = pt_140:write(14025, [EnemyList]),
    lib_server_send:send_to_sid(Status#player_status.sid, Bin);

handle(14026, _Status, [_Enemy, _Flag]) ->
    %% case lib_relationship:update_show_enemy_flag(Status#player_status.pid, Status#player_status.id, Enemy, Flag) of
    %% 	ok ->
    %% 	    EnemyList = lib_relationship:get_show_enemy_list(Status#player_status.pid, Status#player_status.id),
    %% 	    {ok,Bin} = pt_140:write(14026, [1, EnemyList]),
    %% 	    lib_server_send:send_to_sid(Status#player_status.sid, Bin);
    %% 	_ ->
    %% 	    EnemyList = lib_relationship:get_show_enemy_list(Status#player_status.pid, Status#player_status.id),
    %% 	    {ok,Bin} = pt_140:write(14026, [0, EnemyList]),
    %% 	    lib_server_send:send_to_sid(Status#player_status.sid, Bin)
    %% end.
    ok;

%% 删除双方好友关系
handle(14027, Status, [Type, IdB, IsTick]) ->
    case IsTick =:= 0 of
	true ->
	    case Status#player_status.marriage#status_marriage.parner_id =:= IdB of
		true -> [];
		false ->
		    %% 单向删除
		    case lib_relationship:remove_rela(Status#player_status.pid,Status#player_status.id,IdB,Type) of
			none -> handle(14000, Status, [1004]),Flag = 0;
			ok -> Flag = 1
		    end,
		    {ok,BinData} = pt_140:write(14027, [Flag]),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData)
	    end;
	false ->
	    %% 双向删除
	    case lib_relationship:delete_rela_for_divorce(Status#player_status.pid,Status#player_status.id,IdB) of
		none -> handle(14000, Status, [1004]),Flag = 0;
		ok -> Flag = 1
	    end,
	    {ok,BinData} = pt_140:write(14027, [Flag]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData)
    end,
    handle(14003, Status, [Type]),
    EnemyList = lib_relationship:get_show_enemy_list(Status#player_status.pid, Status#player_status.id),
    {ok,Bin} = pt_140:write(14025, [EnemyList]),
    lib_server_send:send_to_sid(Status#player_status.sid, Bin);

%% 好友祝福新春特别版 
handle(14028, Status, [_Name, Wish]) ->
    %%检查目标玩家是否在线
    Name = util:make_sure_list(_Name),
    case mod_disperse:call_to_unite(mod_chat_agent, match, [match_name, [Name]]) of
	[] ->
            {ok,BinData} = pt_140:write(14028,[0]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
        [H|_] ->
	    case gen_server:call(Status#player_status.goods#status_goods.goods_pid, {'delete_more', 522012, 1}) of
		1 ->
		    %% %% 给自己发邮件
		    %% Title1 = data_relationship:get_mail_title(1),
		    %% Content1 = data_relationship:get_mail_content(1,Name),
		    %% mod_disperse:cast_to_unite(lib_mail,send_sys_mail_bg,[[Status#player_status.id], Title1, Content1, 534201, 2, 0, 0, 1, 0, 0, 0, 0]),
		    %% %% 给对方发邮件
		    %% Title2 = data_relationship:get_mail_title(2),
		    %% Content2 = data_relationship:get_mail_content(2,Status#player_status.nickname),
		    %% mod_disperse:cast_to_unite(lib_mail,send_sys_mail_bg,[[H#ets_unite.id], Title2, Content2, 534202, 2, 0, 0, 1, 0, 0, 0, 0]),
		    {ok,BinData} = pt_140:write(14028,[1]),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData), 
		    %% 给H发送提示，索要利是
		    {ok,Bin14029} = pt_140:write(14029, [Status#player_status.id, Status#player_status.nickname, Wish]),
		    lib_server_send:send_to_uid(H#ets_unite.id, Bin14029);
		_ ->
		    {ok,BinData} = pt_140:write(14028,[2]),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData)
	    end
    end;

handle(14030, Status, [WantId, _N]) ->
    N = 1,
    Count = mod_daily_dict:get_count(WantId,1401),
    %% case is_integer(N) andalso N > 0 of
    %% 	false -> []; 
    %% 	true ->
    case N + Count > 10 of
	true ->
	    {ok,BinData} = pt_140:write(14030,[4]),
	    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
	false -> 
	    TotalCost = 10*N,
	    case Status#player_status.gold < TotalCost of
		true ->
		    {ok,BinData} = pt_140:write(14030,[2]),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
		false ->
		    %% 发送世界传闻
		    case lib_player:get_player_info(WantId, sendTv_Message) of
			false ->
			    {ok,BinData} = pt_140:write(14030,[3]),
			    lib_server_send:send_to_sid(Status#player_status.sid, BinData);
			[FriendId,FriendRealm,FriendNick,FriendSex,FriendCareer,FriendImage] ->
			    mod_daily_dict:plus_count(WantId,1401,N),
			    NewStatus = lib_goods_util:cost_money(Status, TotalCost, gold),
			    lib_player:refresh_client(Status#player_status.id, 2),
			    lib_chat:send_TV({all},0,2,[springGift,1,FriendId,FriendRealm,FriendNick,FriendSex,FriendCareer,FriendImage,Status#player_status.id,Status#player_status.realm,Status#player_status.nickname,Status#player_status.sex,Status#player_status.career,Status#player_status.image,534197,N]),
			    %% 发邮件到WantId
			    Title = data_relationship:get_mail_title(3),
			    Content = data_relationship:get_mail_content(3,Status#player_status.nickname), 
			    mod_disperse:cast_to_unite(lib_mail,send_sys_mail_bg,[[WantId], Title, Content, 534197, 2, 0, 0, N, 0, 0, 0, 0]),
			    {ok,BinData} = pt_140:write(14030,[1]),
			    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
			    {ok, NewStatus}
		    end
	    end
    %% end
    end;
	    
%% 错误处理
handle(_Cmd, _Status, _Data) ->
    {error, "pp_relationship no match"}.
