
%%%---------------------------------------
%%% @Module  : data_sell
%%% @Author  : faiy
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_sell).
-compile(export_all).
-include("sell.hrl").
get_sell_class(Type, SubType, Career, Sex) ->
    case get_class(Type, SubType, Career, Sex) of
        Info when is_record(Info, ets_sell_class) ->
            case Info#ets_sell_class.min_type =:= 888 andalso Info#ets_sell_class.max_type =:= 88 of
                true ->
                    case get_class(Type, SubType, Career, 0) of
                        Info1 when is_record(Info1, ets_sell_class) ->
                            case Info1#ets_sell_class.min_type =:= 888 andalso Info1#ets_sell_class.max_type =:= 88 of
                                true ->
                                    case get_class(Type, SubType, 0, Sex) of
                                        Info2 when is_record(Info2, ets_sell_class) ->
                                            case Info2#ets_sell_class.min_type =:= 888 andalso Info2#ets_sell_class.max_type =:= 88 of
                                                true ->
                                                    get_class(Type, SubType, 0, 0);
                                                false ->
                                                    Info2
                                            end;
                                        _ ->
                                            skip
                                    end;
                                false ->
                                    Info1
                            end;
                        _ ->
                            skip
                    end;
                false ->
                    Info
            end;
        _ ->
            skip
    end.
get_class(11,22,0,0) -> 
	    			   	   #ets_sell_class{min_type = 11, name = <<"升级">>, max_type = 1, career = 0, sex = 0, type_list = [{11,22},{11,27},{60,17}]};
get_class(11,27,0,0) -> 
	    			   	   #ets_sell_class{min_type = 11, name = <<"升级">>, max_type = 1, career = 0, sex = 0, type_list = [{11,22},{11,27},{60,17}]};
get_class(60,17,0,0) -> 
	    			   	   #ets_sell_class{min_type = 11, name = <<"升级">>, max_type = 1, career = 0, sex = 0, type_list = [{11,22},{11,27},{60,17}]};
get_class(11,10,0,0) -> 
	    			   	   #ets_sell_class{min_type = 12, name = <<"强化">>, max_type = 1, career = 0, sex = 0, type_list = [{11,10}]};
get_class(11,28,0,0) -> 
	    			   	   #ets_sell_class{min_type = 13, name = <<"进阶">>, max_type = 1, career = 0, sex = 0, type_list = [{11,28}]};
get_class(60,16,0,0) -> 
	    			   	   #ets_sell_class{min_type = 14, name = <<"品质">>, max_type = 1, career = 0, sex = 0, type_list = [{60,16}]};
get_class(11,14,0,0) -> 
	    			   	   #ets_sell_class{min_type = 15, name = <<"宝石">>, max_type = 1, career = 0, sex = 0, type_list = [{11,14},{11,15}]};
get_class(11,15,0,0) -> 
	    			   	   #ets_sell_class{min_type = 15, name = <<"宝石">>, max_type = 1, career = 0, sex = 0, type_list = [{11,14},{11,15}]};
get_class(62,10,0,0) -> 
	    			   	   #ets_sell_class{min_type = 21, name = <<"宠物蛋">>, max_type = 2, career = 0, sex = 0, type_list = [{62,10}]};
get_class(62,13,0,0) -> 
	    			   	   #ets_sell_class{min_type = 22, name = <<"食粮">>, max_type = 2, career = 0, sex = 0, type_list = [{62,13}]};
get_class(62,42,0,0) -> 
	    			   	   #ets_sell_class{min_type = 23, name = <<"成长">>, max_type = 2, career = 0, sex = 0, type_list = [{62,42},{62,43}]};
get_class(62,43,0,0) -> 
	    			   	   #ets_sell_class{min_type = 23, name = <<"成长">>, max_type = 2, career = 0, sex = 0, type_list = [{62,42},{62,43}]};
get_class(62,48,0,0) -> 
	    			   	   #ets_sell_class{min_type = 24, name = <<"潜能">>, max_type = 2, career = 0, sex = 0, type_list = [{62,48}]};
get_class(31,11,0,0) -> 
	    			   	   #ets_sell_class{min_type = 31, name = <<"进阶">>, max_type = 3, career = 0, sex = 0, type_list = [{31,11}]};
get_class(31,15,0,0) -> 
	    			   	   #ets_sell_class{min_type = 32, name = <<"幻化">>, max_type = 3, career = 0, sex = 0, type_list = [{31,15}]};
get_class(23,12,0,0) -> 
	    			   	   #ets_sell_class{min_type = 41, name = <<"境界符">>, max_type = 4, career = 0, sex = 0, type_list = [{23,12}]};
get_class(41,10,0,0) -> 
	    			   	   #ets_sell_class{min_type = 51, name = <<"帮派">>, max_type = 5, career = 0, sex = 0, type_list = [{41,10},{41,11},{41,12},{41,13},{41,14},{41,15},{41,16},{41,17},{41,18},{41,19},{41,20}]};
get_class(41,11,0,0) -> 
	    			   	   #ets_sell_class{min_type = 51, name = <<"帮派">>, max_type = 5, career = 0, sex = 0, type_list = [{41,10},{41,11},{41,12},{41,13},{41,14},{41,15},{41,16},{41,17},{41,18},{41,19},{41,20}]};
get_class(41,12,0,0) -> 
	    			   	   #ets_sell_class{min_type = 51, name = <<"帮派">>, max_type = 5, career = 0, sex = 0, type_list = [{41,10},{41,11},{41,12},{41,13},{41,14},{41,15},{41,16},{41,17},{41,18},{41,19},{41,20}]};
