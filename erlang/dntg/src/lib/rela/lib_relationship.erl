%%%--------------------------------------
%%% @Module  : lib_relationship
%%% @Author  : zhenghehe
%%% @Created : 2011.12.23
%%% @Description: 玩家关系相关处理
%%%--------------------------------------

-module(lib_relationship).
-compile(export_all).
-include("rela.hrl").
-include("unite.hrl").
-include("common.hrl").
-include("server.hrl").
%%好友礼包数据
%%@param Type 礼包类型  1低级 2中级 3高级
%%@return [Id,Price,Name]
get_bless_gift(Type)->
    case Type of
	2->[535111,1,"高级回赠礼包"];
	3->[535112,5,"特级回赠礼包"];
	4->[535113,10,"超级回赠礼包"];
	_->[0,0,""]
    end.

%%获取祝福礼包次序
%%@param Gift_id 礼包ID
%%@return 次序。数字越大，越高。
get_max_bless_gift(Gift_id)->
    case Gift_id of
	535111->1;
	535112->2;
	535113->3;
	_->0
    end.

%%好友升级祝福通知
%%@param 参数均为升级玩家的信息
bless_notice(PlayerPid, Id, Nick, Lv, Sex, Career, Image, Realm)->
    if
	Lv=<25->void;
	Lv=<70->
	    if
		Lv rem 2 =:=0->
		    send_bless_notice(PlayerPid, Id, Nick, Lv, Sex, Career, Image, Realm);
		true->
		    void
	    end;
	true->
	    send_bless_notice(PlayerPid, Id, Nick, Lv, Sex, Career, Image, Realm)
    end,
    ok.

send_bless_notice(PlayerPid, Id, Nick, Lv, Sex, Career, Image, Realm) ->
    {{Year,Month,Day},_Time} = calendar:local_time(),
    TheDate = lists:concat([Year,"-",Month,"-",Day]),
    case lib_relationship:load_friends_by_id(PlayerPid, Id) of
	[]->
	    void;
	List->
	    %% 所有好友发送一遍
	    F = fun(E)->
                case Id =/= E#ets_rela.idB of
                    true ->
                        case lib_player:get_pid_by_id(E#ets_rela.idB) of
                            false ->
                                void;
                            Pid ->
                                gen_server:cast(Pid, {'bless_notice_handle', Id, Nick, Lv, Sex, Career, Image, Realm, TheDate})
                        end;
                    false ->
                        void
                end
		end,
	    lists:foreach(F, List)
    end.

load_player_bless(Id)->
    [Id,Bless_exp, Bless_llpt,Bless_is_exchange,Bless_send,Bless_friend_used,Bless_send_last_time] = db:get_row(io_lib:format(?sql_select_player_bless, [Id])),
    #status_bless{
		   id = Id,		
		   bless_exp = Bless_exp,					   %%经验瓶储存经验
		   bless_llpt = Bless_llpt,					   %%经验瓶储存历练声望
		   bless_is_exchange = Bless_is_exchange,			   %%是否已经兑换			  
		   bless_send = Bless_send,					   %%当天好友祝福发送次数
		   bless_friend_used = Bless_friend_used, 
		   bless_send_last_time = binary_to_list(Bless_send_last_time),	   %%最后一次发送祝福日期
		   bless_accept = dict:new()          %%接受祝福的次数 Key-等级 Value-次数				  
		 }.
update_bless_exp_llpt(Id,Exp,Llpt)->
    db:execute(io_lib:format(?SQL_UPDATE_BLESS_EXP_LLPT, [Exp,Llpt,Id])),
    ok.
update_bless_send(Id,Send,Send_Time)->
    db:execute(io_lib:format(?SQL_UPDATE_BLESS_SEND, [Send,Send_Time,Id])),
    ok.
update_bless_exchange(Id,Exchange)->
    db:execute(io_lib:format(?SQL_UPDATE_BLESS_is_exchange, [Exchange,Id])),
    ok.
update_bless_friend_used(Id)->
    db:execute(io_lib:format(?SQL_UPDATE_BLESS_friend_used, [Id])),
    ok.


