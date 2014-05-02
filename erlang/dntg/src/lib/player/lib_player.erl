%%%--------------------------------------
%%% @Module  : lib_player
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.06.14
%%% @Description:角色相关处理
%%%--------------------------------------
-module(lib_player).
-export([
        set_online/0,
        is_online/1,
        is_online_unite/1,
        is_online_global/1,
        get_role_id_by_name/1,
        get_role_id_by_accname/1,
        get_role_accname_by_id/1,
        get_player_login_data/1,
        get_player_high_data/1,
        get_player_low_data/1,
        get_player_state_data/1,
        get_player_attr_data/1,
		get_player_pt_data/1,
        get_player_vip_data/1,
        get_player_vip_new_data/1,
		get_player_guild_data/1,
        get_player_pet_data/1,
		get_player_arena_data/1,
		get_player_consumption/1,
		delete_player_consumption/1,
		insert_consumption/5,
		update_consumption_gift/2,
		update_consumption_gift2/2,
		update_consumption_eqout_times/4,
		update_consumption_endtime_eqout_times/5,
		add_consumption/4,
        is_exists/1,
        is_accname_exists/1,
        update_player_high/1,
		update_player_login_offline_time/3,
		update_player_login_last_logout_time/2,
        update_player_state/1,
		update_player_state2/1,
        get_online_info/1,
        get_online_info_global/1,
        get_player_info/1,
		get_player_info/2,
        next_lv_exp/1,
        one_to_two/5,
        count_player_attribute/1,
		send_attribute_change_notify/2,
		refresh_client/2,
        refresh_client/1,
		add_pt/3,
        minus_pt/3,
		minus_whpt/2,
        get_player_buff/3,
        get_buff_attribute/2,
        get_player_buff/2,
%%         get_player_buff/3,
        send_buff_notice/2,
        send_wine_buff_notice/3,
        add_player_buff/7,
        del_player_buff/2,
        del_buff/1,
        mod_buff/5,
        reduce_mon_exp_arg/2,
		add_exp/2,
        add_exp/3,
        add_exp/4,
        add_coin/2,
        add_bcoin/2,
		add_money/3,
		add_money_offline/3,
        add_genius_by_id/3,                 %% 增加文采
        rpc_call_by_id/4,
        rpc_cast_by_id/4,
        update_player_info/2,
        get_unite_status/1,
		set_group/2,
        change_pkstatus/2,
		change_pk_status/2,
		change_pk_status_cast/2,
        count_player_speed/1,
        add_task_award/1,
        init_player_buff/1,
        del_player_buff/1,
        check_player_buff/1,
        get_exp_buff/1,
        get_city_war_exp_buff/1,
        save_quickbar/2,
        delete_quickbar/2,
        replace_quickbar/3,
        player_die/4,
		is_transferable/1,
		get_role_max_lv_from_db/0,
        get_pid_by_id/1,
        update_unite_info/2,
		delete_ets_buff/1,
        get_role_any_id_by_accname/1,
		get_online_time/1,
		get_online_time_today/2,
		limit_login/1,
        update_anger/1,
        update_player_exp/1,
        send_wubianhai_award/6,
        add_pk_value/2,
        minus_pk_value/2,
        add_pk_value_deal/2,
        minus_pk_value_deal/2,
        cost_pt/3,
		get_card_good/2,
        get_world_lv_from_unite/0,
        world_lv/1,
        add_hp/2,
		get_player_image_data/1,
		change_player_image/3,
		activate_player_image/2,
		load_player_image/1,
		get_player_normal_image/1,
		get_player_last_login_time/1,
		note_pre_loginTime/1,
		count_hightest_combat_power/1,
        set_sys_conf/2,
        is_screen/2
    ]).
-include("common.hrl").
-include("server.hrl").
-include("sql_player.hrl").
-include("buff.hrl").
-include("unite.hrl").
-include("scene.hrl").
-include("mount.hrl").
-include("arena_new.hrl").
-include("def_goods.hrl").
-include("predefine.hrl").
-include("battle.hrl").

%% 封号
limit_login(Ids) when is_list(Ids) ->
    case util:string_to_term(Ids) of
        undefined -> skip;
        L -> [limit_login(Id) || Id <- L]
    end,
    ok;
limit_login(Id) ->
	mod_disperse:cast_to_unite(lib_unite_send, send_to_uid,  [Id, close]),
    lib_server_send:send_to_uid(Id, close).

%% 设置在线
set_online() ->
    db:execute(?set_role_online).

    
%% 检测某个角色是否在线
is_online(Pid) ->
    case ets:lookup(?ETS_ONLINE, Pid) of
        [] -> false;
        _Other -> true
    end.

is_online_unite(PlayerId) ->
    case mod_chat_agent:lookup(PlayerId) of
        [] -> false;
        _Other -> true
    end.

is_online_global(Id) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            misc:is_process_alive(Pid);
        _ ->
            false
    end.
%% 根据角色名称查找ID
get_role_id_by_name(Name) ->
    db:get_one(io_lib:format(?sql_role_id_by_name, [Name])).

%% 根据id查找账户名称
get_role_accname_by_id(Id) ->
    db:get_one(io_lib:format(?sql_role_accname_by_id, [Id])).

%% 根据账户名称查找ID
get_role_id_by_accname(AccName) ->
    db:get_one(io_lib:format(?sql_role_id_by_accname, [AccName])).

%% 根据账户名称查找角色个数
get_role_any_id_by_accname(AccName) ->
    db:get_all(io_lib:format(?sql_role_any_id_by_accname, [AccName])).

%% 根据账户名称查找ID
get_role_max_lv_from_db() ->
    db:get_one(io_lib:format(?sql_role_max_lv)).

%% 检测指定名称的角色是否已存在
is_accname_exists(AccName) ->
    case db:get_one(io_lib:format(?sql_role_id_by_accname, [AccName])) of
        null -> false;
        _Other -> true
    end.

%% 获取player_login登陆所需数据
get_player_login_data(Id) ->
    db:get_row(io_lib:format(?sql_player_login_data, [Id])).

%% 更新玩家离线时间
update_player_login_offline_time(Id,OfflineTime,NowTime)->
	db:execute(io_lib:format(?sql_player_update_login_data_offline_time, [OfflineTime,NowTime,Id])).

%% 更新玩家离线时间
update_player_login_last_logout_time(Id,NowTime)->
	db:execute(io_lib:format(?sql_player_update_login_data_last_logout_time, [NowTime,Id])).

%% 获取player_high登陆所需数据
get_player_high_data(Id) ->
    db:get_row(io_lib:format(?sql_player_high_data, [Id])).

%% 获取player_low登陆所需数据
get_player_low_data(Id) ->
    db:get_row(io_lib:format(?sql_player_low_data, [Id])).

%% 获取player_state登陆所需数据
get_player_state_data(Id) ->
    db:get_row(io_lib:format(?sql_player_state_data, [Id])).

%% 获取player_attr登陆所需数据
get_player_attr_data(Id) ->
    db:get_row(io_lib:format(?sql_player_attr_data, [Id])).

%%	获取player_pt登陆所需数据
get_player_pt_data(Id) ->
	db:get_row(io_lib:format(?sql_player_pt_data, [Id])).

%% 获取player_vip登陆所需数据
get_player_vip_data(Id) ->
    db:get_row(io_lib:format(?sql_player_vip_data, [Id])).

%% 获取VIP新版信息
get_player_vip_new_data(Id) ->
    db:get_row(io_lib:format(?sql_player_vip_new_data, [Id])).

%% 获取player_arena登陆所需数据
get_player_arena_data(Id) ->
    case db:get_row(io_lib:format(?sql_player_arena_data, [Id])) of
		[]->#status_arena{};
		L->list_to_tuple([status_arena|L])
	end.

%% 获取player_consumption登陆所需数据
get_player_consumption(Id) ->
    case db:get_row(io_lib:format(?sql_player_consumption_data, [Id])) of
		[]->#status_consumption{};
		L->
			NowTime = util:unixtime(),
			Consumption = list_to_tuple([status_consumption|L]),
			if
				NowTime>Consumption#status_consumption.end_time-> %活动已经过期了，直接删除
					spawn(fun () -> timer:sleep(2000), lib_player:delete_player_consumption(Id) end),					
					#status_consumption{};
				true->
					Gift = binary_to_list(Consumption#status_consumption.gift),
					T_Gift_List = string:tokens(Gift, ","),
					Gift_List = [T||T<-T_Gift_List,T/="'"],
					Consumption#status_consumption{gift = pp_activity_daily:no_list_to_string(Gift_List,"")}
			end
	end.
delete_player_consumption(Id)->
	case db:get_row(io_lib:format(?sql_player_consumption_data, [Id])) of
		[] -> skip;
		L ->
			%% 删除前检查玩家是否已领礼包,玩家没领发邮件补发礼包
			case catch data_consumption_gift:all_data() of
				{'EXIT', Why} ->
					catch util:errlog("data_consumption_gift error: ~p", [Why]);	
				All_Data ->
					Consumption = list_to_tuple([status_consumption|L]),
					Gift = binary_to_list(Consumption#status_consumption.gift),
					T_Gift_List = string:tokens(Gift, ","),
					Gift_List = [T||T<-T_Gift_List,T/="'"],			
					Gifting_Data = [GiftList||{_OpenDay,_BeginTime,_EndTime,GiftList}<-All_Data],								 			
					F2 = fun({No, Type, NeedEqout, NeedTimes, Goodsid, _}) ->
							case Type of
								all->
									Eqout = Consumption#status_consumption.eqout_taobao+
									Consumption#status_consumption.eqout_shangcheng+
									Consumption#status_consumption.eqout_petcz+
									Consumption#status_consumption.eqout_petqn+
									Consumption#status_consumption.eqout_smsx+
									Consumption#status_consumption.eqout_smgm+
									Consumption#status_consumption.eqout_petjn+
									Consumption#status_consumption.eqout_cmsd,
									Times = Consumption#status_consumption.times_taobao+
									Consumption#status_consumption.times_shangcheng+
									Consumption#status_consumption.times_petcz+
									Consumption#status_consumption.times_petqn+
									Consumption#status_consumption.times_smsx+
									Consumption#status_consumption.times_smgm+
									Consumption#status_consumption.times_petjn+
									Consumption#status_consumption.times_cmsd;
								repeat->
									Eqout = Consumption#status_consumption.eqout_taobao+
									Consumption#status_consumption.eqout_shangcheng+
									Consumption#status_consumption.eqout_petcz+
									Consumption#status_consumption.eqout_petqn+
									Consumption#status_consumption.eqout_smsx+
									Consumption#status_consumption.eqout_smgm+
									Consumption#status_consumption.eqout_petjn+
									Consumption#status_consumption.eqout_cmsd,
									Times = Consumption#status_consumption.times_taobao+
									Consumption#status_consumption.times_shangcheng+
									Consumption#status_consumption.times_petcz+
									Consumption#status_consumption.times_petqn+
									Consumption#status_consumption.times_smsx+
									Consumption#status_consumption.times_smgm+
									Consumption#status_consumption.times_petjn+
									Consumption#status_consumption.times_cmsd;
								taobao->
									Eqout = Consumption#status_consumption.eqout_taobao,
									Times = Consumption#status_consumption.times_taobao;
								shangcheng->
									Eqout = Consumption#status_consumption.eqout_shangcheng,
									Times = Consumption#status_consumption.times_shangcheng;
								petcz->
									Eqout = Consumption#status_consumption.eqout_petcz,
									Times = Consumption#status_consumption.times_petcz;
								petqn->
									Eqout = Consumption#status_consumption.eqout_petqn,
									Times = Consumption#status_consumption.times_petqn;
								smsx->
									Eqout = Consumption#status_consumption.eqout_smsx,
									Times = Consumption#status_consumption.times_smsx;
								smgm->
									Eqout = Consumption#status_consumption.eqout_smgm,
									Times = Consumption#status_consumption.times_smgm;
								petjn->
									Eqout = Consumption#status_consumption.eqout_petjn,
									Times = Consumption#status_consumption.times_petjn;
								cmsd->
									Eqout = Consumption#status_consumption.eqout_cmsd,
									Times = Consumption#status_consumption.times_cmsd;
								_->
									Eqout = 999999,Times = 999999
							end,
							case NeedEqout =< Eqout andalso NeedTimes =< Times andalso Type=/=repeat of
								true ->
									case lists:member(integer_to_list(No), Gift_List) of
										true -> skip;
										false -> 
											Title = data_activity_text:get_player_consumption_reissue_title(),
											Content = data_activity_text:get_player_consumption_reissue_content(),
											mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Id], Title, Content, Goodsid, 2, 0, 0,1,0,0,0,0])
									end;
								false -> skip
							end,
							case Type=:=repeat of
								true ->
								RepeatCount = Consumption#status_consumption.repeat_count,					
								CanFetchTotal = Eqout div NeedEqout,	
								case CanFetchTotal>RepeatCount of
									true ->
										%% 还有未领取重复礼包
										Goods_num2 = CanFetchTotal-RepeatCount,
										Title2 = data_activity_text:get_player_consumption_reissue_title(),
										Content2 = data_activity_text:get_player_consumption_reissue_content(),
										mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Id], Title2, Content2, Goodsid, 2, 0, 0,Goods_num2,0,0,0,0]);
									false -> skip
								end;
								false -> skip
							end
					end,
					F1 = fun(GiftConf) ->
							lists:foreach(F2, GiftConf)
					end,
					lists:foreach(F1, Gifting_Data)
			end,			
			%% 写入删除日志
			db:execute(io_lib:format(?sql_insert_log_player_consumption, L++[util:unixtime()]))
	end,
	db:execute(io_lib:format(?sql_delete_player_consumption_data, [Id])).
insert_consumption(Type,Id,End_time,Eqout,Times)->
	case Type of
		taobao->
			db:execute(io_lib:format(<<"insert into player_consumption(uid,end_time,eqout_taobao,times_taobao) values(~p,~p,~p,~p)">>, [Id,End_time,Eqout,Times]));
		shangcheng->
			db:execute(io_lib:format(<<"insert into player_consumption(uid,end_time,eqout_shangcheng,times_shangcheng) values(~p,~p,~p,~p)">>, [Id,End_time,Eqout,Times]));
		petcz->
			db:execute(io_lib:format(<<"insert into player_consumption(uid,end_time,eqout_petcz,times_petcz) values(~p,~p,~p,~p)">>, [Id,End_time,Eqout,Times]));
		petqn->
			db:execute(io_lib:format(<<"insert into player_consumption(uid,end_time,eqout_petqn,times_petqn) values(~p,~p,~p,~p)">>, [Id,End_time,Eqout,Times]));
		smsx->
			db:execute(io_lib:format(<<"insert into player_consumption(uid,end_time,eqout_smsx,times_smsx) values(~p,~p,~p,~p)">>, [Id,End_time,Eqout,Times]));
		smgm->
			db:execute(io_lib:format(<<"insert into player_consumption(uid,end_time,eqout_smgm,times_smgm) values(~p,~p,~p,~p)">>, [Id,End_time,Eqout,Times]));
		petjn->
			db:execute(io_lib:format(<<"insert into player_consumption(uid,end_time,eqout_petjn,times_petjn) values(~p,~p,~p,~p)">>, [Id,End_time,Eqout,Times]));
		cmsd->
			db:execute(io_lib:format(<<"insert into player_consumption(uid,end_time,eqout_cmsd,times_cmsd) values(~p,~p,~p,~p)">>, [Id,End_time,Eqout,Times]));
		_->
			void
	end.
update_consumption_gift(Id,Gift)->
	db:execute(io_lib:format(<<"update player_consumption set gift='~s' where uid=~p">>, [Gift, Id])).
update_consumption_gift2(Id,Gift)->
	case db:get_one(io_lib:format(<<"select repeat_count from player_consumption where uid=~p">>, [Id])) of
		null -> Count = 0;			
		Other -> Count = Other
	end,
	db:execute(io_lib:format(<<"update player_consumption set repeat_count=~p,gift='~s' where uid=~p">>, [Count+1, Gift, Id])).
