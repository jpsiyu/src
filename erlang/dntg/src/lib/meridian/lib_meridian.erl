%%%-----------------------------------
%%% @Module  : lib_meridian
%%% @Author  : hc
%%% @Email   : hc@jieyou.com
%%% @Created : 2010.08.09
%%% @Description: 经脉系统
%%%-----------------------------------
-module(lib_meridian).
-compile(export_all).
-include("meridian.hrl").
-include("server.hrl").
-include("def_goods.hrl").

%%更新突破DB等级
%%@param Player_meridian #player_meridian
%%@return 
update_tupo(Player_meridian)->
	Sql = io_lib:format(<<"update meridian set thpmp=~p,tdef=~p,tdoom=~p,tjook=~p,ttenacity=~p,tsudatt=~p,tatt=~p,tfiredef=~p,ticedef=~p,tdrugdef=~p where uid=~p">>, 
						 [Player_meridian#player_meridian.thpmp,
						  Player_meridian#player_meridian.tdef,
						  Player_meridian#player_meridian.tdoom,
						  Player_meridian#player_meridian.tjook,
						  Player_meridian#player_meridian.ttenacity,
						  Player_meridian#player_meridian.tsudatt,
						  Player_meridian#player_meridian.tatt,
						  Player_meridian#player_meridian.tfiredef,
						  Player_meridian#player_meridian.ticedef,
						  Player_meridian#player_meridian.tdrugdef,
						  Player_meridian#player_meridian.uid]),
	db:execute(Sql).

%%获取突破脉的突破等级
%% @param MeridianId 经脉等级
%% @param Player_meridian #player_meridian
%% @return 对应突破等级
get_tupo(MeridianId,Player_meridian)->
	case MeridianId of
		6->Player_meridian#player_meridian.thpmp;      %%气血、内力内功等级,
		2->Player_meridian#player_meridian.tdef;       %%防御内功等级,
		3->Player_meridian#player_meridian.tdoom;      %%命中内功等级,
		4->Player_meridian#player_meridian.tjook;      %%闪避内功等级,
		5->Player_meridian#player_meridian.ttenacity;  %%坚韧内功等级,
		1->Player_meridian#player_meridian.tsudatt;    %%暴击内功等级,
		7->Player_meridian#player_meridian.tatt;       %%攻击内功等级,
		8->Player_meridian#player_meridian.tfiredef;   %%火坑内功等级,
		9->Player_meridian#player_meridian.ticedef;    %%冰抗内功等级,
		10->Player_meridian#player_meridian.tdrugdef
	end.

%%成就：成就：元神境界，全部境界达到N，每次提升调用一次
%% achieve_min_yuanshen_jingjie(Player_meridian)->
%% 	Min = lists:min([Player_meridian#player_meridian.hpmp,      %%气血、内力内功等级,
%% 		  Player_meridian#player_meridian.def,       %%防御内功等级,
%% 		  Player_meridian#player_meridian.doom,      %%命中内功等级,
%% 		  Player_meridian#player_meridian.jook,      %%闪避内功等级,
%% 		  Player_meridian#player_meridian.tenacity,  %%坚韧内功等级,
%% 		  Player_meridian#player_meridian.sudatt,    %%暴击内功等级,
%% 		  Player_meridian#player_meridian.att,       %%攻击内功等级,
%% 		  Player_meridian#player_meridian.firedef,   %%火坑内功等级,
%% 		  Player_meridian#player_meridian.icedef,    %%冰抗内功等级,
%% 		  Player_meridian#player_meridian.drugdef,   %%毒抗内功等级,
%% 		  Player_meridian#player_meridian.ghpmp,     %%气血、内力境界等级,
%% 		  Player_meridian#player_meridian.gdef,      %%防御境界等级,
%% 		  Player_meridian#player_meridian.gdoom,     %%命中境界等级,
%% 		  Player_meridian#player_meridian.gjook,     %%闪避境界等级,
%% 		  Player_meridian#player_meridian.gtenacity, %%坚韧境界等级,
%% 		  Player_meridian#player_meridian.gsudatt,   %%暴击境界等级,
%% 		  Player_meridian#player_meridian.gatt,      %%攻击境界等级,
%% 		  Player_meridian#player_meridian.gfiredef,  %%火坑境界等级,
%% 		  Player_meridian#player_meridian.gicedef,   %%冰抗境界等级,
%% 		  Player_meridian#player_meridian.gdrugdef]),
%% 	mod_achieve:trigger_role(Player_meridian#player_meridian.uid, 13, 0, Min).

%%成就：元神！元神！元神总等级达到 N 级，每次提升调用一次
achieve_sum_yuanshen(PlayerStatus, Player_meridian)->
	Sum = lists:sum([Player_meridian#player_meridian.hpmp,      %%气血、内力内功等级,
		  Player_meridian#player_meridian.def,       %%防御内功等级,
		  Player_meridian#player_meridian.doom,      %%命中内功等级,
		  Player_meridian#player_meridian.jook,      %%闪避内功等级,
		  Player_meridian#player_meridian.tenacity,  %%坚韧内功等级,
		  Player_meridian#player_meridian.sudatt,    %%暴击内功等级,
		  Player_meridian#player_meridian.att,       %%攻击内功等级,
		  Player_meridian#player_meridian.firedef,   %%火坑内功等级,
		  Player_meridian#player_meridian.icedef,    %%冰抗内功等级,
		  Player_meridian#player_meridian.drugdef]),   %%毒抗内功等级,
	mod_achieve:trigger_role(PlayerStatus#player_status.achieve, Player_meridian#player_meridian.uid, 30, 0, Sum),
	%% 触发名人堂：不灭元神，第一个元神总等级达到100
	mod_fame:trigger(PlayerStatus#player_status.mergetime, Player_meridian#player_meridian.uid, 7, 0, Sum).

%% 加载指定玩家的经脉信息
%% @param Uid 玩家ID
%% @return [#ets_player_meridian]
load(Uid)->
	%%加载数据库经脉信息，如果没有，直接新建三条记录。
	case find(Uid) of
		 []->
			 insert(Uid),
			 #player_meridian{uid=Uid};
		 L -> 
			 write_player_meridian(L)
	end.

%%核对玩家材料够不够
%%@param Uid 玩家ID
%%@param L 材料列表。 [[GoodTypeId,Num]...]
%%@return true|false
check_goods(PlayerStatus,[],_IsBuy)->{true,PlayerStatus};
check_goods(PlayerStatus,L,IsBuy)->
	[H|T] = L,
	[GoodTypeId,GoodsNum] = H,
    Dict = lib_goods_dict:get_player_dict(PlayerStatus),
	TGoodsList = lib_goods_util:get_type_goods_list(PlayerStatus#player_status.id, GoodTypeId, 
                                                    ?GOODS_LOC_BAG, Dict),
    TotalNum = lib_goods_util:get_goods_totalnum(TGoodsList),
	if
		TotalNum<GoodsNum -> 
			if
				IsBuy=:=1 -> %%商城购买不够的材料
					Go = PlayerStatus#player_status.goods,
		            case gen_server:call(Go#status_goods.goods_pid,{'pay', PlayerStatus, GoodTypeId, GoodsNum-TotalNum, 1, 2, 2}) of
		                [NewPlayerStatus, Res, GoodsList] ->
							case Res =:= 1 of
                                true ->
									{ok, BinData} = pt_153:write(15310, [Res, GoodTypeId, GoodsNum-TotalNum, 1, NewPlayerStatus#player_status.bcoin, 
		                                                         NewPlayerStatus#player_status.coin, NewPlayerStatus#player_status.bgold, 
		                            							 NewPlayerStatus#player_status.gold, NewPlayerStatus#player_status.point, GoodsList]),
		                    		lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
                                    %% 消费通知
                                    lib_task:event(NewPlayerStatus#player_status.tid, buy_equip, {GoodTypeId}, NewPlayerStatus#player_status.id),
									check_goods(NewPlayerStatus,T,IsBuy);
                                false -> 
                                    {false,NewPlayerStatus}
                            end;
						_Others -> 
							{false,PlayerStatus}
                    end;
				true ->
					{false,PlayerStatus}
            end;
		true->check_goods(PlayerStatus,T,IsBuy)
	end.

%%删除玩家对应材料
%% @param PlayerStatus 玩家状态
%% @parama L 材料列表。 [[GoodTypeId,Num]...]
%%@return true|false
delete_goods(_PlayerStatus,[])->true;
delete_goods(PlayerStatus,L)->
	[H|T] = L,
	[GoodTypeId,Num] = H,
	Good = PlayerStatus#player_status.goods,
	case gen_server:call(Good#status_goods.goods_pid, {'delete_more', GoodTypeId, Num}) of
		1 -> 
			delete_goods(PlayerStatus,T);
		_Other -> 
			false
    end.

%%删除玩家对应材料(不分线，一般给公共线用)
%% @param PlayerStatus 玩家状态
%% @parama L 材料列表。 [[goods,GoodTypeId,Num]...]
%%@return true|false
delete_goods_by_list(Id,L) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:call(Pid, {'delete_goods', L});
        _ ->
            false
    end.

%%获取VIP加成概率
%%@param VipType VIP类型
get_rate_vip(VipType)->
	case VipType of 
 		1->3; %%月卡
		2->4; %%季卡
		3->5; %%半年卡
		_->0
    end.

%% 根骨境界传闻
gen_send_tv(Player_meridian,Player_status,Lv)->
	case lists:member(Lv,[5,10,15,20,25]) of
		false->void;
		true->
			{_Val1,_MLev1,GLev1} = count_attr(Player_meridian,1),
			{_Val2,_MLev2,GLev2} = count_attr(Player_meridian,2),
			{_Val3,_MLev3,GLev3} = count_attr(Player_meridian,3),
			{_Val4,_MLev4,GLev4} = count_attr(Player_meridian,4),
			{_Val5,_MLev5,GLev5} = count_attr(Player_meridian,5),
			{_Val6,_MLev6,GLev6} = count_attr(Player_meridian,6),
			{_Val7,_MLev7,GLev7} = count_attr(Player_meridian,7),
			{_Val8,_MLev8,GLev8} = count_attr(Player_meridian,8),
			{_Val9,_MLev9,GLev9} = count_attr(Player_meridian,9),
			{_Val10,_MLev10,GLev10} = count_attr(Player_meridian,10),
			%MMin = lists:min([MLev1,MLev2,MLev3,MLev4,MLev5,MLev6,MLev7,MLev8,MLev9,MLev10]),
			GMin = lists:min([GLev1,GLev2,GLev3,GLev4,GLev5,GLev6,GLev7,GLev8,GLev9,GLev10]),
			
			if
				GMin =:=Lv ->
					case Lv of
						5->Add = 30;
						10->Add = 60;
						15->Add = 120;
						20->Add = 200;
						25->Add = 300;
						_->Add = 0
					end,
					%%发送传闻
					lib_chat:send_TV({all},0,2,
									 [yuanshenreward,
									  Player_status#player_status.id,
									  Player_status#player_status.realm,
									  Player_status#player_status.nickname,
									  Player_status#player_status.sex,
									  Player_status#player_status.career,
									  Player_status#player_status.image,
									  Lv,
									  Add
									 ]);
				true->void
			end
	end.

%%获取经脉系统的附加人物属性
%% @param L1 [#data_meridian]
%% @param L2 [#data_meridian_gen]
%% @return [气血 -- 全抗] 9个属性列表
count_attr(Player_meridian)->
	{{Mer_Val0,Gen_Val0},_MLev0,_GLev0} = count_attr_0(Player_meridian),
	{{Mer_Val1,Gen_Val1},MLev1,GLev1} = count_attr(Player_meridian,1),
	{{Mer_Val2,Gen_Val2},MLev2,GLev2} = count_attr(Player_meridian,2),
	{{Mer_Val3,Gen_Val3},MLev3,GLev3} = count_attr(Player_meridian,3),
	{{Mer_Val4,Gen_Val4},MLev4,GLev4} = count_attr(Player_meridian,4),
	{{Mer_Val5,Gen_Val5},MLev5,GLev5} = count_attr(Player_meridian,5),
	{{Mer_Val6,Gen_Val6},MLev6,GLev6} = count_attr(Player_meridian,6),
	{{Mer_Val7,Gen_Val7},MLev7,GLev7} = count_attr(Player_meridian,7),
	{{Mer_Val8,Gen_Val8},MLev8,GLev8} = count_attr(Player_meridian,8),
	{{Mer_Val9,Gen_Val9},MLev9,GLev9} = count_attr(Player_meridian,9),
	{{Mer_Val10,Gen_Val10},MLev10,GLev10} = count_attr(Player_meridian,10),
	MMin = lists:min([MLev1,MLev2,MLev3,MLev4,MLev5,MLev6,MLev7,MLev8,MLev9,MLev10]),
	GMin = lists:min([GLev1,GLev2,GLev3,GLev4,GLev5,GLev6,GLev7,GLev8,GLev9,GLev10]),
	if
%		MMin>=80 andalso GMin>=20->
%			{6,[Val0,Val1,Val2,Val3,Val4,Val5,Val6,Val7,Val8,Val9,Val10]};
%		MMin>=70 andalso GMin>=16->
%			{5,[Val0,Val1,Val2,Val3,Val4,Val5,Val6,Val7,Val8,Val9,Val10]};
%		MMin>=60 andalso GMin>=13->
%			{4,[Val0,Val1,Val2,Val3,Val4,Val5,Val6,Val7,Val8,Val9,Val10]};
%		MMin>=50 andalso GMin>=10->
%			{3,[Val0,Val1,Val2,Val3,Val4,Val5,Val6,Val7,Val8,Val9,Val10]};
%		MMin>=40 andalso GMin>=6->
%			{2,[Val0,Val1,Val2,Val3,Val4,Val5,Val6,Val7,Val8,Val9,Val10]};
%		MMin>=30 andalso GMin>=3->
%			{1,[Val0,Val1,Val2,Val3,Val4,Val5,Val6,Val7,Val8,Val9,Val10]};

%% 		MMin>=0 andalso GMin>=20->
%% 			{6,[{Mer_Val0,Gen_Val0},{Mer_Val1,Gen_Val1},{Mer_Val2,Gen_Val2},{Mer_Val3,Gen_Val3},{Mer_Val4,Gen_Val4},
%% 				{Mer_Val5,Gen_Val5},{Mer_Val6,Gen_Val6},{Mer_Val7,Gen_Val7},{Mer_Val8,Gen_Val8},{Mer_Val9,Gen_Val9},{Mer_Val10,Gen_Val10}]};
		MMin>=0 andalso GMin>=25->
			{5,[{Mer_Val0,Gen_Val0},{Mer_Val1,Gen_Val1},{Mer_Val2,Gen_Val2},{Mer_Val3,Gen_Val3},{Mer_Val4,Gen_Val4},
				{Mer_Val5,Gen_Val5},{Mer_Val6,Gen_Val6},{Mer_Val7,Gen_Val7},{Mer_Val8,Gen_Val8},{Mer_Val9,Gen_Val9},{Mer_Val10,Gen_Val10}]};
		MMin>=0 andalso GMin>=20->
			{4,[{Mer_Val0,Gen_Val0},{Mer_Val1,Gen_Val1},{Mer_Val2,Gen_Val2},{Mer_Val3,Gen_Val3},{Mer_Val4,Gen_Val4},
				{Mer_Val5,Gen_Val5},{Mer_Val6,Gen_Val6},{Mer_Val7,Gen_Val7},{Mer_Val8,Gen_Val8},{Mer_Val9,Gen_Val9},{Mer_Val10,Gen_Val10}]};
		MMin>=0 andalso GMin>=15->
			{3,[{Mer_Val0,Gen_Val0},{Mer_Val1,Gen_Val1},{Mer_Val2,Gen_Val2},{Mer_Val3,Gen_Val3},{Mer_Val4,Gen_Val4},
				{Mer_Val5,Gen_Val5},{Mer_Val6,Gen_Val6},{Mer_Val7,Gen_Val7},{Mer_Val8,Gen_Val8},{Mer_Val9,Gen_Val9},{Mer_Val10,Gen_Val10}]};
		MMin>=0 andalso GMin>=10->
			{2,[{Mer_Val0,Gen_Val0},{Mer_Val1,Gen_Val1},{Mer_Val2,Gen_Val2},{Mer_Val3,Gen_Val3},{Mer_Val4,Gen_Val4},
				{Mer_Val5,Gen_Val5},{Mer_Val6,Gen_Val6},{Mer_Val7,Gen_Val7},{Mer_Val8,Gen_Val8},{Mer_Val9,Gen_Val9},{Mer_Val10,Gen_Val10}]};
		MMin>=0 andalso GMin>=5->
			{1,[{Mer_Val0,Gen_Val0},{Mer_Val1,Gen_Val1},{Mer_Val2,Gen_Val2},{Mer_Val3,Gen_Val3},{Mer_Val4,Gen_Val4},
				{Mer_Val5,Gen_Val5},{Mer_Val6,Gen_Val6},{Mer_Val7,Gen_Val7},{Mer_Val8,Gen_Val8},{Mer_Val9,Gen_Val9},{Mer_Val10,Gen_Val10}]};
		true->
			{0,[{Mer_Val0,Gen_Val0},{Mer_Val1,Gen_Val1},{Mer_Val2,Gen_Val2},{Mer_Val3,Gen_Val3},{Mer_Val4,Gen_Val4},
				{Mer_Val5,Gen_Val5},{Mer_Val6,Gen_Val6},{Mer_Val7,Gen_Val7},{Mer_Val8,Gen_Val8},{Mer_Val9,Gen_Val9},{Mer_Val10,Gen_Val10}]}
	end.
%% 添加基础属性
%% @param Player_meridian 
%% return [力量、体制、灵力、身法]
count_base_attr(Player_meridian)->
	_Add5 = 30,
	_Add10 = 60,
	_Add15 = 120,
	_Add20 = 200,
	_Add25 = 300,
	{_Val1,MLev1,GLev1} = count_attr(Player_meridian,1),
	{_Val2,MLev2,GLev2} = count_attr(Player_meridian,2),
	{_Val3,MLev3,GLev3} = count_attr(Player_meridian,3),
	{_Val4,MLev4,GLev4} = count_attr(Player_meridian,4),
	{_Val5,MLev5,GLev5} = count_attr(Player_meridian,5),
	{_Val6,MLev6,GLev6} = count_attr(Player_meridian,6),
	{_Val7,MLev7,GLev7} = count_attr(Player_meridian,7),
	{_Val8,MLev8,GLev8} = count_attr(Player_meridian,8),
	{_Val9,MLev9,GLev9} = count_attr(Player_meridian,9),
	{_Val10,MLev10,GLev10} = count_attr(Player_meridian,10),
	MMin = lists:min([MLev1,MLev2,MLev3,MLev4,MLev5,MLev6,MLev7,MLev8,MLev9,MLev10]),
	GMin = lists:min([GLev1,GLev2,GLev3,GLev4,GLev5,GLev6,GLev7,GLev8,GLev9,GLev10]),
	if
%		MMin>=80 andalso GMin>=20->
%			[_Add20,_Add20,_Add20,_Add20];
%		MMin>=70 andalso GMin>=16->
%			[_Add16,_Add16,_Add16,_Add16];
%		MMin>=60 andalso GMin>=13->
%			[_Add13,_Add13,_Add13,_Add13];
%		MMin>=50 andalso GMin>=10->
%			[_Add10,_Add10,_Add10,_Add10];
%		MMin>=40 andalso GMin>=6->
%			[_Add6,_Add6,_Add6,_Add6];
%		MMin>=30 andalso GMin>=3->
%			[_Add3,_Add3,_Add3,_Add3];


		MMin>=0 andalso GMin>=25->
			[_Add25,_Add25,_Add25,_Add25];
        MMin>=0 andalso GMin>=20->
            [_Add20,_Add20,_Add20,_Add20];
		MMin>=0 andalso GMin>=15->
			[_Add15,_Add15,_Add15,_Add15];
		MMin>=0 andalso GMin>=10->
			[_Add10,_Add10,_Add10,_Add10];
		MMin>=0 andalso GMin>=5->
			[_Add5,_Add5,_Add5,_Add5];
		true->
			[0,0,0,0]
	end.
count_attr(Player_meridian,MMid)->
	%%检测是否有正在修行的脉(有CD时间，需要降级)
	Mid = Player_meridian#player_meridian.mid,
	case Mid of
		0->	%无正在修炼的元神
			Miding = 0,
			IsCDing = 0;
		_-> %检测是否已修炼完成
			T_Lev = lib_meridian:get_mer_level(Player_meridian,Mid),
			T_D = lib_meridian:get_data_meridian(Mid,T_Lev),
			if
				T_D=:=#data_meridian{} ->
					Miding = 0, 
					IsCDing = 0;
                true -> 
					GapTime = util:unixtime()-Player_meridian#player_meridian.cdtime,
					if
						T_D#data_meridian.need_cd<GapTime->
							Miding = Mid,
							IsCDing = 0;
						true->
							Miding = Mid,
							IsCDing = 1
					end
			end
	end,
	case IsCDing of
		1->
			if
				Miding=:=MMid->
					Flag = true;
				true->Flag = false
			end;
		_->Flag = false
	end,
	_MLev = get_mer_level(Player_meridian,MMid),
	case Flag of
		false->MLev = _MLev;
		true -> MLev = _MLev %%MLev = _MLev-1	
	end,
	GLev = get_gen_level(Player_meridian,MMid),
	Data_meridian = get_data_meridian(MMid,MLev),
	Data_meridian_gen = get_data_meridian_gen(MMid,GLev),
	Mer_add = (Data_meridian#data_meridian.nvalue*(100+Data_meridian_gen#data_meridian_gen.addrate)) div 100,
	Gen_add = Data_meridian_gen#data_meridian_gen.add,
	{{Mer_add,Gen_add},MLev,GLev}.
count_attr_0(Player_meridian)->
	%%检测是否有正在修行的脉(有CD时间，需要降级)
	Mid = Player_meridian#player_meridian.mid,
	case Mid of
		0->	%无正在修炼的元神
			Miding = 0,
			IsCDing = 0;
		_-> %检测是否已修炼完成
			T_Lev = lib_meridian:get_mer_level(Player_meridian,Mid),
			T_D = lib_meridian:get_data_meridian(Mid,T_Lev),
			if
				T_D=:=#data_meridian{} ->
					Miding = 0, 
					IsCDing = 0;
                true -> 
					GapTime = util:unixtime()-Player_meridian#player_meridian.cdtime,
					if
						T_D#data_meridian.need_cd<GapTime->
							Miding = Mid,
							IsCDing = 0;
						true->
							Miding = Mid,
							IsCDing = 1
					end
			end
	end,
	case IsCDing of
		1->
			if
				Miding=:=1->
					Flag = true;
				true->Flag = false
			end;
		_->Flag = false
	end,
	_MLev = get_mer_level(Player_meridian,1),
	case Flag of
		false->MLev = _MLev;
		true ->  MLev = _MLev   %% MLev = _MLev-1	
	end,
	GLev = get_gen_level(Player_meridian,1),
	Data_meridian = get_data_meridian(0,MLev),
	Data_meridian_gen = get_data_meridian_gen(0,GLev),
	Mer_add = (Data_meridian#data_meridian.nvalue*(100+Data_meridian_gen#data_meridian_gen.addrate)) div 100,
	Gen_add = Data_meridian_gen#data_meridian_gen.add,
	{{Mer_add,Gen_add},MLev,GLev}.

%%检测玩家是否已达成内功修炼前置条件
%%@param Player_meridian 内功元组
%%@param Preconditon 内功前置条件列表
%%@return true|false
check_mer_preconditon(Player_meridian,Preconditon)->
	case Preconditon of
		[] -> true;
		Others ->
			[H|T] = Others,
			{Mid,TargetLev} = H,
			Lev = get_mer_level(Player_meridian,Mid),
			if
				Lev<TargetLev ->false;
				true -> 
					check_mer_preconditon(Player_meridian,T)
			end
	end.

%% 获取对应内力当前等级
%% @param Player_meridian 玩家内力境界对象
%% @param MeridianId 1-10脉
%% @return Value int
get_mer_level(Player_meridian,MeridianId)->
	case MeridianId of
		0->Player_meridian#player_meridian.sudatt;  
		6->Player_meridian#player_meridian.hpmp;        %%气血内功等级    
		2->Player_meridian#player_meridian.def;       %%防御内功等级
		3->Player_meridian#player_meridian.doom;      %%命中内功等级
		4->Player_meridian#player_meridian.jook;      %%闪避内功等级
		5->Player_meridian#player_meridian.tenacity;  %%坚韧内功等级
		1->Player_meridian#player_meridian.sudatt;    %%暴击内功等级
		7->Player_meridian#player_meridian.att;       %%攻击内功等级
		8->Player_meridian#player_meridian.firedef;   %%火坑内功等级
		9->Player_meridian#player_meridian.icedef;   %%冰抗内功等级
		10->Player_meridian#player_meridian.drugdef   %%毒抗内功等级
	end.

%% 获取对应境界当前等级
%% @param Player_meridian 玩家内力境界对象
%% @param MeridianId 1-10脉
%% @return Value int
get_gen_level(Player_meridian,MeridianId)->
	case MeridianId of
		0->Player_meridian#player_meridian.gsudatt;
		6->Player_meridian#player_meridian.ghpmp;      %%气血内功等级    
		2->Player_meridian#player_meridian.gdef;       %%防御内功等级
		3->Player_meridian#player_meridian.gdoom;      %%命中内功等级
		4->Player_meridian#player_meridian.gjook;      %%闪避内功等级
		5->Player_meridian#player_meridian.gtenacity;  %%坚韧内功等级
		1->Player_meridian#player_meridian.gsudatt;    %%暴击内功等级
		7->Player_meridian#player_meridian.gatt;       %%攻击内功等级
		8->Player_meridian#player_meridian.gfiredef;   %%火坑内功等级
		9->Player_meridian#player_meridian.gicedef;    %%冰抗内功等级
		10->Player_meridian#player_meridian.gdrugdef   %%毒抗内功等级
	end.

%% 获取对应境界附加成功率
%% @param Player_meridian 玩家内力境界对象
%% @param MeridianId 1-11脉
%% @return Value int
get_gen_rate(Player_meridian,MeridianId)->
	case MeridianId of
		0->Player_meridian#player_meridian.grsudatt;
		6->Player_meridian#player_meridian.grhprmp;        %%气血内功等级    
		2->Player_meridian#player_meridian.grdef;       %%防御内功等级
		3->Player_meridian#player_meridian.grdoom;      %%命中内功等级
		4->Player_meridian#player_meridian.grjook;      %%闪避内功等级
		5->Player_meridian#player_meridian.grtenacity;  %%坚韧内功等级
		1->Player_meridian#player_meridian.grsudatt;    %%暴击内功等级
		7->Player_meridian#player_meridian.gratt;       %%攻击内功等级
		8->Player_meridian#player_meridian.grfiredef;   %%火坑内功等级
		9->Player_meridian#player_meridian.gricedef;   %%冰抗内功等级
		10->Player_meridian#player_meridian.grdrugdef   %%毒抗内功等级
	end.


%%获取一个经脉产品数据
%%@param Type 经脉类型 1-8
%%@param Level 经脉级别 1-17
%%@return #data_meridian
get_data_meridian(MType,Level)->
	case data_meridian:get(MType,Level) of
		[] -> #data_meridian{};
		L ->list_to_tuple([data_meridian|L])
    end.

%%获取一个根骨产品数据
%%@param Level 经脉级别 1-20
%%@return #data_meridian_gen
get_data_meridian_gen(GType,Level)->
	case data_meridian_gen:get(GType,Level) of
		[] -> #data_meridian_gen{};
		L ->
			list_to_tuple([data_meridian_gen|L])
    end.
	
%% 返回经脉系统所有数据
%%@param Player_meridian 玩家内功元组
%%@param Type 1:内功 2境界
%%@param MeridianId 内功类型ID  1~10
%%@return [....]
getMers(PlayerStatus,Player_meridian,Type,TMid)->
	%%检测是否有正在修行的脉
	Mid = Player_meridian#player_meridian.mid,
    %%io:format("meridian:~p~n",[[?MODULE,?LINE,Mid]]),
	case Mid of
		0->	%无正在修炼的元神
			Miding = 0,
			RestCdTime = 0,
			IsCDing = 0;
		_-> %检测是否已修炼完成
			T_Lev = lib_meridian:get_mer_level(Player_meridian,Mid),
			T_D = lib_meridian:get_data_meridian(Mid,T_Lev),
			if
				T_D=:=#data_meridian{} ->
					Miding = 0, 
					RestCdTime = 0,
					IsCDing = 0;
                true -> 
					GapTime = util:unixtime()-Player_meridian#player_meridian.cdtime,
					if
						T_D#data_meridian.need_cd<GapTime->
							Miding = Mid,
							RestCdTime = 0,
							IsCDing = 0;
						true->
							Miding = Mid,
							RestCdTime = T_D#data_meridian.need_cd-GapTime,
							IsCDing = 1
					end
			end
	end,
	if
		TMid=:=0 -> %%需要计算出第一个可修行内功信息，如果没有，取0值
            case Type of
				1->
					case IsCDing of
						1->
                            TTMid=Mid;
						_->
                            TTMid = get_next_upmer_id(PlayerStatus,Player_meridian,1)
					end;
				2->
					TTMid = 1
			end;
		true->
			TTMid = TMid
	end,
    [_Name|M] = tuple_to_list(Player_meridian),
	[Uid|T] = M,
	{JJType,_Val} = lib_meridian:count_attr(Player_meridian),
    %%io:format("2222222222meridian:~p~n",[[?LINE,Uid,Type,1,JJType,TTMid,Miding,RestCdTime]]),
	lists:append([[Uid,Type,1,JJType,TTMid],T,
				 [Miding,RestCdTime]]).

%%计算可升级的内功类型
%%@param Player_meridian 玩家内功元组
%%@param MeridianId 内功类型ID  1~10
%%@return 0~10 可修炼的脉(0值为不可修炼)  
get_next_upmer_id(PlayerStatus,Player_meridian,MeridianId)->
    %%io:format("lib_meridian:~p~n",[[?MODULE,?LINE,MeridianId]]),
    if
        MeridianId=:=11 -> 
            case lib_meridian:get_mer_level(Player_meridian,10) >=?MERIDIAN_MAX_LV of
                true -> 10;
                false -> 1
            end;
        true->
            Lev = lib_meridian:get_mer_level(Player_meridian,MeridianId),
            if
                %%检查是否已达最高级
                Lev>=?MERIDIAN_MAX_LV ->
                    get_next_upmer_id(PlayerStatus,Player_meridian,MeridianId+1);
                true ->
                    %%检测是否满足产品条件
                    D = lib_meridian:get_data_meridian(MeridianId,Lev+?MER_UP_GAP),
                    if
                        D=:=#data_meridian{} -> 
                            get_next_upmer_id(PlayerStatus,Player_meridian,MeridianId+1);
                        true -> 
                            %%检测玩家前置内功是否达到要求
                            case lib_meridian:check_mer_preconditon(Player_meridian,D#data_meridian.preconditon) of
                                false->
                                    get_next_upmer_id(PlayerStatus,Player_meridian,MeridianId+1);
                                true->
                                    MeridianId
                            end
                    end
            end
    end.



%%计算可升级的内功类型
%%@param Player_meridian 玩家内功元组
%%@param MeridianId 内功类型ID  1~10
%%@return 0~10 可修炼的脉(0值为不可修炼)  
get_can_up_merType(PlayerStatus,Player_meridian,MeridianId)->
	if
		MeridianId=:=11 -> 
            get_first_up_mer(Player_meridian);
		true->
			Lev = lib_meridian:get_mer_level(Player_meridian,MeridianId),
			if
				%%检查是否已达最高级
				Lev>=?MERIDIAN_MAX_LV ->
					get_can_up_merType(PlayerStatus,Player_meridian,MeridianId+1);
				true ->
					%%检测是否满足产品条件
					D = lib_meridian:get_data_meridian(MeridianId,Lev+?MER_UP_GAP),
					if
						D=:=#data_meridian{} -> 
							get_can_up_merType(PlayerStatus,Player_meridian,MeridianId+1);
		                true -> 
							if
								%%检测玩家等级
								D#data_meridian.need_level>PlayerStatus#player_status.lv ->
									get_can_up_merType(PlayerStatus,Player_meridian,MeridianId+1);
								true->
									%%检测玩家前置内功是否达到要求
									case lib_meridian:check_mer_preconditon(Player_meridian,D#data_meridian.preconditon) of
										false->
											get_can_up_merType(PlayerStatus,Player_meridian,MeridianId+1);
										true->
											if
												%%检测历练声望
												D#data_meridian.need_llpt>PlayerStatus#player_status.llpt ->
													get_can_up_merType(PlayerStatus,Player_meridian,MeridianId+1);
												true->
													if
														%%检测金钱
														D#data_meridian.need_coin>(PlayerStatus#player_status.coin+PlayerStatus#player_status.bcoin) ->
															get_can_up_merType(PlayerStatus,Player_meridian,MeridianId+1);
														true->
															if
																%%检测武魂
																D#data_meridian.need_whpt>PlayerStatus#player_status.whpt->
																	get_can_up_merType(PlayerStatus,Player_meridian,MeridianId+1);
																true->
																	MeridianId
															end
													end
											end
									end
							end
					end
		    end
	end.

get_first_up_mer(Player_meridian) ->
    
    Mid = Player_meridian#player_meridian.mid,
    Lev = lib_meridian:get_mer_level(Player_meridian,Mid),
    if
        %%检查是否已达最高级
        Lev>=?MERIDIAN_MAX_LV ->
            case Mid >= 10 of
                true ->
                    10;
                false ->
                    Mid + 1
            end;
        true ->
            case Mid >= 10 of
                true ->
                    1;
                false ->
                    case Mid =< 1 of
                        true ->
                            1;
                        false ->
                            Mid + 1
                    end
            end
    end.
    


%%查找玩家的经脉信息
find(Uid)->
	db:get_row(io_lib:format(<<"select * from meridian where uid = ~p">>, [Uid])).

%%插入记录
insert(Uid)->
    Sql = io_lib:format(<<"insert into meridian(uid) values(~p)">>, [Uid]),
	db:execute(Sql).

%%更新玩家内功境界数据
%%@param Player_meridian 玩家内功境界元组
update(Player_meridian,Type,Mid,Lev,Rate,NMid)->
	NowTime = util:unixtime(),
	case Type of
		1 ->
			case Mid of
				6->NPlayer_meridian = Player_meridian#player_meridian{hpmp=Lev,mid=NMid,cdtime=NowTime};        %%气血内功等级    
				2->NPlayer_meridian = Player_meridian#player_meridian{def=Lev,mid=NMid,cdtime=NowTime};       %%防御内功等级
				3->NPlayer_meridian = Player_meridian#player_meridian{doom=Lev,mid=NMid,cdtime=NowTime};      %%命中内功等级
				4->NPlayer_meridian = Player_meridian#player_meridian{jook=Lev,mid=NMid,cdtime=NowTime};      %%闪避内功等级
				5->NPlayer_meridian = Player_meridian#player_meridian{tenacity=Lev,mid=NMid,cdtime=NowTime};  %%坚韧内功等级
				1->NPlayer_meridian = Player_meridian#player_meridian{sudatt=Lev,mid=NMid,cdtime=NowTime};    %%暴击内功等级
				7->NPlayer_meridian = Player_meridian#player_meridian{att=Lev,mid=NMid,cdtime=NowTime};       %%攻击内功等级
				8->NPlayer_meridian = Player_meridian#player_meridian{firedef=Lev,mid=NMid,cdtime=NowTime};   %%火坑内功等级
				9->NPlayer_meridian = Player_meridian#player_meridian{icedef=Lev,mid=NMid,cdtime=NowTime};   %%冰抗内功等级
				10->NPlayer_meridian = Player_meridian#player_meridian{drugdef=Lev,mid=NMid,cdtime=NowTime}   %%毒抗内功等级
			end;
		2 ->
			case Mid of
				6->NPlayer_meridian = Player_meridian#player_meridian{ghpmp=Lev,grhprmp=Rate};        %%气血内功等级    
				2->NPlayer_meridian = Player_meridian#player_meridian{gdef=Lev,grdef=Rate};       %%防御内功等级
				3->NPlayer_meridian = Player_meridian#player_meridian{gdoom=Lev,grdoom=Rate};      %%命中内功等级
				4->NPlayer_meridian = Player_meridian#player_meridian{gjook=Lev,grjook=Rate};      %%闪避内功等级
				5->NPlayer_meridian = Player_meridian#player_meridian{gtenacity=Lev,grtenacity=Rate};  %%坚韧内功等级
				1->NPlayer_meridian = Player_meridian#player_meridian{gsudatt=Lev,grsudatt=Rate};    %%暴击内功等级
				7->NPlayer_meridian = Player_meridian#player_meridian{gatt=Lev,gratt=Rate};       %%攻击内功等级
				8->NPlayer_meridian = Player_meridian#player_meridian{gfiredef=Lev,grfiredef=Rate};   %%火坑内功等级
				9->NPlayer_meridian = Player_meridian#player_meridian{gicedef=Lev,gricedef=Rate};   %%冰抗内功等级
				10->NPlayer_meridian = Player_meridian#player_meridian{gdrugdef=Lev,grdrugdef=Rate}   %%毒抗内功等级
			end
	end,
	[_Name|L] = tuple_to_list(NPlayer_meridian),
	[Uid|Value] = L,
	Params = Value ++ [Uid],
	Sql = io_lib:format(<<"update meridian set 		
						  `hpmp`=~p,
						  `def`=~p,
						  `doom`=~p,
						  `jook`=~p,
						  `tenacity`=~p,
						  `sudatt`=~p,
						  `att`=~p,
						  `firedef`=~p,
						  `icedef`=~p,
						  `drugdef`=~p,
						  `ghpmp`=~p,
						  `gdef`=~p,
						  `gdoom`=~p,
						  `gjook`=~p,
						  `gtenacity`=~p,
						  `gsudatt`=~p,
						  `gatt`=~p,
						  `gfiredef`=~p,
						  `gicedef`=~p,
						  `gdrugdef`=~p,
						  `grhprmp`=~p,
						  `grdef`=~p,
						  `grdoom`=~p,
						  `grjook`=~p,
						  `grtenacity`=~p,
						  `grsudatt`=~p,
						  `gratt`=~p,
						  `grfiredef`=~p,
						  `gricedef`=~p,
						  `grdrugdef`=~p,
						  mid = ~p,
						  cdtime=~p,
						  `thpmp`=~p,
						  `tdef`=~p,
						  `tdoom`=~p,
						  `tjook`=~p,
						  `ttenacity`=~p,
						  `tsudatt`=~p,
						  `tatt`=~p,
						  `tfiredef`=~p,
						  `ticedef`=~p,
						  `tdrugdef`=~p
						where `uid`=~p">>,Params),
	db:execute(Sql),
	NPlayer_meridian.

%%去除CD时间专用
update_mid_to_0(Uid)->
	Sql = io_lib:format(<<"update meridian set mid =0 where uid = ~p">>,[Uid]),
	db:execute(Sql).
    
%%将数据库记录转成ets记录。
write_player_meridian([
					  Uid,       %%玩家ID,
					  HpMp,        %%气血内功等级,
					  Def,       %%防御内功等级,
					  Doom,      %%命中内功等级,
					  Jook,      %%闪避内功等级,
					  Tenacity,  %%坚韧内功等级,
					  Sudatt,    %%暴击内功等级,
					  Att,       %%攻击内功等级,
					  Firedef,   %%火坑内功等级,
					  Icedef,    %%冰抗内功等级,
					  Drugdef,   %%毒抗内功等级,
					  GHpMp,       %%气血境界等级,
					  Gdef,      %%防御境界等级,
					  Gdoom,     %%命中境界等级,
					  Gjook,     %%闪避境界等级,
					  Gtenacity, %%坚韧境界等级,
					  Gsudatt,   %%暴击境界等级,
					  Gatt,      %%攻击境界等级,
					  Gfiredef,  %%火坑境界等级,
					  Gicedef,   %%冰抗境界等级,
					  Gdrugdef,  %%毒抗境界等级,
					  GRhpRmp,      %%气血境界附加成功率,
					  Grdef,     %%防御境界附加成功率,
					  Grdoom,    %%命中境界附加成功率,
					  Grjook,    %%闪避境界附加成功率,
					  Grtenacity,%%坚韧境界附加成功率,
					  Grsudatt,  %%暴击境界附加成功率,
					  Gratt,     %%攻击境界附加成功率,
					  Grfiredef, %%火坑境界附加成功率,
					  Gricedef,  %%冰抗境界附加成功率,
					  Grdrugdef,  %%毒抗境界附加成功率
					  Mid,        %%元神类型
					  Cdtime,	  %%CD时间
					  Thpmp,
					  Tdef,
					  Tdoom,
					  Tjook,
					  Ttenacity,
					  Tsudatt,
					  Tatt,
					  Tfiredef,
					  Ticedef,
					  Tdrugdef
        			])->
	#player_meridian{
          uid=Uid,       %%玩家ID,
		  hpmp=HpMp,        %%气血内功等级,
		  def=Def,       %%防御内功等级,
		  doom=Doom,      %%命中内功等级,
		  jook=Jook,      %%闪避内功等级,
		  tenacity=Tenacity,  %%坚韧内功等级,
		  sudatt=Sudatt,    %%暴击内功等级,
		  att=Att,       %%攻击内功等级,
		  firedef=Firedef,   %%火坑内功等级,
		  icedef=Icedef,    %%冰抗内功等级,
		  drugdef=Drugdef,   %%毒抗内功等级,
		  ghpmp=GHpMp,       %%气血境界等级,
		  gdef=Gdef,      %%防御境界等级,
		  gdoom=Gdoom,     %%命中境界等级,
		  gjook=Gjook,     %%闪避境界等级,
		  gtenacity=Gtenacity, %%坚韧境界等级,
		  gsudatt=Gsudatt,   %%暴击境界等级,
		  gatt=Gatt,      %%攻击境界等级,
		  gfiredef=Gfiredef,  %%火坑境界等级,
		  gicedef=Gicedef,   %%冰抗境界等级,
		  gdrugdef=Gdrugdef,  %%毒抗境界等级,
		  grhprmp=GRhpRmp,      %%气血境界附加成功率,
		  grdef=Grdef,     %%防御境界附加成功率,
		  grdoom=Grdoom,    %%命中境界附加成功率,
		  grjook=Grjook,    %%闪避境界附加成功率,
		  grtenacity=Grtenacity,%%坚韧境界附加成功率,
		  grsudatt=Grsudatt,  %%暴击境界附加成功率,
		  gratt=Gratt,     %%攻击境界附加成功率,
		  grfiredef=Grfiredef, %%火坑境界附加成功率,
		  gricedef=Gricedef,  %%冰抗境界附加成功率,
		  grdrugdef=Grdrugdef,  %%毒抗境界附加成功率
		  mid=Mid,				%%元神类型
		  cdtime = Cdtime,		%%CD时间
		  thpmp=Thpmp,
		  tdef=Tdef,
		  tdoom=Tdoom,
		  tjook=Tjook,
		  ttenacity=Ttenacity,
		  tsudatt=Tsudatt,
		  tatt=Tatt,
		  tfiredef=Tfiredef,
		  ticedef=Ticedef,
		  tdrugdef=Tdrugdef
        }.
 