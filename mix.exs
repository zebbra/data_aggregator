defmodule DataAggregator.MixProject do
  use Mix.Project

  @version "0.12.1"

  def project do
    [
      app: :data_aggregator,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [ignore_module_conflict: true],
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() == :prod,
      aliases: aliases(),
      package: package(),
      deps: deps(),
      preferred_cli_env: [
        "test.watch": :test
      ],

      # Dialyzer
      dialyzer: [
        plt_local_path: "priv/plts/project.plt",
        plt_core_path: "priv/plts/core.plt",
        plt_add_apps: [:mix]
      ],

      # Docs
      name: "Data Aggregator",
      source_url: "https://github.com/zebbra/data_aggregator",
      homepage_url: "https://github.com/zebbra/data_aggregator",
      docs: docs()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {DataAggregator.Application, []},
      extra_applications: extra_applications(Mix.env())
    ]
  end

  defp extra_applications(:test), do: [:logger, :runtime_tools, :ssl]
  defp extra_applications(_), do: [:logger, :runtime_tools, :ssl, :os_mon]

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Hex package manager configuration.
  #
  # Type `mix help hex.config` for more information.
  def package do
    [
      name: "data_aggregator",
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md),
      links: %{
        "GitHub" => "https://github.com/zebbra/data_aggregator"
      }
    ]
  end

  defp docs do
    [
      main: "DataAggregator",
      extras: extras(),
      groups_for_modules: groups_for_modules(),
      groups_for_extras: groups_for_extras(),
      nest_modules_by_prefix: nest_modules_by_prefix(),
      before_closing_body_tag: &before_closing_body_tag/1,
      output: "priv/static/docs",
      skip_undefined_reference_warnings_on: [
        "docs/overview.md"
      ]
    ]
  end

  # Render mermaid diagrams in docs
  defp before_closing_body_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({
          startOnLoad: false,
          theme: document.body.className.includes("dark") ? "dark" : "default"
        });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
            graphEl.innerHTML = svg;
            bindFunctions?.(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""

  defp extras do
    Path.wildcard("docs/**/*.{md,livemd,cheatmd}")
  end

  defp groups_for_extras do
    [
      Docs: [
        "docs/development.md",
        "docs/deployment.md"
      ],
      Ash: "docs/api.md",
      Guides: ~r'docs/guides'
    ]
  end

  def nest_modules_by_prefix do
    [
      DataAggregator,
      DataAggregatorWeb,
      DataAggregatorApi
    ]
  end

  defp groups_for_modules do
    [
      "Darwin Core": [
        ~r/^DataAggregator\.DarwinCore/
      ],
      "File Management API": [
        ~r/^DataAggregator\.Files/
      ],
      "Taxonomy API": [
        ~r/^DataAggregator\.Taxonomy/
      ],
      "Records API": [
        ~r/^DataAggregator\.Records/
      ],
      "Jobs API": [
        ~r/^DataAggregator\.Jobs/
      ],
      Preparations: [
        ~r/^DataAggregator\.Preparations/
      ],
      API: [
        ~r/^DataAggregatorApi\./
      ],
      Web: [
        DataAggregatorWeb,
        DataAggregatorWeb.Router,
        DataAggregatorWeb.Endpoint,
        DataAggregatorWeb.Helpers,
        DataAggregatorWeb.ErrorHTML,
        DataAggregatorWeb.ErrorJSON
      ],
      "Live Views": [
        ~r/^DataAggregatorWeb\.\w+Live/
      ],
      Components: [
        ~r/^DataAggregatorWeb\.Blocks/,
        ~r/^DataAggregatorWeb\.Components/,
        ~r/^DataAggregatorWeb\.Filters/,
        ~r/^DataAggregatorWeb\.Layouts/,
        ~r/^DataAggregatorWeb\.LiveComponents/
      ],
      "Live Hooks": [
        DataAggregatorWeb.LiveLocale,
        DataAggregatorWeb.LiveLogger
      ],
      Localisation: [
        DataAggregatorWeb.Locale,
        DataAggregatorWeb.Gettext,
        DataAggregatorWeb.Cldr,
        ~r/^DataAggregatorWeb\.Cldr/
      ],
      Plugs: [
        ~r/^DataAggregatorWeb\.Plug/
      ]
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:usage_rules, "~> 0.1", only: [:dev]},
      {:igniter, "~> 0.5", only: [:dev, :test]},
      # Phoenix Framework
      {:bandit, "~> 1.7.0"},
      {:phoenix, "~> 1.7.14"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.0.0-rc.5", override: true},
      {:phoenix_storybook, "~> 0.8.0"},
      {:tidewave, "~> 0.1", only: :dev},
      {:live_debugger, "~> 0.2.0", only: :dev},

      # Ash Framework
      {:ash, "~> 3.4", override: true},
      {:ash_json_api, "~> 1.4"},
      {:ash_phoenix, "~> 2.1"},
      {:ash_postgres, "~> 2.4", override: true},
      {:ash_state_machine, "~> 0.2"},
      {:ash_uuid, "~> 1.1"},
      {:ash_paper_trail, "~> 0.4"},
      {:ash_pagify, "~> 1.4"},
      {:ash_authentication, "~> 4.0"},
      {:ash_authentication_phoenix, "~> 2.0"},

      # Database and Ecto
      {:ecto, "~> 3.11"},
      {:ecto_sql, "~> 3.11"},
      {:ecto_dev_logger, "~> 0.11"},
      {:ecto_psql_extras, "~> 0.7"},
      {:postgrex, ">= 0.0.0"},

      # Testing and Linting
      {:credo, "~> 1.7.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:assertions, "~> 0.19", only: :test},
      {:git_ops, "~> 2.8.0", only: [:dev]},
      {:git_hooks, "~> 0.8.0", only: [:dev], runtime: false},
      {:tailwind_formatter, "~> 0.4.0", only: [:dev, :test], runtime: false},
      {:mimic, "~> 1.11", only: :test},
      {:styler, "~> 1.0", only: [:dev, :test], runtime: false},
      {:junit_formatter, "~> 3.3", only: :test},
      {:ex_machina, "~> 2.8.0", only: :test},

      # Assets
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3.1", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1,
       override: true},

      # Internationalization and Localization
      {:gettext, "~> 0.20"},
      {:ex_cldr, "~> 2.37"},
      {:ex_cldr_dates_times, "~> 2.20"},
      {:ex_cldr_numbers, "~> 2.31"},
      {:ex_cldr_units, "~> 3.16"},
      {:ex_cldr_plugs, "~> 1.3"},
      {:timex, "~> 3.0"},

      # HTTP and API Utilities
      # TODO: Remove when a new release 1.20.2 is available
      {:hackney, github: "benoitc/hackney", branch: "master", override: true},
      {:jason, "~> 1.4"},
      {:open_api_spex, "~> 3.18"},
      {:redoc_ui_plug, "~> 0.2.1"},
      {:req, "~> 0.5.0"},

      # Mailing
      {:swoosh, "~> 1.3"},
      {:gen_smtp, "~> 1.1"},

      # Data Processing and Parsing
      {:explorer, "~> 0.10.0"},
      {:csv, "~> 3.2"},
      {:waffle, "~> 1.1.9"},
      {:ex_aws, "~> 2.5.4"},
      {:ex_aws_s3, "~> 2.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:sweet_xml, "~> 0.6"},
      {:xml_builder, "~> 2.3"},

      # Background Jobs
      {:oban, "~> 2.17"},
      {:oban_live_dashboard, "~> 0.2.0"},

      # Monitoring and Tracing
      {:phoenix_live_dashboard, "~> 0.8.4"},
      {:sentry, "~> 10.6"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:recon, "~> 2.5", only: :dev},

      # Clustering
      {:dns_cluster, "~> 0.2.0"},

      # Utilities and Helpers
      {:envy, "~> 1.1.1"},
      {:picosat_elixir, "~> 0.2"},
      {:sourceror, "~> 1.7", only: [:dev, :test]},

      # Documentation
      {:ex_doc, "~> 0.35", runtime: false},

      # Livebook Widgets
      {:kino, "~> 0.12", only: :dev},
      {:kino_explorer, "~> 0.1", only: :dev}
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
      # Setup Project
      setup: [
        "deps.get",
        "git_hooks.install",
        "git_ops.message_hook",
        "repo.setup",
        "assets.setup",
        "assets.build",
        "docs"
      ],

      # Database management
      "repo.create": [
        "ash_postgres.create"
      ],
      "repo.migrate": [
        "ash_postgres.migrate"
      ],
      "repo.rollback": [
        "ash_postgres.rollback"
      ],
      "repo.drop": [
        "ash_postgres.drop"
      ],
      "repo.setup": [
        "repo.create",
        "repo.migrate",
        "run priv/repo/seeds.exs",
        "run priv/repo/catalogs/init.exs"
      ],
      "repo.reset": [
        "repo.drop",
        "repo.setup"
      ],
      "repo.lint": [
        "ash_postgres.generate_migrations --check"
      ],
      "repo.dry_run": [
        "ash_postgres.generate_migrations --dry-run"
      ],
      "repo.squash": [
        "ash_postgres.squash_snapshots --into first"
      ],
      "catalogs.import": [
        "run priv/repo/catalogs/init.exs"
      ],
      "users.create": [
        "run priv/repo/users/init.exs"
      ],

      # Run tests
      test: [
        "repo.create --quiet",
        "repo.migrate --quiet",
        "test"
      ],

      # Translation management
      "gettext.update": [
        "gettext.extract --merge"
      ],
      "gettext.lint": [
        "gettext.extract --check-up-to-date"
      ],

      # Asset management
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        "cmd cd assets && npm install"
      ],
      "assets.build": [
        "tailwind data_aggregator",
        "esbuild data_aggregator"
      ],
      "assets.deploy": [
        "tailwind data_aggregator --minify",
        "esbuild data_aggregator --minify",
        "phx.digest"
      ],

      # Run linters
      lint: [
        # temporarily disabled because of deprecation warning in Waffle
        # "compile --all-warnings --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "deps.audit",
        "gettext.lint",
        "repo.lint",
        "dialyzer"
      ],

      # Generate documentation
      docs: [
        "ash.generate_livebook --filename=docs/api.md",
        "ash.generate_resource_diagrams --format md",
        "ash_state_machine.generate_flow_charts --format md",
        "repo.erd",
        "docs"
      ]
    ]
  end
end
