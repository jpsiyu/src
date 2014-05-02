%%%--------------------------------------
%%% @Module  : pt_140
%%% @Author  : zzm
%%% @Email   : ming_up@163.com
%%% @Created : 2010.06.07
%%% @Description:  14玩家间关系信息
%%%--------------------------------------
-module(pt_140).
-export([read/2, write/2]).
-include("unite.hrl").
-include("scene.hrl").
%%注：1.去掉好友分组相关功能(2010.09.07)

%%
%%客户端 -> 服务端 ----------------------------
%%
%%解析模块错误码(本读方法只用来调试用)
read(14000, _) ->
    {ok, [1000]};

%%解析添加好友请求
%% read(14001, <<BId:32,Type:8>>) ->
%%     {ok, [BId,Type]};
read(14001, <<Num:16, Bin/binary>>) ->
    List = read_id_type_list(Bin, [], Num),
    {ok, List};

%%解析添加好友请求
read(14002, <<Num:16, Bin/binary>>) ->
    List = read_id_type_result_list(Bin, [], Num),
    {ok, List};

%%请求好友列表
read(14003, <<Type:8>>) ->
    {ok, [Type]};

%%请求删除好友
read(14004, <<Type:8, Num:16, Bin/binary>>) ->
    List = read_id_list(Bin, [], Num),
    {ok, [List,Type]};

%%请求更改好友关系
read(14005, <<IdB:32,Type:8>>) ->
    {ok, [IdB,Type]};

%%请求更改好友关系
read(14006, <<Bin/binary>>) ->
    {Name,_} = pt:read_string(Bin),
    {ok, [Name]};

%%获取好友分组列表 
read(14007, _R) ->
    {ok, _R};

%%删除好友分组
read(14008, <<Id:16>>) ->
    {ok, [Id]};

%%更改好友分组名字
read(14009, <<Id:16,Bin/binary>>) ->
    {Name,_} = pt:read_string(Bin),
    {ok, [Id,Name]};

%%更改好友所在分组
read(14010, <<IdB:32,Id:16>>) ->
    {ok, [IdB,Id]};

%%按昵称搜索在线玩家
read(14011, <<Bin/binary>>) ->
    {Name,_} = pt:read_string(Bin),
    {ok, [Name]};

%%解析添加好友请求
read(14012, <<BId:32>>) ->
    {ok, [BId]};

%%解析添加好友请求
read(14013, <<AId:32,Result:8>>) ->
    {ok, [AId,Result]};

%%解析添加好友请求
read(14014, <<BId:32>>) ->
    {ok, [BId]};

%%解析好友祝福
read(14016, <<Id:32,Lv:16,Type:8>>) ->
    {ok, [Id,Lv,Type]};

%%回赠领取
%% read(14018, <<Uid:32,Lv:16,Exp:32,Llpt:32,ExtExp:32,ExtLlpt:32,BackBlessType:8>>) ->
%%     {ok, [Uid,Lv,Exp,Llpt,ExtExp,ExtLlpt,BackBlessType]};
%%回赠领取
read(14018, <<Num:16, Bin/binary>>) ->
    List = read_bless_gift_list(Bin, [], Num),
    {ok, List};

read(14019, _) ->
    {ok, []};

read(14020, _) ->
    {ok, []};

read(14021, _) ->
    {ok, []};

read(14022, _) ->
    {ok, []};

read(14023, <<WantedId:32, GoodsTypeId:32>>) ->
    {ok, [WantedId, GoodsTypeId]};
read(14025, _) ->
    {ok, []};
    
read(14026, <<Enemy:32, Flag:8>>) ->
    {ok, [Enemy, Flag]};
read(14027, <<Type:8, Id:32, IsTick:8>>) ->
    {ok, [Type, Id, IsTick]};

read(14028, <<Bin/binary>>) ->
    {Name,Rest} = pt:read_string(Bin),
    {Wish,_} = pt:read_string(Rest),
    {ok, [Name,Wish]};

read(14030, <<Id:32, Num:16>>) ->
    {ok, [Id,Num]};

read(_Cmd, _R) ->
    {error, no_match}.

%%应答14模块错误码
write(14000, [ErrorCode]) ->
    Data = <<ErrorCode:32>>,
    {ok, pt:pack(14000, Data)};

%%应答添加好友请求
write(14001, [Id,Nick,Type,Lvl,Career,Realm,Sex,Image]) ->
    NickBin = pt:write_string(Nick),
    Data = <<Id:32,NickBin/binary,Type:8,Lvl:16,Career:8,Realm:8,Sex:8,Image:8>>,
    {ok, pt:pack(14001, Data)};

%%应答回应添加好友请求
write(14002, [BId,Nick,Lvl,Career,Result]) ->
    NickBin = pt:write_string(Nick),
    Data = <<BId:32,NickBin/binary,Lvl:16,Career:8,Result:8>>,
    {ok, pt:pack(14002, Data)};

