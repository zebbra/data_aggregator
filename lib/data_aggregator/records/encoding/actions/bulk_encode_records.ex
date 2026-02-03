defmodule DataAggregator.Records.Encoding.Actions.BulkEncodeRecords do
  @moduledoc """
  Bulk encodes a batch of records through all catalogs with optimized bulk operations.

  This module processes multiple records at once, using:
  - Bulk state transitions via `Ash.bulk_update`
  - Parallel strategy execution via `Task.async_stream`
  - Bulk audit trail creation via `Ash.bulk_create`

  ## Error Handling

  When a record fails during encoding:
  - The error is captured and the record is marked as failed
  - Other records in the batch continue processing
  - The job returns `:ok` with a summary of successful/failed records
  """

  alias DataAggregator.Records
  alias DataAggregator.Records.Collection
  alias DataAggregator.Records.EncodedRecord
  alias DataAggregator.Records.Encoding.RecordEncodingResult
  alias DataAggregator.Records.Encoding.Strategy
  alias DataAggregator.Records.Record
  alias DataAggregator.Taxonomy.Catalog

  require Ash.Query
  require Logger

  @type result :: %{
          successful: [String.t()],
          failed: [{String.t(), any()}]
        }

  @type record_state :: %{
          record: Record.t(),
          encoded_record: EncodedRecord.t() | nil,
          failed?: boolean(),
          error: any()
        }

  @doc """
  Bulk encodes records through all catalogs.

  ## Arguments

  * `record_ids` - list of record IDs to encode
  * `collection` - the collection these records belong to
  * `opts` - options including `:actor` and `:tenant`

  ## Returns

  `{:ok, result}` where result contains:
  * `:successful` - list of successfully encoded record IDs
  * `:failed` - list of `{record_id, error}` tuples for failed records
  """
  @spec run(list(String.t()), Collection.t(), Keyword.t()) :: {:ok, result()}
  def run(record_ids, collection, opts \\ []) do
    actor = Keyword.get(opts, :actor)
    tenant = collection

    ctx = %{tenant: tenant, actor: actor}

    # Step 1: Fetch records and bulk transition to :encoding state
    records = fetch_and_transition_to_encoding(record_ids, tenant)

    if Enum.empty?(records) do
      Logger.warning("No records found for encoding in batch")
      {:ok, %{successful: [], failed: []}}
    else
      # Step 2: Process all catalogs for all records
      {final_state, audit_records} = process_all_catalogs(records, ctx)

      # Step 3: Bulk create audit trail (reverse to restore catalog order)
      bulk_create_audit_trail(Enum.reverse(audit_records), tenant)

      # Step 4: Categorize and update final states
      results = categorize_results(final_state)
      bulk_update_final_states(results, tenant)

      # Step 5: Bulk update validation status for successful records
      bulk_update_validation_status(results.successful, tenant, actor)

      {:ok, results}
    end
  rescue
    e ->
      Logger.error("Bulk encoding failed unexpectedly: #{Exception.format(:error, e, __STACKTRACE__)}")

      # Prevent records from being stuck in :encoding or :queued state
      Record
      |> Ash.Query.filter(id in ^record_ids and state in [:encoding, :queued])
      |> Ash.Query.set_tenant(collection)
      |> Ash.bulk_update!(:set_encoding_failed, %{},
        tenant: collection,
        domain: Records,
        resource: Record,
        batch_size: Records.encode_db_batch_size()
      )

      reraise e, __STACKTRACE__
  end

  # Transitions records to :encoding state and returns those that succeeded.
  defp fetch_and_transition_to_encoding(record_ids, tenant) do
    # Bulk update to :encoding state directly from a query (no pre-fetch needed)
    %{error_count: error_count} =
      Record
      |> Ash.Query.filter(id in ^record_ids)
      |> Ash.Query.set_tenant(tenant)
      |> Ash.bulk_update!(
        :set_encoding,
        %{},
        tenant: tenant,
        domain: Records,
        resource: Record,
        batch_size: Records.encode_db_batch_size()
      )

    if error_count > 0,
      do: Logger.warning("#{error_count} records failed to transition to :encoding")

    # Fetch only records that successfully transitioned to :encoding.
    # Note: there is a small race window where a cancel action could transition
    # records to :failed between the bulk_update! above and this query. This is
    # acceptable — those records were being cancelled and should be skipped.
    Record
    |> Ash.Query.filter(id in ^record_ids and state == :encoding)
    |> Ash.Query.set_tenant(tenant)
    |> Ash.Query.load([:encoded_record, :collection])
    |> Ash.read!()
  end

  # Processes all catalogs for the batch of records
  defp process_all_catalogs(records, ctx) do
    # Initialize tracking state for each record
    initial_state =
      Map.new(records, fn record ->
        {record.id,
         %{
           record: record,
           encoded_record: record.encoded_record,
           failed?: false,
           error: nil
         }}
      end)

    # Process each catalog sequentially (order matters!)
    catalogs = Catalog.get_catalogs()

    Enum.reduce(catalogs, {initial_state, []}, fn catalog, {state, audits} ->
      process_catalog_for_batch(catalog, state, audits, ctx)
    end)
  end

  # Processes a single catalog for all records in the batch.
  # Records that failed a previous catalog are still processed — matching the
  # single-record encoder behavior where all catalogs run regardless of earlier
  # failures. The failed? flag is preserved so the record ends up as :failed.
  defp process_catalog_for_batch(catalog, record_state, audit_records, ctx) do
    records_to_process = Enum.to_list(record_state)

    # Bulk pre-fetch encoded records to avoid N+1 queries
    encoded_records_map = bulk_fetch_encoded_records(records_to_process, catalog, ctx)

    # Process records in parallel using Task.async_stream
    max_concurrency = Records.encode_max_concurrency()

    task_results =
      records_to_process
      |> Task.async_stream(
        fn {id, data} ->
          encoded_record = Map.get(encoded_records_map, id)
          encode_single_record_catalog(id, data, encoded_record, catalog, ctx)
        end,
        max_concurrency: max_concurrency,
        timeout: to_timeout(minute: 2),
        on_timeout: :kill_task
      )
      |> Enum.to_list()

    # Zip results with input to identify which record timed out
    records_to_process
    |> Enum.zip(task_results)
    |> Enum.reduce({record_state, audit_records}, fn
      {_input, {:ok, {id, updated_data, audit}}}, {state, audits} ->
        {Map.put(state, id, updated_data), [audit | audits]}

      {{id, data}, {:exit, reason}}, {state, audits} ->
        Logger.error("Record #{id} timed out during catalog #{catalog}: #{inspect(reason)}")

        audit =
          build_audit_record(
            catalog,
            :error,
            data.encoded_record,
            data.encoded_record,
            data.record,
            ctx,
            "Task exit: #{inspect(reason)}"
          )

        {Map.put(state, id, %{data | failed?: true, error: reason}), [audit | audits]}
    end)
  end

  # Bulk fetches encoded records for all records in the batch.
  # For :col_taxonomy (first catalog), creates/upserts encoded records per-record.
  # For subsequent catalogs, fetches all in a single query.
  defp bulk_fetch_encoded_records(records_to_process, :col_taxonomy, ctx) do
    records_to_process
    |> Task.async_stream(
      fn {id, data} ->
        {id, Strategy.ensure_encoded_record_exists(data.record, ctx.tenant)}
      end,
      max_concurrency: Records.encode_max_concurrency(),
      timeout: to_timeout(minute: 1),
      on_timeout: :kill_task
    )
    |> Enum.reduce(%{}, fn
      {:ok, {id, encoded_record}}, acc -> Map.put(acc, id, encoded_record)
      {:exit, _reason}, acc -> acc
    end)
  end

  defp bulk_fetch_encoded_records(records_to_process, _catalog, ctx) do
    record_ids = Enum.map(records_to_process, fn {_id, data} -> data.record.id end)

    encoded_by_record_id =
      EncodedRecord
      |> Ash.Query.filter(record_id in ^record_ids)
      |> Ash.Query.set_tenant(ctx.tenant)
      |> Ash.read!()
      |> Map.new(fn er -> {er.record_id, er} end)

    Map.new(records_to_process, fn {id, data} ->
      {id, Map.get(encoded_by_record_id, data.record.id)}
    end)
  end

  # Handles the case where no encoded record exists (e.g. upsert timed out or DB inconsistency)
  defp encode_single_record_catalog(id, data, nil, catalog, ctx) do
    Logger.error("Record #{id} has no encoded record for catalog #{catalog}")

    audit =
      build_audit_record(
        catalog,
        :error,
        nil,
        nil,
        data.record,
        ctx,
        "No encoded record found"
      )

    {id, %{data | failed?: true, error: "No encoded record found"}, audit}
  end

  # Encodes a single record through a single catalog
  defp encode_single_record_catalog(id, data, encoded_record, catalog, ctx) do
    record = data.record

    # Call the strategy without audit creation (we bulk-create audits later)
    case Strategy.encode_without_audit(encoded_record, catalog, ctx) do
      {:ok, new_encoded_record} ->
        audit =
          build_audit_record(catalog, :success, encoded_record, new_encoded_record, record, ctx)

        {id, %{data | encoded_record: new_encoded_record}, audit}

      {:unchanged, unchanged_encoded_record} ->
        audit =
          build_audit_record(
            catalog,
            :unchanged,
            encoded_record,
            unchanged_encoded_record,
            record,
            ctx
          )

        {id, %{data | encoded_record: unchanged_encoded_record}, audit}

      {:error, error, failed_encoded_record} ->
        audit =
          build_audit_record(
            catalog,
            :error,
            encoded_record,
            failed_encoded_record,
            record,
            ctx,
            error
          )

        {id, %{data | encoded_record: failed_encoded_record, failed?: true, error: error}, audit}
    end
  rescue
    e ->
      error_msg = Exception.format(:error, e, __STACKTRACE__)
      Logger.error("Error encoding record #{id} with catalog #{catalog}: #{error_msg}")

      audit =
        build_audit_record(
          catalog,
          :error,
          data.encoded_record,
          data.encoded_record,
          data.record,
          ctx,
          error_msg
        )

      {id, %{data | failed?: true, error: e}, audit}
  end

  # Builds an audit record for RecordEncodingResult
  defp build_audit_record(catalog, state, old_encoded, new_encoded, record, ctx, error \\ nil) do
    %{
      catalog: catalog,
      state: state,
      input: safe_get_input_values(old_encoded, catalog),
      output: safe_get_output_values(new_encoded, catalog),
      message: format_audit_message(state, error),
      record: record,
      collection: ctx.tenant
    }
  end

  defp format_audit_message(:unchanged, _), do: "no changes during encoding"
  defp format_audit_message(:error, error), do: Strategy.format_error_message(error)
  defp format_audit_message(_, _), do: nil

  defp safe_get_input_values(nil, _catalog), do: %{}

  defp safe_get_input_values(encoded_record, catalog), do: Strategy.get_input_values(encoded_record, catalog)

  defp safe_get_output_values(nil, _catalog), do: %{}

  defp safe_get_output_values(encoded_record, catalog), do: Strategy.get_output_values(encoded_record, catalog)

  # Categorizes the final state into successful and failed records
  defp categorize_results(final_state) do
    {successful, failed} =
      Enum.split_with(final_state, fn {_id, data} -> not data.failed? end)

    %{
      successful: Enum.map(successful, fn {id, _} -> id end),
      failed: Enum.map(failed, fn {id, data} -> {id, data.error} end)
    }
  end

  # Bulk creates RecordEncodingResult audit records
  defp bulk_create_audit_trail(audit_records, tenant) do
    if Enum.empty?(audit_records) do
      :ok
    else
      %{error_count: error_count} =
        Ash.bulk_create!(audit_records, RecordEncodingResult, :create,
          tenant: tenant,
          batch_size: Records.encode_db_batch_size(),
          return_errors?: true
        )

      if error_count > 0,
        do: Logger.warning("#{error_count} audit records failed to create")

      :ok
    end
  end

  # Bulk updates final record states (:encoded or :failed)
  defp bulk_update_final_states(results, tenant) do
    # Bulk update successful records to :encoded
    if Enum.any?(results.successful) do
      %{error_count: error_count} =
        Record
        |> Ash.Query.filter(id in ^results.successful)
        |> Ash.Query.set_tenant(tenant)
        |> Ash.bulk_update!(
          :set_encoded,
          %{},
          tenant: tenant,
          domain: Records,
          resource: Record,
          batch_size: Records.encode_db_batch_size()
        )

      if error_count > 0,
        do: Logger.warning("#{error_count} records failed to transition to :encoded")
    end

    # Bulk update failed records to :failed
    failed_ids = Enum.map(results.failed, fn {id, _} -> id end)

    if Enum.any?(failed_ids) do
      %{error_count: error_count} =
        Record
        |> Ash.Query.filter(id in ^failed_ids)
        |> Ash.Query.set_tenant(tenant)
        |> Ash.bulk_update!(
          :set_encoding_failed,
          %{},
          tenant: tenant,
          domain: Records,
          resource: Record,
          batch_size: Records.encode_db_batch_size()
        )

      if error_count > 0,
        do: Logger.warning("#{error_count} records failed to transition to :failed")
    end

    :ok
  end

  # Bulk updates validation status for successful records
  defp bulk_update_validation_status(successful_ids, tenant, actor) do
    if Enum.any?(successful_ids) do
      Record
      |> Ash.Query.filter(id in ^successful_ids)
      |> Ash.Query.set_tenant(tenant)
      |> Ash.bulk_update!(
        :update_validation_status,
        %{status: :unknown},
        actor: actor,
        authorize?: false,
        tenant: tenant,
        domain: Records,
        resource: Record,
        batch_size: Records.encode_db_batch_size()
      )
    end

    :ok
  end
end
