defmodule DataAggregator.Records.Collection.Changes.RegisterAtGbif do
  @moduledoc """
  Registers a Collection via the gbif Rest API to make it available for publishing.
  Updates the collection with the gbif dataset key and DOI.

  according to the example provided by gbif https://github.com/gbif/registry/blob/master/registry-examples/src/test/scripts/register.sh
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Gbif

  require Logger

  @type registered_collection :: {:ok, String.t()} | {:error, String.t()}

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    existing_dataset_key = Changeset.get_argument(changeset, :existing_dataset_key)
    gbif_dataset_key = Changeset.get_attribute(changeset, :gbif_dataset_key)

    dataset_name =
      dataset_name(
        Changeset.get_attribute(changeset, :name),
        Changeset.get_attribute(changeset, :code),
        Changeset.get_attribute(changeset, :grscicoll_institution_name)
      )

    with {:ok, dataset_key} <-
           register_at_gbif(gbif_dataset_key, dataset_name, existing_dataset_key),
         {:ok, gbif_doi} <- get_gbif_doi(dataset_key) do
      Logger.debug("Dataset registered with key: #{dataset_key}")

      changeset
      |> Changeset.change_attribute(:gbif_dataset_key, to_string(dataset_key))
      |> Changeset.change_attribute(:gbif_doi, to_string(gbif_doi))
    else
      {:error, error} ->
        Changeset.add_error(changeset, message: error)
    end
  end

  defp dataset_name(nil, _collection_code, _institution_name) do
    Logger.debug("Dataset name is missing")
    nil
  end

  defp dataset_name(_collection_name, nil, _institution_name) do
    Logger.debug("Collection code is missing")
    nil
  end

  defp dataset_name(_collection_name, _collection_code, nil) do
    Logger.debug("Institution code is missing")
    nil
  end

  defp dataset_name(collection_name, collection_code, institution_name) do
    "#{collection_name} (#{collection_code}) of #{institution_name}"
  end

  @spec register_at_gbif(String.t() | nil, String.t(), String.t() | nil) ::
          registered_collection()
  defp register_at_gbif(_gbif_dataset_key, nil, _existing_dataset_key), do: {:error, "Dataset name is missing"}

  defp register_at_gbif(gbif_dataset_key, dataset_name, existing_dataset_key) do
    cond do
      gbif_dataset_key ->
        Logger.debug("This collection is already registered with dataset key: #{gbif_dataset_key}, do nothing")

        {:ok, gbif_dataset_key}

      existing_dataset_key ->
        Logger.debug(
          "This colleciton does not have a dataset key. We use an existing dataset key instead of registering this collection"
        )

        {:ok, existing_dataset_key}

      true ->
        Logger.debug("This collection does not have a dataset key. We need to register it first")

        register_collection(dataset_name)
    end
  end

  defp get_gbif_doi(dataset_key) do
    with {:ok, response} <- Gbif.RestAPI.get_dataset(dataset_key),
         :ok <- ensure_status(response) do
      {:ok, response.body["doi"]}
    end
  end

  @spec register_collection(String.t()) :: registered_collection()
  defp register_collection(dataset_name) do
    with {:ok, response} <-
           dataset_name |> Gbif.RestAPI.register_dataset() |> ensure_response(dataset_name),
         :ok <- ensure_status(response) do
      {:ok, response.body}
    end
  end

  defp ensure_response({:ok, response}, _), do: {:ok, response}

  defp ensure_response({:error, error}, dataset_name) do
    msg = "Error during collection registering: #{inspect(dataset_name)}, #{inspect(error)}"

    Logger.error(msg)

    {:error, msg}
  end

  defp ensure_status(response) when response.status == 201, do: :ok
  defp ensure_status(response) when response.status == 200, do: :ok

  defp ensure_status(response) do
    msg =
      "No valid response (status #{response.status}) from Gibif api while registering dataset with response: #{inspect(response.body)}"

    Logger.error(msg)

    {:error, msg}
  end
end
