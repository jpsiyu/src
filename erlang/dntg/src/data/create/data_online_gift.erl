%%%-------------------------------------
%%% @Module  : data_online_gift
%%% @Description : 在线礼包配置
%%%---------------------------------------
-module(data_online_gift).
-compile(export_all).
-include("gift_online.hrl").


get_online_gift_by_lv(Lv) ->
    private_get_online_gift(util:floor(Lv/10)*10).
private_get_online_gift(10) -> 
    [{1, [{1,221101,1}], 60, 0},{2, [{1,671001,2}], 120, 0},{3, [{1,501202,1}], 240, 0},{4, [{1,612501,1}], 480, 0},{5, [{1,221112,1}], 720, 0},{6, [{1,501202,3}], 1200, 0},{7, [{1,612501,2}], 1800, 0},{8, [{1,221113,1}], 2700, 0},{9, [{1,611102,5}], 3600, 0},{10, [{1,221114,1}], 4500, 0},{11, [{1,611102,10}], 5400, 0},{12, [{1,221115,1}], 7200, 0}];

private_get_online_gift(20) -> 
    [{1, [{1,221101,1}], 60, 0},{2, [{1,671001,2}], 120, 0},{3, [{1,501202,1}], 240, 0},{4, [{1,612501,1}], 480, 0},{5, [{1,221112,1}], 720, 0},{6, [{1,501202,3}], 1200, 0},{7, [{1,612501,2}], 1800, 0},{8, [{1,221113,1}], 2700, 0},{9, [{1,611102,5}], 3600, 0},{10, [{1,221114,1}], 4500, 0},{11, [{1,611102,10}], 5400, 0},{12, [{1,221115,1}], 7200, 0}];

private_get_online_gift(30) -> 
    [{1, [{1,221101,1}], 60, 0},{2, [{1,671001,2}], 120, 0},{3, [{1,501202,1}], 240, 0},{4, [{1,612501,1}], 480, 0},{5, [{1,221112,1}], 720, 0},{6, [{1,501202,3}], 1200, 0},{7, [{1,612501,2}], 1800, 0},{8, [{1,221113,1}], 2700, 0},{9, [{1,611102,5}], 3600, 0},{10, [{1,221114,1}], 4500, 0},{11, [{1,611102,10}], 5400, 0},{12, [{1,221115,1}], 7200, 0}];

private_get_online_gift(40) -> 
    [{1, [{1,221101,1}], 60, 0},{2, [{1,671001,2}], 120, 0},{3, [{1,501202,1}], 240, 0},{4, [{1,612501,1}], 480, 0},{5, [{1,221112,1}], 720, 0},{6, [{1,501202,3}], 1200, 0},{7, [{1,612501,2}], 1800, 0},{8, [{1,221113,1}], 2700, 0},{9, [{1,611102,5}], 3600, 0},{10, [{1,221114,1}], 4500, 0},{11, [{1,611102,10}], 5400, 0},{12, [{1,221115,1}], 7200, 0}];

private_get_online_gift(50) -> 
    [{1, [{1,221101,1}], 60, 0},{2, [{1,671001,2}], 120, 0},{3, [{1,501202,1}], 240, 0},{4, [{1,612501,1}], 480, 0},{5, [{1,221112,1}], 720, 0},{6, [{1,501202,3}], 1200, 0},{7, [{1,612501,2}], 1800, 0},{8, [{1,221113,1}], 2700, 0},{9, [{1,611102,5}], 3600, 0},{10, [{1,221114,1}], 4500, 0},{11, [{1,611102,10}], 5400, 0},{12, [{1,221115,1}], 7200, 0}];

private_get_online_gift(60) -> 
    [{1, [{1,221101,1}], 60, 0},{2, [{1,671001,2}], 120, 0},{3, [{1,501202,1}], 240, 0},{4, [{1,612501,1}], 480, 0},{5, [{1,221112,1}], 720, 0},{6, [{1,501202,3}], 1200, 0},{7, [{1,612501,2}], 1800, 0},{8, [{1,221113,1}], 2700, 0},{9, [{1,611102,5}], 3600, 0},{10, [{1,221114,1}], 4500, 0},{11, [{1,611102,10}], 5400, 0},{12, [{1,221115,1}], 7200, 0}];

