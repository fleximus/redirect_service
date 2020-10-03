%% Feel free to use, reuse and abuse the code in this file.

-module(redirect_lookup).
-behaviour(cowboy_middleware).

-export([execute/2]).
-export([log/5]).

-define(REDIS_PREFIX, "redirect:").

execute(Req, Env) ->
        {Host, _} = cowboy_req:host(Req),
        {Path, _} = cowboy_req:path(Req),
	% Initiate a redis connection:
        {ok, C} = eredis:start_link(),
	% Lookup for full path:
	% Fallback to hostname:
	{Result, Req2} = check_full_path(C, Req, binary_to_list(Host), binary_to_list(Path)),
        {Result, Req2, Env}.

check_full_path(C, Req, Host, Path) ->
	Key = ?REDIS_PREFIX ++ Host ++ ":" ++ Path,
	io:format("Key lookup for \"~s\"~n", [Key]),
	case redis_lookup(C, ?REDIS_PREFIX ++ Host ++ ":" ++ Path) of
		% Lookup successful:
                {ok, Code, Destination} ->
                        redirect(Req, "[+]", Code, Destination);
		% Lookup unsuccessful:
                {error, _Reason} ->
			check_hostname(C, Req, Host)
	end.

check_hostname(C, Req, Host) ->
	case redis_lookup(C, ?REDIS_PREFIX ++ Host) of
		% Lookup successful:
                {ok, Code, Destination} ->
                        redirect(Req, "[+]", Code, Destination);
		% Lookup unsuccessful:
                {error, _Reason} ->
			redirect_default(Req)
	end.

redis_lookup(C, Key) ->
        {ok, Json} = eredis:q(C, ["GET", Key]),
	json_decode(Json).

json_decode(Json) ->
        try
                {Json2} = jiffy:decode(Json),
                Code = proplists:get_value(<<"Code">>, Json2),
                Destination = proplists:get_value(<<"Destination">>, Json2),
                case {Code, Destination} of
                        {undefined, undefined} -> {error, "Code and Dest undefined."};
                        {undefined, _} -> {error, "Code undefined."};
                        {_, undefined} -> {error, "Destination undefined."};
                        {_,_} -> {ok, Code, Destination}
                end
        catch
                Error:Reason -> {Error, Reason}
        end.

redirect(Req, Status, Code, Destination) ->
        {{RemoteAddress, _Port}, _Req} = cowboy_req:peer(Req),
        {Host, _Req} = cowboy_req:host(Req),
	log_async(RemoteAddress, Host, Destination, Code, Status),
        {ok, Req2} = cowboy_req:reply(Code, [
                {<<"connection">>, <<"close">>},
                {<<"location">>, Destination}
        ], [], Req),
        {error, Req2}.

redirect_default(Req) ->
	redirect(Req, "[-]", <<"302">>, <<"https://www.google.com">>).


log_async(RemoteAddress, Host, Destination, Code, Status) ->
	spawn(?MODULE, log, [RemoteAddress, Host, Destination, Code, Status]).

log(RemoteAddress, Host, Destination, Code, Status) ->
	{ok, Log} = syslog:open("redirect_service", [cons, perror, pid], local0),
	{A, B, C, D} = RemoteAddress,
	ResolvedHostname = case inet:gethostbyaddr(RemoteAddress) of
		{ok, {hostent, Hostname, _Fqdns, inet , 4, _}} -> Hostname;
		{error, _PosixReason} -> inet_parse:ntoa(RemoteAddress)
	end,
        syslog:log(Log, info, "~s [~b.~b.~b.~b] ~s -> ~s [~s] ~s~n", [ResolvedHostname, A, B, C, D, Host, Destination, Code, Status]),
	ok = syslog:close(Log).

