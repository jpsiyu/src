%%%---------------------------------------
%%% @Module  : data_player
%%% @Author  : zhenghehe
%%% @Created : 2010-06-24
%%% @Description:  角色配置
%%%---------------------------------------
-module(data_player).
-compile(export_all).

get_player_config(Type, _Args) ->
    case Type of
        anger_default -> 12;
        anger_max -> 12;
        combo_buff_last_time ->  900 %% 15分钟
    end.