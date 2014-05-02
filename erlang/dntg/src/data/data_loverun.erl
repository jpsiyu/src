%%%------------------------------------
%%% @Module  : data_loverun
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.8.21
%%% @Description: 爱情长跑
%%%------------------------------------
-module(data_loverun).
-compile(export_all).
%%
%% API Functions
%%
%% 基础数据配置
get_loverun_config(Type)->
	case Type of
%%		% [开始日期，结束日期]
%%		activity_date -> [{2012, 11, 12}, {2012, 11, 23}];
%%		% [开始时间，结束时间]
%%		activity_time -> [[{14, 0}, {14, 30}], [{21, 0}, {21, 30}]];
		% 场景Id
		scene_id -> 990;
		% 开新房间人数
		room_new_num -> 175;
		% 房间最大人数
		room_max_num -> 200;
		% 出生点坐标
		scene_born -> {64,22};
		% 离开场景的默认场景ID和坐标
		leave_scene -> {102, 103, 122};
        % 离开场景的默认场景ID和坐标
		leave_scene2 -> [102, 103, 122];
		% 活动开始的坐标
        begin_xy -> [{58, 30}, {63, 23}, {57, 24}, {60, 37}, {67, 29}, {67, 21}];
        % 邮件标题
        title1 -> "浪漫西游，爱情长跑奖励";
        % 邮件内容
        content1 -> "亲爱的玩家：\n恭喜你在这一轮爱情长跑中完满完成任务，与你的TA共谱一曲浪漫恋曲。大闹天宫送上一份真挚礼物，祝天下有情人终成眷属。";
        apply_time -> 15;
		_ ->void
	end.
