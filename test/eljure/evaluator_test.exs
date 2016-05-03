defmodule EljureTest.Evaluator do
  use ExUnit.Case
  doctest Eljure.Evaluator
  import Eljure.Evaluator
  import Eljure.Types
  alias Eljure.Scope
  alias Eljure.Reader

  defp sumFunc args do
    int( Enum.reduce(Enum.map(args, &value/1), &+/2) )
  end

  test "should eval symbol to it's value" do
    scope = Scope.put(Scope.new, "number", int(42))
    assert {int(42), scope} == eval symbol("number"), scope
  end

  test "should eval symbol from parent scope" do
    scope = Scope.put(Scope.new, "number", int(42))
    child_scope = Scope.child(scope)
    assert {int(42), child_scope} == eval symbol("number"), child_scope
  end

  test "should raise error when symbol is not found" do
    scope = Scope.new
    assert_raise RuntimeError, "Undefined symbol: \"sym\"", fn ->
      eval(symbol("sym"), scope)
    end
  end

  test "should evaluate atoms to themselves" do
    scope = Scope.new
    assert {int(42), scope}   == eval int(42), scope
    assert {string("s"), scope}   == eval string("s"), scope
    assert {map(%{a: 2}), scope}  == eval map(%{a: 2}), scope
    assert {keyword("kw"), scope} == eval keyword("kw"), scope
    assert {vector([1, 2]), scope} == eval vector([1, 2]), scope
  end

  test "should eval lists as functions" do
    # given
    scope = Scope.new(%{
      "+" => function(&sumFunc/1),
      "a" => int(1),
      "b" => int(2)
    })
    expr = Reader.read "(+ a b)"

    # expect
   assert {int(3), scope} == eval expr, scope
  end

  test "should evaluate vector tokens" do
    scope = Scope.new %{
      "a" => int(3)
    }
    expr = Reader.read "[1 2 a]"
    assert {vector([int(1), int(2), int(3)]), scope} == eval expr, scope
  end

  test "should evaluate map tokens" do
    scope = Scope.new %{
      "a" => int(3)
    }
    expr = Reader.read "{:a a}"
    assert {map(%{keyword("a") => int(3)}), scope} == eval expr, scope
  end

  test "'def' should define variables" do
    scope = Scope.new
    expr = Reader.read "(def sym 5)"
    eval expr, scope
    assert int(5) == Scope.get(scope, "sym")
  end

  test "'def' should eval value to be set" do
    # given
    scope = Scope.put(Scope.new, "+", function(&sumFunc/1))
    expr = Reader.read "(def sym (+ 1 2))"

    # when
    {result, updated_scope} = eval expr, scope

    #then
    assert symbol("sym") == result
    assert scope == updated_scope
    assert int(3) == Scope.get(updated_scope, "sym")
  end

  test "'fn' should create a function" do
    # given
    scope = Scope.new
    expr = Reader.read "((fn [a] a) 5)"

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert scope == updated_scope
    assert int(5) == result
  end

  test "'let' should create it's scope" do
    # given
    scope = Scope.put(Scope.new, "+", function(&sumFunc/1))
    expr = Reader.read "(let [a 5 b (+ a 1)] b)"

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert scope == updated_scope
    assert int(6) == result

  end

  test "'do' should eval list and return last value" do
    # given
    scope = Scope.new
    expr = Reader.read "(do (def a 5) a)"

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert int(5) == Scope.get(updated_scope, "a")
    assert int(5) == result
  end

  test "'if' special form" do
    scope = Scope.new
            |> Scope.put("t", int(1))
            |> Scope.put("f", int(0))
    assert {int(1), scope} == eval(Reader.read("(if true t f)"), scope)
    assert {int(0), scope} == eval(Reader.read("(if false t f)"), scope)
    assert {int(0), scope} == eval(Reader.read("(if nil t f)"), scope)
  end

  test "'eval' should evaluate ast" do
    scope = Scope.new %{
      "+" => function(&sumFunc/1),
      "a" => int(5)
    }
    expr = Reader.read "(eval (+ a 1))"
    assert  {int(6), scope} == eval(expr, scope)
  end

  test "'eval' should evaluate ast from symbol" do
    scope = Scope.new %{
      "+" => function(&sumFunc/1),
      "a" => int(5),
      "ast" => Reader.read "(+ a 1)"
    }
    expr = Reader.read "(eval ast)"
    assert {int(6), scope} == eval(expr, scope)
  end

  test "'quote' should return unevaluated first form" do
    scope = Scope.new
    expr = Reader.read "(quote (1 2))"
    assert { list([int(1), int(2)]), scope } == eval(expr, scope)
  end

  test "'quasiquote' should return unevaluated first form" do
    scope = Eljure.Core.create_root_scope
    assert { list([int(1)]), scope } == eval(Reader.read("(quasiquote (1))"), scope)
    assert {int(2), scope } == eval(Reader.read("(quasiquote (unquote (+ 1 1)))"), scope)
  end

  test "complex quasiquote expression" do
    scope = Eljure.Core.create_root_scope
            |> Scope.put("a", int(2))
            |> Scope.put("b", vector([int(3), int(4)]))
    expr = Reader.read "(quasiquote (1 (unquote a) (splice-unquote b)))"
    expr2 = Reader.read "`(1 ~a ~@b)"
    expected = Reader.read "(1 2 3 4)"
    assert {expected, scope} == eval expr, scope
    assert {expected, scope} == eval expr2, scope
  end

  test "'apply' should apply function to arguments" do
    scope = Scope.new %{
      "+" => function(&sumFunc/1),
    }

    #1
    with_arg_vector = Reader.read "(apply + 1 2 [3 4])"
    assert { int(10), scope } == eval(with_arg_vector, scope)

    #2
    without_arg_vector = Reader.read "(apply + 1 2 3)"
    assert { int(6), scope } == eval(without_arg_vector, scope)
  end

  test "calling native elixir functions" do
    # given
    scope = Scope.new
    expr = Reader.read "(. String.reverse \"eljure\")"

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert scope == updated_scope
    assert string("erujle") == result
  end

  test "defining macro" do
    scope = Scope.new
    expr = Reader.read "(defmacro test [a b] `(a ~b))"

    {result, updated_scope} = eval expr, scope

    assert scope == updated_scope
    assert :macro == type(result)
  end

  test "expanding macro" do
    # given
    scope = Scope.new %{
      "x" => int(7)
    }
    macro_expr = Reader.read "(defmacro test [name] `(defn ~name [x] x))"
    expand_expr = Reader.read "(macroexpand-1 '(test identity))"
    expected_result = Reader.read "(defn identity [x] x)"

    # when
    eval macro_expr, scope
    {result, updated_scope} = eval expand_expr, scope

    # then
    assert scope == updated_scope
    assert expected_result == result
  end

end
