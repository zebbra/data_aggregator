defmodule DataAggregator.Files do
  @moduledoc """
  This context provides a `DataAggregator.Files.Attachment` resource for managing files.

  ## Resources

  #{"./files-mermaid-class-diagram.md" |> Path.expand(__DIR__) |> File.read!()}

  """

  use Ash.Api

  resources do
    registry DataAggregator.Files.Registry
  end
end
