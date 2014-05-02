%% --------------------------------------------------------
%% @Module:           |pt_370
%% @Author:           |Wu Zhenhua
%% @Email:            |45517168@qq.com
%% @Created:          |2012-03-22
%% @Description:      |运势任务
%% --------------------------------------------------------
-module(pt_370).
-include("fortune.hrl").
-export([read/2, write/2]).

%%
%%客户端 -> 服务端 ----------------------------
%%

%% 取自己的运势信息
read(37000, <<Type:8>>) ->
    {ok, [Type]};

%% 取帮派成员的运势信息
read(37001, _) ->
    {ok, 2};

%% 刷新帮派成员的任务颜色
read(37002, <<Role_id:32>>) ->
    {ok, [Role_id]};

%% 取颜色刷新日志
read(37004, _R) ->
    {ok, 4};

%% 找他帮忙
read(37005, <<Role_id:32>>) ->
    {ok, Role_id};

%% 感谢信息通知
%read(37007, <<Role_id:32>>) ->
%    {ok, Role_id};

%% 感谢结果
read(37008, <<Role_id:32, Type:8>>) ->
    {ok, [Role_id, Type]};

%% 获取运势任务
read(37010, _) ->
    {ok, 100};

%% 刷新运势任务
read(37011, <<Type:8>>) ->
    {ok, [Type]};

%% 选择运势任务
read(37012, <<Sel:8>>) ->
    {ok, Sel};

%% 接取运势任务
read(37013, _R) ->
    {ok, 103};

%% 交运势任务
read(37016, <<TaskId:32>>) ->
    {ok, [TaskId]};

%%  
read(37017, _R) ->
    {ok, gold_refresh_task};

%%  
read(37018, _R) ->
    {ok, gold_finish_task};

%%  
read(37020, <<TaskId:32>>) ->
    {ok, [TaskId]};

%%  
read(37021, _) ->
    {ok, check};

%%  
read(37025, _) ->
    {ok, 37025};

read(_Cmd, _R) ->
    {error, no_match}.


%%
%%服务端 -> 客户端 ------------------------------------
%%


%% 取自己的运势信息
write(37000, [Res, Fortune_id, Color, Refresh_num, Task_id, Count, Refresh_time, Status, P1, P2, P3, PGoods,PGN,PPackage]) ->
	Info = <<Res:16
			 , Fortune_id:16
			   , Color:16
				 , Refresh_num:16
				   , Task_id:32
					 , Count:32
					   , Refresh_time:32
						 , Status:8
						   , P1:32
							 , P2:16
							   , P3:32
								 , PGoods:32
								   , PGN:8
									 , PPackage:32>>,
%% 	io:format("37000 ~n"),
    {ok, pt:pack(37000, Info)};

%% 取帮派成员的运势信息
write(37001, [FortuneList]) ->
	Bin = pack_37001(FortuneList),
%% 	io:format("37001 ~n"),
    {ok, pt:pack(37001, Bin)};

%% 刷新帮派成员的任务颜色
write(37002, [Res, RefreshNum, BrefreshNum, RefreshSpan]) ->
	Info = <<Res:16, RefreshNum:16, BrefreshNum:16, RefreshSpan:16>>,
%% 	io:format("37002 ~n"),
    {ok, pt:pack(37002, Info)};

%%  帮派成员的颜色信息更新通知
write(37003, [Refresh_role, Refresh_num, Role_id, Color, Brefresh_num, Task_id, Refresher, Brefresher]) ->
    Nick1 = list_to_binary(Refresher),
    Len1 = byte_size(Nick1),
    Nick2 = list_to_binary(Brefresher),
    Len2 = byte_size(Nick2),
%% 	io:format("37003 ~n"),
    {ok, pt:pack(37003, <<Refresh_role:32, Refresh_num:16, Role_id:32, Color:16, Brefresh_num:16, Task_id:32, Len1:16, Nick1/binary, Len2:16, Nick2/binary>>)};

%% 取颜色刷新日志
write(37004, LogList) ->
    ListBin = pack_37004(LogList),
%% 	io:format("ListBin ~p ~n", [ListBin]),
    {ok, pt:pack(37004, ListBin)};

%% 找他帮忙
write(37005, [Res, Span]) ->
	Info = <<Res:16, Span:16>>,
%% 	io:format("37005 ~n"),
    {ok, pt:pack(37005, Info)};

