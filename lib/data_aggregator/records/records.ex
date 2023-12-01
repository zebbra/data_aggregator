defmodule DataAggregator.Records do
  @moduledoc """
  Data API

  ## Resources

  #{"records-mermaid-class-diagram.md" |> Path.expand(__DIR__) |> File.read!()}
  """

  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  @default_env [
    import_timeout: :timer.minutes(60),
    import_batch_size: 1000,
    async_import_progress?: true,
    export_timeout: :timer.minutes(60)
  ]

  resources do
    registry DataAggregator.Records.Registry
  end

  graphql do
    authorize? false
  end

  json_api do
    prefix "/api/json"
  end

  @doc """
  Configurations options for the `DataAggregator.Records` context.
  """
  def get_all_env do
    env = Application.get_env(:data_aggregator, __MODULE__, [])
    @default_env |> Keyword.merge(env)
  end

  def get_env(key, default \\ nil), do: get_all_env() |> Keyword.get(key, default)

  def import_timeout, do: get_env(:import_timeout)
  def import_batch_size, do: get_env(:import_batch_size)
  def async_import_progress?, do: get_env(:async_import_progress?)

  def import_max_concurrency do
    num_cpus = :erlang.system_info(:logical_processors_available)
    get_env(:import_max_concurrency, num_cpus)
  end

  def export_timeout, do: get_env(:export_timeout)
end
