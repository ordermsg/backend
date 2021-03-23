-module(tasty_listener).
-author("Order").
-license("MPL-2.0").
-description("The Tasty (voice/video protocol) UDP listener").

-define(PORT, 1747).

-export([start/0]).
-export([init/0, run/1]).
-record(state, {socket}).

start() -> {ok, spawn_link(?MODULE, init, [])}.

init() ->
    {ok, Socket} = gen_udp:open(?PORT, [inet, inet6, binary, {tos, 56}]),
    logging:log("Tasty listener running (node ~p, port ~p)", [node(), ?PORT]),
    register(tasty_listener, self()),

    run(#state{socket=Socket}).

run(State = #state{socket=Socket}) ->
    receive
        {udp, Socket, IP, Port, Packet} ->
            tasty_client:handle_packet({IP, Port}, Packet);
        {send, {IP, Port}, Data} ->
            gen_udp:send(Socket, IP, Port, Data)
    end,
    run(State).