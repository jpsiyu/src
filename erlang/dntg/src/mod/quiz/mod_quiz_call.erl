%%------------------------------------------------------------------------------
%% @Module  : mod_quiz_call
%% @Author  : liangjianxiong
%% @Email   : ljianxiong@qq.com
%% @Created : 2012.5.31
%% @Description: 答题服务器handle_call处理
%%------------------------------------------------------------------------------

-module(mod_quiz_call).
-include("quiz.hrl").
-export([handle_call/3]).

%% 得到答题的状态.
handle_call({get_state}, _From, Status) ->
    {reply, {ok, Status#quiz_state.state}, Status};

%% 使用放大镜.
handle_call({use_scale, RoleId}, _From, Status) ->
	
	%1.检查道具是否用完.
    NewScale = 
		case ets:lookup(?ETS_QUIZ_MEMBER, RoleId) of
			[RoleMember] ->
				Scale = RoleMember#quiz_member.scale, 
				case Scale > 0 of
					true ->
						ets:insert(?ETS_QUIZ_MEMBER, RoleMember#quiz_member{scale = Scale - 1}),
						Scale;
					_ ->
						Scale
				end;
			_ ->
				0
		end,
	
    Return = 
		if 
			NewScale > 0 ->
				case Status#quiz_state.count of
					%若原有四个选项，去掉两个错误选项.
					4 -> 
						TotalList = util:list_shuffle([1, 2, 3, 4]),
						DeleteList = lists:delete(Status#quiz_state.righ_option, TotalList),
						[_Num1|DeleteList2] = DeleteList,
						[1, DeleteList2];
					
					%若原有三个选项，去掉一个错误选项.
					3 -> 
						TotalList = util:list_shuffle([1, 2, 3]),
						DeleteList = lists:delete(Status#quiz_state.righ_option, TotalList),
						[_Num1|DeleteList2] = DeleteList,				
						[1, DeleteList2];

					%若原有两个选项，去掉一个错误选项.
					2 -> 
						DeleteList = lists:delete(Status#quiz_state.righ_option, [1, 2]), 
						[1, DeleteList];
					_ -> 
						[0, []]
				end;
			true ->
				[0, []]
		end,	
    	
	%发给玩家.
	{ok, BinData} = pt_490:write(49009, Return),
	lib_quiz:send_to_uid(RoleId, BinData),

    {reply, ok, Status};

%% 默认匹配
handle_call(Event, _From, Status) ->
    catch util:errlog("mod_quiz:handle_call not match: ~p", [Event]),
    {reply, ok, Status}.