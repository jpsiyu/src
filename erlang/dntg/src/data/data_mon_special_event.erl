%%%---------------------------------------
%%% @Module  : data_mon_special_event
%%% @Author  : zzm
%%% @Email   : ming_up@163.com
%%% @Created : 2011-07-06
%%% @Description:  怪物特殊事件数据
%%%---------------------------------------

-module(data_mon_special_event).
-export([get/1, get_event/2]).

%% get(怪物id) -> []

%% 墨家钜子AI
get(59505) -> 
    [
        {a1,5000,{a2, 45000, {e, 40000, trun}}},
        {b1,5000,{b2, 45000, {e, 40000, trun}}},
        {c1,5000,{c2, 45000, {e, 40000, trun}}}
        %{d1,5000,{d2, 30000, {e, 25000, trun}}}
    ];


%% 一堆情缘副本AI
get(23301) -> {a, 1000, {b, 1000, null}};
get(23302) -> {a, 1000, {b, 1000, null}};
get(23303) -> {a, 1000, {b, 1000, null}};
get(23304) -> {a, 1000, {b, 1000, null}};
get(23305) -> {a, 1000, {b, 1000, null}};
get(23306) -> {a, 1000, {b, 1000, null}};
get(23307) -> {a, 1000, {b, 1000, null}};
get(23308) -> {a, 1000, {b, 1000, null}};
get(23309) -> {a, 1000, {b, 1000, null}};
get(23310) -> {a, 1000, {b, 1000, null}};
get(23311) -> {a, 1000, {b, 1000, null}};
get(23312) -> {a, 1000, {b, 1000, null}};
get(23313) -> {a, 1000, {b, 1000, null}};
get(23314) -> {a, 1000, {b, 1000, null}};
get(23315) -> {a, 1000, {b, 1000, null}};
get(23316) -> {a, 1000, {b, 1000, null}};
get(23317) -> {a, 1000, {b, 1000, null}};
get(23318) -> {a, 1000, {b, 1000, null}};
get(23319) -> {a, 1000, {b, 1000, null}};
get(23320) -> {a, 1000, {b, 1000, null}};
get(23321) -> {a, 1000, {b, 1000, null}};
get(23322) -> {a, 1000, {b, 1000, null}};
%get(23323) -> {a, 1000, {b, 1000, null}};
%get(23324) -> {a, 1000, {b, 1000, null}};
%get(23325) -> {a, 1000, {b, 1000, null}};
%get(23326) -> {a, 1000, {b, 1000, null}};
get(23327) -> {a, 1000, {b, 1000, null}};
get(23328) -> {a, 1000, {b, 1000, null}};
get(23329) -> {a, 1000, {b, 1000, null}};
get(23330) -> {a, 1000, {b, 1000, null}};
get(23331) -> {a, 1000, {b, 1000, null}};
get(23332) -> {a, 1000, {b, 1000, null}};
get(23333) -> {a, 1000, {b, 1000, null}};
get(23334) -> {a, 1000, {b, 1000, null}};
get(23335) -> {a, 1000, {b, 1000, null}};
get(23336) -> {a, 1000, {b, 1000, null}};
get(23337) -> {a, 1000, {b, 1000, null}};
get(23338) -> {a, 1000, {b, 1000, null}};
get(23339) -> {a, 1000, {b, 1000, null}};
get(23340) -> {a, 1000, {b, 1000, null}};
get(23341) -> {a, 1000, {b, 1000, null}};
get(23342) -> {a, 1000, {b, 1000, null}};
get(23343) -> {a, 1000, {b, 1000, null}};
get(23344) -> {a, 1000, {b, 1000, null}};
get(23345) -> {a, 1000, {b, 1000, null}};
get(23346) -> {a, 1000, {b, 1000, null}};
get(23347) -> {a, 1000, {b, 1000, null}};
get(23348) -> {a, 1000, {b, 1000, null}};
get(23349) -> {a, 1000, {b, 1000, null}};
get(23350) -> {a, 1000, {b, 1000, null}};
get(23351) -> {a, 1000, {b, 1000, null}};
get(23352) -> {a, 1000, {b, 1000, null}};
get(23353) -> {a, 1000, {b, 1000, null}};
get(23354) -> {a, 1000, {b, 1000, null}};
get(23355) -> {a, 1000, {b, 1000, null}};
get(23356) -> {a, 1000, {b, 1000, null}};
get(23357) -> {a, 1000, {b, 1000, null}};
get(23358) -> {a, 1000, {b, 1000, null}};
get(23359) -> {a, 1000, {b, 1000, null}};
get(91001) -> {a, 1000, {b, 1000, null}};
get(91002) -> {a, 1000, {b, 1000, null}};
get(91003) -> {a, 1000, {b, 1000, null}};
get(91004) -> {a, 1000, {b, 1000, null}};
get(91005) -> {a, 1000, {b, 1000, null}};
get(91006) -> {a, 1000, {b, 1000, null}};
get(91007) -> {a, 1000, {b, 1000, null}};
get(91008) -> {a, 1000, {b, 1000, null}};
get(91009) -> {a, 1000, {b, 1000, null}};
get(91010) -> {a, 1000, {b, 1000, null}};
get(91011) -> {a, 1000, {b, 1000, null}};

