-module(code_lock_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    %% Код и кнопка блокировки по умолчанию
    DefaultCode = [1,2,3],
    DefaultLockButton = 9,
    code_lock_sup:start_link(DefaultCode, DefaultLockButton).

stop(_State) ->
    ok.

