-module(server).

-behaviour(gen_server).

-export([init/1, code_change/3, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

-include("records.hrl").

init(State) ->
    NewState = wait_for_connection(State),
    {ok, NewState}.

wait_for_connection(State) ->
    log:info("Waiting for connection!"),
    {ok, Socket} = gen_tcp:listen(State#state.port,
                                  [inet,
                                   {active, once},
                                   list]),
    {ok, Accepted} = gen_tcp:accept(Socket),
    log:info("Incoming connection! :33"),
    #serv_state{sock = Accepted}.

handle_call(Any, _Caller, State) ->
    log:info("Unknown call: ~p", [Any]),
    {noreply, State}.

handle_cast({send, Line}, State) ->
    ok = gen_tcp:send(State#serv_state.sock, Line),
    ok = inet:setopts(State#serv_state.sock, [{active, once}]),
    {noreply, State};
handle_cast(Any, State) ->
    log:info("Unknown cast: ~p", [Any]),
    {noreply, State}.

handle_info({tcp, _From, Data}, State) ->
    ok = inet:setopts(State#serv_state.sock, [{active, once}]),
    io:fwrite("~n<<< ~ts", [Data]),
    {noreply, State};
handle_info({tcp_closed, _}, State) ->
    log:info("~nClient closed connection!", []),
    gen_tcp:close(State#serv_state.sock),
    NewState = wait_for_connection(State),
    {noreply, NewState};
handle_info(Any, State) ->
    log:info("Some info: ~p", [Any]),
    {noreply, State}.

terminate(Reason, State) ->
    gen_tcp:close(State#serv_state.sock),
    log:info("Terminating with reason: ~p", [Reason]),
    ok.

code_change(_OldVersion, State, _Extra) -> {ok, State}.
