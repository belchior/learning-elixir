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

  defguardp kind_of(token) when elem(token, 0)
  defguardp type_of(token) when elem(token, 1)
  defguardp char_value_of(token) when elem(token, 2)

  defguardp started_with_sign(tokens) when type_of(hd(tokens)) == :addition or type_of(hd(tokens)) == :subtraction

  @spec to_number(binary) :: :error | number
  def to_number(str) when is_binary(str) do
    case Float.parse(str) do
      :error -> :error
      {_float, remainder} when remainder != "" -> :error
      {float, _} -> if float !== Float.round(float), do: float, else: trunc(float)
    end
  end

  @spec parse(tokens_wrap) :: wrap(ast)
  def parse({:error, reason}) do
    {:error, reason}
  end

  def parse({:ok, tokens}) do
    tokens
    |> remove_space
    |> to_ast({:ok, {nil, nil, nil}})
  end

  defp to_ast([], ast_wrap) when is_empty(ast_wrap) do
    {:error, "Invalid expression"}
  end

  defp to_ast([], ast_wrap) do
    ast_wrap
  end

  defp to_ast([unique_token], ast_wrap) when is_empty(ast_wrap) do
    case unique_token do
      {:operand, _type, char_value} -> {:ok, {:addition, 0, to_number(char_value)}}
      _ -> {:error, "Invalid expression"}
    end
  end

  defp to_ast(tokens, ast_wrap) when is_empty(ast_wrap) and started_with_sign(tokens) do
    new_tokens = [{:operand, :number, "0"} | tokens]
    to_ast(new_tokens, ast_wrap)
  end

  defp to_ast(_tokens, {:error, reason}) do
    {:error, reason}
  end

  defp to_ast(tokens, {:ok, pre_ast}) do
    [token | _tail] = tokens

    case kind_of(token) do
      :operand -> resolve_operand(tokens, {:ok, pre_ast})
      :operator -> resolve_operator(tokens, {:ok, pre_ast})
      :bracket -> resolve_bracket(tokens, {:ok, pre_ast})
      _ -> {:error, "unknown token: #{inspect(token)}"}
    end
  end

  defp resolve_bracket(tokens, ast_wrap) do
    {:ok, pre_ast} = ast_wrap

    br_expression = bracket_expression(tokens)
    rest_expression = tokens -- br_expression
    expression = remove_border_bracket(br_expression)
    empty_ast_wrap = {:ok, {nil, nil, nil}}
    ast_wrap_child = to_ast(expression, empty_ast_wrap)

    if rest_expression == [] and pre_ast == {nil, nil, nil} do
      ast_wrap_child
    else
      case ast_wrap_child do
        {:error, reason} ->
          {:error, reason}

        {:ok, pre_ast_child} ->
          new_ast_wrap = add_pre_ast({:ok, pre_ast}, pre_ast_child)
          to_ast(rest_expression, new_ast_wrap)
      end
    end
  end

  defp resolve_operand(tokens, ast_wrap) do
    [token | tail] = tokens
    new_ast_wrap = add_operand(ast_wrap, char_value_of(token))
    to_ast(tail, new_ast_wrap)
  end

  defp resolve_operator(tokens, ast_wrap) do
    [token | tail] = tokens
    {:ok, pre_ast} = ast_wrap

    if node_filled?(pre_ast) == false do
      # fill the current node
      new_ast_wrap = add_operator(ast_wrap, type_of(token))
      to_ast(tail, new_ast_wrap)
    else
      # it is necessary to create a new node
      {ast_operator, ast_operand1, ast_operand2} = pre_ast
      {_, token_type, _} = token

      if precede?(token_type, ast_operator) do
        # and add the new as a child of the current node
        new_ast_wrap = to_ast(tail, {:ok, {token_type, ast_operand2, nil}})

        case new_ast_wrap do
          {:error, reason} -> {:error, reason}
          {:ok, pre_ast} -> {:ok, {ast_operator, ast_operand1, pre_ast}}
        end
      else
        # and add the current as a child of new node
        new_ast_wrap = {:ok, {token_type, pre_ast, nil}}
        to_ast(tail, new_ast_wrap)
      end
    end
  end

  # AST helpers

  @spec add_operand(ast_wrap, char_value) :: ast_wrap
  defp add_operand({:ok, pre_ast}, char_value) do
    case pre_ast do
      {operator, nil, nil} -> {:ok, {operator, to_number(char_value), nil}}
      {operator, value1, nil} -> {:ok, {operator, value1, to_number(char_value)}}
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

  @spec add_pre_ast(ast_wrap, pre_ast) :: ast_wrap
  defp add_pre_ast({:ok, pre_ast}, pre_ast_child) do
    case pre_ast do
      {operator, nil, nil} -> {:ok, {operator, pre_ast_child, nil}}
      {operator, value1, nil} -> {:ok, {operator, value1, pre_ast_child}}
      _ -> {:error, "The pre_ast #{inspect(pre_ast_child)} can't be added, the node are filled or invalid"}
    end
  end

  @spec bracket_expression(tokens) :: tokens
  defp bracket_expression(tokens) when kind_of(hd(tokens)) != :bracket, do: []

  defp bracket_expression(tokens) do
    initial_value = {0, 0, []}

    callback = fn token, acc ->
      {opens, closes, expression} = acc

      if opens > 0 && opens === closes do
        {:halt, acc}
      else
        case char_value_of(token) do
          "(" -> {:cont, {opens + 1, closes, expression ++ [token]}}
          ")" -> {:cont, {opens, closes + 1, expression ++ [token]}}
          _ when opens > 0 -> {:cont, {opens, closes, expression ++ [token]}}
          _ -> {:cont, acc}
        end
      end
    end

    result = Enum.reduce_while(tokens, initial_value, callback)

    case result do
      {0, 0, _expression} -> []
      {_, _, expression} -> expression
    end
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

  @spec remove_border_bracket(tokens) :: tokens
  defp remove_border_bracket(tokens) do
    if kind_of(hd(tokens)) == :bracket and kind_of(hd(Enum.reverse(tokens))) == :bracket do
      tokens
      |> Enum.drop(1)
      |> Enum.drop(-1)
    else
      tokens
    end
  end

  @spec remove_space(tokens) :: tokens
  defp remove_space(tokens) do
    Enum.reject(tokens, fn token -> elem(token, 0) == :space end)
  end
end
