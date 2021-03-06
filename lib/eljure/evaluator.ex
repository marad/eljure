defmodule Eljure.Evaluator do
  import Kernel, except: [apply: 2]
  alias Eljure.Scope
  alias Eljure.Error.ArityError
  alias Eljure.Error.EvalError
  import Eljure.Types
  import Eljure.Printer
  import Eljure.Function

  def eval list([], _) = ast, scope do
    {ast, scope}
  end

  def eval list([symbol("def", _), symbol(s, _)=symbol, value], _), scope do
    {evaledValue, _} = eval value, scope
    {symbol, Scope.put(scope, s, evaledValue)}
  end

  def eval list([symbol("fn", _), vector(args, _) | body], _), scope do
    {function(&(invoke_fn args, body, scope, &1), nil), scope}
  end

  def eval list([symbol("let", _), vector(args, _) | body], _), scope do
    let_scope = Enum.chunk(args, 2)
              |> destructure
              |> bind_params(Scope.child(scope), true)
    result = elem(List.last(body |> Enum.map(&(eval &1, let_scope))), 0)
    {result, scope}
  end

  def eval list([symbol("do", _) | body], _), scope do
    Enum.reduce(body, {nil, scope}, fn form, {_, sc} ->
      eval form, sc
    end)
  end

  def eval list([symbol("if", _) | args], _) = form, scope do
    case args do
      [cond_form, true_form, false_form] ->
        case eval(cond_form, scope) do
          {bool(false, _), _} -> eval(false_form, scope)
          {nil, _} -> eval(false_form, scope)
          _ -> eval(true_form, scope)
        end
      _ -> raise EvalError, message: "Invalid expression: #{show form}."
    end
  end

  def eval list([symbol("quote", _) | args], _) = whole, scope do
    case args do
      [form] -> {form, scope}
      _ -> raise ArityError, { "exactly one", show(whole) }
    end
  end

  def eval list([symbol("quasiquote", _) | args], _) = whole, scope do
    case args do
      [form] -> eval Eljure.Quasiquote.quasiquote(form), scope
      #[form] -> { Eljure.Quasiquote.quasiquote(form), scope }
      _ -> raise ArityError, { "exactly one", show(whole) }
    end
  end

  def eval list([symbol("defmacro", _), symbol(name, _), vector(args, _) | body], _), scope do
    m = macro(&(invoke_fn args, body, scope, &1), nil)
    {m, Scope.put(scope, name, m)}
  end

  def eval list([symbol("macroexpand-1", _), list([symbol("quote", _), form], _)], _), scope do
    case form do
      list([macro_name | macro_args], _) ->
        {macro_fn, _} = eval macro_name, scope
        case macro_fn do
          macro(_, _) -> { apply(macro_fn, macro_args), scope }
          _ -> { form, scope }
        end
        _ -> { form, scope }
    end
  end

  def eval list([symbol("macroexpand-1", _) | _], _), scope do
    raise ArityError, "Expected exactly one quoted argument"
  end

  def eval list([symbol(".", _), symbol(func_name, _) | arg_list], _), scope do
    args = arg_list
           |> Enum.map(&(eval(&1, scope)))
           |> Enum.map(&(elem(&1, 0)))
           |> Enum.map(&ast_to_native/1)

   result = invoke_native(func_name, args)

   {native_to_ast(result), scope}
  end

  def eval list([symbol("eval", _) | args], _), scope do
    case args do
      [ast] ->
        {evaled_ast, _} = eval(ast, scope)
        eval(evaled_ast, scope)
      _ ->
        raise ArityError, 1
    end
  end

  def eval list(ast, _), scope do
    fname = List.first(ast)
    args_ast = List.delete_at(ast, 0)

    {f, _} = eval(fname, scope)

    case f do
      macro(_, _) ->
        macro_args = List.delete_at(ast, 0)
        expr = apply(f, macro_args)
        eval(expr, scope)

      _ ->
        { args, _ } = eval_ast(list(args_ast, nil), scope)
        { apply(f, args), scope }
    end
  end

  def eval(ast, scope) do
    eval_ast(ast, scope)
  end

  def eval_ast(symbol(s, _), scope) do
    {Scope.get(scope, s), scope}
  end

  def eval_ast(list(l, _), scope) do
    { Enum.map(l, &(elem(eval(&1, scope), 0))), scope}
  end

  def eval_ast(vector(v, meta), scope) do
    { vector(Enum.map(v, &(elem(eval(&1, scope), 0))), meta), scope}
  end

  def eval_ast(map(m, meta), scope) do
    evaled = Enum.reduce(m, %{}, fn {k, v}, r ->
      Map.put(r, k, elem(eval(v,scope), 0))
    end)
    { map(evaled, meta), scope }
  end

  def eval_ast(ast, scope) do
    {ast, scope}
  end

  defp invoke_native code do
    {result, _} = Code.eval_string code
    native_to_ast(result)
  end

  defp invoke_native func, args do
    func_path = String.split(func, ".")
    module_path = List.delete_at(func_path, -1)
    func_name = List.last(func_path)

    Kernel.apply(Module.concat(module_path), String.to_atom(func_name), args)
  end

end
