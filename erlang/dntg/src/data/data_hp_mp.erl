
%%%---------------------------------------
%%% @Module  : data_hp_mp
%%% @Author  : xieyunfei
%%% @Email   : xieyunfei@jieyoumail.com
%%% @Created : 2014-03-03
%%% @Description:  气血和法力数据
%%%---------------------------------------
-module(data_hp_mp).
-export([get_hp_yaopin_cd_len/0,get_mp_yaopin_cd_len/0,get_bag_by_lv/1]).
-include("goods.hrl").

%% 气血类药品使用的冷却时间
%% @return 秒数
get_hp_yaopin_cd_len() ->
    YaoPinMsg=data_hp_bag:get(1),
    YaoPinMsg#base_hp_bag.reply_span.

%% 法力类药品使用的冷却时间
%% @return 秒数
get_mp_yaopin_cd_len() ->
    YaoPinMsg=data_hp_bag:get(2),
    YaoPinMsg#base_hp_bag.reply_span.

%% 获取玩家气血法力包的上限和单次回复值，被外表调用
%% @return [上限值,单次回复值]
get_bag_by_lv(RoleLv) ->
    BagData = data_hp_bag:get_bag_data(),
    get_bag_msg(RoleLv,BagData).

%% 获取玩家气血法力包的上限和单次回复值，被get_bag_by_lv/1 调用。
%% @return [上限值,单次回复值]
get_bag_msg(_RoleLv,[]) -> [0,0];
get_bag_msg(RoleLv,BagData) ->
    [[{LvMin, LvMax},BagMax,ReplyNum] | RestData] = BagData,
    case RoleLv >= LvMin andalso RoleLv =< LvMax of
        true ->
            [BagMax,ReplyNum];
        false ->
            get_bag_msg(RoleLv,RestData)
    end.

