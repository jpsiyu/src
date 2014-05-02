%%%--------------------------------------
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.7.19
%%% @Description: 卡号相关，例如触活
%%%--------------------------------------

%% 最长卡号
-define(CARD_MAX_LENGTH, 40).

%% 操作间隔秒数
-define(CARD_OPT_SPACE_TIME, 4).

%% 通过卡号查询记录
-define(sql_card_get_row, <<"SELECT `card_expire`, `gift_id`, `status` FROM `base_card` WHERE `card_no`='~s'">>).

%% 更新卡号记录
-define(sql_card_update, <<"UPDATE `base_card` SET  `player_id`=~p, `player_name`='~s', `player_time`=~p, `status`=~p WHERE `card_no`='~s'">>).
