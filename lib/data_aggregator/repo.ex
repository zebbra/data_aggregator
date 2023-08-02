defmodule DataAggregator.Repo do
  use Ecto.Repo,
    otp_app: :data_aggregator,
    adapter: Ecto.Adapters.Postgres
end
