%%%-----------------------------------
%%% @Module  : lib_unite
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.07.22
%%% @Description: 公共线
%%%-----------------------------------
-module(lib_unite).
-include("common.hrl").
-include("server.hrl").
-include("unite.hrl").
-export([send_sys_msg/2, 
         send_sys_msg_one/2,
         refresh_client/2,
         apply_cast/4,
         apply_call/4,
         update_lv/2,
         update_player_info/2,
         update_player_info_unite/2,
         trans_to_unite/1
     ]).
%%发聊天系统信息
send_sys_msg(Socket, Msgid) ->
    {ok, BinData} = pt_110:write(11004, Msgid),
    lib_uinte_send:send_to_scene(Socket, BinData).

%%发送系统信息给某个玩家
send_sys_msg_one(Socket, Msgid) ->
    {ok, BinData} = pt_110:write(11004, Msgid),
    lib_uinte_send:send_one(Socket, BinData).

%% 通知客户端刷新信息
%%  What :  1 => 更新人物信息 2 => 更新背包 3 => 更新技能 4 => 更新任务 5 => 更新装备耐久
refresh_client(What, Sid) ->
    {ok, BinData} = pt_130:write(13005, What),
    lib_unite_send:send_to_sid(Sid, BinData).

%% 通过cast调用玩家所在游戏线的方法
%% Id:玩家id
%% Moudle:模块
%% Method:方法
%% Args:参数
apply_cast(Id, Moudle, Method, Args) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'apply_cast', Moudle, Method, Args});
        _ ->
            false
    end.

%% 通过call调用玩家所在游戏线的方法
%% Id:玩家id
%% Moudle:模块
%% Method:方法
%% Args:参数
apply_call(Id, Moudle, Method, Args) ->
    case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:call(Pid, {'apply_call', Moudle, Method, Args});
        _ ->
            false
    end.

%% 更新等级信息（公共线）
update_lv(RoleId, NewLevel) ->
    mod_chat_agent:update_lv(RoleId, NewLevel).

%% 更新用户信息(逻辑线)
update_player_info(Id, UniteStatus) when is_record(UniteStatus, unite_status) ->
    mod_disperse:rpc_cast_by_id(?UNITE, lib_unite, update_player_info_unite, [Id, UniteStatus]).

update_player_info_unite(Id, UniteStatus) when is_record(UniteStatus, unite_status) ->
    case mod_chat_agent:lookup(Id) of
        [] ->
            skip;
        [R] ->
            Pid = R#ets_unite.pid,
            gen_server:cast(Pid, {'base_set_data', UniteStatus}),
            mod_login:save_online(UniteStatus)
    end.

%% 把ps的数据过滤到unite去 
trans_to_unite(PlayerStatus) ->
    #player_status_unite{
        id = PlayerStatus#player_status.id,
        platform = PlayerStatus#player_status.platform,
        server_num = PlayerStatus#player_status.server_num,
		name = PlayerStatus#player_status.nickname,
        sex = PlayerStatus#player_status.sex,
        lv = PlayerStatus#player_status.lv,
        scene = PlayerStatus#player_status.scene,
        realm = PlayerStatus#player_status.realm,
        career = PlayerStatus#player_status.career,
        guild_id = PlayerStatus#player_status.guild#status_guild.guild_id,
        guild_name = PlayerStatus#player_status.guild#status_guild.guild_name,
        guild_position = PlayerStatus#player_status.guild#status_guild.guild_position,
        image = PlayerStatus#player_status.image,
        last_login_time = PlayerStatus#player_status.last_login_time,
		gm = PlayerStatus#player_status.gm,
		vip = PlayerStatus#player_status.vip#status_vip.vip_type,
		dailypid = PlayerStatus#player_status.dailypid
    }.
