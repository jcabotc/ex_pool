defmodule ExPool.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_pool,
     version: "0.1.1",
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
    [mantainers: ["Jaime Cabot"],
     licenses: ["Apache 2"],
     links: %{:GitHub => "https://github.com/jcabotc/ex_pool"}]
  end
end
