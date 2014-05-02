
%%%---------------------------------------
%%% @Module  : data_reiki
%%% @Author  : faiy
%%% @Created : 2014-04-29 16:16:32
%%% @Description:  自动生成
%%%---------------------------------------
-module(data_reiki).
-compile(export_all).
-include("reiki.hrl").
get_level(101043) ->
	    #reiki_level{id=101043,level=35};
get_level(101044) ->
	    #reiki_level{id=101044,level=40};
get_level(101048) ->
	    #reiki_level{id=101048,level=35};
get_level(101049) ->
	    #reiki_level{id=101049,level=40};
get_level(101053) ->
	    #reiki_level{id=101053,level=45};
get_level(101054) ->
	    #reiki_level{id=101054,level=50};
get_level(101058) ->
	    #reiki_level{id=101058,level=45};
get_level(101059) ->
	    #reiki_level{id=101059,level=50};
get_level(101060) ->
	    #reiki_level{id=101060,level=75};
get_level(101063) ->
	    #reiki_level{id=101063,level=55};
get_level(101064) ->
	    #reiki_level{id=101064,level=60};
get_level(101065) ->
	    #reiki_level{id=101065,level=75};
get_level(101068) ->
	    #reiki_level{id=101068,level=55};
get_level(101069) ->
	    #reiki_level{id=101069,level=60};
get_level(101070) ->
	    #reiki_level{id=101070,level=80};
get_level(101073) ->
	    #reiki_level{id=101073,level=65};
get_level(101074) ->
	    #reiki_level{id=101074,level=70};
get_level(101075) ->
	    #reiki_level{id=101075,level=80};
get_level(101078) ->
	    #reiki_level{id=101078,level=65};
get_level(101079) ->
	    #reiki_level{id=101079,level=70};
get_level(102043) ->
	    #reiki_level{id=102043,level=35};
get_level(102044) ->
	    #reiki_level{id=102044,level=40};
get_level(102048) ->
	    #reiki_level{id=102048,level=35};
get_level(102049) ->
	    #reiki_level{id=102049,level=40};
get_level(102053) ->
	    #reiki_level{id=102053,level=45};
get_level(102054) ->
	    #reiki_level{id=102054,level=50};
get_level(102058) ->
	    #reiki_level{id=102058,level=45};
get_level(102059) ->
	    #reiki_level{id=102059,level=50};
get_level(102060) ->
	    #reiki_level{id=102060,level=75};
get_level(102063) ->
	    #reiki_level{id=102063,level=55};
get_level(102064) ->
	    #reiki_level{id=102064,level=60};
get_level(102065) ->
	    #reiki_level{id=102065,level=75};
get_level(102068) ->
	    #reiki_level{id=102068,level=55};
get_level(102069) ->
	    #reiki_level{id=102069,level=60};
get_level(102070) ->
	    #reiki_level{id=102070,level=80};
get_level(102073) ->
	    #reiki_level{id=102073,level=65};
get_level(102074) ->
	    #reiki_level{id=102074,level=70};
get_level(102075) ->
	    #reiki_level{id=102075,level=80};
get_level(102078) ->
	    #reiki_level{id=102078,level=65};
get_level(102079) ->
	    #reiki_level{id=102079,level=70};
get_level(103043) ->
	    #reiki_level{id=103043,level=35};
get_level(103044) ->
	    #reiki_level{id=103044,level=40};
get_level(103048) ->
	    #reiki_level{id=103048,level=35};
get_level(103049) ->
	    #reiki_level{id=103049,level=40};
get_level(103053) ->
	    #reiki_level{id=103053,level=45};
get_level(103054) ->
	    #reiki_level{id=103054,level=50};
get_level(103058) ->
	    #reiki_level{id=103058,level=45};
get_level(103059) ->
	    #reiki_level{id=103059,level=50};
get_level(103060) ->
	    #reiki_level{id=103060,level=75};
get_level(103063) ->
	    #reiki_level{id=103063,level=55};
get_level(103064) ->
	    #reiki_level{id=103064,level=60};
get_level(103065) ->
	    #reiki_level{id=103065,level=75};
get_level(103068) ->
	    #reiki_level{id=103068,level=55};
get_level(103069) ->
	    #reiki_level{id=103069,level=60};
get_level(103070) ->
	    #reiki_level{id=103070,level=80};
get_level(103073) ->
	    #reiki_level{id=103073,level=65};
get_level(103074) ->
	    #reiki_level{id=103074,level=70};
