defmodule DataAggregator.Records.Collection.Actions.Publish do
  @moduledoc """
  Custom action to publish records of a collection through the fast track as DarwinCoreArchive (dwca) file.
  """

  use Ash.Resource.Actions.Implementation

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
  alias DataAggregator.Records.Publication.InfoSpecies
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

    # first we need to copy the data of these records to published_records table if fast track
    maybe_append_published_records(publication, query)
    publication = maybe_update_count(publication, tenant)

    # we need to register now, so we can use the data in the dwc file creation process
    case register(publication) do
      {:ok, collection} ->
        collection

      {:error, error} ->
        raise("Error registering dataset at GBIF: #{inspect(error)}")
    end

    path = FlatFileUtils.create_directory!("publication_#{publication.channel}")
    EmlFile.create(publication.collection, publication, path)
    MetaFile.create(publication.collection, path)

    {:ok, counter} = Counter.start(&Publication.add_publication_progress(publication, &1))

    file_metas = [
      CoreFile.open_file!(path),
      MaterialSampleFile.open_file!(path),
      PreservationFile.open_file!(path),
      ReleveFile.open_file!(path)
    ]

    Enum.each(file_metas, &DwcaFile.write_headers(&1))

    query
    |> stream_query_or_resource(publication)
    |> set_publication_status(:publishing, publication, ctx)
    |> Stream.chunk_every(1000)
    |> Stream.flat_map(fn records ->
      file_metas
      |> Task.async_stream(
        &DwcaFile.write_file!(records, &1, publication.channel, publication.collection),
        timeout: :timer.seconds(30)
      )
      |> Stream.run()

      records
    end)
    |> Counter.count_each(counter)
    |> set_publication_status(:in_publication, publication, ctx)

    Enum.each(file_metas, &FlatFileUtils.close_file(&1.file_descriptor))

    Counter.stop(counter)

    attachment = path |> FlatFileUtils.create_zip!() |> FlatFileUtils.store_on_s3!()
    # remove file from local tmp dir, as it is now stored on s3
    File.rm_rf(path)

    publication =
      publication
      |> Publication.update_attachment(attachment)
      |> Ash.load!([:collection, :attachment])

    # fast_track: create endpoint with attachment, approval: notify infospecies
    case publish(publication, query, ctx) do
      {:ok, publication} ->
        {:ok, publication}

      {:error, error} ->
        Logger.error("Error publishing records on the #{publication.channel} channel: #{inspect(error)}")

        query
        |> stream_query_or_resource(publication)
        |> set_publication_status(
          :publication_failed,
          publication,
          ctx
        )

        {:error, error}
    end
  rescue
    e ->
      publication = input.arguments.publication

      query =
        Record
        |> AshPagify.query_for_filters_map(publication.records_query)
        |> Ash.Query.set_tenant(tenant)

      Logger.error("Error publishing records on the #{publication.channel} channel: #{inspect(e)}")

      query
      |> stream_query_or_resource(publication)
      |> set_publication_status(
        :publication_failed,
        publication,
        ctx
      )

      {:error, e}
  end

  @spec set_publication_status(Enumerable.t(), atom(), Publication.t(), Context.t()) ::
          Enumerable.t()
  defp set_publication_status(stream, status, publication, %{actor: actor, tenant: tenant}) do
    action =
      if publication.channel == :fast_track,
        do: :update_fast_track_status,
        else: :update_approval_status

    status = if action == :update_approval_status, do: translate_status(status), else: status

    max_concurrency = Records.import_max_concurrency()
    batch_size = ceil(Records.import_batch_size() / max_concurrency)

    stream_params =
      if publication.channel == :fast_track do
        Enum.map(stream, &%{id: &1.record_id})
      else
        stream
      end

    Ash.bulk_update(stream_params, action, %{status: status},
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

  defp maybe_append_published_records(%{channel: :approval} = _publication, _query), do: nil

  defp maybe_append_published_records(%{channel: :fast_track} = publication, query) do
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

  defp maybe_update_count(%{channel: :approval} = publication, _tenant), do: publication

  defp maybe_update_count(%{channel: :fast_track} = publication, tenant) do
    # now we update the rows count with the number of records that will be published
    published_records_count = Ash.count!(PublishedRecord, tenant: tenant)
    Publication.update!(publication, %{rows_count: published_records_count})
  end

  defp stream_query_or_resource(_query, %{channel: :fast_track, collection: collection}),
    do: Ash.stream!(PublishedRecord, stream_with: :keyset, batch_size: 1000, tenant: collection)

  defp stream_query_or_resource(query, %{channel: :approval}),
    do: Ash.stream!(query, stream_with: :keyset, batch_size: 1000, load: :encoded_record)

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

  defp translate_status(:publishing), do: :approving
  defp translate_status(:in_publication), do: :in_approval
  defp translate_status(:publication_failed), do: :approval_failed

  defp register(%Publication{channel: :approval} = _publication), do: {:ok, nil}

  defp register(%Publication{channel: :fast_track} = publication) do
    Logger.debug("Registering collection: #{publication.collection.id} at GBIF for publishing")
    Collection.register_at_gbif(publication.collection, publication.existing_dataset_key)
  end

  defp publish(%Publication{channel: :approval} = publication, query, _ctx) do
    case InfoSpecies.notify(publication, query) do
      {:ok, publication} ->
        {:ok, publication}

      {:error, error} ->
        Logger.warning("Error while informing infospecies about new available records for review: #{inspect(error)}")

        {:error, error}
    end
  end

  defp publish(%Publication{channel: :fast_track} = publication, _query, ctx) do
    with {:ok, _dataset_key} <-
           Collection.create_endpoint(publication.collection, publication.attachment.url),
         :ok <- queue_records_for_verification(publication.collection, ctx) do
      {:ok, publication}
    end
  end

  @spec queue_records_for_verification(Ash.Query.t(), any()) :: :ok
  defp queue_records_for_verification(collection, %{actor: actor}) do
    PublishedRecord
    |> Ash.stream!(stream_with: :keyset, batch_size: 1000, tenant: collection)
    |> Enum.each(&Record.enqueue_fast_track_checker(&1, nil, actor: actor))
  end
end
