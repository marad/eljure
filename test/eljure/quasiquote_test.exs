defmodule EljureTest.Quasiquote do
  use ExUnit.Case
  doctest Eljure.Quasiquote
  import Eljure.Quasiquote
  import Eljure.Types
  alias Eljure.Reader

  test "is_pair? function" do
    assert false == is_pair? list([], nil)
    assert true  == is_pair? list([int(1, nil)], nil)
    assert true  == is_pair? list([int(2, nil), int(3, nil)], nil)
  end

  test "quasiquoting simple ast" do
    ast = int(5, nil)
    assert list([symbol("quote", nil), ast], nil) == quasiquote ast
  end

  test "quasiquoting unquoted ast" do
    ast = Reader.read "(unquote (f 5))"
    expected = Reader.read "(f 5)"
    assert expected == quasiquote ast
  end

  test "quasiquoted unquote-spliced ast" do
    ast = Reader.read "((splice-unquote (1 2)) (splice-unquote (3)))"
    expected = Reader.read "(concat (1 2) (concat (3) '()))"
    assert expected == quasiquote ast
  end

  test "quasiquoted oridinary list" do
    ast = Reader.read "(1 2 3)"
    expected = Reader.read "(cons '1 (cons '2 (cons '3 '())))"
    assert expected == quasiquote ast
  end
end
