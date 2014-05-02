%% Author: Administrator
%% Created: 2012-9-9
%% Description: TODO: Add description to lib_peach
-module(lib_peach).
-include("server.hrl").
-include("unite.hrl").
-include("peach.hrl").
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([
	 load_player_peach/1,
	 login_out_peach/1,
	 execute_48101/1,
	 execute_48102/1,
	 execute_48103/2,
	 execute_48104/1,
	 execute_48105/1,
	 execute_48109/1,
	 execute_48110/1,
	 set_score_by_kill_player/2,
	 set_score_by_kill_npc/2,
	 update_player_peach/2,
	 server_send_mail/1
]).

%%
%% API Functions
%%
%% 加载玩家蟠桃数据
load_player_peach(Uid)->
	SQL = io_lib:format(<<"select * from player_peach where id=~p">>, [Uid]),
	case db:get_row(SQL) of
		[]->#status_peach{};
		L->list_to_tuple([status_peach|L])
	end.

%%登陆时踢出蟠桃园
%%@param PlayerStatus 玩家状态
%%@return NewPlayerStatus
login_out_peach(PlayerStates)->
	Peach_Scene_Id = data_peach:get_peach_config(scene_id),
	[SceneId,X,Y] = data_peach:get_peach_config(leave_scene),
	if
		PlayerStates#player_status.scene =:= Peach_Scene_Id->
			NewPlayerStates = PlayerStates#player_status{
				 scene = SceneId,                    % 场景id
			     copy_id = 0,                        % 副本id 
			     y = X,
			     x = Y
			},
			NewPlayerStates;
		true->PlayerStates
	end.

