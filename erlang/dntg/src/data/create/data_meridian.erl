%%%---------------------------------------
%%% @Module  : data_meridian
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2014-04-29 16:16:28
%%% @Description:  经脉数据自动生成
%%%---------------------------------------
-module(data_meridian).
-export([get/2]).

get(1, 1) ->
	[1, 1, 15, [], 0, 0, 10, 5, 2 ,0, 0];
get(1, 2) ->
	[1, 2, 15, [{10,1}], 0, 0, 12, 80, 4 ,0, 0];
get(1, 3) ->
	[1, 3, 15, [{10,2}], 0, 0, 16, 100, 6 ,0, 0];
get(1, 4) ->
	[1, 4, 15, [{10,3}], 0, 0, 22, 150, 8 ,0, 0];
get(1, 5) ->
	[1, 5, 15, [{10,4}], 0, 0, 30, 200, 10 ,0, 0];
get(1, 6) ->
	[1, 6, 15, [{10,5}], 0, 0, 40, 250, 12 ,0, 0];
get(1, 7) ->
	[1, 7, 15, [{10,6}], 0, 0, 52, 300, 14 ,0, 0];
get(1, 8) ->
	[1, 8, 15, [{10,7}], 0, 0, 66, 350, 16 ,0, 0];
get(1, 9) ->
	[1, 9, 15, [{10,8}], 0, 0, 82, 400, 18 ,0, 0];
get(1, 10) ->
	[1, 10, 15, [{10,9}], 0, 0, 100, 450, 20 ,0, 0];
get(1, 11) ->
	[1, 11, 38, [{10,10}], 0, 0, 120, 500, 22 ,0, 0];
get(1, 12) ->
	[1, 12, 38, [{10,11}], 0, 0, 142, 550, 24 ,0, 0];
get(1, 13) ->
	[1, 13, 38, [{10,12}], 0, 0, 166, 600, 26 ,0, 0];
get(1, 14) ->
	[1, 14, 38, [{10,13}], 0, 0, 192, 650, 28 ,0, 0];
get(1, 15) ->
	[1, 15, 38, [{10,14}], 0, 0, 220, 700, 30 ,0, 0];
get(1, 16) ->
	[1, 16, 38, [{10,15}], 0, 0, 250, 750, 32 ,0, 0];
get(1, 17) ->
	[1, 17, 38, [{10,16}], 0, 0, 282, 800, 34 ,0, 0];
get(1, 18) ->
	[1, 18, 38, [{10,17}], 0, 0, 316, 850, 36 ,0, 0];
get(1, 19) ->
	[1, 19, 38, [{10,18}], 0, 0, 352, 900, 38 ,0, 0];
get(1, 20) ->
	[1, 20, 38, [{10,19}], 0, 0, 390, 950, 40 ,0, 0];
get(1, 21) ->
	[1, 21, 48, [{10,20}], 0, 0, 1000, 1000, 44 ,0, 0];
get(1, 22) ->
	[1, 22, 48, [{10,21}], 0, 0, 1021, 1050, 48 ,0, 0];
get(1, 23) ->
	[1, 23, 48, [{10,22}], 0, 0, 1043, 1100, 52 ,0, 0];
get(1, 24) ->
	[1, 24, 48, [{10,23}], 0, 0, 1066, 1150, 56 ,0, 0];
get(1, 25) ->
	[1, 25, 48, [{10,24}], 0, 0, 1090, 1200, 60 ,0, 0];
get(1, 26) ->
	[1, 26, 54, [{10,25}], 0, 0, 1115, 1250, 64 ,0, 0];
get(1, 27) ->
	[1, 27, 54, [{10,26}], 0, 0, 1141, 1300, 68 ,0, 0];
get(1, 28) ->
	[1, 28, 54, [{10,27}], 0, 0, 1168, 1350, 72 ,0, 0];
get(1, 29) ->
	[1, 29, 54, [{10,28}], 0, 0, 1196, 1400, 76 ,0, 0];
get(1, 30) ->
	[1, 30, 54, [{10,29}], 0, 0, 1225, 1450, 80 ,0, 0];
get(1, 31) ->
	[1, 31, 59, [{10,30}], 0, 0, 1255, 1500, 84 ,0, 0];
get(1, 32) ->
	[1, 32, 59, [{10,31}], 0, 0, 1286, 1550, 88 ,0, 0];
get(1, 33) ->
	[1, 33, 59, [{10,32}], 0, 0, 1318, 1600, 92 ,0, 0];
get(1, 34) ->
	[1, 34, 59, [{10,33}], 0, 0, 1351, 1650, 96 ,0, 0];
get(1, 35) ->
	[1, 35, 59, [{10,34}], 0, 0, 1385, 1700, 100 ,0, 0];
get(1, 36) ->
	[1, 36, 64, [{10,35}], 0, 0, 1420, 1750, 104 ,0, 0];
get(1, 37) ->
	[1, 37, 64, [{10,36}], 0, 0, 1456, 1800, 108 ,0, 0];
get(1, 38) ->
	[1, 38, 64, [{10,37}], 0, 0, 1493, 1850, 112 ,0, 0];
get(1, 39) ->
	[1, 39, 64, [{10,38}], 0, 0, 1531, 1900, 116 ,0, 0];
get(1, 40) ->
	[1, 40, 64, [{10,39}], 0, 0, 1570, 1950, 120 ,0, 0];
get(1, 41) ->
	[1, 41, 69, [{10,40}], 0, 0, 1610, 2000, 124 ,0, 0];
get(1, 42) ->
	[1, 42, 69, [{10,41}], 0, 0, 1651, 2050, 128 ,0, 0];
get(1, 43) ->
	[1, 43, 69, [{10,42}], 0, 0, 1693, 2100, 132 ,0, 0];
get(1, 44) ->
	[1, 44, 69, [{10,43}], 0, 0, 1736, 2150, 136 ,0, 0];
get(1, 45) ->
	[1, 45, 69, [{10,44}], 0, 0, 1780, 2200, 140 ,0, 0];
get(1, 46) ->
	[1, 46, 73, [{10,45}], 0, 0, 1825, 2250, 144 ,0, 0];
get(1, 47) ->
	[1, 47, 73, [{10,46}], 0, 0, 1871, 2300, 148 ,0, 0];
get(1, 48) ->
	[1, 48, 73, [{10,47}], 0, 0, 1918, 2350, 152 ,0, 0];
get(1, 49) ->
	[1, 49, 73, [{10,48}], 0, 0, 1966, 2400, 156 ,0, 0];
get(1, 50) ->
	[1, 50, 73, [{10,49}], 0, 0, 2015, 2450, 160 ,0, 0];
get(1, 51) ->
	[1, 51, 78, [{10,50}], 0, 0, 2065, 2500, 164 ,0, 0];
get(1, 52) ->
	[1, 52, 78, [{10,51}], 0, 0, 2116, 2550, 168 ,0, 0];
get(1, 53) ->
	[1, 53, 78, [{10,52}], 0, 0, 2168, 2600, 172 ,0, 0];
get(1, 54) ->
	[1, 54, 78, [{10,53}], 0, 0, 2221, 2650, 176 ,0, 0];
get(1, 55) ->
	[1, 55, 78, [{10,54}], 0, 0, 2275, 2700, 180 ,0, 0];
get(1, 56) ->
	[1, 56, 82, [{10,55}], 0, 0, 2330, 2750, 184 ,0, 0];
get(1, 57) ->
	[1, 57, 82, [{10,56}], 0, 0, 2386, 2800, 188 ,0, 0];
get(1, 58) ->
	[1, 58, 82, [{10,57}], 0, 0, 2443, 2850, 192 ,0, 0];
get(1, 59) ->
	[1, 59, 82, [{10,58}], 0, 0, 2501, 2900, 196 ,0, 0];
get(1, 60) ->
	[1, 60, 82, [{10,59}], 0, 0, 2560, 2950, 200 ,0, 0];
get(2, 1) ->
	[2, 1, 0, [{1,1}], 0, 0, 10, 10, 8 ,0, 0];
get(2, 2) ->
	[2, 2, 0, [{1,2}], 0, 0, 12, 80, 16 ,0, 0];
get(2, 3) ->
	[2, 3, 0, [{1,3}], 0, 0, 16, 100, 24 ,0, 0];
get(2, 4) ->
	[2, 4, 0, [{1,4}], 0, 0, 22, 150, 32 ,0, 0];
get(2, 5) ->
	[2, 5, 0, [{1,5}], 0, 0, 30, 200, 40 ,0, 0];
get(2, 6) ->
	[2, 6, 0, [{1,6}], 0, 0, 40, 250, 48 ,0, 0];
get(2, 7) ->
	[2, 7, 0, [{1,7}], 0, 0, 52, 300, 56 ,0, 0];
get(2, 8) ->
	[2, 8, 0, [{1,8}], 0, 0, 66, 350, 64 ,0, 0];
get(2, 9) ->
	[2, 9, 0, [{1,9}], 0, 0, 82, 400, 72 ,0, 0];
get(2, 10) ->
	[2, 10, 0, [{1,10}], 0, 0, 100, 450, 80 ,0, 0];
get(2, 11) ->
	[2, 11, 0, [{1,11}], 0, 0, 120, 500, 88 ,0, 0];
get(2, 12) ->
	[2, 12, 0, [{1,12}], 0, 0, 142, 550, 96 ,0, 0];
get(2, 13) ->
	[2, 13, 0, [{1,13}], 0, 0, 166, 600, 104 ,0, 0];
get(2, 14) ->
	[2, 14, 0, [{1,14}], 0, 0, 192, 650, 112 ,0, 0];