private_get_online_gift(70) -> 
    [{1, [{1,221101,1}], 60, 0},{2, [{1,671001,2}], 120, 0},{3, [{1,501202,1}], 240, 0},{4, [{1,612501,1}], 480, 0},{5, [{1,221112,1}], 720, 0},{6, [{1,501202,3}], 1200, 0},{7, [{1,612501,2}], 1800, 0},{8, [{1,221113,1}], 2700, 0},{9, [{1,611102,5}], 3600, 0},{10, [{1,221114,1}], 4500, 0},{11, [{1,611102,10}], 5400, 0},{12, [{1,221115,1}], 7200, 0}];

private_get_online_gift(80) -> 
    [{1, [{1,221101,1}], 60, 0},{2, [{1,671001,2}], 120, 0},{3, [{1,501202,1}], 240, 0},{4, [{1,612501,1}], 480, 0},{5, [{1,221112,1}], 720, 0},{6, [{1,501202,3}], 1200, 0},{7, [{1,612501,2}], 1800, 0},{8, [{1,221113,1}], 2700, 0},{9, [{1,611102,5}], 3600, 0},{10, [{1,221114,1}], 4500, 0},{11, [{1,611102,10}], 5400, 0},{12, [{1,221115,1}], 7200, 0}];

private_get_online_gift(90) -> 
    [{1, [{1,221101,1}], 60, 0},{2, [{1,671001,2}], 120, 0},{3, [{1,501202,1}], 240, 0},{4, [{1,612501,1}], 480, 0},{5, [{1,221112,1}], 720, 0},{6, [{1,501202,3}], 1200, 0},{7, [{1,612501,2}], 1800, 0},{8, [{1,221113,1}], 2700, 0},{9, [{1,611102,5}], 3600, 0},{10, [{1,221114,1}], 4500, 0},{11, [{1,611102,10}], 5400, 0},{12, [{1,221115,1}], 7200, 0}];

private_get_online_gift(100) -> 
    [{1, [{1,221101,1}], 60, 0},{2, [{1,671001,2}], 120, 0},{3, [{1,501202,1}], 240, 0},{4, [{1,612501,1}], 480, 0},{5, [{1,221112,1}], 720, 0},{6, [{1,501202,3}], 1200, 0},{7, [{1,612501,2}], 1800, 0},{8, [{1,221113,1}], 2700, 0},{9, [{1,611102,5}], 3600, 0},{10, [{1,221114,1}], 4500, 0},{11, [{1,611102,10}], 5400, 0},{12, [{1,221115,1}], 7200, 0}];

private_get_online_gift(_Lv) ->
    [].

get_gife_by_id(1,10) -> 
    #online_gift_goods{id=1,lv=10,goods=[{1,221101,1}],time_span=60,is_get=0};

get_gife_by_id(1,20) -> 
    #online_gift_goods{id=1,lv=20,goods=[{1,221101,1}],time_span=60,is_get=0};

get_gife_by_id(1,30) -> 
    #online_gift_goods{id=1,lv=30,goods=[{1,221101,1}],time_span=60,is_get=0};

get_gife_by_id(1,40) -> 
    #online_gift_goods{id=1,lv=40,goods=[{1,221101,1}],time_span=60,is_get=0};

get_gife_by_id(1,50) -> 
    #online_gift_goods{id=1,lv=50,goods=[{1,221101,1}],time_span=60,is_get=0};

get_gife_by_id(1,60) -> 
    #online_gift_goods{id=1,lv=60,goods=[{1,221101,1}],time_span=60,is_get=0};

get_gife_by_id(1,70) -> 
    #online_gift_goods{id=1,lv=70,goods=[{1,221101,1}],time_span=60,is_get=0};

get_gife_by_id(1,80) -> 
    #online_gift_goods{id=1,lv=80,goods=[{1,221101,1}],time_span=60,is_get=0};

get_gife_by_id(1,90) -> 
    #online_gift_goods{id=1,lv=90,goods=[{1,221101,1}],time_span=60,is_get=0};

get_gife_by_id(1,100) -> 
    #online_gift_goods{id=1,lv=100,goods=[{1,221101,1}],time_span=60,is_get=0};

get_gife_by_id(2,10) -> 
    #online_gift_goods{id=2,lv=10,goods=[{1,671001,2}],time_span=120,is_get=0};

