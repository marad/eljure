defmodule Eljure.Error do
  defmodule ArityError do
    defexception [:message]

    def exception({expected_arg_no, form}) do
      %ArityError{message: "Arguments expected: #{expected_arg_no} in #{form}"}
    end

    def exception(msg) when is_bitstring(msg) do
      %ArityError{message: msg}
    end

    def exception(expected_arg_no) when is_number(expected_arg_no) do
      %ArityError{message: "Arguments expected: #{expected_arg_no}"}
    end

    def exception [] do
      %ArityError{message: "Invalid number of arguments"}
    end

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

  defmodule FunctionApplicationError do
    defexception [:message]
  end
end
