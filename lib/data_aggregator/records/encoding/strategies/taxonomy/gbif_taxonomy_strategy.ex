defmodule DataAggregator.Records.Encoding.Strategy.GbifTaxonomyStrategy do
  @moduledoc """
    Encode Records with the gbif taxonomy catalog
  """

  import DataAggregator.Helpers, only: [maybe_performant_load_record: 2]

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Gbif
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalog

  require Logger

  # the input attributes are the attributes that will be used to build the request body.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute to be used in the request body
  @input_attributes Catalog.get_input_attributes(:gbif_taxonomy)

  # the output attributes are the attributes that will be updated on the encoded record.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute on the gbif response
  @output_attributes Catalog.get_output_attributes(:gbif_taxonomy)

  # the minimum confidence level to accept a result
  @min_confidence 80

  @doc """
    query the gbif taxanomy api and return the encoded record
  """
  @spec apply_strategy(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  def apply_strategy(encoded_record, ctx) do
    process_encoded_record(encoded_record, ctx)
  end

  @spec process_encoded_record(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  defp process_encoded_record(encoded_record, ctx) do
    with {:ok, params} <- build_request_params(encoded_record),
         {:ok, response} <- fetch_match_api(params),
         {:ok, body} <- parse_response(response),
         {:ok, body} <- parse_response_body(body),
         {:ok, body} <- handle_accepted_usage_key(body),
         {:ok, body} <- handle_synonym(body) do
      encoded_record =
        Strategy.update_encoded_record(body, encoded_record, @output_attributes, ctx)

      {:ok, encoded_record}
    else
      {:error, error} ->
        {:error, error, encoded_record}
    end
  end

  @spec build_request_params(EncodedRecord.t()) :: {:ok, list()}
  defp build_request_params(encoded_record) do
    with {:ok, params} <-
           @input_attributes
           |> Enum.map(&build_request_param(&1, encoded_record))
           |> check_parameters(encoded_record) do
      {:ok, params |> Enum.filter(&(&1 !== nil)) |> Enum.uniq()}
    end
  end

  defp build_request_param({record_attribute, request_attribute}, encoded_record) do
    request_value = Map.get(encoded_record, record_attribute)

    if request_value != nil do
      {request_attribute, request_value}
    end
  end

  @spec fetch_match_api(list()) :: {:ok, Req.Response.t()} | {:error, String.t()}
  defp fetch_match_api(request_params) do
    case Gbif.RestAPI.get_matching_species(request_params) do
      {:ok, response} ->
        {:ok, response}

      {:error, error} ->
        {:error, "[gbif_taxonomy] Error while fetching gbif taxonomy api: #{inspect(error)}"}
    end
  end

  @spec fetch_species_api(String.t()) :: {:ok, Req.Response.t()} | {:error, String.t()}
  defp fetch_species_api(species_key) do
    case Gbif.RestAPI.get_species(species_key) do
      {:ok, response} ->
        {:ok, response}

      {:error, error} ->
        {:error, "[gbif_taxonomy] Error while fetching gbif taxonomy api: #{inspect(error)}"}
    end
  end

  @spec parse_response(Req.Response.t()) :: {:ok, map()} | {:error, String.t()}
  defp parse_response(response) when is_nil(response.status) == false and is_nil(response.body) == false,
    do: {:ok, response.body}

  defp parse_response(response) when is_nil(response.status) or is_nil(response.body),
    do: {:error, "invalid response from gbif taxonomy api: #{inspect(response)}"}

  defp parse_response(response) when response.status != 200,
    do: {:error, "Non 200 response code while fetching gbif taxonomy api: #{inspect(response)}"}

  @spec handle_synonym(map()) :: {:ok, map()} | {:error, String.t()}
  defp handle_synonym(body) when body.synonym == false, do: {:ok, body}

  # if the response is a synonym or if there is no indication of a synonym in the response (body.synonym ),
  # we need to fetch the species api with the usageKey to get the whole, desired taxonomy
  defp handle_synonym(body) do
    with {:ok, response} <- fetch_species_api(body.usageKey),
         {:ok, body} <- parse_response(response) do
      parse_species_api_body(body)
    end
  end

  @spec handle_accepted_usage_key(map()) :: {:ok, map()}
  defp handle_accepted_usage_key(body) do
    case Map.get(body, :acceptedUsageKey, nil) do
      nil -> {:ok, Map.put(body, :acceptedUsageKey, body.usageKey)}
      _ -> {:ok, body}
    end
  end

  @spec parse_species_api_body(map()) :: {:ok, map()}
  defp parse_species_api_body(unparsed_body) do
    {:ok, to_map(unparsed_body)}
  end

  @spec parse_response_body(map()) :: {:ok, map()} | {:error, String.t()}
  defp parse_response_body(unparsed_body) do
    body = to_map(unparsed_body)

    case validate_body(body) do
      {:ok, body} ->
        {:ok, body}

      {:error, error} ->
        {:error, "[gbif_taxonomy] Error while fetching gbif taxonomy api: #{inspect(error)}"}
    end
  end

  defp to_map(data) do
    Map.new(data, fn {key, value} -> {String.to_atom(key), value} end)
  end

  @spec validate_body(map()) :: {:ok, map()} | {:error, any()}
  defp validate_body(body) do
    with :ok <- correct_match_type(body),
         :ok <- confident?(body) do
      {:ok, body}
    end
  end

  @doc ~S"""
    Check if the matchType is correct

    ## Examples
        iex> body = %{status: "ACCEPTED", matchType: "NONE"}
        iex> correct_match_type(body)
        :ok

        iex> body = %{taxonomicStatus: "ACCEPTED", matchType: "SOMETHING"}
        iex> correct_match_type(body)
        :ok

        iex> body = %{matchType: "EXACT"}
        iex> correct_match_type(body)
        :ok

        iex> body = %{matchType: "FUZZY"}
        iex> correct_match_type(body)
        :ok

        iex> body = %{matchType: "something"}
        iex> correct_match_type(body)
        {:error, "For this species name we could not find a matching taxonomy. matchType \"something\" is not accepted"}

        iex> body = %{matchType: "HIGHERRANK", kingdom: "Animalia"}
        iex> correct_match_type(body)
        :ok

        iex> body = %{matchType: "HIGHERRANK"}
        iex> correct_match_type(body)
        :ok

        iex> body = %{matchType: "HIGHERRANK", rank: "SPECIES"}
        iex> correct_match_type(body)
        :ok

        iex> body = %{matchType: "HIGHERRANK", rank: "PHYLUM"}
        iex> correct_match_type(body)
        {:error, "For this species name we could not find a matching taxonomy. Only results in HIGHERRANK (rank \"PHYLUM\")"}

        iex> body = %{matchType: "HIGHERRANK", rank: "KINGDOM"}
        iex> correct_match_type(body)
        {:error, "For this species name we could not find a matching taxonomy. Only results in HIGHERRANK (rank \"KINGDOM\")"}

        iex> body = %{matchType: "NONE"}
        iex> correct_match_type(body)
        {:error, "For this species name we could not find a matching taxonomy. matchType \"NONE\" is not accepted"}

        iex> body = %{matchType: "blabla"}
        iex> correct_match_type(body)
        {:error, "For this species name we could not find a matching taxonomy. matchType \"blabla\" is not accepted"}

  """
  @spec correct_match_type(map()) :: :ok | {:error, String.t()}
  def correct_match_type(body) when body.status == "ACCEPTED", do: :ok
  def correct_match_type(body) when body.taxonomicStatus == "ACCEPTED", do: :ok
  def correct_match_type(body) when body.matchType == "EXACT", do: :ok
  def correct_match_type(body) when body.matchType == "FUZZY", do: :ok

  def correct_match_type(body) when body.matchType == "HIGHERRANK" and (body.rank == "PHYLUM" or body.rank == "KINGDOM"),
    do:
      {:error,
       "For this species name we could not find a matching taxonomy. Only results in HIGHERRANK (rank #{inspect(body.rank)})"}

  def correct_match_type(body) when body.matchType == "HIGHERRANK" do
    :ok
  end

  def correct_match_type(body),
    do:
      {:error,
       "For this species name we could not find a matching taxonomy. matchType #{inspect(body.matchType)} is not accepted"}

  # the gbif api returns a confidence value between 0 and 100,
  # we accept items only if the confidence is >= @min_confidence
  @spec confident?(map()) :: :ok | {:error, String.t()}
  defp confident?(body) when body.confidence >= @min_confidence, do: :ok

  defp confident?(body) when body.confidence < @min_confidence,
    do:
      {:error,
       "For this species name we could not find a matching taxonomy. response value #{inspect(body)} is not confident (min #{@min_confidence}) enough"}

  @spec check_parameters(list(), map()) :: {:ok, list()} | {:error, String.t()}
  defp check_parameters(params, encoded_record) do
    tenant = encoded_record.collection_id
    encoded_record = maybe_performant_load_record(encoded_record, tenant)
    record = Ash.load!(encoded_record.record, [:collection], lazy?: true, tenant: tenant)

    add_kingdom_fallback(params, record)
  end

  # if no taxon attributes were found on the record, we try to add at least the kingdom
  # from the collection as fallback, if this was also not found we return an empty list
  @spec add_kingdom_fallback(list(), EncodedRecord.t()) :: {:ok, list()} | {:error, String.t()}
  defp add_kingdom_fallback(params, record) do
    cond do
      params !== [] ->
        {:ok, params}

      record.collection.type === :zoology ->
        {:ok, [kingdom: "Animalia"]}

      record.collection.type === :botany ->
        {:ok, [kingdom: "Plantae"]}

      true ->
        msg =
          "[gbif_taxonomy] No fallback kingdom found for record #{record.id} on the collection #{record.collection.name}"

        Logger.warning(msg)

        {:error, msg}
    end
  end
end
