defmodule EljureTest.Reader do
  use ExUnit.Case
  doctest Eljure.Reader
  import Eljure.Reader

  test "should read integers" do
    assert {:integer, 42} == read("42")
  end

  test "should read keywords" do
    assert {:keyword, "kw"} == read(":kw")
  end

  test "should read strings" do
    assert {:string, "test string"} == read("\"test string\"")
  end

  test "should read nil" do
    assert nil == read("nil")
  end

  test "should read true and false" do
    assert {:boolean, true} == read("true")
    assert {:boolean, false} == read("false")
  end

  test "should read symbols" do
    assert {:symbol, "my-symbol"} == read("my-symbol")
  end

  test "should read lists/vectors/maps" do
    assert {:list, [{:symbol, "+"}, {:integer, 1}, {:integer, 2}]} == read("(+ 1 2)")
    assert {:vector, [{:integer, 1}, {:integer, 2}, {:integer, 3}]} == read("[1 2 3]")
    assert {:map, %{{:keyword, "key"} => {:string, "value"}}} == read("{:key \"value\"}")
  end

end
