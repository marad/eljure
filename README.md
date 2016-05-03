# Eljure

Eljure is general purpose Clojure-like programming language for Erlang's virtual machine.

## Installation

  1. Add eljure to your list of dependencies in mix.exs:

        def deps do
          [{:eljure, "~> 0.0.1"}]
        end

  2. Ensure eljure is started before your application:

        def application do
          [applications: [:eljure]]
        end
