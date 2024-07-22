defmodule Eljure do
  use Application

  def start(_type, _args) do
    Task.start(fn -> start_app end)
  end

  def start_app do
    case Mix.env do
      :test -> false
      _ -> Eljure.Main.start_repl
    end
  end

end