%% 找他帮忙信息通知
write(37006, Role_id) ->
	Info = <<Role_id:32>>,
%% 	io:format("37006 ~n"),
    {ok, pt:pack(37006, Info)};

%% 感谢信息通知
write(37007, [Role_id]) ->
	Info = <<Role_id:32>>,
%% 	io:format("37007 ~n"),
    {ok, pt:pack(37007, Info)};

%% 感谢信息通知
write(37008, [Res]) ->
	Info = <<Res:8>>,
%% 	io:format("37008 ~n"),
    {ok, pt:pack(37008, Info)};

%% 获取运势任务
write(37010, [Res, Task_id, Refresh_span]) ->
	Info = <<Res:16, Task_id:32, Refresh_span:32>>,
%% 	io:format("37010 ~n"),
    {ok, pt:pack(37010, Info)};

%% 刷新运势任务
write(37011, [Res, Refresh_task, Refresh_span]) ->
	Info = <<Res:16, Refresh_task:32, Refresh_span:32>>,
%% 	io:format("37011 ~n"),
    {ok, pt:pack(37011, Info)};

%% 选择运势任务
write(37012, [Res, Task_id, Refresh_task]) ->
	Info = <<Res:16, Task_id:32, Refresh_task:32>>,
%% 	io:format("37012 ~n"),
    {ok, pt:pack(37012, Info)};

%% 接取运势任务
write(37013, [Res, Task_id, Count, Refresh_task, Refresh_span, Status]) ->
	Info = <<Res:16, Task_id:32, Count:32, Refresh_task:32, Refresh_span:32, Status:8>>,
%% 	io:format("37013 ~n"),
    {ok, pt:pack(37013, Info)};

%% 运势任务统计数通知
write(37014, [Task_id, Count]) ->
	Info = <<Task_id:32, Count:32>>,
%% 	io:format("37014 ~n"),
    {ok, pt:pack(37014, Info)};

%% 完成运势任务通知
write(37015, Task_id) ->
	Info = <<Task_id:32>>,
%% 	io:format("37015 ~n"),
    {ok, pt:pack(37015, Info)};

%% 交运势任务
write(37016, [Res, TaskId, Status]) ->
	Info = <<Res:8, TaskId:32, Status:8>>,
%% 	io:format("37016 ~n"),
    {ok, pt:pack(37016, Info)};

%% 接受任务
write(37020,[Result])->
    {ok, pt:pack(37020, <<Result:8>>)};

%% 立即完成运势任务
write(37018, Res) ->
	Info = <<Res:16>>,
%% 	io:format("37018 ~n"),
    {ok, pt:pack(37018, Info)};

%% 立即完成运势任务
write(37021, [NumNow, NumNeeded]) ->
	Info = <<NumNow:16, NumNeeded:16>>,
    {ok, pt:pack(37021, Info)};

%% New
write(37025, [C]) ->
	Info = <<C:16>>,
    {ok, pt:pack(37025, Info)};



write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.


%% -----------------------------------------------------------------------------
%% *****************************************************************************
%% 		 打包区_对各种内容比较复杂的协议进行打包
%% *****************************************************************************
%% -----------------------------------------------------------------------------

%% -----------------------------------------------------------------
%% 打包37001
%% -----------------------------------------------------------------
pack_37001([]) ->
    <<0:16, <<>>/binary>>;
pack_37001(List) ->
    Rlen = length(List),
	F = fun(InfoD) ->
				case InfoD of
					[] ->
						<<>>;
					[RoleId, RoleColor, TaskColor, RefreshLeft, _RefreshColorTime,  BerefreshNum, TaskId, _Count, _Refresh_task, _Refresh_time, _, Status] ->
        				<<RoleId:32, RoleColor:16, TaskId:32, TaskColor:16, RefreshLeft:16, BerefreshNum:16, Status:8>>
				end
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.

%% -----------------------------------------------------------------
%% 打包37004
%% -----------------------------------------------------------------
pack_37004([]) ->
    <<0:16, <<>>/binary>>;
pack_37004(List) ->
    Rlen = length(List),
	F = fun([RoleId, TaskId, TaskColor, RefresherColor]) ->
        		<<RoleId:32, TaskId:32, TaskColor:16, RefresherColor:16>>
    end,
    RB = list_to_binary([F(D) || D <- List]),
    <<Rlen:16, RB/binary>>.
