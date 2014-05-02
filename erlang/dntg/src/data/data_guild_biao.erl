%%%---------------------------------------
%%% @Module  : data_guild_biao
%%% @Author  : zzm
%%% @Email   : ming_up@163.com
%%% @Created : 2011-06-10
%%% @Description:  帮派镖车配置
%%%--------------------------------------

-module(data_guild_biao).
-export([path/1,biao_config/1,reward/1]).

%% 秦国路线
path(1) ->
[{220,76,46},{220,75,47},{220,74,48},{220,73,49},{220,72,50},{220,71,51},{220,70,52},{220,69,53},{220,68,54},{220,67,55},{220,66,56},{220,65,57},{220,64,58},{220,63,59},{220,62,60},{220,61,61},{220,60,62},{220,59,63},{220,58,64},{220,57,65},{220,56,66},{220,55,67},{220,54,68},{220,53,69},{220,52,70},{220,51,71},{220,50,72},{220,49,73},{220,48,74},{220,47,75},{220,46,76},{220,45,77},{220,44,78},{220,43,79},{220,42,80},{220,41,81},{220,40,82},{220,39,83},{220,38,84},{220,37,85},{220,36,86},{220,35,87},{220,34,88},{220,33,89},{220,32,90},{220,31,91},{220,30,92},{220,29,93},{220,28,94},{220,27,95},{220,26,96},{220,25,97},{220,24,98},{220,23,99},{220,22,100},{220,21,101},{220,20,102},{220,19,103},{220,18,104},{220,17,105},{220,16,106},{220,15,107},{220,14,108},{220,13,109},{220,12,110},{220,11,111},{220,10,112},{220,9,113},{220,8,114},{220,8,115},{220,8,116},{220,8,117},{220,8,118},{220,8,119},{220,8,120},{220,8,121},{220,8,122},{220,8,123},{220,8,124},{220,8,125},{220,8,126},{220,7,127},{220,6,128},{220,5,129},{220,5,130},{220,5,131},{220,5,132},{220,5,133},{161,47,4},{161,46,5},{161,45,6},{161,44,7},{161,43,8},{161,43,9},{161,43,10},{161,43,11},{161,43,12},{161,43,13},{161,43,14},{161,43,15},{161,43,16},{161,43,17},{161,43,18},{161,43,19},{161,43,20},{161,43,21},{161,43,22},{161,43,23},{161,43,24},{161,43,25},{161,43,26},{161,43,27},{161,43,28},{161,43,29},{161,43,30},{161,43,31},{161,43,32},{161,43,33},{161,43,34},{161,43,35},{161,43,36},{161,43,37},{161,43,38},{161,43,39},{161,43,40},{161,43,41},{161,43,42},{161,43,43},{161,43,44},{161,43,45},{161,43,46},{161,43,47},{161,43,48},{161,43,49},{161,42,50},{161,41,51},{161,40,52},{161,40,53},{161,39,54},{161,39,55},{161,39,56},{161,39,57},{161,39,58},{161,39,59},{161,39,60},{161,39,61},{161,39,62},{161,39,63},{161,39,64},{161,39,65},{161,39,66},{161,39,67},{161,39,68},{161,39,69},{161,39,70},{161,38,71},{161,37,72},{161,36,73},{161,35,74},{161,35,75},{161,35,76},{161,35,77},{161,35,78},{161,35,79},{161,35,80},{161,35,81},{161,35,82},{161,35,83},{161,35,84},{161,35,85},{161,35,86},{161,35,87},{161,35,88},{161,35,89},{161,35,90},{161,35,91},{161,35,92},{161,35,93},{161,36,94},{161,36,95},{161,37,96},{161,38,97},{161,39,98},{161,40,99},{161,41,100},{161,42,101},{161,43,102},{161,44,103},{161,45,104},{161,46,105},{161,47,106},{161,48,107},{161,49,108},{161,50,109},{161,51,110},{161,52,111},{161,53,112},{161,54,113},{161,55,114},{161,56,115},{161,57,116},{161,58,117},{161,58,118},{161,58,119}, {160,59,79},{160,58,78},{160,57,77},{160,56,76},{160,55,75},{160,54,74},{160,53,73},{160,52,72},{160,51,71},{160,50,70},{160,49,69},{160,48,68},{160,47,67},{160,46,66},{160,45,65},{160,44,64},{160,43,63},{160,42,62},{160,41,61},{160,40,60},{160,39,59},{160,38,58},{160,37,57},{160,36,56},{160,35,55},{160,34,54},{160,33,53},{160,32,52},{160,31,51}];


