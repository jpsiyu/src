%%%-----------------------------------
%%% @Module  : pt_110
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.04.29
%%% @Description: 11聊天信息
%%%-----------------------------------
-module(pt_110).
-export([read/2, write/2]).
-include("record.hrl").

%%
%%客户端 -> 服务端 ----------------------------
%%

%%世界聊天
read(11001, <<Bin/binary>>) ->
    {Msg, Bin1} = pt:read_string(Bin),
    <<TkTime:32, Bin2/binary>> = Bin1,
    {TK, _} = pt:read_string(Bin2),
    {ok, [Msg, TkTime, TK]};

%%私聊
read(11002, <<Id:32, Bin/binary>>) ->
    {Nick, Bin1} = pt:read_string(Bin),
    {Msg, RestBin} = pt:read_string(Bin1),
    <<FaceType:8, Color:8, IsMove:32, Bin2/binary>> = RestBin,
	{XyzMsg, RestBin2} = pt:read_string(Bin2),
	<<ScenceId:16, X:16, Y:16, RestBin3/binary>> = RestBin2,
    <<TkTime:32, RestBin4/binary>> = RestBin3,
    {TK, _} = pt:read_string(RestBin4),
    {ok, [Id, Nick, Msg, FaceType, Color, IsMove, XyzMsg, ScenceId, X, Y, TkTime, TK]};

%%场景聊天
read(11003, <<Bin/binary>>) ->
    {Msg, Bin1} = pt:read_string(Bin),
    <<TkTime:32, Bin2/binary>> = Bin1,
    {TK, _} = pt:read_string(Bin2),
    {ok, [Msg, TkTime, TK]};

%%帮派聊天
read(11005, <<Bin/binary>>) ->
    {Msg, Bin2} = pt:read_string(Bin),
    <<GuildPosition:8, Bin3/binary>> = Bin2,
	<<Color:32,ScenceId:32,X:16,Y:16,Bin4/binary>> = Bin3,
	{PositionContent, Bin5} = pt:read_string(Bin4),
    <<TkTime:32, Bin6/binary>> = Bin5,
    {TK, <<FortuneId:16>>} = pt:read_string(Bin6),
    {ok, [Msg, GuildPosition,Color,ScenceId,X,Y,PositionContent,TkTime,TK,FortuneId]};

%%队伍聊天
read(11006, <<TeamId:32, Bin/binary>>) ->
    {Msg, Bin1} = pt:read_string(Bin),
    <<TkTime:32, Bin2/binary>> = Bin1,
    {TK, _} = pt:read_string(Bin2),
    {ok, [Msg, TeamId, TkTime, TK]};

%%阵营聊天
read(11008, <<Bin/binary>>) ->
    {Msg, Bin1} = pt:read_string(Bin),
    <<TkTime:32, Bin2/binary>> = Bin1,
    {TK, _} = pt:read_string(Bin2),
    {ok, [Msg, TkTime, TK]};

%%聊天输入状态
read(11012, <<Id:32, InputState:8>>) ->
    {ok, [Id, InputState]};

%%取私聊所需信息
read(11013, <<Id:32>>) ->
	{ok, Id};

%%取私聊所需信息
read(11014, <<Type:8,Bin/binary>>) ->
	{Msg, _} = pt:read_string(Bin),
	{ok, [Type,Msg]};

%%发送坐标
read(11016, <<Channel:8, Bin/binary>>) ->
	{Content, Bin1} = pt:read_string(Bin),
    <<SceneId:16, X:16, Y:16, Bin2/binary>> =Bin1,
	{Content2, _Bin3} = pt:read_string(Bin2),
	{ok, [Channel, Content, SceneId, X, Y, Content2]};

%%发送组队招募消息
read(11020, <<Lv:16,Energy:32,Bin/binary>>) ->
	{Msg,Bin2} = pt:read_string(Bin),
    <<Type:8, _/binary>> = Bin2,
	{ok, [Lv,Energy,Msg,Type]};

read(11031, <<Color:8,Bin/binary>>) ->
	{Content,Bin2} = pt:read_string(Bin),
	<<Type:8, Channel:8, Channel_id:32, _/binary>> = Bin2,
	{ok, [Color,Content,Type,Channel,Channel_id]};

read(11033, _) ->
	{ok, []};

read(11040, <<Uid:32,Limit_time:8>>) ->
	{ok, [Uid,Limit_time]};

