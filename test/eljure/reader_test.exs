defmodule EljureTest.Reader do
  use ExUnit.Case
  doctest Eljure.Reader
  import Eljure.Reader
  import Eljure.Types
  alias Eljure.Error.SyntaxError

  test "should read integers" do
    assert int(42, nil) == read("42")
  end

  test "should read floats" do
    assert float(2.3, nil) == read("2.3")
  end

  test "should read keywords" do
    assert keyword("kw", nil) == read(":kw")
  end

  test "should read strings" do
    assert string("test string", nil) == read("\"test string\"")
  end

  test "should read nil" do
    assert nil == read("nil")
  end

  test "should read true and false" do
    assert bool(true, nil) == read("true")
    assert bool(false, nil) == read("false")
  end

  test "should read symbols" do
    assert symbol("my-symbol", nil) == read("my-symbol")
  end

  test "should read lists/vectors/maps" do
    assert list([symbol("+", nil), int(1, nil), int(2, nil)], nil) == read("(+ 1 2)")
    assert vector([int(1, nil), int(2, nil), int(3, nil)], nil) == read("[1 2 3]")
    assert map(%{keyword("key", nil) => string("value", nil)}, nil) == read("{:key \"value\"}")
  end

  test "should read quote" do
    assert list([symbol("quote", nil), symbol("a", nil)], nil) == read("'a")
  end

  test "should read '`' as quasiquote" do
    assert read("(quasiquote a)") == read("`a")
  end

  test "should read '~'  as unquote" do
    assert read("(unquote a)") == read("~a")
  end

  test "should read '~@' as splice-unquote" do
    assert read("(splice-unquote (1 2 3))") == read("~@(1 2 3)")
  end

  test "syntax error on unexpected end of list/vector/map" do
    assert_raise SyntaxError, fn -> read ")" end
    assert_raise SyntaxError, fn -> read "]" end
    assert_raise SyntaxError, fn -> read "}" end
  end

  test "syntax error when missing end of list/vector/map" do
    assert_raise SyntaxError, fn -> read "(" end
    assert_raise SyntaxError, fn -> read "[" end
    assert_raise SyntaxError, fn -> read "{" end
  end

  test "reading empty string" do
    assert nil == read ""
  end
end