get(2, 15) ->
	[2, 15, 0, [{1,15}], 0, 0, 220, 700, 120 ,0, 0];
get(2, 16) ->
	[2, 16, 0, [{1,16}], 0, 0, 250, 750, 128 ,0, 0];
get(2, 17) ->
	[2, 17, 0, [{1,17}], 0, 0, 282, 800, 136 ,0, 0];
get(2, 18) ->
	[2, 18, 0, [{1,18}], 0, 0, 316, 850, 144 ,0, 0];
get(2, 19) ->
	[2, 19, 0, [{1,19}], 0, 0, 352, 900, 152 ,0, 0];
get(2, 20) ->
	[2, 20, 0, [{1,20}], 0, 0, 390, 950, 160 ,0, 0];
get(2, 21) ->
	[2, 21, 0, [{1,21}], 0, 0, 1000, 1000, 176 ,0, 0];
get(2, 22) ->
	[2, 22, 0, [{1,22}], 0, 0, 1021, 1050, 192 ,0, 0];
get(2, 23) ->
	[2, 23, 0, [{1,23}], 0, 0, 1043, 1100, 208 ,0, 0];
get(2, 24) ->
	[2, 24, 0, [{1,24}], 0, 0, 1066, 1150, 224 ,0, 0];
get(2, 25) ->
	[2, 25, 0, [{1,25}], 0, 0, 1090, 1200, 240 ,0, 0];
get(2, 26) ->
	[2, 26, 0, [{1,26}], 0, 0, 1115, 1250, 256 ,0, 0];
get(2, 27) ->
	[2, 27, 0, [{1,27}], 0, 0, 1141, 1300, 272 ,0, 0];
get(2, 28) ->
	[2, 28, 0, [{1,28}], 0, 0, 1168, 1350, 288 ,0, 0];
get(2, 29) ->
	[2, 29, 0, [{1,29}], 0, 0, 1196, 1400, 304 ,0, 0];
get(2, 30) ->
	[2, 30, 0, [{1,30}], 0, 0, 1225, 1450, 320 ,0, 0];
get(2, 31) ->
	[2, 31, 0, [{1,31}], 0, 0, 1255, 1500, 336 ,0, 0];
get(2, 32) ->
	[2, 32, 0, [{1,32}], 0, 0, 1286, 1550, 352 ,0, 0];
get(2, 33) ->
	[2, 33, 0, [{1,33}], 0, 0, 1318, 1600, 368 ,0, 0];
get(2, 34) ->
	[2, 34, 0, [{1,34}], 0, 0, 1351, 1650, 384 ,0, 0];
get(2, 35) ->
	[2, 35, 0, [{1,35}], 0, 0, 1385, 1700, 400 ,0, 0];
get(2, 36) ->
	[2, 36, 0, [{1,36}], 0, 0, 1420, 1750, 416 ,0, 0];
get(2, 37) ->
	[2, 37, 0, [{1,37}], 0, 0, 1456, 1800, 432 ,0, 0];
get(2, 38) ->
	[2, 38, 0, [{1,38}], 0, 0, 1493, 1850, 448 ,0, 0];
get(2, 39) ->
	[2, 39, 0, [{1,39}], 0, 0, 1531, 1900, 464 ,0, 0];
get(2, 40) ->
	[2, 40, 0, [{1,40}], 0, 0, 1570, 1950, 480 ,0, 0];
get(2, 41) ->
	[2, 41, 0, [{1,41}], 0, 0, 1610, 2000, 496 ,0, 0];
get(2, 42) ->
	[2, 42, 0, [{1,42}], 0, 0, 1651, 2050, 512 ,0, 0];
get(2, 43) ->
	[2, 43, 0, [{1,43}], 0, 0, 1693, 2100, 528 ,0, 0];
get(2, 44) ->
	[2, 44, 0, [{1,44}], 0, 0, 1736, 2150, 544 ,0, 0];
get(2, 45) ->
	[2, 45, 0, [{1,45}], 0, 0, 1780, 2200, 560 ,0, 0];
get(2, 46) ->
	[2, 46, 0, [{1,46}], 0, 0, 1825, 2250, 576 ,0, 0];
get(2, 47) ->
	[2, 47, 0, [{1,47}], 0, 0, 1871, 2300, 592 ,0, 0];
get(2, 48) ->
	[2, 48, 0, [{1,48}], 0, 0, 1918, 2350, 608 ,0, 0];
get(2, 49) ->
	[2, 49, 0, [{1,49}], 0, 0, 1966, 2400, 624 ,0, 0];
get(2, 50) ->
	[2, 50, 0, [{1,50}], 0, 0, 2015, 2450, 640 ,0, 0];
get(2, 51) ->
	[2, 51, 0, [{1,51}], 0, 0, 2065, 2500, 656 ,0, 0];
get(2, 52) ->
	[2, 52, 0, [{1,52}], 0, 0, 2116, 2550, 672 ,0, 0];
get(2, 53) ->
	[2, 53, 0, [{1,53}], 0, 0, 2168, 2600, 688 ,0, 0];
get(2, 54) ->
	[2, 54, 0, [{1,54}], 0, 0, 2221, 2650, 704 ,0, 0];
get(2, 55) ->
	[2, 55, 0, [{1,55}], 0, 0, 2275, 2700, 720 ,0, 0];
get(2, 56) ->
	[2, 56, 0, [{1,56}], 0, 0, 2330, 2750, 736 ,0, 0];
get(2, 57) ->
	[2, 57, 0, [{1,57}], 0, 0, 2386, 2800, 752 ,0, 0];
get(2, 58) ->
	[2, 58, 0, [{1,58}], 0, 0, 2443, 2850, 768 ,0, 0];
get(2, 59) ->
	[2, 59, 0, [{1,59}], 0, 0, 2501, 2900, 784 ,0, 0];
get(2, 60) ->
	[2, 60, 0, [{1,60}], 0, 0, 2560, 2950, 800 ,0, 0];
get(3, 1) ->
	[3, 1, 0, [{2,1}], 0, 0, 10, 15, 5 ,0, 0];
get(3, 2) ->
	[3, 2, 0, [{2,2}], 0, 0, 12, 80, 10 ,0, 0];
get(3, 3) ->
	[3, 3, 0, [{2,3}], 0, 0, 16, 100, 15 ,0, 0];
get(3, 4) ->
	[3, 4, 0, [{2,4}], 0, 0, 22, 150, 20 ,0, 0];
get(3, 5) ->
	[3, 5, 0, [{2,5}], 0, 0, 30, 200, 25 ,0, 0];
get(3, 6) ->
	[3, 6, 0, [{2,6}], 0, 0, 40, 250, 30 ,0, 0];
get(3, 7) ->
	[3, 7, 0, [{2,7}], 0, 0, 52, 300, 35 ,0, 0];
get(3, 8) ->
	[3, 8, 0, [{2,8}], 0, 0, 66, 350, 40 ,0, 0];
get(3, 9) ->
	[3, 9, 0, [{2,9}], 0, 0, 82, 400, 45 ,0, 0];
get(3, 10) ->
	[3, 10, 0, [{2,10}], 0, 0, 100, 450, 50 ,0, 0];
get(3, 11) ->
	[3, 11, 0, [{2,11}], 0, 0, 120, 500, 55 ,0, 0];
get(3, 12) ->
	[3, 12, 0, [{2,12}], 0, 0, 142, 550, 60 ,0, 0];
get(3, 13) ->
	[3, 13, 0, [{2,13}], 0, 0, 166, 600, 65 ,0, 0];
get(3, 14) ->
	[3, 14, 0, [{2,14}], 0, 0, 192, 650, 70 ,0, 0];
get(3, 15) ->
	[3, 15, 0, [{2,15}], 0, 0, 220, 700, 75 ,0, 0];
get(3, 16) ->
	[3, 16, 0, [{2,16}], 0, 0, 250, 750, 80 ,0, 0];
get(3, 17) ->
	[3, 17, 0, [{2,17}], 0, 0, 282, 800, 85 ,0, 0];
get(3, 18) ->
	[3, 18, 0, [{2,18}], 0, 0, 316, 850, 90 ,0, 0];
get(3, 19) ->
	[3, 19, 0, [{2,19}], 0, 0, 352, 900, 95 ,0, 0];
get(3, 20) ->
	[3, 20, 0, [{2,20}], 0, 0, 390, 950, 100 ,0, 0];
get(3, 21) ->
	[3, 21, 0, [{2,21}], 0, 0, 1000, 1000, 110 ,0, 0];
get(3, 22) ->
	[3, 22, 0, [{2,22}], 0, 0, 1021, 1050, 120 ,0, 0];
get(3, 23) ->
	[3, 23, 0, [{2,23}], 0, 0, 1043, 1100, 130 ,0, 0];
get(3, 24) ->
	[3, 24, 0, [{2,24}], 0, 0, 1066, 1150, 140 ,0, 0];
get(3, 25) ->
	[3, 25, 0, [{2,25}], 0, 0, 1090, 1200, 150 ,0, 0];
get(3, 26) ->
	[3, 26, 0, [{2,26}], 0, 0, 1115, 1250, 160 ,0, 0];
get(3, 27) ->
	[3, 27, 0, [{2,27}], 0, 0, 1141, 1300, 170 ,0, 0];
get(3, 28) ->
	[3, 28, 0, [{2,28}], 0, 0, 1168, 1350, 180 ,0, 0];
get(3, 29) ->
	[3, 29, 0, [{2,29}], 0, 0, 1196, 1400, 190 ,0, 0];
