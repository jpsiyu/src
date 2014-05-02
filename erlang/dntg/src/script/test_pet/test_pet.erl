%%%---------------------------------------------
%%% @Module  : test_pet
%%% @Author  : zhenghehe
%%% @Created : 2012.01.18
%%% @Description: 宠物系统测试脚本
%%%---------------------------------------------
-module(test_pet).
-compile(export_all).

start() ->
    case gen_tcp:connect("localhost", 9011, [binary, {packet, 0}]) of
        {ok, Socket1} ->
            gen_tcp:send(Socket1, <<"<policy-file-request/>\0">>),
            rec(Socket1),
            gen_tcp:close(Socket1);
        {error, _Reason1} ->
            io:format("connect failed!~n")
	end,
    case gen_tcp:connect("localhost", 9011, [binary, {packet, 0}]) of
		{ok, Socket} ->
			login(Socket),
            enter(Socket),
			%timer:sleep(5000),
		    %get_pet_list(Socket),	
            %incubate_pet(Socket),
            %get_pet_info(Socket),
            %free_pet(Socket),
            %rename_pet(Socket),
            %fighting_pet(Socket),
            %rest_pet(Socket),
            %upgrade_pet(Socket),
            %start_change_figure(Socket),
            %end_change_figure(Socket),
            %enhance_aptitude_threshold(Socket),
            %manual_change_figure(Socket),
			create_team(Socket),
            ok;
		{error, _Reason} ->
            io:format("connect failed!~n")
	end.

%%登陆
login(Socket) ->
    L = byte_size( <<1:16,10000:16,2:32,1273027133:32,3:16,"htc",32:16,"b33d9ace076ca0ac7a8afa56923a03a4">>),
    gen_tcp:send(Socket, <<L:16,10000:16,2:32,1273027133:32,3:16,"htc",32:16,"b33d9ace076ca0ac7a8afa56923a03a4">>),
	rec(Socket).

%%选择角色进入
enter(Socket) ->
    gen_tcp:send(Socket, <<8:16,10004:16, 3:32>>),
	rec(Socket).

%%心跳包
keep_alive(Socket) ->
    L = byte_size(<<1:16, 10006:16>>),
    gen_tcp:send(Socket, <<L:16, 10006:16>>),
	rec(Socket),
    timer:sleep(5000),
    keep_alive(Socket).

