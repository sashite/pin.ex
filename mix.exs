defmodule Sashite.Pin.MixProject do
  use Mix.Project

  @version "1.1.0"
  @source_url "https://github.com/sashite/pin.ex"

  def project do
    [
      app: :sashite_pin,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Documentation
      name: "Sashite.Pin",
      source_url: @source_url,
      homepage_url: "https://sashite.dev/specs/pin/",
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE"]
      ]
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
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    PIN (Piece Identifier Notation) implementation for Elixir.
    Provides a rule-agnostic format for identifying pieces in abstract strategy
    board games with immutable identifier objects and functional programming principles.
    """
  end

  defp package do
    [
      name: "sashite_pin",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Specification" => "https://sashite.dev/specs/pin/1.0.0/",
        "Documentation" => "https://hexdocs.pm/sashite_pin"
      },
      maintainers: ["Cyril Kato"]
    ]
  end
end