get(3, 30) ->
	[3, 30, 0, [{2,30}], 0, 0, 1225, 1450, 200 ,0, 0];
get(3, 31) ->
	[3, 31, 0, [{2,31}], 0, 0, 1255, 1500, 210 ,0, 0];
get(3, 32) ->
	[3, 32, 0, [{2,32}], 0, 0, 1286, 1550, 220 ,0, 0];
get(3, 33) ->
	[3, 33, 0, [{2,33}], 0, 0, 1318, 1600, 230 ,0, 0];
get(3, 34) ->
	[3, 34, 0, [{2,34}], 0, 0, 1351, 1650, 240 ,0, 0];
get(3, 35) ->
	[3, 35, 0, [{2,35}], 0, 0, 1385, 1700, 250 ,0, 0];
get(3, 36) ->
	[3, 36, 0, [{2,36}], 0, 0, 1420, 1750, 260 ,0, 0];
get(3, 37) ->
	[3, 37, 0, [{2,37}], 0, 0, 1456, 1800, 270 ,0, 0];
get(3, 38) ->
	[3, 38, 0, [{2,38}], 0, 0, 1493, 1850, 280 ,0, 0];
get(3, 39) ->
	[3, 39, 0, [{2,39}], 0, 0, 1531, 1900, 290 ,0, 0];
get(3, 40) ->
	[3, 40, 0, [{2,40}], 0, 0, 1570, 1950, 300 ,0, 0];
get(3, 41) ->
	[3, 41, 0, [{2,41}], 0, 0, 1610, 2000, 310 ,0, 0];
get(3, 42) ->
	[3, 42, 0, [{2,42}], 0, 0, 1651, 2050, 320 ,0, 0];
get(3, 43) ->
	[3, 43, 0, [{2,43}], 0, 0, 1693, 2100, 330 ,0, 0];
get(3, 44) ->
	[3, 44, 0, [{2,44}], 0, 0, 1736, 2150, 340 ,0, 0];
get(3, 45) ->
	[3, 45, 0, [{2,45}], 0, 0, 1780, 2200, 350 ,0, 0];
get(3, 46) ->
	[3, 46, 0, [{2,46}], 0, 0, 1825, 2250, 360 ,0, 0];
get(3, 47) ->
	[3, 47, 0, [{2,47}], 0, 0, 1871, 2300, 370 ,0, 0];
get(3, 48) ->
	[3, 48, 0, [{2,48}], 0, 0, 1918, 2350, 380 ,0, 0];
get(3, 49) ->
	[3, 49, 0, [{2,49}], 0, 0, 1966, 2400, 390 ,0, 0];
get(3, 50) ->
	[3, 50, 0, [{2,50}], 0, 0, 2015, 2450, 400 ,0, 0];
get(3, 51) ->
	[3, 51, 0, [{2,51}], 0, 0, 2065, 2500, 410 ,0, 0];
get(3, 52) ->
	[3, 52, 0, [{2,52}], 0, 0, 2116, 2550, 420 ,0, 0];
get(3, 53) ->
	[3, 53, 0, [{2,53}], 0, 0, 2168, 2600, 430 ,0, 0];
get(3, 54) ->
	[3, 54, 0, [{2,54}], 0, 0, 2221, 2650, 440 ,0, 0];
get(3, 55) ->
	[3, 55, 0, [{2,55}], 0, 0, 2275, 2700, 450 ,0, 0];
get(3, 56) ->
	[3, 56, 0, [{2,56}], 0, 0, 2330, 2750, 460 ,0, 0];
get(3, 57) ->
	[3, 57, 0, [{2,57}], 0, 0, 2386, 2800, 470 ,0, 0];
get(3, 58) ->
	[3, 58, 0, [{2,58}], 0, 0, 2443, 2850, 480 ,0, 0];
get(3, 59) ->
	[3, 59, 0, [{2,59}], 0, 0, 2501, 2900, 490 ,0, 0];
get(3, 60) ->
	[3, 60, 0, [{2,60}], 0, 0, 2560, 2950, 500 ,0, 0];
get(4, 1) ->
	[4, 1, 0, [{3,1}], 0, 0, 10, 20, 4 ,0, 0];
get(4, 2) ->
	[4, 2, 0, [{3,2}], 0, 0, 12, 80, 8 ,0, 0];
get(4, 3) ->
	[4, 3, 0, [{3,3}], 0, 0, 16, 100, 12 ,0, 0];
get(4, 4) ->
	[4, 4, 0, [{3,4}], 0, 0, 22, 150, 16 ,0, 0];
get(4, 5) ->
	[4, 5, 0, [{3,5}], 0, 0, 30, 200, 20 ,0, 0];
get(4, 6) ->
	[4, 6, 0, [{3,6}], 0, 0, 40, 250, 24 ,0, 0];
get(4, 7) ->
	[4, 7, 0, [{3,7}], 0, 0, 52, 300, 28 ,0, 0];
get(4, 8) ->
	[4, 8, 0, [{3,8}], 0, 0, 66, 350, 32 ,0, 0];
get(4, 9) ->
	[4, 9, 0, [{3,9}], 0, 0, 82, 400, 36 ,0, 0];
get(4, 10) ->
	[4, 10, 0, [{3,10}], 0, 0, 100, 450, 40 ,0, 0];
get(4, 11) ->
	[4, 11, 0, [{3,11}], 0, 0, 120, 500, 44 ,0, 0];
get(4, 12) ->
	[4, 12, 0, [{3,12}], 0, 0, 142, 550, 48 ,0, 0];
get(4, 13) ->
	[4, 13, 0, [{3,13}], 0, 0, 166, 600, 52 ,0, 0];
get(4, 14) ->
	[4, 14, 0, [{3,14}], 0, 0, 192, 650, 56 ,0, 0];
get(4, 15) ->
	[4, 15, 0, [{3,15}], 0, 0, 220, 700, 60 ,0, 0];
get(4, 16) ->
	[4, 16, 0, [{3,16}], 0, 0, 250, 750, 64 ,0, 0];
get(4, 17) ->
	[4, 17, 0, [{3,17}], 0, 0, 282, 800, 68 ,0, 0];
get(4, 18) ->
	[4, 18, 0, [{3,18}], 0, 0, 316, 850, 72 ,0, 0];
get(4, 19) ->
	[4, 19, 0, [{3,19}], 0, 0, 352, 900, 76 ,0, 0];
get(4, 20) ->
	[4, 20, 0, [{3,20}], 0, 0, 390, 950, 80 ,0, 0];
get(4, 21) ->
	[4, 21, 0, [{3,21}], 0, 0, 1000, 1000, 88 ,0, 0];
get(4, 22) ->
	[4, 22, 0, [{3,22}], 0, 0, 1021, 1050, 96 ,0, 0];
get(4, 23) ->
	[4, 23, 0, [{3,23}], 0, 0, 1043, 1100, 104 ,0, 0];
get(4, 24) ->
	[4, 24, 0, [{3,24}], 0, 0, 1066, 1150, 112 ,0, 0];
get(4, 25) ->
	[4, 25, 0, [{3,25}], 0, 0, 1090, 1200, 120 ,0, 0];
get(4, 26) ->
	[4, 26, 0, [{3,26}], 0, 0, 1115, 1250, 128 ,0, 0];
get(4, 27) ->
	[4, 27, 0, [{3,27}], 0, 0, 1141, 1300, 136 ,0, 0];
get(4, 28) ->
	[4, 28, 0, [{3,28}], 0, 0, 1168, 1350, 144 ,0, 0];
get(4, 29) ->
	[4, 29, 0, [{3,29}], 0, 0, 1196, 1400, 152 ,0, 0];
get(4, 30) ->
	[4, 30, 0, [{3,30}], 0, 0, 1225, 1450, 160 ,0, 0];
get(4, 31) ->
	[4, 31, 0, [{3,31}], 0, 0, 1255, 1500, 168 ,0, 0];
get(4, 32) ->
	[4, 32, 0, [{3,32}], 0, 0, 1286, 1550, 176 ,0, 0];
get(4, 33) ->
	[4, 33, 0, [{3,33}], 0, 0, 1318, 1600, 184 ,0, 0];
get(4, 34) ->
	[4, 34, 0, [{3,34}], 0, 0, 1351, 1650, 192 ,0, 0];
get(4, 35) ->
	[4, 35, 0, [{3,35}], 0, 0, 1385, 1700, 200 ,0, 0];
get(4, 36) ->
	[4, 36, 0, [{3,36}], 0, 0, 1420, 1750, 208 ,0, 0];
get(4, 37) ->
	[4, 37, 0, [{3,37}], 0, 0, 1456, 1800, 216 ,0, 0];
get(4, 38) ->
	[4, 38, 0, [{3,38}], 0, 0, 1493, 1850, 224 ,0, 0];
get(4, 39) ->
	[4, 39, 0, [{3,39}], 0, 0, 1531, 1900, 232 ,0, 0];
get(4, 40) ->
	[4, 40, 0, [{3,40}], 0, 0, 1570, 1950, 240 ,0, 0];
get(4, 41) ->
	[4, 41, 0, [{3,41}], 0, 0, 1610, 2000, 248 ,0, 0];
get(4, 42) ->
	[4, 42, 0, [{3,42}], 0, 0, 1651, 2050, 256 ,0, 0];
get(4, 43) ->
	[4, 43, 0, [{3,43}], 0, 0, 1693, 2100, 264 ,0, 0];
get(4, 44) ->
	[4, 44, 0, [{3,44}], 0, 0, 1736, 2150, 272 ,0, 0];
get(4, 45) ->
	[4, 45, 0, [{3,45}], 0, 0, 1780, 2200, 280 ,0, 0];
