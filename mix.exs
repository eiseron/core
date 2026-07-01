defmodule EiseronCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :eiseron_core,
      version: "0.2.0",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description()
    ]
  end

  defp description do
    "Pure Elixir primitives shared across Eiseron products."
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "Source" => "https://github.com/eiseron/core"
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:eiseron_devtools, git: "https://github.com/eiseron/devtools.git",
       tag: "v0.1.0", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.12"},
      {:argon2_elixir, "~> 4.0"},
      {:gettext, "~> 1.0"},
      {:sentry, "~> 10.8"},
      {:finch, "~> 0.19"},
      {:plug, "~> 1.16"},
      {:mox, "~> 1.2", only: :test}
    ]
  end
end
