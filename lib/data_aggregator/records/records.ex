class_diagram = Path.expand("records-mermaid-class-diagram.md", __DIR__)

defmodule DataAggregator.Records do
  @moduledoc """
  Data API

  ## Resources

  #{File.read!(class_diagram)}
  """

  use Ash.Domain, extensions: [AshJsonApi.Domain, AshPaperTrail.Domain]

  # ensure module is recompiled when the class diagram changes
  @external_resource class_diagram

  @default_env [
    import_timeout: :timer.minutes(60),
    import_batch_size: 1000,
    approval_batch_size: 1000,
    async_import_progress?: true,
    export_timeout: :timer.minutes(60),
    approval_timeout: :timer.minutes(60),
    encode_timeout: :timer.minutes(60),
    encode_batch_size: 1000,
    publication_verification_timeout: :timer.minutes(5),
    execute_async: true
  ]

  resources do
    resource DataAggregator.Records.Collection
    resource DataAggregator.Records.EncodedRecord
    resource DataAggregator.Records.Encoding.RecordEncodingResult
    resource DataAggregator.Records.Export
    resource DataAggregator.Records.Import
    resource DataAggregator.Records.Import.Record
    resource DataAggregator.Records.Publication
    resource DataAggregator.Records.Record
    resource DataAggregator.Records.Record.Image
    resource DataAggregator.Records.Record.Version
    resource DataAggregator.Records.EncodedRecord.Version
    resource DataAggregator.Records.Approval
    resource DataAggregator.Records.ApprovedRecord
  end

  json_api do
    prefix "/api/json"
  end

  @doc """
  Configurations options for the `DataAggregator.Records` context.
  """
  def get_all_env do
    env = Application.get_env(:data_aggregator, __MODULE__, [])
    Keyword.merge(@default_env, env)
  end

  def get_env(key, default \\ nil), do: Keyword.get(get_all_env(), key, default)
  def import_timeout, do: get_env(:import_timeout)
  def import_batch_size, do: get_env(:import_batch_size)
  def approval_batch_size, do: get_env(:approval_batch_size)
  def async_import_progress?, do: get_env(:async_import_progress?)
  def execute_async?, do: get_env(:execute_async)

  def import_max_concurrency do
    num_cpus = :erlang.system_info(:logical_processors_available)
    max_concurrency = get_env(:import_max_concurrency, num_cpus)

    if max_concurrency > 12, do: 12, else: max_concurrency
  end

  def encode_timeout, do: get_env(:import_timeout)
  def encode_batch_size, do: get_env(:import_batch_size)

  def encode_max_concurrency do
    num_cpus = :erlang.system_info(:logical_processors_available)
    get_env(:encode_max_concurrency, num_cpus)
  end

  def export_timeout, do: get_env(:export_timeout)
  def approval_timeout, do: get_env(:approval_timeout)
end
