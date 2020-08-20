defmodule Calc.Parser do
  use Calc.Types

  @moduledoc """
  Parser token list to AST

  formula: 1+2-3*4/6

  Precedence order:
      () > [] > {} > * > / > + > -

  The token list
      [
        {:operand, :number, "1"},
        {:operator, :addition, "+"},
        {:operand, :number, "2"},
        {:operator, :subtraction, "-"},
        {:operand, :number, "3"},
        {:operator, :multiplication, "*"},
        {:operand, :number, "4"},
        {:operator, :division, "/"},
        {:operand, :number, "6"}
      ]

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
  """

  @type pre_ast :: {
          operator | nil,
          operand | pre_ast | nil,
          operand | pre_ast | nil
        }
  @type ast_wrap :: wrap(pre_ast)
  @type tokens_wrap :: wrap(tokens)

  @spec parse(tokens_wrap) :: wrap(ast)
  def parse({:error, reason}) do
    {:error, reason}
  end

  def parse({:ok, tokens}) do
    tokens
    |> remove_space
    |> to_ast({:ok, {nil, nil, nil}})
  end

  @spec to_number(binary) :: :error | number
  def to_number(str) when is_binary(str) do
    case Float.parse(str) do
      :error -> :error
      {_float, remainder} when remainder != "" -> :error
      {float, _} -> if float !== Float.round(float), do: float, else: trunc(float)
    end
  end

  @spec to_ast(tokens, ast_wrap) :: ast_wrap
  defp to_ast(_tokens, {:error, reason}) do
    {:error, reason}
  end

  defp to_ast([], ast_wrap) do
    ast_wrap
  end

  defp to_ast(tokens, {:ok, pre_ast}) do
    if node_filled?(pre_ast) do
      create_node(tokens, {:ok, pre_ast})
    else
      [token | tail] = tokens
      ast_wrap = {:ok, pre_ast}

      case token do
        {:operator, type, _} -> to_ast(tail, add_operator(ast_wrap, type))
        {:operand, _, value} -> to_ast(tail, add_operand(ast_wrap, value))
      end
    end
  end

  # AST helpers

  @spec add_operand(ast_wrap, value) :: ast_wrap
  defp add_operand({:ok, pre_ast}, value) do
    case pre_ast do
      {operator, nil, nil} -> {:ok, {operator, to_number(value), nil}}
      {operator, number1, nil} -> {:ok, {operator, number1, to_number(value)}}
      _ -> {:error, "The value #{inspect(value)} can't be added, the node are filled or invalid"}
    end
  end

  @spec add_operator(ast_wrap, operator) :: ast_wrap
  defp add_operator({:ok, pre_ast}, operator) do
    case pre_ast do
      {nil, value1, value2} -> {:ok, {operator, value1, value2}}
      _ -> {:error, "Un operator has already been defined and cannot be overridden"}
    end
  end

  @spec create_node(tokens, ast_wrap) :: ast_wrap
  defp create_node([token | tail], {:ok, pre_ast}) do
    {ast_op, ast_val1, ast_val2} = pre_ast
    {_, token_op, _} = token

    if precede?(ast_op, token_op) do
      to_ast(tail, {:ok, {token_op, pre_ast, nil}})
    else
      ast_wrap = to_ast(tail, {:ok, {token_op, ast_val2, nil}})

      case ast_wrap do
        {:ok, new_ast} -> {:ok, {ast_op, ast_val1, new_ast}}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  @spec remove_space(tokens) :: tokens
  def remove_space(tokens) do
    Enum.reject(tokens, fn token -> elem(token, 0) == :space end)
  end

  @spec node_filled?(pre_ast) :: boolean
  defp node_filled?(pre_ast) do
    !(pre_ast
      |> Tuple.to_list()
      |> Enum.find_value(false, &is_nil/1))
  end

  @spec precede?(type, type) :: boolean
  defp precede?(type1, type2) do
    precedence = [
      :round_bracket,
      :box_bracket,
      :curly_bracket,
      :multiplication,
      :division,
      :addition,
      :subtraction,
      :number
    ]

    indexType1 = Enum.find_index(precedence, &(&1 == type1))
    indexType2 = Enum.find_index(precedence, &(&1 == type2))

    case {indexType1, indexType2} do
      {nil, index2} when is_number(index2) -> false
      {index1, nil} when is_number(index1) -> true
      {index1, index2} when is_number(index1) and is_number(index2) -> index1 <= index2
    end
  end
end
