defmodule EljureTest.Reader do
  use ExUnit.Case
  doctest Eljure.Reader
  import Eljure.Reader
  import Eljure.Types

  test "should read integers" do
    assert int(42) == read("42")
  end

  test "should read keywords" do
    assert keyword("kw") == read(":kw")
  end

  test "should read strings" do
    assert string("test string") == read("\"test string\"")
  end

  test "should read nil" do
    assert nil == read("nil")
  end

  test "should read true and false" do
    assert bool(true) == read("true")
    assert bool(false) == read("false")
  end

  test "should read symbols" do
    assert symbol("my-symbol") == read("my-symbol")
  end

  test "should read lists/vectors/maps" do
    assert list([symbol("+"), int(1), int(2)]) == read("(+ 1 2)")
    assert vector([int(1), int(2), int(3)]) == read("[1 2 3]")
    assert map(%{keyword("key") => string("value")}) == read("{:key \"value\"}")
  end

  test "should read quote" do
    assert list([symbol("quote"), symbol("a")]) == read("'a")
  end

  test "should read '`' as quasiquote" do
    assert read("(quasiquote a)") == read("`a")
  end

  test "should read '~'  as unquote" do
    assert read("(unquote a)") == read("~a")
  end

  test "should read '~@' as splice-unquote" do
    assert read("(splice-unquote (1 2 3)") == read("~@(1 2 3)")
  end

end
