%%%------------------------------------
%%% @Module  : mod_word
%%% @Author  : xyao
%%% @Email   : jiexiaowen@gmail.com
%%% @Created : 2012.02.08
%%% @Description: 关键字检查
%%%------------------------------------
-module(mod_word).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([
        init/0, 
        php_update_all/0, 
        php_update_one/1, 
        import_words_by_id/1, 
        update_all/0,
        word_is_sensitive_talk/1, 
        replace_sensitive_talk/2, 
        word_is_sensitive_name/1, 
        replace_sensitive_name/1
    ]).

%%
%% API Functions
%%
%%
%% Include files
%%
-define(ETS_SENSITIVE_TALK, game_sensitive_words_talk).
-define(ETS_SENSITIVE_TALK_PASS_1,game_sensitive_words_talk_pass_1).
-define(ETS_SENSITIVE_TALK_PASS_2,game_sensitive_words_talk_pass_2).
-define(ETS_SENSITIVE_TALK_PASS_3,game_sensitive_words_talk_pass_3).
-define(ETS_SENSITIVE_NAME, game_sensitive_words_name).

%%
%% API Functions
%%
%% php通知更新
php_update_all() ->
    mod_disperse:send_other_server(mod_word, update_all, []),
    mod_disperse:cast_to_unite(mod_word, update_all, []),
    ok.

php_update_one(Id) ->
    mod_disperse:send_other_server(mod_word, import_words_by_id, [Id]),
    mod_disperse:cast_to_unite(mod_word, import_words_by_id, [Id]),
    ok.

init() ->
    ets:new(?ETS_SENSITIVE_TALK, [named_table, public, set]),
	ets:new(?ETS_SENSITIVE_TALK_PASS_1, [named_table, public, set]),
	ets:new(?ETS_SENSITIVE_TALK_PASS_2, [named_table, public, set]),
	ets:new(?ETS_SENSITIVE_TALK_PASS_3, [named_table, public, set]),
    ets:new(?ETS_SENSITIVE_NAME, [named_table, public, set]),	
    talk_init(),
	talk_pass_1_init(),
	talk_pass_2_init(),
	talk_pass_3_init(),
    name_init(),
    ok.

talk_init()->
	ets:delete_all_objects(?ETS_SENSITIVE_TALK),
	import_words_talk(?ETS_SENSITIVE_TALK, 0),
    ok.

talk_pass_1_init()->
	ets:delete_all_objects(?ETS_SENSITIVE_TALK_PASS_1),
	import_words_talk(?ETS_SENSITIVE_TALK_PASS_1, 1),
    ok.

talk_pass_2_init()->
	ets:delete_all_objects(?ETS_SENSITIVE_TALK_PASS_2),
	import_words_talk(?ETS_SENSITIVE_TALK_PASS_2, 2),
    ok.

talk_pass_3_init()->
	ets:delete_all_objects(?ETS_SENSITIVE_TALK_PASS_3),
	import_words_talk(?ETS_SENSITIVE_TALK_PASS_3, 3),
    ok.

name_init() ->
    ets:delete_all_objects(?ETS_SENSITIVE_NAME),
    import_words_name(?ETS_SENSITIVE_NAME),
    ok.

%%
%% Local Functions
%%

%% 更新所有词库
update_all() ->
    talk_init(),
    name_init(),
    ok.

import_words_by_id(Id) ->
    Data = db:get_one(io_lib:format(<<"select `word` from `base_word` where id = ~p limit 1">> , [Id])),
    X = io_lib:format("~ts", [Data]),
    add_word_to_ets(X, ?ETS_SENSITIVE_TALK),
    add_word_to_ets(X, ?ETS_SENSITIVE_NAME),
    ok.

%% 加载名称相关过滤
import_words_name(EtsName)->
    Terms = case application:get_env(filter_name) of
            {ok, malai} -> data_filter_malai:name();
            _ -> data_filter:name()
        end,
    Convert = fun(X) ->
                    X1 = io_lib:format("~ts", [X]),
                    erlang:list_to_binary(X1)
              end,
    Terms1 = lists:map(Convert, Terms),
    Terms2 = get_word_for_db(),
    lists:foreach(fun(X)-> add_word_to_ets(X, EtsName) end, Terms1),
    lists:foreach(fun(X)-> add_word_to_ets(X, EtsName) end, Terms2),
    ok.

