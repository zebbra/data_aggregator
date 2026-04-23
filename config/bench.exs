import Config

# Dedicated bench database — keeps benchmark runs isolated from dev data.
database_url = "ecto://postgres:postgres@localhost:5432/data-aggregator-bench"

# Sync counters so progress lands immediately (easier to reason about during bench).
config :data_aggregator, DataAggregator.Counter, backend: DataAggregator.Counter.Inline
config :data_aggregator, DataAggregator.Files, cache_dir: "priv/storage/bench/cache"

# Real Oban pipeline — no :testing key, so workers drain queues normally.

# Stub mailer — no real emails.
config :data_aggregator, DataAggregator.Mailer, adapter: Swoosh.Adapters.Test

config :data_aggregator, DataAggregator.Repo,
  url: System.get_env("DATABASE_URL") || database_url,
  pool_size: 30,
  queue_target: 5000,
  log: false,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  timeout: 10 * 60 * 1000

# Endpoint must serve so Waffle-uploaded attachments are reachable at
# http://localhost:4003/... during import/export/publish worker runs.
config :data_aggregator, DataAggregatorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4003],
  secret_key_base: "bench-key-base-only-used-locally-not-a-secret-____________________",
  server: true

config :data_aggregator, http_cache_enabled: false
config :data_aggregator, publication_verification_scheduler_active: false
config :data_aggregator, serve_files_from: "priv/storage/bench/files"

config :logger, :console, format: "[$level] $message\n"
config :logger, level: :info

config :phoenix, :plug_init_mode, :runtime

config :swoosh, :api_client, false
