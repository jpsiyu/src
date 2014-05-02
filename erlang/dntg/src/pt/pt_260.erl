%%%------------------------------------
%%% @Module     : pt_260
%%% @Author     : zhenghehe
%%% @Created    : 2010.12.21
%%% @Description: 验证码及二级密码
%%%------------------------------------
-module(pt_260).
-compile(export_all).
-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%

%% 获取验证码
read(26001, <<TypeNum:8>>) ->
    {ok, TypeNum};

%% 输入验证码
read(26002, <<TypeNum:8, Binary/binary>>) ->
    {Code, _Rest} = pt:read_string(Binary),
    {ok, [TypeNum, Code]};

%% 查询是否已经设置
read(26011, _) ->
    {ok, []};

%% 设置密保
read(26012, <<QId1:8, QId2:8, Bin1/binary>>) ->
    {Answer1, Bin2} = pt:read_string(Bin1),
    {Answer2, Bin3} = pt:read_string(Bin2),
    {Password, _} = pt:read_string(Bin3),
    {ok, [QId1, QId2, Answer1, Answer2, Password]};

%% 修改二级密码
read(26013, Bin1) ->
    {OldPassword, Bin2} = pt:read_string(Bin1),
    {NewPassword, _} = pt:read_string(Bin2),
    {ok, [OldPassword, NewPassword]};

%% 查询密保问题(删除前)
read(26014, <<Type:8>>) ->
    {ok, Type};

%% 删除二级密码
read(26015, Bin1) ->
    {Answer1, Bin2} = pt:read_string(Bin1),
    {Answer2, _} = pt:read_string(Bin2),
    {ok, [Answer1, Answer2]};

%% 验证二级密码
read(26016, Bin1) ->
    {Password, _} = pt:read_string(Bin1),
    {ok, Password};

%%查询删改剩余次数
read(26017, _) ->
    {ok, []};

read(_, _) ->
    {error, no_match}.

%%
%%服务端 -> 客户端 ------------------------------------
%%

%% 获取验证码图片
write(26001, [TypeNum, Result, RestTimes, ImageData]) ->
    Size = byte_size(ImageData),
    {ok, pt:pack(26001, <<TypeNum:8, Result:8, RestTimes:8, Size:16, ImageData/binary>>)};

%% 输入验证码
write(26002, [TypeNum, Result, RestTimes, ImageData]) ->
    Size = byte_size(ImageData),
    {ok, pt:pack(26002, <<TypeNum:8, Result:8, RestTimes:8, Size:16, ImageData/binary>>)};

%% 查询是否已经设置
write(26011, [Result, IsSetAnswer, IsSetPassword]) ->
    {ok, pt:pack(26011, <<Result:8, IsSetAnswer:8, IsSetPassword:8>>)};

%% 设置密保
write(26012, Result) ->
    {ok, pt:pack(26012, <<Result:8>>)};

%% 修改二级密码
write(26013, [Result, RestTimes]) ->
    {ok, pt:pack(26013, <<Result:8, RestTimes:8>>)};

%% 查询密保问题(删除前)
write(26014, [Result, QId1, QId2, RestDeleteTimes]) ->
    {ok, pt:pack(26014, <<Result:8, QId1:8, QId2:8, RestDeleteTimes:8>>)};

%% 删除二级密码
write(26015, [Result, RestTimes]) ->
    {ok, pt:pack(26015, <<Result:8, RestTimes:8>>)};

%% 验证二级密码
write(26016, Result) ->
    {ok, pt:pack(26016, <<Result:8>>)};

%% 查询删改剩余次数
write(26017, RestTimes) ->
    {ok, pt:pack(26017, <<RestTimes:8>>)};

write(_, _) ->
    {ok, pt:pack(0, <<>>)}.
