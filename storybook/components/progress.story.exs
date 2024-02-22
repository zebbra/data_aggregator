defmodule Storybook.Components.Progress do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components.Progress

  def function, do: &Progress.progress/1

  def variations do
    [
      %VariationGroup{
        id: :colors,
        variations:
          for color <- ["primary"] do
            %Variation{
              id: String.to_atom(color),
              attributes: %{
                color: color,
                value: 25,
                max: 100
              }
            }
          end
      },
      %VariationGroup{
        id: :sizes,
        variations:
          for size <- ["xs", "sm", "md", "lg", "xl"] do
            %Variation{
              id: String.to_atom(size),
              attributes: %{
                size: size,
                value: 25,
                max: 100,
                label: "25%"
              }
            }
          end
      }
    ]
  end
end
