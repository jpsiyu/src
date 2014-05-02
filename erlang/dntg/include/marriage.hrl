%%%------------------------------------------------
%%% @Author  : guoxi
%%% @Email   : guoxi@jieyou.cn
%%% @Created : 2012.9.25
%%% Description: 结婚 record定义
%%%------------------------------------------------

-record(marriage, {
		id = 0, %ID
		male_id = 0, %新郎ID
		female_id = 0, %新娘ID
		register_time = 0, %登记时间
		wedding_time  = 0, %婚宴时间
        wedding_order_time = 0, %预约婚宴时的时间
		wedding_type = 0, %婚宴类型
		wedding_card = 0, %剩余邀请卡
        wedding_candies = 0, %剩余喜糖
		state = 1, %状态 1.未迎接新娘 2.已迎接新娘，未跳完火盆 3.跳完火盆，未拜堂 4.已拜堂 5.新娘逃婚 6.新郎逃婚
        male_coin = 0,
        male_gold = 0,
        female_coin = 0,
        female_gold = 0,
        male_name = <<>>,
        female_name = <<>>,
        male_career = 0,
        female_career = 0,
        male_sex = 0,
        female_sex = 0,
        male_image = 0,
        female_image = 0,
        cruise_time = 0,  %巡游时间
        cruise_order_time = 0, %预约巡游时的时间
        cruise_type = 0,  %巡游类型
        cruise_state = 1, %巡游状态 1.未开始巡游 2.已开始巡游 3.巡游已结束
        cruise_card = 0,  %巡游表白图册
        cruise_candies = 0, %巡游喜糖
        apply_divorce_time = 0,  %申请离婚的时间戳
        apply_sex = 0,  %申请性别(男、女)
        mark_sure_time = 0,  %协议离婚时间
        divorce = 0  %是否已离婚
		}).
