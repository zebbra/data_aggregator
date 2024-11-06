defmodule DataAggregator.Records.Actions.Publish do
  @moduledoc """
  Custom action to publish records of a collection through the fast track as DarwinCoreArchive (dwca) file.
  """

  use Ash.Resource.Actions.Implementation

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.DarwinCore.Publication.CoreFile
  alias DataAggregator.DarwinCore.Publication.EmlFile
  alias DataAggregator.DarwinCore.Publication.MaterialSampleFile
  alias DataAggregator.DarwinCore.Publication.MetaFile
  alias DataAggregator.DarwinCore.Publication.PreservationFile
  alias DataAggregator.DarwinCore.Publication.ReleveFile
  alias DataAggregator.Misc.FlatFileUtils
  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Publication.InfoSpecies
  alias DataAggregator.Records.Record

  require Ash.Query
  require Logger

  @impl true
  def run(input, _opts, %{tenant: tenant} = ctx) do
    publication = input.arguments.publication

    query =
      Record
      |> AshPagify.query_for_filters_map(publication.records_query)
      |> Ash.Query.set_tenant(tenant)

    set_publication_status(
      query,
      :publishing,
      publication,
      ctx
    )

    path = FlatFileUtils.create_directory!("publication_#{publication.channel}")

    CoreFile.create(query, path, tenant)

    EmlFile.create(publication.collection, path, tenant)

    MaterialSampleFile.create(query, path, tenant)
    PreservationFile.create(query, path, tenant)
    ReleveFile.create(query, path, tenant)

    MetaFile.create(publication.collection, path, tenant)

    # TODO: implement the following files, they contain of attributes from json fields,
    # and therefore need to be implemented in a different way

    # ChronometricAgeFile.create(query, path, tenant)
    # DistributionFile.create(query, path, tenant)
    # PermitFile.create(query, path, tenant)
    # ReferencesFile.create(query, path, tenant)
    # ResourceRelationshipFile.create(query, path, tenant)
    # SpeciesProfileFile.create(query, path, tenant)
    # VernacularNamesFile.create(query, path, tenant)

    attachment = path |> FlatFileUtils.create_zip!() |> FlatFileUtils.store_on_s3!()

    # remove file from local tmp dir, as it is now stored on s3
    File.rm_rf(path)

    set_publication_status(
      query,
      :in_publication,
      publication,
      ctx
    )

    publication =
      publication
      |> Publication.update_attachment(attachment)
      |> Ash.load!([:collection, :attachment])

    case register(publication, query) do
      {:ok, publication} ->
        {:ok, publication}

      {:error, error} ->
        Logger.error("Error publishing records on the #{publication.channel} channel: #{inspect(error)}")

        set_publication_status(
          query,
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

      set_publication_status(
        query,
        :publication_failed,
        publication,
        ctx
      )

      {:error, e}
  end

  @spec queue_records_for_verification(Ash.Query.t()) :: :ok
  defp queue_records_for_verification(query) do
    query
    |> Ash.stream!(page: false)
    |> Enum.each(&Record.enqueue_fast_track_checker/1)
  end

  @spec set_publication_status(Ash.Query.t(), atom(), Publication.t(), Context.t()) :: :ok
  defp set_publication_status(query, status, publication, ctx) do
    query
    |> Ash.stream!(page: false)
    |> Enum.each(&update_record!(&1, status, publication, ctx))
  end

  @spec update_record!(Record.t(), atom(), Publication.t(), Context.t()) :: any()
  defp update_record!(record, status, publication, ctx) do
    maybe_add_publication_progress!(publication, status)

    update_status!(publication.channel, status, record, ctx)
  end

  defp maybe_add_publication_progress!(publication, state) when state in [:in_publication, :publication_failed] do
    if Records.execute_async?() do
      Task.start(fn -> Publication.add_publication_progress!(publication, 1) end)
    else
      Publication.add_publication_progress!(publication, 1)
    end
  end

  defp maybe_add_publication_progress!(_, _), do: :ok

  defp update_status!(:fast_track, status, record, %{actor: actor}),
    do: Record.update_fast_track_status!(record, status, actor: actor, authorize?: false)

  defp update_status!(:approval, status, record, %{actor: actor}),
    do: Record.update_approval_status!(record, translate_status(status), actor: actor, authorize?: false)

  defp translate_status(:publishing), do: :approving
  defp translate_status(:in_publication), do: :in_approval
  defp translate_status(:publication_failed), do: :approval_failed

  defp register(%Publication{channel: :approval} = publication, query) do
    case InfoSpecies.notify(publication, query) do
      {:ok, publication} ->
        {:ok, publication}

      {:error, error} ->
        Logger.warning("Error while informing infospecies about new available records for review: #{inspect(error)}")

        {:error, error}
    end
  end

  defp register(%Publication{channel: :fast_track} = publication, query) do
    with {:ok, _collection} <-
           Collection.register_at_gbif(publication.collection, publication.attachment.url),
         :ok <- queue_records_for_verification(query) do
      {:ok, publication}
    end
  end
end
