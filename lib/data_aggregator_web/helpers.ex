defmodule DataAggregatorWeb.Helpers do
  alias DataAggregatorWeb.Cldr

  import DataAggregatorWeb.Gettext

  @timezone "Europe/Zurich"
  @placeholder Phoenix.HTML.raw("&mdash;")

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
    mb = kb * 1024

    {value, unit} = if bytes < 100 * kb, do: {bytes / kb, "KB"}, else: {bytes / mb, "MB"}

    opts =
      opts
      |> Keyword.put_new(:format, "#,##0.#")
      |> Keyword.update!(:format, &"#{&1} #{unit}")

    Cldr.Number.to_string!(value, opts)
  end

  def pretty_accept_list(term) when is_binary(term) do
    term
    |> String.split(",")
    |> Enum.map_join(", ", &(String.replace(&1, ~r/^\./, "") |> String.upcase()))
  end

  def pretty_accept_list(_), do: nil

  def pretty_max_file_size(max_file_size) when is_number(max_file_size) do
    max_file_size =
      max_file_size
      |> DataAggregatorWeb.Helpers.format_bytes()
      |> String.replace(" ", "")

    mgettext(" up to ") <> max_file_size
  end

  def pretty_max_file_size(_), do: nil
end
