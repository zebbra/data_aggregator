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
    import_timeout: to_timeout(hour: 12),
    import_batch_size: 1000,
    validation_response_batch_size: 1000,
    async_import_progress?: true,
    export_timeout: to_timeout(day: 1),
    validation_response_timeout: to_timeout(hour: 1),
    validation_request_timeout: to_timeout(hour: 1),
    encode_timeout: to_timeout(hour: 1),
    encode_batch_size: 1000,
    publication_verification_timeout: to_timeout(minute: 5),
    execute_async: true,
    image_upload_timeout: to_timeout(hour: 12),
    extraction_timeout: to_timeout(hour: 12),
    mapping_timeout: to_timeout(hour: 12)
  ]

  authorization do
    authorize :when_requested
  end

  resources do
    resource DataAggregator.Records.Collection
    resource DataAggregator.Records.EncodedRecord
    resource DataAggregator.Records.Encoding.RecordEncodingResult
    resource DataAggregator.Records.Export
    resource DataAggregator.Records.Import
    resource DataAggregator.Records.Import.Record
    resource DataAggregator.Records.ImageUpload
    resource DataAggregator.Records.Publication
    resource DataAggregator.Records.Publication.PublishedRecord
    resource DataAggregator.Records.Record
    resource DataAggregator.Records.Record.Image
    resource DataAggregator.Records.Record.Version
    resource DataAggregator.Records.EncodedRecord.Version
    resource DataAggregator.Records.ValidationRequest
    resource DataAggregator.Records.ValidationResponse
    resource DataAggregator.Records.ValidationResponse.ValidatedRecord
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
  def validation_response_batch_size, do: get_env(:validation_response_batch_size)
  def async_import_progress?, do: get_env(:async_import_progress?)
  def execute_async?, do: get_env(:execute_async)

  def import_max_concurrency do
    num_cpus = :erlang.system_info(:logical_processors_available)
    get_env(:import_max_concurrency, num_cpus)
  end

  def encode_timeout, do: get_env(:import_timeout)
  def encode_batch_size, do: get_env(:import_batch_size)

  def encode_max_concurrency do
    num_cpus = :erlang.system_info(:logical_processors_available)
    get_env(:encode_max_concurrency, num_cpus)
  end

  def export_timeout, do: get_env(:export_timeout)
  def validation_response_timeout, do: get_env(:validation_response_timeout)
  def validation_request_timeout, do: get_env(:validation_request_timeout)

  def image_upload_timeout, do: get_env(:image_upload_timeout)
  def extraction_timeout, do: get_env(:extraction_timeout)
  def mapping_timeout, do: get_env(:mapping_timeout)
end
