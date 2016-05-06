defmodule Eljure.Types do
  def type {t, _, _} do t end
  def value {_, v, _} do v end
  def meta {_, _, m} do m end

  defmacro int(i, meta) do
    quote do
      {:integer, unquote(i), unquote(meta)}
    end
  end

  defmacro float(f, meta) do
    quote do
      {:float, unquote(f), unquote(meta)}
    end
  end

  defmacro string(s, meta) do
    quote do
      {:string, unquote(s), unquote(meta)}
    end
  end

  defmacro bool(b, meta) do
    quote do
      {:boolean, unquote(b), unquote(meta)}
    end
  end

  defmacro keyword(kw, meta) do
    quote do
      {:keyword, unquote(kw), unquote(meta)}
    end
  end

  defmacro symbol(s, meta) do
    quote do
      {:symbol, unquote(s), unquote(meta)}
    end
  end

  defmacro function(f, meta) do
    quote do
      {:function, unquote(f), unquote(meta)}
    end
  end

  defmacro list(f, meta) do
    quote do
      {:list, unquote(f), unquote(meta)}
    end
  end

  defmacro vector(v, meta) do
    quote do
      {:vector, unquote(v), unquote(meta)}
    end
  end

  defmacro map(m, meta) do
    quote do
      {:map, unquote(m), unquote(meta)}
    end
  end

  defmacro macro(m, meta) do
    quote do
      {:macro, unquote(m), unquote(meta)}
    end
  end

  def native_to_ast(term) when is_nil(term), do: nil
  def native_to_ast(term) when is_boolean(term), do: bool(term, nil)
  def native_to_ast(term) when is_atom(term), do: keyword(to_string(term), nil)
  def native_to_ast(term) when is_bitstring(term), do: string(term, nil)
  def native_to_ast(term) when is_integer(term), do: int(term, nil)
  def native_to_ast(term) when is_float(term), do: float(term, nil)

  def native_to_ast(term) when is_map(term) do
    converted_map = Enum.reduce(term, %{}, fn {k,v}, acc ->
      Map.put(acc, native_to_ast(k), native_to_ast(v))
    end)
    map(converted_map, nil)
  end

  def native_to_ast(term) when is_list(term) do
    vector( Enum.map(term, &native_to_ast/1), nil )
  end

  def native_to_ast(term) when is_tuple(term) do
    vector( term |> Tuple.to_list |> Enum.map(&native_to_ast/1), nil )
  end

  def native_to_ast(term) when is_function(term) do
    function( fn args -> native_to_ast(Kernel.apply(term, Enum.map(args, &value/1))) end, nil )
  end
end

