defmodule DataAggregator.ApprovalFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Approval
  alias DataAggregator.Records.ApprovedRecord
  alias DataAggregator.RecordsFixtures

  @doc """
  Generate a approval
  """
  def approval_fixture(attrs \\ %{}) do
    path = "test/support/fixtures/files/approval_dwca.zip"

    attachment = Attachment.import_from_path!(path)

    params =
      %{file_url: attachment.url}
      |> Map.merge(attrs)
      |> Map.put_new_lazy(:collection, fn ->
        RecordsFixtures.collection_fixture(%{grscicoll_reference: Ecto.UUID.generate()})
      end)

    Approval.create!(params, tenant: params.collection)
  end

  @doc """
  Generate an approved_record
  """
  def approved_record_fixture(attrs \\ %{}, record_attrs \\ %{}) do
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
    |> ApprovedRecord.create!(tenant: record.collection)
  end
end
