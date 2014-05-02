%%%-----------------------------------
%%% @Module  : pt_120
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.06.23
%%% @Description: 12场景信息
%%%-----------------------------------
-module(pt_120).
-export([read/2, write/2, pack_elem_list/1, pack_npc_list/1]).
-include("server.hrl").
-include("scene.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%

%%走路
read(12001, <<X:16, Y:16, Fly:8>>) ->
    {ok, [X, Y, Fly]};

%%加载场景
read(12002, _) ->
    {ok, load};

%%离开场景
%read(12004, _) ->
%    {ok, leave};

%%切换场景
read(12005, <<Sid:32>>) ->
    {ok, Sid};

%% 请求刷新npc状态
read(12020, _) -> 
    {ok, []};

%%获取场景关系
read(12080, _) ->
    {ok, []};

%%获取场景所有怪物
read(12095, <<Q:32>>) ->
    {ok, Q};

%% 取消变身
read(12099, _R) ->
    {ok, []};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%%走路
write(12001, [X, Y, F, Id, Platform, SerNum]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12001, <<X:16, Y:16, Id:32, Platform1/binary, SerNum:16, F:8>>)};

%%加场景信息
%write(12002, {User, Mon, Elem, Npc}) ->
write(12002, {User, Mon}) ->
    %Data1 = pack_elem_list(Elem),
    Data2 = pack_scene_user_list(User),
    Data3 = pack_mon_list(Mon),
    %Data4 = pack_npc_list(Npc),
    %Data = << Data1/binary, Data2/binary, Data3/binary, Data4/binary>>,
	Data = << Data2/binary, Data3/binary>>,
    {ok, pt:pack(12002, Data, 1)};

	
%%进入新场景广播给本场景的人
write(12003, []) ->
    {ok, pt:pack(12003, <<>>)};
write(12003, D) ->
    {ok, pt:pack(12003, binary_12003(trans_to_12003(D)))};

%%离开场景
write(12004, [Id, Platform, SerNum]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12004, <<Id:32, Platform1/binary, SerNum:16>>)};

%%切换场景
write(12005, [Id, X, Y, Name, Sid]) ->
    Name1 = pt:write_string(Name),
    Data = <<Id:32, X:16, Y:16, Name1/binary, Sid:32>>,
    {ok, pt:pack(12005, Data)};

write(12006, [Id]) ->
    Data = <<Id:32>>,
    {ok, pt:pack(12006, Data)};

%% 有怪物进入场景
write(12007, Info) ->
    {ok, pt:pack(12007, binary_12007(Info))};

%%怪物移动
write(12008, [X, Y, Id]) ->
    Data = <<X:16, Y:16, Id:32>>,
    {ok, pt:pack(12008, Data)};

%% 血量变化
write(12009, [PlayerId, Platform, SerNum, Hp, Hp_lim]) ->
    Platform1 = pt:write_string(Platform),
	{ok, pt:pack(12009, <<PlayerId:32, Platform1/binary, SerNum:16, Hp:32, Hp_lim:32>>)};

%%乘上坐骑或者离开坐骑
write(12010, [PlayerId, Platform, SerNum, PlayerSpeed, FigureId]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12010, <<PlayerId:32, Platform1/binary, SerNum:16, PlayerSpeed:16, FigureId:32>>)};

%%装备物品
write(12012, [PlayerId, Platform, SerNum, Equip_current, Stren7_num, SuitId, HP, HP_lim, 
			  Fashion_weapon, Fashion_armor, Fashion_accessory, 
			  Hide_fashion_weapon, Hide_fashion_armor, 
			  Hide_fashion_accessory, Mount_figure, HideHead, HideTail, HideRing, FashionHead, FashionTail, FashionRing]) ->
    [Wq, Yf, _Zq, WqStren, _YfStren, _Sz] = Equip_current,
    Platform1 = pt:write_string(Platform),
    S7 = pt:write_string(integer_to_list(Stren7_num)),
    [Wqsz, WqszStren] = case Hide_fashion_weapon =:= 1 of
                            false -> 
                                Fashion_weapon;
                            true ->
                                [0,0]
                         end,
    [Yfsz, YfszStren] = case Hide_fashion_armor =:= 1 of
                            false -> 
                                Fashion_armor;
                            true ->
                                [0,0]
                         end,
    [Spsz, SpszStren] = case Hide_fashion_accessory =:= 1 of
                            false -> 
                                Fashion_accessory;
                            true ->
                                [0,0]
                         end,
    [Head, S1] = case HideHead =:= 1 of
                        false ->
                            FashionHead;
                        true ->
                            [0,0]
                    end,
    [Tail, S2] = case HideTail =:= 1 of
                        false ->
                            FashionTail;
                        true ->
                            [0,0]
                    end,
    [Ring, S3] = case HideRing =:= 1 of
                        false ->
                            FashionRing;
                        true ->
                            [0,0]
                    end,
    {ok, pt:pack(12012, <<PlayerId:32, Platform1/binary, SerNum:16, Wq:32, Yf:32, Mount_figure:32, 
						  WqStren:8, S7/binary, SuitId:32, HP:32, HP_lim:32, 
						  Yfsz:32, YfszStren:8, Wqsz:32, WqszStren:8, Spsz:32, 
						  SpszStren:8, Head:32, S1:8, Tail:32, S2:8, Ring:32, S3:8>>)};

