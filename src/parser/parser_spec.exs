defmodule ParserTest do
  use ExUnit.Case
  import Calc.Parser

  @moduledoc """
  The parser test suite
  """

  test "parse should return an Invalid expression error when the expression starts with an empty list" do
    tokens = []
    assert parse({:ok, tokens}) == {:error, "Invalid expression"}
  end

  test "parse should return a valid AST when the only token is a operand" do
    tokens = [{:operand, :number, "1"}]
    ast = {:addition, 0, 1}
    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "parse should return an Invalid expression Error when the list of tokens has only one token and is not an operand" do
    tokens = [{:operator, :addition, "+"}]
    assert parse({:ok, tokens}) == {:error, "Invalid expression"}
  end

  test "parse should return an valid AST from formulas started with operator: + or -" do
    tokens = [{:operator, :addition, "+"}, {:operand, :number, "1"}]
    ast = {:addition, 0, 1}
    assert parse({:ok, tokens}) == {:ok, ast}

    tokens = [{:operator, :subtraction, "-"}, {:operand, :number, "2.1"}]
    ast = {:subtraction, 0, 2.1}
    assert parse({:ok, tokens}) == {:ok, ast}

    tokens = [
      {:operator, :addition, "+"},
      {:operand, :number, "1"},
      {:operator, :addition, "+"},
      {:operand, :number, "1"}
    ]

    ast = {:addition, 0, {:addition, 1, 1}}
    assert parse({:ok, tokens}) == {:ok, ast}

    tokens = [
      {:operator, :subtraction, "-"},
      {:operand, :number, "2.1"},
      {:operator, :addition, "+"},
      {:operand, :number, "1"}
    ]

    ast = {:subtraction, 0, {:addition, 2.1, 1}}
    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "parse should return a valid AST" do
    tokens = [
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

    ast = {
      :subtraction,
      {:addition, 1, 2},
      {
        :division,
        {:multiplication, 3, 4},
        6
      }
    }

    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "parse should respect the precedence order: multiplication over division" do
    tokens = [
      {:operand, :number, "1"},
      {:operator, :division, "/"},
      {:operand, :number, "2"},
      {:operator, :multiplication, "*"},
      {:operand, :number, "3"}
    ]

    ast = {:division, 1, {:multiplication, 2, 3}}
    assert parse({:ok, tokens}) == {:ok, ast}

    tokens = [
      {:operand, :number, "1"},
      {:operator, :multiplication, "*"},
      {:operand, :number, "2"},
      {:operator, :division, "/"},
      {:operand, :number, "3"}
    ]

    ast = {:division, {:multiplication, 1, 2}, 3}
    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "parse should respect the precedence order: division over addition" do
    tokens = [
      {:operand, :number, "1"},
      {:operator, :addition, "+"},
      {:operand, :number, "2"},
      {:operator, :division, "/"},
      {:operand, :number, "3"}
    ]

    ast = {:addition, 1, {:division, 2, 3}}
    assert parse({:ok, tokens}) == {:ok, ast}

    tokens = [
      {:operand, :number, "1"},
      {:operator, :division, "/"},
      {:operand, :number, "2"},
      {:operator, :addition, "+"},
      {:operand, :number, "3"}
    ]

    ast = {:addition, {:division, 1, 2}, 3}
    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "parse should respect the precedence order: addition over subtraction" do
    tokens = [
      {:operand, :number, "1"},
      {:operator, :subtraction, "-"},
      {:operand, :number, "2"},
      {:operator, :addition, "+"},
      {:operand, :number, "3"}
    ]

    ast = {:subtraction, 1, {:addition, 2, 3}}
    assert parse({:ok, tokens}) == {:ok, ast}

    tokens = [
      {:operand, :number, "1"},
      {:operator, :addition, "/"},
      {:operand, :number, "2"},
      {:operator, :subtraction, "+"},
      {:operand, :number, "3"}
    ]

    ast = {:subtraction, {:addition, 1, 2}, 3}
    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "parse should remove all space from the list of tokens before convert into an AST" do
    tokens = [
      {:space, :space, " "},
      {:operand, :number, "1"},
      {:space, :space, " "},
      {:operator, :addition, "+"},
      {:operand, :number, "2"},
      {:operator, :subtraction, "-"},
      {:space, :space, " "},
      {:operand, :number, "3"},
      {:operator, :multiplication, "*"},
      {:operand, :number, "4"},
      {:operator, :division, "/"},
      {:operand, :number, "6"},
      {:space, :space, " "}
    ]

    ast = {
      :subtraction,
      {:addition, 1, 2},
      {
        :division,
        {:multiplication, 3, 4},
        6
      }
    }

    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "to_number" do
    assert to_number("1") === 1
    assert to_number("+1") === 1
    assert to_number("-1") === -1
    assert to_number("1.0") === 1
    assert to_number("-1.0") === -1

    assert to_number("1.2") === 1.2
    assert to_number("-1.2") === -1.2

    assert to_number("1x") === :error
    assert to_number("1.2x") === :error
    assert to_number("x1") === :error
    assert to_number("x1.3") === :error
  end

  test "expression 1." do
    tokens = [
      {:operand, :number, "1"}
    ]

    ast = {:addition, 0, 1}

    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "expression 2." do
    tokens = [
      {:operand, :number, "1"},
      {:operator, :addition, "+"},
      {:operand, :number, "2"}
    ]

    ast = {:addition, 1, 2}

    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "expression 3." do
    tokens = [
      {:operand, :number, "1"},
      {:operator, :addition, "+"},
      {:operand, :number, "2"},
      {:operator, :subtraction, "-"},
      {:operand, :number, "3"}
    ]

    ast = {:subtraction, {:addition, 1, 2}, 3}

    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "expression 4." do
    tokens = [
      {:operand, :number, "1"},
      {:operator, :addition, "+"},
      {:operand, :number, "2"},
      {:operator, :multiplication, "*"},
      {:operand, :number, "3"}
    ]

    ast = {:addition, 1, {:multiplication, 2, 3}}

    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "expression 5." do
    tokens = [
      {:bracket, :round_bracket, "("},
      {:operand, :number, "1"},
      {:bracket, :round_bracket, ")"}
    ]

    ast = {:addition, 0, 1}

    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "expression 6." do
    tokens = [
      {:bracket, :round_bracket, "("},
      {:operand, :number, "1"},
      {:operator, :addition, "+"},
      {:operand, :number, "2"},
      {:bracket, :round_bracket, ")"}
    ]

    ast = {:addition, 1, 2}

    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "expression 7." do
    tokens = [
      {:operand, :number, "1"},
      {:operator, :addition, "+"},
      {:bracket, :round_bracket, "("},
      {:operand, :number, "2"},
      {:bracket, :round_bracket, ")"}
    ]

    ast = {:addition, 1, {:addition, 0, 2}}

    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "expression 8." do
    tokens = [
      {:bracket, :round_bracket, "("},
      {:operand, :number, "2"},
      {:bracket, :round_bracket, ")"},
      {:operator, :addition, "+"},
      {:operand, :number, "1"}
    ]

    ast = {:addition, {:addition, 0, 2}, 1}

    assert parse({:ok, tokens}) == {:ok, ast}
  end

  test "expression 9." do
    tokens = [
      {:bracket, :round_bracket, "("},
      {:operand, :number, "1"},
      {:bracket, :round_bracket, ")"},
      {:operator, :addition, "+"},
      {:bracket, :round_bracket, "("},
      {:operand, :number, "2"},
      {:bracket, :round_bracket, ")"}
    ]

    ast = {:addition, {:addition, 0, 1}, {:addition, 0, 2}}

    assert parse({:ok, tokens}) == {:ok, ast}
  end
end
