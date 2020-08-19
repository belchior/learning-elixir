defmodule InterpreterTest do
  use ExUnit.Case
  import Calc.Interpreter

  doctest Calc.Interpreter

  test "run should return un error when the formula is empty" do
    assert run("") == {:error, "formula is empty"}
  end

  test "run should calculate a math expression" do
    assert run("1+2-3*4/6") == {:ok, 1}
  end

  test "run should return un error when formula has unknown symbol" do
    assert run("?") == {:error, "Invalid char near at: \"?\""}
  end

  test "run should return un error when formula contains division by zero" do
    assert run("5/0") == {:error, "impossible divide by 0"}
  end

  test "run should return un error when formula produces division by zero" do
    assert run("5/3*0") == {:error, "impossible divide by 0"}
  end
end