%%应答好友列表请求
write(14003, [L,Type]) ->
    GLen = length(L),
    Data = write_data_14003(L,<<Type:8,GLen:16>>),
    {ok, pt:pack(14003, Data)};

%%应答删除好友
write(14004, [Flag]) ->
    Data = <<Flag:8>>,
    {ok, pt:pack(14004, Data)};

%%应答更改好友关系
write(14005, [Flag]) ->
    Data = <<Flag:8>>,
    {ok, pt:pack(14005, Data)};

%%新增好友分组
write(14006, [Flag]) ->
    Data = <<Flag:8>>,
    {ok, pt:pack(14006, Data)};

%%应答更改好友关系
write(14007, [L]) ->
    GLen = length(L),
    Data = lib_relationship:write_data_14007(L,<<GLen:16>>),
    {ok, pt:pack(14007, Data)};

%%应答删除好友分组
write(14008, [Flag]) ->
    Data = <<Flag:8>>,
    {ok, pt:pack(14008, Data)};

%%应答更改好友分组名字
write(14009, [Flag]) ->
    Data = <<Flag:8>>,
    {ok, pt:pack(14009, Data)};

%%应答更改好友分组名字
write(14010, [Flag]) ->
    Data = <<Flag:8>>,
    {ok, pt:pack(14010, Data)};

%%应答按昵称搜索在线玩家
write(14011, [L]) ->
    GLen = length(L),
    Data = lib_relationship:write_data_14011(L,<<GLen:16>>),
    {ok, pt:pack(14011, Data)};

%%应答添加好友请求
write(14012, [Id,Nick,Lvl,Career]) ->
    NickBin = pt:write_string(Nick),
    Data = <<Id:32,NickBin/binary,Lvl:16,Career:8>>,
    {ok, pt:pack(14012, Data)};

%%应答回应添加好友请求
write(14013, [BId,Nick,Lvl,Career,Result]) ->
    NickBin = pt:write_string(Nick),
    Data = <<BId:32,NickBin/binary,Lvl:16,Career:8,Result:8>>,
    {ok, pt:pack(14013, Data)};

%%应答更改好友分组名字
write(14014, [Flag]) ->
    Data = <<Flag:8>>,
    {ok, pt:pack(14014, Data)};

%% 好友升级祝福通知
write(14015, [Id,NickName,Lv,Sex,Carrer,Image,Rest_Bless_send,Realm]) ->
    NickNameBin = pt:write_string(NickName),
    Data = <<Id:32,NickNameBin/binary,Lv:16,Sex:8,Carrer:8,Image:8,Rest_Bless_send:8,Realm:8>>,
    {ok, pt:pack(14015, Data)};

write(14016, [Exp,Llpt,Cishu]) ->
    Data = <<Exp:32,Llpt:32,Cishu:8>>,
    {ok, pt:pack(14016, Data)};

write(14017, [Id,NickName,BlessType,Lv,Exp,Llpt,ExtExp,ExtLlpt,GiftId]) ->
    NickNameBin = pt:write_string(NickName),
    Data = <<Id:32,NickNameBin/binary,BlessType:8,Lv:16,Exp:32,Llpt:32,ExtExp:32,ExtLlpt:32,GiftId:32>>,
    {ok, pt:pack(14017, Data)};

write(14018, [Result,Uid,Lv]) ->
    Data = <<Result:8,Uid:32,Lv:16>>,
    {ok, pt:pack(14018, Data)};

write(14019, [IsExchange,Exp,Llpt,Bless_friend_used]) ->
    Data = <<IsExchange:8,Exp:32,Llpt:32,Bless_friend_used:8>>,
    {ok, pt:pack(14019, Data)};

write(14020, [Flag]) ->
    Data = <<Flag:8>>,
    {ok, pt:pack(14020, Data)};