get_level(103075) ->
	    #reiki_level{id=103075,level=80};
get_level(103078) ->
	    #reiki_level{id=103078,level=65};
get_level(103079) ->
	    #reiki_level{id=103079,level=70};
get_level(_Id) ->
	    	[].
get_cost(10,1)->
    	#reiki_cost{type=10,level=1,value=[3,5],llpt=100,times=5,radio=100};
get_cost(10,2)->
    	#reiki_cost{type=10,level=2,value=[3,10],llpt=325,times=5,radio=100};
get_cost(10,3)->
    	#reiki_cost{type=10,level=3,value=[3,15],llpt=650,times=5,radio=100};
get_cost(10,4)->
    	#reiki_cost{type=10,level=4,value=[3,20],llpt=1060,times=5,radio=100};
get_cost(10,5)->
    	#reiki_cost{type=10,level=5,value=[3,25],llpt=1315,times=5,radio=100};
get_cost(10,6)->
    	#reiki_cost{type=10,level=6,value=[3,30],llpt=1790,times=5,radio=95};
get_cost(10,7)->
    	#reiki_cost{type=10,level=7,value=[3,35],llpt=2325,times=5,radio=95};
get_cost(10,8)->
    	#reiki_cost{type=10,level=8,value=[3,40],llpt=2920,times=5,radio=95};
get_cost(10,9)->
    	#reiki_cost{type=10,level=9,value=[3,45],llpt=3565,times=5,radio=95};
get_cost(10,10)->
    	#reiki_cost{type=10,level=10,value=[3,50],llpt=4265,times=5,radio=95};
get_cost(10,11)->
    	#reiki_cost{type=10,level=11,value=[3,55],llpt=5015,times=5,radio=90};
get_cost(10,12)->
    	#reiki_cost{type=10,level=12,value=[3,60],llpt=5810,times=5,radio=90};
get_cost(10,13)->
    	#reiki_cost{type=10,level=13,value=[3,65],llpt=6660,times=5,radio=90};
get_cost(10,14)->
    	#reiki_cost{type=10,level=14,value=[3,70],llpt=7555,times=5,radio=90};
get_cost(10,15)->
    	#reiki_cost{type=10,level=15,value=[3,75],llpt=8495,times=5,radio=90};
get_cost(10,16)->
    	#reiki_cost{type=10,level=16,value=[3,80],llpt=9475,times=5,radio=90};
get_cost(10,17)->
    	#reiki_cost{type=10,level=17,value=[3,85],llpt=10505,times=5,radio=90};
get_cost(10,18)->
    	#reiki_cost{type=10,level=18,value=[3,90],llpt=11575,times=5,radio=90};
get_cost(10,19)->
    	#reiki_cost{type=10,level=19,value=[3,95],llpt=12690,times=5,radio=90};
get_cost(10,20)->
    	#reiki_cost{type=10,level=20,value=[3,100],llpt=13845,times=5,radio=90};
get_cost(10,21)->
    	#reiki_cost{type=10,level=21,value=[3,105],llpt=15045,times=5,radio=80};
get_cost(10,22)->
    	#reiki_cost{type=10,level=22,value=[3,110],llpt=16280,times=5,radio=80};
get_cost(10,23)->
    	#reiki_cost{type=10,level=23,value=[3,115],llpt=17560,times=5,radio=80};
get_cost(10,24)->
    	#reiki_cost{type=10,level=24,value=[3,120],llpt=18875,times=5,radio=80};
get_cost(10,25)->
    	#reiki_cost{type=10,level=25,value=[3,125],llpt=20230,times=5,radio=80};
get_cost(10,26)->
    	#reiki_cost{type=10,level=26,value=[3,130],llpt=21625,times=5,radio=80};
get_cost(10,27)->
    	#reiki_cost{type=10,level=27,value=[3,135],llpt=23060,times=5,radio=80};
get_cost(10,28)->
    	#reiki_cost{type=10,level=28,value=[3,140],llpt=24530,times=5,radio=80};
get_cost(10,29)->
    	#reiki_cost{type=10,level=29,value=[3,145],llpt=26040,times=5,radio=80};
get_cost(10,30)->
    	#reiki_cost{type=10,level=30,value=[3,150],llpt=27580,times=5,radio=80};
get_cost(10,31)->
    	#reiki_cost{type=10,level=31,value=[3,155],llpt=29160,times=5,radio=70};
