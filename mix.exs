defmodule DataAggregator.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_aggregator,
      version: "0.1.0",
      elixir: "~> 1.15",
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
      # phoenix framework
      {:bandit, "~> 1.0-pre"},
      {:phoenix, "~> 1.7.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.1"},
      {:swoosh, "~> 1.3"},
      {:dns_cluster, "~> 0.1.1"},

      # ash framework
      {:ash, "~> 2.13"},
      {:ash_postgres, "~> 1.3"},
      {:ash_phoenix, "~> 1.2"},
      # {:ash_admin, "~> 0.9.0"},
      {:ash_uuid, "~> 0.4"},
      {:ash_graphql, "~> 0.26.6"},

      # db / orm / api
      {:absinthe_plug, "~> 1.5.8"},
      {:ecto_sql, "~> 3.10"},
      {:ecto_erd, "~> 0.5", only: :dev},
      {:postgrex, ">= 0.0.0"},
      {:finch, "~> 0.13"},
      {:open_api_spex, "~> 3.18"},
      {:ash_json_api, "~> 0.33.1"},
      {:redoc_ui_plug, "~> 0.2.1"},
      # {:typed_struct, "~> 0.3.0"},
      # {:typed_ecto_schema, "~> 0.4.1", runtime: false},

      # assets
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},

      # i18n
      {:gettext, "~> 0.20"},
      {:ex_cldr, "~> 2.37"},
      {:ex_cldr_numbers, "~> 2.31"},
      {:ex_cldr_dates_times, "~> 2.14"},
      {:ex_cldr_units, "~> 3.16"},
      {:ex_cldr_plugs, "~> 1.3"},
      {:ex_cldr_locale_display, "~> 1.4"},

      # misc
      {:envy, "~> 1.1.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:hackney, "~> 1.18"},
      {:jason, "~> 1.2"},
      {:timex, "~> 3.0"},

      # metrix and observation
      {:sentry, "~> 9.1"},
      {:telemetry_poller, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:phoenix_live_dashboard, "~> 0.8.1"},

      # linting
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:spark, "~> 1.1.48"},

      # file handling and S3:
      {:waffle, "~> 1.1"},
      {:ex_aws, "~> 2.5.0"},
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
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        "cmd cd assets && npm install"
      ],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
      lint: ["format --check-formatted", "credo --strict"],
      "generate.erd": ["ecto.gen.erd --output-path=erd.dbml"]
    ]
  end
end
