defmodule Calc.Interpreter do
  import Calc.Tokenizer, only: [tokenize: 1]
  import Calc.Parser, only: [parse: 1, to_number: 1]

  use Calc.Types.Wrap

  alias Calc.Tokenizer
  alias Calc.Parser

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

  @typep value :: number
  @typep formula :: String.t()
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

  @spec interpret(wrap(Parser.ast()) | Parser.ast() | value) :: value | error
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

  @spec format(value | error) :: result
  defp format({:error, reason}), do: {:error, reason}

  defp format(value) when is_number(value) do
    value
    |> to_string
    |> to_number
    |> (&{:ok, &1}).()
  end

  # Basic operations

  @spec basic_operation(Tokenizer.operator(), value, value) :: result
  defp basic_operation(operator, value_a, value_b) do
    case operator do
      :addition -> addition(value_a, value_b)
      :division -> division(value_a, value_b)
      :multiplication -> multiplication(value_a, value_b)
      :subtraction -> subtraction(value_a, value_b)
      _ -> {:error, "Undefined operator: #{operator}"}
    end
  end

  @spec addition(value, value) :: success(value)
  defp addition(value_a, value_b) do
    {:ok, value_a + value_b}
  end

  @spec division(value, value) :: result
  defp division(_value_a, value_b) when value_b == 0 do
    {:error, "impossible divide by 0"}
  end

  defp division(value_a, value_b) do
    {:ok, value_a / value_b}
  end

  @spec multiplication(value, value) :: success(value)
  defp multiplication(value_a, value_b) do
    {:ok, value_a * value_b}
  end

  @spec subtraction(value, value) :: success(value)
  defp subtraction(value_a, value_b) do
    {:ok, value_a - value_b}
  end
end
