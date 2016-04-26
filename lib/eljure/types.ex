defmodule Eljure.Types do
  def type {t, _} do t end
  def value {_, v} do v end

  def int(i), do: {:integer, i}
  def string(s), do: {:string, s}
  def bool(true), do: {:boolean, true}
  def bool(false), do: {:boolean, false}
  def keyword(kw), do: {:keyword, kw}
  def symbol(s), do: {:symbol, s}
  def function(f), do: {:function, f}
  def list(l), do: {:list, l}
  def vector(v), do: {:vector, v}
  def map(m), do: {:map, m}

  def native_to_ast(term) when is_nil(term), do: nil
  def native_to_ast(term) when is_boolean(term), do: bool(term)
  def native_to_ast(term) when is_atom(term), do: keyword(to_string(term))
  def native_to_ast(term) when is_bitstring(term), do: string(term)
  def native_to_ast(term) when is_integer(term), do: int(term)
  #def native_to_ast(term) when is_float(term), do: {:float, term}

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