%% 楚国路线
path(2)->
[{220,76,46},{220,75,47},{220,74,48},{220,73,49},{220,72,50},{220,71,51},{220,70,52},{220,69,53},{220,68,54},{220,67,55},{220,66,56},{220,65,57},{220,64,58},{220,63,59},{220,62,60},{220,61,61},{220,60,62},{220,59,63},{220,58,64},{220,57,65},{220,56,66},{220,55,67},{220,54,68},{220,53,69},{220,52,70},{220,51,71},{220,50,72},{220,49,73},{220,48,74},{220,47,75},{220,46,76},{220,45,77},{220,44,78},{220,43,79},{220,42,80},{220,41,81},{220,40,82},{220,39,83},{220,38,84},{220,37,85},{220,36,86},{220,35,87},{220,34,88},{220,33,89},{220,32,90},{220,31,91},{220,30,92},{220,29,93},{220,28,94},{220,27,95},{220,26,96},{220,25,97},{220,24,98},{220,23,99},{220,22,100},{220,21,101},{220,20,102},{220,19,103},{220,18,104},{220,17,105},{220,16,106},{220,15,107},{220,14,108},{220,13,109},{220,12,110},{220,11,111},{220,10,112},{220,9,113},{220,8,114},{220,8,115},{220,8,116},{220,8,117},{220,8,118},{220,8,119},{220,8,120},{220,8,121},{220,8,122},{220,8,123},{220,8,124},{220,8,125},{220,8,126},{220,7,127},{220,6,128},{220,5,129},{220,5,130},{220,5,131},{220,5,132},{220,5,133},{161,47,4},{161,46,5},{161,45,6},{161,44,7},{161,43,8},{161,43,9},{161,43,10},{161,43,11},{161,43,12},{161,43,13},{161,43,14},{161,43,15},{161,43,16},{161,43,17},{161,43,18},{161,43,19},{161,43,20},{161,43,21},{161,43,22},{161,43,23},{161,43,24},{161,43,25},{161,43,26},{161,43,27},{161,43,28},{161,43,29},{161,43,30},{161,43,31},{161,43,32},{161,43,33},{161,43,34},{161,43,35},{161,43,36},{161,43,37},{161,43,38},{161,43,39},{161,43,40},{161,43,41},{161,43,42},{161,43,43},{161,43,44},{161,43,45},{161,43,46},{161,43,47},{161,43,48},{161,43,49},{161,42,50},{161,41,51},{161,40,52},{161,40,53},{161,39,54},{161,39,55},{161,39,56},{161,39,57},{161,39,58},{161,39,59},{161,39,60},{161,39,61},{161,39,62},{161,39,63},{161,39,64},{161,39,65},{161,39,66},{161,39,67},{161,39,68},{161,39,69},{161,39,70},{161,38,71},{161,37,72},{161,36,73},{161,35,74},{161,35,75},{161,35,76},{161,35,77},{161,35,78},{161,35,79},{161,35,80},{161,35,81},{161,35,82},{161,35,83},{161,35,84},{161,35,85},{161,35,86},{161,35,87},{161,35,88},{161,35,89},{161,35,90},{161,35,91},{161,35,92},{161,35,93},{161,36,94},{161,36,95},{161,37,96},{161,38,97},{161,39,98},{161,40,99},{161,41,100},{161,42,101},{161,43,102},{161,44,103},{161,45,104},{161,46,105},{161,47,106},{161,48,107},{161,49,108},{161,50,109},{161,51,110},{161,52,111},{161,53,112},{161,54,113},{161,55,114},{161,56,115},{161,57,116},{161,58,117},{161,58,118},{161,58,119},{180,59,79},{180,58,78},{180,57,77},{180,56,76},{180,55,75},{180,54,74},{180,53,73},{180,52,72},{180,51,71},{180,50,70},{180,49,69},{180,48,68},{180,47,67},{180,46,66},{180,45,65},{180,44,64},{180,43,63},{180,42,62},{180,41,61},{180,40,60},{180,39,59},{180,38,58},{180,37,57},{180,36,56},{180,35,55},{180,34,54},{180,33,53},{180,32,52},{180,31,51}];


    
%% 汉国路线
path(3) ->
     [{220,76,46},{220,75,47},{220,74,48},{220,73,49},{220,72,50},{220,71,51},{220,70,52},{220,69,53},{220,68,54},{220,67,55},{220,66,56},{220,65,57},{220,64,58},{220,63,59},{220,62,60},{220,61,61},{220,60,62},{220,59,63},{220,58,64},{220,57,65},{220,56,66},{220,55,67},{220,54,68},{220,53,69},{220,52,70},{220,51,71},{220,50,72},{220,49,73},{220,48,74},{220,47,75},{220,46,76},{220,45,77},{220,44,78},{220,43,79},{220,42,80},{220,41,81},{220,40,82},{220,39,83},{220,38,84},{220,37,85},{220,36,86},{220,35,87},{220,34,88},{220,33,89},{220,32,90},{220,31,91},{220,30,92},{220,29,93},{220,28,94},{220,27,95},{220,26,96},{220,25,97},{220,24,98},{220,23,99},{220,22,100},{220,21,101},{220,20,102},{220,19,103},{220,18,104},{220,17,105},{220,16,106},{220,15,107},{220,14,108},{220,13,109},{220,12,110},{220,11,111},{220,10,112},{220,9,113},{220,8,114},{220,8,115},{220,8,116},{220,8,117},{220,8,118},{220,8,119},{220,8,120},{220,8,121},{220,8,122},{220,8,123},{220,8,124},{220,8,125},{220,8,126},{220,7,127},{220,6,128},{220,5,129},{220,5,130},{220,5,131},{220,5,132},{220,5,133},{161,47,4},{161,46,5},{161,45,6},{161,44,7},{161,43,8},{161,43,9},{161,43,10},{161,43,11},{161,43,12},{161,43,13},{161,43,14},{161,43,15},{161,43,16},{161,43,17},{161,43,18},{161,43,19},{161,43,20},{161,43,21},{161,43,22},{161,43,23},{161,43,24},{161,43,25},{161,43,26},{161,43,27},{161,43,28},{161,43,29},{161,43,30},{161,43,31},{161,43,32},{161,43,33},{161,43,34},{161,43,35},{161,43,36},{161,43,37},{161,43,38},{161,43,39},{161,43,40},{161,43,41},{161,43,42},{161,43,43},{161,43,44},{161,43,45},{161,43,46},{161,43,47},{161,43,48},{161,43,49},{161,42,50},{161,41,51},{161,40,52},{161,40,53},{161,39,54},{161,39,55},{161,39,56},{161,39,57},{161,39,58},{161,39,59},{161,39,60},{161,39,61},{161,39,62},{161,39,63},{161,39,64},{161,39,65},{161,39,66},{161,39,67},{161,39,68},{161,39,69},{161,39,70},{161,38,71},{161,37,72},{161,36,73},{161,35,74},{161,35,75},{161,35,76},{161,35,77},{161,35,78},{161,35,79},{161,35,80},{161,35,81},{161,35,82},{161,35,83},{161,35,84},{161,35,85},{161,35,86},{161,35,87},{161,35,88},{161,35,89},{161,35,90},{161,35,91},{161,35,92},{161,35,93},{161,36,94},{161,36,95},{161,37,96},{161,38,97},{161,39,98},{161,40,99},{161,41,100},{161,42,101},{161,43,102},{161,44,103},{161,45,104},{161,46,105},{161,47,106},{161,48,107},{161,49,108},{161,50,109},{161,51,110},{161,52,111},{161,53,112},{161,54,113},{161,55,114},{161,56,115},{161,57,116},{161,58,117},{161,58,118},{161,58,119},{200,59,79},{200,58,78},{200,57,77},{200,56,76},{200,55,75},{200,54,74},{200,53,73},{200,52,72},{200,51,71},{200,50,70},{200,49,69},{200,48,68},{200,47,67},{200,46,66},{200,45,65},{200,44,64},{200,43,63},{200,42,62},{200,41,61},{200,40,60},{200,39,59},{200,38,58},{200,37,57},{200,36,56},{200,35,55},{200,34,54},{200,33,53},{200,32,52},{200,31,51}].


%% 血量 法力 攻击 防御 命中 躲避 暴击 坚韧
biao_config(4) ->
     {720000,500,1,500,1000,350,15,500};
biao_config(5) ->
     {1080000,500,1,600,1000,404,15,500};
biao_config(6) ->
     {1440000,500,1,700,1000,460,15,500};
biao_config(7) ->
     {1680000,500,1,800,1000,514,15,500};
biao_config(8) ->
     {1680000,500,1,800,1000,514,15,500};
biao_config(9) ->
     {2340000,500,1,900,1000,514,15,500};
biao_config(10) ->
     {2340000,500,1,900,1000,514,15,500};
biao_config(_) ->
     {2340000,500,1,500,1000,350,15,500}.

%% 奖励
reward(3) -> 40000;
reward(4) -> 60000;
reward(5) -> 80000;
reward(6) -> 120000;
reward(7) -> 180000;
reward(8) -> 180000;
reward(9) -> 180000;
reward(_) -> 0.