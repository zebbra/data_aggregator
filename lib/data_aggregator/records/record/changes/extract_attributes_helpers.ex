defmodule DataAggregator.Records.Record.ExtractAttributesHelpers do
  @moduledoc """
  This module contains helper functions to make import data ready to be stored in the database
  """
  alias DataAggregator.DarwinCore.Schema

  require Logger

  # add here the (db) schema types that need to be converted
  @attributes_to_convert [:boolean, :string, :integer]
                         |> Enum.map(fn type ->
                           Schema.attributes_of_type(type)
                         end)
                         |> List.flatten()

  @spec extract_attributes(map()) :: {map(), map()}
  def extract_attributes(_)

  def extract_attributes(nil), do: {%{}, nil}

  def extract_attributes(params) do
    params
    |> Map.to_list()
    |> Enum.map(&convert_attr_to_atom/1)
    |> Enum.map(&maybe_convert_values/1)
    |> to_map_and_stringify_keys()
    |> Map.split(record_attributes())
  end

  @doc ~S"""
    Converts all keys in a map to strings

    ## Examples

        iex> list = [eve_event_date: "2024-05-07 20:24:08.365465", eve_mosses_identified: true]
        iex> to_map_and_stringify_keys(list)
        %{"eve_event_date" => "2024-05-07 20:24:08.365465", "eve_mosses_identified" => true}

        iex> list = nil
        iex> to_map_and_stringify_keys(list)
        %{}
  """
  @spec to_map_and_stringify_keys(Keyword.t()) :: map
  def to_map_and_stringify_keys(_)
  def to_map_and_stringify_keys(nil), do: %{}

  def to_map_and_stringify_keys(list) do
    for {k, v} <- list, into: %{} do
      {stringify(k), v}
    end
  end

  @doc """
    Converts an attribute to an atom

    ## Examples

        iex> convert_attr_to_atom({"eve_event_date", "2024-05-07 20:24:08.365465"})
        {:eve_event_date, "2024-05-07 20:24:08.365465"}

        iex> convert_attr_to_atom({"eve_mosses_identified", true})
        {:eve_mosses_identified, true}

        iex> convert_attr_to_atom({"eve_mosses_identified", nil})
        {:eve_mosses_identified, nil}

        iex> convert_attr_to_atom({"bluu", nil})
        {:bluu, nil}

        iex> convert_attr_to_atom({:bluu, nil})
        {:bluu, nil}
  """
  @spec convert_attr_to_atom({atom() | String.t(), any()}) :: {atom(), any()}
  def convert_attr_to_atom(_)

  def convert_attr_to_atom({attr, value}) when is_binary(attr) do
    attr = String.to_atom(attr)

    {attr, value}
  end

  def convert_attr_to_atom({attr, value}), do: {attr, value}

  @doc """
  Converts values to the correct type, if type is in @attributes_to_convert

  ## Examples

      iex> maybe_convert_values({:eve_mosses_identified, "true"})
      {:eve_mosses_identified, true}

      iex> maybe_convert_values({:eve_mosses_identified, true})
      {:eve_mosses_identified, true}

      iex> maybe_convert_values({:eve_mosses_identified, "1"})
      {:eve_mosses_identified, true}

      iex> maybe_convert_values({:eve_mosses_identified, 1})
      {:eve_mosses_identified, true}

      iex> maybe_convert_values({:eve_mosses_identified, "yes"})
      {:eve_mosses_identified, true}

      iex> maybe_convert_values({:eve_mosses_identified, "false"})
      {:eve_mosses_identified, false}

      iex> maybe_convert_values({:eve_mosses_identified, false})
      {:eve_mosses_identified, false}

      iex> maybe_convert_values({:eve_mosses_identified, "0"})
      {:eve_mosses_identified, false}

      iex> maybe_convert_values({:eve_mosses_identified, 0})
      {:eve_mosses_identified, false}

      iex> maybe_convert_values({:eve_mosses_identified, "no"})
      {:eve_mosses_identified, false}

      iex> maybe_convert_values({:eve_mosses_identified, "maybe"})
      {:eve_mosses_identified, false}

      iex> maybe_convert_values({:eve_mosses_identified, nil})
      {:eve_mosses_identified, nil}

      iex> maybe_convert_values({:tax_taxon_id_ch, "infofauna:100"})
      [{:oth_swiss_species_center, "infofauna"}, {:tax_taxon_id_ch, 100}]

      iex> maybe_convert_values({:tax_taxon_id_ch, "200"})
      {:tax_taxon_id_ch, 200}
  """
  @spec maybe_convert_values({atom(), any()}) :: {atom(), any()} | [{atom(), [any()]}]
  def maybe_convert_values(_)

  def maybe_convert_values({:tax_taxon_id_ch, value}) when is_binary(value) do
    if String.contains?(value, ":") do
      [center, taxon_id_ch] = value |> String.trim() |> String.split(":", trim: true)

      [
        do_convert_values({:oth_swiss_species_center, center}),
        do_convert_values({:tax_taxon_id_ch, taxon_id_ch})
      ]
    else
      do_convert_values({:tax_taxon_id_ch, value})
    end
  end

  def maybe_convert_values(val), do: do_convert_values(val)

  defp do_convert_values({import_attr, nil}), do: {import_attr, nil}

  defp do_convert_values({import_attr, value}) do
    @attributes_to_convert
    |> Enum.find(fn {schema_attr, _schema_type} -> schema_attr == import_attr end)
    |> case do
      nil -> {import_attr, value}
      {_schema_attr, schema_type} -> {import_attr, maybe_convert_value({value, schema_type})}
    end
  end

  @doc """
  Converts a value to the correct type, according to the db schema (/Users/clau/projects/data_aggregator/lib/data_aggregator/darwin_core/schema/schema.ex)

  implement your `maype_convert_value({value, :your_type})` function, to convert imported values of a certain type the way you want

    ## Examples

        iex> maybe_convert_value({"true", :boolean})
        true

        iex> maybe_convert_value({true, :boolean})
        true

        iex> maybe_convert_value({"yes", :boolean})
        true

        iex> maybe_convert_value({"1", :boolean})
        true

        iex> maybe_convert_value({1, :boolean})
        true

        iex> maybe_convert_value({"false", :boolean})
        false

        iex> maybe_convert_value({"no", :boolean})
        false

        iex> maybe_convert_value({"0", :boolean})
        false

        iex> maybe_convert_value({0, :boolean})
        false

        iex> maybe_convert_value({"maybe", :boolean})
        false

        iex> maybe_convert_value({nil, :boolean})
        nil

        iex> maybe_convert_value({nil, :integer})
        nil

        iex> maybe_convert_value({"100", :integer})
        100

  """
  @spec maybe_convert_value({any(), any()}) :: any()
  def maybe_convert_value(_)

  def maybe_convert_value({nil, _}), do: nil

  # Convert value to string if it is not a binary
  def maybe_convert_value({value, type}) when not is_binary(value), do: maybe_convert_value({to_string(value), type})

  # Convert value to boolean if it is "truthy"
  def maybe_convert_value({value, :boolean}) do
    String.downcase(value) in ["true", "yes", "1"]
  end

  # Convert value to integer
  def maybe_convert_value({value, :integer}) do
    case Integer.parse(value) do
      :error ->
        Logger.warning("Failed to parse integer from binary #{value}")

        value

      {integer, ""} ->
        integer

      _ ->
        Logger.warning("Failed to parse integer from binary #{value}")

        value
    end
  end

  # Default case, return value as is
  def maybe_convert_value({value, _}), do: value

  defp record_attributes do
    for %{name: name} <- Schema.prefixed_attributes() do
      stringify(name)
    end
  end

  defp stringify(val) when is_atom(val), do: Atom.to_string(val)
  defp stringify(val) when is_binary(val), do: val
end
