defmodule Calc.Tokenizer do
  use Calc.Types.Wrap

  @moduledoc """
  Tokenize the received formula

  The formula:
      1+2-3*4/6

  Will be converted to tokenized list:
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
  """
  @typep formula :: String.t()
  @typep character :: String.t()
  @typep current :: non_neg_integer
  @typep pattern :: Regex.t()
  @typep token_wrap :: {:ok, token} | {:empty, nil}
  @typep tokenizers :: [(formula, current -> token_wrap)]
  @typep tokens :: [token]

  @type char_value :: String.t()
  @type operator :: :addition | :division | :multiplication | :subtraction
  @type kind :: :bracket | :operator | :operand | :space
  @type type :: operator | :number | :round_bracket | :box_bracket | :curly_bracket | :space
  @type token :: {kind, type, char_value}

  @spec tokenize(formula) :: wrap(tokens)
  def tokenize(formula) do
    tokenizers = [
      &tokenize_addition/2,
      &tokenize_box_bracket_close/2,
      &tokenize_box_bracket_open/2,
      &tokenize_curly_bracket_close/2,
      &tokenize_curly_bracket_open/2,
      &tokenize_division/2,
      &tokenize_multiplication/2,
      &tokenize_number/2,
      &tokenize_round_bracket_close/2,
      &tokenize_round_bracket_open/2,
      &tokenize_space/2,
      &tokenize_subtraction/2
    ]

    case run_tokenizers(tokenizers, formula) do
      {:error, reason} -> {:error, reason}
      {:ok, tokens} -> {:ok, tokens}
    end
  end

  @spec run_tokenizers(tokenizers, formula, current, tokens) :: wrap(token)
  defp run_tokenizers(tokenizers, formula, current \\ 0, tokens \\ []) do
    if current >= String.length(formula) do
      {:ok, Enum.reverse(tokens)}
    else
      {status, term} = find_token(tokenizers, formula, current)

      if status == :ok do
        position = current + String.length(to_string(elem(term, 2)))
        token_list = [term | tokens]
        run_tokenizers(tokenizers, formula, position, token_list)
      else
        {status, term}
      end
    end
  end

  @spec find_token(tokenizers, formula, current) :: wrap(token)
  defp find_token(tokenizers, formula, current) do
    find_callback = fn tokenizer_fn, _acc ->
      case tokenizer_fn.(formula, current) do
        {:empty, _} -> {:cont, nil}
        {:ok, token} -> {:halt, token}
      end
    end

    token = Enum.reduce_while(tokenizers, nil, find_callback)

    if token do
      {:ok, token}
    else
      char = String.at(formula, current)
      {:error, "Invalid char near at: #{char}"}
    end
  end

  @spec tokenize_char(kind, type, character, formula, current) :: token_wrap
  defp tokenize_char(kind, type, character, formula, current) do
    if character == String.at(formula, current) do
      {:ok, {kind, type, character}}
    else
      {:empty, nil}
    end
  end

  @spec tokenize_pattern(kind, type, pattern, formula, current) :: token_wrap
  defp tokenize_pattern(kind, type, pattern, formula, current) do
    formula
    |> String.slice(current, String.length(formula))
    |> (&Regex.run(pattern, &1)).()
    |> case do
      nil -> {:empty, nil}
      result -> {:ok, {kind, type, hd(result)}}
    end
  end

  # Tokenizers

  @spec tokenize_addition(formula, current) :: token_wrap
  defp tokenize_addition(formula, current) do
    tokenize_char(:operator, :addition, "+", formula, current)
  end

  @spec tokenize_box_bracket_open(formula, current) :: token_wrap
  defp tokenize_box_bracket_open(formula, current) do
    tokenize_char(:bracket, :box_bracket, "[", formula, current)
  end

  @spec tokenize_box_bracket_close(formula, current) :: token_wrap
  defp tokenize_box_bracket_close(formula, current) do
    tokenize_char(:bracket, :box_bracket, "]", formula, current)
  end

  @spec tokenize_curly_bracket_open(formula, current) :: token_wrap
  defp tokenize_curly_bracket_open(formula, current) do
    tokenize_char(:bracket, :curly_bracket, "{", formula, current)
  end

  @spec tokenize_curly_bracket_close(formula, current) :: token_wrap
  defp tokenize_curly_bracket_close(formula, current) do
    tokenize_char(:bracket, :curly_bracket, "}", formula, current)
  end

  @spec tokenize_division(formula, current) :: token_wrap
  defp tokenize_division(formula, current) do
    tokenize_char(:operator, :division, "/", formula, current)
  end

  @spec tokenize_multiplication(formula, current) :: token_wrap
  defp tokenize_multiplication(formula, current) do
    tokenize_char(:operator, :multiplication, "*", formula, current)
  end

  @spec tokenize_number(formula, current) :: token_wrap
  defp tokenize_number(formula, current) do
    tokenize_pattern(:operand, :number, ~r/^[0-9]+(\.\d+)?/u, formula, current)
  end

  @spec tokenize_round_bracket_open(formula, current) :: token_wrap
  defp tokenize_round_bracket_open(formula, current) do
    tokenize_char(:bracket, :round_bracket, "(", formula, current)
  end

  @spec tokenize_round_bracket_close(formula, current) :: token_wrap
  defp tokenize_round_bracket_close(formula, current) do
    tokenize_char(:bracket, :round_bracket, ")", formula, current)
  end

  @spec tokenize_space(formula, current) :: token_wrap
  defp tokenize_space(formula, current) do
    tokenize_pattern(:space, :space, ~r/^\s+/u, formula, current)
  end

  @spec tokenize_subtraction(formula, current) :: token_wrap
  defp tokenize_subtraction(formula, current) do
    tokenize_char(:operator, :subtraction, "-", formula, current)
  end
end