%%掉落包生成
write(12017, [MonId, Time, Scene, DropBin, X, Y]) ->
    ListNum = length(DropBin),
    ListBin = list_to_binary(DropBin),
    {ok, pt:pack(12017, <<MonId:32, Time:16, Scene:32, ListNum:16, 
						  ListBin/binary, X:16, Y:16>>)};

%%加场景信息
write(12011, [User1, User2]) ->
    Data1 = pack_scene_user_list(User1),
    Data2 = pack_leave_list(User2),
    Data = << Data1/binary, Data2/binary>>,
    {ok, pt:pack(12011, Data, 1)};

%% 上任/卸任队长
write(12018, [Id, Platform, SerNum, Type]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12018, <<Id:32, Platform1/binary, SerNum:16, Type:8>>)};

%% 掉落消失
write(12019, DropId) ->
    {ok, pt:pack(12019, <<DropId:32>>)};

%% 掉落捡取信息
write(12021, [PlayerId, Platform, SerNum, DropId, PlayerName]) ->
    Platform1 = pt:write_string(Platform),
    Bin = pt:write_string(PlayerName),
    {ok, pt:pack(12021, <<PlayerId:32, Platform1/binary, SerNum:16, DropId:32, Bin/binary>>)};

%% 改变NPC状态图标
write(12020, []) ->
    {ok, pt:pack(12020, <<>>)};
write(12020, [NpcList]) ->
    NL = length(NpcList),
    Bin = list_to_binary([<<Id:32, Ico:8>> || [Id, Ico] <- NpcList]),
    Data = <<NL:16, Bin/binary>>,
    {ok, pt:pack(12020, Data)};

%% 放烟花通知
write(12022, [PlayerId, Platform, SerNum, GoodsId]) ->
    Platform1 = pt:write_string(Platform),
	{ok, pt:pack(12022, <<PlayerId:32, Platform1/binary, SerNum:16, GoodsId:32>>)};

%% 改变阵营属性（group值）
write(12023, [Sign, Id, Platform, SerNum, Type]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12023, <<Sign:8, Id:32, Platform1/binary, SerNum:16, Type:32>>)};
    
%%发送宠物形象改变通知
write(12033, [PlayerId, Platform, SerNum, Figure, Nimbus, Level, Name, Quality]) ->
    Platform1 = pt:write_string(Platform),
    NameLen = byte_size(Name),
    Data = <<PlayerId:32, Platform1/binary, SerNum:16, Figure:16, Nimbus:16, Level:16, NameLen:16, 
			 Name/binary, Quality:8>>,
    {ok, pt:pack(12033, Data)};

%%升级通知
write(12034, [PlayerId, Platform, SerNum]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12034, <<PlayerId:32, Platform1/binary, SerNum:16>>)};

%% 打包场景相邻关系数据
write(12080, [L]) ->
    Len = length(L),
    Bin = pack_scene_border(L, []),
    {ok, pt:pack(12080, <<Len:16, Bin/binary>>)};

%% 怪物加血
write(12081, [Id, Hp]) ->
    {ok, pt:pack(12081, <<Id:32, Hp:32>>)};

%%改变速度
write(12082, [State, PlayerId, Platform, SerNum, PlayerSpeed]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12082, <<State:8, PlayerId:32, Platform1/binary, SerNum:16, PlayerSpeed:16>>)};

