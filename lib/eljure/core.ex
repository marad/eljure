defmodule Eljure.Core do
  alias Eljure.Scope
  import Eljure.Printer
  import Eljure.Types

  def create_root_scope do
    Scope.new %{
      "+"=> {:function, &plus/1},
      "-"=> {:function, &minus/1},
      "*"=> {:function, &mult/1},
      "/"=> {:function, &divide/1},
      "read-string" => {:function, &read_string/1},
      "slurp" => {:function, &slurp/1},
      "println" => {:function, &println/1},
      "cons" => {:function, &cons/1},
      "concat" => {:function, &concat/1},
    }
  end

  def values terms do
    Enum.map(terms, &value/1)
  end

  def plus args do
    {:integer, Enum.reduce(values(args), &+/2)}
  end

  def minus args do
    {:integer, Enum.reduce(values(args), &(&2 - &1))}
  end

  def mult args do
    {:integer, Enum.reduce(values(args), &*/2)}
  end

  def divide args do
    {:integer, Enum.reduce(values(args), &(div &2, &1))}
  end

  def read_string [str_expr | _] do
    Eljure.Reader.read(value(str_expr))
  end

  def slurp [{:string, file_name} | _] do
    case File.read(file_name) do
      {:ok, body} -> {:string, body}
      _ -> raise "No file #{file_name}"
    end
  end

  def println args do
    to_show = args
              |> Enum.map(&as_string/1)
              |> Enum.join(" ")

    native_to_ast(IO.puts to_show)
  end

  def cons args do
    case args do
      [value, {type, []}] -> {type, [value]}
      [value, {type, [_ | _] = list}] -> {type, [value | list]}
      _ -> raise "Invalid arguments! Expected value and a list."
    end
  end

  def concat args do
    result = args
             |> Enum.map(&value/1)
             |> Enum.reduce(&(&2 ++ &1))
   {:list, result}
  end

end
