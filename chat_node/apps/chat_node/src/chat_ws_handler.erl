-module(chat_ws_handler).
-behavior(cowboy_websocket).

-export([init/2, websocket_init/1, websocket_handle/2, websocket_info/2]).

init(Req, State) ->
    {cowboy_websocket, Req, State}.

websocket_init(State) ->
    % Register process in global 'lobby' group managed by 'pg'
    pg:join(chat_pg, lobby, self()),
    
    NodeStr = atom_to_binary(node(), utf8),
    {reply, {text, <<"Connected to node: ", NodeStr/binary>>}, State}.

websocket_handle({text, Msg}, State) ->
    % Broadcast message across all nodes joined in the 'lobby' group
    Members = pg:get_members(chat_pg, lobby),
    NodeStr = atom_to_binary(node(), utf8),
    Formatted = <<"[", NodeStr/binary, "]: ", Msg/binary>>,
    lists:foreach(fun(Pid) -> Pid ! {broadcast, Formatted} end, Members),
    {ok, State};
websocket_handle(_Data, State) ->
    {ok, State}.

websocket_info({broadcast, Msg}, State) ->
    {reply, {text, Msg}, State};
websocket_info(_Info, State) ->
    {ok, State}.