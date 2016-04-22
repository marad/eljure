defmodule Eljure.Core do
  import Kernel, except: [apply: 2]

  def main do
    IO.puts "Starting Eljure REPL..."
    loop %{"+" => {:function, &({:integer, elem(&1,1) + elem(&2,1)})}}
  end

  defp loop env do
    case String.strip IO.gets "eljure> " do
      "" -> loop env

      "quit" ->; # quit loop

      data ->
        try do
          {result, newEnv} = eval read(data), env
          print result
          loop newEnv
        rescue 
          ex in RuntimeError -> 
            IO.puts ex.message
            loop env
        end
    end
  end

  # Reads input from stdio, parses and returns ast
  def read code do
    Eljure.Reader.read code
  end

  # Evaluates the AST
  def eval({:symbol, s}, env) do
    case Map.fetch(env, s) do
      {:ok, value} -> {value, env}
      :error -> raise "Undefined symbol: \"#{s}\""
    end
  end

  def eval({:list, [{:symbol, "def"}, {:symbol, s}, value]}, env) do
    {evaledValue, _} = eval value, env
    {nil, Map.put(env, s, evaledValue)}
  end

  def eval {:list, l} = ast, env do
    {f, _} = eval(Enum.at(l, 0), env)
    args = List.delete_at(l, 0) 
            |> Enum.map(&(eval(&1, env)))
            |> Enum.map(&(elem(&1, 0)))
    {apply(f, args), env}
  end

  def eval ast, env do
    {ast, env}
  end

  def apply {:function, f}, args do
    Kernel.apply(f, args)
  end

  def apply head, args do
    print(head)
  end

  # Prints the resulting value
  def print result do
    IO.puts as_string result
  end

  def as_string(nil), do: "nil"
  def as_string(true), do: "true"
  def as_string(false), do: "false"
  def as_string({:symbol, s}), do: to_string(s)
  def as_string({:integer, i}), do: to_string(i)
  def as_string({:string, s}), do: "\"#{s}\""
  def as_string({:keyword, k}), do: ":#{k}"
  def as_string({:list, list}) do
    "(#{list |> Enum.map(&as_string/1)
             |> Enum.join(" ")})"
  end
  def as_string({:vector, vector}) do
    "[#{vector |> Enum.map(&as_string/1)
               |> Enum.join(" ")}]"
  end
  def as_string({:map, map}) do
    "{#{map |> Enum.flat_map(fn {k, v} -> [as_string(k), as_string(v)] end)
        |> Enum.join(" ")}}"
  end
  def as_string x do
    to_string(x) <> " !!not atom!!"
  end

end
