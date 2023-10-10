defmodule DataAggregator.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_aggregator,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {DataAggregator.Application, []},
      extra_applications: [:logger, :runtime_tools, :ssl]
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
      # misc
      {:plug_cowboy, "~> 2.5"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.2"},
      {:gettext, "~> 0.20"},
      {:swoosh, "~> 1.3"},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:hackney, "~> 1.18"},
      {:envy, "~> 1.1.1"},
      {:earmark, "~> 1.4"},

      # db / orm / api
      {:ash, "~> 2.13"},
      {:ash_postgres, "~> 1.3"},
      {:ash_phoenix, "~> 1.2"},
      {:ash_admin, "~> 0.9.0"},
      {:ash_uuid, "~> 0.4"},
      {:ash_graphql, "~> 0.25.13"},
      {:absinthe_plug, "~> 1.5.8"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:finch, "~> 0.13"},
      {:ecto_erd, "~> 0.5", only: :dev},
      {:open_api_spex, "~> 3.18"},
      {:ash_json_api, "~> 0.33.1"},
      {:redoc_ui_plug, "~> 0.2.1"},
      {:typed_struct, "~> 0.3.0"},
      {:typed_ecto_schema, "~> 0.4.1", runtime: false},

      # frontend / ui
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:phoenix, "~> 1.7.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_live_dashboard, "~> 0.8.1"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.19.0"},
      {:floki, ">= 0.30.0", only: :test},

      # metrix and observation
      {:sentry, "~> 8.1"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},

      # file handling and S3:
      {:waffle, "~> 1.1"},
      {:ex_aws, "~> 2.1.2"},
      {:ex_aws_s3, "~> 2.0"},
      {:sweet_xml, "~> 0.6"}
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
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
      lint: ["format --check-formatted", "credo --strict"]
    ]
  end
end
