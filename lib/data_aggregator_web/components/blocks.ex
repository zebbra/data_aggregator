defmodule DataAggregatorWeb.Blocks do
  @moduledoc """
  This module is used to import all blocks at once.
  """

  defmacro __using__(_) do
    quote do
      import DataAggregatorWeb.Blocks.EmptyState
      import DataAggregatorWeb.Blocks.Header
      import DataAggregatorWeb.Blocks.SecondaryNavigation
      import DataAggregatorWeb.Blocks.Slideover
    end
  end
end
