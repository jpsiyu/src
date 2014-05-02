%%%--------------------------------------
%%% @Module  : lib_login
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.06.14
%%% @Description:注册登录
%%%--------------------------------------
-module(lib_login).
-export(
    [
        get_role_list/1,
        create_role/8,
        delete_role/2,
        get_player_login_by_id/1,
        update_login_data/3,
        log_all_online/1
    ]
).
-include("common.hrl").
-include("sql_player.hrl").
-include("sql_goods.hrl").
-include("arena_new.hrl").
-include("rela.hrl").
-include("scene.hrl").
-include("def_goods.hrl").
-include("factionwar.hrl").
-include("server.hrl").

%% 取得指定帐号的角色列表 
get_role_list(Name) ->
	%1.得到全部角色的属性.
    RoleList = db:get_all(io_lib:format(?sql_role_list, [Name])),

	%2.得到角色的身上装备和时装.
    FunGetEquip = 
		fun(Pid, Status, Name1, Sex, Lv, Career, Realm) ->
			WeaponGoodsId =
				case db:get_row(io_lib:format(?SQL_GOODS_GET_WEAPON, [Pid])) of
					[] -> 0;
					[_WeaponGoodsId] -> _WeaponGoodsId
				end,
			ArmorGoodsId =
				case db:get_row(io_lib:format(?SQL_GOODS_GET_ARMOR, [Pid])) of
					[] -> 0;
					[_ArmorGoodsId] -> _ArmorGoodsId
				end,
			FashionWeaponGoodsId =
				case db:get_row(io_lib:format(?SQL_GOODS_GET_FASHION_WEAPON, [Pid])) of
					[] -> 0;
					[_FashionWeaponGoodsId] -> _FashionWeaponGoodsId
				end,
			FashionArmorGoodsId =
				case db:get_row(io_lib:format(?SQL_GOODS_GET_FASHION_ARMOR, [Pid])) of
					[] -> 0;
					[_FashionArmorGoodsId] -> _FashionArmorGoodsId
				end,
			FashionAccessoryGoodsId =
				case db:get_row(io_lib:format(?SQL_GOODS_GET_FASHION_ACCESSORY, [Pid])) of
					[] -> 0;
					[_FashionAccessoryGoodsId] -> _FashionAccessoryGoodsId
				end,
			[Pid, Status, Name1, Sex, Lv, Career, Realm, WeaponGoodsId, ArmorGoodsId,
			FashionWeaponGoodsId, FashionArmorGoodsId, FashionAccessoryGoodsId]	
    	end,

	%3.返回角色列表.
	case RoleList of
		List when is_list(List) ->
			[FunGetEquip(Pid, Status, Name2, Sex, Lv, Career, Realm)||
				[Pid, Status, Name2, Sex, Lv, Career, Realm]<-List];
		_ ->
			[]
	end.


%% 根据id查找账户名称
get_player_login_by_id(Id) ->
    db:get_row(io_lib:format(?sql_player_login_by_id, [Id])).

%% 更新登陆需要的记录
update_login_data(Id, Ip, Time) ->
    db:execute(io_lib:format(?sql_update_login_data, [Time, util:ip2bin(Ip), Id])).

