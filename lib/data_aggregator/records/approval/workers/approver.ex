defmodule DataAggregator.Records.Approval.Workers.Approver do
  @moduledoc """
  `Oban.Worker` to run `DataAggregator.Records.Approval.run/1` async.

  Used in `DataAggregator.Records.Approval.enqueue/1` (and tests) like:

  ```elixir
  {:ok, approval} =
    approval_id
    |> DataAggregator.Records.Approval.get_by_id!()
    |> DataAggregator.Records.Approval.enqueue()
  ```

  ## Arguments

  * `id` - the ID of the approval to run
  * `collection_id` - the ID of the collection to approve

  """

  use Oban.Worker, queue: :approvals, max_attempts: 1

  alias DataAggregator.Records
  alias DataAggregator.Records.Approval

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id, "collection_id" => collection_id}}) do
    collection = DataAggregator.Records.Collection.get_by_id!(collection_id)

    with {:ok, approval} <- Approval.get_by_id(id, tenant: collection) do
      Logger.info("Running approval #{inspect(approval.id)} ...")
      Approval.run(approval)
    end
  end

  @impl Oban.Worker
  def timeout(_job), do: Records.approval_timeout() + :timer.minutes(1)
end
