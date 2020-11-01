defmodule Calc.Types.Wrap do
  @moduledoc """
  Shareable typespec definitions
  """

  defmacro __using__(_opts) do
    quote do
      @typep success(t) :: {:ok, t}
      @typep reason :: String.t()
      @typep error :: {:error, reason}
      @typep wrap(t) :: success(t) | error
    end
  end
end
