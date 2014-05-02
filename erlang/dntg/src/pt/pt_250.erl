%%%------------------------------------
%%% @Module  : pt_250
%%% @Author  : hc
%%% @Email   : hc@jieyou.com
%%% @Created : 2010.08.09
%%% @Description: 经脉协议
%%%------------------------------------

-module(pt_250).
-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%

%% 错误码
%%解析模块错误码(本读方法只用来调试用)
read(25000, _) ->
    {ok, [1000]};

%% 开脉
read(25001, <<MeridianId:8>>) ->
    {ok, [MeridianId]};

%%提升根骨
read(25002, <<MeridianId:8,IsUse:8,IsBuy:8>>) ->
    {ok, [MeridianId,IsUse,IsBuy]};

%%查看经脉系统信息
read(25003, <<Uid:32,Mid:8,Type:8>>) ->
    {ok, [Uid,Mid,Type]};

read(25004, _) ->
    {ok, []};

read(25005, <<MeridianId:8>>) ->
    {ok, [MeridianId]};

read(25006, <<Uid:32>>) ->
    {ok, [Uid]};

read(_Cmd, _R) ->
    {error, no_match}.

%%
%% 服务端 -> 客户端 ------------------------------------
%%
write(25000, [ErrorCode])->
	Data = <<ErrorCode:32>>,
    {ok, pt:pack(25000, Data)};

write(25001, [MeridianId,Result])->
	Data = <<MeridianId:8,Result:8>>,
    {ok, pt:pack(25001, Data)};

write(25002, [MeridianId,Result])->
	Data = <<MeridianId:8,Result:8>>,
    {ok, pt:pack(25002, Data)};

write(25003, Result)->
	case Result of 
		[Uid,Type,0] -> Data = <<Uid:32,Type:8,0:8>>;
		Other -> 
			Data = write_25003(Other)
	end,
    {ok, pt:pack(25003, Data)};

write(25004, [Result])->
	Data = <<Result:8>>,
    {ok, pt:pack(25004, Data)};

write(25005, [Result])->
	Data = <<Result:8>>,
    {ok, pt:pack(25005, Data)};

