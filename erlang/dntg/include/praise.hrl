-record(praise_state,{
            get_dict = dict:new(),   %% 获赞列表 {key:玩家Id，Value:#praise_member{}}
            send_dict = dict:new()   %% 送赞列表 {key:玩家Id，Value:#praise_member{}}
    }).

-record(praise_member, {
            id = 0,         %% 玩家Id
            name = 0        %% 昵称     
    }).