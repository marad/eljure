defmodule EljureTest.Core do
  use ExUnit.Case
  doctest Eljure.Core
  import Eljure.Core
  alias Eljure.Scope
  alias Eljure.Reader

  defp sumFunc args do
    {:integer, elem(Enum.at(args,0), 1) + elem(Enum.at(args,1), 1)}
  end

  test "should eval symbol to it's value" do
    scope = Scope.put(Scope.new, "number", {:integer, 42})
    assert {{:integer, 42}, scope} == eval {:symbol, "number"}, scope
  end

  test "should eval symbol from parent scope" do
    scope = Scope.put(Scope.new, "number", {:integer, 42})
    child_scope = Scope.child(scope)
    assert {{:integer, 42}, child_scope} == eval {:symbol, "number"}, child_scope
  end

  test "should raise error when symbol is not found" do
    scope = Scope.new
    assert_raise RuntimeError, "Undefined symbol: \"sym\"", fn ->
      eval({:symbol, "sym"}, scope)
    end
  end

  test "should evaluate atoms to themselves" do
    scope = Scope.new
    assert {{:integer, 42}, scope}   == eval {:integer, 42}, scope
    assert {{:string, "s"}, scope}   == eval {:string, "s"}, scope
    assert {{:map, %{a: 2}}, scope}  == eval {:map, %{a: 2}}, scope
    assert {{:keyword, "kw"}, scope} == eval {:keyword, "kw"}, scope
    assert {{:vector, [1,2]}, scope} == eval {:vector, [1,2]}, scope
  end

  test "should eval lists as functions" do
    # given
    scope = %{
      "+" => {:function, &sumFunc/1},
      "a" => {:integer, 1},
      "b" => {:integer, 2}
    }
    expr = {:list, [{:symbol, "+"}, {:symbol, "a"}, {:symbol, "b"}]}

    # then
   assert {{:integer, 3}, scope} == eval expr, scope
  end

  test "'def' should define variables" do
    scope = Scope.new
    expr = {:list, [{:symbol, "def"}, {:symbol, "sym"}, {:integer, 5}]}
    assert {nil, %{"sym" => {:integer, 5}}} == eval expr, scope
  end

  test "'def' should eval value to be set" do
    # given
    scope = Scope.put(Scope.new, "+", {:function, &sumFunc/1})
    expr = Reader.read("(def sym (+ 1 2))")

    # when
    {result, updated_scope} = eval expr, scope

    #then
    assert result == nil
    assert updated_scope == Map.put(scope, "sym", {:integer, 3})
  end

  test "'fn' should create a function" do
    # given
    env = %{}
    expr = Reader.read("((fn [a] a) 5)")

    # when
    {result, updatedEnv} = eval expr, env

    # then
    assert env == updatedEnv
    assert {:integer, 5} == result
  end
  
end
