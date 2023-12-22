defmodule DataAggregator.Records.Encoding.Strategy.GbifTaxonomy do
  @moduledoc """
    Encode Records with the gbif taxonomy catalog
  """

  require Logger

  alias DataAggregator.Records.EncodedRecord

  # the input attributes are the attributes that will be used to build the request body.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute to be used in the request body
  @input_attributes [
    {:tax_scientific_name, :name},
    {:tax_kingdom, :kingdom}
  ]

  # the output attributes are the attributes that will be updated on the encoded record.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute on the gbif response
  @output_attributes [
    {:tax_kingdom, :kingdom},
    {:tax_phylum, :phylum},
    {:tax_class, :class},
    {:tax_family, :family},
    {:tax_order, :order},
    {:tax_genus, :genus},
    {:tax_scientific_name, :scientificName}
  ]

  # the url to the gbif taxonomy api
  @match_api_url "https://api.gbif.org/v1/species/match"
  @species_api_url "https://api.gbif.org/v1/species"

  def match_api_url, do: @match_api_url
  def species_api_url, do: @species_api_url

  # the minimum confidence level to accept a result
  @min_confidence 80

  @doc """
    query the gbif taxanomy api and return a list of encoded records
  """
  @spec apply_strategy([EncodedRecord.t()]) :: [{:ok, EncodedRecord.t()} | {:error, any()}]
  def apply_strategy(records) do
    Enum.map(records, &process_record/1)
  end

  @spec process_record(EncodedRecord.t()) :: {:ok, EncodedRecord.t()} | {:error, any()}
  defp process_record(record) do
    {:ok,
     record
     |> build_request_params()
     |> fetch_match_api()
     |> parse_response()
     |> parse_match_api_body()
     |> handle_synonym()
     |> update_encoded_record(record)}
  catch
    error ->
      {:error, error}
  end

  @spec build_request_params(EncodedRecord.t()) :: list()
  defp build_request_params(record) do
    Enum.map(@input_attributes, fn {record_attribute, request_attribute} ->
      {request_attribute, Map.get(record, record_attribute, "")}
    end)
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
    case Req.get(url, params: request_params) do
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
      {:error, error} -> throw_error(error)
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

  defp is_correct_match_type(body) when body.matchType == "NONE",
    do: throw("matchType #{inspect(body.matchType)} is not accepted")

  @spec is_confident(map()) :: boolean()
  defp is_confident(body) when body.confidence >= @min_confidence, do: true

  defp is_confident(body) when body.confidence < @min_confidence,
    do: throw("response value #{inspect(body)} is not confident (min #{@min_confidence}) enough")

  @spec update_encoded_record(map(), EncodedRecord.t()) :: EncodedRecord.t()
  defp update_encoded_record(response_body, record) do
    updated_attributes =
      Enum.map(@output_attributes, fn {record_attribute, response_attribute} ->
        {record_attribute, Map.get(response_body, response_attribute)}
      end)
      |> Enum.into(%{})

    EncodedRecord.update!(record, updated_attributes)
  end

  @spec throw_error(map()) :: {:ok, map()} | {:error, any()}
  defp throw_error(error) do
    Logger.error("Error while fetching gbif taxonomy api: #{inspect(error)}")

    throw(error)
  end
end
