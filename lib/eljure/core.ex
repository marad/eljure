defmodule Eljure.Core do
  alias Eljure.Scope
  import Eljure.Printer
  import Eljure.Types
  alias Eljure.Error.ArityError

  def create_root_scope do
    Scope.new %{
      "+"=> function(&plus/1, nil),
      "-"=> function(&minus/1, nil),
      "*"=> function(&mult/1, nil),
      "/"=> function(&divide/1, nil),
      "read-string" => function(&read_string/1, nil),
      "slurp" => function(&slurp/1, nil),
      "println" => function(&println/1, nil),
      "cons" => function(&cons/1, nil),
      "concat" => function(&concat/1, nil),
      "str" => function(&str/1, nil),
      "list"=> function(&list_func/1, nil),
      "vector"=> function(&vector_func/1, nil),
      "with-meta"=> function(&with_meta/1, nil),
      "meta"=> function(&get_meta/1, nil),
    }
  end

  def values terms do
    Enum.map(terms, &value/1)
  end

  def plus args do
    int( Enum.reduce(values(args), &+/2), nil )
  end

  def minus args do
    int( Enum.reduce(values(args), &(&2 - &1)), nil )
  end

  def mult args do
    int( Enum.reduce(values(args), &*/2), nil)
  end

  def divide args do
    int( Enum.reduce(values(args), &(div &2, &1)), nil )

  end

  def read_string [str_expr | _] do
    Eljure.Reader.read(value(str_expr))
  end

  def slurp [string(file_name, nil) | _] do
    case File.read(file_name) do
      {:ok, body} -> string(body, nil)
      _ -> raise "Cannot open file #{file_name}"
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
      _ -> raise ArityError
    end
  end

  def concat args do
    result = args
             |> Enum.map(&value/1)
             |> Enum.reduce(&(&2 ++ &1))
    list(result, nil)
  end

  def str args do
    string(args
          |> Enum.map(&as_string/1)
          |> Enum.join(""), nil)
  end

  def list_func args do
    list(args, nil)
  end

  def vector_func args do
    vector(args, nil)
  end

  def with_meta args do
    case args do
      [{t, v, _}, m] -> {t, v, m}
      _ -> raise ArityError
    end
  end

  def get_meta args do
    case args do
      [{_, _, m}] -> m
      _ -> raise ArityError
    end
  end
end