%% 创建角色
create_role(AccId, AccName, Name, _Realm, _Career, _Sex, IP, Source) ->
    % 职业
    Career =   if
        _Career == 1 -> % 昆仑（战士）
            1;
        _Career == 2 -> % 逍遥（法师）
            2;
        true ->         % 唐门（刺客）
            3
    end,

    % 阵营
    SceneId = 100,
    Realm = 0,
    Scene = data_scene:get(SceneId),
    X = Scene#ets_scene.x,
    Y = Scene#ets_scene.y,

    % 性别
    Sex =   if
        _Sex == 1 ->%男
            1;
        true ->    %女
            2
    end,
                
    Time = util:unixtime(),

    %% 默认参数
    CellNum = ?GOODS_BAG_EXTEND_NUM,
    StorageNum = ?GOODS_STORAGE_EXTEND_NUM,
    Forza = 5,
    Agile = 5,
    Wit = 5,
    Thew = 5,
    Lv = 1,
    [Hp0, Mp0 | _] = lib_player:one_to_two(Forza, Agile, Wit, Thew, Career),
    Hp = round(Hp0),
    Mp = round(Mp0),
	%% change by xieyunfei
	%% 去掉体力值字段
	%%Physical = data_physical:get_default_value(),

    SourceLenValid = util:check_length(Source, 50),
    case SourceLenValid of
        false -> 
            Source2 = "";
        true ->
            SourceContentInValid = util:check_keyword(Source),
            case SourceContentInValid of
                true ->
                    Source2 = "";
                false ->
                    Source2 = Source
            end
    end,


    Sql = io_lib:format(?sql_insert_player_login_one, [AccId, AccName, Time, util:ip2bin(IP), Source2]),
    case db:execute(Sql) of
        1 ->
            case lib_player:get_role_id_by_accname(AccName) of
                null ->
                    0;
                Id ->
                    PlayerHighSql = io_lib:format(?sql_insert_player_high_one, [Id]),
                    PlayerLowSql = io_lib:format(?sql_insert_player_low_one, [Id, Name, Sex, Lv, Career, Realm]),
					%% change by xieyunfei
					%% 去掉体力值字段
                    PlayerStateSql = io_lib:format(?sql_insert_player_state_one, [Id, SceneId, X, Y, Hp, Mp]),
                    PlayerAttrSql = io_lib:format(?sql_insert_player_attr_one, [Id, Forza, Agile, Wit, Thew, CellNum, StorageNum, 0, 0]),
                    PlayerPtSql = io_lib:format(?sql_insert_player_pt_one, [Id]),
                    PlayerVipSql = io_lib:format(?sql_insert_player_vip_one, [Id]),
                    PlayerPetSql = io_lib:format(?sql_insert_player_pet_one, [Id]),
					PlayerBlessSql = io_lib:format(?sql_insert_player_bless_one, [Id]),
					PlayerRechargeStat = io_lib:format(?sql_insert_player_recharge_one, [Id]),
                    F1 = fun() ->
                        db:execute(PlayerHighSql),
                        db:execute(PlayerLowSql),
                        db:execute(PlayerStateSql),
                        db:execute(PlayerAttrSql),
                        db:execute(PlayerPtSql),
                        db:execute(PlayerVipSql),
                        db:execute(PlayerPetSql),
						db:execute(PlayerBlessSql),
						db:execute(PlayerRechargeStat),
                        true
                    end,
                    case
                        db:transaction(F1) =:= true
                    of
                        true -> %% sql执行成功
                           Id;
                        false ->
                            db:execute(io_lib:format("delete from player_login where id = ~p limit 1", [Id])),
                            0
                    end
                end;
        _Other ->
            0
    end.
    
%% 删除角色 - 暂时无用
delete_role(Pid, Accname) ->
    Sql = lists:concat(["select id from player_login where id=",Pid ," and accname='",Accname,"'"]),
    case db:get_one(Sql) of
        null -> false;
        Id ->
            db:execute(lists:concat(["delete from `player_login` where id = ", Id])),
            db:execute(lists:concat(["delete from `player_high` where id = ", Id])),
            db:execute(lists:concat(["delete from `player_low` where id = ", Id])),
            true
    end.

%% 记录在线时长，大于三分钟的写入数据库中
log_all_online(PS) ->
    OnlineTime = util:unixtime() - PS#player_status.last_login_time,
    case OnlineTime >= 3 * 60 of
        true -> 
            %SQL = lists:concat(["insert into `log_all_online` set player_id=", PS#player_status.id, " and online_time=", OnlineTime, " and logout_time=", util:unixtime()]),
            SQL = io_lib:format("insert into `log_all_online` (player_id, online_time, logout_time, last_login_time) values(~p,~p,~p, ~p)", [PS#player_status.id, OnlineTime, util:unixtime(), PS#player_status.last_login_time]),
            db:execute(SQL);
        false -> skip
    end.
