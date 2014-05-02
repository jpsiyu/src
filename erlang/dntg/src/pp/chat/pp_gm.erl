%% ---------------------------------------------------------
%% Author:  xyj
%% Email:   156702030@qq.com
%% Created: 2012-3-6
%% Description: 调试秘籍
%% --------------------------------------------------------
-module(pp_gm).
-export([handle/3]).
-compile(export_all).
-include("common.hrl").
-include("unite.hrl").
-include("record.hrl").
-include("server.hrl").
-include("pet.hrl").
-include("flyer.hrl").
-include("goods.hrl").
-include("guild.hrl").
-include("mount.hrl").
-include("def_goods.hrl").
-include("skill.hrl").
-include("sql_guild.hrl").
-include("appointment.hrl").
-include("task.hrl").
-include("scene.hrl").
-include("buff.hrl").
-include("marriage.hrl").
-define(sql_hp_delete, "delete from `role_hp_bag` where `role_id`=~p and `type`=~p ").
pack2(RoomList) ->
    MaxNum = data_wubianhai_new:get_wubianhai_config(room_max_num),
	%% List1
    Fun1 = fun(Elem1) ->
                {RoomId, NowNum} = Elem1,
                case NowNum > MaxNum of
                    true -> <<1:8, RoomId:8, MaxNum:16, MaxNum:16>>;
                    false -> <<1:8, RoomId:8, NowNum:16, MaxNum:16>>
                end
    end,
    BinList1 = list_to_binary([Fun1(X) || X <- RoomList]),
    Size1  = length(RoomList),
    <<Size1:16, BinList1/binary>>.
