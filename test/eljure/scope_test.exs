defmodule EljureTest.Scope do
  use ExUnit.Case
  doctest Eljure.Scope
  alias Eljure.Scope

  test "should create empty scope" do
    assert true == Scope.empty?(Scope.new)
  end

  test "should create scope from map" do
    map = %{:key => :value}
    assert true == Scope.has_symbol?(Scope.new(map), :key)
  end

  test "should put and get symbol from scope" do
    scope = Scope.put(Scope.new, "symbol", :value)
    assert :value == Scope.get(scope, "symbol")
  end

  test "should lookup symbols in parent scope" do
    # given
    parent_scope = Scope.put(Scope.new, :key, :value)
    child_scope = Scope.child(parent_scope)

    # expect
    assert :value == Scope.get(child_scope, :key)
  end

  test "should not propagate child scope symbols to parent scope" do
    # given
    parent_scope = Scope.new
    Scope.put(Scope.child(parent_scope), :key, :value)

    # expect
    assert_raise RuntimeError, "Undefined symbol: \"key\"", fn ->
      Scope.get(parent_scope, :key)
    end
  end

  test "should raise error when symbol is not found" do
    assert_raise RuntimeError, "Undefined symbol: \"key\"", fn ->
      Scope.get(Scope.new, :key)
    end
  end

  test "child scope returning updated value from parent scope" do
    parent = Scope.new(%{"key" => :value})
    child = Scope.child(parent)

    Scope.put(parent, "key", :other)

    assert :other == Scope.get(child, "key")
  end

end
