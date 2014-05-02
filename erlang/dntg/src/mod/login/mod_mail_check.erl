%% --------------------------------------------------------
%% @Module:           |mod_mail_check
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012
%% @Description:      |邮件工作室检查
%% --------------------------------------------------------
-module(mod_mail_check).
-behaviour(gen_server).

-export([
		 one_mail/1
		, send_to_server_check_mail/1
		, mail_ban_check/1
		, stop_me/0
		, open_me/0
		]).

-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-include("server.hrl").
-include("unite.hrl").
-include("common.hrl").
-include("mail.hrl").
-include("record.hrl").


%% ====================================================================
%% Server functions
%% ====================================================================

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

init([]) ->
    {ok, []}.

%% 添加一个邮件检查
stop_me() ->
	make_cast(stop_me).

%% 添加一个邮件检查
open_me() ->
	make_cast(open_me).

%% 添加一个邮件检查
one_mail([SenderId, ReceiverId, GoodsId, Coin]) ->
	make_cast({one_mail, [SenderId, ReceiverId, GoodsId, Coin]}).

handle_call(_, _From, State) ->
    {reply, ok, State}.

%% 添加一个邮件检查
handle_cast({one_mail, [SenderId, ReceiverId, GoodsId, Coin]}, State) ->
	case get(stoped) of
		undefined ->
    		private_check([SenderId, ReceiverId, GoodsId, Coin]);
		stop_me ->
%% 			?INFO1("MailCheck was stopped ~n", []),
			skip;
		_ ->
			?INFO1("Error In Mail Check ~n", [])
	end,
    {noreply, State};
%% 关闭邮件检查功能
handle_cast(stop_me, State) ->
    put(stoped, stop_me),
    {noreply, State};
%% 启用邮件检查功能
handle_cast(open_me, State) ->
    put(stoped, undefined),
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% 内部方法
%% --------------------------------------------------------------------

%% 检查与处理
private_check([SenderId, ReceiverId, _GoodsId, _Coin]) ->
	case get(ReceiverId) of
		undefined ->
			EDict = dict:new(),
			OneDict = dict:store(SenderId, 1, EDict),
			put(ReceiverId, OneDict);
		Value ->
			SizeDict = dict:size(Value),
			case SizeDict >= ?MAIL_DEADLINE of
				true ->
					send_to_server_check_mail(ReceiverId),
					erlang:erase(ReceiverId);
				false ->
					case dict:find(SenderId, Value) of
						error ->
							NewDict = dict:store(SenderId, 1, Value),
							put(ReceiverId, NewDict);
						{ok, _} ->
							skip
					end
			end
	end.

send_to_server_check_mail(Id) ->
	case misc:get_player_process(Id) of
        Pid when is_pid(Pid) ->
            gen_server:cast(Pid, mail_ban_check);
        _ -> %% 查数据库处理
            db_ban_outline(Id)
    end.

%% 判断不知是否有效果
%% 此方法由游戏线调用
mail_ban_check(PS) ->
	ScoreNow = lib_anti_brush:get_anti_brush_score(PS),
	case ScoreNow >= ?MAIL_S_LIMIT orelse PS#player_status.is_pay =:= true of
		true ->
			skip;
		false ->
			spawn(fun() ->
						  Stime = util:rand(60 * 1000, 120 * 1000),
						  timer:sleep(Stime),
						  mod_disperse:cast_to_unite(lib_unite_send, send_to_uid,  [PS#player_status.id, close]),
    					  lib_server_send:send_to_uid(PS#player_status.id, close)
				  end),
			db_ban_login(PS#player_status.id)
	end.

%% 查充值/且封号
db_ban_outline(Id) ->
	SQL  = io_lib:format("SELECT `total` FROM player_recharge WHERE id=~p", [Id]),
    CZ = case db:get_one(SQL) of
		null -> 0;
		M -> M
	end, 
	case CZ > 0 of
		true ->
			skip;
		false ->
			db_ban_login(Id)
	end.

%% 更改指定玩家的数据库(封号)
db_ban_login(Id) ->
	Data = [1, Id],
	SQL  = io_lib:format("update player_login set status = ~p where id = ~p", Data),
    db:execute(SQL),
	%% 日志
	Info = data_mail_log_text:get_mail_log_text(log_ban_mail),
	NowTime = util:unixtime(),
	Data2 = [0, erlang:integer_to_list(Id), Info, NowTime, "AutoBan"],
	SQL2  = io_lib:format("insert into log_ban set type=~p, object='~s', description='~s', time=~p, admin='~s'", Data2),
    db:execute(SQL2).



%% --------------------------------------------------------------------
%%% 封装的方法 -不用改,不用看放到最后
%% --------------------------------------------------------------------

%% 同步调用
make_cast(Info)->
	case misc:whereis_name(global, ?MODULE) of
		Pid when is_pid(Pid) ->
			gen_server:cast(Pid, Info);
		_r ->
			[]
	end.

%% 同步调用
%% make_call(Info)->
%% 	case misc:whereis_name(global, ?MODULE) of
%% 		Pid when is_pid(Pid) ->
%% 			gen_server:call(Pid, Info, 5000);
%% 		_r ->
%% 			[]
%% 	end.