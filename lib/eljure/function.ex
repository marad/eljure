defmodule Eljure.Function do
  import Eljure.Types
  import Eljure.Printer
  alias Eljure.Scope
  alias Eljure.Evaluator

  def invoke_fn arg_names, body, scope, arg_values do
    func_scope = List.foldl(
      prepare_arg_bindings(arg_names, arg_values),
      Scope.child(scope),
      fn {{:symbol, arg_name, _}, arg_value}, acc ->
        Scope.put(acc, arg_name, arg_value)
      end)

    elem(List.last(body |> Enum.map(&(Evaluator.eval &1, func_scope))), 0)
  end

  def prepare_arg_bindings([{:symbol, "&", _}, arg_name], values) do
    [ { arg_name, list(values) } ]
  end

  def prepare_arg_bindings([arg_name | names], [arg_value | values]) do
    [ { arg_name, arg_value } | prepare_arg_bindings(names, values) ]
  end

  def prepare_arg_bindings([], []) do
    []
  end

  def prepare_arg_bindings([], _values) do
    raise Eljure.Error.ArityError
  end

  def prepare_arg_bindings(_names, []) do
    raise Eljure.Error.ArityError
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
