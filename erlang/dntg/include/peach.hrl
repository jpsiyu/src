%% Author: zengzhaoyuan
%% Created: 2012-9-9
%% Description: TODO: 蟠桃园

-record(peach_room,{  %房间
	id=0, 		%房间ID
	num = 0 	%房间人口				
}).	

-record(peach,{  %蟠桃园玩家记录
	id=0, 					% 玩家ID
	nickname=0, 			% 玩家昵称
	contry = 0, 			% 玩家国家
	sex = 0,				% 性别
	career = 0,				% 职业
	image = 0,				% 头像
	lv = 0, 				% 玩家等级
	pk_status = 2,			% pk状态
	room_id=0, 				% 房间ID
	acquisition = 0,  		% 蟠桃采集数
	plunder = 0,			% 蟠桃掠夺数
	robbed = 0 				% 蟠桃被抢劫数
}).