defmodule Eljure.Evaluator do
  import Kernel, except: [apply: 2]
  alias Eljure.Scope
  import Eljure.Types
  import Eljure.Printer

  # Evaluates the AST
  def eval({:symbol, s}, scope) do
    {Scope.get(scope, s), scope}
  end

  def eval({:list, [{:symbol, "def"}, {:symbol, s}, value]}, scope) do
    {evaledValue, _} = eval value, scope
    {nil, Scope.put(scope, s, evaledValue)}
  end

  def eval({:list, [{:symbol, "fn"}, {:vector, args} | body]}, scope) do
    {{:function, &(invoke_fn args, body, scope, &1)}, scope}
  end

  def eval({:list, [{:symbol, "let"}, {:vector, args} | body]}, scope) do
    let_scope = Enum.reduce(Enum.chunk(args, 2), Scope.child(scope), fn [{:symbol, sym}, val], sc ->
      Scope.put(sc, sym, elem(eval(val, sc), 0))
    end)
    result = elem(List.last(body |> Enum.map(&(eval &1, let_scope))), 0)
    {result, scope}
  end

  def eval({:list, [{:symbol, "do"} | body]}, scope) do
    Enum.reduce(body, {nil, scope}, fn form, {_, sc} ->
      eval form, sc
    end)
  end

  def eval {:list, [{:symbol, "."}, {:symbol, func_name} | arg_list]}, scope do
    args = arg_list
           |> Enum.map(&(eval(&1, scope)))
           |> Enum.map(&(elem(&1, 0)))
           |> Enum.map(&show/1)
           |> Enum.join(",")

    {invoke_native("#{func_name} #{args}"), scope}
  end

  def eval {:list, [{:symbol, "elixir-eval"}, {:string, code}]}, scope do
    {invoke_native(code), scope}
  end

  def eval {:list, [func_name | arg_list]}, scope do
    {f, _} = eval(func_name, scope)
    args = arg_list
            |> Enum.map(&(eval(&1, scope)))
            |> Enum.map(&(elem(&1, 0)))
    {apply(f, args), scope}
  end

  def eval ast, scope do
    {ast, scope}
  end

  def invoke_native code do
    {result, _} = Code.eval_string code
    native_to_ast(result)
  end

  def invoke_fn argvec, body, scope, args do
    func_scope = List.foldl(
      Enum.zip(argvec, args), 
      Scope.child(scope), 
      fn {{:symbol, sym}, arg}, acc ->
        Scope.put(acc, sym, arg)
      end)
      
    elem(List.last(body |> Enum.map(&(eval &1, func_scope))), 0)
  end

  def apply {:function, f}, args do
    Kernel.apply(f, [args])
  end
end
