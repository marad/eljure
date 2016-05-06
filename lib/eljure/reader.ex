defmodule Eljure.Reader do

  import Eljure.Types
  alias Eljure.Error.SyntaxError

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
      "'" -> read_quote("quote", tokens)
      "`" -> read_quote("quasiquote", tokens)
      "~" -> read_quote("unquote", tokens)
      "~@" -> read_quote("splice-unquote", tokens)
      ")" -> raise SyntaxError, message: "Read unexpected ')'"
      "]" -> raise SyntaxError, message: "Read unexpected ']'"
      "}" -> raise SyntaxError, message: "Read unexpected '}'"
      _ -> 
        { read_atom(next), rest }
    end
  end

  defp read_list([_ | tokens]) do
    { l, rest } = read_sequence(tokens, [], ")")
    { list(l, nil), rest }
  end

  defp read_vector([_ | tokens]) do
    { v, rest } = read_sequence(tokens, [], "]")
    { vector(v, nil), rest }
  end

  defp read_map([_ | tokens]) do
    { m, rest } = read_sequence(tokens, [], "}")
   
    { map(m 
          |> Enum.chunk(2)
          |> Enum.into(%{}, fn [k, v] -> {k, v} end), nil ), rest }
  end

  defp read_sequence([], _acc, stop) do
    raise SyntaxError, message: "Expected '#{stop}' but got EOF"
  end

  defp read_sequence([head | tail] = tokens, acc, stop) do
    case head do
      ^stop -> { Enum.reverse(acc), tail }
      _ ->
        { value, rest } = read_form(tokens)
        read_sequence(rest, [value | acc], stop)
    end
  end

  defp read_quote(name, [_ | tokens]) do
    { form, rest } = read_form(tokens)
    { list([symbol(name, nil), form], nil), rest }
  end

  defp read_atom("nil"), do: nil
  defp read_atom("true"), do: bool(true, nil)
  defp read_atom("false"), do: bool(false, nil)
  defp read_atom(":" <> tail), do: keyword(tail, nil)
  defp read_atom(token) do
    cond do
      String.starts_with?(token, "\"") and String.ends_with?(token, "\"") ->
        string(token
               |> String.slice(1..-2)
               |> String.replace("\\\\", "\\"), nil)

      is_integer?(token) ->
        int(Integer.parse(token) |> elem(0), nil)

      is_float?(token) ->
        float(Float.parse(token) |> elem(0), nil)

      true ->
        symbol(token, nil)
    end
  end
  
  defp is_integer?(input) do
    Regex.match?(~r/^-?[0-9]+$/, input)
  end

  defp is_float?(input) do
    Regex.match?(~r/^-?[0-9]+\.[0-9]+$/, input)
  end

end
