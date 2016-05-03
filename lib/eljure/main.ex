defmodule Eljure.Main do
  alias Eljure.Core
  alias Eljure.Reader
  alias Eljure.Printer
  alias Eljure.Evaluator
  alias Eljure.Prelude

  def main [] do
    start_repl
  end

  def main [file] do
    scope = Core.create_root_scope
            |> Prelude.init
    Evaluator.eval Reader.read("(load-file \"#{file}\")"), scope
  end

  def main [file | args] do
    # TODO: run file with args
    IO.puts "To many arguments!"
  end

  def start_repl do
    Core.create_root_scope
    |> Prelude.init
    |> loop
  end

  defp parse_args args do
    {options, _, _} = OptionParser.parse(args, switches: [])
    options
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
          ex in ArityError ->
            # TODO: print stacktrace
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
