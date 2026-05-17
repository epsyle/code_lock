-module(code_lock_sup).
-behaviour(supervisor).

-export([start_link/2, init/1]).

start_link(Code, LockButton) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, {Code, LockButton}).

init({Code, LockButton}) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 1,
        period => 5
    },
    ChildSpecs = [
        #{
            id => code_lock,
            start => {code_lock, start_link, [Code, LockButton]},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [code_lock]
        }
    ],
    {ok, {SupFlags, ChildSpecs}}.
