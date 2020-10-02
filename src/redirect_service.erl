-module(redirect_service).

%% API.
-export([start/0]).

%% API.

start() ->
	ok = application:start(sasl),
	ok = application:start(syslog),
	ok = application:start(crypto),
	ok = application:start(cowlib),
	ok = application:start(ranch),
	ok = application:start(cowboy),
	ok = application:start(redirect_service).
