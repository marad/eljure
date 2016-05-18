defmodule EljureTest.Core do
  use ExUnit.Case
  doctest Eljure.Core
  import Eljure.Core
  import Eljure.Types
  alias Eljure.Error.ArityError

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

  test "basic type checks" do
    assert bool(true, nil) == nil? [nil]
    assert bool(false, nil) == nil? [int(1, nil)]

    assert bool(true, nil) == string? [string("test", nil)]
    assert bool(false, nil) == string? [int(1, nil)]

    assert bool(true, nil) == symbol? [symbol("s", nil)]
    assert bool(false, nil) == symbol? [int(1, nil)]

    assert bool(true, nil) == integer? [int(1, nil)]
    assert bool(false, nil) == integer? [string("s", nil)]

    assert bool(true, nil) == float? [float(1, nil)]
    assert bool(false, nil) == float? [int(1, nil)]

    assert bool(true, nil) == number? [float(1, nil)]
    assert bool(true, nil) == number? [int(1, nil)]
    assert bool(false, nil) == number? [symbol("s", nil)]

    assert bool(true, nil) == map? [map(%{a: 1}, nil)]
    assert bool(false, nil) == map? [string("s", nil)]

    assert bool(true, nil) == list? [list([int(1, nil), int(2, nil)], nil)]
    assert bool(false, nil) == list? [int(2, nil)]

    assert bool(true, nil) == vector? [vector([int(1, nil), int(2, nil)], nil)]
    assert bool(false, nil) == vector? [int(2, nil)]

    assert bool(true, nil) == macro? [macro(&(&1), nil)]
    assert bool(false, nil) == macro? [function(&(&1), nil)]
    assert bool(false, nil) == macro? [int(1, nil)]

    assert bool(true, nil) == function? [function(&(&1), nil)]
    assert bool(false, nil) == function? [macro(&(&1), nil)]
    assert bool(false, nil) == function? [int(1, nil)]
  end

  test "equals" do
    {one, two} = {int(1,nil), int(2,nil)}
    assert bool(true,nil) == eq [one, one, one]
    assert bool(false,nil) == eq [one, two]
    assert bool(false,nil) == eq [one, two, one]
    assert bool(false,nil) == eq [one, one, two]
  end

  test "less than" do
    assert bool(true,nil) == lt [int(1, nil), int(2,nil), int(3, nil)]
    assert bool(false,nil) == lt [int(3, nil), int(2,nil), int(1, nil)]
    assert bool(false,nil) == lt [int(1, nil), int(2,nil), int(0, nil)]
    assert bool(false,nil) == lt [int(1,nil), int(1, nil)]
  end

  test "greater than" do
    assert bool(true,nil) == gt [int(3, nil), int(2,nil), int(1, nil)]
    assert bool(false,nil) == gt [int(1, nil), int(2,nil), int(3, nil)]
    assert bool(false,nil) == gt [int(3, nil), int(2,nil), int(4, nil)]
  end

  test "less than or equal" do
    {one, two, three} = {int(1,nil), int(2,nil), int(3,nil)}
    {t, f} = { bool(true, nil), bool(false, nil) }

    assert t == lte [one, two, three]
    assert t == lte [one, one]
    assert t == lte [one, two]
    assert f == lte [one, three, two]
    assert f == lte [three, two, one]
    assert f == lte [two, one, one]
  end

  test "greater than or equal" do
    {one, two, three} = {int(1,nil), int(2,nil), int(3,nil)}
    {t, f} = { bool(true, nil), bool(false, nil) }

    assert t == gte [three, two, one]
    assert t == gte [one, one]
    assert t == gte [two, one]
    assert f == gte [one, three, two]
    assert f == gte [one, two, three]
    assert f == gte [one, one, two]
  end

  test "'apply' should apply function to arguments" do
    f = function(&plus/1,nil)

    #1
    args = [int(1,nil), int(2,nil), vector([int(3,nil), int(4,nil)],nil)]
    assert int(10, nil) == apply_func [f] ++ args

    #2
    args = [int(1,nil), int(2,nil), int(3,nil)]
    assert int(6,nil) == apply_func [f] ++ args
  end

  test "'rest' function returns tail" do
    vec = vector [int(1,nil), int(2,nil), int(3,nil)], nil
    empty_vector = vector [], nil

    assert vector [int(2,nil), int(3,nil)], nil == rest [vec]
    assert empty_vector == rest [vector([int(1,nil)], nil)]
  end

  test "'rest' returns empty vector" do
    empty_vector = vector [], nil
    assert empty_vector == rest [empty_vector]
  end

  test "'rest' throws exception when no arguments are passed" do
    assert_raise ArityError, fn ->
      rest []
    end
  end

  test "'rest' throws exception when too much args are passed" do
    empty_vector = vector [], nil
    assert_raise ArityError, fn ->
      rest [empty_vector, empty_vector]
    end
  end

  test "'count' function" do
    l = list([int(1,nil), int(2,nil)],nil)
    v = vector([int(1,nil), int(2,nil)],nil)

    assert int(2, nil) == count [l]
    assert int(2, nil) == count [v]
    assert int(0, nil) == count [list([], nil)]
    assert int(0, nil) == count [vector([], nil)]
    assert int(0, nil) == count [nil]

    assert_raise ArityError, fn ->
      count [l, v]
    end

    assert_raise ArityError, fn ->
      count []
    end
  end

end
