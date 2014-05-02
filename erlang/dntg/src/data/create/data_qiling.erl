
%%%---------------------------------------
%%% @Module  : data_qiling
%%% @Author  : faiy
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  器灵配置
%%%---------------------------------------
-module(data_qiling).
-compile(export_all).

get_lv_up_config() -> 
	[
	    	{1,0,2},{2,1,4},{3,4,6},{4,9,8},{5,17,10},{6,28,12},{7,43,14},{8,63,16},{9,88,18},{10,119,20},{11,156,22},{12,200,24},{13,251,26},{14,310,28},{15,377,30},{16,453,32},{17,538,34},{18,633,36},{19,738,38},{20,853,40}
     ].
get_open_pos_config() -> 
	[
	   {1,[{1,602111,0},{2,602111,20},{3,602111,60},{4,602111,120},{5,602111,200},{6,602111,320}]},{2,[{1,602111,0},{2,602111,10},{3,602111,40},{4,602111,90},{5,602111,160},{6,602111,260}]},{3,[{1,602111,0},{2,602111,15},{3,602111,50},{4,602111,105},{5,602111,180},{6,602111,290}]},{4,[{1,602111,0},{2,602111,5},{3,602111,30},{4,602111,75},{5,602111,140},{6,602111,230}]}
     ].