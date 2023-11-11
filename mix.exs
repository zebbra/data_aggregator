defmodule DataAggregator.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_aggregator,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [ignore_module_conflict: true],
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),

      # Dialyzer
      dialyzer: [
        plt_local_path: "priv/plts/project.plt",
        plt_core_path: "priv/plts/core.plt"
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
      extra_applications: [:logger, :runtime_tools, :ssl]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs() do
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

  defp extras() do
    "docs/**/*.{md,livemd,cheatmd}"
    |> Path.wildcard()
  end

  defp groups_for_extras do
    [
      Guides: [
        "docs/development.md",
        "docs/deployment.md"
      ],
      Ash: "docs/api.md",
      Livebooks: ~r'docs/livebooks'
    ]
  end

  def nest_modules_by_prefix() do
    [
      DataAggregator,
      DataAggregatorWeb,
      DataAggregatorApi
    ]
  end

  defp groups_for_modules() do
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
        DataAggregatorWeb.CoreComponents,
        DataAggregatorWeb.ColorMode,
        DataAggregatorWeb.HeadlessComponents,
        ~r/^DataAggregatorWeb\.Headless/
      ],
      "Live Hooks": [
        DataAggregatorWeb.LiveLocale,
        DataAggregatorWeb.LiveLogger,
        DataAggregatorWeb.LiveState,
        DataAggregatorWeb.LiveNavigator
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
      {:ash_uuid, "~> 0.4"},
      {:ash_graphql, "~> 0.26.6"},

      # frontent and components
      {:phoenix_storybook, "~> 0.5.0"},

      # db / orm / api
      {:absinthe_plug, "~> 1.5.8"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:open_api_spex, "~> 3.18"},
      {:ash_json_api, "~> 0.33.1"},
      {:redoc_ui_plug, "~> 0.2.1"},
      {:ecto_dev_logger, "~> 0.9"},
      {:ecto_erd, "~> 0.5", only: :dev},

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

      # misc
      {:envy, "~> 1.1.1"},
      {:floki, ">= 0.30.0", only: :test},
      {:hackney, "~> 1.18"},
      {:jason, "~> 1.2"},
      {:timex, "~> 3.0"},
      {:explorer, "~> 0.7.1"},

      # metrix and observation
      {:sentry, "~> 9.1"},
      {:telemetry_poller, "~> 1.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:phoenix_live_dashboard, "~> 0.8.1"},

      # linting & testing
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:git_hooks, "~> 0.7.0", only: [:dev], runtime: false},
      {:assertions, "~> 0.19", only: :test},

      # file handling and S3
      {:waffle, "~> 1.1"},
      {:ex_aws, "~> 2.5.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:sweet_xml, "~> 0.6"},
      {:csv, "~> 3.2"},

      # http
      {:finch, "~> 0.16"},
      {:castore, "~> 1.0"},
      {:mint, "~> 1.3"},

      # docs
      {:ex_doc, "~> 0.27", runtime: false}
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
        "run priv/repo/seeds.exs"
      ],
      "repo.reset": [
        "repo.drop",
        "repo.setup"
      ],
      "repo.lint": [
        "ash_postgres.generate_migrations --check"
      ],
      "repo.erd": [
        "ecto.gen.erd --output-path=docs/erd.dbml"
        # "ecto.gen.erd --output-path=docs/erd.mmd"
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
        "tailwind default",
        "esbuild default"
      ],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ],

      # Run linters
      lint: [
        "format --check-formatted",
        "credo --strict",
        "deps.audit",
        "dialyzer",
        "gettext.lint",
        "repo.lint"
      ],

      # Generate documentation
      docs: [
        "ash.generate_livebook --filename=docs/api.md",
        "ash.generate_resource_diagrams --format md",
        "repo.erd",
        "docs"
      ]
    ]
  end
end
