defmodule Calc.Types do
  defmacro __using__(_opts) do
    quote do
      @type reason :: String.t()
      @type success(t) :: {:ok, t}
      @type error :: {:error, reason}
      @type wrap(t) :: success(t) | error

      @type formula :: String.t()
      @type kind :: :bracket | :operator | :operand
      @type operator :: :addition | :division | :multiplication | :subtraction
      @type type :: operator | :number | :round_bracket | :box_bracket | :curly_bracket
      @type value :: number

      @type token :: {kind, type, value}
      @type tokens :: [token]

      @type operand :: number
      @type ast :: {
              operator,
              operand | ast,
              operand | ast
            }
    end
  end
end
