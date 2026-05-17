code_lock
=====

An OTP application

Build
-----

    $ rebar3 compile

Example
-----
```erl
Eshell V14.2.5.13 (press Ctrl+G to abort, type help(). for help)
1> code_lock:button(1).
ok
2> code_lock:button(2).
ok
3> code_lock:button(3).
Open. Code=[1,2,3]
ok
4> code_lock:set_code([7,8,9]).
[1,2,3]
Locked
5> code_lock:set_code([7,2,5]).
{error,locked}
6> code_lock:button(1).
ok
7> code_lock:button(2).
ok
8> code_lock:button(3).
ok
9> code_lock:button(4).
ok
10> code_lock:button(5).
ok
11> code_lock:button(6).
ok
12> code_lock:button(7).
ok
13> code_lock:button(7).
ok
14> code_lock:button(9).
Suspended (too many wrong attempts)
ok
Locked
15> whereis(code_lock).
<0.193.0>
16> exit(whereis(code_lock), kill).
true
=SUPERVISOR REPORT==== 17-May-2026::22:54:07.056649 ===
    supervisor: {local,code_lock_sup}
    errorContext: child_terminated
    reason: killed
    offender: [{pid,<0.193.0>},
               {id,code_lock},
               {mfargs,{code_lock,start_link,[[1,2,3],9]}},
               {restart_type,permanent},
               {significant,false},
               {shutdown,5000},
               {child_type,worker}]

Locked
17> whereis(code_lock).
<0.214.0>
