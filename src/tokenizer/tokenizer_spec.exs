defmodule TokenizerTest do
  use ExUnit.Case
  import Calc.Tokenizer

  doctest Calc.Tokenizer

  test "should tokenize a addition operator" do
    tokens = tokenize("+")
    assert tokens == {:ok, [{:operator, :addition, "+"}]}
  end

  test "should tokenize a division operator" do
    tokens = tokenize("/")
    assert tokens == {:ok, [{:operator, :division, "/"}]}
  end

  test "should tokenize a multiplication operator" do
    tokens = tokenize("*")
    assert tokens == {:ok, [{:operator, :multiplication, "*"}]}
  end

  test "should tokenize non negative integer" do
    assert tokenize("0") == {:ok, [{:operand, :number, "0"}]}
    assert tokenize("123") == {:ok, [{:operand, :number, "123"}]}
  end

  test "should tokenize non negative float" do
    assert tokenize("0.0") == {:ok, [{:operand, :number, "0.0"}]}
    assert tokenize("123.456") == {:ok, [{:operand, :number, "123.456"}]}
  end

  test "should tokenize a paren open" do
    tokens = tokenize("(")
    assert tokens == {:ok, [{:bracket, :round_bracket, "("}]}
  end

  test "should tokenize a paren close" do
    tokens = tokenize(")")
    assert tokens == {:ok, [{:bracket, :round_bracket, ")"}]}
  end

  test "should tokenize spaces" do
    tokens = tokenize("  ")
    assert tokens == {:ok, [{:space, :space, "  "}]}
  end

  test "should tokenize a subtraction operator" do
    tokens = tokenize("-")
    assert tokens == {:ok, [{:operator, :subtraction, "-"}]}
  end

  test "tokenize should convert a valid formula to a list of tokens" do
    formula = "1.3+1.7-3*4/6"

    tokens = [
      {:operand, :number, "1.3"},
      {:operator, :addition, "+"},
      {:operand, :number, "1.7"},
      {:operator, :subtraction, "-"},
      {:operand, :number, "3"},
      {:operator, :multiplication, "*"},
      {:operand, :number, "4"},
      {:operator, :division, "/"},
      {:operand, :number, "6"}
    ]

    assert tokenize(formula) == {:ok, tokens}
  end

  test "tokenize should convert a formula with space to a list of tokens" do
    formula = " 1 + 2-3  *4/6 "

    tokens = [
      {:space, :space, " "},
      {:operand, :number, "1"},
      {:space, :space, " "},
      {:operator, :addition, "+"},
      {:space, :space, " "},
      {:operand, :number, "2"},
      {:operator, :subtraction, "-"},
      {:operand, :number, "3"},
      {:space, :space, "  "},
      {:operator, :multiplication, "*"},
      {:operand, :number, "4"},
      {:operator, :division, "/"},
      {:operand, :number, "6"},
      {:space, :space, " "}
    ]

    assert tokenize(formula) == {:ok, tokens}
  end

  test "tokenize should convert a formula with round bracket to a list of tokens" do
    formula = "(1+(2))"

    tokens = [
      {:bracket, :round_bracket, "("},
      {:operand, :number, "1"},
      {:operator, :addition, "+"},
      {:bracket, :round_bracket, "("},
      {:operand, :number, "2"},
      {:bracket, :round_bracket, ")"},
      {:bracket, :round_bracket, ")"}
    ]

    assert tokenize(formula) == {:ok, tokens}
  end

  test "tokenize should convert a formula with box bracket to a list of tokens" do
    formula = "[1+[2]]"

    tokens = [
      {:bracket, :box_bracket, "["},
      {:operand, :number, "1"},
      {:operator, :addition, "+"},
      {:bracket, :box_bracket, "["},
      {:operand, :number, "2"},
      {:bracket, :box_bracket, "]"},
      {:bracket, :box_bracket, "]"}
    ]

    assert tokenize(formula) == {:ok, tokens}
  end

  test "tokenize should convert a formula with curly bracket to a list of tokens" do
    formula = "{1+{2}}"

    tokens = [
      {:bracket, :curly_bracket, "{"},
      {:operand, :number, "1"},
      {:operator, :addition, "+"},
      {:bracket, :curly_bracket, "{"},
      {:operand, :number, "2"},
      {:bracket, :curly_bracket, "}"},
      {:bracket, :curly_bracket, "}"}
    ]

    assert tokenize(formula) == {:ok, tokens}
  end

  test "tokenize should raise an exception in a invalid formula" do
    formula = "1+2-???3*4/6"

    assert tokenize(formula) == {:error, "Invalid char near at: \"?\""}
  end
end
