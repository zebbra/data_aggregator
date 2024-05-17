defmodule DataAggregator.Gbif.RestAPI do
  @moduledoc """
  Module to interact with the GBIF Rest API
  """
  alias DataAggregator.Cache.HttpDiskCache

  require Logger

  def register_dataset(collection_name) do
    Req.post(
      url: System.get_env("GBIF_API_BASE_URL") <> "/dataset",
      auth: gbif_auth(),
      json: registration_params(collection_name)
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

  def create_endpoint(file_url, registration) do
    Req.post(
      url: System.get_env("GBIF_API_BASE_URL") <> "/dataset/#{registration}/endpoint",
      auth: gbif_auth(),
      json: endpoint_params(file_url)
    )
  end

  defp endpoint_params(file_url) do
    %{
      "type" => "DWC_ARCHIVE",
      "url" => file_url
    }
  end

  def search_for_occurrences(catalog_number, dataset_key) do
    [params: [{:catalogNumber, catalog_number}, {:datasetKey, dataset_key}]]
    |> Req.new()
    |> HttpDiskCache.attach()
    |> Req.get(
      url: System.get_env("GBIF_API_BASE_URL") <> "/occurrence/search",
      max_cache_age_seconds: 1 * 60 * 60
    )
  end

  @spec get_grscicoll_entity(String.t(), atom()) :: {:ok, any()} | {:error, any()}
  def get_grscicoll_entity(key, kind) do
    req = HttpDiskCache.attach(Req.new())

    url = System.get_env("GBIF_API_BASE_URL") <> "/grscicoll/#{Atom.to_string(kind)}/#{key}"

    # we cache requests for 10 day
    case Req.get(req, url: url, max_cache_age_seconds: 10 * 24 * 60 * 60) do
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

    url = System.get_env("GBIF_API_BASE_URL") <> "/grscicoll/collection/#{reference}"

    case Req.get(req, url: url, max_cache_age_seconds: 1 * 60 * 60) do
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

    url = System.get_env("GBIF_API_BASE_URL") <> "/grscicoll/collection"

    %{body: body} = Req.get!(req, url: url, max_cache_age_seconds: 1 * 60 * 60)

    body["results"]
  end

  def get_species(species_key) do
    req =
      HttpDiskCache.attach(Req.new())

    Req.get(req,
      url: System.get_env("GBIF_API_BASE_URL") <> "/species/" <> species_key,
      max_cache_age_seconds: 30 * 24 * 60 * 60
    )
  end

  def get_matching_species(params) do
    req =
      HttpDiskCache.attach(Req.new(params: params))

    Req.get(req,
      url: System.get_env("GBIF_API_BASE_URL") <> "/species/match",
      max_cache_age_seconds: 30 * 24 * 60 * 60
    )
  end

  defp gbif_auth, do: {:basic, "#{System.get_env("GBIF_USER")}:#{System.get_env("GBIF_PASSWORD")}"}
end