write(14021, [Group_Id,
	      Group_name,
	      IdB,
	      Nickname,
	      Image,
	      _Lv,
	      Sex,
	      Realm,
	      Career,
	      Intimacy,
	      Closely,
	      Last_login_time
	     ]) ->
    case mod_disperse:call_to_unite(mod_chat_agent, lookup, [IdB]) of
	[] ->
	    Online_flag = 0,
	    Lv = _Lv,
	    SceneName = <<"">>;
	[Player] ->
	    Online_flag = 1,
	    Lv = Player#ets_unite.lv,
	    Scene = data_scene:get(Player#ets_unite.scene),
	    case is_record(Scene, ets_scene) of
		false-> SceneName = <<"">>;
		true-> SceneName = Scene#ets_scene.name
	    end
    end,
    SceneNameBin = pt:write_string(SceneName),
    Group_nameBin = pt:write_string(Group_name),
    NicknameBin = pt:write_string(Nickname),
    Data = <<Group_Id:16,
	     Group_nameBin/binary,
	     Online_flag:8,
	     IdB:32,
	     NicknameBin/binary,
	     Image:8,
	     Lv:16,
	     Sex:8,
	     Realm:8,
	     Career:8,
	     Intimacy:32,
	     Closely:8,
	     SceneNameBin/binary,
	     Last_login_time:32>>,
    {ok, pt:pack(14021, Data)};

write(14022, [Bless_friend_used]) ->
    Data = <<Bless_friend_used:8>>,
    {ok, pt:pack(14022, Data)};

write(14023, [Result, SceneName]) ->
    SceneNameBin = pt:write_string(SceneName),
    Data = <<Result:8, SceneNameBin/binary>>,
    {ok, pt:pack(14023, Data)};

write(14024, [PlayerId, OnlineFlag]) ->
    Data = <<PlayerId:32, OnlineFlag:8>>,
    {ok, pt:pack(14024, Data)};

write(14025, [EnemyList]) ->
    Len = length(EnemyList),
    EnemyBin = list_to_binary([<<Enemy:32>> || Enemy <- EnemyList]),
    Data = <<Len:16, EnemyBin/binary>>,
    {ok, pt:pack(14025, Data)};

write(14026, [Flag, EnemyList]) ->
    Len = length(EnemyList),
    EnemyBin = [<<Enemy:32>> || Enemy <- EnemyList],
    Data = <<Flag:8, Len:16, EnemyBin/binary>>,
    {ok, pt:pack(14026, Data)};

%%应答删除好友
write(14027, [Flag]) ->
    Data = <<Flag:8>>,
    {ok, pt:pack(14027, Data)};

write(14028, [Error]) ->
    Data = <<Error:8>>,
    {ok, pt:pack(14028, Data)};

write(14029, [Id,_Name,_Wish]) ->
    Name = pt:write_string(_Name),
    Wish = pt:write_string(_Wish),
    Data = <<Id:32, Name/binary, Wish/binary>>,
    {ok, pt:pack(14029, Data)};

write(14030, [Error]) ->
    Data = <<Error:8>>,
    {ok, pt:pack(14030, Data)};

write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.

write_data_14003([],Bin)->Bin; 
write_data_14003(R,Bin)->
    [H|T] = R,
    {Group_Id,
        Group_name,
        IdB,
        Nickname,
        Image,
        Online_flag,
        Lv,
        Vip,
        _Scene,
        Sex,
        Realm,
        Career,
        Intimacy,
        Closely,
        KilledByEnemy,
        HatredValue,
        Wanted,
        Last_login_time,
        Longitude,
        Latitude
    } = H,
    Scene = data_scene:get(_Scene),
    case is_record(Scene, ets_scene) of
	false-> SceneName = <<"">>;
	true-> SceneName = Scene#ets_scene.name
    end,
    SceneNameBin = pt:write_string(SceneName),
    Group_nameBin = pt:write_string(Group_name),
    NicknameBin = pt:write_string(Nickname),
    TempBin = <<Group_Id:16,
		Group_nameBin/binary,
		Online_flag:8,
		IdB:32,
		NicknameBin/binary,
		Image:8,
		Lv:16,
		Sex:8,
		Realm:8,
		Career:8,
		Intimacy:32,
		Closely:8,
		SceneNameBin/binary,
		Last_login_time:32,
		Vip:8,
		HatredValue:16,
		KilledByEnemy:16,
		Wanted:8,
        Longitude:32/signed,
        Latitude:32/signed
        >>,
    write_data_14003(T,<<Bin/binary,TempBin/binary>>).


read_id_list(<<Id:32, Rest/binary>>, List, ListNum) when ListNum > 0 ->
    NewList = [{Id} | List],
    read_id_list(Rest, NewList, ListNum - 1);
read_id_list(_, List, _) -> List.

read_id_type_list(<<Id:32, Type:8, Rest/binary>>, List, ListNum) when ListNum > 0 ->
    NewList = [{Id, Type} | List],
    read_id_type_list(Rest, NewList, ListNum - 1);
read_id_type_list(_, List, _) -> List.

read_id_type_result_list(<<Id:32, Type:8, Result:8, Rest/binary>>, List, ListNum) when ListNum > 0 ->
    NewList = [{Id, Type, Result} | List],
    read_id_type_result_list(Rest, NewList, ListNum - 1);
read_id_type_result_list(_, List, _) -> List.

read_bless_gift_list(<<Uid:32, Lv:16, Exp:32, Llpt:32, ExtExp:32, ExtLlpt:32, BackBlessType:8, Rest/binary>>, List, ListNum) when ListNum > 0 ->
    NewList = [{Uid, Lv, Exp, Llpt, ExtExp, ExtLlpt, BackBlessType} | List],
    read_bless_gift_list(Rest, NewList, ListNum - 1);
read_bless_gift_list(_, List, _) -> List.