get(4, 46) ->
	[4, 46, 0, [{3,46}], 0, 0, 1825, 2250, 288 ,0, 0];
get(4, 47) ->
	[4, 47, 0, [{3,47}], 0, 0, 1871, 2300, 296 ,0, 0];
get(4, 48) ->
	[4, 48, 0, [{3,48}], 0, 0, 1918, 2350, 304 ,0, 0];
get(4, 49) ->
	[4, 49, 0, [{3,49}], 0, 0, 1966, 2400, 312 ,0, 0];
get(4, 50) ->
	[4, 50, 0, [{3,50}], 0, 0, 2015, 2450, 320 ,0, 0];
get(4, 51) ->
	[4, 51, 0, [{3,51}], 0, 0, 2065, 2500, 328 ,0, 0];
get(4, 52) ->
	[4, 52, 0, [{3,52}], 0, 0, 2116, 2550, 336 ,0, 0];
get(4, 53) ->
	[4, 53, 0, [{3,53}], 0, 0, 2168, 2600, 344 ,0, 0];
get(4, 54) ->
	[4, 54, 0, [{3,54}], 0, 0, 2221, 2650, 352 ,0, 0];
get(4, 55) ->
	[4, 55, 0, [{3,55}], 0, 0, 2275, 2700, 360 ,0, 0];
get(4, 56) ->
	[4, 56, 0, [{3,56}], 0, 0, 2330, 2750, 368 ,0, 0];
get(4, 57) ->
	[4, 57, 0, [{3,57}], 0, 0, 2386, 2800, 376 ,0, 0];
get(4, 58) ->
	[4, 58, 0, [{3,58}], 0, 0, 2443, 2850, 384 ,0, 0];
get(4, 59) ->
	[4, 59, 0, [{3,59}], 0, 0, 2501, 2900, 392 ,0, 0];
get(4, 60) ->
	[4, 60, 0, [{3,60}], 0, 0, 2560, 2950, 400 ,0, 0];
get(5, 1) ->
	[5, 1, 0, [{4,1}], 0, 0, 10, 25, 4 ,0, 0];
get(5, 2) ->
	[5, 2, 0, [{4,2}], 0, 0, 12, 80, 8 ,0, 0];
get(5, 3) ->
	[5, 3, 0, [{4,3}], 0, 0, 16, 100, 12 ,0, 0];
get(5, 4) ->
	[5, 4, 0, [{4,4}], 0, 0, 22, 150, 16 ,0, 0];
get(5, 5) ->
	[5, 5, 0, [{4,5}], 0, 0, 30, 200, 20 ,0, 0];
get(5, 6) ->
	[5, 6, 0, [{4,6}], 0, 0, 40, 250, 24 ,0, 0];
get(5, 7) ->
	[5, 7, 0, [{4,7}], 0, 0, 52, 300, 28 ,0, 0];
get(5, 8) ->
	[5, 8, 0, [{4,8}], 0, 0, 66, 350, 32 ,0, 0];
get(5, 9) ->
	[5, 9, 0, [{4,9}], 0, 0, 82, 400, 36 ,0, 0];
get(5, 10) ->
	[5, 10, 0, [{4,10}], 0, 0, 100, 450, 40 ,0, 0];
get(5, 11) ->
	[5, 11, 0, [{4,11}], 0, 0, 120, 500, 44 ,0, 0];
get(5, 12) ->
	[5, 12, 0, [{4,12}], 0, 0, 142, 550, 48 ,0, 0];
get(5, 13) ->
	[5, 13, 0, [{4,13}], 0, 0, 166, 600, 52 ,0, 0];
get(5, 14) ->
	[5, 14, 0, [{4,14}], 0, 0, 192, 650, 56 ,0, 0];
get(5, 15) ->
	[5, 15, 0, [{4,15}], 0, 0, 220, 700, 60 ,0, 0];
get(5, 16) ->
	[5, 16, 0, [{4,16}], 0, 0, 250, 750, 64 ,0, 0];
get(5, 17) ->
	[5, 17, 0, [{4,17}], 0, 0, 282, 800, 68 ,0, 0];
get(5, 18) ->
	[5, 18, 0, [{4,18}], 0, 0, 316, 850, 72 ,0, 0];
get(5, 19) ->
	[5, 19, 0, [{4,19}], 0, 0, 352, 900, 76 ,0, 0];
get(5, 20) ->
	[5, 20, 0, [{4,20}], 0, 0, 390, 950, 80 ,0, 0];
get(5, 21) ->
	[5, 21, 0, [{4,21}], 0, 0, 1000, 1000, 88 ,0, 0];
get(5, 22) ->
	[5, 22, 0, [{4,22}], 0, 0, 1021, 1050, 96 ,0, 0];
get(5, 23) ->
	[5, 23, 0, [{4,23}], 0, 0, 1043, 1100, 104 ,0, 0];
get(5, 24) ->
	[5, 24, 0, [{4,24}], 0, 0, 1066, 1150, 112 ,0, 0];
get(5, 25) ->
	[5, 25, 0, [{4,25}], 0, 0, 1090, 1200, 120 ,0, 0];
get(5, 26) ->
	[5, 26, 0, [{4,26}], 0, 0, 1115, 1250, 128 ,0, 0];
get(5, 27) ->
	[5, 27, 0, [{4,27}], 0, 0, 1141, 1300, 136 ,0, 0];
get(5, 28) ->
	[5, 28, 0, [{4,28}], 0, 0, 1168, 1350, 144 ,0, 0];
get(5, 29) ->
	[5, 29, 0, [{4,29}], 0, 0, 1196, 1400, 152 ,0, 0];
get(5, 30) ->
	[5, 30, 0, [{4,30}], 0, 0, 1225, 1450, 160 ,0, 0];
get(5, 31) ->
	[5, 31, 0, [{4,31}], 0, 0, 1255, 1500, 168 ,0, 0];
get(5, 32) ->
	[5, 32, 0, [{4,32}], 0, 0, 1286, 1550, 176 ,0, 0];
get(5, 33) ->
	[5, 33, 0, [{4,33}], 0, 0, 1318, 1600, 184 ,0, 0];
get(5, 34) ->
	[5, 34, 0, [{4,34}], 0, 0, 1351, 1650, 192 ,0, 0];
get(5, 35) ->
	[5, 35, 0, [{4,35}], 0, 0, 1385, 1700, 200 ,0, 0];
get(5, 36) ->
	[5, 36, 0, [{4,36}], 0, 0, 1420, 1750, 208 ,0, 0];
get(5, 37) ->
	[5, 37, 0, [{4,37}], 0, 0, 1456, 1800, 216 ,0, 0];
get(5, 38) ->
	[5, 38, 0, [{4,38}], 0, 0, 1493, 1850, 224 ,0, 0];
get(5, 39) ->
	[5, 39, 0, [{4,39}], 0, 0, 1531, 1900, 232 ,0, 0];
get(5, 40) ->
	[5, 40, 0, [{4,40}], 0, 0, 1570, 1950, 240 ,0, 0];
get(5, 41) ->
	[5, 41, 0, [{4,41}], 0, 0, 1610, 2000, 248 ,0, 0];
get(5, 42) ->
	[5, 42, 0, [{4,42}], 0, 0, 1651, 2050, 256 ,0, 0];
get(5, 43) ->
	[5, 43, 0, [{4,43}], 0, 0, 1693, 2100, 264 ,0, 0];
get(5, 44) ->
	[5, 44, 0, [{4,44}], 0, 0, 1736, 2150, 272 ,0, 0];
get(5, 45) ->
	[5, 45, 0, [{4,45}], 0, 0, 1780, 2200, 280 ,0, 0];
get(5, 46) ->
	[5, 46, 0, [{4,46}], 0, 0, 1825, 2250, 288 ,0, 0];
get(5, 47) ->
	[5, 47, 0, [{4,47}], 0, 0, 1871, 2300, 296 ,0, 0];
get(5, 48) ->
	[5, 48, 0, [{4,48}], 0, 0, 1918, 2350, 304 ,0, 0];
get(5, 49) ->
	[5, 49, 0, [{4,49}], 0, 0, 1966, 2400, 312 ,0, 0];
get(5, 50) ->
	[5, 50, 0, [{4,50}], 0, 0, 2015, 2450, 320 ,0, 0];
get(5, 51) ->
	[5, 51, 0, [{4,51}], 0, 0, 2065, 2500, 328 ,0, 0];
get(5, 52) ->
	[5, 52, 0, [{4,52}], 0, 0, 2116, 2550, 336 ,0, 0];
get(5, 53) ->
	[5, 53, 0, [{4,53}], 0, 0, 2168, 2600, 344 ,0, 0];
get(5, 54) ->
	[5, 54, 0, [{4,54}], 0, 0, 2221, 2650, 352 ,0, 0];
get(5, 55) ->
	[5, 55, 0, [{4,55}], 0, 0, 2275, 2700, 360 ,0, 0];
get(5, 56) ->
	[5, 56, 0, [{4,56}], 0, 0, 2330, 2750, 368 ,0, 0];
get(5, 57) ->
	[5, 57, 0, [{4,57}], 0, 0, 2386, 2800, 376 ,0, 0];
get(5, 58) ->
	[5, 58, 0, [{4,58}], 0, 0, 2443, 2850, 384 ,0, 0];
get(5, 59) ->
	[5, 59, 0, [{4,59}], 0, 0, 2501, 2900, 392 ,0, 0];
get(5, 60) ->
	[5, 60, 0, [{4,60}], 0, 0, 2560, 2950, 400 ,0, 0];
