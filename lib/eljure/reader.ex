defmodule Eljure.Reader do

  def read(input) do
    #input
    #|> tokenize
    #|> read_form
    read_form tokenize input
  end

  def tokenize(input) do
    IO.puts "Tokenizing #{input}..."
    [input]
  end

  def read_form([next | rest] = tokens) do
    case next do
      _ -> read_atom(tokens)
    end
  end

  defp read_atom("nil"), do: nil
  defp read_atom("true"), do: true
  defp read_atom("false"), do: false
  #defp read_atom(":" <> tail), do: keyword
  defp read_atom(token) do
    cond do
      String.starts_with?(token, "\"") and String.ends_with?(token, "\"") ->
        token
        |> String.slice(1..-2)
        |> String.replace("\\\\", "\\")

      is_integer?(token) ->
        Integer.parse(token)
        |> elem(0)

      true ->
        # Blad parsowania? nieznany atom?
        {:symbol, token}
    end
  end

  
  def is_integer?(input) do
    Regex.match?(~r/^-?[0-9]+$/, input)
  end

end
