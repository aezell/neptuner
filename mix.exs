defmodule Neptuner.MixProject do
  use Mix.Project

  def project do
    [
      app: :neptuner,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Neptuner.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:oban_web, "~> 2.0"},
      {:oban, "~> 2.0"},
      {:usage_rules, "~> 0.1", only: [:dev]},
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.8.0-rc.0", override: true},
      {:phoenix_ecto, "~> 4.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.9", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:mix_test_watch, "~> 1.3", only: [:dev, :test], runtime: false},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.16"},
      {:req, "~> 0.5"},
      {:jose, "~> 1.11"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.5"},
      {:dotenv, "~> 3.1.0", only: [:dev, :test]},
      {:remote_ip, "~> 1.2.0"},
      {:hammer, "~> 7.1.0"},
      {:ex_machina, "~> 2.8.0", only: :test},
      {:faker, "~> 0.17.0", only: :test},
      # MCP for local development
      {:tidewave, "~> 0.2.0", only: :dev},
      # Feature flagging
      {:fun_with_flags, "~> 1.13.0"},
      {:fun_with_flags_ui, "~> 1.1"},
      # Social Auth Google
      {:ueberauth_google, "~> 0.10"},
      {:ueberauth_github, "~> 0.8"},
      # Error Tracking
      {:error_tracker, "~> 0.6"},
      # Analytics
      {:phoenix_analytics, "~> 0.3"},
      # Project setup
      {:igniter, "~> 0.6", optional: true},
      {:rename_project, "~> 0.1.0", only: :dev},
      {:owl, "~> 0.12"},
      # Better Toasts
      {:live_toast, "~> 0.8.0"},
      # Timex
      {:timex, "~> 3.7.13"},
      # LemonSqueezy
      {:lemon_ex, "~> 0.2.4"},
      {:httpoison, "~> 2.2.3"},
      # Blog system
      {:backpex, "~> 0.13.0"},
      {:earmark, "~> 1.4"},
      {:slugify, "~> 1.3"},
      # AI
      {:langchain, "0.3.3"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind neptuner", "esbuild neptuner"],
      "assets.deploy": [
        "tailwind neptuner --minify",
        "esbuild neptuner --minify",
        "phx.digest"
      ]
    ]
  end
end
