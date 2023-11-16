defmodule DataAggregator.Platform.Publication.Actions.PublishRecords do
  @moduledoc """
  Custom action to publish records according to a set of rules for a consumer
  """

  use Ash.Resource.Actions.Implementation

  @impl true
  def run(_input, _opts, _context) do
    # go on implementing stuff...
    result = %{}

    {:ok, result}
  end
end
