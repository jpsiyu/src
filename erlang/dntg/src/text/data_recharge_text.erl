%%%--------------------------------------
%%% @Module  : data_activity_text
%%% @Author  : calvin
%%% @Email   : calvinzhong888@gmail.com
%%% @Created : 2012.6.25
%%% @Description: 充值中文配置
%%%--------------------------------------

-module(data_recharge_text).
-compile(export_all).

get_mail_title() ->
	"充值成功".

get_email_content() ->
	"恭喜您，您于~w年~w月~w日~w时~w分充值的[~w元宝]已成功注入。".
