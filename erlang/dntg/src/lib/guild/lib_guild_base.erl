%% --------------------------------------------------------
%% @Module:           |lib_guild_base
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-05-00
%% @Description:      |帮派基础功能_包括_初始化_ETS构造与操作_定时任务 
%% --------------------------------------------------------
-module(lib_guild_base).

-include("common.hrl").
-include("record.hrl").
-include("server.hrl").
-include("goods.hrl").
-include("guild.hrl").
-include("sql_guild.hrl").
-include("unite.hrl").
-include("scene.hrl").
-include("sql_player.hrl").

-compile(export_all).

%% -----------------------------------------------------------------
%% 系统启动时初始化帮派相关信息
%% -----------------------------------------------------------------
init_guild() ->
	load_all_guild().

%% -----------------------------------------------------------------
%% 加载所有帮派_系统启动时调用
%% -----------------------------------------------------------------
load_all_guild() ->
	NowTime = util:unixtime(),
	{_Today, NextDay} = util:get_midnight_seconds(NowTime),
	put(gms_time, {_Today, NextDay}),
	put(gms_nowtime, NowTime),
	SQL0  = io_lib:format(?SQL_GUILD_SELECT_IDS, []),
	GuildIds = db:get_all(SQL0),
	GuildDict = dict:new(),
	%% 获取记录总数
	GuildDictNew =load_guild_loop(GuildIds, GuildDict),
	GuildDictNew.

load_guild_loop([], GuildDict)->
	GuildDict;
load_guild_loop(GuildIds, GuildDict)->
	[[OneGuildId]|GuildIdsNext] = GuildIds,
	SQL0  = io_lib:format(?SQL_GUILD_SELECT_110, [OneGuildId]),
	GuildList = db:get_all(SQL0),
	GuildDictNew = load_guild_init([GuildList, GuildDict, 0]),
	timer:sleep(10),
	load_guild_loop(GuildIdsNext, GuildDictNew).



%% 初始化帮派成员(只能在帮派进程中调用)
init_all_guild_member(GuildId) ->
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_SELECT_ALL, [GuildId]),
    _GuildMemberList = db:get_all(SQL), 
    F = fun([Id,Name,_GuildId,GuildName,DonateTotal,DonateTotalCard,DonateTotalCoin,DonateLastTime,DonateTotalLastDay,DonateTotalLastWeek,PaidGetLastTime,CreateTime,Title,Remark,Honor,DepotStoreLastTime,DepotStoreNum,Position,Version,Donate,PaidAdd, Sex, Level, Career, Image, Material, FurnaceBack, FurnaceDailyBack]) ->
                SQL2 = io_lib:format(?SQL_PLAYER_LOGIN_SELECT_LAST_LOGIN_TIME, [Id]),
                LastLoginTime = db:get_one(SQL2),
                SQL3 = io_lib:format(?sql_player_vip_data, [Id]),
                [_VipType, _VipTime, _VipBagFlag] = db:get_row(SQL3),
                %% 帮派战信息
                FactionWar = lib_factionwar:load_player_factionwar_guild(Id),
                [Id,Name,_GuildId,GuildName,DonateTotal,DonateTotalCard,DonateTotalCoin,DonateLastTime,DonateTotalLastDay,DonateTotalLastWeek,PaidGetLastTime,CreateTime,Title,Remark,Honor,DepotStoreLastTime,DepotStoreNum,Position,Version,Donate,PaidAdd, Sex, Level, Career, LastLoginTime, Image, _VipType, Material, FurnaceBack, FurnaceDailyBack, FactionWar]
        end,
    GuildMemberList = lists:map(F, _GuildMemberList),
	case GuildMemberList of
		[] ->
			[];
		_ ->
			lists:foreach(fun load_guild_member_init/1, GuildMemberList),
			GuildMemberList
	end.

%% 初始化帮派成员(只能在帮派进程中调用)
load_guild_member_init(GuildMemberInfo) ->
	GuildMember = make_record(guild_member, GuildMemberInfo),
	mod_guild_call:update_guild_member([start, GuildMember]).

%% 初始化帮派信息 (只能在帮派进程中调用)
load_guild_init([[], Guild_Dict, _I]) ->
	Guild_Dict;
