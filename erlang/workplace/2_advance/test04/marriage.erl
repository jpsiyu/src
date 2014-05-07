-module(marriage).
-compile(export_all).

init_wedding_cruise_list1(Hour) ->
    case Hour > 21 of
        true -> 
            skip;
        false ->
            {_Hour, _Min, _Sec} = time(),
            case {_Hour, _Min} > {Hour - 1, 45} of
                true ->
                    put({wedding_list, Hour}, {Hour, 3});
                false ->
                    case _Hour >= 19 of
                        true ->
                            put({wedding_list, Hour}, {Hour, 2});
                        false ->
                            put({wedding_list, Hour}, {Hour, 1})
                    end
            end,
            init_wedding_cruise_list1(Hour + 1)
    end.

init_wedding_cruise_list2(Hour) ->
    case Hour > 21 of
        true -> 
            skip;
        false ->
            {_Hour, _Min, _Sec} = time(),
            case {_Hour, _Min} > {Hour, 15} of
                true ->
                    put({cruise_list, Hour}, {Hour, 3});
                false ->
                    case _Hour >= 19 of
                        true ->
                            put({cruise_list, Hour}, {Hour, 2});
                        false ->
                            put({cruise_list, Hour}, {Hour, 1})
                    end
            end,
            init_wedding_cruise_list2(Hour + 1)
    end.
