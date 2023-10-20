defmodule DataAggregatorWeb.Helpers do
  alias DataAggregatorWeb.Cldr
  alias Plug.Conn.Query

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

  def serialize_params(params, allowed_keys \\ ["filter", "order_by"]) do
    params
    |> Map.take(allowed_keys)
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Map.new()
  end

  # https://spapas.github.io/2019/10/17/declarative-ecto-query-sorting/
  def order_by_options(active_link, params, sort_fields \\ []) do
    sort_fields
    |> Enum.into(%{}, fn key -> {key, create_order_url(active_link, params, to_string(key))} end)
  end

  def get_current_order_attr(order_by) do
    case order_by do
      "-" <> order -> order
      order when is_binary(order) -> order
      _ -> nil
    end
  end

  def get_current_order_dir(order_by) do
    case order_by do
      "-" <> _ -> "desc"
      _ -> "asc"
    end
  end

  defp create_order_url(
         active_link,
         params,
         field_name,
         allowed_keys \\ ["filter"]
       ) do
    "/#{active_link}?#{Query.encode(get_order_params(params, allowed_keys, field_name))}"
  end

  defp get_order_params(params, allowed_keys, order_key) do
    params
    |> Map.take(allowed_keys ++ ["order_by"])
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    |> Map.new()
    |> Map.update(
      :order_by,
      order_key,
      &case &1 do
        "-" <> ^order_key -> order_key
        ^order_key -> "-" <> order_key
        _ -> "-" <> order_key
      end
    )
  end
end