get(6, 1) ->
	[6, 1, 0, [{5,1}], 0, 0, 10, 30, 80 ,0, 0];
get(6, 2) ->
	[6, 2, 0, [{5,2}], 0, 0, 12, 80, 160 ,0, 0];
get(6, 3) ->
	[6, 3, 0, [{5,3}], 0, 0, 16, 100, 240 ,0, 0];
get(6, 4) ->
	[6, 4, 0, [{5,4}], 0, 0, 22, 150, 320 ,0, 0];
get(6, 5) ->
	[6, 5, 0, [{5,5}], 0, 0, 30, 200, 400 ,0, 0];
get(6, 6) ->
	[6, 6, 0, [{5,6}], 0, 0, 40, 250, 480 ,0, 0];
get(6, 7) ->
	[6, 7, 0, [{5,7}], 0, 0, 52, 300, 560 ,0, 0];
get(6, 8) ->
	[6, 8, 0, [{5,8}], 0, 0, 66, 350, 640 ,0, 0];
get(6, 9) ->
	[6, 9, 0, [{5,9}], 0, 0, 82, 400, 720 ,0, 0];
get(6, 10) ->
	[6, 10, 0, [{5,10}], 0, 0, 100, 450, 800 ,0, 0];
get(6, 11) ->
	[6, 11, 0, [{5,11}], 0, 0, 120, 500, 880 ,0, 0];
get(6, 12) ->
	[6, 12, 0, [{5,12}], 0, 0, 142, 550, 960 ,0, 0];
get(6, 13) ->
	[6, 13, 0, [{5,13}], 0, 0, 166, 600, 1040 ,0, 0];
get(6, 14) ->
	[6, 14, 0, [{5,14}], 0, 0, 192, 650, 1120 ,0, 0];
get(6, 15) ->
	[6, 15, 0, [{5,15}], 0, 0, 220, 700, 1200 ,0, 0];
get(6, 16) ->
	[6, 16, 0, [{5,16}], 0, 0, 250, 750, 1280 ,0, 0];
get(6, 17) ->
	[6, 17, 0, [{5,17}], 0, 0, 282, 800, 1360 ,0, 0];
get(6, 18) ->
	[6, 18, 0, [{5,18}], 0, 0, 316, 850, 1440 ,0, 0];
get(6, 19) ->
	[6, 19, 0, [{5,19}], 0, 0, 352, 900, 1520 ,0, 0];
get(6, 20) ->
	[6, 20, 0, [{5,20}], 0, 0, 390, 950, 1600 ,0, 0];
get(6, 21) ->
	[6, 21, 0, [{5,21}], 0, 0, 1000, 1000, 1760 ,0, 0];
get(6, 22) ->
	[6, 22, 0, [{5,22}], 0, 0, 1021, 1050, 1920 ,0, 0];
get(6, 23) ->
	[6, 23, 0, [{5,23}], 0, 0, 1043, 1100, 2080 ,0, 0];
get(6, 24) ->
	[6, 24, 0, [{5,24}], 0, 0, 1066, 1150, 2240 ,0, 0];
get(6, 25) ->
	[6, 25, 0, [{5,25}], 0, 0, 1090, 1200, 2400 ,0, 0];
get(6, 26) ->
	[6, 26, 0, [{5,26}], 0, 0, 1115, 1250, 2560 ,0, 0];
get(6, 27) ->
	[6, 27, 0, [{5,27}], 0, 0, 1141, 1300, 2720 ,0, 0];
get(6, 28) ->
	[6, 28, 0, [{5,28}], 0, 0, 1168, 1350, 2880 ,0, 0];
get(6, 29) ->
	[6, 29, 0, [{5,29}], 0, 0, 1196, 1400, 3040 ,0, 0];
get(6, 30) ->
	[6, 30, 0, [{5,30}], 0, 0, 1225, 1450, 3200 ,0, 0];
get(6, 31) ->
	[6, 31, 0, [{5,31}], 0, 0, 1255, 1500, 3360 ,0, 0];
get(6, 32) ->
	[6, 32, 0, [{5,32}], 0, 0, 1286, 1550, 3520 ,0, 0];
get(6, 33) ->
	[6, 33, 0, [{5,33}], 0, 0, 1318, 1600, 3680 ,0, 0];
get(6, 34) ->
	[6, 34, 0, [{5,34}], 0, 0, 1351, 1650, 3840 ,0, 0];
get(6, 35) ->
	[6, 35, 0, [{5,35}], 0, 0, 1385, 1700, 4000 ,0, 0];
get(6, 36) ->
	[6, 36, 0, [{5,36}], 0, 0, 1420, 1750, 4160 ,0, 0];
get(6, 37) ->
	[6, 37, 0, [{5,37}], 0, 0, 1456, 1800, 4320 ,0, 0];
get(6, 38) ->
	[6, 38, 0, [{5,38}], 0, 0, 1493, 1850, 4480 ,0, 0];
get(6, 39) ->
	[6, 39, 0, [{5,39}], 0, 0, 1531, 1900, 4640 ,0, 0];
get(6, 40) ->
	[6, 40, 0, [{5,40}], 0, 0, 1570, 1950, 4800 ,0, 0];
get(6, 41) ->
	[6, 41, 0, [{5,41}], 0, 0, 1610, 2000, 4960 ,0, 0];
get(6, 42) ->
	[6, 42, 0, [{5,42}], 0, 0, 1651, 2050, 5120 ,0, 0];
get(6, 43) ->
	[6, 43, 0, [{5,43}], 0, 0, 1693, 2100, 5280 ,0, 0];
get(6, 44) ->
	[6, 44, 0, [{5,44}], 0, 0, 1736, 2150, 5440 ,0, 0];
get(6, 45) ->
	[6, 45, 0, [{5,45}], 0, 0, 1780, 2200, 5600 ,0, 0];
get(6, 46) ->
	[6, 46, 0, [{5,46}], 0, 0, 1825, 2250, 5760 ,0, 0];
get(6, 47) ->
	[6, 47, 0, [{5,47}], 0, 0, 1871, 2300, 5920 ,0, 0];
get(6, 48) ->
	[6, 48, 0, [{5,48}], 0, 0, 1918, 2350, 6080 ,0, 0];
get(6, 49) ->
	[6, 49, 0, [{5,49}], 0, 0, 1966, 2400, 6240 ,0, 0];
get(6, 50) ->
	[6, 50, 0, [{5,50}], 0, 0, 2015, 2450, 6400 ,0, 0];
get(6, 51) ->
	[6, 51, 0, [{5,51}], 0, 0, 2065, 2500, 6560 ,0, 0];
get(6, 52) ->
	[6, 52, 0, [{5,52}], 0, 0, 2116, 2550, 6720 ,0, 0];
get(6, 53) ->
	[6, 53, 0, [{5,53}], 0, 0, 2168, 2600, 6880 ,0, 0];
get(6, 54) ->
	[6, 54, 0, [{5,54}], 0, 0, 2221, 2650, 7040 ,0, 0];
get(6, 55) ->
	[6, 55, 0, [{5,55}], 0, 0, 2275, 2700, 7200 ,0, 0];
get(6, 56) ->
	[6, 56, 0, [{5,56}], 0, 0, 2330, 2750, 7360 ,0, 0];
get(6, 57) ->
	[6, 57, 0, [{5,57}], 0, 0, 2386, 2800, 7520 ,0, 0];
get(6, 58) ->
	[6, 58, 0, [{5,58}], 0, 0, 2443, 2850, 7680 ,0, 0];
get(6, 59) ->
	[6, 59, 0, [{5,59}], 0, 0, 2501, 2900, 7840 ,0, 0];
get(6, 60) ->
	[6, 60, 0, [{5,60}], 0, 0, 2560, 2950, 8000 ,0, 0];
get(7, 1) ->
	[7, 1, 0, [{6,1}], 0, 0, 10, 35, 4 ,0, 0];
get(7, 2) ->
	[7, 2, 0, [{6,2}], 0, 0, 12, 80, 8 ,0, 0];
get(7, 3) ->
	[7, 3, 0, [{6,3}], 0, 0, 16, 100, 12 ,0, 0];
get(7, 4) ->
	[7, 4, 0, [{6,4}], 0, 0, 22, 150, 16 ,0, 0];
get(7, 5) ->
	[7, 5, 0, [{6,5}], 0, 0, 30, 200, 20 ,0, 0];
get(7, 6) ->
	[7, 6, 0, [{6,6}], 0, 0, 40, 250, 24 ,0, 0];
get(7, 7) ->
	[7, 7, 0, [{6,7}], 0, 0, 52, 300, 28 ,0, 0];
get(7, 8) ->
	[7, 8, 0, [{6,8}], 0, 0, 66, 350, 32 ,0, 0];
get(7, 9) ->
	[7, 9, 0, [{6,9}], 0, 0, 82, 400, 36 ,0, 0];
get(7, 10) ->
	[7, 10, 0, [{6,10}], 0, 0, 100, 450, 40 ,0, 0];
get(7, 11) ->
	[7, 11, 0, [{6,11}], 0, 0, 120, 500, 44 ,0, 0];
get(7, 12) ->
	[7, 12, 0, [{6,12}], 0, 0, 142, 550, 48 ,0, 0];
get(7, 13) ->
	[7, 13, 0, [{6,13}], 0, 0, 166, 600, 52 ,0, 0];
get(7, 14) ->
	[7, 14, 0, [{6,14}], 0, 0, 192, 650, 56 ,0, 0];
get(7, 15) ->
	[7, 15, 0, [{6,15}], 0, 0, 220, 700, 60 ,0, 0];
