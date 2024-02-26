defmodule DataAggregator.Records.Record.Changes.DestroyVersions do
  @moduledoc """
  This change destroys all versions of a record while destroying the record itself
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records
  alias DataAggregator.Records.Record

  require Logger

  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &delete_versions/2, append: true)
  end

  defp delete_versions(%Changeset{}, %Record{} = record) do
    record = Records.load!(record, [:paper_trail_versions], lazy?: true)

    Enum.each(record.paper_trail_versions, &Record.Version.destroy!(&1))

    {:ok, record}
  end
end
