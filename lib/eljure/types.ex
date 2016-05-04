defmodule Eljure.Types do
  def type {t, _, _} do t end
  def value {_, v, _} do v end
  def meta {_, _, m} do m end

  def int(i, meta \\ nil), do: {:integer, i, meta}
  def float(f, meta \\ nil), do: {:float, f, meta}
  def string(s, meta \\ nil), do: {:string, s, meta}
  def bool(b, meta \\ nil), do: {:boolean, b, meta}
  def keyword(kw, meta \\ nil), do: {:keyword, kw, meta}
  def symbol(s, meta \\ nil), do: {:symbol, s, meta}
  def function(f, meta \\ nil), do: {:function, f, meta}
  def list(l, meta \\ nil), do: {:list, l, meta}
  def vector(v, meta \\ nil), do: {:vector, v, meta}
  def map(m, meta \\ nil), do: {:map, m, meta}
  def macro(m, meta \\ nil), do: {:macro, m, meta}

  def native_to_ast(term) when is_nil(term), do: nil
  def native_to_ast(term) when is_boolean(term), do: bool(term)
  def native_to_ast(term) when is_atom(term), do: keyword(to_string(term))
  def native_to_ast(term) when is_bitstring(term), do: string(term)
  def native_to_ast(term) when is_integer(term), do: int(term)
  def native_to_ast(term) when is_float(term), do: float(term)

  def native_to_ast(term) when is_map(term) do
    converted_map = Enum.reduce(term, %{}, fn {k,v}, acc ->
      Map.put(acc, native_to_ast(k), native_to_ast(v))
    end)
    map(converted_map)
  end

  def native_to_ast(term) when is_list(term) do
    vector( Enum.map(term, &native_to_ast/1) )
  end

  def native_to_ast(term) when is_tuple(term) do
    vector( term |> Tuple.to_list |> Enum.map(&native_to_ast/1) )
  end

  def native_to_ast(term) when is_function(term) do
    function( fn args -> native_to_ast(Kernel.apply(term, Enum.map(args, &value/1))) end )
  end
end

