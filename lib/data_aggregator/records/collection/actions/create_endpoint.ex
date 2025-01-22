defmodule DataAggregator.Records.Collection.Actions.CreateEndpoint do
  @moduledoc """
  Custom action to create an endpoint on gbif in the publication process.
  This will create an endpoint on the dataset defined on the collection, with the dwca file url.
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Gbif

  require Logger

  @impl true
  def run(input, _opts, _ctx) do
    collection = input.arguments.collection
    file_url = input.arguments.dwca_file_url

    Logger.debug("Creating endpoint for collection #{collection.id} with file url: #{file_url}")

    collection.gbif_dataset_key
    |> create_endpoint(file_url)
    |> delete_old_endpoints()
  end

  defp create_endpoint(nil, _file_url), do: {:error, "Dataset key is missing"}
  defp create_endpoint(_dataset_key, nil), do: {:error, "Dwca file url is missing"}

  defp create_endpoint(dataset_key, file_url) do
    case Gbif.RestAPI.create_endpoint(file_url, dataset_key) do
      {:ok, response} ->
        if response.status == 201 do
          endpoint_key = response.body
          {:ok, dataset_key, endpoint_key}
        else
          msg =
            "No valid response (status #{response.status}) from Gibif api while creating endpoint with response: #{inspect(response.body)}"

          Logger.error(msg)
          {:error, msg}
        end

      {:error, error} ->
        {:error, "Error during endpoint creation with: #{inspect([file_url, dataset_key])}, #{inspect(error)}"}
    end
  end

  defp delete_old_endpoints({:error, error}), do: {:error, error}

  defp delete_old_endpoints({:ok, dataset_key, new_endpoint_key}) do
    with {:ok, endpoints} <- get_endpoints(dataset_key),
         {:reject_endpoints, old_endpoints} <-
           {:reject_endpoints, Enum.reject(endpoints, &(&1["key"] == new_endpoint_key))},
         {:ok, _} <- delete_endpoints(dataset_key, old_endpoints) do
      {:ok, dataset_key}
    end
  end

  defp get_endpoints(dataset_key) do
    with {:ok, resp} <- Gbif.RestAPI.get_endpoints(dataset_key),
         {:status_is_200, 200} <- {:status_is_200, resp.status},
         {:endpoints_is_list, endpoints} when is_list(endpoints) <-
           {:endpoints_is_list, resp.body} do
      {:ok, endpoints}
    else
      {:error, error} ->
        msg = "Error fetching existing endpoints for dataset #{dataset_key}: #{inspect(error)}"
        Logger.error(msg)
        {:error, msg}

      {:status_is_200, status} ->
        msg = "Error fetching existing endpoints for dataset #{dataset_key}: status #{status}"
        Logger.error(msg)
        {:error, msg}

      {:endpoints_is_list, _} ->
        msg =
          "Error fetching existing endpoints for dataset #{dataset_key}: Body is not a list of endpoints"

        Logger.error(msg)
        {:error, msg}
    end
  end

  defp delete_endpoints(dataset_key, endpoints) do
    Enum.reduce(endpoints, {:ok, ""}, fn endpoint, {status, errors} = _acc ->
      case Gbif.RestAPI.delete_endpoint(dataset_key, endpoint["key"]) do
        {:ok, _} ->
          Logger.info("Deleted endpoint #{endpoint["key"]} for dataset #{dataset_key}")
          {status, errors}

        {:error, error} ->
          msg =
            "Error deleting endpoint #{endpoint["key"]} for dataset #{dataset_key}: #{inspect(error)}"

          Logger.error(msg)
          {:error, errors <> msg}
      end
    end)
  end
end
