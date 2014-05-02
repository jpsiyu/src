%%%---------------------------------------
%%% @Module  : data_mount
%%% @Description : 坐骑配置
%%%---------------------------------------
-module(data_mount).
-compile(export_all).
-include("mount.hrl").


get_mount_upgrade(311001) -> 
    #mount_upgrade{mount_id=311001,next_figure=311002,level=1,speed=36,attr=[{1,600},{13,60},{14,60},{15,60},{4,0},{3,0},{5,0},{6,0},{7,0},{8,0}]};

get_mount_upgrade(311002) -> 
    #mount_upgrade{mount_id=311002,next_figure=311003,level=2,speed=45,attr=[{1,1000},{13,100},{14,100},{15,100},{4,125},{3,0},{5,0},{6,0},{7,22},{8,0}]};

get_mount_upgrade(311003) -> 
    #mount_upgrade{mount_id=311003,next_figure=311004,level=3,speed=54,attr=[{1,1500},{13,230},{14,230},{15,230},{4,125},{3,40},{5,0},{6,0},{7,57},{8,70}]};

get_mount_upgrade(311004) -> 
    #mount_upgrade{mount_id=311004,next_figure=311005,level=4,speed=63,attr=[{1,2100},{13,290},{14,290},{15,290},{4,125},{3,204},{5,109},{6,90},{7,87},{8,70}]};

get_mount_upgrade(311005) -> 
    #mount_upgrade{mount_id=311005,next_figure=311006,level=5,speed=72,attr=[{1,4670},{13,483},{14,483},{15,483},{4,125},{3,235},{5,109},{6,90},{7,102},{8,186}]};

get_mount_upgrade(311006) -> 
    #mount_upgrade{mount_id=311006,next_figure=311007,level=6,speed=81,attr=[{1,5420},{13,750},{14,750},{15,750},{4,125},{3,452},{5,109},{6,90},{7,163},{8,186}]};

get_mount_upgrade(311007) -> 
    #mount_upgrade{mount_id=311007,next_figure=311008,level=7,speed=90,attr=[{1,8990},{13,820},{14,820},{15,820},{4,312},{3,481},{5,109},{6,255},{7,177},{8,374}]};

get_mount_upgrade(311008) -> 
    #mount_upgrade{mount_id=311008,next_figure=311009,level=8,speed=99,attr=[{1,9790},{13,900},{14,900},{15,900},{4,312},{3,751},{5,240},{6,255},{7,268},{8,536}]};

get_mount_upgrade(311009) -> 
    #mount_upgrade{mount_id=311009,next_figure=311010,level=9,speed=108,attr=[{1,14284},{13,1348},{14,1348},{15,1348},{4,660},{3,785},{5,240},{6,418},{7,285},{8,536}]};

get_mount_upgrade(311010) -> 
    #mount_upgrade{mount_id=311010,next_figure=311011,level=10,speed=117,attr=[{1,18824},{13,1468},{14,1468},{15,1468},{4,660},{3,1158},{5,448},{6,578},{7,305},{8,536}]};

get_mount_upgrade(311011) -> 
    #mount_upgrade{mount_id=311011,next_figure=311012,level=11,speed=126,attr=[{1,25035},{13,2088},{14,2088},{15,2088},{4,660},{3,1198},{5,448},{6,578},{7,507},{8,814}]};

get_mount_upgrade(311012) -> 
    #mount_upgrade{mount_id=311012,next_figure=0,level=12,speed=135,attr=[{1,31246},{13,2708},{14,2708},{15,2708},{4,660},{3,1586},{5,448},{6,578},{7,693},{8,814}]};

get_mount_upgrade(_Mountid) ->
    [].

get_upgrade_all() ->
        [311001,311002,311003,311004,311005,311006,311007,311008,311009,311010,311011,311012].

%%坐骑进阶限制
get_upgrade_limit(2) -> 
    #mount_upgrade_limit{level=2,lv=50,max_value=100};
get_upgrade_limit(3) -> 
    #mount_upgrade_limit{level=3,lv=50,max_value=150};
get_upgrade_limit(4) -> 
    #mount_upgrade_limit{level=4,lv=50,max_value=250};
get_upgrade_limit(5) -> 
    #mount_upgrade_limit{level=5,lv=50,max_value=400};
get_upgrade_limit(6) -> 
    #mount_upgrade_limit{level=6,lv=55,max_value=550};
get_upgrade_limit(7) -> 
    #mount_upgrade_limit{level=7,lv=55,max_value=700};
get_upgrade_limit(8) -> 
    #mount_upgrade_limit{level=8,lv=55,max_value=950};
get_upgrade_limit(9) -> 
    #mount_upgrade_limit{level=9,lv=55,max_value=1250};
get_upgrade_limit(10) -> 
    #mount_upgrade_limit{level=10,lv=55,max_value=1500};
get_upgrade_limit(11) -> 
    #mount_upgrade_limit{level=11,lv=60,max_value=1800};
get_upgrade_limit(12) -> 
    #mount_upgrade_limit{level=12,lv=60,max_value=2000};
get_upgrade_limit(_Level) ->
    [].

%% 参数:星星数(star_id),进阶数（level）
get_mount_upgrade_star(0,1) -> 
    #mount_upgrade_star{star_id=0,level=1,next_figure=311002,lim_star=6,radio=10000,lim_lucky=1,coin=1000,goods=[{311101,2}],attr=[{1,0},{13,0},{14,0},{15,0},{4,15},{3,0},{5,0},{6,0},{7,3},{8,0}]};
get_mount_upgrade_star(0,2) -> 
    #mount_upgrade_star{star_id=0,level=2,next_figure=311003,lim_star=6,radio=9300,lim_lucky=1,coin=1500,goods=[{311101,4}],attr=[{1,0},{13,10},{14,10},{15,10},{4,0},{3,0},{5,0},{6,0},{7,5},{8,10}]};
get_mount_upgrade_star(0,3) -> 
    #mount_upgrade_star{star_id=0,level=3,next_figure=311004,lim_star=8,radio=7200,lim_lucky=1,coin=2000,goods=[{311101,6}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,13},{5,6},{6,4},{7,0},{8,0}]};
