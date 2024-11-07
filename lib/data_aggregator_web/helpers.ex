defmodule DataAggregatorWeb.Helpers do
  @moduledoc """
  Formatting helpers for date, datetime, etc.
  """

  alias DataAggregator.Accounts.User
  alias DataAggregatorWeb.Cldr
  alias Phoenix.LiveView.Socket

  @timezone "Europe/Zurich"
  @placeholder Phoenix.HTML.raw("&mdash;")

  def format_number(number, opts \\ [])
  def format_number(%Ash.NotLoaded{}, _opts), do: @placeholder
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

  def format_date(date, opts \\ [])
  def format_date(nil, _opts), do: @placeholder
  def format_date(date, opts), do: Cldr.Date.to_string!(date, opts)

  def format_datetime(datetime, opts \\ [])
  def format_datetime(nil, _opts), do: @placeholder

  def format_datetime(datetime, opts), do: datetime |> DateTime.shift_zone!(@timezone) |> Cldr.DateTime.to_string!(opts)

  def format_weeks(weeks, opts \\ []), do: Cldr.Unit.to_string!(weeks, Keyword.put(opts, :unit, "week"))

  def format_date_interval(from, to, opts \\ []), do: Cldr.Interval.to_string!(from, to, opts)

  # credo:disable-for-next-line Credo.Check.Design.AliasUsage
  def format_time_ago(value, opts \\ []), do: Cldr.DateTime.Relative.to_string!(value, opts)

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

  def format_coordinate(val)

  def format_coordinate(val) when is_float(val) do
    truncated = trunc(val)
    if truncated == val, do: truncated, else: val
  end

  def format_coordinate(val), do: val

  @doc ~S"""
  Returns a string of class names from a list of class names.

  ## Examples

      iex> DataAggregatorWeb.Helpers.class_names(["foo", "bar"])
      "foo bar"

      iex> DataAggregatorWeb.Helpers.class_names(["foo", nil, "bar"])
      "foo bar"

      iex> DataAggregatorWeb.Helpers.class_names(["foo", "", "bar"])
      "foo bar"

      iex> DataAggregatorWeb.Helpers.class_names(["foo", false, "bar"])
      "foo bar"

      iex> DataAggregatorWeb.Helpers.class_names(["foo", true, "bar"])
      "foo true bar"

      iex> DataAggregatorWeb.Helpers.class_names(["foo", 1, "bar"])
      "foo 1 bar"

      iex> DataAggregatorWeb.Helpers.class_names(["foo", 0, "bar"])
      "foo 0 bar"
  """
  @spec class_names([String.t()]) :: String.t()
  def class_names(class_names) do
    class_names
    |> Enum.filter(& &1)
    |> Enum.join(" ")
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  def gbif_base_url, do: System.get_env("GBIF_BASE_URL")

  @spec get_actor(Socket.t() | map()) :: User.t()
  def get_actor(%Socket{assigns: %{current_user: %User{} = actor}}), do: actor
  def get_actor(%{current_user: %User{} = actor}), do: actor

  @spec get_tenant(Socket.t() | map()) :: String.t()
  def get_tenant(%Socket{assigns: %{collection: tenant}}), do: tenant
  def get_tenant(%{collection: tenant}), do: tenant

  def maybe_set_user(%User{first_name: first_name, last_name: last_name}) when first_name != nil and last_name != nil,
    do: "#{first_name} #{last_name}"

  def maybe_set_user(%User{email: email}) when email != nil, do: email
  def maybe_set_user(_), do: Phoenix.HTML.raw("&mdash;")
end