get_cost(10,32)->
    	#reiki_cost{type=10,level=32,value=[3,160],llpt=30775,times=5,radio=70};
get_cost(10,33)->
    	#reiki_cost{type=10,level=33,value=[3,165],llpt=32430,times=5,radio=70};
get_cost(10,34)->
    	#reiki_cost{type=10,level=34,value=[3,170],llpt=34115,times=5,radio=70};
get_cost(10,35)->
    	#reiki_cost{type=10,level=35,value=[3,175],llpt=35845,times=5,radio=70};
get_cost(10,36)->
    	#reiki_cost{type=10,level=36,value=[3,180],llpt=37600,times=5,radio=70};
get_cost(10,37)->
    	#reiki_cost{type=10,level=37,value=[3,185],llpt=39390,times=5,radio=70};
get_cost(10,38)->
    	#reiki_cost{type=10,level=38,value=[3,190],llpt=41220,times=5,radio=70};
get_cost(10,39)->
    	#reiki_cost{type=10,level=39,value=[3,195],llpt=43080,times=5,radio=70};
get_cost(10,40)->
    	#reiki_cost{type=10,level=40,value=[3,200],llpt=44975,times=5,radio=70};
get_cost(10,41)->
    	#reiki_cost{type=10,level=41,value=[3,205],llpt=46900,times=6,radio=65};
get_cost(10,42)->
    	#reiki_cost{type=10,level=42,value=[3,210],llpt=48865,times=6,radio=65};
get_cost(10,43)->
    	#reiki_cost{type=10,level=43,value=[3,215],llpt=50860,times=6,radio=65};
get_cost(10,44)->
    	#reiki_cost{type=10,level=44,value=[3,220],llpt=59245,times=6,radio=65};
get_cost(10,45)->
    	#reiki_cost{type=10,level=45,value=[3,225],llpt=66460,times=6,radio=65};
get_cost(10,46)->
    	#reiki_cost{type=10,level=46,value=[3,230],llpt=77470,times=6,radio=65};
get_cost(10,47)->
    	#reiki_cost{type=10,level=47,value=[3,235],llpt=86940,times=6,radio=65};
get_cost(10,48)->
    	#reiki_cost{type=10,level=48,value=[3,240],llpt=109580,times=6,radio=65};
get_cost(10,49)->
    	#reiki_cost{type=10,level=49,value=[3,245],llpt=138295,times=6,radio=65};
get_cost(10,50)->
    	#reiki_cost{type=10,level=50,value=[3,250],llpt=174755,times=6,radio=65};
get_cost(10,51)->
    	#reiki_cost{type=10,level=51,value=[3,255],llpt=181630,times=6,radio=55};
get_cost(10,52)->
    	#reiki_cost{type=10,level=52,value=[3,260],llpt=188645,times=6,radio=55};
get_cost(10,53)->
    	#reiki_cost{type=10,level=53,value=[3,265],llpt=195780,times=6,radio=55};
get_cost(10,54)->
    	#reiki_cost{type=10,level=54,value=[3,270],llpt=203045,times=6,radio=55};
get_cost(10,55)->
    	#reiki_cost{type=10,level=55,value=[3,275],llpt=210445,times=6,radio=55};
get_cost(10,56)->
    	#reiki_cost{type=10,level=56,value=[3,280],llpt=217970,times=7,radio=50};
get_cost(10,57)->
    	#reiki_cost{type=10,level=57,value=[3,285],llpt=225620,times=7,radio=50};
get_cost(10,58)->
    	#reiki_cost{type=10,level=58,value=[3,290],llpt=233405,times=7,radio=50};
get_cost(10,59)->
    	#reiki_cost{type=10,level=59,value=[3,295],llpt=241315,times=7,radio=50};
get_cost(10,60)->
    	#reiki_cost{type=10,level=60,value=[3,300],llpt=249360,times=7,radio=50};
get_cost(10,61)->
    	#reiki_cost{type=10,level=61,value=[3,305],llpt=257525,times=7,radio=45};
get_cost(10,62)->
    	#reiki_cost{type=10,level=62,value=[3,310],llpt=265825,times=7,radio=45};
get_cost(10,63)->
    	#reiki_cost{type=10,level=63,value=[3,315],llpt=274245,times=7,radio=45};
get_cost(10,64)->
    	#reiki_cost{type=10,level=64,value=[3,320],llpt=282795,times=7,radio=45};
get_cost(10,65)->
    	#reiki_cost{type=10,level=65,value=[3,325],llpt=291480,times=7,radio=45};
