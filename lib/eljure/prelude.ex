defmodule Eljure.Prelude do
  alias Eljure.Reader
  import Eljure.Evaluator

  def init(scope) do
    read_eval(not_func, scope)
    read_eval(load_file, scope)
    read_eval(when_not, scope)
    read_eval(defn, scope)
    read_eval(first_and_second, scope)
    read_eval(query_funcs, scope)
    read_eval(inc_dec, scope)
    read_eval(reverse, scope)

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

  def query_funcs do
    """
    (defn zero? [x] (= x 0))
    (defn true? [x] (= x true))
    (defn false? [x] (= x false))
    """
  end

  def inc_dec do
    """
    (defn inc [x] (+ x 1))
    (defn dec [x] (- x 1))
    """
  end

  def reverse do
    """
    (defn reverse [xs] (. Enum.reverse xs))
    """
  end
end
