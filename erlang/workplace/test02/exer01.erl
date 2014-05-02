-module(exer01).
-compile(export_all).

-define(F_NAME, "exer01.erl").
-define(Separator_list, " ,.?%()[]{}<>-+=\t\n\";:|").

%% open a file and return a raw_doc
to_raw_doc() ->
	{ok, Io} = file:open(?F_NAME, read),
	Raw_doc = read_line(Io, []),
	Raw_doc.

%% convert lines in a file to  a list
read_line(File, Rece) ->
	case io:get_line(File, Rece) of
		eof ->
			Rece;
		Line ->
			New = lists:append(Rece, [Line]),
			read_line(File, New)
	end.

%% convert raw doc to doc
to_doc(Raw) ->
	Doc = read_word(Raw, []),
	Doc.

read_word([], Doc) ->
	Doc;
read_word([H | T], Doc) ->
	New = string:tokens(H, ?Separator_list),	
	read_word(T, lists:append(New, Doc)).

%% create an index with doc
to_index(Doc) ->
	Index_dict = create_index(Doc, dict:new(), 1),
	List = dict:to_list(Index_dict),
	New = [{Key, lists:append(Vlist, [-1])} || {Key, Vlist} <- List],
	New.

create_index([], Dict, _Number) ->
	Dict;
create_index([Doc_H | Doc_T], Dict, Number) ->
	Dict2 = dict:append(Doc_H, Number, Dict),
	create_index(Doc_T, Dict2, Number + 1).
