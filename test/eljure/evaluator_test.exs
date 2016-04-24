defmodule EljureTest.Evaluator do
  use ExUnit.Case
  doctest Eljure.Evaluator
  import Eljure.Evaluator
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
    scope = Scope.new(%{
      "+" => {:function, &sumFunc/1},
      "a" => {:integer, 1},
      "b" => {:integer, 2}
    })
    expr = {:list, [{:symbol, "+"}, {:symbol, "a"}, {:symbol, "b"}]}

    # then
   assert {{:integer, 3}, scope} == eval expr, scope
  end

  test "'def' should define variables" do
    scope = Scope.new
    expr = Reader.read "(def sym 5)"
    eval expr, scope
    assert {:integer, 5} == Scope.get(scope, "sym")
  end

  test "'def' should eval value to be set" do
    # given
    scope = Scope.put(Scope.new, "+", {:function, &sumFunc/1})
    expr = Reader.read("(def sym (+ 1 2))")

    # when
    {result, updated_scope} = eval expr, scope

    #then
    assert result == nil
    assert updated_scope == scope
    assert {:integer, 3} == Scope.get(updated_scope, "sym")
  end

  test "'fn' should create a function" do
    # given
    scope = Scope.new
    expr = Reader.read("((fn [a] a) 5)")

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert scope == updated_scope
    assert {:integer, 5} == result
  end

  test "'let' should create it's scope" do
    # given
    scope = Scope.put(Scope.new, "+", {:function, &sumFunc/1})
    expr = Reader.read "(let [a 5 b (+ a 1)] b)"

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert scope == updated_scope
    assert {:integer, 6} == result

  end

  test "'do' should eval list and return last value" do
    # given
    scope = Scope.new
    expr = Reader.read "(do (def a 5) a)"

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert {:integer, 5} == Scope.get(updated_scope, "a")
    assert {:integer, 5} == result
  end

  test "'if' special form" do
    scope = Scope.new
            |> Scope.put("t", {:integer, 1})
            |> Scope.put("f", {:integer, 0})
    assert {{:integer, 1}, scope} == eval(Reader.read("(if true t f)"), scope)
    assert {{:integer, 0}, scope} == eval(Reader.read("(if false t f)"), scope)
    assert {{:integer, 0}, scope} == eval(Reader.read("(if nil t f)"), scope)
  end

  test "'eval' should evaluate ast" do
    scope = Scope.new %{
      "+" => {:function, &sumFunc/1},
      "a" => {:integer, 5}
    }
    expr = Reader.read "(eval (+ a 1))"
    assert  {{:integer, 6}, scope} == eval(expr, scope)
  end

  test "'eval' should evaluate ast from symbol" do
    scope = Scope.new %{
      "+" => {:function, &sumFunc/1},
      "a" => {:integer, 5},
      "ast" => Reader.read("(+ a 1)"),
    }
    expr = Reader.read "(eval ast)"
    assert {{:integer, 6}, scope} == eval(expr, scope)
  end

  test "calling native elixir functions" do
    # given
    scope = Scope.new
    expr = Reader.read "(. String.reverse \"eljure\")"

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert scope == updated_scope
    assert {:string, "erujle"} == result
  end

end
