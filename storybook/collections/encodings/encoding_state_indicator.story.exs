defmodule Storybook.Collections.StateIndicator do
  use PhoenixStorybook.Story, :component

  alias DataAggregatorWeb.CollectionLive.Encoding.Components

  def function, do: &Components.encoding_state_indicator/1

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
    ~w(encoded success failed error encoding queued unchanged incomplete imported unknown)a
  end
end
