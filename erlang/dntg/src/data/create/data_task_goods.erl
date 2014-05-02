%%%---------------------------------------
%%% @Module  : data_task_goods
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2014-04-29 16:16:28
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_task_goods).
-export([get_trigger_task/1,get_replace_task/1,get_finish_goods/1]).

get_trigger_task(671001) -> 800010;
get_trigger_task(671002) -> 800020;
get_trigger_task(671003) -> 800030;
get_trigger_task(671004) -> 800040;
get_trigger_task(671006) -> 800050;
get_trigger_task(671007) -> 800060;
get_trigger_task(671008) -> 800070;
get_trigger_task(671009) -> 800080;
get_trigger_task(671011) -> 800090;
get_trigger_task(671012) -> 800100;
get_trigger_task(671013) -> 800110;
get_trigger_task(671014) -> 800120;
get_trigger_task(671021) -> 800130;
get_trigger_task(671022) -> 800140;
get_trigger_task(671023) -> 800150;
get_trigger_task(671024) -> 800160;
get_trigger_task(671025) -> 800170;
get_trigger_task(671026) -> 800180;
get_trigger_task(671027) -> 800190;
get_trigger_task(671028) -> 800200;
get_trigger_task(671031) -> 800210;
get_trigger_task(671032) -> 800220;
get_trigger_task(671033) -> 800230;
get_trigger_task(671034) -> 800240;
get_trigger_task(671041) -> 800250;
get_trigger_task(671042) -> 800260;
get_trigger_task(671043) -> 800270;
get_trigger_task(671044) -> 800280;
get_trigger_task(671091) -> 800290;
get_trigger_task(671092) -> 800300;
get_trigger_task(671093) -> 800310;
get_trigger_task(671094) -> 800320;
get_trigger_task(_GoodsId) -> 0.

get_replace_task(_GoodsId) -> 0.

get_finish_goods(_TaskId) -> [].
