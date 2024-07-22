defmodule Eljure.Scope do

  def new(env \\ %{})
  def new(env) do
    case Agent.start_link(fn -> env end) do
      {:ok, pid} -> pid
      :error -> {:error, "Cannot create scope"}
    end
  end

  def put(scope, name, value) do
    Agent.update(scope, fn map ->
      Map.put(map, name, value)
    end)
    scope
  end

  def get(scope, name) do
    result = Agent.get(scope, fn map ->
      case Map.fetch(map, name) do
        {:ok, value} -> {:ok, value}
        :error ->
          case Map.fetch(map, "$parent") do
            {:ok, parent} -> {:ok, get(parent, name)}
            :error ->
              {:error, "Undefined symbol: \"#{name}\""}
          end
      end
    end)

    case result do
      {:ok, value} -> value
      {:error, msg} -> raise msg
    end
  end

  def child(parent) do
    put(new(), "$parent", parent)
  end

  def empty?(scope) do
    #Enum.empty?(scope)
    Agent.get(scope, fn map ->
      Enum.empty?(map)
    end)
  end

  def has_symbol?(scope, symbol) do
    Agent.get(scope, fn map ->
      Map.has_key?(map, symbol)
    end)
  end
end
