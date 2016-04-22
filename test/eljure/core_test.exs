defmodule EljureTest.Core do
  use ExUnit.Case
  doctest Eljure.Core
  import Eljure.Core

  test "should eval symbol to it's value" do
    env = %{"number" => {:integer, 42}}
    assert {{:integer, 42}, env} == eval {:symbol, "number"}, env
  end

  test "should raise error when symbol is not found" do
    env = %{}
    assert_raise RuntimeError, "Undefined symbol: \"sym\"", fn ->
      eval({:symbol, "sym"}, env)
    end
  end

  test "should evaluate atoms to themselves" do
    env = %{}
    assert {{:integer, 42}, env}   == eval {:integer, 42}, env
    assert {{:string, "s"}, env}   == eval {:string, "s"}, env
    assert {{:keyword, "kw"}, env} == eval {:keyword, "kw"}, env
    assert {{:vector, [1,2]}, env} == eval {:vector, [1,2]}, env
    assert {{:map, %{a: 2}}, env}  == eval {:map, %{a: 2}}, env
  end

  test "should eval lists as functions" do
    # given
    env = %{
      "+" => {:function, &({:integer, elem(&1, 1) + elem(&2, 1)})},
      "a" => {:integer, 1},
      "b" => {:integer, 2}
    }
    expr = {:list, [{:symbol, "+"}, {:symbol, "a"}, {:symbol, "b"}]}

    # then
   assert {{:integer, 3}, env} == eval expr, env
  end

  test "'def' should define variables" do
    env = %{}
    expr = {:list, [{:symbol, "def"}, {:symbol, "sym"}, {:integer, 5}]}
    assert {nil, %{"sym" => {:integer, 5}}} == eval expr, env
  end

  test "'def' should eval value to be set" do
    # given
    env = %{"+" => {:function, &({:integer, elem(&1, 1) + elem(&2, 1)})}}
    add_expr = {:list, [{:symbol, "+"}, {:integer, 1}, {:integer, 2}]}
    expr = {:list, [{:symbol, "def"}, {:symbol, "sym"}, add_expr]}

    # when
    {result, updatedEnv} = eval expr, env

    #then
    assert result == nil
    assert updatedEnv == Map.put(env, "sym", {:integer, 3})
  end
end
