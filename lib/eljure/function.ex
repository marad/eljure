defmodule Eljure.Function do
  import Eljure.Types
  import Eljure.Printer
  alias Eljure.Scope
  alias Eljure.Evaluator

  def invoke_fn arg_names, body, scope, arg_values do
    func_scope = prepare_arg_bindings(arg_names, arg_values)
               |> destructure
               |> bind_params(Scope.child(scope))

    elem(List.last(body |> Enum.map(&(Evaluator.eval &1, func_scope))), 0)
  end

  def prepare_arg_bindings arg_names, arg_values do
    case { arg_names, arg_values } do
      # TODO: move this to destructuring code
      { [symbol("&"), arg_name], values } ->
        [ [ arg_name, list(values) ] ]

      { [arg_name | names], [arg_value | values] } ->
        [ [ arg_name, arg_value ] | prepare_arg_bindings(names, values) ]

      { [], [] } -> []
      { [], _ } -> raise Eljure.Error.ArityError
      { _, [] } -> raise Eljure.Error.ArityError
    end
  end

  def destructure bindings do
    bindings
  end

  def bind_params bindings, scope, eval_values \\ false do
    case bindings do
      [ [ symbol(name), value] | rest ] ->
        case eval_values do
          true ->
            { evaled, _ } = Evaluator.eval(value, scope)
            Scope.put(scope, name, evaled)
          false -> Scope.put(scope, name, value)
        end

        bind_params(rest, scope, eval_values)

      [] -> scope
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
