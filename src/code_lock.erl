-module(code_lock).
-behaviour(gen_statem).
-define(NAME, code_lock).

-export([start_link/2,stop/0]).
-export([button/1,set_lock_button/1,set_code/1]).
-export([init/1,callback_mode/0,terminate/3]).
-export([handle_event/4]).

start_link(Code, LockButton) ->
    gen_statem:start_link(
        {local,?NAME}, ?MODULE, {Code,LockButton}, []).
stop() ->
    gen_statem:stop(?NAME).

button(Button) ->
    gen_statem:cast(?NAME, {button,Button}).
set_lock_button(LockButton) ->
    gen_statem:call(?NAME, {set_lock_button,LockButton}).
set_code(NewCode) ->
    gen_statem:call(?NAME, {set_code,NewCode}).

init({Code,LockButton}) ->
    process_flag(trap_exit, true),
    Data = #{
      code => Code,
      length => length(Code),
      buttons => [],
      bad_count => 0
    },
    {ok, {locked,LockButton}, Data}.

callback_mode() ->
    [handle_event_function,state_enter].

%% State: locked
handle_event(enter, _OldState, {locked,_}, Data) ->
    do_lock(),
    {keep_state, Data#{buttons := [], bad_count := maps:get(bad_count, Data, 0)}};
handle_event(state_timeout, button, {locked,_}, Data) ->
    {keep_state, Data#{buttons := []}};
handle_event(
  cast, {button,Button}, {locked,LockButton},
  #{code := Code, length := Length, buttons := Buttons, bad_count := BadCount} = Data) ->

    NewButtons =
        case length(Buttons) < Length of
            true  -> Buttons ++ [Button];
            false -> tl(Buttons) ++ [Button]
        end,

    case length(NewButtons) =:= Length of
        false ->
            {keep_state, Data#{buttons := NewButtons},
             [{state_timeout,30_000,button}]};
        true ->
            case NewButtons =:= Code of
                true ->
                    {next_state, {open,LockButton},
                     Data#{buttons := [], bad_count := 0}};
                false ->
                    NewBadCount = BadCount + 1,
                    case NewBadCount >= 3 of
                        true ->
                            {next_state, {suspended,LockButton},
                             Data#{buttons := [], bad_count := 0},
                             [{state_timeout,10_000,unsuspend}]};
                        false ->
                            {keep_state, Data#{buttons := [], bad_count := NewBadCount},
                             [{state_timeout,30_000,button}]}
                    end
            end
    end;

%% State: open
handle_event(enter, _OldState, {open,_}, Data) ->
    do_unlock(maps:get(code, Data)),
    {keep_state_and_data,
     [{state_timeout,10_000,lock}]}; % Time in milliseconds
handle_event(state_timeout, lock, {open,LockButton}, Data) ->
    {next_state, {locked,LockButton}, Data};
handle_event(cast, {button,LockButton}, {open,LockButton}, Data) ->
    {next_state, {locked,LockButton}, Data};
handle_event(cast, {button,_}, {open,_}, _Data) ->
    {keep_state_and_data,[postpone]};
%% allow changing code in open state via call {set_code, NewCode}
handle_event(
  {call,From}, {set_code,NewCode},
  {open,_LockButton}, Data) ->
    OldCode = maps:get(code, Data),
    NewData = Data#{code => NewCode, length => length(NewCode)},
    {keep_state, NewData, [{reply,From,OldCode}]};

%% State: suspended
handle_event(enter, _OldState, {suspended,_}, Data) ->
    % on entering suspended we could log or do other actions
    io:format("Suspended (too many wrong attempts)~n", []),
    {keep_state, Data#{buttons := []}};
% all button attempts in suspended return an error reply if they come as calls
handle_event(cast, {button,_}, {suspended,_}, Data) ->
    {keep_state, Data, [{postpone}]};
handle_event({call,From}, {set_code,_}, {suspended,_}, Data) ->
    % do not allow changing code while suspended
    {keep_state, Data, [{reply,From,{error, suspended}}]};
handle_event(state_timeout, unsuspend, {suspended,LockButton}, Data) ->
    % after timeout go back to locked and reset bad_count
    {next_state, {locked,LockButton}, Data#{bad_count := 0, buttons := []}};

%% Common events
handle_event(
  {call,From}, {set_lock_button,NewLockButton},
  {StateName,OldLockButton}, Data) ->
    {next_state, {StateName,NewLockButton}, Data,
     [{reply,From,OldLockButton}]}.

do_lock() ->
    io:format("Locked~n", []).
do_unlock(Code) ->
    io:format("Open. Code=~p~n", [Code]).

terminate(_Reason, State, _Data) ->
    State =/= locked andalso do_lock(),
    ok.
