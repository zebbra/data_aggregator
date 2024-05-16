defmodule DataAggregator.Records.Record.Changes.CheckIfFastTrackPublished do
  @moduledoc """
  Checks if a Record has been published on the GBIF portal if yes update the fast_track_status to :published
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Cache.HttpDiskCache
  alias DataAggregator.Records.Collection

  require Logger

  # TODO: make a test! now!
  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    catalog_number = Changeset.get_attribute(changeset, :mte_catalog_number)
    collection_id = Changeset.get_attribute(changeset, :collection_id)

    %{grscicoll_reference: grscicoll_reference} = Collection.get_by_id!(collection_id)

    case catalog_number do
      nil ->
        {:error, "Catalog number is missing"}

      _ ->
        case check_if_fast_track_published(catalog_number, grscicoll_reference) do
          {:ok, true} ->
            Changeset.change_attribute(changeset, :fast_track_status, :published)

          {:ok, false} ->
            Logger.debug("Record is not published on GBIF yet. We do nothing.")

          {:error, error} ->
            msg = "Error while checking if record is published #{inspect(error)}"
            Logger.error(msg)

            Changeset.add_error(changeset, message: msg)
        end
    end
  end

  @doc """
  checks if the record is published on the GBIF portal
  """
  @spec check_if_fast_track_published(String.t(), String.t()) ::
          {:ok, boolean()} | {:error, any()}
  def check_if_fast_track_published(catalog_number, dataset_key) do
    req =
      HttpDiskCache.attach(Req.new(params: [catalogNumber: catalog_number, datasetKey: dataset_key]))

    case Req.get(req, url: System.get_env("GBIF_OCCURRENCE_URL"), max_cache_age_seconds: 1 * 60) do
      {:ok, response} ->
        {:ok, Enum.empty?(response.body["results"])}

      {:error, error} ->
        {:error, error}
    end
  end
end
