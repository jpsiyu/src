%%%------------------------------------
%%% @Module  : data_marriage
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.24
%%% @Description: 结婚系统
%%%------------------------------------
-module(data_marriage).
-compile(export_all).
%%
%% Include files
%%

%%
%% Exported Functions
%%

%%
%% API Functions
%%
%% 基础数据配置
get_marriage_config(Type)->
    case Type of
        scene_id -> 434; %场景ID
        %% 婚宴
        activity_begin1 -> {{2012, 11, 1}, {0, 0, 0}};
        activity_end1 -> {{2012, 11, 1}, {23, 59, 59}};
        %% 巡游
        activity_begin2 -> {{2012, 10, 17}, {0, 0, 0}};
        activity_end2 -> {{2012, 11, 3}, {23, 59, 59}};
        %% 8折活动
        activity_begin3 -> {{2013, 3, 8}, {0, 0, 0}};
        activity_end3 -> {{2013, 3, 8}, {23, 59, 59}};
        _ -> void
    end.
