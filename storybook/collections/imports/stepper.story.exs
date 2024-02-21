defmodule Storybook.Collections.Imports.Stepper do
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.CollectionLive.Import.Components.Stepper

  def function, do: &Stepper.stepper/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          steps: 4,
          current: 2
        }
      },
      %Variation{
        id: :with_links,
        attributes: %{
          links: ["#", "#", "#", "#"],
          current: 2
        }
      },
      %Variation{
        id: :with_disabled_links,
        attributes: %{
          steps: 4,
          links: [nil, "#", "#", nil],
          current: 2
        }
      }
    ]
  end
end