update_consumption_eqout_times(Type,Id,Eqout,Times)->
	case Type of
		taobao->
			db:execute(io_lib:format(<<"update player_consumption set eqout_taobao=eqout_taobao+~p,times_taobao=times_taobao+~p where uid=~p">>, [Eqout,Times, Id]));
		shangcheng->
			db:execute(io_lib:format(<<"update player_consumption set eqout_shangcheng=eqout_shangcheng+~p,times_shangcheng=times_shangcheng+~p where uid=~p">>, [Eqout,Times, Id]));
		petcz->
			db:execute(io_lib:format(<<"update player_consumption set eqout_petcz=eqout_petcz+~p,times_petcz=times_petcz+~p where uid=~p">>, [Eqout,Times, Id]));
		petqn->
			db:execute(io_lib:format(<<"update player_consumption set eqout_petqn=eqout_petqn+~p,times_petqn=times_petqn+~p where uid=~p">>, [Eqout,Times, Id]));
		smsx->
			db:execute(io_lib:format(<<"update player_consumption set eqout_smsx=eqout_smsx+~p,times_smsx=times_smsx+~p where uid=~p">>, [Eqout,Times, Id]));
		smgm->
			db:execute(io_lib:format(<<"update player_consumption set eqout_smgm=eqout_smgm+~p,times_smgm=times_smgm+~p where uid=~p">>, [Eqout,Times, Id]));
		petjn->
			db:execute(io_lib:format(<<"update player_consumption set eqout_petjn=eqout_petjn+~p,times_petjn=times_petjn+~p where uid=~p">>, [Eqout,Times, Id]));
		cmsd->
			db:execute(io_lib:format(<<"update player_consumption set eqout_cmsd=eqout_cmsd+~p,times_cmsd=times_cmsd+~p where uid=~p">>, [Eqout,Times, Id]));
		_->
			void
	end.
update_consumption_endtime_eqout_times(Type,Id,End_time,Eqout,Times)->
	case Type of
		taobao->
			db:execute(io_lib:format(<<"update player_consumption set end_time=~p,eqout_taobao=~p,times_taobao=~p,gift='' where uid=~p">>, [End_time,Eqout,Times, Id]));
		shangcheng->
			db:execute(io_lib:format(<<"update player_consumption set end_time=~p,eqout_shangcheng=~p,times_shangcheng=~p,gift='' where uid=~p">>, [End_time,Eqout,Times, Id]));
		petcz->
			db:execute(io_lib:format(<<"update player_consumption set end_time=~p,eqout_petcz=~p,times_petcz=~p,gift='' where uid=~p">>, [End_time,Eqout,Times, Id]));
		petqn->
			db:execute(io_lib:format(<<"update player_consumption set end_time=~p,eqout_petqn=~p,times_petqn=~p,gift='' where uid=~p">>, [End_time,Eqout,Times, Id]));
		smsx->
			db:execute(io_lib:format(<<"update player_consumption set end_time=~p,eqout_smsx=~p,times_smsx=~p,gift='' where uid=~p">>, [End_time,Eqout,Times, Id]));
		smgm->
			db:execute(io_lib:format(<<"update player_consumption set end_time=~p,eqout_smgm=~p,times_smgm=~p,gift='' where uid=~p">>, [End_time,Eqout,Times, Id]));
		petjn->
			db:execute(io_lib:format(<<"update player_consumption set end_time=~p,eqout_petjn=~p,times_petjn=~p,gift='' where uid=~p">>, [End_time,Eqout,Times, Id]));
		cmsd->
			db:execute(io_lib:format(<<"update player_consumption set end_time=~p,eqout_cmsd=~p,times_cmsd=~p,gift='' where uid=~p">>, [End_time,Eqout,Times, Id]));
		_->
			void
	end.
%%消费礼包返利接口
%% @param Type all、taobao（淘宝）、shangcheng（商城）、petcz（宠物成长）、petqn（宠物潜能）、smsx（神秘刷新）、smgm（神秘购买）、petjn（宠物技能）、cmsd（财迷商店）
%% @param PlayerStatus #player_status
%% @param Eqout 消费额度
%% @param Times 消费次数
%% @return New_PlayerStatus #player_status
add_consumption(Type,PlayerStatus,Eqout,Times) when is_record(PlayerStatus,player_status)->
	Consumption = PlayerStatus#player_status.consumption,
%%	% 合服期间内消费记录不算入消费数额
%%	case PlayerStatus#player_status.mergetime>0 andalso lib_activity_merge:get_merge_day() =< 5 of
%%		true -> New_Consumption = Consumption;
%%		false ->
			NowTime = util:unixtime(),
			case data_consumption_gift:get_element() of
				[]-> %无策划数据情况,无视本接口
					New_Consumption = Consumption;
				{_BeginTime,EndTime,GiftList}->
					Type_List = [T_Type||{_,T_Type,_,_,_,_}<-GiftList],
					Type_Flag1 = lists:member(Type, Type_List),
					Type_Flag2 = lists:member(all, Type_List),
					if
						Type_Flag1 orelse Type_Flag2 -> %%规定类型里的
							if
								Consumption#status_consumption.end_time<NowTime->%活动过期了
									if
										Consumption#status_consumption.end_time>0-> %%有记录的
										%%	lib_player:update_consumption_endtime_eqout_times(Type,PlayerStatus#player_status.id,EndTime,Eqout,Times);
											OutFlag = 0;
										true-> %%没记录的
											OutFlag = 1,
											lib_player:insert_consumption(Type,PlayerStatus#player_status.id,EndTime,Eqout,Times)
									end,
									case OutFlag of
										0 -> New_Consumption = Consumption;
										1 -> 
											case Type of
												taobao->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_taobao = Eqout,
														times_taobao = Times,
														gift = ""								  
													};
												shangcheng->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_shangcheng = Eqout,
														times_shangcheng = Times,
														gift = ""								  
													};
												petcz->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_petcz = Eqout,
														times_petcz = Times,
														gift = ""								  
													};
												petqn->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_petqn = Eqout,
														times_petqn = Times,
														gift = ""								  
													};
												smsx->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_smsx = Eqout,
														times_smsx = Times,
														gift = ""								  
													};
												smgm->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_smgm = Eqout,
														times_smgm = Times,
														gift = ""								  
													};
												petjn->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_petjn = Eqout,
														times_petjn = Times,
														gift = ""								  
													};
												cmsd->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_cmsd = Eqout,
														times_cmsd = Times,
														gift = ""								  
													};
												_->
													New_Consumption = Consumption
											end
									end;
								true->%没有过期
									if
										Consumption#status_consumption.end_time >= (EndTime + 15*24*60*60) -> %不一致结束时间，将视为过期数据
											lib_player:update_consumption_endtime_eqout_times(Type,PlayerStatus#player_status.id,EndTime,Eqout,Times),
											case Type of
												taobao->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_taobao = Eqout,
														times_taobao = Times,
														gift = ""								  
													};
												shangcheng->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_shangcheng = Eqout,
														times_shangcheng = Times,
														gift = ""								  
													};
												petcz->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_petcz = Eqout,
														times_petcz = Times,
														gift = ""								  
													};
												petqn->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_petqn = Eqout,
														times_petqn = Times,
														gift = ""								  
													};
												smsx->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_smsx = Eqout,
														times_smsx = Times,
														gift = ""								  
													};
												smgm->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_smgm = Eqout,
														times_smgm = Times,
														gift = ""								  
													};
												petjn->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_petjn = Eqout,
														times_petjn = Times,
														gift = ""								  
													};
												cmsd->
													New_Consumption = #status_consumption{
														uid = PlayerStatus#player_status.id,
														end_time = EndTime,
														eqout_cmsd = Eqout,
														times_cmsd = Times,
														gift = ""								  
													};_->
													New_Consumption = Consumption
											end;
										true-> %%合法数据
											lib_player:update_consumption_eqout_times(Type,PlayerStatus#player_status.id,Eqout,Times),
											case Type of
												taobao->
													New_Consumption = Consumption#status_consumption{
														eqout_taobao = Consumption#status_consumption.eqout_taobao + Eqout,
														times_taobao = Consumption#status_consumption.times_taobao + Times										 
													};
												shangcheng->
													New_Consumption = Consumption#status_consumption{
														eqout_shangcheng = Consumption#status_consumption.eqout_shangcheng + Eqout,
														times_shangcheng = Consumption#status_consumption.times_shangcheng + Times										 
													};
												petcz->
													New_Consumption = Consumption#status_consumption{
														eqout_petcz = Consumption#status_consumption.eqout_petcz + Eqout,
														times_petcz = Consumption#status_consumption.times_petcz + Times										 
													};
												petqn->
													New_Consumption = Consumption#status_consumption{
														eqout_petqn = Consumption#status_consumption.eqout_petqn + Eqout,
														times_petqn = Consumption#status_consumption.times_petqn + Times										 
													};
												smsx->
													New_Consumption = Consumption#status_consumption{
														eqout_smsx = Consumption#status_consumption.eqout_smsx + Eqout,
														times_smsx = Consumption#status_consumption.times_smsx + Times										 
													};
												smgm->
													New_Consumption = Consumption#status_consumption{
														eqout_smgm = Consumption#status_consumption.eqout_smgm + Eqout,
														times_smgm = Consumption#status_consumption.times_smgm + Times										 
													};
												petjn->
													New_Consumption = Consumption#status_consumption{
														eqout_petjn = Consumption#status_consumption.eqout_petjn + Eqout,
														times_petjn = Consumption#status_consumption.times_petjn + Times										 
													};
												cmsd->
													New_Consumption = Consumption#status_consumption{
														eqout_cmsd = Consumption#status_consumption.eqout_cmsd + Eqout,
														times_cmsd = Consumption#status_consumption.times_cmsd + Times										 
													};
												_->
													New_Consumption = Consumption
											end
									end
							end;
						true->New_Consumption = Consumption
					end
			end,	
%%	end,
	New_PlayerStatus = PlayerStatus#player_status{consumption = New_Consumption},
	pp_activity_daily:reflash_31483(New_PlayerStatus),
	New_PlayerStatus.

%% 获取player guild数据
get_player_guild_data(Id) ->
	case db:get_row(io_lib:format(?sql_player_guild_data, [Id])) of
		[] ->
			[0, <<"">>, 0, 0];
		R ->
			R
	end.
%% 获取player_pet登录所需数据
get_player_pet_data(Id) ->
    db:get_row(io_lib:format(?sql_player_pet_data, [Id])).

%% 检测指定名称的角色是否已存在
is_exists(Name) ->
    case get_role_id_by_name(Name) of
        null -> false;
        _Other -> true
    end.

