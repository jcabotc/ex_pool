defmodule ExPool.Mixfile do
  use Mix.Project

  @version "0.0.3"

  def project do
    [app: :ex_pool,
     version: @version,
     name: "ExPool",
     description: "A generic pooling library for Elixir",
     source_url: "https://github.com/jcabotc/ex_pool",
     package: package,
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     docs: [extras: ["README.md"], main: "readme"]]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev}]
  end

  def package do
    [mantainers: "Jaime Cabot",
     links: %{:GitHub => "https://github.com/jcabotc/ex_pool"}]
  end
end
