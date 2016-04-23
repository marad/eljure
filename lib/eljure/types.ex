defmodule Eljure.Types do
  def type {t, _} do t end
  def value {_, v} do v end

  def native_to_ast(term) when is_nil(term), do: nil
  def native_to_ast(term) when is_boolean(term), do: {:boolean, term}
  def native_to_ast(term) when is_atom(term), do: {:keyword, to_string(term)}
  def native_to_ast(term) when is_bitstring(term), do: {:string, term}
  def native_to_ast(term) when is_integer(term), do: {:integer, term}
  def native_to_ast(term) when is_float(term), do: {:float, term}

  def native_to_ast(term) when is_map(term) do
    converted_map = Enum.reduce(term, %{}, fn {k,v}, acc ->
      Map.put(acc, native_to_ast(k), native_to_ast(v))
    end)
    {:map, converted_map}
  end

  def native_to_ast(term) when is_list(term) do
    {:vector, Enum.map(term, &native_to_ast/1)}
  end

  def native_to_ast(term) when is_tuple(term) do
    {:vector, term |> Tuple.to_list |> Enum.map(&native_to_ast/1)}
  end

  def native_to_ast(term) when is_function(term) do
    {:function, fn args -> native_to_ast(Kernel.apply(term, Enum.map(args, &value/1))) end}
  end
end

