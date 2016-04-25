defmodule Eljure.Prelude do
  alias Eljure.Reader
  import Eljure.Evaluator

  def init(scope) do
    read_eval("(def not (fn [x] (if x false true)))", scope)

    read_eval("""
      (def load-file 
        (fn [file-name] 
          (eval (read-string (str "(do " (slurp file-name) ")")))))
    """, scope)

    scope
  end

  defp read_eval(eljure_code, scope) do
    eval( Reader.read(eljure_code), scope)
  end

end