%% 加载聊天相关过滤
%% @param EtsName  Ets名
%% @param TalkPass 0 敏感字库,需要加载数据库
%%                 1 放行字库等级段1,不要加载数据库
%%                 2 放行字库等级段2,不要加载数据库
%%                 3 放行字库等级段3,不要加载数据库
import_words_talk(EtsName, TalkPass)->
	case TalkPass of
		0 ->
			Terms2 = get_word_for_db(),    
		    lists:foreach(fun(X)-> add_word_to_ets(X, EtsName) end, Terms2),
			Terms = case application:get_env(filter_name) of
				{ok, malai} -> data_filter_malai:talk();
				_ -> data_filter:talk()
			end;
		1 ->
			Terms = case application:get_env(filter_name) of
				{ok, malai} -> data_filter_malai:talk_pass_1();
				_ -> data_filter:talk_pass_1()
			end;
		2 ->
			Terms = case application:get_env(filter_name) of
				{ok, malai} -> data_filter_malai:talk_pass_2();
				_ -> data_filter:talk_pass_2()
			end;
		3 ->
			Terms = case application:get_env(filter_name) of
				{ok, malai} -> data_filter_malai:talk_pass_3();
				_ -> data_filter:talk_pass_3()
			end
	end,
    Convert = fun(X) ->
                    X1 = io_lib:format("~ts", [X]),
                    erlang:list_to_binary(X1)
              end,
    Terms1 = lists:map(Convert, Terms),
    lists:foreach(fun(X)-> add_word_to_ets(X, EtsName) end, Terms1),
    ok.


get_word_for_db() ->
    Data = db:get_all(<<"select `word` from `base_word`">>),
    Convert = fun([X]) ->
            io_lib:format("~ts", [X])
    end,
    lists:map(Convert, Data).

add_word_to_ets(Word,EtsName)->
	UniString = unicode:characters_to_list(Word,unicode),
	case UniString of
		[]-> ignor;
		_->
			[HeadChar|_Left] = UniString,
			case ets:lookup(EtsName, HeadChar) of
				[]-> ets:insert(EtsName, {HeadChar,[UniString]});
				[{_H,OldList}]->
					case lists:member(UniString,OldList) of
						false->ets:insert(EtsName,{HeadChar,[UniString|OldList]});
						true-> ignor
					end
			end
	end.

word_is_sensitive_talk([])->
    false;
word_is_sensitive_talk(Utf8String) when is_list(Utf8String)->
    Utf8Binary = list_to_binary(Utf8String),
    word_is_sensitive_talk(Utf8Binary);
word_is_sensitive_talk(Utf8Binary) when is_binary(Utf8Binary)->
    UniString = unicode:characters_to_list(Utf8Binary,unicode),
    word_is_sensitive_kernel(UniString, ?ETS_SENSITIVE_TALK).

word_is_sensitive_name([])->
    false;
word_is_sensitive_name(Utf8String) when is_list(Utf8String)->
    Utf8Binary = list_to_binary(Utf8String),
    word_is_sensitive_name(Utf8Binary);
word_is_sensitive_name(Utf8Binary) when is_binary(Utf8Binary)->
    UniString = unicode:characters_to_list(Utf8Binary,unicode),
    word_is_sensitive_kernel(UniString, ?ETS_SENSITIVE_NAME).

word_is_sensitive_kernel([], _EtsName)->
	false;
word_is_sensitive_kernel(UniString, EtsName)->
	[HeadChar|TailString] = UniString,
	UniStrLen = length(UniString),
	WordList = get_key_char_wordlist(HeadChar,EtsName),
	Match = fun(Word)->
					WordLen = length(Word),
					if WordLen> UniStrLen-> false; %%小于敏感词长度直接false
					   WordLen =:=	UniStrLen->	UniString =:= Word; %%等于直接比较
					   true-> %%大于取词比较
						   HeadStr = lists:sublist(UniString,WordLen),
						   HeadStr =:= Word
					end
			end,
	case lists:any(Match, WordList) of
		true-> true;
		false-> word_is_sensitive_kernel(TailString,EtsName)
	end.
		
replace_sensitive_talk(Utf8String, Lv) when is_binary(Utf8String)->
	UniString = unicode:characters_to_list(Utf8String,unicode),
	ReplacedString = replace_sensitive_kernel(UniString,Lv,0,[],
											?ETS_SENSITIVE_TALK,?ETS_SENSITIVE_TALK_PASS_1,
											?ETS_SENSITIVE_TALK_PASS_2,?ETS_SENSITIVE_TALK_PASS_3),											
	unicode:characters_to_binary(ReplacedString, utf8);
