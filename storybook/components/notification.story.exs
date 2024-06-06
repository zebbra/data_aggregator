defmodule Storybook.Components.Notification do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.Components

  def function, do: &Components.Notification.collapsible_notification/1

  def variations do
    for color <- ~w(gray blue green red orange) do
      %Variation{
        id: String.to_atom(color),
        attributes: %{
          title: "Title a long long long for #{color}",
          color: color
        },
        slots: [
          """
            <:action class="max-sm:hidden">
              Show more
            </:action>
            Details about the #{color} notification
          """
        ]
      }
    end
  end
end
