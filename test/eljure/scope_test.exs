defmodule EljureTest.Scope do
  use ExUnit.Case
  doctest Eljure.Scope
  alias Eljure.Scope

  test "should create empty scope" do
    assert %{} == Scope.new
  end

  test "should create scope from map" do
    map = %{:key => :value}
    assert map == Scope.from map
  end

  test "should put symbol in scope" do
    scope = Scope.new
    assert %{"symbol" => :value} == Scope.put(scope, "symbol", :value)
  end

  test "should get symbol from scope" do
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

end
