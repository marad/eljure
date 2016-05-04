defmodule Eljure.Evaluator do
  import Kernel, except: [apply: 2]
  alias Eljure.Scope
  import Eljure.Types
  import Eljure.Printer

  def eval({:list, [], _} = ast, scope) do
    {ast, scope}
  end

  def eval({:list, [{:symbol, "def", _}, {:symbol, s, _}=symbol, value], _}, scope) do
    {evaledValue, _} = eval value, scope
    {symbol, Scope.put(scope, s, evaledValue)}
  end

  def eval({:list, [{:symbol, "fn", _}, {:vector, args, _} | body], _}, scope) do
    {function(&(invoke_fn args, body, scope, &1)), scope}
  end

  def eval({:list, [{:symbol, "let", _}, {:vector, args, _} | body], _}, scope) do
    let_scope = Enum.reduce(Enum.chunk(args, 2), Scope.child(scope), fn [{:symbol, sym, _}, val], sc ->
      Scope.put(sc, sym, elem(eval(val, sc), 0))
    end)
    result = elem(List.last(body |> Enum.map(&(eval &1, let_scope))), 0)
    {result, scope}
  end

  def eval({:list, [{:symbol, "do", _} | body], _}, scope) do
    Enum.reduce(body, {nil, scope}, fn form, {_, sc} ->
      eval form, sc
    end)
  end

  def eval({:list, [{:symbol, "if", _} | args], _} = form, scope) do
    case args do
      [cond_form, true_form, false_form] ->
        case eval(cond_form, scope) do
          {{:boolean, false, _}, _} -> eval(false_form, scope)
          {nil, _} -> eval(false_form, scope)
          _ -> eval(true_form, scope)
        end
      _ -> raise Eljure.Error.EvalError, "Invalid expression: #{show form}."
    end
  end

  def eval({:list, [{:symbol, "quote", _} | args], _} = whole, scope) do
    case args do
      [form] -> {form, scope}
      _ -> raise Eljure.Error.ArityError, "Expected exactly one argument in #{show whole}."
    end
  end

  def eval({:list, [{:symbol, "quasiquote", _} | args], _} = whole, scope) do
    case args do
      [form] -> eval Eljure.Quasiquote.quasiquote(form), scope
      #[form] -> { Eljure.Quasiquote.quasiquote(form), scope }
      _ -> raise Eljure.Error.ArityError, "Expected exactly one argument in #{show whole}."
    end
  end

  def eval({:list, [{:symbol, "apply", _}, {:symbol, _, _} = func_symbol | arg_list], _}, scope) do
    {f, _} = eval(func_symbol, scope)
    args = arg_list
           |> Enum.map(&(eval(&1, scope)))
           |> Enum.map(&(elem(&1, 0)))

    case List.last(args) do
      {:vector, arg_vec, _} ->
        first_args = List.delete_at(args, -1)
        { apply(f, first_args ++ arg_vec), scope }

      _ ->
        { apply(f, args), scope }
    end

  end

  def eval {:list, [{:symbol, "defmacro", _}, {:symbol, name, _}, {:vector, args, _} | body], _}, scope do
    m = macro(&(invoke_fn args, body, scope, &1))
    {m, Scope.put(scope, name, m)}
  end

  def eval {:list, [{:symbol, "macroexpand-1", _}, {:list, [{:symbol, "quote", _}, form], _}], _}, scope do
    { first, _ } = eval List.first(value(form)), scope
    case type(first) do
      :macro ->
        macro_args = List.delete_at(value(form), 0)
        { apply(first, macro_args), scope }
      _ -> eval form, scope
    end
  end

  def eval {:list, [{:symbol, ".", _}, {:symbol, func_name, _} | arg_list], _}, scope do
    args = arg_list
           |> Enum.map(&(eval(&1, scope)))
           |> Enum.map(&(elem(&1, 0)))
           |> Enum.map(&show/1)
           |> Enum.join(",")

    {invoke_native("#{func_name} #{args}"), scope}
  end

  #def eval {:list, [{:symbol, "elixir-eval"}, {:string, code}]}, scope do
  #  {invoke_native(code), scope}
  #end

  def eval({:list, [{:symbol, "eval", _} | args], _}, scope) do
    case args do
      [ast] ->
        {evaled_ast, _} = eval(ast, scope)
        eval(evaled_ast, scope)
      _ -> "Arity exception! Expected one argument."
    end
  end

  def eval({:list, ast, _}, scope) do
    fname = List.first(ast)
    args_ast = List.delete_at(ast, 0)

    {f, _} = eval(fname, scope)

    case type(f) do 
      :function ->
        { args, _ } = eval_ast(list(args_ast), scope)
        { apply(f, args), scope }

      :macro ->
        macro_args = List.delete_at(ast, 0)
        expr = apply(f, macro_args)
        eval(expr, scope)
    end
  end


  def eval(ast, scope) do
    eval_ast(ast, scope)
  end

  def eval_ast({:symbol, symbol, _}, scope) do
    {Scope.get(scope, symbol), scope}
  end

  def eval_ast({:list, l, _}, scope) do
    { Enum.map(l, &(elem(eval(&1, scope), 0))), scope}
  end

  def eval_ast({:vector, v, _}, scope) do
    { vector(Enum.map(v, &(elem(eval(&1, scope), 0)))), scope}
  end

  def eval_ast({:map, m, _}, scope) do
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

  defp invoke_fn argvec, body, scope, args do
    func_scope = List.foldl(
      Enum.zip(argvec, args),
      Scope.child(scope),
      fn {{:symbol, sym, _}, arg}, acc ->
        Scope.put(acc, sym, arg)
      end)
    elem(List.last(body |> Enum.map(&(eval &1, func_scope))), 0)
  end

  def apply {:macro, f, _}, args do
    Kernel.apply(f, [args])
  end

  def apply {:function, f, _}, args do
    Kernel.apply(f, [args])
  end

  def apply what, _ do
    raise Eljure.Error.EvalError, "#{show what} is not a function"
  end
end