get_gife_by_id(2,20) -> 
    #online_gift_goods{id=2,lv=20,goods=[{1,671001,2}],time_span=120,is_get=0};

get_gife_by_id(2,30) -> 
    #online_gift_goods{id=2,lv=30,goods=[{1,671001,2}],time_span=120,is_get=0};

get_gife_by_id(2,40) -> 
    #online_gift_goods{id=2,lv=40,goods=[{1,671001,2}],time_span=120,is_get=0};

get_gife_by_id(2,50) -> 
    #online_gift_goods{id=2,lv=50,goods=[{1,671001,2}],time_span=120,is_get=0};

get_gife_by_id(2,60) -> 
    #online_gift_goods{id=2,lv=60,goods=[{1,671001,2}],time_span=120,is_get=0};

get_gife_by_id(2,70) -> 
    #online_gift_goods{id=2,lv=70,goods=[{1,671001,2}],time_span=120,is_get=0};

get_gife_by_id(2,80) -> 
    #online_gift_goods{id=2,lv=80,goods=[{1,671001,2}],time_span=120,is_get=0};

get_gife_by_id(2,90) -> 
    #online_gift_goods{id=2,lv=90,goods=[{1,671001,2}],time_span=120,is_get=0};

get_gife_by_id(2,100) -> 
    #online_gift_goods{id=2,lv=100,goods=[{1,671001,2}],time_span=120,is_get=0};

get_gife_by_id(3,10) -> 
    #online_gift_goods{id=3,lv=10,goods=[{1,501202,1}],time_span=240,is_get=0};

get_gife_by_id(3,20) -> 
    #online_gift_goods{id=3,lv=20,goods=[{1,501202,1}],time_span=240,is_get=0};

get_gife_by_id(3,30) -> 
    #online_gift_goods{id=3,lv=30,goods=[{1,501202,1}],time_span=240,is_get=0};

get_gife_by_id(3,40) -> 
    #online_gift_goods{id=3,lv=40,goods=[{1,501202,1}],time_span=240,is_get=0};

get_gife_by_id(3,50) -> 
    #online_gift_goods{id=3,lv=50,goods=[{1,501202,1}],time_span=240,is_get=0};

get_gife_by_id(3,60) -> 
    #online_gift_goods{id=3,lv=60,goods=[{1,501202,1}],time_span=240,is_get=0};

get_gife_by_id(3,70) -> 
    #online_gift_goods{id=3,lv=70,goods=[{1,501202,1}],time_span=240,is_get=0};

get_gife_by_id(3,80) -> 
    #online_gift_goods{id=3,lv=80,goods=[{1,501202,1}],time_span=240,is_get=0};

get_gife_by_id(3,90) -> 
    #online_gift_goods{id=3,lv=90,goods=[{1,501202,1}],time_span=240,is_get=0};

get_gife_by_id(3,100) -> 
    #online_gift_goods{id=3,lv=100,goods=[{1,501202,1}],time_span=240,is_get=0};

get_gife_by_id(4,10) -> 
    #online_gift_goods{id=4,lv=10,goods=[{1,612501,1}],time_span=480,is_get=0};

get_gife_by_id(4,20) -> 
    #online_gift_goods{id=4,lv=20,goods=[{1,612501,1}],time_span=480,is_get=0};

get_gife_by_id(4,30) -> 
    #online_gift_goods{id=4,lv=30,goods=[{1,612501,1}],time_span=480,is_get=0};

get_gife_by_id(4,40) -> 
    #online_gift_goods{id=4,lv=40,goods=[{1,612501,1}],time_span=480,is_get=0};

get_gife_by_id(4,50) -> 
    #online_gift_goods{id=4,lv=50,goods=[{1,612501,1}],time_span=480,is_get=0};

get_gife_by_id(4,60) -> 
    #online_gift_goods{id=4,lv=60,goods=[{1,612501,1}],time_span=480,is_get=0};

get_gife_by_id(4,70) -> 
    #online_gift_goods{id=4,lv=70,goods=[{1,612501,1}],time_span=480,is_get=0};

get_gife_by_id(4,80) -> 
    #online_gift_goods{id=4,lv=80,goods=[{1,612501,1}],time_span=480,is_get=0};

get_gife_by_id(4,90) -> 
    #online_gift_goods{id=4,lv=90,goods=[{1,612501,1}],time_span=480,is_get=0};

