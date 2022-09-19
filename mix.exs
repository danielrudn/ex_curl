defmodule ExCurl.MixProject do
  use Mix.Project

  @source_url "https://github.com/open-status/ex_curl"

  def project do
    [
      app: :ex_curl,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:zigler, "~> 0.9.1", runtime: false},
      {:jason, ">= 1.0.0"},
      {:bypass, "~> 2.0", only: :test}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: ["README.md", "LICENSE"]
    ]
  end
end
