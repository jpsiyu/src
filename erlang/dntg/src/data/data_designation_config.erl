%%%--------------------------------------
%%% @Module  : data_designation_config
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.10.18
%%% @Description: 称号配置
%%%--------------------------------------

-module(data_designation_config).
-compile(export_all).

get_design_id(1001, 1) -> 200101;
get_design_id(1001, 2) -> 200102;
get_design_id(1004, 1) -> 200201;
get_design_id(1004, 2) -> 200202;
get_design_id(1005, 1) -> 200301;
get_design_id(1005, 2) -> 200302;
get_design_id(5002, 1) -> 200401;
get_design_id(5002, 2) -> 200402;
get_design_id(1002, 1) -> 200601;
get_design_id(1002, 2) -> 200602;
get_design_id(1003, 1) -> 200701;
get_design_id(1003, 2) -> 200702;
get_design_id(2001, 1) -> 200801;
get_design_id(2001, 2) -> 200802;
get_design_id(3001, 1) -> 201001;
get_design_id(3001, 2) -> 201002;
get_design_id(7001, 1) -> 201201;
get_design_id(7002, 1) -> 201401;
get_design_id(7003, 1) -> 201101;
get_design_id(7004, 1) -> 201301;
get_design_id(_Module, _Position) -> 0.
