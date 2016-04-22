defmodule Eljure.Scope do
  def new, do: %{}

  def from(map), do: map

  def put(scope, name, value) do
    Map.put(scope, name, value)
  end

  def get(scope, name) do
    case Map.fetch(scope, name) do
      {:ok, value} -> value
      :error ->
        case Map.fetch(scope, "$parent") do
          {:ok, parent} -> get(parent, name)
          :error ->
            raise "Undefined symbol: \"#{name}\""
        end
    end
  end

  def child(parent) do
    put(new, "$parent", parent)
  end
end
