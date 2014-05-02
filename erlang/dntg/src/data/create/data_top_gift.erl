%%%---------------------------------------
%%% @Module  : data_top_gift
%%% @Description: 活动排名奖励
%%%--------------------------------------
-module(data_top_gift).
-export([send_gift/2]).
%%
%% API Functions
%%
%%发奖
%%@param Top_id_List 已排序的名单
send_gift(Type,Top_id_List)when is_list(Top_id_List)->
	NowTime = util:unixtime(),
	Rules = rules(),
	Rule = get_rule(Type,NowTime,Rules),
	spawn(fun()-> 
		send_gift_sub(Rule,Top_id_List,1)			  
	end).
get_rule(_Type,_NowTime,[])->{error,no_match};
get_rule(Type,NowTime,[Rule|T])->
	{T_Type,Begin,End,_Title,_Content,_} = Rule,
	if
		Type=:=T_Type andalso Begin=<NowTime andalso NowTime=<End->
			{ok,Rule};
		true->
			get_rule(Type,NowTime,T)
	end.
send_gift_sub({error,no_match},_IdLists,_Pos)->ok;
send_gift_sub({ok,_Rule},[],_Pos)->ok;
send_gift_sub({ok,Rule},[Id|T],Pos)->
	{_Type,_Begin,_End,Title,Content,Gift_List} = Rule,
	List = [{T_GiftId,T_Num}||{No_start,No_end,T_GiftId,T_Num}<-Gift_List,No_start=<Pos,Pos=<No_end],
	lists:foreach(fun({GiftId,Num})-> 
		lib_mail:send_sys_mail_bg([Id], Title, Content, GiftId, 2, 0, 0,Num,0,0,0,0),
		timer:sleep(300)
	end, List),
	send_gift_sub({ok,Rule},T,Pos+1).

%%{Type,Begin,End,Title,Content,[{No_start,No_end,GiftId,Num}]}
%%{活动类型,活动开始时间,活动结束时间,邮件标题,邮件内容,[{名次开始,名次结束,礼包ID,礼包数量}]}
%%Type: 1蟠桃园
rules()->
	[{1,1356799985,1357228387,"元旦活动——蟠桃会","恭喜您在新年蟠桃会中领先群仙，获得礼包奖励",[{1,1,534109,1},{2,2,534110,1},{3,3,534111,1},{4,6,534112,1},{7,10,534113,1}]}].