load_guild_init([GuildList, Guild_Dict, _I]) ->
	_I2 = _I + 1,
	[GuildInfo|GuildList_Left] = GuildList,
	[G_Id|_] = GuildInfo,
	New_Guild_Dict = case init_all_guild_member(G_Id) of
		[] ->
			delete_exception_guild(G_Id),
			Guild_Dict;
		_LoadedMemberS ->
			mod_guild_call:init_guild_godanimal([G_Id]),
			GuildApplyListRL = load_all_guild_apply(G_Id),
			lists:foreach(fun(GuildApply) -> mod_guild_call:update_guild_apply([GuildApply]) end, GuildApplyListRL),
			GuildInviteListRL = load_all_guild_invite(G_Id),
			lists:foreach(fun(GuildInvite) -> mod_guild_call:update_guild_invite([GuildInvite]) end, GuildInviteListRL),
			Guild = make_record(guild, GuildInfo),
    		dict:store(Guild#ets_guild.id, Guild, Guild_Dict)
	end,
	load_guild_init([GuildList_Left, New_Guild_Dict, _I2]).

delete_exception_guild(GuildId) ->
	%lib_city_war:delete_win_guild(GuildId),
    % 删除帮派表
    Data = [GuildId],
    SQL  = io_lib:format(?SQL_GUILD_DELETE, Data),
    db:execute(SQL),
    % 删除帮派申请表
    Data2 = [GuildId],
    SQL2  = io_lib:format(?SQL_GUILD_APPLY_DELETE, Data2),
    db:execute(SQL2),
    % 删除帮派邀请表
    Data3 = [GuildId],
    SQL3  = io_lib:format(?SQL_GUILD_INVITE_DELETE, Data3),
    db:execute(SQL3),
    % 删除帮派事件表
    Data4 = [GuildId],
    SQL4  = io_lib:format(?SQL_GUILD_EVENT_DELETE, Data4),
    db:execute(SQL4).
%%	需要删除,帮派目标表,帮派神兽表
%%  % 删除帮派奖励表
%%  Data5 = [GuildId],
%%  SQL5  = io_lib:format(?SQL_GUILD_AWARD_DELETE, Data5),
%%  db:execute(SQL5),
%%  % 删除帮派奖励分配表
%%  Data6 = [GuildId],
%%  SQL6  = io_lib:format(?SQL_GUILD_AWARD_ALLOC_DELETE, Data6),
%%  db:execute(SQL6).

load_guild_into_ets(GuildInfo) ->
    [G_Id|_] = GuildInfo,
	case load_all_guild_member(G_Id) of
		[] ->
			delete_exception_guild(G_Id),
			[];
		_LoadedMemberS ->
			%% 2- 加载该帮派申请         
			GuildApplyListRL = load_all_guild_apply(G_Id),
			lists:foreach(fun(GuildApply) -> gen_server:call(mod_guild, {update_guild_apply, [GuildApply]}) end, GuildApplyListRL),
			%% 3- 加载该帮派邀请
			GuildInviteListRL = load_all_guild_invite(G_Id),
			lists:foreach(fun(GuildInvite) -> gen_server:call(mod_guild, {update_guild_invite, [GuildInvite]}) end, GuildInviteListRL),
			Guild = make_record(guild, GuildInfo),
    		update_guild(Guild),
			Guild
	end.

%% -----------------------------------------------------------------
%% 加载所有帮派成员
%% -----------------------------------------------------------------
%% 简单加载
load_all_guild_member(GuildId) ->
    SQL  = io_lib:format(?SQL_GUILD_MEMBER_SELECT_ALL, [GuildId]),
    _GuildMemberList = db:get_all(SQL), 
    F = fun([Id,Name,_GuildId,GuildName,DonateTotal,DonateTotalCard,DonateTotalCoin,DonateLastTime,DonateTotalLastDay,DonateTotalLastWeek,PaidGetLastTime,CreateTime,Title,Remark,Honor,DepotStoreLastTime,DepotStoreNum,Position,Version,Donate,PaidAdd, Sex, Level, Career, Image, Material, FurnaceBack, FurnaceDailyBack]) ->
                SQL2 = io_lib:format(?SQL_PLAYER_LOGIN_SELECT_LAST_LOGIN_TIME, [Id]),
                LastLoginTime = db:get_one(SQL2),
                SQL3 = io_lib:format(?sql_player_vip_data, [Id]),
                [_VipType, _VipTime, _VipBagFlag] = db:get_row(SQL3),
                %% 帮派战信息
                FactionWar = lib_factionwar:load_player_factionwar_guild(Id),
                [Id,Name,_GuildId,GuildName,DonateTotal,DonateTotalCard,DonateTotalCoin,DonateLastTime,DonateTotalLastDay,DonateTotalLastWeek,PaidGetLastTime,CreateTime,Title,Remark,Honor,DepotStoreLastTime,DepotStoreNum,Position,Version,Donate,PaidAdd, Sex, Level, Career, LastLoginTime, Image, _VipType, Material, FurnaceBack, FurnaceDailyBack, FactionWar]
        end,
    GuildMemberList = lists:map(F, _GuildMemberList),
    lists:foreach(fun load_guild_member_into_ets/1, GuildMemberList),
    GuildMemberList.

load_guild_member_into_ets(GuildMemberInfo) ->
    GuildMember = make_record(guild_member, GuildMemberInfo),
    update_guild_member(GuildMember).

%% 构造帮派记录_需要先初始化成员_申请_邀请后,才初始化这里
make_record(guild, [Id,Name,Tenet,Announce,InitiatorId
				   ,InitiatorName,ChiefId,ChiefName,Realm,Level,Reputation,Funds
				   ,Contribution,_ContributionGetNextTime,CombatNum
				   ,CombatVictoryNum,QQ,CreateTime,DisbandFlag
				   ,_DisbandConfirmTime,_DisbandDeadlineTime,DepotLevel,HallLevel
				   ,CreateType,HouseLevel,MallLevel,MallContri
				   ,AltarLevel,FurnaceLevel,MemberNum,RenameFlag
				   ,FurnaceGrowth,MallGrowth,DepotGrowth,AltarGrowth,ApplySetting,AutoPassConfig]) ->
	[MemberCapacity, ContributionThreshold, ContributionDaily] = data_guild:get_level_info(Level),
	NewGuildMemberCapacity = lib_guild:calc_member_capacity(MemberCapacity, HouseLevel),
	Condition = [Id, 2],
	Info_LS = mod_guild_call:get_guild_member([Condition, 2, 0]),
	DeputyChiefNum  = length(Info_LS),
	[DeputyChief1Id, DeputyChief1Name, DeputyChief2Id, DeputyChief2Name] =
		case DeputyChiefNum of
			0 ->
				[0, <<>>, 0, <<>>];
			1 ->
				[DeputyChief] = Info_LS,
				[DeputyChief#ets_guild_member.id, DeputyChief#ets_guild_member.name, 0, <<>>];
			2 ->
				[DeputyChief1, DeputyChief2] = Info_LS,
				[DeputyChief1#ets_guild_member.id, DeputyChief1#ets_guild_member.name, DeputyChief2#ets_guild_member.id, DeputyChief2#ets_guild_member.name];
			_ ->
				
				[0, <<>>, 0, <<>>]
		end,
	#ets_guild{
			   id = Id,
			   name = util:make_sure_binary(Name),
			   name_upper = string:to_upper(util:make_sure_list(Name)),
			   tenet = Tenet,
			   announce = Announce,
			   initiator_id = InitiatorId,
			   initiator_name = InitiatorName,
			   chief_id = ChiefId,
			   chief_name = util:make_sure_binary(ChiefName),
			   deputy_chief1_id = DeputyChief1Id,
			   deputy_chief1_name = DeputyChief1Name,
			   deputy_chief2_id = DeputyChief2Id,
			   deputy_chief2_name = DeputyChief2Name,
			   deputy_chief_num = DeputyChiefNum,
			   member_num = MemberNum,
			   member_capacity = NewGuildMemberCapacity,
			   realm = Realm,
			   level = Level,
			   reputation = Reputation,
			   funds = Funds,
			   contribution = Contribution,
			   contribution_daily = ContributionDaily,
			   contribution_threshold = ContributionThreshold,
			   contribution_get_nexttime = 0,%%准备删除的变量
			   leve_1_last = CombatNum,		%%             等级1持续时间
			   base_left = CombatVictoryNum,%%        帮主离线时间
			   qq = QQ,
			   create_time = CreateTime,
			   create_type = CreateType,
			   disband_flag = DisbandFlag,
			   disband_confirm_time = 0,
			   disband_deadline_time = 0,
			   depot_level = DepotLevel,
			   hall_level  = HallLevel,
			   house_level = HouseLevel,
			   furnace_level = FurnaceLevel,
			   mall_level = MallLevel,
			   mall_contri  = MallContri,
			   altar_level = AltarLevel,
			   rename_flag = RenameFlag,
		       furnace_growth = FurnaceGrowth,          % 神炉成长
		       mall_growth = MallGrowth,                % 商城成长
		       depot_growth = DepotGrowth,              % 仓库成长
		       altar_growth = AltarGrowth,              % 祭坛成长
               apply_setting = ApplySetting,            % 申请设置
               auto_passconfig = util:bitstring_to_term(AutoPassConfig)         %申请条件设置 [等级, 战斗力]
	};

%% 构造帮派成员记录
make_record(guild_member, [Id,Name,GuildId,GuildName,DonateTotal,DonateTotalCard,DonateTotalCoin,DonateLastTime,DonateTotalLastDay,DonateTotalLastWeek,PaidGetLastTime,CreateTime,Title,Remark,Honor,DepotStoreLastTime,DepotStoreNum,Position,Version,Donate,PaidAdd, Sex, Level, Career, LastLoginTime, Image, Vip, Material, FurnaceBack, FurnaceDailyBack, FactionWar]) ->
    #ets_guild_member{
        id = Id,
        name = Name,
        guild_id = GuildId,
        guild_name = GuildName,
        donate_total = DonateTotal,
        donate_total_card = DonateTotalCard,
        donate_total_coin = DonateTotalCoin,
        donate_lasttime = DonateLastTime,
        donate_total_lastday = DonateTotalLastDay,
        donate_total_lastweek = DonateTotalLastWeek,
        paid_get_lasttime = PaidGetLastTime,
        create_time = CreateTime,
        title = Title,
        remark = Remark,
        honor = Honor,
        sex   = Sex,
        jobs  = Position,
        level = Level,
        position = Position,
        version  = Version,
        last_login_time = LastLoginTime,
        career = Career,
        depot_store_lasttime = DepotStoreLastTime,
        depot_store_num = DepotStoreNum,
        donate = Donate,
        paid_add = PaidAdd,
        image = Image,
        vip = Vip,
        material = Material,
		furnace_back = FurnaceBack,              	  % 神炉返利
        furnace_daily_back = FurnaceDailyBack,        
        factionwar = FactionWar                       % 帮派战信息
    };

%% 构造帮派申请记录
make_record(guild_apply, [Id, GuildId, PlayerId, CreateTime, PlayerName, PlayerSex, PlayerLevel, PlayerCareer, PlayerVipType]) ->
    #ets_guild_apply{
        id          = Id,
        guild_id    = GuildId,
        player_id   = PlayerId,
        player_name = PlayerName,
        player_sex  = PlayerSex,
        player_jobs = 0,
        player_level= PlayerLevel,
        create_time = CreateTime,
        player_career = PlayerCareer,
        player_vip_type = PlayerVipType};

