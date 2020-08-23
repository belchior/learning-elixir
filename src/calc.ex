defmodule Calc do
  import Calc.Interpreter, only: [run: 1]

  @moduledoc """
  Documentation for `Calc`.
  """

  @spec main([binary]) :: :ok
  def main([]) do
    IO.puts("Formula is required")
  end

  def main([formula]) do
    case run(formula) do
      {:error, reason} -> IO.puts(reason)
      {:ok, value} -> IO.puts(inspect(value))
    end
  end
end