get_class(41,13,0,0) -> 
	    			   	   #ets_sell_class{min_type = 51, name = <<"帮派">>, max_type = 5, career = 0, sex = 0, type_list = [{41,10},{41,11},{41,12},{41,13},{41,14},{41,15},{41,16},{41,17},{41,18},{41,19},{41,20}]};
get_class(41,14,0,0) -> 
	    			   	   #ets_sell_class{min_type = 51, name = <<"帮派">>, max_type = 5, career = 0, sex = 0, type_list = [{41,10},{41,11},{41,12},{41,13},{41,14},{41,15},{41,16},{41,17},{41,18},{41,19},{41,20}]};
get_class(41,15,0,0) -> 
	    			   	   #ets_sell_class{min_type = 51, name = <<"帮派">>, max_type = 5, career = 0, sex = 0, type_list = [{41,10},{41,11},{41,12},{41,13},{41,14},{41,15},{41,16},{41,17},{41,18},{41,19},{41,20}]};
get_class(41,16,0,0) -> 
	    			   	   #ets_sell_class{min_type = 51, name = <<"帮派">>, max_type = 5, career = 0, sex = 0, type_list = [{41,10},{41,11},{41,12},{41,13},{41,14},{41,15},{41,16},{41,17},{41,18},{41,19},{41,20}]};
get_class(41,17,0,0) -> 
	    			   	   #ets_sell_class{min_type = 51, name = <<"帮派">>, max_type = 5, career = 0, sex = 0, type_list = [{41,10},{41,11},{41,12},{41,13},{41,14},{41,15},{41,16},{41,17},{41,18},{41,19},{41,20}]};
get_class(41,18,0,0) -> 
	    			   	   #ets_sell_class{min_type = 51, name = <<"帮派">>, max_type = 5, career = 0, sex = 0, type_list = [{41,10},{41,11},{41,12},{41,13},{41,14},{41,15},{41,16},{41,17},{41,18},{41,19},{41,20}]};
get_class(41,19,0,0) -> 
	    			   	   #ets_sell_class{min_type = 51, name = <<"帮派">>, max_type = 5, career = 0, sex = 0, type_list = [{41,10},{41,11},{41,12},{41,13},{41,14},{41,15},{41,16},{41,17},{41,18},{41,19},{41,20}]};
get_class(41,20,0,0) -> 
	    			   	   #ets_sell_class{min_type = 51, name = <<"帮派">>, max_type = 5, career = 0, sex = 0, type_list = [{41,10},{41,11},{41,12},{41,13},{41,14},{41,15},{41,16},{41,17},{41,18},{41,19},{41,20}]};
get_class(50,1,0,0) -> 
	    			   	   #ets_sell_class{min_type = 52, name = <<"任务">>, max_type = 5, career = 0, sex = 0, type_list = [{50,1},{67,10}]};
get_class(67,10,0,0) -> 
	    			   	   #ets_sell_class{min_type = 52, name = <<"任务">>, max_type = 5, career = 0, sex = 0, type_list = [{50,1},{67,10}]};
get_class(67,50,0,0) -> 
	    			   	   #ets_sell_class{min_type = 53, name = <<"令牌">>, max_type = 5, career = 0, sex = 0, type_list = [{67,50}]};
get_class(52,10,0,0) -> 
	    			   	   #ets_sell_class{min_type = 54, name = <<"活动">>, max_type = 5, career = 0, sex = 0, type_list = [{52,10},{52,11},{52,12},{52,13},{22,10},{61,16},{22,12},{52,30}]};
get_class(52,11,0,0) -> 
	    			   	   #ets_sell_class{min_type = 54, name = <<"活动">>, max_type = 5, career = 0, sex = 0, type_list = [{52,10},{52,11},{52,12},{52,13},{22,10},{61,16},{22,12},{52,30}]};
get_class(52,12,0,0) -> 
	    			   	   #ets_sell_class{min_type = 54, name = <<"活动">>, max_type = 5, career = 0, sex = 0, type_list = [{52,10},{52,11},{52,12},{52,13},{22,10},{61,16},{22,12},{52,30}]};
get_class(52,13,0,0) -> 
	    			   	   #ets_sell_class{min_type = 54, name = <<"活动">>, max_type = 5, career = 0, sex = 0, type_list = [{52,10},{52,11},{52,12},{52,13},{22,10},{61,16},{22,12},{52,30}]};
get_class(22,10,0,0) -> 
	    			   	   #ets_sell_class{min_type = 54, name = <<"活动">>, max_type = 5, career = 0, sex = 0, type_list = [{52,10},{52,11},{52,12},{52,13},{22,10},{61,16},{22,12},{52,30}]};
get_class(61,16,0,0) -> 
	    			   	   #ets_sell_class{min_type = 54, name = <<"活动">>, max_type = 5, career = 0, sex = 0, type_list = [{52,10},{52,11},{52,12},{52,13},{22,10},{61,16},{22,12},{52,30}]};
get_class(22,12,0,0) -> 
	    			   	   #ets_sell_class{min_type = 54, name = <<"活动">>, max_type = 5, career = 0, sex = 0, type_list = [{52,10},{52,11},{52,12},{52,13},{22,10},{61,16},{22,12},{52,30}]};
get_class(52,30,0,0) -> 
	    			   	   #ets_sell_class{min_type = 54, name = <<"活动">>, max_type = 5, career = 0, sex = 0, type_list = [{52,10},{52,11},{52,12},{52,13},{22,10},{61,16},{22,12},{52,30}]};
get_class(0,0,0,0) -> 
	    			   	   #ets_sell_class{min_type = 55, name = <<"其它">>, max_type = 5, career = 0, sex = 0, type_list = [{0,0}]};
get_class(_Type,_SubType,_Career,_Sex) -> #ets_sell_class{min_type = 888, name = <<"其它">>, max_type = 88, career = 0, sex = 0, type_list = [{0,0}]}.
