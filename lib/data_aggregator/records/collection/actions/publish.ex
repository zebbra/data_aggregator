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
  alias DataAggregator.Files.Attachment
  alias DataAggregator.Misc.Coordinates
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

  @uncertainty_in_meters 3535

  @impl true
  def run(input, _opts, %{tenant: tenant} = ctx) do
    publication = input.arguments.publication

    # these are the new records that will be published
    query =
      Record
      |> AshPagify.query_for_filters_map(publication.records_query)
      |> Ash.Query.set_tenant(tenant)

    # first we need to copy the data of these records to published_records table
    append_published_records(publication, query)
    publication = update_count(publication, tenant)

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

    set_publication_status(
      Ash.stream!(query, stream_with: :keyset, batch_size: 1000),
      :publishing,
      ctx
    )

    # Use all published records for file generation and set status for original records
    publication
    |> stream_resource()
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
    |> Stream.run()

    Enum.each(file_metas, &FlatFileUtils.close_file(&1.file_descriptor))

    Counter.stop(counter)

    attachment = path |> FlatFileUtils.create_zip!() |> FlatFileUtils.store_on_s3!()
    # remove file from local tmp dir, as it is now stored on s3
    File.rm_rf(path)

    publication =
      publication
      |> Publication.update_attachment(attachment)
      |> Ash.load!([:collection, :attachment])

    set_publication_status(
      Ash.stream!(query, stream_with: :keyset, batch_size: 1000),
      :in_publication,
      ctx
    )

    # create endpoint with attachment
    case publish(publication, query, ctx) do
      {:ok, publication} ->
        {:ok, publication}

      {:error, error} ->
        Logger.error("Error publishing records: #{inspect(error)}")

        set_publication_status(
          Ash.stream!(query, stream_with: :keyset, batch_size: 1000),
          :publication_failed,
          ctx
        )

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

      set_publication_status(
        Ash.stream!(query, stream_with: :keyset, batch_size: 1000),
        :publication_failed,
        ctx
      )

      {:error, e}
  end

  @spec set_publication_status(Enumerable.t(), atom(), Context.t()) ::
          Enumerable.t()
  defp set_publication_status(stream, status, %{actor: actor, tenant: tenant}) do
    max_concurrency = Records.import_max_concurrency()
    batch_size = ceil(Records.import_batch_size() / max_concurrency)

    Ash.bulk_update(stream, :update_publication_status, %{status: status},
      actor: actor,
      authorize?: false,
      domain: Records,
      resource: Record,
      tenant: tenant,
      max_concurrency: max_concurrency,
      batch_size: batch_size
    )

    stream
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

        {x, y} = obfuscate_coordinates(record.loc_decimal_longitude, record.loc_decimal_latitude)

        record
        |> Map.put(:loc_decimal_longitude, x)
        |> Map.put(:loc_decimal_latitude, y)
        |> Map.put(:loc_coordinate_uncertainty_in_meters, @uncertainty_in_meters)

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

  @doc """
  Obfuscates the given coordinates to a 5km grid.

  ## Examples

      iex> obfuscate_coordinates(9.166874938, 47.585812401)
      {9.1338001, 47.5907987}

      iex> obfuscate_coordinates(nil, 47.3769)
      {nil, 47.3769}

      iex> obfuscate_coordinates(8.5417, nil)
      {8.5417, nil}

      iex> obfuscate_coordinates(nil, nil)
      {nil, nil}
  """
  def obfuscate_coordinates(x, y) when not is_nil(x) and not is_nil(y) do
    swiss_coords_lv95 = Coordinates.wgs84_to_lv95!(%Coordinates{e: x, n: y})

    x5 = trunc(swiss_coords_lv95.e / 5000) * 5000 + 2500
    y5 = trunc(swiss_coords_lv95.n / 5000) * 5000 + 2500

    new_coords = Coordinates.lv95_to_wgs84!(%Coordinates{e: x5, n: y5})

    {Float.round(new_coords.e, 7), Float.round(new_coords.n, 7)}
  end

  def obfuscate_coordinates(x, y), do: {x, y}

  defp update_count(publication, tenant) do
    # now we update the rows count with the number of records that will be published
    published_records_count = Ash.count!(PublishedRecord, tenant: tenant)
    Publication.update!(publication, %{rows_count: published_records_count})
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

  defp publish(publication, query, ctx) do
    with {:ok, _dataset_key} <-
           Collection.create_endpoint(
             publication.collection,
             Attachment.Helpers.attachment_public_url(publication.attachment.id)
           ),
         :ok <- queue_records_for_verification(query, ctx) do
      {:ok, publication}
    end
  end

  defp queue_records_for_verification(query, %{actor: actor}) do
    query
    |> Ash.stream!(stream_with: :keyset, batch_size: 1000)
    |> Enum.each(&Record.enqueue_publication_verifier(&1, nil, actor: actor))
  end
end
