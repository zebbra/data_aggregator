defmodule DataAggregator.Gbif.GrSciColl do
  @moduledoc false

  alias DataAggregator.Cache.HttpDiskCache

  require Logger

  @spec get_grscicoll_attributes(String.t(), list()) :: {:ok, map()} | {:error, any()}
  def get_grscicoll_attributes(reference, attributes) do
    with {:ok, collection} <- get_single_collection(reference) do
      {:ok, Map.take(collection, attributes)}
    end
  end

  @spec get_collection_options() :: list()
  def get_collection_options do
    Enum.map(lookup_all_collections(), &{"#{&1["code"]} - #{&1["name"]}", &1["key"]})
  end

  defp get_single_collection(reference) do
    req = HttpDiskCache.attach(Req.new(params: %{country: "CH", limit: 1000}))

    url = "https://api.gbif.org/v1/grscicoll/collection/#{reference}"

    case Req.get(req, url: url, max_cache_age_seconds: 60 * 60) do
      {:ok, result} ->
        body =
          result |> Map.from_struct() |> Map.get(:body)

        case result.status do
          200 ->
            {:ok, body}

          _ ->
            {:error, body}
        end

      {:error, error} ->
        Logger.error("Could not fetch GrSciColl collection for reference #{reference}. error was: #{inspect(error)}")

        {:error, error}
    end
  end

  @spec lookup_all_collections() :: list()
  defp lookup_all_collections do
    req = HttpDiskCache.attach(Req.new(params: %{country: "CH", limit: 1000}))

    url = "https://api.gbif.org/v1/grscicoll/collection"

    %{body: body} = Req.get!(req, url: url, max_cache_age_seconds: 60 * 60)

    body["results"]
  end
end
