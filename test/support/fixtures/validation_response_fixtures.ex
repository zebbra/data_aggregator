defmodule DataAggregator.ValidationResponseFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """

  alias DataAggregator.Records.ValidationResponse
  alias DataAggregator.Records.ValidationResponse.ValidatedRecord
  alias DataAggregator.RecordsFixtures

  @doc """
  Generate a validation
  """
  def validation_response_fixture(attrs \\ %{}, file_path \\ "test/support/fixtures/files/validated.zip") do
    params = Map.merge(%{type: :validated}, attrs)

    ValidationResponse.create_from_path!(
      file_path,
      "test/support/fixtures/files/validated.zip",
      params
    )
  end

  @doc """
  Generate an validated_record
  """
  def validated_record_fixture(attrs \\ %{}, record_attrs \\ %{}) do
    collection =
      if Map.has_key?(attrs, :collection) do
        Map.get(attrs, :collection)
      else
        RecordsFixtures.collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
      end

    record =
      if Map.has_key?(attrs, :record) do
        Map.get(attrs, :record)
      else
        RecordsFixtures.record_fixture(Map.put(record_attrs, :collection, collection))
      end

    attributes = [:extra_data] ++ DataAggregator.DarwinCore.Schema.prefixed_attribute_names()

    record
    |> Map.from_struct()
    |> Map.merge(attrs)
    |> Map.take(attributes)
    |> Map.put_new_lazy(:record, fn -> record end)
    |> Map.put_new_lazy(:collection, fn -> record.collection end)
    |> ValidatedRecord.create!(tenant: record.collection)
  end
end
