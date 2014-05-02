%%%-----------------------------------
%%% @Module  : data_mount_config
%%% @Author  : HHL
%%% @Email   : 
%%% @Created : 2014.4.3
%%% @Description: data_mount_config
%%%-----------------------------------

-module(data_mount_config).

%% ====================================================================
%% API functions
%% ====================================================================
-compile(export_all).
-include("mount.hrl").
%% 1:气血
%% 2:法力
%% 3:攻击
%% 4:防御
%% 5:命中
%% 6:闪避
%% 7:暴击 
%% 8:坚韧 
%% 13:雷抗 
%% 14:水抗 
%% 15:冥抗 
%% 16:全抗

%% ====================================================================
%% Internal functions
%% ====================================================================
get_config(Type)->
    case Type of
        quality_used_coin -> 10000;     %% 
        quality_used_goods -> {311201, 1};      %%
        quality_times -> 10;                    %% 每天资质能培养的次数 
		quality_init_attr -> [{3,0,0}, {1,0,0}, {4,0,0}, {16,0,0}, {5,0,0}, {6,0,0}, {7,0,0}, {8,0,0}];   %%
        lingxi_init_attr -> [{1,0}, {4,0}, {13,0}, {14,0}, {15,0}];      %% 
        attr_type_list -> [1, 2, 3, 4, 5, 6, 7, 8, 13, 14, 15];     %% 坐骑进阶属性类型列表
        resist_attr -> 16;    %% 全抗属性:将13, 14, 15三属性加相应的属性值
        Type -> 
            skip
    end.


mount_is_max_level(Level) ->
    case Level >= 12 of
        true -> true;
        false -> false
    end.


%% get_mount_upgrade_star_info(Level, StarNum)->
%%     MountUpgradeStarRecord = data_mount_temp:get_mount_upgrade_star(Level, StarNum),


get_mount_figure_id_by_level(Level) ->
    case Level of
        1 -> 100001;
        2 -> 100002;
        _ -> 100001
    end.
          
get_mount_type_id_by_level(Level) ->
    case Level of
        1 -> 311001;
        2 -> 311002;
        3 -> 311009;
        _ -> 311001
    end.

%% 获取资质培养的属性总星星数
get_quality_attr_total_star(QualityAttr)->
    lists:foldl(fun({_Type, _Value, StarNum1}, StarNum) ->
                        StarNum + StarNum1
                end, 0, QualityAttr).


get_quality_attr_total_star1(QualityAttr)->
    lists:foldl(fun({_Type, _Value, StarNum1, _AddIsCut}, StarNum) ->
                        StarNum + StarNum1
                end, 0, QualityAttr).


%% 获取灵犀的等级根据现有的灵犀值
get_lingxi_lv(LingXiNum)->
    if
        LingXiNum > 70 -> 5;
        LingXiNum > 60 -> 4;
        LingXiNum > 50 -> 3;
        LingXiNum > 40 -> 2;
        LingXiNum > 20 -> 1;
        true -> 0
    end.

%% 
get_quality_lv(StarNum)->
    if
        StarNum > 100 -> 7;
        StarNum > 90 -> 6;
        StarNum > 80 -> 5;
        StarNum > 70 -> 4;
        StarNum > 60 -> 3;
        StarNum > 50 -> 2;
        StarNum > 20 -> 1;
        true -> 0
    end. 



get_diff_change_figure_list(FigureList)->
    LevelFigure = data_mount:get_upgrade_all(),
    lists:foldl(fun(Upgrade, TempList)->
                        case lists:member(Upgrade#upgrade_change.type_id, LevelFigure) of
                            true ->
                                [{Upgrade#upgrade_change.type_id, Upgrade#upgrade_change.state, 
                                  Upgrade#upgrade_change.time, 1}|TempList];
                            false ->
                                [{Upgrade#upgrade_change.type_id, Upgrade#upgrade_change.state, 
                                  Upgrade#upgrade_change.time, 2}|TempList]
                        end
                end, [], FigureList).

%% 获取幻化形象添加的属性
get_figure_attr(FigureList)->
    ChangeFigureList = [FigureId || {FigureId, _State, _Time, Type} <- FigureList, Type=:=2],
    case ChangeFigureList of
        [] -> [];
        ChangeFigureList ->
            lib_mount2:get_attr_from_figure(ChangeFigureList)
    end.