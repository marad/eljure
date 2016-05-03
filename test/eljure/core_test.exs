defmodule EljureTest.Core do
  use ExUnit.Case
  doctest Eljure.Core
  import Eljure.Core
  import Eljure.Types

  test "cons should add value at the beggining of a list" do
    args = [ int(5), list([int(10)])]
    assert list [int(5), int(10)] == cons args
  end

  test "cons should add value at the beggining of a vector" do
    args = [ int(5), vector([int(10), int(12)]) ]
    assert vector [int(5), int(10), int(12)] == cons args
  end

  test "cons should add to empty list/vector" do
    assert list [int(5)] == cons [int(5), list([])]
    assert vector [int(5)] == cons [int(5), vector([])]
  end

  test "cons adding vector" do
    v = vector([])
    assert list([v, 1]) == cons [v, list([1])]
    assert vector([v, 1]) == cons [v, vector([1])]
    #assert true == false
  end

  test "concat should concatenate lists" do
    assert list([]) == concat([ list([]), list([]) ])
    assert list([int(5)]) == concat([ list([int(5)]), list([]) ])
    assert list([int(6)]) == concat([ list([]), list([int(6)]) ])
    assert list([int(5), int(6)]) == concat([ list([int(5)]), list([int(6)]) ])
    assert list([int(5), int(6), int(7)]) == concat([ list([int(5)]), list([int(6)]), list([int(7)]) ])
  end

  test "list should return list from its arguments" do
    assert list([int(1), int(2)]) == list_func([ int(1), int(2) ])
  end

  test "vector should return vector from its arguments" do
    assert vector([int(1), int(2)]) == vector_func([ int(1), int(2) ])
  end

end
