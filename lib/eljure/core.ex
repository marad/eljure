defmodule Eljure.Core do
  alias Eljure.Scope
  import Eljure.Types

  def create_root_scope do
    Scope.new
    |> Scope.put("+", {:function, &plus/1})
    |> Scope.put("-", {:function, &minus/1})
    |> Scope.put("*", {:function, &mult/1})
    |> Scope.put("/", {:function, &divide/1})
  end

  def values terms do
    Enum.map(terms, &value/1)
  end

  def plus args do
    {:integer, Enum.reduce(values(args), &+/2)}
  end

  def minus args do
    {:integer, Enum.reduce(values(args), &(&2 - &1))}
  end

  def mult args do
    {:integer, Enum.reduce(values(args), &*/2)}
  end

  def divide args do
    {:integer, Enum.reduce(values(args), &(div &2, &1))}
  end

end
