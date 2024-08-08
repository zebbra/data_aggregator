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

    %{file_url: attachment.url}
    |> Map.merge(attrs)
    |> Approval.create!()
  end

  @doc """
  Generate an approved_record
  """
  def approved_record_fixture(attrs \\ %{}) do
    record = RecordsFixtures.record_fixture()

    attributes = [:extra_data] ++ DataAggregator.DarwinCore.Schema.prefixed_attribute_names()

    record
    |> Map.from_struct()
    |> Map.merge(attrs)
    |> Map.take(attributes)
    |> Map.put_new_lazy(:record, fn -> record end)
    |> ApprovedRecord.create!()
  end
end