get_mount_upgrade_star(0,4) -> 
    #mount_upgrade_star{star_id=0,level=4,next_figure=311005,lim_star=8,radio=5760,lim_lucky=2,coin=3000,goods=[{311101,8}],attr=[{1,180},{13,12},{14,12},{15,12},{4,0},{3,0},{5,0},{6,0},{7,0},{8,12}]};
get_mount_upgrade_star(0,5) -> 
    #mount_upgrade_star{star_id=0,level=5,next_figure=311006,lim_star=8,radio=4608,lim_lucky=2,coin=4000,goods=[{311101,10}],attr=[{1,0},{13,17},{14,17},{15,17},{4,0},{3,17},{5,0},{6,0},{7,4},{8,0}]};
get_mount_upgrade_star(0,6) -> 
    #mount_upgrade_star{star_id=0,level=6,next_figure=311007,lim_star=10,radio=4350,lim_lucky=3,coin=5000,goods=[{311101,12}],attr=[{1,220},{13,0},{14,0},{15,0},{4,13},{3,0},{5,0},{6,12},{7,0},{8,13}]};
get_mount_upgrade_star(0,7) -> 
    #mount_upgrade_star{star_id=0,level=7,next_figure=311008,lim_star=10,radio=3480,lim_lucky=3,coin=5000,goods=[{311101,15}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,19},{5,9},{6,0},{7,6},{8,12}]};
get_mount_upgrade_star(0,8) -> 
    #mount_upgrade_star{star_id=0,level=8,next_figure=311009,lim_star=10,radio=2784,lim_lucky=4,coin=5000,goods=[{311101,20}],attr=[{1,268},{13,26},{14,26},{15,26},{4,26},{3,0},{5,0},{6,12},{7,0},{8,0}]};
get_mount_upgrade_star(0,9) -> 
    #mount_upgrade_star{star_id=0,level=9,next_figure=311010,lim_star=12,radio=2584,lim_lucky=4,coin=7000,goods=[{311101,25}],attr=[{1,230},{13,0},{14,0},{15,0},{4,0},{3,22},{5,14},{6,11},{7,0},{8,0}]};
get_mount_upgrade_star(0,10) -> 
    #mount_upgrade_star{star_id=0,level=10,next_figure=311011,lim_star=12,radio=2067,lim_lucky=5,coin=7000,goods=[{311101,30}],attr=[{1,345},{13,34},{14,34},{15,34},{4,0},{3,0},{5,0},{6,0},{7,12},{8,19}]};
get_mount_upgrade_star(0,11) -> 
    #mount_upgrade_star{star_id=0,level=11,next_figure=311012,lim_star=12,radio=1653,lim_lucky=6,coin=9000,goods=[{311101,35}],attr=[{1,345},{13,34},{14,34},{15,34},{4,0},{3,24},{5,0},{6,0},{7,11},{8,0}]};
get_mount_upgrade_star(1,1) -> 
    #mount_upgrade_star{star_id=1,level=1,next_figure=311002,lim_star=6,radio=9100,lim_lucky=1,coin=1000,goods=[{311101,2}],attr=[{1,0},{13,0},{14,0},{15,0},{4,33},{3,0},{5,0},{6,0},{7,6},{8,0}]};
get_mount_upgrade_star(1,2) -> 
    #mount_upgrade_star{star_id=1,level=2,next_figure=311003,lim_star=6,radio=8300,lim_lucky=1,coin=1500,goods=[{311101,4}],attr=[{1,0},{13,20},{14,20},{15,20},{4,0},{3,0},{5,0},{6,0},{7,10},{8,20}]};
get_mount_upgrade_star(1,3) -> 
    #mount_upgrade_star{star_id=1,level=3,next_figure=311004,lim_star=8,radio=6400,lim_lucky=1,coin=2000,goods=[{311101,6}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,27},{5,12},{6,9},{7,0},{8,0}]};
get_mount_upgrade_star(1,4) -> 
    #mount_upgrade_star{star_id=1,level=4,next_figure=311005,lim_star=8,radio=5120,lim_lucky=2,coin=3000,goods=[{311101,8}],attr=[{1,360},{13,24},{14,24},{15,24},{4,0},{3,0},{5,0},{6,0},{7,0},{8,24}]};
get_mount_upgrade_star(1,5) -> 
    #mount_upgrade_star{star_id=1,level=5,next_figure=311006,lim_star=8,radio=4096,lim_lucky=3,coin=4000,goods=[{311101,10}],attr=[{1,0},{13,36},{14,36},{15,36},{4,0},{3,36},{5,0},{6,0},{7,9},{8,0}]};
get_mount_upgrade_star(1,6) -> 
    #mount_upgrade_star{star_id=1,level=6,next_figure=311007,lim_star=10,radio=3630,lim_lucky=3,coin=5000,goods=[{311101,12}],attr=[{1,441},{13,0},{14,0},{15,0},{4,28},{3,0},{5,0},{6,25},{7,0},{8,29}]};
get_mount_upgrade_star(1,7) -> 
    #mount_upgrade_star{star_id=1,level=7,next_figure=311008,lim_star=10,radio=2904,lim_lucky=4,coin=5000,goods=[{311101,15}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,38},{5,20},{6,0},{7,12},{8,25}]};
get_mount_upgrade_star(1,8) -> 
    #mount_upgrade_star{star_id=1,level=8,next_figure=311009,lim_star=10,radio=2323,lim_lucky=5,coin=5000,goods=[{311101,20}],attr=[{1,537},{13,53},{14,53},{15,53},{4,53},{3,0},{5,0},{6,25},{7,0},{8,0}]};
get_mount_upgrade_star(1,9) -> 
    #mount_upgrade_star{star_id=1,level=9,next_figure=311010,lim_star=12,radio=2256,lim_lucky=5,coin=7000,goods=[{311101,25}],attr=[{1,460},{13,0},{14,0},{15,0},{4,0},{3,45},{5,28},{6,22},{7,0},{8,0}]};
get_mount_upgrade_star(1,10) -> 
    #mount_upgrade_star{star_id=1,level=10,next_figure=311011,lim_star=12,radio=1804,lim_lucky=6,coin=7000,goods=[{311101,30}],attr=[{1,691},{13,68},{14,68},{15,68},{4,0},{3,0},{5,0},{6,0},{7,25},{8,38}]};