%% 构造帮派邀请记录
make_record(guild_invite, [Id, PlayerId, GuildId, CreateTime]) ->
    #ets_guild_invite{
        id          = Id,
        guild_id    = GuildId,
        player_id   = PlayerId,
        create_time = CreateTime}.

%% -----------------------------------------------------------------
%% 加载所有帮派申请
%% -----------------------------------------------------------------
load_all_guild_apply(GuildId) ->
    SQL  = io_lib:format(?SQL_GUILD_APPLY_SELECT_GUILD, [GuildId]),
    _GuildApplyList = db:get_all(SQL),
    F = fun([_Id, _GuildId, _PlayerId, _CreateTime, _NickName, _Sex, _Lv, _Career]) ->
                SqlOne = io_lib:format(?sql_player_vip_data, [_PlayerId]),
                [_VipType, _VipTime, _VipBagFlag] = db:get_row(SqlOne),
                [_Id, _GuildId, _PlayerId, _CreateTime, _NickName, _Sex, _Lv, _Career, _VipType]
        end,
    GuildApplyList = lists:map(F, _GuildApplyList),
    lists:map(fun(D) -> make_record(guild_apply, D) end, GuildApplyList).

load_guild_apply_into_ets(GuildApplyInfo) ->
    GuildApply = make_record(guild_apply, GuildApplyInfo),
    update_guild_apply(GuildApply).

