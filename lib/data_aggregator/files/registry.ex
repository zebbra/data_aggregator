defmodule DataAggregator.Files.Registry do
  @moduledoc """
  Registry for `DataAggregator.Files` Ash API.
  """

  use Ash.Registry,
    extensions: [Ash.Registry.ResourceValidations]

  entries do
    entry DataAggregator.Files.Attachment
  end
end
