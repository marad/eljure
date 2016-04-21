defmodule Eljure.Reader do

  # This module is based on MAL code:
  # https://github.com/kanaka/mal/blob/master/elixir/lib/mal/reader.ex

  def read(input) do
    input
    |> tokenize
    |> read_form
    |> elem(0)
  end

  defp tokenize(input) do
    regex = ~r/[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*)/
    Regex.scan(regex, input, capture: :all_but_first)
    |> List.flatten
    |> List.delete_at(-1) # Remove the last match, which is an empty string
    |> Enum.filter(fn token -> not String.starts_with?(token, "#_") end)
  end

  defp read_form([next | rest] = tokens) do
    case next do
      "(" -> read_list(tokens)
      "[" -> read_vector(tokens)
      "{" -> read_map(tokens)
      _ -> 
        { read_atom(next), rest }
    end
  end

  defp read_list(tokens) do
    {list, rest} = read_sequence(List.delete_at(tokens, 0), [], ")")
    { {:list, list}, rest }
  end

  defp read_vector(tokens) do
    {vector, rest} = read_sequence(List.delete_at(tokens, 0), [], "]")
   { {:vector, vector}, rest }
  end

  defp read_map(tokens) do
    {map, rest} = read_sequence(List.delete_at(tokens, 0), [], "}")
   
    {{:map, map 
      |> Enum.chunk(2)
      |> Enum.into(%{}, fn [k, v] -> {k, v} end) }, rest }
  end

  defp read_sequence([], _acc, stop) do
    raise {:error, "Expected #{stop} but got nothing"}
  end

  defp read_sequence([head | tail] = tokens, acc, stop) do
    case head do
      ^stop -> { Enum.reverse(acc), tail }
      _ ->
        {value, rest} = read_form(tokens)
        read_sequence(rest, [value | acc], stop)
    end
  end

  defp read_atom("nil"), do: nil
  defp read_atom("true"), do: true
  defp read_atom("false"), do: false
  defp read_atom(":" <> tail), do: {:keyword, String.to_atom tail}
  defp read_atom(token) do
    cond do
      String.starts_with?(token, "\"") and String.ends_with?(token, "\"") ->
        {:string, token
        |> String.slice(1..-2)
        |> String.replace("\\\\", "\\")}

      is_integer?(token) ->
        {:integer, Integer.parse(token)
        |> elem(0)}

      true ->
        {:symbol, token}
    end
  end
  
  defp is_integer?(input) do
    Regex.match?(~r/^-?[0-9]+$/, input)
  end

end
