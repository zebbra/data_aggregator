defmodule Storybook.CoreComponents.Button do
  use PhoenixStorybook.Story, :component

  def function, do: &Elixir.DataAggregatorWeb.CoreComponents.button/1

  def variations do
    [
      %Variation{
        id: :default,
        slots: ["Button"]
      },
      %Variation{
        id: :secondary,
        attributes: %{
          variant: "secondary"
        },
        slots: ["Secondary"]
      },
      %Variation{
        id: :accent,
        attributes: %{
          variant: "accent"
        },
        slots: ["Accent"]
      },
      %Variation{
        id: :nav,
        attributes: %{
          variant: "nav"
        },
        slots: ["Nav"]
      },
      %Variation{
        id: :table,
        attributes: %{
          variant: "table"
        },
        slots: ["Table"]
      },
      %Variation{
        id: :disabled,
        attributes: %{
          disabled: true
        },
        slots: ["Disabled"]
      }
    ]
  end
end