get(7, 16) ->
	[7, 16, 0, [{6,16}], 0, 0, 250, 750, 64 ,0, 0];
get(7, 17) ->
	[7, 17, 0, [{6,17}], 0, 0, 282, 800, 68 ,0, 0];
get(7, 18) ->
	[7, 18, 0, [{6,18}], 0, 0, 316, 850, 72 ,0, 0];
get(7, 19) ->
	[7, 19, 0, [{6,19}], 0, 0, 352, 900, 76 ,0, 0];
get(7, 20) ->
	[7, 20, 0, [{6,20}], 0, 0, 390, 950, 80 ,0, 0];
get(7, 21) ->
	[7, 21, 0, [{6,21}], 0, 0, 1000, 1000, 88 ,0, 0];
get(7, 22) ->
	[7, 22, 0, [{6,22}], 0, 0, 1021, 1050, 96 ,0, 0];
get(7, 23) ->
	[7, 23, 0, [{6,23}], 0, 0, 1043, 1100, 104 ,0, 0];
get(7, 24) ->
	[7, 24, 0, [{6,24}], 0, 0, 1066, 1150, 112 ,0, 0];
get(7, 25) ->
	[7, 25, 0, [{6,25}], 0, 0, 1090, 1200, 120 ,0, 0];
get(7, 26) ->
	[7, 26, 0, [{6,26}], 0, 0, 1115, 1250, 128 ,0, 0];
get(7, 27) ->
	[7, 27, 0, [{6,27}], 0, 0, 1141, 1300, 136 ,0, 0];
get(7, 28) ->
	[7, 28, 0, [{6,28}], 0, 0, 1168, 1350, 144 ,0, 0];
get(7, 29) ->
	[7, 29, 0, [{6,29}], 0, 0, 1196, 1400, 152 ,0, 0];
get(7, 30) ->
	[7, 30, 0, [{6,30}], 0, 0, 1225, 1450, 160 ,0, 0];
get(7, 31) ->
	[7, 31, 0, [{6,31}], 0, 0, 1255, 1500, 168 ,0, 0];
get(7, 32) ->
	[7, 32, 0, [{6,32}], 0, 0, 1286, 1550, 176 ,0, 0];
get(7, 33) ->
	[7, 33, 0, [{6,33}], 0, 0, 1318, 1600, 184 ,0, 0];
get(7, 34) ->
	[7, 34, 0, [{6,34}], 0, 0, 1351, 1650, 192 ,0, 0];
get(7, 35) ->
	[7, 35, 0, [{6,35}], 0, 0, 1385, 1700, 200 ,0, 0];
get(7, 36) ->
	[7, 36, 0, [{6,36}], 0, 0, 1420, 1750, 208 ,0, 0];
get(7, 37) ->
	[7, 37, 0, [{6,37}], 0, 0, 1456, 1800, 216 ,0, 0];
get(7, 38) ->
	[7, 38, 0, [{6,38}], 0, 0, 1493, 1850, 224 ,0, 0];
get(7, 39) ->
	[7, 39, 0, [{6,39}], 0, 0, 1531, 1900, 232 ,0, 0];
get(7, 40) ->
	[7, 40, 0, [{6,40}], 0, 0, 1570, 1950, 240 ,0, 0];
get(7, 41) ->
	[7, 41, 0, [{6,41}], 0, 0, 1610, 2000, 248 ,0, 0];
get(7, 42) ->
	[7, 42, 0, [{6,42}], 0, 0, 1651, 2050, 256 ,0, 0];
get(7, 43) ->
	[7, 43, 0, [{6,43}], 0, 0, 1693, 2100, 264 ,0, 0];
get(7, 44) ->
	[7, 44, 0, [{6,44}], 0, 0, 1736, 2150, 272 ,0, 0];
get(7, 45) ->
	[7, 45, 0, [{6,45}], 0, 0, 1780, 2200, 280 ,0, 0];
get(7, 46) ->
	[7, 46, 0, [{6,46}], 0, 0, 1825, 2250, 288 ,0, 0];
get(7, 47) ->
	[7, 47, 0, [{6,47}], 0, 0, 1871, 2300, 296 ,0, 0];
get(7, 48) ->
	[7, 48, 0, [{6,48}], 0, 0, 1918, 2350, 304 ,0, 0];
get(7, 49) ->
	[7, 49, 0, [{6,49}], 0, 0, 1966, 2400, 312 ,0, 0];
get(7, 50) ->
	[7, 50, 0, [{6,50}], 0, 0, 2015, 2450, 320 ,0, 0];
get(7, 51) ->
	[7, 51, 0, [{6,51}], 0, 0, 2065, 2500, 328 ,0, 0];
get(7, 52) ->
	[7, 52, 0, [{6,52}], 0, 0, 2116, 2550, 336 ,0, 0];
get(7, 53) ->
	[7, 53, 0, [{6,53}], 0, 0, 2168, 2600, 344 ,0, 0];
get(7, 54) ->
	[7, 54, 0, [{6,54}], 0, 0, 2221, 2650, 352 ,0, 0];
get(7, 55) ->
	[7, 55, 0, [{6,55}], 0, 0, 2275, 2700, 360 ,0, 0];
get(7, 56) ->
	[7, 56, 0, [{6,56}], 0, 0, 2330, 2750, 368 ,0, 0];
get(7, 57) ->
	[7, 57, 0, [{6,57}], 0, 0, 2386, 2800, 376 ,0, 0];
get(7, 58) ->
	[7, 58, 0, [{6,58}], 0, 0, 2443, 2850, 384 ,0, 0];
get(7, 59) ->
	[7, 59, 0, [{6,59}], 0, 0, 2501, 2900, 392 ,0, 0];
get(7, 60) ->
	[7, 60, 0, [{6,60}], 0, 0, 2560, 2950, 400 ,0, 0];
get(8, 1) ->
	[8, 1, 0, [{7,1}], 0, 0, 10, 40, 12 ,0, 0];
get(8, 2) ->
	[8, 2, 0, [{7,2}], 0, 0, 12, 80, 24 ,0, 0];
get(8, 3) ->
	[8, 3, 0, [{7,3}], 0, 0, 16, 100, 36 ,0, 0];
get(8, 4) ->
	[8, 4, 0, [{7,4}], 0, 0, 22, 150, 48 ,0, 0];
get(8, 5) ->
	[8, 5, 0, [{7,5}], 0, 0, 30, 200, 60 ,0, 0];
get(8, 6) ->
	[8, 6, 0, [{7,6}], 0, 0, 40, 250, 72 ,0, 0];
get(8, 7) ->
	[8, 7, 0, [{7,7}], 0, 0, 52, 300, 84 ,0, 0];
get(8, 8) ->
	[8, 8, 0, [{7,8}], 0, 0, 66, 350, 96 ,0, 0];
get(8, 9) ->
	[8, 9, 0, [{7,9}], 0, 0, 82, 400, 108 ,0, 0];
get(8, 10) ->
	[8, 10, 0, [{7,10}], 0, 0, 100, 450, 120 ,0, 0];
get(8, 11) ->
	[8, 11, 0, [{7,11}], 0, 0, 120, 500, 132 ,0, 0];
get(8, 12) ->
	[8, 12, 0, [{7,12}], 0, 0, 142, 550, 144 ,0, 0];
get(8, 13) ->
	[8, 13, 0, [{7,13}], 0, 0, 166, 600, 156 ,0, 0];
get(8, 14) ->
	[8, 14, 0, [{7,14}], 0, 0, 192, 650, 168 ,0, 0];
get(8, 15) ->
	[8, 15, 0, [{7,15}], 0, 0, 220, 700, 180 ,0, 0];
get(8, 16) ->
	[8, 16, 0, [{7,16}], 0, 0, 250, 750, 192 ,0, 0];
get(8, 17) ->
	[8, 17, 0, [{7,17}], 0, 0, 282, 800, 204 ,0, 0];
get(8, 18) ->
	[8, 18, 0, [{7,18}], 0, 0, 316, 850, 216 ,0, 0];
get(8, 19) ->
	[8, 19, 0, [{7,19}], 0, 0, 352, 900, 228 ,0, 0];
get(8, 20) ->
	[8, 20, 0, [{7,20}], 0, 0, 390, 950, 240 ,0, 0];
get(8, 21) ->
	[8, 21, 0, [{7,21}], 0, 0, 1000, 1000, 264 ,0, 0];
get(8, 22) ->
	[8, 22, 0, [{7,22}], 0, 0, 1021, 1050, 288 ,0, 0];
get(8, 23) ->
	[8, 23, 0, [{7,23}], 0, 0, 1043, 1100, 312 ,0, 0];
get(8, 24) ->
	[8, 24, 0, [{7,24}], 0, 0, 1066, 1150, 336 ,0, 0];
get(8, 25) ->
	[8, 25, 0, [{7,25}], 0, 0, 1090, 1200, 360 ,0, 0];
get(8, 26) ->
	[8, 26, 0, [{7,26}], 0, 0, 1115, 1250, 384 ,0, 0];
get(8, 27) ->
	[8, 27, 0, [{7,27}], 0, 0, 1141, 1300, 408 ,0, 0];
get(8, 28) ->
	[8, 28, 0, [{7,28}], 0, 0, 1168, 1350, 432 ,0, 0];
get(8, 29) ->
	[8, 29, 0, [{7,29}], 0, 0, 1196, 1400, 456 ,0, 0];
get(8, 30) ->
	[8, 30, 0, [{7,30}], 0, 0, 1225, 1450, 480 ,0, 0];
