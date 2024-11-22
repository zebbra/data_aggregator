defmodule DataAggregator.Records.Record.Changes.RelateImport do
  @moduledoc """
  Relate a record to an import.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias Ash.Resource.Change
  alias DataAggregator.Records.Import

  @impl Change
  def batch_change(changesets, _opts, _ctx) do
    Enum.to_list(changesets)
  end

  @impl Change
  def before_batch(changesets, _opts, _ctx) do
    changesets
  end

  @impl Change
  def after_batch(batch, _opts, ctx) do
    import_record_args = fn {changeset, record} ->
      import = Changeset.get_argument(changeset, :import)
      %{import_id: import.id, record_id: record.id, collection_id: import.collection_id}
    end

    batch
    |> Stream.map(import_record_args)
    |> bulk_create_import_records!(ctx)

    Enum.map(batch, fn {_, record} -> {:ok, record} end)
  end

  defp bulk_create_import_records!(stream, %{tenant: tenant}) do
    # use the same batch size as the import
    batch_size = DataAggregator.Records.import_batch_size()

    # we have ~280 attributes and PG can handle 65535 params, to we can batch up to ~200 records
    # batch_size = Enum.min([batch_size, 200])

    Ash.bulk_create!(stream, Import.Record, :create,
      batch_size: batch_size,
      return_errors?: true,
      tenant: tenant
    )
  end
end
