defmodule DCMetrics.MixProject do
  use Mix.Project

  def project do
    [
      app: :dc_metrics,
      version: "0.1.2",
      description: description(),
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [
        main: "readme", # The main page in the docs
        extras: ["README.md"]
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
      {:grpc, "~> 0.3.1"},
      {:jason, "~> 1.2"},
      {:google_api_pub_sub, "~> 0.27.0"},
      {:goth, "~> 1.1.0"},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false},
      {:protobuf, "~> 0.7.1"}
    ]
  end

  defp description do
    "Elixir implementation for DeliveryCenter's structured logging format."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/deliverycenter/dc.libs.metrics.elixir"}
    ]
  end
end
