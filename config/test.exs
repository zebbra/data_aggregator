import Config

# Configure your database
#
database_url = "ecto://postgres:postgres@localhost:5432/data-aggregator-test"

config :data_aggregator, DataAggregator.Repo,
  url: System.get_env("DATABASE_URL") || database_url,
  pool_size: System.schedulers_online() * 2,
  pool: Ecto.Adapters.SQL.Sandbox,
  queue_target: 100,
  log: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :data_aggregator, DataAggregatorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "gCUX1IH7IJDICQGJo4YMx912l9PTQXSCTSyoNFpidW1saLPXnEgA8+Zn+TGIA4fz",
  server: true

# In test we don't send emails.
config :data_aggregator, DataAggregator.Mailer, adapter: Swoosh.Adapters.Test

# Serve uploaded files
config :data_aggregator, serve_files_from: "priv/storage/test/files"

# Cache files in the test environment
config :data_aggregator, DataAggregator.Files, cache_dir: "priv/storage/test/cache"

# Use small batches to allow small datasets
config :data_aggregator, DataAggregator.Records,
  import_batch_size: 3,
  import_max_concurrency: 1,
  async_import_progress?: false

# Prevent Oban from running jobs and plugins during test runs
config :data_aggregator, Oban, testing: :inline

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_live_view,
  # Enable helpful, but potentially expensive runtime checks
  enable_expensive_runtime_checks: true

# Disable warnings for dummy resources
config :ash, :validate_api_config_inclusion?, false
config :ash, :validate_api_resource_inclusion?, false
config :ash, warn_on_transaction_hooks?: false

config :mix_test_watch, clear: true

config :junit_formatter,
  report_file: "test-junit-report.xml",
  report_dir: Path.expand("../test/reports", __DIR__),
  include_filename?: true

config :data_aggregator, :pagify, default_limit: 25

config :data_aggregator, :pagify_phoenix,
  pagination: [opts: {Pagify.Components.Pagination, :default_opts}],
  table: [opts: {Pagify.Components.Table, :default_opts}]

# Activate the publication verification scheduler `DataAggregator.Records.Publication.Scheduler.FastTrackPublicationVerifier`
config :data_aggregator, publication_verification_scheduler_active: false
