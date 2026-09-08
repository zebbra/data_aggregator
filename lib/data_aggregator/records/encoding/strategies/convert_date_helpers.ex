defmodule DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers do
  @moduledoc """
    Helper functions for the `DataAggregator.Records.Encoding.Strategy.ConvertDatesStrategy`
  """
  alias DataAggregator.Records.EncodedRecord

  require Logger

  @date_fields [
    :eve_event_date,
    :eve_day,
    :eve_month,
    :eve_year,
    :eve_end_of_period_day,
    :eve_end_of_period_month,
    :eve_end_of_period_year
  ]

  @yyyymmdd ~r/^(\d{4})-(\d{2})-(\d{2})$/
  @yyyymm ~r/^(\d{4})-(\d{2})$/
  @yyyy ~r/^(\d{4})$/

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
    Check if only the event date is present in the map

    ## Examples

        iex> dates = %{eve_event_date: "2020-01-01", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.only_event_date_present?(dates)
        true

        iex> dates = %{eve_event_date: "some-non-date-value-which-gets-not-validated-here", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
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

    relevant_fields_are_present?(dates, relevant_fields)
  end

  @doc """
    Populate the day, month and year fields from the event date

    ## Examples

        iex> dates = %{eve_event_date: "2021-12-06", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year(dates)
        {:ok, %{eve_event_date: "2021-12-06", eve_day: 6, eve_month: 12, eve_year: 2021, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}}

        iex> dates = %{eve_event_date: "2021-12-06", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year(dates)
        {:ok, %{eve_event_date: "2021-12-06", eve_day: 6, eve_month: 12, eve_year: 2021, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}}

        iex> dates = %{eve_event_date: "2021-13-06", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year(dates)
        {:error, "Can not populate day, month and year. Could not convert or parse eventDate because of wrong format: \\"2021-13-06\\" false"}

        iex> dates = %{eve_event_date: "2021-12-06/2021-12-08", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year(dates)
        {:ok, %{eve_event_date: "2021-12-06/2021-12-08", eve_day: 6, eve_month: 12, eve_year: 2021, eve_end_of_period_day: 8, eve_end_of_period_month: 12, eve_end_of_period_year: 2021}}

        iex> dates = %{eve_event_date: "2021-12/2022-01", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year(dates)
        {:ok, %{eve_event_date: "2021-12/2022-01", eve_day: nil, eve_month: 12, eve_year: 2021, eve_end_of_period_day: nil, eve_end_of_period_month: 1, eve_end_of_period_year: 2022}}

        iex> dates = %{eve_event_date: "2021/2022", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year(dates)
        {:ok, %{eve_event_date: "2021/2022", eve_day: nil, eve_month: nil, eve_year: 2021, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: 2022}}

        iex> dates = %{eve_event_date: "2021-2022", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year(dates)
        {:error, "Can not populate day, month and year. Could not convert or parse eventDate because of wrong format: \\"2021-2022\\" {:error, :no_match}"}

        iex> dates = %{eve_event_date: "2021-43/2022-12", eve_day: nil, eve_month: nil, eve_year: nil, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_day_month_year(dates)
        {:error, "Can not populate day, month and year. Could not convert or parse eventDate because of wrong format: \\"2021-43\\" false"}
  """
  @spec populate_day_month_year(map()) :: {:ok, map()} | {:error, String.t()}
  def populate_day_month_year(all_dates) do
    event_date = Map.get(all_dates, :eve_event_date)

    case get_event_date_range(event_date) do
      {:ok, dates} -> populate_day_month_year_range(all_dates, dates)
      {:error, _} -> populate_start_date(all_dates, event_date)
    end
  end

  @doc """
    Populate the event date field from the day, month and year fields

    ## Examples

        iex> dates = %{eve_event_date: nil, eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_event_date(dates)
        {:ok, %{eve_event_date: "2020-01-01", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: nil, eve_end_of_period_month: nil, eve_end_of_period_year: nil}}

        iex> dates = %{eve_event_date: nil, eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}
        iex> alias DataAggregator.Records.Encoding.Strategy.ConvertDateHelpers
        iex> ConvertDateHelpers.populate_event_date(dates)
        {:ok, %{eve_event_date: "2020-01-01/2020-01-02", eve_day: 1, eve_month: 1, eve_year: 2020, eve_end_of_period_day: 2, eve_end_of_period_month: 1, eve_end_of_period_year: 2020}}
  """
  @spec populate_event_date(map()) :: {:ok, map()} | {:error, String.t()}
  def populate_event_date(all_dates) do
    relevant_fields = [:eve_day, :eve_month, :eve_year]

    with true <- relevant_fields_are_present?(all_dates, relevant_fields),
         {:ok, event_date} <- build_event_date(all_dates) do
      maybe_create_ranged_event_date(all_dates, event_date)
    else
      false ->
        {:error, "Can not populate event_date, day, month and year are missing"}

      {:error, error} ->
        {:error, error}
    end
  end

  defp year_month_day(date) do
    cond do
      String.match?(date, @yyyymmdd) ->
        {:ok, @yyyymmdd |> Regex.run(date) |> tl()}

      String.match?(date, @yyyymm) ->
        {:ok, @yyyymm |> Regex.run(date) |> tl() |> Enum.concat([nil])}

      String.match?(date, @yyyy) ->
        {:ok, @yyyy |> Regex.run(date) |> tl() |> Enum.concat([nil, nil])}

      true ->
        {:error, :no_match}
    end
  end

  defp valid_date?([year, nil, nil]), do: valid_date?([year, "01", "01"])
  defp valid_date?([year, month, nil]), do: valid_date?([year, month, "01"])

  defp valid_date?([year, month, day]) do
    case Date.from_iso8601("#{year}-#{month}-#{day}") do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp get_event_date_range(event_date) do
    with true <- is_binary(event_date),
         true <- correct_range_length(event_date),
         true <- String.contains?(event_date, "/"),
         dates = String.split(event_date, "/"),
         2 <- length(dates) do
      Logger.debug("Correct date range: #{inspect(dates)}")

      {:ok, dates}
    else
      _ ->
        Logger.debug("Invalid date range: #{inspect(event_date)}")

        {:error, "Invalid date range"}
    end
  end

  # check for the correct length if its a correct date range:
  # yyyy/yyyy --> year and endOfPeriodYear
  # yyyy-mm/yyyy-mm --> year month and endOfPeriodYear endOfPeriodMonth
  # yyyy-mm-dd/yyyy-mm-dd --> year month day and endOfPeriodYear endOfPeriodMonth endOfPeriodDay
  defp correct_range_length(event_date) do
    String.length(event_date) == 9 or
      String.length(event_date) == 15 or
      String.length(event_date) == 21
  end

  # Populate the day, month and year fields from the event date
  @spec populate_day_month_year_range(map(), list()) :: {:ok, map()} | {:error, String.t()}
  defp populate_day_month_year_range(all_dates, from_to) do
    [from, to] = from_to

    with {:ok, dates} <- populate_start_date(all_dates, from) do
      populate_end_date(dates, to)
    end
  end

  @spec build_event_date(map()) :: {:ok, String.t()} | {:error, String.t()}
  defp build_event_date(dates) do
    day = get_padded_day_or_month(dates, :eve_day)
    month = get_padded_day_or_month(dates, :eve_month)
    year = Map.get(dates, :eve_year)

    case Date.from_iso8601("#{year}-#{month}-#{day}") do
      {:ok, date} ->
        {:ok, Date.to_string(date)}

      {:error, _} ->
        {:error, "Can not populate event_date, invalid day, month or year: '#{year}-#{month}-#{day}'"}
    end
  end

  @spec falsy?(any()) :: boolean()
  defp falsy?(value), do: value in [nil, "", " ", false, 0, "0", "00"]

  @spec all_dates_nil?(map()) :: boolean()
  defp all_dates_nil?(dates) do
    dates
    |> Map.values()
    |> Enum.all?(fn value -> falsy?(value) end)
  end

  @spec populate_start_date(map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  defp populate_start_date(all_dates, event_date) do
    populate_date(all_dates, event_date, %{
      day_field: :eve_day,
      month_field: :eve_month,
      year_field: :eve_year
    })
  end

  @spec populate_end_date(map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  defp populate_end_date(dates, event_date) do
    populate_date(dates, event_date, %{
      day_field: :eve_end_of_period_day,
      month_field: :eve_end_of_period_month,
      year_field: :eve_end_of_period_year
    })
  end

  @spec populate_date(map(), String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  defp populate_date(all_dates, event_date, %{day_field: day_field, month_field: month_field, year_field: year_field}) do
    with {:ok, year_month_day} <- year_month_day(event_date),
         true <- valid_date?(year_month_day),
         [year, month, day] <- Enum.map(year_month_day, &maybe_to_integer/1) do
      dates =
        all_dates
        |> Map.put(day_field, day)
        |> Map.put(month_field, month)
        |> Map.put(year_field, year)

      {:ok, dates}
    else
      unexpected ->
        {:error,
         "Can not populate day, month and year. Could not convert or parse eventDate because of wrong format: #{inspect(event_date)} #{inspect(unexpected)}"}
    end
  end

  defp maybe_to_integer(nil), do: nil
  defp maybe_to_integer(""), do: nil

  defp maybe_to_integer(date_slice) do
    String.to_integer(date_slice)
  end

  @spec maybe_create_ranged_event_date(map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  defp maybe_create_ranged_event_date(dates, start_date) do
    if can_create_range_event_date?(dates) do
      case build_ranged_event_date(dates, start_date) do
        {:ok, event_date} ->
          {:ok, Map.put(dates, :eve_event_date, event_date)}

        {:error, error} ->
          Logger.warning(error)

          {:error, error}
      end
    else
      {:ok, Map.put(dates, :eve_event_date, start_date)}
    end
  end

  @spec build_ranged_event_date(map(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp build_ranged_event_date(dates, start_date) do
    end_day = get_padded_day_or_month(dates, :eve_end_of_period_day)
    end_month = get_padded_day_or_month(dates, :eve_end_of_period_month)
    end_year = Map.get(dates, :eve_end_of_period_year)

    case Date.from_iso8601("#{end_year}-#{end_month}-#{end_day}") do
      {:ok, date} ->
        {:ok, start_date <> "/" <> Date.to_string(date)}

      {:error, _} ->
        {:error, "Can not populate ranged event_date, invalid day, month or year: '#{end_year}-#{end_month}-#{end_day}'"}
    end
  end

  @spec get_padded_day_or_month(map(), atom()) :: String.t()
  defp get_padded_day_or_month(dates, field) do
    case Map.get(dates, field) do
      value when is_integer(value) ->
        value |> Integer.to_string() |> String.pad_leading(2, "0")

      value when is_binary(value) ->
        value |> String.trim() |> String.pad_leading(2, "0")
    end
  end

  @spec can_create_range_event_date?(map()) :: boolean()
  defp can_create_range_event_date?(dates) do
    relevant_fields = [:eve_end_of_period_day, :eve_end_of_period_month, :eve_end_of_period_year]

    relevant_fields_are_present?(dates, relevant_fields)
  end

  @spec relevant_fields_are_present?(map(), list()) :: boolean()
  defp relevant_fields_are_present?(dates, keys) do
    Enum.all?(keys, fn key -> not falsy?(Map.get(dates, key)) end)
  end
end
