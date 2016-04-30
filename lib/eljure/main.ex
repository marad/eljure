defmodule Eljure.Main do
  alias Eljure.Core
  alias Eljure.Reader
  alias Eljure.Printer
  alias Eljure.Evaluator
  alias Eljure.Prelude

  def main args do
    start_repl
  end

  def start_repl do
    IO.puts "Starting Eljure REPL..."
    Core.create_root_scope
    |> Prelude.init
    |> loop
  end

  defp loop scope do
    case prompt do
      "" -> loop scope

      "quit" -> false # quit loop

      data ->
        try do
          {result, updated_scope} = Evaluator.eval Reader.read(data), scope
          print result
          loop updated_scope
        rescue
          ex ->
            IO.puts Exception.message ex
            loop scope
        end
    end
  end

  defp prompt do
    "eljure> " |> IO.gets |> String.strip
  end

  defp print term do
    IO.puts Printer.show term
  end

end
