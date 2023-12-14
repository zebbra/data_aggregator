defmodule DataAggregator.Records.Encoding.Actions.EncodeRecord do
  @moduledoc """
  Encode Records with configured catalogs
  """

  use Ash.Resource.Actions.Implementation

  require Logger

  @impl true
  def run(_input, _opts, _context) do
    {:ok, %{}}
  end
end
