defmodule DataAggregator.ApprovalFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DataAggregator.Records` context.
  """

  alias DataAggregator.Files.Attachment
  alias DataAggregator.Records.Approval

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
end
