%%%---------------------------------------
%%% @Module  : data_token
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:31
%%% @Description:  称号相关
%%%---------------------------------------
-module(data_token).
-compile(export_all).
-include("goods.hrl").

get_token_inof(1, 108001) ->
    #kf_token{career=1, token_id=108001, next_id=108002, pt=10000, num=500, days=15};	

get_token_inof(1, 108002) ->
    #kf_token{career=1, token_id=108002, next_id=108003, pt=17500, num=550, days=7};	

get_token_inof(1, 108003) ->
    #kf_token{career=1, token_id=108003, next_id=108014, pt=27000, num=600, days=7};	

get_token_inof(1, 108014) ->
    #kf_token{career=1, token_id=108014, next_id=108015, pt=40000, num=650, days=7};	

get_token_inof(1, 108015) ->
    #kf_token{career=1, token_id=108015, next_id=108016, pt=54000, num=700, days=7};	

get_token_inof(1, 108016) ->
    #kf_token{career=1, token_id=108016, next_id=108017, pt=76000, num=800, days=7};	

get_token_inof(1, 108017) ->
    #kf_token{career=1, token_id=108017, next_id=108018, pt=98000, num=900, days=7};	

get_token_inof(1, 108018) ->
    #kf_token{career=1, token_id=108018, next_id=108019, pt=123000, num=1000, days=7};	

get_token_inof(1, 108019) ->
    #kf_token{career=1, token_id=108019, next_id=108020, pt=165000, num=1100, days=7};	

get_token_inof(1, 108020) ->
    #kf_token{career=1, token_id=108020, next_id=108021, pt=212000, num=1250, days=7};	

get_token_inof(1, 108021) ->
    #kf_token{career=1, token_id=108021, next_id=108021, pt=265000, num=1400, days=7};	

get_token_inof(2, 108001) ->
    #kf_token{career=2, token_id=108001, next_id=108002, pt=10000, num=500, days=15};	

get_token_inof(2, 108002) ->
    #kf_token{career=2, token_id=108002, next_id=108003, pt=17500, num=550, days=7};	

get_token_inof(2, 108003) ->
    #kf_token{career=2, token_id=108003, next_id=108044, pt=27000, num=600, days=7};	

get_token_inof(2, 108044) ->
    #kf_token{career=2, token_id=108044, next_id=108045, pt=40000, num=650, days=7};	

get_token_inof(2, 108045) ->
    #kf_token{career=2, token_id=108045, next_id=108046, pt=54000, num=700, days=7};	

get_token_inof(2, 108046) ->
    #kf_token{career=2, token_id=108046, next_id=108047, pt=76000, num=800, days=7};	

get_token_inof(2, 108047) ->
    #kf_token{career=2, token_id=108047, next_id=108048, pt=98000, num=900, days=7};	

get_token_inof(2, 108048) ->
    #kf_token{career=2, token_id=108048, next_id=108049, pt=123000, num=1000, days=7};	

get_token_inof(2, 108049) ->
    #kf_token{career=2, token_id=108049, next_id=108050, pt=165000, num=1100, days=7};	

get_token_inof(2, 108050) ->
    #kf_token{career=2, token_id=108050, next_id=108051, pt=212000, num=1250, days=7};	

get_token_inof(2, 108051) ->
    #kf_token{career=2, token_id=108051, next_id=108051, pt=265000, num=1400, days=7};	

get_token_inof(3, 108001) ->
    #kf_token{career=3, token_id=108001, next_id=108002, pt=10000, num=500, days=15};	

get_token_inof(3, 108002) ->
    #kf_token{career=3, token_id=108002, next_id=108003, pt=17500, num=550, days=7};	

get_token_inof(3, 108003) ->
    #kf_token{career=3, token_id=108003, next_id=108074, pt=27000, num=600, days=7};	

get_token_inof(3, 108074) ->
    #kf_token{career=3, token_id=108074, next_id=108075, pt=40000, num=650, days=7};	

get_token_inof(3, 108075) ->
    #kf_token{career=3, token_id=108075, next_id=108076, pt=54000, num=700, days=7};	

get_token_inof(3, 108076) ->
    #kf_token{career=3, token_id=108076, next_id=108077, pt=76000, num=800, days=7};	

get_token_inof(3, 108077) ->
    #kf_token{career=3, token_id=108077, next_id=108078, pt=98000, num=900, days=7};	

get_token_inof(3, 108078) ->
    #kf_token{career=3, token_id=108078, next_id=108079, pt=123000, num=1000, days=7};	

get_token_inof(3, 108079) ->
    #kf_token{career=3, token_id=108079, next_id=108080, pt=165000, num=1100, days=7};	

get_token_inof(3, 108080) ->
    #kf_token{career=3, token_id=108080, next_id=108081, pt=212000, num=1250, days=7};	

get_token_inof(3, 108081) ->
    #kf_token{career=3, token_id=108081, next_id=108081, pt=265000, num=1400, days=7};	

get_token_inof(_, _) ->
    [].
