defmodule Zamrazac.MixProject do
  use Mix.Project

  def project do
    [
      app: :zamrazac,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:floki, "~> 0.32.1"},
      {:earmark, "~> 1.4.24"},
      {:phoenix_html, "~> 3.2"},
      {:timex, "~> 3.7.7"}
    ]
  end
end
