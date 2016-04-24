defmodule EljureTest.Core do
  use ExUnit.Case
  doctest Eljure.Core
  import Eljure.Core

  def int(x) do
    {:integer, x}
  end

  def list(l) do
    {:list, l}
  end

  def vector(v) do
    {:vector, v}
  end

  test "cons should add value at the beggining of a list" do
    args = [ int(5), list([int(10)])]
    assert list [int(5), int(10)] == cons args
  end

  test "cons should add value at the beggining of a vector" do
    args = [ int(5), vector([int(10), int(12)]) ]
    assert vector [int(5), int(10), int(12)] == cons args
  end

  test "cons should add to empty list/vector" do
    assert list [int(5)] == cons [int(5), list([])]
    assert vector [int(5)] == cons [int(5), vector([])]
  end

  test "concat should concatenate lists" do

  end

end
