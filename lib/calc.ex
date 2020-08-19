defmodule Calc do
  import Calc.Interpreter, only: [run: 1]

  @moduledoc """
  Documentation for `Calc`.
  """

  def main([]) do
    IO.puts("Formula is required")
  end

  def main([formula]) do
    case run(formula) do
      {:error, reason} -> IO.puts("\n\n#{inspect(reason)}\n")
      {:ok, value} -> IO.puts("\n\n#{inspect(value)}\n")
    end
  end
end