read(11041, <<Uid:32>>) ->
	{ok, [Uid]};

read(11043, <<Uid:32>>) ->
	{ok, [Uid]};

read(11044, <<Uid:32>>) ->
	{ok, [Uid]};

read(11050, _) ->
    {ok, []};

%%[跨服]场景聊天
read(11062, <<Bin/binary>>) ->
    {Msg, Bin1} = pt:read_string(Bin),
    <<TkTime:32, Bin2/binary>> = Bin1,
    {TK, Bin3} = pt:read_string(Bin2),
	{Platform, Bin4} = pt:read_string(Bin3),
	<<ServerID:16, _/binary>> = Bin4,
    {ok, [Msg, TkTime, TK, Platform, ServerID]};

%%攻城战聊天
read(11070, <<Bin/binary>>) ->
    {Msg, Bin1} = pt:read_string(Bin),
    <<TkTime:32, Bin2/binary>> = Bin1,
    {TK, _} = pt:read_string(Bin2),
    {ok, [Msg, TkTime, TK]};

%% VIP免费号角剩余数量
read(11071, _) ->
    {ok, []};

%% 发送语音聊天
read(11080, <<MsgType:8, ReceiveId:32, VoiceMsgTime:16, TkTime:32, Bin/binary>>) -> 
    {Ticket, VoiceData} = pt:read_string(Bin),
    {Voice , <<ClientAutoId:32>>} = pt:read_voice_bin(VoiceData),
    {ok, [MsgType, ReceiveId, VoiceMsgTime, TkTime, Ticket, Voice, ClientAutoId]};

%% 获取语音内容
read(11081, <<ClientAutoId:32, TkTime:32, Bin/binary>>) -> 
    {Ticket, _} = pt:read_string(Bin),
    {ok, [ClientAutoId, TkTime, Ticket]};

%% 发送图片信息
read(11082, <<MsgType:8, ReceiveId:32, IsEnd:8, TkTime:32, Bin/binary>>) -> 
    {Ticket, PictureData}         = pt:read_string(Bin),
    {TinyPicture, RealPictureBin} = pt:read_voice_bin(PictureData),
    {RealPicture, _}              = pt:read_voice_bin(RealPictureBin),
    {ok, [MsgType, ReceiveId, IsEnd, TkTime, Ticket, TinyPicture, RealPicture]};

%% 获取图片内容
read(11083, <<AutoId:32, TkTime:32, Bin/binary>>) -> 
    {Ticket, _} = pt:read_string(Bin),
    {ok, [AutoId, TkTime, Ticket]};

%% 上传语音文字内容
read(11085, <<ClientAutoId:32, Bin/binary>>) -> 
    {VoiceTextData, _} = pt:read_string(Bin),
    {ok, [ClientAutoId, VoiceTextData]};

%% 获取语音文字内容
read(11086, <<ClientAutoId:32, PlayerId:32>>) -> 
    {ok, [ClientAutoId, PlayerId]};

read(_Cmd, _R) ->
    {error, no_match}.


%%
%%服务端 -> 客户端 ------------------------------------
%%

%%世界
write(11001, [Id, Nick, Realm, Sex, Bin, Gm,Vip,Career,Ringfashion]) ->
    Nick1 = list_to_binary(Nick),
    Len = byte_size(Nick1),
    Bin1 = pt:write_string(Bin),
    Data = <<Id:32, Len:16, Nick1/binary, Realm:8, Sex:8, Bin1/binary, Gm:8,Vip:8,Career:8,Ringfashion:32>>,
    {ok, pt:pack(11001, Data)};

%%私聊
write(11002, [Id, Nick, Bin, Sex, Career, FaceType, Color, IsMove, XyzMsg, ScenceId, X, Y, Ringfashion]) ->
    Nick1 = list_to_binary(Nick),
    Len = byte_size(Nick1),
    Bin1 = list_to_binary(Bin),
    Len1 = byte_size(Bin1),
	XyzMsg1 = list_to_binary(XyzMsg),
	Len2 = byte_size(XyzMsg1),
    Data = <<Id:32, Len:16, Nick1/binary, Len1:16, Bin1/binary, Sex:8, Career:8, FaceType:8, Color:8, IsMove:32, Len2:16, XyzMsg1/binary, ScenceId:16, X:16, Y:16, Ringfashion:32>>,
    {ok, pt:pack(11002, Data)};

