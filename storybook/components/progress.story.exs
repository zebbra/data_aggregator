defmodule Storybook.Components.Progress do
  use PhoenixStorybook.Story, :component
  alias DataAggregatorWeb.Components

  def function, do: &Components.Progress.progress/1

  def variations do
    [
      %VariationGroup{
        id: :colors,
        variations:
          for color <- [
                "",
                "progress-primary",
                "progress-secondary",
                "progress-info",
                "progress-success",
                "progress-error"
              ] do
            %Variation{
              id: String.to_atom(color),
              attributes: %{
                class: color,
                value: 25
              }
            }
          end
      },
      %VariationGroup{
        id: :progress,
        variations:
          for value <- [0, 10, 40, 70, 100] do
            %Variation{
              id: :"#{value}",
              attributes: %{
                class: "progress-primary",
                value: value
              }
            }
          end
      },
      %Variation{
        id: :indeterminate,
        attributes: %{
          class: "progress-primary"
        }
      },
      %VariationGroup{
        id: :sizes,
        variations:
          for size <- ["h-1", "h-2", "h-3", "h-4", "h-5"] do
            %Variation{
              id: String.to_atom(size),
              attributes: %{
                class: size,
                value: 25,
                label: "25%"
              }
            }
          end
      }
    ]
  end
end
