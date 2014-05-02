%% Author: zengzhaoyuan
%% Created: 2012-6-7
%% Description: TODO: 本文件方法，只适合游戏线内部调用

-module(lib_player_server).
-include("server.hrl").
-include("unite.hrl").
-export([
	get_unite_status_attr/2,
	use_arena_score/2,
	use_factionwar_score/2,
	execute_13001/1,
	execute_13004/2,
	get_opt_time/2,
	set_opt_time/3,
	get_player_statue/1,
	get_player_statue_offline/1
]).

%%获取公共性状态单个属性
%%@param UnitePid 公共线线程Pid  #player_status.unite_pid
%%@param AttrName #unite_status的属性原子名称。
%%@return {error,Reson} | {ok,Value}   Value 的对应值
get_unite_status_attr(UnitePid,AttrName)->
	case is_pid(UnitePid) andalso misc:is_process_alive(UnitePid) of
		false->{error,no_unite_pid};
		true->gen_server:call(UnitePid, {get_unite_status_attr,AttrName})
	end.

%%使用竞技场积分
%%@param PlayerStatus #player_status
%%@parama UsedScore 兑换积分值
%%@return {error,Reson} | {ok,{Pre_Rest_Score(使用之前的剩余竞技积分),Rest_Score(剩余竞技场积分),New_PlayerStatus}}
use_arena_score(PlayerStatus,UsedScore) ->
	Arena = PlayerStatus#player_status.arena,
	Pre_Rest_Score = Arena#status_arena.arena_score_total-Arena#status_arena.arena_score_used,
	if
		Pre_Rest_Score < UsedScore->
			{error,no_enough_arena_score};
		true->
			New_Arena = Arena#status_arena{arena_score_used=Arena#status_arena.arena_score_used+UsedScore},
			New_Status = PlayerStatus#player_status{arena=New_Arena},
			lib_arena_new:update_arena_used_score(PlayerStatus#player_status.id,UsedScore),
			Rest_Score = New_Arena#status_arena.arena_score_total-New_Arena#status_arena.arena_score_used,
			{ok,{Pre_Rest_Score,Rest_Score,New_Status}}
	end.

%%使用竞技场积分
%%@param PlayerStatus #player_status
%%@parama UsedScore 兑换积分值
%%@return {error,Reson} | {ok,{Pre_Rest_Score(使用之前的剩余竞技积分),Rest_Score(剩余竞技场积分),New_PlayerStatus}}
use_factionwar_score(PlayerStatus,UsedScore) ->
	Factionwar = PlayerStatus#player_status.factionwar,
	Pre_Rest_Score = Factionwar#status_factionwar.war_score-Factionwar#status_factionwar.war_score_used,
	if
		Pre_Rest_Score < UsedScore->
			{error,no_enough_factionwar_score};
		true->
			New_Factionwar = Factionwar#status_factionwar{war_score_used=Factionwar#status_factionwar.war_score_used+UsedScore},
			New_Status = PlayerStatus#player_status{factionwar=New_Factionwar},
			lib_factionwar:update_factionwar_used_score(PlayerStatus#player_status.id,UsedScore),
			Rest_Score = New_Factionwar#status_factionwar.war_score-New_Factionwar#status_factionwar.war_score_used,
			{ok,{Pre_Rest_Score,Rest_Score,New_Status}}
	end.

%%执行刷新任务属性13001，抽取出来，供大伙使用。
%%@param Status #player_status
execute_13001(Status)->
	{ok, BinData} = pt_130:write(13001, Status),
    lib_server_send:send_one(Status#player_status.socket, BinData).

%%执行、刷新人物属性13004，抽取出来，以供可重复利用。
%%@param Status #player_status
%%@param Id 玩家ID
%%@return 会发送13004协议
execute_13004(Status,Id)->
	UserStatus = case Status#player_status.id =:= Id of
	    true -> Status;
	    false -> lib_player:get_player_info(Id)
	end,
	case is_record(UserStatus, player_status) of
        false -> 
            {ok, BinData} = pt_130:write(13004, []),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        _ ->
            C = UserStatus#player_status.chengjiu,
            Vip = UserStatus#player_status.vip,
            Gs = UserStatus#player_status.guild,
            Pk = UserStatus#player_status.pk,
            Go = UserStatus#player_status.goods,
            Dict = lib_goods_dict:get_player_dict_by_goods_pid(Go#status_goods.goods_pid),
            case  Dict =/= [] of
                true ->
                    SuitList = lib_goods_util:get_suit_id_and_num(UserStatus#player_status.id, Dict);
                false ->
                    SuitList = [{0,0},{0,0},{0,0}]
            end,
			Arena = UserStatus#player_status.arena,
			Factionwar = UserStatus#player_status.factionwar,
            case UserStatus#player_status.marriage#status_marriage.register_time of
                0 -> 
                    ParnerId = 0,
                    ParnerName = "";
                _ ->
                    ParnerId = UserStatus#player_status.marriage#status_marriage.parner_id,
                    ParnerName = UserStatus#player_status.marriage#status_marriage.parner_name
            end,
            {ok, BinData} = pt_130:write(13004, [
                    UserStatus#player_status.id,
                    UserStatus#player_status.hp,
                    UserStatus#player_status.hp_lim,
                    UserStatus#player_status.mp,
                    UserStatus#player_status.mp_lim,
                    UserStatus#player_status.sex,
                    UserStatus#player_status.lv,
                    UserStatus#player_status.career,
                    UserStatus#player_status.nickname,
                    UserStatus#player_status.att,
                    UserStatus#player_status.def,
                    UserStatus#player_status.hit,
                    UserStatus#player_status.dodge,
                    UserStatus#player_status.crit,
                    UserStatus#player_status.ten,
                    Gs#status_guild.guild_id,
                    Gs#status_guild.guild_name,
                    Gs#status_guild.guild_position,
                    UserStatus#player_status.realm,
                    0, %% 这是灵力，已经没用
                    UserStatus#player_status.jobs,
                    Pk#status_pk.pk_value,
                    UserStatus#player_status.forza,
                    UserStatus#player_status.agile,
                    UserStatus#player_status.wit,
                    UserStatus#player_status.thew,
                    UserStatus#player_status.fire,
                    UserStatus#player_status.ice,
                    UserStatus#player_status.drug,
                    UserStatus#player_status.llpt,
                    UserStatus#player_status.xwpt,
                    UserStatus#player_status.fbpt,
                    UserStatus#player_status.fbpt2,
                    UserStatus#player_status.bppt,
                    UserStatus#player_status.gjpt,
                    Vip#status_vip.vip_type,
                    C#status_chengjiu.honour,
                    UserStatus#player_status.mlpt,
                    Go#status_goods.equip_current,
                    Go#status_goods.stren7_num,
                    Go#status_goods.suit_id,
                    UserStatus#player_status.combat_power,
                    Go#status_goods.fashion_weapon,
                    Go#status_goods.fashion_armor,
                    Go#status_goods.fashion_accessory,
                    Go#status_goods.hide_fashion_weapon,
                    Go#status_goods.hide_fashion_armor,
                    Go#status_goods.hide_fashion_accessory, 
                    SuitList,
					Arena#status_arena.arena_score_total-Arena#status_arena.arena_score_used,
					UserStatus#player_status.whpt,
					Factionwar#status_factionwar.war_score-Factionwar#status_factionwar.war_score_used,
                    ParnerId,
                    ParnerName,
                    Go#status_goods.fashion_head, Go#status_goods.fashion_tail, Go#status_goods.fashion_ring,
                    Go#status_goods.hide_head, Go#status_goods.hide_tail, Go#status_goods.hide_ring,
                    UserStatus#player_status.get_praise,
                    UserStatus#player_status.picture
                ]),
            lib_server_send:send_one(Status#player_status.socket, BinData)
    end.

%% 获取操作时间
%% 一般可用于判断是否操作过快或其他
get_opt_time(PS, Key) ->
	if 
		Key =:= card ->
			PS#player_status.opt_time#status_opt_time.card;
		Key =:= newer_card ->
			PS#player_status.opt_time#status_opt_time.newer_card;
		true ->
			0
	end.

%% 设置操作时间
%% 一般可用于判断是否操作过快或其他
set_opt_time(PS, Key, Value) ->
	if 
		Key =:= card ->
			Opt = PS#player_status.opt_time,
			NewOpt = Opt#status_opt_time{card = Value},
			PS#player_status{opt_time = NewOpt};
		Key =:= newer_card ->
			Opt = PS#player_status.opt_time,
			NewOpt = Opt#status_opt_time{newer_card = Value},
			PS#player_status{opt_time = NewOpt};
		true ->
			PS
	end.

%% 构造玩家雕像数据
%% 如果要将数据入库，需要先转换：util:term_to_bitstring(该方法的返回值)
get_player_statue(PS) ->
	[Weapon, Cloth , _, WLight, _CLight | _] = PS#player_status.goods#status_goods.equip_current, 
	ShiZhuang = [
		PS#player_status.goods#status_goods.fashion_weapon, 
		PS#player_status.goods#status_goods.fashion_armor, 
		PS#player_status.goods#status_goods.fashion_accessory
	],
	[
		PS#player_status.id, PS#player_status.lv, PS#player_status.realm, PS#player_status.career, 
		PS#player_status.sex, Weapon, Cloth, WLight, 
		PS#player_status.goods#status_goods.stren7_num, ShiZhuang, 
		PS#player_status.goods#status_goods.suit_id, 
		PS#player_status.vip#status_vip.vip_type, 
		PS#player_status.nickname
	].

%% 构造玩家雕像数据
%% 如果要将数据入库，需要先转换：util:term_to_bitstring(该方法的返回值)
get_player_statue_offline(_RoleId) ->
	[].
