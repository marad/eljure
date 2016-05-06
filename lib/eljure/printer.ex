defmodule Eljure.Printer do
  import Eljure.Types

  def show(nil), do: "nil"
  def show(bool(true)), do: "true"
  def show(bool(false)), do: "false"
  def show(symbol(s)), do: to_string(s)
  def show(int(i,_)), do: to_string(i)
  def show(float(f)), do: to_string(f)
  def show(string(s)), do: "\"#{s}\""
  def show(keyword(k)), do: ":#{k}"
  def show(function(_f)), do: "<function>"
  def show(macro(_m)), do: "<macro>"
  def show(list(list)) do
    "(#{list |> Enum.map(&show/1)
             |> Enum.join(" ")})"
  end
  def show(vector(vector)) do
    "[#{vector |> Enum.map(&show/1)
               |> Enum.join(" ")}]"
  end
  def show(map(map)) do
    "{#{map |> Enum.flat_map(fn {k, v} -> [show(k), show(v)] end)
        |> Enum.join(" ")}}"
  end
  def show x do
    to_string(x) <> " !!not atom!!"
  end

  def as_string string(s) do
    s
  end

  def as_string x do
    show x
  end
end
