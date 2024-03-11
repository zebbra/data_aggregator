# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :data_aggregator,
  ecto_repos: [DataAggregator.Repo],
  generators: [timestamp_type: :utc_datetime],
  env: Mix.env()

# For backwards compatibility, the following configuration is required.
# see https://ash-hq.org/docs/guides/ash/latest/get-started#temporary-config for more details
config :ash, :use_all_identities_in_manage_relationship?, false
config :ash_graphql, :default_managed_relationship_type_name_template, :action_name

# mime type config for json api
config :mime, :types, %{
  "application/vnd.api+json" => ["json"]
}

config :mime, :extensions, %{
  "json" => "application/vnd.api+json",
  "tsv" => "text/plain",
  "pqt" => "application/octet-stream",
  "parquet" => "application/octet-stream",
  "ipc" => "application/octet-stream",
  "arrow" => "application/octet-stream"
}

config :data_aggregator,
  ash_apis: [
    DataAggregator.Platform,
    DataAggregator.Records,
    DataAggregator.Taxonomy,
    DataAggregator.Files,
    DataAggregator.Jobs
  ]

config :data_aggregator, :ash_uuid,
  version: 7,
  encoded?: true,
  prefixed?: true,
  migration_default?: true

# Ash: Type shorthands, not required
# config :ash, :custom_types, uuid: AshUUID.UUID

# Ash: Default belongs_to type, not required
config :ash, :default_belongs_to_type, AshUUID.UUID

# prevent deprecated warning for wrong usage of timestamp dateformat
config :ash, :utc_datetime_type, :naive_datetime

# Configures the endpoint
config :data_aggregator, DataAggregatorWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: DataAggregatorWeb.ErrorHTML, json: DataAggregatorWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DataAggregator.PubSub,
  live_view: [signing_salt: "0w2X+IQm"]

# Configure gettext
config :data_aggregator, DataAggregatorWeb.Gettext,
  default_locale: "en",
  locales: ~w(de fr)

# Configure Cldr
config :ex_cldr,
  default_backend: DataAggregatorWeb.Cldr,
  json_library: Jason

# Configure Oban job queues
config :data_aggregator, Oban,
  repo: DataAggregator.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [imports: 1, encoders: 1]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :data_aggregator, DataAggregator.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.20.1",
  data_aggregator: [
    args: ~w(js/app.ts --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.1",
  data_aggregator: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Filter sensitive data from logs
config :phoenix, :filter_parameters, ["password", "account_token"]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Spark DSL formatter
config :spark, :formatter,
  remove_parens?: true,
  "Ash.Resource": [
    type: Ash.Resource,
    section_order: [
      :authentication,
      :token,
      :attributes,
      :relationships,
      :calculations,
      :aggregates,
      :state_machine,
      :preparations,
      :actions,
      :changes,
      :pub_sub,
      :code_interface,
      :policies,
      :postgres,
      :graphql,
      :json_api
    ]
  ]

# Configure error reporting using Sentry. The Sentry DSN is configured
# dynamically based on the SENTRY_DSN environment variable.
config :sentry,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()],
  context_lines: 5

# Configure Sentry logger handler, which will send logs to Sentry
# See https://hexdocs.pm/sentry/Sentry.LoggerHandler.html
config :data_aggregator, :logger, [
  {:handler, :sentry, Sentry.LoggerHandler,
   %{
     config: %{
       level: :error,
       metadata: :all,
       capture_log_messages: true
     }
   }}
]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