rec(Socket) ->
    receive
        {tcp, Socket, <<"<cross-domain-policy><allow-access-from domain='*' to-ports='*' /></cross-domain-policy>">>} -> 
            io:format("revc : ~p~n", ["flash_file"]);
        {tcp, Socket, <<_L:16,Cmd:16, Bin:16>>} -> 
            io:format("revc : ~p~n", [[Cmd, Bin]]);
        {tcp, Socket, <<_L:16, 59004:16, Code:16>>} ->
            io:format("recv: ~p ~p~n", [59004, Code]);
        {tcp, Socket, <<_L:16, 10004:16, Code:8>>} ->
            io:format("revc : ~p~n", [[10004, Code]]),
            case Code =:= 1 of
                true ->
                    spawn(fun()->keep_alive(Socket)end);
                false ->
                    skip
            end;
        {tcp, Socket, <<_L:16, 10000:16, Uid:32>>} ->
            io:format("recv : ~p ~p~n", [10000, Uid]);
        {tcp, Socket, <<_L:16, 10003:16, Res:8, Uid:32>>} ->
            io:format("recv : ~p ~p ~p~n", [10003, Res, Uid]);
        {tcp, Socket, <<_L:16, 10006:16>>} ->
            skip;
		{tcp, Socket, <<_L:16, 12005:16, Bin/binary>>} ->
			{_Scene, _X, _Y, _Name, _Sid} = pt_400_c:read(12005, Bin),
			{ok, Bin1} = pt_400_c:write(12002, []),
			gen_tcp:send(Socket, Bin1),
    		rec(Socket),
    		rec(Socket);
		{tcp, Socket, <<_L:16, 12002:16, Bin/binary>>} ->
			io:format("12002 ~p~n", [Bin]);
        {tcp, Socket, <<_L:16, 41002:16, Bin/binary>>} ->
            io:format("recv : 41002~n"),
            {Error, _PlayerId, _MaxPetNum, _RecordNum, PetList} = pt_410_c:read(41002, Bin),
            case Error =:= 1 of
                true ->
                    F = fun({PetId, _PetName, _TypeId, _Level, _Quality, _Forza, _Wit, _Agile, _Thew, _UnallocAttr, _Aptitude, _Strength, _StrengthThreshold, _FightFlag, _FigureChangeFlag, _NewFigureChangeLeftTime, _HpLim, _MpLim, _Att, _Def, _Hit, _Dodge, _Crit, _Ten, _PetSkill, _NextLevelExp, _NextLevelLlpt, _EnhanceAptitudeCoin, _NewEnhanceAptitudeProbability, _MaxSkillNum, _Figure, _AptitudeThreshold, _NewUpgradeExp, _Growth, _Fire, _Ice, _Drug, _SavvyLv, _SavvyExp, _SavvyExpUpgrade, _MaxPotentialNum, _Potentials, _CombatPower}) ->
                    io:format("pet id [~p]~n", [PetId])
                end,
                lists:foreach(F, PetList);
                false ->
                    skip
            end;
        {tcp, Socket, <<_L:16, 41003:16, Bin/binary>>} ->
            {Error, PetId, PetName, GoodsTypeId} = pt_410_c:read(41003, Bin),
            io:format("Error[~p] PetId[~p] PetName[~p] GoodsTypeId[~p]~n", [Error, PetId, PetName, GoodsTypeId]);
        {tcp, Socket, <<_L:16, 41001:16, Bin/binary>>} ->
            {Error, Pet} = pt_410_c:read(41001, Bin),
            io:format("Error[~p] Pet[~p]~n", [Error, Pet]);
        {tcp, Socket, <<_L:16, 41004:16, Bin/binary>>} ->
            {Error, PetId} = pt_410_c:read(41004, Bin),
            io:format("Error[~p] PetId[~p]~n", [Error, PetId]);
        {tcp, Socket, <<_L:16, 41005:16, Bin/binary>>} ->
            {Error, PetId, NewPetName} = pt_410_c:read(41005, Bin),
            io:format("Error[~p] PetId[~p] NewPetName[~p]~n", [Error, PetId, NewPetName]);
        {tcp, Socket, <<_L:16, 41006:16, Bin/binary>>} ->
            {Error, PetId, HpLim, MpLim, Att, Def, Hit, Dodge, Crit, Ten} = pt_410_c:read(41006, Bin),
            io:format("Error[~p] PetId[~p] HpLim[~p] MpLim[~p] Att[~p] Def[~p] Hit[~p] Dodge[~p] Crit[~p] Ten[~p]~n", [Error, PetId, HpLim, MpLim, Att, Def, Hit, Dodge, Crit, Ten]);
        {tcp, Socket, <<_L:16, 41007:16, Bin/binary>>} ->
            {Error, PetId} = pt_410_c:read(41007, Bin),
            io:format("Error[~p] PetId[~p]~n", [Error, PetId]);
        {tcp, Socket, <<_L:16, 41008:16, Bin/binary>>} ->
            {Result, PetId, NewLevel, UnallocAttr, ExpLeft, LlptLeft, NextLevelExp, NextLevelLlpt, MaxPotentialNum} = pt_410_c:read(41008, Bin),
            io:format("Result[~p] PetId[~p] NewLevel[~p] UnallocAttr[~p] ExpLeft[~p] LlptLeft[~p] NextLevelExp[~p] NextLevelLlpt[~p] MaxPotentialNum[~p]~n", [Result, PetId, NewLevel, UnallocAttr, ExpLeft, LlptLeft, NextLevelExp, NextLevelLlpt, MaxPotentialNum]);
        {tcp, Socket, <<_L:16, 41016:16, Bin/binary>>} ->
            {Code, PetId, NewFigure, LeftTime, AttrChangeFlag} = pt_410_c:read(41016, Bin),
            io:format("Code[~p] PetId[~p] NewFigure[~p] LeftTime[~p] AttrChangeFlag[~p]~n", [Code, PetId, NewFigure, LeftTime, AttrChangeFlag]);
        {tcp, Socket, <<_L:16, 41017:16, Bin/binary>>} ->
            {Code, PetId, OriginFigure, NewFigure, ChangeType, AttrChangeFlag} = pt_410_c:read(41017, Bin),
            io:format("Code[~p] PetId[~p] OriginFigure[~p] NewFigure[~p] ChangeType[~p] AttrChangeFlag[~p]~n", [Code, PetId, OriginFigure, NewFigure, ChangeType, AttrChangeFlag]);
        {tcp, Socket, <<_L:16, 41022:16, Bin/binary>>} ->
            {Result, PetId, AptitudeThreshold} = pt_410_c:read(41022, Bin),
            io:format("Result[~p] PetId[~p] AptitudeThreshold[~p]~n", [Result, PetId, AptitudeThreshold]);
        {tcp, Socket, <<_L:16, 41030:16, Bin/binary>>} ->
            {Code, PetId, NewFigure, LeftTime, NewIntimacy, AttrChangeFlag} = pt_410_c:read(41030, Bin),
            io:format("Code[~p] PetId[~p] NewFigure[~p] LeftTime[~p] NewIntimacy[~p] AttrChangeFlag[~p]~n", [Code, PetId, NewFigure, LeftTime, NewIntimacy, AttrChangeFlag]);
        {tcp, Socket, <<_L:16, 24000:16, Bin/binary>>} ->
			{Result, TeamName} = pt_410_c:read(24000, Bin),
			io:format("Result[~p] TeamName[~p]~n", [Result, TeamName]);
		{tcp, Socket, <<_L:16, _Cmd:16, _Bin/binary>>} ->
            io:format("recv : Cmd [~p]~n", [_Cmd]);
        {tcp_closed, Socket} ->
            gen_tcp:close(Socket),
			erlang:exit(1)
	after 50000 ->
        ok
    end.

