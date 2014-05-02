%%%------------------------------------------------
%%% @Module  : pt_271
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.24
%%% @Description: 结婚
%%%------------------------------------

-module(pt_271).
-export([read/2, write/2]).

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(27100, <<Bin/binary>>) ->
    {Content, _Bin1} = pt:read_string(Bin),
    {ok, [Content]};

read(27101, _) ->
    {ok, no};

read(27102, _) ->
    {ok, no};

read(27103, _) ->
    {ok, no};

read(27104, _) ->
    {ok, no};

read(27105, _) ->
    {ok, no};

read(27106, _) ->
    {ok, no};

read(27107, _) ->
    {ok, no};

read(27108, _) ->
    {ok, no};

read(27109, _) ->
    {ok, no};

read(27110, _) ->
    {ok, no};

read(27112, _) ->
    {ok, no};

read(27115, <<Type:8, Hour:8>>) ->
    {ok, [Type, Hour]};

read(27117, _) ->
    {ok, no};

read(27118, _) ->
    {ok, no};

read(27119, <<Type:8>>) ->
    {ok, [Type]};

read(27120, <<Type:8, Num:16>>) ->
    {ok, [Type, Num]};

read(27122, <<Bin/binary>>) ->
    {Content, _Bin1} = pt:read_string(Bin),
    {ok, [Content]};

read(27123, _) ->
    {ok, no};

read(27124, _) ->
    {ok, no};

read(27130, _) ->
    {ok, no};

read(27131, <<Level:8, Hour:8>>) ->
    {ok, [Level, Hour]};

read(27132, <<Bin/binary>>) ->
    {Content, Bin1} = pt:read_string(Bin),
    <<Num:16, Bin2/binary>> = Bin1,
    List = read_id_list(Bin2, [], Num),
    {ok, [Content, List]};

read(27133, _) ->
    {ok, no};

read(27135, _) ->
    {ok, no};

read(27136, _) ->
    {ok, no};

read(27137, <<WeddingId:32>>) ->
    {ok, [WeddingId]};

read(27138, <<WeddingId:32>>) ->
    {ok, [WeddingId]};

read(27139, _) ->
    {ok, no};

read(27140, _) ->
    {ok, no};

read(27141, _) ->
    {ok, no};

read(27142, <<ActionId:8>>) ->
    {ok, [ActionId]};

read(27143, <<WeddingId:32>>) ->
    {ok, [WeddingId]};

read(27144, <<WeddingId:32, Type:8, To:8>>) ->
    {ok, [WeddingId, Type, To]};

read(27145, _) ->
    {ok, no};

read(27148, _) ->
    {ok, no};

read(27149, <<Num:32>>) ->
    {ok, [Num]};

read(27151, <<Num:16>>) ->
    {ok, [Num]};

read(27152, <<WeddingId:32>>) ->
    {ok, [WeddingId]};

read(27154, <<Type:8>>) ->
    {ok, [Type]};

read(27155, _R) ->
    {ok, []};

read(27156, _R) ->
    {ok, []};

read(27157, <<Type:8>>) ->
    {ok, [Type]};

read(27170, _R) ->
    {ok, []};

read(27171, <<Ans:8>>) ->
    {ok, [Ans]};

read(27172, _R) ->
    {ok, []};

read(27173, _R) ->
    {ok, []};

read(27174, _R) ->
    {ok, []};

read(27175, _R) ->
    {ok, []};

read(27180, _R) ->
    {ok, []};

read(27181, <<TaskId:8>>) ->
    {ok, [TaskId]};

read(27191, <<WeddingType:8, Hour:8>>) ->
    {ok, [WeddingType, Hour]};

read(27192, <<CruiseType:8, Hour:8>>) ->
    {ok, [CruiseType, Hour]};

read(_Cmd, _R) ->
    {error, no_match}.


%%%=========================================================================
%%% 组包函数
%%%=========================================================================

%%% 男方求婚
write(27100, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27100, Data)};

%%% 申请结婚(998做情缘任务，3000做情比金坚任务，6000可以直接登记)
write(27101, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27101, Data)};

