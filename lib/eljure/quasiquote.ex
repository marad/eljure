defmodule Eljure.Quasiquote do
  import Eljure.Types

  def quasiquote ast do
    case is_pair?(ast) do
      true ->
        case ast do
          {:list, [{:symbol, "unquote", _}, ast | _], _} -> ast
          {:list, [{:list, [{:symbol, "splice-unquote", _}, to_unquote], _} | tail], _} ->
            list([symbol("concat", nil), to_unquote, quasiquote(list(tail, nil))], nil)
          {:list, [head | tail], _} ->
            list([symbol("cons", nil), quasiquote(head), quasiquote(list(tail, nil))], nil)
        end
      false ->
        list [ symbol("quote", nil) , ast ], nil
    end
  end

  def is_pair? {:list, [_head | _args], _} do
    true
  end

  def is_pair? _ do
    false
  end
end