%%加载玩家所有的好友关系，先进程字典中获取，如果无记录，从DB中获取
%%@param Uid 玩家ID
%%@return []|[#ets_rela]
load_relas(UnitePid,Uid)->
    Relas = getRelas(UnitePid),
    if
	Relas=:= undefined ->
	    L = find_relas(Uid),
	    if
		length(L) > 0 ->
		    NRelas = [list_to_tuple([ets_rela|R]) || R <- L],
		    setRelas(UnitePid,NRelas),
		    NRelas;
		true ->[]
	    end;
	true->
	    Relas	
    end.

%%获取指定玩家的某种关系好友信息。
%%@param Uid 指定玩家ID
%%@param Type 1=>好友 2=>仇人 3=>黑人
%%@return []|[#ETS_RELA]
load_relas_by_id(PlayerPid,Uid,Type)->
    case load_relas(PlayerPid,Uid) of
	[]->
	    [];
	Relas ->
	    [R||R<-Relas,R#ets_rela.rela=:=Type]
    end.

%% 获取指定玩家的好友信息,包括好友与好友且仇人关系。
%% @param Uid 指定玩家ID
%% @return []|[#ETS_RELA]
load_friends_by_id(PlayerPid,Uid)->
    case load_relas(PlayerPid,Uid) of
	[]->
	    [];
	Relas ->
	    [R||R<-Relas,R#ets_rela.rela =:= 1 orelse R#ets_rela.rela =:= 4]
    end.
%%获取指定玩家的密友列表。
%%@param UnitePid 公共性进程Pid
%%@param Uid 指定玩家ID
%%@return []|[#ETS_RELA]
load_closely_relas(UnitePid,Uid)->
    case load_relas(UnitePid,Uid) of
	[]->
	    [];
	Relas ->
	    [R||R<-Relas,R#ets_rela.rela =:= 1 orelse R#ets_rela.rela =:= 4,R#ets_rela.closely =:= 1]
    end.

%% 获取指定玩家的好友信息,包括好友与好友且仇人关系。
%% @param Uid 指定玩家ID
%% @return []|[#ETS_RELA]
load_enemy_by_id(PlayerPid,Uid)->
    case load_relas(PlayerPid,Uid) of
	[]->
	    [];
	Relas ->
	    [R||R<-Relas,R#ets_rela.rela =:= 2 orelse R#ets_rela.rela =:= 4 orelse R#ets_rela.rela =:= 5]
    end.

%%%%获取指定玩家的密友数目。
%%@param UnitePid 公共性进程Pid
%%@param Uid 指定玩家ID
%%@return int
get_closely_relas_size(UnitePid,Uid)->
    L = load_closely_relas(UnitePid,Uid),
    length(L).

%% 按照Vip等级不同，获取不同的密友上限。
%% @param Vip 类型
%% @return int
get_closely_max(Vip)->
    case Vip of
	1-> 10;
	2-> 15;
	3-> 20;
	_-> 5
    end.

%%查找角色信息(从缓存中读取，如果没有则从数据库中读取)
%%@param Uid 玩家ID
%%@retur [] | #ETS_RELA_INFO
load_user_info_by_id(Uid) ->
    case ets:lookup(?ETS_RELA_INFO, Uid) of
        [] ->
            case find_info(Uid) of
                [] ->
                    [];
                [Id, Nick, Sex, Lv, Career,Realm,Image, Last_login_time] -> 
                    R = #ets_rela_info{id = Id, 
				       nickname = Nick, 
				       sex = Sex, 
				       lv = Lv, 
				       career = Career,
				       realm = Realm,
				       image = Image,
				       last_login_time = Last_login_time},
                    ets:insert(?ETS_RELA_INFO, R),
                    R
            end;
        [Info] -> Info
    end.

%%更新玩家好友等级（在公共线执行）
update_user_rela_lv(Uid,Lv)->
    case ets:lookup(?ETS_RELA_INFO, Uid) of
        [] ->
            void;
        [Info] -> 
	    New_Info = Info#ets_rela_info{lv=Lv},
	    ets:insert(?ETS_RELA_INFO, New_Info)
    end.

%%更新玩家好友场景（在公共线执行）
update_user_rela_scene(Uid,Scene)->
    case ets:lookup(?ETS_RELA_INFO, Uid) of
        [] ->
            void;
        [Info] ->
	    New_Info = Info#ets_rela_info{scene=Scene},
	    ets:insert(?ETS_RELA_INFO, New_Info)
    end.
%% 更新好友信息（在公共线执行）
update_user_rela_info(Uid, Lv, Vip, Nick, Sex, Realm, Career, OnlineFlag, Scene, LLT, Image, Longitude, Latitude) ->
    NewInfo = #ets_rela_info{
      id = Uid,
      nickname = Nick,
      lv = Lv,
      vip = Vip,
      sex = Sex,
      realm = Realm,
      career = Career,
      online_flag = OnlineFlag,
      scene = Scene,
      last_login_time = LLT,
      image = Image,
      longitude = Longitude,
      latitude = Latitude
     },
    ets:insert(?ETS_RELA_INFO, NewInfo).

send_online_change(Pid, PlayerId, OnlineFlag) ->
    L1 = load_relas_by_id(Pid, PlayerId, 1),
    L2 = load_relas_by_id(Pid, PlayerId, 4),
    L = lists:concat([L1,L2]),
    lists:foreach(fun(X) ->
			  {ok,BinData} = pt_140:write(14024, [PlayerId, OnlineFlag]),
			  lib_server_send:send_to_uid(X#ets_rela.idB, BinData)
		  end, L).
		     

%% 更新玩家通辑情况
%% @param Type:0不通辑，1通辑
update_wanted(PlayerPid, AId, BId, Type) ->
    case get_rela_by_ABId(PlayerPid,AId,BId) of
	[] -> false;
	[Rela] ->
	    case Rela#ets_rela.rela =:= 2 orelse Rela#ets_rela.rela =:= 4 orelse Rela#ets_rela.rela =:= 5 of
		true ->
		    NewRela = Rela#ets_rela{wanted = Type},
		    Relas = load_relas(PlayerPid, AId),
		    DRelas = lists:delete(Rela, Relas),
		    setRelas(PlayerPid, lists:append([DRelas,[NewRela]]));
		false ->
		    []
	    end
    end.

%% 获取玩家自定义分组名
%% @param Uid 玩家ID
%% @return []|[#ets_rela_group]
load_user_rela_groupnames(UnitePid,Uid) ->
    Rela_groupnames = getRela_groupnames(UnitePid),
    if
	Rela_groupnames=:= undefined ->
	    L = find_rela_group_name(Uid),
	    if
		length(L) > 0 ->
		    NRela_groupnames = [list_to_tuple([ets_rela_group|R]) || R <- L],
		    setRela_groupnames(UnitePid,NRela_groupnames),
		    NRela_groupnames;
		true ->[]
	    end;
	true->
	    Rela_groupnames	
    end.

%% 获取组名
%% @param Id 组名ID
%% @param Uid 玩家ID
%% @return {Id,group_name}
get_rela_groupname_by_id(UnitePid,Id,Uid)->
    Rela_groupnames = load_user_rela_groupnames(UnitePid,Uid),
    Rela_groupname = [R||R<-Rela_groupnames,R#ets_rela_group.id =:= Id],
    case Rela_groupname of
	[] ->
	    A = #ets_rela_group{},
	    {0,A#ets_rela_group.group};
	[L] -> {L#ets_rela_group.id,L#ets_rela_group.group}
    end.

%%获取玩家的好友列表对象
%%@param Uid 玩家ID
get_rela_list(UnitePid,Uid,Type)->
    L = load_relas_by_id(UnitePid,Uid,Type),
    R = get_rela_list_sub(UnitePid,L,[]),
    R.
%% @param L #ets_rela
get_rela_list_sub(_UnitePid,[],R)->R;
get_rela_list_sub(UnitePid,L,R)->
    [H|T] = L,
    case mod_disperse:call_to_unite(lib_relationship, load_user_info_by_id, [H#ets_rela.idB]) of
        Info when is_record(Info, ets_rela_info) ->
            {Group_id,Group_name} = get_rela_groupname_by_id(UnitePid,H#ets_rela.group,H#ets_rela.idA),
            E = {Group_id,
                Group_name,
                H#ets_rela.idB,
                Info#ets_rela_info.nickname,
                Info#ets_rela_info.image,
                Info#ets_rela_info.online_flag,
                Info#ets_rela_info.lv,
                Info#ets_rela_info.vip,
                Info#ets_rela_info.scene,
                Info#ets_rela_info.sex,
                Info#ets_rela_info.realm,
                Info#ets_rela_info.career,
                H#ets_rela.intimacy,
                H#ets_rela.closely,
                H#ets_rela.killed_by_enemy,
                H#ets_rela.hatred_value,
                H#ets_rela.wanted,
                Info#ets_rela_info.last_login_time,
                Info#ets_rela_info.longitude,
                Info#ets_rela_info.latitude
            },
            get_rela_list_sub(UnitePid,T,lists:append([E], R));
        [] ->
            get_rela_list_sub(UnitePid,T,R)
    end.

%%提供给添加好友时用
%%@param PlayerStatus #player_status
%%@return DataBin
get_friend_info(PlayerStatus)->
    {ok,DataBin}=pt_140:write(14021, [0,
				      data_rela_text:get_def_group_name(),
				      PlayerStatus#player_status.id,
				      PlayerStatus#player_status.nickname,
				      PlayerStatus#player_status.image,
				      PlayerStatus#player_status.lv,
				      PlayerStatus#player_status.sex,
				      PlayerStatus#player_status.realm,
				      PlayerStatus#player_status.career,
				      0,
				      0,
				      PlayerStatus#player_status.last_login_time
				     ]),
    DataBin.

%%获取两指定玩家的好友信息。
%%@param AId  主玩家ID
%%@param BId  从玩家ID
%%@return []|[?ETS_RELA]
get_rela_by_ABId(UnitePid,AId,BId)->
    case load_relas(UnitePid,AId) of
	[]->
	    [];
	Relas ->
	    [R||R<-Relas,R#ets_rela.idA=:=AId,R#ets_rela.idB=:=BId]	   
    end.

%% 关系是否为黑名单
%% @parma Pid:玩家AId的Pid
is_in_blacklist(Pid, AId, BId) ->
    case get_rela_by_ABId(Pid,AId,BId) of
	[] -> false;
	[Rela] ->
	    case Rela#ets_rela.rela of
		3 -> true;
		5 -> true;
		_ -> false
	    end
    end.
	    
    
%%给IdA添加IdB好友关系，含 好友、黑人、仇人
%%@param IdA 
%%@param IdB
%%@param Rela 1好友 2仇人 3黑名单 4好友且仇人 5仇人且黑名单
%%@return ok
add_rela(UnitePid, IdA, IdB, Rela, StatusTarget)->
    %% 好友关系入库操作
    db:execute(db:make_insert_sql(relationship, ["idA", "idB", "rela","group_id","location_time"], [IdA, IdB, Rela,0,pt:get_time_stamp()])),
    L = find_rela(IdA,IdB),
    if
	length(L) > 0 ->
	    NRelas = [list_to_tuple([ets_rela|R]) || R <- L],
	    Relas = load_relas(UnitePid,IdA),
	    Record_NRelas = lists:nth(1, NRelas),
	    DRelas = lists:delete(Record_NRelas, Relas),
	    setRelas(UnitePid,lists:append([DRelas,NRelas])),
	    %% 目标103:拥有5名好友
	    case StatusTarget =/= undefined of
		true ->
		    mod_target:trigger(StatusTarget, IdA, 103, length(Relas)+1);
		_ ->
		    skip
	    end;

	true ->void
    end,
    ok.
%% 添加好友(修改关系用)
add_friend(PlayerPid, IdA, IdB, StatusTarget) ->
    case get_rela_by_ABId(PlayerPid,IdA, IdB) of
	[]->
	    %%无任何关系,继续好友添加流程
	    add_rela(PlayerPid, IdA, IdB, 1, StatusTarget);
	[L]->
	    if
		L#ets_rela.rela =:= 2 ->
		    update_rela(PlayerPid, IdA, IdB, 4);
		L#ets_rela.rela =:= 3 ->
		    update_rela(PlayerPid, IdA, IdB, 1);
		L#ets_rela.rela =:= 5 ->
		    update_rela(PlayerPid, IdA, IdB, 4);
		true ->
		    []
	    end
    end.

%% 添加仇人
add_enemy(PlayerPid, IdA, IdB) ->
    case get_rela_by_ABId(PlayerPid,IdA, IdB) of
	[]->
	    %%无任何关系,继续好友添加流程
	    add_rela(PlayerPid, IdA, IdB, 2, undefined);
	[L]->
	    if
		L#ets_rela.rela =:= 1 ->
		    update_rela(PlayerPid, IdA, IdB, 4);
		L#ets_rela.rela =:= 3 ->
		    update_rela(PlayerPid, IdA, IdB, 5);
		true ->
		    []
	    end
    end.

%% 添加黑名单
add_blacklist(PlayerPid, IdA, IdB) ->
    case get_rela_by_ABId(PlayerPid,IdA, IdB) of
	[]->
	    %%无任何关系,继续好友添加流程
	    add_rela(PlayerPid, IdA, IdB, 3, undefined);
	[L]->
	    if
		L#ets_rela.rela =:= 1 ->
		    update_rela(PlayerPid, IdA, IdB, 3);
		L#ets_rela.rela =:= 2 ->
		    update_rela(PlayerPid, IdA, IdB, 5);
		L#ets_rela.rela =:= 4 ->
		    update_rela(PlayerPid, IdA, IdB, 5);
		true ->
		    []
	    end
    end.

%%给IdA更新IdB好友关系，含 好友、黑人、仇人
%%@param IdA 
%%@param IdB
%%@param Rela 1好友 2黑名单 3仇人
%%@return ok  DAO层方法
update_rela(PlayerPid,IdA, IdB, Rela)->
    db:execute(io_lib:format(<<"update relationship set rela=~p where idA=~p and idB=~p">>, [Rela,IdA,IdB])),
    %% L = find_rela(IdA,IdB),
    %% if
    %% 	length(L) > 0 ->
    %% NRelas = [list_to_tuple([ets_rela|R]) || R <- L],
    Relas = load_relas(PlayerPid,IdA),
    [ABRela] = get_rela_by_ABId(PlayerPid,IdA, IdB),
    DRelas = lists:delete(ABRela, Relas),
    NRelas = ABRela#ets_rela{rela = Rela},
    setRelas(PlayerPid,lists:append([DRelas,[NRelas]])),
    %% 	true ->void
    %% end,
    ok.
%% 更新仇人显示标志
update_show_enemy_flag(PlayerPid, IdA, IdB, Flag) ->
    db:execute(io_lib:format(<<"update relationship set show_enemy=~p where idA=~p and idB=~p">>, [Flag,IdA,IdB])),
    L = find_rela(IdA,IdB),
    if
	length(L) > 0 ->
	    NRelas = [list_to_tuple([ets_rela|R]) || R <- L],
	    Relas = load_relas(PlayerPid,IdA),
	    [ABRela] = get_rela_by_ABId(PlayerPid,IdA, IdB),
	    DRelas = lists:delete(ABRela, Relas),
	    setRelas(PlayerPid,lists:append([DRelas,NRelas])),
	    ok;
	true ->void
    end.

%%更新两玩家最贵祝福礼包ID
%%@param IdA 
%%@param IdB
%%@param Bless_gift_id 礼包物品ID
%%@return ok  DAO层方法
update_rela_bless_gift_id(UnitePid,IdA, IdB, Bless_gift_id)->
    db:execute(io_lib:format(<<"update relationship set bless_gift_id=~p where idA=~p and idB=~p">>, [Bless_gift_id,IdA,IdB])),
    L = find_rela(IdA,IdB),
    if
	length(L) > 0 ->
	    NRelas = [list_to_tuple([ets_rela|R]) || R <- L],
	    Relas = load_relas(UnitePid,IdA),
	    [ABRela] = get_rela_by_ABId(UnitePid,IdA, IdB),
	    DRelas = lists:delete(ABRela, Relas),
	    setRelas(UnitePid,lists:append([DRelas,NRelas]));
	true ->void
    end,
    ok.

%%给IdA更新IdB密友关系
%%@param UnitePid 公共性Pid
%%@param IdA 
%%@param IdB
%%@param closely 1是 0否
%%@return ok  
update_closely(UnitePid,IdA, IdB, Closely)->
    db:execute(io_lib:format(<<"update relationship set closely=~p where (idA=~p and idB=~p) and (rela=1 or rela=4)">>, [Closely,IdA,IdB])),
    L = find_rela(IdA,IdB),
    if
	length(L) > 0 ->
	    NRelas = [list_to_tuple([ets_rela|R]) || R <- L],
	    Relas = load_relas(UnitePid,IdA),
	    [Rela] = get_rela_by_ABId(UnitePid,IdA, IdB),
	    DRelas = lists:delete(Rela, Relas),
	    setRelas(UnitePid,lists:append([DRelas,NRelas]));
	true ->void
    end,
    ok.
%% 查找亲密度，PlayerPid不存在的话直接查数据库
%% @return void:没有好友关系 | 亲密度数值
find_intimacy_dict(PlayerPid, IdA, IdB) ->
    case misc:is_process_alive(PlayerPid) of
	true ->
	    case get_rela_by_ABId(PlayerPid,IdA, IdB) of
		[]->void;
		[Rela]->
		    Rela#ets_rela.intimacy
	    end;
	false -> find_intimacy(IdA, IdB)
    end.
    
%%给IdA更新IdB的好友亲密度
%%@param IdA 
%%@param IdB
%%@param Intimacy 亲密度
update_Intimacy(UnitePid,IdA, IdB, Intimacy)->
    case is_pid(UnitePid) of
	false->void;
	true->
	    Self = self(),
	    if
		Self =:= UnitePid->
		    update_Intimacy_sub(UnitePid,IdA, IdB, Intimacy);
		true->
		    gen_server:call(UnitePid, {update_Intimacy,UnitePid,IdA, IdB, Intimacy})
	    end
    end.


%%给IdA更新IdB的好友亲密度
%%@param IdA 
%%@param IdB
%%@param Intimacy 亲密度
%%@return ok  
update_Intimacy_sub(UnitePid,IdA, IdB, Intimacy)->
    case get_rela_by_ABId(UnitePid,IdA, IdB) of
	[]->void;
	[Rela]->
	    case Rela#ets_rela.rela =:= 1 orelse Rela#ets_rela.rela =:= 4 of
		true ->
		    New_Rela = Rela#ets_rela{intimacy=Rela#ets_rela.intimacy+Intimacy},
		    Relas = load_relas(UnitePid,IdA),
		    DRelas = lists:delete(Rela, Relas),
		    setRelas(UnitePid,lists:append([DRelas,[New_Rela]])),
		    db:execute(io_lib:format(<<"update relationship set intimacy=intimacy+~p where idA=~p and idB=~p">>, [Intimacy,IdA,IdB])),
		    ok;
		false ->
		    []
	    end
    end.

%%给IdA更新IdB的仙侣奇缘次数
%% @param PidA 发起者PID（即送礼的人）
%% @param PidB 被发起者PID
%% @param IdA 发起者
%% @param IdB 被发起者
update_xlqy_count(PidA, PidB, IdA, IdB)->
    F = fun() ->
		db:execute(io_lib:format(<<"update relationship set xlqy=xlqy+~p where idA=~p and idB=~p">>, [1,IdA,IdB])),
		db:execute(io_lib:format(<<"update relationship set xlqy=xlqy+~p where idA=~p and idB=~p">>, [1,IdB,IdA]))
	end,
    db:transaction(F),
    case is_pid(PidA) of
	false-> [];
	true->
	    case self() =:= PidA of
		true -> update_xlqy_count_sub(PidA, IdA, IdB);
		false -> gen_server:call(PidA, {update_xlqy_count_sub, PidA, IdA, IdB})
	    end
    end,
    case is_pid(PidB) of
	false-> [];
	true->
	    case self() =:= PidB of
		true -> update_xlqy_count_sub(PidB, IdB, IdA);
		false -> gen_server:call(PidB, {update_xlqy_count_sub, PidB, IdB, IdA})
	    end
    end.

%%给IdA更新IdB的仙侣奇缘次数
%%@param IdA 
%%@param IdB
update_xlqy_count_sub(PlayerPid,IdA, IdB)->
    case get_rela_by_ABId(PlayerPid,IdA, IdB) of
	[]->void;
	[Rela]->
	    case Rela#ets_rela.rela =:= 1 orelse Rela#ets_rela.rela =:= 4 of
		true ->
		    New_Rela = Rela#ets_rela{xlqy=Rela#ets_rela.xlqy+1},
		    Relas = load_relas(PlayerPid,IdA),
		    DRelas = lists:delete(Rela, Relas),
		    setRelas(PlayerPid,lists:append([DRelas,[New_Rela]])),
		    ok;
		false ->
		    []
	    end
    end.
%%给IdA更新IdB好友关系
%%@param IdA 
%%@param IdB
%%@param Type:1好友 | 3黑名单
%%@return ok Service层方法
modify_rela(PlayerPid,IdA, IdB, Type)->
    case get_rela_by_ABId(PlayerPid, IdA, IdB) of 
	[] -> none;
	[Rela] ->
	    if
		Rela#ets_rela.rela =:= 2 ->
		    [];
		Rela#ets_rela.rela =:= 4 ->
		    case Type =:= 3 of
			true -> update_rela(PlayerPid,IdA, IdB, 5);
			false -> []
		    end;
		Rela#ets_rela.rela =:= 5 ->
		    case Type =:= 1 of
			true -> update_rela(PlayerPid,IdA, IdB, 4);
			false -> []
		    end;
		true ->
		    update_rela(PlayerPid,IdA, IdB, Type)
	    end,
	    ok
    end.

%% 删除好友关系 含好友、仇人、黑人
%% @param IdA、IdB 玩家ID
%% @param Type客户端传过来的列表标签编号，1好友2仇人3黑名单
%% @return ok | none 非好友关系
remove_rela(PlayerPid,IdA, IdB,Type)->
    case get_rela_by_ABId(PlayerPid,IdA, IdB) of 
	[] -> none;
	[Rela] ->
	    if
		Type =:= 2 ->
		    if
			Rela#ets_rela.rela =:= 2 ->
			    delete_rela(PlayerPid, IdA, Rela#ets_rela.id),
			    clear_rela_hatred_value(PlayerPid, IdA, IdB);
			Rela#ets_rela.rela =:= 4 ->
			    update_rela(PlayerPid, IdA, IdB, 1),
			    clear_rela_hatred_value(PlayerPid, IdA, IdB);
			Rela#ets_rela.rela =:= 5 ->
			    update_rela(PlayerPid, IdA, IdB, 3),
			    clear_rela_hatred_value(PlayerPid, IdA, IdB);
			true ->
			    []
		    end;
		true ->
		    if
			Rela#ets_rela.rela =:= 2 ->
			    [];
			Rela#ets_rela.rela =:= 4 ->
			    update_rela(PlayerPid, IdA, IdB, 2);
			Rela#ets_rela.rela =:= 5 ->
			    update_rela(PlayerPid, IdA, IdB, 2);
			true ->
			    delete_rela(PlayerPid, IdA, Rela#ets_rela.id)
		    end
	    end,
	    ok
    end.

%%获取某种关系个数
%%@param Uid
%%@param Rela  1好友 2黑名单 3仇人
%%@return int 个数
get_relas_size(UnitePid,Uid,Rela)->
    Relas = load_relas_by_id(UnitePid,Uid,Rela),
    length(Relas).

%%获取好友个数
%%@param Uid
%%@return int 个数
get_friends_size(PlayerPid, Uid) ->
    Friends = load_friends_by_id(PlayerPid, Uid),
    length(Friends).
    
%% 添加好友分组
%% @param Uid 玩家ID
%% @param Group_name 组名
add_rela_group(UnitePid,Uid, Group_name)->
    %% 好友关系入库操作
    Sql = io_lib:format(<<"insert into rela_group(uid,group_name) values(~p,'~s')">>, [Uid,list_to_binary(Group_name)]),
    db:execute(Sql),
    %%如果为空，则从数据库中读取全部关系
    L = find_rela_group_name(Uid),
    if
	length(L) > 0 ->
	    NRela_groupnames = [list_to_tuple([ets_rela_group|R]) || R <- L],
	    setRela_groupnames(UnitePid,NRela_groupnames);
	true ->
	    eraseRela_groupnames(UnitePid)
    end,
    ok.

%%查找玩家A所有的好友关系
%% @param 玩家ID
find_relas(IdA) ->
    db:get_all(io_lib:format(<<"select * from relationship where idA = ~p">>, [IdA])).

%%查找玩家A与玩家B的好友关系
%% @param IdA 玩家A Id 
%% @param IdB 玩家B Id 
find_rela(IdA,IdB) ->
    db:get_all(io_lib:format(<<"select * from relationship where idA = ~p and idB=~p">>, [IdA,IdB])).

%%查找玩家A与玩家B的亲密度
%% @param IdA 玩家A Id 
%% @param IdB 玩家B Id 
%% @return int
find_intimacy(IdA,IdB) ->
    db:get_one(io_lib:format(<<"select ifnull(sum(intimacy),0) from relationship where idA = ~p and idB=~p">>, [IdA,IdB])).

%%查找玩家A与玩家B的仙侣奇缘次数
%% @param IdA 玩家A Id 
%% @param IdB 玩家B Id 
%% @return int
find_xlqy_count(IdA,IdB) ->
    db:get_one(io_lib:format(<<"select ifnull(sum(xlqy),0) from relationship where idA = ~p and idB=~p">>, [IdA,IdB])).

%%查找玩家A的基本信息
%% @param IdA 玩家A Id 
find_info(Uid)->
    db:get_row(io_lib:format(<<"select player_low.id, player_low.nickname, player_low.sex, player_low.lv, player_low.career,player_low.realm,player_low.image, player_login.last_login_time from player_low,player_login where player_login.id=player_low.id and player_low.id = ~p">>, [Uid])).

%%查找玩家自定义好友分组名字
%% @param IdA 玩家A Id
find_rela_group_name(Uid)->
    db:get_all(io_lib:format(<<"select id,uid,group_name from rela_group where uid = ~p order by id">>, [Uid])).

%%删除好友关系表某个记录
%%@param Id 记录ID
delete_rela(UnitePid,Uid,Id) ->
    Relas = load_relas(UnitePid,Uid),
    case [R||R<-Relas,R#ets_rela.id =:= Id] of
	[] ->void;
	[Rela]->
	    DRelas = lists:delete(Rela, Relas),
	    setRelas(UnitePid,DRelas)
    end,
    db:execute(io_lib:format(<<"delete from relationship where id = ~p">>, [Id])).

%%删除好友关系表某个记录
%%@param Pid玩家AId的Pid
delete_rela_for_divorce(APid,AId,BId) ->
    F = fun() ->
		db:execute(io_lib:format(<<"delete from relationship where idA=~p and idB=~p">>, [AId, BId])),
		db:execute(io_lib:format(<<"delete from relationship where idA=~p and idB=~p">>, [BId, AId]))
	end,
    db:transaction(F),
    case lib_player:get_player_info(BId, pid) of
	BPid when is_pid(BPid) ->
	    gen_server:cast(BPid, {'del_rela_for_divorce',[AId]});
	_ -> []
    end,
    case misc:is_process_alive(APid) of
	false -> [];
	true ->
	    Relas = load_relas(APid,AId),
	    case [R||R<-Relas,R#ets_rela.idA=:=AId,R#ets_rela.idB=:=BId] of
		[] -> none;
		[Rela]->
		    DRelas = lists:delete(Rela, Relas),
		    setRelas(APid,DRelas),
		    ok
	    end
    end.

%%删除好友分组表某个记录
%%@param Id 记录ID
delete_rela_group(UnitePid,Uid,Id) ->
    db:execute(io_lib:format(<<"delete from rela_group where id = ~p">>, [Id])),
    L = find_rela_group_name(Uid),
    if
	length(L) > 0 ->
	    NRela_groupnames = [list_to_tuple([ets_rela_group|R]) || R <- L],
	    setRela_groupnames(UnitePid,NRela_groupnames);
	true ->
	    eraseRela_groupnames(UnitePid)
    end,
    db:execute(io_lib:format(<<"update relationship set group_id=0 where group_id = ~p">>, [Id])).

%%更新好友分组名字
%%@param Uid 用户ID
%%@param Id 分组记录ID
%%@param Name 新组名
update_rela_group_name(UnitePid,Uid,Id,Name)->
    db:execute(io_lib:format(<<"update rela_group set group_name='~s' where id=~p">>, [Name,Id])),
    L = find_rela_group_name(Uid),
    if
	length(L) > 0 ->
	    NRela_groupnames = [list_to_tuple([ets_rela_group|R]) || R <- L],
	    setRela_groupnames(UnitePid,NRela_groupnames);
	true ->
	    eraseRela_groupnames(UnitePid)
    end,
    ok.

%%更改好友所在分组
%%@param IdA 玩家ID
%%@param IdB 玩家ID
%%@param Id 记录ID
update_rela_group_id(UnitePid,IdA,IdB,Id)->
    db:execute(io_lib:format(<<"update relationship set group_id=~p where idA=~p and idB=~p">>, [Id,IdA,IdB])),
    L = find_rela(IdA,IdB),
    if
	length(L) > 0 ->
	    NRelas = [list_to_tuple([ets_rela|R]) || R <- L],
	    Relas = load_relas(UnitePid,IdA),
	    [Rela] = get_rela_by_ABId(UnitePid,IdA, IdB),
	    DRelas = lists:delete(Rela, Relas),
	    setRelas(UnitePid,lists:append([DRelas,NRelas]));
	true ->void
    end,
    ok.

%%写包调用
%%@param R [#ets_rela_group]
write_data_14011([],Bin)->Bin;
write_data_14011(R,Bin)->
    [H|T] = R,
    Id = H#ets_unite.id,
    Name = H#ets_unite.name,
    NameBin = pt:write_string(Name),
    case H#ets_unite.image of
	undefined -> Image = 0;
	Others -> Image = Others
    end,
    Lv = H#ets_unite.lv,
    Sex = H#ets_unite.sex,
    Realm = H#ets_unite.realm,
    Career = H#ets_unite.career,
    TempBin = <<Id:32,
		NameBin/binary,
		Image:8,
		Lv:16,
		Sex:8,
		Realm:8,
		Career:8>>,
    write_data_14011(T,<<Bin/binary,
                         TempBin/binary>>).

%%写包调用
%%@param R [#ets_rela_group]
write_data_14007([],Bin)->Bin;
write_data_14007(R,Bin)->
    [H|T] = R,
    Id = H#ets_rela_group.id,
    NameBin = H#ets_rela_group.group,
    GLen = byte_size(NameBin),
    write_data_14007(T,<<Bin/binary,Id:16,GLen:16,NameBin:GLen/binary>>).

%%进程字典操作方法。
%% @param UnitePid 公共线进程PID。
getRelas(UnitePid)->
    Pid = self(),
    if
	UnitePid=:=Pid->
	    get(relas);
	true->
	    gen_server:call(UnitePid, {'getRelas'})
    end.

setRelas(UnitePid,Value)->
    Pid = self(),
    if
	UnitePid=:=Pid->
	    put(relas,Value);
	true->
	    gen_server:call(UnitePid, {'putRelas',Value})
    end.

getRela_groupnames(UnitePid)->
    Pid = self(),
    if
	UnitePid=:=Pid->
	    get(rela_groupnames);
	true->
	    gen_server:call(UnitePid, {'getRela_groupnames'})
    end.

setRela_groupnames(UnitePid,Value)->
    Pid = self(),
    if
	UnitePid=:=Pid->
	    put(rela_groupnames,Value);
	true->
	    gen_server:call(UnitePid, {'putRela_groupnames',Value})
    end.

eraseRela_groupnames(UnitePid)->
    Pid = self(),
    if
	UnitePid=:=Pid->
	    erase(rela_groupnames);
	true->
	    gen_server:call(UnitePid, {'eraseRela_groupnames'})
    end.


%% 回应添加好友请求
%% @param:PlayerStatus:#player_status  AId:发起者Id Result：0拒绝/1接受请求
ack_add_rela(PlayerStatus, [AId,_Type,_Result]) ->
    case get_rela_by_ABId(PlayerStatus#player_status.pid, PlayerStatus#player_status.id, AId) of
	%%无任何好友关系
	[] -> 
	    lib_relationship:add_rela(PlayerStatus#player_status.pid, PlayerStatus#player_status.id, AId, 1, PlayerStatus#player_status.status_target);
	%%更新好友关系
	[L2] ->
	    if
		L2#ets_rela.rela =:= 2-> %仅为仇人，变成好友且仇人
		    lib_relationship:update_rela(PlayerStatus#player_status.pid,PlayerStatus#player_status.id, AId, 4);
		L2#ets_rela.rela =:= 3-> %仅为黑名单，变成好友
		    lib_relationship:update_rela(PlayerStatus#player_status.pid,PlayerStatus#player_status.id, AId, 1);
		L2#ets_rela.rela =:= 5-> %仇人且黑名单，变成好友且仇人
		    lib_relationship:update_rela(PlayerStatus#player_status.pid,PlayerStatus#player_status.id, AId, 4);
		true -> void
	    end
    end,
    pp_relationship:handle(14003, PlayerStatus, [1]),
    pp_relationship:handle(14003, PlayerStatus, [2]),
    pp_relationship:handle(14003, PlayerStatus, [3]),
    PlayerStatusBin = lib_relationship:get_friend_info(PlayerStatus),
    lib_server_send:send_to_uid(AId, PlayerStatusBin),
    PlayerStatusRelaSize= lib_relationship:get_friends_size(PlayerStatus#player_status.pid, PlayerStatus#player_status.id),
    %% 触发名人堂：谁人不识君，第一个拥有200个好友
    %% lib_player_unite:trigger_fame(PlayerStatus#player_status.mergetime, PlayerStatus#player_status.id, [PlayerStatus#player_status.id, 12, 0, PlayerStatus_Real_Size]),
    mod_fame:trigger(PlayerStatus#player_status.mergetime, PlayerStatus#player_status.id, 12, 0, PlayerStatusRelaSize),
    %% 触发成就：高朋满座：拥有N个好友
    %% StatusAchieve2 = PlayerStatus#player_status.achieve,
    %% lib_player_unite:trigger_achieve(PlayerStatus#player_status.id, trigger_social, [StatusAchieve2, PlayerStatus#player_status.id, 0, 0,PlayerStatus_Real_Size]);
    mod_achieve:trigger_social(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 0, 0,PlayerStatusRelaSize).

%% 回应添加密友请求
%% @param:PlayerStatus:#player_status  AId:发起者Id Result：0拒绝/1接受请求
ack_add_closely_rela(PlayerStatus, [AId,_Result]) ->
    case get_rela_by_ABId(PlayerStatus#player_status.pid, PlayerStatus#player_status.id, AId) of
	%%无任何好友关系
	[] -> 
	    pp_relationship:handle(14000, PlayerStatus, [1010]);
	%%更新好友关系
	[L2] ->
	    if
		%% 双方为好友关系
		L2#ets_rela.rela =:= 1 orelse L2#ets_rela.rela =:= 4->
		    lib_relationship:update_closely(PlayerStatus#player_status.pid, PlayerStatus#player_status.id, AId, 1);
		true -> void
	    end
    end,
    pp_relationship:handle(14003, PlayerStatus, [1]),
    pp_relationship:handle(14003, PlayerStatus, [2]),
    pp_relationship:handle(14003, PlayerStatus, [3]).


%% 更新被杀次数
%% @param IdA:被杀者
%% @param IdB:杀人者
%% @return ok  
update_rela_killed_times(PlayerPid,IdA, IdB)->
    case get_rela_by_ABId(PlayerPid,IdA, IdB) of
	[]->
	    add_enemy(PlayerPid, IdA, IdB), 	%%加入黑名单
	    [Rela] = get_rela_by_ABId(PlayerPid, IdA, IdB),
	    NewRela = Rela#ets_rela{killed_by_enemy = 1},
	    Relas = load_relas(PlayerPid,IdA),
	    DRelas = lists:delete(Rela, Relas),
	    setRelas(PlayerPid,lists:append([DRelas,[NewRela]])),
	    db:execute(io_lib:format(<<"update relationship set killed_by_enemy=~p where idA=~p and idB=~p">>, [NewRela#ets_rela.killed_by_enemy,IdA,IdB]));
	[Rela]->
	    if
		%% 关系为好友
		Rela#ets_rela.rela =:= 1 ->
		    lib_relationship:update_rela(PlayerPid, IdA, IdB, 4),
		    update_rela_killed_times_helper(PlayerPid, IdA, IdB);
		%% 关系为黑名单
		Rela#ets_rela.rela =:= 3 ->
		    lib_relationship:update_rela(PlayerPid, IdA, IdB, 5),
		    update_rela_killed_times_helper(PlayerPid, IdA, IdB);
		true ->
		    update_rela_killed_times_helper(PlayerPid, IdA, IdB)
	    end
    end,
    update_rela_hatred_value(PlayerPid, IdA, IdB, add),
    ok.
%% @param Rela:#ets_rela{}
update_rela_killed_times_helper(PlayerPid, IdA, IdB)->
    case get_rela_by_ABId(PlayerPid, IdA, IdB) of
	[]-> [];
	[Rela] ->
	    Rela1 = Rela#ets_rela{killed_by_enemy = Rela#ets_rela.killed_by_enemy + 1},
	    case Rela1#ets_rela.show_enemy =:= 0 of
		false ->
		    NewRela = Rela1,
		    Relas = load_relas(PlayerPid,IdA),
		    DRelas = lists:delete(Rela, Relas),
		    setRelas(PlayerPid,lists:append([DRelas,[NewRela]])),
		    db:execute(io_lib:format(<<"update relationship set killed_by_enemy=~p where idA=~p and idB=~p">>, [NewRela#ets_rela.killed_by_enemy,IdA,IdB]));
		true ->
		    case Rela1#ets_rela.killed_by_enemy >= 3 of
			true ->
			    db:execute(io_lib:format(<<"update relationship set show_enemy=~p where idA=~p and idB=~p">>, [1,IdA,IdB])),
			    NewRela = Rela1#ets_rela{show_enemy = 1},
			    Relas = load_relas(PlayerPid,IdA),
			    DRelas = lists:delete(Rela, Relas),
			    setRelas(PlayerPid,lists:append([DRelas,[NewRela]])),
			    db:execute(io_lib:format(<<"update relationship set killed_by_enemy=~p where idA=~p and idB=~p">>, [NewRela#ets_rela.killed_by_enemy,IdA,IdB])),
			    EnemyList = get_show_enemy_list(PlayerPid, IdA),
			    {ok,BinData} = pt_140:write(14025, [EnemyList]),
			    lib_server_send:send_to_uid(IdA, BinData);
			false ->
			    NewRela = Rela1,
			    Relas = load_relas(PlayerPid,IdA),
			    DRelas = lists:delete(Rela, Relas),
			    setRelas(PlayerPid,lists:append([DRelas,[NewRela]])),
			    db:execute(io_lib:format(<<"update relationship set killed_by_enemy=~p where idA=~p and idB=~p">>, [NewRela#ets_rela.killed_by_enemy,IdA,IdB]))
		    end
	    end
    end.
	    

%% 更新仇恨值
%% @param IdA:被杀者
%% @param IdB:杀人者
%% @param Type:add(atom)加次数 | minus(atom)减次数
%% @return ok  
update_rela_hatred_value(UnitePid,IdA, IdB, Type)->
    case get_rela_by_ABId(UnitePid,IdA, IdB) of
	[]->void;
	[Rela]->
	    case Type of
		add ->
		    NewRela = Rela#ets_rela{hatred_value=Rela#ets_rela.hatred_value + 1};
		minus ->
		    case Rela#ets_rela.hatred_value > 0 of
			true ->
			    NewRela = Rela#ets_rela{hatred_value=Rela#ets_rela.hatred_value - 1};
			false ->
			    NewRela = Rela#ets_rela{hatred_value = 0}
		    end
	    end,
	    Relas = load_relas(UnitePid,IdA),
	    DRelas = lists:delete(Rela, Relas),
	    setRelas(UnitePid,lists:append([DRelas,[NewRela]])),
	    db:execute(io_lib:format(<<"update relationship set hatred_value=~p where idA=~p and idB=~p">>, [NewRela#ets_rela.hatred_value,IdA,IdB]))
    end,
    ok.

%% 清除仇恨值
clear_rela_hatred_value(PlayerPid, IdA, IdB) ->
    db:execute(io_lib:format(<<"update relationship set hatred_value=0, show_enemy=0 where idA=~p and idB=~p">>, [IdA,IdB])),
    case get_rela_by_ABId(PlayerPid, IdA, IdB) of
	[] -> [];
	[ABRela] ->
	    Relas = load_relas(PlayerPid,IdA),
	    DRelas = lists:delete(ABRela, Relas),
	    NRelas = ABRela#ets_rela{show_enemy = 0, hatred_value=0},
	    setRelas(PlayerPid,lists:append([DRelas,[NRelas]]))
    end.


foreach_ex(_Fun, [], Status) ->
    {ok, Status};
foreach_ex(Fun, [H|T], Status) ->
    {ok, NewStatus} = Fun(H, Status),
    foreach_ex(Fun, T, NewStatus).

get_show_enemy_list(PlayerPid, Uid) ->
    EnemyList = load_enemy_by_id(PlayerPid,Uid),
    [Enemy#ets_rela.idB || Enemy <- EnemyList, Enemy#ets_rela.killed_by_enemy >= 3 andalso (Enemy#ets_rela.rela =:= 2 orelse Enemy#ets_rela.rela =:= 4 orelse Enemy#ets_rela.rela =:= 5)].

	  
