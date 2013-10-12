%% Feel free to use, reuse and abuse the code in this file.

-module(redirect_lookup).
-behaviour(cowboy_middleware).

-export([execute/2]).

execute(Req, Env) ->
	{Host, _} = cowboy_req:host(Req),
	io:fwrite("Request ~s -> ", [Host]),
	{ok, C} = eredis:start_link(),
	{ok, Json} = eredis:q(C, ["GET", "redirect:" ++ Host]),
	{Json2} = jiffy:decode(Json),
	Code = proplists:get_value(<<"Code">>, Json2),
	Destination = proplists:get_value(<<"Destination">>, Json2),
	io:fwrite("Response [~s] ~s~n", [Code, Destination]),
	{ok, Req2} = cowboy_req:reply(Code, [
                {<<"connection">>, <<"close">>},
                {<<"location">>, Destination}
        ], [], Req),
	{error, Req2, Env}.

