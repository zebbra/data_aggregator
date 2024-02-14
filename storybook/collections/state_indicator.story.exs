defmodule Storybook.Collections.StateIndicator do
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.CollectionLive.Components

  def function, do: &Components.state_indicator/1

  def variations do
    for state <- available_states() do
      %Variation{
        id: state,
        attributes: %{
          state: state
        }
      }
    end
  end

  defp available_states do
    [:encoded, :success, :failed, :encoding, :queued, :unchanged, :incomplete, :imported]
  end
end
