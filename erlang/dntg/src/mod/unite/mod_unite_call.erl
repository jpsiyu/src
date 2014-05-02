%%%------------------------------------
%%% @Module  : mod_unite_call
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2011.12.16
%%% @Description: 公共服务call处理
%%%------------------------------------
-module(mod_unite_call).
-export([handle_call/3]).
-include("unite.hrl").
-include("common.hrl").
-include("server.hrl").


%%------------------------------------------------------------------------------
%% 							    基础功能  
%%------------------------------------------------------------------------------
%%获取用户信息
handle_call('base_data', _from, Status) ->
    {reply, Status, Status};

%%获取公共性状态单个属性
%%@param AttrName #unite_status的属性原子名称。
%%@return {error,Reson} | {ok,Value}
handle_call({get_unite_status_attr,AttrName}, _from, Status) ->
	case AttrName of
		_->Reply = {error,no_this_attr}
	end,
    {reply, Reply, Status};

%% %% 收到求婚回应
%% handle_call({'RECV_PROPOSE_RESPOND', WomanInfo}, _From, Status) ->
%%     [WomanId, WomanName, _Realm, _Sex, _Career] = WomanInfo,
%%     case ets:lookup(?ETS_PROPOSE, Status#unite_status.id) of
%%         [Propose] ->
%%             case Propose#propose.woman =:= WomanId of
%%                 true ->
%%                     PlayerStatus = lib_player:get_player_info(Status#unite_status.id),
%%                     case lib_couple:check_man_respond(PlayerStatus) of
%%                         ok ->
%%                             case lib_couple:marry(PlayerStatus, WomanInfo) of
%%                                 {ok, NewPlayerStatus} ->
%%                                     {ok, BinData} = pt_380:write(38004, [1, WomanId, WomanName]),
%%                                     lib_unite_send:send_to_sid(Status#unite_status.sid, BinData),
%%                                     lib_couple:notice_married_state(NewPlayerStatus),
%%                                     lib_mail:refresh_client(2, Status#unite_status.sid),   %% 刷新背包
%%                                     lib_player:update_player_status(NewPlayerStatus#player_status.id, NewPlayerStatus),
%%                                     ManName = NewPlayerStatus#player_status.nickname,
%%                                     {reply, {ok, ManName}, NewPlayerStatus};
%%                                 error ->
%%                                     {reply, {fail, 2}, Status}
%%                             end;
%%                         {error, Error} ->
%%                             {relay, {error, Error}, Status}
%%                     end;
%%                 false ->    %% 已向另一人求婚
%%                     {reply, {fail, 1}, Status}
%%             end;
%%         _ ->    %% 求婚已失效，包括一方下线过、已婚等情况
%%             {reply, {fail, 0}, Status}
%%     end;

%%------------------------------------------------------------------------------
%% 							    邮件相关功能  
%%------------------------------------------------------------------------------
handle_call({'save_one_mail', PlayerId, OneMail}, _from, Status) ->
	NewMailKey = "Mails_"++integer_to_list(PlayerId),
	OldMailList = case get(NewMailKey) of
		undefined -> 
			MailList = lib_mail:get_maillist_from_database(PlayerId),
			FormatMailList = [lib_mail:make_into_mail(MailInfo)||MailInfo<-MailList],
			put(NewMailKey,FormatMailList),
			FormatMailList;
		Value->
			Value
	end,
	NewMailList = [OneMail|OldMailList],
	put(NewMailKey,NewMailList),
    {reply, NewMailList, Status};

handle_call({'get_mail_all',PlayerId}, _from, Status) ->
	NewMailKey = "Mails_"++integer_to_list(PlayerId),
	NewMailList = case get(NewMailKey) of
		undefined -> 
			MailList = lib_mail:get_maillist_from_database(PlayerId),
			FormatMailList = [lib_mail:make_into_mail(MailInfo)||MailInfo<-MailList],
			put(NewMailKey,FormatMailList),
			FormatMailList;
		Value->
			Value
	end,
	%%	io:format("~n 3:: ~p~n~n!! 3::~p~n",[NewMailList,self()]),
    {reply, NewMailList, Status};

handle_call({'save_mail_all',NewMailKey, FormatMailList}, _from, Status) ->
	put(NewMailKey,FormatMailList),
    {reply, FormatMailList, Status};
handle_call({'delete_mail_all',NewMailKey}, _from, Status) ->
	OldMail = erase(NewMailKey),
    {reply, OldMail, Status};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_unite:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.