get_mount_upgrade_star(1,11) -> 
    #mount_upgrade_star{star_id=1,level=11,next_figure=311012,lim_star=12,radio=1443,lim_lucky=7,coin=9000,goods=[{311101,35}],attr=[{1,691},{13,68},{14,68},{15,68},{4,0},{3,48},{5,0},{6,0},{7,22},{8,0}]};
get_mount_upgrade_star(2,1) -> 
    #mount_upgrade_star{star_id=2,level=1,next_figure=311002,lim_star=6,radio=8400,lim_lucky=1,coin=1000,goods=[{311101,2}],attr=[{1,0},{13,0},{14,0},{15,0},{4,53},{3,0},{5,0},{6,0},{7,9},{8,0}]};
get_mount_upgrade_star(2,2) -> 
    #mount_upgrade_star{star_id=2,level=2,next_figure=311003,lim_star=6,radio=7400,lim_lucky=1,coin=1500,goods=[{311101,4}],attr=[{1,0},{13,30},{14,30},{15,30},{4,0},{3,0},{5,0},{6,0},{7,15},{8,30}]};
get_mount_upgrade_star(2,3) -> 
    #mount_upgrade_star{star_id=2,level=3,next_figure=311004,lim_star=8,radio=5100,lim_lucky=2,coin=2000,goods=[{311101,6}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,40},{5,25},{6,20},{7,0},{8,0}]};
get_mount_upgrade_star(2,4) -> 
    #mount_upgrade_star{star_id=2,level=4,next_figure=311005,lim_star=8,radio=4080,lim_lucky=3,coin=3000,goods=[{311101,8}],attr=[{1,540},{13,36},{14,36},{15,36},{4,0},{3,0},{5,0},{6,0},{7,0},{8,36}]};
get_mount_upgrade_star(2,5) -> 
    #mount_upgrade_star{star_id=2,level=5,next_figure=311006,lim_star=8,radio=3264,lim_lucky=3,coin=4000,goods=[{311101,10}],attr=[{1,0},{13,53},{14,53},{15,53},{4,0},{3,53},{5,0},{6,0},{7,14},{8,0}]};
get_mount_upgrade_star(2,6) -> 
    #mount_upgrade_star{star_id=2,level=6,next_figure=311007,lim_star=10,radio=3120,lim_lucky=4,coin=5000,goods=[{311101,12}],attr=[{1,662},{13,0},{14,0},{15,0},{4,43},{3,0},{5,0},{6,39},{7,0},{8,46}]};
get_mount_upgrade_star(2,7) -> 
    #mount_upgrade_star{star_id=2,level=7,next_figure=311008,lim_star=10,radio=2496,lim_lucky=4,coin=5000,goods=[{311101,15}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,57},{5,30},{6,0},{7,19},{8,38}]};
get_mount_upgrade_star(2,8) -> 
    #mount_upgrade_star{star_id=2,level=8,next_figure=311009,lim_star=10,radio=1996,lim_lucky=5,coin=5000,goods=[{311101,20}],attr=[{1,806},{13,80},{14,80},{15,80},{4,80},{3,0},{5,0},{6,38},{7,0},{8,0}]};
get_mount_upgrade_star(2,9) -> 
    #mount_upgrade_star{star_id=2,level=9,next_figure=311010,lim_star=12,radio=1975,lim_lucky=5,coin=7000,goods=[{311101,25}],attr=[{1,691},{13,0},{14,0},{15,0},{4,0},{3,68},{5,44},{6,34},{7,0},{8,0}]};
get_mount_upgrade_star(2,10) -> 
    #mount_upgrade_star{star_id=2,level=10,next_figure=311011,lim_star=12,radio=1580,lim_lucky=7,coin=7000,goods=[{311101,30}],attr=[{1,1036},{13,103},{14,103},{15,103},{4,0},{3,0},{5,0},{6,0},{7,38},{8,57}]};
get_mount_upgrade_star(2,11) -> 
    #mount_upgrade_star{star_id=2,level=11,next_figure=311012,lim_star=12,radio=1264,lim_lucky=8,coin=9000,goods=[{311101,35}],attr=[{1,1036},{13,103},{14,103},{15,103},{4,0},{3,72},{5,0},{6,0},{7,34},{8,0}]};
get_mount_upgrade_star(3,1) -> 
    #mount_upgrade_star{star_id=3,level=1,next_figure=311002,lim_star=6,radio=7500,lim_lucky=1,coin=1000,goods=[{311101,2}],attr=[{1,0},{13,0},{14,0},{15,0},{4,75},{3,0},{5,0},{6,0},{7,13},{8,0}]};
get_mount_upgrade_star(3,2) -> 
    #mount_upgrade_star{star_id=3,level=2,next_figure=311003,lim_star=6,radio=6000,lim_lucky=1,coin=1500,goods=[{311101,4}],attr=[{1,0},{13,45},{14,45},{15,45},{4,0},{3,0},{5,0},{6,0},{7,21},{8,42}]};
get_mount_upgrade_star(3,3) -> 
    #mount_upgrade_star{star_id=3,level=3,next_figure=311004,lim_star=8,radio=4300,lim_lucky=2,coin=2000,goods=[{311101,6}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,54},{5,37},{6,31},{7,0},{8,0}]};
get_mount_upgrade_star(3,4) -> 
    #mount_upgrade_star{star_id=3,level=4,next_figure=311005,lim_star=8,radio=3440,lim_lucky=3,coin=3000,goods=[{311101,8}],attr=[{1,720},{13,48},{14,48},{15,48},{4,0},{3,0},{5,0},{6,0},{7,0},{8,50}]};
get_mount_upgrade_star(3,5) -> 
    #mount_upgrade_star{star_id=3,level=5,next_figure=311006,lim_star=8,radio=2752,lim_lucky=4,coin=4000,goods=[{311101,10}],attr=[{1,0},{13,72},{14,72},{15,72},{4,0},{3,72},{5,0},{6,0},{7,19},{8,0}]};
