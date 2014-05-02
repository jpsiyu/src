%%%-----------------------------------
%%% @Module  : pt
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.06.30
%%% @Description: 协议公共函数
%%%-----------------------------------
-module(pt).
-export([
            read_string/1,
            write_string/1,
            read_voice_bin/1,
            write_voice_bin/1,
            pack/2,
            pack/3,
            read_id_num_list/3,
            read_id_list/3,
			get_time_stamp/0
        ]).

%%读取{ID，数量}列表 -> {Rest, IdNumList}
read_id_num_list(<<Id:32, Num:16, Rest/binary>>, List, ListNum) when ListNum > 0 ->
    NewList = case lists:keyfind(Id, 1, List) of
                {_,N} -> lists:keyreplace(Id, 1, List, {Id,(N + Num)});
                false -> [{Id,Num}|List]
            end,
    read_id_num_list(Rest, NewList, ListNum-1);
read_id_num_list(Rest, List, _) ->
    {Rest, List}.

%%读取Id列表 -> {Rest, IdList}
read_id_list(<<Id:32, Rest/binary>>, L, Num) when Num > 0 ->
    NewL = case lists:member(Id, L) of
               false -> [Id|L];
               true -> L
           end,
    read_id_list(Rest, NewL, Num-1);
read_id_list(Rest, L, _) -> {Rest, L}.

%%读取字符串
read_string(Bin) ->
    case Bin of
        <<Len:16, Bin1/binary>> ->
            case Bin1 of
                <<Str:Len/binary-unit:8, Rest/binary>> ->
                    {binary_to_list(Str), Rest};
                _R1 ->
                    {[],<<>>}
            end;
        _R1 ->
            {[],<<>>}
    end.

%% 读取语音信息
read_voice_bin(Bin) -> 
    case Bin of
        <<Len:32, Bin1/binary>> ->
            case Bin1 of
                <<VoiceBin:Len/binary, Rest/binary>> ->
                    {VoiceBin, Rest};
                _R1 ->
                    {[],<<>>}
            end;
        _R1 ->
            {[],<<>>}
    end.

%%打包字符串
write_string(S) when is_list(S)->
    SB = iolist_to_binary(S),
    L = byte_size(SB),
    <<L:16, SB/binary>>;

write_string(S) when is_binary(S)->
    L = byte_size(S),
    <<L:16, S/binary>>;

write_string(S) when is_integer(S)->
	SS = integer_to_list(S),
	SB = list_to_binary(SS),
    L = byte_size(SB),
    <<L:16, SB/binary>>;

write_string(_S) ->
	%util:errlog("pt:write_string error, Error = ~p~n", [S]),
	<<0:16, <<>>/binary>>.

%% 打包语音二进制
write_voice_bin(VoiceBin) when is_binary(VoiceBin) -> 
    Len = byte_size(VoiceBin),
    <<Len:32, VoiceBin/binary>>.

%% 打包信息，添加消息头
%% Zip:1压缩0不压缩 默认不压缩, 当数据大于100个字节的时候，默认压缩
pack(Cmd, Data) ->
    pack(Cmd, Data, 0).
pack(Cmd, Data, Zip) ->
    case Zip == 1 orelse byte_size(Data) > 100 of
        true ->
            Data1 = zlib:compress(Data),
            L = byte_size(Data1) + 7,
            <<L:32, Cmd:16, 1:8, Data1/binary>>;
        false ->
            L = byte_size(Data) + 7,
            <<L:32, Cmd:16, 0:8, Data/binary>>
    end.

%% 获得当前的时间戳
get_time_stamp() ->
	{M, S, _} = erlang:now(),
	TS = M * 1000000 + S,
	TS.
