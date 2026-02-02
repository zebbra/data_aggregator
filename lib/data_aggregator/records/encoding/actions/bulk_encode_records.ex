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

  alias DataAggregator.DarwinCore
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
  @spec run(list(String.t()), Collection.t(), Keyword.t()) :: {:ok, result()} | {:error, any()}
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

      # Step 3: Bulk create audit trail
      bulk_create_audit_trail(audit_records, tenant)

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

      {:error, e}
  end

  # Fetches records by IDs and transitions them to :encoding state
  defp fetch_and_transition_to_encoding(record_ids, tenant) do
    # Fetch records with their encoded_record relationship loaded
    records =
      Record
      |> Ash.Query.filter(id in ^record_ids)
      |> Ash.Query.set_tenant(tenant)
      |> Ash.Query.load([:encoded_record, :collection])
      |> Ash.read!()

    if Enum.empty?(records) do
      []
    else
      # Bulk update to :encoding state
      Ash.bulk_update!(
        records,
        :set_encoding,
        %{},
        tenant: tenant,
        domain: Records,
        resource: Record,
        batch_size: Records.encode_db_batch_size(),
        return_errors?: true
      )

      # Re-fetch with updated state
      Record
      |> Ash.Query.filter(id in ^record_ids)
      |> Ash.Query.set_tenant(tenant)
      |> Ash.Query.load([:encoded_record, :collection])
      |> Ash.read!()
    end
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

  # Processes a single catalog for all non-failed records in the batch
  defp process_catalog_for_batch(catalog, record_state, audit_records, ctx) do
    # Filter to only process non-failed records
    records_to_process =
      record_state
      |> Enum.filter(fn {_id, data} -> not data.failed? end)
      |> Enum.map(fn {id, data} -> {id, data} end)

    if Enum.empty?(records_to_process) do
      {record_state, audit_records}
    else
      # Process records in parallel using Task.async_stream
      max_concurrency = Records.encode_max_concurrency()

      results =
        records_to_process
        |> Task.async_stream(
          fn {id, data} ->
            encode_single_record_catalog(id, data, catalog, ctx)
          end,
          max_concurrency: max_concurrency,
          timeout: to_timeout(minute: 2),
          on_timeout: :kill_task
        )
        |> Enum.reduce({record_state, audit_records}, fn result, {state, audits} ->
          case result do
            {:ok, {id, updated_data, audit}} ->
              {Map.put(state, id, updated_data), [audit | audits]}

            {:exit, reason} ->
              Logger.error("Task exited during catalog #{catalog} encoding: #{inspect(reason)}")
              # Keep the state unchanged for this record - it will be handled as a failure
              {state, audits}
          end
        end)

      results
    end
  end

  # Encodes a single record through a single catalog
  defp encode_single_record_catalog(id, data, catalog, ctx) do
    record = data.record
    %{tenant: tenant} = ctx

    # For the first catalog (:col_taxonomy), create/reset the EncodedRecord
    encoded_record =
      if catalog == :col_taxonomy do
        ensure_encoded_record_exists(record, tenant)
      else
        # Reload the encoded record to get any updates from previous catalogs
        case data.encoded_record do
          nil -> EncodedRecord.get_by_record!(record.id, tenant: tenant)
          %Ash.NotLoaded{} -> EncodedRecord.get_by_record!(record.id, tenant: tenant)
          er -> EncodedRecord.get_by_id!(er.id, tenant: tenant)
        end
      end

    # Call the strategy to encode
    case Strategy.encode(encoded_record, catalog, ctx) do
      {:ok, new_encoded_record} ->
        audit =
          build_audit_record(catalog, :success, encoded_record, new_encoded_record, record, ctx)

        {id, %{data | encoded_record: new_encoded_record}, audit}

      {:unchanged, unchanged_encoded_record} ->
        # Strategy.encode returns {:ok, _} even for unchanged, so we create an unchanged audit
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

  # Ensures an EncodedRecord exists for the record (creates via upsert if needed)
  defp ensure_encoded_record_exists(record, tenant) do
    attributes =
      [:extra_data, :iucn_redlist_category] ++ DarwinCore.Schema.prefixed_attribute_names()

    record
    |> Map.from_struct()
    |> Map.take(attributes)
    |> Map.put(:record, record)
    |> EncodedRecord.create!(tenant: tenant)
  end

  # Builds an audit record for RecordEncodingResult
  defp build_audit_record(catalog, state, old_encoded, new_encoded, record, ctx, error \\ nil) do
    %{
      catalog: catalog,
      state: state,
      input: get_input_values(old_encoded, catalog),
      output: get_output_values(new_encoded, catalog),
      message: format_error_message(state, error),
      record: record,
      collection: ctx.tenant
    }
  end

  defp format_error_message(:unchanged, _), do: "no changes during encoding"
  defp format_error_message(:error, error) when is_binary(error), do: error
  defp format_error_message(:error, error), do: inspect(error)
  defp format_error_message(_, _), do: nil

  defp get_input_values(nil, _catalog), do: %{}
  defp get_input_values(%Ash.NotLoaded{}, _catalog), do: %{}

  defp get_input_values(encoded_record, catalog) do
    Map.take(encoded_record, Catalog.get_input_dwc_attributes(catalog))
  end

  defp get_output_values(nil, _catalog), do: %{}
  defp get_output_values(%Ash.NotLoaded{}, _catalog), do: %{}

  defp get_output_values(encoded_record, catalog) do
    Map.take(encoded_record, Catalog.get_output_dwc_attributes(catalog))
  end

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
      Ash.bulk_create!(audit_records, RecordEncodingResult, :create,
        tenant: tenant,
        batch_size: Records.encode_db_batch_size(),
        return_errors?: true
      )

      :ok
    end
  end

  # Bulk updates final record states (:encoded or :failed)
  defp bulk_update_final_states(results, tenant) do
    # Bulk update successful records to :encoded
    if Enum.any?(results.successful) do
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
    end

    # Bulk update failed records to :failed
    failed_ids = Enum.map(results.failed, fn {id, _} -> id end)

    if Enum.any?(failed_ids) do
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
