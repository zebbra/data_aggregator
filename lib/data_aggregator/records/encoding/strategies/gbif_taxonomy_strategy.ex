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
  @api_url "https://api.gbif.org/v1/species/match"

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
     |> fetch_gbif_api()
     |> parse_response()
     |> update_encoded_record(record)}
  catch
    error ->
      {:error, error}
  end

  @spec build_request_params(EncodedRecord.t()) :: list()
  defp build_request_params(record) do
    request_params =
      Enum.map(@input_attributes, fn {record_attribute, request_attribute} ->
        {request_attribute, Map.get(record, record_attribute, "")}
      end)

    request_params
  end

  @spec fetch_gbif_api(list()) :: map()
  defp fetch_gbif_api(request_params) do
    case Req.get(@api_url, params: request_params) do
      {:ok, response} -> response
      {:error, error} -> throw_error(error)
    end
  end

  @spec parse_response(map()) :: map()
  defp parse_response(response)
       when is_nil(response.status) == false and is_nil(response.body) == false do
    case response.status do
      200 -> parse_body(response.body)
      _ -> throw("Non 200 response code while fetching gbif taxonomy api: #{inspect(response)}")
    end
  end

  defp parse_body(unparsed_body) do
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

  defp validate_body(body) do
    is_correct_match_type(body)
    is_confident(body)

    {:ok, body}
  catch
    error -> {:error, error}
  end

  defp is_correct_match_type(body) when body.matchType == "EXACT", do: true
  defp is_correct_match_type(body) when body.matchType == "FUZZY", do: true

  defp is_correct_match_type(body) when body.matchType == "NONE",
    do: throw("matchType #{inspect(body.matchType)} is not accepted")

  defp is_confident(body) when body.confidence >= @min_confidence, do: true

  defp is_confident(body) when body.confidence < @min_confidence,
    do: throw("response value #{inspect(body)} is not confident (min #{@min_confidence}) enough")

  @spec update_encoded_record(map(), EncodedRecord.t()) :: EncodedRecord.t()
  defp update_encoded_record(response, record) do
    updated_attributes =
      Enum.map(@output_attributes, fn {record_attribute, response_attribute} ->
        {record_attribute, Map.get(response, response_attribute)}
      end)
      |> Enum.into(%{})

    Map.merge(record, updated_attributes)
  end

  @spec throw_error(map()) :: {:ok, map()} | {:error, any()}
  defp throw_error(error) do
    Logger.error("Error while fetching gbif taxonomy api: #{inspect(error)}")

    throw(error)
  end
end
