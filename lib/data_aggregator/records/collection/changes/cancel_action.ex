defmodule DataAggregator.Records.Collection.Changes.CancelAction do
  @moduledoc """
  Cancels the current active action of a Collection. Depeneding on the action
  it will:

  1. cancel the enqueuer if present
  2. cancel the worker job
  3. cancel all enqueued jobs
  4. updates the underlying records to reflect the new state
  5. updates the underlying entity to reflect the new state
  6. sets the collection to idle
  """

  use Ash.Resource.Change

  import DateTime, only: [utc_now: 0]

  alias Ash.Changeset
  alias DataAggregator.Jobs.Job
  alias DataAggregator.Records.Export
  alias DataAggregator.Records.ImageUpload
  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Publication
  alias DataAggregator.Records.Record

  require Ecto.Query
  require Logger

  @impl true
  def change(%Changeset{} = changeset, _opts, _ctx) do
    Changeset.before_transaction(changeset, &cancel_action/1)
  end

  defp cancel_action(%Changeset{data: %{state: state}} = changeset) do
    Logger.info("Cancelling action: #{state}")

    case state do
      :importing ->
        cancel_import(changeset)

      :mapping ->
        cancel_image_mapping(changeset)

      :exporting ->
        cancel_export(changeset)

      :encoding ->
        cancel_encoding(changeset)

      :fast_track_publishing ->
        cancel_publication(changeset)

      :approving ->
        cancel_approvals(changeset)

      _ ->
        Changeset.add_error(
          changeset,
          "You are not allowed to cancel an action in state: #{state}"
        )
    end
  rescue
    _ -> Changeset.add_error(changeset, "An error occured while cancelling the action")
  end

  defp cancel_import(%Changeset{data: %{id: collection_id}} = changeset) do
    cancel_all_jobs(Job.query_to_imports_by_collection(collection_id))

    active_import =
      collection_id
      |> Import.query_to_active_by_collection()
      |> Ash.read_one!()

    if active_import do
      Import.cancel_import!(active_import)
    end

    changeset
  end

  defp cancel_image_mapping(%Changeset{data: %{id: collection_id}} = changeset) do
    cancel_all_jobs(Job.query_to_image_mappings_by_collection(collection_id))

    active_image_mapping =
      collection_id
      |> ImageUpload.query_to_active_by_collection()
      |> Ash.read_one!()

    if active_image_mapping do
      ImageUpload.cancel_mapping!(active_image_mapping)
    end

    changeset
  end

  defp cancel_export(%Changeset{data: %{id: collection_id}} = changeset) do
    cancel_all_jobs(Job.query_to_exports_by_collection(collection_id))

    active_export =
      Export.query_to_active()
      |> Ash.Query.set_tenant(collection_id)
      |> Ash.read_one!()

    if active_export do
      Export.cancel_export!(active_export)
    end

    changeset
  end

  defp cancel_encoding(%Changeset{data: %{id: collection_id}} = changeset) do
    # This will cancel all workers
    # 1. DataAggregator.Records.Collection.Workers.EncodingStatePoller
    # 2. DataAggregator.Records.Collection.Workers.RecordsEnqueuer
    # 3. DataAggregator.Records.Record.Workers.Encoder
    cancel_all_jobs(Job.query_to_encodings_by_collection(collection_id))

    # Update all records which are in encoding / queued state to failed
    collection_id
    |> Record.query_to_encoding_by_collection()
    |> Ash.bulk_update!(
      :update,
      %{state: :failed}
    )

    changeset
  end

  defp cancel_publication(%Changeset{data: %{id: collection_id}} = changeset) do
    cancel_all_jobs(Job.query_to_publications_by_collection(collection_id))
    # we do not cancel publication verifications as there might be jobs still running
    # from the previous publication

    active_publication =
      collection_id
      |> Publication.query_to_active_by_collection()
      |> Ash.read_one!()

    if active_publication do
      Publication.cancel_publication!(active_publication)
    end

    changeset
  end

  defp cancel_approvals(%Changeset{data: %{id: collection_id}} = changeset) do
    # Approvals have the same underlying structure as publications. But each
    # approval can have multiple publications. We need to cancel all active
    # publications. The publications are enqueued with the Collection.approve
    # action. There might occur the case the we abort the approval
    # while some publications have not yet been enqueued. However, we do not
    # account for this case as it is not a common use case.
    cancel_all_jobs(Job.query_to_publications_by_collection(collection_id))

    collection_id
    |> Publication.query_to_active_by_collection()
    |> Ash.bulk_update!(
      :update,
      %{state: :failed, finished_at: DateTime.utc_now()}
    )

    changeset
  end

  @doc """
  Cancel many jobs based on a queryable and mark them as `cancelled` to prevent them from running.
  Any currently `executing` jobs are killed while the others are ignored.

  If executing jobs happen to fail before cancellation then the state is set to `cancelled`.
  However, any that complete successfully will remain `completed`.

  Only jobs with the statuses `executing`, `available`, `scheduled`, or `retryable` can be cancelled.

  > Note: This is take from the original Oban source code and adapted to work with Ash.Query.

  ## Example

  Cancel all jobs:

      Oban.cancel_all_jobs(Oban.Job)
      {:ok, 9}

  Cancel all jobs for a specific worker:

      Oban.Job
      |> Ash.Query.filter(worker: "MyApp.MyWorker")
      |> Oban.cancel_all_jobs()
      {:ok, 2}
  """
  @spec cancel_all_jobs(Ash.Query.t()) :: {:ok, non_neg_integer()}
  def cancel_all_jobs(query) do
    %{records: aborted_jobs} = ash_cancel_all_jobs(query)

    payload =
      for %{id: id} <- aborted_jobs || [] do
        %{action: :pkill, job_id: id}
      end

    Oban.Notifier.notify(:signal, payload)

    {:ok, length(aborted_jobs)}
  end

  @spec ash_cancel_all_jobs(Ash.Query.t()) :: Ash.BulkResult.t()
  def ash_cancel_all_jobs(base_query) do
    query =
      base_query
      |> Ash.Query.filter(state not in [:cancelled, :completed, :discarded, :executing])
      |> Ash.Query.select([:id, :queue, :state])

    # Exclude executing jobs from this bulk_update as we need to return only cancelled jobs
    # which have been in state executing (see below)
    Ash.bulk_update(query, :update, %{state: :cancelled, cancelled_at: utc_now()}, reuse_values?: true)

    query =
      base_query
      |> Ash.Query.filter(state == "executing")
      |> Ash.Query.select([:id, :queue, :state])

    Ash.bulk_update(query, :update, %{state: :cancelled, cancelled_at: utc_now()},
      return_records?: true,
      reuse_values?: true
    )
  end
end
