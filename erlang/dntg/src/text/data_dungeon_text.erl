%%%-----------------------------------
%%% @Module  : data_dungeon_text
%%% @Author  : zhenghehe
%%% @Created : 2011.06.14
%%% @Description: 中文文本
%%%-----------------------------------
-module(data_dungeon_text).
-compile(export_all).

%% 获取副本的中文文本.
get_dungeon_text(Type) ->
    case Type of
        1 ->
            <<"没有这个副本场景">>;
        2 ->
            <<"人要向前行，不能走回头路啊！">>;
        3 ->
            <<"副本操作太快">>;
        4 ->
            <<"副本正在冷却中，请稍后再进行挑战！">>;
        5 ->
            <<"在飞行坐骑上不能进入副本！">>;
        6 ->
            <<"该章正在扫荡中！">>;
        7 ->
            <<"活动时间已过！">>
    end.

%% 获取爬塔副本的中文文本.
get_tower_text(Type) ->
    case Type of
        1 ->
           <<"您在护送中，无法进入副本">>;
        2 ->
           <<"副本不存在!">>;
        3 ->
           <<"队伍内有成员进入次数已满或次数不足进入双倍掉落模式!">>;
        4 ->
           "是否进入";
        5 ->
           "第";
        6 ->
           "层？";
        7 ->
           <<"队长今日跳层次数已满，无法进入副本">>;
        8 ->
           "是否进入";
        9 ->
           "？";
        10 ->
           <<"队伍内有成员 <font color = \"#3ADF00\">远征岛声望</font> 低于12000, 无法进入帝王谷!">>;
        11 ->
           <<"你的队伍人数大于3人，不能进入副本!">>;
        12 ->
           <<"你不是队长，无法创建副本!">>;
        13 ->
           <<"进入副本前请先创建队伍!">>;
        14 ->
           "您获得了第";
        15 ->
           "层的奖励! ";
        16 ->
           "远征岛、帝王谷跳层增加次数";
        17 ->
           <<"队伍内有成员正在离线挂机，请先停止再进入!">>;
        18 ->
           <<"有队员与队长不在同一场景中，无法创建副本">>;
        19 ->
           "经验";		
        20 ->
           "历练声望";
        21 ->
           "队伍中有三个不同职业，获得120%的经验和历练声望奖励。";
        22 ->
           "荣誉";
        23 ->
           "帝王荣誉";
        24 ->
           "你在";
        25 ->
           "中途下线，系统为你发放了第";
        26 ->
           "层奖励";
        27 ->
           "您征战到";
		28 ->
           "层， 获得 ";
		29 ->
           "奖励";
		30 ->
           "    尊敬的玩家，";
		31 ->
           "，奖励";
		32 ->
           "！";
		33 ->
           "远征岛";
		34 ->
           "帝王谷";
        35 ->
           <<"你正在排队进入场景中，无法进入副本">>;
        36 ->
            <<"进入次数已满或次数不足进入双倍掉落模式!">>;
        37 ->
            <<"元宝不足，无法进入双倍掉落模式">>;
        38 ->
           <<"队伍内有成员进入次数已满!">>		
    end.

%% 获取铜币副本的中文文本.
get_coin_dungeon_text(Type) ->
    case Type of
        1 ->
            "铜币副本奖励";
        2 ->
            "尊敬的玩家，您挑战铜币副本时中途掉线，系统已自动发放获得的";
        3 ->
            "绑定铜钱，";
        4 ->
            "铜钱奖励。"                                                
    end.   

%% 获取带参数爬塔副本的中文文本.
get_tower_text(Type, Arg) ->
    Text = case Type of
        1 -> 
            <<"是否进入<font color='#39ff0b'>~s</font>第~p层？">>;
        2 -> 
            <<"是否进入<font color='#39ff0b'>~s</font>？">>;
        3 -> 
            <<"是否进入~s<font color='#39ff0b'>~s</font>？">>;
        4 -> 
            <<"双倍~s">>
    end,
    io_lib:format(Text, Arg).

%% 封魔录挂机邮件.
get_auto_story_config(Type, Arg)->
	case Type of
        % 邮件标题
        title1 -> "封魔录扫荡结果";
        % 邮件内容
        content1 -> 
			%Text = "您在封魔录中完成~p次扫荡，获得~p经验，~p武魂。注：掉落物品已存入暂存仓库。",
			Text = "您在封魔录中完成~p次扫荡，获得~p经验，~p武魂。",
			io_lib:format(Text, Arg);
        content2 -> 
			%Text = "您在封魔录中完成~p次扫荡，获得~p经验，~p武魂。注：掉落物品已存入暂存仓库。",
			Text = "您在封魔录中完成~p次扫荡，获得~p经验，~p武魂。\n　　\n　　暂存仓库存入奖励：~s",
			io_lib:format(Text, Arg)	
	end.
	

%% 基础数据配置
get_story_master_config(Type, Arg)->
	case Type of
        % 邮件标题
        title1 -> "每日霸主礼包";
        % 邮件内容
        content1 ->
			[Arg1] = Arg, 
			case Arg1 of
				1 -> 
					"恭喜你蝉连封魔录序章霸主，获得每日霸主礼包！";
				Arg2 -> 
					Text = "恭喜你蝉连封魔录~p章霸主，获得每日霸主礼包！",
					io_lib:format(Text, [Arg2-1])
			end;
		_ ->void
	end.

%% 连连看副本配置
get_lian_config(Type, Arg)->
	case Type of
        % 邮件标题
        title1 -> "火眼金睛活动奖励";
        % 邮件内容
        content1 ->
			Text = "恭喜你在火眼金睛活动副本中获得~p积分，获得相应礼包奖励！",
			io_lib:format(Text, Arg);
        % 邮件标题
        title2 -> "火眼金睛活动结果";
        % 邮件内容
        content2 ->
			"你在活动副本中的表现不给力，获取不足500积分，故无法领取相应礼包奖励，在副本中消除对应三师徒可以获得积分，请下次继续努力哦！";
		_ ->void
	end.


%% 装备副本配置
get_equip_config(Type)->
    case Type of
        title -> "装备副本首次通关奖励";
        content -> <<"恭喜你在装备副本~s中，成功首次通关，获得相应礼包奖励!">>;
        title1 -> "装备副本抽取物品";
        content1 -> <<"您在装备副本第~s层，抽取通关物品时，由于背包没有足够的空间，所以通过邮件发送给您！">>;
        _ ->void
    end.

%% 装备副本霸主每日物品发放
get_equip_master_config(Type, Arg)->
    case Type of
        title -> "装备副本每日霸主礼包";
        content -> 
            [Name] = Arg,
            io_lib:format(<<"恭喜你在装备副本第~s层中成为当日霸主，获得每日装备霸主礼包">>,[Name]);
        _ -> void
    end.