%% -----------------------------------------------------------------
%% 加载所有帮派邀请
%% -----------------------------------------------------------------
load_all_guild_invite(GuildId) ->
    SQL  = io_lib:format(?SQL_GUILD_INVITE_SELECT_ALL, [GuildId]),
    GuildInviteList = db:get_all(SQL),
	lists:map(fun(D) -> make_record(guild_invite, D) end, GuildInviteList).

load_guild_invite_into_ets(GuildInviteInfo) ->
    GuildInvite = make_record(guild_invite, GuildInviteInfo),
    update_guild_invite(GuildInvite).

%% -----------------------------------------------------------------------------
%% 			　　操作
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 获取帮派信息_修改为进程字典
%% 查询类型: 0 全部, 1 按ID查询, 2 按名字查询, 3 按等级查询, 4 按解散状态查询, 5 uppername查询
%% -----------------------------------------------------------------
get_guild_all() ->
	case catch gen_server:call(mod_guild, {get_guild, [0, 0]}, 7000) of
		_D when erlang:is_list(_D) ->
			_D;
		_ ->
			[]
	end.

get_guild(GuildId) ->
	case catch gen_server:call(mod_guild, {get_guild, [GuildId, 1]}, 7000) of
		_D when erlang:is_record(_D, ets_guild) ->
			_D;
		_ ->
			[]
	end.

