%%%------------------------------------
%%% @Module  : mod_team_info
%%% @Author  : zhenghehe
%%% @Created : 2010.07.06
%%% @Description: 组队模块info
%%%------------------------------------
-module(mod_team_info).
-export([handle_info/2]).
-include("common.hrl").
-include("server.hrl").
-include("scene.hrl").
-include("team.hrl").

%% 仲裁结果处理.
handle_info({'arbitrate_result', N}, State) ->
	mod_team_dungeon:handle_info({'arbitrate_result', N}, State);

%% 玩家进程死了.
handle_info({'DEAD', Uid, Scene}, State) ->
	mod_team_base:handle_info({'DEAD', Uid, Scene}, State);

%% 没有匹配到的消息.
handle_info(_Info, State) ->
    {noreply, State}.

%% 掉落包拾取成功反馈
%handle_info({'CHOOSE_OK', DropId}, State) ->
%    Dchl = State#team.drop_choosing_l,
%    Dchsl = State#team.drop_choose_success_l,
%    NewState = case lists:member(DropId, Dchl) of
%        true -> 
%            case lists:member(DropId, Dchsl) of
%                true -> State#team{drop_choosing_l = Dchl -- [DropId]};
%                false -> 
%                    case length(Dchsl) >= 10 of
%                        true -> 
%                            [_H | T] = Dchsl,
%                            NewDchsl = T ++ [DropId],
%                            State#team{drop_choosing_l = Dchl -- [DropId], drop_choose_success_l = NewDchsl};
 %                       false -> 
 %                           NewDchsl = Dchsl ++ [DropId],
 %                           State#team{drop_choosing_l = Dchl -- [DropId], drop_choose_success_l = NewDchsl}
 %                   end
 %           end;
 %       false -> State
 %   end,
    %io:format("Dchl ~p, Dchsl:~p~n", [NewState#team.drop_choosing_l, NewState#team.drop_choose_success_l]),
  %  {noreply, NewState};

%% 掉落包失败反馈
%handle_info({'CHOOSE_FAIL', DropId}, State) ->
%    NewDchl = State#team.drop_choosing_l -- [DropId],
%    {noreply, State#team{drop_choosing_l = NewDchl}};