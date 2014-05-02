%%%------------------------------------------------
%%% File    : clusters.hrl
%%% Author  : xyao
%%% Created : 2011-06-13
%%% Description: 集群record
%%%------------------------------------------------

%% =========================跨服中心========================
-record(clusters_center, {
        node_list                  %% 跨服节点列表
    }).



%% =========================跨服节点========================

%% 重连跨服服务器间隔时间 （300秒）
-define(CONNECT_CENTER_TIME, 300000).

%% 跨服节点
-record(clusters_node, {
        center_node=none,           %% 跨服中心节点
        link = 0                    %% 是否连通(1连通，0不连通)
    }).