%%场景聊天
write(11003, [Id, Nick, Realm, Sex, Bin, GM,Vip,Career,Ringfashion]) ->
    Nick1 = pt:write_string(Nick),
    %Len = byte_size(Nick1),
%    Bin1 = list_to_binary(Bin),
    Bin1 = make_sure_binary(Bin),
    Len1 = byte_size(Bin1),
    Data = <<Id:32, Nick1/binary, Realm:8, Sex:8, Len1:16, Bin1/binary, GM:8,Vip:8,Career:8,Ringfashion:32>>,
    {ok, pt:pack(11003, Data)};

%%聊天系统信息
write(11004, Msg) ->
    Msg1 = pt:write_string(Msg),
    %Len1 = byte_size(Msg1),
    Data = <<Msg1/binary>>,
    {ok, pt:pack(11004, Data)};

%%帮派系统信息
write(11005, [GuildId, GuildName, Realm, Sex, MsgContent, GM,Vip,Career, GuildPosition,Color,ScenceId,X,Y,PositionContent,FortuneId, Ringfashion]) ->
    GuildNameBin  = list_to_binary(GuildName),
    GuildNameLen  = byte_size(GuildNameBin),
%    MsgContentBin = list_to_binary(MsgContent),
    MsgContentBin = make_sure_binary(MsgContent),
    MsgContentLen = byte_size(MsgContentBin),
	PositionContentBin = pt:write_string(PositionContent),
    Data = <<GuildId:32, GuildNameLen:16, GuildNameBin/binary, Realm:8, Sex:8, MsgContentLen:16, 
			 MsgContentBin/binary, GM:8,Vip:8, Career:8, GuildPosition:8,
			 Color:32,ScenceId:32,X:16,Y:16,PositionContentBin/binary,FortuneId:16,Ringfashion:32>>,
    {ok, pt:pack(11005, Data)};

%%队伍聊天
write(11006, [Id, Nick, Realm, Sex, Bin, GM,Vip, Career,Ringfashion]) ->
    Nick1 = list_to_binary(Nick),
    Len = byte_size(Nick1),
%    Bin1 = list_to_binary(Bin),
    Bin1 = make_sure_binary(Bin),
    Len1 = byte_size(Bin1),
    Data = <<Id:32, Len:16, Nick1/binary, Realm:8, Sex:8, Len1:16, Bin1/binary, GM:8,Vip:8, Career:8,Ringfashion:32>>,
    {ok, pt:pack(11006, Data)};

%%私聊返回黑名单通知
%write(11007, Id) ->
%    {ok, pt:pack(11007, <<Id:32>>)};

%% 阵营聊天
write(11008, [Id, Nick, Realm, Sex, Bin, GM,Vip, Career,Ringfashion]) ->
    Nick1 = list_to_binary(Nick),
    Len = byte_size(Nick1),
%    Bin1 = list_to_binary(Bin),
    Bin1 = make_sure_binary(Bin),
    Len1 = byte_size(Bin1),
    Data = <<Id:32, Len:16, Nick1/binary, Realm:8, Sex:8, Len1:16, Bin1/binary, GM:8,Vip:8, Career:8,Ringfashion:32>>,
    {ok, pt:pack(11008, Data)};

%% 世界频道:请勿多次发送同样内容
write(11009, [])->
    Data = <<>>,
    {ok, pt:pack(11009, Data)};

%%聊天过于频繁通知
write(11010, Sid) ->
    {ok, pt:pack(11010, <<Sid:32>>)};
%%对方不在线通知
write(11011, Uid) ->
    {ok, pt:pack(11011, <<Uid:32>>)};

%%聊天输入状态
write(11012, [Id, InputState]) ->
    Data = <<Id:32, InputState:8>>,
    {ok, pt:pack(11012, Data)};

%%取私聊所需信息
write(11013, [OnlineFlag, Id, Name, Sex, Career, Vip, Image, Level, GuildName, Realm, GuildId, Ringfashion]) ->
	if
		GuildName=:=undefined -> 
			GuildName1 = pt:write_string("GuildName");
		true ->
			GuildName1 = pt:write_string(GuildName)
	end,
	Name1 = pt:write_string(Name),
	Data = <<OnlineFlag:8, Id:32, Name1/binary, Sex:8, Career:8, Vip:8, Image:8, Level:16, GuildName1/binary, Realm:8, GuildId:32, Ringfashion:32>>,
	{ok, pt:pack(11013, Data)};

