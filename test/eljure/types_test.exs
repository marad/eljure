defmodule EljureTest.Types do
  use ExUnit.Case
  doctest Eljure.Types
  import Eljure.Types

  test "creating types" do
    assert {:integer, 5, nil} == int(5)
    assert {:integer, 6, nil} == int(6)
    assert {:string, "hello", nil} == string("hello")
    assert {:keyword, "kw", nil} == keyword("kw")
    assert {:symbol, "s", nil} == symbol("s")
    assert {:function, &+/2, nil} == function(&+/2)
    assert {:list, [{:integer, 5, nil}], nil} == list [int(5)]
    assert {:vector, [{:integer, 5, nil}], nil} == vector [int(5)]
    assert {:map, %{a: 1}, nil} == map %{a: 1}
  end

  test "converting native map to eljure map" do
    assert map(%{ keyword("key") => string("value") }) == native_to_ast(%{key: "value"})
  end

  test "converting native list to eljure vector" do
    assert vector([keyword("a"), keyword("b")]) == native_to_ast([:a, :b])
  end

  test "converting native tuple to eljure vector" do
    assert vector([keyword("a"), keyword("b")]) == native_to_ast({:a, :b})
  end

  test "converting function to eljure function" do
    inc = native_to_ast(fn x -> x + 1 end)
    assert int(6) == Eljure.Function.apply(inc, [int(5)])
  end

end