write(12083, [Revive_type,ScenceId, X,Y,ScenceName,Hp,Mp,Gold,BGold,Att_protected]) ->
	ScenceNameBin = pt:write_string(ScenceName),
    {ok, pt:pack(12083, <<Revive_type:8,ScenceId:32, X:16,Y:16,ScenceNameBin/binary,Hp:32,Mp:32,Gold:32,BGold:32,Att_protected:16>>)};

%%pk状态变更通知
write(12084, [PlayerId, Platform, SerNum, Status, PK_value]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12084, <<PlayerId:32, Platform1/binary, SerNum:16, Status:8, PK_value:16>>)};

%% 怪物变身
write(12085, [MonId, ResId, DuringResId, DuringTime, MorphCount, ChangeType, Name]) ->
	NameLen = byte_size(Name),
	Data = <<MonId:32, ResId:32, DuringResId:32, DuringTime:32, MorphCount:8, ChangeType:8, 
			 NameLen:16, Name/binary>>,	 
    {ok, pt:pack(12085, Data)};
    
%% 改变国家
write(12090, [Id, Platform, SerNum, Realm]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12090, <<Id:32, Platform1/binary, SerNum:16, Realm:8>>)};

%% 护送广播
write(12093, [PlayerId, Platform, SerNum, Level, Hp, Hp_lim, NpcId]) ->
    Platform1 = pt:write_string(Platform),
    Data = <<PlayerId:32, Platform1/binary, SerNum:16, Level:8, Hp:32, Hp_lim:32, NpcId:32>>,
    {ok, pt:pack(12093, Data)};

%% 9宫格怪物
write(12094, [Mon1, Mon2]) ->
    Data1 = pack_mon_list(Mon1),
    Data2 = pack_mon_leave_list(Mon2),
    Data = << Data1/binary, Data2/binary>>,
    {ok, pt:pack(12094, Data, 1)};

%% 获取场景所有怪物
write(12095, [Q, AllMon]) ->
    Data = pack_allmon_list(AllMon), 
    {ok, pt:pack(12095, <<Q:32, Data/binary>>)};

%% 玩家头上的称号列表
write(12096, [RoleId, Platform, SerNum, List]) ->
    Platform1 = pt:write_string(Platform),
	Len = length(List),
	List2 = lists:map(fun({DesignId, Content, _EndTime}) ->
		Content2 = pt:write_string(Content),
		<<DesignId:32, Content2/binary>>
	end, List),
	Bin = list_to_binary(List2),
    {ok, pt:pack(12096, <<RoleId:32, Platform1/binary, SerNum:16, Len:16, Bin/binary>>)};

%% 播放一段动画
write(12097, [RoleType, RoleId, MovieType, Value]) ->
    {ok, pt:pack(12097, <<RoleType:8, RoleId:32, MovieType:8, Value:16>>)};

%% 怪物变身
write(12098, [Id, Icon]) ->
    {ok, pt:pack(12098, <<Id:32, Icon:32>>)};

