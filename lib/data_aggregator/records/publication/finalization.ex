defmodule DataAggregator.Records.Publication.Finalization do
  @moduledoc """
  Flips `:publishing` records of a collection to `:published`.

  Shared by `DataAggregator.Records.Publication.Scheduler.PublicationFinalizer` (the normal
  path) and `DataAggregator.Records.Publication.Scheduler.PublicationFinalizerSweeper` (the
  safety net). The two differ only in how they select the records and what they do with a
  failure, so the bulk update itself lives here and the failure is handed back to the caller.
  """
  alias DataAggregator.Records.Record

  @batch_size 1000

  @doc "Batch size used for streaming and for the bulk update."
  @spec batch_size() :: pos_integer()
  def batch_size, do: @batch_size

  @doc """
  Sets every record matched by `query` to `:published`, returning how many were changed.

  Options: `:actor` - credited with the status change, `nil` for a system-initiated sweep.
  """
  @spec finalize(Ash.Query.t(), String.t(), keyword()) ::
          {:ok, non_neg_integer()} | {:error, [term()]}
  def finalize(query, tenant, opts \\ []) do
    query
    |> Ash.Query.set_tenant(tenant)
    |> Record.update_publication_status(:published,
      actor: Keyword.get(opts, :actor),
      authorize?: false,
      tenant: tenant,
      bulk_options: [
        return_records?: true,
        batch_size: @batch_size,
        # `Ash.bulk_update/4` defaults to `[:atomic]` while the code interface widens the
        # strategy, so it is pinned here to keep the produced versions unchanged.
        strategy: [:atomic]
      ]
    )
    |> case do
      %Ash.BulkResult{status: :success, records: records} -> {:ok, length(records || [])}
      %Ash.BulkResult{errors: errors} -> {:error, errors}
    end
  end
end
