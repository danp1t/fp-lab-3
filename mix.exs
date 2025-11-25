# mix.exs
defmodule Interpolation.MixProject do
  use Mix.Project

  def project do
    [
      app: :interpolation,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: [],
      escript: [main_module: Interpolation.CLI]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
