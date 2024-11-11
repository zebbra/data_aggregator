defmodule DataAggregator.Records.Record.Calculations.Changes do
  @moduledoc """
  Module for calculating changes between imported, encoded, and approved records.
  """

  use Ash.Resource.Calculation

  alias DataAggregator.DarwinCore.Schema
  alias DataAggregator.Records.EncodedRecord

  require Ash.Query

  @transformers Schema.dwc_transformers()

  @impl true
  def load(_query, _opts, _ctx) do
    :encoded_record
  end

  @impl true
  def calculate(records, _opts, ctx) do
    if length(records) > 1 do
      raise "Only one record is allowed for this calculation due to performance reasons."
    end

    %{arguments: opts} = ctx

    Enum.map(records, fn record ->
      record.encoded_record
      |> encoded_record_changes(record, ctx)
      |> merge_imported_and_encoded_changes(record)
      |> maybe_transform_values(opts)
      |> maybe_escape_nil(opts)
    end)
  end

  defp encoded_record_changes(encoded_record, record, ctx) do
    %{tenant: tenant} = ctx

    EncodedRecord.Version
    |> Ash.Query.set_tenant(tenant)
    |> Ash.Query.filter(version_action_name: :update)
    |> Ash.Query.filter(version_source_id: encoded_record.id)
    |> Ash.Query.filter(version_inserted_at: %{gt: record.last_imported_at})
    |> Ash.Query.sort(version_inserted_at: :asc)
    |> Ash.read!()
    |> Enum.map(& &1.changes)
    |> Enum.reduce(%{}, &Map.merge/2)
    |> AshPagify.Misc.atomize_keys(depth: 1, existing?: true)
  end

  defp merge_imported_and_encoded_changes(encoded_changes, record) do
    Enum.reduce(Map.keys(encoded_changes), %{}, fn key, acc ->
      imported_value = Map.get(record, key)
      encoded_value = encoded_changes[key]

      if imported_value == encoded_value do
        acc
      else
        Map.put(acc, key, %{
          category_name: key |> Atom.to_string() |> String.split("_") |> List.first(),
          name: Schema.dwc_field_from_prefixed_attribute_name(key),
          imported: imported_value,
          encoded: encoded_value
        })
      end
    end)
  end

  defp maybe_transform_values(changes, %{transform?: true}) do
    Enum.map(changes, fn {key, %{imported: imported, encoded: encoded} = entry} ->
      transformer = @transformers[key]

      if transformer do
        {key, Map.merge(entry, %{imported: transformer.(imported), encoded: transformer.(encoded)})}
      else
        {key, entry}
      end
    end)
  end

  defp maybe_transform_values(changes, _opts), do: changes

  defp maybe_escape_nil(changes, %{escape_nil?: true}) do
    Enum.map(changes, fn {key, %{imported: imported, encoded: encoded} = entry} ->
      {key,
       Map.merge(entry, %{
         imported: escape_nil(imported),
         encoded: escape_nil(encoded)
       })}
    end)
  end

  defp maybe_escape_nil(changes, _opts), do: changes

  defp escape_nil(value) when value in [nil, ""], do: "-"
  defp escape_nil(value), do: value
end
