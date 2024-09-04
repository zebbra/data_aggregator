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
      {:ok, gbif_dataset_key}
      |> create_endpoint(dwca_file_url)
      |> maybe_delete_old_endpoints()
    else
      collection_name
      |> register_collection()
      |> create_endpoint(dwca_file_url)
      |> maybe_delete_old_endpoints()
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
          endpoint_key = response.body
          {:ok, registration, endpoint_key}
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

  defp maybe_delete_old_endpoints({:ok, registration, new_endpoint_key}) do
    # get endpoints
    with {:ok, endpoints} <- get_endpoints(registration),
         {:reject_endpoints, old_endpoints} <-
           {:reject_endpoints, Enum.reject(endpoints, &(&1["key"] == new_endpoint_key))},
         {:ok, _} <- delete_endpoints(registration, old_endpoints) do
      {:ok, registration}
    end
  end

  defp maybe_delete_old_endpoints({:error, error}), do: {:error, error}

  defp get_endpoints(registration) do
    with {:ok, resp} <- Gbif.RestAPI.get_endpoints(registration),
         {:status_is_200, 200} <- {:status_is_200, resp.status},
         {:endpoints_is_list, endpoints} when is_list(endpoints) <-
           {:endpoints_is_list, resp.body} do
      {:ok, endpoints}
    else
      {:error, error} ->
        msg = "Error fetching existing endpoints for dataset #{registration}: #{inspect(error)}"
        Logger.error(msg)
        {:error, msg}

      {:status_is_200, status} ->
        msg = "Error fetching existing endpoints for dataset #{registration}: status #{status}"
        Logger.error(msg)
        {:error, msg}

      {:endpoints_is_list, _} ->
        msg =
          "Error fetching existing endpoints for dataset #{registration}: Body is not a list of endpoints"

        Logger.error(msg)
        {:error, msg}
    end
  end

  def delete_endpoints(registration, endpoints) do
    Enum.reduce(endpoints, {:ok, ""}, fn endpoint, {status, errors} = _acc ->
      case Gbif.RestAPI.delete_endpoint(registration, endpoint["key"]) do
        {:ok, _} ->
          Logger.info("Deleted endpoint #{endpoint["key"]} for dataset #{registration}")
          {status, errors}

        {:error, error} ->
          msg =
            "Error deleting endpoint #{endpoint["key"]} for dataset #{registration}: #{inspect(error)}"

          Logger.error(msg)
          {:error, errors <> msg}
      end
    end)
  end
end
