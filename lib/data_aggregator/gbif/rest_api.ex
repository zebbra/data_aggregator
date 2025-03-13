defmodule DataAggregator.Gbif.RestAPI do
  @moduledoc """
  Module to interact with the GBIF Rest API
  """
  import DataAggregator.Accounts.Helpers, only: [has_role?: 2]
  import DataAggregator.Api.Helpers
  import DataAggregator.Helpers, only: [distinct: 2]

  alias DataAggregator.Accounts.User
  alias DataAggregator.Cache.HttpDiskCache
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.Validation
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
  def register_dataset(dataset_name) do
    Req.post(
      url: register_dataset_url(),
      auth: gbif_auth(),
      json: registration_params(dataset_name)
    )
  end

  @doc """
  Get details of a single dataset
  """
  @spec get_dataset(String.t()) :: Api.response()
  def get_dataset(dataset_key) do
    Req.get(url: get_dataset_url(dataset_key), auth: gbif_auth())
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
  Get the endpoints for a dataset with the GBIF API
  """
  @spec get_endpoints(String.t()) :: Api.response()
  def get_endpoints(registration) do
    Req.get(url: create_endpoint_url(registration), auth: gbif_auth())
  end

  @doc """
  Delete a specific endpoint with the given endpoint_key for a dataset with the GBIF API
  """
  @spec delete_endpoint(String.t(), String.t()) :: Api.response()
  def delete_endpoint(registration, endpoint_key) do
    Req.delete(
      url: create_endpoint_url(registration) <> "/" <> to_string(endpoint_key),
      auth: gbif_auth()
    )
  end

  @doc """
  Search for occurrences in the GBIF API. Returns a list of occurrences.
  """
  @spec search_for_occurrences(String.t(), String.t()) :: Api.response()
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
  @spec get_grscicoll_entity(String.t(), :collection | :institution | :dataset) ::
          Api.response_body()
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
  @spec get_collection_options() :: [{String.t(), String.t(), String.t()}]
  def get_collection_options do
    Enum.map(
      lookup_all_collections(),
      &{"#{&1["code"]} - #{&1["name"]}", &1["key"], &1["institutionKey"]}
    )
  end

  @doc """
  Get all available collections from the GrsciCol API and parse them to have options for
  UI Select Options.

  Available collections are collections that are not already in use in the database.
  """
  @spec get_available_collection_options(User.t()) :: [{String.t(), String.t()}]
  def get_available_collection_options(actor) do
    collections_in_use = distinct(Collection, :grscicoll_reference)

    get_collection_options()
    |> maybe_restrict_to_institution(actor, collections_in_use)
    |> Enum.map(fn {name, key, _} -> {name, key} end)
  end

  defp maybe_restrict_to_institution(collections, actor, collections_in_use) do
    if has_role?(actor, "admin") do
      Enum.reject(collections, fn {_, key, _} ->
        key in collections_in_use
      end)
    else
      Enum.reject(collections, fn {_, key, institution_key} ->
        institution_key != actor.institution_id or key in collections_in_use
      end)
    end
  end

  @doc """
  Get all institutions from the GrsciCol API and parse them to have options for UI Select Options
  """
  @spec get_institution_options() :: [{String.t(), String.t()}]
  def get_institution_options do
    Enum.map(lookup_all_institutions(), &{"#{&1["code"]} - #{&1["name"]}", &1["key"]})
  end

  @doc """
  Get one institution from the GrsciCol Api and parse it to have options for UI Select Options
  """
  @spec get_institution_option(String.t()) :: {String.t(), String.t()}
  def get_institution_option(id) do
    {:ok, institution} = get_grscicoll_entity(id, :institution)
    {"#{institution["code"]} - #{institution["name"]}", institution["key"]}
  end

  @doc """
  Get a single species out of the GBIF API according to its key
  """
  @spec get_species(String.t()) :: Api.response()
  def get_species(species_key) do
    req = HttpDiskCache.attach(Req.new())

    Req.get(req,
      url: gbif_api_base_url() <> "/species/#{species_key}",
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
      url: gbif_api_base_url() <> "/species/match",
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

  @doc """
  Get one institution from the GrSciColl API, according to its key
  """
  @spec get_one_institution(String.t()) :: Api.response_body()
  def get_one_institution(reference) do
    url = grscicoll_entity_by_key_url(reference, :institution)

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

  @doc """
  Get the IUCN Redlist category from the GBIF API for a given key
  """
  @spec get_iucn_redlist_category(String.t()) :: Api.response()
  def get_iucn_redlist_category(key) do
    req = HttpDiskCache.attach(Req.new())

    Req.get(req,
      url: gbif_api_base_url() <> "/species/" <> key <> "/iucnRedListCategory",
      max_cache_age_seconds: @month
    )
  end

  @doc """
  We notify infospecies about the processed validation and its result
  """
  @spec notify_infospecies_with_validation_result(Validation.t()) :: Api.response()
  def notify_infospecies_with_validation_result(validation) do
    Logger.info("Notifying infospecies about validation result")

    Req.post(
      url: infospecies_validation_notification_url(),
      json: notify_infospecies_with_validation_result_params(validation)
    )
  end

  @spec notify_infospecies_with_validation_result_params(Validation.t()) :: map()
  defp notify_infospecies_with_validation_result_params(%Validation{error_log_id: nil} = validation),
    do: %{
      "source_file" => validation.file_url,
      "success_count" => validation.rows_validated_count,
      "error_count" => validation.rows_invalid_count,
      "error_log_url" => ""
    }

  @spec notify_infospecies_with_validation_result_params(Validation.t()) :: map()
  defp notify_infospecies_with_validation_result_params(validation) do
    validation = Ash.load!(validation, [:error_log], lazy?: true)
    error_log = Ash.load!(validation.error_log, [:url], lazy?: true)

    %{
      "success_count" => validation.rows_validated_count,
      "error_count" => validation.rows_invalid_count,
      "error_log_url" => error_log.url
    }
  end

  defp registration_params(dataset_name) do
    %{
      "title" => dataset_name,
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

    Logger.warning(msg)

    {:error, msg}
  end

  defp ensure_status(response) when response.status == 200, do: :ok

  defp ensure_status(response) do
    msg = "Non 200 status code from GrSciColl api with message: #{inspect(response)}"

    Logger.info(msg)

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

  def lookup_all_institutions do
    url = grscicoll_entities_url(:institution)

    %{body: body} =
      [params: %{country: "CH", limit: 1000}]
      |> Req.new()
      |> HttpDiskCache.attach()
      |> Req.get!(url: url, max_cache_age_seconds: @hour)

    body["results"]
  end
end