%% 变身
write(12099, [PlayerId, Platform, SerNum, Figure, LastTime]) ->
    Platform1 = pt:write_string(Platform),
    {ok, pt:pack(12099, <<PlayerId:32, Platform1/binary, SerNum:16, Figure:32, LastTime:32>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

%% =====私有函数=======

%% 打包元素列表
pack_elem_list([]) ->
    <<0:16, <<>>/binary>>;
pack_elem_list(Elem) ->
    Rlen = length(Elem),
    F = fun([Sid, Name, X, Y]) ->
        Name1 = pt:write_string(Name),
        <<Sid:32, Name1/binary, X:16, Y:16>>
    end,
    RB = list_to_binary([F(D) || D <- Elem]),
    <<Rlen:16, RB/binary>>.

%% 打包怪物列表
pack_mon_list([]) ->
    <<0:16, <<>>/binary>>;
pack_mon_list(Mon) ->
    F = fun(D) ->
        binary_12007(D)
    end,
    MonBin = [F(D) || D <- Mon, D#ets_mon.hp > 0],
    Rlen = length(MonBin),
    RB = list_to_binary(MonBin),
    <<Rlen:16, RB/binary>>.

%% 打包NPC列表
pack_npc_list([]) ->
    <<0:16, <<>>/binary>>;
pack_npc_list(Npc) ->
    Rlen = length(Npc),
    F = fun(EtsNpc) ->
        Id = EtsNpc#ets_npc.id, 
        Name = pt:write_string(EtsNpc#ets_npc.name), 
        X = EtsNpc#ets_npc.x, 
        Y = EtsNpc#ets_npc.y, 
        Icon = EtsNpc#ets_npc.icon, 
        Image = EtsNpc#ets_npc.image, 
        Func = EtsNpc#ets_npc.func, 
        Realm = EtsNpc#ets_npc.realm,
        <<Id:32, Id:32, Name/binary, X:16, Y:16, Icon:32, Func:8, Realm:8, Image:32>>
    end,
    RB = list_to_binary([F(D) || D <- Npc]),
    <<Rlen:16, RB/binary>>.

%% 打包场景相邻关系数据
pack_scene_border([], Result) ->
    list_to_binary(Result);
pack_scene_border([{Id, Border} | T], Result) ->
    L = length(Border),
    B = list_to_binary([<<X:32>> || X <- Border]),
    Bin = <<Id:32, L:16, B/binary>>,
    pack_scene_border(T, [Bin | Result]).

pack_scene_user_list([]) ->
    <<0:16, <<>>/binary>>;
pack_scene_user_list(User) ->
    UserBin = pack_scene_user_list_helper(User, []),
    Rlen = length(UserBin),
    RB = list_to_binary(UserBin),
    <<Rlen:16, RB/binary>>.

pack_scene_user_list_helper([], List) ->
    List;
pack_scene_user_list_helper([D | T], List) ->
    case trans_to_12003(D) of
        [] ->
            pack_scene_user_list_helper(T, List);
        D1 ->
            pack_scene_user_list_helper(T, [binary_12003(D1) | List])
    end.

%% 打包玩家离开列表
pack_leave_list([]) ->
    <<0:16, <<>>/binary>>;
pack_leave_list(User) ->
    Rlen = length(User),
    F = fun([Id, Platform, SerNum]) ->
            Platform1 = pt:write_string(Platform),
            <<Id:32, Platform1/binary, SerNum:16>> 
    end,
    RB = list_to_binary([F(D) || D <- User]),
    <<Rlen:16, RB/binary>>.

%% 打包怪物离开列表
pack_mon_leave_list([]) ->
    <<0:16, <<>>/binary>>;
pack_mon_leave_list(User) ->
    Rlen = length(User),
    F = fun(Id) ->
            <<Id:32>> 
    end,
    RB = list_to_binary([F(D) || D <- User]),
    <<Rlen:16, RB/binary>>.

binary_12003([Id, Platform, ServerNum, Nick, Sex, Lv, X, Y, Hp, HpLim, Mp, MpLim, Leader, PetFigure, 
			  PetNimbus, PetName, PetLevel, PetQuality, Weapon, Clothes, Career, 
			  Realm, Group, SitDown, SitRole, DesignList, Flymount, Speed, MountFigure, 
			  HusongLv, HusongNpc, PKStatus, PKValue, Anger, AngerLim, PlayerFigure, FashionWeapon, Stren1,
              FashionArmor, Stren2, FashionAccessory, Stren3, Vip, GuildId, GuildName, 
			  GuildPosition, SuitId, StrenNum, WqStren,Continues_kill,ParnerId,Peach_num,FactionWarStone, MarriageParnerId, IsCruise, QiLing, Image, Fly, Flyer, Visible, CombatPower, FashionHead, Stren4, FashionTail, Stren5, FashionRing, Strne6, Body, Feet]) ->
    Platform1 = pt:write_string(Platform),
	Nick1 = pt:write_string(Nick),
    PetName1 = pt:write_string(PetName),
	GuildNameBin = pt:write_string(GuildName),
	{DesignLen, DesignListBin} = lib_designation:get_client_design_by_ids(Id, DesignList),
    S7 = pt:write_string(integer_to_list(StrenNum)),
    <<Id:32, Platform1/binary, ServerNum:16, Nick1/binary, Sex:8, Lv:16, X:16, Y:16, Hp:32, HpLim:32, Mp:32, 
	  MpLim:32, Leader:8, PetFigure:16, PetNimbus:16, PetName1/binary, 
	  PetLevel:16, PetQuality:8, Weapon:32, Clothes:32, Career:8, Realm:8, 
	  Group:32, SitDown:8, SitRole:32, DesignLen:16, DesignListBin/binary, 
	  Flymount:32, Speed:16, MountFigure:32, HusongLv:32, HusongNpc:32, PKStatus:8, 
	  PKValue:16, Anger:32, AngerLim:32, PlayerFigure:32, FashionWeapon:32, Stren1:8,
      FashionArmor:32, Stren2:8, FashionAccessory:32, Stren3:8, Vip:8, GuildId:32, 
	  GuildNameBin/binary, GuildPosition:8, SuitId:32, S7/binary, WqStren:8,
	  Continues_kill:16, ParnerId:32,Peach_num:16, FactionWarStone:8, MarriageParnerId:32, IsCruise:8, QiLing:32, Image:32, Fly:32, Flyer:32, Visible:8, CombatPower:32, FashionHead:32, Stren4:8, FashionTail:32, Stren5:8, FashionRing:32, Strne6:8, Body:16, Feet:16>>.

binary_12007(S) ->
    #ets_mon{
        x       = X,
        y       = Y,
        id      = Id,
        mid     = Mid,
        hp      = Hp,
        hp_lim  = HpLim,
        lv      = Lv,
        name    = Name,
        speed   = Speed,
        icon    = Icon,
        att_type = AttType,
        kind    = Kind,
        color   = Color,
        out     = Out,
        boss    = Boss,
        collect_time = CollectTime,
        change_player_id = ChangePlayerId,
        is_be_atted      = IsBeAtted,
        is_be_clicked    = IsBeClicked,
        group            = Group
    } = S,
    Name1 = pt:write_string(Name),
    <<X:16, Y:16, Id:32, Mid:32, Hp:32, HpLim:32, Lv:16, Name1/binary, Speed:16, Icon:32, AttType:8, Kind:8, 
    Color:8, Out:8, Boss:8, CollectTime:32, ChangePlayerId:32, IsBeClicked:8, IsBeAtted:8, Group:32>>.

%% 人物
trans_to_12003(D) when is_record(D, ets_scene_user)->
    [Weapon, Clothes, _Zq, WqStren, _YfStren, _Sz] = D#ets_scene_user.equip_current,
    [FashionWeapon1, Stren1] = D#ets_scene_user.fashion_weapon,
    [FashionArmor1, Stren2] = D#ets_scene_user.fashion_armor,
    [FashionAccessory1, Stren3] = D#ets_scene_user.fashion_accessory,
    [FashionHead1, Stren4] = D#ets_scene_user.fashion_head,
    [FashionTail1, Stren5] = D#ets_scene_user.fashion_tail,
    [FashionRing1, Stren6] = D#ets_scene_user.fashion_ring,
    SceneUserPet = D#ets_scene_user.pet,
    Sit = D#ets_scene_user.sit,
    Husong = D#ets_scene_user.husong,
    PK = D#ets_scene_user.pk,
	Arena = D#ets_scene_user.arena,
	Peach = D#ets_scene_user.peach,
    MarriageParnerId = case D#ets_scene_user.marriage_register_time of
        0 -> 0;
        _ -> D#ets_scene_user.marriage_parner_id
    end,
    if
        D#ets_scene_user.hide_fashion_armor =:= 1 ->
            FashionArmor = 0;
        true ->
            FashionArmor = FashionArmor1
    end,
    if
        D#ets_scene_user.hide_fashion_weapon =:= 1 ->
            FashionWeapon = 0;
        true ->
            FashionWeapon = FashionWeapon1
    end,
    if
        D#ets_scene_user.hide_fashion_accessory =:= 1 ->
            FashionAccessory = 0;
        true ->
            FashionAccessory = FashionAccessory1
    end,
    if
        D#ets_scene_user.hide_head =:= 1 ->
            FashionHead = 0;
        true ->
            FashionHead = FashionHead1
    end,
    if
        D#ets_scene_user.hide_tail =:= 1 ->
            FashionTail = 0;
        true ->
            FashionTail = FashionTail1
    end,
    if
        D#ets_scene_user.hide_ring =:= 1 ->
            FashionRing = 0;
        true ->
            FashionRing = FashionRing1
    end,
    [D#ets_scene_user.id,
     D#ets_scene_user.platform, 
     D#ets_scene_user.server_num, 
	 D#ets_scene_user.nickname, 
	 D#ets_scene_user.sex, 
	 D#ets_scene_user.lv, 
	 D#ets_scene_user.x,
	 D#ets_scene_user.y, 
	 D#ets_scene_user.hp, 
	 D#ets_scene_user.hp_lim, 
	 D#ets_scene_user.mp, 
	 D#ets_scene_user.mp_lim,
	 D#ets_scene_user.leader, 
	 SceneUserPet#scene_user_pet.pet_figure, 
	 SceneUserPet#scene_user_pet.pet_nimbus, 
	 SceneUserPet#scene_user_pet.pet_name,
	 SceneUserPet#scene_user_pet.pet_level, 
	 SceneUserPet#scene_user_pet.pet_quality, 
	 Weapon, 
	 Clothes, 
	 D#ets_scene_user.career, 
	 D#ets_scene_user.realm,
	 D#ets_scene_user.group, 
	 Sit#scene_user_sit.sit_down,
	 Sit#scene_user_sit.sit_role,
	 D#ets_scene_user.design, 
	 D#ets_scene_user.fly_mount, 
	 D#ets_scene_user.speed, 
	 D#ets_scene_user.mount_figure, 
	 Husong#scene_user_husong.husong_lv,
	 Husong#scene_user_husong.husong_npc, 
	 PK#scene_user_pk.pk_status, 
	 PK#scene_user_pk.pk_value,
     D#ets_scene_user.anger, 
     D#ets_scene_user.anger_lim,
     D#ets_scene_user.figure,
     FashionWeapon, Stren1,
     FashionArmor, Stren2,
     FashionAccessory, Stren3,
     D#ets_scene_user.vip_type,
	 D#ets_scene_user.guild_id,
	 D#ets_scene_user.guild_name,
	 D#ets_scene_user.guild_position,
     D#ets_scene_user.suit_id,
     D#ets_scene_user.stren7_num,
     WqStren,
	 Arena#scene_user_arena.continues_kill,
     D#ets_scene_user.parner_id,
	 Peach#scene_user_peach.peach_num,
     D#ets_scene_user.factionwar_stone,
     MarriageParnerId,
     D#ets_scene_user.is_cruise,
	 D#ets_scene_user.qiling,
	 D#ets_scene_user.image,
     D#ets_scene_user.flyer_figure,
     D#ets_scene_user.flyer_sky_figure,
     %% D#ets_scene_user.flyer,
     D#ets_scene_user.visible,
     D#ets_scene_user.battle_attr#battle_attr.combat_power,
     FashionHead, Stren4, FashionTail, Stren5, FashionRing, Stren6,
     D#ets_scene_user.body_effect,
     D#ets_scene_user.feet_effect
     ];

trans_to_12003(Status) when is_record(Status, player_status)->
    Pet = Status#player_status.pet,
    Equip = Status#player_status.goods,
    Sit = Status#player_status.sit,
    Mou = Status#player_status.mount,
    Vip = Status#player_status.vip,
    [Weapon, Clothes, _Zq, WqStren, _YfStren, _Sz] = Equip#status_goods.equip_current,
    [FashionWeapon1, Stren1] = Equip#status_goods.fashion_weapon,
    [FashionArmor1, Stren2] = Equip#status_goods.fashion_armor,
    [FashionAccessory1, Stren3] = Equip#status_goods.fashion_accessory,
    [FashionHead1, Stren4] = Equip#status_goods.fashion_head,
    [FashionTail1, Stren5] = Equip#status_goods.fashion_tail,
    [FashionRing1, Stren6] = Equip#status_goods.fashion_ring,
    if
        Equip#status_goods.hide_fashion_armor =:= 1 ->
            FashionArmor = 0;
        true ->
            FashionArmor = FashionArmor1
    end,
    if
        Equip#status_goods.hide_fashion_accessory =:= 1 ->
            FashionAccessory = 0;
        true ->
            FashionAccessory = FashionAccessory1
    end,
    if
        Equip#status_goods.hide_fashion_weapon =:= 1 ->
            FashionWeapon = 0;
        true ->
            FashionWeapon = FashionWeapon1
    end,
    if
        Equip#status_goods.hide_head =:= 1 ->
            FashionHead = 0;
        true ->
            FashionHead = FashionHead1
    end,
    if
        Equip#status_goods.hide_tail =:= 1 ->
            FashionTail = 0;
        true ->
            FashionTail = FashionTail1
    end,
    if
        Equip#status_goods.hide_ring =:= 1 ->
            FashionRing = 0;
        true ->
            FashionRing = FashionRing1
    end,
    %io:format("2222 ~p~n", [{FashionWeapon, FashionArmor, FashionAccessory, Equip#status_goods.hide_fashion_armor,Equip#status_goods.hide_fashion_accessory}]),
    Husong = Status#player_status.husong,
    HusongLv = Husong#status_husong.husong_lv,
    HusongNpc = Husong#status_husong.husong_npc,
    PK = Status#player_status.pk,
    PKStatus = PK#status_pk.pk_status,
    PKValue = PK#status_pk.pk_value,
    PetQuality = data_pet:get_quality(Pet#status_pet.pet_aptitude),
    Anger = Status#player_status.anger,
    AngerLim = Status#player_status.anger_lim,
	Continues_kill = 0,
	Peach_num = Status#player_status.peach_num,
    MarriageParnerId = case Status#player_status.marriage#status_marriage.register_time of
        0 -> 0;
        _ -> Status#player_status.marriage#status_marriage.parner_id
    end,
    [Status#player_status.id, 
     Status#player_status.platform,
     Status#player_status.server_num,
	 Status#player_status.nickname, 
	 Status#player_status.sex, 
	 Status#player_status.lv, 
	 Status#player_status.x,
	 Status#player_status.y, 
	 Status#player_status.hp, 
	 Status#player_status.hp_lim, 
	 Status#player_status.mp, 
	 Status#player_status.mp_lim,
	 Status#player_status.leader, 
	 Pet#status_pet.pet_figure, 
	 Pet#status_pet.pet_nimbus, 
	 Pet#status_pet.pet_name, 
	 Pet#status_pet.pet_level, 
	 PetQuality,
	 Weapon, 
	 Clothes, 
	 Status#player_status.career, 
	 Status#player_status.realm,
	 Status#player_status.group,  
	 Sit#status_sit.sit_down, 
	 Sit#status_sit.sit_role,
	 Status#player_status.designation, 
     Mou#status_mount.fly_mount, 
	 Status#player_status.speed, 
	 Mou#status_mount.mount_figure, 
	 HusongLv, 
	 HusongNpc, 
	 PKStatus, 
	 PKValue,
     Anger,
     AngerLim,
     Status#player_status.figure,
     FashionWeapon, Stren1,
     FashionArmor, Stren2,
     FashionAccessory, Stren3,
     Vip#status_vip.vip_type,
	 Status#player_status.guild#status_guild.guild_id,
	 Status#player_status.guild#status_guild.guild_name,
	 Status#player_status.guild#status_guild.guild_position,
     Equip#status_goods.suit_id,
     Equip#status_goods.stren7_num,
     WqStren,
	 Continues_kill,
     Status#player_status.parner_id,
	 Peach_num,
     Status#player_status.factionwar_stone,
     MarriageParnerId,
     Status#player_status.marriage#status_marriage.is_cruise,
	 Status#player_status.qiling,
	 Status#player_status.image,
     Status#player_status.flyer_attr#status_flyer.figure,
     Status#player_status.flyer_attr#status_flyer.sky_figure,
     %% Mou#status_mount.flyer,
     Status#player_status.visible,
     Status#player_status.combat_power,
     FashionHead, Stren4, FashionTail, Stren5, FashionRing, Stren6,
     Equip#status_goods.body_effect,
     Equip#status_goods.feet_effect
     ];

trans_to_12003(_Status) ->
    [].

pack_allmon_list([]) ->
    <<0:16, <<>>/binary>>;
pack_allmon_list(AllMon) ->
    Rlen = length(AllMon),
    F = fun(SceneMon) ->
        Id = SceneMon#ets_scene_mon.id,
        Name = pt:write_string(SceneMon#ets_scene_mon.mname),
        Kind = SceneMon#ets_scene_mon.kind,
        X = SceneMon#ets_scene_mon.x,
        Y = SceneMon#ets_scene_mon.y,
        Level = SceneMon#ets_scene_mon.lv,
        Out = SceneMon#ets_scene_mon.out,
        <<Id:32, Name/binary, Kind:8, X:16, Y:16, Level:16, Out:8>>
    end,
    RB = list_to_binary([F(D) || D <- AllMon]),
    <<Rlen:16, RB/binary>>.
