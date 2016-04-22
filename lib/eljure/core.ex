defmodule Eljure.Core do
  import Kernel, except: [apply: 2]
  alias Eljure.Reader
  alias Eljure.Scope
  alias Eljure.Repr

  def main do
    case Mix.env do
      :test -> ;
      _ ->
        IO.puts "Starting Eljure REPL..."
        Scope.new
        |> Scope.put("+", {:function, &({:integer, elem(&1,1) + elem(&2,1)})})
        |> loop
    end
  end

  defp loop scope do
    case String.strip IO.gets "eljure> " do
      "" -> loop scope

      "quit" ->; # quit loop

      data ->
        try do
          {result, updated_scope} = eval read(data), scope
          print result
          loop updated_scope
        rescue
          ex in RuntimeError ->
            IO.puts ex.message
            loop scope
        end
    end
  end

  # Reads input from stdio, parses and returns ast
  def read code do
    Reader.read code
  end

  # Evaluates the AST
  def eval({:symbol, s} = term, scope) do
    {Scope.get(scope, s), scope}
  end

  def eval({:list, [{:symbol, "def"}, {:symbol, s}, value]}, scope) do
    {evaledValue, _} = eval value, scope
    {nil, Scope.put(scope, s, evaledValue)}
  end

  def eval({:list, [{:symbol, "fn"}, {:vector, args} | body]}, scope) do
    Enum.map(args, &print/1)
    Enum.map(body, &print/1)
    {{:function, fn -> List.last(args) end}, scope}
  end

  def eval {:list, l} = ast, scope do
    {f, _} = eval(Enum.at(l, 0), scope)
    args = List.delete_at(l, 0)
            |> Enum.map(&(eval(&1, scope)))
            |> Enum.map(&(elem(&1, 0)))
    {apply(f, args), scope}
  end

  def eval ast, scope do
    {ast, scope}
  end

  def apply {:function, f}, args do
    Kernel.apply(f, args)
  end

  def apply head, args do
    print(head)
  end

  # Prints the resulting value
  def print result do
    IO.puts Repr.show result
  end
end
