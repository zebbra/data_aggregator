defmodule Storybook.Blocks.SecondaryNavigation do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Blocks

  def function, do: &Blocks.SecondaryNavigation.secondary_navigation/1
  def imports, do: [{Blocks.SecondaryNavigation, [secondary_navigation_item: 1]}]

  def variations do
    [
      %Variation{
        id: :default,
        slots: [
          """
          <.secondary_navigation_item label="Overview" href="#" active />
          <.secondary_navigation_item label="Details" href="#" />
          <.secondary_navigation_item label="Settings" href="#" />
          """
        ]
      }
    ]
  end
end