get_guild_by_name(GuildName) ->
	case catch gen_server:call(mod_guild, {get_guild, [GuildName, 2]}, 7000) of
		_D when erlang:is_list(_D) ->
			_D;
		_ ->
			[]
	end.

get_guild_lv0() ->
	case catch gen_server:call(mod_guild, {get_guild, [1, 3]}, 7000) of
		_D when erlang:is_list(_D) ->
			_D;
		_ ->
			[]
	end.

get_guild_disband() ->
	case catch gen_server:call(mod_guild, {get_guild, [1, 4]}, 7000) of
		_D when erlang:is_list(_D) ->
			_D;
		_ ->
			[]
	end.

%% 创建帮派,帮派更名使用
get_guild_by_name_upper(GuildNameUpper) ->
	case catch gen_server:call(mod_guild, {get_guild, [GuildNameUpper, 5]}, 7000) of
		_D when erlang:is_list(_D) ->
			_D;
		_ ->
			[]
	end.

get_guild_lev_by_id(GuildId) ->
    case get_guild(GuildId) of
        []  -> null;
        Guild -> Guild#ets_guild.level
    end.

%% 更新帮派缓存_跟换为进程字典
update_guild(Guild) ->
	case catch gen_server:call(mod_guild, {update_guild, [Guild]}, 7000) of
		ok ->
			ok;
		_ ->
			error
	end.

%% 删除帮派缓存_跟换为进程字典
delete_guild(GuildId) ->
    gen_server:call(mod_guild, {delete_guild, [GuildId]}, 7000).

%% 删除帮派前给帮派成员发送神炉返利
send_furnace_back(GuildId) ->
    gen_server:call(mod_guild, {send_furnace_back, [GuildId]}, 7000).
%% -----------------------------------------------------------------
%% 帮派成员 
%% -----------------------------------------------------------------

%% 更新帮派成员缓存
update_guild_member([offline, PlayerId])->
	gen_server:cast(mod_guild, {update_guild_member, [offline, PlayerId]});
