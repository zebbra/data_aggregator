defmodule DataAggregator.Data.Record.Actions.BulkImport do
  @moduledoc """
  Custom action to bulk import a stream of rows using `DataAggregator.Data.Record.import/2`
  """

  use Ash.Resource.Actions.Implementation

  alias DataAggregator.Data.Record

  def run(input, _opts, _context) do
    %{import: import, rows: rows} = input.arguments

    result =
      rows
      |> Stream.map(&%{import: import, params: &1})
      |> DataAggregator.Data.bulk_create(Record, :import, return_errors?: true)

    {:ok, result}
  end
end
