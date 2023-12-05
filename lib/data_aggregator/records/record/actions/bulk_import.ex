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
    {:ok, import} = Records.load(import, [:collection], lazy?: true)

    max_concurrency = Records.import_max_concurrency()
    batch_size = ceil(Records.import_batch_size() / max_concurrency)

    "Bulk importing records with batch size #{batch_size} (concurrency: #{max_concurrency}) ..."
    |> Logger.info()

    result =
      rows
      |> Stream.map(&%{import: import, params: &1})
      |> DataAggregator.Records.bulk_create!(Record, :import,
        return_errors?: true,
        return_records?: true,
        max_concurrency: max_concurrency,
        batch_size: batch_size
      )

    {:ok, result}
  end
end
