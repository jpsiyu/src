%%%------------------------------------
%%% @Module     : mod_mail
%%% @Author     : huangyongxing
%%% @Email      : huangyongxing@yeah.net
%%% @Created    : 2010.08.5
%%% @Description: 信件服务
%%%------------------------------------
-module(mod_mail).
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export(
    [
        start_link/0,
        clean_mail/0,
		log_mail_info/3,
        log_mail_info/5,
        log_get_money/5,
        update_mail_info/3,
        stop/0
    ]).
-include("common.hrl").
%% -include("record.hrl").
%% -include("mail.hrl").
-record(state, {
    }).

%%%------------------------------------
%%%             接口函数
%%%------------------------------------

%% 启动邮件服务
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% 清理过期邮件
clean_mail() ->
    gen_server:cast(?MODULE, 'clean_mail').

%% 记录邮件发送及消费信息
log_mail_info(PlayerStatus, NewStatus, MailInfo, Postage, Attachment) ->
    gen_server:cast(?MODULE, {'log_mail_info', PlayerStatus, NewStatus, MailInfo, Postage, Attachment}).

%% 记录邮件发送及消费信息
log_mail_info(MailInfo, Postage, Attachment) ->
    gen_server:cast(?MODULE, {'log_mail_info', MailInfo, Postage, Attachment}).

%% 记录收取货币附件
log_get_money(MailInfo, SId, Timestamp, PlayerStatus, NewStatus) ->
    gen_server:cast(?MODULE, {'log_get_money', MailInfo, SId, Timestamp, PlayerStatus, NewStatus}).

%% 更新在线玩家邮件信息
update_mail_info(PlayerId, MailInfoList, RoleInfo) ->
    gen_server:cast(?MODULE, {'update_mail_info', PlayerId, MailInfoList, RoleInfo}).

stop() ->
    gen_server:call(?MODULE, stop).

%%%------------------------------------
%%%             回调函数
%%%------------------------------------

init([]) ->
    process_flag(trap_exit, true),
    {ok, #state{} }.

handle_call(Request, From, State) ->
    mod_mail_call:handle_call(Request, From, State).

handle_cast(Msg, State) ->
    mod_mail_cast:handle_cast(Msg, State).

handle_info(Info, State) ->
    mod_mail_info:handle_info(Info, State).

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
