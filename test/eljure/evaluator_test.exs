defmodule EljureTest.Evaluator do
  use ExUnit.Case
  doctest Eljure.Evaluator
  import Eljure.Evaluator
  import Eljure.Types
  alias Eljure.Scope
  alias Eljure.Reader
  alias Eljure.Error.ArityError
  alias Eljure.Error.EvalError
  alias Eljure.Error.FunctionApplicationError

  defp sumFunc args do
    int( Enum.reduce(Enum.map(args, &value/1), &+/2), nil)
  end

  test "should eval symbol to it's value" do
    scope = Scope.put(Scope.new, "number", int(42, nil))
    assert {int(42, nil), scope} == eval symbol("number", nil), scope
  end

  test "should eval symbol from parent scope" do
    scope = Scope.put(Scope.new, "number", int(42, nil))
    child_scope = Scope.child(scope)
    assert {int(42, nil), child_scope} == eval symbol("number", nil), child_scope
  end

  test "should raise error when symbol is not found" do
    scope = Scope.new
    assert_raise RuntimeError, "Undefined symbol: \"sym\"", fn ->
      eval(symbol("sym", nil), scope)
    end
  end

  test "should evaluate atoms to themselves" do
    scope = Scope.new
    assert {int(42, nil), scope}   == eval int(42, nil), scope
    assert {string("s", nil), scope}   == eval string("s", nil), scope
    assert {map(%{a: 2}, nil), scope}  == eval map(%{a: 2}, nil), scope
    assert {keyword("kw", nil), scope} == eval keyword("kw", nil), scope
    assert {vector([1, 2], nil), scope} == eval vector([1, 2], nil), scope
  end

  test "should eval lists as functions" do
    # given
    scope = Scope.new(%{
      "+" => function(&sumFunc/1, nil),
      "a" => int(1, nil),
      "b" => int(2, nil)
    })
    expr = Reader.read "(+ a b)"

    # expect
   assert {int(3, nil), scope} == eval expr, scope
   assert_raise FunctionApplicationError, fn -> eval Reader.read("(a)"), scope end
  end

  test "should evaluate vector tokens" do
    scope = Scope.new %{
      "a" => int(3, nil)
    }
    expr = Reader.read "[1 2 a]"
    assert {vector([int(1, nil), int(2, nil), int(3, nil)], nil), scope} == eval expr, scope
  end

  test "should evaluate map tokens" do
    scope = Scope.new %{
      "a" => int(3, nil)
    }
    expr = Reader.read "{:a a}"
    assert {map(%{keyword("a", nil) => int(3, nil)}, nil), scope} == eval expr, scope
  end

  test "'def' should define variables" do
    scope = Scope.new
    expr = Reader.read "(def sym 5)"
    eval expr, scope
    assert int(5, nil) == Scope.get(scope, "sym")
  end

  test "'def' should eval value to be set" do
    # given
    scope = Scope.put(Scope.new, "+", function(&sumFunc/1, nil))
    expr = Reader.read "(def sym (+ 1 2))"

    # when
    {result, updated_scope} = eval expr, scope

    #then
    assert symbol("sym", nil) == result
    assert scope == updated_scope
    assert int(3, nil) == Scope.get(updated_scope, "sym")
  end

  test "'fn' should create a function" do
    # given
    scope = Scope.new
    expr = Reader.read "((fn [a] a) 5)"

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert scope == updated_scope
    assert int(5, nil) == result
  end

  test "'&' in fn argument list" do
    scope = Scope.new
    expr = Reader.read "((fn [a & b] [a b]) 1 2 3 4)"

    {result, updated_scope} = eval expr, scope

    assert scope == updated_scope
    assert vector([int(1, nil), vector([int(2, nil), int(3, nil), int(4, nil)], nil)], nil) == result
  end

  test "'let' should create it's scope and bind arguments sequentially" do
    # given
    scope = Scope.put(Scope.new, "+", function(&sumFunc/1, nil))
    expr = Reader.read "(let [a 5 b (+ a 1)] b)"

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert scope == updated_scope
    assert int(6, nil) == result

  end

  test "'do' should eval list and return last value" do
    # given
    scope = Scope.new
    expr = Reader.read "(do (def a 5) a)"

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert int(5, nil) == Scope.get(updated_scope, "a")
    assert int(5, nil) == result
  end

  test "'if' special form" do
    scope = Scope.new
            |> Scope.put("t", int(1, nil))
            |> Scope.put("f", int(0, nil))
    assert {int(1, nil), scope} == eval(Reader.read("(if true t f)"), scope)
    assert {int(0, nil), scope} == eval(Reader.read("(if false t f)"), scope)
    assert {int(0, nil), scope} == eval(Reader.read("(if nil t f)"), scope)
  end

  test "if throws error when arguments are missing" do
    scope = Scope.new
    assert_raise EvalError, fn -> eval(Reader.read("(if true :t)"), scope) end
    assert_raise EvalError, fn -> eval(Reader.read("(if true)"), scope) end
    assert_raise EvalError, fn -> eval(Reader.read("(if)"), scope) end
  end

  test "'eval' should evaluate ast" do
    scope = Scope.new %{
      "+" => function(&sumFunc/1, nil),
      "a" => int(5, nil)
    }
    expr = Reader.read "(eval (+ a 1))"
    assert  {int(6, nil), scope} == eval(expr, scope)
  end

  test "'eval' should evaluate ast from symbol" do
    scope = Scope.new %{
      "+" => function(&sumFunc/1, nil),
      "a" => int(5, nil),
      "ast" => Reader.read "(+ a 1)"
    }
    expr = Reader.read "(eval ast)"
    assert {int(6, nil), scope} == eval(expr, scope)
  end

  test "'eval' expects exactlye one argument" do
    scope = Scope.new
    assert_raise ArityError, fn -> eval Reader.read("(eval)"), scope end
    assert_raise ArityError, fn -> eval Reader.read("(eval :a :b)"), scope end
  end

  test "'quote' should return unevaluated first form" do
    scope = Scope.new
    expr = Reader.read "(quote (1 2))"
    assert { list([int(1, nil), int(2, nil)], nil), scope } == eval(expr, scope)
  end

  test "'quote' expects exactly one argument" do
    scope = Scope.new
    assert_raise ArityError, fn -> eval(Reader.read("(quote)"), scope) end
    assert_raise ArityError, fn -> eval(Reader.read("(quote :a :b)"), scope) end
  end

  test "'quasiquote' should return unevaluated first form" do
    scope = Eljure.Core.create_root_scope
    assert { list([int(1, nil)], nil), scope } == eval(Reader.read("(quasiquote (1))"), scope)
    assert {int(2, nil), scope } == eval(Reader.read("(quasiquote (unquote (+ 1 1)))"), scope)
  end

  test "'quasiquote' expects exactly one argument" do
    scope = Scope.new
    assert_raise ArityError, fn -> eval(Reader.read("(quasiquote)"), scope) end
    assert_raise ArityError, fn -> eval(Reader.read("(quasiquote :a :b)"), scope) end
  end

  test "complex quasiquote expression" do
    scope = Eljure.Core.create_root_scope
            |> Scope.put("a", int(2, nil))
            |> Scope.put("b", vector([int(3, nil), int(4, nil)], nil))
    expr = Reader.read "(quasiquote (1 (unquote a) (splice-unquote b)))"
    expr2 = Reader.read "`(1 ~a ~@b)"
    expected = Reader.read "(1 2 3 4)"
    assert {expected, scope} == eval expr, scope
    assert {expected, scope} == eval expr2, scope
  end

  test "'apply' should apply function to arguments" do
    scope = Scope.new %{
      "+" => function(&sumFunc/1, nil),
    }

    #1
    with_arg_vector = Reader.read "(apply + 1 2 [3 4])"
    assert { int(10, nil), scope } == eval(with_arg_vector, scope)

    #2
    without_arg_vector = Reader.read "(apply + 1 2 3)"
    assert { int(6, nil), scope } == eval(without_arg_vector, scope)
  end

  test "calling native elixir functions" do
    # given
    scope = Scope.new
    expr = Reader.read "(. String.reverse \"eljure\")"

    # when
    {result, updated_scope} = eval expr, scope

    # then
    assert scope == updated_scope
    assert string("erujle", nil) == result
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
    scope = Eljure.Core.create_root_scope
    macro_expr = Reader.read "(defmacro test [name] `(def ~name (fn [x] x)))"
    expand_expr = Reader.read "(macroexpand-1 '(test identity))"
    expected_result = Reader.read "(def identity (fn [x] x))"

    # when
    eval macro_expr, scope
    {result, updated_scope} = eval expand_expr, scope

    # then
    assert scope == updated_scope
    assert expected_result == result
  end

  test "expanding not-macros should just return them" do
    scope = Scope.new
    expr = Reader.read "(macroexpand-1 'a)"
    assert {symbol("a", nil), scope} == eval expr, scope
  end

  test "calling macroexpand-1 without any or with more than one arguments raises an error" do
    scope = Scope.new
    assert_raise ArityError, fn -> eval Reader.read("(macroexpand-1)"), scope end
    assert_raise ArityError, fn -> eval Reader.read("(macroexpand-1 :a :b)"), scope end
  end

  test "running a macro" do
    # given
    scope = Eljure.Core.create_root_scope
    macro_expr = Reader.read "(defmacro test [name] `(def ~name (fn [x] x)))"
    test_expr = Reader.read "(do (test id-test) (id-test 5))"

    # when
    eval macro_expr, scope
    {result, updated_scope} = eval test_expr, scope

    # then
    assert scope == updated_scope
    assert int(5, nil) == result

  end

end
