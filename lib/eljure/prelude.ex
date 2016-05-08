defmodule Eljure.Prelude do
  alias Eljure.Reader
  import Eljure.Evaluator

  def init(scope) do
    read_eval(not_func, scope)
    read_eval(load_file, scope)
    read_eval(when_not, scope)
    read_eval(defn, scope)
    read_eval(first_and_second, scope)

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

  def when_not do
    """
    (defmacro when-not [cond & exprs]
      `(if (not ~cond) (do ~@exprs) nil))
    """
  end

  def defn do
    """
    (defmacro defn [name args & body]
      `(def ~name (fn ~args ~@body)))
    """
  end

  def first_and_second do
    """
    (defn first [[f _]] f)
    (defn second [[_ s]] s)
    """
  end

end
