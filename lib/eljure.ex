defmodule Eljure do
  use Application

  def start(_type, _args) do
    IO.puts "Starting app"
    #Task.start(fn -> Eljure.Core.main end)
    Task.start(fn -> Eljure.Core.main end)
  end
end
