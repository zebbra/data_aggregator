defmodule DataAggregator.Storage.Registry do
  use Ash.Registry,
    extensions: [
      # This extension adds helpful compile time validations
      Ash.Registry.ResourceValidations
    ]

  entries do
    entry DataAggregator.Storage.Attachment
    entry DataAggregator.Storage.ImportFile
    entry DataAggregator.Storage.Image
  end
end
