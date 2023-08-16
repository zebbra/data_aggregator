defmodule DataAggregator.Repo do
  use AshPostgres.Repo, otp_app: :data_aggregator

  # Installs Postgres extensions that ash commonly uses
  def installed_extensions do
    ["ash-functions", "uuid-ossp", "citext", AshUUID.PostgresExtension]
  end
end
