defmodule Eljure.Quasiquote do
  import Eljure.Types

  def quasiquote ast do
    case is_pair?(ast) do
      true ->
        case ast do
          {:list, [{:symbol, "unquote"}, ast | _]} -> ast
          {:list, [{:list, [{:symbol, "splice-unquote"}, to_unquote]} | tail]} ->
            list([symbol("concat"), to_unquote, quasiquote(list(tail))])
          {:list, [head | tail]} ->
            list([symbol("cons"), quasiquote(head), quasiquote(list(tail))])
        end
      false ->
        list [ symbol("quote") , ast ]
    end
  end

  def is_pair? {:list, [_head | _args]} do
    true
  end

  def is_pair? _ do
    false
  end
end
