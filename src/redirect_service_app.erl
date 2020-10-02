%% Feel free to use, reuse and abuse the code in this file.

%% @private
-module(redirect_service_app).
-behaviour(application).

%% API.
-export([start/2]).
-export([stop/1]).

%% API.

start(_Type, _Args) ->
	Dispatch = cowboy_router:compile([
		{'_', [
			{"/[...]", cowboy_static, [
				{directory, {priv_dir, redirect_service, []}},
				{mimetypes, {fun mimetypes:path_to_mimes/2, default}}
			]}
		]}
	]),
	{ok, _} = cowboy:start_http(http, 100, [{port, 80}], [
		{env, [{dispatch, Dispatch}]},
		{middlewares, [cowboy_router, redirect_lookup, cowboy_handler]}
	]),
	redirect_service_sup:start_link().

stop(_State) ->
	ok.
