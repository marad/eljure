defmodule Eljure.Core do
  import Kernel, except: [apply: 2]
  alias Eljure.Reader
  alias Eljure.Scope
  alias Eljure.Printer

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

  def eval {:list, l}, scope do
    {f, _} = eval(Enum.at(l, 0), scope)
    args = List.delete_at(l, 0)
            |> Enum.map(&(eval(&1, scope)))
            |> Enum.map(&(elem(&1, 0)))
    {apply(f, args), scope}
  end

  def eval ast, scope do
    {ast, scope}
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
