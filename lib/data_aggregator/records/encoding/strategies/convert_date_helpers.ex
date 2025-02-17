defmodule DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers do
  @moduledoc """
    Helper functions for the `DataAggregator.Records.Encoding.Strategy.ConvertDatesStrategy`
  """
  alias DataAggregator.Records.EncodedRecord

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
    Get the date fields and their values from the encoded record as map

    ## Examples

        iex> encoded_record = %EncodedRecord{eve_event_date: "2020-01-01", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.get_dates(encoded_record)
        %{eve_event_date: "2020-01-01", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}

        iex> encoded_record = %EncodedRecord{eve_event_date: "2020-01-01", eve_day: 10, eve_month: 1, eve_year: 2020, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.get_dates(encoded_record)
        %{eve_event_date: "2020-01-01", eve_day: 10, eve_month: 1, eve_year: 2020, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
  """
  @spec get_dates(EncodedRecord.t()) :: map()
  def get_dates(encoded_record) do
    encoded_record
    |> Map.from_struct()
    |> Map.take(@date_fields)
  end

  @doc """
    Check if no dates are present in the map

    ## Examples

        iex> dates = %{eve_event_date: nil, eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.no_dates_present?(dates)
        true

        iex> dates = %{eve_event_date: "2020-01-01", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.no_dates_present?(dates)
        false
  """
  @spec no_dates_present?(map()) :: boolean()
  def no_dates_present?(dates) do
    date_values = Map.values(dates)

    Enum.all?(date_values, fn value -> value === nil end)
  end

  @doc """
    Check if only the event date is present in the map

    ## Examples

        iex> dates = %{eve_event_date: "2020-01-01", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.only_event_date_present?(dates)
        true

        iex> dates = %{eve_event_date: nil, eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.only_event_date_present?(dates)
        false
  """
  @spec only_event_date_present?(map()) :: boolean()
  def only_event_date_present?(dates) do
    case Map.pop(dates, :eve_event_date) do
      {nil, _popped_dates} ->
        false

      {_event_date, popped_dates} ->
        all_dates_nil?(popped_dates)
    end
  end

  @doc """
    Check if the event date is missing in the map

    ## Examples

        iex> dates = %{eve_event_date: nil, eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.event_date_missing?(dates)
        true

        iex> dates = %{eve_event_date: "2020-01-01", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.event_date_missing?(dates)
        false
  """
  @spec event_date_missing?(map()) :: boolean()
  def event_date_missing?(dates) do
    Map.get(dates, :eve_event_date) === nil
  end

  @doc """
    Check if all date fields are present in the map

    ## Examples

        iex> dates = %{eve_event_date: "2020-01-01", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.all_dates_present?(dates)
        true

        iex> dates = %{eve_event_date: "2020-01-01", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.all_dates_present?(dates)
        false
  """
  @spec all_dates_present?(map()) :: boolean()
  def all_dates_present?(dates) do
    relevant_fields_present?(dates, @date_fields)
  end

  @doc """
    Check if day, month and year are present in the map

    ## Examples

        iex> dates = %{eve_event_date: "2020-01-01", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.day_month_year_present?(dates)
        true

        iex> dates = %{eve_event_date: "2020-01-01", eve_day: nil, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.day_month_year_present?(dates)
        false
  """
  @spec day_month_year_present?(map()) :: boolean()
  def day_month_year_present?(dates) do
    relevant_fields = [:eve_day, :eve_month, :eve_year]

    relevant_fields_present?(dates, relevant_fields)
  end

  @doc """
    Check if the event date is a range

    ## Examples

        iex> dates = %{eve_event_date: "2020-01-01/2020-01-02", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.date_range?(dates)
        true

        iex> dates = %{eve_event_date: "2020-01-01", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.date_range?(dates)
        false
  """
  @spec date_range?(map()) :: boolean()
  def date_range?(dates) do
    event_date = Map.get(dates, :eve_event_date)

    String.contains?(event_date, "/")
  end

  @doc """
    Populate the day, month and year fields from the event date

    ## Examples

        iex> dates = %{eve_event_date: "2029-11-29/2030-07-22", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year_range(dates)
        %{eve_event_date: "2029-11-29/2030-07-22", eve_day: 29, eve_month: 11, eve_year: 2029, eve_end_of_period_day: 22, eve_end_of_period_month: 07, eve_end_of_period_year: 2030}

        iex> dates = %{eve_event_date: "2020-01-01/2020-01-02", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year_range(dates)
        %{eve_event_date: "2020-01-01/2020-01-02", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
  """
  @spec populate_day_month_year_range(map()) :: map()
  def populate_day_month_year_range(dates) do
    event_date = Map.get(dates, :eve_event_date)

    [start_date, end_date] = String.split(event_date, "/")

    dates |> populate_start_date(start_date) |> populate_end_date(end_date)
  end

  @doc """
    Populate the day, month and year fields from the event date

    ## Examples

        iex> dates = %{eve_event_date: "2021-12-06", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year(dates)
        %{eve_event_date: "2021-12-06", eve_day: 6, eve_month: 12, eve_year: 2021, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}

        iex> dates = %{eve_event_date: "2021-12-06", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year(dates)
        %{eve_event_date: "2021-12-06", eve_day: 6, eve_month: 12, eve_year: 2021, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
  """
  @spec populate_day_month_year(map()) :: map()
  def populate_day_month_year(dates) do
    event_date = Map.get(dates, :eve_event_date)

    populate_start_date(dates, event_date)
  end

  @doc """
    Populate the event date field from the day, month and year fields

    ## Examples

        iex> dates = %{eve_event_date: nil, eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_event_date(dates)
        %{eve_event_date: "2020-01-01", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}

        iex> dates = %{eve_event_date: nil, eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_event_date(dates)
        %{eve_event_date: "2020-01-01/2020-01-02", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
  """
  @spec populate_event_date(map()) :: map()
  def populate_event_date(dates) do
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

  @spec falsy?(any()) :: boolean()
  defp falsy?(value), do: value in [nil, "", " ", 0, false]

  @spec all_dates_nil?(map()) :: boolean()
  defp all_dates_nil?(dates) do
    dates
    |> Map.values()
    |> Enum.all?(fn value -> falsy?(value) end)
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
end
