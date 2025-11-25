[
  subdirectories: ["priv/*/migrations"],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs",
    "priv/*/init.exs",
    "storybook/**/*.exs"
  ],
  import_deps: [
    :ash_oban,
    :oban,
    :ecto,
    :ecto_sql,
    :phoenix,
    :ash,
    :ash_phoenix,
    :ash_postgres,
    :ash_json_api,
    :ash_uuid,
    :ash_state_machine,
    :ash_paper_trail,
    :ash_authentication,
    :ash_authentication_phoenix
  ],
  plugins: [
    TailwindFormatter,
    Phoenix.LiveView.HTMLFormatter,
    Spark.Formatter,
    Styler
  ]
]
