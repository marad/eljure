defmodule Eljure.Function do
  import Kernel, except: [destructure: 2]
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

  def prepare_arg_bindings(arg_names, arg_values, check_arity \\ true) do
    case { arg_names, arg_values } do
      { [symbol("&"), arg_name], values } ->
        [ [ arg_name, vector(values) ] ]

      { [arg_name | names], [arg_value | values] } ->
        [ [ arg_name, arg_value ] | prepare_arg_bindings(names, values, check_arity) ]

      { [], [] } -> []
      { [], _ } -> if check_arity do raise Eljure.Error.ArityError else [] end
      { [symbol(_)=arg_name | names], [] } ->
        if check_arity do
          raise Eljure.Error.ArityError
        else
          [ [ arg_name, nil ] | prepare_arg_bindings(names, [], check_arity) ]
        end

      { _, [] } -> if check_arity do raise Eljure.Error.ArityError else [] end
    end
  end

  def destructure bindings do
    destructure [], bindings
  end

  defp destructure acc, bindings do
    case bindings do
      [ [vector(names), vector(values)] | rest ] ->
        destructured_bindings = destructure(prepare_arg_bindings(names, values, false))
        destructure(acc ++ destructured_bindings, rest)

      [ [map(%{keyword("keys") => vector(names)}), map(value_map)] | rest ] ->
        values = Enum.map(names, fn symbol(name,_) -> Map.get(value_map, keyword(name)) end)
        destructured_bindings = destructure(prepare_arg_bindings(names, values, false))
        destructure(acc ++ destructured_bindings, rest)

      [ [map(name_map), map(value_map)] | rest ] ->
        {names, values} = extract_map_bindings(name_map, value_map)
        destructured_bindings = destructure(prepare_arg_bindings(names, values, false))
        destructure(acc ++ destructured_bindings, rest)

      _ -> acc ++ bindings
    end
  end

  defp extract_map_bindings name_map, value_map do
    name_list = Enum.map(name_map, fn {name, _} -> name end)
    value_list = Enum.map(name_map, fn {_, key} -> Map.get(value_map, key) end)
    { name_list, value_list }
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
