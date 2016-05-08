defmodule EljureTest.Function do
  use ExUnit.Case
  doctest Eljure.Function
  import Kernel, except: [apply: 2]
  import Eljure.Function
  import Eljure.Types
  alias Eljure.Scope
  alias Eljure.Reader
  alias Eljure.Error.ArityError
  alias Eljure.Error.FunctionApplicationError

  test "preparing bindings for function" do
    names = [symbol("a", nil), symbol("b", nil)]
    values = [int(1, nil), int(2, nil)]

    result = prepare_arg_bindings(names, values)

    assert [ [ symbol("a", nil), int(1, nil) ],
             [ symbol("b", nil), int(2, nil) ] ] == result
  end

  test "preparing bindings arity checks (more arguments than expected)" do
    names = [symbol("a", nil)]
    values = [int(1, nil), int(2, nil)]

    assert_raise ArityError, fn ->
      prepare_arg_bindings(names, values)
    end

    assert [ [symbol("a", nil), int(1, nil)] ] == prepare_arg_bindings(names, values, false)
  end

  test "preparing bindings arity checks (less arguments than expected)" do
    names = [symbol("a", nil), symbol("b", nil)]
    values = [int(1, nil)]

    assert_raise ArityError, fn ->
      prepare_arg_bindings(names, values)
    end

    assert [ [symbol("a", nil), int(1, nil)],
             [symbol("b", nil), nil] ] == prepare_arg_bindings(names, values, false)
  end

  test "vararg bindings" do
    names = ["a", "&", "b"] |> Enum.map(&(symbol &1, nil))
    values = [1, 2, 3] |> Enum.map(&(int &1, nil))

    result = prepare_arg_bindings(names, values)

    assert [ [symbol("a", nil), int(1, nil)],
             [symbol("b", nil), vector([int(2, nil), int(3, nil)], nil)] ] == result
  end

  test "destructuring [a b c]" do
    name = Reader.read "[a b c]"
    value = Reader.read "[1 2 3 4]"
    bindings = [ [name, value] ]

    result = destructure bindings

    assert [ [symbol("a", nil), int(1, nil)],
             [symbol("b", nil), int(2, nil)],
             [symbol("c", nil), int(3, nil)] ] == result
  end

  test "destructuring [a & b]" do
    name = Reader.read "[a & b]"
    value = Reader.read "[1 2 3]"
    bindings = [ [name, value] ]

    result = destructure bindings

    assert [ [symbol("a", nil), int(1, nil)],
             [symbol("b", nil), vector([int(2, nil), int(3, nil)], nil)] ] == result
  end

  test "destructuring [a & b :as whole]" do
    name = Reader.read "[a & b :as whole]"
    value = Reader.read "[1 2 3]"
    bindings = [ [name, value] ]

    result = destructure bindings

    assert [ [symbol("a", nil), int(1, nil)],
             [symbol("b", nil), vector([int(2, nil), int(3, nil)], nil)],
             [symbol("whole", nil), value] ] == result
  end

  test "destructuring {a :x b :y}" do
    name = Reader.read "{a :x b :y}"
    value = Reader.read "{:x 1 :y 2}"
    bindings = [ [name, value] ]

    result = destructure bindings

    assert [ [symbol("a", nil), int(1, nil)],
             [symbol("b", nil), int(2, nil)] ] == result
  end

  test "destructuring {a :x b :y :as whole}" do
    name = Reader.read "{a :x b :y :as whole}"
    value = Reader.read "{:x 1 :y 2}"
    bindings = [ [name, value] ]

    result = destructure bindings

    assert [ [symbol("a", nil), int(1, nil)],
             [symbol("b", nil), int(2, nil)],
             [symbol("whole", nil), value] ] == result
  end

  test "destructuring {:keys [a b]}" do
    name = Reader.read "{:keys [a b]}"
    value = Reader.read "{:a 1 :b 2}"
    bindings = [ [name, value] ]

    result = destructure bindings

    assert [ [symbol("a", nil), int(1, nil)],
             [symbol("b", nil), int(2, nil)] ] == result
  end

  test "destructuring {:keys [a b] :as x}" do
    name = Reader.read "{:keys [a b] :as x}"
    value = Reader.read "{:a 1 :b 2}"
    bindings = [ [name, value] ]

    result = destructure bindings

    assert [ [symbol("a", nil), int(1, nil)],
             [symbol("b", nil), int(2, nil)],
             [symbol("x", nil), value] ] == result
  end

  test "destructure with multiple bindings" do
    bindings = [ [ symbol("a", nil), int(3, nil) ],
                 [ Reader.read("[x & y]"), Reader.read("[1 2 3]") ] ]

    result = destructure bindings

    assert [ [ symbol("a", nil), int(3, nil) ],
             [ symbol("x", nil), int(1, nil) ],
             [ symbol("y", nil), vector([int(2, nil), int(3, nil)], nil) ] ] == result 
  end

  test "binding params" do
    scope = Scope.new
    bindings = [ [ symbol("i", nil), float(3.2, nil) ],
                 [ symbol("s", nil), string("hello", nil) ] ]

    result = bind_params bindings, scope

    assert float(3.2, nil) == Scope.get(scope, "i")
    assert string("hello", nil) == Scope.get(scope, "s")
    assert scope == result
  end

  test "applying non-function raises an error" do
    assert_raise FunctionApplicationError, fn ->
      apply(int(1, nil), [])
    end
  end

end
