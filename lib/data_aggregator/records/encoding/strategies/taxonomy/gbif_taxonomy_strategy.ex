defmodule DataAggregator.Records.Encoding.Strategy.GbifTaxonomyStrategy do
  @moduledoc """
    Encode Records with the gbif taxonomy catalog
  """

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
  @spec apply_strategy(EncodedRecord.t()) :: EncodingResult.t()
  def apply_strategy(record) do
    process_record(record)
  end

  @spec process_record(EncodedRecord.t()) :: EncodingResult.t()
  defp process_record(record) do
    {:ok,
     record
     |> build_request_params()
     |> fetch_match_api()
     |> parse_response()
     |> parse_response_body()
     |> handle_synonym()
     |> Strategy.update_encoded_record(record, @output_attributes)}
  catch
    error ->
      {:error, error}
  end

  @spec build_request_params(EncodedRecord.t()) :: list()
  defp build_request_params(record) do
    @input_attributes
    |> Enum.map(fn {record_attribute, request_attribute} ->
      request_value = Map.get(record, record_attribute)

      if request_value != nil do
        {request_attribute, request_value}
      end
    end)
    |> check_parameters(record)
    |> Enum.filter(&(&1 !== nil))
    |> Enum.uniq()
  end

  @spec fetch_match_api(list()) :: Req.Response.t()
  defp fetch_match_api(request_params) do
    case Gbif.RestAPI.get_matching_species(request_params) do
      {:ok, response} -> response
      {:error, error} -> log_and_throw(error)
    end
  end

  @spec fetch_species_api(String.t()) :: Req.Response.t()
  defp fetch_species_api(species_key) do
    case Gbif.RestAPI.get_species(species_key) do
      {:ok, response} -> response
      {:error, error} -> log_and_throw(error)
    end
  end

  @spec parse_response(Req.Response.t()) :: map()
  defp parse_response(response) when is_nil(response.status) == false and is_nil(response.body) == false,
    do: response.body

  defp parse_response(response) when is_nil(response.status) or is_nil(response.body),
    do: throw("invalid response from gbif taxonomy api: #{inspect(response)}")

  defp parse_response(response) when response.status != 200,
    do: throw("Non 200 response code while fetching gbif taxonomy api: #{inspect(response)}")

  @spec handle_synonym(map()) :: map()
  defp handle_synonym(body) when body.synonym == false, do: body

  defp handle_synonym(body) when body.synonym == true do
    body.acceptedUsageKey
    |> fetch_species_api()
    |> parse_response()
    |> parse_species_api_body()
  end

  @spec parse_species_api_body(map()) :: map()
  defp parse_species_api_body(unparsed_body) do
    to_map(unparsed_body)
  end

  @spec parse_response_body(map()) :: map()
  defp parse_response_body(unparsed_body) do
    body = to_map(unparsed_body)

    case validate_body(body) do
      {:ok, body} -> body
      {:error, error} -> log_and_throw(error)
    end
  end

  defp to_map(data) do
    Map.new(data, fn {key, value} -> {String.to_atom(key), value} end)
  end

  @spec validate_body(map()) :: {:ok, map()} | {:error, any()}
  defp validate_body(body) do
    is_correct_match_type(body)
    is_confident(body)

    {:ok, body}
  catch
    error -> {:error, error}
  end

  @spec is_correct_match_type(map()) :: boolean()
  defp is_correct_match_type(body) when body.taxonomicStatus == ~c"ACCEPTED", do: true
  defp is_correct_match_type(body) when body.matchType == "EXACT", do: true
  defp is_correct_match_type(body) when body.matchType == "FUZZY", do: true
  defp is_correct_match_type(body) when body.matchType == "HIGHERRANK", do: true
  # has to be verified, if this is the correct way to handle HIGHERRANK matchTypes
  # defp is_correct_match_type(body) when body.matchType == "HIGHERRANK",
  #   do:
  #     throw(
  #       "For this species name we could not find a matching
  #        taxonomy. matchType #{inspect(body.matchType)} is not accepted"
  #     )

  defp is_correct_match_type(body) when body.matchType == "NONE",
    do:
      throw(
        "For this species name we could not find a matching taxonomy. matchType #{inspect(body.matchType)} is not accepted"
      )

  # the gbif api returns a confidence value between 0 and 100,
  # we accept items only if the confidence is >= @min_confidence
  @spec is_confident(map()) :: boolean()
  defp is_confident(body) when body.confidence >= @min_confidence, do: true

  defp is_confident(body) when body.confidence < @min_confidence,
    do:
      throw(
        "For this species name we could not find a matching taxonomy. response value #{inspect(body)} is not confident (min #{@min_confidence}) enough"
      )

  @spec log_and_throw(map()) :: {:ok, map()} | {:error, any()}
  defp log_and_throw(error) do
    Logger.warning("Error while fetching gbif taxonomy api: #{inspect(error)}")

    throw(error)
  end

  defp check_parameters(params, encoded_record) do
    encoded_record = Ash.load!(encoded_record, [:record], lazy?: true)
    record = Ash.load!(encoded_record.record, [:collection], lazy?: true)

    # check if there is at least a kingdom parameter set
    case add_kingdom_fallback(params, record) do
      [] ->
        throw(
          "No taxonomy parameters (eighter tax_kingdom, tax_phylum, tax_class, tax_order or tax_family) found to query the gbif_taxonomy api"
        )

      _ ->
        params
    end
  end

  # if no taxon attributes were found on the record, we try to add at least the kingdom
  # from the collection as fallback, if this was also not found we return an empty list
  defp add_kingdom_fallback(params, record) do
    cond do
      params !== [] ->
        params

      record.collection.type === :zoology ->
        [kingdom: "Animalia"]

      record.collection.type === :botany ->
        [kingdom: "Plantae"]

      true ->
        Logger.warning("No fallback kingdom found for record #{record.id} on the collection #{record.collection.name}")

        []
    end
  end
end
