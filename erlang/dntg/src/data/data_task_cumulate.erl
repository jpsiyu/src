%%%------------------------------------
%%% @Module  : data_task_cumulate
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.7.31
%%% @Description: 功能累积(离线经验累积)
%%%------------------------------------
-module(data_task_cumulate).
-compile(export_all).

get_task_cumulate_data(Type) ->
    case Type of
        task_id_list -> [1, 2, 3, 4];      %% 1.经验本，2.皇榜，3.平乱，4.诛妖  %%后面要加其他累积的要按顺序编号1，2，3，4，5，6、、、同时下面的task_name_list和max_cumulate_day也要依次添加
        task_name_list -> [<<"经验副本">>, <<"皇榜任务">>, <<"平乱任务">>, <<"诛妖任务">>];
        other_task_name -> <<"其他任务">>;
        max_cumulate_day -> [1, 7, 7, 7, 0];  %% 最大离线天数(最后一个0是容错用)
        _ -> skip
    end.

%% 皇榜任务经验
get_hb_exp(Lv) ->
    if
		Lv<30->0;
		Lv=<39->3000000;
		Lv=<49->4200000;
		Lv=<59->5820000;
        Lv=<69->7500000;
        Lv=<79->10425000;
		true->10425000
    end.

%% 平乱任务经验
get_pl_exp(Lv) ->
    if
		Lv<30->0;
		Lv=<39->2000000;
		Lv=<49->2800000;
		Lv=<59->3880000;
        Lv=<69->5000000;
        Lv=<79->6950000;
		true->6950000
    end.

%% 诛妖任务经验
get_zy_exp(Lv) ->
    if
		Lv<30->0;
		Lv=<39->1000000;
		Lv=<49->1400000;
		Lv=<59->1940000;
        Lv=<69->2500000;
        Lv=<79->3475000;
		true->3475000
    end.
