%%%-----------------------------------
%%% @Module  : pt_130
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.07.15
%%% @Description: 玩家信息
%%%-----------------------------------
-module(pt_130).
-export([read/2, write/2]).
-include("server.hrl").
-include("buff.hrl").
-include("goods.hrl").
-include("physical.hrl").

%%
%% 客户端 -> 服务端 ----------------------------
%%

%%走路
read(13001, _) ->
    {ok, info};

%% 指定ID玩家信息
read(13004, <<PlayerId:32>>) ->
    {ok, PlayerId};

%%获取快捷栏
read(13007, _) ->
    {ok, get};

%%保存快捷栏
read(13008, <<T:8, S:8, Id:32>>) ->
    {ok, [T, S, Id]};

%%删除快捷栏
read(13009, <<T:8>>) ->
    {ok, T};

%%替换快捷栏
read(13010, <<T1:8, T2:8>>) ->
    {ok, [T1, T2]};

%%客户端更新
read(13011, _) ->
    {ok, ref};

%%切换PK状态
read(13012, <<ID:8>>) ->
    {ok, [ID]};

%%获取buff列表
read(13014, _) ->
    {ok, []};

%%buff消失时调用
read(13015, <<Id:32>>) ->
    {ok, Id};

%% 获取血包列表
read(13060, _) ->
    {ok, hp_bag_list};

%% 血包回复
read(13061, <<Type:8>>) ->
    {ok, Type};

%% 清除国家守护技能
read(13063, _) ->
    {ok, []};

%% add by xieyunfei
%% 体力值每个小时加一点
read(13030, _) ->
    {ok, []};

%% add by xieyunfei
%% 获取体力值信息
read(13031, _) ->
    {ok, []};

%% add by xieyunfei
%% 加速清除冷却时间，加一点体力值。
read(13032, _) ->
    {ok, []};

%% 获取怒气值/怒气上限
read(13033, _) ->
    {ok, anger};

%% 上线请求技能
read(13034, _) -> 
    {ok, []};

%% 请求充值
read(13051, _) ->
    {ok, get_pay};

%% 变性
read(13065, _) ->
    {ok, no};

%% 头像信息
read(13067, _) ->
	{ok, []};

%% 切换头像
read(13068, <<ImageId:32, ImageType:8>>) ->
	{ok, [ImageId,ImageType]};

%% 使用朱颜果(头像道具)
read(13069, <<ImageId:32>>) ->
	{ok, [ImageId]};

%% 查询/修改用户配置
read(13070, <<Type:8, L:16, Bin/binary>>) ->
    List = read_arrary(13070, L, Bin, []),
	{ok, [Type, List]};

%% 点赞
read(13081, <<PlayerId:32>>) ->
    {ok, PlayerId};

%% 上传头像
read(13083, <<String/binary>>) ->
    {Picture, _} = pt:read_string(String),
    {ok, Picture};

%% 设置GPS经纬度
read(13084, <<Longitude:32/signed, Latitude:32/signed>>) ->
    {ok, [Longitude, Latitude]};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ----------------------------
%%

