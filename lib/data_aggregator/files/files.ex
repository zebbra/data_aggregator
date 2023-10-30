defmodule DataAggregator.Files do
  @moduledoc """
  This context provides an `DataAggregator.Files.Attachment` resource for managing files.
  """

  use Ash.Api

  resources do
    registry DataAggregator.Files.Registry
  end
end
