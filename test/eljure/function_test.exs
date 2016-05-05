defmodule EljureTest.Function do
  use ExUnit.Case
  doctest Eljure.Function
  import Eljure.Function
  import Eljure.Types
  alias Eljure.Scope

  test "preparing bindings for function" do
    names = [symbol("a"), symbol("b")]
    values = [int(1), int(2)]

    result = prepare_arg_bindings(names, values)

    assert [ [ symbol("a"), int(1) ],
             [ symbol("b"), int(2) ] ] == result
  end

  test "vararg bindings" do
    names = ["a", "&", "b"] |> Enum.map(&symbol/1)
    values = [1, 2, 3] |> Enum.map(&int/1)

    result = prepare_arg_bindings(names, values)

    assert [ [symbol("a"), int(1)],
             [symbol("b"), list([int(2), int(3)])] ] == result
  end

  test "vector destructuring" do
  end

  test "binding params" do
    scope = Scope.new
    bindings = [ [ symbol("i"), int(3) ],
                 [ symbol("s"), string("hello") ] ]

    result = bind_params bindings, scope

    assert int(3) == Scope.get(scope, "i")
    assert string("hello") == Scope.get(scope, "s")
    assert scope == result
  end

end 
