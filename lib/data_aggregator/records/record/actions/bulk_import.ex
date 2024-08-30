defmodule DataAggregator.Records.Record.Actions.BulkImport do
  @moduledoc """
  Custom action to bulk import a stream of rows using `DataAggregator.Records.Record.import/2`
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records
  alias DataAggregator.Records.Record

  require Logger

  @impl true
  def run(input, _opts, _context) do
    %{import: import, rows: rows} = input.arguments

    # Eager load the imports collection to avoid N+1 queries when
    # creating the records
    {:ok, import} = Ash.load(import, [:collection], lazy?: true)

    max_concurrency = Records.import_max_concurrency()
    batch_size = ceil(Records.import_batch_size() / max_concurrency)

    # we have ~280 attributes and PG can handle 65535 params, to we can batch up to ~200 records
    # batch_size = Enum.min([batch_size, 200])

    Logger.info("Bulk importing records with batch size #{batch_size} (concurrency: #{max_concurrency}) ...")

    {time, result} =
      :timer.tc(
        fn ->
          rows
          |> Stream.map(&%{import: import, params: &1})
          |> Ash.bulk_create!(Record, :import,
            return_errors?: true,
            return_records?: true,
            max_concurrency: max_concurrency,
            batch_size: batch_size,
            timeout: :timer.minutes(5)
          )
        end,
        :millisecond
      )

    Logger.info("Bulk import took #{time} ms")

    {:ok, result}
  end
end
