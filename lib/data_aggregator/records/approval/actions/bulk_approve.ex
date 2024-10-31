defmodule DataAggregator.Records.Approval.Actions.BulkApprove do
  @moduledoc """
  Custom action to bulk approve a stream of rows using `DataAggregator.Records.AprovedRecord.approve/2`
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records
  alias DataAggregator.Records.ApprovedRecord

  require Logger

  @impl true
  def run(input, _opts, _ctx) do
    %{rows: rows} = input.arguments

    max_concurrency = Records.import_max_concurrency()
    batch_size = ceil(Records.approval_batch_size() / max_concurrency)

    Logger.debug("Bulk approving records with batch size #{batch_size} (concurrency: #{max_concurrency}) ...")

    result =
      rows
      |> Stream.map(& &1)
      |> Ash.bulk_create!(ApprovedRecord, :approve,
        return_errors?: true,
        return_records?: true,
        max_concurrency: max_concurrency,
        batch_size: batch_size,
        tenant: input.tenant
      )

    {:ok, result}
  end
end
