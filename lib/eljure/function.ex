defmodule Eljure.Function do
  import Kernel, except: [destructure: 2, apply: 2]
  import Eljure.Types
  import Eljure.Printer
  alias Eljure.Scope
  alias Eljure.Evaluator
  alias Eljure.Error.ArityError
  alias Eljure.Error.DestructuringError
  alias Eljure.Error.FunctionApplicationError

  def invoke_fn arg_names, body, scope, arg_values do
    func_scope = prepare_arg_bindings(arg_names, arg_values)
               |> destructure
               |> bind_params(Scope.child(scope))

    elem(List.last(body |> Enum.map(&(Evaluator.eval &1, func_scope))), 0)
  end

  def prepare_arg_bindings(arg_names, arg_values, check_arity \\ true) do
    case { arg_names, arg_values } do
      { [keyword("as",_), _], _ } -> []
      { [symbol("&",_), arg_name | _], values } ->
        [ [ arg_name, vector(values, nil) ] ]

      { [arg_name | names], [arg_value | values] } ->
        [ [ arg_name, arg_value ] | prepare_arg_bindings(names, values, check_arity) ]

      { [], [] } -> []
      { [], _ } -> if check_arity do raise ArityError else [] end
      { [arg_name | names], [] } ->
        if check_arity do
          raise ArityError
        else
          [ [ arg_name, nil ] | prepare_arg_bindings(names, [], check_arity) ]
        end
    end
  end

  def destructure bindings do
    destructure [], bindings
  end

  defp destructure acc, bindings do
    case bindings do
      [ [vector(names,_), vector(values,_) = whole_form] | rest ] ->
        destructured_bindings = destructure(prepare_arg_bindings(names, values, false))
        as_keyword_binding = extract_vector_as_keyword_binding(names, whole_form)
        destructure(acc ++ destructured_bindings ++ as_keyword_binding, rest)

      [ [map(%{keyword("keys", nil) => vector(names, _)} = name_map, m), map(value_map, _) = whole_form] | rest ] ->
        #FIXME: Map.get will not work if keyword (the key) has metadata
        values = Enum.map(names, fn symbol(name,_) -> Map.get(value_map, keyword(name, nil)) end)
        destructured_bindings = destructure(prepare_arg_bindings(names, values, false))
        as_keyword_binding = extract_map_as_keyword_binding(name_map, whole_form)
        destructure(acc ++ destructured_bindings ++ as_keyword_binding, rest)

      [ [map(name_map, _), map(value_map, _) = whole_form] | rest ] ->
        {names, values} = extract_map_bindings(name_map, value_map)
        destructured_bindings = destructure(prepare_arg_bindings(names, values, false))
        as_keyword_binding = extract_map_as_keyword_binding(name_map, whole_form)
        destructure(acc ++ destructured_bindings ++ as_keyword_binding, rest)

      # TODO: handle invalid cases (ie. trying to destructure map with vector)

      [ binding | rest ] ->
        destructure(acc ++ [ binding ], rest)

      _ -> acc ++ bindings

    end
  end

  defp extract_vector_as_keyword_binding names, whole_form do
    as_keyword_name = names
                      |> Enum.chunk(2, 1)
                      |> Enum.filter_map(
                          fn [k, _] -> is_as_keyword?(k) end,
                          fn [_, name] -> [name, whole_form] end)
  end

  defp extract_map_bindings name_map, value_map do
    name_list = Enum.filter_map(name_map, 
        fn {name, _} -> not is_as_keyword? name end,
        fn {name, _} -> name end)
    #FIXME: Map.get will net work if keyword (the key) has metadata (idk if this applies here)
    value_list = Enum.filter_map(name_map,
        fn {name, _} -> not is_as_keyword? name end,
        fn {_, key} -> Map.get(value_map, key) end)
    { name_list, value_list }
  end

  defp extract_map_as_keyword_binding name_map, whole_form do
    if Map.has_key?(name_map, keyword("as", nil))  do
      [ [ Map.get(name_map, keyword("as", nil)), whole_form ] ]
    else
      []
    end
  end

  defp is_as_keyword? keyword("as", _) do true end
  defp is_as_keyword? _ do false end

  def bind_params bindings, scope, eval_values \\ false do
    case bindings do
      [ [ symbol(name, _), value] | rest ] ->
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
      macro(f, _) -> Kernel.apply(f, [args])
      function(f, _) -> Kernel.apply(f, [args])
      keyword(_, _) = kw -> apply_keyword(kw, args)
      _ -> raise FunctionApplicationError, "#{show applicable} is not a function"
    end
  end

  defp apply_keyword kw, args do
    case args do
      [m] -> apply_keyword(kw, [m, nil])
      [map(m,_), default] ->
        Map.get(m, kw, default)
      [m, default] ->
        raise FunctionApplicationError, "Keywords work as functions only for maps"
      _ -> raise ArityError
    end
  end

end
