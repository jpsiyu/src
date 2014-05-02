%%%--------------------------------------
%%% @Module  : pt_44
%%% @Author  : shebiao
%%% @Email   : shebiao@jieyou.com
%%% @Created : 2010.10.12
%%% @Description: 师徒消息的解包和组包
%%%--------------------------------------
-module(pt_440).
-export([read/2, write/2]).

-define(SEPARATOR_STRING, "【】").

%%%=========================================================================
%%% 解包函数
%%%=========================================================================
%% -----------------------------------------------------------------
%% 师徒通知
%% -----------------------------------------------------------------
read(44000, <<_Bin/binary>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 获取伯乐榜
%% -----------------------------------------------------------------
read(44001, <<PageSize:16, PageNo:16>>) ->
    {ok, [PageSize, PageNo]};

%% -----------------------------------------------------------------
%% 获取师门信息
%% -----------------------------------------------------------------
read(44002, <<PageSize:16, PageNo:16>>) ->
    {ok, [PageSize, PageNo]};

%% -----------------------------------------------------------------
%% 获取徒弟列表
%% -----------------------------------------------------------------
read(44003, <<PageSize:16, PageNo:16>>) ->
    {ok, [PageSize, PageNo]};

%% -----------------------------------------------------------------
%% 登记上榜
%% -----------------------------------------------------------------
read(44004, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 取消上榜
%% -----------------------------------------------------------------
read(44005, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 搜索伯乐
%% -----------------------------------------------------------------
read(44006, <<Bin/binary>>) ->
    {MasterName, _} = pt:read_string(Bin),
    {ok, [MasterName]};

%% -----------------------------------------------------------------
%% 拜师申请
%% -----------------------------------------------------------------
read(44007, <<MasterId:32>>) ->
    {ok, [MasterId]};

%% -----------------------------------------------------------------
%% 拜师审批
%% -----------------------------------------------------------------
read(44008, <<MasterId:32, HandleResult:16>>) ->
    {ok, [MasterId, HandleResult]};

%% -----------------------------------------------------------------
%% 逐出师门
%% -----------------------------------------------------------------
read(44009, <<PlayerId:32>>) ->
    {ok, [PlayerId]};

%% -----------------------------------------------------------------
%% 退出师门
%% -----------------------------------------------------------------
read(44010, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 汇报成绩
%% -----------------------------------------------------------------
read(44012, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 出师
%% -----------------------------------------------------------------
read(44013, <<EvaluateType:8>>) ->
    {ok, [EvaluateType]};

%% -----------------------------------------------------------------
%% 师道值兑换经验
%% -----------------------------------------------------------------
read(44014, <<ExchangeType:8>>) ->
    {ok, [ExchangeType]};

%% -----------------------------------------------------------------
%% 拜师邀请
%% -----------------------------------------------------------------
read(44015, <<Bin/binary>>) ->
    {PlayerName, _} = pt:read_string(Bin),
    {ok, [PlayerName]};

%% -----------------------------------------------------------------
%% 邀请回应
%% -----------------------------------------------------------------
read(44016, <<MasterId:32, ResponseResult:8>>) ->
    {ok, [MasterId, ResponseResult]};

%% -----------------------------------------------------------------
%% 师傅推荐
%% -----------------------------------------------------------------
read(44017, <<>>) ->
    {ok, []};

%% -----------------------------------------------------------------
%% 取消收徒邀请
%% -----------------------------------------------------------------
read(44018, <<PlayerId:32>>) ->
    {ok, [PlayerId]};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
read(_Cmd, _R) ->
    {error, no_match}.

%%%=========================================================================
%%% 组包函数
%%%=========================================================================

%% -----------------------------------------------------------------
%% 拜师申请
%% 通知类型：0
%% 通知内容：申请人ID， 申请人昵称
%% -----------------------------------------------------------------
write(44000, [0, PlayerId, PlayerName]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<0:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 加入师门
%% 通知类型：1
%% 通知内容：师傅ID， 师傅昵称
%% -----------------------------------------------------------------
write(44000, [1, PlayerId, PlayerName]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<1:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 逐出师门
%% 通知类型：2
%% 通知内容：师傅ID， 师傅昵称
%% -----------------------------------------------------------------
write(44000, [2, PlayerId, PlayerName]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<2:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 退出师门
%% 通知类型：3
%% 通知内容：徒弟ID， 徒弟昵称
%% -----------------------------------------------------------------
write(44000, [3, PlayerId, PlayerName]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<3:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 背叛师门
%% 通知类型：4
%% 通知内容：徒弟ID， 徒弟昵称
%% -----------------------------------------------------------------
write(44000, [4, PlayerId, PlayerName]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<4:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 汇报成绩
%% 通知类型：0
%% 通知内容：徒弟ID， 徒弟昵称，增加经验，增加师道值
%% -----------------------------------------------------------------
write(44000, [5, PlayerId, PlayerName, ExpAdd, ScoreAdd]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    ExpAddList    = integer_to_list(ExpAdd),
    ScoreAddList  = integer_to_list(ScoreAdd),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, ExpAddList, ?SEPARATOR_STRING, ScoreAddList]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<5:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 出师
%% 通知类型：6
%% 通知内容：师傅ID， 师傅昵称，增加的师道值
%% -----------------------------------------------------------------
write(44000, [6, PlayerId, PlayerName, Num]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    NumList       = integer_to_list(Num),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, NumList]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<6:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 拜师申请被拒绝
%% 通知类型：7
%% 通知内容：师傅ID， 师傅昵称
%% -----------------------------------------------------------------
write(44000, [7, PlayerId, PlayerName]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<7:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 拜师申请被取消
%% 通知类型：8
%% 通知内容：徒弟ID， 徒弟昵称
%% -----------------------------------------------------------------
write(44000, [8, PlayerId, PlayerName]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<8:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 拜师邀请
%% 通知类型：9
%% 通知内容：师傅ID， 师傅昵称，线路，国家，等级
%% -----------------------------------------------------------------
write(44000, [9, PlayerId, PlayerName,Realm, Level]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    RealmList     = integer_to_list(Realm),
    LevelList     = integer_to_list(Level),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName, ?SEPARATOR_STRING, RealmList, ?SEPARATOR_STRING, LevelList]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<9:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 拜师邀请拒绝
%% 通知类型：10
%% 通知内容：徒弟ID， 徒弟昵称
%% -----------------------------------------------------------------
write(44000, [10, PlayerId, PlayerName]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<10:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 拜师邀请成功
%% 通知类型：11
%% 通知内容：徒弟ID， 徒弟昵称
%% -----------------------------------------------------------------
write(44000, [11, PlayerId, PlayerName]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<11:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 拜师邀请取消
%% 通知类型：12
%% 通知内容：师傅ID， 师傅昵称
%% -----------------------------------------------------------------
write(44000, [12, PlayerId, PlayerName]) ->
    PlayerIdList  = integer_to_list(PlayerId),
    MsgContentBin = list_to_binary([PlayerIdList, ?SEPARATOR_STRING, PlayerName]),
    MsgContentLen = byte_size(MsgContentBin),
    Data = <<12:16, MsgContentLen:16, MsgContentBin/binary>>,
    {ok, pt:pack(44000, Data)};

%% -----------------------------------------------------------------
%% 获取伯乐榜
%% -----------------------------------------------------------------
write(44001, [Code, PageTotal, PageNo, RecordNum, Records]) ->
    Data = <<Code:16, PageTotal:16, PageNo:16, RecordNum:16, Records/binary>>,
    {ok, pt:pack(44001, Data)};

%% -----------------------------------------------------------------
%% 获取师门信息
%% -----------------------------------------------------------------
write(44002, [Code, MasterName, MasterCareer, MasterLevel, MastrerApprenticeNum, PageTotal, PageNo, RecordNum, Records]) ->
    MasterNameLen = byte_size(MasterName),
    Data = <<Code:16, MasterNameLen:16, MasterName/binary, MasterCareer:16, MasterLevel:16, MastrerApprenticeNum:16, PageTotal:16, PageNo:16, RecordNum:16, Records/binary>>,
    {ok, pt:pack(44002, Data)};

%% -----------------------------------------------------------------
%% 获取徒弟列表
%% -----------------------------------------------------------------
write(44003, [Code, MasterName, MasterCareer, MasterLevel, MasterScore, ApprenticeNum, ApprenticeMaxNum, PageTotal, PageNo, RecordNum, Records]) ->
    MasterNameLen = byte_size(MasterName),
    Data = <<Code:16, MasterNameLen:16, MasterName/binary, MasterCareer:16, MasterLevel:16, MasterScore:32, ApprenticeNum:16, ApprenticeMaxNum:16, PageTotal:16, PageNo:16, RecordNum:16, Records/binary>>,
    {ok, pt:pack(44003, Data)};

%% -----------------------------------------------------------------
%% 登记上榜
%% -----------------------------------------------------------------
write(44004, Code) ->
    Data = <<Code:16>>,
    {ok, pt:pack(44004, Data)};

%% -----------------------------------------------------------------
%% 取消上榜
%% -----------------------------------------------------------------
write(44005, Code) ->
    Data = <<Code:16>>,
    {ok, pt:pack(44005, Data)};

%% -----------------------------------------------------------------
%% 搜索伯乐
%% -----------------------------------------------------------------
write(44006, [Code,PlayerID,PlayerName,Career,Level,Score,ApprenticeNum,Line,CreateTime,Sex,ApprenticeMaxNum,Image]) ->
    PlayerNameLen = byte_size(PlayerName),
    Data = <<Code:16,PlayerID:32,PlayerNameLen:16,PlayerName/binary,Career:16,Level:16,Score:32,ApprenticeNum:16,Line:16,CreateTime:32,Sex:8,ApprenticeMaxNum:16,Image:16>>,
    {ok, pt:pack(44006, Data)};

%% -----------------------------------------------------------------
%% 拜师申请
%% -----------------------------------------------------------------
write(44007, Code) ->
    Data = <<Code:16>>,
    {ok, pt:pack(44007, Data)};

%% -----------------------------------------------------------------
%% 拜师审批
%% -----------------------------------------------------------------
write(44008, [Code, ExpAdd, ScoreAdd]) ->
    Data = <<Code:16, ExpAdd:32, ScoreAdd:32>>,
    {ok, pt:pack(44008, Data)};

%% -----------------------------------------------------------------
%% 逐出师门
%% -----------------------------------------------------------------
write(44009, [Code, PlayerId]) ->
    Data = <<Code:16, PlayerId:32>>,
    {ok, pt:pack(44009, Data)};

%% -----------------------------------------------------------------
%% 退出师门
%% -----------------------------------------------------------------
write(44010, Code) ->
    Data = <<Code:16>>,
    {ok, pt:pack(44010, Data)};

%% -----------------------------------------------------------------
%% 汇报成绩
%% -----------------------------------------------------------------
write(44012, [Code, ExpNum]) ->
    Data = <<Code:16, ExpNum:32>>,
    {ok, pt:pack(44012, Data)};

%% -----------------------------------------------------------------
%% 出师
%% -----------------------------------------------------------------
write(44013, Code) ->
    Data = <<Code:16>>,
    {ok, pt:pack(44013, Data)};

%% -----------------------------------------------------------------
%% 师道值兑换经验
%% -----------------------------------------------------------------
write(44014, [Code, ScoreLeft]) ->
    Data = <<Code:16, ScoreLeft:32>>,
    {ok, pt:pack(44014, Data)};

%% -----------------------------------------------------------------
%% 拜师邀请
%% -----------------------------------------------------------------
write(44015, [Code]) ->
    Data = <<Code:16>>,
    {ok, pt:pack(44015, Data)};

%% -----------------------------------------------------------------
%% 邀请回应
%% -----------------------------------------------------------------
write(44016, [Code]) ->
    Data = <<Code:16>>,
    {ok, pt:pack(44016, Data)};

%% -----------------------------------------------------------------
%% 师傅推荐
%% -----------------------------------------------------------------
write(44017, [RecordNum, Records]) ->
    Data = <<RecordNum:16, Records/binary>>,
    {ok, pt:pack(44017, Data)};

%% -----------------------------------------------------------------
%% 取消收徒邀请
%% -----------------------------------------------------------------
write(44018, [Code]) ->
    Data = <<Code:16>>,
    {ok, pt:pack(44018, Data)};

%% -----------------------------------------------------------------
%% 错误处理
%% -----------------------------------------------------------------
write(_Cmd, _R) ->
    {ok, pt:pack(0, <<>>)}.