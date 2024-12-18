defmodule DataAggregator.Records.Encoding.Strategy.ReverseGeoEncodingStrategy do
  @moduledoc """
    Encode Records with the geo location api (opencagedata) to receive reverse encoded geo locations
  """

  import DataAggregator.Helpers, only: [maybe_performant_load_record: 2]

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Misc.Coordinates
  alias DataAggregator.Opencage
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.GeoCoordResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalog

  require Logger

  # the output attributes are the attributes that will be updated on the encoded record.
  # the first element is the attribute on the encoded record and the second
  # element is the attribute on returning data structure of the catalog
  @output_attributes Catalog.get_output_attributes(:geo_reverse)

  @doc """
    lookup the geo encoding api and return the encoded record
  """
  @spec apply_strategy(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  def apply_strategy(encoded_record, %{tenant: tenant} = ctx) do
    encoded_record = maybe_performant_load_record(encoded_record, tenant)

    case process_encoded_record(encoded_record, ctx) do
      {:ok, encoded_record} ->
        {:ok, encoded_record}

      {:error, error, encoded_record} ->
        handle_error(encoded_record.id, error)

        {:error, error, encoded_record}
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
      |> fetch_if_coords_available()
      |> add_swiss_coordinates(encoded_record)
      |> add_intl_coords(encoded_record)
      |> round_coordinates()
      |> upcase_country_code()
      |> add_municipality_and_city()
      |> Strategy.update_encoded_record(encoded_record, @output_attributes, ctx)
    }
  catch
    error ->
      {:error, error, encoded_record}
  end

  @spec build_params(EncodedRecord.t()) :: {:ok, list()} | {:error, any()}
  defp build_params(encoded_record) do
    case convert_coordinates(encoded_record) do
      {:ok, %{n: lat, e: long}} ->
        {:ok, [{:q, "#{lat},#{long}"}]}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec convert_coordinates(EncodedRecord.t()) :: GeoCoordResult.t()
  defp convert_coordinates(encoded_record) do
    intl_lat = encoded_record.loc_decimal_latitude
    intl_long = encoded_record.loc_decimal_longitude

    swiss_lat_lv03 = encoded_record.loc_swiss_coordinates_lv03_y
    swiss_long_lv03 = encoded_record.loc_swiss_coordinates_lv03_x
    swiss_lat_lv95 = encoded_record.loc_swiss_coordinates_lv95_y
    swiss_long_lv95 = encoded_record.loc_swiss_coordinates_lv95_x

    cond do
      intl_lat != nil and intl_long != nil ->
        {:ok, %{n: intl_lat, e: intl_long}}

      swiss_lat_lv95 != nil and swiss_long_lv95 != nil ->
        {:ok, Coordinates.lv95_to_wgs84!(%Coordinates{n: swiss_lat_lv95, e: swiss_long_lv95})}

      swiss_lat_lv03 != nil and swiss_long_lv03 != nil ->
        {:ok, Coordinates.lv03_to_wgs84!(%Coordinates{n: swiss_lat_lv03, e: swiss_long_lv03})}

      true ->
        {:error, "no coordinates found on encoded_record #{encoded_record.id}"}
    end
  end

  @spec fetch_if_coords_available(GeoCoordResult.t()) :: map()
  defp fetch_if_coords_available(coords_or_error) do
    case coords_or_error do
      {:ok, coords} ->
        coords
        |> fetch_api()
        |> parse_response()

      {:error, error} ->
        Logger.debug(error)

        %{}
    end
  end

  @spec fetch_api(list()) :: Req.Response.t()
  defp fetch_api(params) do
    api_key =
      System.get_env("OPEN_CAGE_DATA_API_KEY") ||
        throw("No open cage data api key found in the environment variables. set one under OPEN_CAGE_DATA_API_KEY")

    params = params ++ [{:key, api_key}, {:language, "en"}, {:no_annotations, 1}]

    case Opencage.RestAPI.fetch(params) do
      {:ok, response} -> response
      {:error, error} -> throw(error)
    end
  end

  @spec parse_response(Req.Response.t()) :: map()
  defp parse_response(response) when response.status == 200 do
    results = response.body["results"]

    cond do
      results != nil and length(results) == 1 ->
        location = hd(results)

        location["components"]

      results == nil ->
        throw("No results found in response from geo api")

      true ->
        throw("Wrong amount of results found in response from geo api (Expected 1 but got #{length(results)}")
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

  @spec add_swiss_coordinates(map(), EncodedRecord.t()) :: map()
  defp add_swiss_coordinates(update_params, encoded_record) do
    cond do
      # if the country is not switzerland we don't need the swiss coordinates
      switzerland?(update_params, encoded_record) == false ->
        update_params
        |> Map.put("loc_swiss_coordinates_lv03_x", nil)
        |> Map.put("loc_swiss_coordinates_lv03_y", nil)
        |> Map.put("loc_swiss_coordinates_lv95_x", nil)
        |> Map.put("loc_swiss_coordinates_lv95_y", nil)

      encoded_record.loc_decimal_latitude != nil and
          encoded_record.loc_decimal_longitude != nil ->
        swiss_coords_lv95 =
          Coordinates.wgs84_to_lv95!(%Coordinates{
            e: encoded_record.loc_decimal_longitude,
            n: encoded_record.loc_decimal_latitude
          })

        swiss_coord_lv03 =
          Coordinates.wgs84_to_lv03!(%Coordinates{
            e: encoded_record.loc_decimal_longitude,
            n: encoded_record.loc_decimal_latitude
          })

        update_params
        |> maybe_put(encoded_record, "loc_swiss_coordinates_lv95_x", swiss_coords_lv95.e)
        |> maybe_put(encoded_record, "loc_swiss_coordinates_lv95_y", swiss_coords_lv95.n)
        |> maybe_put(encoded_record, "loc_swiss_coordinates_lv03_x", swiss_coord_lv03.e)
        |> maybe_put(encoded_record, "loc_swiss_coordinates_lv03_y", swiss_coord_lv03.n)

      encoded_record.loc_swiss_coordinates_lv95_x != nil and
          encoded_record.loc_swiss_coordinates_lv95_y != nil ->
        swiss_coords_lv03 =
          Coordinates.lv95_to_lv03!(%Coordinates{
            e: encoded_record.loc_swiss_coordinates_lv95_x,
            n: encoded_record.loc_swiss_coordinates_lv95_y
          })

        # we need to set the coordinates here, otherwise they will be overwritten with nil
        update_params
        |> Map.put("loc_swiss_coordinates_lv95_x", encoded_record.loc_swiss_coordinates_lv95_x)
        |> Map.put("loc_swiss_coordinates_lv95_y", encoded_record.loc_swiss_coordinates_lv95_y)
        |> maybe_put(encoded_record, "loc_swiss_coordinates_lv03_x", swiss_coords_lv03.e)
        |> maybe_put(encoded_record, "loc_swiss_coordinates_lv03_y", swiss_coords_lv03.n)

      encoded_record.loc_swiss_coordinates_lv03_x != nil and
          encoded_record.loc_swiss_coordinates_lv03_y != nil ->
        swiss_coords_lv95 =
          Coordinates.lv03_to_lv95!(%Coordinates{
            e: encoded_record.loc_swiss_coordinates_lv03_x,
            n: encoded_record.loc_swiss_coordinates_lv03_y
          })

        # we need to set the coordinates here, otherwise they will be overwritten with nil
        update_params
        |> Map.put("loc_swiss_coordinates_lv03_x", encoded_record.loc_swiss_coordinates_lv03_x)
        |> Map.put("loc_swiss_coordinates_lv03_y", encoded_record.loc_swiss_coordinates_lv03_y)
        |> maybe_put(encoded_record, "loc_swiss_coordinates_lv95_x", swiss_coords_lv95.e)
        |> maybe_put(encoded_record, "loc_swiss_coordinates_lv95_y", swiss_coords_lv95.n)

      true ->
        update_params
    end
  end

  @spec maybe_put(map(), EncodedRecord.t(), String.t(), any()) :: map()
  defp maybe_put(update_params, encoded_record, key, value) do
    if Map.get(encoded_record, String.to_atom(key)) == nil do
      Map.put(update_params, key, value)
    else
      Map.put(update_params, key, Map.get(encoded_record, String.to_atom(key)))
    end
  end

  @spec switzerland?(map(), EncodedRecord.t()) :: boolean()
  defp switzerland?(update_params, encoded_record) do
    country =
      String.downcase(
        encoded_record.loc_country || encoded_record.record.loc_country ||
          update_params["country"] || ""
      )

    country_code =
      String.downcase(
        encoded_record.loc_country_code || encoded_record.record.loc_country_code ||
          update_params["country_code"] || ""
      )

    country == "switzerland" or country_code == "ch"
  end

  @spec upcase_country_code(map()) :: map()
  defp upcase_country_code(%{"country_code" => nil} = update_params), do: update_params

  defp upcase_country_code(%{"country_code" => _country_code} = update_params) do
    Map.update!(update_params, "country_code", &String.upcase/1)
  end

  defp upcase_country_code(update_params), do: update_params

  @spec add_intl_coords(map(), EncodedRecord.t()) :: map()
  defp add_intl_coords(update_params, encoded_record) do
    cond do
      encoded_record.loc_decimal_latitude != nil and
          encoded_record.loc_decimal_longitude != nil ->
        # intl coords already set
        # we need to set the coordinates here, otherwise they will be overwritten with nil
        update_params
        |> Map.put("loc_decimal_longitude", encoded_record.loc_decimal_longitude)
        |> Map.put("loc_decimal_latitude", encoded_record.loc_decimal_latitude)

      encoded_record.loc_swiss_coordinates_lv95_x != nil and
          encoded_record.loc_swiss_coordinates_lv95_y != nil ->
        intl_coords =
          Coordinates.lv95_to_wgs84!(%Coordinates{
            e: encoded_record.loc_swiss_coordinates_lv95_x,
            n: encoded_record.loc_swiss_coordinates_lv95_y
          })

        update_params
        |> Map.put("loc_decimal_longitude", intl_coords.e)
        |> Map.put("loc_decimal_latitude", intl_coords.n)

      encoded_record.loc_swiss_coordinates_lv03_x != nil and
          encoded_record.loc_swiss_coordinates_lv03_y != nil ->
        intl_coords =
          Coordinates.lv03_to_wgs84!(%Coordinates{
            e: encoded_record.loc_swiss_coordinates_lv03_x,
            n: encoded_record.loc_swiss_coordinates_lv03_y
          })

        update_params
        |> Map.put("loc_decimal_longitude", intl_coords.e)
        |> Map.put("loc_decimal_latitude", intl_coords.n)

      true ->
        update_params
    end
  end

  defp round_coordinates(update_params) do
    update_params
    |> Map.update("loc_decimal_longitude", nil, &maybe_round(&1, 6))
    |> Map.update("loc_decimal_latitude", nil, &maybe_round(&1, 6))
    |> Map.update("loc_swiss_coordinates_lv95_x", nil, &maybe_round(&1, 1))
    |> Map.update("loc_swiss_coordinates_lv95_y", nil, &maybe_round(&1, 1))
    |> Map.update("loc_swiss_coordinates_lv03_x", nil, &maybe_round(&1, 1))
    |> Map.update("loc_swiss_coordinates_lv03_y", nil, &maybe_round(&1, 1))
  end

  defp maybe_round(nil, _), do: nil
  defp maybe_round(value, precision), do: Float.round(value, precision)

  @spec handle_error(String.t(), map()) :: :ok
  defp handle_error(encoded_record_id, error) do
    Logger.warning(
      "[geo_reverse] Error while encoding the encoded_record #{encoded_record_id} with the geo api: #{inspect(error)}"
    )
  end
end
