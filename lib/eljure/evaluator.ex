defmodule Eljure.Evaluator do
  import Kernel, except: [apply: 2]
  alias Eljure.Scope
  import Eljure.Types
  import Eljure.Printer
  import Eljure.Function

  def eval list([]) = ast, scope do
    {ast, scope}
  end

  def eval list([symbol("def"), symbol(s)=symbol, value]), scope do
    {evaledValue, _} = eval value, scope
    {symbol, Scope.put(scope, s, evaledValue)}
  end

  def eval list([symbol("fn"), vector(args) | body]), scope do
    {function(&(invoke_fn args, body, scope, &1)), scope}
  end

  def eval list([symbol("let"), vector(args) | body]), scope do
    let_scope = Enum.chunk(args, 2)
              |> destructure
              |> bind_params(Scope.child(scope), true)
    result = elem(List.last(body |> Enum.map(&(eval &1, let_scope))), 0)
    {result, scope}
  end

  def eval list([symbol("do") | body]), scope do
    Enum.reduce(body, {nil, scope}, fn form, {_, sc} ->
      eval form, sc
    end)
  end

  def eval list([symbol("if") | args]) = form, scope do
    case args do
      [cond_form, true_form, false_form] ->
        case eval(cond_form, scope) do
          {bool(false), _} -> eval(false_form, scope)
          {nil, _} -> eval(false_form, scope)
          _ -> eval(true_form, scope)
        end
      _ -> raise Eljure.Error.EvalError, "Invalid expression: #{show form}."
    end
  end

  def eval list([symbol("quote") | args]) = whole, scope do
    case args do
      [form] -> {form, scope}
      _ -> raise Eljure.Error.ArityError, "Expected exactly one argument in #{show whole}."
    end
  end

  def eval list([symbol("quasiquote") | args]) = whole, scope do
    case args do
      [form] -> eval Eljure.Quasiquote.quasiquote(form), scope
      #[form] -> { Eljure.Quasiquote.quasiquote(form), scope }
      _ -> raise Eljure.Error.ArityError, "Expected exactly one argument in #{show whole}."
    end
  end

  def eval list([symbol("apply"), symbol(_) = func_symbol | arg_list]), scope do
    {f, _} = eval(func_symbol, scope)
    args = arg_list
           |> Enum.map(&(eval(&1, scope)))
           |> Enum.map(&(elem(&1, 0)))

    case List.last(args) do
      vector(arg_vec) ->
        first_args = List.delete_at(args, -1)
        { apply(f, first_args ++ arg_vec), scope }

      _ ->
        { apply(f, args), scope }
    end

  end

  def eval list([symbol("defmacro"), symbol(name), vector(args) | body]), scope do
    m = macro(&(invoke_fn args, body, scope, &1))
    {m, Scope.put(scope, name, m)}
  end

  def eval list([symbol("macroexpand-1"), list([symbol("quote"), form])]), scope do
    { first, _ } = eval List.first(value(form)), scope
    case first do
      macro(_) ->
        macro_args = List.delete_at(value(form), 0)
        { apply(first, macro_args), scope }
      _ -> eval form, scope
    end
  end

  def eval list([symbol("."), symbol(func_name) | arg_list]), scope do
    args = arg_list
           |> Enum.map(&(eval(&1, scope)))
           |> Enum.map(&(elem(&1, 0)))
           |> Enum.map(&show/1)
           |> Enum.join(",")

    {invoke_native("#{func_name} #{args}"), scope}
  end

  #def eval list([symbol("elixir-eval"), string(code)]), scope do
  #  {invoke_native(code), scope}
  #end

  def eval list([symbol("eval") | args]), scope do
    case args do
      [ast] ->
        {evaled_ast, _} = eval(ast, scope)
        eval(evaled_ast, scope)
      _ -> "Arity exception! Expected one argument."
    end
  end

  def eval list(ast), scope do
    fname = List.first(ast)
    args_ast = List.delete_at(ast, 0)

    {f, _} = eval(fname, scope)

    case f do
      function(_) ->
        { args, _ } = eval_ast(list(args_ast), scope)
        { apply(f, args), scope }

      macro(_) ->
        macro_args = List.delete_at(ast, 0)
        expr = apply(f, macro_args)
        eval(expr, scope)
    end
  end

  def eval(ast, scope) do
    eval_ast(ast, scope)
  end

  def eval_ast(symbol(s), scope) do
    {Scope.get(scope, s), scope}
  end

  def eval_ast(list(l), scope) do
    { Enum.map(l, &(elem(eval(&1, scope), 0))), scope}
  end

  def eval_ast(vector(v), scope) do
    { vector(Enum.map(v, &(elem(eval(&1, scope), 0)))), scope}
  end

  def eval_ast(map(m), scope) do
    evaled = Enum.reduce(m, %{}, fn {k, v}, r ->
      Map.put(r, k, elem(eval(v,scope), 0))
    end)
    { map(evaled), scope }
  end

  def eval_ast(ast, scope) do
    {ast, scope}
  end

  defp invoke_native code do
    {result, _} = Code.eval_string code
    native_to_ast(result)
  end

end