get_cost(10,66)->
    	#reiki_cost{type=10,level=66,value=[3,330],llpt=300285,times=8,radio=40};
get_cost(10,67)->
    	#reiki_cost{type=10,level=67,value=[3,335],llpt=309225,times=8,radio=40};
get_cost(10,68)->
    	#reiki_cost{type=10,level=68,value=[3,340],llpt=318285,times=8,radio=40};
get_cost(10,69)->
    	#reiki_cost{type=10,level=69,value=[3,345],llpt=327480,times=8,radio=40};
get_cost(10,70)->
    	#reiki_cost{type=10,level=70,value=[3,350],llpt=336795,times=8,radio=40};
get_cost(10,71)->
    	#reiki_cost{type=10,level=71,value=[3,355],llpt=346240,times=8,radio=35};
get_cost(10,72)->
    	#reiki_cost{type=10,level=72,value=[3,360],llpt=355810,times=8,radio=35};
get_cost(10,73)->
    	#reiki_cost{type=10,level=73,value=[3,365],llpt=365515,times=8,radio=35};
get_cost(10,74)->
    	#reiki_cost{type=10,level=74,value=[3,370],llpt=375340,times=8,radio=35};
get_cost(10,75)->
    	#reiki_cost{type=10,level=75,value=[3,375],llpt=385295,times=8,radio=35};
get_cost(10,76)->
    	#reiki_cost{type=10,level=76,value=[3,380],llpt=395375,times=9,radio=30};
get_cost(10,77)->
    	#reiki_cost{type=10,level=77,value=[3,385],llpt=405585,times=9,radio=30};
get_cost(10,78)->
    	#reiki_cost{type=10,level=78,value=[3,390],llpt=415920,times=9,radio=30};
get_cost(10,79)->
    	#reiki_cost{type=10,level=79,value=[3,395],llpt=426380,times=9,radio=30};
get_cost(10,80)->
    	#reiki_cost{type=10,level=80,value=[3,400],llpt=436965,times=9,radio=30};
get_cost(_Type,_Level) ->
	    	[].
get_reiki_up(1)->
    	#reiki_up{level=1,need_level=5,gold=40,forza=5,agile=5,wit=5,thew=5};
get_reiki_up(2)->
    	#reiki_up{level=2,need_level=10,gold=50,forza=10,agile=10,wit=10,thew=10};
get_reiki_up(3)->
    	#reiki_up{level=3,need_level=15,gold=60,forza=15,agile=15,wit=15,thew=15};
get_reiki_up(4)->
    	#reiki_up{level=4,need_level=20,gold=70,forza=20,agile=20,wit=20,thew=20};
get_reiki_up(5)->
    	#reiki_up{level=5,need_level=25,gold=80,forza=25,agile=25,wit=25,thew=25};
get_reiki_up(6)->
    	#reiki_up{level=6,need_level=30,gold=90,forza=30,agile=30,wit=30,thew=30};
get_reiki_up(7)->
    	#reiki_up{level=7,need_level=35,gold=100,forza=35,agile=35,wit=35,thew=35};
get_reiki_up(8)->
    	#reiki_up{level=8,need_level=40,gold=110,forza=40,agile=40,wit=40,thew=40};
get_reiki_up(9)->
    	#reiki_up{level=9,need_level=45,gold=120,forza=45,agile=45,wit=45,thew=45};
get_reiki_up(10)->
    	#reiki_up{level=10,need_level=50,gold=150,forza=50,agile=50,wit=50,thew=50};
get_reiki_up(11)->
    	#reiki_up{level=11,need_level=55,gold=180,forza=55,agile=55,wit=55,thew=55};
get_reiki_up(12)->
    	#reiki_up{level=12,need_level=60,gold=220,forza=60,agile=60,wit=60,thew=60};
get_reiki_up(13)->
    	#reiki_up{level=13,need_level=65,gold=250,forza=65,agile=65,wit=65,thew=65};
get_reiki_up(14)->
    	#reiki_up{level=14,need_level=70,gold=300,forza=70,agile=70,wit=70,thew=70};
get_reiki_up(15)->
    	#reiki_up{level=15,need_level=75,gold=350,forza=75,agile=75,wit=75,thew=75};
get_reiki_up(16)->
    	#reiki_up{level=16,need_level=80,gold=500,forza=80,agile=80,wit=80,thew=80};
get_reiki_up(_Level) ->
	    	[].
