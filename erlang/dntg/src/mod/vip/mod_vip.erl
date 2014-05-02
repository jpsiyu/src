%%%------------------------------------
%%% @Module  : mod_vip
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.6.26
%%% @Description: VIP模块
%%%------------------------------------

-module(mod_vip).
-compile(export_all).
-include("server.hrl").
-include("buff.hrl").

lookup_pid(Id) ->
	vip_buff_dict:lookup_pid(Id).

insert_buff(EtsVipBuff) ->
	vip_buff_dict:insert_buff(EtsVipBuff).

login_init(_PlayerStatus) ->
	case mod_vip:lookup_pid(_PlayerStatus#player_status.id) of
		undefined -> 
            Vip = _PlayerStatus#player_status.vip,
            GoodsTypeId = lib_vip:date_attr(Vip#status_vip.vip_type),
            Status = _PlayerStatus,
            case data_goods_effect:get_val(GoodsTypeId, buff) of
                [] -> skip;
                {Type, AttributeId, Value, Time, SceneLimit} ->
                    NowTime = util:unixtime(),
                    case lib_buff:match_three(Status#player_status.player_buff, Type, AttributeId, []) of
                    %case lib_player:get_player_buff(Status#player_status.id, Type, AttributeId) of
                        [] ->
                            NewBuffInfo = lib_player:add_player_buff(Status#player_status.id, Type, GoodsTypeId, AttributeId, Value, NowTime, SceneLimit);
                        [BuffInfo] ->
                            NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsTypeId, Value, NowTime, SceneLimit);
                        [BuffInfo | _T] ->
                            NewBuffInfo = lib_player:mod_buff(BuffInfo, GoodsTypeId, Value, NowTime, SceneLimit)
                    end,
                    %% 初始化祝福,state设为2
					mod_vip:insert_buff(#ets_vip_buff{id = Status#player_status.id, buff = NewBuffInfo, rest_time = Time, state = 2});
                _Any -> skip
            end,
            _PlayerStatus;
		EtsVipBuff ->
			VipBuff = EtsVipBuff#ets_vip_buff.buff,
			VipRestTime = EtsVipBuff#ets_vip_buff.rest_time,
			VipState = EtsVipBuff#ets_vip_buff.state,
			%% VipState为1代表用户下线时处理解冻状态，系统自动冻结，用户上线后自动解冻
			case VipState of
				1 ->
					%% 修改buff结束时间
					VipEndTime = util:unixtime() + VipRestTime,
					mod_vip:insert_buff(EtsVipBuff#ets_vip_buff{buff = VipBuff#ets_buff{end_time = VipEndTime}}),
					%% 增加buff
					PSVip = _PlayerStatus#player_status.vip,
					VipBuffType = lib_vip:date_attr(PSVip#status_vip.vip_type),
					case data_goods_effect:get_val(VipBuffType, buff) of
        				[] -> _PlayerStatus;
    		    		{VipType, VipAttributeId, VipValue, _VipTime, VipSceneLimit} ->
							%% 解冻重新计算buff时间
                            VipNewBuffInfo = case lib_buff:match_three(_PlayerStatus#player_status.player_buff, VipType, VipAttributeId, []) of
							%VipNewBuffInfo = case lib_player:get_player_buff(_PlayerStatus#player_status.id, VipType, VipAttributeId) of
        		 			 	[] -> lib_player:add_player_buff(_PlayerStatus#player_status.id, VipType, VipBuffType, VipAttributeId, VipValue, VipEndTime, VipSceneLimit);
        		  				[VipBuffInfo] -> lib_player:mod_buff(VipBuffInfo, VipBuffType, VipValue, VipEndTime, VipSceneLimit);
                                [VipBuffInfo | _] -> lib_player:mod_buff(VipBuffInfo, VipBuffType, VipValue, VipEndTime, VipSceneLimit)
          		 			end,
							VipBuffId = VipBuff#ets_buff.id,
							VipNewBuffInfo1 = VipNewBuffInfo#ets_buff{id = VipBuffId},
							mod_vip:insert_buff(EtsVipBuff#ets_vip_buff{buff = VipNewBuffInfo1}),
							buff_dict:insert_buff(VipNewBuffInfo1),
          		  			lib_player:send_buff_notice(_PlayerStatus, [VipNewBuffInfo1]),
            				VipBuffAttribute = lib_player:get_buff_attribute(_PlayerStatus#player_status.id, _PlayerStatus#player_status.scene),
            				VipNewPlayerStatus = lib_player:count_player_attribute(_PlayerStatus#player_status{buff_attribute = VipBuffAttribute}),
                            %lib_player:send_attribute_change_notify(VipNewPlayerStatus, 0)
                            case lib_buff:match_two2(VipNewPlayerStatus#player_status.player_buff, 18, []) of
                                [] ->
                                    VipNewPlayerStatus2 = VipNewPlayerStatus#player_status{
                                        player_buff = [VipNewBuffInfo1 | VipNewPlayerStatus#player_status.player_buff]
                                    },
                                    VipNewPlayerStatus2;
                                _ ->
                                    VipNewPlayerStatus
                            end
                    end;
				_ -> _PlayerStatus
			end
	end.

logout(PS) ->
	db:execute(io_lib:format(<<"delete from `buff` where `pid`= ~p and attribute_id = ~p">>
							 , [PS#player_status.id, 18])),
	lib_player:delete_ets_buff(PS#player_status.id),
	case mod_vip:lookup_pid(PS#player_status.id) of
		undefined -> skip;
		EtsVipBuff ->
			_Buff = EtsVipBuff#ets_vip_buff.buff,
			_State = EtsVipBuff#ets_vip_buff.state,
			case _State of
				1 ->
					mod_vip:insert_buff(EtsVipBuff#ets_vip_buff{rest_time = _Buff#ets_buff.end_time - util:unixtime()});
				_ -> skip
			end
	end.