get(8, 31) ->
	[8, 31, 0, [{7,31}], 0, 0, 1255, 1500, 504 ,0, 0];
get(8, 32) ->
	[8, 32, 0, [{7,32}], 0, 0, 1286, 1550, 528 ,0, 0];
get(8, 33) ->
	[8, 33, 0, [{7,33}], 0, 0, 1318, 1600, 552 ,0, 0];
get(8, 34) ->
	[8, 34, 0, [{7,34}], 0, 0, 1351, 1650, 576 ,0, 0];
get(8, 35) ->
	[8, 35, 0, [{7,35}], 0, 0, 1385, 1700, 600 ,0, 0];
get(8, 36) ->
	[8, 36, 0, [{7,36}], 0, 0, 1420, 1750, 624 ,0, 0];
get(8, 37) ->
	[8, 37, 0, [{7,37}], 0, 0, 1456, 1800, 648 ,0, 0];
get(8, 38) ->
	[8, 38, 0, [{7,38}], 0, 0, 1493, 1850, 672 ,0, 0];
get(8, 39) ->
	[8, 39, 0, [{7,39}], 0, 0, 1531, 1900, 696 ,0, 0];
get(8, 40) ->
	[8, 40, 0, [{7,40}], 0, 0, 1570, 1950, 720 ,0, 0];
get(8, 41) ->
	[8, 41, 0, [{7,41}], 0, 0, 1610, 2000, 744 ,0, 0];
get(8, 42) ->
	[8, 42, 0, [{7,42}], 0, 0, 1651, 2050, 768 ,0, 0];
get(8, 43) ->
	[8, 43, 0, [{7,43}], 0, 0, 1693, 2100, 792 ,0, 0];
get(8, 44) ->
	[8, 44, 0, [{7,44}], 0, 0, 1736, 2150, 816 ,0, 0];
get(8, 45) ->
	[8, 45, 0, [{7,45}], 0, 0, 1780, 2200, 840 ,0, 0];
get(8, 46) ->
	[8, 46, 0, [{7,46}], 0, 0, 1825, 2250, 864 ,0, 0];
get(8, 47) ->
	[8, 47, 0, [{7,47}], 0, 0, 1871, 2300, 888 ,0, 0];
get(8, 48) ->
	[8, 48, 0, [{7,48}], 0, 0, 1918, 2350, 912 ,0, 0];
get(8, 49) ->
	[8, 49, 0, [{7,49}], 0, 0, 1966, 2400, 936 ,0, 0];
get(8, 50) ->
	[8, 50, 0, [{7,50}], 0, 0, 2015, 2450, 960 ,0, 0];
get(8, 51) ->
	[8, 51, 0, [{7,51}], 0, 0, 2065, 2500, 984 ,0, 0];
get(8, 52) ->
	[8, 52, 0, [{7,52}], 0, 0, 2116, 2550, 1008 ,0, 0];
get(8, 53) ->
	[8, 53, 0, [{7,53}], 0, 0, 2168, 2600, 1032 ,0, 0];
get(8, 54) ->
	[8, 54, 0, [{7,54}], 0, 0, 2221, 2650, 1056 ,0, 0];
get(8, 55) ->
	[8, 55, 0, [{7,55}], 0, 0, 2275, 2700, 1080 ,0, 0];
get(8, 56) ->
	[8, 56, 0, [{7,56}], 0, 0, 2330, 2750, 1104 ,0, 0];
get(8, 57) ->
	[8, 57, 0, [{7,57}], 0, 0, 2386, 2800, 1128 ,0, 0];
get(8, 58) ->
	[8, 58, 0, [{7,58}], 0, 0, 2443, 2850, 1152 ,0, 0];
get(8, 59) ->
	[8, 59, 0, [{7,59}], 0, 0, 2501, 2900, 1176 ,0, 0];
get(8, 60) ->
	[8, 60, 0, [{7,60}], 0, 0, 2560, 2950, 1200 ,0, 0];
get(9, 1) ->
	[9, 1, 0, [{8,1}], 0, 0, 10, 60, 12 ,0, 0];
get(9, 2) ->
	[9, 2, 0, [{8,2}], 0, 0, 12, 80, 24 ,0, 0];
get(9, 3) ->
	[9, 3, 0, [{8,3}], 0, 0, 16, 100, 36 ,0, 0];
get(9, 4) ->
	[9, 4, 0, [{8,4}], 0, 0, 22, 150, 48 ,0, 0];
get(9, 5) ->
	[9, 5, 0, [{8,5}], 0, 0, 30, 200, 60 ,0, 0];
get(9, 6) ->
	[9, 6, 0, [{8,6}], 0, 0, 40, 250, 72 ,0, 0];
get(9, 7) ->
	[9, 7, 0, [{8,7}], 0, 0, 52, 300, 84 ,0, 0];
get(9, 8) ->
	[9, 8, 0, [{8,8}], 0, 0, 66, 350, 96 ,0, 0];
get(9, 9) ->
	[9, 9, 0, [{8,9}], 0, 0, 82, 400, 108 ,0, 0];
get(9, 10) ->
	[9, 10, 0, [{8,10}], 0, 0, 100, 450, 120 ,0, 0];
get(9, 11) ->
	[9, 11, 0, [{8,11}], 0, 0, 120, 500, 132 ,0, 0];
get(9, 12) ->
	[9, 12, 0, [{8,12}], 0, 0, 142, 550, 144 ,0, 0];
get(9, 13) ->
	[9, 13, 0, [{8,13}], 0, 0, 166, 600, 156 ,0, 0];
get(9, 14) ->
	[9, 14, 0, [{8,14}], 0, 0, 192, 650, 168 ,0, 0];
get(9, 15) ->
	[9, 15, 0, [{8,15}], 0, 0, 220, 700, 180 ,0, 0];
get(9, 16) ->
	[9, 16, 0, [{8,16}], 0, 0, 250, 750, 192 ,0, 0];
get(9, 17) ->
	[9, 17, 0, [{8,17}], 0, 0, 282, 800, 204 ,0, 0];
get(9, 18) ->
	[9, 18, 0, [{8,18}], 0, 0, 316, 850, 216 ,0, 0];
get(9, 19) ->
	[9, 19, 0, [{8,19}], 0, 0, 352, 900, 228 ,0, 0];
get(9, 20) ->
	[9, 20, 0, [{8,20}], 0, 0, 390, 950, 240 ,0, 0];
get(9, 21) ->
	[9, 21, 0, [{8,21}], 0, 0, 1000, 1000, 264 ,0, 0];
get(9, 22) ->
	[9, 22, 0, [{8,22}], 0, 0, 1021, 1050, 288 ,0, 0];
get(9, 23) ->
	[9, 23, 0, [{8,23}], 0, 0, 1043, 1100, 312 ,0, 0];
get(9, 24) ->
	[9, 24, 0, [{8,24}], 0, 0, 1066, 1150, 336 ,0, 0];
get(9, 25) ->
	[9, 25, 0, [{8,25}], 0, 0, 1090, 1200, 360 ,0, 0];
get(9, 26) ->
	[9, 26, 0, [{8,26}], 0, 0, 1115, 1250, 384 ,0, 0];
get(9, 27) ->
	[9, 27, 0, [{8,27}], 0, 0, 1141, 1300, 408 ,0, 0];
get(9, 28) ->
	[9, 28, 0, [{8,28}], 0, 0, 1168, 1350, 432 ,0, 0];
get(9, 29) ->
	[9, 29, 0, [{8,29}], 0, 0, 1196, 1400, 456 ,0, 0];
get(9, 30) ->
	[9, 30, 0, [{8,30}], 0, 0, 1225, 1450, 480 ,0, 0];
get(9, 31) ->
	[9, 31, 0, [{8,31}], 0, 0, 1255, 1500, 504 ,0, 0];
get(9, 32) ->
	[9, 32, 0, [{8,32}], 0, 0, 1286, 1550, 528 ,0, 0];
get(9, 33) ->
	[9, 33, 0, [{8,33}], 0, 0, 1318, 1600, 552 ,0, 0];
get(9, 34) ->
	[9, 34, 0, [{8,34}], 0, 0, 1351, 1650, 576 ,0, 0];
get(9, 35) ->
	[9, 35, 0, [{8,35}], 0, 0, 1385, 1700, 600 ,0, 0];
get(9, 36) ->
	[9, 36, 0, [{8,36}], 0, 0, 1420, 1750, 624 ,0, 0];
get(9, 37) ->
	[9, 37, 0, [{8,37}], 0, 0, 1456, 1800, 648 ,0, 0];
get(9, 38) ->
	[9, 38, 0, [{8,38}], 0, 0, 1493, 1850, 672 ,0, 0];
get(9, 39) ->
	[9, 39, 0, [{8,39}], 0, 0, 1531, 1900, 696 ,0, 0];
get(9, 40) ->
	[9, 40, 0, [{8,40}], 0, 0, 1570, 1950, 720 ,0, 0];
get(9, 41) ->
	[9, 41, 0, [{8,41}], 0, 0, 1610, 2000, 744 ,0, 0];
get(9, 42) ->
	[9, 42, 0, [{8,42}], 0, 0, 1651, 2050, 768 ,0, 0];
get(9, 43) ->
	[9, 43, 0, [{8,43}], 0, 0, 1693, 2100, 792 ,0, 0];
get(9, 44) ->
	[9, 44, 0, [{8,44}], 0, 0, 1736, 2150, 816 ,0, 0];
get(9, 45) ->
	[9, 45, 0, [{8,45}], 0, 0, 1780, 2200, 840 ,0, 0];
