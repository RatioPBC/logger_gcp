defmodule LoggerGCP.MixProject do
  use Mix.Project

  def project do
    [
      app: :logger_gcp,
      version: "0.3.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {LoggerGCP.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, "~> 1.18", only: :dev},
      {:google_api_logging, "~> 0.45"},
      {:goth, "~> 1.3"},
      {:logger_json, "~> 5.0"}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
