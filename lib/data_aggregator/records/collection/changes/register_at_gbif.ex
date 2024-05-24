defmodule DataAggregator.Records.Collection.Changes.RegisterAtGbif do
  @moduledoc """
  Registers a Collection via the gbif Rest API to make it available for publishing.

  according to the example provided by gbif https://github.com/gbif/registry/blob/master/registry-examples/src/test/scripts/register.sh
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Gbif

  require Logger

  @type registered_collection :: {:ok, String.t()} | {:error, String.t()}

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    dwca_file_url = Changeset.get_argument(changeset, :dwca_file_url)
    collection_name = Changeset.get_attribute(changeset, :name)
    gbif_dataset_key = Changeset.get_attribute(changeset, :gbif_dataset_key)

    case register_at_gbif(gbif_dataset_key, collection_name, dwca_file_url) do
      {:ok, dataset_key} ->
        Changeset.change_attribute(changeset, :gbif_dataset_key, to_string(dataset_key))

      {:error, error} ->
        Changeset.add_error(changeset, message: error)
    end
  end

  @spec register_at_gbif(String.t() | nil, String.t(), String.t()) ::
          registered_collection()
  defp register_at_gbif(_gbif_dataset_key, nil, _dwca_file_url), do: {:error, "Collection name is missing"}

  defp register_at_gbif(gbif_dataset_key, collection_name, dwca_file_url) do
    if gbif_dataset_key do
      create_endpoint({:ok, gbif_dataset_key}, dwca_file_url)
    else
      collection_name
      |> register_collection()
      |> create_endpoint(dwca_file_url)
    end
  end

  @spec register_collection(String.t()) :: registered_collection()
  defp register_collection(collection_name) do
    with {:ok, response} <-
           collection_name |> Gbif.RestAPI.register_dataset() |> ensure_response(collection_name),
         :ok <- ensure_status(response) do
      {:ok, response.body}
    end
  end

  defp ensure_response({:ok, response}, _), do: {:ok, response}

  defp ensure_response({:error, error}, collection_name) do
    msg = "Error during collection registering: #{inspect(collection_name)}, #{inspect(error)}"

    Logger.error(msg)

    {:error, msg}
  end

  defp ensure_status(response) when response.status == 201, do: :ok

  defp ensure_status(response) do
    msg =
      "No valid response (status #{response.status}) from Gibif api while registering dataset with response: #{inspect(response.body)}"

    Logger.error(msg)

    {:error, msg}
  end

  defp create_endpoint({:ok, registration}, file_url) do
    case Gbif.RestAPI.create_endpoint(file_url, registration) do
      {:ok, response} ->
        if response.status == 201 do
          # within response.body we should have the endpoint key, but we don't need it for now, so we just
          # return the registration key for storing on the collection
          {:ok, registration}
        else
          msg =
            "No valid response (status #{response.status}) from Gibif api while creating endpoint with response: #{inspect(response.body)}"

          Logger.error(msg)
          {:error, msg}
        end

      {:error, error} ->
        {:error, "Error during endpoint creation with: #{inspect([file_url, registration])}, #{inspect(error)}"}
    end
  end

  defp create_endpoint({:error, error}, _), do: {:error, error}
end
