defmodule DataAggregator.EncodedRecordsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """

  alias DataAggregator.Records.EncodedRecord

  import DataAggregator.RecordsFixtures

  @encoded_record_defaults %{
    mte_material_entity_id: "encoded_record1",
    tax_scientific_name: "06809dc5-f143-459a-be1a-6f03e63fc083"
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
end
