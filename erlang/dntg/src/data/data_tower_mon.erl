%%%---------------------------------------
%%% @Module  : data_tower_mon
%%% @Author  : zzm
%%% @Email   : ming_up@163.com
%%% @Created : 2011-01-19
%%% @Description:  锁妖塔怪物配置
%%%---------------------------------------
-module(data_tower_mon).
-compile(export_all).
-include("dungeon.hrl").
-include("tower.hrl").

% 40163     月光宝盒    -20s
% 40164     月光宝盒    -20s
% 40165     月光宝盒    -20s
% 40169     月光宝盒    -20s

% 40166     和氏壁      +10s
% 40167     赵国暗哨    -15s
% 40168     赵国御林军  -15s
% 40171     雷柱        -15s


get(40163) ->
    #tower_mon{id = 40101, time = -20};

get(40164) ->
    #tower_mon{id = 40164, time = -20};

get(40165) ->
    #tower_mon{id = 40165, time = -20};

get(40166) ->
    #tower_mon{id = 40166, time = 10};

get(40167) ->
    #tower_mon{id = 40167, time = -15};

get(40168) ->
    #tower_mon{id = 40168, time = -15};

get(40169) ->
    #tower_mon{id = 40169, time = -20};

get(40171) ->
    #tower_mon{id = 40171, time = -15};

get(_) ->
    #tower_mon{}. 