get_mount_upgrade_star(3,6) -> 
    #mount_upgrade_star{star_id=3,level=6,next_figure=311007,lim_star=10,radio=2950,lim_lucky=4,coin=5000,goods=[{311101,12}],attr=[{1,883},{13,0},{14,0},{15,0},{4,58},{3,0},{5,0},{6,51},{7,0},{8,60}]};
get_mount_upgrade_star(3,7) -> 
    #mount_upgrade_star{star_id=3,level=7,next_figure=311008,lim_star=10,radio=2360,lim_lucky=5,coin=5000,goods=[{311101,15}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,76},{5,40},{6,0},{7,25},{8,51}]};
get_mount_upgrade_star(3,8) -> 
    #mount_upgrade_star{star_id=3,level=8,next_figure=311009,lim_star=10,radio=1888,lim_lucky=6,coin=5000,goods=[{311101,20}],attr=[{1,1075},{13,107},{14,107},{15,107},{4,107},{3,0},{5,0},{6,51},{7,0},{8,0}]};
get_mount_upgrade_star(3,9) -> 
    #mount_upgrade_star{star_id=3,level=9,next_figure=311010,lim_star=12,radio=1756,lim_lucky=6,coin=7000,goods=[{311101,25}],attr=[{1,921},{13,0},{14,0},{15,0},{4,0},{3,92},{5,58},{6,45},{7,0},{8,0}]};
get_mount_upgrade_star(3,10) -> 
    #mount_upgrade_star{star_id=3,level=10,next_figure=311011,lim_star=12,radio=1404,lim_lucky=7,coin=7000,goods=[{311101,30}],attr=[{1,1382},{13,137},{14,137},{15,137},{4,0},{3,0},{5,0},{6,0},{7,51},{8,76}]};
get_mount_upgrade_star(3,11) -> 
    #mount_upgrade_star{star_id=3,level=11,next_figure=311012,lim_star=12,radio=1123,lim_lucky=9,coin=9000,goods=[{311101,35}],attr=[{1,1382},{13,137},{14,137},{15,137},{4,0},{3,96},{5,0},{6,0},{7,45},{8,0}]};
get_mount_upgrade_star(4,1) -> 
    #mount_upgrade_star{star_id=4,level=1,next_figure=311002,lim_star=6,radio=7000,lim_lucky=1,coin=1000,goods=[{311101,2}],attr=[{1,0},{13,0},{14,0},{15,0},{4,100},{3,0},{5,0},{6,0},{7,17},{8,0}]};
get_mount_upgrade_star(4,2) -> 
    #mount_upgrade_star{star_id=4,level=2,next_figure=311003,lim_star=6,radio=5200,lim_lucky=2,coin=1500,goods=[{311101,4}],attr=[{1,0},{13,60},{14,60},{15,60},{4,0},{3,0},{5,0},{6,0},{7,27},{8,54}]};
get_mount_upgrade_star(4,3) -> 
    #mount_upgrade_star{star_id=4,level=3,next_figure=311004,lim_star=8,radio=3200,lim_lucky=3,coin=2000,goods=[{311101,6}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,72},{5,54},{6,45},{7,0},{8,0}]};
get_mount_upgrade_star(4,4) -> 
    #mount_upgrade_star{star_id=4,level=4,next_figure=311005,lim_star=8,radio=2560,lim_lucky=4,coin=3000,goods=[{311101,8}],attr=[{1,960},{13,64},{14,64},{15,64},{4,0},{3,0},{5,0},{6,0},{7,0},{8,64}]};
get_mount_upgrade_star(4,5) -> 
    #mount_upgrade_star{star_id=4,level=5,next_figure=311006,lim_star=8,radio=2048,lim_lucky=5,coin=4000,goods=[{311101,10}],attr=[{1,0},{13,96},{14,96},{15,96},{4,0},{3,96},{5,0},{6,0},{7,25},{8,0}]};
get_mount_upgrade_star(4,6) -> 
    #mount_upgrade_star{star_id=4,level=6,next_figure=311007,lim_star=10,radio=2240,lim_lucky=5,coin=5000,goods=[{311101,12}],attr=[{1,1177},{13,0},{14,0},{15,0},{4,77},{3,0},{5,0},{6,69},{7,0},{8,80}]};
get_mount_upgrade_star(4,7) -> 
    #mount_upgrade_star{star_id=4,level=7,next_figure=311008,lim_star=10,radio=1792,lim_lucky=6,coin=5000,goods=[{311101,15}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,102},{5,54},{6,0},{7,33},{8,67}]};
get_mount_upgrade_star(4,8) -> 
    #mount_upgrade_star{star_id=4,level=8,next_figure=311009,lim_star=10,radio=1433,lim_lucky=7,coin=5000,goods=[{311101,20}],attr=[{1,1433},{13,143},{14,143},{15,143},{4,143},{3,0},{5,0},{6,67},{7,0},{8,0}]};
get_mount_upgrade_star(4,9) -> 
    #mount_upgrade_star{star_id=4,level=9,next_figure=311010,lim_star=12,radio=1435,lim_lucky=7,coin=7000,goods=[{311101,25}],attr=[{1,1190},{13,0},{14,0},{15,0},{4,0},{3,118},{5,75},{6,58},{7,0},{8,0}]};
get_mount_upgrade_star(4,10) -> 
    #mount_upgrade_star{star_id=4,level=10,next_figure=311011,lim_star=12,radio=1148,lim_lucky=9,coin=7000,goods=[{311101,30}],attr=[{1,1785},{13,178},{14,178},{15,178},{4,0},{3,0},{5,0},{6,0},{7,65},{8,99}]};
get_mount_upgrade_star(4,11) -> 
    #mount_upgrade_star{star_id=4,level=11,next_figure=311012,lim_star=12,radio=918,lim_lucky=11,coin=9000,goods=[{311101,35}],attr=[{1,1785},{13,178},{14,178},{15,178},{4,0},{3,124},{5,0},{6,0},{7,59},{8,0}]};
get_mount_upgrade_star(5,1) -> 
    #mount_upgrade_star{star_id=5,level=1,next_figure=311002,lim_star=6,radio=4000,lim_lucky=2,coin=1000,goods=[{311101,2}],attr=[{1,0},{13,0},{14,0},{15,0},{4,125},{3,0},{5,0},{6,0},{7,22},{8,0}]};