%%传闻、电视
write(11014, [Type,Msg]) ->
	MsgBin = pt:write_string(Msg),
    {ok, pt:pack(11014, <<Type:8,MsgBin/binary>>)};

%%发送坐标
write(11016, [Id, Name, Realm, Sex, Gm, Vip, Career, Content, SceneId, X, Y, Channel, Content2, Ringfashion]) ->
	NameBin = pt:write_string(Name),
	ContentBin = pt:write_string(Content),
	ContentBin2 = pt:write_string(Content2),
	{ok, pt:pack(11016, <<Id:32, NameBin/binary, Realm:8, Sex:8, Gm:8,Vip:8, Career:8, ContentBin/binary, SceneId:16,X:16, Y:16, Channel:8, ContentBin2/binary, Ringfashion:32>>)};

write(11020, [Id, Name, Realm, Sex, Msg,Gm,Vip, Career,Image,Lv,Energy,MyLv,Channel,Ringfashion]) ->
	NameBin = pt:write_string(Name),
	MsgBin = pt:write_string(Msg),
    {ok, pt:pack(11020, <<Id:32, NameBin/binary, Realm:8, Sex:8, MsgBin/binary,Gm:8,Vip:8, Career:8,Image:8,Lv:16,Energy:32,MyLv:16, Channel:8, Ringfashion:32>>)};

%%发送小喇叭消息
write(11031, [Result,No,Type]) ->
	Data = <<Result:8,No:16,Type:8>>,
	{ok, pt:pack(11031, Data)};

%%向客户端广播喇叭消息
write(11032, [Id, 			%角色ID
			  Nickname,		%角色名
			  Realm,		%阵营
			  Sex,			%性别
			  Color,		%颜色
			  Content,		%内容
			  Gm,			%GM
			  Vip,			%VIP
			  Work,			%职业
			  Type,			%喇叭类型  1飞天号角 2冲天号角 3生日号角 4新婚号角
			  Image,        %头像
			  Ringfashion]  %戒指时装
	  ) ->
	NicknameBin = pt:write_string(Nickname),
	ContentBin = pt:write_string(Content),
	Data = <<Id:32, 			%角色ID
			  NicknameBin/binary,		%角色名
			  Realm:8,			%阵营
			  Sex:8,			%性别
			  Color:8,			%颜色
			  ContentBin/binary,		%内容
			  Gm:8,				%GM
			  Vip:8,			%VIP
			  Work:8,			%职业
			  Type:8,			%喇叭类型  1飞天号角 2冲天号角 3生日号角 4新婚号角
			  Image:8,
			  Ringfashion:32>>,
	{ok, pt:pack(11032, Data)};

%%小喇叭消息排队人数
write(11033, [Result,No]) ->
	Data = <<Result:8,No:16>>,
	{ok, pt:pack(11033, Data)};

write(11040, [Result]) ->
	Data = <<Result:8>>,
	{ok, pt:pack(11040, Data)};

write(11041, [Result]) ->
	Data = <<Result:8>>,
	{ok, pt:pack(11041, Data)};

%%发送被禁言通知
write(11042, Release_after) ->
    {ok, pt:pack(11042, <<Release_after:32>>)};

%%获取禁言信息
write(11043, Talk_lim) ->
    {ok, pt:pack(11043, <<Talk_lim:8>>)};

%% 聊天举报
write(11044, [Result]) ->
	Data = <<Result:8>>,
	{ok, pt:pack(11044, Data)};

write(11050, [List]) ->
    ListLen = length(List),
    F = fun(X) ->
		[Type, Color, Content, Url, Num, Span, Start, End, Status] = X,
		ColorBin = pt:write_string(Color),
		ContentBin = pt:write_string(Content),
		UrlBin = pt:write_string(Url),
		<<Type:8, ColorBin/binary, ContentBin/binary, UrlBin/binary, Num:32, Span:16, Start:32, End:32, Status:8>>
	end,
    Bin = list_to_binary(lists:map(F, List)),
    Data = <<ListLen:16, Bin/binary>>,
    {ok, pt:pack(11050, Data)};

%% 获得物品显示信息在右下角提示框内
write(11060, List) ->
	Len = length(List),
	Data = list_to_binary(List),
	Bin = <<Len:16, Data/binary>>,
	{ok, pt:pack(11060, Bin)};

