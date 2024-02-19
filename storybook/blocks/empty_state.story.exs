defmodule Storybook.Blocks.EmptyState do
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
          description: "Get started by importing a new dataset.",
          label: "Import dataset",
          icon: "hero-bug-ant",
          href: "#"
        }
      }
    ]
  end
end
