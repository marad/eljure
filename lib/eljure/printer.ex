defmodule Eljure.Printer do
  def show(nil), do: "nil"
  def show({:boolean, true, _}), do: "true"
  def show({:boolean, false, _}), do: "false"
  def show({:symbol, s, _}), do: to_string(s)
  def show({:integer, i, _}), do: to_string(i)
  def show({:float, i, _}), do: to_string(i)
  def show({:string, s, _}), do: "\"#{s}\""
  def show({:keyword, k, _}), do: ":#{k}"
  def show({:function, _f, _}), do: "<function>"
  def show({:macro, _m, _}), do: "<macro>"
  def show({:list, list, _}) do
    "(#{list |> Enum.map(&show/1)
             |> Enum.join(" ")})"
  end
  def show({:vector, vector, _}) do
    "[#{vector |> Enum.map(&show/1)
               |> Enum.join(" ")}]"
  end
  def show({:map, map, _}) do
    "{#{map |> Enum.flat_map(fn {k, v} -> [show(k), show(v)] end)
        |> Enum.join(" ")}}"
  end
  def show x do
    to_string(x) <> " !!not atom!!"
  end

  def as_string {:string, s, _} do
    s
  end

  def as_string x do
    show x
  end
end
