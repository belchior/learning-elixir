defmodule Calc.Types do
  @moduledoc """
  Shareable typespec definitions
  """

  defmacro __using__(_opts) do
    quote do
      @type formula :: String.t()
      @type kind :: :bracket | :operator | :operand | :space
      @type operand :: number
      @type operator :: :addition | :division | :multiplication | :subtraction
      @type type :: operator | :number | :round_bracket | :box_bracket | :curly_bracket | :space
      @type value :: number

      @type wrap(t) :: success(t) | error
      @type success(t) :: {:ok, t}
      @type reason :: String.t()
      @type error :: {:error, reason}

      @type char_value :: String.t()
      @type token :: {kind, type, char_value}
      @type tokens :: [token]
      @type ast :: {
              operator,
              operand | ast,
              operand | ast
            }
    end
  end
end
