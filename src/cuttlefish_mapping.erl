%% -------------------------------------------------------------------
%%
%% cuttlefish_mapping: models a single mapping
%%
%% Copyright (c) 2013 Basho Technologies, Inc.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
-module(cuttlefish_mapping).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-compile(export_all).
-endif.

-record(mapping, {
        key::string(),
        mapping::string(),
        default::term(),
        commented::term(),
        datatype = string :: cuttlefish_datatypes:datatype(),
        enum::[atom()],
        advanced = false :: boolean(),
        doc = [] :: list(),
        include_default::string()
    }).

-opaque mapping() :: #mapping{}.
-export_type([mapping/0]).

-export([
    parse/1,
    is_mapping/1,
    key/1,
    mapping/1,
    default/1,
    commented/1,
    datatype/1,
    enum/1,
    advanced/1,
    doc/1,
    include_default/1,
    replace/2,
    remove_duplicates/1
    ]).

-spec parse({mapping, string(), string(), [{atom(), any()}]}) -> mapping().
parse({mapping, Key, Mapping, Proplist}) ->
    #mapping{
        key = Key,
        default = proplists:get_value(default, Proplist),
        commented = proplists:get_value(commented, Proplist),
        mapping = Mapping,
        advanced = proplists:get_value(advanced, Proplist, false),
        datatype = proplists:get_value(datatype, Proplist, string),
        enum = proplists:get_value(enum, Proplist),
        doc = proplists:get_value(doc, Proplist, []),
        include_default = proplists:get_value(include_default, Proplist)  
    };
parse(_) -> error.

-spec is_mapping(any()) -> boolean().
is_mapping(M) ->
    is_tuple(M) andalso element(1, M) =:= mapping. 

-spec key(mapping()) -> string().
key(M) -> M#mapping.key.

-spec mapping(mapping()) -> string().
mapping(M) -> M#mapping.mapping.

-spec default(mapping()) -> term().
default(M) -> M#mapping.default.

-spec commented(mapping()) -> term().
commented(M)        -> M#mapping.commented.

-spec datatype(mapping()) -> cuttlefish_datatypes:datatype().
datatype(M) -> M#mapping.datatype.

-spec enum(mapping()) -> [atom()].
enum(M) -> M#mapping.enum.

-spec advanced(mapping()) -> boolean().
advanced(M) -> M#mapping.advanced.

-spec doc(mapping()) -> [string()].
doc(M) -> M#mapping.doc.

-spec include_default(mapping()) -> string().
include_default(M) -> M#mapping.include_default.

-spec replace(mapping(), [mapping()]) -> [mapping()].
replace(Mapping, ListOfMappings) ->
    Removed = lists:filter(fun(M) -> key(M) =/= key(Mapping) end, ListOfMappings), 
    Removed ++ [Mapping].

-spec remove_duplicates([mapping()]) -> [mapping()].
remove_duplicates(Mappings) ->
    lists:foldl(
        fun(Mapping, Acc) ->
            replace(Mapping, Acc)
        end, 
        [], 
        Mappings). 

-ifdef(TEST).

mapping_test() ->

    SampleMapping = {
        mapping,
        "conf.key",
        "erlang.key",
        [
            {advanced, true},
            {default, "default value"},
            {datatype, enum}, 
            {enum, ["on", "off"]},
            {commented, "commented value"},
            {include_default, "default_substitution"},
            {doc, ["documentation", "for feature"]}
        ]
    },

    Record = parse(SampleMapping),

    ?assertEqual("conf.key", Record#mapping.key),
    ?assertEqual("default value", Record#mapping.default),
    ?assertEqual("erlang.key", Record#mapping.mapping),
    ?assertEqual(true, Record#mapping.advanced),
    ?assertEqual(enum, Record#mapping.datatype),
    ?assertEqual(["on", "off"], Record#mapping.enum),
    ?assertEqual(["documentation", "for feature"], Record#mapping.doc),
    ?assertEqual("default_substitution", Record#mapping.include_default),

    %% funciton tests
    ?assertEqual("conf.key", key(Record)),
    ?assertEqual("default value", default(Record)),
    ?assertEqual("erlang.key", mapping(Record)),
    ?assertEqual(true, advanced(Record)),
    ?assertEqual(enum, datatype(Record)),
    ?assertEqual(["on", "off"], enum(Record)),
    ?assertEqual(["documentation", "for feature"], doc(Record)),
    ?assertEqual("default_substitution", include_default(Record)),

    ok.

replace_test() ->
    Element1 = parse({
        mapping,
        "conf.key18",
        "erlang.key4",
        [
            {advanced, true},
            {default, "default value"},
            {datatype, enum}, 
            {enum, ["on", "off"]},
            {commented, "commented value"},
            {include_default, "default_substitution"},
            {doc, ["documentation", "for feature"]}
        ]
    }),

    SampleMappings = [Element1,
    parse({
        mapping,
        "conf.key",
        "erlang.key1",
        [
            {advanced, true},
            {default, "default value"},
            {datatype, enum}, 
            {enum, ["on", "off"]},
            {commented, "commented value"},
            {include_default, "default_substitution"},
            {doc, ["documentation", "for feature"]}
        ]
    }),
    parse({
        mapping,
        "conf.key",
        "erlang.key2",
        [
            {advanced, true},
            {default, "default value"},
            {datatype, enum}, 
            {enum, ["on", "off"]},
            {commented, "commented value"},
            {include_default, "default_substitution"},
            {doc, ["documentation", "for feature"]}
        ]
    })
    ],

    Override = parse({
        mapping,
        "conf.key",
        "erlang.key",
        [
            {advanced, true},
            {default, "default value"},
            {datatype, enum}, 
            {enum, ["on", "off"]},
            {commented, "commented value"},
            {include_default, "default_substitution"},
            {doc, ["documentation", "for feature"]}
        ]
    }),

    NewMappings = replace(Override, SampleMappings),
    ?assertEqual([Element1, Override], NewMappings),
    ok.


remove_duplicates_test() ->
    SampleMappings = [parse({
        mapping,
        "conf.key",
        "erlang.key1",
        [
            {advanced, true},
            {default, "default value"},
            {datatype, enum}, 
            {enum, ["on", "off"]},
            {commented, "commented value"},
            {include_default, "default_substitution"},
            {doc, ["documentation", "for feature"]}
        ]
    }),
    parse({
        mapping,
        "conf.key",
        "erlang.key2",
        [
            {advanced, true},
            {default, "default value"},
            {datatype, enum}, 
            {enum, ["on", "off"]},
            {commented, "commented value"},
            {include_default, "default_substitution"},
            {doc, ["documentation", "for feature"]}
        ]
    })
    ],

    NewMappings = remove_duplicates(SampleMappings),
    [_|Expected] = SampleMappings,
    ?assertEqual(Expected, NewMappings),
    ok.

-endif.