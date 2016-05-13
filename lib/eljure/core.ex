defmodule Eljure.Core do
  alias Eljure.Scope
  import Eljure.Printer
  import Eljure.Types
  alias Eljure.Error.ArityError

  def create_root_scope do
    Scope.new %{
      "+" => function(&plus/1, nil),
      "-" => function(&minus/1, nil),
      "*" => function(&mult/1, nil),
      "/" => function(&divide/1, nil),
      "=" => function(&eq/1, nil),
      ">" => function(&gt/1, nil),
      ">=" => function(&gte/1, nil),
      "<" => function(&lt/1, nil),
      "<=" => function(&lte/1, nil),
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
      "nil?" => function(&nil?/1, nil),
      "string?" => function(&string?/1, nil),
      "symbol?" => function(&symbol?/1, nil),
      "integer?" => function(&integer?/1, nil),
      "float?" => function(&float?/1, nil),
      "number?" => function(&number?/1, nil),
      "map?" => function(&map?/1, nil),
      "list?" => function(&list?/1, nil),
      "vector?" => function(&vector?/1, nil),
      "macro?" => function(&macro?/1, nil),
      "function?" => function(&function?/1, nil),
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

  def eq args do
    result = values(args)
    |> Enum.chunk(2,1)
    |> Enum.map(fn [a, b] -> a == b end)
    |> Enum.reduce(&(&1 && &2))
    bool( result, nil )
  end

  def lt args do
    result = values(args)
    |> Enum.chunk(2,1)
    |> Enum.map(fn [a, b] -> a < b end)
    |> Enum.reduce(&(&1 && &2))

    bool( result, nil )
  end

  def lte args do
    result = values(args)
    |> Enum.chunk(2,1)
    |> Enum.map(fn [a, b] -> a <= b end)
    |> Enum.reduce(&(&1 && &2))

    bool( result, nil )
  end

  def gt args do
    result = values(args)
    |> Enum.chunk(2,1)
    |> Enum.map(fn [a, b] -> a > b end)
    |> Enum.reduce(&(&1 && &2))

    bool( result, nil )
  end

  def gte args do
    result = values(args)
    |> Enum.chunk(2,1)
    |> Enum.map(fn [a, b] -> a >= b end)
    |> Enum.reduce(&(&1 && &2))

    bool( result, nil )
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

  def nil? [nil] do bool(true, nil) end
  def nil? _ do bool(false, nil) end

  def string? [string(_, _)] do bool(true, nil) end
  def string? _ do bool(false, nil) end

  def symbol? [symbol(_, _)] do bool(true, nil) end
  def symbol? _ do bool(false, nil) end

  def integer? [int(_,_)] do bool(true, nil) end
  def integer? _ do bool(false, nil) end

  def float? [float(_,_)] do bool(true, nil) end
  def float? _ do bool(false, nil) end

  def number? [float(_,_)] do bool(true, nil) end
  def number? [int(_,_)] do bool(true, nil) end
  def number? _ do bool(false, nil) end

  def map? [map(_, _)] do bool(true, nil) end
  def map? _ do bool(false, nil) end

  def list? [list(_, _)] do bool(true, nil) end
  def list? _ do bool(false, nil) end

  def vector? [vector(_,_)] do bool(true, nil) end
  def vector? _ do bool(false, nil) end

  def macro? [macro(_, _)] do bool(true, nil) end
  def macro? _ do bool(false, nil) end

  def function? [function(_, _)] do bool(true, nil) end
  def function? _ do bool(false, nil) end
end