get_mount_upgrade_star(5,2) -> 
    #mount_upgrade_star{star_id=5,level=2,next_figure=311003,lim_star=6,radio=3500,lim_lucky=3,coin=1500,goods=[{311101,4}],attr=[{1,0},{13,80},{14,80},{15,80},{4,0},{3,0},{5,0},{6,0},{7,35},{8,70}]};
get_mount_upgrade_star(5,3) -> 
    #mount_upgrade_star{star_id=5,level=3,next_figure=311004,lim_star=8,radio=2100,lim_lucky=5,coin=2000,goods=[{311101,6}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,90},{5,70},{6,58},{7,0},{8,0}]};
get_mount_upgrade_star(5,4) -> 
    #mount_upgrade_star{star_id=5,level=4,next_figure=311005,lim_star=8,radio=1680,lim_lucky=6,coin=3000,goods=[{311101,8}],attr=[{1,1200},{13,80},{14,80},{15,80},{4,0},{3,0},{5,0},{6,0},{7,0},{8,80}]};
get_mount_upgrade_star(5,5) -> 
    #mount_upgrade_star{star_id=5,level=5,next_figure=311006,lim_star=8,radio=1344,lim_lucky=8,coin=4000,goods=[{311101,10}],attr=[{1,0},{13,120},{14,120},{15,120},{4,0},{3,120},{5,0},{6,0},{7,32},{8,0}]};
get_mount_upgrade_star(5,6) -> 
    #mount_upgrade_star{star_id=5,level=6,next_figure=311007,lim_star=10,radio=1880,lim_lucky=6,coin=5000,goods=[{311101,12}],attr=[{1,1472},{13,0},{14,0},{15,0},{4,96},{3,0},{5,0},{6,86},{7,0},{8,98}]};
get_mount_upgrade_star(5,7) -> 
    #mount_upgrade_star{star_id=5,level=7,next_figure=311008,lim_star=10,radio=1504,lim_lucky=7,coin=5000,goods=[{311101,15}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,128},{5,67},{6,0},{7,41},{8,84}]};
get_mount_upgrade_star(5,8) -> 
    #mount_upgrade_star{star_id=5,level=8,next_figure=311009,lim_star=10,radio=1203,lim_lucky=8,coin=5000,goods=[{311101,20}],attr=[{1,1792},{13,179},{14,179},{15,179},{4,179},{3,0},{5,0},{6,84},{7,0},{8,0}]};
get_mount_upgrade_star(5,9) -> 
    #mount_upgrade_star{star_id=5,level=9,next_figure=311010,lim_star=12,radio=1256,lim_lucky=8,coin=7000,goods=[{311101,25}],attr=[{1,1459},{13,0},{14,0},{15,0},{4,0},{3,145},{5,92},{6,71},{7,0},{8,0}]};
get_mount_upgrade_star(5,10) -> 
    #mount_upgrade_star{star_id=5,level=10,next_figure=311011,lim_star=12,radio=1004,lim_lucky=10,coin=7000,goods=[{311101,30}],attr=[{1,2188},{13,218},{14,218},{15,218},{4,0},{3,0},{5,0},{6,0},{7,80},{8,121}]};
get_mount_upgrade_star(5,11) -> 
    #mount_upgrade_star{star_id=5,level=11,next_figure=311012,lim_star=12,radio=803,lim_lucky=13,coin=9000,goods=[{311101,35}],attr=[{1,2188},{13,218},{14,218},{15,218},{4,0},{3,153},{5,0},{6,0},{7,72},{8,0}]};
get_mount_upgrade_star(6,3) -> 
    #mount_upgrade_star{star_id=6,level=3,next_figure=311004,lim_star=8,radio=1400,lim_lucky=7,coin=2000,goods=[{311101,6}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,117},{5,90},{6,74},{7,0},{8,0}]};
get_mount_upgrade_star(6,4) -> 
    #mount_upgrade_star{star_id=6,level=4,next_figure=311005,lim_star=8,radio=1120,lim_lucky=9,coin=3000,goods=[{311101,8}],attr=[{1,1560},{13,104},{14,104},{15,104},{4,0},{3,0},{5,0},{6,0},{7,0},{8,96}]};
get_mount_upgrade_star(6,5) -> 
    #mount_upgrade_star{star_id=6,level=5,next_figure=311006,lim_star=8,radio=896,lim_lucky=12,coin=4000,goods=[{311101,10}],attr=[{1,0},{13,156},{14,156},{15,156},{4,0},{3,156},{5,0},{6,0},{7,40},{8,0}]};
get_mount_upgrade_star(6,6) -> 
    #mount_upgrade_star{star_id=6,level=6,next_figure=311007,lim_star=10,radio=1650,lim_lucky=7,coin=5000,goods=[{311101,12}],attr=[{1,1766},{13,0},{14,0},{15,0},{4,115},{3,0},{5,0},{6,102},{7,0},{8,118}]};
get_mount_upgrade_star(6,7) -> 
    #mount_upgrade_star{star_id=6,level=7,next_figure=311008,lim_star=10,radio=1320,lim_lucky=8,coin=5000,goods=[{311101,15}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,153},{5,80},{6,0},{7,50},{8,100}]};
get_mount_upgrade_star(6,8) -> 
    #mount_upgrade_star{star_id=6,level=8,next_figure=311009,lim_star=10,radio=1056,lim_lucky=10,coin=5000,goods=[{311101,20}],attr=[{1,2150},{13,214},{14,214},{15,214},{4,214},{3,0},{5,0},{6,100},{7,0},{8,0}]};
get_mount_upgrade_star(6,9) -> 
    #mount_upgrade_star{star_id=6,level=9,next_figure=311010,lim_star=12,radio=1125,lim_lucky=9,coin=7000,goods=[{311101,25}],attr=[{1,1728},{13,0},{14,0},{15,0},{4,0},{3,172},{5,108},{6,84},{7,0},{8,0}]};
get_mount_upgrade_star(6,10) -> 
    #mount_upgrade_star{star_id=6,level=10,next_figure=311011,lim_star=12,radio=900,lim_lucky=12,coin=7000,goods=[{311101,30}],attr=[{1,2592},{13,259},{14,259},{15,259},{4,0},{3,0},{5,0},{6,0},{7,95},{8,144}]};
