%%%-----------------------------------
%%% @Module  : lib_server_dict
%%% @Author  : zhenghehe
%%% @Created : 2011.07.18
%%% @Description: 每个玩家的进程字典管理
%%% 函数范式  : 进程字典字段名(put/get, value)
%%%-----------------------------------
-module(lib_server_dict).
-compile(export_all).

equip_evaluate_time(Value) ->
    put("equip_evaluate_time", Value).
equip_evaluate_time() ->
    get("equip_evaluate_time").

rank_look(Value) ->
    put("rank_look", Value).
rank_look() ->
    get("rank_look").

egg_broken_time(Value) ->
    put("egg_broken_time", Value).
egg_broken_time() ->
    get("egg_broken_time").

task_sr_trigger(Value) ->
    put("task_sr_trigger", Value).
task_sr_trigger() ->
    get("task_sr_trigger").

task_sr_active(Value) ->
    put("task_sr_active", Value).
task_sr_active() ->
    get("task_sr_active").

task_sr_rf_count(Value) ->
  put("task_sr_rf_count", Value).
task_sr_rf_count() ->
  get("task_sr_rf_count").

task_sr_30503_count(Value) ->
  put("task_sr_30503_count", Value).
task_sr_30503_count() ->
  get("task_sr_30503_count").

fly_prop(Value) ->
    put("fly_prop", Value).
fly_prop() ->
    get("fly_prop").



