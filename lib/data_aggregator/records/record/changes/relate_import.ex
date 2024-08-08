defmodule DataAggregator.Records.Record.Changes.RelateImport do
  @moduledoc """
  Relate a record to an import.
  """

  use Ash.Resource.Change

  alias Ash.Changeset
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Record

  @impl Ash.Resource.Change
  def batch_change(changesets, _opts, _ctx) do
    changesets
  end

  @impl Ash.Resource.Change
  def change(%Changeset{} = changeset, _opts, %{bulk?: true}) do
    changeset
  end

  @impl Ash.Resource.Change
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.after_action(changeset, &create_import_record/2)
  end

  @impl Ash.Resource.Change
  def after_batch(batch, _opts, _ctx) do
    import_record_args = fn {changeset, record} ->
      import = Changeset.get_argument(changeset, :import)
      %{import: import, record: record}
    end

    batch
    |> Stream.map(import_record_args)
    |> bulk_create_import_records()
    |> Stream.run()

    :ok
  end

  defp bulk_create_import_records(stream) do
    Ash.bulk_create(stream, Import.Record, :create,
      batch_size: 1000,
      # max_concurrency: 4, # does not work in tests
      return_records?: true,
      return_errors?: true,
      return_stream?: true
    )
  end

  defp create_import_record(%Changeset{} = changeset, %Record{} = record) do
    import = Changeset.get_argument(changeset, :import)

    with {:ok, _, notifications} <-
           Import.Record.create(import, record, return_notifications?: true) do
      {:ok, record, notifications}
    end
  end
end
