-module(test_team).
-compile(export_all).

start() ->
    case gen_tcp:connect("localhost", 9010, [binary, {packet, 0}]) of
        {ok, Socket1} ->
            gen_tcp:send(Socket1, <<"<policy-file-request/>\0">>),
            rec(Socket1),
            gen_tcp:close(Socket1);
        {error, _Reason1} ->
            io:format("connect failed!~n")
	end,
    case gen_tcp:connect("localhost", 9010, [binary, {packet, 0}]) of
		{ok, Socket} ->
			login(Socket),
            enter(Socket),
			create_team(Socket),
			rec(Socket),
			rec(Socket),
			rec(Socket),
			rec(Socket),
			%invite_req(Socket),
			%kickout(Socket),
			change_scene(Socket),
			rec(Socket),
			rec(Socket),
			rec(Socket),
			rec(Socket),
			gen_tcp:send(Socket, <<4:16, 12030:16>>),
			loop_rec(Socket),
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
	%io:format("keep_alive~n"),
    L = byte_size(<<1:16, 10006:16>>),
    gen_tcp:send(Socket, <<L:16, 10006:16>>),
	%rec(Socket),
    timer:sleep(5000),
    keep_alive(Socket).
loop_rec(Socket) ->
	rec(Socket),
	loop_rec(Socket).
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
            %io:format("recv : ~p~n", [10006]);
			skip;
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
			{Result, TeamName} = pt_240_c:read(24000, Bin),
			io:format("Result[~p] TeamName[~p]~n", [Result, TeamName]);
		{tcp, Socket, <<_L:16, 24003:16, Bin/binary>>} ->
			{Id, Lv, Career, Realm, Name} = pt_240_c:read(24003, Bin),
			io:format("Id[~p], Lv[~p], Career[~p], Realm[~p], Name[~p]~n", [Id, Lv, Career, Realm, Name]),
			{ok, BinData} = pt_240_c:write(24004, [1, Id]),
			gen_tcp:send(Socket, BinData);
		{tcp, Socket, <<_L:16, 24004:16, Bin/binary>>} ->
			<<Res:16>> = Bin,
			io:format("24004 Res[~p]~n", [Res]);
		{tcp, Socket, <<_L:16, 24006:16, Bin/binary>>} ->
			<<Res:16>> = Bin,
			io:format("24006 Res[~p]~n", [Res]);
		{tcp, Socket, <<_L:16, 24009:16, Bin/binary>>} ->
			<<Res:16>> = Bin,
			io:format("24009 Res[~p]~n", [Res]);
		{tcp, Socket, <<_L:16, 12005:16, Bin/binary>>} ->
			{SceneId, X, Y, SceneName, Sid} = pt_240_c:read(12005, Bin),
			io:format("SceneId[~p], X[~p], Y[~p], SceneName[~p], Sid[~p]~n", [SceneId, X, Y, SceneName, Sid]);
		{tcp, Socket, <<_L:16, _Cmd:16, _Bin/binary>>} ->
            io:format("recv : Cmd [~p]~n", [_Cmd]);
        {tcp_closed, Socket} ->
            gen_tcp:close(Socket)%,
			%erlang:exit(1)
	%after 500 ->
    %    ok
    end.

create_team(Socket) ->
	{ok, BinData} = pt_240_c:write(24000, ["九纵"]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

invite_req(Socket) ->
	{ok, BinData} = pt_240_c:write(24006, [4]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket),
	rec(Socket),
    rec(Socket),
	rec(Socket),
    rec(Socket),
	rec(Socket),
    rec(Socket).

kickout(Socket) ->
	{ok, BinData} = pt_240_c:write(24009, [4]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).

change_scene(Socket) ->
	{ok, BinData} = pt_240_c:write(12005, [450]),
    gen_tcp:send(Socket, BinData),
    rec(Socket),
    rec(Socket).