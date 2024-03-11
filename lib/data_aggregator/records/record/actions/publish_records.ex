defmodule DataAggregator.Records.Actions.PublishRecords do
  @moduledoc """
  Custom action to publish records
  """

  use Ash.Resource.Actions.Implementation

  @impl true
  def run(input, _opts, _context) do
    _export = input.arguments.export

    # do publication magic now!
  end
end