get_mount_upgrade_star(6,11) -> 
    #mount_upgrade_star{star_id=6,level=11,next_figure=311012,lim_star=12,radio=720,lim_lucky=14,coin=9000,goods=[{311101,35}],attr=[{1,2592},{13,259},{14,259},{15,259},{4,0},{3,181},{5,0},{6,0},{7,86},{8,0}]};
get_mount_upgrade_star(7,3) -> 
    #mount_upgrade_star{star_id=7,level=3,next_figure=311004,lim_star=8,radio=1200,lim_lucky=9,coin=2000,goods=[{311101,6}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,144},{5,109},{6,90},{7,0},{8,0}]};
get_mount_upgrade_star(7,4) -> 
    #mount_upgrade_star{star_id=7,level=4,next_figure=311005,lim_star=8,radio=960,lim_lucky=12,coin=3000,goods=[{311101,8}],attr=[{1,1920},{13,128},{14,128},{15,128},{4,0},{3,0},{5,0},{6,0},{7,0},{8,116}]};
get_mount_upgrade_star(7,5) -> 
    #mount_upgrade_star{star_id=7,level=5,next_figure=311006,lim_star=8,radio=768,lim_lucky=15,coin=4000,goods=[{311101,10}],attr=[{1,0},{13,192},{14,192},{15,192},{4,0},{3,192},{5,0},{6,0},{7,48},{8,0}]};
get_mount_upgrade_star(7,6) -> 
    #mount_upgrade_star{star_id=7,level=6,next_figure=311007,lim_star=10,radio=1210,lim_lucky=8,coin=5000,goods=[{311101,12}],attr=[{1,2060},{13,0},{14,0},{15,0},{4,134},{3,0},{5,0},{6,119},{7,0},{8,138}]};
get_mount_upgrade_star(7,7) -> 
    #mount_upgrade_star{star_id=7,level=7,next_figure=311008,lim_star=10,radio=968,lim_lucky=11,coin=5000,goods=[{311101,15}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,179},{5,94},{6,0},{7,58},{8,117}]};
get_mount_upgrade_star(7,8) -> 
    #mount_upgrade_star{star_id=7,level=8,next_figure=311009,lim_star=10,radio=774,lim_lucky=13,coin=5000,goods=[{311101,20}],attr=[{1,2508},{13,250},{14,250},{15,250},{4,250},{3,0},{5,0},{6,118},{7,0},{8,0}]};
get_mount_upgrade_star(7,9) -> 
    #mount_upgrade_star{star_id=7,level=9,next_figure=311010,lim_star=12,radio=1021,lim_lucky=10,coin=7000,goods=[{311101,25}],attr=[{1,1996},{13,0},{14,0},{15,0},{4,0},{3,199},{5,124},{6,96},{7,0},{8,0}]};
get_mount_upgrade_star(7,10) -> 
    #mount_upgrade_star{star_id=7,level=10,next_figure=311011,lim_star=12,radio=816,lim_lucky=13,coin=7000,goods=[{311101,30}],attr=[{1,2995},{13,299},{14,299},{15,299},{4,0},{3,0},{5,0},{6,0},{7,109},{8,166}]};
get_mount_upgrade_star(7,11) -> 
    #mount_upgrade_star{star_id=7,level=11,next_figure=311012,lim_star=12,radio=652,lim_lucky=16,coin=9000,goods=[{311101,35}],attr=[{1,2995},{13,299},{14,299},{15,299},{4,0},{3,209},{5,0},{6,0},{7,99},{8,0}]};
get_mount_upgrade_star(8,6) -> 
    #mount_upgrade_star{star_id=8,level=6,next_figure=311007,lim_star=10,radio=962,lim_lucky=12,coin=5000,goods=[{311101,12}],attr=[{1,2428},{13,0},{14,0},{15,0},{4,157},{3,0},{5,0},{6,140},{7,0},{8,161}]};
get_mount_upgrade_star(8,7) -> 
    #mount_upgrade_star{star_id=8,level=7,next_figure=311008,lim_star=10,radio=769,lim_lucky=13,coin=5000,goods=[{311101,15}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,211},{5,111},{6,0},{7,68},{8,137}]};
get_mount_upgrade_star(8,8) -> 
    #mount_upgrade_star{star_id=8,level=8,next_figure=311009,lim_star=10,radio=615,lim_lucky=17,coin=5000,goods=[{311101,20}],attr=[{1,2956},{13,295},{14,295},{15,295},{4,295},{3,0},{5,0},{6,138},{7,0},{8,0}]};
get_mount_upgrade_star(8,9) -> 
    #mount_upgrade_star{star_id=8,level=9,next_figure=311010,lim_star=12,radio=810,lim_lucky=13,coin=7000,goods=[{311101,25}],attr=[{1,2304},{13,0},{14,0},{15,0},{4,0},{3,230},{5,144},{6,112},{7,0},{8,0}]};
get_mount_upgrade_star(8,10) -> 
    #mount_upgrade_star{star_id=8,level=10,next_figure=311011,lim_star=12,radio=648,lim_lucky=16,coin=7000,goods=[{311101,30}],attr=[{1,3456},{13,345},{14,345},{15,345},{4,0},{3,0},{5,0},{6,0},{7,126},{8,192}]};
get_mount_upgrade_star(8,11) -> 
    #mount_upgrade_star{star_id=8,level=11,next_figure=311012,lim_star=12,radio=518,lim_lucky=20,coin=9000,goods=[{311101,35}],attr=[{1,3456},{13,345},{14,345},{15,345},{4,0},{3,241},{5,0},{6,0},{7,115},{8,0}]};
get_mount_upgrade_star(9,6) -> 
    #mount_upgrade_star{star_id=9,level=6,next_figure=311007,lim_star=10,radio=455,lim_lucky=23,coin=5000,goods=[{311101,12}],attr=[{1,2870},{13,0},{14,0},{15,0},{4,187},{3,0},{5,0},{6,165},{7,0},{8,188}]};
