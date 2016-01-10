# Redirect Service #

Redirect Service is a low latency solution built on Cowboy and Redis
to redirect client requests to other domains and/or urls centrally.

To compile this project you need rebar in your PATH.

Type the following command:
```
$ make
```

You can then start the Erlang node with the following command:
```
./start.sh
```

To create a sample JSON dataset in Redis use the following command:
```
./redis-cli
set "redirect:localhost" '{"Code": "301", "Destination": "http://fleximus.org/projects/redirect_service/"}'
```

To test the redirect use curl:
```
curl -I /dev/stdout http://localhost:8080
```
