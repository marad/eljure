defmodule Eljure do
  use Application

  def start(_type, _args) do
    Task.start(fn -> Eljure.Main.start end)
  end
end