%% 取得在线角色的角色状态
get_online_info(Id) ->
    case ets:lookup(?ETS_ONLINE, Id) of
        [] -> 
			[];
        [R] ->
            case misc:is_process_alive(R#ets_online.pid) of
                true ->
					R;
                false ->
                    []
            end
    end.

%% get_online_info_global(Id) -> [] | Result
get_online_info_global(Id) ->
    Pid = misc:get_player_process(Id),
    case is_pid(Pid) of
        true ->
            if
                node(Pid) =:= node() ->
                    lib_player:get_online_info(Id);
                true ->
                    case rpc:call(node(Pid), lib_player, get_online_info, [Id]) of
                        {badrpc, _Reason} ->
                            [];
                        R ->
                            R
                    end
            end;
        false ->
            []
    end.

rpc_call_by_id(Id, Module, F, Args) ->
    Pid = misc:get_player_process(Id),
    case is_pid(Pid) of
        true ->
            case gen_server:call(Pid, {'apply_call', Module, F, Args}) of
                [] ->
                    [];
                R ->
                    R
            end;
        false ->
            []
    end.

rpc_cast_by_id(Id, Module, F, Args) ->
    Pid = misc:get_player_process(Id),
    case is_pid(Pid) of
        true ->
            gen_server:cast(Pid, {'apply_cast', Module, F, Args});
        false ->
            skip
    end.

%%回写高频数据
update_player_high(Status) ->
    db:execute(io_lib:format(?sql_update_player_high, [Status#player_status.gold, Status#player_status.bgold, Status#player_status.coin, Status#player_status.bcoin, Status#player_status.exp, Status#player_status.id]
    )).

%%回写经验值
update_player_exp(Status) ->
    db:execute(io_lib:format(<<"update `player_high` set `exp`=~p where id=~p">>, [Status#player_status.exp, Status#player_status.id]
    )).

%%change by xieyunfei
%%去掉了Status#player_status.physical，删了physical字段，physical现在变为记录，保存在`role_physical`表中
%%回写状态数据
update_player_state(Status) ->
    PK = Status#player_status.pk,
    Skill = Status#player_status.skill,
    db:execute(io_lib:format(?sql_update_player_state, [Status#player_status.scene, Status#player_status.x, Status#player_status.y, Status#player_status.hp, Status#player_status.mp, 
        case util:term_to_bitstring(Status#player_status.quickbar) of 
            <<"undefined">> -> <<"[]">>; 
            A -> A
        end, PK#status_pk.pk_value, PK#status_pk.pk_status, PK#status_pk.pk_status_change_time, Status#player_status.sit_time_left, Status#player_status.sit_time_today, Status#player_status.anger, 
        case util:term_to_bitstring(Skill#status_skill.skill_cd) of 
            <<"undefined">> -> <<"[]">>; 
            A -> A
        end,
        case util:term_to_bitstring(Status#player_status.sys_conf) of 
             <<"undefined">> -> <<"[]">>; 
            A -> A
        end,
        Status#player_status.shake_money_time,
        Status#player_status.id]
    )).
update_player_state2(Status) ->
    Skill = Status#player_status.skill,
    db:execute(io_lib:format(?sql_update_player_state2, [Status#player_status.scene, Status#player_status.x, Status#player_status.y, Status#player_status.hp, Status#player_status.mp, 
        case util:term_to_bitstring(Status#player_status.quickbar) of 
            <<"undefined">> -> <<>>; 
            A -> A
        end, Status#player_status.sit_time_left, Status#player_status.sit_time_today, Status#player_status.anger, 
        case util:term_to_bitstring(Skill#status_skill.skill_cd) of 
            <<"undefined">> -> <<>>; 
            A -> A
        end,
        Status#player_status.id]
    )).

%% 是否可以传送
is_transferable(_Status) ->
	%% 各种不能被传送的情况请写在下面：
    case lib_marriage:marry_state(_Status#player_status.marriage) of
        %% 巡游中不能传送
        8 -> false;
        _ ->
            %% 监狱不能传送
            case _Status#player_status.scene =:= 998 of
                true -> false;
                false ->
                    %% 运镖中
                    HS = _Status#player_status.husong,
                    if
                        HS#status_husong.husong /= 0 ->
                            false;	
                        true ->
                            case _Status#player_status.mount#status_mount.fly_mount =/= 0 of
                                true -> false;
                                _ -> 
                                    %% 跨服战场
                                    case lib_scene:get_res_type(_Status#player_status.scene) =:= ?SCENE_TYPE_CLUSTERS of
                                        true -> false;
                                        false ->
                                            lib_scene:is_transferable(_Status#player_status.scene)
                                    end
                            end
                    end
            end
    end.

%% 获用户信息
get_player_info(Id) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            case catch gen:call(Pid, '$gen_call', 'base_data') of
                {ok, Res} ->
                    Res;
                _ ->
                    false 
            end;
        _ ->
            false
    end.

%% 获用户信息_分类
get_player_info(Id, Type) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            case catch gen:call(Pid, '$gen_call', {'get_data', Type}) of
                {ok, Res} ->
                    Res;
                _ ->
                    false
            end;
        _ ->
            false
    end.

%% 获取翻拍奖品
%% @param Id 玩家Id
%% @param Type 翻牌类型：1蟠桃园
get_card_good(Id,Type) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
			 gen_server:cast(Pid,{get_card_good,Type});
        _ ->
            skip
    end.

%%游戏线调用，获取公共线状态
get_unite_status(Id) ->
    mod_disperse:call_to_unite(lib_player_unite, get_unite_status_unite, [Id]).

%% 更新用户信息
update_player_info(Id, PlayerStatus) when is_record(PlayerStatus, player_status) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'base_set_data', PlayerStatus});
        _ ->
            skip
    end;
%% 更新用户信息_分类(不分线) #player_status
%% @param Id 玩家ID
%% @param AttrKeyValueList 属性列表 [{Key,Value},{Key,Value},...] Key为原子类型，Value为所需参数数据
update_player_info(Id, AttrKeyValueList) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'set_data', AttrKeyValueList});
        _ ->
            skip
    end.

send_wubianhai_award(GoodsPid, AwardIdList, Tid, Id, Exp, Lilian) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'send_wubianhai_award', [GoodsPid, AwardIdList, Tid, Id, Exp, Lilian]});
        _ ->
            skip
    end.

%% 获取等级经验
next_lv_exp(Lv) ->
    data_exp:get(Lv).

%% 刷新客户端
refresh_client(Id, S) when is_integer(Id)  ->
    {ok, BinData} = pt_130:write(13005, S),
    lib_server_send:send_to_uid(Id, BinData).

%%或新人物信息
refresh_client(Ps) ->
    refresh_client(Ps#player_status.id, 1).
%% 一级属性转化为二级属性
one_to_two(Forza, Agile, Wit, Thew, Career) ->
    %% 职业收益
    [HpY, MpY, AttY, DefY, HitY, DodgeY] = case Career of
        1 -> [1, 1, 1, 1, 2, 3];  %% 神将
        2 -> [1, 2, 1, 1, 2, 3];  %% 天尊
        _ -> [1, 1, 1, 1, 2, 3]   %% 罗刹
    end,
    Hp = Thew * 10 * HpY + 200,
    Mp = Thew * 2 * MpY + 50,
    Att = Forza * 1 * AttY,
    Def = Thew * 1 * DefY,
    Hit = Wit * 2.5 * HitY,
    Dodge = Agile * 2 * DodgeY,
    %Crit = 5,
    [Hp, Mp, Att, Def, Hit, Dodge].

%% 人物属性计算
count_player_attribute(PlayerStatus) ->
    %% 记录原来的血量
    BeforeHp = PlayerStatus#player_status.hp,
    %% 人物一级属性
    [Forza1, Wit1, Agile1, Thew1, Ten1, Crit1] = PlayerStatus#player_status.base_attribute,
    %% 宠物属性加成
    [PetHp,PetMp,PetAtt,PetDef,PetHit,PetDodge,PetCrit,PetTen,PetFire, PetIce, PetDrug, _PetHit1, _PetHit2] = lib_pet:count_pet_attribute(PlayerStatus),
    %io:format("~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p~n", [PetHp,PetMp,PetAtt,PetDef,PetHit,PetDodge,PetCrit,PetTen,PetFire, PetIce, PetDrug]),
    %% 装备属性加成
    Go = PlayerStatus#player_status.goods,
    [Hp2, Mp2, Att2, Def2, Hit2, Dodge2, Crit2, Ten2, Forza2, 
    Agile2, Wit2, Thew2, Fire2, Ice2, Drug2, HpRatio2, MpRatio2, 
    AttRatio2, DefRatio2, HitRatio2, DodgeRatio2, CritRatio2, TenRatio2,  IceRatio2, FireRatio2, DrugRatio2] = Go#status_goods.equip_attribute,
	%% 经脉基础属性[力量、体制、灵力、身法]
    [Forza3, Thew3, Wit3, Agile3] = mod_meridian:count_meridian_base_attribute(PlayerStatus#player_status.player_meridian),
    %% 经脉加成
    %%[Hp3, Mp3, Def3, Hit3, Dodge3, Ten3,Crit3, Att3, Fire3, Ice3, Drug3] = mod_meridian:count_meridian_attribute(PlayerStatus#player_status.player_meridian),
    [_Hp36, Mp30, Def3, Hit3, Dodge3, Ten3,Crit31, Att3, Fire3, Ice3, Drug3] = mod_meridian:count_meridian_attribute(PlayerStatus#player_status.player_meridian),
    Mp3 = 0,
    Crit3 = Mp30,
    Hp3 = Crit31,
	%% 技能加成
    [Att4, Def4, Hit4, Dodge4, Crit4, Ten4, Fire4, Ice4, Drug4, Hp4, Mp4, HurtAddNum4, HurtDelNum4] = PlayerStatus#player_status.skill#status_skill.skill_attribute,
	%% buff加成
    [Hp5, Mp5, Att5, Def5, Hit5, Dodge5, Crit5, Ten5, Forza5, Agile5, Wit5, 
    Thew5, Fire5, Ice5, Drug5, HpRatio5, MpRatio5, AttRatio5, DefRatio5, 
    HitRatio5, DodgeRatio5, CritRatio5, TenRatio5, FireRatio5, IceRatio5, DrugRatio5] = PlayerStatus#player_status.buff_attribute,
    %% 器灵属性
    [QiLingForza, QiLingAgile, QiLingWit, QiLingThew] = lib_qiling:calc_qiling_attr(PlayerStatus#player_status.qiling_attr),
    %% 宝石系统加成
    [Hp14, Mp14, Att14, Def14, Hit14, Dodge14, Crit14, Ten14, Forza14, Agile14, Wit14, Thew14, Fire14, Ice14, Drug14] = PlayerStatus#player_status.gemstone_attr,
    %% 一级属性转化为二级属性
    [Hp1, Mp1, Att1, Def1, Hit1, Dodge1] = one_to_two(Forza1+Forza2+Forza3+Forza5+QiLingForza+Forza14, Agile1+Agile2+Agile3+QiLingAgile+Agile14, Wit1+Wit2+Wit3+Wit5+QiLingWit+Wit14, Thew1+Thew2+Thew3+Thew5+QiLingThew+Thew14, PlayerStatus#player_status.career),
    %% 成就加成
    [Hp6] = PlayerStatus#player_status.achieve_arr,
    %% 坐骑加成
    Mou = PlayerStatus#player_status.mount,
    Mount = lib_mount:get_equip_mount(PlayerStatus#player_status.id, Mou#status_mount.mount_dict),
    [Hp7, Mp7, Att7, Def7, Hit7, Dodge7, Crit7, Ten7, Fire7, Ice7, Drug7] = lib_mount2:remove_type_less_attr_value(Mount#ets_mount.attribute),
%%     [Hp7, Att7, Hit7, Crit7, Fire7, Ice7, Drug7, Mp7, Def7, Dodge7, Ten7, HpRatio7] = Mount#ets_mount.attribute ++ Mount#ets_mount.attribute2,
%%     AttRatio7 = Mount#ets_mount.att_per,
    %% 飞行器加成
    %% FlyerAttr = PlayerStatus#player_status.flyer_attr,
    %% [FHp, FAtt, FDef, FFire, FIce, FDrug, FHit, FDodge, FCrit, FTen] = lib_flyer:compose_attr(FlyerAttr),
    [FHp, FAtt, FDef, FFire, FIce, FDrug, FHit, FDodge, FCrit, FTen] = [0,0,0,0,0,0,0,0,0,0],
    %% 技能Buff加成
    [Hp8, Mp8, HpR8, MpR8] = PlayerStatus#player_status.skill#status_skill.buff_attribute,
    %% 称号属性
    [DesignAtt9, DesignDef9, DesignHp9, DesignMp9, DesignForza9, DesignAgile9, DesignWit9, DesignHit9, 
        DesignDodge9, DesignCrit9, DesignTen9, _DesignRes9, DesignThew9, DesignFire9, DesignIce9, DesignDrug9] = lib_designation:get_affected_attr(PlayerStatus),
    %% [Hp10, Def10] = mod_dungeon_data:count_base_attribute(
    %% PlayerStatus#player_status.pid_dungeon_data,
    %% PlayerStatus#player_status.id,
    %% PlayerStatus#player_status.dailypid),
    [Hp10, Def10, Att15] = mod_dungeon_data:count_base_attribute(
        PlayerStatus#player_status.pid_dungeon_data,
        PlayerStatus#player_status.id,
        PlayerStatus#player_status.dailypid, PlayerStatus#player_status.designation),
    %% io:format("~p ~p DunAttr:~p~n", [?MODULE, ?LINE, [Hp10, Def10]]),    
    %% 仙缘属性
	[Hp11, Def11, Hit11, Dodge11, Ten11, Crit11, Att11, Fire11, Ice11, Drug11] = mod_xianyuan:count_attribute(PlayerStatus),
	%% 仙缘基础属性[气血、雷抗、水抗、冥抗]
    [Hp12, Fire12, Ice12, Drug12] = mod_xianyuan:count_base_attribute(PlayerStatus),
    %% 帮派神兽技能属性
	[Hp13, Def13, Hit13, Dodge13, Crit13, Ten13, Att13, Ice13, Fire13, Drug13] = lib_guild_ga:get_ga_skill_add(PlayerStatus),
    
    %% ====汇总===
    %% 力量= 人物+经脉+装备+被动技能+宝石
    %% 灵力= 人物+经脉+装备+被动技能+宝石   
    %% 身法= 人物+经脉+装备+被动技能+宝石   
    %% 体质= 人物+经脉+装备+被动技能+宝石   
    NewForza = round(Forza1+Forza2+Forza3+Forza5+DesignForza9+QiLingForza+Forza14),
    NewAgile = round(Agile1+Agile2+Agile3+Agile5+DesignAgile9+QiLingAgile+Agile14),
    NewWit   = round(Wit1+Wit2+Wit3+Wit5+DesignWit9+QiLingWit+Wit14),
    NewThew  = round(Thew1+Thew2+Thew3+Thew5+DesignThew9+QiLingThew+Thew14),    

    %% 气血= (一级属性转化+人物+经脉+装备+坐骑+时装+被动技能效果+成就+药品加成+其他)*(1+装备%+被动技能%+药品加成%+其他%)+宠物+技能buff                        
    %% 内力= (一级属性转化+人物+经脉+装备+坐骑+时装+被动技能效果+成就+药品加成+其他)*(1+装备%+被动技能%+药品加成%+其他%)+宠物+技能Buff                        
    %% 攻击= (一级属性转化+人物+经脉+装备+坐骑+时装+被动技能效果+成就+药品加成+其他)*(1+装备%+被动技能%+药品加成%+其他%)+宠物+封魔称号                      
    %% 防御= (一级属性转化+人物+经脉+装备+坐骑+时装+被动技能效果+成就+药品加成+其他)*(1+装备%+被动技能%+药品加成%+其他%)+宠物                        
    %% 命中= (一级属性转化+人物+经脉+装备+坐骑+时装+被动技能效果+成就+药品加成+其他)*(1+装备%+被动技能%+药品加成%+其他%)+宠物                        
    %% 闪避= (一级属性转化+人物+经脉+装备+坐骑+时装+被动技能效果+成就+药品加成+其他)*(1+装备%+被动技能%+药品加成%+其他%)+宠物                        
    %% 暴击= (一级属性转化+人物+经脉+装备+坐骑+时装+被动技能效果+成就+药品加成+其他)*(1+装备%+被动技能%+药品加成%+其他%)+宠物                        
    %% 坚韧= (一级属性转化+人物+经脉+装备+坐骑+时装+被动技能效果+成就+药品加成+其他)*(1+装备%+被动技能%+药品加成%+其他%)+宠物                        
    %% 火抗性=    (一级属性转化+人物+经脉+装备+坐骑+时装+被动技能效果+成就+药品加成+其他)*(1+装备%+被动技能%+药品加成%+其他%)+宠物                        
    %% 冰抗性=    (一级属性转化+人物+经脉+装备+坐骑+时装+被动技能效果+成就+药品加成+其他)*(1+装备%+被动技能%+药品加成%+其他%)+宠物                        
    %% 毒抗性=    (一级属性转化+人物+经脉+装备+坐骑+时装+被动技能效果+成就+药品加成+其他)*(1+装备%+被动技能%+药品加成%+其他%)+宠物                        
    %% NewHpLim = (Hp1+Hp2+Hp3+Hp4+Hp5+Hp6+Hp7+DesignHp9+Hp10+Hp11+Hp12+Hp13+FHp)*(1+HpRatio2+HpRatio5+HpRatio7/100+HpR8)+PetHp+Hp8+Hp14,
    NewHpLim = (Hp1+Hp2+Hp3+Hp4+Hp5+Hp6+Hp7+DesignHp9+Hp10+Hp11+Hp12+Hp13+FHp)*(1+HpRatio2+HpRatio5/100+HpR8)+PetHp+Hp8+Hp14,
    NewMpLim = (Mp1+Mp2+Mp3+Mp4+Mp5+Mp7+DesignMp9)*(1+MpRatio2+MpRatio5+MpR8)+PetMp+Mp8+Mp14,
    %% NewAtt   = (Att1+Att2+Att3+Att4+Att5+Att7+DesignAtt9+Att11+Att13+FAtt)*(1+AttRatio2+AttRatio5+AttRatio7/100)+PetAtt+Att14+Att15,
    NewAtt   = (Att1+Att2+Att3+Att4+Att5+Att7+DesignAtt9+Att11+Att13+FAtt)*(1+AttRatio2+AttRatio5/100)+PetAtt+Att14+Att15,
    NewDefLim = (Def1+Def2+Def3+Def4+Def5+Def7+DesignDef9+Def10+Def11+Def13+FDef)*(1+DefRatio2+DefRatio5)+PetDef+Def14,
    NewHit   = (Hit1+Hit2+Hit3+Hit4+Hit5+Hit7+DesignHit9+Hit11+Hit13+FHit)*(1+HitRatio2+HitRatio5)+PetHit+Hit14,
    NewDodge = (Dodge1+Dodge2+Dodge3+Dodge4+Dodge5+Dodge7+DesignDodge9+Dodge11+Dodge13+FDodge)*(1+DodgeRatio2+DodgeRatio5)+PetDodge+Dodge14,
    NewCrit  = (Crit1+Crit2+Crit3+Crit4+Crit5+Crit7+DesignCrit9+Crit11+Crit13+FCrit)*(1+CritRatio2+CritRatio5)+PetCrit+Crit14,
    NewTen   = (Ten1+Ten2+Ten3+Ten4+Ten5+Ten7+DesignTen9+Ten11+Ten13+FTen)*(1+TenRatio2+TenRatio5)+PetTen+Ten14,
    NewFireLim = (Fire2+Fire3+Fire4+Fire5+Fire7+DesignFire9+Fire11+Fire12+Fire13+FFire)*(1+FireRatio2+FireRatio5)+PetFire+Fire14,
    NewIceLim = (Ice2+Ice3+Ice4+Ice5+Ice7+DesignIce9+Ice11+Ice12+Ice13+FIce)*(1+IceRatio2+IceRatio5)+PetIce+Ice14,
    NewDrugLim = (Drug2+Drug3+Drug4+Drug5+Drug7+DesignDrug9+Drug11+Drug12+Drug13+FDrug)*(1+DrugRatio2+DrugRatio5)+PetDrug+Drug14,
    %%=======护送buff加成==start
    Hs = PlayerStatus#player_status.husong,
    [HusongHpLim, _] = Hs#status_husong.hs_buff2,
	[HusongKang, HusongDef] = Hs#status_husong.hs_buff3,
    NewHusongHpLim = 
    case NewHpLim < HusongHpLim of
        true ->
            HusongHpLim;
        false ->
            NewHpLim
    end,
    NewHp = 
    case PlayerStatus#player_status.hp > NewHusongHpLim of
        true -> NewHusongHpLim;
        false -> PlayerStatus#player_status.hp
    end,
	NewDef =
    case NewDefLim < HusongDef of
		true -> HusongDef;
		false -> NewDefLim
	end,
	NewFire =
    case NewFireLim < HusongKang of
		true -> HusongKang;
		false -> NewFireLim
	end,
	NewIce =
    case NewIceLim < HusongKang of
		true -> HusongKang;
		false -> NewIceLim
	end,
	NewDrug =
    case NewDrugLim < HusongKang of
		true -> HusongKang;
		false -> NewDrugLim
	end,
	%%=======护送buff加成==end
    NewMp = 
    case PlayerStatus#player_status.mp >= NewMpLim of
        true -> NewMpLim;
        false -> PlayerStatus#player_status.mp
    end,
    %NewCrit1 = case NewCrit >= PlayerStatus#player_status.crit of
    %                true -> round(NewCrit);
    %                false -> round(PlayerStatus#player_status.crit)
    %            end,
    %NewTen1 = case NewTen >= PlayerStatus#player_status.ten of
    %                true -> round(NewTen);
    %                false -> round(PlayerStatus#player_status.ten)
    %            end,
	% 
	% [Hp13, Def13, Hit13, Dodge13, Ten13, Crit13, Att13, Fire13, Ice13, Drug13] = lib_guild_ga:get_ga_skill_add(PlayerStatus),
    %% 人物战斗力=攻击*0.7954+防御*0.2652+命中*0.2755+闪避*0.3306+暴击*0.8839+坚韧*0.4419+气血*0.053+(火抗+冰抗+毒抗)*0.0884
    %% NewAtt1 = (Att1+Att2+Att3+Att4+Att7+DesignAtt9+Att11+Att13+FAtt)*(1+AttRatio2+AttRatio7/100)+PetAtt+Att14+Att15,
    NewAtt1 = (Att1+Att2+Att3+Att4+Att7+DesignAtt9+Att11+Att13+FAtt)*(1+AttRatio2)+PetAtt+Att14+Att15,
    NewDef1 = (Def1+Def2+Def3+Def4+Def7+DesignDef9+Def10+Def11+Def13+FDef)*(1+DefRatio2)+PetDef+Def14,
    %% NewHit1 = (Hit1+Hit2+Hit3+Hit4+Hit7)*(1+HitRatio2)+PetHit2,
    NewHit1 = (Hit1+Hit2+Hit3+Hit4+Hit7+DesignHit9+Hit11+Hit13+FHit)*(1+HitRatio2)+PetHit+Hit14,
    NewDodge1 = (Dodge1+Dodge2+Dodge3+Dodge4+Dodge7+DesignDodge9+Dodge11+Dodge13+FDodge)*(1+DodgeRatio2)+PetDodge+Dodge14,
    NewCrit2 = (Crit1+Crit2+Crit3+Crit4+Crit7+DesignCrit9+Crit11+Crit13+FCrit)*(1+CritRatio2)+PetCrit+Crit14,
    NewTen2 = (Ten1+Ten2+Ten3+Ten4+Ten7+DesignTen9+Ten11+Ten13+FTen)*(1+TenRatio2)+PetTen+Ten14,
    %% NewHpLim1 = (Hp1+Hp2+Hp3+Hp4+Hp6+Hp7+DesignHp9+Hp10+Hp11+Hp12+Hp13+FHp)*(1+HpRatio2+HpRatio7/100)+PetHp+Hp14,
    NewHpLim1 = (Hp1+Hp2+Hp3+Hp4+Hp6+Hp7+DesignHp9+Hp10+Hp11+Hp12+Hp13+FHp)*(1+HpRatio2/100)+PetHp+Hp14,
    NewFire1 = (Fire2+Fire3+Fire4+Fire7+DesignFire9+Fire11+Fire12+Fire13+FFire)*(1+FireRatio2)+PetFire+Fire14,
    NewIce1 = (Ice2+Ice3+Ice4+Ice7+DesignIce9+Ice11+Ice12+Ice13+FIce)*(1+IceRatio2)+PetIce+Ice14,
    NewDrug1 = (Drug2+Drug3+Drug4+Drug7+DesignDrug9+Drug11+Drug12+Drug13+FDrug)*(1+DrugRatio2)+PetDrug+Drug14,
    %% _PetHit1 = case PetHit1*10-648 =< 0 of true -> 0; false -> (PetHit1*10-648)*0.2755 end,
    %% Combat_power = NewAtt1*0.7954+NewDef1*0.2652+_PetHit1+NewHit1*0.2755+NewDodge1*0.3306+NewCrit2*0.8839+NewTen2*0.4419+NewHpLim1*0.053+(NewFire1+NewIce1+NewDrug1)*0.0884,
    Combat_power = NewAtt1*3.97+NewDef1*1.32+NewHit1*1.37+NewDodge1*1.65+NewCrit2*3.53+NewTen2*1.76+NewHpLim1*0.26+(NewFire1+NewIce1+NewDrug1)*0.44,
    %% 触发名人堂：这里避免频繁调用，作个数量限制，达到要求的5000才会触发
	case Combat_power >= 5000 of
		true ->
			mod_fame:trigger(PlayerStatus#player_status.mergetime, PlayerStatus#player_status.id, 9, 0, Combat_power);
		_ ->
			skip
	end,
    PlayerStatus1 = PlayerStatus#player_status {
                                forza        = round(NewForza),
                                agile        = round(NewAgile),
                                wit          = round(NewWit),
                                thew         = round(NewThew),
                                hp           = round(NewHp),
                                hp_lim       = round(NewHusongHpLim),
                                mp           = round(NewMp),
                                mp_lim       = round(NewMpLim),
                                att          = round(NewAtt),
                                def          = round(NewDef),
                                hit          = round(NewHit),
                                dodge        = round(NewDodge),
                                crit         = round(NewCrit),
                                ten          = round(NewTen),
                                fire         = round(NewFire),
                                ice          = round(NewIce),
                                drug         = round(NewDrug),
                                hurt_add_num = round(HurtAddNum4),
                                hurt_del_num = round(HurtDelNum4),
                                combat_power = round(Combat_power)
                    },
    %% 南天门保底Buff
    [WubianhaiHpLim, WubianhaiHp, WubianhaiAtt] = PlayerStatus1#player_status.wubianhai_buff,
    case WubianhaiHp > PlayerStatus1#player_status.hp of
        true -> NewWubianhaiHp = WubianhaiHp;
        false -> 
            case WubianhaiHpLim > 0 of
               true -> NewWubianhaiHp = BeforeHp;
               false -> NewWubianhaiHp = PlayerStatus1#player_status.hp
            end
    end,
    PlayerStatus2 = case WubianhaiHpLim > PlayerStatus1#player_status.hp_lim of
        true -> PlayerStatus1#player_status{
                hp     = NewWubianhaiHp,
                hp_lim = WubianhaiHpLim,
                wubianhai_buff = [WubianhaiHpLim, 0, WubianhaiAtt]
        };
        false -> PlayerStatus1#player_status{
                wubianhai_buff = [WubianhaiHpLim, 0, WubianhaiAtt]
		}
    end,
    PlayerStatus3 = case WubianhaiAtt > PlayerStatus2#player_status.att of
        true -> PlayerStatus2#player_status{
                att     = WubianhaiAtt
        };
        false -> PlayerStatus2
    end,
    %% 城战固有变身属性
    case lists:keyfind(attr, 1, PlayerStatus3#player_status.factionwar_option) of
        false -> PlayerStatus3;
        {_, [CWHp, CWLim, CWDef, CWAtt, CWFire, CWIce, CWDrug, CWCrit, CWDodge, CWTen, CWHit]} ->
            case PlayerStatus3#player_status.factionwar_stone == 12 orelse PlayerStatus3#player_status.factionwar_stone == 11 of
                true ->
                    CWHp1 = case CWHp =< 0 of
                        true -> BeforeHp;
                        false -> CWHp
                    end,
                    PlayerStatus3#player_status{hp=CWHp1, hp_lim=CWLim, def=CWDef, att=CWAtt, fire=CWFire, ice=CWIce, drug=CWDrug, crit=CWCrit, dodge=CWDodge, ten=CWTen, hit = CWHit, factionwar_option=[{attr, [0, CWLim, CWDef, CWAtt, CWFire, CWIce, CWDrug, CWCrit, CWDodge, CWTen, CWHit]}]};
                false -> PlayerStatus3#player_status{factionwar_option=[]}
            end
    end.

%% 此方法不能在物品进程里面使用
send_attribute_change_notify(Status, Reason) ->
	ExpLimit = data_exp:get(Status#player_status.lv),
    C = Status#player_status.chengjiu,
    Vip = Status#player_status.vip,
    %% 血包法包修改 xieyunfei
    %%Hp = Status#player_status.hp_bag,
    HpBagCount = lib_hp_bag:get_bag_count(Status#player_status.id,?GOODS_SUBTYPE_HP_BAG),
    MpBagCount = lib_hp_bag:get_bag_count(Status#player_status.id,?GOODS_SUBTYPE_MP_BAG),
    Go = Status#player_status.goods,
    case Go#status_goods.goods_pid =/= self() of
        true ->
	        Dict = lib_goods_dict:get_player_dict_by_goods_pid(Go#status_goods.goods_pid);
        false ->
            Dict = []
    end,
    case  Dict =/= [] of
        true ->
            SuitList = lib_goods_util:get_suit_id_and_num(Status#player_status.id, Dict);
        false ->
            SuitList = [{0,0}, {0,0}, {0,0}]
    end,
	%%称号
	{DesignLen, DesignBin} = lib_designation:get_client_design(Status),
	Arena = Status#player_status.arena,
	Factionwar = Status#player_status.factionwar,
    case Status#player_status.marriage#status_marriage.register_time of
        0 -> 
            ParnerId = 0,
            ParnerName = "";
        _ ->
            ParnerId = Status#player_status.marriage#status_marriage.parner_id,
            ParnerName = Status#player_status.marriage#status_marriage.parner_name
    end,
    {ok, BinData} = pt_130:write(13011, [Status#player_status.id, 
            Reason, Status#player_status.lv, 
            Status#player_status.exp, ExpLimit, 
            Status#player_status.hp, 
            Status#player_status.hp_lim, 
            Status#player_status.mp, 
            Status#player_status.mp_lim, 
            Status#player_status.att, 
            Status#player_status.def, 
            Status#player_status.hit, 
            Status#player_status.dodge, 
            Status#player_status.crit, 
            Status#player_status.ten, 
            Status#player_status.gold,
            Status#player_status.bgold,
            Status#player_status.coin,
            Status#player_status.bcoin,
            Status#player_status.forza,
            Status#player_status.agile,
            Status#player_status.wit,
            Status#player_status.thew,
            Status#player_status.fire,
            Status#player_status.ice,
            Status#player_status.drug,
            Status#player_status.llpt,
            Status#player_status.xwpt,
            Status#player_status.fbpt,
            Status#player_status.fbpt2,
            Status#player_status.bppt,
            Status#player_status.gjpt,
            Vip#status_vip.vip_type,
            C#status_chengjiu.honour,
            Status#player_status.mlpt,
            HpBagCount,
            MpBagCount,
            Status#player_status.combat_power,
            Status#player_status.point,
			DesignLen,
			DesignBin,
			Status#player_status.whpt,
            Go#status_goods.hide_fashion_armor,
            Go#status_goods.hide_fashion_accessory,
            Go#status_goods.stren7_num,
            SuitList,
            Arena#status_arena.arena_score_total-Arena#status_arena.arena_score_used,
            Status#player_status.anger_lim, 
			Factionwar#status_factionwar.war_score-Factionwar#status_factionwar.war_score_used,
            ParnerId,
            ParnerName,
			Status#player_status.image,
			Status#player_status.kf_1v1#status_kf_1v1.pt,
			Status#player_status.kf_1v1#status_kf_1v1.score,
            Go#status_goods.hide_fashion_weapon,
            Go#status_goods.hide_head,
            Go#status_goods.hide_tail,
            Go#status_goods.hide_ring
        ]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
	BinData.

%% 增加罪恶值
add_pk_value(Status, Value) -> 
    update_player_info(Status#player_status.id, [{add_pk_value, Value}]).

add_pk_value_deal(Status, NewStatus) -> 
%%    %% 变黄名
%%    case Status#player_status.pk#status_pk.pk_value =< 100 andalso NewStatus#player_status.pk#status_pk.pk_value > 100 of
%%        true -> 
%%            {ok, Bin1} = pt_120:write(12084, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, NewStatus#player_status.pk#status_pk.pk_status, NewStatus#player_status.pk#status_pk.pk_value]),
%%            lib_server_send:send_to_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, Bin1),
%%            mod_scene_agent:update(pk, NewStatus);
%%        false -> skip
%%    end,
%%    %% 变红名
    case Status#player_status.pk#status_pk.pk_value =< 200 andalso NewStatus#player_status.pk#status_pk.pk_value > 200 of
        true -> 
            %% 邮件通知
            Title1 = data_gjpt:text(1),
            Content1 = data_gjpt:text(2),
            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[NewStatus#player_status.id], Title1, Content1, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        false -> skip
    end,
    {ok, Bin} = pt_120:write(12084, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, NewStatus#player_status.pk#status_pk.pk_status, NewStatus#player_status.pk#status_pk.pk_value]),
    lib_server_send:send_to_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, Bin),
    mod_scene_agent:update(pk, NewStatus),
    %% 送进监狱
    case NewStatus#player_status.pk#status_pk.pk_value > 500 of
        true -> 
            %% 邮件通知
            Title2 = data_gjpt:text(3),
            Content2 = data_gjpt:text(4),
            mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[NewStatus#player_status.id], Title2, Content2, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            lib_scene:player_change_scene(NewStatus#player_status.id, 998, 0, 30, 38, false);
        false -> skip
    end,
    %% 红名状态下自动切换为全体PK模式
    case NewStatus#player_status.pk#status_pk.pk_value > 200 andalso NewStatus#player_status.pk#status_pk.pk_status /= 1 of 
        true -> change_pk_status_cast(NewStatus#player_status.id, 1);
        false -> skip
    end.    

%% 减少罪恶值
minus_pk_value(Status, Value) -> 
    update_player_info(Status#player_status.id, [{minus_pk_value, Value}]).

minus_pk_value_deal(_Status, NewStatus) ->
%%    %% 黄名变白名
%%    case Status#player_status.pk#status_pk.pk_value > 100 andalso NewStatus#player_status.pk#status_pk.pk_value =< 100 of
%%        true -> 
%%            {ok, Bin1} = pt_120:write(12084, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, NewStatus#player_status.pk#status_pk.pk_status, NewStatus#player_status.pk#status_pk.pk_value]),
%%            lib_server_send:send_to_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, Bin1),
%%            mod_scene_agent:update(pk, NewStatus);
%%        false -> skip
%%    end,
%%    %% 红名变黄名
%%    case Status#player_status.pk#status_pk.pk_value > 200 andalso NewStatus#player_status.pk#status_pk.pk_value =< 200 of
%%        true -> 
%%            {ok, Bin2} = pt_120:write(12084, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, NewStatus#player_status.pk#status_pk.pk_status, NewStatus#player_status.pk#status_pk.pk_value]),
%%            lib_server_send:send_to_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, Bin2),
%%            mod_scene_agent:update(pk, NewStatus);
%%        false -> skip
%%    end,
    {ok, Bin} = pt_120:write(12084, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num, NewStatus#player_status.pk#status_pk.pk_status, NewStatus#player_status.pk#status_pk.pk_value]),
    lib_server_send:send_to_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, Bin),
    mod_scene_agent:update(pk, NewStatus),
    %% 送出监狱
    case NewStatus#player_status.pk#status_pk.pk_value =< 500 andalso NewStatus#player_status.scene == ?PRISON_SCENE of
        true ->
            {MainCityX, MainCityY} = lib_scene:get_main_city_x_y(), 
            lib_scene:change_scene_queue(NewStatus, ?MAIN_CITY_SCENE, 0, MainCityX, MainCityY, 0);
        false -> skip
    end.

%% 消耗声望
cost_pt(llpt, PlayerStatus, Cost) ->
    C = PlayerStatus#player_status.llpt - Cost,
    db:execute(io_lib:format(?sql_update_llpt, [C, PlayerStatus#player_status.id])),
    PlayerStatus#player_status{llpt=C}.

%% 增加声望
add_pt(_, PlayerStatus, 0) -> PlayerStatus;

add_pt(llpt, PlayerStatus, Num) ->
	C = PlayerStatus#player_status.llpt + Num,
	db:execute(io_lib:format(?sql_update_llpt, [C, PlayerStatus#player_status.id])),
	%% 限时名人堂（活动）
	PlayerStatus1 = lib_fame_limit:trigger_pt(PlayerStatus, Num),
	PlayerStatus1#player_status{llpt=C};

add_pt(xwpt, PlayerStatus, Num) ->
    C = PlayerStatus#player_status.xwpt + Num,
    db:execute(io_lib:format(?sql_update_xwpt, [C, PlayerStatus#player_status.id])),
    PlayerStatus#player_status{xwpt=C};

add_pt(fbpt, PlayerStatus, Num) ->
    C = PlayerStatus#player_status.fbpt + Num,
    db:execute(io_lib:format(?sql_update_fbpt, [C, PlayerStatus#player_status.id])),
    PlayerStatus#player_status{fbpt=C};

add_pt(fbpt2, PlayerStatus, Num) ->
    C = PlayerStatus#player_status.fbpt2 + Num,
    db:execute(io_lib:format(?sql_update_fbpt2, [C, PlayerStatus#player_status.id])),
    PlayerStatus#player_status{fbpt2=C};

add_pt(bppt, PlayerStatus, Num) ->
    C = PlayerStatus#player_status.bppt + Num,
    db:execute(io_lib:format(?sql_update_bppt, [C, PlayerStatus#player_status.id])),
    PlayerStatus#player_status{bppt=C};

add_pt(gjpt, PlayerStatus, Num) ->
    %update_player_info(PlayerStatus#player_status.id, [{add_gjpt, Num}]),
    C = PlayerStatus#player_status.gjpt + Num,
    db:execute(io_lib:format(?sql_update_gjpt, [C, PlayerStatus#player_status.id])),
	%% 名人堂：如日中天，第一个国家声望达到1000
	mod_fame:trigger(PlayerStatus#player_status.mergetime, PlayerStatus#player_status.id, 2, 0, C),
	%% 成就：奉旨杀人，国家声望达到N点
	mod_achieve:trigger_role(PlayerStatus#player_status.achieve, PlayerStatus#player_status.id, 5, 0, C),
    PlayerStatus#player_status{gjpt=C};

add_pt(mlpt, PlayerStatus, Num) ->
	C = PlayerStatus#player_status.mlpt + Num,
    db:execute(io_lib:format(?sql_update_mlpt, [C, PlayerStatus#player_status.id])),
    PlayerStatus#player_status{mlpt=C};

add_pt(whpt, PlayerStatus, Num) ->
    C = PlayerStatus#player_status.whpt + Num,
    db:execute(io_lib:format(?sql_update_whpt, [C, PlayerStatus#player_status.id])),
    PlayerStatus#player_status{whpt=C};

add_pt(cjpt, PlayerStatus, Num) ->
	C = PlayerStatus#player_status.cjpt + Num,
    db:execute(io_lib:format(?sql_update_cjpt, [C, PlayerStatus#player_status.id])),
	%% 名人堂：成就达人，第一个成就达到200点数
	mod_fame:trigger(PlayerStatus#player_status.mergetime, PlayerStatus#player_status.id, 13, 0, C),
    PlayerStatus#player_status{cjpt=C}.

%% 减少声望
minus_pt(_, R, 0) -> R;
minus_pt(llpt, R, Num) ->
    C = R#player_status.llpt - Num,
    db:execute(io_lib:format(?sql_update_llpt, [C, R#player_status.id])),
    R#player_status{llpt=C};
minus_pt(xwpt, R, Num) ->
    C = R#player_status.xwpt - Num,
    db:execute(io_lib:format(?sql_update_xwpt, [C, R#player_status.id])),
    R#player_status{xwpt=C};
minus_pt(fbpt, R, Num) ->
    C = R#player_status.fbpt - Num,
    db:execute(io_lib:format(?sql_update_fbpt, [C, R#player_status.id])),
    R#player_status{fbpt=C};
minus_pt(fbpt2, R, Num) ->
    C = R#player_status.fbpt2 - Num,
    db:execute(io_lib:format(?sql_update_fbpt2, [C, R#player_status.id])),
    R#player_status{fbpt2=C};
minus_pt(bppt, R, Num) ->
    C = R#player_status.bppt - Num,
    db:execute(io_lib:format(?sql_update_bppt, [C, R#player_status.id])),
    R#player_status{bppt=C};
minus_pt(gjpt, R, Num) ->
    %update_player_info(R#player_status.id, [{minus_gjpt, Num}]),
    C = R#player_status.gjpt - Num,
    C1 = case C > 0 of
        true -> C;
        false -> 0
    end,
    db:execute(io_lib:format(?sql_update_gjpt, [C1, R#player_status.id])),
    R#player_status{gjpt=C1};
minus_pt(mlpt, R, Num) ->
    C = R#player_status.mlpt - Num,
    db:execute(io_lib:format(?sql_update_mlpt, [C, R#player_status.id])),
    R#player_status{mlpt=C};
minus_pt(_, R, _) -> R.

%%扣除武魂
%%@param R #player_status
%%@param Num 扣除的数量
%%@return #player_status
minus_whpt(R, Num) ->
	if
		Num=<0->
			R;
		true->
			if
				R#player_status.whpt=<Num->
					Whpt = 0;
				true->
					Whpt = R#player_status.whpt-Num
			end,
		    db:execute(io_lib:format(?sql_update_whpt, [Whpt, R#player_status.id])),
			New_R = R#player_status{whpt=Whpt},
			%%刷新13011
			lib_player:send_attribute_change_notify(New_R, 0),
			New_R
	end.

%% 衰减怪物经验
reduce_mon_exp_arg(PlayerLv, MonLv) -> 
    if  %% 低于自身20级以上的怪物，击杀获得经验值降低为10%.
        (PlayerLv - MonLv) > 20 -> 0.1;
        %% 低于自身15级以上的怪物，击杀获得经验值降低为15%.
        (PlayerLv - MonLv) > 15 -> 0.15;
        %% 低于自身10级以上的怪物，击杀获得经验值降低为30%.
        (PlayerLv - MonLv) > 10 -> 0.3;
        true -> 1
    end.

%% 增加人物经验
add_exp(Status, Exp) ->
    add_exp(Status, Exp, 1, 0).

%% 增加人物经验
add_exp(Status, Exp, State) ->
    add_exp(Status, Exp, State, 0).

%% 增加人物经验
%% State为0的时候收益正常
%% ExpType:经验类型 0:无类型;1:打怪类型
add_exp(Status, Exp, State, ExpType) ->
	%% 原经验
	OldExp = Status#player_status.exp,

	%0收益正常，3小时 1收益减半，5小时 2收益为0
	Fcm = Status#player_status.fcm,
	case Fcm#status_fcm.fcm_state == 2 andalso State =:= 1 of
		true -> %收益0
			Status;
		false ->
			case Fcm#status_fcm.fcm_state == 1 andalso State =:= 1 of
				true -> %收益减半
					Exp1 = round(Status#player_status.exp + Exp/2);
				false ->
					Exp1 = Status#player_status.exp + Exp
			end,
			NextLvExp = next_lv_exp(Status#player_status.lv),

			if
				%% ---------- 未升级 ----------
				NextLvExp > Exp1 ->  
					{ok, BinData} = pt_130:write(13002, [Exp1, ExpType]),
					lib_server_send:send_to_sid(Status#player_status.sid, BinData),
					Status1 = Status#player_status{exp = Exp1},

					%% 15次写一次 state 为 0 的时候马上写数据库
					TT = case get("lib_player_add_exp") of
						undefined-> 0;
						_TT -> _TT
					end,
					case TT < 15 andalso State =:= 1 of
						true->
							put("lib_player_add_exp", TT+1);
						false ->
							update_player_exp(Status1),
							put("lib_player_add_exp", 0)
					end,
					%% 限时名人堂（活动）
					Status2 = lib_fame_limit:trigger_exp(Status1, Exp1 - OldExp),
                    Status2;


				%% ---------- 已升级 ---------- 
				true -> 
					Exp2 = Exp1 - NextLvExp,
					Lv = Status#player_status.lv + 1,
                    ActiveSum1 = data_active:get_active_sum(Lv-1),
                    ActiveSum2 = data_active:get_active_sum(Lv),
                    case ActiveSum1 =:= ActiveSum2 of
                        true ->
                            skip;
                        _ ->
                           %% 通知客户端显示有新项触发
                           {ok, Bin31481} = pt_314:write(31481, []),
                           lib_server_send:send_to_uid(Status#player_status.id, Bin31481)
                    end,
                    %%目标：将等级提升到55级501
                    mod_target:trigger(Status#player_status.status_target, Status#player_status.id, 501, Lv),
                    
					%% 同步帮派成员等级
					mod_disperse:cast_to_unite(lib_guild_base, update_guild_member_new_info, [Status#player_status.id, Lv]),

					%% 升一级加两点
					[Forza0, Agile0, Wit0, Thew0, Ten0, Crit0] = [2, 2, 2, 2, 2, 0],
					[_Forza0, _Agile0, _Wit0, _Thew0, _Ten0, _Crit0] = Status#player_status.base_attribute,
					Forza1 = Forza0 + _Forza0,
					Agile1 = Agile0 + _Agile0,
					Wit1 = Wit0 + _Wit0,
					Thew1 = Thew0 + _Thew0,
					Ten1 = Ten0 + _Ten0,
					Crit1 = Crit0 + _Crit0,
					Status1 = Status#player_status{
						exp = Exp2,
						lv = Lv,
						ten = Status#player_status.ten + Ten0,
						crit = Status#player_status.crit + Crit0,
						base_attribute = [Forza1, Agile1, Wit1, Thew1, Ten1, Crit1]
					},
					%% 人物属性计算
					NewStatus = count_player_attribute(Status1),
                    
					%%加入事务处理
					Fun = fun() ->
						Sql = io_lib:format(<<"update player_attr set forza=~p, agile=~p, wit=~p, thew=~p, crit=~p, ten=~p  where id=~p">>, [Forza1, Agile1, Wit1, Thew1, Crit1, Ten1, NewStatus#player_status.id]),
						db:execute(Sql),
						Sql1 = io_lib:format(<<"update `player_high` set exp=~p where id=~p">>, [Exp2, NewStatus#player_status.id]),
						db:execute(Sql1),
						db:execute(io_lib:format(<<"update `player_state` set hp=~p, mp=~p where id=~p">>, [NewStatus#player_status.hp_lim, NewStatus#player_status.mp_lim, NewStatus#player_status.id])),
						db:execute(io_lib:format(<<"update `player_low` set lv = ~p where id=~p">>, [Lv, NewStatus#player_status.id])),
						%% 日志
						case Lv > 30 of
							true ->log:log_uplv(NewStatus#player_status.id, Lv);
							false -> skip
						end
					end,
					db:transaction(Fun),
					%% 更新帮派成员缓存
					%% lib_guild:role_upgrade(NewStatus#player_status.id, Lv),
					%% 更新公共线的等级信息
					update_unite_info(NewStatus#player_status.unite_pid, [{lv, Lv}]),
					%% 更新组队进程.
					lib_team:set_member_level(NewStatus),

				    %% 20级时回写玩家场景和坐标
				    case Lv =:= 20 of
				        true ->
				            lib_player:update_player_state(NewStatus);
				        false ->
				            skip
				    end,
					    %% 发送防骗邮件
				    case Lv =:= 30 of
					true ->
					    %mod_disperse:cast_to_unite(lib_mail, send_sys_mail, [[NewStatus#player_status.id], data_sys_mail_text:get_mail_title(), data_sys_mail_text:get_mail_content()]);
                        mod_disperse:cast_to_unite(lib_mail, send_sys_mail_2, [
                                [NewStatus#player_status.id], 
                                data_sys_mail_text:get_mail_title(), 
                                data_sys_mail_text:get_mail_content(),
                                0, 0, 0, 0, 0, 0, 0, 0, 500, 500
                            ]
                        );
					false ->
					    skip
				    end,
				    %% 发送西行礼包邮件
				    case Lv =:= 39 andalso config:get_phone_gift() =:= 1 andalso util:get_open_day() =< 3 of
				    	true ->
				    	    mod_disperse:cast_to_unite(lib_mail, send_sys_mail, [[NewStatus#player_status.id], data_first_gift_text:get_mail_title(), data_first_gift_text:get_mail_content()]);
				    	false ->
				    	    skip
				    end,
				    
				    %% 触发成就
				    case Lv >= 30 andalso (Lv rem 10) =:= 0 of
				        true -> 
						mod_achieve:trigger_role(NewStatus#player_status.achieve, NewStatus#player_status.id, 1, 0, Lv);
				        false -> 
				            skip
				    end,
					
					%% 触发名人堂：冲级！，第一个人物达到40
					case Lv >= 30 of
						true ->
							mod_fame:trigger(NewStatus#player_status.mergetime, NewStatus#player_status.id, 8, 0, Lv);
						_ ->
							skip
					end,
			%% 升级不再广播场景
                    {ok, BinData2} = pt_120:write(12034, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num]),
                    lib_server_send:send_to_sid(NewStatus#player_status.sid, BinData2),
					%% 刷新任务列表
					lib_task:refresh_task(NewStatus),
                    gen_server:cast(NewStatus#player_status.pid, {'sys_refresh_task_eb'}),
					%% 去掉,防止升级后平乱任务刷新，接取不了任务
					%% gen_server:cast(NewStatus#player_status.pid, {'refresh_task_sr_init'}),

                    NewStatus1 = NewStatus#player_status{hp = NewStatus#player_status.hp_lim, mp = NewStatus#player_status.mp_lim},
                    send_attribute_change_notify(NewStatus1, 1),

                    %% 更新场景服务器
                    mod_scene_agent:update(battle_attr, NewStatus1),

					%% 刷新玩家等级榜
					case Lv >= 30 of
						true -> lib_rank_refresh:refresh_player_level_rank(NewStatus1);
						_ -> skip
					end,

					%%好友升级祝福通知
					gen_server:cast(NewStatus1#player_status.pid, {'apply_cast', lib_relationship, bless_notice, [NewStatus1#player_status.pid, NewStatus1#player_status.id,NewStatus1#player_status.nickname,Lv,NewStatus1#player_status.sex,NewStatus1#player_status.career,NewStatus1#player_status.image,NewStatus1#player_status.realm]}),
					%% 限时名人堂（活动）
					NewStatus2 = lib_fame_limit:trigger_exp(NewStatus1, Exp1 - OldExp),
					
					%% 处理世界等级经验加成buff图标
                    lib_rank_helper:world_remove_buff(NewStatus2),

                    %% UC封测活动
                    lib_uc:switch(lv_40_send_gold, [NewStatus2#player_status.id, Lv]),

                    %% 默认激活第一个飞行器
                    case Lv =:= 60 of
                        true ->
                            case self() =:= NewStatus2#player_status.pid of
                                true ->
                                    lib_flyer:unlock_flyer_auto(NewStatus2#player_status.id, 1),
                                    NewStatus3 = lib_flyer:count_attribute_base(NewStatus2),
                                    NewStatus3;
                                false ->
                                    rpc_cast_by_id(NewStatus2#player_status.id, lib_flyer, unlock_flyer_auto, [NewStatus2#player_status.id, 1]),
                                    NewStatus2
                            end;
                        false ->
                            NewStatus2
                    end
			end
	end.

%% 增加铜币
add_coin(R, 0) -> R;
add_coin(R, Num) ->
    C = R#player_status.coin + Num,
    db:execute(io_lib:format(<<"update `player_high` set coin = ~p where id = ~p ">>, [C, R#player_status.id])),
	%% 成就：西游巨富，拥有N万铜钱
	mod_achieve:trigger_role(R#player_status.achieve, R#player_status.id, 2, 0, C),
    R#player_status{coin=C}.

%% 增加绑定铜币
add_bcoin(R, 0) -> R;
add_bcoin(R, Num) ->
    C = R#player_status.bcoin + Num,
    db:execute(io_lib:format(<<"update `player_high` set bcoin = ~p where id = ~p ">>, [C, R#player_status.id])),
    R#player_status{bcoin=C}.

%% 加货币：包括铜钱，绑定铜钱，元宝，绑定元宝
add_money(PS, Amount, Type) ->
	NewPS = case Type of
		coin ->
			%% 成就：西游巨富，拥有N万铜钱
			Total = PS#player_status.coin + Amount,
			mod_achieve:trigger_role(PS#player_status.achieve, PS#player_status.id, 2, 0, Total),

			PS#player_status{coin =Total};
		bcoin -> 
			PS#player_status{bcoin = (PS#player_status.bcoin + Amount)};
        bgold ->
			PS#player_status{bgold = (PS#player_status.bgold+ Amount)};
        gold -> 
			PS#player_status{gold = (PS#player_status.gold + Amount)};
		_ ->
			PS
    end,
    Sql = io_lib:format(?sql_update_player_money, [
		NewPS#player_status.gold,
		NewPS#player_status.bgold,
		NewPS#player_status.coin,
		NewPS#player_status.bcoin,
		NewPS#player_status.id
	]),
    db:execute(Sql),
    NewPS.

%% 玩家不在线增加金钱
add_money_offline(RoleId, Amount, Type) ->
	case get_player_high_data(RoleId) of
		[Gold, Bgold, Coin, Bcoin, _Exp] ->
			[NewGold, NewBgold, NewCoin, NewBcoin] = case Type of
%% 				coin ->
%% 					TotalCoin = Coin + Amount,
%% 					[Gold, Bgold, TotalCoin, Bcoin];
%% 				bcoin -> 
%% 					TotalBcoin = Bcoin + Amount,
%% 					[Gold, Bgold, Coin, TotalBcoin];
%% 		        bgold ->
%% 					TotalBgold = Bgold + Amount,
%% 					[Gold, TotalBgold, Coin, Bcoin];
		        gold -> 
					TotalGold = Gold + Amount,
					[TotalGold, Bgold, Coin, Bcoin];
				_ ->
					[Gold, Bgold, Coin, Bcoin]
		    end,
		    Sql = io_lib:format(?sql_update_player_money, [
				NewGold,
				NewBgold,
				NewCoin,
				NewBcoin,
				RoleId
			]),
		    db:execute(Sql),
			[[Gold, Bgold, Coin, Bcoin], [NewGold, NewBgold, NewCoin, NewBcoin]];
		_ ->
			false
	end.

%% 增加文采
add_genius_by_id(Uid, Genius, Exp) ->  
	case misc:get_player_process(Uid) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'quiz_reward', Genius, Exp});
        _ ->
            void
    end.    
    
%% 初始玩家BUFF表
init_player_buff(PlayerId) ->
    NowTime = util:unixtime(),
    F = fun([Mid,Mpid,Mtype,Mgoods_id,Mattribut_id,Mvalue, Mend_time, Mscene]) ->
            case Mend_time > NowTime of
                true ->
                    BuffInfo = #ets_buff{ id = Mid, pid = Mpid, type = Mtype, goods_id = Mgoods_id, attribute_id = Mattribut_id, value = Mvalue, end_time = Mend_time, scene = lib_goods_util:to_term(Mscene) },
					case Mattribut_id of
						%% VIP祝福BUFF在后面判断
						18 -> skip;
						_ -> buff_dict:insert_buff(BuffInfo)
					end;
                false ->
                    del_buff(Mid)
            end
        end,
    Sql = io_lib:format(?sql_select_buff_all, [PlayerId]),
    case db:get_all(Sql) of
        [] -> [];
        BuffList when is_list(BuffList) ->
            lists:foreach(F, BuffList);
        _ -> []
    end.

%% 取玩家BUFF属性
%% @spec get_buff_attribute(PlayerId, Scene) -> 
%% [HpRatio, MpRatio, AttRatio, DefRatio, HitRatio, DodgeRatio, CritRatio, TenRatio, FireRatio, IceRatio, DrugRatio]
get_buff_attribute(PlayerId, Scene) ->
    L1 = get_player_buff(PlayerId, 2),
    L2 = get_player_buff(PlayerId, 5),
    L3 = get_player_buff(PlayerId, 6),
	L4 = get_player_buff(PlayerId, 7),
	L5 = get_player_buff(PlayerId, 97),	%% 变身buff检查
    BuffList = L1 ++ L2 ++ L3 ++ L4 ++ L5,
    case BuffList =:= [] of
        true -> [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        false ->
            NowTime = util:unixtime(),
            SceneId = Scene,
            data_goods:sum_effect([data_goods:get_effect2(BuffInfo#ets_buff.attribute_id, BuffInfo#ets_buff.value) ||
                BuffInfo <- BuffList, BuffInfo#ets_buff.end_time > NowTime, 
                BuffInfo#ets_buff.scene =:= [] orelse lists:member(SceneId, BuffInfo#ets_buff.scene)])
    end.

%% 取玩家BUFF列表
%% Type : 1 经验卡，2 BUFF符，3 宠物BUFF符  4烧酒  5喜宴  6攻城战属性符  7VIP祝福BUFF 97变身珠buff 98 器灵形象BUFF
get_player_buff(PlayerId, Type) ->
	buff_dict:match_two(PlayerId, Type).
    %ets:match_object(?ETS_BUFF, #ets_buff{ pid = PlayerId, type = Type, _='_'}).

get_player_buff(PlayerId, Type, AttributeId) ->
	buff_dict:match_three(PlayerId, Type, AttributeId).
    %ets:match_object(?ETS_BUFF, #ets_buff{pid = PlayerId, type = Type, attribute_id = AttributeId, _='_'}).

%% 添加BUFF状态
add_player_buff(PlayerId, Type, GoodsTypeId, AttributeId, Value, EndTime, Scene) ->
    %% 先判断是否已存在旧数据
    Sql1 = io_lib:format(<<"select id,pid,type,goods_id,attribute_id,value,end_time,scene from `buff` where pid = ~p and goods_id=~p and attribute_id=~p">>, [PlayerId, GoodsTypeId, AttributeId]),
    case db:get_all(Sql1) of
        [] ->
            Sql = io_lib:format(?sql_insert_buff, [PlayerId, Type, GoodsTypeId, AttributeId, Value, EndTime, util:term_to_string(Scene)]);            
        _ ->
            Sql = io_lib:format(?sql_update_buff, [GoodsTypeId, Value, EndTime, util:term_to_string(Scene), PlayerId])
    end,
    db:execute(Sql),
    Sql2 = io_lib:format(<<"select `id` from `buff` where `pid`=~p and `goods_id`=~p and `attribute_id`=~p">>, [PlayerId, GoodsTypeId, AttributeId]),
    BuffId = db:get_one(Sql2),
    %BuffId = db:get_one(<<"SELECT LAST_INSERT_ID() ">>),
    #ets_buff{id = BuffId, pid = PlayerId, type = Type, goods_id = GoodsTypeId, attribute_id = AttributeId, value = Value, end_time = EndTime, scene = Scene}.

%% 修改BUFF状态
mod_buff(BuffInfo, GoodsTypeId, Value, EndTime, Scene) ->
    Sql = io_lib:format(?sql_update_buff, [GoodsTypeId, Value, EndTime, util:term_to_string(Scene), BuffInfo#ets_buff.id]),
    db:execute(Sql),
    BuffInfo#ets_buff{goods_id = GoodsTypeId, value = Value, end_time = EndTime, scene = Scene}.

%% 删除BUFF状态
del_buff(Id) ->
    Sql = io_lib:format(?sql_delete_buff, [Id]),
    db:execute(Sql).

%% 删除玩家BUFF状态
del_player_buff(PlayerId) ->
	buff_dict:match_delete(PlayerId),
    Sql = io_lib:format(?sql_delete_player_buff, [PlayerId]),
    db:execute(Sql).

%% 删除玩家BUFF状态
del_player_buff(Status, BuffId) ->
    case lib_buff:lookup_id(Status#player_status.player_buff, BuffId) of
	%case buff_dict:lookup_id(BuffId) of
        %% 没有找到BUFF状态
        undefined -> {ok, Status};
        %% BUFF状态不属于你所有
        BuffInfo when BuffInfo#ets_buff.pid =/= Status#player_status.id ->
            {fail, 3};
        BuffInfo ->
            NowTime = util:unixtime(),
            %% VIP祝福可以随时冻结
            case (BuffInfo#ets_buff.attribute_id =:= 18) orelse (BuffInfo#ets_buff.end_time < NowTime) of
                %% BUFF状态还没有过期
                false ->
                    {fail, 4};
                true ->
                    del_buff(BuffId),
					buff_dict:delete_id(BuffId),
                    case BuffInfo#ets_buff.type of
                        %% BUFF符
                        2 ->
                            %% 属性变化
                            BuffAttribute = get_buff_attribute(Status#player_status.id, Status#player_status.scene),
                            NewStatus = count_player_attribute(Status#player_status{buff_attribute = BuffAttribute}),
                            %% 属性通知
                            send_attribute_change_notify(NewStatus, 0),
                            {ok, NewStatus};
                       %% 烧酒
%%                        4 ->
%%                            NewStatus = Status#player_status{winetype = 0},
%%                            lib_player:send_wine_buff_notice(NewStatus, 2, 0),
%%                            {ok, NewStatus};
                       %% 喜宴
                       5 ->
                            %% 属性变化
                            BuffAttribute = get_buff_attribute(Status#player_status.id, Status#player_status.scene),
                            NewStatus = count_player_attribute(Status#player_status{buff_attribute = BuffAttribute}),
                            %% 属性通知
                            send_attribute_change_notify(NewStatus, 0),
                            {ok, NewStatus};
                        %% 攻城战属性符
                       6 ->
                            %% 属性变化
                            BuffAttribute = get_buff_attribute(Status#player_status.id, Status#player_status.scene),
                            NewStatus = count_player_attribute(Status#player_status{buff_attribute = BuffAttribute}),
                            %% 属性通知
                            send_attribute_change_notify(NewStatus, 0),
                            {ok, NewStatus};
						7 ->
                            %% 属性变化
                            BuffAttribute = get_buff_attribute(Status#player_status.id, Status#player_status.scene),
                            NewStatus = count_player_attribute(Status#player_status{buff_attribute = BuffAttribute}),
                            %% 属性通知
                            send_attribute_change_notify(NewStatus, 0),
                            {ok, NewStatus};
						97 ->
                            %% 属性变化
                            BuffAttribute = get_buff_attribute(Status#player_status.id, Status#player_status.scene),
                            NewStatus = count_player_attribute(Status#player_status{buff_attribute = BuffAttribute}),
                            %% 属性通知
                            send_attribute_change_notify(NewStatus, 0),
                            {ok, NewStatus};
                        _ ->
                            {ok, Status}
                    end
            end
    end.

%% 检查玩家BUFF
check_player_buff(Status) ->
    case Status#player_status.player_buff of
	%case buff_dict:match_one(Status#player_status.id) of
        [] ->
          {ok, Status};
        BuffList ->
            NowTime = util:unixtime(),
            SceneId = Status#player_status.scene,
            NewBuffList = [BuffInfo || BuffInfo <- BuffList, BuffInfo#ets_buff.end_time > NowTime,
                                BuffInfo#ets_buff.scene =:= [] orelse lists:member(SceneId, BuffInfo#ets_buff.scene) ],
            lib_player:send_buff_notice(Status, NewBuffList),
            %% 属性变化
            BuffAttribute = lib_player:get_buff_attribute(Status#player_status.id, Status#player_status.scene),
            NewStatus = lib_player:count_player_attribute( Status#player_status{ buff_attribute = BuffAttribute } ),
            %% 属性通知
            lib_player:send_attribute_change_notify(NewStatus, 0),
            {ok, NewStatus}
    end.

%% 取玩家经验BUFF
get_exp_buff(PlayerStatus) ->
    case lib_buff:match_two2(PlayerStatus#player_status.player_buff, 60, []) of
	%case buff_dict:match_two2(PlayerId, 60) of
        [] -> 0;
        BuffList -> 
            [BuffInfo|_] = BuffList,
            BuffInfo#ets_buff.value
    end.

%% 攻城战胜利方经验BUFF
get_city_war_exp_buff(PlayerStatus) ->
    case lib_buff:match_two2(PlayerStatus#player_status.player_buff, 68, []) of
	%case buff_dict:match_two2(PlayerId, 68) of
        [] -> 0;
        _BuffList -> 1
    end.

%% 发送BUFF状态通知
send_buff_notice(Status, BuffList) ->
    {ok, BinData} = pt_130:write(13014, [Status#player_status.id, BuffList]),
    lib_server_send:send_to_uid(Status#player_status.id, BinData).

%%酒醉状态更改通知
send_wine_buff_notice(Status, Type, GoodsId) ->
    {ok, BinData} = pt_130:write(13021, [Type, GoodsId, Status#player_status.id]),
    lib_server_send:send_to_scene(Status#player_status.scene, Status#player_status.copy_id, BinData).

%%设置战斗分组(本方法不分线)（如竞技场中的红黄绿）
%%@param Id 玩家ID
%%@param Group 1红 2黄 3绿
%%@return void 无返回值
set_group(Id,Group)->
	case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {set_group,Group});
        _ ->
            void
    end.

%%更改角色PK状态(本方法不分线)
%%@param Id 玩家ID
%%@param Type 0和平 1全体 2国家 3帮派 4队伍 5善恶 6阵营(竞技场等特殊场景) 7幽灵(和平状态) 8帮战
%%@return->{Result, ErrorCode, NewType, LTime, NewStatus1}
%%         {ok, 0, Type, 0, NewStatus}
%%         {error,......}
change_pk_status(Id,Type)->
	case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:call(Pid, {change_pk_status,Type});
        _ ->
            {error, 9, Type, 0, #player_status{}}
    end.

%%更改角色PK状态(本方法不分线) (游戏线发起-公共线中再次需要调用游戏线方法时调用本方法)
%%@param Id 玩家ID
%%@param Type 0和平 1全体 2国家 3帮派 4队伍 5善恶 6阵营(竞技场等特殊场景) 7幽灵(和平状态)
change_pk_status_cast(Id,Type)->
	case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {change_pk_status,Type});
        _ ->
            void
    end.

%%更改角色PK状态
%%@param Status #player_status
%%@param Type 0和平 1全体 2国家 3帮派 4队伍 5善恶 6阵营(竞技场等特殊场景) 7幽灵(和平状态)
%%return->{ok, 0, Type}|{error, 1, Type}|{error, 2, Type}
change_pkstatus(Status, Type) ->
    case Status#player_status.change_scene_sign of
        %% 换线中，不允许切换PK模式
        1 -> {Result, ErrorCode, NewType, LTime, NewStatus1} = {error, 9, Type, 0, Status};
        _ ->
            NeedStatus = lib_scene:get_scene_pkstatus(Status#player_status.scene),
            Pk = Status#player_status.pk,
			if																  
                Pk#status_pk.pk_status =:= 6 %%竞技场
				  orelse Pk#status_pk.pk_status =:= 7 %%帮战幽灵
				  orelse Pk#status_pk.pk_status =:= 8 %%帮战
				  orelse (Pk#status_pk.pk_status =:= 9 andalso Status#player_status.scene /= 440) -> %%蟠桃园
                    %修改状态
                    NewStatus = Status#player_status{
                        pk=Pk#status_pk{
                            pk_status=Type, 
                            pk_status_change_time=util:unixtime(),
                            old_pk_status = Status#player_status.pk#status_pk.pk_status
                        }
                    },
                    mod_scene_agent:update(pk, NewStatus),
                    %通知场景的玩家
                    {ok, BinData} = pt_120:write(12084, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Type, Pk#status_pk.pk_value]),
                    lib_server_send:send_to_scene(Status#player_status.scene, Status#player_status.copy_id, BinData),
                    %每次更改PK状态保存一下坐标
                    lib_player:update_player_state2(Status),
                    {Result, ErrorCode, NewType, LTime, NewStatus1} = {ok, 0, Type, 0, NewStatus};
                true -> %其他类型
                    case NeedStatus > 0 of
                        true ->
                            {Result, ErrorCode, NewType, LTime, NewStatus1} = {error, 6, Type, 0, Status};
                        false ->
                            %护送中无法切换成和平状态
                            case lib_husong:husong_pk_check(Status) andalso Type =:= 0 of
                                true ->
                                    {Result, ErrorCode, NewType, LTime, NewStatus1} = {error, 5, Type, 0, Status};
                                false ->
                                    %% 红名状态无法切换
                                    case Status#player_status.pk#status_pk.pk_value > 200 andalso Type /=1 of
                                        true ->
                                            {Result, ErrorCode, NewType, LTime, NewStatus1} = {error, 4, Type, 0, Status};
                                        false ->
                                            %% 大闹天宫只允许队伍和全体PK模式
                                            WubianhaiSceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
                                            %% 爱情长跑场景只允许和平模式
                                            LoverunId = data_loverun:get_loverun_config(scene_id),
                                            ButterflySceneId = data_butterfly:get_sceneid(),
                                            HotsprintSceneId1 = data_hotspring:get_sceneid(pm),
                                            HotsprintSceneId2 = data_hotspring:get_sceneid(am),
											FishSceneId = data_fish:get_sceneid(),
                                            PeachId = data_peach:get_peach_config(scene_id),
											Kf3v3Ids = data_kf_3v3:get_config(scene_pk_ids),
											CantChangeSceneId = [LoverunId,ButterflySceneId,HotsprintSceneId1,HotsprintSceneId2,FishSceneId,PeachId] ++ Kf3v3Ids,
											CantChangeResult = lists:member(Status#player_status.scene, CantChangeSceneId),
                                            if
												Status#player_status.scene =:= WubianhaiSceneId ->
                                                    case Type =:= 1 orelse Type =:= 4 orelse Type =:= 3 of
                                                        true -> 
                                                            Now = util:unixtime(),
                                                            NewStatus = Status#player_status{
                                                                pk=Pk#status_pk{
                                                                    pk_status=Type, 
                                                                    pk_status_change_time=Now,
                                                                    old_pk_status = Status#player_status.pk#status_pk.pk_status
                                                                }
                                                            },
                                                            mod_scene_agent:update(pk, NewStatus),
                                                            %通知场景的玩家
                                                            {ok, BinData} = pt_120:write(12084, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Type, Pk#status_pk.pk_value]),
                                                            lib_server_send:send_to_scene(Status#player_status.scene, Status#player_status.copy_id, BinData),
                                                            %每次更改PK状态保存一下坐标
                                                            lib_player:update_player_state(Status),
                                                            {Result, ErrorCode, NewType, LTime, NewStatus1} = {ok, 0, Type, 0, NewStatus};
                                                        false ->
                                                            {Result, ErrorCode, NewType, LTime, NewStatus1} = {error, 8, Type, 0, Status}
                                                    end;
												
												%% 不能修改pk状态
												CantChangeResult =:= true ->
                                                    {Result, ErrorCode, NewType, LTime, NewStatus1} = {error, 8, Type, 0, Status};

												%% 其他场景
                                                true ->
                                                    %新手保护
                                                    case Status#player_status.lv < 30 of
                                                        true ->
                                                            {Result, ErrorCode, NewType, LTime, NewStatus1} = {error, 3, Type, 0, Status};
                                                        _ ->
                                                            case Type =:= Pk#status_pk.pk_status of
                                                                true ->
                                                                    {Result, ErrorCode, NewType, LTime, NewStatus1} = {error, 1, Type, 0, Status};
                                                                false ->
                                                                    Now = util:unixtime(),
                                                                    Far_time = Now - Pk#status_pk.pk_status_change_time,
                                                                    case Type =:= 0 of
                                                                        true ->
                                                                            PkChangeTime = ?PK_CHANGE_TIME,
                                                                            case Far_time >= PkChangeTime orelse Type=:=7 of
                                                                                true ->
                                                                                    %修改状态
                                                                                    NewStatus = Status#player_status{
                                                                                        pk=Pk#status_pk{
                                                                                            pk_status=Type, 
                                                                                            pk_status_change_time=Now,
                                                                                            old_pk_status = Status#player_status.pk#status_pk.pk_status
                                                                                        }
                                                                                    },
                                                                                    mod_scene_agent:update(pk, NewStatus),
                                                                                    %通知场景的玩家
                                                                                    {ok, BinData} = pt_120:write(12084, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Type, Pk#status_pk.pk_value]),
                                                                                    lib_server_send:send_to_scene(Status#player_status.scene, Status#player_status.copy_id, BinData),

                                                                                    %每次更改PK状态保存一下坐标
                                                                                    lib_player:update_player_state(Status),
                                                                                    {Result, ErrorCode, NewType, LTime, NewStatus1} = {ok, 0, Type, 0, NewStatus};
                                                                                _ ->
                                                                                    LeftTime = PkChangeTime - Far_time,
                                                                                    {Result, ErrorCode, NewType, LTime, NewStatus1} = {error, 2, Type, LeftTime, Status}
                                                                            end;
                                                                        false ->
                                                                            %修改状态:罪恶切换不记录时间
                                                                            case Pk#status_pk.pk_status > 0 of
                                                                                true ->
                                                                                    NewStatus = Status#player_status{
                                                                                        pk=Pk#status_pk{
                                                                                            pk_status=Type,
                                                                                            old_pk_status = Status#player_status.pk#status_pk.pk_status
                                                                                        }
                                                                                    };
                                                                                false ->
                                                                                    NewStatus = Status#player_status{
                                                                                        pk=Pk#status_pk{
                                                                                            pk_status=Type, 
                                                                                            pk_status_change_time=Now,
                                                                                            old_pk_status = Status#player_status.pk#status_pk.pk_status
                                                                                        }
                                                                                    }
                                                                            end,
                                                                            mod_scene_agent:update(pk, NewStatus),
                                                                            %通知场景的玩家
                                                                            {ok, BinData} = pt_120:write(12084, [Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Type,  Pk#status_pk.pk_value]),
                                                                            lib_server_send:send_to_scene(Status#player_status.scene, Status#player_status.copy_id, BinData),
                                                                            lib_player:update_player_state(Status),
                                                                            {Result, ErrorCode, NewType, LTime, NewStatus1} = {ok, 0, Type, 0, NewStatus}
                                                                    end
                                                            end
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end,
    %通知本人
    {ok, BinData1} = pt_130:write(13012, [ErrorCode,NewType, LTime]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData1),
    {Result, ErrorCode, NewType, LTime, NewStatus1}.

%% 计算人物速度
count_player_speed(PlayerStatus) ->
    Mou = PlayerStatus#player_status.mount,
    %% 基础速度
    Speed = PlayerStatus#player_status.base_speed,
    %% 坐骑速度
    Speed1 = Mou#status_mount.mount_speed,
    %% 飞行坐骑速度
    FlyMountSpeed = Mou#status_mount.fly_mount_speed,
    %% 飞行器速度
    FlyerSpeed = PlayerStatus#player_status.flyer_attr#status_flyer.speed,
    %% 勋章铸魂技能加成
%%     MedalSpeed = lib_kfz_medal_soul:get_medal_speed(PlayerStatus),
    %% 护送速度
    Hs = PlayerStatus#player_status.husong,
    [_, HusongSpeed] = Hs#status_husong.hs_buff2,
    %% ====汇总===
    NewSpeed = round((Speed + Speed1+FlyMountSpeed+FlyerSpeed)*HusongSpeed),
    PlayerStatus#player_status{speed = NewSpeed}.

%% 增加任务物品
add_task_award(R) ->
	db:execute(
		io_lib:format(
			<<"update `player_pt` set `llpt` = ~p, `xwpt` = ~p, `fbpt` = ~p, `fbpt2` = ~p, `bppt`=~p, `gjpt` = ~p where id = ~p ">>,
			[R#player_status.llpt, R#player_status.xwpt, R#player_status.fbpt, R#player_status.fbpt2, R#player_status.bppt, R#player_status.gjpt, R#player_status.id]
		)
	),
	db:execute(
		io_lib:format(
			<<"update `player_high` set `coin`=~p, `bcoin`=~p where id = ~p ">>,
			[R#player_status.coin, R#player_status.bcoin, R#player_status.id]
		)
	),
	%% 名人堂：如日中天，第一个国家声望达到1000
	mod_fame:trigger(R#player_status.mergetime, R#player_status.id, 2, 0, R#player_status.gjpt),
	%% 成就：奉旨杀人，国家声望达到N点
	mod_achieve:trigger_role(R#player_status.achieve, R#player_status.id, 5, 0, R#player_status.gjpt).

%% 玩家死亡处理
%% Status :当前自己的进程状态
%% AtterSign :杀人者类型 1怪, 2人
%% Atter     :杀人者信息 #battle_return_atter{}
%% HitList   :助攻列表
player_die(Status, AtterSign, Atter, HitList) -> 

    #battle_return_atter{
        id         = NewAttId, 
        platform   = Platform, 
        server_num = ServerNum, 
        pid        = NewAttPid} = Atter,

    KillerKey = [NewAttId, Platform, ServerNum],

    %% 修正速度
    lib_scene:change_speed(Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y, Status#player_status.speed, 2),

    %% 对杀人者(怪或者人)分别处理
	CalcKillTypeStatus = case AtterSign == 2 of
		true ->
			%% 如果玩家杀加入仇人
			case catch gen:call(NewAttPid, '$gen_call', 'base_data') of
				{'EXIT', _} ->
					Status;
				{ok, Player} ->
					HitKeyList = lists:keydelete(KillerKey, 1, HitList),
					HitIdList = [{HitId,Time}||{[HitId, _, _], Time}<-HitKeyList],
					%%设置竞技场积分
					Arena_scene_id = data_arena_new:get_arena_config(scene_id),
					if
						Player#player_status.scene=:=Arena_scene_id andalso Status#player_status.scene=:=Arena_scene_id->
							%% 杀人获得活跃度
							mod_active:trigger(Player#player_status.status_active, 5, 0, Player#player_status.vip#status_vip.vip_type),
							lib_arena_new:set_score_by_kill_player(Player#player_status.id,Status#player_status.id, HitIdList),
							%% 成就：刀剑无眼：在竞技场累积死亡N次
							mod_achieve:trigger_hidden(Status#player_status.achieve, Status#player_status.id, 4, 0, 1),
							%% 杀生成仁：竞技场累积杀N人。每次杀人调一次
							mod_achieve:trigger_trial(Player#player_status.achieve, Player#player_status.id, 31, 0, 1);
						true->void	
					end,

					%%设置帮战
					Factionwar_Scene_id = data_factionwar:get_factionwar_config(scene_id),
					FacStatus = if
						Player#player_status.scene=:=Factionwar_Scene_id andalso Status#player_status.scene=:=Factionwar_Scene_id->
							%% 杀人获得活跃度
							mod_active:trigger(Player#player_status.status_active, 5, 0, Player#player_status.vip#status_vip.vip_type),
							lib_factionwar:set_score_by_kill_player(Player#player_status.id,Status#player_status.id,
																	Player#player_status.achieve,Status#player_status.achieve,
																	HitIdList),
							%% 成就：帮主，他打我：帮派战累积死亡N次
							mod_achieve:trigger_hidden(Status#player_status.achieve, Status#player_status.id, 5, 0, 1),
			                            %% 帮派水晶
			                            %% 杀人者抢到水晶
			                            if
			                                Status#player_status.factionwar_stone > 0 andalso Status#player_status.factionwar_stone < 11 -> 
			                                    gen_server:cast(NewAttPid, {'factionwar_stone', Status#player_status.factionwar_stone}),
			                                    lib_factionwar:del_stone(Status, 2);
			                                true -> Status
			                            end;
						true-> Status	
					end,

					%%设置蟠桃园
					Peach_Scene_id = data_peach:get_peach_config(scene_id),
					if
						Player#player_status.scene=:=Peach_Scene_id andalso Status#player_status.scene=:=Peach_Scene_id->
							%% 杀人获得活跃度
							mod_active:trigger(Player#player_status.status_active, 5, 0, Player#player_status.vip#status_vip.vip_type),
							lib_peach:set_score_by_kill_player(Player#player_status.id,Status#player_status.id);
						true->void	
					end,

					%%设置1v1
					Kf_1v1_Scene_id = data_kf_1v1:get_bd_1v1_config(scene_id2),
					if
						Player#player_status.scene=:=Kf_1v1_Scene_id andalso Status#player_status.scene=:=Kf_1v1_Scene_id->
							lib_kf_1v1:when_kill(Player#player_status.platform,
												 Player#player_status.server_num,
												 Player#player_status.id,
												 Player#player_status.combat_power,
												 Player#player_status.hp,
												 Player#player_status.hp_lim,
												 Status#player_status.platform,
												 Status#player_status.server_num,
												 Status#player_status.id,
												 Status#player_status.combat_power,
												 Status#player_status.hp,
												 Status#player_status.hp_lim);
						true->void	
					end,

					%%设置诸神
					God_Scene_id_flag1 = lists:member(Player#player_status.scene, data_god:get(scene_id2)),
					God_Scene_id_flag2 = lists:member(Status#player_status.scene, data_god:get(scene_id2)),
					if
						God_Scene_id_flag1=:=true andalso God_Scene_id_flag2=:=true->
							mod_clusters_node:apply_cast(mod_god,when_kill,
												[Player#player_status.platform,
												 Player#player_status.server_num,
												 Player#player_status.id,
												 Status#player_status.platform,
												 Status#player_status.server_num,
												 Status#player_status.id]);
						true->void	
					end,

                    %% 竞技场 帮战 大闹天宫 监狱 VIP挂机中屏蔽掉杀人传闻
					Wubianhai_SceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
                    VipScene = data_vip_new:get_config(scene_id),
                    VipScene2 = data_vip_new:get_config(scene_id2),
                    CityWarSceneId = data_city_war:get_city_war_config(scene_id),
                    %% 需要屏蔽掉杀戮传闻的场景，都加在下面的列表中
                    AbSceneList = [Arena_scene_id, Factionwar_Scene_id, Peach_Scene_id,Kf_1v1_Scene_id,Wubianhai_SceneId, 998, VipScene, VipScene2, CityWarSceneId],
                    AbRes = (God_Scene_id_flag1 andalso God_Scene_id_flag2) 
						    orelse (lists:member(Player#player_status.scene, AbSceneList) =:= true andalso lists:member(Status#player_status.scene, AbSceneList) =:= true),
                    if
                        AbRes =:= true ->
                            skip;
                        true->
                            %% 加入好友仇人名单
                            lib_relationship:add_enemy(Status#player_status.pid, Status#player_status.id, Player#player_status.id),
                            lib_relationship:update_rela_killed_times(Status#player_status.pid, Status#player_status.id, Player#player_status.id),
                            lib_relationship:update_rela_hatred_value(Player#player_status.pid, Player#player_status.id, Status#player_status.id, minus), %杀人者对被杀者的仇恨值减1

                            %% 发送被杀传闻，先发送最高战力被杀传闻，如果发送失败，再发送普通玩家被杀传闻
                            case lib_rank:power_top_killed_cw(Status#player_status.id, Status#player_status.career, [Player#player_status.id, Player#player_status.realm, Player#player_status.nickname, Player#player_status.sex, Player#player_status.career, Player#player_status.scene, Player#player_status.x, Player#player_status.y]) of
                                true ->
                                    skip;
                                _ ->
                                    lib_chat:send_TV({realm,Player#player_status.realm},0, 2, ["yewaiPK", 1, Player#player_status.id, Player#player_status.realm, Player#player_status.nickname, Player#player_status.sex, Player#player_status.career, Player#player_status.image, Status#player_status.id, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image, Status#player_status.scene, Status#player_status.x, Status#player_status.y]),
                                    if
                                        Player#player_status.realm /= Status#player_status.realm ->
                                            lib_chat:send_TV({realm,Status#player_status.realm},0, 2, ["yewaiPK", 1, Player#player_status.id, Player#player_status.realm, Player#player_status.nickname, Player#player_status.sex, Player#player_status.career, Player#player_status.image, Status#player_status.id, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image, Status#player_status.scene, Status#player_status.x, Status#player_status.y]);
                                        true ->
                                            skip
                                    end
                            end,

                            case is_screen(Status, 1) of %% 是否被屏蔽了杀戮邮件
                                true -> skip;
                                false -> 
                                    [Title, Format] = data_cw_text:get_kill_text(),
                                    Content = io_lib:format(Format, [data_cw_text:get_realm_name(Player#player_status.realm), Player#player_status.nickname]),
                                    mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.id],Title,Content,0,0,0,0,0,0,0,0,0])
                            end
                    end, 
                    PsHsOk = case FacStatus#player_status.husong#status_husong.husong > 0 of
                        true ->
                            case lib_husong:husong_terminate(FacStatus, Player) of
                                {ok, SelfHs} when is_record(SelfHs, player_status) ->
                                    SelfHs;
                                _ ->
                                    FacStatus
                            end;
                        false ->
                            FacStatus
                    end,
                    %% 大闹天宫：击杀者得到被杀者物品
                    WbhScene_id = data_wubianhai_new:get_wubianhai_config(scene_id),
                    case Player#player_status.scene =:= Status#player_status.scene andalso Status#player_status.scene =:= WbhScene_id of
                        true ->
                            lib_wubianhai_new:kill_player(Player, Status);
                        false -> skip
                    end,
                    %% 攻城战杀戮处理
                    case Status#player_status.scene =:= CityWarSceneId of
                        true ->
                            lib_city_war:kill_deal(Player, Status, HitList);
                        false -> skip
                    end,
					%% 记录玩家今日杀人数
					mod_daily_dict:increment(Player#player_status.id, 9000001),
					%% 在野外等地方杀人可获得国家声望
					PlayerScene = lib_scene:get_data(Player#player_status.scene),
					GJPTSceneTypes = [?SCENE_TYPE_NORMAL, ?SCENE_TYPE_OUTSIDE],
					case is_record(PlayerScene, ets_scene) andalso lists:member(PlayerScene#ets_scene.type, GJPTSceneTypes) of
						true ->
                            NewStatusPk = Status#player_status.pk,
                            %% 判断是否杀死同阵营
                            case Status#player_status.realm =:= Player#player_status.realm of
                                true -> %杀死同阵营玩家
                                    %% 红名玩家死亡
                                    case NewStatusPk#status_pk.pk_value > 200 of
                                        %% 红名玩家扣钱
                                        true -> 
                                            %io:format("2~n"),
                                            update_player_info(Status#player_status.id, [{cost_red_name, 25000}]);
                                        %% 杀死同阵营非红名玩家，扣声望加罪恶值
                                        false -> 
                                            gen_server:cast(Player#player_status.pid, {'set_data', [{minus_gjpt, Player#player_status.gjpt div 20}]}),
                                            add_pk_value(Player, 100)
                                    end;
                                false -> %杀死其他阵营玩家
                                    %% 红名玩家死亡
                                    case NewStatusPk#status_pk.pk_value > 200 of
                                        %% 红名玩家扣钱
                                        true -> 
                                            %io:format("4~n"),
                                            update_player_info(Status#player_status.id, [{cost_red_name, 25000}]);
                                        false -> skip
                                    end,
                                    %% 等级差距是否大于等于10
                                    case Player#player_status.lv - Status#player_status.lv >= 10 of
                                        true -> 
                                            gen_server:cast(Status#player_status.pid, {'set_data', [{minus_gjpt, Status#player_status.gjpt div 20}]});
                                        false -> 
                                            gen_server:cast(Status#player_status.pid, {'set_data', [{minus_gjpt, Status#player_status.gjpt div 10}]}),
                                            %% 30分钟内击杀同一名其他阵营玩家也将不能获得阵营声望奖励
                                            case util:unixtime() - mod_gjpt:lookup_last_kill_time(Player#player_status.id, Status#player_status.id) >= 30 * 60 of
                                                true -> 
                                                    gen_server:cast(Player#player_status.pid, {'set_data', [{add_gjpt, Status#player_status.gjpt div 10}]});
                                                false -> 
                                                    skip
                                            end
                                    end,
                                    %% 记录杀人时间
                                    mod_gjpt:insert_last_kill_time(Player#player_status.id, Status#player_status.id, util:unixtime())
                            end,

							%% 成就：地上很凉，累积被杀死亡N次
							mod_achieve:trigger_hidden(Status#player_status.achieve, Status#player_status.id, 6, 0, 1);
						_ ->
							skip
					end,
                    %% 杀异阵玩家任务
                    %% 只能在BOSS场景、安全场景和野外场景杀人才有效
                    PlayerScene2 = lib_scene:get_data(Player#player_status.scene),
                    GJPTSceneTypes2 = [?SCENE_TYPE_NORMAL, ?SCENE_TYPE_OUTSIDE, ?SCENE_TYPE_BOSS],
                    case is_record(PlayerScene2, ets_scene) andalso lists:member(PlayerScene2#ets_scene.type, GJPTSceneTypes2) of
                        true ->
                            case Status#player_status.realm /= Player#player_status.realm  of
                                true -> 
                                    lib_task:event(Player#player_status.tid, kill, 0, Player#player_status.id);
                                false -> 
                                    skip
                            end;
                        false -> skip
                    end,

                    %% @retrun
                    PsHsOk
            end;
        false ->
			%%终止竞技场连斩
			lib_arena_new:stop_continuous_kill_by_numen_kill(AtterSign,Status#player_status.id),
            %% 攻城战中死亡
            CityWarSceneId = data_city_war:get_city_war_config(scene_id),
            case Status#player_status.scene of
                CityWarSceneId ->
                    lib_city_war:killed_by_mon(Status);
                _ ->
                    skip
            end,
            %% 副本中死亡
            lib_dungeon:player_die(Status),
            Status
    end,

    %% 修正形象  
    FixFigureStatus = lib_figure:player_die(CalcKillTypeStatus),

    %% 中断多段技能
    InSkillStatus   = lib_skill:interrupt_combo_skill(FixFigureStatus),

    %% @retrun
    InSkillStatus.

%% ----------------------------------快捷栏------------------------------------------

%%删除指定位置的快捷栏
save_quickbar([T, S, Id], Q) ->
    case lists:keyfind(T, 1, Q) of
        false ->
            [{T, S, Id} | Q];
        _ -> 
            Q1 = lists:keydelete(T, 1, Q),
            [{T, S, Id} | Q1]
    end.

%%删除指定位置的快捷栏
delete_quickbar(T, Q) ->
    case lists:keyfind(T, 1, Q) of
        false ->
            Q;
        _ ->
            lists:keydelete(T, 1, Q)
    end.

%%删除指定位置的快捷栏
replace_quickbar(T1, T2,  Q) ->
    case lists:keyfind(T1, 1, Q) of
        false -> %T1没有物品
            Q;
        {_ , S1, Id1} ->
            Q1 = lists:keydelete(T2, 1, Q),
            Q2 = lists:keydelete(T1, 1, Q1),
            case lists:keyfind(T2, 1, Q) of
                false -> %T2没有物品
                    [{T2, S1, Id1} | Q2];
                {_, S2, Id2} ->
                    [{T2, S1, Id1}, {T1, S2, Id2} | Q2]
            end
    end.
%% ------------------------------------快捷栏结束------------------------------


%% 获用户信息
get_pid_by_id(Id) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            Pid;
        _ ->
            false
    end.

%% 更新公共线的ets_unite数据
%% UnitePid:公共线用户pid
%% AttrKeyValueList:需要更新的列表[{sex, 1}, {name, Name}]
update_unite_info(UnitePid, AttrKeyValueList) ->
    case is_pid(UnitePid) of
        true ->
            gen_server:cast(UnitePid, {'set_data', AttrKeyValueList});
        false ->
            skip
    end.

%% 删除VIP祝福的BUFF
delete_ets_buff(Id) ->
    delete_buff(buff_dict:get_all(), Id).

%% VIP祝福的属性ID为18
delete_buff([], _Id) -> skip;
delete_buff([BuffInfo | T], Id) ->
	case Id =:= BuffInfo#ets_buff.pid of
        false -> skip;
		true -> buff_dict:delete_id(BuffInfo#ets_buff.id)
    end,
    delete_buff(T, Id).

%% 技能属性更新
update_anger(Status) ->
    {ok, BinData} = pt_130:write(13033, [
            Status#player_status.hp,
            Status#player_status.hp_lim,
            Status#player_status.att,
            Status#player_status.def,
            Status#player_status.hit,
            Status#player_status.dodge,
            Status#player_status.crit,
            Status#player_status.fire,
            Status#player_status.ice,
            Status#player_status.drug,
            Status#player_status.anger,
            Status#player_status.anger_lim]),
    lib_server_send:send_to_sid(Status#player_status.sid, BinData).
    
%% 获取在线时长(双线可以用)
get_online_time(PlayerStatus) when is_record(PlayerStatus, player_status)->
	TimeLastLogout = mod_daily_dict:get_count(PlayerStatus#player_status.id, 9000002),		%% 上次离线时候已经统计的在线时长
	LastLoginTime = PlayerStatus#player_status.last_login_time, %% 本次离线时候已经统计的在线时长
	TimeNow = util:unixtime(),
	Time = (TimeNow - LastLoginTime) + TimeLastLogout,
	case Time < 0 of
		true -> 0;
		_ -> Time
	end;
get_online_time(UniteStatus) when is_record(UniteStatus, unite_status)->
	TimeLastLogout = mod_daily_dict:get_count(UniteStatus#unite_status.id, 9000002),		%% 上次离线时候已经统计的在线时长
	LastLoginTime = UniteStatus#unite_status.last_login_time, %% 本次离线时候已经统计的在线时长
	TimeNow = util:unixtime(),
	Time = (TimeNow - LastLoginTime) + TimeLastLogout,
	case Time < 0 of
		true -> 0;
		_ -> Time
	end;
get_online_time(_)->
	0.

%% 取得当天在线时长（秒），过了当天0点，重新计算时长
%% LastLoginTime : 玩家最后一次登录时间戳
get_online_time_today(RoleId, LastLoginTime) ->
	NowTime = util:unixtime(),
	NowDay = util:unixdate(NowTime),
	OnlineTime = case LastLoginTime < NowDay of
		true -> NowTime - NowDay;
		_ -> NowTime - LastLoginTime
	end,
	%% 当天已经在线时长
	TodayKeepTime = mod_daily_dict:get_count(RoleId, 9000003) + OnlineTime,
	case TodayKeepTime < 0 of
		true -> 0;
		_ -> TodayKeepTime
	end.

%% 世界等级（玩家进程内使用）
get_world_lv_from_unite() -> 
    case get(player_status_world_lv) of
        undefined -> 
            case catch mod_disperse:call_to_unite(mod_rank,get_average_level, []) of
                AverageLevel when is_integer(AverageLevel)-> 
                    put(player_status_world_lv, AverageLevel), 
                    AverageLevel;
                _Other -> 30
            end;
        WorldLv -> WorldLv
    end.

%% 世界等级
%% 1.公共线 0.游戏线
world_lv(Type) ->
    case Type of
        1 ->
            get_world_lv();
        _ ->
            mod_disperse:call_to_unite(lib_player, get_world_lv, [])
    end.

get_world_lv() ->
    %% 世界等级
    WorldLv = case mod_rank:get_average_level() of
        0 -> 
            %% 取第50名玩家等级
            case db:get_row(<<"select `lv` from `player_low` order by `lv` desc limit 50,1 ">>) of
                [] -> data_wubianhai_new:get_wubianhai_config(average_level);
                [PlayerLv] when is_number(PlayerLv) ->
                    case PlayerLv < data_wubianhai_new:get_wubianhai_config(average_level) of
                        true -> data_wubianhai_new:get_wubianhai_config(average_level);
                        false -> PlayerLv
                    end;
                _ -> data_wubianhai_new:get_wubianhai_config(average_level)
            end;
        AVLv -> 
            case AVLv < data_wubianhai_new:get_wubianhai_config(average_level) of
                true -> data_wubianhai_new:get_wubianhai_config(average_level);
                false -> AVLv
            end
    end,
    WorldLv.

%% 增加hp -> true|false
add_hp(Pid, V) when is_pid(Pid)-> 
    Pid ! {last_back_hp, V},
    true;
add_hp(Id, V) -> 
    case get_player_info(Id, pid) of
        false -> false;
        Pid -> 
            Pid ! {last_back_hp, V},
            true
    end.

%% 获取玩家头像信息
get_player_image_data(Status) ->
	%% 普通头像
	Normal_image = data_image:normal_image_config(Status#player_status.lv),
	%% 特殊头像
	F = fun(ImageId) ->
			case lists:member(ImageId, Status#player_status.special_image) of
				true ->
					{ImageId, 1};
				false ->
					{ImageId, 0}
			end
		end,	
	Special_image = lists:map(F, data_image:all_image(2)),
    Xianyuan_pid = Status#player_status.player_xianyuan,
	Player_xianyuan = mod_xianyuan:getPlayer_xianyuan(Xianyuan_pid),
	Xian_yuan_lv = lib_xianyuan:get_xianyuan_level(Player_xianyuan, 1, 10), 
	%% 仙侣头像
	XianlvImage = data_image:xianlv_image_config(Xian_yuan_lv),
	%% 剩余切换次数
	Daily_num_config = data_image:image_config(dialy_num),
	Daily_num = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5700),
	LeftNum = Daily_num_config - Daily_num,
	[Normal_image, Special_image, XianlvImage, LeftNum].

%% 切换玩家头像
change_player_image(Status, ImageId, ImageType) ->	
	case  lists:member(ImageId, data_image:all_image(ImageType)) of
		true ->
			case ImageType of
				1 ->
					NormalImage = data_image:normal_image_config(Status#player_status.lv),					
					case  lists:keyfind(ImageId, 1, NormalImage) of
						{_, State} ->
							case State of
								1 -> ReturnCode = private_change_image(Status, ImageId);
								0 -> ReturnCode =2	 %% 暂未激活
							end;
					   _ -> ReturnCode =2
					end;
				2 -> 
					case lists:member(ImageId, Status#player_status.special_image) of 
						true ->ReturnCode = private_change_image(Status, ImageId);
						false -> ReturnCode =2	%% 暂未激活
					end;
				3 -> 
					Xianyuan_pid = Status#player_status.player_xianyuan,
					Player_xianyuan = mod_xianyuan:getPlayer_xianyuan(Xianyuan_pid),
					Xian_yuan_lv = lib_xianyuan:get_xianyuan_level(Player_xianyuan, 1, 10), 					
					XianlvImage = data_image:xianlv_image_config(Xian_yuan_lv),					
					case lists:keyfind(ImageId, 1, XianlvImage) of
						{_, State} ->							
							case State of
								1 -> ReturnCode = private_change_image(Status, ImageId);
								0 -> ReturnCode =2	%% 暂未激活
							end;
						_ -> ReturnCode =2	
					end
			end;
		false -> %% 该头像暂未开启
			ReturnCode =5
	end,
	ReturnCode.

private_change_image(Status, ImageId) ->
	Daily_num_config = data_image:image_config(dialy_num),
	Daily_num = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, 5700),				
	case Daily_num< Daily_num_config of
		true ->
			Daily_reflesh_time = mod_daily:get_refresh_time(Status#player_status.dailypid, Status#player_status.id, 5700),
			Refresh_cd = data_image:image_config(refresh_cd),
			NowTime = util:unixtime(),
			case NowTime>Daily_reflesh_time+Refresh_cd of
				true ->
					SQL = <<"update player_low set image=~p where id = ~p">>,
					SQL_Format = io_lib:format(SQL, [ImageId, Status#player_status.id]),
					db:execute(SQL_Format),
					mod_daily:increment(Status#player_status.dailypid,Status#player_status.id, 5700),
					ReturnCode =0;   %% 需要改变PS 	
				false -> %% 处于cd时间
					ReturnCode =4
			end;
		false -> %% 今日使用次数已满
			ReturnCode =3
	end,
	ReturnCode.

%% 激活特殊头像
activate_player_image(Status, ImageId) ->
	case  lists:member(ImageId, data_image:all_image(2)) of
		true ->
			case lists:member(ImageId, Status#player_status.special_image)	of
				false ->
					PlayerGoods = Status#player_status.goods,
					GoodsTypeId = data_image:image_config(image_goods_id),			
					case gen_server:call(PlayerGoods#status_goods.goods_pid,{'delete_more', GoodsTypeId, 1}) of
						1 ->
							log:log_goods_use(Status#player_status.id, GoodsTypeId, 1),	
							SQL = <<"replace into player_image(player_id, image_id) values(~p,~p)">>,							
							SQL_Format = io_lib:format(SQL, [Status#player_status.id, ImageId]),
							db:execute(SQL_Format),
							ReturnCode =0;
						2 -> 
							ReturnCode =1;
						3 ->
							%% 物品数量不足
							ReturnCode =1;
						_Other ->
							%% 扣除失败
							ReturnCode =2
					end;
				true -> %% 该头像已激活
					ReturnCode =4
			end;
		false -> %% 该头像暂未开启
			ReturnCode =3
	end,
	ReturnCode.		

%% 加载玩家特殊头像
load_player_image(Status)->
	SQL = <<"select  image_id from player_image where player_id=~p">>,							
	SQL_Format = io_lib:format(SQL, [Status#player_status.id]),	
	ImageList = db:get_all(SQL_Format),
	case ImageList of
		[] ->  ImageList2 = [];
		Other ->  
			F = fun([Image]) ->
				Image
			end,
			ImageList2 = lists:map(F, Other)
	end,
    Status#player_status{special_image= ImageList2}.

%% 获取player_low表中玩家头像
get_player_normal_image(Id) ->
   Result =  db:get_row(io_lib:format(?select_player_low_image, [Id])),
   case Result of
	   [] -> 0;
	   [ResultCode] -> ResultCode
   end.

%% 获取玩家最后登录时间
get_player_last_login_time(Id) ->
	Time = util:unixtime(),
	_Pre_loginTime = db:get_one(io_lib:format(?sql_player_last_login_time, [Id])),
	case _Pre_loginTime =:= null orelse _Pre_loginTime=:=0 of
		true -> Pre_loginTime = Time;
		false -> Pre_loginTime = _Pre_loginTime
	end,
	Pre_loginTime.

%% 记录用户上一次登录时间
note_pre_loginTime(Id) ->	
	Pre_loginTime = get_player_last_login_time(Id),
	mod_activity_festival:set_pre_loginTime(Id, Pre_loginTime).

%% 计算玩家历史最高战斗力
count_hightest_combat_power(Status) ->
	case get(hightest_combat_power) of
		undefined ->
			Hightest_combat_power = db:get_one(io_lib:format(?sql_select_hightest_combat_power, [Status#player_status.id]));
		_Other -> Hightest_combat_power = _Other
	end,
	Now_combat_power = Status#player_status.combat_power,
	PowerGap = Hightest_combat_power - Now_combat_power,
	if
		 PowerGap <0  ->
			private_update_hightest_combat_power(Status, Now_combat_power);
		 PowerGap >0, PowerGap<100 ->
			 private_update_hightest_combat_power(Status, Now_combat_power);
		 true ->
			 case get(hightest_combat_power) of
				 undefined -> put(hightest_combat_power, Now_combat_power);					
				 _ -> skip
			 end,
			 Status
	end.

private_update_hightest_combat_power(Status, Now_combat_power) ->
	Sql = io_lib:format(?sql_update_hightest_combat_power, [Now_combat_power, Status#player_status.id]),
	db:execute(Sql),
	put(hightest_combat_power, Now_combat_power),
	Status#player_status{hightest_combat_power = Now_combat_power}.


%% @spec set_sys_conf(SetList, OldList) -> NewList
%% 设置屏蔽内容
%% SetList = OldList = NewList = list() = [{SubType, Value},...]
%%     SubType = int() = 1 杀戮邮件 | ...
%%     Value = int() = 1 屏蔽|0 不屏蔽
%% @end
set_sys_conf([], NewSysConf) -> NewSysConf;
set_sys_conf([{SubType, Value}|T], OldSysConf) when SubType < 10, SubType > 0 ->
    case lists:keyfind(SubType, 1, OldSysConf) of
        {_, _} -> 
            if 
                Value == 0 -> 
                    NewSysConf = lists:keydelete(SubType, 1, OldSysConf),
                    set_sys_conf(T, NewSysConf);
                true -> 
                    NewSysConf = [{SubType, Value}|lists:keydelete(SubType, 1, OldSysConf)],
                    set_sys_conf(T, NewSysConf)
            end;
        false -> 
            set_sys_conf(T, [{SubType, Value}|OldSysConf])
    end;
set_sys_conf([_H|T], OldSysConf) -> set_sys_conf(T, OldSysConf).

%% @spec is_screen(Status, Type) -> true | false
%% 按类型查看玩家是否屏蔽了某功能
%% Status = #player_status{} = 玩家状态
%% Type   = int() = 屏蔽类型 = 1:杀戮邮件 | ...
%% @end
is_screen(#player_status{sys_conf = SysConf} = _Status, Type) ->
    case lists:keyfind(Type, 1, SysConf) of
        false -> false;
        {_, Value} -> Value == 1
    end.
