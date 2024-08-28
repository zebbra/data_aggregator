defmodule DataAggregator.Records.Record.Changes.SetImportedAfterActionNew do
  @moduledoc """
  Calls `DataAggregator.Records.Record.set_imported/1` after the action has completed
  to update the state to `:imported`.
  """

  use Ash.Resource.Change

  require Logger

  @impl true
  def batch_change(changesets, _opts, _context) do
    changesets
  end

  @impl true
  def before_batch(changesets, _opts, _context) do
    changesets
  end

  @impl true
  def after_batch(batch, _opts, _context) do
    # use the same batch size as the import
    batch_size = DataAggregator.Records.import_batch_size()

    batch
    |> Enum.map(fn {_, record} -> record end)
    |> Ash.bulk_update!(:set_imported, %{},
      stream_batch_size: batch_size,
      return_records?: true,
      return_errors?: true
    )
  end
end
