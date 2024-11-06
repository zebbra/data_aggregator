defmodule DataAggregator.Records.Record.Changes.CreateEncodedRecordAfterAction do
  @moduledoc """
  Calls `DataAggregator.Records.EncodedRecord.create/1` after the action has completed
  to create the associated `EncodedRecord`.
  """

  use Ash.Resource.Change

  alias DataAggregator.Records.EncodedRecord

  require Logger

  @attributes [
                :extra_data,
                :iucn_redlist_category
              ] ++ DataAggregator.DarwinCore.Schema.prefixed_attribute_names()

  @impl true
  def batch_change(changesets, _opts, _context) do
    changesets
  end

  @impl true
  def before_batch(changesets, _opts, _context) do
    changesets
  end

  @impl true
  def after_batch(batch, _opts, %{tenant: tenant}) do
    records = Enum.map(batch, fn {_, record} -> record end)

    params =
      for record <- records do
        record
        |> Map.from_struct()
        |> Map.take(@attributes)
        |> Map.filter(fn {_, v} -> v != nil end)
        |> Map.put(:record, record)
        |> Map.put(:collection, record.collection)
      end

    # use the same batch size as the import
    batch_size = DataAggregator.Records.import_batch_size()

    # we have ~280 attributes and PG can handle 65535 params, to we can batch up to ~200 records
    batch_size = Enum.min([batch_size, 200])

    Logger.info("Creating #{length(params)} encoded records (batch size: #{batch_size}) ...")

    Ash.bulk_create!(params, EncodedRecord, :create,
      batch_size: batch_size,
      return_errors?: true,
      tenant: tenant
    )

    :ok
  end
end
