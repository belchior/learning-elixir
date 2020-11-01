defmodule Calc.MixProject do
  use Mix.Project

  @moduledoc """
  Mix configurations
  """

  def project do
    [
      app: :calc,
      version: "0.1.0",
      elixir: "~> 1.10",
      escript: escript_config(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: ["src"],
      test_paths: ["src"],
      test_pattern: "*_spec.exs"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def escript_config do
    [main_module: Calc]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.4", only: [:dev], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