execute_48101(UniteStatus)->
	Peach_status = mod_peach:get_status(),
	{ok, BinData} = pt_481:write(48101, [Peach_status]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_48102(UniteStatus)->
	Room_List = mod_peach:room_list(),
	{ok, BinData} = pt_481:write(48102, [Room_List]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_48103(UniteStatus,Params)->
	[RoomId] = Params,
	[Result,Rest_time] = mod_peach:enter_room(UniteStatus,RoomId),
	case Result of
		1-> %成功
            DailyPid = lib_player:get_player_info(UniteStatus#unite_status.id,dailypid),
            mod_daily:increment(DailyPid, UniteStatus#unite_status.id, 6000007),
			lib_player:change_pk_status(UniteStatus#unite_status.id,9),
			SceneId = data_peach:get_peach_config(scene_id),
			[X,Y] = data_peach:get_peach_config(scene_born),
			CopyId = RoomId, 
			lib_scene:player_change_scene_queue(UniteStatus#unite_status.id,SceneId,CopyId,X,Y,0);
			%%添加保底玩法
%% 			lib_player:update_player_info(UniteStatus#unite_status.id, [{wubianhai_buff,enter_arena}])
		_->
			void
	end,
	{ok, BinData} = pt_481:write(48103, [RoomId,Result,Rest_time]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_48104(Uid)->
	mod_peach:score_list(Uid),
	ok.

%% 48009协议处理结果。
execute_48105(UniteStatus)->
	[SceneId,X,Y] = data_peach:get_peach_config(leave_scene),
	PkValue = case mod_peach:get_peach(UniteStatus#unite_status.id) of
		{error,_ErrorCode}->
			2; %lib_player:change_pk_status(UniteStatus#unite_status.id,2);
		{ok,Peach}->
			Peach#peach.pk_status %lib_player:change_pk_status(UniteStatus#unite_status.id,Peach#peach.pk_status) %%切换阵营
	end,
    lib_scene:player_change_scene_queue(UniteStatus#unite_status.id,SceneId,0,X,Y,[{pk_value, PkValue}]),
%% 	%%添加保底玩法
%% 	lib_player:update_player_info(UniteStatus#unite_status.id, [{wubianhai_buff,out_arena}]),
	{ok, BinData} = pt_481:write(48105, [1]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_48109(UniteStatus)->
	Scene_Id = data_peach:get_peach_config(scene_id),
	Scene_born = data_peach:get_peach_config(scene_born),
	case mod_peach:get_no1_uid(UniteStatus#unite_status.id) of
		0-> [X,Y] = Scene_born;
		No1_uid->
			case lib_player:get_player_info(No1_uid, position_info) of
				false->[X,Y] = Scene_born;
				{_Scence,_Copy,_X,_Y}->
					if
						Scene_Id=:=_Scence andalso UniteStatus#unite_status.copy_id=:=_Copy->
							[X,Y] = [_X,_Y];
						true->
							[X,Y] = Scene_born
					end
			end
	end,
	{ok, BinData} = pt_481:write(48109, [X,Y]),
    lib_unite_send:send_to_sid(UniteStatus#unite_status.sid, BinData),
	ok.

execute_48110(UniteStatus)->
	lib_player:get_card_good(UniteStatus#unite_status.id,1),
	ok.
server_send_mail(Status)->
	Card = Status#player_status.card,
	Goods_B_Num = Card#status_card.peach_gift_num,
	Gift_Id2 = data_peach:get_peach_config(gift_id2),
	Title = data_mail_log_text:get_mail_log_text(peach_title2),
	Content = io_lib:format(data_mail_log_text:get_mail_log_text(peach_content2),[Goods_B_Num]),
	if
		0<Goods_B_Num->
			mod_disperse:call_to_unite(lib_mail,send_sys_mail_bg, [[Status#player_status.id], 
																   Title, Content, Gift_Id2, 
																   2, 0, 0,Goods_B_Num,0,0,0,0]),
			Result=1;
		true->Result = 0
	end,
	{ok, BinData} = pt_481:write(48110, [Result]),
	mod_disperse:call_to_unite(lib_unite_send,send_to_uid,[Status#player_status.id, BinData]),
	Status#player_status{card=Card#status_card{peach_gift_num=0}}.

%%设置积分-杀人
set_score_by_kill_player(Uid,KilledUid)->
	mod_peach:set_score(player,Uid,KilledUid),
	execute_48104(Uid),
	execute_48104(KilledUid).

%%设置积分-杀守护神、箱子
set_score_by_kill_npc(Uid,NPCTypeId)->
	%%设置积分
	mod_peach:set_score(npc,Uid,NPCTypeId),
	execute_48104(Uid).

%%更新玩家蟠桃园数据
update_player_peach(PlayerStatus,[Score,Acquisition,Plunder,Robbed,Now_Time,Peach_Card_good_num])->
	Peach = PlayerStatus#player_status.peach,
	if
		Peach#status_peach.last_time=<0->
			SQL = io_lib:format(<<"insert into player_peach(id,total_score,score,acquisition,plunder,robbed,last_time) values(~p,~p,~p,~p,~p,~p,~p)">>,
								[PlayerStatus#player_status.id,
								 Score,Score,Acquisition,
								 Plunder,Robbed,Now_Time]);
		true->
			SQL = io_lib:format(<<"update player_peach set total_score=total_score+~p,score=~p,acquisition=~p,plunder=~p,robbed=~p,last_time=~p where id=~p">>,
								[Score,Score,Acquisition,
								 Plunder,Robbed,Now_Time,
								 PlayerStatus#player_status.id])
	end,
	db:execute(SQL),
	New_Peach = Peach#status_peach{
		total_score = Peach#status_peach.total_score+Score,			%历史总积分
		score = Score,     											%上一场积分
	  	acquisition = Acquisition,									%上一场采集所得分
		plunder = Plunder,											%上一场掠夺所得分
	  	robbed = Robbed,											%上一场被抢分
	  	last_time = Now_Time						   
	},
	New_Card = PlayerStatus#player_status.card#status_card{peach_gift_num=Peach_Card_good_num},
	PlayerStatus#player_status{peach=New_Peach,card = New_Card}.
	
%%
%% Local Functions
%%

