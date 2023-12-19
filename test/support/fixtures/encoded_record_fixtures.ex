defmodule DataAggregator.EncodedRecordsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """

  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Record

  import DataAggregator.RecordsFixtures

  @encoded_record_defaults %{
    mte_material_entity_id: "encoded_record1",
    tax_scientific_name: "Oenanthe Pallas, 1771",
    tax_kingdom: "Animalia"
  }

  @doc """
  Generate a encoded_record.
  """
  def encoded_record_fixture(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:record, fn -> record_fixture() end)
    |> EncodedRecord.create!()
  end

  def record_fixture_for_encoding(attrs \\ %{}) do
    @encoded_record_defaults
    |> Map.merge(attrs)
    |> Map.put_new_lazy(:collection, fn -> collection_fixture() end)
    |> Record.create!()
  end
end
