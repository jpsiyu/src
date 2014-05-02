%%%------------------------------------------------
%%% File    : common.hrl
%%% Author  : xyao
%%% Created : 2011-06-14
%%% Description: 公共定义
%%%------------------------------------------------

%%错误处理
-define(DEBUG(F, A), util:log("debug", F, A, ?MODULE, ?LINE)).
-define(INFO(F, A), util:log("info", F, A, ?MODULE, ?LINE)).
-define(ERR(F, A), util:log("error", F, A, ?MODULE, ?LINE)).
-define(DEBUG1(F, A), util:errlog("debug", F, A, ?MODULE, ?LINE)).
-define(INFO1(F, A), util:errlog("info", F, A, ?MODULE, ?LINE)).
-define(ERR1(F, A), util:errlog("error", F, A, ?MODULE, ?LINE)).

%%数据库
-define(DB, gs_mysql_conn).

%%游戏逻辑用户发送进程个数
-define(SERVER_SEND_MSG, 1).
%%聊天用户发送进程个数
-define(CHAT_SEND_MSG, 1).
%%公共服务用户发送进程个数
-define(UNITE_SEND_MSG, 1).

%%每个场景管理个数
-define(SCENE_AGENT_NUM, 10).

-define(DIFF_SECONDS_1970_1900, 2208988800).
-define(DIFF_SECONDS_0000_1900, 62167219200).
-define(ONE_DAY_SECONDS,        86400).
%% 线路定义
-define(UNITE, 1).
-define(MAIN, 10).

%%无法回城的地图ID
-define(FORBIMAP, [999, 998, 994, 992, 224, 228, 230, 995,996,997,982,981]).

%% 需要全场景广播的非副本地图
-define(ALL_BROADCAST_MAP_LIST, [228]).     %% 姻缘厅

%% ETS
-define(SERVER_STATUS, server_status).                          %% 服务器信息
-define(ETS_NODE, ets_node).                                    %% 节点列表
-define(ETS_RELA_INFO, ets_rela_info).                          %% 好友资料
-define(ETS_HP_BAG, ets_hp_bag).                                %% 玩家血包ETS
-define(SECONDARY_PASSWORD, secondary_password).                %% 二级密码表
-define(ROLE_ACHIEVED_NAME, role_achieved_name).                %% 角色称号
-define(ACHIEVED_NAME, achieved_name).                          %% 称号数据
-define(ETS_TD_SCORE, ets_td_score).                            %% 塔防积分
-define(ETS_TOWER_REWARD, ets_tower_reward).                    %% 塔奖励
-define(ETS_LODE, ets_lode).                                    %% 矿脉
-define(ETS_PET_DUNGEON, ets_pet_dungeon).                      %% 宠物副本表.
-define(ETS_COIN_DUNGEON, ets_coin_dungeon).                    %% 铜币副本表.
-define(PRACTICE_OUTLINE, practice_outline).                    %% 离线经验托管
-define(PRACTICE, practice).                                    %% 离线挂机
-define(ETS_OLD_BUCK, ets_old_buck).                            %% 老玩家

%%boss列表
-define(BOSS, [99501,22043,98908,99008,30046,50045,60046,40046,60047,70023,98909,70046]).

%% 远征岛场景
%-define(TOWER_BEGIN_SCENEID, 401). % 远征岛起始场景
-define(TOWER_END_SCENEID, [300, 311]). % 远征岛结束场景

%%PK状态切换时间
-define(PK_CHANGE_TIME, 3600*1).
