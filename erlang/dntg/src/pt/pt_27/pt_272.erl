%%%--------------------------------------
%%% @Module  :  pt_272 
%%% @Author  :  hekai
%%% @Email   :  hekai@jieyou.cn
%%% @Created :  2012-9-27
%%% @Description: 仙缘系统
%%%--------------------------------------

-module(pt_272).
-export([read/2, write/2]).

%% ============================================ 
%% 客户端 -> 服务端
%% ============================================


%% 仙缘修炼
read(27201, <<Xianyuan_type:8>>) ->
	{ok, [Xianyuan_type]};

%% 加速修炼
read(27202, <<>>) ->
	{ok, []};

%% 仙缘修炼境界信息
read(27203, <<>>) ->
	{ok, []};

%% 使用物品增加甜蜜度
read(27205, <<>>) ->
	{ok, []};

%% 总加成
read(27206, <<Uid:32>>) ->
	{ok, [Uid]};

%% 释放夫妻技能
read(27207, <<SkillId:32>>) ->
	{ok, [SkillId]};

%% 夫妻技能信息
read(27208, <<>>) ->
	{ok, []};

%% 查看Id玩家仙缘修炼境界信息
read(27209, <<Id:32>>) ->
	{ok, [Id]};

%%  容错处理
read(_Cmd, _R) ->
    {error, no_match}.


%% ============================================
%% 服务端 -> 客户端
%% ============================================


%% 仙缘修炼
write(27201, [Xianyuan_type, Result]) ->
	Data = <<Xianyuan_type:8, Result:8>>,
	{ok, pt:pack(27201, Data)};

%% 加速修炼
write(27202, [Result]) ->
	Data = <<Result:8>>,
	{ok, pt:pack(27202, Data)};

%% 仙缘修炼、境界信息
write(27203, [Xtype, Xlv, Jlv, RestCdTime, IsCDing, Closeness, Sweetness, Parnet_career, Parnet_name, Skill_lv_1, Skill_lv_2]) ->
	Bin_Parnet = pt:write_string(Parnet_name),
	Data = <<Xtype:8			%% 仙缘类型
			,Xlv:8				%% 修炼级别
			,Jlv:8				%% 境界级别
			,IsCDing:8			%% 是否正在修炼 0否 1是
			,RestCdTime:32		%% 剩余CD时间(秒)			
			,Closeness:32		%% 当前亲密度
			,Sweetness:32		%% 当前甜蜜度
			,Parnet_career:8    %% 对方职业
			,Bin_Parnet/binary  %% 对方名
			,Skill_lv_1:8       %% 1040技能等级
			,Skill_lv_2:8>>,    %% 1050技能等级
	{ok, pt:pack(27203, Data)}; 

%% 境界提升消息
write(27204, [Xianyuan_type]) ->
	{ok, pt:pack(27204, <<Xianyuan_type:8>>)};

%% 使用物品增加甜蜜度
write(27205, [ReturnCode, GetSweetness]) ->
	{ok, pt:pack(27205, <<ReturnCode:8,GetSweetness:8>>)};

%% 修炼总加成
write(27206, [Val1,Val2,Val3,Val4,Val5,Val6,Val7,Val8,Val9,Val10,Val1_1,Val2_1,
		Val3_1,Val4_1,Val5_1,Val6_1,Val7_1,Val8_1,Val9_1,Val10_1,JLevel]) ->
	{ok, pt:pack(27206, <<Val1:32,Val2:32,Val3:32,Val4:32,Val5:32,Val6:32,Val7:32,Val8:32,Val9:32,Val10:32,
			Val1_1:32,Val2_1:32,Val3_1:32,Val4_1:32,Val5_1:32,Val6_1:32,Val7_1:32,Val8_1:32,Val9_1:32,
			Val10_1:32,JLevel:8>>)};

%% 释放夫妻技能
write(27207, [ReturnCode, Left_cd, Skill_id]) ->
	{ok, pt:pack(27207, <<ReturnCode:8, Left_cd:32, Skill_id:32>>)};


%% 夫妻技能信息
write(27208, [Skill]) ->
	SLen = length(Skill),
	F = fun([Id, Lv, Cd]) ->			
			<<Id:32, Lv:8, Cd:32>>
		 end,
	Skill2 = list_to_binary(lists:map(F, Skill)),
	{ok, pt:pack(27208, <<SLen:16, Skill2/binary>>)};

%% 查看Id玩家仙缘修炼境界信息
write(27209, [Xtype, Xlv, Jlv, RestCdTime, IsCDing, Closeness, Sweetness, Parnet_career, Parnet_name, Skill_lv_1, Skill_lv_2]) ->
	Bin_Parnet = pt:write_string(Parnet_name),
	Data = <<Xtype:8			%% 仙缘类型
			,Xlv:8				%% 修炼级别
			,Jlv:8				%% 境界级别
			,IsCDing:8			%% 是否正在修炼 0否 1是
			,RestCdTime:32		%% 剩余CD时间(秒)			
			,Closeness:32		%% 当前亲密度
			,Sweetness:32		%% 当前甜蜜度
			,Parnet_career:8    %% 对方职业
			,Bin_Parnet/binary  %% 对方名
			,Skill_lv_1:8       %% 1040技能等级
			,Skill_lv_2:8>>,    %% 1050技能等级
	{ok, pt:pack(27209, Data)}; 

%%  容错处理
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.
