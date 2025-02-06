defmodule DataAggregator.Records.Encoding.Strategy.ConvertDatesStrategy do
  @moduledoc """
    Encode Records to convert and populate dates
  """

  alias Ash.Resource.Actions.Implementation.Context
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.EncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Taxonomy.Catalog

  require Logger

  @output_attributes Catalog.get_output_attributes(:convert_dates)
  @date_fields [
    :eve_event_date,
    :eve_day,
    :eve_month,
    :eve_year,
    :eve_end_of_period_day,
    :eve_end_of_period_month,
    :eve_end_of_period_year
  ]

  @doc """
    converts the various date fields and return the encoded record with the new date fields
  """
  @spec apply_strategy(EncodedRecord.t(), Context.t()) :: EncodingResult.t()
  def apply_strategy(encoded_record, ctx) do
    {:ok, process_encoded_record(encoded_record, ctx)}
  rescue
    error ->
      handle_error(encoded_record.id, error)

      {:error, error, encoded_record}
  end

  @spec process_encoded_record(EncodedRecord.t(), Context.t()) :: EncodedRecord.t()
  defp process_encoded_record(encoded_record, ctx) do
    encoded_record
    |> get_dates()
    |> convert_dates()
    |> Strategy.update_encoded_record(
      encoded_record,
      @output_attributes,
      ctx
    )
  end

  @spec get_dates(EncodedRecord.t()) :: map()
  defp get_dates(encoded_record) do
    encoded_record
    |> Map.from_struct()
    |> Map.take(@date_fields)
  end

  @spec convert_dates(map()) :: map()
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp convert_dates(dates) do
    cond do
      no_dates_present?(dates) ->
        raise("No dates available: #{inspect(@date_fields)}")

      all_dates_present?(dates) or day_month_year_present?(dates) or event_date_missing?(dates) ->
        populate_event_date(dates)

      only_event_date_present?(dates) and not date_range?(dates) ->
        populate_day_month_year(dates)

      only_event_date_present?(dates) and date_range?(dates) ->
        populate_day_month_year_range(dates)

      true ->
        dates
    end
  end

  @spec no_dates_present?(map()) :: boolean()
  defp no_dates_present?(dates) do
    date_values = Map.values(dates)

    Enum.all?(date_values, fn value -> value === nil end)
  end

  @spec only_event_date_present?(map()) :: boolean()
  defp only_event_date_present?(dates) do
    case Map.pop(dates, :eve_event_date) do
      {nil, _popped_dates} ->
        false

      {_event_date, popped_dates} ->
        all_dates_nil?(popped_dates)
    end
  end

  @spec event_date_missing?(map()) :: boolean()
  defp event_date_missing?(dates) do
    Map.get(dates, :eve_event_date) === nil
  end

  @spec all_dates_present?(map()) :: boolean()
  defp all_dates_present?(dates) do
    relevant_fields_present?(dates, @date_fields)
  end

  @spec day_month_year_present?(map()) :: boolean()
  defp day_month_year_present?(dates) do
    relevant_fields = [:eve_day, :eve_month, :eve_year]

    relevant_fields_present?(dates, relevant_fields)
  end

  @spec falsy?(any()) :: boolean()
  defp falsy?(value), do: value in [nil, "", " ", 0, false]

  @spec all_dates_nil?(map()) :: boolean()
  defp all_dates_nil?(dates) do
    dates
    |> Map.values()
    |> Enum.all?(fn value -> falsy?(value) end)
  end

  @spec date_range?(map()) :: boolean()
  defp date_range?(dates) do
    event_date = Map.get(dates, :eve_event_date)

    String.contains?(event_date, "/")
  end

  @spec populate_day_month_year_range(map()) :: map()
  defp populate_day_month_year_range(dates) do
    event_date = Map.get(dates, :eve_event_date)

    [start_date, end_date] = String.split(event_date, "/")

    dates |> populate_start_date(start_date) |> populate_end_date(end_date)
  end

  @spec populate_day_month_year(map()) :: map()
  defp populate_day_month_year(dates) do
    event_date = Map.get(dates, :eve_event_date)

    populate_start_date(dates, event_date)
  end

  @spec populate_start_date(map(), String.t()) :: map()
  defp populate_start_date(dates, event_date) do
    populate_date(dates, event_date, %{
      day_field: :eve_day,
      month_field: :eve_month,
      year_field: :eve_year
    })
  end

  @spec populate_end_date(map(), String.t()) :: map()
  defp populate_end_date(dates, event_date) do
    populate_date(dates, event_date, %{
      day_field: :eve_end_of_period_day,
      month_field: :eve_end_of_period_month,
      year_field: :eve_end_of_period_year
    })
  end

  @spec populate_date(map(), String.t(), map()) :: map()
  defp populate_date(dates, event_date, %{day_field: day_field, month_field: month_field, year_field: year_field}) do
    case Date.from_iso8601(event_date) do
      {:ok, %Date{day: day, month: month, year: year}} ->
        dates
        |> Map.put(day_field, day)
        |> Map.put(month_field, month)
        |> Map.put(year_field, year)

      {:error, _} ->
        raise("Can not populate day, month and year, invalid event_date: #{inspect(event_date)}")
    end
  end

  @spec populate_event_date(map()) :: map()
  defp populate_event_date(dates) do
    relevant_fields = [:eve_day, :eve_month, :eve_year]

    if not relevant_fields_present?(dates, relevant_fields) do
      raise("Can not populate event_date, all relevant date values are nil: '#{inspect(relevant_fields)}'")
    end

    day = get_padded_day_or_month(dates, :eve_day)
    month = get_padded_day_or_month(dates, :eve_month)
    year = Map.get(dates, :eve_year)

    event_date =
      case Date.from_iso8601("#{year}-#{month}-#{day}") do
        {:ok, date} ->
          Date.to_string(date)

        {:error, _} ->
          raise("Can not populate event_date, invalid day, month or year: '#{year}-#{month}-#{day}'")
      end

    if can_create_range_event_date?(dates) do
      event_date = create_ranged_event_date(dates, event_date)

      Map.put(dates, :eve_event_date, event_date)
    else
      Map.put(dates, :eve_event_date, event_date)
    end
  end

  @spec create_ranged_event_date(map(), String.t()) :: String.t()
  defp create_ranged_event_date(dates, start_date) do
    relevant_fields = [
      :eve_end_of_period_day,
      :eve_end_of_period_month,
      :eve_end_of_period_year
    ]

    if not relevant_fields_present?(dates, relevant_fields) do
      raise("Can not populate ranged event_date, all relevant date values are nil: '#{inspect(relevant_fields)}'")
    end

    end_day = get_padded_day_or_month(dates, :eve_end_of_period_day)
    end_month = get_padded_day_or_month(dates, :eve_end_of_period_month)
    end_year = Map.get(dates, :eve_end_of_period_year)

    case Date.from_iso8601("#{end_year}-#{end_month}-#{end_day}") do
      {:ok, date} ->
        start_date <> "/" <> Date.to_string(date)

      {:error, _} ->
        raise("Can not populate ranged event_date, invalid day, month or year: '#{end_year}-#{end_month}-#{end_day}'")
    end
  end

  @spec get_padded_day_or_month(map(), atom()) :: String.t()
  defp get_padded_day_or_month(dates, field) do
    dates |> Map.get(field) |> Integer.to_string() |> String.pad_leading(2, "0")
  end

  @spec can_create_range_event_date?(map()) :: boolean()
  defp can_create_range_event_date?(dates) do
    relevant_fields = [:eve_end_of_period_day, :eve_end_of_period_month, :eve_end_of_period_year]

    relevant_fields_present?(dates, relevant_fields)
  end

  @spec relevant_fields_present?(map(), list()) :: boolean()
  defp relevant_fields_present?(dates, keys) do
    Enum.all?(keys, fn key -> not falsy?(Map.get(dates, key)) end)
  end

  @spec handle_error(String.t(), any()) :: :ok
  defp handle_error(encoded_record_id, error) do
    Logger.warning(
      "[convert_dates] Error while encoding the encoded_record #{encoded_record_id}, failed to convert and santize date values: #{inspect(error)}"
    )
  end
end
