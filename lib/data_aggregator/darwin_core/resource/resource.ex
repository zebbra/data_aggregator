defmodule DataAggregator.DarwinCore.Resource do
  @moduledoc """
  `Ash.Resource.Extension` that adds Darwin Core attributes to a resource.
  """

  use Spark.Dsl.Extension,
    transformers: [DataAggregator.DarwinCore.Resource.Transformers.AddAttributes]
end
