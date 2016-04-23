defmodule EljureTest.Types do
  use ExUnit.Case
  doctest Eljure.Types
  import Eljure.Types

  test "converting native map to eljure map" do
    assert {:map, %{{:keyword, "key"} => {:string, "value"}}} == native_to_ast(%{key: "value"})
  end

  test "converting native list to eljure vector" do
    assert {:vector, [{:keyword, "a"}, {:keyword, "b"}]} == native_to_ast([:a, :b])
  end

  test "converting native tuple to eljure vector" do
    assert {:vector, [{:keyword, "a"}, {:keyword, "b"}]} == native_to_ast({:a, :b})
  end

  test "converting function to eljure function" do
    inc = native_to_ast(fn x -> x + 1 end)
    assert {:integer, 6} == Eljure.Evaluator.apply(inc, [{:integer, 5}])
  end
end
