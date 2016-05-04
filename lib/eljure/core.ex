defmodule Eljure.Core do
  alias Eljure.Scope
  import Eljure.Printer
  import Eljure.Types

  def create_root_scope do
    Scope.new %{
      "+"=> function(&plus/1),
      "-"=> function(&minus/1),
      "*"=> function(&mult/1),
      "/"=> function(&divide/1),
      "read-string" => function(&read_string/1),
      "slurp" => function(&slurp/1),
      "println" => function(&println/1),
      "cons" => function(&cons/1),
      "concat" => function(&concat/1),
      "str" => function(&str/1),
      "list"=> function(&list_func/1),
      "vector"=> function(&vector_func/1),
      "with-meta"=> function(&with_meta/1),
      "meta"=> function(&get_meta/1),
    }
  end

  def values terms do
    Enum.map(terms, &value/1)
  end

  def plus args do
    int( Enum.reduce(values(args), &+/2) )
  end

  def minus args do
    int( Enum.reduce(values(args), &(&2 - &1)) )
  end

  def mult args do
    int( Enum.reduce(values(args), &*/2) )
  end

  def divide args do
    int( Enum.reduce(values(args), &(div &2, &1)) )

  end

  def read_string [str_expr | _] do
    Eljure.Reader.read(value(str_expr))
  end

  def slurp [{:string, file_name, _} | _] do
    case File.read(file_name) do
      {:ok, body} -> string(body)
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
      [value, {type, [], meta}] -> {type, [value], meta}
      [value, {type, [_ | _] = list, meta}] -> {type, [value | list], meta}
      _ -> raise "Invalid arguments! Expected value and a list."
    end
  end

  def concat args do
    result = args
             |> Enum.map(&value/1)
             |> Enum.reduce(&(&2 ++ &1))
    list(result)
  end

  def str args do
    string(args
          |> Enum.map(&as_string/1)
          |> Enum.join(""))
  end

  def list_func args do
    list(args)
  end

  def vector_func args do
    vector(args)
  end

  def with_meta args do
    case args do
      [{t, v, _}, m] -> {t, v, m}
      _ -> raise Eljure.Error.ArityError
    end
  end

  def get_meta args do
    case args do
      [{_, _, m}] -> m
      _ -> raise Eljure.Error.ArityError
    end
  end
end
