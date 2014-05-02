%%% -------------------------------------------------------------------
%%% Author  : zengzhaoyuan
%%% Description :
%%%
%%% Created : 2012-6-12
%%% -------------------------------------------------------------------
-module(mod_chat_bugle_call).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% External exports
-export([start_link/0,
		 stop/0,
		get_list_size/0,
		put_element/1,
		remove_msg/1,
		execute_send_one/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-include("chat.hrl").
-include("guild.hrl").
-define(TIMEOUT_CT, 15*1000). %15秒一刷

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

stop() ->
    gen_server:call({local,?MODULE}, stop).

%% ====================================================================
%% Server functions
%% ====================================================================
%%获取号角消息队列大小
get_list_size()->
	gen_server:call(?MODULE, {get_list_size}).

%%添加号角消息
put_element(Element)->
	gen_server:cast(?MODULE, {put_element,Element}).

%%发送队列头号角消息
execute_send_one()->
	gen_server:cast(?MODULE, {execute_send_one}).

%%清楚消息队列中指定玩家消息
remove_msg(RoleId)->
	gen_server:cast(?MODULE, {remove_msg, RoleId}).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {ok, []}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({get_list_size}, _From, State) ->
    Reply = length(State),
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({put_element,Element}, State) ->
	{noreply, State++[Element]};

handle_cast({execute_send_one}, State) ->
	case State of
		[]->
			{noreply, State};
		[H|T]->
			{ok,DataBin} = pt_110:write(11032, [H#call.id, 			%角色ID
											  H#call.nickname,		%角色名
											  H#call.realm,			%阵营
											  H#call.sex,			%性别
											  H#call.color,			%颜色
											  H#call.content,		%内容
											  H#call.gm,			%GM
											  H#call.vip,			%VIP
											  H#call.work,			%职业
											  H#call.type,			%喇叭类型  0飞天号角 1冲天号角 2生日号角 3新婚号角 4帮宴传音 5新年号角
											  H#call.image,         %头像ID
											  H#call.ringfashion    %戒指时装
										  ]),							
            case H#call.channel of
				0 ->
					lib_unite_send:send_to_all(DataBin);
				3 ->
					lib_unite_send:send_to_scene(?GUILD_SCENE, H#call.channel_id, DataBin);
				_ -> skip
			end,
			case H#call.type of 
				1 -> mod_chat_bugle_call_timer:set_time(?TIMEOUT_CT);
				5 -> mod_chat_bugle_call_timer:set_time(?TIMEOUT_CT);
				_ -> skip
			end,				
			{noreply, T}
	end;

handle_cast({remove_msg, RoleId}, State) ->
	case State of
		[] ->
			{noreply, State};
		State ->			
			NewState = delete_msg(State, RoleId, State),		
			{noreply, NewState}
	end;

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

delete_msg([], _RoleId, State) -> State;
delete_msg([H|T], RoleId, State) ->
	case H#call.id =:= RoleId of
		true -> delete_msg(T, RoleId, T);
		false -> delete_msg(T, RoleId, State)
	end.

