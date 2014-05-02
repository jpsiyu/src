%%%------------------------------------
%%% @Module  : data_dungeon_secret_shop
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.8.7
%%% @Description: 九重天11、21、31层神秘商店
%%%------------------------------------

-module(data_dungeon_secret_shop).
-compile(export_all).

get_secret_shop_config(Type) ->
	case Type of
        use_scene -> [310, 311, 317, 323, 329, 335, 998, 345, 351, 357, 363, 368, 373, 102, 429];    %可使用的场景ID，九重天11、21、31层(监狱的商店也走该流程) 占领长安城的8折药品 VIP副本场景
        max_num -> 3;              %最大购买数量
		_ -> void
	end.
