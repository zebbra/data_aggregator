defmodule Storybook.Components.List do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &DataAggregatorWeb.Components.List.list/1

  def variations do
    [
      %Variation{
        id: :default,
        slots: [
          ~s|<:item title="Title">And a very long content about how awesome Elixir is.</:item>|,
          ~s|<:item title="Rating">5/5</:item>|
        ]
      }
    ]
  end
end