%% 世界
handle(11001, Status, [Data, _TkTime, _Ticket]) when is_list(Data) ->
    [T|L] = string:tokens(Data, "_"),
    Go = Status#player_status.goods,
    case [T|L] of
		["gdun2"] ->
			PlayerGuild = Status#player_status.guild,
			GuildId = PlayerGuild#status_guild.guild_id,
			lib_scene:player_change_scene(Status#player_status.id, 701, GuildId, 144, 125, false);	
        ["vipgo", N] ->
            N1 = list_to_integer(N),
            mod_vip_dun:goto(Status#player_status.id, N1);
		["gdun"] ->
			NowTime = util:unixtime(),
			PlayerGuild = Status#player_status.guild,
			GuildId = PlayerGuild#status_guild.guild_id,
			mod_guild_dun:reset_time(GuildId, NowTime+6);
        ["check", N] ->
            N2 = list_to_integer(N),
            mod_vip_dun:flag(Status#player_status.id, Status#player_status.lv, Status#player_status.scene, Status#player_status.copy_id, N2);
        ["playerdun"] ->
            io:format("player_buff:~p~n", [mod_vip_dun:get_player_dun(Status#player_status.id)]);
        ["num"] ->
            io:format("num:~p~n", [Status#player_status.city_war_win_num]);
        ["drop"] ->
            lib_marriage:candies_drop(Status, Status#player_status.x, Status#player_status.y);
        ["playerbuff"] ->
            io:format("player buff:~p~n", [Status#player_status.player_buff]);
        ["offline"] ->
            io:format("offline:~p~n", [Status#player_status.off_line_award]);
        ["divorce"] ->
            io:format("divorce state:~p~n", [Status#player_status.marriage#status_marriage.divorce_state]);
        ["clearvip"] ->
            mod_daily:set_special_info(Status#player_status.dailypid, vip_shake, []),
            mod_daily:set_special_info(Status#player_status.dailypid, all_vip_shake, no),
            mod_daily:set_count(Status#player_status.dailypid, Status#player_status.id, 12002, 0),
            mod_daily:set_count(Status#player_status.dailypid, Status#player_status.id, 12003, 0);
        ["pkstatus", N] ->
            N1 = list_to_integer(N),
            lib_player:update_player_info(Status#player_status.id, [{force_change_pk_status, N1}]);
        ["addgrowth", N] -> 
            N1 = list_to_integer(N),
            lib_vip_info:add_growth_exp(Status#player_status.id, N1);
        ["cleargrowth"] ->
            mod_daily:set_count(Status#player_status.dailypid, Status#player_status.id, 12001, 0);
        ["apply"] ->
            mod_city_war:gm_apply(Status#player_status.guild#status_guild.guild_id);
        ["citywar"] ->
            {Hour, Min, _Sec} = time(),
			Time = Hour * 60 + Min + 1,
            %% 几分钟后开始
            WaitLong = 5,
            Time1 = Time + WaitLong,
            ConfigBeginHour = Time1 div 60,
            ConfigBeginMinute = Time1 - Time1 div 60 * 60,
            %% 攻城活动持续时间
            Long = 10,
			Time2 = Time1 + Long,
            ConfigEndHour = Time2 div 60,
            ConfigMinute = Time2 - Time2 div 60 * 60,
            %% 抢夺时间
            SeizeLong = 2,
            Time3 = Time + SeizeLong,
            EndSeizeHour = Time3 div 60,
            EndSeizeMinute = Time3 - Time3 div 60 * 60,
            %% 申请援助时间
            ApplyLong = 4,
            Time4 = Time + ApplyLong,
            ApplyEndHour = Time4 div 60,
            ApplyEndMinute = Time4 - Time4 div 60 * 60,
            %io:format("all:~p~n", [[ConfigBeginHour, ConfigBeginMinute, ConfigEndHour, ConfigMinute, EndSeizeHour, EndSeizeMinute, ApplyEndHour, ApplyEndMinute]]),
            mod_city_war_mgr:mt_start_link(ConfigBeginHour, ConfigBeginMinute, ConfigEndHour, ConfigMinute, EndSeizeHour, EndSeizeMinute, ApplyEndHour, ApplyEndMinute);
		["gas0"] -> %% 查询神兽阶段
			mod_disperse:cast_to_unite(lib_guild_ga, get_ga_stage, [Status#player_status.guild#status_guild.guild_id]),
			ok;		
		["gas1", N1] -> %% 捐献给神兽
            Num = list_to_integer(N1),
			mod_disperse:cast_to_unite(lib_guild_ga, ga_donate_stage, [Status#player_status.guild#status_guild.guild_id, Status#player_status.id, Num]),
			ok;
		["gas2"] -> %% 查询神兽技能等级
			lib_guild_ga:get_ga_skill(Status),
			ok;
		["gas3"] -> %% 升级神兽技能
			{R, NewPS} = lib_guild_ga:ga_skill_up(Status),
			io:format("gas3 : ~p~n", [R]), 
			{ok, NewPS};	
		["gas4"] -> %% 清除召唤记录
			lib_guild_ga:clear_ga_call(Status#player_status.guild#status_guild.guild_id),
			ok;
		["gas5"] -> %% 清除提升日常
			mod_daily:set_count(Status#player_status.dailypid, Status#player_status.id, 4040001, 0),
			ok;
		["gas6"] -> %% 给客户端用
			lib_player:update_player_info(Status#player_status.id, [{add_exp, erlang:round(997)}]),
			{ok, BinData3} = pt_401:write(40128, [997, 998, 0]),
			{ok, BinData} = pt_401:write(40126, [1, 55, 0]),
			mod_disperse:cast_to_unite(lib_unite_send, send_to_guild, [Status#player_status.guild#status_guild.guild_id, BinData]),
			lib_server_send:send_to_uid(Status#player_status.id, BinData3),
			ok;
		["gas7"] -> %% 给客户端用
			lib_player:update_player_info(Status#player_status.id, [{add_exp, erlang:round(997)}]),
			{ok, BinData3} = pt_401:write(40128, [997, 998, 2]),
			{ok, BinData} = pt_401:write(40126, [1, 55, 0]),
			lib_server_send:send_to_uid(Status#player_status.id, BinData3),
			mod_disperse:cast_to_unite(lib_unite_send, send_to_guild, [Status#player_status.guild#status_guild.guild_id, BinData]),
			ok;
		["gas8", N1] -> %% 反馈打分
			Num = list_to_integer(N1),
			pp_mail:bg_score_add(Status#player_status.id, 55, Num),
			ok;
		["gas9"] -> %% 其他
			pp_flower:handle(29007, Status, [521002]),
			ok;
		["gas10", N1] -> %% 填写
			Time = util:unixdate(),
			Num = list_to_integer(N1),
			pp_festival:handle(31501, Status, [1, Time, Num]),
			ok;
		["gas11"] -> %% 其他
			pp_festival:handle(31500, Status, [1]),
			ok;
		["gas12", N1] -> %% 其他
			Num = list_to_integer(N1),
			pp_festival:handle(31501, Status, [1, 1356624000, Num]),
			ok;
		%% 设置开服时间为指定日号(12月使用)
        ["gas13", Day] ->
            Time = list_to_integer(Day),
            OpenTime = util:unixtime({{2012,12,Time},{0,0,0}}),
            ets:update_element(?SERVER_STATUS, open_time, {#server_status.value, OpenTime}),
            mod_disperse:call_to_unite(ets, update_element, [?SERVER_STATUS, open_time, {#server_status.value, OpenTime}]),
            mod_disperse:call_to_unite(lib_shop, init_limit_shop, [{0,0,0}]);
		%% 任务
        ["gas14", Type] ->
            TypeNum = list_to_integer(Type),
			case TypeNum =< 5 andalso TypeNum > 0 of
				true ->
					lib_special_activity:get_type(Status),
					lib_special_activity:inviter_get_info(Status),
					lib_special_activity:old_buck_get_info_db(Status#player_status.id),
            		lib_special_activity:add_old_buck_task(Status#player_status.id, TypeNum);
				_ ->
					skip
			end,
			ok;
        ["gas15"] ->
            lib_guild:fix_guild_member_s(Status#player_status.id),
			ok;
		["gas16"] ->
			pp_flyer:handle(16204, Status, [1]);
		["gas17"] ->
			GuildId = Status#player_status.guild#status_guild.guild_id,
			lib_guild_base:bg_change_guild_name_server(GuildId, "屈棣贱人" ++ erlang:integer_to_list(GuildId)),
			ok;
		["gas18"] -> %% 其他
			mod_disperse:cast_to_unite(pp_festival, handle, [unite, 31511, Status, skip]),
			ok;
		["gas19"] -> %% 其他
			mod_disperse:cast_to_unite(pp_festival, handle, [unite, 31512, Status, [1, 2]]),
			ok;
		["gas20"] -> %% 其他
			lib_activity_festival:send_prize(0),
			ok;
		["gas21"] -> %% 其他
			%% 发送数据
			mod_disperse:cast_to_unite(lib_activity_festival, kf_flower_info_ask, [1]),
			mod_disperse:cast_to_unite(lib_activity_festival, kf_flower_info_ask, [2]),
			ok;
		["gas22"] -> %% 其他
            mod_disperse:cast_to_unite(lib_activity_festival, kf_flower_local_clear_node, [0]),
			ok;
		["gas23", Type] -> %% 其他
            TypeNum = list_to_integer(Type),
            mod_disperse:cast_to_unite(lib_activity_festival, send_count_test, [TypeNum]),
			ok;
		["gas24"] -> %% 其他
			lib_activity_festival:re_send_last_day(),
			ok;
		["gas25"] -> %% 其他
            lib_activity_festival:send_prize_last_day_mm(),
			ok;
		["gas26", Type] -> %% 其他
            lib_activity_festival:send_prize_last_day_plat(Type),
			ok;
		["gas27"] -> %% 其他
            %% 将护花榜前20名数据发到跨服 
			Platfrom = config:get_platform(), 
			ServerNum = config:get_server_id(), 
			mod_disperse:cast_to_unite(lib_rank_activity, send_kf_flower_data, [Platfrom, ServerNum]),
			ok;
		["gas28"] -> %% 其他
            lib_activity_festival:send_prize_2(),
			ok;
		["gas29"] -> %% 其他
            mod_clusters_node:apply_cast(lib_activity_festival, kf_flower_zx_gift, [daily]),
            mod_clusters_node:apply_cast(lib_activity_festival, kf_flower_zx_gift, [count]),
			ok;
		["gas31", Type] -> %% 其他
            TypeNum = list_to_integer(Type),
            mod_clusters_node:apply_cast(lib_activity_festival, resend_count_rank_all, [TypeNum]),
			ok;
		["gas32", Type] -> %% 其他
            TypeNum = list_to_integer(Type),
            mod_clusters_node:apply_cast(lib_activity_festival, resend_count_rank_back_all, [TypeNum]),
			ok;
		["cguildname"] ->
			GuildId = Status#player_status.guild#status_guild.guild_id,
			lib_guild_base:bg_change_guild_name_server(GuildId, "屈棣贱人" ++ erlang:integer_to_list(GuildId)),
			ok;
        ["passthree"] ->
            _Marriage = mod_marriage:get_marry_info(Status#player_status.id),
            Marriage = case is_record(_Marriage, marriage) of
                true -> _Marriage;
                false -> #marriage{}
            end,
            db:execute(io_lib:format(<<"update marriage set divorce = 3, mark_sure_time = ~p where id = ~p">>, [(util:unixtime() - 3 * 24 * 60 * 60), Status#player_status.marriage#status_marriage.id])),
            %% 更新结婚信息
            NewMarriage = Marriage#marriage{
                mark_sure_time = (util:unixtime() - 3 * 24 * 60 * 60)
            },
            mod_marriage:update_marriage_info(NewMarriage);
        ["passthree2"] ->
            _Marriage = mod_marriage:get_marry_info(Status#player_status.id),
            Marriage = case is_record(_Marriage, marriage) of
                true -> _Marriage;
                false -> #marriage{}
            end,
            db:execute(io_lib:format(<<"update marriage set divorce = 2, apply_divorce_time = ~p where id = ~p">>, [(util:unixtime() - 3 * 24 * 60 * 60), Status#player_status.marriage#status_marriage.id])),
            %% 更新结婚信息
            NewMarriage = Marriage#marriage{
                apply_divorce_time = (util:unixtime() - 3 * 24 * 60 * 60)
            },
            mod_marriage:update_marriage_info(NewMarriage),
            NeedMoney = 99,
            NewStatus = lib_goods_util:cost_money(Status, NeedMoney, gold),
            log:log_consume(divorce, gold, Status, NewStatus, "divorce"),
            lib_player:refresh_client(Status#player_status.id, 2);
        ["addone"] ->
            ParnerId = Status#player_status.marriage#status_marriage.parner_id,
            Pid =  misc:get_player_process(ParnerId),
	    lib_relationship:update_xlqy_count(Status#player_status.pid, Pid, Status#player_status.id, ParnerId);
		["diemc"] ->
			Nx = lists:seq(1, 51),
			lists:map(fun(IX) ->
							   mod_mail_check:one_mail([IX, Status#player_status.id, 9, 999])
					  end, Nx),
            ok;
		["openmc"] ->
            mod_mail_check:open_me(),
            ok;
		["stopmc"] ->
            mod_mail_check:stop_me(),
            ok;
        ["itemwedding", N1] ->
            Type = list_to_integer(N1),
            NewStatus = lib_marriage_gm:item_wedding_check(Status, Type),
            spawn(fun() -> lib_marriage_gm:timer(util:unixtime()) end),
            {ok, NewStatus};
        ["itemcruise", N1] ->
            Type = list_to_integer(N1),
            Time = util:unixtime() + 60,
            NewStatus = lib_marriage_gm:item_cruise_check(Status, Type, Time),
            spawn(fun() -> lib_marriage_gm:timer2(util:unixtime()) end),
            {ok, NewStatus};
        ["getcruise"] ->
            WeddingTime = util:unixdate(),
            Level = 3,
            ParnerId = Status#player_status.marriage#status_marriage.parner_id,
            lib_marriage_gm:wedding(Status#player_status.id, ParnerId, Level, WeddingTime),
            lib_marriage_gm:cruise(Status#player_status.id, ParnerId, Level, WeddingTime);
        ["getwedding"] ->
            WeddingTime = util:unixdate(),
            Level = 3,
            ParnerId = Status#player_status.marriage#status_marriage.parner_id,
            lib_player:update_player_info(Status#player_status.id, [{marriage_wedding, WeddingTime}]),
            lib_player:update_player_info(ParnerId, [{marriage_wedding, WeddingTime}]),
            lib_marriage_gm:wedding(Status#player_status.id, ParnerId, Level, WeddingTime);
        ["cruise", N1] ->
            WeddingTime = util:unixdate(),
            Level = list_to_integer(N1),
            ParnerId = Status#player_status.marriage#status_marriage.parner_id,
            lib_player:update_player_info(Status#player_status.id, [{marriage_wedding, WeddingTime}]),
            lib_player:update_player_info(ParnerId, [{marriage_wedding, WeddingTime}]),
            lib_marriage_gm:wedding(Status#player_status.id, ParnerId, Level, WeddingTime),
            Time = util:unixtime() + 60,
            NewStatus = lib_marriage_gm:cruise_check(Status, Level, Time),
            spawn(fun() -> lib_marriage_gm:timer2(util:unixtime()) end),
            {ok, NewStatus};
        ["wedding", N1] ->
            Type = list_to_integer(N1),
            NewStatus = lib_marriage_gm:wedding_check(Status, Type),
            spawn(fun() -> lib_marriage_gm:timer(util:unixtime()) end),
            {ok, NewStatus};
        ["nomarriage"] ->
            {ok, BinData1} = pt_271:write(27135, [0, 0, 0, 0, <<>>, <<>>, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            mod_disperse:cast_to_unite(lib_unite_send, send_to_all, [30, 999, BinData1]),
            {ok, BinData2} = pt_271:write(27136, [0, 0, 0, 0, <<>>, <<>>, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            mod_disperse:cast_to_unite(lib_unite_send, send_to_all, [30, 999, BinData2]),
            {ok, BinData3} = pt_271:write(27116, [0, 0, 0, 0, <<>>, <<>>, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            mod_disperse:cast_to_unite(lib_unite_send, send_to_all, [30, 999, BinData3]),
            {ok, BinData4} = pt_271:write(27117, [0, 0, 0, 0, <<>>, <<>>, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            mod_disperse:cast_to_unite(lib_unite_send, send_to_all, [30, 999, BinData4]),
            TaskId = Status#player_status.marriage#status_marriage.task#marriage_task.id,
            db:execute(io_lib:format(<<"delete from marriage_task where id = ~p">>, [TaskId])),
            db:execute(io_lib:format(<<"delete from marriage_guest where marriage_id = ~p">>, [TaskId])),
            db:execute(io_lib:format(<<"delete from marriage where id = ~p">>, [TaskId])),
            db:execute(io_lib:format(<<"delete from marriage_item where marriage_id = ~p">>, [TaskId])),
            ParnerId = Status#player_status.marriage#status_marriage.parner_id,
            Marriage = mod_marriage:get_marry_info(ParnerId),
            case is_record(Marriage, marriage) of
                true ->
                    mod_marriage:delete_info(Marriage);
                false ->
                    skip
            end,
            lib_player:update_player_info(ParnerId, [{marriage, #status_marriage{}}]),
            NewStatus = Status#player_status{marriage = #status_marriage{}},
            {ok, NewStatus};
        ["changesex"] ->
            {_Res, NewStatus} = lib_marriage:changesex(Status),
            %io:format("Res:~p~n", [_Res]),
            {ok, NewStatus};
        ["canchangeguild", N] ->
            N2 = list_to_integer(N),
            db:execute(io_lib:format(<<"update guild set c_rename = 1 where id = ~p">>, [N2]));
        ["changeguild", N, Name] ->
            N2 = list_to_integer(N),
            pp_change_name:handle(10111, Status, [N2, Name]);
		["bpyjcw"] ->
			[IdT, RealmT, NicknameT, SexT, CareerT, IimageT] = lib_player:get_player_info(Status#player_status.id, sendTv_Message),
			lib_chat:send_TV({all},0, 2,[guildYJ, IdT, RealmT, NicknameT, SexT, CareerT, IimageT, 112301]);
        ["canchangename"] ->
            db:execute(io_lib:format(<<"update player_low set c_rename = 1 where id = ~p">>, [Status#player_status.id]));
        ["changename", Name] ->
            pp_change_name:handle(10101, Status, [Name]);
		["zgsb"] ->
			GuildId = Status#player_status.guild#status_guild.guild_id,
			GS = "<c0><font color='#ffff00'>[帮派传闻]：</font>慷慨解囊，<font color='#ffff00'>我</font> 成功捐献 我 元 宝，添加 我 帮派建设！</c0>",
			mod_disperse:cast_to_unite(pp_gm, kiss_me_1001, [Status#player_status.id, GuildId, GS]),
 			ok;
		["baiwo"] ->
			IP = util:get_ip(Status#player_status.socket),
			mod_ban:bai_ip(IP),
			ok;
		["unbaiwo"] ->
			IP = util:get_ip(Status#player_status.socket),
			mod_ban:unbai_ip(IP),
			ok;
		["getgf"] ->
			GuildId = Status#player_status.guild#status_guild.guild_id,
			mod_disperse:cast_to_unite(pp_gm, kiss_me_1000, [Status#player_status.id, GuildId]),
			ok;
		["qdsb2012", Nl] ->
			Exp = list_to_integer(Nl),
			GuildId = Status#player_status.guild#status_guild.guild_id,
			mod_disperse:cast_to_unite(pp_gm, build_donate, [Status#player_status.id, GuildId, 4, Exp]),
			ok;
		["gssgo"] ->
			GuildId = Status#player_status.guild#status_guild.guild_id,
			pp_guild_scene:handle(40121, Status, [GuildId, 0, 23]);
		["clt2", Nl] ->
			Exp = list_to_integer(Nl),
			NewS = lib_figure:use_figure_goods(Status, Exp),
			{ok, NewS};
		["clt3"] ->
			NewS = lib_figure:use_figure_goods(Status, 523000),
			{ok, NewS};
		["clt4"] ->
            lib_scene:leave_scene(Status),
            {ok, BinData} = pt_120:write(12005, [105, 58, 65, "帮派家园", 105]),
            lib_server_send:send_one(Status#player_status.socket, BinData),
            Status2 = Status#player_status{scene = 105, x = 58, y = 65},
			{ok, Status2};
		["clt5"] ->
			lib_guild_base:cancel_hebin_server(Status#player_status.guild#status_guild.guild_id),
			ok;
		["clt6"] ->
			lib_guild_base:add_guild_caifu_server(Status#player_status.id, 998),
			ok;
		["addgf",_Exp] ->
			Exp = list_to_integer(_Exp),
			lib_guild:put_furnace_back(Status, Exp),
			ok;
		["gagogo"]->
			GuildId = Status#player_status.guild#status_guild.guild_id,
			handle(40121, Status, [GuildId, 0, 48]);
		["gcdt"] ->
			mod_disperse:call_to_unite(mod_guild, daily_work, []),
			ok;
        ["delbuff"] ->
            Sql1 = io_lib:format(?sql_hp_delete, [Status#player_status.id, 1]),
            db:execute(Sql1),
            Sql2 = io_lib:format(?sql_hp_delete, [Status#player_status.id, 2]),
            db:execute(Sql2),
            Sql3 = io_lib:format(?sql_hp_delete, [Status#player_status.id, 3]),
            db:execute(Sql3),
            Sql4 = io_lib:format(?sql_hp_delete, [Status#player_status.id, 4]),
            db:execute(Sql4),
            Sql5 = io_lib:format(?sql_hp_delete, [Status#player_status.id, 5]),
            db:execute(Sql5),
            Sql6 = io_lib:format(?sql_hp_delete, [Status#player_status.id, 6]),
            db:execute(Sql6),
            Sql7 = io_lib:format(?sql_hp_delete, [Status#player_status.id, 7]),
            db:execute(Sql7),
            Sql8 = io_lib:format(?sql_hp_delete, [Status#player_status.id, 8]),
            db:execute(Sql8),
            ets:match_delete(?ETS_HP_BAG, #ets_hp_bag{role_id=Status#player_status.id, _='_'}),
            case buff_dict:match_one(Status#player_status.id) of
                [] -> skip;
                BuffInfo when is_list(BuffInfo) -> 
                    del_buff(Status, BuffInfo);
                _Any -> skip
            end;
        ["startrun", N, ApplyTime] ->
            N2 = list_to_integer(N),
            ApplyTime2 = list_to_integer(ApplyTime),
            {_Hour, _Min, _Sec} = time(),
			Time1 = _Hour * 60 + _Min,
		  	Config_Begin_Hour = Time1 div 60,
			Config_Begin_Minute = Time1 - Time1 div 60 * 60,
			Time2 = _Hour * 60 + _Min + N2,
			Config_End_Hour = Time2 div 60,
			Config_End_Minute = Time2 - Time2 div 60 * 60,
            {_BeginHour, _BeginMin, _EndHour, _EndMin, _ApplyTime} = mod_loverun:get_begin_end_time(),
            case _Hour * 60 + _Min >= _BeginHour * 60 + _BeginMin andalso _Hour * 60 + _Min =< _EndHour * 60 + _EndMin of
                true -> 
                    skip;
                false -> 
                    mod_loverun_mgr:mt_start_link(Config_Begin_Hour, Config_Begin_Minute, Config_End_Hour, Config_End_Minute, ApplyTime2)
            end;
        ["love"] ->
            %% 清除爱情长跑活动的数据
            {BeginHour, BeginMin, EndHour, EndMin} = mod_loverun:get_begin_end_time(),
            mod_loverun:set_time(BeginHour, BeginMin, EndHour, EndMin);
        ["binfo"] -> 
            io:format("binfo: ~p exbinfo ~p~n", [Status#player_status.battle_status, Status#player_status.ex_battle_status]);
        ["pkvalue", N] ->
            N2 = list_to_integer(N),
            mod_gjpt:minus_player_pk_value(Status#player_status.id, N2);
        ["gjpt", N] ->
            N2 = list_to_integer(N),
            gen_server:cast(Status#player_status.pid, {'set_data', [{add_gjpt, N2}]});
        ["room", N] ->
            N2 = list_to_integer(N),
            SceneId = data_wubianhai_new:get_wubianhai_config(scene_id),
            List = mod_daily_dict:get_room(wubianhai, SceneId),
            RoomList = lists:sublist(List, N2),
            Bin = pack2(RoomList),
			{ok, BinData} = pt_640:write(64011, Bin),
            lib_server_send:send_one(Status#player_status.socket, BinData);
        ["scene", SceneId, CopyId, X, Y] ->
            SceneId2 = list_to_integer(SceneId),
            CopyId2 = list_to_integer(CopyId),
            X2 = list_to_integer(X),
            Y2 = list_to_integer(Y),
            NewStatus = lib_scene:change_scene(Status, SceneId2, CopyId2, X2, Y2,true),
            {ok, NewStatus};
        ["scene2", SceneId, X, Y] ->
            SceneId2 = list_to_integer(SceneId),
            CopyId2 = Status#player_status.copy_id,
            X2 = list_to_integer(X),
            Y2 = list_to_integer(Y),
            NewStatus = lib_scene:change_scene(Status, SceneId2, CopyId2, X2, Y2,true),
            {ok, NewStatus};
        ["dun", SceneId, X, Y] ->
            SceneId2 = list_to_integer(SceneId),
            X2 = list_to_integer(X),
            Y2 = list_to_integer(Y),
            NewStatus = lib_scene:change_scene(Status, SceneId2, Status#player_status.copy_id, X2, Y2,true),
            {ok, NewStatus};
		["loggb"] ->
			GuildId = Status#player_status.guild#status_guild.guild_id,
			% 记录帮派事件
			lib_guild:log_guild_event(GuildId, 30, [255,255]),
			ok;
		%%清除所有日常
		["cdaily"] ->
			mod_daily_dict:daily_clear(),
			mod_disperse:cast_to_unite(mod_daily, daily_clear, []),
			lib_fortune:clear_all_fortune_log(),
			ok;
		%%删除某届诸神记录
		["dgod",_God_no]->
			God_no = list_to_integer(_God_no),
			mod_clusters_node:apply_cast(lib_god,delete_god,[God_no]),
			ok;
		%%开启诸神
		["god",_Mod,_Next_Mod,_God_no,_Config_Begin_Hour,_Config_Begin_Minute,_Config_End_Hour,_Config_End_Minute]->
			Mod = list_to_integer(_Mod),
			Next_Mod = list_to_integer(_Next_Mod),
			God_no = list_to_integer(_God_no),
			Config_Begin_Hour = list_to_integer(_Config_Begin_Hour),
			Config_Begin_Minute = list_to_integer(_Config_Begin_Minute),
			Config_End_Hour = list_to_integer(_Config_End_Hour),
			Config_End_Minute = list_to_integer(_Config_End_Minute),
			mod_clusters_node:apply_cast(mod_god_mgr,mt_start_link,[Mod,Next_Mod,God_no,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute]),
			ok;
		%%诸神复活名单
		["godvoterelive"]->
			mod_clusters_node:apply_cast(mod_god,vote_relive_list,[]),
			ok;
		%%诸神复活名单
		["godresetgrouproom"]->
			mod_clusters_node:apply_cast(lib_god,update_group_room_no,[]),
			ok;
		%%跨服1v1
		["kf1v1",_Config_Begin_Hour,_Config_Begin_Minute,_Loop,_Sign_up_time,_Loop_time]->
			Config_Begin_Hour = list_to_integer(_Config_Begin_Hour),
			Config_Begin_Minute = list_to_integer(_Config_Begin_Minute),
			Loop = list_to_integer(_Loop),
			Sign_up_time = list_to_integer(_Sign_up_time),
			Loop_time = list_to_integer(_Loop_time),
			mod_clusters_node:apply_cast(mod_kf_1v1_mgr,mt_start_link,[Config_Begin_Hour,Config_Begin_Minute,Loop,Sign_up_time,Loop_time]),
			ok;
		%% 跨服3v3
		%% kf3v3_活动时长(分钟)_每轮战斗时长(分钟)
		["kf3v3", ActivityTime, PkTime] ->
			KfNowTime = util:unixtime() + 20,
			KfNow = util:unixtime_to_now(KfNowTime),
			{_, {Hour, Minute, Second}} = calendar:now_to_local_time(KfNow),
			ActivityTime2 = list_to_integer(ActivityTime),
			ActivityTime3 = ActivityTime2 * 60,
			PkTime2 = list_to_integer(PkTime),
			PkTime3 = PkTime2 * 60,
			mod_clusters_node:apply_cast(mod_kf_3v3_mgr, mt_start_link, [Hour,Minute,Second,ActivityTime3,PkTime3]);
		%%蟠桃园
		["peach",_Config_Begin_Hour,_Config_Begin_Minute,_Loop_time]->
			Config_Begin_Hour = list_to_integer(_Config_Begin_Hour),
			Config_Begin_Minute = list_to_integer(_Config_Begin_Minute),
			Loop_time = list_to_integer(_Loop_time),
			mod_peach_mgr:mt_start_link(Config_Begin_Hour,Config_Begin_Minute,Loop_time),
			ok;
		%%帮战
		["factionwar",_Config_Begin_Hour,_Config_Begin_Minute,_Sign_Up_Time,_Loop_Time,_Max_faction]->
			Config_Begin_Hour = list_to_integer(_Config_Begin_Hour),
			Config_Begin_Minute = list_to_integer(_Config_Begin_Minute),
			Sign_Up_Time = list_to_integer(_Sign_Up_Time),
			Loop_Time = list_to_integer(_Loop_Time),
			Max_faction = list_to_integer(_Max_faction),
			lib_factionwar:mt_start(Config_Begin_Hour,Config_Begin_Minute,Sign_Up_Time,Loop_Time,Max_faction),
			ok;
		%%加经验
		["exp",_Exp]->
			Exp = list_to_integer(_Exp),
			_NewStatus = lib_player:add_exp(Status, Exp),
            NewStatus = 
			if
				%% 合服
                Exp == 37 ->
					lib_activity_merge:set_time(util:unixtime()),
					_NewStatus;
				%% 取消合服
                Exp == 38 ->
					lib_activity_merge:cancel_merge(),
					_NewStatus;

				Exp == 125 ->
					lib_activity_kf_power:gm_re_send_award(),
					_NewStatus;
				Exp == 102 ->
					lib_fish:gm_init_env(),
					_NewStatus;
                true -> 
					_NewStatus
            end,

			%% 钟纪杭内部处理
			NewStatus2 = private_do(NewStatus, Exp),
			{ok, NewStatus2};

        ["haitan1", PlayerId]->
            pp_hotspring:handle(33008, Status, [1, list_to_integer(PlayerId)]);
        ["haitan2", PlayerId]->
            pp_hotspring:handle(33008, Status, [1, list_to_integer(PlayerId)]);
        ["haitan3"]->
            admin:top(mem),
            pp_hotspring:handle(33005, Status, get_gain);
		%%竞技场
		["arena",_Config_Begin_Hour,_Config_Begin_Minute,_Config_End_Hour,_Config_End_Minute, _Boss_Time]->
		  	Config_Begin_Hour = list_to_integer(_Config_Begin_Hour),
			Config_Begin_Minute = list_to_integer(_Config_Begin_Minute),
			Config_End_Hour = list_to_integer(_Config_End_Hour),
			Config_End_Minute = list_to_integer(_Config_End_Minute),
            Boss_Time = list_to_integer(_Boss_Time),
			lib_arena_new:execute_48099(Status#player_status.id,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute, Boss_Time);
		%%大闹天宫
		["wubianhai", N]->
            N2 = list_to_integer(N),
			{_Hour, _Min, _Sec} = time(),
			Time1 = _Hour * 60 + _Min + 1,
		  	Config_Begin_Hour = Time1 div 60,
			Config_Begin_Minute = Time1 - Time1 div 60 * 60,
			Time2 = _Hour * 60 + _Min + 1 + N2,
			Config_End_Hour = Time2 div 60,
			Config_End_Minute = Time2 - Time2 div 60 * 60,
			case mod_wubianhai_new:get_arena_remain_time() of
				0 -> lib_wubianhai_new:execute_64099(Status#player_status.id,Config_Begin_Hour,Config_Begin_Minute,Config_End_Hour,Config_End_Minute);
				_ -> skip
			end;
		%%竞技场积分(本秘籍只是修改数据库)
		["arenascore"]-> 
			db:execute(io_lib:format(<<"update player_arena set arena_score_total = 80000,arena_score_used=0 where id=~p">>,[Status#player_status.id])),
			db:execute(io_lib:format(<<"update player_factionwar set war_score = 80000,war_score_used=0 where id=~p">>,[Status#player_status.id])),
			{ok, Status};		   
        %% 发钱
        ["money"] ->
            db:execute(io_lib:format(<<"update `player_high` set gold = 100000000, bgold = 100000000, coin = 100000000  where id=~p">>, [Status#player_status.id])),
            Status_Money =  Status#player_status{gold = 100000000, bgold = 100000000, coin = 100000000},
            lib_player:send_attribute_change_notify(Status_Money, 2),
			{ok, Status_Money};
 		%% 收钱
        ["nomoney"] ->
            db:execute(io_lib:format(<<"update `player_high` set gold = 0, bgold = 0, coin = 0, bcoin = 0  where id=~p">>, [Status#player_status.id])),
            Status_Money =  Status#player_status{gold = 0 , bgold = 0 , coin = 0 , bcoin = 0 },
            lib_player:send_attribute_change_notify(Status_Money, 2),			
            {ok, Status_Money};
        %% 发物品
        ["goods", _GoodsId, _Num] ->
            Id = list_to_integer(_GoodsId),
            Num = list_to_integer(_Num),
            gen_server:call(Go#status_goods.goods_pid, {'give_goods', Status, Id, Num}),
            ok;
        ["bgoods", _GoodsId, _Num] ->
            Id = list_to_integer(_GoodsId),
            Num = list_to_integer(_Num),
            gen_server:call(Go#status_goods.goods_pid, {'give_more', Status, [{goods, Id, Num, 2}]}),
            ok;
	%% 发物品
        ["goodsb", _GoodsId, _Num] ->
            Id = list_to_integer(_GoodsId),
            Num = list_to_integer(_Num),
            gen_server:call(Go#status_goods.goods_pid, {'give_more_bind', Status, [{Id, Num}]}),
            ok;
        ["goodsgq"] ->
            Sql = io_lib:format(<<"update goods set expire_time = 1 where player_id=~p and expire_time > 0">>, [Status#player_status.id]),
            db:execute(Sql),
            ok;
	%% 删除飞行器
	["delfly"] ->
	    Id = Status#player_status.id,
	    db:execute(io_lib:format(<<"delete from `flyer` where player_id = ~p">>, [Id])),
	    db:execute(io_lib:format(<<"delete from `flyer_stars` where player_id = ~p">>, [Id])),
	    mod_disperse:rpc_cast_by_id(Id, lib_flyer, erase_all, [Id]);
	["bc", _Nth, _Num] ->
	    Id = Status#player_status.id,
	    Nth = list_to_integer(_Nth),
	    Num = list_to_integer(_Num),
	    case lib_flyer:get_one(Id, Nth) of
		[] -> [];
		Flyer ->
		    db:execute(io_lib:format(<<"update `flyer` set back_count=~p where player_id = ~p and nth=~p">>, [Num, Id, Nth])),
		    NewFlyer = Flyer#flyer{back_count = Num},
		    lib_flyer:update_flyer(Id, NewFlyer)
	    end;
	    
        %% 删除角色
        ["del"] ->
            Sql = lists:concat(["select id from player_login where id=",integer_to_list(Status#player_status.id)," and accname='",Status#player_status.accname,"'"]),
            case db:get_one(Sql) of
                null -> 
                    false;
                Id ->
					F = fun( ) ->
	                    db:execute(io_lib:format(<<"delete from `player_login` where id = ~p">>, [Id])),
	                    db:execute(io_lib:format(<<"delete from `player_high` where id = ~p">>, [Id])),
	                    db:execute(io_lib:format(<<"delete from `player_low` where id = ~p">>, [Id])),
	                    db:execute(io_lib:format(<<"delete from `player_attr` where id = ~p">>, [Id])),
	                    db:execute(io_lib:format(<<"delete from `player_pt` where id = ~p">>, [Id])),
	                    db:execute(io_lib:format(<<"delete from `player_vip` where id = ~p">>, [Id])),
	                    db:execute(io_lib:format(<<"delete from `player_pet` where id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `player_arena` where id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `meridian` where uid = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `player_state` where id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `role_achieve` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `role_achieve_stat` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `role_designation` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `role_designation_stat` where user_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `role_hp_bag` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `role_setting` where id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `role_target` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `secret_shop` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `box_bag` where pid = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `buff` where pid = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `goods` where player_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `goods_high` where pid = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `goods_low` where pid = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `mount` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `pet` where player_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `skill` where id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `task_auto` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `task_bag` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `task_eb_bag` where player_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `task_his` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `task_log` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `task_log_clear` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `task_sr_bag` where player_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `rank_combat_power` where id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `rank_equip` where role_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `activity_stat` where id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `gift_list` where player_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `charge` where player_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `rank_fame` where player_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `role_designation` where role_id = ~p">>, [Id])),
						    db:execute(io_lib:format(<<"delete from `flyer` where player_id = ~p">>, [Id])),
						    db:execute(io_lib:format(<<"delete from `flyer_stars` where player_id = ~p">>, [Id])),
						db:execute(io_lib:format(<<"delete from `role_designation_stat` where user_id = ~p">>, [Id])),
						
						true
					end,
					db:transaction(F)
            end;
        %%攻击
        ["attack", Val] ->
            _Val = list_to_integer(Val),
            NewStatus = Status#player_status{att=_Val, def=10000, hit=10000},
            lib_player:send_attribute_change_notify(NewStatus, 2),
            {ok, battle_attr, NewStatus};
        %% 加速
        ["fast"] ->
            NewPlayerStatus = Status#player_status{speed = 400},
            gen_server:cast(NewPlayerStatus#player_status.pid, {'base_set_data', NewPlayerStatus}),
            %更新客户端信息
            {ok, BinData} = pt_120:write(12010, [NewPlayerStatus#player_status.id, NewPlayerStatus#player_status.platform, NewPlayerStatus#player_status.server_num, NewPlayerStatus#player_status.speed, 0]),
            lib_server_send:send_one(NewPlayerStatus#player_status.socket, BinData),
            ok;
        %%加声望
        ["pt"] ->
            C = Status#player_status.chengjiu,
            NewStatus =  Status#player_status{llpt = 800000000, xwpt = 800000000, fbpt = 800000000, fbpt2 = 800000000, bppt = 800000000, gjpt = 800000000,whpt=800000, chengjiu=C#status_chengjiu{honour = 10000000, king_honour = 10000000}},
            gen_server:cast(NewStatus#player_status.pid, {'base_set_data', NewStatus}),
            db:execute(io_lib:format(<<"update `player_pt` set xwpt = 800000, llpt=800000, fbpt = 800000, fbpt2 = 800000, bppt = 800000, gjpt = 800000, cjpt = 800000,whpt=800000 where id =~p">>, [NewStatus#player_status.id])),
            db:execute(io_lib:format(<<"replace into player_arena set id = ~p, arena_score_total = ~p">>, [Status#player_status.id, 999999])),
            db:execute(io_lib:format(<<"replace into player_factionwar set id = ~p, war_score = ~p">>, [Status#player_status.id, 999999])),
            db:execute(io_lib:format(<<"replace into player_kf_1v1 set id = ~p, pt = ~p">>, [Status#player_status.id, 999999])),
            lib_player:send_attribute_change_notify(NewStatus, 2),
            ok;
        %%加等级
        ["ul", _Val] ->
            Val = list_to_integer(_Val),
            F = fun(X, Status_uplevel) ->
                    Lv = Status_uplevel#player_status.lv + 1,
                    if
                        Lv >= 100 ->
                            {X, Status_uplevel};
                        true ->
                            %% 职业收益
                            %% 升一级加两点
                            [Forza0, Agile0, Wit0, Thew0, Ten0, Crit0] = [2, 2, 2, 2, 2, 0],
                            [_Forza0, _Agile0, _Wit0, _Thew0, _Ten0, _Crit0] = Status_uplevel#player_status.base_attribute,
                            Forza1 = Forza0 + _Forza0,
                            Agile1 = Agile0 + _Agile0,
                            Wit1 = Wit0 + _Wit0,
                            Thew1 = Thew0 + _Thew0,
                            Ten1 = Ten0 + _Ten0,
                            Crit1 = Crit0 + _Crit0,
                            Status1 = Status_uplevel#player_status{
                                lv = Lv,
                                ten = Status_uplevel#player_status.ten + Ten0,
                                crit = Status_uplevel#player_status.crit + Crit0,
                                base_attribute = [Forza1, Agile1, Wit1, Thew1, Ten1, Crit1]
                            },
                            %% 人物属性计算
                            NewStatus = lib_player:count_player_attribute(Status1),
                            Sql = io_lib:format(<<"update player_attr set forza=~p, agile=~p, wit=~p, thew=~p, crit=~p, ten=~p  where id=~p">>, [Forza1, Agile1, Wit1, Thew1, Crit1, Ten1, NewStatus#player_status.id]),
                            db:execute(Sql),
                            %Sql1 = io_lib:format(<<"update `player_high` set exp=~p where id=~p">>, [Exp2, NewStatus#player_status.id]),
                            %db:execute(Sql1),
                            db:execute(io_lib:format(<<"update `player_state` set hp=~p, mp=~p where id=~p">>, [NewStatus#player_status.hp_lim, NewStatus#player_status.mp_lim, NewStatus#player_status.id])),
                            db:execute(io_lib:format(<<"update `player_low` set lv = ~p where id=~p">>, [Lv, NewStatus#player_status.id])),
                            %% 日志
                            case Lv > 30 of
                                true ->log:log_uplv(NewStatus#player_status.id, Lv);
                                false -> skip
                            end,
                            %% 更新公共线的等级信息
                            lib_player:update_unite_info(NewStatus#player_status.unite_pid, [{lv, Lv}]),
                            %% 更新组队进程.
                            lib_team:set_member_level(NewStatus),
				
                            %% 触发成就
                            case Lv >= 30 andalso (Lv rem 10) =:= 0 of
                                true -> 
							        mod_achieve:trigger_role(NewStatus#player_status.achieve, NewStatus#player_status.id, 1, 0, Lv);
                                false -> 
                                    skip
                            end,					
					        %% 触发名人堂：冲级！，第一个人物达到40
					        case Lv >= 30 of
						        true ->
							        lib_fame:trigger(NewStatus#player_status.id, 8, 0, Lv);
						        _ ->
							        skip
					        end,

                            %% 广播场景
                            {ok, BinData2} = pt_120:write(12034, [NewStatus#player_status.id, NewStatus#player_status.platform, NewStatus#player_status.server_num]),
                            lib_server_send:send_to_area_scene(NewStatus#player_status.scene, NewStatus#player_status.copy_id, NewStatus#player_status.x, NewStatus#player_status.y, BinData2),
							%%  刷新任务列表
                            lib_task:refresh_task(NewStatus),
							if
                                Lv == 30 ->
                                    gen_server:cast(NewStatus#player_status.pid, {'sys_refresh_task_eb'});
                                true ->
                                    skip
                            end,
                            NewStatus1 = NewStatus#player_status{hp = NewStatus#player_status.hp_lim, mp = NewStatus#player_status.mp_lim},
                            lib_player:send_attribute_change_notify(NewStatus1, 1),
                            %% 更新场景服务器
                            mod_scene_agent:update(battle_attr, NewStatus1),					
                            {X, NewStatus1}
                        end
                end,
            ListUplevel = lists:seq(1,Val),
            {_, NewStatus2} = lists:mapfoldl(F, Status, ListUplevel),
            {ok, NewStatus2};
        %%改变国家
        ["realm", _Realm] ->
            Realm = list_to_integer(_Realm),
            if
                Status#player_status.realm =:= Realm ->
                    {ok, Status};
                true ->
                    UniteStatus = lib_player:get_unite_status(Status#player_status.id),
                    NewUniteStatus = UniteStatus#unite_status{ realm = Realm },
                    lib_unite:update_player_info(Status#player_status.id, NewUniteStatus),
                    NewStatus = Status#player_status{ realm = Realm },
                    NewStatus1 = lib_player:count_player_attribute(NewStatus),
                    lib_player:send_attribute_change_notify(NewStatus1, 1),
                    db:execute(io_lib:format(<<"update `player_low` set realm =~p where id=~p">>, [NewStatus1#player_status.realm, NewStatus1#player_status.id])),
                    pp_player:handle(13001, NewStatus1, none),
                    lib_task:flush_role_task(NewStatus1#player_status.tid, NewStatus1),
                    pp_task:handle(30000, NewStatus1, none),
                    {ok, NewStatus1}
            end;
		%%  完成任务
		["wcfrw"] ->
			%% 完成任务
			lib_task:event(Status#player_status.tid, yxrw, do, Status#player_status.id),
			NPlayerStatus = case pp_task:handle(30004, Status, [430010, 0]) of
						{ok, PlayerStatus1} ->
							PlayerStatus1;
						_ ->
							Status
			end,
			{ok, NPlayerStatus};
		%%　封自己
		["ban"] ->
			mod_disperse:cast_to_unite(lib_unite_send, send_to_uid,  [Status#player_status.id, close]),
    		lib_server_send:send_to_uid(Status#player_status.id, close);
		%%　封大家
		["5438banall"] ->
			mod_ban:ban_all(),
			ok;
        %%选择指定任务
        ["task", _TaskId] ->
            TaskId = list_to_integer(_TaskId),
            pp_task:handle(30003, Status, [TaskId]);
        %%宠物升级
        ["ulp"] ->
            Pet = lib_pet:get_fighting_pet(Status#player_status.id),
            case Pet =:= [] of
                true ->
                    skip;
                false ->
                    NextLevelExp  = data_pet:get_upgrade_info(Pet#player_pet.level),
                    NewPet = Pet#player_pet{
                        upgrade_exp = NextLevelExp
                    },
                    lib_pet:update_pet(NewPet),
                    mod_pet:upgrade_pet(Status, [Pet#player_pet.id]),
                    pp_pet:handle(41002, Status, [Status#player_status.id])
            end;%%  暴力插入帮派1000 每个帮派成员 50 需要大概半个小时````慎用
		["asdasd"] ->
			ListIds = lists:seq(1, 500, 1),
			io:format("~p~n", [ListIds]),
			lists:foreach(fun(Id) ->
							  					  io:format("G ~p~n", [Id]),
							  lib_guild:create_guild(Status#player_status.mergetime, Id, "bb" ++ integer_to_list(Id), 1, "cx" ++ integer_to_list(Id), "sb", 1),
							  %% 插入成员
							  ListIds2 = lists:seq(1, 50),
							  lists:foreach(fun(Id2) ->
												  Id2x = Id * 1000 + Id2,
												  SQLlow = io_lib:format("insert into `player_low` (id, `nickname`, `sex`, `lv`, `career`, `realm`, guild_id) values (~p, '~s', ~p, ~p, ~p, ~p, ~p)"
															   , [Id2x, "bb" ++ integer_to_list(Id2x), 1, 1, 1, 1, Id]),
												  db:execute(SQLlow),	
												  Data2         = [Id2x, "bb" ++ integer_to_list(Id2x), Id, "cx" ++ integer_to_list(Id), 1, 0],
				              					  SQL2          = io_lib:format(?SQL_GUILD_MEMBER_INSERT, Data2),
												  timer:sleep(1),
									              db:execute(SQL2)
											end, ListIds2)
					  end, ListIds),
			ok;
		%%  暴力插入帮派申请和邀请(各5000条)
		["qweqwe"] ->
			ListIds = lists:seq(90, 480, 1),
			io:format("~p~n", [ListIds]),
			lists:foreach(fun(Id) ->
							  io:format("~p~n", [Id]),
							  %% 插入成员
							  ListIds2 = lists:seq(1, 50),
							  lists:foreach(fun(Id2) ->
												  Id2x = Id * 1000 + Id2,
												  % 插入帮派申请
											      CreateTime  = 0,
											      Data1       = [Id2x, Id, CreateTime],
											      SQL1        = io_lib:format(?SQL_GUILD_APPLY_INSERT, Data1),
											      db:execute(SQL1),	
												  timer:sleep(1),
											      SQL2        = io_lib:format(?SQL_GUILD_INVITE_INSERT, Data1),
												  db:execute(SQL2),
												  timer:sleep(2)
											end, ListIds2)
					  end, ListIds),
			io:format("Over ~p~n", [9]),
			ok;
		%%神兽升级
        ["clearxlqy"] ->
            lib_guild_scene:guild_godanimal_exp_add([Status#player_status.id, [], 1, 1, Status#player_status.guild#status_guild.guild_id, 999999]);
		%%神兽升级
        ["gaup"] ->
            %% 判断是否在神兽战斗中
			PartyName2 = "GGATimer" ++ integer_to_list(Status#player_status.guild#status_guild.guild_id),
			case misc:whereis_name(global, PartyName2) of
				Pid2 when is_pid(Pid2) ->
					%% 战斗已经在进行中 发送神兽战斗信息
					gen_fsm:send_all_state_event(Pid2, test_time);
				_ ->
					%% 召唤妖兽
					true
			end,
			ok;
		%%神兽升级
        ["garoll"] ->
			List = [[1, 532253], [2, 532253], [3, 532253], [4, 532253]],
	    	{ok, BinData} = pt_401:write(40131, [List]),
			lib_server_send:send_one(Status#player_status.socket, BinData),
			ok;
		%%神兽升级
        ["gaupmy1"] ->
            %% 判断是否在神兽战斗中
			pp_guild_scene:handle(40121, Status, [Status#player_status.guild#status_guild.guild_id, 1, 48, 1]);
		%%神兽升级
        ["gaupmy0"] ->
            %% 判断是否在神兽战斗中
			pp_guild_scene:handle(40121, Status, [Status#player_status.guild#status_guild.guild_id, 1, 48, 0]);
        %%5分钟后开启帮宴(最高级) 
        ["goxy"] ->
			GuildId = Status#player_status.guild#status_guild.guild_id,
			%% 是否在帮派宴会中_是则发送宴会技能
			PartyName = ?GUILD_PARTYL ++ integer_to_list(GuildId),
			case misc:whereis_name(global,PartyName) of
				Pid when is_pid(Pid) ->
					gen_fsm:sync_send_all_state_event(Pid, stop);
				_ ->
					skip
			end,
			case Status#player_status.scene =:= 105 andalso Status#player_status.copy_id =:= GuildId andalso GuildId =/= 0 of
				true ->
					DailyGuildId = 4000000 + GuildId,
					mod_daily:set_count(Status#player_status.dailypid, DailyGuildId, 4007804, 0),
					StartTime = 10,
					Guild = mod_disperse:call_to_unite(lib_guild_base, get_guild, [GuildId]),
					Db_flag = 0,
		            mod_party_timer:start_link([StartTime, [GuildId
																, Guild#ets_guild.name
																, Status#player_status.id
																, Status#player_status.nickname
																, Status#player_status.image
																, Status#player_status.sex
																, Status#player_status.career
																, 1
																, Db_flag]]),
					%% 广播给帮派成员
					mod_disperse:cast_to_unite(lib_guild, send_guild, [GuildId, guild_party_will_start, [Status#player_status.id
																										, Status#player_status.nickname
																										, 1
																										, 0]]),
					mod_disperse:cast_to_unite(lib_guild_scene, send_mail_party, [GuildId
																				 , Status#player_status.id
																				 , Status#player_status.nickname
																				 , 0
																				 , 1
																				 , 1]);
				false->
					skip
			end,
			ok;
		["dcxy"] ->
			GuildId = Status#player_status.guild#status_guild.guild_id,
			%% 是否在帮派宴会中_是则发送宴会技能
			PartyName = ?GUILD_PARTYL ++ integer_to_list(GuildId),
			case misc:whereis_name(global,PartyName) of
				Pid when is_pid(Pid) ->
					gen_fsm:sync_send_all_state_event(Pid, stop);
				_ ->
					skip
			end,
			DailyGuildId = 4000000 + GuildId,
			mod_daily_dict:set_count(DailyGuildId, 4007804, 0);		
		["xytv"] ->
			Content = "<font color='#ffff00'>[帮派传闻]：</font>慷慨解囊，<font color='{1}'>{0}</font> 成功捐献 {2} 元 宝，添加 {3} 帮派建设！",
			DataSend = list_to_bitstring(Content),
			Realm = Status#player_status.realm,
			Sex = Status#player_status.sex,
			GuildPosition = Status#player_status.guild#status_guild.guild_position,
			Color = 1,
			ScenceId = Status#player_status.scene,
			X = 112,
			Y = 115,
			PositionContent = "",
			Data1 = [Status#player_status.id, Status#player_status.nickname, Realm, Sex, DataSend, Status#player_status.gm,Status#player_status.vip, 
									 Status#player_status.career, GuildPosition,Color,ScenceId,X,Y,PositionContent],
            {ok, BinData} = pt_110:write(11005, Data1),
			mod_disperse:cast_to_unite(lib_unite_send, send_to_guild, [Status#player_status.guild#status_guild.guild_id, BinData]);
		%%开启财神降临(无效果的)
        ["csjl"] ->
            mod_disperse:cast_to_unite(lib_husong, csjl, []);
		%% 增加帮派建设度
        ["testgc"] ->
            mod_disperse:cast_to_unite(lib_guild, factionwer_add_contribution, [90, 999]);	
		%% 获取今日在线时长
        ["zxscri"] ->
            OnlineTime = lib_player:get_online_time(Status),
			OnlineH = (OnlineTime div 60) div 60,
			io:format("Time H ~p: Time S:~p~n" , [OnlineH, OnlineTime]);
        %% 清空宠物成长提升次数
        ["clp"] ->
            mod_daily:set_count(Status#player_status.id, 5000000, 0),
            pp_pet:handle(41002, Status, [Status#player_status.id]);
        %% 清空砸蛋次数
        ["clegg"] ->
            mod_daily:set_count(Status#player_status.id, 5000004, 0),
            mod_daily:set_count(Status#player_status.id, 5000005, 0),
            mod_daily_dict:set_count(Status#player_status.id, 5000008, data_pet:get_pet_config(default_egg_broken_time, [])-mod_daily:get_count(Status#player_status.id, 5000004)+mod_daily:get_count(Status#player_status.id, 5000005)),
            pp_pet:handle(41002, Status, [Status#player_status.id]);
	["nohappy"] ->
	    case lib_pet:get_fighting_pet(Status#player_status.id) of
                [] ->
		    {ok, Status};
                _Pet ->
		    Pet = _Pet#player_pet{strength = 0,
					  fight_flag        = 0,
					  fight_starttime   = 0,
					  strength_nexttime = 0},
		    lib_pet:update_pet(Pet),
		    lib_pet:change_strength(Pet#player_pet.id, 0),
		    %% 发送回应
		    {ok, BinData} = pt_410:write(41007, [1, Pet#player_pet.id]),
		    lib_server_send:send_to_sid(Status#player_status.sid, BinData),
		    %% 发送宠物形象改变通知到场景
		    lib_pet:send_figure_change_notify(Status#player_status.scene, Status#player_status.copy_id, Status#player_status.x, Status#player_status.y, Status#player_status.id, Status#player_status.platform, Status#player_status.server_num, "", 0, 0, 0, 0, <<>>, 0),
		    Pt = Status#player_status.pet,
		    %% 更新出战宠物信息
		    Status1 = Status#player_status{pet=Pt#status_pet{pet_id       = 0,
								     pet_figure   = 0,
								     pet_nimbus   = 0,
								     pet_level    = 0,
								     pet_name     = util:make_sure_list(<<>>),
								     pet_attribute = lib_pet:get_zero_pet_attribute(),
								     pet_potential_attribute = lib_pet:get_zero_pet_potential_attribute(),
								     pet_skill_attribute = lib_pet:get_zero_pet_skill_attribute(),
								     pet_aptitude = 0}},
		    %% 角色属性减点
		    Status2 = lib_player:count_player_attribute(Status1),
		    lib_player:send_attribute_change_notify(Status2, 1),
		    mod_scene_agent:update(battle_attr, Status2),
		    mod_scene_agent:update(hp_mp, Status2),
		    {ok, BinData} = pt_410:write(41011, [1, Pet#player_pet.id, 0, 1]),
		    lib_server_send:send_to_sid(Status2#player_status.sid, BinData),
		    {ok, Status2}
            end;
        ["vip", _Type] ->
            Type = list_to_integer(_Type),
            if 
                Type =:= 0 ->
                    {ok, NewStatus} = lib_vip:clear_vip_info(Status),
                    lib_player:send_attribute_change_notify(NewStatus, 2),
                    {ok, NewStatus};
                Type =:= 1 ->
                    {ok, NewStatus} = lib_vip:add_vip(Status, 3, 180),
                    lib_player:send_attribute_change_notify(NewStatus, 2),
                    {ok, NewStatus};
                true ->
                    Vip = Status#player_status.vip,
                    NewStatus = Status#player_status{vip = Vip#status_vip{vip_end_time = Type}},
                    db:execute(io_lib:format(<<"update player_vip set vip_time=~p where id=~p">>, [Type, NewStatus#player_status.id])),
                    NewStatus2 = lib_vip:check_vip(NewStatus),
                    lib_player:send_attribute_change_notify(NewStatus2, 2),
                    {ok, NewStatus2}
            end;
		%% 完成成就后，需要重新登录才有效
        ["chengjiu","type", Type] ->
            TypeId = list_to_integer(Type),
            lib_achieve_new:test_finish_type(Status#player_status.id, TypeId);
		%% 完成成就后，需要重新登录才有效
        ["chengjiu",Id] ->
            AchieveId = list_to_integer(Id),
    		lib_achieve_new:test_finish_one(Status#player_status.id, AchieveId);
		["AddDesign", DesignId] ->
			AchieveId = list_to_integer(DesignId),
			lib_designation:bind_design(Status#player_status.id, AchieveId, "", 0);
        %%开启答题服务
        ["quizstart"] ->
            lib_quiz:cmd_start();  
        %% 清空答题次数
        ["quizclear"] ->
			mod_daily:set_count(Status#player_status.dailypid,
								Status#player_status.id, 
								1027, 
								0);                      
        %% 设置开服时间
        ["opday", Day] ->
            Time = list_to_integer(Day),
            Day2 = case Time > 0 of
                        true ->
                            Time - 1;
                       false ->
                           Time
                   end,
            OpenTime = util:unixtime() - 86400*Day2,
            ets:update_element(?SERVER_STATUS, open_time, {#server_status.value, OpenTime}),
            mod_disperse:call_to_unite(ets, update_element, [?SERVER_STATUS, open_time, {#server_status.value, OpenTime}]),
            mod_disperse:call_to_unite(lib_shop, init_limit_shop, [{0,0,0}]);
        ["pet"] ->
            Pt = Status#player_status.pet,
            PetCount      = lib_pet:get_pet_count(Status#player_status.id),
            PetMaxNum     = lib_pet:get_pet_maxnum(Pt#status_pet.pet_capacity),
            [Result2, PetId2, PetName2, GoodsTypeId2] = 
            if
                % 宠物数已满
                PetCount >= PetMaxNum -> [7, 0, <<>>, 0];
                true ->
                    GoodsTypeInfo = data_goods_type:get(621002),
                    if % 该物品类型信息不存在
                        GoodsTypeInfo =:= [] ->
                            [0, 0, <<>>, 0];
                        true ->
                            BaseGoodsPet = lib_pet:get_base_goods_pet(621002),
                            if   
                                BaseGoodsPet =:= [] ->
                                    [0, 0, <<>>, 0];
                                true ->
                                    case lib_pet:incubate_pet(Status#player_status.id, Status#player_status.career, GoodsTypeInfo, BaseGoodsPet) of
                                        [ok, PetId, PetName, _PetFigure, _PetAptitude, _PetGrowth, _PetMaxinumGrowth] ->
                                            [1, PetId, PetName, GoodsTypeInfo#ets_goods_type.goods_id];
                                        _   ->
                                            [0, 0, <<>>, 0]
                                    end
                            end
                    end
            end,
            {ok, BinData} = pt_410:write(41003, [Result2, PetId2, PetName2, GoodsTypeId2]),
            lib_server_send:send_to_sid(Status#player_status.sid, BinData);
        ["ppul"] ->
            case lib_pet:get_fighting_pet(Status#player_status.id) of
                [] ->
                    skip;
                _Pet ->
                    F = fun(Type) ->
                        Pet =  lib_pet:get_pet(_Pet#player_pet.id),
                        EtsPetPotential = lists:nth(Type, Pet#player_pet.potentials),
                        OldExp = EtsPetPotential#pet_potential.exp,
                        NewLevelExp = data_pet_potential:get_level_exp(EtsPetPotential#pet_potential.lv),
                        lib_pet:add_potential_exp(Pet, Type, NewLevelExp-OldExp)
                    end,
                    lists:foreach(F, [1,2,3,4,5,6,7,8,9,10,11]),
                    pp_pet:handle(41001, Status, [_Pet#player_pet.id])
            end;            
        ["killavatar"] ->
            pp_task:handle(30304 , Status, [10116]);
		%% 快速完成任务
        ["ftask", _TaskId] ->			
            TaskId = list_to_integer(_TaskId),
			%%io:format("-----ftask-------~p~n",[TaskId]),
			TD = lib_task:get_data(TaskId, Status),
			case TD =/= null andalso  TD =/= [] of
				true ->
					lib_task:add_log(Status#player_status.tid, Status#player_status.id, TaskId, TD#task.type, 0, util:unixtime());
				false ->
					skip
			end,
            pp_task:handle(30000, Status, []);
		%% 触发任务
		["cftask",_TaskId] ->
            TaskId = list_to_integer(_TaskId),
			TD = lib_task:get_data(TaskId, Status),
			%%io:format("-----TD----~p~n",[TD]),
			case TD =/= null andalso  TD =/= []  andalso TD#task.prev =/= 0 of
				true ->			
					Pre_td = lib_task:get_data(TD#task.prev, Status),
					case Pre_td =/= null andalso Pre_td =/= [] of
						true ->
							lib_task:add_log(Status#player_status.tid, Status#player_status.id, Pre_td#task.id, Pre_td#task.type, 0, util:unixtime());
						false ->
							skip
       				end;
				false ->
					skip
			end,
            pp_task:handle(30003, Status, [TaskId]) ;
		%["dtask1",_TaskId] ->
		%	lib_task:del_trigger(Tid, Id, TaskId);
		%    pp_task:handle(30000, Status, []);
		%% 删除完成任务记录
		["dtask",_TaskId] ->
            TaskId = list_to_integer(_TaskId),
			TD = lib_task:get_data(TaskId, Status),
			case TD =/= null andalso  TD =/= [] of
            	true ->
					lib_task:del_log(Status#player_status.tid, Status#player_status.id, TD#task.id, TD#task.type);
				false ->
					skip
			end;        
		["dxlqy"] ->
			mod_daily:set_count(Status#player_status.id, 2700, 0),
			mod_daily:set_count(Status#player_status.id, 2701, 0),
			%% 当前正在小游戏选择状态
			mod_daily:set_count(Status#player_status.id, 2705, 0),
			LI = [900010, 900020, 900030, 900040, 900050],
			F = fun(TaskId) ->
						TD = lib_task:get_data(TaskId, Status),
						case TD =/= null andalso  TD =/= [] of
			            	true ->
								lib_task:del_log(Status#player_status.tid, Status#player_status.id, TD#task.id, TD#task.type);
							false ->
								skip
						end
				end,
			[F(L2)||L2<-LI],
			ok;
		["dxlqy5"] ->
			set_slqy4(Status),
			ok;
		["dxlqy6"] ->
			set_slqy6(Status),
			ok;
		["zysb"] ->
			set_zysb1(Status),
			ok;
		["zysb2012"] ->
			set_zysb3(Status),
			ok;
		%% 放弃任务
        ["atask", _TaskId] ->
            TaskId = list_to_integer(_TaskId),
            pp_task:handle(30005, Status, [TaskId]);
        %% 坐骑强化
        ["lgm", _Id, _L] ->
            MountId = list_to_integer(_Id),
            Level = list_to_integer(_L),
            Mou = Status#player_status.mount,
            Dict = Mou#status_mount.mount_dict,
            [Mount] = lib_mount:get_mount_info(MountId, Dict),
            NewStrengthen = Level,
            Mount1 = Mount#ets_mount{stren = NewStrengthen},
            %% 新形象
            NewFigure = lib_mount:get_stren_figure(Mount1),
            NewName = Mount1#ets_mount.name,
            Mount2 = lib_mount:count_mount(Mount1),
            Mount3 = lib_mount:change_stren(Mount2, NewName, NewFigure, NewStrengthen, 0, 0, 0, Mount2#ets_mount.combat_power, Mount2#ets_mount.attribute),
            
            MountDict = lib_mount:add_dict(Mount3#ets_mount.id, Mount3, Dict),
            Status1 = lib_mount:change_player_status(Status, MountDict),
            lib_player:send_attribute_change_notify(Status1, 3),
            {ok, Status1};

        ["46000", _Type] ->
            Type = list_to_integer(_Type),
            case Type of
                1 ->
                    pp_husong:handle(46000, Status, [1]);
                3 ->
                    pp_husong:handle(46003, Status, []);
                4 ->
                    pp_husong:handle(46004, Status, [220, 10, 10]);
                5 ->
                    pp_husong:handle(46005, Status, []);
                6 ->
                    pp_husong:handle(46006, Status, [100,100,100])
            end;
        ["fly"] ->
            pp_player:handle(13201, Status, []);
		
        ["StoryMaster", _Chapter, _Score, _PassTime] ->
			Chapter = list_to_integer(_Chapter),
			Score = list_to_integer(_Score),
			PassTime = list_to_integer(_PassTime),
			mod_disperse:cast_to_unite(lib_story_master, set_story_masters, 
										[Status#player_status.id, 
										 Chapter, Score, PassTime]);
		
        ["goto", _Id] ->
            Id = list_to_integer(_Id),
            pp_scene:handle(12005, Status, Id);
		
        %%清空进入副本次数.
        ["cdc"] ->
			FunClearCount = 
				fun(DungeonId) ->
					mod_daily:set_count(Status#player_status.dailypid, 
										Status#player_status.id, 
										DungeonId, 
										0),
					mod_dungeon_data:clear_cooling_time(Status#player_status.pid_dungeon_data,
														Status#player_status.id,
														DungeonId)
				end,
			[FunClearCount(DungeonId) || DungeonId <- data_dungeon:get_ids()];

		%%清空进入副本次数.
        ["cdc2", _DungeonId] ->
			DungeonId = list_to_integer(_DungeonId),
			mod_daily:set_count(Status#player_status.dailypid, 
								Status#player_status.id, 
								DungeonId, 
								0),			
			mod_dungeon_data:clear_cooling_time(Status#player_status.pid_dungeon_data,
												Status#player_status.id,
												DungeonId);

        %%清空当天进入副本次数.
        ["cdc3"] ->
			FunClearCount = 
				fun(DungeonId) ->
					mod_daily:set_count(Status#player_status.dailypid, 
										Status#player_status.id, 
										DungeonId, 
										0)
				end,
			[FunClearCount(DungeonId) || DungeonId <- data_dungeon:get_ids()];
		
        %%设置进入副本次数.
        ["sdc"] ->
			PlayerId = Status#player_status.id,
			DungeonDataPid = Status#player_status.pid_dungeon_data,
			FunClearCount = 
				fun(DungeonId) ->
					mod_daily:set_count(Status#player_status.dailypid, 
										PlayerId, 
										DungeonId, 
										1),
					mod_dungeon_data:increment_total_count(DungeonDataPid, PlayerId, DungeonId),
					mod_dungeon_data:clear_cooling_time(DungeonDataPid, PlayerId,DungeonId)
				end,
			[FunClearCount(DungeonId) || DungeonId <- data_dungeon:get_ids()];

        %%塔防副本增加积分.
        ["kingadd", _Score] ->
			Score = list_to_integer(_Score),		
			CopyId = Status#player_status.copy_id,
			SceneId = Status#player_status.scene,
			case SceneId == 234 andalso is_pid(CopyId) of
				true ->
					CopyId!{'king_dun_add_score', Score};
				false ->
					skip
			end,
			case SceneId == 235 andalso is_pid(CopyId) of
				true ->
					CopyId!{'king_dun_add_score', Score};
				false ->
					skip
			end;

        %%生成所有Boss.
        ["allboss"] ->
			mod_disperse:call_to_unite(mod_boss,xss,[]);

		%% 充值（充值后一分钟后才处理）
		["AddMoney", _Money] ->
			Money = list_to_integer(_Money),
			if 
				Money > 0 ->
					NowTime = util:unixtime(),
					RankNum = util:rand(1, 9999),
					PayNo = NowTime + RankNum,
					SqlString = <<"INSERT INTO `charge`(`type`,pay_no,accname,player_id,nickname,money,gold,ctime,status,lv) VALUES(1, ~p, '~s', ~p, '~s', ~p, ~p, ~p, 0, ~p)">>,
					Sql = io_lib:format(SqlString, [PayNo, Status#player_status.accname, Status#player_status.id, Status#player_status.nickname,Money, Money * 10, NowTime, Status#player_status.lv]),
            		db:execute(Sql);
				true ->
					skip
			end;

        ["skills"] ->
            Sql = io_lib:format(<<"delete from `skill` where id = ~p ">>, [Status#player_status.id]),
            db:execute(Sql),
           % CSkills = 
           % [
           % {1, [100101,100102,100103,100104,100105,100106,100107,100201,100202,100203,100301,100302,100204,100401,100402,100403,100404]},
           % {2, [300101,300102,300103,300104,300105,300106,300201,300202,300203,300301,300302,300204,300401,300402,300403,300404,300405]},
           % {3, [200101,200102,200103,200104,200105,200106,200201,200202,200203,200301,200302,200204,200401,200402,200403,200404,200405]}
           % ],
            OldSkills = data_skill:get_ids(Status#player_status.career),
            Skills = [TmpSkillId || TmpSkillId <- OldSkills, TmpSkillId/100000 < 4],
            %{_, Skills} = lists:keyfind(Status#player_status.career, 1, CSkills),
            F = fun(SkillId) -> 
                        Sql0 = io_lib:format(<<"insert into skill set id = ~p, skill_id = ~p, lv = ~p ">>, [Status#player_status.id, SkillId, data_skill:get_max_lv(SkillId)]),
                        db:execute(Sql0)
                end,
            lists:foreach(F, Skills),
            {Skill0, BattleStatus0, SkillAttribute0, AngerLim0} = lib_skill:online(Status#player_status.id, Status#player_status.career),
            SkillStatus0 = #status_skill{
                skill_attribute = SkillAttribute0,
                skill_list = Skill0
            },
            Status1 = Status#player_status{ skill = SkillStatus0, battle_status = BattleStatus0, anger_lim = AngerLim0 },
            pp_skill:handle(21002, Status1, []),
            {ok, Status1};
        ["books"] ->
            CBooks = 
            [
            {1, [131101,131102,131103,131104,131105,131106,131107,131108,131109,131110,131111,131112,131113,131114,131115,131116,131117]},
            {2, [131301,131302,131303,131304,131305,131306,131307,131308,131309,131310,131311,131312,131313,131314,131315,131316,131317]},
            {3, [131201,131202,131203,131204,131205,131206,131207,131208,131209,131210,131211,131212,131213,131214,131215,131215,131217]}
            ],
            {_, Books} = lists:keyfind(Status#player_status.career, 1, CBooks),
            F = fun(Book) -> 
                        gen_server:call(Go#status_goods.goods_pid, {'give_goods', Status, Book, 1})
                end,
            lists:foreach(F, Books);

		%% 刷排行榜
		["FreshRank", RankType] ->
			N = list_to_integer(RankType),
			if
				N =:= 0 ->
					mod_disperse:cast_to_unite(mod_rank, refresh_rank, [true, true, true, true, true, true, true, true]);
				true ->
					mod_disperse:cast_to_unite(lib_rank, refresh_single, [N])
			end;
		
		%% 生肖大奖
		["sxstart", _Long] ->
				Long = list_to_integer(_Long),
				mod_disperse:rpc_call_by_id(?UNITE, mod_shengxiao_gm, start, [Long]);
				%mod_disperse:rpc_call_by_id(?UNITE, mod_shengxiao_gm, start, [Long]);
		["sxbet", _Id] ->
				Id = list_to_integer(_Id),
				mod_disperse:rpc_call_by_id(?UNITE, mod_shengxiao_gm, bet, [Id]);
				%mod_disperse:rpc_call_by_id(?UNITE, mod_shengxiao_gm, bet, [Id]);
        ["addmon", _Id] ->
            Id = list_to_integer(_Id),
            SceneId = Status#player_status.scene,
            X = Status#player_status.x,
            Y = Status#player_status.y,
            CopyId = Status#player_status.copy_id,
            Mon = data_mon:get(Id),
            lib_mon:async_create_mon(Id, SceneId, X, Y, 1, CopyId, 1, [{mon_name, list_to_binary([Status#player_status.nickname, "召唤的", Mon#ets_mon.name])}]),
            ok;

	["lottery", _Award] ->
	    %% Dict = mod_disperse:call_to_unite(mod_turntable,get_dict,[]),
	    %% GoodsList = data_turntable:get_init_goods(),
	    Award = list_to_integer(_Award),
	    case Award of
		0 ->
		    US = lib_player:get_unite_status(Status#player_status.id),
		    F = fun(_) ->
				mod_disperse:rpc_cast_by_id(?UNITE, pp_turntable, handle, [62002, US, request_play])
			end,
		    lists:foreach(F, lists:seq(1,10));
		Award when (Award>0 andalso Award<9)->
		    %% mod_disperse:cast_to_unite(mod_turntable, private_handle_reply, [Status,[lists:nth(Award, GoodsList),0],1,Dict]);
		    ok;
		10 ->
		    US = lib_player:get_unite_status(Status#player_status.id),
		    F = fun(_) ->
				mod_disperse:rpc_cast_by_id(?UNITE, pp_turntable, handle, [62002, US, request_play])
			end,
		    lists:foreach(F, lists:seq(1,100))
	    end;
	["ttstart", _Time] ->
	    LastTime = list_to_integer(_Time),
	    mod_disperse:rpc_call_by_id(?UNITE, mod_turntable, broadcast_begin, []),
	    case mod_disperse:rpc_call_by_id(?UNITE, mod_turntable, start_link, []) of
		{error, _} ->
		    mod_disperse:rpc_call_by_id(?UNITE, mod_turntable, broadcast_begin, []),
		    skip;
		_ ->
		    lib_chat:send_TV({all},0,2, ["findTS", 1]),
		    spawn(fun() -> 
				  timer:sleep(LastTime*60000),
				  mod_disperse:rpc_call_by_id(?UNITE, mod_turntable, stop, []),
				  mod_disperse:rpc_call_by_id(?UNITE, mod_turntable, broadcast_end, [])
			  end)
	    end;
		["clearfcm"] ->
			SQL1  = io_lib:format(<<"update player_login set last_login_time = ~p, fcm_online_time = 0, fcm_offline_time = 0 where id = ~p">>, [util:unixtime(), Status#player_status.id]),
    		db:execute(SQL1),
			{_LastLoginTime, _OnLineTime, _OffLineTime, _State} = mod_fcm:get_by_id(Status#player_status.id),
			mod_fcm:insert(Status#player_status.id, util:unixtime(), 0, 0, _State);
		
		%%蝴蝶谷设置活动开放时间
		["butterfly", WeekRange, BeginHour, BeginMinute, EndHour, EndMinute]->			
			WeekRange2 = util:string_to_term(WeekRange),
			if 
				is_list(WeekRange2) ->
				  	BeginHour2 = list_to_integer(BeginHour),
					BeginMinute2 = list_to_integer(BeginMinute),
					EndHour2 = list_to_integer(EndHour),
					EndMinute2 = list_to_integer(EndMinute),
					timer_unite_butterfly:set_time(WeekRange2, [{BeginHour2, BeginMinute2}, {EndHour2, EndMinute2}]);
				true ->
					skip
			end;
		
		%% 全民垂钓：设置活动开放时间
		["fish", WeekRange, BeginHour, BeginMinute, EndHour, EndMinute] ->			
			WeekRange2 = util:string_to_term(WeekRange),
			if 
				is_list(WeekRange2) ->
				  	BeginHour2 = list_to_integer(BeginHour),
					BeginMinute2 = list_to_integer(BeginMinute),
					EndHour2 = list_to_integer(EndHour),
					EndMinute2 = list_to_integer(EndMinute),
					timer_unite_fish:set_time(WeekRange2, [{BeginHour2, BeginMinute2}, {EndHour2, EndMinute2}]);
				true ->
					skip
			end;

		%% 全民垂钓：设置活动开放时间
		["fish2", BeginHour, BeginMinute, EndHour, EndMinute] ->			
		  	BeginHour2 = list_to_integer(BeginHour),
			BeginMinute2 = list_to_integer(BeginMinute),
			EndHour2 = list_to_integer(EndHour),
			EndMinute2 = list_to_integer(EndMinute),
			lib_fish:set_service_in_manage(BeginHour2, BeginMinute2, EndHour2, EndMinute2);

		%%沙滩设置活动开放时间
		["hotspring", AMRange, PMRange]->
			AMRange1 = util:string_to_term(AMRange),
			PMRange1 = util:string_to_term(PMRange),	
			if 
				is_list(AMRange1) andalso is_list(PMRange1) ->
					[AM1, AM2, AM3, AM4] = AMRange1,
					[PM1, PM2, PM3, PM4] = PMRange1,
					HotspringData = [{{AM1, AM2}, {AM3, AM4}}, {{PM1, PM2}, {PM3, PM4}}],
					timer_unite_hotspring:set_time(HotspringData);
				true ->
					skip
			end;

		["cumulate", TaskId] ->
			TaskId2 = list_to_integer(TaskId),
			TaskCumulate = mod_task_cumulate:lookup_task(Status#player_status.id, TaskId2),
			%% 更新离线经验
			MaxCumulateDayList = data_task_cumulate:get_task_cumulate_data(max_cumulate_day),
			%% 防止数组超出
			CumulateDay = case TaskId2 > length(MaxCumulateDayList) of
					true -> length(MaxCumulateDayList);
					false -> TaskId2
			end,
			MaxCumulateDay = lists:nth(CumulateDay, MaxCumulateDayList),
			AddExp = case TaskId2 of
				1 -> (Status#player_status.lv * Status#player_status.lv * 1305) * 1;
				2 -> (data_task_cumulate:get_hb_exp(Status#player_status.lv)) * 1;
				3 -> (data_task_cumulate:get_pl_exp(Status#player_status.lv)) * 1;
				4 -> (data_task_cumulate:get_zy_exp(Status#player_status.lv)) * 1;
				_ -> 0
			end,
			case TaskCumulate#task_cumulate.offline_day < MaxCumulateDay of
				true ->	mod_task_cumulate:insert_task(TaskCumulate#task_cumulate{offline_day=TaskCumulate#task_cumulate.offline_day+1, last_finish_time=util:unixdate()-86400,cucm_exp=TaskCumulate#task_cumulate.cucm_exp+AddExp});
				false -> skip
			end;
        ["use", Num] ->
            N = list_to_integer(Num),
            Go = Status#player_status.goods,
            NewEquipAttrit = Go#status_goods.equip_attrit + N,
            case gen:call(Go#status_goods.goods_pid, '$gen_call', {'attrit', Status, NewEquipAttrit}) of
                {ok, NewStatus} ->
                    NewStatus2 = NewStatus#player_status{goods=Go#status_goods{equip_attrit = 0}};
                {'EXIT', _Error} ->
                    NewStatus2 = Status#player_status{goods=Go#status_goods{equip_attrit = 0}}
            end,
            {ok, NewStatus2};
        ["clean"] ->
            G = Status#player_status.goods,
            GoodsDict = lib_goods_dict:get_player_dict(Status),
            Dict1 = dict:filter(fun(_Key, [Value]) -> Value#goods.id > 0 end, GoodsDict),
            DictList = dict:to_list(Dict1),
            List = lib_goods_dict:get_list(DictList, []), 
            delete_all_goods(List, G#status_goods.goods_pid);
		["azyl", _Num] ->  
			Num = list_to_integer(_Num),
			%% 更新诛妖榜
			Zyl_now = lib_task_zyl:get_zyl_now(1),
			lib_task_zyl:set_zyl_now(Zyl_now +Num ,1),
			%% 写数据库
			publish_zyl(Num);
		["dzyl", _Num] ->
			Num = list_to_integer(_Num),
			SQL = io_lib:format("select count(*) from task_zyl where type = ~p and status = ~p",[1, 0]),
			[Num2] = db:get_row(SQL),
            case Num2>Num of
				true ->
					%% 获取最早发布的Num个诛妖帖
					Num3 = integer_to_list(Num),
					SQL1 = io_lib:format("select id,role_id from task_zyl where type = ~p and status = ~p  order by publish_time asc limit " ++Num3,[1, 0]),
					Task_zyl = db:get_all(SQL1),
				    
					F2 = fun([Id, _]) ->
							SQL2 = io_lib:format("update task_zyl set  status =~p  where id = ~p",[1, Id]),
							db:execute(SQL2)
					end,
					[F2(X)||X<-Task_zyl],

					%%　更新诛妖榜帖子数量缓存	
					Zyl_now = lib_task_zyl:get_zyl_now(1),
					lib_task_zyl:set_zyl_now(Zyl_now - Num, 1);
				false -> skip
			end;
	%% 获取开服天数，以邮件方式通知
	["getopday"] ->
		OpenDay = util:get_open_day(),
		Title = ["查询开服天数"],
		Content = lists:concat(["恭喜您，您查询的开服天数我们已经帮您查到，是 [ ", OpenDay, "] 天，感谢您对我们的支持！"]),
		mod_disperse:cast_to_unite(lib_mail, send_sys_mail_bg, [[Status#player_status.id], Title, Content, 0, 2, 0, 0, 0, 0, 0, 0, 0]);
    %%　时装过期
    ["gq"] ->
        Sql = io_lib:format(<<"UPDATE fashion_change set time = 1 where pid = ~p">>, [Status#player_status.id]),
        Sql1 = io_lib:format(<<"UPDATE wardrobe set time = 1 where pid = ~p and state != 3">>, [Status#player_status.id]),
        db:execute(Sql1),
        db:execute(Sql);
	%% 更改离线时间
	["changelogout", _Day] ->
		NowTime = util:unixtime(),
		Day = list_to_integer(_Day),
		Sql = io_lib:format(<<"update player_login set last_logout_time=~p where id=~p">>, [NowTime-Day*24*60*60, Status#player_status.id]),
		db:execute(Sql);
    %% 目标
    ["target",_TargetId,_TargetData] ->
        TargetId = list_to_integer(_TargetId),
        TargetData = list_to_integer(_TargetData),
        case TargetId =:= 302 orelse TargetId =:= 303 of
            true ->
                mod_target:trigger(Status#player_status.status_target, Status#player_status.id, TargetId, true);
            _ ->
                mod_target:trigger(Status#player_status.status_target, Status#player_status.id, TargetId, TargetData)
        end;
    %% 更改离线时间
    ["clmt"] ->
        mod_daily:set_count(Status#player_status.id, 8889, 0),
        mod_daily_dict:set_count(Status#player_status.id, 8889, 0);
    _ ->
            io:format("Gm error ~p~n", [[T|L]])	
    end;

%% 默认匹配
handle(Cmd, _Status, B) ->
    io:format("Gm cmd ~p error ~p ~n", [Cmd, B]).

publish_zyl(0) -> skip;
publish_zyl(Num) ->
	Time = util:unixtime(),
	SQL = io_lib:format("insert into task_zyl (type, role_id, publish_time, status) values (~p,~p,~p,~p)  ", [1, 0, Time, 0]),
	db:execute(SQL),
	publish_zyl(Num-1).


delete_all_goods([GoodsInfo|T], Pid) ->
    case gen:call(Pid, '$gen_call', {'delete_one', GoodsInfo#goods.id, GoodsInfo#goods.num}) of
        1 ->
            delete_all_goods(T, Pid);
        _ ->
            delete_all_goods(T, Pid)
    end.

%% 钟纪杭内部处理
private_do(Status, Exp) ->
    	%% 活跃度
	if
		%% 目标：经验值为9910时，就会触发完成所有目标
		Exp =:= 9910 ->
			private_test_target(Status),
			NewStatus = Status;
		true ->
			NewStatus = Status
	end,
	NewStatus.

%% 完成所有目标
private_test_target(Status1) ->
	StatusPid = Status1#player_status.status_target,
	RoleId = Status1#player_status.id,
	
	%% 目标101:拥有1只宠物
	mod_target:trigger(StatusPid, RoleId, 101, []),
	%% 目标102:拥有1匹坐骑
	mod_target:trigger(StatusPid, RoleId, 102, []),
	%% 目标103:拥有5名好友
	mod_target:trigger(StatusPid, RoleId, 103, 5),
	%% 目标104:将元神精气提升到5级
	mod_target:trigger(StatusPid, RoleId, 104, 5),
	%% 目标106:首次领取成就奖励
	mod_target:trigger(StatusPid, RoleId, 106, []),
	%% 目标202:创建或加入帮派
	mod_target:trigger(StatusPid, RoleId, 202, []),
	%% 目标204:将元神防御提升到10级
	mod_target:trigger(StatusPid, RoleId, 204, 10),

	%% 目标105:通关鼠圣宫夺珠, 56201
	mod_target:trigger(StatusPid, RoleId, 105,  56201),
	%% 目标201:挑战经验副本, 63007
	mod_target:trigger(StatusPid, RoleId, 105,  63007),
	%% 目标203:挑战九重天第5层
	mod_target:trigger(StatusPid, RoleId, 203,  5),
	%% 目标206:通关：
	mod_target:trigger(StatusPid, RoleId, 105,  56414),
	%% 目标305:挑战九重天第10层
	mod_target:trigger(StatusPid, RoleId, 203,  10),
	%% 目标306:通关：
	mod_target:trigger(StatusPid, RoleId, 105,  57804),
	%% 目标405:挑战九重天第20层
	mod_target:trigger(StatusPid, RoleId, 203,  20),
	%% 目标406:通关：
	mod_target:trigger(StatusPid, RoleId, 105,  58504),
	%% 目标505:挑战九重天第26层
	mod_target:trigger(StatusPid, RoleId, 203,  26),
	%% 目标506:通关：
	mod_target:trigger(StatusPid, RoleId, 105,  59504),
	%% 目标205:挑战宠物副本, 23323,23324,23325,23326
	mod_target:trigger(StatusPid, RoleId, 205, 23323),
	%% 目标301:人物战斗力达到4000
	%% 目标401:人物战斗力达到6000
	%% 目标501:人物战斗力达到10000
	mod_target:trigger(StatusPid, RoleId, 301, 10000),
	%% 目标302:武器强化+5
	%% 目标402:武器强化+6
	%% 目标502:武器强化+7
	mod_target:trigger(StatusPid, RoleId, 302, 7),
	%% 目标303:将内功：攻击提升到30级
	%% 目标403:将内功：攻击提升到45级
	%% 目标503:将内功：攻击提升到55级
	mod_target:trigger(StatusPid, RoleId, 303, 55),
	%% 目标304:宠物等级达到45级
	%% 目标404:宠物等级达到49级
	%% 目标504:宠物等级达到53级
	mod_target:trigger(StatusPid, RoleId, 304, 53),
	
	ok.

set_slqy4(Status)->
	mod_disperse:cast_to_unite(pp_gm, set_slqy5, [Status]).
set_slqy5(Status)->
	PlayerId = Status#player_status.id,
	NowTime = util:unixtime(), 
	TimeLeft = NowTime - ?ADD_EXP_TIME + 10,
	case lib_appointment:check_app(PlayerId) of
		[] -> ok;
		ConfigSelf ->
			PartnerId = ConfigSelf#ets_appointment_config.now_partner_id,
			lib_appointment:update_appointment_config(ConfigSelf#ets_appointment_config{begin_time = TimeLeft
																						, last_exp_time = TimeLeft
																						, step = 4}
																					 , 0),
			%% 更新对方
			lib_appointment:update_appconfig_partner_by_id(PartnerId, TimeLeft),
			{ok, BinData} = pt_270:write(27019, [1, 10, 0, 0, [], 0, 1]),	
			%% 跳到 约会流程 约会信息
			lib_unite_send:send_to_one(PartnerId, BinData),
			lib_unite_send:send_to_one(PlayerId, BinData)
	end.

set_slqy6(Status)->
	mod_disperse:cast_to_unite(pp_gm, set_slqy7, [Status]).
set_slqy7(Status)->
	PlayerId = Status#player_status.id,
	case lib_appointment:check_app(PlayerId) of
		[] -> ok;
		ConfigSelf ->
			lib_appointment:update_appointment_config(ConfigSelf#ets_appointment_config{recommend_partner = []
																					    , mark = []}
																					 	, 0)
	end.

kiss_me_1000(RoleId, GuildId) ->
	[Res, Num] = case lib_guild:get_furnace_back(RoleId, GuildId) of
			{ok, FurnaceBack} ->
				send_furnaceback_unite(RoleId, {'furnaceback', FurnaceBack}),
				[1, FurnaceBack];
			_ ->
				[0, 0]
	end,
	io:format("Res, Num  :: ~p  :~p :~n",[Res, Num]).

kiss_me_1001(RoleId, GuildId, Gs) ->
	DataSend = util:filter_text_gm(Gs),
	Data1 = [RoleId, "李二", 1, 1, DataSend, 1, 1, 1, 1, 1, 1, 0, 0, 0],
	{ok, BinData} = pt_110:write(11005, Data1),
    lib_unite_send:send_to_guild(GuildId, BinData).

send_furnaceback_unite(PlayerId, {'furnaceback', Bcoin}) ->
	case misc:get_player_process(PlayerId) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, {'furnaceback', Bcoin});
        _ ->
            0
    end.

build_donate(PlayerId, GuildId, BuildType, CoinNum)->
	gen_server:call(mod_guild, {build_donate, [GuildId, PlayerId, BuildType, CoinNum]}).

set_zysb1(Status)->
	mod_disperse:cast_to_unite(pp_gm, set_zysb2, [Status]).
set_zysb2(Status)->
	GuildId = Status#player_status.guild#status_guild.guild_id,
	PlayerId = Status#player_status.id,
	gen_server:cast(mod_guild, {factionwer_prize, [GuildId, 99, 99, [PlayerId], 99]}).

set_zysb3(Status)->
	mod_disperse:cast_to_unite(pp_gm, set_zysb4, [Status]).
set_zysb4(Status)->
	GuildId = Status#player_status.guild#status_guild.guild_id,
	PlayerId = Status#player_status.id,
	LD = lists:seq(1, 2012),
	lists:foreach(fun(_) ->
						  gen_server:cast(mod_guild, {factionwer_prize, [GuildId, 99, 99, [PlayerId], 99]})
				  end, LD).

role_guild(PlayerId) ->
	NowTime = util:unixtime(),
	NSta = NowTime - 5 * 60 * 60 * 24,
	case lib_guild_base:get_guild_member_by_player_id(PlayerId) of
		GuildMember when is_record(GuildMember, ets_guild_member) ->
            GuildMemberNew = GuildMember#ets_guild_member{online_flag = 0, last_login_time = NSta},
			lib_guild_base:update_guild_member(GuildMemberNew),
			lib_guild_base:update_guild_member_base1(GuildMemberNew);
        _ -> 
			void
    end.
testerr(0) ->
	util:errlog("~n End ~n");
testerr(N) ->
	util:errlog("~n util:errlog ~p ~n", [[N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N, N]]),
	testerr(N-1).

del_buff(Status, [H | T]) -> 
    case is_record(H, ets_buff) of
        true ->
            Now = util:unixtime(),
            buff_dict:insert_buff(H#ets_buff{end_time = Now}),
            lib_player:send_buff_notice(Status, [H#ets_buff{end_time = Now}]),
            {_Error, _NewStatus} = lib_player:del_player_buff(Status, H#ets_buff.id);
        false -> _NewStatus = Status
    end,
    del_buff(_NewStatus, T);
del_buff(Status, []) -> {ok, Status}.
