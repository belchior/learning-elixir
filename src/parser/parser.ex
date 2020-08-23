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
  @type current :: number

  defguardp is_empty(ast_wrap) when ast_wrap == {:ok, {nil, nil, nil}}

  defguardp type_of(token) when elem(token, 1)

  defguardp started_with_sign(tokens) when type_of(hd(tokens)) == :addition or type_of(hd(tokens)) == :subtraction

  @spec parse(tokens_wrap) :: wrap(ast)
  def parse({:error, reason}) do
    {:error, reason}
  end

  def parse({:ok, tokens}) do
    tokens
    |> remove_space
    |> resolve_expression({:ok, {nil, nil, nil}})
  end

  @spec to_number(binary) :: :error | number
  def to_number(str) when is_binary(str) do
    case Float.parse(str) do
      :error -> :error
      {_float, remainder} when remainder != "" -> :error
      {float, _} -> if float !== Float.round(float), do: float, else: trunc(float)
    end
  end

  defp resolve_expression([], ast_wrap) when is_empty(ast_wrap) do
    {:error, "Invalid expression"}
  end

  defp resolve_expression([], ast_wrap) do
    ast_wrap
  end

  defp resolve_expression([unique_token], ast_wrap) when is_empty(ast_wrap) do
    case unique_token do
      {:operand, _type, char_value} -> {:ok, {:addition, 0, to_number(char_value)}}
      _ -> {:error, "Invalid expression"}
    end
  end

  defp resolve_expression(tokens, ast_wrap) when is_empty(ast_wrap) and started_with_sign(tokens) do
    new_tokens = [{:operand, :number, "0"} | tokens]
    resolve_expression(new_tokens, ast_wrap)
  end

  defp resolve_expression(_tokens, {:error, reason}) do
    {:error, reason}
  end

  defp resolve_expression(tokens, {:ok, pre_ast}) do
    [token | tail] = tokens

    if node_filled?(pre_ast) do
      # it is necessary to create a new node
      {ast_operator, ast_value1, ast_value2} = pre_ast
      {_, token_operator, _} = token

      if precede?(token_operator, ast_operator) do
        # and add the new as a child of the current node
        ast_wrap = resolve_expression(tail, {:ok, {token_operator, ast_value2, nil}})

        case ast_wrap do
          {:error, reason} -> {:error, reason}
          {:ok, new_node} -> {:ok, {ast_operator, ast_value1, new_node}}
        end
      else
        # and add the current as a child of new node
        ast_wrap = {:ok, {token_operator, pre_ast, nil}}
        resolve_expression(tail, ast_wrap)
      end
    else
      # fill the current node
      ast_wrap = fill_node(token, {:ok, pre_ast})
      resolve_expression(tail, ast_wrap)
    end
  end

  # AST helpers

  @spec add_operand(ast_wrap, char_value) :: ast_wrap
  defp add_operand({:ok, pre_ast}, char_value) do
    case pre_ast do
      {operator, nil, nil} -> {:ok, {operator, to_number(char_value), nil}}
      {operator, number1, nil} -> {:ok, {operator, number1, to_number(char_value)}}
      _ -> {:error, "The value #{inspect(char_value)} can't be added, the node are filled or invalid"}
    end
  end

  @spec add_operator(ast_wrap, operator) :: ast_wrap
  defp add_operator({:ok, pre_ast}, operator) do
    case pre_ast do
      {nil, value1, value2} -> {:ok, {operator, value1, value2}}
      _ -> {:error, "Un operator has already been defined and cannot be overridden"}
    end
  end

  @spec fill_node(token, ast_wrap) :: ast_wrap
  defp fill_node(token, ast_wrap) do
    case token do
      {:operator, type, _} -> add_operator(ast_wrap, type)
      {:operand, _, char_value} -> add_operand(ast_wrap, char_value)
    end
  end

  @spec remove_space(tokens) :: tokens
  defp remove_space(tokens) do
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

    type1_index = Enum.find_index(precedence, &(&1 == type1))
    type2_index = Enum.find_index(precedence, &(&1 == type2))

    case {type1_index, type2_index} do
      {nil, index2} when is_number(index2) -> false
      {index1, nil} when is_number(index1) -> true
      {index1, index2} when is_number(index1) and is_number(index2) -> index1 <= index2
    end
  end
end
