-module(pt_240_c).
-compile(export_all).

write(24000, [TeamName]) ->
	Data = pt:write_string(TeamName),
	{ok, pt:pack(24000, Data)};
write(24002, [Id]) ->
	Data = <<Id:32>>,
	{ok, pt:pack(24002, Data)};
write(24004, [Res, Uid]) ->
	Data = <<Res:16, Uid:32>>,
	{ok, pt:pack(24004, Data)};
write(24005, []) ->
	{ok, pt:pack(24005, <<>>)};
write(24006, [Uid]) ->
	Data = <<Uid:32>>,
	{ok, pt:pack(24006, Data)};
write(24008, [LeaderId, Res]) ->
	Data = <<LeaderId:32, Res:16>>,
	{ok, pt:pack(24008, Data)};
write(24009, [Uid]) ->
	Data = <<Uid:32>>,
	{ok, pt:pack(24009, Data)};
write(12005, [SceneId]) ->
	Data = <<SceneId:32>>,
	{ok, pt:pack(12005, Data)};
write(12030, []) ->
	{ok, pt:pack(12030, <<>>)};
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

read(24000, Bin) ->
	<<Result:16, Bin1/binary>> = Bin,
	{TeamName, _Res} = pt:read_string(Bin1),
	{Result, TeamName};
read(24002, <<Result:16>>) ->
	Result;
read(24003, Bin) ->
	<<Id:32, Lv:16, Career:16, Realm:16, Bin2/binary>> = Bin,
	{Name, _Res} = pt:read_string(Bin2),
	{Id, Lv, Career, Realm, Name};
read(24004, <<Res:16>>) ->
	Res;
read(24007, Bin) ->
	<<LeaderId:32, Bin2/binary>> = Bin,
	{LeaderName, Bin3} = pt:read_string(Bin2),
	{TeamName, _Res} = pt:read_string(Bin3),
	{LeaderId, LeaderName, TeamName};
read(12005, Bin) ->
	<<SceneId:32, X:16, Y:16, Bin2/binary>> = Bin,
	{SceneName, Bin3} = pt:read_string(Bin2),
	<<Sid:32, _Res/binary>> = Bin3,
	{SceneId, X, Y, SceneName, Sid};
read(_Cmd, _R) ->
    {error, no_match}.