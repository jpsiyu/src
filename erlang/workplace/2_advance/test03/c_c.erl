-module(c_c).
-compile(export_all).

start(Beam) ->
	{ok, {_, [{abstract_code, {_, AC}}]}} = 
		beam_lib:chunks(code:which(Beam), [abstract_code]),
	File = erl_prettypr:format(erl_syntax:form_list(AC)),
	io:fwrite("~s~n", [File]).
