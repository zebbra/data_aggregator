defmodule DataAggregator.Records.Record.ExtractAttributesHelpers do
  @moduledoc false
  alias DataAggregator.DarwinCore.Schema

  @attributes_to_convert [:boolean]
                         |> Enum.map(fn type ->
                           Schema.attributes_of_type(type)
                         end)
                         |> List.flatten()

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
  """
  @spec maybe_convert_values({atom(), any()}) :: {atom(), any()}
  def maybe_convert_values(_)

  def maybe_convert_values({import_attr, nil}), do: {import_attr, nil}

  def maybe_convert_values({import_attr, value}) do
    @attributes_to_convert
    |> Enum.find(fn {schema_attr, _schema_type} -> schema_attr == import_attr end)
    |> case do
      nil -> {import_attr, value}
      {_schema_attr, schema_type} -> {import_attr, maybe_convert_value({value, schema_type})}
    end
  end

  @doc """
  Converts a value to the correct type, according to the db schema (/Users/clau/projects/data_aggregator/lib/data_aggregator/darwin_core/schema/schema.ex)

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
