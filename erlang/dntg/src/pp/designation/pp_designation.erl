%%%--------------------------------------
%%% @Module  : pp_designation
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.4.19
%%% @Description: 称号
%%%--------------------------------------

-module(pp_designation).
-export([handle/3]).
-include("server.hrl").
-include("designation.hrl").

%% 查询称号列表
handle(34001, PS, RoleId) ->
	DesignList = lib_designation:get_all_by_role(RoleId),
    F = fun(RD) ->
                Id = RD#role_designation.design_id,
                Display = RD#role_designation.display,
                BaseDesign = data_designation:get_by_id(Id),
                if
                    BaseDesign =:= [] ->
                        <<>>;
                    true ->
                        
                        case BaseDesign#designation.type of
                            %% 如果是动态文字称号，需要替换
                            3 ->
                                Content = pt:write_string(io_lib:format(BaseDesign#designation.name, [RD#role_designation.content]));
                            _ ->
                                Content = pt:write_string("")
                        end,
                        <<Id:32, Display:8, Content/binary>>
                end
        end,
    NewList1 = [F(RD) || RD <- DesignList],
    NewList = [X || X <- NewList1, X /= <<>>],
    {ok, BinData} = pt_340:write(34001, [RoleId, NewList]),
    lib_server_send:send_to_sid(PS#player_status.sid, BinData);

%% 设置显示称号
handle(34002, PS, [DesignId, 1]) ->
	case lib_designation:set_display(PS, DesignId) of
		{error, ErrorCode} ->
			{ok, BinData} = pt_340:write(34002, [ErrorCode, DesignId, 0]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		{ok, NewPS} -> 
			{ok, BinData} = pt_340:write(34002, [6, DesignId, 1]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData),

			%% 广播头上的称号变化
			{ok, Bin} = pt_120:write(12096, [NewPS#player_status.id, NewPS#player_status.platform, NewPS#player_status.server_num, NewPS#player_status.designation]),
			lib_server_send:send_to_area_scene(NewPS#player_status.scene, NewPS#player_status.copy_id, NewPS#player_status.x, NewPS#player_status.y, Bin),

			{ok, NewPS}
	end;

%% 取消显示
handle(34002, PS, [DesignId, 0]) ->
	case lib_designation:set_hide(PS, DesignId, outside) of
		{error, ErrorCode} ->
			{ok, BinData} = pt_340:write(34002, [ErrorCode, DesignId, 0]),
			lib_server_send:send_to_sid(PS#player_status.sid, BinData);
		{ok, NewPS, SetType} ->
            ErrNum = case SetType == inside of
                true -> 50;
                _ -> 7
            end,
			{ok, BinData} = pt_340:write(34002, [ErrNum, DesignId, 0]),
           	lib_server_send:send_to_sid(PS#player_status.sid, BinData),

			{ok, NewPS}
	end;

handle(_, _, _) ->
    {error, "pp_designation no match"}.
