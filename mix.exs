defmodule AppConfig.Mixfile do
  use Mix.Project

  def project do
    [app: :app_config,
     version: "0.5.2",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     package: package(),
     # Docs
     name: "AppConfig",
     source_url: "https://github.com/jcomellas/app_config",
     homepage_url: "https://github.com/jcomellas/app_config",
     docs: [main: "AppConfig",
            extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: []]
  end

  # Dependencies
  defp deps do
    [{:ex_doc, "~> 0.18", only: :dev, runtime: false}]
  end

  defp package do
    [files: ["lib", "config", "test", "mix.exs", "README*", "LICENSE*"],
     description: "Elixir configuration module that simplifies access to environment variables",
     maintainers: ["Juan Jose Comellas"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/jcomellas/app_config"}]
  end
end
