-module(exer05).
-compile(export_all).

new() ->
	[].

destroy() ->
	ok.

write_element(Key, Element, Db) ->
	[{Key, Element} | Db].

delete(Key, Db) ->
	Ndb = d_match(Key, Db, []),
	Ndb.

d_match(_Key, [], Ndb) ->
	Ndb;
d_match(Key, [{Lkey, Value} | T], Ndb) ->
	case Lkey of	
		Key ->
			d_match(Key, T, Ndb);
		_ ->
			d_match(Key, T, [{Lkey, Value} | Ndb])
	end.

	
read(_Key, []) ->
	{error, instance};
read(Key, [{Lkey, Value} | T]) ->
	case Lkey of
		Key ->
			Value;
		_ ->
			read(Key, T)
	end.

match(Element, Db) ->
	Klist = m_match(Element, Db, []),
	Klist.

m_match(_Element, [], Klist) ->
	Klist;
m_match(Element, [{Lkey, Value} | T], Klist) ->
	case Value of 
		Element ->
			m_match(Element, T, [Lkey | Klist]);
		_ ->
			m_match(Element, T, Klist)
	end.
