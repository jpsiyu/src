%%%---------------------------------------
%%% @Module  : data_master
%%% @Author  : shebiao
%%% @Email   : shebiao@jieyou.com
%%% @Created : 2010-10-12
%%% @Description:  师徒配置
%%%---------------------------------------
-module(data_master).
-compile(export_all).

%% -----------------------------------------------------------------
%% 获取基本配置
%% -----------------------------------------------------------------
get_master_config(Type, _Args) ->
    case Type of
        % 登记上榜最小等级
        master_min_level ->                      28;
        % 拜师最小等级
        apprentice_min_level  ->                 15;
        % 拜师最大等级
        apprentice_max_level ->                  39;
        % 逐出师门的徒弟离线时间
        kickout_offline_time ->                 2*86400;
        % 退出师门的师傅离线时间
        quit_offline_time ->                     2*86400;
        % 自动下伯乐榜的时间
        auto_cancel_register_time ->             7*86400;
        % 汇报等级限制
        report_max_level ->                      40;
        % 师徒决裂书
        master_seperate_book ->                  [42, 10, 1];
        % 出师的等级
        master_finish_level ->                   45;
        % 出师增加的师道值
        master_finish_score ->                   200;
        % 推荐师傅的个数
        introduce_master_num->                   5;
        % 最大邀请人数
        invite_max_num->                         1;
        % 出师礼包（徒弟）
        master_finish_apprentice_gift_bag ->     531501;
        % 出师礼包（师傅）
        master_finish_gift_bag ->                531502;
        % 升20级礼包（徒弟）
        master_uplevel_20_apprentice_gift_bag -> 531503;
        % 升30级礼包（徒弟）
        master_uplevel_30_apprentice_gift_bag -> 531504;
        % 首次拜师礼包（徒弟）
        master_first_join_apprentice_gift_bag -> 531505
    end.

%% -----------------------------------------------------------------
%% 获取汇报信息
%% -----------------------------------------------------------------
get_report_info(Level) ->
    ReportInfo =
        [{16,27376,9125,1},
         {17,27679,9226,2},
         {18,27982,9327,3},
         {19,28285,9428,4},
         {20,28588,9529,4},
         {21,28891,9630,6},
         {22,29194,9731,9},
         {23,29497,9832,12},
         {24,29800,9933,15},
         {25,30103,10034,18},
         {26,30406,10135,46},
         {27,30709,10236,48},
         {28,31012,10337,56},
         {29,31315,10438,59},
         {30,44815,14938,77},
         {31,59230,19743,83},
         {32,74590,24863,88},
         {33,90925,30308,93},
         {34,108265,36088,98},
         {35,126640,42213,103},
         {36,146080,48693,109},
         {37,166615,55538,114},
         {38,188275,62758,119},
         {39,211090,70363,124},
         {40,235090,78363,200}
        ],
     case lists:keyfind(Level, 1, ReportInfo) of
         {_Level, ApprenticeExp, MasterExp, MasterScore} -> {ApprenticeExp, MasterExp, MasterScore};
         false -> {0, 0, 0}
     end.

%% -----------------------------------------------------------------
%% 获取师道值兑换经验信息
%% -----------------------------------------------------------------
get_exchange_exp(ExchangeType) ->
    ExpInfo = [{1,750,345000},
               {2,3000,1488000},
               {3,6000,3240000}] ,
    lists:keyfind(ExchangeType, 1, ExpInfo).

%% -----------------------------------------------------------------
%% 获取最大收徒数
%% -----------------------------------------------------------------
get_max_apprentice_num(Score) ->
    MaxApprenticeNumInfo =
        [
        {0,    300,1},
        {301,  1500,2},
        {1501, 6000,3},
        {6001, 30000,4},
        {30001,99999999999, 5}
        ],
    case keycompare(Score, 1, 2, MaxApprenticeNumInfo) of
        {value, {_, _, MaxNum}} -> MaxNum;
        false -> 1
    end.

keycompare(_Key, _N1, _N2, []) ->
    false;
keycompare(Key, N1, N2, [H|T]) ->
    case Key >= element(N1, H) andalso Key =< element(N2, H) of
        true ->
            {value, H};
        false ->
            keycompare(Key, N1, N2, T)
    end.