write(25006, [{Meridian_Gap,[{Mer_Hp3,Gen_Hp3}, {Mer_Mp3,Gen_Mp3}, {Mer_Def3,Gen_Def3}, {Mer_Hit3,Gen_Hit3}, {Mer_Dodge3,Gen_Dodge3}, 
			  {Mer_Ten3,Gen_Ten3},{Mer_Crit3,Gen_Crit3}, {Mer_Att3,Gen_Att3}, {Mer_Fire3,Gen_Fire3}, 
			  {Mer_Ice3,Gen_Ice3}, {Mer_Drug3,Gen_Drug3}]}])->
	Data = <<Mer_Ten3:16, Mer_Mp3:16, Mer_Def3:16, Mer_Hit3:16, Mer_Dodge3:16, Mer_Hp3:16,Mer_Crit3:16, Mer_Att3:16, Mer_Fire3:16, Mer_Ice3:16, Mer_Drug3:16,Meridian_Gap:8,
			 Gen_Ten3:16, Gen_Mp3:16, Gen_Def3:16, Gen_Hit3:16, Gen_Dodge3:16, Gen_Hp3:16,Gen_Crit3:16, Gen_Att3:16, Gen_Fire3:16, Gen_Ice3:16, Gen_Drug3:16>>,
    {ok, pt:pack(25006, Data)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

write_25003(Data)->
	[ Uid,       %%玩家ID,
	  Type,
      Online,
	  JJType,
	  Mid,
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
	  Ghpmp,       %%气血境界等级,
	  Gdef,      %%防御境界等级,
	  Gdoom,     %%命中境界等级,
	  Gjook,     %%闪避境界等级,
	  Gtenacity, %%坚韧境界等级,
	  Gsudatt,   %%暴击境界等级,
	  Gatt,      %%攻击境界等级,
	  Gfiredef,  %%火坑境界等级,
	  Gicedef,   %%冰抗境界等级,
	  Gdrugdef,  %%毒抗境界等级,
	  Grhprmp,      %%气血境界附加成功率,
	  Grdef,     %%防御境界附加成功率,
	  Grdoom,    %%命中境界附加成功率,
	  Grjook,    %%闪避境界附加成功率,
	  Grtenacity,%%坚韧境界附加成功率,
	  Grsudatt,  %%暴击境界附加成功率,
	  Gratt,     %%攻击境界附加成功率,
	  Grfiredef, %%火坑境界附加成功率,
	  Gricedef,  %%冰抗境界附加成功率,
	  Grdrugdef,  %%毒抗境界附加成功率
	  _CdMid,
	  _CdTime,
	  THpMp,        %%气血内功已突破等级,
	  TDef,       %%防御已突破等级,
	  TDoom,      %%命中已突破等级,
	  TJook,      %%闪避已突破等级,
	  TTenacity,  %%坚韧已突破等级,
	  TSudatt,    %%暴击已突破等级,
	  TAtt,       %%攻击已突破等级,
	  TFiredef,   %%火坑已突破等级,
	  TIcedef,    %%冰抗已突破等级,
	  TDrugdef,    %%毒抗已突破等级,
	  Miding,
	  RestCdTime
    ] = Data,
	<<Uid:32,       %%玩家ID,
      Type:8,
      Online:8,
	  JJType:8,
	  Mid:8,
	  Sudatt:8,        %%暴击内功等级,
	  Def:8,       %%防御内功等级,
	  Doom:8,      %%命中内功等级,
	  Jook:8,      %%闪避内功等级,
	  Tenacity:8,  %%坚韧内功等级,
      HpMp:8,        %%气血内功等级,
	  Att:8,       %%攻击内功等级,
	  Firedef:8,   %%火坑内功等级,
	  Icedef:8,    %%冰抗内功等级,
	  Drugdef:8,   %%毒抗内功等级,
	  Gsudatt:8,       %%暴击境界等级,
	  Gdef:8,      %%防御境界等级,
	  Gdoom:8,     %%命中境界等级,
	  Gjook:8,     %%闪避境界等级,
	  Gtenacity:8, %%坚韧境界等级,
      Ghpmp:8,       %%气血境界等级,
	  Gatt:8,      %%攻击境界等级,
	  Gfiredef:8,  %%火坑境界等级,
	  Gicedef:8,   %%冰抗境界等级,
	  Gdrugdef:8,  %%毒抗境界等级,
      Grsudatt:8,       %%暴击境界附加成功率,
	  Grdef:8,     %%防御境界附加成功率,
	  Grdoom:8,    %%命中境界附加成功率,
	  Grjook:8,    %%闪避境界附加成功率,
	  Grtenacity:8,%%坚韧境界附加成功率,
      Grhprmp:8,      %%气血境界附加成功率,

	  Gratt:8,     %%攻击境界附加成功率,
	  Grfiredef:8, %%火坑境界附加成功率,
	  Gricedef:8,  %%冰抗境界附加成功率,
	  Grdrugdef:8, %%毒抗境界附加成功率
      TSudatt:8,        %%暴击已突破等级,
	  TDef:8,       %%防御已突破等级,
	  TDoom:8,      %%命中已突破等级,
	  TJook:8,      %%闪避已突破等级,
	  TTenacity:8,  %%坚韧已突破等级,
      THpMp:8,        %%气血内功已突破等级,

	  TAtt:8,       %%攻击已突破等级,
	  TFiredef:8,   %%火坑已突破等级,
	  TIcedef:8,    %%冰抗已突破等级,
	  TDrugdef:8,    %%毒抗已突破等级
	  Miding:8,      %%正在修炼的元神
	  RestCdTime:32%% 剩余CD时间(秒)
	>>.  