defmodule Eljure.Core do

  def main do
    IO.puts "Starting Eljure REPL..."
    loop
  end

  defp loop do
    case read do
      "" -> loop

      "quit" ->; # quit loop

      data ->
        print eval data
        loop
    end
  end

  # Reads input from stdio, parses and returns ast
  defp read do
    "eljure> "
    |> IO.gets
    |> String.strip
    |> Eljure.Reader.read
  end

  # Evaluates the AST
  defp eval ast do
    # TODO: evaluate the AST
    ast
  end


  # Prints the resulting value
  defp print result do
    IO.puts as_string result
  end

  defp as_string({:symbol, s}), do: to_string(s)
  defp as_string({:integer, i}), do: to_string(i)
  defp as_string({:string, s}), do: "\"#{s}\""
  defp as_string({:keyword, k}), do: ":#{k}"
  defp as_string({:list, list}) do
    "(#{list |> Enum.map(&as_string/1)
             |> Enum.join(" ")})"
  end
  defp as_string({:vector, vector}) do
    "[#{vector |> Enum.map(&as_string/1)
               |> Enum.join(" ")}]"
  end
  defp as_string({:map, map}) do
    "{#{map |> Enum.flat_map(fn {k, v} -> [as_string(k), as_string(v)] end)
        |> Enum.join(" ")}}"
  end

end