get_pet_list(Socket) ->
    {ok, BinData} = pt_410_c:write(41002, [3]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

incubate_pet(Socket) ->
    {ok, BinData} = pt_410_c:write(41003, [1, 1]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

get_pet_info(Socket) ->
    {ok, BinData} = pt_410_c:write(41001, [34743]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

free_pet(Socket) ->
    {ok, BinData} = pt_410_c:write(41004, [34743]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

rename_pet(Socket) ->
    {ok, BinData} = pt_410_c:write(41005, [34744, "小小小精灵"]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

fighting_pet(Socket) ->
    {ok, BinData} = pt_410_c:write(41006, [34744]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

rest_pet(Socket) ->
    {ok, BinData} = pt_410_c:write(41007, [34744]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

upgrade_pet(Socket) ->
    {ok, BinData} = pt_410_c:write(41008, [34744]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket),
    rec(Socket).

start_change_figure(Socket) ->
    {ok, BinData} = pt_410_c:write(41016, [34744, 2, 10]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

end_change_figure(Socket) ->
    {ok, BinData} = pt_410_c:write(41017, [34744]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

enhance_aptitude_threshold(Socket) ->
    {ok, BinData} = pt_410_c:write(41022, [34744, 3, 10]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

manual_change_figure(Socket) ->
    {ok, BinData} = pt_410_c:write(41030, [34744, 81]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

create_team(Socket) ->
	{ok, BinData} = pt_410_c:write(24000, ["九纵1"]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).
