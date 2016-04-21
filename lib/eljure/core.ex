defmodule Eljure.Core do

  def main do
    IO.puts "Starting Eljure REPL..."
    loop
  end

  defp loop do
    case read do
      "quit" -> ; # quit loop
      data ->
        print eval data
        loop;
    end
  end

  defp read do
    String.strip IO.gets "eljure> "
  end

  defp eval code do
    # TODO: implement code -> AST parser
    # TODO: evaluate the AST
    Eljure.Reader.read(code)
  end

  defp print result do
    IO.puts result
  end

end
