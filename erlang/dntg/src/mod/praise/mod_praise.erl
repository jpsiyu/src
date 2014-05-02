%%%--------------------------------------
%%% @Module  : mod_praise
%%% @Author  : huangwenjie
%%% @Email   : huangwenjie@jieyoumail.com
%%% @Created : 2014.3.21
%%% @Description:  点赞功能
%%%--------------------------------------

-module(mod_praise).
-include("server.hrl").
-include("common.hrl").
-include("praise.hrl").
-compile(export_all).

start_link() ->
    gen_server:start_link(?MODULE, [], []).

stop(Pid) ->
    case is_pid(Pid) andalso is_process_alive(Pid) of 
        true ->
            gen_server:cast(Pid, stop);
        false ->
            skip
    end.

%% 上线读取玩家点赞信息
%% @param: PlayerId(玩家Id),Pid(玩家点赞进程)
role_login(PlayerId, Pid) ->
    gen_server:cast(Pid, {role_login, PlayerId}).

%% 点赞
increment_praise(Pid, SendId, SendName, TargetId, OldNum, TargetName) ->
    gen_server:call(Pid, {increment_praise, SendId, SendName, TargetId, OldNum, TargetName}).

init([]) ->
    {ok, #praise_state{}}.

handle_cast({role_login, PlayerId}, State) ->
    Sql = io_lib:format(<<"select B_id, B_name from player_praise where A_id = ~p">>, [PlayerId]),
    case db:get_all(Sql) of 
        [] ->
            NewState = State;
        All ->
            NewState = private_make_init_state(All, State)
    end,
    {noreply, NewState};

handle_cast(_Msg, State) -> 
    {noreply, State}.

handle_call({increment_praise, SendId, SendName, TargetId, OldNum, TargetName}, _From, State) ->
    GetDict = State#praise_state.get_dict,
    case dict:is_key(SendId, GetDict) of 
        true -> 
            {ok, BinData} = pt_130:write(13081, [2, 0]),
            lib_server_send:send_to_uid(SendId, BinData),
            NewNum = OldNum,
            NewState = State;
        false ->
            %% 写数据库
            Sql = io_lib:format(<<"update player_pt set get_praise = ~p + 1 where id = ~p">>, [OldNum,TargetId]),
            db:execute(Sql), 
            Sql2 = io_lib:format(<<"insert into player_praise (A_id, A_name, B_id, B_name) values (~p, '~s', ~p, '~s')">>, [TargetId, TargetName, SendId, SendName]),
            db:execute(Sql2),
            NewMember = #praise_member{
                id = SendId,
                name = SendName
                },
            NewGetDict = dict:append(SendId, NewMember, GetDict),
            NewNum = OldNum + 1,
            NewState = State#praise_state{get_dict = NewGetDict},
            {ok, BinData} = pt_130:write(13081, [1, NewNum]),
            lib_server_send:send_to_uid(SendId, BinData)
    end,
    {reply, NewNum, NewState};


handle_call(_Request, _From, State) -> 
    Reply = ok,
    {reply, Reply, State}.

handle_info(_Event, State) -> 
    {noreply, State}.

terminate(_Reason, _State) -> 
    ok.

code_change(_OldVsn, State, _Extra) -> 
    {ok, State}.

%% 记录谁赞过我
private_make_init_state([], State) -> State;
private_make_init_state([[B_id, B_name]|T], State) ->
     PraiseRecord = #praise_member{
        id = B_id,
        name = B_name
     }, 
     GetDict = State#praise_state.get_dict,
     NewGetDict = dict:append(B_id, PraiseRecord, GetDict),
     NewState = State#praise_state{get_dict = NewGetDict},
     private_make_init_state(T, NewState).






    


    