%%%-----------------------------------
%%% @Module  : lib_unite_send
%%% @Author  : zhenghehe
%%% @Created : 2012.02.01
%%% @Description: 
%%%-----------------------------------
-module(lib_unite_send).
-compile(export_all).
-include("common.hrl").
-include("unite.hrl").

%%发送信息给指定socket玩家.
%%Pid:游戏逻辑ID
%%Bin:二进制数据.
send_one(S, Bin) ->
    gen_tcp:send(S, Bin).

%%发送给某个id(只用于聊天服务器)
send_to_uid(Id, Bin) ->
    case mod_chat_agent:lookup(Id) of
        [] -> ok;
        [Player] -> 
            send_to_sid(Player#ets_unite.sid, Bin)
    end.

%% 跨服调用send_to_uid
cluster_to_uid(Id, Bin) ->
    mod_disperse:cast_to_unite(lib_unite_send, send_to_uid, [Id, Bin]).

%% 跨服调用send_to_uid
cluster_to_all(Bin) ->
    mod_disperse:cast_to_unite(lib_unite_send, send_to_all, [Bin]).

%%世界
send_to_all(Bin) ->
    L = mod_chat_agent:get_sid(all, 0),
    do_broadcast(L, Bin).

%%带休眠功能的群发器
%% @param SleepTime 睡眠时间(毫秒)
send_to_all(SleepTime,Bin) ->
    L = mod_chat_agent:get_sid(all, 0),
    do_broadcast(SleepTime,L, Bin, 1).

%% 按等级广播
send_to_all(MinLv, MaxLv, Bin) ->
    L = mod_chat_agent:get_sid(all, [MinLv, MaxLv]),
    do_broadcast(L, Bin).

%% 按等级广播
send_to_all(SleepTime,MinLv, MaxLv, Bin) ->
    F_L = mod_chat_agent:get_sid(all, [MinLv, MaxLv]),
    do_broadcast(SleepTime,F_L, Bin,1).

%指定玩家
send_to_one(Id, Bin) ->
    case mod_chat_agent:lookup(Id) of
        [] -> skip;
        [Player] ->
            send_to_sid(Player#ets_unite.sid, Bin)
    end.

% 给场景玩家发消息
send_to_scene(Q, Bin) ->
    send_to_scene(Q, 0, Bin).
send_to_scene(Q, CopyId, Bin) ->
    L = mod_chat_agent:get_sid(scene, [Q, CopyId]),
    do_broadcast(L, Bin).

%%帮派
send_to_guild(G, Bin) ->
    case G =/= 0 of
        true -> 
            L = mod_chat_agent:get_sid(guild, G),
            do_broadcast(L, Bin);
        false ->
            skip
    end.

%%阵营
send_to_realm(R, Bin) ->
    case R =/= 0 of
        true -> 
            L = mod_chat_agent:get_sid(realm, R),
            do_broadcast(L, Bin);
        false ->
            skip
    end.

%%队伍
send_to_team(T, Bin) ->
    case T =/= 0 of
        true -> 
            L = mod_chat_agent:get_sid(team, T),
            do_broadcast(L, Bin);
        false ->
            skip
    end.

%% 分组聊天
send_to_group(Group, Bin) ->
    L = mod_chat_agent:get_sid(group, Group),
    do_broadcast(L, Bin).

%% 对列表中的所有socket进行广播
do_broadcast(L, Bin) ->
    lists:foreach(fun(S) -> send_to_sid(S, Bin) end, L).

%% 对列表中的所有socket进行广播
%% @param SleepTime 睡眠时间 (毫秒)
%% @param L 发送目标SId的列表
%% @param Bin 包文件
%% @param Pos 调用时，直接赋值1即可
do_broadcast(SleepTime,L, Bin,Pos) ->
	case L of
		[]->void;
		[H|T]->
			if
				Pos rem 100 =:=0->
					timer:sleep(SleepTime);
				true->void
			end,
			send_to_sid(H, Bin),
			do_broadcast(SleepTime,T, Bin,Pos+1)
	end.

%%发送信息给指定sid玩家.
send_to_sid(S, Bin) ->
    %rand_to_process(S) ! {send, Bin}.
    S ! {send, Bin}.

%rand_to_process(S) ->
%    %Rand = util:rand(1, 1000) rem ?SEND_MSG + 1,
%    TT = case get("lib_unite_send_rand") of
%        undefined->
%            0;
%        _TT ->
%            case  _TT > 1000000 of
%                true ->
%                    0;
%                false ->
%                    _TT
%            end
%    end,
%    put("lib_unite_send_rand", TT+1),
%    Rand = TT rem ?UNITE_SEND_MSG + 1,
%    element(Rand, S).

%% 广播公共線
send_to_unite_all(Bin) ->
    L = mod_chat_agent:get_sid(all, 0),
    do_broadcast(L, Bin).

%%发聊天系统信息
send_sys_msg(Sid, Msg) ->
    {ok, BinData} = pt_110:write(11004, Msg),
    send_to_sid(Sid, BinData).

%%发送系统信息给某个玩家
send_sys_msg_one(Sid, Msg) ->
    {ok, BinData} = pt_110:write(11004, Msg),
    send_to_sid(Sid, BinData).

send_to_unite_guild(G, Bin) ->
    if (G > 0) ->
            L = mod_chat_agent:get_sid(guild, G),
            [ send_to_sid(S, Bin) || S <- L ];
        true ->
            void
    end.
