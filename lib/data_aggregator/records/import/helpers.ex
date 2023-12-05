defmodule DataAggregator.Records.Import.Helpers do
  @moduledoc false

  alias DataAggregator.Records.Import
  alias DataAggregator.Records.Record

  @doc """
  Returns `true` if the row is valid and can be imported.
  """
  def valid_import_row?(%Import{} = import, row) do
    changeset = Record.changeset_to_import(import, row)
    changeset.valid?
  end
end
