defmodule DataAggregatorWeb.Blocks do
  @moduledoc """
  This module is used to import all blocks at once.
  """

  defmacro __using__(_) do
    quote do
      import DataAggregatorWeb.Blocks.{
        Header
      }
    end
  end
end