%%[跨服]场景聊天
write(11062, [Id, Nick, Realm, Sex, Bin, GM,Vip,Career,Platform, ServerID, Ringfashion]) ->
    Nick1 = pt:write_string(Nick),
    Bin1 = make_sure_binary(Bin),
    Len1 = byte_size(Bin1),
	Platform1 = pt:write_string(Platform),	
    Data = <<Id:32, Nick1/binary, Realm:8, Sex:8, Len1:16, Bin1/binary, GM:8,Vip:8,Career:8, Platform1/binary,ServerID:16, Ringfashion:32>>,
    {ok, pt:pack(11062, Data)};

%%攻城战聊天
write(11070, [Id, Nick, Realm, Sex, Bin, GM, Vip, Career, Group, Ringfashion]) ->
    Nick1 = pt:write_string(Nick),
    %Len = byte_size(Nick1),
%    Bin1 = list_to_binary(Bin),
    Bin1 = make_sure_binary(Bin),
    Len1 = byte_size(Bin1),
    Data = <<Id:32, Nick1/binary, Realm:8, Sex:8, Len1:16, Bin1/binary, GM:8, Vip:8, Career:8, Group:8, Ringfashion:32>>,
    {ok, pt:pack(11070, Data)};

%% VIP免费号角剩余数量
write(11071, [RestNum]) ->
    {ok, pt:pack(11071, <<RestNum:8>>)};

%% 发送语音聊天
write(11080, [AutoId, PlayerId, Name, Realm, Sex, GM, Vip, Career, MsgType, ReceiveId, VoiceMsgTime, TkTime, Ticket]) -> 
    Name_b = pt:write_string(Name),
    Ticket_b = pt:write_string(Ticket),
    Data = <<AutoId:32, PlayerId:32, Name_b/binary, Realm:8, Sex:8, GM:8, Vip:8, 
             Career:8, MsgType:8, ReceiveId:32, VoiceMsgTime:16, TkTime:32, Ticket_b/binary>>,
    {ok, pt:pack(11080, Data)};

%% 获取语音内容
write(11081, [AutoId, VoiceBin, TkTime, Ticket]) -> 
    VoiceBin_b = pt:write_voice_bin(VoiceBin),
    Ticket_b   = pt:write_string(Ticket),
    Data = <<AutoId:32, VoiceBin_b/binary, TkTime:32, Ticket_b/binary>>,
    {ok, pt:pack(11081, Data)};

%% 发送图片信息
write(11082, [AutoId, PlayerId, Name, Realm, Sex, GM, Vip, Career, MsgType, ReceiveId, TinyPicture, TkTime, Ticket]) -> 
    Name_b        = pt:write_string(Name),
    Ticket_b      = pt:write_string(Ticket),
    TinyPicture_b = pt:write_voice_bin(TinyPicture),
    Data = <<AutoId:32, PlayerId:32, Name_b/binary, Realm:8, Sex:8, GM:8, Vip:8, 
             Career:8, MsgType:8, ReceiveId:32, TinyPicture_b/binary, TkTime:32, Ticket_b/binary>>,
    {ok, pt:pack(11082, Data)};

%% 获取图片信息
write(11083, [AutoId, RealPictureBin, TkTime, Ticket]) -> 
    RealPictureBin_b = pt:write_voice_bin(RealPictureBin),
    Ticket_b   = pt:write_string(Ticket),
    Data = <<AutoId:32, RealPictureBin_b/binary, TkTime:32, Ticket_b/binary>>,
    {ok, pt:pack(11083, Data)};

%% 上传语音文字内容
write(11085, Res) -> 
    {ok, pt:pack(11085, <<Res:8>>)};

%% 获取语音文字内容
write(11086, [Res, ClientAutoId, VoiceTextData]) -> 
    VoiceTextData_b = pt:write_string(VoiceTextData),
    Data = <<Res:8, ClientAutoId:32, VoiceTextData_b/binary>>,
    {ok, pt:pack(11086, Data)};

%% 获取图片信息
write(11084, Res) -> 
    Data = <<Res:8>>,
    {ok, pt:pack(11084, Data)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

make_sure_binary(Str) ->
    if
        is_binary(Str) -> Str;
        is_list(Str) -> list_to_binary(Str);
        true -> <<>>
    end.
