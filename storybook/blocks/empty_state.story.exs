defmodule Storybook.Blocks.EmptyState do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Blocks

  def layout, do: :one_column

  def function, do: &Blocks.EmptyState.empty_state/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          href: "#"
        }
      },
      %Variation{
        id: :custom,
        attributes: %{
          title: "No records",
          description: "Get started by importing new data.",
          label: "Import data",
          icon: "hero-bug-ant",
          href: "#"
        }
      }
    ]
  end
end
