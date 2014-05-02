%%%------------------------------------------------
%%% File    : mail.erl
%%% Author  : zhenghehe
%%% Created : 2012-02-01
%%% Description: 信件record定义
%%%------------------------------------------------
%%---------------------------------邮件ETS宏定义---------------------------------
%%-define(ETS_MAIL, ets_mail). %%  邮件 已经取消
%%---------------------------------邮件ETS宏定义---------------------------------
%% 发信及提取附件ErrorCode
-define(OTHER_ERROR,           0).  %% 其它错误

%% 发信ErrorCode
-define(WRONG_TITLE,           2).  %% 标题错误
-define(WRONG_CONTENT,         3).  %% 内容错误
-define(CANNOT_SEND_ATTACH,    4).  %% 不能发送附件
-define(WRONG_NAME,            5).  %% 无合法收件人
-define(NOT_ENOUGH_COIN,       7).  %% 金钱不足
-define(GOODS_NUM_NOT_ENOUGH,  8).  %% 物品数量不足
-define(GOODS_NOT_EXIST,       9).  %% 物品不存在
-define(GOODS_NOT_IN_PACKAGE, 10).  %% 物品不在背包
-define(ATTACH_CANNOT_SEND,   11).  %% 附件不能发送
-define(TITLE_SENSITIVE,      12).  %% 标题存在非法字符
-define(CONTENT_SENSITIVE,    13).  %% 内容存在非法字符
-define(MAX_TIMES,            14).  %% 达到今天最大发送量
-define(BLACKLIST,            15).  %% 在对方黑名单中
-define(CANNOT_SEND_TO_SELF,  17).  %% 不能向自己发送附件

%% 提取附件ErrorCode
-define(NOT_ENOUGH_SPACE,      2).  %% 背包已满
-define(ATTACH_NOT_EXIST,      3).  %% 信件中不存在附件
-define(GOODS_NOT_EXIST_2,     4).  %% 信件中物品不存在

-define(POSTAGE, 50).               %% 邮资
-define(POSTAGE2, 100).             %% 带附件时的邮资

-define(MAX_NUM, 50).               %% 每个用户每天发送信件数量上限
-define(MAX_LOCK_NUM, 10).          %% 最大锁定数量
-define(DAILY_TYPE_MAIL, 1901).     %% 每日记录器中使用的类型
-define(TIME_LIMIT, 86400 * 14).    %% 信件有效期，14天
-define(WARN_TIME, 86400 * 13).     %% 即将过期的警示时间，13天
-define(ESC_CHARS, ["'", "/" , "\"", "_", "<", ">"]).          %% 影响SQL语句的非法字符

%% 玩家上线检查邮件数量
-define(MAX_LEN_OF_MAILLIST, 800).  %% 上线时最大数量，超出则执行清理
-define(DEL_LEN, 50).               %% 清理的数量

%% 邮件防工作室检查
-define(MAIL_S_LIMIT, 20).  		%% 积分底线
-define(MAIL_C_LIMIT, 93).  		%% 金钱处理
-define(MAIL_DEADLINE, 50).         %% 人数上限 

%% 邮件_定义方式_不在定义的时候初始化任何数据
-define(Mail_Record_Def, {
        id,                 %% 邮件Id
        type,               %% 邮件类型
        state,              %% 邮件状态
        locked,             %% 锁定状态(1锁定/2未锁)
        timestamp,          %% 邮件时间戳
        sid,                %% 发件人Id
        sname,       		%% 发件人名字 (binary())，第一次读信时加载
        slv,           		%% 发件人等级，第一次读信时加载
        uid,                %% 收件人Id
        title,              %% 标题 (binary())
        content,     		%% 信件内容 (binary())，第一次读信时加载
        urls,          		%% 网址信息( [{UrlId, UrlName, Url}, ...] )，第一次读信时生成
        goods_id,           %% 物品标识（无物品为0）
        id_type,            %% 标识的类型（0物品Id/1类型Id）
        bind,           	%% 是否绑定（当id_type为1时有效）
        stren,          	%% 强化等级（当id_type为1时有效）
        prefix,         	%% 前缀（当id_type为1时有效）
        goods_type_id,      %% 物品类型ID（无物品为0，客户端显示图标需要）
        goods_num,          %% 物品数量
        bcoin,              %% 绑定铜币
        coin,               %% 铜币
        silver,             %% 绑定元宝
        gold                %% 元宝
    }).
%% 邮件_新定义方式_不在定义的时候初始化任何数据
-record(mail,?Mail_Record_Def).
