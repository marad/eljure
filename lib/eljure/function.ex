defmodule Eljure.Function do
  import Eljure.Types
  import Eljure.Printer
  alias Eljure.Scope
  alias Eljure.Evaluator

  def invoke_fn arg_names, body, scope, arg_values do
    func_scope = List.foldl(
      prepare_arg_bindings(arg_names, arg_values),
      Scope.child(scope),
      fn {symbol(arg_name), arg_value}, acc ->
        Scope.put(acc, arg_name, arg_value)
      end)

    elem(List.last(body |> Enum.map(&(Evaluator.eval &1, func_scope))), 0)
  end

  def prepare_arg_bindings arg_names, arg_values do
    case { arg_names, arg_values } do
      { [symbol("&"), arg_name], values } ->
        [ { arg_name, list(values) } ]

      { [arg_name | names], [arg_value | values] } ->
        [ {arg_name, arg_value} | prepare_arg_bindings(names, values) ]

      { [], [] } -> []
      { [], _ } -> raise Eljure.Error.ArityError
      { _, [] } -> raise Eljure.Error.ArityError
    end
  end

  def apply applicable, args do
    case applicable do
      macro(f) -> Kernel.apply(f, [args])
      function(f) -> Kernel.apply(f, [args])
      _ -> raise Eljure.Error.EvalError, "#{show applicable} is not a function"
    end
  end

end
