defmodule DataAggregator.Records.Encoding.Strategy.GbifTaxonomyStrategy do
  @moduledoc """
    Encode Records with the gbif taxonomy catalog
  """

  require Logger

  alias DataAggregator.Cache.HttpDiskCache
  alias DataAggregator.Records
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalog

  # the input attributes are the attributes that will be used to build the request body.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute to be used in the request body
  @input_attributes Catalog.get_input_attributes(:gbif_taxonomy)

  # the output attributes are the attributes that will be updated on the encoded record.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute on the gbif response
  @output_attributes Catalog.get_output_attributes(:gbif_taxonomy)

  # the url to the gbif taxonomy api
  @match_api_url "https://api.gbif.org/v1/species/match"
  @species_api_url "https://api.gbif.org/v1/species"

  def match_api_url, do: @match_api_url
  def species_api_url, do: @species_api_url

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
     |> parse_match_api_body()
     |> handle_synonym()
     |> Strategy.update_encoded_record(record, @output_attributes)}
  catch
    error ->
      {:error, error}
  end

  @spec build_request_params(EncodedRecord.t()) :: list()
  defp build_request_params(record) do
    ([kingdom: get_kingdom(record)] ++
       Enum.map(@input_attributes, fn {record_attribute, request_attribute} ->
         response_value = Map.get(record, record_attribute, nil)

         if response_value != nil do
           {request_attribute, response_value}
         end
       end))
    |> Enum.filter(&(&1 !== nil))
    |> Enum.uniq()
  end

  @spec fetch_match_api(list()) :: Req.Response.t()
  defp fetch_match_api(request_params) do
    fetch_api(@match_api_url, request_params)
  end

  @spec fetch_species_api(list()) :: Req.Response.t()
  defp fetch_species_api(species_key) do
    fetch_api("#{@species_api_url}/#{species_key}", [])
  end

  @spec fetch_api(String.t(), list()) :: Req.Response.t()
  defp fetch_api(url, request_params) do
    req = HttpDiskCache.attach(Req.new(params: request_params))

    case Req.get(req, url: url) do
      {:ok, response} -> response
      {:error, error} -> throw_error(error)
    end
  end

  @spec parse_response(Req.Response.t()) :: map()
  defp parse_response(response)
       when is_nil(response.status) == false and is_nil(response.body) == false,
       do: response.body

  defp parse_response(response)
       when is_nil(response.status) or is_nil(response.body),
       do: throw("invalid response from gbif taxonomy api: #{inspect(response)}")

  defp parse_response(response)
       when response.status != 200,
       do: throw("Non 200 response code while fetching gbif taxonomy api: #{inspect(response)}")

  @spec handle_synonym(map()) :: map()
  defp handle_synonym(body) when body.synonym == false, do: body

  defp handle_synonym(body) when body.synonym == true do
    fetch_species_api(body.acceptedUsageKey)
    |> parse_response()
    |> parse_species_api_body()
  end

  @spec parse_species_api_body(map()) :: map()
  defp parse_species_api_body(unparsed_body) do
    to_map(unparsed_body)
  end

  @spec parse_match_api_body(map()) :: map()
  defp parse_match_api_body(unparsed_body) do
    body = to_map(unparsed_body)

    case validate_body(body) do
      {:ok, body} -> body
      {:error, error} -> log_and_throw(error)
    end
  end

  defp to_map(data) do
    for {key, value} <- data, into: %{} do
      {parse_key(key), value}
    end
  end

  defp parse_key(key) when is_binary(key) do
    String.to_atom(key)
  end

  defp parse_key(key) when is_atom(key) do
    key
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

  defp is_correct_match_type(body) when body.matchType == "HIGHERRANK",
    do:
      throw(
        "For this species name we could not find a matching taxonomy. matchType #{inspect(body.matchType)} is not accepted"
      )

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
    Logger.error("Error while fetching gbif taxonomy api: #{inspect(error)}")

    throw(error)
  end

  @spec get_kingdom(EncodedRecord.t()) :: String.t()
  defp get_kingdom(encoded_record) do
    encoded_record = Records.load!(encoded_record, [:record], lazy?: true)
    record = Records.load!(encoded_record.record, [:collection], lazy?: true)

    list_of_collection_types =
      Enum.map(CollectionType.get_collection_types(), fn {_key, value} -> value end)

    cond do
      record.tax_kingdom in list_of_collection_types ->
        record.tax_kingdom

      record.collection.type in list_of_collection_types ->
        record.collection.type

      true ->
        throw("No kingdom found for record #{record.id}. not on the collection nor the record")
    end
  end
end