get_mount_upgrade_star(9,7) -> 
    #mount_upgrade_star{star_id=9,level=7,next_figure=311008,lim_star=10,radio=364,lim_lucky=28,coin=5000,goods=[{311101,15}],attr=[{1,0},{13,0},{14,0},{15,0},{4,0},{3,249},{5,131},{6,0},{7,80},{8,162}]};
get_mount_upgrade_star(9,8) -> 
    #mount_upgrade_star{star_id=9,level=8,next_figure=311009,lim_star=10,radio=291,lim_lucky=35,coin=5000,goods=[{311101,20}],attr=[{1,3494},{13,348},{14,348},{15,348},{4,348},{3,0},{5,0},{6,163},{7,0},{8,0}]};
get_mount_upgrade_star(9,9) -> 
    #mount_upgrade_star{star_id=9,level=9,next_figure=311010,lim_star=12,radio=768,lim_lucky=13,coin=7000,goods=[{311101,25}],attr=[{1,2611},{13,0},{14,0},{15,0},{4,0},{3,260},{5,163},{6,126},{7,0},{8,0}]};
get_mount_upgrade_star(9,10) -> 
    #mount_upgrade_star{star_id=9,level=10,next_figure=311011,lim_star=12,radio=614,lim_lucky=17,coin=7000,goods=[{311101,30}],attr=[{1,3916},{13,391},{14,391},{15,391},{4,0},{3,0},{5,0},{6,0},{7,143},{8,217}]};
get_mount_upgrade_star(9,11) -> 
    #mount_upgrade_star{star_id=9,level=11,next_figure=311012,lim_star=12,radio=491,lim_lucky=21,coin=9000,goods=[{311101,35}],attr=[{1,3916},{13,391},{14,391},{15,391},{4,0},{3,273},{5,0},{6,0},{7,130},{8,0}]};
get_mount_upgrade_star(10,9) -> 
    #mount_upgrade_star{star_id=10,level=9,next_figure=311010,lim_star=12,radio=587,lim_lucky=18,coin=7000,goods=[{311101,25}],attr=[{1,2956},{13,0},{14,0},{15,0},{4,0},{3,295},{5,184},{6,142},{7,0},{8,0}]};
get_mount_upgrade_star(10,10) -> 
    #mount_upgrade_star{star_id=10,level=10,next_figure=311011,lim_star=12,radio=469,lim_lucky=22,coin=7000,goods=[{311101,30}],attr=[{1,4435},{13,443},{14,443},{15,443},{4,0},{3,0},{5,0},{6,0},{7,161},{8,246}]};
get_mount_upgrade_star(10,11) -> 
    #mount_upgrade_star{star_id=10,level=11,next_figure=311012,lim_star=12,radio=375,lim_lucky=27,coin=9000,goods=[{311101,35}],attr=[{1,4435},{13,443},{14,443},{15,443},{4,0},{3,309},{5,0},{6,0},{7,147},{8,0}]};
get_mount_upgrade_star(11,9) -> 
    #mount_upgrade_star{star_id=11,level=9,next_figure=311010,lim_star=12,radio=235,lim_lucky=43,coin=7000,goods=[{311101,25}],attr=[{1,3340},{13,0},{14,0},{15,0},{4,0},{3,333},{5,208},{6,160},{7,0},{8,0}]};
get_mount_upgrade_star(11,10) -> 
    #mount_upgrade_star{star_id=11,level=10,next_figure=311011,lim_star=12,radio=188,lim_lucky=54,coin=7000,goods=[{311101,30}],attr=[{1,5011},{13,500},{14,500},{15,500},{4,0},{3,0},{5,0},{6,0},{7,182},{8,278}]};
get_mount_upgrade_star(11,11) -> 
    #mount_upgrade_star{star_id=11,level=11,next_figure=311012,lim_star=12,radio=150,lim_lucky=67,coin=9000,goods=[{311101,35}],attr=[{1,5011},{13,500},{14,500},{15,500},{4,0},{3,348},{5,0},{6,0},{7,166},{8,0}]};
get_mount_upgrade_star(_Lv, _Level) -> [].

%% 当前资质额外星级属性加成
%% 参数是等级QualityLv

get_mount_quality(0) -> 
    #mount_quality{quality_lv=0,quality_lim_star=0,attr=[],quality_max_lv=800};
get_mount_quality(1) -> 
    #mount_quality{quality_lv=1,quality_lim_star=50,attr=[{3,30},{1,300},{7,8},{16,30}],quality_max_lv=800};
get_mount_quality(2) -> 
    #mount_quality{quality_lv=2,quality_lim_star=150,attr=[{3,60},{1,600},{7,15},{16,60}],quality_max_lv=800};
get_mount_quality(3) -> 
    #mount_quality{quality_lv=3,quality_lim_star=300,attr=[{3,100},{1,1000},{7,20},{16,100}],quality_max_lv=800};
get_mount_quality(4) -> 
    #mount_quality{quality_lv=4,quality_lim_star=500,attr=[{3,150},{1,1500},{7,35},{16,150}],quality_max_lv=800};
get_mount_quality(5) -> 
    #mount_quality{quality_lv=5,quality_lim_star=800,attr=[{3,200},{1,2000},{7,50},{16,200}],quality_max_lv=800};
get_mount_quality(_Lv) -> [].

%% 参数：形象id

get_mount_figure(311501) -> 
    #figure_attr_add{figure_id=311501,attr=[{1,200},{4,20},{3,20}],time=0};
get_mount_figure(311502) -> 
    #figure_attr_add{figure_id=311502,attr=[{1,200},{4,20},{3,20}],time=0};
get_mount_figure(311503) -> 
    #figure_attr_add{figure_id=311503,attr=[{1,200},{4,20},{3,20}],time=0};
get_mount_figure(311504) -> 
    #figure_attr_add{figure_id=311504,attr=[{1,200},{4,20},{3,20}],time=0};
get_mount_figure(311505) -> 
    #figure_attr_add{figure_id=311505,attr=[{1,200},{4,20},{3,20}],time=0};
get_mount_figure(311506) -> 
    #figure_attr_add{figure_id=311506,attr=[{1,200},{4,20},{3,20}],time=0};
get_mount_figure(311507) -> 
    #figure_attr_add{figure_id=311507,attr=[{1,200},{4,20},{3,20}],time=0};
