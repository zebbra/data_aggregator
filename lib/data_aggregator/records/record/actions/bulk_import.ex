defmodule DataAggregator.Records.Record.Actions.BulkImport do
  @moduledoc """
  Custom action to bulk import a stream of rows using `DataAggregator.Records.Record.import/2`
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def run(input, _opts, %{actor: actor, tenant: tenant}) do
    %{import: import, rows: rows} = input.arguments

    # Eager load the imports collection to avoid N+1 queries when
    # creating the records
    {:ok, import} = Ash.load(import, [:collection], lazy?: true)

    max_concurrency = Records.import_max_concurrency()
    # Split the configured batch across workers so max_concurrency actually runs
    # batches in parallel; cap at 150 because ~280 DwC attrs × 150 ≈ 42k params,
    # safely under PG's 65535 parameter limit.
    batch_size = min(ceil(Records.import_batch_size() / max_concurrency), 150)

    Logger.info("Bulk importing records with batch size #{batch_size} (concurrency: #{max_concurrency}) ...")

    {time, result} =
      :timer.tc(
        fn ->
          rows
          |> Stream.map(&%{import: import, params: &1})
          |> Ash.bulk_create!(Record, :import,
            return_errors?: true,
            max_concurrency: max_concurrency,
            batch_size: batch_size,
            timeout: to_timeout(minute: 5),
            actor: actor,
            authorize?: false,
            tenant: tenant
          )
        end,
        :millisecond
      )

    Logger.info("Bulk import took #{time} ms")

    {:ok, result}
  end
end
