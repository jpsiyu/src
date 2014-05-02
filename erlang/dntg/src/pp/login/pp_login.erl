%%%--------------------------------------
%%% @Module  : pp_login
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2010.04.29
%%% @Description:  注册登录系统
%%%--------------------------------------
-module(pp_login).
-export([handle/3, 
         check_heart_time/2,
         validate_name/1]).
-include("common.hrl").
-include("server.hrl").
-include("unite.hrl").
-include("record.hrl").

%%记录用户初始数据
-record(player, {
        socket = none,      % socket
        pid = none,         % 玩家进程
        login  = 0,         % 是否登录
        accid  = 0,         % 账户id
        accname = none,     % 账户名
        timeout = 0,        % 超时次数
        req_count = 0,      % 请求次数
        req_list = [],      % 请求列表
        req_time = 0        % 请求时间
    }).


%%登陆验证
handle(10000, Player, Data) ->
    try is_bad_pass(Data) of
        true ->
            [Accid, Accname | _] = Data,
            UserInfo = lib_player:get_role_any_id_by_accname(Accname),
            Uid = case UserInfo of
                [] ->
                    0;
                [[Id] | _] ->
                    Id
            end,
	    %%取选择最小人数的职业来返回
	    Career = get_min_career_choice(),
        {ok, BinData} = pt_100:write(10000, [Uid, length(UserInfo), Career, util:longunixtime()]),
            lib_server_send:send_one(Player#player.socket, BinData),
            {ok, Player#player{login = 1, accid = Accid, accname = Accname}};
        false -> 
            {ok, Player}
    catch
        _:_ -> {ok, Player}
    end;

%%退出登陆
handle(10001, Status, logout) when is_record(Status, player_status)->
    {ok, BinData} = pt_100:write(10001, []),
    lib_server_send:send_one(Status#player_status.socket, BinData),
    mod_login:logout(Status#player_status.pid);


%% 获取角色列表
handle(10002, Player, _Accname) when Player#player.login == 1 ->
    L = lib_login:get_role_list(Player#player.accname),
    {ok, BinData} = pt_100:write(10002, L),
    lib_server_send:send_one(Player#player.socket, BinData);

%% 创建角色
handle(10003, Player, [Realm, Career, Sex, Name, Source]) when is_list(Player#player.accname), is_list(Name), Player#player.login == 1 ->
    Accid = Player#player.accid,
    Accname = Player#player.accname,
    IP = util:get_ip(Player#player.socket),
	case check_ip_limit(IP) of
		true ->
		    case validate_name(Name) of  %% 角色名合法性检测
		        {false, Msg} ->
		            {ok, BinData} = pt_100:write(10003, [Msg, 0]),
		            lib_server_send:send_one(Player#player.socket, BinData);
		        true ->
                    case catch lib_login:create_role(Accid, Accname, Name, Realm, Career, Sex, IP, Source) of
		                0 ->
		                    %%角色创建失败
		                    {ok, BinData} = pt_100:write(10003, [0, 0]),
		                    lib_server_send:send_one(Player#player.socket, BinData);
                        Id when is_integer(Id) -> 
                            %%创建角色成功
                            update_career_choice(Career), %%职业选择加1
                            %% UC封测活动-创建角色发元宝
                            lib_uc:switch(create_role_send_gold, [Id]),
                            {ok, BinData} = pt_100:write(10003, [1, Id]),
                            lib_server_send:send_one(Player#player.socket, BinData);
                        Error -> 
                            %角色创建失败
		                    {ok, BinData} = pt_100:write(10003, [0, 0]),
		                    lib_server_send:send_one(Player#player.socket, BinData),
                            util:errlog("pp_login 10003 create_role error ~p~n", [Error])
		            end
		    end;
		false ->
			{ok, BinData} = pt_100:write(10003, [2, 0]),
		    lib_server_send:send_one(Player#player.socket, BinData)
	end;

%% 进入游戏
handle(10004, Player, [Id, Time, Ticket]) when Player#player.login == 1 ->
    case util:check_char_encrypt(Id, Time, Ticket) of
        true ->
            %% 获取IP
            Ip = util:get_ip(Player#player.socket),
            case mod_ban:check(Id, Ip) of
                passed -> %% 通过验证
                    case mod_login:login(start, [Id, Player#player.accname, Ip, Player#player.socket]) of
                        {error, MLR} ->
                            %%告诉玩家登陆失败
                            {ok, BinData} = pt_590:write(59004, MLR),
                            lib_server_send:send_one(Player#player.socket, BinData),
                            {ok, Player};
                        {ok, Pid} ->
                            %%告诉玩家登陆成功
                            {ok, BinData} = pt_100:write(10004, 1),
                            lib_server_send:send_one(Player#player.socket, BinData),
                            %% 进入逻辑处理
                            {ok, enter, Player#player{pid = Pid}}
                    end;
                login_more ->
                    {ok, BinData} = pt_590:write(59004, 2),
                    lib_server_send:send_one(Player#player.socket, BinData),
                    {ok, Player};
                forbidall -> %% 所有账号登陆都被禁止
                    {ok, BinData} = pt_590:write(59004, 10),
                    lib_server_send:send_one(Player#player.socket, BinData),
                    {ok, Player};
                forbidip ->  %% IP被封
                    {ok, BinData} = pt_590:write(59004, 3),
                    lib_server_send:send_one(Player#player.socket, BinData),
                    {ok, Player};
                _ -> %% 未定义
                    {ok, BinData} = pt_590:write(59004, 9),
                    lib_server_send:send_one(Player#player.socket, BinData),
                    {ok, Player}
            end;
        false ->
            {ok, BinData} = pt_590:write(59004, 9),
            lib_server_send:send_one(Player#player.socket, BinData),
            {ok, Player}
    end;

%% 删除角色 -  暂不使用
%handle(10005, Player, [Pid, Accname]) ->
%    case lib_login:delete_role(Pid, Accname) of
%        true ->
%            {ok, BinData} = pt_100:write(10005, 1),
%            lib_server_send:send_one(Player#player.socket, BinData);
%        false ->
%            {ok, BinData} = pt_100:write(10005, 0),
%            lib_server_send:send_one(Player#player.socket, BinData)
%    end;

%%登录心跳包
handle(10006, Player, _R) when is_record(Player, player) ->
    {ok, BinData} = pt_100:write(10006, []),
    lib_server_send:send_one(Player#player.socket, BinData);

%%聊天心跳包
%%进入聊天服务器后的心跳包
handle(10006, Status, _) when is_record(Status, unite_status) ->
    {ok, BinData} = pt_100:write(10006, []),
    lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
    ok;

%%进入游戏后心跳包
handle(10006, Status, _) when is_record(Status, player_status) ->
    Time = util:longunixtime(),
    T = case get("pp_base_heartbeat_last_time") of
        undefined->
            0;
        _T ->
            _T
    end,
    put("pp_base_heartbeat_last_time", Time),
    %case Time - T < 4900 of
	case Time - T < 1000 of
        true ->
            {ok, BinData} = pt_590:write(59004, 4),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            %% 关闭socket
            %lib_server_send:send_to_sid(Status#player_status.sid, close),
			ok;
        false ->
            skip
    end,
    {ok, BinData2} = pt_100:write(10006, []),
    lib_server_send:send_one(Status#player_status.socket, BinData2),
    ok;

%% 检查名字
handle(10010, Status, [Name]) when Status#player.login == 1 ->
    case validate_name(Name) of  %% 角色名合法性检测
        true ->
            {ok, BinData} = pt_100:write(10010, [1]),
            lib_server_send:send_one(Status#player.socket, BinData);
		_ ->
            {ok, BinData} = pt_100:write(10010, [0]),
            lib_server_send:send_one(Status#player.socket, BinData)
    end,
    ok;

%% 获取在线人数
handle(10016, Status, []) when Status#player.login == 1 ->
   L   = ets:tab2list(?ETS_NODE),
   Num = lists:sum([Node#node.num || Node <- L]),
   {ok, BinData} = pt_100:write(10016, Num),
   lib_server_send:send_one(Status#player.socket, BinData),
   ok;


%%%%获取聊天系统验证所需信息 
%%handle(10090, Status, _) when is_record(Status, player_status)->
%%    [Time, Ticket] = struct_socket_login_ticket(Status#player_status.id),
%%    [Ip, Port] = mod_disperse:get_chat_info(),
%%    {ok, BinData} = pt_100:write(10090, [Time, Port, Ip, Ticket]),
%%    lib_server_send:send_one(Status#player_status.socket, BinData);
%%获取socket登录验证所需信息
handle(10090, Status, _) when is_record(Status, player_status)->
    [Time, Ticket] = struct_socket_login_ticket(Status#player_status.id),
    [Ip, Port] = mod_disperse:get_unite_info(),
    {ok, BinData} = pt_100:write(10090, [Time, Port, Ip, Ticket]),
    lib_server_send:send_one(Status#player_status.socket, BinData);

%%公共线登录
handle(10091, Player, [Id, Time, Ticket]) when is_record(Player, player) ->
    case check_socket_login([Id, Time, Ticket]) of
        true ->
            case catch mod_login:unite_login(Id, Player#player.socket) of
                {ok, Pid} ->
                    %% 告诉玩家登陆成功
                    {ok, BinData} = pt_100:write(10091, 1),
                    lib_unite_send:send_one(Player#player.socket, BinData),
                    %% 进入逻辑处理
                    {ok, enter, Player#player{pid = Pid}};
                R ->
                    {ok, BinData} = pt_100:write(10091, 0),
                    lib_unite_send:send_one(Player#player.socket, BinData),
                    util:errlog("10091 mod_unite login:~p~n", [R])
            end;
        false ->
            {ok, BinData} = pt_100:write(10091, 0),
            lib_unite_send:send_one(Player#player.socket, BinData)
    end;

handle(_Cmd, _Status, _Data) ->
    ?DEBUG("pp_base no match", []),
    {error, "pp_base no match"}.

%% ------------ 私有函数 --------------
%%通行证验证
is_bad_pass([Accid, Accname, Tstamp, TK]) ->
    TICKET = config:get_ticket(),
    Hex = util:md5(lists:concat([Accid, Accname, Tstamp, TICKET])),
    %E = util:unixtime() - Tstamp,
    %E < 86400 andalso Hex =:= TK. %%失效时间
    Hex =:= TK.

%% 角色名合法性检测
validate_name(Name) ->
    validate_name(len, Name).

%% 角色名合法性检测:长度
validate_name(len, Name) ->
    case asn1rt:utf8_binary_to_list(list_to_binary(Name)) of
        {ok, CharList} ->
            Len = string_width(CharList),
            case Len < 13 andalso Len > 2 of
                true ->
                    validate_name(keyword, Name);
                false ->
                    %%角色名称长度为2~6个汉字
                    {false, 5}
            end;
        {error, _Reason} ->
            %%非法字符
            {false, 4}
    end;

%%判断角色名是否已经存在
%%Name:角色名
validate_name(existed, Name) ->
    case lib_player:is_exists(Name) of
        true ->
            %角色名称已经被使用
            {false, 3};
        false ->
            true
    end;

%%判断角色名是有敏感词
%%Name:角色名
validate_name(keyword, Name) ->
    case util:check_keyword(Name) of
        false ->
            validate_name(existed, Name);
        _ ->
            {false, 7}
    end;

validate_name(_, _Name) ->
    {false, 2}.

%% 字符宽度，1汉字=2单位长度，1数字字母=1单位长度
string_width(String) ->
    string_width(String, 0).
string_width([], Len) ->
    Len;
string_width([H | T], Len) ->
    case H > 255 of
        true ->
            string_width(T, Len + 2);
        false ->
            string_width(T, Len + 1)
    end.

%% 构造聊天系统登录验证信息
struct_socket_login_ticket(Id) ->
    Time = util:unixtime(),
    TICKET = config:get_ticket(),
    Hex = util:md5(lists:concat([TICKET, Time, Id])),
    [Time, Hex].

check_socket_login([Id, Time, TK]) ->
    TICKET = config:get_ticket(),
    Hex = util:md5(lists:concat([TICKET, Time, Id])),
    E = util:unixtime() - Time,
    E < 15 andalso Hex =:= TK. %% 15秒失效时间

%% 检查心跳包发送的频率
check_heart_time(NowTime, LimTime) ->
    case get("pp_base_heartbeat_last_time") of
        undefined->
            put("pp_base_heartbeat_last_time", 0),
            false;
        T ->
            NowTime - T > LimTime
    end.

%% 获取最少人选的职业
get_min_career_choice() ->
    case catch ets:lookup(ets_career_count, career_count) of
	[Res] when is_record(Res, career_count)->
	    SJ = Res#career_count.sj,
	    TZ = Res#career_count.tz,
	    LS = Res#career_count.ls,
	    if
		SJ =< TZ andalso SJ =< LS -> 1;	%%神将最少
		TZ =< SJ andalso TZ =< LS -> 2;	%%天尊最少
		true -> 3
	    end;
	Res when length(Res) =:= 0 ->			%%ETS表无数据
	    SQL = io_lib:format(<<"select `career`,count(`career`) from player_low group by `career` order by `career`">>,[]),
	    case db:get_all(SQL) of
	    	All when is_list(All) ->
		    [SJ, TZ, LS] = filter_db_career(All),
	    	    ets:insert(ets_career_count, #career_count{sj=SJ, tz=TZ, ls=LS});
	    	_ ->
	    	    []
	    end,
	    MinCareer = io_lib:format(<<"select `career` from player_low group by `career` order by count(`career`) limit 1">>,[]),
	    case db:get_one(MinCareer) of
		R when is_number(R) ->
		    R;
		_ ->
		    ets:insert(ets_career_count, #career_count{}),	%%刚开服没有任何职业的时候，选天尊
		    2
	    end;
	Reason ->			%%未创建ETS,检查mod_server_init.erl
	    util:errlog("handle 10000 error with reason:~p~n", [Reason]),
	    2
    end.
%% 职业选择加1
update_career_choice(Career) ->
    case Career of
	1 -> ets:update_counter(ets_career_count, career_count, {2,1}); %神将加1
	2 -> ets:update_counter(ets_career_count, career_count, {3,1});	%天尊加1
	3 -> ets:update_counter(ets_career_count, career_count, {4,1}) %罗刹加1
    end.

%% 分离查出来的职业个数
filter_db_career(List) ->
    case length(List) of
	1 ->
	    [[Career, Count]] = List,
	    case Career of
		1 -> [Count, 0, 0];
		2 -> [0, Count, 0];
		3 -> [0, 0, Count]
	    end;
	2 ->
	    [[Career1, Count1], [Career2, Count2]] = List,
	    if
		Career1 =:= 1 andalso Career2 =:= 2 ->
		    [Count1, Count2, 0];
		Career1 =:= 1 andalso Career2 =:= 3 ->
		    [Count1, 0, Count2];
		true ->
		    [0, Count1, Count2]
	    end;
	3 ->
	    [[_, Count1], [_, Count2], [_, Count3]] = List,
	    [Count1, Count2, Count3];
	_ ->
	    [0, 0, 0]
    end.

%% 检查IP注册量限制数量50,需要添加请直接在代码里修改
%% return true 通过,false 不通过
check_ip_limit(Ip)->
	TICKET = config:get_ticket(),
    case TICKET =:= "SDFSDESF123DFSDF" of
        true ->
            true;
        false ->
			case mod_ban:check_bai(Ip) of
				true ->
					true;
				_ ->
					Data = [util:ip2bin(Ip)],
					SQL  = io_lib:format("SELECT COUNT(*) FROM player_login WHERE reg_ip = '~s'", Data),
					case db:get_one(SQL) of
						null ->
							true;
						Times ->
							case Times >= 5000 of
								true ->
									false;
								false ->
									true
							end
					end
			end
    end.