get_gife_by_id(4,100) -> 
    #online_gift_goods{id=4,lv=100,goods=[{1,612501,1}],time_span=480,is_get=0};

get_gife_by_id(5,10) -> 
    #online_gift_goods{id=5,lv=10,goods=[{1,221112,1}],time_span=720,is_get=0};

get_gife_by_id(5,20) -> 
    #online_gift_goods{id=5,lv=20,goods=[{1,221112,1}],time_span=720,is_get=0};

get_gife_by_id(5,30) -> 
    #online_gift_goods{id=5,lv=30,goods=[{1,221112,1}],time_span=720,is_get=0};

get_gife_by_id(5,40) -> 
    #online_gift_goods{id=5,lv=40,goods=[{1,221112,1}],time_span=720,is_get=0};

get_gife_by_id(5,50) -> 
    #online_gift_goods{id=5,lv=50,goods=[{1,221112,1}],time_span=720,is_get=0};

get_gife_by_id(5,60) -> 
    #online_gift_goods{id=5,lv=60,goods=[{1,221112,1}],time_span=720,is_get=0};

get_gife_by_id(5,70) -> 
    #online_gift_goods{id=5,lv=70,goods=[{1,221112,1}],time_span=720,is_get=0};

get_gife_by_id(5,80) -> 
    #online_gift_goods{id=5,lv=80,goods=[{1,221112,1}],time_span=720,is_get=0};

get_gife_by_id(5,90) -> 
    #online_gift_goods{id=5,lv=90,goods=[{1,221112,1}],time_span=720,is_get=0};

get_gife_by_id(5,100) -> 
    #online_gift_goods{id=5,lv=100,goods=[{1,221112,1}],time_span=720,is_get=0};

get_gife_by_id(6,10) -> 
    #online_gift_goods{id=6,lv=10,goods=[{1,501202,3}],time_span=1200,is_get=0};

get_gife_by_id(6,20) -> 
    #online_gift_goods{id=6,lv=20,goods=[{1,501202,3}],time_span=1200,is_get=0};

get_gife_by_id(6,30) -> 
    #online_gift_goods{id=6,lv=30,goods=[{1,501202,3}],time_span=1200,is_get=0};

get_gife_by_id(6,40) -> 
    #online_gift_goods{id=6,lv=40,goods=[{1,501202,3}],time_span=1200,is_get=0};

get_gife_by_id(6,50) -> 
    #online_gift_goods{id=6,lv=50,goods=[{1,501202,3}],time_span=1200,is_get=0};

get_gife_by_id(6,60) -> 
    #online_gift_goods{id=6,lv=60,goods=[{1,501202,3}],time_span=1200,is_get=0};

get_gife_by_id(6,70) -> 
    #online_gift_goods{id=6,lv=70,goods=[{1,501202,3}],time_span=1200,is_get=0};

get_gife_by_id(6,80) -> 
    #online_gift_goods{id=6,lv=80,goods=[{1,501202,3}],time_span=1200,is_get=0};

get_gife_by_id(6,90) -> 
    #online_gift_goods{id=6,lv=90,goods=[{1,501202,3}],time_span=1200,is_get=0};

get_gife_by_id(6,100) -> 
    #online_gift_goods{id=6,lv=100,goods=[{1,501202,3}],time_span=1200,is_get=0};

get_gife_by_id(7,10) -> 
    #online_gift_goods{id=7,lv=10,goods=[{1,612501,2}],time_span=1800,is_get=0};

get_gife_by_id(7,20) -> 
    #online_gift_goods{id=7,lv=20,goods=[{1,612501,2}],time_span=1800,is_get=0};

get_gife_by_id(7,30) -> 
    #online_gift_goods{id=7,lv=30,goods=[{1,612501,2}],time_span=1800,is_get=0};

get_gife_by_id(7,40) -> 
    #online_gift_goods{id=7,lv=40,goods=[{1,612501,2}],time_span=1800,is_get=0};

get_gife_by_id(7,50) -> 
    #online_gift_goods{id=7,lv=50,goods=[{1,612501,2}],time_span=1800,is_get=0};

get_gife_by_id(7,60) -> 
    #online_gift_goods{id=7,lv=60,goods=[{1,612501,2}],time_span=1800,is_get=0};

