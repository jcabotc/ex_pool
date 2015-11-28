defmodule ExPool.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_pool,
     version: "0.0.2",
     name: "ExPool",
     source_url: "https://github.com/jcabotc/ex_pool",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     docs: [extras: ["README.md"]]]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev}]
  end
end
