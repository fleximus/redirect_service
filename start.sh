#!/bin/sh

cd `dirname $0`
/usr/local/bin/erl $1 -noshell -pa ebin deps/*/ebin -s redirect_service \
	-eval "io:format(\"Redirect service started~n\")." +K true