get(9, 46) ->
	[9, 46, 0, [{8,46}], 0, 0, 1825, 2250, 864 ,0, 0];
get(9, 47) ->
	[9, 47, 0, [{8,47}], 0, 0, 1871, 2300, 888 ,0, 0];
get(9, 48) ->
	[9, 48, 0, [{8,48}], 0, 0, 1918, 2350, 912 ,0, 0];
get(9, 49) ->
	[9, 49, 0, [{8,49}], 0, 0, 1966, 2400, 936 ,0, 0];
get(9, 50) ->
	[9, 50, 0, [{8,50}], 0, 0, 2015, 2450, 960 ,0, 0];
get(9, 51) ->
	[9, 51, 0, [{8,51}], 0, 0, 2065, 2500, 984 ,0, 0];
get(9, 52) ->
	[9, 52, 0, [{8,52}], 0, 0, 2116, 2550, 1008 ,0, 0];
get(9, 53) ->
	[9, 53, 0, [{8,53}], 0, 0, 2168, 2600, 1032 ,0, 0];
get(9, 54) ->
	[9, 54, 0, [{8,54}], 0, 0, 2221, 2650, 1056 ,0, 0];
get(9, 55) ->
	[9, 55, 0, [{8,55}], 0, 0, 2275, 2700, 1080 ,0, 0];
get(9, 56) ->
	[9, 56, 0, [{8,56}], 0, 0, 2330, 2750, 1104 ,0, 0];
get(9, 57) ->
	[9, 57, 0, [{8,57}], 0, 0, 2386, 2800, 1128 ,0, 0];
get(9, 58) ->
	[9, 58, 0, [{8,58}], 0, 0, 2443, 2850, 1152 ,0, 0];
get(9, 59) ->
	[9, 59, 0, [{8,59}], 0, 0, 2501, 2900, 1176 ,0, 0];
get(9, 60) ->
	[9, 60, 0, [{8,60}], 0, 0, 2560, 2950, 1200 ,0, 0];
get(10, 1) ->
	[10, 1, 0, [{9,1}], 0, 0, 10, 60, 12 ,0, 0];
get(10, 2) ->
	[10, 2, 0, [{9,2}], 0, 0, 12, 80, 24 ,0, 0];
get(10, 3) ->
	[10, 3, 0, [{9,3}], 0, 0, 16, 100, 36 ,0, 0];
get(10, 4) ->
	[10, 4, 0, [{9,4}], 0, 0, 22, 150, 48 ,0, 0];
get(10, 5) ->
	[10, 5, 0, [{9,5}], 0, 0, 30, 200, 60 ,0, 0];
get(10, 6) ->
	[10, 6, 0, [{9,6}], 0, 0, 40, 250, 72 ,0, 0];
get(10, 7) ->
	[10, 7, 0, [{9,7}], 0, 0, 52, 300, 84 ,0, 0];
get(10, 8) ->
	[10, 8, 0, [{9,8}], 0, 0, 66, 350, 96 ,0, 0];
get(10, 9) ->
	[10, 9, 0, [{9,9}], 0, 0, 82, 400, 108 ,0, 0];
get(10, 10) ->
	[10, 10, 0, [{9,10}], 0, 0, 100, 450, 120 ,0, 0];
get(10, 11) ->
	[10, 11, 0, [{9,11}], 0, 0, 120, 500, 132 ,0, 0];
get(10, 12) ->
	[10, 12, 0, [{9,12}], 0, 0, 142, 550, 144 ,0, 0];
get(10, 13) ->
	[10, 13, 0, [{9,13}], 0, 0, 166, 600, 156 ,0, 0];
get(10, 14) ->
	[10, 14, 0, [{9,14}], 0, 0, 192, 650, 168 ,0, 0];
get(10, 15) ->
	[10, 15, 0, [{9,15}], 0, 0, 220, 700, 180 ,0, 0];
get(10, 16) ->
	[10, 16, 0, [{9,16}], 0, 0, 250, 750, 192 ,0, 0];
get(10, 17) ->
	[10, 17, 0, [{9,17}], 0, 0, 282, 800, 204 ,0, 0];
get(10, 18) ->
	[10, 18, 0, [{9,18}], 0, 0, 316, 850, 216 ,0, 0];
get(10, 19) ->
	[10, 19, 0, [{9,19}], 0, 0, 352, 900, 228 ,0, 0];
get(10, 20) ->
	[10, 20, 0, [{9,20}], 0, 0, 390, 950, 240 ,0, 0];
get(10, 21) ->
	[10, 21, 0, [{9,21}], 0, 0, 1000, 1000, 264 ,0, 0];
get(10, 22) ->
	[10, 22, 0, [{9,22}], 0, 0, 1021, 1050, 288 ,0, 0];
get(10, 23) ->
	[10, 23, 0, [{9,23}], 0, 0, 1043, 1100, 312 ,0, 0];
get(10, 24) ->
	[10, 24, 0, [{9,24}], 0, 0, 1066, 1150, 336 ,0, 0];
get(10, 25) ->
	[10, 25, 0, [{9,25}], 0, 0, 1090, 1200, 360 ,0, 0];
get(10, 26) ->
	[10, 26, 0, [{9,26}], 0, 0, 1115, 1250, 384 ,0, 0];
get(10, 27) ->
	[10, 27, 0, [{9,27}], 0, 0, 1141, 1300, 408 ,0, 0];
get(10, 28) ->
	[10, 28, 0, [{9,28}], 0, 0, 1168, 1350, 432 ,0, 0];
get(10, 29) ->
	[10, 29, 0, [{9,29}], 0, 0, 1196, 1400, 456 ,0, 0];
get(10, 30) ->
	[10, 30, 0, [{9,30}], 0, 0, 1225, 1450, 480 ,0, 0];
get(10, 31) ->
	[10, 31, 0, [{9,31}], 0, 0, 1255, 1500, 504 ,0, 0];
get(10, 32) ->
	[10, 32, 0, [{9,32}], 0, 0, 1286, 1550, 528 ,0, 0];
get(10, 33) ->
	[10, 33, 0, [{9,33}], 0, 0, 1318, 1600, 552 ,0, 0];
get(10, 34) ->
	[10, 34, 0, [{9,34}], 0, 0, 1351, 1650, 576 ,0, 0];
get(10, 35) ->
	[10, 35, 0, [{9,35}], 0, 0, 1385, 1700, 600 ,0, 0];
get(10, 36) ->
	[10, 36, 0, [{9,36}], 0, 0, 1420, 1750, 624 ,0, 0];
get(10, 37) ->
	[10, 37, 0, [{9,37}], 0, 0, 1456, 1800, 648 ,0, 0];
get(10, 38) ->
	[10, 38, 0, [{9,38}], 0, 0, 1493, 1850, 672 ,0, 0];
get(10, 39) ->
	[10, 39, 0, [{9,39}], 0, 0, 1531, 1900, 696 ,0, 0];
get(10, 40) ->
	[10, 40, 0, [{9,40}], 0, 0, 1570, 1950, 720 ,0, 0];
get(10, 41) ->
	[10, 41, 0, [{9,41}], 0, 0, 1610, 2000, 744 ,0, 0];
get(10, 42) ->
	[10, 42, 0, [{9,42}], 0, 0, 1651, 2050, 768 ,0, 0];
get(10, 43) ->
	[10, 43, 0, [{9,43}], 0, 0, 1693, 2100, 792 ,0, 0];
get(10, 44) ->
	[10, 44, 0, [{9,44}], 0, 0, 1736, 2150, 816 ,0, 0];
get(10, 45) ->
	[10, 45, 0, [{9,45}], 0, 0, 1780, 2200, 840 ,0, 0];
get(10, 46) ->
	[10, 46, 0, [{9,46}], 0, 0, 1825, 2250, 864 ,0, 0];
get(10, 47) ->
	[10, 47, 0, [{9,47}], 0, 0, 1871, 2300, 888 ,0, 0];
get(10, 48) ->
	[10, 48, 0, [{9,48}], 0, 0, 1918, 2350, 912 ,0, 0];
get(10, 49) ->
	[10, 49, 0, [{9,49}], 0, 0, 1966, 2400, 936 ,0, 0];
get(10, 50) ->
	[10, 50, 0, [{9,50}], 0, 0, 2015, 2450, 960 ,0, 0];
get(10, 51) ->
	[10, 51, 0, [{9,51}], 0, 0, 2065, 2500, 984 ,0, 0];
get(10, 52) ->
	[10, 52, 0, [{9,52}], 0, 0, 2116, 2550, 1008 ,0, 0];
get(10, 53) ->
	[10, 53, 0, [{9,53}], 0, 0, 2168, 2600, 1032 ,0, 0];
get(10, 54) ->
	[10, 54, 0, [{9,54}], 0, 0, 2221, 2650, 1056 ,0, 0];
get(10, 55) ->
	[10, 55, 0, [{9,55}], 0, 0, 2275, 2700, 1080 ,0, 0];
get(10, 56) ->
	[10, 56, 0, [{9,56}], 0, 0, 2330, 2750, 1104 ,0, 0];
get(10, 57) ->
	[10, 57, 0, [{9,57}], 0, 0, 2386, 2800, 1128 ,0, 0];
get(10, 58) ->
	[10, 58, 0, [{9,58}], 0, 0, 2443, 2850, 1152 ,0, 0];
get(10, 59) ->
	[10, 59, 0, [{9,59}], 0, 0, 2501, 2900, 1176 ,0, 0];
get(10, 60) ->
	[10, 60, 0, [{9,60}], 0, 0, 2560, 2950, 1200 ,0, 0];
get(_Type, _Level) ->
	[].