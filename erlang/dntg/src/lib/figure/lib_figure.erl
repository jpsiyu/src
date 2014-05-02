%%%--------------------------------------
%%% @Module  : lib_figure
%%% @Author  : zzm
%%% @Email   : ming_up@163.com
%%% @Created : 2012.07.17
%%% @Description : 人物变身
%%%--------------------------------------
-module(lib_figure).
-include("buff.hrl").
-include("figure.hrl").
-include("server.hrl").

-export([
        change/2, 
        mon_skill/1, 
        use_figure_goods/2, 
        get_figure_info/1, 
        get_figure_eff/1, 
        get_figure_broadcast/1, 
        del_figure/1,
        player_die/1
    ]).

change(Id, {FigureId, LastTime}) when is_integer(Id) -> 
    case lib_player:get_player_info(Id, pid) of
        false -> false;
        Pid -> 
            gen_server:cast(Pid, {'set_data', [{figure, {FigureId, LastTime, 0}}]}),
            true 
    end;

change(Pid, {FigureId, LastTime}) when is_pid(Pid) ->
    gen_server:cast(Pid, {'set_data', [{figure, {FigureId, LastTime, 0}}]});

%% 更新形象
change(PS, {FigureId, LastTime}) -> change(PS, {FigureId, LastTime, 0});
change(PS, {FigureId0, LastTime0, SkillId}) ->
    if
        PS#player_status.figure == 0 andalso FigureId0 == 0 -> PS;
        (PS#player_status.figure == 1111 orelse PS#player_status.figure == 2222 orelse PS#player_status.figure == 1314) andalso FigureId0 /= 0 -> PS;
        FigureId0 > 520000 andalso PS#player_status.figure < 500000 andalso PS#player_status.figure /= 0 -> %% 技能具有优先级
            PS;
        true -> 
            [FigureId, LastTime] = case FigureId0 == 0 of
                true ->  get_figure_info(PS#player_status.id);
                false -> [FigureId0, LastTime0]
            end,
            %% 变身广播 
            {ok, BinData} = pt_120:write(12099, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num, FigureId, LastTime]),
            lib_server_send:send_to_area_scene(PS#player_status.scene, PS#player_status.copy_id, PS#player_status.x, PS#player_status.y, BinData),
            %% 变身获得的特殊技能
            %% -----------------------------竞技场/帮派战/多人塔防---------------------------------
            case PS#player_status.scene == 223 orelse PS#player_status.scene == 106 orelse PS#player_status.scene == 235 of %% 竞技场/帮派战场景
                true ->
                    AddSL = figure_skill(skill, SkillId),
                    DelSL = figure_skill(figure, PS#player_status.figure),
                    case DelSL == [] of
                        true -> skip;
                        false -> 
                            {ok, BinData1} = pt_130:write(13034, [2, DelSL]),
                            lib_server_send:send_one(PS#player_status.socket, BinData1)
                    end,
                    case AddSL == [] of
                        true -> skip;
                        false -> 
                            {ok, BinData2} = pt_130:write(13034, [1, AddSL]),
                            lib_server_send:send_one(PS#player_status.socket, BinData2)
                    end;
                false -> skip
            end,
            %% --------------------------------------------------------------------------------
            NewStatus = PS#player_status{figure = FigureId},
	    mod_scene_agent:update(figure, NewStatus),
	    case NewStatus#player_status.sit#status_sit.sit_down =:= 2 of
		true -> gen_server:cast(NewStatus#player_status.sit#status_sit.sit_role_pid, {'shuangxiu_figure', FigureId, NewStatus#player_status.id});
		false -> []
	    end,
            NewStatus
    end.

%% 形象技能id
figure_skill(figure, FigureId) -> 
    case FigureId of
        400010 -> [{1, 400014}, {1, 400015}, {1, 400016}, {1, 400073}, {1, 400074}, {1, 400075}, {1, 903006},{1, 903007}]; %% 沙僧
        400008 -> [{1, 400018}, {1, 400076}]; %% 孙悟空
        400059 -> [{1, 400065}, {1, 400083}, {1, 903009},{1, 903010}]; %% 牛魔王
        400062 -> [{1, 400066}, {1, 400084}, {1, 903003},{1, 903004}]; %% 猪八戒
        _ -> []
    end;
%% 形象技能id
figure_skill(skill, SkillId) -> 
    case SkillId of
        %% 沙僧
        400011 -> [{1, 400014}];
        400012 -> [{1, 400015}];
        400013 -> [{1, 400016}];

        400070 -> [{1, 400073}];
        400071 -> [{1, 400074}];
        400072 -> [{1, 400075}];
        %% 悟空
        400008 -> [{1, 400018}];
        400009 -> [{1, 400018}];
        400010 -> [{1, 400018}];

        400067 -> [{1, 400076}];
        400068 -> [{1, 400076}];
        400069 -> [{1, 400076}];
        %% 牛魔王
        400059 -> [{1, 400065}];
        400060 -> [{1, 400065}];
        400061 -> [{1, 400065}];

        400077 -> [{1, 400083}];
        400078 -> [{1, 400083}];
        400079 -> [{1, 400083}];
        %% 猪八戒
        400062 -> [{1, 400066}];
        400063 -> [{1, 400066}];
        400064 -> [{1, 400066}];

        400080 -> [{1, 400084}];
        400081 -> [{1, 400084}];
        400082 -> [{1, 400084}];

        %% 炼狱副本猪八戒
        903002 -> [{1, 903003},{1, 903004}];
        %% 炼狱副本沙僧
        903005 -> [{1, 903006},{1, 903007}];
        %% 炼狱副本牛魔王
        903008 -> [{1, 903009},{1, 903010}];
        _ -> []
    end. 

%% 形象技能id
mon_skill(Mid) -> 
    case Mid of
        0 ->  
            SL = lists:nth(util:rand(1, 4), [[400008, 400009, 400010], [400011, 400012, 400013], [400059, 400060, 400061], [400062, 400063, 400064]]),
            %% 获取世界等级
            N = world_lv_nth_skill(),
            %% 根据世界等级获得技能
            lists:nth(N, SL);
        42011 -> %%孙悟空 
            SL = [400067, 400068, 400069],
            N = world_lv_nth_skill(),
            lists:nth(N, SL);
        42012 -> %%猪八戒 
            SL = [400080, 400081, 400082],
            N = world_lv_nth_skill(),
            lists:nth(N, SL);
        42013 -> %%沙僧 
            SL = [400070, 400071, 400072],
            N = world_lv_nth_skill(),
            lists:nth(N, SL);
        42021 -> %%牛魔王 
            SL = [400077, 400078, 400079],
            N = world_lv_nth_skill(),
            lists:nth(N, SL);
        36200 -> %% 炼狱副本孙悟空
            903001;
        36201 -> %% 炼狱副本猪八戒
            903002;
        36202 -> %% 炼狱副本沙僧
            903005;
        36203 -> %% 炼狱副本牛魔王
            903008;
        %% kf3v3
        25306 -> 401001; %% 狂暴
        25307 -> 401002; %% 加血
        25308 -> 401003; %% 加速
        _ -> false
    end. 

world_lv_nth_skill() -> 
    case catch mod_disperse:call_to_unite(mod_rank,get_average_level, []) of
        AverageLevel when is_integer(AverageLevel)->
            if
                AverageLevel >= 60 -> 3;
                AverageLevel >= 50 -> 2;
                true -> 1
            end;
        _Other ->
            1
    end.

%% ------------------------------------------------------------------------------------------------
%% 使用元魂珠功能
%% 变身buff 的Type 是97 AttributeId 也是97
%% ------------------------------------------------------------------------------------------------

%% 使用变身物品(变身buff需要特殊处理)
use_figure_goods(PlayerStatus, GoodsTypeId) ->
	case data_figure:get(GoodsTypeId) of
		[]-> %% 错误的物品类型
			PlayerStatus;
		Figure ->
            NowTime = util:unixtime(),
			Ftime = NowTime + Figure#figure.time,
            NewBuffInfo = case lib_buff:match_three(PlayerStatus#player_status.player_buff, ?FIGURE_BUFF_TYPE, ?FIGURE_BUFF_ATTID, []) of
		  	%NewBuffInfo = case lib_player:get_player_buff(PlayerStatus#player_status.id, ?FIGURE_BUFF_TYPE, ?FIGURE_BUFF_ATTID) of
		 	 	[] -> 
					lib_player:add_player_buff(PlayerStatus#player_status.id
												, ?FIGURE_BUFF_TYPE
												, GoodsTypeId
												, ?FIGURE_BUFF_ATTID
												, GoodsTypeId	%% Value
												, Ftime
												, []);
		  		[BuffInfo] -> 
					%% 计算时间叠加
					FtimeNext = case BuffInfo#ets_buff.goods_id =:= GoodsTypeId of
									true ->
										Figure#figure.time + BuffInfo#ets_buff.end_time;
									false ->
										Ftime
								end,
					%% 已经有BUFF的处理(规则未完成)
					lib_player:mod_buff(BuffInfo
									   , GoodsTypeId
									   , GoodsTypeId
									   , FtimeNext
									   , [])
		 	end,
			buff_dict:insert_buff(NewBuffInfo),
		  	lib_player:send_buff_notice(PlayerStatus, [NewBuffInfo]),
			BuffAttribute = lib_player:get_buff_attribute(PlayerStatus#player_status.id, PlayerStatus#player_status.scene),
			NewPlayerStatus = lib_player:count_player_attribute(PlayerStatus#player_status{buff_attribute = BuffAttribute}),
		    mod_scene_agent:update(battle_attr, NewPlayerStatus),
            WMTime = Figure#figure.time * 1000,
            NewPlayerStatusF = change(NewPlayerStatus, {Figure#figure.figure, WMTime}),
            %NewPlayerStatus#player_status{figure = Figure#figure.figure},
    		%mod_scene_agent:update(figure, NewPlayerStatusF),
			lib_player:send_attribute_change_notify(NewPlayerStatusF, 0),
			%% 变身广播 
    		%{ok, BinData} = pt_120:write(12099, [PlayerStatus#player_status.id, PlayerStatus#player_status.platform, PlayerStatus#player_status.server_num, Figure#figure.figure, WMTime]),
    		%lib_server_send:send_to_area_scene(PlayerStatus#player_status.scene, PlayerStatus#player_status.copy_id, PlayerStatus#player_status.x, PlayerStatus#player_status.y, BinData),
			NewPlayerStatusF
	end.

%% 查询变身信息
%% [形象, 时间]
get_figure_info(RoleId) ->
	case lib_player:get_player_buff(RoleId, ?FIGURE_BUFF_TYPE, ?FIGURE_BUFF_ATTID) of
 	 	[] -> 
			[0, 0];
  		[BuffInfo] -> 
			case data_figure:get(BuffInfo#ets_buff.goods_id) of
				[]->
					[0, 0];
				Figure ->
					NowTime = util:unixtime(),
					Ctime1 = BuffInfo#ets_buff.end_time - NowTime,
					[Figure#figure.figure, Ctime1 * 1000]
			end
 	end.

%% 变身属性处理
get_figure_eff(RoleId)->
	case lib_player:get_player_buff(RoleId, ?FIGURE_BUFF_TYPE, ?FIGURE_BUFF_ATTID) of
 	 	[] -> 
			[];
  		[BuffInfo] -> 
			BuffInfo
 	end.

%% 变身广播判断
get_figure_broadcast(PS)->
    case lib_buff:match_three(PS#player_status.player_buff, ?FIGURE_BUFF_TYPE, ?FIGURE_BUFF_ATTID, []) of
	%case lib_player:get_player_buff(PS#player_status.id, ?FIGURE_BUFF_TYPE, ?FIGURE_BUFF_ATTID) of
 	 	[] -> 
			PS;
  		[BuffInfo] -> 
			case data_figure:get(BuffInfo#ets_buff.goods_id) of
				[]->
					PS;
				Figure ->
					NowTime = util:unixtime(),
                    Ctime1 = BuffInfo#ets_buff.end_time - NowTime,
                    NewPlayerStatusF = change(PS, {Figure#figure.figure, Ctime1 * 1000}),
                    %PS#player_status{figure = Figure#figure.figure},
		    		%mod_scene_agent:update(figure, NewPlayerStatusF),
					%Ctime1 = BuffInfo#ets_buff.end_time - NowTime,%% 变身广播 
		    		%{ok, BinData} = pt_120:write(12099, [PS#player_status.id, PS#player_status.platform, PS#player_status.server_num, Figure#figure.figure, Ctime1 * 1000]),
					%lib_server_send:send_to_area_scene(PS#player_status.scene, PS#player_status.copy_id, PS#player_status.x, PS#player_status.y, BinData),
					NewPlayerStatusF
			end
 	end.

del_figure(PS) ->
	{ok, BinData} = pt_361:write(36112, [1]),
	lib_server_send:send_to_sid(PS#player_status.sid, BinData).

%% 玩家死亡，清理形象
player_die(#player_status{figure=Figure} = Status) -> 
    case Figure /= 0 of
        true ->
            change(Status, {0, 0});
        false -> 
            Status
    end.



























































%% -------------------------------------------------- E N D ----------------------------------------------------------------
