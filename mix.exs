defmodule DataAggregator.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_aggregator,
      version: "0.1.0",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [ignore_module_conflict: true],
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() == :prod,
      aliases: aliases(),
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

  defp docs do
    [
      main: "DataAggregator",
      extras: extras(),
      groups_for_modules: groups_for_modules(),
      groups_for_extras: groups_for_extras(),
      nest_modules_by_prefix: nest_modules_by_prefix(),
      before_closing_body_tag: &before_closing_body_tag/1,
      output: "priv/static/docs"
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
      "Platform API": [
        ~r/^DataAggregator\.Platform/
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
        ~r/^DataAggregatorWeb\.LiveComponents/,
        ~r/^DataAggregatorWeb\.Layouts/
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
      # Phoenix Framework
      {:bandit, "~> 1.4.2"},
      {:phoenix, "~> 1.7.12"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.11"},
      {:phoenix_storybook, "~> 0.6.0"},

      # Ash Framework
      {:ash, "~> 2.13"},
      {:ash_graphql, "~> 0.28.0"},
      {:ash_json_api, "~> 0.34.0"},
      {:ash_phoenix, "~> 1.2"},
      {:ash_postgres, "~> 1.3"},
      {:ash_state_machine, "~> 0.2.2"},
      {:ash_uuid, "~> 0.7"},
      {:ash_paper_trail, github: "ash-project/ash_paper_trail", branch: "main"},

      # Database and Ecto
      {:ecto, "~> 3.11.0"},
      {:ecto_sql, "~> 3.11.0"},
      {:ecto_dev_logger, "~> 0.9"},
      {:ecto_psql_extras, "~> 0.7"},
      {:postgrex, ">= 0.0.0"},

      # Testing and Linting
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false},
      {:assertions, "~> 0.19", only: :test},
      {:git_hooks, "~> 0.7.0", only: [:dev], runtime: false},
      {:tailwind_formatter, "~> 0.4.0", only: [:dev, :test], runtime: false},
      {:mimic, "~> 1.7", only: :test},
      {:styler, "~> 0.11", only: [:dev, :test], runtime: false},
      {:junit_formatter, "~> 3.3", only: :test},

      # Assets
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1,
       override: true},

      # Internationalization and Localization
      {:gettext, "~> 0.20"},
      {:ex_cldr, "~> 2.37"},
      {:ex_cldr_dates_times, "~> 2.14"},
      {:ex_cldr_numbers, "~> 2.31"},
      {:ex_cldr_units, "~> 3.16"},
      {:ex_cldr_plugs, "~> 1.3"},
      {:timex, "~> 3.0"},

      # HTTP and API Utilities
      {:absinthe_plug, "~> 1.5.8"},
      {:hackney, "~> 1.18"},
      {:jason, "~> 1.2"},
      {:open_api_spex, "~> 3.18"},
      {:redoc_ui_plug, "~> 0.2.1"},
      {:req, "~> 0.4.8"},

      # Mailing
      {:swoosh, "~> 1.3"},

      # Data Processing and Parsing
      {:explorer, "~> 0.8.0"},
      {:csv, "~> 3.2"},
      {:waffle, "~> 1.1"},
      {:ex_aws, "~> 2.5.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:sweet_xml, "~> 0.6"},

      # Background Jobs
      {:oban, "~> 2.16"},
      {:oban_live_dashboard, "~> 0.1.0"},

      # Monitoring and Tracing
      {:phoenix_live_dashboard, "~> 0.8.1"},
      {:sentry, "~> 10.0"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},

      # Clustering
      {:dns_cluster, "~> 0.1.1"},

      # Utilities and Helpers
      {:envy, "~> 1.1.1"},

      # Documentation
      {:ecto_erd, "~> 0.5", only: :dev},
      {:ex_doc, "~> 0.27", runtime: false},

      # Livebook Widgets
      {:kino, "~> 0.12.0", only: :dev},
      {:kino_explorer, "~> 0.1.10", only: :dev}
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
      "catalogs.import": [
        "run priv/repo/catalogs/init.exs"
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
