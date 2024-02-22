defmodule DataAggregator.Records.Actions.EncodingResultsByCollection do
  @moduledoc """
  This module provides the action to read the encoding results for a collection.
  """

  require Ash.Query

  use Ash.Resource.ManualRead

  alias DataAggregator.Records
  alias DataAggregator.Records.Encoding.RecordEncodingResult

  def read(ash_query, _ecto_query, _opts, _context) do
    collection_id = ash_query.arguments.collection_id

    RecordEncodingResult
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(record.collection_id == ^collection_id)
    |> Records.read()
  end
end
