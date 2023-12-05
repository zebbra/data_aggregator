import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

require Logger

if config_env() in [:dev, :test] do
  Envy.load(["config/.env.#{config_env()}"])
end

if config_env() in [:dev] do
  Envy.load([".env"])
end

get_env! = fn
  var -> System.get_env(var) || raise("Required environment variable #{var} is missing")
end

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/data_aggregator start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :data_aggregator, DataAggregatorWeb.Endpoint, server: true
end

if System.get_env("LOG_LEVEL") do
  level = System.get_env("LOG_LEVEL") |> String.to_atom()
  config :logger, level: level
end

if System.get_env("IMPORT_MAX_CONCURRENCY") do
  max_concurrency = System.get_env("IMPORT_MAX_CONCURRENCY") |> String.to_integer()
  config :data_aggregator, DataAggregator.Records, import_max_concurrency: max_concurrency
end

# Configure Sentry runtime environment
config :sentry,
  environment_name: System.get_env("SENTRY_ENVIRONMENT", config_env() |> to_string())

# ## Waffle
config :waffle,
  asset_host: System.get_env("WAFFLE_ASSET_HOST")

case System.get_env("WAFFLE_STORAGE") do
  "s3" ->
    waffle_s3_bucket = get_env!.("WAFFLE_S3_BUCKET")

    config :waffle,
      storage: Waffle.Storage.S3,
      bucket: waffle_s3_bucket

    aws_s3_scheme = System.get_env("AWS_S3_SCHEME", "https://")
    aws_s3_host = System.get_env("AWS_S3_HOST", "s3.amazonaws.com")
    aws_s3_port = System.get_env("AWS_S3_PORT", "443") |> String.to_integer()

    config :ex_aws,
      debug_requests: System.get_env("AWS_DEBUG_REQUESTS") in ~w(true 1),
      access_key_id: get_env!.("AWS_ACCESS_KEY_ID"),
      secret_access_key: get_env!.("AWS_SECRET_ACCESS_KEY"),
      s3: [
        scheme: aws_s3_scheme,
        host: aws_s3_host,
        port: aws_s3_port
      ]

    waffle_s3_uri = URI.new!("#{aws_s3_scheme}#{aws_s3_host}:#{aws_s3_port}/#{waffle_s3_bucket}")
    Logger.info("Waffle configured to use S3 storage: #{waffle_s3_uri}")

  _ ->
    # Use local storage for Waffle by default
    waffle_storage_dir_prefix =
      System.get_env("WAFFLE_STORAGE_DIR_PREFIX", "priv/storage/#{config_env()}")

    config :waffle,
      storage: Waffle.Storage.Local,
      storage_dir_prefix: waffle_storage_dir_prefix

    Logger.info("Waffle configured to use local storage: #{waffle_storage_dir_prefix}")
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :data_aggregator, DataAggregator.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  ## Configure Erlang clustering using DNS cluster
  config :data_aggregator, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  ## Configure the Endpoint

  # Listen IP supports IPv4 and IPv6 addresses.
  {:ok, listen_ip} =
    System.get_env("LISTEN_IP", "127.0.0.1")
    |> String.to_charlist()
    |> :inet.parse_address()

  port =
    System.get_env("PORT", "4000")
    |> String.to_integer()

  base_url =
    System.get_env("BASE_URL", "http://localhost:4000")
    |> URI.parse()

  if base_url.scheme not in ["http", "https"] do
    raise "BASE_URL must start with `http` or `https`. Currently configured as `#{System.get_env("BASE_URL")}`"
  end

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :data_aggregator, DataAggregatorWeb.Endpoint,
    url: [scheme: base_url.scheme, host: base_url.host, path: base_url.path, port: base_url.port],
    http: [
      port: port,
      ip: listen_ip

      # transport_options: [max_connections: :infinity] # not valid for bandit
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :data_aggregator, DataAggregatorWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :data_aggregator, DataAggregatorWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #
  #     config :data_aggregator, DataAggregator.Mailer,
  #       adapter: Swoosh.Adapters.Mailgun,
  #       api_key: System.get_env("MAILGUN_API_KEY"),
  #       domain: System.get_env("MAILGUN_DOMAIN")
  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  #     config :swoosh, :api_client, Swoosh.ApiClient.Hackney
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
end
