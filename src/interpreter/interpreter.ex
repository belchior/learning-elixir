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

  @typep ast_wrap :: wrap(ast)
  @typep result :: wrap(value)

  # Interpreter

  @spec run(formula) :: result
  def run(""), do: {:error, "formula is empty"}

  def run(formula) do
    formula
    |> tokenize
    |> parse
    |> interpret
    |> format
  end

  @spec interpret(ast_wrap | ast | number) :: number | error
  defp interpret({:error, reason}), do: {:error, reason}

  defp interpret({:ok, ast}), do: interpret(ast)

  defp interpret(num) when is_number(num), do: num

  defp interpret({operator, operand_a, operand_b}) do
    basic_operation(operator, interpret(operand_a), interpret(operand_b))
    |> case do
      {:ok, value} -> value
      {:error, reason} -> {:error, reason}
    end
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
  defp basic_operation(operator, num_a, num_b) do
    case operator do
      :addition -> addition(num_a, num_b)
      :division -> division(num_a, num_b)
      :multiplication -> multiplication(num_a, num_b)
      :subtraction -> subtraction(num_a, num_b)
      _ -> {:error, "Undefined operator: #{operator}"}
    end
  end

  @spec addition(number, number) :: success(value)
  defp addition(num_a, num_b) do
    {:ok, num_a + num_b}
  end

  @spec division(number, number) :: result
  defp division(_num_a, num_b) when num_b == 0 do
    {:error, "impossible divide by 0"}
  end

  defp division(num_a, num_b) do
    {:ok, num_a / num_b}
  end

  @spec multiplication(number, number) :: success(value)
  defp multiplication(num_a, num_b) do
    {:ok, num_a * num_b}
  end

  @spec subtraction(number, number) :: success(value)
  defp subtraction(num_a, num_b) do
    {:ok, num_a - num_b}
  end
end
