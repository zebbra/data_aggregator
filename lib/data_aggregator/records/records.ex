defmodule DataAggregator.Records do
  @moduledoc """
  Data API

  ## Resources

  #{"records-mermaid-class-diagram.md" |> Path.expand(__DIR__) |> File.read!()}
  """

  use Ash.Api, extensions: [AshAdmin.Api, AshGraphql.Api, AshJsonApi.Api]

  @default_import_timeout :timer.minutes(5)

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
  def config, do: Application.get_env(:data_aggregator, __MODULE__, [])

  @doc """
  The default import timeout when running imports.
  """
  def import_timeout do
    config() |> Keyword.get(:import_timeout, @default_import_timeout)
  end
end
