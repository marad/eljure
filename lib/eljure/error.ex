defmodule Eljure.Error do
  defmodule ArityError do
    defexception message: "Invalid number of arguments"
  end

  defmodule DestructuringError do
    defexception message: "Destructuring error"
  end

  defmodule EvalError do
    defexception message: "Evaluation exception"
  end

  defmodule SyntaxError do
    defexception message: "Syntax error"
  end
end