%%% 查看结婚进度
write(27102, [Res, AppNow, AppNeed, TaskFlag]) ->
    Data = <<Res:8, AppNow:16, AppNeed:16, TaskFlag:8>>,
    {ok, pt:pack(27102, Data)};

%%% 接任务
write(27103, [Res, Task]) ->
    Data = <<Res:8, Task:8>>,
    {ok, pt:pack(27103, Data)};

%%% 交任务
write(27104, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27104, Data)};

%%% 获得情比金坚任务NPC坐标
write(27105, Bin) ->
    Data = Bin,
    {ok, pt:pack(27105, Data)};

%%% 领取情比金坚任务定情信物
write(27106, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27106, Data)};

%%% 上交情比金坚任务定情信物
write(27107, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27107, Data)};

%%% 情比金坚任务状态
write(27108, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27108, Data)};

%%% 任务
write(27109, [Res, Rela]) ->
    Data = <<Res:8, Rela:32>>,
    {ok, pt:pack(27109, Data)};

%%% 放弃任务
write(27110, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27110, Data)};

%%% 通知女方男方求婚
write(27111, [Name, Content]) ->
    NameStr = pt:write_string(Name),
    ContentStr = pt:write_string(Content),
    Data = <<NameStr/binary, ContentStr/binary>>,
    {ok, pt:pack(27111, Data)};

%%% 女方回应求婚
write(27112, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27112, Data)};

%%% 巡游预约(预约巡游等级和时间)
write(27115, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27115, Data)};

%%% (公共线)巡游倒计时(服务器主动发，并每分钟发一次)
write(27116, [Id, CountdownTime1, MaleId, FemaleId, MaleName, FemaleName, MaleCareer, FemaleCareer, MaleSex, FemaleSex, MaleImage, FemaleImage, Scale, Num1, Num2]) ->
    MaleName1 = MaleName,
    FemaleName1 = FemaleName,
    Len1 = byte_size(MaleName1),
    Len2 = byte_size(FemaleName1),
    Data = <<Id:32, CountdownTime1:32, MaleId:32, Len1:16, MaleName1/binary, MaleCareer:8, MaleSex:8, MaleImage:32, FemaleId:32, Len2:16, FemaleName1/binary, FemaleCareer:8, FemaleSex:8, FemaleImage:32, Scale:8, Num1:32, Num2:32>>,
    {ok, pt:pack(27116, Data)};

%%% (公共线)巡游开始(服务器主动发，并每分钟发一次)
write(27117, [Id, CountdownTime1, MaleId, FemaleId, MaleName, FemaleName, MaleCareer, FemaleCareer, MaleSex, FemaleSex, MaleImage, FemaleImage, Scale, Num1, Num2]) ->
    %io:format("time:~p, CountdownTime1:~p~n", [time(), CountdownTime1]),
    MaleName1 = MaleName,
    FemaleName1 = FemaleName,
    Len1 = byte_size(MaleName1),
    Len2 = byte_size(FemaleName1),
    Data = <<Id:32, CountdownTime1:32, MaleId:32, Len1:16, MaleName1/binary, MaleCareer:8, MaleSex:8, MaleImage:32, FemaleId:32, Len2:16, FemaleName1/binary, FemaleCareer:8, FemaleSex:8, FemaleImage:32, Scale:8, Num1:32, Num2:32>>,
    {ok, pt:pack(27117, Data)};

%%% 开始巡游
write(27118, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27118, Data)};

%%% 剩余数量
write(27119, [Type, Num]) ->
    Data = <<Type:8, Num:16>>,
    {ok, pt:pack(27119, Data)};

%%% 购买
write(27120, [Res, Type, TotalNum]) ->
    Data = <<Res:8, Type:8, TotalNum:16>>,
    {ok, pt:pack(27120, Data)};

%%% 婚宴气氛(公共线)
write(27121, [Num, Name, Type]) ->
    NameStr = pt:write_string(Name),
    Data = <<Num:16, NameStr/binary, Type:8>>,
    {ok, pt:pack(27121, Data)};

%%% 爱情宣言
write(27122, [Res, Num]) ->
    Data = <<Res:8, Num:16>>,
    {ok, pt:pack(27122, Data)};

%%% 发送喜糖
write(27123, [Res, Num]) ->
    Data = <<Res:8, Num:16>>,
    {ok, pt:pack(27123, Data)};

