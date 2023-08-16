# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :data_aggregator,
  ecto_repos: [DataAggregator.Repo]

# For backwards compatibility, the following configuration is required.
# see https://ash-hq.org/docs/guides/ash/latest/get-started#temporary-config for more details
config :ash, :use_all_identities_in_manage_relationship?, false
config :ash_graphql, :default_managed_relationship_type_name_template, :action_name

config :data_aggregator, ash_apis: [DataAggregator.Imports]

config :data_aggregator, :ash_uuid,
  version: 7,
  encoded?: true,
  prefixed?: true,
  migration_default?: true

# Ash: Type shorthands, not required
config :ash, :custom_types, uuid: AshUUID.UUID

# Ash: Default belongs_to type, not required
config :ash, :default_belongs_to_type, AshUUID.UUID

# Configures the endpoint
config :data_aggregator, DataAggregatorWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: DataAggregatorWeb.ErrorHTML, json: DataAggregatorWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: DataAggregator.PubSub,
  live_view: [signing_salt: "0w2X+IQm"]

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
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
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

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
