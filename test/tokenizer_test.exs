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

  test "should tokenize a subtraction operator" do
    tokens = tokenize("-")
    assert tokens == {:ok, [{:operator, :subtraction, "-"}]}
  end

  test "tokenize should convert a valid formula to a list of tokens" do
    formula = "1.3+1.7-3*4/6"

    tokenList = [
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

    assert tokenize(formula) == {:ok, tokenList}
  end

  test "tokenize should raise an exception in a invalid formula" do
    formula = "1+2-???3*4/6"

    assert tokenize(formula) == {:error, "Invalid char near at: \"?\""}
  end
end
