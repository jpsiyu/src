%%%------------------------------------
%%% @Module  : mod_chat_voice
%%% @Author  : xyao
%%% @Created : 2014.2.25
%%% @Description: 语音聊天管理
%%%------------------------------------
-module(mod_chat_voice).
-behaviour(gen_server).
-compile(export_all).
%-export([start_link/0, send_voice/2, get_voice_data/4]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("unite.hrl").
-record(state, {voice_dict = dict:new(), picture_dict = dict:new()}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 发送语音聊天
send_voice(PlayerId, ClientAutoId, DataSend) ->
    gen_server:cast(?MODULE, {'voice_data', PlayerId, ClientAutoId, DataSend}).

%% 获取语音内容
get_voice_data(PlayerId, ClientAutoId, Sid, TkTime, Ticket) -> 
     gen_server:cast(?MODULE, {'get_voice_data', PlayerId, ClientAutoId, Sid, TkTime, Ticket}).

%% 发送语音聊天
send_picture(AutoId, DataSend) ->
    gen_server:cast(?MODULE, {'picture_data', AutoId, DataSend}).

%% 获取语音内容
get_picture_data(AutoId, Sid, TkTime, Ticket) -> 
     gen_server:cast(?MODULE, {'get_picture_data', AutoId, Sid, TkTime, Ticket}).

 %% 发送语音文字聊天
send_voice_text(PlayerId, ClientAutoId, Sid, DataTextSend) ->
    gen_server:cast(?MODULE, {'voice_text_data', PlayerId, ClientAutoId, Sid, DataTextSend}).

%% 获取语音文字内容
get_voice_text_data(PlayerId, ClientAutoId, Sid) -> 
     gen_server:cast(?MODULE, {'get_voice_text_data', PlayerId, ClientAutoId, Sid}).

init([]) ->
    process_flag(trap_exit, true),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

%% 语音聊天(采用dict存储每个玩家的语音信息，语音信息放在list中，采用先进先出原理，
%% list效率比较低，不能让list太长，目前是定义的是100长度)
handle_cast({'voice_data', PlayerId, ClientAutoId, DataSend}, #state{voice_dict=VoiceDict} = State) -> 
    case dict:find(PlayerId, VoiceDict) of
        error -> 
            VoiceList = [{ClientAutoId, DataSend, []}],
            put(voice_list_len, 1),
            NewVoiceDict = dict:store(PlayerId, VoiceList, VoiceDict);
        {ok, OldVoiceList} -> 
            VoiceListLen = case get(voice_list_len) of
                undefined -> length(OldVoiceList);
                Len -> Len
            end,
            case VoiceListLen >= 99 of
                true -> 
                    [_Tail|H] = lists:reverse(OldVoiceList),
                    NewVoiceList = [{ClientAutoId, DataSend, []} | lists:reverse(H)],
                    NewVoiceDict = dict:store(PlayerId, NewVoiceList, VoiceDict);
                false -> 
                    put(voice_list_len, VoiceListLen+1),
                    NewVoiceList = [{ClientAutoId, DataSend, []} | OldVoiceList],
                    NewVoiceDict = dict:store(PlayerId, NewVoiceList, VoiceDict)
            end
    end,
    {noreply, State#state{voice_dict=NewVoiceDict}};

%% 获取语音内容
handle_cast({'get_voice_data', PlayerId, ClientAutoId, Sid, TkTime, Ticket}, #state{voice_dict=VoiceDict} = State) -> 
    case dict:find(PlayerId, VoiceDict) of
        error -> skip;
        {ok, OldVoiceList} -> 
            case lists:keyfind(ClientAutoId, 1, OldVoiceList) of
                false -> skip;
                {_, VoiceBinData, _} -> 
                    {ok, BinData} = pt_110:write(11081, [ClientAutoId, VoiceBinData, TkTime, Ticket]),
                    lib_unite_send:send_to_sid(Sid, BinData)
            end
    end,
    {noreply, State};

%% 存放图片数据
handle_cast({'picture_data', AutoId, DataSend}, #state{picture_dict=PictureDict} = State) -> 
    NewPictureDict = dict:store(AutoId, DataSend, PictureDict),
    {noreply, State#state{picture_dict=NewPictureDict}};

%% 获取图片内容
handle_cast({'get_picture_data', AutoId, Sid, TkTime, Ticket}, #state{picture_dict=PictureDict} = State) -> 
    case dict:find(AutoId, PictureDict) of
        error -> skip;
        {ok, PictrueBinData} -> 
            {ok, BinData} = pt_110:write(11083, [AutoId, PictrueBinData, TkTime, Ticket]),
            lib_unite_send:send_to_sid(Sid, BinData)
    end,
    {noreply, State};

%% 存储语音文字信息
handle_cast({'voice_text_data', PlayerId, ClientAutoId, Sid, VoiceText}, #state{voice_dict=VoiceDict} = State) -> 
    case dict:find(PlayerId, VoiceDict) of
        error -> 
            NewVoiceDict = VoiceDict,
            Res = 2; % 没有找到该玩家的语音文字信息
        {ok, OldVoiceList} -> 
            case lists:keyfind(ClientAutoId, 1, OldVoiceList) of
                false -> 
                    NewVoiceDict = VoiceDict,
                    Res = 2; % 没有找到该玩家的语音文字信息
                {_, VoiceBinData, _} -> 
                    NewVoiceList = lists:keyreplace(ClientAutoId, 1, OldVoiceList, {ClientAutoId, VoiceBinData, VoiceText}),
                    NewVoiceDict = dict:store(PlayerId, NewVoiceList, VoiceDict),
                    Res = 1 % 成功写入该玩家的语音文字信息
            end
    end,
    {ok, BinData} = pt_110:write(11085, Res),
    lib_unite_send:send_to_sid(Sid, BinData),
    {noreply, State#state{voice_dict=NewVoiceDict}};

%% 获取语音文字内容
handle_cast({'get_voice_text_data', PlayerId, ClientAutoId, Sid}, #state{voice_dict=VoiceDict} = State) -> 
    case dict:find(PlayerId, VoiceDict) of
        error -> skip;
        {ok, OldVoiceList} -> 
            case lists:keyfind(ClientAutoId, 1, OldVoiceList) of
                false -> skip;
                {_, _VoiceBinData, VoiceTextData} -> 
                    Res = case VoiceTextData of
                        [] -> 0; % 没有文字信息
                        _  -> 1  % 有文字信息
                    end,
                    {ok, BinData} = pt_110:write(11086, [Res, ClientAutoId, VoiceTextData]),
                    lib_unite_send:send_to_sid(Sid, BinData)
            end
    end,
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
