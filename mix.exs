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
      {:floki, "~> 0.21.0"},
      {:earmark, "~> 1.3.2"},
      {:execv, "~> 0.1.2"},
      {:eex_html, "~> 1.0.0"},
      {:timex, "~> 3.5.0"}
    ]
  end
end
