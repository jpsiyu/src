-module(exer09).
-compile(export_all).

-define(FILE_NAME, "text").
-define(NEW_FILE, "textn").
-define(Separator_list, " \t\n\"|").

start_format() ->
	Doc = to_doc(),
	{ok, Device} = file:open(?NEW_FILE, [append]),
	write_loop(Device, Doc, 0),
	file:close(Device).

write_loop(_Device, [], _N) ->
	ok;
write_loop(Device, [H | T], N) ->
	case N < 50 of
		true ->
			file:write_file(?NEW_FILE, [H] ++ " ", [append]),
			write_loop(Device, T, N + length(H) + 1);
		false ->
			io:format(Device, "~n", []),
			file:write_file(?NEW_FILE, [H] ++ " ", [append]),
			write_loop(Device, T, length(H) + 1)
	end.
	

%% open a file and return a raw_doc
to_raw_doc() ->
	{ok, Io} = file:open(?FILE_NAME, read),
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
to_doc() ->
	Raw = to_raw_doc(),
	Doc = read_word(Raw, []),
	Doc.

read_word([], Doc) ->
	Doc;
read_word([H | T], Doc) ->
	New = string:tokens(H, ?Separator_list),	
	read_word(T, lists:append(Doc, New)).

%% demonstrate how to read
file_reader() ->
	{ok, IoDevice} = file:open(?FILE_NAME, read),
	{ok, Data} = file:read(IoDevice, 100),
	file:close(IoDevice),
	Data.

%% demonstrate how to write
file_writer() ->
	file:write_file(?FILE_NAME, "what a wonderful world!", [append]),
	{ok, IoDevice} = file:open(?FILE_NAME, [append]),
	io:format(IoDevice, "~n", []),
	file:close(IoDevice),
	file:write_file(?FILE_NAME, "good job!", [append]).
