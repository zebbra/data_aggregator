defmodule DataAggregator.Records.Record.Changes.CheckIfFastTrackPublished do
  @moduledoc """
  Checks if a Record has been published on the GBIF portal if yes update the fast_track_status to :published
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Gbif
  alias DataAggregator.Records.Collection

  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    catalog_number = Changeset.get_attribute(changeset, :mte_catalog_number)
    collection_id = Changeset.get_attribute(changeset, :collection_id)

    %{grscicoll_reference: grscicoll_reference} = Collection.get_by_id!(collection_id)

    case check_if_fast_track_published(catalog_number, grscicoll_reference) do
      {:ok, nil} ->
        Logger.debug("Record is not published on GBIF yet. We do nothing.")

        changeset

      {:ok, gbif_id} ->
        changeset
        |> Changeset.change_attribute(:fast_track_status, :published)
        |> Changeset.change_attribute(:occ_occurrence_id, gbif_id)

      {:error, error} ->
        msg =
          "Error while checking if record is published: #{inspect(error)}. Params were: catalog_number: #{catalog_number}, grscicoll_reference: #{grscicoll_reference}"

        Logger.error(msg)

        Changeset.add_error(changeset, message: msg)
    end
  end

  # checks if the record is published on the GBIF portal
  @spec check_if_fast_track_published(String.t(), String.t()) ::
          {:ok, String.t() | nil} | {:error, any()}
  defp check_if_fast_track_published(_catalog_number, nil), do: {:error, "Collection's :grscicoll_reference is missing"}

  defp check_if_fast_track_published(nil, _dataset_key), do: {:error, "Record's :mte_catalog_number is missing"}

  defp check_if_fast_track_published(catalog_number, dataset_key) do
    case Gbif.RestAPI.search_for_occurrences(catalog_number, dataset_key) do
      {:ok, response} ->
        response
        |> verify_api_response()
        |> extract_gbif_id()

      {:error, error} ->
        {:error, error}
    end
  end

  defp verify_api_response(response) do
    cond do
      response.status != 200 ->
        {:error,
         "No valid response (status #{response.status}) from GBIF API while searching for occurrences: #{inspect(response.body)}"}

      Enum.count(response.body["results"]) > 1 ->
        {:error, "More than one occurrence found on GBIF"}

      Enum.empty?(response.body["results"]) ->
        {:ok, nil}

      Enum.count(response.body["results"]) === 1 ->
        {:ok, response}

      true ->
        {:error, "Unknown error while searching for occurrences on GBIF"}
    end
  end

  # get the gbif_id from the response, assuming there is one element on response.body["results"], verified by verify_api_response
  defp extract_gbif_id({:error, error}), do: {:error, error}
  defp extract_gbif_id({:ok, nil}), do: {:ok, nil}

  defp extract_gbif_id({:ok, response}) do
    occurrence = hd(response.body["results"])

    {:ok, occurrence["gbifID"]}
  end
end