get(_) -> [].



%% 注意：每个事件最后都要包含一个revert的事件用于恢复怪物的初始状态
%% 墨家钜子的事件
get_event(59505, a1) -> [{msg, "墨家钜子：烈火燎原！"}];
get_event(59505, a2) -> [{att_times, 3.78}, {career, 1}];
get_event(59505, b1) -> [{msg, "墨家钜子：冰封千里！"}];
get_event(59505, b2) -> [{att_times, 3.78}, {career, 2}];
get_event(59505, c1) -> [{msg, "墨家钜子：剧毒无双！"}];
get_event(59505, c2) -> [{att_times, 3.78}, {career, 3}];
%get_event(59505, d1) -> [{msg, "墨家钜子：蝮蛇突袭！"}];
%get_event(59505, d2) -> [{att_times, 1.83}, {att_type, 0}];
get_event(59505, e)  -> [{att, 3600}, {career, 0}];
get_event(59505, revert)  -> [{att, 3600}, {career, 0}]; %%还原怪物状态


%% 情缘副本一堆事件
get_event(23301, a) -> [{appointment, 5}];
get_event(23301, b) -> [{appointment_msg, 5}];
get_event(23301, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23302, a) -> [{appointment, 5}];
get_event(23302, b) -> [{appointment_msg, 5}];
get_event(23302, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23303, a) -> [{appointment, 5}];
get_event(23303, b) -> [{appointment_msg, 5}];
get_event(23303, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23304, a) -> [{appointment, 5}];
get_event(23304, b) -> [{appointment_msg, 5}];
get_event(23304, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23305, a) -> [{appointment, 5}];
get_event(23305, b) -> [{appointment_msg, 5}];
get_event(23305, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23306, a) -> [{appointment, 5}];
get_event(23306, b) -> [{appointment_msg, 5}];
get_event(23306, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23307, a) -> [{appointment, 5}];
get_event(23307, b) -> [{appointment_msg, 5}];
get_event(23307, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23308, a) -> [{appointment, 5}];
get_event(23308, b) -> [{appointment_msg, 5}];
get_event(23308, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23309, a) -> [{appointment, 5}];
get_event(23309, b) -> [{appointment_msg, 5}];
get_event(23309, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23310, a) -> [{appointment, 5}];
get_event(23310, b) -> [{appointment_msg, 5}];
get_event(23310, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23311, a) -> [{appointment, 5}];
get_event(23311, b) -> [{appointment_msg, 5}];
get_event(23311, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23312, a) -> [{appointment, 5}];
get_event(23312, b) -> [{appointment_msg, 5}];
get_event(23312, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23313, a) -> [{appointment, 5}];
get_event(23313, b) -> [{appointment_msg, 5}];
get_event(23313, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23314, a) -> [{appointment, 5}];
get_event(23314, b) -> [{appointment_msg, 5}];
get_event(23314, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23315, a) -> [{appointment, 5}];
get_event(23315, b) -> [{appointment_msg, 5}];
get_event(23315, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23316, a) -> [{appointment, 5}];
get_event(23316, b) -> [{appointment_msg, 5}];
get_event(23316, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(23317, a) -> [{appointment, 5}];
get_event(23317, b) -> [{appointment_msg, 5}];
get_event(23317, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23318, a) -> [{appointment, 5}];
get_event(23318, b) -> [{appointment_msg, 5}];
get_event(23318, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23319, a) -> [{appointment, 5}];
get_event(23319, b) -> [{appointment_msg, 5}];
get_event(23319, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23320, a) -> [{appointment, 5}];
get_event(23320, b) -> [{appointment_msg, 5}];
get_event(23320, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23321, a) -> [{appointment, 5}];
get_event(23321, b) -> [{appointment_msg, 5}];
get_event(23321, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23322, a) -> [{appointment, 5}];
get_event(23322, b) -> [{appointment_msg, 5}];
get_event(23322, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23323, a) -> [{appointment, 5}];
get_event(23323, b) -> [{appointment_msg, 5}];
get_event(23323, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23324, a) -> [{appointment, 5}];
get_event(23324, b) -> [{appointment_msg, 5}];
get_event(23324, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23325, a) -> [{appointment, 5}];
get_event(23325, b) -> [{appointment_msg, 5}];
get_event(23325, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23326, a) -> [{appointment, 5}];
get_event(23326, b) -> [{appointment_msg, 5}];
get_event(23326, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23327, a) -> [{appointment, 5}];
get_event(23327, b) -> [{appointment_msg, 5}];
get_event(23327, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23328, a) -> [{appointment, 5}];
get_event(23328, b) -> [{appointment_msg, 5}];
get_event(23328, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23329, a) -> [{appointment, 5}];
get_event(23329, b) -> [{appointment_msg, 5}];
get_event(23329, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23330, a) -> [{appointment, 5}];
get_event(23330, b) -> [{appointment_msg, 5}];
get_event(23330, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23331, a) -> [{appointment, 5}];
get_event(23331, b) -> [{appointment_msg, 5}];
get_event(23331, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23332, a) -> [{appointment, 5}];
get_event(23332, b) -> [{appointment_msg, 5}];
get_event(23332, revert)  -> [{att, 22}, {create_att, 0}]; %%还原怪物状

get_event(23333, a) -> [{appointment, 5}];
get_event(23333, b) -> [{appointment_msg, 5}];
get_event(23333, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23334, a) -> [{appointment, 5}];
get_event(23334, b) -> [{appointment_msg, 5}];
get_event(23334, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23335, a) -> [{appointment, 5}];
get_event(23335, b) -> [{appointment_msg, 5}];
get_event(23335, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23336, a) -> [{appointment, 5}];
get_event(23336, b) -> [{appointment_msg, 5}];
get_event(23336, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23337, a) -> [{appointment, 5}];
get_event(23337, b) -> [{appointment_msg, 5}];
get_event(23337, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23338, a) -> [{appointment, 5}];
get_event(23338, b) -> [{appointment_msg, 5}];
get_event(23338, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23339, a) -> [{appointment, 5}];
get_event(23339, b) -> [{appointment_msg, 5}];
get_event(23339, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23340, a) -> [{appointment, 5}];
get_event(23340, b) -> [{appointment_msg, 5}];
get_event(23340, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23341, a) -> [{appointment, 5}];
get_event(23341, b) -> [{appointment_msg, 5}];
get_event(23341, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23342, a) -> [{appointment, 5}];
get_event(23342, b) -> [{appointment_msg, 5}];
get_event(23342, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23343, a) -> [{appointment, 5}];
get_event(23343, b) -> [{appointment_msg, 5}];
get_event(23343, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23344, a) -> [{appointment, 5}];
get_event(23344, b) -> [{appointment_msg, 5}];
get_event(23344, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23345, a) -> [{appointment, 5}];
get_event(23345, b) -> [{appointment_msg, 5}];
get_event(23345, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23346, a) -> [{appointment, 5}];
get_event(23346, b) -> [{appointment_msg, 5}];
get_event(23346, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23347, a) -> [{appointment, 5}];
get_event(23347, b) -> [{appointment_msg, 5}];
get_event(23347, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23348, a) -> [{appointment, 5}];
get_event(23348, b) -> [{appointment_msg, 5}];
get_event(23348, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23349, a) -> [{appointment, 5}];
get_event(23349, b) -> [{appointment_msg, 5}];
get_event(23349, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23350, a) -> [{appointment, 5}];
get_event(23350, b) -> [{appointment_msg, 5}];
get_event(23350, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23351, a) -> [{appointment, 5}];
get_event(23351, b) -> [{appointment_msg, 5}];
get_event(23351, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23352, a) -> [{appointment, 5}];
get_event(23352, b) -> [{appointment_msg, 5}];
get_event(23352, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23353, a) -> [{appointment, 5}];
get_event(23353, b) -> [{appointment_msg, 5}];
get_event(23353, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23354, a) -> [{appointment, 5}];
get_event(23354, b) -> [{appointment_msg, 5}];
get_event(23354, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23355, a) -> [{appointment, 5}];
get_event(23355, b) -> [{appointment_msg, 5}];
get_event(23355, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23356, a) -> [{appointment, 5}];
get_event(23356, b) -> [{appointment_msg, 5}];
get_event(23356, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23357, a) -> [{appointment, 5}];
get_event(23357, b) -> [{appointment_msg, 5}];
get_event(23357, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23358, a) -> [{appointment, 5}];
get_event(23358, b) -> [{appointment_msg, 5}];
get_event(23358, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(23359, a) -> [{appointment, 5}];
get_event(23359, b) -> [{appointment_msg, 5}];
get_event(23359, revert)  -> [{att, 25}, {create_att, 0}]; %%还原怪物状

get_event(91001, a) -> [{appointment, 5}];
get_event(91001, b) -> [{appointment_msg, 5}];
get_event(91001, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(91002, a) -> [{appointment, 5}];
get_event(91002, b) -> [{appointment_msg, 5}];
get_event(91002, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(91003, a) -> [{appointment, 5}];
get_event(91003, b) -> [{appointment_msg, 5}];
get_event(91003, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(91004, a) -> [{appointment, 5}];
get_event(91004, b) -> [{appointment_msg, 5}];
get_event(91004, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(91005, a) -> [{appointment, 5}];
get_event(91005, b) -> [{appointment_msg, 5}];
get_event(91005, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(91006, a) -> [{appointment, 5}];
get_event(91006, b) -> [{appointment_msg, 5}];
get_event(91006, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(91007, a) -> [{appointment, 5}];
get_event(91007, b) -> [{appointment_msg, 5}];
get_event(91007, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(91008, a) -> [{appointment, 5}];
get_event(91008, b) -> [{appointment_msg, 5}];
get_event(91008, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(91009, a) -> [{appointment, 5}];
get_event(91009, b) -> [{appointment_msg, 5}];
get_event(91009, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(91010, a) -> [{appointment, 5}];
get_event(91010, b) -> [{appointment_msg, 5}];
get_event(91010, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(91011, a) -> [{appointment, 5}];
get_event(91011, b) -> [{appointment_msg, 5}];
get_event(91011, revert)  -> [{att, 20}, {create_att, 0}]; %%还原怪物状

get_event(_, _) -> [].
