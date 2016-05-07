# Eljure

Eljure is general purpose Clojure-like programming language for Erlang's virtual machine.


## Building and Running

  You have to use elixir build tool called `mix`. Of course Erlang's virtual machine must be available as well.
  Run the following in terminal:

    mix escript.build

  This will generate the escript executable in main project directory. Then just run

    ./eljure

  to start REPL or:

    ./eljure program.elj

  to execute Eljure program.

