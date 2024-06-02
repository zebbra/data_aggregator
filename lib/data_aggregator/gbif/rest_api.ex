defmodule DataAggregator.Gbif.RestAPI do
  @moduledoc """
  Module to interact with the GBIF Rest API
  """
  import DataAggregator.Api.Helpers

  alias DataAggregator.Cache.HttpDiskCache
  alias DataAggregator.Types.Api

  require Logger

  @hour 60 * 60
  @day 24 * @hour
  @month 30 * @day

  @spec register_dataset(String.t()) :: Api.response()
  def register_dataset(collection_name) do
    Req.post(
      url: register_dataset_url(),
      auth: gbif_auth(),
      json: registration_params(collection_name)
    )
  end

  @spec create_endpoint(String.t(), String.t()) :: Api.response()
  def create_endpoint(file_url, registration) do
    Req.post(
      url: create_endpoint_url(registration),
      auth: gbif_auth(),
      json: endpoint_params(file_url)
    )
  end

  @spec search_for_occurrences(String.t(), String.t()) ::
          Api.response()
  def search_for_occurrences(catalog_number, dataset_key) do
    [params: [{:catalogNumber, catalog_number}, {:datasetKey, dataset_key}]]
    # TODO: extract attaching cache (and other middlewres) to separate helper
    #  module (DataAggregator.Api.Helpers) to have it resusable and not
    #  poluting all api client functions
    |> Req.new()
    |> HttpDiskCache.attach()
    |> Req.get(
      url: search_occurrence_url(),
      max_cache_age_seconds: @hour
    )
  end

  @spec get_grscicoll_entity(String.t(), atom()) :: Api.response_body()
  def get_grscicoll_entity(key, kind) do
    req = HttpDiskCache.attach(Req.new())

    url = grscicoll_entity_by_key_url(key, kind)

    case Req.get(req, url: url, max_cache_age_seconds: 10 * @day) do
      {:ok, response} ->
        if response.status == 200 do
          {:ok, response.body}
        else
          {:error, "No valid response (status #{response.status}) from GrSciColl api"}
        end

      {:error, error} ->
        {:error, "Error during call of GrSciColl api: #{inspect(error)}"}
    end
  end

  @spec get_grscicoll_attributes(String.t(), [String.t()]) :: Api.response_body()
  def get_grscicoll_attributes(reference, attributes) do
    with {:ok, collection} <- get_single_collection(reference) do
      {:ok, Map.take(collection, attributes)}
    end
  end

  @spec get_collection_options() :: [{String.t(), String.t()}]
  def get_collection_options do
    Enum.map(lookup_all_collections(), &{"#{&1["code"]} - #{&1["name"]}", &1["key"]})
  end

  @spec get_species(String.t()) :: Api.response()
  def get_species(species_key) do
    req = HttpDiskCache.attach(Req.new())

    Req.get(req,
      url: gbif_base_url() <> "/species/#{species_key}",
      max_cache_age_seconds: @month
    )
  end

  @spec get_matching_species(Api.params()) ::
          Api.response()
  def get_matching_species(params) do
    req =
      HttpDiskCache.attach(Req.new(params: params))

    Req.get(req,
      url: gbif_base_url() <> "/species/match",
      max_cache_age_seconds: @month
    )
  end

  defp registration_params(collection_name) do
    %{
      "title" => collection_name,
      "type" => "OCCURRENCE",
      "installationKey" => System.get_env("GBIF_INSTALLATION_KEY"),
      "publishingOrganizationKey" => System.get_env("GBIF_ORGANIZATION_KEY"),
      "language" => "eng"
    }
  end

  defp endpoint_params(file_url) do
    %{
      "type" => "DWC_ARCHIVE",
      "url" => file_url
    }
  end

  defp get_single_collection(reference) do
    url = grscicoll_entity_by_key_url(reference, :collection)

    with {:ok, response} <-
           [params: %{country: "CH", limit: 1000}]
           |> Req.new()
           |> HttpDiskCache.attach()
           |> Req.get(url: url, max_cache_age_seconds: @hour)
           |> ensure_response(reference),
         :ok <- ensure_status(response) do
      {:ok, response |> Map.from_struct() |> Map.get(:body)}
    end
  end

  defp ensure_response({:ok, response}, _), do: {:ok, response}

  defp ensure_response({:error, error}, reference) do
    msg =
      "Could not fetch GrSciColl collection for reference #{reference}. error was: #{inspect(error)}"

    Logger.error(msg)

    {:error, msg}
  end

  defp ensure_status(response) when response.status == 200, do: :ok

  defp ensure_status(response) do
    msg = "Non 200 status code from GrSciColl api with message: #{inspect(response)}"

    Logger.error(msg)

    {:error, msg}
  end

  defp lookup_all_collections do
    url = grscicoll_entities_url(:collection)

    %{body: body} =
      [params: %{country: "CH", limit: 1000}]
      |> Req.new()
      |> HttpDiskCache.attach()
      |> Req.get!(url: url, max_cache_age_seconds: @hour)

    body["results"]
  end
end
