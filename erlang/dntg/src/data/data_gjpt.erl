%%%------------------------------------
%%% @Module  : data_gjpt
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.8.20
%%% @Description: 国家声望
%%%------------------------------------
-module(data_gjpt).
-compile(export_all).

text(Type) ->
	case Type of
		1 -> "红名通知";
		2 -> "您由于屠戮本阵营玩家，罪恶值已超过200点，获得红名惩罚！提示：红名状态只能处于全体的战斗模式，且此状态下死亡会掉落损失一定铜币。保持在线或者商城购买并使用免罪金牌能够消除罪恶值。";
		3 -> "关入囚牢通知";
		4 -> "您由于屠戮过多本阵营玩家，罪恶值已超过500点，现将您关入囚牢面壁思过，望早日洗脱罪恶！提示：保持在线或者商城购买并使用免罪金牌能够消除罪恶值，罪恶值降低到500以下时才能自动传出囚牢。";
		_ -> ""
	end.