%%% 传送到婚车
write(27124, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27124, Data)};

%%% 拜堂预约(获得服务器当前时间)
write(27130, [Time]) ->
    Data = <<Time:32>>,
    {ok, pt:pack(27130, Data)};

%%% 拜堂预约(预约婚礼等级和时间)
write(27131, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27131, Data)};

%%% 编辑喜帖并发送
write(27132, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27132, Data)};

%%% 可邀请宾客人数
write(27133, Bin) ->
    Data = Bin,
    {ok, pt:pack(27133, Data)};

%%% 发送喜帖
write(27134, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27134, Data)};

%%% (公共线)婚礼倒计时(服务器主动发，并每分钟发一次)
write(27135, [Id, CountdownTime1, MaleId, FemaleId, MaleName, FemaleName, MaleCareer, FemaleCareer, MaleSex, FemaleSex, MaleImage, FemaleImage, Scale, Num1, Num2]) ->
    MaleName1 = MaleName,
    FemaleName1 = FemaleName,
    Len1 = byte_size(MaleName1),
    Len2 = byte_size(FemaleName1),
    Data = <<Id:32, CountdownTime1:32, MaleId:32, Len1:16, MaleName1/binary, MaleCareer:8, MaleSex:8, MaleImage:32, FemaleId:32, Len2:16, FemaleName1/binary, FemaleCareer:8, FemaleSex:8, FemaleImage:32, Scale:8, Num1:32, Num2:32>>,
    {ok, pt:pack(27135, Data)};

%%% (公共线)婚礼开始(服务器主动发，并每分钟发一次)
write(27136, [Id, CountdownTime1, MaleId, FemaleId, MaleName, FemaleName, MaleCareer, FemaleCareer, MaleSex, FemaleSex, MaleImage, FemaleImage, Scale, Num1, Num2]) ->
    MaleName1 = MaleName,
    FemaleName1 = FemaleName,
    Len1 = byte_size(MaleName1),
    Len2 = byte_size(FemaleName1),
    Data = <<Id:32, CountdownTime1:32, MaleId:32, Len1:16, MaleName1/binary, MaleCareer:8, MaleSex:8, MaleImage:32, FemaleId:32, Len2:16, FemaleName1/binary, FemaleCareer:8, FemaleSex:8, FemaleImage:32, Scale:8, Num1:32, Num2:32>>,
    {ok, pt:pack(27136, Data)};

%%% 进入婚礼场景
write(27137, Bin) ->
    Data = Bin,
    {ok, pt:pack(27137, Data)};

%%% (公共线)婚宴状态
write(27138, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27138, Data)};

%%% 迎接新娘
write(27139, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27139, Data)};

%%% 跳完火盆，交任务
write(27140, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27140, Data)};

%%% 开始拜堂
write(27141, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27141, Data)};

%%% (公共线)亲密无双
write(27142, [Res, PlayerId]) ->
    Data = <<Res:8, PlayerId:32>>,
    {ok, pt:pack(27142, Data)};

%%% 领取祝福
write(27143, [MaleCoin, MaleGold, FemaleCoin, FemaleGold, SendName, SendCoin, SendGold, SendTo]) ->
    SendName1 = list_to_binary(SendName),
    LenSendName = byte_size(SendName1),
    Data = <<MaleCoin:32, MaleGold:32, FemaleCoin:32, FemaleGold:32, LenSendName:16, SendName1/binary, SendCoin:32, SendGold:32, SendTo:8>>,
    {ok, pt:pack(27143, Data)};

%%% (公共线)赠送贺礼
write(27144, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27144, Data)};

%%% (公共线)偷吻新娘
write(27145, [Res, PlayerId]) ->
    Data = <<Res:8, PlayerId:32>>,
    {ok, pt:pack(27145, Data)};

%%% (公共线)放烟花
write(27147, [PlayerId, X, Y, Type]) ->
    Data = <<PlayerId:32, X:16, Y:16, Type:8>>,
    {ok, pt:pack(27147, Data)};

%%% 退出场景
write(27148, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27148, Data)};

%%% 购买喜帖
write(27149, [Res, Num]) ->
    Data = <<Res:8, Num:32>>,
    {ok, pt:pack(27149, Data)};

