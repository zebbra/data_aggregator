defmodule DataAggregatorWeb.Blocks do
  @moduledoc """
  This module is used to import all blocks at once.

  ## Introduction

  Blocks are reusable components that are used to build pages. They are used to
  create a consistent look and feel across the application. Blocks are used to
  create headers, footers, sidebars, and other common components. In general
  blocks to not apply specific styles, but rather provide a structure for
  components to be placed in.
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
