defmodule EljureTest.Core do
  use ExUnit.Case
  doctest Eljure.Core
  import Eljure.Core
  import Eljure.Types

  test "cons should add value at the beggining of a list" do
    args = [ int(5, nil), list([int(10, nil)], nil)]
    assert list([int(5, nil), int(10, nil)], nil) == cons args
  end

  test "cons should add value at the beggining of a vector" do
    args = [ int(5, nil), vector([int(10, nil), int(12, nil)], nil) ]
    assert vector [int(5, nil), int(10, nil), int(12, nil)], nil == cons args
  end

  test "cons should add to empty list/vector" do
    assert list [int(5, nil)], nil == cons [int(5, nil), list([], nil)]
    assert vector [int(5, nil)], nil == cons [int(5, nil), vector([], nil)]
  end

  test "cons adding vector" do
    v = vector([], nil)
    assert list([v, 1], nil) == cons [v, list([1], nil)]
    assert vector([v, 1], nil) == cons [v, vector([1], nil)]
    #assert true == false
  end

  test "concat should concatenate lists" do
    assert list([], nil) == concat([ list([], nil), list([], nil) ])
    assert list([int(5, nil)], nil) == concat([ list([int(5, nil)], nil), list([], nil) ])
    assert list([int(6, nil)], nil) == concat([ list([], nil), list([int(6, nil)], nil) ])
    assert list([int(5, nil), int(6, nil)], nil) == concat([ list([int(5, nil)], nil), list([int(6, nil)], nil) ])
    assert list([int(5, nil), int(6, nil), int(7, nil)], nil) == concat([ list([int(5, nil)], nil), list([int(6, nil)], nil), list([int(7, nil)], nil) ])
  end

  test "list should return list from its arguments" do
    assert list([int(1, nil), int(2, nil)], nil) == list_func([ int(1, nil), int(2, nil) ])
  end

  test "vector should return vector from its arguments" do
    assert vector([int(1, nil), int(2, nil)], nil) == vector_func([ int(1, nil), int(2, nil) ])
  end

  test "with-meta overrides metadata" do
    assert int(1, %{foo: "bar"}) == with_meta [int(1, %{old: "meta"}), %{foo: "bar"}]
  end

  test "meta returns metadata" do
    m = string("hello", nil)
    v = int(1, m)

    assert m == get_meta [v]
  end
end
