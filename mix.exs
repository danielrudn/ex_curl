defmodule ExCurl.MixProject do
  use Mix.Project

  @source_url "https://github.com/danielrudn/ex_curl"

  def project do
    [
      app: :ex_curl,
      version: "0.3.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
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
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:bypass, "~> 2.0", only: :test},
      {:zigler, "~> 0.13", runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: ["README.md", "LICENSE"]
    ]
  end

  defp package do
    [
      description: "Elixir bindings for libcurl.",
      maintainers: ["Daniel Rudnitski"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
