defmodule DataAggregator.Records.Encoding.Strategy.ForwardGeoEncodingStrategy do
  @moduledoc """
    Encode Records with the geo location api (opencagedata) to receive forward encoded geo locations
  """

  alias DataAggregator.Opencage
  alias DataAggregator.Records
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalog

  require Logger

  # the output attributes are the attributes that will be updated on the encoded record.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute on returning data structure of the catalog
  @output_attributes Catalog.get_output_attributes(:geo_forward)

  @doc """
    lookup the geo encoding api and return the encoded record
  """
  @spec apply_strategy(EncodedRecord.t()) :: EncodingResult.t()
  def apply_strategy(encoded_record) do
    encoded_record = Records.load!(encoded_record, [:record])

    longitude = encoded_record.loc_decimal_longitude
    latitude = encoded_record.loc_decimal_latitude

    if longitude != nil && latitude != nil do
      Logger.debug(
        "The record #{encoded_record.id} already has coordinates, therefore a forward encoding will not provide better data. We will not forward encode towards the geo api."
      )

      {:ok, encoded_record}
    else
      case process_record(encoded_record) do
        {:ok, encoded_record} ->
          {:ok, encoded_record}

        {:error, error} ->
          handle_error(encoded_record.id, error)

          {:error, error}
      end
    end
  rescue
    error ->
      handle_error(encoded_record.id, error)

      {:error, error}
  end

  @spec process_record(EncodedRecord.t()) :: EncodingResult.t()
  defp process_record(encoded_record) do
    {
      :ok,
      encoded_record
      |> build_params()
      |> fetch_if_params_available()
      |> Strategy.update_encoded_record(encoded_record, @output_attributes)
    }
  catch
    error ->
      {:error, error}
  end

  @spec build_params(EncodedRecord.t()) :: {:ok, list()} | {:error, any()}
  defp build_params(record) do
    api_key =
      System.get_env("OPEN_CAGE_DATA_API_KEY") ||
        throw("No open cage data api key found in the environment variables. set one under OPEN_CAGE_DATA_API_KEY")

    # we want to encode the location if we have at least one of the following fields,
    # otherwise we would get a way too generic response
    q =
      if record.loc_locality || record.loc_municipality do
        [
          record.loc_locality,
          record.loc_municipality,
          record.loc_state_province,
          record.loc_country,
          record.loc_continent
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join(", ")
      else
        Logger.debug("no record.loc_locality or record.loc_municipality found on record #{record.id}")

        ""
      end

    # in case the q parameter is an empty string, we return nil and don't fetch the api
    case q do
      "" ->
        {:error,
         "The attributes necessary to forward geo encode were not found on record #{record.id}, we will not encode towards the geo api"}

      query ->
        {:ok,
         [
           {:q, query},
           {:key, api_key},
           {:language, "en"},
           {:no_annotations, 1},
           {:countrycode, record.loc_country_code}
         ]
         |> Enum.reject(&is_nil/1)
         |> Enum.filter(fn {_, value} ->
           value != nil
         end)}
    end
  end

  @spec fetch_if_params_available({:ok, list()} | {:error, any()}) :: map()
  defp fetch_if_params_available(request_params) do
    case request_params do
      {:ok, params} ->
        params
        |> fetch_api()
        |> parse_response()
        |> add_municipality_and_city()

      {:error, error} ->
        Logger.debug(error)
        throw(error)
    end
  end

  @spec fetch_api(list()) :: Req.Response.t()
  defp fetch_api(params) do
    case Opencage.RestAPI.fetch(params) do
      {:ok, response} -> response
      {:error, error} -> throw(error)
    end
  end

  @spec parse_response(Req.Response.t()) :: map()
  defp parse_response(response) when response.status == 200 do
    results = response.body["results"]

    if results != nil && Enum.empty?(results) == false do
      location = hd(results)

      location["components"]
    else
      throw("No results found in response from geo api")
    end
  end

  defp parse_response(response) when response.status != 200,
    do: throw("No valid response (status #{response.status}) from geo api")

  defp add_municipality_and_city(update_params) do
    update_params
    |> Map.put(
      "town",
      update_params["town"] || update_params["township"] || update_params["village"] ||
        update_params["city"] ||
        update_params["_normalized_city"]
    )
    |> Map.put(
      "city",
      update_params["city"] || update_params["suburb"] || update_params["township"] ||
        update_params["village"] || update_params["_normalized_city"]
    )
  end

  @spec handle_error(String.t(), map()) :: :ok
  defp handle_error(record_id, error) do
    Logger.warning("Error while encoding the record #{record_id} with the geo api: #{inspect(error)}")
  end
end
