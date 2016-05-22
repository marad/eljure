defmodule Eljure.Namespace do
  alias Eljure.Prelude
  alias Eljure.Core

  def new do
    Core.create_root_scope
    |> Prelude.init
  end
end