write(13001, PS) ->
    Id = PS#player_status.id,
    NickName = pt:write_string(PS#player_status.nickname),
    Sex = PS#player_status.sex,
    Lv = PS#player_status.lv,
    Scene = PS#player_status.scene,
    X = PS#player_status.x,
    Y = PS#player_status.y,
    Gm = PS#player_status.gm,
    Hp = PS#player_status.hp,
    HpLim = PS#player_status.hp_lim,
    Mp = PS#player_status.mp,
    MpLim = PS#player_status.mp_lim,
    Anger = PS#player_status.anger,
    AngerLim = PS#player_status.anger_lim,
    Career = PS#player_status.career,
    Realm = PS#player_status.realm,
    AttSpeed = PS#player_status.att_speed,
    AttArea = PS#player_status.att_area,
    Speed = PS#player_status.speed,
    Exp = PS#player_status.exp,
    Exp_lim = PS#player_status.exp_lim,
    PK = PS#player_status.pk,
    PKStatus = PK#status_pk.pk_status,
    PKValue = PK#status_pk.pk_value,
    
    Guild = PS#player_status.guild,
    Guild_id = Guild#status_guild.guild_id,
    Guild_name = pt:write_string(Guild#status_guild.guild_name),
    Guild_pos = Guild#status_guild.guild_position,
    
    Pet = PS#player_status.pet,
    PetFigure = Pet#status_pet.pet_figure,
    PetNimbus = Pet#status_pet.pet_nimbus,
    PetLevel = Pet#status_pet.pet_level,
    PetQuality = data_pet:get_quality(Pet#status_pet.pet_aptitude),
    _PetName = Pet#status_pet.pet_name,
    PetName = pt:write_string(_PetName),
    _Vip = PS#player_status.vip,
    Vip = _Vip#status_vip.vip_type,

    Goods = PS#player_status.goods,
    [E1, E2, _Zq, WqStren, _YfStren, _Sz] = Goods#status_goods.equip_current,
    S7 = pt:write_string(integer_to_list(Goods#status_goods.stren7_num)),
	
	%%称号处理
	{DesignLen, DesignBin} = lib_designation:get_client_design(PS),
    Mount = PS#player_status.mount,
    MountFigure = lib_mount2:get_new_figure(PS),
    Fly = Mount#status_mount.fly,
    Flyer = PS#player_status.flyer_attr#status_flyer.sky_figure,
    %% Mount#status_mount.flyer,
    Husong = PS#player_status.husong,
    HusongLv = Husong#status_husong.husong_lv,
    HusongNpc = Husong#status_husong.husong_npc,
	%% change by xieyunfei 
	Physical = PS#player_status.physical#status_physical.physical_count,
    PlayerFigure = PS#player_status.figure,
	case lib_secondary_password:is_pass_only_check(PS) of
		false->Secondary_password_is_pass = 0;
		true->Secondary_password_is_pass = 1
    end,
    case Goods#status_goods.hide_fashion_weapon =:= 0 of
        true ->
            [FashionWeapon, Stren1] = Goods#status_goods.fashion_weapon;
        false ->
            [FashionWeapon, Stren1] = [0,0]
    end,
    case Goods#status_goods.hide_fashion_armor =:= 0 of
        true ->
            [FashionArmor, Stren2] = Goods#status_goods.fashion_armor;
        false ->
            [FashionArmor, Stren2] = [0, 0]
    end,
    case Goods#status_goods.hide_fashion_accessory =:= 0 of
        true ->
            [FashionAccessory, Stren3] = Goods#status_goods.fashion_accessory;
        false ->
            [FashionAccessory, Stren3] = [0, 0]
    end,
    case Goods#status_goods.hide_head =:= 0 of
        true ->
            [FashionHead, Stren4] = Goods#status_goods.fashion_head;
        false ->
            [FashionHead, Stren4] = [0, 0]
    end,
    case Goods#status_goods.hide_tail =:= 0 of
        true ->
            [FashionTail, Stren5] = Goods#status_goods.fashion_tail;
        false ->
            [FashionTail, Stren5] = [0, 0]
    end,
    case Goods#status_goods.hide_ring =:= 0 of
        true ->
            [FashionRing, Stren6] = Goods#status_goods.fashion_ring;
        false ->
            [FashionRing, Stren6] = [0, 0]
    end,

    SuitId = Goods#status_goods.suit_id,
	NowTime = util:unixtime(),
%%     io:format("13001 ~p ~p~n", [Id, PetQuality]),
    ServerId = PS#player_status.server_id,
	QiLing = PS#player_status.qiling,
	Image = PS#player_status.image,
    Platform = pt:write_string(PS#player_status.platform),
    ServerNum = PS#player_status.server_num,
    Body = Goods#status_goods.body_effect,
    Feet = Goods#status_goods.feet_effect,
    %% 获赞
    Praise = PS#player_status.get_praise,
    Picture = pt:write_string(PS#player_status.picture),
    Data = <<
            Id:32,
            NickName/binary,
            Sex:8,
            Lv:16,
            Gm:8,
            Scene:32,
            X:16,
            Y:16,
            Hp:32,
            HpLim:32,
            Mp:32,
            MpLim:32,
            Career:8,
            Realm:8,
            AttSpeed:16,
            AttArea:8,
            Speed:16,
            Exp:32,
            Exp_lim:32,
            Guild_id:32,
            Guild_name/binary,
            Guild_pos:8,
            PetFigure:16,
            PetNimbus:16,
            PetName/binary,
            PetLevel:16,
            PetQuality:8,
            Vip:8,
            E1:32,
            E2:32,
			DesignLen:16,
			DesignBin/binary,
            MountFigure:32,
            HusongLv:32,
            HusongNpc:32,
            PKStatus:8,
            PKValue:16,
            Anger:32,
            AngerLim:32,
			Physical:32,
            PlayerFigure:16,
			Secondary_password_is_pass:8,
            FashionArmor:32, 
			Stren1:8,
            FashionWeapon:32, 
			Stren2:8, 
			FashionAccessory:32, 
			Stren3:8,
			NowTime:32,
            SuitId:32,
            S7/binary,
            WqStren:8,
            ServerId:32,
            QiLing:32,
			Image:32,
            Fly:32,
            Platform/binary,
            ServerNum:16,
            Flyer:32,
            FashionHead:32, Stren4:8, FashionTail:32, Stren5:8, FashionRing:32, Stren6:8,
            Body:16, Feet:16,Praise:16,Picture/binary
            >>,
    {ok, pt:pack(13001, Data)};

%%加经验
write(13002, [Exp, ExpType]) ->
    {ok, pt:pack(13002, <<Exp:32, ExpType:8>>)};

%% %%升级
%% write(13003, [Hp, Mp, Lv, Exp, Exp_lim]) ->
%%     {ok, pt:pack(13003, <<Hp:32, Mp:32, Lv:16, Exp:32, Exp_lim:32>>)};

%% 指定ID玩家信息
%%     int:32 用户ID
%%     int:32 气血
%%     int:32 气血上线
%%     int:32 内息
%%     int:32 内息上线
%%     int:8  性别
%%     int:8  等级
%%     int:8  职业
%%     string 玩家名
%%     int:16 攻击
%%     int:16 防御
%%     int:16 命中
%%     int:16 躲避
%%     int:16 暴击
%%     int:16 坚韧
%%     int:16 帮派id
%%     string 帮派名
%%     int:8  帮派职位
%%     int:8  阵营
%%     int:32 灵力
%%     int:8  职位
%%     int:8  爵位
%%     int:16 罪恶值
%%     int:16 力量
%%     int:16 身法 
%%     int:16 灵力
%%     int:16 体力
%%     int:16 火
%%     int:16 冰
%%     int:16 毒
%%     int:32 历练声望
%%     int:32 修为声望
%%     int:32 副本声望
%%     int:32 帮派声望
%%     int:32 国家声望
%%     int:8  vip
%%     int:32 荣誉
%%     int:32 魅力声望
%%     int:32 帝王谷荣誉
%%     int:8 武器发光
%%     int:32 全身装备加7发光
%%     int:32 套装发光
%%     int:32 配偶角色Id
%%     string 配偶角色名
%%     string 师傅名字
%%     int:16 数组大小
%%     string 徒弟名字串
%%     int:32 战斗力
%%     int:8  帮派职位
%%     int:32 武器时装ID
%%     int:32 衣服时装ID
%%     int:32 饰品时装ID
%%     int:16 跨服勋章等级
%%     int:32 师道值
write(13004, []) -> %%不在线
    Data = <<0:32,0:32,0:32,0:32,0:32,0:16,0:16,8:16,
            0:16,0:16,0:16,0:16,0:16,0:16,0:16,
            0:8,0:8,0:32,0:8,
            0:16,0:16,0:16,0:16,0:16,0:16,0:16,0:16,
            0:32,0:32,0:32,0:32,0:32,0:32,0:8,0:32,0:32,0:8,
            0:32,0:32,0:32,0:32,0:32,
             0:16,<<>>/binary,
             0:16,<<>>/binary,
             0:16,<<>>/binary,  %% 全身发光
             0:32, 0:16, 0:32, 0:16, 0:32, 0:16,
			 0:32,
			 0:32,
             0:32,
             0:32,
             0:16,<<>>/binary,
             0:32, 0:32, 0:32, 0:16, <<>>/binary
             >>,
    {ok, pt:pack(13004, Data)};

write(13004, [Id, Hp, Hp_lim, Mp, Mp_lim, Sex, Lv, Career, Nickname, Att, Def, Hit, Dodge, Crit, Ten, 
              GuildId, GuildName, GuildPosition, Realm, Spirit, Jobs, Pk_value, Forza, Agile, 
              Wit, Thew, Fire, Ice, Drug, Llpt, Xwpt, Fbpt, Fbpt2, Bppt, Gjpt, Vip, Honour, Mlpt,
              Equip_Current,Stren7_num,SuitId, Combat_power, Fashion_weapon, Fashion_armor, Fashion_accessory, 
              Hide_fashion_weapon, Hide_fashion_armor, Hide_fashion_accessory, SuitList,Arena_Score,Whpt,Factionwar_Score,
              ParnerId, ParnerName, FashionHead, FashionTail, FashionRing, HideHead, HideTail, HideRing, Praise, Picture]) ->  %%在线
   NewPicture = pt:write_string(Picture),
    Nick1 = pt:write_string(Nickname),
    GuildName1 = pt:write_string(GuildName),
    S7 = pt:write_string(integer_to_list(Stren7_num)),
    ParName = pt:write_string(ParnerName),
    [_E1, _E2, _E3, E4, _E5, _Sz] = Equip_Current,
    [Wqsz, _WqszStren] = case Hide_fashion_weapon =:= 1 of
                            false -> Fashion_weapon;
                            true ->[0,0]
                         end,
    [Yfsz, _YfszStren] = case Hide_fashion_armor =:= 1 of
                            false -> Fashion_armor;
                            true ->[0,0]
                         end,
    [Spsz, _SpszStren] = case Hide_fashion_accessory =:= 1 of
                            false -> Fashion_accessory;
                            true ->[0,0]
                         end,
    [Head, _] = case HideHead =:= 1 of
                    false -> FashionHead;
                    true ->[0,0]
                end,
    [Tail, _] = case HideTail =:= 1 of
                    false -> FashionTail;
                    true ->[0,0]
                end,
    [Ring, _] = case HideRing =:= 1 of
                    false -> FashionRing;
                    true ->[0,0]
                end,
    [{SuitId1, Num1}, {SuitId2, Num2}, {Suitid3, Num3}] = SuitList,
    Data = <<Id:32,
            Hp:32,
            Hp_lim:32,
            Mp:32,
            Mp_lim:32,
            Sex:16,
            Lv:16,
            Career:8,
            Att:16,
            Def:16,
            Hit:16,
            Dodge:16,
            Crit:16,
            Ten:16,
            GuildId:16,
            GuildPosition:8,
            Realm:8,
            Spirit:32,
            Jobs:8,
            Pk_value:16,
            Forza:16, 
            Agile:16, 
            Wit:16,
            Thew:16, 
            Fire:16, 
            Ice:16, 
            Drug:16, 
            Llpt:32, 
            Xwpt:32,
            Fbpt:32,
			Fbpt2:32, 
            Bppt:32, 
            Gjpt:32,
            Vip:8,
            Honour:32,
            Mlpt:32,
            E4:8, 
            SuitId:32,
            Combat_power:32,
            Wqsz:32,
            Yfsz:32,
            Spsz:32,
			Nick1/binary,
			GuildName1/binary,
            S7/binary,
            SuitId1:32,
			Num1:16, 
			SuitId2:32, 
			Num2:16,
            Suitid3:32, Num3:16,
			Arena_Score:32,
			Whpt:32,
			Factionwar_Score:32,
            ParnerId:32,
            ParName/binary,
            Head:32, Tail:32, Ring:32, Praise:16, NewPicture/binary
            >>,
    {ok, pt:pack(13004, Data)};
    

%% 更新人物信息
write(13005, Type) ->
	{ok, pt:pack(13005, <<Type:8>>)};

%%获取快捷栏
write(13007, []) ->
    {ok, pt:pack(13007, <<0:16, <<>>/binary>>)};
write(13007, Quickbar) ->
    Rlen = length(Quickbar),
    F = fun({L, T, Id}) ->
        <<L:8, T:8, Id:32>>
    end,
    RB = list_to_binary([F(D) || D <- Quickbar]),
    {ok, pt:pack(13007, <<Rlen:16, RB/binary>>)};

%%保存快捷栏
write(13008, State) ->
    {ok, pt:pack(13008, <<State:8>>)};

%%删除快捷栏
write(13009, State) ->
    {ok, pt:pack(13009, <<State:8>>)};

%%替换快捷栏
write(13010, State) ->
    {ok, pt:pack(13010, <<State:8>>)};

%%角色属性改变通知
write(13011, [PlayerId, ChangeReason, Level, Exp, ExpLimit, Hp, HpLimit, Mp, MpLimit, Att, Def, Hit, Dodge, Crit, Ten,
    Gold, Silver, Coin, Bcoin, Forza, Agile, Wit, Thew, Fire, Ice, Drug, Llpt, Xwpt, Fbpt, Fbpt2, Bppt, Gjpt, Vip,
    Honour, Mlpt, HpBagNum, MpBagNum,Combat_power, Point, DesignLen, DesignBin,Whpt, HideArmor, HideAccessory, 
	Stren7Num, SuitList, ArenaScore, AngerLim,Factionwar_Score,ParnerId, ParnerName, Image,Kf_pt,Kf_score, HideWeapon, HideHead, HideTail, HideRing]) ->
    S7 = pt:write_string(integer_to_list(Stren7Num)),
    ParName = pt:write_string(ParnerName),
    [{SuitId1, Num1}, {SuitId2, Num2}, {SuitId3, Num3}] = SuitList,
    Data = <<PlayerId:32, ChangeReason:16, Level:16, Exp:32, ExpLimit:32, Hp:32, HpLimit:32, Mp:32, MpLimit:32, Att:16, Def:16, Hit:16, Dodge:16, Crit:16, Ten:16,
            Gold:32,
            Silver:32,
            Coin:32,
            Bcoin:32,
            Forza:16, 
            Agile:16, 
            Wit:16,
            Thew:16, 
            Fire:16, 
            Ice:16, 
            Drug:16, 
            Llpt:32, 
            Xwpt:32,
            Fbpt:32,
			Fbpt2:32, 
            Bppt:32, 
            Gjpt:32,
            Vip:8,
            Honour:32,
            Mlpt:32,
            HpBagNum:32,
            MpBagNum:32,
            Combat_power:32,
            Point:32,
			DesignLen:16,
			DesignBin/binary,
			Whpt:32,
            HideArmor:8, HideAccessory:8,
            S7/binary,SuitId1:32, Num1:16,
            SuitId2:32, Num2:16, SuitId3:32, Num3:16,
            ArenaScore:32,
            AngerLim:8,
            Factionwar_Score:32,
            ParnerId:32,
            ParName/binary,
			Image:32,
			Kf_pt:32,
			Kf_score:32, HideWeapon:8, HideHead:8, HideTail:8, HideRing:8>>,
    {ok, pt:pack(13011, Data)};

%%切换PK状态
write(13012, [ErrorCode, PkType, LeftTime]) ->
    {ok, pt:pack(13012, <<ErrorCode:8, LeftTime:32, PkType:8>>)};

%% BUFF状态通知
write(13014, [PlayerId, BuffList]) ->
    NowTime = util:unixtime(),
    ListNum = length(BuffList),
    F = fun(BuffInfo) ->
                BuffId = BuffInfo#ets_buff.id,
                GoodsTypeId = BuffInfo#ets_buff.goods_id,
                EndTime = BuffInfo#ets_buff.end_time - NowTime,
                <<BuffId:32, GoodsTypeId:32, EndTime:32>>
        end,
    ListBin = list_to_binary(lists:map(F, BuffList)),
    {ok, pt:pack(13014, <<PlayerId:32, ListNum:16, ListBin/binary>>)};

%% 喝酒广播
write(13021, [Type, GoodsId, PlayerId]) ->
    {ok, pt:pack(13021, <<Type:8, GoodsId:16, PlayerId:32>>)};

%% 获取血包列表
write(13060, List) ->
    ListNum = length(List),
    F = fun(Info) ->
            Type = Info#ets_hp_bag.type,
            Bag_num = Info#ets_hp_bag.bag_num,
            Goods_id = Info#ets_hp_bag.goods_id,
            Span = lib_hp_bag:get_reply_span(Type),
            <<Type:8, Goods_id:32, Bag_num:32, Span:8>>
        end,
     ListBin = list_to_binary(lists:map(F, List)),
    {ok, pt:pack(13060, <<ListNum:16, ListBin/binary>>)};

%% 血包回复
write(13061, [Res, Type, GoodsId, BagNum, Span, Mp]) ->
	{ok, pt:pack(13061, <<Res:16, Type:8, GoodsId:32, BagNum:32, Span:8, Mp:32>>)};

%% 查询国家守护技能
write(13062, [BuffState, NationalDef, NationalRes, RestTime]) ->
    {ok, pt:pack(13062, <<BuffState:8, NationalDef:16, NationalRes:16, RestTime:16>>)};

%% add by xieyunfei
%% 体力值每个小时加一点，判断现在是否刷新体力值,Refresh：0否，1是
write(13030, Refresh) ->
    {ok, pt:pack(13030, <<Refresh:8>>)};


%% add by xieyunfei
%% 获得角色体力信息
write(13031, [PhysicalCount,PhysicalSum,AcceleratUse,AcceleratSum,CdTime,CostGold]) ->
    {ok, pt:pack(13031, <<PhysicalCount:8,PhysicalSum:8,AcceleratUse:8,AcceleratSum:8,CdTime:16,CostGold:8>>)};


%% add by xieyunfei
%% 加速清除冷却时间，加一点体力值。
write(13032, IsAccelerat) ->
    {ok, pt:pack(13032, <<IsAccelerat:8>>)};

%% 技能升级改变
write(13033, [Hp, HpLim, Att, Def, Hit, Dodge, Crit, Fire, Ice, Drug, Anger, AngerLim]) ->
    {ok, pt:pack(13033, <<Hp:32, HpLim:32, Att:16, Def:16, Hit:16, Dodge:16, Crit:16, Fire:16, Ice:16, Drug:16, Anger:32, AngerLim:32>>)};

%% 发送新增快捷栏内容
write(13034, [Type, L]) -> 
    Len = length(L),
    F = fun({SubType, SkillId}) ->
            <<SubType:8, SkillId:32>>
    end, 
    LB = list_to_binary([F(E)||E <- L]),
    {ok, pt:pack(13034, <<Type:8, Len:16, LB/binary>>)};

%% 让前端触发发起支付请求
write(13050, _) ->
    {ok, pt:pack(13050, <<1:32>>)};



%% 变性
write(13065, [Res]) ->
    {ok, pt:pack(13065, <<Res:8>>)};

%% 查看Id玩家信息时，给Id玩家发送提示
write(13066, [Sex, NickName]) ->
	NBin = pt:write_string(NickName),	
    {ok, pt:pack(13066, <<Sex:8, NBin/binary>>)};

%% 头像信息
write(13067, [NormalImage, SpecialImage, XianlvImage, LeftNum]) ->
	Len1 = length(NormalImage),
	Len2 = length(SpecialImage),
	Len3 = length(XianlvImage),
	F1 = fun({ImageId, Status}) ->
			<<ImageId:32, Status:8>>
	end,
	LB1 = list_to_binary([F1(E)||E<-NormalImage]),
	F2 = fun({ImageId, Status}) ->
			<<ImageId:32, Status:8>>
	end,
	LB2 = list_to_binary([F2(E)||E<-SpecialImage]),
	F3 = fun({ImageId, Status}) ->
			<<ImageId:32, Status:8>>
	end,
	LB3 = list_to_binary([F3(E)||E<-XianlvImage]),
	{ok, pt:pack(13067, <<Len1:16, LB1/binary, Len2:16, LB2/binary, Len3:16, LB3/binary, LeftNum:8>>)};

%% 切换头像
write(13068, [ResultCode, LeftNum]) ->
	{ok, pt:pack(13068, <<ResultCode:8, LeftNum:8>>)};

%% 使用朱颜果(头像道具)
write(13069, [ResultCode]) ->
	{ok, pt:pack(13069, <<ResultCode:8>>)};

%% 用户屏蔽数据
write(13070, [Res, List]) ->
    Len = length(List),
    Bin = list_to_binary([<<SubType:8, Value:8>> || {SubType, Value}<-List]),
	{ok, pt:pack(13070, <<Res:8, Len:16, Bin/binary>>)};

%% 世界等级经验加成buff图标
write(13080, [Show, Level, Percent, VipPercent]) ->
	{ok, pt:pack(13080, <<Show:8, Level:8, Percent:16, VipPercent:16>>)};

%% 点赞
write(13081, [Err, Num]) ->
    {ok, pt:pack(13081, <<Err:8, Num:16>>)};

%% 上传图像
write(13083, [Res, String]) ->
    Bin = pt:write_string(String),
    {ok, pt:pack(13083, <<Res:8, Bin/binary>>)};

%% 设置GPS经纬度
write(13084, Res) ->
    {ok, pt:pack(13084, <<Res:8>>)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

%% 读取数组
read_arrary(13070, 0, _, Arrary) -> Arrary; 
read_arrary(13070, L, <<SubType:8, Value:8, Bin/binary>>, Arrary) ->
    read_arrary(13070, L-1, Bin, [{SubType, Value}|Arrary]).