replace_sensitive_talk(InputString,Lv)when is_list(InputString)->
	Utf8Binary = list_to_binary(InputString),
	replace_sensitive_talk(Utf8Binary,Lv);
replace_sensitive_talk(InputString,_Lv)->
	InputString.

replace_sensitive_name(Utf8String) when is_binary(Utf8String)->
	UniString = unicode:characters_to_list(Utf8String,unicode),
	ReplacedString = replace_sensitive_kernel(UniString,0,1,[],
											?ETS_SENSITIVE_NAME,?ETS_SENSITIVE_TALK_PASS_1,
											?ETS_SENSITIVE_TALK_PASS_2,?ETS_SENSITIVE_TALK_PASS_3),
	unicode:characters_to_binary(ReplacedString, utf8);
replace_sensitive_name(InputString)when is_list(InputString)->
	Utf8Binary = list_to_binary(InputString),
	replace_sensitive_name(Utf8Binary);
replace_sensitive_name(InputString)->
	InputString.

match_of_replace_sensitive_kernel(Word,Last,InputString,InputStrLen)->
	case Last of
		0->
		WordLen = length(Word),
		if WordLen>InputStrLen -> 0;
			WordLen=:=InputStrLen->
				if(InputString =:= Word)->
						WordLen;
				  true->
				  		0
				  end;
			true->
				HeadStr = lists:sublist(InputString,length(Word)),
				if(HeadStr =:= Word)->
					WordLen;
				  true->
				  	0
				  end
				end;
			_-> Last
		end.

replace_sensitive_kernel([],_Lv,_TalkOrName,LastRepaced, _EtsName,_EtsPass1Name,_EtsPass2Name,_EtsPass3Name)->
	LastRepaced;
%%@param TalkOrName 0表示聊天,聊天需要按等级放行屏蔽词; 1表示名字
replace_sensitive_kernel(InputString,Lv,TalkOrName,LastReplaced,EtsName,EtsPass1Name,EtsPass2Name,EtsPass3Name)->
	[HeadChar|_TailString] = InputString,
	%%WordList = get_key_char_wordlist(HeadChar,EtsName),
	InputStrLen = length(InputString),
	if		
		Lv>=50 andalso TalkOrName=:=0 ->
			%% 检测是否可放行
			WordPass_List = get_key_char_wordlist(HeadChar,EtsPass3Name),
			MatchPass = fun(WordPass,Last)->
						  match_of_replace_sensitive_kernel(WordPass,Last,InputString,InputStrLen)
						  end,
			case lists:foldl(MatchPass,0 ,WordPass_List) of
				0-> %% 不可放行直接走检测屏蔽字
					private_replace_sensitive_kernel(InputString,Lv,TalkOrName,LastReplaced,EtsName,EtsPass1Name,EtsPass2Name,EtsPass3Name);	
					%% 可放行
				SensWordPassLen->
					SubString = lists:sublist(InputString, 1, SensWordPassLen),
					LeftString = lists:sublist(InputString, SensWordPassLen + 1, InputStrLen - SensWordPassLen),
					NewReplaced = LastReplaced ++ SubString,
					replace_sensitive_kernel(LeftString,Lv,TalkOrName,NewReplaced,EtsName,EtsPass1Name,EtsPass2Name,EtsPass3Name)
			end;
		Lv>=39 andalso Lv=<49  andalso TalkOrName=:=0 ->
			%% 检测是否可放行
			WordPass_List = get_key_char_wordlist(HeadChar,EtsPass2Name),
			MatchPass = fun(WordPass,Last)->
						  match_of_replace_sensitive_kernel(WordPass,Last,InputString,InputStrLen)
						  end,
			case lists:foldl(MatchPass,0 ,WordPass_List) of
				0-> %% 不可放行直接走检测屏蔽字
					private_replace_sensitive_kernel(InputString,Lv,TalkOrName,LastReplaced,EtsName,EtsPass1Name,EtsPass2Name,EtsPass3Name);	
					%% 可放行
				SensWordPassLen->
					SubString = lists:sublist(InputString, 1, SensWordPassLen),
					LeftString = lists:sublist(InputString, SensWordPassLen + 1, InputStrLen - SensWordPassLen),
					NewReplaced = LastReplaced ++ SubString,
					replace_sensitive_kernel(LeftString,Lv,TalkOrName,NewReplaced,EtsName,EtsPass1Name,EtsPass2Name,EtsPass3Name)
			end;
		Lv>=1 andalso Lv=<38  andalso TalkOrName=:=0 ->
			%% 检测是否可放行
			WordPass_List = get_key_char_wordlist(HeadChar,EtsPass1Name),
			MatchPass = fun(WordPass,Last)->
						  match_of_replace_sensitive_kernel(WordPass,Last,InputString,InputStrLen)
						  end,
			case lists:foldl(MatchPass,0 ,WordPass_List) of
				0-> %% 不可放行直接走检测屏蔽字
					private_replace_sensitive_kernel(InputString,Lv,TalkOrName,LastReplaced,EtsName,EtsPass1Name,EtsPass2Name,EtsPass3Name);	
					%% 可放行
				SensWordPassLen->
					SubString = lists:sublist(InputString, 1, SensWordPassLen),
					LeftString = lists:sublist(InputString, SensWordPassLen + 1, InputStrLen - SensWordPassLen),
					NewReplaced = LastReplaced ++ SubString,
					replace_sensitive_kernel(LeftString,Lv,TalkOrName,NewReplaced,EtsName,EtsPass1Name,EtsPass2Name,EtsPass3Name)
			end;
		true ->
			private_replace_sensitive_kernel(InputString,Lv,TalkOrName,LastReplaced,EtsName,EtsPass1Name,EtsPass2Name,EtsPass3Name)
	end.


