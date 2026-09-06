%%%-------------------------------------------------------------------
%% @doc chat_node public API
%% @end
%%%-------------------------------------------------------------------

-module(chat_node_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    % Start distributed process group scope
    pg:start(chat_pg),

    % Configure WebSocket route
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/ws", chat_ws_handler, []}
        ]}
    ]),

    % Read port from env or default to 8080
    Port = application:get_env(chat_node, http_port, 8080),

    {ok, _} = cowboy:start_clear(http_listener,
        [{port, Port}],
        #{env => #{dispatch => Dispatch}}
    ),

    chat_node_sup:start_link().

stop(_State) ->
    cowboy:stop_listener(http_listener).
    
%% internal functions
