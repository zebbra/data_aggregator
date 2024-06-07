defmodule DataAggregator.Gbif.RestAPI do
  @moduledoc """
  Module to interact with the GBIF Rest API
  """
  import DataAggregator.Api.Helpers

  alias DataAggregator.Cache.HttpDiskCache
  alias DataAggregator.Types.Api

  require Logger

  @minute 60
  @hour 60 * @minute
  @day 24 * @hour
  @month 30 * @day

  @doc """
  Register a dataset with the GBIF API
  """
  @spec register_dataset(String.t()) :: Api.response()
  def register_dataset(collection_name) do
    Req.post(
      url: register_dataset_url(),
      auth: gbif_auth(),
      json: registration_params(collection_name)
    )
  end

  @doc """
  Create an endpoint for a dataset with the GBIF API and returns the endpoint key
  """
  @spec create_endpoint(String.t(), String.t()) :: Api.response()
  def create_endpoint(file_url, registration) do
    Req.post(
      url: create_endpoint_url(registration),
      auth: gbif_auth(),
      json: endpoint_params(file_url)
    )
  end

  @doc """
  Search for occurrences in the GBIF API. Returns a list of occurrences.
  """
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

  @doc """
  Get a single entity (collection or institution) from the GrSciColl API, according to its key
  """
  @spec get_grscicoll_entity(String.t(), atom()) :: Api.response_body()
  def get_grscicoll_entity(key, kind) do
    req = HttpDiskCache.attach(Req.new())

    url = grscicoll_entity_by_key_url(key, kind)

    case Req.get(req, url: url, max_cache_age_seconds: 10 * @minute) do
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

  @doc """
  Get a single collection from the GrSciColl API, according to its key. Returns only the specified attributes.
  """
  @spec get_grscicoll_collection_attributes(String.t(), [String.t()]) :: Api.response_body()
  def get_grscicoll_collection_attributes(reference, attributes) do
    with {:ok, collection} <- get_one_collection(reference) do
      {:ok, Map.take(collection, attributes)}
    end
  end

  @doc """
  Get all collections from the GrsciCol API and parse them to have options for UI Select Options
  """
  @spec get_collection_options() :: [{String.t(), String.t()}]
  def get_collection_options do
    Enum.map(lookup_all_collections(), &{"#{&1["code"]} - #{&1["name"]}", &1["key"]})
  end

  @doc """
  Get a single species out of the GBIF API according to its key
  """
  @spec get_species(String.t()) :: Api.response()
  def get_species(species_key) do
    req = HttpDiskCache.attach(Req.new())

    Req.get(req,
      url: gbif_base_url() <> "/species/#{species_key}",
      max_cache_age_seconds: @month
    )
  end

  @doc """
  Get a list of species matching the given parameters from the GBIF API
  """
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

  @doc """
  Get one collection from the GrSciColl API, according to its key
  """
  @spec get_one_collection(String.t()) :: Api.response_body()
  def get_one_collection(reference) do
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
