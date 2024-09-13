defmodule Storybook.Components.Badge do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components

  def function, do: &Components.Badge.badge/1

  def variations do
    for color <- ~w(gray blue green red orange) do
      %Variation{
        id: String.to_atom(color),
        attributes: %{
          color: color
        },
        slots: [
          """
            <span class="px-1.5">#{color} badge</span>
          """
        ]
      }
    end
  end
end
