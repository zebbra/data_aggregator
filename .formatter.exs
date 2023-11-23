[
  subdirectories: ["priv/*/migrations"],
  inputs: [
    "*.{heex,ex,exs}",
    "{config,lib,test}/**/*.{heex,ex,exs}",
    "priv/*/seeds.exs",
    "storybook/**/*.exs"
  ],
  import_deps: [
    :ecto,
    :ecto_sql,
    :phoenix,
    :ash,
    :ash_phoenix,
    :ash_postgres,
    :ash_graphql,
    :ash_uuid,
    :ash_state_machine
  ],
  plugins: [
    TailwindFormatter,
    Phoenix.LiveView.HTMLFormatter,
    Spark.Formatter,
    Recode.FormatterPlugin
  ]
]
