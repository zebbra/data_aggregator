defmodule Storybook.Components.Loading do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components.Loading

  def function, do: &Loading.spinner/1

  def variations do
    [
      %Variation{
        id: :hidden,
        attributes: %{
          show: false
        }
      },
      %Variation{
        id: :sm,
        attributes: %{
          size: "sm"
        }
      },
      %Variation{
        id: :md,
        attributes: %{
          size: "md",
          class: "text-indigo-500"
        }
      },
      %Variation{
        id: :lg,
        attributes: %{
          size: "lg",
          class: "text-purple-500"
        }
      }
    ]
  end
end