%% 检测屏蔽字，并替换
private_replace_sensitive_kernel(InputString,Lv,TalkOrName,LastReplaced,EtsName,EtsPass1Name,EtsPass2Name,EtsPass3Name)->
	[HeadChar|TailString] = InputString,
	WordList = get_key_char_wordlist(HeadChar,EtsName),
	InputStrLen = length(InputString),
	Match = fun(Word,Last)->
			match_of_replace_sensitive_kernel(Word,Last,InputString,InputStrLen)
	end,			
	case lists:foldl(Match,0 ,WordList) of
		0-> 
			NewReplaced = LastReplaced ++ [HeadChar],
			replace_sensitive_kernel(TailString,Lv,TalkOrName,NewReplaced,EtsName,EtsPass1Name,EtsPass2Name,EtsPass3Name);
		SensWordLen->
			LeftString = lists:sublist(InputString, SensWordLen + 1, InputStrLen - SensWordLen ),
			NewReplaced = LastReplaced ++ make_sensitive_show_string(SensWordLen),
			replace_sensitive_kernel(LeftString,Lv,TalkOrName,NewReplaced,EtsName,EtsPass1Name,EtsPass2Name,EtsPass3Name)
	end.

get_key_char_wordlist(KeyChar,EtsName)->
	case ets:lookup(EtsName,KeyChar) of
		[]-> [];
		[{_H,WordList}]-> WordList
	end.
make_sensitive_show_string(1)->
	"*";
make_sensitive_show_string(2)->
	"*&";
make_sensitive_show_string(3)->
	"*&^";
make_sensitive_show_string(4)->
	"*&^%";
make_sensitive_show_string(5)->
	"*&^%$";
make_sensitive_show_string(6)->
	"*&^%$#";
make_sensitive_show_string(7)->
	"*&^%$#@";
make_sensitive_show_string(8)->
	"*&^%$#@!";
make_sensitive_show_string(N)->
	M = N rem 8,
	C = N div 8,
	L1 = make_sensitive_show_string(M),
	L2 = lists:append(lists:duplicate(C,"*&^%$#@!")),
	lists:append([L2,L1]).
%test() ->
%    [DescList] = io_lib:format("~ts", ["蜀门"]),
%    io:format("~p~n",[word_is_sensitive(DescList)]),
%    [DescList1] = io_lib:format("~ts", ["玉之魂"]),
%    io:format("~p ~p~n", ["玉之魂", replace_sensitive(DescList1)]),
%    [DescList2] = io_lib:format("~ts", ["梦-话-西-游"]),
%    io:format("~p ~p~n", ["梦-话-西-游", replace_sensitive(DescList2)]),
%    [DescList3] = io_lib:format("~ts", ["游ke"]),
%    io:format("~p~n",[word_is_sensitive(DescList3)]),
%    [DescList4] = io_lib:format("~ts", ["纯-白"]),
%    io:format("~p~n",[word_is_sensitive(DescList4)]).