get_gife_by_id(7,70) -> 
    #online_gift_goods{id=7,lv=70,goods=[{1,612501,2}],time_span=1800,is_get=0};

get_gife_by_id(7,80) -> 
    #online_gift_goods{id=7,lv=80,goods=[{1,612501,2}],time_span=1800,is_get=0};

get_gife_by_id(7,90) -> 
    #online_gift_goods{id=7,lv=90,goods=[{1,612501,2}],time_span=1800,is_get=0};

get_gife_by_id(7,100) -> 
    #online_gift_goods{id=7,lv=100,goods=[{1,612501,2}],time_span=1800,is_get=0};

get_gife_by_id(8,10) -> 
    #online_gift_goods{id=8,lv=10,goods=[{1,221113,1}],time_span=2700,is_get=0};

get_gife_by_id(8,20) -> 
    #online_gift_goods{id=8,lv=20,goods=[{1,221113,1}],time_span=2700,is_get=0};

get_gife_by_id(8,30) -> 
    #online_gift_goods{id=8,lv=30,goods=[{1,221113,1}],time_span=2700,is_get=0};

get_gife_by_id(8,40) -> 
    #online_gift_goods{id=8,lv=40,goods=[{1,221113,1}],time_span=2700,is_get=0};

get_gife_by_id(8,50) -> 
    #online_gift_goods{id=8,lv=50,goods=[{1,221113,1}],time_span=2700,is_get=0};

get_gife_by_id(8,60) -> 
    #online_gift_goods{id=8,lv=60,goods=[{1,221113,1}],time_span=2700,is_get=0};

get_gife_by_id(8,70) -> 
    #online_gift_goods{id=8,lv=70,goods=[{1,221113,1}],time_span=2700,is_get=0};

get_gife_by_id(8,80) -> 
    #online_gift_goods{id=8,lv=80,goods=[{1,221113,1}],time_span=2700,is_get=0};

get_gife_by_id(8,90) -> 
    #online_gift_goods{id=8,lv=90,goods=[{1,221113,1}],time_span=2700,is_get=0};

get_gife_by_id(8,100) -> 
    #online_gift_goods{id=8,lv=100,goods=[{1,221113,1}],time_span=2700,is_get=0};

get_gife_by_id(9,10) -> 
    #online_gift_goods{id=9,lv=10,goods=[{1,611102,5}],time_span=3600,is_get=0};

get_gife_by_id(9,20) -> 
    #online_gift_goods{id=9,lv=20,goods=[{1,611102,5}],time_span=3600,is_get=0};

get_gife_by_id(9,30) -> 
    #online_gift_goods{id=9,lv=30,goods=[{1,611102,5}],time_span=3600,is_get=0};

get_gife_by_id(9,40) -> 
    #online_gift_goods{id=9,lv=40,goods=[{1,611102,5}],time_span=3600,is_get=0};

get_gife_by_id(9,50) -> 
    #online_gift_goods{id=9,lv=50,goods=[{1,611102,5}],time_span=3600,is_get=0};

get_gife_by_id(9,60) -> 
    #online_gift_goods{id=9,lv=60,goods=[{1,611102,5}],time_span=3600,is_get=0};

get_gife_by_id(9,70) -> 
    #online_gift_goods{id=9,lv=70,goods=[{1,611102,5}],time_span=3600,is_get=0};

get_gife_by_id(9,80) -> 
    #online_gift_goods{id=9,lv=80,goods=[{1,611102,5}],time_span=3600,is_get=0};

get_gife_by_id(9,90) -> 
    #online_gift_goods{id=9,lv=90,goods=[{1,611102,5}],time_span=3600,is_get=0};

get_gife_by_id(9,100) -> 
    #online_gift_goods{id=9,lv=100,goods=[{1,611102,5}],time_span=3600,is_get=0};

get_gife_by_id(10,10) -> 
    #online_gift_goods{id=10,lv=10,goods=[{1,221114,1}],time_span=4500,is_get=0};

get_gife_by_id(10,20) -> 
    #online_gift_goods{id=10,lv=20,goods=[{1,221114,1}],time_span=4500,is_get=0};

get_gife_by_id(10,30) -> 
    #online_gift_goods{id=10,lv=30,goods=[{1,221114,1}],time_span=4500,is_get=0};

