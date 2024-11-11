defmodule DataAggregator.Records.Encoding.Strategy.ForwardGeoEncodingStrategy do
  @moduledoc """
    Encode Records with the geo location api (opencagedata) to receive forward encoded geo locations
  """

  import DataAggregator.Helpers, only: [maybe_performant_load_record: 2]

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Opencage
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
  @spec apply_strategy(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  def apply_strategy(encoded_record, %{tenant: tenant} = ctx) do
    encoded_record = maybe_performant_load_record(encoded_record, tenant)

    longitude = encoded_record.loc_decimal_longitude
    latitude = encoded_record.loc_decimal_latitude

    if longitude != nil && latitude != nil do
      Logger.debug(
        "The encoded_record #{encoded_record.id} already has coordinates, therefore a forward encoding will not provide better data. We will not forward encode towards the geo api."
      )

      {:ok, encoded_record}
    else
      case process_encoded_record(encoded_record, ctx) do
        {:ok, encoded_record} ->
          {:ok, encoded_record}

        {:error, error, encoded_record} ->
          handle_error(encoded_record.id, error)

          {:error, error, encoded_record}
      end
    end
  rescue
    error ->
      handle_error(encoded_record.id, error)

      {:error, error, encoded_record}
  end

  @spec process_encoded_record(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  defp process_encoded_record(encoded_record, ctx) do
    {
      :ok,
      encoded_record
      |> build_params()
      |> fetch_if_params_available()
      |> upcase_country_code()
      |> Strategy.update_encoded_record(encoded_record, @output_attributes, ctx)
    }
  catch
    error ->
      {:error, error, encoded_record}
  end

  @spec build_params(EncodedRecord.t()) :: {:ok, list()} | {:error, any()}
  defp build_params(encoded_record) do
    api_key =
      System.get_env("OPEN_CAGE_DATA_API_KEY") ||
        throw("No open cage data api key found in the environment variables. set one under OPEN_CAGE_DATA_API_KEY")

    # we only want to encode, if a tleast loc_country is present
    q =
      if encoded_record.loc_country do
        [
          encoded_record.loc_state_province,
          encoded_record.loc_country
        ]
        |> Enum.reject(&is_nil/1)
        |> Enum.join(", ")
      else
        Logger.debug("no encoded_record.loc_country found on encoded_record #{encoded_record.id}")

        ""
      end

    # in case the q parameter is an empty string, we return nil and don't fetch the api
    case q do
      "" ->
        {:error,
         "The attributes necessary to forward geo encode were not found on encoded_record #{encoded_record.id}, we will not encode towards the geo api"}

      query ->
        {:ok,
         [
           {:q, query},
           {:key, api_key},
           {:language, "en"},
           {:no_annotations, 1},
           {:countrycode, encoded_record.loc_country_code}
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

  @spec upcase_country_code(map()) :: map()
  defp upcase_country_code(%{"country_code" => _country_code} = update_params) do
    Map.update!(update_params, "country_code", &String.upcase/1)
  end

  defp upcase_country_code(update_params), do: update_params

  @spec handle_error(String.t(), map()) :: :ok
  defp handle_error(encoded_record_id, error) do
    Logger.warning(
      "[geo_forward] Error while encoding the encoded_record #{encoded_record_id} with the geo api: #{inspect(error)}"
    )
  end
end
