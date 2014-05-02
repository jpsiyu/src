%%%------------------------------------
%%% @Module  : mod_server_call
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.12.16
%%% @Description: 角色call处理
%%%------------------------------------
-module(mod_server_call).
-export([handle_call/3]).
-include("server.hrl").
-include("goods.hrl").
-include("rela.hrl").
%%==========基础功能base============ 
%%获取用户信息
handle_call('base_data', _from, Status) ->
    {reply, Status, Status};

%% 获取分类的玩家信息_根据模块调用
handle_call({'get_data', Type}, _from, Status) ->
    %% 根据类型_调用各个功能自己的解析模块获取相关的数据
    case Type of
		god -> %%诸神
			{reply, Status#player_status.god, Status};
		kf_1v1_info -> %% 1v1信息, 排行榜也有用到
			{Y,M,D} = date(),
			{{L_Y,L_M,L_D},_} = util:seconds_to_localtime(Status#player_status.kf_1v1#status_kf_1v1.last_time),
			if
				Y=:=L_Y andalso M=:=L_M andalso D=:=L_D->
					Loop_day = Status#player_status.kf_1v1#status_kf_1v1.loop_day;
				true->
					Loop_day = 0
			end,
			{reply, {
				Status#player_status.combat_power,
				Status#player_status.hp,
				Status#player_status.hp_lim,
				Status#player_status.scene,
				Status#player_status.kf_1v1#status_kf_1v1.pt,
				Loop_day,
				Status#player_status.hightest_combat_power,
				Status#player_status.kf_1v1
			}, Status};
		%% 跨服1v1 和 3v3的数据
		kf_pk_info ->
			{reply, {Status#player_status.kf_1v1, Status#player_status.kf_3v3}, Status};
		position_info-> 										%% 个人坐标信息
			{reply, {Status#player_status.scene,
					 Status#player_status.copy_id,
					 Status#player_status.x,
					 Status#player_status.y}, Status};
		dailypid -> 											%% 个人日常进程ID
	    	{reply, Status#player_status.dailypid, Status};
		pid ->
	    	{reply, Status#player_status.pid, Status};
		factionwar->
			{reply, Status#player_status.factionwar, Status};
        factionwar_stone ->
            {reply, Status#player_status.factionwar_stone, Status};
		player_meridian->
			{reply, Status#player_status.player_meridian, Status};
		nickname->
		    {reply, Status#player_status.nickname, Status};
		hightest_combat_power->
		    {reply, Status#player_status.hightest_combat_power, Status};
		combat_power->
		    {reply, Status#player_status.combat_power, Status};
		team ->
		    {reply, lib_team:trans(Status), Status};
		dungeon ->
		    {reply, lib_dungeon:trans(Status), Status};
		lib_sit ->
		    {reply, lib_sit:trans(Status), Status};
	    goods ->
	        {reply, Status#player_status.goods, Status};
		guild ->
		    {reply, Status#player_status.guild, Status};
		gold ->
		    {reply, Status#player_status.gold, Status};
	    unite ->
		    {reply, lib_unite:trans_to_unite(Status), Status};
		turntable ->
		    {reply, lib_turntable:trans(Status), Status};
		goods_pid ->
		    G = Status#player_status.goods,
		    {reply, G#status_goods.goods_pid, Status};
	    mount ->
	        Mount = Status#player_status.mount,
	        {reply, Mount#status_mount.mount_dict, Status};
		status_mount ->
	        {reply, [Status#player_status.mount, Status#player_status.base_speed], Status};
		sxbet ->
			{reply, {Status#player_status.pid, Status#player_status.nickname, Status#player_status.realm, Status#player_status.coin, Status#player_status.sid, Status#player_status.lv}, Status};
		sxaward ->
			{reply, Status#player_status.sid, Status};
		vip_type ->
			{reply, Status#player_status.vip, Status};
		%% 直接是vip类型，与#ets_unite.vip一样，楼上的大哥占了我的名字
		vip ->					
		    {reply, Status#player_status.vip#status_vip.vip_type, Status};
		scene_base ->
				Info = [Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y],
				{reply, Info, Status};
		scene ->
		    {reply, Status#player_status.scene, Status};
		physical ->
			%% change by xieyunfei 
			{reply, Status#player_status.physical#status_physical.physical_count, Status};
		lv ->
			{reply, Status#player_status.lv, Status};
		pk -> 
			{reply, Status#player_status.pk, Status};
		pid_team ->
			{reply, Status#player_status.pid_team, Status};
		status_target ->
			{reply, Status#player_status.status_target, Status};
		achieve ->
			{reply, Status#player_status.achieve, Status};
		interface_status ->			%% 接口需要的pid，目前格式是：[成就pid, 目标pid]							
			{reply, [Status#player_status.achieve, Status#player_status.status_target], Status};
		hotspring_data ->
			{reply, [
				Status#player_status.achieve, Status#player_status.scene, Status#player_status.copy_id	
			], Status};
		sendTv_Message ->
			{reply, [Status#player_status.id, Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image], Status};
        loverun -> 
            {reply, [Status#player_status.nickname, Status#player_status.sex, Status#player_status.scene, Status#player_status.copy_id], Status};
        parner_id -> 
            {reply, Status#player_status.parner_id, Status};
		fish_data ->
			{reply, [Status#player_status.pid, Status#player_status.fish, Status#player_status.scene, Status#player_status.copy_id], Status};
		auto_story_dungeon ->
		    {reply, {ok, Status#player_status.pid,
					 Status#player_status.dailypid,
					 Status#player_status.lv}, Status};
        marriage ->
            {reply, Status#player_status.marriage, Status};
		marriage_parner ->
            {reply, Status#player_status.marriage#status_marriage.parner_id, Status};
        marriage_sendtv ->
            {reply, [Status#player_status.realm, Status#player_status.nickname, Status#player_status.sex, Status#player_status.career, Status#player_status.image], Status};
        marriage_task ->
            {reply, Status#player_status.marriage#status_marriage.task, Status};
		hp ->
			{reply,Status#player_status.hp, Status};
		hp_lim ->
			{reply,Status#player_status.hp_lim, Status};
		name_career ->
			{reply,[Status#player_status.nickname, Status#player_status.career], Status};
		xianyuan_data ->
			{reply,[Status#player_status.marriage#status_marriage.register_time,Status#player_status.marriage#status_marriage.parner_id,
					Status#player_status.player_xianyuan,Status#player_status.cp_skill#couple_skill.lv_1,Status#player_status.cp_skill#couple_skill.lv_2,
					Status#player_status.pid, Status#player_status.marriage#status_marriage.divorce_state], Status};
		qiling ->
			{reply, [Status#player_status.qiling_attr], Status};
		kf_rank_info ->
			{reply, [
				Status#player_status.platform, Status#player_status.server_num, Status#player_status.nickname, 
				Status#player_status.realm, Status#player_status.career, Status#player_status.sex,
				Status#player_status.combat_power, Status#player_status.lv, Status#player_status.coin, 
				Status#player_status.cjpt, Status#player_status.gjpt
			], Status};
        all_coin ->
            {reply, Status#player_status.coin + Status#player_status.bcoin, Status};
		kf_3v3_info -> %% 3v3信息
			{reply, {
				Status#player_status.combat_power,
				Status#player_status.hightest_combat_power,
				Status#player_status.scene,
				Status#player_status.vip#status_vip.growth_lv,
				[
					Status#player_status.kf_1v1#status_kf_1v1.pt,
					Status#player_status.kf_1v1#status_kf_1v1.score
				]
			}, Status};
        figure ->
            {reply, Status#player_status.figure, Status};
        vip_growth_lv ->
            {reply, Status#player_status.vip#status_vip.growth_lv, Status};
        marriage_parner_id ->
            {reply, Status#player_status.marriage#status_marriage.parner_id, Status};
        city_war_stone ->
            {reply, {Status#player_status.factionwar_stone, Status#player_status.x, Status#player_status.y, Status#player_status.pk#status_pk.pk_status}, Status};
        can_transferable ->
            {reply, lib_player:is_transferable(Status), Status};
		fashion_ring ->
			Goods = Status#player_status.goods,
			case Goods#status_goods.hide_ring =:= 0 of
				true ->
					[FashionRing, _Stren6] = Goods#status_goods.fashion_ring;
				false ->
					[FashionRing, _Stren6] = [0, 0]
			end,	
			{reply, FashionRing, Status};
		get_image ->
			BodyImage = lib_player_server:get_player_statue(Status),
			{reply, BodyImage, Status};
        name_career_sex ->
            {reply,[Status#player_status.nickname, Status#player_status.career, Status#player_status.sex], Status};
		_ ->
	    	{reply, Status, Status}
    end;

%% 花费_使用玩家资产
%% @param PlayerId 玩家ID
%% @param Num 消费数量
%% @param Type 消费类型
%% @param ConsumeType 产生消费的记录类型 (data_goods:get_consume_type(Type)如果没有类型,需要在这里添加类型)
%% @param ConsumeInfo 记录相关的信息
%% @return {ok, ok} 成功扣费并记录 {error, 0错误的玩家ID,1元宝不足,2参数错误}
handle_call({spend_assets, [PlayerId, Num, Type, ConsumeType, ConsumeInfo]}, _from, Status) ->
    {Reply, NewStatus} = case PlayerId =:= Status#player_status.id andalso Num >= 0 of
			     false ->
				 %% 错误的玩家ID
				 {{error, 0}, Status};
			     true when is_atom(Type) andalso is_integer(Num)->
				 case lib_goods_util:is_enough_money(Status, Num, Type) of
				     true when is_integer(Num)->
					 StatusCostOk = lib_goods_util:cost_money(Status, Num, Type),
					 log:log_consume(ConsumeType, Type, Status, StatusCostOk, ConsumeInfo),
					 lib_player:refresh_client(Status#player_status.id, 2),
					 {{ok, ok}, StatusCostOk};
				     false ->
					 %% 不足
					 {{error, 1}, Status}
				 end;
			     _ ->
				 %% 参数类型错误
				 {{error, 2}, Status}
			 end,
    {reply, Reply, NewStatus};

%%删除玩家对应材料
%% @param PlayerStatus 玩家状态
%% @parama L 材料列表。 [[GoodTypeId,Num]...]
%%@return true|false
handle_call({'delete_goods', L}, _from, Status) ->
    Reply = lib_meridian:delete_goods(Status,L),
    {reply, Reply, Status};

%%检测场景能否进入
handle_call({scene_check_enter,SceneId}, _from,Status) ->
    case lib_scene:check_enter(Status, SceneId) of
	{false, _Msg} ->
	    {reply, {error,{not_allow_enter_scence,_Msg}}, Status};
	{true, _A, _B, _C, _D, _E, _F} ->
	    {reply, {true,{can_enter,_A, _B, _C, _D, _E, _F}}, Status};
	Others->
	    {reply, {true,{can_enter,Others}}, Status}
    end;

%%改变PK状态
handle_call({change_pk_status,Type}, _from,Status) ->
    Reply = lib_player:change_pkstatus(Status, Type),
    {_Result, _ErrorCode, _NewType, _LTime, NewStatus1} = Reply,
    {reply, Reply, NewStatus1};

%% 调用模块函数
handle_call({'apply_call', Moudle, Method, Args}, _from, Status) ->
    %% 	io:format("mod_server_call apply_call Moudle = ~p, Method = ~p, Args = ~p~n",
    %% 						[Moudle, Method, Args]),
    Reply = case catch apply(Moudle, Method, Args) of
		{'EXIT', Info} ->
		    util:errlog("mod_server_call apply_call error Moudle = ~p, Method = ~p, Args = ~p, Reason = ~p~n",
				[Moudle, Method, Args, Info]);
		DataRet ->
		    DataRet
	    end,
    %% 	io:format("mod_server_call apply_call reply = ~p~n", [Reply]),
    {reply, Reply, Status};

%% 接受交易
handle_call({'recv_sell', PlayerId}, _from, Status) ->
    Sell = Status#player_status.sell,
    Go = Status#player_status.goods,
    if  %% 玩家正在交易中
        Sell#status_sell.sell_status > 0 ->
            {reply, {fail, 5}, Status};
        true ->
            gen_server:cast(Go#status_goods.goods_pid, {'recv_sell'}),
            NewStatus = Status#player_status{sell=Sell#status_sell{sell_id=PlayerId, sell_status=1}},
            {reply, ok, NewStatus}
    end;

%% 完成交易
handle_call({'finish_sell', SellerPlayerStatus, SellerGoodsStatus}, _from, Status) ->
    Sell = Status#player_status.sell,
    Go = Status#player_status.goods,
    if  %% 玩家还没有确认
        Sell#status_sell.sell_status =/= 4 ->
            {reply, {fail, 6}, Status};
        true ->
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'finish_sell_two', Status, SellerPlayerStatus, SellerGoodsStatus}) of
                {ok, {fail, Res}} -> 
                    {reply, {fail, Res}, Status};
                {ok, {ok, NewPlayerStatus, NewSellerPlayerStatus, NewSellerGoodsStatus}} ->
                    {reply, {ok, NewSellerPlayerStatus, NewSellerGoodsStatus, NewPlayerStatus}, NewPlayerStatus};
                {'EXIT',_Reason} ->
		    {reply, {fail, 0}, Status}
            end
    end;

%% 接受双修邀请
handle_call({'shuangxiu_recv', InvitePlayer}, _from, Status) ->
    Sit = Status#player_status.sit,
    Mou = Status#player_status.mount,
    if  %% 对方已在双修中，无法加入双修
        Sit#status_sit.sit_down =:= 2 ->
            {reply, {fail, 5}, Status};
        %% 骑着坐骑不能双修
        Mou#status_mount.mount > 0 ->
            {reply, {fail, 8}, Status};
        true ->
            case (Status#player_status.scene =:= InvitePlayer#player_status.scene
		  andalso abs(Status#player_status.x - InvitePlayer#player_status.x) =< 3
		  andalso abs(Status#player_status.y - InvitePlayer#player_status.y) =< 3 ) of
		%% 与对方距离过远，无法加入双修
		false ->
		    {reply, {fail, 6}, Status};
		true ->
		    NowTime = util:unixtime(),
		    NewStatus = lib_sit:shuangxiu(Status, InvitePlayer#player_status.id, InvitePlayer#player_status.figure, InvitePlayer#player_status.pid, NowTime),
		    NewSit = NewStatus#player_status.sit,
		    {reply, {ok, NewSit#status_sit.sit_hp_time}, NewStatus}
            end
    end;

%% 发放物品
handle_call({'send_goods_unite', Type, GiveList}, _from, Status) ->
	Player_Goods = Status#player_status.goods,
    Info = case Type of
			   bind ->
				   gen_server:call(Player_Goods#status_goods.goods_pid, {'give_more_bind', Status, GiveList}, 4000);
			   unbind ->
				   gen_server:call(Player_Goods#status_goods.goods_pid, {'give_more', Status, GiveList}, 4000)
		   end,
	case Info of
		ok ->
			%% 延时1秒,与摇奖旋转结束同步
			spawn(fun() -> timer:sleep(1000),
				GiveList2 = [{goods, GoodsTypeId, GoodsNum} ||{GoodsTypeId, GoodsNum} <- GiveList],
				lib_gift_new:send_goods_notice_msg(Status, GiveList2)
				end);			
		_ -> skip
	end,
	{reply, Info, Status};

%% 帮派福利发放物品和金钱奖励
handle_call({'send_fuli_unite', _Type, GiveList}, _from, Status) ->
	Player_Goods = Status#player_status.goods,
    [Info, StatusBack] = case gen_server:call(Player_Goods#status_goods.goods_pid, {'give_more_bind', Status, GiveList}, 4000) of
		ok ->
			NewStatus = Status#player_status{coin = Status#player_status.coin + 10000},
			lib_player:refresh_client(Status#player_status.id, 2),
		    log:log_produce(guild_weal, coin, Status, NewStatus, "guild_fu_li"),
			[ok, NewStatus];
		Err ->
			[Err, Status]
	end,
	{reply, Info, StatusBack};

%% 发放私人邮件
%% 改变物品, 铜币, 绑定铜币
handle_call({send_priv_mail, [SenderId, ReceiverId, Title, Content, GoodsId, IdType, GoodsNum, Postage, Coin]}, _from, Status) ->
	%% 检查是否够钱
	case lib_mail:check_fee(Status#player_status.bcoin, Status#player_status.coin, Postage, Coin) of    
    	{ok, NewBCoin, NewCoin} ->
			F = fun() ->
					%% 扣钱
		            {ok, NewStatus} = lib_mail:handle_money_send(Status, NewBCoin, NewCoin),
					%% 写入邮件SQL
		            {ok, MailAttribute} = lib_mail:insert_mail_no_transaction(2, SenderId, ReceiverId, Title, Content, GoodsId, IdType, 0, 0, 0, GoodsNum, 0, Coin, 0, 0),
		            {ok, NewStatus, MailAttribute}
		    end, 
			case GoodsId == 0 orelse IdType /= 0 of
        		true ->      %% 没有物品附件
					case db:transaction(F) of
						{ok, NewStatusX, MailAttributeX} ->
							%% 写入日志
						    case Status#player_status.coin == NewStatusX#player_status.coin of
						        true ->
						            MoneyType = bcoin;
						        false ->
						            MoneyType = coin
						    end,
						    Text = data_mail_log_text:get_mail_log_text(log_mail_info),
						    About = io_lib:format(Text, [GoodsId, Coin]),
						    log:log_consume(mail_send, MoneyType, Status, NewStatusX, About),
							pp_mail:mail_ban_log(NewStatusX, ReceiverId, GoodsId, Coin),%% 防刷
							{reply, {ok, 0, 0, MailAttributeX}, NewStatusX};
						_ ->
							{reply, error, Status}
					end;
				_ ->        %% 有物品附件
					SendMailInfo = [2, SenderId, ReceiverId, Title, Content, IdType, 0, 0, 0, GoodsNum, 0, Coin, 0, 0],
                    PlayerInfo = [Status#player_status.id, NewBCoin, NewCoin],
					Go = Status#player_status.goods,
					case lib_mail:handle_goods_send(Go#status_goods.goods_pid, GoodsId, IdType, GoodsNum, ReceiverId, SendMailInfo, PlayerInfo) of
						{ok, NewId, MailAttribute} ->
							NewStatus = Status#player_status{coin = NewCoin, bcoin = NewBCoin},
							%% 写入日志
						    case Status#player_status.coin == NewStatus#player_status.coin of
						        true ->
						            MoneyType = bcoin;
						        false ->
						            MoneyType = coin
						    end,
						    Text = data_mail_log_text:get_mail_log_text(log_mail_info),
						    About = io_lib:format(Text, [GoodsId, Coin]),
						    log:log_consume(mail_send, MoneyType, Status, NewStatus, About),
							pp_mail:mail_ban_log(NewStatus, ReceiverId, GoodsId, Coin),%% 防刷
							GoodsInfo = lib_goods_util:get_goods_by_id(GoodsId), %% 日志需要
							{reply, {ok, NewId, GoodsInfo#goods.goods_id, MailAttribute}, NewStatus};
						_ ->
							{reply, error, Status}
					end
			end;
		_ ->
			{reply, error, Status}
	end;

%% 收取邮件附件
handle_call({get_attachment, [Mail, PlayerId]}, _from, Status) ->
	case PlayerId =:= Status#player_status.id of
		true ->
			%% 收取附件处理(DB和PlayerStatus) {ok, GoodsId, NewPlayerStatus, IsGetMoneySuc} = 
			case lib_mail:get_attachment_server(Mail, PlayerId, Status) of
				{ok, GoodsId, NewPlayerStatus, IsGetMoneySuc} ->
					{reply, {ok, GoodsId, IsGetMoneySuc}, NewPlayerStatus};
				{error, ErrorCode} ->
					{reply, {error, ErrorCode}, Status};
				_ ->
					{reply, error, Status}
			end;
		false ->
			{reply, error, Status}
	end;

%% 由公共线获取指定的玩家日常数据
handle_call({check_daily, DailyId}, _from, Status) ->
	Num = case DailyId =:= 6000004 of
		true ->
			NumX = mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, DailyId),
			case Status#player_status.lv >= 60 of
				true ->
					NumX;
				false ->
					case NumX >= 3 of
						true ->
							1;
						false ->
							0
					end
			end;
		false ->
			mod_daily:get_count(Status#player_status.dailypid, Status#player_status.id, DailyId)
	end,
	{reply, Num, Status};

%% 公共线扣取指定物品
handle_call({del_goods_unite, GoodsTypeId, Num}, _from, Status) ->
    Go = Status#player_status.goods,
    Reply = case gen_server:call(Go#status_goods.goods_pid,{'delete_more', GoodsTypeId, Num}) of
        1 ->
			1;
        Recv->
			case Recv =:= 2 orelse Recv =:= 3 of
				true -> %%没有物品或数量不足
					2;
				false -> %% 无定义的错误类型
					0
			end
    end,
    {reply, Reply, Status};

%%------------------------------------------------------------------------------
%% 好友相关功能  
%%------------------------------------------------------------------------------
handle_call({update_Intimacy,PlayerPid,IdA, IdB, Intimacy}, _from, Status) ->
    Reply = lib_relationship:update_Intimacy(PlayerPid,IdA, IdB, Intimacy),
    {reply, Reply, Status};

handle_call({find_intimacy_dict,PlayerPid,IdA, IdB}, _from, Status) ->
    Reply = lib_relationship:find_intimacy_dict(PlayerPid,IdA, IdB),
    {reply, Reply, Status};

handle_call({update_xlqy_count_sub,PlayerPid,IdA, IdB}, _from, Status) ->
    Reply = lib_relationship:update_xlqy_count_sub(PlayerPid,IdA, IdB),
    {reply, Reply, Status};

handle_call({get_rela_by_ABId, PlayerPid, IdA, IdB}, _from, Status) ->
    Reply = lib_relationship:get_rela_by_ABId(PlayerPid, IdA, IdB),
    {reply, Reply, Status};

handle_call({'getRelas'}, _from, Status) ->
    Relas = get(relas),
    {reply, Relas, Status};

handle_call({'putRelas',Value}, _from, Status) ->
    put(relas,Value),
    {reply, ok, Status};

handle_call({'eraseRelas'}, _from, Status) ->
    erase(relas),
    {reply, ok, Status};

handle_call({'getRela_groupnames'}, _from, Status) ->
    Rela_groupnames = get(rela_groupnames),
    {reply, Rela_groupnames, Status};

handle_call({'putRela_groupnames',Value}, _from, Status) ->
    put(rela_groupnames,Value),
    {reply, ok, Status};

handle_call({'eraseRela_groupnames'}, _from, Status) ->
    erase(rela_groupnames),
    {reply, ok, Status};

handle_call({'friend_bless_gift', FromId, Gift_Id}, _From, Status) ->
    case lib_relationship:get_rela_by_ABId(Status#player_status.pid,Status#player_status.id,FromId) of
	[]->void;
	[Rela2]->
	    Bless_gift_id = Rela2#ets_rela.bless_gift_id,
	    Old_No = lib_relationship:get_max_bless_gift(Bless_gift_id),
	    No = lib_relationship:get_max_bless_gift(Gift_Id),
	    if
		Old_No < No->
		    lib_relationship:update_rela_bless_gift_id(Status#player_status.pid,Status#player_status.id, FromId, Gift_Id);
		true->
		    void
	    end
    end,
    Reply = {Status#player_status.id,
	     Status#player_status.realm,
	     Status#player_status.nickname,
	     Status#player_status.sex,
	     Status#player_status.career,
	     Status#player_status.image},
    {reply, Reply, Status};

handle_call({'friend_bless', [NoUpLv,_UpLv,_]}, _From, Status) ->
    if
        %% 做验证，防止伪造升级等级
        Status#player_status.lv < _UpLv->
            UpLv = Status#player_status.lv;
        true->
            UpLv = _UpLv
    end,
    Player_Bless = Status#player_status.bless,
    case dict:is_key(UpLv, Player_Bless#status_bless.bless_accept) of
        false->
            Total_Exp_Up = UpLv * UpLv * ?BLESS_UP_EXP,
            Total_LLPT_Up = UpLv * UpLv * ?BLESS_UP_LLPT,
            Total_Exp_NO_Up = NoUpLv * UpLv * ?BLESS_NO_UP_EXP,
            Total_LLPT_NO_Up = NoUpLv * UpLv * ?BLESS_NO_UP_LLPT,
            Cishu = 1;
        true->
            _Cishu = dict:fetch(UpLv, Player_Bless#status_bless.bless_accept),
            if
                _Cishu =< ?MAX_BLESS_ACCEPT->
                    Total_Exp_Up = UpLv * UpLv * ?BLESS_UP_EXP,
                    Total_LLPT_Up = UpLv * UpLv * ?BLESS_UP_LLPT,
                    Total_Exp_NO_Up = NoUpLv * UpLv * ?BLESS_NO_UP_EXP,
                    Total_LLPT_NO_Up = NoUpLv * UpLv * ?BLESS_NO_UP_LLPT,
                    Cishu = _Cishu+1;
                true -> %%第31次祝福
                    Total_Exp_Up = 0,
                    Total_LLPT_Up = 0,
                    Total_Exp_NO_Up = NoUpLv * UpLv * ?BLESS_NO_UP_EXP*5 div 100,
                    Total_LLPT_NO_Up = NoUpLv * UpLv * ?BLESS_NO_UP_LLPT*5 div 100,
                    Cishu = _Cishu+1
            end
    end,
    %%更改升级玩家属性
    if
        UpLv < ?Exp_Llpt_Bottle_Max_Lv -> %低于40级的
            Exp = Total_Exp_Up * 25 div 100,
            Llpt = Total_LLPT_Up * 25 div 100,
            ExtExp = 0,
            ExtLlpt = 0,
            %ExtExp = Total_Exp_Up * 75 div 100,
            %ExtLlpt = Total_LLPT_Up * 75 div 100,
            Status1 = lib_player:add_exp(Status, Exp),
            Status2 = lib_player:add_pt(llpt, Status1, Llpt);
        %lib_relationship:update_bless_exp_llpt(Status2#player_status.id,ExtExp,ExtLlpt);
        true->
            Exp = Total_Exp_Up,
            Llpt = Total_LLPT_Up,
            ExtExp = 0,
            ExtLlpt = 0,
            Status1 = lib_player:add_exp(Status, Exp),
            Status2 = lib_player:add_pt(llpt, Status1, Llpt)
    end,
    %  New_Player_Bless = Player_Bless#status_bless{
    %  		 bless_exp = Player_Bless#status_bless.bless_exp + ExtExp,					   %%经验瓶储存经验
    %  		 bless_llpt = Player_Bless#status_bless.bless_llpt + ExtLlpt,				   %%经验瓶储存历练声望																		 
    %  		 bless_accept = dict:store(UpLv, Cishu, Player_Bless#status_bless.bless_accept)
    %  		},
    %  NewStatus = Status2#player_status{bless=New_Player_Bless},
    %  pp_relationship:handle(14019, NewStatus, []),
    NewStatus = Status2,
    Reply = [{Total_Exp_NO_Up, Total_LLPT_NO_Up}, {UpLv, Exp, Llpt, ExtExp, ExtLlpt,Cishu}],
    {reply, Reply, NewStatus};

%% 是否在黑名单
handle_call({'is_in_blacklist', Pid, AId, BId}, _From, Status) ->
    Is_black = lib_relationship:is_in_blacklist(Pid, AId, BId),
    {reply, Is_black, Status};

%%------------------------------------------------------------------------------
%% 好友相关功能结束
%%------------------------------------------------------------------------------

%% 是否充值
handle_call({'is_pay'}, _From, Status) ->
    {reply, Status#player_status.is_pay, Status};

%% 是否充值
handle_call({'xianyuan_total_attribute'}, _From, Status) ->
	%% 仙缘属性
	[Hp11, Def11, Hit11, Dodge11, Ten11, Crit11, Att11, Fire11, Ice11, Drug11,Hp11_1, Def11_1, Hit11_1,
		Dodge11_1, Ten11_1, Crit11_1, Att11_1, Fire11_1, Ice11_1, Drug11_1]= mod_xianyuan:count_attribute_2(Status),
	JLevel = mod_xianyuan:get_JLevel(Status#player_status.player_xianyuan),
    Reply = [Hp11, Def11, Hit11, Dodge11, Ten11, Crit11, Att11, Fire11, Ice11, Drug11, Hp11_1,
		Def11_1, Hit11_1, Dodge11_1, Ten11_1, Crit11_1, Att11_1, Fire11_1, Ice11_1, Drug11_1,JLevel],
    {reply, Reply, Status};

%% 扣除花灯道具
handle_call({'fire_lamp_delete_goods', Type}, _From, Status) ->
    ErrorCode = lib_activity_festival:fire_lamp_delete_goods(Status, Type),
    {reply, ErrorCode, Status};

%% 前往祝福奖励 
handle_call({'wish_for_lamp_award', Type}, _From, Status) ->
	Res = lib_activity_festival:wish_for_lamp_award(Status, Type),
	[_,_,_,NewStatus] = Res,
    {reply, Res, NewStatus};

%% 收获花灯奖励物品
handle_call({'gain_lamp_goods', Type}, _From, Status) ->
    Res = lib_activity_festival:gain_lamp_goods(Status, Type),
    {reply, Res, Status};

%% 加速清除冷却
handle_call({'updat_physical', NewRoleStatus}, _From, _Status) ->
    Res = ok,
    {reply, Res, NewRoleStatus};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_server:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.
