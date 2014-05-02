%% --------------------------------------------------------
%% @Module:           |pt_290
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-03-22
%% @Description:      |鲜花功能处理协议
%% --------------------------------------------------------
-module(pt_290).
-include("gift.hrl").
-export([read/2, write/2]).


%%======== 赠送鲜花 =========
read(29001, Info) ->
	<<Type:8, Num:16, Len1:16, TargetPlayerName:Len1/binary, FlowerType:8>> = Info,
    {ok, [Type, Num, TargetPlayerName, FlowerType]};

read(29003, Info) ->
	<<FlowerFromId:32, Num:16, Len1:16, FlowerFromName:Len1/binary>> = Info,
    {ok, [FlowerFromId, Num, FlowerFromName]};

read(29006, _) ->
    {ok, get_flower_record};

read(29007, <<GoodsTypeId:32, GoodsId:32>>) ->
    {ok, [GoodsTypeId, GoodsId]};

read(_, _) ->
    {error, no_match}.



write(29001,[Res, FlowerId, TargetPlayerName, MlptAdd, IntimacyAdd, ExpAdd])->
	Bin_TargetPlayerName = pt:write_string(TargetPlayerName),
	Info = <<Res:8, FlowerId:32, Bin_TargetPlayerName/binary, MlptAdd:16, IntimacyAdd:16, ExpAdd:32>>,
	{ok, pt:pack(29001, Info)};
%%======== 获赠鲜花 =========
write(29002,[Type, FlowerNum, FromId, FromName, FromLine, FromVoc, FromSex, MlptAdd, IntimacyAdd, ExpAdd, FlowerType])->
    Bin_FromName = pt:write_string(FromName),
	Info = <<Type:8, FlowerNum:16, FromId:32, Bin_FromName/binary, FromLine:8, FromVoc:8, FromSex:8, MlptAdd:16, IntimacyAdd:16, ExpAdd:32, FlowerType:8>>,
	{ok, pt:pack(29002, Info)};
%%========== 回吻 ===========
write(29003,[Res, BeKissedPlayName])->
	Bin_BeKissedPlayName = pt:write_string(BeKissedPlayName),
	Info = <<Res:8, Bin_BeKissedPlayName/binary>>,
	{ok,pt:pack(29003, Info)};
%%======== 获得回吻 =========
write(29004,[KissFromId, KissFromSex, GivedFlowerNum, KissFromName])->
	Bin_KissFromName = pt:write_string(KissFromName),
	Info = <<KissFromId:32, KissFromSex:8, GivedFlowerNum:16, Bin_KissFromName/binary>>,
	{ok,pt:pack(29004, Info)};
%%======== 全屏飘花 =========
write(29005,[RecvPlayerId,FlowerType])->
    Info = <<RecvPlayerId:32, FlowerType:8>>,
	{ok,pt:pack(29005, Info)};
%%====== 查询鲜花记录 =======
write(29006, ListFlower)->
	Datax = pack_flower_list(ListFlower),
    {ok, pt:pack(29006, Datax)};
%%====== 使用特效符 =======
write(29007, [Res, GoodsTypeId])->
	Info = <<Res:8, GoodsTypeId:32>>,
    {ok, pt:pack(29007, Info)};
%%====== 烟花特效广播 =======
write(29008, [RoleId, GoodsTypeId])->
	Info = <<RoleId:32, GoodsTypeId:32>>,
    {ok, pt:pack(29008, Info)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.


%% 打包鲜花记录
pack_flower_list([]) ->
    <<0:16, <<>>/binary>>;
pack_flower_list(ListFlower) ->
    Rlen = length(ListFlower),
    F = fun([FromId, FromName, ToId, ToName, _Time, Num, Type, HdShow, Sex, Voc]) ->
        FromName_Bin = pt:write_string(FromName),
		ToName_Bin = pt:write_string(ToName),
        <<FromId:32, FromName_Bin/binary, ToId:32, ToName_Bin/binary, _Time:32, Num:16, Type:8, HdShow:8, Sex:8, Voc:8>>
    end,
    RB = list_to_binary([F(D) || D <- ListFlower]),
    <<Rlen:16, RB/binary>>.