update_guild_member(PlayerStatus) when is_record(PlayerStatus, player_status)->
	?INFO1("update_guild_member error : ~p~n", [PlayerStatus#player_status.id]);
update_guild_member(GuildMember) when is_record(GuildMember, ets_guild_member) ->
	OnlyFlag = case mod_chat_agent:lookup(GuildMember#ets_guild_member.id) of
		[] ->
			case GuildMember#ets_guild_member.online_flag =:= 0 of
				true ->
					0;
				false ->
					1
			end;
		_ ->
			1
	end,
	GuildMember_New = GuildMember#ets_guild_member{online_flag = OnlyFlag},
    gen_server:call(mod_guild, {update_guild_member, [GuildMember_New]}, 7000).

%% 玩家升级处理_同步帮派成员等级
update_guild_member_new_info(PlayerId, NewLevel) ->
	case get_guild_member_by_player_id(PlayerId) of
		GuildMember when is_record(GuildMember, ets_guild_member) ->
			GuildMember_New = GuildMember#ets_guild_member{level = NewLevel},
			update_guild_member(GuildMember_New);
		_ ->
			skip
	end.

get_guild_official(GuildId, Position) ->
    gen_server:call(mod_guild, {get_guild_member, [[GuildId, Position], 2]}, 7000).

get_guild_member_by_player_id(PlayerId) ->
    case catch gen_server:call(mod_guild, {get_guild_member, [PlayerId, 1]}, 7000) of
		_D when erlang:is_record(_D, ets_guild_member) ->
			_D;
		_ ->
			[]
	end.

get_guild_member_by_guild_id(GuildId) ->
    case catch gen_server:call(mod_guild, {get_guild_member, [GuildId, 0]}, 7000) of
		_D when erlang:is_list(_D) ->
			_D;
		_ ->
			[]
	end.

delete_guild_member_by_guild_id(GuildId) ->
    gen_server:call(mod_guild, {delete_guild_member, [GuildId, 0]}, 7000).

delete_guild_member_by_player_id(PlayerId) ->
    gen_server:call(mod_guild, {delete_guild_member, [PlayerId, 1]}, 7000).

%% 存入帮派成员信息_写入数据库
update_guild_member_base1(GuildMember) ->
	Data = [GuildMember#ets_guild_member.donate_total
		   , GuildMember#ets_guild_member.donate_total_coin
		   , GuildMember#ets_guild_member.donate_total_card
		   , GuildMember#ets_guild_member.donate_lasttime
		   , GuildMember#ets_guild_member.donate_total_lastday
		   , GuildMember#ets_guild_member.donate_total_lastweek
		   , GuildMember#ets_guild_member.paid_get_lasttime
		   , GuildMember#ets_guild_member.depot_store_lasttime
		   , GuildMember#ets_guild_member.depot_store_num
		   , GuildMember#ets_guild_member.donate
		   , GuildMember#ets_guild_member.paid_add
		   , GuildMember#ets_guild_member.material
		   , GuildMember#ets_guild_member.id],
    Sql  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE1, Data),
    db:execute(Sql).

%% 存入帮派成员总要信息_写数据库
update_guild_member_base0(GuildMember) ->
	Data = [GuildMember#ets_guild_member.guild_id
		   , GuildMember#ets_guild_member.guild_name
		   , GuildMember#ets_guild_member.donate_total
		   , GuildMember#ets_guild_member.donate_total_coin
		   , GuildMember#ets_guild_member.donate_total_card
		   , GuildMember#ets_guild_member.donate_lasttime
		   , GuildMember#ets_guild_member.donate_total_lastday
		   , GuildMember#ets_guild_member.donate_total_lastweek
		   , GuildMember#ets_guild_member.position
		   , GuildMember#ets_guild_member.donate
		   , GuildMember#ets_guild_member.material
		   , GuildMember#ets_guild_member.furnace_back
           , GuildMember#ets_guild_member.furnace_daily_back
		   , GuildMember#ets_guild_member.id],
    Sql  = io_lib:format(?SQL_GUILD_MEMBER_UPDATE0, Data),
	spawn(fun() -> db:execute(Sql) end).

%% 改变帮派成员的帮派财富_写入数据库
change_guild_member_material_data([PlayerId, Material_Change]) ->
	Data = [Material_Change, PlayerId],
    Sql  = io_lib:format(?SQL_GUILD_MEMBER_MATERIAL, Data),
    db:execute(Sql).

%% -----------------------------------------------------------------
%% 帮派申请
%% -----------------------------------------------------------------
get_guild_apply_by_player_id(PlayerId, GuildId) ->
	gen_server:call(mod_guild, {get_guild_apply, [[PlayerId, GuildId], 2]}, 7000).

get_guild_apply_by_player_id(PlayerId) ->
    gen_server:call(mod_guild, {get_guild_apply, [PlayerId, 1]}, 7000).

get_guild_apply_by_guild_id(GuildId) ->
    gen_server:call(mod_guild, {get_guild_apply, [GuildId, 0]}, 7000).

update_guild_apply(GuildApply) ->
    gen_server:call(mod_guild, {update_guild_apply, [GuildApply]}).

delete_guild_apply_by_player_id(PlayerId) ->
	gen_server:call(mod_guild, {delete_guild_apply, [PlayerId, 1]}).

delete_guild_apply_by_player_id(PlayerId, GuildId) ->
    gen_server:call(mod_guild, {delete_guild_apply, [[PlayerId, GuildId], 2]}).

delete_guild_apply_by_guild_id(GuildId) ->
    gen_server:call(mod_guild, {delete_guild_apply, [GuildId, 0]}).

%% -----------------------------------------------------------------
%% 帮派邀请
%% -----------------------------------------------------------------
get_guild_invite_by_player_id(PlayerId, GuildId) ->
	gen_server:call(mod_guild, {get_guild_invite, [[PlayerId, GuildId], 2]}, 7000).

get_guild_invite_by_player_id(PlayerId) ->
	gen_server:call(mod_guild, {get_guild_invite, [PlayerId, 1]}, 7000).

get_guild_invite_by_guild_id(GuildId) ->
    gen_server:call(mod_guild, {get_guild_invite, [GuildId, 0]}, 7000).

update_guild_invite(GuildInvite) ->
    gen_server:call(mod_guild, {update_guild_invite, [GuildInvite]}).

delete_guild_invite_by_player_id(PlayerId) ->
	gen_server:call(mod_guild, {delete_guild_invite, [PlayerId, 1]}).

delete_guild_invite_by_player_id(PlayerId, GuildId) ->
    gen_server:call(mod_guild, {delete_guild_invite, [[PlayerId, GuildId], 2]}).

delete_guild_invite_by_guild_id(GuildId) ->
   	gen_server:call(mod_guild, {delete_guild_invite, [GuildId, 0]}).

%%=========================================================================
%% 获取玩家相关帮派信息
%%=========================================================================

get_player_guild_info(PlayerId) ->
    case mod_chat_agent:lookup(PlayerId) of
        [] ->
            Data = [PlayerId],
            SQL  = io_lib:format(?SQL_PLAYER_SELECT_GUILD_INFO1, Data),
            db:get_row(SQL);
        [OnlineInfo] ->
            [util:make_sure_binary(OnlineInfo#ets_unite.name), OnlineInfo#ets_unite.realm, OnlineInfo#ets_unite.guild_id, util:make_sure_binary(OnlineInfo#ets_unite.guild_name), OnlineInfo#ets_unite.guild_position]
    end.
   
get_player_guild_info2_by_name(PlayerNickname) ->
	case mod_chat_agent:match(match_name, [util:make_sure_list(PlayerNickname)]) of
        [] ->
            Data = [PlayerNickname],
            SQL  = io_lib:format(?SQL_PLAYER_SELECT_GUILD_INFO2_BY_NAME, Data),
            db:get_row(SQL);
        [OnlineInfo] ->
    		[OnlineInfo#ets_unite.id
			, util:make_sure_binary(OnlineInfo#ets_unite.name)
			, OnlineInfo#ets_unite.realm
			, OnlineInfo#ets_unite.career
			, OnlineInfo#ets_unite.sex
			, OnlineInfo#ets_unite.image
			, OnlineInfo#ets_unite.lv
			, OnlineInfo#ets_unite.guild_id
			, util:make_sure_binary(OnlineInfo#ets_unite.guild_name)
			, OnlineInfo#ets_unite.guild_position]
    end.

get_player_guild_info2_by_id(PlayerId) ->
    case mod_chat_agent:lookup(PlayerId) of
        [] ->
            Data = [PlayerId],
            SQL  = io_lib:format(?SQL_PLAYER_SELECT_GUILD_INFO2_BY_ID, Data),
            db:get_row(SQL);
        [OnlineInfo] ->
    		[OnlineInfo#ets_unite.id
			, util:make_sure_binary(OnlineInfo#ets_unite.name)
			, OnlineInfo#ets_unite.realm
			, OnlineInfo#ets_unite.career
			, OnlineInfo#ets_unite.sex
			, OnlineInfo#ets_unite.image
			, OnlineInfo#ets_unite.lv
			, OnlineInfo#ets_unite.guild_id
			, util:make_sure_binary(OnlineInfo#ets_unite.guild_name)
			, OnlineInfo#ets_unite.guild_position]
	end.

set_player_guild_lv(GuildId, Lv) -> 
	L = mod_chat_agent:match(guild_id_pid_sid, [GuildId]),
    [gen_server:cast(Pid, {'guild_lv', Lv}) || [_, Pid, _]<-L],
    ok.

%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 			　　定时服务处理
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 清理掉级后需自动解散的帮派
%% -----------------------------------------------------------------
handle_auto_disband() ->
    Guilds = get_guild_lv0(),
    lists:map(fun handle_auto_disband/1, Guilds).

handle_auto_disband(Guild) ->
    NowTime = util:unixtime(),
    [GuildId, GuildName, Level, DisbandDeadlineTime] = [Guild#ets_guild.id, Guild#ets_guild.name, Guild#ets_guild.level, Guild#ets_guild.disband_deadline_time],
    case  Level == 1 andalso  DisbandDeadlineTime > 0 andalso NowTime > DisbandDeadlineTime of
        true ->
            % 解散帮派
            lib_guild:confirm_disband_guild(GuildId, GuildName, 1),
            % 广播帮派成员
            lib_guild:send_guild(GuildId, 'guild_disband', [GuildId, GuildName]);
        false ->
            void
    end,
    ok.
    


%% -----------------------------------------------------------------
%% 获取所有帮派的ID,供给帮派战使用
%% -----------------------------------------------------------------
get_all_guild_id() ->
    case catch gen_server:call(mod_guild, {get_all_guild_id}, 7000) of
		[] ->
			[];
		Gids->
			Gids
	end.

%% -----------------------------------------------------------------
%% 直接查找数据库获取玩家的帮派ID
%% @return 0 -> 无帮派
%% -----------------------------------------------------------------
db_get_player_guildid(PlayerId) ->
	SQL  = io_lib:format(?SQL_PLAYER_GUILD_ID_SELECT, [PlayerId]),
    db:get_one(SQL).

%% 修复合并帮派
cancel_hebin_server(GuildId) ->
	mod_disperse:cast_to_unite(lib_guild_base, cancel_hebin, [GuildId]).

cancel_hebin(GuildId)->
	case lib_guild:get_guild(GuildId) of
		SelfGuild when is_record(SelfGuild, ets_guild) ->
			mod_guild:make_merge_0(GuildId, 0),
			case SelfGuild#ets_guild.merge_guild_id =:= 0 of
				true ->
					skip;
				false ->
					mod_guild:make_merge_0(SelfGuild#ets_guild.merge_guild_id, 0)
			end;
		_->
			skip
	end.

%% 游戏线使用
add_guild_caifu_server(PlayerId, Num) ->
	mod_disperse:call_to_unite(lib_guild_base, add_guild_caifu, [PlayerId, Num]).

%% 增加玩家帮派财富
add_guild_caifu(PlayerId, Num) ->
	case Num =< 0 of
		true ->
			false;
		false ->
			case get_guild_member_by_player_id(PlayerId) of
				GuildMember when is_record(GuildMember, ets_guild_member) ->
					GuildMember_New = GuildMember#ets_guild_member{material = GuildMember#ets_guild_member.material + Num},
					update_guild_member(GuildMember_New),
					true;
				_ ->
					false
			end
	end.
	
%% 后台更改帮派名称
bg_change_guild_name_server(GuildId, GuildNamex) ->
	GuildName = util:make_sure_binary(GuildNamex),
	%% 更改数据库 
    Data = [GuildName, GuildId],
    SQL = io_lib:format(?SQL_GUILD_UPDATE_RENAME, Data),
    db:execute(SQL),
    Data1 = [GuildName, GuildId],
    SQL1 = io_lib:format(?SQL_GUILD_MEMBER_UPDATE_RENAME_GUILD, Data1),
    db:execute(SQL1),
	NewGuildName = string:to_upper(util:make_sure_list(GuildName)),
    NewNameUp = lib_guild_base:get_guild_by_name_upper(NewGuildName),
    mod_disperse:cast_to_unite(lib_guild, gaimin_hefu, [GuildId, GuildName, NewNameUp]),
	mod_disperse:cast_to_unite(lib_guild, send_guild, [GuildId, 'guild_self_syn_guildname', [GuildId, GuildName]]).

bg_change_guild_name(GuildId, GuildName) ->
    mod_disperse:cast_to_unite(lib_guild, send_guild, [GuildId, 'guild_self_syn_guildname', [GuildId, GuildName]]).

%% 查询帮主ID
get_guild_c_db(GuildId) ->
	Sqlbase = "select chief_id, chief_name from guild where id = ~p",
    Data1 = [GuildId],
    SQL1 = io_lib:format(Sqlbase, Data1),
	case db:get_row(SQL1) of
		[] ->
			[0, <<>>];
		[Cid, Cname] ->
			[Cid, util:make_sure_binary(Cname)]
	end.