get_mount_figure(311508) -> 
    #figure_attr_add{figure_id=311508,attr=[{1,200},{4,20},{3,20}],time=0};
get_mount_figure(311509) -> 
    #figure_attr_add{figure_id=311509,attr=[{1,200},{4,20},{3,20}],time=0};
get_mount_figure(311510) -> 
    #figure_attr_add{figure_id=311510,attr=[{1,200},{4,20},{3,20}],time=0};
get_mount_figure(_FigureId) -> [].

%%　参数两种培养类型１和２
get_mount_quality_attr_cfg(1) -> 
    #mount_quality_attr_cfg{train_type=1,goods=[],coin=20000,att_cfg=[{att_grow,5}, {max_star, 100}, {max_attr, 500}, {radio, [{-2,100},{-1,350},{0,550},{1,900},{2,1000}]}],hp_cfg=[{hp_grow,70}, {max_star, 100}, {max_attr, 7000}, {radio, [{-2,100},{-1,350},{0,550},{1,900},{2,1000}]}],def_cfg=[{def_grow,8}, {max_star, 100}, {max_attr, 800}, {radio, [{-2,100},{-1,350},{0,550},{1,900},{2,1000}]}],resist_cfg=[{resist_grow,8}, {max_star, 100}, {max_attr, 800}, {radio, [{-2,100},{-1,350},{0,550},{1,900},{2,1000}]}],hit_cfg=[{hit_grow,8}, {max_star, 100}, {max_attr, 800}, {radio, [{-2,100},{-1,350},{0,550},{1,900},{2,1000}]}],dodge_cfg=[{dodge_grow,6}, {max_star, 100}, {max_attr, 600}, {radio, [{-2,100},{-1,100},{0,200},{1,400},{2,810}]}],crit_cfg=[{crit_grow,4}, {max_star, 100}, {max_attr, 400}, {radio, [{-2,100},{-1,350},{0,550},{1,900},{2,1000}]}],ten_cfg=[{ten_grow,8}, {max_star, 100}, {max_attr, 800}, {radio, [{-2,100},{-1,350},{0,550},{1,900},{2,1000}]}]};
get_mount_quality_attr_cfg(2) -> 
    #mount_quality_attr_cfg{train_type=2,goods=[{311201,1}],coin=0,att_cfg=[{att_grow,5}, {max_star, 100}, {max_attr, 500}, {radio, [{-2,60},{-1,260},{0,580},{1,790},{2,950},{3,1000}]}],hp_cfg=[{hp_grow,70}, {max_star, 100}, {max_attr, 7000}, {radio, [{-2,60},{-1,260},{0,580},{1,790},{2,950},{3,1000}]}],def_cfg=[{def_grow,8}, {max_star, 100}, {max_attr, 800}, {radio, [{-2,60},{-1,260},{0,580},{1,790},{2,950},{3,1000}]}],resist_cfg=[{resist_grow,8}, {max_star, 100}, {max_attr, 800}, {radio, [{-2,60},{-1,260},{0,580},{1,790},{2,950},{3,1000}]}],hit_cfg=[{hit_grow,8}, {max_star, 100}, {max_attr, 800}, {radio, [{-2,60},{-1,260},{0,580},{1,790},{2,950},{3,1000}]}],dodge_cfg=[{dodge_grow,6}, {max_star, 100}, {max_attr, 600}, {radio, [{-2,100},{-1,100},{0,200},{1,400},{2,810}]}],crit_cfg=[{crit_grow,4}, {max_star, 100}, {max_attr, 400}, {radio, [{-2,60},{-1,260},{0,580},{1,790},{2,950},{3,1000}]}],ten_cfg=[{ten_grow,8}, {max_star, 100}, {max_attr, 800}, {radio, [{-2,60},{-1,260},{0,580},{1,790},{2,950},{3,1000}]}]};
get_mount_quality_attr_cfg(_TrainType)-> [].

%%  参数灵犀丹物品id

get_mount_lingxi_good(311601) -> 
    #mount_lingxi_good{good_id=311601,lingxi_num=5,attr=[{1,100},{4,100},{13,100},{14,100},{15,100}]};
get_mount_lingxi_good(311602) -> 
    #mount_lingxi_good{good_id=311602,lingxi_num=10,attr=[{1,100},{4,100},{13,100},{14,100},{15,100}]};
get_mount_lingxi_good(311603) -> 
    #mount_lingxi_good{good_id=311603,lingxi_num=20,attr=[{1,100},{4,100},{13,100},{14,100},{15,100}]};
get_mount_lingxi_good(_GoodId) -> [].

%% 参数:灵犀等级

get_mount_lingxi_lv(0) -> 
    #mount_lingxi_lv{lv=0,lingxi_p=0,light_effect_list=[],lim_attr=[{13,5000},{14,5000},{15,5000},{1,50000},{4,5000}],max_lv=5};
get_mount_lingxi_lv(1) -> 
    #mount_lingxi_lv{lv=1,lingxi_p=30,light_effect_list=[],lim_attr=[{13,5000},{14,5000},{15,5000},{1,50000},{4,5000}],max_lv=5};
get_mount_lingxi_lv(2) -> 
    #mount_lingxi_lv{lv=2,lingxi_p=75,light_effect_list=[],lim_attr=[{13,5000},{14,5000},{15,5000},{1,50000},{4,5000}],max_lv=5};
get_mount_lingxi_lv(3) -> 
    #mount_lingxi_lv{lv=3,lingxi_p=150,light_effect_list=[],lim_attr=[{13,5000},{14,5000},{15,5000},{1,50000},{4,5000}],max_lv=5};
get_mount_lingxi_lv(4) -> 
    #mount_lingxi_lv{lv=4,lingxi_p=225,light_effect_list=[],lim_attr=[{13,5000},{14,5000},{15,5000},{1,50000},{4,5000}],max_lv=5};
get_mount_lingxi_lv(5) -> 
    #mount_lingxi_lv{lv=5,lingxi_p=300,light_effect_list=[],lim_attr=[{13,5000},{14,5000},{15,5000},{1,50000},{4,5000}],max_lv=5};
get_mount_lingxi_lv(_Lv) -> [].

