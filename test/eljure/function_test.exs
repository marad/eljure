defmodule EljureTest.Function do
  use ExUnit.Case
  doctest Eljure.Function
  import Eljure.Function
  import Eljure.Types
  alias Eljure.Scope
  alias Eljure.Reader
  alias Eljure.Error.ArityError

  test "preparing bindings for function" do
    names = [symbol("a", nil), symbol("b", nil)]
    values = [int(1, nil), int(2, nil)]

    result = prepare_arg_bindings(names, values)

    assert [ [ symbol("a", nil), int(1, nil) ],
             [ symbol("b", nil), int(2, nil) ] ] == result
  end

  test "preparing bindings arity checks" do
    names = [symbol("a", nil)]
    values = [int(1, nil), int(2, nil)]

    assert_raise ArityError, fn ->
      prepare_arg_bindings(names, values)
    end

    assert [ [symbol("a", nil), int(1, nil)] ] == prepare_arg_bindings(names, values, false)

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

  test "destructuring {a :x b :y}" do
    name = Reader.read "{a :x b :y}"
    value = Reader.read "{:x 1 :y 2}"
    bindings = [ [name, value] ]

    result = destructure bindings

    assert [ [symbol("a", nil), int(1, nil)],
             [symbol("b", nil), int(2, nil)] ] == result
  end

  test "destructuring {:keys [a b]}" do
    name = Reader.read "{:keys [a b]}"
    value = Reader.read "{:a 1 :b 2}"
    bindings = [ [name, value] ]

    result = destructure bindings

    assert [ [symbol("a", nil), int(1, nil)],
             [symbol("b", nil), int(2, nil)] ] == result
  end

  test "binding params" do
    scope = Scope.new
    bindings = [ [ symbol("i", nil), int(3, nil) ],
                 [ symbol("s", nil), string("hello", nil) ] ]

    result = bind_params bindings, scope

    assert int(3, nil) == Scope.get(scope, "i")
    assert string("hello", nil) == Scope.get(scope, "s")
    assert scope == result
  end

end
