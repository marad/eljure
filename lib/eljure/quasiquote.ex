defmodule Eljure.Quasiquote do
  import Eljure.Types

  def quasiquote ast do
    case is_pair?(ast) do
      true ->
        case ast do
          {:list, [{:symbol, "unquote", _}, ast | _], _} -> ast
          {:list, [{:list, [{:symbol, "splice-unquote", _}, to_unquote], _} | tail], _} ->
            list([symbol("concat"), to_unquote, quasiquote(list(tail))])
          {:list, [head | tail], _} ->
            list([symbol("cons"), quasiquote(head), quasiquote(list(tail))])
        end
      false ->
        list [ symbol("quote") , ast ]
    end
  end

  def is_pair? {:list, [_head | _args], _} do
    true
  end

  def is_pair? _ do
    false
  end
end
