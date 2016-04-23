defmodule Eljure.Main do
  alias Eljure.Scope
  alias Eljure.Core

  def start do
    case Mix.env do
      :test -> ;
      _ ->
        IO.puts "Starting Eljure REPL..."
        Scope.new
        |> Scope.put("+", {:function, &({:integer, elem(Enum.at(&1, 0),1) + elem(Enum.at(&1, 1),1)})})
        |> loop
    end
  end

  defp loop scope do
    case String.strip IO.gets "eljure> " do
      "" -> loop scope

      "quit" ->; # quit loop

      data ->
        try do
          {result, updated_scope} = Core.eval Core.read(data), scope
          Core.print result
          loop updated_scope
        rescue
          ex in RuntimeError ->
            IO.puts ex.message
            loop scope
        end
    end
  end

end
