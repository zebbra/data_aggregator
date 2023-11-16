defmodule DataAggregator.Records.Record.Actions.BulkImport do
  @moduledoc """
  Custom action to bulk import a stream of rows using `DataAggregator.Records.Record.import/2`
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Records
  alias DataAggregator.Records.Record

  @impl true
  def run(input, _opts, _context) do
    %{import: import, rows: rows} = input.arguments

    # Eager load the imports collection to avoid N+1 queries when
    # creating the records
    {:ok, import} = import |> Records.load([:collection])

    records_stream =
      rows
      |> Stream.map(&%{import: import, params: &1})
      |> DataAggregator.Records.bulk_create(Record, :import,
        return_records?: true,
        return_errors?: true,
        return_stream?: true,
        # does not work in tests
        # max_concurrency: 2,
        batch_size: 1000
      )

    {:ok, records_stream}
  end
end
