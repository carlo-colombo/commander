defmodule Commander.Mixfile do
  use Mix.Project

  def project do
    [app: :commander,
     version: "1.0.0",
     elixir: "~> 1.10",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "A macro library to help create telegram bot",
     name: "Commander",
     source_url: "https://github.com/carlo-colombo/commander",
     deps: deps(),
     package: [
       maintainers: ["Carlo Colombo"],
       licenses: ["MIT"],
       links: %{
         "Github" => "https://github.com/carlo-colombo/commander",
         "docs" => "http://hexdocs.pm/commander"
       }
     ]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:ex_doc, ">= 0.11.4", only: [:dev]}]
  end
end
