defmodule DataAggregator.Records.Collection.Actions.Publish do
  @moduledoc """
  Custom action to publish records of a collection as DarwinCoreArchive (dwca) file.
  """

  use Ash.Resource.Actions.Implementation

  alias Ash.Error.Invalid
  alias Ash.Error.Query.NotFound
  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Counter
  alias DataAggregator.DarwinCore.Publication.CoreFile
  alias DataAggregator.DarwinCore.Publication.DwcaFile
  alias DataAggregator.DarwinCore.Publication.EmlFile
  alias DataAggregator.DarwinCore.Publication.MaterialSampleFile
  alias DataAggregator.DarwinCore.Publication.MetaFile
  alias DataAggregator.DarwinCore.Publication.PreservationFile
  alias DataAggregator.DarwinCore.Publication.ReleveFile
  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Publication.PublishedRecord
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalogs.SwissSpecies

  require Ash.Query
  require Logger

  @record_attributes Enum.map(Schema.prefixed_attributes(), &Map.get(&1, :name))

  @impl true
  def run(input, _opts, %{tenant: tenant} = ctx) do
    publication = input.arguments.publication

    # these are the new records that will be published
    query =
      Record
      |> AshPagify.query_for_filters_map(publication.records_query)
      |> Ash.Query.set_tenant(tenant)

    # Store the original query records for status updates and verification
    original_records = Ash.stream!(query, stream_with: :keyset, batch_size: 1000)

    # first we need to copy the data of these records to published_records table
    append_published_records(publication, query)
    publication = update_count(publication, query, tenant)

    # we need to register now, so we can use the data in the dwc file creation process
    collection =
      case register(publication) do
        {:ok, collection} ->
          collection

        {:error, error} ->
          raise("Error registering dataset at GBIF: #{inspect(error)}")
      end

    path = FlatFileUtils.create_directory!("publication")
    EmlFile.create(collection, publication.license, path)
    MetaFile.create(collection, path)

    {:ok, counter} = Counter.start(&Publication.add_publication_progress(publication, &1))

    file_metas = [
      CoreFile.open_file!(path),
      MaterialSampleFile.open_file!(path),
      PreservationFile.open_file!(path),
      ReleveFile.open_file!(path)
    ]

    Enum.each(file_metas, &DwcaFile.write_headers(&1))

    # Use all published records for file generation and set status for original records
    publication
    |> stream_resource()
    |> set_publication_status(original_records, :publishing, ctx)
    |> Stream.chunk_every(1000)
    |> Stream.flat_map(fn records ->
      file_metas
      |> Task.async_stream(
        &DwcaFile.write_file!(records, &1, collection),
        timeout: to_timeout(second: 30)
      )
      |> Stream.run()

      records
    end)
    |> Counter.count_each(counter)
    |> set_publication_status(original_records, :in_publication, ctx)

    Enum.each(file_metas, &FlatFileUtils.close_file(&1.file_descriptor))

    Counter.stop(counter)

    attachment = path |> FlatFileUtils.create_zip!() |> FlatFileUtils.store_on_s3!()
    # remove file from local tmp dir, as it is now stored on s3
    File.rm_rf(path)

    publication =
      publication
      |> Publication.update_attachment(attachment)
      |> Ash.load!([:collection, :attachment])

    # create endpoint with attachment
    case publish(publication, original_records, ctx) do
      {:ok, publication} ->
        {:ok, publication}

      {:error, error} ->
        Logger.error("Error publishing records: #{inspect(error)}")

        publication
        |> stream_resource()
        |> set_publication_status(original_records, :publication_failed, ctx)

        {:error, error}
    end
  rescue
    e ->
      publication = input.arguments.publication

      Logger.error("Error publishing records: #{inspect(e)}")

      # In case of error, we need to recreate the original query to update status
      query =
        Record
        |> AshPagify.query_for_filters_map(publication.records_query)
        |> Ash.Query.set_tenant(tenant)

      original_records_for_error = Ash.stream!(query, stream_with: :keyset, batch_size: 1000)

      publication
      |> stream_resource()
      |> set_publication_status(original_records_for_error, :publication_failed, ctx)

      {:error, e}
  end

  @spec set_publication_status(Enumerable.t(), Enumerable.t(), atom(), Context.t()) ::
          Enumerable.t()
  defp set_publication_status(all_records_stream, original_records, status, %{actor: actor, tenant: tenant}) do
    max_concurrency = Records.import_max_concurrency()
    batch_size = ceil(Records.import_batch_size() / max_concurrency)

    # Create a set of original record IDs for efficient lookup
    original_ids = MapSet.new(original_records, & &1.id)

    # Filter and update only records that are in the original set
    stream_params =
      all_records_stream
      |> Stream.filter(fn record ->
        MapSet.member?(original_ids, record.record_id)
      end)
      |> Enum.map(fn record ->
        %{id: record.record_id}
      end)

    # Only perform bulk update if there are records to update
    if length(stream_params) > 0 do
      Ash.bulk_update(stream_params, :update_publication_status, %{status: status},
        actor: actor,
        authorize?: false,
        domain: Records,
        resource: Record,
        tenant: tenant,
        max_concurrency: max_concurrency,
        batch_size: batch_size
      )
    end

    all_records_stream
  end

  defp append_published_records(publication, query) do
    query
    |> Ash.stream!(stream_with: :keyset, batch_size: 1000, load: :encoded_record)
    |> Stream.map(fn record ->
      record_inputs(record, publication)
    end)
    |> Stream.map(&maybe_apply_publication_rules/1)
    |> Ash.bulk_create(PublishedRecord, :create,
      upsert?: true,
      upsert_identity: :unique_record_id,
      upsert_fields: {:replace_all_except, [:inserted_at, :id, :record_id, :collection_id]},
      tenant: publication.collection,
      batch_size: 200
    )
  end

  defp maybe_apply_publication_rules(%{loc_country: "Switzerland", tax_taxon_id: taxon_id} = record)
       when not is_nil(taxon_id) do
    case SwissSpecies.get_by_usage_key(taxon_id) do
      {:ok, _result} ->
        Logger.debug("This is a swissSpecies entry. lets use the publication rule to round the data to 2 decimal places")

        # this is a swissSpecies entry. lets use the publication rule
        record
        |> Map.put(:loc_decimal_latitude, round_coordinates(record.loc_decimal_latitude))
        |> Map.put(:loc_decimal_longitude, round_coordinates(record.loc_decimal_longitude))

      {:error, %NotFound{}} ->
        record

      {:error, %Invalid{}} ->
        record

      {:error, error} ->
        Logger.warning("SwissSpecies.get_by_usage_key failed: #{inspect(error)}")
        record
    end
  end

  defp maybe_apply_publication_rules(record), do: record

  defp round_coordinates(value) when is_float(value) do
    Float.round(value, 2)
  end

  defp round_coordinates(value), do: value

  defp update_count(publication, query, tenant) do
    # now we update the rows count with the number of records that were in the original query
    rows_count = Ash.count!(query, tenant: tenant)
    Publication.update!(publication, %{rows_count: rows_count})
  end

  defp stream_resource(%{collection: collection}),
    do: Ash.stream!(PublishedRecord, stream_with: :keyset, batch_size: 1000, tenant: collection)

  defp record_inputs(record, publication) do
    layer = if publication.layer == "import", do: record, else: Map.get(record, :encoded_record)

    layer
    |> Map.from_struct()
    |> Map.take(@record_attributes)
    |> Map.put(:record_id, record.id)
    |> Map.put(:extra_data, record.extra_data)
    |> Map.put(:publication_id, publication.id)
    |> Map.put(:collection_id, publication.collection.id)
  end

  defp register(publication) do
    Logger.debug("Registering collection: #{publication.collection.id} at GBIF for publishing")
    Collection.register_at_gbif(publication.collection, publication.existing_dataset_key)
  end

  defp publish(publication, original_records, ctx) do
    with {:ok, _dataset_key} <-
           Collection.create_endpoint(publication.collection, publication.attachment.url),
         :ok <- queue_records_for_verification(original_records, ctx) do
      {:ok, publication}
    end
  end

  @spec queue_records_for_verification(Enumerable.t(), any()) :: :ok
  defp queue_records_for_verification(original_records, %{actor: actor}) do
    Enum.each(original_records, &Record.enqueue_publication_verifier(&1, nil, actor: actor))
  end
end
