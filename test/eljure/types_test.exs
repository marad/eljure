defmodule EljureTest.Types do
  use ExUnit.Case
  doctest Eljure.Types
  import Eljure.Types

  test "creating types" do
    assert {:integer, 5, nil} == int(5, nil)
    assert {:integer, 6, nil} == int(6, nil)
    assert {:string, "hello", nil} == string("hello", nil)
    assert {:keyword, "kw", nil} == keyword("kw", nil)
    assert {:symbol, "s", nil} == symbol("s", nil)
    assert {:function, &+/2, nil} == function(&+/2, nil)
    assert {:list, [{:integer, 5, nil}], nil} == list [int(5, nil)], nil
    assert {:vector, [{:integer, 5, nil}], nil} == vector [int(5, nil)], nil
    assert {:map, %{a: 1}, nil} == map %{a: 1}, nil
  end

  test "converting native map to eljure map" do
    assert map(%{ keyword("key", nil) => string("value", nil) }, nil) == native_to_ast(%{key: "value"})
  end

  test "converting native list to eljure vector" do
    assert vector([keyword("a", nil), keyword("b", nil)], nil) == native_to_ast([:a, :b])
  end

  test "converting native tuple to eljure vector" do
    assert vector([keyword("a", nil), keyword("b", nil)], nil) == native_to_ast({:a, :b})
  end

  test "converting function to eljure function" do
    inc = native_to_ast(fn x -> x + 1 end)
    assert int(6, nil) == Eljure.Function.apply(inc, [int(5, nil)])
  end

  test "converting to eljure map to native map" do
    assert %{"hello" => 5} == ast_to_native map(%{string("hello",nil) => int(5,nil)}, nil)
  end

  test "converting eljure vector to native list" do
    assert [1, 2] == ast_to_native vector([int(1,nil), int(2,nil)], nil)
  end

  test "converting eljure list to native list" do
    assert [1, 2] == ast_to_native list([int(1,nil), int(2,nil)], nil)
  end

  test "converting keyword to atom" do
    assert :test == ast_to_native keyword("test",nil)
  end

end
