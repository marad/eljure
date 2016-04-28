defmodule Eljure.Prelude do
  alias Eljure.Reader
  import Eljure.Evaluator

  def init(scope) do
    read_eval(not_func, scope)
    read_eval(load_file, scope)

    scope
  end

  defp read_eval(eljure_code, scope) do
    eval( Reader.read(eljure_code), scope)
  end

  def not_func do
    "(def not (fn [x] (if x false true)))"
  end

  def load_file do
    """
    (def load-file
      (fn [file-name]
        (eval (read-string (str "(do " (slurp file-name) ")")))))
    """
  end

end