%%% 婚宴气氛
write(27150, [Value, Name]) ->
    NameBinary = pt:write_string(Name),
    Data = <<Value:16, NameBinary/binary>>,
    {ok, pt:pack(27150, Data)};

%%% 姻缘日志
write(27151, Bin) ->
    Data = Bin,
    {ok, pt:pack(27151, Data)};

%%% 索要喜帖
write(27152, [Res]) ->
    Data = <<Res:8>>,
    {ok, pt:pack(27152, Data)};

%%% 索要喜帖
write(27153, [Id, Name, Career, Sex, Image, Realm, RestNum]) ->
    NameStr = pt:write_string(Name),
    Data = <<Id:32, NameStr/binary, Career:8, Sex:8, Image:32, Realm:8, RestNum:16>>,
    {ok, pt:pack(27153, Data)};

%%% 喜糖
write(27154, [Type, Res, Num]) ->
    Data = <<Type:8, Res:8, Num:16>>,
    {ok, pt:pack(27154, Data)};

%%% 闹洞房
write(27155, Res) ->
    {ok, pt:pack(27155, <<Res:8>>)};

%% 已被预约的喜宴或巡游时段
write(27157, [List, Time, Type]) ->
    Data = pack_list2(List, Time, Type),
    {ok, pt:pack(27157, Data)};

%%% 预约协议离婚
write(27170, [Res, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(27170, <<Res:8, Str1/binary>>)};

%%% 确认协议离婚
write(27171, [Res, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(27171, <<Res:8, Str1/binary>>)};

%%% 强制离婚
write(27172, [Res, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(27172, <<Res:8, Str1/binary>>)};

%%% 强制离婚状态
write(27173, [Res]) ->
    {ok, pt:pack(27173, <<Res:8>>)};

%%% 单人离婚
write(27174, [Res, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(27174, <<Res:8, Str1/binary>>)};

%%% 取消强制离婚
write(27175, [Res, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(27175, <<Res:8, Str1/binary>>)};

%% 获得结婚纪念日信息
write(27180, [Res, Str, Array, Total, Now]) ->
    Data = pack_list(Res, Str, Array, Total, Now),
    {ok, pt:pack(27180, Data)};

%% 领取奖励
write(27181, [Res, Str]) ->
    Str1 = pt:write_string(Str),
    {ok, pt:pack(27181, <<Res:8, Str1/binary>>)};

%%% 使用道具 使用提示
write(27190, [Type, Type2, Hour]) ->
    {ok, pt:pack(27190, <<Type:8, Type2:8, Hour:8>>)};

%%% 使用道具 拜堂预约(预约婚礼等级和时间)
write(27191, [Res]) ->
    {ok, pt:pack(27191, <<Res:8>>)};

%%% 使用道具 巡游预约(预约巡游等级和时间)
write(27192, [Res]) ->
    {ok, pt:pack(27192, <<Res:8>>)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.

read_id_list(<<Id:32, Rest/binary>>, List, ListNum) when ListNum > 0 ->
    NewList = [{Id} | List],
    read_id_list(Rest, NewList, ListNum - 1);
read_id_list(_, List, _) -> List.

pack_list(Res, Str, Array, Total, Now) ->
	%% List1
    Fun1 = fun(Elem1) ->
            {TaskId, TotalNum, NowNum, AwardId, NameStr, ContentStr, AwardNum, CanGet} = Elem1,
            NameStr1 = pt:write_string(NameStr),
            ContentStr1 = pt:write_string(ContentStr),
            <<TaskId:8, TotalNum:16, NowNum:16, AwardId:32, NameStr1/binary, ContentStr1/binary, AwardNum:16, CanGet:8>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- Array]),
    Size1  = length(Array),
    Str1 = pt:write_string(Str),
    <<Res:8, Str1/binary, Total:16, Now:16, Size1:16, BinList1/binary>>.

pack_list2(List, Time, Type) ->
	%% List1
    Fun1 = fun(Elem1) ->
            {Hour, State} = Elem1,
            <<Hour:8, State:8>>
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- List]),
    Size1  = length(List),
    <<Size1:16, BinList1/binary, Time:32, Type:8>>.