get_gife_by_id(10,40) -> 
    #online_gift_goods{id=10,lv=40,goods=[{1,221114,1}],time_span=4500,is_get=0};

get_gife_by_id(10,50) -> 
    #online_gift_goods{id=10,lv=50,goods=[{1,221114,1}],time_span=4500,is_get=0};

get_gife_by_id(10,60) -> 
    #online_gift_goods{id=10,lv=60,goods=[{1,221114,1}],time_span=4500,is_get=0};

get_gife_by_id(10,70) -> 
    #online_gift_goods{id=10,lv=70,goods=[{1,221114,1}],time_span=4500,is_get=0};

get_gife_by_id(10,80) -> 
    #online_gift_goods{id=10,lv=80,goods=[{1,221114,1}],time_span=4500,is_get=0};

get_gife_by_id(10,90) -> 
    #online_gift_goods{id=10,lv=90,goods=[{1,221114,1}],time_span=4500,is_get=0};

get_gife_by_id(10,100) -> 
    #online_gift_goods{id=10,lv=100,goods=[{1,221114,1}],time_span=4500,is_get=0};

get_gife_by_id(11,10) -> 
    #online_gift_goods{id=11,lv=10,goods=[{1,611102,10}],time_span=5400,is_get=0};

get_gife_by_id(11,20) -> 
    #online_gift_goods{id=11,lv=20,goods=[{1,611102,10}],time_span=5400,is_get=0};

get_gife_by_id(11,30) -> 
    #online_gift_goods{id=11,lv=30,goods=[{1,611102,10}],time_span=5400,is_get=0};

get_gife_by_id(11,40) -> 
    #online_gift_goods{id=11,lv=40,goods=[{1,611102,10}],time_span=5400,is_get=0};

get_gife_by_id(11,50) -> 
    #online_gift_goods{id=11,lv=50,goods=[{1,611102,10}],time_span=5400,is_get=0};

get_gife_by_id(11,60) -> 
    #online_gift_goods{id=11,lv=60,goods=[{1,611102,10}],time_span=5400,is_get=0};

get_gife_by_id(11,70) -> 
    #online_gift_goods{id=11,lv=70,goods=[{1,611102,10}],time_span=5400,is_get=0};

get_gife_by_id(11,80) -> 
    #online_gift_goods{id=11,lv=80,goods=[{1,611102,10}],time_span=5400,is_get=0};

get_gife_by_id(11,90) -> 
    #online_gift_goods{id=11,lv=90,goods=[{1,611102,10}],time_span=5400,is_get=0};

get_gife_by_id(11,100) -> 
    #online_gift_goods{id=11,lv=100,goods=[{1,611102,10}],time_span=5400,is_get=0};

get_gife_by_id(12,10) -> 
    #online_gift_goods{id=12,lv=10,goods=[{1,221115,1}],time_span=7200,is_get=0};

get_gife_by_id(12,20) -> 
    #online_gift_goods{id=12,lv=20,goods=[{1,221115,1}],time_span=7200,is_get=0};

get_gife_by_id(12,30) -> 
    #online_gift_goods{id=12,lv=30,goods=[{1,221115,1}],time_span=7200,is_get=0};

get_gife_by_id(12,40) -> 
    #online_gift_goods{id=12,lv=40,goods=[{1,221115,1}],time_span=7200,is_get=0};

get_gife_by_id(12,50) -> 
    #online_gift_goods{id=12,lv=50,goods=[{1,221115,1}],time_span=7200,is_get=0};

get_gife_by_id(12,60) -> 
    #online_gift_goods{id=12,lv=60,goods=[{1,221115,1}],time_span=7200,is_get=0};

get_gife_by_id(12,70) -> 
    #online_gift_goods{id=12,lv=70,goods=[{1,221115,1}],time_span=7200,is_get=0};

get_gife_by_id(12,80) -> 
    #online_gift_goods{id=12,lv=80,goods=[{1,221115,1}],time_span=7200,is_get=0};

get_gife_by_id(12,90) -> 
    #online_gift_goods{id=12,lv=90,goods=[{1,221115,1}],time_span=7200,is_get=0};

get_gife_by_id(12,100) -> 
    #online_gift_goods{id=12,lv=100,goods=[{1,221115,1}],time_span=7200,is_get=0};

get_gife_by_id(_Id,_Lv)->
    [].

