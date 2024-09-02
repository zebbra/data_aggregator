defmodule DataAggregatorWeb.Filters.Helpers do
  @moduledoc """
  Provides helper functions for filters with the `AshPagify.FilterForm` and
  `AshPhoenix.FilterForm` module.
  """

  import DataAggregatorWeb.Helpers, only: [format_number: 1]

  alias AshPagify.FilterForm
  alias AshPhoenix.FilterForm.Predicate

  @doc """
  Returns true if the value is present, false otherwise.

  ## Examples

      iex> present?(%AshPhoenix.FilterForm.Predicate{value: nil})
      false

      iex> present?(%AshPhoenix.FilterForm.Predicate{value: ""})
      false

      iex> present?(%AshPhoenix.FilterForm.Predicate{value: " "})
      false

      iex> present?(%AshPhoenix.FilterForm.Predicate{value: []})
      false

      iex> present?(%AshPhoenix.FilterForm.Predicate{value: [1, 2, 3]})
      true

      iex> present?(%AshPhoenix.FilterForm.Predicate{value: "foo"})
      true
  """
  @spec present?(term() | String.t() | list() | nil) :: boolean()
  def present?(%Predicate{value: value}) do
    !blank?(value)
  end

  def present?(%FilterForm{components: components}) do
    Enum.any?(components, &present?/1)
  end

  def present?(value) do
    !blank?(value)
  end

  @doc """
  Returns true if the value is blank, false otherwise.

  ## Examples

      iex> blank?(%AshPhoenix.FilterForm.Predicate{value: nil})
      true

      iex> blank?(%AshPhoenix.FilterForm.Predicate{value: ""})
      true

      iex> blank?(%AshPhoenix.FilterForm.Predicate{value: " "})
      true

      iex> blank?(%AshPhoenix.FilterForm.Predicate{value: []})
      true

      iex> blank?(%AshPhoenix.FilterForm.Predicate{value: [1, 2, 3]})
      false

      iex> blank?(%AshPhoenix.FilterForm.Predicate{value: "foo"})
      false
  """
  @spec blank?(term() | String.t() | list() | nil) :: boolean()
  def blank?(%Predicate{value: value}) do
    blank?(value)
  end

  def blank?([]) do
    true
  end

  def blank?(str_or_nil) do
    "" == str_or_nil |> to_string() |> String.trim()
  end

  @shift_date_unites [
    :microseconds,
    :milliseconds,
    :seconds,
    :minutes,
    :hours,
    :days,
    :weeks,
    :months,
    :years,
    :century
  ]

  @type shift_date_unit ::
          unquote(
            @shift_date_unites
            |> Enum.map_join(" | ", &inspect/1)
            |> Code.string_to_quoted!()
          )

  @doc """
  A single function for shifting dates back using various units: milliseconds,
  seconds, minutes, hours, days, weeks, months, years, century.

  Uses the `Timex` library to shift the date.

  Shift is done backwards by amount of -1 by default. To shift forward,
  use a positive amount.

  ## Examples

      iex> shift_date(:days, -1, ~U[2020-01-02 00:00:00Z])
      ~U[2020-01-01 00:00:00Z]

      iex> shift_date("days", -1, ~U[2020-01-02 00:00:00Z])
      ~U[2020-01-01 00:00:00Z]

      iex> date = ~D[2016-02-15]
      ...> shift_date(:months, -1, date)
      ~D[2016-01-15]

      iex> date = ~D[2016-01-15]
      ...> shift_date(:century, -1, date)
      ~D[1916-01-15]

  ### Shifting across timezone changes

      iex> use Timex
      ...> datetime = Timex.to_datetime({{2016,3,13}, {1,0,0}}, "America/Chicago")
      ...> # 2-3 AM doesn't exist due to leap forward, shift accounts for this
      ...> %DateTime{hour: 3} = shift_date(:hours, 1, datetime)
      ...> shifted = shift_date(:hours, 1, datetime)
      ...> {datetime.zone_abbr, shifted.zone_abbr, shifted.hour}
      {"CST", "CDT", 3}
  """
  @spec shift_date(unit :: shift_date_unit(), amount :: integer(), Date.t() | DateTime.t()) ::
          Date.t() | DateTime.t()
  def shift_date(unit, amount \\ -1, date \\ Date.utc_today())

  def shift_date(unit, amount, date) when is_binary(unit) do
    shift_date(String.to_existing_atom(unit), amount, date)
  end

  def shift_date(:century, _amount, date) do
    shift_date(:years, -100, date)
  end

  def shift_date(unit, amount, date) do
    Timex.shift(date, Keyword.new([{unit, amount}]))
  end

  @doc """
  Formats a count of items to a human-readable string.

  If the count is greater than 1000, it will be formatted as `1,000+`.

  ## Examples

      iex> format_count(100)
      "100"

      iex> format_count(1000)
      "1,000"

      iex> format_count(1001)
      "1,000+"
  """
  @spec format_count(integer()) :: String.t()
  def format_count(count) do
    if count > 1000 do
      count = format_number(1000)
      "#{count}+"
    else
      format_number(count)
    end
  end
end
