defmodule DataAggregator.Records.Actions.EncodingResultsByCollection do
  @moduledoc """
  This module provides the action to read the encoding results for a collection.
  """

  use Ash.Resource.ManualRead

  alias DataAggregator.Records.Encoding.RecordEncodingResult

  require Ash.Query

  def read(ash_query, _ecto_query, _opts, _context) do
    collection_id = ash_query.arguments.collection_id

    RecordEncodingResult
    |> Ash.Query.for_read(:read)
    |> Ash.Query.filter(record.collection_id == ^collection_id)
    |> Ash.read()
  end
end
