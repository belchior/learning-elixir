defmodule Calc.Interpreter do
  import Calc.Tokenizer, only: [tokenize: 1]
  import Calc.Parser, only: [parse: 1, to_number: 1]

  use Calc.Types

  @moduledoc """
  Interprets un Abstract Syntax Tree and return a number

  Precedence order:
      () > [] > {} > * > / > + > -

  The formula:
      1+2-3*4/6

  Will be converted into the AST
      {
        :subtraction,
        {:addition, "1", "2"},
        {
          :division,
          {:multiplication, "3", "4"},
          "6"
        }
      }

  And then return a value
      1
  """

  @type ast_wrap :: wrap(ast)
  @type result :: wrap(value)

  # Interpreter

  @spec run(formula) :: result
  def run(""), do: {:error, "formula is empty"}

  def run(formula) do
    formula
    |> tokenize
    |> parse
    |> compile
    |> format
  end

  @spec compile(ast_wrap | ast | number) :: number | error
  def compile({:error, reason}), do: {:error, reason}

  def compile({:ok, ast}), do: compile(ast)

  def compile(num) when is_number(num), do: num

  def compile({operator, operandA, operandB}) do
    basic_operation(operator, compile(operandA), compile(operandB))
  end

  @spec format(value) :: result
  defp format({:error, reason}), do: {:error, reason}

  defp format(value) when is_number(value) do
    value
    |> to_string
    |> to_number
    |> (&{:ok, &1}).()
  end

  # Basic operations

  @spec basic_operation(operator, number, number) :: result
  def basic_operation(operator, numA, numB) do
    result = apply(__MODULE__, operator, [numA, numB])

    case result do
      {:ok, value} -> value
      {:error, reason} -> {:error, reason}
    end
  end

  @spec addition(number, number) :: success(value)
  def addition(numA, numB) do
    {:ok, numA + numB}
  end

  @spec division(number, number) :: result
  def division(_numA, numB) when numB == 0 do
    {:error, "impossible divide by 0"}
  end

  def division(numA, numB) do
    {:ok, numA / numB}
  end

  @spec multiplication(number, number) :: success(value)
  def multiplication(numA, numB) do
    {:ok, numA * numB}
  end

  @spec subtraction(number, number) :: success(value)
  def subtraction(numA, numB) do
    {:ok, numA - numB}
  end
end
