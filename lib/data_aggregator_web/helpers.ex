defmodule DataAggregatorWeb.Helpers do
  @moduledoc """
  Formatting helpers for date, datetime, etc.
  """

  alias DataAggregator.Records.Record
  alias DataAggregatorWeb.Cldr

  @timezone "Europe/Zurich"
  @placeholder Phoenix.HTML.raw("&mdash;")

  def format_number(number, opts \\ [])
  def format_number(nil, _opts), do: @placeholder
  def format_number(number, opts), do: Cldr.Number.to_string!(number, opts)

  def format_percent(number, opts \\ [])
  def format_percent(nil, _opts), do: @placeholder

  def format_percent(number, opts) do
    {precision, opts} = Keyword.pop(opts, :precision, 0)

    number = Float.round(number * 100.0, precision)
    opts = Keyword.merge([unit: "percent", style: :short], opts)
    Cldr.Unit.to_string!(number, opts)
  end

  def format_date(date, opts \\ []), do: Cldr.Date.to_string!(date, opts)

  def format_datetime(datetime, opts \\ [])
  def format_datetime(nil, _opts), do: @placeholder

  def format_datetime(datetime, opts),
    do: datetime |> DateTime.shift_zone!(@timezone) |> Cldr.DateTime.to_string!(opts)

  def format_weeks(weeks, opts \\ []),
    do: Cldr.Unit.to_string!(weeks, Keyword.merge(opts, unit: "week"))

  def format_date_interval(from, to, opts \\ []),
    do: Cldr.Interval.to_string!(from, to, opts)

  def format_time_ago(value, opts \\ []),
    # credo:disable-for-next-line Credo.Check.Design.AliasUsage
    do: Cldr.DateTime.Relative.to_string!(value, opts)

  def format_bytes(bytes, opts \\ []) do
    kb = 1024
    mb = 1024 * kb
    gb = 1024 * mb

    {value, unit} =
      cond do
        bytes < kb -> {bytes / 1.0, :byte}
        bytes < mb -> {bytes / kb, :kilobyte}
        bytes < gb -> {bytes / mb, :megabyte}
        true -> {bytes / gb, :gigabyte}
      end

    precision = Keyword.get(opts, :precision, 1)
    value = Float.round(value, precision)

    opts =
      opts
      |> Keyword.put(:unit, unit)
      |> Keyword.put_new(:style, :short)

    Cldr.Unit.to_string!(value, opts)
  end

  def format_seconds(nil), do: @placeholder

  def format_seconds(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    seconds = rem(seconds, 60)

    format = &String.pad_leading(Integer.to_string(&1), 2, "0")
    "#{format.(hours)}:#{format.(minutes)}:#{format.(seconds)}"
  end

  @spec imported_attribute(Record.t(), atom()) :: any()
  def imported_attribute(record, attribute) do
    if record != nil do
      record |> Map.get(attribute) |> value_for_record_attribute()
    else
      "-"
    end
  end

  @spec encoded_attribute(Record.t(), atom()) :: any()
  def encoded_attribute(record, attribute) do
    if record.encoded_record != nil do
      record.encoded_record |> Map.get(attribute) |> value_for_record_attribute()
    else
      "-"
    end
  end

  defp value_for_record_attribute(value) when is_nil(value), do: "-"
  defp value_for_record_attribute(value) when value === "", do: "-"
  defp value_for_record_attribute(value), do: value
end
